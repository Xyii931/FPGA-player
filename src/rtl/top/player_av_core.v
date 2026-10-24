// Real TF/BMP/two-WAV data path + actual pin/transition/display resources.
// Logical framebuffer memory ports need real acceptance and per-command retirement.
// Application item scheduling, physical SDRAM and HDMI PHY remain external.
module player_av_core (
    input wire I_host_clk,
    input wire I_sd_clk,
    input wire I_video_clk,
    input wire I_async_reset,
    input wire I_clock_enable,
    input wire I_pause,
    input wire I_alert_hold,
    output wire O_cmd_ready,
    output wire O_result_valid,
    output wire [3:0] O_result_error,
    output wire [2:0] O_result_op,
    output wire [2:0] O_result_slot,
    output wire [1:0] O_result_owner,
    output wire [31:0] O_result_token,
    output wire [31:0] O_result_generation,
    output wire [20:0] O_result_base,
    output wire [17:0] O_slot_states,
    output wire [191:0] O_slot_tokens,
    output wire [191:0] O_slot_generations,
    output wire [191:0] O_slot_assets,
    output wire [17:0] O_slot_layouts,
    output wire [17:0] O_slot_readers,
    output wire [11:0] O_slot_rotations,
    output wire [5:0] O_slot_resident,
    output wire [5:0] O_slot_stale,
    output wire [5:0] O_cancel_loading,
    output wire O_token_exhausted,
    output wire O_display_start_ready,
    output wire O_display_busy,
    output wire O_display_done_valid,
    output wire [3:0] O_display_error,
    output wire [3:0] O_display_lease_error,
    output wire [3:0] O_display_commit_error,
    output wire [3:0] O_display_prepare_error,
    output wire [3:0] O_display_retire_error,
    input wire I_display_video_allow_apply,
    output wire O_display_host_quarantined,
    output wire O_display_host_response_discarded,
    output wire O_display_video_quarantined,
    output wire [15:0] O_display_tag,
    output wire [31:0] O_display_epoch,
    output wire [31:0] O_display_previous_epoch,
    output wire O_display_applied,
    output wire O_display_retired,
    output wire O_display_cancel_late,
    output wire [1:0] O_display_acquired_mask,
    output wire [1:0] O_display_released_mask,
    output wire [1:0] O_display_host_active_mask,
    output wire O_display_host_active_valid,
    output wire [31:0] O_display_host_active_epoch,
    output wire [246:0] O_display_host_active_config,
    output wire [1:0] O_display_host_reserve,
    output wire [1:0] O_display_source_idle,
    output wire [1:0] O_display_source_busy,
    output wire [1:0] O_display_owned,
    output wire [1:0] O_display_lease_valid,
    output wire [5:0] O_display_lease_slots,
    output wire [63:0] O_display_lease_tokens,
    output wire [63:0] O_display_lease_generations,
    output wire [1:0] O_display_lease_resident,
    output wire [1:0] O_display_source_block,
    output wire [1:0] O_display_reader_stop,
    output wire [1:0] O_display_video_retire_ack,
    output wire [1:0] O_display_source_fault,
    output wire [137:0] O_display_video_leases,
    output wire [31:0] O_display_video_lease_version,
    output wire [1:0] O_display_video_authorized,
    output wire [31:0] O_display_next_epoch,
    output wire O_display_pending_valid,
    output wire [246:0] O_display_pending_config,
    output wire [15:0] O_display_pending_tag,
    output wire [31:0] O_display_pending_epoch,
    output wire O_display_video_active_valid,
    output wire [246:0] O_display_video_active_config,
    output wire [15:0] O_display_video_active_tag,
    output wire O_display_video_response_discarded,
    input wire I_display_scan_stop,
    output wire O_display_scan_stop_ack,
    output wire [1:0] O_display_reader_retire_ack,
    output wire [1:0] O_display_reader_host_retired,
    output wire [1:0] O_display_source_in_use,
    output wire [1:0] O_display_source_owner_retired,
    output wire [1:0] O_display_source_pipeline_retired,
    output wire [8:0] O_display_prefetch_y,
    output wire [31:0] O_display_video_active_epoch,
    output wire O_display_frame_start,
    output wire O_display_local_applied,
    output wire [3:0] O_display_bank_busy,
    output wire O_display_valid,
    output wire O_display_hsync,
    output wire O_display_vsync,
    output wire O_display_de,
    output wire [15:0] O_display_x,
    output wire [15:0] O_display_y,
    output wire [23:0] O_display_rgb,
    output wire [31:0] O_display_pixel_epoch,
    output wire [15:0] O_display_pixel_tag,
    output wire O_display_repeated,
    output wire O_display_pixel_fault,
    output wire O_display_video_und,
    output wire [31:0] O_display_und_count,
    output wire [31:0] O_display_line_error_count,
    output wire [1:0] O_display_mem_valid,
    input wire [1:0] I_display_mem_ready,
    output wire [41:0] O_display_mem_addr,
    output wire [63:0] O_display_mem_tag,
    output wire [63:0] O_display_mem_token,
    output wire [63:0] O_display_mem_generation,
    output wire [63:0] O_display_mem_deadline,
    input wire [1:0] I_display_mem_valid,
    output wire [1:0] O_display_mem_ready,
    input wire [63:0] I_display_mem_data,
    input wire [63:0] I_display_mem_tag,
    input wire [63:0] I_display_mem_token,
    input wire [63:0] I_display_mem_generation,
    input wire [7:0] I_display_mem_error,
    output wire [31:0] O_display_host_time,
    output wire [31:0] O_display_video_time,
    output wire O_display_deadline_quarantined,
    output wire [31:0] O_display_prepare_target,
    input wire I_transition_start_valid,
    output wire O_transition_start_ready,
    input wire [31:0] I_transition_epoch,
    input wire [15:0] I_transition_tag,
    input wire [246:0] I_transition_config,
    input wire [2:0] I_transition_effect,
    input wire [15:0] I_transition_duration_frames,
    input wire signed [6:0] I_transition_av_offset_steps,
    input wire [1:0] I_transition_audio_action,
    input wire I_transition_audio_slot,
    input wire [15:0] I_transition_track_epoch,
    input wire [31:0] I_transition_track_serial,
    input wire [31:0] I_transition_start_index,
    input wire I_transition_abort,
    output wire O_transition_pause_allow,
    output wire [1:0] O_transition_image_hold,
    output wire [1:0] O_transition_audio_hold,
    output wire [246:0] O_transition_frozen_config,
    output wire O_transition_audio_bind_valid,
    output wire [31:0] O_transition_audio_bind_epoch,
    output wire [15:0] O_transition_audio_bind_tag,
    output wire O_transition_audio_bind_slot,
    output wire [15:0] O_transition_audio_bind_track_epoch,
    output wire [31:0] O_transition_audio_bind_serial,
    output wire [31:0] O_transition_audio_bind_index,
    output wire O_transition_audio_bind_reuse,
    output wire O_transition_audio_pending,
    output wire O_transition_audio_unbind,
    output wire O_transition_play_valid,
    output wire O_transition_fade_valid,
    output wire O_transition_target_b,
    output wire O_transition_silence_valid,
    output wire O_transition_audio_stop_request,
    output wire O_transition_event_valid,
    output wire O_transition_event_cancel,
    output wire [31:0] O_transition_event_epoch,
    output wire [15:0] O_transition_event_tag,
    output wire [15:0] O_transition_event_index,
    output wire [2:0] O_transition_event_effect,
    output wire [16:0] O_transition_event_progress,
    output wire [31:0] O_transition_event_target,
    output wire [246:0] O_transition_event_config,
    output wire O_transition_event_done_ready,
    input wire I_transition_recover_valid,
    input wire I_transition_recover_source,
    output wire O_transition_recover_ready,
    output wire O_transition_busy,
    output wire O_transition_done_valid,
    input wire I_transition_done_ready,
    output wire [31:0] O_transition_epoch,
    output wire [15:0] O_transition_tag,
    output wire [3:0] O_transition_error,
    output wire [3:0] O_transition_timeline_error,
    output wire [3:0] O_transition_settle_error,
    output wire [3:0] O_transition_bind_error,
    output wire O_transition_settled,
    output wire O_transition_recovery_required,
    output wire O_transition_recovery_result,
    output wire O_transition_cancel_late,
    output wire O_transition_selected_source,
    output wire O_transition_video_started,
    output wire O_transition_video_finished,
    output wire O_transition_audio_started,
    output wire O_transition_audio_finished,
    output wire [31:0] O_transition_actual_start,
    output wire [31:0] O_transition_actual_midpoint,
    output wire [31:0] O_transition_actual_audio,
    output wire [31:0] O_transition_dwell_start,
    output wire [31:0] O_transition_settle_time,
    output wire [31:0] O_transition_commit_epoch,
    output wire signed [31:0] O_transition_anchor_error,
    output wire [16:0] O_transition_last_progress,
    output wire O_transition_quarantined,
    output wire O_transition_response_discarded,
    output wire [137:0] O_transition_host_reservation,
    output wire [5:0] O_transition_host_pinned_slots,
    output wire O_transition_host_busy,
    output wire O_transition_host_quarantined,
    output wire [137:0] O_transition_video_reservation,
    output wire [31:0] O_transition_video_epoch,
    output wire [15:0] O_transition_video_tag,
    input wire I_transition_retry_pin_valid,
    output wire O_transition_retry_pin_ready,
    output wire [3:0] O_transition_pin_error,
    output wire O_transition_transition_started,
    output wire O_transition_sync_required,
    output wire O_transition_retry_result,
    output wire [3:0] O_transition_transition_error,
    output wire [137:0] O_transition_images,
    output wire O_transition_pin_quarantined,
    output wire O_transition_pin_response_discarded,
    output wire O_event_event_ready,
    output wire O_event_busy,
    output wire O_event_done_valid,
    output wire [31:0] O_event_epoch,
    output wire [15:0] O_event_tag,
    output wire [15:0] O_event_index,
    output wire [3:0] O_event_error,
    output wire [3:0] O_event_backend_error,
    output wire [3:0] O_event_lease_error,
    output wire [3:0] O_event_slot_error,
    output wire [3:0] O_event_commit_error,
    output wire [3:0] O_event_prepare_error,
    output wire [3:0] O_event_retire_error,
    output wire O_event_applied,
    output wire O_event_retired,
    output wire [31:0] O_event_apply_time,
    output wire [31:0] O_event_commit_epoch,
    output wire O_event_quarantined,
    output wire O_event_response_discarded,
    output wire O_event_target_valid,
    output wire [31:0] O_event_target_epoch,
    output wire [31:0] O_event_target_time,
    output wire [15:0] O_event_target_tag,
    output wire O_event_video_abort,
    output wire O_event_host_start_valid,
    output wire [246:0] O_event_host_config,
    output wire [15:0] O_event_host_tag,
    output wire O_event_host_abort,
    output wire O_event_host_done_ready,
    output wire O_event_host_quarantined,
    output wire O_event_host_response_discarded,
    output wire [2:0] O_slot_arbiter_client_ready,
    output wire [2:0] O_slot_arbiter_client_result_valid,
    output wire [96:0] O_slot_arbiter_client_result,
    output wire O_slot_arbiter_cmd_valid,
    output wire [114:0] O_slot_arbiter_cmd,
    output wire O_slot_arbiter_result_ready,
    output wire [5:0] O_slot_arbiter_mutating_slots,
    output wire O_slot_arbiter_busy,
    output wire O_slot_arbiter_contract_fault,
    output wire O_slot_arbiter_response_discarded,
    output wire O_sample_tick,
    output wire O_acr_valid,
    output wire [19:0] O_acr_n,
    output wire [19:0] O_acr_cts,
    output wire O_acr_overflow,
    input wire I_image_start_valid,
    output wire O_image_start_ready,
    input wire [15:0] I_image_tag,
    input wire [31:0] I_image_generation,
    input wire [31:0] I_image_asset,
    input wire [2:0] I_image_layout,
    input wire I_image_compose,
    input wire [3:0] I_image_parts,
    output wire O_image_part_needed,
    output wire [3:0] O_image_part_index,
    input wire I_image_part_valid,
    output wire O_image_part_ready,
    input wire [6:0] I_image_part_path_length,
    input wire [1:0] I_image_rotation,
    input wire I_image_abort,
    output wire O_image_slot_cmd_valid,
    output wire [2:0] O_image_slot_cmd_op,
    output wire [2:0] O_image_slot_cmd_slot,
    output wire [1:0] O_image_slot_cmd_owner,
    output wire [31:0] O_image_slot_cmd_token,
    output wire [31:0] O_image_slot_cmd_generation,
    output wire [31:0] O_image_slot_cmd_asset,
    output wire [2:0] O_image_slot_cmd_layout,
    output wire [1:0] O_image_slot_cmd_rotation,
    output wire O_image_slot_cmd_resident,
    output wire O_image_slot_cmd_success,
    output wire O_image_producer_retired,
    output wire O_image_memory_retired,
    output wire O_image_slot_result_ready,
    output wire O_image_busy,
    output wire O_image_progress,
    output wire O_image_done_valid,
    input wire I_image_done_ready,
    output wire [3:0] O_image_error,
    output wire [1:0] O_image_context,
    output wire [15:0] O_image_tag,
    output wire [31:0] O_image_generation,
    output wire [31:0] O_image_lease_token,
    output wire [2:0] O_image_slot,
    output wire O_image_published,
    output wire O_image_slot_owned,
    output wire O_image_file_started,
    output wire O_image_transform_started,
    output wire O_image_writer_started,
    output wire [3:0] O_image_file_source_error,
    output wire [3:0] O_image_parser_error,
    output wire [3:0] O_image_storage_error,
    output wire [3:0] O_image_transform_error,
    output wire [3:0] O_image_writer_error,
    output wire [3:0] O_image_memory_error,
    output wire [7:0] O_image_file_error,
    output wire [2:0] O_image_path_warning,
    output wire [31:0] O_image_file_size,
    output wire [31:0] O_image_accepted_writes,
    output wire [31:0] O_image_retired_writes,
    output wire [31:0] O_image_pixels,
    output wire O_image_response_discarded,
    input wire [31:0] I_image_sector_budget,
    input wire [6:0] I_image_path_length,
    input wire I_image_path_valid,
    output wire O_image_path_ready,
    input wire [7:0] I_image_path_data,
    input wire I_image_path_last,
    output wire O_image_mem_valid,
    input wire I_image_mem_ready,
    output wire O_image_mem_wr,
    output wire [20:0] O_image_mem_addr,
    output wire [31:0] O_image_mem_data,
    output wire [31:0] O_image_mem_tag,
    output wire [3:0] O_image_mem_mask,
    output wire [31:0] O_image_mem_lease_token,
    output wire [31:0] O_image_mem_generation,
    input wire I_image_mem_done_valid,
    output wire O_image_mem_done_ready,
    input wire [31:0] I_image_mem_done_tag,
    input wire [31:0] I_image_mem_done_lease_token,
    input wire [31:0] I_image_mem_done_generation,
    input wire [3:0] I_image_mem_done_error,
    input wire [15:0] I_image_rect_x,
    input wire [15:0] I_image_rect_y,
    input wire [15:0] I_image_rect_width,
    input wire [15:0] I_image_rect_height,
    input wire I_image_bilinear,
    input wire [31:0] I_image_clear_rgba,
    output wire O_image_evict_valid,
    output wire [114:0] O_image_evict_command,
    output wire O_image_evict_result_ready,
    output wire [3:0] O_image_loader_error,
    output wire [3:0] O_image_slot_error,
    output wire O_image_loader_started,
    output wire O_image_reused,
    output wire O_image_evicted,
    output wire O_image_quarantined,
    output wire O_image_stage_valid,
    output wire [5:0] O_image_staged_slots,
    input wire I_image_stage_release_valid,
    output wire O_image_stage_release_ready,
    input wire [2:0] I_image_stage_slot,
    input wire [31:0] I_image_stage_token,
    input wire [31:0] I_image_stage_generation,
    input wire I_image_stage_discard,
    output wire [227:0] O_image_frozen_request,
    output wire [31:0] O_image_loader_lease_token,
    output wire O_scan_start_ready,
    input wire I_scan_abort,
    input wire [31:0] I_scan_seed,
    input wire [31:0] I_scan_sector_budget,
    input wire [31:0] I_scan_directory_sector_budget,
    input wire [9:0] I_scan_directory_duration,
    input wire [9:0] I_scan_directory_transition_ms,
    input wire [2:0] I_scan_directory_transition,
    input wire [1:0] I_scan_directory_order,
    output wire O_scan_busy,
    output wire O_scan_done_valid,
    output wire [3:0] O_scan_error,
    output wire [3:0] O_scan_list_source_error,
    output wire [3:0] O_scan_list_build_error,
    output wire [3:0] O_scan_directory_build_error,
    output wire [6:0] O_scan_count,
    output wire O_scan_committed,
    output wire O_scan_used_directory,
    output wire O_scan_list_missing,
    output wire O_scan_list_started,
    output wire O_scan_directory_started,
    output wire [7:0] O_scan_list_warning,
    output wire [7:0] O_scan_directory_warning,
    output wire [1:0] O_scan_context,
    output wire [15:0] O_scan_tag,
    output wire [31:0] O_scan_generation,
    output wire [7:0] O_scan_file_error,
    output wire [3:0] O_scan_storage_error,
    output wire [2:0] O_scan_path_warning,
    output wire [31:0] O_scan_file_size,
    output wire O_scan_active_valid,
    output wire [6:0] O_scan_active_count,
    output wire [31:0] O_scan_active_generation,
    output wire [31:0] O_scan_active_revision,
    input wire I_scan_acquire_valid,
    output wire O_scan_acquire_ready,
    output wire O_scan_snapshot_valid,
    output wire [6:0] O_scan_snapshot_count,
    output wire [31:0] O_scan_snapshot_generation,
    output wire [31:0] O_scan_snapshot_revision,
    input wire I_scan_release_valid,
    output wire O_scan_release_ready,
    input wire I_scan_read_valid,
    output wire O_scan_read_ready,
    input wire [5:0] I_scan_read_index,
    input wire [1:0] I_scan_read_kind,
    input wire [6:0] I_scan_read_address,
    input wire [15:0] I_scan_read_tag,
    output wire O_scan_read_result_valid,
    input wire I_scan_read_result_ready,
    output wire [6:0] O_scan_read_file_length,
    output wire [6:0] O_scan_read_audio_length,
    output wire [5:0] O_scan_read_title_length,
    output wire [9:0] O_scan_read_duration,
    output wire [9:0] O_scan_read_transition_ms,
    output wire [2:0] O_scan_read_transition,
    output wire [6:0] O_scan_read_policy,
    output wire [7:0] O_scan_read_data,
    output wire [15:0] O_scan_read_tag,
    output wire [3:0] O_scan_read_error,
    output wire [7:0] O_scan_directory_error,
    output wire [7:0] O_scan_directory_primary_error,
    output wire [3:0] O_scan_directory_storage_error,
    output wire [2:0] O_scan_enum_warning,
    output wire [32:0] O_scan_directory_sectors,
    output wire [1:0] O_scan_active_order,
    output wire [1:0] O_scan_active_base_order,
    output wire O_scan_active_base_order_explicit,
    input wire I_scan_reorder_valid,
    output wire O_scan_reorder_ready,
    input wire [1:0] I_scan_reorder_order,
    input wire [31:0] I_scan_reorder_seed,
    input wire [31:0] I_scan_reorder_generation,
    input wire [15:0] I_scan_reorder_tag,
    input wire [5:0] I_scan_reorder_current_index,
    input wire I_scan_reorder_abort,
    output wire O_scan_reorder_done_valid,
    input wire I_scan_reorder_done_ready,
    output wire [3:0] O_scan_reorder_error,
    output wire [15:0] O_scan_reorder_tag,
    output wire [31:0] O_scan_reorder_generation,
    output wire [31:0] O_scan_reorder_revision,
    output wire [5:0] O_scan_reorder_current_index,
    input wire I_scan_order_override,
    input wire [1:0] I_scan_runtime_order,
    input wire [1:0] I_audio_file_start_valid,
    output wire [1:0] O_audio_file_start_ready,
    input wire [31:0] I_audio_file_tag,
    input wire [63:0] I_audio_file_generation,
    input wire [63:0] I_audio_file_sector_budget,
    input wire [63:0] I_audio_file_start_index,
    input wire [13:0] I_audio_file_path_length,
    input wire [1:0] I_audio_file_path_valid,
    output wire [1:0] O_audio_file_path_ready,
    input wire [15:0] I_audio_file_path_data,
    input wire [1:0] I_audio_file_path_last,
    input wire [1:0] I_audio_file_abort,
    output wire [1:0] O_audio_file_busy,
    output wire [1:0] O_audio_file_done_valid,
    input wire [1:0] I_audio_file_done_ready,
    output wire [7:0] O_audio_file_error,
    output wire [15:0] O_audio_file_file_error,
    output wire [7:0] O_audio_file_storage_error,
    output wire [5:0] O_audio_file_path_warning,
    output wire [3:0] O_audio_file_context,
    output wire [31:0] O_audio_file_tag,
    output wire [63:0] O_audio_file_generation,
    output wire [63:0] O_audio_file_file_size,
    output wire [1:0] O_audio_byte_discarded,
    input wire [1:0] I_audio_recycle_valid,
    output wire [1:0] O_audio_recycle_ready,
    output wire [1:0] O_audio_recycle_done,
    output wire [1:0] O_audio_available,
    output wire [1:0] O_audio_source_busy,
    output wire [63:0] O_audio_written_frames,
    output wire O_audio_play_ready,
    output wire O_audio_fade_ready,
    output wire O_audio_silence_ready,
    output wire O_audio_silence_started,
    output wire O_audio_silence_done,
    output wire O_audio_paused,
    output wire O_audio_pause_busy,
    input wire [4:0] I_audio_volume,
    input wire I_audio_mute,
    input wire I_audio_prompt_valid,
    input wire [23:0] I_audio_prompt_left,
    input wire [23:0] I_audio_prompt_right,
    output wire O_audio_sample_valid,
    output wire [23:0] O_audio_left,
    output wire [23:0] O_audio_right,
    output wire O_audio_clipped,
    output wire O_audio_fade_done,
    output wire O_audio_active_b,
    output wire O_audio_busy,
    output wire O_audio_started,
    output wire [1:0] O_audio_loaded,
    output wire [1:0] O_audio_enabled,
    output wire [1:0] O_audio_end,
    output wire [1:0] O_audio_consumed,
    output wire [1:0] O_audio_underrun,
    output wire [1:0] O_audio_release,
    output wire [63:0] O_audio_next_index,
    output wire [1:0] O_audio_need_fill,
    output wire [1:0] O_audio_failed,
    output wire [1:0] O_audio_slot_stopping,
    output wire [1:0] O_audio_event_valid,
    output wire [1:0] O_audio_event_header,
    output wire [31:0] O_audio_event_epoch,
    output wire [63:0] O_audio_event_total_frames,
    output wire [63:0] O_audio_event_written_frames,
    output wire [7:0] O_audio_event_error,
    output wire O_audio_bind_ready,
    output wire O_audio_audio_ready,
    output wire [31:0] O_audio_audio_epoch,
    output wire [1:0] O_audio_track_known,
    output wire [31:0] O_audio_track_epochs,
    output wire [63:0] O_audio_track_serials,
    output wire [63:0] O_audio_track_totals,
    output wire O_audio_bound,
    output wire O_audio_binding_revoked,
    output wire [3:0] O_audio_bind_error,
    output wire O_audio_audio_accepted,
    output wire [31:0] O_audio_audio_accepted_epoch,
    output wire [15:0] O_audio_audio_accepted_tag,
    output wire O_audio_prepare_contract_fault,
    output wire O_audio_prepare_quarantined,
    output wire O_audio_prepare_response_discarded,
    input wire I_storage_demo,
    input wire I_storage_recovery,
    output wire O_storage_demo_active,
    output wire O_storage_demo_ready,
    output wire O_storage_recovery_active,
    output wire [3:0] O_storage_demo_error,
    output wire O_storage_flash_valid,
    input wire I_storage_flash_ready,
    output wire [23:0] O_storage_flash_address,
    output wire [15:0] O_storage_flash_length,
    output wire [15:0] O_storage_flash_tag,
    input wire I_storage_flash_read_valid,
    output wire O_storage_flash_read_ready,
    input wire [7:0] I_storage_flash_read_data,
    input wire I_storage_flash_read_last,
    input wire I_storage_flash_done_valid,
    output wire O_storage_flash_done_ready,
    input wire [3:0] I_storage_flash_error,
    input wire [15:0] I_storage_flash_tag,
    output wire [3:0] O_storage_lease_grant,
    output wire O_storage_busy,
    output wire O_storage_quiescent,
    output wire [2:0] O_storage_leased_contexts,
    output wire [2:0] O_storage_descriptors,
    output wire [2:0] O_storage_pending_reads,
    output wire O_storage_contract_fault,
    output wire O_storage_response_discarded,
    output wire O_storage_mount_ready,
    output wire O_storage_mount_result_valid,
    output wire [7:0] O_storage_mount_error,
    output wire [3:0] O_storage_mount_storage_error,
    output wire [31:0] O_storage_mount_generation,
    output wire O_storage_mounted,
    output wire [31:0] O_storage_generation,
    output wire O_storage_card_ready,
    output wire O_storage_card_present,
    output wire [32:0] O_storage_capacity_sectors,
    output wire O_storage_sd_high_capacity,
    output wire [3:0] O_storage_sd_card_error,
    output wire O_storage_sd_ncs,
    output wire O_storage_sd_sclk,
    output wire O_storage_sd_mosi,
    input wire I_storage_sd_miso,
    input wire I_session_enable,
    input wire I_session_reload,
    input wire I_session_rescan,
    output wire O_session_client_abort,
    output wire O_session_allow_start,
    output wire O_session_ready,
    output wire O_session_busy,
    output wire O_session_scan_done,
    output wire [6:0] O_session_count,
    output wire [3:0] O_session_error,
    output wire [3:0] O_session_scan_error,
    output wire [7:0] O_session_mount_error,
    output wire [3:0] O_session_mount_storage_error,
    output wire [31:0] O_session_generation,
    output wire O_audio_stop_stop_ack,
    output wire O_audio_stop_video_busy,
    output wire O_audio_stop_host_busy,
    input wire I_bgm_start_valid,
    output wire O_bgm_start_ready,
    output wire O_bgm_need,
    input wire I_bgm_slot,
    input wire [15:0] I_bgm_track_epoch,
    input wire I_bgm_abort,
    output wire O_bgm_done_valid,
    input wire I_bgm_done_ready,
    output wire [7:0] O_bgm_result,
    input wire I_resident_enable,
    output wire O_resident_mem_valid,
    input wire I_resident_mem_ready,
    output wire O_resident_mem_wr,
    output wire [20:0] O_resident_mem_addr,
    output wire [31:0] O_resident_mem_data,
    output wire [31:0] O_resident_mem_tag,
    output wire [31:0] O_resident_mem_token,
    output wire [31:0] O_resident_mem_generation,
    output wire [3:0] O_resident_mem_mask,
    input wire I_resident_mem_result_valid,
    output wire O_resident_mem_result_ready,
    input wire I_resident_mem_result_wr,
    input wire [31:0] I_resident_mem_result_tag,
    input wire [31:0] I_resident_mem_result_token,
    input wire [31:0] I_resident_mem_result_generation,
    input wire [3:0] I_resident_mem_result_error,
    output wire O_resident_busy,
    output wire O_resident_ready,
    output wire [31:0] O_resident_token,
    output wire [31:0] O_resident_generation,
    output wire [3:0] O_resident_error,
    output wire O_resident_response_discarded
);
    wire S_io_O_sample_tick;
    wire S_io_O_acr_valid;
    wire [19:0] S_io_O_acr_n;
    wire [19:0] S_io_O_acr_cts;
    wire S_io_O_acr_overflow;
    wire S_io_O_image_start_ready;
    wire S_io_O_image_part_needed;
    wire [3:0] S_io_O_image_part_index;
    wire S_io_O_image_part_ready;
    wire S_io_O_image_slot_cmd_valid;
    wire [2:0] S_io_O_image_slot_cmd_op;
    wire [2:0] S_io_O_image_slot_cmd_slot;
    wire [1:0] S_io_O_image_slot_cmd_owner;
    wire [31:0] S_io_O_image_slot_cmd_token;
    wire [31:0] S_io_O_image_slot_cmd_generation;
    wire [31:0] S_io_O_image_slot_cmd_asset;
    wire [2:0] S_io_O_image_slot_cmd_layout;
    wire [1:0] S_io_O_image_slot_cmd_rotation;
    wire S_io_O_image_slot_cmd_resident;
    wire S_io_O_image_slot_cmd_success;
    wire S_io_O_image_producer_retired;
    wire S_io_O_image_memory_retired;
    wire S_io_O_image_slot_result_ready;
    wire S_io_O_image_busy;
    wire S_io_O_image_progress;
    wire S_io_O_image_done_valid;
    wire [3:0] S_io_O_image_error;
    wire [1:0] S_io_O_image_context;
    wire [15:0] S_io_O_image_tag;
    wire [31:0] S_io_O_image_generation;
    wire [31:0] S_io_O_image_lease_token;
    wire [2:0] S_io_O_image_slot;
    wire S_io_O_image_published;
    wire S_io_O_image_slot_owned;
    wire S_io_O_image_file_started;
    wire S_io_O_image_transform_started;
    wire S_io_O_image_writer_started;
    wire [3:0] S_io_O_image_file_source_error;
    wire [3:0] S_io_O_image_parser_error;
    wire [3:0] S_io_O_image_storage_error;
    wire [3:0] S_io_O_image_transform_error;
    wire [3:0] S_io_O_image_writer_error;
    wire [3:0] S_io_O_image_memory_error;
    wire [7:0] S_io_O_image_file_error;
    wire [2:0] S_io_O_image_path_warning;
    wire [31:0] S_io_O_image_file_size;
    wire [31:0] S_io_O_image_accepted_writes;
    wire [31:0] S_io_O_image_retired_writes;
    wire [31:0] S_io_O_image_pixels;
    wire S_io_O_image_response_discarded;
    wire S_io_O_image_path_ready;
    wire S_io_O_image_mem_valid;
    wire S_io_O_image_mem_wr;
    wire [20:0] S_io_O_image_mem_addr;
    wire [31:0] S_io_O_image_mem_data;
    wire [31:0] S_io_O_image_mem_tag;
    wire [3:0] S_io_O_image_mem_mask;
    wire [31:0] S_io_O_image_mem_lease_token;
    wire [31:0] S_io_O_image_mem_generation;
    wire S_io_O_image_mem_done_ready;
    wire S_io_O_image_evict_valid;
    wire [114:0] S_io_O_image_evict_command;
    wire S_io_O_image_evict_result_ready;
    wire [3:0] S_io_O_image_loader_error;
    wire [3:0] S_io_O_image_slot_error;
    wire S_io_O_image_loader_started;
    wire S_io_O_image_reused;
    wire S_io_O_image_evicted;
    wire S_io_O_image_quarantined;
    wire S_io_O_image_stage_valid;
    wire [5:0] S_io_O_image_staged_slots;
    wire S_io_O_image_stage_release_ready;
    wire [227:0] S_io_O_image_frozen_request;
    wire [31:0] S_io_O_image_loader_lease_token;
    wire S_io_O_scan_start_ready;
    wire S_io_O_scan_busy;
    wire S_io_O_scan_done_valid;
    wire [3:0] S_io_O_scan_error;
    wire [3:0] S_io_O_scan_list_source_error;
    wire [3:0] S_io_O_scan_list_build_error;
    wire [3:0] S_io_O_scan_directory_build_error;
    wire [6:0] S_io_O_scan_count;
    wire S_io_O_scan_committed;
    wire S_io_O_scan_used_directory;
    wire S_io_O_scan_list_missing;
    wire S_io_O_scan_list_started;
    wire S_io_O_scan_directory_started;
    wire [7:0] S_io_O_scan_list_warning;
    wire [7:0] S_io_O_scan_directory_warning;
    wire [1:0] S_io_O_scan_context;
    wire [15:0] S_io_O_scan_tag;
    wire [31:0] S_io_O_scan_generation;
    wire [7:0] S_io_O_scan_file_error;
    wire [3:0] S_io_O_scan_storage_error;
    wire [2:0] S_io_O_scan_path_warning;
    wire [31:0] S_io_O_scan_file_size;
    wire S_io_O_scan_active_valid;
    wire [6:0] S_io_O_scan_active_count;
    wire [31:0] S_io_O_scan_active_generation;
    wire [31:0] S_io_O_scan_active_revision;
    wire S_io_O_scan_acquire_ready;
    wire S_io_O_scan_snapshot_valid;
    wire [6:0] S_io_O_scan_snapshot_count;
    wire [31:0] S_io_O_scan_snapshot_generation;
    wire [31:0] S_io_O_scan_snapshot_revision;
    wire S_io_O_scan_release_ready;
    wire S_io_O_scan_read_ready;
    wire S_io_O_scan_read_result_valid;
    wire [6:0] S_io_O_scan_read_file_length;
    wire [6:0] S_io_O_scan_read_audio_length;
    wire [5:0] S_io_O_scan_read_title_length;
    wire [9:0] S_io_O_scan_read_duration;
    wire [9:0] S_io_O_scan_read_transition_ms;
    wire [2:0] S_io_O_scan_read_transition;
    wire [6:0] S_io_O_scan_read_policy;
    wire [7:0] S_io_O_scan_read_data;
    wire [15:0] S_io_O_scan_read_tag;
    wire [3:0] S_io_O_scan_read_error;
    wire [7:0] S_io_O_scan_directory_error;
    wire [7:0] S_io_O_scan_directory_primary_error;
    wire [3:0] S_io_O_scan_directory_storage_error;
    wire [2:0] S_io_O_scan_enum_warning;
    wire [32:0] S_io_O_scan_directory_sectors;
    wire [1:0] S_io_O_scan_active_order;
    wire [1:0] S_io_O_scan_active_base_order;
    wire S_io_O_scan_active_base_order_explicit;
    wire S_io_O_scan_reorder_ready;
    wire S_io_O_scan_reorder_done_valid;
    wire [3:0] S_io_O_scan_reorder_error;
    wire [15:0] S_io_O_scan_reorder_tag;
    wire [31:0] S_io_O_scan_reorder_generation;
    wire [31:0] S_io_O_scan_reorder_revision;
    wire [5:0] S_io_O_scan_reorder_current_index;
    wire [1:0] S_io_O_audio_file_start_ready;
    wire [1:0] S_io_O_audio_file_path_ready;
    wire [1:0] S_io_O_audio_file_busy;
    wire [1:0] S_io_O_audio_file_done_valid;
    wire [7:0] S_io_O_audio_file_error;
    wire [15:0] S_io_O_audio_file_file_error;
    wire [7:0] S_io_O_audio_file_storage_error;
    wire [5:0] S_io_O_audio_file_path_warning;
    wire [3:0] S_io_O_audio_file_context;
    wire [31:0] S_io_O_audio_file_tag;
    wire [63:0] S_io_O_audio_file_generation;
    wire [63:0] S_io_O_audio_file_file_size;
    wire [1:0] S_io_O_audio_byte_discarded;
    wire [1:0] S_io_O_audio_recycle_ready;
    wire [1:0] S_io_O_audio_recycle_done;
    wire [1:0] S_io_O_audio_available;
    wire [1:0] S_io_O_audio_source_busy;
    wire [63:0] S_io_O_audio_written_frames;
    wire S_io_O_audio_play_ready;
    wire S_io_O_audio_fade_ready;
    wire S_io_O_audio_silence_ready;
    wire S_io_O_audio_silence_started;
    wire S_io_O_audio_silence_done;
    wire S_io_O_audio_paused;
    wire S_io_O_audio_pause_busy;
    wire S_io_O_audio_sample_valid;
    wire [23:0] S_io_O_audio_left;
    wire [23:0] S_io_O_audio_right;
    wire S_io_O_audio_clipped;
    wire S_io_O_audio_fade_done;
    wire S_io_O_audio_active_b;
    wire S_io_O_audio_busy;
    wire S_io_O_audio_started;
    wire [1:0] S_io_O_audio_loaded;
    wire [1:0] S_io_O_audio_enabled;
    wire [1:0] S_io_O_audio_end;
    wire [1:0] S_io_O_audio_consumed;
    wire [1:0] S_io_O_audio_underrun;
    wire [1:0] S_io_O_audio_release;
    wire [63:0] S_io_O_audio_next_index;
    wire [1:0] S_io_O_audio_need_fill;
    wire [1:0] S_io_O_audio_failed;
    wire [1:0] S_io_O_audio_slot_stopping;
    wire [1:0] S_io_O_audio_event_valid;
    wire [1:0] S_io_O_audio_event_header;
    wire [31:0] S_io_O_audio_event_epoch;
    wire [63:0] S_io_O_audio_event_total_frames;
    wire [63:0] S_io_O_audio_event_written_frames;
    wire [7:0] S_io_O_audio_event_error;
    wire S_io_O_audio_bind_ready;
    wire S_io_O_audio_audio_ready;
    wire [31:0] S_io_O_audio_audio_epoch;
    wire [1:0] S_io_O_audio_track_known;
    wire [31:0] S_io_O_audio_track_epochs;
    wire [63:0] S_io_O_audio_track_serials;
    wire [63:0] S_io_O_audio_track_totals;
    wire S_io_O_audio_bound;
    wire S_io_O_audio_binding_revoked;
    wire [3:0] S_io_O_audio_bind_error;
    wire S_io_O_audio_audio_accepted;
    wire [31:0] S_io_O_audio_audio_accepted_epoch;
    wire [15:0] S_io_O_audio_audio_accepted_tag;
    wire S_io_O_audio_prepare_contract_fault;
    wire S_io_O_audio_prepare_quarantined;
    wire S_io_O_audio_prepare_response_discarded;
    wire S_io_O_storage_demo_active;
    wire S_io_O_storage_demo_ready;
    wire S_io_O_storage_recovery_active;
    wire [3:0] S_io_O_storage_demo_error;
    wire S_io_O_storage_flash_valid;
    wire [23:0] S_io_O_storage_flash_address;
    wire [15:0] S_io_O_storage_flash_length;
    wire [15:0] S_io_O_storage_flash_tag;
    wire S_io_O_storage_flash_read_ready;
    wire S_io_O_storage_flash_done_ready;
    wire [3:0] S_io_O_storage_lease_grant;
    wire S_io_O_storage_busy;
    wire S_io_O_storage_quiescent;
    wire [2:0] S_io_O_storage_leased_contexts;
    wire [2:0] S_io_O_storage_descriptors;
    wire [2:0] S_io_O_storage_pending_reads;
    wire S_io_O_storage_contract_fault;
    wire S_io_O_storage_response_discarded;
    wire S_io_O_storage_mount_ready;
    wire S_io_O_storage_mount_result_valid;
    wire [7:0] S_io_O_storage_mount_error;
    wire [3:0] S_io_O_storage_mount_storage_error;
    wire [31:0] S_io_O_storage_mount_generation;
    wire S_io_O_storage_mounted;
    wire [31:0] S_io_O_storage_generation;
    wire S_io_O_storage_card_ready;
    wire S_io_O_storage_card_present;
    wire [32:0] S_io_O_storage_capacity_sectors;
    wire S_io_O_storage_sd_high_capacity;
    wire [3:0] S_io_O_storage_sd_card_error;
    wire S_io_O_storage_sd_ncs;
    wire S_io_O_storage_sd_sclk;
    wire S_io_O_storage_sd_mosi;
    wire S_io_O_session_client_abort;
    wire S_io_O_session_allow_start;
    wire S_io_O_session_ready;
    wire S_io_O_session_busy;
    wire S_io_O_session_scan_done;
    wire [6:0] S_io_O_session_count;
    wire [3:0] S_io_O_session_error;
    wire [3:0] S_io_O_session_scan_error;
    wire [7:0] S_io_O_session_mount_error;
    wire [3:0] S_io_O_session_mount_storage_error;
    wire [31:0] S_io_O_session_generation;
    wire S_transition_O_start_ready;
    wire S_transition_O_pause_allow;
    wire [1:0] S_transition_O_image_hold;
    wire [1:0] S_transition_O_audio_hold;
    wire [246:0] S_transition_O_frozen_config;
    wire S_transition_O_audio_bind_valid;
    wire [31:0] S_transition_O_audio_bind_epoch;
    wire [15:0] S_transition_O_audio_bind_tag;
    wire S_transition_O_audio_bind_slot;
    wire [15:0] S_transition_O_audio_bind_track_epoch;
    wire [31:0] S_transition_O_audio_bind_serial;
    wire [31:0] S_transition_O_audio_bind_index;
    wire S_transition_O_audio_bind_reuse;
    wire S_transition_O_audio_pending;
    wire S_transition_O_audio_unbind;
    wire S_transition_O_play_valid;
    wire S_transition_O_fade_valid;
    wire S_transition_O_target_b;
    wire S_transition_O_silence_valid;
    wire S_transition_O_audio_stop_request;
    wire S_transition_O_event_valid;
    wire S_transition_O_event_cancel;
    wire [31:0] S_transition_O_event_epoch;
    wire [15:0] S_transition_O_event_tag;
    wire [15:0] S_transition_O_event_index;
    wire [2:0] S_transition_O_event_effect;
    wire [16:0] S_transition_O_event_progress;
    wire [31:0] S_transition_O_event_target;
    wire [246:0] S_transition_O_event_config;
    wire S_transition_O_event_done_ready;
    wire S_transition_O_recover_ready;
    wire S_transition_O_busy;
    wire S_transition_O_done_valid;
    wire [31:0] S_transition_O_epoch;
    wire [15:0] S_transition_O_tag;
    wire [3:0] S_transition_O_error;
    wire [3:0] S_transition_O_timeline_error;
    wire [3:0] S_transition_O_settle_error;
    wire [3:0] S_transition_O_bind_error;
    wire S_transition_O_settled;
    wire S_transition_O_recovery_required;
    wire S_transition_O_recovery_result;
    wire S_transition_O_cancel_late;
    wire S_transition_O_selected_source;
    wire S_transition_O_video_started;
    wire S_transition_O_video_finished;
    wire S_transition_O_audio_started;
    wire S_transition_O_audio_finished;
    wire [31:0] S_transition_O_actual_start;
    wire [31:0] S_transition_O_actual_midpoint;
    wire [31:0] S_transition_O_actual_audio;
    wire [31:0] S_transition_O_dwell_start;
    wire [31:0] S_transition_O_settle_time;
    wire [31:0] S_transition_O_commit_epoch;
    wire signed [31:0] S_transition_O_anchor_error;
    wire [16:0] S_transition_O_last_progress;
    wire S_transition_O_quarantined;
    wire S_transition_O_response_discarded;
    wire [137:0] S_transition_O_host_reservation;
    wire [5:0] S_transition_O_host_pinned_slots;
    wire S_transition_O_host_busy;
    wire S_transition_O_host_quarantined;
    wire [137:0] S_transition_O_video_reservation;
    wire [31:0] S_transition_O_video_epoch;
    wire [15:0] S_transition_O_video_tag;
    wire S_transition_O_retry_pin_ready;
    wire [3:0] S_transition_O_pin_error;
    wire S_transition_O_transition_started;
    wire S_transition_O_sync_required;
    wire S_transition_O_retry_result;
    wire [3:0] S_transition_O_transition_error;
    wire [137:0] S_transition_O_images;
    wire S_transition_O_pin_quarantined;
    wire S_transition_O_pin_response_discarded;
    wire S_display_O_start_ready;
    wire S_display_O_busy;
    wire S_display_O_done_valid;
    wire [3:0] S_display_O_error;
    wire [3:0] S_display_O_lease_error;
    wire [3:0] S_display_O_slot_error;
    wire [3:0] S_display_O_commit_error;
    wire [3:0] S_display_O_prepare_error;
    wire [3:0] S_display_O_retire_error;
    wire S_display_O_host_quarantined;
    wire S_display_O_host_response_discarded;
    wire S_display_O_video_quarantined;
    wire [15:0] S_display_O_tag;
    wire [31:0] S_display_O_epoch;
    wire [31:0] S_display_O_previous_epoch;
    wire S_display_O_applied;
    wire S_display_O_retired;
    wire S_display_O_cancel_late;
    wire [1:0] S_display_O_acquired_mask;
    wire [1:0] S_display_O_released_mask;
    wire [1:0] S_display_O_host_active_mask;
    wire S_display_O_host_active_valid;
    wire [31:0] S_display_O_host_active_epoch;
    wire [246:0] S_display_O_host_active_config;
    wire [1:0] S_display_O_host_reserve;
    wire [1:0] S_display_O_source_idle;
    wire [1:0] S_display_O_source_busy;
    wire [1:0] S_display_O_owned;
    wire [1:0] S_display_O_lease_valid;
    wire [5:0] S_display_O_lease_slots;
    wire [63:0] S_display_O_lease_tokens;
    wire [63:0] S_display_O_lease_generations;
    wire [1:0] S_display_O_lease_resident;
    wire S_display_O_slot_cmd_valid;
    wire [2:0] S_display_O_slot_cmd_op;
    wire [2:0] S_display_O_slot_cmd_slot;
    wire [1:0] S_display_O_slot_cmd_owner;
    wire [31:0] S_display_O_slot_cmd_token;
    wire [31:0] S_display_O_slot_cmd_generation;
    wire S_display_O_slot_frame_boundary;
    wire S_display_O_slot_reader_retired;
    wire S_display_O_slot_result_ready;
    wire [1:0] S_display_O_source_block;
    wire [1:0] S_display_O_reader_stop;
    wire [1:0] S_display_O_video_retire_ack;
    wire [1:0] S_display_O_source_fault;
    wire [137:0] S_display_O_video_leases;
    wire [31:0] S_display_O_video_lease_version;
    wire [1:0] S_display_O_video_authorized;
    wire [31:0] S_display_O_next_epoch;
    wire S_display_O_pending_valid;
    wire [246:0] S_display_O_pending_config;
    wire [15:0] S_display_O_pending_tag;
    wire [31:0] S_display_O_pending_epoch;
    wire S_display_O_video_active_valid;
    wire [246:0] S_display_O_video_active_config;
    wire [15:0] S_display_O_video_active_tag;
    wire S_display_O_video_response_discarded;
    wire S_display_O_scan_stop_ack;
    wire [1:0] S_display_O_reader_retire_ack;
    wire [1:0] S_display_O_reader_host_retired;
    wire [1:0] S_display_O_source_in_use;
    wire [1:0] S_display_O_source_owner_retired;
    wire [1:0] S_display_O_source_pipeline_retired;
    wire [8:0] S_display_O_prefetch_y;
    wire [31:0] S_display_O_video_active_epoch;
    wire S_display_O_frame_start;
    wire S_display_O_local_applied;
    wire [3:0] S_display_O_bank_busy;
    wire S_display_O_valid;
    wire S_display_O_hsync;
    wire S_display_O_vsync;
    wire S_display_O_de;
    wire [15:0] S_display_O_x;
    wire [15:0] S_display_O_y;
    wire [23:0] S_display_O_rgb;
    wire [31:0] S_display_O_pixel_epoch;
    wire [15:0] S_display_O_pixel_tag;
    wire S_display_O_repeated;
    wire S_display_O_pixel_fault;
    wire S_display_O_video_und;
    wire [31:0] S_display_O_und_count;
    wire [31:0] S_display_O_line_error_count;
    wire [1:0] S_display_O_mem_valid;
    wire [41:0] S_display_O_mem_addr;
    wire [63:0] S_display_O_mem_tag;
    wire [63:0] S_display_O_mem_token;
    wire [63:0] S_display_O_mem_generation;
    wire [63:0] S_display_O_mem_deadline;
    wire [1:0] S_display_O_mem_ready;
    wire [31:0] S_display_O_host_time;
    wire [31:0] S_display_O_video_time;
    wire S_display_O_deadline_quarantined;
    wire [31:0] S_display_O_prepare_target;
    wire S_event_O_event_ready;
    wire S_event_O_busy;
    wire S_event_O_done_valid;
    wire [31:0] S_event_O_epoch;
    wire [15:0] S_event_O_tag;
    wire [15:0] S_event_O_index;
    wire [3:0] S_event_O_error;
    wire [3:0] S_event_O_backend_error;
    wire [3:0] S_event_O_lease_error;
    wire [3:0] S_event_O_slot_error;
    wire [3:0] S_event_O_commit_error;
    wire [3:0] S_event_O_prepare_error;
    wire [3:0] S_event_O_retire_error;
    wire S_event_O_applied;
    wire S_event_O_retired;
    wire [31:0] S_event_O_apply_time;
    wire [31:0] S_event_O_commit_epoch;
    wire S_event_O_quarantined;
    wire S_event_O_response_discarded;
    wire S_event_O_target_valid;
    wire [31:0] S_event_O_target_epoch;
    wire [31:0] S_event_O_target_time;
    wire [15:0] S_event_O_target_tag;
    wire S_event_O_video_abort;
    wire S_event_O_host_start_valid;
    wire [246:0] S_event_O_host_config;
    wire [15:0] S_event_O_host_tag;
    wire S_event_O_host_abort;
    wire S_event_O_host_done_ready;
    wire S_event_O_host_quarantined;
    wire S_event_O_host_response_discarded;
    wire [2:0] S_arbiter_O_client_ready;
    wire [2:0] S_arbiter_O_client_result_valid;
    wire [96:0] S_arbiter_O_client_result;
    wire S_arbiter_O_cmd_valid;
    wire [114:0] S_arbiter_O_cmd;
    wire S_arbiter_O_result_ready;
    wire [5:0] S_arbiter_O_mutating_slots;
    wire S_arbiter_O_busy;
    wire S_arbiter_O_contract_fault;
    wire S_arbiter_O_response_discarded;
    wire S_slots_O_cmd_ready;
    wire S_slots_O_result_valid;
    wire [3:0] S_slots_O_result_error;
    wire [2:0] S_slots_O_result_op;
    wire [2:0] S_slots_O_result_slot;
    wire [1:0] S_slots_O_result_owner;
    wire [31:0] S_slots_O_result_token;
    wire [31:0] S_slots_O_result_generation;
    wire [20:0] S_slots_O_result_base;
    wire [17:0] S_slots_O_slot_states;
    wire [191:0] S_slots_O_slot_tokens;
    wire [191:0] S_slots_O_slot_generations;
    wire [191:0] S_slots_O_slot_assets;
    wire [17:0] S_slots_O_slot_layouts;
    wire [17:0] S_slots_O_slot_readers;
    wire [11:0] S_slots_O_slot_rotations;
    wire [5:0] S_slots_O_slot_resident;
    wire [5:0] S_slots_O_slot_stale;
    wire [5:0] S_slots_O_cancel_loading;
    wire S_slots_O_token_exhausted;
    wire S_stop_O_stop_ack;
    wire S_stop_O_video_busy;
    wire S_stop_O_host_busy;
    wire [1:0] S_stop_O_recycle_valid;
    wire S_loop_O_start_ready;
    wire S_loop_O_need;
    wire S_loop_O_done_valid;
    wire [7:0] S_loop_O_result;
    wire S_loop_O_fade_valid;
    wire S_loop_O_target_b;
    wire S_loop_O_video_busy;
    wire S_loop_O_stop_request;
    wire S_resident_O_slot_valid;
    wire [114:0] S_resident_O_slot_command;
    wire S_resident_O_slot_result_ready;
    wire S_resident_O_mem_valid;
    wire S_resident_O_mem_wr;
    wire [20:0] S_resident_O_mem_addr;
    wire [31:0] S_resident_O_mem_data;
    wire [31:0] S_resident_O_mem_tag;
    wire [31:0] S_resident_O_mem_token;
    wire [31:0] S_resident_O_mem_generation;
    wire [3:0] S_resident_O_mem_mask;
    wire S_resident_O_mem_result_ready;
    wire S_resident_O_busy;
    wire S_resident_O_ready;
    wire [31:0] S_resident_O_token;
    wire [31:0] S_resident_O_generation;
    wire [3:0] S_resident_O_error;
    wire S_resident_O_response_discarded;
    wire [1:0] S_maintenance_O_client_ready;
    wire [1:0] S_maintenance_O_client_result_valid;
    wire [96:0] S_maintenance_O_client_result;
    wire S_maintenance_O_cmd_valid;
    wire [114:0] S_maintenance_O_command;
    wire S_maintenance_O_result_ready;
    wire S_maintenance_O_busy;
    wire [114:0] S_image_command;
    wire [114:0] S_display_command;
    wire [1:0] S_file_allow;
    wire S_host_reset,S_video_reset;
    (* ASYNC_REG="TRUE" *) reg S_media_abort_meta,S_media_abort_video;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin S_media_abort_meta<=1; S_media_abort_video<=1; end
        else begin S_media_abort_meta<=S_io_O_session_client_abort; S_media_abort_video<=S_media_abort_meta; end
    end
    media_io u_io (
        .I_host_clk(I_host_clk),
        .I_sd_clk(I_sd_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .O_sample_tick(S_io_O_sample_tick),
        .O_acr_valid(S_io_O_acr_valid),
        .O_acr_n(S_io_O_acr_n),
        .O_acr_cts(S_io_O_acr_cts),
        .O_acr_overflow(S_io_O_acr_overflow),
        .I_image_start_valid(I_image_start_valid),
        .O_image_start_ready(S_io_O_image_start_ready),
        .I_image_tag(I_image_tag),
        .I_image_generation(I_image_generation),
        .I_image_asset(I_image_asset),
        .I_image_layout(I_image_layout),
        .I_image_compose(I_image_compose),
        .I_image_parts(I_image_parts),
        .O_image_part_needed(S_io_O_image_part_needed),
        .O_image_part_index(S_io_O_image_part_index),
        .I_image_part_valid(I_image_part_valid),
        .O_image_part_ready(S_io_O_image_part_ready),
        .I_image_part_path_length(I_image_part_path_length),
        .I_image_rotation(I_image_rotation),
        .I_image_abort(I_image_abort),
        .O_image_slot_cmd_valid(S_io_O_image_slot_cmd_valid),
        .I_image_slot_cmd_ready(S_arbiter_O_client_ready[0]),
        .O_image_slot_cmd_op(S_io_O_image_slot_cmd_op),
        .O_image_slot_cmd_slot(S_io_O_image_slot_cmd_slot),
        .O_image_slot_cmd_owner(S_io_O_image_slot_cmd_owner),
        .O_image_slot_cmd_token(S_io_O_image_slot_cmd_token),
        .O_image_slot_cmd_generation(S_io_O_image_slot_cmd_generation),
        .O_image_slot_cmd_asset(S_io_O_image_slot_cmd_asset),
        .O_image_slot_cmd_layout(S_io_O_image_slot_cmd_layout),
        .O_image_slot_cmd_rotation(S_io_O_image_slot_cmd_rotation),
        .O_image_slot_cmd_resident(S_io_O_image_slot_cmd_resident),
        .O_image_slot_cmd_success(S_io_O_image_slot_cmd_success),
        .O_image_producer_retired(S_io_O_image_producer_retired),
        .O_image_memory_retired(S_io_O_image_memory_retired),
        .I_image_slot_result_valid(S_arbiter_O_client_result_valid[0]),
        .O_image_slot_result_ready(S_io_O_image_slot_result_ready),
        .I_image_slot_result_error(S_arbiter_O_client_result[96:93]),
        .I_image_slot_result_op(S_arbiter_O_client_result[92:90]),
        .I_image_slot_result_slot(S_arbiter_O_client_result[89:87]),
        .I_image_slot_result_owner(S_arbiter_O_client_result[86:85]),
        .I_image_slot_result_token(S_arbiter_O_client_result[84:53]),
        .I_image_slot_result_generation(S_arbiter_O_client_result[52:21]),
        .O_image_busy(S_io_O_image_busy),
        .O_image_progress(S_io_O_image_progress),
        .O_image_done_valid(S_io_O_image_done_valid),
        .I_image_done_ready(I_image_done_ready),
        .O_image_error(S_io_O_image_error),
        .O_image_context(S_io_O_image_context),
        .O_image_tag(S_io_O_image_tag),
        .O_image_generation(S_io_O_image_generation),
        .O_image_lease_token(S_io_O_image_lease_token),
        .O_image_slot(S_io_O_image_slot),
        .O_image_published(S_io_O_image_published),
        .O_image_slot_owned(S_io_O_image_slot_owned),
        .O_image_file_started(S_io_O_image_file_started),
        .O_image_transform_started(S_io_O_image_transform_started),
        .O_image_writer_started(S_io_O_image_writer_started),
        .O_image_file_source_error(S_io_O_image_file_source_error),
        .O_image_parser_error(S_io_O_image_parser_error),
        .O_image_storage_error(S_io_O_image_storage_error),
        .O_image_transform_error(S_io_O_image_transform_error),
        .O_image_writer_error(S_io_O_image_writer_error),
        .O_image_memory_error(S_io_O_image_memory_error),
        .O_image_file_error(S_io_O_image_file_error),
        .O_image_path_warning(S_io_O_image_path_warning),
        .O_image_file_size(S_io_O_image_file_size),
        .O_image_accepted_writes(S_io_O_image_accepted_writes),
        .O_image_retired_writes(S_io_O_image_retired_writes),
        .O_image_pixels(S_io_O_image_pixels),
        .O_image_response_discarded(S_io_O_image_response_discarded),
        .I_image_sector_budget(I_image_sector_budget),
        .I_image_path_length(I_image_path_length),
        .I_image_path_valid(I_image_path_valid),
        .O_image_path_ready(S_io_O_image_path_ready),
        .I_image_path_data(I_image_path_data),
        .I_image_path_last(I_image_path_last),
        .O_image_mem_valid(S_io_O_image_mem_valid),
        .I_image_mem_ready(I_image_mem_ready),
        .O_image_mem_wr(S_io_O_image_mem_wr),
        .O_image_mem_addr(S_io_O_image_mem_addr),
        .O_image_mem_data(S_io_O_image_mem_data),
        .O_image_mem_tag(S_io_O_image_mem_tag),
        .O_image_mem_mask(S_io_O_image_mem_mask),
        .O_image_mem_lease_token(S_io_O_image_mem_lease_token),
        .O_image_mem_generation(S_io_O_image_mem_generation),
        .I_image_mem_done_valid(I_image_mem_done_valid),
        .O_image_mem_done_ready(S_io_O_image_mem_done_ready),
        .I_image_mem_done_tag(I_image_mem_done_tag),
        .I_image_mem_done_lease_token(I_image_mem_done_lease_token),
        .I_image_mem_done_generation(I_image_mem_done_generation),
        .I_image_mem_done_error(I_image_mem_done_error),
        .I_image_rect_x(I_image_rect_x),
        .I_image_rect_y(I_image_rect_y),
        .I_image_rect_width(I_image_rect_width),
        .I_image_rect_height(I_image_rect_height),
        .I_image_bilinear(I_image_bilinear),
        .I_image_clear_rgba(I_image_clear_rgba),
        .I_image_slot_states(S_slots_O_slot_states),
        .I_image_slot_layouts(S_slots_O_slot_layouts),
        .I_image_slot_readers(S_slots_O_slot_readers),
        .I_image_slot_tokens(S_slots_O_slot_tokens),
        .I_image_slot_generations(S_slots_O_slot_generations),
        .I_image_slot_assets(S_slots_O_slot_assets),
        .I_image_slot_rotations(S_slots_O_slot_rotations),
        .I_image_slot_resident(S_slots_O_slot_resident),
        .I_image_slot_stale(S_slots_O_slot_stale),
        .I_image_pinned_slots(S_transition_O_host_pinned_slots),
        .I_image_mutating_slots(S_arbiter_O_mutating_slots),
        .I_image_host_reservation(S_transition_O_host_reservation),
        .O_image_evict_valid(S_io_O_image_evict_valid),
        .I_image_evict_ready(S_maintenance_O_client_ready[0]),
        .O_image_evict_command(S_io_O_image_evict_command),
        .I_image_evict_result_valid(S_maintenance_O_client_result_valid[0]),
        .O_image_evict_result_ready(S_io_O_image_evict_result_ready),
        .I_image_evict_result(S_maintenance_O_client_result),
        .O_image_loader_error(S_io_O_image_loader_error),
        .O_image_slot_error(S_io_O_image_slot_error),
        .O_image_loader_started(S_io_O_image_loader_started),
        .O_image_reused(S_io_O_image_reused),
        .O_image_evicted(S_io_O_image_evicted),
        .O_image_quarantined(S_io_O_image_quarantined),
        .O_image_stage_valid(S_io_O_image_stage_valid),
        .O_image_staged_slots(S_io_O_image_staged_slots),
        .I_image_stage_release_valid(I_image_stage_release_valid),
        .O_image_stage_release_ready(S_io_O_image_stage_release_ready),
        .I_image_stage_slot(I_image_stage_slot),
        .I_image_stage_token(I_image_stage_token),
        .I_image_stage_generation(I_image_stage_generation),
        .I_image_stage_discard(I_image_stage_discard),
        .O_image_frozen_request(S_io_O_image_frozen_request),
        .O_image_loader_lease_token(S_io_O_image_loader_lease_token),
        .O_scan_start_ready(S_io_O_scan_start_ready),
        .I_scan_abort(I_scan_abort),
        .I_scan_seed(I_scan_seed),
        .I_scan_sector_budget(I_scan_sector_budget),
        .I_scan_directory_sector_budget(I_scan_directory_sector_budget),
        .I_scan_directory_duration(I_scan_directory_duration),
        .I_scan_directory_transition_ms(I_scan_directory_transition_ms),
        .I_scan_directory_transition(I_scan_directory_transition),
        .I_scan_directory_order(I_scan_directory_order),
        .O_scan_busy(S_io_O_scan_busy),
        .O_scan_done_valid(S_io_O_scan_done_valid),
        .O_scan_error(S_io_O_scan_error),
        .O_scan_list_source_error(S_io_O_scan_list_source_error),
        .O_scan_list_build_error(S_io_O_scan_list_build_error),
        .O_scan_directory_build_error(S_io_O_scan_directory_build_error),
        .O_scan_count(S_io_O_scan_count),
        .O_scan_committed(S_io_O_scan_committed),
        .O_scan_used_directory(S_io_O_scan_used_directory),
        .O_scan_list_missing(S_io_O_scan_list_missing),
        .O_scan_list_started(S_io_O_scan_list_started),
        .O_scan_directory_started(S_io_O_scan_directory_started),
        .O_scan_list_warning(S_io_O_scan_list_warning),
        .O_scan_directory_warning(S_io_O_scan_directory_warning),
        .O_scan_context(S_io_O_scan_context),
        .O_scan_tag(S_io_O_scan_tag),
        .O_scan_generation(S_io_O_scan_generation),
        .O_scan_file_error(S_io_O_scan_file_error),
        .O_scan_storage_error(S_io_O_scan_storage_error),
        .O_scan_path_warning(S_io_O_scan_path_warning),
        .O_scan_file_size(S_io_O_scan_file_size),
        .O_scan_active_valid(S_io_O_scan_active_valid),
        .O_scan_active_count(S_io_O_scan_active_count),
        .O_scan_active_generation(S_io_O_scan_active_generation),
        .O_scan_active_revision(S_io_O_scan_active_revision),
        .I_scan_acquire_valid(I_scan_acquire_valid),
        .O_scan_acquire_ready(S_io_O_scan_acquire_ready),
        .O_scan_snapshot_valid(S_io_O_scan_snapshot_valid),
        .O_scan_snapshot_count(S_io_O_scan_snapshot_count),
        .O_scan_snapshot_generation(S_io_O_scan_snapshot_generation),
        .O_scan_snapshot_revision(S_io_O_scan_snapshot_revision),
        .I_scan_release_valid(I_scan_release_valid),
        .O_scan_release_ready(S_io_O_scan_release_ready),
        .I_scan_read_valid(I_scan_read_valid),
        .O_scan_read_ready(S_io_O_scan_read_ready),
        .I_scan_read_index(I_scan_read_index),
        .I_scan_read_kind(I_scan_read_kind),
        .I_scan_read_address(I_scan_read_address),
        .I_scan_read_tag(I_scan_read_tag),
        .O_scan_read_result_valid(S_io_O_scan_read_result_valid),
        .I_scan_read_result_ready(I_scan_read_result_ready),
        .O_scan_read_file_length(S_io_O_scan_read_file_length),
        .O_scan_read_audio_length(S_io_O_scan_read_audio_length),
        .O_scan_read_title_length(S_io_O_scan_read_title_length),
        .O_scan_read_duration(S_io_O_scan_read_duration),
        .O_scan_read_transition_ms(S_io_O_scan_read_transition_ms),
        .O_scan_read_transition(S_io_O_scan_read_transition),
        .O_scan_read_policy(S_io_O_scan_read_policy),
        .O_scan_read_data(S_io_O_scan_read_data),
        .O_scan_read_tag(S_io_O_scan_read_tag),
        .O_scan_read_error(S_io_O_scan_read_error),
        .O_scan_directory_error(S_io_O_scan_directory_error),
        .O_scan_directory_primary_error(S_io_O_scan_directory_primary_error),
        .O_scan_directory_storage_error(S_io_O_scan_directory_storage_error),
        .O_scan_enum_warning(S_io_O_scan_enum_warning),
        .O_scan_directory_sectors(S_io_O_scan_directory_sectors),
        .O_scan_active_order(S_io_O_scan_active_order),
        .O_scan_active_base_order(S_io_O_scan_active_base_order),
        .O_scan_active_base_order_explicit(S_io_O_scan_active_base_order_explicit),
        .I_scan_reorder_valid(I_scan_reorder_valid),
        .O_scan_reorder_ready(S_io_O_scan_reorder_ready),
        .I_scan_reorder_order(I_scan_reorder_order),
        .I_scan_reorder_seed(I_scan_reorder_seed),
        .I_scan_reorder_generation(I_scan_reorder_generation),
        .I_scan_reorder_tag(I_scan_reorder_tag),
        .I_scan_reorder_current_index(I_scan_reorder_current_index),
        .I_scan_reorder_abort(I_scan_reorder_abort),
        .O_scan_reorder_done_valid(S_io_O_scan_reorder_done_valid),
        .I_scan_reorder_done_ready(I_scan_reorder_done_ready),
        .O_scan_reorder_error(S_io_O_scan_reorder_error),
        .O_scan_reorder_tag(S_io_O_scan_reorder_tag),
        .O_scan_reorder_generation(S_io_O_scan_reorder_generation),
        .O_scan_reorder_revision(S_io_O_scan_reorder_revision),
        .O_scan_reorder_current_index(S_io_O_scan_reorder_current_index),
        .I_scan_order_override(I_scan_order_override),
        .I_scan_runtime_order(I_scan_runtime_order),
        .I_audio_file_start_valid(I_audio_file_start_valid & S_file_allow),
        .O_audio_file_start_ready(S_io_O_audio_file_start_ready),
        .I_audio_file_tag(I_audio_file_tag),
        .I_audio_file_generation(I_audio_file_generation),
        .I_audio_file_sector_budget(I_audio_file_sector_budget),
        .I_audio_file_start_index(I_audio_file_start_index),
        .I_audio_file_path_length(I_audio_file_path_length),
        .I_audio_file_path_valid(I_audio_file_path_valid),
        .O_audio_file_path_ready(S_io_O_audio_file_path_ready),
        .I_audio_file_path_data(I_audio_file_path_data),
        .I_audio_file_path_last(I_audio_file_path_last),
        .I_audio_file_abort(I_audio_file_abort),
        .O_audio_file_busy(S_io_O_audio_file_busy),
        .O_audio_file_done_valid(S_io_O_audio_file_done_valid),
        .I_audio_file_done_ready(I_audio_file_done_ready),
        .O_audio_file_error(S_io_O_audio_file_error),
        .O_audio_file_file_error(S_io_O_audio_file_file_error),
        .O_audio_file_storage_error(S_io_O_audio_file_storage_error),
        .O_audio_file_path_warning(S_io_O_audio_file_path_warning),
        .O_audio_file_context(S_io_O_audio_file_context),
        .O_audio_file_tag(S_io_O_audio_file_tag),
        .O_audio_file_generation(S_io_O_audio_file_generation),
        .O_audio_file_file_size(S_io_O_audio_file_file_size),
        .O_audio_byte_discarded(S_io_O_audio_byte_discarded),
        .I_audio_recycle_valid(I_audio_recycle_valid | S_stop_O_recycle_valid),
        .O_audio_recycle_ready(S_io_O_audio_recycle_ready),
        .O_audio_recycle_done(S_io_O_audio_recycle_done),
        .O_audio_available(S_io_O_audio_available),
        .O_audio_source_busy(S_io_O_audio_source_busy),
        .O_audio_written_frames(S_io_O_audio_written_frames),
        .I_audio_play_valid(S_transition_O_play_valid),
        .O_audio_play_ready(S_io_O_audio_play_ready),
        .I_audio_fade_valid(S_transition_O_fade_valid || S_loop_O_fade_valid),
        .I_audio_target_b(S_loop_O_video_busy ? S_loop_O_target_b : S_transition_O_target_b),
        .O_audio_fade_ready(S_io_O_audio_fade_ready),
        .I_audio_silence_valid(S_transition_O_silence_valid),
        .O_audio_silence_ready(S_io_O_audio_silence_ready),
        .O_audio_silence_started(S_io_O_audio_silence_started),
        .O_audio_silence_done(S_io_O_audio_silence_done),
        .I_audio_pause((I_pause || I_alert_hold) && (I_alert_hold || S_transition_O_pause_allow)),
        .I_audio_pause_allow(I_alert_hold || S_transition_O_pause_allow),
        .O_audio_paused(S_io_O_audio_paused),
        .O_audio_pause_busy(S_io_O_audio_pause_busy),
        .I_audio_volume(I_audio_volume),
        .I_audio_mute(I_audio_mute),
        .I_audio_prompt_valid(I_audio_prompt_valid),
        .I_audio_prompt_left(I_audio_prompt_left),
        .I_audio_prompt_right(I_audio_prompt_right),
        .O_audio_sample_valid(S_io_O_audio_sample_valid),
        .O_audio_left(S_io_O_audio_left),
        .O_audio_right(S_io_O_audio_right),
        .O_audio_clipped(S_io_O_audio_clipped),
        .O_audio_fade_done(S_io_O_audio_fade_done),
        .O_audio_active_b(S_io_O_audio_active_b),
        .O_audio_busy(S_io_O_audio_busy),
        .O_audio_started(S_io_O_audio_started),
        .O_audio_loaded(S_io_O_audio_loaded),
        .O_audio_enabled(S_io_O_audio_enabled),
        .O_audio_end(S_io_O_audio_end),
        .O_audio_consumed(S_io_O_audio_consumed),
        .O_audio_underrun(S_io_O_audio_underrun),
        .O_audio_release(S_io_O_audio_release),
        .O_audio_next_index(S_io_O_audio_next_index),
        .O_audio_need_fill(S_io_O_audio_need_fill),
        .O_audio_failed(S_io_O_audio_failed),
        .O_audio_slot_stopping(S_io_O_audio_slot_stopping),
        .O_audio_event_valid(S_io_O_audio_event_valid),
        .I_audio_event_ready(2'b11),
        .O_audio_event_header(S_io_O_audio_event_header),
        .O_audio_event_epoch(S_io_O_audio_event_epoch),
        .O_audio_event_total_frames(S_io_O_audio_event_total_frames),
        .O_audio_event_written_frames(S_io_O_audio_event_written_frames),
        .O_audio_event_error(S_io_O_audio_event_error),
        .I_audio_bind_valid(S_transition_O_audio_bind_valid),
        .O_audio_bind_ready(S_io_O_audio_bind_ready),
        .I_audio_bind_display_epoch(S_transition_O_audio_bind_epoch),
        .I_audio_bind_display_tag(S_transition_O_audio_bind_tag),
        .I_audio_bind_slot(S_transition_O_audio_bind_slot),
        .I_audio_bind_track_epoch(S_transition_O_audio_bind_track_epoch),
        .I_audio_bind_track_serial(S_transition_O_audio_bind_serial),
        .I_audio_bind_start_index(S_transition_O_audio_bind_index),
        .I_audio_bind_reuse_active(S_transition_O_audio_bind_reuse),
        .I_audio_unbind(S_transition_O_audio_unbind || S_stop_O_video_busy),
        .I_audio_bind_abort(I_transition_abort || S_media_abort_video),
        .I_audio_pending_valid(S_transition_O_audio_pending),
        .I_audio_pending_epoch(S_transition_O_epoch),
        .I_audio_pending_tag(S_transition_O_tag),
        .I_audio_display_audio_applied(1'b0),
        .O_audio_audio_ready(S_io_O_audio_audio_ready),
        .O_audio_audio_epoch(S_io_O_audio_audio_epoch),
        .O_audio_track_known(S_io_O_audio_track_known),
        .O_audio_track_epochs(S_io_O_audio_track_epochs),
        .O_audio_track_serials(S_io_O_audio_track_serials),
        .O_audio_track_totals(S_io_O_audio_track_totals),
        .O_audio_bound(S_io_O_audio_bound),
        .O_audio_binding_revoked(S_io_O_audio_binding_revoked),
        .O_audio_bind_error(S_io_O_audio_bind_error),
        .O_audio_audio_accepted(S_io_O_audio_audio_accepted),
        .O_audio_audio_accepted_epoch(S_io_O_audio_audio_accepted_epoch),
        .O_audio_audio_accepted_tag(S_io_O_audio_audio_accepted_tag),
        .O_audio_prepare_contract_fault(S_io_O_audio_prepare_contract_fault),
        .O_audio_prepare_quarantined(S_io_O_audio_prepare_quarantined),
        .O_audio_prepare_response_discarded(S_io_O_audio_prepare_response_discarded),
        .I_storage_demo(I_storage_demo),
        .I_storage_recovery(I_storage_recovery),
        .O_storage_demo_active(S_io_O_storage_demo_active),
        .O_storage_demo_ready(S_io_O_storage_demo_ready),
        .O_storage_recovery_active(S_io_O_storage_recovery_active),
        .O_storage_demo_error(S_io_O_storage_demo_error),
        .O_storage_flash_valid(S_io_O_storage_flash_valid),
        .I_storage_flash_ready(I_storage_flash_ready),
        .O_storage_flash_address(S_io_O_storage_flash_address),
        .O_storage_flash_length(S_io_O_storage_flash_length),
        .O_storage_flash_tag(S_io_O_storage_flash_tag),
        .I_storage_flash_read_valid(I_storage_flash_read_valid),
        .O_storage_flash_read_ready(S_io_O_storage_flash_read_ready),
        .I_storage_flash_read_data(I_storage_flash_read_data),
        .I_storage_flash_read_last(I_storage_flash_read_last),
        .I_storage_flash_done_valid(I_storage_flash_done_valid),
        .O_storage_flash_done_ready(S_io_O_storage_flash_done_ready),
        .I_storage_flash_error(I_storage_flash_error),
        .I_storage_flash_tag(I_storage_flash_tag),
        .O_storage_lease_grant(S_io_O_storage_lease_grant),
        .O_storage_busy(S_io_O_storage_busy),
        .O_storage_quiescent(S_io_O_storage_quiescent),
        .O_storage_leased_contexts(S_io_O_storage_leased_contexts),
        .O_storage_descriptors(S_io_O_storage_descriptors),
        .O_storage_pending_reads(S_io_O_storage_pending_reads),
        .O_storage_contract_fault(S_io_O_storage_contract_fault),
        .O_storage_response_discarded(S_io_O_storage_response_discarded),
        .O_storage_mount_ready(S_io_O_storage_mount_ready),
        .O_storage_mount_result_valid(S_io_O_storage_mount_result_valid),
        .O_storage_mount_error(S_io_O_storage_mount_error),
        .O_storage_mount_storage_error(S_io_O_storage_mount_storage_error),
        .O_storage_mount_generation(S_io_O_storage_mount_generation),
        .O_storage_mounted(S_io_O_storage_mounted),
        .O_storage_generation(S_io_O_storage_generation),
        .O_storage_card_ready(S_io_O_storage_card_ready),
        .O_storage_card_present(S_io_O_storage_card_present),
        .O_storage_capacity_sectors(S_io_O_storage_capacity_sectors),
        .O_storage_sd_high_capacity(S_io_O_storage_sd_high_capacity),
        .O_storage_sd_card_error(S_io_O_storage_sd_card_error),
        .O_storage_sd_ncs(S_io_O_storage_sd_ncs),
        .O_storage_sd_sclk(S_io_O_storage_sd_sclk),
        .O_storage_sd_mosi(S_io_O_storage_sd_mosi),
        .I_storage_sd_miso(I_storage_sd_miso),
        .I_session_enable(I_session_enable),
        .I_session_reload(I_session_reload),
        .I_session_rescan(I_session_rescan),
        .O_session_client_abort(S_io_O_session_client_abort),
        .O_session_allow_start(S_io_O_session_allow_start),
        .O_session_ready(S_io_O_session_ready),
        .O_session_busy(S_io_O_session_busy),
        .O_session_scan_done(S_io_O_session_scan_done),
        .O_session_count(S_io_O_session_count),
        .O_session_error(S_io_O_session_error),
        .O_session_scan_error(S_io_O_session_scan_error),
        .O_session_mount_error(S_io_O_session_mount_error),
        .O_session_mount_storage_error(S_io_O_session_mount_storage_error),
        .O_session_generation(S_io_O_session_generation)
    );
    playback_image_pipeline #(.STOP_PENDING_AUDIO(1)) u_transition (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_clock_enable(I_clock_enable),
        .I_time(S_display_O_video_time),
        .I_frame_start(S_display_O_frame_start),
        .I_sample_tick(S_io_O_sample_tick),
        .I_start_valid(I_transition_start_valid && !S_stop_O_video_busy && !S_loop_O_video_busy && (!S_media_abort_video || I_transition_config[109:108]==3)),
        .O_start_ready(S_transition_O_start_ready),
        .I_epoch(I_transition_epoch),
        .I_tag(I_transition_tag),
        .I_config(I_transition_config),
        .I_effect(I_transition_effect),
        .I_duration_frames(I_transition_duration_frames),
        .I_av_offset_steps(I_transition_av_offset_steps),
        .I_audio_action(I_transition_audio_action),
        .I_audio_slot(I_transition_audio_slot),
        .I_track_epoch(I_transition_track_epoch),
        .I_track_serial(I_transition_track_serial),
        .I_start_index(I_transition_start_index),
        .I_display_leases(S_display_O_video_leases),
        .I_pause(I_pause),
        .I_abort(I_transition_abort || (S_media_abort_video && I_transition_config[109:108]!=3)),
        .O_pause_allow(S_transition_O_pause_allow),
        .O_image_hold(S_transition_O_image_hold),
        .O_audio_hold(S_transition_O_audio_hold),
        .O_frozen_config(S_transition_O_frozen_config),
        .O_audio_bind_valid(S_transition_O_audio_bind_valid),
        .I_audio_bind_ready(S_io_O_audio_bind_ready),
        .O_audio_bind_epoch(S_transition_O_audio_bind_epoch),
        .O_audio_bind_tag(S_transition_O_audio_bind_tag),
        .O_audio_bind_slot(S_transition_O_audio_bind_slot),
        .O_audio_bind_track_epoch(S_transition_O_audio_bind_track_epoch),
        .O_audio_bind_serial(S_transition_O_audio_bind_serial),
        .O_audio_bind_index(S_transition_O_audio_bind_index),
        .O_audio_bind_reuse(S_transition_O_audio_bind_reuse),
        .O_audio_pending(S_transition_O_audio_pending),
        .O_audio_unbind(S_transition_O_audio_unbind),
        .I_audio_bound(S_io_O_audio_bound),
        .I_audio_bind_error(S_io_O_audio_bind_error),
        .I_audio_ready(S_io_O_audio_audio_ready),
        .I_audio_epoch(S_io_O_audio_audio_epoch),
        .I_track_known(S_io_O_audio_track_known),
        .I_track_enabled(S_io_O_audio_enabled),
        .I_track_consumed(S_io_O_audio_consumed),
        .I_track_epochs(S_io_O_audio_track_epochs),
        .I_track_serials(S_io_O_audio_track_serials),
        .I_track_totals(S_io_O_audio_track_totals),
        .I_track_next_index(S_io_O_audio_next_index),
        .O_play_valid(S_transition_O_play_valid),
        .O_fade_valid(S_transition_O_fade_valid),
        .O_target_b(S_transition_O_target_b),
        .I_play_ready(S_io_O_audio_play_ready),
        .I_fade_ready(S_io_O_audio_fade_ready),
        .I_fade_done(S_io_O_audio_fade_done),
        .I_active_b(S_io_O_audio_active_b),
        .O_silence_valid(S_transition_O_silence_valid),
        .I_silence_ready(S_io_O_audio_silence_ready),
        .I_silence_started(S_io_O_audio_silence_started),
        .I_silence_done(S_io_O_audio_silence_done),
        .O_audio_stop_request(S_transition_O_audio_stop_request),
        .I_audio_stop_ack(S_stop_O_stop_ack),
        .O_event_valid(S_transition_O_event_valid),
        .I_event_ready(S_event_O_event_ready),
        .O_event_cancel(S_transition_O_event_cancel),
        .O_event_epoch(S_transition_O_event_epoch),
        .O_event_tag(S_transition_O_event_tag),
        .O_event_index(S_transition_O_event_index),
        .O_event_effect(S_transition_O_event_effect),
        .O_event_progress(S_transition_O_event_progress),
        .O_event_target(S_transition_O_event_target),
        .O_event_config(S_transition_O_event_config),
        .I_event_busy(S_event_O_busy),
        .I_event_done_valid(S_event_O_done_valid),
        .O_event_done_ready(S_transition_O_event_done_ready),
        .I_event_done_epoch(S_event_O_epoch),
        .I_event_done_tag(S_event_O_tag),
        .I_event_done_index(S_event_O_index),
        .I_event_done_error(S_event_O_error),
        .I_event_done_applied(S_event_O_applied),
        .I_event_done_retired(S_event_O_retired),
        .I_event_done_time(S_event_O_apply_time),
        .I_event_commit_epoch(S_event_O_commit_epoch),
        .I_event_quarantined(S_event_O_quarantined),
        .I_active_valid(S_display_O_video_active_valid),
        .I_active_config(S_display_O_video_active_config),
        .I_active_epoch(S_display_O_video_active_epoch),
        .I_active_tag(S_display_O_video_active_tag),
        .I_recover_valid(I_transition_recover_valid),
        .I_recover_source(I_transition_recover_source),
        .O_recover_ready(S_transition_O_recover_ready),
        .O_busy(S_transition_O_busy),
        .O_done_valid(S_transition_O_done_valid),
        .I_done_ready(I_transition_done_ready),
        .O_epoch(S_transition_O_epoch),
        .O_tag(S_transition_O_tag),
        .O_error(S_transition_O_error),
        .O_timeline_error(S_transition_O_timeline_error),
        .O_settle_error(S_transition_O_settle_error),
        .O_bind_error(S_transition_O_bind_error),
        .O_settled(S_transition_O_settled),
        .O_recovery_required(S_transition_O_recovery_required),
        .O_recovery_result(S_transition_O_recovery_result),
        .O_cancel_late(S_transition_O_cancel_late),
        .O_selected_source(S_transition_O_selected_source),
        .O_video_started(S_transition_O_video_started),
        .O_video_finished(S_transition_O_video_finished),
        .O_audio_started(S_transition_O_audio_started),
        .O_audio_finished(S_transition_O_audio_finished),
        .O_actual_start(S_transition_O_actual_start),
        .O_actual_midpoint(S_transition_O_actual_midpoint),
        .O_actual_audio(S_transition_O_actual_audio),
        .O_dwell_start(S_transition_O_dwell_start),
        .O_settle_time(S_transition_O_settle_time),
        .O_commit_epoch(S_transition_O_commit_epoch),
        .O_anchor_error(S_transition_O_anchor_error),
        .O_last_progress(S_transition_O_last_progress),
        .O_quarantined(S_transition_O_quarantined),
        .O_response_discarded(S_transition_O_response_discarded),
        .I_media_valid(S_io_O_storage_mounted),
        .I_media_generation(S_io_O_storage_generation),
        .I_slot_states(S_slots_O_slot_states),
        .I_slot_tokens(S_slots_O_slot_tokens),
        .I_slot_generations(S_slots_O_slot_generations),
        .I_slot_resident(S_slots_O_slot_resident),
        .I_slot_stale(S_slots_O_slot_stale),
        .I_mutating_slots(S_arbiter_O_mutating_slots),
        .O_host_reservation(S_transition_O_host_reservation),
        .O_host_pinned_slots(S_transition_O_host_pinned_slots),
        .O_host_busy(S_transition_O_host_busy),
        .O_host_quarantined(S_transition_O_host_quarantined),
        .O_video_reservation(S_transition_O_video_reservation),
        .O_video_epoch(S_transition_O_video_epoch),
        .O_video_tag(S_transition_O_video_tag),
        .I_retry_pin_valid(I_transition_retry_pin_valid),
        .O_retry_pin_ready(S_transition_O_retry_pin_ready),
        .O_pin_error(S_transition_O_pin_error),
        .O_transition_started(S_transition_O_transition_started),
        .O_sync_required(S_transition_O_sync_required),
        .O_retry_result(S_transition_O_retry_result),
        .O_transition_error(S_transition_O_transition_error),
        .O_images(S_transition_O_images),
        .O_pin_quarantined(S_transition_O_pin_quarantined),
        .O_pin_response_discarded(S_transition_O_pin_response_discarded)
    );
    display_timed_pipeline #(.USE_TARGET(1),.PREPARE_IN_VBLANK(1)) u_display (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_target_valid(S_event_O_target_valid),
        .I_target_epoch(S_event_O_target_epoch),
        .I_target_time(S_event_O_target_time),
        .I_target_tag(S_event_O_target_tag),
        .I_start_valid(S_event_O_host_start_valid),
        .O_start_ready(S_display_O_start_ready),
        .I_config(S_event_O_host_config),
        .I_tag(S_event_O_host_tag),
        .I_abort(S_event_O_host_abort),
        .O_busy(S_display_O_busy),
        .O_done_valid(S_display_O_done_valid),
        .I_done_ready(S_event_O_host_done_ready),
        .O_error(S_display_O_error),
        .O_lease_error(S_display_O_lease_error),
        .O_slot_error(S_display_O_slot_error),
        .O_commit_error(S_display_O_commit_error),
        .O_prepare_error(S_display_O_prepare_error),
        .O_retire_error(S_display_O_retire_error),
        .I_video_allow_apply(I_display_video_allow_apply),
        .I_video_abort(S_event_O_video_abort),
        .I_audio_ready(1'b0),
        .I_audio_epoch(32'd0),
        .O_host_quarantined(S_display_O_host_quarantined),
        .O_host_response_discarded(S_display_O_host_response_discarded),
        .O_video_quarantined(S_display_O_video_quarantined),
        .O_tag(S_display_O_tag),
        .O_epoch(S_display_O_epoch),
        .O_previous_epoch(S_display_O_previous_epoch),
        .O_applied(S_display_O_applied),
        .O_retired(S_display_O_retired),
        .O_cancel_late(S_display_O_cancel_late),
        .O_acquired_mask(S_display_O_acquired_mask),
        .O_released_mask(S_display_O_released_mask),
        .O_host_active_mask(S_display_O_host_active_mask),
        .O_host_active_valid(S_display_O_host_active_valid),
        .O_host_active_epoch(S_display_O_host_active_epoch),
        .O_host_active_config(S_display_O_host_active_config),
        .O_host_reserve(S_display_O_host_reserve),
        .O_source_idle(S_display_O_source_idle),
        .O_source_busy(S_display_O_source_busy),
        .O_owned(S_display_O_owned),
        .O_lease_valid(S_display_O_lease_valid),
        .O_lease_slots(S_display_O_lease_slots),
        .O_lease_tokens(S_display_O_lease_tokens),
        .O_lease_generations(S_display_O_lease_generations),
        .O_lease_resident(S_display_O_lease_resident),
        .I_slot_states(S_slots_O_slot_states),
        .I_slot_readers(S_slots_O_slot_readers),
        .I_slot_tokens(S_slots_O_slot_tokens),
        .I_slot_generations(S_slots_O_slot_generations),
        .I_slot_resident(S_slots_O_slot_resident),
        .O_slot_cmd_valid(S_display_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_arbiter_O_client_ready[1]),
        .O_slot_cmd_op(S_display_O_slot_cmd_op),
        .O_slot_cmd_slot(S_display_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_display_O_slot_cmd_owner),
        .O_slot_cmd_token(S_display_O_slot_cmd_token),
        .O_slot_cmd_generation(S_display_O_slot_cmd_generation),
        .O_slot_frame_boundary(S_display_O_slot_frame_boundary),
        .O_slot_reader_retired(S_display_O_slot_reader_retired),
        .I_slot_result_valid(S_arbiter_O_client_result_valid[1]),
        .O_slot_result_ready(S_display_O_slot_result_ready),
        .I_slot_result_error(S_arbiter_O_client_result[96:93]),
        .I_slot_result_op(S_arbiter_O_client_result[92:90]),
        .I_slot_result_slot(S_arbiter_O_client_result[89:87]),
        .I_slot_result_owner(S_arbiter_O_client_result[86:85]),
        .I_slot_result_token(S_arbiter_O_client_result[84:53]),
        .I_slot_result_generation(S_arbiter_O_client_result[52:21]),
        .I_slot_result_base(S_arbiter_O_client_result[20:0]),
        .O_source_block(S_display_O_source_block),
        .O_reader_stop(S_display_O_reader_stop),
        .O_video_retire_ack(S_display_O_video_retire_ack),
        .O_source_fault(S_display_O_source_fault),
        .O_video_leases(S_display_O_video_leases),
        .O_video_lease_version(S_display_O_video_lease_version),
        .O_video_authorized(S_display_O_video_authorized),
        .O_next_epoch(S_display_O_next_epoch),
        .O_pending_valid(S_display_O_pending_valid),
        .O_pending_config(S_display_O_pending_config),
        .O_pending_tag(S_display_O_pending_tag),
        .O_pending_epoch(S_display_O_pending_epoch),
        .O_video_active_valid(S_display_O_video_active_valid),
        .O_video_active_config(S_display_O_video_active_config),
        .O_video_active_tag(S_display_O_video_active_tag),
        .O_video_response_discarded(S_display_O_video_response_discarded),
        .I_scan_stop(I_display_scan_stop),
        .O_scan_stop_ack(S_display_O_scan_stop_ack),
        .O_reader_retire_ack(S_display_O_reader_retire_ack),
        .O_reader_host_retired(S_display_O_reader_host_retired),
        .O_source_in_use(S_display_O_source_in_use),
        .O_source_owner_retired(S_display_O_source_owner_retired),
        .O_source_pipeline_retired(S_display_O_source_pipeline_retired),
        .O_prefetch_y(S_display_O_prefetch_y),
        .O_video_active_epoch(S_display_O_video_active_epoch),
        .O_frame_start(S_display_O_frame_start),
        .O_local_applied(S_display_O_local_applied),
        .O_bank_busy(S_display_O_bank_busy),
        .O_valid(S_display_O_valid),
        .O_hsync(S_display_O_hsync),
        .O_vsync(S_display_O_vsync),
        .O_de(S_display_O_de),
        .O_x(S_display_O_x),
        .O_y(S_display_O_y),
        .O_rgb(S_display_O_rgb),
        .O_pixel_epoch(S_display_O_pixel_epoch),
        .O_pixel_tag(S_display_O_pixel_tag),
        .O_repeated(S_display_O_repeated),
        .O_pixel_fault(S_display_O_pixel_fault),
        .O_video_und(S_display_O_video_und),
        .O_und_count(S_display_O_und_count),
        .O_line_error_count(S_display_O_line_error_count),
        .O_mem_valid(S_display_O_mem_valid),
        .I_mem_ready(I_display_mem_ready),
        .O_mem_addr(S_display_O_mem_addr),
        .O_mem_tag(S_display_O_mem_tag),
        .O_mem_token(S_display_O_mem_token),
        .O_mem_generation(S_display_O_mem_generation),
        .O_mem_deadline(S_display_O_mem_deadline),
        .I_mem_valid(I_display_mem_valid),
        .O_mem_ready(S_display_O_mem_ready),
        .I_mem_data(I_display_mem_data),
        .I_mem_tag(I_display_mem_tag),
        .I_mem_token(I_display_mem_token),
        .I_mem_generation(I_display_mem_generation),
        .I_mem_error(I_display_mem_error),
        .I_clock_enable(I_clock_enable),
        .O_host_time(S_display_O_host_time),
        .O_video_time(S_display_O_video_time),
        .O_deadline_quarantined(S_display_O_deadline_quarantined),
        .O_prepare_target(S_display_O_prepare_target)
    );
    display_event_executor u_event (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_clock_enable(I_clock_enable),
        .I_video_time(S_display_O_video_time),
        .I_frame_start(S_display_O_frame_start),
        .I_active_valid(S_display_O_video_active_valid),
        .I_event_valid(S_transition_O_event_valid),
        .O_event_ready(S_event_O_event_ready),
        .I_event_epoch(S_transition_O_event_epoch),
        .I_event_tag(S_transition_O_event_tag),
        .I_event_index(S_transition_O_event_index),
        .I_event_effect(S_transition_O_event_effect),
        .I_event_progress(S_transition_O_event_progress),
        .I_event_target(S_transition_O_event_target),
        .I_config(S_transition_O_event_config),
        .I_cancel(S_transition_O_event_cancel),
        .I_bank_busy(S_display_O_bank_busy),
        .O_busy(S_event_O_busy),
        .O_done_valid(S_event_O_done_valid),
        .I_done_ready(S_transition_O_event_done_ready),
        .O_epoch(S_event_O_epoch),
        .O_tag(S_event_O_tag),
        .O_index(S_event_O_index),
        .O_error(S_event_O_error),
        .O_backend_error(S_event_O_backend_error),
        .O_lease_error(S_event_O_lease_error),
        .O_slot_error(S_event_O_slot_error),
        .O_commit_error(S_event_O_commit_error),
        .O_prepare_error(S_event_O_prepare_error),
        .O_retire_error(S_event_O_retire_error),
        .O_applied(S_event_O_applied),
        .O_retired(S_event_O_retired),
        .O_apply_time(S_event_O_apply_time),
        .O_commit_epoch(S_event_O_commit_epoch),
        .O_quarantined(S_event_O_quarantined),
        .O_response_discarded(S_event_O_response_discarded),
        .O_target_valid(S_event_O_target_valid),
        .O_target_epoch(S_event_O_target_epoch),
        .O_target_time(S_event_O_target_time),
        .O_target_tag(S_event_O_target_tag),
        .O_video_abort(S_event_O_video_abort),
        .I_pending_valid(S_display_O_pending_valid),
        .I_pending_config(S_display_O_pending_config),
        .I_pending_epoch(S_display_O_pending_epoch),
        .I_pending_tag(S_display_O_pending_tag),
        .I_local_applied(S_display_O_local_applied),
        .I_active_config(S_display_O_video_active_config),
        .I_active_epoch(S_display_O_video_active_epoch),
        .I_active_tag(S_display_O_video_active_tag),
        .O_host_start_valid(S_event_O_host_start_valid),
        .I_host_start_ready(S_display_O_start_ready),
        .O_host_config(S_event_O_host_config),
        .O_host_tag(S_event_O_host_tag),
        .O_host_abort(S_event_O_host_abort),
        .I_host_next_epoch(S_display_O_next_epoch),
        .I_host_done_valid(S_display_O_done_valid),
        .O_host_done_ready(S_event_O_host_done_ready),
        .I_host_epoch(S_display_O_epoch),
        .I_host_tag(S_display_O_tag),
        .I_host_error(S_display_O_error),
        .I_host_lease_error(S_display_O_lease_error),
        .I_host_slot_error(S_display_O_slot_error),
        .I_host_commit_error(S_display_O_commit_error),
        .I_host_prepare_error(S_display_O_prepare_error),
        .I_host_retire_error(S_display_O_retire_error),
        .I_host_applied(S_display_O_applied),
        .I_host_retired(S_display_O_retired),
        .I_host_quarantined(S_display_O_host_quarantined),
        .O_host_quarantined(S_event_O_host_quarantined),
        .O_host_response_discarded(S_event_O_host_response_discarded)
    );
    fb_slot_arbiter u_arbiter (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_pinned_slots(S_transition_O_host_pinned_slots | S_io_O_image_staged_slots),
        .I_client_valid({S_maintenance_O_cmd_valid,S_display_O_slot_cmd_valid,S_io_O_image_slot_cmd_valid}),
        .O_client_ready(S_arbiter_O_client_ready),
        .I_client_command({S_maintenance_O_command,S_display_command,S_image_command}),
        .O_client_result_valid(S_arbiter_O_client_result_valid),
        .I_client_result_ready({S_maintenance_O_result_ready,S_display_O_slot_result_ready,S_io_O_image_slot_result_ready}),
        .O_client_result(S_arbiter_O_client_result),
        .O_cmd_valid(S_arbiter_O_cmd_valid),
        .I_cmd_ready(S_slots_O_cmd_ready),
        .O_cmd(S_arbiter_O_cmd),
        .I_result_valid(S_slots_O_result_valid),
        .O_result_ready(S_arbiter_O_result_ready),
        .I_result({S_slots_O_result_error,S_slots_O_result_op,S_slots_O_result_slot,S_slots_O_result_owner,S_slots_O_result_token,S_slots_O_result_generation,S_slots_O_result_base}),
        .O_mutating_slots(S_arbiter_O_mutating_slots),
        .O_busy(S_arbiter_O_busy),
        .O_contract_fault(S_arbiter_O_contract_fault),
        .O_response_discarded(S_arbiter_O_response_discarded)
    );
    fb_slot_manager u_slots (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_io_O_storage_mounted),
        .I_media_generation(S_io_O_storage_generation),
        .I_cmd_valid(S_arbiter_O_cmd_valid),
        .O_cmd_ready(S_slots_O_cmd_ready),
        .I_cmd_op(S_arbiter_O_cmd[114:112]),
        .I_cmd_slot(S_arbiter_O_cmd[111:109]),
        .I_cmd_owner(S_arbiter_O_cmd[108:107]),
        .I_cmd_token(S_arbiter_O_cmd[106:75]),
        .I_cmd_generation(S_arbiter_O_cmd[74:43]),
        .I_cmd_asset(S_arbiter_O_cmd[42:11]),
        .I_cmd_layout(S_arbiter_O_cmd[10:8]),
        .I_cmd_rotation(S_arbiter_O_cmd[7:6]),
        .I_cmd_resident(S_arbiter_O_cmd[5]),
        .I_cmd_success(S_arbiter_O_cmd[4]),
        .I_producer_retired(S_arbiter_O_cmd[3]),
        .I_memory_retired(S_arbiter_O_cmd[2]),
        .I_reader_retired(S_arbiter_O_cmd[1]),
        .I_frame_boundary(S_arbiter_O_cmd[0]),
        .O_result_valid(S_slots_O_result_valid),
        .I_result_ready(S_arbiter_O_result_ready),
        .O_result_error(S_slots_O_result_error),
        .O_result_op(S_slots_O_result_op),
        .O_result_slot(S_slots_O_result_slot),
        .O_result_owner(S_slots_O_result_owner),
        .O_result_token(S_slots_O_result_token),
        .O_result_generation(S_slots_O_result_generation),
        .O_result_base(S_slots_O_result_base),
        .O_slot_states(S_slots_O_slot_states),
        .O_slot_tokens(S_slots_O_slot_tokens),
        .O_slot_generations(S_slots_O_slot_generations),
        .O_slot_assets(S_slots_O_slot_assets),
        .O_slot_layouts(S_slots_O_slot_layouts),
        .O_slot_readers(S_slots_O_slot_readers),
        .O_slot_rotations(S_slots_O_slot_rotations),
        .O_slot_resident(S_slots_O_slot_resident),
        .O_slot_stale(S_slots_O_slot_stale),
        .O_cancel_loading(S_slots_O_cancel_loading),
        .O_token_exhausted(S_slots_O_token_exhausted)
    );
    audio_stop_cdc u_stop (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_stop_request(S_transition_O_audio_stop_request || S_loop_O_stop_request),
        .O_stop_ack(S_stop_O_stop_ack),
        .O_video_busy(S_stop_O_video_busy),
        .O_host_busy(S_stop_O_host_busy),
        .O_recycle_valid(S_stop_O_recycle_valid),
        .I_recycle_ready(S_io_O_audio_recycle_ready),
        .I_recycle_done(S_io_O_audio_recycle_done),
        .I_available(S_io_O_audio_available)
    );
    bgm_loop_cdc u_loop (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_start_valid(I_bgm_start_valid),
        .O_start_ready(S_loop_O_start_ready),
        .O_need(S_loop_O_need),
        .I_slot(I_bgm_slot),
        .I_track_epoch(I_bgm_track_epoch),
        .I_abort(I_bgm_abort),
        .O_done_valid(S_loop_O_done_valid),
        .I_done_ready(I_bgm_done_ready),
        .O_result(S_loop_O_result),
        .I_clock_enable(I_clock_enable),
        .I_pause(I_pause),
        .I_media_abort(S_media_abort_video),
        .I_transition_busy(S_transition_O_busy),
        .I_track_known(S_io_O_audio_track_known),
        .I_track_enabled(S_io_O_audio_enabled),
        .I_track_failed(S_io_O_audio_failed),
        .I_track_epochs(S_io_O_audio_track_epochs),
        .I_track_serials(S_io_O_audio_track_serials),
        .I_track_totals(S_io_O_audio_track_totals),
        .I_track_next_index(S_io_O_audio_next_index),
        .I_active_b(S_io_O_audio_active_b),
        .I_fade_ready(S_io_O_audio_fade_ready),
        .I_fade_done(S_io_O_audio_fade_done),
        .O_fade_valid(S_loop_O_fade_valid),
        .O_target_b(S_loop_O_target_b),
        .O_video_busy(S_loop_O_video_busy),
        .O_stop_request(S_loop_O_stop_request),
        .I_stop_ack(S_stop_O_stop_ack)
    );
    resident_frame_init u_resident (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_enable(I_resident_enable),
        .O_slot_valid(S_resident_O_slot_valid),
        .I_slot_ready(S_maintenance_O_client_ready[1]),
        .O_slot_command(S_resident_O_slot_command),
        .I_slot_result_valid(S_maintenance_O_client_result_valid[1]),
        .O_slot_result_ready(S_resident_O_slot_result_ready),
        .I_slot_result(S_maintenance_O_client_result),
        .O_mem_valid(S_resident_O_mem_valid),
        .I_mem_ready(I_resident_mem_ready),
        .O_mem_wr(S_resident_O_mem_wr),
        .O_mem_addr(S_resident_O_mem_addr),
        .O_mem_data(S_resident_O_mem_data),
        .O_mem_tag(S_resident_O_mem_tag),
        .O_mem_token(S_resident_O_mem_token),
        .O_mem_generation(S_resident_O_mem_generation),
        .O_mem_mask(S_resident_O_mem_mask),
        .I_mem_result_valid(I_resident_mem_result_valid),
        .O_mem_result_ready(S_resident_O_mem_result_ready),
        .I_mem_result_wr(I_resident_mem_result_wr),
        .I_mem_result_tag(I_resident_mem_result_tag),
        .I_mem_result_token(I_resident_mem_result_token),
        .I_mem_result_generation(I_resident_mem_result_generation),
        .I_mem_result_error(I_resident_mem_result_error),
        .O_busy(S_resident_O_busy),
        .O_ready(S_resident_O_ready),
        .O_token(S_resident_O_token),
        .O_generation(S_resident_O_generation),
        .O_error(S_resident_O_error),
        .O_response_discarded(S_resident_O_response_discarded)
    );
    slot_cmd_mux2 u_maintenance (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_client_valid({S_resident_O_slot_valid,S_io_O_image_evict_valid}),
        .O_client_ready(S_maintenance_O_client_ready),
        .I_client_command({S_resident_O_slot_command,S_io_O_image_evict_command}),
        .O_client_result_valid(S_maintenance_O_client_result_valid),
        .I_client_result_ready({S_resident_O_slot_result_ready,S_io_O_image_evict_result_ready}),
        .O_client_result(S_maintenance_O_client_result),
        .O_cmd_valid(S_maintenance_O_cmd_valid),
        .I_cmd_ready(S_arbiter_O_client_ready[2]),
        .O_command(S_maintenance_O_command),
        .I_result_valid(S_arbiter_O_client_result_valid[2]),
        .O_result_ready(S_maintenance_O_result_ready),
        .I_result(S_arbiter_O_client_result),
        .O_busy(S_maintenance_O_busy)
    );
    assign O_cmd_ready=S_slots_O_cmd_ready;
    assign O_result_valid=S_slots_O_result_valid;
    assign O_result_error=S_slots_O_result_error;
    assign O_result_op=S_slots_O_result_op;
    assign O_result_slot=S_slots_O_result_slot;
    assign O_result_owner=S_slots_O_result_owner;
    assign O_result_token=S_slots_O_result_token;
    assign O_result_generation=S_slots_O_result_generation;
    assign O_result_base=S_slots_O_result_base;
    assign O_slot_states=S_slots_O_slot_states;
    assign O_slot_tokens=S_slots_O_slot_tokens;
    assign O_slot_generations=S_slots_O_slot_generations;
    assign O_slot_assets=S_slots_O_slot_assets;
    assign O_slot_layouts=S_slots_O_slot_layouts;
    assign O_slot_readers=S_slots_O_slot_readers;
    assign O_slot_rotations=S_slots_O_slot_rotations;
    assign O_slot_resident=S_slots_O_slot_resident;
    assign O_slot_stale=S_slots_O_slot_stale;
    assign O_cancel_loading=S_slots_O_cancel_loading;
    assign O_token_exhausted=S_slots_O_token_exhausted;
    assign O_display_start_ready=S_display_O_start_ready;
    assign O_display_busy=S_display_O_busy;
    assign O_display_done_valid=S_display_O_done_valid;
    assign O_display_error=S_display_O_error;
    assign O_display_lease_error=S_display_O_lease_error;
    assign O_display_commit_error=S_display_O_commit_error;
    assign O_display_prepare_error=S_display_O_prepare_error;
    assign O_display_retire_error=S_display_O_retire_error;
    assign O_display_host_quarantined=S_display_O_host_quarantined;
    assign O_display_host_response_discarded=S_display_O_host_response_discarded;
    assign O_display_video_quarantined=S_display_O_video_quarantined;
    assign O_display_tag=S_display_O_tag;
    assign O_display_epoch=S_display_O_epoch;
    assign O_display_previous_epoch=S_display_O_previous_epoch;
    assign O_display_applied=S_display_O_applied;
    assign O_display_retired=S_display_O_retired;
    assign O_display_cancel_late=S_display_O_cancel_late;
    assign O_display_acquired_mask=S_display_O_acquired_mask;
    assign O_display_released_mask=S_display_O_released_mask;
    assign O_display_host_active_mask=S_display_O_host_active_mask;
    assign O_display_host_active_valid=S_display_O_host_active_valid;
    assign O_display_host_active_epoch=S_display_O_host_active_epoch;
    assign O_display_host_active_config=S_display_O_host_active_config;
    assign O_display_host_reserve=S_display_O_host_reserve;
    assign O_display_source_idle=S_display_O_source_idle;
    assign O_display_source_busy=S_display_O_source_busy;
    assign O_display_owned=S_display_O_owned;
    assign O_display_lease_valid=S_display_O_lease_valid;
    assign O_display_lease_slots=S_display_O_lease_slots;
    assign O_display_lease_tokens=S_display_O_lease_tokens;
    assign O_display_lease_generations=S_display_O_lease_generations;
    assign O_display_lease_resident=S_display_O_lease_resident;
    assign O_display_source_block=S_display_O_source_block;
    assign O_display_reader_stop=S_display_O_reader_stop;
    assign O_display_video_retire_ack=S_display_O_video_retire_ack;
    assign O_display_source_fault=S_display_O_source_fault;
    assign O_display_video_leases=S_display_O_video_leases;
    assign O_display_video_lease_version=S_display_O_video_lease_version;
    assign O_display_video_authorized=S_display_O_video_authorized;
    assign O_display_next_epoch=S_display_O_next_epoch;
    assign O_display_pending_valid=S_display_O_pending_valid;
    assign O_display_pending_config=S_display_O_pending_config;
    assign O_display_pending_tag=S_display_O_pending_tag;
    assign O_display_pending_epoch=S_display_O_pending_epoch;
    assign O_display_video_active_valid=S_display_O_video_active_valid;
    assign O_display_video_active_config=S_display_O_video_active_config;
    assign O_display_video_active_tag=S_display_O_video_active_tag;
    assign O_display_video_response_discarded=S_display_O_video_response_discarded;
    assign O_display_scan_stop_ack=S_display_O_scan_stop_ack;
    assign O_display_reader_retire_ack=S_display_O_reader_retire_ack;
    assign O_display_reader_host_retired=S_display_O_reader_host_retired;
    assign O_display_source_in_use=S_display_O_source_in_use;
    assign O_display_source_owner_retired=S_display_O_source_owner_retired;
    assign O_display_source_pipeline_retired=S_display_O_source_pipeline_retired;
    assign O_display_prefetch_y=S_display_O_prefetch_y;
    assign O_display_video_active_epoch=S_display_O_video_active_epoch;
    assign O_display_frame_start=S_display_O_frame_start;
    assign O_display_local_applied=S_display_O_local_applied;
    assign O_display_bank_busy=S_display_O_bank_busy;
    assign O_display_valid=S_display_O_valid;
    assign O_display_hsync=S_display_O_hsync;
    assign O_display_vsync=S_display_O_vsync;
    assign O_display_de=S_display_O_de;
    assign O_display_x=S_display_O_x;
    assign O_display_y=S_display_O_y;
    assign O_display_rgb=S_display_O_rgb;
    assign O_display_pixel_epoch=S_display_O_pixel_epoch;
    assign O_display_pixel_tag=S_display_O_pixel_tag;
    assign O_display_repeated=S_display_O_repeated;
    assign O_display_pixel_fault=S_display_O_pixel_fault;
    assign O_display_video_und=S_display_O_video_und;
    assign O_display_und_count=S_display_O_und_count;
    assign O_display_line_error_count=S_display_O_line_error_count;
    assign O_display_mem_valid=S_display_O_mem_valid;
    assign O_display_mem_addr=S_display_O_mem_addr;
    assign O_display_mem_tag=S_display_O_mem_tag;
    assign O_display_mem_token=S_display_O_mem_token;
    assign O_display_mem_generation=S_display_O_mem_generation;
    assign O_display_mem_deadline=S_display_O_mem_deadline;
    assign O_display_mem_ready=S_display_O_mem_ready;
    assign O_display_host_time=S_display_O_host_time;
    assign O_display_video_time=S_display_O_video_time;
    assign O_display_deadline_quarantined=S_display_O_deadline_quarantined;
    assign O_display_prepare_target=S_display_O_prepare_target;
    assign O_transition_start_ready=S_transition_O_start_ready && !S_stop_O_video_busy && !S_loop_O_video_busy && (!S_media_abort_video || I_transition_config[109:108]==3);
    assign O_transition_pause_allow=S_transition_O_pause_allow;
    assign O_transition_image_hold=S_transition_O_image_hold;
    assign O_transition_audio_hold=S_transition_O_audio_hold;
    assign O_transition_frozen_config=S_transition_O_frozen_config;
    assign O_transition_audio_bind_valid=S_transition_O_audio_bind_valid;
    assign O_transition_audio_bind_epoch=S_transition_O_audio_bind_epoch;
    assign O_transition_audio_bind_tag=S_transition_O_audio_bind_tag;
    assign O_transition_audio_bind_slot=S_transition_O_audio_bind_slot;
    assign O_transition_audio_bind_track_epoch=S_transition_O_audio_bind_track_epoch;
    assign O_transition_audio_bind_serial=S_transition_O_audio_bind_serial;
    assign O_transition_audio_bind_index=S_transition_O_audio_bind_index;
    assign O_transition_audio_bind_reuse=S_transition_O_audio_bind_reuse;
    assign O_transition_audio_pending=S_transition_O_audio_pending;
    assign O_transition_audio_unbind=S_transition_O_audio_unbind;
    assign O_transition_play_valid=S_transition_O_play_valid;
    assign O_transition_fade_valid=S_transition_O_fade_valid;
    assign O_transition_target_b=S_transition_O_target_b;
    assign O_transition_silence_valid=S_transition_O_silence_valid;
    assign O_transition_audio_stop_request=S_transition_O_audio_stop_request;
    assign O_transition_event_valid=S_transition_O_event_valid;
    assign O_transition_event_cancel=S_transition_O_event_cancel;
    assign O_transition_event_epoch=S_transition_O_event_epoch;
    assign O_transition_event_tag=S_transition_O_event_tag;
    assign O_transition_event_index=S_transition_O_event_index;
    assign O_transition_event_effect=S_transition_O_event_effect;
    assign O_transition_event_progress=S_transition_O_event_progress;
    assign O_transition_event_target=S_transition_O_event_target;
    assign O_transition_event_config=S_transition_O_event_config;
    assign O_transition_event_done_ready=S_transition_O_event_done_ready;
    assign O_transition_recover_ready=S_transition_O_recover_ready;
    assign O_transition_busy=S_transition_O_busy;
    assign O_transition_done_valid=S_transition_O_done_valid;
    assign O_transition_epoch=S_transition_O_epoch;
    assign O_transition_tag=S_transition_O_tag;
    assign O_transition_error=S_transition_O_error;
    assign O_transition_timeline_error=S_transition_O_timeline_error;
    assign O_transition_settle_error=S_transition_O_settle_error;
    assign O_transition_bind_error=S_transition_O_bind_error;
    assign O_transition_settled=S_transition_O_settled;
    assign O_transition_recovery_required=S_transition_O_recovery_required;
    assign O_transition_recovery_result=S_transition_O_recovery_result;
    assign O_transition_cancel_late=S_transition_O_cancel_late;
    assign O_transition_selected_source=S_transition_O_selected_source;
    assign O_transition_video_started=S_transition_O_video_started;
    assign O_transition_video_finished=S_transition_O_video_finished;
    assign O_transition_audio_started=S_transition_O_audio_started;
    assign O_transition_audio_finished=S_transition_O_audio_finished;
    assign O_transition_actual_start=S_transition_O_actual_start;
    assign O_transition_actual_midpoint=S_transition_O_actual_midpoint;
    assign O_transition_actual_audio=S_transition_O_actual_audio;
    assign O_transition_dwell_start=S_transition_O_dwell_start;
    assign O_transition_settle_time=S_transition_O_settle_time;
    assign O_transition_commit_epoch=S_transition_O_commit_epoch;
    assign O_transition_anchor_error=S_transition_O_anchor_error;
    assign O_transition_last_progress=S_transition_O_last_progress;
    assign O_transition_quarantined=S_transition_O_quarantined;
    assign O_transition_response_discarded=S_transition_O_response_discarded;
    assign O_transition_host_reservation=S_transition_O_host_reservation;
    assign O_transition_host_pinned_slots=S_transition_O_host_pinned_slots;
    assign O_transition_host_busy=S_transition_O_host_busy;
    assign O_transition_host_quarantined=S_transition_O_host_quarantined;
    assign O_transition_video_reservation=S_transition_O_video_reservation;
    assign O_transition_video_epoch=S_transition_O_video_epoch;
    assign O_transition_video_tag=S_transition_O_video_tag;
    assign O_transition_retry_pin_ready=S_transition_O_retry_pin_ready;
    assign O_transition_pin_error=S_transition_O_pin_error;
    assign O_transition_transition_started=S_transition_O_transition_started;
    assign O_transition_sync_required=S_transition_O_sync_required;
    assign O_transition_retry_result=S_transition_O_retry_result;
    assign O_transition_transition_error=S_transition_O_transition_error;
    assign O_transition_images=S_transition_O_images;
    assign O_transition_pin_quarantined=S_transition_O_pin_quarantined;
    assign O_transition_pin_response_discarded=S_transition_O_pin_response_discarded;
    assign O_event_event_ready=S_event_O_event_ready;
    assign O_event_busy=S_event_O_busy;
    assign O_event_done_valid=S_event_O_done_valid;
    assign O_event_epoch=S_event_O_epoch;
    assign O_event_tag=S_event_O_tag;
    assign O_event_index=S_event_O_index;
    assign O_event_error=S_event_O_error;
    assign O_event_backend_error=S_event_O_backend_error;
    assign O_event_lease_error=S_event_O_lease_error;
    assign O_event_slot_error=S_event_O_slot_error;
    assign O_event_commit_error=S_event_O_commit_error;
    assign O_event_prepare_error=S_event_O_prepare_error;
    assign O_event_retire_error=S_event_O_retire_error;
    assign O_event_applied=S_event_O_applied;
    assign O_event_retired=S_event_O_retired;
    assign O_event_apply_time=S_event_O_apply_time;
    assign O_event_commit_epoch=S_event_O_commit_epoch;
    assign O_event_quarantined=S_event_O_quarantined;
    assign O_event_response_discarded=S_event_O_response_discarded;
    assign O_event_target_valid=S_event_O_target_valid;
    assign O_event_target_epoch=S_event_O_target_epoch;
    assign O_event_target_time=S_event_O_target_time;
    assign O_event_target_tag=S_event_O_target_tag;
    assign O_event_video_abort=S_event_O_video_abort;
    assign O_event_host_start_valid=S_event_O_host_start_valid;
    assign O_event_host_config=S_event_O_host_config;
    assign O_event_host_tag=S_event_O_host_tag;
    assign O_event_host_abort=S_event_O_host_abort;
    assign O_event_host_done_ready=S_event_O_host_done_ready;
    assign O_event_host_quarantined=S_event_O_host_quarantined;
    assign O_event_host_response_discarded=S_event_O_host_response_discarded;
    assign S_image_command={S_io_O_image_slot_cmd_op,S_io_O_image_slot_cmd_slot,S_io_O_image_slot_cmd_owner,S_io_O_image_slot_cmd_token,S_io_O_image_slot_cmd_generation,S_io_O_image_slot_cmd_asset,S_io_O_image_slot_cmd_layout,S_io_O_image_slot_cmd_rotation,S_io_O_image_slot_cmd_resident,S_io_O_image_slot_cmd_success,S_io_O_image_producer_retired,S_io_O_image_memory_retired,1'b0,1'b0};
    assign S_display_command={S_display_O_slot_cmd_op,S_display_O_slot_cmd_slot,S_display_O_slot_cmd_owner,S_display_O_slot_cmd_token,S_display_O_slot_cmd_generation,32'd0,3'd0,2'd0,1'b0,1'b1,1'b0,1'b0,S_display_O_slot_reader_retired,S_display_O_slot_frame_boundary};
    assign O_slot_arbiter_client_ready=S_arbiter_O_client_ready;
    assign O_slot_arbiter_client_result_valid=S_arbiter_O_client_result_valid;
    assign O_slot_arbiter_client_result=S_arbiter_O_client_result;
    assign O_slot_arbiter_cmd_valid=S_arbiter_O_cmd_valid;
    assign O_slot_arbiter_cmd=S_arbiter_O_cmd;
    assign O_slot_arbiter_result_ready=S_arbiter_O_result_ready;
    assign O_slot_arbiter_mutating_slots=S_arbiter_O_mutating_slots;
    assign O_slot_arbiter_busy=S_arbiter_O_busy;
    assign O_slot_arbiter_contract_fault=S_arbiter_O_contract_fault;
    assign O_slot_arbiter_response_discarded=S_arbiter_O_response_discarded;
    assign O_sample_tick=S_io_O_sample_tick;
    assign O_acr_valid=S_io_O_acr_valid;
    assign O_acr_n=S_io_O_acr_n;
    assign O_acr_cts=S_io_O_acr_cts;
    assign O_acr_overflow=S_io_O_acr_overflow;
    assign O_image_start_ready=S_io_O_image_start_ready;
    assign O_image_part_needed=S_io_O_image_part_needed;
    assign O_image_part_index=S_io_O_image_part_index;
    assign O_image_part_ready=S_io_O_image_part_ready;
    assign O_image_slot_cmd_valid=S_io_O_image_slot_cmd_valid;
    assign O_image_slot_cmd_op=S_io_O_image_slot_cmd_op;
    assign O_image_slot_cmd_slot=S_io_O_image_slot_cmd_slot;
    assign O_image_slot_cmd_owner=S_io_O_image_slot_cmd_owner;
    assign O_image_slot_cmd_token=S_io_O_image_slot_cmd_token;
    assign O_image_slot_cmd_generation=S_io_O_image_slot_cmd_generation;
    assign O_image_slot_cmd_asset=S_io_O_image_slot_cmd_asset;
    assign O_image_slot_cmd_layout=S_io_O_image_slot_cmd_layout;
    assign O_image_slot_cmd_rotation=S_io_O_image_slot_cmd_rotation;
    assign O_image_slot_cmd_resident=S_io_O_image_slot_cmd_resident;
    assign O_image_slot_cmd_success=S_io_O_image_slot_cmd_success;
    assign O_image_producer_retired=S_io_O_image_producer_retired;
    assign O_image_memory_retired=S_io_O_image_memory_retired;
    assign O_image_slot_result_ready=S_io_O_image_slot_result_ready;
    assign O_image_busy=S_io_O_image_busy;
    assign O_image_progress=S_io_O_image_progress;
    assign O_image_done_valid=S_io_O_image_done_valid;
    assign O_image_error=S_io_O_image_error;
    assign O_image_context=S_io_O_image_context;
    assign O_image_tag=S_io_O_image_tag;
    assign O_image_generation=S_io_O_image_generation;
    assign O_image_lease_token=S_io_O_image_lease_token;
    assign O_image_slot=S_io_O_image_slot;
    assign O_image_published=S_io_O_image_published;
    assign O_image_slot_owned=S_io_O_image_slot_owned;
    assign O_image_file_started=S_io_O_image_file_started;
    assign O_image_transform_started=S_io_O_image_transform_started;
    assign O_image_writer_started=S_io_O_image_writer_started;
    assign O_image_file_source_error=S_io_O_image_file_source_error;
    assign O_image_parser_error=S_io_O_image_parser_error;
    assign O_image_storage_error=S_io_O_image_storage_error;
    assign O_image_transform_error=S_io_O_image_transform_error;
    assign O_image_writer_error=S_io_O_image_writer_error;
    assign O_image_memory_error=S_io_O_image_memory_error;
    assign O_image_file_error=S_io_O_image_file_error;
    assign O_image_path_warning=S_io_O_image_path_warning;
    assign O_image_file_size=S_io_O_image_file_size;
    assign O_image_accepted_writes=S_io_O_image_accepted_writes;
    assign O_image_retired_writes=S_io_O_image_retired_writes;
    assign O_image_pixels=S_io_O_image_pixels;
    assign O_image_response_discarded=S_io_O_image_response_discarded;
    assign O_image_path_ready=S_io_O_image_path_ready;
    assign O_image_mem_valid=S_io_O_image_mem_valid;
    assign O_image_mem_wr=S_io_O_image_mem_wr;
    assign O_image_mem_addr=S_io_O_image_mem_addr;
    assign O_image_mem_data=S_io_O_image_mem_data;
    assign O_image_mem_tag=S_io_O_image_mem_tag;
    assign O_image_mem_mask=S_io_O_image_mem_mask;
    assign O_image_mem_lease_token=S_io_O_image_mem_lease_token;
    assign O_image_mem_generation=S_io_O_image_mem_generation;
    assign O_image_mem_done_ready=S_io_O_image_mem_done_ready;
    assign O_image_evict_valid=S_io_O_image_evict_valid;
    assign O_image_evict_command=S_io_O_image_evict_command;
    assign O_image_evict_result_ready=S_io_O_image_evict_result_ready;
    assign O_image_loader_error=S_io_O_image_loader_error;
    assign O_image_slot_error=S_io_O_image_slot_error;
    assign O_image_loader_started=S_io_O_image_loader_started;
    assign O_image_reused=S_io_O_image_reused;
    assign O_image_evicted=S_io_O_image_evicted;
    assign O_image_quarantined=S_io_O_image_quarantined;
    assign O_image_stage_valid=S_io_O_image_stage_valid;
    assign O_image_staged_slots=S_io_O_image_staged_slots;
    assign O_image_stage_release_ready=S_io_O_image_stage_release_ready;
    assign O_image_frozen_request=S_io_O_image_frozen_request;
    assign O_image_loader_lease_token=S_io_O_image_loader_lease_token;
    assign O_scan_start_ready=S_io_O_scan_start_ready;
    assign O_scan_busy=S_io_O_scan_busy;
    assign O_scan_done_valid=S_io_O_scan_done_valid;
    assign O_scan_error=S_io_O_scan_error;
    assign O_scan_list_source_error=S_io_O_scan_list_source_error;
    assign O_scan_list_build_error=S_io_O_scan_list_build_error;
    assign O_scan_directory_build_error=S_io_O_scan_directory_build_error;
    assign O_scan_count=S_io_O_scan_count;
    assign O_scan_committed=S_io_O_scan_committed;
    assign O_scan_used_directory=S_io_O_scan_used_directory;
    assign O_scan_list_missing=S_io_O_scan_list_missing;
    assign O_scan_list_started=S_io_O_scan_list_started;
    assign O_scan_directory_started=S_io_O_scan_directory_started;
    assign O_scan_list_warning=S_io_O_scan_list_warning;
    assign O_scan_directory_warning=S_io_O_scan_directory_warning;
    assign O_scan_context=S_io_O_scan_context;
    assign O_scan_tag=S_io_O_scan_tag;
    assign O_scan_generation=S_io_O_scan_generation;
    assign O_scan_file_error=S_io_O_scan_file_error;
    assign O_scan_storage_error=S_io_O_scan_storage_error;
    assign O_scan_path_warning=S_io_O_scan_path_warning;
    assign O_scan_file_size=S_io_O_scan_file_size;
    assign O_scan_active_valid=S_io_O_scan_active_valid;
    assign O_scan_active_count=S_io_O_scan_active_count;
    assign O_scan_active_generation=S_io_O_scan_active_generation;
    assign O_scan_active_revision=S_io_O_scan_active_revision;
    assign O_scan_acquire_ready=S_io_O_scan_acquire_ready;
    assign O_scan_snapshot_valid=S_io_O_scan_snapshot_valid;
    assign O_scan_snapshot_count=S_io_O_scan_snapshot_count;
    assign O_scan_snapshot_generation=S_io_O_scan_snapshot_generation;
    assign O_scan_snapshot_revision=S_io_O_scan_snapshot_revision;
    assign O_scan_release_ready=S_io_O_scan_release_ready;
    assign O_scan_read_ready=S_io_O_scan_read_ready;
    assign O_scan_read_result_valid=S_io_O_scan_read_result_valid;
    assign O_scan_read_file_length=S_io_O_scan_read_file_length;
    assign O_scan_read_audio_length=S_io_O_scan_read_audio_length;
    assign O_scan_read_title_length=S_io_O_scan_read_title_length;
    assign O_scan_read_duration=S_io_O_scan_read_duration;
    assign O_scan_read_transition_ms=S_io_O_scan_read_transition_ms;
    assign O_scan_read_transition=S_io_O_scan_read_transition;
    assign O_scan_read_policy=S_io_O_scan_read_policy;
    assign O_scan_read_data=S_io_O_scan_read_data;
    assign O_scan_read_tag=S_io_O_scan_read_tag;
    assign O_scan_read_error=S_io_O_scan_read_error;
    assign O_scan_directory_error=S_io_O_scan_directory_error;
    assign O_scan_directory_primary_error=S_io_O_scan_directory_primary_error;
    assign O_scan_directory_storage_error=S_io_O_scan_directory_storage_error;
    assign O_scan_enum_warning=S_io_O_scan_enum_warning;
    assign O_scan_directory_sectors=S_io_O_scan_directory_sectors;
    assign O_scan_active_order=S_io_O_scan_active_order;
    assign O_scan_active_base_order=S_io_O_scan_active_base_order;
    assign O_scan_active_base_order_explicit=S_io_O_scan_active_base_order_explicit;
    assign O_scan_reorder_ready=S_io_O_scan_reorder_ready;
    assign O_scan_reorder_done_valid=S_io_O_scan_reorder_done_valid;
    assign O_scan_reorder_error=S_io_O_scan_reorder_error;
    assign O_scan_reorder_tag=S_io_O_scan_reorder_tag;
    assign O_scan_reorder_generation=S_io_O_scan_reorder_generation;
    assign O_scan_reorder_revision=S_io_O_scan_reorder_revision;
    assign O_scan_reorder_current_index=S_io_O_scan_reorder_current_index;
    assign O_audio_file_start_ready=S_io_O_audio_file_start_ready & S_file_allow;
    assign O_audio_file_path_ready=S_io_O_audio_file_path_ready;
    assign O_audio_file_busy=S_io_O_audio_file_busy;
    assign O_audio_file_done_valid=S_io_O_audio_file_done_valid;
    assign O_audio_file_error=S_io_O_audio_file_error;
    assign O_audio_file_file_error=S_io_O_audio_file_file_error;
    assign O_audio_file_storage_error=S_io_O_audio_file_storage_error;
    assign O_audio_file_path_warning=S_io_O_audio_file_path_warning;
    assign O_audio_file_context=S_io_O_audio_file_context;
    assign O_audio_file_tag=S_io_O_audio_file_tag;
    assign O_audio_file_generation=S_io_O_audio_file_generation;
    assign O_audio_file_file_size=S_io_O_audio_file_file_size;
    assign O_audio_byte_discarded=S_io_O_audio_byte_discarded;
    assign O_audio_recycle_ready=S_io_O_audio_recycle_ready;
    assign O_audio_recycle_done=S_io_O_audio_recycle_done;
    assign O_audio_available=S_io_O_audio_available;
    assign O_audio_source_busy=S_io_O_audio_source_busy;
    assign O_audio_written_frames=S_io_O_audio_written_frames;
    assign O_audio_play_ready=S_io_O_audio_play_ready;
    assign O_audio_fade_ready=S_io_O_audio_fade_ready;
    assign O_audio_silence_ready=S_io_O_audio_silence_ready;
    assign O_audio_silence_started=S_io_O_audio_silence_started;
    assign O_audio_silence_done=S_io_O_audio_silence_done;
    assign O_audio_paused=S_io_O_audio_paused;
    assign O_audio_pause_busy=S_io_O_audio_pause_busy;
    assign O_audio_sample_valid=S_io_O_audio_sample_valid;
    assign O_audio_left=S_io_O_audio_left;
    assign O_audio_right=S_io_O_audio_right;
    assign O_audio_clipped=S_io_O_audio_clipped;
    assign O_audio_fade_done=S_io_O_audio_fade_done;
    assign O_audio_active_b=S_io_O_audio_active_b;
    assign O_audio_busy=S_io_O_audio_busy;
    assign O_audio_started=S_io_O_audio_started;
    assign O_audio_loaded=S_io_O_audio_loaded;
    assign O_audio_enabled=S_io_O_audio_enabled;
    assign O_audio_end=S_io_O_audio_end;
    assign O_audio_consumed=S_io_O_audio_consumed;
    assign O_audio_underrun=S_io_O_audio_underrun;
    assign O_audio_release=S_io_O_audio_release;
    assign O_audio_next_index=S_io_O_audio_next_index;
    assign O_audio_need_fill=S_io_O_audio_need_fill;
    assign O_audio_failed=S_io_O_audio_failed;
    assign O_audio_slot_stopping=S_io_O_audio_slot_stopping;
    assign O_audio_event_valid=S_io_O_audio_event_valid;
    assign O_audio_event_header=S_io_O_audio_event_header;
    assign O_audio_event_epoch=S_io_O_audio_event_epoch;
    assign O_audio_event_total_frames=S_io_O_audio_event_total_frames;
    assign O_audio_event_written_frames=S_io_O_audio_event_written_frames;
    assign O_audio_event_error=S_io_O_audio_event_error;
    assign O_audio_bind_ready=S_io_O_audio_bind_ready;
    assign O_audio_audio_ready=S_io_O_audio_audio_ready;
    assign O_audio_audio_epoch=S_io_O_audio_audio_epoch;
    assign O_audio_track_known=S_io_O_audio_track_known;
    assign O_audio_track_epochs=S_io_O_audio_track_epochs;
    assign O_audio_track_serials=S_io_O_audio_track_serials;
    assign O_audio_track_totals=S_io_O_audio_track_totals;
    assign O_audio_bound=S_io_O_audio_bound;
    assign O_audio_binding_revoked=S_io_O_audio_binding_revoked;
    assign O_audio_bind_error=S_io_O_audio_bind_error;
    assign O_audio_audio_accepted=S_io_O_audio_audio_accepted;
    assign O_audio_audio_accepted_epoch=S_io_O_audio_audio_accepted_epoch;
    assign O_audio_audio_accepted_tag=S_io_O_audio_audio_accepted_tag;
    assign O_audio_prepare_contract_fault=S_io_O_audio_prepare_contract_fault;
    assign O_audio_prepare_quarantined=S_io_O_audio_prepare_quarantined;
    assign O_audio_prepare_response_discarded=S_io_O_audio_prepare_response_discarded;
    assign O_storage_demo_active=S_io_O_storage_demo_active;
    assign O_storage_demo_ready=S_io_O_storage_demo_ready;
    assign O_storage_recovery_active=S_io_O_storage_recovery_active;
    assign O_storage_demo_error=S_io_O_storage_demo_error;
    assign O_storage_flash_valid=S_io_O_storage_flash_valid;
    assign O_storage_flash_address=S_io_O_storage_flash_address;
    assign O_storage_flash_length=S_io_O_storage_flash_length;
    assign O_storage_flash_tag=S_io_O_storage_flash_tag;
    assign O_storage_flash_read_ready=S_io_O_storage_flash_read_ready;
    assign O_storage_flash_done_ready=S_io_O_storage_flash_done_ready;
    assign O_storage_lease_grant=S_io_O_storage_lease_grant;
    assign O_storage_busy=S_io_O_storage_busy;
    assign O_storage_quiescent=S_io_O_storage_quiescent;
    assign O_storage_leased_contexts=S_io_O_storage_leased_contexts;
    assign O_storage_descriptors=S_io_O_storage_descriptors;
    assign O_storage_pending_reads=S_io_O_storage_pending_reads;
    assign O_storage_contract_fault=S_io_O_storage_contract_fault;
    assign O_storage_response_discarded=S_io_O_storage_response_discarded;
    assign O_storage_mount_ready=S_io_O_storage_mount_ready;
    assign O_storage_mount_result_valid=S_io_O_storage_mount_result_valid;
    assign O_storage_mount_error=S_io_O_storage_mount_error;
    assign O_storage_mount_storage_error=S_io_O_storage_mount_storage_error;
    assign O_storage_mount_generation=S_io_O_storage_mount_generation;
    assign O_storage_mounted=S_io_O_storage_mounted;
    assign O_storage_generation=S_io_O_storage_generation;
    assign O_storage_card_ready=S_io_O_storage_card_ready;
    assign O_storage_card_present=S_io_O_storage_card_present;
    assign O_storage_capacity_sectors=S_io_O_storage_capacity_sectors;
    assign O_storage_sd_high_capacity=S_io_O_storage_sd_high_capacity;
    assign O_storage_sd_card_error=S_io_O_storage_sd_card_error;
    assign O_storage_sd_ncs=S_io_O_storage_sd_ncs;
    assign O_storage_sd_sclk=S_io_O_storage_sd_sclk;
    assign O_storage_sd_mosi=S_io_O_storage_sd_mosi;
    assign O_session_client_abort=S_io_O_session_client_abort;
    assign O_session_allow_start=S_io_O_session_allow_start;
    assign O_session_ready=S_io_O_session_ready;
    assign O_session_busy=S_io_O_session_busy;
    assign O_session_scan_done=S_io_O_session_scan_done;
    assign O_session_count=S_io_O_session_count;
    assign O_session_error=S_io_O_session_error;
    assign O_session_scan_error=S_io_O_session_scan_error;
    assign O_session_mount_error=S_io_O_session_mount_error;
    assign O_session_mount_storage_error=S_io_O_session_mount_storage_error;
    assign O_session_generation=S_io_O_session_generation;
    assign S_file_allow={2{!S_stop_O_host_busy}};
    assign O_audio_stop_stop_ack=S_stop_O_stop_ack;
    assign O_audio_stop_video_busy=S_stop_O_video_busy;
    assign O_audio_stop_host_busy=S_stop_O_host_busy;
    assign O_bgm_start_ready=S_loop_O_start_ready;
    assign O_bgm_need=S_loop_O_need;
    assign O_bgm_done_valid=S_loop_O_done_valid;
    assign O_bgm_result=S_loop_O_result;
    assign O_resident_mem_valid=S_resident_O_mem_valid;
    assign O_resident_mem_wr=S_resident_O_mem_wr;
    assign O_resident_mem_addr=S_resident_O_mem_addr;
    assign O_resident_mem_data=S_resident_O_mem_data;
    assign O_resident_mem_tag=S_resident_O_mem_tag;
    assign O_resident_mem_token=S_resident_O_mem_token;
    assign O_resident_mem_generation=S_resident_O_mem_generation;
    assign O_resident_mem_mask=S_resident_O_mem_mask;
    assign O_resident_mem_result_ready=S_resident_O_mem_result_ready;
    assign O_resident_busy=S_resident_O_busy;
    assign O_resident_ready=S_resident_O_ready;
    assign O_resident_token=S_resident_O_token;
    assign O_resident_generation=S_resident_O_generation;
    assign O_resident_error=S_resident_O_error;
    assign O_resident_response_discarded=S_resident_O_response_discarded;
endmodule
