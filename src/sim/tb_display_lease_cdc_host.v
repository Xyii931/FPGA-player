`timescale 1ns/1ps
// Real host owner, lease CDC, guard, slots, commit CDC and reader FIFO/RAM.
// Only video prepare/retire/pixel references and logical memory remain fixtures.
module tb_display_lease_cdc_host;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    wire S_host_reset;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reset_sync u_host_reset (.I_clk(S_host_clk),.I_async_reset(S_reset),.O_reset(S_host_reset));
    reg S_fixture=1,S_f_valid=0,S_f_result_ready=0,S_cmd_gate=1,S_media_valid=1;
    reg [2:0] S_f_op=0,S_f_slot=0;
    reg [31:0] S_f_token=0;
    reg [31:0] S_tokens[0:5];
    reg S_commit_gate=1,S_allow_apply=1,S_prepare_finish=1,S_retire_finish=1;
    reg S_prepare_busy=0,S_prepare_done_valid=0,S_retire_busy=0,S_retire_done_valid=0;
    reg [31:0] S_prepare_epoch=0,S_retire_epoch=0;
    reg [15:0] S_prepare_tag=0,S_retire_tag=0;
    reg [3:0] S_prepare_error=0,S_retire_error=0;
    reg [1:0] S_old_refs=0,S_task_owned=0,S_mem_enable=3;
    reg S_task_valid=0;
    reg [4:0] S_frame_count=0;
    wire S_frame_start=S_frame_count==0 && !S_reset;
    wire [1:0] S_video_in_use=(S_c_O_active_valid ? S_c_O_active_config[246:245] : 2'b00) |
        (S_c_O_pending_valid ? S_c_O_pending_config[246:245] : 2'b00) | S_old_refs | S_task_owned |
        ((S_c_O_retire_valid && S_c_O_retire_old) ? S_c_O_retire_config[246:245] : 2'b00);
    reg S_publish_gate=1,S_publish_install=1,S_publish_ack=1;
    wire S_publish_ready,S_publish_busy,S_cdc_done,S_cdc_host_fault,S_cdc_video_fault,S_cdc_discard,S_cdc_installed;
    wire [31:0] S_video_version;
    wire [1:0] S_video_authorized;
    reg [137:0] S_publish_saved=0;
    wire [137:0] S_video_leases;
    reg [31:0] S_version_saved=0;
    wire [31:0] S_publish_done_version;
    wire [3:0] S_publish_error;
    wire S_publish_done_valid=S_cdc_done && S_publish_ack;
    reg S_expect_fault=0,S_fake_commit=0;
    integer S_case=0,S_publishes=0,S_commands=0,S_commits=0,S_discards=0;
    reg S_publish_held=0,S_commit_held=0;
    reg S_publish_fire;
    reg [169:0] S_held_publish;
    reg [262:0] S_held_commit;
    reg  S_o_I_start_valid=0;
    wire  S_o_O_start_ready;
    reg [246:0] S_o_I_config=0;
    reg [15:0] S_o_I_tag=0;
    reg  S_o_I_abort=0;
    wire  S_o_O_busy;
    wire  S_o_O_done_valid;
    reg  S_o_I_done_ready=0;
    wire [3:0] S_o_O_error;
    wire [3:0] S_o_O_lease_error;
    wire [3:0] S_o_O_slot_error;
    wire [3:0] S_o_O_commit_error;
    wire [3:0] S_o_O_prepare_error;
    wire [3:0] S_o_O_retire_error;
    wire [15:0] S_o_O_tag;
    wire [31:0] S_o_O_epoch;
    wire [31:0] S_o_O_previous_epoch;
    wire  S_o_O_applied;
    wire  S_o_O_retired;
    wire  S_o_O_cancel_late;
    wire  S_o_O_quarantined;
    wire  S_o_O_response_discarded;
    wire [1:0] S_o_O_acquired_mask;
    wire [1:0] S_o_O_released_mask;
    wire [1:0] S_o_O_active_mask;
    wire  S_o_O_active_valid;
    wire [31:0] S_o_O_active_epoch;
    wire [246:0] S_o_O_active_config;
    wire [1:0] S_o_O_host_reserve;
    wire [1:0] S_o_O_source_idle;
    wire [1:0] S_o_O_source_busy;
    wire  S_o_O_publish_valid;
    wire [137:0] S_o_O_publish_leases;
    wire [31:0] S_o_O_publish_version;
    wire  S_o_O_publish_done_ready;
    wire  S_o_O_commit_valid;
    wire [246:0] S_o_O_commit_config;
    wire [15:0] S_o_O_commit_tag;
    wire  S_o_O_commit_abort;
    wire  S_o_O_commit_done_ready;
    wire [1:0] S_o_O_owned;
    wire [1:0] S_o_O_lease_valid;
    wire [5:0] S_o_O_lease_slots;
    wire [63:0] S_o_O_lease_tokens;
    wire [63:0] S_o_O_lease_generations;
    wire [1:0] S_o_O_lease_resident;
    wire  S_o_O_slot_cmd_valid;
    wire [2:0] S_o_O_slot_cmd_op;
    wire [2:0] S_o_O_slot_cmd_slot;
    wire [1:0] S_o_O_slot_cmd_owner;
    wire [31:0] S_o_O_slot_cmd_token;
    wire [31:0] S_o_O_slot_cmd_generation;
    wire  S_o_O_slot_frame_boundary;
    wire  S_o_O_slot_reader_retired;
    wire  S_o_O_slot_result_ready;
    wire [1:0] S_o_O_video_block;
    wire [1:0] S_o_O_video_reader_stop;
    wire [1:0] S_o_O_video_retire_ack;
    wire [1:0] S_o_O_video_fault;
    display_host_owner u_display_host_owner (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_start_valid(S_o_I_start_valid),
        .O_start_ready(S_o_O_start_ready),
        .I_config(S_o_I_config),
        .I_tag(S_o_I_tag),
        .I_abort(S_o_I_abort),
        .O_busy(S_o_O_busy),
        .O_done_valid(S_o_O_done_valid),
        .I_done_ready(S_o_I_done_ready),
        .O_error(S_o_O_error),
        .O_lease_error(S_o_O_lease_error),
        .O_slot_error(S_o_O_slot_error),
        .O_commit_error(S_o_O_commit_error),
        .O_prepare_error(S_o_O_prepare_error),
        .O_retire_error(S_o_O_retire_error),
        .O_tag(S_o_O_tag),
        .O_epoch(S_o_O_epoch),
        .O_previous_epoch(S_o_O_previous_epoch),
        .O_applied(S_o_O_applied),
        .O_retired(S_o_O_retired),
        .O_cancel_late(S_o_O_cancel_late),
        .O_quarantined(S_o_O_quarantined),
        .O_response_discarded(S_o_O_response_discarded),
        .O_acquired_mask(S_o_O_acquired_mask),
        .O_released_mask(S_o_O_released_mask),
        .O_active_mask(S_o_O_active_mask),
        .O_active_valid(S_o_O_active_valid),
        .O_active_epoch(S_o_O_active_epoch),
        .O_active_config(S_o_O_active_config),
        .O_host_reserve(S_o_O_host_reserve),
        .O_source_idle(S_o_O_source_idle),
        .O_source_busy(S_o_O_source_busy),
        .O_publish_valid(S_o_O_publish_valid),
        .I_publish_ready(S_publish_gate && S_publish_ready),
        .O_publish_leases(S_o_O_publish_leases),
        .O_publish_version(S_o_O_publish_version),
        .I_publish_done_valid(S_publish_done_valid),
        .O_publish_done_ready(S_o_O_publish_done_ready),
        .I_publish_done_version(S_publish_done_version),
        .I_publish_error(S_publish_error),
        .O_commit_valid(S_o_O_commit_valid),
        .I_commit_ready(S_c_O_submit_ready && S_commit_gate),
        .O_commit_config(S_o_O_commit_config),
        .O_commit_tag(S_o_O_commit_tag),
        .O_commit_abort(S_o_O_commit_abort),
        .I_commit_next_epoch(S_c_O_next_epoch),
        .I_commit_done_valid(S_c_O_done_valid || S_fake_commit),
        .O_commit_done_ready(S_o_O_commit_done_ready),
        .I_commit_tag(S_c_O_tag ^ {15'd0,S_fake_commit}),
        .I_commit_epoch(S_c_O_epoch),
        .I_commit_previous_epoch(S_c_O_previous_epoch),
        .I_commit_error(S_c_O_error),
        .I_commit_prepare_error(S_c_O_prepare_error),
        .I_commit_retire_error(S_c_O_retire_error),
        .I_commit_applied(S_c_O_applied),
        .I_commit_retired(S_c_O_retired),
        .I_commit_quarantined(S_c_O_quarantined),
        .O_owned(S_o_O_owned),
        .O_lease_valid(S_o_O_lease_valid),
        .O_lease_slots(S_o_O_lease_slots),
        .O_lease_tokens(S_o_O_lease_tokens),
        .O_lease_generations(S_o_O_lease_generations),
        .O_lease_resident(S_o_O_lease_resident),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_readers(S_m_O_slot_readers),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .O_slot_cmd_valid(S_o_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_m_O_cmd_ready && S_cmd_gate && !S_fixture),
        .O_slot_cmd_op(S_o_O_slot_cmd_op),
        .O_slot_cmd_slot(S_o_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_o_O_slot_cmd_owner),
        .O_slot_cmd_token(S_o_O_slot_cmd_token),
        .O_slot_cmd_generation(S_o_O_slot_cmd_generation),
        .O_slot_frame_boundary(S_o_O_slot_frame_boundary),
        .O_slot_reader_retired(S_o_O_slot_reader_retired),
        .I_slot_result_valid(S_m_O_result_valid && !S_fixture),
        .O_slot_result_ready(S_o_O_slot_result_ready),
        .I_slot_result_error(S_m_O_result_error),
        .I_slot_result_op(S_m_O_result_op),
        .I_slot_result_slot(S_m_O_result_slot),
        .I_slot_result_owner(S_m_O_result_owner),
        .I_slot_result_token(S_m_O_result_token),
        .I_slot_result_generation(S_m_O_result_generation),
        .I_slot_result_base(S_m_O_result_base),
        .I_video_frame_start(S_frame_start),
        .I_video_in_use(S_video_in_use),
        .I_video_reader_ack(S_r_O_retire_ack),
        .I_video_owner_retired(~S_task_owned),
        .I_video_pipeline_retired(2'b11),
        .O_video_block(S_o_O_video_block),
        .O_video_reader_stop(S_o_O_video_reader_stop),
        .O_video_retire_ack(S_o_O_video_retire_ack),
        .O_video_fault(S_o_O_video_fault)
    );
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
    fb_slot_manager u_fb_slot_manager (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(32'd11),
        .I_cmd_valid(S_fixture ? S_f_valid : (S_o_O_slot_cmd_valid && S_cmd_gate)),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_fixture ? S_f_op : S_o_O_slot_cmd_op),
        .I_cmd_slot(S_fixture ? S_f_slot : S_o_O_slot_cmd_slot),
        .I_cmd_owner(S_fixture ? 2'd2 : S_o_O_slot_cmd_owner),
        .I_cmd_token(S_fixture ? S_f_token : S_o_O_slot_cmd_token),
        .I_cmd_generation(S_fixture ? (S_f_slot==5 ? 32'd77 : 32'd11) : S_o_O_slot_cmd_generation),
        .I_cmd_asset(32'd9),
        .I_cmd_layout(3'd0),
        .I_cmd_rotation(2'd0),
        .I_cmd_resident(S_fixture && S_f_slot==5),
        .I_cmd_success(1'b1),
        .I_producer_retired(1'b1),
        .I_memory_retired(1'b1),
        .I_reader_retired(S_fixture ? 1'b1 : S_o_O_slot_reader_retired),
        .I_frame_boundary(S_fixture ? 1'b1 : S_o_O_slot_frame_boundary),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_fixture ? S_f_result_ready : S_o_O_slot_result_ready),
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
    wire  S_c_O_submit_ready;
    wire [31:0] S_c_O_next_epoch;
    wire  S_c_O_busy;
    wire  S_c_O_done_valid;
    wire [3:0] S_c_O_error;
    wire [3:0] S_c_O_prepare_error;
    wire [3:0] S_c_O_retire_error;
    wire [15:0] S_c_O_tag;
    wire [31:0] S_c_O_epoch;
    wire [31:0] S_c_O_previous_epoch;
    wire  S_c_O_applied;
    wire  S_c_O_retired;
    wire  S_c_O_quarantined;
    wire  S_c_O_host_response_discarded;
    wire  S_c_O_pending_valid;
    wire [246:0] S_c_O_pending_config;
    wire [15:0] S_c_O_pending_tag;
    wire [31:0] S_c_O_pending_epoch;
    wire  S_c_O_prepare_valid;
    wire  S_c_O_prepare_abort;
    wire  S_c_O_prepare_done_ready;
    wire  S_c_O_active_valid;
    wire [246:0] S_c_O_active_config;
    wire [15:0] S_c_O_active_tag;
    wire [31:0] S_c_O_active_epoch;
    wire  S_c_O_applied_pulse;
    wire  S_c_O_apply_valid;
    wire  S_c_O_retire_valid;
    wire [246:0] S_c_O_retire_config;
    wire [15:0] S_c_O_retire_tag;
    wire [31:0] S_c_O_retire_epoch;
    wire  S_c_O_retire_old;
    wire  S_c_O_retire_done_ready;
    wire  S_c_O_video_quarantined;
    wire  S_c_O_video_response_discarded;
    frame_commit_cdc u_frame_commit_cdc (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_submit_valid(S_o_O_commit_valid && S_commit_gate),
        .O_submit_ready(S_c_O_submit_ready),
        .I_config(S_o_O_commit_config),
        .I_tag(S_o_O_commit_tag),
        .I_validate_error(4'd0),
        .I_abort(S_o_O_commit_abort),
        .O_next_epoch(S_c_O_next_epoch),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(S_o_O_commit_done_ready && !S_fake_commit),
        .O_error(S_c_O_error),
        .O_prepare_error(S_c_O_prepare_error),
        .O_retire_error(S_c_O_retire_error),
        .O_tag(S_c_O_tag),
        .O_epoch(S_c_O_epoch),
        .O_previous_epoch(S_c_O_previous_epoch),
        .O_applied(S_c_O_applied),
        .O_retired(S_c_O_retired),
        .O_quarantined(S_c_O_quarantined),
        .O_host_response_discarded(S_c_O_host_response_discarded),
        .O_pending_valid(S_c_O_pending_valid),
        .O_pending_config(S_c_O_pending_config),
        .O_pending_tag(S_c_O_pending_tag),
        .O_pending_epoch(S_c_O_pending_epoch),
        .O_prepare_valid(S_c_O_prepare_valid),
        .I_prepare_ready(!S_prepare_busy),
        .O_prepare_abort(S_c_O_prepare_abort),
        .I_prepare_done_valid(S_prepare_done_valid),
        .O_prepare_done_ready(S_c_O_prepare_done_ready),
        .I_prepare_done_tag(S_prepare_tag),
        .I_prepare_done_epoch(S_prepare_epoch),
        .I_prepare_done_error(S_prepare_error),
        .I_frame_start(S_frame_start),
        .I_allow_apply(S_allow_apply),
        .I_video_abort(1'b0),
        .O_active_valid(S_c_O_active_valid),
        .O_active_config(S_c_O_active_config),
        .O_active_tag(S_c_O_active_tag),
        .O_active_epoch(S_c_O_active_epoch),
        .O_applied_pulse(S_c_O_applied_pulse),
        .O_apply_valid(S_c_O_apply_valid),
        .O_retire_valid(S_c_O_retire_valid),
        .I_retire_ready(!S_retire_busy),
        .O_retire_config(S_c_O_retire_config),
        .O_retire_tag(S_c_O_retire_tag),
        .O_retire_epoch(S_c_O_retire_epoch),
        .O_retire_old(S_c_O_retire_old),
        .I_retire_done_valid(S_retire_done_valid),
        .O_retire_done_ready(S_c_O_retire_done_ready),
        .I_retire_done_tag(S_retire_tag),
        .I_retire_done_epoch(S_retire_epoch),
        .I_retire_done_error(S_retire_error),
        .O_video_quarantined(S_c_O_video_quarantined),
        .O_video_response_discarded(S_c_O_video_response_discarded)
    );
    wire  S_r_O_task_ready;
    wire  S_r_O_line_valid;
    wire [3:0] S_r_O_line_error;
    wire [3:0] S_r_O_line_memory_error;
    wire [2:0] S_r_O_line_slot;
    wire [20:0] S_r_O_line_base;
    wire [8:0] S_r_O_line_y;
    wire  S_r_O_line_bank;
    wire [31:0] S_r_O_line_token;
    wire [31:0] S_r_O_line_generation;
    wire [31:0] S_r_O_line_epoch;
    wire [31:0] S_r_O_line_deadline;
    wire [15:0] S_r_O_line_tag;
    wire [9:0] S_r_O_line_accepted;
    wire [9:0] S_r_O_line_retired;
    wire [1:0] S_r_O_read_ready;
    wire [1:0] S_r_O_pixel_valid;
    wire [63:0] S_r_O_rgba;
    wire [1:0] S_r_O_pixel_bank;
    wire [19:0] S_r_O_pixel_x;
    wire [63:0] S_r_O_pixel_token;
    wire [63:0] S_r_O_pixel_generation;
    wire [63:0] S_r_O_pixel_epoch;
    wire [31:0] S_r_O_pixel_tag;
    wire [1:0] S_r_O_release_ready;
    wire [3:0] S_r_O_bank_valid;
    wire [3:0] S_r_O_bank_reserved;
    wire [11:0] S_r_O_bank_slots;
    wire [35:0] S_r_O_bank_rows;
    wire [127:0] S_r_O_bank_tokens;
    wire [127:0] S_r_O_bank_generations;
    wire [127:0] S_r_O_bank_epochs;
    wire [63:0] S_r_O_bank_tags;
    wire [1:0] S_r_O_retire_ack;
    wire [1:0] S_r_O_host_retired;
    wire [1:0] S_r_O_host_busy;
    wire [1:0] S_r_O_host_tag_exhausted;
    wire [1:0] S_r_O_release_discarded;
    wire [1:0] S_r_O_event_discarded;
    wire [1:0] S_r_O_response_discarded;
    wire [1:0] S_r_O_mem_valid;
    wire [41:0] S_r_O_mem_addr;
    wire [63:0] S_r_O_mem_tag;
    wire [63:0] S_r_O_mem_token;
    wire [63:0] S_r_O_mem_generation;
    wire [63:0] S_r_O_mem_deadline;
    wire [1:0] S_r_O_mem_ready;
    wire  S_r_O_line_source;
    fb_reader u_fb_reader (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_lease_valid(S_o_O_lease_valid),
        .I_lease_slot(S_o_O_lease_slots),
        .I_lease_token(S_o_O_lease_tokens),
        .I_lease_generation(S_o_O_lease_generations),
        .I_task_valid(S_task_valid),
        .O_task_ready(S_r_O_task_ready),
        .I_task_slot(S_video_leases[132:130]),
        .I_task_base(21'd0),
        .I_task_y(9'd7),
        .I_task_bank(1'b0),
        .I_task_token(S_video_leases[97:66]),
        .I_task_generation(S_video_leases[33:2]),
        .I_task_epoch(32'd1),
        .I_task_deadline(32'h7fffffff),
        .I_task_tag(16'habcd),
        .O_line_valid(S_r_O_line_valid),
        .I_line_ready(1'b1),
        .O_line_error(S_r_O_line_error),
        .O_line_memory_error(S_r_O_line_memory_error),
        .O_line_slot(S_r_O_line_slot),
        .O_line_base(S_r_O_line_base),
        .O_line_y(S_r_O_line_y),
        .O_line_bank(S_r_O_line_bank),
        .O_line_token(S_r_O_line_token),
        .O_line_generation(S_r_O_line_generation),
        .O_line_epoch(S_r_O_line_epoch),
        .O_line_deadline(S_r_O_line_deadline),
        .O_line_tag(S_r_O_line_tag),
        .O_line_accepted(S_r_O_line_accepted),
        .O_line_retired(S_r_O_line_retired),
        .I_read_valid(2'b00),
        .O_read_ready(S_r_O_read_ready),
        .I_read_bank(2'b00),
        .I_read_x(20'd0),
        .O_pixel_valid(S_r_O_pixel_valid),
        .O_rgba(S_r_O_rgba),
        .O_pixel_bank(S_r_O_pixel_bank),
        .O_pixel_x(S_r_O_pixel_x),
        .O_pixel_token(S_r_O_pixel_token),
        .O_pixel_generation(S_r_O_pixel_generation),
        .O_pixel_epoch(S_r_O_pixel_epoch),
        .O_pixel_tag(S_r_O_pixel_tag),
        .I_release_valid(2'b00),
        .O_release_ready(S_r_O_release_ready),
        .I_release_bank(2'b00),
        .I_release_token(64'd0),
        .I_release_generation(64'd0),
        .I_release_epoch(64'd0),
        .I_release_tag(32'd0),
        .O_bank_valid(S_r_O_bank_valid),
        .O_bank_reserved(S_r_O_bank_reserved),
        .O_bank_slots(S_r_O_bank_slots),
        .O_bank_rows(S_r_O_bank_rows),
        .O_bank_tokens(S_r_O_bank_tokens),
        .O_bank_generations(S_r_O_bank_generations),
        .O_bank_epochs(S_r_O_bank_epochs),
        .O_bank_tags(S_r_O_bank_tags),
        .I_retire_request(S_o_O_video_reader_stop),
        .O_retire_ack(S_r_O_retire_ack),
        .O_host_retired(S_r_O_host_retired),
        .O_host_busy(S_r_O_host_busy),
        .O_host_tag_exhausted(S_r_O_host_tag_exhausted),
        .O_release_discarded(S_r_O_release_discarded),
        .O_event_discarded(S_r_O_event_discarded),
        .O_response_discarded(S_r_O_response_discarded),
        .O_mem_valid(S_r_O_mem_valid),
        .I_mem_ready(S_mem_enable),
        .O_mem_addr(S_r_O_mem_addr),
        .O_mem_tag(S_r_O_mem_tag),
        .O_mem_token(S_r_O_mem_token),
        .O_mem_generation(S_r_O_mem_generation),
        .O_mem_deadline(S_r_O_mem_deadline),
        .I_mem_valid(S_r_O_mem_valid & S_mem_enable),
        .O_mem_ready(S_r_O_mem_ready),
        .I_mem_data(64'h336699ff336699ff),
        .I_mem_tag(S_r_O_mem_tag),
        .I_mem_token(S_r_O_mem_token),
        .I_mem_generation(S_r_O_mem_generation),
        .I_mem_error(8'd0),
        .I_task_source(1'b0),
        .O_line_source(S_r_O_line_source)
    );

    task fail;
        input [767:0] message;
        begin $display("FAIL: host owner case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #10000000; fail("watchdog timeout"); end
    always @(posedge S_video_clk or posedge S_reset) begin
        if(S_reset) begin
            S_frame_count<=0; S_prepare_busy<=0; S_prepare_done_valid<=0; S_retire_busy<=0;
            S_retire_done_valid<=0; S_prepare_epoch<=0; S_prepare_tag<=0; S_retire_epoch<=0; S_retire_tag<=0;
            S_old_refs<=0; S_task_owned<=0;
        end else begin
            S_frame_count<=S_frame_count+1'b1;
            if(S_c_O_prepare_valid && !S_prepare_busy) begin
                S_prepare_busy<=1; S_prepare_epoch<=S_c_O_pending_epoch; S_prepare_tag<=S_c_O_pending_tag;
            end
            if(S_prepare_busy && S_prepare_finish && (S_prepare_error!=0 ||
                (S_video_authorized & S_c_O_pending_config[246:245])==S_c_O_pending_config[246:245]))
                S_prepare_done_valid<=1;
            if(S_prepare_done_valid && S_c_O_prepare_done_ready) begin S_prepare_busy<=0; S_prepare_done_valid<=0; end
            if(S_c_O_retire_valid && !S_retire_busy) begin
                S_retire_busy<=1; S_retire_epoch<=S_c_O_retire_epoch; S_retire_tag<=S_c_O_retire_tag;
                if(S_c_O_retire_old) S_old_refs<=S_c_O_retire_config[246:245];
            end
            if(S_retire_busy && S_retire_finish) S_retire_done_valid<=1;
            if(S_retire_done_valid && S_c_O_retire_done_ready) begin
                S_retire_busy<=0; S_retire_done_valid<=0; S_old_refs<=0;
            end
            if(S_task_valid && S_r_O_task_ready) S_task_owned[0]<=1;
            if(S_r_O_line_valid) S_task_owned[S_r_O_line_source]<=0;
        end
    end
    always @(posedge S_host_clk) if(!S_reset && !S_host_reset) begin
        S_publish_fire=S_o_O_publish_valid && S_publish_gate && S_publish_ready;
        if(S_publish_fire) begin
            S_publish_saved=S_o_O_publish_leases; S_version_saved=S_o_O_publish_version;
            S_publishes=S_publishes+1;
        end
        if(S_publish_held && (!S_o_O_publish_valid ||
            S_held_publish!=={S_o_O_publish_version,S_o_O_publish_leases})) fail("publisher request changed before acceptance");
        S_publish_held=S_o_O_publish_valid && !S_publish_fire;
        S_held_publish={S_o_O_publish_version,S_o_O_publish_leases};
        if(S_commit_held && (!S_o_O_commit_valid || S_held_commit!=={S_o_O_commit_tag,S_o_O_commit_config}))
            fail("commit request withdrawn or mutated under backpressure");
        S_commit_held=S_o_O_commit_valid && !(S_c_O_submit_ready && S_commit_gate);
        S_held_commit={S_o_O_commit_tag,S_o_O_commit_config};
        if(S_o_O_commit_valid && S_c_O_submit_ready && S_commit_gate) begin
            if(S_o_O_source_busy!=0 || S_o_O_host_reserve!=0 || S_publish_busy || S_video_leases[137:136]!==S_o_O_lease_valid)
                fail("commit preceded installed lease or guard release");
            S_commits=S_commits+1;
        end
        if(S_o_O_slot_cmd_valid && S_m_O_cmd_ready && S_cmd_gate && !S_fixture) begin
            S_commands=S_commands+1;
            if(!S_o_O_host_reserve[S_o_O_slot_cmd_owner[0]] || !S_o_O_video_block[S_o_O_slot_cmd_owner[0]])
                fail("real slot mutation escaped source reservation");
            if(S_o_O_slot_cmd_op==2 && !S_o_O_slot_frame_boundary)
                fail("acquire bypassed held frame permission");
            if(S_o_O_slot_cmd_op==3 && (!S_o_O_slot_reader_retired ||
                !S_r_O_retire_ack[S_o_O_slot_cmd_owner[0]] || S_task_owned[S_o_O_slot_cmd_owner[0]]))
                fail("release bypassed actual reader retirement proof");
        end
        #1;
        if(S_o_O_response_discarded) S_discards=S_discards+1;
        if(!S_expect_fault && (S_o_O_quarantined || |S_o_O_video_fault || S_cdc_host_fault || S_cdc_video_fault)) fail("unexpected resource quarantine");
    end
    function [68:0] source_lease;
        input [137:0] leases;
        input source;
        begin source_lease={leases[136+source],leases[130+source*3+:3],leases[66+source*32+:32],
            leases[2+source*32+:32],leases[source]}; end
    endfunction
    // Complete leases cross only the real request FIFO; completion crosses u_results.
    display_lease_cdc u_display_lease_cdc (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_publish_valid(S_o_O_publish_valid && S_publish_gate),.O_publish_ready(S_publish_ready),
        .I_publish_leases(S_o_O_publish_leases),.I_publish_version(S_o_O_publish_version),
        .O_done_valid(S_cdc_done),.I_done_ready(S_o_O_publish_done_ready && S_publish_ack),
        .O_done_version(S_publish_done_version),.O_error(S_publish_error),.O_host_busy(S_publish_busy),
        .O_host_quarantined(S_cdc_host_fault),.O_host_response_discarded(S_cdc_discard),
        .I_video_install_enable(S_publish_install),.I_video_block(S_o_O_video_block),
        .I_video_in_use(S_video_in_use),.I_video_owner_retired(~S_task_owned),
        .I_video_pipeline_retired(2'b11),.I_video_guard_fault(S_o_O_video_fault),
        .I_video_query_config(S_c_O_pending_valid ? S_c_O_pending_config : S_c_O_active_config),
        .O_video_leases(S_video_leases),.O_video_version(S_video_version),.O_video_installed(S_cdc_installed),
        .O_video_quarantined(S_cdc_video_fault),.O_video_authorized(S_video_authorized)
    );
    reg [137:0] S_previous_video_leases=0;
    always @(posedge S_video_clk) begin
        #1;
        if(S_reset) S_previous_video_leases=0;
        else if(S_cdc_installed) begin
            if((source_lease(S_video_leases,0)!==source_lease(S_previous_video_leases,0) && !S_o_O_video_block[0]) ||
                (source_lease(S_video_leases,1)!==source_lease(S_previous_video_leases,1) && !S_o_O_video_block[1]))
                fail("real CDC installation changed an unreserved source");
            if(S_video_version!==S_version_saved || S_video_leases!==S_publish_saved)
                fail("real FIFO installation differed from accepted host snapshot");
            S_previous_video_leases=S_video_leases;
        end
    end
    function [246:0] make_config;
        input [1:0] mask;
        input from_source;
        input [2:0] a,b;
        begin make_config={mask,from_source,{b,a},{S_tokens[b],S_tokens[a]},
            {(b==5 ? 32'd77 : 32'd11),(a==5 ? 32'd77 : 32'd11)},
            {(b==5),(a==5)},3'd0,16'd60,17'd0,4'd0,4'd0,5'd8,3'd0,2'd0,1'b0,1'b0,
            18'd0,2'b00,32'hc202c101}; end
    endfunction
    task fixture_cmd;
        input [2:0] op,slot;
        begin
            @(negedge S_host_clk); S_f_op=op; S_f_slot=slot; S_f_token=op==0 ? 0 : S_tokens[slot]; S_f_valid=1;
            @(posedge S_host_clk); while(!S_m_O_cmd_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_f_valid=0; wait(S_m_O_result_valid); #1;
            if(S_m_O_result_error!=0) fail("real slot fixture preparation");
            if(op==0) S_tokens[slot]=S_m_O_result_token;
            @(negedge S_host_clk); S_f_result_ready=1; @(negedge S_host_clk); S_f_result_ready=0;
        end
    endtask
    task reset_all;
        integer slot;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_fixture=1; S_f_valid=0; S_f_result_ready=0;
            S_o_I_start_valid=0; S_o_I_done_ready=0; S_o_I_abort=0;
            S_cmd_gate=1; S_media_valid=1; S_commit_gate=1; S_allow_apply=1; S_prepare_finish=1; S_retire_finish=1;
            S_prepare_error=0; S_retire_error=0; S_mem_enable=3; S_task_valid=0;
            S_publish_gate=1; S_publish_install=1; S_publish_ack=1; S_expect_fault=0; S_fake_commit=0;
            S_publish_held=0; S_commit_held=0;
            repeat(6) @(negedge S_video_clk); S_reset=0; wait(!S_host_reset);
            for(slot=0;slot<6;slot=slot+1) begin fixture_cmd(0,slot); fixture_cmd(1,slot); end
            @(negedge S_host_clk); S_fixture=0;
            S_publishes=0; S_commands=0; S_commits=0; S_discards=0;
        end
    endtask
    task start;
        input [246:0] payload;
        input [15:0] tag;
        begin
            @(negedge S_host_clk); S_o_I_config=payload; S_o_I_tag=tag; S_o_I_start_valid=1;
            @(posedge S_host_clk); while(!S_o_O_start_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_o_I_start_valid=0; S_o_I_config=0; S_o_I_tag=0;
        end
    endtask
    task result;
        input [3:0] error;
        input [1:0] owned,acquired,released;
        input applied;
        reg [90:0] saved;
        begin
            wait(S_o_O_done_valid); #1;
            if(S_o_O_error!==error || S_o_O_owned!==owned || S_o_O_acquired_mask!==acquired ||
                S_o_O_released_mask!==released || S_o_O_applied!==applied || S_o_O_quarantined)
                fail("transaction terminal or real lease effect fact");
            if(S_o_O_host_reserve!=0 || S_o_O_source_busy!=0) fail("result preceded guard four phase clear");
            if(S_o_O_active_valid && S_o_O_active_epoch!==S_c_O_active_epoch)
                fail("host active epoch observation changed on failed transaction");
            saved={S_o_O_error,S_o_O_tag,S_o_O_epoch,S_o_O_previous_epoch,S_o_O_acquired_mask,
                S_o_O_released_mask,S_o_O_applied,S_o_O_retired,S_o_O_cancel_late};
            repeat(8) begin @(negedge S_host_clk);
                if(!S_o_O_done_valid || S_o_O_start_ready || saved!=={S_o_O_error,S_o_O_tag,S_o_O_epoch,
                    S_o_O_previous_epoch,S_o_O_acquired_mask,S_o_O_released_mask,S_o_O_applied,S_o_O_retired,S_o_O_cancel_late})
                    fail("transaction result not held");
            end
            S_o_I_done_ready=1; @(negedge S_host_clk); S_o_I_done_ready=0;
        end
    endtask
    initial begin
        S_case=1; reset_all;
        start(make_config(1,0,0,1),16'h1001); result(0,1,1,0,1);
        if(S_commands!=1 || S_publishes!=1 || S_commits!=1 || S_o_O_active_mask!=1) fail("initial lock publish commit chain");
        start(make_config(3,0,0,1),16'h1002); result(0,3,2,0,1);
        if(S_commands!=2 || S_publishes!=2) fail("existing source lease was reacquired");
        start(make_config(2,1,0,1),16'h1003); result(0,2,0,1,1);
        if(S_commands!=3 || S_publishes!=3 || S_m_O_slot_readers[0] || !S_m_O_slot_readers[4])
            fail("old source not truly released after commit");

        S_case=2; reset_all; start(make_config(1,0,0,1),16'h2001); result(0,1,1,0,1);
        S_prepare_error=2;
        start(make_config(3,0,0,1),16'h2002); result(5,1,2,2,0);
        if(S_o_O_active_mask!=1 || !S_m_O_slot_readers[0] || S_m_O_slot_readers[4] ||
            S_o_O_commit_error!=2 || S_o_O_prepare_error!=2) fail("failed candidate damaged old foreground lease");

        S_case=3; reset_all; S_cmd_gate=0;
        start(make_config(1,0,0,1),16'h3001); wait(S_o_O_slot_cmd_valid);
        @(negedge S_host_clk); S_o_I_abort=1;
        repeat(12) begin @(negedge S_host_clk); if(!S_o_O_slot_cmd_valid || S_o_O_done_valid)
            fail("late acquire cancel withdrew real slot command"); end
        S_cmd_gate=1; result(3,0,1,1,0); S_o_I_abort=0;
        if(S_commits!=0 || S_publishes!=2 || S_m_O_slot_readers[0] || S_o_O_lease_error!=5 || !S_o_O_cancel_late)
            fail("late acquired lock not cleaned after publication");

        S_case=4; reset_all; S_publish_gate=0;
        start(make_config(1,0,0,1),16'h4001); wait(S_o_O_publish_valid);
        repeat(10) begin @(negedge S_host_clk); if(S_o_O_host_reserve!=1 || S_o_O_video_block!=1 || S_o_O_commit_valid)
            fail("publication queue backpressure released source guard"); end
        S_publish_gate=1; S_publish_ack=0; wait(S_publish_busy); wait(S_cdc_done);
        if(S_video_version!=1 || S_video_leases[137:136]!=1) fail("result arrived before real snapshot installation");
        repeat(12) begin @(negedge S_host_clk); if(S_o_O_host_reserve!=1 || S_o_O_commit_valid || S_o_O_done_valid)
            fail("queue acceptance substituted for video installed acknowledgement"); end
        S_publish_ack=1; result(0,1,1,0,1);

        S_case=5; reset_all; S_publish_install=0;
        start(make_config(1,0,0,1),16'h5001); wait(S_publish_busy);
        repeat(20) begin @(negedge S_video_clk);
            if(S_video_version!=0 || S_video_authorized!=0 || S_o_O_host_reserve!=1 || S_commits!=0)
                fail("uninstalled real CDC request authorized or committed source");
        end
        S_publish_install=1; result(0,1,1,0,1);
        #1; if(S_video_version!=1 || S_video_authorized!=1) fail("installed lease not authorized after guard clear");

        S_case=6; reset_all; S_commit_gate=0;
        start(make_config(1,0,0,1),16'h6001); wait(S_o_O_commit_valid);
        @(negedge S_host_clk); S_o_I_abort=1;
        repeat(10) begin @(negedge S_host_clk); if(!S_o_O_commit_valid || !S_o_O_commit_abort || S_o_O_done_valid)
            fail("cancel withdrew presented commit before true acceptance"); end
        S_commit_gate=1; result(3,0,1,1,0); S_o_I_abort=0;
        if(S_o_O_epoch!=0 || S_o_O_active_valid) fail("unstarted remote commit fabricated active epoch");

        S_case=7; reset_all; start(make_config(1,0,0,1),16'h7001); result(0,1,1,0,1);
        start(make_config(1,0,2,1),16'h7002); result(2,1,0,0,0);
        if(S_commands!=1 || S_o_O_active_mask!=1) fail("busy source overwritten to satisfy third target");

        S_case=8; reset_all; S_media_valid=0;
        start(make_config(1,0,0,1),16'h8001); result(4,0,0,0,0);
        if(S_commits!=0 || S_publishes!=0 || S_o_O_slot_error!=2) fail("invalidated slot acquired or published");
        start(make_config(1,0,5,1),16'h8002); result(0,1,1,0,1);
        if(!S_o_O_lease_resident[0] || S_o_O_lease_generations[31:0]!=77) fail("resident safety page lease rejected");

        S_case=9; reset_all; S_prepare_finish=0;
        start(make_config(1,0,0,1),16'h9001); wait(S_prepare_busy);
        @(negedge S_host_clk); S_o_I_abort=1;
        repeat(12) begin @(negedge S_host_clk); if(S_o_O_done_valid || S_o_O_slot_cmd_op==3 && S_o_O_slot_cmd_valid)
            fail("commit cancellation reclaimed lock before real prepare terminal"); end
        S_prepare_finish=1; result(3,0,1,1,0); S_o_I_abort=0;

        S_case=10; reset_all; start(make_config(1,0,0,1),16'ha001); result(0,1,1,0,1);
        S_mem_enable=0;
        @(negedge S_video_clk); S_task_valid=1;
        @(posedge S_video_clk); while(!S_r_O_task_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_task_valid=0;
        wait(S_r_O_mem_valid[0]);
        start(make_config(2,1,0,1),16'ha002);
        wait(S_c_O_active_config[246:245]==2);
        repeat(80) begin @(negedge S_host_clk); if(!S_o_O_owned[0] || S_o_O_done_valid)
            fail("old source lock released with real reader task outstanding"); end
        @(negedge S_host_clk); S_host_run=0;
        repeat(12) begin @(negedge S_video_clk); if(!S_o_O_owned[0]) fail("host stop invented reader retirement"); end
        S_host_run=1; S_mem_enable=3;
        result(0,2,2,1,1);

        S_case=11; reset_all; start(make_config(1,0,0,1),16'hb001); result(0,1,1,0,1);
        S_retire_finish=0;
        start(make_config(2,1,0,1),16'hb002); wait(S_retire_busy);
        @(negedge S_host_clk); S_o_I_abort=1;
        repeat(12) begin @(negedge S_host_clk); if(S_o_O_done_valid || S_o_O_owned!=3)
            fail("applied commit cleaned old lease before actual old config retirement"); end
        S_retire_finish=1; result(0,2,2,1,1); S_o_I_abort=0;
        if(!S_o_O_cancel_late || S_o_O_active_mask!=2) fail("late abort rolled back actual applied configuration");

        S_case=12; reset_all; S_publish_install=0;
        start(make_config(1,0,0,1),16'hc001); wait(S_publish_busy);
        @(negedge S_video_clk); S_video_run=0;
        repeat(16) begin @(negedge S_host_clk); if(S_o_O_commit_valid || S_o_O_done_valid || S_o_O_host_reserve!=1)
            fail("video stop fabricated lease delivery"); end
        S_publish_install=1; S_video_run=1; result(0,1,1,0,1);

        S_case=13; reset_all; S_expect_fault=1;
        // Deliberately disagree with guard proof at the publisher boundary; real error travels back.
        force u_display_lease_cdc.I_video_owner_retired=2'b10;
        start(make_config(1,0,0,1),16'hd001); wait(S_o_O_done_valid); #1;
        if(S_o_O_error!=7 || !S_o_O_quarantined || S_o_O_owned!=1 || S_o_O_host_reserve!=1 || S_o_O_commit_valid)
            fail("failed lease publication silently released unknown authority");
        release u_display_lease_cdc.I_video_owner_retired;
        if(S_publish_error!=3 || !S_cdc_video_fault || !S_cdc_host_fault || S_video_version!=0)
            fail("real publication error failed to retain old installed authority");

        S_case=14; reset_all; start(make_config(1,0,0,1),16'he001); result(0,1,1,0,1);
        S_retire_error=4; S_expect_fault=1;
        start(make_config(2,1,0,1),16'he002); wait(S_o_O_done_valid); #1;
        if(S_o_O_error!=8 || !S_o_O_quarantined || !S_o_O_applied || S_o_O_active_mask!=2 || S_o_O_owned!=3)
            fail("applied retirement failure guessed safe lease cleanup");

        S_case=15; reset_all;
        start(make_config(1,0,0,1),16'hf001); wait(u_display_host_owner.S_state==3);
        @(negedge S_host_clk); S_o_I_abort=1;
        result(3,0,0,0,0); S_o_I_abort=0;
        if(S_commands!=0 || S_publishes!=0 || S_commits!=0) fail("early cancel invented resource side effects");

        S_case=16; reset_all;
        start(make_config(0,0,0,1),16'hf002); result(1,0,0,0,0);
        if(S_commands!=0 || S_publishes!=0 || S_commits!=0) fail("invalid config acquired resources");

        S_case=17; reset_all; S_expect_fault=1;
        force u_display_host_owner.O_publish_version=32'hffffffff;
        start(make_config(1,0,0,1),16'hf003); wait(S_o_O_done_valid); #1;
        release u_display_host_owner.O_publish_version;
        if(S_o_O_error!=9 || !S_o_O_quarantined || S_o_O_owned!=1 || S_o_O_host_reserve!=1 || S_publishes!=0)
            fail("exhausted publication version wrapped or lost real lock");
        S_case=18; reset_all;
        start(make_config(1,0,0,1),16'hf004); wait(S_c_O_done_valid);
        @(negedge S_host_clk); S_fake_commit=1;
        @(negedge S_host_clk);
        if(S_discards!=1 || S_o_O_done_valid || S_o_O_active_valid)
            fail("wrong commit identity advanced active resource owner");
        S_fake_commit=0; result(0,1,1,0,1);
        $display("PASS: host owner with real lease CDC/locks/guard/commit CDC/reader retirement");
        S_test_pass=1; $finish;
    end
endmodule
