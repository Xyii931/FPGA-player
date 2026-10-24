// Read-only command/result mailbox plus real byte FIFO. Both owners share reset.
module flash_read_cdc (
    input wire I_host_clk,I_flash_clk,I_async_reset,
    input wire I_valid,
    output wire O_ready,
    input wire [23:0] I_address,
    input wire [9:0] I_length,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire O_byte_last,O_done_valid,
    input wire I_done_ready,
    output wire [3:0] O_error,
    output wire O_flash_valid,
    input wire I_flash_ready,
    output wire [23:0] O_flash_address,
    output wire [15:0] O_flash_length,O_flash_tag,
    input wire I_flash_read_valid,
    output wire O_flash_read_ready,
    input wire [7:0] I_flash_read_data,
    input wire I_flash_read_last,I_flash_done_valid,
    output wire O_flash_done_ready,
    input wire [3:0] I_flash_error,
    input wire [15:0] I_flash_tag
);
    wire S_host_reset,S_flash_reset;
    reg [1:0] S_host_state;
    reg [2:0] S_flash_state;
    reg S_request,S_ack;
    reg [33:0] S_command,S_flash_command;
    reg [9:0] S_received,S_sent,S_result_count;
    reg [3:0] S_result_error;
    reg [15:0] S_tag;
    (* ASYNC_REG="TRUE" *) reg S_req_meta,S_req_sync,S_ack_meta,S_ack_sync;
    wire S_fifo_ready,S_fifo_full,S_fifo_empty;
    wire [10:0] S_write_level,S_read_level;
    reset_sync u_host(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_flash(.I_clk(I_flash_clk),.I_async_reset(I_async_reset),.O_reset(S_flash_reset));
    assign O_ready=!S_host_reset && S_host_state==0;
    assign O_done_valid=!S_host_reset && S_host_state==1 && S_ack_sync && S_received==S_result_count;
    assign O_error=S_result_error;
    assign O_flash_valid=!S_flash_reset && S_flash_state==2;
    assign O_flash_address=S_flash_command[33:10];
    assign O_flash_length={6'd0,S_flash_command[9:0]};
    assign O_flash_tag=S_tag;
    assign O_flash_read_ready=!S_flash_reset && S_flash_state==3 && S_fifo_ready;
    assign O_flash_done_ready=!S_flash_reset && S_flash_state==3;
    async_fifo #(.DATA_BITS(9),.ADDR_BITS(10)) u_bytes (
        .I_write_clk(I_flash_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(I_flash_read_valid && S_flash_state==3),.O_write_ready(S_fifo_ready),
        .I_write_data({I_flash_read_last,I_flash_read_data}),.O_write_full(S_fifo_full),.O_write_level(S_write_level),
        .O_read_valid(O_byte_valid),.I_read_ready(I_byte_ready),.O_read_data({O_byte_last,O_byte_data}),
        .O_read_empty(S_fifo_empty),.O_read_level(S_read_level));
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin S_host_state<=0; S_request<=0; S_command<=0; S_received<=0; S_ack_meta<=0; S_ack_sync<=0; end
        else begin
            S_ack_meta<=S_ack; S_ack_sync<=S_ack_meta;
            if(O_byte_valid && I_byte_ready) S_received<=S_received+1'b1;
            case(S_host_state)
                0:if(I_valid && O_ready) begin S_command<={I_address,I_length}; S_received<=0; S_request<=1; S_host_state<=1; end
                1:if(O_done_valid && I_done_ready) begin S_request<=0; S_host_state<=2; end
                2:if(!S_ack_sync) S_host_state<=0;
                default:S_host_state<=2;
            endcase
        end
    end
    always @(posedge I_flash_clk or posedge S_flash_reset) begin
        if(S_flash_reset) begin
            S_flash_state<=0; S_req_meta<=0; S_req_sync<=0; S_ack<=0; S_sent<=0;
            S_result_count<=0; S_result_error<=0; S_tag<=0; S_flash_command<=0;
        end else begin
            S_req_meta<=S_request; S_req_sync<=S_req_meta;
            case(S_flash_state)
                0:if(S_req_sync) S_flash_state<=1;
                1:begin
                    S_flash_command<=S_command; S_sent<=0; S_tag<=S_tag+1'b1;
                    if(S_command[9:0]==0 || S_command[9:0]>512 ||
                        {1'b0,S_command[33:10]}+{15'd0,S_command[9:0]}>25'h1000000) begin
                        S_result_count<=0; S_result_error<=1; S_ack<=1; S_flash_state<=4;
                    end else S_flash_state<=2;
                end
                2:if(I_flash_ready) S_flash_state<=3;
                3:begin
                    if(I_flash_read_valid && O_flash_read_ready) S_sent<=S_sent+1'b1;
                    if(I_flash_done_valid && O_flash_done_ready) begin
                        S_result_count<=S_sent+((I_flash_read_valid && O_flash_read_ready) ? 10'd1 : 10'd0);
                        S_result_error<=I_flash_tag!=S_tag ? 4'd8 : I_flash_error!=0 ? I_flash_error :
                            S_sent+((I_flash_read_valid && O_flash_read_ready) ? 10'd1 : 10'd0)!=S_flash_command[9:0] ? 4'd8 : 4'd0;
                        S_ack<=1; S_flash_state<=4;
                    end
                end
                4:if(!S_req_sync) begin S_ack<=0; S_flash_state<=0; end
                default:S_flash_state<=4;
            endcase
        end
    end
endmodule
