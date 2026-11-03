`timescale 1ns/1ps
// Raw-file cache protocol and native SDRAM, independent from the WAV decoder.
module tb_lean_audio_cache;
    reg S_clk=0,S_shift=0,S_reset=1,S_catalog=1,S_found=1,S_enable=0;
    always #6 S_clk=~S_clk;
    always @(S_clk) S_shift<=#7 S_clk;
    reg [31:0] S_size=37;
    reg [7:0] S_generation=1;
    reg [2:0] S_fault=0;
    reg S_hold_retire=0,S_hold_result=0,S_cancel=0;
    wire S_cached,S_loading,S_source_command,S_source_begin_ready,S_source_byte_ready,S_source_cancel;
    wire [3:0] S_error;
    wire [31:0] S_source_offset,S_source_length;
    reg [2:0] S_peer=0;
    reg [31:0] S_source_cursor=0,S_source_done_bytes=0;
    reg [7:0] S_source_error=0;
    integer S_cycle=0,S_requests=0,S_writes=0,S_case=0;
    reg S_test_pass=0;
    wire S_source_bytes=S_peer==2 && S_cycle%3!=0;
    wire [31:0] S_source_position=S_source_cursor+(S_fault==2 && S_source_cursor==32 ? 32'd1 : 32'd0);
    reg S_command=0,S_begin_ready=0,S_byte_ready=0;
    reg [31:0] S_offset=0,S_length=0;
    wire S_command_ready,S_begin,S_byte,S_done,S_eof;
    wire [31:0] S_file_size,S_byte_offset,S_done_bytes;
    wire [7:0] S_begin_error,S_byte_data,S_file_error;
    wire S_write,S_write_ready,S_read,S_read_ready,S_result,S_result_ready,S_idle,S_initialized,S_clock_fault,S_memory_error;
    wire [20:0] S_write_address,S_read_address;
    wire [31:0] S_write_data,S_result_data;
    wire [3:0] S_result_error;
    wire sclk,cke,ras,cas,we,device_fault;
    wire [10:0] addr;
    wire [1:0] ba;
    wire [3:0] dm;
    wire [31:0] dq;
    function [7:0] pattern;
        input [31:0] offset;
        begin pattern=offset[7:0]^offset[15:8]^offset[23:16]^S_generation; end
    endfunction
    lean_audio_cache u_cache (
        .I_clk(S_clk),.I_reset(S_reset),.I_catalog_ready(S_catalog),.I_audio_found(S_found),.I_enable(S_enable),
        .I_memory_error(S_clock_fault || S_memory_error || device_fault),.I_writes_idle(S_idle && !S_hold_retire),
        .O_ready(S_cached),.O_loading(S_loading),.O_error(S_error),
        .O_source_command_valid(S_source_command),.I_source_command_ready(S_peer==0),
        .O_source_offset(S_source_offset),.O_source_length(S_source_length),
        .I_source_begin_valid(S_peer==1),.O_source_begin_ready(S_source_begin_ready),
        .I_source_file_size(S_size),.I_source_begin_error(S_fault==3 ? 8'd2 : 8'd0),
        .I_source_byte_valid(S_source_bytes),.O_source_byte_ready(S_source_byte_ready),
        .I_source_byte_data(pattern(S_source_cursor)),.I_source_byte_offset(S_source_position),
        .I_source_file_done(S_peer==3),.I_source_file_error(S_source_error),
        .I_source_file_bytes(S_source_done_bytes),.I_source_file_eof(S_source_done_bytes==S_size),.O_source_cancel(S_source_cancel),
        .I_command_valid(S_command),.O_command_ready(S_command_ready),.I_offset(S_offset),.I_length(S_length),
        .O_begin_valid(S_begin),.I_begin_ready(S_begin_ready),.O_file_size(S_file_size),.O_begin_error(S_begin_error),
        .O_byte_valid(S_byte),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte_data),.O_byte_offset(S_byte_offset),
        .O_file_done(S_done),.O_file_error(S_file_error),.O_file_bytes(S_done_bytes),.O_file_eof(S_eof),.I_cancel(S_cancel),
        .O_write_valid(S_write),.I_write_ready(S_write_ready),.O_write_address(S_write_address),.O_write_data(S_write_data),
        .O_read_valid(S_read),.I_read_ready(S_read_ready),.O_read_address(S_read_address),
        .I_result_valid(S_result && !S_hold_result),.O_result_ready(S_result_ready),.I_result_data(S_result_data),.I_result_error(S_result_error)
    );
    lean_frame_memory #(.INIT_CYCLES(32)) u_memory (
        .I_clk(S_clk),.I_clk_sft(S_shift),.I_reset(S_reset),
        .I_read_valid(S_read),.O_read_ready(S_read_ready),.I_read_address(S_read_address),.I_read_tag(32'h80000000),
        .O_read_result_valid(S_result),.I_read_result_ready(S_result_ready && !S_hold_result),
        .O_read_data(S_result_data),.O_read_tag(),.O_read_error(S_result_error),
        .I_write_valid(S_write),.O_write_ready(S_write_ready),.I_write_address(S_write_address),.I_write_data(S_write_data),
        .O_writes_idle(S_idle),.O_initialized(S_initialized),.O_clock_fault(S_clock_fault),.O_memory_error(S_memory_error),
        .O_sdram_clk(sclk),.O_sdram_cke(cke),.O_sdram_ras_n(ras),.O_sdram_cas_n(cas),.O_sdram_we_n(we),
        .O_sdram_addr(addr),.O_sdram_ba(ba),.O_sdram_dm(dm),.IO_sdram_dq(dq)
    );
    sim_sdr_device u_device (
        .I_clk(sclk),.I_reset(S_reset),.I_cke(cke),.I_ras_n(ras),.I_cas_n(cas),.I_we_n(we),
        .I_addr(addr),.I_ba(ba),.I_dm(dm),.IO_dq(dq),.O_fault(device_fault),.O_reads(),.O_writes(),.O_refreshes()
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: audio cache case %0d: %0s",S_case,message); $stop; end
    endtask
    always @(posedge S_clk) if(!S_reset) begin
        S_cycle<=S_cycle+1;
        if(S_clock_fault || S_memory_error || device_fault) fail("native SDRAM protocol");
        if(S_write && S_write_ready) begin
            if(S_write_address<1048576) fail("cache overwrote image reservation");
            S_writes=S_writes+1;
        end
        case(S_peer)
            0:if(S_source_command) begin
                if(S_source_offset!=0 || S_source_length!=32'hffffffff) fail("partial prefetch");
                S_requests=S_requests+1; S_source_cursor<=0; S_source_error<=0; S_peer<=1;
            end
            // A failed Begin retires without Byte or Done, as lean_media_source does.
            1:if(S_source_begin_ready) S_peer<=S_fault==3 ? 0 : 2;
            2:if(S_source_cancel || (S_fault==1 && S_source_cursor>=257)) begin
                S_source_done_bytes<=S_source_cursor; S_source_error<=S_source_cancel ? 8'd8 : 8'd2; S_peer<=3;
            end else if(S_source_bytes && S_source_byte_ready) begin
                S_source_cursor<=S_source_cursor+1;
                if(S_source_cursor+1==S_size) begin S_source_done_bytes<=S_size; S_peer<=3; end
            end
            3:S_peer<=0;
        endcase
    end
    task media_reset;
        begin
            @(negedge S_clk); S_catalog=0;
            wait(S_peer==0 && !u_cache.S_read_busy && !u_cache.S_write_pending);
            repeat(8) @(negedge S_clk);
            if(S_cached || S_error!=0) fail("cache not invalidated");
            S_generation=S_generation+1; S_fault=0;
            S_catalog=1;
        end
    endtask
    task start_read;
        input [31:0] offset,length;
        begin
            @(negedge S_clk); S_offset=offset; S_length=length; S_command=1;
            while(!S_command_ready) @(negedge S_clk);
            @(negedge S_clk); S_command=0;
            wait(S_begin);
            if(S_file_size!=S_size) fail("cached size changed");
            @(negedge S_clk); S_begin_ready=1;
            @(negedge S_clk); S_begin_ready=0;
        end
    endtask
    task check_read;
        input [31:0] offset,length;
        integer checked,wanted;
        begin
            start_read(offset,length);
            wanted=offset>S_size ? 0 : (length>S_size-offset ? S_size-offset : length);
            checked=0;
            while(!S_done) begin
                @(negedge S_clk); S_byte_ready=S_cycle%7!=0;
                @(posedge S_clk);
                if(S_byte && S_byte_ready) begin
                    if(S_byte_offset!=offset+checked || S_byte_data!==pattern(offset+checked)) fail("cached byte/offset changed");
                    checked=checked+1;
                end
            end
            if(checked!=wanted || S_done_bytes!=wanted || S_file_error!=(offset>S_size ? 11 : 0) ||
                S_eof!=(offset+checked==S_size)) fail("range/EOF/count metadata");
            @(negedge S_clk); S_byte_ready=0;
        end
    endtask
    integer S_before;
    initial begin
        repeat(12) @(negedge S_clk); S_reset=0;
        wait(S_initialized); repeat(20) @(negedge S_clk);
        if(S_requests!=0) fail("prefetch before first-image enable");
        S_case=1; S_enable=1;
        wait(u_cache.S_state==3); @(negedge S_clk); S_hold_retire=1;
        wait(u_cache.S_state==4); repeat(20) @(negedge S_clk);
        if(S_cached) fail("cache published before writes retired");
        S_hold_retire=0; wait(S_cached);
        if(S_writes!=10 || u_device.S_memory[1048585]!=={24'd0,pattern(36)}) fail("partial last word packing");
        check_read(0,37); check_read(1,17); check_read(37,2048); check_read(38,1);
        if(S_requests!=1) fail("loop/local reads returned to TF");

        // Hold a native read return across removal; a new file must not consume it.
        S_case=2; @(negedge S_clk); S_hold_result=1;
        start_read(0,16); wait(u_cache.S_read_busy);
        @(negedge S_clk); S_catalog=0;
        wait(S_result); repeat(8) @(negedge S_clk);
        S_before=S_requests; S_generation=S_generation+1; S_size=8193; S_catalog=1;
        repeat(8) @(negedge S_clk);
        if(S_requests!=S_before) fail("new cache started before old read drained");
        S_hold_result=0; wait(S_cached);
        check_read(0,32); check_read(1019,20); check_read(4091,20); check_read(8187,100);

        S_case=3; S_enable=0; media_reset; S_size=4194305; S_enable=1;
        wait(S_error!=0); wait(u_cache.S_state==6);
        if(S_cached) fail("oversize cache accepted");

        S_case=4; S_enable=0; media_reset; S_size=1000; S_fault=1; S_enable=1;
        wait(u_cache.S_state==6); if(S_cached || S_error==0) fail("source failure published");

        S_case=5; S_enable=0; media_reset; S_size=1000; S_fault=2; S_enable=1;
        wait(u_cache.S_state==6); if(S_cached || S_error==0) fail("offset discontinuity published");

        S_case=6; S_enable=0; media_reset; S_size=1000; S_fault=3; S_enable=1;
        wait(S_peer==1); wait(S_peer==0); repeat(20) @(negedge S_clk);
        if(u_cache.S_state!=6 || S_cached || S_error==0 || S_loading)
            fail("failed Begin waited for a Done that source never sends");

        S_case=7; S_enable=0; media_reset; S_size=1025; S_enable=1;
        wait(S_peer==2 && S_source_cursor>31); @(negedge S_clk); S_enable=0;
        media_reset; S_size=$test$plusargs("FULL_CAPACITY") ? 4194304 : 1025; S_enable=1;
        wait(S_cached);
        check_read(S_size-17,32); check_read(3,21);
        if(S_size==4194304 && S_write_address!=2097151) fail("maximum cache address");
        $display("CACHE_NATIVE requests=%0d writes=%0d last_size=%0d",S_requests,S_writes,S_size);
        S_test_pass=1; $display("PASS: audio cache native SDRAM, packing, bounds, retirement, range, abort, stale-return drain and media recovery"); $finish;
    end
    initial begin #2000000000; fail("watchdog"); end
endmodule
