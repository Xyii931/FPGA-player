`timescale 1ns/1ps
// Real console/line queue/UI and serial transceivers. Media owners are explicit fixtures.
module tb_player_console;
    reg S_clk=0,S_reset=1;
    always #4 S_clk=~S_clk;
    reg S_rx_valid=0,S_rx_error=0;
    reg [7:0] S_rx_data=0;
    wire S_tx_valid;
    reg S_tx_ready=1;
    wire [7:0] S_tx_data;
    wire S_request_valid,S_request_ready,S_result_valid,S_result_ready,S_result_pending;
    wire [4:0] S_op;
    wire [3:0] S_key,S_error;
    wire [15:0] S_value,S_base,S_effective;
    wire [5:0] S_text_length;
    wire [319:0] S_text;
    wire [239:0] S_config;
    wire S_auto,S_mute,S_pause,S_next,S_prev,S_goto,S_reload,S_rescan,S_menu,S_root,S_edit,S_confirm;
    wire [5:0] S_goto_index;
    wire [2:0] S_group;
    wire [3:0] S_row,S_menu_key,S_ui_error;
    wire [15:0] S_menu_value;
    wire S_board_interrupt,S_selftest,S_hold;
    wire [31:0] S_dropped;
    reg [3:0] S_keys=0,S_switch=0,S_switch_changed=0;
    reg S_busy=0,S_session_busy=0,S_session_ready=1;
    reg S_finish=0,S_scan_finish=0,S_force_busy=0;
    integer S_owner_count=0;
    reg [5:0] S_index=0;
    reg [2047:0] S_lines[0:63];
    reg [2047:0] S_line=0;
    integer S_line_count=0,S_checked=0;
    reg S_console_done=0,S_serial_done=0,S_test_pass=0;
    wire S_runtime_u_ui_O_order_override;
    reg [1:0] S_effective_order=0;
    reg S_effective_order_valid=0;
    wire S_restore_ready,S_save_valid,S_save_done_ready;
    reg S_restore_valid=0;
    reg [239:0] S_restore_config=0;
    wire S_alert,S_recovery;
    wire [5:0] S_alert_length;
    wire [319:0] S_alert_text;
    reg S_save_ready=1,S_save_done=0;
    reg [3:0] S_save_error=0;
    wire [2:0] S_policy_u_ui_O_default_override;
    player_ui_ctrl u_ui (
        .I_clk(S_clk),.I_reset(S_reset),.I_key_release(S_keys),.I_switch(S_switch),.I_switch_changed(S_switch_changed),
        .I_switch_initialized(1'b1),.I_active(1'b1),.I_player_busy(S_busy || S_force_busy),.I_fault(1'b0),
        .I_session_ready(S_session_ready),.I_session_busy(S_session_busy),.I_count(7'd4),.I_current_index(S_index),
        .I_request_valid(S_request_valid),.O_request_ready(S_request_ready),.I_request_op(S_op),.I_request_key(S_key),.I_request_value(S_value),
        .O_result_valid(S_result_valid),.I_result_ready(S_result_ready),.O_result_error(S_error),.O_result_pending(S_result_pending),
        .O_result_base(S_base),.O_result_effective(S_effective),.O_config(S_config),.O_auto(S_auto),.O_mute(S_mute),.O_pause(S_pause),
        .O_next(S_next),.O_prev(S_prev),.O_goto(S_goto),.O_reload(S_reload),.O_rescan(S_rescan),.O_goto_index(S_goto_index),
        .O_menu(S_menu),.O_menu_root(S_root),.O_menu_edit(S_edit),.O_menu_confirm(S_confirm),.O_menu_group(S_group),
        .O_menu_row(S_row),.O_menu_key(S_menu_key),.O_menu_value(S_menu_value),.O_board_interrupt(S_board_interrupt),
        .O_selftest(S_selftest),.O_ui_error(S_ui_error),
        .O_default_override(S_policy_u_ui_O_default_override),
        .I_effective_order(S_effective_order),
        .I_effective_order_valid(S_effective_order_valid),
        .I_settings_initialized(1'b1),.I_restore_valid(S_restore_valid),.I_restore_found(1'b1),
        .O_restore_ready(S_restore_ready),.I_restore_config(S_restore_config),.I_restore_override(4'd0),
        .O_save_valid(S_save_valid),.I_save_ready(S_save_ready),.I_save_done_valid(S_save_done),
        .O_save_done_ready(S_save_done_ready),.I_save_error(S_save_error),
        .O_order_override(S_runtime_u_ui_O_order_override),
        .I_request_text_length(S_text_length),
        .I_request_text(S_text),
        .O_alert(S_alert),
        .O_alert_length(S_alert_length),
        .O_alert_text(S_alert_text),
        .O_recovery(S_recovery)
    );
    player_console #(.LOG_CYCLES(1000000)) u_console (
        .I_clk(S_clk),.I_reset(S_reset),.I_rx_valid(S_rx_valid),.I_rx_frame_error(S_rx_error),.I_rx_data(S_rx_data),
        .O_tx_valid(S_tx_valid),.I_tx_ready(S_tx_ready),.O_tx_data(S_tx_data),.O_request_valid(S_request_valid),
        .I_request_ready(S_request_ready),.O_request_op(S_op),.O_request_key(S_key),.O_request_value(S_value),
        .O_request_text_length(S_text_length),.O_request_text(S_text),.I_result_valid(S_result_valid),.O_result_ready(S_result_ready),
        .I_result_error(S_error),.I_result_pending(S_result_pending),.I_result_base(S_base),.I_result_effective(S_effective),
        .I_player_busy(S_busy || S_force_busy),.I_active(1'b1),.I_fault(1'b0),.I_session_busy(S_session_busy),
        .I_session_ready(S_session_ready),.I_board_interrupt(S_board_interrupt),.I_selftest(S_selftest),
        .I_player_error(4'd0),.I_session_error(4'd0),.I_current_index(S_index),.I_count(7'd4),
        .I_media_status(16'h0803),.I_status(32'h0000c04f),.I_video_und(32'd3),.I_audio_und(32'd4),.I_fps(16'd59),
        .I_mem_busy_cycles(21'd7),.I_mem_grant_cycles(21'd5),.O_control_hold(S_hold),.O_dropped_lines(S_dropped)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: %0s",message); $stop; end
    endtask
    always @(posedge S_clk) if(!S_reset) begin
        if(S_next || S_prev || S_goto) begin
            S_busy<=1; S_owner_count=S_owner_count+1;
            if(S_goto) S_index<=S_goto_index;
            else if(S_next) S_index<=S_index==3 ? 6'd0 : S_index+1'b1;
            else S_index<=S_index==0 ? 6'd3 : S_index-1'b1;
        end
        if(S_finish) S_busy<=0;
        if(S_rescan || S_reload) begin S_session_busy<=1; S_session_ready<=0; end
        if(S_scan_finish) begin S_session_busy<=0; S_session_ready<=1; end
        if(S_tx_valid && S_tx_ready) begin
            S_line={S_line[2039:0],S_tx_data};
            if(S_tx_data==10) begin
                S_lines[S_line_count]=S_line; S_line_count=S_line_count+1; S_line=0;
            end
        end
    end
    task automatic send_byte;
        input [7:0] data;
        begin @(negedge S_clk); S_rx_data=data; S_rx_valid=1; @(negedge S_clk); S_rx_valid=0; end
    endtask
    task automatic command;
        input [1023:0] text;
        input integer length;
        integer i;
        begin
            for(i=length-1;i>=0;i=i-1) send_byte(text[i*8+:8]);
            send_byte(13); send_byte(10);
        end
    endtask
    task automatic expect_line;
        input [2047:0] text;
        begin
            wait(S_line_count>S_checked);
            if(S_lines[S_checked]!==text) begin
                $display("Expected: %0s actual: %0s",text,S_lines[S_checked]); fail("UART reply mismatch");
            end
            S_checked=S_checked+1;
        end
    endtask
    task automatic release_owner;
        begin @(negedge S_clk); S_finish=1; @(negedge S_clk); S_finish=0; end
    endtask
    task automatic board_key;
        input integer which;
        begin
            @(negedge S_clk); S_keys=4'b0001<<which; @(negedge S_clk); S_keys=0;
            repeat(12) @(negedge S_clk);
        end
    endtask
    // Independent byte-stream grammar oracle for the UI's fixed-lane validator.
    // Nondeclared upper bytes must not affect acceptance of right-aligned text.
    function alert_reference;
        input [319:0] text;
        input [5:0] length;
        integer position;
        reg pending,valid;
        reg [7:0] byte_value;
        begin
            pending=0; valid=length>=1 && length<=40;
            for(position=0;position<length && position<40;position=position+1) begin
                byte_value=(text >> ((length-position-1)*8));
                if(pending) begin
                    valid=valid && byte_value>=8'ha1 && byte_value<=8'hfe;
                    pending=0;
                end else if(byte_value>=8'ha1 && byte_value<=8'hfe) pending=1;
                else valid=valid && byte_value>=8'h20 && byte_value<=8'h7e;
            end
            alert_reference=valid && !pending;
        end
    endfunction
    integer S_before,S_j,S_length,S_byte,S_position,S_setting_key,S_setting_value,S_signed_value;
    reg [319:0] S_validation_text;
    reg S_validation_done=0;
    initial begin
        // Exercise every byte value at the start, middle and end of every
        // legal length, plus all GB2312 lead/trail combinations and bad lengths.
        for(S_length=0;S_length<=41;S_length=S_length+1)
            for(S_byte=0;S_byte<256;S_byte=S_byte+1)
                for(S_position=0;S_position<3;S_position=S_position+1) begin
                    S_validation_text={40{8'h41}};
                    case(S_position)
                        0:S_validation_text[7:0]=S_byte;
                        1:S_validation_text[159:152]=S_byte;
                        2:S_validation_text[319:312]=S_byte;
                    endcase
                    if(u_ui.valid_alert_text(S_validation_text,S_length)!==alert_reference(S_validation_text,S_length))
                        fail("alert validation changed byte grammar or declared length");
                end
        for(S_byte=0;S_byte<65536;S_byte=S_byte+1) begin
            S_validation_text={{38{8'hff}},S_byte[15:0]};
            if(u_ui.valid_alert_text(S_validation_text,6'd2)!==alert_reference(S_validation_text,6'd2))
                fail("alert validation changed two-byte grammar or used undeclared bytes");
        end
        // Exhaust all signed 16-bit offset inputs against the original signed
        // arithmetic rule, including extremes that truncate in the narrow path.
        for(S_setting_value=0;S_setting_value<65536;S_setting_value=S_setting_value+1) begin
            S_signed_value=S_setting_value>=32768 ? S_setting_value-65536 : S_setting_value;
            if(u_ui.valid_value(4'd11,S_setting_value)!==
                (S_signed_value>=-500 && S_signed_value<=500 && S_signed_value%10==0))
                fail("signed offset range or divisibility changed");
            // Every configuration admitted by restore/SET must stay valid in
            // both menu directions; task prevalidation relies on this invariant.
            for(S_setting_key=0;S_setting_key<15;S_setting_key=S_setting_key+1)
                if(u_ui.valid_value(S_setting_key,S_setting_value)) begin
                    if(!u_ui.valid_value(S_setting_key,u_ui.step_value(S_setting_key,S_setting_value,1'b0)) ||
                       !u_ui.valid_value(S_setting_key,u_ui.step_value(S_setting_key,S_setting_value,1'b1)))
                        fail("menu stepping escaped validated configuration range");
                end
        end
        S_validation_done=1;
    end
    initial begin
        repeat(5) @(negedge S_clk); S_reset=0; repeat(30) @(negedge S_clk);
        // Restore has priority, so an already presented UART request must stay
        // pending and execute once, after the real restore handshake.
        fork
            command("SET interval 20",15);
            begin
                wait(S_request_valid); @(negedge S_clk);
                S_restore_config=S_config; S_restore_config[31:16]=17; S_restore_valid=1;
                #1; if(S_request_ready || !S_restore_ready) fail("restore/request admission conflict");
                @(posedge S_clk); #1;
                if(S_config[31:16]!=17) fail("restore lost priority to a pending UART request");
                @(negedge S_clk); S_restore_valid=0;
            end
        join
        expect_line("OK\r\n");
        if(S_config[31:16]!=20) fail("request lost or acknowledged without effect during restore");
        command("pInG",4); expect_line("PONG\r\n");
        command("SET brightness -4",17); expect_line("OK\r\n");
        command("GET BRIGHTNESS",14); expect_line("OK base=-00004 effective=-00004\r\n");
        if(S_config[143:128]!==16'hfffc) fail("signed brightness not stored");
        command("SET brightness -5",17); expect_line("ERR range\r\n");
        command("SET interval 20",15); expect_line("OK\r\n");
        command("GET interval",12); expect_line("OK base=+00020 effective=+00020\r\n");
        if(!S_policy_u_ui_O_default_override[0]) fail("runtime interval override not recorded");
        command("SET transition random",21); expect_line("OK\r\n");
        if(S_config[34:32]!=7 || !S_policy_u_ui_O_default_override[1]) fail("random transition setting");
        // UI coding is LIST=0/NAME=1/RANDOM=2. Actual index commit may lag SET.
        if(S_runtime_u_ui_O_order_override) fail("order override before explicit edit");
        @(negedge S_clk); S_effective_order_valid=1; S_effective_order=0;
        command("SET order name",14); expect_line("OK\r\n");
        if(!S_runtime_u_ui_O_order_override || S_config[65:64]!=1) fail("order source or enum");
        command("GET order",9); expect_line("OK base=+00001 effective=+00000\r\n");
        @(negedge S_clk); S_effective_order=1;
        command("GET order",9); expect_line("OK base=+00001 effective=+00001\r\n");
        command("SET order random",16); expect_line("OK\r\n");
        command("GET order",9); expect_line("OK base=+00002 effective=+00001\r\n");
        command("SET mute 0",10); expect_line("OK\r\n");
        @(negedge S_clk); S_switch[1]=1; S_switch_changed=2;
        @(negedge S_clk); S_switch_changed=0;
        command("GET mute",8); expect_line("OK base=+00000 effective=+00001\r\n");
        command("PAUSE",5); expect_line("OK\r\n"); if(!S_pause) fail("PAUSE did not reach runtime owner");
        command("RESUME",6); expect_line("OK\r\n"); if(S_pause) fail("RESUME did not reach runtime owner");
        command("NEXT",4); expect_line("OK pending tag=00001\r\n");
        repeat(30) @(negedge S_clk);
        if(!S_busy || !S_hold || S_line_count!=S_checked) fail("long command falsely completed before owner retirement");
        command("PREV",4); expect_line("ERR busy\r\n");
        release_owner(); expect_line("DONE tag=00001\r\n");
        command("SCAN",4); expect_line("OK pending tag=00002\r\n");
        if(!S_session_busy) fail("SCAN did not use real session request");
        @(negedge S_clk); S_scan_finish=1; @(negedge S_clk); S_scan_finish=0;
        expect_line("DONE tag=00002\r\n");
        command("PLAY 4",6); expect_line("ERR range\r\n");
        command("SET rotation 90",15); expect_line("OK\r\n");
        wait(S_busy); if(S_config[111:96]!=1) fail("rotation enum or redraw request");
        release_owner(); repeat(20) @(negedge S_clk);
        // Actual alert state accepts text and OFF, including malformed GB2312 rejection.
        command("ALERT 2 Hello World",19); expect_line("OK\r\n");
        if(S_text_length!=11 || S_text!==320'd0+"Hello World") fail("ALERT remaining text changed case/spacing");
        if(!S_alert || S_alert_length!=11 || S_alert_text[319:232]!=="Hello World") fail("real alert text state");
        command("ALERT OFF",9); expect_line("OK\r\n");
        if(S_alert) fail("ALERT OFF did not retire timer state");
        command({"ALERT 2 ",16'ha1a1},10); expect_line("OK\r\n");
        if(!S_alert || S_alert_length!=2 || S_alert_text[319:304]!==16'ha1a1)
            fail("valid GB2312 pair did not reach actual alert state");
        command({"ALERT 2 ",8'ha1},9); expect_line("ERR range\r\n");
        command({"ALERT 2 ",16'ha120},10); expect_line("ERR range\r\n");
        command("ALERT 2 1234567890123456789012345678901234567890",48); expect_line("OK\r\n");
        if(S_alert_length!=40 || S_alert_text!=="1234567890123456789012345678901234567890" || !S_validation_done)
            fail("maximum alert text or independent grammar sweep");
        command("ALERT OFF",9); expect_line("OK\r\n");
        command("RECOVER",7); expect_line("OK\r\n");
        if(!S_recovery) fail("RECOVER did not select real recovery source");
        command("MODE PLAY",9); expect_line("OK\r\n");
        if(S_recovery) fail("MODE PLAY did not exit recovery source");
        command("RECOVER",7); expect_line("OK\r\n");
        command("RELOAD",6); expect_line("OK\r\n");
        if(S_recovery) fail("RELOAD did not exit recovery source");
        repeat(20) @(negedge S_clk);
        @(negedge S_clk); S_scan_finish=1;
        @(negedge S_clk); S_scan_finish=0;
        command("SAVE",4); wait(S_save_valid);
        repeat(40) @(negedge S_clk);
        if(S_line_count!=S_checked) fail("SAVE acknowledged before real store terminal");
        S_save_done=1; wait(S_save_done_ready); @(negedge S_clk); S_save_done=0;
        expect_line("OK\r\n");
        command("SAVE",4); wait(S_save_valid); repeat(20) @(negedge S_clk);
        S_save_error=6; S_save_done=1; wait(S_save_done_ready); @(negedge S_clk); S_save_done=0;
        expect_line("ERR io\r\n"); S_save_error=0;
        // Both line slots can queue during TX backpressure without mangling a suffix.
        S_tx_ready=0; command("PING",4); repeat(100) @(negedge S_clk);
        command("GET volume",10); command("GET mute",8);
        repeat(100) @(negedge S_clk); S_tx_ready=1;
        expect_line("PONG\r\n"); expect_line("OK base=+00012 effective=+00012\r\n"); expect_line("OK base=+00000 effective=+00001\r\n");
        // Overlong text must not execute even if its suffix is a valid command.
        S_before=S_owner_count;
        for(S_j=0;S_j<130;S_j=S_j+1) send_byte("X");
        command("NEXT",4); expect_line("ERR range\r\n");
        if(S_owner_count!=S_before) fail("truncated command suffix executed");
        send_byte("N"); @(negedge S_clk); S_rx_error=1; @(negedge S_clk); S_rx_error=0;
        command("EXT",3); expect_line("ERR io\r\n");
        command("NEXT",4); expect_line("OK pending tag=00003\r\n");
        board_key(1); expect_line("ERR tag=00003 superseded\r\n"); release_owner();
        repeat(20) @(negedge S_clk);
        // Root -> DISPLAY -> BRIGHTNESS edit is the same config bank as UART.
        board_key(3); board_key(1); board_key(2);
        board_key(1); board_key(1); board_key(1); board_key(2); board_key(1);
        if(!S_menu || S_root || !S_edit || S_group!=1 || S_row!=3 || S_config[143:128]!==16'hfffd)
            fail("menu edit is not connected to UART configuration bank");
        board_key(3); board_key(3); board_key(3);
        if(S_menu) fail("KEY4 menu/back hierarchy");
        command("MODE THUMB",10); expect_line("OK\r\n");
        wait(S_busy);
        if(S_config[82:80]!=4 || S_auto) fail("THUMB mode has no layout consumer or still auto-advances");
        release_owner(); repeat(20) @(negedge S_clk);
        board_key(2); wait(S_busy);
        if(S_config[82:80]!=0) fail("THUMB KEY3 did not select current item in FULL");
        release_owner(); repeat(20) @(negedge S_clk);
        command("DEFAULT",7); expect_line("OK\r\n");
        if(!S_runtime_u_ui_O_order_override || S_config[65:64]!=0) fail("DEFAULT order source");
        S_console_done=1;
    end

    reg S_serial_valid=0;
    reg [7:0] S_serial_data=0;
    wire S_serial_ready,S_serial_tx,S_serial_rx_valid,S_serial_rx_error;
    wire [7:0] S_serial_rx_data;
    reg [7:0] S_serial_expected=0;
    integer S_serial_count=0;
    uart_tx #(.CLOCK_HZ(1000000),.BAUD(100000)) u_tx (
        .I_clk(S_clk),.I_reset(S_reset),.I_valid(S_serial_valid),.O_ready(S_serial_ready),.I_data(S_serial_data),.O_tx(S_serial_tx)
    );
    uart_rx #(.CLOCK_HZ(1000000),.BAUD(100000)) u_rx (
        .I_clk(S_clk),.I_reset(S_reset),.I_rx(S_serial_tx),.O_valid(S_serial_rx_valid),.O_frame_error(S_serial_rx_error),.O_data(S_serial_rx_data)
    );
    always @(posedge S_clk) if(!S_reset) begin
        if(S_serial_rx_error) fail("8N1 loopback framing");
        if(S_serial_rx_valid) begin
            if(S_serial_rx_data!==S_serial_expected) fail("8N1 LSB-first byte mismatch");
            S_serial_count=S_serial_count+1;
        end
    end
    task automatic serial_byte;
        input [7:0] value;
        integer wanted;
        begin
            wait(S_serial_ready); @(negedge S_clk); S_serial_data=value; S_serial_expected=value; S_serial_valid=1;
            wanted=S_serial_count+1; @(negedge S_clk); S_serial_valid=0;
            wait(S_serial_count==wanted);
        end
    endtask
    initial begin
        wait(!S_reset); serial_byte(8'ha5); serial_byte(0); serial_byte(255); serial_byte(8'h3c); S_serial_done=1;
    end
    initial begin
        wait(S_console_done && S_serial_done); S_test_pass=1;
        $display("PASS: console/UI/line ownership/real completion fixtures and 8N1 transceivers"); $finish;
    end
    initial begin #10000000; fail("player_console watchdog"); end
endmodule
