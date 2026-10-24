// P0 parallel RGB source. No HDMI core/PHY, AXIS adapter or framebuffer here.
module p0_video_source (
    input wire I_clk, I_reset,
    input wire [1:0] I_pattern,
    output wire O_hsync, O_vsync, O_de,
    output wire [15:0] O_x, O_y,
    output wire O_frame_start, O_line_start,
    output wire [23:0] O_rgb
);
    wire S_hsync, S_vsync, S_de, S_frame_start, S_line_start;
    wire [15:0] S_x, S_y;
    video_timing u_timing (
        .I_clk(I_clk), .I_reset(I_reset), .O_hsync(S_hsync), .O_vsync(S_vsync),
        .O_de(S_de), .O_x(S_x), .O_y(S_y),
        .O_frame_start(S_frame_start), .O_line_start(S_line_start), .O_raster_x(), .O_raster_y()
    );
    video_test_pattern u_pattern (
        .I_clk(I_clk), .I_reset(I_reset), .I_pattern(I_pattern),
        .I_hsync(S_hsync), .I_vsync(S_vsync), .I_de(S_de), .I_x(S_x), .I_y(S_y),
        .I_frame_start(S_frame_start), .I_line_start(S_line_start),
        .O_hsync(O_hsync), .O_vsync(O_vsync), .O_de(O_de), .O_x(O_x), .O_y(O_y),
        .O_frame_start(O_frame_start), .O_line_start(O_line_start), .O_rgb(O_rgb)
    );
endmodule
