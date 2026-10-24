`timescale 1ns/1ps
module tb_clk_monitor;
    wire [3:0] S_done;
    reg S_test_pass = 1'b0;
    clk_monitor_case #(5, 32, 8) u_100m(S_done[0]);
    clk_monitor_case #(4, 32, 8) u_125m(S_done[1]);
    clk_monitor_case #(20, 32, 8) u_25m(S_done[2]);
    // Also exercise production 1ms windows and 20-bit counter, not just scaled tests.
    clk_monitor_case #(5, 50000, 20) u_default(S_done[3]);
    initial begin
        wait (&S_done);
        S_test_pass = 1'b1;
        $display("PASS: clk_monitor rates, wrap, stop/restart, clear and reset");
        $finish;
    end
    initial begin
        #100000000;
        $display("FAIL: clk_monitor timeout"); $stop;
    end
endmodule

module clk_monitor_case #(
    parameter integer HALF_PERIOD = 5, WINDOW = 32, BITS = 8
) (output reg O_done);
    reg S_ref = 1'b0;
    reg S_mon = 1'b0;
    reg S_run = 1'b1;
    reg S_reset = 1'b0;
    reg S_clear = 1'b0;
    wire S_valid, S_lost, S_sticky;
    wire [BITS-1:0] S_count;
    integer S_i;
    integer S_ref_edges = 0;
    localparam EXPECTED = WINDOW * 20 / (2 * HALF_PERIOD);
    always #10 S_ref = ~S_ref;
    always #(HALF_PERIOD) if (S_run) S_mon = ~S_mon;
    clk_monitor #(.COUNTER_BITS(BITS), .WINDOW_CYCLES(WINDOW)) u_dut (
        .I_clk_50m(S_ref), .I_clk_mon(S_mon), .I_reset(S_reset), .I_clear(S_clear),
        .O_sample_valid(S_valid), .O_edge_count(S_count),
        .O_clock_lost(S_lost), .O_clock_lost_sticky(S_sticky)
    );
    // Independent cadence checker: first window is baseline only.
    always @(posedge S_ref or posedge S_reset) begin
        if (S_reset) S_ref_edges = 0;
        else begin
            S_ref_edges = S_ref_edges + 1;
            #0.001;
            if (S_valid !== (S_ref_edges >= 2*WINDOW && S_ref_edges % WINDOW == 0)) begin
                $display("FAIL in %m: window cadence at edge %0d", S_ref_edges); $stop;
            end
        end
    end
    task next_sample;
        begin
            @(posedge S_ref); #1;
            while (S_valid !== 1'b1) begin @(posedge S_ref); #1; end
        end
    endtask
    task check_running;
        begin
            if (S_count != EXPECTED || S_lost !== 1'b0) begin
                $display("FAIL in %m: expected %0d edges, got %0d/lost=%b",
                    EXPECTED, S_count, S_lost); $stop;
            end
        end
    endtask
    initial begin
        O_done = 1'b0;
        #1; S_reset = 1'b1;
        #1;
        if ({S_valid, S_lost, S_sticky} !== 3'b000 || S_count !== 0) begin
            $display("FAIL in %m: reset outputs"); $stop;
        end
        repeat (2) @(negedge S_ref);
        S_reset = 1'b0;
        // 8 samples cover repeated 8-bit counter wrap in scaled cases.
        for (S_i = 0; S_i < 8; S_i = S_i + 1) begin
            next_sample; check_running;
            if (S_sticky !== 1'b0) begin
                $display("FAIL in %m: false startup alarm"); $stop;
            end
        end
        @(negedge S_ref); S_run = 1'b0;
        repeat (3) next_sample;
        if (S_count !== 0 || {S_lost, S_sticky} !== 2'b11) begin
            $display("FAIL in %m: stopped clock not detected"); $stop;
        end
        // Clear on a non-sampling edge: live alarm stays high.
        @(negedge S_ref); S_clear = 1'b1;
        @(posedge S_ref); #1;
        if ({S_lost, S_sticky} !== 2'b10) begin
            $display("FAIL in %m: clear changed live alarm or failed to clear sticky"); $stop;
        end
        @(negedge S_ref); S_clear = 1'b0;
        // Hold clear through the next zero sample: a new fault wins over clear.
        S_clear = 1'b1;
        next_sample;
        if ({S_lost, S_sticky} !== 2'b11) begin
            $display("FAIL in %m: new-fault/clear priority"); $stop;
        end
        @(negedge S_ref); S_clear = 1'b0; S_run = 1'b1;
        repeat (3) next_sample;
        check_running;
        if (S_sticky !== 1'b1) begin
            $display("FAIL in %m: sticky lost on recovery"); $stop;
        end
        @(negedge S_ref); S_clear = 1'b1;
        @(posedge S_ref); #1;
        if ({S_lost, S_sticky} !== 2'b00) begin
            $display("FAIL in %m: clear after recovery"); $stop;
        end
        @(negedge S_ref); S_clear = 1'b0;
        // Reset during a stopped clock must still assert and restart the baseline.
        S_run = 1'b0;
        #1; S_reset = 1'b1;
        #1;
        if ({S_valid, S_lost, S_sticky} !== 3'b000 || S_count !== 0) begin
            $display("FAIL in %m: reset while stopped"); $stop;
        end
        @(negedge S_ref); S_reset = 1'b0;
        repeat (3) next_sample;
        if ({S_lost, S_sticky} !== 2'b11) begin
            $display("FAIL in %m: stopped at startup"); $stop;
        end
        @(negedge S_ref); S_run = 1'b1;
        repeat (3) next_sample;
        check_running;
        O_done = 1'b1;
    end
endmodule
