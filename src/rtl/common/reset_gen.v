// Reset policy only: no PLL generation, key debounce or transaction draining.
module reset_gen #(
    parameter integer POR_COUNTER_BITS = 20,
    parameter integer SYNC_STAGES = 2
) (
    input  wire I_clk_50m,
    input  wire I_clk_100m,
    input  wire I_clk_125m,
    input  wire I_clk_25m,
    input  wire I_sys_pll_locked,
    input  wire I_video_pll_locked,
    input  wire I_global_reset,
    // Level request from the isolation controller AFTER outstanding work drains.
    input  wire I_media_reset_safe,
    output wire O_reset_sys,
    output wire O_reset_mem,
    output wire O_reset_media,
    output wire O_reset_sd_media,
    output wire O_reset_video
);
    wire S_por_hold;
    wire S_sys_async_reset;
    wire S_video_async_reset;

    generate
        if (POR_COUNTER_BITS >= 1) begin : g_por
            reg [POR_COUNTER_BITS-1:0] S_por_count;
            reg S_por_done;

            // Requires verified FPGA power-up initialization support in TD.
            // Never mask this initial block with synthesis translate_off.
            initial begin
                S_por_count = {POR_COUNTER_BITS{1'b0}};
                S_por_done = 1'b0;
            end

            // One-shot POR: expires on the 2**POR_COUNTER_BITS-th 50 MHz edge.
            // Global reset and PLL lock changes do not restart this counter.
            always @(posedge I_clk_50m) begin
                if (!S_por_done) begin
                    if (&S_por_count)
                        S_por_done <= 1'b1;
                    else
                        S_por_count <= S_por_count + 1'b1;
                end
            end
            assign S_por_hold = ~S_por_done;
        end else begin : g_invalid_por
            assign S_por_hold = 1'b1;
            // synthesis translate_off
            initial begin
                $display("FAIL: reset_gen POR_COUNTER_BITS must be at least 1");
                $stop;
            end
            // synthesis translate_on
        end
    endgenerate

    assign S_sys_async_reset = S_por_hold | I_global_reset | ~I_sys_pll_locked;
    assign S_video_async_reset = S_por_hold | I_global_reset | ~I_video_pll_locked;

    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) u_sys (
        .I_clk(I_clk_100m), .I_async_reset(S_sys_async_reset),
        .O_reset(O_reset_sys)
    );
    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) u_mem (
        .I_clk(I_clk_125m), .I_async_reset(S_sys_async_reset),
        .O_reset(O_reset_mem)
    );
    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) u_media (
        .I_clk(I_clk_125m),
        .I_async_reset(S_sys_async_reset | I_media_reset_safe),
        .O_reset(O_reset_media)
    );
    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) u_sd_media (
        .I_clk(I_clk_100m),
        .I_async_reset(S_sys_async_reset | I_media_reset_safe),
        .O_reset(O_reset_sd_media)
    );
    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) u_video (
        .I_clk(I_clk_25m), .I_async_reset(S_video_async_reset),
        .O_reset(O_reset_video)
    );
endmodule
