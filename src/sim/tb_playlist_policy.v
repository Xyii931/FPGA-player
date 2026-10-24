`timescale 1ns/1ps
// Actual playlist_player_ctrl; item/image/file/retirement peers are explicit fixtures.
// Parser/store snapshot behavior is exercised in the existing dedicated tests.
module tb_playlist_policy;
    reg I_clk=0;
    reg I_reset=0;
    reg I_enable=0;
    reg I_auto=0;
    reg I_pause=0;
    reg I_session_ready=0;
    reg I_session_abort=0;
    reg I_media_valid=0;
    reg [31:0] I_media_generation=0;
    reg I_next=0;
    reg I_prev=0;
    reg I_goto_valid=0;
    reg [5:0] I_goto_index=0;
    reg [2:0] I_layout=0;
    reg [1:0] I_rotation=0;
    reg I_bilinear=0;
    reg [3:0] I_brightness=0;
    reg [3:0] I_contrast=0;
    reg [4:0] I_saturation=0;
    reg signed [6:0] I_av_offset_steps=0;
    reg [2:0] I_default_override=0;
    reg [9:0] I_default_duration=0;
    reg [9:0] I_default_transition_ms=0;
    reg [2:0] I_default_transition=0;
    wire O_busy;
    wire [22:0] S_layout_view;
    wire S_compose,S_part_valid;
    wire [3:0] S_parts;
    wire [6:0] S_part_path_length;
    wire O_active_valid;
    wire O_fault;
    wire O_changed;
    wire [3:0] O_error;
    wire [5:0] O_current_index;
    wire [6:0] O_count;
    wire [31:0] O_generation;
    wire [31:0] O_revision;
    wire O_item_start_valid;
    reg I_item_start_ready=0;
    wire [5:0] O_item_index;
    wire [15:0] O_item_tag;
    wire [31:0] O_item_revision;
    wire O_item_abort;
    reg I_item_done_valid=0;
    wire O_item_done_ready;
    reg [3:0] I_item_error=0;
    reg [31:0] I_item_generation=0;
    reg [31:0] I_item_revision=0;
    reg [6:0] I_item_count=0;
    reg [6:0] I_item_file_length=0;
    reg [6:0] I_item_audio_length=0;
    reg [9:0] I_item_duration=0;
    reg [9:0] I_item_transition_ms=0;
    reg [2:0] I_item_transition=0;
    reg [6:0] I_item_policy=0;
    wire [1:0] O_item_string_kind;
    wire [6:0] O_item_string_address;
    reg [7:0] I_item_string_data=0;
    wire O_image_start_valid;
    reg I_image_start_ready=0;
    wire [15:0] O_image_tag;
    wire [31:0] O_image_generation;
    wire [31:0] O_image_asset;
    wire [2:0] O_image_layout;
    wire [1:0] O_image_rotation;
    wire O_image_bilinear;
    wire O_image_abort;
    wire [6:0] O_image_path_length;
    wire O_image_path_valid;
    reg I_image_path_ready=0;
    wire [7:0] O_image_path_data;
    wire O_image_path_last;
    reg I_image_done_valid=0;
    wire O_image_done_ready;
    reg [3:0] I_image_error=0;
    reg [15:0] I_image_tag=0;
    reg [31:0] I_image_generation=0;
    reg [31:0] I_image_token=0;
    reg [2:0] I_image_slot=0;
    reg I_image_stage_valid=0;
    reg I_image_quarantined=0;
    wire O_image_stage_release_valid;
    reg I_image_stage_release_ready=0;
    wire [2:0] O_image_stage_slot;
    wire [31:0] O_image_stage_token;
    wire [31:0] O_image_stage_generation;
    wire O_image_stage_discard;
    wire [1:0] O_audio_file_start_valid;
    reg [1:0] I_audio_file_start_ready=0;
    wire [31:0] O_audio_file_tag;
    wire [63:0] O_audio_file_generation;
    wire [13:0] O_audio_file_path_length;
    wire [1:0] O_audio_file_path_valid;
    reg [1:0] I_audio_file_path_ready=0;
    wire [15:0] O_audio_file_path_data;
    wire [1:0] O_audio_file_path_last;
    wire [1:0] O_audio_file_abort;
    reg [1:0] I_audio_file_done_valid=0;
    wire [1:0] O_audio_file_done_ready;
    reg [7:0] I_audio_file_error=0;
    reg [31:0] I_audio_file_tag=0;
    wire [1:0] O_audio_recycle_valid;
    reg [1:0] I_audio_recycle_ready=0;
    reg [1:0] I_audio_recycle_done=0;
    reg [1:0] I_audio_available=0;
    reg I_bgm_need=0;
    reg I_bgm_start_ready=0;
    reg I_bgm_done_valid=0;
    reg [7:0] I_bgm_result=0;
    wire O_bgm_start_valid;
    wire O_bgm_slot;
    wire O_bgm_abort;
    wire O_bgm_done_ready;
    wire [15:0] O_bgm_track_epoch;
    wire O_command_valid;
    reg I_command_ready=0;
    wire [403:0] O_command;
    wire [9:0] O_dwell_seconds;
    wire O_command_abort;
    reg I_command_done_valid=0;
    wire O_command_done_ready;
    reg [127:0] I_command_result=0;
    reg I_dwell_expired=0;
    wire O_response_discarded;
    playlist_player_ctrl u_app (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_enable(I_enable),
        .I_auto(I_auto),
        .I_pause(I_pause),
        .I_session_ready(I_session_ready),
        .I_session_abort(I_session_abort),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_next(I_next),
        .I_prev(I_prev),
        .I_goto_valid(I_goto_valid),
        .I_goto_index(I_goto_index),
        .I_layout(I_layout),
        .I_rotation(I_rotation),
        .I_bilinear(I_bilinear),
        .I_brightness(I_brightness),
        .I_contrast(I_contrast),
        .I_saturation(I_saturation),
        .I_av_offset_steps(I_av_offset_steps),
        .I_default_override(I_default_override),
        .I_default_duration(I_default_duration),
        .I_default_transition_ms(I_default_transition_ms),
        .I_default_transition(I_default_transition),
        .O_busy(O_busy),
        .O_active_valid(O_active_valid),
        .O_all_failed(),.O_watchdog_expired(),.O_fault(O_fault),
        .O_changed(O_changed),
        .O_error(O_error),
        .O_current_index(O_current_index),
        .O_count(O_count),
        .O_generation(O_generation),
        .O_revision(O_revision),
        .O_item_start_valid(O_item_start_valid),
        .I_item_start_ready(I_item_start_ready),
        .O_item_index(O_item_index),
        .O_item_tag(O_item_tag),
        .O_item_revision(O_item_revision),
        .O_item_abort(O_item_abort),
        .I_item_done_valid(I_item_done_valid),
        .O_item_done_ready(O_item_done_ready),
        .I_item_error(I_item_error),
        .I_item_generation(I_item_generation),
        .I_item_revision(I_item_revision),
        .I_item_count(I_item_count),
        .I_item_file_length(I_item_file_length),
        .I_item_audio_length(I_item_audio_length),
        .I_item_title_length(6'd0),.I_item_duration(I_item_duration),
        .I_item_transition_ms(I_item_transition_ms),
        .I_item_transition(I_item_transition),
        .I_item_policy(I_item_policy),
        .O_item_string_kind(O_item_string_kind),
        .O_item_string_address(O_item_string_address),
        .I_item_string_data(I_item_string_data),
        .O_image_start_valid(O_image_start_valid),
        .I_image_start_ready(I_image_start_ready),
        .O_image_tag(O_image_tag),
        .O_image_generation(O_image_generation),
        .O_image_asset(O_image_asset),
        .O_image_layout(O_image_layout),
        .O_image_rotation(O_image_rotation),
        .O_image_bilinear(O_image_bilinear),
        .O_image_abort(O_image_abort),
        .O_image_path_length(O_image_path_length),
        .O_image_path_valid(O_image_path_valid),
        .I_image_path_ready(I_image_path_ready),
        .O_image_path_data(O_image_path_data),
        .O_image_path_last(O_image_path_last),
        .I_image_done_valid(I_image_done_valid),
        .O_image_done_ready(O_image_done_ready),
        .I_image_error(I_image_error),
        .I_image_tag(I_image_tag),
        .I_image_generation(I_image_generation),
        .I_image_progress(1'b0),.I_image_pixels(32'd0),.I_image_retired_writes(32'd0),.I_image_token(I_image_token),
        .I_image_slot(I_image_slot),
        .I_image_stage_valid(I_image_stage_valid),
        .I_image_quarantined(I_image_quarantined),
        .O_image_stage_release_valid(O_image_stage_release_valid),
        .I_image_stage_release_ready(I_image_stage_release_ready),
        .O_image_stage_slot(O_image_stage_slot),
        .O_image_stage_token(O_image_stage_token),
        .O_image_stage_generation(O_image_stage_generation),
        .O_image_stage_discard(O_image_stage_discard),
        .O_audio_file_start_valid(O_audio_file_start_valid),
        .I_audio_file_start_ready(I_audio_file_start_ready),
        .O_audio_file_tag(O_audio_file_tag),
        .O_audio_file_generation(O_audio_file_generation),
        .O_audio_file_path_length(O_audio_file_path_length),
        .O_audio_file_path_valid(O_audio_file_path_valid),
        .I_audio_file_path_ready(I_audio_file_path_ready),
        .O_audio_file_path_data(O_audio_file_path_data),
        .O_audio_file_path_last(O_audio_file_path_last),
        .O_audio_file_abort(O_audio_file_abort),
        .I_audio_file_done_valid(I_audio_file_done_valid),
        .O_audio_file_done_ready(O_audio_file_done_ready),
        .I_audio_file_error(I_audio_file_error),
        .I_audio_file_tag(I_audio_file_tag),
        .O_audio_recycle_valid(O_audio_recycle_valid),
        .I_audio_recycle_ready(I_audio_recycle_ready),
        .I_audio_recycle_done(I_audio_recycle_done),
        .I_audio_available(I_audio_available),
        .I_bgm_need(I_bgm_need),
        .I_bgm_start_ready(I_bgm_start_ready),
        .I_bgm_done_valid(I_bgm_done_valid),
        .I_bgm_result(I_bgm_result),
        .O_bgm_start_valid(O_bgm_start_valid),
        .O_bgm_slot(O_bgm_slot),
        .O_bgm_abort(O_bgm_abort),
        .O_bgm_done_ready(O_bgm_done_ready),
        .O_bgm_track_epoch(O_bgm_track_epoch),
        .O_command_valid(O_command_valid),
        .I_command_ready(I_command_ready),
        .O_command(O_command),
        .O_dwell_seconds(O_dwell_seconds),
        .O_command_abort(O_command_abort),
        .I_command_done_valid(I_command_done_valid),
        .O_command_done_ready(O_command_done_ready),
        .I_command_result(I_command_result),
        .I_dwell_expired(I_dwell_expired),
        .O_response_discarded(O_response_discarded),
        .I_index_revision(32'd1),
        .O_titles(),.O_title_lengths(),.O_view(S_layout_view),
        .O_image_compose(S_compose),
        .O_image_parts(S_parts),
        .I_image_part_needed(1'b0),
        .I_image_part_index(4'd0),
        .O_image_part_valid(S_part_valid),
        .I_image_part_ready(1'b0),
        .O_image_part_path_length(S_part_path_length),
        .I_order_hold(1'b0),
        .I_order_applied(1'b0),
        .I_order_generation(32'd0),
        .I_order_revision(32'd0),
        .I_order_index(6'd0),
        .I_alert(1'b0),
        .I_resident_ready(1'b0),
        .I_resident_token(32'd0),
        .O_alert_hold(),
        .O_alert_visible(),
        .I_audio_bookmark(64'd0),
        .O_audio_file_start_index(),
        .O_alert_restoring()
    );
    reg S_test_pass=0;
    always #4 I_clk=~I_clk;
    reg [511:0] S_file="/PLAY/A.BMP",S_audio="/PLAY/BGM.WAV";
    reg [1:0] S_recycle_1=0,S_recycle_2=0;
    reg S_item_pending=0,S_image_pending=0,S_loop_pending=0;
    reg S_active_b=0;
    reg [1:0] S_enabled=0;
    integer S_images=0,S_opens=0,S_commands=0,S_loops=0,S_retirements=0;
    integer S_expected_duration=8,S_expected_effect=2,S_expected_frames=12;
    reg [403:0] S_held;
    reg [6:0] S_audio_position[0:1];
    integer S_slot,S_target,S_before,S_before_commands,S_before_images;
    task fail;
        input [767:0] message;
        begin $display("FAIL playlist policy: %0s",message); $stop; end
    endtask
    always @(posedge I_clk) begin
        if(!I_reset) begin
            I_item_string_data<=O_item_string_kind==1 ?
                (O_item_string_address<I_item_audio_length ? S_audio[(I_item_audio_length-1-O_item_string_address)*8+:8] : 8'd0) :
                (O_item_string_address<I_item_file_length ? S_file[(I_item_file_length-1-O_item_string_address)*8+:8] : 8'd0);
            if(O_item_start_valid && I_item_start_ready) S_item_pending<=1;
            if(S_item_pending) begin S_item_pending<=0; I_item_done_valid<=1; end
            if(I_item_done_valid && O_item_done_ready) I_item_done_valid<=0;
            if(O_image_start_valid && I_image_start_ready) begin
                S_images=S_images+1; S_image_pending<=1;
                I_image_tag<=O_image_tag; I_image_generation<=O_image_generation;
                I_image_token<=S_images; I_image_slot<=(S_images-1)%6;
            end
            if(S_image_pending && O_image_path_valid && I_image_path_ready && O_image_path_last) begin
                S_image_pending<=0; I_image_done_valid<=1;
            end
            if(I_image_done_valid && O_image_done_ready) I_image_done_valid<=0;
            S_recycle_1<=O_audio_recycle_valid & I_audio_recycle_ready;
            S_recycle_2<=S_recycle_1; I_audio_recycle_done<=S_recycle_2;
            if(|S_recycle_2) S_retirements=S_retirements+1;
            for(S_slot=0;S_slot<2;S_slot=S_slot+1) begin
                if(O_audio_file_start_valid[S_slot] && I_audio_file_start_ready[S_slot]) begin
                    S_opens=S_opens+1; S_audio_position[S_slot]<=0;
                end
                if(O_audio_file_path_valid[S_slot] && I_audio_file_path_ready[S_slot]) begin
                    if(O_audio_file_path_data[S_slot*8+:8]!==S_audio[(I_item_audio_length-1-S_audio_position[S_slot])*8+:8])
                        fail("file path changed, including BGM loop RAM path");
                    S_audio_position[S_slot]<=S_audio_position[S_slot]+1'b1;
                end
            end
            if(O_command_valid && I_command_ready) begin
                if(O_dwell_seconds!=S_expected_duration || O_command[105:90]!=S_expected_frames ||
                    (S_expected_effect==7 ? O_command[108:106]>6 : O_command[108:106]!=S_expected_effect))
                    fail("ITEM/GLOBAL/runtime priority, frames or random effect");
                S_commands=S_commands+1;
                if(O_command[82:81]==1 || O_command[82:81]==2) begin
                    S_active_b=O_command[80]; S_enabled=2'b01<<S_active_b;
                end else if(O_command[82:81]==0 && O_command[80]) S_enabled=0;
                I_command_result<={O_command[403:356],4'd0,1'b1,!O_command[353],4'd0,
                    32'd123,S_active_b,2'b11,S_enabled,33'd0};
                I_command_done_valid<=1;
            end
            if(I_command_done_valid && O_command_done_ready) I_command_done_valid<=0;
            if(O_bgm_start_valid && I_bgm_start_ready) begin
                I_bgm_need<=0; S_loop_pending<=1; S_target=O_bgm_slot;
            end
            if(S_loop_pending) begin
                S_loop_pending<=0; S_loops=S_loops+1; S_active_b=S_target;
                S_enabled=2'b01<<S_active_b;
                I_bgm_result<={4'd0,1'b0,S_active_b,S_enabled}; I_bgm_done_valid<=1;
            end
            if(I_bgm_done_valid && O_bgm_done_ready) I_bgm_done_valid<=0;
        end
    end
    task finished;
        input integer count;
        begin
            wait(S_commands==count); wait(!O_busy); repeat(3) @(negedge I_clk);
            if(O_fault || O_error) fail("application fault or item error");
        end
    endtask
    task next_item;
        begin @(negedge I_clk); I_next=1; @(negedge I_clk); I_next=0; end
    endtask
    initial begin
        I_reset=1; I_item_file_length=11; I_item_audio_length=13;
        I_item_generation=7; I_item_revision=1; I_item_count=3;
        I_media_generation=7; I_media_valid=1; I_session_ready=1;
        I_item_start_ready=1; I_image_start_ready=1; I_image_path_ready=1;
        I_image_stage_valid=1; I_image_stage_release_ready=1;
        I_audio_file_start_ready=3; I_audio_file_path_ready=3;
        I_audio_recycle_ready=3; I_audio_available=3;
        I_command_ready=1; I_bgm_start_ready=1;
        I_default_duration=10; I_default_transition=0; I_default_transition_ms=400;
        I_saturation=8;
        I_item_policy=7'h7f; I_item_duration=8; I_item_transition=2; I_item_transition_ms=200;
        repeat(5) @(negedge I_clk); I_reset=0; I_enable=1;
        finished(1); if(S_opens!=1) fail("initial BGM not opened once");

        // GLOBAL is explicit, but a runtime override supersedes inherited fields.
        I_item_policy=7'h78; I_item_duration=30; I_item_transition=7; I_item_transition_ms=600;
        I_default_override=7; I_default_duration=20; I_default_transition=7; I_default_transition_ms=1000;
        S_expected_duration=20; S_expected_effect=7; S_expected_frames=60; I_command_ready=0;
        next_item(); wait(O_item_start_valid); @(negedge I_clk); I_default_duration=99;
        wait(O_command_valid); @(negedge I_clk); S_held=O_command;
        repeat(12) begin
            @(negedge I_clk);
            if(!O_command_valid || O_command!==S_held || O_dwell_seconds!=20) fail("random/command/defaults not frozen");
        end
        I_command_ready=1; finished(2);
        if(S_opens!=1) fail("same GLOBAL BGM reopened across images");

        // Same path length is insufficient: compare every byte.
        S_audio="/PLAY/ALT.WAV"; I_default_duration=20;
        next_item(); finished(3); if(S_opens!=2) fail("different BGM path reused");
        // Explicit ITEM fields survive runtime overrides; inherited ms uses runtime.
        S_audio="/PLAY/OWN.WAV"; I_item_policy=7'h3b;
        I_item_duration=11; I_item_transition=1; I_item_transition_ms=600;
        I_default_transition_ms=200; S_expected_duration=11; S_expected_effect=1; S_expected_frames=12;
        next_item(); finished(4); if(S_opens!=3) fail("ITEM audio did not replace BGM");
        I_item_audio_length=0; I_item_policy=0;
        I_default_duration=15; I_default_transition=4; I_default_transition_ms=400;
        S_expected_duration=15; S_expected_effect=4; S_expected_frames=24;
        next_item(); finished(5); if(S_enabled!=0 || S_opens!=3) fail("no-audio item did not issue silence");

        S_audio="/PLAY/BGM.WAV"; I_item_audio_length=13; I_item_policy=7'h78;
        next_item(); finished(6); if(S_opens!=4) fail("BGM after leaving it did not restart");
        S_before_images=S_images; S_before_commands=S_commands; S_before=S_retirements;
        @(negedge I_clk); I_bgm_need=1;
        wait(S_loops==1); wait(S_retirements>=S_before+2); repeat(8) @(negedge I_clk);
        if(S_opens!=5 || S_images!=S_before_images || S_commands!=S_before_commands)
            fail("BGM loop reset display/dwell or did not reopen alternate context");
        next_item(); finished(7); if(S_opens!=5) fail("post-loop same BGM lost continuity identity");
        S_test_pass=1; $display("PASS: actual playlist owner inheritance/random/BGM identity/loop path/silence policies"); $finish;
    end
    initial begin #2000000; fail("watchdog"); end
endmodule
