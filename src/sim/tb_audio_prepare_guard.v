`timescale 1ns/1ps
// Real WAV/parser/PCM/event FIFOs/playback/recycle. Byte and I/O peers are explicit fixtures.
// The independent apply pulse is a registered display peer; the integration TB uses real apply.
module tb_audio_prepare_guard;
    wire S_silence_u_prepared_O_started;
    wire S_silence_u_prepared_O_silence_ready;
    wire S_silence_u_prepared_O_silence_started;
    wire S_silence_u_prepared_O_silence_done;
    reg S_decode_clk=0,S_audio_clk=0,S_decode_run=1,S_audio_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_decode_run) S_decode_clk=~S_decode_clk;
    always #20 if(S_audio_run) S_audio_clk=~S_audio_clk;
    reg S_tick_run=0;
    integer S_tick_phase=0,S_case=0,S_accepts=0;
    reg [7:0] S_file[0:2047];
    integer S_lengths[0:1];
    reg [15:0] S_epochs[0:1];
    reg [31:0] S_saved_serial=0,S_saved_index=0;
    reg [1:0] S_d_I_start_valid=0;
    wire [1:0] S_d_O_start_ready;
    reg [63:0] S_d_I_file_size=0;
    reg [31:0] S_d_I_epoch=0;
    reg [1:0] S_d_I_byte_valid=0;
    reg [1:0] S_d_I_byte_last=0;
    reg [15:0] S_d_I_byte_data=0;
    reg [31:0] S_d_I_byte_epoch=0;
    wire [1:0] S_d_O_byte_ready;
    wire [1:0] S_d_O_byte_discarded;
    reg [1:0] S_d_I_stream_error_valid=0;
    reg [31:0] S_d_I_stream_error_epoch=0;
    reg [1:0] S_d_I_recycle_valid=0;
    wire [1:0] S_d_O_recycle_ready;
    wire [1:0] S_d_O_recycle_done;
    wire [1:0] S_d_O_available;
    wire [1:0] S_d_O_cancel_valid;
    reg [1:0] S_d_I_cancel_ready=0;
    wire [31:0] S_d_O_cancel_epoch;
    wire [1:0] S_d_O_io_retire_request;
    reg [1:0] S_d_I_io_retired=0;
    wire [1:0] S_d_O_source_busy;
    wire [63:0] S_d_O_written_frames;
    reg S_d_I_sample_tick=0;
    reg S_d_I_play_valid=0;
    wire S_d_O_play_ready;
    reg S_d_I_fade_valid=0;
    reg S_d_I_target_b=0;
    wire S_d_O_fade_ready;
    reg S_d_I_pause=0;
    reg S_d_I_pause_allow=0;
    wire S_d_O_paused;
    wire S_d_O_pause_busy;
    reg [4:0] S_d_I_volume=0;
    reg S_d_I_mute=0;
    reg S_d_I_prompt_valid=0;
    reg [23:0] S_d_I_prompt_left=0;
    reg [23:0] S_d_I_prompt_right=0;
    wire S_d_O_sample_valid;
    wire [23:0] S_d_O_left;
    wire [23:0] S_d_O_right;
    wire S_d_O_clipped;
    wire S_d_O_fade_done;
    wire S_d_O_active_b;
    wire S_d_O_busy;
    wire [1:0] S_d_O_loaded;
    wire [1:0] S_d_O_enabled;
    wire [1:0] S_d_O_end;
    wire [1:0] S_d_O_consumed;
    wire [1:0] S_d_O_underrun;
    wire [1:0] S_d_O_release;
    wire [63:0] S_d_O_next_index;
    wire [1:0] S_d_O_need_fill;
    wire [1:0] S_d_O_failed;
    wire [1:0] S_d_O_slot_stopping;
    wire [1:0] S_d_O_event_valid;
    reg [1:0] S_d_I_event_ready=0;
    wire [1:0] S_d_O_event_header;
    wire [31:0] S_d_O_event_epoch;
    wire [63:0] S_d_O_event_total_frames;
    wire [63:0] S_d_O_event_written_frames;
    wire [7:0] S_d_O_event_error;
    reg S_d_I_bind_valid=0;
    wire S_d_O_bind_ready;
    reg [31:0] S_d_I_bind_display_epoch=0;
    reg [15:0] S_d_I_bind_display_tag=0;
    reg S_d_I_bind_slot=0;
    reg [15:0] S_d_I_bind_track_epoch=0;
    reg [31:0] S_d_I_bind_track_serial=0;
    reg [31:0] S_d_I_bind_start_index=0;
    reg S_d_I_bind_reuse_active=0;
    reg S_d_I_unbind=0;
    reg S_d_I_bind_abort=0;
    reg S_d_I_pending_valid=0;
    reg [31:0] S_d_I_pending_epoch=0;
    reg [15:0] S_d_I_pending_tag=0;
    reg S_d_I_display_audio_applied=0;
    wire S_d_O_audio_ready;
    wire [31:0] S_d_O_audio_epoch;
    wire [1:0] S_d_O_track_known;
    wire [31:0] S_d_O_track_epochs;
    wire [63:0] S_d_O_track_serials;
    wire [63:0] S_d_O_track_totals;
    wire S_d_O_bound;
    wire S_d_O_binding_revoked;
    wire [3:0] S_d_O_bind_error;
    wire S_d_O_audio_accepted;
    wire [31:0] S_d_O_audio_accepted_epoch;
    wire [15:0] S_d_O_audio_accepted_tag;
    wire S_d_O_prepare_contract_fault;
    wire S_d_O_prepare_quarantined;
    wire S_d_O_prepare_response_discarded;
    always @(negedge S_audio_clk) begin
        if(S_reset || !S_tick_run) begin S_tick_phase=0; S_d_I_sample_tick=0; end
        else begin S_d_I_sample_tick=S_tick_phase==9; S_tick_phase=S_tick_phase==9 ? 0 : S_tick_phase+1; end
    end
    // This byte fixture has no outstanding file obligations after the full file is sent.
    always @(posedge S_decode_clk) begin
        if(S_reset) S_d_I_io_retired<=0;
        else S_d_I_io_retired<=S_d_O_io_retire_request;
    end
    wav_audio_prepared #(.FIFO_ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4),.FADE_SAMPLES(7)) u_prepared (
        .I_decode_clk(S_decode_clk),
        .I_audio_clk(S_audio_clk),
        .I_async_reset(S_reset),
        .I_start_valid(S_d_I_start_valid),
        .O_start_ready(S_d_O_start_ready),
        .I_file_size(S_d_I_file_size),
        .I_epoch(S_d_I_epoch),
        .I_byte_valid(S_d_I_byte_valid),
        .I_byte_last(S_d_I_byte_last),
        .I_byte_data(S_d_I_byte_data),
        .I_byte_epoch(S_d_I_byte_epoch),
        .O_byte_ready(S_d_O_byte_ready),
        .O_byte_discarded(S_d_O_byte_discarded),
        .I_stream_error_valid(S_d_I_stream_error_valid),
        .I_stream_error_epoch(S_d_I_stream_error_epoch),
        .I_recycle_valid(S_d_I_recycle_valid),
        .O_recycle_ready(S_d_O_recycle_ready),
        .O_recycle_done(S_d_O_recycle_done),
        .O_available(S_d_O_available),
        .O_cancel_valid(S_d_O_cancel_valid),
        .I_cancel_ready(S_d_I_cancel_ready),
        .O_cancel_epoch(S_d_O_cancel_epoch),
        .O_io_retire_request(S_d_O_io_retire_request),
        .I_io_retired(S_d_I_io_retired),
        .O_source_busy(S_d_O_source_busy),
        .O_written_frames(S_d_O_written_frames),
        .I_sample_tick(S_d_I_sample_tick),
        .I_play_valid(S_d_I_play_valid),
        .O_play_ready(S_d_O_play_ready),
        .I_fade_valid(S_d_I_fade_valid),
        .I_target_b(S_d_I_target_b),
        .O_fade_ready(S_d_O_fade_ready),
        .I_pause(S_d_I_pause),
        .I_pause_allow(S_d_I_pause_allow),
        .O_paused(S_d_O_paused),
        .O_pause_busy(S_d_O_pause_busy),
        .I_volume(S_d_I_volume),
        .I_mute(S_d_I_mute),
        .I_prompt_valid(S_d_I_prompt_valid),
        .I_prompt_left(S_d_I_prompt_left),
        .I_prompt_right(S_d_I_prompt_right),
        .O_sample_valid(S_d_O_sample_valid),
        .O_left(S_d_O_left),
        .O_right(S_d_O_right),
        .O_clipped(S_d_O_clipped),
        .O_fade_done(S_d_O_fade_done),
        .O_active_b(S_d_O_active_b),
        .O_busy(S_d_O_busy),
        .O_loaded(S_d_O_loaded),
        .O_enabled(S_d_O_enabled),
        .O_end(S_d_O_end),
        .O_consumed(S_d_O_consumed),
        .O_underrun(S_d_O_underrun),
        .O_release(S_d_O_release),
        .O_next_index(S_d_O_next_index),
        .O_need_fill(S_d_O_need_fill),
        .O_failed(S_d_O_failed),
        .O_slot_stopping(S_d_O_slot_stopping),
        .O_event_valid(S_d_O_event_valid),
        .I_event_ready(S_d_I_event_ready),
        .O_event_header(S_d_O_event_header),
        .O_event_epoch(S_d_O_event_epoch),
        .O_event_total_frames(S_d_O_event_total_frames),
        .O_event_written_frames(S_d_O_event_written_frames),
        .O_event_error(S_d_O_event_error),
        .I_bind_valid(S_d_I_bind_valid),
        .O_bind_ready(S_d_O_bind_ready),
        .I_bind_display_epoch(S_d_I_bind_display_epoch),
        .I_bind_display_tag(S_d_I_bind_display_tag),
        .I_bind_slot(S_d_I_bind_slot),
        .I_bind_track_epoch(S_d_I_bind_track_epoch),
        .I_bind_track_serial(S_d_I_bind_track_serial),
        .I_bind_start_index(S_d_I_bind_start_index),
        .I_bind_reuse_active(S_d_I_bind_reuse_active),
        .I_unbind(S_d_I_unbind),
        .I_bind_abort(S_d_I_bind_abort),
        .I_pending_valid(S_d_I_pending_valid),
        .I_pending_epoch(S_d_I_pending_epoch),
        .I_pending_tag(S_d_I_pending_tag),
        .I_display_audio_applied(S_d_I_display_audio_applied),
        .O_audio_ready(S_d_O_audio_ready),
        .O_audio_epoch(S_d_O_audio_epoch),
        .O_track_known(S_d_O_track_known),
        .O_track_epochs(S_d_O_track_epochs),
        .O_track_serials(S_d_O_track_serials),
        .O_track_totals(S_d_O_track_totals),
        .O_bound(S_d_O_bound),
        .O_binding_revoked(S_d_O_binding_revoked),
        .O_bind_error(S_d_O_bind_error),
        .O_audio_accepted(S_d_O_audio_accepted),
        .O_audio_accepted_epoch(S_d_O_audio_accepted_epoch),
        .O_audio_accepted_tag(S_d_O_audio_accepted_tag),
        .O_prepare_contract_fault(S_d_O_prepare_contract_fault),
        .O_prepare_quarantined(S_d_O_prepare_quarantined),
        .O_prepare_response_discarded(S_d_O_prepare_response_discarded),
        .I_silence_valid(1'b0),
        .O_silence_ready(S_silence_u_prepared_O_silence_ready),
        .O_silence_started(S_silence_u_prepared_O_silence_started),
        .O_silence_done(S_silence_u_prepared_O_silence_done),
        .O_started(S_silence_u_prepared_O_started),
        .I_start_index(64'd0)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: audio preparation case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #300000000; fail("watchdog timeout"); end
    always @(posedge S_audio_clk) begin
        if(!S_reset && S_d_O_audio_ready && (!S_d_O_bound || S_d_O_binding_revoked ||
            S_d_O_audio_epoch!==S_d_I_pending_epoch || S_d_O_prepare_quarantined))
            fail("proof escaped current binding/pending identity");
        #1; if(!S_reset && S_d_O_audio_accepted) S_accepts=S_accepts+1;
    end
    task reset_all;
        begin
            S_decode_run=1; S_audio_run=1; S_reset=1; S_tick_run=0;
            S_d_I_start_valid=0; S_d_I_byte_valid=0; S_d_I_byte_last=0; S_d_I_recycle_valid=0;
            S_d_I_stream_error_valid=0; S_d_I_play_valid=0; S_d_I_fade_valid=0;
            S_d_I_pause=0; S_d_I_pause_allow=1; S_d_I_volume=16;
            S_d_I_cancel_ready=3; S_d_I_event_ready=3;
            S_d_I_bind_valid=0; S_d_I_unbind=0; S_d_I_bind_abort=0;
            S_d_I_bind_display_epoch=10; S_d_I_bind_display_tag=16'hbeef;
            S_d_I_bind_start_index=0; S_d_I_bind_reuse_active=0;
            S_d_I_pending_valid=1; S_d_I_pending_epoch=10; S_d_I_pending_tag=16'hbeef;
            S_d_I_display_audio_applied=0;
            repeat(8) @(negedge S_audio_clk); S_reset=0;
            wait(S_d_O_available==3); repeat(4) @(negedge S_audio_clk); S_accepts=0;
        end
    endtask
    task put32;
        input integer address,value;
        begin S_file[address]=value; S_file[address+1]=value>>8;
            S_file[address+2]=value>>16; S_file[address+3]=value>>24; end
    endtask
    task open_file;
        input integer slot,frames,bad_tail;
        input [15:0] epoch;
        integer base,k;
        begin
            base=slot*1024; S_lengths[slot]=44+4*frames+8*bad_tail; S_epochs[slot]=epoch;
            for(k=0;k<1024;k=k+1) S_file[base+k]=0;
            S_file[base]="R"; S_file[base+1]="I"; S_file[base+2]="F"; S_file[base+3]="F";
            put32(base+4,S_lengths[slot]-8);
            S_file[base+8]="W"; S_file[base+9]="A"; S_file[base+10]="V"; S_file[base+11]="E";
            S_file[base+12]="f"; S_file[base+13]="m"; S_file[base+14]="t"; S_file[base+15]=" ";
            put32(base+16,16); S_file[base+20]=1; S_file[base+22]=2;
            put32(base+24,48000); put32(base+28,192000); S_file[base+32]=4; S_file[base+34]=16;
            S_file[base+36]="d"; S_file[base+37]="a"; S_file[base+38]="t"; S_file[base+39]="a";
            put32(base+40,4*frames);
            for(k=0;k<4*frames;k=k+1) S_file[base+44+k]=k+17;
            if(bad_tail!=0) begin
                S_file[base+44+4*frames]="d"; S_file[base+45+4*frames]="a";
                S_file[base+46+4*frames]="t"; S_file[base+47+4*frames]="a";
            end
            wait(S_d_O_start_ready[slot]); @(negedge S_decode_clk);
            S_d_I_file_size[slot*32+:32]=S_lengths[slot]; S_d_I_epoch[slot*16+:16]=epoch; S_d_I_start_valid[slot]=1;
            @(posedge S_decode_clk); while(!S_d_O_start_ready[slot]) @(posedge S_decode_clk);
            @(negedge S_decode_clk); S_d_I_start_valid[slot]=0;
        end
    endtask
    task send_range;
        input integer slot,first,limit;
        integer k;
        begin
            for(k=first;k<limit;k=k+1) begin
                @(negedge S_decode_clk); S_d_I_byte_valid[slot]=1;
                S_d_I_byte_data[slot*8+:8]=S_file[slot*1024+k];
                S_d_I_byte_epoch[slot*16+:16]=S_epochs[slot]; S_d_I_byte_last[slot]=k==S_lengths[slot]-1;
                @(posedge S_decode_clk); while(!S_d_O_byte_ready[slot]) @(posedge S_decode_clk);
                @(negedge S_decode_clk); S_d_I_byte_valid[slot]=0;
            end
        end
    endtask
    task bind_track;
        input slot,reuse_active;
        input [31:0] serial,index;
        input [3:0] error;
        begin
            @(negedge S_audio_clk); S_d_I_bind_slot=slot; S_d_I_bind_reuse_active=reuse_active;
            S_d_I_bind_track_epoch=S_epochs[slot]; S_d_I_bind_track_serial=serial;
            S_d_I_bind_start_index=index; S_d_I_bind_valid=1;
            @(posedge S_audio_clk); while(!S_d_O_bind_ready) @(posedge S_audio_clk);
            #1; if(S_d_O_bind_error!==error || (error!=0 && S_d_O_bound)) fail("bind error/occupancy result");
            @(negedge S_audio_clk); S_d_I_bind_valid=0;
        end
    endtask
    task unbind;
        begin @(negedge S_audio_clk); S_d_I_unbind=1;
            @(negedge S_audio_clk); S_d_I_unbind=0; if(S_d_O_bound) fail("unbind did not release binding"); end
    endtask
    task recycle;
        input integer slot;
        begin
            @(negedge S_decode_clk); S_d_I_recycle_valid[slot]=1;
            @(posedge S_decode_clk); while(!S_d_O_recycle_ready[slot]) @(posedge S_decode_clk);
            @(negedge S_decode_clk); S_d_I_recycle_valid[slot]=0;
            wait(S_d_O_recycle_done[slot]); @(negedge S_decode_clk);
        end
    endtask
    task load_full;
        input integer slot,frames;
        input [15:0] epoch;
        begin open_file(slot,frames,0,epoch); send_range(slot,0,S_lengths[slot]);
            wait(S_d_O_track_known[slot]); repeat(12) @(negedge S_audio_clk); end
    endtask
    initial begin
        S_case=1; reset_all;
        bind_track(0,0,0,0,1);
        if(S_d_O_audio_ready) fail("no real header/PCM but proof asserted");

        S_case=2; reset_all; open_file(0,12,0,16'hab12); send_range(0,0,72);
        wait(S_d_O_track_known[0] && u_prepared.S_level[4:0]==7);
        if(S_d_O_track_epochs[15:0]!=16'hab12 || S_d_O_track_serials[31:0]!=1) fail("full audio epoch or initial lifetime serial");
        bind_track(0,0,1,0,0);
        repeat(8) begin @(negedge S_audio_clk); if(S_d_O_audio_ready) fail("insufficient real prefill granted proof"); end
        send_range(0,72,76); wait(S_d_O_audio_ready);
        send_range(0,76,S_lengths[0]);

        S_case=3; reset_all; open_file(0,3,0,16'h2244); send_range(0,0,52);
        wait(S_d_O_track_known[0] && u_prepared.S_level[4:0]==2); bind_track(0,0,1,0,0);
        if(S_d_O_audio_ready) fail("partial short tail mistaken for fully visible PCM");
        send_range(0,52,S_lengths[0]); wait(S_d_O_audio_ready);
        if(u_prepared.S_prefilled[0] || u_prepared.S_level[4:0]!=3) fail("short-tail proof did not use actual conservative read level");

        S_case=4; reset_all; load_full(0,0,16'h8001); bind_track(0,0,1,0,0);
        if(!S_d_O_audio_ready || u_prepared.S_pcm_valid[0] || !S_d_O_end[0]) fail("legal empty WAV required fabricated PCM");

        S_case=5; reset_all; S_d_I_event_ready=0; open_file(0,3,0,16'h5566); send_range(0,0,S_lengths[0]);
        wait(S_d_O_loaded[0]); repeat(10) @(negedge S_audio_clk);
        if(S_d_O_track_known[0]) fail("unconsumed header created track identity");
        bind_track(0,0,1,0,3); S_d_I_event_ready=3; wait(S_d_O_track_known[0]); bind_track(0,0,1,0,0);
        wait(S_d_O_audio_ready);

        S_case=6; @(negedge S_audio_clk); S_d_I_pending_tag=16'hbeee;
        if(S_d_O_audio_ready) begin #1; if(S_d_O_audio_ready) fail("wrong display tag retained proof"); end
        repeat(2) @(negedge S_audio_clk); S_d_I_pending_tag=16'hbeef;
        if(!S_d_O_binding_revoked || S_d_O_audio_ready) fail("restored pending identity revived revoked binding");
        unbind; bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);

        S_case=7; reset_all; load_full(0,12,16'h1234); bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);
        S_tick_run=1; @(negedge S_audio_clk); S_d_I_play_valid=1;
        @(posedge S_audio_clk); while(!S_d_O_play_ready) @(posedge S_audio_clk);
        @(negedge S_audio_clk); S_d_I_play_valid=0;
        wait(S_d_O_next_index[31:0]>=2);
        if(!S_d_O_binding_revoked || S_d_O_audio_ready) fail("fresh position moved without sticky proof revocation");
        unbind; bind_track(0,1,1,0,0); wait(S_d_O_audio_ready); S_saved_index=S_d_O_next_index[31:0];
        wait(S_d_O_next_index[31:0]>S_saved_index);
        if(!S_d_O_audio_ready || S_d_O_binding_revoked) fail("same active background track was restarted or required re-prefill");

        S_case=8; @(negedge S_audio_clk); S_d_I_pause=1; #1;
        if(S_d_O_audio_ready) fail("pause busy retained apply permission");
        wait(S_d_O_paused); if(S_d_O_binding_revoked) fail("pause destroyed valid active identity");
        @(negedge S_audio_clk); S_d_I_pause=0; wait(!S_d_O_pause_busy); wait(S_d_O_audio_ready);

        S_case=9; recycle(1);
        if(!S_d_O_audio_ready || S_d_O_binding_revoked) fail("other slot recycle revoked active background proof");

        S_case=10; reset_all; load_full(0,3,16'haaaa); S_saved_serial=S_d_O_track_serials[31:0];
        recycle(0); load_full(0,3,16'haaaa);
        if(S_d_O_track_serials[31:0]!=S_saved_serial+1) fail("local flush reused old lifetime serial");
        bind_track(0,0,S_saved_serial,0,3); bind_track(0,0,S_saved_serial+1,0,0); wait(S_d_O_audio_ready);

        S_case=11; @(negedge S_audio_clk); S_d_I_bind_abort=1; #1;
        if(S_d_O_audio_ready) fail("abort retained audio proof");
        repeat(2) @(negedge S_audio_clk); S_d_I_bind_abort=0;
        if(!S_d_O_binding_revoked || S_d_O_audio_ready) fail("abort clear resurrected old binding");

        S_case=12; reset_all; open_file(0,8,1,16'hcccc); send_range(0,0,76);
        wait(S_d_O_track_known[0]); bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);
        S_d_I_event_ready=0; send_range(0,76,S_lengths[0]); wait(S_d_O_failed[0]);
        repeat(3) @(negedge S_audio_clk);
        if(S_d_O_audio_ready || !S_d_O_binding_revoked || S_d_O_prepare_quarantined)
            fail("late real parser error did not revoke proof independently of external event backpressure");
        S_d_I_event_ready=3;

        S_case=13; reset_all; load_full(0,3,16'hdddd); bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);
        @(negedge S_audio_clk); S_d_I_pending_valid=0; S_d_I_display_audio_applied=1;
        @(posedge S_audio_clk); #1;
        if(!S_d_O_audio_accepted || S_d_O_audio_accepted_epoch!=10 || S_d_O_audio_accepted_tag!=16'hbeef ||
            S_d_O_bound || S_d_O_prepare_quarantined) fail("registered display apply lost preceding-edge readiness proof");
        @(negedge S_audio_clk); S_d_I_display_audio_applied=0;

        S_case=14; reset_all; load_full(0,3,16'heeee); bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);
        @(negedge S_decode_clk); S_decode_run=0;
        repeat(20) begin @(negedge S_audio_clk); if(!S_d_O_audio_ready || S_d_O_audio_accepted)
            fail("decode clock stop changed already visible proof or fabricated apply"); end
        S_decode_run=1; @(negedge S_audio_clk); S_audio_run=0; S_d_I_pending_epoch=11;
        repeat(20) begin @(negedge S_decode_clk); if(S_d_O_audio_ready || S_d_O_audio_accepted)
            fail("audio clock stop fabricated pending acceptance"); end
        S_audio_run=1; repeat(3) @(negedge S_audio_clk); S_d_I_pending_epoch=10;
        if(!S_d_O_binding_revoked || S_d_O_audio_ready) fail("clock recovery resurrected replaced pending binding");

        S_case=15; reset_all;
        // Fault injection at a genuine new header, not a fake source completion.
        @(negedge S_audio_clk); u_prepared.u_prepare_guard.S_track_serials[31:0]=32'hffffffff;
        open_file(0,0,0,16'hffff); send_range(0,0,S_lengths[0]); wait(S_d_O_prepare_quarantined);
        if(!S_d_O_prepare_contract_fault || S_d_O_track_known!=0 || S_d_O_bind_ready) fail("lifetime exhaustion wrapped or retained permission");

        S_case=16; reset_all; open_file(0,12,0,16'h1111); send_range(0,0,48); wait(S_d_O_track_known[0]);
        bind_track(0,0,1,0,0); repeat(3) @(negedge S_audio_clk);
        S_d_I_display_audio_applied=1; @(negedge S_audio_clk); S_d_I_display_audio_applied=0;
        if(!S_d_O_prepare_quarantined || !S_d_O_prepare_contract_fault || S_d_O_audio_accepted)
            fail("display audio apply without preceding proof was accepted");

        S_case=17; reset_all; load_full(0,3,16'h2222); bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);
        recycle(0);
        if(!S_d_O_binding_revoked || S_d_O_audio_ready || S_d_O_track_known[0]) fail("selected recycle retained proof before or after flush");
        if(S_d_O_prepare_quarantined) fail("ordinary selected recycle became contract isolation");
        S_case=18; reset_all; load_full(1,3,16'hab12);
        S_epochs[1]=16'hbc12; bind_track(1,0,1,0,3); S_epochs[1]=16'hab12;
        bind_track(1,0,1,0,0); wait(S_d_O_audio_ready);
        if(S_d_O_track_serials[31:0]!=0 || S_d_O_track_serials[63:32]!=1 ||
            S_d_O_track_epochs[31:16]!=16'hab12) fail("B slot proof aliased A or truncated the upper epoch byte");
        recycle(0);
        if(!S_d_O_audio_ready || S_d_O_binding_revoked) fail("A recycle damaged fresh B proof");

        S_case=19; reset_all; load_full(0,3,16'h5555);
        S_d_I_bind_display_epoch=11; bind_track(0,0,1,0,2); S_d_I_bind_display_epoch=10;
        bind_track(0,0,1,1,4); bind_track(0,1,1,0,4);
        bind_track(0,0,1,0,0); wait(S_d_O_audio_ready);
        if(S_d_O_prepare_quarantined) fail("rejected bind configuration became global protocol isolation");

        S_case=20; reset_all; open_file(0,3,0,16'h6666); send_range(0,0,44); wait(S_d_O_track_known[0]);
        S_d_I_event_ready=0; send_range(0,44,S_lengths[0]);
        wait(S_d_O_event_valid[0] && !S_d_O_event_header[0]);
        @(negedge S_audio_clk); force u_prepared.u_prepare_guard.I_event_epoch=32'h00009999;
        S_d_I_event_ready=3; @(negedge S_audio_clk); release u_prepared.u_prepare_guard.I_event_epoch;
        if(!S_d_O_prepare_quarantined || !S_d_O_prepare_contract_fault || S_d_O_track_known!=0)
            fail("wrong full terminal epoch was accepted as the current WAV transaction");

        $display("PASS: real WAV preparation, complete binding identities, lifetime safety, revocation and apply evidence");
        S_test_pass=1; $finish;
    end
endmodule
