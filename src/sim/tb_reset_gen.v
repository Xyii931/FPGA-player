`timescale 1ns/1ps

module tb_reset_gen;
    reg S_clk_50m = 1'b0;
    reg S_clk_100m = 1'b0;
    reg S_clk_125m = 1'b0;
    reg S_clk_25m = 1'b0;
    reg S_run_sys = 1'b1;
    reg S_run_video = 1'b1;
    reg S_sys_lock = 1'b1;
    reg S_video_lock = 1'b1;
    reg S_global_reset = 1'b0;
    reg S_media_safe = 1'b0;
    reg S_test_pass = 1'b0;
    wire S_rst_sys, S_rst_mem, S_rst_media, S_rst_sd, S_rst_video;
    wire [4:0] S_resets;
    integer S_i;

    assign S_resets = {S_rst_sys, S_rst_mem, S_rst_media, S_rst_sd, S_rst_video};
    always #10 S_clk_50m = ~S_clk_50m;
    always #5 if (S_run_sys) S_clk_100m = ~S_clk_100m;
    always #4 if (S_run_sys) S_clk_125m = ~S_clk_125m;
    always #20 if (S_run_video) S_clk_25m = ~S_clk_25m;

    // Shortened POR for directed simulation: 16 edges, not the production 2**20.
    reset_gen #(.POR_COUNTER_BITS(4)) u_dut (
        .I_clk_50m(S_clk_50m), .I_clk_100m(S_clk_100m),
        .I_clk_125m(S_clk_125m), .I_clk_25m(S_clk_25m),
        .I_sys_pll_locked(S_sys_lock), .I_video_pll_locked(S_video_lock),
        .I_global_reset(S_global_reset), .I_media_reset_safe(S_media_safe),
        .O_reset_sys(S_rst_sys), .O_reset_mem(S_rst_mem),
        .O_reset_media(S_rst_media), .O_reset_sd_media(S_rst_sd),
        .O_reset_video(S_rst_video)
    );

    // Each checker independently counts destination edges after its cause clears.
    reset_gen_output_check u_check_sys (S_clk_100m,
        u_dut.S_por_hold | S_global_reset | ~S_sys_lock, S_rst_sys);
    reset_gen_output_check u_check_mem (S_clk_125m,
        u_dut.S_por_hold | S_global_reset | ~S_sys_lock, S_rst_mem);
    reset_gen_output_check u_check_media (S_clk_125m,
        u_dut.S_por_hold | S_global_reset | ~S_sys_lock | S_media_safe, S_rst_media);
    reset_gen_output_check u_check_sd (S_clk_100m,
        u_dut.S_por_hold | S_global_reset | ~S_sys_lock | S_media_safe, S_rst_sd);
    reset_gen_output_check u_check_video (S_clk_25m,
        u_dut.S_por_hold | S_global_reset | ~S_video_lock, S_rst_video);

    task check;
        input [4:0] expected;
        begin
            if (S_resets !== expected) begin
                $display("FAIL at %0t: expected resets %b, got %b",
                         $time, expected, S_resets);
                $stop;
            end
        end
    endtask

    task settle;
        begin
            repeat (6) @(posedge S_clk_50m);
            #1;
        end
    endtask

    initial begin
        #1; check(5'b11111);
        for (S_i = 1; S_i <= 16; S_i = S_i + 1) begin
            @(posedge S_clk_50m); #1;
            if (u_dut.S_por_hold !== (S_i < 16)) begin
                $display("FAIL: POR duration at 50 MHz edge %0d", S_i);
                $stop;
            end
            if (S_i < 16) check(5'b11111);
        end
        settle; check(5'b00000);

        // Media reset is isolated from sys, mem and video, including long holds.
        #2; S_media_safe = 1'b1;
        #1; check(5'b00110);
        settle; check(5'b00110);
        S_media_safe = 1'b0;
        settle; check(5'b00000);

        // Lost sys PLL: its clocks are stopped before lock falls.
        #2; S_run_sys = 1'b0;
        #2; S_sys_lock = 1'b0;
        #1; check(5'b11110);
        settle; check(5'b11110);
        S_sys_lock = 1'b1;
        settle; check(5'b11110);
        S_run_sys = 1'b1;
        settle; check(5'b00000);

        // Lost video PLL: system/media clocks continue unaffected.
        #2; S_run_video = 1'b0;
        #2; S_video_lock = 1'b0;
        #1; check(5'b00001);
        S_video_lock = 1'b1;
        settle; check(5'b00001);
        S_run_video = 1'b1;
        settle; check(5'b00000);

        // Global assertion while every PLL output is stopped.
        #2; S_run_sys = 1'b0; S_run_video = 1'b0;
        #2; S_global_reset = 1'b1;
        #1; check(5'b11111);
        S_global_reset = 1'b0;
        settle; check(5'b11111);
        S_run_sys = 1'b1; S_run_video = 1'b1;
        settle; check(5'b00000);
        if (u_dut.S_por_hold !== 1'b0) begin
            $display("FAIL: global reset restarted one-shot POR");
            $stop;
        end

        // Overlapping causes: releasing one must not clear the other.
        #2; S_global_reset = 1'b1; S_media_safe = 1'b1;
        #1; check(5'b11111);
        S_global_reset = 1'b0;
        settle; check(5'b00110);
        S_media_safe = 1'b0;
        settle; check(5'b00000);
        #2; S_sys_lock = 1'b0; S_video_lock = 1'b0;
        #1; check(5'b11111);
        S_sys_lock = 1'b1;
        settle; check(5'b00001);
        S_video_lock = 1'b1;
        settle; check(5'b00000);

        S_test_pass = 1'b1;
        $display("PASS: reset_gen directed scenarios completed");
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: reset_gen simulation timeout");
        $stop;
    end
endmodule

// Timing checker for default two-stage release; it does not inspect the pipe.
module reset_gen_output_check (
    input wire I_clk,
    input wire I_cause,
    input wire I_reset
);
    integer S_edges = 0;
    time S_last_edge;
    always @(posedge I_clk) S_last_edge = $time;
    always @(posedge I_clk or posedge I_cause) begin
        if (I_cause) S_edges = 0;
        else if (S_edges < 2) S_edges = S_edges + 1;
        #0.001;
        if (I_reset !== (I_cause || S_edges < 2)) begin
            $display("FAIL at %0t in %m: assertion/release timing", $time);
            $stop;
        end
    end
    always @(negedge I_reset) begin
        if ($time != S_last_edge) begin
            $display("FAIL at %0t in %m: release outside rising edge", $time);
            $stop;
        end
    end
endmodule
