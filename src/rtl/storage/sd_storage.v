// Host-domain sector port to physical TF SPI. No FAT/files or video reset here.
module sd_storage #(
    parameter integer COMMAND_ADDR_BITS=3,RETURN_ADDR_BITS=6,
    parameter [15:0] INIT_DIVIDER=16'd250,WORK_DIVIDER=16'd4,
    parameter [31:0] POWERUP_CYCLES=32'd100000,INIT_TIMEOUT_CYCLES=32'd100000000,
    parameter [31:0] INIT_POLL_CYCLES=32'd100000,RETRY_CYCLES=32'd200000000,
    parameter [31:0] PROBE_CYCLES=32'd50000000,DELIVERY_TIMEOUT_CYCLES=32'd10000000,
    parameter [31:0] RESPONSE_TIMEOUT_CYCLES=32'd1000000,TOKEN_TIMEOUT_CYCLES=32'd10000000,
    parameter [31:0] BUSY_TIMEOUT_CYCLES=32'd50000000,STALL_TIMEOUT_CYCLES=32'd10000000
) (
    input wire I_host_clk,I_sd_clk,I_async_reset,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [31:0] I_lba,
    input wire [7:0] I_count,
    input wire [1:0] I_context,I_priority,
    input wire [15:0] I_tag,
    input wire [2:0] I_urgent_context,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire O_sector_last,O_request_last,
    output wire [1:0] O_byte_context,
    output wire [15:0] O_byte_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [1:0] O_done_context,
    output wire [15:0] O_done_tag,
    output wire [3:0] O_done_error,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_tag,
    output wire O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output wire [1:0] O_cancel_done_context,
    output wire [15:0] O_cancel_done_tag,
    output wire O_card_ready,O_card_present,
    output wire [32:0] O_capacity_sectors,
    // Native SD-domain diagnostics; synchronize a snapshot before host use.
    output wire O_sd_high_capacity,
    output wire [3:0] O_sd_card_error,
    output wire O_sd_ncs,O_sd_sclk,O_sd_mosi,
    input wire I_sd_miso
);
    wire S_sd_reset,S_card_ready,S_card_present;
    wire [32:0] S_capacity_sectors;
    wire S_request_valid,S_request_ready,S_cancel_valid,S_cancel_ready;
    wire [31:0] S_lba;
    wire [7:0] S_count;
    wire [1:0] S_context,S_priority,S_cancel_context;
    wire [15:0] S_tag,S_cancel_tag;
    wire [2:0] S_urgent;
    wire S_byte_valid,S_byte_ready,S_sector_last,S_request_last,S_done_valid,S_done_ready;
    wire [7:0] S_byte;
    wire [1:0] S_byte_context,S_done_context,S_cancel_done_context;
    wire [15:0] S_byte_tag,S_done_tag,S_cancel_done_tag;
    wire [3:0] S_error;
    wire S_cancel_done_valid,S_cancel_done_ready;
    reset_sync u_sd_reset (.I_clk(I_sd_clk),.I_async_reset(I_async_reset),.O_reset(S_sd_reset));
    assign O_card_present=O_card_ready;
    sector_cdc_bridge #(.COMMAND_ADDR_BITS(COMMAND_ADDR_BITS),.RETURN_ADDR_BITS(RETURN_ADDR_BITS)) u_bridge (
        .I_host_clk(I_host_clk),.I_sd_clk(I_sd_clk),.I_async_reset(I_async_reset),
        .I_request_valid(I_request_valid),.O_request_ready(O_request_ready),.I_lba(I_lba),.I_count(I_count),
        .I_context(I_context),.I_priority(I_priority),.I_tag(I_tag),
        .I_cancel_valid(I_cancel_valid),.O_cancel_ready(O_cancel_ready),.I_cancel_context(I_cancel_context),.I_cancel_tag(I_cancel_tag),
        .I_urgent_context(I_urgent_context),.O_card_ready(O_card_ready),.O_byte_valid(O_byte_valid),.I_byte_ready(I_byte_ready),
        .O_byte_data(O_byte_data),.O_sector_last(O_sector_last),.O_request_last(O_request_last),
        .O_byte_context(O_byte_context),.O_byte_tag(O_byte_tag),.O_done_valid(O_done_valid),.I_done_ready(I_done_ready),
        .O_done_context(O_done_context),.O_done_tag(O_done_tag),.O_done_error(O_done_error),
        .O_cancel_done_valid(O_cancel_done_valid),.I_cancel_done_ready(I_cancel_done_ready),
        .O_cancel_done_context(O_cancel_done_context),.O_cancel_done_tag(O_cancel_done_tag),
        .I_sd_card_ready(S_card_ready),.I_sd_capacity_sectors(S_capacity_sectors),.O_capacity_sectors(O_capacity_sectors),
        .O_sd_request_valid(S_request_valid),.I_sd_request_ready(S_request_ready),
        .O_sd_lba(S_lba),.O_sd_count(S_count),.O_sd_context(S_context),.O_sd_priority(S_priority),.O_sd_tag(S_tag),
        .O_sd_cancel_valid(S_cancel_valid),.I_sd_cancel_ready(S_cancel_ready),.O_sd_cancel_context(S_cancel_context),.O_sd_cancel_tag(S_cancel_tag),
        .O_sd_urgent_context(S_urgent),.I_sd_byte_valid(S_byte_valid),.O_sd_byte_ready(S_byte_ready),.I_sd_byte_data(S_byte),
        .I_sd_sector_last(S_sector_last),.I_sd_request_last(S_request_last),.I_sd_byte_context(S_byte_context),.I_sd_byte_tag(S_byte_tag),
        .I_sd_done_valid(S_done_valid),.O_sd_done_ready(S_done_ready),.I_sd_done_context(S_done_context),.I_sd_done_tag(S_done_tag),.I_sd_done_error(S_error),
        .I_sd_cancel_done_valid(S_cancel_done_valid),.O_sd_cancel_done_ready(S_cancel_done_ready),
        .I_sd_cancel_done_context(S_cancel_done_context),.I_sd_cancel_done_tag(S_cancel_done_tag));
    sd_sector_reader #(.INIT_DIVIDER(INIT_DIVIDER),.WORK_DIVIDER(WORK_DIVIDER),.POWERUP_CYCLES(POWERUP_CYCLES),
        .INIT_TIMEOUT_CYCLES(INIT_TIMEOUT_CYCLES),.INIT_POLL_CYCLES(INIT_POLL_CYCLES),.RETRY_CYCLES(RETRY_CYCLES),
        .PROBE_CYCLES(PROBE_CYCLES),.DELIVERY_TIMEOUT_CYCLES(DELIVERY_TIMEOUT_CYCLES),
        .RESPONSE_TIMEOUT_CYCLES(RESPONSE_TIMEOUT_CYCLES),.TOKEN_TIMEOUT_CYCLES(TOKEN_TIMEOUT_CYCLES),
        .BUSY_TIMEOUT_CYCLES(BUSY_TIMEOUT_CYCLES),.STALL_TIMEOUT_CYCLES(STALL_TIMEOUT_CYCLES)) u_reader (
        .I_clk(I_sd_clk),.I_reset(S_sd_reset),.I_request_valid(S_request_valid),.O_request_ready(S_request_ready),
        .I_lba(S_lba),.I_count(S_count),.I_context(S_context),.I_priority(S_priority),.I_tag(S_tag),.I_urgent_context(S_urgent),
        .O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),.O_sector_last(S_sector_last),.O_request_last(S_request_last),
        .O_byte_context(S_byte_context),.O_byte_tag(S_byte_tag),.O_done_valid(S_done_valid),.I_done_ready(S_done_ready),
        .O_done_context(S_done_context),.O_done_tag(S_done_tag),.O_done_error(S_error),
        .I_cancel_valid(S_cancel_valid),.O_cancel_ready(S_cancel_ready),.I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),
        .O_cancel_done_valid(S_cancel_done_valid),.I_cancel_done_ready(S_cancel_done_ready),
        .O_cancel_done_context(S_cancel_done_context),.O_cancel_done_tag(S_cancel_done_tag),
        .O_card_ready(S_card_ready),.O_high_capacity(O_sd_high_capacity),.O_capacity_sectors(S_capacity_sectors),
        .O_card_present(S_card_present),.O_card_error(O_sd_card_error),
        .O_sd_ncs(O_sd_ncs),.O_sd_sclk(O_sd_sclk),.O_sd_mosi(O_sd_mosi),.I_sd_miso(I_sd_miso));
endmodule
