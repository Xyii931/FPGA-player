// Actual WAV slots/playback with read-domain display preparation proof.
// I_audio_clk MUST be the same physical clock/reset domain as display video.
module wav_audio_prepared #(
    parameter integer FIFO_ADDR_BITS=11,
    parameter integer PREFILL_FRAMES=1024,
    parameter integer LOW_FRAMES=512,
    parameter integer FADE_SAMPLES=9600
) (
    input wire I_decode_clk,I_audio_clk,I_async_reset,
    input wire [1:0] I_start_valid,
    output wire [1:0] O_start_ready,
    input wire [63:0] I_file_size,I_start_index,
    input wire [31:0] I_epoch,
    input wire [1:0] I_byte_valid,I_byte_last,
    input wire [15:0] I_byte_data,
    input wire [31:0] I_byte_epoch,
    output wire [1:0] O_byte_ready,O_byte_discarded,
    input wire [1:0] I_stream_error_valid,
    input wire [31:0] I_stream_error_epoch,
    input wire [1:0] I_recycle_valid,
    output wire [1:0] O_recycle_ready,O_recycle_done,O_available,
    output wire [1:0] O_cancel_valid,
    input wire [1:0] I_cancel_ready,
    output wire [31:0] O_cancel_epoch,
    output wire [1:0] O_io_retire_request,
    input wire [1:0] I_io_retired,
    output wire [1:0] O_source_busy,
    output wire [63:0] O_written_frames,
    // Everything below is in the audio domain (including event ready).
    input wire I_sample_tick,I_play_valid,
    output wire O_play_ready,
    input wire I_fade_valid,I_target_b,
    output wire O_fade_ready,
    input wire I_silence_valid,
    output wire O_silence_ready,O_silence_started,O_silence_done,
    input wire I_pause,I_pause_allow,
    output wire O_paused,O_pause_busy,
    input wire [4:0] I_volume,
    input wire I_mute,I_prompt_valid,
    input wire [23:0] I_prompt_left,I_prompt_right,
    output wire O_sample_valid,
    output wire [23:0] O_left,O_right,
    output wire O_clipped,O_fade_done,O_active_b,O_busy,O_started,
    output wire [1:0] O_loaded,O_enabled,O_end,O_consumed,O_underrun,O_release,
    output wire [63:0] O_next_index,
    output wire [1:0] O_need_fill,O_failed,O_slot_stopping,
    output wire [1:0] O_event_valid,
    input wire [1:0] I_event_ready,
    output wire [1:0] O_event_header,
    output wire [31:0] O_event_epoch,
    output wire [63:0] O_event_total_frames,O_event_written_frames,
    output wire [7:0] O_event_error,
    input wire I_bind_valid,
    output wire O_bind_ready,
    input wire [31:0] I_bind_display_epoch,
    input wire [15:0] I_bind_display_tag,
    input wire I_bind_slot,
    input wire [15:0] I_bind_track_epoch,
    input wire [31:0] I_bind_track_serial,I_bind_start_index,
    input wire I_bind_reuse_active,I_unbind,I_bind_abort,
    input wire I_pending_valid,
    input wire [31:0] I_pending_epoch,
    input wire [15:0] I_pending_tag,
    input wire I_display_audio_applied,
    output wire O_audio_ready,
    output wire [31:0] O_audio_epoch,
    output wire [1:0] O_track_known,
    output wire [31:0] O_track_epochs,
    output wire [63:0] O_track_serials,O_track_totals,
    output wire O_bound,O_binding_revoked,
    output wire [3:0] O_bind_error,
    output wire O_audio_accepted,
    output wire [31:0] O_audio_accepted_epoch,
    output wire [15:0] O_audio_accepted_tag,
    output wire O_prepare_contract_fault,O_prepare_quarantined,O_prepare_response_discarded
);
    wire S_audio_reset;
    wire [1:0] S_clear,S_idle,S_pcm_valid,S_pcm_ready,S_prefilled;
    wire [1:0] S_load_valid,S_load_ready,S_load_error;
    wire [47:0] S_left,S_right;
    wire [2*(FIFO_ADDR_BITS+1)-1:0] S_level;
    wire [63:0] S_total,S_start_index;
    wire S_play_ready,S_fade_ready,S_silence_ready;
    wire S_commands_allowed=!(|O_slot_stopping) && !(|S_clear);
    // Qualify early commands so they cannot block the metadata needed to start.
    wire S_play_valid=I_play_valid && O_loaded[0] && S_commands_allowed;
    wire S_fade_valid=I_fade_valid && O_loaded[I_target_b] && S_commands_allowed;
    genvar G_slot;
    reset_sync u_audio_reset (
        .I_clk(I_audio_clk),.I_async_reset(I_async_reset),.O_reset(S_audio_reset));
    assign O_play_ready=S_play_ready && O_loaded[0] && S_commands_allowed;
    assign O_silence_ready=S_silence_ready && S_commands_allowed;
    assign O_fade_ready=S_fade_ready && O_loaded[I_target_b] && S_commands_allowed;
    generate for (G_slot=0; G_slot<2; G_slot=G_slot+1) begin : g_slot
        wav_audio_slot #(.FIFO_ADDR_BITS(FIFO_ADDR_BITS),.PREFILL_FRAMES(PREFILL_FRAMES),
            .LOW_FRAMES(LOW_FRAMES)) u_slot (
            .I_decode_clk(I_decode_clk),.I_audio_clk(I_audio_clk),.I_async_reset(I_async_reset),
            .I_start_valid(I_start_valid[G_slot]),.O_start_ready(O_start_ready[G_slot]),
            .I_file_size(I_file_size[G_slot*32+:32]),.I_start_index(I_start_index[G_slot*32+:32]),.I_epoch(I_epoch[G_slot*16+:16]),
            .I_byte_valid(I_byte_valid[G_slot]),.I_byte_last(I_byte_last[G_slot]),
            .I_byte_data(I_byte_data[G_slot*8+:8]),.I_byte_epoch(I_byte_epoch[G_slot*16+:16]),
            .O_byte_ready(O_byte_ready[G_slot]),.O_byte_discarded(O_byte_discarded[G_slot]),
            .I_stream_error_valid(I_stream_error_valid[G_slot]),
            .I_stream_error_epoch(I_stream_error_epoch[G_slot*16+:16]),
            .I_recycle_valid(I_recycle_valid[G_slot]),.O_recycle_ready(O_recycle_ready[G_slot]),
            .O_recycle_done(O_recycle_done[G_slot]),.O_available(O_available[G_slot]),
            .O_cancel_valid(O_cancel_valid[G_slot]),.I_cancel_ready(I_cancel_ready[G_slot]),
            .O_cancel_epoch(O_cancel_epoch[G_slot*16+:16]),
            .O_io_retire_request(O_io_retire_request[G_slot]),.I_io_retired(I_io_retired[G_slot]),
            .O_source_busy(O_source_busy[G_slot]),.O_written_frames(O_written_frames[G_slot*32+:32]),
            .O_stop(O_slot_stopping[G_slot]),.O_clear(S_clear[G_slot]),.I_idle(S_idle[G_slot]),
            .O_pcm_valid(S_pcm_valid[G_slot]),.I_pcm_ready(S_pcm_ready[G_slot]),
            .O_left(S_left[G_slot*24+:24]),.O_right(S_right[G_slot*24+:24]),
            .O_level(S_level[G_slot*(FIFO_ADDR_BITS+1)+:(FIFO_ADDR_BITS+1)]),
            .O_prefilled(S_prefilled[G_slot]),.O_need_fill(O_need_fill[G_slot]),.O_failed(O_failed[G_slot]),
            .O_load_valid(S_load_valid[G_slot]),.I_load_ready(S_load_ready[G_slot]),
            .O_total_frames(S_total[G_slot*32+:32]),.O_start_index(S_start_index[G_slot*32+:32]),
            .O_event_valid(O_event_valid[G_slot]),.I_event_ready(I_event_ready[G_slot]),
            .O_event_header(O_event_header[G_slot]),.O_event_epoch(O_event_epoch[G_slot*16+:16]),
            .O_event_total_frames(O_event_total_frames[G_slot*32+:32]),
            .O_event_written_frames(O_event_written_frames[G_slot*32+:32]),
            .O_event_error(O_event_error[G_slot*4+:4]));
    end endgenerate

    audio_playback #(.FIFO_ADDR_BITS(FIFO_ADDR_BITS),.FADE_SAMPLES(FADE_SAMPLES)) u_playback (
        .I_clk(I_audio_clk),.I_reset(S_audio_reset),.I_sample_tick(I_sample_tick),
        .I_a_stop(O_slot_stopping[0]),.I_b_stop(O_slot_stopping[1]),
        .I_a_clear(S_clear[0]),.I_b_clear(S_clear[1]),.O_a_idle(S_idle[0]),.O_b_idle(S_idle[1]),
        .I_a_valid(S_pcm_valid[0]),.I_b_valid(S_pcm_valid[1]),
        .O_a_ready(S_pcm_ready[0]),.O_b_ready(S_pcm_ready[1]),
        .I_a_left(S_left[23:0]),.I_a_right(S_right[23:0]),
        .I_b_left(S_left[47:24]),.I_b_right(S_right[47:24]),
        .I_a_level(S_level[FIFO_ADDR_BITS:0]),.I_b_level(S_level[2*(FIFO_ADDR_BITS+1)-1:FIFO_ADDR_BITS+1]),
        .I_a_prefilled(S_prefilled[0]),.I_b_prefilled(S_prefilled[1]),
        .I_a_load_valid(S_load_valid[0]),.I_b_load_valid(S_load_valid[1]),
        .O_a_load_ready(S_load_ready[0]),.O_b_load_ready(S_load_ready[1]),
        .I_a_total_frames(S_total[31:0]),.I_a_start_index(S_start_index[31:0]),
        .I_b_total_frames(S_total[63:32]),.I_b_start_index(S_start_index[63:32]),
        .O_a_load_error(S_load_error[0]),.O_b_load_error(S_load_error[1]),
        .O_a_loaded(O_loaded[0]),.O_b_loaded(O_loaded[1]),
        .O_a_next_index(O_next_index[31:0]),.O_b_next_index(O_next_index[63:32]),
        .O_a_end(O_end[0]),.O_b_end(O_end[1]),
        .I_start_valid(S_play_valid),.O_start_ready(S_play_ready),
        .I_fade_valid(S_fade_valid),.I_target_b(I_target_b),.O_fade_ready(S_fade_ready),
        .I_silence_valid(I_silence_valid && S_commands_allowed),.O_silence_ready(S_silence_ready),
        .O_silence_started(O_silence_started),.O_silence_done(O_silence_done),
        .I_pause(I_pause),.I_pause_allow(I_pause_allow),.O_paused(O_paused),.O_pause_busy(O_pause_busy),
        .O_a_enabled(O_enabled[0]),.O_b_enabled(O_enabled[1]),
        .O_a_consumed(O_consumed[0]),.O_b_consumed(O_consumed[1]),
        .O_a_underrun(O_underrun[0]),.O_b_underrun(O_underrun[1]),
        .O_release_a(O_release[0]),.O_release_b(O_release[1]),
        .I_volume(I_volume),.I_mute(I_mute),.I_prompt_valid(I_prompt_valid),
        .I_prompt_left(I_prompt_left),.I_prompt_right(I_prompt_right),
        .O_sample_valid(O_sample_valid),.O_left(O_left),.O_right(O_right),.O_clipped(O_clipped),
        .O_fade_done(O_fade_done),.O_active_b(O_active_b),.O_busy(O_busy),.O_started(O_started));
    audio_prepare_guard #(.FIFO_ADDR_BITS(FIFO_ADDR_BITS)) u_prepare_guard (
        .I_clk(I_audio_clk),.I_reset(S_audio_reset),
        .I_clear(S_clear),.I_stop(O_slot_stopping),.I_failed(O_failed),
        .I_loaded(O_loaded),.I_enabled(O_enabled),.I_end(O_end),
        .I_pcm_valid(S_pcm_valid),.I_prefilled(S_prefilled),.I_level(S_level),.I_next_index(O_next_index),
        .I_event_valid(O_event_valid),.I_event_ready(I_event_ready),.I_event_header(O_event_header),
        .I_event_epoch(O_event_epoch),.I_event_total(O_event_total_frames),
        .I_event_written(O_event_written_frames),.I_event_error(O_event_error),
        .I_bind_valid(I_bind_valid),.O_bind_ready(O_bind_ready),
        .I_bind_display_epoch(I_bind_display_epoch),.I_bind_display_tag(I_bind_display_tag),
        .I_bind_slot(I_bind_slot),.I_bind_track_epoch(I_bind_track_epoch),
        .I_bind_track_serial(I_bind_track_serial),.I_bind_start_index(I_bind_start_index),
        .I_bind_reuse_active(I_bind_reuse_active),.I_unbind(I_unbind),.I_abort(I_bind_abort),
        .I_pause_busy(O_pause_busy),.I_playback_busy(O_busy),
        .I_pending_valid(I_pending_valid),.I_pending_epoch(I_pending_epoch),.I_pending_tag(I_pending_tag),
        .I_display_audio_applied(I_display_audio_applied),
        .O_audio_ready(O_audio_ready),.O_audio_epoch(O_audio_epoch),
        .O_track_known(O_track_known),.O_track_epochs(O_track_epochs),
        .O_track_serials(O_track_serials),.O_track_totals(O_track_totals),
        .O_bound(O_bound),.O_binding_revoked(O_binding_revoked),.O_bind_error(O_bind_error),
        .O_accepted(O_audio_accepted),.O_accepted_epoch(O_audio_accepted_epoch),.O_accepted_tag(O_audio_accepted_tag),
        .O_contract_fault(O_prepare_contract_fault),.O_quarantined(O_prepare_quarantined),
        .O_response_discarded(O_prepare_response_discarded)
    );
endmodule
