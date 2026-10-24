`timescale 1ns/1ps
// Controller protocol stimulus only; real I/O retirement is covered separately.
module tb_media_scan_ctrl;
    reg S_I_clk=0;
    reg S_I_reset=0;
    reg S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg S_I_start_valid=0;
    wire S_O_start_ready;
    wire S_O_lease_request;
    reg S_I_lease_grant=0;
    reg S_I_abort=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_seed=0;
    reg [31:0] S_I_sector_budget=0;
    reg [31:0] S_I_directory_sector_budget=0;
    reg [9:0] S_I_directory_duration=0;
    reg [9:0] S_I_directory_transition_ms=0;
    reg [2:0] S_I_directory_transition=0;
    reg [1:0] S_I_directory_order=0;
    wire S_O_lease_active;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [3:0] S_O_list_source_error;
    wire [3:0] S_O_list_build_error;
    wire [3:0] S_O_directory_build_error;
    wire [6:0] S_O_count;
    wire S_O_committed;
    wire S_O_used_directory;
    wire S_O_list_missing;
    wire S_O_list_started;
    wire S_O_directory_started;
    wire [7:0] S_O_list_warning;
    wire [7:0] S_O_directory_warning;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_seed;
    wire [31:0] S_O_sector_budget;
    wire [31:0] S_O_directory_sector_budget;
    wire [9:0] S_O_directory_duration;
    wire [9:0] S_O_directory_transition_ms;
    wire [2:0] S_O_directory_transition;
    wire [1:0] S_O_directory_order;
    wire S_O_list_start_valid;
    reg S_I_list_start_ready=0;
    wire S_O_child_abort;
    reg S_I_list_build_start=0;
    reg S_I_source_done_valid=0;
    wire S_O_source_done_ready;
    reg [3:0] S_I_source_error=0;
    reg S_I_source_builder_started=0;
    reg [15:0] S_I_source_tag=0;
    reg [31:0] S_I_source_generation=0;
    wire S_O_directory_mode;
    wire S_O_directory_start_valid;
    reg S_I_directory_start_ready=0;
    wire [15:0] S_O_directory_tag;
    reg S_I_build_committed=0;
    reg S_I_build_done_valid=0;
    wire S_O_build_done_ready;
    reg [3:0] S_I_build_error=0;
    reg [6:0] S_I_build_count=0;
    reg [7:0] S_I_build_warning=0;
    reg [15:0] S_I_build_tag=0;
    reg [31:0] S_I_build_generation=0;
    media_scan_ctrl u_dut (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .I_lease_grant(S_I_lease_grant),
        .I_abort(S_I_abort),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_seed(S_I_seed),
        .I_sector_budget(S_I_sector_budget),
        .I_directory_sector_budget(S_I_directory_sector_budget),
        .I_directory_duration(S_I_directory_duration),
        .I_directory_transition_ms(S_I_directory_transition_ms),
        .I_directory_transition(S_I_directory_transition),
        .I_directory_order(S_I_directory_order),
        .O_lease_active(S_O_lease_active),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_list_source_error(S_O_list_source_error),
        .O_list_build_error(S_O_list_build_error),
        .O_directory_build_error(S_O_directory_build_error),
        .O_count(S_O_count),
        .O_committed(S_O_committed),
        .O_used_directory(S_O_used_directory),
        .O_list_missing(S_O_list_missing),
        .O_list_started(S_O_list_started),
        .O_directory_started(S_O_directory_started),
        .O_list_warning(S_O_list_warning),
        .O_directory_warning(S_O_directory_warning),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_seed(S_O_seed),
        .O_sector_budget(S_O_sector_budget),
        .O_directory_sector_budget(S_O_directory_sector_budget),
        .O_directory_duration(S_O_directory_duration),
        .O_directory_transition_ms(S_O_directory_transition_ms),
        .O_directory_transition(S_O_directory_transition),
        .O_directory_order(S_O_directory_order),
        .O_list_start_valid(S_O_list_start_valid),
        .I_list_start_ready(S_I_list_start_ready),
        .O_child_abort(S_O_child_abort),
        .I_list_build_start(S_I_list_build_start),
        .I_source_done_valid(S_I_source_done_valid),
        .O_source_done_ready(S_O_source_done_ready),
        .I_source_error(S_I_source_error),
        .I_source_builder_started(S_I_source_builder_started),
        .I_source_tag(S_I_source_tag),
        .I_source_generation(S_I_source_generation),
        .O_directory_mode(S_O_directory_mode),
        .O_directory_start_valid(S_O_directory_start_valid),
        .I_directory_start_ready(S_I_directory_start_ready),
        .O_directory_tag(S_O_directory_tag),
        .I_build_committed(S_I_build_committed),
        .I_build_done_valid(S_I_build_done_valid),
        .O_build_done_ready(S_O_build_done_ready),
        .I_build_error(S_I_build_error),
        .I_build_count(S_I_build_count),
        .I_build_warning(S_I_build_warning),
        .I_build_tag(S_I_build_tag),
        .I_build_generation(S_I_build_generation)
    );

    always #4 S_I_clk=~S_I_clk;
    reg S_test_pass=0;
    reg [159:0] S_held;
    integer S_case=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: media_scan_ctrl case %0d: %0s",S_case,message); $stop; end
    endtask
    task launch;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_start_valid=1; S_I_tag=tag; S_I_context=1;
            S_I_generation=S_I_media_generation; S_I_seed=32'h12345678;
            S_I_sector_budget=12; S_I_directory_sector_budget=19;
            S_I_directory_duration=25; S_I_directory_transition=3;
            S_I_directory_transition_ms=600; S_I_directory_order=0;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0; S_I_tag=0; S_I_context=3;
            S_I_generation=0; S_I_seed=0; S_I_sector_budget=0; S_I_directory_sector_budget=0;
            S_I_directory_duration=0; S_I_directory_transition_ms=0;
            S_I_directory_transition=0; S_I_directory_order=3;
            if(S_O_context!==1 || S_O_tag!==tag || S_O_generation!==S_I_media_generation ||
                S_O_seed!==32'h12345678 || S_O_sector_budget!==12 || S_O_directory_sector_budget!==19 ||
                S_O_directory_duration!==25 || S_O_directory_transition_ms!==600 ||
                S_O_directory_transition!==3 || S_O_directory_order!==0) fail("command snapshot");
        end
    endtask
    task accept_list;
        begin
            wait(S_O_list_start_valid);
            @(negedge S_I_clk); S_I_list_start_ready=1;
            @(negedge S_I_clk); S_I_list_start_ready=0;
        end
    endtask
    task begin_builder;
        begin
            @(negedge S_I_clk); S_I_list_build_start=1; S_I_build_committed=0;
            @(negedge S_I_clk); S_I_list_build_start=0;
        end
    endtask
    task source_done;
        input [3:0] error;
        input started;
        begin
            @(negedge S_I_clk); S_I_source_done_valid=1; S_I_source_error=error;
            S_I_source_builder_started=started; S_I_source_tag=S_O_tag;
            S_I_source_generation=S_O_generation;
            @(posedge S_I_clk); while(!S_O_source_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_source_done_valid=0;
        end
    endtask
    task build_done;
        input [3:0] error;
        input [6:0] count;
        input committed,directory;
        begin
            @(negedge S_I_clk); S_I_build_done_valid=1; S_I_build_error=error;
            S_I_build_count=count; S_I_build_committed=committed;
            S_I_build_warning=directory ? 8'h41 : 8'h82;
            S_I_build_tag=directory ? S_O_directory_tag : S_O_tag;
            S_I_build_generation=S_O_generation;
            @(posedge S_I_clk); while(!S_O_build_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_build_done_valid=0;
        end
    endtask
    task accept_directory;
        begin
            wait(S_O_directory_start_valid);
            if(!S_O_used_directory || !S_O_directory_mode || S_O_list_start_valid ||
                S_O_directory_tag!==S_O_tag+16'd1) fail("automatic directory selection/tag");
            repeat(4) begin
                @(negedge S_I_clk);
                if(!S_O_directory_start_valid || S_O_done_valid || S_O_start_ready) fail("directory start backpressure");
            end
            S_I_directory_start_ready=1; S_I_build_committed=0;
            @(negedge S_I_clk); S_I_directory_start_ready=0;
        end
    endtask
    task finish;
        input [3:0] error;
        input [6:0] count;
        input committed,directory,missing;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_count!==count || S_O_committed!==committed ||
                S_O_used_directory!==directory || S_O_list_missing!==missing) fail("joined scan result");
            S_held={S_O_error,S_O_count,S_O_committed,S_O_used_directory,S_O_list_missing,
                S_O_list_warning,S_O_directory_warning,S_O_tag,S_O_generation};
            @(negedge S_I_clk); S_I_abort=1; S_I_media_valid=0;
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_done_valid || !S_O_lease_active || S_O_start_ready || S_O_list_start_valid ||
                    S_O_directory_start_valid || S_O_child_abort ||
                    {S_O_error,S_O_count,S_O_committed,S_O_used_directory,S_O_list_missing,
                    S_O_list_warning,S_O_directory_warning,S_O_tag,S_O_generation}!==S_held)
                    fail("terminal stability / lease retention");
            end
            S_I_abort=0; S_I_media_valid=1; S_I_done_ready=1;
            @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_lease_active) fail("lease not released after done handshake");
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_I_abort=1; @(negedge S_I_clk); S_I_abort=0; end
    endtask
    initial begin
        S_I_reset=1; S_I_media_valid=1; S_I_media_generation=32'h11223344;
        #35; @(negedge S_I_clk); S_I_reset=0; S_I_start_valid=1;
        repeat(6) begin
            @(negedge S_I_clk);
            if(!S_O_lease_request || S_O_start_ready || S_O_list_start_valid || S_O_directory_start_valid)
                fail("request depends on grant / speculative start");
        end
        S_I_start_valid=0; S_I_lease_grant=1;
        launch(16'h1000); accept_list; begin_builder; source_done(0,1);
        repeat(7) begin @(negedge S_I_clk); if(S_O_done_valid || S_O_directory_start_valid) fail("source done mistaken for index completion"); end
        build_done(0,3,1,0); finish(0,3,1,0,0);
        if(S_O_list_warning!==8'h82) fail("list warning lost");

        launch(16'h1001); accept_list; begin_builder; build_done(0,2,1,0);
        repeat(7) begin @(negedge S_I_clk); if(S_O_done_valid || S_O_directory_start_valid) fail("builder done skipped source retirement"); end
        source_done(0,1); finish(0,2,1,0,0);

        launch(16'h1020); accept_list; begin_builder;
        fork
            source_done(0,1);
            build_done(0,2,1,0);
        join
        finish(0,2,1,0,0);

        launch(16'hffff); accept_list; source_done(5,0); accept_directory;
        if(S_O_directory_tag!==0) fail("directory tag wrap");
        build_done(0,4,1,1); finish(0,4,1,1,1);
        if(S_O_directory_warning!==8'h41 || S_O_list_source_error!==5) fail("separate phase diagnostics");

        launch(16'h1003); accept_list; begin_builder; build_done(5,0,0,0);
        repeat(6) begin @(negedge S_I_clk); if(S_O_directory_start_valid) fail("fallback before source terminal"); end
        source_done(0,1); accept_directory; build_done(5,0,0,1); finish(5,0,0,1,0);

        launch(16'h1004); accept_list; source_done(1,0); finish(1,0,0,0,0);
        launch(16'h1005); accept_list; begin_builder; build_done(1,0,0,0);
        source_done(2,1); finish(1,0,0,0,0);
        launch(16'h1006); accept_list; begin_builder; source_done(1,1);
        build_done(1,1,0,0); finish(1,1,0,0,0);

        launch(16'h1007); accept_list; begin_builder; pulse_abort;
        repeat(7) begin @(negedge S_I_clk); if(!S_O_child_abort || S_O_done_valid) fail("cancel skipped real terminals"); end
        source_done(2,1); build_done(2,0,0,0); finish(2,0,0,0,0);
        launch(16'h1008); accept_list; source_done(5,0);
        wait(S_O_directory_start_valid); pulse_abort; finish(2,0,0,1,1);
        if(S_O_directory_started) fail("cancelled pending directory command was accepted");

        launch(16'h1009); accept_list; begin_builder;
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        source_done(3,1); build_done(3,0,0,0); finish(3,0,0,0,0);
        S_I_media_generation=S_I_media_generation+1;

        launch(16'h1010); accept_list; begin_builder;
        @(negedge S_I_clk); S_I_source_done_valid=1; S_I_source_tag=S_O_tag+1;
        S_I_source_generation=S_O_generation; S_I_source_error=5; S_I_source_builder_started=0;
        S_I_build_done_valid=1; S_I_build_tag=S_O_tag; S_I_build_generation=S_O_generation+1;
        @(posedge S_I_clk); if(!S_O_source_done_ready || !S_O_build_done_ready) fail("stale identity not drained");
        @(negedge S_I_clk); S_I_source_done_valid=0; S_I_build_done_valid=0;
        source_done(0,1); build_done(0,1,1,0); finish(0,1,1,0,0);

        // Commit is irrevocable even while the other terminal is delayed.
        launch(16'h1011); accept_list; begin_builder; build_done(0,1,1,0);
        pulse_abort; if(S_O_child_abort) fail("late abort rewrote committed success");
        source_done(0,1); finish(0,1,1,0,0);
        // The old committed level must not exempt a command with no build start yet.
        launch(16'h1012); pulse_abort; finish(2,0,0,0,0);
        if(S_O_list_started) fail("cancel before source start launched work");

        launch(16'h1013); accept_list; source_done(0,0); finish(4,0,0,0,0);
        launch(16'h1014); accept_list; source_done(5,1); finish(4,0,0,0,0);
        launch(16'h1015); accept_list; begin_builder; build_done(0,0,0,0);
        source_done(0,1); finish(4,0,0,0,0);
        launch(16'h1016); accept_list; source_done(5,0); accept_directory;
        build_done(1,0,0,1); finish(1,0,0,1,1);
        launch(16'h1017); accept_list; source_done(5,0); accept_directory; pulse_abort;
        build_done(2,0,0,1); finish(2,0,0,1,1);

        // Invalid defaults fail before starting either child.
        @(negedge S_I_clk); S_I_context=0; S_I_start_valid=1; S_I_generation=S_I_media_generation;
        @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_I_start_valid=0;
        finish(4,0,0,0,0);

        launch(16'h1018); accept_list; begin_builder;
        @(negedge S_I_clk); S_I_reset=1;
        repeat(4) @(negedge S_I_clk);
        S_I_reset=0; S_I_build_committed=0;
        if(S_O_busy || S_O_done_valid || S_O_child_abort) fail("global reset cleanup");
        launch(16'h1019); accept_list; source_done(5,0); accept_directory;
        build_done(0,1,1,1); finish(0,1,1,1,1);
        S_test_pass=1;
        $display("PASS: media_scan_ctrl joins, fallback, identity, cancellation and commit");
        $finish;
    end
    initial begin #10000000; fail("watchdog: scan controller did not retire"); end
endmodule
