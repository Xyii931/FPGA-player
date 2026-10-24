// Reserve an unused physical source at a video boundary before host lock changes.
// Real reader retirement and external references must both complete before ack.
module display_source_guard (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire [1:0] I_host_reserve,I_host_retire_request,
    output wire [1:0] O_host_source_idle,O_host_acquire_permit,O_host_retire_ack,O_host_busy,O_host_fault,
    input wire I_video_frame_start,
    input wire [1:0] I_video_in_use,I_video_reader_ack,I_video_owner_retired,I_video_pipeline_retired,
    output wire [1:0] O_video_block,O_video_reader_stop,O_video_retire_ack,O_video_fault
);
    localparam [1:0] H_IDLE=0,H_WAIT=1,H_HELD=2,H_CLEAR=3;
    localparam [1:0] R_IDLE=0,R_WAIT=1,R_HELD=2,R_CLEAR=3;
    localparam [1:0] V_IDLE=0,V_WAIT=1,V_HELD=2,V_CLEAR=3;
    wire S_host_reset,S_video_reset;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    genvar g;
    generate for(g=0;g<2;g=g+1) begin: GEN_SOURCE
        reg [1:0] S_host_state,S_retire_state,S_video_state;
        reg S_reserve,S_retire,S_host_ack,S_host_fault,S_grant,S_stop,S_video_ack,S_video_fault;
        reg S_host_idle,S_host_busy;
        (* ASYNC_REG="TRUE" *) reg S_reserve_meta,S_reserve_sync,S_retire_meta,S_retire_sync;
        (* ASYNC_REG="TRUE" *) reg S_grant_meta,S_grant_sync,S_ack_meta,S_ack_sync,S_fault_meta,S_fault_sync;
        assign O_host_source_idle[g]=S_host_idle && !I_async_reset && !S_host_reset;
        assign O_host_acquire_permit[g]=O_host_source_idle[g];
        assign O_host_retire_ack[g]=S_host_ack && !I_async_reset && !S_host_reset;
        assign O_host_busy[g]=S_host_busy;
        assign O_host_fault[g]=S_host_fault;
        assign O_video_block[g]=S_grant || S_video_fault;
        assign O_video_reader_stop[g]=S_stop;
        assign O_video_retire_ack[g]=S_video_ack;
        assign O_video_fault[g]=S_video_fault;
        always @(posedge I_host_clk or posedge S_host_reset) begin
            if(S_host_reset) begin
                S_host_state<=H_IDLE; S_retire_state<=R_IDLE;
                S_reserve<=0; S_retire<=0; S_host_ack<=0; S_host_fault<=0; S_host_idle<=0; S_host_busy<=0;
                S_grant_meta<=0; S_grant_sync<=0; S_ack_meta<=0; S_ack_sync<=0; S_fault_meta<=0; S_fault_sync<=0;
            end else begin
                S_grant_meta<=S_grant; S_grant_sync<=S_grant_meta;
                S_ack_meta<=S_video_ack; S_ack_sync<=S_ack_meta;
                S_fault_meta<=S_video_fault; S_fault_sync<=S_fault_meta;
                if(S_fault_sync) S_host_fault<=1;
                if(I_host_retire_request[g] && S_host_state==H_IDLE && !I_host_reserve[g]) S_host_fault<=1;
                S_host_idle<=S_host_state==H_HELD && S_grant_sync && !S_host_fault && !S_fault_sync;
                case(S_host_state)
                    H_IDLE:if(I_host_reserve[g] && !S_grant_sync && !S_ack_sync && !S_host_fault) begin
                        S_reserve<=1; S_host_busy<=1; S_host_state<=H_WAIT;
                    end
                    H_WAIT:if(S_grant_sync) S_host_state<=H_HELD;
                    H_HELD:if(!I_host_reserve[g] && !I_host_retire_request[g] && S_retire_state==R_IDLE && !S_ack_sync) begin
                        S_reserve<=0; S_host_idle<=0; S_host_state<=H_CLEAR;
                    end
                    H_CLEAR:if(!S_grant_sync) begin S_host_busy<=0; S_host_idle<=0; S_host_state<=H_IDLE; end
                    default:S_host_state<=H_IDLE;
                endcase
                case(S_retire_state)
                    R_IDLE:if(S_host_state==H_HELD && S_grant_sync && I_host_retire_request[g] &&
                        !S_ack_sync && !S_host_fault && !S_fault_sync) begin S_retire<=1; S_retire_state<=R_WAIT; end
                    R_WAIT:if(S_ack_sync) begin S_host_ack<=1; S_retire_state<=R_HELD; end
                    R_HELD:if(!I_host_retire_request[g]) begin S_retire<=0; S_retire_state<=R_CLEAR; end
                    R_CLEAR:if(!S_ack_sync) begin S_host_ack<=0; S_retire_state<=R_IDLE; end
                    default:S_retire_state<=R_IDLE;
                endcase
            end
        end
        always @(posedge I_video_clk or posedge S_video_reset) begin
            if(S_video_reset) begin
                S_reserve_meta<=0; S_reserve_sync<=0; S_retire_meta<=0; S_retire_sync<=0;
                S_grant<=0; S_stop<=0; S_video_ack<=0; S_video_fault<=0; S_video_state<=V_IDLE;
            end else begin
                S_reserve_meta<=S_reserve; S_reserve_sync<=S_reserve_meta;
                S_retire_meta<=S_retire; S_retire_sync<=S_retire_meta;
                if(S_grant && I_video_in_use[g]) S_video_fault<=1;
                if(!S_grant && S_reserve_sync && I_video_frame_start && !I_video_in_use[g] && !S_video_fault) S_grant<=1;
                if(S_grant && !S_reserve_sync && !S_retire_sync && S_video_state==V_IDLE) S_grant<=0;
                case(S_video_state)
                    V_IDLE:if(S_grant && S_retire_sync && !I_video_reader_ack[g] &&
                        !I_video_in_use[g] && !S_video_fault) begin S_stop<=1; S_video_state<=V_WAIT; end
                    V_WAIT:if(I_video_reader_ack[g] && I_video_owner_retired[g] && I_video_pipeline_retired[g] &&
                        !I_video_in_use[g] && !S_video_fault) begin S_video_ack<=1; S_video_state<=V_HELD; end
                    V_HELD:if(!S_retire_sync) begin S_stop<=0; S_video_state<=V_CLEAR; end
                    V_CLEAR:if(!I_video_reader_ack[g]) begin S_video_ack<=0; S_video_state<=V_IDLE; end
                    default:S_video_state<=V_IDLE;
                endcase
            end
        end
    end endgenerate
endmodule
