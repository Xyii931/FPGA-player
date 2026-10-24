`timescale 1ns/1ps
module tb_bmp_frame_load_ctrl;
    reg S_I_clk=0;
    reg S_I_reset=0;
    reg S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg S_I_start_valid=0;
    wire S_O_start_ready;
    wire S_O_lease_request;
    wire S_O_lease_active;
    reg S_I_lease_grant=0;
    reg S_I_config_valid=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_asset=0;
    reg [2:0] S_I_slot=0;
    reg [2:0] S_I_layout=0;
    reg [1:0] S_I_rotation=0;
    reg S_I_abort=0;
    wire S_O_file_start_valid;
    reg S_I_file_start_ready=0;
    reg S_I_file_header_valid=0;
    wire S_O_file_header_ready;
    wire S_O_transform_start_valid;
    reg S_I_transform_start_ready=0;
    reg S_I_geometry_valid=0;
    wire S_O_geometry_ready;
    wire S_O_writer_start_valid;
    reg S_I_writer_start_ready=0;
    wire S_O_writer_lease_grant;
    wire S_O_file_abort;
    wire S_O_transform_abort;
    wire S_O_writer_abort;
    reg S_I_writer_cancel_source=0;
    reg S_I_file_done_valid=0;
    wire S_O_file_done_ready;
    reg [1:0] S_I_file_context=0;
    reg [15:0] S_I_file_tag=0;
    reg [31:0] S_I_file_generation=0;
    reg [31:0] S_I_file_size=0;
    reg [3:0] S_I_file_error=0;
    reg [3:0] S_I_parser_error=0;
    reg [3:0] S_I_storage_error=0;
    reg [7:0] S_I_fs_error=0;
    reg [2:0] S_I_path_warning=0;
    reg S_I_transform_done_valid=0;
    wire S_O_transform_done_ready;
    reg [15:0] S_I_transform_tag=0;
    reg [31:0] S_I_transform_generation=0;
    reg [3:0] S_I_transform_error=0;
    reg S_I_writer_done_valid=0;
    wire S_O_writer_done_ready;
    reg [15:0] S_I_writer_tag=0;
    reg [2:0] S_I_writer_slot=0;
    reg [31:0] S_I_writer_generation=0;
    reg [31:0] S_I_writer_token=0;
    reg [3:0] S_I_writer_error=0;
    reg [3:0] S_I_memory_error=0;
    reg [31:0] S_I_accepted_writes=0;
    reg [31:0] S_I_retired_writes=0;
    reg [31:0] S_I_pixels=0;
    wire S_O_source_valid;
    reg S_I_source_ready=0;
    wire [3:0] S_O_source_error;
    wire S_O_slot_cmd_valid;
    reg S_I_slot_cmd_ready=0;
    wire [2:0] S_O_slot_cmd_op;
    wire [2:0] S_O_slot_cmd_slot;
    wire [1:0] S_O_slot_cmd_owner;
    wire [31:0] S_O_slot_cmd_token;
    wire [31:0] S_O_slot_cmd_generation;
    wire [31:0] S_O_slot_cmd_asset;
    wire [2:0] S_O_slot_cmd_layout;
    wire [1:0] S_O_slot_cmd_rotation;
    wire S_O_slot_cmd_resident;
    wire S_O_slot_cmd_success;
    wire S_O_producer_retired;
    wire S_O_memory_retired;
    reg S_I_slot_result_valid=0;
    wire S_O_slot_result_ready;
    reg [3:0] S_I_slot_result_error=0;
    reg [2:0] S_I_slot_result_op=0;
    reg [2:0] S_I_slot_result_slot=0;
    reg [1:0] S_I_slot_result_owner=0;
    reg [31:0] S_I_slot_result_token=0;
    reg [31:0] S_I_slot_result_generation=0;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_lease_token;
    wire [2:0] S_O_slot;
    wire S_O_published;
    wire S_O_slot_owned;
    wire S_O_file_started;
    wire S_O_transform_started;
    wire S_O_writer_started;
    wire [3:0] S_O_file_source_error;
    wire [3:0] S_O_parser_error;
    wire [3:0] S_O_storage_error;
    wire [3:0] S_O_transform_error;
    wire [3:0] S_O_writer_error;
    wire [3:0] S_O_memory_error;
    wire [7:0] S_O_file_error;
    wire [2:0] S_O_path_warning;
    wire [31:0] S_O_file_size;
    wire [31:0] S_O_accepted_writes;
    wire [31:0] S_O_retired_writes;
    wire [31:0] S_O_pixels;
    wire S_O_response_discarded;
    bmp_frame_load_ctrl u_dut (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .O_lease_active(S_O_lease_active),
        .I_lease_grant(S_I_lease_grant),
        .I_config_valid(S_I_config_valid),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_asset(S_I_asset),
        .I_slot(S_I_slot),
        .I_layout(S_I_layout),
        .I_rotation(S_I_rotation),
        .I_abort(S_I_abort),
        .O_file_start_valid(S_O_file_start_valid),
        .I_file_start_ready(S_I_file_start_ready),
        .I_file_header_valid(S_I_file_header_valid),
        .O_file_header_ready(S_O_file_header_ready),
        .O_transform_start_valid(S_O_transform_start_valid),
        .I_transform_start_ready(S_I_transform_start_ready),
        .I_geometry_valid(S_I_geometry_valid),
        .O_geometry_ready(S_O_geometry_ready),
        .O_writer_start_valid(S_O_writer_start_valid),
        .I_writer_start_ready(S_I_writer_start_ready),
        .O_writer_lease_grant(S_O_writer_lease_grant),
        .O_file_abort(S_O_file_abort),
        .O_transform_abort(S_O_transform_abort),
        .O_writer_abort(S_O_writer_abort),
        .I_writer_cancel_source(S_I_writer_cancel_source),
        .I_file_done_valid(S_I_file_done_valid),
        .O_file_done_ready(S_O_file_done_ready),
        .I_file_context(S_I_file_context),
        .I_file_tag(S_I_file_tag),
        .I_file_generation(S_I_file_generation),
        .I_file_size(S_I_file_size),
        .I_file_error(S_I_file_error),
        .I_parser_error(S_I_parser_error),
        .I_storage_error(S_I_storage_error),
        .I_fs_error(S_I_fs_error),
        .I_path_warning(S_I_path_warning),
        .I_transform_done_valid(S_I_transform_done_valid),
        .O_transform_done_ready(S_O_transform_done_ready),
        .I_transform_tag(S_I_transform_tag),
        .I_transform_generation(S_I_transform_generation),
        .I_transform_error(S_I_transform_error),
        .I_writer_done_valid(S_I_writer_done_valid),
        .O_writer_done_ready(S_O_writer_done_ready),
        .I_writer_tag(S_I_writer_tag),
        .I_writer_slot(S_I_writer_slot),
        .I_writer_generation(S_I_writer_generation),
        .I_writer_token(S_I_writer_token),
        .I_writer_error(S_I_writer_error),
        .I_memory_error(S_I_memory_error),
        .I_accepted_writes(S_I_accepted_writes),
        .I_retired_writes(S_I_retired_writes),
        .I_pixels(S_I_pixels),
        .O_source_valid(S_O_source_valid),
        .I_source_ready(S_I_source_ready),
        .O_source_error(S_O_source_error),
        .O_slot_cmd_valid(S_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_I_slot_cmd_ready),
        .O_slot_cmd_op(S_O_slot_cmd_op),
        .O_slot_cmd_slot(S_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_O_slot_cmd_owner),
        .O_slot_cmd_token(S_O_slot_cmd_token),
        .O_slot_cmd_generation(S_O_slot_cmd_generation),
        .O_slot_cmd_asset(S_O_slot_cmd_asset),
        .O_slot_cmd_layout(S_O_slot_cmd_layout),
        .O_slot_cmd_rotation(S_O_slot_cmd_rotation),
        .O_slot_cmd_resident(S_O_slot_cmd_resident),
        .O_slot_cmd_success(S_O_slot_cmd_success),
        .O_producer_retired(S_O_producer_retired),
        .O_memory_retired(S_O_memory_retired),
        .I_slot_result_valid(S_I_slot_result_valid),
        .O_slot_result_ready(S_O_slot_result_ready),
        .I_slot_result_error(S_I_slot_result_error),
        .I_slot_result_op(S_I_slot_result_op),
        .I_slot_result_slot(S_I_slot_result_slot),
        .I_slot_result_owner(S_I_slot_result_owner),
        .I_slot_result_token(S_I_slot_result_token),
        .I_slot_result_generation(S_I_slot_result_generation),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_lease_token(S_O_lease_token),
        .O_slot(S_O_slot),
        .O_published(S_O_published),
        .O_slot_owned(S_O_slot_owned),
        .O_file_started(S_O_file_started),
        .O_transform_started(S_O_transform_started),
        .O_writer_started(S_O_writer_started),
        .O_file_source_error(S_O_file_source_error),
        .O_parser_error(S_O_parser_error),
        .O_storage_error(S_O_storage_error),
        .O_transform_error(S_O_transform_error),
        .O_writer_error(S_O_writer_error),
        .O_memory_error(S_O_memory_error),
        .O_file_error(S_O_file_error),
        .O_path_warning(S_O_path_warning),
        .O_file_size(S_O_file_size),
        .O_accepted_writes(S_O_accepted_writes),
        .O_retired_writes(S_O_retired_writes),
        .O_pixels(S_O_pixels),
        .O_response_discarded(S_O_response_discarded),
        .I_more_parts(1'b0),
        .I_part_valid(1'b0),
        .O_part_needed(),
        .O_part_ready()
    );
    always #4 S_I_clk=~S_I_clk;
    reg S_test_pass=0;
    integer S_case=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #200000000; fail("watchdog timeout"); end

    task reset_all;
        begin
            @(negedge S_I_clk); S_I_reset=1; S_I_abort=0; S_I_start_valid=0;
            S_I_media_valid=1; S_I_media_generation=7; S_I_lease_grant=1; S_I_config_valid=1;
            S_I_context=1; S_I_tag=16'hfa35; S_I_generation=7; S_I_asset=23;
            S_I_slot=2; S_I_layout=0; S_I_rotation=1;
            S_I_file_start_ready=1; S_I_transform_start_ready=1; S_I_writer_start_ready=1;
            S_I_file_header_valid=0; S_I_geometry_valid=0; S_I_writer_cancel_source=0;
            S_I_file_done_valid=0; S_I_transform_done_valid=0; S_I_writer_done_valid=0;
            S_I_slot_cmd_ready=0; S_I_slot_result_valid=0; S_I_source_ready=0; S_I_done_ready=0;
            S_I_file_error=0; S_I_transform_error=0; S_I_writer_error=0;
            repeat(3) @(negedge S_I_clk); S_I_reset=0;
        end
    endtask
    task launch;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_start_valid=1;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task slot_command;
        input [2:0] op;
        input success;
        reg [110:0] saved;
        begin
            wait(S_O_slot_cmd_valid); #1;
            if(S_O_slot_cmd_op!==op || S_O_slot_cmd_slot!==2 || S_O_slot_cmd_owner!==1 ||
                S_O_slot_cmd_generation!==7 || S_O_slot_cmd_asset!==23 || S_O_slot_cmd_rotation!==1 ||
                S_O_slot_cmd_resident || S_O_slot_cmd_success!==success) fail("slot command snapshot");
            if(op==1 && (!S_O_producer_retired || !S_O_memory_retired)) fail("FINISH before actual retirement");
            saved={S_O_slot_cmd_op,S_O_slot_cmd_slot,S_O_slot_cmd_owner,S_O_slot_cmd_token,
                S_O_slot_cmd_generation,S_O_slot_cmd_asset,S_O_slot_cmd_layout,S_O_slot_cmd_rotation,
                S_O_slot_cmd_resident,S_O_slot_cmd_success};
            repeat(3) begin
                @(negedge S_I_clk);
                if(!S_O_slot_cmd_valid || saved!=={S_O_slot_cmd_op,S_O_slot_cmd_slot,S_O_slot_cmd_owner,
                    S_O_slot_cmd_token,S_O_slot_cmd_generation,S_O_slot_cmd_asset,S_O_slot_cmd_layout,
                    S_O_slot_cmd_rotation,S_O_slot_cmd_resident,S_O_slot_cmd_success}) fail("held slot command");
            end
            S_I_slot_cmd_ready=1; @(negedge S_I_clk); S_I_slot_cmd_ready=0;
        end
    endtask
    task slot_reply;
        input [2:0] op;
        input [3:0] error;
        input [31:0] token;
        begin
            @(negedge S_I_clk); S_I_slot_result_op=op; S_I_slot_result_slot=2;
            S_I_slot_result_owner=1; S_I_slot_result_generation=7; S_I_slot_result_token=token;
            S_I_slot_result_error=error; S_I_slot_result_valid=1;
            @(posedge S_I_clk); while(!S_O_slot_result_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_slot_result_valid=0;
        end
    endtask
    task allocate;
        begin
            slot_command(0,0);
            // A stale ALLOC response cannot grant a fresh lease.
            @(negedge S_I_clk); S_I_slot_result_op=0; S_I_slot_result_slot=2;
            S_I_slot_result_owner=1; S_I_slot_result_generation=8;
            S_I_slot_result_token=32'hd123; S_I_slot_result_error=0; S_I_slot_result_valid=1;
            @(negedge S_I_clk); S_I_slot_result_valid=0;
            if(!S_O_response_discarded || S_O_slot_owned || S_O_file_started) fail("stale slot response");
            slot_reply(0,0,32'hd123);
        end
    endtask
    task all_started;
        begin
            wait(S_O_file_started);
            @(negedge S_I_clk); S_I_file_header_valid=1;
            @(posedge S_I_clk); while(!S_O_file_header_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_file_header_valid=0; S_I_geometry_valid=1;
            @(posedge S_I_clk); while(!S_O_geometry_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_geometry_valid=0;
            if(!S_O_transform_started || !S_O_writer_started) fail("header/geometry start handshake");
        end
    endtask
    task file_done;
        input [3:0] error;
        begin
            @(negedge S_I_clk); S_I_file_done_valid=1; S_I_file_error=error;
            S_I_file_context=1; S_I_file_tag=16'hfa35; S_I_file_generation=7; S_I_file_size=700;
            S_I_parser_error=error==5 ? 4'd2 : 4'd0; S_I_fs_error=error==1 ? 8'd9 : 8'd0;
            @(posedge S_I_clk); if(!S_O_file_done_ready) fail("file terminal not accepted");
            @(negedge S_I_clk); S_I_file_done_valid=0;
        end
    endtask
    task transform_done;
        input [3:0] error;
        begin
            @(negedge S_I_clk); S_I_transform_done_valid=1; S_I_transform_error=error;
            S_I_transform_tag=16'hfa35; S_I_transform_generation=7;
            @(posedge S_I_clk); if(!S_O_transform_done_ready) fail("transform terminal not accepted");
            @(negedge S_I_clk); S_I_transform_done_valid=0;
        end
    endtask
    task source_union;
        input [3:0] error;
        begin
            wait(S_O_source_valid); #1;
            repeat(4) begin
                @(negedge S_I_clk);
                if(!S_O_source_valid || S_O_source_error!==error || S_O_done_valid || S_O_slot_cmd_valid)
                    fail("joint source result/retirement barrier");
            end
            S_I_source_ready=1; @(negedge S_I_clk); S_I_source_ready=0;
            if(S_O_source_valid) fail("joint source result repeated");
        end
    endtask
    task writer_done;
        input [3:0] error;
        begin
            @(negedge S_I_clk); S_I_writer_done_valid=1; S_I_writer_error=error;
            S_I_writer_tag=16'hfa35; S_I_writer_slot=2; S_I_writer_token=32'hd123; S_I_writer_generation=7;
            S_I_memory_error=error==3 ? 4'd9 : 4'd0;
            S_I_accepted_writes=307206; S_I_retired_writes=307206; S_I_pixels=6;
            @(posedge S_I_clk); if(!S_O_writer_done_ready) fail("writer terminal not accepted");
            @(negedge S_I_clk); S_I_writer_done_valid=0;
        end
    endtask
    task result;
        input [3:0] error;
        input published,owned;
        reg [182:0] saved;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_published!==published || S_O_slot_owned!==owned || !S_O_lease_active)
                fail("root result/lease");
            saved={S_O_error,S_O_context,S_O_tag,S_O_generation,S_O_slot,S_O_lease_token,
                S_O_published,S_O_slot_owned,S_O_file_source_error,S_O_transform_error,S_O_writer_error,
                S_O_file_error,S_O_parser_error,S_O_memory_error,S_O_file_size,S_O_pixels};
            S_I_abort=1; S_I_media_valid=0;
            repeat(4) begin
                @(negedge S_I_clk);
                if(!S_O_done_valid || saved!=={S_O_error,S_O_context,S_O_tag,S_O_generation,S_O_slot,
                    S_O_lease_token,S_O_published,S_O_slot_owned,S_O_file_source_error,S_O_transform_error,
                    S_O_writer_error,S_O_file_error,S_O_parser_error,S_O_memory_error,S_O_file_size,S_O_pixels})
                    fail("result freeze");
            end
            S_I_done_ready=1; @(negedge S_I_clk); S_I_done_ready=0; S_I_abort=0; S_I_media_valid=1;
            if(S_O_lease_active || (owned && S_O_start_ready)) fail("release/quarantine");
        end
    endtask
    task finish;
        input [3:0] error;
        begin slot_command(1,error==0); slot_reply(1,error==6 ? 4'd4 : error==0 ? 4'd0 : 4'd6,32'hd123);
            result(error,error==0,0); end
    endtask
    initial begin
        reset_all;
        // Grant request must not depend on the internal file source's readiness.
        S_I_lease_grant=0;
        fork
            launch;
            begin wait(S_O_lease_request); repeat(4) @(negedge S_I_clk);
                if(S_O_start_ready || S_O_slot_cmd_valid) fail("namespace lease gating"); S_I_lease_grant=1; end
        join
        allocate; all_started;
        @(negedge S_I_clk); S_I_transform_done_valid=1; S_I_transform_tag=16'hfa34;
        S_I_transform_generation=7; S_I_writer_done_valid=1; S_I_writer_tag=16'hfa35;
        S_I_writer_generation=7; S_I_writer_slot=2; S_I_writer_token=32'hd124;
        @(negedge S_I_clk); S_I_transform_done_valid=0; S_I_writer_done_valid=0;
        if(!S_O_response_discarded || S_O_memory_retired || S_O_source_valid) fail("stale transform/writer terminal");
        // Mutating command inputs cannot change an active job.
        S_I_tag=3; S_I_generation=99; S_I_context=2; S_I_asset=9; S_I_slot=4;
        transform_done(0);
        repeat(4) begin @(negedge S_I_clk); if(S_O_source_valid || S_O_slot_cmd_valid) fail("transform is not file retirement"); end
        // Wrong complete identities are consumed, without completing this job.
        S_I_file_context=1; S_I_file_tag=16'hfa34; S_I_file_generation=7; S_I_file_done_valid=1;
        @(negedge S_I_clk); S_I_file_done_valid=0;
        if(!S_O_response_discarded || S_O_source_valid) fail("stale file terminal");
        file_done(0); source_union(0); writer_done(0); finish(0);

        reset_all; launch; allocate; all_started;
        file_done(0);
        repeat(4) begin @(negedge S_I_clk); if(S_O_source_valid) fail("file is not transform retirement"); end
        transform_done(0); source_union(0); writer_done(0); finish(0);

        reset_all; launch; allocate; all_started;
        fork file_done(0); transform_done(0); join
        source_union(0); writer_done(0); finish(0);

        // Pixel transform already succeeded; late file failure must reject READY.
        reset_all; launch; allocate; all_started; transform_done(0); file_done(1);
        if(!S_O_writer_abort) fail("late file error did not cancel writer");
        source_union(1); writer_done(5); finish(3);
        if(S_O_file_error!==9) fail("raw file diagnostic");

        reset_all; launch; allocate; all_started;
        @(negedge S_I_clk); S_I_writer_cancel_source=1;
        #1; if(!S_O_file_abort || !S_O_transform_abort) fail("writer failure cancellation");
        repeat(4) begin @(negedge S_I_clk); if(S_O_done_valid || S_O_slot_cmd_valid) fail("cancel is not retirement"); end
        if(S_O_writer_abort) fail("writer root cause fed back as peer abort");
        file_done(2); transform_done(4); source_union(1); writer_done(3); S_I_writer_cancel_source=0; finish(5);
        if(S_O_memory_error!==9) fail("raw memory diagnostic");

        // Failure before header / between header and geometry: no invented writer duty.
        reset_all; launch; allocate; wait(S_O_file_started); file_done(5); finish(3);
        if(S_O_transform_started || S_O_writer_started) fail("unstarted children waited/started");
        reset_all; launch; allocate; wait(S_O_file_started);
        @(negedge S_I_clk); S_I_file_header_valid=1;
        @(negedge S_I_clk); S_I_file_header_valid=0; S_I_abort=1;
        file_done(2); transform_done(4); finish(7);
        if(S_O_writer_started) fail("geometry was never granted");

        // ALLOC remains stable after cancellation and must still retire its result.
        reset_all; S_I_file_start_ready=0; launch; wait(S_O_slot_cmd_valid);
        @(negedge S_I_clk); S_I_abort=1; allocate; finish(7);
        if(S_O_file_started) fail("canceled before file start");

        reset_all; launch; allocate; all_started;
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        file_done(3); transform_done(4); source_union(1); writer_done(6); finish(6);

        // FINISH payload is immutable after its decision; late abort is too late.
        reset_all; launch; allocate; all_started;
        file_done(0); transform_done(0); source_union(0); writer_done(0);
        wait(S_O_slot_cmd_valid); @(negedge S_I_clk); S_I_abort=1;
        slot_command(1,1); slot_reply(1,0,32'hd123); result(0,1,0);
        // Media invalidation after that decision is still reported and prevents publication.
        reset_all; launch; allocate; all_started;
        file_done(0); transform_done(0); source_union(0); writer_done(0);
        wait(S_O_slot_cmd_valid); @(negedge S_I_clk); S_I_media_valid=0;
        slot_command(1,1); slot_reply(1,4,32'hd123); result(6,0,0);

        reset_all; launch; slot_command(0,0); slot_reply(0,2,0); result(2,0,0);
        reset_all; S_I_config_valid=0; launch; result(1,0,0);
        if(S_O_file_started || S_O_slot_cmd_valid) fail("invalid config performed work");
        reset_all; S_I_slot=6; launch; result(1,0,0);
        reset_all; S_I_layout=5; launch; result(1,0,0);
        reset_all; S_I_media_valid=0; launch; result(6,0,0);
        reset_all; S_I_context=3; S_I_start_valid=1;
        repeat(4) begin @(negedge S_I_clk); if(S_O_start_ready || S_O_lease_request) fail("reserved context"); end

        // Bad FINISH response cannot be treated as proof that the slot is released.
        reset_all; launch; allocate; all_started;
        file_done(0); transform_done(0); source_union(0); writer_done(0);
        slot_command(1,1); slot_reply(1,3,32'hd123); result(8,0,1);
        S_I_start_valid=1; repeat(5) begin @(negedge S_I_clk);
            if(S_O_start_ready || S_O_lease_request || S_O_slot_cmd_valid) fail("unknown slot ownership reused"); end
        reset_all; launch; slot_command(0,0); slot_reply(0,0,0); result(8,0,1);
        reset_all;
        S_test_pass=1; $display("PASS: bmp_frame_load_ctrl protocol cases (no physical memory)"); $finish;
    end
endmodule
