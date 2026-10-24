`timescale 1ns/1ps
// Actual timeline, reference raster, identified executor/audio ownership protocol peers.
module tb_playback_transition_owner;
    wire S_silence_u_owner_O_silence_valid;
    reg S_clk=0,S_run=1,S_reset=0,S_test_pass=0;
    always #20 if(S_run) S_clk=~S_clk;
    reg [31:0] S_time=0;
    reg [18:0] S_raster=0;
    wire S_frame_start=S_raster==0 && !S_reset;
    always @(posedge S_clk or posedge S_reset)
        if(S_reset) begin S_time<=0; S_raster<=0; end
        else begin S_time<=S_time+1'b1; S_raster<=S_raster==419999 ? 0 : S_raster+1'b1; end
    reg S_d_I_clock_enable=0;
    reg S_d_I_sample_tick=0;
    reg S_d_I_start_valid=0;
    wire S_d_O_start_ready;
    reg [31:0] S_d_I_epoch=0;
    reg [15:0] S_d_I_tag=0;
    reg [246:0] S_d_I_config=0;
    reg [2:0] S_d_I_effect=0;
    reg [15:0] S_d_I_duration_frames=0;
    reg signed [6:0] S_d_I_av_offset_steps=0;
    reg [1:0] S_d_I_audio_action=0;
    reg S_d_I_audio_slot=0;
    reg [15:0] S_d_I_track_epoch=0;
    reg [31:0] S_d_I_track_serial=0;
    reg [31:0] S_d_I_start_index=0;
    reg [137:0] S_d_I_images=0;
    reg [137:0] S_d_I_display_leases=0;
    reg S_d_I_pause=0;
    reg S_d_I_abort=0;
    wire S_d_O_pause_allow;
    wire [1:0] S_d_O_image_hold;
    wire [1:0] S_d_O_audio_hold;
    wire [246:0] S_d_O_frozen_config;
    wire S_d_O_audio_bind_valid;
    reg S_d_I_audio_bind_ready=0;
    wire [31:0] S_d_O_audio_bind_epoch;
    wire [15:0] S_d_O_audio_bind_tag;
    wire S_d_O_audio_bind_slot;
    wire [15:0] S_d_O_audio_bind_track_epoch;
    wire [31:0] S_d_O_audio_bind_serial;
    wire [31:0] S_d_O_audio_bind_index;
    wire S_d_O_audio_bind_reuse;
    wire S_d_O_audio_pending;
    wire S_d_O_audio_unbind;
    reg S_d_I_audio_bound=0;
    reg [3:0] S_d_I_audio_bind_error=0;
    reg S_d_I_audio_ready=0;
    reg [31:0] S_d_I_audio_epoch=0;
    reg [1:0] S_d_I_track_known=0;
    reg [1:0] S_d_I_track_enabled=0;
    reg [1:0] S_d_I_track_consumed=0;
    reg [31:0] S_d_I_track_epochs=0;
    reg [63:0] S_d_I_track_serials=0;
    reg [63:0] S_d_I_track_totals=0;
    reg [63:0] S_d_I_track_next_index=0;
    wire S_d_O_play_valid;
    wire S_d_O_fade_valid;
    wire S_d_O_target_b;
    reg S_d_I_play_ready=0;
    reg S_d_I_fade_ready=0;
    reg S_d_I_fade_done=0;
    reg S_d_I_active_b=0;
    wire S_d_O_audio_stop_request;
    reg S_d_I_audio_stop_ack=0;
    wire S_d_O_event_valid;
    reg S_d_I_event_ready=0;
    wire S_d_O_event_cancel;
    wire [31:0] S_d_O_event_epoch;
    wire [15:0] S_d_O_event_tag;
    wire [15:0] S_d_O_event_index;
    wire [2:0] S_d_O_event_effect;
    wire [16:0] S_d_O_event_progress;
    wire [31:0] S_d_O_event_target;
    wire [246:0] S_d_O_event_config;
    reg S_d_I_event_busy=0;
    reg S_d_I_event_done_valid=0;
    wire S_d_O_event_done_ready;
    reg [31:0] S_d_I_event_done_epoch=0;
    reg [15:0] S_d_I_event_done_tag=0;
    reg [15:0] S_d_I_event_done_index=0;
    reg [3:0] S_d_I_event_done_error=0;
    reg S_d_I_event_done_applied=0;
    reg S_d_I_event_done_retired=0;
    reg [31:0] S_d_I_event_done_time=0;
    reg [31:0] S_d_I_event_commit_epoch=0;
    reg S_d_I_event_quarantined=0;
    reg S_d_I_active_valid=0;
    reg [246:0] S_d_I_active_config=0;
    reg [31:0] S_d_I_active_epoch=0;
    reg [15:0] S_d_I_active_tag=0;
    reg S_d_I_recover_valid=0;
    reg S_d_I_recover_source=0;
    wire S_d_O_recover_ready;
    wire S_d_O_busy;
    wire S_d_O_done_valid;
    reg S_d_I_done_ready=0;
    wire [31:0] S_d_O_epoch;
    wire [15:0] S_d_O_tag;
    wire [3:0] S_d_O_error;
    wire [3:0] S_d_O_timeline_error;
    wire [3:0] S_d_O_settle_error;
    wire [3:0] S_d_O_bind_error;
    wire S_d_O_settled;
    wire S_d_O_recovery_required;
    wire S_d_O_recovery_result;
    wire S_d_O_cancel_late;
    wire S_d_O_selected_source;
    wire S_d_O_video_started;
    wire S_d_O_video_finished;
    wire S_d_O_audio_started;
    wire S_d_O_audio_finished;
    wire [31:0] S_d_O_actual_start;
    wire [31:0] S_d_O_actual_midpoint;
    wire [31:0] S_d_O_actual_audio;
    wire [31:0] S_d_O_dwell_start;
    wire [31:0] S_d_O_settle_time;
    wire [31:0] S_d_O_commit_epoch;
    wire signed [31:0] S_d_O_anchor_error;
    wire [16:0] S_d_O_last_progress;
    wire S_d_O_quarantined;
    wire S_d_O_response_discarded;
    playback_transition_owner u_owner (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_clock_enable(S_d_I_clock_enable),
        .I_time(S_time),
        .I_frame_start(S_frame_start),
        .I_sample_tick(S_d_I_sample_tick),
        .I_start_valid(S_d_I_start_valid),
        .O_start_ready(S_d_O_start_ready),
        .I_epoch(S_d_I_epoch),
        .I_tag(S_d_I_tag),
        .I_config(S_d_I_config),
        .I_effect(S_d_I_effect),
        .I_duration_frames(S_d_I_duration_frames),
        .I_av_offset_steps(S_d_I_av_offset_steps),
        .I_audio_action(S_d_I_audio_action),
        .I_audio_slot(S_d_I_audio_slot),
        .I_track_epoch(S_d_I_track_epoch),
        .I_track_serial(S_d_I_track_serial),
        .I_start_index(S_d_I_start_index),
        .I_images(S_d_I_images),
        .I_display_leases(S_d_I_display_leases),
        .I_pause(S_d_I_pause),
        .I_abort(S_d_I_abort),
        .O_pause_allow(S_d_O_pause_allow),
        .O_image_hold(S_d_O_image_hold),
        .O_audio_hold(S_d_O_audio_hold),
        .O_frozen_config(S_d_O_frozen_config),
        .O_audio_bind_valid(S_d_O_audio_bind_valid),
        .I_audio_bind_ready(S_d_I_audio_bind_ready),
        .O_audio_bind_epoch(S_d_O_audio_bind_epoch),
        .O_audio_bind_tag(S_d_O_audio_bind_tag),
        .O_audio_bind_slot(S_d_O_audio_bind_slot),
        .O_audio_bind_track_epoch(S_d_O_audio_bind_track_epoch),
        .O_audio_bind_serial(S_d_O_audio_bind_serial),
        .O_audio_bind_index(S_d_O_audio_bind_index),
        .O_audio_bind_reuse(S_d_O_audio_bind_reuse),
        .O_audio_pending(S_d_O_audio_pending),
        .O_audio_unbind(S_d_O_audio_unbind),
        .I_audio_bound(S_d_I_audio_bound),
        .I_audio_bind_error(S_d_I_audio_bind_error),
        .I_audio_ready(S_d_I_audio_ready),
        .I_audio_epoch(S_d_I_audio_epoch),
        .I_track_known(S_d_I_track_known),
        .I_track_enabled(S_d_I_track_enabled),
        .I_track_consumed(S_d_I_track_consumed),
        .I_track_epochs(S_d_I_track_epochs),
        .I_track_serials(S_d_I_track_serials),
        .I_track_totals(S_d_I_track_totals),
        .I_track_next_index(S_d_I_track_next_index),
        .O_play_valid(S_d_O_play_valid),
        .O_fade_valid(S_d_O_fade_valid),
        .O_target_b(S_d_O_target_b),
        .I_play_ready(S_d_I_play_ready),
        .I_fade_ready(S_d_I_fade_ready),
        .I_fade_done(S_d_I_fade_done),
        .I_active_b(S_d_I_active_b),
        .O_audio_stop_request(S_d_O_audio_stop_request),
        .I_audio_stop_ack(S_d_I_audio_stop_ack),
        .O_event_valid(S_d_O_event_valid),
        .I_event_ready(S_d_I_event_ready),
        .O_event_cancel(S_d_O_event_cancel),
        .O_event_epoch(S_d_O_event_epoch),
        .O_event_tag(S_d_O_event_tag),
        .O_event_index(S_d_O_event_index),
        .O_event_effect(S_d_O_event_effect),
        .O_event_progress(S_d_O_event_progress),
        .O_event_target(S_d_O_event_target),
        .O_event_config(S_d_O_event_config),
        .I_event_busy(S_d_I_event_busy),
        .I_event_done_valid(S_d_I_event_done_valid),
        .O_event_done_ready(S_d_O_event_done_ready),
        .I_event_done_epoch(S_d_I_event_done_epoch),
        .I_event_done_tag(S_d_I_event_done_tag),
        .I_event_done_index(S_d_I_event_done_index),
        .I_event_done_error(S_d_I_event_done_error),
        .I_event_done_applied(S_d_I_event_done_applied),
        .I_event_done_retired(S_d_I_event_done_retired),
        .I_event_done_time(S_d_I_event_done_time),
        .I_event_commit_epoch(S_d_I_event_commit_epoch),
        .I_event_quarantined(S_d_I_event_quarantined),
        .I_active_valid(S_d_I_active_valid),
        .I_active_config(S_d_I_active_config),
        .I_active_epoch(S_d_I_active_epoch),
        .I_active_tag(S_d_I_active_tag),
        .I_recover_valid(S_d_I_recover_valid),
        .I_recover_source(S_d_I_recover_source),
        .O_recover_ready(S_d_O_recover_ready),
        .O_busy(S_d_O_busy),
        .O_done_valid(S_d_O_done_valid),
        .I_done_ready(S_d_I_done_ready),
        .O_epoch(S_d_O_epoch),
        .O_tag(S_d_O_tag),
        .O_error(S_d_O_error),
        .O_timeline_error(S_d_O_timeline_error),
        .O_settle_error(S_d_O_settle_error),
        .O_bind_error(S_d_O_bind_error),
        .O_settled(S_d_O_settled),
        .O_recovery_required(S_d_O_recovery_required),
        .O_recovery_result(S_d_O_recovery_result),
        .O_cancel_late(S_d_O_cancel_late),
        .O_selected_source(S_d_O_selected_source),
        .O_video_started(S_d_O_video_started),
        .O_video_finished(S_d_O_video_finished),
        .O_audio_started(S_d_O_audio_started),
        .O_audio_finished(S_d_O_audio_finished),
        .O_actual_start(S_d_O_actual_start),
        .O_actual_midpoint(S_d_O_actual_midpoint),
        .O_actual_audio(S_d_O_actual_audio),
        .O_dwell_start(S_d_O_dwell_start),
        .O_settle_time(S_d_O_settle_time),
        .O_commit_epoch(S_d_O_commit_epoch),
        .O_anchor_error(S_d_O_anchor_error),
        .O_last_progress(S_d_O_last_progress),
        .O_quarantined(S_d_O_quarantined),
        .O_response_discarded(S_d_O_response_discarded),
        .O_silence_valid(S_silence_u_owner_O_silence_valid),
        .I_silence_ready(1'b0),
        .I_silence_started(1'b0),
        .I_silence_done(1'b0)
    );
    integer S_case=0,S_events=0,S_settles=0;
    reg S_accept=1,S_retire=1,S_install_leases=1,S_auto_apply=1,S_peer_active=0,S_peer_applied=0,S_peer_cancel=0;
    reg [31:0] S_peer_epoch=0,S_peer_target=0,S_peer_time=0,S_next_commit=1,S_peer_commit=0;
    reg [15:0] S_peer_tag=0,S_peer_index=0;
    reg [246:0] S_peer_config=0,S_saved_config=0;
    reg [3:0] S_peer_error=0;
    reg S_bind_gate=1,S_bind_failure=0,S_audio_gate=1;
    reg [4:0] S_tick_div=0;
    integer S_fade_ticks=0;
    reg [196:0] S_saved_result=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: transition owner case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin repeat(6) #1000000000; fail("watchdog timeout"); end
    function [137:0] image_proof;
        input [246:0] cfg;
        input [1:0] mask;
        begin image_proof={mask,cfg[243:238],cfg[237:174],cfg[173:110],cfg[109:108]}; end
    endfunction
    always @* begin
        S_d_I_event_ready=S_accept && !S_peer_active && !S_d_I_event_done_valid;
        S_d_I_audio_bind_ready=S_bind_gate && !S_d_I_audio_bound && !S_d_O_audio_unbind;
        S_d_I_play_ready=S_audio_gate && !S_d_I_track_enabled[0];
        S_d_I_fade_ready=S_audio_gate && S_fade_ticks==0;
        S_d_I_sample_tick=S_tick_div==16;
    end
    // This is an explicit protocol executor, never a substitute for real display tests.
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin
            S_peer_active<=0; S_peer_applied<=0; S_peer_cancel<=0; S_d_I_event_busy<=0;
            S_d_I_event_done_valid<=0; S_next_commit<=1; S_events<=0; S_settles<=0;
            S_d_I_active_valid<=0; S_d_I_active_config<=0; S_d_I_active_epoch<=0; S_d_I_active_tag<=0;
            S_d_I_display_leases<=0;
        end else begin
            if(S_d_O_event_valid && S_d_I_event_ready) begin
                S_peer_active<=1; S_d_I_event_busy<=1; S_peer_applied<=0; S_peer_cancel<=0;
                S_peer_epoch<=S_d_O_event_epoch; S_peer_tag<=S_d_O_event_tag; S_peer_index<=S_d_O_event_index;
                S_peer_target<=S_d_O_event_target; S_peer_config<=S_d_O_event_config;
                S_peer_config[107:105]<=S_d_O_event_effect; S_peer_config[88:72]<=S_d_O_event_progress;
                S_peer_config[33:32]<=0; S_peer_config[31:0]<={S_d_O_event_tag,S_d_O_event_tag};
                S_peer_commit<=S_next_commit; S_next_commit<=S_next_commit+1'b1;
                if(S_d_O_event_index==16'hffff) S_settles<=S_settles+1;
                else S_events<=S_events+1;
            end
            if(S_peer_active && S_d_O_event_cancel && !S_peer_applied) S_peer_cancel<=1;
            if(S_peer_active && !S_peer_applied && !S_peer_cancel && !S_d_O_event_cancel && S_auto_apply &&
                S_frame_start && S_time>=S_peer_target && S_d_I_clock_enable) begin
                S_peer_applied<=1; S_peer_time<=S_time;
                S_d_I_active_valid<=1; S_d_I_active_config<=S_peer_config;
                S_d_I_active_epoch<=S_peer_commit; S_d_I_active_tag<=S_peer_tag;
            end
            if(S_peer_active && !S_d_I_event_done_valid && S_retire &&
                (S_peer_applied || S_peer_cancel)) begin
                S_d_I_event_done_valid<=1;
                S_d_I_event_done_epoch<=S_peer_epoch; S_d_I_event_done_tag<=S_peer_tag; S_d_I_event_done_index<=S_peer_index;
                S_d_I_event_done_error<=S_peer_cancel ? 4'd3 : S_peer_error;
                S_d_I_event_done_applied<=S_peer_applied; S_d_I_event_done_retired<=1;
                S_d_I_event_done_time<=S_peer_time; S_d_I_event_commit_epoch<=S_peer_commit;
                if(S_peer_applied && S_install_leases) S_d_I_display_leases<=image_proof(S_peer_config,S_peer_config[246:245]);
            end
            if(S_d_I_event_done_valid && S_d_O_event_done_ready) begin
                S_d_I_event_done_valid<=0; S_peer_active<=0; S_d_I_event_busy<=0;
            end
        end
    end
    // Sample ticks are accelerated solely for audio ownership protocol cases.
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin
            S_tick_div<=0; S_d_I_audio_bound<=0; S_d_I_audio_ready<=0; S_d_I_audio_epoch<=0;
            S_d_I_audio_bind_error<=0; S_d_I_track_enabled<=0; S_d_I_track_consumed<=0;
            S_d_I_track_next_index<=0; S_d_I_audio_stop_ack<=0; S_d_I_fade_done<=0;
            S_d_I_active_b<=0; S_fade_ticks<=0;
        end else begin
            S_tick_div<=S_tick_div==16 ? 0 : S_tick_div+1'b1;
            S_d_I_audio_bind_error<=0; S_d_I_track_consumed<=0; S_d_I_fade_done<=0;
            if(S_d_O_audio_bind_valid && S_d_I_audio_bind_ready) begin
                if(S_bind_failure) S_d_I_audio_bind_error<=3;
                else begin S_d_I_audio_bound<=1; S_d_I_audio_epoch<=S_d_O_audio_bind_epoch; S_d_I_audio_ready<=1; end
            end
            if(S_d_O_audio_unbind) begin S_d_I_audio_bound<=0; S_d_I_audio_ready<=0; end
            if(S_d_O_play_valid && S_d_I_play_ready) begin S_d_I_track_enabled[0]<=1; S_d_I_audio_ready<=0; end
            if(S_d_O_fade_valid && S_d_I_fade_ready) begin
                S_d_I_track_enabled[S_d_O_target_b]<=1; S_fade_ticks<=4; S_d_I_audio_ready<=0;
            end
            if(S_d_I_sample_tick) begin
                if(S_d_I_track_enabled[0]) begin
                    S_d_I_track_consumed[0]<=1; S_d_I_track_next_index[31:0]<=S_d_I_track_next_index[31:0]+1'b1;
                end
                if(S_d_I_track_enabled[1]) begin
                    S_d_I_track_consumed[1]<=1; S_d_I_track_next_index[63:32]<=S_d_I_track_next_index[63:32]+1'b1;
                end
                if(S_fade_ticks>0) begin
                    S_fade_ticks<=S_fade_ticks-1;
                    if(S_fade_ticks==1) begin S_d_I_fade_done<=1; S_d_I_active_b<=S_d_O_target_b; end
                end
            end
            if(S_d_O_audio_stop_request) begin S_d_I_audio_stop_ack<=1; S_d_I_track_enabled<=0; S_fade_ticks<=0; end
            else S_d_I_audio_stop_ack<=0;
        end
    end
    task reset_all;
        begin
            S_run=1; S_reset=1; S_accept=1; S_retire=1; S_install_leases=1; S_auto_apply=1;
            S_peer_error=0; S_bind_gate=1; S_bind_failure=0; S_audio_gate=1;
            S_d_I_start_valid=0; S_d_I_done_ready=0; S_d_I_recover_valid=0;
            S_d_I_clock_enable=1; S_d_I_pause=0; S_d_I_abort=0; S_d_I_event_quarantined=0;
            S_d_I_audio_action=0; S_d_I_audio_slot=0; S_d_I_track_epoch=9; S_d_I_track_serial=11; S_d_I_start_index=0;
            S_d_I_track_known=3; S_d_I_track_epochs={16'd10,16'd9}; S_d_I_track_serials={32'd12,32'd11};
            S_d_I_track_totals={32'd1000000000,32'd1000000000};
            S_d_I_config={2'b11,1'b0,3'd1,3'd0,32'd22,32'd11,32'd4,32'd4,2'b00,
                3'd0,16'd2,17'd0,4'd0,4'd0,5'd8,3'd0,2'd0,1'b0,1'b0,18'd0,2'd0,32'd0};
            S_d_I_images=image_proof(S_d_I_config,3); S_d_I_effect=0; S_d_I_duration_frames=2; S_d_I_av_offset_steps=0;
            repeat(6) @(negedge S_clk); S_reset=0; wait(S_d_O_start_ready);
        end
    endtask
    task start;
        input [31:0] epoch;
        begin
            @(negedge S_clk); S_d_I_epoch=epoch; S_d_I_tag=16'h8100+epoch[15:0]; S_d_I_start_valid=1;
            @(posedge S_clk); while(!S_d_O_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_d_I_start_valid=0;
        end
    endtask
    task result;
        input [3:0] error;
        input settled,source,recovery;
        begin
            wait(S_d_O_done_valid); #1;
            if(S_d_O_error!==error || S_d_O_settled!==settled || S_d_O_recovery_required!==recovery ||
                (settled && (S_d_O_selected_source!==source || S_d_O_image_hold!==(2'b01<<source))))
                fail("owner terminal disagrees with actual single-source and lease facts");
            S_saved_result={S_d_O_epoch,S_d_O_tag,S_d_O_error,S_d_O_timeline_error,S_d_O_settle_error,S_d_O_bind_error,
                S_d_O_settled,S_d_O_recovery_required,S_d_O_cancel_late,S_d_O_image_hold,
                S_d_O_actual_start,S_d_O_dwell_start,S_d_O_settle_time,S_d_O_commit_epoch};
            S_d_I_abort=1;
            repeat(10) begin @(negedge S_clk);
                if(!S_d_O_done_valid || S_saved_result!=={S_d_O_epoch,S_d_O_tag,S_d_O_error,S_d_O_timeline_error,
                    S_d_O_settle_error,S_d_O_bind_error,S_d_O_settled,S_d_O_recovery_required,S_d_O_cancel_late,
                    S_d_O_image_hold,S_d_O_actual_start,S_d_O_dwell_start,S_d_O_settle_time,S_d_O_commit_epoch})
                    fail("new abort changed frozen owner result"); end
            S_d_I_done_ready=1; @(negedge S_clk); S_d_I_done_ready=0; S_d_I_abort=0;
        end
    endtask
    initial begin
        S_case=1; reset_all; start(1); S_saved_config=S_d_O_frozen_config; S_d_I_config=0;
        result(0,1,1,0);
        if(S_events!=3 || S_settles!=1 || S_d_O_frozen_config!==S_saved_config ||
            S_d_O_settle_time!=S_d_O_dwell_start+420000 || S_d_I_display_leases[137:136]!=2)
            fail("frozen transition or actual last-frame dwell/single-source release sequence");

        S_case=2; reset_all; S_d_I_config[244]=1; S_d_I_effect=6;
        start(1); result(0,1,0,0);
        if(S_d_I_active_config[244]!=0 || S_d_I_active_config[246:245]!=1 || S_d_I_active_config[88:72]!=0)
            fail("reverse transition did not normalize selected physical source");

        S_case=3; reset_all; S_d_I_pause=1; start(1);
        repeat(80) begin @(negedge S_clk); if(S_events!=0 || !S_d_O_pause_allow) fail("pause before planning started a visible transition"); end
        S_d_I_pause=0; result(0,1,1,0);

        S_case=4; reset_all; S_d_I_images[137:136]=1; start(1);
        repeat(20) @(negedge S_clk); S_d_I_abort=1; result(3,1,0,0);
        if(S_events!=0 || S_settles!=1) fail("pre-plan cancellation did not restore complete source only");

        S_case=5; reset_all; start(1);
        wait(S_d_O_video_started || (S_events==1 && S_d_I_event_done_valid));
        @(negedge S_clk); S_d_I_abort=1; result(3,1,0,0);

        S_case=6; reset_all; start(1); wait(S_d_O_last_progress==32768);
        @(negedge S_clk); S_d_I_abort=1; result(3,1,1,0);

        S_case=7; reset_all; S_install_leases=0; start(1); wait(u_owner.S_state==10);
        repeat(40) begin @(negedge S_clk);
            if(S_d_O_done_valid || S_d_O_image_hold!=3 || S_d_O_settled) fail("commit retired was mistaken for actual old lease release"); end
        S_d_I_display_leases=image_proof(S_d_I_active_config,1);
        repeat(10) begin @(negedge S_clk); if(S_d_O_done_valid) fail("wrong retained-source lease authorized release"); end
        S_d_I_display_leases=image_proof(S_d_I_active_config,2); result(0,1,1,0);

        S_case=8; reset_all; start(1); wait(S_events==1);
        @(negedge S_clk); S_d_I_images[137]=0;
        result(4,1,0,0);

        S_case=9; reset_all; start(1); wait(S_events==1);
        @(negedge S_clk); S_d_I_images[136]=0;
        result(4,0,0,1);
        if(S_d_O_image_hold!=3 || S_d_O_start_ready) fail("missing selected image falsely released source ownership");
        S_d_I_images=image_proof(S_d_O_frozen_config,3); S_d_I_recover_source=1; wait(S_d_O_recover_ready);
        @(negedge S_clk); S_d_I_recover_valid=1;
        @(negedge S_clk); S_d_I_recover_valid=0; result(0,1,1,0);
        if(!S_d_O_recovery_result) fail("explicit recovery lost transaction diagnostics");

        S_case=10; reset_all; S_d_I_audio_action=1; start(1); result(0,1,1,0);
        if(!S_d_O_audio_started || !S_d_O_audio_finished || S_d_O_timeline_error!=0 || S_d_I_audio_bound)
            fail("fresh proof withdrawal after real play acceptance cancelled normal transition");

        S_case=11; reset_all; S_d_I_audio_action=2; S_d_I_audio_slot=1; S_d_I_track_epoch=10; S_d_I_track_serial=12;
        start(1); result(0,1,1,0);
        if(!S_d_O_audio_finished || !S_d_I_active_b || S_d_I_audio_bound) fail("fade completion and final unbind did not retire");

        S_case=12; reset_all; S_d_I_audio_action=1; S_bind_failure=1;
        start(1); result(4,1,0,0);
        if(S_d_O_bind_error!=3 || S_events!=0) fail("audio bind rejection started timeline");

        S_case=13; reset_all; S_d_I_audio_action=1; start(1);
        wait(S_d_I_track_enabled[0] && S_d_O_last_progress==32768);
        @(negedge S_clk); S_d_I_abort=1; result(3,1,1,0);
        if(S_d_I_audio_stop_ack || S_d_I_track_enabled!=0) fail("cancel did not wait actual stop acknowledgment return-to-zero");

        S_case=14; reset_all; start(1); wait(S_d_O_event_valid && S_d_O_event_index==16'hffff);
        @(negedge S_clk); S_d_I_abort=1; result(0,1,1,0);
        if(!S_d_O_cancel_late) fail("late abort withdrew irreversible single-source cleanup");

        S_case=15; reset_all; S_d_I_config[52]=1; start(1); result(1,0,0,0);
        if(S_events!=0 || S_settles!=0) fail("invalid audio-required config created display work");

        S_case=16; reset_all; S_retire=0; start(1); wait(S_peer_applied);
        @(negedge S_clk); S_run=0;
        #10000; if(S_d_O_done_valid) fail("stopped owner clock fabricated resource retirement");
        S_run=1; S_retire=1; result(0,1,1,0);

        $display("PASS: 16 transition-owner scenarios with actual timeline and explicit executor/audio proof peers");
        S_test_pass=1; $finish;
    end
endmodule
