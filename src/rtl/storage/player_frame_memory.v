// Actual six-client arbitration and native SDR command/retirement pipeline.
// Raw SDR pins connect to player_sdram_phy (or an explicit simulation device).
module player_frame_memory (
    input wire I_clk,
    input wire I_clk_sft,
    input wire I_reset,
    input wire [31:0] I_time,
    input wire [5:0] I_client_valid,
    output wire [5:0] O_client_ready,
    input wire [5:0] I_client_wr,
    input wire [125:0] I_client_addr,
    input wire [191:0] I_client_data,
    input wire [191:0] I_client_tag,
    input wire [191:0] I_client_token,
    input wire [191:0] I_client_generation,
    input wire [191:0] I_client_deadline,
    input wire [23:0] I_client_mask,
    output wire [5:0] O_client_result_valid,
    input wire [5:0] I_client_result_ready,
    output wire [5:0] O_client_result_wr,
    output wire [191:0] O_client_result_data,
    output wire [191:0] O_client_result_tag,
    output wire [191:0] O_client_result_token,
    output wire [191:0] O_client_result_generation,
    output wire [23:0] O_client_result_error,
    input wire I_clear_stats,
    output wire O_arbiter_busy,
    output wire O_contract_fault,
    output wire O_response_discarded,
    output wire O_issue_exhausted,
    output wire O_window_valid,
    output wire [20:0] O_busy_cycles,
    output wire [20:0] O_grant_cycles,
    output wire [191:0] O_client_grants,
    output wire O_initialized,
    output wire O_clock_fault,
    output wire O_device_busy,
    output wire O_controller_busy,
    output wire O_refresh_pulse,
    output wire O_sdram_clk,
    output wire O_sdram_cke,
    output wire O_sdram_ras_n,
    output wire O_sdram_cas_n,
    output wire O_sdram_we_n,
    output wire [10:0] O_sdram_addr,
    output wire [1:0] O_sdram_ba,
    output wire [3:0] O_sdram_dm,
    inout wire [31:0] IO_sdram_dq,
    output wire O_busy
);
    wire [5:0] S_arb_O_client_ready;
    wire [5:0] S_arb_O_client_result_valid;
    wire [5:0] S_arb_O_client_result_wr;
    wire [191:0] S_arb_O_client_result_data;
    wire [191:0] S_arb_O_client_result_tag;
    wire [191:0] S_arb_O_client_result_token;
    wire [191:0] S_arb_O_client_result_generation;
    wire [23:0] S_arb_O_client_result_error;
    wire S_arb_O_mem_valid;
    wire S_arb_O_mem_wr;
    wire [20:0] S_arb_O_mem_addr;
    wire [31:0] S_arb_O_mem_data;
    wire [31:0] S_arb_O_mem_tag;
    wire [3:0] S_arb_O_mem_mask;
    wire S_arb_O_mem_result_ready;
    wire S_arb_O_busy;
    wire S_arb_O_contract_fault;
    wire S_arb_O_response_discarded;
    wire S_arb_O_issue_exhausted;
    wire S_arb_O_window_valid;
    wire [20:0] S_arb_O_busy_cycles;
    wire [20:0] S_arb_O_grant_cycles;
    wire [191:0] S_arb_O_client_grants;
    wire S_native_O_cmd_ready;
    wire S_native_O_result_valid;
    wire S_native_O_result_wr;
    wire [31:0] S_native_O_result_data;
    wire [31:0] S_native_O_result_tag;
    wire [3:0] S_native_O_result_error;
    wire S_native_O_initialized;
    wire S_native_O_clock_fault;
    wire S_native_O_device_busy;
    wire S_native_O_busy;
    wire S_native_O_refresh_pulse;
    wire S_native_O_sdram_clk;
    wire S_native_O_sdram_cke;
    wire S_native_O_sdram_ras_n;
    wire S_native_O_sdram_cas_n;
    wire S_native_O_sdram_we_n;
    wire [10:0] S_native_O_sdram_addr;
    wire [1:0] S_native_O_sdram_ba;
    wire [3:0] S_native_O_sdram_dm;
    frame_mem_arbiter u_arb (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_time(I_time),
        .I_client_valid(I_client_valid),
        .O_client_ready(S_arb_O_client_ready),
        .I_client_wr(I_client_wr),
        .I_client_addr(I_client_addr),
        .I_client_data(I_client_data),
        .I_client_tag(I_client_tag),
        .I_client_token(I_client_token),
        .I_client_generation(I_client_generation),
        .I_client_deadline(I_client_deadline),
        .I_client_mask(I_client_mask),
        .O_client_result_valid(S_arb_O_client_result_valid),
        .I_client_result_ready(I_client_result_ready),
        .O_client_result_wr(S_arb_O_client_result_wr),
        .O_client_result_data(S_arb_O_client_result_data),
        .O_client_result_tag(S_arb_O_client_result_tag),
        .O_client_result_token(S_arb_O_client_result_token),
        .O_client_result_generation(S_arb_O_client_result_generation),
        .O_client_result_error(S_arb_O_client_result_error),
        .O_mem_valid(S_arb_O_mem_valid),
        .I_mem_ready(S_native_O_cmd_ready),
        .O_mem_wr(S_arb_O_mem_wr),
        .O_mem_addr(S_arb_O_mem_addr),
        .O_mem_data(S_arb_O_mem_data),
        .O_mem_tag(S_arb_O_mem_tag),
        .O_mem_mask(S_arb_O_mem_mask),
        .I_mem_result_valid(S_native_O_result_valid),
        .O_mem_result_ready(S_arb_O_mem_result_ready),
        .I_mem_result_wr(S_native_O_result_wr),
        .I_mem_result_data(S_native_O_result_data),
        .I_mem_result_tag(S_native_O_result_tag),
        .I_mem_result_error(S_native_O_result_error),
        .I_device_busy(S_native_O_device_busy),
        .I_clear_stats(I_clear_stats),
        .O_busy(S_arb_O_busy),
        .O_contract_fault(S_arb_O_contract_fault),
        .O_response_discarded(S_arb_O_response_discarded),
        .O_issue_exhausted(S_arb_O_issue_exhausted),
        .O_window_valid(S_arb_O_window_valid),
        .O_busy_cycles(S_arb_O_busy_cycles),
        .O_grant_cycles(S_arb_O_grant_cycles),
        .O_client_grants(S_arb_O_client_grants)
    );
    native_sdram_ctrl u_native (
        .I_clk(I_clk),
        .I_clk_sft(I_clk_sft),
        .I_reset(I_reset),
        .I_cmd_valid(S_arb_O_mem_valid),
        .O_cmd_ready(S_native_O_cmd_ready),
        .I_cmd_wr(S_arb_O_mem_wr),
        .I_cmd_addr(S_arb_O_mem_addr),
        .I_cmd_data(S_arb_O_mem_data),
        .I_cmd_tag(S_arb_O_mem_tag),
        .I_cmd_mask(S_arb_O_mem_mask),
        .O_result_valid(S_native_O_result_valid),
        .I_result_ready(S_arb_O_mem_result_ready),
        .O_result_wr(S_native_O_result_wr),
        .O_result_data(S_native_O_result_data),
        .O_result_tag(S_native_O_result_tag),
        .O_result_error(S_native_O_result_error),
        .O_initialized(S_native_O_initialized),
        .O_clock_fault(S_native_O_clock_fault),
        .O_device_busy(S_native_O_device_busy),
        .O_busy(S_native_O_busy),
        .O_refresh_pulse(S_native_O_refresh_pulse),
        .O_sdram_clk(S_native_O_sdram_clk),
        .O_sdram_cke(S_native_O_sdram_cke),
        .O_sdram_ras_n(S_native_O_sdram_ras_n),
        .O_sdram_cas_n(S_native_O_sdram_cas_n),
        .O_sdram_we_n(S_native_O_sdram_we_n),
        .O_sdram_addr(S_native_O_sdram_addr),
        .O_sdram_ba(S_native_O_sdram_ba),
        .O_sdram_dm(S_native_O_sdram_dm),
        .IO_sdram_dq(IO_sdram_dq)
    );
    assign O_client_ready=S_arb_O_client_ready;
    assign O_client_result_valid=S_arb_O_client_result_valid;
    assign O_client_result_wr=S_arb_O_client_result_wr;
    assign O_client_result_data=S_arb_O_client_result_data;
    assign O_client_result_tag=S_arb_O_client_result_tag;
    assign O_client_result_token=S_arb_O_client_result_token;
    assign O_client_result_generation=S_arb_O_client_result_generation;
    assign O_client_result_error=S_arb_O_client_result_error;
    assign O_arbiter_busy=S_arb_O_busy;
    assign O_contract_fault=S_arb_O_contract_fault;
    assign O_response_discarded=S_arb_O_response_discarded;
    assign O_issue_exhausted=S_arb_O_issue_exhausted;
    assign O_window_valid=S_arb_O_window_valid;
    assign O_busy_cycles=S_arb_O_busy_cycles;
    assign O_grant_cycles=S_arb_O_grant_cycles;
    assign O_client_grants=S_arb_O_client_grants;
    assign O_initialized=S_native_O_initialized;
    assign O_clock_fault=S_native_O_clock_fault;
    assign O_device_busy=S_native_O_device_busy;
    assign O_controller_busy=S_native_O_busy;
    assign O_refresh_pulse=S_native_O_refresh_pulse;
    assign O_sdram_clk=S_native_O_sdram_clk;
    assign O_sdram_cke=S_native_O_sdram_cke;
    assign O_sdram_ras_n=S_native_O_sdram_ras_n;
    assign O_sdram_cas_n=S_native_O_sdram_cas_n;
    assign O_sdram_we_n=S_native_O_sdram_we_n;
    assign O_sdram_addr=S_native_O_sdram_addr;
    assign O_sdram_ba=S_native_O_sdram_ba;
    assign O_sdram_dm=S_native_O_sdram_dm;
    assign O_busy=S_arb_O_busy | S_native_O_busy;
endmodule
