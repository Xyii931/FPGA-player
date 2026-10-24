`timescale 1ns/1ps
// Actual recovery catalog and FAT32 core. Raw SD sectors are an explicit endpoint.
// No physical SPI/SD/fragment recovery, SDRAM, image decoder or hardware evidence.
module tb_raw_recovery;
    reg S_clk=0,S_reset=1,S_enable=1,S_card=1,S_test_pass=0;
    always #4 S_clk=~S_clk;
    reg S_core_I_clk=0;
    reg S_core_I_reset=0;
    reg S_core_I_card_ready=0;
    reg S_core_I_unmount=0;
    reg [32:0] S_core_I_capacity_sectors=0;
    reg S_core_I_mount_valid=0;
    wire S_core_O_mount_ready;
    wire S_core_O_mount_result_valid;
    reg S_core_I_mount_result_ready=0;
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
    reg S_core_I_enum_valid=0;
    wire S_core_O_enum_ready;
    reg [15:0] S_core_I_enum_tag=0;
    reg [6:0] S_core_I_enum_path_length=0;
    reg [31:0] S_core_I_enum_sector_budget=0;
    reg S_core_I_enum_path_valid=0;
    wire S_core_O_enum_path_ready;
    reg [7:0] S_core_I_enum_path_data=0;
    reg S_core_I_enum_path_last=0;
    reg S_core_I_enum_stop=0;
    reg S_core_I_enum_cancel=0;
    wire S_core_O_enum_entry_valid;
    reg S_core_I_enum_entry_ready=0;
    wire [7:0] S_core_O_enum_attr;
    wire [31:0] S_core_O_enum_size;
    wire [31:0] S_core_O_enum_first_cluster;
    wire [87:0] S_core_O_enum_alias;
    wire [6:0] S_core_O_enum_name_length;
    wire S_core_O_enum_is_lfn;
    wire S_core_O_enum_name_valid;
    reg S_core_I_enum_name_ready=0;
    wire [7:0] S_core_O_enum_name_data;
    wire S_core_O_enum_name_last;
    wire S_core_O_enum_done_valid;
    reg S_core_I_enum_done_ready=0;
    wire [15:0] S_core_O_enum_tag;
    wire [31:0] S_core_O_enum_generation;
    wire [31:0] S_core_O_enum_sectors;
    wire [2:0] S_core_O_enum_warning;
    wire [7:0] S_core_O_enum_error;
    wire [3:0] S_core_O_enum_storage_error;
    reg S_core_I_open_valid=0;
    wire S_core_O_open_ready;
    reg [1:0] S_core_I_open_context=0;
    reg [15:0] S_core_I_open_tag=0;
    reg [6:0] S_core_I_path_length=0;
    reg [31:0] S_core_I_sector_budget=0;
    reg S_core_I_path_valid=0;
    wire S_core_O_path_ready;
    reg [7:0] S_core_I_path_data=0;
    reg S_core_I_path_last=0;
    reg S_core_I_open_cancel=0;
    wire S_core_O_open_result_valid;
    reg S_core_I_open_result_ready=0;
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
    reg S_core_I_close_valid=0;
    wire S_core_O_close_ready;
    reg [1:0] S_core_I_close_context=0;
    reg S_core_I_read_valid=0;
    wire S_core_O_read_ready;
    reg [1:0] S_core_I_read_context=0;
    reg [1:0] S_core_I_read_priority=0;
    reg [31:0] S_core_I_offset=0;
    reg [31:0] S_core_I_length=0;
    reg [15:0] S_core_I_epoch=0;
    reg [2:0] S_core_I_urgent_context=0;
    wire S_core_O_byte_valid;
    reg S_core_I_byte_ready=0;
    wire [7:0] S_core_O_byte_data;
    wire [1:0] S_core_O_byte_context;
    wire [15:0] S_core_O_byte_epoch;
    wire [31:0] S_core_O_byte_offset;
    wire S_core_O_byte_last;
    wire S_core_O_done_valid;
    reg S_core_I_done_ready=0;
    wire [1:0] S_core_O_done_context;
    wire [15:0] S_core_O_done_epoch;
    wire [31:0] S_core_O_done_bytes;
    wire S_core_O_done_eof;
    wire [7:0] S_core_O_done_error;
    wire [3:0] S_core_O_done_storage_error;
    reg S_core_I_cancel_valid=0;
    wire S_core_O_cancel_ready;
    reg [1:0] S_core_I_cancel_context=0;
    reg [15:0] S_core_I_cancel_epoch=0;
    wire S_core_O_cancel_done_valid;
    reg S_core_I_cancel_done_ready=0;
    wire [1:0] S_core_O_cancel_done_context;
    wire [15:0] S_core_O_cancel_done_epoch;
    wire S_core_O_sd_request_valid;
    reg S_core_I_sd_request_ready=0;
    wire [31:0] S_core_O_sd_lba;
    wire [7:0] S_core_O_sd_count;
    wire [1:0] S_core_O_sd_context;
    wire [1:0] S_core_O_sd_priority;
    wire [15:0] S_core_O_sd_tag;
    reg S_core_I_sd_byte_valid=0;
    wire S_core_O_sd_byte_ready;
    reg [7:0] S_core_I_sd_byte_data=0;
    reg S_core_I_sd_sector_last=0;
    reg S_core_I_sd_request_last=0;
    reg [1:0] S_core_I_sd_byte_context=0;
    reg [15:0] S_core_I_sd_byte_tag=0;
    reg S_core_I_sd_done_valid=0;
    wire S_core_O_sd_done_ready;
    reg [1:0] S_core_I_sd_done_context=0;
    reg [15:0] S_core_I_sd_done_tag=0;
    reg [3:0] S_core_I_sd_done_error=0;
    wire S_core_O_sd_cancel_valid;
    reg S_core_I_sd_cancel_ready=0;
    wire [1:0] S_core_O_sd_cancel_context;
    wire [15:0] S_core_O_sd_cancel_tag;
    reg S_core_I_sd_cancel_done_valid=0;
    wire S_core_O_sd_cancel_done_ready;
    reg [1:0] S_core_I_sd_cancel_done_context=0;
    reg [15:0] S_core_I_sd_cancel_done_tag=0;
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
    demo_sector_source #(.RECOVERY(1),.RECOVERY_SECTORS(16)) u_demo (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_recovery_enable(S_enable),
        .I_raw_card_ready(S_card),
        .O_raw_request_valid(S_demo_O_raw_request_valid),
        .I_raw_request_ready(!S_raw_active && !S_raw_done),
        .O_raw_lba(S_demo_O_raw_lba),
        .O_raw_tag(S_demo_O_raw_tag),
        .I_raw_byte_valid(S_raw_active),
        .O_raw_byte_ready(S_demo_O_raw_byte_ready),
        .I_raw_byte_data(S_disk[{S_raw_sector[3:0],S_raw_byte}]),
        .I_raw_sector_last(S_raw_byte==9'd511),
        .I_raw_request_last(S_raw_byte==9'd511),
        .I_raw_byte_tag(S_raw_tag),
        .I_raw_done_valid(S_raw_done && S_terminal_delay==0),
        .O_raw_done_ready(S_demo_O_raw_done_ready),
        .I_raw_done_error(S_raw_sector==5 ? 4'd2 : 4'd0),
        .I_raw_done_tag(S_raw_tag),
        .O_ready(S_demo_O_ready),
        .O_error(S_demo_O_error),
        .O_flash_valid(S_demo_O_flash_valid),
        .I_flash_ready(1'b0),
        .O_flash_address(S_demo_O_flash_address),
        .O_flash_length(S_demo_O_flash_length),
        .I_flash_byte_valid(1'b0),
        .O_flash_byte_ready(S_demo_O_flash_byte_ready),
        .I_flash_byte_data(8'd0),
        .I_flash_byte_last(1'b0),
        .I_flash_done_valid(1'b0),
        .O_flash_done_ready(S_demo_O_flash_done_ready),
        .I_flash_error(4'd0),
        .I_request_valid(S_core_O_sd_request_valid),
        .O_request_ready(S_demo_O_request_ready),
        .I_lba(S_core_O_sd_lba),
        .I_count(S_core_O_sd_count),
        .I_context(S_core_O_sd_context),
        .I_tag(S_core_O_sd_tag),
        .O_byte_valid(S_demo_O_byte_valid),
        .I_byte_ready(S_core_O_sd_byte_ready),
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
        .I_done_ready(S_core_O_sd_done_ready),
        .O_done_error(S_demo_O_done_error),
        .I_cancel_valid(S_core_O_sd_cancel_valid),
        .O_cancel_ready(S_demo_O_cancel_ready),
        .I_cancel_context(S_core_O_sd_cancel_context),
        .I_cancel_tag(S_core_O_sd_cancel_tag),
        .O_cancel_done_valid(S_demo_O_cancel_done_valid),
        .I_cancel_done_ready(S_core_O_sd_cancel_done_ready),
        .O_quiescent(S_demo_O_quiescent)
    );
    reg [7:0] S_disk[0:8191];
    reg S_raw_active=0,S_raw_done=0;
    reg [31:0] S_raw_sector=0;
    reg [8:0] S_raw_byte=0;
    reg [15:0] S_raw_tag=0;
    reg [7:0] S_received[0:1023];
    integer S_i,S_read_count=0,S_requests=0,S_terminal_delay=0;
    reg S_initial_scan=1;
    task fail;
        input [767:0] text;
        begin $display("FAIL raw_recovery: %0s",text); $stop; end
    endtask
    // Hold each byte until actual acceptance, then delay the real terminal.
    always @(posedge S_clk) begin
        if(S_reset) begin S_raw_active<=0; S_raw_done<=0; S_terminal_delay<=0; end
        else begin
            if(S_demo_O_raw_request_valid && !S_raw_active && !S_raw_done) begin
                if(S_demo_O_raw_lba>=16) fail("raw read exceeded configured scan/file bound");
                S_raw_sector<=S_demo_O_raw_lba; S_raw_tag<=S_demo_O_raw_tag;
                S_raw_byte<=0; S_raw_active<=1; S_requests=S_requests+1;
            end
            if(S_raw_active && S_demo_O_raw_byte_ready) begin
                if(S_raw_byte==511) begin S_raw_active<=0; S_raw_done<=1; S_terminal_delay<=9; end
                else S_raw_byte<=S_raw_byte+1'b1;
            end
            if(S_terminal_delay!=0) S_terminal_delay<=S_terminal_delay-1;
            if(S_raw_done && S_terminal_delay==0 && S_demo_O_raw_done_ready) S_raw_done<=0;
            if(S_initial_scan && S_raw_sector==5 && S_demo_O_ready) fail("catalog published before failed candidate retired");
        end
    end
    task put32;
        input integer at;
        input [31:0] value;
        begin S_disk[at]=value[7:0]; S_disk[at+1]=value[15:8]; S_disk[at+2]=value[23:16]; S_disk[at+3]=value[31:24]; end
    endtask
    task bmp;
        input integer sector,height;
        integer at;
        begin
            at=sector*512; S_disk[at]="B"; S_disk[at+1]="M";
            put32(at+2,54+8*height); put32(at+10,54); put32(at+14,40);
            put32(at+18,2); put32(at+22,height); put32(at+26,32'h00180001);
            put32(at+34,8*height); S_disk[at+54]=8'h13; S_disk[at+55]=8'h57;
        end
    endtask
    task mount;
        begin
            wait(S_demo_O_ready || S_demo_O_error!=0);
            if(S_demo_O_error!=0) fail("recovery rejected valid readable candidates");
            S_initial_scan=0;
            @(negedge S_clk); S_core_I_mount_valid=1;
            while(!S_core_O_mount_ready) @(negedge S_clk);
            @(negedge S_clk); S_core_I_mount_valid=0;
            wait(S_core_O_mount_result_valid);
            if(S_core_O_mount_error!=0 || !S_core_O_mounted) fail("recovery virtual FAT mount");
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
            if(S_core_O_open_error!=0 || S_core_O_open_size!=size) fail("recovered alias/size or failed candidate inclusion");
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
                fail("recovered file byte/EOF completion");
            @(negedge S_clk); S_core_I_done_ready=1; S_core_I_byte_ready=0;
            @(negedge S_clk); S_core_I_done_ready=0; S_core_I_close_context=0; S_core_I_close_valid=1;
            while(!S_core_O_close_ready) @(negedge S_clk);
            @(negedge S_clk); S_core_I_close_valid=0;
        end
    endtask
    always @(posedge S_clk) if(!S_reset && S_core_O_byte_valid && S_core_I_byte_ready) begin
        if(S_core_O_byte_offset!=S_read_count || S_core_O_byte_epoch!=S_core_I_epoch ||
            S_core_O_byte_generation!=S_core_O_generation) fail("recovery FAT descriptor identity");
        S_received[S_read_count]=S_core_O_byte_data; S_read_count=S_read_count+1;
    end
    initial begin
        for(S_i=0;S_i<8192;S_i=S_i+1) S_disk[S_i]=0;
        bmp(2,1); bmp(4,100); bmp(7,100);
        // Oversized declared file must never overlap the next virtual asset window.
        bmp(10,1); put32(5120+2,32'd8388609);
        S_disk[7*512+600]=8'hac;
        repeat(5) @(negedge S_clk); S_reset=0;
        mount(); open_file("/PLAY/PLAYLIST.TXT",18,128); read_file(128);
        if({S_received[18],S_received[19],S_received[20]}!=="BMP" ||
            {S_received[77],S_received[78],S_received[79],S_received[80]}!=="D001") fail("recovery playlist excludes failed candidate");
        open_file("/D000.BMP",9,62); read_file(62);
        if({S_received[0],S_received[1]}!=="BM" || S_received[54]!=8'h13) fail("first recovered BMP bytes");
        open_file("/D001.BMP",9,854); read_file(854);
        if(S_received[600]!=8'hac) fail("continuous second sector did not map to raw disk");
        // Dropped card withdraws ready; real backend must drain before rearming.
        @(negedge S_clk); S_card=0;
        @(negedge S_clk); if(S_demo_O_ready) fail("removed card kept recovered directory online");
        wait(S_demo_O_quiescent); repeat(5) @(negedge S_clk);
        S_enable=0; S_card=1; repeat(5) @(negedge S_clk);
        S_i=S_requests; S_enable=1;
        wait(S_demo_O_raw_request_valid);
        if(S_demo_O_raw_lba!=0) fail("recovery restart did not rescan from sector zero");
        wait(S_requests>S_i); @(negedge S_clk); S_enable=0;
        wait(S_demo_O_quiescent);
        if(S_raw_active || S_raw_done || S_demo_O_ready) fail("recovery mode exit bypassed backend drain");
        S_test_pass=1; $display("PASS recovery scan/read failures/virtual FAT/bounds/removal/drain"); $finish;
    end
    initial begin #30000000; fail("watchdog"); end
endmodule
