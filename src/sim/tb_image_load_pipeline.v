`timescale 1ns/1ps
// Real automatic slot owner, BMP loader/transform/writer, pin CDC, arbiter and slots.
// File service, logical memory responses and display reader retirement are explicit peers.
module tb_image_load_pipeline;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    wire S_host_reset;
    reset_sync u_reset (.I_clk(S_host_clk),.I_async_reset(S_reset),.O_reset(S_host_reset));
    reg S_media_valid=1,S_cmd_gate=1,S_inject_result=0;
    reg [31:0] S_generation=7;
    reg [96:0] S_bad_result=0;
    wire [96:0] S_manager_result;
    reg  S_p_I_video_enable=0;
    reg  S_p_I_update_valid=0;
    wire  S_p_O_update_ready;
    reg [31:0] S_p_I_epoch=0;
    reg [15:0] S_p_I_tag=0;
    reg [137:0] S_p_I_reservation=0;
    wire  S_p_O_done_valid;
    reg  S_p_I_done_ready=0;
    wire [31:0] S_p_O_epoch;
    wire [15:0] S_p_O_tag;
    wire [3:0] S_p_O_error;
    wire [137:0] S_p_O_images;
    wire [137:0] S_p_O_video_reservation;
    wire [31:0] S_p_O_video_epoch;
    wire [15:0] S_p_O_video_tag;
    wire  S_p_O_video_busy;
    wire  S_p_O_video_quarantined;
    wire  S_p_O_video_response_discarded;
    wire [137:0] S_p_O_host_reservation;
    wire [5:0] S_p_O_host_pinned_slots;
    wire  S_p_O_host_busy;
    wire  S_p_O_host_quarantined;
    wire [2:0] S_a_I_client_valid;
    wire [2:0] S_a_O_client_ready;
    wire [344:0] S_a_I_client_command;
    wire [2:0] S_a_O_client_result_valid;
    wire [2:0] S_a_I_client_result_ready;
    wire [96:0] S_a_O_client_result;
    wire  S_a_O_cmd_valid;
    wire [114:0] S_a_O_cmd;
    wire  S_a_O_result_ready;
    wire [5:0] S_a_O_mutating_slots;
    wire  S_a_O_busy;
    wire  S_a_O_contract_fault;
    wire  S_a_O_response_discarded;
    wire  S_m_O_cmd_ready;
    wire  S_m_O_result_valid;
    wire [3:0] S_m_O_result_error;
    wire [2:0] S_m_O_result_op;
    wire [2:0] S_m_O_result_slot;
    wire [1:0] S_m_O_result_owner;
    wire [31:0] S_m_O_result_token;
    wire [31:0] S_m_O_result_generation;
    wire [20:0] S_m_O_result_base;
    wire [17:0] S_m_O_slot_states;
    wire [191:0] S_m_O_slot_tokens;
    wire [191:0] S_m_O_slot_generations;
    wire [191:0] S_m_O_slot_assets;
    wire [17:0] S_m_O_slot_layouts;
    wire [17:0] S_m_O_slot_readers;
    wire [11:0] S_m_O_slot_rotations;
    wire [5:0] S_m_O_slot_resident;
    wire [5:0] S_m_O_slot_stale;
    wire [5:0] S_m_O_cancel_loading;
    wire  S_m_O_token_exhausted;
    image_reservation_cdc u_pins (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_video_enable(S_p_I_video_enable),
        .I_update_valid(S_p_I_update_valid),
        .O_update_ready(S_p_O_update_ready),
        .I_epoch(S_p_I_epoch),
        .I_tag(S_p_I_tag),
        .I_reservation(S_p_I_reservation),
        .O_done_valid(S_p_O_done_valid),
        .I_done_ready(S_p_I_done_ready),
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
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .I_slot_stale(S_m_O_slot_stale),
        .I_mutating_slots(S_a_O_mutating_slots),
        .O_host_reservation(S_p_O_host_reservation),
        .O_host_pinned_slots(S_p_O_host_pinned_slots),
        .O_host_busy(S_p_O_host_busy),
        .O_host_quarantined(S_p_O_host_quarantined)
    );
    fb_slot_arbiter u_arbiter (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_pinned_slots(S_p_O_host_pinned_slots | S_O_staged_slots),
        .I_client_valid(S_a_I_client_valid),
        .O_client_ready(S_a_O_client_ready),
        .I_client_command(S_a_I_client_command),
        .O_client_result_valid(S_a_O_client_result_valid),
        .I_client_result_ready(S_a_I_client_result_ready),
        .O_client_result(S_a_O_client_result),
        .O_cmd_valid(S_a_O_cmd_valid),
        .I_cmd_ready(S_m_O_cmd_ready && S_cmd_gate),
        .O_cmd(S_a_O_cmd),
        .I_result_valid(S_inject_result || S_m_O_result_valid),
        .O_result_ready(S_a_O_result_ready),
        .I_result(S_inject_result ? S_bad_result : S_manager_result),
        .O_mutating_slots(S_a_O_mutating_slots),
        .O_busy(S_a_O_busy),
        .O_contract_fault(S_a_O_contract_fault),
        .O_response_discarded(S_a_O_response_discarded)
    );
    fb_slot_manager u_slots (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_cmd_valid(S_a_O_cmd_valid && S_cmd_gate),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_a_O_cmd[114:112]),
        .I_cmd_slot(S_a_O_cmd[111:109]),
        .I_cmd_owner(S_a_O_cmd[108:107]),
        .I_cmd_token(S_a_O_cmd[106:75]),
        .I_cmd_generation(S_a_O_cmd[74:43]),
        .I_cmd_asset(S_a_O_cmd[42:11]),
        .I_cmd_layout(S_a_O_cmd[10:8]),
        .I_cmd_rotation(S_a_O_cmd[7:6]),
        .I_cmd_resident(S_a_O_cmd[5]),
        .I_cmd_success(S_a_O_cmd[4]),
        .I_producer_retired(S_a_O_cmd[3]),
        .I_memory_retired(S_a_O_cmd[2]),
        .I_reader_retired(S_a_O_cmd[1]),
        .I_frame_boundary(S_a_O_cmd[0]),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_a_O_result_ready && !S_inject_result),
        .O_result_error(S_m_O_result_error),
        .O_result_op(S_m_O_result_op),
        .O_result_slot(S_m_O_result_slot),
        .O_result_owner(S_m_O_result_owner),
        .O_result_token(S_m_O_result_token),
        .O_result_generation(S_m_O_result_generation),
        .O_result_base(S_m_O_result_base),
        .O_slot_states(S_m_O_slot_states),
        .O_slot_tokens(S_m_O_slot_tokens),
        .O_slot_generations(S_m_O_slot_generations),
        .O_slot_assets(S_m_O_slot_assets),
        .O_slot_layouts(S_m_O_slot_layouts),
        .O_slot_readers(S_m_O_slot_readers),
        .O_slot_rotations(S_m_O_slot_rotations),
        .O_slot_resident(S_m_O_slot_resident),
        .O_slot_stale(S_m_O_slot_stale),
        .O_cancel_loading(S_m_O_cancel_loading),
        .O_token_exhausted(S_m_O_token_exhausted)
    );
    assign S_manager_result={S_m_O_result_error,S_m_O_result_op,S_m_O_result_slot,S_m_O_result_owner,
        S_m_O_result_token,S_m_O_result_generation,S_m_O_result_base};

    reg S_I_start_valid=0;
    wire S_O_start_ready;
    wire S_O_lease_request;
    wire S_O_lease_active;
    reg S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_asset=0;
    reg [2:0] S_I_layout=0;
    reg [1:0] S_I_rotation=0;
    reg S_I_abort=0;
    wire S_O_slot_cmd_valid;
    wire S_I_slot_cmd_ready;
    wire [2:0] S_O_slot_cmd_op;
    wire [2:0] S_O_slot_cmd_slot;
    wire [1:0] S_O_slot_cmd_owner;
    wire [31:0] S_O_slot_cmd_token;
    wire [31:0] S_O_slot_cmd_generation;
    wire [31:0] S_O_slot_cmd_asset;
    wire [2:0] S_O_slot_cmd_layout;
    wire [1:0] S_O_slot_cmd_rotation;
    wire S_O_slot_cmd_resident;
    wire S_O_slot_cmd_success;
    wire S_O_producer_retired;
    wire S_O_memory_retired;
    wire S_I_slot_result_valid;
    wire S_O_slot_result_ready;
    wire [3:0] S_I_slot_result_error;
    wire [2:0] S_I_slot_result_op;
    wire [2:0] S_I_slot_result_slot;
    wire [1:0] S_I_slot_result_owner;
    wire [31:0] S_I_slot_result_token;
    wire [31:0] S_I_slot_result_generation;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_lease_token;
    wire [2:0] S_O_slot;
    wire S_O_published;
    wire S_O_slot_owned;
    wire S_O_file_started;
    wire S_O_transform_started;
    wire S_O_writer_started;
    wire [3:0] S_O_file_source_error;
    wire [3:0] S_O_parser_error;
    wire [3:0] S_O_storage_error;
    wire [3:0] S_O_transform_error;
    wire [3:0] S_O_writer_error;
    wire [3:0] S_O_memory_error;
    wire [7:0] S_O_file_error;
    wire [2:0] S_O_path_warning;
    wire [31:0] S_O_file_size;
    wire [31:0] S_O_accepted_writes;
    wire [31:0] S_O_retired_writes;
    wire [31:0] S_O_pixels;
    wire S_O_response_discarded;
    reg [31:0] S_I_sector_budget=0;
    reg [6:0] S_I_path_length=0;
    reg S_I_path_valid=0;
    wire S_O_path_ready;
    reg [7:0] S_I_path_data=0;
    reg S_I_path_last=0;
    wire S_O_fs_open_valid;
    reg S_I_fs_open_ready=0;
    wire [1:0] S_O_fs_open_context;
    wire [15:0] S_O_fs_open_tag;
    wire [6:0] S_O_fs_path_length;
    wire [31:0] S_O_fs_sector_budget;
    wire S_O_fs_path_valid;
    reg S_I_fs_path_ready=0;
    wire [7:0] S_O_fs_path_data;
    wire S_O_fs_path_last;
    wire S_O_fs_open_cancel;
    reg S_I_fs_open_result_valid=0;
    wire S_O_fs_open_result_ready;
    reg [1:0] S_I_fs_open_context=0;
    reg [15:0] S_I_fs_open_tag=0;
    reg [31:0] S_I_fs_open_generation=0;
    reg [31:0] S_I_fs_open_size=0;
    reg [7:0] S_I_fs_open_error=0;
    reg [3:0] S_I_fs_open_storage_error=0;
    reg [2:0] S_I_fs_open_warning=0;
    wire S_O_fs_read_valid;
    reg S_I_fs_read_ready=0;
    wire [1:0] S_O_fs_read_context;
    wire [1:0] S_O_fs_read_priority;
    wire [31:0] S_O_fs_offset;
    wire [31:0] S_O_fs_length;
    wire [15:0] S_O_fs_epoch;
    reg S_I_fs_byte_valid=0;
    wire S_O_fs_byte_ready;
    reg [7:0] S_I_fs_byte_data=0;
    reg [1:0] S_I_fs_byte_context=0;
    reg [15:0] S_I_fs_byte_epoch=0;
    reg [31:0] S_I_fs_byte_generation=0;
    reg [31:0] S_I_fs_byte_offset=0;
    reg S_I_fs_byte_last=0;
    reg S_I_fs_done_valid=0;
    wire S_O_fs_done_ready;
    reg [1:0] S_I_fs_done_context=0;
    reg [15:0] S_I_fs_done_epoch=0;
    reg [31:0] S_I_fs_done_generation=0;
    reg [31:0] S_I_fs_done_bytes=0;
    reg S_I_fs_done_eof=0;
    reg [7:0] S_I_fs_done_error=0;
    reg [3:0] S_I_fs_done_storage_error=0;
    wire S_O_fs_cancel_valid;
    reg S_I_fs_cancel_ready=0;
    wire [1:0] S_O_fs_cancel_context;
    wire [15:0] S_O_fs_cancel_epoch;
    reg S_I_fs_cancel_done_valid=0;
    wire S_O_fs_cancel_done_ready;
    reg [1:0] S_I_fs_cancel_done_context=0;
    reg [15:0] S_I_fs_cancel_done_epoch=0;
    reg [31:0] S_I_fs_cancel_done_generation=0;
    wire S_O_fs_close_valid;
    reg S_I_fs_close_ready=0;
    wire [1:0] S_O_fs_close_context;
    wire S_O_mem_valid;
    wire S_I_mem_ready;
    wire S_O_mem_wr;
    wire [20:0] S_O_mem_addr;
    wire [31:0] S_O_mem_data;
    wire [31:0] S_O_mem_tag;
    wire [3:0] S_O_mem_mask;
    wire [31:0] S_O_mem_lease_token;
    wire [31:0] S_O_mem_generation;
    wire S_I_mem_done_valid;
    wire S_O_mem_done_ready;
    reg [31:0] S_I_mem_done_tag=0;
    reg [31:0] S_I_mem_done_lease_token=0;
    reg [31:0] S_I_mem_done_generation=0;
    reg [3:0] S_I_mem_done_error=0;
    reg [15:0] S_I_rect_x=0;
    reg [15:0] S_I_rect_y=0;
    reg [15:0] S_I_rect_width=0;
    reg [15:0] S_I_rect_height=0;
    reg S_I_bilinear=0;
    reg [31:0] S_I_clear_rgba=0;
    wire S_O_evict_valid;
    wire [114:0] S_O_evict_command;
    wire S_O_evict_result_ready;
    wire [3:0] S_O_loader_error;
    wire [3:0] S_O_slot_error;
    wire S_O_loader_started;
    wire S_O_reused;
    wire S_O_evicted;
    wire S_O_quarantined;
    wire S_O_stage_valid;
    wire [5:0] S_O_staged_slots;
    reg S_I_stage_release_valid=0;
    wire S_O_stage_release_ready;
    reg [2:0] S_I_stage_slot=0;
    reg [31:0] S_I_stage_token=0;
    reg [31:0] S_I_stage_generation=0;
    reg S_I_stage_discard=0;
    wire [227:0] S_O_frozen_request;
    wire [31:0] S_O_loader_lease_token;
    image_load_pipeline u_dut (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .O_lease_active(S_O_lease_active),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_asset(S_I_asset),
        .I_layout(S_I_layout),
        .I_rotation(S_I_rotation),
        .I_abort(S_I_abort),
        .O_slot_cmd_valid(S_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_I_slot_cmd_ready),
        .O_slot_cmd_op(S_O_slot_cmd_op),
        .O_slot_cmd_slot(S_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_O_slot_cmd_owner),
        .O_slot_cmd_token(S_O_slot_cmd_token),
        .O_slot_cmd_generation(S_O_slot_cmd_generation),
        .O_slot_cmd_asset(S_O_slot_cmd_asset),
        .O_slot_cmd_layout(S_O_slot_cmd_layout),
        .O_slot_cmd_rotation(S_O_slot_cmd_rotation),
        .O_slot_cmd_resident(S_O_slot_cmd_resident),
        .O_slot_cmd_success(S_O_slot_cmd_success),
        .O_producer_retired(S_O_producer_retired),
        .O_memory_retired(S_O_memory_retired),
        .I_slot_result_valid(S_I_slot_result_valid),
        .O_slot_result_ready(S_O_slot_result_ready),
        .I_slot_result_error(S_I_slot_result_error),
        .I_slot_result_op(S_I_slot_result_op),
        .I_slot_result_slot(S_I_slot_result_slot),
        .I_slot_result_owner(S_I_slot_result_owner),
        .I_slot_result_token(S_I_slot_result_token),
        .I_slot_result_generation(S_I_slot_result_generation),
        .O_progress(),.O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_lease_token(S_O_lease_token),
        .O_slot(S_O_slot),
        .O_published(S_O_published),
        .O_slot_owned(S_O_slot_owned),
        .O_file_started(S_O_file_started),
        .O_transform_started(S_O_transform_started),
        .O_writer_started(S_O_writer_started),
        .O_file_source_error(S_O_file_source_error),
        .O_parser_error(S_O_parser_error),
        .O_storage_error(S_O_storage_error),
        .O_transform_error(S_O_transform_error),
        .O_writer_error(S_O_writer_error),
        .O_memory_error(S_O_memory_error),
        .O_file_error(S_O_file_error),
        .O_path_warning(S_O_path_warning),
        .O_file_size(S_O_file_size),
        .O_accepted_writes(S_O_accepted_writes),
        .O_retired_writes(S_O_retired_writes),
        .O_pixels(S_O_pixels),
        .O_response_discarded(S_O_response_discarded),
        .I_sector_budget(S_I_sector_budget),
        .I_path_length(S_I_path_length),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
        .O_fs_open_valid(S_O_fs_open_valid),
        .I_fs_open_ready(S_I_fs_open_ready),
        .O_fs_open_context(S_O_fs_open_context),
        .O_fs_open_tag(S_O_fs_open_tag),
        .O_fs_path_length(S_O_fs_path_length),
        .O_fs_sector_budget(S_O_fs_sector_budget),
        .O_fs_path_valid(S_O_fs_path_valid),
        .I_fs_path_ready(S_I_fs_path_ready),
        .O_fs_path_data(S_O_fs_path_data),
        .O_fs_path_last(S_O_fs_path_last),
        .O_fs_open_cancel(S_O_fs_open_cancel),
        .I_fs_open_result_valid(S_I_fs_open_result_valid),
        .O_fs_open_result_ready(S_O_fs_open_result_ready),
        .I_fs_open_context(S_I_fs_open_context),
        .I_fs_open_tag(S_I_fs_open_tag),
        .I_fs_open_generation(S_I_fs_open_generation),
        .I_fs_open_size(S_I_fs_open_size),
        .I_fs_open_error(S_I_fs_open_error),
        .I_fs_open_storage_error(S_I_fs_open_storage_error),
        .I_fs_open_warning(S_I_fs_open_warning),
        .O_fs_read_valid(S_O_fs_read_valid),
        .I_fs_read_ready(S_I_fs_read_ready),
        .O_fs_read_context(S_O_fs_read_context),
        .O_fs_read_priority(S_O_fs_read_priority),
        .O_fs_offset(S_O_fs_offset),
        .O_fs_length(S_O_fs_length),
        .O_fs_epoch(S_O_fs_epoch),
        .I_fs_byte_valid(S_I_fs_byte_valid),
        .O_fs_byte_ready(S_O_fs_byte_ready),
        .I_fs_byte_data(S_I_fs_byte_data),
        .I_fs_byte_context(S_I_fs_byte_context),
        .I_fs_byte_epoch(S_I_fs_byte_epoch),
        .I_fs_byte_generation(S_I_fs_byte_generation),
        .I_fs_byte_offset(S_I_fs_byte_offset),
        .I_fs_byte_last(S_I_fs_byte_last),
        .I_fs_done_valid(S_I_fs_done_valid),
        .O_fs_done_ready(S_O_fs_done_ready),
        .I_fs_done_context(S_I_fs_done_context),
        .I_fs_done_epoch(S_I_fs_done_epoch),
        .I_fs_done_generation(S_I_fs_done_generation),
        .I_fs_done_bytes(S_I_fs_done_bytes),
        .I_fs_done_eof(S_I_fs_done_eof),
        .I_fs_done_error(S_I_fs_done_error),
        .I_fs_done_storage_error(S_I_fs_done_storage_error),
        .O_fs_cancel_valid(S_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_I_fs_cancel_ready),
        .O_fs_cancel_context(S_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(S_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(S_I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(S_I_fs_cancel_done_generation),
        .O_fs_close_valid(S_O_fs_close_valid),
        .I_fs_close_ready(S_I_fs_close_ready),
        .O_fs_close_context(S_O_fs_close_context),
        .O_mem_valid(S_O_mem_valid),
        .I_mem_ready(S_I_mem_ready),
        .O_mem_wr(S_O_mem_wr),
        .O_mem_addr(S_O_mem_addr),
        .O_mem_data(S_O_mem_data),
        .O_mem_tag(S_O_mem_tag),
        .O_mem_mask(S_O_mem_mask),
        .O_mem_lease_token(S_O_mem_lease_token),
        .O_mem_generation(S_O_mem_generation),
        .I_mem_done_valid(S_I_mem_done_valid),
        .O_mem_done_ready(S_O_mem_done_ready),
        .I_mem_done_tag(S_I_mem_done_tag),
        .I_mem_done_lease_token(S_I_mem_done_lease_token),
        .I_mem_done_generation(S_I_mem_done_generation),
        .I_mem_done_error(S_I_mem_done_error),
        .I_rect_x(S_I_rect_x),
        .I_rect_y(S_I_rect_y),
        .I_rect_width(S_I_rect_width),
        .I_rect_height(S_I_rect_height),
        .I_bilinear(S_I_bilinear),
        .I_clear_rgba(S_I_clear_rgba),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_layouts(S_m_O_slot_layouts),
        .I_slot_readers(S_m_O_slot_readers),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_assets(S_m_O_slot_assets),
        .I_slot_rotations(S_m_O_slot_rotations),
        .I_slot_resident(S_m_O_slot_resident),
        .I_slot_stale(S_m_O_slot_stale),
        .I_pinned_slots(S_p_O_host_pinned_slots),
        .I_mutating_slots(S_a_O_mutating_slots),
        .I_host_reservation(S_p_O_host_reservation),
        .O_evict_valid(S_O_evict_valid),
        .I_evict_ready(S_a_O_client_ready[2]),
        .O_evict_command(S_O_evict_command),
        .I_evict_result_valid(S_a_O_client_result_valid[2]),
        .O_evict_result_ready(S_O_evict_result_ready),
        .I_evict_result(S_a_O_client_result),
        .O_loader_error(S_O_loader_error),
        .O_slot_error(S_O_slot_error),
        .O_loader_started(S_O_loader_started),
        .O_reused(S_O_reused),
        .O_evicted(S_O_evicted),
        .O_quarantined(S_O_quarantined),
        .O_stage_valid(S_O_stage_valid),
        .O_staged_slots(S_O_staged_slots),
        .I_stage_release_valid(S_I_stage_release_valid),
        .O_stage_release_ready(S_O_stage_release_ready),
        .I_stage_slot(S_I_stage_slot),
        .I_stage_token(S_I_stage_token),
        .I_stage_generation(S_I_stage_generation),
        .I_stage_discard(S_I_stage_discard),
        .O_frozen_request(S_O_frozen_request),
        .O_loader_lease_token(S_O_loader_lease_token),
        .I_compose(1'b0),
        .I_parts(4'd0),
        .O_part_needed(),
        .O_part_index(),
        .I_part_valid(1'b0),
        .O_part_ready(),
        .I_part_path_length(7'd0)
    );
    // Client0 loader, client1 explicit display/setup peer, client2 actual automatic EVICT owner.
    reg [1:0] S_peer_valid=0,S_peer_result_ready=0;
    reg [229:0] S_peer_command=0;
    wire [17:0] S_states=S_m_O_slot_states;
    assign S_a_I_client_valid={S_O_evict_valid,S_peer_valid[0],S_O_slot_cmd_valid};
    assign S_a_I_client_result_ready={S_O_evict_result_ready,S_peer_result_ready[0],S_O_slot_result_ready};
    assign S_a_I_client_command={S_O_evict_command,S_peer_command[114:0],S_O_slot_cmd_op,S_O_slot_cmd_slot,S_O_slot_cmd_owner,
        S_O_slot_cmd_token,S_O_slot_cmd_generation,S_O_slot_cmd_asset,S_O_slot_cmd_layout,S_O_slot_cmd_rotation,
        S_O_slot_cmd_resident,S_O_slot_cmd_success,S_O_producer_retired,S_O_memory_retired,1'b0,1'b0};
    assign S_I_slot_cmd_ready=S_a_O_client_ready[0];
    assign S_I_slot_result_valid=S_a_O_client_result_valid[0];
    assign {S_I_slot_result_error,S_I_slot_result_op,S_I_slot_result_slot,S_I_slot_result_owner,
        S_I_slot_result_token,S_I_slot_result_generation}=S_a_O_client_result[96:21];
    integer S_case=0,S_manager_commands=0,S_discarded=0;
    reg [31:0] S_tokens[0:5];
    reg [137:0] S_pair=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: image reservation case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #200000000; fail("watchdog timeout"); end
    always @(posedge S_host_clk) begin
        if(S_host_reset) S_manager_commands=0;
        else if(S_a_O_cmd_valid && S_m_O_cmd_ready && S_cmd_gate) begin
            S_manager_commands=S_manager_commands+1;
            if((S_a_O_cmd[114:112]==0 || S_a_O_cmd[114:112]==4) && S_a_O_cmd[111:109]<6 &&
                (S_p_O_host_pinned_slots[S_a_O_cmd[111:109]] || S_O_staged_slots[S_a_O_cmd[111:109]])) fail("real mutation escaped image pin protection");
        end
    end
    always @(posedge S_video_clk) if(!S_reset && S_p_O_video_response_discarded) S_discarded=S_discarded+1;
    function [114:0] command;
        input [2:0] op,slot;
        input [1:0] owner;
        input [31:0] token,generation;
        input resident;
        begin command={op,slot,owner,token,generation,32'd53,3'd0,2'd0,resident,1'b1,4'b1111}; end
    endfunction
    function [137:0] reservation;
        input [1:0] hold;
        input [2:0] a,b;
        begin reservation={hold,b,a,S_tokens[b],S_tokens[a],32'd7,32'd7,2'b00}; end
    endfunction
    task offer;
        input integer client;
        input [114:0] payload;
        begin
            @(negedge S_host_clk); S_peer_command[(client-1)*115+:115]=payload; S_peer_valid[client-1]=1;
            @(posedge S_host_clk); while(!S_a_O_client_ready[client]) @(posedge S_host_clk);
            @(negedge S_host_clk); S_peer_valid[client-1]=0;
        end
    endtask
    task take;
        input integer client;
        input [3:0] error;
        reg [96:0] held;
        begin
            wait(S_a_O_client_result_valid[client]); #1; held=S_a_O_client_result;
            if(held[96:93]!==error || S_a_O_client_result_valid!==(3'b001<<client)) fail("slot result error or client routing");
            if(held[92:90]==0 && error==0) S_tokens[held[89:87]]=held[84:53];
            repeat(4) begin @(negedge S_host_clk);
                if(!S_a_O_client_result_valid[client] || S_a_O_client_result!==held) fail("slot terminal changed under client backpressure"); end
            S_peer_result_ready[client-1]=1; @(negedge S_host_clk); S_peer_result_ready[client-1]=0;
        end
    endtask
    task slot_cmd;
        input integer client;
        input [2:0] op,slot;
        input [1:0] owner;
        input [3:0] error;
        begin offer(client,command(op,slot,owner,op==0 ? 0 : S_tokens[slot],7,0)); take(client,error); end
    endtask
    task update;
        input [31:0] epoch;
        input [137:0] desired;
        begin
            @(negedge S_video_clk); S_p_I_epoch=epoch; S_p_I_tag=16'ha000+epoch[15:0];
            S_p_I_reservation=desired; S_p_I_update_valid=1;
            @(posedge S_video_clk); while(!S_p_O_update_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_p_I_update_valid=0;
        end
    endtask
    task done;
        input [3:0] error;
        input [1:0] available;
        reg [51:0] held;
        begin
            wait(S_p_O_done_valid); #1;
            if(S_p_O_error!==error || S_p_O_images[137:136]!==available) fail("pin acknowledgment or reliable availability mismatch");
            held={S_p_O_epoch,S_p_O_tag,S_p_O_error};
            repeat(6) begin @(negedge S_video_clk);
                if(!S_p_O_done_valid || held!=={S_p_O_epoch,S_p_O_tag,S_p_O_error}) fail("pin result changed under backpressure"); end
            S_p_I_done_ready=1; @(negedge S_video_clk); S_p_I_done_ready=0;
        end
    endtask
    // A single registered logical write response. Not a model of SDRAM timing.
    reg S_allow_memory=1,S_inject_write_error=0,S_response_hold=0;
    reg S_endpoint_valid=0,S_hold_last_response=0;
    reg [31:0] S_frame[0:1843199];
    reg [2:0] S_check_slot=0;
    integer S_writes=0,S_replies=0,S_closes=0,S_cycle=0;
    reg [7:0] S_bmp[0:699];
    integer S_i,S_j,S_bpp=24;
    integer S_bad_config=0;
    reg S_top_down=0;
    reg [1:0] S_rotation=0;
    reg S_mem_held=0;
    reg [152:0] S_mem_saved;
    assign S_I_mem_done_valid=S_endpoint_valid && !S_response_hold;
    assign S_I_mem_ready=S_allow_memory &&
        (!S_endpoint_valid || (S_O_mem_done_ready && !S_response_hold)) && S_cycle%5!=0;
    always @(posedge S_host_clk) begin
        if(S_host_reset) begin
            S_endpoint_valid<=0; S_writes=0; S_replies=0; S_closes=0; S_cycle<=0; S_mem_held<=0;
        end else begin
            S_cycle<=S_cycle+1;
            if(S_I_mem_done_valid && S_O_mem_done_ready && !S_response_hold) begin
                S_endpoint_valid<=0; S_replies=S_replies+1;
            end
            if(S_O_mem_valid && S_I_mem_ready) begin
                if(!S_O_mem_wr || S_O_mem_mask!==0 || S_O_mem_addr<S_O_slot*307200 || S_O_mem_addr>=(S_O_slot+1)*307200 ||
                    S_O_mem_lease_token!==S_O_loader_lease_token || S_O_mem_generation!==7) fail("logical write identity/address/mask");
                S_frame[S_O_mem_addr]=S_O_mem_data;
                S_writes=S_writes+1;
                S_endpoint_valid<=1; S_I_mem_done_tag<=S_O_mem_tag;
                S_I_mem_done_lease_token<=S_O_mem_lease_token; S_I_mem_done_generation<=S_O_mem_generation;
                S_I_mem_done_error<=S_inject_write_error ? 4'd9 : 4'd0;
                // Hold BEFORE this response is first published, never withdraw valid.
                if(S_hold_last_response && S_writes==307206) S_response_hold<=1;
            end
            if(S_mem_held && (!S_O_mem_valid || S_mem_saved!=={S_O_mem_wr,S_O_mem_addr,S_O_mem_data,
                S_O_mem_tag,S_O_mem_mask,S_O_mem_lease_token,S_O_mem_generation})) fail("write command changed during stall");
            S_mem_held<=S_O_mem_valid && !S_I_mem_ready;
            S_mem_saved<={S_O_mem_wr,S_O_mem_addr,S_O_mem_data,S_O_mem_tag,S_O_mem_mask,S_O_mem_lease_token,S_O_mem_generation};
            if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
        end
    end
    task bmp32;
        input integer address;
        input [31:0] value;
        begin S_bmp[address]=value; S_bmp[address+1]=value>>8;
            S_bmp[address+2]=value>>16; S_bmp[address+3]=value>>24; end
    endtask
    task make_bmp;
        input integer bpp;
        input top_down;
        begin
            S_bpp=bpp; S_top_down=top_down;
            for(S_i=0;S_i<700;S_i=S_i+1) S_bmp[S_i]=0;
            S_bmp[0]="B"; S_bmp[1]="M";
            bmp32(2,700); bmp32(10,510); bmp32(14,40); bmp32(18,3);
            bmp32(22,top_down ? 32'hfffffffe : 32'd2);
            S_bmp[26]=1; S_bmp[28]=bpp; bmp32(34,24);
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                S_j=510+(S_i/3)*12+(S_i%3)*(bpp/8);
                S_bmp[S_j]=8'h30+S_i; S_bmp[S_j+1]=8'h20+S_i; S_bmp[S_j+2]=8'h10+S_i;
                if(bpp==32) S_bmp[S_j+3]=S_i;
            end
            for(S_i=534;S_i<700;S_i=S_i+1) S_bmp[S_i]=8'ha5;
        end
    endtask
    task reset_all;
        begin
            @(negedge S_host_clk); S_reset=1; S_host_run=1; S_video_run=1; S_cmd_gate=1; S_inject_result=0;
            S_peer_valid=0; S_peer_result_ready=0; S_p_I_update_valid=0; S_p_I_done_ready=0;
            for(S_i=0;S_i<6;S_i=S_i+1) S_tokens[S_i]=0;
            S_p_I_reservation=0; S_p_I_video_enable=1; S_I_abort=0; S_I_start_valid=0; S_I_done_ready=0;
            S_media_valid=1; S_generation=7; S_I_lease_grant=1;
            S_I_fs_open_ready=1; S_I_fs_path_ready=1; S_I_fs_read_ready=1; S_I_fs_close_ready=1;
            S_I_fs_open_result_valid=0; S_I_fs_byte_valid=0; S_I_fs_done_valid=0;
            S_I_fs_cancel_ready=0; S_I_fs_cancel_done_valid=0; S_I_path_valid=0;
            S_allow_memory=1; S_response_hold=0; S_inject_write_error=0; S_hold_last_response=0; S_bad_config=0; S_I_stage_release_valid=0; S_I_stage_discard=0;
            repeat(6) @(negedge S_video_clk); S_reset=0; wait(!S_host_reset && S_p_O_update_ready && S_O_start_ready);
        end
    endtask
    task launch;
        begin
            @(negedge S_host_clk); S_I_context=1; S_I_tag=16'hf135; S_I_generation=7;
            S_I_asset=53; S_I_layout=0; S_I_rotation=S_rotation;
            S_I_rect_x=S_bad_config==2 ? 65535 : 11;
            S_I_rect_y=19; S_I_rect_width=S_rotation[0] ? 2 : 3;
            S_I_rect_height=S_rotation[0] ? 3 : 2; S_I_bilinear=0;
            S_I_clear_rgba=32'h040506ff; S_I_path_length=S_bad_config==1 ? 65 : 9; S_I_sector_budget=8;
            S_I_start_valid=1;
            @(posedge S_host_clk); while(!S_O_start_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_I_start_valid=0;
        end
    endtask
    task send_path;
        reg [71:0] path;
        integer j;
        begin
            path="/TEST.BMP";
            for(j=0;j<9;j=j+1) begin
                @(negedge S_host_clk); S_I_path_valid=1; S_I_path_data=path[(8-j)*8+:8]; S_I_path_last=j==8;
                @(posedge S_host_clk); while(!S_O_path_ready) @(posedge S_host_clk);
            end
            @(negedge S_host_clk); S_I_path_valid=0;
        end
    endtask
    task open_result;
        input [7:0] error;
        begin
            @(negedge S_host_clk); S_I_fs_open_context=1; S_I_fs_open_tag=16'hf135;
            S_I_fs_open_generation=7; S_I_fs_open_size=700; S_I_fs_open_error=error;
            S_I_fs_open_result_valid=1;
            @(posedge S_host_clk); while(!S_O_fs_open_result_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_I_fs_open_result_valid=0;
        end
    endtask
    task byte_in;
        input integer offset;
        begin
            @(negedge S_host_clk); S_I_fs_byte_context=1; S_I_fs_byte_epoch=16'hf135;
            S_I_fs_byte_generation=7; S_I_fs_byte_offset=offset; S_I_fs_byte_data=S_bmp[offset];
            S_I_fs_byte_last=offset==699; S_I_fs_byte_valid=1;
            @(posedge S_host_clk); while(!S_O_fs_byte_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_I_fs_byte_valid=0;
        end
    endtask
    task read_done;
        input [31:0] count;
        input [7:0] error;
        begin
            @(negedge S_host_clk); S_I_fs_done_context=1; S_I_fs_done_epoch=16'hf135;
            S_I_fs_done_generation=7; S_I_fs_done_bytes=count; S_I_fs_done_error=error;
            S_I_fs_done_eof=error==0; S_I_fs_done_valid=1;
            @(posedge S_host_clk); while(!S_O_fs_done_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_I_fs_done_valid=0;
        end
    endtask
    task cancel_ack;
        begin
            @(negedge S_host_clk); S_I_fs_cancel_done_context=1; S_I_fs_cancel_done_epoch=16'hf135;
            S_I_fs_cancel_done_generation=7; S_I_fs_cancel_done_valid=1;
            @(posedge S_host_clk); while(!S_O_fs_cancel_done_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_I_fs_cancel_done_valid=0;
        end
    endtask
    task assert_loading;
        begin
            repeat(8) begin @(negedge S_host_clk);
                if(S_states[S_O_slot*3+:3]!==1 || S_O_done_valid || S_O_published || S_O_stage_valid)
                    fail("premature complete image/stage before file and write retirement"); end
        end
    endtask
    task counts_clear;
        begin
            @(negedge S_host_clk); S_writes=0; S_replies=0; S_closes=0;
        end
    endtask
    task take_auto;
        input [3:0] error;
        input [2:0] slot;
        input reused;
        reg [116:0] saved;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_slot!==slot || S_O_reused!==reused || S_O_slot_owned ||
                (error==0 && (!S_O_stage_valid || !S_O_published || S_O_lease_token==0)))
                fail("automatic owner terminal/selection/stage");
            if(error==0 && !reused && (S_O_pixels!=6 || S_O_accepted_writes!=307206 ||
                S_O_retired_writes!=307206 || S_closes!=1 || !S_O_lease_active))
                fail("actual file close/pixel/write retirement missing");
            if(reused && (S_O_loader_started || S_O_lease_active || S_O_file_started ||
                S_O_accepted_writes!=0 || S_O_path_ready)) fail("cache hit launched file or inherited old diagnostics");
            saved={S_O_error,S_O_context,S_O_tag,S_O_generation,S_O_slot,S_O_lease_token,
                S_O_loader_error,S_O_slot_error,S_O_published,S_O_loader_started,S_O_reused,S_O_evicted,16'd0};
            repeat(5) begin @(negedge S_host_clk);
                if(!S_O_done_valid || saved!=={S_O_error,S_O_context,S_O_tag,S_O_generation,S_O_slot,
                    S_O_lease_token,S_O_loader_error,S_O_slot_error,S_O_published,S_O_loader_started,
                    S_O_reused,S_O_evicted,16'd0}) fail("automatic result changed under backpressure"); end
            S_I_done_ready=1; @(negedge S_host_clk); S_I_done_ready=0;
            if(error==0 && (!S_O_stage_valid || S_O_start_ready || !S_O_busy))
                fail("external result consumption prematurely reopened candidate slot");
            if(S_O_lease_active) fail("consumed result retained real loader namespace");
        end
    endtask
    task release_stage;
        input discard;
        begin
            @(negedge S_host_clk); S_I_stage_slot=S_O_slot; S_I_stage_token=S_O_lease_token;
            S_I_stage_generation=S_O_generation; S_I_stage_discard=discard; S_I_stage_release_valid=1;
            @(posedge S_host_clk); while(!S_O_stage_release_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_I_stage_release_valid=0;
            if(S_O_stage_valid || !S_O_start_ready) fail("real pin/stage handoff did not finish");
        end
    endtask
    task feed;
        integer j;
        begin
            send_path; open_result(0);
            for(j=0;j<700;j=j+1) byte_in(j);
            read_done(700,0);
        end
    endtask
    task check_frame;
        integer u,v,px,py,k,at;
        reg [31:0] expected;
        begin
            // Independent direct inverse mapping for this unscaled 3x2 image.
            for(at=0;at<307200;at=at+1) begin
                expected=32'h040506ff;
                for(v=0;v<2;v=v+1) for(u=0;u<3;u=u+1) begin
                    case(S_rotation)
                        0:begin px=u; py=v; end
                        1:begin px=1-v; py=u; end
                        2:begin px=2-u; py=1-v; end
                        3:begin px=v; py=2-u; end
                    endcase
                    if(at==(19+py)*640+11+px) begin
                        k=(S_top_down ? v : 1-v)*3+u;
                        expected={8'h10+k[7:0],8'h20+k[7:0],8'h30+k[7:0],8'hff};
                    end
                end
                if(S_frame[S_check_slot*307200+at]!==expected) fail("full frame RGBA/black border/rotation");
            end
        end
    endtask
    reg [31:0] S_first_token=0;
    integer k,j;
    always @(posedge S_host_clk) if(!S_host_reset && S_a_O_cmd_valid && S_m_O_cmd_ready && S_cmd_gate &&
        S_a_O_cmd[114:112]==1 && S_a_O_cmd[4] && S_O_loader_started) begin
        if(!S_O_producer_retired || !S_O_memory_retired || S_O_accepted_writes!=307206 ||
            S_O_retired_writes!=307206 || !u_dut.u_loader.u_ctrl.S_file_seen || !u_dut.u_loader.u_ctrl.S_transform_seen)
            fail("successful real FINISH bypassed actual producer/write retirement");
    end
    initial begin
        S_case=1; reset_all; S_rotation=0; S_check_slot=0; S_hold_last_response=1;
        make_bmp(24,0); launch; wait(S_O_loader_lease_token!=0); S_tokens[0]=S_O_loader_lease_token;
        S_pair=reservation(1,0,1); update(1,S_pair); done(3,0);
        if(S_p_O_host_pinned_slots!=0) fail("LOADING became complete through pin CDC");
        send_path; open_result(0);
        for(k=0;k<700;k=k+1) byte_in(k);
        wait(u_dut.u_loader.u_ctrl.S_transform_seen); assert_loading;
        S_I_fs_close_ready=0; read_done(700,0); wait(S_O_fs_close_valid); assert_loading;
        @(negedge S_host_clk); S_I_fs_close_ready=1;
        wait(u_dut.u_loader.u_ctrl.S_file_seen && S_response_hold); assert_loading;
        @(negedge S_host_clk); S_response_hold=0;
        wait(S_O_done_valid); check_frame;
        // Clock stop cannot create a handoff: there is still no real video pin.
        @(negedge S_video_clk); S_video_run=0;
        slot_cmd(1,4,0,2,2);
        repeat(12) begin @(negedge S_host_clk);
            if(!S_O_stage_valid || S_p_O_host_pinned_slots!=0 || !S_O_done_valid)
                fail("unconsumed publication lost protection while video stopped"); end
        take_auto(0,0,0); S_first_token=S_O_lease_token;
        slot_cmd(1,4,0,2,2);
        @(negedge S_host_clk); S_I_stage_release_valid=1; S_I_stage_slot=0;
        S_I_stage_token=S_first_token; S_I_stage_generation=7; S_I_stage_discard=0;
        repeat(10) begin @(negedge S_host_clk);
            if(S_O_stage_release_ready || !S_O_stage_valid) fail("stage accepted absent host pin"); end
        S_I_stage_release_valid=0; S_video_run=1;
        update(2,S_pair); done(0,1); release_stage(0);
        if(S_p_O_host_pinned_slots!=1) fail("handoff removed actual video pin");
        slot_cmd(1,2,0,0,0);

        S_case=2; launch; take_auto(0,0,1);
        if(S_writes!=307206 || S_closes!=1 || S_O_lease_token!=S_first_token)
            fail("cache hit restarted BMP IO or changed allocation identity");
        check_frame; release_stage(0);
        if(S_m_O_slot_readers[2:0]!=1) fail("cache handoff retired actual READ_LOCK");

        S_case=3; counts_clear; S_rotation=1; S_check_slot=1; S_hold_last_response=0;
        make_bmp(32,1); launch; feed; take_auto(0,1,0); check_frame;
        if(S_m_O_slot_readers[2:0]!=1 || S_p_O_host_pinned_slots!=1 || S_O_staged_slots!=2)
            fail("new geometry damaged old pinned/displayed image");
        S_tokens[1]=S_O_lease_token;
        slot_cmd(1,4,1,2,2);
        S_pair=reservation(3,0,1); update(3,S_pair); done(0,3); release_stage(0);
        S_pair[137:136]=2; update(4,S_pair); done(0,2);
        slot_cmd(1,4,0,2,2); slot_cmd(1,3,0,0,0); slot_cmd(1,4,0,2,0);
        if(S_m_O_slot_readers[2:0]!=0 || S_states[2:0]!=0) fail("old real reader did not retire explicitly");

        S_case=4; reset_all; S_rotation=0; S_check_slot=2; make_bmp(24,0);
        // Set up complete slots using REAL ALLOC/FINISH, not force of internal state.
        for(j=0;j<5;j=j+1) begin slot_cmd(1,0,j,2,0); slot_cmd(1,1,j,2,0); end
        S_pair=reservation(1,0,2); update(1,S_pair); done(0,1);
        slot_cmd(1,2,1,0,0); slot_cmd(1,2,3,1,0); slot_cmd(1,2,4,2,0);
        launch; wait(S_O_evicted);
        if(S_O_slot!=2 || S_states[8:6]!=0 || S_m_O_slot_tokens[95:64]!=S_tokens[2])
            fail("automatic EVICT did not finish before real ALLOC");
        feed; take_auto(0,2,0); check_frame;
        if(!S_O_evicted || S_O_lease_token==S_tokens[2]) fail("automatic eviction reused retired token");
        S_tokens[2]=S_O_lease_token;

        S_case=5; S_pair=reservation(3,0,2); update(2,S_pair); done(0,3); release_stage(0);
        // 0/2 pinned, 1/3/4 actual readers, 5 FREE but reserved for resident safety.
        S_rotation=2; launch;
        repeat(50) begin @(negedge S_host_clk);
            if(S_O_done_valid || S_O_loader_started || S_O_evict_valid || S_O_slot_cmd_valid)
                fail("all-busy escaped real pin/reader/slot5 exclusions"); end
        S_I_abort=1; take_auto(3,0,0);
        if(S_m_O_slot_readers[5:3]!=1 || S_m_O_slot_readers[11:9]!=2 || S_m_O_slot_readers[14:12]!=4)
            fail("waiting cancellation fabricated reader retirement");

        S_case=6; reset_all; S_rotation=0; S_check_slot=0; make_bmp(24,0);
        launch; feed; take_auto(0,0,0); check_frame;
        @(negedge S_host_clk); S_media_valid=0;
        repeat(8) @(negedge S_host_clk);
        if(S_states[2:0]!=0 || S_O_staged_slots!=1 || S_O_start_ready)
            fail("media invalidation silently dropped staged handoff identity");
        release_stage(1);

        S_case=7; reset_all;
        for(j=0;j<5;j=j+1) begin slot_cmd(1,0,j,2,0); slot_cmd(1,1,j,2,0); end
        @(negedge S_host_clk); S_cmd_gate=0; launch;
        wait(S_a_O_cmd_valid && S_a_O_cmd[114:112]==4);
        @(negedge S_host_clk); S_I_abort=1;
        repeat(15) begin @(negedge S_host_clk);
            if(S_O_done_valid || S_O_loader_started || !S_a_O_cmd_valid || S_a_O_cmd[114:112]!=4)
                fail("cancelled EVICT withdrew real command or skipped debt"); end
        S_cmd_gate=1; take_auto(3,0,0);
        if(!S_O_evicted || S_states[2:0]!=0 || S_O_loader_started)
            fail("cancel after maintenance acceptance started a BMP");

        if(S_a_O_contract_fault || S_p_O_video_quarantined || S_p_O_host_quarantined || S_O_quarantined)
            fail("normal real BMP auto-slot chain entered isolation");
        $display("PASS: 7 real automatic owner/BMP/writer/slot/pin scenarios; explicit file/memory/reader peers");
        S_test_pass=1; $finish;
    end
endmodule
