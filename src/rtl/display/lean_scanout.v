// Two frame buffers and one two-bank RGB line cache. No transition/lease engine.
// The video->host event queue orders line requests, releases and swap barriers.
// A swap ACK is emitted only after every earlier read has retired, so the old
// frame buffer cannot be reused while a queued old-frame request still owns it.
module lean_scanout (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_commit_valid,
    output wire O_commit_ready,
    input wire I_commit_slot,
    output wire O_commit_done,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [20:0] O_read_address,
    output wire [31:0] O_read_tag,
    input wire I_result_valid,
    output wire O_result_ready,
    input wire [31:0] I_result_data,I_result_tag,
    input wire [3:0] I_result_error,
    output reg O_de,O_valid,
    output reg [15:0] O_x,O_y,
    output wire [23:0] O_rgb,
    output wire O_frame_start,
    output reg O_fault,
    output reg [31:0] O_underflow_lines
);
    localparam integer EVENT_BITS=44;
    localparam [1:0] REQUEST=0,RELEASE=1,SWAP=2;
    localparam [1:0] H_IDLE=0,H_READ=1,H_DRAIN=2;
    wire S_hrst,S_vrst;
    reset_sync u_hrst(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_hrst));
    reset_sync u_vrst(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_vrst));
    wire S_de,S_frame,S_line;
    wire [15:0] S_x,S_y,S_rx,S_ry;
    video_timing u_timing (
        .I_clk(I_video_clk),.I_reset(S_vrst),.O_de(S_de),.O_x(S_x),.O_y(S_y),
        .O_frame_start(S_frame),.O_line_start(S_line),.O_raster_x(S_rx),.O_raster_y(S_ry),
        .O_hsync(), .O_vsync()
    );
    assign O_frame_start=S_frame;
    wire S_commit_wready,S_commit_valid,S_commit_take,S_commit_data;
    reg S_host_pending;
    wire S_event_wready,S_event_valid,S_event_take;
    wire [EVENT_BITS-1:0] S_event_data;
    wire S_reply_wready,S_reply_valid,S_reply_write;
    wire [EVENT_BITS-1:0] S_reply_data,S_reply_input;
    wire [1:0] S_event_kind=S_event_data[43:42];
    wire S_event_slot=S_event_data[41];
    wire [31:0] S_event_frame=S_event_data[40:9];
    wire [8:0] S_event_y=S_event_data[8:0];
    reg S_active,S_slot,S_video_fault;
    reg [31:0] S_frame_id;
    wire S_want_swap=S_frame && S_commit_valid && !S_video_fault;
    wire S_want_line=S_active && S_line && S_ry>=34 && S_ry<514 && !S_video_fault;
    wire S_want_release=S_active && S_rx==799 && S_ry>=35 && S_ry<515 && !S_video_fault;
    wire [8:0] S_requested_y=S_ry-16'd34;
    wire [8:0] S_release_y=S_ry-16'd35;
    wire [1:0] S_kind=S_want_swap ? SWAP : S_want_release ? RELEASE : REQUEST;
    wire [EVENT_BITS-1:0] S_event_input={S_kind,S_want_swap ? S_commit_data : S_slot,
        S_want_swap ? S_frame_id+32'd1 : S_frame_id,S_want_release ? S_release_y : S_requested_y};
    wire S_event_write=S_want_swap || S_want_line || S_want_release;
    assign S_commit_take=S_want_swap && S_event_wready;
    assign O_commit_ready=!S_hrst && !S_host_pending && S_commit_wready;
    async_fifo #(.DATA_BITS(1),.ADDR_BITS(2)) u_commits (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(I_commit_valid && O_commit_ready),.O_write_ready(S_commit_wready),.I_write_data(I_commit_slot),
        .O_read_valid(S_commit_valid),.I_read_ready(S_commit_take),.O_read_data(S_commit_data),
        .O_write_full(), .O_write_level(), .O_read_empty(), .O_read_level()
    );
    async_fifo #(.DATA_BITS(EVENT_BITS),.ADDR_BITS(3)) u_events (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_event_write),.O_write_ready(S_event_wready),.I_write_data(S_event_input),
        .O_read_valid(S_event_valid),.I_read_ready(S_event_take),.O_read_data(S_event_data),
        .O_write_full(), .O_write_level(), .O_read_empty(), .O_read_level()
    );
    async_fifo #(.DATA_BITS(EVENT_BITS),.ADDR_BITS(3)) u_replies (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_reply_write),.O_write_ready(S_reply_wready),.I_write_data(S_reply_input),
        .O_read_valid(S_reply_valid),.I_read_ready(1'b1),.O_read_data(S_reply_data),
        .O_write_full(), .O_write_level(), .O_read_empty(), .O_read_level()
    );
    wire S_barrier=S_event_valid && S_event_kind==SWAP;
    reg [1:0] S_host_state;
    reg S_job_slot;
    reg [31:0] S_job_frame;
    reg [8:0] S_job_y;
    reg [9:0] S_issue_x;
    reg [20:0] S_line_address;
    reg S_job_error;
    wire S_last_result=I_result_tag[9:0]==639;
    wire S_result_fire=I_result_valid && O_result_ready;
    wire S_line_reply=S_host_state!=H_IDLE && I_result_valid && S_last_result;
    assign S_event_take=!S_hrst && S_host_state==H_IDLE;
    assign O_read_valid=!S_hrst && S_host_state==H_READ;
    assign O_read_address=S_line_address+{11'd0,S_issue_x};
    assign O_read_tag={21'd0,S_job_y[0],S_issue_x};
    assign O_result_ready=!S_hrst && (!S_last_result || S_reply_wready);
    assign S_reply_write=S_line_reply && O_result_ready;
    // A failed line never publishes a matching row identity.
    assign S_reply_input={REQUEST,S_job_slot,S_job_frame,
        (S_job_error || I_result_error!=0) ? 9'd511 : S_job_y};
    assign O_commit_done=S_host_state==H_IDLE && S_barrier && S_event_take;
    always @(posedge I_host_clk or posedge S_hrst) begin
        if(S_hrst) begin
            S_host_state<=H_IDLE; S_host_pending<=0; S_job_slot<=0; S_job_frame<=0;
            S_job_y<=0; S_issue_x<=0; S_line_address<=0; S_job_error<=0;
        end else begin
            if(I_commit_valid && O_commit_ready) S_host_pending<=1;
            if(O_commit_done) S_host_pending<=0;
            if(S_result_fire && I_result_error!=0) S_job_error<=1;
            case(S_host_state)
                H_IDLE: if(S_event_valid && S_event_take && S_event_kind==REQUEST) begin
                    S_job_slot<=S_event_slot; S_job_frame<=S_event_frame; S_job_y<=S_event_y;
                    S_line_address<=(S_event_slot ? 21'd307200 : 21'd0)+
                        ({12'd0,S_event_y}<<9)+({12'd0,S_event_y}<<7);
                    S_issue_x<=0; S_job_error<=0; S_host_state<=H_READ;
                end
                H_READ:if(I_read_ready) begin
                    if(S_issue_x==639) S_host_state<=H_DRAIN;
                    else S_issue_x<=S_issue_x+1'b1;
                end
                H_DRAIN:if(S_result_fire && S_last_result) S_host_state<=H_IDLE;
                default:S_host_state<=H_IDLE;
            endcase
        end
    end
    (* ram_style="bram" *) reg [23:0] S_line0[0:639],S_line1[0:639];
    reg [23:0] S_line0_q,S_line1_q;
    always @(posedge I_host_clk) begin
        if(S_result_fire) begin
            if(I_result_tag[10]) S_line1[I_result_tag[9:0]]<=I_result_data[23:0];
            else S_line0[I_result_tag[9:0]]<=I_result_data[23:0];
        end
    end
    always @(posedge I_video_clk) if(S_de) begin
        S_line0_q<=S_line0[S_x[9:0]];
        S_line1_q<=S_line1[S_x[9:0]];
    end
    reg [31:0] S_bank_frame[0:1];
    reg [8:0] S_bank_y[0:1];
    reg [1:0] S_bank_valid,S_bank_slot;
    reg S_line_ok,S_pixel_ok,S_pixel_bank;
    wire S_match=S_active && S_bank_valid[S_y[0]] && S_bank_slot[S_y[0]]==S_slot &&
        S_bank_frame[S_y[0]]==S_frame_id && S_bank_y[S_y[0]]==S_y[8:0];
    wire S_current_ok=!S_video_fault && (S_x==0 ? S_match : S_line_ok);
    assign O_rgb=S_pixel_ok ? (S_pixel_bank ? S_line1_q : S_line0_q) : 24'd0;
    always @(posedge I_video_clk or posedge S_vrst) begin
        if(S_vrst) begin
            S_active<=0; S_slot<=0; S_frame_id<=0; S_video_fault<=0;
            S_bank_valid<=0; S_bank_slot<=0; S_bank_frame[0]<=0; S_bank_frame[1]<=0;
            S_bank_y[0]<=0; S_bank_y[1]<=0; S_line_ok<=0; S_pixel_ok<=0; S_pixel_bank<=0;
            O_de<=0; O_valid<=0; O_x<=0; O_y<=0; O_underflow_lines<=0;
        end else begin
            if(S_frame) S_frame_id<=S_frame_id+1'b1;
            if(S_commit_take) begin S_active<=1; S_slot<=S_commit_data; end
            if(S_event_write && !S_event_wready) S_video_fault<=1;
            if(S_reply_valid && S_reply_data[43:42]==REQUEST) begin
                S_bank_valid[S_reply_data[0]]<=1;
                S_bank_slot[S_reply_data[0]]<=S_reply_data[41];
                S_bank_frame[S_reply_data[0]]<=S_reply_data[40:9];
                S_bank_y[S_reply_data[0]]<=S_reply_data[8:0];
            end
            if(S_de && S_x==0) begin
                S_line_ok<=S_match;
                if(S_active && !S_match) O_underflow_lines<=O_underflow_lines+1'b1;
            end
            S_pixel_ok<=S_de && S_current_ok; S_pixel_bank<=S_y[0];
            O_de<=S_de; O_valid<=S_de; O_x<=S_x; O_y<=S_y;
        end
    end
    (* ASYNC_REG="TRUE" *) reg S_fault_meta;
    always @(posedge I_host_clk or posedge S_hrst) begin
        if(S_hrst) begin S_fault_meta<=0; O_fault<=0; end
        else begin S_fault_meta<=S_video_fault; O_fault<=S_fault_meta; end
    end
endmodule
