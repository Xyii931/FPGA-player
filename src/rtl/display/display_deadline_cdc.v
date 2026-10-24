// Causal timestamp round trip; all multi-bit state crosses only the two FIFOs.
// Clock ratio/phase margin require continuous stable clocks and hardware validation.
// Global reset covers BOTH clocks, the resource chain and the host arbiter timebase.
module display_deadline_cdc #(
    parameter integer QUEUE_BITS=2,
    parameter integer HOST_CYCLES_PER_VIDEO=5,
    parameter integer MARGIN_CYCLES=16,
    parameter integer MIN_SLACK_CYCLES=32,
    parameter integer MAX_VIDEO_AHEAD=1048576
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_enable,I_abort,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire I_kind,
    input wire [31:0] I_epoch,
    input wire [8:0] I_row,
    input wire [15:0] I_tag,
    input wire [31:0] I_target_video_time,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output wire O_kind,
    output wire [31:0] O_epoch,
    output wire [8:0] O_row,
    output wire [15:0] O_tag,
    output wire [31:0] O_sequence,O_target_video_time,
    output reg [31:0] O_deadline,O_valid_until_video_time,
    output wire O_deadline_usable,
    output reg O_video_quarantined,O_response_discarded,
    output wire O_host_busy,
    output reg O_host_quarantined,
    output reg [31:0] O_host_time,O_video_time
);
    localparam [1:0] V_IDLE=0,V_SEND=1,V_WAIT=2,V_RESULT=3;
    localparam integer VIDEO_GUARD=(MARGIN_CYCLES+MIN_SLACK_CYCLES+2+HOST_CYCLES_PER_VIDEO-1)/HOST_CYCLES_PER_VIDEO;
    reg [1:0] S_video_state;
    reg [153:0] S_request;
    reg [189:0] S_echo;
    reg S_echo_valid,S_sequence_exhausted,S_cancel,S_overdue,S_expired;
    reg [31:0] S_next_sequence,S_host_sequence;
    wire S_host_reset,S_video_reset;
    wire S_request_write_ready,S_request_valid,S_request_ready;
    wire [153:0] S_request_data;
    wire S_echo_write_ready,S_echo_read_valid,S_echo_read_ready;
    wire [189:0] S_echo_data;
    wire [31:0] S_input_ahead=I_target_video_time-O_video_time;
    wire [31:0] S_elapsed=O_video_time-S_request[121:90];
    wire [31:0] S_remaining=S_request[89:58]-O_video_time;
    wire [63:0] S_scaled_remaining={32'd0,S_remaining}*HOST_CYCLES_PER_VIDEO;
    wire [31:0] S_expiry=S_request[89:58]-S_elapsed-VIDEO_GUARD;
    wire [31:0] S_expiry_ahead=S_expiry-O_video_time;
    wire [31:0] S_result_ahead=O_valid_until_video_time-O_video_time;
    wire S_echo_match=S_echo_data[153:0]==S_request;
    wire [3:0] S_echo_error=S_echo_data[189:186];
    wire [31:0] S_host_stamp=S_echo_data[185:154];
    wire S_host_sequence_ok=S_request_data[153:122]!=0 && !(&S_host_sequence) &&
        S_request_data[153:122]==S_host_sequence+1'b1;
    wire S_host_range_ok=S_request_data[56:25]!=0 && S_request_data[24:16]<480;
    wire S_result_time_ok=!S_overdue && !S_elapsed[31] && S_elapsed<=MAX_VIDEO_AHEAD &&
        S_remaining!=0 && !S_remaining[31] && S_remaining<=MAX_VIDEO_AHEAD &&
        S_scaled_remaining[63:31]==0 && S_scaled_remaining>MARGIN_CYCLES &&
        // Counter advances on this same edge; leave a usable interval AFTER publishing.
        S_expiry_ahead>1 && !S_expiry_ahead[31];
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    async_fifo #(.DATA_BITS(154),.ADDR_BITS(QUEUE_BITS)) u_requests (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_video_state==V_SEND),.O_write_ready(S_request_write_ready),.I_write_data(S_request),
        .O_write_full(),.O_write_level(),.O_read_valid(S_request_valid),.I_read_ready(S_request_ready),
        .O_read_data(S_request_data),.O_read_empty(),.O_read_level()
    );
    async_fifo #(.DATA_BITS(190),.ADDR_BITS(QUEUE_BITS)) u_echoes (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_echo_valid),.O_write_ready(S_echo_write_ready),.I_write_data(S_echo),
        .O_write_full(),.O_write_level(),.O_read_valid(S_echo_read_valid),.I_read_ready(S_echo_read_ready),
        .O_read_data(S_echo_data),.O_read_empty(),.O_read_level()
    );
    assign O_request_ready=!I_async_reset && !S_video_reset && I_enable &&
        S_video_state==V_IDLE && !O_video_quarantined;
    assign O_busy=S_video_state!=V_IDLE || O_video_quarantined;
    assign O_done_valid=!I_async_reset && !S_video_reset && S_video_state==V_RESULT;
    assign {O_sequence,O_target_video_time}={S_request[153:122],S_request[89:58]};
    assign {O_kind,O_epoch,O_row,O_tag}=S_request[57:0];
    assign O_deadline_usable=O_done_valid && O_error==0 && !O_video_quarantined &&
        I_enable && !I_abort && !S_cancel && !S_expired && S_result_ahead!=0 && !S_result_ahead[31];
    assign O_host_busy=S_echo_valid || S_request_valid || O_host_quarantined;
    assign S_request_ready=!I_async_reset && !S_host_reset && !S_echo_valid;
    assign S_echo_read_ready=!I_async_reset && !S_video_reset && S_video_state==V_WAIT;
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            O_host_time<=0; S_host_sequence<=0; S_echo<=0; S_echo_valid<=0; O_host_quarantined<=0;
        end else begin
            O_host_time<=O_host_time+1'b1;
            if(S_echo_valid && S_echo_write_ready) S_echo_valid<=0;
            if(S_request_valid && S_request_ready) begin
                // This is the real host receipt edge; no video timestamp is sampled here.
                S_echo<={4'd0,O_host_time,S_request_data}; S_echo_valid<=1;
                if(O_host_quarantined || !S_host_sequence_ok || !S_host_range_ok) begin
                    S_echo<={4'd5,O_host_time,S_request_data}; O_host_quarantined<=1;
                end else S_host_sequence<=S_request_data[153:122];
            end
        end
    end
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            O_video_time<=0; S_video_state<=V_IDLE; S_request<=0; S_next_sequence<=1;
            S_sequence_exhausted<=0; S_cancel<=0; S_overdue<=0; S_expired<=0;
            O_error<=0; O_deadline<=0; O_valid_until_video_time<=0;
            O_video_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_video_time<=O_video_time+1'b1;
            O_response_discarded<=S_echo_read_valid && S_echo_read_ready && !S_echo_match;
            if(S_video_state!=V_IDLE && (I_abort || !I_enable)) S_cancel<=1;
            if((S_video_state==V_SEND || S_video_state==V_WAIT) &&
                (S_elapsed[31] || S_elapsed>MAX_VIDEO_AHEAD)) S_overdue<=1;
            if(S_video_state==V_RESULT && (S_result_ahead==0 || S_result_ahead[31])) S_expired<=1;
            case(S_video_state)
                V_IDLE:if(I_request_valid && O_request_ready) begin
                    S_request<={32'd0,O_video_time,I_target_video_time,I_kind,I_epoch,I_row,I_tag};
                    S_cancel<=I_abort; S_overdue<=0; S_expired<=0;
                    O_error<=0; O_deadline<=0; O_valid_until_video_time<=0;
                    if(S_sequence_exhausted) begin O_error<=6; O_video_quarantined<=1; S_video_state<=V_RESULT; end
                    else if(I_abort) begin O_error<=4; S_video_state<=V_RESULT; end
                    else if(I_epoch==0 || I_row>=480) begin O_error<=1; S_video_state<=V_RESULT; end
                    else if(S_input_ahead==0 || S_input_ahead[31]) begin O_error<=2; S_video_state<=V_RESULT; end
                    else if(S_input_ahead>MAX_VIDEO_AHEAD) begin O_error<=3; S_video_state<=V_RESULT; end
                    else begin
                        S_request<={S_next_sequence,O_video_time,I_target_video_time,I_kind,I_epoch,I_row,I_tag};
                        if(&S_next_sequence) S_sequence_exhausted<=1;
                        else S_next_sequence<=S_next_sequence+1'b1;
                        S_video_state<=V_SEND;
                    end
                end
                V_SEND:if(S_request_write_ready) S_video_state<=V_WAIT;
                V_WAIT:if(S_echo_read_valid && S_echo_read_ready && S_echo_match) begin
                    if(S_echo_error!=0) begin
                        O_error<=S_echo_error==5 ? 4'd5 : 4'd6; O_video_quarantined<=1;
                    end else if(S_cancel || I_abort || !I_enable) O_error<=4;
                    else if(!S_result_time_ok) O_error<=2;
                    else begin
                        // Retain a PAST host anchor, then use remaining VIDEO time at this edge.
                        O_deadline<=S_host_stamp+S_scaled_remaining[31:0]-MARGIN_CYCLES;
                        O_valid_until_video_time<=S_expiry;
                    end
                    S_video_state<=V_RESULT;
                end
                V_RESULT:if(I_done_ready) S_video_state<=V_IDLE;
                default:begin O_error<=6; O_video_quarantined<=1; S_video_state<=V_RESULT; end
            endcase
        end
    end
    // synthesis translate_off
    initial begin
        if(QUEUE_BITS<2 || QUEUE_BITS>16 || HOST_CYCLES_PER_VIDEO<1 || HOST_CYCLES_PER_VIDEO>16 ||
            MARGIN_CYCLES<2 || MARGIN_CYCLES>1048576 || MIN_SLACK_CYCLES<1 || MIN_SLACK_CYCLES>1048576 ||
            MAX_VIDEO_AHEAD<1 || MAX_VIDEO_AHEAD>=134217728) begin
            $display("FAIL: display_deadline_cdc invalid ratio/range/queue parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
