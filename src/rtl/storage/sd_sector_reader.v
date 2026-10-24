// Read-only card initialization plus four resumable requests. One CMD17 per turn.
// CRC-checked sector RAM prevents delivery of a corrupt or canceled partial block.
module sd_sector_reader #(
    parameter [15:0] INIT_DIVIDER=16'd250,WORK_DIVIDER=16'd4,
    parameter [31:0] POWERUP_CYCLES=32'd100000,
    parameter [31:0] INIT_TIMEOUT_CYCLES=32'd100000000,
    parameter [31:0] INIT_POLL_CYCLES=32'd100000,
    parameter [31:0] RETRY_CYCLES=32'd200000000,
    parameter [31:0] PROBE_CYCLES=32'd50000000,
    parameter [31:0] DELIVERY_TIMEOUT_CYCLES=32'd10000000,
    parameter [31:0] RESPONSE_TIMEOUT_CYCLES=32'd1000000,
    parameter [31:0] TOKEN_TIMEOUT_CYCLES=32'd10000000,
    parameter [31:0] BUSY_TIMEOUT_CYCLES=32'd50000000,
    parameter [31:0] STALL_TIMEOUT_CYCLES=32'd10000000
) (
    input wire I_clk,I_reset,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [31:0] I_lba,
    input wire [7:0] I_count,
    input wire [1:0] I_context,I_priority,
    input wire [15:0] I_tag,
    input wire [2:0] I_urgent_context,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output reg [7:0] O_byte_data,
    output wire O_sector_last,O_request_last,
    output wire [1:0] O_byte_context,
    output wire [15:0] O_byte_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [1:0] O_done_context,
    output wire [15:0] O_done_tag,
    output wire [3:0] O_done_error,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_tag,
    output reg O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output wire [1:0] O_cancel_done_context,
    output wire [15:0] O_cancel_done_tag,
    output reg O_card_ready,O_high_capacity,
    output reg [32:0] O_capacity_sectors,
    output wire O_card_present,
    output reg [3:0] O_card_error,
    output wire O_sd_ncs,O_sd_sclk,O_sd_mosi,
    input wire I_sd_miso
);
    localparam [3:0] POWER_WAIT=0,CLOCK_START=1,CLOCK_WAIT=2,COMMAND_SEND=3,COMMAND_WAIT=4,
        SCHEDULE=5,READ_SEND=6,READ_WAIT=7,DELIVER=8,COMPLETE=9,RETRY=10,POLL_DELAY=11;
    localparam [2:0] INIT_CMD0=0,INIT_CMD8=1,INIT_CMD55=2,INIT_ACMD41=3,INIT_CMD58=4,INIT_CMD16=5,PROBE_CMD13=6,INIT_CMD9=7;
    reg [3:0] S_state,S_complete_error;
    reg [2:0] S_step;
    reg [31:0] S_timer,S_init_age,S_probe_age,S_delivery_age;
    reg S_v2,S_init_budget,S_output_valid;
    reg [3:0] S_valid,S_canceled;
    reg [31:0] S_lba[0:3];
    reg [7:0] S_remaining[0:3];
    reg [1:0] S_context[0:3],S_priority[0:3];
    reg [15:0] S_tag[0:3];
    reg [3:0] S_entry_error[0:3];
    reg [1:0] S_active,S_round_robin;
    reg S_free_found,S_pick_found,S_duplicate,S_cancel_live;
    reg [1:0] S_free,S_pick;
    reg [2:0] S_best_score,S_score;
    integer S_scan,S_candidate,S_reset_index;
    reg S_cancel_pending;
    reg [1:0] S_cancel_context;
    reg [15:0] S_cancel_tag;
    reg [7:0] S_sector[0:511];
    reg [9:0] S_write_count;
    reg [8:0] S_out_index;
    reg S_block_good;
    reg [39:0] S_response;
    reg [127:0] S_csd;
    reg [4:0] S_csd_count;
    reg S_csd_good;
    wire S_csd_valid;
    wire [32:0] S_capacity_sectors;
    sd_csd_decode u_csd (.I_csd(S_csd),.I_high_capacity(O_high_capacity),
        .O_valid(S_csd_valid),.O_capacity_sectors(S_capacity_sectors));
    wire [31:0] S_ocr={S_response[15:8],S_response[23:16],S_response[31:24],S_response[39:32]};
    wire [32:0] S_request_end={1'b0,I_lba}+{25'd0,I_count}-33'd1;
    wire S_bad_request=I_context==3 || I_count==0 || I_count>128 || S_request_end[32] ||
        S_request_end>=O_capacity_sectors || (!O_high_capacity && S_request_end>33'h0007fffff);
    wire S_cancel_accept=I_cancel_valid && O_cancel_ready;
    wire S_cancel_active=S_cancel_accept && I_cancel_context==S_context[S_active] && I_cancel_tag==S_tag[S_active];
    wire S_phy_cmd_ready,S_phy_idle_ready,S_phy_response_valid,S_phy_byte_valid,S_phy_block_done,S_phy_crc_ok;
    wire S_phy_done,S_phy_busy,S_phy_block_last,S_phy_request_last;
    wire [39:0] S_phy_response;
    wire [2:0] S_phy_response_count;
    wire [7:0] S_phy_byte;
    wire [3:0] S_phy_error;
    wire [15:0] S_phy_tag;
    reg [5:0] S_command_index;
    reg [31:0] S_command_argument;
    reg [7:0] S_command_crc;
    reg [2:0] S_response_bytes;
    wire S_read_command=S_state==READ_SEND || S_state==READ_WAIT;
    wire S_phy_abort=S_read_command && (S_canceled[S_active] || S_cancel_active);

    assign O_card_present=O_card_ready;
    assign O_request_ready=!I_reset && O_card_ready && S_free_found && !S_duplicate && !I_cancel_valid &&
        !(S_cancel_pending && S_cancel_context==I_context && S_cancel_tag==I_tag);
    assign O_cancel_ready=!I_reset && !S_cancel_pending && !O_cancel_done_valid;
    assign O_cancel_done_context=S_cancel_context;
    assign O_cancel_done_tag=S_cancel_tag;
    assign O_byte_valid=!I_reset && S_state==DELIVER && S_output_valid && !S_canceled[S_active] && !S_cancel_active;
    assign O_sector_last=S_out_index==511;
    assign O_request_last=O_sector_last && S_remaining[S_active]==1;
    assign O_byte_context=S_context[S_active];
    assign O_byte_tag=S_tag[S_active];
    assign O_done_valid=!I_reset && S_state==COMPLETE;
    assign O_done_context=S_context[S_active];
    assign O_done_tag=S_tag[S_active];
    assign O_done_error=S_complete_error;

    always @* begin
        S_free_found=0; S_pick_found=0; S_duplicate=0; S_cancel_live=0;
        S_free=0; S_pick=0; S_best_score=0; S_score=0; S_candidate=0;
        for(S_scan=0;S_scan<4;S_scan=S_scan+1) begin
            if(!S_valid[S_scan] && !S_free_found) begin S_free_found=1; S_free=S_scan; end
            if(S_valid[S_scan] && S_context[S_scan]==I_context && S_tag[S_scan]==I_tag) S_duplicate=1;
            if(S_valid[S_scan] && S_context[S_scan]==S_cancel_context && S_tag[S_scan]==S_cancel_tag) S_cancel_live=1;
            S_candidate=(S_round_robin+S_scan)&3;
            S_score={(S_context[S_candidate]<3 ? I_urgent_context[S_context[S_candidate]] : 1'b0),S_priority[S_candidate]};
            if(S_valid[S_candidate] && (!S_pick_found || S_score>S_best_score)) begin
                S_pick_found=1; S_pick=S_candidate; S_best_score=S_score;
            end
        end
    end
    always @* begin
        S_command_index=0; S_command_argument=0; S_command_crc=8'h01; S_response_bytes=1;
        if(S_read_command) begin
            S_command_index=17;
            S_command_argument=O_high_capacity ? S_lba[S_active] : S_lba[S_active]<<9;
        end else case(S_step)
            INIT_CMD0: begin S_command_index=0; S_command_crc=8'h95; end
            INIT_CMD8: begin S_command_index=8; S_command_argument=32'h1aa; S_command_crc=8'h87; S_response_bytes=5; end
            INIT_CMD55: S_command_index=55;
            INIT_ACMD41: begin S_command_index=41; S_command_argument=S_v2 ? 32'h40000000 : 0; end
            INIT_CMD58: begin S_command_index=58; S_response_bytes=5; end
            INIT_CMD16: begin S_command_index=16; S_command_argument=512; end
            INIT_CMD9: S_command_index=9;
            PROBE_CMD13: begin S_command_index=13; S_response_bytes=2; end
            default: S_command_index=0;
        endcase
    end
    sd_spi_phy #(.RESPONSE_TIMEOUT_CYCLES(RESPONSE_TIMEOUT_CYCLES),.TOKEN_TIMEOUT_CYCLES(TOKEN_TIMEOUT_CYCLES),
        .BUSY_TIMEOUT_CYCLES(BUSY_TIMEOUT_CYCLES),.STALL_TIMEOUT_CYCLES(STALL_TIMEOUT_CYCLES)) u_phy (
        .I_clk(I_clk),.I_reset(I_reset),.I_cmd_valid(S_state==COMMAND_SEND || S_state==READ_SEND),
        .O_cmd_ready(S_phy_cmd_ready),.I_cmd_index(S_command_index),.I_cmd_argument(S_command_argument),
        .I_cmd_crc(S_command_crc),.I_response_bytes(S_response_bytes),.I_block_count(8'd1),
        .I_divider((S_read_command || S_step==PROBE_CMD13) ? WORK_DIVIDER : INIT_DIVIDER),
        .I_tag(S_read_command ? S_tag[S_active] : 16'd0),.I_crc_check(1'b1),.I_abort(S_phy_abort),
        .I_idle_valid(S_state==CLOCK_START),.O_idle_ready(S_phy_idle_ready),.I_idle_bytes(8'd10),
        .O_response_valid(S_phy_response_valid),.I_response_ready(1'b1),.O_response_data(S_phy_response),
        .O_response_bytes(S_phy_response_count),.O_byte_valid(S_phy_byte_valid),.I_byte_ready(1'b1),
        .O_byte_data(S_phy_byte),.O_block_last(S_phy_block_last),.O_request_last(S_phy_request_last),
        .O_block_done(S_phy_block_done),.O_crc_ok(S_phy_crc_ok),.O_done(S_phy_done),
        .O_error(S_phy_error),.O_tag(S_phy_tag),.O_busy(S_phy_busy),
        .O_sd_ncs(O_sd_ncs),.O_sd_sclk(O_sd_sclk),.O_sd_mosi(O_sd_mosi),.I_sd_miso(I_sd_miso));

    task complete_active;
        input [3:0] error;
        begin S_complete_error<=error; S_state<=COMPLETE; S_output_valid<=0; end
    endtask
    task lose_card;
        input [3:0] error;
        begin O_card_ready<=0; O_card_error<=error; S_init_budget<=0; S_state<=SCHEDULE; end
    endtask
    task ready_card;
        begin
            O_card_ready<=1; O_card_error<=0; S_init_budget<=0; S_probe_age<=0; S_state<=SCHEDULE;
        end
    endtask

    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=POWER_WAIT; S_step<=INIT_CMD0; S_timer<=0; S_init_age<=0; S_probe_age<=0; S_delivery_age<=0;
            S_v2<=0; S_init_budget<=0; S_valid<=0; S_canceled<=0; S_active<=0; S_round_robin<=0;
            S_cancel_pending<=0; S_cancel_context<=0; S_cancel_tag<=0; O_cancel_done_valid<=0;
            S_write_count<=0; S_out_index<=0; S_block_good<=0; S_output_valid<=0; S_complete_error<=0;
            S_response<=0; O_byte_data<=0; O_card_ready<=0; O_high_capacity<=0; O_card_error<=0;
            O_capacity_sectors<=0; S_csd<=0; S_csd_count<=0; S_csd_good<=0;
            for(S_reset_index=0;S_reset_index<4;S_reset_index=S_reset_index+1) begin
                S_lba[S_reset_index]<=0; S_remaining[S_reset_index]<=0; S_context[S_reset_index]<=0;
                S_priority[S_reset_index]<=0; S_tag[S_reset_index]<=0; S_entry_error[S_reset_index]<=0;
            end
        end else begin
            if(S_init_budget && S_init_age<INIT_TIMEOUT_CYCLES) S_init_age<=S_init_age+32'd1;
            if(O_card_ready && S_probe_age<PROBE_CYCLES) S_probe_age<=S_probe_age+32'd1;
            if(S_phy_response_valid) S_response<=S_phy_response;
            if(S_state==COMMAND_WAIT && S_step==INIT_CMD9) begin
                if(S_phy_byte_valid) begin S_csd<={S_csd[119:0],S_phy_byte}; S_csd_count<=S_csd_count+5'd1; end
                if(S_phy_block_done) S_csd_good<=S_phy_crc_ok;
            end
            if(S_state==READ_WAIT && S_phy_byte_valid) begin
                S_sector[S_write_count[8:0]]<=S_phy_byte;
                S_write_count<=S_write_count+10'd1;
            end
            if(S_state==READ_WAIT && S_phy_block_done) S_block_good<=S_phy_crc_ok;
            if(I_request_valid && O_request_ready) begin
                S_valid[S_free]<=1; S_canceled[S_free]<=0; S_lba[S_free]<=I_lba;
                S_remaining[S_free]<=I_count; S_context[S_free]<=I_context; S_priority[S_free]<=I_priority;
                S_tag[S_free]<=I_tag; S_entry_error[S_free]<=S_bad_request ? 4'd7 : 4'd0;
            end
            if(S_cancel_accept) begin
                S_cancel_pending<=1; S_cancel_context<=I_cancel_context; S_cancel_tag<=I_cancel_tag;
                for(S_reset_index=0;S_reset_index<4;S_reset_index=S_reset_index+1)
                    if(S_valid[S_reset_index] && S_context[S_reset_index]==I_cancel_context && S_tag[S_reset_index]==I_cancel_tag)
                        S_canceled[S_reset_index]<=1;
            end
            if(S_cancel_pending && !S_cancel_live && !O_cancel_done_valid) O_cancel_done_valid<=1;
            if(O_cancel_done_valid && I_cancel_done_ready) begin O_cancel_done_valid<=0; S_cancel_pending<=0; end
            case(S_state)
                POWER_WAIT: if(S_timer>=POWERUP_CYCLES-1) begin S_timer<=0; S_state<=CLOCK_START; end
                    else S_timer<=S_timer+32'd1;
                CLOCK_START: if(S_phy_idle_ready) S_state<=CLOCK_WAIT;
                CLOCK_WAIT: if(S_phy_done) begin
                    if(S_phy_error!=0) lose_card(S_phy_error);
                    else begin S_step<=INIT_CMD0; S_state<=COMMAND_SEND; end
                end
                COMMAND_SEND: if(S_phy_cmd_ready) S_state<=COMMAND_WAIT;
                COMMAND_WAIT: if(S_phy_done) begin
                    if(S_phy_error!=0) lose_card(S_phy_error);
                    else if(S_init_budget && S_init_age>=INIT_TIMEOUT_CYCLES) lose_card(4'd10);
                    else case(S_step)
                        INIT_CMD0: if(S_response[7:0]!=1) lose_card(4'd5);
                            else begin S_step<=INIT_CMD8; S_state<=COMMAND_SEND; end
                        INIT_CMD8: begin
                            if(S_response[7:0]==5) begin S_v2<=0; S_step<=INIT_CMD55; S_state<=COMMAND_SEND; S_init_budget<=1; S_init_age<=0; end
                            else if(S_response[7:0]==1 && S_response[39:24]==16'haa01 && S_response[23:8]==0) begin
                                S_v2<=1; S_step<=INIT_CMD55; S_state<=COMMAND_SEND; S_init_budget<=1; S_init_age<=0;
                            end else lose_card(4'd5);
                        end
                        INIT_CMD55: if(S_response[7:0]>1) lose_card(4'd5);
                            else begin S_step<=INIT_ACMD41; S_state<=COMMAND_SEND; end
                        INIT_ACMD41: if(S_response[7:0]==0) begin S_step<=INIT_CMD58; S_state<=COMMAND_SEND; end
                            else if(S_response[7:0]==1) begin S_timer<=0; S_state<=POLL_DELAY; end
                            else lose_card(4'd5);
                        INIT_CMD58: begin
                            if(S_response[7:0]!=0 || !S_ocr[31] || S_ocr[23:15]==0) lose_card(4'd5);
                            else begin
                                O_high_capacity<=S_v2 && S_ocr[30];
                                if(S_v2 && S_ocr[30]) begin S_step<=INIT_CMD9; S_state<=COMMAND_SEND; S_csd_count<=0; S_csd_good<=0; end
                                else begin S_step<=INIT_CMD16; S_state<=COMMAND_SEND; end
                            end
                        end
                        INIT_CMD16: if(S_response[7:0]!=0) lose_card(4'd5);
                            else begin S_step<=INIT_CMD9; S_state<=COMMAND_SEND; S_csd_count<=0; S_csd_good<=0; end
                        INIT_CMD9: if(S_response[7:0]!=0 || S_csd_count!=16 || !S_csd_good || !S_csd_valid) lose_card(4'd5);
                            else begin O_capacity_sectors<=S_capacity_sectors; ready_card; end
                        PROBE_CMD13: if(S_response[15:0]!=0) lose_card(4'd5); else S_state<=SCHEDULE;
                        default: lose_card(4'd5);
                    endcase
                end
                POLL_DELAY: if(S_init_age>=INIT_TIMEOUT_CYCLES) lose_card(4'd10);
                    else if(S_timer>=INIT_POLL_CYCLES-1) begin S_step<=INIT_CMD55; S_state<=COMMAND_SEND; S_timer<=0; end
                    else S_timer<=S_timer+32'd1;
                SCHEDULE: begin
                    if(S_pick_found) begin
                        S_active<=S_pick; S_round_robin<=S_pick+2'd1;
                        if(S_canceled[S_pick]) begin S_complete_error<=6; S_state<=COMPLETE; end
                        else if(!O_card_ready) begin S_complete_error<=11; S_state<=COMPLETE; end
                        else if(S_entry_error[S_pick]!=0) begin S_complete_error<=S_entry_error[S_pick]; S_state<=COMPLETE; end
                        else begin S_write_count<=0; S_block_good<=0; S_state<=READ_SEND; end
                    end else if(!O_card_ready) begin S_timer<=0; S_state<=RETRY; end
                    else if(S_probe_age>=PROBE_CYCLES-1 && !(I_request_valid && O_request_ready)) begin
                        S_probe_age<=0; S_step<=PROBE_CMD13; S_state<=COMMAND_SEND;
                    end
                end
                READ_SEND: if(S_canceled[S_active] || S_cancel_active) complete_active(4'd6);
                    else if(S_phy_cmd_ready) S_state<=READ_WAIT;
                READ_WAIT: if(S_phy_done) begin
                    if(S_phy_error!=0 && S_phy_error!=6) begin
                        O_card_ready<=0; O_card_error<=S_phy_error;
                    end
                    if(S_canceled[S_active] || S_cancel_active || S_phy_error==6) complete_active(4'd6);
                    else if(S_phy_error!=0) begin
                        O_card_ready<=0; O_card_error<=S_phy_error; complete_active(S_phy_error);
                    end else if(S_write_count!=512 || !S_block_good) begin
                        O_card_ready<=0; O_card_error<=5; complete_active(4'd5);
                    end else begin S_out_index<=0; S_output_valid<=0; S_delivery_age<=0; S_state<=DELIVER; end
                end
                DELIVER: begin
                    if(S_canceled[S_active] || S_cancel_active) complete_active(4'd6);
                    else if(!S_output_valid) begin O_byte_data<=S_sector[0]; S_output_valid<=1; end
                    else if(O_byte_valid && I_byte_ready) begin
                        S_delivery_age<=0;
                        if(S_out_index==511) begin
                            S_output_valid<=0;
                            if(S_remaining[S_active]==1) complete_active(4'd0);
                            else begin
                                S_remaining[S_active]<=S_remaining[S_active]-8'd1;
                                S_lba[S_active]<=S_lba[S_active]+32'd1; S_state<=SCHEDULE;
                            end
                        end else begin
                            S_out_index<=S_out_index+9'd1; O_byte_data<=S_sector[S_out_index+9'd1];
                        end
                    end else if(S_delivery_age>=DELIVERY_TIMEOUT_CYCLES-1) complete_active(4'd8);
                    else S_delivery_age<=S_delivery_age+32'd1;
                end
                COMPLETE: if(I_done_ready) begin S_valid[S_active]<=0; S_canceled[S_active]<=0; S_state<=SCHEDULE; end
                RETRY: if(S_timer>=RETRY_CYCLES-1) begin S_timer<=0; S_state<=POWER_WAIT; S_step<=INIT_CMD0; O_high_capacity<=0; end
                    else S_timer<=S_timer+32'd1;
                default: lose_card(4'd5);
            endcase
        end
    end
endmodule
