// One scanout reader + one inactive-frame writer, with a held native command.
// Writer retirement includes the command skid register, not just issued SDRAM.
module lean_frame_memory #(
    parameter integer INIT_CYCLES=25000
) (
    input wire I_clk,I_clk_sft,I_reset,
    input wire I_read_valid,
    output wire O_read_ready,
    input wire [20:0] I_read_address,
    input wire [31:0] I_read_tag,
    output wire O_read_result_valid,
    input wire I_read_result_ready,
    output wire [31:0] O_read_data,O_read_tag,
    output wire [3:0] O_read_error,
    input wire I_write_valid,
    output wire O_write_ready,
    input wire [20:0] I_write_address,
    input wire [31:0] I_write_data,
    output wire O_writes_idle,
    output wire O_initialized,O_clock_fault,
    output reg O_memory_error,
    output wire O_sdram_clk,O_sdram_cke,O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n,
    output wire [10:0] O_sdram_addr,
    output wire [1:0] O_sdram_ba,
    output wire [3:0] O_sdram_dm,
    inout wire [31:0] IO_sdram_dq
);
    reg S_valid,S_write;
    reg [20:0] S_address;
    reg [31:0] S_data,S_tag;
    reg [5:0] S_writes;
    wire S_ready,S_result,S_result_write,S_take;
    wire [31:0] S_result_data,S_result_tag;
    wire [3:0] S_error;
    wire S_room=!S_valid || S_ready;
    assign O_read_ready=!I_reset && O_initialized && !O_clock_fault && S_room;
    assign O_write_ready=O_read_ready && !I_read_valid;
    wire S_write_fire=I_write_valid && O_write_ready;
    wire S_read_fire=I_read_valid && O_read_ready;
    assign O_read_result_valid=S_result && !S_result_write;
    assign O_read_data=S_result_data;
    assign O_read_tag=S_result_tag;
    assign O_read_error=S_error;
    assign S_take=S_result_write || I_read_result_ready;
    wire S_retire=S_result && S_take && S_result_write;
    assign O_writes_idle=S_writes==0;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_valid<=0; S_write<=0; S_address<=0; S_data<=0; S_tag<=0; S_writes<=0; O_memory_error<=0;
        end else begin
            if(S_room) begin
                S_valid<=S_read_fire || S_write_fire;
                S_write<=!I_read_valid;
                S_address<=I_read_valid ? I_read_address : I_write_address;
                S_data<=I_write_data; S_tag<=I_read_valid ? I_read_tag : 32'd0;
            end
            case({S_write_fire,S_retire})
                2'b10:S_writes<=S_writes+1'b1;
                2'b01:S_writes<=S_writes-1'b1;
                default:begin end
            endcase
            if(S_result && S_take && S_error!=0) O_memory_error<=1;
        end
    end
    native_sdram_ctrl #(.INIT_CYCLES(INIT_CYCLES)) u_native (
        .I_clk(I_clk),.I_clk_sft(I_clk_sft),.I_reset(I_reset),
        .I_cmd_valid(S_valid),.O_cmd_ready(S_ready),.I_cmd_wr(S_write),.I_cmd_addr(S_address),
        .I_cmd_data(S_data),.I_cmd_tag(S_tag),.I_cmd_mask(4'd0),
        .O_result_valid(S_result),.I_result_ready(S_take),.O_result_wr(S_result_write),
        .O_result_data(S_result_data),.O_result_tag(S_result_tag),.O_result_error(S_error),
        .O_initialized(O_initialized),.O_clock_fault(O_clock_fault),
        .O_sdram_clk(O_sdram_clk),.O_sdram_cke(O_sdram_cke),.O_sdram_ras_n(O_sdram_ras_n),
        .O_sdram_cas_n(O_sdram_cas_n),.O_sdram_we_n(O_sdram_we_n),
        .O_sdram_addr(O_sdram_addr),.O_sdram_ba(O_sdram_ba),.O_sdram_dm(O_sdram_dm),.IO_sdram_dq(IO_sdram_dq),
        .O_device_busy(), .O_busy(), .O_refresh_pulse()
    );
endmodule
