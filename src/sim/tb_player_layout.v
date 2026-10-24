`timescale 1ns/1ps
// Actual application owner. Item/image/audio/display peers are protocol endpoints.
// Real pixel composition is checked separately by tb_bmp_frame_loader.
module tb_player_layout;
    reg I_clk=0;
    reg I_reset=0;
    reg I_enable=0;
    reg I_auto=0;
    reg I_pause=0;
    reg S_alert=0,S_delay_result=0,S_result_pending=0;
    wire S_alert_hold,S_alert_visible,S_alert_restoring;
    wire [63:0] S_audio_start_index;
    reg S_normal_audio_slot=0;
    reg I_session_ready=0;
    reg I_session_abort=0;
    reg I_media_valid=0;
    reg [31:0] I_media_generation=0;
    reg S_order_hold=0,S_order_applied=0;
    reg [31:0] S_order_revision=3;
    reg [5:0] S_order_index=3;
    reg [31:0] I_index_revision=0;
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
    wire [22:0] O_view;
    wire [2879:0] S_titles;
    wire [53:0] S_title_lengths;
    wire S_all_failed;
    wire S_watchdog_expired;
    reg [5:0] S_item_title_length=0;
    reg S_fail_all=0;
    integer S_label_slot,S_label_index;
    reg [63:0] S_label_path;
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
    wire O_image_compose;
    wire [3:0] O_image_parts;
    reg I_image_part_needed=0;
    reg [3:0] I_image_part_index=0;
    wire O_image_part_valid;
    reg I_image_part_ready=0;
    wire [6:0] O_image_part_path_length;
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
    playlist_player_ctrl #(.WATCHDOG_CYCLES(30'd10000)) u_app (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_enable(I_enable),
        .I_auto(I_auto),
        .I_pause(I_pause),
        .I_session_ready(I_session_ready),
        .I_session_abort(I_session_abort),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_index_revision(I_index_revision),
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
        .O_titles(S_titles),.O_title_lengths(S_title_lengths),.O_view(O_view),
        .O_active_valid(O_active_valid),
        .O_all_failed(S_all_failed),.O_watchdog_expired(S_watchdog_expired),.O_fault(O_fault),
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
        .I_item_title_length(S_item_title_length),.I_item_duration(I_item_duration),
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
        .O_image_compose(O_image_compose),
        .O_image_parts(O_image_parts),
        .I_image_part_needed(I_image_part_needed),
        .I_image_part_index(I_image_part_index),
        .O_image_part_valid(O_image_part_valid),
        .I_image_part_ready(I_image_part_ready),
        .O_image_part_path_length(O_image_part_path_length),
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
        .I_order_hold(S_order_hold),
        .I_order_applied(S_order_applied),
        .I_order_generation(32'd7),
        .I_order_revision(S_order_revision),
        .I_order_index(S_order_index),
        .I_alert(S_alert),
        .I_resident_ready(1'b1),
        .I_resident_token(32'hf00d),
        .O_alert_hold(S_alert_hold),
        .O_alert_visible(S_alert_visible),
        .I_audio_bookmark({32'd5678,32'd1234}),
        .O_audio_file_start_index(S_audio_start_index),
        .O_alert_restoring(S_alert_restoring)
    );
    always #4 I_clk=~I_clk;
    reg S_test_pass=0,S_item_pending=0,S_image_live=0;
    reg [5:0] S_copy_index=0;
    reg [3:0] S_parts=1,S_part=0;
    reg [1:0] S_recycle_1=0,S_recycle_2=0;
    reg S_source=0;
    integer S_fetches=0,S_images=0,S_commands=0,S_opens=0;
    integer S_expected_index=0,S_expected_layout=0,S_path_position=0;
    integer S_audio_position[0:1];
    integer S_slot,S_picture,S_before_images,S_before_fetches,S_before_commands,S_before_opens;
    reg S_reject=0;
    reg [63:0] S_expected_path;
    reg [15:0] S_osd_x=0,S_osd_y=0;
    reg S_osd_de=1;
    wire [23:0] S_osd_rgb;
    player_status_osd u_osd (
        .I_de(S_osd_de),.I_valid(1'b1),.I_x(S_osd_x),.I_y(S_osd_y),.I_state(16'd0),
        .I_menu_info(16'd0),.I_menu_value(16'd0),.I_view(O_view),.I_rgb(24'h123456),.O_rgb(S_osd_rgb)
    );
    function [63:0] item_path;
        input [5:0] index;
        input audio;
        reg [7:0] tens,units;
        begin
            tens=8'd48+index/10; units=8'd48+index%10;
            item_path=audio ? {"/A",tens,units,".WAV"} : {"/I",tens,units,".BMP"};
        end
    endfunction
    task fail;
        input [767:0] message;
        begin $display("FAIL player_layout: %0s",message); $stop; end
    endtask
    always @(posedge I_clk) begin
        if(!I_reset) begin
            S_expected_path=item_path(S_copy_index,O_item_string_kind==1);
            if(O_item_string_kind==2) begin
                case(O_item_string_address)
                    0:I_item_string_data<=8'hd6;
                    1:I_item_string_data<=8'hd0;
                    2:I_item_string_data<=8'hce;
                    default:I_item_string_data<=8'hc4;
                endcase
            end else I_item_string_data<=S_expected_path[(7-O_item_string_address)*8+:8];
            if(O_item_start_valid && I_item_start_ready) begin
                S_fetches=S_fetches+1; S_item_pending<=1; S_copy_index<=O_item_index;
                if(O_item_revision!=0 && O_item_revision!=I_index_revision) fail("secondary fetch lost frozen revision");
                I_item_error<=S_fail_all || (S_reject && S_image_live) ? 4'd4 : 4'd0;
                S_item_title_length<=O_item_index==7 ? 6'd4 : 6'd0;
            end
            if(S_item_pending) begin S_item_pending<=0; I_item_done_valid<=1; end
            if(I_item_done_valid && O_item_done_ready) I_item_done_valid<=0;
            if(O_image_start_valid && I_image_start_ready) begin
                if(!O_image_compose || O_image_layout!=S_expected_layout) fail("layout missing actual image consumer");
                S_images=S_images+1; S_image_live<=1; S_part<=0; S_parts<=O_image_parts; S_path_position=0;
                I_image_tag<=O_image_tag; I_image_generation<=O_image_generation;
                I_image_slot<=S_images%5; I_image_token<=S_images; I_image_stage_valid<=1;
                I_image_error<=0;
                if(O_image_parts!=(S_expected_layout==0 ? 1 : S_expected_layout<3 ? 2 :
                    S_expected_layout==3 ? 4 : S_expected_index<9 ? 9 : 3)) fail("wrong part count or final THUMB page");
            end
            if(O_image_part_valid && I_image_part_ready) begin
                S_part<=I_image_part_index; I_image_part_needed<=0; S_path_position=0;
            end
            if(O_image_path_valid && I_image_path_ready) begin
                S_picture=S_expected_layout==4 ? (S_expected_index/9)*9+S_part : (S_expected_index+S_part)%12;
                S_expected_path=item_path(S_picture,0);
                if(O_image_path_data!==S_expected_path[(7-S_path_position)*8+:8] ||
                    O_image_path_last!==(S_path_position==7)) fail("wrong composed picture or path byte");
                S_path_position=S_path_position+1;
                if(O_image_path_last) begin
                    if(S_part+1<S_parts) begin I_image_part_needed<=1; I_image_part_index<=S_part+1'b1; end
                    else begin I_image_done_valid<=1; S_image_live<=0; end
                end
            end
            if(S_image_live && O_image_abort) begin
                S_image_live<=0; I_image_part_needed<=0; I_image_done_valid<=1;
                I_image_error<=3; I_image_stage_valid<=0;
            end
            if(I_image_done_valid && O_image_done_ready) I_image_done_valid<=0;
            S_recycle_1<=O_audio_recycle_valid & I_audio_recycle_ready;
            S_recycle_2<=S_recycle_1; I_audio_recycle_done<=S_recycle_2;
            for(S_slot=0;S_slot<2;S_slot=S_slot+1) begin
                if(O_audio_file_start_valid[S_slot] && I_audio_file_start_ready[S_slot]) begin
                    S_audio_position[S_slot]=0; S_opens=S_opens+1;
                    if(S_alert_restoring && (S_slot!=0 || S_audio_start_index[31:0]!=(S_normal_audio_slot ? 32'd5678 : 32'd1234)))
                        fail("alert resume did not use chosen track bookmark");
                end
                if(O_audio_file_path_valid[S_slot] && I_audio_file_path_ready[S_slot]) begin
                    S_expected_path=item_path(S_expected_index,1);
                    if(O_audio_file_path_data[S_slot*8+:8]!==S_expected_path[(7-S_audio_position[S_slot])*8+:8])
                        fail("secondary image fetch overwrote selected audio path");
                    S_audio_position[S_slot]=S_audio_position[S_slot]+1;
                end
            end
            if(O_command_valid && I_command_ready) begin
                S_commands=S_commands+1; S_source=!S_source;
                if(!S_alert_hold) S_normal_audio_slot=O_command[80];
                if(S_alert && (O_command[218:217]!=3 || O_command[352:347]!={3'd5,3'd5} ||
                    O_command[82:80]!=0 || O_command[346:283]!={32'hf00d,32'hf00d}))
                    fail("resident alert command lost slot/token/resident or changed track lifecycle");
                I_command_result<={O_command[403:356],4'd0,1'b1,S_source,4'd0,
                    32'd123,O_command[80],2'b11,(2'b01<<O_command[80]),33'd0};
                S_result_pending<=1;
            end
            if(S_result_pending && !S_delay_result) begin S_result_pending<=0; I_command_done_valid<=1; end
            if(I_command_done_valid && O_command_done_ready) I_command_done_valid<=0;
        end
    end
    task completed;
        input integer commands;
        begin
            wait(S_commands==commands); wait(!O_busy); repeat(4) @(negedge I_clk);
            if(O_fault || O_error || O_current_index!=S_expected_index || O_view[21:19]!=S_expected_layout)
                fail("layout did not settle with actual display result");
            for(S_label_slot=0;S_label_slot<9;S_label_slot=S_label_slot+1) begin
                S_label_index=S_expected_layout==4 ? (S_expected_index/9)*9+S_label_slot : S_expected_index;
                if((S_expected_layout==4 && S_label_index<12) || (S_expected_layout!=4 && S_label_slot==0)) begin
                    if(S_label_index==7) begin
                        if(S_title_lengths[S_label_slot*6+:6]!==4 || S_titles[S_label_slot*320+288+:32]!==32'hd6d0cec4)
                            fail("explicit GB2312 title changed or was replaced by another item");
                    end else begin
                        S_label_path=item_path(S_label_index,0);
                        if(S_title_lengths[S_label_slot*6+:6]!==3 || S_titles[S_label_slot*320+296+:24]!==S_label_path[55:32])
                            fail("basename label does not match the actually presented atlas");
                    end
                end else if(S_title_lengths[S_label_slot*6+:6]!==0) fail("unused label retained stale text");
            end
        end
    endtask
    task go;
        input integer index,layout;
        begin
            @(negedge I_clk); S_expected_index=index; S_expected_layout=layout;
            I_layout=layout; I_goto_index=index; I_goto_valid=1;
            @(negedge I_clk); I_goto_valid=0;
        end
    endtask
    task unchanged;
        begin
            if(S_images!=S_before_images || S_fetches!=S_before_fetches ||
                S_commands!=S_before_commands || S_opens!=S_before_opens)
                fail("same-page selection reloaded atlas/audio or restarted transition");
        end
    endtask
    initial begin
        I_reset=1; I_item_file_length=8; I_item_audio_length=8; I_item_duration=10;
        I_item_transition_ms=400; I_item_count=12; I_item_revision=1; I_index_revision=1;
        I_item_generation=7; I_media_generation=7; I_media_valid=1; I_session_ready=1;
        I_item_start_ready=1; I_image_start_ready=1; I_image_path_ready=1; I_image_part_ready=1;
        I_image_stage_release_ready=1; I_audio_file_start_ready=3; I_audio_file_path_ready=3;
        I_audio_recycle_ready=3; I_audio_available=3; I_command_ready=1;
        I_default_duration=10; I_default_transition_ms=400; I_saturation=8;
        repeat(5) @(negedge I_clk); I_reset=0; I_enable=1;
        completed(1);
        go(11,1); completed(2); // PIP wraps to index zero.
        go(2,2); completed(3);
        go(10,3); completed(4); // QUAD wraps 10,11,0,1.
        go(7,4); completed(5); // Selected metadata/audio=7, atlas starts at zero.
        S_osd_x=213; S_osd_y=320; #1;
        if(S_osd_rgb!==24'hffff40) fail("selected THUMB cell did not have an OSD border");
        S_before_images=S_images; S_before_fetches=S_fetches;
        S_before_commands=S_commands; S_before_opens=S_opens;
        @(negedge I_clk); S_expected_index=8; I_next=1;
        @(negedge I_clk); I_next=0;
        wait(O_busy); wait(!O_busy); repeat(8) @(negedge I_clk);
        unchanged;
        if(O_current_index!=8 || O_view[12:7]!=8) fail("focus did not move");
        #1; if(S_osd_rgb!==24'h123456) fail("old focus border was baked into atlas");
        S_osd_x=426; #1; if(S_osd_rgb!==24'hffff40) fail("new focus border missing");
        S_osd_de=0; #1; if(S_osd_rgb!==0) fail("OSD leaked into blanking");
        S_osd_de=1;
        I_auto=1; I_dwell_expired=1; repeat(50) @(negedge I_clk); unchanged;
        I_auto=0; I_dwell_expired=0;
        go(9,4); completed(6); if(O_view[18:13]!=9) fail("final page base");
        go(8,4); completed(7);
        // A changed index revision invalidates the same-page atlas shortcut.
        I_index_revision=2; I_item_revision=2; go(8,4); completed(8);
        go(8,0); completed(9);
        S_before_images=S_images; S_before_fetches=S_fetches;
        S_before_commands=S_commands; S_before_opens=S_opens;
        // A FULL frame remains the same physical asset after its index is relocated.
        @(negedge I_clk); S_order_hold=1; I_index_revision=3; I_item_revision=3; S_order_applied=1;
        @(negedge I_clk); S_order_applied=0; repeat(4) @(negedge I_clk);
        if(O_current_index!=3 || O_revision!=3) fail("FULL reindex did not relocate current logical item");
        unchanged; S_expected_index=3; S_order_hold=0;
        repeat(6) @(negedge I_clk); unchanged;
        go(4,4); completed(10);
        // Keep the old atlas label identity until the new order is actually rendered.
        @(negedge I_clk); S_order_hold=1; I_next=1;
        @(negedge I_clk); I_next=0; repeat(3) @(negedge I_clk);
        S_order_index=10; S_order_revision=4; I_index_revision=4; I_item_revision=4; S_order_applied=1;
        @(negedge I_clk); S_order_applied=0; repeat(3) @(negedge I_clk);
        if(O_current_index!=10 || O_view[12:7]!=4 || O_view[18:13]!=0)
            fail("new logical index corrupted labels on the old THUMB atlas");
        S_expected_index=11; S_order_hold=0; completed(11);
        if(O_view[18:13]!=9 || O_view[12:7]!=11) fail("queued relative navigation or multi-layout redraw after sort");
        go(8,0); completed(12);
        // Failed secondary lookup must abort the real image owner and retain the front frame.
        S_reject=1; go(10,3); wait(O_image_abort); I_pause=1; wait(!O_busy); repeat(10) @(negedge I_clk);
        if(S_commands!=12 || O_current_index!=8 || O_view[21:19]!=0 || O_fault || O_error==0)
            fail("failed multi-part frame replaced front or leaked application ownership");
        // Every lookup fails: exactly one finite pass, preserving the front image.
        S_reject=0; S_fail_all=1; S_before_fetches=S_fetches;
        go(0,0); I_pause=0; wait(S_all_failed); repeat(10) @(negedge I_clk);
        if(S_fetches-S_before_fetches!=12 || O_busy || O_fault || O_current_index!=8 || O_error!=10)
            fail("all-bad playlist did not stop after one pass with retained foreground");
        S_before_fetches=S_fetches; repeat(200) @(negedge I_clk);
        if(S_fetches!=S_before_fetches) fail("all-bad playlist retried forever");
        S_fail_all=0; go(2,0); completed(13);
        if(S_all_failed) fail("manual navigation did not recover from all-bad latch");
        // A blocked offer times out through real cancellation; PAUSE excludes elapsed idle time.
        I_image_start_ready=0; I_item_count=1; go(0,0); wait(O_image_start_valid);
        @(negedge I_clk); I_pause=1;
        repeat(12000) @(negedge I_clk);
        if(S_watchdog_expired || O_image_abort) fail("watchdog counted a paused transaction");
        I_pause=0; wait(S_watchdog_expired); wait(S_all_failed);
        repeat(10) @(negedge I_clk);
        if(O_fault || O_busy || O_current_index!=2 || S_commands!=13)
            fail("timeout fabricated image completion or discarded the foreground");
        I_item_count=12; I_image_start_ready=1; go(3,0); completed(14);
        // Alert waits for genuine command retirement, overrides user pause, and
        // restores the same frame without reopening any image or replacing its labels.
        S_before_images=S_images; S_before_fetches=S_fetches; S_before_opens=S_opens;
        @(negedge I_clk); I_pause=1; S_delay_result=1; S_alert=1;
        wait(S_commands==15); repeat(12) @(negedge I_clk);
        if(S_alert_visible || !S_alert_hold || S_images!=S_before_images || S_fetches!=S_before_fetches)
            fail("alert became visible without a real result or read another file");
        S_delay_result=0; wait(S_alert_visible); repeat(8) @(negedge I_clk);
        if(O_view[22] || O_fault) fail("normal overlay was not isolated during alert");
        S_alert=0; wait(S_alert_restoring); wait(S_commands==16); wait(!S_alert_hold);
        repeat(8) @(negedge I_clk);
        if(S_alert_visible || O_fault || O_current_index!=3 || S_images!=S_before_images ||
            S_fetches!=S_before_fetches || S_opens!=S_before_opens+1 || !O_view[22])
            fail("alert did not restore the selected frame and reopen its saved track exactly once");
        // A no-card alert still uses the resident transaction; expiry abandons stale bookmarks.
        I_media_valid=0; I_session_ready=0; S_alert=1; wait(S_alert_visible);
        S_alert=0; wait(!S_alert_hold); repeat(8) @(negedge I_clk);
        if(O_active_valid || O_fault) fail("media change restored a stale ordinary slot");
        S_test_pass=1; $display("PASS: real layout scheduler, wrap, cached audio, THUMB page/focus/revision and failed-part retirement"); $finish;
    end
    initial begin #2000000; fail("watchdog"); end
endmodule
