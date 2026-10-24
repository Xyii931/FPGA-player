// Fixed 640x480 scanout timing. Only actual frame_start establishes the time anchor.
// Multi-bit clocks/timestamps cross ONLY the internal real deadline CDC FIFOs.
module display_deadline_scheduler #(
    parameter integer PREP_MIN_LEAD=32000,
    parameter integer SCAN_MIN_LEAD=64,
    parameter integer USE_TARGET=0,
    parameter integer PREPARE_IN_VBLANK=0
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_clock_enable,I_video_abort,I_frame_start,
    input wire I_target_valid,
    input wire [31:0] I_target_epoch,I_target_time,
    input wire [15:0] I_target_tag,
    input wire I_pending_valid,
    input wire [246:0] I_pending_config,
    input wire [31:0] I_pending_epoch,
    input wire [15:0] I_pending_tag,
    input wire I_active_valid,
    input wire [31:0] I_active_epoch,
    input wire [15:0] I_active_tag,
    input wire [8:0] I_prefetch_y,
    output wire O_prepare_deadline_valid,
    output wire [31:0] O_prepare_deadline_epoch,
    output wire [63:0] O_prepare_deadlines,
    output wire O_scan_deadline_valid,
    output wire [8:0] O_scan_deadline_y,
    output wire [31:0] O_scan_deadline_epoch,O_scan_deadline,
    output wire O_allow_apply,
    output wire [31:0] O_prepare_target,
    output wire [31:0] O_host_time,O_video_time,
    output wire O_host_quarantined,
    output reg O_contract_fault,O_quarantined,O_response_discarded,
    output wire O_busy
);
    localparam [1:0] IDLE=0,OFFER=1,WAIT_RESULT=2;
    localparam [31:0] FRAME_CYCLES=420000;
    reg [1:0] S_state;
    reg S_anchored,S_prefer,S_kind,S_prepare_cached,S_scan_cached,S_prepare_expired,S_prepare_missed;
    reg [31:0] S_frame_origin,S_epoch,S_target,S_origin;
    reg [31:0] S_requested_target,S_prepare_requested_target;
    reg [15:0] S_tag;
    reg [8:0] S_row;
    reg [246:0] S_config;
    reg [246:0] S_prepare_config;
    reg [31:0] S_prepare_epoch,S_prepare_target,S_prepare_deadline,S_prepare_until;
    reg [15:0] S_prepare_tag;
    reg [31:0] S_scan_epoch,S_scan_origin,S_scan_deadline,S_scan_until;
    reg [15:0] S_scan_tag;
    reg [8:0] S_scan_row;
    wire S_reset;
    wire S_d_ready,S_d_done,S_d_kind,S_d_usable,S_d_video_fault,S_d_discard;
    wire [3:0] S_d_error;
    wire [31:0] S_d_epoch,S_d_sequence,S_d_target,S_d_deadline,S_d_until;
    wire [15:0] S_d_tag;
    wire [8:0] S_d_row;
    wire S_enabled=I_clock_enable && !O_quarantined;
    wire S_frame_live=S_anchored && S_enabled;
    wire [31:0] S_live_origin=I_frame_start ? O_video_time : S_frame_origin;
    wire [31:0] S_frame_age=O_video_time-S_frame_origin;
    wire [31:0] S_next_frame=S_live_origin+FRAME_CYCLES;
    wire [31:0] S_next_lead=S_next_frame-O_video_time;
    // Reused-source event commands enter during blanking, after the final old row.
    wire [31:0] S_required_lead=(PREPARE_IN_VBLANK && USE_TARGET && I_active_valid) ? 32'd2048 : PREP_MIN_LEAD;
    wire [31:0] S_prepare_choice=S_next_lead>=S_required_lead ? S_next_frame : S_next_frame+FRAME_CYCLES;
    wire S_target_identity_ok=I_target_valid && I_target_epoch==I_pending_epoch && I_target_tag==I_pending_tag;
    wire [31:0] S_target_from_origin=I_target_time-S_live_origin;
    wire [31:0] S_origin_from_target=S_live_origin-I_target_time;
    wire S_target_grid_ok=S_target_from_origin!=32'h80000000 &&
        (S_target_from_origin[31] ? S_origin_from_target%FRAME_CYCLES==0 : S_target_from_origin%FRAME_CYCLES==0);
    wire [31:0] S_choice_from_origin=S_prepare_choice-S_live_origin;
    wire [31:0] S_selected_target=(USE_TARGET && !S_target_from_origin[31] &&
        S_target_from_origin>=S_choice_from_origin) ? I_target_time : S_prepare_choice;
    wire [31:0] S_selected_lead=S_selected_target-O_video_time;
    // Wait for far targets to enter the real bridge's supported conversion horizon.
    wire S_target_available=!USE_TARGET || (S_target_identity_ok && S_target_grid_ok &&
        S_selected_lead>=S_required_lead && !S_selected_lead[31] && S_selected_lead<=32'd1048576);
    wire [31:0] S_scan_target=S_live_origin+(32'd35+I_prefetch_y)*32'd800;
    wire [31:0] S_scan_lead=S_scan_target-O_video_time;
    wire [31:0] S_prepare_left=S_prepare_target-O_video_time;
    wire [31:0] S_prepare_fresh=S_prepare_until-O_video_time;
    wire [31:0] S_scan_fresh=S_scan_until-O_video_time;
    wire S_prepare_match=S_prepare_cached && I_pending_valid && S_prepare_config==I_pending_config &&
        S_prepare_epoch==I_pending_epoch && S_prepare_tag==I_pending_tag &&
        (!USE_TARGET || (S_target_identity_ok && S_prepare_requested_target==I_target_time));
    wire S_scan_match=S_scan_cached && I_active_valid && S_scan_epoch==I_active_epoch &&
        S_scan_tag==I_active_tag && S_scan_row==I_prefetch_y && S_scan_origin==S_live_origin;
    wire S_prepare_identity_ok=I_pending_epoch!=0 && I_pending_config[246:245]!=0;
    wire S_want_prepare=S_frame_live && !I_video_abort && I_pending_valid && S_prepare_identity_ok && S_target_available &&
        (!S_prepare_match || S_prepare_missed || S_prepare_left[31]);
    wire S_want_scan=S_frame_live && I_active_valid && I_active_epoch!=0 && I_prefetch_y<480 &&
        S_scan_lead>=SCAN_MIN_LEAD && !S_scan_lead[31] &&
        (!S_scan_match || S_scan_fresh==0 || S_scan_fresh[31]);
    wire S_choose_scan=S_want_scan && (!S_want_prepare || S_prefer);
    wire S_offer_relevant=S_kind ?
        (I_active_valid && I_active_epoch==S_epoch && I_active_tag==S_tag && I_prefetch_y==S_row && S_origin==S_live_origin) :
        (I_pending_valid && I_pending_epoch==S_epoch && I_pending_tag==S_tag && I_pending_config==S_config &&
        (!USE_TARGET || (S_target_identity_ok && S_requested_target==I_target_time)));
    wire S_result_match=S_d_kind==S_kind && S_d_epoch==S_epoch && S_d_row==S_row &&
        S_d_tag==S_tag && S_d_target==S_target;
    // Convert early, but do not steal a ping-pong bank throughout the old visible frame.
    wire S_prepare_window=!PREPARE_IN_VBLANK || !I_active_valid ||
        (S_prepare_target==S_live_origin+FRAME_CYCLES && S_frame_age>=32'd412000 && !I_frame_start);
    reset_sync u_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_reset));
    display_deadline_cdc u_deadline (
        .I_host_clk(I_host_clk),.I_video_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_enable(I_clock_enable),.I_abort(!S_enabled || !S_offer_relevant || (!S_kind && I_video_abort)),
        .I_request_valid(!S_reset && S_state==OFFER),.O_request_ready(S_d_ready),
        .I_kind(S_kind),.I_epoch(S_epoch),.I_row(S_row),.I_tag(S_tag),.I_target_video_time(S_target),
        .O_busy(),.O_done_valid(S_d_done),.I_done_ready(S_state==WAIT_RESULT),.O_error(S_d_error),
        .O_kind(S_d_kind),.O_epoch(S_d_epoch),.O_row(S_d_row),.O_tag(S_d_tag),.O_sequence(S_d_sequence),
        .O_target_video_time(S_d_target),.O_deadline(S_d_deadline),.O_valid_until_video_time(S_d_until),
        .O_deadline_usable(S_d_usable),.O_video_quarantined(S_d_video_fault),.O_response_discarded(S_d_discard),
        .O_host_busy(),.O_host_quarantined(O_host_quarantined),.O_host_time(O_host_time),.O_video_time(O_video_time)
    );
    assign O_prepare_deadline_valid=!S_reset && S_frame_live && !I_video_abort && S_prepare_match && !S_prepare_expired && S_prepare_window &&
        S_prepare_fresh!=0 && !S_prepare_fresh[31];
    assign O_prepare_deadline_epoch=S_prepare_epoch;
    assign O_prepare_deadlines={S_prepare_deadline,S_prepare_deadline};
    assign O_scan_deadline_valid=!S_reset && S_frame_live && S_scan_match && S_scan_fresh!=0 && !S_scan_fresh[31];
    assign O_scan_deadline_y=S_scan_row;
    assign O_scan_deadline_epoch=S_scan_epoch;
    assign O_scan_deadline=S_scan_deadline;
    assign O_prepare_target=S_prepare_target;
    assign O_allow_apply=!S_reset && S_frame_live && !I_video_abort && S_prepare_match && !S_prepare_missed && I_frame_start &&
        O_video_time==S_prepare_target;
    assign O_busy=S_state!=IDLE || O_quarantined;
    always @(posedge I_video_clk or posedge S_reset) begin
        if(S_reset) begin
            S_state<=IDLE; S_anchored<=0; S_prefer<=0; S_kind<=0; S_frame_origin<=0;
            S_epoch<=0; S_target<=0; S_origin<=0; S_tag<=0; S_row<=0; S_config<=0;
            S_requested_target<=0; S_prepare_requested_target<=0;
            S_prepare_cached<=0; S_prepare_config<=0; S_prepare_epoch<=0; S_prepare_tag<=0;
            S_prepare_expired<=0; S_prepare_missed<=0;
            S_prepare_target<=0; S_prepare_deadline<=0; S_prepare_until<=0;
            S_scan_cached<=0; S_scan_epoch<=0; S_scan_tag<=0; S_scan_row<=0; S_scan_origin<=0;
            S_scan_deadline<=0; S_scan_until<=0; O_contract_fault<=0; O_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=S_d_discard;
            if(!S_enabled) begin S_anchored<=0; S_prepare_cached<=0; S_scan_cached<=0; end
            else if(I_frame_start) begin S_anchored<=1; S_frame_origin<=O_video_time; end
            if(I_video_abort) S_prepare_cached<=0;
            if(S_prepare_cached && (S_prepare_fresh==0 || S_prepare_fresh[31])) S_prepare_expired<=1;
            if(S_prepare_cached && S_prepare_left[31]) S_prepare_missed<=1;
            if(!I_pending_valid || (S_prepare_cached && !S_prepare_match)) S_prepare_cached<=0;
            if(S_scan_cached && (!S_scan_match || S_scan_fresh==0 || S_scan_fresh[31])) S_scan_cached<=0;
            if(S_d_video_fault || (I_pending_valid && !S_prepare_identity_ok) ||
                (USE_TARGET && S_frame_live && I_pending_valid && S_target_identity_ok && !S_target_grid_ok) ||
                (S_anchored && S_enabled && ((I_frame_start && S_frame_age!=FRAME_CYCLES) ||
                (!I_frame_start && S_frame_age>=FRAME_CYCLES)))) begin
                O_contract_fault<=1; O_quarantined<=1;
            end
            case(S_state)
                IDLE:if(!O_quarantined && (S_want_prepare || S_want_scan)) begin
                    S_kind<=S_choose_scan; S_epoch<=S_choose_scan ? I_active_epoch : I_pending_epoch;
                    S_tag<=S_choose_scan ? I_active_tag : I_pending_tag;
                    S_row<=S_choose_scan ? I_prefetch_y : 9'd0;
                    S_target<=S_choose_scan ? S_scan_target : S_selected_target;
                    S_requested_target<=I_target_time;
                    S_origin<=S_live_origin; S_config<=I_pending_config;
                    S_prefer<=!S_choose_scan; S_state<=OFFER;
                end
                OFFER:if(S_d_ready) S_state<=WAIT_RESULT;
                WAIT_RESULT:if(S_d_done) begin
                    if(!S_result_match) O_response_discarded<=1;
                    else begin
                        S_state<=IDLE;
                        if(S_d_error==1 || S_d_error==3 || S_d_error>=5) begin
                            O_contract_fault<=1; O_quarantined<=1;
                        end else if(S_d_error==0 && S_d_usable && S_frame_live && S_offer_relevant &&
                            (S_kind || !I_video_abort)) begin
                            if(S_kind) begin
                                S_scan_cached<=1; S_scan_epoch<=S_epoch; S_scan_tag<=S_tag; S_scan_row<=S_row;
                                S_scan_origin<=S_origin; S_scan_deadline<=S_d_deadline; S_scan_until<=S_d_until;
                            end else begin
                                S_prepare_cached<=1; S_prepare_config<=S_config; S_prepare_epoch<=S_epoch; S_prepare_tag<=S_tag;
                                S_prepare_requested_target<=S_requested_target;
                                S_prepare_expired<=0; S_prepare_missed<=0;
                                S_prepare_target<=S_target; S_prepare_deadline<=S_d_deadline; S_prepare_until<=S_d_until;
                            end
                        end
                    end
                end
                default:begin O_contract_fault<=1; O_quarantined<=1; S_state<=IDLE; end
            endcase
        end
    end
    // synthesis translate_off
    initial begin
        if(PREP_MIN_LEAD<64 || PREP_MIN_LEAD>420000 || SCAN_MIN_LEAD<32 || SCAN_MIN_LEAD>800 ||
            (USE_TARGET!=0 && USE_TARGET!=1) || (PREPARE_IN_VBLANK!=0 && PREPARE_IN_VBLANK!=1)) begin
            $display("FAIL: display_deadline_scheduler invalid lead parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
