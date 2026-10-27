// UART 8N1, ready/valid byte input. Idle line and reset level are high.
module uart_tx #(
    parameter integer CLOCK_HZ=100000000,BAUD=115200
) (
    input wire I_clk,I_reset,I_valid,
    output wire O_ready,
    input wire [7:0] I_data,
    output reg O_tx
);
    reg S_busy;
    reg [3:0] S_bit;
    reg [9:0] S_frame;
    reg [31:0] S_count;
    localparam integer DIVISOR=(CLOCK_HZ+BAUD/2)/BAUD;
    assign O_ready=!I_reset && !S_busy;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin S_busy<=0; S_bit<=0; S_frame<=10'h3ff; S_count<=0; O_tx<=1; end
        else if(!S_busy) begin
            if(I_valid) begin
                S_frame<={1'b1,I_data,1'b0}; O_tx<=0; S_busy<=1; S_bit<=0; S_count<=DIVISOR-1;
            end
        end else if(S_count!=0) S_count<=S_count-1'b1;
        else if(S_bit==9) begin S_busy<=0; O_tx<=1; end
        else begin S_bit<=S_bit+1'b1; O_tx<=S_frame[S_bit+1'b1]; S_count<=DIVISOR-1; end
    end
    // synthesis translate_off
    initial if(BAUD<1 || DIVISOR<8) begin $display("FAIL: uart_tx clock/baud"); $stop; end
    // synthesis translate_on
endmodule
