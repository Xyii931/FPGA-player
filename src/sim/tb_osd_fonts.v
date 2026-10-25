`timescale 1ns/1ps
// Actual cache, arbiter, CFG1, Flash SPI and byte decoder.
module tb_osd_fonts;
    wire [1:0] S_done;
    reg S_test_pass=0;
    font_cache_case u_cache_case(.O_done(S_done[0]));
    font_text_case u_text_case(.O_done(S_done[1]));
    initial begin
        wait(&S_done); S_test_pass=1;
        $display("PASS: real glyph/Flash/settings route, protection/eviction and GB2312 text"); $finish;
    end
    initial begin
        #50000000;
        $display("FAIL: font test watchdog done=%b cache_state=%0d code=%0d flash_state=%0d text_job=%0d",
            S_done,u_cache_case.u_cache.S_state,u_cache_case.u_cache.S_code,
            u_cache_case.u_settings.S_flash_state,u_text_case.S_job);
        $stop;
    end
endmodule

module font_cache_case(output reg O_done=0);
    reg S_host_clk=0,S_clk=0,S_reset=1;
    always #4 S_host_clk=~S_host_clk;
    always #5 S_clk=~S_clk;
    reg S_get=0,S_lock=0,S_result_ready=0;
    reg [13:0] S_code=0;
    reg [399:0] S_pinned=0;
    wire S_get_ready,S_result_valid;
    wire [8:0] S_slot,S_locked;
    wire [3:0] S_error;
    wire [31:0] S_misses,S_errors;
    reg S_row=0;
    reg [8:0] S_row_slot=0;
    reg [3:0] S_row_number=0;
    wire S_row_valid,S_row_missing;
    wire [15:0] S_row_bits;
    wire S_font_valid,S_font_ready,S_font_read_valid,S_font_read_ready,S_font_read_last,S_font_done,S_font_done_ready;
    wire [23:0] S_font_address;
    wire [15:0] S_font_tag,S_font_result_tag;
    wire [7:0] S_font_data;
    wire [3:0] S_font_error;
    wire S_initialized,S_restore,S_restore_found,S_save_ready,S_save_done;
    wire [239:0] S_restore_config;
    wire [3:0] S_restore_override,S_load_error,S_save_error;
    reg S_save=0,S_save_done_ready=0,S_busy_stuck=0,S_bad_last=0,S_bad_tag=0;
    wire S_cs,S_sclk,S_mosi,S_miso;
    integer S_i,S_j,S_before;
    reg [8:0] S_last_slot,S_locked_slot,S_pinned_slot,S_late_pinned_slot;
    reg S_background=0;
    reg [3:0] S_background_row;
    reg [2:0] S_background_states=0;
    reg S_background_collision=0;
    integer S_background_reads=0;
    player_settings #(.FLASH_TIMEOUT_CYCLES(10000)) u_settings (
        .I_host_clk(S_host_clk),.I_flash_clk(S_clk),.I_async_reset(S_reset),
        .O_initialized(S_initialized),.O_restore_valid(S_restore),.I_restore_ready(1'b1),
        .O_restore_found(S_restore_found),.O_restore_config(S_restore_config),.O_restore_override(S_restore_override),.O_load_error(S_load_error),
        .I_save_valid(S_save),.O_save_ready(S_save_ready),.I_config(240'd0),.I_override(4'd0),
        .O_save_done_valid(S_save_done),.I_save_done_ready(S_save_done_ready),.O_save_error(S_save_error),
        .I_font_valid(S_font_valid),.O_font_ready(S_font_ready),.I_font_address(S_font_address),.I_font_tag(S_font_tag),
        .O_font_read_valid(S_font_read_valid),.I_font_read_ready(S_font_read_ready),.O_font_read_data(S_font_data),
        .O_font_read_last(S_font_read_last),.O_font_done_valid(S_font_done),.I_font_done_ready(S_font_done_ready),
        .O_font_error(S_font_error),.O_font_tag(S_font_result_tag),
        .O_flash_cs_n(S_cs),.O_flash_sclk(S_sclk),.O_flash_mosi(S_mosi),.I_flash_miso(S_miso),
        .I_demo_valid(1'b0),
        .O_demo_ready(),
        .I_demo_address(24'd0),
        .I_demo_length(16'd0),
        .I_demo_tag(16'd0),
        .O_demo_read_valid(),
        .I_demo_read_ready(1'b1),
        .O_demo_read_data(),
        .O_demo_read_last(),
        .O_demo_done_valid(),
        .I_demo_done_ready(1'b1),
        .O_demo_error(),
        .O_demo_tag()
    );
    sim_spi_nor #(.MEMORY_BYTES(348288)) u_nor (
        .I_clk(S_clk),.I_cs_n(S_cs),.I_sclk(S_sclk),.I_mosi(S_mosi),
        .I_reject_wren(1'b0),.I_busy_stuck(S_busy_stuck),.I_corrupt_program(1'b0),.O_miso(S_miso)
    );
    glyph_cache #(.LOCK_LIMIT(2)) u_cache (
        .I_clk(S_clk),.I_reset(S_reset),.I_get_valid(S_get),.O_get_ready(S_get_ready),.I_code(S_code),.I_lock(S_lock),.I_pinned(S_pinned),
        .O_result_valid(S_result_valid),.I_result_ready(S_result_ready),.O_slot(S_slot),.O_error(S_error),
        .O_locked_count(S_locked),.O_miss_count(S_misses),.O_flash_error_count(S_errors),
        .I_row_valid(S_row),.I_row_slot(S_row_slot),.I_row(S_row_number),.O_row_valid(S_row_valid),.O_row_missing(S_row_missing),.O_row_bits(S_row_bits),
        .O_font_valid(S_font_valid),.I_font_ready(S_font_ready),.O_font_address(S_font_address),.O_font_tag(S_font_tag),
        .I_font_read_valid(S_font_read_valid),.O_font_read_ready(S_font_read_ready),.I_font_read_data(S_font_data),
        .I_font_read_last(S_font_read_last ^ (S_bad_last && u_cache.S_bytes==0)),
        .I_font_done_valid(S_font_done),.O_font_done_ready(S_font_done_ready),.I_font_error(S_font_error),
        .I_font_tag(S_font_result_tag ^ (S_bad_tag ? 16'd1 : 16'd0))
    );
    function [7:0] glyph_byte;
        input integer code,offset;
        begin glyph_byte=code*37+offset*13+code/256; end
    endfunction
    // The renderer's independent metadata/data ports must keep serving a pinned
    // glyph throughout lookup, CLOCK replacement and physical Flash filling.
    always @(negedge S_clk) if(S_background && !S_reset) begin
        S_row=1; S_row_slot=S_locked_slot; S_row_number=S_row_number+1'b1;
    end
    always @(posedge S_clk) if(S_background && !S_reset && S_row) begin
        S_background_row=S_row_number;
        if(u_cache.S_state==u_cache.LOOKUP) S_background_states[0]=1;
        if(u_cache.S_state==u_cache.VICTIM) S_background_states[1]=1;
        if(u_cache.S_state==u_cache.FILL) S_background_states[2]=1;
        if(u_cache.C_meta_write && u_cache.S_meta_address==S_row_slot) S_background_collision=1;
        #1;
        if(!S_row_valid || S_row_missing ||
            S_row_bits!=={glyph_byte(0,S_background_row*2),glyph_byte(0,S_background_row*2+1)})
            fail("concurrent protected glyph row lost");
        S_background_reads=S_background_reads+1;
    end
    task fail;
        input [511:0] message;
        begin $display("FAIL cache: %0s",message); $stop; end
    endtask
    task request;
        input [13:0] code;
        input lock;
        begin
            wait(S_get_ready); @(negedge S_clk); S_get=1; S_code=code; S_lock=lock;
            @(negedge S_clk); S_get=0; S_code=14'd8835; S_lock=!lock;
        end
    endtask
    task result;
        input [3:0] error;
        integer k;
        reg [12:0] held;
        begin
            wait(S_result_valid); held={S_slot,S_error}; S_last_slot=S_slot;
            repeat(3) begin
                @(negedge S_clk); if(!S_result_valid || {S_slot,S_error}!==held || S_get_ready) fail("result changed under backpressure");
            end
            if(S_error!==error) begin $display("actual=%0d expected=%0d",S_error,error); fail("cache error"); end
            S_result_ready=1; @(negedge S_clk); S_result_ready=0;
        end
    endtask
    task row;
        input [8:0] slot;
        input [3:0] number;
        input integer code;
        begin
            @(negedge S_clk); S_row=1; S_row_slot=slot; S_row_number=number;
            @(posedge S_clk); #1;
            if(!S_row_valid || S_row_missing || S_row_bits!=={glyph_byte(code,number*2),glyph_byte(code,number*2+1)})
                fail("synchronous glyph row/bit order or pinned row lost");
            @(negedge S_clk); S_row=0;
        end
    endtask
    task missing_row;
        input [8:0] slot;
        input [3:0] number;
        begin
            @(negedge S_clk); S_row=1; S_row_slot=slot; S_row_number=number;
            @(posedge S_clk); #1;
            if(!S_row_valid || !S_row_missing ||
                S_row_bits!==(number==0 || number==15 ? 16'hffff : 16'h8001))
                fail("missing glyph synchronous fallback");
            @(negedge S_clk); S_row=0;
        end
    endtask
    initial begin
        repeat(5) @(negedge S_clk);
        for(S_i=0;S_i<510;S_i=S_i+1)
            for(S_j=0;S_j<32;S_j=S_j+1) u_nor.S_memory[65536+S_i*32+S_j]=glyph_byte(S_i,S_j);
        for(S_j=0;S_j<32;S_j=S_j+1) u_nor.S_memory[65536+8835*32+S_j]=glyph_byte(8835,S_j);
        S_reset=0;
        missing_row(0,0); missing_row(0,5); missing_row(0,15);
        request(0,1); result(0); S_locked_slot=S_last_slot;
        if(!S_initialized || S_locked!=1) fail("boot arbitration/lock install");
        S_before=u_nor.S_reads; request(0,1); result(0);
        if(u_nor.S_reads!=S_before || S_locked!=1) fail("cache hit issued physical read or relocked");
        request(1,0); result(0); S_pinned_slot=S_last_slot; S_pinned[S_last_slot]=1;
        @(negedge S_clk); S_background=1;
        for(S_i=2;S_i<400;S_i=S_i+1) begin request(S_i,0); result(0); end
        request(400,0); result(0);
        if(S_last_slot==S_locked_slot || S_last_slot==S_pinned_slot) fail("CLOCK evicted locked/pinned slot");
        S_before=u_nor.S_reads; request(0,0); result(0); request(1,0); result(0);
        if(u_nor.S_reads!=S_before) fail("protected glyph not retained");
        @(negedge S_clk); S_background=0; #1; S_row=0;
        if(S_background_reads==0 || S_background_states!==3'b111 || !S_background_collision)
            fail("concurrent cache read/collision coverage");
        row(S_locked_slot,0,0); row(S_locked_slot,15,0); row(S_pinned_slot,5,1);
        missing_row(511,5); row(S_locked_slot,0,0);
        S_pinned={400{1'b1}}; S_before=u_nor.S_reads; request(401,0); result(2);
        if(u_nor.S_reads!=S_before) fail("full protected cache performed a read");
        S_pinned=0; S_pinned[S_pinned_slot]=1;
        // Add a live pin after candidate decoding, immediately before the
        // eviction decision. An earlier sampled pin mask would lose this pin.
        request(401,0);
        wait(u_cache.S_state==u_cache.VICTIM && u_cache.S_victim);
        @(negedge S_clk);
        S_late_pinned_slot=u_cache.S_cursor; S_pinned[S_late_pinned_slot]=1;
        result(0);
        if(S_last_slot==S_late_pinned_slot) fail("late pin did not protect eviction candidate");
        request(1,1); result(0); if(S_locked!=2) fail("lock existing glyph");
        request(402,1); result(3); request(8836,0); result(1);
        // Real SAVE reserves the complete sequence; RAM row reads keep working.
        wait(S_save_ready); @(negedge S_host_clk); S_save=1; @(negedge S_host_clk); S_save=0;
        wait(u_settings.S_flash_state==4);
        request(403,0); wait(S_font_valid);
        if(S_font_ready) fail("font request admitted inside SAVE sequence");
        for(S_i=0;S_i<16;S_i=S_i+1) row(S_locked_slot,S_i,0);
        result(0); wait(S_save_done);
        if(S_save_error!=0) fail("SAVE/queued glyph read interference");
        @(negedge S_host_clk); S_save_done_ready=1; @(negedge S_host_clk); S_save_done_ready=0;
        S_busy_stuck=1; request(404,0); result(4); S_busy_stuck=0;
        request(404,0); result(0);
        S_bad_last=1; request(405,0); result(4); S_bad_last=0;
        request(405,0); result(0);
        S_bad_tag=1; request(406,0); result(5); S_bad_tag=0;
        request(406,0); result(0);
        request(8835,0); result(0); row(S_last_slot,15,8835);
        if(S_errors!=3) fail("font error telemetry");
        // Metadata is cleared by a real bounded sweep after common reset;
        // stale glyph data may remain in RAM, but every old slot is invalid.
        @(negedge S_clk); S_reset=1; S_pinned=0;
        repeat(4) @(negedge S_clk); S_reset=0; #1;
        if(S_get_ready || S_result_valid) fail("cache admitted request before reset sweep");
        missing_row(S_last_slot,0);
        wait(S_get_ready);
        for(S_i=0;S_i<400;S_i=S_i+1) missing_row(S_i,5);
        request(8835,0); result(0); row(S_last_slot,15,8835);
        if(S_misses!=1 || S_locked!=0 || S_errors!=0) fail("metadata reset/reload accounting");
        O_done=1;
    end
endmodule

module font_text_case(output reg O_done=0);
    reg S_clk=0,S_reset=1,S_start=0,S_valid=0,S_last=0,S_abort=0,S_ready=0;
    always #5 S_clk=~S_clk;
    reg [5:0] S_length=0;
    reg [7:0] S_byte=0;
    wire S_start_ready,S_byte_ready,S_cell_valid,S_cell_last,S_busy,S_done;
    wire [15:0] S_cell;
    wire [1:0] S_error;
    wire [5:0] S_warnings;
    reg [7:0] S_bytes[0:39];
    reg [15:0] S_expected[0:39];
    integer S_count=0,S_total=0,S_tick=0,S_job=0;
    reg S_hold=0,S_waiting=0;
    reg [16:0] S_held;
    gb2312_text_decoder u_decode (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),.I_length(S_length),
        .I_byte_valid(S_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),.I_byte_last(S_last),.I_abort(S_abort),
        .O_valid(S_cell_valid),.I_ready(S_ready),.O_cell(S_cell),.O_last(S_cell_last),.O_busy(S_busy),
        .O_done(S_done),.O_error(S_error),.O_warnings(S_warnings)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL text: %0s",message); $stop; end
    endtask
    always @(negedge S_clk) S_ready=!S_hold && S_tick%5>=2;
    always @(posedge S_clk) if(!S_reset) begin
        S_tick=S_tick+1;
        if(S_waiting && !S_abort && (!S_cell_valid || {S_cell,S_cell_last}!==S_held)) fail("text cell changed while stalled");
        S_waiting=S_cell_valid && !S_ready; S_held={S_cell,S_cell_last};
        if(S_cell_valid && S_ready) begin
            if(S_count>=S_total || S_cell!==S_expected[S_count] || S_cell_last!==(S_count+1==S_total)) fail("decoded cell/order/last");
            S_count=S_count+1;
        end
    end
    task start;
        input [5:0] length;
        input integer cells;
        begin
            wait(S_start_ready); @(negedge S_clk); S_count=0; S_total=cells; S_length=length; S_start=1; S_waiting=0;
            @(negedge S_clk); S_start=0; S_job=S_job+1;
        end
    endtask
    task send;
        input integer first,count;
        integer k;
        begin
            for(k=first;k<first+count;k=k+1) begin
                @(negedge S_clk); S_valid=1; S_byte=S_bytes[k]; S_last=k+1==S_length;
                @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
                @(negedge S_clk); S_valid=0;
            end
        end
    endtask
    task finish;
        input [1:0] error;
        input [5:0] warnings;
        begin
            wait(S_done); if(S_error!==error || S_warnings!=warnings || (error==0 && S_count!=S_total)) fail("text terminal");
            @(negedge S_clk);
        end
    endtask
    initial begin
        repeat(5) @(negedge S_clk); S_reset=0;
        S_bytes[0]="A"; S_bytes[1]=8'hd6; S_bytes[2]=8'hd0; S_bytes[3]=8'hce; S_bytes[4]=8'hc4;
        S_bytes[5]="a"; S_bytes[6]=8'ha1; S_bytes[7]=" "; S_bytes[8]=8'hfe;
        S_expected[0]="A"; S_expected[1]=16'h8000+5029; S_expected[2]=16'h8000+4265; S_expected[3]="a";
        S_expected[4]="?"; S_expected[5]=" "; S_expected[6]="?";
        start(9,7); send(0,9); finish(0,2);
        S_bytes[0]=8'ha1; S_bytes[1]=8'ha1; S_bytes[2]=8'hfe; S_bytes[3]=8'hfe;
        S_expected[0]=16'h8000; S_expected[1]=16'h8000+8835;
        start(4,2); send(0,4); finish(0,0);
        S_bytes[0]=1; S_bytes[1]=8'hff; S_bytes[2]="Z";
        S_expected[0]="?"; S_expected[1]="?"; S_expected[2]="Z";
        start(3,3); send(0,3); finish(0,2);
        start(0,0); finish(0,0);
        start(41,0); finish(1,0);
        S_bytes[0]="Q"; start(1,1); S_hold=1; send(0,1);
        wait(S_cell_valid); repeat(4) @(negedge S_clk); S_abort=1;
        repeat(3) @(negedge S_clk); S_abort=0; S_hold=0;
        // done is a pulse and may occur during the asserted abort interval.
        wait(S_start_ready); if(S_error!=2 || S_count!=0) fail("abort held text offer");
        O_done=1;
    end
endmodule
