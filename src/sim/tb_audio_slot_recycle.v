`timescale 1ns/1ps
// Protocol endpoints are driven explicitly; this is not a file/player integration.
module tb_audio_slot_recycle;
    reg S_decode_clk=0,S_audio_clk=0,S_audio_run=1;
    always #4 S_decode_clk=~S_decode_clk;
    always #20 if (S_audio_run) S_audio_clk=~S_audio_clk;
    reg S_reset=1,S_request=0,S_quiet=0,S_source_ready=1;
    reg S_io_retired=0,S_audio_idle=1;
    wire S_ready,S_available,S_done,S_abort,S_retire,S_stop,S_flush;
    reg S_test_pass=0,S_previous_flush=1;
    integer S_done_count=0,S_flush_count=0,S_flush_width=0;
    integer S_before;
    audio_slot_recycle u_dut (
        .I_decode_clk(S_decode_clk),.I_audio_clk(S_audio_clk),.I_async_reset(S_reset),
        .I_recycle_valid(S_request),.O_recycle_ready(S_ready),.O_available(S_available),
        .O_done(S_done),.I_source_quiescent(S_quiet),.I_source_start_ready(S_source_ready),
        .O_abort(S_abort),.O_io_retire_request(S_retire),.I_io_retired(S_io_retired),
        .O_audio_stop(S_stop),.I_audio_idle(S_audio_idle),.O_async_flush(S_flush));

    task fail;
        input [511:0] message;
        begin $display("FAIL: %0s",message); $stop; end
    endtask
    task cycles;
        input integer count;
        integer i;
        begin for(i=0;i<count;i=i+1) begin @(posedge S_decode_clk); #1; end end
    endtask
    task request_recycle;
        begin
            wait(S_ready); @(negedge S_decode_clk); S_request=1;
            @(negedge S_decode_clk); S_request=0;
            if (!S_abort || !S_retire || S_available) fail("request not held / slot open");
        end
    endtask
    task no_flush;
        begin cycles(20); if(S_flush || S_available || S_done) fail("premature flush/reuse"); end
    endtask
    task finish_recycle;
        begin
            wait(S_flush); wait(!S_flush); wait(!S_retire);
            // A file completion held high must prevent rearming.
            cycles(20); if(S_available || S_done) fail("retire ack not returned to zero");
            @(negedge S_decode_clk); S_io_retired=0;
            wait(S_done); #1;
            if (!S_available || S_stop) fail("done before ready/stop release");
            cycles(3);
        end
    endtask

    always @(posedge S_decode_clk) begin
        #1;
        if (S_reset) begin S_previous_flush=1; S_flush_width=0; end
        else begin
            if(S_done) S_done_count=S_done_count+1;
            if(S_flush) S_flush_width=S_flush_width+1;
            if(S_flush && !S_previous_flush) begin
                S_flush_count=S_flush_count+1;
                if(!S_quiet || !S_io_retired || !S_stop || !S_audio_idle)
                    fail("flush before independent retire conditions");
            end
            if(!S_flush && S_previous_flush) begin
                if(S_flush_width<4) fail("flush shorter than four decode clocks");
                S_flush_width=0;
            end
            if(S_available && (S_flush || S_retire || S_stop)) fail("available while retiring");
            S_previous_flush=S_flush;
        end
    end

    initial begin
        #101; S_reset=0;
        wait(S_available); cycles(3);
        if(S_done_count!=0) fail("startup reported recycle done");

        // Each prerequisite can independently delay retirement.
        @(negedge S_audio_clk); S_audio_idle=0;
        request_recycle;
        no_flush;
        @(negedge S_decode_clk); S_io_retired=1;
        no_flush;
        @(negedge S_audio_clk); S_audio_idle=1;
        no_flush;
        @(negedge S_decode_clk); S_quiet=1;
        finish_recycle;
        if(S_done_count!=1 || S_flush_count!=1) fail("first recycle event count");

        // A stopped audio domain cannot acknowledge a new request.
        @(negedge S_audio_clk); S_audio_run=0; S_audio_idle=0;
        @(negedge S_decode_clk); S_quiet=1;
        request_recycle;
        @(negedge S_decode_clk); S_io_retired=1; S_audio_idle=1;
        no_flush;
        S_audio_run=1;
        finish_recycle;
        if(S_done_count!=2 || S_flush_count!=2) fail("stopped reader event count");

        // Flush asserts asynchronously while audio is stopped; recovery waits.
        request_recycle;
        wait(S_stop); no_flush;
        @(negedge S_audio_clk); S_audio_run=0;
        @(negedge S_decode_clk); S_io_retired=1; S_source_ready=0;
        wait(S_flush); wait(!S_flush); cycles(30);
        if(S_available || !S_retire || !S_stop) fail("recovered without audio clock");
        S_audio_run=1; cycles(30);
        if(S_available || !S_retire) fail("ignored source reset recovery");
        @(negedge S_decode_clk); S_source_ready=1;
        wait(!S_retire);
        @(negedge S_decode_clk); S_io_retired=0;
        wait(S_done); cycles(3);
        if(S_done_count!=3 || S_flush_count!=3) fail("recovery event count");

        // Explicit global reset is the sole forced-discard escape.
        @(negedge S_decode_clk); S_quiet=0;
        request_recycle; no_flush; S_before=S_done_count;
        #3; S_reset=1; S_io_retired=0;
        #1; if(!S_flush) fail("global reset did not assert flush");
        cycles(10); @(negedge S_decode_clk); S_reset=0;
        wait(S_available); cycles(10);
        if(S_done_count!=S_before) fail("reset replayed pending completion");
        S_test_pass=1; $display("PASS: audio_slot_recycle"); $finish;
    end
    initial begin #200000; fail("watchdog timeout"); end
endmodule
