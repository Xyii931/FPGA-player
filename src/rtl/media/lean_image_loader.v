// Fixed 640x480 BMP -> inactive frame. Quarter turns use 3/4 nearest sampling,
// yielding a centered 360x480 image without a scaler or source line RAM.
// A frame is publishable only after parser, file I/O AND memory writes retire.
module lean_image_loader (
    input wire I_clk,I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [1:0] I_rotation,
    input wire I_slot,
    input wire I_byte_valid,
    output wire O_byte_ready,
    output wire O_stream_pause,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,I_file_done,
    input wire [7:0] I_file_error,
    input wire I_memory_error,I_writes_idle,
    output wire O_cancel,
    output wire O_write_valid,
    input wire I_write_ready,
    output wire [20:0] O_write_address,
    output wire [31:0] O_write_data,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [18:0] O_pixels
);
    localparam [2:0] IDLE=0,CLEAR=1,LOAD=2,RETIRE=3,DONE=4;
    reg [2:0] S_state;
    reg [1:0] S_rotation;
    reg S_slot,S_parser_seen,S_file_seen;
    reg [18:0] S_clear;
    reg [8:0] S_clear_column;
    // Capture each pixel with its 640-pixel row offset. The frame memory's own
    // write register then only adds base+x, splitting the long address chain.
    reg S_px_valid;
    reg [9:0] S_px_x;
    reg [18:0] S_px_row;
    reg [31:0] S_px_data;
    wire S_parser_ready,S_parser_done,S_parser_error,S_header,S_pixel,S_pixel_ready;
    wire [15:0] S_width,S_height,S_x,S_y;
    wire [31:0] S_rgba;
    wire S_byte_ready;
    wire S_start=I_start_valid && O_start_ready;
    wire S_bad_header=S_header && (S_width!=640 || S_height!=480);
    // Header valid itself is masked by parser abort. Latch a bad header below;
    // feeding it straight back to abort creates a combinational loop.
    wire S_abort=O_error!=0 || I_memory_error || (I_file_done && I_file_error!=0);
    wire S_drop=S_rotation[0] && (S_x[1:0]==3 || S_y[1:0]==3);
    wire [9:0] S_dx=({2'd0,S_x[9:2]}<<1)+{2'd0,S_x[9:2]}+{8'd0,S_x[1:0]};
    wire [8:0] S_dy=({2'd0,S_y[8:2]}<<1)+{2'd0,S_y[8:2]}+{7'd0,S_y[1:0]};
    reg [9:0] C_x;
    reg [8:0] C_y;
    always @* begin
        case(S_rotation)
            0:begin C_x=S_x[9:0]; C_y=S_y[8:0]; end
            1:begin C_x=10'd499-{1'b0,S_dy}; C_y=S_dx[8:0]; end
            2:begin C_x=10'd639-S_x[9:0]; C_y=9'd479-S_y[8:0]; end
            default:begin C_x=10'd140+{1'b0,S_dy}; C_y=9'd479-S_dx[8:0]; end
        endcase
    end
    wire [20:0] S_base=S_slot ? 21'd307200 : 21'd0;
    wire [18:0] S_row_offset=({10'd0,C_y}<<9)+({12'd0,C_y}<<7);
    wire S_px_free=!S_px_valid || I_write_ready;
    wire S_px_take=S_px_valid && I_write_ready;
    wire S_px_accept=S_state==LOAD && !S_abort && S_pixel && !S_drop && S_px_free;
    assign O_start_ready=!I_reset && S_state==IDLE && S_parser_ready;
    assign O_write_valid=!I_reset && !S_abort &&
        (S_state==CLEAR || (S_state==LOAD && S_px_valid));
    assign O_write_address=S_base+(S_state==CLEAR ? {2'd0,S_clear} :
        {2'd0,S_px_row}+{11'd0,S_px_x});
    // bmp_parser emits RRGGBBAA; the lean frame stores ffRRGGBB.
    assign O_write_data=S_state==CLEAR ? 32'd0 : S_px_data;
    assign S_pixel_ready=S_state==LOAD && !S_abort && (S_drop || S_px_free);
    assign O_stream_pause=!I_reset && S_state==CLEAR;
    assign O_byte_ready=!I_reset && (S_state==LOAD ? S_byte_ready : S_state==RETIRE);
    assign O_cancel=S_state!=IDLE && S_state!=DONE && S_abort && !S_file_seen;
    assign O_done_valid=!I_reset && S_state==DONE;
    bmp_parser u_parser (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_start),.O_start_ready(S_parser_ready),
        .I_file_size(I_file_size),.I_tag(8'd0),.O_done(S_parser_done),.O_err(S_parser_error),
        .I_byte_valid(I_byte_valid && S_state==LOAD),.O_byte_ready(S_byte_ready),.I_byte_data(I_byte_data),
        .I_byte_last(I_byte_last),.I_stream_error(I_file_done && I_file_error!=0),.I_abort(S_abort),
        .O_header_valid(S_header),.I_header_ready(!S_bad_header),.O_width(S_width),.O_height(S_height),
        .O_pixel_valid(S_pixel),.I_pixel_ready(S_pixel_ready),.O_rgba(S_rgba),.O_x(S_x),.O_y(S_y),
        .O_busy(), .O_error_code(), .O_tag(), .O_bottom_up(), .O_bpp(), .O_pixel_offset(), .O_row_bytes(), .O_pixel_last()
    );
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_rotation<=0; S_slot<=0; S_parser_seen<=0; S_file_seen<=0;
            S_clear<=0; S_clear_column<=0; S_px_valid<=0; S_px_x<=0; S_px_row<=0; S_px_data<=0;
            O_error<=0; O_pixels<=0;
        end else begin
            if(S_state!=IDLE && S_state!=DONE) begin
                if(I_file_done) begin
                    S_file_seen<=1;
                    if(I_file_error!=0) O_error<=4'd2;
                end
                if(S_parser_done) begin
                    S_parser_seen<=1;
                    if(S_parser_error && O_error==0) O_error<=4'd3;
                end
                if(S_bad_header) O_error<=4'd1;
                if(I_memory_error) O_error<=4'd4;
            end
            case(S_state)
                IDLE:if(S_start) begin
                    S_rotation<=I_rotation; S_slot<=I_slot; S_clear<=0; S_clear_column<=0; O_pixels<=0;
                    S_px_valid<=0;
                    S_parser_seen<=0; S_file_seen<=0; O_error<=0;
                    // Full-size 0/180 degree loads overwrite every pixel.
                    // Quarter turns clear only the two 140-pixel side bars.
                    S_state<=I_rotation[0] ? CLEAR : LOAD;
                end
                CLEAR:if(S_abort) S_state<=RETIRE;
                    else if(I_write_ready) begin
                        if(S_clear==307199) S_state<=LOAD;
                        else begin
                            S_clear<=S_clear+(S_clear_column==139 ? 19'd361 : 19'd1);
                            S_clear_column<=S_clear_column==279 ? 9'd0 : S_clear_column+1'b1;
                        end
                    end
                LOAD:begin
                    if(S_px_accept) begin
                        S_px_valid<=1; S_px_x<=C_x; S_px_row<=S_row_offset;
                        S_px_data<={8'hff,S_rgba[31:8]}; O_pixels<=O_pixels+1'b1;
                    end else if(S_px_take) S_px_valid<=0;
                    if(S_abort) begin S_px_valid<=0; S_state<=RETIRE; end
                    // Parser completion is a pulse and can precede acceptance
                    // of the last buffered pixel. Retain it across backpressure.
                    else if((S_parser_seen || S_parser_done) && !S_px_valid && !S_px_accept) S_state<=RETIRE;
                end
                RETIRE:if(S_parser_seen && S_file_seen && I_writes_idle) begin
                    if(O_error==0 && O_pixels!=(S_rotation[0] ? 19'd172800 : 19'd307200)) O_error<=4'd5;
                    S_state<=DONE;
                end
                DONE:if(I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
