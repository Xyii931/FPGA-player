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
    output reg O_row_valid,
    output wire O_row_missing,
    output wire [15:0] O_row_bits,
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
    localparam [3:0] CLEAR_META=0,IDLE=1,LOOKUP_REQ=2,LOOKUP=3,
        VICTIM_REQ=4,VICTIM=5,COMMAND=6,FILL=7,RESULT=8,LOOKUP_META=9,VICTIM_META=10;
    reg [3:0] S_state;
    // bit16 referenced, bit15 locked, bit14 valid, bits13:0 glyph index.
    // Port A searches/updates; independent port B serves the synchronous row read.
    reg [16:0] S_metadata[0:399];
    reg [16:0] S_meta_q,S_row_meta;
    reg S_initialized,S_row_initialized,S_row_in_range;
    reg S_row_forward,S_row_forward_valid;
    reg C_meta_write;
    reg [16:0] C_meta_data;
    reg [15:0] S_rows[0:6399];
    reg [15:0] S_row_bits,S_row_fallback;
    reg [13:0] S_code;
    reg S_lock,S_shape_error;
    reg S_lookup_hit,S_lookup_last,S_lock_allowed,S_meta_locked,S_meta_replaceable;
    reg [8:0] S_cursor,S_clock_hand;
    reg [399:0] S_victim_select;
    reg [9:0] S_scanned;
    reg [5:0] S_bytes;
    reg [7:0] S_first_byte;
    reg [15:0] S_next_tag;
    wire S_read_fire=I_font_read_valid && O_font_read_ready;
    wire S_row_hit=S_row_initialized && S_row_in_range &&
        (S_row_forward ? S_row_forward_valid : S_row_meta[14]);
    // Decode the candidate before the decision, but read the live pin mask at
    // the decision edge. A pin added during the search must still protect it.
    wire S_protected=S_meta_locked || |(I_pinned & S_victim_select);
    wire S_victim=!S_protected && S_meta_replaceable;
    wire S_fill_success=I_font_done_valid && I_font_tag==O_font_tag && I_font_error==0 &&
        !S_shape_error && S_bytes==32 && !S_read_fire;
    wire [8:0] S_meta_address=S_state==FILL ? O_slot : S_cursor;
    wire [12:0] S_row_address={I_row_slot,I_row};
    wire [12:0] S_fill_address={O_slot,S_bytes[4:1]};
    assign O_get_ready=!I_reset && S_state==IDLE;
    assign O_result_valid=!I_reset && S_state==RESULT;
    assign O_font_valid=!I_reset && S_state==COMMAND;
    assign O_font_address=24'h010000+{5'd0,S_code,5'd0};
    assign O_font_read_ready=!I_reset && S_state==FILL;
    assign O_font_done_ready=!I_reset && S_state==FILL;
    assign O_row_missing=!I_reset && !S_row_hit;
    assign O_row_bits=O_row_missing ? S_row_fallback : S_row_bits;

    // Shift a constant one to decode the candidate, with one simulation process.
    // No reset is needed: VICTIM_REQ always prepares every bit before use.
    always @(posedge I_clk)
        if(S_state==VICTIM_REQ) S_victim_select<=400'd1<<S_cursor;

    always @* begin
        C_meta_write=0; C_meta_data=0;
        if(S_state==CLEAR_META) C_meta_write=1;
        else if(S_state==LOOKUP && S_lookup_hit && S_lock_allowed) begin
            C_meta_write=1; C_meta_data={1'b1,S_meta_q[15] | S_lock,1'b1,S_meta_q[13:0]};
        end else if(S_state==VICTIM && !S_protected) begin
            C_meta_write=1;
            // Selected victims are invalidated before any Flash request.
            // Otherwise give a referenced, unprotected slot its second chance.
            if(!S_victim) C_meta_data={1'b0,S_meta_q[15:0]};
        end else if(S_state==FILL && S_fill_success) begin
            C_meta_write=1; C_meta_data={1'b1,S_lock,1'b1,S_code};
        end
    end
    always @(posedge I_clk) begin
        if(C_meta_write) S_metadata[S_meta_address]<=C_meta_data;
        S_meta_q<=S_metadata[S_meta_address];
        if(!I_reset && I_row_valid) S_row_meta<=S_metadata[I_row_slot];
    end

    // One fill port and one synchronous row port; do not reset the glyph RAM.
    always @(posedge I_clk) begin
        if(S_read_fire && S_bytes<32 && S_bytes[0])
            S_rows[S_fill_address]<={S_first_byte,I_font_read_data};
        if(!I_reset && I_row_valid) begin
            // Keep the synchronous RAM output register directly on its port.
            // Missing-glyph selection follows the register, preserving latency.
            S_row_bits<=S_rows[S_row_address];
            S_row_fallback<=I_row==0 || I_row==15 ? 16'hffff : 16'h8001;
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=CLEAR_META; S_initialized<=0; S_row_initialized<=0; S_row_in_range<=0;
            S_row_forward<=0; S_row_forward_valid<=0;
            S_code<=0; S_lock<=0;
            S_lookup_hit<=0; S_lookup_last<=0; S_lock_allowed<=0; S_meta_locked<=0; S_meta_replaceable<=0;
            S_shape_error<=0; S_cursor<=0; S_clock_hand<=0; S_scanned<=0; S_bytes<=0; S_first_byte<=0;
            S_next_tag<=1; O_font_tag<=0; O_slot<=0; O_error<=0; O_locked_count<=0;
            O_miss_count<=0; O_flash_error_count<=0; O_row_valid<=0;
        end else begin
            O_row_valid<=I_row_valid;
            if(I_row_valid) begin
                S_row_initialized<=S_initialized; S_row_in_range<=I_row_slot<400;
                // Preserve pre-write valid on a coincident metadata update.
                // Do not depend on the BRAM's cross-port collision data.
                S_row_forward<=C_meta_write && S_meta_address==I_row_slot;
                S_row_forward_valid<=S_meta_q[14];
            end
            case(S_state)
                CLEAR_META:if(S_cursor==399) begin
                    S_initialized<=1; S_cursor<=0; S_state<=IDLE;
                end else S_cursor<=S_cursor+1'b1;
                IDLE:if(I_get_valid) begin
                    S_code<=I_code; S_lock<=I_lock; S_cursor<=0; O_error<=0; O_slot<=0;
                    if(I_code>=8836) begin O_error<=1; S_state<=RESULT; end
                    else S_state<=LOOKUP_REQ;
                end
                LOOKUP_REQ:S_state<=LOOKUP_META;
                LOOKUP_META:begin
                    S_lookup_hit<=S_meta_q[14] && S_meta_q[13:0]==S_code;
                    S_lookup_last<=S_cursor==399;
                    S_lock_allowed<=!S_lock || S_meta_q[15] || O_locked_count<LOCK_LIMIT;
                    S_state<=LOOKUP;
                end
                LOOKUP:if(S_lookup_hit) begin
                    O_slot<=S_cursor;
                    if(!S_lock_allowed) O_error<=3;
                    else begin
                        if(S_lock && !S_meta_q[15]) O_locked_count<=O_locked_count+1'b1;
                    end
                    S_state<=RESULT;
                end else if(S_lookup_last) begin
                    O_miss_count<=O_miss_count+1'b1;
                    if(S_lock && O_locked_count>=LOCK_LIMIT) begin O_error<=3; S_state<=RESULT; end
                    else begin S_cursor<=S_clock_hand; S_scanned<=0; S_state<=VICTIM_REQ; end
                end else begin S_cursor<=S_cursor+1'b1; S_state<=LOOKUP_REQ; end
                VICTIM_REQ:S_state<=VICTIM_META;
                VICTIM_META:begin
                    S_meta_locked<=S_meta_q[15];
                    S_meta_replaceable<=!S_meta_q[14] || !S_meta_q[16];
                    S_state<=VICTIM;
                end
                VICTIM:if(S_victim) begin
                    O_slot<=S_cursor;
                    S_clock_hand<=S_cursor==399 ? 9'd0 : S_cursor+1'b1;
                    O_font_tag<=S_next_tag; S_next_tag<=S_next_tag+1'b1;
                    S_bytes<=0; S_shape_error<=0; S_state<=COMMAND;
                end else if(S_scanned==799) begin O_error<=2; S_state<=RESULT; end
                else begin
                    S_scanned<=S_scanned+1'b1; S_cursor<=S_cursor==399 ? 9'd0 : S_cursor+1'b1;
                    S_state<=VICTIM_REQ;
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
                            if(S_lock) O_locked_count<=O_locked_count+1'b1;
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
