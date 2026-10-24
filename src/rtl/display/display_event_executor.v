// One timeline frame in video, one actual resource transaction in host.
// The caller is the exclusive host-entry owner. All obligations share global reset.
module display_event_executor (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_clock_enable,
    input wire [31:0] I_video_time,
    input wire I_frame_start,I_active_valid,
    input wire I_event_valid,
    output wire O_event_ready,
    input wire [31:0] I_event_epoch,
    input wire [15:0] I_event_tag,I_event_index,
    input wire [2:0] I_event_effect,
    input wire [16:0] I_event_progress,
    input wire [31:0] I_event_target,
    input wire [246:0] I_config,
    input wire I_cancel,
    input wire [3:0] I_bank_busy,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [31:0] O_epoch,
    output reg [15:0] O_tag,O_index,
    output reg [3:0] O_error,O_backend_error,O_lease_error,O_slot_error,O_commit_error,O_prepare_error,O_retire_error,
    output reg O_applied,O_retired,
    output reg [31:0] O_apply_time,O_commit_epoch,
    output reg O_quarantined,O_response_discarded,
    output wire O_target_valid,
    output wire [31:0] O_target_epoch,O_target_time,
    output wire [15:0] O_target_tag,
    output wire O_video_abort,
    input wire I_pending_valid,
    input wire [246:0] I_pending_config,
    input wire [31:0] I_pending_epoch,
    input wire [15:0] I_pending_tag,
    input wire I_local_applied,
    input wire [246:0] I_active_config,
    input wire [31:0] I_active_epoch,
    input wire [15:0] I_active_tag,
    output wire O_host_start_valid,
    input wire I_host_start_ready,
    output wire [246:0] O_host_config,
    output wire [15:0] O_host_tag,
    output wire O_host_abort,
    input wire [31:0] I_host_next_epoch,
    input wire I_host_done_valid,
    output wire O_host_done_ready,
    input wire [31:0] I_host_epoch,
    input wire [15:0] I_host_tag,
    input wire [3:0] I_host_error,I_host_lease_error,I_host_slot_error,
    input wire [3:0] I_host_commit_error,I_host_prepare_error,I_host_retire_error,
    input wire I_host_applied,I_host_retired,I_host_quarantined,
    output reg O_host_quarantined,O_host_response_discarded
);
    localparam [2:0] V_IDLE=0,V_BANK=1,V_SEND=2,V_WAIT=3,V_RESULT=4,V_CLEAR=5;
    localparam [2:0] H_IDLE=0,H_OFFER=1,H_WAIT=2,H_RETURN=3,H_CLEAR=4;
    reg [2:0] S_vstate,S_hstate;
    reg [31:0] S_sequence,S_target,S_mapping;
    reg [246:0] S_config;
    reg [374:0] S_request,S_host_request;
    reg [433:0] S_host_result;
    reg [31:0] S_expected_epoch;
    reg S_cancel,S_inflight,S_host_available;
    reg S_anchored;
    reg [31:0] S_frame_origin;
    (* ASYNC_REG="TRUE" *) reg S_cancel_meta,S_cancel_sync,S_inflight_meta,S_inflight_sync;
    (* ASYNC_REG="TRUE" *) reg S_available_meta,S_available_sync,S_fault_meta,S_fault_sync;
    wire S_vreset,S_hreset;
    wire S_request_wready,S_request_valid,S_request_ready;
    wire [374:0] S_request_data;
    wire S_result_wready,S_result_valid,S_result_ready;
    wire [433:0] S_result_data;
    wire S_active=S_vstate==V_BANK || S_vstate==V_SEND || S_vstate==V_WAIT;
    wire S_cancel_now=S_cancel || I_cancel || !I_clock_enable || O_quarantined;
    wire [1:0] S_mask=S_config[246:245];
    wire S_banks_free=(!S_mask[0] || I_bank_busy[1:0]!=3) && (!S_mask[1] || I_bank_busy[3:2]!=3);
    wire [31:0] S_frame_age=I_video_time-S_frame_origin;
    wire [31:0] S_target_ahead=S_target-I_video_time;
    wire S_bank_window=!I_active_valid || (S_anchored && !I_frame_start && S_frame_age>=32'd412032 &&
        S_frame_age<32'd415904 && (S_target_ahead[31] || S_target_ahead<=32'd8000));
    wire [1:0] S_banks={I_bank_busy[2],I_bank_busy[0]};
    wire S_pending_match=I_pending_valid && I_pending_epoch!=0 && I_pending_tag==O_tag && I_pending_config==S_config;
    wire S_local_match=I_active_epoch!=0 && I_active_epoch==S_mapping && I_active_tag==O_tag && I_active_config==S_config;
    wire [31:0] S_local_time=I_video_time-1'b1;
    wire [31:0] S_local_delta=S_local_time-S_target;
    wire S_local_time_ok=!S_local_delta[31] && S_local_delta%32'd420000==0;
    wire S_local_fact=S_active && I_local_applied && S_local_match && S_local_time_ok;
    wire S_local_fault=S_active && I_local_applied && (!S_local_fact || O_applied);
    wire S_mapping_fault=S_active && S_pending_match && S_mapping!=0 && S_mapping!=I_pending_epoch;
    wire S_have_apply=O_applied || S_local_fact;
    wire S_result_match=S_result_data[433:59]==S_request;
    wire [31:0] S_result_epoch=S_result_data[58:27];
    wire [3:0] S_result_error=S_result_data[26:23];
    wire S_result_applied=S_result_data[2],S_result_retired=S_result_data[1],S_result_fault=S_result_data[0];
    wire S_result_contract=S_result_applied!=S_have_apply ||
        (S_result_applied && (S_mapping==0 || S_result_epoch!=S_mapping)) ||
        (S_result_error==0 && (!S_result_applied || !S_result_retired || S_result_epoch==0));
    wire S_host_identity_ok=I_host_tag==S_host_request[310:295] &&
        (I_host_epoch==S_expected_epoch || (!I_host_applied && I_host_error!=0 && I_host_epoch==0));
    wire S_host_contract=(I_host_error==0 && (!I_host_applied || !I_host_retired || I_host_epoch==0)) ||
        (I_host_applied && (I_host_epoch==0 || !I_host_retired || I_host_error!=0));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_vreset));
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_hreset));
    async_fifo #(.DATA_BITS(375),.ADDR_BITS(2)) u_requests (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_vstate==V_SEND),.O_write_ready(S_request_wready),.I_write_data(S_request),
        .O_write_full(),.O_write_level(),.O_read_valid(S_request_valid),.I_read_ready(S_request_ready),
        .O_read_data(S_request_data),.O_read_empty(),.O_read_level()
    );
    async_fifo #(.DATA_BITS(434),.ADDR_BITS(2)) u_results (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_hstate==H_RETURN),.O_write_ready(S_result_wready),.I_write_data(S_host_result),
        .O_write_full(),.O_write_level(),.O_read_valid(S_result_valid),.I_read_ready(S_result_ready),
        .O_read_data(S_result_data),.O_read_empty(),.O_read_level()
    );
    assign O_event_ready=!I_async_reset && !S_vreset && S_vstate==V_IDLE && S_available_sync && !O_quarantined && !S_fault_sync;
    assign O_busy=S_vstate!=V_IDLE || O_quarantined || S_fault_sync;
    assign O_done_valid=!S_vreset && S_vstate==V_RESULT;
    assign O_target_valid=!S_vreset && S_active && S_pending_match && !S_cancel_now &&
        (S_mapping==0 || S_mapping==I_pending_epoch);
    assign O_target_epoch=I_pending_epoch;
    assign O_target_tag=O_tag;
    assign O_target_time=S_target;
    assign O_video_abort=!S_vreset && (O_quarantined || (S_active && S_cancel_now));
    assign S_result_ready=!S_vreset && S_vstate==V_WAIT;
    assign S_request_ready=!S_hreset && S_hstate==H_IDLE && S_inflight_sync && !O_host_quarantined;
    assign O_host_start_valid=!S_hreset && S_hstate==H_OFFER;
    assign O_host_config=S_host_request[278:32];
    assign O_host_tag=S_host_request[310:295];
    assign O_host_abort=!S_hreset && (S_hstate==H_OFFER || S_hstate==H_WAIT) && (S_cancel_sync || O_host_quarantined);
    assign O_host_done_ready=!S_hreset && S_hstate==H_WAIT;
    always @(posedge I_host_clk or posedge S_hreset) begin
        if(S_hreset) begin
            S_hstate<=H_IDLE; S_host_request<=0; S_host_result<=0; S_expected_epoch<=0; S_host_available<=1;
            S_cancel_meta<=0; S_cancel_sync<=0; S_inflight_meta<=0; S_inflight_sync<=0;
            O_host_quarantined<=0; O_host_response_discarded<=0;
        end else begin
            S_cancel_meta<=S_cancel; S_cancel_sync<=S_cancel_meta;
            S_inflight_meta<=S_inflight; S_inflight_sync<=S_inflight_meta;
            O_host_response_discarded<=0;
            case(S_hstate)
                H_IDLE:if(S_request_valid && S_request_ready) begin
                    S_host_request<=S_request_data; S_host_available<=0; S_hstate<=H_OFFER;
                end
                H_OFFER:if(I_host_start_ready) begin S_expected_epoch<=I_host_next_epoch; S_hstate<=H_WAIT; end
                H_WAIT:if(I_host_done_valid) begin
                    if(!S_host_identity_ok) O_host_response_discarded<=1;
                    else begin
                        S_host_result<={S_host_request,I_host_epoch,I_host_error,I_host_lease_error,I_host_slot_error,
                            I_host_commit_error,I_host_prepare_error,I_host_retire_error,I_host_applied,I_host_retired,
                            (I_host_quarantined || S_host_contract)};
                        if(I_host_quarantined || S_host_contract) O_host_quarantined<=1;
                        S_hstate<=H_RETURN;
                    end
                end
                H_RETURN:if(S_result_wready) S_hstate<=H_CLEAR;
                H_CLEAR:if(!S_inflight_sync && !S_cancel_sync && I_host_start_ready && !O_host_quarantined) begin
                    S_host_available<=1; S_hstate<=H_IDLE;
                end
                default:begin O_host_quarantined<=1; S_host_available<=0; end
            endcase
        end
    end
    always @(posedge I_video_clk or posedge S_vreset) begin
        if(S_vreset) begin
            S_vstate<=V_IDLE; S_sequence<=0; S_target<=0; S_mapping<=0; S_config<=0; S_request<=0;
            S_cancel<=0; S_inflight<=0; S_available_meta<=0; S_available_sync<=0; S_fault_meta<=0; S_fault_sync<=0;
            S_anchored<=0; S_frame_origin<=0;
            O_epoch<=0; O_tag<=0; O_index<=0; O_error<=0; O_backend_error<=0; O_lease_error<=0; O_slot_error<=0;
            O_commit_error<=0; O_prepare_error<=0; O_retire_error<=0; O_applied<=0; O_retired<=0;
            O_apply_time<=0; O_commit_epoch<=0; O_quarantined<=0; O_response_discarded<=0;
        end else begin
            S_available_meta<=S_host_available; S_available_sync<=S_available_meta;
            S_fault_meta<=O_host_quarantined; S_fault_sync<=S_fault_meta;
            O_response_discarded<=0;
            if(!I_clock_enable) S_anchored<=0;
            else if(I_frame_start) begin S_anchored<=1; S_frame_origin<=I_video_time; end
            if(S_active && S_cancel_now) begin
                S_cancel<=1;
                if(O_error==0) O_error<=I_clock_enable ? 4'd3 : 4'd4;
            end
            if(S_active && S_pending_match) begin
                if(S_mapping==0) S_mapping<=I_pending_epoch;
                else if(S_mapping!=I_pending_epoch) begin O_quarantined<=1; O_error<=6; S_cancel<=1; end
            end
            if(S_active && I_local_applied) begin
                if(!S_local_fact || O_applied) begin O_quarantined<=1; O_error<=6; S_cancel<=1; end
                else begin O_applied<=1; O_apply_time<=S_local_time; O_commit_epoch<=I_active_epoch; end
            end
            case(S_vstate)
                V_IDLE:if(I_event_valid && O_event_ready) begin
                    O_epoch<=I_event_epoch; O_tag<=I_event_tag; O_index<=I_event_index;
                    O_error<=0; O_backend_error<=0; O_lease_error<=0; O_slot_error<=0; O_commit_error<=0; O_prepare_error<=0; O_retire_error<=0;
                    O_applied<=0; O_retired<=0; O_apply_time<=0; O_commit_epoch<=0;
                    S_mapping<=0; S_target<=I_event_target; S_config<=I_config; S_cancel<=I_cancel || !I_clock_enable;
                    S_config[107:105]<=I_event_effect; S_config[88:72]<=I_event_progress;
                    S_config[51:34]<=0; S_config[31:0]<={I_event_tag,I_event_tag};
                    if(I_event_epoch==0 || I_event_effect>6 || I_event_progress>65536 ||
                        I_config[246:245]==0 || !I_config[245+I_config[244]] || I_config[52] ||
                        (I_event_progress!=0 && I_config[246:245]!=3)) begin O_error<=1; S_vstate<=V_RESULT; end
                    else if(&S_sequence) begin O_error<=7; O_quarantined<=1; S_vstate<=V_RESULT; end
                    else begin S_sequence<=S_sequence+1'b1; S_vstate<=V_BANK; end
                end
                V_BANK:if(S_cancel_now) begin
                    if(O_error==0) O_error<=I_clock_enable ? 4'd3 : 4'd4;
                    S_vstate<=V_RESULT;
                end else if(S_bank_window && S_banks_free) begin
                    S_config[33:32]<=S_banks;
                    S_request<={S_sequence,O_epoch,O_tag,O_index,S_config[246:34],S_banks,S_config[31:0],S_target};
                    S_inflight<=1; S_vstate<=V_SEND;
                end
                V_SEND:if(S_request_wready) S_vstate<=V_WAIT;
                V_WAIT:if(S_result_valid) begin
                    if(!S_result_match) O_response_discarded<=1;
                    else begin
                        O_backend_error<=S_result_error;
                        {O_lease_error,O_slot_error,O_commit_error,O_prepare_error,O_retire_error}<=S_result_data[22:3];
                        O_retired<=S_result_retired;
                        if(!S_have_apply) O_commit_epoch<=S_result_epoch;
                        if(S_result_contract || S_local_fault || S_mapping_fault || O_error==6 || O_quarantined) begin
                            O_error<=6; O_quarantined<=1; S_cancel<=1;
                        end
                        else if(S_cancel_now) O_error<=I_clock_enable ? 4'd3 : 4'd4;
                        else O_error<=S_result_error==0 ? 4'd0 : 4'd2;
                        if(S_result_fault) begin O_quarantined<=1; S_cancel<=1; end
                        S_vstate<=V_RESULT;
                    end
                end
                V_RESULT:if(I_done_ready) begin
                    S_cancel<=0; S_inflight<=0;
                    S_vstate<=S_inflight ? V_CLEAR : V_IDLE;
                end
                V_CLEAR:if(S_available_sync && !O_quarantined && !S_fault_sync) S_vstate<=V_IDLE;
                default:begin O_error<=6; O_quarantined<=1; S_cancel<=1; end
            endcase
        end
    end
endmodule
