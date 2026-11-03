`timescale 1ns/1ps
module tb_sector_cdc_bridge;
    wire [1:0] S_done;
    reg S_test_pass=0;
    sector_bridge_case #(4,5) u_fast_host(S_done[0]);
    sector_bridge_case #(20,4) u_slow_host(S_done[1]);
    initial begin wait(&S_done); S_test_pass=1; $display("PASS: ordered sector CDC, cancel drain, media barrier and clock stop"); $finish; end
    initial begin #100000; $display("FAIL: sector bridge timeout"); $stop; end
endmodule

module sector_bridge_case #(
    parameter integer HOST_HALF=4,SD_HALF=5
) (output reg O_done=0);
    reg S_host_clk=0,S_sd_clk=0,S_run_host=1,S_reset=1;
    always #(HOST_HALF) if(S_run_host) S_host_clk=~S_host_clk;
    always #(SD_HALF) S_sd_clk=~S_sd_clk;
    reg S_request=0,S_cancel=0;
    wire S_request_ready,S_cancel_ready,S_card_ready;
    reg [31:0] S_lba=0;
    reg [7:0] S_count=0;
    reg [1:0] S_context=0,S_priority=0,S_cancel_context=0;
    reg [15:0] S_tag=0,S_cancel_tag=0;
    reg [2:0] S_urgent=0;
    wire S_byte_valid,S_sector_last,S_request_last,S_done_valid,S_ack_valid;
    reg S_byte_ready=0,S_done_ready=0,S_ack_ready=0;
    wire [7:0] S_byte;
    wire [1:0] S_byte_context,S_done_context,S_ack_context;
    wire [15:0] S_byte_tag,S_done_tag,S_ack_tag;
    wire [3:0] S_error;
    reg S_sd_card_ready=0,S_sd_request_ready=0,S_sd_cancel_ready=0;
    reg [32:0] S_sd_capacity=33'h100000000;
    wire [32:0] S_capacity;
    wire S_sd_request_valid,S_sd_cancel_valid;
    wire [31:0] S_sd_lba;
    wire [7:0] S_sd_count;
    wire [1:0] S_sd_context,S_sd_priority,S_sd_cancel_context;
    wire [15:0] S_sd_tag,S_sd_cancel_tag;
    wire [2:0] S_sd_urgent;
    reg S_sd_byte_valid=0,S_sd_done_valid=0,S_sd_ack_valid=0;
    wire S_sd_byte_ready,S_sd_done_ready,S_sd_ack_ready;
    reg [7:0] S_sd_byte=0;
    reg S_sd_sector_last=0,S_sd_request_last=0;
    reg [1:0] S_sd_byte_context=0;
    reg [15:0] S_sd_byte_tag=16'h1111;
    integer S_bytes=0,S_terminals=0,S_acks=0,S_forwarded=0;
    reg [27:0] S_held_byte;
    reg [21:0] S_held_done;
    reg [17:0] S_held_ack;
    reg S_wait_byte=0,S_wait_done=0,S_wait_ack=0;
    reg S_wait_fifo=0;
    reg [33:0] S_held_fifo;
    sector_cdc_bridge #(.COMMAND_ADDR_BITS(2),.RETURN_ADDR_BITS(2)) u_dut (
        .I_host_clk(S_host_clk),.I_sd_clk(S_sd_clk),.I_async_reset(S_reset),
        .I_request_valid(S_request),.O_request_ready(S_request_ready),.I_lba(S_lba),.I_count(S_count),
        .I_context(S_context),.I_priority(S_priority),.I_tag(S_tag),
        .I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),.I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),
        .I_urgent_context(S_urgent),.O_card_ready(S_card_ready),.O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),
        .O_byte_data(S_byte),.O_sector_last(S_sector_last),.O_request_last(S_request_last),
        .O_byte_context(S_byte_context),.O_byte_tag(S_byte_tag),.O_done_valid(S_done_valid),.I_done_ready(S_done_ready),
        .O_done_context(S_done_context),.O_done_tag(S_done_tag),.O_done_error(S_error),
        .O_cancel_done_valid(S_ack_valid),.I_cancel_done_ready(S_ack_ready),.O_cancel_done_context(S_ack_context),.O_cancel_done_tag(S_ack_tag),
        .I_sd_card_ready(S_sd_card_ready),.I_sd_capacity_sectors(S_sd_capacity),.O_capacity_sectors(S_capacity),
        .O_sd_request_valid(S_sd_request_valid),.I_sd_request_ready(S_sd_request_ready),
        .O_sd_lba(S_sd_lba),.O_sd_count(S_sd_count),.O_sd_context(S_sd_context),.O_sd_priority(S_sd_priority),.O_sd_tag(S_sd_tag),
        .O_sd_cancel_valid(S_sd_cancel_valid),.I_sd_cancel_ready(S_sd_cancel_ready),
        .O_sd_cancel_context(S_sd_cancel_context),.O_sd_cancel_tag(S_sd_cancel_tag),.O_sd_urgent_context(S_sd_urgent),
        .I_sd_byte_valid(S_sd_byte_valid),.O_sd_byte_ready(S_sd_byte_ready),.I_sd_byte_data(S_sd_byte),
        .I_sd_sector_last(S_sd_sector_last),.I_sd_request_last(S_sd_request_last),
        .I_sd_byte_context(S_sd_byte_context),.I_sd_byte_tag(S_sd_byte_tag),
        .I_sd_done_valid(S_sd_done_valid),.O_sd_done_ready(S_sd_done_ready),.I_sd_done_context(2'd0),.I_sd_done_tag(16'h1111),.I_sd_done_error(4'd6),
        .I_sd_cancel_done_valid(S_sd_ack_valid),.O_sd_cancel_done_ready(S_sd_ack_ready),
        .I_sd_cancel_done_context(2'd0),.I_sd_cancel_done_tag(16'h1111));
    task fail;
        input [511:0] message;
        begin $display("FAIL in %m: %0s",message); $stop; end
    endtask
    task request;
        input [15:0] tag;
        input [1:0] context;
        input [31:0] lba;
        begin
            @(negedge S_host_clk); S_request=1; S_tag=tag; S_context=context; S_lba=lba; S_count=2; S_priority=1;
            @(posedge S_host_clk); while(!S_request_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_request=0;
        end
    endtask
    task send_byte;
        input [7:0] value;
        input last;
        input [15:0] tag;
        begin
            @(negedge S_sd_clk); S_sd_byte_valid=1; S_sd_byte=value; S_sd_byte_tag=tag;
            S_sd_sector_last=last; S_sd_request_last=last;
            @(posedge S_sd_clk); while(!S_sd_byte_ready) @(posedge S_sd_clk);
            @(negedge S_sd_clk); S_sd_byte_valid=0;
        end
    endtask
    always @(posedge S_sd_clk) if(!S_reset) begin
        if(S_wait_fifo && (!u_dut.S_return_write_valid || u_dut.S_return_write_data!==S_held_fifo))
            fail("return FIFO producer changed during full backpressure");
        S_wait_fifo=u_dut.S_return_write_valid && !u_dut.S_return_write_ready;
        S_held_fifo=u_dut.S_return_write_data;
        if(S_sd_request_valid && S_sd_request_ready) begin
            S_forwarded=S_forwarded+1;
            if(S_forwarded!=1 || S_sd_tag!=16'h1111 || S_sd_context!=0 || S_sd_lba!=5 || S_sd_count!=2 || S_sd_priority!=1)
                fail("request fields or old request replay");
        end
        if(S_sd_cancel_valid && S_sd_cancel_ready &&
            (S_forwarded!=1 || S_sd_cancel_tag!=16'h1111 || S_sd_cancel_context!=0)) fail("cancel bypassed request");
    end
    always @(posedge S_host_clk) begin
        if(S_reset) begin S_wait_byte=0; S_wait_done=0; S_wait_ack=0; end
        else begin
            if(S_wait_byte && (!S_byte_valid || {S_byte_context,S_byte_tag,S_sector_last,S_request_last,S_byte}!==S_held_byte)) fail("byte stalled identity");
            if(S_wait_done && (!S_done_valid || {S_done_context,S_done_tag,S_error}!==S_held_done)) fail("done stalled identity");
            if(S_wait_ack && (!S_ack_valid || {S_ack_context,S_ack_tag}!==S_held_ack)) fail("cancel ack stalled identity");
            S_wait_byte=S_byte_valid && !S_byte_ready; S_held_byte={S_byte_context,S_byte_tag,S_sector_last,S_request_last,S_byte};
            S_wait_done=S_done_valid && !S_done_ready; S_held_done={S_done_context,S_done_tag,S_error};
            S_wait_ack=S_ack_valid && !S_ack_ready; S_held_ack={S_ack_context,S_ack_tag};
            if(S_byte_valid && S_byte_ready) begin
                if(S_byte_tag!=16'h1111 || S_byte_context!=0 || S_byte!==(S_bytes==0 ? 8'h11 : (S_bytes==1 ? 8'h22 : 8'h33)) ||
                    S_sector_last!==(S_bytes==2) || S_request_last!==(S_bytes==2)) fail("byte return order/fields");
                S_bytes=S_bytes+1;
            end
            if(S_done_valid && S_done_ready) begin
                if(S_terminals==0) begin
                    if(S_done_tag!=16'h1111 || S_error!=6 || S_done_context!=0 || S_bytes!=3) fail("done bypassed old bytes");
                end else if(S_terminals==1) begin
                    if(S_done_tag!=16'h2222 || S_error!=11 || S_done_context!=1) fail("first offline rejection");
                end else if(S_terminals==2) begin
                    if(S_done_tag!=16'h3333 || S_error!=11 || S_done_context!=2) fail("second offline rejection");
                end else fail("duplicate terminal");
                S_terminals=S_terminals+1;
            end
            if(S_ack_valid && S_ack_ready) begin
                if(S_ack_tag!=16'h1111 || S_ack_context!=0 || S_bytes!=3 || S_terminals!=1 || S_acks!=0) fail("cancel ACK bypassed drain");
                S_acks=S_acks+1;
            end
        end
    end
    initial begin
        #101; S_reset=0;
        repeat(10) @(negedge S_host_clk);
        if(S_card_ready || S_request_ready) fail("request allowed before media ready");
        @(negedge S_sd_clk); S_sd_card_ready=1;
        wait(S_card_ready);
        #1; if(S_capacity!==33'h100000000) fail("initial capacity snapshot or 33-bit truncation");
        request(16'h1111,0,5);
        @(negedge S_host_clk); S_cancel=1; S_cancel_tag=16'h1111; S_cancel_context=0;
        @(posedge S_host_clk); while(!S_cancel_ready) @(posedge S_host_clk);
        @(negedge S_host_clk); S_cancel=0;
        repeat(10) @(negedge S_sd_clk);
        if(!S_sd_request_valid || S_sd_cancel_valid) fail("cancel overtook unaccepted request");
        S_sd_request_ready=1;
        @(negedge S_sd_clk); S_sd_request_ready=0;
        wait(S_sd_cancel_valid);
        @(negedge S_sd_clk); S_sd_cancel_ready=1;
        @(negedge S_sd_clk); S_sd_cancel_ready=0;
        send_byte(8'h11,0,16'h1111); send_byte(8'h22,0,16'h1111); send_byte(8'h33,1,16'h1111);
        @(negedge S_sd_clk); S_sd_done_valid=1;
        @(posedge S_sd_clk); while(!S_sd_done_ready) @(posedge S_sd_clk);
        @(negedge S_sd_clk); S_sd_done_valid=0; S_sd_ack_valid=1;
        @(posedge S_sd_clk); while(!S_sd_ack_ready) @(posedge S_sd_clk);
        @(negedge S_sd_clk); S_sd_ack_valid=0;
        repeat(10) @(negedge S_host_clk);
        if(S_ack_valid || S_done_valid || !S_byte_valid) fail("return ACK bypassed blocked byte");
        if(!u_dut.S_return_write_valid || u_dut.S_return_write_ready) fail("return FIFO full case not reached");
        S_byte_ready=1; wait(S_bytes==3);
        @(negedge S_host_clk); S_byte_ready=0;
        wait(S_done_valid); repeat(5) @(negedge S_host_clk);
        if(S_ack_valid) fail("return ACK bypassed blocked terminal");
        S_done_ready=1; wait(S_terminals==1);
        wait(S_ack_valid); repeat(5) @(negedge S_host_clk);
        S_ack_ready=1; wait(S_acks==1);
        @(negedge S_host_clk); S_ack_ready=0; S_done_ready=0;

        request(16'h2222,1,10); request(16'h3333,2,20);
        wait(S_sd_request_valid);
        @(negedge S_sd_clk); S_sd_card_ready=0;
        S_sd_capacity=33'd8388608;
        @(negedge S_sd_clk); S_sd_card_ready=1;
        wait(!S_card_ready); wait(S_card_ready);
        #1; if(S_capacity!==33'd8388608) fail("replacement capacity was not committed atomically");
        @(negedge S_host_clk); S_done_ready=1;
        wait(S_terminals==3);
        if(S_forwarded!=1) fail("queued old media request replayed");

        @(negedge S_host_clk); S_run_host=0;
        @(negedge S_sd_clk); S_sd_card_ready=0;
        S_sd_capacity=33'd524288;
        @(negedge S_sd_clk); S_sd_card_ready=1;
        repeat(50) @(negedge S_sd_clk);
        if(u_dut.S_allow || S_sd_request_valid) fail("media barrier ignored stopped host");
        S_run_host=1; wait(!S_card_ready); wait(S_card_ready);
        #1; if(S_capacity!==33'd524288) fail("capacity handshake skipped stopped host");
        S_urgent=3'b101; repeat(4) @(negedge S_sd_clk);
        if(S_sd_urgent!=3'b101) fail("urgent flags did not synchronize");

        // Another removal while the stop handshake is opening must recapture
        // capacity, even if the new media returns before the host acknowledges.
        @(negedge S_sd_clk); S_sd_card_ready=0;
        @(negedge S_sd_clk); S_sd_capacity=33'd1048576; S_sd_card_ready=1;
        wait(!S_card_ready); wait(u_dut.S_media_state==1);
        @(negedge S_sd_clk); S_sd_card_ready=0;
        @(negedge S_sd_clk); S_sd_capacity=33'd2097152; S_sd_card_ready=1;
        wait(S_card_ready); #1;
        if(S_capacity!==33'd2097152) fail("opening loss retained stale capacity");

        send_byte(8'hee,1,16'h4444); wait(S_byte_valid);
        @(negedge S_host_clk); S_run_host=0;
        #3; S_reset=1; S_wait_fifo=0; #1;
        if(S_byte_valid || S_done_valid || S_ack_valid || S_card_ready) fail("shared reset did not flush stopped domain");
        repeat(10) @(negedge S_sd_clk);
        S_run_host=1; #101; S_reset=0;
        wait(S_card_ready); repeat(10) @(negedge S_host_clk);
        if(S_byte_valid || S_done_valid || S_ack_valid || S_bytes!=3 || S_terminals!=3 || S_acks!=1) fail("old return survived reset");
        O_done=1;
    end
endmodule
