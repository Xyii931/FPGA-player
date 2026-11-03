`timescale 1ns/1ps
// Real chain walker + real checked sector port, with a host-side sector peer.
module tb_fat32_chain_walk;
    reg S_clk=0,S_reset=1,S_mounted=1,S_start=0,S_result_ready=0,S_cancel=0;
    always #4 S_clk=~S_clk;
    reg [31:0] S_fat_lba=32,S_cluster_count=68768,S_first=2,S_target=0,S_limit=100;
    wire S_start_ready,S_result_valid,S_eoc;
    wire [31:0] S_cluster,S_hops;
    wire [7:0] S_error;
    wire [3:0] S_storage_error;
    wire S_read_valid,S_read_ready,S_read_abort,S_read_result_valid,S_read_result_ready;
    wire [31:0] S_read_lba;
    wire [7:0] S_read_error,S_buffer_data;
    wire [3:0] S_read_storage_error;
    wire [8:0] S_buffer_address;
    wire S_request_valid,S_byte_ready,S_done_ready,S_cancel_valid,S_cancel_done_ready;
    reg S_request_ready=0,S_byte_valid=0,S_done_valid=0,S_ack_valid=0;
    wire [31:0] S_lba;
    wire [7:0] S_count;
    wire [1:0] S_context,S_priority,S_cancel_context;
    wire [15:0] S_tag,S_cancel_tag;
    reg [7:0] S_byte=0;
    reg [15:0] S_return_tag=0;
    reg [3:0] S_return_error=0,S_injected_error=0;
    reg S_last=0,S_allow_ack=1,S_bad_marker=0,S_cancel_seen=0;
    reg [31:0] S_fat[0:383];
    integer S_requests=0,S_terminals=0,S_acks=0,S_cases=0,S_i,S_model_index,S_model_word;
    integer S_before,S_terminals_before;
    reg [31:0] S_model_value;
    reg [76:0] S_held;
    reg S_test_pass=0,S_keep_cache=1;
    fat32_chain_walk u_walk (
        .I_clk(S_clk),.I_reset(S_reset),.I_mounted(S_mounted),.I_fat_lba(S_fat_lba),.I_cluster_count(S_cluster_count),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.I_first_cluster(S_first),.I_target_index(S_target),.I_hop_limit(S_limit),
        .I_cancel(S_cancel),.O_result_valid(S_result_valid),.I_result_ready(S_result_ready),
        .O_cluster(S_cluster),.O_hops(S_hops),.O_eoc(S_eoc),.O_error(S_error),.O_storage_error(S_storage_error),
        .O_read_valid(S_read_valid),.I_read_ready(S_read_ready),.O_read_lba(S_read_lba),.O_read_abort(S_read_abort),
        .I_read_result_valid(S_read_result_valid),.O_read_result_ready(S_read_result_ready),
        .I_read_error(S_read_error),.I_storage_error(S_read_storage_error),
        .O_buffer_address(S_buffer_address),.I_buffer_data(S_buffer_data));
    fat32_sector_port u_port (
        .I_clk(S_clk),.I_reset(S_reset),.I_card_ready(1'b1),
        .I_start_valid(S_read_valid),.O_start_ready(S_read_ready),.I_lba(S_read_lba),
        .I_context(2'd2),.I_priority(2'd3),.I_abort(S_read_abort),
        .O_result_valid(S_read_result_valid),.I_result_ready(S_read_result_ready),.O_error(S_read_error),.O_storage_error(S_read_storage_error),
        .I_buffer_address(S_buffer_address),.O_buffer_data(S_buffer_data),
        .O_request_valid(S_request_valid),.I_request_ready(S_request_ready),.O_lba(S_lba),.O_count(S_count),
        .O_context(S_context),.O_priority(S_priority),.O_tag(S_tag),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_sector_last(S_last),.I_request_last(S_last),.I_byte_context(2'd2),.I_byte_tag(S_return_tag),
        .I_done_valid(S_done_valid),.O_done_ready(S_done_ready),.I_done_context(2'd2),.I_done_tag(S_return_tag),.I_done_error(S_return_error),
        .O_cancel_valid(S_cancel_valid),.I_cancel_ready(1'b1),.O_cancel_context(S_cancel_context),.O_cancel_tag(S_cancel_tag),
        .I_cancel_done_valid(S_ack_valid),.O_cancel_done_ready(S_cancel_done_ready),
        .I_cancel_done_context(2'd2),.I_cancel_done_tag(S_return_tag));
    task fail;
        input [511:0] message;
        begin $display("FAIL: chain case %0d: %0s",S_cases,message); $stop; end
    endtask
    task normal_chain;
        begin
            for(S_i=0;S_i<384;S_i=S_i+1) S_fat[S_i]=0;
            S_fat[2]=32'hf0000007; S_fat[7]=130; S_fat[130]=131;
            S_fat[131]=260; S_fat[260]=32'h0fffffff;
            S_first=2; S_fat_lba=32; S_cluster_count=68768; S_limit=100;
            S_bad_marker=0; S_injected_error=0; S_mounted=1; S_allow_ack=1;
        end
    endtask
    task launch;
        input [31:0] target;
        begin
            S_cases=S_cases+1; S_before=S_requests; S_terminals_before=S_terminals;
            // Fault cases change the virtual card: remount invalidates copies.
            if(!S_keep_cache) begin
                @(negedge S_clk); S_mounted=0;
                repeat(2) @(negedge S_clk); S_mounted=1;
            end
            @(negedge S_clk); S_target=target; S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
        end
    endtask
    task expect_result;
        input [7:0] error;
        input eoc;
        input [31:0] cluster,hops;
        input integer requests;
        begin
            wait(S_result_valid); #1;
            if(S_error!==error || S_eoc!==eoc || S_cluster!==cluster || S_hops!==hops || S_requests-S_before!=requests)
                fail("cluster/hops/EOC/error or FAT cache read count");
            S_held={S_cluster,S_hops,S_eoc,S_error,S_storage_error};
            repeat(8) begin
                @(negedge S_clk);
                if(!S_result_valid || S_start_ready || {S_cluster,S_hops,S_eoc,S_error,S_storage_error}!==S_held)
                    fail("result changed under backpressure");
            end
            S_result_ready=1; @(negedge S_clk); S_result_ready=0;
        end
    endtask
    always @(posedge S_clk) if(!S_reset && S_cancel_valid) begin
        if(S_cancel_context!=2 || S_cancel_tag!=S_return_tag || S_cancel_seen) fail("cancel identity/duplicate");
        S_cancel_seen=1;
    end
    initial begin
        wait(!S_reset);
        forever begin
            wait(S_request_valid); repeat(4) @(negedge S_clk); S_request_ready=1;
            @(posedge S_clk); while(!S_request_valid) @(posedge S_clk);
            if(S_count!=1 || S_context!=2 || S_priority!=3 || S_lba<32 || S_lba>34)
                fail("FAT sector request address/identity");
            S_model_word=(S_lba-32)*128; S_requests=S_requests+1; S_return_tag=S_tag; S_cancel_seen=0;
            @(negedge S_clk); S_request_ready=0;
            for(S_model_index=0;S_model_index<512;S_model_index=S_model_index+1) begin
                S_model_value=S_fat[S_model_word+S_model_index/4];
                S_byte=S_model_value>>(8*(S_model_index%4));
                S_last=S_model_index==(S_bad_marker ? 510 : 511); S_byte_valid=1;
                @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
                @(negedge S_clk); S_byte_valid=0;
                if(S_model_index%29==0) repeat(2) @(negedge S_clk);
            end
            repeat(6) @(negedge S_clk);
            S_return_error=S_cancel_seen ? 4'd6 : S_injected_error; S_done_valid=1;
            @(posedge S_clk); while(!S_done_ready) @(posedge S_clk);
            S_terminals=S_terminals+1;
            @(negedge S_clk); S_done_valid=0;
            if(S_cancel_seen) begin
                wait(S_allow_ack); repeat(9) @(negedge S_clk); S_ack_valid=1;
                @(posedge S_clk); while(!S_cancel_done_ready) @(posedge S_clk);
                S_acks=S_acks+1; @(negedge S_clk); S_ack_valid=0;
            end
        end
    end
    initial begin
        normal_chain; #39; S_reset=0;
        launch(0); expect_result(0,0,2,0,0);
        launch(1); expect_result(0,0,7,1,1);
        // Destroy the shared RAM contents after returning ownership. A cache
        // hit must use its own copy, not stale data in fat32_sector_port.
        for(S_i=0;S_i<512;S_i=S_i+1) u_port.S_ram[S_i]=8'hff;
        launch(2); expect_result(0,0,130,2,0);
        launch(3); expect_result(0,0,131,3,1);
        launch(4); expect_result(0,0,260,4,0);
        launch(5); expect_result(0,1,260,4,1);
        S_keep_cache=0;
        S_fat[2]=0; launch(1); expect_result(9,0,2,0,1);
        S_fat[2]=1; launch(1); expect_result(9,0,2,0,1);
        S_fat[2]=32'h0ffffff7; launch(1); expect_result(9,0,2,0,1);
        S_fat[2]=32'h0ffffff0; launch(1); expect_result(9,0,2,0,1);
        S_fat[2]=68770; launch(1); expect_result(9,0,2,0,1);
        S_fat[2]=2; launch(1); expect_result(9,0,2,0,1);
        normal_chain; S_fat[7]=2; launch(4); expect_result(9,0,7,1,1);
        normal_chain; S_fat[131]=130; launch(20); expect_result(9,0,130,4,2);
        normal_chain; S_limit=4; launch(5); expect_result(10,0,2,0,0);
        normal_chain; S_limit=0; launch(0); expect_result(10,0,2,0,0);
        normal_chain; S_first=1; launch(0); expect_result(9,0,1,0,0);
        normal_chain; S_first=68770; launch(0); expect_result(9,0,68770,0,0);
        normal_chain; S_first=130; S_fat_lba=32'hffffffff;
        launch(1); expect_result(9,0,130,0,0);
        normal_chain; S_bad_marker=1; launch(1); expect_result(2,0,2,0,1);
        normal_chain; S_injected_error=4; launch(1); expect_result(2,0,2,0,1);
        if(S_storage_error!=4) fail("underlying storage error lost");
        normal_chain; S_allow_ack=0; launch(4);
        wait(S_byte_valid && S_model_index==20); @(negedge S_clk); S_cancel=1;
        @(negedge S_clk); S_cancel=0;
        wait(S_terminals>S_terminals_before); repeat(20) @(negedge S_clk);
        if(S_result_valid || S_start_ready || !S_cancel_seen) fail("cancel retired before ordered acknowledgement");
        S_allow_ack=1; expect_result(8,0,2,0,1);
        normal_chain; launch(4);
        wait(S_byte_valid && S_model_index==20); @(negedge S_clk); S_mounted=0;
        expect_result(1,0,2,0,1);
        normal_chain; launch(4); expect_result(0,0,260,4,2);
        if(S_acks!=2) fail("missing physical cancel retirement");
        S_test_pass=1; $display("PASS: fragmented FAT chains, sector cache, EOC, reserved/bad/loop/budget and cancel drain"); $finish;
    end
    initial begin #2000000; fail("chain watchdog"); end
endmodule
