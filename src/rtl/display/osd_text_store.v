// Double-buffered resolved text cells, with cache pins owned until actual retirement.
// All ports are 100 MHz. Publication/old-retired proof comes from the video owner.
module osd_text_store (
    input wire I_clk,I_reset,I_begin_valid,
    output wire O_begin_ready,
    input wire I_line_valid,
    output wire O_line_ready,
    input wire I_layer,
    input wire [3:0] I_line,
    input wire [9:0] I_x,
    input wire [8:0] I_y,
    input wire [1:0] I_color,
    input wire I_lock,
    input wire [5:0] I_length,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,I_finish_valid,
    output wire O_finish_ready,
    input wire I_abort,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg O_cancel_late,O_active_valid,O_active_bank,
    output reg [31:0] O_glyph_misses,
    output wire [399:0] O_pinned,
    output wire O_publish_valid,O_publish_bank,
    input wire I_publish_ready,I_publish_done_valid,I_publish_done_bank,I_old_retired,
    output wire O_publish_done_ready,
    output reg O_response_discarded,
    output wire O_get_valid,
    input wire I_get_ready,
    output wire [13:0] O_get_code,
    output wire O_get_lock,
    input wire I_get_result_valid,
    output wire O_get_result_ready,
    input wire [8:0] I_get_slot,
    input wire [3:0] I_get_error,
    input wire I_query_bank,I_query_layer,
    input wire [3:0] I_query_line,
    output wire O_query_valid,
    output wire [9:0] O_query_x,
    output wire [8:0] O_query_y,
    output wire [1:0] O_query_color,
    output wire [5:0] O_query_count,
    input wire I_read_valid,
    input wire [5:0] I_read_column,
    output reg O_read_valid,
    output wire [15:0] O_read_cell
);
    localparam [3:0] IDLE=0,READY=1,LINE=2,GET_OFFER=3,GET_WAIT=4,PUBLISH=5,WAIT_PUBLISH=6,RESULT=7,CANCEL=8;
    reg [3:0] S_state;
    reg S_bank,S_lock,S_cancel;
    reg [5:0] S_line_address,S_column;
    reg [13:0] S_pending_code;
    reg [399:0] S_pins0,S_pins1;
    reg [47:0] S_line_valid;
    reg [9:0] S_x[0:47];
    reg [8:0] S_y[0:47];
    reg [1:0] S_color[0:47];
    reg [5:0] S_count[0:47];
    reg [15:0] S_cells[0:1919];
    reg [15:0] S_read_cell;
    reg S_read_in_range;
    reg S_decoder_done;
    reg [1:0] S_decoder_error;
    wire S_decode_start_ready,S_decode_byte_ready,S_decode_valid,S_decode_last,S_decode_busy,S_decode_done;
    wire [15:0] S_decode_cell;
    wire [1:0] S_decode_error;
    wire [5:0] S_decode_warnings;
    wire S_line_ok=I_line<12 && I_x<640 && I_y<=464 && I_length<=40;
    wire S_start_line=I_line_valid && O_line_ready;
    wire S_decode_ready=S_state==LINE && !S_cancel && !I_abort;
    wire S_cell_fire=S_decode_valid && S_decode_ready;
    wire S_ascii_write=S_cell_fire && !S_decode_cell[15];
    wire S_glyph_write=S_state==GET_WAIT && I_get_result_valid && !S_cancel && !I_abort;
    wire [15:0] S_write_cell=S_ascii_write ? {9'd0,S_decode_cell[6:0]} :
        (I_get_error==0 && I_get_slot<400 ? {7'b1000000,I_get_slot} : 16'h003f);
    wire [10:0] S_write_address={5'd0,S_line_address}*11'd40+{5'd0,S_column};
    wire [5:0] S_query_address=(I_query_bank ? 6'd24 : 6'd0)+(I_query_layer ? 6'd12 : 6'd0)+{2'd0,I_query_line};
    wire [10:0] S_read_address={5'd0,S_query_address}*11'd40+{5'd0,I_read_column};
    assign O_begin_ready=!I_reset && S_state==IDLE;
    assign O_line_ready=!I_reset && S_state==READY && !S_cancel && !I_abort && S_decode_start_ready;
    assign O_finish_ready=!I_reset && S_state==READY && !I_line_valid && !S_cancel && !I_abort;
    assign O_byte_ready=!I_reset && S_state==LINE && S_decode_byte_ready;
    assign O_busy=S_state!=IDLE;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_pinned=S_pins0 | S_pins1;
    assign O_publish_valid=!I_reset && S_state==PUBLISH;
    assign O_publish_bank=S_bank;
    assign O_publish_done_ready=!I_reset && S_state==WAIT_PUBLISH && I_old_retired;
    assign O_get_valid=!I_reset && S_state==GET_OFFER;
    assign O_get_code=S_pending_code;
    assign O_get_lock=S_lock;
    assign O_get_result_ready=!I_reset && S_state==GET_WAIT;
    assign O_query_valid=I_query_line<12 && S_line_valid[S_query_address];
    assign O_query_x=O_query_valid ? S_x[S_query_address] : 10'd0;
    assign O_query_y=O_query_valid ? S_y[S_query_address] : 9'd0;
    assign O_query_color=O_query_valid ? S_color[S_query_address] : 2'd0;
    assign O_query_count=O_query_valid ? S_count[S_query_address] : 6'd0;
    assign O_read_cell=S_read_in_range ? S_read_cell : 16'h0020;
    gb2312_text_decoder u_decoder (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_start_line && S_line_ok),.O_start_ready(S_decode_start_ready),.I_length(I_length),
        .I_byte_valid(I_byte_valid && S_state==LINE),.O_byte_ready(S_decode_byte_ready),.I_byte_data(I_byte_data),.I_byte_last(I_byte_last),
        .I_abort((S_cancel || I_abort) && S_decode_busy),.O_valid(S_decode_valid),.I_ready(S_decode_ready),.O_cell(S_decode_cell),
        .O_last(S_decode_last),.O_busy(S_decode_busy),.O_done(S_decode_done),.O_error(S_decode_error),.O_warnings(S_decode_warnings)
    );
    // One write port and one synchronous read port. Valid descriptors delimit RAM.
    always @(posedge I_clk) begin
        if(S_ascii_write || S_glyph_write) S_cells[S_write_address]<=S_write_cell;
        O_read_valid<=!I_reset && I_read_valid;
        if(!I_reset && I_read_valid) begin
            S_read_cell<=S_cells[S_read_address];
            S_read_in_range<=O_query_valid && I_read_column<O_query_count && I_read_column<40;
        end
    end
    task cancel_frame;
        input [3:0] error;
        begin
            // Retire the failed preparation before the wide bank clear.
            O_error<=error; S_state<=CANCEL;
        end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_bank<=0; S_lock<=0; S_cancel<=0; S_line_address<=0; S_column<=0; S_pending_code<=0;
            S_pins0<=0; S_pins1<=0; S_line_valid<=0; S_decoder_done<=0; S_decoder_error<=0;
            O_error<=0; O_cancel_late<=0; O_active_valid<=0; O_active_bank<=0; O_glyph_misses<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            if(S_decode_done) begin S_decoder_done<=1; S_decoder_error<=S_decode_error; end
            if(I_abort && S_state!=IDLE && S_state!=RESULT) begin
                if(S_state==PUBLISH || S_state==WAIT_PUBLISH) O_cancel_late<=1;
                else S_cancel<=1;
            end
            case(S_state)
                IDLE:if(I_begin_valid) begin
                    S_bank<=!O_active_bank; S_cancel<=0; O_error<=0; O_cancel_late<=0;
                    if(!O_active_bank) begin S_pins1<=0; S_line_valid[47:24]<=0; end
                    else begin S_pins0<=0; S_line_valid[23:0]<=0; end
                    S_state<=READY;
                end
                READY:if(S_cancel || I_abort) cancel_frame(2);
                    else if(S_start_line) begin
                        if(!S_line_ok) cancel_frame(1);
                        else begin
                            S_line_address<=(S_bank ? 6'd24 : 6'd0)+(I_layer ? 6'd12 : 6'd0)+{2'd0,I_line};
                            S_x[(S_bank ? 6'd24 : 6'd0)+(I_layer ? 6'd12 : 6'd0)+{2'd0,I_line}]<=I_x;
                            S_y[(S_bank ? 6'd24 : 6'd0)+(I_layer ? 6'd12 : 6'd0)+{2'd0,I_line}]<=I_y;
                            S_color[(S_bank ? 6'd24 : 6'd0)+(I_layer ? 6'd12 : 6'd0)+{2'd0,I_line}]<=I_color;
                            S_lock<=I_lock; S_column<=0; S_decoder_done<=0; S_decoder_error<=0; S_state<=LINE;
                        end
                    end else if(I_finish_valid && O_finish_ready) S_state<=PUBLISH;
                LINE:if((S_cancel || I_abort) && !S_decode_busy) cancel_frame(2);
                    else if(S_cell_fire) begin
                        if(S_decode_cell[15]) begin S_pending_code<=S_decode_cell[13:0]; S_state<=GET_OFFER; end
                        else S_column<=S_column+1'b1;
                    end else if(S_decoder_done && !S_decode_valid && !S_decode_busy) begin
                        if(S_decoder_error!=0) cancel_frame(1);
                        else begin S_line_valid[S_line_address]<=1; S_count[S_line_address]<=S_column; S_state<=READY; end
                    end
                GET_OFFER:if(I_get_ready) S_state<=GET_WAIT;
                GET_WAIT:if(I_get_result_valid) begin
                    if(!S_cancel && !I_abort) begin
                        if(I_get_error==0 && I_get_slot<400) begin
                            if(S_bank) S_pins1[I_get_slot]<=1; else S_pins0[I_get_slot]<=1;
                        end else O_glyph_misses<=O_glyph_misses+1'b1;
                        S_column<=S_column+1'b1;
                    end
                    S_state<=LINE;
                end
                PUBLISH:if(I_publish_ready) S_state<=WAIT_PUBLISH;
                WAIT_PUBLISH:if(I_publish_done_valid && O_publish_done_ready) begin
                    if(I_publish_done_bank!=S_bank) O_response_discarded<=1;
                    else begin
                        O_active_valid<=1; O_active_bank<=S_bank;
                        if(S_bank) begin S_pins0<=0; S_line_valid[23:0]<=0; end
                        else begin S_pins1<=0; S_line_valid[47:24]<=0; end
                        O_error<=0; S_state<=RESULT;
                    end
                end
                CANCEL:begin
                    if(S_bank) begin S_pins1<=0; S_line_valid[47:24]<=0; end
                    else begin S_pins0<=0; S_line_valid[23:0]<=0; end
                    S_state<=RESULT;
                end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin O_error<=3; S_state<=RESULT; end
            endcase
        end
    end
endmodule
