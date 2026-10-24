`timescale 1ns/1ps
module tb_wav_track_source;
    wire [1:0] S_done;
    reg S_test_pass=0;
    wav_source_case #(4,20,2) u_fast_decode(S_done[0]);
    wav_source_case #(20,4,4) u_fast_audio(S_done[1]);
    initial begin
        wait (&S_done); S_test_pass=1;
        $display("PASS: tagged WAV bridge, real PCM/event FIFOs, backpressure, cancellation and clock stop");
        $finish;
    end
    initial begin #5000000; $display("FAIL: WAV track source timeout"); $stop; end
endmodule

module wav_source_case #(
    parameter integer DECODE_HALF=4,AUDIO_HALF=20,ADDR=2
) (output reg O_done);
    localparam integer DEPTH=2**ADDR;
    reg S_decode_clk=0,S_audio_clk=0,S_run_audio=1,S_flush=0;
    reg S_start=0,S_byte_valid=0,S_last=0,S_abort=0,S_read_error=0;
    reg [31:0] S_size=0,S_seek=0;
    wire [31:0] S_event_seek;
    reg [15:0] S_epoch=0,S_byte_epoch=0,S_error_epoch=0;
    reg [7:0] S_byte=0;
    wire S_start_ready,S_byte_ready,S_discard,S_cancel,S_busy,S_quiet;
    wire [15:0] S_cancel_epoch,S_pcm_epoch,S_event_epoch;
    reg S_cancel_ready=0,S_allow_pcm=0,S_allow_events=0;
    reg S_pcm_ready=0;
    wire S_pcm_valid,S_prefilled,S_need_fill,S_header_seen,S_failed;
    wire [23:0] S_left,S_right;
    wire [31:0] S_written,S_total_event,S_written_event;
    wire [ADDR:0] S_write_level,S_read_level;
    wire S_event_valid,S_event_header;
    wire [3:0] S_event_error;
    reg [7:0] S_file[0:4095];
    reg S_apt_mode=0;
    integer S_length,S_frames,S_headers=0,S_terminals=0,S_received=0,S_audio_cycle=0;
    integer S_expected_written,S_cases=0,S_discards=0,S_j;
    reg [3:0] S_expected_error=0;
    reg S_wait_pcm=0,S_wait_event=0;
    reg [47:0] S_held_pcm;
    reg [84:0] S_held_event;
    reg [15:0] S_word;
    always #(DECODE_HALF) S_decode_clk=~S_decode_clk;
    initial begin #1; forever begin #(AUDIO_HALF); if (S_run_audio) S_audio_clk=~S_audio_clk; end end
    function [15:0] sample;
        input integer index;
        begin
            if(S_apt_mode) sample=16'h8000;
            else case (index%5)
                0: sample=16'h8000;
                1: sample=16'h7fff;
                2: sample=16'hffff;
                default: sample=S_epoch+index*16'h101;
            endcase
        end
    endfunction
    wav_track_source #(.FIFO_ADDR_BITS(ADDR),.PREFILL_FRAMES(DEPTH/2),.LOW_FRAMES(DEPTH/4)) u_dut (
        .I_decode_clk(S_decode_clk),.I_audio_clk(S_audio_clk),.I_async_flush(S_flush),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.I_file_size(S_size),.I_epoch(S_epoch),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_byte_last(S_last),.I_byte_epoch(S_byte_epoch),.I_abort(S_abort),
        .I_stream_error_valid(S_read_error),.I_stream_error_epoch(S_error_epoch),
        .O_byte_discarded(S_discard),.O_cancel_valid(S_cancel),.I_cancel_ready(S_cancel_ready),
        .O_cancel_epoch(S_cancel_epoch),.O_busy(S_busy),.O_quiescent(S_quiet),.O_written_frames(S_written),
        .O_valid(S_pcm_valid),.I_ready(S_pcm_ready),.O_left(S_left),.O_right(S_right),
        .O_pcm_epoch(S_pcm_epoch),.O_write_level(S_write_level),.O_read_level(S_read_level),
        .O_prefilled(S_prefilled),.O_need_fill(S_need_fill),.O_header_seen(S_header_seen),.O_failed(S_failed),
        .O_event_valid(S_event_valid),.I_event_ready(S_allow_events),.O_event_header(S_event_header),
        .O_event_epoch(S_event_epoch),.O_event_total_frames(S_total_event),
        .O_event_written_frames(S_written_event),.O_event_error(S_event_error),
        .I_start_index(S_seek),
        .O_event_start_index(S_event_seek)
    );

    always @(negedge S_audio_clk or posedge S_flush) begin
        if (S_flush) begin S_pcm_ready=0; S_audio_cycle=0; end
        else begin
            S_audio_cycle=S_audio_cycle+1;
            S_pcm_ready=S_allow_pcm && S_audio_cycle%7>=2;
        end
    end
    always @(posedge S_audio_clk or posedge S_flush) begin
        if (S_flush) begin
            S_headers=0; S_terminals=0; S_received=0; S_wait_pcm=0; S_wait_event=0;
        end else if (!O_done) begin
            if (S_wait_event && (!S_event_valid ||
                {S_event_header,S_event_epoch,S_total_event,S_written_event,S_event_error}!==S_held_event)) begin
                $display("FAIL in %m: event changed under backpressure"); $stop;
            end
            // Error acceptance explicitly cancels a waiting PCM offer.
            if (S_wait_pcm && !S_failed && (!S_pcm_valid || {S_left,S_right}!==S_held_pcm)) begin
                $display("FAIL in %m: PCM changed while stalled"); $stop;
            end
            S_wait_event=S_event_valid && !S_allow_events;
            S_held_event={S_event_header,S_event_epoch,S_total_event,S_written_event,S_event_error};
            S_wait_pcm=S_pcm_valid && !S_pcm_ready;
            S_held_pcm={S_left,S_right};
            if (S_event_valid && S_allow_events) begin
                if (S_event_epoch!==S_epoch || S_total_event!=S_frames) begin
                    $display("FAIL in %m: event identity/total"); $stop;
                end
                if (S_event_header) begin
                    S_headers=S_headers+1;
                    if (S_headers!=1 || S_terminals!=0 || S_written_event!=0 || S_event_error!=0 || S_event_seek!=S_seek) begin
                        $display("FAIL in %m: header record/order"); $stop;
                    end
                end else begin
                    S_terminals=S_terminals+1;
                    if (S_terminals!=1 || S_written_event!=S_expected_written || S_event_error!==S_expected_error) begin
                        $display("FAIL in %m: terminal record written=%0d expected=%0d code=%0d expected=%0d",
                            S_written_event,S_expected_written,S_event_error,S_expected_error); $stop;
                    end
                end
            end
            if (S_pcm_valid && S_pcm_ready) begin
                if (!S_header_seen || S_headers!=1 || S_pcm_epoch!==S_epoch ||
                    S_left!=={sample(S_received+S_seek),8'd0} || S_right!=={~sample(S_received+S_seek),8'd0}) begin
                    $display("FAIL in %m: PCM identity/order at %0d",S_received); $stop;
                end
                S_received=S_received+1;
                if (S_received+S_seek>S_frames) begin $display("FAIL in %m: extra PCM frame"); $stop; end
            end
        end
    end
    task put32;
        input integer at;
        input [31:0] value;
        begin
            S_file[at]=value[7:0]; S_file[at+1]=value[15:8];
            S_file[at+2]=value[23:16]; S_file[at+3]=value[31:24];
        end
    endtask
    task begin_job;
        input integer frames;
        input [15:0] epoch;
        input apt;
        integer k,block_at;
        begin
            S_start=0; S_byte_valid=0; S_abort=0; S_read_error=0;
            S_allow_pcm=0; S_allow_events=0; S_cancel_ready=0;
            #2; S_flush=1;
            S_epoch=epoch; S_frames=frames; S_apt_mode=apt;
            S_length=apt ? 24+((frames+1016)/1017)*1024 : 44+4*frames;
            S_expected_error=0; S_expected_written=frames; S_cases=S_cases+1;
            for (k=0; k<4096; k=k+1) S_file[k]=0;
            if(apt) begin
                S_file[0]="A"; S_file[1]="P"; S_file[2]="T"; S_file[3]="0";
                put32(4,48000); S_file[8]=2; S_file[10]=1; S_file[13]=4; S_file[14]=24;
                put32(16,frames);
                for(block_at=24;block_at<S_length;block_at=block_at+1024) begin
                    S_file[block_at+1]=8'h80;
                    S_file[block_at+512]=8'hff; S_file[block_at+513]=8'h7f;
                end
            end else begin
            S_file[0]="R"; S_file[1]="I"; S_file[2]="F"; S_file[3]="F";
            put32(4,S_length-8);
            S_file[8]="W"; S_file[9]="A"; S_file[10]="V"; S_file[11]="E";
            S_file[12]="f"; S_file[13]="m"; S_file[14]="t"; S_file[15]=" "; put32(16,16);
            S_file[20]=1; S_file[22]=2; put32(24,48000); put32(28,192000);
            S_file[32]=4; S_file[34]=16;
            S_file[36]="d"; S_file[37]="a"; S_file[38]="t"; S_file[39]="a"; put32(40,frames*4);
            for (k=0; k<frames; k=k+1) begin
                S_word=sample(k); S_file[44+4*k]=S_word[7:0]; S_file[45+4*k]=S_word[15:8];
                S_file[46+4*k]=~S_word[7:0]; S_file[47+4*k]=~S_word[15:8];
            end
            end
            S_size=S_length;
            repeat (4) @(negedge S_decode_clk);
            S_flush=0;
            wait (S_start_ready);
            @(negedge S_decode_clk); S_start=1;
            @(posedge S_decode_clk); #1;
            if (S_start_ready) begin $display("FAIL in %m: accepted start did not close slot"); $stop; end
            @(negedge S_decode_clk); S_start=0;
        end
    endtask
    task send_one;
        input [7:0] value;
        input last;
        input [15:0] epoch;
        input discarded;
        begin
            @(negedge S_decode_clk);
            S_byte_valid=1; S_byte=value; S_last=last; S_byte_epoch=epoch;
            @(posedge S_decode_clk);
            while (!S_byte_ready) @(posedge S_decode_clk);
            #1;
            if (S_discard!==discarded) begin $display("FAIL in %m: byte epoch/discard"); $stop; end
            if (discarded) S_discards=S_discards+1;
            @(negedge S_decode_clk); S_byte_valid=0;
        end
    endtask
    task send_range;
        input integer first,count;
        input inject_stale;
        integer k;
        begin
            for (k=first; k<first+count; k=k+1) begin
                // Same low eight bits deliberately tests the full epoch comparison.
                if (inject_stale && k%13==0) send_one(8'hff,1,S_epoch^16'h0100,1);
                send_one(S_file[k],k==S_length-1,S_epoch,0);
            end
        end
    endtask
    task acknowledge_cancel;
        integer k;
        begin
            wait (S_cancel);
            for (k=0; k<8; k=k+1) begin
                @(posedge S_decode_clk); #1;
                if (!S_cancel || S_cancel_epoch!==S_epoch || S_quiet || !S_busy) begin
                    $display("FAIL in %m: cancellation request was not held"); $stop;
                end
            end
            @(negedge S_decode_clk); S_cancel_ready=1;
            wait (S_quiet);
            @(negedge S_decode_clk); S_cancel_ready=0;
            if (S_start_ready) begin $display("FAIL in %m: slot reused without flush"); $stop; end
        end
    endtask
    initial begin
        O_done=0;
        begin_job(40,16'h0101,0);
        // Stale errors and bytes must not alter the live parser.
        S_error_epoch=16'h0001; S_read_error=1;
        send_one(0,1,16'h0001,1); S_read_error=0;
        fork
            send_range(0,S_length,1);
            begin
                wait (S_write_level==DEPTH);
                repeat (20) @(posedge S_decode_clk);
                if (S_header_seen || S_pcm_valid || !S_event_valid || S_start_ready) begin
                    $display("FAIL in %m: PCM escaped before header acceptance/full FIFO"); $stop;
                end
                S_allow_events=1; S_allow_pcm=1;
            end
        join
        wait (S_terminals==1 && S_received==40 && S_quiet);
        if (S_cancel || S_failed || S_headers!=1) begin $display("FAIL in %m: normal completion"); $stop; end

        // A full PCM FIFO plus another held sample is cancellable without reading.
        begin_job(DEPTH+8,16'h0201,0); S_allow_events=1;
        send_range(0,44+4*(DEPTH+1),0);
        wait (S_written==DEPTH);
        send_one(8'haa,1,16'h0101,1);
        S_expected_error=6; S_expected_written=DEPTH;
        @(negedge S_decode_clk); S_abort=1;
        repeat (3) @(posedge S_decode_clk);
        @(negedge S_decode_clk); S_abort=0;
        wait (S_terminals==1); #1;
        if (!S_failed || S_pcm_valid || S_received!=0) begin $display("FAIL in %m: failed PCM suppression"); $stop; end
        acknowledge_cancel;

        begin_job(8,16'h0301,0); S_allow_events=1;
        send_range(0,52,0); wait (S_written==2);
        S_expected_error=5; S_expected_written=2;
        @(negedge S_decode_clk); S_error_epoch=S_epoch; S_read_error=1;
        repeat (3) @(posedge S_decode_clk);
        @(negedge S_decode_clk); S_read_error=0;
        wait (S_terminals==1); acknowledge_cancel;

        // Header and successful terminal can queue while the audio clock is stopped.
        @(negedge S_audio_clk); S_run_audio=0;
        begin_job(2,16'h0401,0); send_range(0,S_length,0); wait (S_quiet);
        if (S_event_valid || S_pcm_valid || S_header_seen) begin $display("FAIL in %m: stopped-domain release"); $stop; end
        S_run_audio=1; S_allow_events=1; S_allow_pcm=1;
        wait (S_terminals==1 && S_received==2);

        begin_job(0,16'h0501,0); S_allow_events=1; S_allow_pcm=1;
        send_range(0,S_length,0); wait (S_terminals==1 && S_quiet);
        if (S_received!=0 || S_failed || S_cancel) begin $display("FAIL in %m: empty WAV"); $stop; end
        begin_job(0,16'h0601,0); S_file[0]="X"; S_expected_error=1; S_expected_written=0;
        S_allow_events=1; S_allow_pcm=1;
        send_range(0,4,0); wait (S_terminals==1); #1;
        if (S_headers!=0 || S_header_seen || !S_failed || S_pcm_valid) begin
            $display("FAIL in %m: pre-header failure"); $stop;
        end
        acknowledge_cancel;
        // Bytes from the old transaction arriving after its terminal are drained.
        send_one(8'h55,1,S_epoch,1);
        begin_job(1030,16'h0701,1); S_allow_events=1; S_allow_pcm=1;
        send_range(0,S_length,1); wait(S_terminals==1 && S_received==1030 && S_quiet);
        if(S_headers!=1 || S_failed || S_cancel || S_written!=1030) begin
            $display("FAIL in %m: two APT blocks through real tagged PCM/event FIFOs"); $stop;
        end
        S_seek=13; begin_job(40,16'h0801,0); S_allow_events=1; S_allow_pcm=1;
        send_range(0,S_length,1); wait(S_terminals==1 && S_received==27 && S_quiet);
        if(S_written!=40 || S_failed || S_cancel) begin $display("FAIL in %m: WAV seek prefix was not really decoded"); $stop; end
        S_seek=1019; begin_job(1030,16'h0901,1); S_allow_events=1; S_allow_pcm=1;
        send_range(0,S_length,1); wait(S_terminals==1 && S_received==11 && S_quiet);
        if(S_written!=1030 || S_failed || S_cancel) begin $display("FAIL in %m: APT cross-block seek"); $stop; end
        if (S_cases!=9 || S_discards<5) begin $display("FAIL in %m: scenario/discard coverage"); $stop; end
        O_done=1;
    end
endmodule
