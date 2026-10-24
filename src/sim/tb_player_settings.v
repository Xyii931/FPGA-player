`timescale 1ns/1ps
// Real mailboxes -> settings_store -> flash_ctrl -> SPI byte master -> pin peer.
module tb_player_settings;
    reg S_host_clk=0,S_flash_clk=0,S_reset=1;
    always #4 S_host_clk=~S_host_clk;
    always #5 S_flash_clk=~S_flash_clk;
    wire S_initialized,S_restore_valid,S_restore_found,S_save_ready,S_save_done,S_cs,S_sclk,S_mosi,S_miso;
    reg S_restore_ready=1,S_save=0,S_done_ready=0;
    reg [239:0] S_config=0;
    reg [3:0] S_override=0;
    wire [239:0] S_restored;
    wire [3:0] S_restored_override,S_load_error,S_save_error;
    reg S_reject=0,S_busy_stuck=0,S_corrupt=0,S_test_pass=0;
    reg [239:0] S_first,S_second;
    reg [3:0] S_held_error;
    integer S_before,S_index,S_cut;
    wire S_idle_O_font_ready;
    wire S_idle_O_font_read_valid;
    wire [7:0] S_idle_O_font_read_data;
    wire S_idle_O_font_read_last;
    wire S_idle_O_font_done_valid;
    wire [3:0] S_idle_O_font_error;
    wire [15:0] S_idle_O_font_tag;
    player_settings #(.FLASH_TIMEOUT_CYCLES(10000)) u_dut (
        .I_host_clk(S_host_clk),.I_flash_clk(S_flash_clk),.I_async_reset(S_reset),
        .O_initialized(S_initialized),.O_restore_valid(S_restore_valid),.I_restore_ready(S_restore_ready),
        .O_restore_found(S_restore_found),.O_restore_config(S_restored),.O_restore_override(S_restored_override),.O_load_error(S_load_error),
        .I_save_valid(S_save),.O_save_ready(S_save_ready),.I_config(S_config),.I_override(S_override),
        .O_save_done_valid(S_save_done),.I_save_done_ready(S_done_ready),.O_save_error(S_save_error),
        .I_font_valid(1'b0),.I_font_address(24'd0),.I_font_tag(16'd0),
        .I_font_read_ready(1'b1),.I_font_done_ready(1'b1),
        .O_font_ready(S_idle_O_font_ready),
        .O_font_read_valid(S_idle_O_font_read_valid),
        .O_font_read_data(S_idle_O_font_read_data),
        .O_font_read_last(S_idle_O_font_read_last),
        .O_font_done_valid(S_idle_O_font_done_valid),
        .O_font_error(S_idle_O_font_error),
        .O_font_tag(S_idle_O_font_tag),
        .O_flash_cs_n(S_cs),.O_flash_sclk(S_sclk),.O_flash_mosi(S_mosi),.I_flash_miso(S_miso),
        .I_demo_valid(),
        .O_demo_ready(),
        .I_demo_address(1'b0),
        .I_demo_length(1'b0),
        .I_demo_tag(1'b0),
        .O_demo_read_valid(),
        .I_demo_read_ready(1'b1),
        .O_demo_read_data(),
        .O_demo_read_last(),
        .O_demo_done_valid(),
        .I_demo_done_ready(1'b1),
        .O_demo_error(),
        .O_demo_tag()
    );
    sim_spi_nor u_nor (
        .I_clk(S_flash_clk),.I_cs_n(S_cs),.I_sclk(S_sclk),.I_mosi(S_mosi),
        .I_reject_wren(S_reject),.I_busy_stuck(S_busy_stuck),.I_corrupt_program(S_corrupt),.O_miso(S_miso)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: %0s",message); $stop; end
    endtask
    task restart;
        begin
            @(negedge S_host_clk); S_save=0; S_done_ready=0; S_reset=1;
            repeat(8) @(negedge S_host_clk); S_reset=0;
            wait(S_initialized); @(negedge S_host_clk);
        end
    endtask
    task request_save;
        input [239:0] cfg;
        input [3:0] overrides;
        begin
            wait(S_save_ready); @(negedge S_host_clk); S_config=cfg; S_override=overrides; S_save=1;
            @(negedge S_host_clk); S_save=0;
            // Live UI changes cannot modify the accepted save snapshot.
            S_config=~cfg; S_override=~overrides;
        end
    endtask
    task save_result;
        input [3:0] error;
        integer k;
        begin
            wait(S_save_done); S_held_error=S_save_error;
            for(k=0;k<20;k=k+1) begin
                @(negedge S_host_clk);
                if(!S_save_done || S_save_ready || S_save_error!==S_held_error) fail("save result backpressure");
            end
            if(S_save_error!==error) begin $display("save error=%0d expected=%0d",S_save_error,error); fail("save terminal"); end
            S_done_ready=1; @(negedge S_host_clk); S_done_ready=0;
            wait(S_save_ready);
        end
    endtask
    initial begin
        for(S_index=0;S_index<15;S_index=S_index+1) begin
            S_first[S_index*16+:16]=S_index+1;
            S_second[S_index*16+:16]=100+S_index;
        end
        repeat(6) @(negedge S_host_clk); S_reset=0;
        wait(S_initialized); if(S_restore_found || S_load_error!=0) fail("blank flash boot fallback");
        request_save(S_first,4'h5); save_result(0);
        if(u_dut.u_store.O_sequence!=1) fail("first record sequence");
        restart;
        if(!S_restore_found || S_restored!==S_first || S_restored_override!=5) fail("boot restore first copy");
        // Interrupt inactive-copy body programming. Active copy must remain recoverable.
        for(S_cut=0;S_cut<4;S_cut=S_cut+1) begin
            request_save(S_second,4'ha);
            case(S_cut)
                0:wait(u_dut.u_store.S_job==2 && u_dut.u_flash.S_phase==3 && u_dut.u_flash.S_index==3);
                1:wait(u_dut.u_store.S_job==3 && u_dut.u_store.S_index==40);
                2:wait(u_dut.u_store.S_job==4 && u_dut.u_store.S_index==80);
                3:wait(u_dut.u_store.S_job==5 && u_dut.u_store.S_index==2);
            endcase
            restart;
            if(!S_restore_found || S_restored!==S_first || u_dut.u_store.O_sequence!=1) fail("torn uncommitted copy selected");
        end
        request_save(S_second,4'ha); save_result(0); restart;
        if(!S_restore_found || S_restored!==S_second || S_restored_override!=10 || u_dut.u_store.O_sequence!=2)
            fail("latest committed copy not selected");
        // Simulated bit programming fault is detected before commit is issued.
        S_corrupt=1; request_save(S_first,0); save_result(6); S_corrupt=0;
        restart;
        if(S_restored!==S_second || u_dut.u_store.O_sequence!=2) fail("failed verification replaced active copy");
        S_reject=1; request_save(S_first,0); save_result(3); S_reject=0;
        // Preflight timeout must retire even though no write payload was accepted.
        S_busy_stuck=1; request_save(S_first,0); save_result(4); S_busy_stuck=0;
        // Corrupt newest CRC: startup falls back to the older valid committed copy.
        request_save(S_first,4'hf); save_result(0);
        if(u_dut.u_store.O_sequence!=3) fail("failed saves advanced sequence");
        u_nor.S_memory[140]=u_nor.S_memory[140]^8'h01;
        restart;
        if(S_restored!==S_second || u_dut.u_store.O_sequence!=2) fail("CRC fallback");
        // An uncommitted newer record cannot supersede the retained one.
        u_nor.S_memory[140]=u_nor.S_memory[140]^8'h01; u_nor.S_memory[144]=8'hff;
        restart;
        if(S_restored!==S_second || u_dut.u_store.O_sequence!=2) fail("commit marker fallback");
        S_before=u_nor.S_erases; repeat(200) @(negedge S_host_clk);
        if(u_nor.S_erases!=S_before) fail("implicit background save");
        S_test_pass=1; $display("PASS: actual CFG1/SPI/CDC, torn write, CRC/commit, WEL and BUSY failure"); $finish;
    end
    initial begin #20000000; fail("settings watchdog"); end
endmodule
