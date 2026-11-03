// Dual-clock FIFO with synchronous RAM read and registered Gray source pointers.
// Shared reset MUST flush both sides; never reset one pointer independently.
// Assert I_async_reset at startup; this block does not generate power-on reset.
module async_fifo #(
    parameter integer DATA_BITS = 48,
    parameter integer ADDR_BITS = 11,
    parameter integer USE_BRAM32K = 0,
    parameter integer FULL_REGISTER = 0
) (
    input wire I_write_clk, I_read_clk, I_async_reset,
    input wire I_write_valid,
    output wire O_write_ready,
    input wire [DATA_BITS-1:0] I_write_data,
    output wire O_write_full,
    output wire [ADDR_BITS:0] O_write_level,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [DATA_BITS-1:0] O_read_data,
    output wire O_read_empty,
    output wire [ADDR_BITS:0] O_read_level
);
    localparam integer DEPTH = 2**ADDR_BITS;
    wire S_write_reset, S_read_reset;
    reg [ADDR_BITS:0] S_write_binary, S_write_gray, S_read_binary, S_read_gray;
    reg [ADDR_BITS:0] S_read_gray_meta, S_read_gray_sync;
    reg [ADDR_BITS:0] S_write_gray_meta, S_write_gray_sync;
    wire S_write_fire = I_write_valid && O_write_ready;
    wire S_read_fire = O_read_valid && I_read_ready;
    wire [ADDR_BITS:0] S_write_next = S_write_binary + S_write_fire;
    wire [ADDR_BITS:0] S_write_gray_next = (S_write_next >> 1) ^ S_write_next;
    wire [ADDR_BITS:0] S_read_next = S_read_binary + S_read_fire;
    wire [ADDR_BITS:0] S_read_gray_next = (S_read_next >> 1) ^ S_read_next;
    wire [ADDR_BITS:0] S_full_compare =
        {~S_read_gray_sync[ADDR_BITS:ADDR_BITS-1],S_read_gray_sync[ADDR_BITS-2:0]};
    // The full comparison feeds write_ready/write_fire, which drives the next
    // write pointer. Compare the NEXT pointer when registering full, so the
    // flag asserts on the edge that consumes the final free entry. Comparing
    // the current pointer would allow one more write and overwrite unread data.
    reg S_full_q;
    wire S_full_now=S_write_gray == S_full_compare;
    wire S_write_full=FULL_REGISTER ? S_full_q : S_full_now;
    reg S_read_valid;
    wire [DATA_BITS-1:0] S_read_data;
    wire S_head_available = S_read_gray_next != S_write_gray_sync;
    wire S_read_enable = !S_read_reset && (!S_read_valid || I_read_ready) && S_head_available;
    function [ADDR_BITS:0] gray_to_binary;
        input [ADDR_BITS:0] gray;
        integer bit_index;
        begin
            gray_to_binary[ADDR_BITS] = gray[ADDR_BITS];
            for (bit_index=ADDR_BITS-1; bit_index>=0; bit_index=bit_index-1)
                gray_to_binary[bit_index] = gray_to_binary[bit_index+1] ^ gray[bit_index];
        end
    endfunction
    reset_sync u_write_reset (
        .I_clk(I_write_clk),.I_async_reset(I_async_reset),.O_reset(S_write_reset));
    reset_sync u_read_reset (
        .I_clk(I_read_clk),.I_async_reset(I_async_reset),.O_reset(S_read_reset));
    assign O_write_full = S_write_full;
    // Both local resets assert asynchronously and release on their own clock.
    // Use those local levels for datapath gating; the shared request must not
    // bypass reset synchronization into another domain's ready/valid logic.
    assign O_write_ready = !S_write_reset && !O_write_full;
    assign O_read_valid = !S_read_reset && S_read_valid;
    assign O_read_empty = !O_read_valid;
    assign O_read_data = S_read_data;
    assign O_write_level = S_write_binary - gray_to_binary(S_read_gray_sync);
    assign O_read_level = gray_to_binary(S_write_gray_sync) - S_read_binary;

    // The current address is not released to the writer until its output is consumed.
    // If a head is consumed, synchronously read the NEXT head on the same edge.
    // No storage reset. Only large audio payload FIFOs select explicit 32K blocks;
    // Shallow control FIFOs use LUT RAM rather than one 9K block per 18 bits
    // of payload. TD's ram_style="dram" is a distributed RAM directive, not
    // external DRAM. Both inferred styles retain the same synchronous read.
    // Neither path uses collision results.
    generate if (USE_BRAM32K) begin : g_bram32k
        player_bram32k #(.DATA_BITS(DATA_BITS),.ADDR_BITS(ADDR_BITS),.DEPTH(DEPTH)) u_memory (
            .I_clk_a(I_write_clk),.I_enable_a(S_write_fire),.I_write_a(1'b1),
            .I_address_a(S_write_binary[ADDR_BITS-1:0]),.I_data_a(I_write_data),.O_data_a(),
            .I_clk_b(I_read_clk),.I_enable_b(S_read_enable),.I_write_b(1'b0),
            .I_address_b(S_read_next[ADDR_BITS-1:0]),.I_data_b({DATA_BITS{1'b0}}),.O_data_b(S_read_data));
    end else begin : g_inferred
        localparam MEMORY_STYLE=ADDR_BITS<=4 ? "dram" : "bram";
        (* ram_style=MEMORY_STYLE *) reg [DATA_BITS-1:0] S_memory [0:DEPTH-1];
        reg [DATA_BITS-1:0] S_data;
        assign S_read_data=S_data;
        always @(posedge I_write_clk) begin
            if (S_write_fire) S_memory[S_write_binary[ADDR_BITS-1:0]] <= I_write_data;
        end
        always @(posedge I_read_clk) begin
            if (S_read_enable) S_data <= S_memory[S_read_next[ADDR_BITS-1:0]];
        end
    end endgenerate
    always @(posedge I_write_clk or posedge S_write_reset) begin
        if (S_write_reset) begin
            S_write_binary <= 0; S_write_gray <= 0;
            S_read_gray_meta <= 0; S_read_gray_sync <= 0;
            S_full_q <= 0;
        end else begin
            if (FULL_REGISTER) S_full_q <= S_write_gray_next == S_full_compare;
            S_write_binary <= S_write_next;
            S_write_gray <= S_write_gray_next;
            S_read_gray_meta <= S_read_gray;
            S_read_gray_sync <= S_read_gray_meta;
        end
    end
    always @(posedge I_read_clk or posedge S_read_reset) begin
        if (S_read_reset) begin
            S_read_binary <= 0; S_read_gray <= 0; S_read_valid <= 0;
            S_write_gray_meta <= 0; S_write_gray_sync <= 0;
        end else begin
            S_read_binary <= S_read_next;
            S_read_gray <= S_read_gray_next;
            S_write_gray_meta <= S_write_gray;
            S_write_gray_sync <= S_write_gray_meta;
            if (!S_read_valid || I_read_ready) S_read_valid <= S_head_available;
        end
    end
    // synthesis translate_off
    initial begin
        if (DATA_BITS<1 || ADDR_BITS<2 || ADDR_BITS>16 ||
            (USE_BRAM32K!=0 && USE_BRAM32K!=1) || (FULL_REGISTER!=0 && FULL_REGISTER!=1)) begin
            $display("FAIL: async_fifo invalid width/depth parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
