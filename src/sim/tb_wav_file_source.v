`timescale 1ns/1ps
// Real WAV file owner; file and decoder control peers are explicit protocol stimulus.
module tb_wav_file_source;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    reg  S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg  S_I_start_valid=0;
    wire  S_O_start_ready;
    wire  S_O_lease_request;
    reg  S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [1:0] S_I_read_priority=0;
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
    wire [7:0] S_O_file_error;
    wire [3:0] S_O_storage_error;
    wire [2:0] S_O_path_warning;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_file_size;
    wire  S_O_track_started;
    wire  S_O_track_start_valid;
    reg  S_I_track_start_ready=0;
    wire [31:0] S_O_track_file_size;
    wire [15:0] S_O_track_epoch;
    wire  S_O_track_byte_valid;
    reg  S_I_track_byte_ready=0;
    wire [7:0] S_O_track_byte_data;
    wire  S_O_track_byte_last;
    wire [15:0] S_O_track_byte_epoch;
    wire  S_O_track_stream_error;
    wire [15:0] S_O_track_stream_error_epoch;
    reg  S_I_track_cancel_valid=0;
    wire  S_O_track_cancel_ready;
    reg [15:0] S_I_track_cancel_epoch=0;
    reg  S_I_io_retire_request=0;
    wire  S_O_io_retired;
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
    wav_file_source u_source (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_read_priority(S_I_read_priority),
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
        .O_file_error(S_O_file_error),
        .O_storage_error(S_O_storage_error),
        .O_path_warning(S_O_path_warning),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_file_size(S_O_file_size),
        .O_track_started(S_O_track_started),
        .O_track_start_valid(S_O_track_start_valid),
        .I_track_start_ready(S_I_track_start_ready),
        .O_track_file_size(S_O_track_file_size),
        .O_track_epoch(S_O_track_epoch),
        .O_track_byte_valid(S_O_track_byte_valid),
        .I_track_byte_ready(S_I_track_byte_ready),
        .O_track_byte_data(S_O_track_byte_data),
        .O_track_byte_last(S_O_track_byte_last),
        .O_track_byte_epoch(S_O_track_byte_epoch),
        .O_track_stream_error(S_O_track_stream_error),
        .O_track_stream_error_epoch(S_O_track_stream_error_epoch),
        .I_track_cancel_valid(S_I_track_cancel_valid),
        .O_track_cancel_ready(S_O_track_cancel_ready),
        .I_track_cancel_epoch(S_I_track_cancel_epoch),
        .I_io_retire_request(S_I_io_retire_request),
        .O_io_retired(S_O_io_retired),
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
        .O_fs_close_context(S_O_fs_close_context),
        .I_start_index(32'd0),
        .O_track_start_index()
    );
    always #4 S_I_clk=~S_I_clk;

    reg S_test_pass=0;
    integer S_case=0,S_bytes=0,S_reads=0,S_closes=0,S_track_starts=0;
    reg [1:0] S_expected_priority=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: WAV file case %0d: %0s",S_case,message); $stop; end
    endtask
    always @(posedge S_I_clk) begin
        if(!S_I_reset) begin
            if(S_O_fs_read_valid && S_I_fs_read_ready) begin
                S_reads=S_reads+1;
                if(S_O_fs_offset!==0 || S_O_fs_length!==S_O_file_size || S_O_fs_epoch!==S_O_tag ||
                    S_O_fs_read_context!==S_O_context || S_O_fs_read_priority!==S_expected_priority)
                    fail("read identity/length/priority");
            end
            if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
            if(S_O_track_start_valid && S_I_track_start_ready) begin
                S_track_starts=S_track_starts+1;
                if(S_O_track_epoch!==S_O_tag || S_O_track_file_size!==S_O_file_size) fail("track start identity");
            end
            if(S_O_track_byte_valid && S_I_track_byte_ready) begin
                if(S_O_track_byte_epoch!==S_O_tag || S_O_track_byte_last!==(S_bytes+1==S_O_file_size))
                    fail("track byte epoch/last");
                S_bytes=S_bytes+1;
            end
            if(S_O_io_retired && (S_O_fs_open_valid || S_O_fs_read_valid || S_O_fs_cancel_valid || S_O_fs_close_valid))
                fail("retired while file obligations offered");
        end
    end
    task start_source;
        input [1:0] context;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_context=context; S_I_tag=tag; S_I_generation=S_I_media_generation;
            S_I_path_length=9; S_I_sector_budget=8; S_I_read_priority=S_expected_priority;
            S_bytes=0; S_I_start_valid=1;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task send_path;
        reg [71:0] path;
        integer k;
        begin
            path="/TEST.WAV";
            for(k=0;k<9;k=k+1) begin
                @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=path[(8-k)*8+:8]; S_I_path_last=k==8;
                @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
                if(S_O_fs_path_data!==path[(8-k)*8+:8] || S_O_fs_path_last!==(k==8) || S_O_fs_path_length!==9)
                    fail("path forwarding/snapshot");
            end
            @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        end
    endtask
    task take_result;
        input [3:0] error;
        reg [101:0] terminal;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || !S_O_lease_active || S_O_start_ready) fail("file terminal/lease");
            terminal={S_O_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_track_started};
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_done_valid || {S_O_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                    S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_track_started}!==terminal)
                    fail("file terminal backpressure");
            end
            S_I_done_ready=1; @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_busy) fail("file lease did not release");
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_I_abort=1; @(negedge S_I_clk); S_I_abort=0; end
    endtask
    initial begin #20000000; fail("watchdog"); end

    task open_result;
        input [31:0] size;
        input [7:0] error;
        begin
            @(negedge S_I_clk); S_I_fs_open_result_valid=1;
            S_I_fs_open_context=S_O_context; S_I_fs_open_tag=S_O_tag;
            S_I_fs_open_generation=S_O_generation; S_I_fs_open_size=size; S_I_fs_open_error=error;
            @(posedge S_I_clk); while(!S_O_fs_open_result_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_open_result_valid=0;
        end
    endtask
    task setup_file;
        begin start_source(1,16'h8123); send_path; open_result(8,0); end
    endtask
    task byte_in;
        input integer offset;
        input last;
        begin
            @(negedge S_I_clk); S_I_fs_byte_valid=1;
            S_I_fs_byte_context=S_O_context; S_I_fs_byte_epoch=S_O_tag; S_I_fs_byte_generation=S_O_generation;
            S_I_fs_byte_offset=offset; S_I_fs_byte_data=8'h40+offset; S_I_fs_byte_last=last;
            @(posedge S_I_clk); while(!S_O_fs_byte_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_byte_valid=0;
        end
    endtask
    task read_done;
        input [31:0] count;
        input [7:0] error;
        input eof;
        begin
            @(negedge S_I_clk); S_I_fs_done_valid=1;
            S_I_fs_done_context=S_O_context; S_I_fs_done_epoch=S_O_tag; S_I_fs_done_generation=S_O_generation;
            S_I_fs_done_bytes=count; S_I_fs_done_error=error; S_I_fs_done_eof=eof;
            @(posedge S_I_clk); while(!S_O_fs_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_done_valid=0;
        end
    endtask
    task cancel_ack;
        begin
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=1; S_I_fs_cancel_done_context=S_O_context;
            S_I_fs_cancel_done_epoch=S_O_tag; S_I_fs_cancel_done_generation=S_O_generation;
            @(posedge S_I_clk); while(!S_O_fs_cancel_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
        end
    endtask
    task finish_cancel;
        input [3:0] error;
        begin
            wait(S_O_fs_cancel_valid);
            @(negedge S_I_clk); S_I_fs_cancel_ready=1;
            @(negedge S_I_clk); S_I_fs_cancel_ready=0;
            read_done(u_source.S_received,8,0);
            repeat(8) begin @(negedge S_I_clk); if(S_O_io_retired || S_O_fs_close_valid || S_O_done_valid) fail("cancel accepted is not retired"); end
            // Stale acknowledgement is drained, and must not satisfy the actual cancel.
            S_I_fs_cancel_done_valid=1; S_I_fs_cancel_done_context=S_O_context;
            S_I_fs_cancel_done_epoch=S_O_tag+16'd1; S_I_fs_cancel_done_generation=S_O_generation;
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
            if(S_O_fs_close_valid) fail("stale cancel ack");
            cancel_ack; take_result(error);
        end
    endtask
    task track_cancel;
        input [15:0] epoch;
        begin
            @(negedge S_I_clk); S_I_track_cancel_epoch=epoch; S_I_track_cancel_valid=1;
            @(posedge S_I_clk); if(!S_O_track_cancel_ready) fail("matching late decoder cancel not accepted");
            @(negedge S_I_clk); S_I_track_cancel_valid=0;
        end
    endtask
    task release_retire;
        begin
            wait(S_O_io_retired);
            repeat(5) begin @(negedge S_I_clk); if(!S_O_io_retired || S_O_start_ready) fail("four-phase hold/new-start gate"); end
            S_I_io_retire_request=0;
            @(negedge S_I_clk); if(S_O_io_retired) fail("retired did not fall after request");
        end
    endtask
    integer k,before_count;
    always @(posedge S_I_clk) if(!S_I_reset && S_O_track_byte_valid && S_I_track_byte_ready)
        if(S_O_track_byte_data!==8'h40+S_I_fs_byte_offset[7:0]) fail("track payload");
    initial begin
        S_I_reset=1; S_I_media_valid=1; S_I_media_generation=7;
        S_I_fs_open_ready=1; S_I_fs_path_ready=1; S_I_fs_read_ready=1; S_I_fs_close_ready=1;
        S_I_track_start_ready=1; S_I_track_byte_ready=1;
        repeat(4) @(negedge S_I_clk); S_I_reset=0;
        // Empty owner also responds to retirement; grant is not required to request a lease.
        S_I_io_retire_request=1; release_retire;
        fork
            begin start_source(0,16'hffff); end
            begin wait(S_O_lease_request); repeat(3) @(negedge S_I_clk);
                if(S_O_start_ready || S_O_fs_open_valid) fail("ungranted lease"); S_I_lease_grant=1; end
        join
        S_I_context=2; S_I_tag=0; S_I_generation=99; S_I_sector_budget=99; S_I_read_priority=3;
        send_path; open_result(8,0);
        wait(u_source.S_state==6);
        if(S_O_context!==0 || S_O_tag!==16'hffff || S_O_generation!==7) fail("start snapshot");
        // Stale byte identities and foreign contexts are separated before the track.
        @(negedge S_I_clk); S_I_fs_byte_valid=1; S_I_fs_byte_context=2;
        #1; if(S_O_fs_byte_ready || S_O_track_byte_valid) fail("foreign byte ready");
        @(negedge S_I_clk); S_I_fs_byte_context=0; S_I_fs_byte_epoch=16'hfffe; S_I_fs_byte_generation=7;
        @(negedge S_I_clk); S_I_fs_byte_valid=0;
        if(S_bytes) fail("stale byte forwarded");
        S_I_track_byte_ready=0;
        @(negedge S_I_clk); S_I_fs_byte_valid=1; S_I_fs_byte_context=0; S_I_fs_byte_epoch=16'hffff;
        S_I_fs_byte_generation=7; S_I_fs_byte_offset=0; S_I_fs_byte_data=8'h40; S_I_fs_byte_last=0;
        repeat(5) begin @(negedge S_I_clk); if(S_O_fs_byte_ready || !S_O_track_byte_valid || S_O_track_byte_data!==8'h40) fail("track byte backpressure"); end
        S_I_track_byte_ready=1;
        @(negedge S_I_clk); S_I_fs_byte_valid=0;
        for(k=1;k<7;k=k+1) byte_in(k,0);
        // Last byte and file terminal count on the same edge.
        @(negedge S_I_clk); S_I_fs_byte_valid=1; S_I_fs_byte_offset=7; S_I_fs_byte_data=8'h47; S_I_fs_byte_last=1;
        S_I_fs_done_valid=1; S_I_fs_done_context=0; S_I_fs_done_epoch=16'hffff;
        S_I_fs_done_generation=7; S_I_fs_done_bytes=8; S_I_fs_done_error=0; S_I_fs_done_eof=1;
        @(posedge S_I_clk); if(!S_O_fs_done_ready || !S_O_fs_byte_ready) fail("last/done parallel");
        @(negedge S_I_clk); S_I_fs_byte_valid=0; S_I_fs_done_valid=0;
        wait(S_O_done_valid); track_cancel(16'hffff);
        if(S_O_error!==0) fail("late decoder cancel rewrote published file result");
        S_I_track_start_ready=0; take_result(0);
        track_cancel(16'hffff); // File done already consumed: decoder can still become quiescent.
        if(S_O_start_ready) fail("slot not ready but bridge accepts new identity");
        @(negedge S_I_clk); S_I_io_retire_request=1; release_retire; S_I_track_start_ready=1;

        setup_file; byte_in(0,0); track_cancel(16'h8123); finish_cancel(5);
        if(!S_O_track_stream_error || S_O_track_stream_error_epoch!==16'h8123) fail("decode cancellation/error identity");
        setup_file; byte_in(1,0); if(S_bytes) fail("bad offset reached decoder"); finish_cancel(4);
        setup_file; byte_in(0,1); if(S_bytes) fail("early last reached decoder"); finish_cancel(4);
        setup_file; read_done(0,9,0); take_result(1);
        if(S_O_file_error!==9 || !S_O_track_stream_error) fail("transport diagnostic");
        setup_file; byte_in(0,0); read_done(1,0,0); take_result(4);
        // All bytes alone do not retire the file.
        setup_file; for(k=0;k<8;k=k+1) byte_in(k,k==7);
        repeat(5) begin @(negedge S_I_clk); if(S_O_done_valid || S_O_fs_close_valid) fail("bytes alone are not done"); end
        read_done(8,0,1); take_result(0);
        setup_file; wait(u_source.S_state==6);
        @(negedge S_I_clk); S_I_track_cancel_valid=1; S_I_track_cancel_epoch=16'h0023;
        #1; if(S_O_track_cancel_ready) fail("low8-only decoder epoch comparison");
        @(negedge S_I_clk); S_I_track_cancel_valid=0;
        pulse_abort; finish_cancel(2);
        setup_file; wait(u_source.S_state==6);
        @(negedge S_I_clk); S_I_io_retire_request=1;
        finish_cancel(2); release_retire;
        // Close acknowledgement remains mandatory even after actual read retirement.
        S_I_fs_close_ready=0; setup_file; read_done(0,9,0); wait(S_O_fs_close_valid);
        @(negedge S_I_clk); S_I_io_retire_request=1;
        repeat(5) begin @(negedge S_I_clk); if(S_O_io_retired || S_O_done_valid) fail("close stalled but retired"); end
        S_I_fs_close_ready=1; take_result(2); release_retire;
        // Short loss pulse and generation change are sticky, despite immediate recovery.
        setup_file; wait(u_source.S_state==6);
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        finish_cancel(3);
        setup_file; wait(u_source.S_state==6);
        @(negedge S_I_clk); S_I_media_generation=8;
        finish_cancel(3); S_I_media_generation=7;
        // done before an unaccepted cancel creates no fake acknowledgement obligation.
        setup_file; wait(u_source.S_state==6); pulse_abort; read_done(0,8,0); take_result(2);
        // Same-edge cancel and done still require a real cancel_done.
        setup_file; wait(u_source.S_state==6); pulse_abort; wait(S_O_fs_cancel_valid);
        @(negedge S_I_clk); S_I_fs_cancel_ready=1; S_I_fs_done_valid=1;
        S_I_fs_done_context=S_O_context; S_I_fs_done_epoch=S_O_tag; S_I_fs_done_generation=S_O_generation;
        S_I_fs_done_bytes=0; S_I_fs_done_error=8; S_I_fs_done_eof=0;
        @(posedge S_I_clk); if(!S_O_fs_cancel_valid || !S_O_fs_done_ready) fail("parallel done/cancel");
        @(negedge S_I_clk); S_I_fs_cancel_ready=0; S_I_fs_done_valid=0;
        repeat(6) begin @(negedge S_I_clk); if(S_O_fs_close_valid || S_O_done_valid) fail("parallel cancel owes ack"); end
        cancel_ack; take_result(2);
        S_I_fs_read_ready=0; setup_file; wait(S_O_track_started); before_count=S_reads;
        pulse_abort; take_result(2); if(S_reads!==before_count) fail("abort before read acceptance"); S_I_fs_read_ready=1;
        start_source(2,16'h22); wait(u_source.S_state==2); pulse_abort; wait(S_O_fs_open_cancel);
        before_count=S_closes; open_result(8,0); take_result(2);
        if(S_closes!==before_count+1 || S_O_track_started) fail("late successful open not closed");
        start_source(2,16'h23); send_path; before_count=S_closes; open_result(0,14); take_result(1);
        if(S_closes!==before_count || S_O_track_started) fail("missing file started track/closed nonexistent fd");
        // Decoder start may be backpressured after open, with no read submitted yet.
        start_source(1,16'h24); send_path; S_I_track_start_ready=0; open_result(8,0);
        wait(S_O_track_start_valid); before_count=S_reads;
        repeat(5) begin @(negedge S_I_clk); if(!S_O_track_start_valid || S_O_track_started || S_O_fs_read_valid) fail("track start backpressure"); end
        pulse_abort; take_result(2); if(S_reads!==before_count) fail("unstarted track issued read");
        S_I_track_start_ready=1;
        // Open returns are isolated by context and full tag/generation.
        start_source(0,16'h25); send_path;
        @(negedge S_I_clk); S_I_fs_open_result_valid=1; S_I_fs_open_context=2;
        #1; if(S_O_fs_open_result_ready) fail("foreign open ready");
        @(negedge S_I_clk); S_I_fs_open_context=0; S_I_fs_open_tag=16'h0125; S_I_fs_open_generation=7;
        @(negedge S_I_clk); S_I_fs_open_tag=16'h25; S_I_fs_open_generation=6;
        @(negedge S_I_clk); S_I_fs_open_result_valid=0;
        if(S_O_track_started) fail("stale open started track");
        open_result(0,14); take_result(1);
        setup_file; wait(u_source.S_state==6);
        @(negedge S_I_clk); S_I_fs_done_valid=1; S_I_fs_done_context=2;
        #1; if(S_O_fs_done_ready) fail("foreign done ready");
        @(negedge S_I_clk); S_I_fs_done_context=1; S_I_fs_done_epoch=S_O_tag; S_I_fs_done_generation=6;
        @(negedge S_I_clk); S_I_fs_done_valid=0;
        if(S_O_done_valid || S_O_fs_close_valid) fail("stale generation retired read");
        pulse_abort; finish_cancel(2);
        // Invalid path last is canceled and retains protocol root cause on error8.
        start_source(0,16'h26);
        @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data="/"; S_I_path_last=1;
        @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        wait(S_O_fs_open_cancel); open_result(0,8); take_result(4);
        // Boundary paths forward all 64 bytes without wrapping the counter.
        @(negedge S_I_clk); S_I_start_valid=1; S_I_path_length=64; S_I_context=0;
        S_I_tag=16'h27; S_I_generation=7; S_I_sector_budget=8;
        @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_start_valid=0;
        for(k=0;k<64;k=k+1) begin
            @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=k==0 ? "/" : "a"; S_I_path_last=k==63;
            @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
            if(S_O_fs_path_last!==(k==63) || S_O_fs_path_length!==64) fail("64-byte path boundary");
        end
        @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        open_result(0,14); take_result(1);
        @(negedge S_I_clk); S_I_start_valid=1; S_I_path_length=65; S_I_context=0; S_I_generation=7;
        @(negedge S_I_clk); S_I_start_valid=0; take_result(4);
        setup_file; read_done(0,9,0); wait(S_O_done_valid);
        @(negedge S_I_clk); S_I_media_valid=0; S_I_abort=1;
        take_result(1); S_I_media_valid=1; S_I_abort=0;
        setup_file; @(negedge S_I_clk); S_I_reset=1;
        repeat(3) @(negedge S_I_clk); S_I_reset=0;
        if(S_O_busy || S_O_done_valid || S_O_io_retired) fail("coordinated global reset");
        S_test_pass=1; $display("PASS: wav_file_source protocol endpoints"); $finish;
    end
endmodule
