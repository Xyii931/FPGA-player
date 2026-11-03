// Source: lab_ex5_i2s HDMI transmitter wrapper + hdmi_phy_warpper.v, unchanged.
// True scanout/PCM/ACR inputs. Vendor core scheduling and board timing unverified.
module player_hdmi (
    input wire I_video_clk,I_serial_clk,I_reset,I_hpd,
    input wire I_de,I_valid,
    input wire [15:0] I_x,I_y,
    input wire [23:0] I_rgb,
    input wire I_audio_valid,
    input wire [23:0] I_audio_left,I_audio_right,
    input wire I_acr_valid,
    input wire [19:0] I_acr_n,I_acr_cts,
    output wire O_hdmi_clk_p,O_hdmi_d0_p,O_hdmi_d1_p,O_hdmi_d2_p,
    output wire O_hdmi_scl,
    inout wire IO_hdmi_sda,
    output wire O_locked,O_bridge_fault,O_sink_reset,
    output wire [31:0] O_restart_count
);
    reg S_hpd_meta,S_hpd_sync;
    wire S_output_reset;
    wire S_axis_ready,S_axis_valid,S_axis_user,S_axis_last;
    wire [23:0] S_axis_data;
    wire [11:0] S_level;
    wire [9:0] S_ch0,S_ch1,S_ch2,S_chclk;
    reg [16:0] S_edid_count;
    reg S_edid_sent,S_edid_trigger;
    wire S_edid_valid;
    wire [7:0] S_edid_data;
    always @(posedge I_video_clk or posedge I_reset) begin
        if(I_reset) begin S_hpd_meta<=0; S_hpd_sync<=0; end
        else begin S_hpd_meta<=I_hpd; S_hpd_sync<=S_hpd_meta; end
    end
    scanout_axis_bridge u_axis (
        .I_clk(I_video_clk),.I_reset(I_reset || !S_hpd_sync),
        .I_de(I_de),.I_valid(I_valid),.I_x(I_x),.I_y(I_y),.I_rgb(I_rgb),
        .I_ready(S_axis_ready),.O_valid(S_axis_valid),.O_user(S_axis_user),
        .O_last(S_axis_last),.O_data(S_axis_data),.O_sink_reset(S_output_reset),
        .O_fault(O_bridge_fault),.O_restart_count(O_restart_count),.O_level(S_level)
    );
    assign O_sink_reset=S_output_reset;
    always @(posedge I_video_clk or posedge S_output_reset) begin
        if(S_output_reset) begin S_edid_count<=0; S_edid_sent<=0; S_edid_trigger<=0; end
        else begin
            S_edid_trigger<=0;
            if(!S_edid_sent) begin
                if(S_edid_count==17'd99999) begin S_edid_sent<=1; S_edid_trigger<=1; end
                else S_edid_count<=S_edid_count+1'b1;
            end
        end
    end
    hdmi_1_4b_transmitter_core_wrapper #(
        .DEVICE("EG"),.HTOTAL(800),.HSA(96),.HFP(16),.HBP(48),.HACTIVE(640),
        .VTOTAL(525),.VSA(2),.VFP(10),.VBP(33),.VACTIVE(480),
        .VIDEO_VIC(1),.VIDEO_TPG("Disable"),.VIDEO_FORMAT("RGB"),
        .AUDIO_SAMPLE_RATE("48K"),.IIC_SCL_DIV(250)
    ) u_hdmi (
        .I_pixel_clk(I_video_clk),.I_rst(S_output_reset),
        .I_edid_read_trig(S_edid_trigger),.O_edid_read_valid(S_edid_valid),.O_edid_read_data(S_edid_data),
        .I_axis_s_user(S_axis_user),.I_axis_s_valid(S_axis_valid),.I_axis_s_last(S_axis_last),
        .I_axis_s_data(S_axis_data),.O_axis_s_ready(S_axis_ready),
        .I_audio_valid(I_audio_valid && !S_output_reset),
        .I_audio_left_data(I_audio_left),.I_audio_right_data(I_audio_right),
        .I_acr_valid(I_acr_valid && !S_output_reset),.I_acr_cts(I_acr_cts),.I_acr_n(I_acr_n),
        .O_video_locked(O_locked),.O_ddc_scl(O_hdmi_scl),.IO_ddc_sda(IO_hdmi_sda),
        .O_ch0_tmds_data(S_ch0),.O_ch1_tmds_data(S_ch1),.O_ch2_tmds_data(S_ch2),.O_clk_tmds_data(S_chclk)
    );
    hdmi_phy_wrapper #(.DEVICE("EG")) u_phy (
        .I_pixel_clk(I_video_clk),.I_serial_clk(I_serial_clk),.I_rst(S_output_reset),
        .I_tmds_channel_0(S_ch0),.I_tmds_channel_1(S_ch1),.I_tmds_channel_2(S_ch2),.I_tmds_channel_clk(S_chclk),
        .O_tmds_ch0_p(O_hdmi_d0_p),.O_tmds_ch1_p(O_hdmi_d1_p),
        .O_tmds_ch2_p(O_hdmi_d2_p),.O_tmds_clk_p(O_hdmi_clk_p)
    );
endmodule
