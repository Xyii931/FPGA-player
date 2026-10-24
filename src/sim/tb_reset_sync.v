`timescale 1ns/1ps

module tb_reset_sync;
    reg S_clk;
    reg S_clock_enable;
    reg S_async_reset;
    reg S_test_pass;
    wire S_reset_2;
    wire S_reset_3;
    integer S_phase;
    time S_last_rising_edge;

    reset_sync u_default (
        .I_clk(S_clk), .I_async_reset(S_async_reset), .O_reset(S_reset_2)
    );
    reset_sync #(.SYNC_STAGES(3)) u_three_stages (
        .I_clk(S_clk), .I_async_reset(S_async_reset), .O_reset(S_reset_3)
    );

    initial begin
        S_clk = 1'b0;
        forever begin
            #5;
            if (S_clock_enable)
                S_clk = ~S_clk;
        end
    end

    task check_outputs;
        input expected_2;
        input expected_3;
        begin
            if ((S_reset_2 !== expected_2) || (S_reset_3 !== expected_3)) begin
                $display("FAIL at %0t: expected %b/%b, got %b/%b",
                         $time, expected_2, expected_3, S_reset_2, S_reset_3);
                $stop;
            end
        end
    endtask

    task assert_reset;
        begin
            S_async_reset = 1'b1;
            #1; // Allow nonblocking assignments to settle.
            check_outputs(1'b1, 1'b1);
        end
    endtask

    task check_release;
        begin
            @(posedge S_clk); #1;
            check_outputs(1'b1, 1'b1);
            @(posedge S_clk); #1;
            check_outputs(1'b0, 1'b1);
            @(posedge S_clk); #1;
            check_outputs(1'b0, 1'b0);
            @(posedge S_clk); #1;
            check_outputs(1'b0, 1'b0);
        end
    endtask

    always @(posedge S_clk)
        S_last_rising_edge = $time;

    // Nonblocking updates must release reset at a rising edge, never between.
    always @(negedge S_reset_2 or negedge S_reset_3) begin
        if ((S_async_reset === 1'b0) && ($time != S_last_rising_edge)) begin
            $display("FAIL at %0t: reset released outside a rising edge", $time);
            $stop;
        end
    end

    initial begin
        S_test_pass = 1'b0;
        S_clock_enable = 1'b1;
        S_async_reset = 1'b0;

        // Startup assertion and release at four different non-edge phases.
        for (S_phase = 1; S_phase <= 4; S_phase = S_phase + 1) begin
            @(negedge S_clk); #2;
            assert_reset;
            @(negedge S_clk); #(S_phase);
            S_async_reset = 1'b0;
            #0.1;
            check_outputs(1'b1, 1'b1);
            check_release;
        end

        // Reassert while release is in progress, before either stage finishes.
        @(negedge S_clk); #2;
        assert_reset;
        S_async_reset = 1'b0;
        @(posedge S_clk); #1;
        check_outputs(1'b1, 1'b1);
        #1;
        assert_reset;
        #1;
        S_async_reset = 1'b0;
        check_release;

        // Reassert after the two-stage output releases but before stage three.
        @(negedge S_clk); #2;
        assert_reset;
        S_async_reset = 1'b0;
        repeat (2) @(posedge S_clk);
        #1;
        check_outputs(1'b0, 1'b1);
        #1;
        assert_reset;
        #1;
        S_async_reset = 1'b0;
        check_release;

        // Stop the clock low, then high: assertion must not need a clock edge.
        @(negedge S_clk);
        S_clock_enable = 1'b0;
        #2;
        assert_reset;
        #12;
        S_async_reset = 1'b0;
        #20;
        check_outputs(1'b1, 1'b1);
        S_clock_enable = 1'b1;
        check_release;

        @(posedge S_clk); #1;
        S_clock_enable = 1'b0;
        #1;
        assert_reset;
        #12;
        S_async_reset = 1'b0;
        #20;
        check_outputs(1'b1, 1'b1);
        S_clock_enable = 1'b1;
        check_release;

        S_test_pass = 1'b1;
        $display("PASS: reset_sync directed scenarios completed");
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: reset_sync simulation timeout");
        $stop;
    end
endmodule
