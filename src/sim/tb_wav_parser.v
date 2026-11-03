`timescale 1ns/1ps
module tb_wav_parser;
    reg S_clk=0,S_reset=0,S_start=0,S_valid=0,S_last=0,S_abort=0,S_read_error=0;
    reg [31:0] S_size=0;
    reg [7:0] S_tag=0,S_byte=0;
    reg S_header_ready=0,S_sample_ready=0,S_force_stall=0;
    wire S_start_ready,S_ready,S_busy,S_done,S_err,S_header_valid,S_sample_valid,S_sample_last;
    wire [3:0] S_code;
    wire [7:0] S_out_tag;
    wire [31:0] S_offset,S_bytes,S_frames,S_index;
    wire [23:0] S_left,S_right;
    reg S_test_pass=0;
    reg [7:0] S_file[0:4095];
    integer S_total,S_riff_end,S_fmt_head,S_data_head,S_data_offset,S_frame_count;
    integer S_cursor,S_k,S_j,S_chunk_at,S_case=0,S_received=0,S_headers=0,S_terminals=0,S_input_bytes=0;
    integer S_ticks=0;
    reg [15:0] S_rng=16'h1234;
    reg [3:0] S_expected_error=0;
    reg S_header_wait=0,S_sample_wait=0;
    reg [95:0] S_saved_header;
    reg [80:0] S_saved_sample;
    reg [15:0] S_l16,S_r16;
    always #4 S_clk=~S_clk;
    wav_parser u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(S_size),.I_tag(S_tag),.I_byte_valid(S_valid),.O_byte_ready(S_ready),
        .I_byte_data(S_byte),.I_byte_last(S_last),.I_abort(S_abort),.I_stream_error(S_read_error),
        .O_busy(S_busy),.O_done(S_done),.O_err(S_err),.O_error_code(S_code),.O_tag(S_out_tag),
        .O_header_valid(S_header_valid),.I_header_ready(S_header_ready),
        .O_data_offset(S_offset),.O_data_bytes(S_bytes),.O_total_frames(S_frames),
        .O_sample_valid(S_sample_valid),.I_sample_ready(S_sample_ready),
        .O_left(S_left),.O_right(S_right),.O_sample_index(S_index),.O_sample_last(S_sample_last)
    );
    function [15:0] left_sample;
        input integer index;
        begin
            case (index%8)
                0: left_sample=0;
                1: left_sample=16'h7fff;
                2: left_sample=16'h8000;
                3: left_sample=16'hffff;
                4: left_sample=1;
                5: left_sample=16'h4000;
                6: left_sample=16'hc000;
                7: left_sample=16'h1234;
            endcase
        end
    endfunction
    task put32;
        input integer at;
        input [31:0] value;
        begin
            S_file[at]=value[7:0]; S_file[at+1]=value[15:8];
            S_file[at+2]=value[23:16]; S_file[at+3]=value[31:24];
        end
    endtask
    task chunk_header;
        input [31:0] id;
        input integer size;
        begin
            S_chunk_at=S_cursor;
            S_file[S_cursor]=id[31:24]; S_file[S_cursor+1]=id[23:16];
            S_file[S_cursor+2]=id[15:8]; S_file[S_cursor+3]=id[7:0];
            put32(S_cursor+4,size);
            S_cursor=S_cursor+8;
        end
    endtask
    task junk;
        input integer count;
        begin
            chunk_header(32'h4a554e4b,count);
            // Nonzero pad bytes must be skipped, not treated as another chunk header.
            for (S_j=0; S_j<count+(count%2); S_j=S_j+1) begin
                S_file[S_cursor]=8'h5a; S_cursor=S_cursor+1;
            end
        end
    endtask
    task build_file;
        input integer frames;
        input rich;
        input integer tail;
        begin
            for (S_k=0; S_k<4096; S_k=S_k+1) S_file[S_k]=0;
            S_frame_count=frames;
            S_file[0]="R"; S_file[1]="I"; S_file[2]="F"; S_file[3]="F";
            S_file[8]="W"; S_file[9]="A"; S_file[10]="V"; S_file[11]="E";
            S_cursor=12;
            if (rich) begin junk(0); junk(3); end
            S_fmt_head=S_cursor;
            chunk_header(32'h666d7420,rich ? 19 : 16);
            S_file[S_cursor]=1; S_file[S_cursor+2]=2;
            put32(S_cursor+4,48000); put32(S_cursor+8,192000);
            S_file[S_cursor+12]=4; S_file[S_cursor+14]=16;
            S_cursor=S_cursor+(rich ? 20 : 16);
            if (rich) junk(5);
            S_data_head=S_cursor;
            chunk_header(32'h64617461,4*frames);
            S_data_offset=S_cursor;
            for (S_k=0; S_k<frames; S_k=S_k+1) begin
                S_l16=left_sample(S_k); S_r16=~S_l16;
                S_file[S_cursor]=S_l16[7:0]; S_file[S_cursor+1]=S_l16[15:8];
                S_file[S_cursor+2]=S_r16[7:0]; S_file[S_cursor+3]=S_r16[15:8];
                S_cursor=S_cursor+4;
            end
            if (rich) begin junk(1); junk(2); end
            S_riff_end=S_cursor; put32(4,S_riff_end-8);
            S_total=S_cursor+tail;
            for (S_k=S_cursor; S_k<S_total; S_k=S_k+1) S_file[S_k]=8'hee;
        end
    endtask
    always @(negedge S_clk) begin
        S_ticks=S_ticks+1;
        S_rng={S_rng[14:0],S_rng[15]^S_rng[13]^S_rng[12]^S_rng[10]};
        S_header_ready=S_ticks%23>=9;
        S_sample_ready=!S_force_stall && S_ticks%29>=10 && S_rng[0];
    end
    always @(posedge S_clk) begin
        if (S_reset || S_abort || S_read_error) begin S_header_wait=0; S_sample_wait=0; end
        else begin
            if (S_header_wait && (!S_header_valid || {S_offset,S_bytes,S_frames} !== S_saved_header)) begin
                $display("FAIL: WAV metadata changed while stalled"); $stop;
            end
            if (S_sample_wait && (!S_sample_valid || {S_left,S_right,S_index,S_sample_last} !== S_saved_sample)) begin
                $display("FAIL: WAV sample changed while stalled"); $stop;
            end
            S_header_wait=S_header_valid && !S_header_ready;
            S_sample_wait=S_sample_valid && !S_sample_ready;
            S_saved_header={S_offset,S_bytes,S_frames};
            S_saved_sample={S_left,S_right,S_index,S_sample_last};
            if (S_valid && S_ready) S_input_bytes=S_input_bytes+1;
            if (S_header_valid && S_header_ready) begin
                S_headers=S_headers+1;
                if (S_offset!=S_data_offset || S_bytes!=S_frame_count*4 || S_frames!=S_frame_count) begin
                    $display("FAIL: WAV metadata case=%0d",S_case); $stop;
                end
            end
            if (S_sample_valid && S_sample_ready) begin
                S_l16=left_sample(S_received); S_r16=~S_l16;
                if (S_index!=S_received || $signed(S_left)!=$signed(S_l16)*32'sd256 ||
                    $signed(S_right)!=$signed(S_r16)*32'sd256 ||
                    S_sample_last !== (S_received==S_frame_count-1)) begin
                    $display("FAIL: WAV sample case=%0d frame=%0d L=%h R=%h",S_case,S_received,S_left,S_right); $stop;
                end
                S_received=S_received+1;
            end
        end
        if (!S_reset && S_done) begin
            S_terminals=S_terminals+1;
            if (S_code !== S_expected_error || S_err !== (S_expected_error!=0) || S_out_tag !== S_tag) begin
                $display("FAIL: WAV terminal case=%0d code=%0d expected=%0d",S_case,S_code,S_expected_error); $stop;
            end
        end
    end
    task start_job;
        input [3:0] expected_error;
        begin
            @(negedge S_clk);
            S_case=S_case+1; S_tag=S_case; S_expected_error=expected_error;
            S_received=0; S_headers=0; S_terminals=0; S_input_bytes=0;
            S_size=S_total; S_start=1;
            @(posedge S_clk);
            if (!S_start_ready) begin $display("FAIL: WAV start not ready"); $stop; end
            @(negedge S_clk); S_start=0;
        end
    endtask
    task send_bytes;
        input integer count,last_index;
        integer index;
        reg accepted;
        begin
            index=0;
            while (index<count && S_terminals==0) begin
                @(negedge S_clk);
                if (index%7==0) begin S_valid=0; @(negedge S_clk); end
                S_valid=1; S_byte=S_file[index]; S_last=(index==last_index);
                accepted=0;
                while (!accepted && S_terminals==0) begin
                    @(posedge S_clk); accepted=S_ready;
                    @(negedge S_clk);
                end
                S_valid=0; index=index+1;
            end
        end
    endtask
    task finish_job;
        input success;
        begin
            wait (S_terminals!=0);
            repeat (4) @(negedge S_clk);
            if (S_terminals!=1 || S_busy || !S_start_ready ||
                (success && (S_received!=S_frame_count || S_headers!=1 || S_input_bytes!=S_total))) begin
                $display("FAIL: WAV totals case=%0d samples=%0d headers=%0d bytes=%0d",S_case,S_received,S_headers,S_input_bytes); $stop;
            end
        end
    endtask
    initial begin
        #1; S_reset=1;
        repeat (2) @(negedge S_clk); S_reset=0;
        build_file(8,0,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(32,1,7); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(0,0,0); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(0,1,3); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        build_file(1,0,0); S_file[0]="X"; start_job(1); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[8]="X"; start_job(1); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(4,32'hffffffff); start_job(3); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(4,1); start_job(3); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(S_fmt_head+4,15); start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[S_fmt_head+8]=3; start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[S_fmt_head+10]=1; start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(S_fmt_head+12,44100); start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(S_fmt_head+16,123); start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[S_fmt_head+20]=2; start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[S_fmt_head+22]=24; start_job(2); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(S_data_head+4,3); start_job(3); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); put32(S_data_head+4,32'hfffffffc); start_job(3); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[S_fmt_head]="J"; start_job(4); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0); S_file[S_data_head]="J"; start_job(4); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(1,0,0);
        S_file[S_fmt_head]="d"; S_file[S_fmt_head+1]="a"; S_file[S_fmt_head+2]="t"; S_file[S_fmt_head+3]="a";
        start_job(4); send_bytes(S_total,S_total-1); finish_job(0);
        // Trailing partial RIFF chunk header after samples: no success terminal.
        build_file(2,0,1); put32(4,S_total-8);
        start_job(3); send_bytes(S_total,S_total-1); finish_job(0);
        // Duplicate data/fmt following already emitted samples.
        build_file(2,0,0); chunk_header(32'h64617461,0); S_total=S_cursor; put32(4,S_total-8);
        start_job(4); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(2,0,0); chunk_header(32'h666d7420,16); S_cursor=S_cursor+16;
        S_total=S_cursor; put32(4,S_total-8);
        start_job(4); send_bytes(S_total,S_total-1); finish_job(0);
        // Unknown odd chunk missing its required pad at RIFF end.
        build_file(1,0,0); chunk_header(32'h4a554e4b,1); S_cursor=S_cursor+1;
        S_total=S_cursor; put32(4,S_total-8);
        start_job(3); send_bytes(S_total,S_total-1); finish_job(0);
        build_file(2,1,0); start_job(5); send_bytes(11,10); finish_job(0);
        build_file(2,0,0); start_job(5); send_bytes(S_total,-1); finish_job(0);
        build_file(1,0,0); S_total=10; start_job(3); finish_job(0);
        build_file(8,0,0); start_job(5); send_bytes(20,-1);
        @(negedge S_clk); S_read_error=1;
        @(negedge S_clk); S_read_error=0; finish_job(0);
        build_file(8,0,0); S_force_stall=1; start_job(6); send_bytes(S_data_offset+4,-1);
        wait (S_sample_valid);
        @(negedge S_clk); S_abort=1;
        @(negedge S_clk); S_abort=0; S_force_stall=0; finish_job(0);
        if (S_sample_valid) begin $display("FAIL: WAV cancelled sample survived"); $stop; end
        build_file(8,0,0); start_job(0); send_bytes(20,-1);
        @(negedge S_clk); S_reset=1;
        repeat (2) @(negedge S_clk); S_reset=0;
        repeat (3) @(negedge S_clk);
        if (S_terminals!=0 || S_busy || S_sample_valid || S_header_valid) begin
            $display("FAIL: WAV reset cancellation"); $stop;
        end
        build_file(8,1,5); start_job(0); send_bytes(S_total,S_total-1); finish_job(1);
        S_test_pass=1;
        $display("PASS: WAV PCM, RIFF boundaries/pad, backpressure, cancellation (%0d cases)",S_case);
        $finish;
    end
    initial begin
        #2000000;
        $display("FAIL: WAV timeout case=%0d",S_case); $stop;
    end
endmodule
