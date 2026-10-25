// Board UI/HUD -> stable mailbox -> GB2312 text/cache -> dual-clock raster overlay.
// Fixed Chinese glyphs: 111 unique, within the default 192 locked-slot budget.
module player_osd (
    input wire I_font_clk,
    input wire [47:0] I_ui,
    input wire I_hud,
    input wire I_fps_valid,
    input wire I_mem_valid,
    input wire [15:0] I_fps,
    input wire [31:0] I_video_und,
    input wire [31:0] I_audio_und,
    input wire [6:0] I_count,
    input wire [5:0] I_index,
    input wire [20:0] I_mem_busy,
    input wire [20:0] I_mem_grant,
    input wire [22:0] I_view,
    input wire [2879:0] I_titles,
    input wire [53:0] I_title_lengths,
    input wire [31:0] I_title_serial,
    input wire I_alert,
    input wire [5:0] I_alert_length,
    input wire [319:0] I_alert_text,
    output wire [3:0] O_builder_error,
    input wire I_video_clk,
    input wire I_async_reset,
    output wire O_busy,
    output wire O_cancel_late,
    output wire O_active_valid,
    output wire O_active_bank,
    output wire [31:0] O_glyph_misses,
    output wire O_response_discarded,
    output wire [8:0] O_locked_count,
    output wire [31:0] O_miss_count,
    output wire [31:0] O_flash_error_count,
    output wire O_font_valid,
    input wire I_font_ready,
    output wire [23:0] O_font_address,
    output wire [15:0] O_font_tag,
    input wire I_font_read_valid,
    output wire O_font_read_ready,
    input wire [7:0] I_font_read_data,
    input wire I_font_read_last,
    input wire I_font_done_valid,
    output wire O_font_done_ready,
    input wire [3:0] I_font_error,
    input wire [15:0] I_font_tag,
    output wire [31:0] O_missing_rows,
    input wire I_frame_start,
    input wire I_video_valid,
    input wire I_de,
    input wire [15:0] I_video_x,
    input wire [15:0] I_video_y,
    input wire [23:0] I_rgb,
    output wire O_valid,
    output wire O_de,
    output wire [15:0] O_x,
    output wire [15:0] O_y,
    output wire [23:0] O_rgb,
    output wire [31:0] O_line_misses,
    input wire I_host_clk
);
    wire S_begin_valid;
    wire S_line_valid;
    wire S_layer;
    wire [3:0] S_line;
    wire [9:0] S_x;
    wire [8:0] S_y;
    wire [1:0] S_color;
    wire S_lock;
    wire [5:0] S_length;
    wire S_byte_valid;
    wire [7:0] S_byte_data;
    wire S_byte_last;
    wire S_finish_valid;
    wire S_done_ready;
    wire S_begin_ready;
    wire S_line_ready;
    wire S_byte_ready;
    wire S_finish_ready;
    wire S_done_valid;
    wire [3:0] S_error;
    wire [47:0] S_state_ui;
    wire S_state_hud;
    wire S_state_fps_valid;
    wire S_state_mem_valid;
    wire [15:0] S_state_fps;
    wire [31:0] S_state_video_und;
    wire [31:0] S_state_audio_und;
    wire [6:0] S_state_count;
    wire [5:0] S_state_index;
    wire [20:0] S_state_mem_busy;
    wire [20:0] S_state_mem_grant;
    wire [22:0] S_state_view;
    wire [2879:0] S_state_titles;
    wire [53:0] S_state_title_lengths;
    wire S_state_alert;
    wire [5:0] S_state_alert_length;
    wire [319:0] S_state_alert_text;
    wire S_font_reset;
    wire S_idle;
    wire [3469:0] S_snapshot;
    wire [589:0] S_small_snapshot;
    wire S_title_read;
    wire [3:0] S_title_line;
    wire [5:0] S_title_address;
    wire [7:0] S_title_data;
    wire S_snapshot_valid,S_snapshot_done;
    reset_sync u_reset(.I_clk(I_font_clk),.I_async_reset(I_async_reset),.O_reset(S_font_reset));
    osd_title_snapshot u_snapshot (
        .I_host_clk(I_host_clk),.I_font_clk(I_font_clk),.I_async_reset(I_async_reset),.I_boundary(S_idle),
        .I_release(S_snapshot_done),.O_state_valid(S_snapshot_valid),
        .I_state({I_alert,I_alert_length,I_alert_text,I_view,I_title_lengths,I_mem_grant,I_mem_busy,I_index,I_count,I_audio_und,I_video_und,I_fps,I_mem_valid,I_fps_valid,I_hud,I_ui}),
        .I_titles(I_titles),.I_serial(I_title_serial),.O_state(S_small_snapshot),
        .I_title_read(S_title_read),.I_title_line(S_title_line),.I_title_address(S_title_address),.O_title_data(S_title_data)
    );
    assign S_snapshot={S_small_snapshot[589:240],2880'd0,S_small_snapshot[239:0]};
    assign {S_state_alert,S_state_alert_length,S_state_alert_text,S_state_view,S_state_titles,S_state_title_lengths,S_state_mem_grant,S_state_mem_busy,S_state_index,S_state_count,S_state_audio_und,S_state_video_und,
        S_state_fps,S_state_mem_valid,S_state_fps_valid,S_state_hud,S_state_ui}=S_snapshot;
    osd_menu_builder #(.EXTERNAL_SNAPSHOT(1),.EXTERNAL_TITLES(1)) u_builder (
        .I_snapshot_valid(S_snapshot_valid),.O_snapshot_done(S_snapshot_done),
        .O_begin_valid(S_begin_valid),
        .O_line_valid(S_line_valid),
        .O_layer(S_layer),
        .O_line(S_line),
        .O_x(S_x),
        .O_y(S_y),
        .O_color(S_color),
        .O_lock(S_lock),
        .O_length(S_length),
        .O_byte_valid(S_byte_valid),
        .O_byte_data(S_byte_data),
        .O_byte_last(S_byte_last),
        .O_finish_valid(S_finish_valid),
        .O_done_ready(S_done_ready),
        .I_begin_ready(S_begin_ready),
        .I_line_ready(S_line_ready),
        .I_byte_ready(S_byte_ready),
        .I_finish_ready(S_finish_ready),
        .I_done_valid(S_done_valid),
        .I_error(S_error),
        .I_clk(I_font_clk),
        .I_reset(S_font_reset),
        .I_ui(S_state_ui),
        .I_hud(S_state_hud),
        .I_fps_valid(S_state_fps_valid),
        .I_mem_valid(S_state_mem_valid),
        .I_fps(S_state_fps),
        .I_video_und(S_state_video_und),
        .I_audio_und(S_state_audio_und),
        .I_count(S_state_count),
        .I_index(S_state_index),
        .I_mem_busy(S_state_mem_busy),
        .I_mem_grant(S_state_mem_grant),
        .I_view(S_state_view),
        .I_titles(S_state_titles),
        .I_title_lengths(S_state_title_lengths),
        .O_title_read(S_title_read),.O_title_line(S_title_line),.O_title_address(S_title_address),.I_title_data(S_title_data),
        .I_alert(S_state_alert),
        .I_alert_length(S_state_alert_length),
        .I_alert_text(S_state_alert_text),
        .O_idle(S_idle),
        .O_error(O_builder_error)
    );
    osd_text_video u_text (
        .I_begin_valid(S_begin_valid),
        .I_line_valid(S_line_valid),
        .I_layer(S_layer),
        .I_line(S_line),
        .I_x(S_x),
        .I_y(S_y),
        .I_color(S_color),
        .I_lock(S_lock),
        .I_length(S_length),
        .I_byte_valid(S_byte_valid),
        .I_byte_data(S_byte_data),
        .I_byte_last(S_byte_last),
        .I_finish_valid(S_finish_valid),
        .I_done_ready(S_done_ready),
        .O_begin_ready(S_begin_ready),
        .O_line_ready(S_line_ready),
        .O_byte_ready(S_byte_ready),
        .O_finish_ready(S_finish_ready),
        .O_done_valid(S_done_valid),
        .O_error(S_error),
        .I_font_clk(I_font_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_abort(1'b0),
        .O_busy(O_busy),
        .O_cancel_late(O_cancel_late),
        .O_active_valid(O_active_valid),
        .O_active_bank(O_active_bank),
        .O_glyph_misses(O_glyph_misses),
        .O_response_discarded(O_response_discarded),
        .O_locked_count(O_locked_count),
        .O_miss_count(O_miss_count),
        .O_flash_error_count(O_flash_error_count),
        .O_font_valid(O_font_valid),
        .I_font_ready(I_font_ready),
        .O_font_address(O_font_address),
        .O_font_tag(O_font_tag),
        .I_font_read_valid(I_font_read_valid),
        .O_font_read_ready(O_font_read_ready),
        .I_font_read_data(I_font_read_data),
        .I_font_read_last(I_font_read_last),
        .I_font_done_valid(I_font_done_valid),
        .O_font_done_ready(O_font_done_ready),
        .I_font_error(I_font_error),
        .I_font_tag(I_font_tag),
        .O_missing_rows(O_missing_rows),
        .I_frame_start(I_frame_start),
        .I_video_valid(I_video_valid),
        .I_de(I_de),
        .I_video_x(I_video_x),
        .I_video_y(I_video_y),
        .I_rgb(I_rgb),
        .O_valid(O_valid),
        .O_de(O_de),
        .O_x(O_x),
        .O_y(O_y),
        .O_rgb(O_rgb),
        .O_line_misses(O_line_misses)
    );
endmodule
