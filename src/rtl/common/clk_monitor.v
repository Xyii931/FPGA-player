// One monitored domain. Reference clock must keep running.
// Diagnostic window counts only; PLL lock remains the fast reset source.
module clk_monitor #(
    parameter integer COUNTER_BITS = 20,
    parameter integer WINDOW_CYCLES = 50000
) (
    input  wire I_clk_50m,
    input  wire I_clk_mon,
    input  wire I_reset,
    input  wire I_clear,
    output reg  O_sample_valid,
    output reg  [COUNTER_BITS-1:0] O_edge_count,
    output reg  O_clock_lost,
    output reg  O_clock_lost_sticky
);
    wire S_reset_mon;
    reg [COUNTER_BITS-1:0] S_count_mon;
    reg [COUNTER_BITS-1:0] S_gray_mon;
    wire [COUNTER_BITS-1:0] S_count_next = S_count_mon + 1'b1;
    reg [COUNTER_BITS-1:0] S_gray_meta;
    reg [COUNTER_BITS-1:0] S_gray_sync;
    reg [COUNTER_BITS-1:0] S_previous;
    reg [31:0] S_window_count;
    reg S_baseline_valid;
    wire [COUNTER_BITS-1:0] S_observed;
    wire [COUNTER_BITS-1:0] S_delta = S_observed - S_previous;

    function [COUNTER_BITS-1:0] gray_to_binary;
        input [COUNTER_BITS-1:0] gray;
        integer bit_index;
        begin
            gray_to_binary[COUNTER_BITS-1] = gray[COUNTER_BITS-1];
            for (bit_index = COUNTER_BITS-2; bit_index >= 0; bit_index = bit_index-1)
                gray_to_binary[bit_index] = gray_to_binary[bit_index+1] ^ gray[bit_index];
        end
    endfunction
    assign S_observed = gray_to_binary(S_gray_sync);

    reset_sync u_mon_reset (
        .I_clk(I_clk_mon), .I_async_reset(I_reset), .O_reset(S_reset_mon)
    );
    always @(posedge I_clk_mon or posedge S_reset_mon) begin
        if (S_reset_mon) begin
            S_count_mon <= {COUNTER_BITS{1'b0}};
            S_gray_mon <= {COUNTER_BITS{1'b0}};
        end else begin
            S_count_mon <= S_count_next;
            // Register the Gray word at its source, avoiding binary decode glitches.
            S_gray_mon <= (S_count_next >> 1) ^ S_count_next;
        end
    end
    // Constrain Gray bus skew/delay and synchronizer placement in TD integration.
    always @(posedge I_clk_50m or posedge I_reset) begin
        if (I_reset) begin
            S_gray_meta <= {COUNTER_BITS{1'b0}};
            S_gray_sync <= {COUNTER_BITS{1'b0}};
        end else begin
            S_gray_meta <= S_gray_mon;
            S_gray_sync <= S_gray_meta;
        end
    end
    always @(posedge I_clk_50m or posedge I_reset) begin
        if (I_reset) begin
            S_previous <= {COUNTER_BITS{1'b0}};
            S_window_count <= 32'd0;
            S_baseline_valid <= 1'b0;
            O_sample_valid <= 1'b0;
            O_edge_count <= {COUNTER_BITS{1'b0}};
            O_clock_lost <= 1'b0;
            O_clock_lost_sticky <= 1'b0;
        end else begin
            O_sample_valid <= 1'b0;
            if (I_clear) O_clock_lost_sticky <= 1'b0;
            if (S_window_count == WINDOW_CYCLES-1) begin
                S_window_count <= 32'd0;
                S_previous <= S_observed;
                S_baseline_valid <= 1'b1;
                if (S_baseline_valid) begin
                    O_sample_valid <= 1'b1;
                    O_edge_count <= S_delta;
                    O_clock_lost <= (S_delta == {COUNTER_BITS{1'b0}});
                    if (S_delta == {COUNTER_BITS{1'b0}})
                        O_clock_lost_sticky <= 1'b1;
                end
            end else S_window_count <= S_window_count + 1'b1;
        end
    end
    // synthesis translate_off
    initial begin
        if (COUNTER_BITS < 2 || COUNTER_BITS > 30 || WINDOW_CYCLES < 4) begin
            $display("FAIL: clk_monitor invalid counter/window parameters");
            $stop;
        end
    end
    // synthesis translate_on
endmodule
