`timescale 1ns/1ps
// Real timestamp FIFOs/counters; clock availability and request targets are fixtures.
// Checks actual host time at the target edge, rather than replaying the converter formula.
module tb_display_deadline_cdc;
    localparam integer C_MAX_AHEAD=4096;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    initial begin #3; forever begin #20; if(S_video_run) S_video_clk=~S_video_clk; end end
    reg S_enable=1,S_abort=0,S_valid=0,S_done_ready=0,S_kind=0;
    reg [31:0] S_epoch=0,S_target=0;
    reg [8:0] S_row=0;
    reg [15:0] S_tag=0;
    wire S_ready,S_busy,S_done,S_result_kind,S_usable,S_video_fault,S_discard,S_host_busy,S_host_fault;
    wire [3:0] S_error;
    wire [31:0] S_result_epoch,S_sequence,S_result_target,S_deadline,S_valid_until,S_host_time,S_video_time;
    wire [8:0] S_result_row;
    wire [15:0] S_result_tag;
    integer S_case=0,S_stamps=0,S_discards=0,S_mutation=0;
    reg [31:0] S_expected_target=0,S_last_host_stamp=0,S_target_host_time=0;
    reg [153:0] S_last_host_request=0,S_held_request=0,S_fake_request=0;
    reg [189:0] S_fake_echo=0;
    reg S_target_seen=0,S_watch_target=0,S_echo_held=0;
    reg [189:0] S_saved_echo=0;
    display_deadline_cdc #(.MAX_VIDEO_AHEAD(C_MAX_AHEAD)) u_deadline (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_enable(S_enable),.I_abort(S_abort),.I_request_valid(S_valid),.O_request_ready(S_ready),
        .I_kind(S_kind),.I_epoch(S_epoch),.I_row(S_row),.I_tag(S_tag),.I_target_video_time(S_target),
        .O_busy(S_busy),.O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),
        .O_kind(S_result_kind),.O_epoch(S_result_epoch),.O_row(S_result_row),.O_tag(S_result_tag),
        .O_sequence(S_sequence),.O_target_video_time(S_result_target),.O_deadline(S_deadline),
        .O_valid_until_video_time(S_valid_until),.O_deadline_usable(S_usable),
        .O_video_quarantined(S_video_fault),.O_response_discarded(S_discard),
        .O_host_busy(S_host_busy),.O_host_quarantined(S_host_fault),.O_host_time(S_host_time),.O_video_time(S_video_time)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: deadline CDC case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #100000000; fail("watchdog timeout"); end
    function future;
        input [31:0] a,b;
        reg [31:0] distance;
        begin distance=a-b; future=distance!=0 && !distance[31]; end
    endfunction
    always @(posedge S_host_clk) if(!S_reset && !u_deadline.S_host_reset) begin
        if(u_deadline.S_request_valid && u_deadline.S_request_ready) begin
            S_last_host_stamp=S_host_time; S_last_host_request=u_deadline.S_request_data; S_stamps=S_stamps+1;
        end
        if(S_echo_held && (!u_deadline.S_echo_valid || S_saved_echo!==u_deadline.S_echo))
            fail("host timestamp echo changed before actual FIFO acceptance");
        S_echo_held=u_deadline.S_echo_valid && !u_deadline.S_echo_write_ready;
        S_saved_echo=u_deadline.S_echo;
    end
    always @(posedge S_video_clk) if(!S_reset) begin
        if(S_watch_target && S_video_time==S_expected_target) begin
            S_target_host_time=S_host_time; S_target_seen=1;
        end
        if(u_deadline.S_echo_read_valid && u_deadline.S_echo_read_ready && u_deadline.S_echo_match) begin
            if(u_deadline.S_echo_data[185:154]!==S_last_host_stamp ||
                u_deadline.S_echo_data[153:0]!==S_last_host_request)
                fail("echo was not captured at actual host receipt with full identity");
        end
        #1; if(S_discard) S_discards=S_discards+1;
    end
    task reset_all;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_enable=1; S_abort=0; S_valid=0; S_done_ready=0;
            S_watch_target=0; S_target_seen=0; S_echo_held=0;
            repeat(6) @(negedge S_video_clk); S_reset=0;
            wait(S_ready); @(negedge S_video_clk); S_stamps=0; S_discards=0;
        end
    endtask
    task publish;
        input kind;
        input [31:0] epoch;
        input [8:0] row;
        input [15:0] tag;
        input [31:0] ahead;
        begin
            @(negedge S_video_clk); S_kind=kind; S_epoch=epoch; S_row=row; S_tag=tag;
            S_target=S_video_time+ahead; S_expected_target=S_target; S_target_seen=0; S_valid=1;
            @(posedge S_video_clk); while(!S_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_valid=0;
            // Live fields are deliberately no longer the accepted request.
            S_kind=~kind; S_epoch=~epoch; S_row=~row; S_tag=~tag; S_target=~S_expected_target;
        end
    endtask
    task held_result;
        input [3:0] error;
        input [31:0] expected_sequence;
        reg [189:0] saved;
        begin
            wait(S_done); #1;
            if(S_error!==error || S_sequence!==expected_sequence || !S_busy || S_ready)
                fail("result error/sequence or in-flight state");
            saved={S_error,S_result_kind,S_result_epoch,S_result_row,S_result_tag,S_sequence,S_result_target,
                S_deadline,S_valid_until};
            repeat(8) begin @(negedge S_video_clk);
                if(!S_done || saved!=={S_error,S_result_kind,S_result_epoch,S_result_row,S_result_tag,S_sequence,
                    S_result_target,S_deadline,S_valid_until}) fail("frozen result payload changed under backpressure");
            end
        end
    endtask
    task consume;
        begin @(negedge S_video_clk); S_done_ready=1; @(negedge S_video_clk); S_done_ready=0; end
    endtask
    task check_live;
        reg [31:0] slack;
        begin
            #1; slack=S_deadline-S_host_time;
            if(!S_usable || !future(S_deadline,S_host_time) || slack<32 ||
                !future(S_result_target,S_valid_until) || !future(S_valid_until,S_video_time))
                fail("usable result lacked actual host slack or conservative video expiry");
        end
    endtask
    task check_target_bound;
        reg [31:0] early;
        begin
            wait(S_target_seen); #1; early=S_target_host_time-S_deadline;
            if(early[31] || early<16) fail("deadline extended past actual host time at real video target");
        end
    endtask
    initial begin
        S_case=1; reset_all;
        publish(0,7,0,16'h1234,800); held_result(0,1); check_live;
        if(S_result_kind!==0 || S_result_epoch!=7 || S_result_row!=0 || S_result_tag!=16'h1234 ||
            S_result_target!==S_expected_target || S_stamps!=1) fail("accepted request identity followed live inputs");
        S_watch_target=1;
        wait(!S_usable);
        if(S_error!=0 || !S_done || !future(S_result_target,S_video_time)) fail("result expiry mutated terminal or occurred after target");
        repeat(2) @(negedge S_video_clk);
        check_target_bound;
        // Move time backwards after expiry to represent a later full counter wrap.
        force u_deadline.O_video_time=S_valid_until-1'b1;
        #1; if(S_usable) fail("expired held result resurrected after counter wrap");
        release u_deadline.O_video_time;
        consume;

        S_case=2; reset_all;
        publish(0,0,0,1,1000); held_result(1,0); consume;
        publish(1,8,480,2,1000); held_result(1,0); consume;
        publish(0,8,0,6,0); held_result(2,0); consume;
        publish(0,8,0,3,32'hffffffff); held_result(2,0); consume;
        // One tick elapses between task setup and acceptance: actual distance is exactly half-range.
        publish(0,8,0,4,32'h80000001); held_result(2,0); consume;
        publish(0,8,0,5,C_MAX_AHEAD+32); held_result(3,0); consume;
        if(S_stamps!=0 || S_video_fault || S_host_fault) fail("local reject issued a timestamp or consumed remote sequence");
        publish(1,8,479,16'hffff,1000); held_result(0,1); check_live; consume;

        S_case=3; reset_all;
        // Stop real echo FIFO writes while the host retains its accepted timestamp.
        force u_deadline.S_echo_write_ready=1'b0;
        force u_deadline.u_echoes.I_write_valid=1'b0;
        publish(1,9,11,16'h4321,2000); wait(u_deadline.S_echo_valid);
        S_held_request=u_deadline.S_request;
        repeat(20) begin @(negedge S_video_clk);
            if(S_done || u_deadline.S_request!==S_held_request || !u_deadline.S_echo_valid)
                fail("host echo backpressure lost the real timestamp obligation"); end
        release u_deadline.S_echo_write_ready; release u_deadline.u_echoes.I_write_valid;
        held_result(0,1); check_live; S_watch_target=1; check_target_bound; consume;

        S_case=4; reset_all; S_abort=1;
        publish(0,10,0,1,1000); held_result(4,0); consume; S_abort=0;
        if(S_stamps!=0) fail("preaccepted cancellation created a remote timestamp");
        publish(0,10,0,2,1000); held_result(0,1); check_live; consume;

        S_case=5; reset_all;
        force u_deadline.S_request_write_ready=1'b0;
        force u_deadline.u_requests.I_write_valid=1'b0;
        publish(0,11,0,1,1000); S_abort=1; S_held_request=u_deadline.S_request;
        repeat(10) begin @(negedge S_video_clk);
            if(S_done || u_deadline.S_video_state!=1 || u_deadline.S_request!==S_held_request || S_stamps!=0)
                fail("cancel withdrew a presented FIFO request under backpressure"); end
        release u_deadline.S_request_write_ready; release u_deadline.u_requests.I_write_valid;
        held_result(4,1); if(S_stamps!=1 || S_usable) fail("cancel substituted for actual remote drain"); consume;

        S_case=6; reset_all; @(negedge S_host_clk); S_host_run=0;
        publish(0,12,0,1,2000);
        @(negedge S_video_clk); S_enable=0;
        repeat(20) begin @(negedge S_video_clk); if(S_done || S_stamps!=0 || !S_busy)
            fail("host stop fabricated timestamp completion"); end
        S_host_run=1; held_result(4,1); consume; S_enable=1;
        publish(0,12,0,2,1000); held_result(0,2); check_live; consume;

        S_case=7; reset_all; @(negedge S_host_clk); S_host_run=0;
        // Deliberately omit clock-availability withdrawal: overdue still cannot fake done.
        publish(0,13,0,1,1000);
        repeat(C_MAX_AHEAD+20) @(negedge S_video_clk);
        if(S_done || !u_deadline.S_overdue || S_stamps!=0) fail("overdue wait fabricated an unreceived host echo");
        force u_deadline.O_video_time=u_deadline.S_request[121:90]+64;
        @(negedge S_video_clk); release u_deadline.O_video_time;
        S_host_run=1; held_result(2,1);
        if(S_usable || !u_deadline.S_overdue) fail("overdue in-flight request resurrected after counter wrap"); consume;

        S_case=8; reset_all;
        publish(1,14,3,1,2000); wait(u_deadline.S_video_state==2);
        @(negedge S_video_clk); S_enable=0; S_video_run=0;
        repeat(60) begin @(negedge S_host_clk); if(S_done || !S_busy) fail("video stop consumed timestamp echo"); end
        S_video_run=1; held_result(4,1); consume; S_enable=1;
        publish(1,14,4,2,1000); held_result(0,2); check_live; consume;

        S_case=9; reset_all;
        publish(0,15,0,1,1000); held_result(0,1); check_live;
        @(negedge S_video_clk); S_enable=0; #1;
        if(S_usable || S_error!=0 || !S_done) fail("late clock withdrawal mutated frozen error or retained use permission");
        repeat(2) @(negedge S_video_clk); S_enable=1; #1;
        if(S_usable || S_error!=0) fail("held result resurrected after clock permission recovery"); consume;
        publish(0,15,0,2,1000); held_result(0,2); check_live;
        @(negedge S_video_clk); S_abort=1; #1;
        if(S_usable || S_error!=0 || !S_done) fail("late abort mutated frozen error or retained use permission");
        repeat(2) @(negedge S_video_clk); S_abort=0; #1;
        if(S_usable) fail("held result resurrected after late abort cleared"); consume;

        S_case=10;
        for(S_mutation=0;S_mutation<7;S_mutation=S_mutation+1) begin
            reset_all; force u_deadline.S_request_ready=1'b0;
            publish(1,16,17,16'h5678,2000); wait(u_deadline.S_video_state==2);
            S_fake_request=u_deadline.S_request;
            case(S_mutation)
                0:S_fake_request[122]=~S_fake_request[122];
                1:S_fake_request[90]=~S_fake_request[90];
                2:S_fake_request[58]=~S_fake_request[58];
                3:S_fake_request[57]=~S_fake_request[57];
                4:S_fake_request[25]=~S_fake_request[25];
                5:S_fake_request[16]=~S_fake_request[16];
                6:S_fake_request[0]=~S_fake_request[0];
            endcase
            S_fake_echo={4'd0,32'd0,S_fake_request};
            @(negedge S_host_clk);
            // Inject through the REAL write port; do not force read-valid on an empty FIFO.
            force u_deadline.u_echoes.I_write_valid=1'b1;
            force u_deadline.u_echoes.I_write_data=S_fake_echo;
            @(posedge S_host_clk); if(!u_deadline.u_echoes.O_write_ready) fail("bad identity echo was not enqueued");
            @(negedge S_host_clk);
            release u_deadline.u_echoes.I_write_valid; release u_deadline.u_echoes.I_write_data;
            wait(S_discards==1); #1;
            if(S_done || !S_busy || S_video_fault || S_stamps!=0) fail("wrong full identity cleared unique in-flight obligation");
            release u_deadline.S_request_ready;
            held_result(0,1); check_live; consume;
        end

        S_case=11; reset_all; force u_deadline.S_host_sequence=32'd7;
        publish(0,17,0,1,1000); held_result(5,1); release u_deadline.S_host_sequence;
        if(!S_host_fault || !S_video_fault || S_usable || S_ready) fail("host sequence contract did not isolate both endpoints"); consume;
        reset_all; force u_deadline.S_host_range_ok=1'b0;
        publish(0,17,0,2,1000); held_result(5,1); release u_deadline.S_host_range_ok;
        if(!S_host_fault || !S_video_fault) fail("host identity recheck was bypassed"); consume;

        S_case=12; reset_all; force u_deadline.S_sequence_exhausted=1'b1;
        publish(0,18,0,1,1000); held_result(6,0); release u_deadline.S_sequence_exhausted;
        if(!S_video_fault || S_host_fault || S_stamps!=0 || S_ready) fail("remote sequence exhaustion wrapped"); consume;

        S_case=13; reset_all;
        @(negedge S_video_clk);
        force u_deadline.O_host_time=32'hfffffe00; force u_deadline.O_video_time=32'hffffff00;
        @(negedge S_video_clk); release u_deadline.O_host_time; release u_deadline.O_video_time;
        publish(1,19,479,16'hffff,1000); held_result(0,1); check_live;
        if(S_result_target>1000 || S_deadline>10000) fail("modular host/video time did not cross wrap");
        S_watch_target=1; check_target_bound; consume;

        S_case=14; reset_all; @(negedge S_host_clk); S_host_run=0;
        publish(0,20,0,1,1000); wait(u_deadline.S_video_state==2);
        @(negedge S_video_clk); S_video_run=0; S_reset=1; #2;
        if(S_done || S_ready || S_usable || S_host_time!=0 || S_video_time!=0)
            fail("global reset with clocks stopped retained timestamp authority");
        reset_all; publish(0,20,0,2,1000); held_result(0,1); check_live; consume;

        S_case=15; reset_all; S_enable=0;
        @(negedge S_video_clk); S_kind=1; S_epoch=21; S_row=7; S_tag=1;
        S_target=S_video_time+1000; S_valid=1;
        repeat(12) begin @(negedge S_video_clk); if(S_ready || S_done || S_stamps!=0)
            fail("disabled timestamp service admitted request"); end
        S_enable=1;
        @(posedge S_video_clk); while(!S_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_valid=0;
        held_result(0,1); check_live; consume;

        S_case=16; reset_all;
        publish(0,22,0,1,12); held_result(2,1);
        if(S_usable || S_deadline!=0 || S_valid_until!=0) fail("insufficient fresh slack produced a usable deadline"); consume;
        $display("PASS: causal deadline timestamp CDC, actual host-time bounds, expiry and identity");
        S_test_pass=1; $finish;
    end
endmodule
