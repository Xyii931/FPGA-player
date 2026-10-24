`timescale 1ns/1ps
// Real six-client arbiter/native SDR controller. The SDR device is a command fixture.
// Not a vendor primitive timing test and not a measured bandwidth result.
module tb_frame_memory;
    reg S_clk=0,S_reset=1,S_shift_run=1,S_expect_clock_fault=0;
    wire S_clk_sft=S_shift_run ? ~S_clk : 1'b0;
    always #4 S_clk=~S_clk;
    reg [31:0] S_time=0;
    always @(posedge S_clk) begin if(S_reset) S_time<=0; else S_time<=S_time+32'd1; end
    wire [31:0] S_dq;
    reg S_test_pass=0,S_check_edf=0;
    reg [31:0] S_reference[0:2097151];
    reg [31:0] S_expected_data[0:767],S_expected_tag[0:767],S_expected_token[0:767],S_expected_generation[0:767],S_issue_time[0:767];
    reg S_expected_wr[0:767];
    integer S_sent[0:5],S_received[0:5];
    integer S_i,S_lane,S_index,S_address,S_item,S_client,S_total_reads=0,S_total_writes=0;
    reg [31:0] S_refresh_before;
    reg [5:0] S_m_I_client_valid=0;
    wire [5:0] S_m_O_client_ready;
    reg [5:0] S_m_I_client_wr=0;
    reg [125:0] S_m_I_client_addr=0;
    reg [191:0] S_m_I_client_data=0;
    reg [191:0] S_m_I_client_tag=0;
    reg [191:0] S_m_I_client_token=0;
    reg [191:0] S_m_I_client_generation=0;
    reg [191:0] S_m_I_client_deadline=0;
    reg [23:0] S_m_I_client_mask=0;
    wire [5:0] S_m_O_client_result_valid;
    reg [5:0] S_m_I_client_result_ready=0;
    wire [5:0] S_m_O_client_result_wr;
    wire [191:0] S_m_O_client_result_data;
    wire [191:0] S_m_O_client_result_tag;
    wire [191:0] S_m_O_client_result_token;
    wire [191:0] S_m_O_client_result_generation;
    wire [23:0] S_m_O_client_result_error;
    reg S_m_I_clear_stats=0;
    wire S_m_O_arbiter_busy;
    wire S_m_O_contract_fault;
    wire S_m_O_response_discarded;
    wire S_m_O_issue_exhausted;
    wire S_m_O_window_valid;
    wire [20:0] S_m_O_busy_cycles;
    wire [20:0] S_m_O_grant_cycles;
    wire [191:0] S_m_O_client_grants;
    wire S_m_O_initialized;
    wire S_m_O_clock_fault;
    wire S_m_O_device_busy;
    wire S_m_O_controller_busy;
    wire S_m_O_refresh_pulse;
    wire S_m_O_sdram_clk;
    wire S_m_O_sdram_cke;
    wire S_m_O_sdram_ras_n;
    wire S_m_O_sdram_cas_n;
    wire S_m_O_sdram_we_n;
    wire [10:0] S_m_O_sdram_addr;
    wire [1:0] S_m_O_sdram_ba;
    wire [3:0] S_m_O_sdram_dm;
    wire S_m_O_busy;
    player_frame_memory u_m (
        .I_clk(S_clk),
        .I_clk_sft(S_clk_sft),
        .I_reset(S_reset),
        .I_time(S_time),
        .I_client_valid(S_m_I_client_valid),
        .O_client_ready(S_m_O_client_ready),
        .I_client_wr(S_m_I_client_wr),
        .I_client_addr(S_m_I_client_addr),
        .I_client_data(S_m_I_client_data),
        .I_client_tag(S_m_I_client_tag),
        .I_client_token(S_m_I_client_token),
        .I_client_generation(S_m_I_client_generation),
        .I_client_deadline(S_m_I_client_deadline),
        .I_client_mask(S_m_I_client_mask),
        .O_client_result_valid(S_m_O_client_result_valid),
        .I_client_result_ready(S_m_I_client_result_ready),
        .O_client_result_wr(S_m_O_client_result_wr),
        .O_client_result_data(S_m_O_client_result_data),
        .O_client_result_tag(S_m_O_client_result_tag),
        .O_client_result_token(S_m_O_client_result_token),
        .O_client_result_generation(S_m_O_client_result_generation),
        .O_client_result_error(S_m_O_client_result_error),
        .I_clear_stats(S_m_I_clear_stats),
        .O_arbiter_busy(S_m_O_arbiter_busy),
        .O_contract_fault(S_m_O_contract_fault),
        .O_response_discarded(S_m_O_response_discarded),
        .O_issue_exhausted(S_m_O_issue_exhausted),
        .O_window_valid(S_m_O_window_valid),
        .O_busy_cycles(S_m_O_busy_cycles),
        .O_grant_cycles(S_m_O_grant_cycles),
        .O_client_grants(S_m_O_client_grants),
        .O_initialized(S_m_O_initialized),
        .O_clock_fault(S_m_O_clock_fault),
        .O_device_busy(S_m_O_device_busy),
        .O_controller_busy(S_m_O_controller_busy),
        .O_refresh_pulse(S_m_O_refresh_pulse),
        .O_sdram_clk(S_m_O_sdram_clk),
        .O_sdram_cke(S_m_O_sdram_cke),
        .O_sdram_ras_n(S_m_O_sdram_ras_n),
        .O_sdram_cas_n(S_m_O_sdram_cas_n),
        .O_sdram_we_n(S_m_O_sdram_we_n),
        .O_sdram_addr(S_m_O_sdram_addr),
        .O_sdram_ba(S_m_O_sdram_ba),
        .O_sdram_dm(S_m_O_sdram_dm),
        .IO_sdram_dq(S_dq),
        .O_busy(S_m_O_busy)
    );
    wire S_d_O_fault;
    wire [31:0] S_d_O_reads;
    wire [31:0] S_d_O_writes;
    wire [31:0] S_d_O_refreshes;
    sim_sdr_device u_d (
        .I_clk(S_m_O_sdram_clk),
        .I_reset(S_reset),
        .I_cke(S_m_O_sdram_cke),
        .I_ras_n(S_m_O_sdram_ras_n),
        .I_cas_n(S_m_O_sdram_cas_n),
        .I_we_n(S_m_O_sdram_we_n),
        .I_addr(S_m_O_sdram_addr),
        .I_ba(S_m_O_sdram_ba),
        .I_dm(S_m_O_sdram_dm),
        .IO_dq(S_dq),
        .O_fault(S_d_O_fault),
        .O_reads(S_d_O_reads),
        .O_writes(S_d_O_writes),
        .O_refreshes(S_d_O_refreshes)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL frame_memory t=%0d: %0s",S_time,message); $finish; end
    endtask
    function [20:0] address;
        input integer index;
        reg [10:0] row;
        begin row=index>>2; address={row,index[1:0],index[7:0]}; end
    endfunction
    task automatic submit;
        input integer client;
        input wr;
        input integer item;
        input [31:0] data;
        input [3:0] mask;
        input [31:0] deadline;
        begin
            @(negedge S_clk);
            S_m_I_client_valid[client]=1; S_m_I_client_wr[client]=wr;
            S_m_I_client_addr[client*21+:21]=address(item);
            S_m_I_client_data[client*32+:32]=data; S_m_I_client_mask[client*4+:4]=mask;
            S_m_I_client_tag[client*32+:32]=32'h10000000+client*256+S_sent[client];
            S_m_I_client_token[client*32+:32]=32'h70000000+client;
            S_m_I_client_generation[client*32+:32]=32'h30000000+client;
            S_m_I_client_deadline[client*32+:32]=deadline;
            while(!S_m_O_client_ready[client]) @(negedge S_clk);
            @(negedge S_clk); S_m_I_client_valid[client]=0;
        end
    endtask
    task automatic stream;
        input integer client;
        input integer count;
        integer item;
        begin
            for(item=0;item<count;item=item+1)
                submit(client,client==4,item,32'ha1b2c3d4,4'b1010,32'd10000000);
        end
    endtask
    always @(posedge S_clk) begin
        if(S_reset) begin
            for(S_i=0;S_i<6;S_i=S_i+1) begin S_sent[S_i]=0; S_received[S_i]=0; end
            S_total_reads=0; S_total_writes=0;
        end else begin
            if(S_d_O_fault || S_m_O_contract_fault || S_m_O_issue_exhausted ||
                (S_m_O_clock_fault && !S_expect_clock_fault)) fail("device/fabric/clock contract fault");
            if(S_check_edf && (|S_m_O_client_ready)) begin
                if(S_m_O_client_ready!=6'b000010) fail("earlier scan deadline not granted first");
                S_check_edf=0;
            end
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                if(S_m_I_client_valid[S_i] && S_m_O_client_ready[S_i]) begin
                    if(!S_m_O_initialized || S_sent[S_i]>=128) fail("accept before initialization / scoreboard overflow");
                    S_index=S_i*128+S_sent[S_i]; S_address=S_m_I_client_addr[S_i*21+:21];
                    S_expected_data[S_index]=S_reference[S_address];
                    S_expected_tag[S_index]=S_m_I_client_tag[S_i*32+:32];
                    S_expected_token[S_index]=S_m_I_client_token[S_i*32+:32];
                    S_expected_generation[S_index]=S_m_I_client_generation[S_i*32+:32];
                    S_expected_wr[S_index]=S_m_I_client_wr[S_i]; S_issue_time[S_index]=S_time;
                    if(S_m_I_client_wr[S_i]) begin
                        S_total_writes=S_total_writes+1;
                        for(S_lane=0;S_lane<4;S_lane=S_lane+1)
                            if(!S_m_I_client_mask[S_i*4+S_lane])
                                S_reference[S_address][S_lane*8+:8]=S_m_I_client_data[S_i*32+S_lane*8+:8];
                    end else S_total_reads=S_total_reads+1;
                    S_sent[S_i]=S_sent[S_i]+1;
                end
                if(S_m_O_client_result_valid[S_i] && S_m_I_client_result_ready[S_i]) begin
                    if(S_received[S_i]>=S_sent[S_i]) fail("unsolicited/duplicate client result");
                    S_index=S_i*128+S_received[S_i];
                    if(S_m_O_client_result_wr[S_i]!==S_expected_wr[S_index] ||
                        S_m_O_client_result_tag[S_i*32+:32]!==S_expected_tag[S_index] ||
                        S_m_O_client_result_token[S_i*32+:32]!==S_expected_token[S_index] ||
                        S_m_O_client_result_generation[S_i*32+:32]!==S_expected_generation[S_index] ||
                        S_m_O_client_result_error[S_i*4+:4]!==0) fail("result identity/order/error");
                    if(!S_expected_wr[S_index] && S_m_O_client_result_data[S_i*32+:32]!==S_expected_data[S_index])
                        fail("actual DQ readback / byte mask / bank row mapping");
                    if(S_expected_wr[S_index] && S_time-S_issue_time[S_index]<4) fail("write retired before actual command/tWR");
                    S_received[S_i]=S_received[S_i]+1;
                end
            end
        end
    end
    initial begin
        #101; S_reset=0; S_m_I_client_result_ready=63;
        wait(S_m_O_initialized);
        for(S_item=0;S_item<32;S_item=S_item+1)
            submit(2,1,S_item,32'h12340000^(S_item*32'h01010101),4'd0,0);
        wait(S_received[2]==32);
        @(negedge S_clk); S_check_edf=1;
        fork
            submit(0,0,0,0,0,S_time+32'd2000);
            submit(1,0,1,0,0,S_time+32'd100);
        join
        wait(S_received[0]==1 && S_received[1]==1);
        @(negedge S_clk); S_m_I_client_result_ready[0]=0;
        fork
            stream(0,20);
            stream(1,20);
            stream(3,20);
            stream(4,20);
            stream(5,20);
            begin
                wait(S_sent[0]>=9);
                S_refresh_before=S_d_O_refreshes;
                repeat(2200) @(negedge S_clk);
                if(S_received[1]<=1 || S_d_O_refreshes<=S_refresh_before)
                    fail("held client blocked unrelated results / physical refresh");
                S_m_I_client_result_ready[0]=1;
            end
        join
        wait(S_received[0]==S_sent[0] && S_received[1]==S_sent[1] && S_received[2]==S_sent[2] &&
             S_received[3]==S_sent[3] && S_received[4]==S_sent[4] && S_received[5]==S_sent[5]);
        wait(!S_m_O_arbiter_busy); repeat(4) @(negedge S_clk);
        if(S_d_O_reads!=S_total_reads || S_d_O_writes!=S_total_writes || S_d_O_refreshes<9)
            fail("physical command counts / missing refresh");
        for(S_client=0;S_client<6;S_client=S_client+1)
            if(S_m_O_client_grants[S_client*32+:32]!=S_sent[S_client]) fail("grant telemetry not actual accepts");
        // Lose the DEVICE edge immediately after logical acceptance of a WRITE.
        // Host timing alone must never manufacture a write completion.
        S_expect_clock_fault=1;
        fork
            submit(2,1,0,32'hdeadbeef,4'd0,0);
            begin
                wait(S_m_O_client_ready[2]); @(posedge S_clk); #1; S_shift_run=0;
            end
        join
        wait(S_m_O_clock_fault); repeat(12) @(negedge S_clk);
        if(S_received[2]!=32 || S_sent[2]!=33 || !S_m_O_busy || S_d_O_writes!=S_total_writes-1)
            fail("missing device clock produced fake write retirement");
        @(posedge S_clk); #1; S_shift_run=1;
        repeat(12) @(negedge S_clk);
        if(!S_m_O_clock_fault || S_received[2]!=32 || S_d_O_writes!=S_total_writes-1)
            fail("clock recovery replayed unknown physical command");
        S_test_pass=1; $display("PASS real native SDR controller + six-client arbiter; SDR command fixture only"); $finish;
    end
    initial begin #2000000; fail("timeout"); end
endmodule
