`timescale 1ns/1ps
module tb_audio_track_guard;
    reg S_clk=0,S_reset=0,S_tick=0,S_enable=1;
    reg S_valid=0,S_prefilled=0,S_tail_ready=0,S_end=0;
    reg [23:0] S_left=0,S_right=0;
    wire S_ready,S_sample_valid,S_consumed,S_underrun;
    wire S_waiting,S_running,S_fading;
    wire [23:0] S_out_left,S_out_right;
    integer S_checks=0,S_consumptions=0,S_underflows=0,S_i;
    reg [23:0] S_anchor_left,S_anchor_right;
    reg S_test_pass=0;
    always #20 S_clk=~S_clk;
    audio_track_guard u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),.I_enable(S_enable),
        .I_valid(S_valid),.O_ready(S_ready),.I_left(S_left),.I_right(S_right),
        .I_prefilled(S_prefilled),.I_tail_ready(S_tail_ready),.I_end(S_end),
        .O_sample_valid(S_sample_valid),.O_left(S_out_left),.O_right(S_out_right),
        .O_consumed(S_consumed),.O_underrun(S_underrun),
        .O_waiting(S_waiting),.O_running(S_running),.O_fading(S_fading));

    // Independent arithmetic reference: signed division, explicitly floor negatives.
    function [23:0] reference;
        input [23:0] value;
        input integer gain;
        reg signed [63:0] wide;
        begin
            wide=$signed(value);
            wide=wide*gain;
            if (wide<0) wide=-((-wide+63)/64);
            else wide=wide/64;
            reference=wide[23:0];
        end
    endfunction
    task pulse;
        input [23:0] expected_left,expected_right;
        input consumed,underrun;
        begin
            @(negedge S_clk); S_tick=1;
            #1;
            if ((S_ready && S_valid) !== consumed) begin
                $display("FAIL: guard input handshake at check %0d",S_checks); $stop;
            end
            @(posedge S_clk); #1;
            if (!S_sample_valid || S_out_left!==expected_left || S_out_right!==expected_right ||
                S_consumed!==consumed || S_underrun!==underrun) begin
                $display("FAIL: guard check %0d L/R=%h/%h expected=%h/%h consume=%b und=%b",
                    S_checks,S_out_left,S_out_right,expected_left,expected_right,S_consumed,S_underrun); $stop;
            end
            S_checks=S_checks+1;
            if (consumed) S_consumptions=S_consumptions+1;
            if (underrun) S_underflows=S_underflows+1;
            @(negedge S_clk); S_tick=0;
            @(posedge S_clk); #1;
            if (S_sample_valid || S_consumed || S_underrun || S_ready ||
                S_out_left!==expected_left || S_out_right!==expected_right) begin
                $display("FAIL: guard changed/consumed outside sample tick"); $stop;
            end
        end
    endtask
    task fade;
        input [23:0] anchor_left,anchor_right;
        input underrun,full_refill;
        integer remaining;
        begin
            S_valid=0; S_prefilled=0;
            for (remaining=63; remaining>=0; remaining=remaining-1) begin
                pulse(reference(anchor_left,remaining),reference(anchor_right,remaining),
                    0,underrun && remaining==63);
                if (remaining>0 && !S_fading) begin
                    $display("FAIL: guard fade ended early"); $stop;
                end
                // A refill returns immediately but is retained, not consumed.
                // EOF has no returning data. Never withdraw a stalled valid frame.
                S_valid=underrun;
                S_prefilled=underrun && full_refill;
            end
            if (!S_waiting || S_out_left!=0 || S_out_right!=0) begin
                $display("FAIL: guard fade endpoint/state"); $stop;
            end
        end
    endtask
    task reset_guard;
        begin
            S_tick=0; S_valid=0; S_prefilled=0; S_tail_ready=0; S_end=0; S_enable=1;
            #2; S_reset=1; #1;
            if (S_ready || S_sample_valid || S_consumed || S_underrun ||
                S_out_left!=0 || S_out_right!=0 || !S_waiting) begin
                $display("FAIL: guard asynchronous reset"); $stop;
            end
            @(negedge S_clk); S_reset=0;
        end
    endtask
    initial begin
        reset_guard;
        // Empty startup and partial prefill are not starvation events.
        repeat (4) pulse(0,0,0,0);
        S_valid=1; S_left=24'h7fffff; S_right=24'h800000;
        repeat (4) pulse(0,0,0,0);
        S_prefilled=1;
        for (S_i=1; S_i<=64; S_i=S_i+1)
            pulse(reference(S_left,S_i),reference(S_right,S_i),1,0);
        if (!S_running) begin $display("FAIL: guard did not start"); $stop; end
        // Unity endpoint and fresh varying samples; exact negative rounding near zero.
        S_left=24'hffffff; S_right=24'h000001; pulse(S_left,S_right,1,0);
        S_left=24'h800001; S_right=24'h7ffffe; pulse(S_left,S_right,1,0);
        fade(S_left,S_right,1,0);
        repeat (8) pulse(0,0,0,0);
        // Recovery requires a new prefill, and restarts from 1/64, not unity.
        S_prefilled=1;
        for (S_i=1; S_i<=7; S_i=S_i+1)
            pulse(reference(S_left,S_i),reference(S_right,S_i),1,0);
        S_anchor_left=reference(S_left,7); S_anchor_right=reference(S_right,7);
        fade(S_anchor_left,S_anchor_right,1,1);
        // A different track must explicitly clear the pending refill/context.
        reset_guard;
        // Short final data can start below the normal prefill threshold.
        S_valid=1; S_prefilled=0; S_tail_ready=1; S_end=0;
        S_left=24'hffffff; S_right=24'h000001;
        pulse(reference(S_left,1),reference(S_right,1),1,0);
        S_anchor_left=reference(S_left,1); S_anchor_right=reference(S_right,1);
        S_end=1;
        fade(S_anchor_left,S_anchor_right,0,0);
        S_valid=0; S_tail_ready=0;
        repeat (3) pulse(0,0,0,0);
        // Revoking permission fades without reading even when a frame is valid.
        S_end=0; S_valid=1; S_prefilled=1;
        S_left=24'h400000; S_right=24'hc00000;
        pulse(reference(S_left,1),reference(S_right,1),1,0);
        S_enable=0;
        for (S_i=63; S_i>=0; S_i=S_i-1)
            pulse(reference(reference(S_left,1),S_i),reference(reference(S_right,1),S_i),0,0);
        repeat (3) pulse(0,0,0,0);
        // Restart the track and reset during a nonzero fade.
        reset_guard;
        S_valid=1; S_prefilled=1; S_left=24'h7fffff; S_right=24'h800000;
        pulse(reference(S_left,1),reference(S_right,1),1,0);
        S_valid=0;
        pulse(reference(reference(S_left,1),63),reference(reference(S_right,1),63),0,1);
        reset_guard;
        repeat (4) pulse(0,0,0,0);
        if (S_underflows!=3 || S_consumptions!=76) begin
            $display("FAIL: guard event totals consumed=%0d underruns=%0d",S_consumptions,S_underflows); $stop;
        end
        S_test_pass=1;
        $display("PASS: guard prefill, 64-sample fade, recovery, short tail, EOF and reset (%0d checks)",S_checks);
        $finish;
    end
    initial begin
        #1000000;
        $display("FAIL: audio track guard timeout"); $stop;
    end
endmodule
