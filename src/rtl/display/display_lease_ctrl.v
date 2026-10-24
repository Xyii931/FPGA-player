// Physical reader owners 0/1; role rotation leaves the current source locked.
// All signals are host-domain. Retirement/idle/permit must be real authorizations.
module display_lease_ctrl (
    input wire I_clk,I_reset,I_start_valid,
    output wire O_start_ready,
    input wire I_op,I_source,
    input wire [2:0] I_slot,
    input wire [31:0] I_token,I_generation,
    input wire [15:0] I_tag,
    input wire I_abort,
    input wire [1:0] I_source_idle,I_acquire_permit,I_retire_ack,
    output reg [1:0] O_retire_request,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,O_slot_error,
    output reg O_op,O_source,
    output reg [2:0] O_slot,
    output reg [31:0] O_token,O_generation,
    output reg [15:0] O_tag,
    output reg O_changed,O_cancel_late,O_quarantined,O_response_discarded,
    output wire [1:0] O_owned,O_lease_valid,
    output wire [5:0] O_lease_slots,
    output wire [63:0] O_lease_tokens,O_lease_generations,
    output wire [1:0] O_lease_resident,
    input wire [17:0] I_slot_states,I_slot_readers,
    input wire [191:0] I_slot_tokens,I_slot_generations,
    input wire [5:0] I_slot_resident,
    output wire O_slot_cmd_valid,
    input wire I_slot_cmd_ready,
    output wire [2:0] O_slot_cmd_op,O_slot_cmd_slot,
    output wire [1:0] O_slot_cmd_owner,
    output wire [31:0] O_slot_cmd_token,O_slot_cmd_generation,
    output wire O_slot_frame_boundary,O_slot_reader_retired,
    input wire I_slot_result_valid,
    output wire O_slot_result_ready,
    input wire [3:0] I_slot_result_error,
    input wire [2:0] I_slot_result_op,I_slot_result_slot,
    input wire [1:0] I_slot_result_owner,
    input wire [31:0] I_slot_result_token,I_slot_result_generation,
    input wire [20:0] I_slot_result_base
);
    localparam [2:0] IDLE=0,PERMIT=1,ACK_ZERO=2,RETIRE=3,SEND=4,REPLY=5,CLEAR=6,RESULT=7;
    reg [2:0] S_state;
    reg [1:0] S_owned,S_resident;
    reg [2:0] S_slots[0:1];
    reg [31:0] S_tokens[0:1],S_generations[0:1];
    reg [1:0] S_actual;
    reg [1:0] S_orphan;
    reg S_committed,S_authority_lost,S_cancel;
    wire S_transaction=S_state!=IDLE && S_state!=RESULT;
    wire [1:0] S_release_mask=O_op && (S_state==SEND || S_state==REPLY) ? (2'b01<<O_source) : 2'b00;
    wire S_live_fault=|(S_owned & ~S_actual & ~S_release_mask) || |S_orphan;
    wire S_isolated=O_quarantined || S_live_fault;
    wire S_lost=S_authority_lost || (S_transaction && S_committed && !I_source_idle[O_source]);
    function [20:0] slot_base;
        input [2:0] slot;
        begin case(slot)
            0:slot_base=21'h000000; 1:slot_base=21'h04b000; 2:slot_base=21'h096000;
            3:slot_base=21'h0e1000; 4:slot_base=21'h12c000; 5:slot_base=21'h177000;
            default:slot_base=0;
        endcase end
    endfunction
    wire S_result_match=I_slot_result_op==O_slot_cmd_op && I_slot_result_slot==O_slot &&
        I_slot_result_owner=={1'b0,O_source} && I_slot_result_token==O_token &&
        I_slot_result_generation==O_generation && I_slot_result_base==slot_base(O_slot);
    wire S_reply=I_slot_result_valid && O_slot_result_ready && S_result_match;
    wire S_expected_reference=O_slot<6 && I_slot_states[O_slot*3+:3]==3 &&
        I_slot_readers[O_slot*3+O_source] && I_slot_tokens[O_slot*32+:32]==O_token &&
        I_slot_generations[O_slot*32+:32]==O_generation;
    wire S_release_gone=O_slot<6 && !I_slot_readers[O_slot*3+O_source];
    assign O_start_ready=!I_reset && S_state==IDLE && !S_isolated;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_busy=S_state!=IDLE || O_quarantined;
    assign O_owned=S_owned;
    assign O_lease_valid=S_owned & S_actual & {2{!I_reset}};
    assign O_lease_slots={S_slots[1],S_slots[0]};
    assign O_lease_tokens={S_tokens[1],S_tokens[0]};
    assign O_lease_generations={S_generations[1],S_generations[0]};
    assign O_lease_resident=S_resident;
    assign O_slot_cmd_valid=!I_reset && S_state==SEND;
    assign O_slot_cmd_op=O_op ? 3'd3 : 3'd2;
    assign O_slot_cmd_slot=O_slot;
    assign O_slot_cmd_owner={1'b0,O_source};
    assign O_slot_cmd_token=O_token;
    assign O_slot_cmd_generation=O_generation;
    assign O_slot_frame_boundary=!O_op && S_committed;
    assign O_slot_reader_retired=O_op && O_retire_request[O_source] && I_retire_ack[O_source];
    assign O_slot_result_ready=!I_reset && S_state==REPLY;
    integer C_i,C_s;
    always @* begin
        S_actual=0;
        S_orphan=0;
        for(C_i=0;C_i<2;C_i=C_i+1)
            if(S_slots[C_i]<6 && I_slot_states[S_slots[C_i]*3+:3]==3 &&
                I_slot_readers[S_slots[C_i]*3+C_i] && I_slot_tokens[S_slots[C_i]*32+:32]==S_tokens[C_i] &&
                I_slot_generations[S_slots[C_i]*32+:32]==S_generations[C_i] &&
                I_slot_resident[S_slots[C_i]]==S_resident[C_i]) S_actual[C_i]=1;
        for(C_i=0;C_i<2;C_i=C_i+1)
            for(C_s=0;C_s<6;C_s=C_s+1)
                if(I_slot_readers[C_s*3+C_i] &&
                    !(S_owned[C_i] && S_slots[C_i]==C_s) &&
                    !(!O_op && O_source==C_i && O_slot==C_s && (S_state==SEND || S_state==REPLY))) S_orphan[C_i]=1;
    end
    integer S_i;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_owned<=0; S_resident<=0; S_committed<=0; S_authority_lost<=0; S_cancel<=0;
            O_retire_request<=0; O_error<=0; O_slot_error<=0; O_op<=0; O_source<=0;
            O_slot<=0; O_token<=0; O_generation<=0; O_tag<=0;
            O_changed<=0; O_cancel_late<=0; O_quarantined<=0; O_response_discarded<=0;
            for(S_i=0;S_i<2;S_i=S_i+1) begin S_slots[S_i]<=0; S_tokens[S_i]<=0; S_generations[S_i]<=0; end
        end else begin
            O_response_discarded<=I_slot_result_valid && O_slot_result_ready && !S_result_match;
            if(S_live_fault) begin O_quarantined<=1; if(S_transaction && !S_lost) O_error<=8; end
            if(S_transaction && S_committed && !I_source_idle[O_source]) begin
                S_authority_lost<=1; O_quarantined<=1; O_error<=6;
            end
            if(S_transaction && S_committed && I_abort) begin S_cancel<=1; O_cancel_late<=1; end
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    O_op<=I_op; O_source<=I_source; O_slot<=I_slot; O_token<=I_token; O_generation<=I_generation; O_tag<=I_tag;
                    O_error<=0; O_slot_error<=0; O_changed<=0; O_cancel_late<=0;
                    S_committed<=0; S_authority_lost<=0; S_cancel<=0;
                    if(I_slot>=6 || I_token==0) begin O_error<=1; S_state<=RESULT; end
                    else if(!I_source_idle[I_source] || (!I_op && S_owned[I_source]) || (I_op && !S_owned[I_source])) begin
                        O_error<=2; S_state<=RESULT;
                    end else if(I_op && (I_slot!=S_slots[I_source] || I_token!=S_tokens[I_source] || I_generation!=S_generations[I_source])) begin
                        O_error<=3; S_state<=RESULT;
                    end else if(I_abort) begin O_error<=5; S_state<=RESULT; end
                    else S_state<=I_op ? ACK_ZERO : PERMIT;
                end
                PERMIT:begin
                    if(I_abort) begin O_error<=5; S_state<=RESULT; end
                    else if(!I_source_idle[O_source]) begin O_error<=2; S_state<=RESULT; end
                    else if(S_isolated) begin O_error<=8; S_state<=RESULT; end
                    else if(I_acquire_permit[O_source]) begin S_committed<=1; S_state<=SEND; end
                end
                ACK_ZERO:begin
                    if(I_abort) begin O_error<=5; S_state<=RESULT; end
                    else if(!I_source_idle[O_source]) begin O_error<=2; S_state<=RESULT; end
                    else if(S_isolated) begin O_error<=8; S_state<=RESULT; end
                    else if(!I_retire_ack[O_source]) begin
                        O_retire_request[O_source]<=1; S_committed<=1; S_state<=RETIRE;
                    end
                end
                RETIRE:if(I_retire_ack[O_source]) begin
                    if(S_lost || S_isolated) begin
                        O_error<=S_lost ? 4'd6 : 4'd8; O_retire_request[O_source]<=0; S_state<=CLEAR;
                    end else S_state<=SEND;
                end
                SEND:if(I_slot_cmd_ready) S_state<=REPLY;
                REPLY:if(S_reply) begin
                    O_slot_error<=I_slot_result_error;
                    if(I_slot_result_error!=0) O_error<=S_lost ? 4'd6 : S_isolated ? 4'd8 : 4'd4;
                    else if(!O_op) begin
                        // A late cancel does not erase the real newly acquired reference.
                        S_owned[O_source]<=1; S_slots[O_source]<=O_slot;
                        S_tokens[O_source]<=O_token; S_generations[O_source]<=O_generation;
                        S_resident[O_source]<=I_slot_resident[O_slot]; O_changed<=1;
                        if(!S_expected_reference) begin O_error<=8; O_quarantined<=1; end
                        else O_error<=S_lost ? 4'd6 : S_isolated ? 4'd8 :
                            S_cancel || I_abort ? 4'd5 : 4'd0;
                    end else if(!S_release_gone) begin O_error<=8; O_quarantined<=1; end
                    else begin
                        S_owned[O_source]<=0; O_changed<=1;
                        O_error<=S_lost ? 4'd6 : S_isolated ? 4'd8 : 4'd0;
                    end
                    if(O_op) begin O_retire_request[O_source]<=0; S_state<=CLEAR; end
                    else S_state<=RESULT;
                end
                CLEAR:if(!I_retire_ack[O_source]) S_state<=RESULT;
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
