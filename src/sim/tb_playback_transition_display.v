`timescale 1ns/1ps
// Real host owner + lease/commit CDC + candidate/scanout/reader + slot manager/RAM.
// Actual deadline scheduler/CDC; only slot loading, logical memory and audio readiness are fixtures.
module tb_playback_transition_display;
    // Shared endpoint declarations precede all instance/assign uses.
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
    wire [17:0] S_m_O_slot_readers;
    wire [5:0] S_m_O_slot_resident;
    wire S_silence_u_owner_O_silence_valid;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    wire S_host_reset;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reset_sync u_host_reset (.I_clk(S_host_clk),.I_async_reset(S_reset),.O_reset(S_host_reset));
    reg S_fixture=1,S_f_valid=0,S_f_result_ready=0,S_cmd_gate=1,S_media_valid=1;
    reg [2:0] S_f_op=0,S_f_slot=0;
    reg [31:0] S_f_token=0;
    reg [31:0] S_tokens[0:5];
    reg [1:0] S_mem_enable=3;
    reg [7:0] S_mem_error=0;
    reg S_expect_fault=0,S_check_pixels=0;
    integer S_case=0,S_commands=0,S_publishes=0,S_applies=0,S_pixels=0,S_frames=0;
    integer S_mem_counts[0:1];
    integer S_i,S_v_i;
    reg [137:0] S_last_publish=0,S_previous_video_leases=0;
    reg [31:0] S_last_version=0,S_saved_epoch=0,S_frame_epoch=0;
    reg [3:0] S_seed_mask=0;
    reg [1:0] S_next_banks=0;
    reg [246:0] S_bad_config;
    wire S_d_I_start_valid;
    wire S_d_O_start_ready;
    wire [246:0] S_d_I_config;
    wire [15:0] S_d_I_tag;
    wire S_d_I_abort;
    wire S_d_O_busy;
    wire S_d_O_done_valid;
    wire S_d_I_done_ready;
    wire [3:0] S_d_O_error;
    wire [3:0] S_d_O_lease_error;
    wire [3:0] S_d_O_slot_error;
    wire [3:0] S_d_O_commit_error;
    wire [3:0] S_d_O_prepare_error;
    wire [3:0] S_d_O_retire_error;
    reg S_d_I_video_allow_apply=1;
    wire S_d_I_video_abort;
    reg S_d_I_audio_ready=0;
    reg [31:0] S_d_I_audio_epoch=0;
    wire S_d_O_host_quarantined;
    wire S_d_O_host_response_discarded;
    wire S_d_O_video_quarantined;
    wire [15:0] S_d_O_tag;
    wire [31:0] S_d_O_epoch;
    wire [31:0] S_d_O_previous_epoch;
    wire S_d_O_applied;
    wire S_d_O_retired;
    wire S_d_O_cancel_late;
    wire [1:0] S_d_O_acquired_mask;
    wire [1:0] S_d_O_released_mask;
    wire [1:0] S_d_O_host_active_mask;
    wire S_d_O_host_active_valid;
    wire [31:0] S_d_O_host_active_epoch;
    wire [246:0] S_d_O_host_active_config;
    wire [1:0] S_d_O_host_reserve;
    wire [1:0] S_d_O_source_idle;
    wire [1:0] S_d_O_source_busy;
    wire [1:0] S_d_O_owned;
    wire [1:0] S_d_O_lease_valid;
    wire [5:0] S_d_O_lease_slots;
    wire [63:0] S_d_O_lease_tokens;
    wire [63:0] S_d_O_lease_generations;
    wire [1:0] S_d_O_lease_resident;
    wire S_d_O_slot_cmd_valid;
    wire [2:0] S_d_O_slot_cmd_op;
    wire [2:0] S_d_O_slot_cmd_slot;
    wire [1:0] S_d_O_slot_cmd_owner;
    wire [31:0] S_d_O_slot_cmd_token;
    wire [31:0] S_d_O_slot_cmd_generation;
    wire S_d_O_slot_frame_boundary;
    wire S_d_O_slot_reader_retired;
    wire S_d_O_slot_result_ready;
    wire [1:0] S_d_O_source_block;
    wire [1:0] S_d_O_reader_stop;
    wire [1:0] S_d_O_video_retire_ack;
    wire [1:0] S_d_O_source_fault;
    wire [137:0] S_d_O_video_leases;
    wire [31:0] S_d_O_video_lease_version;
    wire [1:0] S_d_O_video_authorized;
    wire [31:0] S_d_O_next_epoch;
    wire S_d_O_pending_valid;
    wire [246:0] S_d_O_pending_config;
    wire [15:0] S_d_O_pending_tag;
    wire [31:0] S_d_O_pending_epoch;
    wire S_d_O_video_active_valid;
    wire [246:0] S_d_O_video_active_config;
    wire [15:0] S_d_O_video_active_tag;
    wire S_d_O_video_response_discarded;
    reg S_d_I_scan_stop=0;
    wire S_d_O_scan_stop_ack;
    wire [1:0] S_d_O_reader_retire_ack;
    wire [1:0] S_d_O_reader_host_retired;
    wire [1:0] S_d_O_source_in_use;
    wire [1:0] S_d_O_source_owner_retired;
    wire [1:0] S_d_O_source_pipeline_retired;
    wire [8:0] S_d_O_prefetch_y;
    wire [31:0] S_d_O_video_active_epoch;
    wire S_d_O_frame_start;
    wire S_d_O_local_applied;
    wire S_d_O_valid;
    wire S_d_O_hsync;
    wire S_d_O_vsync;
    wire S_d_O_de;
    wire [15:0] S_d_O_x;
    wire [15:0] S_d_O_y;
    wire [23:0] S_d_O_rgb;
    wire [31:0] S_d_O_pixel_epoch;
    wire [15:0] S_d_O_pixel_tag;
    wire S_d_O_repeated;
    wire S_d_O_pixel_fault;
    wire S_d_O_video_und;
    wire [31:0] S_d_O_und_count;
    wire [31:0] S_d_O_line_error_count;
    wire [1:0] S_d_O_mem_valid;
    wire [41:0] S_d_O_mem_addr;
    wire [63:0] S_d_O_mem_tag;
    wire [63:0] S_d_O_mem_token;
    wire [63:0] S_d_O_mem_generation;
    wire [63:0] S_d_O_mem_deadline;
    wire [1:0] S_d_O_mem_ready;
    reg S_clock_enable=1;
    wire [31:0] S_host_time,S_video_time,S_prepare_target;
    wire S_deadline_fault;
    wire S_target_valid;
    wire [31:0] S_target_epoch,S_target_time;
    reg [31:0] S_target_actual=0;
    wire [15:0] S_target_tag;
    reg [31:0] S_target_apply_time=0,S_target_lag=0;
    wire [3:0] S_bank_busy;
    display_timed_pipeline #(.USE_TARGET(1),.PREPARE_IN_VBLANK(1)) u_timed (
        .O_bank_busy(S_bank_busy),
        .I_target_valid(S_target_valid),.I_target_epoch(S_target_epoch),
        .I_target_time(S_target_time),.I_target_tag(S_target_tag),
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_start_valid(S_d_I_start_valid),
        .O_start_ready(S_d_O_start_ready),
        .I_config(S_d_I_config),
        .I_tag(S_d_I_tag),
        .I_abort(S_d_I_abort),
        .O_busy(S_d_O_busy),
        .O_done_valid(S_d_O_done_valid),
        .I_done_ready(S_d_I_done_ready),
        .O_error(S_d_O_error),
        .O_lease_error(S_d_O_lease_error),
        .O_slot_error(S_d_O_slot_error),
        .O_commit_error(S_d_O_commit_error),
        .O_prepare_error(S_d_O_prepare_error),
        .O_retire_error(S_d_O_retire_error),
        .I_video_allow_apply(S_d_I_video_allow_apply),
        .I_video_abort(S_d_I_video_abort),
        .I_audio_ready(S_d_I_audio_ready),
        .I_audio_epoch(S_d_I_audio_epoch),
        .O_host_quarantined(S_d_O_host_quarantined),
        .O_host_response_discarded(S_d_O_host_response_discarded),
        .O_video_quarantined(S_d_O_video_quarantined),
        .O_tag(S_d_O_tag),
        .O_epoch(S_d_O_epoch),
        .O_previous_epoch(S_d_O_previous_epoch),
        .O_applied(S_d_O_applied),
        .O_retired(S_d_O_retired),
        .O_cancel_late(S_d_O_cancel_late),
        .O_acquired_mask(S_d_O_acquired_mask),
        .O_released_mask(S_d_O_released_mask),
        .O_host_active_mask(S_d_O_host_active_mask),
        .O_host_active_valid(S_d_O_host_active_valid),
        .O_host_active_epoch(S_d_O_host_active_epoch),
        .O_host_active_config(S_d_O_host_active_config),
        .O_host_reserve(S_d_O_host_reserve),
        .O_source_idle(S_d_O_source_idle),
        .O_source_busy(S_d_O_source_busy),
        .O_owned(S_d_O_owned),
        .O_lease_valid(S_d_O_lease_valid),
        .O_lease_slots(S_d_O_lease_slots),
        .O_lease_tokens(S_d_O_lease_tokens),
        .O_lease_generations(S_d_O_lease_generations),
        .O_lease_resident(S_d_O_lease_resident),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_readers(S_m_O_slot_readers),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .O_slot_cmd_valid(S_d_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_m_O_cmd_ready && S_cmd_gate && !S_fixture),
        .O_slot_cmd_op(S_d_O_slot_cmd_op),
        .O_slot_cmd_slot(S_d_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_d_O_slot_cmd_owner),
        .O_slot_cmd_token(S_d_O_slot_cmd_token),
        .O_slot_cmd_generation(S_d_O_slot_cmd_generation),
        .O_slot_frame_boundary(S_d_O_slot_frame_boundary),
        .O_slot_reader_retired(S_d_O_slot_reader_retired),
        .I_slot_result_valid(S_m_O_result_valid && !S_fixture),
        .O_slot_result_ready(S_d_O_slot_result_ready),
        .I_slot_result_error(S_m_O_result_error),
        .I_slot_result_op(S_m_O_result_op),
        .I_slot_result_slot(S_m_O_result_slot),
        .I_slot_result_owner(S_m_O_result_owner),
        .I_slot_result_token(S_m_O_result_token),
        .I_slot_result_generation(S_m_O_result_generation),
        .I_slot_result_base(S_m_O_result_base),
        .O_source_block(S_d_O_source_block),
        .O_reader_stop(S_d_O_reader_stop),
        .O_video_retire_ack(S_d_O_video_retire_ack),
        .O_source_fault(S_d_O_source_fault),
        .O_video_leases(S_d_O_video_leases),
        .O_video_lease_version(S_d_O_video_lease_version),
        .O_video_authorized(S_d_O_video_authorized),
        .O_next_epoch(S_d_O_next_epoch),
        .O_pending_valid(S_d_O_pending_valid),
        .O_pending_config(S_d_O_pending_config),
        .O_pending_tag(S_d_O_pending_tag),
        .O_pending_epoch(S_d_O_pending_epoch),
        .O_video_active_valid(S_d_O_video_active_valid),
        .O_video_active_config(S_d_O_video_active_config),
        .O_video_active_tag(S_d_O_video_active_tag),
        .O_video_response_discarded(S_d_O_video_response_discarded),
        .I_scan_stop(S_d_I_scan_stop),
        .O_scan_stop_ack(S_d_O_scan_stop_ack),
        .O_reader_retire_ack(S_d_O_reader_retire_ack),
        .O_reader_host_retired(S_d_O_reader_host_retired),
        .O_source_in_use(S_d_O_source_in_use),
        .O_source_owner_retired(S_d_O_source_owner_retired),
        .O_source_pipeline_retired(S_d_O_source_pipeline_retired),
        .O_prefetch_y(S_d_O_prefetch_y),
        .O_video_active_epoch(S_d_O_video_active_epoch),
        .O_frame_start(S_d_O_frame_start),
        .O_local_applied(S_d_O_local_applied),
        .O_valid(S_d_O_valid),
        .O_hsync(S_d_O_hsync),
        .O_vsync(S_d_O_vsync),
        .O_de(S_d_O_de),
        .O_x(S_d_O_x),
        .O_y(S_d_O_y),
        .O_rgb(S_d_O_rgb),
        .O_pixel_epoch(S_d_O_pixel_epoch),
        .O_pixel_tag(S_d_O_pixel_tag),
        .O_repeated(S_d_O_repeated),
        .O_pixel_fault(S_d_O_pixel_fault),
        .O_video_und(S_d_O_video_und),
        .O_und_count(S_d_O_und_count),
        .O_line_error_count(S_d_O_line_error_count),
        .O_mem_valid(S_d_O_mem_valid),
        .I_mem_ready(S_mem_enable),
        .O_mem_addr(S_d_O_mem_addr),
        .O_mem_tag(S_d_O_mem_tag),
        .O_mem_token(S_d_O_mem_token),
        .O_mem_generation(S_d_O_mem_generation),
        .O_mem_deadline(S_d_O_mem_deadline),
        .I_mem_valid(S_d_O_mem_valid & S_mem_enable),
        .O_mem_ready(S_d_O_mem_ready),
        .I_mem_data(64'h0000ffffff0000ff),
        .I_mem_tag(S_d_O_mem_tag),
        .I_mem_token(S_d_O_mem_token),
        .I_mem_generation(S_d_O_mem_generation),
        .I_mem_error(S_mem_error),
        .I_clock_enable(S_clock_enable),
        .O_host_time(S_host_time),
        .O_video_time(S_video_time),
        .O_deadline_quarantined(S_deadline_fault),
        .O_prepare_target(S_prepare_target)
    );

    wire [191:0] S_m_O_slot_assets;
    wire [17:0] S_m_O_slot_layouts;
    wire [11:0] S_m_O_slot_rotations;
    wire [5:0] S_m_O_slot_stale;
    wire [5:0] S_m_O_cancel_loading;
    wire  S_m_O_token_exhausted;
    fb_slot_manager u_fb_slot_manager (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(32'd11),
        .I_cmd_valid(S_fixture ? S_f_valid : (S_d_O_slot_cmd_valid && S_cmd_gate)),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_fixture ? S_f_op : S_d_O_slot_cmd_op),
        .I_cmd_slot(S_fixture ? S_f_slot : S_d_O_slot_cmd_slot),
        .I_cmd_owner(S_fixture ? 2'd2 : S_d_O_slot_cmd_owner),
        .I_cmd_token(S_fixture ? S_f_token : S_d_O_slot_cmd_token),
        .I_cmd_generation(S_fixture ? (S_f_slot==5 ? 32'd77 : 32'd11) : S_d_O_slot_cmd_generation),
        .I_cmd_asset(32'd9),
        .I_cmd_layout(3'd0),
        .I_cmd_rotation(2'd0),
        .I_cmd_resident(S_fixture && S_f_slot==5),
        .I_cmd_success(1'b1),
        .I_producer_retired(1'b1),
        .I_memory_retired(1'b1),
        .I_reader_retired(S_fixture ? 1'b1 : S_d_O_slot_reader_retired),
        .I_frame_boundary(S_fixture ? 1'b1 : S_d_O_slot_frame_boundary),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_fixture ? S_f_result_ready : S_d_O_slot_result_ready),
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

    task fail;
        input [767:0] message;
        begin $display("FAIL: resource pipeline case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin repeat(8) #1000000000; fail("watchdog timeout"); end
    function [20:0] slot_base;
        input [2:0] slot;
        begin case(slot)
            0:slot_base=21'h000000; 1:slot_base=21'h04b000; 2:slot_base=21'h096000;
            3:slot_base=21'h0e1000; 4:slot_base=21'h12c000; 5:slot_base=21'h177000;
            default:slot_base=21'h1fffff;
        endcase end
    endfunction
    function [69-1:0] source_lease;
        input [137:0] leases;
        input source;
        begin source_lease={leases[136+source],leases[130+source*3+:3],leases[66+source*32+:32],
            leases[2+source*32+:32],leases[source]}; end
    endfunction
    function [246:0] make_config;
        input [1:0] mask;
        input from_source;
        input [2:0] a,b;
        input [16:0] progress;
        input [1:0] banks;
        input audio;
        begin make_config={mask,from_source,{b,a},{S_tokens[b],S_tokens[a]},
            {(b==5 ? 32'd77 : 32'd11),(a==5 ? 32'd77 : 32'd11)},
            {(b==5),(a==5)},3'd0,16'd60,progress,4'd0,4'd0,5'd8,3'd0,2'd0,1'b0,audio,
            18'd0,banks,32'hc202c101}; end
    endfunction
    task fixture_cmd;
        input [2:0] op,slot;
        begin
            @(negedge S_host_clk); S_f_op=op; S_f_slot=slot; S_f_token=op==0 ? 0 : S_tokens[slot]; S_f_valid=1;
            @(posedge S_host_clk); while(!S_m_O_cmd_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_f_valid=0; wait(S_m_O_result_valid); #1;
            if(S_m_O_result_error!=0) fail("slot loading fixture failed");
            if(op==0) S_tokens[slot]=S_m_O_result_token;
            @(negedge S_host_clk); S_f_result_ready=1; @(negedge S_host_clk); S_f_result_ready=0;
        end
    endtask
    task reset_all;
        integer slot;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_fixture=1; S_f_valid=0; S_f_result_ready=0;
            S_d_I_video_allow_apply=1; S_d_I_audio_ready=0; S_d_I_audio_epoch=0;
            S_clock_enable=1; S_d_I_scan_stop=0;
            S_target_actual=0;
            S_cmd_gate=1; S_media_valid=1; S_mem_enable=3; S_mem_error=0;
            S_expect_fault=0; S_check_pixels=0; S_previous_video_leases=0;
            repeat(6) @(negedge S_video_clk); S_reset=0; wait(!S_host_reset);
            for(slot=0;slot<6;slot=slot+1) begin fixture_cmd(0,slot); fixture_cmd(1,slot); end
            @(negedge S_host_clk); S_fixture=0;
            wait(S_d_O_start_ready);
            S_commands=0; S_publishes=0; S_applies=0; S_pixels=0; S_frames=0;
            S_mem_counts[0]=0; S_mem_counts[1]=0;
        end
    endtask
    task choose_free_banks;
        input [1:0] mask;
        reg [3:0] occupied;
        begin
            occupied=15;
            while((mask[0] && occupied[1:0]==3) || (mask[1] && occupied[3:2]==3)) begin
                @(negedge S_video_clk);
                occupied=u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_r_O_bank_reserved |
                    u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_s_O_owned_banks |
                    u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_a_O_task_reserved;
            end
            S_next_banks={occupied[2],occupied[0]};
        end
    endtask
    task complete_frame;
        begin
            wait(S_d_O_frame_start); @(negedge S_video_clk); S_pixels=0;
            S_frame_epoch=S_d_O_video_active_epoch; S_check_pixels=1;
            @(negedge S_video_clk); wait(S_d_O_frame_start); @(negedge S_video_clk); #1; S_check_pixels=0;
            if(S_pixels!=307200) fail("complete real scanout frame pixel coverage");
        end
    endtask
    always @(posedge S_host_clk) if(!S_reset && !S_host_reset) begin
        if(u_timed.u_display_resource_pipeline.S_o_O_publish_valid && u_timed.u_display_resource_pipeline.S_l_O_publish_ready) begin
            S_last_publish=u_timed.u_display_resource_pipeline.S_o_O_publish_leases; S_last_version=u_timed.u_display_resource_pipeline.S_o_O_publish_version;
            S_publishes=S_publishes+1;
        end
        if(S_d_O_slot_cmd_valid && S_d_O_slot_cmd_owner<2 && S_m_O_cmd_ready && S_cmd_gate && !S_fixture) begin
            S_commands=S_commands+1;
            if(!S_d_O_host_reserve[S_d_O_slot_cmd_owner[0]] || !S_d_O_source_block[S_d_O_slot_cmd_owner[0]] ||
                S_d_O_source_in_use[S_d_O_slot_cmd_owner[0]]) fail("slot mutation escaped actual source reservation");
            if(S_d_O_slot_cmd_op==2 && !S_d_O_slot_frame_boundary) fail("acquire bypassed real frame permission");
            if(S_d_O_slot_cmd_op==3 && (!S_d_O_slot_reader_retired ||
                !S_d_O_reader_retire_ack[S_d_O_slot_cmd_owner[0]] ||
                !S_d_O_source_owner_retired[S_d_O_slot_cmd_owner[0]] ||
                !S_d_O_source_pipeline_retired[S_d_O_slot_cmd_owner[0]]))
                fail("release bypassed real reader/owner/pixel retirement");
        end
        for(S_i=0;S_i<2;S_i=S_i+1) if(S_d_O_mem_valid[S_i] && S_mem_enable[S_i]) begin
            S_mem_counts[S_i]=S_mem_counts[S_i]+1;
            if(!S_d_O_lease_valid[S_i] || S_d_O_mem_token[S_i*32+:32]!==S_d_O_lease_tokens[S_i*32+:32] ||
                S_d_O_mem_generation[S_i*32+:32]!==S_d_O_lease_generations[S_i*32+:32] ||
                S_d_O_mem_addr[S_i*21+:21]<slot_base(S_d_O_lease_slots[S_i*3+:3]) ||
                S_d_O_mem_addr[S_i*21+:21]>=slot_base(S_d_O_lease_slots[S_i*3+:3])+307200)
                fail("memory request lost real host lock identity or slot extent");
        end
        #1; if(!S_expect_fault && S_d_O_host_quarantined) fail("unexpected host isolation");
    end
    always @(posedge S_video_clk) if(!S_reset && u_timed.u_display_resource_pipeline.S_c_O_apply_valid) begin
        begin
            S_target_lag=S_video_time-S_target_time;
            if(!S_target_valid || S_target_epoch!==S_d_O_pending_epoch || S_target_tag!==S_d_O_pending_tag ||
                S_target_lag[31] || S_target_lag%32'd420000!=0)
                fail("targeted apply preceded requested frame or lost mapped identity/grid");
            S_target_actual=S_video_time;
        end
        if(!S_d_O_frame_start || !u_timed.u_display_resource_pipeline.S_p_O_can_apply ||
            !u_timed.u_display_resource_pipeline.u_display_video_pipeline.u_scanout_engine.S_install ||
            !u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_c_O_adopt_ready)
            fail("apply did not atomically install scanout and adopt all seeds");
        if(S_d_O_pending_config[52] && (!S_d_I_audio_ready || S_d_I_audio_epoch!==S_d_O_pending_epoch))
            fail("audio-required apply lacked matching audio epoch");
        S_seed_mask=0;
        if(S_d_O_pending_config[245]) S_seed_mask[S_d_O_pending_config[32]]=1;
        if(S_d_O_pending_config[246]) S_seed_mask[2+S_d_O_pending_config[33]]=1;
        S_saved_epoch=S_d_O_pending_epoch;
        #1;
        if(S_d_O_video_active_epoch!==S_saved_epoch || u_timed.u_display_resource_pipeline.S_c_O_active_epoch!==S_saved_epoch ||
            !S_d_O_local_applied || !u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_c_O_adopted ||
            (u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_s_O_owned_banks & S_seed_mask)!==S_seed_mask ||
            u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_c_O_owned_banks!=0)
            fail("partial seed ownership or delayed local epoch installation");
        S_applies=S_applies+1;
    end
    always @(negedge S_video_clk) if(!S_reset) begin
        if(!S_expect_fault && (S_d_O_video_quarantined || S_d_O_pixel_fault)) fail("unexpected video/pixel isolation");
        if(S_d_O_frame_start) S_frames=S_frames+1;
        if(S_check_pixels && S_d_O_valid && S_d_O_de) begin
            if(S_d_O_rgb!==24'h0000ff || S_d_O_pixel_epoch!==S_frame_epoch || S_d_O_repeated)
                fail("real leased pixel/epoch continuity");
            S_pixels=S_pixels+1;
        end
        if((S_d_O_reader_stop & S_d_O_source_in_use)!=0) fail("reader stopped a source still in real use");
        if(u_timed.u_display_resource_pipeline.S_l_O_video_installed) begin
            if(S_d_O_video_leases!==S_last_publish || S_d_O_video_lease_version!==S_last_version)
                fail("real publication changed accepted snapshot");
            for(S_v_i=0;S_v_i<2;S_v_i=S_v_i+1)
                if(source_lease(S_d_O_video_leases,S_v_i)!==source_lease(S_previous_video_leases,S_v_i) &&
                    (!S_d_O_source_block[S_v_i] || S_d_O_source_in_use[S_v_i] ||
                    !S_d_O_source_owner_retired[S_v_i] || !S_d_O_source_pipeline_retired[S_v_i]))
                    fail("lease installed before actual source proof");
            S_previous_video_leases=S_d_O_video_leases;
        end
    end
    reg [31:0] S_last_prepare_deadline=0;
    integer S_real_deadlines=0;
    always @(posedge S_video_clk) if(!S_reset) begin
        if(u_timed.u_display_resource_pipeline.u_display_video_pipeline.u_scanout_engine.C_new_task) begin
            if(!u_timed.S_s_O_scan_deadline_valid || u_timed.S_s_O_scan_deadline==32'h7fffffff ||
                u_timed.S_s_O_scan_deadline_epoch!==S_d_O_video_active_epoch ||
                u_timed.S_s_O_scan_deadline_y!==S_d_O_prefetch_y)
                fail("real scanout task bypassed converted row/epoch deadline");
        end
        if(u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_prepare_fire) begin
            if(!u_timed.S_s_O_prepare_deadline_valid ||
                u_timed.S_s_O_prepare_deadline_epoch!==S_d_O_pending_epoch ||
                u_timed.S_s_O_prepare_deadlines[31:0]==32'h7fffffff)
                fail("actual prepare retained a constant or mismatched deadline");
            S_last_prepare_deadline=u_timed.S_s_O_prepare_deadlines[31:0];
            S_real_deadlines=S_real_deadlines+1;
        end
        if(u_timed.u_display_resource_pipeline.S_c_O_apply_valid &&
            (!u_timed.S_s_O_allow_apply || S_video_time!==S_prepare_target))
            fail("configuration applied outside the selected real deadline target frame");
    end
    // Images are a stable same-domain availability fixture, independent of READ_LOCK.
    // There is no WAV/guard peer in these audio_action=0 real-display scenarios.
    wire S_video_reset;
    reset_sync u_event_reset (.I_clk(S_video_clk),.I_async_reset(S_reset),.O_reset(S_video_reset));
    reg [246:0] S_base_config=0;
    reg S_o_I_sample_tick=0;
    reg S_o_I_start_valid=0;
    wire S_o_O_start_ready;
    reg [31:0] S_o_I_epoch=0;
    reg [15:0] S_o_I_tag=0;
    reg [2:0] S_o_I_effect=0;
    reg [15:0] S_o_I_duration_frames=0;
    reg signed [6:0] S_o_I_av_offset_steps=0;
    reg [1:0] S_o_I_audio_action=0;
    reg S_o_I_audio_slot=0;
    reg [15:0] S_o_I_track_epoch=0;
    reg [31:0] S_o_I_track_serial=0;
    reg [31:0] S_o_I_start_index=0;
    reg [137:0] S_o_I_images=0;
    reg S_o_I_pause=0;
    reg S_o_I_abort=0;
    wire S_o_O_pause_allow;
    wire [1:0] S_o_O_image_hold;
    wire [1:0] S_o_O_audio_hold;
    wire [246:0] S_o_O_frozen_config;
    wire S_o_O_audio_bind_valid;
    reg S_o_I_audio_bind_ready=0;
    wire [31:0] S_o_O_audio_bind_epoch;
    wire [15:0] S_o_O_audio_bind_tag;
    wire S_o_O_audio_bind_slot;
    wire [15:0] S_o_O_audio_bind_track_epoch;
    wire [31:0] S_o_O_audio_bind_serial;
    wire [31:0] S_o_O_audio_bind_index;
    wire S_o_O_audio_bind_reuse;
    wire S_o_O_audio_pending;
    wire S_o_O_audio_unbind;
    reg S_o_I_audio_bound=0;
    reg [3:0] S_o_I_audio_bind_error=0;
    reg S_o_I_audio_ready=0;
    reg [31:0] S_o_I_audio_epoch=0;
    reg [1:0] S_o_I_track_known=0;
    reg [1:0] S_o_I_track_enabled=0;
    reg [1:0] S_o_I_track_consumed=0;
    reg [31:0] S_o_I_track_epochs=0;
    reg [63:0] S_o_I_track_serials=0;
    reg [63:0] S_o_I_track_totals=0;
    reg [63:0] S_o_I_track_next_index=0;
    wire S_o_O_play_valid;
    wire S_o_O_fade_valid;
    wire S_o_O_target_b;
    reg S_o_I_play_ready=0;
    reg S_o_I_fade_ready=0;
    reg S_o_I_fade_done=0;
    reg S_o_I_active_b=0;
    wire S_o_O_audio_stop_request;
    reg S_o_I_audio_stop_ack=0;
    wire S_o_O_event_valid;
    wire S_o_I_event_ready;
    wire S_o_O_event_cancel;
    wire [31:0] S_o_O_event_epoch;
    wire [15:0] S_o_O_event_tag;
    wire [15:0] S_o_O_event_index;
    wire [2:0] S_o_O_event_effect;
    wire [16:0] S_o_O_event_progress;
    wire [31:0] S_o_O_event_target;
    wire [246:0] S_o_O_event_config;
    wire S_o_I_event_done_valid;
    wire S_o_O_event_done_ready;
    wire [31:0] S_o_I_event_done_epoch;
    wire [15:0] S_o_I_event_done_tag;
    wire [15:0] S_o_I_event_done_index;
    wire [3:0] S_o_I_event_done_error;
    wire S_o_I_event_done_applied;
    wire [31:0] S_o_I_event_done_time;
    reg S_o_I_recover_valid=0;
    reg S_o_I_recover_source=0;
    wire S_o_O_recover_ready;
    wire S_o_O_busy;
    wire S_o_O_done_valid;
    reg S_o_I_done_ready=0;
    wire [31:0] S_o_O_epoch;
    wire [15:0] S_o_O_tag;
    wire [3:0] S_o_O_error;
    wire [3:0] S_o_O_timeline_error;
    wire [3:0] S_o_O_settle_error;
    wire [3:0] S_o_O_bind_error;
    wire S_o_O_settled;
    wire S_o_O_recovery_required;
    wire S_o_O_recovery_result;
    wire S_o_O_cancel_late;
    wire S_o_O_selected_source;
    wire S_o_O_video_started;
    wire S_o_O_video_finished;
    wire S_o_O_audio_started;
    wire S_o_O_audio_finished;
    wire [31:0] S_o_O_actual_start;
    wire [31:0] S_o_O_actual_midpoint;
    wire [31:0] S_o_O_actual_audio;
    wire [31:0] S_o_O_dwell_start;
    wire [31:0] S_o_O_settle_time;
    wire [31:0] S_o_O_commit_epoch;
    wire signed [31:0] S_o_O_anchor_error;
    wire [16:0] S_o_O_last_progress;
    wire S_o_O_quarantined;
    wire S_o_O_response_discarded;
    wire S_e_O_busy;
    wire [3:0] S_e_O_backend_error;
    wire [3:0] S_e_O_lease_error;
    wire [3:0] S_e_O_slot_error;
    wire [3:0] S_e_O_commit_error;
    wire [3:0] S_e_O_prepare_error;
    wire [3:0] S_e_O_retire_error;
    wire S_e_O_retired;
    wire [31:0] S_e_O_commit_epoch;
    wire S_e_O_quarantined;
    wire S_e_O_response_discarded;
    wire S_e_O_host_quarantined;
    wire S_e_O_host_response_discarded;
    playback_transition_owner u_owner (
        .I_clk(S_video_clk),
        .I_reset(S_video_reset),
        .I_clock_enable(S_clock_enable),
        .I_time(S_video_time),
        .I_frame_start(S_d_O_frame_start),
        .I_sample_tick(S_o_I_sample_tick),
        .I_start_valid(S_o_I_start_valid),
        .O_start_ready(S_o_O_start_ready),
        .I_epoch(S_o_I_epoch),
        .I_tag(S_o_I_tag),
        .I_config(S_base_config),
        .I_effect(S_o_I_effect),
        .I_duration_frames(S_o_I_duration_frames),
        .I_av_offset_steps(S_o_I_av_offset_steps),
        .I_audio_action(S_o_I_audio_action),
        .I_audio_slot(S_o_I_audio_slot),
        .I_track_epoch(S_o_I_track_epoch),
        .I_track_serial(S_o_I_track_serial),
        .I_start_index(S_o_I_start_index),
        .I_images(S_o_I_images),
        .I_display_leases(S_d_O_video_leases),
        .I_pause(S_o_I_pause),
        .I_abort(S_o_I_abort),
        .O_pause_allow(S_o_O_pause_allow),
        .O_image_hold(S_o_O_image_hold),
        .O_audio_hold(S_o_O_audio_hold),
        .O_frozen_config(S_o_O_frozen_config),
        .O_audio_bind_valid(S_o_O_audio_bind_valid),
        .I_audio_bind_ready(S_o_I_audio_bind_ready),
        .O_audio_bind_epoch(S_o_O_audio_bind_epoch),
        .O_audio_bind_tag(S_o_O_audio_bind_tag),
        .O_audio_bind_slot(S_o_O_audio_bind_slot),
        .O_audio_bind_track_epoch(S_o_O_audio_bind_track_epoch),
        .O_audio_bind_serial(S_o_O_audio_bind_serial),
        .O_audio_bind_index(S_o_O_audio_bind_index),
        .O_audio_bind_reuse(S_o_O_audio_bind_reuse),
        .O_audio_pending(S_o_O_audio_pending),
        .O_audio_unbind(S_o_O_audio_unbind),
        .I_audio_bound(S_o_I_audio_bound),
        .I_audio_bind_error(S_o_I_audio_bind_error),
        .I_audio_ready(S_o_I_audio_ready),
        .I_audio_epoch(S_o_I_audio_epoch),
        .I_track_known(S_o_I_track_known),
        .I_track_enabled(S_o_I_track_enabled),
        .I_track_consumed(S_o_I_track_consumed),
        .I_track_epochs(S_o_I_track_epochs),
        .I_track_serials(S_o_I_track_serials),
        .I_track_totals(S_o_I_track_totals),
        .I_track_next_index(S_o_I_track_next_index),
        .O_play_valid(S_o_O_play_valid),
        .O_fade_valid(S_o_O_fade_valid),
        .O_target_b(S_o_O_target_b),
        .I_play_ready(S_o_I_play_ready),
        .I_fade_ready(S_o_I_fade_ready),
        .I_fade_done(S_o_I_fade_done),
        .I_active_b(S_o_I_active_b),
        .O_audio_stop_request(S_o_O_audio_stop_request),
        .I_audio_stop_ack(S_o_I_audio_stop_ack),
        .O_event_valid(S_o_O_event_valid),
        .I_event_ready(S_o_I_event_ready),
        .O_event_cancel(S_o_O_event_cancel),
        .O_event_epoch(S_o_O_event_epoch),
        .O_event_tag(S_o_O_event_tag),
        .O_event_index(S_o_O_event_index),
        .O_event_effect(S_o_O_event_effect),
        .O_event_progress(S_o_O_event_progress),
        .O_event_target(S_o_O_event_target),
        .O_event_config(S_o_O_event_config),
        .I_event_busy(S_e_O_busy),
        .I_event_done_valid(S_o_I_event_done_valid),
        .O_event_done_ready(S_o_O_event_done_ready),
        .I_event_done_epoch(S_o_I_event_done_epoch),
        .I_event_done_tag(S_o_I_event_done_tag),
        .I_event_done_index(S_o_I_event_done_index),
        .I_event_done_error(S_o_I_event_done_error),
        .I_event_done_applied(S_o_I_event_done_applied),
        .I_event_done_retired(S_e_O_retired),
        .I_event_done_time(S_o_I_event_done_time),
        .I_event_commit_epoch(S_e_O_commit_epoch),
        .I_event_quarantined(S_e_O_quarantined),
        .I_active_valid(S_d_O_video_active_valid),
        .I_active_config(S_d_O_video_active_config),
        .I_active_epoch(S_d_O_video_active_epoch),
        .I_active_tag(S_d_O_video_active_tag),
        .I_recover_valid(S_o_I_recover_valid),
        .I_recover_source(S_o_I_recover_source),
        .O_recover_ready(S_o_O_recover_ready),
        .O_busy(S_o_O_busy),
        .O_done_valid(S_o_O_done_valid),
        .I_done_ready(S_o_I_done_ready),
        .O_epoch(S_o_O_epoch),
        .O_tag(S_o_O_tag),
        .O_error(S_o_O_error),
        .O_timeline_error(S_o_O_timeline_error),
        .O_settle_error(S_o_O_settle_error),
        .O_bind_error(S_o_O_bind_error),
        .O_settled(S_o_O_settled),
        .O_recovery_required(S_o_O_recovery_required),
        .O_recovery_result(S_o_O_recovery_result),
        .O_cancel_late(S_o_O_cancel_late),
        .O_selected_source(S_o_O_selected_source),
        .O_video_started(S_o_O_video_started),
        .O_video_finished(S_o_O_video_finished),
        .O_audio_started(S_o_O_audio_started),
        .O_audio_finished(S_o_O_audio_finished),
        .O_actual_start(S_o_O_actual_start),
        .O_actual_midpoint(S_o_O_actual_midpoint),
        .O_actual_audio(S_o_O_actual_audio),
        .O_dwell_start(S_o_O_dwell_start),
        .O_settle_time(S_o_O_settle_time),
        .O_commit_epoch(S_o_O_commit_epoch),
        .O_anchor_error(S_o_O_anchor_error),
        .O_last_progress(S_o_O_last_progress),
        .O_quarantined(S_o_O_quarantined),
        .O_response_discarded(S_o_O_response_discarded),
        .O_silence_valid(S_silence_u_owner_O_silence_valid),
        .I_silence_ready(1'b0),
        .I_silence_started(1'b0),
        .I_silence_done(1'b0)
    );
    display_event_executor u_executor (
        .I_frame_start(S_d_O_frame_start),.I_active_valid(S_d_O_video_active_valid),
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_clock_enable(S_clock_enable),
        .I_video_time(S_video_time),
        .I_event_valid(S_o_O_event_valid),
        .O_event_ready(S_o_I_event_ready),
        .I_event_epoch(S_o_O_event_epoch),
        .I_event_tag(S_o_O_event_tag),
        .I_event_index(S_o_O_event_index),
        .I_event_effect(S_o_O_event_effect),
        .I_event_progress(S_o_O_event_progress),
        .I_event_target(S_o_O_event_target),
        .I_config(S_o_O_event_config),
        .I_cancel(S_o_O_event_cancel),
        .I_bank_busy(S_bank_busy),
        .O_busy(S_e_O_busy),
        .O_done_valid(S_o_I_event_done_valid),
        .I_done_ready(S_o_O_event_done_ready),
        .O_epoch(S_o_I_event_done_epoch),
        .O_tag(S_o_I_event_done_tag),
        .O_index(S_o_I_event_done_index),
        .O_error(S_o_I_event_done_error),
        .O_backend_error(S_e_O_backend_error),
        .O_lease_error(S_e_O_lease_error),
        .O_slot_error(S_e_O_slot_error),
        .O_commit_error(S_e_O_commit_error),
        .O_prepare_error(S_e_O_prepare_error),
        .O_retire_error(S_e_O_retire_error),
        .O_applied(S_o_I_event_done_applied),
        .O_retired(S_e_O_retired),
        .O_apply_time(S_o_I_event_done_time),
        .O_commit_epoch(S_e_O_commit_epoch),
        .O_quarantined(S_e_O_quarantined),
        .O_response_discarded(S_e_O_response_discarded),
        .O_target_valid(S_target_valid),
        .O_target_epoch(S_target_epoch),
        .O_target_time(S_target_time),
        .O_target_tag(S_target_tag),
        .O_video_abort(S_d_I_video_abort),
        .I_pending_valid(S_d_O_pending_valid),
        .I_pending_config(S_d_O_pending_config),
        .I_pending_epoch(S_d_O_pending_epoch),
        .I_pending_tag(S_d_O_pending_tag),
        .I_local_applied(S_d_O_local_applied),
        .I_active_config(S_d_O_video_active_config),
        .I_active_epoch(S_d_O_video_active_epoch),
        .I_active_tag(S_d_O_video_active_tag),
        .O_host_start_valid(S_d_I_start_valid),
        .I_host_start_ready(S_d_O_start_ready),
        .O_host_config(S_d_I_config),
        .O_host_tag(S_d_I_tag),
        .O_host_abort(S_d_I_abort),
        .I_host_next_epoch(S_d_O_next_epoch),
        .I_host_done_valid(S_d_O_done_valid),
        .O_host_done_ready(S_d_I_done_ready),
        .I_host_epoch(S_d_O_epoch),
        .I_host_tag(S_d_O_tag),
        .I_host_error(S_d_O_error),
        .I_host_lease_error(S_d_O_lease_error),
        .I_host_slot_error(S_d_O_slot_error),
        .I_host_commit_error(S_d_O_commit_error),
        .I_host_prepare_error(S_d_O_prepare_error),
        .I_host_retire_error(S_d_O_retire_error),
        .I_host_applied(S_d_O_applied),
        .I_host_retired(S_d_O_retired),
        .I_host_quarantined(S_d_O_host_quarantined),
        .O_host_quarantined(S_e_O_host_quarantined),
        .O_host_response_discarded(S_e_O_host_response_discarded)
    );
    integer S_animation_results=0,S_cleanup_results=0,S_pixel_checks=0;
    integer S_acquires=0,S_releases=0;
    reg [31:0] S_last_commit=0,S_last_animation_time=0;
    reg S_monitor_pixels=0,S_normal=0;
    function [137:0] image_proof;
        input [246:0] cfg;
        input [1:0] mask;
        begin image_proof={mask,cfg[243:238],cfg[237:174],cfg[173:110],cfg[109:108]}; end
    endfunction
    // Independent logical source selection for progress 0 / 32768 / 65536.
    function [23:0] expected_pixel;
        input [246:0] cfg;
        input [15:0] x,y;
        reg choose_to,physical;
        reg [7:0] rank;
        begin
            choose_to=0; rank=((x>>3)*37)^((y>>3)*73);
            if(cfg[88:72]==65536) choose_to=1;
            else if(cfg[88:72]!=0) case(cfg[107:105])
                0:choose_to=0;
                1,2:choose_to=x>=320;
                3:choose_to=x*480+y*640<307200;
                4:choose_to=(x[5] ? 31-(x%32) : x%32)<16;
                5:choose_to=rank<128;
                6:choose_to=x>=160 && x<480 && y>=120 && y<360;
                default:choose_to=0;
            endcase
            physical=choose_to ? !cfg[244] : cfg[244];
            if(cfg[246:245]==1) expected_pixel=24'hff0000;
            else if(cfg[246:245]==2) expected_pixel=24'h0000ff;
            else if(cfg[107:105]==0 && cfg[88:72]==32768) expected_pixel=24'h800080;
            else expected_pixel=physical ? 24'h0000ff : 24'hff0000;
        end
    endfunction
    always @(negedge S_video_clk) if(!S_video_reset && S_monitor_pixels && S_d_O_valid && S_d_O_de && S_d_O_pixel_epoch!=0) begin
        if(S_d_O_pixel_epoch!==S_d_O_video_active_epoch || S_d_O_repeated ||
            S_d_O_rgb!==expected_pixel(S_d_O_video_active_config,S_d_O_x,S_d_O_y))
            fail("single/dual source pixel reference lost physical from direction or active identity");
        S_pixel_checks=S_pixel_checks+1;
    end
    always @(posedge S_host_clk) begin
        if(S_host_reset) begin S_acquires=0; S_releases=0; end
        else if(!S_fixture && S_d_O_slot_cmd_valid && S_m_O_cmd_ready && S_cmd_gate) begin
            if(S_d_O_slot_cmd_op==2) S_acquires=S_acquires+1;
            if(S_d_O_slot_cmd_op==3) S_releases=S_releases+1;
        end
    end
    always @(posedge S_video_clk) begin
        if(S_video_reset) begin
            S_animation_results=0; S_cleanup_results=0; S_last_commit=0; S_last_animation_time=0; S_pixel_checks=0;
        end else begin
            if(S_d_O_local_applied) begin
                if(S_d_O_video_active_epoch<=S_last_commit) fail("underlying actual commit epoch did not advance");
                S_last_commit=S_d_O_video_active_epoch;
            end
            if(S_o_I_event_done_valid && S_o_O_event_done_ready) begin
                if(S_o_I_event_done_epoch!==S_o_O_epoch || S_o_I_event_done_tag!==S_o_O_tag)
                    fail("owner result lost actual executor transaction identity");
                if(S_o_I_event_done_index==16'hffff) begin
                    S_cleanup_results=S_cleanup_results+1;
                    if(S_o_I_event_done_error!=0 || !S_o_I_event_done_applied || !S_e_O_retired ||
                        S_d_O_video_active_config[246:245]!=(2'b01<<S_o_O_selected_source))
                        fail("single-source cleanup lacked actual apply and retirement");
                end else begin
                    S_animation_results=S_animation_results+1;
                    if(S_normal && (S_o_I_event_done_index!=S_animation_results-1 || S_o_I_event_done_error!=0 ||
                        !S_o_I_event_done_applied || !S_e_O_retired || S_e_O_quarantined))
                        fail("normal animation did not retire actual ordered executor results");
                    if(S_o_I_event_done_applied && S_o_I_event_done_index==2) S_last_animation_time=S_o_I_event_done_time;
                end
            end
        end
    end
    task prepare_case;
        begin
            S_o_I_start_valid=0; S_o_I_done_ready=0; S_o_I_pause=0; S_o_I_abort=0;
            S_o_I_recover_valid=0; S_o_I_recover_source=0; S_o_I_audio_action=0;
            S_normal=0; S_monitor_pixels=0; reset_all;
        end
    endtask
    task begin_transition;
        input [31:0] epoch;
        input from_source;
        input [2:0] effect;
        begin
            wait(S_o_O_start_ready);
            @(negedge S_video_clk);
            S_base_config=make_config(3,from_source,0,1,0,0,0); S_base_config[104:89]=2;
            S_o_I_images=image_proof(S_base_config,3);
            S_o_I_epoch=epoch; S_o_I_tag=16'h9000+epoch[15:0]; S_o_I_effect=effect;
            S_o_I_duration_frames=2; S_o_I_av_offset_steps=0;
            S_o_I_abort=0; S_o_I_done_ready=0; S_o_I_start_valid=1;
            S_animation_results=0; S_cleanup_results=0; S_last_animation_time=0;
            @(posedge S_video_clk); while(!S_o_O_start_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_o_I_start_valid=0;
        end
    endtask
    task finish_transition;
        input [3:0] error;
        input settled,source;
        reg [196:0] held;
        begin
            wait(S_o_O_done_valid); #1;
            if(S_o_O_error!==error || S_o_O_settled!==settled ||
                (settled && (S_o_O_image_hold!==(2'b01<<source) || S_o_O_selected_source!==source ||
                    S_d_O_video_leases[137:136]!==(2'b01<<source) || S_d_O_owned!==(2'b01<<source) ||
                    S_m_O_slot_readers[2:0]!=(source ? 0 : 1) || S_m_O_slot_readers[5:3]!=(source ? 2 : 0))))
                fail("terminal preceded actual single-source lease installation and old READ_RELEASE");
            if(S_normal && (S_animation_results!=3 || S_cleanup_results!=1 ||
                S_o_O_dwell_start!==S_last_animation_time || S_o_O_settle_time<=S_o_O_dwell_start))
                fail("dwell anchor or complete animation/single-source sequence was fabricated");
            held={S_o_O_epoch,S_o_O_tag,S_o_O_error,S_o_O_timeline_error,S_o_O_settle_error,S_o_O_bind_error,
                S_o_O_settled,S_o_O_recovery_required,S_o_O_cancel_late,S_o_O_image_hold,
                S_o_O_actual_start,S_o_O_dwell_start,S_o_O_settle_time,S_o_O_commit_epoch};
            S_o_I_abort=1;
            repeat(12) begin @(negedge S_video_clk);
                if(!S_o_O_done_valid || held!=={S_o_O_epoch,S_o_O_tag,S_o_O_error,S_o_O_timeline_error,
                    S_o_O_settle_error,S_o_O_bind_error,S_o_O_settled,S_o_O_recovery_required,S_o_O_cancel_late,
                    S_o_O_image_hold,S_o_O_actual_start,S_o_O_dwell_start,S_o_O_settle_time,S_o_O_commit_epoch})
                    fail("owner result changed under real-chain terminal backpressure"); end
            S_o_I_done_ready=1; @(negedge S_video_clk); S_o_I_done_ready=0; S_o_I_abort=0;
        end
    endtask
    task observe_frame;
        integer count;
        begin
            wait(S_d_O_frame_start); @(negedge S_video_clk); count=0;
            @(negedge S_video_clk);
            while(!S_d_O_frame_start) begin
                if(S_d_O_valid && S_d_O_de) count=count+1;
                @(negedge S_video_clk);
            end
            if(count!=307200) fail("settled single-source frame did not contain all visible pixels");
        end
    endtask
    initial begin
        S_case=1; prepare_case; S_normal=1; S_monitor_pixels=1;
        begin_transition(1,0,2); finish_transition(0,1,1); observe_frame;
        if(S_acquires!=2 || S_releases!=1 || S_commands!=3 || S_publishes!=3 || S_applies!=4)
            fail("forward transition did not acquire two sources and actually release old A once");
        // Preserve the live display/slot owners: reacquire A, retain B, then release B.
        begin_transition(2,1,2); finish_transition(0,1,0); observe_frame;
        if(S_acquires!=3 || S_releases!=2 || S_commands!=5 || S_publishes!=5 || S_applies!=8 ||
            S_d_O_und_count!=0 || S_pixel_checks<8*307200 || S_deadline_fault)
            fail("reverse transition reloaded retained source or omitted real old-B release/pixels");

        S_case=2; prepare_case; S_mem_enable=0;
        begin_transition(1,0,0); wait(S_d_O_mem_valid[0]);
        @(negedge S_video_clk); S_o_I_abort=1;
        repeat(50) begin @(negedge S_video_clk);
            if(S_o_O_done_valid || S_o_O_image_hold!=3 || S_applies!=0)
                fail("cancel bypassed actual candidate memory obligations"); end
        S_mem_enable=3; finish_transition(3,1,0);
        if(S_applies!=1 || S_cleanup_results!=1) fail("pre-apply cancel failed real from-only cleanup");

        S_case=3; prepare_case; S_monitor_pixels=1;
        begin_transition(1,0,2); wait(S_o_O_last_progress==0 && S_animation_results==1);
        @(negedge S_video_clk); S_o_I_abort=1; finish_transition(3,1,0); observe_frame;
        if(!S_o_O_video_started || !S_o_O_cancel_late) fail("late cancel erased actual first-frame fact");

        S_case=4; prepare_case; S_monitor_pixels=1;
        begin_transition(1,0,2); wait(S_o_O_last_progress==32768);
        @(negedge S_video_clk); S_o_I_abort=1; finish_transition(3,1,1); observe_frame;

        S_case=5; prepare_case; begin_transition(1,0,0);
        wait(S_o_O_event_valid); @(negedge S_video_clk); S_o_I_images[136]=0;
        finish_transition(4,0,0);
        if(!S_o_O_recovery_required || S_o_O_image_hold!=3 || S_o_O_start_ready)
            fail("missing old-source availability falsely completed recovery");
        S_o_I_images=image_proof(S_o_O_frozen_config,3); S_o_I_recover_source=1;
        wait(S_o_O_recover_ready); @(negedge S_video_clk); S_o_I_recover_valid=1;
        @(negedge S_video_clk); S_o_I_recover_valid=0; finish_transition(0,1,1);
        if(!S_o_O_recovery_result) fail("explicit actual display recovery lost its result identity");

        S_case=6; prepare_case; S_normal=1;
        begin_transition(1,0,6); wait(S_d_O_pending_valid);
        @(negedge S_video_clk); S_host_run=0;
        repeat(200) begin @(negedge S_video_clk);
            if(S_o_O_done_valid || S_cleanup_results!=0 || S_o_O_image_hold!=3)
                fail("stopped host fabricated single-source retirement"); end
        S_host_run=1; finish_transition(0,1,1);

        S_case=7; prepare_case; S_normal=1;
        begin_transition(1,0,0); wait(S_o_O_event_valid && S_o_O_event_index==16'hffff);
        @(negedge S_video_clk); S_o_I_abort=1; finish_transition(0,1,1);
        if(!S_o_O_cancel_late || S_e_O_quarantined) fail("late abort withdrew real single-source cleanup");

        $display("PASS: 7 real transition-owner/display-chain scenarios, bidirectional reuse, actual old-source releases and recovery");
        S_test_pass=1; $finish;
    end
endmodule
