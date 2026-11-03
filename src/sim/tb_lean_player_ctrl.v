`timescale 1ns/1ps
module tb_lean_player_ctrl;
    reg S_clk=0,S_reset=1,S_rx=0,S_rx_error=0,S_ready=1,S_active=0,S_busy=0,S_changed=0;
    reg [7:0] S_byte=0;
    reg [3:0] S_keys=0,S_current=2,S_error=0;
    reg [4:0] S_count=4;
    wire S_tx,S_next,S_prev,S_reload,S_auto,S_mute;
    wire [7:0] S_tx_byte;
    wire [1:0] S_rotation;
    wire [2:0] S_volume;
    wire [5:0] S_interval;
    wire [31:0] S_dropped;
    reg [319:0] S_response=0;
    integer S_length=0,S_next_count=0,S_prev_count=0,S_reload_count=0,S_before,S_i,S_test_interval;
    reg [7:0] S_time_tens,S_time_ones;
    reg S_test_pass=0;
    always #4 S_clk=~S_clk;
    lean_player_ctrl #(.CLOCK_HZ(16)) u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_key_release(S_keys),.I_rx_valid(S_rx),.I_rx_error(S_rx_error),.I_rx_data(S_byte),
        .O_tx_valid(S_tx),.I_tx_ready(S_ready),.O_tx_data(S_tx_byte),
        .I_active(S_active),.I_busy(S_busy),.I_changed(S_changed),.I_current(S_current),.I_count(S_count),.I_error(S_error),
        .O_next(S_next),.O_prev(S_prev),.O_reload(S_reload),.O_auto(S_auto),.O_mute(S_mute),
        .O_rotation(S_rotation),.O_volume(S_volume),.O_interval(S_interval),.O_dropped(S_dropped)
    );
    always @(posedge S_clk) if(!S_reset) begin
        if(S_tx && S_ready) begin S_response={S_response[311:0],S_tx_byte}; S_length=S_length+1; end
        if(S_next) S_next_count=S_next_count+1;
        if(S_prev) S_prev_count=S_prev_count+1;
        if(S_reload) S_reload_count=S_reload_count+1;
    end
    task fail;
        input [511:0] text;
        begin $display("FAIL: lean console: %0s len=%0d response=%h",text,S_length,S_response); $stop; end
    endtask
    task byte_send;
        input [7:0] value;
        begin @(negedge S_clk); S_rx=1; S_byte=value; @(negedge S_clk); S_rx=0; end
    endtask
    task line;
        input [63:0] text;
        input integer length;
        input valid;
        begin
            S_response=0; S_length=0;
            for(S_i=length-1;S_i>=0;S_i=S_i-1) byte_send(text>>(S_i*8));
            byte_send(13); byte_send(10);
            wait(!S_tx); @(negedge S_clk);
            if(valid && (S_length!=4 || S_response!={"OK",8'd13,8'd10})) fail("missing OK");
            if(!valid && (S_length!=5 || S_response!={"ERR",8'd13,8'd10})) fail("missing ERR");
        end
    endtask
    reg [7:0] S_held;
    initial begin
        repeat(5) @(negedge S_clk); S_reset=0;
        line("A0",2,1); line("T01",3,1); line("R3",2,1); line("V2",2,1); line("M1",2,1);
        if(S_auto || S_interval!=1 || S_rotation!=3 || S_volume!=2 || !S_mute) fail("configuration mismatch");
        S_before=S_next_count; line("N",1,1); if(S_next_count!=S_before+1) fail("NEXT missing");
        line("P",1,1); if(S_prev_count!=1) fail("PREV missing");
        line("T00",3,0); line("T61",3,0); line("R4",2,0); line("V5",2,0); line("NXXX",4,0);
        if(S_interval!=1 || S_rotation!=3 || S_volume!=2 || S_next_count!=S_before+1) fail("invalid command executed");
        // Cover every accepted decimal interval and reject non-digit ASCII
        // around the digit boundaries; range decoding must not alias them.
        for(S_test_interval=1;S_test_interval<=60;S_test_interval=S_test_interval+1) begin
            S_time_tens=48+S_test_interval/10; S_time_ones=48+S_test_interval%10;
            line({8'h54,S_time_tens,S_time_ones},3,1);
            if(S_interval!=S_test_interval) fail("decimal interval decoding mismatch");
        end
        line("T0/",3,0); line("T0:",3,0); line("T/1",3,0); line("T70",3,0);
        if(S_interval!=60) fail("malformed time command executed");
        line("T01",3,1);
        S_response=0; S_length=0; S_ready=0; byte_send("?"); byte_send(10);
        wait(S_tx); #1; S_held=S_tx_byte; S_current=9; S_count=16;
        repeat(5) begin @(posedge S_clk); #1; if(!S_tx || S_tx_byte!==S_held) fail("TX changed while stalled"); end
        @(negedge S_clk); S_ready=1; wait(!S_tx); @(negedge S_clk);
        if(S_response!=={"I:02 N:04 A:0 R:3 T:01 V:2 M:1 B:0 E:0",8'd13,8'd10}) fail("status snapshot or layout mismatch");
        line("A1",2,1); S_before=S_next_count;
        @(negedge S_clk); S_active=1;
        repeat(17) @(negedge S_clk);
        if(S_next_count!=S_before+1) fail("automatic interval mismatch");
        S_busy=1; S_before=S_next_count; repeat(40) @(negedge S_clk);
        if(S_next_count!=S_before) fail("autoplay advanced during load");
        S_active=0; S_busy=0;
        @(negedge S_clk); S_keys=8; @(negedge S_clk); S_keys=0; repeat(2) @(negedge S_clk);
        if(S_rotation!=0 || S_reload_count!=2) fail("board rotation missing");
        S_test_pass=1; $display("PASS: lean UART grammar, responses, timer, keys and atomic status"); $finish;
    end
    initial begin #100000; fail("watchdog"); end
endmodule
