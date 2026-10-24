// Board diagnostic only: KEY1 hold resets immediately; SW1/2 select a pattern.
// Reuses the reference encrypted HDMI IP and PHY unchanged, with attribution in
// src/td_project/README.md. No TF, SDRAM, Flash, audio or final application UI.
module p0_hdmi_top (
    input wire I_clk_50m,
    input wire I_key_reset_n,
    input wire [1:0] I_pattern_sw,
    output wire [3:0] O_led,
    output wire O_hdmi_clk_p, O_hdmi_d0_p, O_hdmi_d1_p, O_hdmi_d2_p,
    output wire O_hdmi_scl,
    inout wire IO_hdmi_sda
);
    reg [3:0] S_pll_start_count;
    reg S_pll_started;
    wire S_pll_reset = ~S_pll_started;
    wire S_clk100, S_clk125, S_clk125s, S_clk25, S_clk5x;
    wire S_sys_lock, S_video_lock, S_video_reset;
    wire S_rst_sys, S_rst_mem, S_rst_media, S_rst_sd;
    wire S_ready, S_valid, S_user, S_last, S_core_locked;
    wire [23:0] S_data;
    wire [9:0] S_ch0, S_ch1, S_ch2, S_chclk;
    reg [1:0] S_sw_meta, S_sw_sync, S_sw_candidate, S_pattern;
    reg [9:0] S_sw_stable_count;
    reg [23:0] S_heartbeat;
    reg [16:0] S_edid_count;
    reg S_edid_sent, S_edid_trig;
    wire S_edid_valid;
    wire [7:0] S_edid_data;
    // Independent one-shot: no reset_gen/lock feedback into the PLL reset pin.
    // Initial-state mapping MUST be verified in TD and on the board.
    initial begin
        S_pll_start_count = 4'd0;
        S_pll_started = 1'b0;
    end
    always @(posedge I_clk_50m) begin
        if (!S_pll_started) begin
            if (&S_pll_start_count) S_pll_started <= 1'b1;
            else S_pll_start_count <= S_pll_start_count + 1'b1;
        end
    end
    pll_tree u_pll_tree (
        .I_clk_50m(I_clk_50m), .I_pll_reset(S_pll_reset),
        .O_sd_card_clk(S_clk100), .O_ext_mem_clk(S_clk125),
        .O_ext_mem_clk_sft(S_clk125s), .O_video_clk(S_clk25),
        .O_hdmi_5x_clk(S_clk5x), .O_sys_pll_locked(S_sys_lock),
        .O_video_pll_locked(S_video_lock)
    );
    reset_gen u_reset (
        .I_clk_50m(I_clk_50m), .I_clk_100m(S_clk100), .I_clk_125m(S_clk125),
        .I_clk_25m(S_clk25), .I_sys_pll_locked(S_sys_lock),
        .I_video_pll_locked(S_video_lock), .I_global_reset(~I_key_reset_n),
        .I_media_reset_safe(1'b0), .O_reset_sys(S_rst_sys), .O_reset_mem(S_rst_mem),
        .O_reset_media(S_rst_media), .O_reset_sd_media(S_rst_sd),
        .O_reset_video(S_video_reset)
    );
    // Slow physical switches: synchronize, then accept only a stable whole vector.
    always @(posedge S_clk25 or posedge S_video_reset) begin
        if (S_video_reset) begin
            S_sw_meta <= 2'd0;
            S_sw_sync <= 2'd0;
            S_sw_candidate <= 2'd0;
            S_pattern <= 2'd0;
            S_sw_stable_count <= 10'd0;
        end else begin
            S_sw_meta <= I_pattern_sw;
            S_sw_sync <= S_sw_meta;
            if (S_sw_sync != S_sw_candidate) begin
                S_sw_candidate <= S_sw_sync;
                S_sw_stable_count <= 10'd0;
            end else if (&S_sw_stable_count) S_pattern <= S_sw_candidate;
            else S_sw_stable_count <= S_sw_stable_count + 1'b1;
        end
    end
    always @(posedge S_clk25 or posedge S_video_reset) begin
        if (S_video_reset) begin
            S_heartbeat <= 24'd0;
            S_edid_count <= 17'd0;
            S_edid_sent <= 1'b0;
            S_edid_trig <= 1'b0;
        end else begin
            S_heartbeat <= S_heartbeat + 1'b1;
            S_edid_trig <= 1'b0;
            if (!S_edid_sent) begin
                if (S_edid_count == 17'd99999) begin
                    S_edid_sent <= 1'b1;
                    S_edid_trig <= 1'b1;
                end else S_edid_count <= S_edid_count + 1'b1;
            end
        end
    end
    assign O_led = ~{S_heartbeat[23], S_core_locked, S_video_lock, S_sys_lock};
    video_pattern_axis u_pattern (
        .I_clk(S_clk25), .I_reset(S_video_reset), .I_pattern(S_pattern),
        .I_ready(S_ready), .O_valid(S_valid), .O_user(S_user),
        .O_last(S_last), .O_data(S_data)
    );
    hdmi_1_4b_transmitter_core_wrapper #(
        .DEVICE("EG"), .HTOTAL(800), .HSA(96), .HFP(16), .HBP(48), .HACTIVE(640),
        .VTOTAL(525), .VSA(2), .VFP(10), .VBP(33), .VACTIVE(480),
        .VIDEO_VIC(1), .VIDEO_TPG("Disable"), .VIDEO_FORMAT("RGB"),
        .AUDIO_SAMPLE_RATE("48K"), .IIC_SCL_DIV(250)
    ) u_hdmi (
        .I_pixel_clk(S_clk25), .I_rst(S_video_reset),
        .I_edid_read_trig(S_edid_trig), .O_edid_read_valid(S_edid_valid),
        .O_edid_read_data(S_edid_data), .I_axis_s_user(S_user),
        .I_axis_s_valid(S_valid), .I_axis_s_last(S_last), .I_axis_s_data(S_data),
        .O_axis_s_ready(S_ready), .I_audio_valid(1'b0),
        .I_audio_left_data(24'd0), .I_audio_right_data(24'd0),
        .I_acr_valid(1'b0), .I_acr_cts(20'd25000), .I_acr_n(20'd6144),
        .O_video_locked(S_core_locked), .O_ddc_scl(O_hdmi_scl),
        .IO_ddc_sda(IO_hdmi_sda), .O_ch0_tmds_data(S_ch0), .O_ch1_tmds_data(S_ch1),
        .O_ch2_tmds_data(S_ch2), .O_clk_tmds_data(S_chclk)
    );
    hdmi_phy_wrapper #(.DEVICE("EG")) u_phy (
        .I_pixel_clk(S_clk25), .I_serial_clk(S_clk5x), .I_rst(S_video_reset),
        .I_tmds_channel_0(S_ch0), .I_tmds_channel_1(S_ch1),
        .I_tmds_channel_2(S_ch2), .I_tmds_channel_clk(S_chclk),
        .O_tmds_ch0_p(O_hdmi_d0_p), .O_tmds_ch1_p(O_hdmi_d1_p),
        .O_tmds_ch2_p(O_hdmi_d2_p), .O_tmds_clk_p(O_hdmi_clk_p)
    );
endmodule
