// Coalescing stable-payload mailbox; update visual state only in vertical blank.
// Common reset is mandatory. Source holds data until destination frame ack.
module video_ui_cdc #(
    parameter integer WIDTH=16
) (
    input wire I_host_clk,I_video_clk,I_async_reset,I_frame_start,
    input wire [WIDTH-1:0] I_state,
    output reg [WIDTH-1:0] O_state
);
    wire S_host_reset,S_video_reset;
    reg [WIDTH-1:0] S_payload;
    reg S_request,S_ack,S_ack_meta,S_ack_sync,S_request_meta,S_request_sync;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin S_payload<=0; S_request<=0; S_ack_meta<=0; S_ack_sync<=0; end
        else begin
            S_ack_meta<=S_ack; S_ack_sync<=S_ack_meta;
            if(S_request==S_ack_sync && S_payload!=I_state) begin
                S_payload<=I_state; S_request<=!S_request;
            end
        end
    end
    reg S_request_seen;
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_request_meta<=0; S_request_sync<=0; S_request_seen<=0; S_ack<=0; O_state<=0;
        end else begin
            S_request_meta<=S_request; S_request_sync<=S_request_meta;
            S_request_seen<=S_request_sync;
            // Extra destination cycle after synchronized request before bus capture.
            if(I_frame_start && S_request_seen!=S_ack) begin
                O_state<=S_payload; S_ack<=S_request_seen;
            end
        end
    end
endmodule
