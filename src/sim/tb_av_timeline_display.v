`timescale 1ns/1ps
// Real host owner + lease/commit CDC + candidate/scanout/reader + slot manager/RAM.
// Actual deadline scheduler/CDC; only slot loading, logical memory and audio readiness are fixtures.
module tb_av_timeline_display;
    wire S_silence_u_timeline_O_silence_valid;
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
    initial begin repeat(4) #1000000000; fail("watchdog timeout"); end
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
    wire S_video_reset;
    reset_sync u_event_reset (.I_clk(S_video_clk),.I_async_reset(S_reset),.O_reset(S_video_reset));
    reg [246:0] S_base_config=0;
    reg S_t_I_sample_tick=0;
    reg S_t_I_start_valid=0;
    wire S_t_O_start_ready;
    reg [31:0] S_t_I_epoch=0;
    reg [15:0] S_t_I_tag=0;
    reg [2:0] S_t_I_effect=0;
    reg [15:0] S_t_I_duration_frames=0;
    reg signed [6:0] S_t_I_av_offset_steps=0;
    reg [1:0] S_t_I_audio_action=0;
    reg S_t_I_audio_slot=0;
    reg [15:0] S_t_I_track_epoch=0;
    reg [31:0] S_t_I_track_serial=0;
    reg [31:0] S_t_I_start_index=0;
    reg S_t_I_resources_ready=0;
    reg [31:0] S_t_I_resources_epoch=0;
    reg [15:0] S_t_I_resources_tag=0;
    reg [1:0] S_t_I_track_known=0;
    reg [1:0] S_t_I_track_enabled=0;
    reg [1:0] S_t_I_track_consumed=0;
    reg [31:0] S_t_I_track_epochs=0;
    reg [63:0] S_t_I_track_serials=0;
    reg [63:0] S_t_I_track_totals=0;
    reg [63:0] S_t_I_track_next_index=0;
    reg S_t_I_pause=0;
    reg S_t_I_abort=0;
    wire S_t_O_pause_allow;
    wire S_t_O_video_valid;
    wire S_t_I_video_ready;
    wire S_t_O_video_cancel;
    wire [31:0] S_t_O_video_epoch;
    wire [15:0] S_t_O_video_tag;
    wire [2:0] S_t_O_video_effect;
    wire [15:0] S_t_O_video_frame_index;
    wire [16:0] S_t_O_video_progress;
    wire [31:0] S_t_O_video_target_time;
    wire S_t_I_video_done_valid;
    wire S_t_O_video_done_ready;
    wire [31:0] S_t_I_video_done_epoch;
    wire [15:0] S_t_I_video_done_tag;
    wire [15:0] S_t_I_video_done_frame_index;
    wire [3:0] S_t_I_video_done_error;
    wire S_t_I_video_done_applied;
    wire [31:0] S_t_I_video_done_time;
    wire S_t_O_play_valid;
    reg S_t_I_play_ready=0;
    wire S_t_O_fade_valid;
    wire S_t_O_target_b;
    wire [31:0] S_t_O_audio_target_time;
    reg S_t_I_fade_ready=0;
    reg S_t_I_fade_done=0;
    reg S_t_I_active_b=0;
    wire S_t_O_audio_stop_request;
    reg S_t_I_audio_stop_ack=0;
    wire S_t_O_busy;
    wire S_t_O_done_valid;
    reg S_t_I_done_ready=0;
    wire [3:0] S_t_O_error;
    wire [31:0] S_t_O_epoch;
    wire [15:0] S_t_O_tag;
    wire S_t_O_cancel_late;
    wire S_t_O_video_started;
    wire S_t_O_video_finished;
    wire S_t_O_audio_started;
    wire S_t_O_audio_finished;
    wire [31:0] S_t_O_planned_start;
    wire [31:0] S_t_O_planned_midpoint;
    wire [31:0] S_t_O_planned_audio;
    wire [31:0] S_t_O_actual_start;
    wire [31:0] S_t_O_actual_midpoint;
    wire [31:0] S_t_O_actual_audio;
    wire [31:0] S_t_O_actual_finish;
    wire [31:0] S_t_O_audio_command_time;
    wire [31:0] S_t_O_audio_start_index;
    wire signed [31:0] S_t_O_anchor_error;
    wire S_t_O_midpoint_seen;
    wire S_t_O_late;
    wire S_t_O_contract_fault;
    wire S_t_O_quarantined;
    wire S_t_O_response_discarded;
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
    av_event_timeline u_timeline (
        .I_clk(S_video_clk),
        .I_reset(S_video_reset),
        .I_clock_enable(S_clock_enable),
        .I_time(S_video_time),
        .I_frame_start(S_d_O_frame_start),
        .I_sample_tick(S_t_I_sample_tick),
        .I_start_valid(S_t_I_start_valid),
        .O_start_ready(S_t_O_start_ready),
        .I_epoch(S_t_I_epoch),
        .I_tag(S_t_I_tag),
        .I_effect(S_t_I_effect),
        .I_duration_frames(S_t_I_duration_frames),
        .I_av_offset_steps(S_t_I_av_offset_steps),
        .I_audio_action(S_t_I_audio_action),
        .I_audio_slot(S_t_I_audio_slot),
        .I_track_epoch(S_t_I_track_epoch),
        .I_track_serial(S_t_I_track_serial),
        .I_start_index(S_t_I_start_index),
        .I_resources_ready(S_t_I_resources_ready),
        .I_resources_epoch(S_t_I_resources_epoch),
        .I_resources_tag(S_t_I_resources_tag),
        .I_track_known(S_t_I_track_known),
        .I_track_enabled(S_t_I_track_enabled),
        .I_track_consumed(S_t_I_track_consumed),
        .I_track_epochs(S_t_I_track_epochs),
        .I_track_serials(S_t_I_track_serials),
        .I_track_totals(S_t_I_track_totals),
        .I_track_next_index(S_t_I_track_next_index),
        .I_pause(S_t_I_pause),
        .I_abort(S_t_I_abort),
        .O_pause_allow(S_t_O_pause_allow),
        .O_video_valid(S_t_O_video_valid),
        .I_video_ready(S_t_I_video_ready),
        .O_video_cancel(S_t_O_video_cancel),
        .O_video_epoch(S_t_O_video_epoch),
        .O_video_tag(S_t_O_video_tag),
        .O_video_effect(S_t_O_video_effect),
        .O_video_frame_index(S_t_O_video_frame_index),
        .O_video_progress(S_t_O_video_progress),
        .O_video_target_time(S_t_O_video_target_time),
        .I_video_done_valid(S_t_I_video_done_valid),
        .O_video_done_ready(S_t_O_video_done_ready),
        .I_video_done_epoch(S_t_I_video_done_epoch),
        .I_video_done_tag(S_t_I_video_done_tag),
        .I_video_done_frame_index(S_t_I_video_done_frame_index),
        .I_video_done_error(S_t_I_video_done_error),
        .I_video_done_applied(S_t_I_video_done_applied),
        .I_video_done_time(S_t_I_video_done_time),
        .O_play_valid(S_t_O_play_valid),
        .I_play_ready(S_t_I_play_ready),
        .O_fade_valid(S_t_O_fade_valid),
        .O_target_b(S_t_O_target_b),
        .O_audio_target_time(S_t_O_audio_target_time),
        .I_fade_ready(S_t_I_fade_ready),
        .I_fade_done(S_t_I_fade_done),
        .I_active_b(S_t_I_active_b),
        .O_audio_stop_request(S_t_O_audio_stop_request),
        .I_audio_stop_ack(S_t_I_audio_stop_ack),
        .O_busy(S_t_O_busy),
        .O_done_valid(S_t_O_done_valid),
        .I_done_ready(S_t_I_done_ready),
        .O_error(S_t_O_error),
        .O_epoch(S_t_O_epoch),
        .O_tag(S_t_O_tag),
        .O_cancel_late(S_t_O_cancel_late),
        .O_video_started(S_t_O_video_started),
        .O_video_finished(S_t_O_video_finished),
        .O_audio_started(S_t_O_audio_started),
        .O_audio_finished(S_t_O_audio_finished),
        .O_planned_start(S_t_O_planned_start),
        .O_planned_midpoint(S_t_O_planned_midpoint),
        .O_planned_audio(S_t_O_planned_audio),
        .O_actual_start(S_t_O_actual_start),
        .O_actual_midpoint(S_t_O_actual_midpoint),
        .O_actual_audio(S_t_O_actual_audio),
        .O_actual_finish(S_t_O_actual_finish),
        .O_audio_command_time(S_t_O_audio_command_time),
        .O_audio_start_index(S_t_O_audio_start_index),
        .O_anchor_error(S_t_O_anchor_error),
        .O_midpoint_seen(S_t_O_midpoint_seen),
        .O_late(S_t_O_late),
        .O_contract_fault(S_t_O_contract_fault),
        .O_quarantined(S_t_O_quarantined),
        .O_response_discarded(S_t_O_response_discarded),
        .O_silence_valid(S_silence_u_timeline_O_silence_valid),
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
        .I_event_valid(S_t_O_video_valid),
        .O_event_ready(S_t_I_video_ready),
        .I_event_epoch(S_t_O_video_epoch),
        .I_event_tag(S_t_O_video_tag),
        .I_event_index(S_t_O_video_frame_index),
        .I_event_effect(S_t_O_video_effect),
        .I_event_progress(S_t_O_video_progress),
        .I_event_target(S_t_O_video_target_time),
        .I_config(S_base_config),
        .I_cancel(S_t_O_video_cancel),
        .I_bank_busy(S_bank_busy),
        .O_busy(S_e_O_busy),
        .O_done_valid(S_t_I_video_done_valid),
        .I_done_ready(S_t_O_video_done_ready),
        .O_epoch(S_t_I_video_done_epoch),
        .O_tag(S_t_I_video_done_tag),
        .O_index(S_t_I_video_done_frame_index),
        .O_error(S_t_I_video_done_error),
        .O_backend_error(S_e_O_backend_error),
        .O_lease_error(S_e_O_lease_error),
        .O_slot_error(S_e_O_slot_error),
        .O_commit_error(S_e_O_commit_error),
        .O_prepare_error(S_e_O_prepare_error),
        .O_retire_error(S_e_O_retire_error),
        .O_applied(S_t_I_video_done_applied),
        .O_retired(S_e_O_retired),
        .O_apply_time(S_t_I_video_done_time),
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
    integer S_effect=0,S_event_results=0,S_event_applies=0,S_retired_events=0;
    integer S_pixel_checks=0;
    reg [31:0] S_last_commit=0,S_first_target=0;
    reg [15:0] S_expected_index=0;
    reg S_monitor_success=0;
    function [23:0] expected_pixel;
        input [2:0] effect;
        input [16:0] progress;
        input [15:0] x,y;
        reg choose_b;
        reg [7:0] rank;
        begin
            choose_b=0; rank=((x>>3)*37)^((y>>3)*73);
            if(progress==65536) choose_b=1;
            else if(progress!=0) case(effect)
                0:choose_b=0;
                1,2:choose_b=x>=320;
                3:choose_b=x*480+y*640<307200;
                4:choose_b=(x[5] ? 31-(x%32) : x%32)<16;
                5:choose_b=rank<128;
                6:choose_b=x>=160 && x<480 && y>=120 && y<360;
                default:choose_b=0;
            endcase
            expected_pixel=effect==0 && progress==32768 ? 24'h800080 : (choose_b ? 24'h0000ff : 24'hff0000);
        end
    endfunction
    always @(negedge S_video_clk) if(!S_video_reset && S_monitor_success && S_d_O_valid && S_d_O_de && S_d_O_pixel_epoch!=0) begin
        if(S_d_O_pixel_epoch!==S_d_O_video_active_epoch || S_d_O_repeated ||
            S_d_O_rgb!==expected_pixel(S_d_O_video_active_config[107:105],S_d_O_video_active_config[88:72],S_d_O_x,S_d_O_y))
            fail("independent red/blue pixel reference disagrees with actual animated scanout");
        S_pixel_checks=S_pixel_checks+1;
    end
    task begin_transition;
        input [31:0] epoch;
        input [2:0] effect;
        begin
            wait(S_t_O_start_ready);
            @(negedge S_video_clk);
            S_base_config=make_config(3,0,0,1,0,0,0);
            S_base_config[104:89]=16'd2;
            S_t_I_epoch=epoch; S_t_I_tag=16'h7000+epoch[15:0]; S_t_I_effect=effect;
            S_t_I_duration_frames=2; S_t_I_resources_ready=1;
            S_t_I_resources_epoch=epoch; S_t_I_resources_tag=S_t_I_tag;
            S_t_I_audio_action=0; S_t_I_abort=0; S_t_I_done_ready=0; S_t_I_start_valid=1;
            S_event_results=0; S_event_applies=0; S_retired_events=0; S_expected_index=0;
            @(posedge S_video_clk); while(!S_t_O_start_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_t_I_start_valid=0;
        end
    endtask
    task finish_transition;
        input [3:0] error;
        reg [150:0] held;
        begin
            wait(S_t_O_done_valid); #1;
            if(S_t_O_error!==error || (error==0 && (!S_t_O_video_finished || S_event_results!=3 ||
                S_event_applies!=3 || S_retired_events!=3 || !S_t_O_midpoint_seen)))
                fail("timeline terminal preceded actual frame applies and resource retirement");
            held={S_t_O_epoch,S_t_O_tag,S_t_O_error,S_t_O_actual_start,S_t_O_actual_midpoint,S_t_O_actual_finish,
                S_t_O_video_started,S_t_O_video_finished,S_t_O_cancel_late};
            repeat(12) begin @(negedge S_video_clk);
                if(!S_t_O_done_valid || held!=={S_t_O_epoch,S_t_O_tag,S_t_O_error,S_t_O_actual_start,
                    S_t_O_actual_midpoint,S_t_O_actual_finish,S_t_O_video_started,S_t_O_video_finished,S_t_O_cancel_late})
                    fail("actual timeline result mutated while backpressured"); end
            S_t_I_done_ready=1; @(negedge S_video_clk); S_t_I_done_ready=0; S_t_I_abort=0;
        end
    endtask
    always @(posedge S_video_clk) if(!S_video_reset) begin
        if(S_d_O_local_applied) begin
            if(S_d_O_video_active_epoch<=S_last_commit) fail("actual underlying commit epochs did not increase across timeline frames");
            S_last_commit=S_d_O_video_active_epoch; S_event_applies=S_event_applies+1;
        end
        if(S_t_I_video_done_valid && S_t_O_video_done_ready) begin
            if(S_t_I_video_done_epoch!==S_t_O_epoch || S_t_I_video_done_tag!==S_t_O_tag ||
                S_t_I_video_done_frame_index!==S_expected_index)
                fail("actual resource result lost transaction tag/index mapping");
            if(S_monitor_success) begin
                if(S_t_I_video_done_error!=0 || !S_t_I_video_done_applied || !S_e_O_retired ||
                    S_t_I_video_done_time!==S_target_actual || S_e_O_commit_epoch!==S_d_O_video_active_epoch ||
                    S_d_O_video_active_config[88:72]!==({1'b0,S_expected_index}*17'd32768) ||
                    S_d_O_video_active_config[107:105]!==S_t_I_effect || S_e_O_quarantined)
                    fail("timeline frame did not come from actual matching effect/progress/apply/retire");
                if(S_expected_index==0) S_first_target=S_t_I_video_done_time;
                else if(S_t_I_video_done_time!==S_first_target+S_expected_index*32'd420000)
                    fail("continuous animation slipped despite immediate logical memory and stable resources");
                S_retired_events=S_retired_events+1;
            end
            S_expected_index=S_expected_index+1'b1; S_event_results=S_event_results+1;
        end
    end
    initial begin
        S_case=1; reset_all; S_last_commit=0; S_monitor_success=1;
        for(S_effect=0;S_effect<7;S_effect=S_effect+1) begin
            begin_transition(S_effect+1,S_effect[2:0]); finish_transition(0);
            if(S_commands!=2 || S_publishes!=2 || S_d_O_owned!=3 ||
                S_m_O_slot_readers[2:0]!=1 || S_m_O_slot_readers[5:3]!=2)
                fail("real multi-effect animation reacquired/released/flushed unchanged source leases");
            if(S_t_O_actual_midpoint!==S_t_O_actual_start+420000 || S_t_O_actual_finish!==S_t_O_actual_start+840000)
                fail("actual transition anchors were inferred from command acceptance instead of display applies");
        end
        complete_frame;
        if(S_last_commit!=21 || S_applies!=21 || S_real_deadlines!=21 || S_deadline_fault ||
            S_d_O_und_count!=0 || S_pixel_checks<21*307200)
            fail("seven effects did not complete twenty-one real resource transactions");

        S_case=2; S_monitor_success=0; reset_all; S_last_commit=0; S_mem_enable=0;
        begin_transition(1,0); wait(S_d_O_mem_valid[0]);
        @(negedge S_video_clk); S_t_I_abort=1;
        repeat(50) begin @(negedge S_video_clk);
            if(S_t_O_done_valid || S_d_O_owned!=3 || S_applies!=0)
                fail("timeline cancellation bypassed actual candidate memory obligations"); end
        S_mem_enable=3; finish_transition(3);
        if(S_d_O_owned!=0 || S_commands!=4 || S_applies!=0 || S_e_O_quarantined)
            fail("cancelled actual animation failed to reclaim only newly acquired leases");

        S_case=3; reset_all; S_last_commit=0;
        begin_transition(1,2); wait(S_t_I_video_done_valid && S_t_O_video_done_ready);
        @(negedge S_video_clk); S_t_I_abort=1;
        finish_transition(3);
        if(!S_t_O_video_started || !S_t_O_cancel_late || S_t_O_actual_start==0 || S_d_O_owned!=3)
            fail("late timeline cancellation erased irrevocable display or active resource ownership");

        S_case=4; reset_all; S_last_commit=0; S_monitor_success=1;
        begin_transition(1,6); wait(S_d_O_pending_valid);
        @(negedge S_video_clk); S_host_run=0;
        repeat(200) begin @(negedge S_video_clk);
            if(S_t_O_done_valid || S_event_results!=0) fail("host stop fabricated actual animation terminal"); end
        S_host_run=1; finish_transition(0);

        $display("PASS: 4 actual timeline/executor/display-chain scenarios; 7 effects and 21 continuous progress commits");
        S_test_pass=1; $finish;
    end
endmodule
