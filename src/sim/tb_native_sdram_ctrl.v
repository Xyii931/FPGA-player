`timescale 1ns/1ps
// Short command-level test; physical phase/electrical timing still needs TD/board checks.
module tb_native_sdram_ctrl;
    reg S_clk=0,S_shift=0,S_ideal_shift=0,S_run_shift=1,S_reset=1;
    reg S_command=0,S_write=0,S_take=1;
    reg [20:0] S_address=0;
    reg [31:0] S_data=0,S_tag=0;
    wire S_ready,S_result,S_result_write,S_initialized,S_fault,S_device_fault;
    wire [31:0] S_result_data,S_result_tag;
    wire [3:0] S_result_error;
    wire S_sclk,S_cke,S_ras,S_cas,S_we;
    wire [10:0] S_addr;
    wire [1:0] S_bank;
    wire [3:0] S_mask;
    wire [31:0] S_dq;
    reg S_test_pass=0;
    integer S_results=0,S_before;
    integer S_refreshes=0,S_stress;
    wire S_refresh_pulse;
    integer S_device_cycle=0,S_last_refresh=-1;
    reg S_mode_loaded=0;
    always @(posedge S_sclk) begin
        if(S_reset || S_fault) begin S_device_cycle=0; S_last_refresh=-1; S_mode_loaded=0; end
        else begin
            S_device_cycle=S_device_cycle+1;
            if(S_cke && {S_ras,S_cas,S_we}==3'b000) S_mode_loaded=1;
            if(S_cke && {S_ras,S_cas,S_we}==3'b001) begin
                if(S_mode_loaded && S_last_refresh>=0 && S_device_cycle-S_last_refresh>650)
                    fail("refresh command interval exceeded 650 device cycles");
                S_last_refresh=S_device_cycle;
            end
        end
    end
    realtime S_dq_changed=0;
    always @(S_dq) S_dq_changed=$realtime;
    always @(posedge S_sclk) if(!S_reset && S_cke && {S_ras,S_cas,S_we}==3'b100) begin
        // The DQ-only multicycle exception requires a full host cycle of
        // pre-drive in addition to the 7 ns phase: 19 ns at 83.333333 MHz.
        if($realtime-S_dq_changed<18.999) fail("WRITE data was not pre-driven for the constrained interval");
    end
    always #6 S_clk=~S_clk;
    always @(S_clk) S_ideal_shift<=#7 S_clk;
    always @(S_ideal_shift) if(S_run_shift) S_shift=S_ideal_shift;
    native_sdram_ctrl #(.INIT_CYCLES(32)) u_dut (
        .I_clk(S_clk),.I_clk_sft(S_shift),.I_reset(S_reset),
        .I_cmd_valid(S_command),.O_cmd_ready(S_ready),.I_cmd_wr(S_write),
        .I_cmd_addr(S_address),.I_cmd_data(S_data),.I_cmd_tag(S_tag),.I_cmd_mask(4'd0),
        .O_result_valid(S_result),.I_result_ready(S_take),.O_result_wr(S_result_write),
        .O_result_data(S_result_data),.O_result_tag(S_result_tag),.O_result_error(S_result_error),
        .O_initialized(S_initialized),.O_clock_fault(S_fault),
        .O_device_busy(),.O_busy(),.O_refresh_pulse(S_refresh_pulse),
        .O_sdram_clk(S_sclk),.O_sdram_cke(S_cke),.O_sdram_ras_n(S_ras),
        .O_sdram_cas_n(S_cas),.O_sdram_we_n(S_we),.O_sdram_addr(S_addr),
        .O_sdram_ba(S_bank),.O_sdram_dm(S_mask),.IO_sdram_dq(S_dq)
    );
    sim_sdr_device u_device (
        .I_clk(S_sclk),.I_reset(S_reset),.I_cke(S_cke),.I_ras_n(S_ras),
        .I_cas_n(S_cas),.I_we_n(S_we),.I_addr(S_addr),.I_ba(S_bank),
        .I_dm(S_mask),.IO_dq(S_dq),.O_fault(S_device_fault),
        .O_reads(),.O_writes(),.O_refreshes()
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: native SDRAM: %0s",message); $stop; end
    endtask
    task command;
        input write_request;
        input [20:0] address;
        input [31:0] data,tag;
        begin
            @(negedge S_clk); S_command=1; S_write=write_request;
            S_address=address; S_data=data; S_tag=tag;
            @(posedge S_clk); while(!S_ready) @(posedge S_clk);
            @(negedge S_clk); S_command=0;
        end
    endtask
    task check_result;
        input write_request;
        input [31:0] data,tag;
        begin
            @(posedge S_clk); while(!S_result) @(posedge S_clk);
            if(S_result_error!=0 || S_result_write!==write_request || S_result_tag!==tag ||
                (!write_request && S_result_data!==data)) begin
                $display("expected wr=%b data=%h tag=%h; got wr=%b data=%h tag=%h error=%h",
                    write_request,data,tag,S_result_write,S_result_data,S_result_tag,S_result_error);
                fail("data/tag/result mismatch");
            end
            @(negedge S_clk);
        end
    endtask
    task reset_and_start;
        begin
            @(negedge S_clk); S_reset=1; S_command=0;
            repeat(4) @(negedge S_clk);
            S_reset=0; wait(S_initialized); @(negedge S_clk);
            if(S_fault || S_device_fault) fail("initialization fault");
        end
    endtask
    always @(posedge S_clk) if(!S_reset && S_result && S_take) S_results=S_results+1;
    always @(posedge S_clk) if(!S_reset && S_refresh_pulse) S_refreshes=S_refreshes+1;
    initial begin
        reset_and_start;
        command(1,21'd0,32'h12abcdef,32'd1); check_result(1,0,1);
        command(0,21'd0,0,32'd2); check_result(0,32'h12abcdef,2);
        command(1,21'd1024,32'h76543210,32'd3); check_result(1,0,3);
        command(0,21'd1024,0,32'd4); check_result(0,32'h76543210,4);
        // Keep a result under backpressure, then lose the device clock. The
        // outstanding transaction must never be acknowledged after the fault.
        S_take=0; command(1,21'd1025,32'hdeadbeef,32'd5);
        wait(S_result); S_before=S_results;
        @(negedge S_shift); #1 S_run_shift=0;
        wait(S_fault); #1;
        if(S_ready || S_result) fail("clock fault did not block interfaces");
        S_take=1;
        repeat(12) begin @(negedge S_clk); if(S_result || S_results!=S_before) fail("faulted result retired"); end
        // Resume at the configured phase; a clock restart alone cannot unstick
        // a controller whose pin history is unknown. Shared reset is required.
        @(posedge S_clk); #1 S_run_shift=1;
        repeat(12) begin @(negedge S_clk); if(!S_fault || S_ready || S_result) fail("fault cleared without reset"); end
        reset_and_start;
        command(1,21'd8,32'hface2468,32'd6); check_result(1,0,6);
        command(0,21'd8,0,32'd7); check_result(0,32'hface2468,7);
        // Cross several idle refresh thresholds before reusing an open row.
        S_before=S_refreshes;
        wait(S_refreshes>=S_before+3);
        command(0,21'd8,0,32'd9); check_result(0,32'hface2468,9);
        // Start row-changing traffic just before refresh scheduling becomes
        // urgent; check the actual device commands, including drain/precharge.
        for(S_stress=0;S_stress<3;S_stress=S_stress+1) begin
            @(posedge S_refresh_pulse);
            repeat(590) @(negedge S_clk);
            command(1,(S_stress+1)<<10,32'hf00d0000+S_stress,32'd10+S_stress);
            check_result(1,0,32'd10+S_stress);
            command(0,(S_stress+1)<<10,0,32'd13+S_stress);
            check_result(0,32'hf00d0000+S_stress,32'd13+S_stress);
        end
        // Stop the device clock after data pre-drive but before WRITE can be
        // sampled. Restored edges alone must not acknowledge this pending write.
        S_take=0; command(1,21'd9,32'h0badf00d,32'd8);
        @(negedge S_shift); #1 S_run_shift=0; S_before=S_results;
        wait(S_fault); S_take=1;
        repeat(12) begin @(negedge S_clk); if(S_result || S_results!=S_before) fail("unissued WRITE retired"); end
        @(posedge S_clk); #1 S_run_shift=1;
        reset_and_start;
        // Assert reset while a write drives DQ. Its registered drive enable
        // must release asynchronously, without waiting for either clock.
        @(negedge S_clk); S_command=1; S_write=1; S_address=9; S_data=32'h55aa55aa;
        @(posedge S_clk); while(!S_ready) @(posedge S_clk);
        #1 S_reset=1; S_command=0;
        #0.1;
        if(u_dut.S_dq_drive!==0 || S_result || S_ready) fail("asynchronous reset did not release write drive");
        if(S_device_fault) fail("device command timing violation");
        S_test_pass=1;
        $display("PASS: native SDRAM read/write tags, row change, clock loss, blocked retirement and reset recovery");
        $finish;
    end
    initial begin #100000; fail("watchdog"); end
endmodule
