`timescale 1ns/1ps
// Real FAT32 core and children; host-sector peer, not a physical SD card.
module tb_fat32_core;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    reg  S_I_card_ready=0;
    reg  S_I_unmount=0;
    reg [32:0] S_I_capacity_sectors=0;
    reg  S_I_mount_valid=0;
    wire  S_O_mount_ready;
    wire  S_O_mount_result_valid;
    reg  S_I_mount_result_ready=0;
    wire [7:0] S_O_mount_error;
    wire [3:0] S_O_mount_storage_error;
    wire [31:0] S_O_mount_generation;
    wire  S_O_mounted;
    wire  S_O_quiescent;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_partition_lba;
    wire [31:0] S_O_volume_sectors;
    wire [31:0] S_O_fat_lba;
    wire [31:0] S_O_data_lba;
    wire [31:0] S_O_cluster_count;
    wire [31:0] S_O_root_cluster;
    wire [7:0] S_O_sectors_per_cluster;
    wire [2:0] S_O_cluster_shift;
    reg  S_I_enum_valid=0;
    wire  S_O_enum_ready;
    reg [15:0] S_I_enum_tag=0;
    reg [6:0] S_I_enum_path_length=0;
    reg [31:0] S_I_enum_sector_budget=0;
    reg  S_I_enum_path_valid=0;
    wire  S_O_enum_path_ready;
    reg [7:0] S_I_enum_path_data=0;
    reg  S_I_enum_path_last=0;
    reg  S_I_enum_stop=0;
    reg  S_I_enum_cancel=0;
    wire  S_O_enum_entry_valid;
    reg  S_I_enum_entry_ready=0;
    wire [7:0] S_O_enum_attr;
    wire [31:0] S_O_enum_size;
    wire [31:0] S_O_enum_first_cluster;
    wire [87:0] S_O_enum_alias;
    wire [6:0] S_O_enum_name_length;
    wire  S_O_enum_is_lfn;
    wire  S_O_enum_name_valid;
    reg  S_I_enum_name_ready=0;
    wire [7:0] S_O_enum_name_data;
    wire  S_O_enum_name_last;
    wire  S_O_enum_done_valid;
    reg  S_I_enum_done_ready=0;
    wire [15:0] S_O_enum_tag;
    wire [31:0] S_O_enum_generation;
    wire [31:0] S_O_enum_sectors;
    wire [2:0] S_O_enum_warning;
    wire [7:0] S_O_enum_error;
    wire [3:0] S_O_enum_storage_error;
    reg  S_I_open_valid=0;
    wire  S_O_open_ready;
    reg [1:0] S_I_open_context=0;
    reg [15:0] S_I_open_tag=0;
    reg [6:0] S_I_path_length=0;
    reg [31:0] S_I_sector_budget=0;
    reg  S_I_path_valid=0;
    wire  S_O_path_ready;
    reg [7:0] S_I_path_data=0;
    reg  S_I_path_last=0;
    reg  S_I_open_cancel=0;
    wire  S_O_open_result_valid;
    reg  S_I_open_result_ready=0;
    wire [1:0] S_O_open_context;
    wire [15:0] S_O_open_tag;
    wire [31:0] S_O_open_generation;
    wire [31:0] S_O_open_size;
    wire [31:0] S_O_open_first_cluster;
    wire [31:0] S_O_open_sectors;
    wire [7:0] S_O_open_attr;
    wire [7:0] S_O_open_error;
    wire [3:0] S_O_open_storage_error;
    wire [2:0] S_O_open_warning;
    wire [31:0] S_O_byte_generation;
    wire [31:0] S_O_done_generation;
    wire [31:0] S_O_cancel_done_generation;
    reg  S_I_close_valid=0;
    wire  S_O_close_ready;
    reg [1:0] S_I_close_context=0;
    reg  S_I_read_valid=0;
    wire  S_O_read_ready;
    reg [1:0] S_I_read_context=0;
    reg [1:0] S_I_read_priority=0;
    reg [31:0] S_I_offset=0;
    reg [31:0] S_I_length=0;
    reg [15:0] S_I_epoch=0;
    reg [2:0] S_I_urgent_context=0;
    wire  S_O_byte_valid;
    reg  S_I_byte_ready=0;
    wire [7:0] S_O_byte_data;
    wire [1:0] S_O_byte_context;
    wire [15:0] S_O_byte_epoch;
    wire [31:0] S_O_byte_offset;
    wire  S_O_byte_last;
    wire  S_O_done_valid;
    reg  S_I_done_ready=0;
    wire [1:0] S_O_done_context;
    wire [15:0] S_O_done_epoch;
    wire [31:0] S_O_done_bytes;
    wire  S_O_done_eof;
    wire [7:0] S_O_done_error;
    wire [3:0] S_O_done_storage_error;
    reg  S_I_cancel_valid=0;
    wire  S_O_cancel_ready;
    reg [1:0] S_I_cancel_context=0;
    reg [15:0] S_I_cancel_epoch=0;
    wire  S_O_cancel_done_valid;
    reg  S_I_cancel_done_ready=0;
    wire [1:0] S_O_cancel_done_context;
    wire [15:0] S_O_cancel_done_epoch;
    wire  S_O_sd_request_valid;
    reg  S_I_sd_request_ready=0;
    wire [31:0] S_O_sd_lba;
    wire [7:0] S_O_sd_count;
    wire [1:0] S_O_sd_context;
    wire [1:0] S_O_sd_priority;
    wire [15:0] S_O_sd_tag;
    reg  S_I_sd_byte_valid=0;
    wire  S_O_sd_byte_ready;
    reg [7:0] S_I_sd_byte_data=0;
    reg  S_I_sd_sector_last=0;
    reg  S_I_sd_request_last=0;
    reg [1:0] S_I_sd_byte_context=0;
    reg [15:0] S_I_sd_byte_tag=0;
    reg  S_I_sd_done_valid=0;
    wire  S_O_sd_done_ready;
    reg [1:0] S_I_sd_done_context=0;
    reg [15:0] S_I_sd_done_tag=0;
    reg [3:0] S_I_sd_done_error=0;
    wire  S_O_sd_cancel_valid;
    reg  S_I_sd_cancel_ready=0;
    wire [1:0] S_O_sd_cancel_context;
    wire [15:0] S_O_sd_cancel_tag;
    reg  S_I_sd_cancel_done_valid=0;
    wire  S_O_sd_cancel_done_ready;
    reg [1:0] S_I_sd_cancel_done_context=0;
    reg [15:0] S_I_sd_cancel_done_tag=0;
    fat32_core u_dut (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_card_ready(S_I_card_ready),
        .I_unmount(S_I_unmount),
        .I_capacity_sectors(S_I_capacity_sectors),
        .I_mount_valid(S_I_mount_valid),
        .O_mount_ready(S_O_mount_ready),
        .O_mount_result_valid(S_O_mount_result_valid),
        .I_mount_result_ready(S_I_mount_result_ready),
        .O_mount_error(S_O_mount_error),
        .O_mount_storage_error(S_O_mount_storage_error),
        .O_mount_generation(S_O_mount_generation),
        .O_mounted(S_O_mounted),
        .O_quiescent(S_O_quiescent),
        .O_generation(S_O_generation),
        .O_partition_lba(S_O_partition_lba),
        .O_volume_sectors(S_O_volume_sectors),
        .O_fat_lba(S_O_fat_lba),
        .O_data_lba(S_O_data_lba),
        .O_cluster_count(S_O_cluster_count),
        .O_root_cluster(S_O_root_cluster),
        .O_sectors_per_cluster(S_O_sectors_per_cluster),
        .O_cluster_shift(S_O_cluster_shift),
        .I_enum_valid(S_I_enum_valid),
        .O_enum_ready(S_O_enum_ready),
        .I_enum_tag(S_I_enum_tag),
        .I_enum_path_length(S_I_enum_path_length),
        .I_enum_sector_budget(S_I_enum_sector_budget),
        .I_enum_path_valid(S_I_enum_path_valid),
        .O_enum_path_ready(S_O_enum_path_ready),
        .I_enum_path_data(S_I_enum_path_data),
        .I_enum_path_last(S_I_enum_path_last),
        .I_enum_stop(S_I_enum_stop),
        .I_enum_cancel(S_I_enum_cancel),
        .O_enum_entry_valid(S_O_enum_entry_valid),
        .I_enum_entry_ready(S_I_enum_entry_ready),
        .O_enum_attr(S_O_enum_attr),
        .O_enum_size(S_O_enum_size),
        .O_enum_first_cluster(S_O_enum_first_cluster),
        .O_enum_alias(S_O_enum_alias),
        .O_enum_name_length(S_O_enum_name_length),
        .O_enum_is_lfn(S_O_enum_is_lfn),
        .O_enum_name_valid(S_O_enum_name_valid),
        .I_enum_name_ready(S_I_enum_name_ready),
        .O_enum_name_data(S_O_enum_name_data),
        .O_enum_name_last(S_O_enum_name_last),
        .O_enum_done_valid(S_O_enum_done_valid),
        .I_enum_done_ready(S_I_enum_done_ready),
        .O_enum_tag(S_O_enum_tag),
        .O_enum_generation(S_O_enum_generation),
        .O_enum_sectors(S_O_enum_sectors),
        .O_enum_warning(S_O_enum_warning),
        .O_enum_error(S_O_enum_error),
        .O_enum_storage_error(S_O_enum_storage_error),
        .I_open_valid(S_I_open_valid),
        .O_open_ready(S_O_open_ready),
        .I_open_context(S_I_open_context),
        .I_open_tag(S_I_open_tag),
        .I_path_length(S_I_path_length),
        .I_sector_budget(S_I_sector_budget),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
        .I_open_cancel(S_I_open_cancel),
        .O_open_result_valid(S_O_open_result_valid),
        .I_open_result_ready(S_I_open_result_ready),
        .O_open_context(S_O_open_context),
        .O_open_tag(S_O_open_tag),
        .O_open_generation(S_O_open_generation),
        .O_open_size(S_O_open_size),
        .O_open_first_cluster(S_O_open_first_cluster),
        .O_open_sectors(S_O_open_sectors),
        .O_open_attr(S_O_open_attr),
        .O_open_error(S_O_open_error),
        .O_open_storage_error(S_O_open_storage_error),
        .O_open_warning(S_O_open_warning),
        .O_byte_generation(S_O_byte_generation),
        .O_done_generation(S_O_done_generation),
        .O_cancel_done_generation(S_O_cancel_done_generation),
        .I_close_valid(S_I_close_valid),
        .O_close_ready(S_O_close_ready),
        .I_close_context(S_I_close_context),
        .I_read_valid(S_I_read_valid),
        .O_read_ready(S_O_read_ready),
        .I_read_context(S_I_read_context),
        .I_read_priority(S_I_read_priority),
        .I_offset(S_I_offset),
        .I_length(S_I_length),
        .I_epoch(S_I_epoch),
        .I_urgent_context(S_I_urgent_context),
        .O_byte_valid(S_O_byte_valid),
        .I_byte_ready(S_I_byte_ready),
        .O_byte_data(S_O_byte_data),
        .O_byte_context(S_O_byte_context),
        .O_byte_epoch(S_O_byte_epoch),
        .O_byte_offset(S_O_byte_offset),
        .O_byte_last(S_O_byte_last),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_done_context(S_O_done_context),
        .O_done_epoch(S_O_done_epoch),
        .O_done_bytes(S_O_done_bytes),
        .O_done_eof(S_O_done_eof),
        .O_done_error(S_O_done_error),
        .O_done_storage_error(S_O_done_storage_error),
        .I_cancel_valid(S_I_cancel_valid),
        .O_cancel_ready(S_O_cancel_ready),
        .I_cancel_context(S_I_cancel_context),
        .I_cancel_epoch(S_I_cancel_epoch),
        .O_cancel_done_valid(S_O_cancel_done_valid),
        .I_cancel_done_ready(S_I_cancel_done_ready),
        .O_cancel_done_context(S_O_cancel_done_context),
        .O_cancel_done_epoch(S_O_cancel_done_epoch),
        .O_sd_request_valid(S_O_sd_request_valid),
        .I_sd_request_ready(S_I_sd_request_ready),
        .O_sd_lba(S_O_sd_lba),
        .O_sd_count(S_O_sd_count),
        .O_sd_context(S_O_sd_context),
        .O_sd_priority(S_O_sd_priority),
        .O_sd_tag(S_O_sd_tag),
        .I_sd_byte_valid(S_I_sd_byte_valid),
        .O_sd_byte_ready(S_O_sd_byte_ready),
        .I_sd_byte_data(S_I_sd_byte_data),
        .I_sd_sector_last(S_I_sd_sector_last),
        .I_sd_request_last(S_I_sd_request_last),
        .I_sd_byte_context(S_I_sd_byte_context),
        .I_sd_byte_tag(S_I_sd_byte_tag),
        .I_sd_done_valid(S_I_sd_done_valid),
        .O_sd_done_ready(S_O_sd_done_ready),
        .I_sd_done_context(S_I_sd_done_context),
        .I_sd_done_tag(S_I_sd_done_tag),
        .I_sd_done_error(S_I_sd_done_error),
        .O_sd_cancel_valid(S_O_sd_cancel_valid),
        .I_sd_cancel_ready(S_I_sd_cancel_ready),
        .O_sd_cancel_context(S_O_sd_cancel_context),
        .O_sd_cancel_tag(S_O_sd_cancel_tag),
        .I_sd_cancel_done_valid(S_I_sd_cancel_done_valid),
        .O_sd_cancel_done_ready(S_O_sd_cancel_done_ready),
        .I_sd_cancel_done_context(S_I_sd_cancel_done_context),
        .I_sd_cancel_done_tag(S_I_sd_cancel_done_tag));
    always #4 S_I_clk=~S_I_clk;
    reg [7:0] S_disk[0:4095],S_model_ram[0:511];
    reg [2:0] S_host_state=0;
    reg S_canceled=0,S_cancel_seen=0,S_injected=0;
    reg [31:0] S_fail_lba=32'hffffffff;
    integer S_cycle=0,S_requests=0,S_acks=0,S_retired=0,S_index=0,S_delay=0,S_base=0;
    integer S_i,S_j,S_k,S_case=0,S_before,S_done_count=0,S_done_before,S_path_count=0;
    integer S_count[0:2],S_next[0:2],S_end[0:2],S_ref[0:2];
    reg [2:0] S_expected_active=0;
    reg [7:0] S_expected_error[0:2];
    reg S_expected_eof[0:2];
    reg [15:0] S_expected_epoch[0:2];
    reg [31:0] S_expected_generation[0:2];
    reg [31:0] S_generation=0;
    reg [255:0] S_held;
    reg [7:0] S_checksum;
    reg [87:0] S_alias="THEME~1 WAV";
    reg [103:0] S_name="Theme One.wav";
    integer S_unit_offset;
    reg S_test_pass=0;
    reg S_compete_enum=0;
    task fail;
        input [511:0] message;
        begin $display("FAIL: FAT32 core case %0d: %0s",S_case,message); $stop; end
    endtask
    function [7:0] sample_byte;
        input integer reference,offset;
        // Distinguish 512-byte fragments too, not only byte positions in a sector.
        begin sample_byte=(reference==0 ? 8'h20 : 8'h60)^offset[7:0]^{6'd0,offset[9:8]}; end
    endfunction
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
        input [31:0] cluster,size;
        begin
            for(S_j=0;S_j<11;S_j=S_j+1) S_disk[address+S_j]=alias[(10-S_j)*8+:8];
            S_disk[address+11]=attr; put16(address+20,cluster>>16); put16(address+26,cluster); put32(address+28,size);
        end
    endtask
    task mount_command;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_mount_valid=1;
            @(posedge S_I_clk); while(!S_O_mount_ready) @(posedge S_I_clk);
            S_generation=S_generation+1;
            @(negedge S_I_clk); S_I_mount_valid=0;
        end
    endtask
    task mount_result;
        input [7:0] error;
        begin
            wait(S_O_mount_result_valid); #1;
            if(S_O_mount_error!==error || S_O_mount_generation!==S_generation || S_O_mounted!==(error==0))
                fail("mount commit/error/generation");
            S_held={S_O_mount_error,S_O_mount_storage_error,S_O_mount_generation,S_O_root_cluster,S_O_data_lba};
            repeat(6) begin
                @(negedge S_I_clk);
                if(!S_O_mount_result_valid || S_O_mount_ready ||
                    {S_O_mount_error,S_O_mount_storage_error,S_O_mount_generation,S_O_root_cluster,S_O_data_lba}!==S_held)
                    fail("mount terminal not held");
            end
            S_I_mount_result_ready=1; @(negedge S_I_clk); S_I_mount_result_ready=0;
        end
    endtask
    task open_header;
        input [1:0] context;
        input [15:0] tag;
        input integer length,budget;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_open_context=context; S_I_open_tag=tag;
            S_I_path_length=length; S_I_sector_budget=budget; S_I_open_valid=1;
            if(S_compete_enum) S_I_enum_valid=1;
            @(posedge S_I_clk); while(!S_O_open_ready) @(posedge S_I_clk);
            if(S_compete_enum && S_O_enum_ready) fail("enum defeated simultaneous open priority");
            @(negedge S_I_clk); S_I_open_valid=0;
            if(S_compete_enum) S_I_enum_valid=0;
        end
    endtask
    task open_path;
        input [1:0] context;
        input [15:0] tag;
        input [511:0] path;
        input integer length,budget;
        begin
            open_header(context,tag,length,budget);
            for(S_k=0;S_k<length && !S_O_open_result_valid;S_k=S_k+1) begin
                @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=path[(length-1-S_k)*8+:8]; S_I_path_last=S_k==length-1;
                @(posedge S_I_clk); while(!S_O_path_ready && !S_O_open_result_valid) @(posedge S_I_clk);
                @(negedge S_I_clk); S_I_path_valid=0;
            end
            S_I_path_last=0;
        end
    endtask
    task open_result;
        input [1:0] context;
        input [15:0] tag;
        input [7:0] error;
        input [31:0] size,cluster;
        begin
            wait(S_O_open_result_valid); #1;
            if(S_O_open_context!==context || S_O_open_tag!==tag || S_O_open_error!==error || S_O_open_generation!==S_generation)
                fail("open identity/error/generation");
            if(error==0 && (S_O_open_size!==size || S_O_open_first_cluster!==cluster || S_O_open_attr[4]))
                fail("open descriptor metadata");
            S_held={S_O_open_context,S_O_open_tag,S_O_open_generation,S_O_open_size,S_O_open_first_cluster,
                S_O_open_attr,S_O_open_error,S_O_open_storage_error,S_O_open_warning,S_O_open_sectors};
            repeat(6) begin
                @(negedge S_I_clk);
                if(!S_O_open_result_valid ||
                    {S_O_open_context,S_O_open_tag,S_O_open_generation,S_O_open_size,S_O_open_first_cluster,
                    S_O_open_attr,S_O_open_error,S_O_open_storage_error,S_O_open_warning,S_O_open_sectors}!==S_held)
                    fail("open result changed");
            end
            // Even a successful loaded descriptor stays reserved until result ack.
            if(context<3) begin
                S_I_read_context=context; S_I_close_context=context; S_I_read_valid=1; S_I_close_valid=1;
                #1; if(S_O_read_ready || S_O_close_ready) fail("reserved context reused before open result ack");
                S_I_read_valid=0; S_I_close_valid=0;
            end
            S_I_open_result_ready=1; @(negedge S_I_clk); S_I_open_result_ready=0;
        end
    endtask
    task enum_header;
        input [15:0] tag;
        input integer length,budget;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_enum_tag=tag; S_I_enum_path_length=length;
            S_I_enum_sector_budget=budget; S_I_enum_valid=1;
            @(posedge S_I_clk); while(!S_O_enum_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_enum_valid=0;
        end
    endtask
    task enum_path;
        input [15:0] tag;
        input [511:0] path;
        input integer length,budget;
        begin
            enum_header(tag,length,budget);
            for(S_k=0;S_k<length && !S_O_enum_done_valid;S_k=S_k+1) begin
                @(negedge S_I_clk); S_I_enum_path_valid=1;
                S_I_enum_path_data=path[(length-1-S_k)*8+:8]; S_I_enum_path_last=S_k==length-1;
                @(posedge S_I_clk); while(!S_O_enum_path_ready && !S_O_enum_done_valid) @(posedge S_I_clk);
                @(negedge S_I_clk); S_I_enum_path_valid=0;
            end
            S_I_enum_path_last=0;
        end
    endtask
    task enum_entry;
        input [15:0] tag;
        input [511:0] name;
        input integer length;
        input [7:0] attr;
        input [31:0] size,cluster;
        input [87:0] alias;
        input lfn;
        begin
            wait(S_O_enum_entry_valid); #1;
            if(S_O_enum_tag!==tag || S_O_enum_generation!==S_generation || S_O_enum_attr!==attr ||
                S_O_enum_size!==size || S_O_enum_first_cluster!==cluster ||
                S_O_enum_name_length!==length || S_O_enum_is_lfn!==lfn) fail("enum metadata/identity");
            for(S_j=0;S_j<11;S_j=S_j+1)
                if(S_O_enum_alias[S_j*8+:8]!==alias[(10-S_j)*8+:8]) fail("enum raw alias byte order");
            S_held={S_O_enum_attr,S_O_enum_size,S_O_enum_first_cluster,S_O_enum_alias,
                S_O_enum_name_length,S_O_enum_is_lfn,S_O_enum_tag,S_O_enum_generation};
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_enum_entry_valid || S_O_enum_name_valid || S_O_enum_done_valid ||
                    S_O_open_ready || S_O_enum_ready || S_O_quiescent || S_O_mount_ready ||
                    {S_O_enum_attr,S_O_enum_size,S_O_enum_first_cluster,S_O_enum_alias,
                    S_O_enum_name_length,S_O_enum_is_lfn,S_O_enum_tag,S_O_enum_generation}!==S_held)
                    fail("enum entry backpressure/namespace barrier");
            end
            S_I_enum_entry_ready=1; @(negedge S_I_clk); S_I_enum_entry_ready=0;
            for(S_k=0;S_k<length;S_k=S_k+1) begin
                wait(S_O_enum_name_valid); #1;
                if(S_O_enum_name_data!==name[(length-1-S_k)*8+:8] || S_O_enum_name_last!==(S_k==length-1) ||
                    S_O_enum_tag!==tag || S_O_enum_generation!==S_generation) fail("enum name/last/identity");
                S_held={S_O_enum_name_data,S_O_enum_name_last,S_O_enum_tag,S_O_enum_generation};
                repeat(3) begin
                    @(negedge S_I_clk);
                    if(!S_O_enum_name_valid || S_O_enum_done_valid ||
                        {S_O_enum_name_data,S_O_enum_name_last,S_O_enum_tag,S_O_enum_generation}!==S_held)
                        fail("enum name backpressure");
                end
                S_I_enum_name_ready=1; @(negedge S_I_clk); S_I_enum_name_ready=0;
            end
        end
    endtask
    task enum_result;
        input [15:0] tag;
        input [7:0] error;
        input [31:0] sectors;
        input [2:0] warning;
        input [3:0] storage_error;
        begin
            wait(S_O_enum_done_valid); #1;
            if(S_O_enum_tag!==tag || S_O_enum_generation!==S_generation || S_O_enum_error!==error ||
                S_O_enum_sectors!==sectors || S_O_enum_warning!==warning || S_O_enum_storage_error!==storage_error)
                fail("enum terminal identity/error/budget/warning");
            S_held={S_O_enum_tag,S_O_enum_generation,S_O_enum_error,S_O_enum_storage_error,S_O_enum_sectors,S_O_enum_warning};
            @(negedge S_I_clk); S_I_mount_valid=1; S_I_enum_stop=1; S_I_enum_cancel=1;
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_enum_done_valid || S_O_mount_ready || S_O_quiescent || S_O_open_ready || S_O_enum_ready ||
                    S_O_enum_entry_valid || S_O_enum_name_valid ||
                    {S_O_enum_tag,S_O_enum_generation,S_O_enum_error,S_O_enum_storage_error,S_O_enum_sectors,S_O_enum_warning}!==S_held)
                    fail("enum terminal held/new mount barrier");
            end
            S_I_mount_valid=0; S_I_enum_stop=0; S_I_enum_cancel=0;
            S_I_enum_done_ready=1; @(negedge S_I_clk); S_I_enum_done_ready=0;
        end
    endtask
    task close_file;
        input [1:0] context;
        begin
            @(negedge S_I_clk); S_I_close_context=context; S_I_close_valid=1;
            @(posedge S_I_clk); while(!S_O_close_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_close_valid=0;
        end
    endtask
    task read_file;
        input [1:0] context;
        input [15:0] epoch;
        input integer offset,length,actual_length,reference;
        input [7:0] error;
        input eof;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk);
            if(S_expected_active[context]) fail("test reused pending context");
            S_expected_active[context]=1; S_expected_epoch[context]=epoch;
            S_expected_generation[context]=S_generation; S_expected_error[context]=error; S_expected_eof[context]=eof;
            S_count[context]=0; S_next[context]=offset; S_end[context]=offset+actual_length; S_ref[context]=reference;
            S_I_read_context=context; S_I_epoch=epoch; S_I_offset=offset; S_I_length=length;
            S_I_read_priority=context; S_I_read_valid=1;
            @(posedge S_I_clk); while(!S_O_read_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_read_valid=0;
        end
    endtask
    task accept_done;
        begin
            wait(S_O_done_valid); @(negedge S_I_clk); S_I_done_ready=1;
            @(negedge S_I_clk); S_I_done_ready=0;
        end
    endtask
    task cancel_file;
        input [1:0] context;
        input [15:0] epoch;
        begin
            @(negedge S_I_clk); S_I_cancel_context=context; S_I_cancel_epoch=epoch; S_I_cancel_valid=1;
            @(posedge S_I_clk); while(!S_O_cancel_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_cancel_valid=0;
        end
    endtask
    task cancel_result;
        input [1:0] context;
        input [15:0] epoch;
        begin
            wait(S_O_cancel_done_valid); #1;
            if(S_O_cancel_done_context!==context || S_O_cancel_done_epoch!==epoch || S_O_cancel_done_generation!==S_generation)
                fail("file cancel identity/generation");
            repeat(5) begin
                @(negedge S_I_clk);
                if(S_O_mount_ready || !S_O_cancel_done_valid) fail("mount crossed unaccepted cancel result");
            end
            S_I_cancel_done_ready=1; @(negedge S_I_clk); S_I_cancel_done_ready=0;
        end
    endtask
    // Host endpoint. A cancel ack is intentionally much later than request done.
    always @* begin
        S_I_sd_request_ready=S_host_state==0 && S_cycle%7!=0;
        S_I_sd_cancel_ready=S_host_state!=0 && !S_cancel_seen && S_cycle%5!=0;
    end
    always @(posedge S_I_clk) begin
        S_cycle<=S_cycle+1;
        if(!S_I_reset) begin
            if(S_O_sd_cancel_valid && S_I_sd_cancel_ready) begin
                if(S_O_sd_cancel_context!==S_I_sd_done_context || S_O_sd_cancel_tag!==S_I_sd_done_tag) fail("physical cancel identity");
                S_canceled<=1; S_cancel_seen<=1;
            end
            case(S_host_state)
                0:if(S_O_sd_request_valid && S_I_sd_request_ready) begin
                    if(S_O_sd_count!=1 || S_O_sd_context==3) fail("physical request fields");
                    S_requests=S_requests+1;
                    case(S_O_sd_lba)
                        0:S_base=0; 32:S_base=512; 1232:S_base=1024; 1233:S_base=1536;
                        1236:S_base=2048; 1235:S_base=2560; 1238:S_base=3072; 1239:S_base=3584;
                        default:begin S_base=0; fail("unexpected LBA"); end
                    endcase
                    for(S_index=0;S_index<512;S_index=S_index+1) S_model_ram[S_index]=S_disk[S_base+S_index];
                    S_index=0; S_host_state<=1; S_canceled<=0; S_cancel_seen<=0; S_injected<=S_O_sd_lba==S_fail_lba;
                    S_I_sd_byte_context<=S_O_sd_context; S_I_sd_byte_tag<=S_O_sd_tag;
                    S_I_sd_done_context<=S_O_sd_context; S_I_sd_done_tag<=S_O_sd_tag;
                    S_I_sd_cancel_done_context<=S_O_sd_context; S_I_sd_cancel_done_tag<=S_O_sd_tag;
                end
                1:begin
                    if(S_I_sd_byte_valid && S_O_sd_byte_ready) begin
                        S_I_sd_byte_valid<=0;
                        if(S_index==511 || S_canceled) begin S_delay=12; S_host_state<=2; end
                        else S_index=S_index+1;
                    end else if(!S_I_sd_byte_valid && S_cycle%4!=0) begin
                        S_I_sd_byte_data<=S_model_ram[S_index]; S_I_sd_byte_valid<=1;
                        S_I_sd_sector_last<=S_index==511; S_I_sd_request_last<=S_index==511;
                    end
                end
                2:if(S_delay==0) begin
                    S_I_sd_done_error<=S_canceled ? 4'd6 : (S_injected ? 4'd4 : 4'd0);
                    S_I_sd_done_valid<=1; S_host_state<=3;
                end else S_delay=S_delay-1;
                3:if(S_I_sd_done_valid && S_O_sd_done_ready) begin
                    S_I_sd_done_valid<=0; S_retired=S_retired+1; S_delay=30; S_host_state<=4;
                end
                4:if(S_delay==0) begin
                    if(S_cancel_seen) begin S_I_sd_cancel_done_valid<=1; S_host_state<=5; end
                    else if(!(S_O_sd_cancel_valid && S_I_sd_cancel_ready)) S_host_state<=0;
                end else S_delay=S_delay-1;
                5:if(S_I_sd_cancel_done_valid && S_O_sd_cancel_done_ready) begin
                    S_I_sd_cancel_done_valid<=0; S_acks=S_acks+1; S_host_state<=0;
                end
                default:fail("host endpoint state");
            endcase
        end
    end
    always @(posedge S_I_clk) if(!S_I_reset) begin
        if(S_I_mount_valid && S_O_mount_ready &&
            (!S_O_quiescent || u_dut.S_result!=0 || !u_dut.S_port_ready || u_dut.S_port_valid ||
                u_dut.S_file_valid || u_dut.S_namespace_valid)) fail("mount admitted with an unretired physical owner");
        if(S_I_enum_valid && S_O_enum_ready && S_I_open_valid && S_O_open_ready)
            fail("two namespace commands accepted together");
        if(S_O_enum_entry_valid || S_O_enum_name_valid)
            if(u_dut.S_open_state!=8 || S_O_enum_generation!==S_generation)
                fail("enum output outside scan/current generation");
        if(S_I_path_valid && S_O_path_ready) S_path_count=S_path_count+1;
        if(S_O_byte_valid && S_I_byte_ready) begin
            if(S_O_byte_context==3 || !S_expected_active[S_O_byte_context]) fail("unexpected file byte");
            if(S_O_byte_epoch!==S_expected_epoch[S_O_byte_context] || S_O_byte_generation!==S_expected_generation[S_O_byte_context] ||
                S_O_byte_offset!==S_next[S_O_byte_context] || S_O_byte_data!==sample_byte(S_ref[S_O_byte_context],S_next[S_O_byte_context]) ||
                S_O_byte_last!==(S_next[S_O_byte_context]+1==S_end[S_O_byte_context])) fail("file payload/identity/offset/last");
            S_count[S_O_byte_context]=S_count[S_O_byte_context]+1; S_next[S_O_byte_context]=S_next[S_O_byte_context]+1;
        end
        if(S_O_done_valid && S_I_done_ready) begin
            if(!S_expected_active[S_O_done_context] || S_O_done_error!==S_expected_error[S_O_done_context] ||
                S_O_done_epoch!==S_expected_epoch[S_O_done_context] || S_O_done_generation!==S_expected_generation[S_O_done_context] ||
                S_O_done_bytes!==S_count[S_O_done_context] ||
                (S_O_done_error==0 && S_O_done_eof!==S_expected_eof[S_O_done_context]))
                fail("file done identity/error/count/eof");
            if(S_O_done_error==0 && S_next[S_O_done_context]!=S_end[S_O_done_context]) fail("short successful file read");
            S_expected_active[S_O_done_context]=0; S_done_count=S_done_count+1;
        end
    end
    initial begin
        S_I_reset=1; S_I_card_ready=1; S_I_capacity_sectors=100000;
        for(S_i=0;S_i<4096;S_i=S_i+1) S_disk[S_i]=0;
        S_disk[0]=8'heb; S_disk[2]=8'h90; put16(11,512); S_disk[13]=1; put16(14,32); S_disk[16]=2;
        put32(32,70000); put32(36,600); put32(44,2); put16(510,16'haa55);
        put32(512+3*4,6); put32(512+6*4,32'h0fffffff); put32(512+8*4,9); put32(512+9*4,32'h0fffffff);
        short_entry(1024,"IMAGE   BMP",32,3,900); short_entry(1056,"MUSIC      ",16,5,0); short_entry(1088,"EMPTY   WAV",32,0,0);
        S_checksum=0;
        for(S_i=0;S_i<11;S_i=S_i+1) S_checksum={S_checksum[0],S_checksum[7:1]}+S_alias[(10-S_i)*8+:8];
        S_disk[2560]=8'h41; S_disk[2571]=15; S_disk[2573]=S_checksum;
        for(S_i=0;S_i<13;S_i=S_i+1) begin
            case(S_i)
                0:S_unit_offset=1; 1:S_unit_offset=3; 2:S_unit_offset=5; 3:S_unit_offset=7; 4:S_unit_offset=9;
                5:S_unit_offset=14; 6:S_unit_offset=16; 7:S_unit_offset=18; 8:S_unit_offset=20; 9:S_unit_offset=22;
                10:S_unit_offset=24; 11:S_unit_offset=28; default:S_unit_offset=30;
            endcase
            S_disk[2560+S_unit_offset]=S_name[(12-S_i)*8+:8];
        end
        short_entry(2592,S_alias,32,8,700);
        for(S_i=0;S_i<512;S_i=S_i+1) begin
            S_disk[1536+S_i]=sample_byte(0,S_i); S_disk[2048+S_i]=sample_byte(0,512+S_i);
            S_disk[3072+S_i]=sample_byte(1,S_i); S_disk[3584+S_i]=sample_byte(1,512+S_i);
        end
        #39; S_I_reset=0;
        // Rejections before a path starts must not consume the path frame.
        open_path(0,16'h100,"image.bmp",9,8); open_result(0,16'h100,1,0,0);
        if(S_path_count!=0) fail("unmounted open consumed a path");
        enum_path(16'h400,"/",1,8); enum_result(16'h400,1,0,0,0);
        mount_command; mount_result(0);
        if(S_O_fat_lba!=32 || S_O_data_lba!=1232 || S_O_root_cluster!=2 || S_O_cluster_count!=68768) fail("mounted geometry");
        S_compete_enum=1;
        open_path(0,16'h101,"IMAGE.BMP",9,8); open_result(0,16'h101,0,900,3);
        S_compete_enum=0;
        // Root enumeration does not consume a file descriptor or stop its data.
        S_I_byte_ready=1; read_file(0,16'h301,0,900,900,0,0,1);
        enum_path(16'h401,"/",1,8);
        enum_entry(16'h401,"IMAGE.BMP",9,32,900,3,"IMAGE   BMP",0);
        enum_entry(16'h401,"MUSIC",5,16,0,5,"MUSIC      ",0);
        enum_entry(16'h401,"EMPTY.WAV",9,32,0,0,"EMPTY   WAV",0);
        enum_result(16'h401,0,1,0,0); accept_done;
        // Resolve a directory path, then enumerate its ASCII LFN in client 1.
        enum_path(16'h402,"//music/",8,8);
        enum_entry(16'h402,"Theme One.wav",13,32,700,8,"THEME~1 WAV",1);
        enum_result(16'h402,0,2,0,0);
        enum_path(16'h403,"image.bmp",9,8); enum_result(16'h403,15,1,0,0);
        enum_path(16'h404,"not-here",8,8); enum_result(16'h404,14,1,0,0);
        enum_path(16'h405,"music",5,1); enum_result(16'h405,10,1,0,0);
        enum_path(16'h406,"/",1,0); enum_result(16'h406,10,0,0,0);
        enum_path(16'h407,"../music",8,8); enum_result(16'h407,13,0,0,0);
        enum_header(16'h408,2,8);
        @(negedge S_I_clk); S_I_enum_path_valid=1; S_I_enum_path_data=8'h2f; S_I_enum_path_last=1;
        @(posedge S_I_clk); while(!S_O_enum_path_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_enum_path_valid=0; S_I_enum_path_last=0;
        enum_result(16'h408,13,0,0,0);
        // Cancel before a path is supplied, then prove the next command is clean.
        enum_header(16'h409,5,8);
        @(negedge S_I_clk); S_I_enum_cancel=1;
        @(negedge S_I_clk); S_I_enum_cancel=0; enum_result(16'h409,8,0,0,0);
        enum_path(16'h40a,"music",5,8);
        enum_entry(16'h40a,"Theme One.wav",13,32,700,8,"THEME~1 WAV",1);
        enum_result(16'h40a,0,2,0,0);
        // stop during path reception is latched, but does not bypass resolution.
        S_I_enum_stop=1; enum_path(16'h40b,"music",5,8); S_I_enum_stop=0;
        enum_result(16'h40b,0,1,0,0);
        enum_path(16'h40c,"/",1,8); wait(S_O_enum_entry_valid);
        @(negedge S_I_clk); S_I_enum_stop=1;
        @(negedge S_I_clk); S_I_enum_stop=0; enum_result(16'h40c,0,1,0,0);
        // Cancel can discard a partially consumed name; no next entry is needed.
        enum_path(16'h40d,"/",1,8); wait(S_O_enum_entry_valid);
        @(negedge S_I_clk); S_I_enum_entry_ready=1;
        @(negedge S_I_clk); S_I_enum_entry_ready=0; wait(S_O_enum_name_valid);
        S_I_enum_name_ready=1; @(negedge S_I_clk); S_I_enum_name_ready=0; S_I_enum_cancel=1;
        @(negedge S_I_clk); S_I_enum_cancel=0; enum_result(16'h40d,8,1,0,0);
        // A physical scan cancellation must wait for the delayed host cancel ack.
        enum_path(16'h40e,"/",1,8); wait(S_host_state==1 && S_index>30);
        S_before=S_acks; @(negedge S_I_clk); S_I_enum_cancel=1;
        @(negedge S_I_clk); S_I_enum_cancel=0; wait(S_O_enum_done_valid);
        if(S_acks!=S_before+1) fail("enum completed before physical cancel ack");
        enum_result(16'h40e,8,0,0,6);
        // Cancel while resolving the directory, before handing client 1 to scan.
        enum_path(16'h414,"music",5,8); wait(S_host_state==1 && S_index>30);
        S_before=S_acks; @(negedge S_I_clk); S_I_enum_cancel=1;
        @(negedge S_I_clk); S_I_enum_cancel=0; wait(S_O_enum_done_valid);
        if(S_acks!=S_before+1) fail("enum lookup cancel skipped joined retirement");
        enum_result(16'h414,8,0,0,6);
        // Normal stop still waits for the physical ack, without becoming cancel.
        enum_path(16'h415,"/",1,8); wait(S_host_state==1 && S_index>30);
        S_before=S_acks; @(negedge S_I_clk); S_I_enum_stop=1;
        @(negedge S_I_clk); S_I_enum_stop=0; wait(S_O_enum_done_valid);
        if(S_acks!=S_before+1) fail("enum stop skipped physical retirement");
        enum_result(16'h415,0,0,0,6);
        S_I_enum_cancel=1; enum_path(16'h416,"/",1,8); S_I_enum_cancel=0;
        enum_result(16'h416,8,0,0,0);
        // A held directory entry must not reserve the stale open context number.
        enum_path(16'h417,"/",1,8); wait(S_O_enum_entry_valid);
        read_file(0,16'h303,0,900,900,0,8,0); wait(S_host_state==1 && S_index>30);
        cancel_file(0,16'h303); accept_done; cancel_result(0,16'h303);
        @(negedge S_I_clk); S_I_enum_stop=1;
        @(negedge S_I_clk); S_I_enum_stop=0; enum_result(16'h417,0,1,0,0);
        // Aggregate warning from both lookup and final scan, with alias fallback.
        S_disk[1024]=8'hff; S_disk[2573]=S_checksum^8'h01;
        enum_path(16'h40f,"music",5,8);
        enum_entry(16'h40f,"THEME~1.WAV",11,32,700,8,"THEME~1 WAV",0);
        enum_result(16'h40f,0,2,5,0); S_disk[1024]=8'h49; S_disk[2573]=S_checksum;
        S_fail_lba=1235; enum_path(16'h410,"music",5,8); enum_result(16'h410,2,1,0,4);
        S_fail_lba=32'hffffffff;
        S_before=S_path_count; open_path(0,16'h102,"empty.wav",9,8); open_result(0,16'h102,16,0,0);
        if(S_path_count!=S_before) fail("busy open consumed a path");
        open_path(3,16'h103,"image.bmp",9,8); open_result(3,16'h103,7,0,0);
        // A real file read and a nested LFN open share one physical port.
        S_I_byte_ready=1; read_file(0,16'h201,0,900,900,0,0,1);
        S_I_urgent_context=1;
        open_path(1,16'h104,"music/Theme One.wav",19,8); open_result(1,16'h104,0,700,8);
        S_I_urgent_context=0; accept_done;
        read_file(0,16'h202,500,600,400,0,0,1);
        read_file(1,16'h203,400,400,300,1,0,1);
        S_done_before=S_done_count; S_I_done_ready=1;
        wait(S_done_count==S_done_before+2); @(negedge S_I_clk); S_I_done_ready=0;
        // Empty file and unopened reads use independent identities.
        open_path(2,16'h105,"empty.wav",9,8); open_result(2,16'h105,0,0,0);
        S_done_before=S_done_count;
        read_file(0,16'h220,0,20,20,0,0,0);
        read_file(1,16'h221,0,20,20,1,0,0);
        read_file(2,16'h204,0,10,0,0,0,1);
        S_I_done_ready=1; wait(S_done_count==S_done_before+3);
        @(negedge S_I_clk); S_I_done_ready=0; close_file(2);
        read_file(2,16'h205,0,1,0,0,7,1); accept_done;
        open_path(2,16'h106,"music",5,8); open_result(2,16'h106,17,0,0);
        open_path(2,16'h107,"missing.wav",11,8); open_result(2,16'h107,14,0,0);
        // Roll back a descriptor if cancel arrives after load committed.
        open_path(2,16'h108,"image.bmp",9,8); wait(u_dut.S_open_state==3);
        @(negedge S_I_clk); S_I_open_cancel=1; @(negedge S_I_clk); S_I_open_cancel=0;
        open_result(2,16'h108,8,0,0); read_file(2,16'h206,0,1,0,0,7,0); accept_done;
        open_header(2,16'h109,9,8); @(negedge S_I_clk); S_I_open_cancel=1;
        @(negedge S_I_clk); S_I_open_cancel=0; open_result(2,16'h109,8,0,0);
        // A physically cancelled read cannot retire before done and cancel ack.
        read_file(1,16'h207,0,700,700,1,8,0); wait(S_host_state==1 && S_index>30);
        S_before=S_acks; cancel_file(1,16'h207); wait(S_O_done_valid);
        if(S_acks!=S_before+1 || S_O_cancel_done_valid) fail("physical/file cancel completion ordering");
        @(negedge S_I_clk); S_I_mount_valid=1;
        repeat(6) begin @(negedge S_I_clk); if(S_O_mount_ready) fail("mount crossed unread file done"); end
        accept_done; cancel_result(1,16'h207);
        S_I_mount_valid=0;
        close_file(1); open_path(1,16'h110,"music/THEME~1.WAV",17,8); open_result(1,16'h110,0,700,8);
        // Unmount invalidates an in-flight read but preserves geometry until drain.
        S_I_byte_ready=0; read_file(0,16'h208,0,900,900,0,1,0); wait(S_O_byte_valid);
        @(negedge S_I_clk); S_I_unmount=1; put32(44,4);
        @(negedge S_I_clk); S_I_unmount=0; wait(S_O_done_valid);
        S_I_mount_valid=1;
        repeat(6) begin
            @(negedge S_I_clk);
            if(S_O_mount_ready || S_O_mounted || S_O_root_cluster!=2 || S_O_generation!=S_generation)
                fail("new geometry visible before old request retired");
        end
        S_I_mount_valid=0; accept_done; mount_command; mount_result(0);
        if(S_O_root_cluster!=4) fail("remount did not commit new geometry");
        put32(44,2); mount_command; mount_result(0);
        S_I_byte_ready=1; read_file(0,16'h209,0,1,0,0,7,0); accept_done;
        open_path(0,16'h111,"image.bmp",9,8); open_result(0,16'h111,0,900,3);
        // Already published success must survive a later media event unchanged.
        read_file(0,16'h210,0,1,1,0,0,0); wait(S_O_done_valid);
        @(negedge S_I_clk); S_I_card_ready=0; @(negedge S_I_clk); S_I_card_ready=1;
        repeat(6) begin @(negedge S_I_clk); if(S_O_mounted || S_O_mount_ready || S_O_done_error!=0) fail("loss rewrote terminal or skipped barrier"); end
        accept_done;
        // A short loss during mounting remains a failed attempt after recovery.
        mount_command; wait(S_host_state==1 && S_index>30);
        @(negedge S_I_clk); S_I_card_ready=0; @(negedge S_I_clk); S_I_card_ready=1; mount_result(1);
        mount_command; mount_result(0);
        // Checked CRC failure propagates without publishing a descriptor.
        S_fail_lba=1232; open_path(2,16'h112,"image.bmp",9,8); open_result(2,16'h112,2,0,0);
        if(S_O_open_storage_error!=4) fail("storage error provenance"); S_fail_lba=32'hffffffff;
        open_path(2,16'h113,"image.bmp",9,8); open_result(2,16'h113,0,900,3);
        S_fail_lba=1233; read_file(2,16'h211,0,20,20,0,2,0); wait(S_O_done_valid);
        if(S_O_done_storage_error!=4) fail("file storage error provenance"); accept_done; S_fail_lba=32'hffffffff;
        read_file(2,16'h212,0,20,20,0,0,0); accept_done;
        // Restore card_ready early while old physical data are still draining.
        read_file(2,16'h213,0,20,20,0,1,0); wait(S_host_state==1 && S_index>30);
        @(negedge S_I_clk); S_I_card_ready=0; @(negedge S_I_clk); S_I_card_ready=1;
        wait(S_O_done_valid); S_I_mount_valid=1;
        repeat(6) begin @(negedge S_I_clk); if(S_O_mount_ready || S_O_mounted) fail("short loss skipped read retirement"); end
        S_I_mount_valid=0; accept_done; mount_command; mount_result(0);
        // A path lookup owns real I/O too: loss must retire it before remount.
        open_path(1,16'h114,"image.bmp",9,8); wait(S_host_state==1 && S_index>30);
        @(negedge S_I_clk); S_I_card_ready=0; @(negedge S_I_clk); S_I_card_ready=1;
        open_result(1,16'h114,1,0,0); mount_command; mount_result(0);
        open_path(2,16'h115,"image.bmp",9,8); open_result(2,16'h115,0,900,3);
        read_file(2,16'h214,0,20,20,0,0,0); accept_done;
        // Loss of a physical enumeration must drain even if card_ready returns.
        enum_path(16'h411,"/",1,8); wait(S_host_state==1 && S_index>30);
        S_before=S_acks;
        @(negedge S_I_clk); S_I_card_ready=0;
        @(negedge S_I_clk); S_I_card_ready=1; wait(S_O_enum_done_valid);
        if(S_O_mounted || S_acks!=S_before+1) fail("enum loss skipped retirement/lost latch");
        enum_result(16'h411,1,0,0,6); mount_command; mount_result(0);
        // Unmount discards a partly delivered name and still returns its old identity.
        enum_path(16'h412,"/",1,8); wait(S_O_enum_entry_valid);
        @(negedge S_I_clk); S_I_enum_entry_ready=1;
        @(negedge S_I_clk); S_I_enum_entry_ready=0; wait(S_O_enum_name_valid);
        @(negedge S_I_clk); S_I_unmount=1;
        @(negedge S_I_clk); S_I_unmount=0;
        enum_result(16'h412,1,1,0,0); mount_command; mount_result(0);
        // Published success is immutable even when the medium subsequently vanishes.
        enum_path(16'h413,"music",5,8);
        enum_entry(16'h413,"Theme One.wav",13,32,700,8,"THEME~1 WAV",1);
        wait(S_O_enum_done_valid);
        @(negedge S_I_clk); S_I_card_ready=0;
        @(negedge S_I_clk); S_I_card_ready=1;
        enum_result(16'h413,0,2,0,0); mount_command; mount_result(0);
        open_path(2,16'h116,"image.bmp",9,8); open_result(2,16'h116,0,900,3);
        read_file(2,16'h302,500,20,20,0,0,0); accept_done;
        wait(S_O_quiescent); if(S_expected_active!=0) fail("pending test identities left behind");
        S_test_pass=1; $display("PASS: real FAT32 core mount/open/read/enumerate, shared RAM, backpressure, generations and retirement barriers"); $finish;
    end
    initial begin #10000000; fail("FAT32 core watchdog"); end
endmodule
