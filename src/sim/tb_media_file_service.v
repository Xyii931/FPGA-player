`timescale 1ns/1ps
// Real mux and FAT32 core. Only host SD sectors are fixtures.
module tb_media_file_service;
    reg S_I_clk=0;
    reg [3:0] S_I_lease_request=0;
    reg [3:0] S_I_lease_active=0;
    reg [7:0] S_I_lease_context=0;
    wire [3:0] S_O_lease_grant;
    reg [3:0] S_I_client_open_valid=0;
    wire [3:0] S_O_client_open_ready;
    reg [227:0] S_I_client_open=0;
    reg [3:0] S_I_client_path_valid=0;
    wire [3:0] S_O_client_path_ready;
    reg [31:0] S_I_client_path_data=0;
    reg [3:0] S_I_client_path_last=0;
    reg [3:0] S_I_client_open_cancel=0;
    wire [3:0] S_O_client_open_result_valid;
    reg [3:0] S_I_client_open_result_ready=0;
    wire [96:0] S_O_client_open_result;
    reg [3:0] S_I_client_read_valid=0;
    wire [3:0] S_O_client_read_ready;
    reg [335:0] S_I_client_read=0;
    wire [3:0] S_O_client_byte_valid;
    reg [3:0] S_I_client_byte_ready=0;
    wire [90:0] S_O_client_byte;
    wire [3:0] S_O_client_done_valid;
    reg [3:0] S_I_client_done_ready=0;
    wire [379:0] S_O_client_done;
    reg [3:0] S_I_client_cancel_valid=0;
    wire [3:0] S_O_client_cancel_ready;
    reg [71:0] S_I_client_cancel=0;
    wire [3:0] S_O_client_cancel_done_valid;
    reg [3:0] S_I_client_cancel_done_ready=0;
    wire [49:0] S_O_client_cancel_done;
    reg [3:0] S_I_client_close_valid=0;
    wire [3:0] S_O_client_close_ready;
    reg [7:0] S_I_client_close_context=0;
    reg [3:0] S_I_client_urgent=0;
    wire S_O_busy;
    wire S_O_quiescent;
    wire [2:0] S_O_leased_contexts;
    wire [2:0] S_O_descriptors;
    wire [2:0] S_O_pending_reads;
    wire S_O_contract_fault;
    wire S_O_response_discarded;
    reg S_I_scan_valid=0;
    wire S_O_scan_ready;
    reg [15:0] S_I_scan_tag=0;
    reg [6:0] S_I_scan_path_length=0;
    reg [31:0] S_I_scan_sector_budget=0;
    reg S_I_scan_path_valid=0;
    wire S_O_scan_path_ready;
    reg [7:0] S_I_scan_path_data=0;
    reg S_I_scan_path_last=0;
    reg S_I_scan_stop=0;
    reg S_I_scan_cancel=0;
    wire S_O_scan_entry_valid;
    reg S_I_scan_entry_ready=0;
    wire [7:0] S_O_scan_attr;
    wire [31:0] S_O_scan_size;
    wire [31:0] S_O_scan_first_cluster;
    wire [87:0] S_O_scan_alias;
    wire [6:0] S_O_scan_name_length;
    wire S_O_scan_is_lfn;
    wire S_O_scan_name_valid;
    reg S_I_scan_name_ready=0;
    wire [7:0] S_O_scan_name_data;
    wire S_O_scan_name_last;
    wire S_O_scan_done_valid;
    reg S_I_scan_done_ready=0;
    wire [15:0] S_O_scan_tag;
    wire [31:0] S_O_scan_generation;
    wire [31:0] S_O_scan_sectors;
    wire [2:0] S_O_scan_warning;
    wire [7:0] S_O_scan_error;
    wire [3:0] S_O_scan_storage_error;
    reg S_I_reset=0;
    wire [2:0] S_O_urgent_context;
    reg S_I_card_ready=0;
    reg S_I_unmount=0;
    reg [32:0] S_I_capacity_sectors=0;
    reg S_I_mount_valid=0;
    wire S_O_mount_ready;
    wire S_O_mount_result_valid;
    reg S_I_mount_result_ready=0;
    wire [7:0] S_O_mount_error;
    wire [3:0] S_O_mount_storage_error;
    wire [31:0] S_O_mount_generation;
    wire S_O_mounted;
    wire [31:0] S_O_generation;
    wire S_O_sd_request_valid;
    reg S_I_sd_request_ready=0;
    wire [31:0] S_O_sd_lba;
    wire [7:0] S_O_sd_count;
    wire [1:0] S_O_sd_context;
    wire [1:0] S_O_sd_priority;
    wire [15:0] S_O_sd_tag;
    reg S_I_sd_byte_valid=0;
    wire S_O_sd_byte_ready;
    reg [7:0] S_I_sd_byte_data=0;
    reg S_I_sd_sector_last=0;
    reg S_I_sd_request_last=0;
    reg [1:0] S_I_sd_byte_context=0;
    reg [15:0] S_I_sd_byte_tag=0;
    reg S_I_sd_done_valid=0;
    wire S_O_sd_done_ready;
    reg [1:0] S_I_sd_done_context=0;
    reg [15:0] S_I_sd_done_tag=0;
    reg [3:0] S_I_sd_done_error=0;
    wire S_O_sd_cancel_valid;
    reg S_I_sd_cancel_ready=0;
    wire [1:0] S_O_sd_cancel_context;
    wire [15:0] S_O_sd_cancel_tag;
    reg S_I_sd_cancel_done_valid=0;
    wire S_O_sd_cancel_done_ready;
    reg [1:0] S_I_sd_cancel_done_context=0;
    reg [15:0] S_I_sd_cancel_done_tag=0;
    media_file_service u_dut (
        .I_clk(S_I_clk),
        .I_lease_request(S_I_lease_request),
        .I_lease_active(S_I_lease_active),
        .I_lease_context(S_I_lease_context),
        .O_lease_grant(S_O_lease_grant),
        .I_client_open_valid(S_I_client_open_valid),
        .O_client_open_ready(S_O_client_open_ready),
        .I_client_open(S_I_client_open),
        .I_client_path_valid(S_I_client_path_valid),
        .O_client_path_ready(S_O_client_path_ready),
        .I_client_path_data(S_I_client_path_data),
        .I_client_path_last(S_I_client_path_last),
        .I_client_open_cancel(S_I_client_open_cancel),
        .O_client_open_result_valid(S_O_client_open_result_valid),
        .I_client_open_result_ready(S_I_client_open_result_ready),
        .O_client_open_result(S_O_client_open_result),
        .I_client_read_valid(S_I_client_read_valid),
        .O_client_read_ready(S_O_client_read_ready),
        .I_client_read(S_I_client_read),
        .O_client_byte_valid(S_O_client_byte_valid),
        .I_client_byte_ready(S_I_client_byte_ready),
        .O_client_byte(S_O_client_byte),
        .O_client_done_valid(S_O_client_done_valid),
        .I_client_done_ready(S_I_client_done_ready),
        .O_client_done(S_O_client_done),
        .I_client_cancel_valid(S_I_client_cancel_valid),
        .O_client_cancel_ready(S_O_client_cancel_ready),
        .I_client_cancel(S_I_client_cancel),
        .O_client_cancel_done_valid(S_O_client_cancel_done_valid),
        .I_client_cancel_done_ready(S_I_client_cancel_done_ready),
        .O_client_cancel_done(S_O_client_cancel_done),
        .I_client_close_valid(S_I_client_close_valid),
        .O_client_close_ready(S_O_client_close_ready),
        .I_client_close_context(S_I_client_close_context),
        .I_client_urgent(S_I_client_urgent),
        .O_busy(S_O_busy),
        .O_quiescent(S_O_quiescent),
        .O_leased_contexts(S_O_leased_contexts),
        .O_descriptors(S_O_descriptors),
        .O_pending_reads(S_O_pending_reads),
        .O_contract_fault(S_O_contract_fault),
        .O_response_discarded(S_O_response_discarded),
        .I_scan_valid(S_I_scan_valid),
        .O_scan_ready(S_O_scan_ready),
        .I_scan_tag(S_I_scan_tag),
        .I_scan_path_length(S_I_scan_path_length),
        .I_scan_sector_budget(S_I_scan_sector_budget),
        .I_scan_path_valid(S_I_scan_path_valid),
        .O_scan_path_ready(S_O_scan_path_ready),
        .I_scan_path_data(S_I_scan_path_data),
        .I_scan_path_last(S_I_scan_path_last),
        .I_scan_stop(S_I_scan_stop),
        .I_scan_cancel(S_I_scan_cancel),
        .O_scan_entry_valid(S_O_scan_entry_valid),
        .I_scan_entry_ready(S_I_scan_entry_ready),
        .O_scan_attr(S_O_scan_attr),
        .O_scan_size(S_O_scan_size),
        .O_scan_first_cluster(S_O_scan_first_cluster),
        .O_scan_alias(S_O_scan_alias),
        .O_scan_name_length(S_O_scan_name_length),
        .O_scan_is_lfn(S_O_scan_is_lfn),
        .O_scan_name_valid(S_O_scan_name_valid),
        .I_scan_name_ready(S_I_scan_name_ready),
        .O_scan_name_data(S_O_scan_name_data),
        .O_scan_name_last(S_O_scan_name_last),
        .O_scan_done_valid(S_O_scan_done_valid),
        .I_scan_done_ready(S_I_scan_done_ready),
        .O_scan_tag(S_O_scan_tag),
        .O_scan_generation(S_O_scan_generation),
        .O_scan_sectors(S_O_scan_sectors),
        .O_scan_warning(S_O_scan_warning),
        .O_scan_error(S_O_scan_error),
        .O_scan_storage_error(S_O_scan_storage_error),
        .I_reset(S_I_reset),
        .O_urgent_context(S_O_urgent_context),
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
        .O_generation(S_O_generation),
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
        .I_sd_cancel_done_tag(S_I_sd_cancel_done_tag)
    );
    reg S_t_I_enable=0;
    reg S_t_I_reload=0;
    reg S_t_I_rescan=0;
    reg S_t_I_card_ready=0;
    reg S_t_I_storage_quiescent=0;
    reg S_t_I_mounted=0;
    reg [31:0] S_t_I_generation=0;
    wire S_t_O_unmount;
    wire S_t_O_mount_valid;
    reg S_t_I_mount_ready=0;
    reg S_t_I_mount_result_valid=0;
    wire S_t_O_mount_result_ready;
    reg [7:0] S_t_I_mount_error=0;
    reg [3:0] S_t_I_mount_storage_error=0;
    reg [31:0] S_t_I_mount_generation=0;
    wire S_t_O_scan_start_valid;
    reg S_t_I_scan_start_ready=0;
    reg S_t_I_scan_done_valid=0;
    wire S_t_O_scan_done_ready;
    wire S_t_O_scan_abort;
    wire [15:0] S_t_O_scan_tag;
    wire [31:0] S_t_O_scan_generation;
    reg [3:0] S_t_I_scan_error=0;
    reg [6:0] S_t_I_scan_count=0;
    reg S_t_I_scan_committed=0;
    reg [31:0] S_t_I_scan_generation=0;
    wire S_t_O_client_abort;
    wire S_t_O_allow_start;
    wire S_t_O_ready;
    wire S_t_O_busy;
    wire S_t_O_scan_done;
    wire [6:0] S_t_O_count;
    wire [3:0] S_t_O_error;
    wire [3:0] S_t_O_scan_error;
    wire [7:0] S_t_O_mount_error;
    wire [3:0] S_t_O_mount_storage_error;
    wire [31:0] S_t_O_generation;
    media_session_ctrl #(.RETRY_CYCLES(32'd4)) u_session (

        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_enable(S_t_I_enable),
        .I_reload(S_t_I_reload),
        .I_rescan(S_t_I_rescan),
        .I_card_ready(S_t_I_card_ready),
        .I_storage_quiescent(S_t_I_storage_quiescent),
        .I_mounted(S_t_I_mounted),
        .I_generation(S_t_I_generation),
        .O_unmount(S_t_O_unmount),
        .O_mount_valid(S_t_O_mount_valid),
        .I_mount_ready(S_t_I_mount_ready),
        .I_mount_result_valid(S_t_I_mount_result_valid),
        .O_mount_result_ready(S_t_O_mount_result_ready),
        .I_mount_error(S_t_I_mount_error),
        .I_mount_storage_error(S_t_I_mount_storage_error),
        .I_mount_generation(S_t_I_mount_generation),
        .O_scan_start_valid(S_t_O_scan_start_valid),
        .I_scan_start_ready(S_t_I_scan_start_ready),
        .I_scan_done_valid(S_t_I_scan_done_valid),
        .O_scan_done_ready(S_t_O_scan_done_ready),
        .O_scan_abort(S_t_O_scan_abort),
        .O_scan_tag(S_t_O_scan_tag),
        .O_scan_generation(S_t_O_scan_generation),
        .I_scan_error(S_t_I_scan_error),
        .I_scan_count(S_t_I_scan_count),
        .I_scan_committed(S_t_I_scan_committed),
        .I_scan_generation(S_t_I_scan_generation),
        .O_client_abort(S_t_O_client_abort),
        .O_allow_start(S_t_O_allow_start),
        .O_ready(S_t_O_ready),
        .O_busy(S_t_O_busy),
        .O_scan_done(S_t_O_scan_done),
        .O_count(S_t_O_count),
        .O_error(S_t_O_error),
        .O_scan_error(S_t_O_scan_error),
        .O_mount_error(S_t_O_mount_error),
        .O_mount_storage_error(S_t_O_mount_storage_error),
        .O_generation(S_t_O_generation)
    );
    reg S_session_test_pass=0;
    task session_mount_accept;
        begin
            wait(S_t_O_mount_valid);
            @(negedge S_I_clk); S_t_I_mount_ready=1;
            @(negedge S_I_clk); S_t_I_mount_ready=0;
        end
    endtask
    task session_scan_accept;
        input [15:0] tag;
        begin
            wait(S_t_O_scan_start_valid);
            if(S_t_O_scan_tag!==tag || S_t_O_scan_generation!==2) fail("session scan identity");
            @(negedge S_I_clk); S_t_I_scan_start_ready=1;
            @(negedge S_I_clk); S_t_I_scan_start_ready=0;
        end
    endtask
    initial begin
        @(posedge S_I_reset); @(negedge S_I_reset);
        @(negedge S_I_clk); S_t_I_enable=1; S_t_I_card_ready=1;
        repeat(8) begin
            @(negedge S_I_clk);
            if(S_t_O_mount_valid || !S_t_O_client_abort) fail("session skipped real drain");
        end
        S_t_I_storage_quiescent=1;
        session_mount_accept;
        @(negedge S_I_clk);
        S_t_I_generation=1; S_t_I_mount_generation=1; S_t_I_mount_error=4;
        S_t_I_mount_result_valid=1;
        @(posedge S_I_clk); if(!S_t_O_mount_result_ready) fail("session failed mount not consumed");
        @(negedge S_I_clk); S_t_I_mount_result_valid=0;
        if(S_t_O_error!==1) fail("session mount diagnostic");
        session_mount_accept;
        @(negedge S_I_clk);
        S_t_I_generation=2; S_t_I_mount_generation=2; S_t_I_mount_error=0;
        S_t_I_mounted=1; S_t_I_mount_result_valid=1;
        @(posedge S_I_clk); if(!S_t_O_mount_result_ready) fail("session mount result");
        @(negedge S_I_clk); S_t_I_mount_result_valid=0;
        session_scan_accept(1);
        @(negedge S_I_clk);
        S_t_I_scan_done_valid=1; S_t_I_scan_generation=2; S_t_I_scan_count=3; S_t_I_scan_committed=1;
        @(posedge S_I_clk); if(!S_t_O_scan_done_ready) fail("session scan result");
        @(negedge S_I_clk); S_t_I_scan_done_valid=0;
        if(!S_t_O_ready || !S_t_O_allow_start || S_t_O_count!==3) fail("session ready");
        S_t_I_rescan=1;
        @(negedge S_I_clk); S_t_I_rescan=0;
        session_scan_accept(3);
        @(negedge S_I_clk);
        S_t_I_reload=1; S_t_I_mounted=0; S_t_I_storage_quiescent=0;
        @(negedge S_I_clk); S_t_I_reload=0;
        repeat(8) begin
            @(negedge S_I_clk);
            if(!S_t_O_client_abort || !S_t_O_scan_abort || !S_t_O_scan_done_ready ||
                S_t_O_ready || S_t_O_mount_valid) fail("session restarted before scan retirement");
        end
        S_t_I_scan_done_valid=1; S_t_I_scan_error=2; S_t_I_scan_committed=0;
        @(negedge S_I_clk); S_t_I_scan_done_valid=0;
        repeat(8) begin @(negedge S_I_clk); if(S_t_O_mount_valid) fail("session erased old leases"); end
        S_t_I_storage_quiescent=1;
        session_mount_accept;
        @(negedge S_I_clk); S_t_I_enable=0;
        repeat(6) begin
            @(negedge S_I_clk);
            if(!S_t_O_mount_result_ready || S_t_O_mount_valid || !S_t_O_client_abort)
                fail("session disabled while mount in flight");
        end
        S_t_I_mount_result_valid=1; S_t_I_mount_error=1;
        @(negedge S_I_clk); S_t_I_mount_result_valid=0;
        repeat(4) @(negedge S_I_clk);
        if(S_t_O_ready || S_t_O_busy || S_t_O_mount_valid) fail("session disabled result drain");
        S_session_test_pass=1;
    end
    reg S_test_pass=0;
    reg [7:0] S_disk[0:3071],S_sector[0:511];
    reg [2:0] S_sd_state=0;
    reg S_sd_canceled=0,S_sd_cancel_seen=0;
    reg [3:0] S_done_seen=0;
    reg [94:0] S_held_done;
    reg [31:0] S_old_generation;
    reg S_check_data=1,S_check_done=1;
    integer S_i,S_j,S_index,S_base,S_delay,S_cycles=0,S_seen[0:2];
    always #4 S_I_clk=~S_I_clk;
    initial begin #100000000; fail("timeout"); end
    task fail;
        input [511:0] message;
        begin $display("FAIL media_file_service: %0s",message); $finish; end
    endtask
    task put16;
        input integer at,value;
        begin S_disk[at]=value; S_disk[at+1]=value>>8; end
    endtask
    task put32;
        input integer at;
        input [31:0] value;
        begin
            S_disk[at]=value; S_disk[at+1]=value>>8;
            S_disk[at+2]=value>>16; S_disk[at+3]=value>>24;
        end
    endtask
    task entry;
        input integer at,cluster;
        input [87:0] alias;
        begin
            for(S_j=0;S_j<11;S_j=S_j+1) S_disk[at+S_j]=alias[(10-S_j)*8+:8];
            S_disk[at+11]=8'h20; put16(at+26,cluster); put32(at+28,64);
        end
    endtask
    task mount_card;
        begin
            @(negedge S_I_clk); S_I_mount_valid=1;
            @(posedge S_I_clk); while(!S_O_mount_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_mount_valid=0;
            wait(S_O_mount_result_valid); #1;
            if(S_O_mount_error!==0 || !S_O_mounted) fail("mount");
            @(negedge S_I_clk); S_I_mount_result_ready=1;
            @(negedge S_I_clk); S_I_mount_result_ready=0;
        end
    endtask
    task open_file;
        input integer client,context,length;
        input [63:0] path;
        integer k;
        reg [15:0] tag;
        begin
            tag=16'h20+client;
            @(negedge S_I_clk);
            S_I_client_open[client*57+:57]={context[1:0],tag,length[6:0],32'd100};
            S_I_client_open_valid[client]=1;
            @(posedge S_I_clk); while(!S_O_client_open_ready[client]) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_client_open_valid[client]=0;
            for(k=0;k<length;k=k+1) begin
                S_I_client_path_valid[client]=1;
                S_I_client_path_data[client*8+:8]=path[(length-1-k)*8+:8];
                S_I_client_path_last[client]=k==length-1;
                @(posedge S_I_clk); while(!S_O_client_path_ready[client]) @(posedge S_I_clk);
                @(negedge S_I_clk);
            end
            S_I_client_path_valid[client]=0; S_I_client_path_last[client]=0;
            wait(S_O_client_open_result_valid[client]); #1;
            if(S_O_client_open_result!=={context[1:0],tag,S_O_generation,32'd64,8'd0,4'd0,3'd0})
                fail("open route/identity/size");
            @(negedge S_I_clk); S_I_client_open_result_ready[client]=1;
            @(negedge S_I_clk); S_I_client_open_result_ready[client]=0;
        end
    endtask
    task read_file;
        input integer client;
        reg [15:0] epoch;
        begin
            epoch=16'h100+client;
            @(negedge S_I_clk);
            S_I_client_read[client*84+:84]={client[1:0],2'd2,32'd0,32'd64,epoch};
            S_I_client_read_valid[client]=1;
            @(posedge S_I_clk); while(!S_O_client_read_ready[client]) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_client_read_valid[client]=0;
        end
    endtask
    task close_file;
        input integer client,context;
        begin
            @(negedge S_I_clk); S_I_client_close_context[client*2+:2]=context;
            S_I_client_close_valid[client]=1;
            @(posedge S_I_clk); while(!S_O_client_close_ready[client]) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_client_close_valid[client]=0;
            S_I_lease_active[client]=0;
        end
    endtask
    task enumerate_root;
        integer entries,names;
        begin
            entries=0; names=0;
            @(negedge S_I_clk); S_I_scan_valid=1; S_I_scan_tag=16'h5050;
            S_I_scan_path_length=1; S_I_scan_sector_budget=100;
            @(posedge S_I_clk); while(!S_O_scan_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_scan_valid=0;
            S_I_scan_path_valid=1; S_I_scan_path_data="/"; S_I_scan_path_last=1;
            @(posedge S_I_clk); while(!S_O_scan_path_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_scan_path_valid=0; S_I_scan_path_last=0;
            S_I_scan_entry_ready=1; S_I_scan_name_ready=1;
            while(!S_O_scan_done_valid) begin
                @(posedge S_I_clk);
                if(S_O_scan_entry_valid && S_I_scan_entry_ready) begin
                    if(S_O_scan_size!==64 || S_O_scan_attr!==8'h20) fail("enum metadata");
                    entries=entries+1;
                end
                if(S_O_scan_name_valid && S_I_scan_name_ready && S_O_scan_name_last) names=names+1;
                @(negedge S_I_clk);
            end
            if(entries!=3 || names!=3 || S_O_scan_error!==0 || S_O_scan_tag!==16'h5050 ||
                S_O_scan_generation!==S_O_generation) fail("enum with live audio files");
            S_I_scan_done_ready=1;
            @(negedge S_I_clk); S_I_scan_done_ready=0; S_I_scan_entry_ready=0; S_I_scan_name_ready=0;
        end
    endtask
    initial begin
        for(S_i=0;S_i<3072;S_i=S_i+1) S_disk[S_i]=0;
        for(S_i=0;S_i<3;S_i=S_i+1) S_seen[S_i]=0;
        put16(11,512); S_disk[13]=1; put16(14,32); S_disk[16]=2;
        put32(32,70000); put32(36,600); put32(44,2); put16(510,16'haa55);
        put32(512,32'h0ffffff8); put32(516,32'hffffffff);
        put32(520,32'h0fffffff); put32(524,32'h0fffffff);
        put32(528,32'h0fffffff); put32(536,32'h0fffffff);
        entry(1024,3,"PIC     BIN"); entry(1056,4,"A       BIN"); entry(1088,6,"B       BIN");
        for(S_i=0;S_i<64;S_i=S_i+1) begin
            S_disk[1536+S_i]=8'h20+S_i;
            S_disk[2048+S_i]=8'h60+S_i;
            S_disk[2560+S_i]=8'ha0+S_i;
        end
        S_I_lease_context={2'd0,2'd2,2'd1,2'd0};
        S_I_capacity_sectors=70000; S_I_client_byte_ready=4'hf;
        S_I_client_done_ready=4'b0110;
        @(negedge S_I_clk); S_I_reset=1;
        repeat(4) @(negedge S_I_clk); S_I_reset=0; S_I_card_ready=1;
        mount_card;
        @(negedge S_I_clk); S_I_lease_request=4'b0111;
        wait(S_O_lease_grant[2:0]==3'b111);
        @(negedge S_I_clk); S_I_lease_active=4'b0111; S_I_lease_request=0;
        open_file(0,0,8,"/PIC.BIN"); open_file(1,1,6,"/A.BIN"); open_file(2,2,6,"/B.BIN");
        if(S_O_descriptors!==3'b111) fail("three real descriptors");
        fork read_file(0); read_file(1); read_file(2); join
        wait(S_O_client_done_valid[0]); #1; S_held_done=S_O_client_done[94:0];
        // A held context0 result cannot stop contexts1/2 or change its payload.
        wait(S_done_seen[2:1]==2'b11);
        repeat(12) begin
            @(negedge S_I_clk);
            if(!S_O_client_done_valid[0] || S_O_client_done[94:0]!==S_held_done)
                fail("held result changed or other contexts blocked");
        end
        S_I_client_done_ready[0]=1; wait(S_done_seen[0]);
        @(negedge S_I_clk);
        for(S_i=0;S_i<3;S_i=S_i+1) if(S_seen[S_i]!=64) fail("three file bytes");
        // Scan cannot take context0 until image closes and releases its lease.
        S_I_lease_request[3]=1;
        repeat(8) begin @(negedge S_I_clk); if(S_O_lease_grant[3]) fail("stole image context"); end
        close_file(0,0); wait(S_O_lease_grant[3]);
        @(negedge S_I_clk); S_I_lease_active[3]=1; S_I_lease_request[3]=0;
        S_done_seen=0; S_seen[1]=0; S_seen[2]=0;
        fork enumerate_root; read_file(1); read_file(2); join
        wait(S_done_seen[2:1]==2'b11);
        @(negedge S_I_clk); S_I_lease_active[3]=0;
        // An already completed read still supports a real late cancel and ack.
        S_I_client_cancel[18+:18]={2'd1,16'h101}; S_I_client_cancel_valid[1]=1;
        @(posedge S_I_clk); while(!S_O_client_cancel_ready[1]) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_client_cancel_valid[1]=0;
        wait(S_O_client_cancel_done_valid[1]); #1;
        if(S_O_client_cancel_done!=={2'd1,16'h101,S_O_generation}) fail("late cancel route");
        @(negedge S_I_clk); S_I_client_cancel_done_ready[1]=1;
        @(negedge S_I_clk); S_I_client_cancel_done_ready[1]=0;
        // A waiting remount cannot erase descriptors or take an active lease.
        S_I_mount_valid=1;
        repeat(8) begin @(negedge S_I_clk); if(S_O_mount_ready) fail("remount skipped lease drain"); end
        S_I_mount_valid=0;
        close_file(1,1); close_file(2,2); wait(S_O_quiescent);
        S_old_generation=S_O_generation;
        @(negedge S_I_clk); S_I_card_ready=0;
        @(negedge S_I_clk); S_I_card_ready=1;
        repeat(4) @(negedge S_I_clk);
        if(S_O_mounted) fail("card recovery reused old mount");
        mount_card;
        if(S_O_generation!==S_old_generation+1 || S_O_contract_fault) fail("remount generation/fault");
        // Lose media while an accepted read is in flight; keep all real debts.
        S_check_data=0; S_check_done=0;
        S_I_lease_request=2; wait(S_O_lease_grant[1]);
        @(negedge S_I_clk); S_I_lease_active=2; S_I_lease_request=0;
        open_file(1,1,6,"/A.BIN");
        S_done_seen=0; read_file(1);
        wait(S_sd_state==1);
        @(negedge S_I_clk); S_I_card_ready=0;
        S_I_client_cancel[18+:18]={2'd1,16'h101}; S_I_client_cancel_valid[1]=1;
        @(posedge S_I_clk); while(!S_O_client_cancel_ready[1]) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_client_cancel_valid[1]=0;
        wait(S_O_client_cancel_done_valid[1]);
        @(negedge S_I_clk); S_I_client_cancel_done_ready[1]=1;
        @(negedge S_I_clk); S_I_client_cancel_done_ready[1]=0;
        wait(S_done_seen[1]); close_file(1,1); wait(S_O_quiescent);
        if(S_O_contract_fault || S_O_pending_reads!=0 || S_O_descriptors!=0) fail("loss drain/fault");
        wait(S_session_test_pass);
        S_test_pass=1;
        $display("PASS media_file_service: three files, backpressure, scan/audio sharing, late cancel, remount and loss drain");
        $finish;
    end
    always @(posedge S_I_clk) begin
        if(!S_I_reset) begin
            if(S_O_contract_fault) fail("shared service contract fault");
            if(S_O_client_byte_valid!=0 && |(S_O_client_byte_valid & S_I_client_byte_ready)) begin
                S_i=S_O_client_byte[82:81];
                if(S_i>2 || S_O_client_byte_valid!==(4'b0001<<S_i)) fail("byte client/context route");
                if(S_check_data) begin
                    if(S_O_client_byte[80:65]!==16'h100+S_i || S_O_client_byte[64:33]!==S_O_generation ||
                        S_O_client_byte[32:1]!==S_seen[S_i] ||
                        S_O_client_byte[90:83]!==((8'h20+S_i*64+S_seen[S_i])&255) ||
                        S_O_client_byte[0]!==(S_seen[S_i]==63)) fail("file byte identity/content");
                end
                S_seen[S_i]=S_seen[S_i]+1;
            end
            for(S_i=0;S_i<3;S_i=S_i+1) if(S_O_client_done_valid[S_i] && S_I_client_done_ready[S_i]) begin
                if(S_check_done && S_O_client_done[S_i*95+:95]!==
                    {S_i[1:0],(16'h100+S_i[15:0]),S_O_generation,32'd64,1'b1,8'd0,4'd0}) fail("file done");
                S_done_seen[S_i]=1;
            end
        end
    end
    // Sector fixture returns captured data with variable gaps and delayed cancel ack.
    always @* begin
        S_I_sd_request_ready=S_sd_state==0;
        S_I_sd_cancel_ready=S_sd_state!=0 && !S_sd_cancel_seen;
    end
    always @(posedge S_I_clk) begin
        S_cycles<=S_cycles+1;
        if(S_I_reset) begin
            S_sd_state<=0; S_sd_canceled<=0; S_sd_cancel_seen<=0;
            S_I_sd_byte_valid<=0; S_I_sd_done_valid<=0; S_I_sd_cancel_done_valid<=0;
        end else begin
            if(S_O_sd_cancel_valid && S_I_sd_cancel_ready) begin
                if(S_O_sd_cancel_context!==S_I_sd_done_context || S_O_sd_cancel_tag!==S_I_sd_done_tag)
                    fail("SD cancel identity");
                S_sd_canceled<=1; S_sd_cancel_seen<=1;
            end
            case(S_sd_state)
                0:if(S_O_sd_request_valid && S_I_sd_request_ready) begin
                    if(S_O_sd_count!==1) fail("sector count");
                    case(S_O_sd_lba)
                        0:S_base=0; 32:S_base=512; 1232:S_base=1024;
                        1233:S_base=1536; 1234:S_base=2048; 1236:S_base=2560;
                        default:begin S_base=0; fail("unexpected SD LBA"); end
                    endcase
                    for(S_index=0;S_index<512;S_index=S_index+1) S_sector[S_index]=S_disk[S_base+S_index];
                    S_index=0; S_sd_state<=1; S_sd_canceled<=0; S_sd_cancel_seen<=0;
                    S_I_sd_byte_context<=S_O_sd_context; S_I_sd_byte_tag<=S_O_sd_tag;
                    S_I_sd_done_context<=S_O_sd_context; S_I_sd_done_tag<=S_O_sd_tag;
                    S_I_sd_cancel_done_context<=S_O_sd_context; S_I_sd_cancel_done_tag<=S_O_sd_tag;
                end
                1:if(S_I_sd_byte_valid && S_O_sd_byte_ready) begin
                    S_I_sd_byte_valid<=0;
                    if(S_index==511 || S_sd_canceled) begin S_delay=9; S_sd_state<=2; end
                    else S_index=S_index+1;
                end else if(!S_I_sd_byte_valid && S_cycles%4!=0) begin
                    S_I_sd_byte_data<=S_sector[S_index]; S_I_sd_byte_valid<=1;
                    S_I_sd_sector_last<=S_index==511; S_I_sd_request_last<=S_index==511;
                end
                2:if(S_delay==0) begin
                    S_I_sd_done_error<=S_sd_canceled ? 4'd6 : 4'd0;
                    S_I_sd_done_valid<=1; S_sd_state<=3;
                end else S_delay=S_delay-1;
                3:if(S_I_sd_done_valid && S_O_sd_done_ready) begin
                    S_I_sd_done_valid<=0; S_delay=40; S_sd_state<=4;
                end
                4:if(S_delay==0) begin
                    if(S_sd_cancel_seen) begin S_I_sd_cancel_done_valid<=1; S_sd_state<=5; end
                    else if(!(S_O_sd_cancel_valid && S_I_sd_cancel_ready)) S_sd_state<=0;
                end else S_delay=S_delay-1;
                5:if(S_I_sd_cancel_done_valid && S_O_sd_cancel_done_ready) begin
                    S_I_sd_cancel_done_valid<=0; S_sd_state<=0;
                end
                default:fail("SD fixture state");
            endcase
        end
    end
endmodule
