// One reliable event transaction in the shared 25 MHz video/audio domain.
// Video ready is enqueue only; completion requires an actual, identified apply report.
module av_event_timeline #(
    parameter integer MIN_LEAD=32000,
    parameter integer STOP_PENDING_AUDIO=0
) (
    input wire I_clk,I_reset,I_clock_enable,
    input wire [31:0] I_time,
    input wire I_frame_start,I_sample_tick,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    input wire [2:0] I_effect,
    input wire [15:0] I_duration_frames,
    input wire signed [6:0] I_av_offset_steps,
    input wire [1:0] I_audio_action,
    input wire I_audio_slot,
    input wire [15:0] I_track_epoch,
    input wire [31:0] I_track_serial,I_start_index,
    input wire I_resources_ready,
    input wire [31:0] I_resources_epoch,
    input wire [15:0] I_resources_tag,
    input wire [1:0] I_track_known,I_track_enabled,I_track_consumed,
    input wire [31:0] I_track_epochs,
    input wire [63:0] I_track_serials,I_track_totals,I_track_next_index,
    input wire I_pause,I_abort,
    output wire O_pause_allow,
    output wire O_video_valid,
    input wire I_video_ready,
    output wire O_video_cancel,
    output wire [31:0] O_video_epoch,
    output wire [15:0] O_video_tag,
    output wire [2:0] O_video_effect,
    output wire [15:0] O_video_frame_index,
    output wire [16:0] O_video_progress,
    output wire [31:0] O_video_target_time,
    input wire I_video_done_valid,
    output wire O_video_done_ready,
    input wire [31:0] I_video_done_epoch,
    input wire [15:0] I_video_done_tag,I_video_done_frame_index,
    input wire [3:0] I_video_done_error,
    input wire I_video_done_applied,
    input wire [31:0] I_video_done_time,
    output wire O_play_valid,
    input wire I_play_ready,
    output wire O_fade_valid,O_target_b,
    output wire [31:0] O_audio_target_time,
    input wire I_fade_ready,I_fade_done,I_active_b,
    output wire O_silence_valid,
    input wire I_silence_ready,I_silence_started,I_silence_done,
    output wire O_audio_stop_request,
    input wire I_audio_stop_ack,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [31:0] O_epoch,
    output reg [15:0] O_tag,
    output reg O_cancel_late,O_video_started,O_video_finished,O_audio_started,O_audio_finished,
    output reg [31:0] O_planned_start,O_planned_midpoint,O_planned_audio,
    output reg [31:0] O_actual_start,O_actual_midpoint,O_actual_audio,O_actual_finish,
    output reg [31:0] O_audio_command_time,O_audio_start_index,
    output reg signed [31:0] O_anchor_error,
    output reg O_midpoint_seen,O_late,O_contract_fault,O_quarantined,O_response_discarded
);
    localparam [2:0] IDLE=0,WAIT_READY=1,DIVIDE=2,PLAN=3,RUN=4,DRAIN=5,RESULT=6;
    localparam [1:0] V_IDLE=0,V_OFFER=1,V_WAIT=2;
    localparam [2:0] A_IDLE=0,A_OFFER=1,A_FIRST=2,A_FADE=3,A_DONE=4;
    localparam [31:0] FRAME_CYCLES=420000;
    reg [2:0] S_state,S_audio_state;
    reg [1:0] S_video_state,S_audio_action,S_stop_state;
    reg S_anchored,S_time_valid,S_slot,S_cancel,S_audio_sent;
    reg [31:0] S_frame_origin,S_previous_time,S_last_epoch,S_transaction_time;
    reg [2:0] S_effect;
    reg [15:0] S_duration,S_half,S_track_epoch,S_index;
    reg [31:0] S_track_serial,S_start_index,S_candidate,S_video_target,S_audio_target;
    reg signed [31:0] S_offset;
    reg [16:0] S_div_q,S_div_r,S_step,S_fraction,S_progress,S_accum;
    reg [4:0] S_div_bit;
    wire S_live=I_clock_enable && !O_quarantined;
    wire S_active=S_state!=IDLE && S_state!=RESULT;
    wire [31:0] S_live_origin=I_frame_start ? I_time : S_frame_origin;
    wire [31:0] S_frame_age=I_time-S_frame_origin;
    wire [31:0] S_transaction_age=I_time-S_transaction_time;
    wire [31:0] S_half_ticks={16'd0,S_half}*FRAME_CYCLES;
    wire [31:0] S_candidate_mid=S_candidate+S_half_ticks;
    wire [31:0] S_candidate_audio=S_candidate_mid+S_offset;
    wire [31:0] S_start_ahead=S_candidate-I_time;
    wire [31:0] S_audio_ahead=S_candidate_audio-I_time;
    wire [31:0] S_audio_due=I_time-S_audio_target;
    wire [31:0] S_done_lag=I_time-I_video_done_time;
    wire [31:0] S_done_delta=I_video_done_time-S_video_target;
    wire [31:0] S_next_index=I_track_next_index[S_slot*32+:32];
    wire [31:0] S_total=I_track_totals[S_slot*32+:32];
    // action 0/slot 1 is an explicit fade-to-silence event; slot 0 stays no-op.
    wire S_silence=S_audio_action==0 && S_slot;
    wire S_no_event=S_audio_action==0 && !S_slot;
    wire S_identity_ok=S_audio_action==0 || (I_track_known[S_slot] &&
        I_track_epochs[S_slot*16+:16]==S_track_epoch && I_track_serials[S_slot*32+:32]==S_track_serial &&
        S_next_index<=S_total &&
        ((S_audio_sent || S_audio_action==3) ? (I_track_enabled[S_slot] && S_next_index>=S_start_index) :
        (!I_track_enabled[S_slot] && S_next_index==S_start_index)));
    wire S_resources_ok=I_resources_ready && I_resources_epoch==O_epoch && I_resources_tag==O_tag && S_identity_ok;
    wire [17:0] S_trial={S_div_r,S_div_q[16]};
    wire S_subtract=S_trial>={2'd0,S_duration};
    wire [17:0] S_remainder_next=S_subtract ? S_trial-{2'd0,S_duration} : S_trial;
    wire [16:0] S_quotient_next={S_div_q[15:0],S_subtract};
    wire [17:0] S_fraction_sum={1'b0,S_accum}+{1'b0,S_fraction};
    wire S_fraction_carry=S_fraction_sum>={2'd0,S_duration};
    wire [16:0] S_next_progress=S_progress+S_step+S_fraction_carry;
    wire [31:0] S_actual_mid_estimate=I_video_done_time+({16'd0,S_half}-{16'd0,S_index})*FRAME_CYCLES;
    wire S_done_match=I_video_done_epoch==O_epoch && I_video_done_tag==O_tag && I_video_done_frame_index==S_index;
    wire S_done_time_ok=!S_done_lag[31] && !S_done_delta[31] && S_done_delta%FRAME_CYCLES==0;
    wire S_video_report=S_video_state==V_WAIT && I_video_done_valid && S_done_match;
    wire S_video_reject=S_video_report && (I_video_done_error!=0 || !I_video_done_applied || !S_done_time_ok);
    wire S_mid_report=S_video_report && I_video_done_applied && S_done_time_ok && S_index==S_half;
    wire S_time_fault=I_clock_enable && ((S_time_valid && I_time!=S_previous_time+1'b1) ||
        (S_anchored && ((I_frame_start && S_frame_age!=FRAME_CYCLES) || (!I_frame_start && S_frame_age>=FRAME_CYCLES))));
    wire S_abort_now=I_abort || !I_clock_enable || O_quarantined || S_time_fault ||
        (S_state==RUN && !S_identity_ok) || (S_active && S_transaction_age[31]);
    wire S_cancelling=S_cancel || S_abort_now;
    wire S_draining_now=S_cancelling || S_video_reject;
    wire [3:0] S_cancel_error=(S_time_fault || O_quarantined || S_transaction_age[31]) ? 4'd6 :
        (!I_clock_enable ? 4'd5 : (I_abort ? 4'd3 : 4'd4));
    wire S_audio_handshake=S_audio_state==A_OFFER &&
        ((S_audio_action==1 && I_play_ready) || (S_audio_action==2 && I_fade_ready) ||
        (S_silence && I_silence_ready));
    assign O_start_ready=!I_reset && !O_quarantined && S_state==IDLE;
    assign O_busy=S_state!=IDLE || O_quarantined;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_pause_allow=S_state==IDLE || S_state==WAIT_READY || S_state==RESULT;
    assign O_video_valid=!I_reset && S_video_state==V_OFFER;
    assign O_video_cancel=!I_reset && S_video_state!=V_IDLE && S_cancelling;
    assign {O_video_epoch,O_video_tag,O_video_effect}={O_epoch,O_tag,S_effect};
    assign O_video_frame_index=S_index;
    assign O_video_progress=S_progress;
    assign O_video_target_time=S_video_target;
    assign O_play_valid=!I_reset && S_audio_state==A_OFFER && S_audio_action==1;
    assign O_fade_valid=!I_reset && S_audio_state==A_OFFER && S_audio_action==2;
    assign O_silence_valid=!I_reset && S_audio_state==A_OFFER && S_silence;
    assign O_target_b=S_slot;
    assign O_audio_target_time=S_audio_target;
    assign O_video_done_ready=!I_reset && S_video_state==V_WAIT;
    assign O_audio_stop_request=!I_reset && S_stop_state==1;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_video_state<=V_IDLE; S_audio_state<=A_IDLE; S_stop_state<=0;
            S_anchored<=0; S_time_valid<=0; S_frame_origin<=0; S_previous_time<=0;
            S_last_epoch<=0; S_transaction_time<=0; S_cancel<=0; S_audio_sent<=0;
            S_audio_action<=0; S_slot<=0; S_track_epoch<=0; S_track_serial<=0; S_start_index<=0;
            S_effect<=0; S_duration<=0; S_half<=0; S_index<=0; S_offset<=0;
            S_candidate<=0; S_video_target<=0; S_audio_target<=0;
            S_div_q<=0; S_div_r<=0; S_step<=0; S_fraction<=0; S_progress<=0; S_accum<=0; S_div_bit<=0;
            O_error<=0; O_epoch<=0; O_tag<=0; O_cancel_late<=0;
            O_video_started<=0; O_video_finished<=0; O_audio_started<=0; O_audio_finished<=0;
            O_planned_start<=0; O_planned_midpoint<=0; O_planned_audio<=0;
            O_actual_start<=0; O_actual_midpoint<=0; O_actual_audio<=0; O_actual_finish<=0;
            O_audio_command_time<=0; O_audio_start_index<=0; O_anchor_error<=0;
            O_midpoint_seen<=0; O_late<=0; O_contract_fault<=0; O_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            if(!I_clock_enable) begin S_anchored<=0; S_time_valid<=0; end
            else begin
                S_time_valid<=1; S_previous_time<=I_time;
                if(I_frame_start) begin S_frame_origin<=I_time; S_anchored<=1; end
            end
            if(S_time_fault) begin O_contract_fault<=1; O_quarantined<=1; end
            if(S_active && S_abort_now) begin
                S_cancel<=1;
                if(O_error==0) O_error<=S_cancel_error;
                if(S_transaction_age[31]) begin O_contract_fault<=1; O_quarantined<=1; end
            end
            // Presented commands remain valid, even when cancellation requires a late drain.
            if(S_video_state==V_OFFER && I_video_ready) S_video_state<=V_WAIT;
            if(S_video_state==V_WAIT && I_video_done_valid) begin
                if(!S_done_match) O_response_discarded<=1;
                else begin
                    S_video_state<=V_IDLE;
                    if(I_video_done_error!=0) begin
                        S_cancel<=1; if(O_error==0) O_error<=S_cancelling ? S_cancel_error : 4'd2;
                    end
                    if((I_video_done_applied && !S_done_time_ok) || (!I_video_done_applied && I_video_done_error==0)) begin
                        S_cancel<=1; O_error<=6; O_contract_fault<=1; O_quarantined<=1;
                    end else if(I_video_done_applied) begin
                        O_video_started<=1;
                        if(S_index==0) O_actual_start<=I_video_done_time;
                        if(S_index==S_half) begin
                            O_actual_midpoint<=I_video_done_time; O_midpoint_seen<=1;
                            if(O_audio_started) O_anchor_error<=O_actual_audio-I_video_done_time-S_offset;
                        end
                        if(S_done_delta!=0) O_late<=1;
                        if(S_draining_now) O_cancel_late<=1;
                        if(S_index==S_duration) begin O_actual_finish<=I_video_done_time; O_video_finished<=1; end
                        else if(!S_draining_now) begin
                            S_index<=S_index+1'b1; S_progress<=S_next_progress;
                            S_accum<=S_fraction_carry ? S_fraction_sum-{2'd0,S_duration} : S_fraction_sum;
                            S_video_target<=I_video_done_time+FRAME_CYCLES; S_video_state<=V_OFFER;
                        end
                        if(S_index<=S_half && S_audio_state==A_IDLE && !S_draining_now)
                            S_audio_target<=S_actual_mid_estimate+S_offset;
                    end
                end
            end
            if(S_audio_handshake) begin
                S_audio_sent<=1; S_audio_state<=A_FIRST; O_audio_command_time<=I_time;
                if(S_cancelling) O_cancel_late<=1;
            end
            if(S_active && S_audio_state==A_FIRST && S_silence && I_silence_started) begin
                O_audio_started<=1; S_audio_state<=A_FADE; O_actual_audio<=I_time-1'b1;
                O_audio_start_index<=0;
                if(O_midpoint_seen || S_mid_report) O_anchor_error<=I_time-1'b1-
                    (S_mid_report ? I_video_done_time : O_actual_midpoint)-S_offset;
                if(I_time-1'b1!=S_audio_target) O_late<=1;
            end
            if(S_active && S_silence && I_silence_done &&
                (S_audio_state==A_FIRST || S_audio_state==A_FADE)) begin
                if(!O_audio_started && !I_silence_started) begin
                    S_cancel<=1; O_error<=6; O_contract_fault<=1; O_quarantined<=1;
                end else begin S_audio_state<=A_DONE; O_audio_finished<=1; end
            end
            if(S_active && S_audio_action!=0 && S_audio_state==A_FIRST && I_track_serials[S_slot*32+:32]==S_track_serial &&
                I_track_epochs[S_slot*16+:16]==S_track_epoch &&
                ((I_track_consumed[S_slot] && S_next_index>S_start_index) ||
                (S_next_index==S_total && I_track_known[S_slot] && I_track_enabled[S_slot] && I_sample_tick))) begin
                O_audio_started<=1; S_audio_state<=S_audio_action==2 ? A_FADE : A_DONE;
                O_actual_audio<=I_track_consumed[S_slot] ? I_time-1'b1 : I_time;
                O_audio_start_index<=I_track_consumed[S_slot] ? S_next_index-1'b1 : S_next_index;
                if(S_audio_action==1) O_audio_finished<=1;
                if(O_midpoint_seen || S_mid_report) O_anchor_error<=(I_track_consumed[S_slot] ? I_time-1'b1 : I_time)-
                    (S_mid_report ? I_video_done_time : O_actual_midpoint)-S_offset;
                if((I_track_consumed[S_slot] ? I_time-1'b1 : I_time)!=S_audio_target) O_late<=1;
            end
            if(S_active && (S_audio_state==A_FIRST || S_audio_state==A_FADE) && I_fade_done && S_audio_action==2) begin
                if(I_active_b!=S_slot) begin S_cancel<=1; O_error<=6; O_contract_fault<=1; O_quarantined<=1; end
                else if(S_audio_state==A_FADE) begin S_audio_state<=A_DONE; O_audio_finished<=1; end
            end
            if(S_active && S_cancelling && (O_video_started || S_audio_sent)) O_cancel_late<=1;
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    O_epoch<=I_epoch; O_tag<=I_tag; O_error<=0; O_cancel_late<=0; S_cancel<=0;
                    S_transaction_time<=I_time; S_effect<=I_effect; S_duration<=I_duration_frames;
                    S_half<=(I_duration_frames+16'd1)>>1;
                    S_offset<=$signed(I_av_offset_steps)*32'sd250000;
                    S_audio_action<=I_audio_action; S_slot<=I_audio_slot; S_track_epoch<=I_track_epoch;
                    S_track_serial<=I_track_serial; S_start_index<=I_start_index;
                    S_index<=0; S_progress<=0; S_accum<=0; S_audio_sent<=0; S_stop_state<=0;
                    S_video_state<=V_IDLE; S_audio_state<=A_IDLE;
                    O_video_started<=0; O_video_finished<=0; O_audio_started<=0;
                    O_audio_finished<=(I_audio_action==0 && !I_audio_slot) || I_audio_action==3;
                    O_planned_start<=0; O_planned_midpoint<=0; O_planned_audio<=0;
                    O_actual_start<=0; O_actual_midpoint<=0; O_actual_audio<=0; O_actual_finish<=0;
                    O_audio_command_time<=0; O_audio_start_index<=0; O_anchor_error<=0; O_midpoint_seen<=0; O_late<=0;
                    if(I_epoch==0 || I_epoch<=S_last_epoch || I_effect>6 || I_duration_frames==0 || I_duration_frames>60 ||
                        I_av_offset_steps< -7'sd50 || I_av_offset_steps>7'sd50 ||
                        (I_audio_action!=0 && I_track_serial==0) || (I_audio_action==1 && I_audio_slot)) begin
                        O_error<=1; S_state<=RESULT;
                    end else begin S_last_epoch<=I_epoch; S_state<=WAIT_READY; end
                end
                WAIT_READY:if(S_cancelling) S_state<=DRAIN;
                    else if(S_live && S_anchored && !I_pause && S_resources_ok) begin
                        S_div_q<=17'd65536; S_div_r<=0; S_div_bit<=0; S_state<=DIVIDE;
                    end
                DIVIDE:if(S_cancelling) S_state<=DRAIN;
                    else if(!S_resources_ok || I_pause) S_state<=WAIT_READY;
                    else begin
                        S_div_q<=S_quotient_next; S_div_r<=S_remainder_next;
                        if(S_div_bit==16) begin
                            S_step<=S_quotient_next; S_fraction<=S_remainder_next;
                            S_candidate<=S_live_origin+FRAME_CYCLES; S_state<=PLAN;
                        end else S_div_bit<=S_div_bit+1'b1;
                    end
                PLAN:if(S_cancelling) S_state<=DRAIN;
                    else if(!S_resources_ok || I_pause) S_state<=WAIT_READY;
                    else if(S_start_ahead>=MIN_LEAD && !S_start_ahead[31] &&
                        (S_no_event || S_audio_action==3 || (S_audio_ahead>=MIN_LEAD && !S_audio_ahead[31]))) begin
                        O_planned_start<=S_candidate; O_planned_midpoint<=S_candidate_mid; O_planned_audio<=S_candidate_audio;
                        S_video_target<=S_candidate; S_audio_target<=S_candidate_audio;
                        S_video_state<=V_OFFER; S_audio_state<=(S_no_event || S_audio_action==3) ? A_DONE : A_IDLE;
                        S_state<=RUN;
                    end else S_candidate<=S_candidate+FRAME_CYCLES;
                RUN:begin
                    if(S_draining_now) S_state<=DRAIN;
                    else begin
                        if(S_audio_state==A_IDLE && !S_audio_due[31] &&
                            !(S_video_report && I_video_done_error==0 && S_done_time_ok && S_index<=S_half))
                            S_audio_state<=A_OFFER;
                        if(O_video_finished && O_audio_finished && S_video_state==V_IDLE) S_state<=RESULT;
                    end
                end
                DRAIN:begin
                    // Default peers must accept an already presented command.
                    // The integrated recycler can also prove a pending command was
                    // canceled: its ack means BOTH slots/file/read-side truly retired.
                    if(S_audio_state==A_IDLE) S_audio_state<=A_DONE;
                    if((S_audio_state!=A_OFFER || STOP_PENDING_AUDIO!=0) && S_video_state==V_IDLE) begin
                        if(!S_audio_sent && S_audio_state!=A_OFFER && S_stop_state==0) S_state<=RESULT;
                        else case(S_stop_state)
                            0:if(!I_audio_stop_ack) S_stop_state<=1;
                            1:if(I_audio_stop_ack) begin
                                S_stop_state<=2;
                                if(STOP_PENDING_AUDIO!=0 && S_audio_state==A_OFFER) begin
                                    S_audio_state<=A_DONE;
                                    if(S_audio_handshake) begin O_error<=6; O_contract_fault<=1; O_quarantined<=1; end
                                end
                            end
                            2:if(!I_audio_stop_ack) begin S_stop_state<=0; S_audio_state<=A_DONE; S_state<=RESULT; end
                            default:begin O_error<=6; O_contract_fault<=1; O_quarantined<=1; end
                        endcase
                    end
                end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin O_error<=6; S_cancel<=1; O_contract_fault<=1; O_quarantined<=1; S_state<=DRAIN; end
            endcase
        end
    end
    // synthesis translate_off
    initial begin
        if(MIN_LEAD<64 || MIN_LEAD>420000 || (STOP_PENDING_AUDIO!=0 && STOP_PENDING_AUDIO!=1)) begin
            $display("FAIL: av_event_timeline invalid minimum lead"); $stop;
        end
    end
    // synthesis translate_on
endmodule
