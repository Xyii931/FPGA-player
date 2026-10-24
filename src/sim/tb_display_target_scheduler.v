`timescale 1ns/1ps
// Real timestamp FIFOs and counters; reference raster/target owner are explicit fixtures.
module tb_display_target_scheduler;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    wire S_video_reset;
    reset_sync u_reset (.I_clk(S_video_clk),.I_async_reset(S_reset),.O_reset(S_video_reset));
    reg [18:0] S_raster=0;
    always @(posedge S_video_clk or posedge S_video_reset)
        if(S_video_reset) S_raster<=0;
        else S_raster<=S_raster==419999 ? 0 : S_raster+1'b1;
    reg S_enable=1,S_abort=0,S_pending=0,S_active=0,S_target_valid=0;
    wire S_frame_start=S_raster==0 && !S_video_reset;
    reg [246:0] S_config=0;
    reg [31:0] S_pending_epoch=1,S_active_epoch=2,S_target_epoch=1,S_target_time=0;
    reg [15:0] S_pending_tag=16'h1234,S_active_tag=16'h5678,S_target_tag=16'h1234;
    reg [8:0] S_y=1;
    wire S_prepare_valid,S_scan_valid,S_apply,S_host_fault,S_fault,S_contract,S_discard,S_busy;
    wire [31:0] S_prepare_epoch,S_scan_epoch,S_scan_deadline,S_selected,S_host_time,S_video_time;
    wire [63:0] S_prepare_deadlines;
    wire [8:0] S_scan_y;
    integer S_case=0,S_prepares=0,S_scans=0,S_applies=0;
    reg [31:0] S_saved_target=0,S_lag=0;
    display_deadline_scheduler #(.USE_TARGET(1)) u_scheduler (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_clock_enable(S_enable),.I_video_abort(S_abort),.I_frame_start(S_frame_start),
        .I_target_valid(S_target_valid),.I_target_epoch(S_target_epoch),.I_target_time(S_target_time),.I_target_tag(S_target_tag),
        .I_pending_valid(S_pending),.I_pending_config(S_config),.I_pending_epoch(S_pending_epoch),.I_pending_tag(S_pending_tag),
        .I_active_valid(S_active),.I_active_epoch(S_active_epoch),.I_active_tag(S_active_tag),.I_prefetch_y(S_y),
        .O_prepare_deadline_valid(S_prepare_valid),.O_prepare_deadline_epoch(S_prepare_epoch),.O_prepare_deadlines(S_prepare_deadlines),
        .O_scan_deadline_valid(S_scan_valid),.O_scan_deadline_y(S_scan_y),.O_scan_deadline_epoch(S_scan_epoch),
        .O_scan_deadline(S_scan_deadline),.O_allow_apply(S_apply),.O_prepare_target(S_selected),
        .O_host_time(S_host_time),.O_video_time(S_video_time),.O_host_quarantined(S_host_fault),
        .O_contract_fault(S_contract),.O_quarantined(S_fault),.O_response_discarded(S_discard),.O_busy(S_busy)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: target scheduler case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin repeat(4) #1000000000; fail("watchdog timeout"); end
    always @(posedge S_video_clk) if(!S_video_reset) begin
        if(u_scheduler.S_state==1 && u_scheduler.S_d_ready) begin
            if(u_scheduler.S_kind) S_scans=S_scans+1;
            else begin
                S_prepares=S_prepares+1;
                S_lag=u_scheduler.S_target-S_target_time;
                if(!S_target_valid || S_target_epoch!==S_pending_epoch || S_target_tag!==S_pending_tag ||
                    S_lag[31] || S_lag%32'd420000!=0 || u_scheduler.S_selected_lead>1048576)
                    fail("prepare ignored requested identity/grid/conversion horizon");
            end
        end
        if(S_apply) begin
            S_lag=S_video_time-S_target_time; S_applies=S_applies+1;
            if(!S_frame_start || S_video_time!==S_selected || !S_target_valid || S_lag[31] || S_lag%32'd420000!=0)
                fail("apply escaped real selected target frame");
        end
    end
    task reset_all;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_enable=1; S_abort=0;
            S_pending=0; S_active=0; S_target_valid=0; S_target_epoch=1; S_target_tag=16'h1234; S_target_time=0;
            S_pending_epoch=1; S_pending_tag=16'h1234; S_active_epoch=2; S_active_tag=16'h5678;
            S_config=0; S_config[245]=1; S_y=1;
            repeat(6) @(negedge S_video_clk); S_reset=0;
            wait(!S_video_reset); @(negedge S_video_clk); S_prepares=0; S_scans=0; S_applies=0;
        end
    endtask
    task target_from_frame;
        input [31:0] frames_ahead;
        begin
            wait(u_scheduler.S_anchored); @(negedge S_video_clk);
            S_target_time=u_scheduler.S_live_origin+frames_ahead*32'd420000;
            S_target_valid=1; S_target_epoch=S_pending_epoch; S_target_tag=S_pending_tag;
        end
    endtask
    task no_prepare;
        input integer cycles;
        integer j;
        begin for(j=0;j<cycles;j=j+1) begin @(negedge S_video_clk);
            if(S_prepare_valid || S_apply || S_prepares!=0 || S_fault)
                fail("unmapped or distant target started preparation/isolated instead of waiting"); end end
    endtask
    initial begin
        S_case=1; reset_all; S_pending=1; S_active=1;
        no_prepare(60); wait(S_scan_valid);
        if(S_scans==0) fail("missing target blocked old foreground scan deadlines");
        target_from_frame(2); S_target_epoch=3; no_prepare(30);
        S_target_epoch=1; S_target_tag=16'h9999; no_prepare(30);
        S_target_tag=S_pending_tag; wait(S_prepare_valid);
        if(S_selected!==S_target_time || S_selected!=840000 || S_fault) fail("future mapped target was replaced by nearest frame");
        wait(S_apply); @(negedge S_video_clk); S_pending=0;

        S_case=2; reset_all; S_pending=1; S_active=1; target_from_frame(5);
        no_prepare(100); wait(S_scan_valid);
        wait(S_video_time==32'd1051000); @(negedge S_video_clk);
        if(S_prepares!=0 || S_fault) fail("far target was converted outside bridge horizon");
        wait(S_prepare_valid);
        if(S_selected!=2100000 || S_target_time!=2100000 || S_fault) fail("far target changed while waiting for conversion horizon");

        S_case=3; reset_all; S_pending=1; target_from_frame(2); wait(S_prepare_valid);
        S_saved_target=S_selected;
        @(negedge S_video_clk); S_target_time=S_target_time+420000; #1;
        if(S_prepare_valid || S_apply) fail("changed requested time retained same-epoch cached authority");
        wait(S_prepare_valid);
        if(S_selected!=S_saved_target+420000 || u_scheduler.S_prepare_requested_target!==S_target_time)
            fail("cache did not preserve original requested-target identity");

        S_case=4; reset_all; S_pending=1; target_from_frame(2); wait(S_prepare_valid);
        @(negedge S_video_clk); S_target_valid=0;
        repeat(3) @(negedge S_video_clk); S_target_valid=1; #1;
        if(S_prepare_valid || S_apply) fail("withdraw/reissue resurrected old target cache");
        wait(S_prepare_valid); if(S_fault) fail("reissued target did not reconvert");

        S_case=5; reset_all; wait(S_raster==400000); S_pending=1;
        target_from_frame(1); wait(S_prepare_valid);
        if(S_selected!=840000 || S_target_time!=420000) fail("insufficient lead did not slip by one full frame");

        S_case=6; reset_all; S_pending=1; target_from_frame(1); wait(S_prepare_valid);
        S_saved_target=S_target_time; wait(S_apply); @(negedge S_video_clk);
        wait(S_prepare_valid);
        if(S_selected!=S_saved_target+420000 || S_target_time!==S_saved_target)
            fail("missed frame rewrote original target or lost complete-frame retry");

        S_case=7; reset_all; S_pending=1; S_active=1; target_from_frame(2); wait(S_prepare_valid && S_scan_valid);
        @(negedge S_video_clk); S_abort=1; #1;
        if(S_prepare_valid || S_apply || !S_scan_valid) fail("target abort damaged foreground scan or retained apply");
        repeat(3) @(negedge S_video_clk); S_abort=0; #1;
        if(S_prepare_valid) fail("clearing target abort resurrected old deadline");
        wait(S_prepare_valid);

        S_case=8; reset_all; S_pending=1; target_from_frame(2); wait(S_prepare_valid);
        @(negedge S_video_clk); S_enable=0; S_video_run=0;
        repeat(50) begin @(negedge S_host_clk);
            if(S_prepare_valid || S_apply || S_applies!=0) fail("stopped video retained target authority"); end
        S_video_run=1; repeat(3) @(negedge S_video_clk); S_enable=1;
        repeat(50) begin @(negedge S_video_clk);
            if(S_prepare_valid || S_apply) fail("recovery reused target without new real frame anchor"); end
        wait(S_prepare_valid); if(S_selected!==S_target_time || S_fault) fail("reanchored target lost planned future frame");

        S_case=9; reset_all; @(negedge S_host_clk); S_host_run=0;
        S_pending=1; target_from_frame(2); wait(u_scheduler.S_state==2);
        S_saved_target=u_scheduler.S_target;
        @(negedge S_video_clk); S_target_time=S_target_time+420000;
        repeat(40) begin @(negedge S_video_clk);
            if(u_scheduler.S_state!=2 || u_scheduler.S_target!==S_saved_target || S_prepare_valid)
                fail("target replacement fabricated retirement during host stop"); end
        S_host_run=1; wait(S_prepare_valid);
        if(S_selected!==S_target_time || S_fault) fail("stale real conversion installed replacement target cache");

        S_case=10; reset_all; S_pending=1; target_from_frame(2);
        S_target_time=S_target_time+1;
        wait(S_fault); #1;
        if(!S_contract || S_prepare_valid || S_apply || S_prepares!=0) fail("off-grid target did not isolate before preparation");

        S_case=11; reset_all; S_pending=1; target_from_frame(0);
        S_target_time=u_scheduler.S_live_origin+32'h80000000;
        wait(S_fault); #1;
        if(!S_contract || S_prepare_valid || S_apply) fail("half-range target ambiguity was accepted");

        S_case=12; reset_all; S_pending=1; target_from_frame(0); wait(S_prepare_valid);
        if(S_selected!=420000 || S_target_time!=0) fail("already passed target was not retried on its real grid");
        @(negedge S_video_clk); S_config[68]=1; #1;
        if(S_prepare_valid) fail("requested time hid changed full pending configuration");
        wait(S_prepare_valid);

        S_case=13; reset_all; S_enable=0;
        repeat(3) @(negedge S_video_clk);
        // Counter seed only: exercise mod32 rollover without replacing any bridge response.
        u_scheduler.u_deadline.O_video_time=32'hfff80000;
        S_enable=1; wait(u_scheduler.S_anchored); S_pending=1; target_from_frame(2);
        if(S_target_time>=u_scheduler.S_live_origin) fail("rollover fixture did not select wrapped target");
        wait(S_prepare_valid); if(S_selected!==S_target_time || S_fault) fail("wrapped future target was mistaken for stale history");
        wait(S_apply); @(negedge S_video_clk); S_pending=0;

        S_case=14; reset_all; S_pending=1; target_from_frame(2); S_target_valid=0;
        S_target_time=S_target_time+1;
        no_prepare(40); S_target_time=S_target_time-1; S_target_valid=1;
        wait(S_prepare_valid); if(S_fault || S_host_fault) fail("invalid data without target-valid damaged recovered service");
        $display("PASS: 14 targeted scheduler scenarios using real deadline FIFOs, frame grid, horizon, cancellation and rollover");
        S_test_pass=1; $finish;
    end
endmodule
