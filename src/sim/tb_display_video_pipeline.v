`timescale 1ns/1ps
// Actual CDC + planner/map + candidate + arbiter + scanout + reader/RAM.
// Leases, video authority and host absolute deadlines are explicit fixtures.
// Memory is a zero-latency tagged logical endpoint, not physical SDRAM.
module tb_display_video_pipeline;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    reg [1:0] S_mem_enable=3;
    reg [7:0] S_mem_error=0;
    reg S_allow_apply=1,S_expect_quarantine=0,S_check_pixels=0;
    integer S_case=0,S_applies=0,S_pixels=0,S_frames=0;
    integer S_effect;
    reg [31:0] S_saved_epoch;
    reg [246:0] S_saved_config;
    reg [3:0] S_seed_mask;
    reg [1:0] S_next_banks;
    reg [246:0] S_bad_config;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    wire  S_p_O_prepare_ready;
    reg  S_p_I_prepare_deadline_valid=0;
    wire  S_p_O_prepare_done_valid;
    wire [3:0] S_p_O_prepare_error;
    wire [31:0] S_p_O_prepare_epoch;
    wire [15:0] S_p_O_prepare_tag;
    wire  S_p_O_can_apply;
    wire  S_p_O_retire_ready;
    wire  S_p_O_retire_done_valid;
    wire [3:0] S_p_O_retire_error;
    wire [31:0] S_p_O_retire_epoch;
    wire [15:0] S_p_O_retire_tag;
    reg [1:0] S_p_I_authorized=0;
    reg [1:0] S_p_I_source_block=0;
    reg  S_p_I_scan_deadline_valid=0;
    reg  S_p_I_scan_stop=0;
    wire  S_p_O_scan_stop_ack;
    wire [1:0] S_p_O_reader_retire_ack;
    wire [1:0] S_p_O_reader_host_retired;
    wire [1:0] S_p_O_source_in_use;
    wire [1:0] S_p_O_source_owner_retired;
    wire [1:0] S_p_O_source_pipeline_retired;
    wire [8:0] S_p_O_prefetch_y;
    wire [31:0] S_p_O_active_epoch;
    wire  S_p_O_frame_start;
    wire  S_p_O_local_applied;
    wire  S_p_O_busy;
    wire  S_p_O_contract_fault;
    wire  S_p_O_quarantined;
    wire  S_p_O_valid;
    wire  S_p_O_hsync;
    wire  S_p_O_vsync;
    wire  S_p_O_de;
    wire [15:0] S_p_O_x;
    wire [15:0] S_p_O_y;
    wire [23:0] S_p_O_rgb;
    wire [31:0] S_p_O_epoch;
    wire [15:0] S_p_O_tag;
    wire  S_p_O_repeated;
    wire  S_p_O_pixel_fault;
    wire  S_p_O_video_und;
    wire [31:0] S_p_O_und_count;
    wire [31:0] S_p_O_line_error_count;
    wire [1:0] S_p_O_mem_valid;
    wire [41:0] S_p_O_mem_addr;
    wire [63:0] S_p_O_mem_tag;
    wire [63:0] S_p_O_mem_token;
    wire [63:0] S_p_O_mem_generation;
    wire [63:0] S_p_O_mem_deadline;
    wire [1:0] S_p_O_mem_ready;
    display_video_pipeline u_pipeline (
        .O_bank_busy(),
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_prepare_valid(S_c_O_prepare_valid),
        .O_prepare_ready(S_p_O_prepare_ready),
        .I_pending_config(S_c_O_pending_config),
        .I_pending_epoch(S_c_O_pending_epoch),
        .I_pending_tag(S_c_O_pending_tag),
        .I_prepare_abort(S_c_O_prepare_abort),
        .I_prepare_deadline_valid(S_p_I_prepare_deadline_valid),
        .I_prepare_deadline_epoch(S_c_O_pending_epoch),
        .I_prepare_deadlines(64'h7fffffff7fffffff),
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
        .I_authorized(S_p_I_authorized),
        .I_source_block(S_p_I_source_block),
        .I_lease_valid(2'b11),
        .I_lease_slots({3'd1,3'd0}),
        .I_lease_tokens({32'd22,32'd11}),
        .I_lease_generations({32'd202,32'd101}),
        .I_scan_deadline_valid(S_p_I_scan_deadline_valid),
        .I_scan_deadline_y(S_p_O_prefetch_y),
        .I_scan_deadline_epoch(S_p_O_active_epoch),
        .I_scan_deadline(32'h7fffffff),
        .I_scan_stop(S_p_I_scan_stop),
        .O_scan_stop_ack(S_p_O_scan_stop_ack),
        .I_reader_retire_request(2'b00),
        .O_reader_retire_ack(S_p_O_reader_retire_ack),
        .O_reader_host_retired(S_p_O_reader_host_retired),
        .O_source_in_use(S_p_O_source_in_use),
        .O_source_owner_retired(S_p_O_source_owner_retired),
        .O_source_pipeline_retired(S_p_O_source_pipeline_retired),
        .O_prefetch_y(S_p_O_prefetch_y),
        .O_active_epoch(S_p_O_active_epoch),
        .O_frame_start(S_p_O_frame_start),
        .O_local_applied(S_p_O_local_applied),
        .O_busy(S_p_O_busy),
        .O_contract_fault(S_p_O_contract_fault),
        .O_quarantined(S_p_O_quarantined),
        .O_valid(S_p_O_valid),
        .O_hsync(S_p_O_hsync),
        .O_vsync(S_p_O_vsync),
        .O_de(S_p_O_de),
        .O_x(S_p_O_x),
        .O_y(S_p_O_y),
        .O_rgb(S_p_O_rgb),
        .O_epoch(S_p_O_epoch),
        .O_tag(S_p_O_tag),
        .O_repeated(S_p_O_repeated),
        .O_pixel_fault(S_p_O_pixel_fault),
        .O_video_und(S_p_O_video_und),
        .O_und_count(S_p_O_und_count),
        .O_line_error_count(S_p_O_line_error_count),
        .O_mem_valid(S_p_O_mem_valid),
        .I_mem_ready(S_mem_enable),
        .O_mem_addr(S_p_O_mem_addr),
        .O_mem_tag(S_p_O_mem_tag),
        .O_mem_token(S_p_O_mem_token),
        .O_mem_generation(S_p_O_mem_generation),
        .O_mem_deadline(S_p_O_mem_deadline),
        .I_mem_valid(S_p_O_mem_valid & S_mem_enable),
        .O_mem_ready(S_p_O_mem_ready),
        .I_mem_data(64'h336699ff336699ff),
        .I_mem_tag(S_p_O_mem_tag),
        .I_mem_token(S_p_O_mem_token),
        .I_mem_generation(S_p_O_mem_generation),
        .I_mem_error(S_mem_error)
    );
    reg  S_c_I_submit_valid=0;
    wire  S_c_O_submit_ready;
    reg [246:0] S_c_I_config=0;
    reg [15:0] S_c_I_tag=0;
    reg  S_c_I_abort=0;
    wire [31:0] S_c_O_next_epoch;
    wire  S_c_O_busy;
    wire  S_c_O_done_valid;
    reg  S_c_I_done_ready=0;
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
    frame_commit_cdc u_commit (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_submit_valid(S_c_I_submit_valid),
        .O_submit_ready(S_c_O_submit_ready),
        .I_config(S_c_I_config),
        .I_tag(S_c_I_tag),
        .I_validate_error(4'd0),
        .I_abort(S_c_I_abort),
        .O_next_epoch(S_c_O_next_epoch),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(S_c_I_done_ready),
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
        .I_prepare_ready(S_p_O_prepare_ready),
        .O_prepare_abort(S_c_O_prepare_abort),
        .I_prepare_done_valid(S_p_O_prepare_done_valid),
        .O_prepare_done_ready(S_c_O_prepare_done_ready),
        .I_prepare_done_tag(S_p_O_prepare_tag),
        .I_prepare_done_epoch(S_p_O_prepare_epoch),
        .I_prepare_done_error(S_p_O_prepare_error),
        .I_frame_start(S_p_O_frame_start),
        .I_allow_apply(S_p_O_can_apply && S_allow_apply),
        .I_video_abort(S_p_O_quarantined),
        .O_active_valid(S_c_O_active_valid),
        .O_active_config(S_c_O_active_config),
        .O_active_tag(S_c_O_active_tag),
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
        .O_video_response_discarded(S_c_O_video_response_discarded)
    );

    task fail;
        input [767:0] message;
        begin $display("FAIL: video pipeline case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #500000000; fail("watchdog timeout"); end
    function [246:0] make_config;
        input [2:0] effect;
        input [16:0] progress;
        input [1:0] banks;
        begin make_config={2'b11,1'b0,{3'd1,3'd0},{32'd22,32'd11},{32'd202,32'd101},
            2'b00,effect,16'd60,progress,4'd0,4'd0,5'd8,3'd0,2'd0,1'b0,1'b0,
            18'd0,banks,{16'hc202,16'hc101}}; end
    endfunction
    task reset_all;
        begin
            S_host_run=1; S_video_run=1; S_reset=1;
            S_c_I_submit_valid=0; S_c_I_done_ready=0; S_c_I_abort=0;
            S_c_I_config=0; S_c_I_tag=0;
            S_mem_enable=3; S_mem_error=0; S_allow_apply=1;
            S_p_I_prepare_deadline_valid=1; S_p_I_authorized=3; S_p_I_source_block=0;
            S_p_I_scan_deadline_valid=1; S_p_I_scan_stop=0;
            S_expect_quarantine=0; S_check_pixels=0;
            repeat(6) @(negedge S_video_clk); S_reset=0;
            wait(S_c_O_submit_ready); @(negedge S_video_clk);
            S_applies=0; S_pixels=0; S_frames=0;
        end
    endtask
    task submit;
        input [246:0] payload;
        input [15:0] tag;
        begin
            @(negedge S_host_clk); S_c_I_config=payload; S_c_I_tag=tag; S_c_I_submit_valid=1;
            @(posedge S_host_clk); while(!S_c_O_submit_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_c_I_submit_valid=0;
        end
    endtask
    task choose_free_banks;
        reg [3:0] occupied;
        begin
            occupied=15;
            while(occupied[1:0]==3 || occupied[3:2]==3) begin
                @(negedge S_video_clk);
                occupied=u_pipeline.S_r_O_bank_reserved | u_pipeline.S_s_O_owned_banks |
                    u_pipeline.S_a_O_task_reserved;
            end
            S_next_banks={occupied[2],occupied[0]};
        end
    endtask
    task result;
        input [3:0] error;
        input applied;
        begin
            wait(S_c_O_done_valid); #1;
            if(S_c_O_error!==error || S_c_O_applied!==applied || !S_c_O_retired ||
                S_c_O_quarantined || S_p_O_contract_fault) fail("host result disagrees with actual pipeline");
            if(applied && (S_c_O_active_epoch!==S_p_O_active_epoch ||
                u_pipeline.S_active_config!==S_c_O_active_config)) fail("host success before local install");
            S_saved_config=S_c_O_active_config;
            repeat(8) begin @(negedge S_host_clk);
                if(!S_c_O_done_valid || S_c_O_active_config!==S_saved_config) fail("host result not held");
            end
            S_c_I_done_ready=1; @(negedge S_host_clk); S_c_I_done_ready=0;
            wait(S_c_O_submit_ready);
        end
    endtask
    // Sample before and after NBA: all three ownership changes must be atomic.
    always @(posedge S_video_clk) if(!S_reset && S_c_O_apply_valid) begin
        if(!S_p_O_frame_start || !S_p_O_can_apply || !u_pipeline.S_apply_fire ||
            !u_pipeline.u_scanout_engine.S_install || !u_pipeline.S_c_O_adopt_ready)
            fail("apply missing matching install and atomic adopt");
        S_seed_mask=0;
        S_seed_mask[u_pipeline.S_cfg_first_bank[0]]=1;
        S_seed_mask[2+u_pipeline.S_cfg_first_bank[1]]=1;
        S_saved_epoch=S_c_O_pending_epoch;
        #1;
        if(S_p_O_active_epoch!==S_saved_epoch || S_c_O_active_epoch!==S_saved_epoch ||
            !S_p_O_local_applied || !u_pipeline.S_c_O_adopted || u_pipeline.S_c_O_owned_banks!=0 ||
            (u_pipeline.S_s_O_owned_banks & S_seed_mask)!==S_seed_mask)
            fail("partial seed takeover or delayed local configuration");
        S_applies=S_applies+1;
    end
    always @(negedge S_video_clk) if(!S_reset) begin
        if(!S_expect_quarantine && (S_p_O_contract_fault || S_p_O_quarantined || S_p_O_pixel_fault))
            fail("unexpected resource or pixel contract fault");
        if(S_check_pixels && S_p_O_valid && S_p_O_de) begin
            if(S_p_O_rgb!==24'h336699 || S_p_O_epoch!==S_p_O_active_epoch || S_p_O_repeated)
                fail("real scanout pixel, epoch or row continuity");
            S_pixels=S_pixels+1;
        end
        if(S_check_pixels && S_p_O_frame_start) S_frames=S_frames+1;
        if(S_c_O_retire_valid && S_c_O_retire_old && S_p_O_retire_ready &&
            (S_c_O_retire_config!==u_pipeline.S_previous_config ||
             S_c_O_retire_epoch!==u_pipeline.S_previous_epoch)) fail("wrong old configuration routed");
    end
    initial begin
        // A complete frame for each effect, with actual line prefetch and RAM pixels.
        for(S_effect=0;S_effect<7;S_effect=S_effect+1) begin
            S_case=S_effect; reset_all;
            submit(make_config(S_effect,17'd32768,2'b00),16'h1000+S_effect);
            result(0,1); S_check_pixels=1;
            wait(S_frames==1); @(negedge S_video_clk); S_check_pixels=0;
            if(S_applies!=1 || S_pixels!=307200 || S_p_O_und_count!=0) fail("complete frame coverage");
        end

        // Enabled but visually unused source must also transfer its bank, at both endpoints.
        S_case=7; reset_all;
        submit(make_config(0,0,0),16'h2000); result(0,1);
        wait(S_p_O_valid && S_p_O_de); @(negedge S_video_clk);
        S_p_I_scan_deadline_valid=0;
        // Preserve the same leases and source identities across the next epoch.
        choose_free_banks;
        submit(make_config(0,65536,S_next_banks),16'h2001); result(0,1);
        if(S_applies!=2 || u_pipeline.S_previous_valid || u_pipeline.S_pending_valid)
            fail("continuous commit or real old epoch retirement");
        if(S_c_O_previous_epoch!=1 || S_c_O_active_epoch!=2) fail("continuous commit epoch identity");

        // Cancel a real in-flight request while memory is stalled; no fabricated completion.
        S_case=8; reset_all; S_mem_enable=0;
        submit(make_config(0,32768,0),16'h3000);
        wait(S_p_O_mem_valid!=0); @(negedge S_host_clk); S_c_I_abort=1;
        repeat(32) begin @(negedge S_video_clk);
            if(S_c_O_done_valid || S_p_O_prepare_done_valid || S_applies!=0)
                fail("cancel fabricated pending memory retirement");
        end
        @(negedge S_host_clk); S_host_run=0;
        repeat(8) begin @(negedge S_video_clk); if(S_p_O_prepare_done_valid)
            fail("host stop fabricated line completion"); end
        S_host_run=1; S_mem_enable=3;
        result(3,0); S_c_I_abort=0;
        if(u_pipeline.S_r_O_bank_reserved!=0 || u_pipeline.S_a_O_task_reserved!=0 || S_applies!=0)
            fail("cancel leaked candidate bank or task");

        // Successful pending remains separate from old foreground; late abort rolls back only pending.
        S_case=9; reset_all; submit(make_config(0,0,0),16'h4000); result(0,1);
        S_allow_apply=0; S_p_I_scan_deadline_valid=0;
        submit(make_config(0,65536,3),16'h4001);
        wait(u_pipeline.S_state==7); @(negedge S_host_clk); S_c_I_abort=1;
        result(3,0); S_c_I_abort=0;
        if(S_p_O_active_epoch!=1 || S_c_O_active_epoch!=1 || S_applies!=1)
            fail("cancel damaged old foreground configuration");

        // Video pause cannot transfer ownership or acknowledge the host; recovery continues.
        S_case=10; reset_all; S_allow_apply=0;
        submit(make_config(0,0,0),16'h5000); wait(u_pipeline.S_state==7);
        @(negedge S_video_clk); S_video_run=0; S_allow_apply=1;
        repeat(20) begin @(negedge S_host_clk); if(S_c_O_done_valid || S_applies!=0)
            fail("video stop fabricated apply"); end
        S_video_run=1; result(0,1);

        // Real reader memory error cleans a successful sibling without applying.
        S_case=11; reset_all; S_mem_error=8'h90;
        submit(make_config(0,32768,0),16'h6000); result(2,0);
        if(u_pipeline.S_r_O_bank_reserved!=0 || S_applies!=0) fail("failed candidate leaked successful sibling");

        // A same-cycle offer reserves its bank before scanout creates a new request.
        S_case=12; reset_all; submit(make_config(0,0,0),16'h7000); result(0,1);
        S_allow_apply=0; S_p_I_prepare_deadline_valid=0;
        submit(make_config(0,65536,3),16'h7001);
        wait(S_c_O_prepare_valid);
        // At the first visible line's start the real scanner advances want_y to 1.
        // Permit prepare before the following edge would create that row's task.
        wait(S_p_O_prefetch_y==1); @(negedge S_video_clk);
        S_p_I_prepare_deadline_valid=1; #1;
        if(!u_pipeline.S_prepare_fire || !u_pipeline.u_scanout_engine.C_need[0] ||
            u_pipeline.u_scanout_engine.C_exists[0] || u_pipeline.S_s_O_task_valid ||
            u_pipeline.S_r_O_bank_reserved[1] || u_pipeline.S_s_O_owned_banks[1])
            fail("bank race fixture missed eligible scanout row request");
        if((u_pipeline.S_offer_banks & u_pipeline.C_input_banks)!==u_pipeline.C_input_banks)
            fail("candidate offer missing bank reservation");
        if(u_pipeline.u_scanout_engine.C_new_task &&
            u_pipeline.S_offer_banks[{u_pipeline.u_scanout_engine.C_task_source,u_pipeline.u_scanout_engine.C_task_bank}])
            fail("same cycle prepare scanout bank collision");
        wait(u_pipeline.S_state==7); S_allow_apply=1; result(0,1);

        // Corrupt retire identity before presentation; do not clear unknown obligations.
        S_case=13; reset_all; S_mem_enable=0;
        submit(make_config(0,32768,0),16'h8000); wait(S_p_O_mem_valid!=0);
        @(negedge S_host_clk); S_c_I_abort=1; S_mem_enable=3;
        wait(S_p_O_prepare_done_valid); @(negedge S_video_clk);
        S_expect_quarantine=1;
        force u_pipeline.I_retire_tag=16'hdead;
        wait(S_p_O_retire_done_valid); @(negedge S_video_clk);
        release u_pipeline.I_retire_tag;
        if(!S_p_O_contract_fault || !S_p_O_quarantined || S_p_O_prepare_ready || S_p_O_can_apply)
            fail("wrong retire identity did not quarantine unknown resource state");
        if(u_pipeline.S_r_O_bank_reserved==0 || !u_pipeline.S_pending_valid)
            fail("wrong identity cleared uncertain candidate obligation");
        reset_all;
        S_case=14; S_expect_quarantine=1;
        force u_pipeline.I_apply_valid=1'b1;
        @(negedge S_video_clk); release u_pipeline.I_apply_valid;
        if(!S_p_O_contract_fault || !S_p_O_quarantined || S_p_O_can_apply)
            fail("illegal apply did not quarantine unknown resource state");
        reset_all;
        // A missing absolute deadline must leave the candidate unstarted.
        S_case=15; S_p_I_prepare_deadline_valid=0;
        submit(make_config(0,0,0),16'h8800); wait(S_c_O_prepare_valid);
        repeat(16) begin @(negedge S_video_clk);
            if(S_p_O_prepare_ready || u_pipeline.S_pending_valid || S_p_O_mem_valid!=0)
                fail("prepare accepted without host deadline authorization");
        end
        @(negedge S_host_clk); S_c_I_abort=1; result(3,0); S_c_I_abort=0;
        if(u_pipeline.S_r_O_bank_reserved!=0) fail("unstarted prepare invented resource obligation");
        reset_all;
        // Wrong first row fails query before candidate task creation.
        S_case=16; S_bad_config=make_config(0,0,0); S_bad_config[42:34]=9'd1;
        submit(S_bad_config,16'h8900); result(2,0);
        if(S_c_O_prepare_error!=1 || u_pipeline.S_r_O_bank_reserved!=0 || S_applies!=0)
            fail("first row query mismatch acquired a candidate bank");
        reset_all;
        submit(make_config(0,0,0),16'h9000); result(0,1);
        $display("PASS: actual CDC/video pipeline atomic install, ownership, pixels and retirement");
        S_test_pass=1; $finish;
    end
endmodule
