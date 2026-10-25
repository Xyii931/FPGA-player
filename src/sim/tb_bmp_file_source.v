`timescale 1ns/1ps
// Real source/parser; file protocol endpoints are explicit stimulus.
module tb_bmp_file_source;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    reg  S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg  S_I_start_valid=0;
    wire  S_O_start_ready;
    wire  S_O_lease_request;
    reg  S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_sector_budget=0;
    reg [6:0] S_I_path_length=0;
    reg  S_I_path_valid=0;
    wire  S_O_path_ready;
    reg [7:0] S_I_path_data=0;
    reg  S_I_path_last=0;
    reg  S_I_abort=0;
    wire  S_O_lease_active;
    wire  S_O_busy;
    wire  S_O_done_valid;
    reg  S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [3:0] S_O_parser_error;
    wire [7:0] S_O_file_error;
    wire [3:0] S_O_storage_error;
    wire [2:0] S_O_path_warning;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_file_size;
    wire  S_O_parser_started;
    wire  S_O_header_valid;
    reg  S_I_header_ready=0;
    wire [15:0] S_O_width;
    wire [15:0] S_O_height;
    wire  S_O_bottom_up;
    wire [5:0] S_O_bpp;
    wire [31:0] S_O_pixel_offset;
    wire [31:0] S_O_row_bytes;
    wire  S_O_pixel_valid;
    reg  S_I_pixel_ready=0;
    wire [31:0] S_O_rgba;
    wire [15:0] S_O_x;
    wire [15:0] S_O_y;
    wire  S_O_pixel_last;
    wire  S_O_fs_open_valid;
    reg  S_I_fs_open_ready=0;
    wire [1:0] S_O_fs_open_context;
    wire [15:0] S_O_fs_open_tag;
    wire [6:0] S_O_fs_path_length;
    wire [31:0] S_O_fs_sector_budget;
    wire  S_O_fs_path_valid;
    reg  S_I_fs_path_ready=0;
    wire [7:0] S_O_fs_path_data;
    wire  S_O_fs_path_last;
    wire  S_O_fs_open_cancel;
    reg  S_I_fs_open_result_valid=0;
    wire  S_O_fs_open_result_ready;
    reg [1:0] S_I_fs_open_context=0;
    reg [15:0] S_I_fs_open_tag=0;
    reg [31:0] S_I_fs_open_generation=0;
    reg [31:0] S_I_fs_open_size=0;
    reg [7:0] S_I_fs_open_error=0;
    reg [3:0] S_I_fs_open_storage_error=0;
    reg [2:0] S_I_fs_open_warning=0;
    wire  S_O_fs_read_valid;
    reg  S_I_fs_read_ready=0;
    wire [1:0] S_O_fs_read_context;
    wire [1:0] S_O_fs_read_priority;
    wire [31:0] S_O_fs_offset;
    wire [31:0] S_O_fs_length;
    wire [15:0] S_O_fs_epoch;
    reg  S_I_fs_byte_valid=0;
    wire  S_O_fs_byte_ready;
    reg [7:0] S_I_fs_byte_data=0;
    reg [1:0] S_I_fs_byte_context=0;
    reg [15:0] S_I_fs_byte_epoch=0;
    reg [31:0] S_I_fs_byte_generation=0;
    reg [31:0] S_I_fs_byte_offset=0;
    reg  S_I_fs_byte_last=0;
    reg  S_I_fs_done_valid=0;
    wire  S_O_fs_done_ready;
    reg [1:0] S_I_fs_done_context=0;
    reg [15:0] S_I_fs_done_epoch=0;
    reg [31:0] S_I_fs_done_generation=0;
    reg [31:0] S_I_fs_done_bytes=0;
    reg  S_I_fs_done_eof=0;
    reg [7:0] S_I_fs_done_error=0;
    reg [3:0] S_I_fs_done_storage_error=0;
    wire  S_O_fs_cancel_valid;
    reg  S_I_fs_cancel_ready=0;
    wire [1:0] S_O_fs_cancel_context;
    wire [15:0] S_O_fs_cancel_epoch;
    reg  S_I_fs_cancel_done_valid=0;
    wire  S_O_fs_cancel_done_ready;
    reg [1:0] S_I_fs_cancel_done_context=0;
    reg [15:0] S_I_fs_cancel_done_epoch=0;
    reg [31:0] S_I_fs_cancel_done_generation=0;
    wire  S_O_fs_close_valid;
    reg  S_I_fs_close_ready=0;
    wire [1:0] S_O_fs_close_context;
    bmp_file_source u_source (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_sector_budget(S_I_sector_budget),
        .I_path_length(S_I_path_length),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
        .I_abort(S_I_abort),
        .O_lease_active(S_O_lease_active),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_parser_error(S_O_parser_error),
        .O_file_error(S_O_file_error),
        .O_storage_error(S_O_storage_error),
        .O_path_warning(S_O_path_warning),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_file_size(S_O_file_size),
        .O_parser_started(S_O_parser_started),
        .O_header_valid(S_O_header_valid),
        .I_header_ready(S_I_header_ready),
        .O_width(S_O_width),
        .O_height(S_O_height),
        .O_bottom_up(S_O_bottom_up),
        .O_bpp(S_O_bpp),
        .O_pixel_offset(S_O_pixel_offset),
        .O_row_bytes(S_O_row_bytes),
        .O_pixel_valid(S_O_pixel_valid),
        .I_pixel_ready(S_I_pixel_ready),
        .O_rgba(S_O_rgba),
        .O_x(S_O_x),
        .O_y(S_O_y),
        .O_pixel_last(S_O_pixel_last),
        .O_fs_open_valid(S_O_fs_open_valid),
        .I_fs_open_ready(S_I_fs_open_ready),
        .O_fs_open_context(S_O_fs_open_context),
        .O_fs_open_tag(S_O_fs_open_tag),
        .O_fs_path_length(S_O_fs_path_length),
        .O_fs_sector_budget(S_O_fs_sector_budget),
        .O_fs_path_valid(S_O_fs_path_valid),
        .I_fs_path_ready(S_I_fs_path_ready),
        .O_fs_path_data(S_O_fs_path_data),
        .O_fs_path_last(S_O_fs_path_last),
        .O_fs_open_cancel(S_O_fs_open_cancel),
        .I_fs_open_result_valid(S_I_fs_open_result_valid),
        .O_fs_open_result_ready(S_O_fs_open_result_ready),
        .I_fs_open_context(S_I_fs_open_context),
        .I_fs_open_tag(S_I_fs_open_tag),
        .I_fs_open_generation(S_I_fs_open_generation),
        .I_fs_open_size(S_I_fs_open_size),
        .I_fs_open_error(S_I_fs_open_error),
        .I_fs_open_storage_error(S_I_fs_open_storage_error),
        .I_fs_open_warning(S_I_fs_open_warning),
        .O_fs_read_valid(S_O_fs_read_valid),
        .I_fs_read_ready(S_I_fs_read_ready),
        .O_fs_read_context(S_O_fs_read_context),
        .O_fs_read_priority(S_O_fs_read_priority),
        .O_fs_offset(S_O_fs_offset),
        .O_fs_length(S_O_fs_length),
        .O_fs_epoch(S_O_fs_epoch),
        .I_fs_byte_valid(S_I_fs_byte_valid),
        .O_fs_byte_ready(S_O_fs_byte_ready),
        .I_fs_byte_data(S_I_fs_byte_data),
        .I_fs_byte_context(S_I_fs_byte_context),
        .I_fs_byte_epoch(S_I_fs_byte_epoch),
        .I_fs_byte_generation(S_I_fs_byte_generation),
        .I_fs_byte_offset(S_I_fs_byte_offset),
        .I_fs_byte_last(S_I_fs_byte_last),
        .I_fs_done_valid(S_I_fs_done_valid),
        .O_fs_done_ready(S_O_fs_done_ready),
        .I_fs_done_context(S_I_fs_done_context),
        .I_fs_done_epoch(S_I_fs_done_epoch),
        .I_fs_done_generation(S_I_fs_done_generation),
        .I_fs_done_bytes(S_I_fs_done_bytes),
        .I_fs_done_eof(S_I_fs_done_eof),
        .I_fs_done_error(S_I_fs_done_error),
        .I_fs_done_storage_error(S_I_fs_done_storage_error),
        .O_fs_cancel_valid(S_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_I_fs_cancel_ready),
        .O_fs_cancel_context(S_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(S_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(S_I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(S_I_fs_cancel_done_generation),
        .O_fs_close_valid(S_O_fs_close_valid),
        .I_fs_close_ready(S_I_fs_close_ready),
        .O_fs_close_context(S_O_fs_close_context)
    );
    always #4 S_I_clk=~S_I_clk;

    reg S_test_pass=0,S_check_pixels=1,S_top_down=0;
    reg [7:0] S_bmp[0:699];
    integer S_i,S_j,S_case=0,S_pixels=0,S_headers=0,S_reads=0,S_closes=0;
    integer S_bpp=24;
    reg [31:0] S_expected_rgba;
    reg S_pixel_held=0;
    reg [64:0] S_held_pixel;
    task fail;
        input [767:0] message;
        begin $display("FAIL: bmp_file CASE %0d: %0s",S_case,message); $stop; end
    endtask
    task bmp32;
        input integer address;
        input [31:0] value;
        begin
            S_bmp[address]=value; S_bmp[address+1]=value>>8;
            S_bmp[address+2]=value>>16; S_bmp[address+3]=value>>24;
        end
    endtask
    task make_bmp;
        input integer bpp;
        input top_down;
        begin
            S_bpp=bpp; S_top_down=top_down;
            for(S_i=0;S_i<700;S_i=S_i+1) S_bmp[S_i]=0;
            S_bmp[0]="B"; S_bmp[1]="M";
            bmp32(2,700); bmp32(10,510); bmp32(14,40); bmp32(18,3);
            bmp32(22,top_down ? 32'hfffffffe : 32'd2);
            S_bmp[26]=1; S_bmp[28]=bpp; bmp32(34,24);
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                S_j=510+(S_i/3)*12+(S_i%3)*(bpp/8);
                S_bmp[S_j]=8'h30+S_i; S_bmp[S_j+1]=8'h20+S_i; S_bmp[S_j+2]=8'h10+S_i;
                if(bpp==32) S_bmp[S_j+3]=S_i;
            end
            if(bpp==24) begin
                S_bmp[519]=8'hee; S_bmp[520]=8'hee; S_bmp[521]=8'hee;
                S_bmp[531]=8'hee; S_bmp[532]=8'hee; S_bmp[533]=8'hee;
            end
            for(S_i=534;S_i<700;S_i=S_i+1) S_bmp[S_i]=8'ha5;
        end
    endtask
    always @(posedge S_I_clk) begin
        if(S_I_reset) S_pixel_held<=0;
        else begin
            if(S_O_fs_read_valid && S_I_fs_read_ready) begin
                S_reads=S_reads+1;
                if(S_O_fs_offset!==0 || S_O_fs_length!==S_O_file_size ||
                    S_O_fs_epoch!==S_O_tag || S_O_fs_read_context!==S_O_context || S_O_fs_read_priority!==0)
                    fail("read identity/offset/length/priority");
            end
            if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
            if(S_check_pixels) begin
                if(S_O_header_valid && S_I_header_ready) begin
                    S_headers=S_headers+1;
                    if(S_O_width!==3 || S_O_height!==2 || S_O_bpp!==S_bpp ||
                        S_O_bottom_up!==!S_top_down || S_O_pixel_offset!==510 || S_O_row_bytes!==12)
                        fail("header metadata");
                end
                if(S_pixel_held && (!S_O_pixel_valid ||
                    {S_O_rgba,S_O_x,S_O_y,S_O_pixel_last}!==S_held_pixel)) fail("pixel changed under backpressure");
                S_pixel_held<=S_O_pixel_valid && !S_I_pixel_ready;
                S_held_pixel<={S_O_rgba,S_O_x,S_O_y,S_O_pixel_last};
                if(S_O_pixel_valid && S_I_pixel_ready) begin
                    S_expected_rgba={8'h10+S_pixels[7:0],8'h20+S_pixels[7:0],8'h30+S_pixels[7:0],8'hff};
                    if(S_pixels>=6 || S_O_rgba!==S_expected_rgba || S_O_x!==S_pixels%3 ||
                        S_O_y!==(S_top_down ? S_pixels/3 : 1-S_pixels/3) || S_O_pixel_last!==(S_pixels==5))
                        fail("RGBA/normalized coordinate/pixel_last");
                    S_pixels=S_pixels+1;
                end
            end else S_pixel_held<=0;
        end
    end
    task start_source;
        input [1:0] context;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_context=context; S_I_tag=tag;
            S_I_generation=S_I_media_generation; S_I_sector_budget=8; S_I_path_length=9;
            S_I_start_valid=1; S_pixels=0; S_headers=0;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task send_path;
        reg [71:0] path;
        integer k;
        begin
            path="/TEST.BMP";
            for(k=0;k<9;k=k+1) begin
                @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=path[(8-k)*8+:8]; S_I_path_last=k==8;
                @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
            end
            @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_I_abort=1; @(negedge S_I_clk); S_I_abort=0; end
    endtask
    task take_result;
        input [3:0] error;
        reg [105:0] terminal;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || !S_O_lease_active || S_O_start_ready) fail("terminal/lease");
            terminal={S_O_error,S_O_parser_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_parser_started};
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_done_valid || {S_O_error,S_O_parser_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                    S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_parser_started}!==terminal)
                    fail("terminal backpressure");
            end
            S_I_done_ready=1;
            @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_busy) fail("lease release after done acceptance");
        end
    endtask
    initial begin #20000000; fail("watchdog"); end

    task open_result;
        input [31:0] size;
        input [7:0] error;
        begin
            @(negedge S_I_clk);
            S_I_fs_open_context=S_O_context; S_I_fs_open_tag=S_O_tag;
            S_I_fs_open_generation=S_O_generation; S_I_fs_open_size=size;
            S_I_fs_open_error=error; S_I_fs_open_result_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_open_result_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_open_result_valid=0;
        end
    endtask
    task setup_file;
        input [31:0] size;
        begin start_source(1,16'hf123); send_path; open_result(size,0); end
    endtask
    task byte_in;
        input integer offset;
        input last;
        begin
            @(negedge S_I_clk); S_I_fs_byte_context=S_O_context; S_I_fs_byte_epoch=S_O_tag;
            S_I_fs_byte_generation=S_O_generation; S_I_fs_byte_offset=offset;
            S_I_fs_byte_data=S_bmp[offset]; S_I_fs_byte_last=last; S_I_fs_byte_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_byte_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_byte_valid=0;
        end
    endtask
    task read_done;
        input [31:0] count;
        input [7:0] error;
        input eof;
        begin
            @(negedge S_I_clk); S_I_fs_done_context=S_O_context; S_I_fs_done_epoch=S_O_tag;
            S_I_fs_done_generation=S_O_generation; S_I_fs_done_bytes=count;
            S_I_fs_done_error=error; S_I_fs_done_eof=eof; S_I_fs_done_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_done_valid=0;
        end
    endtask
    task cancel_ack;
        begin
            @(negedge S_I_clk); S_I_fs_cancel_done_context=S_O_context;
            S_I_fs_cancel_done_epoch=S_O_tag; S_I_fs_cancel_done_generation=S_O_generation;
            S_I_fs_cancel_done_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_cancel_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
        end
    endtask
    task finish_canceled;
        input [3:0] error;
        begin
            wait(S_O_fs_cancel_valid);
            @(negedge S_I_clk); S_I_fs_cancel_ready=1;
            @(negedge S_I_clk); S_I_fs_cancel_ready=0;
            read_done(u_source.S_received,8,0);
            repeat(8) begin @(negedge S_I_clk); if(S_O_fs_close_valid || S_O_done_valid) fail("cancel acceptance/done is not ack"); end
            // Stale cancel ack is consumed without releasing this transaction.
            S_I_fs_cancel_done_context=S_O_context; S_I_fs_cancel_done_epoch=S_O_tag+16'd1;
            S_I_fs_cancel_done_generation=S_O_generation; S_I_fs_cancel_done_valid=1;
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
            if(S_O_fs_close_valid) fail("stale cancel ack");
            cancel_ack; take_result(error);
        end
    endtask
    integer k,before_count;
    initial begin
        S_I_reset=1; S_I_media_valid=1; S_I_media_generation=7;
        S_I_fs_open_ready=1; S_I_fs_path_ready=1; S_I_fs_read_ready=1; S_I_fs_close_ready=1;
        S_I_header_ready=1; S_I_pixel_ready=1;
        repeat(4) @(negedge S_I_clk); S_I_reset=0;
        // Lease request must precede grant; start payload is snapshotted.
        make_bmp(24,0);
        fork
            begin start_source(0,16'hffff); end
            begin wait(S_O_lease_request); repeat(3) @(negedge S_I_clk);
                if(S_O_start_ready || S_O_fs_open_valid) fail("ungranted lease"); S_I_lease_grant=1; end
        join
        S_I_context=2; S_I_tag=5; S_I_generation=99; S_I_path_length=1; S_I_sector_budget=99;
        send_path;
        if(S_O_fs_open_context!==0 || S_O_fs_open_tag!==16'hffff || S_O_fs_path_length!==9 || S_O_fs_sector_budget!==8)
            fail("command snapshot");
        // Another context is never consumed; stale own identities are drained.
        S_I_fs_open_context=2; S_I_fs_open_result_valid=1;
        #1; if(S_O_fs_open_result_ready) fail("foreign context open");
        @(negedge S_I_clk); S_I_fs_open_context=0; S_I_fs_open_tag=16'hfffe; S_I_fs_open_generation=7;
        @(negedge S_I_clk); S_I_fs_open_result_valid=0;
        if(S_O_parser_started) fail("stale open started parser");
        open_result(700,0); wait(S_O_fs_byte_ready);
        S_I_fs_byte_context=2; S_I_fs_byte_valid=1; #1;
        if(S_O_fs_byte_ready) fail("foreign byte");
        @(negedge S_I_clk); S_I_fs_byte_context=0; S_I_fs_byte_epoch=16'hfffe; S_I_fs_byte_generation=7;
        @(negedge S_I_clk); S_I_fs_byte_valid=0;
        // Header and pixel stalls both propagate, then last byte and done handshake together.
        S_I_header_ready=0;
        for(k=0;k<54;k=k+1) byte_in(k,0);
        // Ready for a malformed/stale byte is deliberately high to drain it.
        // Probe backpressure with the next in-order byte's address instead.
        S_I_fs_byte_offset=54;
        wait(S_O_header_valid); repeat(5) begin @(negedge S_I_clk); if(!S_O_header_valid || S_O_fs_byte_ready) fail("header stall"); end
        S_I_header_ready=1;
        for(k=54;k<513;k=k+1) byte_in(k,0);
        S_I_fs_byte_offset=513;
        S_I_pixel_ready=0; wait(S_O_pixel_valid);
        repeat(5) @(negedge S_I_clk); S_I_pixel_ready=1;
        for(k=513;k<699;k=k+1) byte_in(k,0);
        @(negedge S_I_clk); S_I_fs_done_valid=1; S_I_fs_done_context=0;
        S_I_fs_done_epoch=16'hffff; S_I_fs_done_generation=7; S_I_fs_done_bytes=700;
        S_I_fs_done_eof=1; S_I_fs_done_error=0;
        S_I_fs_byte_valid=1; S_I_fs_byte_context=0; S_I_fs_byte_epoch=16'hffff;
        S_I_fs_byte_generation=7; S_I_fs_byte_offset=699; S_I_fs_byte_data=S_bmp[699]; S_I_fs_byte_last=1;
        @(posedge S_I_clk); if(!S_O_fs_done_ready || !S_O_fs_byte_ready) fail("last/done concurrent");
        @(negedge S_I_clk); S_I_fs_done_valid=0; S_I_fs_byte_valid=0;
        take_result(0); if(S_pixels!==6 || S_headers!==1) fail("24bit complete pixels");

        make_bmp(32,1); setup_file(700);
        for(k=0;k<700;k=k+1) byte_in(k,k==699);
        repeat(8) begin @(negedge S_I_clk); if(S_O_done_valid || S_O_fs_close_valid) fail("parser success before file done"); end
        read_done(700,0,1); take_result(0);
        if(S_pixels!==6 || S_headers!==1) fail("32bit complete pixels");

        S_check_pixels=0; before_count=S_reads;
        setup_file(10); wait(S_O_fs_cancel_valid); finish_canceled(5);
        if(S_O_parser_error!==4 || S_reads!==before_count+1) fail("short file parser/root error");
        make_bmp(24,0); S_bmp[0]="X"; setup_file(700);
        for(k=0;k<4;k=k+1) byte_in(k,0);
        finish_canceled(5); if(S_O_parser_error!==1) fail("bad signature diagnostic");

        make_bmp(24,0); setup_file(700); byte_in(1,0); finish_canceled(4);
        setup_file(700); byte_in(0,1); finish_canceled(4);
        setup_file(700); byte_in(0,0); read_done(1,0,0); take_result(4);
        setup_file(700); read_done(0,9,0); take_result(1);
        if(S_O_file_error!==9 || S_O_parser_error!==5) fail("transport diagnostic");

        setup_file(700); byte_in(0,0); pulse_abort; finish_canceled(2);
        setup_file(700); byte_in(0,0);
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        finish_canceled(3);
        // Abort before read acceptance: end parser, close without a made-up read.done.
        S_I_fs_read_ready=0; setup_file(700); wait(S_O_parser_started); pulse_abort;
        before_count=S_reads; take_result(2); if(S_reads!==before_count) fail("read started after abort");
        S_I_fs_read_ready=1;
        // Open cancellation must still consume a late successful open and close it.
        start_source(2,16'h20); wait(S_O_fs_path_valid===0 && u_source.S_state==2);
        pulse_abort; wait(S_O_fs_open_cancel); before_count=S_closes;
        open_result(700,0); take_result(2); if(S_closes!==before_count+1) fail("late open close");
        start_source(0,16'h21); send_path; before_count=S_closes;
        open_result(0,14); take_result(1); if(S_O_parser_started || S_closes!==before_count) fail("missing file no close/parser");
        // Bad path last is a protocol fault; wait for real failed open retirement.
        start_source(0,16'h22); @(negedge S_I_clk);
        S_I_path_valid=1; S_I_path_data="/"; S_I_path_last=1;
        @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_path_valid=0; wait(S_O_fs_open_cancel);
        open_result(0,8); take_result(4);
        // Short-file parser may finish without any accepted read command.
        S_I_fs_read_ready=0; before_count=S_reads; setup_file(10); take_result(5);
        if(S_reads!==before_count || S_O_parser_error!==4) fail("short file without read acceptance");
        S_I_fs_read_ready=1;
        // done before cancel acceptance removes an unaccepted cancel obligation.
        setup_file(700); wait(S_O_fs_byte_ready); pulse_abort;
        wait(S_O_fs_cancel_valid); read_done(0,8,0); take_result(2);
        // Accepting done and cancel together still owes the actual cancel_done.
        setup_file(700); wait(u_source.S_state==6); pulse_abort; wait(S_O_fs_cancel_valid);
        @(negedge S_I_clk); S_I_fs_cancel_ready=1;
        S_I_fs_done_valid=1; S_I_fs_done_context=S_O_context; S_I_fs_done_epoch=S_O_tag;
        S_I_fs_done_generation=S_O_generation; S_I_fs_done_bytes=0; S_I_fs_done_error=8; S_I_fs_done_eof=0;
        @(posedge S_I_clk); if(!S_O_fs_cancel_valid || !S_O_fs_done_ready) fail("concurrent cancel/done handshake");
        @(negedge S_I_clk); S_I_fs_cancel_ready=0; S_I_fs_done_valid=0;
        repeat(6) begin @(negedge S_I_clk); if(S_O_fs_close_valid || S_O_done_valid) fail("concurrent cancel owes ack"); end
        cancel_ack; take_result(2);
        // Stale done/generation and another context's done cannot retire this read.
        setup_file(700);
        @(negedge S_I_clk); S_I_fs_done_valid=1; S_I_fs_done_context=2;
        #1; if(S_O_fs_done_ready) fail("foreign done ready");
        @(negedge S_I_clk); S_I_fs_done_context=S_O_context; S_I_fs_done_epoch=S_O_tag;
        S_I_fs_done_generation=S_O_generation-1;
        @(negedge S_I_clk); S_I_fs_done_valid=0;
        if(S_O_done_valid || S_O_fs_close_valid) fail("stale generation done");
        S_I_fs_close_ready=0; read_done(0,9,0); wait(S_O_fs_close_valid);
        repeat(6) begin @(negedge S_I_clk); if(!S_O_fs_close_valid || S_O_done_valid) fail("close backpressure"); end
        S_I_fs_close_ready=1; take_result(1);
        // All 64 path bytes forward without wrapping the path counter.
        @(negedge S_I_clk); S_I_start_valid=1; S_I_path_length=64; S_I_context=0;
        S_I_tag=16'h30; S_I_generation=7; S_I_sector_budget=8;
        @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_start_valid=0;
        for(k=0;k<64;k=k+1) begin
            @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=k==0 ? "/" : "a"; S_I_path_last=k==63;
            @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
            if(S_O_fs_path_last!==(k==63) || S_O_fs_path_length!==64) fail("64-byte path forwarding");
        end
        @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        open_result(0,14); take_result(1);
        // Invalid length/budget starts no filesystem command.
        @(negedge S_I_clk); S_I_start_valid=1; S_I_path_length=65; S_I_context=0;
        S_I_generation=7; S_I_sector_budget=8;
        @(negedge S_I_clk); S_I_start_valid=0; take_result(4);
        // Published results freeze even if medium disappears.
        setup_file(700); read_done(0,9,0); wait(S_O_done_valid);
        @(negedge S_I_clk); S_I_media_valid=0; S_I_abort=1;
        take_result(1); S_I_media_valid=1; S_I_abort=0;
        // Global reset is coordinated with all endpoints by the real owner.
        setup_file(700); @(negedge S_I_clk); S_I_reset=1;
        repeat(3) @(negedge S_I_clk); S_I_reset=0;
        if(S_O_busy || S_O_done_valid) fail("global reset");
        S_test_pass=1; $display("PASS: bmp_file_source protocol and real parser"); $finish;
    end
endmodule
