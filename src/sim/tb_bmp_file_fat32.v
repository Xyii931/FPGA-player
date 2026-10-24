`timescale 1ns/1ps
// Real source/parser; real FAT32 core, only SD host sectors are fixtures.
module tb_bmp_file_fat32;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    wire  S_I_media_valid;
    wire [31:0] S_I_media_generation;
    reg  S_I_start_valid=0;
    wire  S_O_start_ready;
    wire  S_O_lease_request;
    reg  S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_sector_budget=0;
    reg [6:0] S_I_path_length=0;
    reg  S_I_path_valid=0;
    wire  S_O_path_ready;
    reg [7:0] S_I_path_data=0;
    reg  S_I_path_last=0;
    reg  S_I_abort=0;
    wire  S_O_lease_active;
    wire  S_O_busy;
    wire  S_O_done_valid;
    reg  S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [3:0] S_O_parser_error;
    wire [7:0] S_O_file_error;
    wire [3:0] S_O_storage_error;
    wire [2:0] S_O_path_warning;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_file_size;
    wire  S_O_parser_started;
    wire  S_O_header_valid;
    reg  S_I_header_ready=0;
    wire [15:0] S_O_width;
    wire [15:0] S_O_height;
    wire  S_O_bottom_up;
    wire [5:0] S_O_bpp;
    wire [31:0] S_O_pixel_offset;
    wire [31:0] S_O_row_bytes;
    wire  S_O_pixel_valid;
    reg  S_I_pixel_ready=0;
    wire [31:0] S_O_rgba;
    wire [15:0] S_O_x;
    wire [15:0] S_O_y;
    wire  S_O_pixel_last;
    wire  S_O_fs_open_valid;
    wire  S_I_fs_open_ready;
    wire [1:0] S_O_fs_open_context;
    wire [15:0] S_O_fs_open_tag;
    wire [6:0] S_O_fs_path_length;
    wire [31:0] S_O_fs_sector_budget;
    wire  S_O_fs_path_valid;
    wire  S_I_fs_path_ready;
    wire [7:0] S_O_fs_path_data;
    wire  S_O_fs_path_last;
    wire  S_O_fs_open_cancel;
    wire  S_I_fs_open_result_valid;
    wire  S_O_fs_open_result_ready;
    wire [1:0] S_I_fs_open_context;
    wire [15:0] S_I_fs_open_tag;
    wire [31:0] S_I_fs_open_generation;
    wire [31:0] S_I_fs_open_size;
    wire [7:0] S_I_fs_open_error;
    wire [3:0] S_I_fs_open_storage_error;
    wire [2:0] S_I_fs_open_warning;
    wire  S_O_fs_read_valid;
    wire  S_I_fs_read_ready;
    wire [1:0] S_O_fs_read_context;
    wire [1:0] S_O_fs_read_priority;
    wire [31:0] S_O_fs_offset;
    wire [31:0] S_O_fs_length;
    wire [15:0] S_O_fs_epoch;
    wire  S_I_fs_byte_valid;
    wire  S_O_fs_byte_ready;
    wire [7:0] S_I_fs_byte_data;
    wire [1:0] S_I_fs_byte_context;
    wire [15:0] S_I_fs_byte_epoch;
    wire [31:0] S_I_fs_byte_generation;
    wire [31:0] S_I_fs_byte_offset;
    wire  S_I_fs_byte_last;
    wire  S_I_fs_done_valid;
    wire  S_O_fs_done_ready;
    wire [1:0] S_I_fs_done_context;
    wire [15:0] S_I_fs_done_epoch;
    wire [31:0] S_I_fs_done_generation;
    wire [31:0] S_I_fs_done_bytes;
    wire  S_I_fs_done_eof;
    wire [7:0] S_I_fs_done_error;
    wire [3:0] S_I_fs_done_storage_error;
    wire  S_O_fs_cancel_valid;
    wire  S_I_fs_cancel_ready;
    wire [1:0] S_O_fs_cancel_context;
    wire [15:0] S_O_fs_cancel_epoch;
    wire  S_I_fs_cancel_done_valid;
    wire  S_O_fs_cancel_done_ready;
    wire [1:0] S_I_fs_cancel_done_context;
    wire [15:0] S_I_fs_cancel_done_epoch;
    wire [31:0] S_I_fs_cancel_done_generation;
    wire  S_O_fs_close_valid;
    wire  S_I_fs_close_ready;
    wire [1:0] S_O_fs_close_context;
    bmp_file_source u_source (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_sector_budget(S_I_sector_budget),
        .I_path_length(S_I_path_length),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
        .I_abort(S_I_abort),
        .O_lease_active(S_O_lease_active),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_parser_error(S_O_parser_error),
        .O_file_error(S_O_file_error),
        .O_storage_error(S_O_storage_error),
        .O_path_warning(S_O_path_warning),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_file_size(S_O_file_size),
        .O_parser_started(S_O_parser_started),
        .O_header_valid(S_O_header_valid),
        .I_header_ready(S_I_header_ready),
        .O_width(S_O_width),
        .O_height(S_O_height),
        .O_bottom_up(S_O_bottom_up),
        .O_bpp(S_O_bpp),
        .O_pixel_offset(S_O_pixel_offset),
        .O_row_bytes(S_O_row_bytes),
        .O_pixel_valid(S_O_pixel_valid),
        .I_pixel_ready(S_I_pixel_ready),
        .O_rgba(S_O_rgba),
        .O_x(S_O_x),
        .O_y(S_O_y),
        .O_pixel_last(S_O_pixel_last),
        .O_fs_open_valid(S_O_fs_open_valid),
        .I_fs_open_ready(S_I_fs_open_ready),
        .O_fs_open_context(S_O_fs_open_context),
        .O_fs_open_tag(S_O_fs_open_tag),
        .O_fs_path_length(S_O_fs_path_length),
        .O_fs_sector_budget(S_O_fs_sector_budget),
        .O_fs_path_valid(S_O_fs_path_valid),
        .I_fs_path_ready(S_I_fs_path_ready),
        .O_fs_path_data(S_O_fs_path_data),
        .O_fs_path_last(S_O_fs_path_last),
        .O_fs_open_cancel(S_O_fs_open_cancel),
        .I_fs_open_result_valid(S_I_fs_open_result_valid),
        .O_fs_open_result_ready(S_O_fs_open_result_ready),
        .I_fs_open_context(S_I_fs_open_context),
        .I_fs_open_tag(S_I_fs_open_tag),
        .I_fs_open_generation(S_I_fs_open_generation),
        .I_fs_open_size(S_I_fs_open_size),
        .I_fs_open_error(S_I_fs_open_error),
        .I_fs_open_storage_error(S_I_fs_open_storage_error),
        .I_fs_open_warning(S_I_fs_open_warning),
        .O_fs_read_valid(S_O_fs_read_valid),
        .I_fs_read_ready(S_I_fs_read_ready),
        .O_fs_read_context(S_O_fs_read_context),
        .O_fs_read_priority(S_O_fs_read_priority),
        .O_fs_offset(S_O_fs_offset),
        .O_fs_length(S_O_fs_length),
        .O_fs_epoch(S_O_fs_epoch),
        .I_fs_byte_valid(S_I_fs_byte_valid),
        .O_fs_byte_ready(S_O_fs_byte_ready),
        .I_fs_byte_data(S_I_fs_byte_data),
        .I_fs_byte_context(S_I_fs_byte_context),
        .I_fs_byte_epoch(S_I_fs_byte_epoch),
        .I_fs_byte_generation(S_I_fs_byte_generation),
        .I_fs_byte_offset(S_I_fs_byte_offset),
        .I_fs_byte_last(S_I_fs_byte_last),
        .I_fs_done_valid(S_I_fs_done_valid),
        .O_fs_done_ready(S_O_fs_done_ready),
        .I_fs_done_context(S_I_fs_done_context),
        .I_fs_done_epoch(S_I_fs_done_epoch),
        .I_fs_done_generation(S_I_fs_done_generation),
        .I_fs_done_bytes(S_I_fs_done_bytes),
        .I_fs_done_eof(S_I_fs_done_eof),
        .I_fs_done_error(S_I_fs_done_error),
        .I_fs_done_storage_error(S_I_fs_done_storage_error),
        .O_fs_cancel_valid(S_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_I_fs_cancel_ready),
        .O_fs_cancel_context(S_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(S_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(S_I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(S_I_fs_cancel_done_generation),
        .O_fs_close_valid(S_O_fs_close_valid),
        .I_fs_close_ready(S_I_fs_close_ready),
        .O_fs_close_context(S_O_fs_close_context)
    );
    always #4 S_I_clk=~S_I_clk;
    reg  S_F_I_card_ready=0;
    reg  S_F_I_unmount=0;
    reg  S_F_I_mount_valid=0;
    wire  S_F_O_mount_ready;
    wire  S_F_O_mount_result_valid;
    reg  S_F_I_mount_result_ready=0;
    wire [7:0] S_F_O_mount_error;
    wire [3:0] S_F_O_mount_storage_error;
    wire [31:0] S_F_O_mount_generation;
    wire  S_F_O_quiescent;
    wire [31:0] S_F_O_partition_lba;
    wire [31:0] S_F_O_volume_sectors;
    wire [31:0] S_F_O_fat_lba;
    wire [31:0] S_F_O_data_lba;
    wire [31:0] S_F_O_cluster_count;
    wire [31:0] S_F_O_root_cluster;
    wire [7:0] S_F_O_sectors_per_cluster;
    wire [2:0] S_F_O_cluster_shift;
    wire [31:0] S_F_O_open_first_cluster;
    wire [31:0] S_F_O_open_sectors;
    wire [7:0] S_F_O_open_attr;
    wire  S_F_O_sd_request_valid;
    reg  S_F_I_sd_request_ready=0;
    wire [31:0] S_F_O_sd_lba;
    wire [7:0] S_F_O_sd_count;
    wire [1:0] S_F_O_sd_context;
    wire [1:0] S_F_O_sd_priority;
    wire [15:0] S_F_O_sd_tag;
    reg  S_F_I_sd_byte_valid=0;
    wire  S_F_O_sd_byte_ready;
    reg [7:0] S_F_I_sd_byte_data=0;
    reg  S_F_I_sd_sector_last=0;
    reg  S_F_I_sd_request_last=0;
    reg [1:0] S_F_I_sd_byte_context=0;
    reg [15:0] S_F_I_sd_byte_tag=0;
    reg  S_F_I_sd_done_valid=0;
    wire  S_F_O_sd_done_ready;
    reg [1:0] S_F_I_sd_done_context=0;
    reg [15:0] S_F_I_sd_done_tag=0;
    reg [3:0] S_F_I_sd_done_error=0;
    wire  S_F_O_sd_cancel_valid;
    reg  S_F_I_sd_cancel_ready=0;
    wire [1:0] S_F_O_sd_cancel_context;
    wire [15:0] S_F_O_sd_cancel_tag;
    reg  S_F_I_sd_cancel_done_valid=0;
    wire  S_F_O_sd_cancel_done_ready;
    reg [1:0] S_F_I_sd_cancel_done_context=0;
    reg [15:0] S_F_I_sd_cancel_done_tag=0;
    fat32_core u_files (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_card_ready(S_F_I_card_ready),
        .I_unmount(S_F_I_unmount),
        .I_capacity_sectors(33'd100000),
        .I_mount_valid(S_F_I_mount_valid),
        .O_mount_ready(S_F_O_mount_ready),
        .O_mount_result_valid(S_F_O_mount_result_valid),
        .I_mount_result_ready(S_F_I_mount_result_ready),
        .O_mount_error(S_F_O_mount_error),
        .O_mount_storage_error(S_F_O_mount_storage_error),
        .O_mount_generation(S_F_O_mount_generation),
        .O_mounted(S_I_media_valid),
        .O_quiescent(S_F_O_quiescent),
        .O_generation(S_I_media_generation),
        .O_partition_lba(S_F_O_partition_lba),
        .O_volume_sectors(S_F_O_volume_sectors),
        .O_fat_lba(S_F_O_fat_lba),
        .O_data_lba(S_F_O_data_lba),
        .O_cluster_count(S_F_O_cluster_count),
        .O_root_cluster(S_F_O_root_cluster),
        .O_sectors_per_cluster(S_F_O_sectors_per_cluster),
        .O_cluster_shift(S_F_O_cluster_shift),
        .I_enum_valid(1'd0),
        .O_enum_ready(),
        .I_enum_tag(16'd0),
        .I_enum_path_length(7'd0),
        .I_enum_sector_budget(32'd0),
        .I_enum_path_valid(1'd0),
        .O_enum_path_ready(),
        .I_enum_path_data(8'd0),
        .I_enum_path_last(1'd0),
        .I_enum_stop(1'd0),
        .I_enum_cancel(1'd0),
        .O_enum_entry_valid(),
        .I_enum_entry_ready(1'd0),
        .O_enum_attr(),
        .O_enum_size(),
        .O_enum_first_cluster(),
        .O_enum_alias(),
        .O_enum_name_length(),
        .O_enum_is_lfn(),
        .O_enum_name_valid(),
        .I_enum_name_ready(1'd0),
        .O_enum_name_data(),
        .O_enum_name_last(),
        .O_enum_done_valid(),
        .I_enum_done_ready(1'd0),
        .O_enum_tag(),
        .O_enum_generation(),
        .O_enum_sectors(),
        .O_enum_warning(),
        .O_enum_error(),
        .O_enum_storage_error(),
        .I_open_valid(S_O_fs_open_valid),
        .O_open_ready(S_I_fs_open_ready),
        .I_open_context(S_O_fs_open_context),
        .I_open_tag(S_O_fs_open_tag),
        .I_path_length(S_O_fs_path_length),
        .I_sector_budget(S_O_fs_sector_budget),
        .I_path_valid(S_O_fs_path_valid),
        .O_path_ready(S_I_fs_path_ready),
        .I_path_data(S_O_fs_path_data),
        .I_path_last(S_O_fs_path_last),
        .I_open_cancel(S_O_fs_open_cancel),
        .O_open_result_valid(S_I_fs_open_result_valid),
        .I_open_result_ready(S_O_fs_open_result_ready),
        .O_open_context(S_I_fs_open_context),
        .O_open_tag(S_I_fs_open_tag),
        .O_open_generation(S_I_fs_open_generation),
        .O_open_size(S_I_fs_open_size),
        .O_open_first_cluster(S_F_O_open_first_cluster),
        .O_open_sectors(S_F_O_open_sectors),
        .O_open_attr(S_F_O_open_attr),
        .O_open_error(S_I_fs_open_error),
        .O_open_storage_error(S_I_fs_open_storage_error),
        .O_open_warning(S_I_fs_open_warning),
        .O_byte_generation(S_I_fs_byte_generation),
        .O_done_generation(S_I_fs_done_generation),
        .O_cancel_done_generation(S_I_fs_cancel_done_generation),
        .I_close_valid(S_O_fs_close_valid),
        .O_close_ready(S_I_fs_close_ready),
        .I_close_context(S_O_fs_close_context),
        .I_read_valid(S_O_fs_read_valid),
        .O_read_ready(S_I_fs_read_ready),
        .I_read_context(S_O_fs_read_context),
        .I_read_priority(S_O_fs_read_priority),
        .I_offset(S_O_fs_offset),
        .I_length(S_O_fs_length),
        .I_epoch(S_O_fs_epoch),
        .I_urgent_context(3'd0),
        .O_byte_valid(S_I_fs_byte_valid),
        .I_byte_ready(S_O_fs_byte_ready),
        .O_byte_data(S_I_fs_byte_data),
        .O_byte_context(S_I_fs_byte_context),
        .O_byte_epoch(S_I_fs_byte_epoch),
        .O_byte_offset(S_I_fs_byte_offset),
        .O_byte_last(S_I_fs_byte_last),
        .O_done_valid(S_I_fs_done_valid),
        .I_done_ready(S_O_fs_done_ready),
        .O_done_context(S_I_fs_done_context),
        .O_done_epoch(S_I_fs_done_epoch),
        .O_done_bytes(S_I_fs_done_bytes),
        .O_done_eof(S_I_fs_done_eof),
        .O_done_error(S_I_fs_done_error),
        .O_done_storage_error(S_I_fs_done_storage_error),
        .I_cancel_valid(S_O_fs_cancel_valid),
        .O_cancel_ready(S_I_fs_cancel_ready),
        .I_cancel_context(S_O_fs_cancel_context),
        .I_cancel_epoch(S_O_fs_cancel_epoch),
        .O_cancel_done_valid(S_I_fs_cancel_done_valid),
        .I_cancel_done_ready(S_O_fs_cancel_done_ready),
        .O_cancel_done_context(S_I_fs_cancel_done_context),
        .O_cancel_done_epoch(S_I_fs_cancel_done_epoch),
        .O_sd_request_valid(S_F_O_sd_request_valid),
        .I_sd_request_ready(S_F_I_sd_request_ready),
        .O_sd_lba(S_F_O_sd_lba),
        .O_sd_count(S_F_O_sd_count),
        .O_sd_context(S_F_O_sd_context),
        .O_sd_priority(S_F_O_sd_priority),
        .O_sd_tag(S_F_O_sd_tag),
        .I_sd_byte_valid(S_F_I_sd_byte_valid),
        .O_sd_byte_ready(S_F_O_sd_byte_ready),
        .I_sd_byte_data(S_F_I_sd_byte_data),
        .I_sd_sector_last(S_F_I_sd_sector_last),
        .I_sd_request_last(S_F_I_sd_request_last),
        .I_sd_byte_context(S_F_I_sd_byte_context),
        .I_sd_byte_tag(S_F_I_sd_byte_tag),
        .I_sd_done_valid(S_F_I_sd_done_valid),
        .O_sd_done_ready(S_F_O_sd_done_ready),
        .I_sd_done_context(S_F_I_sd_done_context),
        .I_sd_done_tag(S_F_I_sd_done_tag),
        .I_sd_done_error(S_F_I_sd_done_error),
        .O_sd_cancel_valid(S_F_O_sd_cancel_valid),
        .I_sd_cancel_ready(S_F_I_sd_cancel_ready),
        .O_sd_cancel_context(S_F_O_sd_cancel_context),
        .O_sd_cancel_tag(S_F_O_sd_cancel_tag),
        .I_sd_cancel_done_valid(S_F_I_sd_cancel_done_valid),
        .O_sd_cancel_done_ready(S_F_O_sd_cancel_done_ready),
        .I_sd_cancel_done_context(S_F_I_sd_cancel_done_context),
        .I_sd_cancel_done_tag(S_F_I_sd_cancel_done_tag)
    );


    reg S_test_pass=0,S_check_pixels=1,S_top_down=0;
    reg [7:0] S_bmp[0:699];
    integer S_i,S_j,S_case=0,S_pixels=0,S_headers=0,S_reads=0,S_closes=0;
    integer S_bpp=24;
    reg [31:0] S_expected_rgba;
    reg S_pixel_held=0;
    reg [64:0] S_held_pixel;
    task fail;
        input [767:0] message;
        begin $display("FAIL: bmp_file CASE %0d: %0s",S_case,message); $stop; end
    endtask
    task bmp32;
        input integer address;
        input [31:0] value;
        begin
            S_bmp[address]=value; S_bmp[address+1]=value>>8;
            S_bmp[address+2]=value>>16; S_bmp[address+3]=value>>24;
        end
    endtask
    task make_bmp;
        input integer bpp;
        input top_down;
        begin
            S_bpp=bpp; S_top_down=top_down;
            for(S_i=0;S_i<700;S_i=S_i+1) S_bmp[S_i]=0;
            S_bmp[0]="B"; S_bmp[1]="M";
            bmp32(2,700); bmp32(10,510); bmp32(14,40); bmp32(18,3);
            bmp32(22,top_down ? 32'hfffffffe : 32'd2);
            S_bmp[26]=1; S_bmp[28]=bpp; bmp32(34,24);
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                S_j=510+(S_i/3)*12+(S_i%3)*(bpp/8);
                S_bmp[S_j]=8'h30+S_i; S_bmp[S_j+1]=8'h20+S_i; S_bmp[S_j+2]=8'h10+S_i;
                if(bpp==32) S_bmp[S_j+3]=S_i;
            end
            if(bpp==24) begin
                S_bmp[519]=8'hee; S_bmp[520]=8'hee; S_bmp[521]=8'hee;
                S_bmp[531]=8'hee; S_bmp[532]=8'hee; S_bmp[533]=8'hee;
            end
            for(S_i=534;S_i<700;S_i=S_i+1) S_bmp[S_i]=8'ha5;
        end
    endtask
    always @(posedge S_I_clk) begin
        if(S_I_reset) S_pixel_held<=0;
        else begin
            if(S_O_fs_read_valid && S_I_fs_read_ready) begin
                S_reads=S_reads+1;
                if(S_O_fs_offset!==0 || S_O_fs_length!==S_O_file_size ||
                    S_O_fs_epoch!==S_O_tag || S_O_fs_read_context!==S_O_context || S_O_fs_read_priority!==0)
                    fail("read identity/offset/length/priority");
            end
            if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
            if(S_check_pixels) begin
                if(S_O_header_valid && S_I_header_ready) begin
                    S_headers=S_headers+1;
                    if(S_O_width!==3 || S_O_height!==2 || S_O_bpp!==S_bpp ||
                        S_O_bottom_up!==!S_top_down || S_O_pixel_offset!==510 || S_O_row_bytes!==12)
                        fail("header metadata");
                end
                if(S_pixel_held && (!S_O_pixel_valid ||
                    {S_O_rgba,S_O_x,S_O_y,S_O_pixel_last}!==S_held_pixel)) fail("pixel changed under backpressure");
                S_pixel_held<=S_O_pixel_valid && !S_I_pixel_ready;
                S_held_pixel<={S_O_rgba,S_O_x,S_O_y,S_O_pixel_last};
                if(S_O_pixel_valid && S_I_pixel_ready) begin
                    S_expected_rgba={8'h10+S_pixels[7:0],8'h20+S_pixels[7:0],8'h30+S_pixels[7:0],8'hff};
                    if(S_pixels>=6 || S_O_rgba!==S_expected_rgba || S_O_x!==S_pixels%3 ||
                        S_O_y!==(S_top_down ? S_pixels/3 : 1-S_pixels/3) || S_O_pixel_last!==(S_pixels==5))
                        fail("RGBA/normalized coordinate/pixel_last");
                    S_pixels=S_pixels+1;
                end
            end else S_pixel_held<=0;
        end
    end
    task start_source;
        input [1:0] context;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_context=context; S_I_tag=tag;
            S_I_generation=S_I_media_generation; S_I_sector_budget=8; S_I_path_length=9;
            S_I_start_valid=1; S_pixels=0; S_headers=0;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task send_path;
        reg [71:0] path;
        integer k;
        begin
            path="/TEST.BMP";
            for(k=0;k<9;k=k+1) begin
                @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=path[(8-k)*8+:8]; S_I_path_last=k==8;
                @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
            end
            @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_I_abort=1; @(negedge S_I_clk); S_I_abort=0; end
    endtask
    task take_result;
        input [3:0] error;
        reg [105:0] terminal;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || !S_O_lease_active || S_O_start_ready) fail("terminal/lease");
            terminal={S_O_error,S_O_parser_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_parser_started};
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_done_valid || {S_O_error,S_O_parser_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                    S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_parser_started}!==terminal)
                    fail("terminal backpressure");
            end
            S_I_done_ready=1;
            @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_busy) fail("lease release after done acceptance");
        end
    endtask
    initial begin #20000000; fail("watchdog"); end

    reg [7:0] S_disk[0:3071],S_sector[0:511];
    reg [2:0] S_host_state=0;
    reg S_canceled=0,S_cancel_seen=0,S_injected=0;
    reg [31:0] S_fail_lba=32'hffffffff;
    integer S_cycle=0,S_index=0,S_base=0,S_delay=0,S_cancel_acks=0,S_before,k;
    reg [31:0] S_mount_generation=0;
    task copy_bmp;
        begin
            for(k=0;k<700;k=k+1) S_disk[(k<512 ? 2048 : 2560)+(k<512 ? k : k-512)]=S_bmp[k];
        end
    endtask
    task launch;
        input [1:0] context;
        input [15:0] tag;
        begin
            // This single-owner fixture grants only known closed/retired contexts.
            // Hardware must provide a real namespace/context lease arbiter.
            if(u_files.S_descriptors[context] || u_files.S_pending[context] || u_files.S_cancel_busy ||
                u_files.S_open_state!=0) fail("fixture granted an occupied namespace/context");
            start_source(context,tag); send_path;
        end
    endtask
    task finish_real;
        input [3:0] error;
        begin
            wait(S_O_done_valid);
            if(u_files.S_descriptors[S_O_context] || u_files.S_pending[S_O_context] || u_files.S_cancel_busy)
                fail("source done before actual core close/retirement");
            take_result(error);
        end
    endtask
    initial begin
        S_I_reset=1; S_F_I_card_ready=1; S_I_lease_grant=1;
        S_I_header_ready=1; S_I_pixel_ready=1;
        for(S_i=0;S_i<3072;S_i=S_i+1) S_disk[S_i]=0;
        S_disk[0]=8'heb; S_disk[2]=8'h90; put16(11,512); S_disk[13]=1;
        put16(14,32); S_disk[16]=2; put32(32,70000); put32(36,600);
        put32(44,2); put16(510,16'haa55);
        put32(512+2*4,32'h0fffffff); put32(512+4*4,6); put32(512+6*4,32'h0fffffff);
        short_entry(1024,"TEST    BMP",32,4,700);
        make_bmp(24,0); copy_bmp;
        repeat(4) @(negedge S_I_clk); S_I_reset=0;
        mount_card;
        // Fragmented 24bit bottom-up, pixel itself crosses the non-contiguous cluster boundary.
        S_I_header_ready=0; launch(0,16'hffff); wait(S_O_header_valid);
        repeat(8) begin @(negedge S_I_clk); if(S_pixels || S_O_done_valid) fail("header backpressure"); end
        S_I_header_ready=1; S_I_pixel_ready=0; wait(S_O_pixel_valid);
        repeat(8) @(negedge S_I_clk); S_I_pixel_ready=1;
        finish_real(0); if(S_pixels!==6 || S_headers!==1) fail("real fragmented 24bit pixels");
        make_bmp(32,1); copy_bmp; launch(2,16'h0);
        finish_real(0); if(S_pixels!==6 || S_headers!==1) fail("real fragmented 32bit pixels");
        S_check_pixels=0;
        S_bmp[0]="X"; copy_bmp; launch(1,16'h10); finish_real(5);
        if(S_O_parser_error!==1) fail("real invalid BMP diagnostic");
        // Missing file and truncated geometry cannot publish image success.
        S_disk[1024]=8'he5; launch(0,16'h11); finish_real(1);
        if(S_O_file_error!==14 || S_O_parser_started) fail("missing file diagnostic");
        short_entry(1024,"TEST    BMP",32,4,60); make_bmp(24,0); copy_bmp;
        launch(0,16'h12); finish_real(5);
        short_entry(1024,"TEST    BMP",32,4,700);
        // An SD sector integrity failure is a file failure, not parser success.
        S_fail_lba=1236; launch(1,16'h13); finish_real(1);
        if(S_O_file_error===0 || S_O_storage_error!==4) fail("physical error diagnostics");
        S_fail_lba=32'hffffffff;
        // Cancel while second data cluster is physically in flight; real ack is delayed.
        launch(2,16'h14);
        wait(S_host_state==1 && S_F_O_sd_lba==1236); S_before=S_cancel_acks;
        pulse_abort; finish_real(2);
        if(S_cancel_acks<=S_before) fail("no physical cancellation acknowledgement");
        // Loss/recovery is latched; card_ready alone never remounts old generation.
        launch(0,16'h15); wait(S_host_state==1 && S_F_O_sd_lba==1234);
        @(negedge S_I_clk); S_F_I_card_ready=0;
        @(negedge S_I_clk); S_F_I_card_ready=1;
        finish_real(3); repeat(5) @(negedge S_I_clk);
        if(S_I_media_valid) fail("automatic remount");
        mount_card; S_check_pixels=1; launch(0,16'h16); finish_real(0);
        if(S_pixels!==6 || S_headers!==1 || S_O_generation!==S_mount_generation) fail("remounted pixels/generation");
        S_test_pass=1; $display("PASS: bmp_file_fat32 real source/parser/core, SD sectors are fixtures"); $finish;
    end
    task put16;
        input integer address,value;
        begin S_disk[address]=value; S_disk[address+1]=value>>8; end
    endtask
    task put32;
        input integer address;
        input [31:0] value;
        begin
            S_disk[address]=value[7:0]; S_disk[address+1]=value[15:8];
            S_disk[address+2]=value[23:16]; S_disk[address+3]=value[31:24];
        end
    endtask
    task short_entry;
        input integer address;
        input [87:0] alias;
        input [7:0] attr;
        input integer cluster,size;
        begin
            for(S_j=0;S_j<11;S_j=S_j+1) S_disk[address+S_j]=alias[(10-S_j)*8+:8];
            S_disk[address+11]=attr; put16(address+20,cluster>>16);
            put16(address+26,cluster); put32(address+28,size);
        end
    endtask
    task mount_card;
        begin
            @(negedge S_I_clk); S_F_I_mount_valid=1;
            @(posedge S_I_clk); while(!S_F_O_mount_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_F_I_mount_valid=0;
            wait(S_F_O_mount_result_valid); #1;
            if(S_F_O_mount_error!==0 || !S_I_media_valid ||
                S_I_media_generation!==S_mount_generation+1) fail("real mount/generation");
            S_mount_generation=S_mount_generation+1;
            @(negedge S_I_clk); S_F_I_mount_result_ready=1;
            @(negedge S_I_clk); S_F_I_mount_result_ready=0;
        end
    endtask
    // This is the SD host request contract, not a card or FAT32 replacement.
    // Each accepted sector snapshots its fixture bytes, then returns real valid/ready traffic.
    always @* begin
        S_F_I_sd_request_ready=S_host_state==0;
        S_F_I_sd_cancel_ready=S_host_state!=0 && !S_cancel_seen;
    end
    always @(posedge S_I_clk) begin
        S_cycle<=S_cycle+1;
        if(S_I_reset) begin
            S_host_state<=0; S_canceled<=0; S_cancel_seen<=0;
            S_F_I_sd_byte_valid<=0; S_F_I_sd_done_valid<=0; S_F_I_sd_cancel_done_valid<=0;
        end else begin
            if(S_F_O_sd_cancel_valid && S_F_I_sd_cancel_ready) begin
                if(S_F_O_sd_cancel_context!==S_F_I_sd_done_context || S_F_O_sd_cancel_tag!==S_F_I_sd_done_tag)
                    fail("physical cancel identity");
                S_canceled<=1; S_cancel_seen<=1;
            end
            case(S_host_state)
                0:if(S_F_O_sd_request_valid && S_F_I_sd_request_ready) begin
                    if(S_F_O_sd_count!==1) fail("sector request count");
                    case(S_F_O_sd_lba)
                        0:S_base=0; 32:S_base=512; 1232:S_base=1024;
                        1233:S_base=1536; 1234:S_base=2048; 1236:S_base=2560;
                        default:begin S_base=0; fail("unexpected fixture LBA"); end
                    endcase
                    for(S_index=0;S_index<512;S_index=S_index+1) S_sector[S_index]=S_disk[S_base+S_index];
                    S_index=0; S_host_state<=1; S_canceled<=0; S_cancel_seen<=0;
                    S_injected<=S_F_O_sd_lba==S_fail_lba;
                    S_F_I_sd_byte_context<=S_F_O_sd_context; S_F_I_sd_byte_tag<=S_F_O_sd_tag;
                    S_F_I_sd_done_context<=S_F_O_sd_context; S_F_I_sd_done_tag<=S_F_O_sd_tag;
                    S_F_I_sd_cancel_done_context<=S_F_O_sd_context; S_F_I_sd_cancel_done_tag<=S_F_O_sd_tag;
                end
                1:begin
                    if(S_F_I_sd_byte_valid && S_F_O_sd_byte_ready) begin
                        S_F_I_sd_byte_valid<=0;
                        if(S_index==511 || S_canceled) begin S_delay=9; S_host_state<=2; end
                        else S_index=S_index+1;
                    end else if(!S_F_I_sd_byte_valid && S_cycle%4!=0) begin
                        S_F_I_sd_byte_data<=S_sector[S_index]; S_F_I_sd_byte_valid<=1;
                        S_F_I_sd_sector_last<=S_index==511; S_F_I_sd_request_last<=S_index==511;
                    end
                end
                2:if(S_delay==0) begin
                    S_F_I_sd_done_error<=S_canceled ? 4'd6 : (S_injected ? 4'd4 : 4'd0);
                    S_F_I_sd_done_valid<=1; S_host_state<=3;
                end else S_delay=S_delay-1;
                3:if(S_F_I_sd_done_valid && S_F_O_sd_done_ready) begin
                    S_F_I_sd_done_valid<=0; S_delay=40; S_host_state<=4;
                end
                4:if(S_delay==0) begin
                    if(S_cancel_seen) begin S_F_I_sd_cancel_done_valid<=1; S_host_state<=5; end
                    else if(!(S_F_O_sd_cancel_valid && S_F_I_sd_cancel_ready)) S_host_state<=0;
                end else S_delay=S_delay-1;
                5:if(S_F_I_sd_cancel_done_valid && S_F_O_sd_cancel_done_ready) begin
                    S_F_I_sd_cancel_done_valid<=0; S_cancel_acks=S_cancel_acks+1; S_host_state<=0;
                end
                default:fail("SD fixture state");
            endcase
            if(S_O_fs_close_valid && (u_files.S_pending[S_O_context] || u_files.S_cancel_busy))
                fail("source offered close before real file retirement");
        end
    end
endmodule
