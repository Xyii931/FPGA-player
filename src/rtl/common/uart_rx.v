// UART 8N1. One-cycle valid/error pulses; no wire-level flow control.
module uart_rx #(
    parameter integer CLOCK_HZ=125000000,BAUD=115200
) (
    input wire I_clk,I_reset,I_rx,
    output reg O_valid,O_frame_error,
    output reg [7:0] O_data
);
    localparam integer DIVISOR=(CLOCK_HZ+BAUD/2)/BAUD;
    localparam [2:0] IDLE=0,START=1,DATA=2,STOP=3,RECOVER=4;
    reg S_meta,S_sync;
    reg [2:0] S_state,S_bit;
    reg [31:0] S_count;
    reg [7:0] S_data;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_meta<=1; S_sync<=1; S_state<=IDLE; S_bit<=0; S_count<=0;
            S_data<=0; O_data<=0; O_valid<=0; O_frame_error<=0;
        end else begin
            S_meta<=I_rx; S_sync<=S_meta; O_valid<=0; O_frame_error<=0;
            case(S_state)
                IDLE:if(!S_sync) begin S_count<=DIVISOR/2-1; S_state<=START; end
                START:if(S_count!=0) S_count<=S_count-1'b1;
                    else if(S_sync) S_state<=IDLE;
                    else begin S_count<=DIVISOR-1; S_bit<=0; S_state<=DATA; end
                DATA:if(S_count!=0) S_count<=S_count-1'b1;
                    else begin
                        S_data[S_bit]<=S_sync; S_count<=DIVISOR-1;
                        if(S_bit==7) S_state<=STOP; else S_bit<=S_bit+1'b1;
                    end
                STOP:if(S_count!=0) S_count<=S_count-1'b1;
                    else if(S_sync) begin O_data<=S_data; O_valid<=1; S_state<=IDLE; end
                    else begin O_frame_error<=1; S_state<=RECOVER; end
                RECOVER:if(S_sync) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
    // synthesis translate_off
    initial if(BAUD<1 || DIVISOR<8) begin $display("FAIL: uart_rx clock/baud"); $stop; end
    // synthesis translate_on
endmodule
