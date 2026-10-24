// Three checked clients, private synchronous sector snapshots, one sector_port.
// Never multiplex only the command: FAT walkers may still be reading old RAM.
// Client 0 is the low slice. Each client owns its RAM until its NEXT request.
module fat32_sector_arbiter (
    input wire I_clk,I_reset,I_card_ready,
    input wire [2:0] I_read_valid,
    output reg [2:0] O_read_ready,
    input wire [95:0] I_read_lba,
    input wire [5:0] I_context,I_priority,
    input wire [2:0] I_urgent,I_abort,
    output reg [2:0] O_result_valid,
    input wire [2:0] I_result_ready,
    output reg [23:0] O_error,
    output reg [11:0] O_storage_error,
    input wire [26:0] I_buffer_address,
    output reg [23:0] O_buffer_data,
    output wire O_port_valid,
    input wire I_port_ready,
    output wire [31:0] O_port_lba,
    output wire [1:0] O_port_context,O_port_priority,
    output wire O_port_abort,
    input wire I_port_result_valid,
    output wire O_port_result_ready,
    input wire [7:0] I_port_error,
    input wire [3:0] I_port_storage_error,
    output wire [8:0] O_port_buffer_address,
    input wire [7:0] I_port_buffer_data
);
    localparam [2:0] IDLE=0,SEND=1,WAIT_RESULT=2,COPY_PRIME=3,COPY_BYTE=4,RELEASE=5;
    reg [2:0] S_state;
    reg [1:0] S_owner,S_rr,S_pick;
    reg [31:0] S_lba;
    reg [1:0] S_context,S_priority;
    reg S_canceled,S_lost,S_found;
    reg [2:0] S_best,S_score;
    reg [8:0] S_copy;
    reg [7:0] S_error;
    reg [3:0] S_storage_error;
    reg [7:0] S_ram0[0:511],S_ram1[0:511],S_ram2[0:511];
    integer S_i,S_candidate;
    wire S_cancel=S_canceled || I_abort[S_owner];
    wire S_invalid=S_lost || !I_card_ready;

    always @* begin
        S_found=0; S_pick=0; S_best=0; S_score=0; S_candidate=0; O_read_ready=0;
        for(S_i=0;S_i<3;S_i=S_i+1) begin
            S_candidate=S_rr+S_i;
            if(S_candidate>=3) S_candidate=S_candidate-3;
            S_score={I_urgent[S_candidate],I_priority[S_candidate*2+:2]};
            if(I_read_valid[S_candidate] && !O_result_valid[S_candidate] && (!S_found || S_score>S_best)) begin
                S_found=1; S_pick=S_candidate; S_best=S_score;
            end
        end
        if(!I_reset && S_state==IDLE && S_found) O_read_ready[S_pick]=1;
    end
    assign O_port_valid=!I_reset && S_state==SEND && !S_cancel && !S_invalid;
    assign O_port_lba=S_lba;
    assign O_port_context=S_context;
    assign O_port_priority=S_priority;
    assign O_port_abort=!I_reset && S_state!=IDLE && S_state!=SEND && (S_cancel || S_invalid);
    // Hold the successful port result throughout synchronous RAM copying.
    assign O_port_result_ready=!I_reset && S_state==RELEASE;
    // PRIME fetches byte 0. COPY_BYTE writes the previous synchronous fetch
    // while prefetching the next address, for 512 consecutive copy cycles.
    assign O_port_buffer_address=S_state==COPY_BYTE && S_copy!=511 ? S_copy+9'd1 : S_copy;
    always @(posedge I_clk) begin
        O_buffer_data[7:0]<=S_ram0[I_buffer_address[8:0]];
        O_buffer_data[15:8]<=S_ram1[I_buffer_address[17:9]];
        O_buffer_data[23:16]<=S_ram2[I_buffer_address[26:18]];
        if(!I_reset && S_state==COPY_BYTE && !S_cancel && !S_invalid) begin
            case(S_owner)
                0:S_ram0[S_copy]<=I_port_buffer_data;
                1:S_ram1[S_copy]<=I_port_buffer_data;
                2:S_ram2[S_copy]<=I_port_buffer_data;
                default:begin end
            endcase
        end
    end
    task publish;
        input [7:0] error_code;
        input [3:0] storage_error;
        begin
            O_result_valid[S_owner]<=1; O_error[S_owner*8+:8]<=error_code;
            O_storage_error[S_owner*4+:4]<=storage_error; S_state<=IDLE;
        end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_owner<=0; S_rr<=0; S_lba<=0; S_context<=0; S_priority<=0;
            S_canceled<=0; S_lost<=0; S_copy<=0; S_error<=0; S_storage_error<=0;
            O_result_valid<=0; O_error<=0; O_storage_error<=0;
        end else begin
            O_result_valid<=O_result_valid & ~I_result_ready;
            if(S_state!=IDLE) begin
                if(I_abort[S_owner]) S_canceled<=1;
                if(!I_card_ready) S_lost<=1;
            end
            case(S_state)
                IDLE: if(S_found) begin
                    S_owner<=S_pick; S_rr<=S_pick==2 ? 2'd0 : S_pick+2'd1;
                    S_lba<=I_read_lba[S_pick*32+:32]; S_context<=I_context[S_pick*2+:2];
                    S_priority<=I_priority[S_pick*2+:2]; S_canceled<=I_abort[S_pick]; S_lost<=!I_card_ready;
                    S_error<=0; S_storage_error<=0; S_copy<=0; S_state<=SEND;
                end
                SEND: begin
                    if(S_invalid) publish(8'd1,4'd0);
                    else if(S_cancel) publish(8'd8,4'd0);
                    else if(I_port_ready) S_state<=WAIT_RESULT;
                end
                WAIT_RESULT: if(I_port_result_valid) begin
                    S_error<=I_port_error; S_storage_error<=I_port_storage_error; S_copy<=0;
                    if(S_invalid || S_cancel || I_port_error!=0) S_state<=RELEASE;
                    else S_state<=COPY_PRIME;
                end
                COPY_PRIME: begin
                    if(S_invalid || S_cancel) S_state<=RELEASE;
                    else S_state<=COPY_BYTE;
                end
                COPY_BYTE: begin
                    if(S_invalid || S_cancel || S_copy==511) S_state<=RELEASE;
                    else S_copy<=S_copy+9'd1;
                end
                RELEASE: if(I_port_result_valid) begin
                    if(S_invalid) publish(8'd1,S_storage_error);
                    else if(S_cancel) publish(8'd8,S_storage_error);
                    else publish(S_error,S_storage_error);
                end
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
