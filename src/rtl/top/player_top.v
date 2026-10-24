// Physical TF/SDRAM/HDMI playback entry. Not a claim of full product completion.
// Startup initialization, PLL phase, resources and vendor HDMI require TD/board checks.
module player_top (
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
    reg [3:0] S_pll_start_count;
    reg S_pll_started;
    wire S_pll_reset=!S_pll_started;
    wire S_clk100,S_clk125,S_clk125s,S_clk25,S_clk5x,S_sys_lock,S_video_lock;
    wire S_key_global_reset,S_rst_sys,S_rst_mem,S_rst_media,S_rst_sd,S_rst_video;
    wire S_common_reset,S_host_reset,S_video_reset;
    wire [3:0] S_keys,S_switch,S_key_release,S_switch_changed;
    wire S_inputs_initialized;
    wire S_auto,S_pause,S_mute,S_next,S_prev,S_reload,S_rescan,S_menu;
    wire [3:0] S_menu_row,S_menu_key,S_ui_error;
    wire [2:0] S_menu_group;
    wire S_menu_root,S_menu_edit,S_menu_confirm,S_goto,S_board_interrupt,S_selftest;
    wire [5:0] S_goto_index,S_current_index;
    wire [6:0] S_item_count;
    wire [239:0] S_config;
    wire [2:0] S_default_override;
    wire S_order_override,S_index_valid;
    wire S_settings_initialized,S_restore_valid,S_restore_ready,S_restore_found;
    wire [239:0] S_restore_config;
    wire [3:0] S_restore_override,S_load_error,S_save_error;
    wire S_save_valid,S_save_ready,S_save_done,S_save_done_ready;
    wire [3:0] S_order_error;
    wire [1:0] S_index_order;
    wire [1:0] S_effective_order=S_index_order==0 ? 2'd1 : S_index_order==1 ? 2'd0 : S_index_order;
    wire [15:0] S_menu_info,S_menu_value;
    wire signed [15:0] S_offset_ms=S_config[191:176];
    wire signed [6:0] S_offset_steps=S_offset_ms/16'sd10;
    wire S_player_busy,S_session_busy;
    wire S_all_failed,S_watchdog_expired,S_resident_ready;
    wire S_demo_active,S_demo_ready,S_recovery,S_recovery_active;
    wire [3:0] S_demo_error,S_demo_flash_error;
    wire S_demo_flash_valid,S_demo_flash_ready,S_demo_flash_read_valid,S_demo_flash_read_ready,S_demo_flash_read_last,S_demo_flash_done,S_demo_flash_done_ready;
    wire [23:0] S_demo_flash_address;
    wire [15:0] S_demo_flash_length,S_demo_flash_tag,S_demo_flash_result_tag;
    wire [7:0] S_demo_flash_read_data;
    wire S_alert,S_alert_hold,S_alert_visible;
    wire [5:0] S_alert_length;
    wire [319:0] S_alert_text;
    (* ASYNC_REG="TRUE" *) reg S_alert_audio_meta,S_alert_audio;
    wire S_output_sample_valid;
    wire [23:0] S_output_audio_left,S_output_audio_right;
    wire [3:0] S_resident_error;
    wire [3:0] S_player_error;
    wire S_memory_initialized,S_memory_clock_fault,S_memory_contract_fault;
    wire S_active,S_player_fault,S_session_ready;
    wire [3:0] S_session_error;
    wire S_frame_start,S_pixel_valid,S_de,S_sample_valid,S_acr_valid;
    wire [15:0] S_x,S_y;
    wire [310:0] S_video_state;
    wire [22:0] S_player_view;
    wire [2879:0] S_titles;
    wire [53:0] S_title_lengths;
    wire [23:0] S_rgb,S_color_rgb,S_overlay_rgb,S_audio_left,S_audio_right;
    wire [19:0] S_acr_n,S_acr_cts;
    wire S_hdmi_locked,S_bridge_fault,S_sink_reset;
    wire [31:0] S_hdmi_restarts;
    wire S_uart_rx_valid,S_uart_rx_error,S_uart_tx_valid,S_uart_tx_ready;
    wire [7:0] S_uart_rx_data,S_uart_tx_data;
    wire S_uart_request_valid,S_uart_request_ready,S_uart_result_valid,S_uart_result_ready,S_uart_pending,S_console_hold;
    wire [4:0] S_uart_op;
    wire [3:0] S_uart_key,S_uart_error;
    wire [15:0] S_uart_value,S_uart_base,S_uart_effective;
    wire [5:0] S_uart_text_length;
    wire [319:0] S_uart_text;
    wire [31:0] S_uart_dropped,S_raw_vund,S_vund_count,S_aund_count,S_status;
    wire [1:0] S_audio_underrun;
    wire [15:0] S_fps;
    wire S_fps_valid,S_mem_window_valid;
    wire [20:0] S_mem_busy_cycles,S_mem_grant_cycles;
    reg S_mem_stats_seen;
    reg [1:0] S_hdmi_status_meta,S_hdmi_status_sync;
    // No lock/reset_gen/user-reset feedback into PLL reset.
    initial begin S_pll_start_count=0; S_pll_started=0; end
    always @(posedge I_clk_50m) begin
        if(!S_pll_started) begin
            if(&S_pll_start_count) S_pll_started<=1;
            else S_pll_start_count<=S_pll_start_count+1'b1;
        end
    end
    pll_tree u_pll (
        .I_clk_50m(I_clk_50m),.I_pll_reset(S_pll_reset),
        .O_sd_card_clk(S_clk100),.O_ext_mem_clk(S_clk125),.O_ext_mem_clk_sft(S_clk125s),
        .O_video_clk(S_clk25),.O_hdmi_5x_clk(S_clk5x),
        .O_sys_pll_locked(S_sys_lock),.O_video_pll_locked(S_video_lock)
    );
    key_long_reset u_long_reset (
        .I_clk(I_clk_50m),.I_startup_reset(S_pll_reset),.I_key_n(I_key_n[0]),.O_global_reset(S_key_global_reset)
    );
    reset_gen u_reset (
        .I_clk_50m(I_clk_50m),.I_clk_100m(S_clk100),.I_clk_125m(S_clk125),.I_clk_25m(S_clk25),
        .I_sys_pll_locked(S_sys_lock),.I_video_pll_locked(S_video_lock),
        .I_global_reset(S_key_global_reset || !S_sys_lock || !S_video_lock),.I_media_reset_safe(1'b0),
        .O_reset_sys(S_rst_sys),.O_reset_mem(S_rst_mem),.O_reset_media(S_rst_media),
        .O_reset_sd_media(S_rst_sd),.O_reset_video(S_rst_video)
    );
    // Shared reason, then target-domain release. Never reset a FIFO side alone.
    assign S_common_reset=S_rst_mem || S_rst_video;
    reset_sync u_host_reset(.I_clk(S_clk125),.I_async_reset(S_common_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset(.I_clk(S_clk25),.I_async_reset(S_common_reset),.O_reset(S_video_reset));
    board_inputs u_inputs (
        .I_clk(S_clk125),.I_reset(S_host_reset),.I_key_n(I_key_n),.I_switch(I_switch),
        .O_keys(S_keys),.O_switch(S_switch),.O_key_release(S_key_release),
        .O_switch_changed(S_switch_changed),.O_switch_initialized(S_inputs_initialized)
    );
    assign O_flash_wp_n=1'b1;
    assign O_flash_hold_n=1'b1;
    wire S_idle_O_font_ready;
    wire S_idle_O_font_read_valid;
    wire [7:0] S_idle_O_font_read_data;
    wire S_idle_O_font_read_last;
    wire S_idle_O_font_done_valid;
    wire [3:0] S_idle_O_font_error;
    wire [15:0] S_idle_O_font_tag;
    wire [3:0] S_osd_builder_error;
    wire S_osd_busy;
    wire S_osd_cancel_late;
    wire S_osd_active_valid;
    wire S_osd_active_bank;
    wire [31:0] S_osd_glyph_misses;
    wire S_osd_response_discarded;
    wire [8:0] S_osd_locked_count;
    wire [31:0] S_osd_miss_count;
    wire [31:0] S_osd_flash_error_count;
    wire S_osd_font_valid;
    wire [23:0] S_osd_font_address;
    wire [15:0] S_osd_font_tag;
    wire S_osd_font_read_ready;
    wire S_osd_font_done_ready;
    wire [31:0] S_osd_missing_rows;
    wire S_osd_valid;
    wire S_osd_de;
    wire [15:0] S_osd_x;
    wire [15:0] S_osd_y;
    wire [23:0] S_osd_rgb;
    wire [31:0] S_osd_line_misses;
    player_settings u_settings (
        .I_host_clk(S_clk125),.I_flash_clk(S_clk100),.I_async_reset(S_common_reset),
        .O_initialized(S_settings_initialized),.O_restore_valid(S_restore_valid),.I_restore_ready(S_restore_ready),
        .O_restore_found(S_restore_found),.O_restore_config(S_restore_config),.O_restore_override(S_restore_override),.O_load_error(S_load_error),
        .I_save_valid(S_save_valid),.O_save_ready(S_save_ready),.I_config(S_config),.I_override({S_order_override,S_default_override}),
        .O_save_done_valid(S_save_done),.I_save_done_ready(S_save_done_ready),.O_save_error(S_save_error),
        .I_font_valid(S_osd_font_valid),.I_font_address(S_osd_font_address),.I_font_tag(S_osd_font_tag),
        .I_font_read_ready(S_osd_font_read_ready),.I_font_done_ready(S_osd_font_done_ready),
        .O_font_ready(S_idle_O_font_ready),
        .O_font_read_valid(S_idle_O_font_read_valid),
        .O_font_read_data(S_idle_O_font_read_data),
        .O_font_read_last(S_idle_O_font_read_last),
        .O_font_done_valid(S_idle_O_font_done_valid),
        .O_font_error(S_idle_O_font_error),
        .O_font_tag(S_idle_O_font_tag),
        .I_demo_valid(S_demo_flash_valid),.O_demo_ready(S_demo_flash_ready),.I_demo_address(S_demo_flash_address),
        .I_demo_length(S_demo_flash_length),.I_demo_tag(S_demo_flash_tag),
        .O_demo_read_valid(S_demo_flash_read_valid),.I_demo_read_ready(S_demo_flash_read_ready),
        .O_demo_read_data(S_demo_flash_read_data),.O_demo_read_last(S_demo_flash_read_last),
        .O_demo_done_valid(S_demo_flash_done),.I_demo_done_ready(S_demo_flash_done_ready),
        .O_demo_error(S_demo_flash_error),.O_demo_tag(S_demo_flash_result_tag),
        .O_flash_cs_n(O_flash_cs_n),.O_flash_sclk(O_flash_sclk),.O_flash_mosi(O_flash_mosi),.I_flash_miso(I_flash_miso)
    );
    player_ui_ctrl u_controls (
        .I_clk(S_clk125),.I_reset(S_host_reset),.I_key_release(S_key_release),
        .I_switch(S_switch),.I_switch_changed(S_switch_changed),.I_switch_initialized(S_inputs_initialized),
        .I_settings_initialized(S_settings_initialized),.I_restore_valid(S_restore_valid),.I_restore_found(S_restore_found),
        .O_restore_ready(S_restore_ready),.I_restore_config(S_restore_config),.I_restore_override(S_restore_override),
        .O_save_valid(S_save_valid),.I_save_ready(S_save_ready),.I_save_done_valid(S_save_done),
        .O_save_done_ready(S_save_done_ready),.I_save_error(S_save_error),
        .I_effective_order(S_effective_order),.I_effective_order_valid(S_index_valid),
        .I_active(S_active),.I_player_busy(S_player_busy),.I_fault(S_player_fault || S_memory_clock_fault || S_memory_contract_fault),
        .I_session_ready(S_session_ready),.I_session_busy(S_session_busy),.I_count(S_item_count),.I_current_index(S_current_index),
        .I_request_valid(S_uart_request_valid),.O_request_ready(S_uart_request_ready),.I_request_op(S_uart_op),
        .I_request_key(S_uart_key),.I_request_value(S_uart_value),
        .I_request_text_length(S_uart_text_length),.I_request_text(S_uart_text),
        .O_recovery(S_recovery),.O_alert(S_alert),.O_alert_length(S_alert_length),.O_alert_text(S_alert_text),.O_result_valid(S_uart_result_valid),
        .I_result_ready(S_uart_result_ready),.O_result_error(S_uart_error),.O_result_pending(S_uart_pending),
        .O_result_base(S_uart_base),.O_result_effective(S_uart_effective),.O_config(S_config),.O_default_override(S_default_override),.O_order_override(S_order_override),
        .O_auto(S_auto),.O_pause(S_pause),.O_mute(S_mute),.O_next(S_next),.O_prev(S_prev),
        .O_goto(S_goto),.O_goto_index(S_goto_index),.O_reload(S_reload),.O_rescan(S_rescan),
        .O_menu(S_menu),.O_menu_root(S_menu_root),.O_menu_edit(S_menu_edit),.O_menu_confirm(S_menu_confirm),
        .O_menu_group(S_menu_group),.O_menu_row(S_menu_row),.O_menu_key(S_menu_key),.O_menu_value(S_menu_value),
        .O_board_interrupt(S_board_interrupt),.O_selftest(S_selftest),.O_ui_error(S_ui_error)
    );
    assign S_menu_info={S_ui_error!=0 ? S_ui_error : S_order_error,S_menu_key,S_menu_confirm,S_menu_edit,S_menu_root,S_menu_group,2'd0};
    video_ui_cdc #(.WIDTH(311)) u_ui_cdc (
        .I_host_clk(S_clk125),.I_video_clk(S_clk25),.I_async_reset(S_common_reset),.I_frame_start(S_frame_start),
        .I_state({S_player_view,S_config,S_menu_value,S_menu_info,
            S_recovery_active,S_demo_active,S_alert_visible,(!S_active && !S_alert_visible),S_player_busy,(S_player_fault || S_session_error!=0 || S_memory_clock_fault || S_memory_contract_fault),
            S_active,S_session_ready,1'b0,S_menu_row[2:0],(S_menu && !S_alert_hold),S_mute,S_pause,S_auto}),
        .O_state(S_video_state)
    );
    // Live color values are applied once here. The transition core stays neutral.
    video_color_adjust u_live_color (
        .I_de(S_de),.I_rgb(S_rgb),.I_brightness(S_video_state[179:176]),
        .I_contrast(S_video_state[259:256]),.I_saturation(S_video_state[276:272]),.O_rgb(S_color_rgb)
    );
    player_status_osd #(.CHINESE_MENU(1)) u_panel (
        .I_de(S_de),.I_valid(S_pixel_valid),.I_x(S_x),.I_y(S_y),.I_state(S_video_state[15:0]),
        .I_menu_info(S_video_state[31:16]),.I_menu_value(S_video_state[47:32]),
        .I_view(S_video_state[310:288]),.I_rgb(S_color_rgb),.O_rgb(S_overlay_rgb)
    );
    player_osd u_osd (
        .I_font_clk(S_clk100),
        .I_ui({S_menu_value,S_menu_info,4'd0,S_player_busy,(S_all_failed || S_player_fault || S_session_error!=0 || S_memory_clock_fault || S_memory_contract_fault),S_active,S_session_ready,S_switch[3],S_menu_row[2:0],S_menu,S_mute,S_pause,S_auto}),
        .I_hud(S_config[192]),
        .I_fps_valid(S_fps_valid),
        .I_mem_valid(S_mem_stats_seen),
        .I_fps(S_fps),
        .I_video_und(S_vund_count),
        .I_audio_und(S_aund_count),
        .I_count(S_item_count),
        .I_index(S_current_index),
        .I_mem_busy(S_mem_busy_cycles),
        .I_mem_grant(S_mem_grant_cycles),
        .I_view(S_player_view),.I_titles(S_titles),.I_title_lengths(S_title_lengths),
        .I_alert(S_alert_visible),.I_alert_length(S_alert_length),.I_alert_text(S_alert_text),
        .O_builder_error(S_osd_builder_error),
        .I_video_clk(S_clk25),
        .I_async_reset(S_common_reset),
        .O_busy(S_osd_busy),
        .O_cancel_late(S_osd_cancel_late),
        .O_active_valid(S_osd_active_valid),
        .O_active_bank(S_osd_active_bank),
        .O_glyph_misses(S_osd_glyph_misses),
        .O_response_discarded(S_osd_response_discarded),
        .O_locked_count(S_osd_locked_count),
        .O_miss_count(S_osd_miss_count),
        .O_flash_error_count(S_osd_flash_error_count),
        .O_font_valid(S_osd_font_valid),
        .I_font_ready(S_idle_O_font_ready),
        .O_font_address(S_osd_font_address),
        .O_font_tag(S_osd_font_tag),
        .I_font_read_valid(S_idle_O_font_read_valid),
        .O_font_read_ready(S_osd_font_read_ready),
        .I_font_read_data(S_idle_O_font_read_data),
        .I_font_read_last(S_idle_O_font_read_last),
        .I_font_done_valid(S_idle_O_font_done_valid),
        .O_font_done_ready(S_osd_font_done_ready),
        .I_font_error(S_idle_O_font_error),
        .I_font_tag(S_idle_O_font_tag),
        .O_missing_rows(S_osd_missing_rows),
        .I_frame_start(S_frame_start),
        .I_video_valid(1'b1),
        .I_de(S_de),
        .I_video_x(S_x),
        .I_video_y(S_y),
        .I_rgb(S_overlay_rgb),
        .O_valid(S_osd_valid),
        .O_de(S_osd_de),
        .O_x(S_osd_x),
        .O_y(S_osd_y),
        .O_rgb(S_osd_rgb),
        .O_line_misses(S_osd_line_misses),
        .I_host_clk(S_clk125)
    );
    uart_rx u_uart_rx(.I_clk(S_clk125),.I_reset(S_host_reset),.I_rx(I_uart_rx),
        .O_valid(S_uart_rx_valid),.O_frame_error(S_uart_rx_error),.O_data(S_uart_rx_data));
    uart_tx u_uart_tx(.I_clk(S_clk125),.I_reset(S_host_reset),.I_valid(S_uart_tx_valid),
        .O_ready(S_uart_tx_ready),.I_data(S_uart_tx_data),.O_tx(O_uart_tx));
    player_console u_console (
        .I_clk(S_clk125),.I_reset(S_host_reset),.I_rx_valid(S_uart_rx_valid),.I_rx_frame_error(S_uart_rx_error),
        .I_rx_data(S_uart_rx_data),.O_tx_valid(S_uart_tx_valid),.I_tx_ready(S_uart_tx_ready),.O_tx_data(S_uart_tx_data),
        .O_request_valid(S_uart_request_valid),.I_request_ready(S_uart_request_ready),.O_request_op(S_uart_op),
        .O_request_key(S_uart_key),.O_request_value(S_uart_value),.O_request_text_length(S_uart_text_length),.O_request_text(S_uart_text),
        .I_result_valid(S_uart_result_valid),.O_result_ready(S_uart_result_ready),.I_result_error(S_uart_error),
        .I_result_pending(S_uart_pending),.I_result_base(S_uart_base),.I_result_effective(S_uart_effective),
        .I_player_busy(S_player_busy),.I_active(S_active),.I_fault(S_player_fault || S_memory_clock_fault || S_memory_contract_fault),
        .I_session_busy(S_session_busy),.I_session_ready(S_session_ready),.I_board_interrupt(S_board_interrupt),.I_selftest(S_selftest),
        .I_player_error(S_player_error),.I_session_error(S_session_error),.I_current_index(S_current_index),.I_count(S_item_count),
        .I_media_status({S_resident_error,S_resident_ready,S_alert_visible,S_alert_hold,S_alert,
            S_demo_error,S_recovery,S_recovery_active,S_demo_ready,S_demo_active}),.I_status(S_status),.I_video_und(S_vund_count),.I_audio_und(S_aund_count),.I_fps(S_fps),
        .I_mem_busy_cycles(S_mem_busy_cycles),.I_mem_grant_cycles(S_mem_grant_cycles),
        .O_control_hold(S_console_hold),.O_dropped_lines(S_uart_dropped)
    );
    player_telemetry u_telemetry (
        .I_host_clk(S_clk125),.I_video_clk(S_clk25),.I_async_reset(S_common_reset),.I_frame_start(S_frame_start),
        .I_video_und_count(S_raw_vund),.I_audio_underrun(S_audio_underrun),
        .O_video_und_count(S_vund_count),.O_audio_und_count(S_aund_count),.O_fps(S_fps),.O_fps_valid(S_fps_valid)
    );
    always @(posedge S_clk125 or posedge S_host_reset) begin
        if(S_host_reset) begin S_hdmi_status_meta<=0; S_hdmi_status_sync<=0; S_mem_stats_seen<=0; end
        else begin
            S_hdmi_status_meta<={S_bridge_fault,S_hdmi_locked}; S_hdmi_status_sync<=S_hdmi_status_meta;
            if(S_mem_window_valid) S_mem_stats_seen<=1;
        end
    end
    assign S_status={S_load_error,S_save_error,(S_resident_error!=0),S_all_failed,S_watchdog_expired,S_settings_initialized,S_order_error,S_fps_valid,S_mem_stats_seen,S_menu,S_switch[3],S_pause,S_auto,
        S_memory_contract_fault,S_memory_clock_fault,S_hdmi_status_sync[1],S_session_ready,S_player_busy,
        S_active,S_memory_initialized,S_video_lock,S_sys_lock,S_hdmi_status_sync[0]};
    always @(posedge S_clk25 or posedge S_video_reset) begin
        if(S_video_reset) begin S_alert_audio_meta<=0; S_alert_audio<=0; end
        else begin S_alert_audio_meta<=S_alert; S_alert_audio<=S_alert_audio_meta; end
    end
    alert_audio_mux u_alert_audio (
        .I_clk(S_clk25),.I_reset(S_video_reset),.I_alert(S_alert_audio),
        .I_sample_valid(S_sample_valid),.I_mute(S_video_state[2]),.I_volume(S_video_state[196:192]),
        .I_left(S_audio_left),.I_right(S_audio_right),.O_sample_valid(S_output_sample_valid),
        .O_left(S_output_audio_left),.O_right(S_output_audio_right)
    );
    player_hdmi u_output (
        .I_video_clk(S_clk25),.I_serial_clk(S_clk5x),.I_reset(S_video_reset),.I_hpd(I_hdmi_hpd),
        .I_de(S_osd_de),.I_valid(S_osd_valid),.I_x(S_osd_x),.I_y(S_osd_y),.I_rgb(S_osd_rgb),
        .I_audio_valid(S_output_sample_valid),.I_audio_left(S_output_audio_left),.I_audio_right(S_output_audio_right),
        .I_acr_valid(S_acr_valid),.I_acr_n(S_acr_n),.I_acr_cts(S_acr_cts),
        .O_hdmi_clk_p(O_hdmi_clk_p),.O_hdmi_d0_p(O_hdmi_d0_p),.O_hdmi_d1_p(O_hdmi_d1_p),.O_hdmi_d2_p(O_hdmi_d2_p),
        .O_hdmi_scl(O_hdmi_scl),.IO_hdmi_sda(IO_hdmi_sda),
        .O_locked(S_hdmi_locked),.O_bridge_fault(S_bridge_fault),.O_sink_reset(S_sink_reset),.O_restart_count(S_hdmi_restarts)
    );
    assign O_led=~{(S_player_fault || S_memory_clock_fault || S_memory_contract_fault || S_bridge_fault || S_session_error!=0),
        S_active,S_memory_initialized,(S_sys_lock && S_video_lock)};
    player_memory_top u_player (
        .I_mem_clk_sft(S_clk125s),
        .I_memory_clear_stats(1'b0),
        .I_aux_valid(3'd0),
        .I_aux_wr(3'd0),
        .I_aux_addr(63'd0),
        .I_aux_data(96'd0),
        .I_aux_mask(12'd0),
        .I_aux_tag(96'd0),
        .I_aux_token(96'd0),
        .I_aux_generation(96'd0),
        .I_aux_deadline(96'd0),
        .I_aux_result_ready(3'b111),
        .I_host_clk(S_clk125),
        .I_sd_clk(S_clk100),
        .I_video_clk(S_clk25),
        .I_async_reset(S_common_reset),
        .I_clock_enable(1'b1),
        .I_enable(S_memory_initialized && S_inputs_initialized && S_settings_initialized),
        .I_alert(S_alert),
        .I_auto(S_auto && !S_console_hold),
        .I_pause(S_pause),
        .I_next(S_next),
        .I_prev(S_prev),
        .I_goto_valid(S_goto),
        .I_goto_index(S_goto_index),
        .I_layout(S_config[82:80]),
        .I_rotation(S_config[97:96]),
        .I_bilinear(S_config[112]),
        .I_brightness(4'd0),
        .I_contrast(4'd0),
        .I_saturation(5'd8),
        .I_av_offset_steps(S_offset_steps),
        .I_audio_sector_budget(32'd16777216),
        .I_order_override(S_order_override),
        .I_runtime_order(S_config[65:64]),
        .I_default_override(S_default_override),
        .I_default_duration(S_config[25:16]),
        .I_default_transition_ms(S_config[57:48]),
        .I_default_transition(S_config[34:32]),
        .I_display_video_allow_apply(1'b1),
        .I_display_scan_stop(1'b0),
        .I_image_sector_budget(32'd32768),
        .I_image_rect_x(16'd0),
        .I_image_rect_y(16'd0),
        .I_image_rect_width(16'd640),
        .I_image_rect_height(16'd480),
        .I_image_clear_rgba(32'h000000ff),
        .I_scan_abort(1'b0),
        .I_scan_seed(32'h46504741),
        .I_scan_sector_budget(32'd256),
        .I_scan_directory_sector_budget(32'd4096),
        .I_scan_directory_duration(10'd10),
        .I_scan_directory_transition_ms(10'd400),
        .I_scan_directory_transition(3'd0),
        .I_scan_directory_order(2'd0),
        .I_audio_volume(S_video_state[196:192]),
        .I_audio_mute(S_video_state[2]),
        .I_audio_prompt_valid(1'b0),
        .I_audio_prompt_left(24'd0),
        .I_audio_prompt_right(24'd0),
        .I_storage_demo(S_switch[3]),
        .I_storage_recovery(S_recovery),
        .O_storage_recovery_active(S_recovery_active),
        .O_storage_demo_active(S_demo_active),
        .O_storage_demo_ready(S_demo_ready),
        .O_storage_demo_error(S_demo_error),
        .O_storage_flash_valid(S_demo_flash_valid),
        .I_storage_flash_ready(S_demo_flash_ready),
        .O_storage_flash_address(S_demo_flash_address),
        .O_storage_flash_length(S_demo_flash_length),
        .O_storage_flash_tag(S_demo_flash_tag),
        .I_storage_flash_read_valid(S_demo_flash_read_valid),
        .O_storage_flash_read_ready(S_demo_flash_read_ready),
        .I_storage_flash_read_data(S_demo_flash_read_data),
        .I_storage_flash_read_last(S_demo_flash_read_last),
        .I_storage_flash_done_valid(S_demo_flash_done),
        .O_storage_flash_done_ready(S_demo_flash_done_ready),
        .I_storage_flash_error(S_demo_flash_error),
        .I_storage_flash_tag(S_demo_flash_result_tag),
        .I_storage_sd_miso(I_tf_miso),
        .I_session_reload(S_reload),
        .I_session_rescan(S_rescan),
        .O_memory_initialized(S_memory_initialized),
        .O_memory_clock_fault(S_memory_clock_fault),
        .O_memory_contract_fault(S_memory_contract_fault),
        .O_player_active_valid(S_active),
        .O_player_fault(S_player_fault),
        .O_session_ready(S_session_ready),
        .O_session_error(S_session_error),
        .O_display_frame_start(S_frame_start),
        .O_display_valid(S_pixel_valid),
        .O_display_de(S_de),
        .O_display_x(S_x),
        .O_display_y(S_y),
        .O_display_rgb(S_rgb),
        .O_audio_sample_valid(S_sample_valid),
        .O_audio_left(S_audio_left),
        .O_audio_right(S_audio_right),
        .O_acr_valid(S_acr_valid),
        .O_acr_n(S_acr_n),
        .O_acr_cts(S_acr_cts),
        .O_storage_sd_ncs(O_tf_ncs),
        .O_storage_sd_sclk(O_tf_sclk),
        .O_storage_sd_mosi(O_tf_mosi),
        .O_player_busy(S_player_busy),
        .O_player_error(S_player_error),
        .O_player_current_index(S_current_index),
        .O_order_error(S_order_error),
        .O_scan_active_valid(S_index_valid),
        .O_scan_active_order(S_index_order),
        .O_player_titles(S_titles),
        .O_player_title_lengths(S_title_lengths),
        .O_player_all_failed(S_all_failed),
        .O_player_watchdog_expired(S_watchdog_expired),
        .O_resident_ready(S_resident_ready),
        .O_resident_error(S_resident_error),
        .O_player_alert_visible(S_alert_visible),
        .O_player_alert_hold(S_alert_hold),
        .O_player_count(S_item_count),
        .O_player_view(S_player_view),
        .O_session_busy(S_session_busy),
        .O_display_und_count(S_raw_vund),
        .O_audio_underrun(S_audio_underrun),
        .O_memory_window_valid(S_mem_window_valid),
        .O_memory_busy_cycles(S_mem_busy_cycles),
        .O_memory_grant_cycles(S_mem_grant_cycles)
    );
endmodule
