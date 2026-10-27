`timescale 1ns/1ps
module tb_sd_sector_reader;
    wire [4:0] S_done;
    reg S_test_pass=0;
    sector_reader_case #(0,1) u_sdhc(S_done[0]);
    sector_reader_case #(0,0) u_v2_sdsc(S_done[1]);
    sector_reader_case #(1,0) u_legacy(S_done[2]);
    sector_reader_case #(0,1,1,4) u_storage_fast_host(S_done[3]);
    sector_reader_case #(1,0,1,20) u_storage_slow_host(S_done[4]);
    initial begin
        wait(&S_done); S_test_pass=1;
        $display("PASS: sector reader SDHC/SDSC/legacy, arbitration, CRC commit, cancel and recovery"); $finish;
    end
    initial begin #20000000; $display("FAIL: sector reader watchdog"); $stop; end
endmodule

module sector_reader_case #(
    parameter integer LEGACY=0,HIGH_CAPACITY=1,USE_BRIDGE=0,HOST_HALF=5
) (output reg O_done=0);
    reg S_clk=0,S_sd_clk=0,S_reset=1,S_request=0,S_cancel=0;
    always #(HOST_HALF) S_clk=~S_clk;
    always #5 S_sd_clk=~S_sd_clk;
    reg [31:0] S_lba=0;
    reg [7:0] S_count=0;
    reg [1:0] S_context=0,S_priority=0,S_cancel_context=0;
    reg [15:0] S_tag=0,S_cancel_tag=0;
    reg [2:0] S_urgent=0;
    wire S_request_ready,S_byte_valid,S_sector_last,S_request_last,S_done_valid,S_cancel_ready,S_cancel_done;
    reg S_byte_ready=0,S_done_ready=1,S_cancel_done_ready=0;
    wire [7:0] S_byte;
    wire [1:0] S_byte_context,S_done_context,S_cancel_done_context;
    wire [15:0] S_byte_tag,S_done_tag,S_cancel_done_tag;
    wire [3:0] S_error,S_card_error;
    wire S_card_ready,S_card_present,S_high_capacity,S_ncs,S_sclk,S_mosi,S_miso;
    wire [32:0] S_capacity;
    reg S_present=1,S_allow_init=1,S_corrupt=0,S_allow_bytes=1;
    wire [31:0] S_read_count,S_last_lba,S_probe_count,S_cmd16_count,S_acmd41_count;
    wire S_model_error;
    integer S_expected_base[0:15],S_expected_count[0:15],S_expected_context[0:15],S_expected_error[0:15];
    integer S_bytes_seen[0:15],S_done_seen[0:15];
    integer S_cycle=0,S_k,S_tag_index,S_expected_lba,S_expected_byte,S_seen_reads=0,S_order[0:15];
    integer S_completion_total=0,S_read_before;
    wire S_internal_canceled,S_internal_block_good,S_internal_phy_busy;
    wire S_internal_read_send;
    wire [5:0] S_internal_phy_index;
    wire [9:0] S_internal_write_count;
    reg [15:0] S_drop_data=0;
    wire S_canceling_data=S_internal_canceled ||
        (S_cancel && S_cancel_ready && S_cancel_context==S_byte_context && S_cancel_tag==S_byte_tag);
    reg S_wait_byte=0,S_wait_done=0;
    reg [27:0] S_held_byte;
    reg [21:0] S_held_done;
    generate if(USE_BRIDGE) begin : g_bridge
    sd_storage #(.INIT_DIVIDER(6),.POWERUP_CYCLES(8),.INIT_TIMEOUT_CYCLES(100000),
        .INIT_POLL_CYCLES(100),.RETRY_CYCLES(3000),.PROBE_CYCLES(50000),
        .DELIVERY_TIMEOUT_CYCLES(10000),.RESPONSE_TIMEOUT_CYCLES(2000),
        .TOKEN_TIMEOUT_CYCLES(1000),.BUSY_TIMEOUT_CYCLES(1000),.STALL_TIMEOUT_CYCLES(1000)) u_dut (
        .I_host_clk(S_clk),.I_sd_clk(S_sd_clk),.I_async_reset(S_reset),.I_request_valid(S_request),.O_request_ready(S_request_ready),
        .I_lba(S_lba),.I_count(S_count),.I_context(S_context),.I_priority(S_priority),.I_tag(S_tag),
        .I_urgent_context(S_urgent),.O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),
        .O_sector_last(S_sector_last),.O_request_last(S_request_last),.O_byte_context(S_byte_context),.O_byte_tag(S_byte_tag),
        .O_done_valid(S_done_valid),.I_done_ready(S_done_ready),.O_done_context(S_done_context),
        .O_done_tag(S_done_tag),.O_done_error(S_error),.I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),
        .I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),.O_cancel_done_valid(S_cancel_done),
        .I_cancel_done_ready(S_cancel_done_ready),.O_cancel_done_context(S_cancel_done_context),.O_cancel_done_tag(S_cancel_done_tag),
        .O_card_ready(S_card_ready),.O_capacity_sectors(S_capacity),.O_sd_high_capacity(S_high_capacity),.O_card_present(S_card_present),.O_sd_card_error(S_card_error),
        .O_sd_ncs(S_ncs),.O_sd_sclk(S_sclk),.O_sd_mosi(S_mosi),.I_sd_miso(S_miso));
        assign S_internal_write_count=u_dut.u_reader.S_write_count;
        assign S_internal_block_good=u_dut.u_reader.S_block_good;
        assign S_internal_phy_busy=u_dut.u_reader.S_phy_busy;
        assign S_internal_phy_index=u_dut.u_reader.u_phy.S_index;
        assign S_internal_canceled=u_dut.u_reader.S_canceled[u_dut.u_reader.S_active];
        assign S_internal_read_send=u_dut.u_reader.S_state==u_dut.u_reader.READ_SEND;
        always @(posedge S_sd_clk) if(!S_reset && u_dut.S_byte_valid && u_dut.S_byte_ready)
            if(!S_internal_block_good || S_internal_write_count!=512 || S_internal_phy_busy)
                fail("bridge input before CRC/physical completion");
    end else begin : g_direct
    sd_sector_reader #(.INIT_DIVIDER(6),.POWERUP_CYCLES(8),.INIT_TIMEOUT_CYCLES(100000),
        .INIT_POLL_CYCLES(100),.RETRY_CYCLES(3000),.PROBE_CYCLES(50000),
        .DELIVERY_TIMEOUT_CYCLES(10000),.RESPONSE_TIMEOUT_CYCLES(2000),
        .TOKEN_TIMEOUT_CYCLES(1000),.BUSY_TIMEOUT_CYCLES(1000),.STALL_TIMEOUT_CYCLES(1000)) u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_request_valid(S_request),.O_request_ready(S_request_ready),
        .I_lba(S_lba),.I_count(S_count),.I_context(S_context),.I_priority(S_priority),.I_tag(S_tag),
        .I_urgent_context(S_urgent),.O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),
        .O_sector_last(S_sector_last),.O_request_last(S_request_last),.O_byte_context(S_byte_context),.O_byte_tag(S_byte_tag),
        .O_done_valid(S_done_valid),.I_done_ready(S_done_ready),.O_done_context(S_done_context),
        .O_done_tag(S_done_tag),.O_done_error(S_error),.I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),
        .I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),.O_cancel_done_valid(S_cancel_done),
        .I_cancel_done_ready(S_cancel_done_ready),.O_cancel_done_context(S_cancel_done_context),.O_cancel_done_tag(S_cancel_done_tag),
        .O_card_ready(S_card_ready),.O_capacity_sectors(S_capacity),.O_high_capacity(S_high_capacity),.O_card_present(S_card_present),.O_card_error(S_card_error),
        .O_sd_ncs(S_ncs),.O_sd_sclk(S_sclk),.O_sd_mosi(S_mosi),.I_sd_miso(S_miso));
        assign S_internal_write_count=u_dut.S_write_count;
        assign S_internal_block_good=u_dut.S_block_good;
        assign S_internal_phy_busy=u_dut.S_phy_busy;
        assign S_internal_phy_index=u_dut.u_phy.S_index;
        assign S_internal_canceled=u_dut.S_canceled[u_dut.S_active];
        assign S_internal_read_send=u_dut.S_state==u_dut.READ_SEND;
        always @(posedge S_clk) if(!S_reset && S_internal_read_send && u_dut.S_cancel_active)
            if(u_dut.u_phy.I_cmd_valid) fail("canceled READ_SEND asserted PHY command valid");
    end endgenerate
    // Interface envelope, independent of the internal controller/FIFO checks:
    // 7 ns outward, 14 ns card response, 5 ns inward (FPGA and PCB budget).
    wire S_card_clk,S_card_ncs,S_card_mosi,S_card_miso;
    assign #7 S_card_clk=S_sclk;
    assign #7 S_card_ncs=S_ncs;
    assign #7 S_card_mosi=S_mosi;
    assign #5 S_miso=S_card_miso;
    sd_spi_card_model #(.OUTPUT_DELAY_NS(14)) u_card (
        .I_ncs(S_card_ncs),.I_sclk(S_card_clk),.I_mosi(S_card_mosi),.O_miso(S_card_miso),
        .I_present(S_present),.I_legacy(LEGACY!=0),.I_high_capacity(HIGH_CAPACITY!=0),
        .I_allow_init(S_allow_init),.I_corrupt_crc(S_corrupt),.O_read_count(S_read_count),.O_last_lba(S_last_lba),
        .O_probe_count(S_probe_count),.O_cmd16_count(S_cmd16_count),.O_acmd41_count(S_acmd41_count),.O_protocol_error(S_model_error));
    task fail;
        input [511:0] message;
        begin $display("FAIL in %m: %0s",message); $stop; end
    endtask
    task request;
        input integer tag,context,lba,count,priority,error;
        begin
            S_expected_base[tag]=lba; S_expected_count[tag]=count; S_expected_context[tag]=context;
            S_expected_error[tag]=error; S_drop_data[tag]=0; S_bytes_seen[tag]=0; S_done_seen[tag]=0;
            @(negedge S_clk); S_tag=tag; S_context=context; S_lba=lba; S_count=count; S_priority=priority; S_request=1;
            @(posedge S_clk); while(!S_request_ready) @(posedge S_clk);
            @(negedge S_clk); S_request=0;
        end
    endtask
    task cancel_request;
        input integer tag,context;
        begin
            @(negedge S_clk); S_cancel_tag=tag; S_cancel_context=context; S_cancel=1;
            @(posedge S_clk); while(!S_cancel_ready) @(posedge S_clk);
            @(negedge S_clk); S_cancel=0; S_drop_data[tag]=1;
        end
    endtask
    task accept_cancel;
        input integer tag,context;
        begin
            wait(S_cancel_done); #1;
            if(S_cancel_done_tag!=tag || S_cancel_done_context!=context || !S_done_seen[tag]) fail("cancel ack before request retirement");
            @(negedge S_clk); S_cancel_done_ready=1;
            @(negedge S_clk); S_cancel_done_ready=0;
        end
    endtask
    always @(negedge S_clk) begin
        S_cycle=S_cycle+1;
        S_byte_ready=S_allow_bytes && S_cycle%11>=3;
    end
    always @(posedge S_clk) if(!S_reset && !O_done) begin
        if(S_model_error) fail("card model protocol error");
        if(S_read_count!=S_seen_reads) begin
            if(S_seen_reads<16) S_order[S_seen_reads]=S_last_lba;
            S_seen_reads=S_read_count;
        end
        if(S_wait_byte && !S_canceling_data && (!S_byte_valid ||
            {S_byte_context,S_byte_tag,S_sector_last,S_request_last,S_byte}!==S_held_byte) && S_error!=8)
            fail("byte identity changed under backpressure");
        if(S_wait_done && (!S_done_valid || {S_done_context,S_done_tag,S_error}!==S_held_done)) fail("terminal changed under backpressure");
        S_wait_byte=S_byte_valid && !S_byte_ready;
        S_held_byte={S_byte_context,S_byte_tag,S_sector_last,S_request_last,S_byte};
        S_wait_done=S_done_valid && !S_done_ready; S_held_done={S_done_context,S_done_tag,S_error};
        if(S_byte_valid && S_byte_ready && !S_drop_data[S_byte_tag[3:0]]) begin
            S_tag_index=S_byte_tag;
            if(S_tag_index>15) fail("unknown data tag");
            S_expected_lba=S_expected_base[S_tag_index]+S_bytes_seen[S_tag_index]/512;
            S_expected_byte=(S_expected_lba+S_bytes_seen[S_tag_index]%512)&255;
            if(S_byte!==S_expected_byte[7:0] || S_byte_context!=S_expected_context[S_tag_index] ||
                S_sector_last!==(S_bytes_seen[S_tag_index]%512==511) ||
                S_request_last!==(S_bytes_seen[S_tag_index]==512*S_expected_count[S_tag_index]-1))
                fail("sector byte/identity/markers");
            if(!USE_BRIDGE && (!S_internal_block_good || S_internal_write_count!=512 || S_internal_phy_busy))
                fail("data published before CRC and physical completion");
            S_bytes_seen[S_tag_index]=S_bytes_seen[S_tag_index]+1;
        end
        if(S_done_valid && S_done_ready) begin
            S_tag_index=S_done_tag;
            if(S_tag_index>15 || S_done_context!=S_expected_context[S_tag_index] || S_error!=S_expected_error[S_tag_index])
                fail("request terminal identity/error");
            if(S_done_seen[S_tag_index]) fail("duplicate request terminal");
            if(S_error==0 && S_bytes_seen[S_tag_index]!=512*S_expected_count[S_tag_index]) fail("early success terminal");
            S_done_seen[S_tag_index]=1; S_completion_total=S_completion_total+1;
        end
    end
    initial begin
        for(S_k=0;S_k<16;S_k=S_k+1) begin
            S_expected_base[S_k]=0; S_expected_count[S_k]=0; S_expected_context[S_k]=0;
            S_expected_error[S_k]=0; S_bytes_seen[S_k]=0; S_done_seen[S_k]=0;
        end
        #31; S_reset=0;
        wait(S_card_ready); #1;
        if(S_high_capacity!==(HIGH_CAPACITY!=0) || !S_card_present || S_acmd41_count<3 ||
            ((HIGH_CAPACITY==0) && S_cmd16_count!=1) || ((HIGH_CAPACITY!=0) && S_cmd16_count!=0)) fail("card initialization branch");
        if(S_capacity!==(HIGH_CAPACITY!=0 ? 33'd8388608 : 33'd524288)) fail("CMD9 capacity / host snapshot");
        request(1,0,10,3,1,0);
        wait(S_read_count==1);
        request(2,1,40,1,3,0);
        request(3,2,70,1,2,0);
        request(4,0,90,1,1,0);
        // Full queue counts the current item; urgent context overrides priority.
        @(negedge S_clk); S_urgent=3'b100; S_tag=15;
        if(!USE_BRIDGE && S_request_ready) fail("four-entry queue exceeded");
        wait(S_done_seen[1] && S_done_seen[2] && S_done_seen[3] && S_done_seen[4]);
        if(S_order[0]!=10 || S_order[1]!=70 || S_order[2]!=40 || S_order[3]!=90 || S_order[4]!=11 || S_order[5]!=12)
            fail("sector arbitration / priority / round robin");
        S_urgent=0;

        request(5,0,100,2,0,6);
        wait(S_internal_write_count>=10 && S_read_count==7);
        S_done_ready=0;
        cancel_request(5,0);
        wait(S_done_valid); repeat(20) @(negedge S_clk);
        if(S_cancel_done || S_bytes_seen[5]!=0 || S_internal_phy_busy) fail("cancel completed before physical/terminal drain");
        S_done_ready=1; wait(S_done_seen[5]); wait(S_cancel_done);
        if(!USE_BRIDGE) begin
            @(negedge S_clk); S_tag=5; S_context=0; S_request=1;
            repeat(10) begin @(negedge S_clk); if(S_request_ready) fail("same tag reused before cancel ack"); end
            S_request=0;
        end else repeat(10) @(negedge S_clk);
        accept_cancel(5,0);
        request(5,0,120,1,0,0); wait(S_done_seen[5]);

        // A bad CRC never enters the user byte stream; queued requests retire.
        S_corrupt=1;
        request(6,1,150,1,0,4);
        wait(S_last_lba==150);
        request(7,2,160,1,0,11);
        wait(S_done_seen[6] && S_done_seen[7]);
        if(S_bytes_seen[6]!=0 || S_bytes_seen[7]!=0 || S_card_ready) fail("CRC or media failure leaked bytes");
        S_corrupt=0;
        wait(S_card_ready);
        request(8,2,180,0,0,7); wait(S_done_seen[8]);

        // Idle CMD13 detects removal; no old request is replayed on insertion.
        S_read_before=S_read_count;
        @(negedge S_clk); S_present=0;
        wait(!S_card_ready);
        if(S_card_error!=1) fail("idle card loss response timeout");
        repeat(3500) @(negedge S_clk);
        S_allow_init=0; S_present=1;
        wait(S_card_error==10);
        if(S_card_ready || S_request_ready) fail("ACMD41 total initialization budget ignored");
        S_allow_init=1; wait(S_card_ready);
        if(S_read_count!=S_read_before) fail("old read replayed on new media");
        request(9,1,200,1,0,0); wait(S_done_seen[9]);

        // Queue cancellation never reaches the card; consumer stalls hold identity.
        S_allow_bytes=0;
        request(10,0,210,1,0,0); wait(S_byte_valid);
        S_read_before=S_read_count;
        request(11,2,220,1,3,6);
        cancel_request(11,2);
        repeat(20) @(negedge S_clk);
        if(S_cancel_done || S_read_count!=S_read_before) fail("queued cancellation completed before retirement");
        S_allow_bytes=1;
        wait(S_done_seen[10] && S_done_seen[11]);
        accept_cancel(11,2);
        if(S_read_count!=S_read_before || S_bytes_seen[11]!=0) fail("queued canceled sector reached card");
        S_allow_bytes=0;
        request(12,1,230,1,0,6); wait(S_byte_valid);
        cancel_request(12,1); S_allow_bytes=1; wait(S_done_seen[12]); accept_cancel(12,1);
        if(S_bytes_seen[12]!=0) fail("canceled waiting output was delivered");
        S_allow_bytes=1;
        request(13,0,S_capacity-1,1,0,0); wait(S_done_seen[13]);
        S_read_before=S_read_count;
        request(14,0,S_capacity-1,2,0,7); wait(S_done_seen[14]);
        if(S_read_count!=S_read_before || S_bytes_seen[14]!=0) fail("request crossed physical card capacity");
        // Cancel at the PHY command acceptance boundary. Registering abort
        // must not start a read that the owner has already retired.
        if(!USE_BRIDGE) begin
            S_read_before=S_read_count;
            request(15,0,240,1,0,6);
            wait(S_internal_read_send);
            cancel_request(15,0);
            wait(S_done_seen[15]); accept_cancel(15,0);
            // A periodic CMD13 probe may start after cancellation retires.
            // Check for the canceled CMD17, not unrelated background traffic.
            if(S_read_count!=S_read_before || S_bytes_seen[15]!=0 ||
                (S_internal_phy_busy && S_internal_phy_index==17)) begin
                fail("cancel at read acceptance started physical work");
            end
        end
        if(S_completion_total!=(USE_BRIDGE ? 15 : 16)) fail("missing request terminal");
        O_done=1;
    end
endmodule
