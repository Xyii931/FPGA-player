// Pixel-clock enable, not a generated clock. Never gate it for pause/mute.
module samp_tick #(
    parameter [31:0] SAMP_INC = 32'd8246337
) (
    input wire I_clk, I_reset,
    output reg O_sample_tick
);
    reg [31:0] S_phase;
    wire [32:0] S_sum = {1'b0,S_phase} + {1'b0,SAMP_INC};
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_phase <= 32'd0;
            O_sample_tick <= 1'b0;
        end else begin
            S_phase <= S_sum[31:0];
            O_sample_tick <= S_sum[32];
        end
    end
    // synthesis translate_off
    initial begin
        if (SAMP_INC == 0) begin
            $display("FAIL: samp_tick increment must be nonzero"); $stop;
        end
    end
    // synthesis translate_on
endmodule
