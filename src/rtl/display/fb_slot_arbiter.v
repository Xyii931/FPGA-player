// Three host-domain slot clients; immutable accepted commands, one real result.
// Retired/frame promises must remain valid until the client's result is consumed.
module fb_slot_arbiter (
    input wire I_clk,I_reset,
    input wire [5:0] I_pinned_slots,
    input wire [2:0] I_client_valid,
    output reg [2:0] O_client_ready,
    input wire [344:0] I_client_command,
    output wire [2:0] O_client_result_valid,
    input wire [2:0] I_client_result_ready,
    output wire [96:0] O_client_result,
    output wire O_cmd_valid,
    input wire I_cmd_ready,
    output wire [114:0] O_cmd,
    input wire I_result_valid,
    output wire O_result_ready,
    input wire [96:0] I_result,
    output reg [5:0] O_mutating_slots,
    output wire O_busy,
    output reg O_contract_fault,O_response_discarded
);
    localparam [1:0] IDLE=0,SEND=1,WAIT_RESULT=2,RESULT=3;
    reg [1:0] S_state,S_client,S_next;
    reg [114:0] S_command;
    reg [96:0] S_result;
    reg S_rejected;
    reg C_found;
    reg [2:0] C_eligible;
    reg [2:0] C_grant,C_rejected;
    reg [17:0] C_mutations;
    reg [1:0] C_choice;
    reg [114:0] C_command,C_candidate;
    integer C_i;
    wire [2:0] S_op=S_command[114:112],S_slot=S_command[111:109];
    wire S_mutates=S_op==0 || S_op==4;
    wire S_match=I_result[92:90]==S_op && I_result[89:87]==S_slot &&
        I_result[86:85]==S_command[108:107] && I_result[52:21]==S_command[74:43] &&
        ((S_op==0 && I_result[96:93]==0) ? I_result[84:53]!=0 : I_result[84:53]==S_command[106:75]);
    always @* begin
        // Check fixed client slices first; rotate only the three eligibility bits.
        // A dynamic integer offset here expands three wide command multiplexers.
        C_found=0; C_choice=0; C_command=0; C_candidate=0; C_eligible=0;
        C_grant=0; C_rejected=0; C_mutations=0;
        for(C_i=0;C_i<3;C_i=C_i+1) begin
            C_candidate=I_client_command[C_i*115+:115];
            C_eligible[C_i]=I_client_valid[C_i] &&
                (C_candidate[114:112]!=1 || (C_candidate[3] && C_candidate[2])) &&
                (C_candidate[114:112]!=2 || C_candidate[108:107]>=2 || C_candidate[0]) &&
                (C_candidate[114:112]!=3 || C_candidate[1]);
            if((C_candidate[114:112]==0 || C_candidate[114:112]==4) && C_candidate[111:109]<6) begin
                C_rejected[C_i]=I_pinned_slots[C_candidate[111:109]];
                C_mutations[C_i*6+:6]=6'b000001<<C_candidate[111:109];
            end
        end
        C_found=|C_eligible;
        case(S_next)
            0:if(C_eligible[0]) C_choice=0;
                else if(C_eligible[1]) C_choice=1; else C_choice=2;
            1:if(C_eligible[1]) C_choice=1;
                else if(C_eligible[2]) C_choice=2; else C_choice=0;
            default:if(C_eligible[2]) C_choice=2;
                else if(C_eligible[0]) C_choice=0; else C_choice=1;
        endcase
        case(C_choice)
            0:C_command=I_client_command[114:0];
            1:C_command=I_client_command[229:115];
            default:C_command=I_client_command[344:230];
        endcase
        if(C_found) C_grant=3'b001<<C_choice;
        O_client_ready=0;
        if(!I_reset && S_state==IDLE && !O_contract_fault) O_client_ready=C_grant;
        O_mutating_slots=0;
        // Include admission on this edge, not only the registered request.
        if(S_state!=IDLE && !S_rejected && S_mutates && S_slot<6) O_mutating_slots[S_slot]=1;
        for(C_i=0;C_i<3;C_i=C_i+1)
            if(O_client_ready[C_i] && !C_rejected[C_i])
                O_mutating_slots=O_mutating_slots | C_mutations[C_i*6+:6];
    end
    assign O_cmd_valid=!I_reset && S_state==SEND;
    assign O_cmd=S_command;
    assign O_result_ready=!I_reset && S_state==WAIT_RESULT;
    assign O_client_result_valid=(!I_reset && S_state==RESULT) ? (3'b001<<S_client) : 3'b000;
    assign O_client_result=S_result;
    assign O_busy=S_state!=IDLE || O_contract_fault;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_client<=0; S_next<=0; S_command<=0; S_result<=0; S_rejected<=0;
            O_contract_fault<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            case(S_state)
                IDLE:if(|O_client_ready) begin
                    S_client<=C_choice; S_command<=C_command; S_rejected<=0;
                    if(|(C_grant & C_rejected)) begin
                        S_rejected<=1;
                        S_result<={4'd2,C_command[114:107],C_command[106:75],C_command[74:43],21'd0};
                        S_state<=RESULT;
                    end else S_state<=SEND;
                end
                SEND:if(I_cmd_ready) S_state<=WAIT_RESULT;
                WAIT_RESULT:if(I_result_valid) begin
                    if(!S_match) begin O_contract_fault<=1; O_response_discarded<=1; end
                    else begin S_result<=I_result; S_state<=RESULT; end
                end
                RESULT:if(I_client_result_ready[S_client]) begin
                    S_next<=S_client==2 ? 2'd0 : S_client+1'b1; S_state<=IDLE;
                end
                default:begin O_contract_fault<=1; end
            endcase
        end
    end
endmodule
