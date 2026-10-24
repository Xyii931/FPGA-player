// Host-domain application owner. All video commands/proofs use player_control_cdc.
// No assumed file completion, slot retirement or display apply acknowledgements.
module playlist_player_ctrl #(
    parameter [29:0] WATCHDOG_CYCLES=30'd625000000
) (
    input wire I_clk,I_reset,I_enable,I_auto,I_pause,I_session_ready,I_session_abort,
    input wire I_media_valid,
    input wire I_alert,I_resident_ready,
    input wire [31:0] I_resident_token,
    output wire O_alert_hold,
    output reg O_alert_visible,
    output wire O_alert_restoring,
    input wire [31:0] I_media_generation,I_index_revision,
    input wire I_order_hold,I_order_applied,
    input wire [31:0] I_order_generation,I_order_revision,
    input wire [5:0] I_order_index,
    input wire I_next,I_prev,I_goto_valid,
    input wire [5:0] I_goto_index,
    input wire [2:0] I_layout,
    input wire [1:0] I_rotation,
    input wire I_bilinear,
    input wire [3:0] I_brightness,I_contrast,
    input wire [4:0] I_saturation,
    input wire signed [6:0] I_av_offset_steps,
    input wire [2:0] I_default_override,
    input wire [9:0] I_default_duration,I_default_transition_ms,
    input wire [2:0] I_default_transition,
    output wire O_busy,
    output wire [22:0] O_view,
    output reg [2879:0] O_titles,
    output reg [53:0] O_title_lengths,
    output reg O_active_valid,O_fault,O_changed,
    output reg O_all_failed,O_watchdog_expired,
    output reg [3:0] O_error,
    output reg [5:0] O_current_index,
    output reg [6:0] O_count,
    output reg [31:0] O_generation,O_revision,
    output wire O_item_start_valid,
    input wire I_item_start_ready,
    output wire [5:0] O_item_index,
    output wire [15:0] O_item_tag,
    output wire [31:0] O_item_revision,
    output wire O_item_abort,
    input wire I_item_done_valid,
    output wire O_item_done_ready,
    input wire [3:0] I_item_error,
    input wire [31:0] I_item_generation,I_item_revision,
    input wire [6:0] I_item_count,I_item_file_length,I_item_audio_length,
    input wire [5:0] I_item_title_length,
    input wire [9:0] I_item_duration,I_item_transition_ms,
    input wire [2:0] I_item_transition,
    input wire [6:0] I_item_policy,
    output wire [1:0] O_item_string_kind,
    output wire [6:0] O_item_string_address,
    input wire [7:0] I_item_string_data,
    output wire O_image_start_valid,
    input wire I_image_start_ready,
    output wire [15:0] O_image_tag,
    output wire [31:0] O_image_generation,O_image_asset,
    output wire [2:0] O_image_layout,
    output wire O_image_compose,
    output wire [3:0] O_image_parts,
    input wire I_image_part_needed,
    input wire [3:0] I_image_part_index,
    output wire O_image_part_valid,
    input wire I_image_part_ready,
    output wire [6:0] O_image_part_path_length,
    output wire [1:0] O_image_rotation,
    output wire O_image_bilinear,O_image_abort,
    output wire [6:0] O_image_path_length,
    output wire O_image_path_valid,
    input wire I_image_path_ready,
    output wire [7:0] O_image_path_data,
    output wire O_image_path_last,
    input wire I_image_done_valid,
    output wire O_image_done_ready,
    input wire [3:0] I_image_error,
    input wire [15:0] I_image_tag,
    input wire [31:0] I_image_generation,I_image_token,
    input wire [31:0] I_image_pixels,I_image_retired_writes,
    input wire I_image_progress,
    input wire [2:0] I_image_slot,
    input wire I_image_stage_valid,I_image_quarantined,
    output wire O_image_stage_release_valid,
    input wire I_image_stage_release_ready,
    output wire [2:0] O_image_stage_slot,
    output wire [31:0] O_image_stage_token,O_image_stage_generation,
    output wire O_image_stage_discard,
    output wire [1:0] O_audio_file_start_valid,
    input wire [1:0] I_audio_file_start_ready,
    output wire [31:0] O_audio_file_tag,
    output wire [63:0] O_audio_file_generation,O_audio_file_start_index,
    output wire [13:0] O_audio_file_path_length,
    output wire [1:0] O_audio_file_path_valid,
    input wire [1:0] I_audio_file_path_ready,
    output wire [15:0] O_audio_file_path_data,
    output wire [1:0] O_audio_file_path_last,O_audio_file_abort,
    input wire [1:0] I_audio_file_done_valid,
    output wire [1:0] O_audio_file_done_ready,
    input wire [7:0] I_audio_file_error,
    input wire [31:0] I_audio_file_tag,
    output wire [1:0] O_audio_recycle_valid,
    input wire [1:0] I_audio_recycle_ready,I_audio_recycle_done,I_audio_available,
    input wire I_bgm_need,I_bgm_start_ready,I_bgm_done_valid,
    input wire [7:0] I_bgm_result,
    output wire O_bgm_start_valid,O_bgm_slot,O_bgm_abort,O_bgm_done_ready,
    output wire [15:0] O_bgm_track_epoch,
    output wire O_command_valid,
    input wire I_command_ready,
    output wire [403:0] O_command,
    output wire [9:0] O_dwell_seconds,
    output wire O_command_abort,
    input wire I_command_done_valid,
    output wire O_command_done_ready,
    input wire [127:0] I_command_result,
    input wire [63:0] I_audio_bookmark,
    input wire I_dwell_expired,
    output reg O_response_discarded
);
    localparam [5:0] MEDIA=0,FETCH_OFFER=1,FETCH_WAIT=2,IMAGE_OFFER=3,IMAGE_WAIT=4,
        RECYCLE=5,AUDIO_OFFER=6,AUDIO_PATH=7,COMMAND_OFFER=8,COMMAND_WAIT=9,
        STAGE=10,DWELL=11,FAULT=12,BGM_ADDRESS=13,BGM_WAIT=14,BGM_CHECK=15,
        LOOP_OFFER=16,LOOP_WAIT=17,PART_FETCH_OFFER=18,PART_FETCH_WAIT=19,
        PART_OFFER=20,IMAGE_PREP=21,THUMB_FOCUS=22,TITLE_ADDRESS=23,TITLE_WAIT=24,TITLE_COPY=25,
        ALERT_PREP=26,ALERT_OFFER=27,ALERT_WAIT=28,ALERT_HOLD=29,RESTORE_OFFER=30,RESTORE_WAIT=31,ALERT_AUDIO_START=32,ALERT_AUDIO_PATH=33,ALERT_ABANDON=34;
    localparam [1:0] PATH_IDLE=0,PATH_READ=1,PATH_OFFER=2;
    reg [5:0] S_state,S_after_recycle;
    reg [5:0] S_watch_state;
    reg [29:0] S_watch_cycles;
    reg [31:0] S_watch_pixels,S_watch_writes;
    reg [6:0] S_bad_count;
    reg S_failure_accounted,S_watch_cancel;
    reg S_alert_pending,S_alert_saved_valid;
    reg [2:0] S_alert_saved_slot;
    reg [31:0] S_alert_saved_token,S_alert_saved_generation;
    reg S_alert_saved_resident;
    reg S_alert_reloading,S_current_has_audio,S_current_audio_slot,S_current_bgm;
    reg [6:0] S_current_audio_length;
    reg [511:0] S_current_audio_path;
    reg [31:0] S_alert_audio_index;
    integer S_copy_byte,S_path_copy;
    wire S_alert_audio_loading=S_state==ALERT_AUDIO_START || S_state==ALERT_AUDIO_PATH;
    wire S_alert_phase=S_state>=ALERT_PREP || S_alert_reloading;
    assign O_alert_restoring=S_alert_reloading;
    wire S_restore=S_state==RESTORE_OFFER || S_state==RESTORE_WAIT;
    wire [2:0] S_alert_slot=S_restore ? S_alert_saved_slot : 3'd5;
    wire [31:0] S_alert_token=S_restore ? S_alert_saved_token : I_resident_token;
    wire [31:0] S_alert_generation=S_restore ? S_alert_saved_generation : 32'd0;
    wire S_alert_resident=S_restore ? S_alert_saved_resident : 1'b1;
    assign O_alert_hold=I_alert || S_alert_pending || S_alert_phase;
    reg [1:0] S_path_state;
    reg [6:0] S_path_address,S_file_length,S_audio_length;
    reg [5:0] S_index,S_pending_index;
    reg S_pending,S_cancel,S_failed,S_stage,S_active_source,S_audio_active_b;
    reg S_new_audio,S_audio_started,S_audio_slot,S_audio_first;
    reg S_item_bgm,S_bgm_active,S_reuse_bgm,S_loop;
    reg [6:0] S_bgm_length,S_bgm_address;
    reg [31:0] S_bgm_generation;
    reg [7:0] S_bgm_path[0:63];
    reg [7:0] S_bgm_byte,S_audio_byte;
    reg [7:0] S_audio_path[0:63];
    reg S_bgm_match,S_image_live;
    reg [3:0] S_parts;
    reg [5:0] S_part_fetch_index,S_page_base,S_applied_page;
    reg [6:0] S_item_count,S_applied_count;
    reg [2:0] S_applied_layout;
    reg [1:0] S_applied_rotation;
    reg [3:0] S_applied_brightness,S_applied_contrast;
    reg [4:0] S_applied_saturation;
    reg S_applied_bilinear,S_pending_absolute;
    // Staged labels belong to this complete image transaction, never the next fetch.
    reg [2879:0] S_titles;
    reg [53:0] S_title_lengths;
    reg [6:0] S_title_address,S_title_read_length,S_title_component;
    reg [5:0] S_title_length;
    reg [3:0] S_title_slot;
    reg [5:0] S_title_after;
    reg S_title_file;
    reg [23:0] S_title_suffix;
    wire S_title_copy=S_state==TITLE_ADDRESS || S_state==TITLE_WAIT || S_state==TITLE_COPY;
    reg [31:0] S_atlas_revision;
    reg [5:0] S_view_index;
    wire [5:0] S_navigation_event=I_goto_valid ? I_goto_index : (I_next ? S_next_index : S_prev_index);
    wire [5:0] S_queued_index=S_user_event ? S_navigation_event : S_pending_index;
    wire S_queued_absolute=S_user_event ? (I_goto_valid || (S_pending && S_pending_absolute)) : S_pending_absolute;
    wire [8:0] S_remap_sum={3'd0,I_order_index}+{3'd0,S_queued_index}+
        {2'd0,O_count}-{3'd0,O_current_index};
    wire [5:0] S_remapped_pending=S_queued_absolute || O_count==0 ? S_queued_index : S_remap_sum%O_count;
    wire S_part_fetch=S_state==PART_FETCH_OFFER || S_state==PART_FETCH_WAIT;
    wire [6:0] S_part_sum={1'b0,S_index}+{3'd0,I_image_part_index};
    wire S_focus_only=O_active_valid && S_applied_layout==4 && I_layout==4 &&
        S_applied_rotation==I_rotation && S_applied_bilinear==I_bilinear &&
        O_generation==I_media_generation && S_atlas_revision==I_index_revision &&
        {1'b0,S_pending_index}<S_applied_count && S_pending_index/6'd9==S_applied_page/6'd9;
    assign O_view={O_active_valid && !O_alert_hold,S_applied_layout,S_applied_page,S_view_index,S_applied_count};
    reg [31:0] S_sequence,S_generation,S_revision,S_seen_generation;
    reg [9:0] S_duration;
    reg [9:0] S_default_duration,S_default_ms;
    reg [2:0] S_default_effect,S_default_override;
    reg [31:0] S_random;
    reg [15:0] S_frames;
    reg [2:0] S_effect,S_layout,S_stage_slot;
    reg [1:0] S_rotation;
    reg S_bilinear;
    reg [3:0] S_brightness,S_contrast;
    reg [4:0] S_saturation;
    reg signed [6:0] S_offset;
    reg [31:0] S_stage_token,S_stage_generation;
    reg [5:0] S_slots;
    reg [63:0] S_tokens,S_generations;
    reg [1:0] S_recycle_required,S_recycle_offer,S_recycle_completed;
    wire S_media_ok=I_enable && I_session_ready && I_media_valid && !I_session_abort;
    wire [9:0] S_selected_duration=I_item_policy[0] || (I_item_policy[3] && !S_default_override[0]) ?
        I_item_duration : S_default_duration;
    wire [2:0] S_selected_effect=I_item_policy[1] || (I_item_policy[4] && !S_default_override[1]) ?
        I_item_transition : S_default_effect;
    wire [9:0] S_selected_ms=I_item_policy[2] || (I_item_policy[5] && !S_default_override[2]) ?
        I_item_transition_ms : S_default_ms;
    function [31:0] random_next;
        input [31:0] value;
        reg [31:0] next_value;
        begin
            next_value=value^(value<<13); next_value=next_value^(next_value>>17);
            random_next=next_value^(next_value<<5);
        end
    endfunction
    wire S_work=S_state!=MEDIA && S_state!=DWELL && S_state!=FAULT && S_state!=ALERT_HOLD && S_state!=ALERT_PREP;
    wire S_progress=I_image_progress || S_state!=S_watch_state || I_image_pixels!=S_watch_pixels ||
        I_image_retired_writes!=S_watch_writes ||
        (O_image_path_valid && I_image_path_ready) ||
        (|(O_audio_file_path_valid & I_audio_file_path_ready)) ||
        (|(O_audio_recycle_valid & I_audio_recycle_ready)) || (|S_recycle_done) ||
        (I_item_done_valid && O_item_done_ready) ||
        (I_image_done_valid && O_image_done_ready) ||
        (I_command_done_valid && O_command_done_ready);
    wire S_watch_timeout=S_work && !I_pause && !S_progress && WATCHDOG_CYCLES!=0 &&
        S_watch_cycles>=WATCHDOG_CYCLES-30'd1;
    wire S_cancel_now=S_cancel || (!S_alert_phase && (I_alert || S_alert_pending)) || !I_enable || I_session_abort || !I_media_valid ||
        (S_work && I_media_generation!=S_generation);
    wire S_user_event=I_next || I_prev || I_goto_valid;
    wire S_loop_preempt=S_pending || S_user_event || (!I_pause && I_auto && S_applied_layout!=4 && I_dwell_expired);
    wire [5:0] S_navigation_base=S_pending ? S_pending_index : (S_work ? S_index : O_current_index);
    wire [5:0] S_next_index=O_count==0 || {1'b0,S_navigation_base}+7'd1>=O_count ? 6'd0 : S_navigation_base+6'd1;
    wire [5:0] S_prev_index=S_navigation_base==0 ? (O_count==0 ? 6'd0 : O_count[5:0]-6'd1) : S_navigation_base-6'd1;
    wire [1:0] S_audio_mask=S_audio_slot ? 2'b10 : 2'b01;
    wire [1:0] S_recycle_accept=O_audio_recycle_valid & I_audio_recycle_ready;
    wire [1:0] S_recycle_done=I_audio_recycle_done & ~S_recycle_offer & S_recycle_required;
    wire S_result_match=I_command_result[127:96]==S_sequence && I_command_result[95:80]==S_sequence[15:0];
    wire [3:0] S_result_error=I_command_result[79:76];
    wire S_result_settled=I_command_result[75];
    wire S_result_source=I_command_result[74];
    wire S_result_unsafe=I_command_result[73] || I_command_result[72] || I_command_result[70] ||
        (!I_command_result[75] && !I_command_result[71]);
    wire [5:0] S_command_slots=!O_active_valid ? {S_stage_slot,S_stage_slot} :
        (S_active_source ? {S_slots[5:3],S_stage_slot} : {S_stage_slot,S_slots[2:0]});
    wire [63:0] S_command_tokens=!O_active_valid ? {S_stage_token,S_stage_token} :
        (S_active_source ? {S_tokens[63:32],S_stage_token} : {S_stage_token,S_tokens[31:0]});
    wire [63:0] S_command_generations=!O_active_valid ? {S_stage_generation,S_stage_generation} :
        (S_active_source ? {S_generations[63:32],S_stage_generation} : {S_stage_generation,S_generations[31:0]});
    wire [246:0] S_config={2'b11,S_active_source,S_command_slots,S_command_tokens,S_command_generations,
        2'b00,S_effect,S_frames,17'd0,S_brightness,S_contrast,S_saturation,S_layout,S_rotation,
        1'b0,1'b0,18'd0,2'd0,32'd0};
    wire [1:0] S_audio_action=S_new_audio ? (S_audio_first ? 2'd1 : 2'd2) :
        (S_reuse_bgm ? 2'd3 : 2'd0);
    wire S_command_audio_slot=!S_new_audio && !S_reuse_bgm ? 1'b1 : S_audio_slot;
    wire [246:0] S_alert_config={2'b11,1'b0,{S_alert_slot,S_alert_slot},{S_alert_token,S_alert_token},
        {S_alert_generation,S_alert_generation},{2{S_alert_resident}},3'd0,16'd1,17'd0,
        S_restore ? S_applied_brightness : 4'd0,S_restore ? S_applied_contrast : 4'd0,
        S_restore ? S_applied_saturation : 5'd8,S_restore ? S_applied_layout : 3'd0,S_restore ? S_applied_rotation : 2'd0,
        1'b0,1'b0,18'd0,2'd0,32'd0};
    assign O_command=S_alert_phase ? {S_sequence,S_sequence[15:0],S_alert_config,3'd0,16'd1,7'd0,
        (S_restore && S_alert_reloading && S_current_has_audio) ? 2'd2 : 2'd0,1'b0,S_sequence[15:0],32'd0,32'd0} :
        {S_sequence,S_sequence[15:0],S_config,S_effect,S_frames,S_offset,
        S_audio_action,S_command_audio_slot,S_sequence[15:0],32'd0,32'd0};
    // Preparing the next background context is not a foreground image transaction.
    // Once navigation is queued, busy stays asserted through its actual completion.
    assign O_busy=S_work && (!S_loop || S_pending || S_user_event);
    assign O_item_start_valid=!I_reset && (S_state==FETCH_OFFER || S_state==PART_FETCH_OFFER) && !S_cancel_now;
    assign {O_item_index,O_item_tag,O_item_revision}={S_part_fetch ? S_part_fetch_index : S_index,
        S_sequence[15:0],S_part_fetch ? S_revision : 32'd0};
    assign O_item_abort=S_cancel_now;
    assign O_item_done_ready=!I_reset && (S_state==FETCH_WAIT || S_state==PART_FETCH_WAIT);
    wire S_bgm_compare=S_state==BGM_ADDRESS || S_state==BGM_WAIT || S_state==BGM_CHECK;
    assign O_item_string_kind=S_title_copy ? (S_title_file ? 2'd0 : 2'd2) : (S_bgm_compare ? 2'd1 : 2'd0);
    assign O_item_string_address=S_title_copy ? S_title_address : (S_bgm_compare ? S_bgm_address : S_path_address);
    assign O_image_start_valid=!I_reset && S_state==IMAGE_OFFER && !S_cancel_now;
    assign {O_image_tag,O_image_generation,O_image_asset}={S_sequence[15:0],S_generation,S_sequence};
    assign {O_image_layout,O_image_rotation,O_image_bilinear}={S_layout,S_rotation,S_bilinear};
    assign O_image_compose=1'b1;
    assign O_image_parts=S_parts;
    assign O_image_part_valid=!I_reset && S_state==PART_OFFER && !S_cancel_now;
    assign O_image_part_path_length=S_file_length;
    assign O_image_abort=S_cancel_now;
    assign O_image_path_length=S_file_length;
    assign O_image_path_valid=!I_reset && S_state==IMAGE_WAIT && S_path_state==PATH_OFFER;
    assign O_image_path_data=I_item_string_data;
    assign O_image_path_last=S_path_address+7'd1==S_file_length;
    assign O_image_done_ready=!I_reset && S_state==IMAGE_WAIT;
    assign O_image_stage_release_valid=!I_reset && S_state==STAGE && S_stage;
    assign {O_image_stage_slot,O_image_stage_token,O_image_stage_generation}={S_stage_slot,S_stage_token,S_stage_generation};
    // Safe only after the real result or before any transition was submitted.
    // Installed display pins remain independently held by playback_image_pipeline.
    assign O_image_stage_discard=1'b1;
    assign O_audio_file_start_valid={2{!I_reset && ((S_state==AUDIO_OFFER && !S_cancel_now) ||
        (S_state==ALERT_AUDIO_START && !S_failed && I_media_valid && I_media_generation==S_alert_saved_generation))}} & S_audio_mask;
    assign O_audio_file_tag={S_sequence[15:0],S_sequence[15:0]};
    assign O_audio_file_generation=S_alert_reloading ? {S_alert_saved_generation,S_alert_saved_generation} : {S_generation,S_generation};
    assign O_audio_file_start_index=S_alert_reloading ? {S_alert_audio_index,S_alert_audio_index} : 64'd0;
    assign O_audio_file_path_length={S_audio_length,S_audio_length};
    assign O_audio_file_path_valid={2{!I_reset && (S_state==AUDIO_PATH || S_state==ALERT_AUDIO_PATH) && S_path_state==PATH_OFFER}} & S_audio_mask;
    assign O_audio_file_path_data=S_loop ? {S_bgm_byte,S_bgm_byte} : {S_audio_byte,S_audio_byte};
    assign O_audio_file_path_last={2{S_path_address+7'd1==S_audio_length}} & S_audio_mask;
    assign O_audio_file_abort={2{(S_alert_reloading ? (!I_media_valid || I_media_generation!=S_alert_saved_generation || S_failed) : S_cancel_now) && S_audio_started}} & S_audio_mask;
    assign O_audio_file_done_ready={2{!I_reset}};
    assign O_audio_recycle_valid={2{!I_reset && S_state==RECYCLE}} & S_recycle_offer;
    assign O_bgm_start_valid=!I_reset && S_state==LOOP_OFFER && !S_cancel_now && !S_loop_preempt;
    assign O_bgm_slot=S_audio_slot;
    assign O_bgm_track_epoch=S_sequence[15:0];
    assign O_bgm_abort=S_cancel_now || (S_loop && S_loop_preempt);
    assign O_bgm_done_ready=!I_reset && S_state==LOOP_WAIT;
    assign O_command_valid=!I_reset && ((S_state==COMMAND_OFFER && !S_cancel_now) ||
        S_state==ALERT_OFFER || (S_state==RESTORE_OFFER && !S_failed &&
        I_media_valid && I_media_generation==S_alert_saved_generation));
    assign O_dwell_seconds=S_duration;
    assign O_command_abort=(!S_alert_phase && S_cancel_now) ||
        (S_restore && (S_failed || !I_media_valid || I_media_generation!=S_alert_saved_generation));
    assign O_command_done_ready=!I_reset && (S_state==COMMAND_WAIT || S_state==ALERT_WAIT || S_state==RESTORE_WAIT);
    task recycle;
        input [1:0] mask;
        input [5:0] return_state;
        begin
            // available means the recycler can ACCEPT work, not that a loaded
            // track/file is already retired. Always require a real new done.
            S_recycle_required<=mask;
            S_recycle_offer<=mask; S_recycle_completed<=0;
            S_after_recycle<=return_state; S_state<=RECYCLE;
        end
    endtask
    task copy_title;
        input [3:0] slot;
        input [5:0] after_state;
        begin
            S_title_slot<=slot; S_title_after<=after_state;
            S_title_file<=I_item_title_length==0;
            S_title_read_length<=I_item_title_length==0 ? I_item_file_length : {1'b0,I_item_title_length};
            S_title_address<=0; S_title_length<=0; S_title_component<=0; S_title_suffix<=0;
            S_titles[slot*320+:320]<=0; S_title_lengths[slot*6+:6]<=0;
            S_state<=TITLE_ADDRESS;
        end
    endtask
    task begin_item;
        input [5:0] index;
        begin
            if(S_sequence==32'hffffffff) begin O_fault<=1; O_error<=15; S_state<=FAULT; end
            else begin
                S_sequence<=S_sequence+32'd1; S_index<=index; S_generation<=I_media_generation;
                S_layout<=I_layout; S_rotation<=I_rotation; S_bilinear<=I_bilinear;
                S_brightness<=I_brightness; S_contrast<=I_contrast; S_saturation<=I_saturation; S_offset<=I_av_offset_steps;
                S_default_duration<=I_default_duration; S_default_ms<=I_default_transition_ms;
                S_default_effect<=I_default_transition; S_default_override<=I_default_override;
                S_cancel<=0; S_failed<=0; S_stage<=0;
                S_titles<=0; S_title_lengths<=0;
                S_failure_accounted<=0; S_watch_cancel<=0;
                S_audio_started<=0; S_new_audio<=0; O_error<=0; S_state<=FETCH_OFFER;
                S_reuse_bgm<=0; S_item_bgm<=0; S_loop<=0; S_image_live<=0;
            end
        end
    endtask
    // Full byte identity, not a hash. No reset on path RAM; active/length delimit it.
    always @(posedge I_clk) begin
        if(!I_reset && S_state==AUDIO_PATH && S_item_bgm && !S_loop &&
            O_audio_file_path_valid[S_audio_slot] && I_audio_file_path_ready[S_audio_slot])
            S_bgm_path[S_path_address[5:0]]<=S_audio_byte;
        if(!I_reset && S_state==BGM_CHECK) S_audio_path[S_bgm_address[5:0]]<=I_item_string_data;
        if(!I_reset && S_state==ALERT_HOLD && !I_alert && S_sequence!=32'hffffffff &&
            S_alert_saved_valid && I_media_valid && S_alert_saved_generation==I_media_generation && S_current_has_audio)
            for(S_path_copy=0;S_path_copy<64;S_path_copy=S_path_copy+1)
                S_audio_path[S_path_copy]<=S_current_audio_path[S_path_copy*8+:8];
        if(!I_reset && S_state==RESTORE_WAIT && I_command_done_valid && S_result_match &&
            S_result_error==0 && S_result_settled && !S_result_unsafe && S_alert_reloading && S_current_bgm)
            for(S_path_copy=0;S_path_copy<64;S_path_copy=S_path_copy+1)
                S_bgm_path[S_path_copy]<=S_current_audio_path[S_path_copy*8+:8];
        S_audio_byte<=S_audio_path[S_path_address[5:0]];
        if(S_bgm_compare || S_loop) S_bgm_byte<=S_bgm_path[S_loop ? S_path_address[5:0] : S_bgm_address[5:0]];
    end
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=MEDIA; S_after_recycle<=DWELL; S_path_state<=PATH_IDLE; S_path_address<=0;
            S_index<=0; S_pending_index<=0; S_pending<=0; S_cancel<=0; S_failed<=0; S_stage<=0;
            S_active_source<=0; S_audio_active_b<=0;
            S_new_audio<=0; S_audio_started<=0; S_audio_slot<=0; S_audio_first<=1;
            S_item_bgm<=0; S_bgm_active<=0; S_reuse_bgm<=0; S_loop<=0;
            S_bgm_length<=0; S_bgm_address<=0; S_bgm_generation<=0;
            S_bgm_match<=0; S_image_live<=0; S_parts<=1; S_part_fetch_index<=0; S_page_base<=0;
            S_item_count<=0; S_applied_count<=0; S_applied_page<=0; S_applied_layout<=0;
            S_applied_rotation<=0; S_applied_bilinear<=0; S_atlas_revision<=0; S_view_index<=0; S_pending_absolute<=0;
            S_applied_brightness<=0; S_applied_contrast<=0; S_applied_saturation<=8;
            S_sequence<=0; S_generation<=0; S_revision<=0; S_seen_generation<=0;
            S_titles<=0; S_title_lengths<=0; O_titles<=0; O_title_lengths<=0;
            S_title_address<=0; S_title_read_length<=0; S_title_component<=0;
            S_title_length<=0; S_title_slot<=0; S_title_after<=IMAGE_PREP; S_title_file<=0; S_title_suffix<=0;
            S_file_length<=0; S_audio_length<=0; S_duration<=0; S_frames<=1; S_effect<=0;
            S_default_duration<=10; S_default_ms<=400; S_default_effect<=0; S_default_override<=0;
            S_random<=32'h46504741;
            S_layout<=0; S_rotation<=0; S_bilinear<=0; S_brightness<=0; S_contrast<=0; S_saturation<=8; S_offset<=0;
            S_stage_slot<=0; S_stage_token<=0; S_stage_generation<=0; S_slots<=0; S_tokens<=0; S_generations<=0;
            S_recycle_required<=0; S_recycle_offer<=0; S_recycle_completed<=0;
            O_active_valid<=0; O_current_index<=0; O_count<=0; O_generation<=0; O_revision<=0;
            O_fault<=0; O_changed<=0; O_error<=0; O_response_discarded<=0;
            O_all_failed<=0; O_watchdog_expired<=0;
            S_watch_state<=MEDIA; S_watch_cycles<=0; S_watch_pixels<=0; S_watch_writes<=0;
            S_bad_count<=0; S_failure_accounted<=0; S_watch_cancel<=0;
            S_alert_pending<=0; S_alert_saved_valid<=0; O_alert_visible<=0;
            S_alert_reloading<=0; S_current_has_audio<=0; S_current_audio_slot<=0; S_current_audio_length<=0;
            S_current_audio_path<=0; S_current_bgm<=0; S_alert_audio_index<=0;
            S_alert_saved_slot<=0; S_alert_saved_token<=0; S_alert_saved_generation<=0; S_alert_saved_resident<=0;
        end else begin
            O_changed<=0; O_response_discarded<=0;
            if(I_alert && !S_alert_phase) S_alert_pending<=1;
            if(!I_media_valid || I_session_abort) S_bgm_active<=0;
            if(S_user_event && !O_alert_hold) begin
                S_pending<=1; S_pending_index<=S_navigation_event;
                S_pending_absolute<=I_goto_valid || (S_pending && S_pending_absolute);
                S_bad_count<=0; O_all_failed<=0;
            end
            if(S_work && S_cancel_now) S_cancel<=1;
            if(S_audio_started && I_audio_file_done_valid[S_audio_slot] &&
                I_audio_file_tag[S_audio_slot*16+:16]==S_sequence[15:0] &&
                I_audio_file_error[S_audio_slot*4+:4]!=0) begin
                S_cancel<=1; S_failed<=1; O_error<=6;
            end
            if(S_path_state==PATH_READ) S_path_state<=PATH_OFFER;
            if((O_image_path_valid && I_image_path_ready) ||
                (O_audio_file_path_valid[S_audio_slot] && I_audio_file_path_ready[S_audio_slot])) begin
                if(S_state==IMAGE_WAIT ? O_image_path_last : O_audio_file_path_last[S_audio_slot]) S_path_state<=PATH_IDLE;
                else begin S_path_address<=S_path_address+7'd1; S_path_state<=PATH_READ; end
            end
            case(S_state)
                MEDIA:if(I_alert || S_alert_pending) S_state<=ALERT_PREP;
                    else if(S_media_ok && !I_order_hold && !I_pause && !S_user_event) begin
                    S_seen_generation<=I_media_generation;
                    S_bad_count<=0; O_all_failed<=0;
                    if(S_pending) begin S_pending<=0; begin_item(S_pending_index); end
                    else begin_item(0);
                end
                FETCH_OFFER:if(S_cancel_now) begin S_failed<=1; S_state<=DWELL; end
                    else if(I_item_start_ready) S_state<=FETCH_WAIT;
                FETCH_WAIT:if(I_item_done_valid) begin
                    O_count<=I_item_count;
                    if(S_cancel_now || I_item_error!=0 || I_item_generation!=S_generation) begin
                        S_failed<=1; O_error<=I_item_error!=0 ? I_item_error : 4'd3; S_state<=DWELL;
                    end else begin
                        S_revision<=I_item_revision; S_file_length<=I_item_file_length; S_audio_length<=I_item_audio_length;
                        S_item_count<=I_item_count; S_page_base<=(S_index/6'd9)*6'd9;
                        case(S_layout)
                            1,2:S_parts<=2;
                            3:S_parts<=4;
                            4:S_parts<=I_item_count-({1'b0,S_index}/7'd9)*7'd9>=9 ?
                                4'd9 : I_item_count-({1'b0,S_index}/7'd9)*7'd9;
                            default:S_parts<=1;
                        endcase
                        S_new_audio<=I_item_audio_length!=0; S_duration<=S_selected_duration;
                        S_item_bgm<=I_item_policy[6];
                        S_effect<=S_selected_effect==7 ? S_random%32'd7 : S_selected_effect;
                        S_random<=random_next(S_random);
                        case(S_selected_ms)
                            200:S_frames<=12; 400:S_frames<=24; 600:S_frames<=36; default:S_frames<=60;
                        endcase
                        S_bgm_match<=I_item_policy[6] && S_bgm_active && S_bgm_generation==S_generation &&
                            S_bgm_length==I_item_audio_length && !S_audio_first;
                        // Copy selected audio BEFORE another item fetch replaces the shared strings.
                        if(I_item_audio_length!=0) begin S_bgm_address<=0; S_state<=BGM_ADDRESS; end
                        else S_state<=IMAGE_PREP;
                        copy_title(S_layout==4 ? S_index%6'd9 : 4'd0,
                            I_item_audio_length!=0 ? BGM_ADDRESS : IMAGE_PREP);
                    end
                end
                // Synchronous item string RAM: set address, wait, then consume.
                TITLE_ADDRESS:if(S_cancel_now) begin
                        S_failed<=1;
                        S_state<=S_image_live ? IMAGE_WAIT : DWELL;
                    end else if(S_title_read_length==0) S_state<=S_title_after;
                    else S_state<=TITLE_WAIT;
                TITLE_WAIT:S_state<=TITLE_COPY;
                TITLE_COPY:if(S_cancel_now) begin
                        S_failed<=1; S_state<=S_image_live ? IMAGE_WAIT : DWELL;
                    end else begin
                        S_title_suffix<={S_title_suffix[15:0],I_item_string_data};
                        if(S_title_file && I_item_string_data==8'h2f) begin
                            S_title_length<=0; S_title_component<=0;
                            S_titles[S_title_slot*320+:320]<=0;
                            S_title_lengths[S_title_slot*6+:6]<=0;
                        end else begin
                            S_title_component<=S_title_component+1'b1;
                            if(S_title_length<40) begin
                                S_titles[S_title_slot*320+(39-S_title_length)*8+:8]<=I_item_string_data;
                                S_title_length<=S_title_length+1'b1;
                                S_title_lengths[S_title_slot*6+:6]<=S_title_length+1'b1;
                            end
                            // Strip extension only if the complete basename fits in this label.
                            if(S_title_file && S_title_address+7'd1==S_title_read_length &&
                                S_title_component>=3 && S_title_component<40 &&
                                S_title_suffix[23:16]==8'h2e &&
                                (S_title_suffix[15:8] | 8'h20)==8'h62 &&
                                (S_title_suffix[7:0] | 8'h20)==8'h6d &&
                                (I_item_string_data | 8'h20)==8'h70)
                                S_title_lengths[S_title_slot*6+:6]<=S_title_length-6'd3;
                        end
                        if(S_title_address+7'd1==S_title_read_length) S_state<=S_title_after;
                        else begin S_title_address<=S_title_address+1'b1; S_state<=TITLE_ADDRESS; end
                    end
                BGM_ADDRESS:if(S_cancel_now) begin S_failed<=1; S_state<=DWELL; end else S_state<=BGM_WAIT;
                BGM_WAIT:S_state<=BGM_CHECK;
                BGM_CHECK:if(S_cancel_now) begin S_failed<=1; S_state<=DWELL; end
                    else begin
                        if(S_bgm_byte!=I_item_string_data) S_bgm_match<=0;
                        if(S_bgm_address+7'd1==S_audio_length) begin
                            if(S_bgm_match && S_bgm_byte==I_item_string_data) begin S_new_audio<=0; S_reuse_bgm<=1; end
                            S_state<=IMAGE_PREP;
                        end else begin S_bgm_address<=S_bgm_address+1'b1; S_state<=BGM_ADDRESS; end
                    end
                IMAGE_PREP:if(S_cancel_now) begin S_failed<=1; S_state<=DWELL; end
                    else if(S_layout==4 && S_page_base!=S_index) begin
                        S_part_fetch_index<=S_page_base; S_state<=PART_FETCH_OFFER;
                    end else S_state<=IMAGE_OFFER;
                PART_FETCH_OFFER:if(S_cancel_now || (S_image_live && I_image_done_valid)) begin
                        if(S_image_live) S_state<=IMAGE_WAIT;
                        else begin S_failed<=1; S_state<=DWELL; end
                    end else if(I_item_start_ready) S_state<=PART_FETCH_WAIT;
                PART_FETCH_WAIT:if(I_item_done_valid) begin
                    if(S_cancel_now || I_item_error!=0 || I_item_generation!=S_generation ||
                        I_item_revision!=S_revision || I_item_count!=S_item_count ||
                        I_item_file_length==0 || I_item_file_length>64) begin
                        S_failed<=1; O_error<=I_item_error!=0 ? I_item_error : 4'd3;
                        if(S_image_live) begin S_cancel<=1; S_state<=IMAGE_WAIT; end else S_state<=DWELL;
                    end else begin
                        S_file_length<=I_item_file_length;
                        if(S_layout==4) copy_title(S_part_fetch_index-S_page_base,
                            S_image_live ? PART_OFFER : IMAGE_OFFER);
                        else S_state<=S_image_live ? PART_OFFER : IMAGE_OFFER;
                    end
                end
                PART_OFFER:if(S_cancel_now || I_image_done_valid) S_state<=IMAGE_WAIT;
                    else if(I_image_part_ready) begin S_path_address<=0; S_path_state<=PATH_READ; S_state<=IMAGE_WAIT; end
                IMAGE_OFFER:if(S_cancel_now) begin S_failed<=1; S_state<=DWELL; end
                    else if(I_image_start_ready) begin S_image_live<=1; S_path_address<=0; S_path_state<=PATH_READ; S_state<=IMAGE_WAIT; end
                IMAGE_WAIT:if(I_image_done_valid) begin
                    if(I_image_tag!=S_sequence[15:0] || I_image_generation!=S_generation) O_response_discarded<=1;
                    else begin
                        S_image_live<=0; S_path_state<=PATH_IDLE; S_stage<=I_image_stage_valid;
                        S_stage_slot<=I_image_slot; S_stage_token<=I_image_token; S_stage_generation<=I_image_generation;
                        if(I_image_quarantined || (I_image_stage_valid && I_image_token==0)) begin O_fault<=1; O_error<=8; S_state<=FAULT; end
                        else if(S_cancel_now || I_image_error!=0 || !I_image_stage_valid) begin
                            O_error<=I_image_error!=0 ? I_image_error : 4'd3; S_failed<=1; S_state<=STAGE;
                        end else if(S_new_audio) begin
                            S_audio_slot<=S_audio_first ? 1'b0 : !S_audio_active_b;
                            recycle(S_audio_first || S_audio_active_b ? 2'b01 : 2'b10,AUDIO_OFFER);
                        end else S_state<=COMMAND_OFFER;
                    end
                end
                    else if(I_image_part_needed && !S_cancel_now) begin
                        S_part_fetch_index<=S_layout==4 ? S_page_base+I_image_part_index :
                            (S_item_count==0 ? 6'd0 : S_part_sum%S_item_count);
                        S_path_state<=PATH_IDLE; S_state<=PART_FETCH_OFFER;
                    end
                RECYCLE:begin
                    S_recycle_offer<=S_recycle_offer & ~S_recycle_accept;
                    S_recycle_completed<=S_recycle_completed | S_recycle_done;
                    if((S_recycle_offer & ~S_recycle_accept)==0 &&
                        ((S_recycle_completed | S_recycle_done) & S_recycle_required)==S_recycle_required &&
                        (I_audio_available & S_recycle_required)==S_recycle_required) S_state<=S_after_recycle;
                end
                AUDIO_OFFER:if(S_cancel_now) begin S_failed<=1; S_state<=STAGE; end
                    else if(I_audio_file_start_ready[S_audio_slot]) begin
                        // Subsequent writes reuse this RAM. Do not retain old identity
                        // through an unsuccessful replacement of the running BGM.
                        if(!S_loop) S_bgm_active<=0;
                        S_audio_started<=1; S_path_address<=0; S_path_state<=PATH_READ; S_state<=AUDIO_PATH;
                    end
                AUDIO_PATH:if(S_cancel_now) begin
                        S_failed<=1; S_path_state<=PATH_IDLE;
                        if(S_loop) begin S_bgm_active<=0; recycle(S_audio_mask,DWELL); end else S_state<=STAGE;
                    end
                    else if(O_audio_file_path_valid[S_audio_slot] && I_audio_file_path_ready[S_audio_slot] &&
                        O_audio_file_path_last[S_audio_slot]) begin
                        S_path_state<=PATH_IDLE; S_state<=S_loop ? LOOP_OFFER : COMMAND_OFFER;
                    end
                LOOP_OFFER:if(S_cancel_now || S_loop_preempt) begin
                        if(S_cancel_now) S_bgm_active<=0;
                        recycle(S_audio_mask,DWELL);
                    end else if(I_bgm_start_ready) S_state<=LOOP_WAIT;
                LOOP_WAIT:if(I_bgm_done_valid) begin
                    S_audio_active_b<=I_bgm_result[2]; S_audio_first<=I_bgm_result[1:0]==0;
                    if(I_bgm_result[7:4]==0 && S_current_bgm) S_current_audio_slot<=I_bgm_result[2];
                    if(I_bgm_result[7:4]==0) recycle(~S_audio_mask,DWELL);
                    else begin
                        if(!I_bgm_result[3] || S_cancel_now || !S_loop_preempt) S_bgm_active<=0;
                        recycle(S_audio_mask,DWELL);
                    end
                end
                COMMAND_OFFER:if(S_cancel_now) begin S_failed<=1; S_state<=STAGE; end
                    else if(I_command_ready) S_state<=COMMAND_WAIT;
                COMMAND_WAIT:if(I_command_done_valid) begin
                    if(!S_result_match) O_response_discarded<=1;
                    else if(S_result_unsafe) begin O_fault<=1; O_error<=8; S_state<=FAULT; end
                    else begin
                        O_error<=S_result_error; S_failed<=S_result_error!=0;
                        S_audio_active_b<=I_command_result[37];
                        S_audio_first<=I_command_result[34:33]==0;
                        if(S_result_error==0 && S_result_settled && S_audio_started) begin
                            S_bgm_active<=S_item_bgm && I_command_result[33+S_audio_slot];
                            S_bgm_length<=S_audio_length; S_bgm_generation<=S_generation;
                        end else if(!S_reuse_bgm || I_command_result[34:33]==0) S_bgm_active<=0;
                        if(S_result_settled) begin
                            S_active_source<=S_result_source; S_slots<=S_command_slots;
                            S_tokens<=S_command_tokens; S_generations<=S_command_generations;
                            O_active_valid<=1;
                            if(!O_active_valid || S_result_source!=S_active_source) begin
                                O_current_index<=S_index; O_generation<=S_generation; O_revision<=S_revision; O_changed<=1;
                                S_applied_layout<=S_layout; S_applied_page<=S_page_base; S_applied_count<=S_item_count;
                                S_applied_rotation<=S_rotation; S_applied_bilinear<=S_bilinear;
                                S_applied_brightness<=S_brightness; S_applied_contrast<=S_contrast; S_applied_saturation<=S_saturation;
                                S_atlas_revision<=S_revision; S_view_index<=S_index;
                                if(S_new_audio) begin
                                    S_current_has_audio<=1; S_current_audio_slot<=S_audio_slot;
                                    S_current_audio_length<=S_audio_length; S_current_bgm<=S_item_bgm;
                                    for(S_copy_byte=0;S_copy_byte<64;S_copy_byte=S_copy_byte+1)
                                        S_current_audio_path[S_copy_byte*8+:8]<=S_audio_path[S_copy_byte];
                                end else if(!S_reuse_bgm) begin S_current_has_audio<=0; S_current_audio_length<=0; end
                                O_titles<=S_titles; O_title_lengths<=S_title_lengths;
                                S_bad_count<=0; O_all_failed<=0;
                            end
                        end
                        S_state<=STAGE;
                    end
                end
                STAGE:if(!S_stage || I_image_stage_release_ready) begin
                    S_stage<=0;
                    if(S_alert_pending && !S_audio_started) S_state<=DWELL;
                    else if(!S_new_audio && !S_reuse_bgm && !S_failed && !S_cancel_now) recycle(2'b11,DWELL);
                    else if(S_audio_started) recycle(S_failed || S_cancel_now ? S_audio_mask : ~S_audio_mask,DWELL);
                    else S_state<=DWELL;
                end
                DWELL:begin
                    S_loop<=0; S_audio_started<=0;
                    if(I_alert || S_alert_pending) S_state<=ALERT_PREP;
                    else if(!S_media_ok) S_state<=MEDIA;
                    else if(!I_order_hold && I_media_generation!=S_seen_generation) begin
                        S_seen_generation<=I_media_generation; S_bad_count<=0; O_all_failed<=0; begin_item(0);
                    end
                    else if(!I_order_hold && !I_pause && !S_user_event && S_pending) begin
                        S_pending<=0;
                        if(S_focus_only) begin
                            O_current_index<=S_pending_index; S_index<=S_pending_index; S_view_index<=S_pending_index; O_changed<=1;
                            O_error<=0; S_failed<=0; S_state<=THUMB_FOCUS;
                        end else begin_item(S_pending_index);
                    end
                    // All accepted owners have really completed before DWELL is reached.
                    // Bound automatic skipping to one pass, even with AUTO disabled.
                    else if(!I_order_hold && !I_pause && !S_user_event && S_failed &&
                        !S_failure_accounted && !O_all_failed) begin
                        S_failure_accounted<=1;
                        if(O_count==0 || S_bad_count+7'd1>=O_count) begin
                            S_bad_count<=O_count; O_all_failed<=1; O_error<=10;
                        end else begin
                            S_bad_count<=S_bad_count+1'b1;
                            begin_item({1'b0,S_index}+7'd1>=O_count ? 6'd0 : S_index+6'd1);
                        end
                    end
                    else if(!I_order_hold && !I_pause && !S_user_event && I_auto && S_applied_layout!=4 && I_dwell_expired && !S_failed)
                        begin_item(O_count==0 || {1'b0,O_current_index}+7'd1>=O_count ? 6'd0 : O_current_index+6'd1);
                    else if(!I_pause && !S_user_event && !S_pending && S_bgm_active && I_bgm_need && !S_failed) begin
                        if(S_sequence==32'hffffffff) begin O_fault<=1; O_error<=15; S_state<=FAULT; end
                        else begin
                            S_loop<=1; S_audio_started<=0; S_sequence<=S_sequence+1'b1;
                            S_audio_slot<=!S_audio_active_b; S_audio_length<=S_bgm_length;
                            S_cancel<=0; S_item_bgm<=1;
                            recycle(S_audio_active_b ? 2'b01 : 2'b10,AUDIO_OFFER);
                        end
                    end
                end
                // A real application completion interval also lets UART retire same-page navigation.
                THUMB_FOCUS:S_state<=DWELL;
                ALERT_PREP:if(!I_alert) begin S_alert_pending<=0; S_cancel<=0; S_failed<=0; S_state<=DWELL; end
                    else if(I_resident_ready && S_sequence==32'hffffffff) begin
                        O_fault<=1; O_error<=15; S_alert_pending<=0; S_state<=FAULT;
                    end else if(I_resident_ready) begin
                        S_alert_saved_valid<=O_active_valid && I_media_valid && O_generation==I_media_generation;
                        S_alert_saved_slot<=S_active_source ? S_slots[5:3] : S_slots[2:0];
                        S_alert_saved_token<=S_active_source ? S_tokens[63:32] : S_tokens[31:0];
                        S_alert_saved_generation<=S_active_source ? S_generations[63:32] : S_generations[31:0];
                        S_alert_saved_resident<=0;
                        S_sequence<=S_sequence+1'b1; S_cancel<=0; S_failed<=0; S_state<=ALERT_OFFER;
                    end
                ALERT_OFFER:if(I_command_ready) S_state<=ALERT_WAIT;
                ALERT_WAIT:if(I_command_done_valid) begin
                    if(!S_result_match) O_response_discarded<=1;
                    else if(S_result_error!=0 || !S_result_settled || S_result_unsafe) begin
                        O_error<=S_result_error!=0 ? S_result_error : 4'd8; O_fault<=1; S_state<=FAULT;
                    end else begin
                        O_alert_visible<=1;
                        S_alert_audio_index<=I_audio_bookmark[S_current_audio_slot*32+:32];
                        S_state<=ALERT_HOLD;
                    end
                end
                ALERT_HOLD:if(!I_alert) begin
                    if(S_sequence==32'hffffffff) begin O_fault<=1; O_error<=15; S_state<=FAULT; end
                    else if(S_alert_saved_valid && I_media_valid && S_alert_saved_generation==I_media_generation) begin
                        S_sequence<=S_sequence+1'b1;
                        S_alert_reloading<=S_current_has_audio; S_failed<=0; S_audio_started<=0;
                        if(S_current_has_audio) begin
                            S_audio_slot<=0; S_audio_length<=S_current_audio_length; S_loop<=0;
                            recycle(2'b11,ALERT_AUDIO_START);
                        end else S_state<=RESTORE_OFFER;
                    end else begin
                        O_alert_visible<=0; O_active_valid<=0; S_alert_pending<=0;
                        S_cancel<=0; S_failed<=0; S_pending<=0; S_state<=MEDIA;
                    end
                end
                ALERT_AUDIO_START:if(S_failed || !I_media_valid || I_media_generation!=S_alert_saved_generation) begin
                        S_current_has_audio<=0; recycle(2'b11,ALERT_ABANDON);
                    end else if(I_audio_file_start_ready[0]) begin
                        S_audio_started<=1; S_path_address<=0; S_path_state<=PATH_READ; S_state<=ALERT_AUDIO_PATH;
                    end
                ALERT_AUDIO_PATH:if(S_failed || !I_media_valid || I_media_generation!=S_alert_saved_generation) begin
                        S_path_state<=PATH_IDLE; S_current_has_audio<=0; recycle(2'b11,ALERT_ABANDON);
                    end else if(O_audio_file_path_valid[0] && I_audio_file_path_ready[0] && O_audio_file_path_last[0]) begin
                        S_path_state<=PATH_IDLE; S_state<=RESTORE_OFFER;
                    end
                ALERT_ABANDON:begin
                    S_alert_reloading<=0; S_audio_started<=0; S_cancel<=0; S_failed<=0;
                    if(S_sequence==32'hffffffff) begin O_fault<=1; O_error<=15; S_state<=FAULT; end
                    else if(I_media_valid && S_alert_saved_generation==I_media_generation) begin
                        S_sequence<=S_sequence+1'b1; S_state<=RESTORE_OFFER;
                    end
                    else begin O_alert_visible<=0; O_active_valid<=0; S_alert_pending<=0; S_state<=MEDIA; end
                end
                RESTORE_OFFER:if(S_failed || !I_media_valid || I_media_generation!=S_alert_saved_generation) begin
                        S_current_has_audio<=0; recycle(2'b11,ALERT_ABANDON);
                    end else if(I_command_ready) S_state<=RESTORE_WAIT;
                RESTORE_WAIT:if(I_command_done_valid) begin
                    if(!S_result_match) O_response_discarded<=1;
                    else if(!S_result_unsafe && S_failed && I_media_valid && S_alert_saved_generation==I_media_generation) begin
                        S_current_has_audio<=0; recycle(2'b11,ALERT_ABANDON);
                    end
                    else if(!S_result_unsafe && (!I_media_valid || S_alert_saved_generation!=I_media_generation)) begin
                        O_alert_visible<=0; O_active_valid<=0; S_alert_pending<=I_alert;
                        S_alert_reloading<=0;
                        S_cancel<=0; S_failed<=0; S_pending<=0; S_state<=I_alert ? ALERT_PREP : MEDIA;
                    end else if(S_result_error!=0 || !S_result_settled || S_result_unsafe) begin
                        O_error<=S_result_error!=0 ? S_result_error : 4'd8; O_fault<=1; S_state<=FAULT;
                    end else begin
                        S_active_source<=S_result_source; S_slots<={S_alert_saved_slot,S_alert_saved_slot};
                        S_tokens<={S_alert_saved_token,S_alert_saved_token};
                        S_generations<={S_alert_saved_generation,S_alert_saved_generation};
                        O_alert_visible<=0; S_alert_pending<=I_alert; S_cancel<=0; S_failed<=0;
                        S_alert_reloading<=0; S_audio_started<=0;
                        if(S_alert_reloading && S_current_has_audio) begin
                            S_current_audio_slot<=0; S_audio_active_b<=0; S_audio_first<=0;
                            S_bgm_active<=S_current_bgm; S_bgm_length<=S_current_audio_length; S_bgm_generation<=S_alert_saved_generation;
                        end
                        S_state<=I_alert ? ALERT_PREP : DWELL;
                    end
                end
                FAULT:begin O_fault<=1; end
                default:begin O_fault<=1; O_error<=8; S_state<=FAULT; end
            endcase
            // Sorting preserves the current physical item; only its logical position changes.
            // The controller holds new image work through this complete APPLY interval.
            if(I_order_applied && I_media_valid && I_order_generation==I_media_generation) begin
                if(O_active_valid && O_generation==I_order_generation) begin
                    O_current_index<=I_order_index; S_index<=I_order_index;
                    O_revision<=I_order_revision; S_revision<=I_order_revision; O_changed<=1;
                    if(S_pending || S_user_event) begin S_pending<=1; S_pending_index<=S_remapped_pending; end
                    else if(S_applied_layout!=0) begin
                        S_pending<=1; S_pending_index<=I_order_index; S_pending_absolute<=1;
                    end
                end
            end
            // Timeout requests cancellation but never changes the ownership state.
            // A second full interval without retirement reports a protected fault;
            // the existing state machine continues to consume genuine results.
            S_watch_state<=S_state; S_watch_pixels<=I_image_pixels; S_watch_writes<=I_image_retired_writes;
            if(!S_work || I_pause || S_progress || S_watch_timeout) S_watch_cycles<=0;
            else if(WATCHDOG_CYCLES!=0) S_watch_cycles<=S_watch_cycles+1'b1;
            if(S_watch_timeout && !S_alert_phase) begin
                S_cancel<=1; S_failed<=1; O_watchdog_expired<=1; O_error<=9;
                if(S_watch_cancel) O_fault<=1;
                S_watch_cancel<=1;
            end
        end
    end
endmodule
