`timescale 1ns/1ps
// Actual command/result FIFOs. Display execution/retirement are explicit protocol peers.
module tb_display_event_executor;
    reg S_d_I_frame_start=0,S_d_I_active_valid=0;
    reg S_host_clk=0,S_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_clk=~S_clk;
    reg S_d_I_clock_enable=0;
    reg [31:0] S_d_I_video_time=0;
    reg S_d_I_event_valid=0;
    wire S_d_O_event_ready;
    reg [31:0] S_d_I_event_epoch=0;
    reg [15:0] S_d_I_event_tag=0;
    reg [15:0] S_d_I_event_index=0;
    reg [2:0] S_d_I_event_effect=0;
    reg [16:0] S_d_I_event_progress=0;
    reg [31:0] S_d_I_event_target=0;
    reg [246:0] S_d_I_config=0;
    reg S_d_I_cancel=0;
    reg [3:0] S_d_I_bank_busy=0;
    wire S_d_O_busy;
    wire S_d_O_done_valid;
    reg S_d_I_done_ready=0;
    wire [31:0] S_d_O_epoch;
    wire [15:0] S_d_O_tag;
    wire [15:0] S_d_O_index;
    wire [3:0] S_d_O_error;
    wire [3:0] S_d_O_backend_error;
    wire [3:0] S_d_O_lease_error;
    wire [3:0] S_d_O_slot_error;
    wire [3:0] S_d_O_commit_error;
    wire [3:0] S_d_O_prepare_error;
    wire [3:0] S_d_O_retire_error;
    wire S_d_O_applied;
    wire S_d_O_retired;
    wire [31:0] S_d_O_apply_time;
    wire [31:0] S_d_O_commit_epoch;
    wire S_d_O_quarantined;
    wire S_d_O_response_discarded;
    wire S_d_O_target_valid;
    wire [31:0] S_d_O_target_epoch;
    wire [31:0] S_d_O_target_time;
    wire [15:0] S_d_O_target_tag;
    wire S_d_O_video_abort;
    reg S_d_I_pending_valid=0;
    reg [246:0] S_d_I_pending_config=0;
    reg [31:0] S_d_I_pending_epoch=0;
    reg [15:0] S_d_I_pending_tag=0;
    reg S_d_I_local_applied=0;
    reg [246:0] S_d_I_active_config=0;
    reg [31:0] S_d_I_active_epoch=0;
    reg [15:0] S_d_I_active_tag=0;
    wire S_d_O_host_start_valid;
    reg S_d_I_host_start_ready=0;
    wire [246:0] S_d_O_host_config;
    wire [15:0] S_d_O_host_tag;
    wire S_d_O_host_abort;
    reg [31:0] S_d_I_host_next_epoch=0;
    reg S_d_I_host_done_valid=0;
    wire S_d_O_host_done_ready;
    reg [31:0] S_d_I_host_epoch=0;
    reg [15:0] S_d_I_host_tag=0;
    reg [3:0] S_d_I_host_error=0;
    reg [3:0] S_d_I_host_lease_error=0;
    reg [3:0] S_d_I_host_slot_error=0;
    reg [3:0] S_d_I_host_commit_error=0;
    reg [3:0] S_d_I_host_prepare_error=0;
    reg [3:0] S_d_I_host_retire_error=0;
    reg S_d_I_host_applied=0;
    reg S_d_I_host_retired=0;
    reg S_d_I_host_quarantined=0;
    wire S_d_O_host_quarantined;
    wire S_d_O_host_response_discarded;
    display_event_executor u_executor (
        .I_frame_start(S_d_I_frame_start),.I_active_valid(S_d_I_active_valid),
        .I_host_clk(S_host_clk),
        .I_video_clk(S_clk),
        .I_async_reset(S_reset),
        .I_clock_enable(S_d_I_clock_enable),
        .I_video_time(S_d_I_video_time),
        .I_event_valid(S_d_I_event_valid),
        .O_event_ready(S_d_O_event_ready),
        .I_event_epoch(S_d_I_event_epoch),
        .I_event_tag(S_d_I_event_tag),
        .I_event_index(S_d_I_event_index),
        .I_event_effect(S_d_I_event_effect),
        .I_event_progress(S_d_I_event_progress),
        .I_event_target(S_d_I_event_target),
        .I_config(S_d_I_config),
        .I_cancel(S_d_I_cancel),
        .I_bank_busy(S_d_I_bank_busy),
        .O_busy(S_d_O_busy),
        .O_done_valid(S_d_O_done_valid),
        .I_done_ready(S_d_I_done_ready),
        .O_epoch(S_d_O_epoch),
        .O_tag(S_d_O_tag),
        .O_index(S_d_O_index),
        .O_error(S_d_O_error),
        .O_backend_error(S_d_O_backend_error),
        .O_lease_error(S_d_O_lease_error),
        .O_slot_error(S_d_O_slot_error),
        .O_commit_error(S_d_O_commit_error),
        .O_prepare_error(S_d_O_prepare_error),
        .O_retire_error(S_d_O_retire_error),
        .O_applied(S_d_O_applied),
        .O_retired(S_d_O_retired),
        .O_apply_time(S_d_O_apply_time),
        .O_commit_epoch(S_d_O_commit_epoch),
        .O_quarantined(S_d_O_quarantined),
        .O_response_discarded(S_d_O_response_discarded),
        .O_target_valid(S_d_O_target_valid),
        .O_target_epoch(S_d_O_target_epoch),
        .O_target_time(S_d_O_target_time),
        .O_target_tag(S_d_O_target_tag),
        .O_video_abort(S_d_O_video_abort),
        .I_pending_valid(S_d_I_pending_valid),
        .I_pending_config(S_d_I_pending_config),
        .I_pending_epoch(S_d_I_pending_epoch),
        .I_pending_tag(S_d_I_pending_tag),
        .I_local_applied(S_d_I_local_applied),
        .I_active_config(S_d_I_active_config),
        .I_active_epoch(S_d_I_active_epoch),
        .I_active_tag(S_d_I_active_tag),
        .O_host_start_valid(S_d_O_host_start_valid),
        .I_host_start_ready(S_d_I_host_start_ready),
        .O_host_config(S_d_O_host_config),
        .O_host_tag(S_d_O_host_tag),
        .O_host_abort(S_d_O_host_abort),
        .I_host_next_epoch(S_d_I_host_next_epoch),
        .I_host_done_valid(S_d_I_host_done_valid),
        .O_host_done_ready(S_d_O_host_done_ready),
        .I_host_epoch(S_d_I_host_epoch),
        .I_host_tag(S_d_I_host_tag),
        .I_host_error(S_d_I_host_error),
        .I_host_lease_error(S_d_I_host_lease_error),
        .I_host_slot_error(S_d_I_host_slot_error),
        .I_host_commit_error(S_d_I_host_commit_error),
        .I_host_prepare_error(S_d_I_host_prepare_error),
        .I_host_retire_error(S_d_I_host_retire_error),
        .I_host_applied(S_d_I_host_applied),
        .I_host_retired(S_d_I_host_retired),
        .I_host_quarantined(S_d_I_host_quarantined),
        .O_host_quarantined(S_d_O_host_quarantined),
        .O_host_response_discarded(S_d_O_host_response_discarded)
    );
    integer S_case=0,S_host_commands=0;
    reg [246:0] S_saved_config=0;
    reg [31:0] S_expected=100,S_saved_time=0;
    reg [15:0] S_saved_tag=0;
    reg [158:0] S_saved_result=0;
    always @(posedge S_clk or posedge S_reset)
        if(S_reset) S_d_I_video_time<=0;
        else S_d_I_video_time<=S_d_I_video_time+1'b1;
    always @(posedge S_host_clk) if(!S_reset && S_d_O_host_start_valid && S_d_I_host_start_ready)
        S_host_commands=S_host_commands+1;
    task fail;
        input [767:0] message;
        begin $display("FAIL: event executor case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin repeat(4) #1000000000; fail("watchdog timeout"); end
    task reset_all;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_d_I_frame_start=0; S_d_I_active_valid=0;
            S_d_I_clock_enable=1; S_d_I_event_valid=0; S_d_I_cancel=0; S_d_I_done_ready=0;
            S_d_I_bank_busy=0; S_d_I_pending_valid=0; S_d_I_local_applied=0;
            S_d_I_pending_config=0; S_d_I_pending_epoch=0; S_d_I_pending_tag=0;
            S_d_I_active_config=0; S_d_I_active_epoch=0; S_d_I_active_tag=0;
            S_d_I_host_start_ready=0; S_d_I_host_done_valid=0; S_d_I_host_epoch=0; S_d_I_host_tag=0;
            S_d_I_host_error=0; S_d_I_host_lease_error=0; S_d_I_host_slot_error=0;
            S_d_I_host_commit_error=0; S_d_I_host_prepare_error=0; S_d_I_host_retire_error=0;
            S_d_I_host_applied=0; S_d_I_host_retired=0; S_d_I_host_quarantined=0;
            S_expected=100; S_d_I_host_next_epoch=100;
            S_d_I_config=0; S_d_I_config[246:245]=3; S_d_I_config[104:89]=2;
            S_d_I_config[237:174]={32'd22,32'd11}; S_d_I_config[173:110]={32'd4,32'd4};
            repeat(6) @(negedge S_clk); S_reset=0; wait(S_d_O_event_ready); S_host_commands=0;
        end
    endtask
    task event_offer;
        input [31:0] epoch;
        input [15:0] index;
        begin
            @(negedge S_clk); S_d_I_event_epoch=epoch; S_d_I_event_tag=16'hb123; S_d_I_event_index=index;
            S_d_I_event_effect=0; S_d_I_event_progress=32768; S_d_I_event_target=S_d_I_video_time+150;
            S_d_I_event_valid=1;
            @(posedge S_clk); while(!S_d_O_event_ready) @(posedge S_clk);
            @(negedge S_clk); S_d_I_event_valid=0;
        end
    endtask
    task backend_accept;
        begin
            wait(S_d_O_host_start_valid);
            @(negedge S_host_clk); S_saved_config=S_d_O_host_config; S_saved_tag=S_d_O_host_tag;
            S_d_I_host_next_epoch=S_expected; S_d_I_host_start_ready=1;
            @(posedge S_host_clk); if(!S_d_O_host_start_valid) fail("presented host offer disappeared");
            @(negedge S_host_clk); S_d_I_host_start_ready=0;
        end
    endtask
    task pending_install;
        begin
            @(negedge S_clk); S_d_I_pending_valid=1; S_d_I_pending_config=S_saved_config;
            S_d_I_pending_epoch=S_expected; S_d_I_pending_tag=S_saved_tag;
            repeat(3) @(negedge S_clk);
            if(!S_d_O_target_valid || S_d_O_target_epoch!==S_expected || S_d_O_target_time!==S_d_I_event_target)
                fail("complete pending identity did not establish distinct commit mapping");
        end
    endtask
    task local_apply;
        begin
            wait(S_d_I_video_time==S_d_I_event_target+1'b1); @(negedge S_clk);
            S_d_I_pending_valid=0; S_d_I_active_config=S_saved_config;
            S_d_I_active_epoch=S_expected; S_d_I_active_tag=S_saved_tag; S_d_I_local_applied=1;
            @(negedge S_clk); S_d_I_local_applied=0;
            if(!S_d_O_applied || S_d_O_apply_time!==S_d_I_event_target)
                fail("registered actual apply fact was not stamped at time minus one");
        end
    endtask
    task backend_done;
        input [3:0] error;
        input applied,retired;
        begin
            @(negedge S_host_clk); S_d_I_host_epoch=S_expected; S_d_I_host_tag=S_saved_tag;
            S_d_I_host_error=error; S_d_I_host_applied=applied; S_d_I_host_retired=retired; S_d_I_host_done_valid=1;
            @(posedge S_host_clk); while(!S_d_O_host_done_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_d_I_host_done_valid=0; S_d_I_host_start_ready=1;
        end
    endtask
    task result;
        input [3:0] error;
        input applied;
        begin
            wait(S_d_O_done_valid); #1;
            if(S_d_O_error!==error || S_d_O_applied!==applied || S_d_O_epoch!==S_d_I_event_epoch ||
                S_d_O_tag!==S_d_I_event_tag || S_d_O_index!==S_d_I_event_index)
                fail("identified terminal differs from actual event/commit facts");
            S_saved_result={S_d_O_epoch,S_d_O_tag,S_d_O_index,S_d_O_error,S_d_O_backend_error,
                S_d_O_lease_error,S_d_O_slot_error,S_d_O_commit_error,S_d_O_prepare_error,S_d_O_retire_error,
                S_d_O_applied,S_d_O_retired,S_d_O_apply_time,S_d_O_commit_epoch,S_d_O_quarantined};
            S_d_I_cancel=1;
            repeat(8) begin @(negedge S_clk);
                if(!S_d_O_done_valid || S_d_O_event_ready || S_saved_result!=={S_d_O_epoch,S_d_O_tag,S_d_O_index,
                    S_d_O_error,S_d_O_backend_error,S_d_O_lease_error,S_d_O_slot_error,S_d_O_commit_error,
                    S_d_O_prepare_error,S_d_O_retire_error,S_d_O_applied,S_d_O_retired,S_d_O_apply_time,
                    S_d_O_commit_epoch,S_d_O_quarantined}) fail("new abort mutated a backpressured result");
            end
            S_d_I_done_ready=1; @(negedge S_clk); S_d_I_done_ready=0; S_d_I_cancel=0;
        end
    endtask
    initial begin
        S_case=1; reset_all; S_d_I_bank_busy=15; event_offer(7,0);
        repeat(20) @(negedge S_clk);
        if(S_host_commands!=0 || S_d_O_host_start_valid || S_d_O_done_valid) fail("busy banks did not hold unpresented command");
        S_d_I_cancel=1; result(3,0);
        if(S_host_commands!=0) fail("local bank-wait cancellation created host work");

        S_case=2; reset_all; event_offer(7,4); backend_accept; pending_install; local_apply; backend_done(0,1,1); result(0,1);
        if(S_d_O_commit_epoch!=100 || S_d_O_epoch!=7 || S_d_O_quarantined) fail("timeline epoch was used as underlying commit epoch");
        wait(S_d_O_event_ready); @(negedge S_host_clk); S_d_I_host_start_ready=0;

        S_case=3; S_expected=101; S_d_I_bank_busy=5; event_offer(7,5);
        wait(S_d_O_host_start_valid); S_saved_config=S_d_O_host_config;
        S_d_I_config=0;
        repeat(15) begin @(negedge S_host_clk);
            if(!S_d_O_host_start_valid || S_d_O_host_config!==S_saved_config || S_d_O_host_config[33:32]!=3)
                fail("host offer mutated or did not choose actual free banks"); end
        backend_accept; pending_install; local_apply; backend_done(0,1,1); result(0,1);
        if(S_d_O_commit_epoch!=101 || S_host_commands!=2) fail("consecutive event reuse lost unique commit mapping");

        S_case=4; reset_all; event_offer(8,0); wait(S_d_O_host_start_valid);
        @(negedge S_clk); S_d_I_cancel=1;
        repeat(15) begin @(negedge S_host_clk);
            if(!S_d_O_host_start_valid || S_d_O_done_valid) fail("cancellation withdrew a presented host offer"); end
        backend_accept; if(!S_d_O_host_abort) fail("held cancellation did not cross to host owner");
        S_expected=0; backend_done(3,0,0); wait(S_d_O_done_valid);
        @(negedge S_host_clk); S_host_run=0; result(3,0);
        repeat(30) begin @(negedge S_clk);
            if(S_d_O_event_ready) fail("stopped host fabricated four-phase cancellation clear"); end
        S_host_run=1; wait(S_d_O_event_ready);

        S_case=5; reset_all; event_offer(9,0); backend_accept;
        @(negedge S_clk); S_video_run=0;
        backend_done(2,0,1);
        repeat(30) begin @(negedge S_host_clk);
            if(S_d_O_done_valid) fail("stopped event clock fabricated returned completion"); end
        S_video_run=1; result(2,0);

        S_case=6; reset_all; event_offer(10,0); backend_accept;
        @(negedge S_host_clk); S_d_I_host_tag=S_saved_tag+1'b1; S_d_I_host_epoch=S_expected;
        S_d_I_host_error=2; S_d_I_host_retired=1; S_d_I_host_done_valid=1;
        @(negedge S_host_clk); S_d_I_host_done_valid=0;
        repeat(15) @(negedge S_clk);
        if(S_d_O_done_valid || u_executor.S_hstate!=2) fail("wrong host identity discharged unique in-flight command");
        backend_done(2,0,1); result(2,0);

        S_case=7; reset_all; event_offer(11,0); backend_accept;
        @(negedge S_clk); S_d_I_pending_valid=1; S_d_I_pending_config=S_saved_config;
        S_d_I_pending_config[68]=!S_saved_config[68]; S_d_I_pending_epoch=S_expected; S_d_I_pending_tag=S_saved_tag;
        repeat(5) begin @(negedge S_clk); if(S_d_O_target_valid) fail("partial pending configuration acquired target authority"); end
        S_d_I_pending_config=S_saved_config; S_d_I_pending_tag=S_saved_tag+1'b1;
        repeat(5) begin @(negedge S_clk); if(S_d_O_target_valid) fail("wrong pending tag acquired target authority"); end
        pending_install; local_apply; backend_done(0,1,1); result(0,1);

        S_case=8; reset_all; event_offer(12,0); backend_accept; pending_install;
        @(negedge S_clk); S_d_I_active_epoch=S_expected; S_d_I_active_tag=S_saved_tag+1'b1;
        S_d_I_active_config=S_saved_config; S_d_I_local_applied=1;
        @(negedge S_clk); S_d_I_local_applied=0;
        backend_done(2,0,1); result(6,0);
        if(!S_d_O_quarantined) fail("unidentified apply fact did not isolate");

        S_case=9; reset_all; event_offer(13,0); backend_accept; pending_install; local_apply;
        S_d_I_host_retire_error=5; S_d_I_host_quarantined=1;
        backend_done(8,1,0); result(2,1);
        if(S_d_O_apply_time!==S_d_I_event_target || S_d_O_retire_error!=5 || S_d_O_backend_error!=8 ||
            !S_d_O_quarantined || S_d_O_retired) fail("post-apply retirement failure erased actual display or raw errors");

        S_case=10; reset_all; event_offer(14,0); backend_accept; backend_done(0,0,1); result(6,0);
        if(!S_d_O_quarantined) fail("success without applied escaped quarantine");

        S_case=11; reset_all; event_offer(15,0); backend_accept; pending_install;
        backend_done(0,1,1); result(6,0);
        if(!S_d_O_quarantined) fail("host applied flag replaced missing local timestamp proof");

        S_case=12; reset_all; event_offer(16,0); backend_accept; pending_install; local_apply;
        @(negedge S_clk); S_d_I_local_applied=1;
        @(negedge S_clk); S_d_I_local_applied=0;
        backend_done(0,1,1); result(6,1);
        if(S_d_O_apply_time!==S_d_I_event_target) fail("duplicate apply overwrote first irrevocable timestamp");

        S_case=13; reset_all; S_d_I_clock_enable=0; event_offer(17,0); result(4,0);
        if(S_host_commands!=0) fail("clock permission withdrawal started host work");

        S_case=14; reset_all; u_executor.S_sequence=32'hffffffff;
        event_offer(18,0); result(7,0);
        if(!S_d_O_quarantined || S_host_commands!=0) fail("sequence exhaustion wrapped or created work");

        S_case=15; reset_all; S_d_I_config[52]=1;
        event_offer(19,0); result(1,0);
        if(S_host_commands!=0) fail("fresh-proof bit was silently bypassed instead of rejecting contract");

        S_case=16; reset_all; event_offer(20,0); backend_accept; pending_install; local_apply;
        @(negedge S_clk); S_d_I_cancel=1;
        backend_done(0,1,1); result(3,1);
        if(S_d_O_apply_time!==S_d_I_event_target) fail("late cancel erased actual applied fact");

        S_case=17; reset_all; event_offer(21,0); backend_accept; pending_install;
        @(negedge S_clk); S_d_I_pending_epoch=S_expected+1'b1;
        repeat(4) @(negedge S_clk);
        if(!S_d_O_quarantined || S_d_O_target_valid) fail("pending commit epoch changed inside unique mapping");
        backend_done(2,0,1); result(6,0);

        S_case=18; reset_all; event_offer(22,0); backend_accept;
        @(negedge S_host_clk); S_host_run=0;
        @(negedge S_clk); S_d_I_cancel=1;
        repeat(30) begin @(negedge S_clk);
            if(S_d_O_done_valid || S_d_O_event_ready) fail("host stop timeout fabricated resource retirement"); end
        S_host_run=1; backend_done(3,0,1); result(3,0);
        $display("PASS: 18 executor protocol scenarios; real FIFOs, identity, irrevocable facts and cancellation clear");
        S_test_pass=1; $finish;
    end
endmodule
