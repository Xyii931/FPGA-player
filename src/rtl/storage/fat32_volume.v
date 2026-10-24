// Standalone mounting wrapper for sd_storage's host-domain interface.
// This is not yet a path resolver or a complete multi-file filesystem.
module fat32_volume (
    input wire I_clk,I_reset,I_card_ready,
    input wire [32:0] I_capacity_sectors,
    input wire I_start_valid,
    output wire O_start_ready,
    output wire O_result_valid,
    input wire I_result_ready,
    output wire [7:0] O_error,
    output wire [3:0] O_storage_error,
    output wire O_mounted,
    output wire [31:0] O_partition_lba,O_volume_sectors,O_fat_lba,O_data_lba,
    output wire [31:0] O_cluster_count,O_root_cluster,
    output wire [7:0] O_sectors_per_cluster,
    output wire [2:0] O_cluster_shift,
    output wire O_request_valid,
    input wire I_request_ready,
    output wire [31:0] O_lba,
    output wire [7:0] O_count,
    output wire [1:0] O_context,O_priority,
    output wire [15:0] O_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_sector_last,I_request_last,
    input wire [1:0] I_byte_context,
    input wire [15:0] I_byte_tag,
    input wire I_done_valid,
    output wire O_done_ready,
    input wire [1:0] I_done_context,
    input wire [15:0] I_done_tag,
    input wire [3:0] I_done_error,
    output wire O_cancel_valid,
    input wire I_cancel_ready,
    output wire [1:0] O_cancel_context,
    output wire [15:0] O_cancel_tag,
    input wire I_cancel_done_valid,
    output wire O_cancel_done_ready,
    input wire [1:0] I_cancel_done_context,
    input wire [15:0] I_cancel_done_tag
);
    wire S_read_valid,S_read_ready,S_result_valid,S_result_ready;
    wire [31:0] S_read_lba;
    wire [7:0] S_error,S_buffer_data;
    wire [3:0] S_storage_error;
    wire [8:0] S_buffer_address;
    fat32_mount u_mount (
        .I_clk(I_clk),.I_reset(I_reset),.I_card_ready(I_card_ready),.I_capacity_sectors(I_capacity_sectors),
        .I_start_valid(I_start_valid),.O_start_ready(O_start_ready),.O_result_valid(O_result_valid),
        .I_result_ready(I_result_ready),.O_error(O_error),.O_storage_error(O_storage_error),.O_mounted(O_mounted),
        .O_partition_lba(O_partition_lba),.O_volume_sectors(O_volume_sectors),.O_fat_lba(O_fat_lba),.O_data_lba(O_data_lba),
        .O_cluster_count(O_cluster_count),.O_root_cluster(O_root_cluster),
        .O_sectors_per_cluster(O_sectors_per_cluster),.O_cluster_shift(O_cluster_shift),
        .O_read_valid(S_read_valid),.I_read_ready(S_read_ready),.O_read_lba(S_read_lba),
        .I_read_result_valid(S_result_valid),.O_read_result_ready(S_result_ready),
        .I_read_error(S_error),.I_storage_error(S_storage_error),
        .O_buffer_address(S_buffer_address),.I_buffer_data(S_buffer_data));
    fat32_sector_port u_sector (
        .I_clk(I_clk),.I_reset(I_reset),.I_card_ready(I_card_ready),
        .I_start_valid(S_read_valid),.O_start_ready(S_read_ready),.I_lba(S_read_lba),
        .I_context(2'd0),.I_priority(2'd0),.I_abort(1'b0),
        .O_result_valid(S_result_valid),.I_result_ready(S_result_ready),.O_error(S_error),.O_storage_error(S_storage_error),
        .I_buffer_address(S_buffer_address),.O_buffer_data(S_buffer_data),
        .O_request_valid(O_request_valid),.I_request_ready(I_request_ready),.O_lba(O_lba),.O_count(O_count),
        .O_context(O_context),.O_priority(O_priority),.O_tag(O_tag),
        .I_byte_valid(I_byte_valid),.O_byte_ready(O_byte_ready),.I_byte_data(I_byte_data),
        .I_sector_last(I_sector_last),.I_request_last(I_request_last),.I_byte_context(I_byte_context),.I_byte_tag(I_byte_tag),
        .I_done_valid(I_done_valid),.O_done_ready(O_done_ready),.I_done_context(I_done_context),.I_done_tag(I_done_tag),.I_done_error(I_done_error),
        .O_cancel_valid(O_cancel_valid),.I_cancel_ready(I_cancel_ready),.O_cancel_context(O_cancel_context),.O_cancel_tag(O_cancel_tag),
        .I_cancel_done_valid(I_cancel_done_valid),.O_cancel_done_ready(O_cancel_done_ready),
        .I_cancel_done_context(I_cancel_done_context),.I_cancel_done_tag(I_cancel_done_tag));
endmodule
