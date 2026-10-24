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
    localparam [4:0] ST_IDLE=0, ST_DIV_X=1, ST_DIV_Y_INIT=2,
        ST_DIV_Y=3, ST_INIT=4, ST_SELECT=5, ST_LOAD=6,
        ST_READ00=7, ST_READ01=8, ST_READ10=9, ST_READ11=10,
        ST_BLEND=11, ST_OUTPUT=12, ST_DONE=13, ST_CAPTURE11=14;
    reg [4:0] S_state;
    reg [15:0] S_src_w, S_src_h, S_dst_w, S_dst_h;
    reg S_bilinear, S_bottom_up, S_output_complete;
    reg [31:0] S_line0 [0:1919];
    reg [31:0] S_line1 [0:1919];
    reg [15:0] S_load_x, S_rows_loaded;
    reg [31:0] S_div_num, S_step_x, S_step_y;
    reg [32:0] S_div_rem;
    reg [15:0] S_divisor;
    reg [5:0] S_div_count;
    reg signed [31:0] S_origin_x, S_acc_x, S_acc_y;
    reg [31:0] S_p00, S_p01, S_p10, S_p11;
    reg [31:0] S_read0, S_read1;
    reg [1:0] S_channel;

    wire [32:0] S_div_trial = {S_div_rem[31:0],S_div_num[31]};
    wire S_div_sub = S_div_trial >= {17'd0,S_divisor};
    wire [31:0] S_div_next = {S_div_num[30:0],S_div_sub};
    wire [15:0] S_expected_y = S_bottom_up ? S_src_h-16'd1-S_rows_loaded : S_rows_loaded;
    wire S_input_last = S_load_x == S_src_w-16'd1 && S_rows_loaded == S_src_h-16'd1;

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

    wire [15:0] S_x0 = base_coordinate(S_acc_x,S_src_w,!S_bilinear);
    wire [15:0] S_y0 = base_coordinate(S_acc_y,S_src_h,!S_bilinear);
    wire [15:0] S_x1 = (!S_bilinear || S_x0 == S_src_w-16'd1) ? S_x0 : S_x0+16'd1;
    wire [15:0] S_y1 = (!S_bilinear || S_y0 == S_src_h-16'd1) ? S_y0 : S_y0+16'd1;
    wire [15:0] S_fx = fraction(S_acc_x,S_src_w,!S_bilinear);
    wire [15:0] S_fy = fraction(S_acc_y,S_src_h,!S_bilinear);
    wire [15:0] S_arrival0 = S_bottom_up ? S_src_h-16'd1-S_y0 : S_y0;
    wire [15:0] S_arrival1 = S_bottom_up ? S_src_h-16'd1-S_y1 : S_y1;
    wire [15:0] S_required_row = S_bottom_up ? S_arrival0 : S_arrival1;
    wire S_read_enable = S_state == ST_READ00 || S_state == ST_READ01 ||
        S_state == ST_READ10 || S_state == ST_READ11;
    wire [15:0] S_read_x = (S_state == ST_READ00 || S_state == ST_READ10) ? S_x0 : S_x1;

    // One explicit synchronous read site per bank. RAM and read registers have no
    // reset; the controller loads every needed row before enabling its use.
    always @(posedge I_clk) begin
        if (!I_reset && O_pixel_ready && I_pixel_valid && I_x == S_load_x &&
            I_y == S_expected_y && I_pixel_last == S_input_last) begin
            if (S_rows_loaded[0]) S_line1[S_load_x]<=I_rgba;
            else S_line0[S_load_x]<=I_rgba;
        end
        if (!I_reset && S_read_enable) begin
            S_read0<=S_line0[S_read_x];
            S_read1<=S_line1[S_read_x];
        end
    end

    // Full horizontal precision, then one final round to nearest at Q32.
    // One channel per cycle; synthesis still determines multiplier sharing/mapping.
    function [7:0] interpolate;
        input [7:0] p00,p01,p10,p11;
        input [15:0] fx,fy;
        reg [16:0] wx0,wx1,wy0,wy1;
        reg [24:0] top,bottom;
        reg [41:0] total;
        begin
            wx0=17'd65536-{1'b0,fx}; wx1={1'b0,fx};
            wy0=17'd65536-{1'b0,fy}; wy1={1'b0,fy};
            top=p00*wx0+p01*wx1;
            bottom=p10*wx0+p11*wx1;
            total=top*wy0+bottom*wy1+42'd2147483648;
            interpolate=total[39:32];
        end
    endfunction

    assign O_start_ready = S_state == ST_IDLE;
    assign O_busy = S_state != ST_IDLE;
    assign O_done_valid = S_state == ST_DONE;
    assign O_pixel_ready = S_state == ST_LOAD && !I_abort && !I_stream_error;
    assign O_pixel_valid = S_state == ST_OUTPUT && !I_abort && !I_stream_error;

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=ST_IDLE;
            S_src_w<=0; S_src_h<=0; S_dst_w<=0; S_dst_h<=0;
            S_bilinear<=0; S_bottom_up<=0; S_output_complete<=0;
            S_load_x<=0; S_rows_loaded<=0;
            S_div_num<=0; S_div_rem<=0; S_divisor<=0; S_div_count<=0;
            S_step_x<=0; S_step_y<=0; S_origin_x<=0; S_acc_x<=0; S_acc_y<=0;
            S_p00<=0; S_p01<=0; S_p10<=0; S_p11<=0; S_channel<=0;
            O_rgba<=0; O_x<=0; O_y<=0; O_pixel_last<=0;
            O_error<=0; O_tag<=0; O_generation<=0;
        end else if (S_state != ST_IDLE && S_state != ST_DONE && (I_abort || I_stream_error)) begin
            O_error<=I_abort ? 4'd4 : 4'd3;
            S_state<=ST_DONE;
        end else begin
            case (S_state)
                ST_IDLE: if (I_start_valid) begin
                    S_src_w<=I_src_width; S_src_h<=I_src_height;
                    S_dst_w<=I_dst_width; S_dst_h<=I_dst_height;
                    S_bilinear<=I_bilinear; S_bottom_up<=I_bottom_up;
                    O_tag<=I_tag; O_generation<=I_generation; O_error<=0;
                    S_load_x<=0; S_rows_loaded<=0; S_output_complete<=0;
                    O_x<=0; O_y<=I_bottom_up ? I_dst_height-16'd1 : 16'd0;
                    O_pixel_last<=0;
                    S_div_num<={I_src_width,16'd0}; S_div_rem<=0;
                    S_divisor<=I_dst_width; S_div_count<=0;
                    if (I_src_width == 0 || I_src_width > 1920 ||
                        I_src_height == 0 || I_src_height > 1080 ||
                        I_dst_width == 0 || I_dst_width > 640 ||
                        I_dst_height == 0 || I_dst_height > 640) begin
                        O_error<=4'd1; S_state<=ST_DONE;
                    end else S_state<=ST_DIV_X;
                end
                ST_DIV_X, ST_DIV_Y: begin
                    S_div_num<=S_div_next;
                    S_div_rem<=S_div_sub ? S_div_trial-{17'd0,S_divisor} : S_div_trial;
                    S_div_count<=S_div_count+1'b1;
                    if (S_div_count == 31) begin
                        if (S_state == ST_DIV_X) begin
                            S_step_x<=S_div_next; S_state<=ST_DIV_Y_INIT;
                        end else begin
                            S_step_y<=S_div_next; S_state<=ST_INIT;
                        end
                    end
                end
                ST_DIV_Y_INIT: begin
                    S_div_num<={S_src_h,16'd0}; S_div_rem<=0;
                    S_divisor<=S_dst_h; S_div_count<=0;
                    S_state<=ST_DIV_Y;
                end
                ST_INIT: begin
                    S_origin_x<=$signed(S_step_x >> 1)-32'sd32768;
                    S_acc_x<=$signed(S_step_x >> 1)-32'sd32768;
                    S_acc_y<=$signed(S_step_y >> 1)-32'sd32768 +
                        (S_bottom_up ? $signed((S_dst_h-16'd1)*S_step_y) : 32'sd0);
                    S_state<=ST_SELECT;
                end
                ST_SELECT: begin
                    if (S_output_complete) begin
                        S_state<=S_rows_loaded == S_src_h ? ST_DONE : ST_LOAD;
                    end else if (S_rows_loaded > S_required_row) S_state<=ST_READ00;
                    else S_state<=ST_LOAD;
                end
                ST_LOAD: if (I_pixel_valid) begin
                    if (I_x != S_load_x || I_y != S_expected_y || I_pixel_last != S_input_last) begin
                        O_error<=4'd2; S_state<=ST_DONE;
                    end else begin
                        if (S_load_x == S_src_w-16'd1) begin
                            S_load_x<=0; S_rows_loaded<=S_rows_loaded+16'd1;
                            S_state<=ST_SELECT;
                        end else S_load_x<=S_load_x+16'd1;
                    end
                end
                ST_READ00: begin
                    S_state<=ST_READ01;
                end
                ST_READ01: begin
                    S_p00<=S_arrival0[0] ? S_read1 : S_read0;
                    S_state<=ST_READ10;
                end
                ST_READ10: begin
                    S_p01<=S_arrival0[0] ? S_read1 : S_read0;
                    S_state<=ST_READ11;
                end
                ST_READ11: begin
                    S_p10<=S_arrival1[0] ? S_read1 : S_read0;
                    S_state<=ST_CAPTURE11;
                end
                ST_CAPTURE11: begin
                    S_p11<=S_arrival1[0] ? S_read1 : S_read0;
                    S_channel<=0; S_state<=ST_BLEND;
                end
                ST_BLEND: begin
                    O_rgba[31-S_channel*8 -: 8]<=interpolate(
                        S_p00[31-S_channel*8 -: 8],S_p01[31-S_channel*8 -: 8],
                        S_p10[31-S_channel*8 -: 8],S_p11[31-S_channel*8 -: 8],S_fx,S_fy);
                    if (S_channel == 3) begin
                        O_pixel_last<=O_x == S_dst_w-16'd1 &&
                            (S_bottom_up ? O_y == 0 : O_y == S_dst_h-16'd1);
                        S_state<=ST_OUTPUT;
                    end else S_channel<=S_channel+1'b1;
                end
                ST_OUTPUT: if (I_pixel_ready) begin
                    if (O_x == S_dst_w-16'd1) begin
                        O_x<=0; S_acc_x<=S_origin_x;
                        if (O_pixel_last) S_output_complete<=1;
                        else begin
                            O_y<=S_bottom_up ? O_y-16'd1 : O_y+16'd1;
                            S_acc_y<=S_bottom_up ? S_acc_y-$signed(S_step_y) : S_acc_y+$signed(S_step_y);
                        end
                        S_state<=ST_SELECT;
                    end else begin
                        O_x<=O_x+16'd1; S_acc_x<=S_acc_x+$signed(S_step_x);
                        S_state<=ST_READ00;
                    end
                end
                ST_DONE: if (I_done_ready) S_state<=ST_IDLE;
                default: S_state<=ST_IDLE;
            endcase
        end
    end
endmodule
