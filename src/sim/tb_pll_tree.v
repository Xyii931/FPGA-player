`timescale 1ns/1ps
module tb_pll_tree;
    reg S_refclk = 1'b0;
    reg S_pll_reset = 1'b0;
    reg S_global_reset = 1'b0;
    reg S_media_safe = 1'b0;
    reg S_test_pass = 1'b0;
    reg S_check_periods = 1'b0;
    wire S_clk100, S_clk125, S_clk125s, S_clk25, S_clk5x;
    wire S_sys_lock, S_video_lock;
    wire S_rst_sys, S_rst_mem, S_rst_media, S_rst_sd, S_rst_video;
    wire [4:0] S_resets;
    integer S_i;
    always #10 S_refclk = ~S_refclk;
    assign S_resets = {S_rst_sys, S_rst_mem, S_rst_media, S_rst_sd, S_rst_video};

    pll_tree u_tree (
        .I_clk_50m(S_refclk), .I_pll_reset(S_pll_reset),
        .O_sd_card_clk(S_clk100), .O_ext_mem_clk(S_clk125),
        .O_ext_mem_clk_sft(S_clk125s), .O_video_clk(S_clk25),
        .O_hdmi_5x_clk(S_clk5x), .O_sys_pll_locked(S_sys_lock),
        .O_video_pll_locked(S_video_lock)
    );
    reset_gen #(.POR_COUNTER_BITS(3)) u_reset (
        .I_clk_50m(S_refclk), .I_clk_100m(S_clk100),
        .I_clk_125m(S_clk125), .I_clk_25m(S_clk25),
        .I_sys_pll_locked(S_sys_lock), .I_video_pll_locked(S_video_lock),
        .I_global_reset(S_global_reset), .I_media_reset_safe(S_media_safe),
        .O_reset_sys(S_rst_sys), .O_reset_mem(S_rst_mem),
        .O_reset_media(S_rst_media), .O_reset_sd_media(S_rst_sd),
        .O_reset_video(S_rst_video)
    );

    // Check all five output routes, not hardware PLL accuracy.
    pll_tree_period_check #(10) u_p100(S_clk100, S_check_periods);
    pll_tree_period_check #(8) u_p125(S_clk125, S_check_periods);
    pll_tree_period_check #(8) u_p125s(S_clk125s, S_check_periods);
    pll_tree_period_check #(40) u_p25(S_clk25, S_check_periods);
    pll_tree_period_check #(8) u_p5x(S_clk5x, S_check_periods);

    pll_tree_reset_check u_rsys(S_clk100,
        u_reset.S_por_hold | S_global_reset | ~S_sys_lock, S_rst_sys);
    pll_tree_reset_check u_rmem(S_clk125,
        u_reset.S_por_hold | S_global_reset | ~S_sys_lock, S_rst_mem);
    pll_tree_reset_check u_rmedia(S_clk125,
        u_reset.S_por_hold | S_global_reset | ~S_sys_lock | S_media_safe, S_rst_media);
    pll_tree_reset_check u_rsd(S_clk100,
        u_reset.S_por_hold | S_global_reset | ~S_sys_lock | S_media_safe, S_rst_sd);
    pll_tree_reset_check u_rvideo(S_clk25,
        u_reset.S_por_hold | S_global_reset | ~S_video_lock, S_rst_video);

    // Reference/reset fanout and lock/clock routing must remain direct.
    always @(S_refclk or S_pll_reset or S_sys_lock or S_video_lock or
             S_clk100 or S_clk125 or S_clk125s or S_clk25 or S_clk5x) begin
        #0.001;
        if ({u_tree.u_sys.I_refclk, u_tree.u_video.I_refclk,
             u_tree.u_sys.I_reset, u_tree.u_video.I_reset} !==
            {S_refclk, S_refclk, S_pll_reset, S_pll_reset} ||
            {S_sys_lock, S_video_lock, S_clk100, S_clk125, S_clk125s, S_clk25, S_clk5x} !==
            {u_tree.u_sys.O_locked, u_tree.u_video.O_locked,
             u_tree.u_sys.O_clk_100m, u_tree.u_sys.O_clk_125m,
             u_tree.u_sys.O_clk_125m_sft, u_tree.u_video.O_clk_25m,
             u_tree.u_video.O_clk_125m}) begin
            $display("FAIL: pll_tree port routing");
            $stop;
        end
    end

    task check;
        input [4:0] expected;
        begin
            if (S_resets !== expected) begin
                $display("FAIL at %0t: expected %b, got %b", $time, expected, S_resets);
                $stop;
            end
        end
    endtask
    task settle;
        begin
            repeat (12) @(posedge S_refclk);
            #1;
        end
    endtask

    initial begin
        // Explicit edge avoids relying on time-zero PLL reset initialization.
        #1; S_pll_reset = 1'b1;
        #1; check(5'b11111);
        repeat (3) @(posedge S_refclk);
        #1;
        if ({S_sys_lock, S_video_lock} !== 2'b00) begin
            $display("FAIL: PLL reset did not clear both locks"); $stop;
        end
        S_pll_reset = 1'b0;
        for (S_i = 1; S_i <= 6; S_i = S_i + 1) begin
            @(posedge S_refclk); #1;
            if ({S_sys_lock, S_video_lock} !== {S_i >= 4, S_i >= 6}) begin
                $display("FAIL: model lock delay/fanout at edge %0d", S_i); $stop;
            end
        end
        settle; check(5'b00000);
        S_check_periods = 1'b1;
        settle;

        // Media/global business reset must not reset either PLL.
        S_media_safe = 1'b1;
        #1; check(5'b00110);
        settle; check(5'b00110);
        S_media_safe = 1'b0;
        settle; check(5'b00000);
        S_global_reset = 1'b1;
        #1; check(5'b11111);
        settle;
        if ({S_sys_lock, S_video_lock} !== 2'b11) begin
            $display("FAIL: business reset disturbed PLL lock"); $stop;
        end
        S_global_reset = 1'b0;
        settle; check(5'b00000);

        // Lock loss while output clocks still run must affect only that PLL's domains.
        u_tree.u_sys.S_unlock = 1'b1;
        #1; check(5'b11110);
        settle; check(5'b11110);
        u_tree.u_sys.S_unlock = 1'b0;
        settle; check(5'b00000);
        u_tree.u_video.S_unlock = 1'b1;
        #1; check(5'b00001);
        settle; check(5'b00001);
        u_tree.u_video.S_unlock = 1'b0;
        settle; check(5'b00000);
        S_check_periods = 1'b0;

        // Stop clocks BEFORE lock falls. Re-lock alone cannot release reset.
        u_tree.u_sys.S_stop = 1'b1;
        #2; u_tree.u_sys.S_unlock = 1'b1;
        #1; check(5'b11110);
        settle; check(5'b11110);
        u_tree.u_sys.S_unlock = 1'b0;
        settle; check(5'b11110);
        if (S_sys_lock !== 1'b1) begin
            $display("FAIL: system model failed to re-lock"); $stop;
        end
        u_tree.u_sys.S_stop = 1'b0;
        settle; check(5'b00000);

        u_tree.u_video.S_stop = 1'b1;
        #2; u_tree.u_video.S_unlock = 1'b1;
        #1; check(5'b00001);
        settle; check(5'b00001);
        u_tree.u_video.S_unlock = 1'b0;
        settle; check(5'b00001);
        if (S_video_lock !== 1'b1) begin
            $display("FAIL: video model failed to re-lock"); $stop;
        end
        u_tree.u_video.S_stop = 1'b0;
        settle; check(5'b00000);

        // Independent external PLL reset clears both locks and all domains.
        #2; S_pll_reset = 1'b1;
        #1; check(5'b11111);
        if ({S_sys_lock, S_video_lock} !== 2'b00) begin
            $display("FAIL: runtime PLL reset"); $stop;
        end
        settle;
        S_pll_reset = 1'b0;
        settle; check(5'b00000);
        S_test_pass = 1'b1;
        $display("PASS: pll_tree wiring/reset integration using ideal PLL substitutes");
        $finish;
    end
    initial begin
        #20000;
        $display("FAIL: pll_tree integration timeout"); $stop;
    end
endmodule

module pll_tree_period_check #(parameter integer PERIOD_NS = 10) (
    input wire I_clk, input wire I_enable
);
    time S_last_edge;
    reg S_seen = 1'b0;
    always @(posedge I_clk or negedge I_enable) begin
        if (!I_enable) S_seen = 1'b0;
        else begin
            if (S_seen && $time - S_last_edge != PERIOD_NS) begin
                $display("FAIL in %m: ideal clock output period"); $stop;
            end
            S_last_edge = $time;
            S_seen = 1'b1;
        end
    end
endmodule

module pll_tree_reset_check (
    input wire I_clk, input wire I_cause, input wire I_reset
);
    integer S_edges = 0;
    time S_last_edge;
    always @(posedge I_clk) S_last_edge = $time;
    always @(posedge I_clk or posedge I_cause) begin
        if (I_cause) S_edges = 0;
        else if (S_edges < 2) S_edges = S_edges + 1;
        #0.001;
        if (I_reset !== (I_cause || S_edges < 2)) begin
            $display("FAIL at %0t in %m: reset assertion/release timing", $time); $stop;
        end
    end
    always @(negedge I_reset) begin
        if ($time != S_last_edge) begin
            $display("FAIL in %m: reset release outside rising edge"); $stop;
        end
    end
endmodule
