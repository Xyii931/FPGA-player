`timescale 1ns/1ps
// Real arbiter + real sector_port. Host endpoint supplies deterministic sectors.
module tb_fat32_sector_arbiter;
    reg S_clk=0,S_reset=1,S_card_ready=1;
    always #4 S_clk=~S_clk;
    reg [2:0] S_valid=0,S_urgent=0,S_abort=0,S_result_ready=0;
    reg [95:0] S_lba=0;
    reg [5:0] S_priority=0;
    wire [2:0] S_ready,S_result;
    wire [23:0] S_error,S_data;
    wire [11:0] S_storage_error;
    reg [26:0] S_address=0;
    wire S_port_valid,S_port_ready,S_port_abort,S_port_result,S_port_result_ready;
    wire [31:0] S_port_lba;
    wire [1:0] S_port_context,S_port_priority;
    wire [7:0] S_port_error,S_port_data;
    wire [3:0] S_port_storage_error;
    wire [8:0] S_port_address;
    wire S_request,S_byte_ready,S_done_ready,S_cancel,S_cancel_done_ready;
    wire [31:0] S_request_lba;
    wire [7:0] S_count;
    wire [1:0] S_request_context,S_request_priority,S_cancel_context;
    wire [15:0] S_tag,S_cancel_tag;
    reg S_byte_valid=0,S_done=0,S_cancel_done=0;
    reg [7:0] S_byte=0;
    reg S_last=0;
    reg [1:0] S_return_context=0;
    reg [15:0] S_return_tag=0;
    reg [3:0] S_return_error=0;
    reg [2:0] S_host_state=0;
    reg S_host_canceled=0,S_host_cancel_seen=0,S_force_error=0,S_allow_request=1;
    reg [31:0] S_host_lba=0;
    integer S_byte_index=0,S_host_delay=0,S_cycle=0,S_requests=0,S_retired=0,S_acks=0;
    integer S_order[0:63];
    integer S_i,S_j,S_case=0,S_before,S_before_acks,S_before_retired,S_expected_requests;
    reg [2:0] S_mask;
    reg S_test_pass=0;
    wire S_request_ready=S_host_state==0 && S_allow_request && S_cycle%7!=0;
    wire S_cancel_ready=S_host_state!=0 && !S_host_cancel_seen && S_cycle%5!=0;

    fat32_sector_arbiter u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_card_ready(S_card_ready),.I_read_valid(S_valid),.O_read_ready(S_ready),
        .I_read_lba(S_lba),.I_context(6'b10_01_00),.I_priority(S_priority),.I_urgent(S_urgent),.I_abort(S_abort),
        .O_result_valid(S_result),.I_result_ready(S_result_ready),.O_error(S_error),.O_storage_error(S_storage_error),
        .I_buffer_address(S_address),.O_buffer_data(S_data),.O_port_valid(S_port_valid),.I_port_ready(S_port_ready),
        .O_port_lba(S_port_lba),.O_port_context(S_port_context),.O_port_priority(S_port_priority),.O_port_abort(S_port_abort),
        .I_port_result_valid(S_port_result),.O_port_result_ready(S_port_result_ready),
        .I_port_error(S_port_error),.I_port_storage_error(S_port_storage_error),
        .O_port_buffer_address(S_port_address),.I_port_buffer_data(S_port_data));
    fat32_sector_port u_port (
        .I_clk(S_clk),.I_reset(S_reset),.I_card_ready(S_card_ready),.I_start_valid(S_port_valid),.O_start_ready(S_port_ready),
        .I_lba(S_port_lba),.I_context(S_port_context),.I_priority(S_port_priority),.I_abort(S_port_abort),
        .O_result_valid(S_port_result),.I_result_ready(S_port_result_ready),.O_error(S_port_error),
        .O_storage_error(S_port_storage_error),.I_buffer_address(S_port_address),.O_buffer_data(S_port_data),
        .O_request_valid(S_request),.I_request_ready(S_request_ready),.O_lba(S_request_lba),.O_count(S_count),
        .O_context(S_request_context),.O_priority(S_request_priority),.O_tag(S_tag),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_sector_last(S_last),.I_request_last(S_last),.I_byte_context(S_return_context),.I_byte_tag(S_return_tag),
        .I_done_valid(S_done),.O_done_ready(S_done_ready),.I_done_context(S_return_context),.I_done_tag(S_return_tag),
        .I_done_error(S_return_error),.O_cancel_valid(S_cancel),.I_cancel_ready(S_cancel_ready),
        .O_cancel_context(S_cancel_context),.O_cancel_tag(S_cancel_tag),.I_cancel_done_valid(S_cancel_done),
        .O_cancel_done_ready(S_cancel_done_ready),.I_cancel_done_context(S_return_context),.I_cancel_done_tag(S_return_tag));
    task fail;
        input [511:0] message;
        begin $display("FAIL: sector arbiter case %0d: %0s",S_case,message); $stop; end
    endtask
    function [7:0] pattern;
        input [31:0] lba;
        input integer address;
        begin pattern=lba[7:0]^address[7:0]^{7'd0,address[8]}; end
    endfunction
    task launch;
        input [2:0] clients;
        input [31:0] lba0,lba1,lba2;
        begin
            S_case=S_case+1;
            @(negedge S_clk); S_lba={lba2,lba1,lba0}; S_mask=clients; S_valid=clients;
            while(S_mask!=0) begin
                @(posedge S_clk); S_mask=S_mask & ~S_ready;
                @(negedge S_clk); S_valid=S_mask;
            end
        end
    endtask
    task consume;
        input [2:0] clients;
        begin
            @(negedge S_clk); S_result_ready=clients;
            @(negedge S_clk); S_result_ready=0;
        end
    endtask
    task check_result;
        input integer client;
        input [7:0] error;
        input [3:0] storage_error;
        begin
            wait(S_result[client]); #1;
            if(S_error[client*8+:8]!==error || S_storage_error[client*4+:4]!==storage_error)
                fail("result error or underlying storage error");
            repeat(5) begin
                @(negedge S_clk);
                if(!S_result[client] || S_error[client*8+:8]!==error || S_storage_error[client*4+:4]!==storage_error)
                    fail("held result changed");
            end
        end
    endtask
    task check_buffers;
        input [31:0] lba0,lba1,lba2;
        begin
            for(S_i=0;S_i<512;S_i=S_i+1) begin
                @(negedge S_clk); S_address={3{S_i[8:0]}};
                @(posedge S_clk); #1;
                if(S_data!=={pattern(lba2,S_i),pattern(lba1,S_i),pattern(lba0,S_i)})
                    fail("private RAM copy/address/ownership mismatch");
            end
        end
    endtask
    task pulse_abort;
        input [2:0] clients;
        begin @(negedge S_clk); S_abort=clients; @(negedge S_clk); S_abort=0; end
    endtask
    // NBA on all protocol outputs/state avoids active-edge handshake races.
    always @(posedge S_clk) begin
        S_cycle<=S_cycle+1;
        if(S_reset) begin
            S_host_state<=0; S_byte_valid<=0; S_done<=0; S_cancel_done<=0;
            S_host_canceled<=0; S_host_cancel_seen<=0; S_byte_index<=0;
        end else begin
            if(S_cancel && S_cancel_ready) begin
                if(S_cancel_context!==S_return_context || S_cancel_tag!==S_return_tag) fail("cancel identity");
                S_host_canceled<=1; S_host_cancel_seen<=1;
            end
            case(S_host_state)
                0:if(S_request && S_request_ready) begin
                    if(S_count!=1) fail("physical read must be one sector");
                    S_order[S_requests]=S_request_context; S_requests=S_requests+1;
                    S_host_lba<=S_request_lba; S_return_context<=S_request_context; S_return_tag<=S_tag;
                    S_byte_index<=0; S_host_canceled<=0; S_host_cancel_seen<=0;
                    S_return_error<=0; S_host_state<=1;
                end
                1:begin
                    if(S_byte_valid && S_byte_ready) begin
                        S_byte_valid<=0;
                        if(S_byte_index==511 || S_host_canceled) begin S_host_delay<=12; S_host_state<=2; end
                        else S_byte_index<=S_byte_index+1;
                    end else if(!S_byte_valid && S_cycle%4!=0) begin
                        S_byte<=pattern(S_host_lba,S_byte_index); S_last<=S_byte_index==511; S_byte_valid<=1;
                    end
                end
                2:begin
                    if(S_host_delay==0) begin
                        S_return_error<=S_host_canceled ? 4'd6 : (S_force_error ? 4'd4 : 4'd0);
                        S_done<=1; S_host_state<=3;
                    end else S_host_delay<=S_host_delay-1;
                end
                3:if(S_done && S_done_ready) begin
                    S_done<=0; S_retired=S_retired+1; S_host_delay<=30; S_host_state<=4;
                end
                4:begin
                    // A late cancel after done must still get its real ack.
                    if(S_host_delay==0) begin
                        if(S_host_cancel_seen) begin S_cancel_done<=1; S_host_state<=5; end
                        else if(!(S_cancel && S_cancel_ready)) S_host_state<=0;
                    end else S_host_delay<=S_host_delay-1;
                end
                5:if(S_cancel_done && S_cancel_done_ready) begin
                    S_cancel_done<=0; S_acks=S_acks+1; S_host_state<=0;
                end
                default:fail("host endpoint state");
            endcase
        end
    end
    initial begin
        #39; S_reset=0;
        // Urgency beats priority, equal priority rotates. Keep all results held.
        S_urgent=4; S_priority=6'b00_01_10; S_before=S_requests;
        launch(7,11,22,33); wait(S_result==7); #1;
        if(S_order[S_before]!=2 || S_order[S_before+1]!=0 || S_order[S_before+2]!=1)
            fail("urgent/priority/round-robin order");
        if(S_error!==0) fail("batch failed");
        check_buffers(11,22,33);
        @(negedge S_clk); S_valid=7; S_before=S_requests;
        repeat(6) begin @(negedge S_clk); if(S_ready!=0) fail("held result accepted another request"); end
        if(S_requests!=S_before) fail("held result allowed physical resubmission"); S_valid=0;
        // Client 2 keeps both its result and RAM while client 0 runs again.
        consume(1); S_urgent=0; launch(1,91,0,0); check_result(0,0,0);
        if(!S_result[2] || !S_result[1]) fail("unrelated result was lost");
        check_buffers(91,22,33);
        // An abort/media event cannot rewrite an already published result.
        @(negedge S_clk); S_abort=7; S_card_ready=0;
        repeat(4) @(negedge S_clk);
        if(S_result!=7 || S_error!==0) fail("published terminal was rewritten");
        S_abort=0; S_card_ready=1; consume(7);
        // Reset at an idle boundary establishes a known RR seed for two rounds.
        wait(S_host_state==0); @(negedge S_clk); S_reset=1;
        @(negedge S_clk); S_reset=0; S_priority=0;
        for(S_j=0;S_j<2;S_j=S_j+1) begin
            S_before=S_requests; launch(7,41,42,43); wait(S_result==7); #1;
            if(S_order[S_before]!=0 || S_order[S_before+1]!=1 || S_order[S_before+2]!=2) fail("equal-priority rotation");
            check_buffers(41,42,43); consume(7);
        end
        // Cancel before the arbiter submits: no host request is allowed.
        wait(S_host_state==0); S_before=S_requests;
        launch(2,0,52,0); S_abort=2; @(negedge S_clk); S_abort=0;
        check_result(1,8,0); if(S_requests!=S_before) fail("unsubmitted cancel reached host"); consume(2);
        // Physical cancel waits for done AND an intentionally delayed ack.
        S_before_acks=S_acks; S_before_retired=S_retired;
        launch(4,0,0,63); wait(S_host_state==1 && S_byte_index>=50); pulse_abort(4);
        wait(S_retired>S_before_retired); repeat(10) begin
            @(negedge S_clk); if(S_result[2]) fail("cancel published before physical ack");
        end
        check_result(2,8,6); if(S_acks!=S_before_acks+1) fail("missing real cancel ack"); consume(4);
        // Cancel while copying a physically completed result must invalidate it.
        launch(1,71,0,0); wait(u_dut.S_state==4 && u_dut.S_copy==100); pulse_abort(1);
        check_result(0,8,0); consume(1);
        // Latch a short loss even when ready returns before the transaction ends.
        launch(2,0,82,0); wait(S_host_state==1 && S_byte_index>=50);
        @(negedge S_clk); S_card_ready=0; @(negedge S_clk); S_card_ready=1;
        S_expected_requests=S_requests; check_result(1,1,6);
        if(S_requests!=S_expected_requests) fail("old request replayed on restored medium"); consume(2);
        launch(4,0,0,93); wait(u_dut.S_state==4 && u_dut.S_copy==100);
        @(negedge S_clk); S_card_ready=0; @(negedge S_clk); S_card_ready=1;
        check_result(2,1,0); consume(4);
        S_force_error=1; launch(1,101,0,0); check_result(0,2,4); consume(1); S_force_error=0;
        // New requests on a blocked medium finish locally rather than replay.
        S_card_ready=0; S_before=S_requests; launch(2,0,102,0); check_result(1,1,0);
        if(S_requests!=S_before) fail("blocked media request reached host"); consume(2); S_card_ready=1;
        launch(7,111,112,113); wait(S_result==7); #1;
        if(S_error!==0) fail("recovery failed"); check_buffers(111,112,113); consume(7);
        S_test_pass=1; $display("PASS: private sector snapshots, arbitration, held results, physical cancel, loss and recovery"); $finish;
    end
    initial begin #5000000; fail("arbiter watchdog"); end
endmodule
