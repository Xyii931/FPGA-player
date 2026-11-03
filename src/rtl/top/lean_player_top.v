// HX4S20 board entry: clocks, TF storage, SDRAM, player and HDMI output.
module lean_player_top (
    input wire I_clk_50m,
    input wire [3:0] I_key_n,I_switch,
    input wire I_tf_miso,I_hdmi_hpd,I_uart_rx,I_flash_miso,
    output wire O_uart_tx,
    output wire O_tf_ncs,O_tf_sclk,O_tf_mosi,
    output wire O_flash_cs_n,O_flash_sclk,O_flash_mosi,O_flash_wp_n,O_flash_hold_n,
    output wire [3:0] O_led,
    output wire O_hdmi_clk_p,O_hdmi_d0_p,O_hdmi_d1_p,O_hdmi_d2_p,
    output wire O_hdmi_scl,
    inout wire IO_hdmi_sda
);
    reg [3:0] S_pll_count;
    reg S_pll_started;
    wire S_pll_reset=!S_pll_started;
    wire S_clk100,S_clk125,S_clk125s,S_clk25,S_clk5x,S_sys_lock,S_video_lock;
    wire S_global_reset,S_rst_mem,S_rst_video,S_common_reset,S_host_reset;
    // Independent PLL startup pulse lasting 16 board-clock cycles.
    initial begin S_pll_count=0; S_pll_started=0; end
    always @(posedge I_clk_50m) if(!S_pll_started) begin
        if(&S_pll_count) S_pll_started<=1;
        else S_pll_count<=S_pll_count+1'b1;
    end
    pll_tree u_pll (
        .I_clk_50m(I_clk_50m),.I_pll_reset(S_pll_reset),
        .O_sd_card_clk(S_clk100),.O_ext_mem_clk(S_clk125),.O_ext_mem_clk_sft(S_clk125s),
        .O_video_clk(S_clk25),.O_hdmi_5x_clk(S_clk5x),
        .O_sys_pll_locked(S_sys_lock),.O_video_pll_locked(S_video_lock)
    );
    key_long_reset u_long_reset (
        .I_clk(I_clk_50m),.I_startup_reset(S_pll_reset),.I_key_n(I_key_n[0]),.O_global_reset(S_global_reset)
    );
    reset_gen u_reset (
        .I_clk_50m(I_clk_50m),.I_clk_100m(S_clk100),.I_clk_125m(S_clk125),.I_clk_25m(S_clk25),
        .I_sys_pll_locked(S_sys_lock),.I_video_pll_locked(S_video_lock),
        .I_global_reset(S_global_reset || !S_sys_lock || !S_video_lock),.I_media_reset_safe(1'b0),
        .O_reset_mem(S_rst_mem),.O_reset_video(S_rst_video),
        .O_reset_sys(), .O_reset_media(), .O_reset_sd_media()
    );
    assign S_common_reset=S_rst_mem || S_rst_video;
    reset_sync u_host_reset(.I_clk(S_clk125),.I_async_reset(S_common_reset),.O_reset(S_host_reset));
    wire [3:0] S_key_release;
    board_inputs #(.DEBOUNCE_CYCLES(1666667)) u_inputs (
        .I_clk(S_clk125),.I_reset(S_host_reset),.I_key_n(I_key_n),.I_switch(I_switch),.O_key_release(S_key_release),
        .O_keys(), .O_switch(), .O_switch_changed(), .O_switch_initialized()
    );
    wire S_rx_valid,S_rx_error,S_tx_valid,S_tx_ready;
    wire [7:0] S_rx_data,S_tx_data;
    uart_rx #(.CLOCK_HZ(83333333)) u_rx(.I_clk(S_clk125),.I_reset(S_host_reset),.I_rx(I_uart_rx),
        .O_valid(S_rx_valid),.O_frame_error(S_rx_error),.O_data(S_rx_data));
    uart_tx #(.CLOCK_HZ(83333333)) u_tx(.I_clk(S_clk125),.I_reset(S_host_reset),.I_valid(S_tx_valid),
        .O_ready(S_tx_ready),.I_data(S_tx_data),.O_tx(O_uart_tx));
    wire S_card,S_request,S_request_ready,S_byte_valid,S_byte_ready,S_sector_last,S_request_last,S_done,S_done_ready;
    wire S_cancel,S_cancel_ready,S_cancel_done,S_cancel_done_ready;
    wire [32:0] S_capacity;
    wire [31:0] S_lba;
    wire [7:0] S_count,S_byte;
    wire [1:0] S_context,S_priority,S_byte_context,S_done_context,S_cancel_context,S_cancel_done_context;
    wire [15:0] S_tag,S_byte_tag,S_done_tag,S_cancel_tag,S_cancel_done_tag;
    wire [3:0] S_sd_error;
    // 50 MHz / 6 = 8.333 MHz during reads; initialization remains 200 kHz.
    sd_storage #(.WORK_DIVIDER(16'd6)) u_storage (
        .I_host_clk(S_clk125),.I_sd_clk(I_clk_50m),.I_async_reset(S_host_reset),
        .I_request_valid(S_request),.O_request_ready(S_request_ready),.I_lba(S_lba),.I_count(S_count),
        .I_context(S_context),.I_priority(S_priority),.I_tag(S_tag),.I_urgent_context(3'd0),
        .O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),
        .O_sector_last(S_sector_last),.O_request_last(S_request_last),.O_byte_context(S_byte_context),.O_byte_tag(S_byte_tag),
        .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_done_context(S_done_context),.O_done_tag(S_done_tag),.O_done_error(S_sd_error),
        .I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),.I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),
        .O_cancel_done_valid(S_cancel_done),.I_cancel_done_ready(S_cancel_done_ready),
        .O_cancel_done_context(S_cancel_done_context),.O_cancel_done_tag(S_cancel_done_tag),
        .O_card_ready(S_card),.O_capacity_sectors(S_capacity),
        .O_sd_ncs(O_tf_ncs),.O_sd_sclk(O_tf_sclk),.O_sd_mosi(O_tf_mosi),.I_sd_miso(I_tf_miso),
        .O_card_present(), .O_sd_high_capacity(), .O_sd_card_error()
    );
    wire S_read,S_read_ready,S_result,S_result_ready,S_write,S_write_ready,S_write_idle;
    wire [20:0] S_read_address,S_write_address;
    wire [31:0] S_read_tag,S_result_tag,S_result_data,S_write_data;
    wire [3:0] S_result_error;
    wire S_mem_initialized,S_mem_clock_fault,S_mem_error;
    wire S_sdram_clk,S_sdram_cke,S_sdram_ras_n,S_sdram_cas_n,S_sdram_we_n;
    wire [10:0] S_sdram_addr;
    wire [1:0] S_sdram_ba;
    wire [3:0] S_sdram_dm;
    wire [31:0] S_sdram_dq;
    lean_frame_memory u_memory (
        .I_clk(S_clk125),.I_clk_sft(S_clk125s),.I_reset(S_host_reset),
        .I_read_valid(S_read),.O_read_ready(S_read_ready),.I_read_address(S_read_address),.I_read_tag(S_read_tag),
        .O_read_result_valid(S_result),.I_read_result_ready(S_result_ready),
        .O_read_data(S_result_data),.O_read_tag(S_result_tag),.O_read_error(S_result_error),
        .I_write_valid(S_write),.O_write_ready(S_write_ready),.I_write_address(S_write_address),.I_write_data(S_write_data),
        .O_writes_idle(S_write_idle),.O_initialized(S_mem_initialized),.O_clock_fault(S_mem_clock_fault),.O_memory_error(S_mem_error),
        .O_sdram_clk(S_sdram_clk),.O_sdram_cke(S_sdram_cke),.O_sdram_ras_n(S_sdram_ras_n),
        .O_sdram_cas_n(S_sdram_cas_n),.O_sdram_we_n(S_sdram_we_n),
        .O_sdram_addr(S_sdram_addr),.O_sdram_ba(S_sdram_ba),.O_sdram_dm(S_sdram_dm),.IO_sdram_dq(S_sdram_dq)
    );
    player_sdram_phy u_sdram (
        .I_clk(S_sdram_clk),.I_cke(S_sdram_cke),.I_ras_n(S_sdram_ras_n),.I_cas_n(S_sdram_cas_n),.I_we_n(S_sdram_we_n),
        .I_addr(S_sdram_addr),.I_ba(S_sdram_ba),.I_dm(S_sdram_dm),.IO_dq(S_sdram_dq)
    );
    wire S_de,S_valid,S_sample,S_acr,S_active,S_busy,S_hdmi_locked,S_bridge_fault;
    wire [15:0] S_x,S_y;
    wire [23:0] S_rgb,S_audio_left,S_audio_right;
    wire [19:0] S_acr_n,S_acr_cts;
    wire [3:0] S_current,S_error;
    wire [4:0] S_images;
    lean_player_core u_player (
        .I_host_clk(S_clk125),.I_video_clk(S_clk25),.I_async_reset(S_host_reset),.I_key_release(S_key_release),
        .I_rx_valid(S_rx_valid),.I_rx_error(S_rx_error),.I_rx_data(S_rx_data),
        .O_tx_valid(S_tx_valid),.I_tx_ready(S_tx_ready),.O_tx_data(S_tx_data),
        .I_card_ready(S_card),.I_capacity_sectors(S_capacity),
        .I_memory_ready(S_mem_initialized),.I_memory_error(S_mem_clock_fault || S_mem_error),.I_writes_idle(S_write_idle),
        .O_read_valid(S_read),.I_read_ready(S_read_ready),.O_read_address(S_read_address),.O_read_tag(S_read_tag),
        .I_result_valid(S_result),.O_result_ready(S_result_ready),.I_result_data(S_result_data),.I_result_tag(S_result_tag),.I_result_error(S_result_error),
        .O_write_valid(S_write),.I_write_ready(S_write_ready),.O_write_address(S_write_address),.O_write_data(S_write_data),
        .O_de(S_de),.O_valid(S_valid),.O_x(S_x),.O_y(S_y),.O_rgb(S_rgb),
        .O_sample_valid(S_sample),.O_audio_left(S_audio_left),.O_audio_right(S_audio_right),
        .O_acr_valid(S_acr),.O_acr_n(S_acr_n),.O_acr_cts(S_acr_cts),.O_active(S_active),.O_busy(S_busy),
        .O_current(S_current),.O_count(S_images),.O_error(S_error),
        .O_request_valid(S_request),.I_request_ready(S_request_ready),.O_lba(S_lba),.O_count_sectors(S_count),
        .O_context(S_context),.O_priority(S_priority),.O_tag(S_tag),
        .I_sd_byte_valid(S_byte_valid),.O_sd_byte_ready(S_byte_ready),.I_sd_byte_data(S_byte),
        .I_sector_last(S_sector_last),.I_request_last(S_request_last),.I_sd_byte_context(S_byte_context),.I_sd_byte_tag(S_byte_tag),
        .I_sd_done_valid(S_done),.O_sd_done_ready(S_done_ready),.I_sd_done_context(S_done_context),.I_sd_done_tag(S_done_tag),.I_sd_done_error(S_sd_error),
        .O_cancel_valid(S_cancel),.I_cancel_ready(S_cancel_ready),.O_cancel_context(S_cancel_context),.O_cancel_tag(S_cancel_tag),
        .I_cancel_done_valid(S_cancel_done),.O_cancel_done_ready(S_cancel_done_ready),
        .I_cancel_done_context(S_cancel_done_context),.I_cancel_done_tag(S_cancel_done_tag)
    );
    player_hdmi u_hdmi (
        .I_video_clk(S_clk25),.I_serial_clk(S_clk5x),.I_reset(S_rst_video),.I_hpd(I_hdmi_hpd),
        .I_de(S_de),.I_valid(S_valid),.I_x(S_x),.I_y(S_y),.I_rgb(S_rgb),
        .I_audio_valid(S_sample),.I_audio_left(S_audio_left),.I_audio_right(S_audio_right),
        .I_acr_valid(S_acr),.I_acr_n(S_acr_n),.I_acr_cts(S_acr_cts),
        .O_hdmi_clk_p(O_hdmi_clk_p),.O_hdmi_d0_p(O_hdmi_d0_p),.O_hdmi_d1_p(O_hdmi_d1_p),.O_hdmi_d2_p(O_hdmi_d2_p),
        .O_hdmi_scl(O_hdmi_scl),.IO_hdmi_sda(IO_hdmi_sda),.O_locked(S_hdmi_locked),.O_bridge_fault(S_bridge_fault),
        .O_sink_reset(), .O_restart_count()
    );
    assign {O_flash_cs_n,O_flash_sclk,O_flash_mosi,O_flash_wp_n,O_flash_hold_n}=5'b10011;
    assign O_led=~{S_error!=0 || S_bridge_fault,S_active,S_card,S_mem_initialized};
endmodule

