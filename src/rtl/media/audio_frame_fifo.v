// One audio track, 48 data bits per frame. Context/index/EOF live outside this RAM.
module audio_frame_fifo #(
    parameter integer ADDR_BITS=11,
    parameter integer PREFILL_FRAMES=1024,
    parameter integer LOW_FRAMES=512
) (
    input wire I_write_clk, I_read_clk, I_async_flush,
    input wire I_valid,
    output wire O_ready,
    input wire [23:0] I_left, I_right,
    output wire O_valid,
    input wire I_ready,
    output wire [23:0] O_left, O_right,
    output wire [ADDR_BITS:0] O_write_level, O_read_level,
    output wire O_prefilled, O_need_fill
);
    wire S_full, S_empty;
    // Preserve all 48 PCM bits and the configured capacity; reserve the small
    // RAM pool for control, display and filesystem buffers.
    async_fifo #(.DATA_BITS(48),.ADDR_BITS(ADDR_BITS),.USE_BRAM32K(1)) u_fifo (
        .I_write_clk(I_write_clk),.I_read_clk(I_read_clk),.I_async_reset(I_async_flush),
        .I_write_valid(I_valid),.O_write_ready(O_ready),.I_write_data({I_left,I_right}),
        .O_write_full(S_full),.O_write_level(O_write_level),
        .O_read_valid(O_valid),.I_read_ready(I_ready),.O_read_data({O_left,O_right}),
        .O_read_empty(S_empty),.O_read_level(O_read_level));
    assign O_prefilled = !I_async_flush && O_valid && O_read_level>=PREFILL_FRAMES;
    assign O_need_fill = !I_async_flush && O_read_level<LOW_FRAMES;
    // synthesis translate_off
    initial begin
        if (LOW_FRAMES<1 || PREFILL_FRAMES<LOW_FRAMES || PREFILL_FRAMES>2**ADDR_BITS) begin
            $display("FAIL: audio_frame_fifo invalid watermarks"); $stop;
        end
    end
    // synthesis translate_on
endmodule
