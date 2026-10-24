`timescale 1ns/1ps
// Real source guard + lease controller + slot manager + reader/CDC/RAM.
// Explicit logical memory response and external reference proof endpoints.
module tb_display_source_guard;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_async_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    wire S_host_reset;
    reset_sync u_host_reset (.I_clk(S_host_clk),.I_async_reset(S_async_reset),.O_reset(S_host_reset));
    reg S_fixture=1,S_f_valid=0,S_f_result_ready=0,S_cmd_gate=1;
    reg [2:0] S_f_op=0,S_f_slot=0;
    reg [1:0] S_f_owner=2;
    reg [31:0] S_f_token=0,S_f_generation=11;
    reg [1:0] S_mem_enable=3,S_stale_reader_ack=0;
    reg [1:0] S_g_I_host_reserve=0;
    wire [1:0] S_g_O_host_source_idle;
    wire [1:0] S_g_O_host_acquire_permit;
    wire [1:0] S_g_O_host_retire_ack;
    wire [1:0] S_g_O_host_busy;
    wire [1:0] S_g_O_host_fault;
    reg  S_g_I_video_frame_start=0;
    reg [1:0] S_g_I_video_in_use=0;
    reg [1:0] S_g_I_video_owner_retired=0;
    reg [1:0] S_g_I_video_pipeline_retired=0;
    wire [1:0] S_g_O_video_block;
    wire [1:0] S_g_O_video_reader_stop;
    wire [1:0] S_g_O_video_retire_ack;
    wire [1:0] S_g_O_video_fault;
    reg  S_c_I_start_valid=0;
    wire  S_c_O_start_ready;
    reg  S_c_I_op=0;
    reg  S_c_I_source=0;
    reg [2:0] S_c_I_slot=0;
    reg [31:0] S_c_I_token=0;
    reg [31:0] S_c_I_generation=0;
    reg [15:0] S_c_I_tag=0;
    reg  S_c_I_abort=0;
    wire [1:0] S_c_O_retire_request;
    wire  S_c_O_busy;
    wire  S_c_O_done_valid;
    reg  S_c_I_done_ready=0;
    wire [3:0] S_c_O_error;
    wire [3:0] S_c_O_slot_error;
    wire  S_c_O_op;
    wire  S_c_O_source;
    wire [2:0] S_c_O_slot;
    wire [31:0] S_c_O_token;
    wire [31:0] S_c_O_generation;
    wire [15:0] S_c_O_tag;
    wire  S_c_O_changed;
    wire  S_c_O_cancel_late;
    wire  S_c_O_quarantined;
    wire  S_c_O_response_discarded;
    wire [1:0] S_c_O_owned;
    wire [1:0] S_c_O_lease_valid;
    wire [5:0] S_c_O_lease_slots;
    wire [63:0] S_c_O_lease_tokens;
    wire [63:0] S_c_O_lease_generations;
    wire [1:0] S_c_O_lease_resident;
    wire  S_c_O_slot_cmd_valid;
    wire [2:0] S_c_O_slot_cmd_op;
    wire [2:0] S_c_O_slot_cmd_slot;
    wire [1:0] S_c_O_slot_cmd_owner;
    wire [31:0] S_c_O_slot_cmd_token;
    wire [31:0] S_c_O_slot_cmd_generation;
    wire  S_c_O_slot_frame_boundary;
    wire  S_c_O_slot_reader_retired;
    wire  S_c_O_slot_result_ready;
    reg  S_m_I_media_valid=0;
    reg [31:0] S_m_I_media_generation=0;
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
    reg  S_r_I_task_valid=0;
    wire  S_r_O_task_ready;
    reg [2:0] S_r_I_task_slot=0;
    reg [20:0] S_r_I_task_base=0;
    reg [8:0] S_r_I_task_y=0;
    reg  S_r_I_task_bank=0;
    reg [31:0] S_r_I_task_token=0;
    reg [31:0] S_r_I_task_generation=0;
    reg [31:0] S_r_I_task_epoch=0;
    reg [31:0] S_r_I_task_deadline=0;
    reg [15:0] S_r_I_task_tag=0;
    wire  S_r_O_line_valid;
    reg  S_r_I_line_ready=0;
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
    reg [1:0] S_r_I_read_valid=0;
    wire [1:0] S_r_O_read_ready;
    reg [1:0] S_r_I_read_bank=0;
    reg [19:0] S_r_I_read_x=0;
    wire [1:0] S_r_O_pixel_valid;
    wire [63:0] S_r_O_rgba;
    wire [1:0] S_r_O_pixel_bank;
    wire [19:0] S_r_O_pixel_x;
    wire [63:0] S_r_O_pixel_token;
    wire [63:0] S_r_O_pixel_generation;
    wire [63:0] S_r_O_pixel_epoch;
    wire [31:0] S_r_O_pixel_tag;
    reg [1:0] S_r_I_release_valid=0;
    wire [1:0] S_r_O_release_ready;
    reg [1:0] S_r_I_release_bank=0;
    reg [63:0] S_r_I_release_token=0;
    reg [63:0] S_r_I_release_generation=0;
    reg [63:0] S_r_I_release_epoch=0;
    reg [31:0] S_r_I_release_tag=0;
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
    wire [1:0] S_r_I_mem_ready;
    wire [41:0] S_r_O_mem_addr;
    wire [63:0] S_r_O_mem_tag;
    wire [63:0] S_r_O_mem_token;
    wire [63:0] S_r_O_mem_generation;
    wire [63:0] S_r_O_mem_deadline;
    wire [1:0] S_r_I_mem_valid;
    wire [1:0] S_r_O_mem_ready;
    wire [63:0] S_r_I_mem_data;
    wire [63:0] S_r_I_mem_tag;
    wire [63:0] S_r_I_mem_token;
    wire [63:0] S_r_I_mem_generation;
    wire [7:0] S_r_I_mem_error;
    reg  S_r_I_task_source=0;
    wire  S_r_O_line_source;
    display_source_guard u_guard (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_async_reset),
        .I_host_reserve(S_g_I_host_reserve),
        .I_host_retire_request(S_c_O_retire_request),
        .O_host_source_idle(S_g_O_host_source_idle),
        .O_host_acquire_permit(S_g_O_host_acquire_permit),
        .O_host_retire_ack(S_g_O_host_retire_ack),
        .O_host_busy(S_g_O_host_busy),
        .O_host_fault(S_g_O_host_fault),
        .I_video_frame_start(S_g_I_video_frame_start),
        .I_video_in_use(S_g_I_video_in_use),
        .I_video_reader_ack(S_r_O_retire_ack | S_stale_reader_ack),
        .I_video_owner_retired(S_g_I_video_owner_retired),
        .I_video_pipeline_retired(S_g_I_video_pipeline_retired),
        .O_video_block(S_g_O_video_block),
        .O_video_reader_stop(S_g_O_video_reader_stop),
        .O_video_retire_ack(S_g_O_video_retire_ack),
        .O_video_fault(S_g_O_video_fault)
    );
    display_lease_ctrl u_leases (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_start_valid(S_c_I_start_valid),
        .O_start_ready(S_c_O_start_ready),
        .I_op(S_c_I_op),
        .I_source(S_c_I_source),
        .I_slot(S_c_I_slot),
        .I_token(S_c_I_token),
        .I_generation(S_c_I_generation),
        .I_tag(S_c_I_tag),
        .I_abort(S_c_I_abort),
        .I_source_idle(S_g_O_host_source_idle),
        .I_acquire_permit(S_g_O_host_acquire_permit),
        .I_retire_ack(S_g_O_host_retire_ack),
        .O_retire_request(S_c_O_retire_request),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(S_c_I_done_ready),
        .O_error(S_c_O_error),
        .O_slot_error(S_c_O_slot_error),
        .O_op(S_c_O_op),
        .O_source(S_c_O_source),
        .O_slot(S_c_O_slot),
        .O_token(S_c_O_token),
        .O_generation(S_c_O_generation),
        .O_tag(S_c_O_tag),
        .O_changed(S_c_O_changed),
        .O_cancel_late(S_c_O_cancel_late),
        .O_quarantined(S_c_O_quarantined),
        .O_response_discarded(S_c_O_response_discarded),
        .O_owned(S_c_O_owned),
        .O_lease_valid(S_c_O_lease_valid),
        .O_lease_slots(S_c_O_lease_slots),
        .O_lease_tokens(S_c_O_lease_tokens),
        .O_lease_generations(S_c_O_lease_generations),
        .O_lease_resident(S_c_O_lease_resident),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_readers(S_m_O_slot_readers),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .O_slot_cmd_valid(S_c_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_m_O_cmd_ready && !S_fixture && S_cmd_gate),
        .O_slot_cmd_op(S_c_O_slot_cmd_op),
        .O_slot_cmd_slot(S_c_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_c_O_slot_cmd_owner),
        .O_slot_cmd_token(S_c_O_slot_cmd_token),
        .O_slot_cmd_generation(S_c_O_slot_cmd_generation),
        .O_slot_frame_boundary(S_c_O_slot_frame_boundary),
        .O_slot_reader_retired(S_c_O_slot_reader_retired),
        .I_slot_result_valid(S_m_O_result_valid && !S_fixture),
        .O_slot_result_ready(S_c_O_slot_result_ready),
        .I_slot_result_error(S_m_O_result_error),
        .I_slot_result_op(S_m_O_result_op),
        .I_slot_result_slot(S_m_O_result_slot),
        .I_slot_result_owner(S_m_O_result_owner),
        .I_slot_result_token(S_m_O_result_token),
        .I_slot_result_generation(S_m_O_result_generation),
        .I_slot_result_base(S_m_O_result_base)
    );
    fb_slot_manager u_slots (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_m_I_media_valid),
        .I_media_generation(S_m_I_media_generation),
        .I_cmd_valid(S_fixture ? S_f_valid : (S_c_O_slot_cmd_valid && S_cmd_gate)),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_fixture ? S_f_op : S_c_O_slot_cmd_op),
        .I_cmd_slot(S_fixture ? S_f_slot : S_c_O_slot_cmd_slot),
        .I_cmd_owner(S_fixture ? S_f_owner : S_c_O_slot_cmd_owner),
        .I_cmd_token(S_fixture ? S_f_token : S_c_O_slot_cmd_token),
        .I_cmd_generation(S_fixture ? S_f_generation : S_c_O_slot_cmd_generation),
        .I_cmd_asset(32'd9),
        .I_cmd_layout(3'd0),
        .I_cmd_rotation(2'd0),
        .I_cmd_resident(1'b0),
        .I_cmd_success(1'b1),
        .I_producer_retired(1'b1),
        .I_memory_retired(1'b1),
        .I_reader_retired(S_fixture ? 1'b1 : S_c_O_slot_reader_retired),
        .I_frame_boundary(S_fixture ? 1'b1 : S_c_O_slot_frame_boundary),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_fixture ? S_f_result_ready : S_c_O_slot_result_ready),
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
    fb_reader u_reader (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_async_reset),
        .I_lease_valid(S_c_O_lease_valid),
        .I_lease_slot(S_c_O_lease_slots),
        .I_lease_token(S_c_O_lease_tokens),
        .I_lease_generation(S_c_O_lease_generations),
        .I_task_valid(S_r_I_task_valid),
        .O_task_ready(S_r_O_task_ready),
        .I_task_slot(S_r_I_task_slot),
        .I_task_base(S_r_I_task_base),
        .I_task_y(S_r_I_task_y),
        .I_task_bank(S_r_I_task_bank),
        .I_task_token(S_r_I_task_token),
        .I_task_generation(S_r_I_task_generation),
        .I_task_epoch(S_r_I_task_epoch),
        .I_task_deadline(S_r_I_task_deadline),
        .I_task_tag(S_r_I_task_tag),
        .O_line_valid(S_r_O_line_valid),
        .I_line_ready(S_r_I_line_ready),
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
        .I_read_valid(S_r_I_read_valid),
        .O_read_ready(S_r_O_read_ready),
        .I_read_bank(S_r_I_read_bank),
        .I_read_x(S_r_I_read_x),
        .O_pixel_valid(S_r_O_pixel_valid),
        .O_rgba(S_r_O_rgba),
        .O_pixel_bank(S_r_O_pixel_bank),
        .O_pixel_x(S_r_O_pixel_x),
        .O_pixel_token(S_r_O_pixel_token),
        .O_pixel_generation(S_r_O_pixel_generation),
        .O_pixel_epoch(S_r_O_pixel_epoch),
        .O_pixel_tag(S_r_O_pixel_tag),
        .I_release_valid(S_r_I_release_valid),
        .O_release_ready(S_r_O_release_ready),
        .I_release_bank(S_r_I_release_bank),
        .I_release_token(S_r_I_release_token),
        .I_release_generation(S_r_I_release_generation),
        .I_release_epoch(S_r_I_release_epoch),
        .I_release_tag(S_r_I_release_tag),
        .O_bank_valid(S_r_O_bank_valid),
        .O_bank_reserved(S_r_O_bank_reserved),
        .O_bank_slots(S_r_O_bank_slots),
        .O_bank_rows(S_r_O_bank_rows),
        .O_bank_tokens(S_r_O_bank_tokens),
        .O_bank_generations(S_r_O_bank_generations),
        .O_bank_epochs(S_r_O_bank_epochs),
        .O_bank_tags(S_r_O_bank_tags),
        .I_retire_request(S_g_O_video_reader_stop),
        .O_retire_ack(S_r_O_retire_ack),
        .O_host_retired(S_r_O_host_retired),
        .O_host_busy(S_r_O_host_busy),
        .O_host_tag_exhausted(S_r_O_host_tag_exhausted),
        .O_release_discarded(S_r_O_release_discarded),
        .O_event_discarded(S_r_O_event_discarded),
        .O_response_discarded(S_r_O_response_discarded),
        .O_mem_valid(S_r_O_mem_valid),
        .I_mem_ready(S_r_I_mem_ready),
        .O_mem_addr(S_r_O_mem_addr),
        .O_mem_tag(S_r_O_mem_tag),
        .O_mem_token(S_r_O_mem_token),
        .O_mem_generation(S_r_O_mem_generation),
        .O_mem_deadline(S_r_O_mem_deadline),
        .I_mem_valid(S_r_I_mem_valid),
        .O_mem_ready(S_r_O_mem_ready),
        .I_mem_data(S_r_I_mem_data),
        .I_mem_tag(S_r_I_mem_tag),
        .I_mem_token(S_r_I_mem_token),
        .I_mem_generation(S_r_I_mem_generation),
        .I_mem_error(S_r_I_mem_error),
        .I_task_source(S_r_I_task_source),
        .O_line_source(S_r_O_line_source)
    );
    integer S_case=0,S_i;
    reg [31:0] S_tokens[0:1];
    reg [15:0] S_cmd_tag=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: display_source_guard case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #2000000; fail("watchdog timeout"); end
    assign S_r_I_mem_ready=S_mem_enable;
    assign S_r_I_mem_valid=S_r_O_mem_valid & S_mem_enable;
    assign S_r_I_mem_tag=S_r_O_mem_tag;
    assign S_r_I_mem_token=S_r_O_mem_token;
    assign S_r_I_mem_generation=S_r_O_mem_generation;
    assign S_r_I_mem_error=0;
    assign S_r_I_mem_data={32'h915a0000^{11'd0,S_r_O_mem_addr[41:21]},32'h26c30000^{11'd0,S_r_O_mem_addr[20:0]}};
    task fixture_command;
        input integer op,slot;
        input [31:0] token;
        begin
            @(negedge S_host_clk); S_f_op=op; S_f_slot=slot; S_f_token=token; S_f_valid=1;
            @(posedge S_host_clk); while(!S_m_O_cmd_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_f_valid=0;
            wait(S_m_O_result_valid); #1;
            if(S_m_O_result_error!=0) fail("real slot fixture preparation");
            if(op==0) S_tokens[slot]=S_m_O_result_token;
            @(negedge S_host_clk); S_f_result_ready=1;
            @(negedge S_host_clk); S_f_result_ready=0;
        end
    endtask
    task reset_all;
        integer slot;
        begin
            S_case=S_case+1;
            @(negedge S_host_clk); S_async_reset=1; S_fixture=1; S_f_valid=0; S_f_result_ready=0;
            S_c_I_start_valid=0; S_c_I_done_ready=0; S_c_I_abort=0; S_g_I_host_reserve=0; S_cmd_gate=1;
            S_g_I_video_frame_start=0; S_g_I_video_in_use=0; S_g_I_video_owner_retired=0; S_g_I_video_pipeline_retired=0;
            S_r_I_task_valid=0; S_r_I_line_ready=1; S_r_I_read_valid=0; S_r_I_release_valid=0;
            S_mem_enable=3; S_stale_reader_ack=0; S_m_I_media_valid=1; S_m_I_media_generation=11;
            repeat(8) @(negedge S_host_clk); S_async_reset=0;
            wait(!S_host_reset); repeat(8) @(negedge S_video_clk);
            for(slot=0;slot<2;slot=slot+1) begin fixture_command(0,slot,0); fixture_command(1,slot,S_tokens[slot]); end
            @(negedge S_host_clk); S_fixture=0;
            if(S_g_O_host_source_idle!=0 || S_g_O_host_busy!=0 || S_g_O_video_block!=0 || S_g_O_host_retire_ack!=0)
                fail("reset retained stale authorization");
        end
    endtask
    task frame;
        begin
            @(negedge S_video_clk); S_g_I_video_frame_start=1;
            @(negedge S_video_clk); S_g_I_video_frame_start=0;
        end
    endtask
    task reserve;
        input integer source;
        begin
            S_case=S_case+1;
            @(negedge S_host_clk); S_g_I_host_reserve[source]=1;
            repeat(6) @(negedge S_video_clk);
            if(S_g_O_host_source_idle[source] || S_g_O_video_block[source]) fail("reservation bypassed video boundary");
            frame; wait(S_g_O_host_source_idle[source]);
            if(!S_g_O_host_acquire_permit[source] || !S_g_O_video_block[source]) fail("grant did not reserve source");
        end
    endtask
    task unreserve;
        input integer source;
        begin
            @(negedge S_host_clk); S_g_I_host_reserve[source]=0;
            wait(!S_g_O_host_busy[source]);
            repeat(3) @(negedge S_host_clk);
            if(S_g_O_host_source_idle[source] || S_g_O_video_block[source] || S_g_O_host_retire_ack[source]) fail("reservation did not return to zero");
        end
    endtask
    task lease_start;
        input integer op,source;
        begin
            S_case=S_case+1; S_cmd_tag=S_cmd_tag+1;
            @(negedge S_host_clk); S_c_I_op=op; S_c_I_source=source; S_c_I_slot=source;
            S_c_I_token=S_tokens[source]; S_c_I_generation=11; S_c_I_tag=S_cmd_tag; S_c_I_start_valid=1;
            @(posedge S_host_clk); if(!S_c_O_start_ready) fail("lease start unavailable");
            @(negedge S_host_clk); S_c_I_start_valid=0;
        end
    endtask
    task lease_result;
        input integer error;
        reg [94:0] saved;
        begin
            wait(S_c_O_done_valid); #1;
            if(S_c_O_error!==error[3:0] || S_c_O_tag!==S_cmd_tag || (error==0 && !S_c_O_changed)) fail("real lease terminal");
            saved={S_c_O_error,S_c_O_slot_error,S_c_O_op,S_c_O_source,S_c_O_slot,S_c_O_token,S_c_O_generation,S_c_O_tag,S_c_O_changed,S_c_O_cancel_late};
            repeat(5) begin @(negedge S_host_clk);
                if(!S_c_O_done_valid || S_c_O_start_ready || saved!=={S_c_O_error,S_c_O_slot_error,S_c_O_op,S_c_O_source,S_c_O_slot,
                    S_c_O_token,S_c_O_generation,S_c_O_tag,S_c_O_changed,S_c_O_cancel_late}) fail("lease terminal under backpressure"); end
            S_c_I_done_ready=1; @(negedge S_host_clk); S_c_I_done_ready=0;
        end
    endtask
    task acquire;
        input integer source;
        begin reserve(source); lease_start(0,source); lease_result(0); unreserve(source); end
    endtask
    task line_task;
        input integer source,row,bank;
        begin
            @(negedge S_video_clk);
            if(S_g_O_video_block[source]) fail("test attempted a new task while reserved");
            S_r_I_task_source=source; S_r_I_task_slot=source; S_r_I_task_base=source*307200;
            S_r_I_task_y=row; S_r_I_task_bank=bank; S_r_I_task_token=S_tokens[source]; S_r_I_task_generation=11;
            S_r_I_task_epoch=source+1; S_r_I_task_deadline=32'h34567890; S_r_I_task_tag=source*100+row; S_r_I_task_valid=1;
            @(posedge S_video_clk); while(!S_r_O_task_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_r_I_task_valid=0;
        end
    endtask
    task pixel;
        input integer source,row,bank,x;
        reg [31:0] expected;
        begin
            @(negedge S_video_clk); S_r_I_read_valid=2'b01<<source;
            S_r_I_read_bank[source]=bank; S_r_I_read_x[source*10+:10]=x;
            #1; if(!S_r_O_read_ready[source]) fail("other source lost read readiness");
            @(posedge S_video_clk); #1;
            expected=(source==0 ? 32'h26c30000 : 32'h915a0000)^(source*307200+row*640+x);
            if(!S_r_O_pixel_valid[source] || S_r_O_rgba[source*32+:32]!==expected ||
                S_r_O_pixel_token[source*32+:32]!==S_tokens[source] || S_r_O_pixel_epoch[source*32+:32]!==source+1)
                fail("real unaffected source pixels/identity");
            @(negedge S_video_clk); S_r_I_read_valid=0;
        end
    endtask
    initial begin
        reset_all; acquire(0); acquire(1);
        if(S_c_O_lease_valid!==3 || S_m_O_slot_readers[2:0]!==1 || S_m_O_slot_readers[5:3]!==2) fail("dual real read locks");
        @(negedge S_video_clk); S_g_I_video_in_use=3;
        line_task(1,9,0); wait(S_r_O_bank_valid[2]);
        line_task(0,17,0); wait(S_r_O_bank_valid[0]);
        pixel(0,17,0,31); pixel(1,9,0,73);
        // An unused configuration can still have an outstanding old read obligation.
        S_mem_enable[0]=0; line_task(0,18,1); wait(S_r_O_mem_valid[0]);
        @(negedge S_host_clk); S_g_I_host_reserve[0]=1;
        repeat(6) @(negedge S_video_clk);
        frame; repeat(8) @(negedge S_host_clk);
        if(S_g_O_host_source_idle[0] || S_g_O_video_block[0] || S_g_O_video_reader_stop[0]) fail("active source granted/stopped");
        pixel(0,17,0,41); pixel(1,9,0,83);
        @(negedge S_video_clk); S_g_I_video_in_use[0]=0;
        frame; wait(S_g_O_host_source_idle[0]);
        if(S_g_O_video_block!==1) fail("reserved source disturbed other active source");
        S_cmd_gate=0; lease_start(1,0);
        wait(S_g_O_video_reader_stop[0]);
        repeat(8) begin @(negedge S_video_clk);
            if(S_r_O_retire_ack[0] || S_g_O_host_retire_ack[0] || S_c_O_done_valid || S_c_O_slot_cmd_valid) fail("outstanding read falsely retired"); end
        pixel(1,9,0,101);
        // Stopped host cannot retire its pending memory command/barrier.
        @(negedge S_host_clk); S_host_run=0;
        repeat(12) begin @(negedge S_video_clk); if(S_g_O_host_retire_ack[0] || S_r_O_retire_ack[0]) fail("stopped host invented reader completion"); end
        S_host_run=1; @(negedge S_host_clk); S_mem_enable[0]=1;
        wait(S_r_O_retire_ack[0]);
        repeat(8) begin @(negedge S_host_clk); if(S_g_O_host_retire_ack[0] || S_c_O_slot_cmd_valid) fail("reader internal ack replaced external owner proof"); end
        @(negedge S_video_clk); S_g_I_video_owner_retired[0]=1;
        repeat(6) begin @(negedge S_host_clk); if(S_g_O_host_retire_ack[0]) fail("external pipeline not retired"); end
        S_g_I_video_pipeline_retired[0]=1;
        wait(S_g_O_host_retire_ack[0]); wait(S_c_O_slot_cmd_valid);
        repeat(5) begin @(negedge S_host_clk);
            if(!S_c_O_lease_valid[0] || !S_g_O_video_reader_stop[0] || S_c_O_done_valid) fail("lock released before real manager acceptance"); end
        pixel(1,9,0,127);
        // Early reserve withdrawal cannot end an active retirement handshake.
        @(negedge S_host_clk); S_g_I_host_reserve[0]=0;
        repeat(6) begin @(negedge S_host_clk);
            if(!S_g_O_host_source_idle[0] || !S_g_O_host_busy[0] || !S_g_O_video_block[0]) fail("reserve cleared with retirement still held"); end
        S_cmd_gate=1;
        wait(!S_g_O_video_reader_stop[0]);
        @(negedge S_video_clk); S_video_run=0;
        repeat(16) begin @(negedge S_host_clk);
            if(S_c_O_done_valid || !S_g_O_host_retire_ack[0] || !S_g_O_host_busy[0]) fail("retirement skipped real reader ack zero"); end
        S_video_run=1; lease_result(0);
        wait(!S_g_O_host_busy[0]);
        if(S_c_O_owned!==2 || S_c_O_lease_valid!==2 || S_r_O_bank_valid[1:0]!=0 || !S_r_O_bank_valid[2] ||
            S_g_O_host_fault!=0 || S_g_O_video_fault!=0) fail("real source retirement affected other foreground");
        pixel(1,9,0,211);
        // Fresh reservation needs a fresh frame; previously completed ack cannot be reused.
        acquire(0); reserve(0); S_stale_reader_ack[0]=1; lease_start(1,0);
        repeat(8) begin @(negedge S_video_clk);
            if(S_g_O_video_reader_stop[0] || S_g_O_host_retire_ack[0]) fail("stale reader ack used by next retirement"); end
        S_stale_reader_ack[0]=0; wait(S_g_O_video_reader_stop[0]);
        lease_result(0); unreserve(0);
        if(S_c_O_lease_valid!==2 || S_g_O_host_fault!=0) fail("second real retirement not reusable");
        // A canceled pending reservation still completes its dispatched handshake.
        reset_all;
        @(negedge S_host_clk); S_g_I_host_reserve[1]=1;
        wait(S_g_O_host_busy[1]); @(negedge S_host_clk); S_g_I_host_reserve[1]=0;
        repeat(5) begin @(negedge S_video_clk); if(!S_g_O_host_busy[1] || S_g_O_host_source_idle[1]) fail("pending reserve withdrawn across CDC"); end
        frame; wait(!S_g_O_host_busy[1]);
        if(S_g_O_video_block!=0 || S_g_O_host_source_idle!=0 || S_g_O_host_fault!=0) fail("early reserve clear left stale grant");
        // Independent grants can be concurrent; clearing one never clears the other.
        reset_all;
        @(negedge S_host_clk); S_g_I_host_reserve=3;
        repeat(6) @(negedge S_video_clk); frame;
        wait(S_g_O_host_source_idle==3);
        if(S_g_O_video_block!==3 || S_g_O_host_acquire_permit!==3) fail("concurrent source grants lost a lane");
        unreserve(0);
        if(!S_g_O_host_source_idle[1] || !S_g_O_video_block[1] || !S_g_O_host_busy[1]) fail("one reserve clear released the other lane");
        unreserve(1);
        // A grant cannot authorize a new configuration while the host owns its reservation.
        reset_all; reserve(0);
        @(negedge S_video_clk); S_g_I_video_in_use[0]=1;
        wait(S_g_O_video_fault[0]); wait(S_g_O_host_fault[0]);
        repeat(4) @(negedge S_host_clk);
        if(S_g_O_host_source_idle[0] || S_g_O_host_acquire_permit[0] || !S_g_O_video_block[0]) fail("in-use violation silently retained host authorization");
        reset_all; acquire(1);
        if(S_c_O_lease_valid!==2 || S_g_O_host_fault!=0 || S_g_O_video_fault!=0) fail("unified reset did not restore guard");
        S_test_pass=1; $display("PASS: source guard/real lease and reader/CDC/retirement proofs/clock stops/source isolation"); $finish;
    end
endmodule
