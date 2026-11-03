// One checked, buffered sector at a time. The owner must keep receiving old
// returns until terminal/cancel acknowledgement; media loss never flushes CDC.
module fat32_sector_port (
    input wire I_clk,I_reset,I_card_ready,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_lba,
    input wire [1:0] I_context,I_priority,
    input wire I_abort,
    output wire O_result_valid,
    input wire I_result_ready,
    output reg [7:0] O_error,
    output reg [3:0] O_storage_error,
    input wire [8:0] I_buffer_address,
    output reg [7:0] O_buffer_data,
    output wire O_request_valid,
    input wire I_request_ready,
    output reg [31:0] O_lba,
    output wire [7:0] O_count,
    output reg [1:0] O_context,O_priority,
    output reg [15:0] O_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_sector_last,I_request_last,
    input wire [1:0] I_byte_context,
    input wire [15:0] I_byte_tag,
    input wire I_done_valid,
    output wire O_done_ready,
    input wire [1:0] I_done_context,
    input wire [15:0] I_done_tag,
    input wire [3:0] I_done_error,
    output wire O_cancel_valid,
    input wire I_cancel_ready,
    output wire [1:0] O_cancel_context,
    output wire [15:0] O_cancel_tag,
    input wire I_cancel_done_valid,
    output wire O_cancel_done_ready,
    input wire [1:0] I_cancel_done_context,
    input wire [15:0] I_cancel_done_tag
);
    localparam [1:0] IDLE=0,SEND=1,RECEIVE=2,RESULT=3;
    reg [1:0] S_state;
    reg [7:0] S_ram[0:511];
    reg [15:0] S_next_tag;
    reg [9:0] S_received;
    reg S_bad,S_lost,S_aborted,S_cancel_sent,S_done_seen,S_ack_seen;
    wire S_byte_match=I_byte_context==O_context && I_byte_tag==O_tag;
    wire S_done_match=I_done_context==O_context && I_done_tag==O_tag;
    wire S_ack_match=I_cancel_done_context==O_context && I_cancel_done_tag==O_tag;
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_result_valid=!I_reset && S_state==RESULT;
    assign O_request_valid=!I_reset && S_state==SEND && I_card_ready && !I_abort;
    assign O_count=8'd1;
    assign O_byte_ready=!I_reset;
    assign O_done_ready=!I_reset;
    assign O_cancel_done_ready=!I_reset;
    assign O_cancel_valid=!I_reset && S_state==RECEIVE && !S_cancel_sent &&
        (S_aborted || I_abort);
    assign O_cancel_context=O_context;
    assign O_cancel_tag=O_tag;

    // Synchronous RAM read; this memory has no reset and is overwritten per read.
    always @(posedge I_clk) begin
        O_buffer_data<=S_ram[I_buffer_address];
        if(S_state==RECEIVE && I_byte_valid && S_byte_match && S_received<512)
            S_ram[S_received[8:0]]<=I_byte_data;
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_next_tag<=0; S_received<=0; S_bad<=0; S_lost<=0;
            S_aborted<=0; S_cancel_sent<=0; S_done_seen<=0; S_ack_seen<=0;
            O_lba<=0; O_context<=0; O_priority<=0; O_tag<=0; O_error<=0; O_storage_error<=0;
        end else begin
            case(S_state)
                IDLE: if(I_start_valid) begin
                    O_lba<=I_lba; O_context<=I_context; O_priority<=I_priority;
                    O_tag<=S_next_tag; S_next_tag<=S_next_tag+16'd1;
                    O_error<=0; O_storage_error<=0; S_received<=0; S_bad<=I_context==3;
                    S_lost<=0; S_aborted<=0; S_cancel_sent<=0; S_done_seen<=0; S_ack_seen<=0;
                    if(!I_card_ready) begin O_error<=1; S_state<=RESULT; end
                    else if(I_context==3) begin O_error<=7; S_state<=RESULT; end
                    else S_state<=SEND;
                end
                SEND: if(!I_card_ready) begin O_error<=1; S_state<=RESULT; end
                    else if(I_abort) begin O_error<=8; S_state<=RESULT; end
                    else if(I_request_ready) S_state<=RECEIVE;
                RECEIVE: begin
                    if(!I_card_ready) S_lost<=1;
                    if(I_abort) S_aborted<=1;
                    if(O_cancel_valid && I_cancel_ready) S_cancel_sent<=1;
                    if(I_cancel_done_valid && S_ack_match) S_ack_seen<=1;
                    if(I_byte_valid) begin
                        if(!S_byte_match || S_received>=512 || S_done_seen) S_bad<=1;
                        else begin
                            S_received<=S_received+10'd1;
                            if(I_sector_last!=(S_received==511) || I_request_last!=(S_received==511)) S_bad<=1;
                        end
                    end
                    if(I_done_valid && S_done_match) begin
                        S_done_seen<=1; O_storage_error<=I_done_error;
                        if(I_done_error!=0) O_error<=2;
                    end
                    if(S_done_seen && (!(S_aborted || I_abort) || (S_cancel_sent && S_ack_seen))) begin
                        if(S_lost || !I_card_ready) O_error<=1;
                        else if(S_aborted || I_abort) O_error<=8;
                        else if(O_storage_error!=0) O_error<=2;
                        else if(S_bad || S_received!=512) O_error<=7;
                        S_state<=RESULT;
                    end
                end
                RESULT: if(I_result_ready) S_state<=IDLE;
                default: S_state<=IDLE;
            endcase
        end
    end
endmodule
