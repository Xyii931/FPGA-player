`timescale 1ns/1ps
// Real stop bridge and real slot recyclers. File/reader retirement are explicit peers.
module tb_audio_stop_cdc;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=1;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reg S_request=0;
    wire S_ack,S_video_busy,S_host_busy;
    wire [1:0] S_valid,S_ready,S_done,S_available,S_retire,S_stop,S_flush;
    reg [1:0] S_quiet=3,S_idle=3,S_io_allow=0,S_io_retired=0,S_stale_done=0;
    wire [1:0] S_bridge_done=S_done | S_stale_done;
    wire [1:0] S_abort;
    integer S_accept_a=0,S_accept_b=0,S_before_a,S_before_b;
    reg S_test_pass=0;
    audio_stop_cdc u_stop (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_stop_request(S_request),.O_stop_ack(S_ack),.O_video_busy(S_video_busy),.O_host_busy(S_host_busy),
        .O_recycle_valid(S_valid),.I_recycle_ready(S_ready),.I_recycle_done(S_bridge_done),.I_available(S_available));
    audio_slot_recycle u_a (
        .I_decode_clk(S_host_clk),.I_audio_clk(S_video_clk),.I_async_reset(S_reset),
        .I_recycle_valid(S_valid[0]),.O_recycle_ready(S_ready[0]),.O_available(S_available[0]),.O_done(S_done[0]),
        .I_source_quiescent(S_quiet[0]),.I_source_start_ready(1'b1),.O_abort(S_abort[0]),
        .O_io_retire_request(S_retire[0]),.I_io_retired(S_io_retired[0]),
        .O_audio_stop(S_stop[0]),.I_audio_idle(S_idle[0]),.O_async_flush(S_flush[0]));
    audio_slot_recycle u_b (
        .I_decode_clk(S_host_clk),.I_audio_clk(S_video_clk),.I_async_reset(S_reset),
        .I_recycle_valid(S_valid[1]),.O_recycle_ready(S_ready[1]),.O_available(S_available[1]),.O_done(S_done[1]),
        .I_source_quiescent(S_quiet[1]),.I_source_start_ready(1'b1),.O_abort(S_abort[1]),
        .O_io_retire_request(S_retire[1]),.I_io_retired(S_io_retired[1]),
        .O_audio_stop(S_stop[1]),.I_audio_idle(S_idle[1]),.O_async_flush(S_flush[1]));
    task fail;
        input [511:0] message;
        begin $display("FAIL audio_stop_cdc: %0s",message); $finish; end
    endtask
    task video_cycles;
        input integer count;
        integer k;
        begin for(k=0;k<count;k=k+1) @(negedge S_video_clk); end
    endtask
    task finish_stop;
        begin
            wait(S_ack); #1;
            if(S_available!==3 || S_retire!==0 || S_io_retired!==0 || S_stop!==0)
                fail("ack before real two-slot retirement and rearm");
            video_cycles(6);
            if(!S_ack || !S_video_busy) fail("held request lost acknowledgement");
            S_request=0; wait(!S_ack); wait(!S_video_busy && !S_host_busy);
            video_cycles(3);
        end
    endtask
    always @(posedge S_host_clk) begin
        if(S_reset) S_io_retired<=0;
        else begin
            // A four-phase file peer; do not create retirement on cancel acceptance.
            S_io_retired<=S_retire & S_io_allow;
            if(S_valid[0] && S_ready[0]) S_accept_a=S_accept_a+1;
            if(S_valid[1] && S_ready[1]) S_accept_b=S_accept_b+1;
            if(S_ack && (S_available!=3 || S_retire!=0)) fail("unsafe ack");
        end
    end
    initial begin
        #101; S_reset=0; wait(S_available==3); video_cycles(4);
        // A stale done at admission must not retire the newly accepted recycle.
        @(negedge S_video_clk); S_quiet=0; S_idle=0; S_request=1;
        wait(S_valid==3);
        @(negedge S_host_clk); S_stale_done=3;
        @(negedge S_host_clk); S_stale_done=0;
        video_cycles(16);
        if(S_ack || S_available!=0 || S_retire!=3) fail("stale done / pending files accepted as complete");
        @(negedge S_host_clk); S_io_allow=1;
        video_cycles(12); if(S_ack) fail("file retirement substituted for source/reader idle");
        S_quiet=3; video_cycles(12); if(S_ack) fail("source quiescent substituted for reader idle");
        S_io_allow=3; video_cycles(12); if(S_ack) fail("both files substituted for reader idle");
        S_idle=1; video_cycles(16); if(S_ack) fail("only one slot retired");
        S_idle=3; finish_stop;
        if(S_accept_a!=1 || S_accept_b!=1) fail("duplicate slot admission");
        // Stop the actual audio clock; neither its recycler nor bridge can invent ack.
        @(negedge S_video_clk); S_request=1;
        wait(S_valid!=0); @(negedge S_video_clk); S_video_run=0;
        repeat(60) @(negedge S_host_clk);
        if(S_ack || !S_host_busy) fail("stopped video acknowledged");
        S_video_run=1; finish_stop;
        if(S_accept_a!=2 || S_accept_b!=2) fail("stopped video duplicate recycle");
        // A short request is retained even if the host clock is stopped.
        @(negedge S_host_clk); S_host_run=0;
        @(negedge S_video_clk); S_request=1;
        @(negedge S_video_clk); S_request=0;
        video_cycles(12); if(S_ack || !S_video_busy) fail("host stop lost/acknowledged pending request");
        S_host_run=1;
        wait(S_ack); wait(!S_ack); wait(!S_video_busy && !S_host_busy);
        video_cycles(4);
        if(S_accept_a!=3 || S_accept_b!=3) fail("early withdrawal lost actual recycle");
        // Global reset is the only forced discard; pending request must not replay.
        @(negedge S_video_clk); S_quiet=0; S_request=1;
        wait(S_retire==3); S_before_a=S_accept_a; S_before_b=S_accept_b;
        #3; S_reset=1; S_request=0; S_io_allow=0;
        video_cycles(5); S_reset=0; S_quiet=3;
        wait(S_available==3); video_cycles(12);
        if(S_ack || S_video_busy || S_host_busy || S_accept_a!=S_before_a || S_accept_b!=S_before_b)
            fail("global reset replayed pending stop");
        S_test_pass=1; $display("PASS audio_stop_cdc with real two-slot recyclers; retirement peers are fixtures"); $finish;
    end
    initial begin #1000000; fail("timeout"); end
endmodule
