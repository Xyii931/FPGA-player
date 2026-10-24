// One source, two explicitly owned complete lines. No physical SDRAM timing model.
// A global shared reset must also retire/reset the external transaction owners.
module fb_line_reader #(
    parameter integer QUEUE_BITS=2,
    parameter integer PENDING_BITS=3,
    parameter integer MEM_TAG_BITS=32
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_lease_valid,
    input wire [2:0] I_lease_slot,
    input wire [31:0] I_lease_token,I_lease_generation,
    input wire I_task_valid,
    output wire O_task_ready,
    input wire [2:0] I_task_slot,
    input wire [20:0] I_task_base,
    input wire [8:0] I_task_y,
    input wire I_task_bank,
    input wire [31:0] I_task_token,I_task_generation,I_task_epoch,I_task_deadline,
    input wire [15:0] I_task_tag,
    output wire O_line_valid,
    input wire I_line_ready,
    output wire [3:0] O_line_error,O_line_memory_error,
    output wire [2:0] O_line_slot,
    output wire [20:0] O_line_base,
    output wire [8:0] O_line_y,
    output wire O_line_bank,
    output wire [31:0] O_line_token,O_line_generation,O_line_epoch,O_line_deadline,
    output wire [15:0] O_line_tag,
    output wire [9:0] O_line_accepted,O_line_retired,
    input wire I_read_valid,
    output wire O_read_ready,
    input wire I_read_bank,
    input wire [9:0] I_read_x,
    output reg O_pixel_valid,
    output reg [31:0] O_rgba,
    output reg O_pixel_bank,
    output reg [9:0] O_pixel_x,
    output reg [31:0] O_pixel_token,O_pixel_generation,O_pixel_epoch,
    output reg [15:0] O_pixel_tag,
    input wire I_release_valid,
    output wire O_release_ready,
    input wire I_release_bank,
    input wire [31:0] I_release_token,I_release_generation,I_release_epoch,
    input wire [15:0] I_release_tag,
    output wire [1:0] O_bank_valid,O_bank_reserved,
    output wire [5:0] O_bank_slots,
    output wire [17:0] O_bank_rows,
    output wire [63:0] O_bank_tokens,O_bank_generations,O_bank_epochs,
    output wire [31:0] O_bank_tags,
    input wire I_retire_request,
    output reg O_retire_ack,
    output wire O_host_retired,O_host_busy,O_host_tag_exhausted,
    output reg O_release_discarded,O_event_discarded,O_response_discarded,
    output wire O_mem_valid,
    input wire I_mem_ready,
    output reg [20:0] O_mem_addr,
    output reg [31:0] O_mem_tag,
    output wire [31:0] O_mem_token,O_mem_generation,O_mem_deadline,
    input wire I_mem_valid,
    output wire O_mem_ready,
    input wire [31:0] I_mem_data,I_mem_tag,I_mem_token,I_mem_generation,
    input wire [3:0] I_mem_error
);
    localparam integer DEPTH=1<<PENDING_BITS;
    // job = slot3/base21/y9/bank1/token32/generation32/epoch32/deadline32/tag16.
    localparam integer JOB_BITS=178,REQUEST_BITS=179,EVENT_BITS=207;
    localparam [1:0] IDLE=0,RUN=1,RESULT=2,WAIT_RELEASE=3;
    wire S_host_reset,S_video_reset;
    reg [1:0] S_state;
    reg [JOB_BITS-1:0] S_job;
    wire [2:0] S_slot;
    wire [20:0] S_base;
    wire [8:0] S_y;
    wire S_bank;
    wire [31:0] S_token,S_generation,S_epoch,S_deadline;
    wire [15:0] S_tag;
    assign {S_slot,S_base,S_y,S_bank,S_token,S_generation,S_epoch,S_deadline,S_tag}=S_job;
    reg [3:0] S_error,S_memory_error;
    reg [9:0] S_issue,S_accepted,S_retired;
    reg S_cmd_valid,S_event_barrier;
    reg [MEM_TAG_BITS-1:0] S_next_tag;
    reg S_tag_exhausted;
    reg [31:0] S_pending[0:DEPTH-1];
    reg [PENDING_BITS-1:0] S_head,S_tail;
    reg [PENDING_BITS:0] S_count;
    reg S_stopping,S_barrier_sent,S_barrier_seen;
    (* ASYNC_REG="TRUE" *) reg S_stop_meta,S_stop_sync;
    reg [1:0] S_reserved,S_bank_valid;
    reg [2:0] S_bank_slot[0:1];
    reg [8:0] S_bank_y[0:1];
    reg [31:0] S_bank_token[0:1],S_bank_generation[0:1],S_bank_epoch[0:1];
    reg [15:0] S_bank_tag[0:1];
    reg [31:0] S_line0[0:639],S_line1[0:639];
    wire S_request_wready,S_request_valid,S_request_ready;
    wire [REQUEST_BITS-1:0] S_request_data;
    wire S_event_wready,S_event_valid,S_event_ready;
    wire [EVENT_BITS-1:0] S_event_data;
    wire [JOB_BITS-1:0] S_event_job;
    wire S_event_is_barrier;
    wire [3:0] S_event_error,S_event_memory_error;
    wire [9:0] S_event_accepted,S_event_retired;
    wire S_active=S_state==RUN;
    wire S_lease_bad=!I_lease_valid || I_lease_slot!=S_slot || I_lease_token!=S_token ||
        I_lease_generation!=S_generation;
    wire S_mem_fire=O_mem_valid && I_mem_ready;
    wire S_identity=I_mem_token==S_token && I_mem_generation==S_generation;
    wire [31:0] S_expected_tag=S_count!=0 ? S_pending[S_head] : O_mem_tag;
    wire S_response=S_active && I_mem_valid && O_mem_ready && S_identity &&
        (S_count!=0 || S_mem_fire) && I_mem_tag==S_expected_tag;
    wire S_response_bad=S_active && I_mem_valid && O_mem_ready && S_identity && !S_response;
    wire [PENDING_BITS+1:0] S_reserved_count={1'b0,S_count}+(S_cmd_valid ? 1'b1 : 1'b0);
    wire S_room=S_reserved_count<DEPTH || S_response;
    reg [3:0] S_next_error;
    function [2:0] error_rank;
        input [3:0] code;
        begin case(code)
            2:error_rank=6; 5:error_rank=5; 3:error_rank=4;
            4:error_rank=3; 6:error_rank=2; 1:error_rank=1;
            default:error_rank=0;
        endcase end
    endfunction
    function [20:0] slot_base;
        input [2:0] slot;
        begin case(slot)
            0:slot_base=21'h000000; 1:slot_base=21'h04b000; 2:slot_base=21'h096000;
            3:slot_base=21'h0e1000; 4:slot_base=21'h12c000; 5:slot_base=21'h177000;
            default:slot_base=21'h1fffff;
        endcase end
    endfunction
    wire S_config_ok=S_slot<6 && S_base==slot_base(S_slot) && S_y<480 && S_token!=0;
    always @* begin
        S_next_error=S_error;
        if (!S_config_ok && error_rank(S_next_error)<1) S_next_error=1;
        if (S_tag_exhausted && S_issue<640 && error_rank(S_next_error)<2) S_next_error=6;
        if (S_response_bad && error_rank(S_next_error)<3) S_next_error=4;
        if (S_response && I_mem_error!=0 && error_rank(S_next_error)<4) S_next_error=3;
        if (S_stop_sync && error_rank(S_next_error)<5) S_next_error=5;
        if (S_config_ok && S_lease_bad) S_next_error=2;
    end
    wire S_prepare=S_active && S_next_error==0 && S_issue<640 &&
        (!S_cmd_valid || I_mem_ready) && S_room && !S_tag_exhausted;
    wire S_store=S_response && I_mem_error==0 && S_next_error==0;
    wire [JOB_BITS-1:0] S_task_job={I_task_slot,I_task_base,I_task_y,I_task_bank,
        I_task_token,I_task_generation,I_task_epoch,I_task_deadline,I_task_tag};
    wire S_enqueue_barrier=S_stopping && !S_barrier_sent;
    wire S_enqueue_task=!S_stopping && !I_retire_request && I_task_valid && !S_reserved[I_task_bank];
    wire S_task_fire=I_task_valid && O_task_ready;
    wire S_event_match=S_reserved[O_line_bank] && S_bank_slot[O_line_bank]==O_line_slot &&
        S_bank_y[O_line_bank]==O_line_y && S_bank_token[O_line_bank]==O_line_token &&
        S_bank_generation[O_line_bank]==O_line_generation && S_bank_epoch[O_line_bank]==O_line_epoch &&
        S_bank_tag[O_line_bank]==O_line_tag;
    wire S_line_fire=S_event_valid && S_event_ready && !S_event_is_barrier;
    wire S_release_match=S_bank_valid[I_release_bank] &&
        I_release_token==S_bank_token[I_release_bank] && I_release_generation==S_bank_generation[I_release_bank] &&
        I_release_epoch==S_bank_epoch[I_release_bank] && I_release_tag==S_bank_tag[I_release_bank];
    wire S_read_fire=I_read_valid && O_read_ready;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    async_fifo #(.DATA_BITS(REQUEST_BITS),.ADDR_BITS(QUEUE_BITS)) u_requests (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_enqueue_barrier || S_enqueue_task),.O_write_ready(S_request_wready),
        .I_write_data(S_enqueue_barrier ? {1'b1,{JOB_BITS{1'b0}}} : {1'b0,S_task_job}),
        .O_write_full(),.O_write_level(),.O_read_valid(S_request_valid),.I_read_ready(S_request_ready),
        .O_read_data(S_request_data),.O_read_empty(),.O_read_level()
    );
    async_fifo #(.DATA_BITS(EVENT_BITS),.ADDR_BITS(QUEUE_BITS)) u_events (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_state==RESULT),.O_write_ready(S_event_wready),
        .I_write_data({S_event_barrier,S_error,S_memory_error,S_accepted,S_retired,S_job}),
        .O_write_full(),.O_write_level(),.O_read_valid(S_event_valid),.I_read_ready(S_event_ready),
        .O_read_data(S_event_data),.O_read_empty(),.O_read_level()
    );
    assign S_request_ready=!I_async_reset && !S_host_reset && S_state==IDLE;
    assign {S_event_is_barrier,S_event_error,S_event_memory_error,S_event_accepted,S_event_retired,S_event_job}=S_event_data;
    assign {O_line_slot,O_line_base,O_line_y,O_line_bank,O_line_token,O_line_generation,
        O_line_epoch,O_line_deadline,O_line_tag}=S_event_job;
    assign O_line_error=S_event_error;
    assign O_line_memory_error=S_event_memory_error;
    assign O_line_accepted=S_event_accepted;
    assign O_line_retired=S_event_retired;
    assign O_task_ready=!I_async_reset && !S_video_reset && !S_stopping && !I_retire_request &&
        !S_reserved[I_task_bank] && S_request_wready;
    assign O_line_valid=!I_async_reset && !S_video_reset && !S_stopping && !I_retire_request &&
        S_event_valid && !S_event_is_barrier && S_event_match;
    assign S_event_ready=!S_video_reset && (S_event_is_barrier || S_stopping || I_retire_request ||
        !S_event_match || I_line_ready);
    assign O_read_ready=!I_async_reset && !S_video_reset && !S_stopping && !I_retire_request &&
        S_bank_valid[I_read_bank] && I_read_x<640 && !(I_release_valid && I_release_bank==I_read_bank);
    assign O_release_ready=!I_async_reset && !S_video_reset && !S_stopping && !I_retire_request &&
        (!S_release_match || !(O_pixel_valid && O_pixel_bank==I_release_bank));
    assign O_bank_valid=S_bank_valid;
    assign O_bank_reserved=S_reserved;
    assign O_bank_slots={S_bank_slot[1],S_bank_slot[0]};
    assign O_bank_rows={S_bank_y[1],S_bank_y[0]};
    assign O_bank_tokens={S_bank_token[1],S_bank_token[0]};
    assign O_bank_generations={S_bank_generation[1],S_bank_generation[0]};
    assign O_bank_epochs={S_bank_epoch[1],S_bank_epoch[0]};
    assign O_bank_tags={S_bank_tag[1],S_bank_tag[0]};
    assign O_mem_valid=!I_async_reset && !S_host_reset && S_cmd_valid;
    assign O_mem_token=S_token;
    assign O_mem_generation=S_generation;
    assign O_mem_deadline=S_deadline;
    assign O_mem_ready=!I_async_reset && !S_host_reset;
    assign O_host_retired=!I_async_reset && !S_host_reset && S_state==WAIT_RELEASE;
    assign O_host_busy=S_state!=IDLE || S_request_valid;
    assign O_host_tag_exhausted=S_tag_exhausted;

    // Simple dual-port RAMs: one host write port, one synchronous video read port.
    // No reset or initialization on storage. An unpublished bank cannot be read.
    always @(posedge I_host_clk) begin
        if (!S_host_reset && S_store && S_retired<640) begin
            if (S_bank) S_line1[S_retired]<=I_mem_data;
            else S_line0[S_retired]<=I_mem_data;
        end
    end
    always @(posedge I_video_clk) begin
        if (S_read_fire) begin
            if (I_read_bank) O_rgba<=S_line1[I_read_x];
            else O_rgba<=S_line0[I_read_x];
        end
    end
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if (S_host_reset) begin
            S_state<=IDLE; S_job<=0; S_error<=0; S_memory_error<=0;
            S_issue<=0; S_accepted<=0; S_retired<=0; S_cmd_valid<=0; S_event_barrier<=0;
            S_next_tag<=1; S_tag_exhausted<=0; S_head<=0; S_tail<=0; S_count<=0;
            S_stop_meta<=0; S_stop_sync<=0; O_response_discarded<=0;
            O_mem_addr<=0; O_mem_tag<=0;
        end else begin
            S_stop_meta<=S_stopping; S_stop_sync<=S_stop_meta;
            O_response_discarded<=I_mem_valid && O_mem_ready && !S_response;
            if (S_active) begin
                S_error<=S_next_error;
                if (S_mem_fire) begin
                    S_cmd_valid<=0; S_pending[S_tail]<=O_mem_tag; S_tail<=S_tail+1'b1;
                    S_accepted<=S_accepted+10'd1;
                end
                if (S_response) begin
                    S_head<=S_head+1'b1; S_retired<=S_retired+10'd1;
                    if (I_mem_error!=0 && S_memory_error==0) S_memory_error<=I_mem_error;
                end
                case ({S_mem_fire,S_response})
                    2'b10:S_count<=S_count+1'b1;
                    2'b01:S_count<=S_count-1'b1;
                    default:begin end
                endcase
                if (S_prepare) begin
                    S_cmd_valid<=1; O_mem_tag<=S_next_tag;
                    O_mem_addr<=S_base+({12'd0,S_y}<<9)+({12'd0,S_y}<<7)+S_issue;
                    S_issue<=S_issue+10'd1;
                    if (&S_next_tag) S_tag_exhausted<=1;
                    else S_next_tag<=S_next_tag+1'b1;
                end
                // A real response retires each accepted command, including on stop.
                if ((S_issue==640 || S_next_error!=0) && S_count==0 && !S_cmd_valid) S_state<=RESULT;
            end
            case (S_state)
                IDLE:if (S_request_valid && S_request_ready) begin
                    S_job<=S_request_data[JOB_BITS-1:0]; S_event_barrier<=S_request_data[JOB_BITS];
                    S_error<=0; S_memory_error<=0; S_issue<=0; S_accepted<=0; S_retired<=0;
                    S_head<=0; S_tail<=0; S_count<=0; S_cmd_valid<=0;
                    if (S_request_data[JOB_BITS]) S_state<=RESULT;
                    else S_state<=RUN;
                end
                RUN:begin end
                RESULT:if (S_event_wready) S_state<=S_event_barrier ? WAIT_RELEASE : IDLE;
                WAIT_RELEASE:if (!S_stop_sync) S_state<=IDLE;
                default:begin end
            endcase
        end
    end
    integer S_i;
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if (S_video_reset) begin
            S_stopping<=0; S_barrier_sent<=0; S_barrier_seen<=0; O_retire_ack<=0;
            S_reserved<=0; S_bank_valid<=0; O_release_discarded<=0; O_event_discarded<=0;
            O_pixel_valid<=0; O_pixel_bank<=0; O_pixel_x<=0;
            O_pixel_token<=0; O_pixel_generation<=0; O_pixel_epoch<=0; O_pixel_tag<=0;
            for (S_i=0;S_i<2;S_i=S_i+1) begin
                S_bank_slot[S_i]<=0; S_bank_y[S_i]<=0; S_bank_token[S_i]<=0;
                S_bank_generation[S_i]<=0; S_bank_epoch[S_i]<=0; S_bank_tag[S_i]<=0;
            end
        end else begin
            O_pixel_valid<=S_read_fire;
            if (S_read_fire) begin
                O_pixel_bank<=I_read_bank; O_pixel_x<=I_read_x;
                O_pixel_token<=S_bank_token[I_read_bank]; O_pixel_generation<=S_bank_generation[I_read_bank];
                O_pixel_epoch<=S_bank_epoch[I_read_bank]; O_pixel_tag<=S_bank_tag[I_read_bank];
            end
            O_release_discarded<=I_release_valid && O_release_ready && !S_release_match;
            O_event_discarded<=S_line_fire && !S_event_match;
            if (S_task_fire) begin
                S_reserved[I_task_bank]<=1; S_bank_valid[I_task_bank]<=0;
                S_bank_slot[I_task_bank]<=I_task_slot; S_bank_y[I_task_bank]<=I_task_y;
                S_bank_token[I_task_bank]<=I_task_token; S_bank_generation[I_task_bank]<=I_task_generation;
                S_bank_epoch[I_task_bank]<=I_task_epoch; S_bank_tag[I_task_bank]<=I_task_tag;
            end
            if (S_line_fire && S_event_match) begin
                if (S_event_error==0) S_bank_valid[O_line_bank]<=1;
                else begin S_reserved[O_line_bank]<=0; S_bank_valid[O_line_bank]<=0; end
            end
            if (I_release_valid && O_release_ready && S_release_match) begin
                S_reserved[I_release_bank]<=0; S_bank_valid[I_release_bank]<=0;
            end
            if (I_retire_request) S_stopping<=1;
            if (S_enqueue_barrier && S_request_wready) S_barrier_sent<=1;
            if (S_event_valid && S_event_ready && S_event_is_barrier) S_barrier_seen<=1;
            if (S_stopping || I_retire_request) begin
                S_reserved<=0; S_bank_valid<=0;
                if (S_barrier_seen && !O_pixel_valid) O_retire_ack<=1;
            end
            if (O_retire_ack && !I_retire_request) begin
                S_stopping<=0; S_barrier_sent<=0; S_barrier_seen<=0; O_retire_ack<=0;
            end
        end
    end
endmodule
