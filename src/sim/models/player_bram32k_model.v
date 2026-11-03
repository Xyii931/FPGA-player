// Functional storage contract only. Loaded explicitly by load_player_bram.do;
// never compile together with src/ip/player_bram32k.v or add to player.al.
// Does not verify EG4 mapping, byte enables, primitive latency or collisions.
module player_bram32k #(
    parameter integer DATA_BITS=8,
    parameter integer ADDR_BITS=12,
    parameter integer DEPTH=4096
) (
    input wire I_clk_a,I_enable_a,I_write_a,
    input wire [ADDR_BITS-1:0] I_address_a,
    input wire [DATA_BITS-1:0] I_data_a,
    output reg [DATA_BITS-1:0] O_data_a,
    input wire I_clk_b,I_enable_b,I_write_b,
    input wire [ADDR_BITS-1:0] I_address_b,
    input wire [DATA_BITS-1:0] I_data_b,
    output reg [DATA_BITS-1:0] O_data_b
);
    reg [DATA_BITS-1:0] S_memory[0:DEPTH-1];
    always @(posedge I_clk_a) if(I_enable_a) begin
        if(I_address_a>=DEPTH) begin $display("FAIL: RAM model port A address"); $stop; end
        else if(I_write_a) begin S_memory[I_address_a]<=I_data_a; O_data_a<={DATA_BITS{1'bx}}; end
        else O_data_a<=S_memory[I_address_a];
    end
    always @(posedge I_clk_b) if(I_enable_b) begin
        if(I_address_b>=DEPTH) begin $display("FAIL: RAM model port B address"); $stop; end
        else if(I_write_b) begin S_memory[I_address_b]<=I_data_b; O_data_b<={DATA_BITS{1'bx}}; end
        else O_data_b<=S_memory[I_address_b];
    end
endmodule
