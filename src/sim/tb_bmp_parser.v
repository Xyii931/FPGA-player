`timescale 1ns/1ps
module tb_bmp_parser;
    reg S_clk = 0, S_reset = 0, S_start = 0, S_abort = 0, S_stream_err = 0;
    reg [31:0] S_size = 0;
    reg [7:0] S_tag = 0, S_byte = 0;
    reg S_byte_valid = 0, S_byte_last = 0, S_meta_ready = 0, S_pixel_ready = 0;
    wire S_start_ready, S_busy, S_done, S_err, S_byte_ready, S_meta_valid, S_pixel_valid;
    wire [3:0] S_code;
    wire [7:0] S_result_tag;
    wire [15:0] S_width, S_height, S_x, S_y;
    wire S_bottom_up, S_last;
    wire [5:0] S_bpp;
    wire [31:0] S_offset, S_stride, S_rgba;
    reg [7:0] S_file [0:8191];
    integer S_w, S_h, S_bits, S_gap, S_tail, S_total, S_row_bytes;
    integer S_i, S_row, S_col, S_channel, S_at, S_case = 0;
    integer S_pixels = 0, S_terminals = 0, S_headers = 0;
    integer S_expected_x, S_expected_y, S_expected_row;
    reg S_bottom;
    reg [3:0] S_expected_error = 0;
    reg S_test_pass = 0;
    reg [15:0] S_rng = 16'hbeef;
    integer S_ticks = 0;
    reg S_meta_wait = 0, S_pixel_wait = 0;
    reg S_force_pixel_stall = 0;
    reg [102:0] S_saved_meta;
    reg [64:0] S_saved_pixel;
    always #4 S_clk = ~S_clk;
    bmp_parser u_dut (
        .I_clk(S_clk), .I_reset(S_reset), .I_start_valid(S_start), .O_start_ready(S_start_ready),
        .I_file_size(S_size), .I_tag(S_tag), .O_busy(S_busy), .O_done(S_done), .O_err(S_err),
        .O_error_code(S_code), .O_tag(S_result_tag), .I_byte_valid(S_byte_valid),
        .O_byte_ready(S_byte_ready), .I_byte_data(S_byte), .I_byte_last(S_byte_last),
        .I_stream_error(S_stream_err), .I_abort(S_abort), .O_header_valid(S_meta_valid),
        .I_header_ready(S_meta_ready), .O_width(S_width), .O_height(S_height),
        .O_bottom_up(S_bottom_up), .O_bpp(S_bpp), .O_pixel_offset(S_offset), .O_row_bytes(S_stride),
        .O_pixel_valid(S_pixel_valid), .I_pixel_ready(S_pixel_ready), .O_rgba(S_rgba),
        .O_x(S_x), .O_y(S_y), .O_pixel_last(S_last)
    );
    function [7:0] channel;
        input integer x, y, c;
        begin channel = (x*17 + y*31 + c*67 + 9) % 256; end
    endfunction
    task put32;
        input integer at;
        input [31:0] value;
        begin
            S_file[at]=value[7:0]; S_file[at+1]=value[15:8];
            S_file[at+2]=value[23:16]; S_file[at+3]=value[31:24];
        end
    endtask
    task build_file;
        input integer w, h, bits;
        input bottom;
        input integer gap, tail;
        begin
            S_w=w; S_h=h; S_bits=bits; S_bottom=bottom; S_gap=gap; S_tail=tail;
            S_row_bytes=((w*(bits/8)+3)/4)*4;
            S_total=54+gap+S_row_bytes*h+tail;
            if (S_total > 8192) begin $display("FAIL: test fixture capacity"); $stop; end
            for (S_i=0; S_i<S_total; S_i=S_i+1) S_file[S_i]=0;
            S_file[0]=8'h42; S_file[1]=8'h4d;
            put32(2,S_total); put32(10,54+gap); put32(14,40); put32(18,w);
            if (bottom) put32(22,h); else put32(22,-h);
            S_file[26]=1; S_file[28]=bits;
            put32(34,S_row_bytes*h);
            for (S_row=0; S_row<h; S_row=S_row+1)
                for (S_col=0; S_col<w; S_col=S_col+1)
                    for (S_channel=0; S_channel<bits/8; S_channel=S_channel+1) begin
                        S_at=54+gap+S_row*S_row_bytes+S_col*(bits/8)+S_channel;
                        S_file[S_at]=channel(S_col,S_row,S_channel);
                    end
        end
    endtask
    // Periodic long stalls plus deterministic pseudo-random ready.
    always @(negedge S_clk) begin
        S_ticks=S_ticks+1;
        S_rng={S_rng[14:0],S_rng[15]^S_rng[13]^S_rng[12]^S_rng[10]};
        S_meta_ready=(S_ticks%23 >= 9);
        S_pixel_ready=!S_force_pixel_stall && (S_ticks%29 >= 10) && S_rng[0];
    end
    always @(posedge S_clk) begin
        if (S_reset || S_abort || S_stream_err) begin
            S_meta_wait=0; S_pixel_wait=0;
        end else begin
            if (S_meta_wait && (!S_meta_valid ||
                {S_width,S_height,S_bottom_up,S_bpp,S_offset,S_stride} !== S_saved_meta)) begin
                $display("FAIL: header changed while waiting"); $stop;
            end
            if (S_pixel_wait && (!S_pixel_valid || {S_rgba,S_x,S_y,S_last} !== S_saved_pixel)) begin
                $display("FAIL: pixel changed while waiting"); $stop;
            end
            S_meta_wait=S_meta_valid && !S_meta_ready;
            S_saved_meta={S_width,S_height,S_bottom_up,S_bpp,S_offset,S_stride};
            S_pixel_wait=S_pixel_valid && !S_pixel_ready;
            S_saved_pixel={S_rgba,S_x,S_y,S_last};
            if (S_meta_valid && S_meta_ready) begin
                S_headers=S_headers+1;
                if (S_width != S_w || S_height != S_h || S_bpp != S_bits ||
                    S_bottom_up !== S_bottom || S_stride != S_row_bytes || S_offset != 54+S_gap) begin
                    $display("FAIL: metadata case %0d",S_case); $stop;
                end
            end
            if (S_pixel_valid && S_pixel_ready) begin
                S_expected_x=S_pixels%S_w;
                S_expected_row=S_pixels/S_w;
                S_expected_y=S_bottom ? S_h-1-S_expected_row : S_expected_row;
                if (S_x != S_expected_x || S_y != S_expected_y ||
                    S_rgba !== {channel(S_expected_x,S_expected_row,2),
                        channel(S_expected_x,S_expected_row,1),channel(S_expected_x,S_expected_row,0),8'hff} ||
                    S_last !== (S_pixels == S_w*S_h-1)) begin
                    $display("FAIL: pixel case=%0d index=%0d xy=%0d,%0d rgba=%h",S_case,S_pixels,S_x,S_y,S_rgba);
                    $stop;
                end
                S_pixels=S_pixels+1;
            end
        end
        // done is observed on the next clock after its registered assertion.
        if (!S_reset && S_done) begin
            S_terminals=S_terminals+1;
            if (S_code !== S_expected_error || S_err !== (S_expected_error != 0) || S_result_tag !== S_tag) begin
                $display("FAIL: terminal case=%0d code=%0d expected=%0d tag=%h",S_case,S_code,S_expected_error,S_result_tag); $stop;
            end
        end
    end
    task start_job;
        input [3:0] error_code;
        begin
            @(negedge S_clk);
            S_case=S_case+1; S_tag=S_case; S_expected_error=error_code;
            S_pixels=0; S_headers=0; S_terminals=0;
            S_size=S_total; S_start=1;
            @(posedge S_clk);
            if (!S_start_ready) begin $display("FAIL: start not ready"); $stop; end
            @(negedge S_clk); S_start=0;
        end
    endtask
    task send_bytes;
        input integer count;
        input integer last_index;
        integer index;
        reg accepted;
        begin
            index=0;
            while (index<count && S_terminals==0) begin
                @(negedge S_clk);
                if (index%7==0) begin
                    S_byte_valid=0;
                    @(negedge S_clk);
                end
                S_byte_valid=1; S_byte=S_file[index]; S_byte_last=(index==last_index);
                accepted=0;
                while (!accepted && S_terminals==0) begin
                    @(posedge S_clk);
                    accepted=S_byte_ready;
                    @(negedge S_clk);
                end
                S_byte_valid=0;
                index=index+1;
            end
        end
    endtask
    task finish_job;
        input expect_full;
        begin
            wait (S_terminals != 0);
            repeat (4) @(negedge S_clk);
            if (S_terminals != 1 || S_busy || !S_start_ready ||
                (expect_full && (S_headers != 1 || S_pixels != S_w*S_h)) ||
                (S_expected_error >= 1 && S_expected_error <= 4 && (S_headers != 0 || S_pixels != 0))) begin
                $display("FAIL: completion totals case=%0d headers=%0d pixels=%0d",S_case,S_headers,S_pixels); $stop;
            end
        end
    endtask
    initial begin
        #1; S_reset=1;
        repeat (2) @(negedge S_clk);
        S_reset=0;
        // Every 24-bit padding width, signed heights, BGRA alpha ignored, gaps/tails.
        build_file(1,3,24,1,0,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(2,3,24,0,7,5); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(3,2,24,1,1,0); put32(34,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(4,2,24,0,0,3); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(3,2,32,1,0,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(1,1,32,0,0,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(1,1,24,1,0,0); S_file[0]=0; start_job(1); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(14,108); start_job(1); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); S_file[26]=2; start_job(2); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); S_file[28]=16; start_job(2); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(30,3); start_job(2); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(18,0); start_job(3); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(18,-1); start_job(3); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(18,1921); start_job(3); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(22,32'h80000000); start_job(3); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(22,0); start_job(3); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(22,1081); start_job(3); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(10,53); start_job(4); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(10,32'hfffffffe); start_job(4); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(2,S_total+1); start_job(4); send_bytes(54,-1); finish_job(0);
        build_file(1,1,24,1,0,0); put32(34,1); start_job(4); send_bytes(54,-1); finish_job(0);
        build_file(2,2,24,1,0,0); S_total=S_total-1; put32(2,S_total);
        start_job(4); send_bytes(54,-1); finish_job(0);
        build_file(2,2,24,0,0,0); start_job(5); send_bytes(60,59); finish_job(0);
        build_file(1,1,24,0,0,0); start_job(5); send_bytes(11,10); finish_job(0);
        build_file(1,1,24,0,0,0); start_job(5); send_bytes(S_total,-1); finish_job(0);
        build_file(1,1,24,0,0,0); S_total=12; start_job(4); finish_job(0);
        // Maximum legal dimensions: header only, then cancel before supplying pixels.
        build_file(1,1,32,0,0,0);
        S_w=1920; S_h=1080; S_row_bytes=7680; S_total=54+7680*1080;
        put32(2,S_total); put32(18,1920); put32(22,-1080); put32(34,7680*1080);
        start_job(6); send_bytes(54,-1); wait (S_headers==1);
        @(negedge S_clk); S_abort=1;
        @(negedge S_clk); S_abort=0;
        finish_job(0);
        // Explicit upstream read error, then reusable after terminal.
        build_file(2,2,32,1,0,0); start_job(5); send_bytes(56,-1);
        @(negedge S_clk); S_stream_err=1;
        @(negedge S_clk); S_stream_err=0;
        finish_job(0);
        // Cancel a valid pixel held by the consumer; no pixel may survive cancellation.
        build_file(2,2,24,0,0,0); S_force_pixel_stall=1;
        start_job(6); send_bytes(57,-1); wait (S_pixel_valid);
        @(negedge S_clk); S_abort=1;
        @(negedge S_clk); S_abort=0; S_force_pixel_stall=0;
        finish_job(0);
        if (S_pixel_valid) begin $display("FAIL: cancelled pixel remained valid"); $stop; end
        // Reset discards a partial header without a terminal, then accepts a new job.
        build_file(2,2,24,0,0,0); start_job(0); send_bytes(20,-1);
        @(negedge S_clk); S_reset=1;
        repeat (2) @(negedge S_clk);
        S_reset=0;
        repeat (3) @(negedge S_clk);
        if (S_terminals != 0 || !S_start_ready || S_pixel_valid || S_meta_valid) begin
            $display("FAIL: reset cancellation"); $stop;
        end
        build_file(1,1,24,0,0,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        S_test_pass=1;
        $display("PASS: BMP headers, BGR/BGRA, coordinates, padding, backpressure and errors (%0d cases)",S_case);
        $finish;
    end
    initial begin
        #1000000;
        $display("FAIL: BMP parser timeout case=%0d",S_case); $stop;
    end
endmodule
