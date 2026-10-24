`timescale 1ns/1ps
// Pin-level card peer. Models protocol assumptions, not real card compatibility.
module tb_sd_spi_phy;
    reg S_clk=0,S_reset=1,S_cmd_valid=0,S_idle_valid=0,S_abort=0;
    always #5 S_clk=~S_clk;
    reg [5:0] S_index=0;
    reg [31:0] S_argument=0;
    reg [7:0] S_cmd_crc=1,S_blocks=1,S_idle_bytes=10;
    reg [2:0] S_response_bytes=1;
    reg [15:0] S_divider=4,S_tag=0;
    reg S_response_ready=1,S_byte_ready=1,S_crc_check=1;
    wire S_cmd_ready,S_idle_ready,S_response_valid,S_byte_valid,S_block_last,S_request_last;
    wire S_block_done,S_crc_ok,S_done,S_busy,S_ncs,S_sclk,S_mosi;
    wire [39:0] S_response;
    wire [2:0] S_response_count;
    wire [7:0] S_byte;
    wire [3:0] S_error;
    wire [15:0] S_out_tag;
    reg [7:0] S_tx_shift=8'hff,S_rx_shift=0;
    wire S_miso=S_ncs ? 1'b1 : S_tx_shift[7];
    reg [7:0] S_queue[0:4095],S_packet[0:5];
    integer S_qread=0,S_qwrite=0,S_bits=0,S_packet_count=0;
    integer S_model_blocks=1,S_command_count=0,S_stop_count=0,S_idle_edges=0;
    integer S_received=0,S_block_events=0,S_good_blocks=0,S_cases=0,S_i,S_timeout;
    reg [7:0] S_seed=8'h29;
    reg S_bad_crc=0,S_no_token=0,S_bad_token=0,S_no_response=0,S_hold_busy=0;
    reg S_wait_byte=0,S_wait_response=0,S_test_pass=0;
    reg [7:0] S_saved_byte;
    reg [39:0] S_saved_response;
    reg [1:0] S_saved_last;
    reg [5:0] S_expected_index;
    reg [31:0] S_expected_argument;
    sd_spi_phy #(.RESPONSE_TIMEOUT_CYCLES(5000),.TOKEN_TIMEOUT_CYCLES(1000),
        .BUSY_TIMEOUT_CYCLES(1000),.STALL_TIMEOUT_CYCLES(500)) u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_cmd_valid(S_cmd_valid),.O_cmd_ready(S_cmd_ready),
        .I_cmd_index(S_index),.I_cmd_argument(S_argument),.I_cmd_crc(S_cmd_crc),
        .I_response_bytes(S_response_bytes),.I_block_count(S_blocks),.I_divider(S_divider),.I_tag(S_tag),
        .I_crc_check(S_crc_check),.I_abort(S_abort),.I_idle_valid(S_idle_valid),.O_idle_ready(S_idle_ready),
        .I_idle_bytes(S_idle_bytes),.O_response_valid(S_response_valid),.I_response_ready(S_response_ready),
        .O_response_data(S_response),.O_response_bytes(S_response_count),.O_byte_valid(S_byte_valid),
        .I_byte_ready(S_byte_ready),.O_byte_data(S_byte),.O_block_last(S_block_last),
        .O_request_last(S_request_last),.O_block_done(S_block_done),.O_crc_ok(S_crc_ok),
        .O_done(S_done),.O_error(S_error),.O_tag(S_out_tag),.O_busy(S_busy),
        .O_sd_ncs(S_ncs),.O_sd_sclk(S_sclk),.O_sd_mosi(S_mosi),.I_sd_miso(S_miso));
    task fail;
        input [511:0] message;
        begin $display("FAIL: case %0d: %0s",S_cases,message); $stop; end
    endtask
    function [15:0] reference_crc;
        input [15:0] previous;
        input [7:0] value;
        reg [15:0] remainder;
        integer k;
        begin
            remainder=previous^{value,8'd0};
            for(k=0;k<8;k=k+1) begin
                if(remainder[15]) remainder=(remainder<<1)^16'h1021;
                else remainder=remainder<<1;
            end
            reference_crc=remainder;
        end
    endfunction
    function [7:0] payload;
        input integer block_number,index;
        begin payload=S_seed+3*block_number+index; end
    endfunction
    task push;
        input [7:0] value;
        begin
            if(S_qwrite>=4096) fail("card response queue overflow");
            S_queue[S_qwrite]=value; S_qwrite=S_qwrite+1;
        end
    endtask
    task card_command;
        input [7:0] last_byte;
        integer index,b,k;
        reg [31:0] argument;
        reg [15:0] crc;
        reg [7:0] value;
        begin
            index=S_packet[0]&63; argument={S_packet[1],S_packet[2],S_packet[3],S_packet[4]};
            S_command_count=S_command_count+1;
            if(index==12) begin
                S_stop_count=S_stop_count+1;
                if(argument!=0 || last_byte!=1) fail("CMD12 framing");
                // Stop discards future blocks that the card had prepared.
                S_qread=0; S_qwrite=0;
                push(8'h04); // A plausible nonzero R1: this stuff byte must be skipped.
                push(0); push(0); push(0);
                if(!S_hold_busy) push(8'hff);
            end else begin
                if(index!=S_expected_index || argument!==S_expected_argument) fail("command index/argument");
                if(last_byte!==S_cmd_crc || S_packet[0][7:6]!=1) fail("command CRC/end bit/framing");
                if(!S_no_response) begin
                    push(8'hff);
                    push(index==0 || index==8 ? 8'h01 : 8'h00);
                    if(index==8) begin push(0); push(0); push(1); push(8'haa); end
                    if(index==58) begin push(8'hc0); push(8'hff); push(8'h80); push(0); end
                    if(index==13) push(0);
                    if(index==9 || index==17 || index==18) begin
                        if(S_bad_token) push(8'h0b);
                        else if(!S_no_token) for(b=0;b<S_model_blocks;b=b+1) begin
                            push(8'hff); push(8'hff); push(8'hfe); crc=0;
                            for(k=0;k<(index==9 ? 16 : 512);k=k+1) begin value=payload(b,k); push(value); crc=reference_crc(crc,value); end
                            push(crc[15:8]); push(crc[7:0]^(S_bad_crc ? 8'h01 : 8'h00));
                        end
                    end
                end
            end
        end
    endtask
    always @(negedge S_ncs) begin
        S_qread=0; S_qwrite=0; S_bits=0; S_packet_count=0; S_rx_shift=0; S_tx_shift=8'hff;
    end
    always @(posedge S_sclk) begin
        if(S_ncs) begin
            S_idle_edges=S_idle_edges+1;
            if(!S_mosi) fail("MOSI not high with CS high");
        end else begin
            S_rx_shift={S_rx_shift[6:0],S_mosi}; S_bits=S_bits+1;
            if(S_bits==8) begin
                S_bits=0;
                if(S_packet_count==0) begin
                    if(S_rx_shift[7:6]==1) begin S_packet[0]=S_rx_shift; S_packet_count=1; end
                end else if(S_packet_count==5) begin
                    card_command(S_rx_shift); S_packet_count=0;
                end else begin S_packet[S_packet_count]=S_rx_shift; S_packet_count=S_packet_count+1; end
            end
        end
    end
    always @(negedge S_sclk) if(!S_ncs) begin
        if(S_bits==0) begin
            if(S_qread<S_qwrite) begin S_tx_shift=S_queue[S_qread]; S_qread=S_qread+1; end
            else S_tx_shift=S_hold_busy ? 8'h00 : 8'hff;
        end else S_tx_shift={S_tx_shift[6:0],1'b1};
    end
    always @(posedge S_ncs) if(!S_reset && S_qread<S_qwrite) fail("CS released before queued block/CRC/stop completed");

    task launch;
        input [5:0] index;
        input [31:0] argument;
        input [2:0] response_bytes;
        input [7:0] blocks;
        begin
            wait(S_cmd_ready); @(negedge S_clk);
            S_cases=S_cases+1; S_tag=S_cases; S_received=0; S_block_events=0; S_good_blocks=0;
            S_stop_count=0; S_command_count=0; S_wait_byte=0; S_wait_response=0;
            S_expected_index=index; S_expected_argument=argument;
            S_index=index; S_argument=argument; S_response_bytes=response_bytes; S_blocks=blocks;
            S_cmd_crc=index==0 ? 8'h95 : (index==8 ? 8'h87 : 8'h01); S_cmd_valid=1;
            @(negedge S_clk); S_cmd_valid=0;
        end
    endtask
    task completed;
        input [3:0] error;
        input integer bytes,blocks,good,stops;
        begin
            wait(S_done); #2;
            if(S_error!==error || S_received!=bytes || S_block_events!=blocks ||
                S_good_blocks!=good || S_stop_count!=stops || !S_ncs || S_sclk || S_busy || S_out_tag!==S_tag)
                fail("completion status / data / CRC / CMD12 count");
            @(negedge S_clk); S_abort=0; S_byte_ready=1; S_response_ready=1;
        end
    endtask
    always @(posedge S_clk) if(!S_reset) begin
        if(S_wait_byte && !S_abort && (!S_byte_valid || {S_byte,S_block_last,S_request_last}!=={S_saved_byte,S_saved_last}) && S_error!=8)
            fail("byte changed under backpressure");
        if(S_wait_response && !S_abort && (!S_response_valid || S_response!==S_saved_response) && S_error!=8)
            fail("response changed under backpressure");
        S_wait_byte=S_byte_valid && !S_byte_ready; S_saved_byte=S_byte; S_saved_last={S_block_last,S_request_last};
        S_wait_response=S_response_valid && !S_response_ready; S_saved_response=S_response;
        if(S_byte_valid && S_byte_ready) begin
            if(S_ncs || S_byte!==payload(S_received/(S_expected_index==9 ? 16 : 512),S_received%(S_expected_index==9 ? 16 : 512)) ||
                S_block_last!==(S_received%(S_expected_index==9 ? 16 : 512)==(S_expected_index==9 ? 15 : 511)) ||
                S_request_last!==((S_received%(S_expected_index==9 ? 16 : 512)==(S_expected_index==9 ? 15 : 511)) &&
                    (S_received/(S_expected_index==9 ? 16 : 512)==S_blocks-1)))
                fail("data byte / markers / CS");
            S_received=S_received+1;
        end
        if(S_response_valid && S_response_ready && S_response_count!=S_response_bytes) fail("response byte count");
        if(S_response_valid && S_response_ready && S_expected_index==12 && S_response[7:0]!=0)
            fail("CMD12 stuff mistaken for R1");
        if(S_block_done) begin S_block_events=S_block_events+1; if(S_crc_ok) S_good_blocks=S_good_blocks+1; end
    end

    initial begin
        #31; S_reset=0;
        @(negedge S_clk); S_divider=250; S_idle_valid=1;
        @(negedge S_clk); S_idle_valid=0;
        wait(S_done); #2; if(S_idle_edges!=80 || !S_ncs || S_error!=0) fail("startup 80 clocks");
        @(negedge S_clk); S_divider=4;
        launch(0,0,1,0); completed(0,0,0,0,0);
        S_response_ready=0;
        launch(8,32'h1aa,5,0);
        wait(S_response_valid); repeat(20) @(negedge S_clk);
        if(S_response!==40'haa01000001 || S_sclk || S_ncs) fail("R7 packing / response hold");
        S_response_ready=1; completed(0,0,0,0,0);
        launch(58,0,5,0); wait(S_response_valid); #1;
        if(S_response!==40'h0080ffc000) fail("OCR packing");
        completed(0,0,0,0,0);
        launch(13,0,2,0); completed(0,0,0,0,0);
        launch(9,0,1,1); completed(0,16,1,1,0);
        S_bad_crc=1; launch(9,0,1,1); completed(4,16,1,0,0); S_bad_crc=0;
        launch(9,0,1,1); wait(S_received==5); @(negedge S_clk); S_abort=1;
        completed(6,5,1,0,0);
        launch(9,0,1,0); completed(7,0,0,0,0);
        S_byte_ready=0;
        launch(17,32'h1234,1,1);
        wait(S_byte_valid); repeat(100) @(negedge S_clk);
        if(S_sclk || S_ncs) fail("data stall not at byte boundary");
        S_byte_ready=1; completed(0,512,1,1,0);
        S_model_blocks=2;
        launch(18,32'h4321,1,2); completed(0,1024,2,2,1);
        S_model_blocks=1;
        launch(18,32'h2111,1,1);
        wait(u_dut.S_state==12); @(negedge S_clk); S_abort=1;
        completed(6,512,1,1,1);
        launch(18,32'h2222,1,2);
        wait(S_received==13); @(negedge S_clk); S_abort=1;
        completed(6,13,1,0,1);
        S_bad_crc=1; S_model_blocks=2;
        launch(18,32'h3333,1,2); completed(4,512,1,0,1); S_bad_crc=0; S_model_blocks=1;
        S_byte_ready=0;
        launch(18,32'h4444,1,2); completed(8,0,1,0,1);
        S_bad_token=1;
        launch(18,32'h5555,1,2); completed(3,0,0,0,1); S_bad_token=0;
        S_no_token=1;
        launch(18,32'h6666,1,2); completed(2,0,0,0,1); S_no_token=0;
        S_no_response=1;
        launch(0,0,1,0); completed(1,0,0,0,0); S_no_response=0;
        S_hold_busy=1;
        launch(12,0,1,0); completed(9,0,0,0,1); S_hold_busy=0;
        launch(18,0,1,0); completed(7,0,0,0,0);
        if(S_command_count!=0) fail("invalid parameters reached card");
        S_test_pass=1; $display("PASS: pin-level SD responses, blocks, CRC, CMD12, cancellation and timeouts"); $finish;
    end
    initial begin #3000000; fail("SD PHY watchdog"); end
endmodule
