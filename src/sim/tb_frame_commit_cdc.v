`timescale 1ns/1ps
module tb_frame_commit_cdc;
    reg S_I_host_clk=0;
    reg S_I_video_clk=0;
    reg S_I_async_reset=0;
    reg S_I_submit_valid=0;
    wire S_O_submit_ready;
    reg [31:0] S_I_config=0;
    reg [15:0] S_I_tag=0;
    reg [3:0] S_I_validate_error=0;
    reg S_I_abort=0;
    wire [31:0] S_O_next_epoch;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [3:0] S_O_prepare_error;
    wire [3:0] S_O_retire_error;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_epoch;
    wire [31:0] S_O_previous_epoch;
    wire S_O_applied;
    wire S_O_retired;
    wire S_O_quarantined;
    wire S_O_host_response_discarded;
    wire S_O_pending_valid;
    wire [31:0] S_O_pending_config;
    wire [15:0] S_O_pending_tag;
    wire [31:0] S_O_pending_epoch;
    wire S_O_prepare_valid;
    reg S_I_prepare_ready=0;
    wire S_O_prepare_abort;
    reg S_I_prepare_done_valid=0;
    wire S_O_prepare_done_ready;
    reg [15:0] S_I_prepare_done_tag=0;
    reg [31:0] S_I_prepare_done_epoch=0;
    reg [3:0] S_I_prepare_done_error=0;
    reg S_I_frame_start=0;
    reg S_I_allow_apply=0;
    reg S_I_video_abort=0;
    wire S_O_active_valid;
    wire [31:0] S_O_active_config;
    wire [15:0] S_O_active_tag;
    wire [31:0] S_O_active_epoch;
    wire S_O_applied_pulse;
    wire S_O_retire_valid;
    reg S_I_retire_ready=0;
    wire [31:0] S_O_retire_config;
    wire [15:0] S_O_retire_tag;
    wire [31:0] S_O_retire_epoch;
    wire S_O_retire_old;
    reg S_I_retire_done_valid=0;
    wire S_O_retire_done_ready;
    reg [15:0] S_I_retire_done_tag=0;
    reg [31:0] S_I_retire_done_epoch=0;
    reg [3:0] S_I_retire_done_error=0;
    wire S_O_video_quarantined;
    wire S_O_video_response_discarded;
    frame_commit_cdc #(.CONFIG_BITS(32),.EPOCH_BITS(2)) u_dut (
        .O_apply_valid(),
        .I_host_clk(S_I_host_clk),
        .I_video_clk(S_I_video_clk),
        .I_async_reset(S_I_async_reset),
        .I_submit_valid(S_I_submit_valid),
        .O_submit_ready(S_O_submit_ready),
        .I_config(S_I_config),
        .I_tag(S_I_tag),
        .I_validate_error(S_I_validate_error),
        .I_abort(S_I_abort),
        .O_next_epoch(S_O_next_epoch),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_prepare_error(S_O_prepare_error),
        .O_retire_error(S_O_retire_error),
        .O_tag(S_O_tag),
        .O_epoch(S_O_epoch),
        .O_previous_epoch(S_O_previous_epoch),
        .O_applied(S_O_applied),
        .O_retired(S_O_retired),
        .O_quarantined(S_O_quarantined),
        .O_host_response_discarded(S_O_host_response_discarded),
        .O_pending_valid(S_O_pending_valid),
        .O_pending_config(S_O_pending_config),
        .O_pending_tag(S_O_pending_tag),
        .O_pending_epoch(S_O_pending_epoch),
        .O_prepare_valid(S_O_prepare_valid),
        .I_prepare_ready(S_I_prepare_ready),
        .O_prepare_abort(S_O_prepare_abort),
        .I_prepare_done_valid(S_I_prepare_done_valid),
        .O_prepare_done_ready(S_O_prepare_done_ready),
        .I_prepare_done_tag(S_I_prepare_done_tag),
        .I_prepare_done_epoch(S_I_prepare_done_epoch),
        .I_prepare_done_error(S_I_prepare_done_error),
        .I_frame_start(S_I_frame_start),
        .I_allow_apply(S_I_allow_apply),
        .I_video_abort(S_I_video_abort),
        .O_active_valid(S_O_active_valid),
        .O_active_config(S_O_active_config),
        .O_active_tag(S_O_active_tag),
        .O_active_epoch(S_O_active_epoch),
        .O_applied_pulse(S_O_applied_pulse),
        .O_retire_valid(S_O_retire_valid),
        .I_retire_ready(S_I_retire_ready),
        .O_retire_config(S_O_retire_config),
        .O_retire_tag(S_O_retire_tag),
        .O_retire_epoch(S_O_retire_epoch),
        .O_retire_old(S_O_retire_old),
        .I_retire_done_valid(S_I_retire_done_valid),
        .O_retire_done_ready(S_O_retire_done_ready),
        .I_retire_done_tag(S_I_retire_done_tag),
        .I_retire_done_epoch(S_I_retire_done_epoch),
        .I_retire_done_error(S_I_retire_done_error),
        .O_video_quarantined(S_O_video_quarantined),
        .O_video_response_discarded(S_O_video_response_discarded)
    );
    reg S_test_pass=0,S_host_run=1,S_video_run=1;
    integer S_case=0;
    always #4 if(S_host_run) S_I_host_clk=~S_I_host_clk;
    always #20 if(S_video_run) S_I_video_clk=~S_I_video_clk;
    task fail;
        input [767:0] message;
        begin $display("FAIL: commit case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #20000000; fail("watchdog timeout"); end
    task reset_all;
        begin
            S_host_run=1; S_video_run=1;
            @(negedge S_I_host_clk); S_I_async_reset=1; S_I_submit_valid=0; S_I_done_ready=0;
            S_I_abort=0; S_I_validate_error=0; S_I_prepare_ready=0; S_I_prepare_done_valid=0;
            S_I_retire_ready=0; S_I_retire_done_valid=0; S_I_frame_start=0;
            S_I_allow_apply=1; S_I_video_abort=0;
            repeat(6) @(negedge S_I_host_clk); S_I_async_reset=0;
            wait(S_O_submit_ready);
        end
    endtask
    task submit;
        input [31:0] config_value;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_host_clk); S_I_config=config_value; S_I_tag=tag; S_I_submit_valid=1;
            @(posedge S_I_host_clk); while(!S_O_submit_ready) @(posedge S_I_host_clk);
            @(negedge S_I_host_clk); S_I_submit_valid=0; S_I_config=32'hffffffff; S_I_tag=16'hffff;
        end
    endtask
    task prepare_start;
        input [31:0] config_value;
        input [15:0] tag;
        begin
            wait(S_O_prepare_valid); #1;
            repeat(3) begin @(negedge S_I_video_clk);
                if(!S_O_prepare_valid || S_O_pending_config!==config_value || S_O_pending_tag!==tag) fail("prepare payload snapshot/stability"); end
            S_I_prepare_ready=1; @(negedge S_I_video_clk); S_I_prepare_ready=0;
        end
    endtask
    task prepare_done;
        input [3:0] error;
        begin
            @(negedge S_I_video_clk); S_I_prepare_done_valid=1; S_I_prepare_done_epoch=S_O_pending_epoch;
            S_I_prepare_done_tag=S_O_pending_tag; S_I_prepare_done_error=error;
            @(posedge S_I_video_clk); while(!S_O_prepare_done_ready) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_I_prepare_done_valid=0;
        end
    endtask
    task frame;
        begin
            @(negedge S_I_video_clk); S_I_frame_start=1;
            @(negedge S_I_video_clk); S_I_frame_start=0;
        end
    endtask
    task retire;
        input old;
        input [31:0] config_value,epoch;
        input [15:0] tag;
        input [3:0] error;
        reg [80:0] saved;
        begin
            wait(S_O_retire_valid); #1;
            if(S_O_retire_old!==old || S_O_retire_config!==config_value || S_O_retire_epoch!==epoch || S_O_retire_tag!==tag)
                fail("wrong old/candidate retirement identity");
            saved={S_O_retire_old,S_O_retire_config,S_O_retire_epoch,S_O_retire_tag};
            repeat(4) begin @(negedge S_I_video_clk);
                if(!S_O_retire_valid || saved!=={S_O_retire_old,S_O_retire_config,S_O_retire_epoch,S_O_retire_tag}) fail("retire command changed under backpressure"); end
            S_I_retire_ready=1; @(negedge S_I_video_clk); S_I_retire_ready=0;
            repeat(5) begin @(negedge S_I_video_clk); if(S_O_done_valid) fail("retire acceptance treated as completion"); end
            // A stale completion must be drained without retiring current resources.
            S_I_retire_done_valid=1; S_I_retire_done_epoch=epoch+1; S_I_retire_done_tag=tag; S_I_retire_done_error=0;
            @(negedge S_I_video_clk); S_I_retire_done_valid=0;
            if(!S_O_video_response_discarded) fail("stale retirement not diagnosed");
            repeat(3) begin @(negedge S_I_video_clk); if(S_O_done_valid) fail("stale retirement completed current config"); end
            S_I_retire_done_valid=1; S_I_retire_done_epoch=epoch; S_I_retire_done_tag=tag; S_I_retire_done_error=error;
            @(negedge S_I_video_clk); S_I_retire_done_valid=0;
        end
    endtask
    task result;
        input [3:0] error;
        input applied,retired,quarantined;
        input [31:0] epoch,previous;
        input [15:0] tag;
        reg [94:0] saved;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_applied!==applied || S_O_retired!==retired ||
                S_O_quarantined!==quarantined || S_O_epoch!==epoch || S_O_previous_epoch!==previous || S_O_tag!==tag)
                fail("host result identity/facts");
            saved={S_O_error,S_O_prepare_error,S_O_retire_error,S_O_applied,S_O_retired,S_O_quarantined,
                S_O_tag,S_O_epoch,S_O_previous_epoch};
            S_I_abort=1;
            repeat(6) begin @(negedge S_I_host_clk);
                if(!S_O_done_valid || S_O_submit_ready || saved!=={S_O_error,S_O_prepare_error,S_O_retire_error,
                    S_O_applied,S_O_retired,S_O_quarantined,S_O_tag,S_O_epoch,S_O_previous_epoch}) fail("result not frozen"); end
            S_I_done_ready=1; @(negedge S_I_host_clk); S_I_done_ready=0; S_I_abort=0;
            if(!quarantined) wait(S_O_submit_ready);
        end
    endtask
    initial begin
        reset_all;
        submit(32'h11223344,1); prepare_start(32'h11223344,1);
        // Frame boundary concurrent with prepare completion must wait another frame.
        @(negedge S_I_video_clk); S_I_frame_start=1;
        fork prepare_done(0); begin repeat(2) @(negedge S_I_video_clk); S_I_frame_start=0; end join
        if(S_O_active_valid) fail("prepare done stole concurrent frame boundary");
        S_I_allow_apply=0; frame; if(S_O_active_valid) fail("readiness ignored");
        S_I_allow_apply=1; frame;
        if(!S_O_active_valid || S_O_active_config!==32'h11223344 || S_O_active_epoch!==1) fail("first atomic apply");
        result(0,1,1,0,1,0,1);
        // Second config swaps atomically, but old resource completion is still owed.
        submit(32'haabbccdd,2); prepare_start(32'haabbccdd,2);
        S_I_prepare_done_epoch=1; S_I_prepare_done_tag=2; S_I_prepare_done_valid=1;
        @(negedge S_I_video_clk); S_I_prepare_done_valid=0;
        if(!S_O_video_response_discarded) fail("stale prepare identity");
        prepare_done(0); repeat(5) @(negedge S_I_video_clk);
        if(S_O_active_config!==32'h11223344) fail("active changed in midframe");
        frame; S_I_abort=1; // Late abort cannot undo an applied configuration.
        retire(1,32'h11223344,1,1,0);
        if(S_O_active_config!==32'haabbccdd || S_O_active_epoch!==2) fail("late abort rolled back active");
        result(0,1,1,0,2,1,2);
        // Prepare error retains the active config and retires the candidate.
        submit(32'hdeadbeef,3); prepare_start(32'hdeadbeef,3); prepare_done(9);
        retire(0,32'hdeadbeef,3,3,0); result(2,0,1,0,3,0,3);
        if(S_O_prepare_error!==9 || S_O_active_config!==32'haabbccdd || S_O_next_epoch!==0) fail("prepare cause/epoch exhaustion");
        submit(32'h01020304,4); result(5,0,0,0,0,0,4);

        // Cancellation while prepare is active owes its real terminal, then cleanup.
        reset_all; submit(32'h11110000,5); prepare_start(32'h11110000,5);
        @(negedge S_I_host_clk); S_I_abort=1; wait(S_O_prepare_abort);
        repeat(5) begin @(negedge S_I_video_clk); if(S_O_retire_valid || S_O_done_valid) fail("cancel accepted is not prepare done"); end
        prepare_done(7); retire(0,32'h11110000,1,5,0); result(3,0,1,0,1,0,5);

        // Stop video before delivery; host remains busy, resumes without replay.
        reset_all; @(negedge S_I_video_clk); S_video_run=0;
        submit(32'h22220000,6); S_I_abort=1;
        repeat(30) @(negedge S_I_host_clk);
        if(S_O_done_valid || S_O_submit_ready) fail("completion without video clock");
        S_video_run=1; wait(S_O_pending_valid); wait(S_O_retire_valid);
        if(S_O_prepare_valid) fail("canceled command started prepare");
        retire(0,32'h22220000,1,6,0); result(3,0,1,0,1,0,6);

        // Permission revocation has priority over a simultaneous host cancellation.
        reset_all; submit(32'h33330000,7); prepare_start(32'h33330000,7);
        S_I_video_abort=1; prepare_done(0); S_I_video_abort=0;
        retire(0,32'h33330000,1,7,0); result(4,0,1,0,1,0,7);

        // A stopped host delays result consumption but cannot duplicate an apply.
        reset_all; submit(32'habcdef01,11); prepare_start(32'habcdef01,11); prepare_done(0);
        @(negedge S_I_host_clk); S_host_run=0;
        frame; repeat(8) @(negedge S_I_video_clk);
        if(!S_O_active_valid || S_O_active_epoch!==1 || S_O_submit_ready) fail("stopped host broke committed video state");
        S_host_run=1; result(0,1,1,0,1,0,11);

        // Same-cycle retirement accept/done is a real handshake, not a timeout.
        submit(32'habcdef02,12); prepare_start(32'habcdef02,12); prepare_done(0); frame;
        wait(S_O_retire_valid); @(negedge S_I_video_clk);
        S_I_retire_ready=1; S_I_retire_done_valid=1; S_I_retire_done_epoch=1; S_I_retire_done_tag=11;
        S_I_retire_done_error=0;
        @(negedge S_I_video_clk); S_I_retire_ready=0; S_I_retire_done_valid=0;
        result(0,1,1,0,2,1,12);

        // Once applied, a failed old-resource retirement reports the fact and quarantines.
        submit(32'habcdef03,13); prepare_start(32'habcdef03,13); prepare_done(0); frame;
        retire(1,32'habcdef02,2,12,9); result(6,1,0,1,3,2,13);
        if(S_O_active_config!==32'habcdef03 || S_O_active_epoch!==3) fail("retirement failure silently rolled back apply");

        // A failed real cleanup quarantines the transaction even after host result consumption.
        reset_all; submit(32'h44440000,8); prepare_start(32'h44440000,8); prepare_done(1);
        retire(0,32'h44440000,1,8,9); result(6,0,0,1,1,0,8);
        if(S_O_retire_error!==9 || !S_O_video_quarantined) fail("retire error diagnostics/quarantine");
        repeat(20) begin @(negedge S_I_host_clk); if(S_O_submit_ready || !S_O_busy) fail("quarantined resources reused"); end

        // Local validation never transfers candidate ownership or allocates an epoch.
        reset_all; S_I_validate_error=1; submit(32'h55550000,9); result(1,0,0,0,0,0,9);
        if(S_O_pending_valid || S_O_next_epoch!==1) fail("local rejection consumed epoch");
        S_I_validate_error=0; S_I_abort=1; submit(0,10); result(3,0,0,0,0,0,10);
        reset_all;
        S_test_pass=1; $display("PASS: frame_commit_cdc prepare/frame/retire protocol preparation"); $finish;
    end
endmodule
