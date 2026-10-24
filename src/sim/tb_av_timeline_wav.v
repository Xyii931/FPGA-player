`timescale 1ns/1ps
// Actual WAV/parser/PCM/playback/samp_tick and timeline. Video execution remains an explicit peer.
// Real video_timing and transition_plan validate frame-grid/plan readiness.
module tb_av_timeline_wav;
    wire S_silence_u_prepared_O_started;
    wire S_silence_u_timeline_O_silence_valid;
    wire S_silence_u_prepared_O_silence_ready;
    wire S_silence_u_prepared_O_silence_started;
    wire S_silence_u_prepared_O_silence_done;
    reg S_clk=0,S_run=1,S_reset=0,S_test_pass=0;
    always #20 if(S_run) S_clk=~S_clk;
    reg [31:0] S_time=0;
    wire S_tick;
    samp_tick u_tick (.I_clk(S_clk),.I_reset(S_reset),.O_sample_tick(S_tick));
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) S_time<=0;
        else S_time<=S_time+1'b1;
    end
    wire S_raster_frame;
    reg S_frame_gate=1;
    wire S_frame_start=S_raster_frame && S_frame_gate;
    video_timing u_timing (.I_clk(S_clk),.I_reset(S_reset),.O_hsync(),.O_vsync(),.O_de(),
        .O_x(),.O_y(),.O_frame_start(S_raster_frame),.O_line_start(),
        .O_raster_x(),.O_raster_y());
    integer S_case=0,S_requests=0,S_actual_frames=0,S_audio_commands=0;
    reg S_video_gate=1,S_audio_gate=1,S_apply_gate=1,S_stop_gate=1,S_ack_fall_gate=1,S_inject_wrong=0;
    reg [3:0] S_peer_error=0;
    reg S_peer_pending=0,S_peer_result_real=0;
    reg [31:0] S_peer_target=0;
    reg [15:0] S_peer_index=0;
    reg [31:0] S_command_epoch=0,S_saved_start=0,S_saved_mid=0,S_saved_audio=0;
    reg [143:0] S_held_offer=0;
    reg S_offer_held=0;
    reg S_d_I_clock_enable=0;
    reg S_d_I_start_valid=0;
    wire S_d_O_start_ready;
    reg [31:0] S_d_I_epoch=0;
    reg [15:0] S_d_I_tag=0;
    reg [2:0] S_d_I_effect=0;
    reg [15:0] S_d_I_duration_frames=0;
    reg signed [6:0] S_d_I_av_offset_steps=0;
    reg [1:0] S_d_I_audio_action=0;
    reg S_d_I_audio_slot=0;
    reg [15:0] S_d_I_track_epoch=0;
    reg [31:0] S_d_I_track_serial=0;
    reg [31:0] S_d_I_start_index=0;
    wire S_d_I_resources_ready;
    wire [1:0] S_d_I_track_known;
    wire [1:0] S_d_I_track_enabled;
    wire [1:0] S_d_I_track_consumed;
    wire [31:0] S_d_I_track_epochs;
    wire [63:0] S_d_I_track_serials;
    wire [63:0] S_d_I_track_totals;
    wire [63:0] S_d_I_track_next_index;
    reg S_d_I_pause=0;
    reg S_d_I_abort=0;
    wire S_d_O_pause_allow;
    wire S_d_O_video_valid;
    reg S_d_I_video_ready=0;
    wire S_d_O_video_cancel;
    wire [31:0] S_d_O_video_epoch;
    wire [15:0] S_d_O_video_tag;
    wire [2:0] S_d_O_video_effect;
    wire [15:0] S_d_O_video_frame_index;
    wire [16:0] S_d_O_video_progress;
    wire [31:0] S_d_O_video_target_time;
    reg S_d_I_video_done_valid=0;
    wire S_d_O_video_done_ready;
    reg [31:0] S_d_I_video_done_epoch=0;
    reg [15:0] S_d_I_video_done_tag=0;
    reg [15:0] S_d_I_video_done_frame_index=0;
    reg [3:0] S_d_I_video_done_error=0;
    reg S_d_I_video_done_applied=0;
    reg [31:0] S_d_I_video_done_time=0;
    wire S_d_O_play_valid;
    wire S_d_I_play_ready;
    wire S_d_O_fade_valid;
    wire S_d_O_target_b;
    wire [31:0] S_d_O_audio_target_time;
    wire S_d_I_fade_ready;
    wire S_d_I_fade_done;
    wire S_d_I_active_b;
    wire S_d_O_audio_stop_request;
    reg S_d_I_audio_stop_ack=0;
    wire S_d_O_busy;
    wire S_d_O_done_valid;
    reg S_d_I_done_ready=0;
    wire [3:0] S_d_O_error;
    wire [31:0] S_d_O_epoch;
    wire [15:0] S_d_O_tag;
    wire S_d_O_cancel_late;
    wire S_d_O_video_started;
    wire S_d_O_video_finished;
    wire S_d_O_audio_started;
    wire S_d_O_audio_finished;
    wire [31:0] S_d_O_planned_start;
    wire [31:0] S_d_O_planned_midpoint;
    wire [31:0] S_d_O_planned_audio;
    wire [31:0] S_d_O_actual_start;
    wire [31:0] S_d_O_actual_midpoint;
    wire [31:0] S_d_O_actual_audio;
    wire [31:0] S_d_O_actual_finish;
    wire [31:0] S_d_O_audio_command_time;
    wire [31:0] S_d_O_audio_start_index;
    wire signed [31:0] S_d_O_anchor_error;
    wire S_d_O_midpoint_seen;
    wire S_d_O_late;
    wire S_d_O_contract_fault;
    wire S_d_O_quarantined;
    wire S_d_O_response_discarded;
    reg [1:0] S_a_I_start_valid=0;
    wire [1:0] S_a_O_start_ready;
    reg [63:0] S_a_I_file_size=0;
    reg [31:0] S_a_I_epoch=0;
    reg [1:0] S_a_I_byte_valid=0;
    reg [1:0] S_a_I_byte_last=0;
    reg [15:0] S_a_I_byte_data=0;
    reg [31:0] S_a_I_byte_epoch=0;
    wire [1:0] S_a_O_byte_ready;
    wire [1:0] S_a_O_byte_discarded;
    reg [1:0] S_a_I_stream_error_valid=0;
    reg [31:0] S_a_I_stream_error_epoch=0;
    reg [1:0] S_a_I_recycle_valid=0;
    wire [1:0] S_a_O_recycle_ready;
    wire [1:0] S_a_O_recycle_done;
    wire [1:0] S_a_O_available;
    wire [1:0] S_a_O_cancel_valid;
    reg [1:0] S_a_I_cancel_ready=0;
    wire [31:0] S_a_O_cancel_epoch;
    wire [1:0] S_a_O_io_retire_request;
    reg [1:0] S_a_I_io_retired=0;
    wire [1:0] S_a_O_source_busy;
    wire [63:0] S_a_O_written_frames;
    wire S_a_O_play_ready;
    wire S_a_O_fade_ready;
    wire S_a_O_paused;
    wire S_a_O_pause_busy;
    reg [4:0] S_a_I_volume=0;
    reg S_a_I_mute=0;
    reg S_a_I_prompt_valid=0;
    reg [23:0] S_a_I_prompt_left=0;
    reg [23:0] S_a_I_prompt_right=0;
    wire S_a_O_sample_valid;
    wire [23:0] S_a_O_left;
    wire [23:0] S_a_O_right;
    wire S_a_O_clipped;
    wire S_a_O_fade_done;
    wire S_a_O_active_b;
    wire S_a_O_busy;
    wire [1:0] S_a_O_loaded;
    wire [1:0] S_a_O_enabled;
    wire [1:0] S_a_O_end;
    wire [1:0] S_a_O_consumed;
    wire [1:0] S_a_O_underrun;
    wire [1:0] S_a_O_release;
    wire [63:0] S_a_O_next_index;
    wire [1:0] S_a_O_need_fill;
    wire [1:0] S_a_O_failed;
    wire [1:0] S_a_O_slot_stopping;
    wire [1:0] S_a_O_event_valid;
    reg [1:0] S_a_I_event_ready=0;
    wire [1:0] S_a_O_event_header;
    wire [31:0] S_a_O_event_epoch;
    wire [63:0] S_a_O_event_total_frames;
    wire [63:0] S_a_O_event_written_frames;
    wire [7:0] S_a_O_event_error;
    reg S_a_I_bind_valid=0;
    wire S_a_O_bind_ready;
    reg [31:0] S_a_I_bind_display_epoch=0;
    reg [15:0] S_a_I_bind_display_tag=0;
    reg S_a_I_bind_slot=0;
    reg [15:0] S_a_I_bind_track_epoch=0;
    reg [31:0] S_a_I_bind_track_serial=0;
    reg [31:0] S_a_I_bind_start_index=0;
    reg S_a_I_bind_reuse_active=0;
    reg S_a_I_unbind=0;
    reg S_a_I_bind_abort=0;
    wire S_a_O_audio_ready;
    wire [31:0] S_a_O_audio_epoch;
    wire [1:0] S_a_O_track_known;
    wire [31:0] S_a_O_track_epochs;
    wire [63:0] S_a_O_track_serials;
    wire [63:0] S_a_O_track_totals;
    wire S_a_O_bound;
    wire S_a_O_binding_revoked;
    wire [3:0] S_a_O_bind_error;
    wire S_a_O_audio_accepted;
    wire [31:0] S_a_O_audio_accepted_epoch;
    wire [15:0] S_a_O_audio_accepted_tag;
    wire S_a_O_prepare_contract_fault;
    wire S_a_O_prepare_quarantined;
    wire S_a_O_prepare_response_discarded;
    reg S_decode_clk=0;
    always #4 S_decode_clk=~S_decode_clk;
    reg [7:0] S_file[0:2047];
    integer S_lengths[0:1];
    reg [15:0] S_epochs[0:1];
    integer S_real_commands=0,S_real_fades=0;
    reg [31:0] S_preserved_index=0;
    assign S_d_I_resources_ready=S_a_O_audio_ready && S_a_O_audio_epoch==S_d_O_epoch;
    assign S_d_I_track_known=S_a_O_track_known;
    assign S_d_I_track_epochs=S_a_O_track_epochs;
    assign S_d_I_track_serials=S_a_O_track_serials;
    assign S_d_I_track_totals=S_a_O_track_totals;
    assign S_d_I_track_enabled=S_a_O_enabled;
    assign S_d_I_track_consumed=S_a_O_consumed;
    assign S_d_I_track_next_index=S_a_O_next_index;
    assign S_d_I_play_ready=S_a_O_play_ready && S_audio_gate;
    assign S_d_I_fade_ready=S_a_O_fade_ready && S_audio_gate;
    assign S_d_I_fade_done=S_a_O_fade_done;
    assign S_d_I_active_b=S_a_O_active_b;
    always @(posedge S_decode_clk) begin
        if(S_reset) S_a_I_io_retired<=0;
        else S_a_I_io_retired<=S_a_O_io_retire_request;
    end
    always @(posedge S_clk) if(!S_reset) begin
        if((S_d_O_play_valid && S_d_I_play_ready) || (S_d_O_fade_valid && S_d_I_fade_ready))
            S_real_commands=S_real_commands+1;
        if(S_a_O_fade_done) S_real_fades=S_real_fades+1;
        if(S_a_O_prepare_quarantined || S_a_O_underrun!=0) fail("unexpected real WAV protocol failure or underrun");
    end
    wav_audio_prepared #(.FIFO_ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4),.FADE_SAMPLES(9600)) u_prepared (
        .I_decode_clk(S_decode_clk),
        .I_audio_clk(S_clk),
        .I_async_reset(S_reset),
        .I_start_valid(S_a_I_start_valid),
        .O_start_ready(S_a_O_start_ready),
        .I_file_size(S_a_I_file_size),
        .I_epoch(S_a_I_epoch),
        .I_byte_valid(S_a_I_byte_valid),
        .I_byte_last(S_a_I_byte_last),
        .I_byte_data(S_a_I_byte_data),
        .I_byte_epoch(S_a_I_byte_epoch),
        .O_byte_ready(S_a_O_byte_ready),
        .O_byte_discarded(S_a_O_byte_discarded),
        .I_stream_error_valid(S_a_I_stream_error_valid),
        .I_stream_error_epoch(S_a_I_stream_error_epoch),
        .I_recycle_valid(S_a_I_recycle_valid),
        .O_recycle_ready(S_a_O_recycle_ready),
        .O_recycle_done(S_a_O_recycle_done),
        .O_available(S_a_O_available),
        .O_cancel_valid(S_a_O_cancel_valid),
        .I_cancel_ready(S_a_I_cancel_ready),
        .O_cancel_epoch(S_a_O_cancel_epoch),
        .O_io_retire_request(S_a_O_io_retire_request),
        .I_io_retired(S_a_I_io_retired),
        .O_source_busy(S_a_O_source_busy),
        .O_written_frames(S_a_O_written_frames),
        .I_sample_tick(S_tick),
        .I_play_valid(S_d_O_play_valid && S_audio_gate),
        .O_play_ready(S_a_O_play_ready),
        .I_fade_valid(S_d_O_fade_valid && S_audio_gate),
        .I_target_b(S_d_O_target_b),
        .O_fade_ready(S_a_O_fade_ready),
        .I_pause(S_d_I_pause && S_d_O_pause_allow),
        .I_pause_allow(1'b1),
        .O_paused(S_a_O_paused),
        .O_pause_busy(S_a_O_pause_busy),
        .I_volume(S_a_I_volume),
        .I_mute(S_a_I_mute),
        .I_prompt_valid(S_a_I_prompt_valid),
        .I_prompt_left(S_a_I_prompt_left),
        .I_prompt_right(S_a_I_prompt_right),
        .O_sample_valid(S_a_O_sample_valid),
        .O_left(S_a_O_left),
        .O_right(S_a_O_right),
        .O_clipped(S_a_O_clipped),
        .O_fade_done(S_a_O_fade_done),
        .O_active_b(S_a_O_active_b),
        .O_busy(S_a_O_busy),
        .O_loaded(S_a_O_loaded),
        .O_enabled(S_a_O_enabled),
        .O_end(S_a_O_end),
        .O_consumed(S_a_O_consumed),
        .O_underrun(S_a_O_underrun),
        .O_release(S_a_O_release),
        .O_next_index(S_a_O_next_index),
        .O_need_fill(S_a_O_need_fill),
        .O_failed(S_a_O_failed),
        .O_slot_stopping(S_a_O_slot_stopping),
        .O_event_valid(S_a_O_event_valid),
        .I_event_ready(S_a_I_event_ready),
        .O_event_header(S_a_O_event_header),
        .O_event_epoch(S_a_O_event_epoch),
        .O_event_total_frames(S_a_O_event_total_frames),
        .O_event_written_frames(S_a_O_event_written_frames),
        .O_event_error(S_a_O_event_error),
        .I_bind_valid(S_a_I_bind_valid),
        .O_bind_ready(S_a_O_bind_ready),
        .I_bind_display_epoch(S_a_I_bind_display_epoch),
        .I_bind_display_tag(S_a_I_bind_display_tag),
        .I_bind_slot(S_a_I_bind_slot),
        .I_bind_track_epoch(S_a_I_bind_track_epoch),
        .I_bind_track_serial(S_a_I_bind_track_serial),
        .I_bind_start_index(S_a_I_bind_start_index),
        .I_bind_reuse_active(S_a_I_bind_reuse_active),
        .I_unbind(S_a_I_unbind),
        .I_bind_abort(S_a_I_bind_abort),
        .I_pending_valid(S_d_O_busy && !S_d_O_done_valid),
        .I_pending_epoch(S_d_O_epoch),
        .I_pending_tag(S_d_O_tag),
        .I_display_audio_applied(1'b0),
        .O_audio_ready(S_a_O_audio_ready),
        .O_audio_epoch(S_a_O_audio_epoch),
        .O_track_known(S_a_O_track_known),
        .O_track_epochs(S_a_O_track_epochs),
        .O_track_serials(S_a_O_track_serials),
        .O_track_totals(S_a_O_track_totals),
        .O_bound(S_a_O_bound),
        .O_binding_revoked(S_a_O_binding_revoked),
        .O_bind_error(S_a_O_bind_error),
        .O_audio_accepted(S_a_O_audio_accepted),
        .O_audio_accepted_epoch(S_a_O_audio_accepted_epoch),
        .O_audio_accepted_tag(S_a_O_audio_accepted_tag),
        .O_prepare_contract_fault(S_a_O_prepare_contract_fault),
        .O_prepare_quarantined(S_a_O_prepare_quarantined),
        .O_prepare_response_discarded(S_a_O_prepare_response_discarded),
        .I_silence_valid(1'b0),
        .O_silence_ready(S_silence_u_prepared_O_silence_ready),
        .O_silence_started(S_silence_u_prepared_O_silence_started),
        .O_silence_done(S_silence_u_prepared_O_silence_done),
        .O_started(S_silence_u_prepared_O_started),
        .I_start_index(64'd0)
    );
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
            wait(S_a_O_start_ready[slot]); @(negedge S_decode_clk);
            S_a_I_file_size[slot*32+:32]=S_lengths[slot]; S_a_I_epoch[slot*16+:16]=epoch; S_a_I_start_valid[slot]=1;
            @(posedge S_decode_clk); while(!S_a_O_start_ready[slot]) @(posedge S_decode_clk);
            @(negedge S_decode_clk); S_a_I_start_valid[slot]=0;
        end
    endtask
    task send_range;
        input integer slot,first,limit;
        integer k;
        begin
            for(k=first;k<limit;k=k+1) begin
                @(negedge S_decode_clk); S_a_I_byte_valid[slot]=1;
                S_a_I_byte_data[slot*8+:8]=S_file[slot*1024+k];
                S_a_I_byte_epoch[slot*16+:16]=S_epochs[slot]; S_a_I_byte_last[slot]=k==S_lengths[slot]-1;
                @(posedge S_decode_clk); while(!S_a_O_byte_ready[slot]) @(posedge S_decode_clk);
                @(negedge S_decode_clk); S_a_I_byte_valid[slot]=0;
            end
        end
    endtask
    task bind_track;
        input slot,reuse_active;
        input [31:0] serial,index;
        input [3:0] error;
        begin
            @(negedge S_clk); S_a_I_bind_display_epoch=S_d_O_epoch; S_a_I_bind_display_tag=S_d_O_tag; S_a_I_bind_slot=slot; S_a_I_bind_reuse_active=reuse_active;
            S_a_I_bind_track_epoch=S_epochs[slot]; S_a_I_bind_track_serial=serial;
            S_a_I_bind_start_index=index; S_a_I_bind_valid=1;
            @(posedge S_clk); while(!S_a_O_bind_ready) @(posedge S_clk);
            #1; if(S_a_O_bind_error!==error || (error!=0 && S_a_O_bound)) fail("bind error/occupancy result");
            @(negedge S_clk); S_a_I_bind_valid=0;
        end
    endtask
    task unbind;
        begin @(negedge S_clk); S_a_I_unbind=1;
            @(negedge S_clk); S_a_I_unbind=0; if(S_a_O_bound) fail("unbind did not release binding"); end
    endtask
    task recycle;
        input integer slot;
        begin
            @(negedge S_decode_clk); S_a_I_recycle_valid[slot]=1;
            @(posedge S_decode_clk); while(!S_a_O_recycle_ready[slot]) @(posedge S_decode_clk);
            @(negedge S_decode_clk); S_a_I_recycle_valid[slot]=0;
            wait(S_a_O_recycle_done[slot]); @(negedge S_decode_clk);
        end
    endtask
    task load_full;
        input integer slot,frames;
        input [15:0] epoch;
        begin open_file(slot,frames,0,epoch); send_range(slot,0,S_lengths[slot]);
            wait(S_a_O_track_known[slot]); repeat(12) @(negedge S_clk); end
    endtask
    task audio_defaults;
        begin
            S_a_I_start_valid=0; S_a_I_byte_valid=0; S_a_I_byte_last=0; S_a_I_recycle_valid=0;
            S_a_I_stream_error_valid=0; S_a_I_event_ready=3; S_a_I_cancel_ready=3;
            S_a_I_volume=16; S_a_I_bind_valid=0; S_a_I_unbind=0; S_a_I_bind_abort=0;
            S_real_commands=0; S_real_fades=0;
        end
    endtask
    av_event_timeline u_timeline (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_clock_enable(S_d_I_clock_enable),
        .I_time(S_time),
        .I_frame_start(S_frame_start),
        .I_sample_tick(S_tick),
        .I_start_valid(S_d_I_start_valid),
        .O_start_ready(S_d_O_start_ready),
        .I_epoch(S_d_I_epoch),
        .I_tag(S_d_I_tag),
        .I_effect(S_d_I_effect),
        .I_duration_frames(S_d_I_duration_frames),
        .I_av_offset_steps(S_d_I_av_offset_steps),
        .I_audio_action(S_d_I_audio_action),
        .I_audio_slot(S_d_I_audio_slot),
        .I_track_epoch(S_d_I_track_epoch),
        .I_track_serial(S_d_I_track_serial),
        .I_start_index(S_d_I_start_index),
        .I_resources_ready(S_d_I_resources_ready),
        .I_resources_epoch(S_d_O_epoch),
        .I_resources_tag(S_d_O_tag),
        .I_track_known(S_d_I_track_known),
        .I_track_enabled(S_d_I_track_enabled),
        .I_track_consumed(S_d_I_track_consumed),
        .I_track_epochs(S_d_I_track_epochs),
        .I_track_serials(S_d_I_track_serials),
        .I_track_totals(S_d_I_track_totals),
        .I_track_next_index(S_d_I_track_next_index),
        .I_pause(S_d_I_pause),
        .I_abort(S_d_I_abort),
        .O_pause_allow(S_d_O_pause_allow),
        .O_video_valid(S_d_O_video_valid),
        .I_video_ready(S_d_I_video_ready),
        .O_video_cancel(S_d_O_video_cancel),
        .O_video_epoch(S_d_O_video_epoch),
        .O_video_tag(S_d_O_video_tag),
        .O_video_effect(S_d_O_video_effect),
        .O_video_frame_index(S_d_O_video_frame_index),
        .O_video_progress(S_d_O_video_progress),
        .O_video_target_time(S_d_O_video_target_time),
        .I_video_done_valid(S_d_I_video_done_valid),
        .O_video_done_ready(S_d_O_video_done_ready),
        .I_video_done_epoch(S_d_I_video_done_epoch),
        .I_video_done_tag(S_d_I_video_done_tag),
        .I_video_done_frame_index(S_d_I_video_done_frame_index),
        .I_video_done_error(S_d_I_video_done_error),
        .I_video_done_applied(S_d_I_video_done_applied),
        .I_video_done_time(S_d_I_video_done_time),
        .O_play_valid(S_d_O_play_valid),
        .I_play_ready(S_d_I_play_ready),
        .O_fade_valid(S_d_O_fade_valid),
        .O_target_b(S_d_O_target_b),
        .O_audio_target_time(S_d_O_audio_target_time),
        .I_fade_ready(S_d_I_fade_ready),
        .I_fade_done(S_d_I_fade_done),
        .I_active_b(S_d_I_active_b),
        .O_audio_stop_request(S_d_O_audio_stop_request),
        .I_audio_stop_ack(S_d_I_audio_stop_ack),
        .O_busy(S_d_O_busy),
        .O_done_valid(S_d_O_done_valid),
        .I_done_ready(S_d_I_done_ready),
        .O_error(S_d_O_error),
        .O_epoch(S_d_O_epoch),
        .O_tag(S_d_O_tag),
        .O_cancel_late(S_d_O_cancel_late),
        .O_video_started(S_d_O_video_started),
        .O_video_finished(S_d_O_video_finished),
        .O_audio_started(S_d_O_audio_started),
        .O_audio_finished(S_d_O_audio_finished),
        .O_planned_start(S_d_O_planned_start),
        .O_planned_midpoint(S_d_O_planned_midpoint),
        .O_planned_audio(S_d_O_planned_audio),
        .O_actual_start(S_d_O_actual_start),
        .O_actual_midpoint(S_d_O_actual_midpoint),
        .O_actual_audio(S_d_O_actual_audio),
        .O_actual_finish(S_d_O_actual_finish),
        .O_audio_command_time(S_d_O_audio_command_time),
        .O_audio_start_index(S_d_O_audio_start_index),
        .O_anchor_error(S_d_O_anchor_error),
        .O_midpoint_seen(S_d_O_midpoint_seen),
        .O_late(S_d_O_late),
        .O_contract_fault(S_d_O_contract_fault),
        .O_quarantined(S_d_O_quarantined),
        .O_response_discarded(S_d_O_response_discarded),
        .O_silence_valid(S_silence_u_timeline_O_silence_valid),
        .I_silence_ready(1'b0),
        .I_silence_started(1'b0),
        .I_silence_done(1'b0)
    );
    wire S_plan_ready,S_plan_done;
    wire [3:0] S_plan_error;
    wire [16:0] S_plan_progress;
    wire S_execute=S_peer_pending && S_plan_done && !S_d_I_video_done_valid &&
        ((S_d_O_video_cancel || S_peer_error!=0) || (S_raster_frame && !((S_time-S_peer_target)&32'h80000000) && S_apply_gate));
    transition_plan u_plan (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_d_O_video_valid && S_d_I_video_ready),.O_start_ready(S_plan_ready),
        .I_effect(S_d_O_video_effect),.I_progress(S_d_O_video_progress),.I_epoch(S_d_O_video_epoch),.I_tag(S_d_O_video_tag),
        .O_done_valid(S_plan_done),.I_done_ready(S_execute),.O_error(S_plan_error),.O_effect(),.O_progress(S_plan_progress),
        .O_epoch(),.O_tag(),.O_dx(),.O_left(),.O_dy(),.O_top(),.O_blind_count(),.O_mosaic_count(),
        .O_wipe_threshold(),.O_step_x(),.O_step_y());
    task fail;
        input [767:0] message;
        begin $display("FAIL: AV event timeline case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin repeat(20) #1000000000; fail("watchdog timeout"); end
    always @* begin
        S_d_I_video_ready=S_video_gate && !S_peer_pending && !S_d_I_video_done_valid && S_plan_ready;

    end
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin
            S_peer_pending<=0; S_peer_result_real<=0; S_d_I_video_done_valid<=0;
            S_d_I_video_done_epoch<=0; S_d_I_video_done_tag<=0; S_d_I_video_done_frame_index<=0;
            S_d_I_video_done_error<=0; S_d_I_video_done_applied<=0; S_d_I_video_done_time<=0; S_peer_target<=0; S_peer_index<=0;
            S_requests<=0; S_actual_frames<=0;
        end else begin
            if(S_d_O_video_valid && S_d_I_video_ready) begin
                S_peer_pending<=1; S_peer_target<=S_d_O_video_target_time; S_peer_index<=S_d_O_video_frame_index;
                if(S_d_O_video_progress!==(65536*S_d_O_video_frame_index)/S_d_I_duration_frames)
                    fail("progress quotient/remainder differs from independent frame fraction");
                S_requests<=S_requests+1;
            end
            if(S_d_I_video_done_valid && S_d_O_video_done_ready) begin
                S_d_I_video_done_valid<=0;
                if(S_peer_result_real) S_peer_pending<=0;
            end
            if(S_inject_wrong && S_peer_pending && !S_d_I_video_done_valid) begin
                S_d_I_video_done_valid<=1; S_d_I_video_done_epoch<=S_d_O_epoch^32'h01000000;
                S_d_I_video_done_tag<=S_d_O_tag; S_d_I_video_done_frame_index<=S_peer_index;
                S_d_I_video_done_error<=0; S_d_I_video_done_applied<=1; S_d_I_video_done_time<=S_peer_target; S_peer_result_real<=0;
            end else if(S_execute) begin
                S_d_I_video_done_valid<=1; S_d_I_video_done_epoch<=S_d_O_epoch;
                S_d_I_video_done_tag<=S_d_O_tag; S_d_I_video_done_frame_index<=S_peer_index;
                S_d_I_video_done_error<=S_d_O_video_cancel ? 4'd3 : S_peer_error;
                S_d_I_video_done_applied<=!S_d_O_video_cancel && S_peer_error==0;
                S_d_I_video_done_time<=S_time; S_peer_result_real<=1;
                if(!S_d_O_video_cancel && S_peer_error==0) begin
                    S_actual_frames<=S_actual_frames+1;
                    if(S_plan_error!=0 || S_plan_progress!==(65536*S_peer_index)/S_d_I_duration_frames)
                        fail("actual frame installed a failed/stale real transition plan");
                end
            end
        end
    end
    always @(posedge S_clk) if(!S_reset) begin
        if(S_d_O_video_valid) begin
            if(S_offer_held && S_held_offer!=={S_d_O_video_epoch,S_d_O_video_tag,S_d_O_video_effect,
                S_d_O_video_frame_index,S_d_O_video_progress,S_d_O_video_target_time}) fail("presented video offer changed under backpressure/cancel");
            S_held_offer={S_d_O_video_epoch,S_d_O_video_tag,S_d_O_video_effect,S_d_O_video_frame_index,S_d_O_video_progress,S_d_O_video_target_time};
            S_offer_held=!S_d_I_video_ready;
        end else begin
            if(S_offer_held) fail("presented video valid withdrew before handshake"); S_offer_held=0;
        end
        if(S_d_O_play_valid && S_d_O_fade_valid) fail("two audio commands presented simultaneously");
    end
    task reset_all;
        begin
            S_run=1; S_reset=1; S_frame_gate=1; S_command_epoch=0; S_offer_held=0;
            S_video_gate=1; S_audio_gate=1; S_apply_gate=1; S_stop_gate=1; S_ack_fall_gate=1;
            S_inject_wrong=0; S_peer_error=0;
            S_d_I_start_valid=0; S_d_I_done_ready=0; S_d_I_abort=0; S_d_I_pause=0;
            S_d_I_clock_enable=1;

            repeat(6) @(negedge S_clk); S_reset=0; repeat(5) @(negedge S_clk);
        end
    endtask
    task start_event;
        input [15:0] frames;
        input signed [6:0] offset_steps;
        input [1:0] action;
        input slot;
        begin
            @(negedge S_clk); S_command_epoch=S_command_epoch+1;
            S_d_I_epoch=S_command_epoch; S_d_I_tag=16'h8912; S_d_I_effect=6; S_d_I_duration_frames=frames;
            S_d_I_av_offset_steps=offset_steps; S_d_I_audio_action=action; S_d_I_audio_slot=slot;
            S_d_I_track_epoch=S_a_O_track_epochs[slot*16+:16]; S_d_I_track_serial=S_a_O_track_serials[slot*32+:32];
            S_d_I_start_index=0; S_d_I_start_valid=1;
            @(posedge S_clk); while(!S_d_O_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_d_I_start_valid=0;
        end
    endtask
    task result;
        input [3:0] error;
        reg [767:0] held;
        reg saved_abort;
        begin
            wait(S_d_O_done_valid); #2;
            if(S_d_O_error!==error) fail("unexpected transaction result");
            held={S_d_O_error,S_d_O_epoch,S_d_O_tag,S_d_O_cancel_late,S_d_O_video_started,S_d_O_video_finished,
                S_d_O_audio_started,S_d_O_audio_finished,S_d_O_actual_start,S_d_O_actual_midpoint,S_d_O_actual_audio,
                S_d_O_actual_finish,S_d_O_audio_command_time,S_d_O_audio_start_index,S_d_O_anchor_error,
                S_d_O_planned_start,S_d_O_planned_midpoint,S_d_O_planned_audio,S_d_O_midpoint_seen,S_d_O_late};
            saved_abort=S_d_I_abort; S_d_I_abort=1;
            repeat(8) begin @(negedge S_clk);
                if(!S_d_O_done_valid || S_d_O_start_ready || held!=={S_d_O_error,S_d_O_epoch,S_d_O_tag,S_d_O_cancel_late,
                    S_d_O_video_started,S_d_O_video_finished,S_d_O_audio_started,S_d_O_audio_finished,S_d_O_actual_start,
                    S_d_O_actual_midpoint,S_d_O_actual_audio,S_d_O_actual_finish,S_d_O_audio_command_time,
                    S_d_O_audio_start_index,S_d_O_anchor_error,S_d_O_planned_start,S_d_O_planned_midpoint,
                    S_d_O_planned_audio,S_d_O_midpoint_seen,S_d_O_late}) fail("result payload changed under backpressure");
            end
            S_d_I_abort=saved_abort;
            S_d_I_done_ready=1; @(negedge S_clk); S_d_I_done_ready=0;
        end
    endtask
    initial begin
        S_case=1; audio_defaults; reset_all; wait(S_a_O_available==3); load_full(0,3,16'habcd);
        start_event(2,0,1,0); bind_track(0,0,S_a_O_track_serials[31:0],0,0); result(0);
        if(S_real_commands!=1 || !S_d_O_audio_started || S_d_O_audio_start_index!=0 ||
            S_d_O_anchor_error<0 || S_d_O_anchor_error>521 || S_d_I_track_next_index[31:0]!=3)
            fail("actual sample consumption did not establish the default audio anchor");
        if(!S_a_O_binding_revoked) fail("fresh preparation was incorrectly kept valid after actual audio start");
        unbind;

        S_case=2; load_full(1,3,16'h1234);
        start_event(2,1,2,1); bind_track(1,0,S_a_O_track_serials[63:32],0,0);
        wait(S_d_O_video_finished);
        if(S_d_O_done_valid || S_real_fades!=0) fail("timeline completed before actual 9600-sample fade output");
        result(0);
        if(S_real_commands!=2 || S_real_fades!=1 || !S_d_O_audio_finished || !S_a_O_active_b ||
            S_d_O_anchor_error<0 || S_d_O_anchor_error>521 || S_d_O_actual_finish>=S_time)
            fail("actual two-slot fade/output completion or dwell start facts");
        unbind;

        S_case=3; audio_defaults; reset_all; wait(S_a_O_available==3); load_full(0,3,16'habcd);
        start_event(2,-50,1,0); bind_track(0,0,S_a_O_track_serials[31:0],0,0); result(0);
        if(S_d_O_actual_audio>=S_d_O_actual_start || S_d_O_anchor_error<0 || S_d_O_anchor_error>521 || S_real_commands!=1)
            fail("actual negative-500 ms audio start did not precede the planned transition");
        unbind;

        S_case=4; S_preserved_index=S_a_O_next_index[31:0];
        start_event(2,0,3,0); bind_track(0,1,S_a_O_track_serials[31:0],0,0); result(0);
        if(S_real_commands!=1 || S_d_O_audio_started || S_a_O_next_index[31:0]!==S_preserved_index)
            fail("reuse of real same-background WAV restarted or rewound its position");

        S_case=5; audio_defaults; reset_all; wait(S_a_O_available==3); load_full(0,0,16'habcd);
        start_event(2,0,1,0); bind_track(0,0,S_a_O_track_serials[31:0],0,0); result(0);
        if(!S_d_O_audio_started || !S_d_O_audio_finished || S_d_O_audio_start_index!=0 ||
            S_a_O_next_index[31:0]!=0 || S_d_O_anchor_error<0 || S_d_O_anchor_error>521 || S_real_commands!=1)
            fail("real empty WAV did not establish a sample-boundary zero-source anchor");
        $display("PASS: actual WAV/PCM/playback sample anchors, signed offsets, 9600-sample fade and background reuse");
        S_test_pass=1; $finish;
    end
endmodule
