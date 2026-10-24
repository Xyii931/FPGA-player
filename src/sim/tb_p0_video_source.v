`timescale 1ns/1ps
module tb_p0_video_source;
    reg S_clk = 1'b0;
    reg S_reset = 1'b0;
    reg [1:0] S_pattern = 2'd0;
    reg S_test_pass = 1'b0;
    wire S_hs, S_vs, S_de, S_fs, S_ls;
    wire [15:0] S_x, S_y;
    wire [23:0] S_rgb;
    wire S_small_done, S_one_done;
    integer S_frame, S_h, S_v, S_ex, S_ey, S_pixels, S_lines;
    reg S_expected_de;
    reg [23:0] S_expected_rgb;
    always #20 S_clk = ~S_clk;
    p0_video_source u_dut (
        .I_clk(S_clk), .I_reset(S_reset), .I_pattern(S_pattern),
        .O_hsync(S_hs), .O_vsync(S_vs), .O_de(S_de), .O_x(S_x), .O_y(S_y),
        .O_frame_start(S_fs), .O_line_start(S_ls), .O_rgb(S_rgb)
    );
    // Non-default geometry and positive sync polarity, plus 1x1 active video.
    video_timing_case #(1, 1, 3, 1, 1, 1, 2, 1, 1'b1) u_small(S_small_done);
    video_timing_case #(1, 0, 1, 0, 1, 0, 1, 0, 1'b0) u_one(S_one_done);

    // Independent expected colors, based on observable active coordinates.
    function [23:0] expected_rgb;
        input integer mode, x, y;
        integer gray;
        begin
            expected_rgb = 24'd0;
            case (mode)
                0: begin
                    if      (x < 80)  expected_rgb = 24'hffffff;
                    else if (x < 160) expected_rgb = 24'hffff00;
                    else if (x < 240) expected_rgb = 24'h00ffff;
                    else if (x < 320) expected_rgb = 24'h00ff00;
                    else if (x < 400) expected_rgb = 24'hff00ff;
                    else if (x < 480) expected_rgb = 24'hff0000;
                    else if (x < 560) expected_rgb = 24'h0000ff;
                end
                1: begin
                    gray = x * 255 / 639;
                    expected_rgb = {gray[7:0], gray[7:0], gray[7:0]};
                end
                2: if (x == 0 || x == 639 || y == 0 || y == 479 || x == 320 || y == 240)
                    expected_rgb = 24'hffffff;
                3: if ((x + y) % 2 == 1) expected_rgb = 24'hffffff;
            endcase
        end
    endfunction
    task check_reset;
        begin
            if ({S_hs, S_vs, S_de, S_fs, S_ls} !== 5'b11000 ||
                S_x !== 0 || S_y !== 0 || S_rgb !== 0) begin
                $display("FAIL: video source reset outputs"); $stop;
            end
        end
    endtask
    initial begin
        #1; S_reset = 1'b1;
        #1; check_reset;
        repeat (2) @(negedge S_clk);
        S_reset = 1'b0;
        // Each frame switches the requested mode mid-frame, but must retain its old mode.
        for (S_frame = 0; S_frame < 4; S_frame = S_frame + 1) begin
            S_pixels = 0;
            S_lines = 0;
            for (S_v = 0; S_v < 525; S_v = S_v + 1) begin
                for (S_h = 0; S_h < 800; S_h = S_h + 1) begin
                    S_expected_de = S_h >= 144 && S_h < 784 && S_v >= 35 && S_v < 515;
                    S_ex = 0; S_ey = 0; S_expected_rgb = 0;
                    if (S_expected_de) begin
                        S_ex = S_h - 144; S_ey = S_v - 35;
                        S_expected_rgb = expected_rgb(S_frame, S_ex, S_ey);
                        S_pixels = S_pixels + 1;
                    end
                    if (S_h == 0) S_lines = S_lines + 1;
                    @(posedge S_clk); #1;
                    if (S_hs !== (S_h >= 96) || S_vs !== (S_v >= 2) ||
                        S_de !== S_expected_de || S_x !== S_ex || S_y !== S_ey ||
                        S_fs !== (S_h == 0 && S_v == 0) || S_ls !== (S_h == 0) ||
                        S_rgb !== S_expected_rgb) begin
                        $display("FAIL: frame=%0d raster=(%0d,%0d) xy=(%0d,%0d) rgb=%h expected=%h",
                            S_frame, S_h, S_v, S_x, S_y, S_rgb, S_expected_rgb); $stop;
                    end
                    if (S_h == 200 && S_v == 100) S_pattern = S_frame + 1;
                end
            end
            if (S_pixels != 307200 || S_lines != 525) begin
                $display("FAIL: frame pixel/line totals"); $stop;
            end
        end
        // Reset in the active region and verify a clean restart from raster origin.
        repeat (36*800 + 150) @(posedge S_clk);
        #2; S_reset = 1'b1;
        #1; check_reset;
        @(negedge S_clk); S_reset = 1'b0;
        @(posedge S_clk); #1;
        if ({S_fs, S_ls, S_de} !== 3'b110 || S_rgb !== 0) begin
            $display("FAIL: video restart at raster origin"); $stop;
        end
        wait (S_small_done && S_one_done);
        S_test_pass = 1'b1;
        $display("PASS: P0 video raster, four full-frame patterns, mode latch and reset");
        $finish;
    end
    initial begin
        #100000000;
        $display("FAIL: P0 video timeout"); $stop;
    end
endmodule

module video_timing_case #(
    parameter integer HSA=1, HBP=1, HA=3, HFP=1, VSA=1, VBP=1, VA=2, VFP=1,
    parameter POL=1'b1
) (output reg O_done);
    localparam HT = HSA+HBP+HA+HFP, VT = VSA+VBP+VA+VFP;
    reg S_clk = 1'b0;
    reg S_reset = 1'b0;
    wire S_hs, S_vs, S_de, S_fs, S_ls;
    wire [15:0] S_x, S_y;
    integer S_f, S_h, S_v, S_ex, S_ey;
    reg S_ed;
    always #20 S_clk = ~S_clk;
    video_timing #(.HTOTAL(HT), .HSA(HSA), .HBP(HBP), .HACTIVE(HA), .HFP(HFP),
        .VTOTAL(VT), .VSA(VSA), .VBP(VBP), .VACTIVE(VA), .VFP(VFP),
        .HS_POL(POL), .VS_POL(POL)) u_dut (
        .I_clk(S_clk), .I_reset(S_reset), .O_hsync(S_hs), .O_vsync(S_vs),
        .O_de(S_de), .O_x(S_x), .O_y(S_y), .O_frame_start(S_fs), .O_line_start(S_ls), .O_raster_x(), .O_raster_y()
    );
    initial begin
        O_done = 1'b0;
        #1; S_reset = 1'b1;
        #1;
        if ({S_hs, S_vs} !== {~POL, ~POL} || S_de !== 0 || S_fs !== 0 || S_ls !== 0) begin
            $display("FAIL in %m: timing reset polarity"); $stop;
        end
        @(negedge S_clk); S_reset = 1'b0;
        // Observe each raster cycle before its counter-advancing edge.
        for (S_f = 0; S_f < 2; S_f = S_f + 1)
            for (S_v = 0; S_v < VT; S_v = S_v + 1)
                for (S_h = 0; S_h < HT; S_h = S_h + 1) begin
                    #1;
                    S_ed = S_h >= HSA+HBP && S_h < HSA+HBP+HA &&
                           S_v >= VSA+VBP && S_v < VSA+VBP+VA;
                    S_ex = 0; S_ey = 0;
                    if (S_ed) begin S_ex = S_h-HSA-HBP; S_ey = S_v-VSA-VBP; end
                    if (S_hs !== (S_h < HSA ? POL : ~POL) ||
                        S_vs !== (S_v < VSA ? POL : ~POL) || S_de !== S_ed ||
                        S_x !== S_ex || S_y !== S_ey || S_fs !== (S_h == 0 && S_v == 0) ||
                        S_ls !== (S_h == 0)) begin
                        $display("FAIL in %m: timing geometry at %0d,%0d", S_h, S_v); $stop;
                    end
                    @(negedge S_clk);
                end
        O_done = 1'b1;
    end
endmodule
