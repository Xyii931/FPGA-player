`timescale 1ns/1ps
// Integration above the checked sector boundary; SPI and the port are separate tests.
module tb_fat32_directory;
    reg S_clk=0,S_reset=1,S_mounted=1,S_start=0,S_stop=0,S_cancel=0,S_done_ready=0;
    always #4 S_clk=~S_clk;
    reg [31:0] S_first=2,S_budget=8;
    reg [2:0] S_shift=0;
    wire S_start_ready,S_entry_valid,S_name_valid,S_last,S_done;
    reg S_entry_ready=0,S_name_ready=0;
    wire [7:0] S_attr,S_name,S_error;
    wire [31:0] S_size,S_cluster,S_sectors;
    wire [87:0] S_alias;
    wire [6:0] S_length;
    wire S_lfn;
    wire [3:0] S_storage_error;
    wire [2:0] S_warning;
    wire S_read_valid,S_read_abort,S_read_result_ready;
    wire [31:0] S_read_lba;
    wire [8:0] S_buffer_address;
    reg [7:0] S_buffer_data=0;
    reg [7:0] S_ram[0:511],S_disk[0:1023];
    reg [1:0] S_model_state=0;
    reg [7:0] S_model_error=0;
    reg [3:0] S_model_storage_error=0;
    reg S_aborted=0,S_loop=0,S_force_error=0;
    integer S_delay=0,S_i,S_j,S_index,S_at,S_base,S_cycle=0,S_requests=0,S_fat_reads=0;
    integer S_entries=0,S_names=0,S_position=0,S_before,S_before_entries,S_cases=0;
    reg [7:0] S_checksum;
    reg [87:0] S_short="FILE    WAV";
    reg [167:0] S_entry_held;
    reg [8:0] S_name_held;
    reg S_entry_wait=0,S_name_wait=0,S_test_pass=0;
    fat32_directory u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_mounted(S_mounted),.I_fat_lba(32'd32),.I_data_lba(32'd1232),
        .I_cluster_count(32'd68768),.I_cluster_shift(S_shift),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_first_cluster(S_first),.I_sector_budget(S_budget),.I_stop(S_stop),.I_cancel(S_cancel),
        .O_entry_valid(S_entry_valid),.I_entry_ready(S_entry_ready),.O_attr(S_attr),.O_size(S_size),.O_first_cluster(S_cluster),
        .O_alias(S_alias),.O_name_length(S_length),.O_is_lfn(S_lfn),.O_name_valid(S_name_valid),.I_name_ready(S_name_ready),
        .O_name_data(S_name),.O_name_last(S_last),.O_done_valid(S_done),.I_done_ready(S_done_ready),
        .O_error(S_error),.O_storage_error(S_storage_error),.O_sectors(S_sectors),.O_warning(S_warning),
        .O_read_valid(S_read_valid),.I_read_ready(S_model_state==0),.O_read_lba(S_read_lba),.O_read_abort(S_read_abort),
        .I_read_result_valid(S_model_state==2),.O_read_result_ready(S_read_result_ready),
        .I_read_error(S_model_error),.I_storage_error(S_model_storage_error),.O_buffer_address(S_buffer_address),.I_buffer_data(S_buffer_data));
    task fail;
        input [511:0] message;
        begin $display("FAIL: directory integration %0d: %0s",S_cases,message); $stop; end
    endtask
    task image;
        begin
            for(S_i=0;S_i<1024;S_i=S_i+1) S_disk[S_i]=0;
            for(S_i=0;S_i<32;S_i=S_i+1) S_disk[S_i*32]=8'he5;
            S_checksum=0;
            for(S_i=0;S_i<11;S_i=S_i+1) begin
                S_disk[544+S_i]=S_short[(10-S_i)*8+:8];
                S_checksum={S_checksum[0],S_checksum[7:1]}+S_disk[544+S_i];
            end
            S_disk[555]=32; S_disk[570]=3; S_disk[572]=100;
            for(S_j=1;S_j<=2;S_j=S_j+1) begin
                S_base=S_j==2 ? 480 : 512;
                S_disk[S_base]=S_j==2 ? 8'h42 : 8'h01; S_disk[S_base+11]=15; S_disk[S_base+13]=S_checksum;
                for(S_i=0;S_i<13;S_i=S_i+1) begin
                    case(S_i)
                        0:S_at=1; 1:S_at=3; 2:S_at=5; 3:S_at=7; 4:S_at=9; 5:S_at=14;
                        6:S_at=16; 7:S_at=18; 8:S_at=20; 9:S_at=22; 10:S_at=24; 11:S_at=28; default:S_at=30;
                    endcase
                    S_disk[S_base+S_at]=65+(S_j-1)*13+S_i;
                end
            end
            S_disk[576]=0; S_first=2; S_budget=8; S_shift=0; S_mounted=1; S_loop=0; S_force_error=0;
        end
    endtask
    task launch;
        begin
            S_cases=S_cases+1; S_before=S_requests; S_before_entries=S_entries;
            @(negedge S_clk); S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
        end
    endtask
    task finish;
        input [7:0] error;
        input integer entries,sectors;
        begin
            wait(S_done); #1;
            if(S_error!==error || S_entries-S_before_entries!=entries || S_sectors!=sectors || S_model_state!=0)
                fail("joined completion/error/sectors or in-flight sector released early");
            repeat(7) begin @(negedge S_clk); if(!S_done || S_error!==error) fail("terminal backpressure"); end
            S_done_ready=1; @(negedge S_clk); S_done_ready=0;
        end
    endtask
    always @(posedge S_clk) begin
        S_buffer_data<=S_ram[S_buffer_address];
        if(!S_reset) begin
            if(S_model_state==0 && S_read_valid) begin
                S_requests=S_requests+1; S_delay=40; S_aborted=0; S_model_state<=1;
                S_model_error=0; S_model_storage_error=0;
                if(S_read_lba==32) begin
                    S_fat_reads=S_fat_reads+1;
                    for(S_index=0;S_index<512;S_index=S_index+1) S_ram[S_index]=0;
                    S_ram[8]=7;
                    if(S_loop) S_ram[28]=2;
                    else begin S_ram[28]=255; S_ram[29]=255; S_ram[30]=255; S_ram[31]=15; end
                end else begin
                    if(S_read_lba==1232) S_base=0;
                    else if((S_shift==0 && S_read_lba==1237) || (S_shift==1 && S_read_lba==1233)) S_base=512;
                    else begin S_base=0; fail("directory LBA or cluster mapping"); end
                    for(S_index=0;S_index<512;S_index=S_index+1) S_ram[S_index]=S_disk[S_base+S_index];
                end
            end else if(S_model_state==1) begin
                if(S_read_abort) S_aborted=1;
                if(S_delay==0) begin
                    S_model_error=S_aborted ? 8'd8 : (S_force_error ? 8'd2 : 8'd0);
                    S_model_storage_error=S_aborted ? 4'd6 : (S_force_error ? 4'd4 : 4'd0); S_model_state<=2;
                end else S_delay=S_delay-1;
            end else if(S_model_state==2 && S_read_result_ready) S_model_state<=0;
        end
    end
    always @(negedge S_clk) begin
        S_cycle=S_cycle+1; S_entry_ready=S_cycle%9>=3; S_name_ready=S_cycle%7>=2;
    end
    always @(posedge S_clk) if(!S_reset) begin
        if(S_entry_wait && !S_stop && !S_cancel && (!S_entry_valid ||
            {S_attr,S_size,S_cluster,S_alias,S_length,S_lfn}!==S_entry_held)) fail("entry metadata stability");
        if(S_name_wait && !S_stop && !S_cancel && (!S_name_valid || {S_last,S_name}!==S_name_held)) fail("name stability");
        S_entry_wait=S_entry_valid && !S_entry_ready; S_entry_held={S_attr,S_size,S_cluster,S_alias,S_length,S_lfn};
        S_name_wait=S_name_valid && !S_name_ready; S_name_held={S_last,S_name};
        if(S_entry_valid && S_entry_ready) begin
            if(S_attr!=32 || S_size!=100 || S_cluster!=3 || S_length!=26 || !S_lfn) fail("cross-cluster entry metadata");
            S_entries=S_entries+1; S_position=0;
        end
        if(S_name_valid && S_name_ready) begin
            if(S_name!==8'd65+S_position || S_last!==(S_position==25)) fail("cross-cluster LFN bytes");
            S_position=S_position+1; if(S_last) S_names=S_names+1;
        end
    end
    initial begin
        image; #39; S_reset=0;
        launch; finish(0,1,2);
        image; S_disk[576]=8'he5; launch; finish(0,1,2);
        image; S_shift=1; S_i=S_fat_reads; launch; finish(0,1,2);
        if(S_fat_reads!=S_i) fail("cluster-internal second sector unexpectedly traversed FAT");
        image; S_budget=1; launch; finish(10,0,1);
        image; S_loop=1; S_disk[576]=8'he5; launch; finish(9,1,2);
        image; S_first=1; launch; finish(9,0,0);
        image; S_budget=0; launch; finish(10,0,0);
        image; S_disk[0]=0; launch; finish(0,0,1);
        image; launch; wait(S_model_state==1); @(negedge S_clk); S_stop=1;
        @(negedge S_clk); S_stop=0; finish(0,0,0);
        image; launch; wait(S_model_state==1); @(negedge S_clk); S_cancel=1;
        @(negedge S_clk); S_cancel=0; finish(8,0,0);
        image; launch; wait(S_model_state==1); @(negedge S_clk); S_mounted=0;
        finish(1,0,0);
        image; S_force_error=1; launch; finish(2,0,0);
        image; launch; finish(0,1,2);
        if(S_entries!=S_names) fail("lost directory name");
        S_test_pass=1; $display("PASS: directory stream/parser join, fragmented cross-cluster LFN, budget/loop and retirement"); $finish;
    end
    initial begin #3000000; fail("directory integration watchdog"); end
endmodule
