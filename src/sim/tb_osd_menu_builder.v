`timescale 1ns/1ps
module tb_osd_menu_builder;
    reg S_clk=0,S_reset=1,S_start=0,S_ready=0;
    reg [15:0] S_value=0;
    wire S_start_ready,S_done,S_direct_done,S_held_done,S_serial_done,S_title_snapshot_done;
    wire [1:0] S_mailbox_done;
    wire [19:0] S_digits;
    reg S_test_pass=0;
    integer value,digit,rest;
    reg [19:0] expected,held;
    always #5 S_clk=~S_clk;
    osd_binary_decimal u_decimal (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_value(S_value),.O_done_valid(S_done),.I_done_ready(S_ready),.O_digits(S_digits));
    osd_menu_fixture #(.EXTERNAL(0)) u_direct(.O_pass(S_direct_done));
    osd_menu_fixture #(.EXTERNAL(1)) u_held(.O_pass(S_held_done));
    osd_menu_fixture #(.EXTERNAL(2)) u_serial(.O_pass(S_serial_done));
    osd_title_snapshot_fixture u_title_snapshot(.O_pass(S_title_snapshot_done));
    osd_mailbox_fixture u_mailbox(.O_pass(S_mailbox_done[0]));
    osd_mailbox_fixture #(.WIDTH(131)) u_wide_mailbox(.O_pass(S_mailbox_done[1]));
    initial begin
        repeat(4) @(negedge S_clk); S_reset=0;
        // Compare every 16-bit value against an independent arithmetic model.
        for(value=0;value<65536;value=value+1) begin
            @(negedge S_clk); S_value=value; S_start=1;
            @(posedge S_clk); if(!S_start_ready) begin $display("FAIL: decimal start"); $stop; end
            @(negedge S_clk); S_start=0; S_value=~value;
            wait(S_done); expected=0; rest=value;
            for(digit=0;digit<5;digit=digit+1) begin expected[digit*4+:4]=rest%10; rest=rest/10; end
            if(S_digits!==expected) begin $display("FAIL: decimal %0d got %h expected %h",value,S_digits,expected); $stop; end
            if(value%257==0) begin
                held=S_digits;
                repeat(3) begin @(negedge S_clk);
                    if(!S_done || S_start_ready || S_digits!==held) begin $display("FAIL: decimal result stall"); $stop; end
                end
            end
            @(negedge S_clk); S_ready=1;
            @(negedge S_clk); S_ready=0;
        end
        // Reset discards a partial conversion; the next request is independent.
        S_value=65535; S_start=1; @(negedge S_clk); S_start=0;
        repeat(7) @(negedge S_clk); S_reset=1;
        repeat(3) @(negedge S_clk); S_reset=0; #1;
        if(S_done || !S_start_ready) begin $display("FAIL: decimal reset"); $stop; end
        S_value=42; S_start=1; @(negedge S_clk); S_start=0; wait(S_done);
        if(S_digits!==20'h00042) begin $display("FAIL: decimal restart"); $stop; end
        wait(S_direct_done && S_held_done && S_serial_done && S_title_snapshot_done && (&S_mailbox_done));
        S_test_pass=1;
        $display("PASS: OSD decimal all 65536 values; menu/HUD/title/alert bytes, stalls and held snapshot CDC");
        $finish;
    end
    initial begin #30000000; $display("FAIL: OSD menu watchdog"); $stop; end
endmodule

// Actual title RAM/mailbox; patterned bytes are independent of menu formatting.
module osd_title_snapshot_fixture(output reg O_pass=0);
    reg S_host_clk=0,S_font_clk=0,S_run_host=1,S_run_font=1,S_reset=1;
    reg [589:0] S_input=0;
    reg [2879:0] S_titles=0;
    reg [31:0] S_serial=0;
    reg S_boundary=0,S_release=0,S_read=0;
    reg [3:0] S_line=0;
    reg [5:0] S_address=0;
    wire [589:0] S_output;
    wire S_valid;
    wire [7:0] S_data;
    integer i,j;
    always #4 if(S_run_host && !O_pass) S_host_clk=~S_host_clk;
    always #7 if(S_run_font && !O_pass) S_font_clk=~S_font_clk;
    osd_title_snapshot u_dut (
        .I_host_clk(S_host_clk),.I_font_clk(S_font_clk),.I_async_reset(S_reset),
        .I_boundary(S_boundary),.I_release(S_release),.I_state(S_input),.I_titles(S_titles),.I_serial(S_serial),
        .O_state(S_output),.O_state_valid(S_valid),.I_title_read(S_read),.I_title_line(S_line),
        .I_title_address(S_address),.O_title_data(S_data));
    task fail;
        input [511:0] message;
        begin $display("FAIL: title snapshot %0s",message); $stop; end
    endtask
    function [7:0] pattern;
        input integer seed,line,address;
        begin pattern=(seed+line*43+address*3)&255; end
    endfunction
    task set_titles;
        input integer seed;
        integer line,address;
        begin
            for(line=0;line<9;line=line+1)
                for(address=0;address<40;address=address+1)
                    S_titles[line*320+(39-address)*8+:8]=pattern(seed,line,address);
            S_serial=S_serial+1'b1;
        end
    endtask
    task receive;
        input [589:0] expected;
        begin
            wait(u_dut.S_state==u_dut.RETIRE);
            repeat(20) @(negedge S_font_clk);
            if(S_valid) fail("published before font boundary");
            S_boundary=1; @(negedge S_font_clk); S_boundary=0;
            if(!S_valid || S_output!==expected) fail("metadata not paired with title copy");
        end
    endtask
    task read_all;
        input integer seed;
        integer line,address;
        begin
            for(line=0;line<9;line=line+1)
                for(address=0;address<40;address=address+1) begin
                    @(negedge S_font_clk); S_read=1; S_line=line; S_address=address;
                    @(posedge S_font_clk); #1;
                    if(S_data!==pattern(seed,line,address)) fail("title RAM mixed versions or changed held bytes");
                end
            @(negedge S_font_clk); S_read=0;
            S_line=9; S_address=0; S_read=1;
            @(posedge S_font_clk); #1; if(S_data!==0) fail("invalid title line did not return zero");
            @(negedge S_font_clk); S_line=0; S_address=40;
            @(posedge S_font_clk); #1; if(S_data!==0) fail("invalid title address did not return zero");
            @(negedge S_font_clk); S_read=0;
        end
    endtask
    task retire;
        begin
            @(negedge S_font_clk); S_release=1;
            @(negedge S_font_clk); S_release=0;
            if(S_valid) fail("font release did not retire RAM ownership");
        end
    endtask
    // RAM cannot be overwritten while a released request is still travelling
    // back to host; the mailbox must actually return its capture credit first.
    always @(posedge S_host_clk) if(!S_reset && u_dut.S_state==u_dut.COPY) begin
        if(u_dut.u_state.S_request!=u_dut.u_state.S_ack_sync ||
            !u_dut.u_state.S_check) fail("copy overwrote a published RAM bank");
    end
    initial begin
        S_input[589]=1; S_input[137:131]=64; set_titles(17);
        repeat(5) @(negedge S_font_clk); S_reset=0;
        receive(S_input); read_all(17);
        @(negedge S_font_clk); S_run_font=0;
        @(negedge S_host_clk); set_titles(93); S_input[588]=1;
        repeat(50) @(negedge S_host_clk);
        if(!S_valid || !S_output[589] || S_output[588]) fail("stopped font released its metadata");
        S_run_font=1; read_all(17); retire;
        // Change serial mid-copy without changing any metadata fields. Neither
        // a partial copy nor the discarded comparison base may suppress retry.
        wait(u_dut.S_state==u_dut.COPY && u_dut.S_write_address==170);
        @(negedge S_host_clk); set_titles(151);
        receive(S_input); read_all(151); retire;
        // An unchanged candidate must not rebuild even after several full
        // copies and publication checks, with all font boundaries enabled.
        S_boundary=1;
        for(i=0;i<2000;i=i+1) begin
            @(negedge S_host_clk); if(S_valid) fail("unchanged titles produced a duplicate snapshot");
        end
        S_boundary=0;
        wait(u_dut.S_state==u_dut.COPY && u_dut.S_write_address==150);
        @(negedge S_host_clk); S_run_host=0;
        @(negedge S_font_clk); S_run_font=0; S_reset=1; #2;
        if(S_valid) fail("common reset did not invalidate stopped snapshot");
        S_serial=0; S_input=0; set_titles(211); #30; S_reset=0; #30;
        if(S_valid) fail("snapshot escaped reset without clocks");
        S_run_host=1; S_run_font=1;
        receive(590'd0); read_all(211); retire;
        O_pass=1;
        $display("PASS: title snapshot RAM bytes, serial retry, boundary/ownership, stopped font, reset and unchanged suppression");
    end
endmodule

// Held mailbox boundary/ownership tests, independent of menu formatting.
module osd_mailbox_fixture #(parameter integer WIDTH=16)(output reg O_pass=0);
    localparam [WIDTH-1:0] HIGH_BIT={1'b1,{(WIDTH-1){1'b0}}};
    localparam [WIDTH-1:0] MID_BIT={{(WIDTH-1){1'b0}},1'b1} << (WIDTH/2);
    reg S_host_clk=0,S_video_clk=0,S_run_host=1,S_run_video=1,S_reset=1;
    reg S_boundary=0,S_release=0;
    reg [WIDTH-1:0] S_input=0;
    wire [WIDTH-1:0] S_output;
    wire S_valid;
    always #4 if(S_run_host && !O_pass) S_host_clk=~S_host_clk;
    always #5 if(S_run_video && !O_pass) S_video_clk=~S_video_clk;
    video_ui_cdc #(.WIDTH(WIDTH),.HOLD_PAYLOAD(1)) u_dut (
        .I_capture_valid(1'b0),.I_publish_valid(1'b0),.I_discard_valid(1'b0),
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_frame_start(S_boundary),.I_release(S_release),.I_state(S_input),
        .O_state(S_output),.O_state_valid(S_valid));
    task fail;
        input [511:0] message;
        begin $display("FAIL: held mailbox width=%0d %0s",WIDTH,message); $stop; end
    endtask
    task receive;
        input [WIDTH-1:0] expected;
        begin
            repeat(24) @(negedge S_video_clk);
            if(S_valid) fail("published outside allowed boundary");
            S_boundary=1;
            @(negedge S_video_clk); S_boundary=0;
            if(!S_valid || S_output!==expected) fail("snapshot payload / initial zero publication");
        end
    endtask
    task release_snapshot;
        begin
            S_release=1; @(negedge S_video_clk); S_release=0;
            if(S_valid) fail("release did not retire snapshot");
        end
    endtask
    initial begin
        repeat(5) @(negedge S_video_clk); S_reset=0;
        receive(16'd0);
        // Keep only the latest state while the initial zero payload is owned.
        S_input=16'h1111;
        repeat(10) @(negedge S_video_clk); S_input=16'h2222;
        repeat(10) @(negedge S_video_clk);
        if(!S_valid || S_output!==0) fail("in-flight source update changed payload");
        @(negedge S_host_clk); S_run_host=0;
        release_snapshot;
        repeat(40) @(negedge S_video_clk);
        if(S_valid || S_output!==0) fail("stopped source fabricated a new snapshot");
        S_run_host=1; receive(16'h2222);
        // Destination pause must not release ownership, even as source changes.
        @(negedge S_video_clk); S_run_video=0; S_input=16'h3333;
        repeat(40) @(negedge S_host_clk);
        if(!S_valid || S_output!==16'h2222) fail("stopped destination released payload");
        S_run_video=1; @(negedge S_video_clk); release_snapshot;
        receive(16'h3333);
        // Compare against the old payload on the capture edge, not live input
        // on the following check edge. Exercise a partial final compare group.
        release_snapshot;
        @(negedge S_host_clk); while(!u_dut.S_capture) @(negedge S_host_clk);
        S_input=HIGH_BIT;
        @(posedge S_host_clk); #1; S_input=16'h4444;
        receive(HIGH_BIT); release_snapshot;
        receive(16'h4444);
        S_input=MID_BIT; release_snapshot; receive(MID_BIT);
        // Both clocks stopped: common asynchronous reset invalidates in-flight data.
        @(negedge S_host_clk); S_run_host=0;
        @(negedge S_video_clk); S_run_video=0; S_reset=1; #2;
        if(S_valid) fail("reset did not invalidate stopped mailbox");
        S_input=0; #30; S_reset=0; #30;
        if(S_valid) fail("reset released without destination clock");
        S_run_host=1; S_run_video=1;
        receive(16'd0); release_snapshot;
        repeat(40) @(negedge S_video_clk);
        if(S_valid) fail("duplicate publication after reset");
        O_pass=1;
        $display("PASS: held mailbox width=%0d atomic capture, partial groups, coalescing, stopped clocks and reset",WIDTH);
    end
endmodule

// Real builder; only text publication is an endpoint. EXTERNAL also uses real CDC.
module osd_menu_fixture #(parameter integer EXTERNAL=0)(output reg O_pass=0);
    reg S_host_clk=0,S_clk=0,S_run_host=1,S_reset=1;
    reg [3469:0] S_input=0;
    wire [3469:0] S_bus;
    wire S_snapshot_valid,S_snapshot_done,S_idle;
    wire S_begin,S_line_valid,S_byte_valid,S_last,S_finish,S_done_ready;
    wire S_layer,S_lock;
    wire [3:0] S_line,S_error;
    wire [9:0] S_x;
    wire [8:0] S_y;
    wire [1:0] S_color;
    wire [5:0] S_length;
    wire [7:0] S_byte;
    reg S_done=0;
    reg [3:0] S_result_error=0;
    integer S_cycle=0,S_begins=0,S_frames=0,S_pos=0,S_key=0,S_delay=0;
    reg S_receiving=0;
    wire S_begin_ready=S_cycle%7!=0;
    wire S_line_ready=!S_receiving && S_cycle%3!=0;
    wire S_byte_ready=S_receiving && S_cycle%5!=0;
    reg [319:0] S_expected[0:23];
    reg [5:0] S_lengths[0:23];
    reg [9:0] S_xs[0:23];
    reg [8:0] S_ys[0:23];
    reg [1:0] S_colors[0:23];
    reg S_locks[0:23];
    reg [23:0] S_seen=0,S_wanted=0;
    reg S_line_stalled=0,S_byte_stalled=0;
    reg [32:0] S_line_saved;
    reg [8:0] S_byte_saved;
    integer i,j,n,number,magnitude,target;
    reg [319:0] text;
    reg [3469:0] saved;
    always #4 if(S_run_host && !O_pass) S_host_clk=~S_host_clk;
    always #5 if(!O_pass) S_clk=~S_clk;
    reg [31:0] S_title_serial=0;
    wire S_title_read;
    wire [3:0] S_title_line;
    wire [5:0] S_title_address;
    wire [7:0] S_title_data;
    generate if(EXTERNAL==2) begin: g_serial
        wire [589:0] S_small;
        osd_title_snapshot u_snapshot (
            .I_host_clk(S_host_clk),.I_font_clk(S_clk),.I_async_reset(S_reset),
            .I_boundary(S_idle),.I_release(S_snapshot_done),
            .I_state({S_input[3469:3120],S_input[239:0]}),.I_titles(S_input[3119:240]),.I_serial(S_title_serial),
            .O_state(S_small),.O_state_valid(S_snapshot_valid),
            .I_title_read(S_title_read),.I_title_line(S_title_line),.I_title_address(S_title_address),.O_title_data(S_title_data));
        assign S_bus={S_small[589:240],2880'd0,S_small[239:0]};
    end else if(EXTERNAL!=0) begin: g_cdc
        assign S_title_data=8'd0;
        video_ui_cdc #(.WIDTH(3470),.HOLD_PAYLOAD(1)) u_cdc (
            .I_capture_valid(1'b0),.I_publish_valid(1'b0),.I_discard_valid(1'b0),
            .I_host_clk(S_host_clk),.I_video_clk(S_clk),.I_async_reset(S_reset),
            .I_frame_start(S_idle),.I_release(S_snapshot_done),.I_state(S_input),
            .O_state(S_bus),.O_state_valid(S_snapshot_valid));
    end else begin: g_direct
        assign S_title_data=8'd0;
        assign S_bus=S_input;
        assign S_snapshot_valid=1'b0;
    end endgenerate
    osd_menu_builder #(.EXTERNAL_SNAPSHOT(EXTERNAL),.EXTERNAL_TITLES(EXTERNAL==2)) u_builder (
        .I_clk(S_clk),.I_reset(S_reset),.I_snapshot_valid(S_snapshot_valid),.O_snapshot_done(S_snapshot_done),
        .I_ui(S_bus[47:0]),.I_hud(S_bus[48]),.I_fps_valid(S_bus[49]),.I_mem_valid(S_bus[50]),
        .I_fps(S_bus[66:51]),.I_video_und(S_bus[98:67]),.I_audio_und(S_bus[130:99]),
        .I_count(S_bus[137:131]),.I_index(S_bus[143:138]),
        .I_mem_busy(S_bus[164:144]),.I_mem_grant(S_bus[185:165]),
        .I_titles(S_bus[3119:240]),.I_title_lengths(S_bus[239:186]),.I_view(S_bus[3142:3120]),
        .O_title_read(S_title_read),.O_title_line(S_title_line),.O_title_address(S_title_address),.I_title_data(S_title_data),
        .I_alert(S_bus[3469]),.I_alert_length(S_bus[3468:3463]),.I_alert_text(S_bus[3462:3143]),
        .O_begin_valid(S_begin),.I_begin_ready(S_begin_ready),.O_line_valid(S_line_valid),.I_line_ready(S_line_ready),
        .O_layer(S_layer),.O_line(S_line),.O_x(S_x),.O_y(S_y),.O_color(S_color),.O_lock(S_lock),.O_length(S_length),
        .O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),.O_byte_last(S_last),
        .O_finish_valid(S_finish),.I_finish_ready(1'b1),.I_done_valid(S_done),.O_done_ready(S_done_ready),
        .O_idle(S_idle),.I_error(S_result_error),.O_error(S_error));
    task fail;
        input [511:0] message;
        begin $display("FAIL: OSD external=%0d frame=%0d key=%0d byte=%0d %0s",EXTERNAL,S_frames,S_key,S_pos,message); $stop; end
    endtask
    task expect_line;
        input integer key;
        input [319:0] bytes;
        input integer length,x,y,color,locked;
        begin
            S_expected[key]=bytes; S_lengths[key]=length; S_xs[key]=x; S_ys[key]=y;
            S_colors[key]=color; S_locks[key]=locked; S_wanted[key]=1;
        end
    endtask
    task clear_lines;
        begin
            S_wanted=0;
            for(i=0;i<24;i=i+1) begin S_expected[i]=0; S_lengths[i]=0; end
        end
    endtask
    function [39:0] decimal5;
        input integer value;
        integer k,rest;
        begin
            rest=value;
            for(k=0;k<5;k=k+1) begin decimal5[k*8+:8]=48+rest%10; rest=rest/10; end
        end
    endfunction
    task run_frame;
        begin
            target=S_frames+1; S_title_serial=S_title_serial+1'b1;
            wait(S_begins==target);
            // Live inputs change during the held transaction, then coalesce back.
            @(negedge S_clk); saved=S_input; S_input[66:51]=~saved[66:51];
            if(EXTERNAL!=0) S_run_host=0;
            repeat(11) @(negedge S_clk);
            if(EXTERNAL==2) begin
                if({S_bus[3469:3120],S_bus[239:0]}!=={saved[3469:3120],saved[239:0]}) fail("held serial snapshot changed");
            end else if(EXTERNAL!=0 && S_bus!==saved) fail("held source snapshot changed");
            S_input=saved; S_run_host=1;
            wait(S_frames==target);
            @(negedge S_clk);
            if(S_error!==S_result_error) fail("publication result");
            repeat(12) @(negedge S_clk);
            if(S_begins!=target || !S_idle) fail("unchanged state rebuilt / snapshot not released");
        end
    endtask
    always @(posedge S_clk) begin
        S_cycle<=S_cycle+1;
        if(!S_reset) begin
            if(S_line_stalled && (!S_line_valid || S_line_saved!==
                {S_layer,S_line,S_x,S_y,S_color,S_lock,S_length})) fail("line changed during stall");
            if(S_byte_stalled && (!S_byte_valid || S_byte_saved!=={S_byte,S_last})) fail("byte changed during stall");
            S_line_stalled<=S_line_valid && !S_line_ready;
            S_byte_stalled<=S_byte_valid && !S_byte_ready;
            S_line_saved<={S_layer,S_line,S_x,S_y,S_color,S_lock,S_length};
            S_byte_saved<={S_byte,S_last};
            if(S_begin && S_begin_ready) begin S_begins=S_begins+1; S_seen=0; end
            if(S_line_valid && S_line_ready) begin
                S_key=S_layer ? 12+S_line : S_line; S_pos=0; S_receiving<=1;
                if(S_key>=24 || !S_wanted[S_key] || S_seen[S_key]) fail("unexpected/duplicate line");
                if({S_length,S_x,S_y,S_color,S_lock}!==
                    {S_lengths[S_key],S_xs[S_key],S_ys[S_key],S_colors[S_key],S_locks[S_key]}) fail("line metadata");
                S_seen[S_key]=1;
            end
            if(S_byte_valid && S_byte_ready) begin
                if(S_byte!==S_expected[S_key][(39-S_pos)*8+:8] || S_last!==(S_pos+1==S_lengths[S_key]))
                    fail("line bytes / last");
                S_pos=S_pos+1;
                if(S_last) S_receiving<=0;
            end
            if(S_finish) begin
                if(S_receiving || S_seen!==S_wanted) fail("finish before complete expected lines");
                S_delay<=19;
            end else if(S_delay!=0) begin
                S_delay<=S_delay-1;
                if(S_delay==1) S_done<=1;
            end
            if(S_done && S_done_ready) begin S_done<=0; S_frames=S_frames+1; end
            if(EXTERNAL!=0 && S_snapshot_done && !(S_done && S_done_ready)) fail("snapshot retired before real result");
        end
    end
    initial begin
        clear_lines;
        S_input[9]=1; S_input[48]=1; S_input[49]=1; S_input[50]=1;
        S_input[66:51]=65535; S_input[98:67]=32'hdeadbeef; S_input[130:99]=32'h1234abcd;
        S_input[137:131]=64; S_input[143:138]=63;
        S_input[164:144]=1048576; S_input[185:165]=786432; S_input[3142]=1;
        expect_line(14,{72'h465053203635353335,248'd0},9,424,56,0,1);
        expect_line(15,{72'hcad3c6b5c7b7d4d820,64'h4445414442454546,184'd0},17,424,76,0,1);
        expect_line(16,{72'hd2f4c6b5c7b7d4d820,64'h3132333441424344,184'd0},17,424,96,0,1);
        expect_line(17,{80'h4954454d2036342f3634,240'd0},10,424,116,0,1);
        expect_line(18,{104'h42572031303025204730373525,216'd0},13,424,136,0,1);
        expect_line(19,320'hd7cad4b420554e4b4e4f574e00000000000000000000000000000000000000000000000000000000,12,424,156,0,1);
        repeat(5) @(negedge S_clk); S_reset=0;
        run_frame;
        // Positive, signed, overflowed rotation and decimal-width boundaries.
        for(j=0;j<15;j=j+1) begin
            clear_lines; @(negedge S_clk); S_input=0; S_input[3]=1;
            case(j)
                0:n=0; 1:n=9; 2:n=10; 3:n=99; 4:n=100; 5:n=999; 6:n=1000;
                7:n=9999; 8:n=10000; 9:n=32767; 10:n=32768; 11:n=65535;
                12:n=3; 13:n=400; default:n=65535;
            endcase
            S_input[47:32]=n; S_input[27:24]=j>=12 ? 6 : 0;
            number=j>=12 ? (n*90)&65535 : n;
            magnitude=number>=32768 ? (65536-number)&65535 : number;
            expect_line(12,320'hb2a5b7c5c9e8d6c30000000000000000000000000000000000000000000000000000000000000000,8,144,104,0,1);
            expect_line(13,320'hd7d4b6afb2a5b7c50000000000000000000000000000000000000000000000000000000000000000,8,144,128,1,1);
            expect_line(14,320'hcda3c1f4c3ebcafd0000000000000000000000000000000000000000000000000000000000000000,8,144,152,0,1);
            expect_line(15,320'hd7aab3a1d0a7b9fb0000000000000000000000000000000000000000000000000000000000000000,8,144,176,0,1);
            expect_line(16,320'hd7aab3a1cab1bce40000000000000000000000000000000000000000000000000000000000000000,8,144,200,0,1);
            expect_line(17,320'hb2a5b7c5cbb3d0f20000000000000000000000000000000000000000000000000000000000000000,8,144,224,0,1);
            expect_line(18,320'hd4ddcda3b2a5b7c50000000000000000000000000000000000000000000000000000000000000000,8,144,248,0,1);
            expect_line(19,{56'hb5b1c7b0d6b520,number>=32768 ? 8'd45 : 8'd43,decimal5(magnitude),216'd0},13,144,272,0,1);
            expect_line(20,320'hb0b4bcfc34b7b5bbd800000000000000000000000000000000000000000000000000000000000000,9,144,296,0,1);
            run_frame;
        end
        clear_lines; @(negedge S_clk); S_input=0; S_input[9]=1;
        S_input[3142]=1; S_input[3141:3139]=4; S_input[3138:3133]=3; S_input[3132:3127]=4;
        S_input[240+:320]={40{8'h41}}; S_input[186+:6]=40;
        S_input[560+:320]={{12{8'h42}},16'ha1a1,{26{8'h43}}}; S_input[192+:6]=40;
        S_input[2800+:320]={20{16'ha1a1}}; S_input[234+:6]=40;
        expect_line(0,{{13{8'h41}},216'd0},13,2,144,0,0);
        expect_line(1,{{12{8'h42}},16'ha1a1,208'd0},14,215,144,1,0);
        expect_line(8,{{13{16'ha1a1}},112'd0},26,428,464,0,0);
        run_frame;
        // Distinguish every title word and grid position, including middle rows.
        clear_lines; @(negedge S_clk); S_input=0; S_input[9]=1;
        S_input[3142]=1; S_input[3141:3139]=4; S_input[3132:3127]=63;
        for(j=0;j<9;j=j+1) begin
            for(n=0;n<40;n=n+1) text[(39-n)*8+:8]=65+j;
            S_input[240+j*320+:320]=text; S_input[186+j*6+:6]=40;
            expect_line(j,{text[319:216],216'd0},13,2+(j%3)*213,144+(j/3)*160,0,0);
        end
        run_frame;
        // A two-byte glyph may occupy the final cell without being split.
        clear_lines; @(negedge S_clk); S_input=0; S_input[9]=1; S_input[3142]=1;
        S_input[240+:320]={{38{8'h41}},16'ha1a1}; S_input[186+:6]=40;
        expect_line(0,{{38{8'h41}},16'ha1a1},40,8,456,0,0);
        run_frame;
        // A trailing lead byte has no complete glyph and is omitted.
        clear_lines; @(negedge S_clk); S_input[240+:320]={8'ha1,312'd0}; S_input[186+:6]=1;
        run_frame;
        clear_lines; @(negedge S_clk); S_input=0;
        S_input[3469]=1; S_input[3468:3463]=40;
        S_input[3462:3143]={{31{8'h41}},16'ha1a1,{7{8'h42}}};
        expect_line(12,{40'h414c455254,280'd0},5,64,184,3,1);
        expect_line(13,{{31{8'h41}},16'ha1a1,56'd0},33,64,232,0,0);
        expect_line(14,{{7{8'h42}},264'd0},7,64,256,0,0);
        S_result_error=2; run_frame;
        if(EXTERNAL!=0 && S_snapshot_valid) fail("held mailbox not released after error result");
        O_pass=1;
        $display("PASS: OSD menu fixture external=%0d, %0d complete frames",EXTERNAL,S_frames);
    end
endmodule
