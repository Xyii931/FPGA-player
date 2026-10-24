// W25Q64 single-lane mode-0 transactions. Completion uses real status reads.
module flash_ctrl #(
    parameter [15:0] SPI_DIVIDER=16'd4,
    parameter integer TIMEOUT_CYCLES=100000000
) (
    input wire I_clk,I_reset,I_cmd_valid,
    output wire O_cmd_ready,
    input wire [1:0] I_op,
    input wire [23:0] I_address,
    input wire [15:0] I_length,I_tag,
    input wire I_write_valid,
    output wire O_write_ready,
    input wire [7:0] I_write_data,
    input wire I_write_last,
    output wire O_read_valid,
    input wire I_read_ready,
    output reg [7:0] O_read_data,
    output wire O_read_last,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output wire O_busy,
    output reg O_cs_n,
    output wire O_sclk,O_mosi,
    input wire I_miso
);
    localparam [2:0] IDLE=0,PREPARE=1,TRANSMIT=2,RECEIVE=3,GAP=4,READ_OUT=5,RESULT=6;
    localparam [2:0] BEFORE=0,WREN=1,WEL=2,COMMAND=3,AFTER=4;
    reg [2:0] S_state,S_phase;
    reg [1:0] S_op;
    reg [23:0] S_address;
    reg [15:0] S_length;
    reg [16:0] S_index;
    reg [31:0] S_poll_ticks;
    reg [3:0] S_gap;
    reg [7:0] S_status;
    reg S_payload_error;
    wire S_tx_ready,S_rx_valid,S_spi_busy;
    wire [7:0] S_rx_data;
    reg [7:0] C_tx_data;
    wire S_body=S_phase==COMMAND && S_op==1 && S_index>=4;
    wire S_tx_valid=S_state==TRANSMIT && (!S_body || I_write_valid);
    wire [16:0] S_packet_bytes=S_phase==WREN ? 17'd1 :
        S_phase!=COMMAND ? 17'd2 : S_op==2 ? 17'd4 : {1'b0,S_length}+17'd4;
    wire [24:0] S_end={1'b0,I_address}+{9'd0,I_length};
    wire S_command_ok=I_op<3 && I_length!=0 && S_end<=25'h0800000 &&
        (I_op!=1 || (I_length<=256 && {9'd0,I_address[7:0]}+{1'b0,I_length}<=256)) &&
        (I_op!=2 || (I_address[11:0]==0 && I_length==4096));
    assign O_cmd_ready=!I_reset && S_state==IDLE;
    assign O_write_ready=!I_reset && S_state==TRANSMIT && S_body && S_tx_ready;
    assign O_read_valid=!I_reset && S_state==READ_OUT;
    assign O_read_last=S_index+17'd1==S_packet_bytes;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_busy=S_state!=IDLE;
    always @* begin
        C_tx_data=8'hff;
        if(S_phase==WREN) C_tx_data=8'h06;
        else if(S_phase!=COMMAND) C_tx_data=S_index==0 ? 8'h05 : 8'hff;
        else case(S_index)
            0:C_tx_data=S_op==0 ? 8'h03 : S_op==1 ? 8'h02 : 8'h20;
            1:C_tx_data=S_address[23:16];
            2:C_tx_data=S_address[15:8];
            3:C_tx_data=S_address[7:0];
            default:C_tx_data=S_op==1 ? I_write_data : 8'hff;
        endcase
    end
    spi_byte_master u_spi (
        .I_clk(I_clk),.I_reset(I_reset),.I_tx_valid(S_tx_valid),.O_tx_ready(S_tx_ready),
        .I_tx_data(C_tx_data),.I_divider(SPI_DIVIDER),.O_rx_valid(S_rx_valid),
        .I_rx_ready(S_state==RECEIVE),.O_rx_data(S_rx_data),
        .O_sclk(O_sclk),.O_mosi(O_mosi),.I_miso(I_miso),.O_busy(S_spi_busy)
    );
    task packet_finished;
        begin O_cs_n<=1; S_gap<=0; S_state<=GAP; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_phase<=BEFORE; S_op<=0; S_address<=0; S_length<=0;
            S_index<=0; S_poll_ticks<=0; S_gap<=0; S_status<=0; S_payload_error<=0;
            O_cs_n<=1; O_error<=0; O_tag<=0; O_read_data<=0;
        end else begin
            if(S_state!=IDLE && S_state!=RESULT && S_poll_ticks<TIMEOUT_CYCLES) S_poll_ticks<=S_poll_ticks+1'b1;
            case(S_state)
                IDLE:if(I_cmd_valid) begin
                    S_op<=I_op; S_address<=I_address; S_length<=I_length; O_tag<=I_tag;
                    S_payload_error<=0; S_poll_ticks<=0; O_error<=0; S_phase<=BEFORE;
                    if(!S_command_ok) begin O_error<=1; S_state<=RESULT; end
                    else S_state<=PREPARE;
                end
                PREPARE:begin O_cs_n<=0; S_index<=0; S_state<=TRANSMIT; end
                TRANSMIT:if(S_tx_valid && S_tx_ready) begin
                    if(S_body && I_write_last!=(S_index+17'd1==S_packet_bytes)) S_payload_error<=1;
                    S_state<=RECEIVE;
                end
                RECEIVE:if(S_rx_valid) begin
                    if(S_phase==COMMAND && S_op==0 && S_index>=4) begin O_read_data<=S_rx_data; S_state<=READ_OUT; end
                    else if(S_body && S_payload_error) packet_finished;
                    else if(S_index+17'd1==S_packet_bytes) begin
                        if(S_phase==BEFORE || S_phase==WEL || S_phase==AFTER) S_status<=S_rx_data;
                        packet_finished;
                    end else begin S_index<=S_index+17'd1; S_state<=TRANSMIT; end
                end
                READ_OUT:if(I_read_ready) begin
                    if(O_read_last) packet_finished;
                    else begin S_index<=S_index+17'd1; S_state<=TRANSMIT; end
                end
                GAP:if(S_gap!=7) S_gap<=S_gap+1'b1;
                    else case(S_phase)
                        BEFORE,AFTER:if(S_status[0]) begin
                            if(S_poll_ticks>=TIMEOUT_CYCLES) begin O_error<=4; S_state<=RESULT; end
                            else S_state<=PREPARE;
                        end else if(S_phase==AFTER) begin O_error<=S_payload_error ? 4'd2 : 4'd0; S_state<=RESULT; end
                        else begin S_phase<=S_op==0 ? COMMAND : WREN; S_state<=PREPARE; end
                        WREN:begin S_phase<=WEL; S_state<=PREPARE; end
                        WEL:if(!S_status[1] || S_status[0]) begin O_error<=3; S_state<=RESULT; end
                            else begin S_phase<=COMMAND; S_state<=PREPARE; end
                        COMMAND:if(S_op==0) S_state<=RESULT;
                            else begin S_phase<=AFTER; S_poll_ticks<=0; S_state<=PREPARE; end
                        default:begin O_error<=5; S_state<=RESULT; end
                    endcase
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin O_cs_n<=1; O_error<=5; S_state<=RESULT; end
            endcase
        end
    end
endmodule
