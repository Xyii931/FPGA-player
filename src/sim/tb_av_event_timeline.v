`timescale 1ns/1ps
// Reliable video executor and audio consumer are EXPLICIT peers; no physical memory/HDMI here.
// Real video_timing and transition_plan validate frame-grid/plan readiness.
module tb_av_event_timeline;
    wire S_silence_u_timeline_O_silence_valid;
    reg S_silence_started=0,S_silence_done=0,S_peer_silence=0;
    reg S_clk=0,S_run=1,S_reset=0,S_test_pass=0;
    always #20 if(S_run) S_clk=~S_clk;
    reg [31:0] S_time=0;
    reg [4:0] S_phase=0;
    wire S_tick=S_phase==16;
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin S_time<=0; S_phase<=0; end
        else begin S_time<=S_time+1'b1; S_phase<=S_phase==16 ? 0 : S_phase+1'b1; end
    end
    wire S_raster_frame;
    reg S_frame_gate=1;
    wire S_frame_start=S_raster_frame && S_frame_gate;
    video_timing u_timing (.I_clk(S_clk),.I_reset(S_reset),.O_hsync(),.O_vsync(),.O_de(),
        .O_x(),.O_y(),.O_frame_start(S_raster_frame),.O_line_start(),
        .O_raster_x(),.O_raster_y());
    integer S_case=0,S_requests=0,S_actual_frames=0,S_audio_commands=0,S_tick_count=0,S_peer_fade_count=0;
    reg S_video_gate=1,S_audio_gate=1,S_apply_gate=1,S_stop_gate=1,S_ack_fall_gate=1,S_inject_wrong=0;
    reg [3:0] S_peer_error=0;
    reg S_peer_pending=0,S_peer_result_real=0,S_peer_audio_busy=0;
    reg [31:0] S_peer_target=0;
    reg [15:0] S_peer_index=0;
    reg S_last_audio_slot=0;
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
    reg S_d_I_resources_ready=0;
    reg [1:0] S_d_I_track_known=0;
    reg [1:0] S_d_I_track_enabled=0;
    reg [1:0] S_d_I_track_consumed=0;
    reg [31:0] S_d_I_track_epochs=0;
    reg [63:0] S_d_I_track_serials=0;
    reg [63:0] S_d_I_track_totals=0;
    reg [63:0] S_d_I_track_next_index=0;
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
    reg S_d_I_play_ready=0;
    wire S_d_O_fade_valid;
    wire S_d_O_target_b;
    wire [31:0] S_d_O_audio_target_time;
    reg S_d_I_fade_ready=0;
    reg S_d_I_fade_done=0;
    reg S_d_I_active_b=0;
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
        .I_silence_ready(S_d_I_fade_ready),
        .I_silence_started(S_silence_started),
        .I_silence_done(S_silence_done)
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
        S_d_I_play_ready=S_audio_gate && !S_peer_audio_busy && !(S_d_I_pause && S_d_O_pause_allow);
        S_d_I_fade_ready=S_audio_gate && !S_peer_audio_busy && !(S_d_I_pause && S_d_O_pause_allow);
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
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin
            S_d_I_track_enabled<=0; S_d_I_track_consumed<=0; S_d_I_track_next_index<=0;
            S_d_I_fade_done<=0; S_d_I_active_b<=0; S_d_I_audio_stop_ack<=0;
            S_peer_audio_busy<=0; S_peer_fade_count<=0; S_last_audio_slot<=0; S_audio_commands<=0;
            S_peer_silence<=0; S_silence_started<=0; S_silence_done<=0;
        end else begin
            S_d_I_track_consumed<=0; S_d_I_fade_done<=0;
            S_silence_started<=0; S_silence_done<=0;
            if(S_silence_u_timeline_O_silence_valid && S_d_I_fade_ready) begin
                S_peer_silence<=1; S_peer_audio_busy<=1; S_peer_fade_count<=0;
                S_audio_commands<=S_audio_commands+1;
            end
            if((S_d_O_play_valid && S_d_I_play_ready) || (S_d_O_fade_valid && S_d_I_fade_ready)) begin
                S_d_I_track_enabled[S_d_O_target_b]<=1; S_last_audio_slot<=S_d_O_target_b;
                S_peer_audio_busy<=S_d_O_fade_valid; S_peer_fade_count<=0; S_audio_commands<=S_audio_commands+1;
            end
            if(S_tick) begin
                if(S_d_I_track_enabled[0] && S_d_I_track_next_index[31:0]<S_d_I_track_totals[31:0]) begin
                    S_d_I_track_consumed[0]<=1; S_d_I_track_next_index[31:0]<=S_d_I_track_next_index[31:0]+1'b1;
                end
                if(S_d_I_track_enabled[1] && S_d_I_track_next_index[63:32]<S_d_I_track_totals[63:32]) begin
                    S_d_I_track_consumed[1]<=1; S_d_I_track_next_index[63:32]<=S_d_I_track_next_index[63:32]+1'b1;
                end
                if(S_peer_audio_busy) begin
                    if(S_peer_silence && S_peer_fade_count==0) S_silence_started<=1;
                    if(S_peer_fade_count==3) begin
                        S_peer_audio_busy<=0;
                        if(S_peer_silence) begin
                            S_peer_silence<=0; S_silence_done<=1; S_d_I_track_enabled<=0;
                        end else begin S_d_I_fade_done<=1; S_d_I_active_b<=S_last_audio_slot; end
                    end else S_peer_fade_count<=S_peer_fade_count+1;
                end
            end
            if(S_d_O_audio_stop_request && S_stop_gate) begin
                S_d_I_track_enabled[S_last_audio_slot]<=0; S_peer_audio_busy<=0; S_d_I_audio_stop_ack<=1;
            end else if(!S_d_O_audio_stop_request && S_ack_fall_gate) S_d_I_audio_stop_ack<=0;
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
            S_d_I_clock_enable=1; S_d_I_resources_ready=1;
            S_d_I_track_known=3; S_d_I_track_epochs=32'h1234abcd;
            S_d_I_track_serials={32'd7,32'd5}; S_d_I_track_totals={32'h10000000,32'h10000000};
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
            S_d_I_track_epoch=slot ? 16'h1234 : 16'habcd; S_d_I_track_serial=slot ? 7 : 5;
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
        S_case=1; reset_all; start_event(3,0,0,0); result(0);
        if(S_requests!=4 || S_actual_frames!=4 || !S_d_O_video_finished || S_d_O_actual_finish-S_d_O_actual_start!=1260000 ||
            S_d_O_actual_midpoint-S_d_O_actual_start!=840000 || S_audio_commands!=0) fail("odd-duration frame progression/endpoints/midpoint");

        S_case=2; reset_all; start_event(2,0,1,0); result(0);
        if(!S_d_O_audio_started || S_audio_commands!=1 || S_d_O_anchor_error<0 || S_d_O_anchor_error>17 ||
            S_d_O_actual_audio<S_d_O_audio_command_time) fail("default midpoint/sample boundary start facts");

        S_case=3; reset_all; start_event(2,50,2,1); result(0);
        if(S_d_O_planned_audio-S_d_O_planned_midpoint!=12500000 || !S_d_O_audio_finished || S_audio_commands!=1 ||
            S_d_O_anchor_error<0 || S_d_O_anchor_error>17) fail("positive 500 ms anchor/fade completion");

        S_case=4; reset_all; start_event(2,-50,1,0); result(0);
        if(S_d_O_planned_midpoint-S_d_O_planned_audio!=12500000 || S_d_O_actual_audio>=S_d_O_actual_start ||
            S_d_O_planned_audio<32000 || S_d_O_anchor_error<0 || S_d_O_anchor_error>17)
            fail("negative 500 ms early audio and preparation lead");

        S_case=5; reset_all; S_d_I_resources_ready=0; start_event(2,0,0,0);
        repeat(100) begin @(negedge S_clk); if(S_requests!=0 || S_d_O_video_valid) fail("unprepared resources started timeline"); end
        S_d_I_resources_ready=1; result(0);

        S_case=6; reset_all; S_video_gate=0; start_event(2,0,0,0); wait(S_d_O_video_valid);
        S_saved_start=S_d_O_video_target_time; repeat(30) @(negedge S_clk); S_d_I_abort=1;
        repeat(12) begin @(negedge S_clk); if(!S_d_O_video_valid || !S_d_O_video_cancel || S_d_O_done_valid ||
            S_d_O_video_target_time!==S_saved_start) fail("cancel withdrew offered video or fabricated retirement"); end
        S_video_gate=1; result(3);
        if(S_d_O_cancel_late || S_d_O_video_started) fail("cancelled unexecuted video fabricated apply facts");

        S_case=7; reset_all; S_apply_gate=0; start_event(2,0,1,0); wait(S_d_O_audio_started);
        S_d_I_abort=1; S_stop_gate=0;
        repeat(40) begin @(negedge S_clk); if(S_d_O_done_valid) fail("audio cancellation bypassed actual stop ack"); end
        wait(S_d_O_audio_stop_request); S_stop_gate=1; S_ack_fall_gate=0;
        wait(S_d_I_audio_stop_ack); repeat(8) @(negedge S_clk);
        if(S_d_O_done_valid || S_d_O_audio_stop_request) fail("stop acknowledgement four-phase return was bypassed");
        S_ack_fall_gate=1; result(3);
        if(!S_d_O_cancel_late || !S_d_O_audio_started) fail("late audio execution facts erased by cancel");

        S_case=8; reset_all; S_apply_gate=0; start_event(2,0,0,0); wait(S_requests==1);
        S_inject_wrong=1; wait(S_d_O_response_discarded); @(negedge S_clk); S_inject_wrong=0;
        if(S_d_O_done_valid || !S_peer_pending) fail("wrong response identity retired the actual frame command");
        S_apply_gate=1; result(0);

        S_case=9; reset_all; S_apply_gate=0; start_event(2,50,1,0); wait(S_requests==1);
        wait(S_time>S_d_O_planned_start+420000); @(negedge S_clk); S_apply_gate=1; result(0);
        if(!S_d_O_late || S_d_O_actual_start<=S_d_O_planned_start || S_d_O_anchor_error<0 || S_d_O_anchor_error>17)
            fail("late video did not rebase unpresented positive-offset audio");

        S_case=10; reset_all; S_audio_gate=0; start_event(2,-1,1,0); wait(S_d_O_play_valid);
        S_saved_audio=u_timeline.S_audio_target;
        repeat(20) begin @(negedge S_clk); if(!S_d_O_play_valid || u_timeline.S_audio_target!==S_saved_audio)
            fail("presented audio event target changed under backpressure"); end
        S_audio_gate=1; result(0);
        if(S_audio_commands!=1) fail("audio request repeated during backpressure");

        S_case=11; reset_all; S_d_I_pause=1; start_event(2,0,1,0);
        repeat(30) begin @(negedge S_clk); if(S_requests || S_audio_commands) fail("paused preparation scheduled events"); end
        S_d_I_pause=0; wait(S_requests==1); @(negedge S_clk); S_d_I_pause=1;
        if(S_d_O_pause_allow) fail("pause allowed during incomplete transition");
        result(0); if(!S_d_O_pause_allow) fail("completed transition did not release pause permission");

        S_case=12; reset_all; start_event(0,0,0,0); result(1);
        if(S_requests!=0 || S_audio_commands!=0) fail("invalid duration acquired external obligations");
        start_event(2,51,0,0); result(1);

        S_case=13; reset_all; S_peer_error=2; start_event(2,-50,1,0); result(2);
        if(S_audio_commands!=0 || S_d_O_video_started) fail("early display rejection started future audio or fabricated apply");

        S_case=14; reset_all; S_apply_gate=0; start_event(2,0,0,0); wait(S_requests==1);
        @(negedge S_clk); S_d_I_clock_enable=0;
        result(5);
        if(S_d_O_quarantined || S_d_O_video_started) fail("clock withdrawal fabricated completion or contract fault");

        S_case=15; reset_all; start_event(2,0,0,0); wait(S_requests==1);
        @(negedge S_clk); S_frame_gate=0; result(6);
        if(!S_d_O_quarantined || !S_d_O_contract_fault) fail("missing real frame cadence retained timeline authority");

        S_case=16; reset_all; S_audio_gate=0; start_event(2,-1,1,0); wait(S_d_O_play_valid);
        S_d_I_abort=1; repeat(15) begin @(negedge S_clk); if(S_d_O_done_valid || !S_d_O_play_valid)
            fail("presented audio cancellation retracted valid before real handshake"); end
        S_audio_gate=1; result(3);
        if(!S_d_O_cancel_late || S_audio_commands!=1) fail("late accepted audio command was hidden by cancellation");

        S_case=17; reset_all;
        @(negedge S_clk); S_d_I_track_enabled[0]=1;
        start_event(2,0,3,0); result(0);
        if(S_audio_commands!=0 || S_d_O_audio_started || S_d_I_track_next_index[31:0]==0)
            fail("same background track restarted or lost its actual position");

        S_case=18; reset_all; S_d_I_resources_ready=0; start_event(2,0,0,0);
        @(negedge S_clk); S_d_I_abort=1; result(3);
        if(S_d_O_video_started || S_requests) fail("unstarted cancellation fabricated a video event");
        S_case=19; reset_all; S_d_I_resources_ready=0; start_event(2,0,0,0);
        @(negedge S_clk); S_d_I_abort=1; result(3); S_d_I_abort=0;
        S_command_epoch=0; start_event(2,0,0,0); result(1);
        if(S_requests) fail("duplicate transaction epoch issued external frame requests");

        S_case=20; reset_all;
        @(negedge S_clk); S_d_I_clock_enable=0;
        repeat(2) @(negedge S_clk); S_time=32'hfff00000;
        repeat(2) @(negedge S_clk); S_d_I_clock_enable=1;
        start_event(3,0,0,0); result(0);
        if(S_d_O_actual_finish-S_d_O_actual_start!=1260000 || S_d_O_actual_finish>=S_d_O_actual_start || S_d_O_quarantined)
            fail("modular timestamp wrap broke observed frame scheduling");

        S_case=21; reset_all; S_apply_gate=0; start_event(2,0,0,0); wait(S_requests==1);
        @(negedge S_clk); S_d_I_clock_enable=0; S_run=0;
        repeat(50) begin #40; if(S_d_O_done_valid || !S_d_O_video_cancel)
            fail("stopped event clock fabricated execution/retirement"); end
        S_run=1; result(5);

        S_case=22; reset_all; S_apply_gate=0; start_event(2,-50,1,0); wait(S_d_O_audio_started);
        S_saved_audio=S_d_O_actual_audio; @(negedge S_clk); S_apply_gate=1; result(0);
        if(S_d_O_actual_audio!==S_saved_audio || !S_d_O_late ||
            $signed(S_d_O_anchor_error)>=0 || S_d_O_actual_midpoint<=S_d_O_planned_midpoint)
            fail("late video silently retimed already executed negative-offset audio");

        S_case=23; reset_all; S_d_I_resources_ready=0; start_event(2,0,1,0);
        S_d_I_resources_ready=1; wait(S_requests==1);
        @(negedge S_clk); S_d_I_track_epochs[15:0]=16'h12cd; result(4);
        if(S_audio_commands || S_d_O_video_started) fail("changed full track epoch retained event authority");

        S_case=24; reset_all; S_apply_gate=0; start_event(2,0,0,0); wait(S_peer_pending && S_plan_done);
        @(negedge S_clk); S_d_I_video_done_epoch=S_d_O_epoch; S_d_I_video_done_tag=S_d_O_tag;
        S_d_I_video_done_frame_index=0; S_d_I_video_done_error=0; S_d_I_video_done_applied=1; S_d_I_video_done_time=S_time;
        S_d_I_video_done_valid=1; S_peer_result_real=1;
        result(6);
        if(!S_d_O_contract_fault || !S_d_O_quarantined || S_d_O_video_started)
            fail("off-grid successful apply report was accepted as a real displayed frame");

        S_case=25; reset_all; S_apply_gate=0; start_event(2,0,0,0); wait(S_peer_pending && S_plan_done);
        // An actual apply may be followed by a downstream retirement error.
        wait(S_raster_frame && S_time==S_peer_target); @(negedge S_clk);
        S_d_I_video_done_epoch=S_d_O_epoch; S_d_I_video_done_tag=S_d_O_tag;
        S_d_I_video_done_frame_index=0; S_d_I_video_done_error=2; S_d_I_video_done_applied=1;
        S_d_I_video_done_time=S_peer_target; S_d_I_video_done_valid=1; S_peer_result_real=1;
        result(2);
        if(!S_d_O_video_started || !S_d_O_cancel_late || S_d_O_actual_start!==S_peer_target || S_requests!=1)
            fail("post-apply retirement failure erased irreversible display facts or issued another frame");

        S_case=26; reset_all; S_apply_gate=0; start_event(2,0,0,0); wait(S_peer_pending && S_plan_done);
        @(negedge S_clk); S_d_I_video_done_epoch=S_d_O_epoch; S_d_I_video_done_tag=S_d_O_tag;
        S_d_I_video_done_frame_index=0; S_d_I_video_done_error=0; S_d_I_video_done_applied=0;
        S_d_I_video_done_time=0; S_d_I_video_done_valid=1; S_peer_result_real=1;
        result(6);
        if(S_d_O_video_started || !S_d_O_quarantined) fail("non-applied success report fabricated a displayed frame");
        S_case=27; reset_all; start_event(2,0,0,1); result(0);
        if(!S_d_O_audio_started || !S_d_O_audio_finished || S_audio_commands!=1 ||
            S_d_O_anchor_error<0 || S_d_O_anchor_error>17)
            fail("explicit silence bypassed the actual sample start/done or midpoint anchor");
        $display("PASS: frame/sample anchors, signed offsets, reliable execution facts, cancellation and result holds");
        S_test_pass=1; $finish;
    end
endmodule
