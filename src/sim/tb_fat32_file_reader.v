`timescale 1ns/1ps
module tb_fat32_file_reader;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    reg  S_I_mounted=0;
    reg [31:0] S_I_fat_lba=0;
    reg [31:0] S_I_data_lba=0;
    reg [31:0] S_I_cluster_count=0;
    reg [2:0] S_I_cluster_shift=0;
    reg  S_I_load_valid=0;
    wire  S_O_load_ready;
    reg [1:0] S_I_load_context=0;
    reg [31:0] S_I_first_cluster=0;
    reg [31:0] S_I_file_size=0;
    wire  S_O_load_result_valid;
    reg  S_I_load_result_ready=0;
    wire [1:0] S_O_load_context;
    wire [7:0] S_O_load_error;
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
    fat32_files u_dut (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_mounted(S_I_mounted),
        .I_fat_lba(S_I_fat_lba),
        .I_data_lba(S_I_data_lba),
        .I_cluster_count(S_I_cluster_count),
        .I_cluster_shift(S_I_cluster_shift),
        .I_load_valid(S_I_load_valid),
        .O_load_ready(S_O_load_ready),
        .I_load_context(S_I_load_context),
        .I_first_cluster(S_I_first_cluster),
        .I_file_size(S_I_file_size),
        .O_load_result_valid(S_O_load_result_valid),
        .I_load_result_ready(S_I_load_result_ready),
        .O_load_context(S_O_load_context),
        .O_load_error(S_O_load_error),
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
    integer S_seen[0:2],S_expected[0:2],S_start_offset[0:2],S_expected_error[0:2],S_sizes[0:2];
    reg [15:0] S_epochs[0:2];
    reg [2:0] S_finished=0;
    reg [31:0] S_fat[0:127];
    integer S_i,S_model_index=0,S_model_lba=0,S_requests=0,S_fat_requests=0,S_data_requests=0;
    integer S_order[0:127],S_before,S_cycle=0,S_model_word,S_physical_done=0;
    integer S_byte_cluster,S_expected_offset;
    reg [31:0] S_value;
    reg S_model_live=0,S_cancel_seen=0,S_allow_ack=1,S_hold_consumer=0;
    reg [3:0] S_inject_error=0;
    reg S_byte_wait=0,S_done_wait=0;
    reg [58:0] S_held_byte;
    reg [62:0] S_held_done;
    reg S_test_pass=0;
    task fail;
        input [511:0] message;
        begin $display("FAIL: file reader: %0s",message); $stop; end
    endtask
    function integer cluster_for;
        input integer context,sector;
        begin
            case(context)
                0:case(sector) 0:cluster_for=2; 1:cluster_for=7; default:cluster_for=9; endcase
                1:case(sector) 0:cluster_for=3; 1:cluster_for=8; default:cluster_for=10; endcase
                default:case(sector) 0:cluster_for=4; 1:cluster_for=11; default:cluster_for=12; endcase
            endcase
        end
    endfunction
    task load_file;
        input [1:0] context;
        input [31:0] first,size;
        input [7:0] error;
        begin
            @(negedge S_I_clk); S_I_load_context=context; S_I_first_cluster=first; S_I_file_size=size; S_I_load_valid=1;
            @(posedge S_I_clk); while(!S_O_load_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_load_valid=0;
            wait(S_O_load_result_valid); #1;
            if(S_O_load_context!==context || S_O_load_error!==error) fail("load descriptor/result");
            repeat(4) @(negedge S_I_clk);
            S_I_load_result_ready=1; @(negedge S_I_clk); S_I_load_result_ready=0;
            if(error==0) S_sizes[context]=size;
        end
    endtask
    task read_file;
        input integer context,offset,length,expected,error,priority;
        input [15:0] epoch;
        begin
            S_seen[context]=0; S_expected[context]=expected; S_start_offset[context]=offset;
            S_expected_error[context]=error; S_epochs[context]=epoch; S_finished[context]=0;
            @(negedge S_I_clk); S_I_read_context=context; S_I_offset=offset; S_I_length=length;
            S_I_epoch=epoch; S_I_read_priority=priority; S_I_read_valid=1;
            @(posedge S_I_clk); while(!S_O_read_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_read_valid=0;
        end
    endtask
    task cancel_file;
        input [1:0] context;
        input [15:0] epoch;
        begin
            @(negedge S_I_clk); S_I_cancel_context=context; S_I_cancel_epoch=epoch; S_I_cancel_valid=1;
            @(posedge S_I_clk); while(!S_O_cancel_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_cancel_valid=0; S_byte_wait=0;
        end
    endtask
    task acknowledge_cancel;
        input [1:0] context;
        input [15:0] epoch;
        begin
            wait(S_O_cancel_done_valid); #1;
            if(S_O_cancel_done_context!==context || S_O_cancel_done_epoch!==epoch) fail("file cancel identity");
            repeat(5) @(negedge S_I_clk);
            S_I_cancel_done_ready=1; @(negedge S_I_clk); S_I_cancel_done_ready=0;
        end
    endtask
    task remount_files;
        begin
            // Mutating the read-only card fixture represents replacing media.
            // Invalidate FAT copies and reload descriptors after remount.
            @(negedge S_I_clk); S_I_mounted=0;
            repeat(2) @(negedge S_I_clk); S_I_mounted=1;
            load_file(0,2,1300,0); load_file(1,3,1400,0); load_file(2,4,1536,0);
        end
    endtask
    always @(negedge S_I_clk) begin
        S_cycle=S_cycle+1; S_I_byte_ready=!S_hold_consumer && S_cycle%11>=3;
    end
    always @(posedge S_I_clk) if(!S_I_reset) begin
        if(S_O_sd_cancel_valid && S_I_sd_cancel_ready) begin
            if(S_cancel_seen || S_O_sd_cancel_tag!=S_I_sd_byte_tag || S_O_sd_cancel_context!=S_I_sd_byte_context)
                fail("sector cancel identity or duplicate");
            S_cancel_seen=1;
        end
        if(S_byte_wait && S_I_mounted && !S_I_cancel_valid && (!S_O_byte_valid ||
            {S_O_byte_context,S_O_byte_epoch,S_O_byte_offset,S_O_byte_last,S_O_byte_data}!==S_held_byte))
            fail("file byte changed under backpressure");
        if(S_done_wait && (!S_O_done_valid ||
            {S_O_done_context,S_O_done_epoch,S_O_done_bytes,S_O_done_eof,S_O_done_error,S_O_done_storage_error}!==S_held_done))
            fail("file terminal changed under backpressure");
        S_byte_wait=S_O_byte_valid && !S_I_byte_ready;
        S_held_byte={S_O_byte_context,S_O_byte_epoch,S_O_byte_offset,S_O_byte_last,S_O_byte_data};
        S_done_wait=S_O_done_valid && !S_I_done_ready;
        S_held_done={S_O_done_context,S_O_done_epoch,S_O_done_bytes,S_O_done_eof,S_O_done_error,S_O_done_storage_error};
        if(S_O_byte_valid && S_I_byte_ready) begin
            S_i=S_O_byte_context;
            S_expected_offset=S_start_offset[S_i]+S_seen[S_i];
            S_byte_cluster=cluster_for(S_i,S_expected_offset/512);
            if(S_O_byte_epoch!==S_epochs[S_i] || S_O_byte_offset!==S_expected_offset ||
                S_O_byte_data!==((S_byte_cluster*17+S_expected_offset%512)&255) || S_model_live)
                fail("file bytes/context/epoch/offset or data before physical retirement");
            if(S_expected_error[S_i]==0 && S_expected[S_i]>=0 &&
                S_O_byte_last!==(S_seen[S_i]+1==S_expected[S_i])) fail("file last");
            S_seen[S_i]=S_seen[S_i]+1;
        end
        if(S_O_done_valid && S_I_done_ready) begin
            S_i=S_O_done_context;
            if(S_finished[S_i] || S_O_done_epoch!==S_epochs[S_i] || S_O_done_error!==S_expected_error[S_i] ||
                S_O_done_bytes!==S_seen[S_i] || (S_expected[S_i]>=0 && S_seen[S_i]!=S_expected[S_i]))
                fail("file terminal error/byte count/identity/duplicate");
            if(S_expected_error[S_i]==0 && S_O_done_eof!==(S_start_offset[S_i]+S_seen[S_i]==S_sizes[S_i])) fail("EOF status");
            S_finished[S_i]=1;
        end
    end
    initial begin
        wait(!S_I_reset);
        forever begin
            wait(S_O_sd_request_valid); repeat(3) @(negedge S_I_clk); S_I_sd_request_ready=1;
            @(posedge S_I_clk); while(!S_O_sd_request_valid) @(posedge S_I_clk);
            if(S_O_sd_count!=1 || S_O_sd_context>2) fail("sector fields");
            S_model_lba=S_O_sd_lba; S_model_live=1; S_cancel_seen=0; S_requests=S_requests+1;
            S_I_sd_byte_tag=S_O_sd_tag; S_I_sd_byte_context=S_O_sd_context;
            S_I_sd_done_tag=S_O_sd_tag; S_I_sd_done_context=S_O_sd_context;
            if(S_model_lba==32) S_fat_requests=S_fat_requests+1;
            else begin S_order[S_data_requests]=S_O_sd_context; S_data_requests=S_data_requests+1; end
            @(negedge S_I_clk); S_I_sd_request_ready=0;
            for(S_model_index=0;S_model_index<512;S_model_index=S_model_index+1) begin
                if(S_model_lba==32) begin
                    S_value=S_fat[S_model_index/4]; S_I_sd_byte_data=S_value>>(8*(S_model_index%4));
                end else begin
                    if(S_model_lba<1232 || S_model_lba>1242) fail("file data LBA outside fixtures");
                    S_I_sd_byte_data=(S_model_lba-1232+2)*17+S_model_index;
                end
                S_I_sd_sector_last=S_model_index==511; S_I_sd_request_last=S_I_sd_sector_last; S_I_sd_byte_valid=1;
                @(posedge S_I_clk); while(!S_O_sd_byte_ready) @(posedge S_I_clk);
                @(negedge S_I_clk); S_I_sd_byte_valid=0;
                if(S_model_index%31==0) repeat(2) @(negedge S_I_clk);
            end
            repeat(4) @(negedge S_I_clk);
            S_I_sd_done_error=S_cancel_seen ? 4'd6 : S_inject_error; S_I_sd_done_valid=1;
            @(posedge S_I_clk); while(!S_O_sd_done_ready) @(posedge S_I_clk);
            S_physical_done=S_physical_done+1; S_model_live=0;
            @(negedge S_I_clk); S_I_sd_done_valid=0;
            if(S_cancel_seen) begin
                wait(S_allow_ack); repeat(7) @(negedge S_I_clk);
                S_I_sd_cancel_done_context=S_I_sd_done_context; S_I_sd_cancel_done_tag=S_I_sd_done_tag;
                S_I_sd_cancel_done_valid=1;
                @(posedge S_I_clk); while(!S_O_sd_cancel_done_ready) @(posedge S_I_clk);
                @(negedge S_I_clk); S_I_sd_cancel_done_valid=0;
            end
        end
    end
    initial begin
        S_I_reset=1; S_I_mounted=1; S_I_fat_lba=32; S_I_data_lba=1232; S_I_cluster_count=68768;
        S_I_done_ready=1; S_I_sd_cancel_ready=1;
        for(S_i=0;S_i<128;S_i=S_i+1) S_fat[S_i]=0;
        S_fat[2]=7; S_fat[7]=9; S_fat[9]=32'h0fffffff;
        S_fat[3]=8; S_fat[8]=10; S_fat[10]=32'h0fffffff;
        S_fat[4]=11; S_fat[11]=12; S_fat[12]=32'h0fffffff;
        #39; S_I_reset=0;
        load_file(0,2,1300,0); load_file(1,3,1400,0); load_file(2,4,1536,0);
        S_I_urgent_context=3'b100;
        read_file(0,500,800,800,0,0,16'h0101);
        read_file(1,0,700,700,0,3,16'h0201);
        read_file(2,510,1000,1000,0,0,16'h0301);
        wait(&S_finished); #1;
        if(S_order[0]!=0 || S_order[1]!=2) fail("urgent context not chosen at the next sector boundary");
        S_I_urgent_context=0;
        // A high-priority audio request arrives while the image is looking
        // up its next cluster. Re-arbitrate after metadata, before image data.
        S_before=S_data_requests;
        read_file(0,512,20,20,0,0,16'h0109);
        wait(u_dut.u_files.O_walk_start);
        read_file(1,0,20,20,0,3,16'h0209);
        wait(S_finished[0] && S_finished[1]);
        if(S_order[S_before]!=1) fail("audio waited behind image data after FAT lookup");
        read_file(0,512,20,20,0,0,16'h0102); wait(S_finished[0]);
        S_before=S_fat_requests;
        read_file(0,600,20,20,0,0,16'h0103); wait(S_finished[0]);
        if(S_fat_requests!=S_before) fail("same-cluster checkpoint was lost");
        read_file(0,20,30,30,0,0,16'h0104); wait(S_finished[0]);
        read_file(2,1530,100,6,0,0,16'h0302); wait(S_finished[2]);
        S_before=S_requests;
        read_file(2,1536,50,0,0,0,16'h0303); wait(S_finished[2]);
        read_file(2,1537,50,0,11,0,16'h0304); wait(S_finished[2]);
        if(S_requests!=S_before) fail("EOF/out-of-range read accessed storage");
        load_file(1,0,0,0); read_file(1,0,100,0,0,0,16'h0202); wait(S_finished[1]);
        load_file(1,1,10,9); read_file(1,0,10,0,7,0,16'h0203); wait(S_finished[1]);
        load_file(1,3,68768*512,0); load_file(1,3,68768*512+1,9);
        S_fat[3]=32'h0fffffff; remount_files;
        read_file(1,0,1100,512,12,0,16'h0204); wait(S_finished[1]);
        S_fat[3]=0; remount_files;
        read_file(1,0,1100,512,9,0,16'h0205); wait(S_finished[1]);
        S_fat[3]=8; S_fat[8]=3; remount_files; load_file(1,3,1800,0);
        read_file(1,0,1800,1024,9,0,16'h0206); wait(S_finished[1]); S_fat[8]=10;
        remount_files; S_inject_error=4;
        read_file(2,0,10,0,2,0,16'h0305); wait(S_finished[2]);
        if(S_O_done_storage_error!=4) fail("storage CRC error lost"); S_inject_error=0;
        load_file(1,3,1400,0); S_allow_ack=0; S_I_done_ready=0; S_before=S_physical_done;
        read_file(1,0,1400,0,8,0,16'h02ff);
        wait(S_model_live && S_model_index==20); cancel_file(1,16'h02ff);
        wait(S_physical_done>S_before); repeat(20) @(negedge S_I_clk);
        if(S_O_done_valid || S_O_cancel_done_valid) fail("file retired before physical cancel acknowledgement");
        S_allow_ack=1; wait(S_O_done_valid); repeat(10) @(negedge S_I_clk);
        if(S_O_cancel_done_valid) fail("file cancel bypassed unaccepted read terminal");
        S_I_done_ready=1; wait(S_finished[1]); wait(S_O_cancel_done_valid);
        @(negedge S_I_clk); S_I_read_context=1; S_I_epoch=16'h02ff; S_I_read_valid=1;
        repeat(5) begin @(negedge S_I_clk); if(S_O_read_ready) fail("same epoch reused before file cancel acknowledgement"); end
        S_I_read_valid=0; acknowledge_cancel(1,16'h02ff);
        read_file(1,0,20,20,0,0,16'h02ff); wait(S_finished[1]);
        S_before=S_physical_done;
        read_file(0,0,1000,0,1,0,16'h0105); read_file(2,0,1000,0,1,0,16'h0306);
        wait(S_model_live && S_model_index==20); @(negedge S_I_clk); S_I_mounted=0; S_byte_wait=0;
        wait(S_finished[0] && S_finished[2]);
        @(negedge S_I_clk); S_I_mounted=1;
        read_file(0,0,10,0,7,0,16'h0106); wait(S_finished[0]);
        load_file(0,2,1300,0); read_file(0,0,10,10,0,0,16'h0107); wait(S_finished[0]);
        @(negedge S_I_clk); S_I_close_context=0; S_I_close_valid=1;
        @(posedge S_I_clk); while(!S_O_close_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_close_valid=0;
        read_file(0,0,10,0,7,0,16'h0108); wait(S_finished[0]);
        cancel_file(0,16'h9999); acknowledge_cancel(0,16'h9999);
        S_test_pass=1; $display("PASS: three file contexts, fragments, offsets, fairness, EOF, errors, checkpoints and ordered cancellation"); $finish;
    end
    initial begin #5000000; fail("file reader watchdog"); end
endmodule
