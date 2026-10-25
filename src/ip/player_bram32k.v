// EG4 block RAM allocation, based on TD 6.2.168116's supplied HDL template:
// template/verilog/Device-Primitive/EG4/RAM,ROM/eg4_ram_rom.v, EG_LOGIC_BRAM.
// Select 32K explicitly; automatic inference previously consumed only BRAM9K.
// Synchronous read, no optional output register, no content reset/initial value.
// Read output during a write and cross-port same-address collisions are undefined.
module player_bram32k #(
    parameter integer DATA_BITS=8,
    parameter integer ADDR_BITS=12,
    parameter integer DEPTH=4096
) (
    input wire I_clk_a,I_enable_a,I_write_a,
    input wire [ADDR_BITS-1:0] I_address_a,
    input wire [DATA_BITS-1:0] I_data_a,
    output wire [DATA_BITS-1:0] O_data_a,
    input wire I_clk_b,I_enable_b,I_write_b,
    input wire [ADDR_BITS-1:0] I_address_b,
    input wire [DATA_BITS-1:0] I_data_b,
    output wire [DATA_BITS-1:0] O_data_b
);
    EG_LOGIC_BRAM #(
        .DATA_WIDTH_A(DATA_BITS),.DATA_WIDTH_B(DATA_BITS),
        .ADDR_WIDTH_A(ADDR_BITS),.ADDR_WIDTH_B(ADDR_BITS),
        .DATA_DEPTH_A(DEPTH),.DATA_DEPTH_B(DEPTH),
        .BYTE_ENABLE(0),.BYTE_A(1),.BYTE_B(1),
        .MODE("DP"),.REGMODE_A("NOREG"),.REGMODE_B("NOREG"),
        .WRITEMODE_A("NORMAL"),.WRITEMODE_B("NORMAL"),.RESETMODE("SYNC"),
        .DEBUGGABLE("NO"),.PACKABLE("NO"),.FORCE_KEEP("OFF"),
        .INIT_FILE("NONE"),.FILL_ALL("NONE"),.IMPLEMENT("32K")
    ) u_ram (
        .clka(I_clk_a),.cea(I_enable_a),.wea(I_write_a),.addra(I_address_a),
        .dia(I_data_a),.doa(O_data_a),.ocea(1'b1),.rsta(1'b0),.bea(1'b1),
        .clkb(I_clk_b),.ceb(I_enable_b),.web(I_write_b),.addrb(I_address_b),
        .dib(I_data_b),.dob(O_data_b),.oceb(1'b1),.rstb(1'b0),.beb(1'b1)
    );
    // synthesis translate_off
    initial begin
        if(DATA_BITS<1 || ADDR_BITS<1 || DEPTH<1 || DEPTH>2**ADDR_BITS) begin
            $display("FAIL: player_bram32k invalid width/depth"); $stop;
        end
    end
    // synthesis translate_on
endmodule
