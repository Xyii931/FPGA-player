// Real lock/publication/commit/video resource chain. All endpoints share global reset.
// Deadlines and audio evidence are video-domain inputs, supplied reliably by their owners.
// Logical memory/slot interfaces require real acceptance and retirement; no fixed delays.
module display_resource_pipeline (
    input wire I_host_clk,
    input wire I_video_clk,
    input wire I_async_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [246:0] I_config,
    input wire [15:0] I_tag,
    input wire I_abort,
    output wire O_busy,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [3:0] O_error,
    output wire [3:0] O_lease_error,
    output wire [3:0] O_slot_error,
    output wire [3:0] O_commit_error,
    output wire [3:0] O_prepare_error,
    output wire [3:0] O_retire_error,
    input wire I_video_allow_apply,
    input wire I_video_abort,
    input wire I_audio_ready,
    input wire [31:0] I_audio_epoch,
    output wire O_host_quarantined,
    output wire O_host_response_discarded,
    output wire O_video_quarantined,
    output wire [15:0] O_tag,
    output wire [31:0] O_epoch,
    output wire [31:0] O_previous_epoch,
    output wire O_applied,
    output wire O_retired,
    output wire O_cancel_late,
    output wire [1:0] O_acquired_mask,
    output wire [1:0] O_released_mask,
    output wire [1:0] O_host_active_mask,
    output wire O_host_active_valid,
    output wire [31:0] O_host_active_epoch,
    output wire [246:0] O_host_active_config,
    output wire [1:0] O_host_reserve,
    output wire [1:0] O_source_idle,
    output wire [1:0] O_source_busy,
    output wire [1:0] O_owned,
    output wire [1:0] O_lease_valid,
    output wire [5:0] O_lease_slots,
    output wire [63:0] O_lease_tokens,
    output wire [63:0] O_lease_generations,
    output wire [1:0] O_lease_resident,
    input wire [17:0] I_slot_states,
    input wire [17:0] I_slot_readers,
    input wire [191:0] I_slot_tokens,
    input wire [191:0] I_slot_generations,
    input wire [5:0] I_slot_resident,
    output wire O_slot_cmd_valid,
    input wire I_slot_cmd_ready,
    output wire [2:0] O_slot_cmd_op,
    output wire [2:0] O_slot_cmd_slot,
    output wire [1:0] O_slot_cmd_owner,
    output wire [31:0] O_slot_cmd_token,
    output wire [31:0] O_slot_cmd_generation,
    output wire O_slot_frame_boundary,
    output wire O_slot_reader_retired,
    input wire I_slot_result_valid,
    output wire O_slot_result_ready,
    input wire [3:0] I_slot_result_error,
    input wire [2:0] I_slot_result_op,
    input wire [2:0] I_slot_result_slot,
    input wire [1:0] I_slot_result_owner,
    input wire [31:0] I_slot_result_token,
    input wire [31:0] I_slot_result_generation,
    input wire [20:0] I_slot_result_base,
    output wire [1:0] O_source_block,
    output wire [1:0] O_reader_stop,
    output wire [1:0] O_video_retire_ack,
    output wire [1:0] O_source_fault,
    output wire [137:0] O_video_leases,
    output wire [31:0] O_video_lease_version,
    output wire [1:0] O_video_authorized,
    output wire [31:0] O_next_epoch,
    output wire O_pending_valid,
    output wire [246:0] O_pending_config,
    output wire [15:0] O_pending_tag,
    output wire [31:0] O_pending_epoch,
    output wire O_video_active_valid,
    output wire [246:0] O_video_active_config,
    output wire [15:0] O_video_active_tag,
    output wire O_video_response_discarded,
    input wire I_prepare_deadline_valid,
    input wire [31:0] I_prepare_deadline_epoch,
    input wire [63:0] I_prepare_deadlines,
    input wire I_scan_deadline_valid,
    input wire [8:0] I_scan_deadline_y,
    input wire [31:0] I_scan_deadline_epoch,
    input wire [31:0] I_scan_deadline,
    input wire I_scan_stop,
    output wire O_scan_stop_ack,
    output wire [1:0] O_reader_retire_ack,
    output wire [1:0] O_reader_host_retired,
    output wire [1:0] O_source_in_use,
    output wire [1:0] O_source_owner_retired,
    output wire [1:0] O_source_pipeline_retired,
    output wire [8:0] O_prefetch_y,
    output wire [31:0] O_video_active_epoch,
    output wire O_frame_start,
    output wire O_local_applied,
    output wire [3:0] O_bank_busy,
    output wire O_valid,
    output wire O_hsync,
    output wire O_vsync,
    output wire O_de,
    output wire [15:0] O_x,
    output wire [15:0] O_y,
    output wire [23:0] O_rgb,
    output wire [31:0] O_pixel_epoch,
    output wire [15:0] O_pixel_tag,
    output wire O_repeated,
    output wire O_pixel_fault,
    output wire O_video_und,
    output wire [31:0] O_und_count,
    output wire [31:0] O_line_error_count,
    output wire [1:0] O_mem_valid,
    input wire [1:0] I_mem_ready,
    output wire [41:0] O_mem_addr,
    output wire [63:0] O_mem_tag,
    output wire [63:0] O_mem_token,
    output wire [63:0] O_mem_generation,
    output wire [63:0] O_mem_deadline,
    input wire [1:0] I_mem_valid,
    output wire [1:0] O_mem_ready,
    input wire [63:0] I_mem_data,
    input wire [63:0] I_mem_tag,
    input wire [63:0] I_mem_token,
    input wire [63:0] I_mem_generation,
    input wire [7:0] I_mem_error
);
    wire S_o_O_start_ready;
    wire S_o_O_busy;
    wire S_o_O_quarantined;
    wire S_o_O_response_discarded;
    wire S_o_O_publish_valid;
    wire S_l_O_publish_ready;
    wire [137:0] S_o_O_publish_leases;
    wire [31:0] S_o_O_publish_version;
    wire S_l_O_done_valid;
    wire S_o_O_publish_done_ready;
    wire [31:0] S_l_O_done_version;
    wire [3:0] S_l_O_error;
    wire S_o_O_commit_valid;
    wire S_c_O_submit_ready;
    wire [246:0] S_o_O_commit_config;
    wire [15:0] S_o_O_commit_tag;
    wire S_o_O_commit_abort;
    wire S_c_O_done_valid;
    wire S_o_O_commit_done_ready;
    wire [15:0] S_c_O_tag;
    wire [31:0] S_c_O_epoch;
    wire [31:0] S_c_O_previous_epoch;
    wire [3:0] S_c_O_error;
    wire [3:0] S_c_O_prepare_error;
    wire [3:0] S_c_O_retire_error;
    wire S_c_O_applied;
    wire S_c_O_retired;
    wire S_l_O_host_busy;
    wire S_l_O_host_quarantined;
    wire S_l_O_host_response_discarded;
    wire S_l_O_video_installed;
    wire S_l_O_video_quarantined;
    wire S_c_O_busy;
    wire S_c_O_quarantined;
    wire S_c_O_host_response_discarded;
    wire S_c_O_prepare_valid;
    wire S_p_O_prepare_ready;
    wire S_c_O_prepare_abort;
    wire S_p_O_prepare_done_valid;
    wire S_c_O_prepare_done_ready;
    wire [15:0] S_p_O_prepare_tag;
    wire [31:0] S_p_O_prepare_epoch;
    wire [3:0] S_p_O_prepare_error;
    wire [31:0] S_c_O_active_epoch;
    wire S_c_O_applied_pulse;
    wire S_c_O_apply_valid;
    wire S_c_O_retire_valid;
    wire S_p_O_retire_ready;
    wire [246:0] S_c_O_retire_config;
    wire [15:0] S_c_O_retire_tag;
    wire [31:0] S_c_O_retire_epoch;
    wire S_c_O_retire_old;
    wire S_p_O_retire_done_valid;
    wire S_c_O_retire_done_ready;
    wire [15:0] S_p_O_retire_tag;
    wire [31:0] S_p_O_retire_epoch;
    wire [3:0] S_p_O_retire_error;
    wire S_c_O_video_quarantined;
    wire S_p_O_can_apply;
    wire S_p_O_busy;
    wire S_p_O_contract_fault;
    wire S_p_O_quarantined;
    wire S_host_reset;
    wire S_video_reset;
    reg S_video_fault;
    (* ASYNC_REG="TRUE" *) reg S_fault_meta,S_fault_sync;
    wire S_video_resource_fault=S_p_O_contract_fault || S_p_O_quarantined ||
        S_l_O_video_quarantined || S_c_O_video_quarantined || |O_source_fault;
    wire S_host_fault=S_o_O_quarantined || S_l_O_host_quarantined || S_c_O_quarantined || S_fault_sync;
    wire S_allow_apply=I_video_allow_apply && S_p_O_can_apply && !O_video_quarantined &&
        (!O_pending_config[52] || (I_audio_ready && I_audio_epoch==O_pending_epoch));
    assign O_start_ready=S_o_O_start_ready && !S_host_fault;
    assign O_busy=S_o_O_busy || S_l_O_host_busy || S_c_O_busy || S_host_fault;
    assign O_host_quarantined=S_host_fault;
    assign O_host_response_discarded=S_o_O_response_discarded ||
        S_l_O_host_response_discarded || S_c_O_host_response_discarded;
    assign O_video_quarantined=S_video_fault || S_video_resource_fault;
    // The owner validates the original range. Recheck the CURRENT real host lease at commit.
    reg C_host_lease_ok;
    integer C_i;
    always @* begin
        C_host_lease_ok=1;
        for(C_i=0;C_i<2;C_i=C_i+1)
            if(S_o_O_commit_config[245+C_i] && (!O_lease_valid[C_i] ||
                O_lease_slots[C_i*3+:3]!=S_o_O_commit_config[238+C_i*3+:3] ||
                O_lease_tokens[C_i*32+:32]!=S_o_O_commit_config[174+C_i*32+:32] ||
                O_lease_generations[C_i*32+:32]!=S_o_O_commit_config[110+C_i*32+:32] ||
                O_lease_resident[C_i]!=S_o_O_commit_config[108+C_i])) C_host_lease_ok=0;
    end
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    // Latch in the source domain before the only new single-bit crossing.
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) S_video_fault<=0;
        else if(S_video_resource_fault) S_video_fault<=1;
    end
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin S_fault_meta<=0; S_fault_sync<=0; end
        else begin S_fault_meta<=S_video_fault; S_fault_sync<=S_fault_meta; end
    end
    display_host_owner u_display_host_owner (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_start_valid(I_start_valid && !S_host_fault),
        .O_start_ready(S_o_O_start_ready),
        .I_config(I_config),
        .I_tag(I_tag),
        .I_abort(I_abort || S_host_fault),
        .O_busy(S_o_O_busy),
        .O_done_valid(O_done_valid),
        .I_done_ready(I_done_ready),
        .O_error(O_error),
        .O_lease_error(O_lease_error),
        .O_slot_error(O_slot_error),
        .O_commit_error(O_commit_error),
        .O_prepare_error(O_prepare_error),
        .O_retire_error(O_retire_error),
        .O_tag(O_tag),
        .O_epoch(O_epoch),
        .O_previous_epoch(O_previous_epoch),
        .O_applied(O_applied),
        .O_retired(O_retired),
        .O_cancel_late(O_cancel_late),
        .O_quarantined(S_o_O_quarantined),
        .O_response_discarded(S_o_O_response_discarded),
        .O_acquired_mask(O_acquired_mask),
        .O_released_mask(O_released_mask),
        .O_active_mask(O_host_active_mask),
        .O_active_valid(O_host_active_valid),
        .O_active_epoch(O_host_active_epoch),
        .O_active_config(O_host_active_config),
        .O_host_reserve(O_host_reserve),
        .O_source_idle(O_source_idle),
        .O_source_busy(O_source_busy),
        .O_publish_valid(S_o_O_publish_valid),
        .I_publish_ready(S_l_O_publish_ready),
        .O_publish_leases(S_o_O_publish_leases),
        .O_publish_version(S_o_O_publish_version),
        .I_publish_done_valid(S_l_O_done_valid),
        .O_publish_done_ready(S_o_O_publish_done_ready),
        .I_publish_done_version(S_l_O_done_version),
        .I_publish_error(S_l_O_error),
        .O_commit_valid(S_o_O_commit_valid),
        .I_commit_ready(S_c_O_submit_ready),
        .O_commit_config(S_o_O_commit_config),
        .O_commit_tag(S_o_O_commit_tag),
        .O_commit_abort(S_o_O_commit_abort),
        .I_commit_next_epoch(O_next_epoch),
        .I_commit_done_valid(S_c_O_done_valid),
        .O_commit_done_ready(S_o_O_commit_done_ready),
        .I_commit_tag(S_c_O_tag),
        .I_commit_epoch(S_c_O_epoch),
        .I_commit_previous_epoch(S_c_O_previous_epoch),
        .I_commit_error(S_c_O_error),
        .I_commit_prepare_error(S_c_O_prepare_error),
        .I_commit_retire_error(S_c_O_retire_error),
        .I_commit_applied(S_c_O_applied),
        .I_commit_retired(S_c_O_retired),
        .I_commit_quarantined(S_host_fault),
        .O_owned(O_owned),
        .O_lease_valid(O_lease_valid),
        .O_lease_slots(O_lease_slots),
        .O_lease_tokens(O_lease_tokens),
        .O_lease_generations(O_lease_generations),
        .O_lease_resident(O_lease_resident),
        .I_slot_states(I_slot_states),
        .I_slot_readers(I_slot_readers),
        .I_slot_tokens(I_slot_tokens),
        .I_slot_generations(I_slot_generations),
        .I_slot_resident(I_slot_resident),
        .O_slot_cmd_valid(O_slot_cmd_valid),
        .I_slot_cmd_ready(I_slot_cmd_ready),
        .O_slot_cmd_op(O_slot_cmd_op),
        .O_slot_cmd_slot(O_slot_cmd_slot),
        .O_slot_cmd_owner(O_slot_cmd_owner),
        .O_slot_cmd_token(O_slot_cmd_token),
        .O_slot_cmd_generation(O_slot_cmd_generation),
        .O_slot_frame_boundary(O_slot_frame_boundary),
        .O_slot_reader_retired(O_slot_reader_retired),
        .I_slot_result_valid(I_slot_result_valid),
        .O_slot_result_ready(O_slot_result_ready),
        .I_slot_result_error(I_slot_result_error),
        .I_slot_result_op(I_slot_result_op),
        .I_slot_result_slot(I_slot_result_slot),
        .I_slot_result_owner(I_slot_result_owner),
        .I_slot_result_token(I_slot_result_token),
        .I_slot_result_generation(I_slot_result_generation),
        .I_slot_result_base(I_slot_result_base),
        .I_video_frame_start(O_frame_start),
        .I_video_in_use(O_source_in_use),
        .I_video_reader_ack(O_reader_retire_ack),
        .I_video_owner_retired(O_source_owner_retired),
        .I_video_pipeline_retired(O_source_pipeline_retired),
        .O_video_block(O_source_block),
        .O_video_reader_stop(O_reader_stop),
        .O_video_retire_ack(O_video_retire_ack),
        .O_video_fault(O_source_fault)
    );
    display_lease_cdc u_display_lease_cdc (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_publish_valid(S_o_O_publish_valid),
        .O_publish_ready(S_l_O_publish_ready),
        .I_publish_leases(S_o_O_publish_leases),
        .I_publish_version(S_o_O_publish_version),
        .O_done_valid(S_l_O_done_valid),
        .I_done_ready(S_o_O_publish_done_ready),
        .O_done_version(S_l_O_done_version),
        .O_error(S_l_O_error),
        .O_host_busy(S_l_O_host_busy),
        .O_host_quarantined(S_l_O_host_quarantined),
        .O_host_response_discarded(S_l_O_host_response_discarded),
        .I_video_install_enable(1'b1),
        .I_video_block(O_source_block),
        .I_video_in_use(O_source_in_use),
        .I_video_owner_retired(O_source_owner_retired),
        .I_video_pipeline_retired(O_source_pipeline_retired),
        .I_video_guard_fault(O_source_fault | {2{O_video_quarantined}}),
        .I_video_query_config(O_pending_valid ? O_pending_config : O_video_active_config),
        .O_video_leases(O_video_leases),
        .O_video_version(O_video_lease_version),
        .O_video_installed(S_l_O_video_installed),
        .O_video_quarantined(S_l_O_video_quarantined),
        .O_video_authorized(O_video_authorized)
    );
    frame_commit_cdc u_frame_commit_cdc (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_submit_valid(S_o_O_commit_valid),
        .O_submit_ready(S_c_O_submit_ready),
        .I_config(S_o_O_commit_config),
        .I_tag(S_o_O_commit_tag),
        .I_validate_error(C_host_lease_ok ? 4'd0 : 4'd4),
        .I_abort(S_o_O_commit_abort),
        .O_next_epoch(O_next_epoch),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(S_o_O_commit_done_ready),
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
        .O_pending_valid(O_pending_valid),
        .O_pending_config(O_pending_config),
        .O_pending_tag(O_pending_tag),
        .O_pending_epoch(O_pending_epoch),
        .O_prepare_valid(S_c_O_prepare_valid),
        .I_prepare_ready(S_p_O_prepare_ready),
        .O_prepare_abort(S_c_O_prepare_abort),
        .I_prepare_done_valid(S_p_O_prepare_done_valid),
        .O_prepare_done_ready(S_c_O_prepare_done_ready),
        .I_prepare_done_tag(S_p_O_prepare_tag),
        .I_prepare_done_epoch(S_p_O_prepare_epoch),
        .I_prepare_done_error(S_p_O_prepare_error),
        .I_frame_start(O_frame_start),
        .I_allow_apply(S_allow_apply),
        .I_video_abort(I_video_abort || O_video_quarantined),
        .O_active_valid(O_video_active_valid),
        .O_active_config(O_video_active_config),
        .O_active_tag(O_video_active_tag),
        .O_active_epoch(S_c_O_active_epoch),
        .O_applied_pulse(S_c_O_applied_pulse),
        .O_apply_valid(S_c_O_apply_valid),
        .O_retire_valid(S_c_O_retire_valid),
        .I_retire_ready(S_p_O_retire_ready),
        .O_retire_config(S_c_O_retire_config),
        .O_retire_tag(S_c_O_retire_tag),
        .O_retire_epoch(S_c_O_retire_epoch),
        .O_retire_old(S_c_O_retire_old),
        .I_retire_done_valid(S_p_O_retire_done_valid),
        .O_retire_done_ready(S_c_O_retire_done_ready),
        .I_retire_done_tag(S_p_O_retire_tag),
        .I_retire_done_epoch(S_p_O_retire_epoch),
        .I_retire_done_error(S_p_O_retire_error),
        .O_video_quarantined(S_c_O_video_quarantined),
        .O_video_response_discarded(O_video_response_discarded)
    );
    display_video_pipeline u_display_video_pipeline (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_prepare_valid(S_c_O_prepare_valid),
        .O_prepare_ready(S_p_O_prepare_ready),
        .I_pending_config(O_pending_config),
        .I_pending_epoch(O_pending_epoch),
        .I_pending_tag(O_pending_tag),
        .I_prepare_abort(S_c_O_prepare_abort),
        .I_prepare_deadline_valid(I_prepare_deadline_valid),
        .I_prepare_deadline_epoch(I_prepare_deadline_epoch),
        .I_prepare_deadlines(I_prepare_deadlines),
        .O_prepare_done_valid(S_p_O_prepare_done_valid),
        .I_prepare_done_ready(S_c_O_prepare_done_ready),
        .O_prepare_error(S_p_O_prepare_error),
        .O_prepare_epoch(S_p_O_prepare_epoch),
        .O_prepare_tag(S_p_O_prepare_tag),
        .I_apply_valid(S_c_O_apply_valid),
        .O_can_apply(S_p_O_can_apply),
        .I_retire_valid(S_c_O_retire_valid),
        .O_retire_ready(S_p_O_retire_ready),
        .I_retire_old(S_c_O_retire_old),
        .I_retire_config(S_c_O_retire_config),
        .I_retire_epoch(S_c_O_retire_epoch),
        .I_retire_tag(S_c_O_retire_tag),
        .O_retire_done_valid(S_p_O_retire_done_valid),
        .I_retire_done_ready(S_c_O_retire_done_ready),
        .O_retire_error(S_p_O_retire_error),
        .O_retire_epoch(S_p_O_retire_epoch),
        .O_retire_tag(S_p_O_retire_tag),
        .I_authorized(O_video_authorized),
        .I_source_block(O_source_block),
        .I_lease_valid(O_lease_valid),
        .I_lease_slots(O_lease_slots),
        .I_lease_tokens(O_lease_tokens),
        .I_lease_generations(O_lease_generations),
        .I_scan_deadline_valid(I_scan_deadline_valid),
        .I_scan_deadline_y(I_scan_deadline_y),
        .I_scan_deadline_epoch(I_scan_deadline_epoch),
        .I_scan_deadline(I_scan_deadline),
        .I_scan_stop(I_scan_stop),
        .O_scan_stop_ack(O_scan_stop_ack),
        .I_reader_retire_request(O_reader_stop),
        .O_reader_retire_ack(O_reader_retire_ack),
        .O_reader_host_retired(O_reader_host_retired),
        .O_source_in_use(O_source_in_use),
        .O_source_owner_retired(O_source_owner_retired),
        .O_source_pipeline_retired(O_source_pipeline_retired),
        .O_prefetch_y(O_prefetch_y),
        .O_active_epoch(O_video_active_epoch),
        .O_frame_start(O_frame_start),
        .O_local_applied(O_local_applied),
        .O_bank_busy(O_bank_busy),
        .O_busy(S_p_O_busy),
        .O_contract_fault(S_p_O_contract_fault),
        .O_quarantined(S_p_O_quarantined),
        .O_valid(O_valid),
        .O_hsync(O_hsync),
        .O_vsync(O_vsync),
        .O_de(O_de),
        .O_x(O_x),
        .O_y(O_y),
        .O_rgb(O_rgb),
        .O_epoch(O_pixel_epoch),
        .O_tag(O_pixel_tag),
        .O_repeated(O_repeated),
        .O_pixel_fault(O_pixel_fault),
        .O_video_und(O_video_und),
        .O_und_count(O_und_count),
        .O_line_error_count(O_line_error_count),
        .O_mem_valid(O_mem_valid),
        .I_mem_ready(I_mem_ready),
        .O_mem_addr(O_mem_addr),
        .O_mem_tag(O_mem_tag),
        .O_mem_token(O_mem_token),
        .O_mem_generation(O_mem_generation),
        .O_mem_deadline(O_mem_deadline),
        .I_mem_valid(I_mem_valid),
        .O_mem_ready(O_mem_ready),
        .I_mem_data(I_mem_data),
        .I_mem_tag(I_mem_tag),
        .I_mem_token(I_mem_token),
        .I_mem_generation(I_mem_generation),
        .I_mem_error(I_mem_error)
    );
endmodule
