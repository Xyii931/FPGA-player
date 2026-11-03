// Assert asynchronously; release after SYNC_STAGES rising clock edges.
// The caller must assert I_async_reset at startup. This module is not a POR.
module reset_sync #(
    parameter integer SYNC_STAGES = 2
) (
    input  wire I_clk,
    input  wire I_async_reset,
    output wire O_reset
);

    generate
        if (SYNC_STAGES >= 2) begin : g_valid_stages
            reg [SYNC_STAGES-1:0] S_reset_pipe;

            always @(posedge I_clk or posedge I_async_reset) begin
                if (I_async_reset)
                    S_reset_pipe <= {SYNC_STAGES{1'b1}};
                else
                    S_reset_pipe <= {S_reset_pipe[SYNC_STAGES-2:0], 1'b0};
            end

            assign O_reset = S_reset_pipe[SYNC_STAGES-1];
        end else begin : g_invalid_stages
            assign O_reset = 1'b1;
            // synthesis translate_off
            initial begin
                $display("FAIL: reset_sync SYNC_STAGES must be at least 2");
                $stop;
            end
            // synthesis translate_on
        end
    endgenerate

endmodule
