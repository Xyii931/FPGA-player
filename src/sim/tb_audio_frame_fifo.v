`timescale 1ns/1ps
module tb_audio_frame_fifo;
    reg S_write_clk=0,S_read_clk=0,S_flush=0,S_valid=0,S_ready=0;
    reg [23:0] S_left=0,S_right=0;
    wire S_input_ready,S_output_valid,S_prefilled,S_need_fill;
    wire [23:0] S_out_left,S_out_right;
    wire [11:0] S_write_level,S_read_level;
    integer S_sent=0,S_received=0,S_i;
    reg S_test_pass=0;
    always #4 S_write_clk=~S_write_clk;
    initial begin #1; forever #20 S_read_clk=~S_read_clk; end
    audio_frame_fifo u_dut (
        .I_write_clk(S_write_clk),.I_read_clk(S_read_clk),.I_async_flush(S_flush),
        .I_valid(S_valid),.O_ready(S_input_ready),.I_left(S_left),.I_right(S_right),
        .O_valid(S_output_valid),.I_ready(S_ready),.O_left(S_out_left),.O_right(S_out_right),
        .O_write_level(S_write_level),.O_read_level(S_read_level),
        .O_prefilled(S_prefilled),.O_need_fill(S_need_fill));
    function [23:0] sample;
        input integer index;
        begin sample=24'h800000+index*24'h000101; end
    endfunction
    always @(posedge S_write_clk) begin
        if (!S_flush && S_valid && S_input_ready) S_sent=S_sent+1;
    end
    always @(posedge S_read_clk) begin
        if (!S_flush && S_output_valid && S_ready) begin
            if (S_out_left!==sample(S_received) || S_out_right!==~sample(S_received)) begin
                $display("FAIL: audio FIFO stereo pairing/index %0d",S_received); $stop;
            end
            S_received=S_received+1;
        end
        #0.001;
        if (!S_flush) begin
            if (S_prefilled !== (S_output_valid && S_read_level>=1024) ||
                S_need_fill !== (S_read_level<512)) begin
                $display("FAIL: audio FIFO watermarks"); $stop;
            end
        end
    end
    task settle;
        begin
            repeat (8) @(posedge S_write_clk);
            repeat (8) @(posedge S_read_clk);
            #1;
        end
    endtask
    task write_frames;
        input integer count;
        integer index;
        begin
            for (index=0; index<count; index=index+1) begin
                @(negedge S_write_clk);
                S_valid=1; S_left=sample(S_sent); S_right=~sample(S_sent);
                @(posedge S_write_clk);
                while (!S_input_ready) @(posedge S_write_clk);
            end
            @(negedge S_write_clk); S_valid=0;
            settle;
        end
    endtask
    task read_frames;
        input integer count;
        integer target;
        begin
            target=S_received+count;
            @(negedge S_read_clk); S_ready=1;
            wait (S_received==target);
            @(negedge S_read_clk); S_ready=0;
            settle;
        end
    endtask
    task check_level;
        input integer level;
        input prefilled,need_fill;
        begin
            if (S_write_level!=level || S_read_level!=level ||
                S_prefilled !== prefilled || S_need_fill !== need_fill) begin
                $display("FAIL: expected audio level %0d actual write/read=%0d/%0d",level,S_write_level,S_read_level); $stop;
            end
        end
    endtask
    initial begin
        #1; S_flush=1;
        #1;
        if (S_prefilled || S_need_fill || S_input_ready || S_output_valid) begin
            $display("FAIL: audio flush interfaces"); $stop;
        end
        repeat (3) @(negedge S_write_clk); S_flush=0;
        settle; check_level(0,0,1);
        write_frames(511); check_level(511,0,1);
        write_frames(1); check_level(512,0,0);
        write_frames(511); check_level(1023,0,0);
        write_frames(1); check_level(1024,1,0);
        write_frames(1024); check_level(2048,1,0);
        if (S_input_ready) begin $display("FAIL: audio capacity exceeded"); $stop; end
        read_frames(1024); check_level(1024,1,0);
        read_frames(1); check_level(1023,0,0);
        read_frames(511); check_level(512,0,0);
        read_frames(1); check_level(511,0,1);
        read_frames(511); check_level(0,0,1);
        if (S_output_valid || S_sent!=2048 || S_received!=2048) begin
            $display("FAIL: audio count/empty totals"); $stop;
        end
        write_frames(12);
        #2; S_flush=1;
        #1;
        if (S_output_valid || S_prefilled || S_need_fill || S_input_ready) begin
            $display("FAIL: nonempty audio flush"); $stop;
        end
        repeat (3) @(negedge S_write_clk);
        S_sent=0; S_received=0; S_flush=0;
        settle; check_level(0,0,1);
        write_frames(8); read_frames(8); check_level(0,0,1);
        S_test_pass=1;
        $display("PASS: stereo audio FIFO 2048 frames, exact 512/1024 thresholds and flush");
        $finish;
    end
    initial begin
        #2000000;
        $display("FAIL: audio FIFO timeout"); $stop;
    end
endmodule
