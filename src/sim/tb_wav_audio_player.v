`timescale 1ns/1ps
// Real WAV parser/FIFOs/playback/recycle; file retirement is a delayed test peer.
module tb_wav_audio_player;
    wire S_silence_u_dut_O_silence_ready;
    wire S_silence_u_dut_O_silence_started;
    wire S_silence_u_dut_O_silence_done;
    reg S_decode_clk=0,S_audio_clk=0,S_reset=1,S_tick=0;
    always #4 S_decode_clk=~S_decode_clk;
    always #20 S_audio_clk=~S_audio_clk;
    reg [1:0] S_start=0,S_byte_valid=0,S_last=0,S_recycle=0,S_cancel_ready=0,S_retired=0;
    reg [63:0] S_size=0;
    reg [31:0] S_epoch=0,S_byte_epoch=0;
    reg [15:0] S_bytes=0;
    wire [1:0] S_start_ready,S_byte_ready,S_discard,S_recycle_ready,S_recycle_done,S_available;
    wire [1:0] S_cancel,S_retire,S_source_busy;
    wire [31:0] S_cancel_epoch;
    wire [63:0] S_written;
    reg S_play=1,S_fade=0,S_target=0,S_pause=0;
    wire S_play_ready,S_fade_ready,S_paused,S_pause_busy,S_valid,S_clip,S_fade_done,S_active,S_busy;
    wire [23:0] S_left,S_right;
    wire [1:0] S_loaded,S_enabled,S_end,S_consumed,S_under,S_release,S_fill,S_failed,S_stopping;
    wire [63:0] S_next;
    wire [1:0] S_event_valid,S_event_header;
    reg [1:0] S_event_ready=0;
    wire [31:0] S_event_epoch;
    wire [63:0] S_event_total,S_event_written;
    wire [7:0] S_event_error;
    reg [7:0] S_file[0:4095];
    integer S_frames[0:1],S_length[0:1],S_received[0:1],S_headers[0:1],S_terminals[0:1];
    integer S_retire_delay[0:1];
    integer S_gain_consumed[0:1];
    wire [1:0] S_guard_reset={u_dut.u_playback.S_b_guard_reset,u_dut.u_playback.S_a_guard_reset};
    reg [1:0] S_sender_done=0;
    reg [15:0] S_seed[0:1],S_expected_epoch[0:1];
    integer S_tick_count=0,S_i,S_j,S_checks=0,S_samples=0,S_recycles=0;
    reg [4:0] S_valid_pipe=0,S_check_pipe=0;
    reg [23:0] S_left_pipe[0:4],S_right_pipe[0:4];
    reg [1:0] S_event_held=0;
    reg [84:0] S_held[0:1];
    reg S_test_pass=0;

    wav_audio_player #(.FIFO_ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4),.FADE_SAMPLES(7)) u_dut (
        .I_decode_clk(S_decode_clk),.I_audio_clk(S_audio_clk),.I_async_reset(S_reset),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.I_file_size(S_size),.I_epoch(S_epoch),
        .I_byte_valid(S_byte_valid),.I_byte_last(S_last),.I_byte_data(S_bytes),.I_byte_epoch(S_byte_epoch),
        .O_byte_ready(S_byte_ready),.O_byte_discarded(S_discard),
        .I_stream_error_valid(2'b00),.I_stream_error_epoch(32'd0),
        .I_recycle_valid(S_recycle),.O_recycle_ready(S_recycle_ready),
        .O_recycle_done(S_recycle_done),.O_available(S_available),
        .O_cancel_valid(S_cancel),.I_cancel_ready(S_cancel_ready),.O_cancel_epoch(S_cancel_epoch),
        .O_io_retire_request(S_retire),.I_io_retired(S_retired),
        .O_source_busy(S_source_busy),.O_written_frames(S_written),
        .I_sample_tick(S_tick),.I_play_valid(S_play),.O_play_ready(S_play_ready),
        .I_fade_valid(S_fade),.I_target_b(S_target),.O_fade_ready(S_fade_ready),
        .I_pause(S_pause),.I_pause_allow(1'b1),.O_paused(S_paused),.O_pause_busy(S_pause_busy),
        .I_volume(5'd16),.I_mute(1'b0),.I_prompt_valid(1'b0),
        .I_prompt_left(24'd0),.I_prompt_right(24'd0),
        .O_sample_valid(S_valid),.O_left(S_left),.O_right(S_right),.O_clipped(S_clip),
        .O_fade_done(S_fade_done),.O_active_b(S_active),.O_busy(S_busy),
        .O_loaded(S_loaded),.O_enabled(S_enabled),.O_end(S_end),.O_consumed(S_consumed),
        .O_underrun(S_under),.O_release(S_release),.O_next_index(S_next),
        .O_need_fill(S_fill),.O_failed(S_failed),.O_slot_stopping(S_stopping),
        .O_event_valid(S_event_valid),.I_event_ready(S_event_ready),.O_event_header(S_event_header),
        .O_event_epoch(S_event_epoch),.O_event_total_frames(S_event_total),
        .O_event_written_frames(S_event_written),.O_event_error(S_event_error),
        .I_silence_valid(1'b0),
        .O_silence_ready(S_silence_u_dut_O_silence_ready),
        .O_silence_started(S_silence_u_dut_O_silence_started),
        .O_silence_done(S_silence_u_dut_O_silence_done),
        .I_start_index(64'd0)
    );

    task fail;
        input [511:0] message;
        begin $display("FAIL: %0s",message); $stop; end
    endtask
    function [15:0] sample;
        input integer slot,index;
        begin sample=S_seed[slot]+index*17; end
    endfunction
    task put32;
        input integer address,value;
        begin
            S_file[address]=value; S_file[address+1]=value>>8;
            S_file[address+2]=value>>16; S_file[address+3]=value>>24;
        end
    endtask
    task begin_file;
        input integer slot,frames;
        input [15:0] epoch,seed;
        integer base,k;
        reg [15:0] word_value;
        begin
            base=slot*2048; S_frames[slot]=frames; S_length[slot]=44+4*frames;
            S_seed[slot]=seed; S_expected_epoch[slot]=epoch; S_sender_done[slot]=0;
            for(k=0;k<2048;k=k+1) S_file[base+k]=0;
            S_file[base]="R"; S_file[base+1]="I"; S_file[base+2]="F"; S_file[base+3]="F";
            put32(base+4,S_length[slot]-8);
            S_file[base+8]="W"; S_file[base+9]="A"; S_file[base+10]="V"; S_file[base+11]="E";
            S_file[base+12]="f"; S_file[base+13]="m"; S_file[base+14]="t"; S_file[base+15]=" ";
            put32(base+16,16); S_file[base+20]=1; S_file[base+22]=2;
            put32(base+24,48000); put32(base+28,192000); S_file[base+32]=4; S_file[base+34]=16;
            S_file[base+36]="d"; S_file[base+37]="a"; S_file[base+38]="t"; S_file[base+39]="a";
            put32(base+40,4*frames);
            for(k=0;k<frames;k=k+1) begin
                word_value=sample(slot,k);
                S_file[base+44+4*k]=word_value[7:0]; S_file[base+45+4*k]=word_value[15:8];
                S_file[base+46+4*k]=~word_value[7:0]; S_file[base+47+4*k]=~word_value[15:8];
            end
            wait(S_start_ready[slot]); @(negedge S_decode_clk);
            S_size[slot*32+:32]=S_length[slot]; S_epoch[slot*16+:16]=epoch; S_start[slot]=1;
            @(negedge S_decode_clk); S_start[slot]=0;
        end
    endtask
    task send_byte;
        input integer slot;
        input [7:0] value;
        input last;
        input [15:0] epoch;
        input discarded;
        begin
            @(negedge S_decode_clk); S_byte_valid[slot]=1; S_last[slot]=last;
            S_bytes[slot*8+:8]=value; S_byte_epoch[slot*16+:16]=epoch;
            @(posedge S_decode_clk); while(!S_byte_ready[slot]) @(posedge S_decode_clk);
            #1; if(S_discard[slot]!==discarded) fail("byte identity/discard");
            @(negedge S_decode_clk); S_byte_valid[slot]=0;
        end
    endtask
    task automatic send_file;
        input integer slot;
        integer k;
        begin
            for(k=0;k<S_length[slot];k=k+1) begin
                // A recycle abort makes all remaining bytes idle discards.
                @(negedge S_decode_clk); S_byte_valid[slot]=1; S_last[slot]=k==S_length[slot]-1;
                S_bytes[slot*8+:8]=S_file[slot*2048+k]; S_byte_epoch[slot*16+:16]=S_expected_epoch[slot];
                @(posedge S_decode_clk); while(!S_byte_ready[slot]) @(posedge S_decode_clk);
                @(negedge S_decode_clk); S_byte_valid[slot]=0;
            end
            S_sender_done[slot]=1;
        end
    endtask
    task fade_to;
        input target;
        begin
            @(negedge S_audio_clk); S_target=target; S_fade=1;
            @(posedge S_audio_clk); while(!S_fade_ready) @(posedge S_audio_clk);
            @(negedge S_audio_clk); S_fade=0;
            wait(S_fade_done); #1; if(S_active!==target) fail("fade endpoint");
        end
    endtask
    task recycle;
        input integer slot;
        begin
            wait(S_recycle_ready[slot]); @(negedge S_decode_clk); S_recycle[slot]=1;
            @(negedge S_decode_clk); S_recycle[slot]=0;
        end
    endtask

    // Test file owner: retired only after every old byte has really returned.
    always @(negedge S_decode_clk) begin
        if(S_reset) begin S_retired=0; S_retire_delay[0]=0; S_retire_delay[1]=0; end
        else for(S_i=0;S_i<2;S_i=S_i+1) begin
            if(!S_retire[S_i]) begin S_retired[S_i]=0; S_retire_delay[S_i]=0; end
            else if(S_sender_done[S_i]) begin
                if(S_retire_delay[S_i]==20) S_retired[S_i]=1;
                else S_retire_delay[S_i]=S_retire_delay[S_i]+1;
            end
        end
    end
    always @(posedge S_decode_clk) begin
        #1;
        if(S_recycle_done[0]) S_recycles=S_recycles+1;
        if(S_recycle_done[1]) S_recycles=S_recycles+1;
    end
    always @(negedge S_audio_clk) begin
        if(S_reset) begin S_tick=0; S_tick_count=0; end
        else begin S_tick_count=S_tick_count+1; S_tick=S_tick_count%8==0; end
    end
    // Independent byte-derived frame order, full-scale steady output and cadence.
    always @(posedge S_audio_clk) begin
        if(S_reset) begin S_valid_pipe=0; S_check_pipe=0; end
        else begin
            S_valid_pipe={S_valid_pipe[3:0],S_tick};
            S_check_pipe={S_check_pipe[3:0],1'b0};
            for(S_j=4;S_j>0;S_j=S_j-1) begin
                S_left_pipe[S_j]=S_left_pipe[S_j-1]; S_right_pipe[S_j]=S_right_pipe[S_j-1];
            end
            for(S_j=0;S_j<2;S_j=S_j+1) begin
                if(u_dut.S_clear[S_j]) begin
                    S_received[S_j]=0; S_headers[S_j]=0; S_terminals[S_j]=0; S_event_held[S_j]=0;
                    S_gain_consumed[S_j]=0;
                end else begin
                    if(S_guard_reset[S_j]) S_gain_consumed[S_j]=0;
                    if(S_event_held[S_j] && (!S_event_valid[S_j] ||
                        {S_event_header[S_j],S_event_epoch[S_j*16+:16],S_event_total[S_j*32+:32],
                        S_event_written[S_j*32+:32],S_event_error[S_j*4+:4]}!==S_held[S_j]))
                        fail("event changed while waiting");
                    S_event_held[S_j]=S_event_valid[S_j] && !S_event_ready[S_j];
                    S_held[S_j]={S_event_header[S_j],S_event_epoch[S_j*16+:16],S_event_total[S_j*32+:32],
                        S_event_written[S_j*32+:32],S_event_error[S_j*4+:4]};
                    if(S_event_valid[S_j] && S_event_ready[S_j]) begin
                        if(S_event_epoch[S_j*16+:16]!==S_expected_epoch[S_j] ||
                            S_event_total[S_j*32+:32]!=S_frames[S_j]) fail("event epoch/frame total");
                        if(S_event_header[S_j]) begin
                            S_headers[S_j]=S_headers[S_j]+1;
                            if(S_headers[S_j]!=1 || S_terminals[S_j]!=0) fail("header order");
                        end else begin
                            S_terminals[S_j]=S_terminals[S_j]+1;
                            if(S_terminals[S_j]!=1) fail("duplicate terminal");
                            if(S_event_error[S_j*4+:4]!=0 && S_event_error[S_j*4+:4]!=6)
                                fail("unexpected terminal error");
                            if(S_event_error[S_j*4+:4]==0 && S_event_written[S_j*32+:32]!=S_frames[S_j])
                                fail("success before all frames written");
                        end
                    end
                    if(u_dut.S_pcm_valid[S_j] && u_dut.S_pcm_ready[S_j]) begin
                        if(u_dut.S_left[S_j*24+:24]!=={sample(S_j,S_received[S_j]),8'd0} ||
                            u_dut.S_right[S_j*24+:24]!=={~sample(S_j,S_received[S_j]),8'd0})
                            fail("PCM old slot/order/channel contamination");
                        if(S_next[S_j*32+:32]!=S_received[S_j]) fail("absolute consumed index");
                        if(S_j==S_active && !S_busy && !S_fade && !S_pause_busy &&
                            S_gain_consumed[S_j]>=80 && !S_stopping[S_j]) begin
                            S_check_pipe[0]=1;
                            S_left_pipe[0]=u_dut.S_left[S_j*24+:24];
                            S_right_pipe[0]=u_dut.S_right[S_j*24+:24];
                        end
                        S_received[S_j]=S_received[S_j]+1;
                        S_gain_consumed[S_j]=S_gain_consumed[S_j]+1;
                    end
                end
            end
            #1;
            if(S_valid!==S_valid_pipe[4]) fail("sample valid cadence");
            if(S_check_pipe[4]) begin
                if(!S_valid || S_left!==S_left_pipe[4] || S_right!==S_right_pipe[4]) fail("steady PCM output");
                S_checks=S_checks+1;
            end
            if(S_valid) S_samples=S_samples+1;
            if(|S_under) fail("unexpected underrun with fast producers");
        end
    end

    initial begin
        for(S_j=0;S_j<2;S_j=S_j+1) begin
            S_received[S_j]=0; S_headers[S_j]=0; S_terminals[S_j]=0;
            S_gain_consumed[S_j]=0;
            S_expected_epoch[S_j]=0; S_frames[S_j]=0;
        end
        #101; S_reset=0;
        wait(&S_available);
        begin_file(0,180,16'h0101,16'h1200);
        begin_file(1,180,16'h0201,16'ha100);
        fork
            send_file(0);
            send_file(1);
            begin
                // play was already held before either header existed.
                wait(&S_event_valid);
                repeat(20) @(negedge S_audio_clk);
                S_event_ready=3;
                wait(S_enabled[0]); @(negedge S_audio_clk); S_play=0;
                wait(S_next[31:0]>=90 && S_loaded[1]);
                fade_to(1);
                recycle(0);
                wait(S_cancel[0]);
                repeat(30) @(negedge S_decode_clk);
                if(S_recycle_done[0] || !S_loaded[0] || S_start_ready[0]) fail("cancel acceptance confused with retirement");
                S_cancel_ready=3;
                wait(S_recycle_done[0]);
                if(!S_loaded[1] || !S_enabled[1]) fail("A flush disturbed B");
                begin_file(0,160,16'h0301,16'h3400);
                send_byte(0,8'hff,1,16'h0101,1);
                fork
                    send_file(0);
                    begin
                        wait(S_loaded[0] && S_next[63:32]>=100);
                        fade_to(0);
                        @(negedge S_audio_clk); S_pause=1;
                        wait(S_paused);
                        // Active guard is frozen in PLAY: stop must still fade it.
                        recycle(0);
                        wait(S_recycle_done[0]);
                        if(!S_paused || S_loaded[0] || !S_loaded[1]) fail("paused slot recycle isolation");
                        @(negedge S_audio_clk); S_pause=0;
                        wait(!S_pause_busy);
                        fade_to(1);
                        wait(S_end[1]);
                    end
                join
            end
        join
        wait(S_terminals[1]==1);
        repeat(30) @(negedge S_audio_clk);
        if(S_received[1]!=180 || S_recycles!=2 || S_checks<5 || S_samples<200)
            fail("missing integration coverage");
        S_test_pass=1;
        $display("PASS: WAV dual slots, metadata, PCM, fades, retirement, reuse and paused recycle");
        $finish;
    end
    initial begin #5000000; fail("WAV audio integration timeout"); end
endmodule
