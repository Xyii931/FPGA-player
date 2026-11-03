// Wiring only. I_pll_reset must not be derived from reset_gen or lost lock.
module pll_tree (
    input  wire I_clk_50m,
    input  wire I_pll_reset,
    output wire O_sd_card_clk,
    output wire O_ext_mem_clk,
    output wire O_ext_mem_clk_sft,
    output wire O_video_clk,
    output wire O_hdmi_5x_clk,
    output wire O_sys_pll_locked,
    output wire O_video_pll_locked
);
    player_sys_pll u_sys (
        .I_refclk(I_clk_50m), .I_reset(I_pll_reset),
        .O_clk_100m(O_sd_card_clk), .O_clk_125m(O_ext_mem_clk),
        .O_clk_125m_sft(O_ext_mem_clk_sft), .O_locked(O_sys_pll_locked)
    );
    player_video_pll u_video (
        .I_refclk(I_clk_50m), .I_reset(I_pll_reset),
        .O_clk_25m(O_video_clk), .O_clk_125m(O_hdmi_5x_clk),
        .O_locked(O_video_pll_locked)
    );
endmodule
