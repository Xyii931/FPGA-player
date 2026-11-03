// SPI mode 0, MSB first. Divider is the COMPLETE SCLK period in I_clk cycles.
// CS belongs to the transaction owner. Only byte boundaries may be stalled.
module spi_byte_master (
    input wire I_clk,I_reset,
    input wire I_tx_valid,
    output wire O_tx_ready,
    input wire [7:0] I_tx_data,
    input wire [15:0] I_divider,
    output reg O_rx_valid,
    input wire I_rx_ready,
    output reg [7:0] O_rx_data,
    output reg O_sclk,O_mosi,
    input wire I_miso,
    output wire O_busy
);
    reg S_active;
    reg [15:0] S_half_period,S_count;
    reg [2:0] S_bit;
    reg [7:0] S_tx,S_rx;
    wire S_divider_valid=I_divider>=4 && !I_divider[0];
    assign O_tx_ready=!I_reset && !S_active && (!O_rx_valid || I_rx_ready) && S_divider_valid;
    assign O_busy=S_active || O_rx_valid;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_active<=0; S_half_period<=0; S_count<=0; S_bit<=0; S_tx<=0; S_rx<=0;
            O_rx_valid<=0; O_rx_data<=0; O_sclk<=0; O_mosi<=1;
        end else begin
            if(O_rx_valid && I_rx_ready) O_rx_valid<=0;
            if(I_tx_valid && O_tx_ready) begin
                S_active<=1; S_half_period<=I_divider>>1; S_count<=(I_divider>>1)-16'd1;
                S_bit<=7; S_tx<=I_tx_data; S_rx<=0; O_mosi<=I_tx_data[7];
            end else if(S_active) begin
                if(S_count!=0) S_count<=S_count-16'd1;
                else begin
                    S_count<=S_half_period-16'd1;
                    if(!O_sclk) begin
                        O_sclk<=1; S_rx<={S_rx[6:0],I_miso};
                    end else begin
                        O_sclk<=0;
                        if(S_bit==0) begin
                            S_active<=0; O_mosi<=1; O_rx_data<=S_rx; O_rx_valid<=1;
                        end else begin
                            S_bit<=S_bit-3'd1; S_tx<={S_tx[6:0],1'b1}; O_mosi<=S_tx[6];
                        end
                    end
                end
            end
        end
    end
endmodule
