// Build one raster line from actual resolved text cells and glyph-cache row reads.
// Layer 0 is low priority HUD, layer 1 is foreground/menu/alert.
module osd_line_renderer (
    input wire I_clk,I_reset,I_start_valid,
    output wire O_start_ready,
    input wire I_bank,
    input wire [8:0] I_y,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire O_query_bank,O_query_layer,
    output wire [3:0] O_query_line,
    input wire I_query_valid,
    input wire [9:0] I_query_x,
    input wire [8:0] I_query_y,
    input wire [1:0] I_query_color,
    input wire [5:0] I_query_count,
    output wire O_read_valid,
    output wire [5:0] O_read_column,
    input wire I_read_valid,
    input wire [15:0] I_read_cell,
    output wire O_row_valid,
    output wire [8:0] O_row_slot,
    output wire [3:0] O_row,
    input wire I_row_valid,I_row_missing,
    input wire [15:0] I_row_bits,
    output wire O_write_valid,
    input wire I_write_ready,
    output wire O_write_clear,O_write_layer,
    output wire [9:0] O_write_x,
    output wire [1:0] O_write_color,
    output wire O_write_ink,
    output reg [31:0] O_missing_rows
);
    localparam [3:0] IDLE=0,CLEAR=1,QUERY=2,CELL_REQ=3,CELL_WAIT=4,FONT_REQ=5,FONT_WAIT=6,PIXELS=7,DONE=8;
    reg [3:0] S_state;
    reg S_bank,S_layer;
    reg [8:0] S_y;
    reg [3:0] S_line,S_row,S_pixel;
    reg [5:0] S_column,S_count;
    reg [9:0] S_origin,S_clear_x;
    reg [1:0] S_color;
    reg [15:0] S_cell,S_bits;
    wire [7:0] S_ascii;
    wire [10:0] S_pixel_x={1'b0,S_origin}+{1'b0,S_column,4'd0}+{7'd0,S_pixel};
    wire [9:0] S_row_offset={1'b0,S_y}-{1'b0,I_query_y};
    ascii_font8x16 u_ascii(.I_char(I_read_cell[7:0]),.I_row(S_row),.O_bits(S_ascii));
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_done_valid=!I_reset && S_state==DONE;
    assign O_query_bank=S_bank;
    assign O_query_layer=S_layer;
    assign O_query_line=S_line;
    assign O_read_valid=!I_reset && S_state==CELL_REQ;
    assign O_read_column=S_column;
    assign O_row_valid=!I_reset && S_state==FONT_REQ;
    assign O_row_slot=S_cell[8:0];
    assign O_row=S_row;
    assign O_write_valid=!I_reset && (S_state==CLEAR || (S_state==PIXELS && S_pixel_x<640));
    assign O_write_clear=S_state==CLEAR;
    assign O_write_layer=S_layer;
    assign O_write_x=S_state==CLEAR ? S_clear_x : S_pixel_x[9:0];
    assign O_write_color=S_color;
    assign O_write_ink=S_state==PIXELS && S_bits[15-S_pixel];
    task next_line;
        begin
            S_column<=0;
            if(S_line==11) begin
                S_line<=0;
                if(S_layer) S_state<=DONE;
                else begin S_layer<=1; S_state<=QUERY; end
            end else begin S_line<=S_line+1'b1; S_state<=QUERY; end
        end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_bank<=0; S_layer<=0; S_y<=0; S_line<=0; S_row<=0; S_pixel<=0;
            S_column<=0; S_count<=0; S_origin<=0; S_clear_x<=0; S_color<=0; S_cell<=0; S_bits<=0; O_missing_rows<=0;
        end else case(S_state)
            IDLE:if(I_start_valid) begin
                S_bank<=I_bank; S_y<=I_y; S_layer<=0; S_line<=0; S_column<=0; S_clear_x<=0; S_state<=CLEAR;
            end
            CLEAR:if(I_write_ready) begin
                if(S_clear_x==639) begin S_clear_x<=0; S_state<=QUERY; end
                else S_clear_x<=S_clear_x+1'b1;
            end
            QUERY:if(I_query_valid && I_query_count!=0 && I_query_y<=S_y && S_row_offset<16) begin
                S_origin<=I_query_x; S_count<=I_query_count>40 ? 6'd40 : I_query_count;
                S_color<=I_query_color; S_row<=S_row_offset[3:0]; S_column<=0; S_state<=CELL_REQ;
            end else next_line;
            CELL_REQ:S_state<=CELL_WAIT;
            CELL_WAIT:if(I_read_valid) begin
                S_cell<=I_read_cell; S_pixel<=0;
                if(I_read_cell[15]) S_state<=FONT_REQ;
                else begin S_bits<={S_ascii,8'd0}; S_state<=PIXELS; end
            end
            FONT_REQ:S_state<=FONT_WAIT;
            FONT_WAIT:if(I_row_valid) begin
                S_bits<=I_row_bits; S_pixel<=0; S_state<=PIXELS;
                if(I_row_missing) O_missing_rows<=O_missing_rows+1'b1;
            end
            PIXELS:if(S_pixel_x>=640) next_line;
                else if(I_write_ready) begin
                    if(S_pixel==15) begin
                        S_pixel<=0;
                        if(S_column+6'd1>=S_count) next_line;
                        else begin S_column<=S_column+1'b1; S_state<=CELL_REQ; end
                    end else S_pixel<=S_pixel+1'b1;
                end
            DONE:if(I_done_ready) S_state<=IDLE;
            default:S_state<=IDLE;
        endcase
    end
endmodule
