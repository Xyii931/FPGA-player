// One stable-payload mailbox; reset must cover BOTH clock domains and all owners.
// CDC implementation requires TD bus-skew/max-delay review, not bitwise bus sync.
module player_control_cdc (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [403:0] I_command,
    input wire [9:0] I_dwell_seconds,
    input wire I_abort,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output wire [127:0] O_result,
    output wire [63:0] O_audio_bookmark,
    output wire O_dwell_expired,
    input wire I_clock_enable,I_pause,I_hold_dwell,
    input wire [31:0] I_time,
    input wire [1:0] I_track_known,I_track_enabled,
    input wire [31:0] I_track_epochs,
    input wire [63:0] I_track_serials,I_track_next_index,
    input wire I_active_b,I_audio_has_started,
    output wire O_video_start_valid,
    input wire I_video_start_ready,
    output wire [403:0] O_video_command,
    output wire O_video_abort,
    input wire I_video_done_valid,
    output wire O_video_done_ready,
    input wire [31:0] I_video_epoch,
    input wire [15:0] I_video_tag,
    input wire [3:0] I_video_error,
    input wire I_video_settled,I_video_selected_source,I_video_recovery_required,I_video_transition_started,
    input wire I_video_quarantined,I_video_sync_required,
    input wire [31:0] I_video_dwell_start,
    output reg O_response_discarded
);
    localparam [2:0] H_IDLE=0,H_WAIT=1,H_CAPTURE=2,H_RESULT=3,H_CLEAR=4;
    localparam [2:0] V_IDLE=0,V_CAPTURE=1,V_RESOLVE=2,V_OFFER=3,V_RUN=4,V_HOLD=5;
    reg [2:0] S_host_state,S_video_state;
    reg [403:0] S_host_command,S_video_command;
    reg [9:0] S_host_dwell,S_video_dwell;
    reg [127:0] S_video_result,S_host_result;
    reg [63:0] S_last_next,S_last_serial,S_video_bookmark,S_host_bookmark;
    reg [33:0] S_saved_remaining;
    reg S_saved_armed,S_saved_expired,S_command_held_dwell;
    reg [1:0] S_enabled_previous;
    integer S_track;
    reg S_request,S_ack,S_abort;
    reg [33:0] S_remaining;
    reg S_dwell_armed,S_expired;
    wire S_host_reset,S_video_reset;
    (* ASYNC_REG="TRUE" *) reg S_req_meta,S_req_sync,S_ack_meta,S_ack_sync;
    (* ASYNC_REG="TRUE" *) reg S_abort_meta,S_abort_sync,S_expired_meta,S_expired_sync;
    wire [1:0] S_action=S_video_command[82:81];
    wire S_slot=S_video_command[80];
    wire S_fresh_ready=I_track_known[S_slot] && !I_track_enabled[S_slot] &&
        I_track_epochs[S_slot*16+:16]==S_video_command[79:64] &&
        I_track_serials[S_slot*32+:32]!=0;
    wire S_reuse_ready=I_track_known[I_active_b] && I_track_enabled[I_active_b] &&
        I_track_serials[I_active_b*32+:32]!=0;
    wire S_cancel=S_abort_sync || !I_clock_enable;
    wire [33:0] S_dwell_cycles={24'd0,S_video_dwell}*34'd25000000;
    wire [31:0] S_dwell_age=I_time-I_video_dwell_start;
    wire S_done_match=I_video_epoch==S_video_command[403:372] &&
        I_video_tag==S_video_command[371:356];
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    assign O_start_ready=!S_host_reset && S_host_state==H_IDLE && !I_abort;
    assign O_busy=S_host_state!=H_IDLE;
    assign O_done_valid=!S_host_reset && S_host_state==H_RESULT;
    assign O_result=S_host_result;
    assign O_audio_bookmark=S_host_bookmark;
    assign O_dwell_expired=!S_host_reset && S_expired_sync;
    // Before acceptance cancellation suppresses the offer. After it, drain the real owner.
    assign O_video_start_valid=!S_video_reset && S_video_state==V_OFFER && !S_cancel;
    assign O_video_command=S_video_command;
    assign O_video_abort=!S_video_reset && S_cancel;
    assign O_video_done_ready=!S_video_reset && S_video_state==V_RUN;
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_host_state<=H_IDLE; S_host_command<=0; S_host_dwell<=0; S_host_result<=0; S_host_bookmark<=0;
            S_request<=0; S_abort<=0; S_ack_meta<=0; S_ack_sync<=0;
            S_expired_meta<=0; S_expired_sync<=0;
        end else begin
            S_ack_meta<=S_ack; S_ack_sync<=S_ack_meta;
            S_expired_meta<=S_expired; S_expired_sync<=S_expired_meta;
            if((S_host_state==H_WAIT || S_host_state==H_CAPTURE || S_host_state==H_RESULT) && I_abort) S_abort<=1;
            case(S_host_state)
                H_IDLE:if(I_start_valid && O_start_ready) begin
                    S_host_command<=I_command; S_host_dwell<=I_dwell_seconds;
                    S_request<=1; S_abort<=0; S_host_state<=H_WAIT;
                end
                H_WAIT:if(S_ack_sync) S_host_state<=H_CAPTURE;
                H_CAPTURE:begin S_host_result<=S_video_result; S_host_bookmark<=S_video_bookmark; S_host_state<=H_RESULT; end
                H_RESULT:if(I_done_ready) begin S_request<=0; S_abort<=0; S_host_state<=H_CLEAR; end
                H_CLEAR:if(!S_ack_sync) begin S_abort<=0; S_host_state<=H_IDLE; end
                default:begin S_abort<=1; S_host_state<=H_WAIT; end
            endcase
        end
    end
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_video_state<=V_IDLE; S_video_command<=0; S_video_dwell<=0; S_video_result<=0;
            S_req_meta<=0; S_req_sync<=0; S_abort_meta<=0; S_abort_sync<=0; S_ack<=0;
            S_remaining<=0; S_dwell_armed<=0; S_expired<=0; O_response_discarded<=0;
            S_last_next<=0; S_last_serial<=0; S_video_bookmark<=0; S_saved_remaining<=0;
            S_saved_armed<=0; S_saved_expired<=0; S_command_held_dwell<=0; S_enabled_previous<=0;
        end else begin
            S_req_meta<=S_request; S_req_sync<=S_req_meta;
            S_abort_meta<=S_abort; S_abort_sync<=S_abort_meta;
            O_response_discarded<=0;
            S_enabled_previous<=I_track_enabled;
            // Retain the actual final unconsumed frame across real stop/slot clear.
            for(S_track=0;S_track<2;S_track=S_track+1)
                if(I_track_known[S_track] && (I_track_enabled[S_track] || S_enabled_previous[S_track] ||
                    I_track_serials[S_track*32+:32]!=S_last_serial[S_track*32+:32])) begin
                    S_last_next[S_track*32+:32]<=I_track_next_index[S_track*32+:32];
                    S_last_serial[S_track*32+:32]<=I_track_serials[S_track*32+:32];
                end
            if(S_dwell_armed && I_clock_enable && !I_pause && !I_hold_dwell) begin
                if(S_remaining<=1) begin S_remaining<=0; S_expired<=1; S_dwell_armed<=0; end
                else S_remaining<=S_remaining-1'b1;
            end
            case(S_video_state)
                V_IDLE:if(S_req_sync) S_video_state<=V_CAPTURE;
                V_CAPTURE:begin
                    S_video_command<=S_host_command; S_video_dwell<=S_host_dwell;
                    S_command_held_dwell<=I_hold_dwell;
                    if(!I_hold_dwell) begin
                        S_saved_remaining<=S_remaining; S_saved_armed<=S_dwell_armed; S_saved_expired<=S_expired;
                        S_expired<=0; S_dwell_armed<=0;
                    end
                    S_video_state<=V_RESOLVE;
                end
                V_RESOLVE:if(S_cancel) begin
                    if(I_hold_dwell && !S_command_held_dwell) begin
                        S_remaining<=S_saved_remaining; S_dwell_armed<=S_saved_armed; S_expired<=S_saved_expired;
                    end
                    S_video_result<={S_video_command[403:356],4'd3,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,
                        32'd0,I_active_b,I_track_known,I_track_enabled,33'd0};
                    S_video_bookmark<=S_last_next;
                    for(S_track=0;S_track<2;S_track=S_track+1)
                        if(I_track_enabled[S_track]) S_video_bookmark[S_track*32+:32]<=I_track_next_index[S_track*32+:32];
                    S_ack<=1; S_video_state<=V_HOLD;
                end else if(S_action==0) S_video_state<=V_OFFER;
                else if(S_action==3) begin
                    if(S_reuse_ready) begin
                        S_video_command[80]<=I_active_b;
                        S_video_command[79:64]<=I_track_epochs[I_active_b*16+:16];
                        S_video_command[63:32]<=I_track_serials[I_active_b*32+:32];
                        S_video_command[31:0]<=I_track_next_index[I_active_b*32+:32];
                    end else begin S_video_command[82:81]<=0; S_video_command[63:32]<=0; end
                    S_video_state<=V_OFFER;
                end else if(S_fresh_ready) begin
                    // Both-slot stop does not reset the shared mixer. Resume it
                    // using fade, even when neither old track is still enabled.
                    S_video_command[82:81]<=I_audio_has_started ? 2'd2 : 2'd1;
                    S_video_command[63:32]<=I_track_serials[S_slot*32+:32];
                    S_video_command[31:0]<=I_track_next_index[S_slot*32+:32];
                    S_video_state<=V_OFFER;
                end
                V_OFFER:if(S_cancel) begin
                    if(I_hold_dwell && !S_command_held_dwell) begin
                        S_remaining<=S_saved_remaining; S_dwell_armed<=S_saved_armed; S_expired<=S_saved_expired;
                    end
                    S_video_result<={S_video_command[403:356],4'd3,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,
                        32'd0,I_active_b,I_track_known,I_track_enabled,33'd0};
                    S_video_bookmark<=S_last_next;
                    for(S_track=0;S_track<2;S_track=S_track+1)
                        if(I_track_enabled[S_track]) S_video_bookmark[S_track*32+:32]<=I_track_next_index[S_track*32+:32];
                    S_ack<=1; S_video_state<=V_HOLD;
                end else if(I_video_start_ready) S_video_state<=V_RUN;
                V_RUN:if(I_video_done_valid) begin
                    if(!S_done_match) O_response_discarded<=1;
                    else begin
                        S_video_result<={I_video_epoch,I_video_tag,I_video_error,I_video_settled,
                            I_video_selected_source,I_video_recovery_required,I_video_quarantined,!I_video_transition_started,
                            I_video_sync_required,I_video_dwell_start,I_active_b,I_track_known,I_track_enabled,33'd0};
                        if(I_hold_dwell && !S_command_held_dwell && I_video_settled && !I_video_quarantined && !I_video_sync_required) begin
                            if(I_video_selected_source==S_video_command[353]) begin
                                S_remaining<=S_saved_remaining; S_dwell_armed<=S_saved_armed; S_expired<=S_saved_expired;
                            end else begin
                                S_remaining<=S_dwell_cycles; S_dwell_armed<=S_dwell_cycles!=0; S_expired<=S_dwell_cycles==0;
                            end
                        end else if(!I_hold_dwell && I_video_settled && I_video_error==0 && !I_video_quarantined && !I_video_sync_required) begin
                            if(S_dwell_age[31] || {2'd0,S_dwell_age}>=S_dwell_cycles) begin
                                S_remaining<=0; S_expired<=1; S_dwell_armed<=0;
                            end else begin
                                S_remaining<=S_dwell_cycles-{2'd0,S_dwell_age}; S_dwell_armed<=1; S_expired<=0;
                            end
                        end
                        S_video_bookmark<=S_last_next;
                    for(S_track=0;S_track<2;S_track=S_track+1)
                        if(I_track_enabled[S_track]) S_video_bookmark[S_track*32+:32]<=I_track_next_index[S_track*32+:32];
                    S_ack<=1; S_video_state<=V_HOLD;
                    end
                end
                V_HOLD:if(!S_req_sync && !S_abort_sync) begin S_ack<=0; S_video_state<=V_IDLE; end
                default:begin S_video_state<=V_RESOLVE; end
            endcase
        end
    end
endmodule
