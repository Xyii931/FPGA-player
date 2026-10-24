`timescale 1ns/1ps
// Actual text/cache/render/CDC/row RAM, real raster. Font bytes are explicit fixtures.
module tb_osd_text_video;
    reg S_host_clk=0,S_video_clk=0,S_run_host=1,S_reset=1;
    initial forever begin #5; if(S_run_host) S_host_clk=~S_host_clk; end
    always #20 S_video_clk=~S_video_clk;
    wire S_de,S_frame,S_line_start,S_hs,S_vs;
    wire [15:0] S_x,S_y,S_rx,S_ry;
    video_timing u_timing (
        .I_clk(S_video_clk),.I_reset(S_reset),.O_hsync(S_hs),.O_vsync(S_vs),.O_de(S_de),
        .O_x(S_x),.O_y(S_y),.O_frame_start(S_frame),.O_line_start(S_line_start),.O_raster_x(S_rx),.O_raster_y(S_ry)
    );
    reg S_begin=0,S_line=0,S_layer=0,S_bytes_valid=0,S_last=0,S_finish=0;
    reg [7:0] S_byte=0;
    reg [5:0] S_length=0;
    reg [1:0] S_color=0;
    wire S_begin_ready,S_line_ready,S_bytes_ready,S_finish_ready,S_busy,S_done,S_cancel_late,S_active,S_active_bank,S_discard;
    wire [3:0] S_error;
    wire [8:0] S_locked;
    wire [31:0] S_glyph_misses,S_cache_misses,S_flash_errors,S_missing_rows,S_line_misses;
    wire S_font_valid,S_font_read_ready,S_font_done_ready;
    reg S_font_ready=0,S_font_read=0,S_font_last=0,S_font_done=0;
    wire [23:0] S_font_address;
    wire [15:0] S_font_tag;
    reg [15:0] S_font_result_tag=0;
    reg [7:0] S_font_data=0;
    reg [5:0] S_font_index=0;
    reg [2:0] S_font_state=0;
    wire S_out_valid,S_out_de;
    wire [15:0] S_out_x,S_out_y;
    wire [23:0] S_out_rgb;
    reg [7:0] S_source[0:39];
    integer S_frames=0,S_checked=0,S_before;
    reg S_check=0,S_test_pass=0;
    reg [15:0] S_seen_x,S_seen_y;
    reg S_seen_de;
    reg [23:0] S_expected;
    osd_text_video u_dut (
        .I_font_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_begin_valid(S_begin),.O_begin_ready(S_begin_ready),.I_line_valid(S_line),.O_line_ready(S_line_ready),
        .I_layer(S_layer),.I_line(4'd0),.I_x(10'd16),.I_y(9'd32),.I_color(S_color),.I_lock(1'b0),.I_length(S_length),
        .I_byte_valid(S_bytes_valid),.O_byte_ready(S_bytes_ready),.I_byte_data(S_byte),.I_byte_last(S_last),
        .I_finish_valid(S_finish),.O_finish_ready(S_finish_ready),.I_abort(1'b0),.O_busy(S_busy),
        .O_done_valid(S_done),.I_done_ready(1'b1),.O_error(S_error),.O_cancel_late(S_cancel_late),
        .O_active_valid(S_active),.O_active_bank(S_active_bank),.O_glyph_misses(S_glyph_misses),.O_response_discarded(S_discard),
        .O_locked_count(S_locked),.O_miss_count(S_cache_misses),.O_flash_error_count(S_flash_errors),
        .O_font_valid(S_font_valid),.I_font_ready(S_font_ready),.O_font_address(S_font_address),.O_font_tag(S_font_tag),
        .I_font_read_valid(S_font_read),.O_font_read_ready(S_font_read_ready),.I_font_read_data(S_font_data),
        .I_font_read_last(S_font_last),.I_font_done_valid(S_font_done),.O_font_done_ready(S_font_done_ready),
        .I_font_error(4'd0),.I_font_tag(S_font_result_tag),.O_missing_rows(S_missing_rows),
        .I_frame_start(S_frame),.I_video_valid(1'b1),.I_de(S_de),.I_video_x(S_x),.I_video_y(S_y),.I_rgb(24'h203040),
        .O_valid(S_out_valid),.O_de(S_out_de),.O_x(S_out_x),.O_y(S_out_y),.O_rgb(S_out_rgb),.O_line_misses(S_line_misses)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL video OSD: %0s",message); $stop; end
    endtask
    function [15:0] font_row;
        input integer row;
        begin font_row=16'h8000>>row; end
    endfunction
    function ascii_ink;
        input integer ch,x,y;
        reg [34:0] bits;
        integer row,column;
        begin
            bits=ch==65 ? 35'b01110_10001_10001_11111_10001_10001_10001 :
                35'b11110_10001_10001_11110_10001_10001_11110;
            row=(y-1)/2; column=x-1;
            ascii_ink=0;
            if(y>=1 && y<=14 && x>=1 && x<=5) ascii_ink=bits[(6-row)*5+4-column];
        end
    endfunction
    always @(negedge S_host_clk) if(!S_reset) begin
        case(S_font_state)
            0:begin S_font_ready=1; if(S_font_valid) begin
                if(S_font_address!=24'h010000) fail("font address");
                S_font_result_tag=S_font_tag; S_font_index=0; S_font_state=1;
            end end
            1:begin S_font_ready=0; S_font_state=2; end
            2:begin
                S_font_data=S_font_index[0] ? font_row(S_font_index/2) : font_row(S_font_index/2)>>8;
                S_font_last=S_font_index==31; S_font_read=1; S_font_state=3;
            end
            3:if(S_font_read_ready) begin
                S_font_read=0;
                if(S_font_index==31) S_font_state=4;
                else begin S_font_index=S_font_index+1'b1; S_font_state=2; end
            end
            4:begin S_font_done=1; S_font_state=5; end
            5:if(S_font_done_ready) begin S_font_done=0; S_font_state=0; end
            default:S_font_state=0;
        endcase
    end
    always @(posedge S_video_clk) if(!S_reset) begin
        if(S_frame) S_frames=S_frames+1;
        S_seen_x=S_x; S_seen_y=S_y; S_seen_de=S_de;
        #1;
        if(S_check) begin
            if(!S_out_valid || S_out_de!==S_seen_de || S_out_x!==S_seen_x || S_out_y!==S_seen_y) fail("one-cycle raster alignment");
            S_expected=S_seen_de ? 24'h203040 : 24'd0;
            if(S_seen_de && S_seen_y>=32 && S_seen_y<48) begin
                // The source row is a diagonal 1-bit glyph; foreground ASCII has priority.
                if(S_seen_x>=16 && S_seen_x<32 && S_seen_x-16==S_seen_y-32) S_expected=24'h40c0ff;
                if(S_seen_x>=32 && S_seen_x<40 && ascii_ink(66,S_seen_x-32,S_seen_y-32)) S_expected=24'h40c0ff;
                if(S_seen_x>=16 && S_seen_x<24 && ascii_ink(65,S_seen_x-16,S_seen_y-32)) S_expected=24'hffff40;
            end
            if(S_out_rgb!==S_expected) begin
                $display("x=%0d y=%0d actual=%06h expected=%06h",S_seen_x,S_seen_y,S_out_rgb,S_expected);
                fail("two-layer glyph pixel/priority comparison");
            end
            if(S_seen_de) S_checked=S_checked+1;
        end
    end
    task add_line;
        input layer;
        input [1:0] color;
        input [5:0] length;
        integer k;
        begin
            wait(S_line_ready); @(negedge S_host_clk); S_layer=layer; S_color=color; S_length=length; S_line=1;
            @(negedge S_host_clk); S_line=0;
            for(k=0;k<length;k=k+1) begin
                @(negedge S_host_clk); S_bytes_valid=1; S_byte=S_source[k]; S_last=k+1==length;
                @(posedge S_host_clk); while(!S_bytes_ready) @(posedge S_host_clk);
                @(negedge S_host_clk); S_bytes_valid=0;
            end
            wait(S_line_ready);
        end
    endtask
    initial begin
        repeat(5) @(negedge S_host_clk); S_reset=0;
        wait(S_begin_ready); @(negedge S_host_clk); S_begin=1; @(negedge S_host_clk); S_begin=0;
        S_source[0]=8'ha1; S_source[1]=8'ha1; S_source[2]="B"; add_line(0,1,3);
        S_source[0]="A"; add_line(1,2,1);
        wait(S_finish_ready); @(negedge S_host_clk); S_finish=1; @(negedge S_host_clk); S_finish=0;
        wait(S_done); if(S_error!=0 || !S_active || S_cache_misses!=1) fail("actual text publication");
        wait(S_frame); @(negedge S_video_clk); S_check=1; S_before=S_frames;
        wait(S_frames>S_before); @(negedge S_video_clk); S_check=0;
        if(S_checked!=640*480 || S_missing_rows!=0 || S_glyph_misses!=0) fail("full-frame coverage");
        // Stopped producer leaves video running and reports missed rows, then recovers.
        wait(S_de && S_x==0 && S_y==100); @(negedge S_host_clk); S_run_host=0;
        S_before=S_line_misses; repeat(4000) @(negedge S_video_clk);
        if(S_line_misses<=S_before) fail("stopped producer deadline detection");
        S_run_host=1;
        wait(S_frame); @(negedge S_video_clk); S_check=1; S_before=S_frames;
        wait(S_frames>S_before); @(negedge S_video_clk); S_check=0;
        S_test_pass=1; $display("PASS: actual text/glyph/renderer/dual-clock line RAM and full-frame pixels"); $finish;
    end
    initial begin #150000000; fail("video OSD watchdog"); end
endmodule
