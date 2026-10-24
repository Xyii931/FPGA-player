// Pin mapping source: reference/lab_ex5_i2s/src/user_source/hdl_source/IP/sdram.v
// Original generator: Anlogic IP Generator, TD 5.6.71036, 2023-12-12.
// Primitive/pin configuration retained; project module name avoids reference conflicts.
// This wrapper is the SDRAM array, not the reference encrypted sdr_as_ram controller.
module player_sdram_phy (
    input wire I_clk,I_cke,I_ras_n,I_cas_n,I_we_n,
    input wire [10:0] I_addr,
    input wire [1:0] I_ba,
    input wire [3:0] I_dm,
    inout wire [31:0] IO_dq
);
    EG_PHY_SDRAM_2M_32 u_memory (
        .clk(I_clk),.ras_n(I_ras_n),.cas_n(I_cas_n),.we_n(I_we_n),
        .addr(I_addr),.ba(I_ba),.dq(IO_dq),.cs_n(1'b0),
        .dm0(I_dm[0]),.dm1(I_dm[1]),.dm2(I_dm[2]),.dm3(I_dm[3]),.cke(I_cke));
endmodule
