`timescale 1ns/1ps
// Actual byte decoder and text banks; cache/publication are explicit protocol peers.
module tb_osd_text_store;
    reg S_clk=0,S_reset=1,S_begin=0,S_line=0,S_byte_valid=0,S_byte_last=0,S_finish=0,S_abort=0;
    always #5 S_clk=~S_clk;
    wire S_begin_ready,S_line_ready,S_byte_ready,S_finish_ready,S_busy,S_done;
    reg S_done_ready=0;
    reg S_layer=0,S_lock=0;
    reg [3:0] S_line_index=0;
    reg [5:0] S_length=0;
    reg [7:0] S_byte=0;
    wire [3:0] S_error;
    wire S_cancel_late,S_active,S_active_bank;
    wire [31:0] S_misses;
    wire [399:0] S_pins;
    wire S_publish,S_publish_bank,S_publish_done_ready,S_discard;
    reg S_publish_ready=0,S_publish_done=0,S_published_bank=0,S_retired=0;
    wire S_get,S_get_lock,S_get_done_ready;
    wire [13:0] S_get_code;
    reg S_get_ready=1,S_get_done=0,S_hold_result=0;
    reg [8:0] S_get_slot=0;
    reg [3:0] S_get_error=0,S_peer_error=0;
    reg S_peer_pending=0;
    integer S_peer_delay=0;
    reg S_query_bank=0,S_query_layer=0,S_read=0;
    reg [3:0] S_query_line=0;
    reg [5:0] S_column=0;
    wire S_query_valid,S_read_valid;
    wire [9:0] S_x;
    wire [8:0] S_y;
    wire [1:0] S_color;
    wire [5:0] S_count;
    wire [15:0] S_cell;
    reg [7:0] S_bytes[0:39];
    reg S_first_bank,S_second_bank,S_test_pass=0;
    osd_text_store u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_begin_valid(S_begin),.O_begin_ready(S_begin_ready),
        .I_line_valid(S_line),.O_line_ready(S_line_ready),.I_layer(S_layer),.I_line(S_line_index),
        .I_x(10'd16),.I_y(9'd32),.I_color(2'd1),.I_lock(S_lock),.I_length(S_length),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),.I_byte_last(S_byte_last),
        .I_finish_valid(S_finish),.O_finish_ready(S_finish_ready),.I_abort(S_abort),
        .O_busy(S_busy),.O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),.O_cancel_late(S_cancel_late),
        .O_active_valid(S_active),.O_active_bank(S_active_bank),.O_glyph_misses(S_misses),.O_pinned(S_pins),
        .O_publish_valid(S_publish),.O_publish_bank(S_publish_bank),.I_publish_ready(S_publish_ready),
        .I_publish_done_valid(S_publish_done),.I_publish_done_bank(S_published_bank),.I_old_retired(S_retired),
        .O_publish_done_ready(S_publish_done_ready),.O_response_discarded(S_discard),
        .O_get_valid(S_get),.I_get_ready(S_get_ready),.O_get_code(S_get_code),.O_get_lock(S_get_lock),
        .I_get_result_valid(S_get_done),.O_get_result_ready(S_get_done_ready),.I_get_slot(S_get_slot),.I_get_error(S_get_error),
        .I_query_bank(S_query_bank),.I_query_layer(S_query_layer),.I_query_line(S_query_line),
        .O_query_valid(S_query_valid),.O_query_x(S_x),.O_query_y(S_y),.O_query_color(S_color),.O_query_count(S_count),
        .I_read_valid(S_read),.I_read_column(S_column),.O_read_valid(S_read_valid),.O_read_cell(S_cell)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL text store: %0s",message); $stop; end
    endtask
    always @(posedge S_clk) if(!S_reset) begin
        if(S_get && S_get_ready) begin
            if(S_peer_pending || S_get_done) fail("overlapping glyph requests");
            S_peer_pending<=1; S_peer_delay<=5; S_get_slot<=S_get_code==5029 ? 9'd7 : 9'd9;
            S_get_error<=S_peer_error;
        end
        if(S_peer_pending) begin
            if(S_peer_delay!=0) S_peer_delay<=S_peer_delay-1;
            else if(!S_hold_result) begin S_get_done<=1; S_peer_pending<=0; end
        end
        if(S_get_done && S_get_done_ready) S_get_done<=0;
    end
    task begin_frame;
        begin
            wait(S_begin_ready); @(negedge S_clk); S_begin=1;
            @(negedge S_clk); S_begin=0; wait(S_line_ready);
        end
    endtask
    task start_line;
        input [5:0] length;
        begin
            wait(S_line_ready); @(negedge S_clk); S_length=length; S_line=1;
            @(negedge S_clk); S_line=0;
        end
    endtask
    task send_bytes;
        input integer count;
        integer k;
        begin
            for(k=0;k<count;k=k+1) begin
                @(negedge S_clk); S_byte_valid=1; S_byte=S_bytes[k]; S_byte_last=k+1==S_length;
                @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
                @(negedge S_clk); S_byte_valid=0;
            end
        end
    endtask
    task read_cell;
        input bank;
        input [5:0] column;
        input [15:0] cell_value;
        begin
            @(negedge S_clk); S_query_bank=bank; S_column=column; S_read=1;
            @(posedge S_clk); #1;
            if(!S_read_valid || S_cell!==cell_value || !S_query_valid || S_x!=16 || S_y!=32 || S_color!=1) fail("resolved cell/descriptor read");
            @(negedge S_clk); S_read=0;
        end
    endtask
    task offer_frame;
        begin
            wait(S_finish_ready); @(negedge S_clk); S_finish=1; @(negedge S_clk); S_finish=0;
            wait(S_publish); repeat(4) begin @(negedge S_clk); if(!S_publish) fail("publication offer withdrawn"); end
            S_published_bank=S_publish_bank; S_publish_ready=1;
            @(negedge S_clk); S_publish_ready=0;
        end
    endtask
    task finish_frame;
        input [3:0] error;
        begin
            wait(S_done); if(S_error!==error) fail("frame terminal error");
            repeat(3) @(negedge S_clk);
            if(!S_done || S_begin_ready) fail("frame terminal not held");
            S_done_ready=1; @(negedge S_clk); S_done_ready=0;
        end
    endtask
    initial begin
        repeat(5) @(negedge S_clk); S_reset=0;
        begin_frame;
        S_bytes[0]="A"; S_bytes[1]=8'hd6; S_bytes[2]=8'hd0;
        start_line(3); send_bytes(3); wait(S_line_ready); S_first_bank=S_publish_bank;
        if(!S_pins[7] || S_active) fail("staging glyph pin/active identity");
        read_cell(S_first_bank,0,16'h0041); read_cell(S_first_bank,1,16'h8007);
        if(S_count!=2) fail("byte versus resolved cell count");
        offer_frame; S_publish_done=1; S_retired=0;
        repeat(8) begin @(negedge S_clk); if(S_publish_done_ready || S_active || !S_pins[7]) fail("early publication/retirement"); end
        S_retired=1; @(negedge S_clk); S_publish_done=0; S_retired=0; finish_frame(0);
        if(!S_active || S_active_bank!=S_first_bank || !S_pins[7]) fail("first actual bank activation");

        begin_frame; S_bytes[0]=8'hce; S_bytes[1]=8'hc4;
        start_line(2); send_bytes(2); wait(S_line_ready); S_second_bank=S_publish_bank;
        if(!S_pins[7] || !S_pins[9] || S_second_bank==S_first_bank) fail("active/staging pin union");
        read_cell(S_first_bank,1,16'h8007); read_cell(S_second_bank,0,16'h8009);
        offer_frame; S_publish_done=1;
        repeat(5) begin @(negedge S_clk); if(!S_pins[7] || !S_pins[9]) fail("old pins cleared before readers retired"); end
        S_retired=1; @(negedge S_clk); S_publish_done=0; S_retired=0; finish_frame(0);
        if(S_pins[7] || !S_pins[9]) fail("old pins not retired after actual publication");

        begin_frame; S_bytes[0]=8'hd6; S_bytes[1]=8'hd0; S_get_ready=0; S_hold_result=1;
        start_line(2); send_bytes(2); wait(S_get);
        @(negedge S_clk); S_abort=1; @(negedge S_clk); S_abort=0;
        repeat(6) begin @(negedge S_clk); if(!S_get || S_get_code!=5029 || S_done || !S_pins[9]) fail("cancel withdrew glyph offer/freed active"); end
        S_get_ready=1; wait(S_peer_pending); repeat(6) @(negedge S_clk);
        if(S_done) fail("cancel completed before actual glyph result");
        S_hold_result=0; finish_frame(2);
        if(S_pins[7] || !S_pins[9] || S_active_bank!=S_second_bank) fail("cancel changed active text");

        begin_frame; S_peer_error=4; start_line(2); send_bytes(2); wait(S_line_ready); S_peer_error=0;
        read_cell(S_publish_bank,0,16'h003f);
        if(S_misses!=1 || !S_pins[9]) fail("missing glyph fallback/pin accounting");
        wait(S_finish_ready); @(negedge S_clk); S_finish=1; @(negedge S_clk); S_finish=0;
        wait(S_publish); S_published_bank=S_publish_bank;
        S_abort=1; @(negedge S_clk); S_abort=0;
        if(!S_publish || !S_cancel_late) fail("presented publication cancellation");
        S_publish_ready=1; @(negedge S_clk); S_publish_ready=0;
        S_publish_done=1; S_retired=1; @(negedge S_clk); S_publish_done=0; S_retired=0; finish_frame(0);
        if(S_pins!=0 || !S_cancel_late) fail("fallback bank still pinned old glyph or lost late cancel");

        begin_frame; S_line_index=12; start_line(1); finish_frame(1);
        S_test_pass=1; $display("PASS: real decoder/text banks, cache pins, publication retirement and cancellation"); $finish;
    end
    initial begin #1000000; fail("text store watchdog"); end
endmodule
