// Sequential BMP byte stream -> normalized-coordinate RGBA pixels.
// Output belongs to an uncommitted destination until successful O_done.
module bmp_parser (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [7:0] I_tag,
    output wire O_busy,
    output reg O_done, O_err,
    output reg [3:0] O_error_code,
    output reg [7:0] O_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,
    input wire I_stream_error, I_abort,
    output wire O_header_valid,
    input wire I_header_ready,
    output reg [15:0] O_width, O_height,
    output reg O_bottom_up,
    output reg [5:0] O_bpp,
    output reg [31:0] O_pixel_offset, O_row_bytes,
    output reg O_pixel_valid,
    input wire I_pixel_ready,
    output reg [31:0] O_rgba,
    output reg [15:0] O_x, O_y,
    output reg O_pixel_last
);
    localparam [3:0] ST_IDLE=0, ST_HEADER=1, ST_CHECK=2, ST_META=3,
        ST_SKIP=4, ST_PIXELS=5, ST_TAIL=6, ST_DRAIN=7, ST_FINISH=8,
        ST_GEOMETRY=9, ST_STRIDE=10, ST_AREA=11, ST_END=12, ST_LENGTH=13;
    reg [3:0] S_state;
    reg [7:0] S_header [0:53];
    reg [31:0] S_file_size, S_file_size_m1, S_pos, S_row_pos;
    reg S_at_last;
    reg [15:0] S_x, S_row;
    reg [1:0] S_component;
    reg [7:0] S_blue, S_green, S_red;
    wire [31:0] S_width_raw, S_height_raw;
    reg [31:0] S_height_abs;
    wire [15:0] S_bpp_raw;
    reg [12:0] S_stride;
    reg [23:0] S_image_bytes;
    reg [32:0] S_pixel_end;
    reg [31:0] S_row_data_bytes;
    wire [31:0] S_offset_raw;
    function [31:0] header_u32;
        input integer offset;
        begin
            header_u32 = {S_header[offset+3], S_header[offset+2],
                          S_header[offset+1], S_header[offset]};
        end
    endfunction
    assign S_width_raw = {S_header[21],S_header[20],S_header[19],S_header[18]};
    assign S_height_raw = {S_header[25],S_header[24],S_header[23],S_header[22]};
    assign S_bpp_raw = {S_header[29], S_header[28]};
    // Expose memory reads in the expression so simulators track header changes.
    assign S_offset_raw = {S_header[13],S_header[12],S_header[11],S_header[10]};
    // Geometry scratch is overwritten on every job before use, without reset.
    // Separate stride, multiply, end addition and validation into clock cycles.
    // Legal stride <= 7680 (13 bits), height <= 1080 (11 bits).
    always @(posedge I_clk) begin
        if (S_state == ST_CHECK)
            S_height_abs <= S_height_raw[31] ? (~S_height_raw + 32'd1) : S_height_raw;
        if (S_state == ST_STRIDE) begin
            S_stride <= (O_bpp == 24) ?
                (((({2'd0,O_width[10:0]} << 1) + {2'd0,O_width[10:0]} + 13'd3) >> 2) << 2) :
                ({2'd0,O_width[10:0]} << 2);
            // Register the unpadded row length so the pixel loop never waits
            // for the width*3/4 multiplier.
            S_row_data_bytes <= O_width * ((O_bpp == 24) ? 32'd3 : 32'd4);
        end
        if (S_state == ST_AREA)
            S_image_bytes <= S_stride * O_height[10:0];
        if (S_state == ST_END)
            S_pixel_end <= {1'b0,O_pixel_offset} + {9'd0,S_image_bytes};
    end
    assign O_start_ready = S_state == ST_IDLE;
    assign O_busy = S_state != ST_IDLE;
    assign O_header_valid = S_state == ST_META && !I_abort && !I_stream_error;
    assign O_byte_ready = !I_abort && !I_stream_error && !O_pixel_valid &&
        (S_state == ST_HEADER || S_state == ST_SKIP ||
         S_state == ST_PIXELS || S_state == ST_TAIL);

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state <= ST_IDLE;
            S_file_size <= 0; S_file_size_m1 <= 0; S_pos <= 0; S_row_pos <= 0; S_at_last <= 0;
            S_x <= 0; S_row <= 0; S_component <= 0;
            S_blue <= 0; S_green <= 0; S_red <= 0;
            O_done <= 0; O_err <= 0; O_error_code <= 0; O_tag <= 0;
            O_width <= 0; O_height <= 0; O_bottom_up <= 0; O_bpp <= 0;
            O_pixel_offset <= 0; O_row_bytes <= 0;
            O_pixel_valid <= 0; O_rgba <= 0; O_x <= 0; O_y <= 0; O_pixel_last <= 0;
        end else begin
            O_done <= 1'b0;
            O_err <= 1'b0;
            if (O_pixel_valid && I_pixel_ready) O_pixel_valid <= 1'b0;
            if (O_busy && S_state != ST_FINISH && (I_abort || I_stream_error)) begin
                O_error_code <= I_abort ? 4'd6 : 4'd5;
                O_pixel_valid <= 1'b0;
                S_state <= ST_FINISH;
            end else begin
                case (S_state)
                    ST_IDLE: if (I_start_valid) begin
                        S_file_size <= I_file_size;
                        S_file_size_m1 <= I_file_size - 32'd1;
                        S_at_last <= 1'b0;
                        O_tag <= I_tag;
                        S_pos <= 0; S_row_pos <= 0; S_x <= 0; S_row <= 0; S_component <= 0;
                        O_width <= 0; O_height <= 0; O_bottom_up <= 0; O_bpp <= 0;
                        O_pixel_offset <= 0; O_row_bytes <= 0;
                        O_pixel_valid <= 0; O_pixel_last <= 0;
                        O_error_code <= I_file_size < 54 ? 4'd4 : 4'd0;
                        S_state <= I_file_size < 54 ? ST_FINISH : ST_HEADER;
                    end
                    ST_CHECK: begin
                        if (S_header[0] != 8'h42 || S_header[1] != 8'h4d || header_u32(14) != 40) begin
                            O_error_code <= 4'd1; S_state <= ST_FINISH;
                        end else if ({S_header[27],S_header[26]} != 1 ||
                            (S_bpp_raw != 24 && S_bpp_raw != 32) || header_u32(30) != 0) begin
                            O_error_code <= 4'd2; S_state <= ST_FINISH;
                        end else S_state <= ST_GEOMETRY;
                    end
                    ST_GEOMETRY: begin
                        if (S_width_raw < 1 || S_width_raw > 1920 ||
                            S_height_abs < 1 || S_height_abs > 1080) begin
                            O_error_code <= 4'd3; S_state <= ST_FINISH;
                        end else begin
                            O_width <= S_width_raw[15:0]; O_height <= S_height_abs[15:0];
                            O_bottom_up <= !S_height_raw[31]; O_bpp <= S_bpp_raw[5:0];
                            O_pixel_offset <= S_offset_raw;
                            S_state <= ST_STRIDE;
                        end
                    end
                    ST_STRIDE: S_state <= ST_AREA;
                    ST_AREA: begin
                        O_row_bytes <= {19'd0,S_stride};
                        S_state <= ST_END;
                    end
                    ST_END: S_state <= ST_LENGTH;
                    ST_LENGTH: begin
                        if (header_u32(2) != S_file_size || O_pixel_offset < 54 ||
                            S_pixel_end > {1'b0,S_file_size} ||
                            (header_u32(34) != 0 && header_u32(34) != {8'd0,S_image_bytes})) begin
                            O_error_code <= 4'd4; S_state <= ST_FINISH;
                        end else S_state <= ST_META;
                    end
                    ST_META: if (I_header_ready)
                        S_state <= S_pos == O_pixel_offset ? ST_PIXELS : ST_SKIP;
                    ST_DRAIN: if (!O_pixel_valid || I_pixel_ready) S_state <= ST_FINISH;
                    ST_FINISH: begin
                        O_done <= 1'b1;
                        O_err <= O_error_code != 0;
                        S_state <= ST_IDLE;
                    end
                    default: begin end
                endcase
                if (I_byte_valid && O_byte_ready) begin
                    // EOF is checked before producing any pixel from this byte.
                    if (I_byte_last != S_at_last) begin
                        O_error_code <= 4'd5;
                        O_pixel_valid <= 1'b0;
                        S_state <= ST_FINISH;
                    end else begin
                        S_pos <= S_pos + 1'b1;
                        S_at_last <= (S_pos + 32'd1 == S_file_size_m1);
                        case (S_state)
                            ST_HEADER: begin
                                S_header[S_pos] <= I_byte_data;
                                if (S_pos == 53) S_state <= ST_CHECK;
                            end
                            ST_SKIP: if (S_pos + 1 == O_pixel_offset) S_state <= ST_PIXELS;
                            ST_PIXELS: begin
                                if (S_row_pos < S_row_data_bytes) begin
                                    case (S_component)
                                        0: S_blue <= I_byte_data;
                                        1: S_green <= I_byte_data;
                                        2: S_red <= I_byte_data;
                                        default: begin end
                                    endcase
                                    if ((O_bpp == 24 && S_component == 2) ||
                                        (O_bpp == 32 && S_component == 3)) begin
                                        O_rgba <= {((O_bpp == 24) ? I_byte_data : S_red),
                                                    S_green, S_blue, 8'hff};
                                        O_x <= S_x;
                                        O_y <= O_bottom_up ? O_height-1-S_row : S_row;
                                        O_pixel_last <= S_x == O_width-1 && S_row == O_height-1;
                                        O_pixel_valid <= 1'b1;
                                        S_component <= 0;
                                        S_x <= S_x + 1'b1;
                                    end else S_component <= S_component + 1'b1;
                                end
                                if (S_row_pos == O_row_bytes-1) begin
                                    S_row_pos <= 0; S_x <= 0; S_component <= 0;
                                    if (S_row == O_height-1) S_state <= ST_TAIL;
                                    else S_row <= S_row + 1'b1;
                                end else S_row_pos <= S_row_pos + 1'b1;
                            end
                            default: begin end
                        endcase
                        if (S_at_last && S_state != ST_HEADER)
                            S_state <= ST_DRAIN;
                    end
                end
            end
        end
    end
endmodule
