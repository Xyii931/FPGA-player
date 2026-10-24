// 400 fully searched GB2312 slots with pinned/locked protection and CLOCK eviction.
// All ports including the row reader are in I_clk (100 MHz), not the pixel domain.
module glyph_cache #(
    parameter integer LOCK_LIMIT=192
) (
    input wire I_clk,I_reset,I_get_valid,
    output wire O_get_ready,
    input wire [13:0] I_code,
    input wire I_lock,
    input wire [399:0] I_pinned,
    output wire O_result_valid,
    input wire I_result_ready,
    output reg [8:0] O_slot,
    output reg [3:0] O_error,
    output reg [8:0] O_locked_count,
    output reg [31:0] O_miss_count,O_flash_error_count,
    input wire I_row_valid,
    input wire [8:0] I_row_slot,
    input wire [3:0] I_row,
    output reg O_row_valid,O_row_missing,
    output reg [15:0] O_row_bits,
    output wire O_font_valid,
    input wire I_font_ready,
    output wire [23:0] O_font_address,
    output reg [15:0] O_font_tag,
    input wire I_font_read_valid,
    output wire O_font_read_ready,
    input wire [7:0] I_font_read_data,
    input wire I_font_read_last,I_font_done_valid,
    output wire O_font_done_ready,
    input wire [3:0] I_font_error,
    input wire [15:0] I_font_tag
);
    localparam [2:0] IDLE=0,LOOKUP=1,VICTIM=2,COMMAND=3,FILL=4,RESULT=5;
    reg [2:0] S_state;
    reg [399:0] S_valid,S_locked,S_referenced;
    reg [13:0] S_tags[0:399];
    reg [15:0] S_rows[0:6399];
    reg [13:0] S_code;
    reg S_lock,S_shape_error;
    reg [8:0] S_cursor,S_clock_hand;
    reg [9:0] S_scanned;
    reg [5:0] S_bytes;
    reg [7:0] S_first_byte;
    reg [15:0] S_next_tag;
    wire S_read_fire=I_font_read_valid && O_font_read_ready;
    wire S_row_hit=I_row_slot<400 && S_valid[I_row_slot];
    wire [12:0] S_row_address={I_row_slot,I_row};
    wire [12:0] S_fill_address={O_slot,S_bytes[4:1]};
    assign O_get_ready=!I_reset && S_state==IDLE;
    assign O_result_valid=!I_reset && S_state==RESULT;
    assign O_font_valid=!I_reset && S_state==COMMAND;
    assign O_font_address=24'h010000+{5'd0,S_code,5'd0};
    assign O_font_read_ready=!I_reset && S_state==FILL;
    assign O_font_done_ready=!I_reset && S_state==FILL;

    // One fill port and one synchronous row port; do not reset the glyph RAM.
    always @(posedge I_clk) begin
        if(S_read_fire && S_bytes<32 && S_bytes[0])
            S_rows[S_fill_address]<={S_first_byte,I_font_read_data};
        if(!I_reset && I_row_valid) begin
            O_row_bits<=S_row_hit ? S_rows[S_row_address] :
                (I_row==0 || I_row==15 ? 16'hffff : 16'h8001);
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_valid<=0; S_locked<=0; S_referenced<=0; S_code<=0; S_lock<=0;
            S_shape_error<=0; S_cursor<=0; S_clock_hand<=0; S_scanned<=0; S_bytes<=0; S_first_byte<=0;
            S_next_tag<=1; O_font_tag<=0; O_slot<=0; O_error<=0; O_locked_count<=0;
            O_miss_count<=0; O_flash_error_count<=0; O_row_valid<=0; O_row_missing<=0;
        end else begin
            O_row_valid<=I_row_valid;
            if(I_row_valid) O_row_missing<=!S_row_hit;
            case(S_state)
                IDLE:if(I_get_valid) begin
                    S_code<=I_code; S_lock<=I_lock; S_cursor<=0; O_error<=0; O_slot<=0;
                    if(I_code>=8836) begin O_error<=1; S_state<=RESULT; end
                    else S_state<=LOOKUP;
                end
                LOOKUP:if(S_valid[S_cursor] && S_tags[S_cursor]==S_code) begin
                    O_slot<=S_cursor;
                    if(S_lock && !S_locked[S_cursor] && O_locked_count>=LOCK_LIMIT) O_error<=3;
                    else begin
                        S_referenced[S_cursor]<=1;
                        if(S_lock && !S_locked[S_cursor]) begin S_locked[S_cursor]<=1; O_locked_count<=O_locked_count+1'b1; end
                    end
                    S_state<=RESULT;
                end else if(S_cursor==399) begin
                    O_miss_count<=O_miss_count+1'b1;
                    if(S_lock && O_locked_count>=LOCK_LIMIT) begin O_error<=3; S_state<=RESULT; end
                    else begin S_cursor<=S_clock_hand; S_scanned<=0; S_state<=VICTIM; end
                end else S_cursor<=S_cursor+1'b1;
                VICTIM:if(!S_locked[S_cursor] && !I_pinned[S_cursor] &&
                    (!S_valid[S_cursor] || !S_referenced[S_cursor])) begin
                    O_slot<=S_cursor; S_valid[S_cursor]<=0; S_referenced[S_cursor]<=0;
                    S_clock_hand<=S_cursor==399 ? 9'd0 : S_cursor+1'b1;
                    O_font_tag<=S_next_tag; S_next_tag<=S_next_tag+1'b1;
                    S_bytes<=0; S_shape_error<=0; S_state<=COMMAND;
                end else if(S_scanned==799) begin O_error<=2; S_state<=RESULT; end
                else begin
                    if(!S_locked[S_cursor] && !I_pinned[S_cursor]) S_referenced[S_cursor]<=0;
                    S_scanned<=S_scanned+1'b1; S_cursor<=S_cursor==399 ? 9'd0 : S_cursor+1'b1;
                end
                COMMAND:if(I_font_ready) S_state<=FILL;
                FILL:begin
                    if(S_read_fire) begin
                        if(S_bytes<32 && !S_bytes[0]) S_first_byte<=I_font_read_data;
                        if(S_bytes<63) S_bytes<=S_bytes+1'b1;
                        if(S_bytes>=32 || I_font_read_last!=(S_bytes==31)) S_shape_error<=1;
                    end
                    if(I_font_done_valid) begin
                        if(I_font_tag!=O_font_tag) begin O_error<=5; O_flash_error_count<=O_flash_error_count+1'b1; end
                        else if(I_font_error!=0 || S_shape_error || S_bytes!=32 || S_read_fire) begin
                            O_error<=4; O_flash_error_count<=O_flash_error_count+1'b1;
                        end else begin
                            S_tags[O_slot]<=S_code; S_valid[O_slot]<=1; S_referenced[O_slot]<=1;
                            if(S_lock) begin S_locked[O_slot]<=1; O_locked_count<=O_locked_count+1'b1; end
                        end
                        S_state<=RESULT;
                    end
                end
                RESULT:if(I_result_ready) S_state<=IDLE;
                default:begin O_error<=4; S_state<=RESULT; end
            endcase
        end
    end
endmodule
