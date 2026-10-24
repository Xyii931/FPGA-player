`timescale 1ns/1ps
module tb_spi_byte_master;
    reg S_clk=0,S_reset=1,S_tx_valid=0,S_rx_ready=0,S_miso=1;
    reg [7:0] S_tx=0,S_reply=0;
    reg [15:0] S_divider=4;
    wire S_tx_ready,S_rx_valid,S_sclk,S_mosi,S_busy;
    wire [7:0] S_rx;
    reg [7:0] S_seen;
    integer S_bits=0,S_cycle=0,S_edge_cycle=0,S_expected_half=2,S_j;
    reg S_check_edges=0,S_test_pass=0;
    always #5 S_clk=~S_clk;
    spi_byte_master u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_tx_valid(S_tx_valid),.O_tx_ready(S_tx_ready),
        .I_tx_data(S_tx),.I_divider(S_divider),.O_rx_valid(S_rx_valid),.I_rx_ready(S_rx_ready),
        .O_rx_data(S_rx),.O_sclk(S_sclk),.O_mosi(S_mosi),.I_miso(S_miso),.O_busy(S_busy));
    task fail;
        input [511:0] message;
        begin $display("FAIL: %0s",message); $stop; end
    endtask
    always @(posedge S_clk) S_cycle=S_cycle+1;
    always @(S_sclk) if(S_check_edges) begin
        if(S_edge_cycle!=0 && S_cycle-S_edge_cycle!=S_expected_half) fail("SPI half period / latched divider");
        S_edge_cycle=S_cycle;
    end
    always @(posedge S_sclk) begin
        S_seen={S_seen[6:0],S_mosi}; S_bits=S_bits+1;
    end
    always @(negedge S_sclk) if(S_bits<8) S_miso=S_reply[7-S_bits];
    task transfer;
        input [7:0] tx,reply;
        input [15:0] divider;
        begin
            @(negedge S_clk); S_tx=tx; S_reply=reply; S_divider=divider;
            S_seen=0; S_bits=0; S_edge_cycle=0; S_expected_half=divider/2;
            S_miso=reply[7]; S_check_edges=1; S_tx_valid=1;
            @(posedge S_clk); while(!S_tx_ready) @(posedge S_clk);
            @(negedge S_clk); S_tx_valid=0; S_divider=6; S_tx=~tx;
            wait(S_rx_valid); #1; S_check_edges=0;
            if(S_bits!=8 || S_seen!==tx || S_rx!==reply || S_sclk || !S_mosi) fail("SPI byte bit order / mode0");
            for(S_j=0;S_j<12;S_j=S_j+1) begin
                @(negedge S_clk);
                if(!S_rx_valid || S_rx!==reply || S_tx_ready || S_sclk) fail("RX wait not stable");
            end
            S_rx_ready=1; @(negedge S_clk); S_rx_ready=0;
            if(S_rx_valid) fail("RX handshake not cleared");
        end
    endtask
    initial begin
        #31; S_reset=0;
        @(negedge S_clk); S_divider=3; S_tx_valid=1;
        repeat(5) begin @(negedge S_clk); if(S_tx_ready || S_sclk) fail("odd divider accepted"); end
        S_tx_valid=0;
        transfer(8'h96,8'h3c,4);
        transfer(8'h01,8'h80,250);
        transfer(8'hff,8'h00,6);
        transfer(8'h00,8'hff,10);
        @(negedge S_clk); S_tx_valid=1; S_divider=4;
        wait(S_sclk); #2; S_reset=1; #1;
        if(S_sclk || !S_mosi || S_rx_valid) fail("reset did not abort active SPI");
        S_tx_valid=0; #20; S_reset=0;
        transfer(8'ha5,8'h5a,4);
        S_test_pass=1; $display("PASS: SPI mode0 byte, latched periods, bit order, backpressure and reset"); $finish;
    end
    initial begin #200000; fail("SPI byte watchdog"); end
endmodule
