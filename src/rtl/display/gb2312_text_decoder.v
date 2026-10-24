// Bounded byte string -> text cells. Invalid GB trail bytes are reprocessed.
module gb2312_text_decoder (
    input wire I_clk,I_reset,I_start_valid,
    output wire O_start_ready,
    input wire [5:0] I_length,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,I_abort,
    output reg O_valid,
    input wire I_ready,
    output reg [15:0] O_cell,
    output reg O_last,
    output wire O_busy,
    output reg O_done,
    output reg [1:0] O_error,
    output reg [5:0] O_warnings
);
    localparam [2:0] IDLE=0,BYTES=1,REPLAY=2,TRAIL=3,DRAIN=4,FINISH=5;
    reg [2:0] S_state;
    reg [5:0] S_length,S_count;
    reg S_lead_valid,S_saved_last;
    reg [7:0] S_lead,S_saved;
    wire S_room=!O_valid || I_ready;
    wire S_process=S_state==REPLAY || (S_state==BYTES && I_byte_valid && O_byte_ready);
    wire [7:0] S_byte=S_state==REPLAY ? S_saved : I_byte_data;
    wire S_last=S_state==REPLAY ? S_saved_last : S_count+6'd1==S_length;
    wire S_gb_byte=S_byte>=8'ha1 && S_byte<=8'hfe;
    wire [13:0] S_slot=({6'd0,S_lead}-14'd161)*14'd94+({6'd0,S_byte}-14'd161);
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_byte_ready=!I_reset && S_state==BYTES && S_room && !I_abort;
    assign O_busy=S_state!=IDLE;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_length<=0; S_count<=0; S_lead_valid<=0; S_saved_last<=0;
            S_lead<=0; S_saved<=0; O_valid<=0; O_cell<=0; O_last<=0; O_done<=0; O_error<=0; O_warnings<=0;
        end else begin
            O_done<=0;
            if(O_valid && I_ready) O_valid<=0;
            if(O_busy && S_state!=FINISH && I_abort) begin O_valid<=0; O_error<=2; S_state<=FINISH; end
            else begin
                case(S_state)
                    IDLE:if(I_start_valid) begin
                        S_length<=I_length; S_count<=0; S_lead_valid<=0; O_valid<=0; O_last<=0;
                        O_error<=I_length>40 ? 2'd1 : 2'd0; O_warnings<=0;
                        S_state<=I_length==0 || I_length>40 ? FINISH : BYTES;
                    end
                    TRAIL:if(S_room) begin
                        O_valid<=1; O_cell<=16'h003f; O_last<=1; O_warnings<=O_warnings+1'b1;
                        S_lead_valid<=0; S_state<=DRAIN;
                    end
                    DRAIN:if(!O_valid || I_ready) S_state<=FINISH;
                    FINISH:begin O_done<=1; S_state<=IDLE; end
                    default:begin end
                endcase
                if(S_process && S_room) begin
                    if(S_state==BYTES && I_byte_last!=S_last) begin
                        O_valid<=0; O_error<=1; S_state<=FINISH;
                    end else begin
                        if(S_state==BYTES) S_count<=S_count+1'b1;
                        S_state<=S_last ? DRAIN : BYTES;
                        if(S_lead_valid) begin
                            S_lead_valid<=0; O_valid<=1;
                            if(S_gb_byte) begin O_cell<={2'b10,S_slot}; O_last<=S_last; end
                            else begin
                                O_cell<=16'h003f; O_last<=0; O_warnings<=O_warnings+1'b1;
                                S_saved<=S_byte; S_saved_last<=S_last; S_state<=REPLAY;
                            end
                        end else if(S_byte>=8'h20 && S_byte<=8'h7e) begin
                            O_cell<={8'd0,S_byte}; O_valid<=1; O_last<=S_last;
                        end else if(S_gb_byte) begin
                            S_lead<=S_byte; S_lead_valid<=1;
                            if(S_last) S_state<=TRAIL;
                        end else begin
                            O_cell<=16'h003f; O_valid<=1; O_last<=S_last; O_warnings<=O_warnings+1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule
