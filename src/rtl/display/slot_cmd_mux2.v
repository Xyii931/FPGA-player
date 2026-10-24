// Two command owners -> one existing slot-arbiter client. All ports host-domain.
// Captures a complete command before admission; a real result retires ownership.
module slot_cmd_mux2 (
    input wire I_clk,I_reset,
    input wire [1:0] I_client_valid,
    output reg [1:0] O_client_ready,
    input wire [229:0] I_client_command,
    output wire [1:0] O_client_result_valid,
    input wire [1:0] I_client_result_ready,
    output wire [96:0] O_client_result,
    output wire O_cmd_valid,
    input wire I_cmd_ready,
    output wire [114:0] O_command,
    input wire I_result_valid,
    output wire O_result_ready,
    input wire [96:0] I_result,
    output wire O_busy
);
    localparam [1:0] IDLE=0,SEND=1,RESULT=2;
    reg [1:0] S_state;
    reg S_client;
    reg [114:0] S_command;
    wire S_choice=I_client_valid[1];
    always @* begin
        O_client_ready=0;
        if(!I_reset && S_state==IDLE && |I_client_valid) O_client_ready[S_choice]=1;
    end
    assign O_cmd_valid=!I_reset && S_state==SEND;
    assign O_command=S_command;
    assign O_client_result=I_result;
    assign O_client_result_valid={2{!I_reset && S_state==RESULT && I_result_valid}} & (2'b01<<S_client);
    assign O_result_ready=!I_reset && S_state==RESULT && I_client_result_ready[S_client];
    assign O_busy=S_state!=IDLE;
    always @(posedge I_clk) begin
        if(I_reset) begin S_state<=IDLE; S_client<=0; S_command<=0; end
        else case(S_state)
            IDLE:if(|(I_client_valid & O_client_ready)) begin
                S_client<=S_choice; S_command<=I_client_command[S_choice*115+:115]; S_state<=SEND;
            end
            SEND:if(I_cmd_ready) S_state<=RESULT;
            RESULT:if(I_result_valid && O_result_ready) S_state<=IDLE;
            default:S_state<=IDLE;
        endcase
    end
endmodule
