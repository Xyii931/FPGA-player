// Atomic video-boundary configuration with real prepare/retire ownership.
// The resource owner, reader, downstream pipeline and both domains share global reset.
module frame_commit_cdc #(
    parameter integer CONFIG_BITS=247,
    parameter integer QUEUE_BITS=2,
    parameter integer EPOCH_BITS=32
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_submit_valid,
    output wire O_submit_ready,
    input wire [CONFIG_BITS-1:0] I_config,
    input wire [15:0] I_tag,
    input wire [3:0] I_validate_error,
    input wire I_abort,
    output wire [31:0] O_next_epoch,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,O_prepare_error,O_retire_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_epoch,O_previous_epoch,
    output reg O_applied,O_retired,O_quarantined,
    output reg O_host_response_discarded,
    output wire O_pending_valid,
    output reg [CONFIG_BITS-1:0] O_pending_config,
    output reg [15:0] O_pending_tag,
    output reg [31:0] O_pending_epoch,
    output wire O_prepare_valid,
    input wire I_prepare_ready,
    output wire O_prepare_abort,
    input wire I_prepare_done_valid,
    output wire O_prepare_done_ready,
    input wire [15:0] I_prepare_done_tag,
    input wire [31:0] I_prepare_done_epoch,
    input wire [3:0] I_prepare_done_error,
    input wire I_frame_start,I_allow_apply,I_video_abort,
    output reg O_active_valid,
    output reg [CONFIG_BITS-1:0] O_active_config,
    output reg [15:0] O_active_tag,
    output reg [31:0] O_active_epoch,
    output reg O_applied_pulse,
    output wire O_apply_valid,
    output wire O_retire_valid,
    input wire I_retire_ready,
    output reg [CONFIG_BITS-1:0] O_retire_config,
    output reg [15:0] O_retire_tag,
    output reg [31:0] O_retire_epoch,
    output reg O_retire_old,
    input wire I_retire_done_valid,
    output wire O_retire_done_ready,
    input wire [15:0] I_retire_done_tag,
    input wire [31:0] I_retire_done_epoch,
    input wire [3:0] I_retire_done_error,
    output wire O_video_quarantined,
    output reg O_video_response_discarded
);
    localparam integer REQUEST_BITS=CONFIG_BITS+48,RESULT_BITS=95;
    localparam [2:0] H_IDLE=0,H_SEND=1,H_WAIT=2,H_RESULT=3,H_CLEAR=4;
    localparam [3:0] V_IDLE=0,V_PREP=1,V_PREP_WAIT=2,V_FRAME=3,
        V_RETIRE=4,V_RETIRE_WAIT=5,V_ACK=6,V_CLEAR=7,V_QUARANTINE=8;
    wire S_host_reset,S_video_reset;
    reg [2:0] S_host_state;
    reg [3:0] S_video_state;
    reg [REQUEST_BITS-1:0] S_command;
    reg [EPOCH_BITS-1:0] S_next_epoch;
    reg S_epoch_exhausted,S_cancel,S_remote,S_seen_video_busy;
    reg S_host_inflight;
    reg S_video_quarantined,S_v_applied,S_v_retired;
    reg S_video_available;
    reg [3:0] S_error,S_prepare_error,S_retire_error;
    reg [31:0] S_previous_epoch;
    (* ASYNC_REG="TRUE" *) reg S_cancel_meta,S_cancel_sync,S_inflight_meta,S_inflight_sync;
    (* ASYNC_REG="TRUE" *) reg S_available_meta,S_available_sync;
    wire S_request_wready,S_request_valid,S_request_ready;
    wire [REQUEST_BITS-1:0] S_request_data;
    wire S_result_wready,S_result_valid,S_result_ready;
    wire [RESULT_BITS-1:0] S_result_data;
    wire [3:0] S_result_error,S_result_prepare_error,S_result_retire_error;
    wire S_result_applied,S_result_retired,S_result_quarantined;
    wire [15:0] S_result_tag;
    wire [31:0] S_result_epoch,S_result_previous_epoch;
    wire S_result_match=S_result_tag==O_tag && S_result_epoch==O_epoch;
    wire S_before_apply=S_video_state==V_PREP || S_video_state==V_PREP_WAIT || S_video_state==V_FRAME;
    wire [3:0] S_effective_error=I_video_abort || S_error==4 ? 4'd4 :
        S_cancel_sync || S_error==3 ? 4'd3 : S_error;
    wire [31:0] S_epoch_wide=S_next_epoch;
    wire S_prepare_fire=O_prepare_valid && I_prepare_ready;
    wire S_prepare_done=I_prepare_done_valid && O_prepare_done_ready &&
        I_prepare_done_epoch==O_pending_epoch && I_prepare_done_tag==O_pending_tag;
    wire S_retire_done=I_retire_done_valid && O_retire_done_ready &&
        (S_video_state==V_RETIRE_WAIT || (O_retire_valid && I_retire_ready)) &&
        I_retire_done_epoch==O_retire_epoch && I_retire_done_tag==O_retire_tag;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    async_fifo #(.DATA_BITS(REQUEST_BITS),.ADDR_BITS(QUEUE_BITS)) u_requests (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_host_state==H_SEND),.O_write_ready(S_request_wready),.I_write_data(S_command),
        .O_write_full(),.O_write_level(),.O_read_valid(S_request_valid),.I_read_ready(S_request_ready),
        .O_read_data(S_request_data),.O_read_empty(),.O_read_level()
    );
    async_fifo #(.DATA_BITS(RESULT_BITS),.ADDR_BITS(QUEUE_BITS)) u_results (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_video_state==V_ACK),.O_write_ready(S_result_wready),
        .I_write_data({S_error,S_prepare_error,S_retire_error,S_v_applied,S_v_retired,S_video_quarantined,
            O_pending_tag,O_pending_epoch,S_previous_epoch}),
        .O_write_full(),.O_write_level(),.O_read_valid(S_result_valid),.I_read_ready(S_result_ready),
        .O_read_data(S_result_data),.O_read_empty(),.O_read_level()
    );
    assign {S_result_error,S_result_prepare_error,S_result_retire_error,S_result_applied,S_result_retired,
        S_result_quarantined,S_result_tag,S_result_epoch,S_result_previous_epoch}=S_result_data;
    assign O_submit_ready=!I_async_reset && !S_host_reset && S_host_state==H_IDLE && !O_quarantined && S_available_sync;
    assign O_next_epoch=S_epoch_exhausted ? 32'd0 : S_next_epoch;
    assign O_busy=S_host_state!=H_IDLE || O_quarantined;
    assign O_done_valid=!I_async_reset && !S_host_reset && S_host_state==H_RESULT;
    assign S_request_ready=!I_async_reset && !S_video_reset && S_video_state==V_IDLE;
    assign S_result_ready=!I_async_reset && !S_host_reset && S_host_state==H_WAIT;
    assign O_pending_valid=!I_async_reset && !S_video_reset && S_before_apply;
    assign O_prepare_valid=O_pending_valid && S_video_state==V_PREP && S_effective_error==0;
    assign O_prepare_abort=S_video_state==V_PREP_WAIT && S_effective_error!=0;
    assign O_prepare_done_ready=!I_async_reset && !S_video_reset && S_video_state==V_PREP_WAIT;
    assign O_retire_valid=!I_async_reset && !S_video_reset && S_video_state==V_RETIRE;
    assign O_retire_done_ready=!I_async_reset && !S_video_reset &&
        (S_video_state==V_RETIRE || S_video_state==V_RETIRE_WAIT);
    assign O_video_quarantined=S_video_quarantined;
    assign O_apply_valid=!I_async_reset && !S_video_reset && S_video_state==V_FRAME &&
        S_effective_error==0 && I_frame_start && I_allow_apply;

    always @(posedge I_host_clk or posedge S_host_reset) begin
        if (S_host_reset) begin
            S_host_state<=H_IDLE; S_command<=0; S_next_epoch<=1; S_epoch_exhausted<=0;
            S_cancel<=0; S_remote<=0; S_seen_video_busy<=0; S_host_inflight<=0;
            S_available_meta<=0; S_available_sync<=0;
            O_error<=0; O_prepare_error<=0; O_retire_error<=0; O_tag<=0;
            O_epoch<=0; O_previous_epoch<=0; O_applied<=0; O_retired<=0; O_quarantined<=0;
            O_host_response_discarded<=0;
        end else begin
            S_available_meta<=S_video_available;
            S_available_sync<=S_available_meta;
            O_host_response_discarded<=S_result_valid && S_result_ready && !S_result_match;
            if (S_remote && !S_available_sync) S_seen_video_busy<=1;
            if ((S_host_state==H_SEND || S_host_state==H_WAIT) && I_abort) S_cancel<=1;
            case (S_host_state)
                H_IDLE:if (I_submit_valid && O_submit_ready) begin
                    O_tag<=I_tag; O_epoch<=0; O_previous_epoch<=0;
                    O_applied<=0; O_retired<=0; O_prepare_error<=0; O_retire_error<=0;
                    S_cancel<=0; S_remote<=0; S_seen_video_busy<=0; S_host_inflight<=0;
                    if (I_abort) begin O_error<=3; S_host_state<=H_RESULT; end
                    else if (I_validate_error!=0) begin O_error<=I_validate_error; S_host_state<=H_RESULT; end
                    else if (S_epoch_exhausted) begin O_error<=5; S_host_state<=H_RESULT; end
                    else begin
                        S_command<={I_tag,S_epoch_wide,I_config};
                        O_epoch<=S_next_epoch; O_error<=0; S_remote<=1; S_host_inflight<=1; S_host_state<=H_SEND;
                        if (&S_next_epoch) S_epoch_exhausted<=1;
                        else S_next_epoch<=S_next_epoch+1'b1;
                    end
                end
                H_SEND:if (S_request_wready) S_host_state<=H_WAIT;
                H_WAIT:if (S_result_valid && S_result_match) begin
                    O_error<=S_result_error; O_prepare_error<=S_result_prepare_error; O_retire_error<=S_result_retire_error;
                    O_applied<=S_result_applied; O_retired<=S_result_retired; O_quarantined<=S_result_quarantined;
                    O_previous_epoch<=S_result_previous_epoch; S_host_state<=H_RESULT;
                end
                H_RESULT:if (I_done_ready) begin
                    S_cancel<=0; S_host_inflight<=0;
                    S_host_state<=S_remote ? H_CLEAR : H_IDLE;
                end
                H_CLEAR:if (S_seen_video_busy && S_available_sync) begin S_remote<=0; S_host_state<=H_IDLE; end
                default:S_host_state<=H_IDLE;
            endcase
        end
    end

    always @(posedge I_video_clk or posedge S_video_reset) begin
        if (S_video_reset) begin
            S_video_state<=V_IDLE; S_cancel_meta<=0; S_cancel_sync<=0; S_inflight_meta<=0; S_inflight_sync<=0;
            S_video_available<=1;
            S_video_quarantined<=0; S_v_applied<=0; S_v_retired<=0;
            S_error<=0; S_prepare_error<=0; S_retire_error<=0; S_previous_epoch<=0;
            O_pending_config<=0; O_pending_tag<=0; O_pending_epoch<=0;
            O_active_valid<=0; O_active_config<=0; O_active_tag<=0; O_active_epoch<=0; O_applied_pulse<=0;
            O_retire_config<=0; O_retire_tag<=0; O_retire_epoch<=0; O_retire_old<=0;
            O_video_response_discarded<=0;
        end else begin
            S_cancel_meta<=S_cancel; S_cancel_sync<=S_cancel_meta;
            S_inflight_meta<=S_host_inflight; S_inflight_sync<=S_inflight_meta;
            O_applied_pulse<=0;
            O_video_response_discarded<=(I_prepare_done_valid && O_prepare_done_ready && !S_prepare_done) ||
                (I_retire_done_valid && O_retire_done_ready && !S_retire_done);
            if (S_before_apply) S_error<=S_effective_error;
            case (S_video_state)
                V_IDLE:if (S_request_valid && S_request_ready) begin
                    S_video_available<=0;
                    {O_pending_tag,O_pending_epoch,O_pending_config}<=S_request_data;
                    S_error<=0; S_prepare_error<=0; S_retire_error<=0;
                    S_v_applied<=0; S_v_retired<=0; S_previous_epoch<=0; S_video_state<=V_PREP;
                end
                V_PREP:if (S_effective_error!=0) begin
                    O_retire_config<=O_pending_config; O_retire_epoch<=O_pending_epoch;
                    O_retire_tag<=O_pending_tag; O_retire_old<=0; S_video_state<=V_RETIRE;
                end else if (S_prepare_fire) S_video_state<=V_PREP_WAIT;
                V_PREP_WAIT:if (S_prepare_done) begin
                    S_prepare_error<=I_prepare_done_error;
                    if (S_effective_error!=0 || I_prepare_done_error!=0) begin
                        if (S_effective_error==0) S_error<=2;
                        O_retire_config<=O_pending_config; O_retire_epoch<=O_pending_epoch;
                        O_retire_tag<=O_pending_tag; O_retire_old<=0; S_video_state<=V_RETIRE;
                    end else S_video_state<=V_FRAME;
                end
                V_FRAME:if (S_effective_error!=0) begin
                    O_retire_config<=O_pending_config; O_retire_epoch<=O_pending_epoch;
                    O_retire_tag<=O_pending_tag; O_retire_old<=0; S_video_state<=V_RETIRE;
                end else if (O_apply_valid) begin
                    O_active_valid<=1; O_active_config<=O_pending_config;
                    O_active_tag<=O_pending_tag; O_active_epoch<=O_pending_epoch; O_applied_pulse<=1;
                    S_v_applied<=1; S_previous_epoch<=O_active_epoch;
                    if (O_active_valid) begin
                        O_retire_config<=O_active_config; O_retire_epoch<=O_active_epoch;
                        O_retire_tag<=O_active_tag; O_retire_old<=1; S_video_state<=V_RETIRE;
                    end else begin S_v_retired<=1; S_video_state<=V_ACK; end
                end
                V_RETIRE:if (I_retire_ready) S_video_state<=V_RETIRE_WAIT;
                V_RETIRE_WAIT:begin end
                V_ACK:if (S_result_wready) S_video_state<=V_CLEAR;
                V_CLEAR:if (!S_inflight_sync && !S_cancel_sync) begin
                    S_video_state<=S_video_quarantined ? V_QUARANTINE : V_IDLE;
                    S_video_available<=!S_video_quarantined;
                end
                V_QUARANTINE:begin end
                default:S_video_state<=V_IDLE;
            endcase
            if (S_retire_done) begin
                S_retire_error<=I_retire_done_error;
                if (I_retire_done_error!=0) begin S_error<=6; S_video_quarantined<=1; end
                else S_v_retired<=1;
                S_video_state<=V_ACK;
            end
        end
    end
endmodule
