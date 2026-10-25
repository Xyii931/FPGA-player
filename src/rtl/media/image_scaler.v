// Streaming half-pixel Q16 scaler. Two full source rows, never a frame RAM.
// Both source and destination traverse rows in the configured arrival direction.
// Pixels are candidates until file retirement AND real framebuffer writes succeed.
module image_scaler (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [15:0] I_src_width, I_src_height,
    input wire [15:0] I_dst_width, I_dst_height,
    input wire I_bilinear, I_bottom_up,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire I_abort, I_stream_error,
    input wire I_pixel_valid,
    output wire O_pixel_ready,
    input wire [31:0] I_rgba,
    input wire [15:0] I_x, I_y,
    input wire I_pixel_last,
    output wire O_pixel_valid,
    input wire I_pixel_ready,
    output reg [31:0] O_rgba,
    output reg [15:0] O_x, O_y,
    output reg O_pixel_last,
    output wire O_busy, O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation
);
    localparam [26:0] ST_IDLE=27'd1<<0, ST_DIV_X=27'd1<<1, ST_DIV_Y_INIT=27'd1<<2,
        ST_DIV_Y=27'd1<<3, ST_INIT=27'd1<<4, ST_SELECT=27'd1<<5, ST_LOAD=27'd1<<6,
        ST_READ00=27'd1<<7, ST_READ01=27'd1<<8, ST_READ10=27'd1<<9, ST_READ11=27'd1<<10,
        ST_BLEND=27'd1<<11, ST_OUTPUT=27'd1<<12, ST_DONE=27'd1<<13, ST_CAPTURE11=27'd1<<14,
        ST_HMULT=27'd1<<15, ST_HSUM=27'd1<<16, ST_VDIFF=27'd1<<17, ST_VMULT=27'd1<<18,
        ST_VSUM=27'd1<<19, ST_ROUND=27'd1<<20, ST_COORD_ADJUST=27'd1<<21, ST_COORD_BASE=27'd1<<22,
        ST_COORD_NEXT=27'd1<<23, ST_COORD_ROW=27'd1<<24, ST_SPAN=27'd1<<25, ST_INIT_Y=27'd1<<26;
    reg [26:0] S_state;
    reg [15:0] S_src_w, S_src_h, S_dst_w, S_dst_h;
    reg [15:0] S_src_w_last, S_src_h_last, S_expected_y;
    reg [15:0] S_dst_w_last, S_dst_h_last;
    reg S_bilinear, S_bottom_up, S_output_complete;
    reg [15:0] S_load_x, S_rows_loaded;
    reg [31:0] S_div_num, S_step_x, S_step_y;
    reg [32:0] S_div_rem;
    reg [15:0] S_divisor;
    reg [5:0] S_div_count;
    reg signed [31:0] S_origin_x, S_acc_x, S_acc_y;
    reg [31:0] S_p00, S_p01, S_p10, S_p11;
    wire [31:0] S_read0, S_read1;
    reg [1:0] S_channel;
    reg [15:0] S_blend_fx, S_blend_fy;
    reg signed [8:0] S_delta_top, S_delta_bottom;
    reg [7:0] S_base_top, S_base_bottom;
    reg signed [25:0] S_product_top, S_product_bottom;
    reg signed [24:0] S_top, S_bottom, S_delta_y;
    reg signed [41:0] S_product_y, S_total;
    reg signed [31:0] S_coord_x, S_coord_y;
    reg [15:0] S_x0, S_y0, S_x1, S_y1, S_fx, S_fy;
    reg [15:0] S_arrival0, S_arrival1, S_required_row;
    reg [9:0] S_span_factor;
    reg [31:0] S_span_step, S_y_span;

    wire [32:0] S_div_trial = {S_div_rem[31:0],S_div_num[31]};
    wire S_div_sub = S_div_trial >= {17'd0,S_divisor};
    wire [31:0] S_div_next = {S_div_num[30:0],S_div_sub};
    wire S_input_last = S_load_x == S_src_w_last && S_rows_loaded == S_src_h_last;

    // pos is signed Q16. Legal geometry keeps all accumulators in signed 32 bits.
    function [15:0] base_coordinate;
        input signed [31:0] pos;
        input [15:0] size;
        input nearest;
        reg signed [31:0] adjusted, limit;
        begin
            adjusted = nearest ? pos + 32'sd32768 : pos;
            limit = $signed({size-16'd1,16'd0});
            if (adjusted < 0) base_coordinate = 0;
            else if (adjusted >= limit) base_coordinate = size-16'd1;
            else base_coordinate = adjusted[31:16];
        end
    endfunction
    function [15:0] fraction;
        input signed [31:0] pos;
        input [15:0] size;
        input nearest;
        reg signed [31:0] limit;
        begin
            limit = $signed({size-16'd1,16'd0});
            fraction = (nearest || pos < 0 || pos >= limit) ? 16'd0 : pos[15:0];
        end
    endfunction

    wire S_read_enable = S_state[7] || S_state[8] ||
        S_state[9] || S_state[10];
    wire [15:0] S_read_x = (S_state[7] || S_state[9]) ? S_x0 : S_x1;

    // Two complete source rows; explicitly allocate 32K blocks rather than
    // consume the small-block pool. One synchronous read cycle, no RAM reset.
    // The validated geometry keeps every enabled full address below 1920.
    // Loading and reading are mutually exclusive; no collision data is used.
    wire S_line_write=!I_reset && O_pixel_ready && I_pixel_valid && I_x==S_load_x &&
        I_y==S_expected_y && I_pixel_last==S_input_last;
    player_bram32k #(.DATA_BITS(32),.ADDR_BITS(11),.DEPTH(1920)) u_line0 (
        .I_clk_a(I_clk),.I_enable_a(S_line_write && !S_rows_loaded[0]),.I_write_a(1'b1),
        .I_address_a(S_load_x[10:0]),.I_data_a(I_rgba),.O_data_a(),
        .I_clk_b(I_clk),.I_enable_b(!I_reset && S_read_enable),.I_write_b(1'b0),
        .I_address_b(S_read_x[10:0]),.I_data_b(32'd0),.O_data_b(S_read0));
    player_bram32k #(.DATA_BITS(32),.ADDR_BITS(11),.DEPTH(1920)) u_line1 (
        .I_clk_a(I_clk),.I_enable_a(S_line_write && S_rows_loaded[0]),.I_write_a(1'b1),
        .I_address_a(S_load_x[10:0]),.I_data_a(I_rgba),.O_data_a(),
        .I_clk_b(I_clk),.I_enable_b(!I_reset && S_read_enable),.I_write_b(1'b0),
        .I_address_b(S_read_x[10:0]),.I_data_b(32'd0),.O_data_b(S_read1));

    // Exact difference-form interpolation, with no intermediate rounding:
    // top = (p00 << 16) + (p01-p00)*fx, likewise bottom;
    // total = (top << 16) + (bottom-top)*fy + 2^31.
    // Snapshot fractions before arithmetic. Each channel traverses registered
    // subtract/multiply/add stages; only ST_OUTPUT publishes a complete pixel.
    wire [7:0] S_c00=S_p00[31-S_channel*8 -: 8];
    wire [7:0] S_c01=S_p01[31-S_channel*8 -: 8];
    wire [7:0] S_c10=S_p10[31-S_channel*8 -: 8];
    wire [7:0] S_c11=S_p11[31-S_channel*8 -: 8];

    assign O_start_ready = S_state[0];
    assign O_busy = !S_state[0];
    assign O_done_valid = S_state[13];
    assign O_pixel_ready = S_state[6] && !I_abort && !I_stream_error;
    assign O_pixel_valid = S_state[12] && !I_abort && !I_stream_error;
    wire S_bad_geometry=I_src_width==0 || I_src_width>1920 ||
        I_src_height==0 || I_src_height>1080 || I_dst_width==0 || I_dst_width>640 ||
        I_dst_height==0 || I_dst_height>640;
    wire S_bad_pixel=I_x!=S_load_x || I_y!=S_expected_y || I_pixel_last!=S_input_last;

    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) O_error<=0;
        else if(S_state[0] && I_start_valid) O_error<=S_bad_geometry ? 4'd1 : 4'd0;
        else if(!S_state[0] && !S_state[13] && (I_abort || I_stream_error))
            O_error<=I_abort ? 4'd4 : 4'd3;
        else if(S_state[6] && I_pixel_valid && S_bad_pixel) O_error<=4'd2;
    end

    // Scratch stages have no reset or abort enable chain. Every value is
    // overwritten in order before use; the main FSM alone admits output.
    always @(posedge I_clk) begin
        case(1'b1)
            S_state[21]: begin
                S_coord_x<=S_bilinear ? S_acc_x : S_acc_x+32'sd32768;
                S_coord_y<=S_bilinear ? S_acc_y : S_acc_y+32'sd32768;
            end
            S_state[22]: begin
                S_x0<=base_coordinate(S_coord_x,S_src_w,1'b0);
                S_y0<=base_coordinate(S_coord_y,S_src_h,1'b0);
                S_fx<=fraction(S_acc_x,S_src_w,!S_bilinear);
                S_fy<=fraction(S_acc_y,S_src_h,!S_bilinear);
            end
            S_state[23]: begin
                S_x1<=(!S_bilinear || S_x0==S_src_w_last) ? S_x0 : S_x0+16'd1;
                S_y1<=(!S_bilinear || S_y0==S_src_h_last) ? S_y0 : S_y0+16'd1;
                S_arrival0<=S_bottom_up ? S_src_h_last-S_y0 : S_y0;
            end
            S_state[24]: begin
                S_arrival1<=S_bottom_up ? S_src_h_last-S_y1 : S_y1;
                S_required_row<=S_bottom_up ? S_arrival0 : S_y1;
            end
            S_state[14]: begin
                S_blend_fx<=S_fx; S_blend_fy<=S_fy;
            end
            S_state[11]: begin
                S_base_top<=S_c00; S_base_bottom<=S_c10;
                S_delta_top<=$signed({1'b0,S_c01})-$signed({1'b0,S_c00});
                S_delta_bottom<=$signed({1'b0,S_c11})-$signed({1'b0,S_c10});
            end
            S_state[15]: begin
                S_product_top<=S_delta_top*$signed({1'b0,S_blend_fx});
                S_product_bottom<=S_delta_bottom*$signed({1'b0,S_blend_fx});
            end
            S_state[16]: begin
                S_top<=$signed({1'b0,S_base_top,16'd0})+S_product_top;
                S_bottom<=$signed({1'b0,S_base_bottom,16'd0})+S_product_bottom;
            end
            S_state[17]: begin
                S_delta_y<=S_bottom-S_top;
            end
            S_state[18]: begin
                S_product_y<=S_delta_y*$signed({1'b0,S_blend_fy});
            end
            S_state[19]: begin
                S_total<=$signed({1'b0,S_top,16'd0})+S_product_y+42'sd2147483648;
            end
            default: begin end
        endcase
    end

    // Coordinate scratch may update on an abort edge; the main controller
    // revokes publication that edge and every new task reinitializes it.
    // Keep its enables independent of the terminal/error priority chain.
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) S_acc_y<=0;
        else if(S_state[26])
            S_acc_y<=$signed(S_step_y >> 1)-32'sd32768+$signed(S_y_span);
        else if(S_state[12] && I_pixel_ready && O_x==S_dst_w_last && !O_pixel_last)
            S_acc_y<=S_bottom_up ? S_acc_y-$signed(S_step_y) : S_acc_y+$signed(S_step_y);
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) S_output_complete<=0;
        else if(S_state[0] && I_start_valid) S_output_complete<=0;
        else if(S_state[12] && I_pixel_ready && O_pixel_last) S_output_complete<=1;
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin O_x<=0; O_y<=0; end
        else if(S_state[0] && I_start_valid) begin
            O_x<=0; O_y<=I_bottom_up ? I_dst_height-16'd1 : 16'd0;
        end else if(S_state[12] && I_pixel_ready) begin
            if(O_x==S_dst_w_last) begin
                O_x<=0;
                if(!O_pixel_last) O_y<=S_bottom_up ? O_y-16'd1 : O_y+16'd1;
            end else O_x<=O_x+16'd1;
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin S_origin_x<=0; S_acc_x<=0; end
        else if(S_state[4]) begin
            S_origin_x<=$signed(S_step_x >> 1)-32'sd32768;
            S_acc_x<=$signed(S_step_x >> 1)-32'sd32768;
        end else if(S_state[12] && I_pixel_ready)
            S_acc_x<=O_x==S_dst_w_last ? S_origin_x : S_acc_x+$signed(S_step_x);
    end

    reg [26:0] S_next_state;
    // Direct one-hot transitions avoid a priority chain through all stages.
    always @* begin
        S_next_state=0;
        S_next_state[0]=(S_state[0] && !I_start_valid) ||
            (S_state[13] && I_done_ready) || !(|S_state);
        S_next_state[1]=(S_state[0] && I_start_valid && !S_bad_geometry) ||
            (S_state[1] && S_div_count!=31);
        S_next_state[2]=S_state[1] && S_div_count==31;
        S_next_state[3]=S_state[2] || (S_state[3] && S_div_count!=31);
        S_next_state[4]=S_state[3] && S_div_count==31;
        S_next_state[5]=S_state[24] || (S_state[6] && I_pixel_valid &&
            !S_bad_pixel && S_load_x==S_src_w_last);
        S_next_state[6]=(S_state[5] && (S_output_complete ?
            S_rows_loaded!=S_src_h : S_rows_loaded<=S_required_row)) ||
            (S_state[6] && (!I_pixel_valid || (!S_bad_pixel && S_load_x!=S_src_w_last)));
        S_next_state[7]=S_state[5] && !S_output_complete && S_rows_loaded>S_required_row;
        S_next_state[8]=S_state[7];
        S_next_state[9]=S_state[8];
        S_next_state[10]=S_state[9];
        S_next_state[11]=S_state[14] || (S_state[20] && S_channel!=3);
        S_next_state[12]=(S_state[20] && S_channel==3) || (S_state[12] && !I_pixel_ready);
        S_next_state[13]=(S_state[0] && I_start_valid && S_bad_geometry) ||
            (S_state[5] && S_output_complete && S_rows_loaded==S_src_h) ||
            (S_state[6] && I_pixel_valid && S_bad_pixel) || (S_state[13] && !I_done_ready);
        S_next_state[14]=S_state[10];
        S_next_state[15]=S_state[11];
        S_next_state[16]=S_state[15];
        S_next_state[17]=S_state[16];
        S_next_state[18]=S_state[17];
        S_next_state[19]=S_state[18];
        S_next_state[20]=S_state[19];
        S_next_state[21]=S_state[26] || (S_state[12] && I_pixel_ready);
        S_next_state[22]=S_state[21];
        S_next_state[23]=S_state[22];
        S_next_state[24]=S_state[23];
        S_next_state[25]=S_state[4] || (S_state[25] && S_span_factor!=0);
        S_next_state[26]=S_state[25] && S_span_factor==0;
        if(!S_state[0] && !S_state[13] && (I_abort || I_stream_error)) S_next_state=ST_DONE;
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) S_state<=ST_IDLE;
        else S_state<=S_next_state;
    end

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_src_w<=0; S_src_h<=0; S_dst_w<=0; S_dst_h<=0;
            S_src_w_last<=0; S_src_h_last<=0; S_expected_y<=0;
            S_dst_w_last<=0; S_dst_h_last<=0;
            S_bilinear<=0; S_bottom_up<=0;
            S_load_x<=0; S_rows_loaded<=0;
            S_div_num<=0; S_div_rem<=0; S_divisor<=0; S_div_count<=0;
            S_step_x<=0; S_step_y<=0;
            S_p00<=0; S_p01<=0; S_p10<=0; S_p11<=0; S_channel<=0;
            S_span_factor<=0; S_span_step<=0; S_y_span<=0;
            O_rgba<=0; O_pixel_last<=0;
            O_tag<=0; O_generation<=0;
        end else begin
            case (1'b1)
                S_state[0]: if (I_start_valid) begin
                    S_src_w<=I_src_width; S_src_h<=I_src_height;
                    S_src_w_last<=I_src_width-16'd1; S_src_h_last<=I_src_height-16'd1;
                    S_dst_w<=I_dst_width; S_dst_h<=I_dst_height;
                    S_dst_w_last<=I_dst_width-16'd1; S_dst_h_last<=I_dst_height-16'd1;
                    S_bilinear<=I_bilinear; S_bottom_up<=I_bottom_up;
                    O_tag<=I_tag; O_generation<=I_generation;
                    S_load_x<=0; S_rows_loaded<=0;
                    O_pixel_last<=0;
                    S_div_num<={I_src_width,16'd0}; S_div_rem<=0;
                    S_divisor<=I_dst_width; S_div_count<=0;
                end
                S_state[1], S_state[3]: begin
                    S_div_num<=S_div_next;
                    S_div_rem<=S_div_sub ? S_div_trial-{17'd0,S_divisor} : S_div_trial;
                    S_div_count<=S_div_count+1'b1;
                    if (S_div_count == 31) begin
                        if (S_state[1]) begin
                            S_step_x<=S_div_next;
                        end else begin
                            S_step_y<=S_div_next;
                        end
                    end
                end
                S_state[2]: begin
                    S_div_num<={S_src_h,16'd0}; S_div_rem<=0;
                    S_divisor<=S_dst_h; S_div_count<=0;
                end
                S_state[4]: begin
                    S_expected_y<=S_bottom_up ? S_src_h_last : 16'd0;
                    // A one-time shift/add product avoids a wide startup DSP
                    // chain. Validated destination height needs only ten bits.
                    S_span_factor<=S_bottom_up ? S_dst_h_last : 16'd0;
                    S_span_step<=S_step_y; S_y_span<=0;
                end
                S_state[25]: begin
                    if(S_span_factor!=0) begin
                        if(S_span_factor[0]) S_y_span<=S_y_span+S_span_step;
                        S_span_step<=S_span_step<<1; S_span_factor<=S_span_factor>>1;
                    end
                end
                S_state[6]: if (I_pixel_valid) begin
                    if (S_bad_pixel) begin
                    end else begin
                        if (S_load_x == S_src_w_last) begin
                            S_load_x<=0; S_rows_loaded<=S_rows_loaded+16'd1;
                            S_expected_y<=S_bottom_up ? S_expected_y-16'd1 : S_expected_y+16'd1;
                        end else S_load_x<=S_load_x+16'd1;
                    end
                end
                S_state[8]: begin
                    S_p00<=S_arrival0[0] ? S_read1 : S_read0;
                end
                S_state[9]: begin
                    S_p01<=S_arrival0[0] ? S_read1 : S_read0;
                end
                S_state[10]: begin
                    S_p10<=S_arrival1[0] ? S_read1 : S_read0;
                end
                S_state[14]: begin
                    S_p11<=S_arrival1[0] ? S_read1 : S_read0;

                    S_channel<=0;
                end
                S_state[20]: begin
                    O_rgba[31-S_channel*8 -: 8]<=S_total[39:32];
                    if (S_channel == 3) begin
                        O_pixel_last<=O_x == S_dst_w_last &&
                            (S_bottom_up ? O_y == 0 : O_y == S_dst_h_last);
                    end else begin S_channel<=S_channel+1'b1;  end
                end
                default: begin end
            endcase
        end
    end
endmodule
