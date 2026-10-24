`timescale 1ns/1ps
// Real initializer + command mux + actual six-slot manager. Memory peer retires
// accepted writes explicitly; this is not an SDRAM timing/physical test.
module tb_resident_frame;
    reg S_clk=0,S_reset=1,S_enable=0,S_test_pass=0;
    always #4 S_clk=~S_clk;
    wire S_init_O_slot_valid;
    wire [114:0] S_init_O_slot_command;
    wire S_init_O_slot_result_ready;
    wire S_init_O_mem_valid;
    wire S_init_O_mem_wr;
    wire [20:0] S_init_O_mem_addr;
    wire [31:0] S_init_O_mem_data;
    wire [31:0] S_init_O_mem_tag;
    wire [31:0] S_init_O_mem_token;
    wire [31:0] S_init_O_mem_generation;
    wire [3:0] S_init_O_mem_mask;
    wire S_init_O_mem_result_ready;
    wire S_init_O_busy;
    wire S_init_O_ready;
    wire [31:0] S_init_O_token;
    wire [31:0] S_init_O_generation;
    wire [3:0] S_init_O_error;
    wire S_init_O_response_discarded;
    wire [1:0] S_client_ready,S_client_result_valid;
    wire [96:0] S_result,S_slot_result;
    wire [114:0] S_command;
    wire S_cmd_valid,S_cmd_ready,S_result_ready,S_slot_result_valid,S_mux_busy;
    wire [17:0] S_states;
    wire [191:0] S_tokens,S_generations,S_assets;
    wire [17:0] S_layouts,S_readers;
    wire [11:0] S_rotations;
    wire [5:0] S_resident,S_stale,S_cancel_loading;
    wire S_exhausted;
    reg S_mem_pending=0,S_inject=1;
    reg [2:0] S_delay=0;
    reg [31:0] S_return_tag=0,S_return_token=0;
    integer S_writes=0,S_retired=0,S_discarded=0;
    task fail;
        input [767:0] text;
        begin $display("FAIL resident: %0s",text); $stop; end
    endtask
    resident_frame_init u_init (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_enable(S_enable),
        .O_slot_valid(S_init_O_slot_valid),
        .I_slot_ready(S_client_ready[1]),
        .O_slot_command(S_init_O_slot_command),
        .I_slot_result_valid(S_client_result_valid[1]),
        .O_slot_result_ready(S_init_O_slot_result_ready),
        .I_slot_result(S_result),
        .O_mem_valid(S_init_O_mem_valid),
        .I_mem_ready(!S_mem_pending),
        .O_mem_wr(S_init_O_mem_wr),
        .O_mem_addr(S_init_O_mem_addr),
        .O_mem_data(S_init_O_mem_data),
        .O_mem_tag(S_init_O_mem_tag),
        .O_mem_token(S_init_O_mem_token),
        .O_mem_generation(S_init_O_mem_generation),
        .O_mem_mask(S_init_O_mem_mask),
        .I_mem_result_valid(S_mem_pending && S_delay==0),
        .O_mem_result_ready(S_init_O_mem_result_ready),
        .I_mem_result_wr(1'b1),
        .I_mem_result_tag(S_return_tag),
        .I_mem_result_token(S_return_token),
        .I_mem_result_generation(32'd0),
        .I_mem_result_error(4'd0),
        .O_busy(S_init_O_busy),
        .O_ready(S_init_O_ready),
        .O_token(S_init_O_token),
        .O_generation(S_init_O_generation),
        .O_error(S_init_O_error),
        .O_response_discarded(S_init_O_response_discarded)
    );
    slot_cmd_mux2 u_mux (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_client_valid({S_init_O_slot_valid,1'b0}),
        .O_client_ready(S_client_ready),
        .I_client_command({S_init_O_slot_command,115'd0}),
        .O_client_result_valid(S_client_result_valid),
        .I_client_result_ready({S_init_O_slot_result_ready,1'b1}),
        .O_client_result(S_result),
        .O_cmd_valid(S_cmd_valid),
        .I_cmd_ready(S_cmd_ready),
        .O_command(S_command),
        .I_result_valid(S_slot_result_valid),
        .O_result_ready(S_result_ready),
        .I_result(S_slot_result),
        .O_busy(S_mux_busy)
    );
    fb_slot_manager u_slots (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_media_valid(1'b0),
        .I_media_generation(32'd9),
        .I_cmd_valid(S_cmd_valid),
        .O_cmd_ready(S_cmd_ready),
        .I_cmd_op(S_command[114:112]),
        .I_cmd_slot(S_command[111:109]),
        .I_cmd_owner(S_command[108:107]),
        .I_cmd_token(S_command[106:75]),
        .I_cmd_generation(S_command[74:43]),
        .I_cmd_asset(S_command[42:11]),
        .I_cmd_layout(S_command[10:8]),
        .I_cmd_rotation(S_command[7:6]),
        .I_cmd_resident(S_command[5]),
        .I_cmd_success(S_command[4]),
        .I_producer_retired(S_command[3]),
        .I_memory_retired(S_command[2]),
        .I_reader_retired(S_command[1]),
        .I_frame_boundary(S_command[0]),
        .O_result_valid(S_slot_result_valid),
        .I_result_ready(S_result_ready),
        .O_result_error(S_slot_result[96:93]),
        .O_result_op(S_slot_result[92:90]),
        .O_result_slot(S_slot_result[89:87]),
        .O_result_owner(S_slot_result[86:85]),
        .O_result_token(S_slot_result[84:53]),
        .O_result_generation(S_slot_result[52:21]),
        .O_result_base(S_slot_result[20:0]),
        .O_slot_states(S_states),
        .O_slot_tokens(S_tokens),
        .O_slot_generations(S_generations),
        .O_slot_assets(S_assets),
        .O_slot_layouts(S_layouts),
        .O_slot_readers(S_readers),
        .O_slot_rotations(S_rotations),
        .O_slot_resident(S_resident),
        .O_slot_stale(S_stale),
        .O_cancel_loading(S_cancel_loading),
        .O_token_exhausted(S_exhausted)
    );
    always @(posedge S_clk) if(!S_reset) begin
        if(S_init_O_response_discarded) S_discarded<=S_discarded+1;
        if(S_mem_pending && S_delay!=0) S_delay<=S_delay-1'b1;
        if(S_init_O_mem_valid && !S_mem_pending) begin
            if(S_init_O_mem_addr!==21'h177000+S_writes || S_init_O_mem_tag!==S_writes ||
                S_init_O_mem_token==0 || S_init_O_mem_generation!=0 || !S_init_O_mem_wr || S_init_O_mem_mask!=0)
                fail("write identity/address");
            if(S_writes==0 && S_init_O_mem_data!==32'hfff0f0ff) fail("border color");
            S_writes<=S_writes+1; S_mem_pending<=1; S_delay<=3;
            S_return_tag<=S_init_O_mem_tag;
            S_return_token<=S_inject ? S_init_O_mem_token^32'h80000000 : S_init_O_mem_token;
        end
        if(S_mem_pending && S_delay==0 && S_init_O_mem_result_ready) begin
            if(S_inject) begin S_inject<=0; S_return_token<=S_init_O_mem_token; S_delay<=2; end
            else begin S_mem_pending<=0; S_retired<=S_retired+1; end
        end
        if(S_init_O_ready && (S_retired!=307200 || S_states[17:15]!=2 || !S_resident[5]))
            fail("resident published before real writes/FINISH");
    end
    initial begin
        repeat(5) @(negedge S_clk); S_reset=0;
        repeat(20) @(negedge S_clk); if(S_writes!=0) fail("started before SDRAM enable");
        S_enable=1; wait(S_init_O_ready); repeat(8) @(negedge S_clk);
        if(S_writes!=307200 || S_retired!=307200 || S_discarded!=1 || S_init_O_error!=0) fail("retirement or wrong-response isolation");
        S_enable=0; repeat(20) @(negedge S_clk); if(!S_init_O_ready) fail("media/enable invalidated resident page");
        S_test_pass=1; $display("PASS resident slot and real write retirement"); $finish;
    end
    initial begin #30000000; fail("watchdog"); end
endmodule
