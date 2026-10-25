`timescale 1ns/1ps
// Real host owner + lease/commit CDC + candidate/scanout/reader + slot manager/RAM.
// Only slot loading, logical memory, host deadlines and audio readiness are fixtures.
module tb_display_resource_pipeline;
    // Declare shared endpoint buses before their first instance connection.
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
    reg S_deadline_wrong=0,S_expect_fault=0,S_check_pixels=0;
    integer S_case=0,S_commands=0,S_publishes=0,S_applies=0,S_pixels=0,S_frames=0;
    integer S_mem_counts[0:1];
    integer S_i,S_v_i;
    reg [137:0] S_last_publish=0,S_previous_video_leases=0;
    reg [31:0] S_last_version=0,S_saved_epoch=0,S_frame_epoch=0;
    reg [3:0] S_seed_mask=0;
    reg [1:0] S_next_banks=0;
    reg [246:0] S_bad_config;
    reg S_d_I_start_valid=0;
    wire S_d_O_start_ready;
    reg [246:0] S_d_I_config=0;
    reg [15:0] S_d_I_tag=0;
    reg S_d_I_abort=0;
    wire S_d_O_busy;
    wire S_d_O_done_valid;
    reg S_d_I_done_ready=0;
    wire [3:0] S_d_O_error;
    wire [3:0] S_d_O_lease_error;
    wire [3:0] S_d_O_slot_error;
    wire [3:0] S_d_O_commit_error;
    wire [3:0] S_d_O_prepare_error;
    wire [3:0] S_d_O_retire_error;
    reg S_d_I_video_allow_apply=1;
    reg S_d_I_video_abort=0;
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
    reg S_d_I_prepare_deadline_valid=1;
    reg S_d_I_scan_deadline_valid=1;
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
    display_resource_pipeline u_resource (
        .O_bank_busy(),
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
        .I_prepare_deadline_valid(S_d_I_prepare_deadline_valid),
        .I_prepare_deadline_epoch(S_d_O_pending_epoch ^ {31'd0,S_deadline_wrong}),
        .I_prepare_deadlines(64'h7fffffff7fffffff),
        .I_scan_deadline_valid(S_d_I_scan_deadline_valid),
        .I_scan_deadline_y(S_d_O_prefetch_y),
        .I_scan_deadline_epoch(S_d_O_video_active_epoch),
        .I_scan_deadline(32'h7fffffff),
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
        .I_mem_data(64'h336699ff336699ff),
        .I_mem_tag(S_d_O_mem_tag),
        .I_mem_token(S_d_O_mem_token),
        .I_mem_generation(S_d_O_mem_generation),
        .I_mem_error(S_mem_error)
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
    initial begin #2000000000; fail("watchdog timeout"); end
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
            S_d_I_start_valid=0; S_d_I_done_ready=0; S_d_I_abort=0;
            S_d_I_video_allow_apply=1; S_d_I_video_abort=0; S_d_I_audio_ready=0; S_d_I_audio_epoch=0;
            S_d_I_prepare_deadline_valid=1; S_d_I_scan_deadline_valid=1; S_d_I_scan_stop=0;
            S_cmd_gate=1; S_media_valid=1; S_mem_enable=3; S_mem_error=0; S_deadline_wrong=0;
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
                occupied=u_resource.u_display_video_pipeline.S_r_O_bank_reserved |
                    u_resource.u_display_video_pipeline.S_s_O_owned_banks |
                    u_resource.u_display_video_pipeline.S_a_O_task_reserved;
            end
            S_next_banks={occupied[2],occupied[0]};
        end
    endtask
    task start;
        input [246:0] payload;
        input [15:0] tag;
        begin
            @(negedge S_host_clk); S_d_I_config=payload; S_d_I_tag=tag; S_d_I_start_valid=1;
            @(posedge S_host_clk); while(!S_d_O_start_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_d_I_start_valid=0; S_d_I_config=0; S_d_I_tag=0;
        end
    endtask
    task result;
        input [3:0] error;
        input [1:0] owned,acquired,released;
        input applied;
        reg [110:0] saved;
        begin
            wait(S_d_O_done_valid); #1;
            if(S_d_O_error!==error || S_d_O_owned!==owned || S_d_O_acquired_mask!==acquired ||
                S_d_O_released_mask!==released || S_d_O_applied!==applied || S_d_O_host_quarantined || S_d_O_video_quarantined)
                fail("terminal disagrees with real slot/lease/commit facts");
            if(S_d_O_host_reserve!=0 || S_d_O_source_busy!=0) fail("terminal preceded guard four phase clear");
            if(S_d_O_video_leases!=={S_d_O_lease_valid,S_d_O_lease_slots,S_d_O_lease_tokens,
                S_d_O_lease_generations,S_d_O_lease_resident}) fail("terminal preceded real lease snapshot installation");
            if(applied && (S_d_O_host_active_epoch!==S_d_O_video_active_epoch ||
                S_d_O_host_active_config!==S_d_O_video_active_config)) fail("host success preceded actual local install");
            saved={S_d_O_error,S_d_O_lease_error,S_d_O_slot_error,S_d_O_commit_error,S_d_O_prepare_error,S_d_O_retire_error,
                S_d_O_tag,S_d_O_epoch,S_d_O_previous_epoch,S_d_O_acquired_mask,S_d_O_released_mask,
                S_d_O_applied,S_d_O_retired,S_d_O_cancel_late};
            repeat(8) begin @(negedge S_host_clk);
                if(!S_d_O_done_valid || S_d_O_start_ready || saved!=={S_d_O_error,S_d_O_lease_error,S_d_O_slot_error,
                    S_d_O_commit_error,S_d_O_prepare_error,S_d_O_retire_error,S_d_O_tag,S_d_O_epoch,S_d_O_previous_epoch,
                    S_d_O_acquired_mask,S_d_O_released_mask,S_d_O_applied,S_d_O_retired,S_d_O_cancel_late})
                    fail("result payload not held under backpressure");
            end
            S_d_I_done_ready=1; @(negedge S_host_clk); S_d_I_done_ready=0;
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
        if(u_resource.S_o_O_publish_valid && u_resource.S_l_O_publish_ready) begin
            S_last_publish=u_resource.S_o_O_publish_leases; S_last_version=u_resource.S_o_O_publish_version;
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
    always @(posedge S_video_clk) if(!S_reset && u_resource.S_c_O_apply_valid) begin
        if(!S_d_O_frame_start || !u_resource.S_p_O_can_apply ||
            !u_resource.u_display_video_pipeline.u_scanout_engine.S_install ||
            !u_resource.u_display_video_pipeline.S_c_O_adopt_ready)
            fail("apply did not atomically install scanout and adopt all seeds");
        if(S_d_O_pending_config[52] && (!S_d_I_audio_ready || S_d_I_audio_epoch!==S_d_O_pending_epoch))
            fail("audio-required apply lacked matching audio epoch");
        S_seed_mask=0;
        if(S_d_O_pending_config[245]) S_seed_mask[S_d_O_pending_config[32]]=1;
        if(S_d_O_pending_config[246]) S_seed_mask[2+S_d_O_pending_config[33]]=1;
        S_saved_epoch=S_d_O_pending_epoch;
        #1;
        if(S_d_O_video_active_epoch!==S_saved_epoch || u_resource.S_c_O_active_epoch!==S_saved_epoch ||
            !S_d_O_local_applied || !u_resource.u_display_video_pipeline.S_c_O_adopted ||
            (u_resource.u_display_video_pipeline.S_s_O_owned_banks & S_seed_mask)!==S_seed_mask ||
            u_resource.u_display_video_pipeline.S_c_O_owned_banks!=0)
            fail("partial seed ownership or delayed local epoch installation");
        S_applies=S_applies+1;
    end
    always @(negedge S_video_clk) if(!S_reset) begin
        if(!S_expect_fault && (S_d_O_video_quarantined || S_d_O_pixel_fault)) fail("unexpected video/pixel isolation");
        if(S_d_O_frame_start) S_frames=S_frames+1;
        if(S_check_pixels && S_d_O_valid && S_d_O_de) begin
            if(S_d_O_rgb!==24'h336699 || S_d_O_pixel_epoch!==S_frame_epoch || S_d_O_repeated)
                fail("real leased pixel/epoch continuity");
            S_pixels=S_pixels+1;
        end
        if((S_d_O_reader_stop & S_d_O_source_in_use)!=0) fail("reader stopped a source still in real use");
        if(u_resource.S_l_O_video_installed) begin
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
    initial begin
        S_case=1; reset_all;
        start(make_config(1,0,0,1,0,0,0),16'h1001); result(0,1,1,0,1); complete_frame;
        if(S_commands!=1 || S_publishes!=1 || S_applies!=1 || S_d_O_und_count!=0 || !S_m_O_slot_readers[0])
            fail("first full leased frame did not use actual slot lock and installation");

        S_case=2; choose_free_banks(3);
        start(make_config(3,0,0,1,32768,S_next_banks,0),16'h1002); result(0,3,2,0,1);
        if(S_commands!=2 || S_publishes!=2 || S_d_O_previous_epoch!=1) fail("shared foreground lease reacquired");
        choose_free_banks(2);
        start(make_config(2,1,0,1,0,S_next_banks,0),16'h1003); result(0,2,0,1,1); complete_frame;
        if(S_commands!=3 || S_publishes!=3 || S_m_O_slot_readers[0] || !S_m_O_slot_readers[4])
            fail("removed source not physically released after real old epoch retirement");
        choose_free_banks(3);
        start(make_config(3,1,2,1,32768,S_next_banks,0),16'h1004); result(0,3,1,0,1);
        if(S_d_O_lease_slots[2:0]!=2 || S_commands!=4 || S_publishes!=4 || S_mem_counts[0]==0)
            fail("freed physical source could not acquire third image identity");

        S_case=3; start(make_config(3,1,3,1,32768,0,0),16'h2001); result(2,3,0,0,0);
        if(S_commands!=4 || S_publishes!=4 || S_d_O_video_active_epoch!=4) fail("conflicting target damaged active leases");

        S_case=4; reset_all; start(make_config(1,0,0,1,0,0,0),16'h3001); result(0,1,1,0,1);
        S_mem_enable=1; choose_free_banks(3);
        start(make_config(3,0,0,1,32768,S_next_banks,0),16'h3002); wait(S_d_O_mem_valid[1]);
        @(negedge S_host_clk); S_d_I_abort=1;
        repeat(30) begin @(negedge S_video_clk);
            if(S_d_O_done_valid || S_d_O_owned!=3 || S_d_O_reader_stop!=0) fail("cancel fabricated candidate task retirement");
        end
        @(negedge S_host_clk); S_host_run=0;
        repeat(12) begin @(negedge S_video_clk); if(S_d_O_done_valid || S_d_O_owned!=3)
            fail("host stop released in-flight candidate lock"); end
        S_host_run=1; S_mem_enable=3; result(3,1,2,2,0); S_d_I_abort=0;
        if(S_d_O_host_active_epoch!=1 || S_publishes!=3 || S_m_O_slot_readers[4])
            fail("cancel cleanup damaged old foreground or leaked new source");

        S_case=5; reset_all; start(make_config(1,0,0,1,0,0,0),16'h4001); result(0,1,1,0,1);
        S_mem_error=8'h90; choose_free_banks(3);
        start(make_config(3,0,0,1,32768,S_next_banks,0),16'h4002); result(5,1,2,2,0);
        if(S_d_O_commit_error!=2 || S_d_O_prepare_error!=2 || S_d_O_host_active_epoch!=1)
            fail("real reader candidate error lost original cause or old foreground");

        S_case=6; reset_all; start(make_config(1,0,0,1,0,0,0),16'h5001); result(0,1,1,0,1);
        choose_free_banks(3); S_bad_config=make_config(3,0,0,1,32768,S_next_banks,0); S_bad_config[43+:9]=1;
        start(S_bad_config,16'h5002); result(5,1,2,2,0);
        if(S_d_O_prepare_error!=1 || S_mem_counts[1]!=0 || S_d_O_host_active_epoch!=1)
            fail("first-row query mismatch acquired bank or changed foreground");

        S_case=7; reset_all; S_d_I_prepare_deadline_valid=0;
        start(make_config(1,0,0,1,0,0,0),16'h6001); wait(u_resource.S_c_O_prepare_valid);
        repeat(18) begin @(negedge S_video_clk);
            if(u_resource.S_p_O_prepare_ready || S_d_O_mem_valid!=0 || S_d_O_done_valid)
                fail("missing host deadline started actual candidate"); end
        S_d_I_prepare_deadline_valid=1; S_deadline_wrong=1;
        repeat(18) begin @(negedge S_video_clk); if(u_resource.S_p_O_prepare_ready || S_d_O_mem_valid!=0)
            fail("wrong epoch host deadline started actual candidate"); end
        @(negedge S_host_clk); S_d_I_abort=1; result(3,0,1,1,0); S_d_I_abort=0;

        S_case=8; reset_all; S_d_I_audio_ready=1; S_d_I_audio_epoch=32'hffffffff;
        start(make_config(1,0,0,1,0,0,1),16'h7001); wait(u_resource.u_display_video_pipeline.S_state==7);
        S_saved_epoch=S_frames;
        while(S_frames<S_saved_epoch+2) begin @(negedge S_video_clk);
            if(S_d_O_done_valid || S_applies!=0 || !S_d_O_owned[0]) fail("wrong audio epoch bypassed real frame gate"); end
        S_d_I_audio_ready=0; S_d_I_audio_epoch=S_d_O_pending_epoch;
        repeat(18) begin @(negedge S_video_clk); if(u_resource.S_allow_apply) fail("audio epoch alone permitted apply"); end
        S_d_I_audio_ready=1; result(0,1,1,0,1);

        S_case=9; reset_all; S_d_I_video_allow_apply=0;
        start(make_config(1,0,0,1,0,0,0),16'h8001); wait(u_resource.u_display_video_pipeline.S_state==7);
        @(negedge S_video_clk); S_video_run=0; S_d_I_video_allow_apply=1;
        repeat(24) begin @(negedge S_host_clk); if(S_d_O_done_valid || S_applies!=0 || S_d_O_owned!=1)
            fail("video stop fabricated atomic configuration installation"); end
        S_video_run=1; result(0,1,1,0,1);

        S_case=10; reset_all; start(make_config(1,0,0,1,0,0,0),16'h9001); result(0,1,1,0,1);
        // Stall an actual old scanout request; the new source still has its independent memory path.
        @(negedge S_host_clk); S_mem_enable=2; wait(S_d_O_mem_valid[0]);
        start(make_config(2,1,0,1,0,0,0),16'h9002); wait(S_d_O_video_active_config[246:245]==2);
        repeat(80) begin @(negedge S_host_clk);
            if(S_d_O_done_valid || S_d_O_owned!=3 || S_d_O_reader_stop[0] || !S_m_O_slot_readers[0])
                fail("old reader/scanout obligation released physical lock before real retirement"); end
        @(negedge S_host_clk); S_host_run=0;
        repeat(12) begin @(negedge S_video_clk); if(S_d_O_owned!=3) fail("stopped host invented old epoch retirement"); end
        S_host_run=1; S_mem_enable=3; result(0,2,2,1,1);

        S_case=11; reset_all; S_media_valid=0;
        start(make_config(1,0,0,1,0,0,0),16'ha001); result(4,0,0,0,0);
        if(S_d_O_slot_error!=2 || S_publishes!=0 || S_applies!=0) fail("invalidated slot acquired or published");
        start(make_config(1,0,5,1,0,0,0),16'ha002); result(0,1,1,0,1);
        if(!S_d_O_lease_resident[0] || S_d_O_lease_generations[31:0]!=77) fail("resident safety source lost identity");

        S_case=12; reset_all; S_cmd_gate=0;
        start(make_config(1,0,0,1,0,0,0),16'hb001); wait(S_d_O_slot_cmd_valid);
        @(negedge S_host_clk); S_d_I_abort=1;
        repeat(16) begin @(negedge S_host_clk); if(!S_d_O_slot_cmd_valid || S_d_O_done_valid)
            fail("late cancel withdrew presented real slot command"); end
        S_cmd_gate=1; result(3,0,1,1,0); S_d_I_abort=0;
        if(!S_d_O_cancel_late || S_publishes!=2 || S_applies!=0) fail("late acquired cancelled lock not published then released");

        S_case=14; reset_all;
        start(make_config(1,0,0,1,0,0,0),16'hb101); wait(u_resource.S_o_O_commit_valid);
        @(negedge S_host_clk);
        // Corrupt only the current host proof, after publication and before submit acceptance.
        force u_resource.O_lease_resident=2'b01;
        wait(u_resource.S_c_O_done_valid); @(negedge S_host_clk); release u_resource.O_lease_resident;
        result(5,0,1,1,0);
        if(S_d_O_commit_error!=4 || S_d_O_epoch!=0 || S_applies!=0 || S_mem_counts[0]!=0 || S_publishes!=2)
            fail("submit failed to revalidate current resident lease or fabricated remote start");

        S_case=15; reset_all; S_expect_fault=1;
        @(negedge S_video_clk); force u_resource.u_display_video_pipeline.O_contract_fault=1'b1;
        wait(S_d_O_host_quarantined); @(negedge S_host_clk);
        release u_resource.u_display_video_pipeline.O_contract_fault;
        S_d_I_config=make_config(1,0,0,1,0,0,0); S_d_I_tag=16'hb201; S_d_I_start_valid=1;
        repeat(16) begin @(negedge S_host_clk);
            if(S_d_O_start_ready || S_d_O_done_valid || !S_d_O_busy || S_commands!=0 || S_publishes!=0 ||
                S_d_O_owned!=0 || !u_resource.S_o_O_start_ready)
                fail("idle video resource fault did not block wrapper admission independently of owner");
        end
        S_d_I_start_valid=0;

        S_case=13; reset_all; S_expect_fault=1; S_mem_enable=0;
        start(make_config(1,0,0,1,0,0,0),16'hc001); wait(S_d_O_mem_valid[0]);
        @(negedge S_video_clk); force u_resource.u_display_video_pipeline.O_contract_fault=1'b1;
        repeat(3) @(negedge S_video_clk); release u_resource.u_display_video_pipeline.O_contract_fault;
        wait(S_d_O_host_quarantined);
        if(S_d_O_start_ready || !S_d_O_video_quarantined || S_d_O_done_valid || S_d_O_owned!=1)
            fail("video fault crossing admitted new work or fabricated terminal");
        S_mem_enable=3; wait(S_d_O_done_valid); #1;
        if(S_d_O_error!=8 || !S_d_O_host_quarantined || S_d_O_owned!=1 || S_d_O_released_mask!=0 || S_applies!=0)
            fail("resource fault guessed safe cleanup from a real commit result");
        reset_all; start(make_config(1,0,0,1,0,0,0),16'hc002); result(0,1,1,0,1);
        $display("PASS: actual host/video resource chain, slot locks, publication, scanout and retirement");
        S_test_pass=1; $finish;
    end
endmodule
