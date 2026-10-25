// Coalescing stable-payload mailbox; update visual state only in vertical blank.
// Common reset is mandatory. Source holds data until destination frame ack.
module video_ui_cdc #(
    parameter integer WIDTH=16,
    parameter integer HOLD_PAYLOAD=0,
    parameter integer MANUAL_CAPTURE=0
) (
    input wire I_host_clk,I_video_clk,I_async_reset,I_frame_start,
    input wire I_release,
    input wire I_capture_valid,I_publish_valid,I_discard_valid,
    output wire O_capture_ready,
    output wire [WIDTH-1:0] O_host_state,
    input wire [WIDTH-1:0] I_state,
    output wire [WIDTH-1:0] O_state,
    output wire O_state_valid
);
    wire S_host_reset,S_video_reset;
    reg [WIDTH-1:0] S_payload;
    reg S_request,S_ack,S_ack_meta,S_ack_sync,S_request_meta,S_request_sync;
    reg S_initialized;
    localparam integer COMPARE_BITS=64;
    localparam integer COMPARE_GROUPS=(WIDTH+COMPARE_BITS-1)/COMPARE_BITS;
    reg [COMPARE_GROUPS-1:0] S_changed;
    reg S_check;
    wire S_capture=S_request==S_ack_sync && !S_check && (MANUAL_CAPTURE==0 || I_capture_valid);
    assign O_capture_ready=!S_host_reset && !I_async_reset && S_request==S_ack_sync && !S_check;
    assign O_host_state=S_payload;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    genvar group_index;
    generate for(group_index=0;group_index<COMPARE_GROUPS;group_index=group_index+1) begin: g_compare
        localparam integer FIRST=group_index*COMPARE_BITS;
        localparam integer BITS=WIDTH-FIRST<COMPARE_BITS ? WIDTH-FIRST : COMPARE_BITS;
        always @(posedge I_host_clk or posedge S_host_reset) begin
            if(S_host_reset) S_changed[group_index]<=0;
            // Both operands precede the same edge that captures the new payload.
            else if(S_capture) S_changed[group_index]<=I_state[FIRST+:BITS]!=S_payload[FIRST+:BITS];
        end
    end endgenerate
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_payload<=0; S_request<=0; S_ack_meta<=0; S_ack_sync<=0; S_initialized<=0; S_check<=0;
        end
        else begin
            S_ack_meta<=S_ack; S_ack_sync<=S_ack_meta;
            if(S_request==S_ack_sync) begin
                if(!S_check) begin
                    if(MANUAL_CAPTURE==0 || I_capture_valid) begin S_payload<=I_state; S_check<=1; end
                end else if(MANUAL_CAPTURE==0 || I_publish_valid || I_discard_valid) begin
                    S_check<=0;
                    // A discarded capture is not a published comparison base.
                    if(MANUAL_CAPTURE!=0 && I_discard_valid) S_initialized<=0;
                    else if((HOLD_PAYLOAD!=0 && !S_initialized) || |S_changed) begin
                        S_request<=!S_request; S_initialized<=1;
                    end
                end
            end
        end
    end
    reg S_request_seen;
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_request_meta<=0; S_request_sync<=0; S_request_seen<=0;
        end else begin
            S_request_meta<=S_request; S_request_sync<=S_request_meta;
            S_request_seen<=S_request_sync;
        end
    end
    generate if(HOLD_PAYLOAD!=0) begin: g_hold
        reg S_valid;
        assign O_state=S_payload;
        assign O_state_valid=!S_video_reset && !I_async_reset && S_valid;
        always @(posedge I_video_clk or posedge S_video_reset) begin
            if(S_video_reset) begin S_valid<=0; S_ack<=0; end
            else if(S_valid) begin
                if(I_release) begin S_valid<=0; S_ack<=S_request_seen; end
            end else if(I_frame_start && S_request_seen!=S_ack) S_valid<=1;
        end
    end else begin: g_capture
        reg [WIDTH-1:0] S_state;
        assign O_state=S_state;
        assign O_state_valid=!S_video_reset && !I_async_reset;
        always @(posedge I_video_clk or posedge S_video_reset) begin
            if(S_video_reset) begin S_state<=0; S_ack<=0; end
            // Extra destination cycle after synchronized request before bus capture.
            else if(I_frame_start && S_request_seen!=S_ack) begin
                S_state<=S_payload; S_ack<=S_request_seen;
            end
        end
    end endgenerate
endmodule
