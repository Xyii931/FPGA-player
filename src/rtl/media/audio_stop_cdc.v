// One video-domain stop owns a real recycle of BOTH host/decode audio slots.
// An accepted recycle retires only on its actual done + available, never a timeout.
module audio_stop_cdc (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_stop_request,
    output reg O_stop_ack,
    output wire O_video_busy,O_host_busy,
    output wire [1:0] O_recycle_valid,
    input wire [1:0] I_recycle_ready,I_recycle_done,I_available
);
    localparam [1:0] V_IDLE=0,V_WAIT=1,V_HOLD=2,V_CLEAR=3;
    reg [1:0] S_video_state;
    reg S_request,S_host_active,S_host_ack;
    reg [1:0] S_offer,S_completed;
    (* ASYNC_REG="TRUE" *) reg S_request_meta,S_request_sync;
    (* ASYNC_REG="TRUE" *) reg S_ack_meta,S_ack_sync;
    wire S_host_reset,S_video_reset;
    wire [1:0] S_accept=O_recycle_valid & I_recycle_ready;
    // A previous owner's done may coincide with our new ready/valid edge.
    // Real slot recycling takes multiple cycles: ignore done until AFTER accept.
    wire [1:0] S_done=I_recycle_done & ~S_offer;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    assign O_video_busy=!S_video_reset && (S_video_state!=V_IDLE || I_stop_request);
    assign O_host_busy=!S_host_reset && (S_host_active || S_request_sync);
    assign O_recycle_valid={2{!S_host_reset && S_host_active && !S_host_ack}} & S_offer;
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_video_state<=V_IDLE; S_request<=0; S_ack_meta<=0; S_ack_sync<=0; O_stop_ack<=0;
        end else begin
            S_ack_meta<=S_host_ack; S_ack_sync<=S_ack_meta;
            case(S_video_state)
                V_IDLE:if(I_stop_request) begin S_request<=1; S_video_state<=V_WAIT; end
                V_WAIT:if(S_ack_sync) begin O_stop_ack<=1; S_video_state<=V_HOLD; end
                V_HOLD:if(!I_stop_request) begin S_request<=0; S_video_state<=V_CLEAR; end
                V_CLEAR:if(!S_ack_sync) begin O_stop_ack<=0; S_video_state<=V_IDLE; end
                default:begin S_request<=1; S_video_state<=V_WAIT; end
            endcase
        end
    end
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_request_meta<=0; S_request_sync<=0; S_host_active<=0; S_host_ack<=0;
            S_offer<=0; S_completed<=0;
        end else begin
            S_request_meta<=S_request; S_request_sync<=S_request_meta;
            if(!S_host_active) begin
                if(S_request_sync) begin S_host_active<=1; S_offer<=3; S_completed<=0; end
            end else if(!S_host_ack) begin
                S_offer<=S_offer & ~S_accept;
                S_completed<=S_completed | S_done;
                if((S_offer & ~S_accept)==0 && (S_completed | S_done)==3 && I_available==3)
                    S_host_ack<=1;
            end else if(!S_request_sync) begin
                S_host_ack<=0; S_host_active<=0; S_offer<=0; S_completed<=0;
            end
        end
    end
endmodule
