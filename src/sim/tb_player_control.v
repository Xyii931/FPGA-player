`timescale 1ns/1ps
// Real mailbox and real timeline; video apply/track/stop peers are EXPLICIT fixtures.
module tb_player_control;
    wire S_silence_u_t_O_silence_valid;
    reg S_host_clk=0,S_video_clk=0,S_video_run=1,S_reset=1;
    always #4 S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reg [31:0] S_time=0;
    always @(posedge S_video_clk) begin
        if(S_reset) S_time<=0; else S_time<=S_time+32'd1;
    end
    reg S_test_pass=0;
    reg [403:0] S_frozen;
    reg S_c_I_start_valid=0;
    wire S_c_O_start_ready;
    reg [403:0] S_c_I_command=0;
    reg [9:0] S_c_I_dwell_seconds=0;
    reg S_c_I_abort=0;
    wire S_c_O_busy;
    wire S_c_O_done_valid;
    reg S_c_I_done_ready=0;
    wire [127:0] S_c_O_result;
    wire S_c_O_dwell_expired;
    reg S_c_I_pause=0;
    reg [1:0] S_c_I_track_known=0;
    reg [1:0] S_c_I_track_enabled=0;
    reg [31:0] S_c_I_track_epochs=0;
    reg [63:0] S_c_I_track_serials=0;
    reg [63:0] S_c_I_track_next_index=0;
    reg S_c_I_active_b=0;
    reg S_c_I_audio_has_started=0;
    wire S_c_O_video_start_valid;
    reg S_c_I_video_start_ready=0;
    wire [403:0] S_c_O_video_command;
    wire S_c_O_video_abort;
    reg S_c_I_video_done_valid=0;
    wire S_c_O_video_done_ready;
    reg [31:0] S_c_I_video_epoch=0;
    reg [15:0] S_c_I_video_tag=0;
    reg [3:0] S_c_I_video_error=0;
    reg S_c_I_video_settled=0;
    reg S_c_I_video_selected_source=0;
    reg S_c_I_video_recovery_required=0;
    reg S_c_I_video_transition_started=0;
    reg S_c_I_video_quarantined=0;
    reg S_c_I_video_sync_required=0;
    reg [31:0] S_c_I_video_dwell_start=0;
    wire S_c_O_response_discarded;
    player_control_cdc u_c (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_start_valid(S_c_I_start_valid),
        .O_start_ready(S_c_O_start_ready),
        .I_command(S_c_I_command),
        .I_dwell_seconds(S_c_I_dwell_seconds),
        .I_abort(S_c_I_abort),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(S_c_I_done_ready),
        .O_result(S_c_O_result),
        .O_dwell_expired(S_c_O_dwell_expired),
        .I_clock_enable(1'b1),
        .I_pause(S_c_I_pause),
        .I_time(S_time),
        .I_track_known(S_c_I_track_known),
        .I_track_enabled(S_c_I_track_enabled),
        .I_track_epochs(S_c_I_track_epochs),
        .I_track_serials(S_c_I_track_serials),
        .I_track_next_index(S_c_I_track_next_index),
        .I_active_b(S_c_I_active_b),
        .I_audio_has_started(S_c_I_audio_has_started),
        .O_video_start_valid(S_c_O_video_start_valid),
        .I_video_start_ready(S_c_I_video_start_ready),
        .O_video_command(S_c_O_video_command),
        .O_video_abort(S_c_O_video_abort),
        .I_video_done_valid(S_c_I_video_done_valid),
        .O_video_done_ready(S_c_O_video_done_ready),
        .I_video_epoch(S_c_I_video_epoch),
        .I_video_tag(S_c_I_video_tag),
        .I_video_error(S_c_I_video_error),
        .I_video_settled(S_c_I_video_settled),
        .I_video_selected_source(S_c_I_video_selected_source),
        .I_video_recovery_required(S_c_I_video_recovery_required),
        .I_video_transition_started(S_c_I_video_transition_started),
        .I_video_quarantined(S_c_I_video_quarantined),
        .I_video_sync_required(S_c_I_video_sync_required),
        .I_video_dwell_start(S_c_I_video_dwell_start),
        .O_response_discarded(S_c_O_response_discarded),
        .I_hold_dwell(1'b0),
        .O_audio_bookmark()
    );
    reg S_t_I_start_valid=0;
    wire S_t_O_start_ready;
    reg S_t_I_abort=0;
    wire S_t_O_pause_allow;
    wire S_t_O_video_valid;
    reg S_t_I_video_ready=0;
    wire S_t_O_video_cancel;
    wire [31:0] S_t_O_video_epoch;
    wire [15:0] S_t_O_video_tag;
    wire [2:0] S_t_O_video_effect;
    wire [15:0] S_t_O_video_frame_index;
    wire [16:0] S_t_O_video_progress;
    wire [31:0] S_t_O_video_target_time;
    reg S_t_I_video_done_valid=0;
    wire S_t_O_video_done_ready;
    reg [31:0] S_t_I_video_done_epoch=0;
    reg [15:0] S_t_I_video_done_tag=0;
    reg [15:0] S_t_I_video_done_frame_index=0;
    reg [3:0] S_t_I_video_done_error=0;
    reg S_t_I_video_done_applied=0;
    reg [31:0] S_t_I_video_done_time=0;
    wire S_t_O_play_valid;
    wire S_t_O_fade_valid;
    wire S_t_O_target_b;
    wire [31:0] S_t_O_audio_target_time;
    wire S_t_O_audio_stop_request;
    reg S_t_I_audio_stop_ack=0;
    wire S_t_O_busy;
    wire S_t_O_done_valid;
    reg S_t_I_done_ready=0;
    wire [3:0] S_t_O_error;
    wire [31:0] S_t_O_epoch;
    wire [15:0] S_t_O_tag;
    wire S_t_O_cancel_late;
    wire S_t_O_video_started;
    wire S_t_O_video_finished;
    wire S_t_O_audio_started;
    wire S_t_O_audio_finished;
    wire [31:0] S_t_O_planned_start;
    wire [31:0] S_t_O_planned_midpoint;
    wire [31:0] S_t_O_planned_audio;
    wire [31:0] S_t_O_actual_start;
    wire [31:0] S_t_O_actual_midpoint;
    wire [31:0] S_t_O_actual_audio;
    wire [31:0] S_t_O_actual_finish;
    wire [31:0] S_t_O_audio_command_time;
    wire [31:0] S_t_O_audio_start_index;
    wire signed [31:0] S_t_O_anchor_error;
    wire S_t_O_midpoint_seen;
    wire S_t_O_late;
    wire S_t_O_contract_fault;
    wire S_t_O_quarantined;
    wire S_t_O_response_discarded;
    av_event_timeline #(.STOP_PENDING_AUDIO(1)) u_t (
        .I_clk(S_video_clk),
        .I_reset(S_reset),
        .I_clock_enable(1'b1),
        .I_time(S_time),
        .I_frame_start(S_time%32'd420000==0),
        .I_sample_tick(S_time%32'd521==0),
        .I_start_valid(S_t_I_start_valid),
        .O_start_ready(S_t_O_start_ready),
        .I_epoch(32'd1),
        .I_tag(16'hbeef),
        .I_effect(3'd0),
        .I_duration_frames(16'd1),
        .I_av_offset_steps(7'd0),
        .I_audio_action(2'd1),
        .I_audio_slot(1'b0),
        .I_track_epoch(16'h11),
        .I_track_serial(32'haaaa),
        .I_start_index(32'd0),
        .I_resources_ready(1'b1),
        .I_resources_epoch(32'd1),
        .I_resources_tag(16'hbeef),
        .I_track_known(2'b01),
        .I_track_enabled(2'b00),
        .I_track_consumed(2'b00),
        .I_track_epochs(32'h00000011),
        .I_track_serials(64'h000000000000aaaa),
        .I_track_totals(64'd1000),
        .I_track_next_index(64'd0),
        .I_pause(1'b0),
        .I_abort(S_t_I_abort),
        .O_pause_allow(S_t_O_pause_allow),
        .O_video_valid(S_t_O_video_valid),
        .I_video_ready(S_t_I_video_ready),
        .O_video_cancel(S_t_O_video_cancel),
        .O_video_epoch(S_t_O_video_epoch),
        .O_video_tag(S_t_O_video_tag),
        .O_video_effect(S_t_O_video_effect),
        .O_video_frame_index(S_t_O_video_frame_index),
        .O_video_progress(S_t_O_video_progress),
        .O_video_target_time(S_t_O_video_target_time),
        .I_video_done_valid(S_t_I_video_done_valid),
        .O_video_done_ready(S_t_O_video_done_ready),
        .I_video_done_epoch(S_t_I_video_done_epoch),
        .I_video_done_tag(S_t_I_video_done_tag),
        .I_video_done_frame_index(S_t_I_video_done_frame_index),
        .I_video_done_error(S_t_I_video_done_error),
        .I_video_done_applied(S_t_I_video_done_applied),
        .I_video_done_time(S_t_I_video_done_time),
        .O_play_valid(S_t_O_play_valid),
        .I_play_ready(1'b0),
        .O_fade_valid(S_t_O_fade_valid),
        .O_target_b(S_t_O_target_b),
        .O_audio_target_time(S_t_O_audio_target_time),
        .I_fade_ready(1'b0),
        .I_fade_done(1'b0),
        .I_active_b(1'b0),
        .O_audio_stop_request(S_t_O_audio_stop_request),
        .I_audio_stop_ack(S_t_I_audio_stop_ack),
        .O_busy(S_t_O_busy),
        .O_done_valid(S_t_O_done_valid),
        .I_done_ready(S_t_I_done_ready),
        .O_error(S_t_O_error),
        .O_epoch(S_t_O_epoch),
        .O_tag(S_t_O_tag),
        .O_cancel_late(S_t_O_cancel_late),
        .O_video_started(S_t_O_video_started),
        .O_video_finished(S_t_O_video_finished),
        .O_audio_started(S_t_O_audio_started),
        .O_audio_finished(S_t_O_audio_finished),
        .O_planned_start(S_t_O_planned_start),
        .O_planned_midpoint(S_t_O_planned_midpoint),
        .O_planned_audio(S_t_O_planned_audio),
        .O_actual_start(S_t_O_actual_start),
        .O_actual_midpoint(S_t_O_actual_midpoint),
        .O_actual_audio(S_t_O_actual_audio),
        .O_actual_finish(S_t_O_actual_finish),
        .O_audio_command_time(S_t_O_audio_command_time),
        .O_audio_start_index(S_t_O_audio_start_index),
        .O_anchor_error(S_t_O_anchor_error),
        .O_midpoint_seen(S_t_O_midpoint_seen),
        .O_late(S_t_O_late),
        .O_contract_fault(S_t_O_contract_fault),
        .O_quarantined(S_t_O_quarantined),
        .O_response_discarded(S_t_O_response_discarded),
        .O_silence_valid(S_silence_u_t_O_silence_valid),
        .I_silence_ready(1'b0),
        .I_silence_started(1'b0),
        .I_silence_done(1'b0)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL player_control: %0s",message); $finish; end
    endtask
    task video_cycles;
        input integer count;
        integer k;
        begin for(k=0;k<count;k=k+1) @(negedge S_video_clk); end
    endtask
    task send_command;
        input [31:0] epoch;
        input [1:0] action;
        begin
            @(negedge S_host_clk); S_c_I_command=0;
            S_c_I_command[403:372]=epoch; S_c_I_command[371:356]=epoch[15:0];
            S_c_I_command[82:81]=action; S_c_I_command[79:64]=16'h11;
            S_frozen=S_c_I_command; S_c_I_start_valid=1;
            while(!S_c_O_start_ready) @(negedge S_host_clk);
            @(negedge S_host_clk); S_c_I_start_valid=0; S_c_I_command=404'hbad;
        end
    endtask
    task consume_result;
        begin
            wait(S_c_O_done_valid);
            repeat(8) @(negedge S_host_clk);
            if(!S_c_O_done_valid || S_c_O_start_ready) fail("result/backpressure not retained");
            S_c_I_done_ready=1; @(negedge S_host_clk); S_c_I_done_ready=0; S_c_I_abort=0;
            wait(!S_c_O_busy); @(negedge S_host_clk);
        end
    endtask
    task backend_result;
        input [31:0] epoch;
        input [3:0] error;
        begin
            @(negedge S_video_clk);
            S_c_I_video_epoch=epoch; S_c_I_video_tag=epoch[15:0]; S_c_I_video_error=error;
            S_c_I_video_transition_started=1; S_c_I_video_settled=1;
            S_c_I_video_dwell_start=S_time; S_c_I_video_done_valid=1;
            while(!S_c_O_video_done_ready) @(negedge S_video_clk);
            @(negedge S_video_clk); S_c_I_video_done_valid=0;
        end
    endtask
    initial begin
        #101; S_reset=0;
        S_c_I_dwell_seconds=1;
        wait(S_c_O_start_ready);
        send_command(1,0);
        wait(S_c_O_video_start_valid); video_cycles(8);
        if(S_c_O_video_command!==S_frozen || S_c_O_done_valid) fail("unstable payload or enqueue treated as apply");
        S_c_I_video_start_ready=1; video_cycles(1); S_c_I_video_start_ready=0;
        backend_result(1,0); consume_result;
        if(S_c_O_result[127:96]!=1 || !S_c_O_result[75] || S_c_O_result[71]) fail("actual result identity lost");
        // Host cancellation can arrive before the stopped video domain captures request.
        @(negedge S_video_clk); S_video_run=0;
        send_command(2,0);
        @(negedge S_host_clk); S_c_I_abort=1;
        repeat(30) @(negedge S_host_clk);
        if(S_c_O_done_valid) fail("stopped domain fabricated completion");
        S_video_run=1; wait(S_c_O_done_valid);
        if(!S_c_O_result[71] || S_c_O_result[79:76]!=3) fail("pre-accept cancellation not returned safely");
        consume_result;
        // A mixer already started before a two-slot stop must resume with fade.
        S_c_I_track_known=1; S_c_I_track_epochs=32'h11;
        S_c_I_track_serials=64'haaaa; S_c_I_audio_has_started=1;
        send_command(3,1); wait(S_c_O_video_start_valid);
        if(S_c_O_video_command[82:81]!=2 || S_c_O_video_command[63:32]!=32'haaaa)
            fail("fresh track did not use real serial / preserved mixer state");
        S_c_I_video_start_ready=1; video_cycles(1); S_c_I_video_start_ready=0;
        @(negedge S_host_clk); S_c_I_abort=1;
        wait(S_c_O_video_abort); video_cycles(8);
        if(S_c_O_done_valid) fail("accepted transaction canceled without real retirement");
        backend_result(3,3); consume_result;
        // Real timeline cancellation with a play command permanently backpressured.
        @(negedge S_video_clk); S_t_I_start_valid=1;
        while(!S_t_O_start_ready) @(negedge S_video_clk);
        video_cycles(1); S_t_I_start_valid=0;
        wait(S_t_O_video_valid); S_t_I_video_ready=1;
        S_t_I_video_done_epoch=S_t_O_video_epoch; S_t_I_video_done_tag=S_t_O_video_tag;
        S_t_I_video_done_frame_index=S_t_O_video_frame_index;
        video_cycles(1); S_t_I_video_ready=0;
        wait(S_t_O_play_valid);
        @(negedge S_video_clk); S_t_I_abort=1;
        wait(S_t_O_video_cancel);
        S_t_I_video_done_error=3; S_t_I_video_done_applied=0; S_t_I_video_done_valid=1;
        video_cycles(1); S_t_I_video_done_valid=0;
        wait(S_t_O_audio_stop_request); video_cycles(6);
        if(!S_t_O_play_valid || S_t_O_done_valid) fail("pending offer withdrawn before stop proof");
        S_t_I_audio_stop_ack=1; video_cycles(3);
        if(S_t_O_play_valid || S_t_O_done_valid || S_t_O_audio_started) fail("pending stop ack mishandled");
        wait(!S_t_O_audio_stop_request); video_cycles(4); S_t_I_audio_stop_ack=0;
        wait(S_t_O_done_valid);
        if(S_t_O_error!=3 || S_t_O_quarantined || S_t_O_audio_started) fail("pending cancellation terminal incorrect");
        S_t_I_done_ready=1; video_cycles(2);
        S_test_pass=1;
        $display("PASS player_control: real mailbox/timeline; display/track/stop endpoints are fixtures"); $finish;
    end
    initial begin #100000000; fail("timeout"); end
endmodule
