// Actual pin CDC + whole transition owner, one video/audio clock and shared reset.
// Slot status/mutation inputs are host-domain; event/audio controls are video-domain.
module playback_image_pipeline #(
    parameter integer STOP_PENDING_AUDIO=0
) (
    input wire I_host_clk,
    input wire I_video_clk,
    input wire I_async_reset,
    input wire I_clock_enable,
    input wire [31:0] I_time,
    input wire I_frame_start,
    input wire I_sample_tick,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    input wire [246:0] I_config,
    input wire [2:0] I_effect,
    input wire [15:0] I_duration_frames,
    input wire signed [6:0] I_av_offset_steps,
    input wire [1:0] I_audio_action,
    input wire I_audio_slot,
    input wire [15:0] I_track_epoch,
    input wire [31:0] I_track_serial,
    input wire [31:0] I_start_index,
    input wire [137:0] I_display_leases,
    input wire I_pause,
    input wire I_abort,
    output wire O_pause_allow,
    output wire [1:0] O_image_hold,
    output wire [1:0] O_audio_hold,
    output wire [246:0] O_frozen_config,
    output wire O_audio_bind_valid,
    input wire I_audio_bind_ready,
    output wire [31:0] O_audio_bind_epoch,
    output wire [15:0] O_audio_bind_tag,
    output wire O_audio_bind_slot,
    output wire [15:0] O_audio_bind_track_epoch,
    output wire [31:0] O_audio_bind_serial,
    output wire [31:0] O_audio_bind_index,
    output wire O_audio_bind_reuse,
    output wire O_audio_pending,
    output wire O_audio_unbind,
    input wire I_audio_bound,
    input wire [3:0] I_audio_bind_error,
    input wire I_audio_ready,
    input wire [31:0] I_audio_epoch,
    input wire [1:0] I_track_known,
    input wire [1:0] I_track_enabled,
    input wire [1:0] I_track_consumed,
    input wire [31:0] I_track_epochs,
    input wire [63:0] I_track_serials,
    input wire [63:0] I_track_totals,
    input wire [63:0] I_track_next_index,
    output wire O_play_valid,
    output wire O_fade_valid,
    output wire O_target_b,
    input wire I_play_ready,
    input wire I_fade_ready,
    input wire I_fade_done,
    input wire I_active_b,
    output wire O_silence_valid,
    input wire I_silence_ready,
    input wire I_silence_started,
    input wire I_silence_done,
    output wire O_audio_stop_request,
    input wire I_audio_stop_ack,
    output wire O_event_valid,
    input wire I_event_ready,
    output wire O_event_cancel,
    output wire [31:0] O_event_epoch,
    output wire [15:0] O_event_tag,
    output wire [15:0] O_event_index,
    output wire [2:0] O_event_effect,
    output wire [16:0] O_event_progress,
    output wire [31:0] O_event_target,
    output wire [246:0] O_event_config,
    input wire I_event_busy,
    input wire I_event_done_valid,
    output wire O_event_done_ready,
    input wire [31:0] I_event_done_epoch,
    input wire [15:0] I_event_done_tag,
    input wire [15:0] I_event_done_index,
    input wire [3:0] I_event_done_error,
    input wire I_event_done_applied,
    input wire I_event_done_retired,
    input wire [31:0] I_event_done_time,
    input wire [31:0] I_event_commit_epoch,
    input wire I_event_quarantined,
    input wire I_active_valid,
    input wire [246:0] I_active_config,
    input wire [31:0] I_active_epoch,
    input wire [15:0] I_active_tag,
    input wire I_recover_valid,
    input wire I_recover_source,
    output wire O_recover_ready,
    output wire O_busy,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [31:0] O_epoch,
    output wire [15:0] O_tag,
    output wire [3:0] O_error,
    output wire [3:0] O_timeline_error,
    output wire [3:0] O_settle_error,
    output wire [3:0] O_bind_error,
    output wire O_settled,
    output wire O_recovery_required,
    output wire O_recovery_result,
    output wire O_cancel_late,
    output wire O_selected_source,
    output wire O_video_started,
    output wire O_video_finished,
    output wire O_audio_started,
    output wire O_audio_finished,
    output wire [31:0] O_actual_start,
    output wire [31:0] O_actual_midpoint,
    output wire [31:0] O_actual_audio,
    output wire [31:0] O_dwell_start,
    output wire [31:0] O_settle_time,
    output wire [31:0] O_commit_epoch,
    output wire signed [31:0] O_anchor_error,
    output wire [16:0] O_last_progress,
    output wire O_quarantined,
    output wire O_response_discarded,
    input wire I_media_valid,
    input wire [31:0] I_media_generation,
    input wire [17:0] I_slot_states,
    input wire [191:0] I_slot_tokens,
    input wire [191:0] I_slot_generations,
    input wire [5:0] I_slot_resident,
    input wire [5:0] I_slot_stale,
    input wire [5:0] I_mutating_slots,
    output wire [137:0] O_host_reservation,
    output wire [5:0] O_host_pinned_slots,
    output wire O_host_busy,
    output wire O_host_quarantined,
    output wire [137:0] O_video_reservation,
    output wire [31:0] O_video_epoch,
    output wire [15:0] O_video_tag,
    input wire I_retry_pin_valid,
    output wire O_retry_pin_ready,
    output wire [3:0] O_pin_error,
    output wire O_transition_started,
    output wire O_sync_required,
    output wire O_retry_result,
    output wire [3:0] O_transition_error,
    output wire [137:0] O_images,
    output wire O_pin_quarantined,
    output wire O_pin_response_discarded
);
    wire S_reset;
    wire [403:0] S_input_command={I_epoch,I_tag,I_config,I_effect,I_duration_frames,I_av_offset_steps,
        I_audio_action,I_audio_slot,I_track_epoch,I_track_serial,I_start_index};
    wire S_c_O_start_ready;
    wire S_c_O_transition_start_valid;
    wire [403:0] S_c_O_command;
    wire S_c_O_transition_abort;
    wire S_c_O_transition_done_ready;
    wire S_c_O_recover_ready;
    wire S_c_O_transition_recover_valid;
    wire S_c_O_transition_recover_source;
    wire S_c_O_pin_update_valid;
    wire [31:0] S_c_O_pin_epoch;
    wire [15:0] S_c_O_pin_tag;
    wire [137:0] S_c_O_pin_reservation;
    wire S_c_O_pin_done_ready;
    wire S_c_O_retry_pin_ready;
    wire S_c_O_busy;
    wire S_c_O_done_valid;
    wire [31:0] S_c_O_epoch;
    wire [15:0] S_c_O_tag;
    wire [3:0] S_c_O_error;
    wire [3:0] S_c_O_pin_error;
    wire S_c_O_transition_started;
    wire S_c_O_sync_required;
    wire S_c_O_retry_result;
    wire S_c_O_cancel_late;
    wire S_c_O_quarantined;
    wire S_c_O_response_discarded;
    wire S_p_O_update_ready;
    wire S_p_O_done_valid;
    wire [31:0] S_p_O_epoch;
    wire [15:0] S_p_O_tag;
    wire [3:0] S_p_O_error;
    wire [137:0] S_p_O_images;
    wire [137:0] S_p_O_video_reservation;
    wire [31:0] S_p_O_video_epoch;
    wire [15:0] S_p_O_video_tag;
    wire S_p_O_video_busy;
    wire S_p_O_video_quarantined;
    wire S_p_O_video_response_discarded;
    wire [137:0] S_p_O_host_reservation;
    wire [5:0] S_p_O_host_pinned_slots;
    wire S_p_O_host_busy;
    wire S_p_O_host_quarantined;
    wire S_t_O_start_ready;
    wire S_t_O_pause_allow;
    wire [1:0] S_t_O_image_hold;
    wire [1:0] S_t_O_audio_hold;
    wire [246:0] S_t_O_frozen_config;
    wire S_t_O_audio_bind_valid;
    wire [31:0] S_t_O_audio_bind_epoch;
    wire [15:0] S_t_O_audio_bind_tag;
    wire S_t_O_audio_bind_slot;
    wire [15:0] S_t_O_audio_bind_track_epoch;
    wire [31:0] S_t_O_audio_bind_serial;
    wire [31:0] S_t_O_audio_bind_index;
    wire S_t_O_audio_bind_reuse;
    wire S_t_O_audio_pending;
    wire S_t_O_audio_unbind;
    wire S_t_O_play_valid;
    wire S_t_O_fade_valid;
    wire S_t_O_target_b;
    wire S_t_O_silence_valid;
    wire S_t_O_audio_stop_request;
    wire S_t_O_event_valid;
    wire S_t_O_event_cancel;
    wire [31:0] S_t_O_event_epoch;
    wire [15:0] S_t_O_event_tag;
    wire [15:0] S_t_O_event_index;
    wire [2:0] S_t_O_event_effect;
    wire [16:0] S_t_O_event_progress;
    wire [31:0] S_t_O_event_target;
    wire [246:0] S_t_O_event_config;
    wire S_t_O_event_done_ready;
    wire S_t_O_recover_ready;
    wire S_t_O_busy;
    wire S_t_O_done_valid;
    wire [31:0] S_t_O_epoch;
    wire [15:0] S_t_O_tag;
    wire [3:0] S_t_O_error;
    wire [3:0] S_t_O_timeline_error;
    wire [3:0] S_t_O_settle_error;
    wire [3:0] S_t_O_bind_error;
    wire S_t_O_settled;
    wire S_t_O_recovery_required;
    wire S_t_O_recovery_result;
    wire S_t_O_cancel_late;
    wire S_t_O_selected_source;
    wire S_t_O_video_started;
    wire S_t_O_video_finished;
    wire S_t_O_audio_started;
    wire S_t_O_audio_finished;
    wire [31:0] S_t_O_actual_start;
    wire [31:0] S_t_O_actual_midpoint;
    wire [31:0] S_t_O_actual_audio;
    wire [31:0] S_t_O_dwell_start;
    wire [31:0] S_t_O_settle_time;
    wire [31:0] S_t_O_commit_epoch;
    wire signed [31:0] S_t_O_anchor_error;
    wire [16:0] S_t_O_last_progress;
    wire S_t_O_quarantined;
    wire S_t_O_response_discarded;
    reset_sync u_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_reset));
    playback_image_ctrl u_ctrl (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_clock_enable(I_clock_enable),
        .I_start_valid(I_start_valid),
        .O_start_ready(S_c_O_start_ready),
        .I_command(S_input_command),
        .I_abort(I_abort),
        .O_transition_start_valid(S_c_O_transition_start_valid),
        .I_transition_start_ready(S_t_O_start_ready),
        .O_command(S_c_O_command),
        .O_transition_abort(S_c_O_transition_abort),
        .I_transition_busy(S_t_O_busy),
        .I_transition_done_valid(S_t_O_done_valid),
        .O_transition_done_ready(S_c_O_transition_done_ready),
        .I_transition_epoch(S_t_O_epoch),
        .I_transition_tag(S_t_O_tag),
        .I_transition_config(S_t_O_frozen_config),
        .I_transition_hold(S_t_O_image_hold),
        .I_transition_error(S_t_O_error),
        .I_transition_settled(S_t_O_settled),
        .I_transition_quarantined(S_t_O_quarantined),
        .I_recover_valid(I_recover_valid),
        .I_recover_source(I_recover_source),
        .O_recover_ready(S_c_O_recover_ready),
        .O_transition_recover_valid(S_c_O_transition_recover_valid),
        .O_transition_recover_source(S_c_O_transition_recover_source),
        .I_transition_recover_ready(S_t_O_recover_ready),
        .O_pin_update_valid(S_c_O_pin_update_valid),
        .I_pin_update_ready(S_p_O_update_ready),
        .O_pin_epoch(S_c_O_pin_epoch),
        .O_pin_tag(S_c_O_pin_tag),
        .O_pin_reservation(S_c_O_pin_reservation),
        .I_pin_done_valid(S_p_O_done_valid),
        .O_pin_done_ready(S_c_O_pin_done_ready),
        .I_pin_epoch(S_p_O_epoch),
        .I_pin_installed_epoch(S_p_O_video_epoch),
        .I_pin_tag(S_p_O_tag),
        .I_pin_installed_tag(S_p_O_video_tag),
        .I_pin_error(S_p_O_error),
        .I_pin_installed_reservation(S_p_O_video_reservation),
        .I_images(S_p_O_images),
        .I_pin_quarantined(S_p_O_video_quarantined),
        .I_retry_pin_valid(I_retry_pin_valid),
        .O_retry_pin_ready(S_c_O_retry_pin_ready),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(I_done_ready),
        .O_epoch(S_c_O_epoch),
        .O_tag(S_c_O_tag),
        .O_error(S_c_O_error),
        .O_pin_error(S_c_O_pin_error),
        .O_transition_started(S_c_O_transition_started),
        .O_sync_required(S_c_O_sync_required),
        .O_retry_result(S_c_O_retry_result),
        .O_cancel_late(S_c_O_cancel_late),
        .O_quarantined(S_c_O_quarantined),
        .O_response_discarded(S_c_O_response_discarded)
    );
    image_reservation_cdc u_pins (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_video_enable(I_clock_enable),
        .I_update_valid(S_c_O_pin_update_valid),
        .O_update_ready(S_p_O_update_ready),
        .I_epoch(S_c_O_pin_epoch),
        .I_tag(S_c_O_pin_tag),
        .I_reservation(S_c_O_pin_reservation),
        .O_done_valid(S_p_O_done_valid),
        .I_done_ready(S_c_O_pin_done_ready),
        .O_epoch(S_p_O_epoch),
        .O_tag(S_p_O_tag),
        .O_error(S_p_O_error),
        .O_images(S_p_O_images),
        .O_video_reservation(S_p_O_video_reservation),
        .O_video_epoch(S_p_O_video_epoch),
        .O_video_tag(S_p_O_video_tag),
        .O_video_busy(S_p_O_video_busy),
        .O_video_quarantined(S_p_O_video_quarantined),
        .O_video_response_discarded(S_p_O_video_response_discarded),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_slot_states(I_slot_states),
        .I_slot_tokens(I_slot_tokens),
        .I_slot_generations(I_slot_generations),
        .I_slot_resident(I_slot_resident),
        .I_slot_stale(I_slot_stale),
        .I_mutating_slots(I_mutating_slots),
        .O_host_reservation(S_p_O_host_reservation),
        .O_host_pinned_slots(S_p_O_host_pinned_slots),
        .O_host_busy(S_p_O_host_busy),
        .O_host_quarantined(S_p_O_host_quarantined)
    );
    playback_transition_owner #(.STOP_PENDING_AUDIO(STOP_PENDING_AUDIO)) u_transition (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_clock_enable(I_clock_enable),
        .I_time(I_time),
        .I_frame_start(I_frame_start),
        .I_sample_tick(I_sample_tick),
        .I_start_valid(S_c_O_transition_start_valid),
        .O_start_ready(S_t_O_start_ready),
        .I_epoch(S_c_O_command[403:372]),
        .I_tag(S_c_O_command[371:356]),
        .I_config(S_c_O_command[355:109]),
        .I_effect(S_c_O_command[108:106]),
        .I_duration_frames(S_c_O_command[105:90]),
        .I_av_offset_steps(S_c_O_command[89:83]),
        .I_audio_action(S_c_O_command[82:81]),
        .I_audio_slot(S_c_O_command[80]),
        .I_track_epoch(S_c_O_command[79:64]),
        .I_track_serial(S_c_O_command[63:32]),
        .I_start_index(S_c_O_command[31:0]),
        .I_images(S_p_O_images),
        .I_display_leases(I_display_leases),
        .I_pause(I_pause),
        .I_abort(S_c_O_transition_abort),
        .O_pause_allow(S_t_O_pause_allow),
        .O_image_hold(S_t_O_image_hold),
        .O_audio_hold(S_t_O_audio_hold),
        .O_frozen_config(S_t_O_frozen_config),
        .O_audio_bind_valid(S_t_O_audio_bind_valid),
        .I_audio_bind_ready(I_audio_bind_ready),
        .O_audio_bind_epoch(S_t_O_audio_bind_epoch),
        .O_audio_bind_tag(S_t_O_audio_bind_tag),
        .O_audio_bind_slot(S_t_O_audio_bind_slot),
        .O_audio_bind_track_epoch(S_t_O_audio_bind_track_epoch),
        .O_audio_bind_serial(S_t_O_audio_bind_serial),
        .O_audio_bind_index(S_t_O_audio_bind_index),
        .O_audio_bind_reuse(S_t_O_audio_bind_reuse),
        .O_audio_pending(S_t_O_audio_pending),
        .O_audio_unbind(S_t_O_audio_unbind),
        .I_audio_bound(I_audio_bound),
        .I_audio_bind_error(I_audio_bind_error),
        .I_audio_ready(I_audio_ready),
        .I_audio_epoch(I_audio_epoch),
        .I_track_known(I_track_known),
        .I_track_enabled(I_track_enabled),
        .I_track_consumed(I_track_consumed),
        .I_track_epochs(I_track_epochs),
        .I_track_serials(I_track_serials),
        .I_track_totals(I_track_totals),
        .I_track_next_index(I_track_next_index),
        .O_play_valid(S_t_O_play_valid),
        .O_fade_valid(S_t_O_fade_valid),
        .O_target_b(S_t_O_target_b),
        .I_play_ready(I_play_ready),
        .I_fade_ready(I_fade_ready),
        .I_fade_done(I_fade_done),
        .I_active_b(I_active_b),
        .O_silence_valid(S_t_O_silence_valid),
        .I_silence_ready(I_silence_ready),
        .I_silence_started(I_silence_started),
        .I_silence_done(I_silence_done),
        .O_audio_stop_request(S_t_O_audio_stop_request),
        .I_audio_stop_ack(I_audio_stop_ack),
        .O_event_valid(S_t_O_event_valid),
        .I_event_ready(I_event_ready),
        .O_event_cancel(S_t_O_event_cancel),
        .O_event_epoch(S_t_O_event_epoch),
        .O_event_tag(S_t_O_event_tag),
        .O_event_index(S_t_O_event_index),
        .O_event_effect(S_t_O_event_effect),
        .O_event_progress(S_t_O_event_progress),
        .O_event_target(S_t_O_event_target),
        .O_event_config(S_t_O_event_config),
        .I_event_busy(I_event_busy),
        .I_event_done_valid(I_event_done_valid),
        .O_event_done_ready(S_t_O_event_done_ready),
        .I_event_done_epoch(I_event_done_epoch),
        .I_event_done_tag(I_event_done_tag),
        .I_event_done_index(I_event_done_index),
        .I_event_done_error(I_event_done_error),
        .I_event_done_applied(I_event_done_applied),
        .I_event_done_retired(I_event_done_retired),
        .I_event_done_time(I_event_done_time),
        .I_event_commit_epoch(I_event_commit_epoch),
        .I_event_quarantined(I_event_quarantined),
        .I_active_valid(I_active_valid),
        .I_active_config(I_active_config),
        .I_active_epoch(I_active_epoch),
        .I_active_tag(I_active_tag),
        .I_recover_valid(S_c_O_transition_recover_valid),
        .I_recover_source(S_c_O_transition_recover_source),
        .O_recover_ready(S_t_O_recover_ready),
        .O_busy(S_t_O_busy),
        .O_done_valid(S_t_O_done_valid),
        .I_done_ready(S_c_O_transition_done_ready),
        .O_epoch(S_t_O_epoch),
        .O_tag(S_t_O_tag),
        .O_error(S_t_O_error),
        .O_timeline_error(S_t_O_timeline_error),
        .O_settle_error(S_t_O_settle_error),
        .O_bind_error(S_t_O_bind_error),
        .O_settled(S_t_O_settled),
        .O_recovery_required(S_t_O_recovery_required),
        .O_recovery_result(S_t_O_recovery_result),
        .O_cancel_late(S_t_O_cancel_late),
        .O_selected_source(S_t_O_selected_source),
        .O_video_started(S_t_O_video_started),
        .O_video_finished(S_t_O_video_finished),
        .O_audio_started(S_t_O_audio_started),
        .O_audio_finished(S_t_O_audio_finished),
        .O_actual_start(S_t_O_actual_start),
        .O_actual_midpoint(S_t_O_actual_midpoint),
        .O_actual_audio(S_t_O_actual_audio),
        .O_dwell_start(S_t_O_dwell_start),
        .O_settle_time(S_t_O_settle_time),
        .O_commit_epoch(S_t_O_commit_epoch),
        .O_anchor_error(S_t_O_anchor_error),
        .O_last_progress(S_t_O_last_progress),
        .O_quarantined(S_t_O_quarantined),
        .O_response_discarded(S_t_O_response_discarded)
    );
    assign O_start_ready=S_c_O_start_ready;
    assign O_recover_ready=S_c_O_recover_ready;
    assign O_retry_pin_ready=S_c_O_retry_pin_ready;
    assign O_done_valid=S_c_O_done_valid;
    assign O_epoch=S_c_O_epoch;
    assign O_tag=S_c_O_tag;
    assign O_error=S_c_O_error;
    assign O_pin_error=S_c_O_pin_error;
    assign O_transition_started=S_c_O_transition_started;
    assign O_sync_required=S_c_O_sync_required;
    assign O_retry_result=S_c_O_retry_result;
    assign O_images=S_p_O_images;
    assign O_video_reservation=S_p_O_video_reservation;
    assign O_video_epoch=S_p_O_video_epoch;
    assign O_video_tag=S_p_O_video_tag;
    assign O_host_reservation=S_p_O_host_reservation;
    assign O_host_pinned_slots=S_p_O_host_pinned_slots;
    assign O_host_busy=S_p_O_host_busy;
    assign O_host_quarantined=S_p_O_host_quarantined;
    assign O_pause_allow=S_t_O_pause_allow;
    assign O_audio_hold=S_t_O_audio_hold;
    assign O_audio_bind_valid=S_t_O_audio_bind_valid;
    assign O_audio_bind_epoch=S_t_O_audio_bind_epoch;
    assign O_audio_bind_tag=S_t_O_audio_bind_tag;
    assign O_audio_bind_slot=S_t_O_audio_bind_slot;
    assign O_audio_bind_track_epoch=S_t_O_audio_bind_track_epoch;
    assign O_audio_bind_serial=S_t_O_audio_bind_serial;
    assign O_audio_bind_index=S_t_O_audio_bind_index;
    assign O_audio_bind_reuse=S_t_O_audio_bind_reuse;
    assign O_audio_pending=S_t_O_audio_pending;
    assign O_audio_unbind=S_t_O_audio_unbind;
    assign O_play_valid=S_t_O_play_valid;
    assign O_fade_valid=S_t_O_fade_valid;
    assign O_target_b=S_t_O_target_b;
    assign O_silence_valid=S_t_O_silence_valid;
    assign O_audio_stop_request=S_t_O_audio_stop_request;
    assign O_event_valid=S_t_O_event_valid;
    assign O_event_cancel=S_t_O_event_cancel;
    assign O_event_epoch=S_t_O_event_epoch;
    assign O_event_tag=S_t_O_event_tag;
    assign O_event_index=S_t_O_event_index;
    assign O_event_effect=S_t_O_event_effect;
    assign O_event_progress=S_t_O_event_progress;
    assign O_event_target=S_t_O_event_target;
    assign O_event_config=S_t_O_event_config;
    assign O_event_done_ready=S_t_O_event_done_ready;
    assign O_timeline_error=S_c_O_transition_started ? S_t_O_timeline_error : 0;
    assign O_settle_error=S_c_O_transition_started ? S_t_O_settle_error : 0;
    assign O_bind_error=S_c_O_transition_started ? S_t_O_bind_error : 0;
    assign O_settled=S_c_O_transition_started ? S_t_O_settled : 0;
    assign O_recovery_result=S_c_O_transition_started ? S_t_O_recovery_result : 0;
    assign O_selected_source=S_c_O_transition_started ? S_t_O_selected_source : 0;
    assign O_video_started=S_c_O_transition_started ? S_t_O_video_started : 0;
    assign O_video_finished=S_c_O_transition_started ? S_t_O_video_finished : 0;
    assign O_audio_started=S_c_O_transition_started ? S_t_O_audio_started : 0;
    assign O_audio_finished=S_c_O_transition_started ? S_t_O_audio_finished : 0;
    assign O_actual_start=S_c_O_transition_started ? S_t_O_actual_start : 0;
    assign O_actual_midpoint=S_c_O_transition_started ? S_t_O_actual_midpoint : 0;
    assign O_actual_audio=S_c_O_transition_started ? S_t_O_actual_audio : 0;
    assign O_dwell_start=S_c_O_transition_started ? S_t_O_dwell_start : 0;
    assign O_settle_time=S_c_O_transition_started ? S_t_O_settle_time : 0;
    assign O_commit_epoch=S_c_O_transition_started ? S_t_O_commit_epoch : 0;
    assign O_anchor_error=S_c_O_transition_started ? S_t_O_anchor_error : 0;
    assign O_last_progress=S_c_O_transition_started ? S_t_O_last_progress : 0;
    assign O_busy=S_c_O_busy;
    assign O_quarantined=S_c_O_quarantined || (S_c_O_transition_started && S_t_O_quarantined);
    assign O_response_discarded=S_c_O_response_discarded || S_t_O_response_discarded;
    assign O_image_hold=S_c_O_transition_started ? S_t_O_image_hold : S_p_O_video_reservation[137:136];
    assign O_frozen_config=S_c_O_command[355:109];
    assign O_cancel_late=S_c_O_cancel_late || (S_c_O_transition_started && S_t_O_cancel_late);
    assign O_recovery_required=S_c_O_sync_required || (S_c_O_transition_started && S_t_O_recovery_required);
    assign O_transition_error=S_c_O_transition_started ? S_t_O_error : 4'd0;
    assign O_pin_quarantined=S_p_O_video_quarantined;
    assign O_pin_response_discarded=S_p_O_video_response_discarded;
endmodule
