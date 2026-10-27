// Ordered command and return FIFOs. Cancel ACK cannot bypass old byte records.
// Media loss drains old commands under a level handshake before reopening.
module sector_cdc_bridge #(
    parameter integer COMMAND_ADDR_BITS=3,RETURN_ADDR_BITS=6
) (
    input wire I_host_clk,I_sd_clk,I_async_reset,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [31:0] I_lba,
    input wire [7:0] I_count,
    input wire [1:0] I_context,I_priority,
    input wire [15:0] I_tag,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_tag,
    input wire [2:0] I_urgent_context,
    output reg O_card_ready,
    output reg [32:0] O_capacity_sectors,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire O_sector_last,O_request_last,
    output wire [1:0] O_byte_context,
    output wire [15:0] O_byte_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [1:0] O_done_context,
    output wire [15:0] O_done_tag,
    output wire [3:0] O_done_error,
    output wire O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output wire [1:0] O_cancel_done_context,
    output wire [15:0] O_cancel_done_tag,
    // All ports below belong to the SD clock domain.
    input wire I_sd_card_ready,
    input wire [32:0] I_sd_capacity_sectors,
    output wire O_sd_request_valid,
    input wire I_sd_request_ready,
    output wire [31:0] O_sd_lba,
    output wire [7:0] O_sd_count,
    output wire [1:0] O_sd_context,O_sd_priority,
    output wire [15:0] O_sd_tag,
    output wire O_sd_cancel_valid,
    input wire I_sd_cancel_ready,
    output wire [1:0] O_sd_cancel_context,
    output wire [15:0] O_sd_cancel_tag,
    output wire [2:0] O_sd_urgent_context,
    input wire I_sd_byte_valid,
    output wire O_sd_byte_ready,
    input wire [7:0] I_sd_byte_data,
    input wire I_sd_sector_last,I_sd_request_last,
    input wire [1:0] I_sd_byte_context,
    input wire [15:0] I_sd_byte_tag,
    input wire I_sd_done_valid,
    output wire O_sd_done_ready,
    input wire [1:0] I_sd_done_context,
    input wire [15:0] I_sd_done_tag,
    input wire [3:0] I_sd_done_error,
    input wire I_sd_cancel_done_valid,
    output wire O_sd_cancel_done_ready,
    input wire [1:0] I_sd_cancel_done_context,
    input wire [15:0] I_sd_cancel_done_tag
);
    localparam [1:0] BLOCKED=0,OPENING=1,ONLINE=2;
    reg [1:0] S_media_state;
    reg S_stop,S_allow;
    reg [32:0] S_capacity_snapshot;
    wire S_host_reset,S_sd_reset;
    reg [1:0] S_stop_sync,S_allow_sync,S_ack_sync;
    reg S_host_ack;
    reg [2:0] S_urgent_meta,S_urgent_sync;
    wire S_command_write_ready,S_command_cancel,S_command_read_ready;
    reg S_command_valid;
    wire S_command_full,S_command_empty;
    wire [COMMAND_ADDR_BITS:0] S_command_write_level,S_command_read_level;
    reg [60:0] S_command_data;
    wire S_command_fifo_valid;
    wire [60:0] S_command_fifo_data;
    reg S_command_write_valid;
    reg [60:0] S_command_write_data;
    wire S_host_buffer_ready=!S_command_write_valid || S_command_write_ready;
    wire S_return_write_ready,S_return_valid,S_return_read_ready,S_return_full,S_return_empty;
    wire [RETURN_ADDR_BITS:0] S_return_write_level,S_return_read_level;
    reg S_return_write_valid;
    reg [33:0] S_return_write_data;
    reg S_offer_valid;
    reg [33:0] S_offer_data;
    wire S_offer_ready=!S_return_write_valid || S_return_write_ready;
    wire [33:0] S_return_data;
    wire [1:0] S_return_type=S_return_data[33:32];
    wire S_reject=S_media_state!=ONLINE || !I_sd_card_ready;
    wire S_reject_valid=S_command_valid && !S_command_cancel && S_reject;
    wire S_choose_done=I_sd_done_valid;
    wire S_choose_byte=!S_choose_done && I_sd_byte_valid;
    wire S_choose_cancel=!S_choose_done && !S_choose_byte && I_sd_cancel_done_valid;
    wire S_choose_reject=!S_choose_done && !S_choose_byte && !S_choose_cancel && S_reject_valid;

    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_sd_reset (.I_clk(I_sd_clk),.I_async_reset(I_async_reset),.O_reset(S_sd_reset));
    assign O_cancel_ready=!S_host_reset && S_host_buffer_ready;
    assign O_request_ready=O_card_ready && !I_cancel_valid && S_host_buffer_ready;
    assign {S_command_cancel,O_sd_lba,O_sd_count,O_sd_context,O_sd_tag,O_sd_priority}=S_command_data;
    assign O_sd_cancel_context=O_sd_context;
    assign O_sd_cancel_tag=O_sd_tag;
    assign O_sd_request_valid=!S_sd_reset && S_command_valid && !S_command_cancel && !S_reject;
    assign O_sd_cancel_valid=!S_sd_reset && S_command_valid && S_command_cancel;
    assign S_command_read_ready=!S_sd_reset && (S_command_cancel ? I_sd_cancel_ready :
        (S_reject ? (S_choose_reject && S_offer_ready) : I_sd_request_ready));
    assign O_sd_urgent_context=S_urgent_sync;
    assign O_sd_done_ready=!S_sd_reset && S_offer_ready && S_choose_done;
    assign O_sd_byte_ready=!S_sd_reset && S_offer_ready && S_choose_byte;
    assign O_sd_cancel_done_ready=!S_sd_reset && S_offer_ready && S_choose_cancel;
    assign O_byte_valid=S_return_valid && S_return_type==0;
    assign O_done_valid=S_return_valid && S_return_type==1;
    assign O_cancel_done_valid=S_return_valid && S_return_type==2;
    assign O_byte_context=S_return_data[31:30];
    assign O_done_context=S_return_data[31:30];
    assign O_cancel_done_context=S_return_data[31:30];
    assign O_byte_tag=S_return_data[29:14];
    assign O_done_tag=S_return_data[29:14];
    assign O_cancel_done_tag=S_return_data[29:14];
    assign O_byte_data=S_return_data[13:6];
    assign O_sector_last=S_return_data[5];
    assign O_request_last=S_return_data[4];
    assign O_done_error=S_return_data[3:0];
    assign S_return_read_ready=S_return_type==0 ? I_byte_ready :
        (S_return_type==1 ? I_done_ready : (S_return_type==2 ? I_cancel_done_ready : 1'b0));

    async_fifo #(.DATA_BITS(61),.ADDR_BITS(COMMAND_ADDR_BITS)) u_commands (
        .I_write_clk(I_host_clk),.I_read_clk(I_sd_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_command_write_valid),
        .O_write_ready(S_command_write_ready),
        .I_write_data(S_command_write_data),
        .O_write_full(S_command_full),.O_write_level(S_command_write_level),
        .O_read_valid(S_command_fifo_valid),.I_read_ready(!S_command_valid),.O_read_data(S_command_fifo_data),
        .O_read_empty(S_command_empty),.O_read_level(S_command_read_level));
    // Decouple the synchronous FIFO read-enable from the SD request validation
    // and return arbitration cones. One held command preserves FIFO ordering.
    always @(posedge I_sd_clk or posedge S_sd_reset) begin
        if(S_sd_reset) begin S_command_valid<=0; S_command_data<=0; end
        else if(!S_command_valid) begin
            S_command_valid<=S_command_fifo_valid;
            if(S_command_fifo_valid) S_command_data<=S_command_fifo_data;
        end else if(S_command_read_ready) S_command_valid<=0;
    end
    always @* begin
        S_offer_valid=!S_sd_reset && (S_choose_done || S_choose_byte || S_choose_cancel || S_choose_reject);
        S_offer_data=0;
        if(S_choose_done) S_offer_data={2'd1,I_sd_done_context,I_sd_done_tag,8'd0,2'b00,I_sd_done_error};
        else if(S_choose_byte) S_offer_data={2'd0,I_sd_byte_context,I_sd_byte_tag,I_sd_byte_data,
            I_sd_sector_last,I_sd_request_last,4'd0};
        else if(S_choose_cancel) S_offer_data={2'd2,I_sd_cancel_done_context,I_sd_cancel_done_tag,8'd0,6'd0};
        else if(S_choose_reject) S_offer_data={2'd1,O_sd_context,O_sd_tag,8'd0,2'b00,4'd11};
    end
    async_fifo #(.DATA_BITS(34),.ADDR_BITS(RETURN_ADDR_BITS)) u_returns (
        .I_write_clk(I_sd_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_return_write_valid),.O_write_ready(S_return_write_ready),.I_write_data(S_return_write_data),
        .O_write_full(S_return_full),.O_write_level(S_return_write_level),
        .O_read_valid(S_return_valid),.I_read_ready(S_return_read_ready),.O_read_data(S_return_data),
        .O_read_empty(S_return_empty),.O_read_level(S_return_read_level));

    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_stop_sync<=2'b11; S_allow_sync<=0; S_host_ack<=1;
            S_command_write_valid<=0; S_command_write_data<=0;
            O_card_ready<=0; O_capacity_sectors<=0;
        end
        else begin
            S_stop_sync<={S_stop_sync[0],S_stop}; S_allow_sync<={S_allow_sync[0],S_allow};
            // Bundled data: snapshot precedes OPENING's round trip and allow.
            // Capture capacity on the same edge that publishes host readiness.
            O_card_ready<=S_allow_sync[1] && !S_stop_sync[1];
            if(S_allow_sync[1] && !S_stop_sync[1] && !O_card_ready)
                O_capacity_sectors<=S_capacity_snapshot;
            S_host_ack<=S_stop_sync[1] && !S_command_write_valid;
            if(S_host_buffer_ready) begin
                S_command_write_valid<=I_cancel_valid || (I_request_valid && O_card_ready);
                if(I_cancel_valid) S_command_write_data<={1'b1,32'd0,8'd0,I_cancel_context,I_cancel_tag,2'd0};
                else if(I_request_valid && O_card_ready)
                    S_command_write_data<={1'b0,I_lba,I_count,I_context,I_tag,I_priority};
            end
        end
    end
    // Lock arbitration results before the FIFO so full queues keep data stable.
    always @(posedge I_sd_clk or posedge S_sd_reset) begin
        if(S_sd_reset) begin S_return_write_valid<=0; S_return_write_data<=0; end
        else if(S_offer_ready) begin
            S_return_write_valid<=S_offer_valid;
            if(S_offer_valid) S_return_write_data<=S_offer_data;
        end
    end
    always @(posedge I_sd_clk or posedge S_sd_reset) begin
        if(S_sd_reset) begin
            S_media_state<=BLOCKED; S_stop<=1; S_allow<=0; S_ack_sync<=2'b11;
            S_capacity_snapshot<=0;
            S_urgent_meta<=0; S_urgent_sync<=0;
        end else begin
            S_ack_sync<={S_ack_sync[0],S_host_ack};
            S_urgent_meta<=I_urgent_context; S_urgent_sync<=S_urgent_meta;
            case(S_media_state)
                BLOCKED: if(S_ack_sync[1] && S_command_read_level==0 && !S_command_valid && !S_command_fifo_valid && I_sd_card_ready) begin
                    S_capacity_snapshot<=I_sd_capacity_sectors;
                    S_stop<=0; S_media_state<=OPENING;
                end
                OPENING: if(!I_sd_card_ready) begin
                    // A second loss during opening also invalidates the snapshot.
                    S_media_state<=BLOCKED; S_stop<=1; S_allow<=0;
                end else if(!S_ack_sync[1]) begin S_media_state<=ONLINE; S_allow<=1; end
                ONLINE: if(!I_sd_card_ready) begin S_media_state<=BLOCKED; S_stop<=1; S_allow<=0; end
                default: begin S_media_state<=BLOCKED; S_stop<=1; S_allow<=0; end
            endcase
        end
    end
endmodule
