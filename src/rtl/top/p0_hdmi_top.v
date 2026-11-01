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
    inout wire IO_hdmi_sda,
    // SD read diagnostic: sector 0 read result is shown as a solid colour.
    output wire O_tf_ncs, O_tf_sclk, O_tf_mosi,
    input wire I_tf_miso
);
    reg [3:0] S_pll_start_count;
    reg S_pll_started;
    wire S_pll_reset = ~S_pll_started;
    wire S_clk100, S_clk125, S_clk125s, S_clk25, S_clk5x;
    wire S_sys_lock, S_video_lock, S_video_reset;
    wire S_rst_sys, S_rst_mem, S_rst_media, S_rst_sd;
    wire S_ready, S_valid, S_user, S_last, S_core_locked;
    wire [23:0] S_data;
    wire [23:0] S_pat_data;
    reg [23:0] S_test_color;
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
    // Raster-driven source: matches the proven vendor reference handshake
    // (color_bar + video_rgb_to_axis_640x480), where valid follows the active
    // window and O_axis_s_ready is not used. The previous ready-paced source
    // held valid high forever and left the core without per-line valid gaps.
    video_pattern_raster #(
        .ACTIVE_W(640), .ACTIVE_H(480),
        .HTOTAL(800), .VTOTAL(525), .HSTART(160), .VSTART(45)
    ) u_pattern (
        .I_clk(S_clk25), .I_reset(S_video_reset), .I_pattern(S_pattern),
        .O_valid(S_valid), .O_user(S_user),
        .O_last(S_last), .O_data(S_pat_data)
    );
    // SD diagnostic build: the pattern is replaced by a solid status colour.
    assign S_data = S_test_color;
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

    // ------------------------------------------------------------------
    // SD sector-0 read diagnostic through the same fat32_sector_port the
    // player's mount uses.
    //   blue   = waiting for card_ready
    //   yellow = request sent, waiting for the port result
    //   green  = result, no error
    //   red    = result with a non-zero port error code
    // ------------------------------------------------------------------
    wire S_card, S_port_start, S_port_ready, S_port_result;
    wire [7:0] S_port_error;
    wire [3:0] S_port_storage;
    wire S_req_valid, S_req_ready;
    wire [31:0] S_req_lba;
    wire [7:0] S_req_count;
    wire [1:0] S_req_context, S_req_priority;
    wire [15:0] S_req_tag;
    wire S_byte_valid, S_sector_last, S_req_last, S_done_valid;
    wire [7:0] S_byte;
    wire [1:0] S_byte_ctx, S_done_ctx;
    wire [15:0] S_byte_tag, S_done_tag;
    wire [3:0] S_done_error;
    wire [32:0] S_capacity;
    wire S_port_byte_ready, S_port_done_ready;
    wire [1:0] S_port_state;
    wire [1:0] S_port_match;
    reg [1:0] S_sd_state;
    reg S_start_r;
    reg [7:0] S_sd_error;
    reg S_done_dbg;
    reg S_m_mounted_r;

    sd_storage #(.WORK_DIVIDER(16'd250)) u_sd (
        .I_host_clk(S_clk125), .I_sd_clk(S_clk100), .I_async_reset(S_rst_mem),
        .I_request_valid(S_req_valid), .O_request_ready(S_req_ready),
        .I_lba(S_req_lba), .I_count(S_req_count), .I_context(S_req_context),
        .I_priority(S_req_priority), .I_tag(S_req_tag), .I_urgent_context(3'd0),
        .O_byte_valid(S_byte_valid), .I_byte_ready(S_port_byte_ready), .O_byte_data(S_byte),
        .O_sector_last(S_sector_last), .O_request_last(S_req_last),
        .O_byte_context(S_byte_ctx), .O_byte_tag(S_byte_tag),
        .O_done_valid(S_done_valid), .I_done_ready(S_port_done_ready),
        .O_done_context(S_done_ctx), .O_done_tag(S_done_tag), .O_done_error(S_done_error),
        .I_cancel_valid(1'b0), .O_cancel_ready(), .I_cancel_context(2'd0), .I_cancel_tag(16'd0),
        .O_cancel_done_valid(), .I_cancel_done_ready(1'b0),
        .O_cancel_done_context(), .O_cancel_done_tag(),
        .O_card_ready(S_card), .O_capacity_sectors(S_capacity),
        .O_sd_ncs(O_tf_ncs), .O_sd_sclk(O_tf_sclk), .O_sd_mosi(O_tf_mosi), .I_sd_miso(I_tf_miso),
        .O_card_present(), .O_sd_high_capacity(), .O_sd_card_error()
    );

    wire S_m_read, S_m_take, S_m_sresult, S_m_mounted;
    wire S_m_start_ready;
    wire [31:0] S_m_lba;
    wire [8:0] S_m_addr;
    wire [7:0] S_m_data, S_m_error;
    wire [3:0] S_m_storage;

    fat32_sector_port u_port (
        .I_clk(S_clk125), .I_reset(S_rst_mem), .I_card_ready(S_card),
        .I_start_valid(S_m_read), .O_start_ready(S_port_ready), .I_lba(S_m_lba),
        .I_context(2'd0), .I_priority(2'd0), .I_abort(1'b0),
        .O_result_valid(S_port_result), .I_result_ready(S_m_take),
        .O_error(S_port_error), .O_storage_error(S_port_storage),
        .I_buffer_address(S_m_addr), .O_buffer_data(S_m_data),
        .O_dbg_state(S_port_state), .O_dbg_match(S_port_match),
        .O_request_valid(S_req_valid), .I_request_ready(S_req_ready),
        .O_lba(S_req_lba), .O_count(S_req_count), .O_context(S_req_context),
        .O_priority(S_req_priority), .O_tag(S_req_tag),
        .I_byte_valid(S_byte_valid), .O_byte_ready(S_port_byte_ready), .I_byte_data(S_byte),
        .I_sector_last(S_sector_last), .I_request_last(S_req_last),
        .I_byte_context(S_byte_ctx), .I_byte_tag(S_byte_tag),
        .I_done_valid(S_done_valid), .O_done_ready(S_port_done_ready),
        .I_done_context(S_done_ctx), .I_done_tag(S_done_tag), .I_done_error(S_done_error),
        .O_cancel_valid(), .I_cancel_ready(1'b0), .O_cancel_context(), .O_cancel_tag(),
        .I_cancel_done_valid(1'b0), .O_cancel_done_ready(),
        .I_cancel_done_context(2'd0), .I_cancel_done_tag(16'd0)
    );

    fat32_mount u_mount (
        .I_clk(S_clk125), .I_reset(S_rst_mem), .I_card_ready(S_card),
        .I_capacity_sectors(S_capacity),
        .I_start_valid(S_start_r), .O_start_ready(S_m_start_ready),
        .O_result_valid(S_m_sresult), .I_result_ready(S_sd_state==2'd2),
        .O_error(S_m_error), .O_storage_error(S_m_storage), .O_mounted(S_m_mounted),
        .O_fat_lba(), .O_data_lba(), .O_cluster_count(), .O_root_cluster(),
        .O_cluster_shift(), .O_sectors_per_cluster(),
        .O_read_valid(S_m_read), .I_read_ready(S_port_ready), .O_read_lba(S_m_lba),
        .I_read_result_valid(S_port_result), .I_read_error(S_port_error),
        .I_storage_error(S_port_storage), .O_read_result_ready(S_m_take),
        .O_buffer_address(S_m_addr), .I_buffer_data(S_m_data)
    );


    always @(posedge S_clk125 or posedge S_rst_mem) begin
        if (S_rst_mem) begin
            S_sd_state <= 2'd0;
            S_start_r <= 1'b0;
            S_sd_error <= 8'd0;
            S_m_mounted_r <= 1'b0;
        end else begin
            case (S_sd_state)
                2'd0: if (S_card) begin
                    S_start_r <= 1'b1;
                    S_sd_state <= 2'd1;
                end
                2'd1: if (S_m_start_ready) S_sd_state <= 2'd2;
                2'd2: if (S_m_sresult) begin
                    S_sd_error <= S_m_error;
                    S_m_mounted_r <= S_m_mounted;
                    S_sd_state <= 2'd3;
                end
                default: ;
            endcase
        end
    end

    always @(posedge S_clk125 or posedge S_rst_mem) begin
        if (S_rst_mem) S_done_dbg <= 1'b0;
        else if (S_done_valid) S_done_dbg <= 1'b1;
    end

    always @* begin
        if (S_sd_state == 2'd3)
            S_test_color = (S_sd_error != 0) ? 24'hff0000 :
                (S_m_mounted_r ? 24'h00ff00 : 24'hff00ff);
        else if (S_sd_state == 2'd0) S_test_color = 24'h0000ff;
        else S_test_color = 24'hffff00;
    end
endmodule

// ---------------------------------------------------------------------------
// Pattern source for the HDMI core.
//
// Kept in this file on purpose: TD rewrites p0_hdmi.al from its own in-memory
// file list and drops source entries it did not open itself, which turned a
// separate video_pattern_raster.v into a "black box". Defining the module in
// an always-compiled file avoids that project-file fragility entirely.
//
// Timing follows the proven vendor reference (lab_ex5_i2s color_bar):
//   H_TOTAL = 640 + 16(FP) + 96(SYNC) + 48(BP) = 800
//   V_TOTAL = 480 + 10(FP) +  2(SYNC) + 33(BP) = 525
//   active window: h = 160..799, v = 45..524
// I_axis_s_valid is asserted only inside the active window (like DE) and
// O_axis_s_ready is deliberately unused, exactly as in the reference design.
// ---------------------------------------------------------------------------
module video_pattern_raster #(
    parameter integer ACTIVE_W = 640,
    parameter integer ACTIVE_H = 480,
    parameter integer HTOTAL   = 800,
    parameter integer VTOTAL   = 525,
    parameter integer HSTART   = 160,
    parameter integer VSTART   = 45
) (
    input  wire        I_clk,
    input  wire        I_reset,
    input  wire [1:0]  I_pattern,
    output wire        O_valid,
    output wire        O_user,
    output wire        O_last,
    output reg  [23:0] O_data
);
    localparam integer HEND = HSTART + ACTIVE_W;
    localparam integer VEND = VSTART + ACTIVE_H;

    // Exact floor(x*255/(W-1)) without a divider.
    localparam [16:0] GRAY_DENOM     = (ACTIVE_W > 1) ? ACTIVE_W-1 : 1;
    localparam [7:0]  GRAY_STEP      = 255 / GRAY_DENOM;
    localparam [15:0] GRAY_REMAINDER = 255 % GRAY_DENOM;

    reg [15:0] S_hc;
    reg [15:0] S_vc;
    reg [1:0]  S_pattern;
    reg [7:0]  S_gray;
    reg [15:0] S_gray_error;

    wire [16:0] S_gray_next = {1'b0, S_gray_error} + {1'b0, GRAY_REMAINDER};

    wire S_hactive = (S_hc >= HSTART) && (S_hc < HEND);
    wire S_vactive = (S_vc >= VSTART) && (S_vc < VEND);
    wire S_valid   = S_hactive && S_vactive;

    wire [15:0] S_x = S_hc - HSTART;
    wire [15:0] S_y = S_vc - VSTART;

    assign O_valid = S_valid;
    assign O_user  = S_valid && (S_x == 16'd0) && (S_y == 16'd0);
    assign O_last  = S_valid && (S_x == ACTIVE_W-1);

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_hc <= 16'd0;
            S_vc <= 16'd0;
            S_pattern <= 2'd0;
            S_gray <= 8'd0;
            S_gray_error <= 16'd0;
        end else begin
            if (S_hc == HTOTAL-1) begin
                S_hc <= 16'd0;
                if (S_vc == VTOTAL-1) S_vc <= 16'd0;
                else S_vc <= S_vc + 1'b1;
            end else begin
                S_hc <= S_hc + 1'b1;
            end

            // Latch the pattern select at the first active pixel of a frame.
            if (S_valid && S_x == 16'd0 && S_y == 16'd0)
                S_pattern <= I_pattern;

            // Gray ramp advances only with active pixels; restart each line.
            if (S_valid) begin
                if (S_x == ACTIVE_W-1) begin
                    S_gray <= 8'd0;
                    S_gray_error <= 16'd0;
                end else if (S_gray_next >= GRAY_DENOM) begin
                    S_gray <= S_gray + GRAY_STEP + 8'd1;
                    S_gray_error <= S_gray_next - GRAY_DENOM;
                end else begin
                    S_gray <= S_gray + GRAY_STEP;
                    S_gray_error <= S_gray_next[15:0];
                end
            end
        end
    end

    always @* begin
        O_data = 24'd0;
        if (S_valid) begin
            case (S_pattern)
                2'd0: begin
                    if      (S_x < (  ACTIVE_W+7)/8) O_data = 24'hffffff;
                    else if (S_x < (2*ACTIVE_W+7)/8) O_data = 24'hffff00;
                    else if (S_x < (3*ACTIVE_W+7)/8) O_data = 24'h00ffff;
                    else if (S_x < (4*ACTIVE_W+7)/8) O_data = 24'h00ff00;
                    else if (S_x < (5*ACTIVE_W+7)/8) O_data = 24'hff00ff;
                    else if (S_x < (6*ACTIVE_W+7)/8) O_data = 24'hff0000;
                    else if (S_x < (7*ACTIVE_W+7)/8) O_data = 24'h0000ff;
                end
                2'd1: O_data = {S_gray, S_gray, S_gray};
                2'd2: if (S_x == 0 || S_x == ACTIVE_W-1 || S_y == 0 ||
                          S_y == ACTIVE_H-1 || S_x == ACTIVE_W/2 || S_y == ACTIVE_H/2)
                    O_data = 24'hffffff;
                2'd3: O_data = (S_x[0] ^ S_y[0]) ? 24'hffffff : 24'h000000;
            endcase
        end
    end

    // synthesis translate_off
    initial begin
        if (ACTIVE_W < 1 || ACTIVE_H < 1 || ACTIVE_W > 65536 || ACTIVE_H > 65536 ||
            HSTART + ACTIVE_W > HTOTAL || VSTART + ACTIVE_H > VTOTAL) begin
            $display("FAIL: video_pattern_raster invalid geometry"); $stop;
        end
    end
    // synthesis translate_on
endmodule













