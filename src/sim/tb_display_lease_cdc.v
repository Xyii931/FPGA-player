`timescale 1ns/1ps
// Real publication FIFOs/reset synchronizers; source proofs/query are video-domain fixtures.
module tb_display_lease_cdc;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reg S_valid=0,S_done_ready=0,S_install=1;
    reg [137:0] S_leases=0;
    reg [31:0] S_version=0;
    reg [1:0] S_block=3,S_in_use=0,S_owner_retired=3,S_pipeline_retired=3,S_fault=0;
    reg [246:0] S_query=0;
    wire S_ready,S_done,S_busy,S_host_fault,S_discard,S_installed,S_video_fault;
    wire [31:0] S_done_version,S_video_version;
    wire [3:0] S_error;
    wire [137:0] S_video_leases;
    wire [1:0] S_authorized;
    integer S_case=0,S_installs=0,S_discards=0;
    reg [137:0] S_expected;
    display_lease_cdc u_display_lease_cdc (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_publish_valid(S_valid),.O_publish_ready(S_ready),.I_publish_leases(S_leases),.I_publish_version(S_version),
        .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_done_version(S_done_version),.O_error(S_error),
        .O_host_busy(S_busy),.O_host_quarantined(S_host_fault),.O_host_response_discarded(S_discard),
        .I_video_install_enable(S_install),.I_video_block(S_block),.I_video_in_use(S_in_use),
        .I_video_owner_retired(S_owner_retired),.I_video_pipeline_retired(S_pipeline_retired),
        .I_video_guard_fault(S_fault),.I_video_query_config(S_query),.O_video_leases(S_video_leases),
        .O_video_version(S_video_version),.O_video_installed(S_installed),
        .O_video_quarantined(S_video_fault),.O_video_authorized(S_authorized)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: lease CDC case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #5000000; fail("watchdog timeout"); end
    always @(posedge S_video_clk) begin #1; if(S_installed) S_installs=S_installs+1; end
    always @(posedge S_host_clk) begin #1; if(S_discard) S_discards=S_discards+1; end
    function [137:0] leases;
        input [1:0] mask;
        input [2:0] a,b;
        input [31:0] ta,tb,ga,gb;
        input [1:0] resident;
        begin leases={mask,{b,a},{tb,ta},{gb,ga},resident}; end
    endfunction
    task query;
        input [137:0] value;
        begin
            S_query=0; S_query[246:245]=value[137:136]; S_query[243:238]=value[135:130];
            S_query[237:174]=value[129:66]; S_query[173:110]=value[65:2]; S_query[109:108]=value[1:0];
        end
    endtask
    task reset_all;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_valid=0; S_done_ready=0;
            S_install=1; S_block=3; S_in_use=0; S_owner_retired=3; S_pipeline_retired=3; S_fault=0; S_query=0;
            repeat(6) @(negedge S_video_clk); S_reset=0;
            wait(S_ready); @(negedge S_host_clk); S_installs=0; S_discards=0;
        end
    endtask
    task publish;
        input [137:0] value;
        input [31:0] version;
        begin
            @(negedge S_host_clk); S_leases=value; S_version=version; S_valid=1;
            @(posedge S_host_clk); while(!S_ready) @(posedge S_host_clk);
            @(negedge S_host_clk); S_valid=0; S_leases=~value; S_version=~version;
        end
    endtask
    task result;
        input [31:0] version;
        input [3:0] error;
        begin
            wait(S_done); #1;
            repeat(9) begin
                @(negedge S_host_clk);
                if(!S_done || S_done_version!==version || S_error!==error || !S_busy || S_ready)
                    fail("terminal identity/error changed under result backpressure");
            end
            S_done_ready=1; @(negedge S_host_clk); S_done_ready=0;
        end
    endtask
    task rejected_range;
        input [137:0] value;
        begin
            reset_all; publish(value,1); result(1,1);
            if(S_video_leases!==0 || S_video_version!==0 || S_installs!=0 || !S_video_fault || !S_host_fault || S_ready)
                fail("range error installed snapshot or failed to isolate");
        end
    endtask
    task rejected_permission;
        input integer kind;
        reg [137:0] previous,next_value;
        begin
            reset_all; previous=leases(1,0,0,5,0,11,0,0);
            publish(previous,1); result(1,0);
            next_value=previous; next_value[66+:32]=6;
            // A token-only change must require every proof, even with valid/slot unchanged.
            case(kind)
                0:S_block=2;
                1:S_in_use=1;
                2:S_owner_retired=2;
                3:S_pipeline_retired=2;
                4:S_fault=1;
            endcase
            publish(next_value,2); result(2,3);
            if(S_video_leases!==previous || S_video_version!=1 || S_installs!=1 ||
                !S_host_fault || !S_video_fault || S_authorized!=0)
                fail("changed source bypassed reservation/owner/pipeline/fault proof or destroyed old snapshot");
        end
    endtask
    initial begin
        S_case=1; reset_all; S_install=0;
        S_expected=leases(3,0,5,32'h1234,32'habcd,32'h11223344,32'h55667788,2);
        publish(S_expected,1);
        repeat(18) begin @(negedge S_host_clk);
            if(S_done || S_ready || !S_busy || S_video_version!=0) fail("receipt substituted for actual video installation");
        end
        @(negedge S_video_clk); S_install=1;
        wait(S_installed); #1;
        if(S_video_leases!==S_expected || S_video_version!=1) fail("accepted snapshot changed with live host inputs");
        wait(S_done); #1;
        if(S_installs!=1) fail("publication installed more than once");
        @(negedge S_video_clk); S_block=0; query(S_expected); #1;
        if(S_authorized!==3) fail("full installed identity did not authorize both sources");
        S_query[238+:3]=1; #1; if(S_authorized!==2) fail("slot identity ignored"); query(S_expected);
        S_query[174+:32]=32'h1235; #1; if(S_authorized!==2) fail("token identity ignored"); query(S_expected);
        S_query[110+:32]=0; #1; if(S_authorized!==2) fail("generation identity ignored"); query(S_expected);
        S_query[108]=1; #1; if(S_authorized!==2) fail("resident identity ignored"); query(S_expected);
        S_query[245]=0; #1; if(S_authorized!==2) fail("query source mask ignored"); query(S_expected);
        S_block=2; #1; if(S_authorized!==1) fail("block did not revoke only its source");
        S_block=0; S_fault=2; #1; if(S_authorized!==1) fail("guard fault did not revoke its source"); S_fault=0;
        result(1,0);

        S_case=2; S_in_use=3; S_owner_retired=0; S_pipeline_retired=0;
        publish(S_expected,2); result(2,0);
        if(S_video_version!=2 || S_video_leases!==S_expected || S_authorized!==3)
            fail("unchanged snapshot required unrelated source retirement");

        S_case=3; S_block=2; S_in_use=1; S_owner_retired=2; S_pipeline_retired=2;
        S_expected=leases(3,0,1,32'h1234,32'h8899,32'h11223344,32'h99999999,0);
        publish(S_expected,3); result(3,0); query(S_expected); #1;
        if(S_authorized!==1 || S_video_leases!==S_expected) fail("peer source publication disturbed active source");
        S_expected[137]=0; publish(S_expected,4); result(4,0);
        S_block=0; query(S_expected); #1;
        if(S_authorized!==1) fail("invalidated lease retained authorization");

        S_case=4; reset_all; S_install=0; S_expected=leases(1,0,0,5,0,11,0,0);
        publish(S_expected,1); wait(u_display_lease_cdc.S_host_state==2);
        @(negedge S_host_clk); S_host_run=0; S_install=1;
        repeat(18) @(negedge S_video_clk);
        if(S_video_version!=1 || S_done || S_installs!=1) fail("host stop lost installation or invented host completion");
        S_host_run=1; result(1,0);

        S_case=5; reset_all; @(negedge S_video_clk); S_video_run=0;
        publish(leases(1,0,0,5,0,11,0,0),1);
        repeat(24) begin @(negedge S_host_clk); if(S_done || S_ready || S_video_version!=0)
            fail("video stop fabricated installation"); end
        S_video_run=1; result(1,0);

        S_case=6; reset_all; S_install=0;
        publish(leases(1,0,0,5,0,11,0,0),1); wait(u_display_lease_cdc.S_video_state==1);
        @(negedge S_video_clk); S_in_use=1; S_install=1;
        result(1,3);
        if(S_video_leases!==0 || S_video_version!=0 || S_installs!=0 || !S_host_fault || !S_video_fault)
            fail("install edge did not recheck live source references");

        S_case=7; rejected_range(leases(1,6,0,5,0,11,0,0));
        S_case=8; rejected_range(leases(1,0,0,0,0,11,0,0));
        S_case=9; rejected_range(leases(1,0,0,5,0,11,0,1));

        S_case=10; reset_all; publish(0,0); result(0,2);
        if(!S_host_fault || S_video_fault || S_video_version!=0) fail("zero version reached video or lacked host isolation");
        reset_all; publish(0,2); result(2,2);
        if(S_installs!=0) fail("skipped host version installed");
        reset_all; publish(0,1); result(1,0); publish(0,1); result(1,2);
        if(S_installs!=1) fail("repeated version installed twice");

        S_case=11; reset_all;
        // Inject corrupted receiver sequence state, not an alternate publisher.
        force u_display_lease_cdc.S_video_sequence_ok=1'b0;
        publish(leases(1,0,0,5,0,11,0,0),1); result(1,2);
        release u_display_lease_cdc.S_video_sequence_ok;
        if(!S_video_fault || !S_host_fault || S_video_leases!==0 || S_installs!=0)
            fail("receiver version fault modified installed state");

        S_case=12; reset_all; S_install=0;
        publish(leases(1,0,0,5,0,11,0,0),1); wait(u_display_lease_cdc.S_host_state==2);
        wait(u_display_lease_cdc.S_video_state==1);
        @(negedge S_video_clk);
        // Enqueue one stale result via the REAL write interface, preserving both FIFO pointers.
        // Never force a read-valid net: that can advance an empty queue's read pointer.
        force u_display_lease_cdc.u_results.I_write_valid=1'b1;
        force u_display_lease_cdc.u_results.I_write_data={4'd0,32'd99};
        @(posedge S_video_clk);
        if(!u_display_lease_cdc.u_results.O_write_ready) fail("stale result injection was not enqueued");
        @(negedge S_video_clk);
        release u_display_lease_cdc.u_results.I_write_valid; release u_display_lease_cdc.u_results.I_write_data;
        wait(S_discards==1);
        #1; if(S_discards!=1 || S_done || !S_busy || S_host_fault) fail("wrong response version cleared in-flight obligation");
        S_install=1; result(1,0);

        S_case=13; reset_all;
        force u_display_lease_cdc.S_host_version=32'hffffffff;
        publish(0,1); result(1,2); release u_display_lease_cdc.S_host_version;
        if(!S_host_fault || S_installs!=0) fail("host version exhaustion wrapped");
        reset_all; force u_display_lease_cdc.O_video_version=32'hffffffff;
        publish(0,1); result(1,2); release u_display_lease_cdc.O_video_version;
        if(!S_video_fault || S_installs!=0) fail("video version exhaustion wrapped");

        S_case=14; reset_all; S_install=0;
        publish(leases(1,0,0,5,0,11,0,0),1); wait(u_display_lease_cdc.S_video_state==1);
        @(negedge S_host_clk); S_host_run=0;
        @(negedge S_video_clk); S_video_run=0; S_reset=1; #2;
        if(S_ready || S_done || S_authorized!=0 || S_video_leases!==0 || S_video_version!=0)
            fail("global reset with both clocks stopped retained old authority");
        reset_all; publish(leases(1,5,0,55,0,77,0,1),1); result(1,0);
        if(S_video_version!=1 || S_installs!=1 || S_host_fault || S_video_fault)
            fail("global reset did not flush stale publication and result");
        S_case=15; rejected_permission(0); rejected_permission(1); rejected_permission(2);
        rejected_permission(3); rejected_permission(4);
        $display("PASS: reliable lease CDC installation/identity/backpressure/stop/reset protocol");
        S_test_pass=1; $finish;
    end
endmodule
