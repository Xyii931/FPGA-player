// One complete two-image transition, then an actual single-source commit/release.
// All ports belong to the SAME physical video/audio clock. Proofs require real owners.
module playback_transition_owner #(
    parameter integer STOP_PENDING_AUDIO=0
) (
    input wire I_clk,I_reset,I_clock_enable,
    input wire [31:0] I_time,
    input wire I_frame_start,I_sample_tick,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    input wire [246:0] I_config,
    input wire [2:0] I_effect,
    input wire [15:0] I_duration_frames,
    input wire signed [6:0] I_av_offset_steps,
    input wire [1:0] I_audio_action,
    input wire I_audio_slot,
    input wire [15:0] I_track_epoch,
    input wire [31:0] I_track_serial,I_start_index,
    input wire [137:0] I_images,I_display_leases,
    input wire I_pause,I_abort,
    output wire O_pause_allow,
    output reg [1:0] O_image_hold,
    output wire [1:0] O_audio_hold,
    output wire [246:0] O_frozen_config,
    output wire O_audio_bind_valid,
    input wire I_audio_bind_ready,
    output wire [31:0] O_audio_bind_epoch,
    output wire [15:0] O_audio_bind_tag,
    output wire O_audio_bind_slot,
    output wire [15:0] O_audio_bind_track_epoch,
    output wire [31:0] O_audio_bind_serial,O_audio_bind_index,
    output wire O_audio_bind_reuse,O_audio_pending,O_audio_unbind,
    input wire I_audio_bound,
    input wire [3:0] I_audio_bind_error,
    input wire I_audio_ready,
    input wire [31:0] I_audio_epoch,
    input wire [1:0] I_track_known,I_track_enabled,I_track_consumed,
    input wire [31:0] I_track_epochs,
    input wire [63:0] I_track_serials,I_track_totals,I_track_next_index,
    output wire O_play_valid,O_fade_valid,O_target_b,
    input wire I_play_ready,I_fade_ready,I_fade_done,I_active_b,
    output wire O_silence_valid,
    input wire I_silence_ready,I_silence_started,I_silence_done,
    output wire O_audio_stop_request,
    input wire I_audio_stop_ack,
    output wire O_event_valid,
    input wire I_event_ready,
    output wire O_event_cancel,
    output wire [31:0] O_event_epoch,
    output wire [15:0] O_event_tag,O_event_index,
    output wire [2:0] O_event_effect,
    output wire [16:0] O_event_progress,
    output wire [31:0] O_event_target,
    output wire [246:0] O_event_config,
    input wire I_event_busy,I_event_done_valid,
    output wire O_event_done_ready,
    input wire [31:0] I_event_done_epoch,
    input wire [15:0] I_event_done_tag,I_event_done_index,
    input wire [3:0] I_event_done_error,
    input wire I_event_done_applied,I_event_done_retired,
    input wire [31:0] I_event_done_time,I_event_commit_epoch,
    input wire I_event_quarantined,
    input wire I_active_valid,
    input wire [246:0] I_active_config,
    input wire [31:0] I_active_epoch,
    input wire [15:0] I_active_tag,
    input wire I_recover_valid,I_recover_source,
    output wire O_recover_ready,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [31:0] O_epoch,
    output reg [15:0] O_tag,
    output reg [3:0] O_error,O_timeline_error,O_settle_error,O_bind_error,
    output reg O_settled,O_recovery_required,O_recovery_result,O_cancel_late,O_selected_source,
    output reg O_video_started,O_video_finished,O_audio_started,O_audio_finished,
    output reg [31:0] O_actual_start,O_actual_midpoint,O_actual_audio,O_dwell_start,O_settle_time,O_commit_epoch,
    output reg signed [31:0] O_anchor_error,
    output reg [16:0] O_last_progress,
    output reg O_quarantined,O_response_discarded
);
    localparam [3:0] IDLE=0,WAIT_IMAGES=1,BIND=2,WAIT_AUDIO=3,START=4,RUN=5,
        UNBIND=6,DECIDE=7,SET_OFFER=8,SET_WAIT=9,PROOF=10,RESULT=11;
    reg [3:0] S_state;
    reg [246:0] S_config,S_single_config;
    reg [2:0] S_effect;
    reg [15:0] S_duration,S_track_epoch;
    reg signed [6:0] S_offset;
    reg [1:0] S_audio_action;
    reg S_slot,S_cancel,S_authorized,S_unbind,S_anchored,S_target_source;
    reg [31:0] S_serial,S_start_index,S_frame_origin,S_settle_target,S_last_epoch;
    wire S_active=S_state!=IDLE && S_state!=RESULT;
    wire [31:0] S_origin=I_frame_start ? I_time : S_frame_origin;
    wire [31:0] S_next_frame=S_origin+32'd420000;
    wire [31:0] S_next_lead=S_next_frame-I_time;
    wire [31:0] S_selected_frame=S_next_lead>=32'd32000 ? S_next_frame : S_next_frame+32'd420000;
    wire [1:0] S_single_mask=2'b01<<S_target_source;
    function image_matches;
        input [137:0] proof;
        input [246:0] cfg;
        input source;
        begin image_matches=proof[136+source] && proof[130+source*3+:3]==cfg[238+source*3+:3] &&
            proof[66+source*32+:32]==cfg[174+source*32+:32] &&
            proof[2+source*32+:32]==cfg[110+source*32+:32] && proof[source]==cfg[108+source]; end
    endfunction
    wire S_images_ok=image_matches(I_images,S_config,0) && image_matches(I_images,S_config,1);
    wire S_selected_ok=image_matches(I_images,S_config,S_target_source);
    wire S_cancel_now=S_cancel || I_abort || !I_clock_enable ||
        (S_authorized && !O_recovery_result && !S_images_ok) || I_event_quarantined || O_quarantined;
    wire S_timeline_phase=S_state==START || S_state==RUN;
    wire S_settle_phase=S_state==SET_OFFER || S_state==SET_WAIT || S_state==PROOF;
    wire S_done_match=I_event_done_epoch==O_epoch && I_event_done_tag==O_tag && I_event_done_index==16'hffff;
    wire [31:0] S_done_delta=I_event_done_time-S_settle_target;
    wire [31:0] S_done_age=I_time-I_event_done_time;
    wire S_done_time_ok=!S_done_delta[31] && S_done_delta%32'd420000==0 && !S_done_age[31];
    wire S_single_active_ok=I_active_valid && I_active_epoch==O_commit_epoch && I_active_tag==O_tag &&
        I_active_config[246:34]==S_single_config[246:34];
    wire S_lease_proof=I_display_leases[137:136]==S_single_mask &&
        image_matches(I_display_leases,S_config,S_target_source);
    wire S_t_O_start_ready;
    wire S_t_O_pause_allow;
    wire S_t_O_video_valid;
    wire S_t_O_video_cancel;
    wire [31:0] S_t_O_video_epoch;
    wire [15:0] S_t_O_video_tag;
    wire [2:0] S_t_O_video_effect;
    wire [15:0] S_t_O_video_frame_index;
    wire [16:0] S_t_O_video_progress;
    wire [31:0] S_t_O_video_target_time;
    wire S_t_O_video_done_ready;
    wire S_t_O_play_valid;
    wire S_t_O_fade_valid;
    wire S_t_O_target_b;
    wire [31:0] S_t_O_audio_target_time;
    wire S_t_O_audio_stop_request;
    wire S_t_O_busy;
    wire S_t_O_done_valid;
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
    assign O_start_ready=!I_reset && S_state==IDLE && !O_recovery_required && !O_quarantined && !I_event_quarantined;
    assign O_recover_ready=!I_reset && S_state==IDLE && O_recovery_required && !O_quarantined &&
        !I_event_quarantined && !I_event_busy && I_clock_enable && S_anchored &&
        image_matches(I_images,S_config,I_recover_source);
    assign O_busy=S_state!=IDLE || O_recovery_required || O_quarantined;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_frozen_config=S_config;
    assign O_audio_hold=I_track_enabled | ((S_active && S_audio_action!=0) ? (2'b01<<S_slot) : 2'b00);
    assign O_pause_allow=(S_state==IDLE || S_state==WAIT_IMAGES || S_state==BIND || S_state==WAIT_AUDIO ||
        S_state==RESULT || (S_timeline_phase && S_t_O_pause_allow));
    assign O_audio_bind_valid=!I_reset && S_state==BIND;
    assign {O_audio_bind_epoch,O_audio_bind_tag,O_audio_bind_slot,O_audio_bind_track_epoch,
        O_audio_bind_serial,O_audio_bind_index}={O_epoch,O_tag,S_slot,S_track_epoch,S_serial,S_start_index};
    assign O_audio_bind_reuse=S_audio_action==3;
    assign O_audio_pending=!I_reset && S_active && S_audio_action!=0 && !O_audio_unbind;
    assign O_audio_unbind=!I_reset && (S_unbind || S_state==UNBIND);
    assign O_play_valid=S_t_O_play_valid;
    assign O_fade_valid=S_t_O_fade_valid;
    assign O_target_b=S_t_O_target_b;
    assign O_audio_stop_request=S_t_O_audio_stop_request;
    assign O_event_valid=!I_reset && (S_state==SET_OFFER || (S_timeline_phase && S_t_O_video_valid));
    assign O_event_cancel=S_timeline_phase && S_t_O_video_cancel;
    assign O_event_epoch=O_epoch;
    assign O_event_tag=O_tag;
    assign O_event_index=S_settle_phase ? 16'hffff : S_t_O_video_frame_index;
    assign O_event_effect=S_settle_phase ? 3'd0 : S_t_O_video_effect;
    assign O_event_progress=S_settle_phase ? 17'd0 : S_t_O_video_progress;
    assign O_event_target=S_settle_phase ? S_settle_target : S_t_O_video_target_time;
    assign O_event_config=S_settle_phase ? S_single_config : S_config;
    assign O_event_done_ready=!I_reset && (S_state==SET_WAIT || (S_timeline_phase && S_t_O_video_done_ready));
    av_event_timeline #(.STOP_PENDING_AUDIO(STOP_PENDING_AUDIO)) u_timeline (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_clock_enable(I_clock_enable),
        .I_time(I_time),
        .I_frame_start(I_frame_start),
        .I_sample_tick(I_sample_tick),
        .I_start_valid(S_state==START),
        .O_start_ready(S_t_O_start_ready),
        .I_epoch(O_epoch),
        .I_tag(O_tag),
        .I_effect(S_effect),
        .I_duration_frames(S_duration),
        .I_av_offset_steps(S_offset),
        .I_audio_action(S_audio_action),
        .I_audio_slot(S_slot),
        .I_track_epoch(S_track_epoch),
        .I_track_serial(S_serial),
        .I_start_index(S_start_index),
        .I_resources_ready(S_images_ok && (S_audio_action==0 || (I_audio_ready && I_audio_epoch==O_epoch))),
        .I_resources_epoch(O_epoch),
        .I_resources_tag(O_tag),
        .I_track_known(I_track_known),
        .I_track_enabled(I_track_enabled),
        .I_track_consumed(I_track_consumed),
        .I_track_epochs(I_track_epochs),
        .I_track_serials(I_track_serials),
        .I_track_totals(I_track_totals),
        .I_track_next_index(I_track_next_index),
        .I_pause(I_pause),
        .I_abort(S_cancel_now),
        .O_pause_allow(S_t_O_pause_allow),
        .O_video_valid(S_t_O_video_valid),
        .I_video_ready(I_event_ready && S_timeline_phase),
        .O_video_cancel(S_t_O_video_cancel),
        .O_video_epoch(S_t_O_video_epoch),
        .O_video_tag(S_t_O_video_tag),
        .O_video_effect(S_t_O_video_effect),
        .O_video_frame_index(S_t_O_video_frame_index),
        .O_video_progress(S_t_O_video_progress),
        .O_video_target_time(S_t_O_video_target_time),
        .I_video_done_valid(I_event_done_valid && S_timeline_phase),
        .O_video_done_ready(S_t_O_video_done_ready),
        .I_video_done_epoch(I_event_done_epoch),
        .I_video_done_tag(I_event_done_tag),
        .I_video_done_frame_index(I_event_done_index),
        .I_video_done_error(I_event_done_error),
        .I_video_done_applied(I_event_done_applied),
        .I_video_done_time(I_event_done_time),
        .O_play_valid(S_t_O_play_valid),
        .I_play_ready(I_play_ready),
        .O_fade_valid(S_t_O_fade_valid),
        .O_silence_valid(O_silence_valid),
        .I_silence_ready(I_silence_ready),
        .I_silence_started(I_silence_started),
        .I_silence_done(I_silence_done),
        .O_target_b(S_t_O_target_b),
        .O_audio_target_time(S_t_O_audio_target_time),
        .I_fade_ready(I_fade_ready),
        .I_fade_done(I_fade_done),
        .I_active_b(I_active_b),
        .O_audio_stop_request(S_t_O_audio_stop_request),
        .I_audio_stop_ack(I_audio_stop_ack),
        .O_busy(S_t_O_busy),
        .O_done_valid(S_t_O_done_valid),
        .I_done_ready(S_state==RUN),
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
        .O_response_discarded(S_t_O_response_discarded)
    );
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_config<=0; S_single_config<=0; S_effect<=0; S_duration<=0; S_offset<=0;
            S_audio_action<=0; S_slot<=0; S_track_epoch<=0; S_serial<=0; S_start_index<=0;
            S_cancel<=0; S_authorized<=0; S_unbind<=0; S_anchored<=0; S_frame_origin<=0;
            S_settle_target<=0; S_target_source<=0; S_last_epoch<=0;
            O_image_hold<=0; O_epoch<=0; O_tag<=0; O_error<=0; O_timeline_error<=0; O_settle_error<=0; O_bind_error<=0;
            O_settled<=0; O_recovery_required<=0; O_recovery_result<=0; O_cancel_late<=0; O_selected_source<=0;
            O_video_started<=0; O_video_finished<=0; O_audio_started<=0; O_audio_finished<=0;
            O_actual_start<=0; O_actual_midpoint<=0; O_actual_audio<=0; O_dwell_start<=0; O_settle_time<=0;
            O_commit_epoch<=0; O_anchor_error<=0; O_last_progress<=0; O_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=S_t_O_response_discarded;
            if(!I_clock_enable) S_anchored<=0;
            else if(I_frame_start) begin S_anchored<=1; S_frame_origin<=I_time; end
            if(S_active && !S_settle_phase && S_cancel_now) begin
                S_cancel<=1;
                if(O_error==0) O_error<=!I_clock_enable ? 4'd5 : I_abort ? 4'd3 : 4'd4;
            end
            if(S_settle_phase && I_abort) O_cancel_late<=1;
            if((S_t_O_play_valid && I_play_ready) || (S_t_O_fade_valid && I_fade_ready)) S_unbind<=1;
            if(S_state==RUN && I_event_done_valid && O_event_done_ready &&
                I_event_done_epoch==O_epoch && I_event_done_tag==O_tag &&
                I_event_done_index==S_t_O_video_frame_index && I_event_done_applied) begin
                O_last_progress<=S_t_O_video_progress; O_commit_epoch<=I_event_commit_epoch;
            end
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    O_epoch<=I_epoch; O_tag<=I_tag; S_config<=I_config; S_config[104:89]<=I_duration_frames; S_config[51:34]<=0;
                    S_effect<=I_effect; S_duration<=I_duration_frames; S_offset<=I_av_offset_steps;
                    S_audio_action<=I_audio_action; S_slot<=I_audio_slot; S_track_epoch<=I_track_epoch;
                    S_serial<=I_track_serial; S_start_index<=I_start_index;
                    S_cancel<=0; S_authorized<=0; S_unbind<=0;
                    O_error<=0; O_timeline_error<=0; O_settle_error<=0; O_bind_error<=0; O_settled<=0;
                    O_recovery_result<=0; O_cancel_late<=0; O_last_progress<=0;
                    O_video_started<=0; O_video_finished<=0; O_audio_started<=0; O_audio_finished<=0;
                    O_actual_start<=0; O_actual_midpoint<=0; O_actual_audio<=0; O_dwell_start<=0;
                    O_settle_time<=0; O_commit_epoch<=0; O_anchor_error<=0;
                    if(I_epoch==0 || I_epoch<=S_last_epoch || I_config[246:245]!=3 || I_config[52] ||
                        I_effect>6 || I_duration_frames==0 || I_duration_frames>60 ||
                        I_av_offset_steps< -7'sd50 || I_av_offset_steps>7'sd50 ||
                        (I_audio_action!=0 && I_track_serial==0) || (I_audio_action==1 && I_audio_slot)) begin
                        O_error<=1; S_state<=RESULT;
                    end else begin S_last_epoch<=I_epoch; O_image_hold<=3; S_state<=WAIT_IMAGES; end
                end else if(I_recover_valid && O_recover_ready) begin
                    S_target_source<=I_recover_source; O_selected_source<=I_recover_source;
                    O_recovery_result<=1; O_error<=0; O_settle_error<=0; O_settled<=0; S_cancel<=0;
                    S_state<=DECIDE;
                end
                WAIT_IMAGES:if(S_cancel_now) S_state<=UNBIND;
                    else if(S_images_ok) S_state<=S_audio_action==0 ? START : BIND;
                BIND:if(I_audio_bind_ready) S_state<=S_cancel_now ? UNBIND : WAIT_AUDIO;
                WAIT_AUDIO:if(S_cancel_now) S_state<=UNBIND;
                    else if(I_audio_bind_error!=0) begin O_bind_error<=I_audio_bind_error; O_error<=4; S_cancel<=1; S_state<=UNBIND; end
                    else if(I_audio_bound && I_audio_ready && I_audio_epoch==O_epoch && S_images_ok) S_state<=START;
                START:if(S_t_O_start_ready) begin S_authorized<=1; S_state<=RUN; end
                RUN:if(S_t_O_done_valid) begin
                    O_timeline_error<=S_t_O_error;
                    if(O_error==0 && !S_cancel_now) O_error<=S_t_O_error;
                    O_video_started<=S_t_O_video_started; O_video_finished<=S_t_O_video_finished;
                    O_audio_started<=S_t_O_audio_started; O_audio_finished<=S_t_O_audio_finished;
                    O_actual_start<=S_t_O_actual_start; O_actual_midpoint<=S_t_O_actual_midpoint;
                    O_actual_audio<=S_t_O_actual_audio; O_dwell_start<=S_t_O_actual_finish;
                    O_anchor_error<=S_t_O_anchor_error; O_cancel_late<=S_t_O_cancel_late;
                    if(S_t_O_quarantined) begin O_quarantined<=1; O_recovery_required<=1; end
                    S_target_source<=S_t_O_error==0 ? !S_config[244] :
                        ((O_last_progress>=32768) ? !S_config[244] : S_config[244]);
                    S_state<=UNBIND;
                end
                UNBIND:if(!I_audio_bound) begin
                    S_unbind<=0;
                    if(!S_authorized) S_target_source<=S_config[244];
                    S_state<=DECIDE;
                end
                DECIDE:if(!I_clock_enable || I_event_quarantined || O_quarantined || !S_selected_ok) begin
                    if(O_error==0) O_error<=!I_clock_enable ? 4'd5 : 4'd4;
                    O_recovery_required<=1; S_state<=RESULT;
                end else if(S_anchored && !I_event_busy) begin
                    S_single_config<=S_config; S_single_config[246:245]<=S_single_mask; S_single_config[244]<=S_target_source;
                    S_single_config[107:105]<=0; S_single_config[88:72]<=0;
                    S_settle_target<=S_selected_frame; O_selected_source<=S_target_source;
                    S_state<=SET_OFFER;
                end
                SET_OFFER:if(I_event_ready) S_state<=SET_WAIT;
                SET_WAIT:if(I_event_done_valid) begin
                    if(!S_done_match) O_response_discarded<=1;
                    else begin
                        O_settle_error<=I_event_done_error;
                        if(I_event_done_applied) begin O_settle_time<=I_event_done_time; O_commit_epoch<=I_event_commit_epoch; end
                        if(I_event_done_error!=0 || !I_event_done_applied || !I_event_done_retired ||
                            I_event_commit_epoch==0 || !S_done_time_ok) begin
                            if(O_error==0) O_error<=6;
                            O_recovery_required<=1; S_state<=RESULT;
                        end else S_state<=PROOF;
                    end
                end
                PROOF:if(!I_clock_enable || I_event_quarantined || !S_selected_ok) begin
                    if(O_error==0) O_error<=!I_clock_enable ? 4'd5 : 4'd4;
                    O_recovery_required<=1; S_state<=RESULT;
                end
                    else if(S_single_active_ok && S_lease_proof) begin
                        O_settled<=1; O_recovery_required<=0; O_image_hold<=S_single_mask; S_state<=RESULT;
                    end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin O_error<=6; O_quarantined<=1; O_recovery_required<=1; S_state<=RESULT; end
            endcase
        end
    end
endmodule
