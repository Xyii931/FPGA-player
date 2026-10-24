// ACR cadence is driven by sample events in the pixel domain, NOT 5x clock.
module acr_gen #(
    parameter integer MEASURE_MODE = 0,
    parameter [19:0] ACR_N = 20'd6144, ACR_CTS = 20'd25000
) (
    input wire I_clk, I_reset, I_sample_tick,
    output reg O_acr_valid,
    output reg [19:0] O_acr_n, O_acr_cts,
    output reg O_measure_overflow
);
    localparam integer SAMPLE_EVENTS = ACR_N / 128;
    reg [12:0] S_event_count;
    wire S_boundary = I_sample_tick && S_event_count == SAMPLE_EVENTS-1;
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) S_event_count <= 13'd0;
        else if (I_sample_tick) begin
            if (S_boundary) S_event_count <= 13'd0;
            else S_event_count <= S_event_count + 1'b1;
        end
    end
    generate
        if (MEASURE_MODE == 0) begin : g_constant
            always @(posedge I_clk or posedge I_reset) begin
                if (I_reset) begin
                    O_acr_valid <= 0; O_acr_n <= 0; O_acr_cts <= 0;
                    O_measure_overflow <= 0;
                end else begin
                    O_acr_valid <= S_boundary;
                    if (S_boundary) begin O_acr_n <= ACR_N; O_acr_cts <= ACR_CTS; end
                end
            end
        end else begin : g_measure
            reg S_anchored;
            reg [20:0] S_interval;
            always @(posedge I_clk or posedge I_reset) begin
                if (I_reset) begin
                    S_anchored <= 0; S_interval <= 0;
                    O_acr_valid <= 0; O_acr_n <= 0; O_acr_cts <= 0;
                    O_measure_overflow <= 0;
                end else begin
                    O_acr_valid <= 0;
                    if (S_boundary) begin
                        S_anchored <= 1;
                        S_interval <= 0;
                        if (S_anchored) begin
                            if (S_interval < 21'h0fffff) begin
                                O_acr_valid <= 1;
                                O_acr_n <= ACR_N;
                                O_acr_cts <= S_interval[19:0] + 1'b1;
                            end else O_measure_overflow <= 1;
                        end
                    end else if (S_anchored && S_interval < 21'h100000)
                        S_interval <= S_interval + 1'b1;
                end
            end
        end
    endgenerate
    // synthesis translate_off
    initial begin
        if ((MEASURE_MODE != 0 && MEASURE_MODE != 1) || ACR_N == 0 ||
            ACR_N[6:0] != 0 || ACR_CTS == 0) begin
            $display("FAIL: acr_gen invalid mode/N/CTS"); $stop;
        end
    end
    // synthesis translate_on
endmodule
