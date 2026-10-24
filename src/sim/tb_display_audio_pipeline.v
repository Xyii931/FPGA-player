`timescale 1ns/1ps
// Real host owner + lease/commit CDC + candidate/scanout/reader + slot manager/RAM.
// Actual deadline scheduler/CDC plus real WAV preparation; file bytes, bind commands and logical memory are fixtures.
module tb_display_audio_pipeline;
    wire S_silence_u_prepared_O_started;
    wire S_silence_u_prepared_O_silence_ready;
    wire S_silence_u_prepared_O_silence_started;
    wire S_silence_u_prepared_O_silence_done;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    wire S_host_reset;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reset_sync u_host_reset (.I_clk(S_host_clk),.I_async_reset(S_reset),.O_reset(S_host_reset));
    reg S_fixture=1,S_f_valid=0,S_f_result_ready=0,S_cmd_gate=1,S_media_valid=1;
    reg [2:0] S_f_op=0,S_f_slot=0;
    reg [31:0] S_f_token=0;
    reg [31:0] S_tokens[0:5];
    reg [1:0] S_mem_enable=3;
    reg [7:0] S_mem_error=0;
    reg S_expect_fault=0,S_check_pixels=0;
    integer S_case=0,S_commands=0,S_publishes=0,S_applies=0,S_pixels=0,S_frames=0;
    integer S_mem_counts[0:1];
    integer S_i,S_v_i;
    reg [137:0] S_last_publish=0,S_previous_video_leases=0;
    reg [31:0] S_last_version=0,S_saved_epoch=0,S_frame_epoch=0;
    reg [3:0] S_seed_mask=0;
    reg [1:0] S_next_banks=0;
    reg [246:0] S_bad_config;
    reg S_d_I_start_valid=0;
    wire S_d_O_start_ready;
    reg [246:0] S_d_I_config=0;
    reg [15:0] S_d_I_tag=0;
    reg S_d_I_abort=0;
    wire S_d_O_busy;
    wire S_d_O_done_valid;
    reg S_d_I_done_ready=0;
    wire [3:0] S_d_O_error;
    wire [3:0] S_d_O_lease_error;
    wire [3:0] S_d_O_slot_error;
    wire [3:0] S_d_O_commit_error;
    wire [3:0] S_d_O_prepare_error;
    wire [3:0] S_d_O_retire_error;
    reg S_d_I_video_allow_apply=1;
    reg S_d_I_video_abort=0;
    wire S_d_I_audio_ready;
    wire [31:0] S_d_I_audio_epoch;
    wire S_d_O_host_quarantined;
    wire S_d_O_host_response_discarded;
    wire S_d_O_video_quarantined;
    wire [15:0] S_d_O_tag;
    wire [31:0] S_d_O_epoch;
    wire [31:0] S_d_O_previous_epoch;
    wire S_d_O_applied;
    wire S_d_O_retired;
    wire S_d_O_cancel_late;
    wire [1:0] S_d_O_acquired_mask;
    wire [1:0] S_d_O_released_mask;
    wire [1:0] S_d_O_host_active_mask;
    wire S_d_O_host_active_valid;
    wire [31:0] S_d_O_host_active_epoch;
    wire [246:0] S_d_O_host_active_config;
    wire [1:0] S_d_O_host_reserve;
    wire [1:0] S_d_O_source_idle;
    wire [1:0] S_d_O_source_busy;
    wire [1:0] S_d_O_owned;
    wire [1:0] S_d_O_lease_valid;
    wire [5:0] S_d_O_lease_slots;
    wire [63:0] S_d_O_lease_tokens;
    wire [63:0] S_d_O_lease_generations;
    wire [1:0] S_d_O_lease_resident;
    wire S_d_O_slot_cmd_valid;
    wire [2:0] S_d_O_slot_cmd_op;
    wire [2:0] S_d_O_slot_cmd_slot;
    wire [1:0] S_d_O_slot_cmd_owner;
    wire [31:0] S_d_O_slot_cmd_token;
    wire [31:0] S_d_O_slot_cmd_generation;
    wire S_d_O_slot_frame_boundary;
    wire S_d_O_slot_reader_retired;
    wire S_d_O_slot_result_ready;
    wire [1:0] S_d_O_source_block;
    wire [1:0] S_d_O_reader_stop;
    wire [1:0] S_d_O_video_retire_ack;
    wire [1:0] S_d_O_source_fault;
    wire [137:0] S_d_O_video_leases;
    wire [31:0] S_d_O_video_lease_version;
    wire [1:0] S_d_O_video_authorized;
    wire [31:0] S_d_O_next_epoch;
    wire S_d_O_pending_valid;
    wire [246:0] S_d_O_pending_config;
    wire [15:0] S_d_O_pending_tag;
    wire [31:0] S_d_O_pending_epoch;
    wire S_d_O_video_active_valid;
    wire [246:0] S_d_O_video_active_config;
    wire [15:0] S_d_O_video_active_tag;
    wire S_d_O_video_response_discarded;
    reg S_d_I_scan_stop=0;
    wire S_d_O_scan_stop_ack;
    wire [1:0] S_d_O_reader_retire_ack;
    wire [1:0] S_d_O_reader_host_retired;
    wire [1:0] S_d_O_source_in_use;
    wire [1:0] S_d_O_source_owner_retired;
    wire [1:0] S_d_O_source_pipeline_retired;
    wire [8:0] S_d_O_prefetch_y;
    wire [31:0] S_d_O_video_active_epoch;
    wire S_d_O_frame_start;
    wire S_d_O_local_applied;
    wire S_d_O_valid;
    wire S_d_O_hsync;
    wire S_d_O_vsync;
    wire S_d_O_de;
    wire [15:0] S_d_O_x;
    wire [15:0] S_d_O_y;
    wire [23:0] S_d_O_rgb;
    wire [31:0] S_d_O_pixel_epoch;
    wire [15:0] S_d_O_pixel_tag;
    wire S_d_O_repeated;
    wire S_d_O_pixel_fault;
    wire S_d_O_video_und;
    wire [31:0] S_d_O_und_count;
    wire [31:0] S_d_O_line_error_count;
    wire [1:0] S_d_O_mem_valid;
    wire [41:0] S_d_O_mem_addr;
    wire [63:0] S_d_O_mem_tag;
    wire [63:0] S_d_O_mem_token;
    wire [63:0] S_d_O_mem_generation;
    wire [63:0] S_d_O_mem_deadline;
    wire [1:0] S_d_O_mem_ready;
    reg S_clock_enable=1;
    wire [31:0] S_host_time,S_video_time,S_prepare_target;
    wire S_deadline_fault;
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
    reg S_a_I_sample_tick=0;
    reg S_a_I_play_valid=0;
    wire S_a_O_play_ready;
    reg S_a_I_fade_valid=0;
    reg S_a_I_target_b=0;
    wire S_a_O_fade_ready;
    reg S_a_I_pause=0;
    reg S_a_I_pause_allow=0;
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
    wire S_a_I_pending_valid=S_d_O_pending_valid;
    wire [31:0] S_a_I_pending_epoch=S_d_O_pending_epoch;
    wire [15:0] S_a_I_pending_tag=S_d_O_pending_tag;
    wire S_a_I_display_audio_applied=S_d_O_local_applied && S_d_O_video_active_config[52];
    assign S_d_I_audio_ready=S_a_O_audio_ready;
    assign S_d_I_audio_epoch=S_a_O_audio_epoch;
    reg [7:0] S_audio_file[0:2047];
    integer S_audio_lengths[0:1];
    reg [15:0] S_audio_epochs[0:1];
    integer S_audio_accepts=0;
    always @(posedge S_host_clk) begin
        if(S_reset) S_a_I_io_retired<=0;
        else S_a_I_io_retired<=S_a_O_io_retire_request;
    end
    always @(posedge S_video_clk) begin
        if(!S_reset && S_a_O_prepare_quarantined) fail("unexpected real audio preparation isolation");
        #2; if(!S_reset && S_a_O_audio_accepted) begin
            S_audio_accepts=S_audio_accepts+1;
            if(S_a_O_audio_accepted_epoch!==S_d_O_video_active_epoch ||
                S_a_O_audio_accepted_tag!==S_d_O_video_active_tag)
                fail("real audio proof accepted another installed display identity");
        end
    end
    wav_audio_prepared #(.FIFO_ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4),.FADE_SAMPLES(7)) u_prepared (
        .I_decode_clk(S_host_clk),
        .I_audio_clk(S_video_clk),
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
        .I_sample_tick(S_a_I_sample_tick),
        .I_play_valid(S_a_I_play_valid),
        .O_play_ready(S_a_O_play_ready),
        .I_fade_valid(S_a_I_fade_valid),
        .I_target_b(S_a_I_target_b),
        .O_fade_ready(S_a_O_fade_ready),
        .I_pause(S_a_I_pause),
        .I_pause_allow(S_a_I_pause_allow),
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
        .I_pending_valid(S_a_I_pending_valid),
        .I_pending_epoch(S_a_I_pending_epoch),
        .I_pending_tag(S_a_I_pending_tag),
        .I_display_audio_applied(S_a_I_display_audio_applied),
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
        begin S_audio_file[address]=value; S_audio_file[address+1]=value>>8;
            S_audio_file[address+2]=value>>16; S_audio_file[address+3]=value>>24; end
    endtask
    task open_file;
        input integer slot,frames,bad_tail;
        input [15:0] epoch;
        integer base,k;
        begin
            base=slot*1024; S_audio_lengths[slot]=44+4*frames+8*bad_tail; S_audio_epochs[slot]=epoch;
            for(k=0;k<1024;k=k+1) S_audio_file[base+k]=0;
            S_audio_file[base]="R"; S_audio_file[base+1]="I"; S_audio_file[base+2]="F"; S_audio_file[base+3]="F";
            put32(base+4,S_audio_lengths[slot]-8);
            S_audio_file[base+8]="W"; S_audio_file[base+9]="A"; S_audio_file[base+10]="V"; S_audio_file[base+11]="E";
            S_audio_file[base+12]="f"; S_audio_file[base+13]="m"; S_audio_file[base+14]="t"; S_audio_file[base+15]=" ";
            put32(base+16,16); S_audio_file[base+20]=1; S_audio_file[base+22]=2;
            put32(base+24,48000); put32(base+28,192000); S_audio_file[base+32]=4; S_audio_file[base+34]=16;
            S_audio_file[base+36]="d"; S_audio_file[base+37]="a"; S_audio_file[base+38]="t"; S_audio_file[base+39]="a";
            put32(base+40,4*frames);
            for(k=0;k<4*frames;k=k+1) S_audio_file[base+44+k]=k+17;
            if(bad_tail!=0) begin
                S_audio_file[base+44+4*frames]="d"; S_audio_file[base+45+4*frames]="a";
                S_audio_file[base+46+4*frames]="t"; S_audio_file[base+47+4*frames]="a";
            end
            wait(S_a_O_start_ready[slot]); @(negedge S_host_clk);
            S_a_I_file_size[slot*32+:32]=S_audio_lengths[slot]; S_a_I_epoch[slot*16+:16]=epoch; S_a_I_start_valid[slot]=1;
            @(posedge S_host_clk); while(!S_a_O_start_ready[slot]) @(posedge S_host_clk);
            @(negedge S_host_clk); S_a_I_start_valid[slot]=0;
        end
    endtask
    task send_range;
        input integer slot,first,limit;
        integer k;
        begin
            for(k=first;k<limit;k=k+1) begin
                @(negedge S_host_clk); S_a_I_byte_valid[slot]=1;
                S_a_I_byte_data[slot*8+:8]=S_audio_file[slot*1024+k];
                S_a_I_byte_epoch[slot*16+:16]=S_audio_epochs[slot]; S_a_I_byte_last[slot]=k==S_audio_lengths[slot]-1;
                @(posedge S_host_clk); while(!S_a_O_byte_ready[slot]) @(posedge S_host_clk);
                @(negedge S_host_clk); S_a_I_byte_valid[slot]=0;
            end
        end
    endtask
    task bind_track;
        input slot,reuse_active;
        input [31:0] serial,index;
        input [3:0] error;
        begin
            @(negedge S_video_clk); S_a_I_bind_display_epoch=S_d_O_pending_epoch; S_a_I_bind_display_tag=S_d_O_pending_tag; S_a_I_bind_slot=slot; S_a_I_bind_reuse_active=reuse_active;
            S_a_I_bind_track_epoch=S_audio_epochs[slot]; S_a_I_bind_track_serial=serial;
            S_a_I_bind_start_index=index; S_a_I_bind_valid=1;
            @(posedge S_video_clk); while(!S_a_O_bind_ready) @(posedge S_video_clk);
            #1; if(S_a_O_bind_error!==error || (error!=0 && S_a_O_bound)) fail("bind error/occupancy result");
            @(negedge S_video_clk); S_a_I_bind_valid=0;
        end
    endtask
    task unbind;
        begin @(negedge S_video_clk); S_a_I_unbind=1;
            @(negedge S_video_clk); S_a_I_unbind=0; if(S_a_O_bound) fail("unbind did not release binding"); end
    endtask
    task recycle;
        input integer slot;
        begin
            @(negedge S_host_clk); S_a_I_recycle_valid[slot]=1;
            @(posedge S_host_clk); while(!S_a_O_recycle_ready[slot]) @(posedge S_host_clk);
            @(negedge S_host_clk); S_a_I_recycle_valid[slot]=0;
            wait(S_a_O_recycle_done[slot]); @(negedge S_host_clk);
        end
    endtask
    task load_full;
        input integer slot,frames;
        input [15:0] epoch;
        begin open_file(slot,frames,0,epoch); send_range(slot,0,S_audio_lengths[slot]);
            wait(S_a_O_track_known[slot]); repeat(12) @(negedge S_video_clk); end
    endtask
    task audio_defaults;
        begin
            S_a_I_start_valid=0; S_a_I_byte_valid=0; S_a_I_byte_last=0; S_a_I_recycle_valid=0;
            S_a_I_stream_error_valid=0; S_a_I_play_valid=0; S_a_I_fade_valid=0; S_a_I_sample_tick=0;
            S_a_I_cancel_ready=3; S_a_I_event_ready=3; S_a_I_pause_allow=1; S_a_I_volume=16;
            S_a_I_bind_valid=0; S_a_I_unbind=0; S_a_I_bind_abort=0;
            S_audio_accepts=0;
        end
    endtask
    display_timed_pipeline u_timed (
        .O_bank_busy(),
        .I_target_valid(1'b0),.I_target_epoch(32'd0),.I_target_time(32'd0),.I_target_tag(16'd0),
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_start_valid(S_d_I_start_valid),
        .O_start_ready(S_d_O_start_ready),
        .I_config(S_d_I_config),
        .I_tag(S_d_I_tag),
        .I_abort(S_d_I_abort),
        .O_busy(S_d_O_busy),
        .O_done_valid(S_d_O_done_valid),
        .I_done_ready(S_d_I_done_ready),
        .O_error(S_d_O_error),
        .O_lease_error(S_d_O_lease_error),
        .O_slot_error(S_d_O_slot_error),
        .O_commit_error(S_d_O_commit_error),
        .O_prepare_error(S_d_O_prepare_error),
        .O_retire_error(S_d_O_retire_error),
        .I_video_allow_apply(S_d_I_video_allow_apply),
        .I_video_abort(S_d_I_video_abort),
        .I_audio_ready(S_d_I_audio_ready),
        .I_audio_epoch(S_d_I_audio_epoch),
        .O_host_quarantined(S_d_O_host_quarantined),
        .O_host_response_discarded(S_d_O_host_response_discarded),
        .O_video_quarantined(S_d_O_video_quarantined),
        .O_tag(S_d_O_tag),
        .O_epoch(S_d_O_epoch),
        .O_previous_epoch(S_d_O_previous_epoch),
        .O_applied(S_d_O_applied),
        .O_retired(S_d_O_retired),
        .O_cancel_late(S_d_O_cancel_late),
        .O_acquired_mask(S_d_O_acquired_mask),
        .O_released_mask(S_d_O_released_mask),
        .O_host_active_mask(S_d_O_host_active_mask),
        .O_host_active_valid(S_d_O_host_active_valid),
        .O_host_active_epoch(S_d_O_host_active_epoch),
        .O_host_active_config(S_d_O_host_active_config),
        .O_host_reserve(S_d_O_host_reserve),
        .O_source_idle(S_d_O_source_idle),
        .O_source_busy(S_d_O_source_busy),
        .O_owned(S_d_O_owned),
        .O_lease_valid(S_d_O_lease_valid),
        .O_lease_slots(S_d_O_lease_slots),
        .O_lease_tokens(S_d_O_lease_tokens),
        .O_lease_generations(S_d_O_lease_generations),
        .O_lease_resident(S_d_O_lease_resident),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_readers(S_m_O_slot_readers),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .O_slot_cmd_valid(S_d_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_m_O_cmd_ready && S_cmd_gate && !S_fixture),
        .O_slot_cmd_op(S_d_O_slot_cmd_op),
        .O_slot_cmd_slot(S_d_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_d_O_slot_cmd_owner),
        .O_slot_cmd_token(S_d_O_slot_cmd_token),
        .O_slot_cmd_generation(S_d_O_slot_cmd_generation),
        .O_slot_frame_boundary(S_d_O_slot_frame_boundary),
        .O_slot_reader_retired(S_d_O_slot_reader_retired),
        .I_slot_result_valid(S_m_O_result_valid && !S_fixture),
        .O_slot_result_ready(S_d_O_slot_result_ready),
        .I_slot_result_error(S_m_O_result_error),
        .I_slot_result_op(S_m_O_result_op),
        .I_slot_result_slot(S_m_O_result_slot),
        .I_slot_result_owner(S_m_O_result_owner),
        .I_slot_result_token(S_m_O_result_token),
        .I_slot_result_generation(S_m_O_result_generation),
        .I_slot_result_base(S_m_O_result_base),
        .O_source_block(S_d_O_source_block),
        .O_reader_stop(S_d_O_reader_stop),
        .O_video_retire_ack(S_d_O_video_retire_ack),
        .O_source_fault(S_d_O_source_fault),
        .O_video_leases(S_d_O_video_leases),
        .O_video_lease_version(S_d_O_video_lease_version),
        .O_video_authorized(S_d_O_video_authorized),
        .O_next_epoch(S_d_O_next_epoch),
        .O_pending_valid(S_d_O_pending_valid),
        .O_pending_config(S_d_O_pending_config),
        .O_pending_tag(S_d_O_pending_tag),
        .O_pending_epoch(S_d_O_pending_epoch),
        .O_video_active_valid(S_d_O_video_active_valid),
        .O_video_active_config(S_d_O_video_active_config),
        .O_video_active_tag(S_d_O_video_active_tag),
        .O_video_response_discarded(S_d_O_video_response_discarded),
        .I_scan_stop(S_d_I_scan_stop),
        .O_scan_stop_ack(S_d_O_scan_stop_ack),
        .O_reader_retire_ack(S_d_O_reader_retire_ack),
        .O_reader_host_retired(S_d_O_reader_host_retired),
        .O_source_in_use(S_d_O_source_in_use),
        .O_source_owner_retired(S_d_O_source_owner_retired),
        .O_source_pipeline_retired(S_d_O_source_pipeline_retired),
        .O_prefetch_y(S_d_O_prefetch_y),
        .O_video_active_epoch(S_d_O_video_active_epoch),
        .O_frame_start(S_d_O_frame_start),
        .O_local_applied(S_d_O_local_applied),
        .O_valid(S_d_O_valid),
        .O_hsync(S_d_O_hsync),
        .O_vsync(S_d_O_vsync),
        .O_de(S_d_O_de),
        .O_x(S_d_O_x),
        .O_y(S_d_O_y),
        .O_rgb(S_d_O_rgb),
        .O_pixel_epoch(S_d_O_pixel_epoch),
        .O_pixel_tag(S_d_O_pixel_tag),
        .O_repeated(S_d_O_repeated),
        .O_pixel_fault(S_d_O_pixel_fault),
        .O_video_und(S_d_O_video_und),
        .O_und_count(S_d_O_und_count),
        .O_line_error_count(S_d_O_line_error_count),
        .O_mem_valid(S_d_O_mem_valid),
        .I_mem_ready(S_mem_enable),
        .O_mem_addr(S_d_O_mem_addr),
        .O_mem_tag(S_d_O_mem_tag),
        .O_mem_token(S_d_O_mem_token),
        .O_mem_generation(S_d_O_mem_generation),
        .O_mem_deadline(S_d_O_mem_deadline),
        .I_mem_valid(S_d_O_mem_valid & S_mem_enable),
        .O_mem_ready(S_d_O_mem_ready),
        .I_mem_data(64'h336699ff336699ff),
        .I_mem_tag(S_d_O_mem_tag),
        .I_mem_token(S_d_O_mem_token),
        .I_mem_generation(S_d_O_mem_generation),
        .I_mem_error(S_mem_error),
        .I_clock_enable(S_clock_enable),
        .O_host_time(S_host_time),
        .O_video_time(S_video_time),
        .O_deadline_quarantined(S_deadline_fault),
        .O_prepare_target(S_prepare_target)
    );

    wire  S_m_O_cmd_ready;
    wire  S_m_O_result_valid;
    wire [3:0] S_m_O_result_error;
    wire [2:0] S_m_O_result_op;
    wire [2:0] S_m_O_result_slot;
    wire [1:0] S_m_O_result_owner;
    wire [31:0] S_m_O_result_token;
    wire [31:0] S_m_O_result_generation;
    wire [20:0] S_m_O_result_base;
    wire [17:0] S_m_O_slot_states;
    wire [191:0] S_m_O_slot_tokens;
    wire [191:0] S_m_O_slot_generations;
    wire [191:0] S_m_O_slot_assets;
    wire [17:0] S_m_O_slot_layouts;
    wire [17:0] S_m_O_slot_readers;
    wire [11:0] S_m_O_slot_rotations;
    wire [5:0] S_m_O_slot_resident;
    wire [5:0] S_m_O_slot_stale;
    wire [5:0] S_m_O_cancel_loading;
    wire  S_m_O_token_exhausted;
    fb_slot_manager u_fb_slot_manager (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(32'd11),
        .I_cmd_valid(S_fixture ? S_f_valid : (S_d_O_slot_cmd_valid && S_cmd_gate)),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_fixture ? S_f_op : S_d_O_slot_cmd_op),
        .I_cmd_slot(S_fixture ? S_f_slot : S_d_O_slot_cmd_slot),
        .I_cmd_owner(S_fixture ? 2'd2 : S_d_O_slot_cmd_owner),
        .I_cmd_token(S_fixture ? S_f_token : S_d_O_slot_cmd_token),
        .I_cmd_generation(S_fixture ? (S_f_slot==5 ? 32'd77 : 32'd11) : S_d_O_slot_cmd_generation),
        .I_cmd_asset(32'd9),
        .I_cmd_layout(3'd0),
        .I_cmd_rotation(2'd0),
        .I_cmd_resident(S_fixture && S_f_slot==5),
        .I_cmd_success(1'b1),
        .I_producer_retired(1'b1),
        .I_memory_retired(1'b1),
        .I_reader_retired(S_fixture ? 1'b1 : S_d_O_slot_reader_retired),
        .I_frame_boundary(S_fixture ? 1'b1 : S_d_O_slot_frame_boundary),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_fixture ? S_f_result_ready : S_d_O_slot_result_ready),
        .O_result_error(S_m_O_result_error),
        .O_result_op(S_m_O_result_op),
        .O_result_slot(S_m_O_result_slot),
        .O_result_owner(S_m_O_result_owner),
        .O_result_token(S_m_O_result_token),
        .O_result_generation(S_m_O_result_generation),
        .O_result_base(S_m_O_result_base),
        .O_slot_states(S_m_O_slot_states),
        .O_slot_tokens(S_m_O_slot_tokens),
        .O_slot_generations(S_m_O_slot_generations),
        .O_slot_assets(S_m_O_slot_assets),
        .O_slot_layouts(S_m_O_slot_layouts),
        .O_slot_readers(S_m_O_slot_readers),
        .O_slot_rotations(S_m_O_slot_rotations),
        .O_slot_resident(S_m_O_slot_resident),
        .O_slot_stale(S_m_O_slot_stale),
        .O_cancel_loading(S_m_O_cancel_loading),
        .O_token_exhausted(S_m_O_token_exhausted)
    );

    task fail;
        input [767:0] message;
        begin $display("FAIL: resource pipeline case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #2000000000; fail("watchdog timeout"); end
    function [20:0] slot_base;
        input [2:0] slot;
        begin case(slot)
            0:slot_base=21'h000000; 1:slot_base=21'h04b000; 2:slot_base=21'h096000;
            3:slot_base=21'h0e1000; 4:slot_base=21'h12c000; 5:slot_base=21'h177000;
            default:slot_base=21'h1fffff;
        endcase end
    endfunction
    function [69-1:0] source_lease;
        input [137:0] leases;
        input source;
        begin source_lease={leases[136+source],leases[130+source*3+:3],leases[66+source*32+:32],
            leases[2+source*32+:32],leases[source]}; end
    endfunction
    function [246:0] make_config;
        input [1:0] mask;
        input from_source;
        input [2:0] a,b;
        input [16:0] progress;
        input [1:0] banks;
        input audio;
        begin make_config={mask,from_source,{b,a},{S_tokens[b],S_tokens[a]},
            {(b==5 ? 32'd77 : 32'd11),(a==5 ? 32'd77 : 32'd11)},
            {(b==5),(a==5)},3'd0,16'd60,progress,4'd0,4'd0,5'd8,3'd0,2'd0,1'b0,audio,
            18'd0,banks,32'hc202c101}; end
    endfunction
    task fixture_cmd;
        input [2:0] op,slot;
        begin
            @(negedge S_host_clk); S_f_op=op; S_f_slot=slot; S_f_token=op==0 ? 0 : S_tokens[slot]; S_f_valid=1;
            @(posedge S_host_clk); while(!S_m_O_cmd_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_f_valid=0; wait(S_m_O_result_valid); #1;
            if(S_m_O_result_error!=0) fail("slot loading fixture failed");
            if(op==0) S_tokens[slot]=S_m_O_result_token;
            @(negedge S_host_clk); S_f_result_ready=1; @(negedge S_host_clk); S_f_result_ready=0;
        end
    endtask
    task reset_all;
        integer slot;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_fixture=1; S_f_valid=0; S_f_result_ready=0;
            S_d_I_start_valid=0; S_d_I_done_ready=0; S_d_I_abort=0;
            S_d_I_video_allow_apply=1; S_d_I_video_abort=0;
            S_clock_enable=1; S_d_I_scan_stop=0;
            S_cmd_gate=1; S_media_valid=1; S_mem_enable=3; S_mem_error=0;
            S_expect_fault=0; S_check_pixels=0; S_previous_video_leases=0;
            repeat(6) @(negedge S_video_clk); S_reset=0; wait(!S_host_reset);
            for(slot=0;slot<6;slot=slot+1) begin fixture_cmd(0,slot); fixture_cmd(1,slot); end
            @(negedge S_host_clk); S_fixture=0;
            wait(S_d_O_start_ready);
            S_commands=0; S_publishes=0; S_applies=0; S_pixels=0; S_frames=0;
            S_mem_counts[0]=0; S_mem_counts[1]=0;
        end
    endtask
    task choose_free_banks;
        input [1:0] mask;
        reg [3:0] occupied;
        begin
            occupied=15;
            while((mask[0] && occupied[1:0]==3) || (mask[1] && occupied[3:2]==3)) begin
                @(negedge S_video_clk);
                occupied=u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_r_O_bank_reserved |
                    u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_s_O_owned_banks |
                    u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_a_O_task_reserved;
            end
            S_next_banks={occupied[2],occupied[0]};
        end
    endtask
    task start;
        input [246:0] payload;
        input [15:0] tag;
        begin
            @(negedge S_host_clk); S_d_I_config=payload; S_d_I_tag=tag; S_d_I_start_valid=1;
            @(posedge S_host_clk); while(!S_d_O_start_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_d_I_start_valid=0; S_d_I_config=0; S_d_I_tag=0;
        end
    endtask
    task result;
        input [3:0] error;
        input [1:0] owned,acquired,released;
        input applied;
        reg [110:0] saved;
        begin
            wait(S_d_O_done_valid); #1;
            if(S_d_O_error!==error || S_d_O_owned!==owned || S_d_O_acquired_mask!==acquired ||
                S_d_O_released_mask!==released || S_d_O_applied!==applied || S_d_O_host_quarantined || S_d_O_video_quarantined)
                fail("terminal disagrees with real slot/lease/commit facts");
            if(S_d_O_host_reserve!=0 || S_d_O_source_busy!=0) fail("terminal preceded guard four phase clear");
            if(S_d_O_video_leases!=={S_d_O_lease_valid,S_d_O_lease_slots,S_d_O_lease_tokens,
                S_d_O_lease_generations,S_d_O_lease_resident}) fail("terminal preceded real lease snapshot installation");
            if(applied && (S_d_O_host_active_epoch!==S_d_O_video_active_epoch ||
                S_d_O_host_active_config!==S_d_O_video_active_config)) fail("host success preceded actual local install");
            saved={S_d_O_error,S_d_O_lease_error,S_d_O_slot_error,S_d_O_commit_error,S_d_O_prepare_error,S_d_O_retire_error,
                S_d_O_tag,S_d_O_epoch,S_d_O_previous_epoch,S_d_O_acquired_mask,S_d_O_released_mask,
                S_d_O_applied,S_d_O_retired,S_d_O_cancel_late};
            repeat(8) begin @(negedge S_host_clk);
                if(!S_d_O_done_valid || S_d_O_start_ready || saved!=={S_d_O_error,S_d_O_lease_error,S_d_O_slot_error,
                    S_d_O_commit_error,S_d_O_prepare_error,S_d_O_retire_error,S_d_O_tag,S_d_O_epoch,S_d_O_previous_epoch,
                    S_d_O_acquired_mask,S_d_O_released_mask,S_d_O_applied,S_d_O_retired,S_d_O_cancel_late})
                    fail("result payload not held under backpressure");
            end
            S_d_I_done_ready=1; @(negedge S_host_clk); S_d_I_done_ready=0;
        end
    endtask
    task complete_frame;
        begin
            wait(S_d_O_frame_start); @(negedge S_video_clk); S_pixels=0;
            S_frame_epoch=S_d_O_video_active_epoch; S_check_pixels=1;
            @(negedge S_video_clk); wait(S_d_O_frame_start); @(negedge S_video_clk); #1; S_check_pixels=0;
            if(S_pixels!=307200) fail("complete real scanout frame pixel coverage");
        end
    endtask
    always @(posedge S_host_clk) if(!S_reset && !S_host_reset) begin
        if(u_timed.u_display_resource_pipeline.S_o_O_publish_valid && u_timed.u_display_resource_pipeline.S_l_O_publish_ready) begin
            S_last_publish=u_timed.u_display_resource_pipeline.S_o_O_publish_leases; S_last_version=u_timed.u_display_resource_pipeline.S_o_O_publish_version;
            S_publishes=S_publishes+1;
        end
        if(S_d_O_slot_cmd_valid && S_d_O_slot_cmd_owner<2 && S_m_O_cmd_ready && S_cmd_gate && !S_fixture) begin
            S_commands=S_commands+1;
            if(!S_d_O_host_reserve[S_d_O_slot_cmd_owner[0]] || !S_d_O_source_block[S_d_O_slot_cmd_owner[0]] ||
                S_d_O_source_in_use[S_d_O_slot_cmd_owner[0]]) fail("slot mutation escaped actual source reservation");
            if(S_d_O_slot_cmd_op==2 && !S_d_O_slot_frame_boundary) fail("acquire bypassed real frame permission");
            if(S_d_O_slot_cmd_op==3 && (!S_d_O_slot_reader_retired ||
                !S_d_O_reader_retire_ack[S_d_O_slot_cmd_owner[0]] ||
                !S_d_O_source_owner_retired[S_d_O_slot_cmd_owner[0]] ||
                !S_d_O_source_pipeline_retired[S_d_O_slot_cmd_owner[0]]))
                fail("release bypassed real reader/owner/pixel retirement");
        end
        for(S_i=0;S_i<2;S_i=S_i+1) if(S_d_O_mem_valid[S_i] && S_mem_enable[S_i]) begin
            S_mem_counts[S_i]=S_mem_counts[S_i]+1;
            if(!S_d_O_lease_valid[S_i] || S_d_O_mem_token[S_i*32+:32]!==S_d_O_lease_tokens[S_i*32+:32] ||
                S_d_O_mem_generation[S_i*32+:32]!==S_d_O_lease_generations[S_i*32+:32] ||
                S_d_O_mem_addr[S_i*21+:21]<slot_base(S_d_O_lease_slots[S_i*3+:3]) ||
                S_d_O_mem_addr[S_i*21+:21]>=slot_base(S_d_O_lease_slots[S_i*3+:3])+307200)
                fail("memory request lost real host lock identity or slot extent");
        end
        #1; if(!S_expect_fault && S_d_O_host_quarantined) fail("unexpected host isolation");
    end
    always @(posedge S_video_clk) if(!S_reset && u_timed.u_display_resource_pipeline.S_c_O_apply_valid) begin
        if(!S_d_O_frame_start || !u_timed.u_display_resource_pipeline.S_p_O_can_apply ||
            !u_timed.u_display_resource_pipeline.u_display_video_pipeline.u_scanout_engine.S_install ||
            !u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_c_O_adopt_ready)
            fail("apply did not atomically install scanout and adopt all seeds");
        if(S_d_O_pending_config[52] && (!S_d_I_audio_ready || S_d_I_audio_epoch!==S_d_O_pending_epoch))
            fail("audio-required apply lacked matching audio epoch");
        S_seed_mask=0;
        if(S_d_O_pending_config[245]) S_seed_mask[S_d_O_pending_config[32]]=1;
        if(S_d_O_pending_config[246]) S_seed_mask[2+S_d_O_pending_config[33]]=1;
        S_saved_epoch=S_d_O_pending_epoch;
        #1;
        if(S_d_O_video_active_epoch!==S_saved_epoch || u_timed.u_display_resource_pipeline.S_c_O_active_epoch!==S_saved_epoch ||
            !S_d_O_local_applied || !u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_c_O_adopted ||
            (u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_s_O_owned_banks & S_seed_mask)!==S_seed_mask ||
            u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_c_O_owned_banks!=0)
            fail("partial seed ownership or delayed local epoch installation");
        S_applies=S_applies+1;
    end
    always @(negedge S_video_clk) if(!S_reset) begin
        if(!S_expect_fault && (S_d_O_video_quarantined || S_d_O_pixel_fault)) fail("unexpected video/pixel isolation");
        if(S_d_O_frame_start) S_frames=S_frames+1;
        if(S_check_pixels && S_d_O_valid && S_d_O_de) begin
            if(S_d_O_rgb!==24'h336699 || S_d_O_pixel_epoch!==S_frame_epoch || S_d_O_repeated)
                fail("real leased pixel/epoch continuity");
            S_pixels=S_pixels+1;
        end
        if((S_d_O_reader_stop & S_d_O_source_in_use)!=0) fail("reader stopped a source still in real use");
        if(u_timed.u_display_resource_pipeline.S_l_O_video_installed) begin
            if(S_d_O_video_leases!==S_last_publish || S_d_O_video_lease_version!==S_last_version)
                fail("real publication changed accepted snapshot");
            for(S_v_i=0;S_v_i<2;S_v_i=S_v_i+1)
                if(source_lease(S_d_O_video_leases,S_v_i)!==source_lease(S_previous_video_leases,S_v_i) &&
                    (!S_d_O_source_block[S_v_i] || S_d_O_source_in_use[S_v_i] ||
                    !S_d_O_source_owner_retired[S_v_i] || !S_d_O_source_pipeline_retired[S_v_i]))
                    fail("lease installed before actual source proof");
            S_previous_video_leases=S_d_O_video_leases;
        end
    end
    reg [31:0] S_last_prepare_deadline=0;
    integer S_real_deadlines=0;
    always @(posedge S_video_clk) if(!S_reset) begin
        if(u_timed.u_display_resource_pipeline.u_display_video_pipeline.u_scanout_engine.C_new_task) begin
            if(!u_timed.S_s_O_scan_deadline_valid || u_timed.S_s_O_scan_deadline==32'h7fffffff ||
                u_timed.S_s_O_scan_deadline_epoch!==S_d_O_video_active_epoch ||
                u_timed.S_s_O_scan_deadline_y!==S_d_O_prefetch_y)
                fail("real scanout task bypassed converted row/epoch deadline");
        end
        if(u_timed.u_display_resource_pipeline.u_display_video_pipeline.S_prepare_fire) begin
            if(!u_timed.S_s_O_prepare_deadline_valid ||
                u_timed.S_s_O_prepare_deadline_epoch!==S_d_O_pending_epoch ||
                u_timed.S_s_O_prepare_deadlines[31:0]==32'h7fffffff)
                fail("actual prepare retained a constant or mismatched deadline");
            S_last_prepare_deadline=u_timed.S_s_O_prepare_deadlines[31:0];
            S_real_deadlines=S_real_deadlines+1;
        end
        if(u_timed.u_display_resource_pipeline.S_c_O_apply_valid &&
            (!u_timed.S_s_O_allow_apply || S_video_time!==S_prepare_target))
            fail("configuration applied outside the selected real deadline target frame");
    end
    initial begin
        S_case=1; audio_defaults; reset_all;
        start(make_config(1,0,0,1,0,0,1),16'h6001); wait(S_d_O_pending_valid);
        S_saved_epoch=S_frames;
        while(S_frames<S_saved_epoch+2) begin @(negedge S_video_clk);
            if(S_d_O_done_valid || S_applies!=0 || S_d_I_audio_ready) fail("display fabricated readiness without real WAV metadata"); end
        open_file(0,12,0,16'hf123); send_range(0,0,72);
        wait(S_a_O_track_known[0] && u_prepared.S_level[4:0]==7);
        bind_track(0,0,S_a_O_track_serials[31:0],0,0);
        S_saved_epoch=S_frames;
        while(S_frames<S_saved_epoch+1) begin @(negedge S_video_clk);
            if(S_applies!=0 || S_d_I_audio_ready) fail("display accepted incomplete real prefill"); end
        send_range(0,72,S_audio_lengths[0]); wait(S_d_I_audio_ready);
        result(0,1,1,0,1); complete_frame;
        if(S_audio_accepts!=1 || S_a_O_bound || S_a_O_binding_revoked || S_d_O_und_count!=0)
            fail("actual applied frame did not consume matching real audio proof");

        S_case=2; audio_defaults; reset_all;
        S_d_I_video_allow_apply=0;
        start(make_config(1,0,0,1,0,0,1),16'h6002); wait(S_d_O_pending_valid);
        open_file(0,8,1,16'hf124); send_range(0,0,76); wait(S_a_O_track_known[0]);
        bind_track(0,0,S_a_O_track_serials[31:0],0,0); wait(S_d_I_audio_ready);
        S_a_I_event_ready=0; send_range(0,76,S_audio_lengths[0]); wait(S_a_O_failed[0]);
        repeat(3) @(negedge S_video_clk); S_d_I_video_allow_apply=1;
        S_saved_epoch=S_frames;
        while(S_frames<S_saved_epoch+2) begin @(negedge S_video_clk);
            if(S_d_O_done_valid || S_applies!=0 || S_d_I_audio_ready)
                fail("late real WAV error retained display apply permission"); end
        if(!S_a_O_binding_revoked || S_a_O_prepare_quarantined) fail("ordinary WAV error lost revocation or wrongly isolated protocol");
        S_a_I_event_ready=3; @(negedge S_host_clk); S_d_I_abort=1;
        result(3,0,1,1,0); S_d_I_abort=0; unbind;

        S_case=3; audio_defaults; reset_all;
        // Short complete tail is below prefill but actually visible in the FIFO.
        load_full(0,3,16'hf125);
        start(make_config(1,0,0,1,0,0,1),16'h6003); wait(S_d_O_pending_valid);
        bind_track(0,0,S_a_O_track_serials[31:0],0,0); result(0,1,1,0,1); complete_frame;
        if(S_audio_accepts!=1 || S_d_O_und_count!=0 || S_a_O_audio_accepted_tag!=16'h6003)
            fail("real short-tail preparation did not join complete timed display frame");
        $display("PASS: real WAV readiness and lifetime binding with actual timed display commit/retirement/frame");
        S_test_pass=1; $finish;
    end
endmodule
