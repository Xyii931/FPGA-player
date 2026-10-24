// Read-only SD SPI transactions. Initialization/retry/scheduling belong upstairs.
// Completed blocks need CRC acceptance before the caller commits their bytes.
module sd_spi_phy #(
    parameter [31:0] RESPONSE_TIMEOUT_CYCLES=32'd1000000,
    parameter [31:0] TOKEN_TIMEOUT_CYCLES=32'd10000000,
    parameter [31:0] BUSY_TIMEOUT_CYCLES=32'd50000000,
    parameter [31:0] STALL_TIMEOUT_CYCLES=32'd10000000
) (
    input wire I_clk,I_reset,
    input wire I_cmd_valid,
    output wire O_cmd_ready,
    input wire [5:0] I_cmd_index,
    input wire [31:0] I_cmd_argument,
    input wire [7:0] I_cmd_crc,
    input wire [2:0] I_response_bytes,
    input wire [7:0] I_block_count,
    input wire [15:0] I_divider,I_tag,
    input wire I_crc_check,I_abort,
    input wire I_idle_valid,
    output wire O_idle_ready,
    input wire [7:0] I_idle_bytes,
    output reg O_response_valid,
    input wire I_response_ready,
    output reg [39:0] O_response_data,
    output reg [2:0] O_response_bytes,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output reg [7:0] O_byte_data,
    output wire O_block_last,O_request_last,
    output reg O_block_done,O_crc_ok,O_done,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output wire O_busy,
    output reg O_sd_ncs,
    output wire O_sd_sclk,O_sd_mosi,
    input wire I_sd_miso
);
    localparam [3:0] IDLE=0,IDLE_CLOCKS=1,SEND_COMMAND=2,STOP_STUFF=3,
        WAIT_RESPONSE=4,EXTRA_RESPONSE=5,HOLD_RESPONSE=6,WAIT_TOKEN=7,
        READ_DATA=8,HOLD_DATA=9,CRC_HIGH=10,CRC_LOW=11,WAIT_BUSY=12,TRAIL=13;
    reg [3:0] S_state,S_age_state;
    reg [31:0] S_age;
    reg [15:0] S_divider,S_crc;
    reg [47:0] S_command;
    reg [5:0] S_index;
    reg [2:0] S_command_byte,S_response_index;
    reg [7:0] S_blocks_left,S_idle_left,S_crc_high;
    reg [8:0] S_data_index;
    reg [8:0] S_data_last;
    reg S_crc_check,S_multi,S_internal_stop,S_drop,S_pending;
    reg [3:0] S_abort_error;
    wire S_transfer_ready,S_received,S_engine_busy;
    wire [7:0] S_rx;
    wire S_transfer_state=S_state==IDLE_CLOCKS || S_state==SEND_COMMAND || S_state==STOP_STUFF ||
        S_state==WAIT_RESPONSE || S_state==EXTRA_RESPONSE || S_state==WAIT_TOKEN ||
        S_state==READ_DATA || S_state==CRC_HIGH || S_state==CRC_LOW || S_state==WAIT_BUSY || S_state==TRAIL;
    wire S_transfer_valid=S_transfer_state && !S_pending;
    wire [7:0] S_tx=S_state==SEND_COMMAND ? S_command[47:40] : 8'hff;
    wire S_supported=I_cmd_index==0 || I_cmd_index==8 || I_cmd_index==55 || I_cmd_index==41 ||
        I_cmd_index==58 || I_cmd_index==16 || I_cmd_index==17 || I_cmd_index==18 ||
        I_cmd_index==12 || I_cmd_index==13 || I_cmd_index==9;
    wire S_parameters_ok=S_supported && I_cmd_crc[0] && I_divider>=4 && !I_divider[0] &&
        (I_response_bytes==1 || I_response_bytes==2 || I_response_bytes==5) &&
        (I_cmd_index!=17 || I_block_count==1) &&
        (I_cmd_index!=9 || (I_block_count==1 && I_response_bytes==1)) &&
        (I_cmd_index!=18 || (I_block_count>=1 && I_block_count<=128));
    assign O_idle_ready=!I_reset && S_state==IDLE && !I_abort;
    assign O_cmd_ready=O_idle_ready && !I_idle_valid;
    assign O_busy=S_state!=IDLE;
    assign O_byte_valid=S_state==HOLD_DATA && !S_drop && !I_abort && !I_reset;
    assign O_block_last=S_data_index==S_data_last;
    assign O_request_last=O_block_last && S_blocks_left==1;

    spi_byte_master u_byte (
        .I_clk(I_clk),.I_reset(I_reset),.I_tx_valid(S_transfer_valid),.O_tx_ready(S_transfer_ready),
        .I_tx_data(S_tx),.I_divider(S_divider),.O_rx_valid(S_received),.I_rx_ready(1'b1),
        .O_rx_data(S_rx),.O_sclk(O_sd_sclk),.O_mosi(O_sd_mosi),
        .I_miso(I_sd_miso),.O_busy(S_engine_busy));

    function [15:0] crc16_byte;
        input [15:0] old_crc;
        input [7:0] value;
        reg [15:0] crc;
        integer bit_index;
        begin
            crc=old_crc;
            for(bit_index=7;bit_index>=0;bit_index=bit_index-1)
                if(crc[15]^value[bit_index]) crc=(crc<<1)^16'h1021;
                else crc=crc<<1;
            crc16_byte=crc;
        end
    endfunction

    // Called only with the byte engine idle or on a complete received byte.
    task retire;
        input [3:0] error_code;
        begin
            O_error<=error_code; O_response_valid<=0;
            if(S_multi && !S_internal_stop) begin
                S_internal_stop<=1; S_index<=12; S_command_byte<=0;
                S_command<={8'h4c,32'd0,8'h01}; S_state<=SEND_COMMAND;
            end else begin O_sd_ncs<=1; S_state<=TRAIL; end
        end
    endtask

    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_age_state<=IDLE; S_age<=0; S_divider<=250;
            S_crc<=0; S_command<=0; S_index<=0; S_command_byte<=0; S_response_index<=0;
            S_blocks_left<=0; S_idle_left<=0; S_crc_high<=0; S_data_index<=0; S_data_last<=511;
            S_crc_check<=0; S_multi<=0; S_internal_stop<=0; S_drop<=0; S_pending<=0; S_abort_error<=6;
            O_response_valid<=0; O_response_data<=0; O_response_bytes<=0; O_byte_data<=0;
            O_block_done<=0; O_crc_ok<=0; O_done<=0; O_error<=0; O_tag<=0; O_sd_ncs<=1;
        end else begin
            O_done<=0; O_block_done<=0;
            S_age_state<=S_state;
            if(S_age_state!=S_state) S_age<=0;
            else if(S_age!=32'hffffffff) S_age<=S_age+32'd1;
            if(S_transfer_valid && S_transfer_ready) S_pending<=1;
            if(S_received) S_pending<=0;
            if(I_abort && S_state!=IDLE && S_state!=IDLE_CLOCKS && S_state!=TRAIL) S_drop<=1;
            case(S_state)
                IDLE: begin
                    if(I_idle_valid && O_idle_ready) begin
                        S_divider<=(I_divider>=4 && !I_divider[0]) ? I_divider : 16'd250;
                        S_idle_left<=I_idle_bytes; O_tag<=I_tag; O_error<=0; S_drop<=0;
                        if(I_idle_bytes==0 || I_divider<4 || I_divider[0]) begin
                            O_error<=7; S_state<=TRAIL;
                        end else S_state<=IDLE_CLOCKS;
                    end else if(I_cmd_valid && O_cmd_ready) begin
                        O_tag<=I_tag; O_error<=0; O_crc_ok<=0; O_response_data<=0;
                        O_response_bytes<=I_response_bytes; S_index<=I_cmd_index;
                        S_blocks_left<=I_block_count; S_crc_check<=I_crc_check;
                        S_data_last<=I_cmd_index==9 ? 9'd15 : 9'd511;
                        S_divider<=(I_divider>=4 && !I_divider[0]) ? I_divider : 16'd250;
                        S_drop<=0; S_abort_error<=6; S_multi<=0; S_internal_stop<=0;
                        S_command<={2'b01,I_cmd_index,I_cmd_argument,I_cmd_crc}; S_command_byte<=0;
                        if(!S_parameters_ok) begin O_error<=7; S_state<=TRAIL; end
                        else begin O_sd_ncs<=0; S_state<=SEND_COMMAND; end
                    end
                end
                IDLE_CLOCKS: if(S_received) begin
                    if(S_idle_left==1) begin O_done<=1; S_state<=IDLE; end
                    else S_idle_left<=S_idle_left-8'd1;
                end
                SEND_COMMAND: if(S_received) begin
                    S_command<={S_command[39:0],8'hff};
                    if(S_command_byte==5) S_state<=(S_index==12) ? STOP_STUFF : WAIT_RESPONSE;
                    else S_command_byte<=S_command_byte+3'd1;
                end
                STOP_STUFF: if(S_received) S_state<=WAIT_RESPONSE;
                WAIT_RESPONSE: if(S_received) begin
                    if(!S_rx[7]) begin
                        if(S_internal_stop) begin
                            if(S_rx!=0) begin O_error<=5; O_sd_ncs<=1; S_state<=TRAIL; end
                            else S_state<=WAIT_BUSY;
                        end else begin
                            O_response_data[7:0]<=S_rx;
                            if(S_index==18 && S_rx==0) S_multi<=1;
                            if(O_response_bytes==1) begin O_response_valid<=1; S_state<=HOLD_RESPONSE; end
                            else begin S_response_index<=1; S_state<=EXTRA_RESPONSE; end
                        end
                    end else if(S_age>=RESPONSE_TIMEOUT_CYCLES) retire(4'd1);
                end
                EXTRA_RESPONSE: if(S_received) begin
                    O_response_data[S_response_index*8+:8]<=S_rx;
                    if(S_response_index==O_response_bytes-1) begin O_response_valid<=1; S_state<=HOLD_RESPONSE; end
                    else S_response_index<=S_response_index+3'd1;
                end
                HOLD_RESPONSE: begin
                    if(S_drop || I_abort) retire(S_abort_error);
                    else if(O_response_valid && I_response_ready) begin
                        O_response_valid<=0;
                        // Idle-state R1=1 and illegal-command R1 are valid replies.
                        // Only read commands require R1=0 at this layer.
                        if((S_index==9 || S_index==17 || S_index==18) && O_response_data[7:0]!=0) retire(4'd5);
                        else if(S_index==9 || S_index==17 || S_index==18) S_state<=WAIT_TOKEN;
                        else if(S_index==12 && O_response_data[7:0]==0) S_state<=WAIT_BUSY;
                        else if(S_index==12) retire(4'd5);
                        else retire(4'd0);
                    end else if(S_age>=STALL_TIMEOUT_CYCLES) retire(4'd8);
                end
                WAIT_TOKEN: if(S_received) begin
                    if(S_rx==8'hfe) begin S_data_index<=0; S_crc<=0; S_state<=READ_DATA; end
                    else if(S_drop || I_abort) retire(S_abort_error);
                    else if(S_rx!=8'hff) retire(S_rx[7:4]==0 ? 4'd3 : 4'd5);
                    else if(S_age>=TOKEN_TIMEOUT_CYCLES) retire(4'd2);
                end
                READ_DATA: if(S_received) begin
                    O_byte_data<=S_rx; S_crc<=crc16_byte(S_crc,S_rx); S_state<=HOLD_DATA;
                end
                HOLD_DATA: begin
                    if(S_drop || I_abort || I_byte_ready || S_age>=STALL_TIMEOUT_CYCLES) begin
                        if(!S_drop && !I_abort && !I_byte_ready) begin
                            S_drop<=1; S_abort_error<=8; O_error<=8;
                        end
                        if(S_data_index==S_data_last) S_state<=CRC_HIGH;
                        else begin S_data_index<=S_data_index+9'd1; S_state<=READ_DATA; end
                    end
                end
                CRC_HIGH: if(S_received) begin S_crc_high<=S_rx; S_state<=CRC_LOW; end
                CRC_LOW: if(S_received) begin
                    O_block_done<=1;
                    O_crc_ok<=!S_drop && !I_abort && (!S_crc_check || {S_crc_high,S_rx}==S_crc);
                    if(S_drop || I_abort) retire(S_abort_error);
                    else if(S_crc_check && {S_crc_high,S_rx}!=S_crc) retire(4'd4);
                    else if(S_blocks_left==1) retire(4'd0);
                    else begin S_blocks_left<=S_blocks_left-8'd1; S_state<=WAIT_TOKEN; end
                end
                WAIT_BUSY: if(S_received) begin
                    if(S_rx!=0) begin
                        if(S_internal_stop) begin
                            if((S_drop || I_abort) && O_error==0) O_error<=S_abort_error;
                            O_sd_ncs<=1; S_state<=TRAIL;
                        end
                        else retire((S_drop || I_abort) ? S_abort_error : 4'd0);
                    end else if(S_age>=BUSY_TIMEOUT_CYCLES) begin O_error<=9; O_sd_ncs<=1; S_state<=TRAIL; end
                end
                TRAIL: if(S_received) begin O_done<=1; S_state<=IDLE; end
                default: begin O_error<=5; O_sd_ncs<=1; S_state<=TRAIL; end
            endcase
        end
    end
endmodule
