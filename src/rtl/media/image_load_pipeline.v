// Automatic ordinary-slot owner + one real BMP loader. Host clock only.
// Route loader slot commands to client0, maintenance to client2 of ONE arbiter.
// I_pinned_slots is the real pin mask; arbiter pins = it | O_staged_slots.
module image_load_pipeline #(
    parameter integer PENDING_BITS=3,
    parameter integer MEM_TAG_BITS=32
) (
    input wire I_clk,
    input wire I_reset,
    input wire I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,
    output wire O_lease_request,
    output wire O_lease_active,
    input wire I_lease_grant,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire [31:0] I_asset,
    input wire [2:0] I_layout,
    input wire I_compose,
    input wire [3:0] I_parts,
    output wire O_part_needed,
    output wire [3:0] O_part_index,
    input wire I_part_valid,
    output wire O_part_ready,
    input wire [6:0] I_part_path_length,
    input wire [1:0] I_rotation,
    input wire I_abort,
    output wire O_slot_cmd_valid,
    input wire I_slot_cmd_ready,
    output wire [2:0] O_slot_cmd_op,
    output wire [2:0] O_slot_cmd_slot,
    output wire [1:0] O_slot_cmd_owner,
    output wire [31:0] O_slot_cmd_token,
    output wire [31:0] O_slot_cmd_generation,
    output wire [31:0] O_slot_cmd_asset,
    output wire [2:0] O_slot_cmd_layout,
    output wire [1:0] O_slot_cmd_rotation,
    output wire O_slot_cmd_resident,
    output wire O_slot_cmd_success,
    output wire O_producer_retired,
    output wire O_memory_retired,
    input wire I_slot_result_valid,
    output wire O_slot_result_ready,
    input wire [3:0] I_slot_result_error,
    input wire [2:0] I_slot_result_op,
    input wire [2:0] I_slot_result_slot,
    input wire [1:0] I_slot_result_owner,
    input wire [31:0] I_slot_result_token,
    input wire [31:0] I_slot_result_generation,
    output wire O_busy,
    output wire O_progress,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [3:0] O_error,
    output wire [1:0] O_context,
    output wire [15:0] O_tag,
    output wire [31:0] O_generation,
    output wire [31:0] O_lease_token,
    output wire [2:0] O_slot,
    output wire O_published,
    output wire O_slot_owned,
    output wire O_file_started,
    output wire O_transform_started,
    output wire O_writer_started,
    output wire [3:0] O_file_source_error,
    output wire [3:0] O_parser_error,
    output wire [3:0] O_storage_error,
    output wire [3:0] O_transform_error,
    output wire [3:0] O_writer_error,
    output wire [3:0] O_memory_error,
    output wire [7:0] O_file_error,
    output wire [2:0] O_path_warning,
    output wire [31:0] O_file_size,
    output wire [31:0] O_accepted_writes,
    output wire [31:0] O_retired_writes,
    output wire [31:0] O_pixels,
    output wire O_response_discarded,
    input wire [31:0] I_sector_budget,
    input wire [6:0] I_path_length,
    input wire I_path_valid,
    output wire O_path_ready,
    input wire [7:0] I_path_data,
    input wire I_path_last,
    output wire O_fs_open_valid,
    input wire I_fs_open_ready,
    output wire [1:0] O_fs_open_context,
    output wire [15:0] O_fs_open_tag,
    output wire [6:0] O_fs_path_length,
    output wire [31:0] O_fs_sector_budget,
    output wire O_fs_path_valid,
    input wire I_fs_path_ready,
    output wire [7:0] O_fs_path_data,
    output wire O_fs_path_last,
    output wire O_fs_open_cancel,
    input wire I_fs_open_result_valid,
    output wire O_fs_open_result_ready,
    input wire [1:0] I_fs_open_context,
    input wire [15:0] I_fs_open_tag,
    input wire [31:0] I_fs_open_generation,
    input wire [31:0] I_fs_open_size,
    input wire [7:0] I_fs_open_error,
    input wire [3:0] I_fs_open_storage_error,
    input wire [2:0] I_fs_open_warning,
    output wire O_fs_read_valid,
    input wire I_fs_read_ready,
    output wire [1:0] O_fs_read_context,
    output wire [1:0] O_fs_read_priority,
    output wire [31:0] O_fs_offset,
    output wire [31:0] O_fs_length,
    output wire [15:0] O_fs_epoch,
    input wire I_fs_byte_valid,
    output wire O_fs_byte_ready,
    input wire [7:0] I_fs_byte_data,
    input wire [1:0] I_fs_byte_context,
    input wire [15:0] I_fs_byte_epoch,
    input wire [31:0] I_fs_byte_generation,
    input wire [31:0] I_fs_byte_offset,
    input wire I_fs_byte_last,
    input wire I_fs_done_valid,
    output wire O_fs_done_ready,
    input wire [1:0] I_fs_done_context,
    input wire [15:0] I_fs_done_epoch,
    input wire [31:0] I_fs_done_generation,
    input wire [31:0] I_fs_done_bytes,
    input wire I_fs_done_eof,
    input wire [7:0] I_fs_done_error,
    input wire [3:0] I_fs_done_storage_error,
    output wire O_fs_cancel_valid,
    input wire I_fs_cancel_ready,
    output wire [1:0] O_fs_cancel_context,
    output wire [15:0] O_fs_cancel_epoch,
    input wire I_fs_cancel_done_valid,
    output wire O_fs_cancel_done_ready,
    input wire [1:0] I_fs_cancel_done_context,
    input wire [15:0] I_fs_cancel_done_epoch,
    input wire [31:0] I_fs_cancel_done_generation,
    output wire O_fs_close_valid,
    input wire I_fs_close_ready,
    output wire [1:0] O_fs_close_context,
    output wire O_mem_valid,
    input wire I_mem_ready,
    output wire O_mem_wr,
    output wire [20:0] O_mem_addr,
    output wire [31:0] O_mem_data,
    output wire [31:0] O_mem_tag,
    output wire [3:0] O_mem_mask,
    output wire [31:0] O_mem_lease_token,
    output wire [31:0] O_mem_generation,
    input wire I_mem_done_valid,
    output wire O_mem_done_ready,
    input wire [31:0] I_mem_done_tag,
    input wire [31:0] I_mem_done_lease_token,
    input wire [31:0] I_mem_done_generation,
    input wire [3:0] I_mem_done_error,
    input wire [15:0] I_rect_x,
    input wire [15:0] I_rect_y,
    input wire [15:0] I_rect_width,
    input wire [15:0] I_rect_height,
    input wire I_bilinear,
    input wire [31:0] I_clear_rgba,
    input wire [17:0] I_slot_states,
    input wire [17:0] I_slot_layouts,
    input wire [17:0] I_slot_readers,
    input wire [191:0] I_slot_tokens,
    input wire [191:0] I_slot_generations,
    input wire [191:0] I_slot_assets,
    input wire [11:0] I_slot_rotations,
    input wire [5:0] I_slot_resident,
    input wire [5:0] I_slot_stale,
    input wire [5:0] I_pinned_slots,
    input wire [5:0] I_mutating_slots,
    input wire [137:0] I_host_reservation,
    output wire O_evict_valid,
    input wire I_evict_ready,
    output wire [114:0] O_evict_command,
    input wire I_evict_result_valid,
    output wire O_evict_result_ready,
    input wire [96:0] I_evict_result,
    output wire [3:0] O_loader_error,
    output wire [3:0] O_slot_error,
    output wire O_loader_started,
    output wire O_reused,
    output wire O_evicted,
    output wire O_quarantined,
    output wire O_stage_valid,
    output wire [5:0] O_staged_slots,
    input wire I_stage_release_valid,
    output wire O_stage_release_ready,
    input wire [2:0] I_stage_slot,
    input wire [31:0] I_stage_token,
    input wire [31:0] I_stage_generation,
    input wire I_stage_discard,
    output wire [227:0] O_frozen_request,
    output wire [31:0] O_loader_lease_token
);
    wire S_c_O_start_ready;
    wire S_c_O_evict_valid;
    wire [114:0] S_c_O_evict_command;
    wire S_c_O_evict_result_ready;
    wire S_c_O_loader_start_valid;
    wire [227:0] S_c_O_loader_request;
    wire [2:0] S_c_O_loader_slot;
    wire S_c_O_loader_abort;
    wire S_c_O_loader_done_ready;
    wire S_c_O_busy;
    wire S_c_O_done_valid;
    wire [1:0] S_c_O_context;
    wire [15:0] S_c_O_tag;
    wire [31:0] S_c_O_generation;
    wire [2:0] S_c_O_slot;
    wire [31:0] S_c_O_token;
    wire [3:0] S_c_O_error;
    wire [3:0] S_c_O_loader_error;
    wire [3:0] S_c_O_slot_error;
    wire S_c_O_loader_started;
    wire S_c_O_reused;
    wire S_c_O_evicted;
    wire S_c_O_published;
    wire S_c_O_quarantined;
    wire S_c_O_response_discarded;
    wire S_c_O_stage_valid;
    wire [5:0] S_c_O_staged_slots;
    wire S_c_O_stage_release_ready;
    wire S_l_O_start_ready;
    wire S_l_O_lease_request;
    wire S_l_O_lease_active;
    wire S_l_O_part_needed;
    wire [3:0] S_l_O_part_index;
    wire S_l_O_part_ready;
    wire S_l_O_slot_cmd_valid;
    wire [2:0] S_l_O_slot_cmd_op;
    wire [2:0] S_l_O_slot_cmd_slot;
    wire [1:0] S_l_O_slot_cmd_owner;
    wire [31:0] S_l_O_slot_cmd_token;
    wire [31:0] S_l_O_slot_cmd_generation;
    wire [31:0] S_l_O_slot_cmd_asset;
    wire [2:0] S_l_O_slot_cmd_layout;
    wire [1:0] S_l_O_slot_cmd_rotation;
    wire S_l_O_slot_cmd_resident;
    wire S_l_O_slot_cmd_success;
    wire S_l_O_producer_retired;
    wire S_l_O_memory_retired;
    wire S_l_O_slot_result_ready;
    wire S_l_O_busy;
    wire S_l_O_done_valid;
    wire [3:0] S_l_O_error;
    wire [1:0] S_l_O_context;
    wire [15:0] S_l_O_tag;
    wire [31:0] S_l_O_generation;
    wire [31:0] S_l_O_lease_token;
    wire [2:0] S_l_O_slot;
    wire S_l_O_published;
    wire S_l_O_slot_owned;
    wire S_l_O_file_started;
    wire S_l_O_transform_started;
    wire S_l_O_writer_started;
    wire [3:0] S_l_O_file_source_error;
    wire [3:0] S_l_O_parser_error;
    wire [3:0] S_l_O_storage_error;
    wire [3:0] S_l_O_transform_error;
    wire [3:0] S_l_O_writer_error;
    wire [3:0] S_l_O_memory_error;
    wire [7:0] S_l_O_file_error;
    wire [2:0] S_l_O_path_warning;
    wire [31:0] S_l_O_file_size;
    wire [31:0] S_l_O_accepted_writes;
    wire [31:0] S_l_O_retired_writes;
    wire [31:0] S_l_O_pixels;
    wire S_l_O_response_discarded;
    wire S_l_O_path_ready;
    wire S_l_O_fs_open_valid;
    wire [1:0] S_l_O_fs_open_context;
    wire [15:0] S_l_O_fs_open_tag;
    wire [6:0] S_l_O_fs_path_length;
    wire [31:0] S_l_O_fs_sector_budget;
    wire S_l_O_fs_path_valid;
    wire [7:0] S_l_O_fs_path_data;
    wire S_l_O_fs_path_last;
    wire S_l_O_fs_open_cancel;
    wire S_l_O_fs_open_result_ready;
    wire S_l_O_fs_read_valid;
    wire [1:0] S_l_O_fs_read_context;
    wire [1:0] S_l_O_fs_read_priority;
    wire [31:0] S_l_O_fs_offset;
    wire [31:0] S_l_O_fs_length;
    wire [15:0] S_l_O_fs_epoch;
    wire S_l_O_fs_byte_ready;
    wire S_l_O_fs_done_ready;
    wire S_l_O_fs_cancel_valid;
    wire [1:0] S_l_O_fs_cancel_context;
    wire [15:0] S_l_O_fs_cancel_epoch;
    wire S_l_O_fs_cancel_done_ready;
    wire S_l_O_fs_close_valid;
    wire [1:0] S_l_O_fs_close_context;
    wire S_l_O_mem_valid;
    wire S_l_O_mem_wr;
    wire [20:0] S_l_O_mem_addr;
    wire [31:0] S_l_O_mem_data;
    wire [31:0] S_l_O_mem_tag;
    wire [3:0] S_l_O_mem_mask;
    wire [31:0] S_l_O_mem_lease_token;
    wire [31:0] S_l_O_mem_generation;
    wire S_l_O_mem_done_ready;
    image_load_owner u_owner (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_start_valid(I_start_valid),
        .O_start_ready(S_c_O_start_ready),
        .I_request({I_compose,I_parts,I_context,I_tag,I_generation,I_asset,I_layout,I_rotation,I_rect_x,I_rect_y,I_rect_width,I_rect_height,I_bilinear,I_clear_rgba,I_path_length,I_sector_budget}),
        .I_abort(I_abort),
        .I_slot_states(I_slot_states),
        .I_slot_layouts(I_slot_layouts),
        .I_slot_readers(I_slot_readers),
        .I_slot_tokens(I_slot_tokens),
        .I_slot_generations(I_slot_generations),
        .I_slot_assets(I_slot_assets),
        .I_slot_rotations(I_slot_rotations),
        .I_slot_resident(I_slot_resident),
        .I_slot_stale(I_slot_stale),
        .I_pinned_slots(I_pinned_slots),
        .I_mutating_slots(I_mutating_slots),
        .I_host_reservation(I_host_reservation),
        .O_evict_valid(S_c_O_evict_valid),
        .I_evict_ready(I_evict_ready),
        .O_evict_command(S_c_O_evict_command),
        .I_evict_result_valid(I_evict_result_valid),
        .O_evict_result_ready(S_c_O_evict_result_ready),
        .I_evict_result(I_evict_result),
        .O_loader_start_valid(S_c_O_loader_start_valid),
        .I_loader_start_ready(S_l_O_start_ready),
        .O_loader_request(S_c_O_loader_request),
        .O_loader_slot(S_c_O_loader_slot),
        .O_loader_abort(S_c_O_loader_abort),
        .I_loader_done_valid(S_l_O_done_valid),
        .O_loader_done_ready(S_c_O_loader_done_ready),
        .I_loader_context(S_l_O_context),
        .I_loader_tag(S_l_O_tag),
        .I_loader_generation(S_l_O_generation),
        .I_loader_token(S_l_O_lease_token),
        .I_loader_slot(S_l_O_slot),
        .I_loader_error(S_l_O_error),
        .I_loader_published(S_l_O_published),
        .I_loader_slot_owned(S_l_O_slot_owned),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(I_done_ready),
        .O_context(S_c_O_context),
        .O_tag(S_c_O_tag),
        .O_generation(S_c_O_generation),
        .O_slot(S_c_O_slot),
        .O_token(S_c_O_token),
        .O_error(S_c_O_error),
        .O_loader_error(S_c_O_loader_error),
        .O_slot_error(S_c_O_slot_error),
        .O_loader_started(S_c_O_loader_started),
        .O_reused(S_c_O_reused),
        .O_evicted(S_c_O_evicted),
        .O_published(S_c_O_published),
        .O_quarantined(S_c_O_quarantined),
        .O_response_discarded(S_c_O_response_discarded),
        .O_stage_valid(S_c_O_stage_valid),
        .O_staged_slots(S_c_O_staged_slots),
        .I_stage_release_valid(I_stage_release_valid),
        .O_stage_release_ready(S_c_O_stage_release_ready),
        .I_stage_slot(I_stage_slot),
        .I_stage_token(I_stage_token),
        .I_stage_generation(I_stage_generation),
        .I_stage_discard(I_stage_discard)
    );
    bmp_frame_loader #(.PENDING_BITS(PENDING_BITS),.MEM_TAG_BITS(MEM_TAG_BITS)) u_loader (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_start_valid(S_c_O_loader_start_valid),
        .O_start_ready(S_l_O_start_ready),
        .O_lease_request(S_l_O_lease_request),
        .O_lease_active(S_l_O_lease_active),
        .I_lease_grant(I_lease_grant),
        .I_context(S_c_O_loader_request[222:221]),
        .I_tag(S_c_O_loader_request[220:205]),
        .I_generation(S_c_O_loader_request[204:173]),
        .I_asset(S_c_O_loader_request[172:141]),
        .I_slot(S_c_O_loader_slot),
        .I_layout(S_c_O_loader_request[140:138]),
        .I_compose(S_c_O_loader_request[227]),
        .I_parts(S_c_O_loader_request[226:223]),
        .O_part_needed(S_l_O_part_needed),
        .O_part_index(S_l_O_part_index),
        .I_part_valid(I_part_valid),
        .O_part_ready(S_l_O_part_ready),
        .I_part_path_length(I_part_path_length),
        .I_rotation(S_c_O_loader_request[137:136]),
        .I_abort(S_c_O_loader_abort),
        .O_slot_cmd_valid(S_l_O_slot_cmd_valid),
        .I_slot_cmd_ready(I_slot_cmd_ready),
        .O_slot_cmd_op(S_l_O_slot_cmd_op),
        .O_slot_cmd_slot(S_l_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_l_O_slot_cmd_owner),
        .O_slot_cmd_token(S_l_O_slot_cmd_token),
        .O_slot_cmd_generation(S_l_O_slot_cmd_generation),
        .O_slot_cmd_asset(S_l_O_slot_cmd_asset),
        .O_slot_cmd_layout(S_l_O_slot_cmd_layout),
        .O_slot_cmd_rotation(S_l_O_slot_cmd_rotation),
        .O_slot_cmd_resident(S_l_O_slot_cmd_resident),
        .O_slot_cmd_success(S_l_O_slot_cmd_success),
        .O_producer_retired(S_l_O_producer_retired),
        .O_memory_retired(S_l_O_memory_retired),
        .I_slot_result_valid(I_slot_result_valid),
        .O_slot_result_ready(S_l_O_slot_result_ready),
        .I_slot_result_error(I_slot_result_error),
        .I_slot_result_op(I_slot_result_op),
        .I_slot_result_slot(I_slot_result_slot),
        .I_slot_result_owner(I_slot_result_owner),
        .I_slot_result_token(I_slot_result_token),
        .I_slot_result_generation(I_slot_result_generation),
        .O_busy(S_l_O_busy),
        .O_done_valid(S_l_O_done_valid),
        .I_done_ready(S_c_O_loader_done_ready),
        .O_error(S_l_O_error),
        .O_context(S_l_O_context),
        .O_tag(S_l_O_tag),
        .O_generation(S_l_O_generation),
        .O_lease_token(S_l_O_lease_token),
        .O_slot(S_l_O_slot),
        .O_published(S_l_O_published),
        .O_slot_owned(S_l_O_slot_owned),
        .O_file_started(S_l_O_file_started),
        .O_transform_started(S_l_O_transform_started),
        .O_writer_started(S_l_O_writer_started),
        .O_file_source_error(S_l_O_file_source_error),
        .O_parser_error(S_l_O_parser_error),
        .O_storage_error(S_l_O_storage_error),
        .O_transform_error(S_l_O_transform_error),
        .O_writer_error(S_l_O_writer_error),
        .O_memory_error(S_l_O_memory_error),
        .O_file_error(S_l_O_file_error),
        .O_path_warning(S_l_O_path_warning),
        .O_file_size(S_l_O_file_size),
        .O_accepted_writes(S_l_O_accepted_writes),
        .O_retired_writes(S_l_O_retired_writes),
        .O_pixels(S_l_O_pixels),
        .O_response_discarded(S_l_O_response_discarded),
        .I_sector_budget(S_c_O_loader_request[31:0]),
        .I_path_length(S_c_O_loader_request[38:32]),
        .I_path_valid(I_path_valid),
        .O_path_ready(S_l_O_path_ready),
        .I_path_data(I_path_data),
        .I_path_last(I_path_last),
        .O_fs_open_valid(S_l_O_fs_open_valid),
        .I_fs_open_ready(I_fs_open_ready),
        .O_fs_open_context(S_l_O_fs_open_context),
        .O_fs_open_tag(S_l_O_fs_open_tag),
        .O_fs_path_length(S_l_O_fs_path_length),
        .O_fs_sector_budget(S_l_O_fs_sector_budget),
        .O_fs_path_valid(S_l_O_fs_path_valid),
        .I_fs_path_ready(I_fs_path_ready),
        .O_fs_path_data(S_l_O_fs_path_data),
        .O_fs_path_last(S_l_O_fs_path_last),
        .O_fs_open_cancel(S_l_O_fs_open_cancel),
        .I_fs_open_result_valid(I_fs_open_result_valid),
        .O_fs_open_result_ready(S_l_O_fs_open_result_ready),
        .I_fs_open_context(I_fs_open_context),
        .I_fs_open_tag(I_fs_open_tag),
        .I_fs_open_generation(I_fs_open_generation),
        .I_fs_open_size(I_fs_open_size),
        .I_fs_open_error(I_fs_open_error),
        .I_fs_open_storage_error(I_fs_open_storage_error),
        .I_fs_open_warning(I_fs_open_warning),
        .O_fs_read_valid(S_l_O_fs_read_valid),
        .I_fs_read_ready(I_fs_read_ready),
        .O_fs_read_context(S_l_O_fs_read_context),
        .O_fs_read_priority(S_l_O_fs_read_priority),
        .O_fs_offset(S_l_O_fs_offset),
        .O_fs_length(S_l_O_fs_length),
        .O_fs_epoch(S_l_O_fs_epoch),
        .I_fs_byte_valid(I_fs_byte_valid),
        .O_fs_byte_ready(S_l_O_fs_byte_ready),
        .I_fs_byte_data(I_fs_byte_data),
        .I_fs_byte_context(I_fs_byte_context),
        .I_fs_byte_epoch(I_fs_byte_epoch),
        .I_fs_byte_generation(I_fs_byte_generation),
        .I_fs_byte_offset(I_fs_byte_offset),
        .I_fs_byte_last(I_fs_byte_last),
        .I_fs_done_valid(I_fs_done_valid),
        .O_fs_done_ready(S_l_O_fs_done_ready),
        .I_fs_done_context(I_fs_done_context),
        .I_fs_done_epoch(I_fs_done_epoch),
        .I_fs_done_generation(I_fs_done_generation),
        .I_fs_done_bytes(I_fs_done_bytes),
        .I_fs_done_eof(I_fs_done_eof),
        .I_fs_done_error(I_fs_done_error),
        .I_fs_done_storage_error(I_fs_done_storage_error),
        .O_fs_cancel_valid(S_l_O_fs_cancel_valid),
        .I_fs_cancel_ready(I_fs_cancel_ready),
        .O_fs_cancel_context(S_l_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_l_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(S_l_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(I_fs_cancel_done_generation),
        .O_fs_close_valid(S_l_O_fs_close_valid),
        .I_fs_close_ready(I_fs_close_ready),
        .O_fs_close_context(S_l_O_fs_close_context),
        .O_mem_valid(S_l_O_mem_valid),
        .I_mem_ready(I_mem_ready),
        .O_mem_wr(S_l_O_mem_wr),
        .O_mem_addr(S_l_O_mem_addr),
        .O_mem_data(S_l_O_mem_data),
        .O_mem_tag(S_l_O_mem_tag),
        .O_mem_mask(S_l_O_mem_mask),
        .O_mem_lease_token(S_l_O_mem_lease_token),
        .O_mem_generation(S_l_O_mem_generation),
        .I_mem_done_valid(I_mem_done_valid),
        .O_mem_done_ready(S_l_O_mem_done_ready),
        .I_mem_done_tag(I_mem_done_tag),
        .I_mem_done_lease_token(I_mem_done_lease_token),
        .I_mem_done_generation(I_mem_done_generation),
        .I_mem_done_error(I_mem_done_error),
        .I_rect_x(S_c_O_loader_request[135:120]),
        .I_rect_y(S_c_O_loader_request[119:104]),
        .I_rect_width(S_c_O_loader_request[103:88]),
        .I_rect_height(S_c_O_loader_request[87:72]),
        .I_bilinear(S_c_O_loader_request[71]),
        .I_clear_rgba(S_c_O_loader_request[70:39])
    );
    assign O_start_ready=S_c_O_start_ready;
    assign O_lease_request=S_l_O_lease_request;
    assign O_lease_active=S_l_O_lease_active;
    assign O_part_needed=S_l_O_part_needed;
    assign O_part_index=S_l_O_part_index;
    assign O_part_ready=S_l_O_part_ready;
    assign O_slot_cmd_valid=S_l_O_slot_cmd_valid;
    assign O_slot_cmd_op=S_l_O_slot_cmd_op;
    assign O_slot_cmd_slot=S_l_O_slot_cmd_slot;
    assign O_slot_cmd_owner=S_l_O_slot_cmd_owner;
    assign O_slot_cmd_token=S_l_O_slot_cmd_token;
    assign O_slot_cmd_generation=S_l_O_slot_cmd_generation;
    assign O_slot_cmd_asset=S_l_O_slot_cmd_asset;
    assign O_slot_cmd_layout=S_l_O_slot_cmd_layout;
    assign O_slot_cmd_rotation=S_l_O_slot_cmd_rotation;
    assign O_slot_cmd_resident=S_l_O_slot_cmd_resident;
    assign O_slot_cmd_success=S_l_O_slot_cmd_success;
    assign O_producer_retired=S_l_O_producer_retired;
    assign O_memory_retired=S_l_O_memory_retired;
    assign O_slot_result_ready=S_l_O_slot_result_ready;
    assign O_busy=S_c_O_busy;
    assign O_done_valid=S_c_O_done_valid;
    assign O_error=S_c_O_error;
    assign O_context=S_c_O_context;
    assign O_tag=S_c_O_tag;
    assign O_generation=S_c_O_generation;
    assign O_lease_token=S_c_O_token;
    assign O_slot=S_c_O_slot;
    assign O_published=S_c_O_published;
    assign O_slot_owned=S_c_O_loader_started ? S_l_O_slot_owned : 0;
    assign O_file_started=S_c_O_loader_started ? S_l_O_file_started : 0;
    assign O_transform_started=S_c_O_loader_started ? S_l_O_transform_started : 0;
    assign O_writer_started=S_c_O_loader_started ? S_l_O_writer_started : 0;
    assign O_file_source_error=S_c_O_loader_started ? S_l_O_file_source_error : 0;
    assign O_parser_error=S_c_O_loader_started ? S_l_O_parser_error : 0;
    assign O_storage_error=S_c_O_loader_started ? S_l_O_storage_error : 0;
    assign O_transform_error=S_c_O_loader_started ? S_l_O_transform_error : 0;
    assign O_writer_error=S_c_O_loader_started ? S_l_O_writer_error : 0;
    assign O_memory_error=S_c_O_loader_started ? S_l_O_memory_error : 0;
    assign O_file_error=S_c_O_loader_started ? S_l_O_file_error : 0;
    assign O_path_warning=S_c_O_loader_started ? S_l_O_path_warning : 0;
    assign O_file_size=S_c_O_loader_started ? S_l_O_file_size : 0;
    assign O_accepted_writes=S_c_O_loader_started ? S_l_O_accepted_writes : 0;
    assign O_retired_writes=S_c_O_loader_started ? S_l_O_retired_writes : 0;
    assign O_pixels=S_c_O_loader_started ? S_l_O_pixels : 0;
    // Actual transfer evidence; the public pixel/write counts are terminal summaries.
    assign O_progress=!I_reset && ((I_fs_byte_valid && O_fs_byte_ready) ||
        (O_mem_valid && I_mem_ready) || (I_mem_done_valid && O_mem_done_ready) ||
        (I_fs_open_result_valid && O_fs_open_result_ready) ||
        (I_fs_done_valid && O_fs_done_ready) ||
        (I_fs_cancel_done_valid && O_fs_cancel_done_ready) ||
        (O_fs_close_valid && I_fs_close_ready) ||
        (I_slot_result_valid && O_slot_result_ready));
    assign O_response_discarded=S_c_O_response_discarded | S_l_O_response_discarded;
    assign O_path_ready=S_l_O_path_ready;
    assign O_fs_open_valid=S_l_O_fs_open_valid;
    assign O_fs_open_context=S_l_O_fs_open_context;
    assign O_fs_open_tag=S_l_O_fs_open_tag;
    assign O_fs_path_length=S_l_O_fs_path_length;
    assign O_fs_sector_budget=S_l_O_fs_sector_budget;
    assign O_fs_path_valid=S_l_O_fs_path_valid;
    assign O_fs_path_data=S_l_O_fs_path_data;
    assign O_fs_path_last=S_l_O_fs_path_last;
    assign O_fs_open_cancel=S_l_O_fs_open_cancel;
    assign O_fs_open_result_ready=S_l_O_fs_open_result_ready;
    assign O_fs_read_valid=S_l_O_fs_read_valid;
    assign O_fs_read_context=S_l_O_fs_read_context;
    assign O_fs_read_priority=S_l_O_fs_read_priority;
    assign O_fs_offset=S_l_O_fs_offset;
    assign O_fs_length=S_l_O_fs_length;
    assign O_fs_epoch=S_l_O_fs_epoch;
    assign O_fs_byte_ready=S_l_O_fs_byte_ready;
    assign O_fs_done_ready=S_l_O_fs_done_ready;
    assign O_fs_cancel_valid=S_l_O_fs_cancel_valid;
    assign O_fs_cancel_context=S_l_O_fs_cancel_context;
    assign O_fs_cancel_epoch=S_l_O_fs_cancel_epoch;
    assign O_fs_cancel_done_ready=S_l_O_fs_cancel_done_ready;
    assign O_fs_close_valid=S_l_O_fs_close_valid;
    assign O_fs_close_context=S_l_O_fs_close_context;
    assign O_mem_valid=S_l_O_mem_valid;
    assign O_mem_wr=S_l_O_mem_wr;
    assign O_mem_addr=S_l_O_mem_addr;
    assign O_mem_data=S_l_O_mem_data;
    assign O_mem_tag=S_l_O_mem_tag;
    assign O_mem_mask=S_l_O_mem_mask;
    assign O_mem_lease_token=S_l_O_mem_lease_token;
    assign O_mem_generation=S_l_O_mem_generation;
    assign O_mem_done_ready=S_l_O_mem_done_ready;
    assign O_evict_valid=S_c_O_evict_valid;
    assign O_evict_command=S_c_O_evict_command;
    assign O_evict_result_ready=S_c_O_evict_result_ready;
    assign O_loader_error=S_c_O_loader_error;
    assign O_slot_error=S_c_O_slot_error;
    assign O_loader_started=S_c_O_loader_started;
    assign O_reused=S_c_O_reused;
    assign O_evicted=S_c_O_evicted;
    assign O_quarantined=S_c_O_quarantined;
    assign O_stage_valid=S_c_O_stage_valid;
    assign O_staged_slots=S_c_O_staged_slots;
    assign O_stage_release_ready=S_c_O_stage_release_ready;
    assign O_frozen_request=S_c_O_loader_request;
    assign O_loader_lease_token=S_l_O_lease_token;
endmodule
