// Real media data path: TF SPI/FAT32 -> scan/index, BMP frame load and two WAV files.
// Mount/scan/file ownership are connected internally. Display memory/event/UI remain external.
// I_host_clk=125 MHz, I_sd_clk=100 MHz, I_video_clk=audio/video 25 MHz.
module media_io (
    input wire I_host_clk,
    input wire I_sd_clk,
    input wire I_video_clk,
    input wire I_async_reset,
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
    input wire I_image_slot_cmd_ready,
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
    input wire I_image_slot_result_valid,
    output wire O_image_slot_result_ready,
    input wire [3:0] I_image_slot_result_error,
    input wire [2:0] I_image_slot_result_op,
    input wire [2:0] I_image_slot_result_slot,
    input wire [1:0] I_image_slot_result_owner,
    input wire [31:0] I_image_slot_result_token,
    input wire [31:0] I_image_slot_result_generation,
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
    input wire [17:0] I_image_slot_states,
    input wire [17:0] I_image_slot_layouts,
    input wire [17:0] I_image_slot_readers,
    input wire [191:0] I_image_slot_tokens,
    input wire [191:0] I_image_slot_generations,
    input wire [191:0] I_image_slot_assets,
    input wire [11:0] I_image_slot_rotations,
    input wire [5:0] I_image_slot_resident,
    input wire [5:0] I_image_slot_stale,
    input wire [5:0] I_image_pinned_slots,
    input wire [5:0] I_image_mutating_slots,
    input wire [137:0] I_image_host_reservation,
    output wire O_image_evict_valid,
    input wire I_image_evict_ready,
    output wire [114:0] O_image_evict_command,
    input wire I_image_evict_result_valid,
    output wire O_image_evict_result_ready,
    input wire [96:0] I_image_evict_result,
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
    input wire I_audio_play_valid,
    output wire O_audio_play_ready,
    input wire I_audio_fade_valid,
    input wire I_audio_target_b,
    output wire O_audio_fade_ready,
    input wire I_audio_silence_valid,
    output wire O_audio_silence_ready,
    output wire O_audio_silence_started,
    output wire O_audio_silence_done,
    input wire I_audio_pause,
    input wire I_audio_pause_allow,
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
    input wire [1:0] I_audio_event_ready,
    output wire [1:0] O_audio_event_header,
    output wire [31:0] O_audio_event_epoch,
    output wire [63:0] O_audio_event_total_frames,
    output wire [63:0] O_audio_event_written_frames,
    output wire [7:0] O_audio_event_error,
    input wire I_audio_bind_valid,
    output wire O_audio_bind_ready,
    input wire [31:0] I_audio_bind_display_epoch,
    input wire [15:0] I_audio_bind_display_tag,
    input wire I_audio_bind_slot,
    input wire [15:0] I_audio_bind_track_epoch,
    input wire [31:0] I_audio_bind_track_serial,
    input wire [31:0] I_audio_bind_start_index,
    input wire I_audio_bind_reuse_active,
    input wire I_audio_unbind,
    input wire I_audio_bind_abort,
    input wire I_audio_pending_valid,
    input wire [31:0] I_audio_pending_epoch,
    input wire [15:0] I_audio_pending_tag,
    input wire I_audio_display_audio_applied,
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
    output wire [31:0] O_session_generation
);
    wire S_image_O_start_ready;
    wire S_image_O_lease_request;
    wire S_image_O_lease_active;
    wire S_image_O_part_needed;
    wire [3:0] S_image_O_part_index;
    wire S_image_O_part_ready;
    wire S_image_O_slot_cmd_valid;
    wire [2:0] S_image_O_slot_cmd_op;
    wire [2:0] S_image_O_slot_cmd_slot;
    wire [1:0] S_image_O_slot_cmd_owner;
    wire [31:0] S_image_O_slot_cmd_token;
    wire [31:0] S_image_O_slot_cmd_generation;
    wire [31:0] S_image_O_slot_cmd_asset;
    wire [2:0] S_image_O_slot_cmd_layout;
    wire [1:0] S_image_O_slot_cmd_rotation;
    wire S_image_O_slot_cmd_resident;
    wire S_image_O_slot_cmd_success;
    wire S_image_O_producer_retired;
    wire S_image_O_memory_retired;
    wire S_image_O_slot_result_ready;
    wire S_image_O_busy;
    wire S_image_O_progress;
    wire S_image_O_done_valid;
    wire [3:0] S_image_O_error;
    wire [1:0] S_image_O_context;
    wire [15:0] S_image_O_tag;
    wire [31:0] S_image_O_generation;
    wire [31:0] S_image_O_lease_token;
    wire [2:0] S_image_O_slot;
    wire S_image_O_published;
    wire S_image_O_slot_owned;
    wire S_image_O_file_started;
    wire S_image_O_transform_started;
    wire S_image_O_writer_started;
    wire [3:0] S_image_O_file_source_error;
    wire [3:0] S_image_O_parser_error;
    wire [3:0] S_image_O_storage_error;
    wire [3:0] S_image_O_transform_error;
    wire [3:0] S_image_O_writer_error;
    wire [3:0] S_image_O_memory_error;
    wire [7:0] S_image_O_file_error;
    wire [2:0] S_image_O_path_warning;
    wire [31:0] S_image_O_file_size;
    wire [31:0] S_image_O_accepted_writes;
    wire [31:0] S_image_O_retired_writes;
    wire [31:0] S_image_O_pixels;
    wire S_image_O_response_discarded;
    wire S_image_O_path_ready;
    wire S_image_O_fs_open_valid;
    wire [1:0] S_image_O_fs_open_context;
    wire [15:0] S_image_O_fs_open_tag;
    wire [6:0] S_image_O_fs_path_length;
    wire [31:0] S_image_O_fs_sector_budget;
    wire S_image_O_fs_path_valid;
    wire [7:0] S_image_O_fs_path_data;
    wire S_image_O_fs_path_last;
    wire S_image_O_fs_open_cancel;
    wire S_image_O_fs_open_result_ready;
    wire S_image_O_fs_read_valid;
    wire [1:0] S_image_O_fs_read_context;
    wire [1:0] S_image_O_fs_read_priority;
    wire [31:0] S_image_O_fs_offset;
    wire [31:0] S_image_O_fs_length;
    wire [15:0] S_image_O_fs_epoch;
    wire S_image_O_fs_byte_ready;
    wire S_image_O_fs_done_ready;
    wire S_image_O_fs_cancel_valid;
    wire [1:0] S_image_O_fs_cancel_context;
    wire [15:0] S_image_O_fs_cancel_epoch;
    wire S_image_O_fs_cancel_done_ready;
    wire S_image_O_fs_close_valid;
    wire [1:0] S_image_O_fs_close_context;
    wire S_image_O_mem_valid;
    wire S_image_O_mem_wr;
    wire [20:0] S_image_O_mem_addr;
    wire [31:0] S_image_O_mem_data;
    wire [31:0] S_image_O_mem_tag;
    wire [3:0] S_image_O_mem_mask;
    wire [31:0] S_image_O_mem_lease_token;
    wire [31:0] S_image_O_mem_generation;
    wire S_image_O_mem_done_ready;
    wire S_image_O_evict_valid;
    wire [114:0] S_image_O_evict_command;
    wire S_image_O_evict_result_ready;
    wire [3:0] S_image_O_loader_error;
    wire [3:0] S_image_O_slot_error;
    wire S_image_O_loader_started;
    wire S_image_O_reused;
    wire S_image_O_evicted;
    wire S_image_O_quarantined;
    wire S_image_O_stage_valid;
    wire [5:0] S_image_O_staged_slots;
    wire S_image_O_stage_release_ready;
    wire [227:0] S_image_O_frozen_request;
    wire [31:0] S_image_O_loader_lease_token;
    wire S_scan_O_start_ready;
    wire S_scan_O_lease_request;
    wire S_scan_O_lease_active;
    wire S_scan_O_busy;
    wire S_scan_O_done_valid;
    wire [3:0] S_scan_O_error;
    wire [3:0] S_scan_O_list_source_error;
    wire [3:0] S_scan_O_list_build_error;
    wire [3:0] S_scan_O_directory_build_error;
    wire [6:0] S_scan_O_count;
    wire S_scan_O_committed;
    wire S_scan_O_used_directory;
    wire S_scan_O_list_missing;
    wire S_scan_O_list_started;
    wire S_scan_O_directory_started;
    wire [7:0] S_scan_O_list_warning;
    wire [7:0] S_scan_O_directory_warning;
    wire [1:0] S_scan_O_context;
    wire [15:0] S_scan_O_tag;
    wire [31:0] S_scan_O_generation;
    wire [7:0] S_scan_O_file_error;
    wire [3:0] S_scan_O_storage_error;
    wire [2:0] S_scan_O_path_warning;
    wire [31:0] S_scan_O_file_size;
    wire S_scan_O_fs_open_valid;
    wire [1:0] S_scan_O_fs_open_context;
    wire [15:0] S_scan_O_fs_open_tag;
    wire [6:0] S_scan_O_fs_path_length;
    wire [31:0] S_scan_O_fs_sector_budget;
    wire S_scan_O_fs_path_valid;
    wire [7:0] S_scan_O_fs_path_data;
    wire S_scan_O_fs_path_last;
    wire S_scan_O_fs_open_cancel;
    wire S_scan_O_fs_open_result_ready;
    wire S_scan_O_fs_read_valid;
    wire [1:0] S_scan_O_fs_read_context;
    wire [1:0] S_scan_O_fs_read_priority;
    wire [31:0] S_scan_O_fs_offset;
    wire [31:0] S_scan_O_fs_length;
    wire [15:0] S_scan_O_fs_epoch;
    wire S_scan_O_fs_byte_ready;
    wire S_scan_O_fs_done_ready;
    wire S_scan_O_fs_cancel_valid;
    wire [1:0] S_scan_O_fs_cancel_context;
    wire [15:0] S_scan_O_fs_cancel_epoch;
    wire S_scan_O_fs_cancel_done_ready;
    wire S_scan_O_fs_close_valid;
    wire [1:0] S_scan_O_fs_close_context;
    wire S_scan_O_active_valid;
    wire [6:0] S_scan_O_active_count;
    wire [31:0] S_scan_O_active_generation;
    wire [31:0] S_scan_O_active_revision;
    wire S_scan_O_acquire_ready;
    wire S_scan_O_snapshot_valid;
    wire [6:0] S_scan_O_snapshot_count;
    wire [31:0] S_scan_O_snapshot_generation;
    wire [31:0] S_scan_O_snapshot_revision;
    wire S_scan_O_release_ready;
    wire S_scan_O_read_ready;
    wire S_scan_O_read_result_valid;
    wire [6:0] S_scan_O_read_file_length;
    wire [6:0] S_scan_O_read_audio_length;
    wire [5:0] S_scan_O_read_title_length;
    wire [9:0] S_scan_O_read_duration;
    wire [9:0] S_scan_O_read_transition_ms;
    wire [2:0] S_scan_O_read_transition;
    wire [6:0] S_scan_O_read_policy;
    wire [7:0] S_scan_O_read_data;
    wire [15:0] S_scan_O_read_tag;
    wire [3:0] S_scan_O_read_error;
    wire [7:0] S_scan_O_directory_error;
    wire [7:0] S_scan_O_directory_primary_error;
    wire [3:0] S_scan_O_directory_storage_error;
    wire [2:0] S_scan_O_enum_warning;
    wire [32:0] S_scan_O_directory_sectors;
    wire S_scan_O_enum_valid;
    wire [15:0] S_scan_O_enum_tag;
    wire [6:0] S_scan_O_enum_path_length;
    wire [31:0] S_scan_O_enum_sector_budget;
    wire S_scan_O_enum_path_valid;
    wire [7:0] S_scan_O_enum_path_data;
    wire S_scan_O_enum_path_last;
    wire S_scan_O_enum_stop;
    wire S_scan_O_enum_cancel;
    wire S_scan_O_enum_entry_ready;
    wire S_scan_O_enum_name_ready;
    wire S_scan_O_enum_done_ready;
    wire [1:0] S_scan_O_active_order;
    wire [1:0] S_scan_O_active_base_order;
    wire S_scan_O_active_base_order_explicit;
    wire S_scan_O_reorder_ready;
    wire S_scan_O_reorder_done_valid;
    wire [3:0] S_scan_O_reorder_error;
    wire [15:0] S_scan_O_reorder_tag;
    wire [31:0] S_scan_O_reorder_generation;
    wire [31:0] S_scan_O_reorder_revision;
    wire [5:0] S_scan_O_reorder_current_index;
    wire S_a_O_start_ready;
    wire S_a_O_lease_request;
    wire S_a_O_path_ready;
    wire S_a_O_lease_active;
    wire S_a_O_busy;
    wire S_a_O_done_valid;
    wire [3:0] S_a_O_error;
    wire [7:0] S_a_O_file_error;
    wire [3:0] S_a_O_storage_error;
    wire [2:0] S_a_O_path_warning;
    wire [1:0] S_a_O_context;
    wire [15:0] S_a_O_tag;
    wire [31:0] S_a_O_generation;
    wire [31:0] S_a_O_file_size;
    wire S_a_O_track_started;
    wire S_a_O_track_start_valid;
    wire [31:0] S_a_O_track_file_size;
    wire [31:0] S_a_O_track_start_index;
    wire [15:0] S_a_O_track_epoch;
    wire S_a_O_track_byte_valid;
    wire [7:0] S_a_O_track_byte_data;
    wire S_a_O_track_byte_last;
    wire [15:0] S_a_O_track_byte_epoch;
    wire S_a_O_track_stream_error;
    wire [15:0] S_a_O_track_stream_error_epoch;
    wire S_a_O_track_cancel_ready;
    wire S_a_O_io_retired;
    wire S_a_O_fs_open_valid;
    wire [1:0] S_a_O_fs_open_context;
    wire [15:0] S_a_O_fs_open_tag;
    wire [6:0] S_a_O_fs_path_length;
    wire [31:0] S_a_O_fs_sector_budget;
    wire S_a_O_fs_path_valid;
    wire [7:0] S_a_O_fs_path_data;
    wire S_a_O_fs_path_last;
    wire S_a_O_fs_open_cancel;
    wire S_a_O_fs_open_result_ready;
    wire S_a_O_fs_read_valid;
    wire [1:0] S_a_O_fs_read_context;
    wire [1:0] S_a_O_fs_read_priority;
    wire [31:0] S_a_O_fs_offset;
    wire [31:0] S_a_O_fs_length;
    wire [15:0] S_a_O_fs_epoch;
    wire S_a_O_fs_byte_ready;
    wire S_a_O_fs_done_ready;
    wire S_a_O_fs_cancel_valid;
    wire [1:0] S_a_O_fs_cancel_context;
    wire [15:0] S_a_O_fs_cancel_epoch;
    wire S_a_O_fs_cancel_done_ready;
    wire S_a_O_fs_close_valid;
    wire [1:0] S_a_O_fs_close_context;
    wire S_b_O_start_ready;
    wire S_b_O_lease_request;
    wire S_b_O_path_ready;
    wire S_b_O_lease_active;
    wire S_b_O_busy;
    wire S_b_O_done_valid;
    wire [3:0] S_b_O_error;
    wire [7:0] S_b_O_file_error;
    wire [3:0] S_b_O_storage_error;
    wire [2:0] S_b_O_path_warning;
    wire [1:0] S_b_O_context;
    wire [15:0] S_b_O_tag;
    wire [31:0] S_b_O_generation;
    wire [31:0] S_b_O_file_size;
    wire S_b_O_track_started;
    wire S_b_O_track_start_valid;
    wire [31:0] S_b_O_track_file_size;
    wire [31:0] S_b_O_track_start_index;
    wire [15:0] S_b_O_track_epoch;
    wire S_b_O_track_byte_valid;
    wire [7:0] S_b_O_track_byte_data;
    wire S_b_O_track_byte_last;
    wire [15:0] S_b_O_track_byte_epoch;
    wire S_b_O_track_stream_error;
    wire [15:0] S_b_O_track_stream_error_epoch;
    wire S_b_O_track_cancel_ready;
    wire S_b_O_io_retired;
    wire S_b_O_fs_open_valid;
    wire [1:0] S_b_O_fs_open_context;
    wire [15:0] S_b_O_fs_open_tag;
    wire [6:0] S_b_O_fs_path_length;
    wire [31:0] S_b_O_fs_sector_budget;
    wire S_b_O_fs_path_valid;
    wire [7:0] S_b_O_fs_path_data;
    wire S_b_O_fs_path_last;
    wire S_b_O_fs_open_cancel;
    wire S_b_O_fs_open_result_ready;
    wire S_b_O_fs_read_valid;
    wire [1:0] S_b_O_fs_read_context;
    wire [1:0] S_b_O_fs_read_priority;
    wire [31:0] S_b_O_fs_offset;
    wire [31:0] S_b_O_fs_length;
    wire [15:0] S_b_O_fs_epoch;
    wire S_b_O_fs_byte_ready;
    wire S_b_O_fs_done_ready;
    wire S_b_O_fs_cancel_valid;
    wire [1:0] S_b_O_fs_cancel_context;
    wire [15:0] S_b_O_fs_cancel_epoch;
    wire S_b_O_fs_cancel_done_ready;
    wire S_b_O_fs_close_valid;
    wire [1:0] S_b_O_fs_close_context;
    wire [1:0] S_player_O_start_ready;
    wire [1:0] S_player_O_byte_ready;
    wire [1:0] S_player_O_byte_discarded;
    wire [1:0] S_player_O_recycle_ready;
    wire [1:0] S_player_O_recycle_done;
    wire [1:0] S_player_O_available;
    wire [1:0] S_player_O_cancel_valid;
    wire [31:0] S_player_O_cancel_epoch;
    wire [1:0] S_player_O_io_retire_request;
    wire [1:0] S_player_O_source_busy;
    wire [63:0] S_player_O_written_frames;
    wire S_player_O_play_ready;
    wire S_player_O_fade_ready;
    wire S_player_O_silence_ready;
    wire S_player_O_silence_started;
    wire S_player_O_silence_done;
    wire S_player_O_paused;
    wire S_player_O_pause_busy;
    wire S_player_O_sample_valid;
    wire [23:0] S_player_O_left;
    wire [23:0] S_player_O_right;
    wire S_player_O_clipped;
    wire S_player_O_fade_done;
    wire S_player_O_active_b;
    wire S_player_O_busy;
    wire S_player_O_started;
    wire [1:0] S_player_O_loaded;
    wire [1:0] S_player_O_enabled;
    wire [1:0] S_player_O_end;
    wire [1:0] S_player_O_consumed;
    wire [1:0] S_player_O_underrun;
    wire [1:0] S_player_O_release;
    wire [63:0] S_player_O_next_index;
    wire [1:0] S_player_O_need_fill;
    wire [1:0] S_player_O_failed;
    wire [1:0] S_player_O_slot_stopping;
    wire [1:0] S_player_O_event_valid;
    wire [1:0] S_player_O_event_header;
    wire [31:0] S_player_O_event_epoch;
    wire [63:0] S_player_O_event_total_frames;
    wire [63:0] S_player_O_event_written_frames;
    wire [7:0] S_player_O_event_error;
    wire S_player_O_bind_ready;
    wire S_player_O_audio_ready;
    wire [31:0] S_player_O_audio_epoch;
    wire [1:0] S_player_O_track_known;
    wire [31:0] S_player_O_track_epochs;
    wire [63:0] S_player_O_track_serials;
    wire [63:0] S_player_O_track_totals;
    wire S_player_O_bound;
    wire S_player_O_binding_revoked;
    wire [3:0] S_player_O_bind_error;
    wire S_player_O_audio_accepted;
    wire [31:0] S_player_O_audio_accepted_epoch;
    wire [15:0] S_player_O_audio_accepted_tag;
    wire S_player_O_prepare_contract_fault;
    wire S_player_O_prepare_quarantined;
    wire S_player_O_prepare_response_discarded;
    wire S_files_O_demo_active;
    wire S_files_O_demo_ready;
    wire S_files_O_recovery_active;
    wire [3:0] S_files_O_demo_error;
    wire S_files_O_flash_valid;
    wire [23:0] S_files_O_flash_address;
    wire [15:0] S_files_O_flash_length;
    wire [15:0] S_files_O_flash_tag;
    wire S_files_O_flash_read_ready;
    wire S_files_O_flash_done_ready;
    wire [3:0] S_files_O_lease_grant;
    wire [3:0] S_files_O_client_open_ready;
    wire [3:0] S_files_O_client_path_ready;
    wire [3:0] S_files_O_client_open_result_valid;
    wire [96:0] S_files_O_client_open_result;
    wire [3:0] S_files_O_client_read_ready;
    wire [3:0] S_files_O_client_byte_valid;
    wire [90:0] S_files_O_client_byte;
    wire [3:0] S_files_O_client_done_valid;
    wire [379:0] S_files_O_client_done;
    wire [3:0] S_files_O_client_cancel_ready;
    wire [3:0] S_files_O_client_cancel_done_valid;
    wire [49:0] S_files_O_client_cancel_done;
    wire [3:0] S_files_O_client_close_ready;
    wire S_files_O_busy;
    wire S_files_O_quiescent;
    wire [2:0] S_files_O_leased_contexts;
    wire [2:0] S_files_O_descriptors;
    wire [2:0] S_files_O_pending_reads;
    wire S_files_O_contract_fault;
    wire S_files_O_response_discarded;
    wire S_files_O_scan_ready;
    wire S_files_O_scan_path_ready;
    wire S_files_O_scan_entry_valid;
    wire [7:0] S_files_O_scan_attr;
    wire [31:0] S_files_O_scan_size;
    wire [31:0] S_files_O_scan_first_cluster;
    wire [87:0] S_files_O_scan_alias;
    wire [6:0] S_files_O_scan_name_length;
    wire S_files_O_scan_is_lfn;
    wire S_files_O_scan_name_valid;
    wire [7:0] S_files_O_scan_name_data;
    wire S_files_O_scan_name_last;
    wire S_files_O_scan_done_valid;
    wire [15:0] S_files_O_scan_tag;
    wire [31:0] S_files_O_scan_generation;
    wire [31:0] S_files_O_scan_sectors;
    wire [2:0] S_files_O_scan_warning;
    wire [7:0] S_files_O_scan_error;
    wire [3:0] S_files_O_scan_storage_error;
    wire S_files_O_mount_ready;
    wire S_files_O_mount_result_valid;
    wire [7:0] S_files_O_mount_error;
    wire [3:0] S_files_O_mount_storage_error;
    wire [31:0] S_files_O_mount_generation;
    wire S_files_O_mounted;
    wire [31:0] S_files_O_generation;
    wire S_files_O_card_ready;
    wire S_files_O_card_present;
    wire [32:0] S_files_O_capacity_sectors;
    wire S_files_O_sd_high_capacity;
    wire [3:0] S_files_O_sd_card_error;
    wire S_files_O_sd_ncs;
    wire S_files_O_sd_sclk;
    wire S_files_O_sd_mosi;
    wire S_session_O_unmount;
    wire S_session_O_mount_valid;
    wire S_session_O_mount_result_ready;
    wire S_session_O_scan_start_valid;
    wire S_session_O_scan_done_ready;
    wire S_session_O_scan_abort;
    wire [15:0] S_session_O_scan_tag;
    wire [31:0] S_session_O_scan_generation;
    wire S_session_O_client_abort;
    wire S_session_O_allow_start;
    wire S_session_O_ready;
    wire S_session_O_busy;
    wire S_session_O_scan_done;
    wire [6:0] S_session_O_count;
    wire [3:0] S_session_O_error;
    wire [3:0] S_session_O_scan_error;
    wire [7:0] S_session_O_mount_error;
    wire [3:0] S_session_O_mount_storage_error;
    wire [31:0] S_session_O_generation;
    wire [94:0] S_image_done;
    wire [94:0] S_a_done;
    wire [94:0] S_b_done;
    wire [94:0] S_scan_done;
    wire [1:0] S_auto_recycle;
    wire [1:0] S_abort_event_ready;
    wire S_host_reset,S_video_reset;
    reg [1:0] S_need_meta,S_need_host;
    reg [1:0] S_recycle_issued;
    reg S_session_abort_meta,S_session_abort_video;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin S_need_meta<=0; S_need_host<=0; S_recycle_issued<=0; end
        else begin
            S_need_meta<=S_player_O_need_fill; S_need_host<=S_need_meta;
            if(!S_session_O_client_abort) S_recycle_issued<=0;
            else S_recycle_issued<=S_recycle_issued | (S_auto_recycle & S_player_O_recycle_ready);
        end
    end
    assign S_auto_recycle={2{S_session_O_client_abort}} & ~S_recycle_issued;
    assign S_abort_event_ready={2{S_session_abort_video}};
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin S_session_abort_meta<=1; S_session_abort_video<=1; end
        else begin S_session_abort_meta<=S_session_O_client_abort; S_session_abort_video<=S_session_abort_meta; end
    end
    samp_tick u_tick (.I_clk(I_video_clk),.I_reset(S_video_reset),.O_sample_tick(O_sample_tick));
    acr_gen u_acr (.I_clk(I_video_clk),.I_reset(S_video_reset),.I_sample_tick(O_sample_tick),
        .O_acr_valid(O_acr_valid),.O_acr_n(O_acr_n),.O_acr_cts(O_acr_cts),.O_measure_overflow(O_acr_overflow));
    image_load_pipeline u_image (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_files_O_mounted),
        .I_media_generation(S_files_O_generation),
        .I_start_valid(I_image_start_valid && S_session_O_allow_start),
        .O_start_ready(S_image_O_start_ready),
        .O_lease_request(S_image_O_lease_request),
        .O_lease_active(S_image_O_lease_active),
        .I_lease_grant(S_files_O_lease_grant[0]),
        .I_context(2'd0),
        .I_tag(I_image_tag),
        .I_generation(I_image_generation),
        .I_asset(I_image_asset),
        .I_layout(I_image_layout),
        .I_compose(I_image_compose),
        .I_parts(I_image_parts),
        .O_part_needed(S_image_O_part_needed),
        .O_part_index(S_image_O_part_index),
        .I_part_valid(I_image_part_valid),
        .O_part_ready(S_image_O_part_ready),
        .I_part_path_length(I_image_part_path_length),
        .I_rotation(I_image_rotation),
        .I_abort(I_image_abort || S_session_O_client_abort),
        .O_slot_cmd_valid(S_image_O_slot_cmd_valid),
        .I_slot_cmd_ready(I_image_slot_cmd_ready),
        .O_slot_cmd_op(S_image_O_slot_cmd_op),
        .O_slot_cmd_slot(S_image_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_image_O_slot_cmd_owner),
        .O_slot_cmd_token(S_image_O_slot_cmd_token),
        .O_slot_cmd_generation(S_image_O_slot_cmd_generation),
        .O_slot_cmd_asset(S_image_O_slot_cmd_asset),
        .O_slot_cmd_layout(S_image_O_slot_cmd_layout),
        .O_slot_cmd_rotation(S_image_O_slot_cmd_rotation),
        .O_slot_cmd_resident(S_image_O_slot_cmd_resident),
        .O_slot_cmd_success(S_image_O_slot_cmd_success),
        .O_producer_retired(S_image_O_producer_retired),
        .O_memory_retired(S_image_O_memory_retired),
        .I_slot_result_valid(I_image_slot_result_valid),
        .O_slot_result_ready(S_image_O_slot_result_ready),
        .I_slot_result_error(I_image_slot_result_error),
        .I_slot_result_op(I_image_slot_result_op),
        .I_slot_result_slot(I_image_slot_result_slot),
        .I_slot_result_owner(I_image_slot_result_owner),
        .I_slot_result_token(I_image_slot_result_token),
        .I_slot_result_generation(I_image_slot_result_generation),
        .O_busy(S_image_O_busy),
        .O_progress(S_image_O_progress),
        .O_done_valid(S_image_O_done_valid),
        .I_done_ready(I_image_done_ready || S_session_O_client_abort),
        .O_error(S_image_O_error),
        .O_context(S_image_O_context),
        .O_tag(S_image_O_tag),
        .O_generation(S_image_O_generation),
        .O_lease_token(S_image_O_lease_token),
        .O_slot(S_image_O_slot),
        .O_published(S_image_O_published),
        .O_slot_owned(S_image_O_slot_owned),
        .O_file_started(S_image_O_file_started),
        .O_transform_started(S_image_O_transform_started),
        .O_writer_started(S_image_O_writer_started),
        .O_file_source_error(S_image_O_file_source_error),
        .O_parser_error(S_image_O_parser_error),
        .O_storage_error(S_image_O_storage_error),
        .O_transform_error(S_image_O_transform_error),
        .O_writer_error(S_image_O_writer_error),
        .O_memory_error(S_image_O_memory_error),
        .O_file_error(S_image_O_file_error),
        .O_path_warning(S_image_O_path_warning),
        .O_file_size(S_image_O_file_size),
        .O_accepted_writes(S_image_O_accepted_writes),
        .O_retired_writes(S_image_O_retired_writes),
        .O_pixels(S_image_O_pixels),
        .O_response_discarded(S_image_O_response_discarded),
        .I_sector_budget(I_image_sector_budget),
        .I_path_length(I_image_path_length),
        .I_path_valid(I_image_path_valid),
        .O_path_ready(S_image_O_path_ready),
        .I_path_data(I_image_path_data),
        .I_path_last(I_image_path_last),
        .O_fs_open_valid(S_image_O_fs_open_valid),
        .I_fs_open_ready(S_files_O_client_open_ready[0]),
        .O_fs_open_context(S_image_O_fs_open_context),
        .O_fs_open_tag(S_image_O_fs_open_tag),
        .O_fs_path_length(S_image_O_fs_path_length),
        .O_fs_sector_budget(S_image_O_fs_sector_budget),
        .O_fs_path_valid(S_image_O_fs_path_valid),
        .I_fs_path_ready(S_files_O_client_path_ready[0]),
        .O_fs_path_data(S_image_O_fs_path_data),
        .O_fs_path_last(S_image_O_fs_path_last),
        .O_fs_open_cancel(S_image_O_fs_open_cancel),
        .I_fs_open_result_valid(S_files_O_client_open_result_valid[0]),
        .O_fs_open_result_ready(S_image_O_fs_open_result_ready),
        .I_fs_open_context(S_files_O_client_open_result[96:95]),
        .I_fs_open_tag(S_files_O_client_open_result[94:79]),
        .I_fs_open_generation(S_files_O_client_open_result[78:47]),
        .I_fs_open_size(S_files_O_client_open_result[46:15]),
        .I_fs_open_error(S_files_O_client_open_result[14:7]),
        .I_fs_open_storage_error(S_files_O_client_open_result[6:3]),
        .I_fs_open_warning(S_files_O_client_open_result[2:0]),
        .O_fs_read_valid(S_image_O_fs_read_valid),
        .I_fs_read_ready(S_files_O_client_read_ready[0]),
        .O_fs_read_context(S_image_O_fs_read_context),
        .O_fs_read_priority(S_image_O_fs_read_priority),
        .O_fs_offset(S_image_O_fs_offset),
        .O_fs_length(S_image_O_fs_length),
        .O_fs_epoch(S_image_O_fs_epoch),
        .I_fs_byte_valid(S_files_O_client_byte_valid[0]),
        .O_fs_byte_ready(S_image_O_fs_byte_ready),
        .I_fs_byte_data(S_files_O_client_byte[90:83]),
        .I_fs_byte_context(S_files_O_client_byte[82:81]),
        .I_fs_byte_epoch(S_files_O_client_byte[80:65]),
        .I_fs_byte_generation(S_files_O_client_byte[64:33]),
        .I_fs_byte_offset(S_files_O_client_byte[32:1]),
        .I_fs_byte_last(S_files_O_client_byte[0]),
        .I_fs_done_valid(S_files_O_client_done_valid[0]),
        .O_fs_done_ready(S_image_O_fs_done_ready),
        .I_fs_done_context(S_image_done[94:93]),
        .I_fs_done_epoch(S_image_done[92:77]),
        .I_fs_done_generation(S_image_done[76:45]),
        .I_fs_done_bytes(S_image_done[44:13]),
        .I_fs_done_eof(S_image_done[12]),
        .I_fs_done_error(S_image_done[11:4]),
        .I_fs_done_storage_error(S_image_done[3:0]),
        .O_fs_cancel_valid(S_image_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_files_O_client_cancel_ready[0]),
        .O_fs_cancel_context(S_image_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_image_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_files_O_client_cancel_done_valid[0]),
        .O_fs_cancel_done_ready(S_image_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_files_O_client_cancel_done[49:48]),
        .I_fs_cancel_done_epoch(S_files_O_client_cancel_done[47:32]),
        .I_fs_cancel_done_generation(S_files_O_client_cancel_done[31:0]),
        .O_fs_close_valid(S_image_O_fs_close_valid),
        .I_fs_close_ready(S_files_O_client_close_ready[0]),
        .O_fs_close_context(S_image_O_fs_close_context),
        .O_mem_valid(S_image_O_mem_valid),
        .I_mem_ready(I_image_mem_ready),
        .O_mem_wr(S_image_O_mem_wr),
        .O_mem_addr(S_image_O_mem_addr),
        .O_mem_data(S_image_O_mem_data),
        .O_mem_tag(S_image_O_mem_tag),
        .O_mem_mask(S_image_O_mem_mask),
        .O_mem_lease_token(S_image_O_mem_lease_token),
        .O_mem_generation(S_image_O_mem_generation),
        .I_mem_done_valid(I_image_mem_done_valid),
        .O_mem_done_ready(S_image_O_mem_done_ready),
        .I_mem_done_tag(I_image_mem_done_tag),
        .I_mem_done_lease_token(I_image_mem_done_lease_token),
        .I_mem_done_generation(I_image_mem_done_generation),
        .I_mem_done_error(I_image_mem_done_error),
        .I_rect_x(I_image_rect_x),
        .I_rect_y(I_image_rect_y),
        .I_rect_width(I_image_rect_width),
        .I_rect_height(I_image_rect_height),
        .I_bilinear(I_image_bilinear),
        .I_clear_rgba(I_image_clear_rgba),
        .I_slot_states(I_image_slot_states),
        .I_slot_layouts(I_image_slot_layouts),
        .I_slot_readers(I_image_slot_readers),
        .I_slot_tokens(I_image_slot_tokens),
        .I_slot_generations(I_image_slot_generations),
        .I_slot_assets(I_image_slot_assets),
        .I_slot_rotations(I_image_slot_rotations),
        .I_slot_resident(I_image_slot_resident),
        .I_slot_stale(I_image_slot_stale),
        .I_pinned_slots(I_image_pinned_slots),
        .I_mutating_slots(I_image_mutating_slots),
        .I_host_reservation(I_image_host_reservation),
        .O_evict_valid(S_image_O_evict_valid),
        .I_evict_ready(I_image_evict_ready),
        .O_evict_command(S_image_O_evict_command),
        .I_evict_result_valid(I_image_evict_result_valid),
        .O_evict_result_ready(S_image_O_evict_result_ready),
        .I_evict_result(I_image_evict_result),
        .O_loader_error(S_image_O_loader_error),
        .O_slot_error(S_image_O_slot_error),
        .O_loader_started(S_image_O_loader_started),
        .O_reused(S_image_O_reused),
        .O_evicted(S_image_O_evicted),
        .O_quarantined(S_image_O_quarantined),
        .O_stage_valid(S_image_O_stage_valid),
        .O_staged_slots(S_image_O_staged_slots),
        .I_stage_release_valid(I_image_stage_release_valid),
        .O_stage_release_ready(S_image_O_stage_release_ready),
        .I_stage_slot(I_image_stage_slot),
        .I_stage_token(I_image_stage_token),
        .I_stage_generation(I_image_stage_generation),
        .I_stage_discard(I_image_stage_discard),
        .O_frozen_request(S_image_O_frozen_request),
        .O_loader_lease_token(S_image_O_loader_lease_token)
    );
    media_index_scan u_scan (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_files_O_mounted),
        .I_media_generation(S_files_O_generation),
        .I_start_valid(S_session_O_scan_start_valid),
        .O_start_ready(S_scan_O_start_ready),
        .O_lease_request(S_scan_O_lease_request),
        .I_lease_grant(S_files_O_lease_grant[3]),
        .I_abort(I_scan_abort || S_session_O_scan_abort),
        .I_context(2'd0),
        .I_tag(S_session_O_scan_tag),
        .I_generation(S_session_O_scan_generation),
        .I_seed(I_scan_seed),
        .I_sector_budget(I_scan_sector_budget),
        .I_directory_sector_budget(I_scan_directory_sector_budget),
        .I_directory_duration(I_scan_directory_duration),
        .I_directory_transition_ms(I_scan_directory_transition_ms),
        .I_directory_transition(I_scan_directory_transition),
        .I_directory_order(I_scan_directory_order),
        .O_lease_active(S_scan_O_lease_active),
        .O_busy(S_scan_O_busy),
        .O_done_valid(S_scan_O_done_valid),
        .I_done_ready(S_session_O_scan_done_ready),
        .O_error(S_scan_O_error),
        .O_list_source_error(S_scan_O_list_source_error),
        .O_list_build_error(S_scan_O_list_build_error),
        .O_directory_build_error(S_scan_O_directory_build_error),
        .O_count(S_scan_O_count),
        .O_committed(S_scan_O_committed),
        .O_used_directory(S_scan_O_used_directory),
        .O_list_missing(S_scan_O_list_missing),
        .O_list_started(S_scan_O_list_started),
        .O_directory_started(S_scan_O_directory_started),
        .O_list_warning(S_scan_O_list_warning),
        .O_directory_warning(S_scan_O_directory_warning),
        .O_context(S_scan_O_context),
        .O_tag(S_scan_O_tag),
        .O_generation(S_scan_O_generation),
        .O_file_error(S_scan_O_file_error),
        .O_storage_error(S_scan_O_storage_error),
        .O_path_warning(S_scan_O_path_warning),
        .O_file_size(S_scan_O_file_size),
        .O_fs_open_valid(S_scan_O_fs_open_valid),
        .I_fs_open_ready(S_files_O_client_open_ready[3]),
        .O_fs_open_context(S_scan_O_fs_open_context),
        .O_fs_open_tag(S_scan_O_fs_open_tag),
        .O_fs_path_length(S_scan_O_fs_path_length),
        .O_fs_sector_budget(S_scan_O_fs_sector_budget),
        .O_fs_path_valid(S_scan_O_fs_path_valid),
        .I_fs_path_ready(S_files_O_client_path_ready[3]),
        .O_fs_path_data(S_scan_O_fs_path_data),
        .O_fs_path_last(S_scan_O_fs_path_last),
        .O_fs_open_cancel(S_scan_O_fs_open_cancel),
        .I_fs_open_result_valid(S_files_O_client_open_result_valid[3]),
        .O_fs_open_result_ready(S_scan_O_fs_open_result_ready),
        .I_fs_open_context(S_files_O_client_open_result[96:95]),
        .I_fs_open_tag(S_files_O_client_open_result[94:79]),
        .I_fs_open_generation(S_files_O_client_open_result[78:47]),
        .I_fs_open_size(S_files_O_client_open_result[46:15]),
        .I_fs_open_error(S_files_O_client_open_result[14:7]),
        .I_fs_open_storage_error(S_files_O_client_open_result[6:3]),
        .I_fs_open_warning(S_files_O_client_open_result[2:0]),
        .O_fs_read_valid(S_scan_O_fs_read_valid),
        .I_fs_read_ready(S_files_O_client_read_ready[3]),
        .O_fs_read_context(S_scan_O_fs_read_context),
        .O_fs_read_priority(S_scan_O_fs_read_priority),
        .O_fs_offset(S_scan_O_fs_offset),
        .O_fs_length(S_scan_O_fs_length),
        .O_fs_epoch(S_scan_O_fs_epoch),
        .I_fs_byte_valid(S_files_O_client_byte_valid[3]),
        .O_fs_byte_ready(S_scan_O_fs_byte_ready),
        .I_fs_byte_data(S_files_O_client_byte[90:83]),
        .I_fs_byte_context(S_files_O_client_byte[82:81]),
        .I_fs_byte_epoch(S_files_O_client_byte[80:65]),
        .I_fs_byte_generation(S_files_O_client_byte[64:33]),
        .I_fs_byte_offset(S_files_O_client_byte[32:1]),
        .I_fs_byte_last(S_files_O_client_byte[0]),
        .I_fs_done_valid(S_files_O_client_done_valid[3]),
        .O_fs_done_ready(S_scan_O_fs_done_ready),
        .I_fs_done_context(S_scan_done[94:93]),
        .I_fs_done_epoch(S_scan_done[92:77]),
        .I_fs_done_generation(S_scan_done[76:45]),
        .I_fs_done_bytes(S_scan_done[44:13]),
        .I_fs_done_eof(S_scan_done[12]),
        .I_fs_done_error(S_scan_done[11:4]),
        .I_fs_done_storage_error(S_scan_done[3:0]),
        .O_fs_cancel_valid(S_scan_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_files_O_client_cancel_ready[3]),
        .O_fs_cancel_context(S_scan_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_scan_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_files_O_client_cancel_done_valid[3]),
        .O_fs_cancel_done_ready(S_scan_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_files_O_client_cancel_done[49:48]),
        .I_fs_cancel_done_epoch(S_files_O_client_cancel_done[47:32]),
        .I_fs_cancel_done_generation(S_files_O_client_cancel_done[31:0]),
        .O_fs_close_valid(S_scan_O_fs_close_valid),
        .I_fs_close_ready(S_files_O_client_close_ready[3]),
        .O_fs_close_context(S_scan_O_fs_close_context),
        .O_active_valid(S_scan_O_active_valid),
        .O_active_count(S_scan_O_active_count),
        .O_active_generation(S_scan_O_active_generation),
        .O_active_revision(S_scan_O_active_revision),
        .I_acquire_valid(I_scan_acquire_valid),
        .O_acquire_ready(S_scan_O_acquire_ready),
        .O_snapshot_valid(S_scan_O_snapshot_valid),
        .O_snapshot_count(S_scan_O_snapshot_count),
        .O_snapshot_generation(S_scan_O_snapshot_generation),
        .O_snapshot_revision(S_scan_O_snapshot_revision),
        .I_release_valid(I_scan_release_valid),
        .O_release_ready(S_scan_O_release_ready),
        .I_read_valid(I_scan_read_valid),
        .O_read_ready(S_scan_O_read_ready),
        .I_read_index(I_scan_read_index),
        .I_read_kind(I_scan_read_kind),
        .I_read_address(I_scan_read_address),
        .I_read_tag(I_scan_read_tag),
        .O_read_result_valid(S_scan_O_read_result_valid),
        .I_read_result_ready(I_scan_read_result_ready),
        .O_read_file_length(S_scan_O_read_file_length),
        .O_read_audio_length(S_scan_O_read_audio_length),
        .O_read_title_length(S_scan_O_read_title_length),
        .O_read_duration(S_scan_O_read_duration),
        .O_read_transition_ms(S_scan_O_read_transition_ms),
        .O_read_transition(S_scan_O_read_transition),
        .O_read_policy(S_scan_O_read_policy),
        .O_read_data(S_scan_O_read_data),
        .O_read_tag(S_scan_O_read_tag),
        .O_read_error(S_scan_O_read_error),
        .O_directory_error(S_scan_O_directory_error),
        .O_directory_primary_error(S_scan_O_directory_primary_error),
        .O_directory_storage_error(S_scan_O_directory_storage_error),
        .O_enum_warning(S_scan_O_enum_warning),
        .O_directory_sectors(S_scan_O_directory_sectors),
        .O_enum_valid(S_scan_O_enum_valid),
        .I_enum_ready(S_files_O_scan_ready),
        .O_enum_tag(S_scan_O_enum_tag),
        .O_enum_path_length(S_scan_O_enum_path_length),
        .O_enum_sector_budget(S_scan_O_enum_sector_budget),
        .O_enum_path_valid(S_scan_O_enum_path_valid),
        .I_enum_path_ready(S_files_O_scan_path_ready),
        .O_enum_path_data(S_scan_O_enum_path_data),
        .O_enum_path_last(S_scan_O_enum_path_last),
        .O_enum_stop(S_scan_O_enum_stop),
        .O_enum_cancel(S_scan_O_enum_cancel),
        .I_enum_entry_valid(S_files_O_scan_entry_valid),
        .O_enum_entry_ready(S_scan_O_enum_entry_ready),
        .I_enum_attr(S_files_O_scan_attr),
        .I_enum_size(S_files_O_scan_size),
        .I_enum_first_cluster(S_files_O_scan_first_cluster),
        .I_enum_name_length(S_files_O_scan_name_length),
        .I_enum_name_valid(S_files_O_scan_name_valid),
        .O_enum_name_ready(S_scan_O_enum_name_ready),
        .I_enum_name_data(S_files_O_scan_name_data),
        .I_enum_name_last(S_files_O_scan_name_last),
        .I_enum_done_valid(S_files_O_scan_done_valid),
        .O_enum_done_ready(S_scan_O_enum_done_ready),
        .I_enum_tag(S_files_O_scan_tag),
        .I_enum_generation(S_files_O_scan_generation),
        .I_enum_sectors(S_files_O_scan_sectors),
        .I_enum_error(S_files_O_scan_error),
        .I_enum_storage_error(S_files_O_scan_storage_error),
        .I_enum_warning(S_files_O_scan_warning),
        .O_active_order(S_scan_O_active_order),
        .O_active_base_order(S_scan_O_active_base_order),
        .O_active_base_order_explicit(S_scan_O_active_base_order_explicit),
        .I_reorder_valid(I_scan_reorder_valid),
        .O_reorder_ready(S_scan_O_reorder_ready),
        .I_reorder_order(I_scan_reorder_order),
        .I_reorder_seed(I_scan_reorder_seed),
        .I_reorder_generation(I_scan_reorder_generation),
        .I_reorder_tag(I_scan_reorder_tag),
        .I_reorder_current_index(I_scan_reorder_current_index),
        .I_reorder_abort(I_scan_reorder_abort),
        .O_reorder_done_valid(S_scan_O_reorder_done_valid),
        .I_reorder_done_ready(I_scan_reorder_done_ready),
        .O_reorder_error(S_scan_O_reorder_error),
        .O_reorder_tag(S_scan_O_reorder_tag),
        .O_reorder_generation(S_scan_O_reorder_generation),
        .O_reorder_revision(S_scan_O_reorder_revision),
        .O_reorder_current_index(S_scan_O_reorder_current_index),
        .I_order_override(I_scan_order_override),
        .I_runtime_order(I_scan_runtime_order)
    );
    wav_file_source u_a (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_files_O_mounted),
        .I_media_generation(S_files_O_generation),
        .I_start_valid(I_audio_file_start_valid[0] && S_session_O_allow_start),
        .O_start_ready(S_a_O_start_ready),
        .O_lease_request(S_a_O_lease_request),
        .I_lease_grant(S_files_O_lease_grant[1]),
        .I_context(2'd1),
        .I_read_priority(2'd2),
        .I_tag(I_audio_file_tag[0+:16]),
        .I_generation(I_audio_file_generation[0+:32]),
        .I_sector_budget(I_audio_file_sector_budget[0+:32]),
        .I_start_index(I_audio_file_start_index[0+:32]),
        .I_path_length(I_audio_file_path_length[0+:7]),
        .I_path_valid(I_audio_file_path_valid[0+:1]),
        .O_path_ready(S_a_O_path_ready),
        .I_path_data(I_audio_file_path_data[0+:8]),
        .I_path_last(I_audio_file_path_last[0+:1]),
        .I_abort(I_audio_file_abort[0] || S_session_O_client_abort),
        .O_lease_active(S_a_O_lease_active),
        .O_busy(S_a_O_busy),
        .O_done_valid(S_a_O_done_valid),
        .I_done_ready(I_audio_file_done_ready[0] || S_session_O_client_abort),
        .O_error(S_a_O_error),
        .O_file_error(S_a_O_file_error),
        .O_storage_error(S_a_O_storage_error),
        .O_path_warning(S_a_O_path_warning),
        .O_context(S_a_O_context),
        .O_tag(S_a_O_tag),
        .O_generation(S_a_O_generation),
        .O_file_size(S_a_O_file_size),
        .O_track_started(S_a_O_track_started),
        .O_track_start_valid(S_a_O_track_start_valid),
        .I_track_start_ready(S_player_O_start_ready[0] && S_player_O_available[0]),
        .O_track_file_size(S_a_O_track_file_size),
        .O_track_start_index(S_a_O_track_start_index),
        .O_track_epoch(S_a_O_track_epoch),
        .O_track_byte_valid(S_a_O_track_byte_valid),
        .I_track_byte_ready(S_player_O_byte_ready[0]),
        .O_track_byte_data(S_a_O_track_byte_data),
        .O_track_byte_last(S_a_O_track_byte_last),
        .O_track_byte_epoch(S_a_O_track_byte_epoch),
        .O_track_stream_error(S_a_O_track_stream_error),
        .O_track_stream_error_epoch(S_a_O_track_stream_error_epoch),
        .I_track_cancel_valid(S_player_O_cancel_valid[0]),
        .O_track_cancel_ready(S_a_O_track_cancel_ready),
        .I_track_cancel_epoch(S_player_O_cancel_epoch[0+:16]),
        .I_io_retire_request(S_player_O_io_retire_request[0]),
        .O_io_retired(S_a_O_io_retired),
        .O_fs_open_valid(S_a_O_fs_open_valid),
        .I_fs_open_ready(S_files_O_client_open_ready[1]),
        .O_fs_open_context(S_a_O_fs_open_context),
        .O_fs_open_tag(S_a_O_fs_open_tag),
        .O_fs_path_length(S_a_O_fs_path_length),
        .O_fs_sector_budget(S_a_O_fs_sector_budget),
        .O_fs_path_valid(S_a_O_fs_path_valid),
        .I_fs_path_ready(S_files_O_client_path_ready[1]),
        .O_fs_path_data(S_a_O_fs_path_data),
        .O_fs_path_last(S_a_O_fs_path_last),
        .O_fs_open_cancel(S_a_O_fs_open_cancel),
        .I_fs_open_result_valid(S_files_O_client_open_result_valid[1]),
        .O_fs_open_result_ready(S_a_O_fs_open_result_ready),
        .I_fs_open_context(S_files_O_client_open_result[96:95]),
        .I_fs_open_tag(S_files_O_client_open_result[94:79]),
        .I_fs_open_generation(S_files_O_client_open_result[78:47]),
        .I_fs_open_size(S_files_O_client_open_result[46:15]),
        .I_fs_open_error(S_files_O_client_open_result[14:7]),
        .I_fs_open_storage_error(S_files_O_client_open_result[6:3]),
        .I_fs_open_warning(S_files_O_client_open_result[2:0]),
        .O_fs_read_valid(S_a_O_fs_read_valid),
        .I_fs_read_ready(S_files_O_client_read_ready[1]),
        .O_fs_read_context(S_a_O_fs_read_context),
        .O_fs_read_priority(S_a_O_fs_read_priority),
        .O_fs_offset(S_a_O_fs_offset),
        .O_fs_length(S_a_O_fs_length),
        .O_fs_epoch(S_a_O_fs_epoch),
        .I_fs_byte_valid(S_files_O_client_byte_valid[1]),
        .O_fs_byte_ready(S_a_O_fs_byte_ready),
        .I_fs_byte_data(S_files_O_client_byte[90:83]),
        .I_fs_byte_context(S_files_O_client_byte[82:81]),
        .I_fs_byte_epoch(S_files_O_client_byte[80:65]),
        .I_fs_byte_generation(S_files_O_client_byte[64:33]),
        .I_fs_byte_offset(S_files_O_client_byte[32:1]),
        .I_fs_byte_last(S_files_O_client_byte[0]),
        .I_fs_done_valid(S_files_O_client_done_valid[1]),
        .O_fs_done_ready(S_a_O_fs_done_ready),
        .I_fs_done_context(S_a_done[94:93]),
        .I_fs_done_epoch(S_a_done[92:77]),
        .I_fs_done_generation(S_a_done[76:45]),
        .I_fs_done_bytes(S_a_done[44:13]),
        .I_fs_done_eof(S_a_done[12]),
        .I_fs_done_error(S_a_done[11:4]),
        .I_fs_done_storage_error(S_a_done[3:0]),
        .O_fs_cancel_valid(S_a_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_files_O_client_cancel_ready[1]),
        .O_fs_cancel_context(S_a_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_a_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_files_O_client_cancel_done_valid[1]),
        .O_fs_cancel_done_ready(S_a_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_files_O_client_cancel_done[49:48]),
        .I_fs_cancel_done_epoch(S_files_O_client_cancel_done[47:32]),
        .I_fs_cancel_done_generation(S_files_O_client_cancel_done[31:0]),
        .O_fs_close_valid(S_a_O_fs_close_valid),
        .I_fs_close_ready(S_files_O_client_close_ready[1]),
        .O_fs_close_context(S_a_O_fs_close_context)
    );
    wav_file_source u_b (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_files_O_mounted),
        .I_media_generation(S_files_O_generation),
        .I_start_valid(I_audio_file_start_valid[1] && S_session_O_allow_start),
        .O_start_ready(S_b_O_start_ready),
        .O_lease_request(S_b_O_lease_request),
        .I_lease_grant(S_files_O_lease_grant[2]),
        .I_context(2'd2),
        .I_read_priority(2'd2),
        .I_tag(I_audio_file_tag[16+:16]),
        .I_generation(I_audio_file_generation[32+:32]),
        .I_sector_budget(I_audio_file_sector_budget[32+:32]),
        .I_start_index(I_audio_file_start_index[32+:32]),
        .I_path_length(I_audio_file_path_length[7+:7]),
        .I_path_valid(I_audio_file_path_valid[1+:1]),
        .O_path_ready(S_b_O_path_ready),
        .I_path_data(I_audio_file_path_data[8+:8]),
        .I_path_last(I_audio_file_path_last[1+:1]),
        .I_abort(I_audio_file_abort[1] || S_session_O_client_abort),
        .O_lease_active(S_b_O_lease_active),
        .O_busy(S_b_O_busy),
        .O_done_valid(S_b_O_done_valid),
        .I_done_ready(I_audio_file_done_ready[1] || S_session_O_client_abort),
        .O_error(S_b_O_error),
        .O_file_error(S_b_O_file_error),
        .O_storage_error(S_b_O_storage_error),
        .O_path_warning(S_b_O_path_warning),
        .O_context(S_b_O_context),
        .O_tag(S_b_O_tag),
        .O_generation(S_b_O_generation),
        .O_file_size(S_b_O_file_size),
        .O_track_started(S_b_O_track_started),
        .O_track_start_valid(S_b_O_track_start_valid),
        .I_track_start_ready(S_player_O_start_ready[1] && S_player_O_available[1]),
        .O_track_file_size(S_b_O_track_file_size),
        .O_track_start_index(S_b_O_track_start_index),
        .O_track_epoch(S_b_O_track_epoch),
        .O_track_byte_valid(S_b_O_track_byte_valid),
        .I_track_byte_ready(S_player_O_byte_ready[1]),
        .O_track_byte_data(S_b_O_track_byte_data),
        .O_track_byte_last(S_b_O_track_byte_last),
        .O_track_byte_epoch(S_b_O_track_byte_epoch),
        .O_track_stream_error(S_b_O_track_stream_error),
        .O_track_stream_error_epoch(S_b_O_track_stream_error_epoch),
        .I_track_cancel_valid(S_player_O_cancel_valid[1]),
        .O_track_cancel_ready(S_b_O_track_cancel_ready),
        .I_track_cancel_epoch(S_player_O_cancel_epoch[16+:16]),
        .I_io_retire_request(S_player_O_io_retire_request[1]),
        .O_io_retired(S_b_O_io_retired),
        .O_fs_open_valid(S_b_O_fs_open_valid),
        .I_fs_open_ready(S_files_O_client_open_ready[2]),
        .O_fs_open_context(S_b_O_fs_open_context),
        .O_fs_open_tag(S_b_O_fs_open_tag),
        .O_fs_path_length(S_b_O_fs_path_length),
        .O_fs_sector_budget(S_b_O_fs_sector_budget),
        .O_fs_path_valid(S_b_O_fs_path_valid),
        .I_fs_path_ready(S_files_O_client_path_ready[2]),
        .O_fs_path_data(S_b_O_fs_path_data),
        .O_fs_path_last(S_b_O_fs_path_last),
        .O_fs_open_cancel(S_b_O_fs_open_cancel),
        .I_fs_open_result_valid(S_files_O_client_open_result_valid[2]),
        .O_fs_open_result_ready(S_b_O_fs_open_result_ready),
        .I_fs_open_context(S_files_O_client_open_result[96:95]),
        .I_fs_open_tag(S_files_O_client_open_result[94:79]),
        .I_fs_open_generation(S_files_O_client_open_result[78:47]),
        .I_fs_open_size(S_files_O_client_open_result[46:15]),
        .I_fs_open_error(S_files_O_client_open_result[14:7]),
        .I_fs_open_storage_error(S_files_O_client_open_result[6:3]),
        .I_fs_open_warning(S_files_O_client_open_result[2:0]),
        .O_fs_read_valid(S_b_O_fs_read_valid),
        .I_fs_read_ready(S_files_O_client_read_ready[2]),
        .O_fs_read_context(S_b_O_fs_read_context),
        .O_fs_read_priority(S_b_O_fs_read_priority),
        .O_fs_offset(S_b_O_fs_offset),
        .O_fs_length(S_b_O_fs_length),
        .O_fs_epoch(S_b_O_fs_epoch),
        .I_fs_byte_valid(S_files_O_client_byte_valid[2]),
        .O_fs_byte_ready(S_b_O_fs_byte_ready),
        .I_fs_byte_data(S_files_O_client_byte[90:83]),
        .I_fs_byte_context(S_files_O_client_byte[82:81]),
        .I_fs_byte_epoch(S_files_O_client_byte[80:65]),
        .I_fs_byte_generation(S_files_O_client_byte[64:33]),
        .I_fs_byte_offset(S_files_O_client_byte[32:1]),
        .I_fs_byte_last(S_files_O_client_byte[0]),
        .I_fs_done_valid(S_files_O_client_done_valid[2]),
        .O_fs_done_ready(S_b_O_fs_done_ready),
        .I_fs_done_context(S_b_done[94:93]),
        .I_fs_done_epoch(S_b_done[92:77]),
        .I_fs_done_generation(S_b_done[76:45]),
        .I_fs_done_bytes(S_b_done[44:13]),
        .I_fs_done_eof(S_b_done[12]),
        .I_fs_done_error(S_b_done[11:4]),
        .I_fs_done_storage_error(S_b_done[3:0]),
        .O_fs_cancel_valid(S_b_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_files_O_client_cancel_ready[2]),
        .O_fs_cancel_context(S_b_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_b_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_files_O_client_cancel_done_valid[2]),
        .O_fs_cancel_done_ready(S_b_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_files_O_client_cancel_done[49:48]),
        .I_fs_cancel_done_epoch(S_files_O_client_cancel_done[47:32]),
        .I_fs_cancel_done_generation(S_files_O_client_cancel_done[31:0]),
        .O_fs_close_valid(S_b_O_fs_close_valid),
        .I_fs_close_ready(S_files_O_client_close_ready[2]),
        .O_fs_close_context(S_b_O_fs_close_context)
    );
    wav_audio_prepared u_player (
        .I_decode_clk(I_host_clk),
        .I_audio_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_start_valid({S_b_O_track_start_valid && S_player_O_available[1],S_a_O_track_start_valid && S_player_O_available[0]}),
        .O_start_ready(S_player_O_start_ready),
        .I_file_size({S_b_O_track_file_size,S_a_O_track_file_size}),
        .I_start_index({S_b_O_track_start_index,S_a_O_track_start_index}),
        .I_epoch({S_b_O_track_epoch,S_a_O_track_epoch}),
        .I_byte_valid({S_b_O_track_byte_valid,S_a_O_track_byte_valid}),
        .I_byte_last({S_b_O_track_byte_last,S_a_O_track_byte_last}),
        .I_byte_data({S_b_O_track_byte_data,S_a_O_track_byte_data}),
        .I_byte_epoch({S_b_O_track_byte_epoch,S_a_O_track_byte_epoch}),
        .O_byte_ready(S_player_O_byte_ready),
        .O_byte_discarded(S_player_O_byte_discarded),
        .I_stream_error_valid({S_b_O_track_stream_error,S_a_O_track_stream_error}),
        .I_stream_error_epoch({S_b_O_track_stream_error_epoch,S_a_O_track_stream_error_epoch}),
        .I_recycle_valid(I_audio_recycle_valid | S_auto_recycle),
        .O_recycle_ready(S_player_O_recycle_ready),
        .O_recycle_done(S_player_O_recycle_done),
        .O_available(S_player_O_available),
        .O_cancel_valid(S_player_O_cancel_valid),
        .I_cancel_ready({S_b_O_track_cancel_ready,S_a_O_track_cancel_ready}),
        .O_cancel_epoch(S_player_O_cancel_epoch),
        .O_io_retire_request(S_player_O_io_retire_request),
        .I_io_retired({S_b_O_io_retired,S_a_O_io_retired}),
        .O_source_busy(S_player_O_source_busy),
        .O_written_frames(S_player_O_written_frames),
        .I_sample_tick(O_sample_tick),
        .I_play_valid(I_audio_play_valid && !S_session_abort_video),
        .O_play_ready(S_player_O_play_ready),
        .I_fade_valid(I_audio_fade_valid && !S_session_abort_video),
        .I_target_b(I_audio_target_b),
        .O_fade_ready(S_player_O_fade_ready),
        .I_silence_valid(I_audio_silence_valid && !S_session_abort_video),
        .O_silence_ready(S_player_O_silence_ready),
        .O_silence_started(S_player_O_silence_started),
        .O_silence_done(S_player_O_silence_done),
        .I_pause(I_audio_pause),
        .I_pause_allow(I_audio_pause_allow),
        .O_paused(S_player_O_paused),
        .O_pause_busy(S_player_O_pause_busy),
        .I_volume(I_audio_volume),
        .I_mute(I_audio_mute),
        .I_prompt_valid(I_audio_prompt_valid),
        .I_prompt_left(I_audio_prompt_left),
        .I_prompt_right(I_audio_prompt_right),
        .O_sample_valid(S_player_O_sample_valid),
        .O_left(S_player_O_left),
        .O_right(S_player_O_right),
        .O_clipped(S_player_O_clipped),
        .O_fade_done(S_player_O_fade_done),
        .O_active_b(S_player_O_active_b),
        .O_busy(S_player_O_busy),
        .O_started(S_player_O_started),
        .O_loaded(S_player_O_loaded),
        .O_enabled(S_player_O_enabled),
        .O_end(S_player_O_end),
        .O_consumed(S_player_O_consumed),
        .O_underrun(S_player_O_underrun),
        .O_release(S_player_O_release),
        .O_next_index(S_player_O_next_index),
        .O_need_fill(S_player_O_need_fill),
        .O_failed(S_player_O_failed),
        .O_slot_stopping(S_player_O_slot_stopping),
        .O_event_valid(S_player_O_event_valid),
        .I_event_ready(I_audio_event_ready | S_abort_event_ready),
        .O_event_header(S_player_O_event_header),
        .O_event_epoch(S_player_O_event_epoch),
        .O_event_total_frames(S_player_O_event_total_frames),
        .O_event_written_frames(S_player_O_event_written_frames),
        .O_event_error(S_player_O_event_error),
        .I_bind_valid(I_audio_bind_valid),
        .O_bind_ready(S_player_O_bind_ready),
        .I_bind_display_epoch(I_audio_bind_display_epoch),
        .I_bind_display_tag(I_audio_bind_display_tag),
        .I_bind_slot(I_audio_bind_slot),
        .I_bind_track_epoch(I_audio_bind_track_epoch),
        .I_bind_track_serial(I_audio_bind_track_serial),
        .I_bind_start_index(I_audio_bind_start_index),
        .I_bind_reuse_active(I_audio_bind_reuse_active),
        .I_unbind(I_audio_unbind || S_session_abort_video),
        .I_bind_abort(I_audio_bind_abort || S_session_abort_video),
        .I_pending_valid(I_audio_pending_valid),
        .I_pending_epoch(I_audio_pending_epoch),
        .I_pending_tag(I_audio_pending_tag),
        .I_display_audio_applied(I_audio_display_audio_applied),
        .O_audio_ready(S_player_O_audio_ready),
        .O_audio_epoch(S_player_O_audio_epoch),
        .O_track_known(S_player_O_track_known),
        .O_track_epochs(S_player_O_track_epochs),
        .O_track_serials(S_player_O_track_serials),
        .O_track_totals(S_player_O_track_totals),
        .O_bound(S_player_O_bound),
        .O_binding_revoked(S_player_O_binding_revoked),
        .O_bind_error(S_player_O_bind_error),
        .O_audio_accepted(S_player_O_audio_accepted),
        .O_audio_accepted_epoch(S_player_O_audio_accepted_epoch),
        .O_audio_accepted_tag(S_player_O_audio_accepted_tag),
        .O_prepare_contract_fault(S_player_O_prepare_contract_fault),
        .O_prepare_quarantined(S_player_O_prepare_quarantined),
        .O_prepare_response_discarded(S_player_O_prepare_response_discarded)
    );
    media_storage u_files (
        .I_demo(I_storage_demo),
        .I_recovery(I_storage_recovery),
        .O_demo_active(S_files_O_demo_active),
        .O_demo_ready(S_files_O_demo_ready),
        .O_recovery_active(S_files_O_recovery_active),
        .O_demo_error(S_files_O_demo_error),
        .O_flash_valid(S_files_O_flash_valid),
        .I_flash_ready(I_storage_flash_ready),
        .O_flash_address(S_files_O_flash_address),
        .O_flash_length(S_files_O_flash_length),
        .O_flash_tag(S_files_O_flash_tag),
        .I_flash_read_valid(I_storage_flash_read_valid),
        .O_flash_read_ready(S_files_O_flash_read_ready),
        .I_flash_read_data(I_storage_flash_read_data),
        .I_flash_read_last(I_storage_flash_read_last),
        .I_flash_done_valid(I_storage_flash_done_valid),
        .O_flash_done_ready(S_files_O_flash_done_ready),
        .I_flash_error(I_storage_flash_error),
        .I_flash_tag(I_storage_flash_tag),
        .I_lease_request({S_scan_O_lease_request,S_b_O_lease_request,S_a_O_lease_request,S_image_O_lease_request}),
        .I_lease_active({S_scan_O_lease_active,S_b_O_lease_active,S_a_O_lease_active,S_image_O_lease_active}),
        .I_lease_context({2'd0,2'd2,2'd1,2'd0}),
        .O_lease_grant(S_files_O_lease_grant),
        .I_client_open_valid({S_scan_O_fs_open_valid,S_b_O_fs_open_valid,S_a_O_fs_open_valid,S_image_O_fs_open_valid}),
        .O_client_open_ready(S_files_O_client_open_ready),
        .I_client_open({S_scan_O_fs_open_context,S_scan_O_fs_open_tag,S_scan_O_fs_path_length,S_scan_O_fs_sector_budget,S_b_O_fs_open_context,S_b_O_fs_open_tag,S_b_O_fs_path_length,S_b_O_fs_sector_budget,S_a_O_fs_open_context,S_a_O_fs_open_tag,S_a_O_fs_path_length,S_a_O_fs_sector_budget,S_image_O_fs_open_context,S_image_O_fs_open_tag,S_image_O_fs_path_length,S_image_O_fs_sector_budget}),
        .I_client_path_valid({S_scan_O_fs_path_valid,S_b_O_fs_path_valid,S_a_O_fs_path_valid,S_image_O_fs_path_valid}),
        .O_client_path_ready(S_files_O_client_path_ready),
        .I_client_path_data({S_scan_O_fs_path_data,S_b_O_fs_path_data,S_a_O_fs_path_data,S_image_O_fs_path_data}),
        .I_client_path_last({S_scan_O_fs_path_last,S_b_O_fs_path_last,S_a_O_fs_path_last,S_image_O_fs_path_last}),
        .I_client_open_cancel({S_scan_O_fs_open_cancel,S_b_O_fs_open_cancel,S_a_O_fs_open_cancel,S_image_O_fs_open_cancel}),
        .O_client_open_result_valid(S_files_O_client_open_result_valid),
        .I_client_open_result_ready({S_scan_O_fs_open_result_ready,S_b_O_fs_open_result_ready,S_a_O_fs_open_result_ready,S_image_O_fs_open_result_ready}),
        .O_client_open_result(S_files_O_client_open_result),
        .I_client_read_valid({S_scan_O_fs_read_valid,S_b_O_fs_read_valid,S_a_O_fs_read_valid,S_image_O_fs_read_valid}),
        .O_client_read_ready(S_files_O_client_read_ready),
        .I_client_read({S_scan_O_fs_read_context,S_scan_O_fs_read_priority,S_scan_O_fs_offset,S_scan_O_fs_length,S_scan_O_fs_epoch,S_b_O_fs_read_context,S_b_O_fs_read_priority,S_b_O_fs_offset,S_b_O_fs_length,S_b_O_fs_epoch,S_a_O_fs_read_context,S_a_O_fs_read_priority,S_a_O_fs_offset,S_a_O_fs_length,S_a_O_fs_epoch,S_image_O_fs_read_context,S_image_O_fs_read_priority,S_image_O_fs_offset,S_image_O_fs_length,S_image_O_fs_epoch}),
        .O_client_byte_valid(S_files_O_client_byte_valid),
        .I_client_byte_ready({S_scan_O_fs_byte_ready,S_b_O_fs_byte_ready,S_a_O_fs_byte_ready,S_image_O_fs_byte_ready}),
        .O_client_byte(S_files_O_client_byte),
        .O_client_done_valid(S_files_O_client_done_valid),
        .I_client_done_ready({S_scan_O_fs_done_ready,S_b_O_fs_done_ready,S_a_O_fs_done_ready,S_image_O_fs_done_ready}),
        .O_client_done(S_files_O_client_done),
        .I_client_cancel_valid({S_scan_O_fs_cancel_valid,S_b_O_fs_cancel_valid,S_a_O_fs_cancel_valid,S_image_O_fs_cancel_valid}),
        .O_client_cancel_ready(S_files_O_client_cancel_ready),
        .I_client_cancel({S_scan_O_fs_cancel_context,S_scan_O_fs_cancel_epoch,S_b_O_fs_cancel_context,S_b_O_fs_cancel_epoch,S_a_O_fs_cancel_context,S_a_O_fs_cancel_epoch,S_image_O_fs_cancel_context,S_image_O_fs_cancel_epoch}),
        .O_client_cancel_done_valid(S_files_O_client_cancel_done_valid),
        .I_client_cancel_done_ready({S_scan_O_fs_cancel_done_ready,S_b_O_fs_cancel_done_ready,S_a_O_fs_cancel_done_ready,S_image_O_fs_cancel_done_ready}),
        .O_client_cancel_done(S_files_O_client_cancel_done),
        .I_client_close_valid({S_scan_O_fs_close_valid,S_b_O_fs_close_valid,S_a_O_fs_close_valid,S_image_O_fs_close_valid}),
        .O_client_close_ready(S_files_O_client_close_ready),
        .I_client_close_context({S_scan_O_fs_close_context,S_b_O_fs_close_context,S_a_O_fs_close_context,S_image_O_fs_close_context}),
        .I_client_urgent({1'b0,S_need_host[1],S_need_host[0],1'b0}),
        .O_busy(S_files_O_busy),
        .O_quiescent(S_files_O_quiescent),
        .O_leased_contexts(S_files_O_leased_contexts),
        .O_descriptors(S_files_O_descriptors),
        .O_pending_reads(S_files_O_pending_reads),
        .O_contract_fault(S_files_O_contract_fault),
        .O_response_discarded(S_files_O_response_discarded),
        .I_scan_valid(S_scan_O_enum_valid),
        .O_scan_ready(S_files_O_scan_ready),
        .I_scan_tag(S_scan_O_enum_tag),
        .I_scan_path_length(S_scan_O_enum_path_length),
        .I_scan_sector_budget(S_scan_O_enum_sector_budget),
        .I_scan_path_valid(S_scan_O_enum_path_valid),
        .O_scan_path_ready(S_files_O_scan_path_ready),
        .I_scan_path_data(S_scan_O_enum_path_data),
        .I_scan_path_last(S_scan_O_enum_path_last),
        .I_scan_stop(S_scan_O_enum_stop),
        .I_scan_cancel(S_scan_O_enum_cancel),
        .O_scan_entry_valid(S_files_O_scan_entry_valid),
        .I_scan_entry_ready(S_scan_O_enum_entry_ready),
        .O_scan_attr(S_files_O_scan_attr),
        .O_scan_size(S_files_O_scan_size),
        .O_scan_first_cluster(S_files_O_scan_first_cluster),
        .O_scan_alias(S_files_O_scan_alias),
        .O_scan_name_length(S_files_O_scan_name_length),
        .O_scan_is_lfn(S_files_O_scan_is_lfn),
        .O_scan_name_valid(S_files_O_scan_name_valid),
        .I_scan_name_ready(S_scan_O_enum_name_ready),
        .O_scan_name_data(S_files_O_scan_name_data),
        .O_scan_name_last(S_files_O_scan_name_last),
        .O_scan_done_valid(S_files_O_scan_done_valid),
        .I_scan_done_ready(S_scan_O_enum_done_ready),
        .O_scan_tag(S_files_O_scan_tag),
        .O_scan_generation(S_files_O_scan_generation),
        .O_scan_sectors(S_files_O_scan_sectors),
        .O_scan_warning(S_files_O_scan_warning),
        .O_scan_error(S_files_O_scan_error),
        .O_scan_storage_error(S_files_O_scan_storage_error),
        .I_unmount(S_session_O_unmount),
        .I_mount_valid(S_session_O_mount_valid),
        .O_mount_ready(S_files_O_mount_ready),
        .O_mount_result_valid(S_files_O_mount_result_valid),
        .I_mount_result_ready(S_session_O_mount_result_ready),
        .O_mount_error(S_files_O_mount_error),
        .O_mount_storage_error(S_files_O_mount_storage_error),
        .O_mount_generation(S_files_O_mount_generation),
        .O_mounted(S_files_O_mounted),
        .O_generation(S_files_O_generation),
        .I_host_clk(I_host_clk),
        .I_sd_clk(I_sd_clk),
        .I_async_reset(I_async_reset),
        .O_card_ready(S_files_O_card_ready),
        .O_card_present(S_files_O_card_present),
        .O_capacity_sectors(S_files_O_capacity_sectors),
        .O_sd_high_capacity(S_files_O_sd_high_capacity),
        .O_sd_card_error(S_files_O_sd_card_error),
        .O_sd_ncs(S_files_O_sd_ncs),
        .O_sd_sclk(S_files_O_sd_sclk),
        .O_sd_mosi(S_files_O_sd_mosi),
        .I_sd_miso(I_storage_sd_miso)
    );
    media_session_ctrl u_session (
        .I_clk(I_host_clk),
        .I_reset(S_host_reset),
        .I_enable(I_session_enable),
        .I_reload(I_session_reload),
        .I_rescan(I_session_rescan),
        .I_card_ready(S_files_O_card_ready),
        .I_storage_quiescent(S_files_O_quiescent),
        .I_mounted(S_files_O_mounted),
        .I_generation(S_files_O_generation),
        .O_unmount(S_session_O_unmount),
        .O_mount_valid(S_session_O_mount_valid),
        .I_mount_ready(S_files_O_mount_ready),
        .I_mount_result_valid(S_files_O_mount_result_valid),
        .O_mount_result_ready(S_session_O_mount_result_ready),
        .I_mount_error(S_files_O_mount_error),
        .I_mount_storage_error(S_files_O_mount_storage_error),
        .I_mount_generation(S_files_O_mount_generation),
        .O_scan_start_valid(S_session_O_scan_start_valid),
        .I_scan_start_ready(S_scan_O_start_ready),
        .I_scan_done_valid(S_scan_O_done_valid),
        .O_scan_done_ready(S_session_O_scan_done_ready),
        .O_scan_abort(S_session_O_scan_abort),
        .O_scan_tag(S_session_O_scan_tag),
        .O_scan_generation(S_session_O_scan_generation),
        .I_scan_error(S_scan_O_error),
        .I_scan_count(S_scan_O_count),
        .I_scan_committed(S_scan_O_committed),
        .I_scan_generation(S_scan_O_generation),
        .O_client_abort(S_session_O_client_abort),
        .O_allow_start(S_session_O_allow_start),
        .O_ready(S_session_O_ready),
        .O_busy(S_session_O_busy),
        .O_scan_done(S_session_O_scan_done),
        .O_count(S_session_O_count),
        .O_error(S_session_O_error),
        .O_scan_error(S_session_O_scan_error),
        .O_mount_error(S_session_O_mount_error),
        .O_mount_storage_error(S_session_O_mount_storage_error),
        .O_generation(S_session_O_generation)
    );
    assign O_image_start_ready=S_image_O_start_ready && S_session_O_allow_start;
    assign O_image_part_needed=S_image_O_part_needed;
    assign O_image_part_index=S_image_O_part_index;
    assign O_image_part_ready=S_image_O_part_ready;
    assign O_image_slot_cmd_valid=S_image_O_slot_cmd_valid;
    assign O_image_slot_cmd_op=S_image_O_slot_cmd_op;
    assign O_image_slot_cmd_slot=S_image_O_slot_cmd_slot;
    assign O_image_slot_cmd_owner=S_image_O_slot_cmd_owner;
    assign O_image_slot_cmd_token=S_image_O_slot_cmd_token;
    assign O_image_slot_cmd_generation=S_image_O_slot_cmd_generation;
    assign O_image_slot_cmd_asset=S_image_O_slot_cmd_asset;
    assign O_image_slot_cmd_layout=S_image_O_slot_cmd_layout;
    assign O_image_slot_cmd_rotation=S_image_O_slot_cmd_rotation;
    assign O_image_slot_cmd_resident=S_image_O_slot_cmd_resident;
    assign O_image_slot_cmd_success=S_image_O_slot_cmd_success;
    assign O_image_producer_retired=S_image_O_producer_retired;
    assign O_image_memory_retired=S_image_O_memory_retired;
    assign O_image_slot_result_ready=S_image_O_slot_result_ready;
    assign O_image_busy=S_image_O_busy;
    assign O_image_progress=S_image_O_progress;
    assign O_image_done_valid=S_image_O_done_valid;
    assign O_image_error=S_image_O_error;
    assign O_image_context=S_image_O_context;
    assign O_image_tag=S_image_O_tag;
    assign O_image_generation=S_image_O_generation;
    assign O_image_lease_token=S_image_O_lease_token;
    assign O_image_slot=S_image_O_slot;
    assign O_image_published=S_image_O_published;
    assign O_image_slot_owned=S_image_O_slot_owned;
    assign O_image_file_started=S_image_O_file_started;
    assign O_image_transform_started=S_image_O_transform_started;
    assign O_image_writer_started=S_image_O_writer_started;
    assign O_image_file_source_error=S_image_O_file_source_error;
    assign O_image_parser_error=S_image_O_parser_error;
    assign O_image_storage_error=S_image_O_storage_error;
    assign O_image_transform_error=S_image_O_transform_error;
    assign O_image_writer_error=S_image_O_writer_error;
    assign O_image_memory_error=S_image_O_memory_error;
    assign O_image_file_error=S_image_O_file_error;
    assign O_image_path_warning=S_image_O_path_warning;
    assign O_image_file_size=S_image_O_file_size;
    assign O_image_accepted_writes=S_image_O_accepted_writes;
    assign O_image_retired_writes=S_image_O_retired_writes;
    assign O_image_pixels=S_image_O_pixels;
    assign O_image_response_discarded=S_image_O_response_discarded;
    assign O_image_path_ready=S_image_O_path_ready;
    assign O_image_mem_valid=S_image_O_mem_valid;
    assign O_image_mem_wr=S_image_O_mem_wr;
    assign O_image_mem_addr=S_image_O_mem_addr;
    assign O_image_mem_data=S_image_O_mem_data;
    assign O_image_mem_tag=S_image_O_mem_tag;
    assign O_image_mem_mask=S_image_O_mem_mask;
    assign O_image_mem_lease_token=S_image_O_mem_lease_token;
    assign O_image_mem_generation=S_image_O_mem_generation;
    assign O_image_mem_done_ready=S_image_O_mem_done_ready;
    assign O_image_evict_valid=S_image_O_evict_valid;
    assign O_image_evict_command=S_image_O_evict_command;
    assign O_image_evict_result_ready=S_image_O_evict_result_ready;
    assign O_image_loader_error=S_image_O_loader_error;
    assign O_image_slot_error=S_image_O_slot_error;
    assign O_image_loader_started=S_image_O_loader_started;
    assign O_image_reused=S_image_O_reused;
    assign O_image_evicted=S_image_O_evicted;
    assign O_image_quarantined=S_image_O_quarantined;
    assign O_image_stage_valid=S_image_O_stage_valid;
    assign O_image_staged_slots=S_image_O_staged_slots;
    assign O_image_stage_release_ready=S_image_O_stage_release_ready;
    assign O_image_frozen_request=S_image_O_frozen_request;
    assign O_image_loader_lease_token=S_image_O_loader_lease_token;
    assign O_scan_start_ready=S_scan_O_start_ready;
    assign O_scan_busy=S_scan_O_busy;
    assign O_scan_done_valid=S_scan_O_done_valid;
    assign O_scan_error=S_scan_O_error;
    assign O_scan_list_source_error=S_scan_O_list_source_error;
    assign O_scan_list_build_error=S_scan_O_list_build_error;
    assign O_scan_directory_build_error=S_scan_O_directory_build_error;
    assign O_scan_count=S_scan_O_count;
    assign O_scan_committed=S_scan_O_committed;
    assign O_scan_used_directory=S_scan_O_used_directory;
    assign O_scan_list_missing=S_scan_O_list_missing;
    assign O_scan_list_started=S_scan_O_list_started;
    assign O_scan_directory_started=S_scan_O_directory_started;
    assign O_scan_list_warning=S_scan_O_list_warning;
    assign O_scan_directory_warning=S_scan_O_directory_warning;
    assign O_scan_context=S_scan_O_context;
    assign O_scan_tag=S_scan_O_tag;
    assign O_scan_generation=S_scan_O_generation;
    assign O_scan_file_error=S_scan_O_file_error;
    assign O_scan_storage_error=S_scan_O_storage_error;
    assign O_scan_path_warning=S_scan_O_path_warning;
    assign O_scan_file_size=S_scan_O_file_size;
    assign O_scan_active_valid=S_scan_O_active_valid;
    assign O_scan_active_count=S_scan_O_active_count;
    assign O_scan_active_generation=S_scan_O_active_generation;
    assign O_scan_active_revision=S_scan_O_active_revision;
    assign O_scan_acquire_ready=S_scan_O_acquire_ready;
    assign O_scan_snapshot_valid=S_scan_O_snapshot_valid;
    assign O_scan_snapshot_count=S_scan_O_snapshot_count;
    assign O_scan_snapshot_generation=S_scan_O_snapshot_generation;
    assign O_scan_snapshot_revision=S_scan_O_snapshot_revision;
    assign O_scan_release_ready=S_scan_O_release_ready;
    assign O_scan_read_ready=S_scan_O_read_ready;
    assign O_scan_read_result_valid=S_scan_O_read_result_valid;
    assign O_scan_read_file_length=S_scan_O_read_file_length;
    assign O_scan_read_audio_length=S_scan_O_read_audio_length;
    assign O_scan_read_title_length=S_scan_O_read_title_length;
    assign O_scan_read_duration=S_scan_O_read_duration;
    assign O_scan_read_transition_ms=S_scan_O_read_transition_ms;
    assign O_scan_read_transition=S_scan_O_read_transition;
    assign O_scan_read_policy=S_scan_O_read_policy;
    assign O_scan_read_data=S_scan_O_read_data;
    assign O_scan_read_tag=S_scan_O_read_tag;
    assign O_scan_read_error=S_scan_O_read_error;
    assign O_scan_directory_error=S_scan_O_directory_error;
    assign O_scan_directory_primary_error=S_scan_O_directory_primary_error;
    assign O_scan_directory_storage_error=S_scan_O_directory_storage_error;
    assign O_scan_enum_warning=S_scan_O_enum_warning;
    assign O_scan_directory_sectors=S_scan_O_directory_sectors;
    assign O_scan_active_order=S_scan_O_active_order;
    assign O_scan_active_base_order=S_scan_O_active_base_order;
    assign O_scan_active_base_order_explicit=S_scan_O_active_base_order_explicit;
    assign O_scan_reorder_ready=S_scan_O_reorder_ready;
    assign O_scan_reorder_done_valid=S_scan_O_reorder_done_valid;
    assign O_scan_reorder_error=S_scan_O_reorder_error;
    assign O_scan_reorder_tag=S_scan_O_reorder_tag;
    assign O_scan_reorder_generation=S_scan_O_reorder_generation;
    assign O_scan_reorder_revision=S_scan_O_reorder_revision;
    assign O_scan_reorder_current_index=S_scan_O_reorder_current_index;
    assign O_audio_file_start_ready={S_b_O_start_ready,S_a_O_start_ready} & {2{S_session_O_allow_start}};
    assign O_audio_file_path_ready={S_b_O_path_ready,S_a_O_path_ready};
    assign O_audio_file_busy={S_b_O_busy,S_a_O_busy};
    assign O_audio_file_done_valid={S_b_O_done_valid,S_a_O_done_valid};
    assign O_audio_file_error={S_b_O_error,S_a_O_error};
    assign O_audio_file_file_error={S_b_O_file_error,S_a_O_file_error};
    assign O_audio_file_storage_error={S_b_O_storage_error,S_a_O_storage_error};
    assign O_audio_file_path_warning={S_b_O_path_warning,S_a_O_path_warning};
    assign O_audio_file_context={S_b_O_context,S_a_O_context};
    assign O_audio_file_tag={S_b_O_tag,S_a_O_tag};
    assign O_audio_file_generation={S_b_O_generation,S_a_O_generation};
    assign O_audio_file_file_size={S_b_O_file_size,S_a_O_file_size};
    assign O_audio_byte_discarded=S_player_O_byte_discarded;
    assign O_audio_recycle_ready=S_player_O_recycle_ready;
    assign O_audio_recycle_done=S_player_O_recycle_done;
    assign O_audio_available=S_player_O_available;
    assign O_audio_source_busy=S_player_O_source_busy;
    assign O_audio_written_frames=S_player_O_written_frames;
    assign O_audio_play_ready=S_player_O_play_ready && !S_session_abort_video;
    assign O_audio_fade_ready=S_player_O_fade_ready && !S_session_abort_video;
    assign O_audio_silence_ready=S_player_O_silence_ready && !S_session_abort_video;
    assign O_audio_silence_started=S_player_O_silence_started;
    assign O_audio_silence_done=S_player_O_silence_done;
    assign O_audio_paused=S_player_O_paused;
    assign O_audio_pause_busy=S_player_O_pause_busy;
    assign O_audio_sample_valid=S_player_O_sample_valid;
    assign O_audio_left=S_player_O_left;
    assign O_audio_right=S_player_O_right;
    assign O_audio_clipped=S_player_O_clipped;
    assign O_audio_fade_done=S_player_O_fade_done;
    assign O_audio_active_b=S_player_O_active_b;
    assign O_audio_busy=S_player_O_busy;
    assign O_audio_started=S_player_O_started;
    assign O_audio_loaded=S_player_O_loaded;
    assign O_audio_enabled=S_player_O_enabled;
    assign O_audio_end=S_player_O_end;
    assign O_audio_consumed=S_player_O_consumed;
    assign O_audio_underrun=S_player_O_underrun;
    assign O_audio_release=S_player_O_release;
    assign O_audio_next_index=S_player_O_next_index;
    assign O_audio_need_fill=S_player_O_need_fill;
    assign O_audio_failed=S_player_O_failed;
    assign O_audio_slot_stopping=S_player_O_slot_stopping;
    assign O_audio_event_valid=S_player_O_event_valid;
    assign O_audio_event_header=S_player_O_event_header;
    assign O_audio_event_epoch=S_player_O_event_epoch;
    assign O_audio_event_total_frames=S_player_O_event_total_frames;
    assign O_audio_event_written_frames=S_player_O_event_written_frames;
    assign O_audio_event_error=S_player_O_event_error;
    assign O_audio_bind_ready=S_player_O_bind_ready;
    assign O_audio_audio_ready=S_player_O_audio_ready;
    assign O_audio_audio_epoch=S_player_O_audio_epoch;
    assign O_audio_track_known=S_player_O_track_known;
    assign O_audio_track_epochs=S_player_O_track_epochs;
    assign O_audio_track_serials=S_player_O_track_serials;
    assign O_audio_track_totals=S_player_O_track_totals;
    assign O_audio_bound=S_player_O_bound;
    assign O_audio_binding_revoked=S_player_O_binding_revoked;
    assign O_audio_bind_error=S_player_O_bind_error;
    assign O_audio_audio_accepted=S_player_O_audio_accepted;
    assign O_audio_audio_accepted_epoch=S_player_O_audio_accepted_epoch;
    assign O_audio_audio_accepted_tag=S_player_O_audio_accepted_tag;
    assign O_audio_prepare_contract_fault=S_player_O_prepare_contract_fault;
    assign O_audio_prepare_quarantined=S_player_O_prepare_quarantined;
    assign O_audio_prepare_response_discarded=S_player_O_prepare_response_discarded;
    assign O_storage_demo_active=S_files_O_demo_active;
    assign O_storage_demo_ready=S_files_O_demo_ready;
    assign O_storage_recovery_active=S_files_O_recovery_active;
    assign O_storage_demo_error=S_files_O_demo_error;
    assign O_storage_flash_valid=S_files_O_flash_valid;
    assign O_storage_flash_address=S_files_O_flash_address;
    assign O_storage_flash_length=S_files_O_flash_length;
    assign O_storage_flash_tag=S_files_O_flash_tag;
    assign O_storage_flash_read_ready=S_files_O_flash_read_ready;
    assign O_storage_flash_done_ready=S_files_O_flash_done_ready;
    assign O_storage_lease_grant=S_files_O_lease_grant;
    assign O_storage_busy=S_files_O_busy;
    assign O_storage_quiescent=S_files_O_quiescent;
    assign O_storage_leased_contexts=S_files_O_leased_contexts;
    assign O_storage_descriptors=S_files_O_descriptors;
    assign O_storage_pending_reads=S_files_O_pending_reads;
    assign O_storage_contract_fault=S_files_O_contract_fault;
    assign O_storage_response_discarded=S_files_O_response_discarded;
    assign O_storage_mount_ready=S_files_O_mount_ready;
    assign O_storage_mount_result_valid=S_files_O_mount_result_valid;
    assign O_storage_mount_error=S_files_O_mount_error;
    assign O_storage_mount_storage_error=S_files_O_mount_storage_error;
    assign O_storage_mount_generation=S_files_O_mount_generation;
    assign O_storage_mounted=S_files_O_mounted;
    assign O_storage_generation=S_files_O_generation;
    assign O_storage_card_ready=S_files_O_card_ready;
    assign O_storage_card_present=S_files_O_card_present;
    assign O_storage_capacity_sectors=S_files_O_capacity_sectors;
    assign O_storage_sd_high_capacity=S_files_O_sd_high_capacity;
    assign O_storage_sd_card_error=S_files_O_sd_card_error;
    assign O_storage_sd_ncs=S_files_O_sd_ncs;
    assign O_storage_sd_sclk=S_files_O_sd_sclk;
    assign O_storage_sd_mosi=S_files_O_sd_mosi;
    assign S_image_done=S_files_O_client_done[0+:95];
    assign S_a_done=S_files_O_client_done[95+:95];
    assign S_b_done=S_files_O_client_done[190+:95];
    assign S_scan_done=S_files_O_client_done[285+:95];
    assign O_session_client_abort=S_session_O_client_abort;
    assign O_session_allow_start=S_session_O_allow_start;
    assign O_session_ready=S_session_O_ready;
    assign O_session_busy=S_session_O_busy;
    assign O_session_scan_done=S_session_O_scan_done;
    assign O_session_count=S_session_O_count;
    assign O_session_error=S_session_O_error;
    assign O_session_scan_error=S_session_O_scan_error;
    assign O_session_mount_error=S_session_O_mount_error;
    assign O_session_mount_storage_error=S_session_O_mount_storage_error;
    assign O_session_generation=S_session_O_generation;
endmodule
