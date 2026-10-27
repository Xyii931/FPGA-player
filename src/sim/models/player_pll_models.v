`timescale 1ns/1ps
// SIMULATION ONLY. Compile instead of src/ip/player_*_pll.v, never alongside it.
// Ideal oscillators and programmable lock/stop behavior, NOT Anlogic models.
// No claims about real PLL frequency, phase, jitter, reset or acquisition timing.
module player_sys_pll (
    input wire I_refclk,
    input wire I_reset,
    output wire O_clk_100m,
    output wire O_clk_125m,
    output wire O_clk_125m_sft,
    output wire O_locked
);
    // Testbench controls, absent from synthesis interfaces.
    reg S_stop = 1'b0;
    reg S_unlock = 1'b0;
    reg S_clk0 = 1'b0;
    reg S_clk1 = 1'b0;
    always #5 if (!S_stop && !I_reset) S_clk0 = ~S_clk0;
    always #5 if (!S_stop && !I_reset) S_clk1 = ~S_clk1;
    assign O_clk_100m = S_clk0;
    assign O_clk_125m = S_clk1;
    assign O_clk_125m_sft = ~S_clk1;
    player_pll_lock_model #(.LOCK_EDGES(4)) u_lock (
        .I_refclk(I_refclk), .I_reset(I_reset | S_unlock),
        .O_locked(O_locked)
    );
endmodule

module player_video_pll (
    input wire I_refclk,
    input wire I_reset,
    output wire O_clk_25m,
    output wire O_clk_125m,
    output wire O_locked
);
    reg S_stop = 1'b0;
    reg S_unlock = 1'b0;
    reg S_clk0 = 1'b0;
    reg S_clk1 = 1'b0;
    always #20 if (!S_stop && !I_reset) S_clk0 = ~S_clk0;
    always #4 if (!S_stop && !I_reset) S_clk1 = ~S_clk1;
    assign O_clk_25m = S_clk0;
    assign O_clk_125m = S_clk1;
    player_pll_lock_model #(.LOCK_EDGES(6)) u_lock (
        .I_refclk(I_refclk), .I_reset(I_reset | S_unlock),
        .O_locked(O_locked)
    );
endmodule

module player_pll_lock_model #(
    parameter integer LOCK_EDGES = 4
) (
    input wire I_refclk,
    input wire I_reset,
    output reg O_locked
);
    integer S_count;
    // Caller must assert reset explicitly at startup.
    always @(posedge I_refclk or posedge I_reset) begin
        if (I_reset) begin
            S_count <= 0;
            O_locked <= 1'b0;
        end else if (!O_locked) begin
            if (S_count == LOCK_EDGES - 1)
                O_locked <= 1'b1;
            else
                S_count <= S_count + 1;
        end
    end
endmodule
