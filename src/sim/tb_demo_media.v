`timescale 1ns/1ps
// Actual DEM1 CRC/catalog -> real FAT32 mount/path/read and Flash CDC/FIFO.
// Physical Flash is an explicit held-byte/terminal fixture; no vendor primitive model.
module tb_demo_media;
    // Declare the complete endpoint before instances (Verilog-2001).
    reg S_clk=0,S_flash_clk=0,S_reset=1,S_test_pass=0;
    reg S_core_I_clk=0;
    reg S_core_I_reset=0;
    reg S_core_I_card_ready=0;
    reg S_core_I_unmount=0;
    reg [32:0] S_core_I_capacity_sectors=0;
    reg S_core_I_mount_valid=0;
    reg S_core_I_mount_result_ready=0;
    reg S_core_I_enum_valid=0;
    reg [15:0] S_core_I_enum_tag=0;
    reg [6:0] S_core_I_enum_path_length=0;
    reg [31:0] S_core_I_enum_sector_budget=0;
    reg S_core_I_enum_path_valid=0;
    reg [7:0] S_core_I_enum_path_data=0;
    reg S_core_I_enum_path_last=0;
    reg S_core_I_enum_stop=0;
    reg S_core_I_enum_cancel=0;
    reg S_core_I_enum_entry_ready=0;
    reg S_core_I_enum_name_ready=0;
    reg S_core_I_enum_done_ready=0;
    reg S_core_I_open_valid=0;
    reg [1:0] S_core_I_open_context=0;
    reg [15:0] S_core_I_open_tag=0;
    reg [6:0] S_core_I_path_length=0;
    reg [31:0] S_core_I_sector_budget=0;
    reg S_core_I_path_valid=0;
    reg [7:0] S_core_I_path_data=0;
    reg S_core_I_path_last=0;
    reg S_core_I_open_cancel=0;
    reg S_core_I_open_result_ready=0;
    reg S_core_I_close_valid=0;
    reg [1:0] S_core_I_close_context=0;
    reg S_core_I_read_valid=0;
    reg [1:0] S_core_I_read_context=0;
    reg [1:0] S_core_I_read_priority=0;
    reg [31:0] S_core_I_offset=0;
    reg [31:0] S_core_I_length=0;
    reg [15:0] S_core_I_epoch=0;
    reg [2:0] S_core_I_urgent_context=0;
    reg S_core_I_byte_ready=0;
    reg S_core_I_done_ready=0;
    reg S_core_I_cancel_valid=0;
    reg [1:0] S_core_I_cancel_context=0;
    reg [15:0] S_core_I_cancel_epoch=0;
    reg S_core_I_cancel_done_ready=0;
    reg S_core_I_sd_request_ready=0;
    reg S_core_I_sd_byte_valid=0;
    reg [7:0] S_core_I_sd_byte_data=0;
    reg S_core_I_sd_sector_last=0;
    reg S_core_I_sd_request_last=0;
    reg [1:0] S_core_I_sd_byte_context=0;
    reg [15:0] S_core_I_sd_byte_tag=0;
    reg S_core_I_sd_done_valid=0;
    reg [1:0] S_core_I_sd_done_context=0;
    reg [15:0] S_core_I_sd_done_tag=0;
    reg [3:0] S_core_I_sd_done_error=0;
    reg S_core_I_sd_cancel_ready=0;
    reg S_core_I_sd_cancel_done_valid=0;
    reg [1:0] S_core_I_sd_cancel_done_context=0;
    reg [15:0] S_core_I_sd_cancel_done_tag=0;
    reg S_manual=0,S_request=0,S_byte_ready=0,S_done_ready=0,S_cancel=0,S_cancel_done_ready=0;
    reg [31:0] S_lba=0;
    reg [7:0] S_manual_count=1;
    reg S_phy_hold=0;
    reg [7:0] S_flash_mem[0:16383];
    reg S_phy_active=0,S_phy_done=0;
    reg [23:0] S_phy_address=0;
    reg [15:0] S_phy_length=0,S_phy_index=0,S_phy_tag=0;
    reg [7:0] S_received[0:4095];
    integer S_i,S_read_count=0;
    reg [31:0] S_crc;
    reg [1:0] S_phy_pause=0;
    reg S_meta_pending=0;
    reg [127:0] S_expected_meta;
    integer S_meta_lane;
    reg S_buffer_pending=0;
    reg [7:0] S_expected_buffer;
    integer S_header_lane;
    wire S_core_O_mount_ready;
    wire S_core_O_mount_result_valid;
    wire [7:0] S_core_O_mount_error;
    wire [3:0] S_core_O_mount_storage_error;
    wire [31:0] S_core_O_mount_generation;
    wire S_core_O_mounted;
    wire S_core_O_quiescent;
    wire [31:0] S_core_O_generation;
    wire [31:0] S_core_O_partition_lba;
    wire [31:0] S_core_O_volume_sectors;
    wire [31:0] S_core_O_fat_lba;
    wire [31:0] S_core_O_data_lba;
    wire [31:0] S_core_O_cluster_count;
    wire [31:0] S_core_O_root_cluster;
    wire [7:0] S_core_O_sectors_per_cluster;
    wire [2:0] S_core_O_cluster_shift;
    wire S_core_O_enum_ready;
    wire S_core_O_enum_path_ready;
    wire S_core_O_enum_entry_valid;
    wire [7:0] S_core_O_enum_attr;
    wire [31:0] S_core_O_enum_size;
    wire [31:0] S_core_O_enum_first_cluster;
    wire [87:0] S_core_O_enum_alias;
    wire [6:0] S_core_O_enum_name_length;
    wire S_core_O_enum_is_lfn;
    wire S_core_O_enum_name_valid;
    wire [7:0] S_core_O_enum_name_data;
    wire S_core_O_enum_name_last;
    wire S_core_O_enum_done_valid;
    wire [15:0] S_core_O_enum_tag;
    wire [31:0] S_core_O_enum_generation;
    wire [31:0] S_core_O_enum_sectors;
    wire [2:0] S_core_O_enum_warning;
    wire [7:0] S_core_O_enum_error;
    wire [3:0] S_core_O_enum_storage_error;
    wire S_core_O_open_ready;
    wire S_core_O_path_ready;
    wire S_core_O_open_result_valid;
    wire [1:0] S_core_O_open_context;
    wire [15:0] S_core_O_open_tag;
    wire [31:0] S_core_O_open_generation;
    wire [31:0] S_core_O_open_size;
    wire [31:0] S_core_O_open_first_cluster;
    wire [31:0] S_core_O_open_sectors;
    wire [7:0] S_core_O_open_attr;
    wire [7:0] S_core_O_open_error;
    wire [3:0] S_core_O_open_storage_error;
    wire [2:0] S_core_O_open_warning;
    wire [31:0] S_core_O_byte_generation;
    wire [31:0] S_core_O_done_generation;
    wire [31:0] S_core_O_cancel_done_generation;
    wire S_core_O_close_ready;
    wire S_core_O_read_ready;
    wire S_core_O_byte_valid;
    wire [7:0] S_core_O_byte_data;
    wire [1:0] S_core_O_byte_context;
    wire [15:0] S_core_O_byte_epoch;
    wire [31:0] S_core_O_byte_offset;
    wire S_core_O_byte_last;
    wire S_core_O_done_valid;
    wire [1:0] S_core_O_done_context;
    wire [15:0] S_core_O_done_epoch;
    wire [31:0] S_core_O_done_bytes;
    wire S_core_O_done_eof;
    wire [7:0] S_core_O_done_error;
    wire [3:0] S_core_O_done_storage_error;
    wire S_core_O_cancel_ready;
    wire S_core_O_cancel_done_valid;
    wire [1:0] S_core_O_cancel_done_context;
    wire [15:0] S_core_O_cancel_done_epoch;
    wire S_core_O_sd_request_valid;
    wire [31:0] S_core_O_sd_lba;
    wire [7:0] S_core_O_sd_count;
    wire [1:0] S_core_O_sd_context;
    wire [1:0] S_core_O_sd_priority;
    wire [15:0] S_core_O_sd_tag;
    wire S_core_O_sd_byte_ready;
    wire S_core_O_sd_done_ready;
    wire S_core_O_sd_cancel_valid;
    wire [1:0] S_core_O_sd_cancel_context;
    wire [15:0] S_core_O_sd_cancel_tag;
    wire S_core_O_sd_cancel_done_ready;
    wire S_demo_O_raw_request_valid;
    wire [31:0] S_demo_O_raw_lba;
    wire [15:0] S_demo_O_raw_tag;
    wire S_demo_O_raw_byte_ready;
    wire S_demo_O_raw_done_ready;
    wire S_demo_O_ready;
    wire [3:0] S_demo_O_error;
    wire S_demo_O_flash_valid;
    wire [23:0] S_demo_O_flash_address;
    wire [9:0] S_demo_O_flash_length;
    wire S_demo_O_flash_byte_ready;
    wire S_demo_O_flash_done_ready;
    wire S_demo_O_request_ready;
    wire S_demo_O_byte_valid;
    wire [7:0] S_demo_O_byte_data;
    wire S_demo_O_sector_last;
    wire S_demo_O_request_last;
    wire [1:0] S_demo_O_byte_context;
    wire [1:0] S_demo_O_done_context;
    wire [1:0] S_demo_O_cancel_done_context;
    wire [15:0] S_demo_O_byte_tag;
    wire [15:0] S_demo_O_done_tag;
    wire [15:0] S_demo_O_cancel_done_tag;
    wire S_demo_O_done_valid;
    wire [3:0] S_demo_O_done_error;
    wire S_demo_O_cancel_ready;
    wire S_demo_O_cancel_done_valid;
    wire S_demo_O_quiescent;
    wire S_bridge_O_ready;
    wire S_bridge_O_byte_valid;
    wire [7:0] S_bridge_O_byte_data;
    wire S_bridge_O_byte_last;
    wire S_bridge_O_done_valid;
    wire [3:0] S_bridge_O_error;
    wire S_bridge_O_flash_valid;
    wire [23:0] S_bridge_O_flash_address;
    wire [15:0] S_bridge_O_flash_length;
    wire [15:0] S_bridge_O_flash_tag;
    wire S_bridge_O_flash_read_ready;
    wire S_bridge_O_flash_done_ready;
    wire S_phy_emit=S_phy_active && S_phy_pause==0;
    always #4 S_clk=~S_clk;
    always #5 S_flash_clk=~S_flash_clk;
    fat32_core u_core (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_card_ready(S_demo_O_ready),
        .I_unmount(S_core_I_unmount),
        .I_capacity_sectors(33'd4194304),
        .I_mount_valid(S_core_I_mount_valid),
        .O_mount_ready(S_core_O_mount_ready),
        .O_mount_result_valid(S_core_O_mount_result_valid),
        .I_mount_result_ready(S_core_I_mount_result_ready),
        .O_mount_error(S_core_O_mount_error),
        .O_mount_storage_error(S_core_O_mount_storage_error),
        .O_mount_generation(S_core_O_mount_generation),
        .O_mounted(S_core_O_mounted),
        .O_quiescent(S_core_O_quiescent),
        .O_generation(S_core_O_generation),
        .O_partition_lba(S_core_O_partition_lba),
        .O_volume_sectors(S_core_O_volume_sectors),
        .O_fat_lba(S_core_O_fat_lba),
        .O_data_lba(S_core_O_data_lba),
        .O_cluster_count(S_core_O_cluster_count),
        .O_root_cluster(S_core_O_root_cluster),
        .O_sectors_per_cluster(S_core_O_sectors_per_cluster),
        .O_cluster_shift(S_core_O_cluster_shift),
        .I_enum_valid(S_core_I_enum_valid),
        .O_enum_ready(S_core_O_enum_ready),
        .I_enum_tag(S_core_I_enum_tag),
        .I_enum_path_length(S_core_I_enum_path_length),
        .I_enum_sector_budget(S_core_I_enum_sector_budget),
        .I_enum_path_valid(S_core_I_enum_path_valid),
        .O_enum_path_ready(S_core_O_enum_path_ready),
        .I_enum_path_data(S_core_I_enum_path_data),
        .I_enum_path_last(S_core_I_enum_path_last),
        .I_enum_stop(S_core_I_enum_stop),
        .I_enum_cancel(S_core_I_enum_cancel),
        .O_enum_entry_valid(S_core_O_enum_entry_valid),
        .I_enum_entry_ready(S_core_I_enum_entry_ready),
        .O_enum_attr(S_core_O_enum_attr),
        .O_enum_size(S_core_O_enum_size),
        .O_enum_first_cluster(S_core_O_enum_first_cluster),
        .O_enum_alias(S_core_O_enum_alias),
        .O_enum_name_length(S_core_O_enum_name_length),
        .O_enum_is_lfn(S_core_O_enum_is_lfn),
        .O_enum_name_valid(S_core_O_enum_name_valid),
        .I_enum_name_ready(S_core_I_enum_name_ready),
        .O_enum_name_data(S_core_O_enum_name_data),
        .O_enum_name_last(S_core_O_enum_name_last),
        .O_enum_done_valid(S_core_O_enum_done_valid),
        .I_enum_done_ready(S_core_I_enum_done_ready),
        .O_enum_tag(S_core_O_enum_tag),
        .O_enum_generation(S_core_O_enum_generation),
        .O_enum_sectors(S_core_O_enum_sectors),
        .O_enum_warning(S_core_O_enum_warning),
        .O_enum_error(S_core_O_enum_error),
        .O_enum_storage_error(S_core_O_enum_storage_error),
        .I_open_valid(S_core_I_open_valid),
        .O_open_ready(S_core_O_open_ready),
        .I_open_context(S_core_I_open_context),
        .I_open_tag(S_core_I_open_tag),
        .I_path_length(S_core_I_path_length),
        .I_sector_budget(S_core_I_sector_budget),
        .I_path_valid(S_core_I_path_valid),
        .O_path_ready(S_core_O_path_ready),
        .I_path_data(S_core_I_path_data),
        .I_path_last(S_core_I_path_last),
        .I_open_cancel(S_core_I_open_cancel),
        .O_open_result_valid(S_core_O_open_result_valid),
        .I_open_result_ready(S_core_I_open_result_ready),
        .O_open_context(S_core_O_open_context),
        .O_open_tag(S_core_O_open_tag),
        .O_open_generation(S_core_O_open_generation),
        .O_open_size(S_core_O_open_size),
        .O_open_first_cluster(S_core_O_open_first_cluster),
        .O_open_sectors(S_core_O_open_sectors),
        .O_open_attr(S_core_O_open_attr),
        .O_open_error(S_core_O_open_error),
        .O_open_storage_error(S_core_O_open_storage_error),
        .O_open_warning(S_core_O_open_warning),
        .O_byte_generation(S_core_O_byte_generation),
        .O_done_generation(S_core_O_done_generation),
        .O_cancel_done_generation(S_core_O_cancel_done_generation),
        .I_close_valid(S_core_I_close_valid),
        .O_close_ready(S_core_O_close_ready),
        .I_close_context(S_core_I_close_context),
        .I_read_valid(S_core_I_read_valid),
        .O_read_ready(S_core_O_read_ready),
        .I_read_context(S_core_I_read_context),
        .I_read_priority(S_core_I_read_priority),
        .I_offset(S_core_I_offset),
        .I_length(S_core_I_length),
        .I_epoch(S_core_I_epoch),
        .I_urgent_context(S_core_I_urgent_context),
        .O_byte_valid(S_core_O_byte_valid),
        .I_byte_ready(S_core_I_byte_ready),
        .O_byte_data(S_core_O_byte_data),
        .O_byte_context(S_core_O_byte_context),
        .O_byte_epoch(S_core_O_byte_epoch),
        .O_byte_offset(S_core_O_byte_offset),
        .O_byte_last(S_core_O_byte_last),
        .O_done_valid(S_core_O_done_valid),
        .I_done_ready(S_core_I_done_ready),
        .O_done_context(S_core_O_done_context),
        .O_done_epoch(S_core_O_done_epoch),
        .O_done_bytes(S_core_O_done_bytes),
        .O_done_eof(S_core_O_done_eof),
        .O_done_error(S_core_O_done_error),
        .O_done_storage_error(S_core_O_done_storage_error),
        .I_cancel_valid(S_core_I_cancel_valid),
        .O_cancel_ready(S_core_O_cancel_ready),
        .I_cancel_context(S_core_I_cancel_context),
        .I_cancel_epoch(S_core_I_cancel_epoch),
        .O_cancel_done_valid(S_core_O_cancel_done_valid),
        .I_cancel_done_ready(S_core_I_cancel_done_ready),
        .O_cancel_done_context(S_core_O_cancel_done_context),
        .O_cancel_done_epoch(S_core_O_cancel_done_epoch),
        .O_sd_request_valid(S_core_O_sd_request_valid),
        .I_sd_request_ready(S_demo_O_request_ready),
        .O_sd_lba(S_core_O_sd_lba),
        .O_sd_count(S_core_O_sd_count),
        .O_sd_context(S_core_O_sd_context),
        .O_sd_priority(S_core_O_sd_priority),
        .O_sd_tag(S_core_O_sd_tag),
        .I_sd_byte_valid(S_demo_O_byte_valid),
        .O_sd_byte_ready(S_core_O_sd_byte_ready),
        .I_sd_byte_data(S_demo_O_byte_data),
        .I_sd_sector_last(S_demo_O_sector_last),
        .I_sd_request_last(S_demo_O_request_last),
        .I_sd_byte_context(S_demo_O_byte_context),
        .I_sd_byte_tag(S_demo_O_byte_tag),
        .I_sd_done_valid(S_demo_O_done_valid),
        .O_sd_done_ready(S_core_O_sd_done_ready),
        .I_sd_done_context(S_demo_O_done_context),
        .I_sd_done_tag(S_demo_O_done_tag),
        .I_sd_done_error(S_demo_O_done_error),
        .O_sd_cancel_valid(S_core_O_sd_cancel_valid),
        .I_sd_cancel_ready(S_demo_O_cancel_ready),
        .O_sd_cancel_context(S_core_O_sd_cancel_context),
        .O_sd_cancel_tag(S_core_O_sd_cancel_tag),
        .I_sd_cancel_done_valid(S_demo_O_cancel_done_valid),
        .O_sd_cancel_done_ready(S_core_O_sd_cancel_done_ready),
        .I_sd_cancel_done_context(S_demo_O_cancel_done_context),
        .I_sd_cancel_done_tag(S_demo_O_cancel_done_tag)
    );
    demo_sector_source u_demo (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_recovery_enable(1'b0),
        .I_raw_card_ready(1'b0),
        .O_raw_request_valid(S_demo_O_raw_request_valid),
        .I_raw_request_ready(1'b0),
        .O_raw_lba(S_demo_O_raw_lba),
        .O_raw_tag(S_demo_O_raw_tag),
        .I_raw_byte_valid(1'b0),
        .O_raw_byte_ready(S_demo_O_raw_byte_ready),
        .I_raw_byte_data(8'd0),
        .I_raw_sector_last(1'b0),
        .I_raw_request_last(1'b0),
        .I_raw_byte_tag(16'd0),
        .I_raw_done_valid(1'b0),
        .O_raw_done_ready(S_demo_O_raw_done_ready),
        .I_raw_done_error(4'd0),
        .I_raw_done_tag(16'd0),
        .O_ready(S_demo_O_ready),
        .O_error(S_demo_O_error),
        .O_flash_valid(S_demo_O_flash_valid),
        .I_flash_ready(S_bridge_O_ready),
        .O_flash_address(S_demo_O_flash_address),
        .O_flash_length(S_demo_O_flash_length),
        .I_flash_byte_valid(S_bridge_O_byte_valid),
        .O_flash_byte_ready(S_demo_O_flash_byte_ready),
        .I_flash_byte_data(S_bridge_O_byte_data),
        .I_flash_byte_last(S_bridge_O_byte_last),
        .I_flash_done_valid(S_bridge_O_done_valid),
        .O_flash_done_ready(S_demo_O_flash_done_ready),
        .I_flash_error(S_bridge_O_error),
        .I_request_valid(S_manual ? S_request : S_core_O_sd_request_valid),
        .O_request_ready(S_demo_O_request_ready),
        .I_lba(S_manual ? S_lba : S_core_O_sd_lba),
        .I_count(S_manual ? S_manual_count : S_core_O_sd_count),
        .I_context(S_manual ? 2'd2 : S_core_O_sd_context),
        .I_tag(S_manual ? 16'h55aa : S_core_O_sd_tag),
        .O_byte_valid(S_demo_O_byte_valid),
        .I_byte_ready(S_manual ? S_byte_ready : S_core_O_sd_byte_ready),
        .O_byte_data(S_demo_O_byte_data),
        .O_sector_last(S_demo_O_sector_last),
        .O_request_last(S_demo_O_request_last),
        .O_byte_context(S_demo_O_byte_context),
        .O_done_context(S_demo_O_done_context),
        .O_cancel_done_context(S_demo_O_cancel_done_context),
        .O_byte_tag(S_demo_O_byte_tag),
        .O_done_tag(S_demo_O_done_tag),
        .O_cancel_done_tag(S_demo_O_cancel_done_tag),
        .O_done_valid(S_demo_O_done_valid),
        .I_done_ready(S_manual ? S_done_ready : S_core_O_sd_done_ready),
        .O_done_error(S_demo_O_done_error),
        .I_cancel_valid(S_manual ? S_cancel : S_core_O_sd_cancel_valid),
        .O_cancel_ready(S_demo_O_cancel_ready),
        .I_cancel_context(S_manual ? 2'd2 : S_core_O_sd_cancel_context),
        .I_cancel_tag(S_manual ? 16'h55aa : S_core_O_sd_cancel_tag),
        .O_cancel_done_valid(S_demo_O_cancel_done_valid),
        .I_cancel_done_ready(S_manual ? S_cancel_done_ready : S_core_O_sd_cancel_done_ready),
        .O_quiescent(S_demo_O_quiescent)
    );
    flash_read_cdc u_bridge (
        .I_host_clk(S_clk),
        .I_flash_clk(S_flash_clk),
        .I_async_reset(S_reset),
        .I_valid(S_demo_O_flash_valid),
        .O_ready(S_bridge_O_ready),
        .I_address(S_demo_O_flash_address),
        .I_length(S_demo_O_flash_length),
        .O_byte_valid(S_bridge_O_byte_valid),
        .I_byte_ready(S_demo_O_flash_byte_ready),
        .O_byte_data(S_bridge_O_byte_data),
        .O_byte_last(S_bridge_O_byte_last),
        .O_done_valid(S_bridge_O_done_valid),
        .I_done_ready(S_demo_O_flash_done_ready),
        .O_error(S_bridge_O_error),
        .O_flash_valid(S_bridge_O_flash_valid),
        .I_flash_ready(!S_phy_active && !S_phy_done),
        .O_flash_address(S_bridge_O_flash_address),
        .O_flash_length(S_bridge_O_flash_length),
        .O_flash_tag(S_bridge_O_flash_tag),
        .I_flash_read_valid(S_phy_emit),
        .O_flash_read_ready(S_bridge_O_flash_read_ready),
        .I_flash_read_data(S_flash_mem[S_phy_address+S_phy_index]),
        .I_flash_read_last(S_phy_index+16'd1==S_phy_length),
        .I_flash_done_valid(S_phy_done && !S_phy_hold),
        .O_flash_done_ready(S_bridge_O_flash_done_ready),
        .I_flash_error(4'd0),
        .I_flash_tag(S_phy_tag)
    );
    task fail;
        input [767:0] text;
        begin $display("FAIL demo_media: %0s",text); $stop; end
    endtask
    always @(posedge S_flash_clk) begin
        if(S_reset) begin S_phy_active<=0; S_phy_done<=0; S_phy_pause<=0; end
        else begin
            if(S_phy_pause!=0) S_phy_pause<=S_phy_pause-1'b1;
            if(S_bridge_O_flash_valid && !S_phy_active && !S_phy_done) begin
                if(S_bridge_O_flash_address<24'h100000 || S_bridge_O_flash_address+S_bridge_O_flash_length>24'h104000)
                    fail("Flash request outside immutable DEM fixture");
                S_phy_active<=1; S_phy_address<=S_bridge_O_flash_address-24'h100000;
                S_phy_length<=S_bridge_O_flash_length; S_phy_index<=0; S_phy_tag<=S_bridge_O_flash_tag; S_phy_pause<=0;
            end
            if(S_phy_emit && S_bridge_O_flash_read_ready) begin
                // Insert gaps only AFTER acceptance; a stalled valid byte stays valid.
                S_phy_pause<=S_phy_index[1:0]==1 ? 2'd2 : 2'd0;
                if(S_phy_index+16'd1==S_phy_length) begin S_phy_active<=0; S_phy_done<=1; end
                else S_phy_index<=S_phy_index+1'b1;
            end
            if(S_phy_done && !S_phy_hold && S_bridge_O_flash_done_ready) S_phy_done<=0;
        end
    end
    function [31:0] crc_range;
        input integer first,length;
        integer j,k;
        reg [31:0] value;
        begin
            value=32'hffffffff;
            for(j=0;j<length;j=j+1) begin
                value=value^{24'd0,S_flash_mem[first+j]};
                for(k=0;k<8;k=k+1) value=value[0] ? (value>>1)^32'hedb88320 : value>>1;
            end
            crc_range=value^32'hffffffff;
        end
    endfunction
    task put32;
        input integer at;
        input [31:0] value;
        begin S_flash_mem[at]=value[7:0]; S_flash_mem[at+1]=value[15:8]; S_flash_mem[at+2]=value[23:16]; S_flash_mem[at+3]=value[31:24]; end
    endtask
    task build_pack;
        begin
            for(S_i=0;S_i<16384;S_i=S_i+1) S_flash_mem[S_i]=0;
            put32(0,32'h314d4544); put32(4,32'h00020001); put32(8,40);
            put32(16,1); put32(20,64); put32(24,22); // type1/id0
            put32(36,2); put32(40,128); put32(44,52); // type2/id0
            put32(64,32'h31454c52); put32(68,32'h00010002); put32(72,6);
            S_flash_mem[80]=2; put32(82,32'hff0000ff); put32(76,crc_range(80,6));
            put32(128,32'h46464952); put32(132,44); put32(136,32'h45564157);
            put32(140,32'h20746d66); put32(144,16); put32(148,32'h00020001);
            put32(152,48000); put32(156,192000); put32(160,32'h00100004);
            put32(164,32'h61746164); put32(168,8); put32(172,32'h7fff8000); put32(176,32'h0001ffff);
            put32(28,crc_range(64,22)); put32(48,crc_range(128,52)); put32(12,crc_range(16,40));
        end
    endtask
    // Full literal record layout; replace only the two hexadecimal filename
    // digits. This does not call the DUT's formatter or read its pair map.
    function [511:0] expected_record;
        input integer image,audio,has_audio;
        reg [127:0] digits;
        reg [511:0] text;
        begin
            digits="0123456789ABCDEF";
            if(has_audio) text={"[ITEM]",8'd10,"file=/D000.RLE",8'd10,
                "audio=/D000.WAV",8'd10,{25{8'd32}},8'd10};
            else text={"[ITEM]",8'd10,"file=/D000.RLE",8'd10,{41{8'd32}},8'd10};
            text[(63-15)*8+:8]=digits[(15-((image>>4)&15))*8+:8];
            text[(63-16)*8+:8]=digits[(15-(image&15))*8+:8];
            if(has_audio) begin
                text[(63-31)*8+:8]=digits[(15-((audio>>4)&15))*8+:8];
                text[(63-32)*8+:8]=digits[(15-(audio&15))*8+:8];
            end
            expected_record=text;
        end
    endfunction
    function [7:0] expected_list_byte;
        input integer address,images,paired;
        reg [511:0] text;
        begin
            text=expected_record(address/64,images*2-1-address/64,paired);
            expected_list_byte=address<images*64 ? text[(63-address%64)*8+:8] : 8'd0;
        end
    endfunction
    task build_catalog;
        input integer images,paired;
        integer entry,count,at;
        begin
            for(entry=0;entry<16384;entry=entry+1) S_flash_mem[entry]=0;
            count=images*(paired ? 2 : 1);
            put32(0,32'h314d4544); put32(4,(count<<16)|1); put32(8,count*20);
            // Images first, audio in reverse ID order: the pairing cannot be
            // inferred from adjacency or the index of the displayed image.
            // Opaque one-byte payloads exercise the DEM1 owner, not the decoders.
            for(entry=0;entry<count;entry=entry+1) begin
                at=16+entry*20;
                put32(at,entry<images ? (entry<<16)|1 : ((count-1-entry)<<16)|2);
                put32(at+4,4096+entry); put32(at+8,1);
                S_flash_mem[4096+entry]=(entry*73+19)&255;
                put32(at+12,crc_range(4096+entry,1));
            end
            put32(12,crc_range(16,count*20));
        end
    endtask
    task build_buffer_pack;
        integer entry,at,size,j;
        begin
            build_catalog(1,1);
            // Two opaque files cross the 512-byte CRC and fetch boundaries;
            // the final one-byte fetch must not expose retained sector bytes.
            for(entry=0;entry<2;entry=entry+1) begin
                at=entry==0 ? 4096 : 8192; size=entry==0 ? 1025 : 513;
                for(j=0;j<size;j=j+1) S_flash_mem[at+j]=(j*37+(j>>8)*53+entry*71+11)&255;
                put32(20+entry*20,at); put32(24+entry*20,size);
                put32(28+entry*20,crc_range(at,size));
            end
            put32(12,crc_range(16,40));
        end
    endtask
    task read_asset_sectors;
        input integer entry,offset,count,size;
        integer byte_index,at;
        reg [7:0] expected;
        begin
            wait(S_demo_O_quiescent);
            @(negedge S_clk); S_manual=1; S_lba=33054+entry*16384+offset/512;
            S_manual_count=count; S_request=1; S_byte_ready=0;
            while(!S_demo_O_request_ready) @(negedge S_clk);
            @(negedge S_clk); S_request=0;
            at=entry==0 ? 4096 : 8192;
            for(byte_index=0;byte_index<count*512;byte_index=byte_index+1) begin
                wait(S_demo_O_byte_valid);
                expected=offset+byte_index<size ? S_flash_mem[at+offset+byte_index] : 8'd0;
                // Include stalls on byte0, byte511, short-fetch tails and zeros.
                if(byte_index%17==0 || byte_index%512==511 || offset+byte_index==size-1)
                    repeat(3) begin
                        @(posedge S_clk); #1;
                        if(!S_demo_O_byte_valid || S_demo_O_byte_data!==expected)
                            fail("asset byte changed under buffer backpressure");
                    end
                @(negedge S_clk); S_byte_ready=1;
                @(posedge S_clk);
                if(!S_demo_O_byte_valid || S_demo_O_byte_data!==expected ||
                    S_demo_O_sector_last!==(byte_index%512==511) ||
                    S_demo_O_request_last!==(byte_index==count*512-1) ||
                    S_demo_O_byte_context!=2 || S_demo_O_byte_tag!=16'h55aa)
                    fail("asset multi-sector bytes, padding, identity or last");
                @(negedge S_clk); S_byte_ready=0;
            end
            wait(S_demo_O_done_valid);
            if(S_demo_O_done_error!=0) fail("asset sector terminal");
            @(negedge S_clk); S_done_ready=1;
            @(negedge S_clk); S_done_ready=0;
            wait(S_demo_O_quiescent);
        end
    endtask
    task cancel_buffer_prepare;
        input integer byte_index;
        begin
            wait(S_demo_O_quiescent);
            @(negedge S_clk); S_manual=1; S_lba=33054; S_manual_count=1; S_request=1; S_byte_ready=1;
            while(!S_demo_O_request_ready) @(negedge S_clk);
            @(negedge S_clk); S_request=0;
            wait(u_demo.S_q==u_demo.Q_BUFFER && u_demo.S_byte==byte_index);
            @(negedge S_clk); S_cancel=1; S_byte_ready=0;
            while(!S_demo_O_cancel_ready) @(negedge S_clk);
            @(negedge S_clk); S_cancel=0;
            wait(S_demo_O_done_valid && S_demo_O_cancel_done_valid);
            if(S_demo_O_done_error!=7 || S_demo_O_byte_valid || S_demo_O_done_tag!=16'h55aa ||
                S_demo_O_cancel_done_tag!=16'h55aa || u_demo.S_fetch_active || u_demo.S_fetch_offer)
                fail("buffer preparation cancel terminal or backend retirement");
            @(negedge S_clk); S_done_ready=1; S_cancel_done_ready=1;
            @(negedge S_clk); S_done_ready=0; S_cancel_done_ready=0;
            wait(S_demo_O_quiescent);
        end
    endtask
    task read_list_sector;
        input integer sector,count,images,paired;
        integer byte_index;
        reg [7:0] expected;
        begin
            wait(S_demo_O_quiescent);
            @(negedge S_clk); S_manual=1; S_lba=32830+sector; S_manual_count=count; S_request=1; S_byte_ready=0;
            while(!S_demo_O_request_ready) @(negedge S_clk);
            @(negedge S_clk); S_request=0;
            for(byte_index=0;byte_index<count*512;byte_index=byte_index+1) begin
                wait(S_demo_O_byte_valid);
                expected=expected_list_byte(sector*512+byte_index,images,paired);
                if(byte_index%64==63 || byte_index%64==0) begin
                    repeat(3) begin
                        @(posedge S_clk); #1;
                        if(!S_demo_O_byte_valid || S_demo_O_byte_data!==expected ||
                            S_demo_O_sector_last!==(byte_index%512==511) ||
                            S_demo_O_request_last!==(byte_index==count*512-1)) fail("list byte changed under boundary backpressure");
                    end
                end
                @(negedge S_clk); S_byte_ready=1;
                @(posedge S_clk);
                if(!S_demo_O_byte_valid || S_demo_O_byte_data!==expected ||
                    S_demo_O_sector_last!==(byte_index%512==511) || S_demo_O_request_last!==(byte_index==count*512-1) ||
                    S_demo_O_byte_context!=2 || S_demo_O_byte_tag!=16'h55aa) fail("full list sector byte/identity/last");
                @(negedge S_clk); S_byte_ready=0;
            end
            wait(S_demo_O_done_valid);
            repeat(3) begin
                @(negedge S_clk);
                if(!S_demo_O_done_valid || S_demo_O_done_error!=0 ||
                    S_demo_O_done_context!=2 || S_demo_O_done_tag!=16'h55aa) fail("list sector terminal hold");
            end
            S_done_ready=1; @(negedge S_clk); S_done_ready=0;
            wait(S_demo_O_quiescent);
        end
    endtask
    task cancel_list_prepare;
        input integer at_boundary;
        begin
            wait(S_demo_O_quiescent);
            @(negedge S_clk); S_manual=1; S_lba=32830; S_manual_count=1; S_request=1; S_byte_ready=at_boundary;
            while(!S_demo_O_request_ready) @(negedge S_clk);
            @(negedge S_clk); S_request=0;
            if(at_boundary) begin
                wait(u_demo.S_q==u_demo.Q_STREAM);
                wait(u_demo.S_q==u_demo.Q_LIST);
                if(u_demo.S_byte!=64) fail("cancel did not reach next-record preparation");
            end else wait(u_demo.S_q==u_demo.Q_LIST);
            @(negedge S_clk); S_cancel=1; S_byte_ready=0;
            while(!S_demo_O_cancel_ready) @(negedge S_clk);
            @(negedge S_clk); S_cancel=0;
            wait(S_demo_O_done_valid && S_demo_O_cancel_done_valid);
            if(S_demo_O_done_error!=7 || S_demo_O_byte_valid || S_demo_O_done_tag!=16'h55aa ||
                S_demo_O_cancel_done_tag!=16'h55aa) fail("list preparation cancel terminal");
            @(negedge S_clk); S_done_ready=1; S_cancel_done_ready=1;
            @(negedge S_clk); S_done_ready=0; S_cancel_done_ready=0;
            wait(S_demo_O_quiescent);
        end
    endtask
    // Golden directory and FAT sectors for build_catalog: sizes are one byte,
    // and aliases follow entry positions, independent of pairing IDs.
    function [7:0] expected_meta_byte;
        input integer lba,byte_index,entries,images;
        integer cluster,entry,asset,at;
        reg [31:0] value;
        reg [87:0] name;
        reg [127:0] digits;
        begin
            expected_meta_byte=0; value=0; name=0; digits="0123456789ABCDEF";
            if(lba>=32800 && lba<=32808) begin
                entry=(lba-32800)*16+byte_index/32; at=byte_index%32;
                if(entry>=1 && entry<=entries) begin
                    asset=entry-1;
                    name=asset<images ? "D000    RLE" : "D000    WAV";
                    name[(10-2)*8+:8]=digits[(15-((asset>>4)&15))*8+:8];
                    name[(10-3)*8+:8]=digits[(15-(asset&15))*8+:8];
                    value=256+asset*16384;
                    if(at<11) expected_meta_byte=name[(10-at)*8+:8];
                    else case(at)
                        11:expected_meta_byte=8'h20;
                        20:expected_meta_byte=value[23:16]; 21:expected_meta_byte=value[31:24];
                        26:expected_meta_byte=value[7:0]; 27:expected_meta_byte=value[15:8];
                        28:expected_meta_byte=1;
                        default:begin end
                    endcase
                end else if(entry==0) begin
                    name="PLAY       ";
                    if(at<11) expected_meta_byte=name[(10-at)*8+:8];
                    else if(at==11) expected_meta_byte=8'h10;
                    else if(at==26) expected_meta_byte=16;
                end
            end else begin
                // These cases address FAT sectors in asset windows, away from
                // root/list reserved chains. A one-byte file uses one cluster.
                cluster=(lba-32)*128+byte_index/4;
                asset=(cluster-256)/16384;
                if(cluster>=256 && asset<entries && (cluster-256)%16384==0) value=32'h0fffffff;
                expected_meta_byte=value >> ((byte_index%4)*8);
            end
        end
    endfunction
    task read_meta_sector;
        input integer lba,entries,images;
        integer byte_index;
        reg [7:0] expected;
        begin
            wait(S_demo_O_quiescent);
            @(negedge S_clk); S_manual=1; S_lba=lba; S_manual_count=1; S_request=1; S_byte_ready=0;
            while(!S_demo_O_request_ready) @(negedge S_clk);
            @(negedge S_clk); S_request=0;
            for(byte_index=0;byte_index<512;byte_index=byte_index+1) begin
                wait(S_demo_O_byte_valid); expected=expected_meta_byte(lba,byte_index,entries,images);
                // Hold each newly loaded FAT/directory descriptor at least two
                // cycles, so metadata cannot advance behind a stalled output.
                if(byte_index%4==0 || byte_index%32==31) repeat(2) begin
                    @(posedge S_clk); #1;
                    if(!S_demo_O_byte_valid || S_demo_O_byte_data!==expected) fail("metadata byte changed under backpressure");
                end
                @(negedge S_clk); S_byte_ready=1;
                @(posedge S_clk);
                if(!S_demo_O_byte_valid || S_demo_O_byte_data!==expected ||
                    S_demo_O_sector_last!==(byte_index==511) || S_demo_O_request_last!==(byte_index==511) ||
                    S_demo_O_byte_context!=2 || S_demo_O_byte_tag!=16'h55aa) fail("directory/FAT golden byte or identity");
                @(negedge S_clk); S_byte_ready=0;
            end
            wait(S_demo_O_done_valid);
            if(S_demo_O_done_error!=0 || !u_demo.S_catalog_idle) fail("metadata sector completed with an internal read outstanding");
            @(negedge S_clk); S_done_ready=1;
            @(negedge S_clk); S_done_ready=0;
            wait(S_demo_O_quiescent);
        end
    endtask
    task cancel_catalog_read;
        input integer kind;
        begin
            wait(S_demo_O_quiescent);
            @(negedge S_clk); S_manual=1; S_manual_count=1; S_request=1; S_byte_ready=1;
            S_lba=kind==0 ? 33054 : kind==1 ? 32800 : 34;
            while(!S_demo_O_request_ready) @(negedge S_clk);
            @(negedge S_clk); S_request=0;
            wait((u_demo.S_q==u_demo.Q_ASSET || u_demo.S_q==u_demo.Q_META_WAIT) && u_demo.S_catalog_phase==3);
            @(negedge S_clk); S_cancel=1; S_byte_ready=0;
            while(!S_demo_O_cancel_ready) @(negedge S_clk);
            @(negedge S_clk); S_cancel=0;
            while(!S_demo_O_done_valid) begin
                @(posedge S_clk); #1;
                if(!u_demo.S_catalog_idle && (S_demo_O_request_ready || S_demo_O_done_valid ||
                    S_demo_O_cancel_done_valid || S_demo_O_quiescent)) fail("cancel bypassed catalog read retirement");
            end
            wait(S_demo_O_cancel_done_valid);
            if(S_demo_O_done_error!=7 || S_demo_O_byte_valid || !u_demo.S_catalog_idle ||
                S_demo_O_done_tag!=16'h55aa || S_demo_O_cancel_done_tag!=16'h55aa) fail("catalog read cancel terminal");
            @(negedge S_clk); S_done_ready=1; S_cancel_done_ready=1;
            @(negedge S_clk); S_done_ready=0; S_cancel_done_ready=0;
            wait(S_demo_O_quiescent);
        end
    endtask
    task reject_catalog;
        input integer error;
        begin
            S_manual=0; S_request=0; S_byte_ready=0; S_reset=1;
            repeat(5) @(negedge S_clk); S_reset=0;
            wait(S_demo_O_error!=0 || S_demo_O_ready);
            if(S_demo_O_ready || S_demo_O_error!=error) fail("invalid catalog was published or rejected for the wrong reason");
            @(negedge S_clk); S_reset=1;
        end
    endtask
    task mount;
        begin
            wait(S_demo_O_ready || S_demo_O_error!=0);
            if(S_demo_O_error!=0) fail("valid package rejected");
            @(negedge S_clk); S_core_I_mount_valid=1;
            while(!S_core_O_mount_ready) @(negedge S_clk);
            @(negedge S_clk); S_core_I_mount_valid=0;
            wait(S_core_O_mount_result_valid);
            if(S_core_O_mount_error!=0 || !S_core_O_mounted) fail("virtual geometry rejected by real FAT32 mount");
            @(negedge S_clk); S_core_I_mount_result_ready=1;
            @(negedge S_clk); S_core_I_mount_result_ready=0;
        end
    endtask
    task open_file;
        input [255:0] path;
        input integer length,size;
        integer j;
        begin
            @(negedge S_clk); S_core_I_open_context=0; S_core_I_open_tag=S_core_I_open_tag+1;
            S_core_I_path_length=length; S_core_I_sector_budget=100; S_core_I_open_valid=1;
            while(!S_core_O_open_ready) @(negedge S_clk);
            @(negedge S_clk); S_core_I_open_valid=0;
            for(j=length-1;j>=0;j=j-1) begin
                S_core_I_path_valid=1; S_core_I_path_data=path[j*8+:8]; S_core_I_path_last=j==0;
                while(!S_core_O_path_ready) @(negedge S_clk);
                @(negedge S_clk);
            end
            S_core_I_path_valid=0; wait(S_core_O_open_result_valid);
            if(S_core_O_open_error!=0 || S_core_O_open_size!=size) fail("real FAT32 path/size did not match catalog");
            @(negedge S_clk); S_core_I_open_result_ready=1;
            @(negedge S_clk); S_core_I_open_result_ready=0;
        end
    endtask
    task read_file;
        input integer length;
        begin
            S_read_count=0;
            @(negedge S_clk); S_core_I_read_context=0; S_core_I_offset=0; S_core_I_length=length;
            S_core_I_epoch=S_core_I_epoch+1; S_core_I_read_valid=1;
            while(!S_core_O_read_ready) @(negedge S_clk);
            @(negedge S_clk); S_core_I_read_valid=0; S_core_I_byte_ready=1;
            wait(S_core_O_done_valid);
            if(S_core_O_done_error!=0 || S_core_O_done_bytes!=length || S_read_count!=length || !S_core_O_done_eof)
                fail("virtual file bypassed real bytes/EOF completion");
            @(negedge S_clk); S_core_I_done_ready=1; S_core_I_byte_ready=0;
            @(negedge S_clk); S_core_I_done_ready=0; S_core_I_close_context=0; S_core_I_close_valid=1;
            while(!S_core_O_close_ready) @(negedge S_clk);
            @(negedge S_clk); S_core_I_close_valid=0;
        end
    endtask
    always @(posedge S_clk) if(!S_reset && S_core_O_byte_valid && S_core_I_byte_ready) begin
        if(S_core_O_byte_offset!=S_read_count || S_core_O_byte_epoch!=S_core_I_epoch ||
            S_core_O_byte_generation!=S_core_O_generation) fail("real FAT descriptor identity");
        if(S_read_count>=4096) fail("fixture receive capacity exceeded");
        S_received[S_read_count]=S_core_O_byte_data; S_read_count=S_read_count+1;
    end
    // Compare complete returned records to the immutable DEM1 table fixture,
    // including fields not visible in the generated filename or FAT entry.
    always @(posedge S_clk) begin
        if(S_reset) S_meta_pending=0;
        else begin
            if(u_demo.S_catalog_done) begin
                if(!S_meta_pending || u_demo.S_catalog_result!==S_expected_meta)
                    fail("catalog word order, full-width fields or stale read completion");
                S_meta_pending=0;
            end
            if(u_demo.S_catalog_start) begin
                if(S_meta_pending || u_demo.S_catalog_phase!=0 ||
                    {1'b0,u_demo.S_catalog_request}>=u_demo.S_entries)
                    fail("overlapping/out-of-range catalog read");
                for(S_meta_lane=0;S_meta_lane<16;S_meta_lane=S_meta_lane+1)
                    S_expected_meta[S_meta_lane*8+:8]=S_flash_mem[16+u_demo.S_catalog_request*20+S_meta_lane];
                S_meta_pending=1;
            end
            if(u_demo.S_boot==u_demo.CAT_STORE &&
                (u_demo.S_catalog_phase!=0 || u_demo.S_catalog_start)) fail("catalog read/write overlap");
        end
    end
    always @(posedge S_clk) begin
        if(S_reset) S_buffer_pending=0;
        else begin
            if(S_buffer_pending && u_demo.S_buffer_q!==S_expected_buffer)
                fail("synchronous buffer read differs from immutable Flash bytes");
            S_buffer_pending=0;
            if(u_demo.S_buffer_boot_read || u_demo.S_buffer_stream_read) begin
                if(u_demo.S_fetch_active || u_demo.S_fetch_offer || u_demo.S_fetch_start ||
                    u_demo.S_buffer_write || (u_demo.S_buffer_boot_read && u_demo.S_buffer_stream_read))
                    fail("buffer read before real backend retirement or read-port conflict");
                if(u_demo.S_buffer_address>=u_demo.O_flash_length) fail("buffer read past fetched payload");
                S_expected_buffer=S_flash_mem[u_demo.S_fetch_address-32'h100000+u_demo.S_buffer_address];
                S_buffer_pending=1;
            end
            if(u_demo.S_boot==u_demo.HEADER_CHECK)
                for(S_header_lane=0;S_header_lane<16;S_header_lane=S_header_lane+1)
                    if(u_demo.S_header[S_header_lane*8+:8]!==S_flash_mem[S_header_lane])
                        fail("fixed header snapshot did not follow accepted bytes");
        end
    end
    initial begin
        build_pack(); repeat(5) @(negedge S_clk); S_reset=0;
        mount(); open_file("/PLAY/PLAYLIST.TXT",18,64); read_file(64);
        if({S_received[0],S_received[1],S_received[2],S_received[3],S_received[4],S_received[5]}!=="[ITEM]" ||
            {S_received[13],S_received[14],S_received[15],S_received[16]}!=="D000" ||
            {S_received[29],S_received[30],S_received[31],S_received[32]}!=="D001") fail("paired image/audio playlist");
        open_file("/D000.RLE",9,22); read_file(22);
        if({S_received[0],S_received[1],S_received[2],S_received[3]}!=="RLE1") fail("RLE bytes not from Flash");
        open_file("/D001.WAV",9,52); read_file(52);
        if({S_received[0],S_received[1],S_received[2],S_received[3]}!=="RIFF") fail("WAV bytes not from Flash");
        // Exercise cancellation at the actual sector endpoint without forcing state.
        @(negedge S_clk); S_manual=1; S_lba=33054; S_request=1; S_phy_hold=1;
        while(!S_demo_O_request_ready) @(negedge S_clk);
        @(negedge S_clk); S_request=0;
        wait(S_bridge_O_flash_valid);
        @(negedge S_clk); S_cancel=1;
        while(!S_demo_O_cancel_ready) @(negedge S_clk);
        @(negedge S_clk); S_cancel=0;
        wait(S_phy_done); repeat(12) @(negedge S_clk);
        if(S_demo_O_done_valid || S_demo_O_cancel_done_valid || S_demo_O_byte_valid)
            fail("cancellation fabricated backend retirement");
        S_phy_hold=0;
        wait(S_demo_O_done_valid && S_demo_O_cancel_done_valid);
        if(S_demo_O_done_error!=7 || S_demo_O_done_tag!=16'h55aa || S_demo_O_cancel_done_tag!=16'h55aa)
            fail("cancel terminal identity");
        @(negedge S_clk); S_done_ready=1; S_cancel_done_ready=1;
        @(negedge S_clk); S_done_ready=0; S_cancel_done_ready=0;
        wait(S_demo_O_quiescent);
        // A late cancel accepted alongside an already-held done must not hang.
        @(negedge S_clk); S_lba=0; S_request=1; S_byte_ready=1;
        while(!S_demo_O_request_ready) @(negedge S_clk);
        @(negedge S_clk); S_request=0;
        wait(S_demo_O_done_valid);
        @(negedge S_clk); S_done_ready=1; S_cancel=1;
        if(!S_demo_O_cancel_ready) fail("held-terminal cancel backpressure");
        @(negedge S_clk); S_done_ready=0; S_cancel=0; S_byte_ready=0;
        wait(S_demo_O_cancel_done_valid);
        if(S_demo_O_cancel_done_tag!=16'h55aa) fail("held-terminal cancel identity");
        @(negedge S_clk); S_cancel_done_ready=1;
        @(negedge S_clk); S_cancel_done_ready=0;
        wait(S_demo_O_quiescent);
        // A valid table with one corrupt payload cannot be exposed as mounted media.
        @(negedge S_clk); S_reset=1; S_flash_mem[84]=S_flash_mem[84]^8'h01;
        repeat(5) @(negedge S_clk); S_reset=0; wait(S_demo_O_error!=0);
        if(S_demo_O_error!=5 || S_demo_O_ready) fail("payload CRC was not enforced before catalog ready");
        // Maximum catalog: all 64 pairs, final index127, eight list clusters.
        @(negedge S_clk); S_reset=1; S_manual=0; build_catalog(64,1);
        repeat(5) @(negedge S_clk); S_reset=0;
        mount(); open_file("/PLAY/PLAYLIST.TXT",18,4096); read_file(4096);
        for(S_i=0;S_i<4096;S_i=S_i+1)
            if(S_received[S_i]!==expected_list_byte(S_i,64,1)) fail("maximum paired list file golden bytes");
        open_file("/D07F.WAV",9,1); read_file(1);
        if(S_received[0]!==S_flash_mem[4096+127]) fail("last catalog record offset/size/CRC lane mapping");
        cancel_list_prepare(0); cancel_list_prepare(1);
        cancel_catalog_read(0); cancel_catalog_read(1); cancel_catalog_read(2);
        read_meta_sector(32800,128,64); read_meta_sector(32804,128,64); read_meta_sector(32808,128,64);
        read_meta_sector(34,128,64); read_meta_sector(34+127*128,128,64);
        read_list_sector(0,8,64,1);
        // Rebuild a shorter unpaired catalog over retained RAM. Check the ninth
        // item, its sector padding, and a wholly stale old list sector.
        @(negedge S_clk); S_reset=1; S_manual=0; build_catalog(9,0);
        repeat(5) @(negedge S_clk); S_reset=0;
        mount(); open_file("/PLAY/PLAYLIST.TXT",18,576); read_file(576);
        for(S_i=0;S_i<576;S_i=S_i+1)
            if(S_received[S_i]!==expected_list_byte(S_i,9,0)) fail("unpaired list after shorter rebuild");
        read_list_sector(1,1,9,0); read_list_sector(2,1,9,0);
        read_meta_sector(32800,9,9); read_meta_sector(32808,9,9);
        read_meta_sector(34+127*128,9,9); // valid old index is now outside the catalog
        // Full 16-bit IDs must distinguish these two pairs despite equal low bytes.
        @(negedge S_clk); S_reset=1; S_manual=0; build_catalog(2,1);
        put32(16,32'h01000001); put32(36,32'h00000001);
        put32(56,32'h00000002); put32(76,32'h01000002); put32(12,crc_range(16,80));
        repeat(5) @(negedge S_clk); S_reset=0;
        mount(); open_file("/PLAY/PLAYLIST.TXT",18,128); read_file(128);
        for(S_i=0;S_i<128;S_i=S_i+1)
            if(S_received[S_i]!==expected_list_byte(S_i,2,1)) fail("full-width ID pairing");
        // Fresh CRC-correct tables isolate duplicate, overlap and orphan checks.
        @(negedge S_clk); S_reset=1; build_catalog(2,0); put32(36,1); put32(12,crc_range(16,40));
        reject_catalog(3);
        build_catalog(2,0); put32(40,4096); put32(12,crc_range(16,40)); reject_catalog(3);
        build_catalog(1,1); put32(36,32'h00010002); put32(12,crc_range(16,40)); reject_catalog(6);
        // Mixed full/partial fetches, byte stalls, padding, and cancellation of
        // the first/intermediate/final byte preparation must all be reusable.
        build_buffer_pack(); repeat(5) @(negedge S_clk); S_reset=0;
        mount(); open_file("/D000.RLE",9,1025); read_file(1025);
        for(S_i=0;S_i<1025;S_i=S_i+1)
            if(S_received[S_i]!==S_flash_mem[4096+S_i]) fail("1025-byte file through real FAT reader");
        open_file("/D001.WAV",9,513); read_file(513);
        for(S_i=0;S_i<513;S_i=S_i+1)
            if(S_received[S_i]!==S_flash_mem[8192+S_i]) fail("513-byte file through real FAT reader");
        cancel_buffer_prepare(0); cancel_buffer_prepare(1); cancel_buffer_prepare(511);
        read_asset_sectors(0,0,3,1025); read_asset_sectors(1,0,2,513);
        read_asset_sectors(0,1536,1,1025); // old RAM contents beyond EOF remain invisible
        @(negedge S_clk); S_reset=1; build_buffer_pack(); S_flash_mem[4096+512]=S_flash_mem[4096+512]^1;
        reject_catalog(5);
        build_buffer_pack(); S_flash_mem[4096+1024]=S_flash_mem[4096+1024]^1; reject_catalog(5);
        S_test_pass=1; $display("PASS DEM1 CRC, synchronous catalog/buffer, FAT/list, stalls, cancels and shorter rebuild"); $finish;
    end
    initial begin #30000000; fail("watchdog"); end
endmodule
