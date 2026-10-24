`timescale 1ns/1ps
// Real deadline CDC; a reference raster supplies frame pulses, never a fake bridge result.
module tb_display_deadline_scheduler;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 S_video_clk=~S_video_clk;
    wire S_video_reset;
    reset_sync u_reset (.I_clk(S_video_clk),.I_async_reset(S_reset),.O_reset(S_video_reset));
    reg [18:0] S_raster=0;
    always @(posedge S_video_clk or posedge S_video_reset)
        if(S_video_reset) S_raster<=0;
        else S_raster<=S_raster==419999 ? 0 : S_raster+1'b1;
    reg S_frame_gate=1,S_enable=1,S_abort=0,S_pending=0,S_active=0;
    wire S_frame_start=S_frame_gate && S_raster==0 && !S_video_reset;
    reg [246:0] S_config=0;
    reg [31:0] S_pending_epoch=1,S_active_epoch=2;
    reg [15:0] S_pending_tag=16'h1234,S_active_tag=16'h5678;
    reg [8:0] S_y=1;
    wire S_prepare_valid,S_scan_valid,S_apply,S_host_fault,S_fault,S_contract,S_discard,S_busy;
    wire [31:0] S_prepare_epoch,S_scan_epoch,S_scan_deadline,S_target,S_host_time,S_video_time;
    wire [63:0] S_prepare_deadlines;
    wire [8:0] S_scan_y;
    integer S_case=0,S_offers=0,S_discard_count=0;
    reg [7:0] S_kind_order=0;
    reg [31:0] S_saved_target=0,S_saved_deadline=0;
    reg [246:0] S_saved_config=0;
    display_deadline_scheduler u_scheduler (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_clock_enable(S_enable),.I_video_abort(S_abort),.I_frame_start(S_frame_start),
        .I_target_valid(1'b0),.I_target_epoch(32'd0),.I_target_time(32'd0),.I_target_tag(16'd0),
        .I_pending_valid(S_pending),.I_pending_config(S_config),.I_pending_epoch(S_pending_epoch),.I_pending_tag(S_pending_tag),
        .I_active_valid(S_active),.I_active_epoch(S_active_epoch),.I_active_tag(S_active_tag),.I_prefetch_y(S_y),
        .O_prepare_deadline_valid(S_prepare_valid),.O_prepare_deadline_epoch(S_prepare_epoch),.O_prepare_deadlines(S_prepare_deadlines),
        .O_scan_deadline_valid(S_scan_valid),.O_scan_deadline_y(S_scan_y),.O_scan_deadline_epoch(S_scan_epoch),
        .O_scan_deadline(S_scan_deadline),.O_allow_apply(S_apply),.O_prepare_target(S_target),
        .O_host_time(S_host_time),.O_video_time(S_video_time),.O_host_quarantined(S_host_fault),
        .O_contract_fault(S_contract),.O_quarantined(S_fault),.O_response_discarded(S_discard),.O_busy(S_busy)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: deadline scheduler case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #2000000000; fail("watchdog timeout"); end
    always @(posedge S_video_clk) if(!S_video_reset) begin
        if(u_scheduler.S_state==1 && u_scheduler.S_d_ready) begin
            if(S_offers<8) S_kind_order[S_offers]=u_scheduler.S_kind;
            S_offers=S_offers+1;
        end
        if(S_apply && (!S_frame_start || S_video_time!==S_target)) fail("apply escaped actual selected frame");
        #1; if(S_discard) S_discard_count=S_discard_count+1;
    end
    task reset_all;
        begin
            S_host_run=1; S_reset=1; S_enable=1; S_abort=0; S_pending=0; S_active=0; S_frame_gate=1;
            S_config=0; S_config[245]=1; S_pending_epoch=1; S_pending_tag=16'h1234;
            S_active_epoch=2; S_active_tag=16'h5678; S_y=1;
            repeat(6) @(negedge S_video_clk); S_reset=0;
            wait(!S_video_reset); @(negedge S_video_clk); S_offers=0; S_kind_order=0; S_discard_count=0;
        end
    endtask
    initial begin
        S_case=1; reset_all; S_pending=1; S_active=1;
        wait(S_prepare_valid && S_scan_valid); #1;
        if(S_kind_order[1:0]!=2'b10 || S_prepare_deadlines[63:32]!==S_prepare_deadlines[31:0] ||
            S_scan_epoch!=2 || S_scan_y!=1 || S_target!=420000 || S_fault)
            fail("prepare/scan fairness or first observed frame target");
        if(u_scheduler.S_scan_target!=28800) fail("scan deadline targeted first pixel instead of row selection edge");
        S_saved_target=S_target;
        wait(!S_prepare_valid);
        if(S_target!==S_saved_target || !u_scheduler.S_prepare_cached) fail("deadline expiry discarded the planned apply frame");
        wait(S_apply); #1;
        if(S_video_time!=S_saved_target || S_prepare_valid) fail("expired deadline prevented scheduled apply or remained consumable");
        @(negedge S_video_clk); wait(S_prepare_valid); #1;
        if(S_target!=840000) fail("missed target frame was not retargeted after its real edge");

        S_case=2; reset_all; S_pending=1; wait(S_prepare_valid);
        @(negedge S_video_clk); S_config[68]=1; #1;
        if(S_prepare_valid || S_apply) fail("same epoch changed full config reused old preparation cache");
        wait(S_prepare_valid);
        if(u_scheduler.S_prepare_config!==S_config) fail("new full configuration was not reconverted");
        @(negedge S_video_clk); S_pending_tag=S_pending_tag+1; #1;
        if(S_prepare_valid) fail("prepare tag change retained old cache");

        S_case=3; reset_all; S_active=1; wait(S_scan_valid);
        @(negedge S_video_clk); S_y=2; #1;
        if(S_scan_valid) fail("scan row change retained old deadline"); wait(S_scan_valid);
        if(S_scan_y!=2) fail("scan row cache identity");
        @(negedge S_video_clk); S_active_tag=S_active_tag+1; #1;
        if(S_scan_valid) fail("scan tag change retained old deadline"); wait(S_scan_valid);
        @(negedge S_video_clk); S_active_epoch=3; #1;
        if(S_scan_valid) fail("scan epoch change retained old deadline"); wait(S_scan_valid);
        S_saved_deadline=S_scan_deadline;
        wait(S_raster==30000); #1;
        if(S_scan_valid || u_scheduler.S_want_scan) fail("past current-frame row disguised as a next-frame deadline");

        S_case=4; reset_all; S_frame_gate=0; S_pending=1; S_active=1;
        repeat(80) begin @(negedge S_video_clk); if(S_prepare_valid || S_scan_valid || S_offers!=0)
            fail("deadline service guessed a frame anchor from reset"); end
        S_frame_gate=1; wait(S_prepare_valid && S_scan_valid);

        S_case=5; reset_all; S_pending=1; S_active=1; wait(S_prepare_valid && S_scan_valid);
        @(negedge S_video_clk); S_abort=1; #1;
        if(S_prepare_valid || S_apply || !S_scan_valid) fail("prepare abort damaged old foreground scan scheduling");
        repeat(2) @(negedge S_video_clk); S_abort=0; #1;
        if(S_prepare_valid) fail("aborted prepare cache resurrected on abort clear");
        wait(S_prepare_valid);

        S_case=6; reset_all; S_pending=1; S_active=1; wait(S_prepare_valid && S_scan_valid);
        @(negedge S_video_clk); S_enable=0; #1;
        if(S_prepare_valid || S_scan_valid || S_apply) fail("clock withdrawal retained deadline authority");
        repeat(3) @(negedge S_video_clk); S_enable=1;
        repeat(30) begin @(negedge S_video_clk); if(S_prepare_valid || S_scan_valid || S_apply)
            fail("clock recovery reused a stale observed frame anchor"); end
        wait(S_prepare_valid && S_scan_valid);

        S_case=7; reset_all;
        force u_scheduler.S_d_ready=1'b0;
        force u_scheduler.u_deadline.I_request_valid=1'b0;
        S_pending=1; wait(u_scheduler.S_state==1); S_saved_config=u_scheduler.S_config;
        @(negedge S_video_clk); S_pending=0; S_config[68]=1;
        repeat(12) begin @(negedge S_video_clk);
            if(u_scheduler.S_state!=1 || u_scheduler.S_config!==S_saved_config || !u_scheduler.u_deadline.I_abort)
                fail("cancel withdrew or mutated a presented conversion offer"); end
        release u_scheduler.S_d_ready; release u_scheduler.u_deadline.I_request_valid;
        wait(u_scheduler.S_state==0); #1;
        if(S_prepare_valid || S_apply || S_fault) fail("cancelled stale offer installed a cache");

        S_case=8; reset_all; @(negedge S_host_clk); S_host_run=0;
        S_pending=1; wait(u_scheduler.S_state==2);
        @(negedge S_video_clk); S_pending_epoch=3;
        repeat(25) begin @(negedge S_video_clk); if(u_scheduler.S_state!=2 || S_prepare_valid)
            fail("pending identity change fabricated bridge retirement during host stop"); end
        S_host_run=1; wait(S_prepare_valid);
        if(S_prepare_epoch!=3 || S_fault) fail("old conversion crossed into replacement pending identity");

        S_case=9; reset_all; S_pending=1; wait(S_prepare_valid);
        // Assert an impossible second frame pulse without 420000 real pixel clocks.
        @(negedge S_video_clk); force u_scheduler.I_frame_start=1'b1;
        @(negedge S_video_clk); release u_scheduler.I_frame_start;
        if(!S_contract || !S_fault || S_prepare_valid || S_apply) fail("inconsistent real frame cadence did not isolate");

        S_case=10; reset_all; S_pending_epoch=0; S_pending=1;
        repeat(5) @(negedge S_video_clk);
        if(!S_contract || !S_fault || S_prepare_valid || S_offers!=0) fail("invalid pending identity was accepted");
        reset_all; S_pending=1; wait(S_prepare_valid);
        if(S_fault || S_host_fault) fail("global reset did not recover timing contract isolation");
        S_case=11; reset_all; S_pending=1; wait(S_prepare_valid);
        @(negedge S_video_clk); S_frame_gate=0;
        wait(S_fault); #1;
        if(!S_contract || S_prepare_valid || S_apply) fail("missing observed frame cadence retained predicted time authority");
        S_case=12; reset_all;
        wait(S_raster==400000); @(negedge S_video_clk); S_pending=1; S_active=1; S_y=479;
        wait(S_prepare_valid && S_scan_valid); #1;
        if(S_target!=840000 || u_scheduler.S_scan_target!=411200 || S_fault)
            fail("late-frame preparation ignored minimum lead or moved scan into another frame");
        $display("PASS: deadline target selection, fair arbitration, complete cache identity, expiry and real FIFO drain");
        S_test_pass=1; $finish;
    end
endmodule
