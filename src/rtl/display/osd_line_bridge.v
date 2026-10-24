// Reliable line tasks and frame-boundary text publication. No pixel backpressure.
// RAM port A 100 MHz writes complete offscreen rows; port B 25 MHz scans them.
module osd_line_bridge (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_publish_valid,I_publish_bank,
    output wire O_publish_ready,O_publish_done_valid,O_publish_done_bank,O_old_retired,
    input wire I_publish_done_ready,
    output wire O_render_start_valid,
    input wire I_render_start_ready,
    output wire O_render_bank,
    output wire [8:0] O_render_y,
    input wire I_render_done_valid,
    output wire O_render_done_ready,
    input wire I_write_valid,I_write_clear,I_write_layer,
    output wire O_write_ready,
    input wire [9:0] I_write_x,
    input wire [1:0] I_write_color,
    input wire I_write_ink,
    input wire I_frame_start,I_valid,I_de,
    input wire [15:0] I_x,I_y,
    input wire [23:0] I_rgb,
    output reg O_valid,O_de,
    output reg [15:0] O_x,O_y,
    output wire [23:0] O_rgb,
    output reg [31:0] O_line_misses
);
    wire S_host_reset,S_video_reset;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    localparam [1:0] H_IDLE=0,H_OFFER=1,H_RENDER=2;
    reg [1:0] S_host_state;
    reg S_line_request,S_line_ack,S_line_waiting,S_line_ready;
    reg S_request_text_bank,S_request_ram_bank;
    reg [8:0] S_request_y;
    reg S_host_text_bank,S_host_ram_bank;
    reg [8:0] S_host_y;
    (* async_reg="true" *) reg S_line_req_meta,S_line_req_sync,S_line_ack_meta,S_line_ack_sync;
    reg S_publish_request,S_publish_ack,S_publish_busy,S_publish_result;
    reg S_host_publish_bank,S_video_text_bank,S_video_text_valid;
    (* async_reg="true" *) reg S_pub_req_meta,S_pub_req_sync,S_pub_ack_meta,S_pub_ack_sync;
    reg S_scan_bank,S_scan_valid;
    reg S_previous_de,S_prefetch_zero;
    reg [8:0] S_previous_y;
    reg S_read_valid;
    reg [23:0] S_rgb;
    reg [2:0] S_low[0:1279],S_high[0:1279];
    reg [2:0] S_low_q,S_high_q;
    wire S_complete=S_line_waiting && S_line_ack_sync==S_line_request;
    wire S_available=S_line_ready || S_complete;
    wire S_line_start=I_de && I_x==0 && I_y<480;
    wire S_row_matches=S_available && S_video_text_valid && S_request_y==I_y[8:0] && S_request_text_bank==S_video_text_bank;
    wire S_read_bank=S_line_start && S_row_matches ? S_request_ram_bank : S_scan_bank;
    wire S_use_row=S_line_start ? S_row_matches : S_scan_valid;
    wire S_pending_publish=S_pub_req_sync!=S_publish_ack;
    wire S_idle_tasks=!S_line_waiting || S_complete;
    wire S_install=I_frame_start && S_pending_publish && S_idle_tasks && !S_read_valid;
    wire S_end_frame=S_previous_de && !I_de && S_previous_y==479;
    wire S_zero_request=S_prefetch_zero || S_end_frame;
    wire S_schedule=(I_de && I_x==0 && I_y<479) || S_zero_request;
    wire [8:0] S_next_y=S_zero_request ? 9'd0 : I_y[8:0]+9'd1;
    wire [10:0] S_write_address=(S_host_ram_bank ? 11'd640 : 11'd0)+{1'b0,I_write_x};
    wire [10:0] S_read_address=(S_read_bank ? 11'd640 : 11'd0)+{1'b0,I_x[9:0]};
    wire [2:0] S_top=S_high_q[2] ? S_high_q : S_low_q;
    function [23:0] ink_color;
        input [1:0] color;
        begin case(color) 0:ink_color=24'hffffff; 1:ink_color=24'h40c0ff;
            2:ink_color=24'hffff40; default:ink_color=24'hff4040; endcase end
    endfunction
    assign O_rgb=O_de ? (S_read_valid && S_top[2] ? ink_color(S_top[1:0]) : S_rgb) : 24'd0;
    assign O_publish_ready=!S_host_reset && !S_publish_busy && !S_publish_result;
    assign O_publish_done_valid=!S_host_reset && S_publish_result;
    assign O_publish_done_bank=S_host_publish_bank;
    assign O_old_retired=S_publish_result;
    assign O_render_start_valid=!S_host_reset && S_host_state==H_OFFER;
    assign O_render_bank=S_host_text_bank;
    assign O_render_y=S_host_y;
    assign O_render_done_ready=!S_host_reset && S_host_state==H_RENDER;
    assign O_write_ready=!S_host_reset && S_host_state==H_RENDER;
    always @(posedge I_host_clk) begin
        if(I_write_valid && O_write_ready && I_write_x<640) begin
            if(I_write_clear) begin S_low[S_write_address]<=0; S_high[S_write_address]<=0; end
            else if(I_write_ink) begin
                if(I_write_layer) S_high[S_write_address]<={1'b1,I_write_color};
                else S_low[S_write_address]<={1'b1,I_write_color};
            end
        end
    end
    always @(posedge I_video_clk) begin
        if(!S_video_reset && I_valid && I_de && I_x<640 && I_y<480 && S_use_row) begin
            S_low_q<=S_low[S_read_address]; S_high_q<=S_high[S_read_address];
        end
    end
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_host_state<=H_IDLE; S_line_req_meta<=0; S_line_req_sync<=0; S_line_ack<=0;
            S_host_text_bank<=0; S_host_ram_bank<=0; S_host_y<=0;
            S_publish_request<=0; S_publish_busy<=0; S_publish_result<=0; S_host_publish_bank<=0;
            S_pub_ack_meta<=0; S_pub_ack_sync<=0;
        end else begin
            S_line_req_meta<=S_line_request; S_line_req_sync<=S_line_req_meta;
            S_pub_ack_meta<=S_publish_ack; S_pub_ack_sync<=S_pub_ack_meta;
            if(I_publish_valid && O_publish_ready) begin
                S_host_publish_bank<=I_publish_bank; S_publish_request<=!S_publish_request; S_publish_busy<=1;
            end
            if(S_publish_busy && S_pub_ack_sync==S_publish_request) begin S_publish_busy<=0; S_publish_result<=1; end
            if(S_publish_result && I_publish_done_ready) S_publish_result<=0;
            case(S_host_state)
                H_IDLE:if(S_line_req_sync!=S_line_ack) begin
                    S_host_text_bank<=S_request_text_bank; S_host_ram_bank<=S_request_ram_bank; S_host_y<=S_request_y;
                    S_host_state<=H_OFFER;
                end
                H_OFFER:if(I_render_start_ready) S_host_state<=H_RENDER;
                H_RENDER:if(I_render_done_valid) begin S_line_ack<=S_line_req_sync; S_host_state<=H_IDLE; end
                default:S_host_state<=H_IDLE;
            endcase
        end
    end
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_line_request<=0; S_line_waiting<=0; S_line_ready<=0; S_request_text_bank<=0; S_request_ram_bank<=0; S_request_y<=0;
            S_line_ack_meta<=0; S_line_ack_sync<=0; S_pub_req_meta<=0; S_pub_req_sync<=0;
            S_publish_ack<=0; S_video_text_bank<=0; S_video_text_valid<=0; S_scan_bank<=0; S_scan_valid<=0;
            S_previous_de<=0; S_previous_y<=0; S_prefetch_zero<=0;
            S_read_valid<=0; S_rgb<=0; O_valid<=0; O_de<=0; O_x<=0; O_y<=0; O_line_misses<=0;
        end else begin
            S_line_ack_meta<=S_line_ack; S_line_ack_sync<=S_line_ack_meta;
            S_pub_req_meta<=S_publish_request; S_pub_req_sync<=S_pub_req_meta;
            O_valid<=I_valid; O_de<=I_de; O_x<=I_x; O_y<=I_y; S_rgb<=I_rgb;
            S_previous_de<=I_de;
            if(I_de) S_previous_y<=I_y[8:0];
            if(S_end_frame) S_prefetch_zero<=1;
            S_read_valid<=I_valid && I_de && I_x<640 && I_y<480 && S_use_row;
            if(S_complete) begin S_line_waiting<=0; S_line_ready<=1; end
            if(S_line_start) begin
                S_scan_valid<=S_row_matches;
                if(S_row_matches) S_scan_bank<=S_request_ram_bank;
                else if(S_video_text_valid) O_line_misses<=O_line_misses+1'b1;
                if(S_available) S_line_ready<=0;
            end
            if(!I_de) S_scan_valid<=0;
            if(S_install) begin
                S_video_text_bank<=S_host_publish_bank; S_video_text_valid<=1;
                S_publish_ack<=S_pub_req_sync; S_line_ready<=0; S_scan_valid<=0;
                S_read_valid<=0; S_prefetch_zero<=1;
            end else if(S_schedule && S_video_text_valid && !S_pending_publish && S_idle_tasks) begin
                // A row is owned from this offer through real renderer completion.
                S_request_text_bank<=S_video_text_bank; S_request_ram_bank<=!S_read_bank; S_request_y<=S_next_y;
                S_line_request<=!S_line_request; S_line_waiting<=1; S_line_ready<=0; S_prefetch_zero<=0;
            end
        end
    end
endmodule
