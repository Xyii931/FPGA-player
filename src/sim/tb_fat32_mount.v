`timescale 1ns/1ps
// A host-domain sector peer, deliberately separate from the SPI card model.
module tb_fat32_mount;
    reg S_clk=0,S_reset=1,S_card_ready=1,S_start=0,S_result_ready=0;
    always #4 S_clk=~S_clk;
    reg [32:0] S_capacity=100000;
    wire S_start_ready,S_result_valid,S_mounted;
    wire [7:0] S_error,S_spc;
    wire [3:0] S_storage_error;
    wire [31:0] S_partition,S_volume,S_fat,S_data,S_clusters,S_root;
    wire [2:0] S_shift;
    wire S_request_valid,S_byte_ready,S_done_ready,S_cancel_valid,S_cancel_done_ready;
    reg S_request_ready=0,S_byte_valid=0,S_done_valid=0;
    wire [31:0] S_lba;
    wire [7:0] S_count;
    wire [1:0] S_context,S_priority,S_cancel_context;
    wire [15:0] S_tag,S_cancel_tag;
    reg [7:0] S_byte=0;
    reg S_sector_last=0,S_request_last=0;
    reg [1:0] S_return_context=0;
    reg [15:0] S_return_tag=0;
    reg [3:0] S_return_error=0;
    reg [7:0] S_disk[0:1023];
    reg [31:0] S_boot_lba=2048;
    integer S_limit=512,S_requests=0,S_cases=0,S_i,S_model_index,S_model_base;
    integer S_expected_requests,S_model_limit;
    reg S_bad_markers=0,S_bad_identity=0,S_test_pass=0;
    reg [3:0] S_injected_error=0;
    reg [15:0] S_previous_tag=0;
    reg [127:0] S_held_result;
    fat32_volume u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_card_ready(S_card_ready),.I_capacity_sectors(S_capacity),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.O_result_valid(S_result_valid),.I_result_ready(S_result_ready),
        .O_error(S_error),.O_storage_error(S_storage_error),.O_mounted(S_mounted),
        .O_partition_lba(S_partition),.O_volume_sectors(S_volume),.O_fat_lba(S_fat),.O_data_lba(S_data),
        .O_cluster_count(S_clusters),.O_root_cluster(S_root),.O_sectors_per_cluster(S_spc),.O_cluster_shift(S_shift),
        .O_request_valid(S_request_valid),.I_request_ready(S_request_ready),.O_lba(S_lba),.O_count(S_count),
        .O_context(S_context),.O_priority(S_priority),.O_tag(S_tag),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_sector_last(S_sector_last),.I_request_last(S_request_last),.I_byte_context(S_return_context),.I_byte_tag(S_return_tag),
        .I_done_valid(S_done_valid),.O_done_ready(S_done_ready),.I_done_context(S_return_context),.I_done_tag(S_return_tag),.I_done_error(S_return_error),
        .O_cancel_valid(S_cancel_valid),.I_cancel_ready(1'b1),.O_cancel_context(S_cancel_context),.O_cancel_tag(S_cancel_tag),
        .I_cancel_done_valid(1'b0),.O_cancel_done_ready(S_cancel_done_ready),.I_cancel_done_context(2'd0),.I_cancel_done_tag(16'd0));
    task fail;
        input [511:0] message;
        begin $display("FAIL: mount case %0d: %0s",S_cases,message); $stop; end
    endtask
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
    task make_boot;
        input integer base;
        begin
            S_disk[base]=8'heb; S_disk[base+2]=8'h90;
            put16(base+11,512); S_disk[base+13]=1; put16(base+14,32); S_disk[base+16]=2;
            put32(base+32,70000); put32(base+36,600); put32(base+44,2); put16(base+510,16'haa55);
        end
    endtask
    task raw_disk;
        begin
            for(S_i=0;S_i<1024;S_i=S_i+1) S_disk[S_i]=0;
            make_boot(0); S_capacity=100000; S_limit=512;
            S_bad_markers=0; S_bad_identity=0; S_injected_error=0; S_card_ready=1;
        end
    endtask
    task partitioned_disk;
        begin
            raw_disk;
            for(S_i=0;S_i<512;S_i=S_i+1) S_disk[S_i]=0;
            // The first entry is Linux. FAT32 is in the second primary entry.
            S_disk[450]=8'h83; S_disk[466]=8'h0c; S_disk[462]=8'h80;
            put32(470,2048); put32(474,70000); put16(510,16'haa55); make_boot(512);
        end
    endtask
    task launch;
        begin
            S_cases=S_cases+1; S_expected_requests=S_requests;
            @(negedge S_clk); S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
        end
    endtask
    task expect_result;
        input [7:0] error;
        input integer requests;
        begin
            wait(S_result_valid); #1;
            if(S_error!==error || S_mounted!==(error==0) || S_requests-S_expected_requests!=requests)
                fail("mount error/read count/commit");
            S_held_result={S_error,S_storage_error,S_partition,S_fat,S_data,20'd0};
            repeat(9) begin
                @(negedge S_clk);
                if(!S_result_valid || S_start_ready || {S_error,S_storage_error,S_partition,S_fat,S_data,20'd0}!==S_held_result)
                    fail("terminal changed under backpressure");
            end
            S_result_ready=1; @(negedge S_clk); S_result_ready=0;
        end
    endtask
    // All producers change at negative edges; acceptance is sampled at positive edges.
    initial begin
        wait(!S_reset);
        forever begin
            wait(S_request_valid); repeat(3) @(negedge S_clk); S_request_ready=1;
            @(posedge S_clk); while(!S_request_valid) @(posedge S_clk);
            if(S_count!=1 || S_context!=0 || S_priority!=0 ||
                (S_requests>0 && S_tag!==S_previous_tag+16'd1)) fail("sector request fields/tag reuse");
            S_previous_tag=S_tag; S_requests=S_requests+1;
            if(S_lba==0) S_model_base=0;
            else if(S_lba==S_boot_lba) S_model_base=512;
            else begin S_model_base=0; fail("out-of-bounds/unexpected sector request"); end
            S_return_tag=S_tag; S_return_context=S_context; S_model_limit=S_limit;
            @(negedge S_clk); S_request_ready=0;
            for(S_model_index=0;S_model_index<S_model_limit;S_model_index=S_model_index+1) begin
                if(S_model_index%17==0) repeat(2) @(negedge S_clk);
                S_byte=S_disk[S_model_base+S_model_index]; S_byte_valid=1;
                S_sector_last=S_model_index==(S_bad_markers ? 510 : 511); S_request_last=S_sector_last;
                S_return_context=S_bad_identity ? 2'd1 : 2'd0;
                @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
                @(negedge S_clk); S_byte_valid=0;
            end
            S_return_context=0; S_return_error=S_injected_error;
            repeat(7) @(negedge S_clk); S_done_valid=1;
            @(posedge S_clk); while(!S_done_ready) @(posedge S_clk);
            @(negedge S_clk); S_done_valid=0;
        end
    end
    always @(posedge S_clk) if(!S_reset && S_cancel_valid) fail("mount unexpectedly canceled a sector");
    initial begin
        raw_disk; #37; S_reset=0;
        launch; expect_result(0,1);
        if(S_partition!=0 || S_volume!=70000 || S_fat!=32 || S_data!=1232 ||
            S_clusters!=68768 || S_root!=2 || S_spc!=1 || S_shift!=0) fail("raw geometry");
        partitioned_disk; put16(512+40,16'h0081);
        launch; expect_result(0,2);
        if(S_partition!=2048 || S_fat!=2680 || S_data!=3280 || S_clusters!=68768) fail("partition/active FAT geometry");
        raw_disk; S_disk[13]=8; put32(32,600000); S_capacity=700000;
        launch; expect_result(0,1);
        if(S_shift!=3 || S_clusters!=74846) fail("cluster shift/rounding");
        raw_disk; put16(40,16'h000f); launch; expect_result(0,1);
        if(S_fat!=32) fail("mirrored FAT incorrectly used the active-table nibble");
        raw_disk; S_disk[510]=0; launch; expect_result(3,1);
        raw_disk; S_disk[0]=0; launch; expect_result(3,1);
        raw_disk; put16(11,1024); launch; expect_result(3,1);
        raw_disk; put16(22,1); launch; expect_result(3,1);
        raw_disk; put16(42,1); launch; expect_result(3,1);
        raw_disk; S_disk[13]=3; launch; expect_result(6,1);
        raw_disk; S_disk[16]=3; launch; expect_result(6,1);
        raw_disk; put16(40,16'h82); launch; expect_result(6,1);
        raw_disk; put32(36,1); launch; expect_result(6,1);
        raw_disk; put32(32,10000); launch; expect_result(6,1);
        raw_disk; put32(44,68770); launch; expect_result(6,1);
        raw_disk; S_capacity=69999; launch; expect_result(5,1);
        partitioned_disk; put32(474,69999); launch; expect_result(5,2);
        partitioned_disk; put32(470,32'hfffffff0); S_capacity=33'h100000000;
        launch; expect_result(5,1);
        partitioned_disk; S_disk[466]=7; launch; expect_result(4,1);
        raw_disk; S_card_ready=0; launch; expect_result(1,0);
        raw_disk; S_capacity=0; launch; expect_result(5,0);
        raw_disk; S_capacity=33'h100000001; launch; expect_result(5,0);
        raw_disk; S_injected_error=4; launch; expect_result(2,1);
        if(S_storage_error!=4) fail("original storage error lost");
        raw_disk; S_bad_markers=1; launch; expect_result(2,1);
        raw_disk; S_bad_identity=1; launch; expect_result(2,1);
        raw_disk; S_limit=511; launch; expect_result(2,1);
        raw_disk; launch;
        wait(S_byte_valid && S_model_index==16); @(negedge S_clk); S_card_ready=0;
        // Do not reset or flush: the peer still returns all old bytes and done.
        expect_result(1,1);
        raw_disk; launch; expect_result(0,1);
        @(negedge S_clk); S_card_ready=0; @(negedge S_clk);
        if(S_mounted) fail("mounted survived media loss");
        S_test_pass=1; $display("PASS: checked sector buffering, FAT32 raw/MBR/active FAT, geometry, media drain and errors"); $finish;
    end
    initial begin #2000000; fail("mount watchdog"); end
endmodule
