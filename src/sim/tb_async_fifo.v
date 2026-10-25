`timescale 1ns/1ps
module tb_async_fifo;
    wire [9:0] S_done;
    reg S_test_pass=0;
    async_fifo_case #(2,3,13) u_min(S_done[0]);
    async_fifo_case #(4,13,3) u_fast_reader(S_done[1]);
    async_fifo_case #(4,5,5) u_equal_clocks(S_done[2]);
    async_fifo_case #(11,4,20) u_audio_depth(S_done[3]);
    // Retain all inferred cases and independently score the explicit 32K path.
    // The full-depth case matches one production stereo payload FIFO exactly.
    async_fifo_case #(2,3,13,48,1) u_bram_min(S_done[4]);
    async_fifo_case #(4,13,3,48,1) u_bram_fast_reader(S_done[5]);
    async_fifo_case #(4,5,5,48,1) u_bram_equal_clocks(S_done[6]);
    async_fifo_case #(11,4,20,48,1) u_bram_audio_depth(S_done[7]);
    // Production control payload widths: 375-bit requests and 434-bit results.
    async_fifo_case #(2,4,20,375,0) u_control_request(S_done[8]);
    async_fifo_case #(2,20,4,434,0) u_control_result(S_done[9]);
    initial begin
        wait (&S_done);
        S_test_pass=1;
        $display("PASS: inferred/32K async FIFO order, capacity, wrap, CDC rates, stalls and stopped-clock flush");
        $finish;
    end
    initial begin
        #10000000;
        $display("FAIL: async FIFO timeout"); $stop;
    end
endmodule

module async_fifo_case #(
    parameter integer ADDR=4, WRITE_HALF=4, READ_HALF=20,
    parameter integer DATA_BITS=32, USE_BRAM32K=0
) (output reg O_done);
    localparam integer DEPTH=2**ADDR;
    reg S_write_clk=0,S_read_clk=0,S_run_read=1,S_run_write=1,S_reset=0;
    reg S_write_valid=0,S_read_ready=0;
    reg [DATA_BITS-1:0] S_write_data=0;
    wire S_write_ready,S_read_valid,S_full,S_empty;
    wire [DATA_BITS-1:0] S_read_data;
    wire [ADDR:0] S_write_level,S_read_level;
    reg [DATA_BITS-1:0] S_expected[0:DEPTH-1];
    integer S_head=0,S_tail=0,S_sent=0,S_received=0;
    integer S_phase=0,S_wcycle=0,S_rcycle=0,S_epoch=0;
    integer S_saved_tail,S_saved_head,S_c;
    reg S_input_taken=0,S_output_stalled=0;
    reg [DATA_BITS-1:0] S_held_data;
    reg [15:0] S_wrng=16'hbabe,S_rrng=16'h1234;
    always #(WRITE_HALF) if (S_run_write) S_write_clk=~S_write_clk;
    // Nonzero initial phase also exercises unrelated clock-edge alignment.
    initial begin
        #1;
        forever begin #(READ_HALF); if (S_run_read) S_read_clk=~S_read_clk; end
    end
    async_fifo #(.DATA_BITS(DATA_BITS),.ADDR_BITS(ADDR),.USE_BRAM32K(USE_BRAM32K)) u_dut (
        .I_write_clk(S_write_clk),.I_read_clk(S_read_clk),.I_async_reset(S_reset),
        .I_write_valid(S_write_valid),.O_write_ready(S_write_ready),.I_write_data(S_write_data),
        .O_write_full(S_full),.O_write_level(S_write_level),
        .O_read_valid(S_read_valid),.I_read_ready(S_read_ready),.O_read_data(S_read_data),
        .O_read_empty(S_empty),.O_read_level(S_read_level));
    function [DATA_BITS-1:0] payload;
        input integer index,epoch;
        integer lane;
        begin
            // Cover non-byte-aligned high bits as well as all complete bytes.
            for (lane=0;lane<DATA_BITS;lane=lane+1)
                payload[lane]=((index*(73+2*(lane/8))+(index/256)*29+epoch*37+(lane/8)*53) >> (lane%8)) & 1;
        end
    endfunction
    always @(posedge S_reset) begin
        S_head=0; S_tail=0; S_sent=0; S_received=0;
    end
    always @(posedge S_write_clk or posedge S_reset) begin
        if (S_reset) S_input_taken=0;
        else if (!O_done) begin
            S_input_taken=S_write_valid && S_write_ready;
            if (S_input_taken) begin
                if (S_tail-S_head>=DEPTH) begin $display("FAIL in %m: over-capacity write"); $stop; end
                S_expected[S_tail%DEPTH]=S_write_data;
                S_tail=S_tail+1; S_sent=S_sent+1;
            end
            #0.001;
            if (S_write_level>DEPTH || (S_full && S_write_ready)) begin
                $display("FAIL in %m: write status range/full handshake"); $stop;
            end
        end
    end
    always @(posedge S_read_clk or posedge S_reset) begin
        if (S_reset) S_output_stalled=0;
        else if (!O_done) begin
            if (S_output_stalled && (!S_read_valid || S_read_data!==S_held_data)) begin
                $display("FAIL in %m: held read changed"); $stop;
            end
            if (S_empty !== !S_read_valid) begin $display("FAIL in %m: read empty/valid"); $stop; end
            S_output_stalled=S_read_valid && !S_read_ready;
            S_held_data=S_read_data;
            if (S_read_valid && S_read_ready) begin
                if (S_head==S_tail || S_read_data!==S_expected[S_head%DEPTH]) begin
                    $display("FAIL in %m: read order head=%0d tail=%0d data=%h",S_head,S_tail,S_read_data); $stop;
                end
                S_head=S_head+1; S_received=S_received+1;
            end
            #0.001;
            if (S_read_level>DEPTH) begin $display("FAIL in %m: read level out of range"); $stop; end
        end
    end
    always @(negedge S_write_clk or posedge S_reset) begin
        if (S_reset) begin S_write_valid=0; S_wcycle=0; end
        else if (!O_done) begin
            S_wcycle=S_wcycle+1;
            S_wrng={S_wrng[14:0],S_wrng[15]^S_wrng[13]^S_wrng[12]^S_wrng[10]};
            // Once valid is raised, retain it and its payload until accepted/reset.
            if (!S_write_valid || S_input_taken) begin
                S_write_valid=(S_phase==1 || S_phase==2) && (S_phase==1 || S_wrng[0]);
                S_write_data=payload(S_sent,S_epoch);
            end
        end
    end
    always @(negedge S_read_clk or posedge S_reset) begin
        if (S_reset) begin S_read_ready=0; S_rcycle=0; end
        else if (!O_done) begin
            S_rcycle=S_rcycle+1;
            S_rrng={S_rrng[14:0],S_rrng[15]^S_rrng[13]^S_rrng[12]^S_rrng[10]};
            S_read_ready=(S_phase==3) || (S_phase==2 && S_rcycle%31>=9 && S_rrng[0]);
        end
    end
    task wait_settle;
        begin
            repeat (8) @(posedge S_write_clk);
            repeat (8) @(posedge S_read_clk);
            #1;
        end
    endtask
    task drain;
        begin
            S_phase=3;
            // Permit a producer word already held at full to complete, then stop.
            repeat (8) @(posedge S_write_clk);
            wait (S_head==S_tail && !S_write_valid);
            wait_settle;
            if (!S_empty || S_read_valid || S_read_level!=0 || S_write_level!=0 || S_full) begin
                $display("FAIL in %m: drain did not reach empty"); $stop;
            end
        end
    endtask
    initial begin
        O_done=0;
        // Native mode has an independent global startup model. Initialize RAM
        // only through real writes after it releases, never through RAM reset.
        #100;
        #1; S_reset=1;
        #1;
        if (S_write_ready || S_read_valid) begin $display("FAIL in %m: reset interfaces"); $stop; end
        repeat (3) @(negedge S_write_clk);
        S_reset=0;
        wait_settle;
        if (!S_empty || S_read_level!=0 || S_write_level!=0 || !S_write_ready) begin
            $display("FAIL in %m: empty startup"); $stop;
        end
        S_phase=1;
        wait (S_full);
        wait_settle;
        if (S_tail-S_head!=DEPTH || S_write_level!=DEPTH || S_read_level!=DEPTH) begin
            $display("FAIL in %m: exact capacity incl prefetched head"); $stop;
        end
        S_saved_tail=S_tail;
        repeat (20) @(posedge S_write_clk);
        if (S_tail!=S_saved_tail) begin $display("FAIL in %m: full overwrite"); $stop; end
        S_phase=2;
        wait (S_received>=8*DEPTH);
        drain;
        // Empty reads cannot replay stale RAM contents as valid frames.
        S_saved_head=S_head;
        repeat (20) @(posedge S_read_clk);
        if (S_head!=S_saved_head || S_read_valid) begin $display("FAIL in %m: empty read"); $stop; end
        S_phase=1;
        wait (S_full);
        wait_settle;
        // Stop the reader while a head is valid and reset BOTH pointers.
        @(negedge S_read_clk); S_run_read=0;
        #1; S_reset=1; S_phase=0; S_epoch=S_epoch+1;
        #1;
        if (S_write_ready || S_read_valid) begin $display("FAIL in %m: stopped-clock flush"); $stop; end
        repeat (3) @(negedge S_write_clk);
        S_reset=0; S_phase=1;
        wait (S_full);
        if (S_read_valid || S_tail!=DEPTH) begin $display("FAIL in %m: fill with reader stopped"); $stop; end
        S_run_read=1;
        wait_settle;
        drain;
        // Conversely the reader remains safe if writer clock stops during reset.
        @(negedge S_write_clk); S_run_write=0;
        #1; S_reset=1; S_phase=0; S_epoch=S_epoch+1;
        repeat (3) @(negedge S_read_clk);
        S_reset=0;
        repeat (10) @(posedge S_read_clk);
        #1;
        if (S_read_valid || S_write_ready) begin $display("FAIL in %m: writer-stopped reset release"); $stop; end
        S_run_write=1;
        wait_settle;
        S_phase=1;
        wait (S_full);
        drain;
        O_done=1;
    end
endmodule
