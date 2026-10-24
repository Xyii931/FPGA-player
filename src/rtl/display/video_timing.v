// Free-running raster: sync, back porch, active video, front porch.
module video_timing #(
    parameter integer HTOTAL = 800, HSA = 96, HBP = 48, HACTIVE = 640, HFP = 16,
    parameter integer VTOTAL = 525, VSA = 2, VBP = 33, VACTIVE = 480, VFP = 10,
    parameter HS_POL = 1'b0, VS_POL = 1'b0
) (
    input wire I_clk,
    input wire I_reset,
    output wire O_hsync,
    output wire O_vsync,
    output wire O_de,
    output wire [15:0] O_x,
    output wire [15:0] O_y,
    output wire O_frame_start,
    output wire O_line_start,
    output wire [15:0] O_raster_x,
    output wire [15:0] O_raster_y
);
    reg [15:0] S_hcount;
    reg [15:0] S_vcount;
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_hcount <= 16'd0;
            S_vcount <= 16'd0;
        end else if (S_hcount == HTOTAL-1) begin
            S_hcount <= 16'd0;
            if (S_vcount == VTOTAL-1) S_vcount <= 16'd0;
            else S_vcount <= S_vcount + 1'b1;
        end else S_hcount <= S_hcount + 1'b1;
    end
    assign O_hsync = !I_reset && S_hcount < HSA ? HS_POL : ~HS_POL;
    assign O_vsync = !I_reset && S_vcount < VSA ? VS_POL : ~VS_POL;
    assign O_de = !I_reset &&
        S_hcount >= HSA+HBP && S_hcount < HSA+HBP+HACTIVE &&
        S_vcount >= VSA+VBP && S_vcount < VSA+VBP+VACTIVE;
    assign O_x = O_de ? S_hcount - (HSA+HBP) : 16'd0;
    assign O_y = O_de ? S_vcount - (VSA+VBP) : 16'd0;
    assign O_frame_start = !I_reset && S_hcount == 0 && S_vcount == 0;
    assign O_line_start = !I_reset && S_hcount == 0;
    assign O_raster_x = S_hcount;
    assign O_raster_y = S_vcount;
    // synthesis translate_off
    initial begin
        if (HTOTAL != HSA+HBP+HACTIVE+HFP || VTOTAL != VSA+VBP+VACTIVE+VFP ||
            HSA < 1 || VSA < 1 || HACTIVE < 1 || VACTIVE < 1 ||
            HBP < 0 || HFP < 0 || VBP < 0 || VFP < 0 ||
            HTOTAL > 65536 || VTOTAL > 65536) begin
            $display("FAIL: video_timing invalid geometry"); $stop;
        end
    end
    // synthesis translate_on
endmodule
