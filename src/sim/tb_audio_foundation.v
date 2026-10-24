`timescale 1ns/1ps
module tb_audio_foundation;
    reg S_clk=0, S_reset=0;
    wire S_tick, S_cv, S_mv, S_co, S_mo, S_overflow_done, S_pcm_done;
    wire [19:0] S_cn, S_cc, S_mn, S_mc;
    reg S_test_pass=0;
    integer S_cycle, S_events, S_anchor, S_gap, S_last_tick, S_packets;
    integer S_expected_cts;
    reg S_expected_cv, S_expected_mv;
    reg S_consumed_tick;
    reg [63:0] S_product, S_previous_product;
    always #20 S_clk=~S_clk;
    samp_tick u_tick(.I_clk(S_clk),.I_reset(S_reset),.O_sample_tick(S_tick));
    acr_gen u_constant(.I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),
        .O_acr_valid(S_cv),.O_acr_n(S_cn),.O_acr_cts(S_cc),.O_measure_overflow(S_co));
    acr_gen #(.MEASURE_MODE(1)) u_measure (
        .I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),
        .O_acr_valid(S_mv),.O_acr_n(S_mn),.O_acr_cts(S_mc),.O_measure_overflow(S_mo));
    acr_overflow_case u_overflow(S_overflow_done);
    pcm_conversion_case u_pcm(S_pcm_done);
    task run_epoch;
        input integer cycles;
        begin
            S_events=0; S_anchor=0; S_last_tick=0; S_packets=0;
            for (S_cycle=1; S_cycle<=cycles; S_cycle=S_cycle+1) begin
                @(posedge S_clk);
                // ACR consumes the PRE-edge tick; check output after NBA updates.
                S_consumed_tick=S_tick;
                S_expected_cv=0; S_expected_mv=0;
                if (S_consumed_tick) begin
                    S_events=S_events+1;
                    if (S_events%48==0) begin
                        S_expected_cv=1; S_packets=S_packets+1;
                        if (S_anchor!=0) begin
                            S_expected_mv=1;
                            S_expected_cts=S_cycle-S_anchor;
                        end
                        S_anchor=S_cycle;
                    end
                end
                #1;
                // Independent closed-form carry count, not DUT accumulator state.
                S_product=S_cycle*64'd8246337;
                S_previous_product=(S_cycle-1)*64'd8246337;
                if (S_tick !== ((S_product>>32)!=(S_previous_product>>32))) begin
                    $display("FAIL: sample carry at edge %0d",S_cycle); $stop;
                end
                if (S_tick) begin
                    if (S_last_tick==0 && S_cycle!=521) begin
                        $display("FAIL: first sample phase"); $stop;
                    end
                    if (S_last_tick!=0) begin
                        S_gap=S_cycle-S_last_tick;
                        if (S_gap!=520 && S_gap!=521) begin
                            $display("FAIL: sample spacing %0d",S_gap); $stop;
                        end
                    end
                    S_last_tick=S_cycle;
                end
                if (S_cv !== S_expected_cv || S_mv !== S_expected_mv || S_co || S_mo) begin
                    $display("FAIL: ACR cadence at edge %0d",S_cycle); $stop;
                end
                if (S_cv && (S_cn!=6144 || S_cc!=25000)) begin
                    $display("FAIL: constant N/CTS"); $stop;
                end
                if (S_mv && (S_mn!=6144 || S_mc!=S_expected_cts || S_mc<24999 || S_mc>25001)) begin
                    $display("FAIL: measured CTS expected=%0d actual=%0d",S_expected_cts,S_mc); $stop;
                end
            end
            if (cycles>=250000 && S_packets<9) begin
                $display("FAIL: incomplete ACR coverage"); $stop;
            end
        end
    endtask
    initial begin
        #1; S_reset=1;
        #1;
        if ({S_tick,S_cv,S_mv,S_co,S_mo,S_cn,S_cc,S_mn,S_mc} !== 85'd0) begin
            $display("FAIL: audio reset outputs"); $stop;
        end
        repeat (2) @(negedge S_clk);
        S_reset=0;
        run_epoch(250000);
        // Partial ACR window must be forgotten and phase restarted by video reset.
        @(negedge S_clk); S_reset=1;
        repeat (2) @(negedge S_clk);
        S_reset=0;
        run_epoch(60000);
        wait (S_overflow_done && S_pcm_done);
        S_test_pass=1;
        $display("PASS: sample phase/cadence, ACR modes/overflow, exhaustive PCM with backpressure");
        $finish;
    end
    initial begin
        #100000000;
        $display("FAIL: audio foundation timeout"); $stop;
    end
endmodule

// N=128 makes every supplied sample event a boundary, allowing exact edge tests.
module acr_overflow_case(output reg O_done);
    reg S_clk=0, S_reset=0, S_tick=0;
    wire S_valid, S_overflow;
    wire [19:0] S_n,S_cts;
    always #4 S_clk=~S_clk;
    acr_gen #(.MEASURE_MODE(1),.ACR_N(20'd128)) u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),
        .O_acr_valid(S_valid),.O_acr_n(S_n),.O_acr_cts(S_cts),.O_measure_overflow(S_overflow));
    task boundary;
        input integer distance;
        input expected_valid;
        input integer expected_cts;
        begin
            // Called on a falling edge immediately after previous boundary.
            S_tick=0;
            repeat (distance-1) @(negedge S_clk);
            S_tick=1;
            @(posedge S_clk); #1;
            if (S_valid !== expected_valid || (S_valid && (S_n!=128 || S_cts!=expected_cts))) begin
                $display("FAIL: measured interval distance=%0d CTS=%0d valid=%b",distance,S_cts,S_valid); $stop;
            end
            @(negedge S_clk);
        end
    endtask
    initial begin
        O_done=0;
        #1; S_reset=1;
        repeat (2) @(negedge S_clk);
        S_reset=0; S_tick=1;
        @(posedge S_clk); #1;
        if (S_valid || S_overflow) begin $display("FAIL: incomplete first measurement"); $stop; end
        @(negedge S_clk);
        boundary(1,1,1);
        boundary(37,1,37);
        boundary(1048575,1,1048575);
        if (S_overflow) begin $display("FAIL: false measurement overflow"); $stop; end
        boundary(1048576,0,0);
        if (!S_overflow) begin $display("FAIL: lost measurement overflow"); $stop; end
        boundary(5,1,5);
        if (!S_overflow) begin $display("FAIL: overflow history cleared"); $stop; end
        S_reset=1;
        #1;
        if (S_valid || S_overflow || S_n!=0 || S_cts!=0) begin
            $display("FAIL: measurement reset"); $stop;
        end
        O_done=1;
    end
endmodule

module pcm_conversion_case(output reg O_done);
    reg S_clk=0,S_reset=0,S_valid=0,S_ready=0;
    wire S_in_ready,S_out_valid,S_last;
    reg [15:0] S_left=0,S_right=0;
    reg [31:0] S_index=0;
    reg S_in_last=0;
    wire [23:0] S_out_left,S_out_right;
    wire [31:0] S_out_index;
    integer S_sent=0,S_received=0,S_cycle=0;
    reg S_stalled=0;
    reg [80:0] S_saved;
    reg S_pending=0;
    reg S_input_taken=0;
    reg [15:0] S_expected_left,S_expected_right;
    reg [31:0] S_expected_index;
    reg S_expected_last;
    always #4 S_clk=~S_clk;
    pcm16_to_pcm24 u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_valid(S_valid),.O_ready(S_in_ready),
        .I_left(S_left),.I_right(S_right),.I_sample_index(S_index),.I_last(S_in_last),
        .O_valid(S_out_valid),.I_ready(S_ready),.O_left(S_out_left),.O_right(S_out_right),
        .O_sample_index(S_out_index),.O_last(S_last));
    always @(posedge S_clk) begin
        if (S_reset) begin S_pending=0; S_stalled=0; S_input_taken=0; end
        else if (!O_done) begin
            S_input_taken=S_valid && S_in_ready;
            if (S_stalled && (!S_out_valid || {S_out_left,S_out_right,S_out_index,S_last} !== S_saved)) begin
                $display("FAIL: PCM held payload"); $stop;
            end
            S_stalled=S_out_valid && !S_ready;
            S_saved={S_out_left,S_out_right,S_out_index,S_last};
            if (S_out_valid && S_ready) begin
                if (!S_pending || $signed(S_out_left)!=$signed(S_expected_left)*32'sd256 ||
                    $signed(S_out_right)!=$signed(S_expected_right)*32'sd256 ||
                    S_out_index!==S_expected_index || S_last!==S_expected_last) begin
                    $display("FAIL: PCM result at received=%0d",S_received); $stop;
                end
                S_pending=0; S_received=S_received+1;
            end
            if (S_valid && S_in_ready) begin
                if (S_pending) begin $display("FAIL: PCM register overwrite"); $stop; end
                S_pending=1;
                S_expected_left=S_left; S_expected_right=S_right;
                S_expected_index=S_index; S_expected_last=S_in_last;
                S_sent=S_sent+1;
            end
        end
    end
    initial begin
        O_done=0;
        #1; S_reset=1;
        repeat (2) @(negedge S_clk);
        S_reset=0;
        // Every signed 16-bit code in each channel; opposite channel bit patterns.
        while (S_received<65536) begin
            @(negedge S_clk);
            S_cycle=S_cycle+1;
            S_ready=(S_cycle%31>=10);
            if (!S_valid || S_input_taken) begin
                S_valid=S_sent<65536;
                S_left=S_sent; S_right=~S_sent;
                S_index=32'hffff0000+S_sent;
                S_in_last=S_sent==65535;
            end
        end
        @(negedge S_clk); S_valid=0; S_ready=0;
        // An occupied elastic slot is discarded by reset while blocked.
        S_left=16'h8000; S_right=16'h7fff; S_index=123; S_in_last=1; S_valid=1;
        @(posedge S_clk);
        @(negedge S_clk); S_valid=0;
        if (!S_out_valid || S_in_ready) begin $display("FAIL: PCM stall setup"); $stop; end
        #1; S_reset=1;
        #1;
        if (S_out_valid || S_in_ready || S_out_left!=0 || S_out_right!=0) begin
            $display("FAIL: PCM reset cancellation"); $stop;
        end
        repeat (2) @(negedge S_clk);
        S_reset=0; S_valid=1; S_ready=1;
        S_left=1; S_right=16'hffff; S_index=7; S_in_last=1;
        @(posedge S_clk);
        @(negedge S_clk); S_valid=0;
        @(posedge S_clk);
        #1; O_done=1;
    end
endmodule
