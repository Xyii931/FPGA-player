// BGM-only file replacement. This mailbox never changes display or dwell state.
// Stable slot/epoch/result payloads require the same TD CDC review as player_control_cdc.
module bgm_loop_cdc #(
    parameter integer PREFETCH_FRAMES=48000,
    parameter integer FADE_FRAMES=9600
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_start_valid,
    output wire O_start_ready,O_need,
    input wire I_slot,
    input wire [15:0] I_track_epoch,
    input wire I_abort,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [7:0] O_result,
    input wire I_clock_enable,I_pause,I_media_abort,I_transition_busy,
    input wire [1:0] I_track_known,I_track_enabled,I_track_failed,
    input wire [31:0] I_track_epochs,
    input wire [63:0] I_track_serials,I_track_totals,I_track_next_index,
    input wire I_active_b,I_fade_ready,I_fade_done,
    output wire O_fade_valid,O_target_b,O_video_busy,O_stop_request,
    input wire I_stop_ack
);
    localparam [2:0] H_IDLE=0,H_WAIT=1,H_CAPTURE=2,H_RESULT=3,H_CLEAR=4;
    localparam [3:0] V_IDLE=0,V_CAPTURE=1,V_PREPARE=2,V_OFFER=3,V_RUN=4,
        V_STOP=5,V_STOP_CLEAR=6,V_HOLD=7;
    reg [2:0] S_host_state;
    reg [3:0] S_video_state;
    reg S_request,S_ack,S_abort,S_host_slot,S_slot,S_offered,S_pending_offer;
    reg [15:0] S_host_epoch,S_epoch;
    reg [31:0] S_serial;
    reg [7:0] S_video_result,S_host_result;
    wire S_host_reset,S_video_reset;
    (* ASYNC_REG="TRUE" *) reg S_req_meta,S_req_sync,S_ack_meta,S_ack_sync;
    (* ASYNC_REG="TRUE" *) reg S_abort_meta,S_abort_sync,S_need_meta,S_need_sync;
    wire [31:0] S_active_total=I_track_totals[I_active_b*32+:32];
    wire [31:0] S_active_index=I_track_next_index[I_active_b*32+:32];
    wire [31:0] S_remaining=S_active_index<=S_active_total ? S_active_total-S_active_index : 32'd0;
    wire S_need_video=I_track_known[I_active_b] && I_track_enabled[I_active_b] &&
        !I_track_failed[I_active_b] && S_active_total!=0 && S_remaining<=PREFETCH_FRAMES;
    wire S_fresh=I_track_known[S_slot] && !I_track_enabled[S_slot] && !I_track_failed[S_slot] &&
        I_track_epochs[S_slot*16+:16]==S_epoch && I_track_serials[S_slot*32+:32]!=0 &&
        I_track_next_index[S_slot*32+:32]==0;
    wire S_same_serial=I_track_known[S_slot] && I_track_epochs[S_slot*16+:16]==S_epoch &&
        I_track_serials[S_slot*32+:32]==S_serial && !I_track_failed[S_slot];
    wire S_cancel=S_abort_sync || I_media_abort || !I_clock_enable;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    assign O_start_ready=!S_host_reset && S_host_state==H_IDLE && !I_abort;
    assign O_need=!S_host_reset && S_need_sync;
    assign O_done_valid=!S_host_reset && S_host_state==H_RESULT;
    assign O_result=S_host_result;
    // Once offered, valid remains asserted until acceptance or real stop acknowledgement.
    assign O_fade_valid=!S_video_reset && S_pending_offer &&
        (S_video_state==V_OFFER || (S_video_state==V_STOP && !I_stop_ack));
    assign O_target_b=S_slot;
    assign O_video_busy=S_video_state!=V_IDLE && S_video_state!=V_HOLD;
    assign O_stop_request=!S_video_reset && S_video_state==V_STOP;
    task finish;
        input [3:0] error;
        input not_started;
        begin
            S_video_result<={error,not_started,I_active_b,I_track_enabled};
            S_ack<=1; S_video_state<=V_HOLD;
        end
    endtask
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_host_state<=H_IDLE; S_request<=0; S_abort<=0; S_host_slot<=0; S_host_epoch<=0;
            S_host_result<=0; S_ack_meta<=0; S_ack_sync<=0; S_need_meta<=0; S_need_sync<=0;
        end else begin
            S_ack_meta<=S_ack; S_ack_sync<=S_ack_meta;
            S_need_meta<=S_need_video; S_need_sync<=S_need_meta;
            if((S_host_state==H_WAIT || S_host_state==H_CAPTURE || S_host_state==H_RESULT) && I_abort) S_abort<=1;
            case(S_host_state)
                H_IDLE:if(I_start_valid && O_start_ready) begin
                    S_host_slot<=I_slot; S_host_epoch<=I_track_epoch;
                    S_request<=1; S_abort<=0; S_host_state<=H_WAIT;
                end
                H_WAIT:if(S_ack_sync) S_host_state<=H_CAPTURE;
                H_CAPTURE:begin S_host_result<=S_video_result; S_host_state<=H_RESULT; end
                H_RESULT:if(I_done_ready) begin S_request<=0; S_abort<=0; S_host_state<=H_CLEAR; end
                H_CLEAR:if(!S_ack_sync) begin S_abort<=0; S_host_state<=H_IDLE; end
                default:S_host_state<=H_IDLE;
            endcase
        end
    end
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_video_state<=V_IDLE; S_slot<=0; S_epoch<=0; S_serial<=0; S_offered<=0; S_pending_offer<=0;
            S_video_result<=0; S_ack<=0; S_req_meta<=0; S_req_sync<=0; S_abort_meta<=0; S_abort_sync<=0;
        end else begin
            S_req_meta<=S_request; S_req_sync<=S_req_meta;
            S_abort_meta<=S_abort; S_abort_sync<=S_abort_meta;
            if(O_fade_valid && I_fade_ready) S_pending_offer<=0;
            case(S_video_state)
                V_IDLE:if(S_req_sync) S_video_state<=V_CAPTURE;
                V_CAPTURE:begin
                    S_slot<=S_host_slot; S_epoch<=S_host_epoch; S_serial<=0;
                    S_offered<=0; S_pending_offer<=0; S_video_state<=V_PREPARE;
                end
                V_PREPARE:if(S_cancel) finish(4'd3,1'b1);
                    else if(I_track_failed[S_slot]) finish(4'd4,1'b1);
                    else if(S_fresh && !I_transition_busy && !I_pause && S_remaining<=FADE_FRAMES && I_fade_ready) begin
                        S_serial<=I_track_serials[S_slot*32+:32]; S_offered<=1; S_pending_offer<=1; S_video_state<=V_OFFER;
                    end
                V_OFFER:if(S_cancel || !S_same_serial) S_video_state<=V_STOP;
                    else if(I_fade_ready) S_video_state<=V_RUN;
                V_RUN:if(S_cancel || !S_same_serial) S_video_state<=V_STOP;
                    else if(I_fade_done) begin
                        if(I_active_b==S_slot && I_track_enabled[S_slot]) finish(4'd0,1'b0);
                        else S_video_state<=V_STOP;
                    end
                V_STOP:if(I_stop_ack) begin S_pending_offer<=0; S_video_state<=V_STOP_CLEAR; end
                V_STOP_CLEAR:if(!I_stop_ack) finish(4'd3,!S_offered);
                V_HOLD:if(!S_req_sync && !S_abort_sync) begin S_ack<=0; S_video_state<=V_IDLE; end
                default:S_video_state<=V_STOP;
            endcase
        end
    end
endmodule
