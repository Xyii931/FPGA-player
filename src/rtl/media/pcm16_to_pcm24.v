// One elastic stereo frame register. Samples are bit patterns of signed PCM.
module pcm16_to_pcm24 (
    input wire I_clk, I_reset,
    input wire I_valid,
    output wire O_ready,
    input wire [15:0] I_left, I_right,
    input wire [31:0] I_sample_index,
    input wire I_last,
    output reg O_valid,
    input wire I_ready,
    output reg [23:0] O_left, O_right,
    output reg [31:0] O_sample_index,
    output reg O_last
);
    assign O_ready = !I_reset && (!O_valid || I_ready);
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            O_valid <= 0; O_left <= 0; O_right <= 0;
            O_sample_index <= 0; O_last <= 0;
        end else if (O_ready) begin
            O_valid <= I_valid;
            if (I_valid) begin
                O_left <= {I_left,8'd0}; O_right <= {I_right,8'd0};
                O_sample_index <= I_sample_index; O_last <= I_last;
            end
        end
    end
endmodule
