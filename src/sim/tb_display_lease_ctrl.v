`timescale 1ns/1ps
// Real slot manager; retirement and host authorization are explicit test endpoints.
module tb_display_lease_ctrl;
    reg S_clk=0,S_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_run) S_clk=~S_clk;
    reg S_fixture=1,S_f_valid=0,S_f_result_ready=0,S_f_resident=0;
    reg [2:0] S_f_op=0,S_f_slot=0;
    reg [1:0] S_f_owner=2;
    reg [31:0] S_f_token=0,S_f_generation=11;
    reg S_cmd_gate=1,S_result_gate=1,S_wrong_result=0;
    reg [17:0] S_status_xor=0;
    reg  S_c_I_start_valid=0;
    wire  S_c_O_start_ready;
    reg  S_c_I_op=0;
    reg  S_c_I_source=0;
    reg [2:0] S_c_I_slot=0;
    reg [31:0] S_c_I_token=0;
    reg [31:0] S_c_I_generation=0;
    reg [15:0] S_c_I_tag=0;
    reg  S_c_I_abort=0;
    reg [1:0] S_c_I_source_idle=0;
    reg [1:0] S_c_I_acquire_permit=0;
    reg [1:0] S_c_I_retire_ack=0;
    wire [1:0] S_c_O_retire_request;
    wire  S_c_O_busy;
    wire  S_c_O_done_valid;
    reg  S_c_I_done_ready=0;
    wire [3:0] S_c_O_error;
    wire [3:0] S_c_O_slot_error;
    wire  S_c_O_op;
    wire  S_c_O_source;
    wire [2:0] S_c_O_slot;
    wire [31:0] S_c_O_token;
    wire [31:0] S_c_O_generation;
    wire [15:0] S_c_O_tag;
    wire  S_c_O_changed;
    wire  S_c_O_cancel_late;
    wire  S_c_O_quarantined;
    wire  S_c_O_response_discarded;
    wire [1:0] S_c_O_owned;
    wire [1:0] S_c_O_lease_valid;
    wire [5:0] S_c_O_lease_slots;
    wire [63:0] S_c_O_lease_tokens;
    wire [63:0] S_c_O_lease_generations;
    wire [1:0] S_c_O_lease_resident;
    wire  S_c_O_slot_cmd_valid;
    wire [2:0] S_c_O_slot_cmd_op;
    wire [2:0] S_c_O_slot_cmd_slot;
    wire [1:0] S_c_O_slot_cmd_owner;
    wire [31:0] S_c_O_slot_cmd_token;
    wire [31:0] S_c_O_slot_cmd_generation;
    wire  S_c_O_slot_frame_boundary;
    wire  S_c_O_slot_reader_retired;
    wire  S_c_O_slot_result_ready;
    reg  S_m_I_media_valid=0;
    reg [31:0] S_m_I_media_generation=0;
    wire  S_m_O_cmd_ready;
    wire  S_m_O_result_valid;
    wire [3:0] S_m_O_result_error;
    wire [2:0] S_m_O_result_op;
    wire [2:0] S_m_O_result_slot;
    wire [1:0] S_m_O_result_owner;
    wire [31:0] S_m_O_result_token;
    wire [31:0] S_m_O_result_generation;
    wire [20:0] S_m_O_result_base;
    wire [17:0] S_m_O_slot_states;
    wire [191:0] S_m_O_slot_tokens;
    wire [191:0] S_m_O_slot_generations;
    wire [191:0] S_m_O_slot_assets;
    wire [17:0] S_m_O_slot_layouts;
    wire [17:0] S_m_O_slot_readers;
    wire [11:0] S_m_O_slot_rotations;
    wire [5:0] S_m_O_slot_resident;
    wire [5:0] S_m_O_slot_stale;
    wire [5:0] S_m_O_cancel_loading;
    wire  S_m_O_token_exhausted;
    display_lease_ctrl u_dut (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_start_valid(S_c_I_start_valid),
        .O_start_ready(S_c_O_start_ready),
        .I_op(S_c_I_op),
        .I_source(S_c_I_source),
        .I_slot(S_c_I_slot),
        .I_token(S_c_I_token),
        .I_generation(S_c_I_generation),
        .I_tag(S_c_I_tag),
        .I_abort(S_c_I_abort),
        .I_source_idle(S_c_I_source_idle),
        .I_acquire_permit(S_c_I_acquire_permit),
        .I_retire_ack(S_c_I_retire_ack),
        .O_retire_request(S_c_O_retire_request),
        .O_busy(S_c_O_busy),
        .O_done_valid(S_c_O_done_valid),
        .I_done_ready(S_c_I_done_ready),
        .O_error(S_c_O_error),
        .O_slot_error(S_c_O_slot_error),
        .O_op(S_c_O_op),
        .O_source(S_c_O_source),
        .O_slot(S_c_O_slot),
        .O_token(S_c_O_token),
        .O_generation(S_c_O_generation),
        .O_tag(S_c_O_tag),
        .O_changed(S_c_O_changed),
        .O_cancel_late(S_c_O_cancel_late),
        .O_quarantined(S_c_O_quarantined),
        .O_response_discarded(S_c_O_response_discarded),
        .O_owned(S_c_O_owned),
        .O_lease_valid(S_c_O_lease_valid),
        .O_lease_slots(S_c_O_lease_slots),
        .O_lease_tokens(S_c_O_lease_tokens),
        .O_lease_generations(S_c_O_lease_generations),
        .O_lease_resident(S_c_O_lease_resident),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_readers(S_m_O_slot_readers ^ S_status_xor),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .O_slot_cmd_valid(S_c_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_m_O_cmd_ready && S_cmd_gate && !S_fixture),
        .O_slot_cmd_op(S_c_O_slot_cmd_op),
        .O_slot_cmd_slot(S_c_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_c_O_slot_cmd_owner),
        .O_slot_cmd_token(S_c_O_slot_cmd_token),
        .O_slot_cmd_generation(S_c_O_slot_cmd_generation),
        .O_slot_frame_boundary(S_c_O_slot_frame_boundary),
        .O_slot_reader_retired(S_c_O_slot_reader_retired),
        .I_slot_result_valid(S_m_O_result_valid && S_result_gate && !S_fixture),
        .O_slot_result_ready(S_c_O_slot_result_ready),
        .I_slot_result_error(S_m_O_result_error),
        .I_slot_result_op(S_m_O_result_op),
        .I_slot_result_slot(S_m_O_result_slot),
        .I_slot_result_owner(S_m_O_result_owner),
        .I_slot_result_token(S_m_O_result_token),
        .I_slot_result_generation(S_m_O_result_generation ^ (S_wrong_result ? 32'd1 : 32'd0)),
        .I_slot_result_base(S_m_O_result_base)
    );
    fb_slot_manager u_slots (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_media_valid(S_m_I_media_valid),
        .I_media_generation(S_m_I_media_generation),
        .I_cmd_valid(S_fixture ? S_f_valid : (S_c_O_slot_cmd_valid && S_cmd_gate)),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_fixture ? S_f_op : S_c_O_slot_cmd_op),
        .I_cmd_slot(S_fixture ? S_f_slot : S_c_O_slot_cmd_slot),
        .I_cmd_owner(S_fixture ? S_f_owner : S_c_O_slot_cmd_owner),
        .I_cmd_token(S_fixture ? S_f_token : S_c_O_slot_cmd_token),
        .I_cmd_generation(S_fixture ? S_f_generation : S_c_O_slot_cmd_generation),
        .I_cmd_asset(32'd9),
        .I_cmd_layout(3'd0),
        .I_cmd_rotation(2'd0),
        .I_cmd_resident(S_f_resident),
        .I_cmd_success(1'b1),
        .I_producer_retired(1'b1),
        .I_memory_retired(1'b1),
        .I_reader_retired(S_fixture ? 1'b1 : S_c_O_slot_reader_retired),
        .I_frame_boundary(S_fixture ? 1'b1 : S_c_O_slot_frame_boundary),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_fixture ? S_f_result_ready : (S_c_O_slot_result_ready && S_result_gate && !S_wrong_result)),
        .O_result_error(S_m_O_result_error),
        .O_result_op(S_m_O_result_op),
        .O_result_slot(S_m_O_result_slot),
        .O_result_owner(S_m_O_result_owner),
        .O_result_token(S_m_O_result_token),
        .O_result_generation(S_m_O_result_generation),
        .O_result_base(S_m_O_result_base),
        .O_slot_states(S_m_O_slot_states),
        .O_slot_tokens(S_m_O_slot_tokens),
        .O_slot_generations(S_m_O_slot_generations),
        .O_slot_assets(S_m_O_slot_assets),
        .O_slot_layouts(S_m_O_slot_layouts),
        .O_slot_readers(S_m_O_slot_readers),
        .O_slot_rotations(S_m_O_slot_rotations),
        .O_slot_resident(S_m_O_slot_resident),
        .O_slot_stale(S_m_O_slot_stale),
        .O_cancel_loading(S_m_O_cancel_loading),
        .O_token_exhausted(S_m_O_token_exhausted)
    );
    integer S_case=0,S_discards=0,S_commands=0;
    reg [31:0] S_saved_token[0:5],S_saved_generation[0:5];
    reg S_expect_op,S_expect_source;
    reg [2:0] S_expect_slot;
    reg [31:0] S_expect_token,S_expect_generation;
    reg [15:0] S_expect_tag;
    reg S_cmd_held=0;
    reg [73:0] S_cmd_saved,S_cmd_now;
    task fail;
        input [767:0] message;
        begin $display("FAIL: display_lease_ctrl case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #1000000; fail("watchdog timeout"); end
    always @(posedge S_clk) begin
        if(S_reset) begin S_cmd_held=0; S_commands=0; S_discards=0; end
        else begin
            S_cmd_now={S_c_O_slot_cmd_op,S_c_O_slot_cmd_slot,S_c_O_slot_cmd_owner,
                S_c_O_slot_cmd_token,S_c_O_slot_cmd_generation,S_c_O_slot_frame_boundary,S_c_O_slot_reader_retired};
            if(S_cmd_held && (!S_c_O_slot_cmd_valid || S_cmd_now!==S_cmd_saved)) fail("slot command changed before acceptance");
            S_cmd_held=S_c_O_slot_cmd_valid && !(S_m_O_cmd_ready && S_cmd_gate && !S_fixture); S_cmd_saved=S_cmd_now;
            if(S_c_O_slot_cmd_valid && S_m_O_cmd_ready && S_cmd_gate && !S_fixture) S_commands=S_commands+1;
            #1; if(S_c_O_response_discarded) S_discards=S_discards+1;
        end
    end
    task fixture_cmd;
        input integer op,slot;
        input [31:0] token,generation;
        begin
            @(negedge S_clk); S_f_op=op; S_f_slot=slot; S_f_token=token; S_f_generation=generation; S_f_valid=1;
            @(posedge S_clk); while(!S_m_O_cmd_ready) @(posedge S_clk);
            @(negedge S_clk); S_f_valid=0;
            wait(S_m_O_result_valid); #1;
            if(S_m_O_result_error!=0 || S_m_O_result_op!==op[2:0] || S_m_O_result_slot!==slot[2:0]) fail("fixture slot preparation");
            if(op==0) begin S_saved_token[slot]=S_m_O_result_token; S_saved_generation[slot]=generation; end
            @(negedge S_clk); S_f_result_ready=1;
            @(negedge S_clk); S_f_result_ready=0;
        end
    endtask
    task reset_all;
        integer slot;
        begin
            S_case=S_case+1;
            @(negedge S_clk); S_reset=1; S_fixture=1; S_f_valid=0; S_f_result_ready=0; S_f_resident=0;
            S_c_I_start_valid=0; S_c_I_done_ready=0; S_c_I_abort=0; S_c_I_source_idle=3; S_c_I_acquire_permit=0; S_c_I_retire_ack=0;
            S_cmd_gate=1; S_result_gate=1; S_wrong_result=0; S_status_xor=0; S_m_I_media_valid=1; S_m_I_media_generation=11;
            repeat(4) @(negedge S_clk); S_reset=0;
            for(slot=0;slot<6;slot=slot+1) begin
                S_f_resident=slot==5;
                fixture_cmd(0,slot,0,slot==5 ? 77 : 11);
                fixture_cmd(1,slot,S_saved_token[slot],S_saved_generation[slot]);
            end
            @(negedge S_clk); S_fixture=0; S_f_resident=0;
            if(!S_c_O_start_ready || S_c_O_owned!=0 || S_c_O_lease_valid!=0 || S_c_O_quarantined) fail("reset/real manager preparation");
        end
    endtask
    task start;
        input integer op,source,slot;
        input [31:0] token,generation;
        begin
            S_case=S_case+1; S_expect_op=op; S_expect_source=source; S_expect_slot=slot;
            S_expect_token=token; S_expect_generation=generation; S_expect_tag=S_case;
            @(negedge S_clk); S_c_I_op=op; S_c_I_source=source; S_c_I_slot=slot;
            S_c_I_token=token; S_c_I_generation=generation; S_c_I_tag=S_expect_tag; S_c_I_start_valid=1;
            @(posedge S_clk); if(!S_c_O_start_ready) fail("unexpected start backpressure");
            @(negedge S_clk); S_c_I_start_valid=0;
            // All command fields are snapshots, independent of later input changes.
            S_c_I_op=!op; S_c_I_source=!source; S_c_I_slot=7;
            S_c_I_token=32'hdeadbeef; S_c_I_generation=32'hffffffff; S_c_I_tag=0;
        end
    endtask
    task result;
        input integer error,slot_error,changed,late;
        reg [94:0] saved;
        begin
            wait(S_c_O_done_valid); #1;
            if(S_c_O_error!==error[3:0] || S_c_O_slot_error!==slot_error[3:0] || S_c_O_changed!==changed[0] ||
                S_c_O_cancel_late!==late[0] || S_c_O_op!==S_expect_op || S_c_O_source!==S_expect_source ||
                S_c_O_slot!==S_expect_slot || S_c_O_token!==S_expect_token || S_c_O_generation!==S_expect_generation || S_c_O_tag!==S_expect_tag)
                fail("terminal snapshot/error/side-effect fact");
            saved={S_c_O_error,S_c_O_slot_error,S_c_O_op,S_c_O_source,S_c_O_slot,S_c_O_token,S_c_O_generation,S_c_O_tag,S_c_O_changed,S_c_O_cancel_late};
            repeat(5) begin
                @(negedge S_clk); S_c_I_start_valid=1;
                if(S_c_O_start_ready || !S_c_O_done_valid || !S_c_O_busy || saved!=={S_c_O_error,S_c_O_slot_error,
                    S_c_O_op,S_c_O_source,S_c_O_slot,S_c_O_token,S_c_O_generation,S_c_O_tag,S_c_O_changed,S_c_O_cancel_late})
                    fail("terminal changed under backpressure");
            end
            S_c_I_start_valid=0; S_c_I_done_ready=1;
            @(negedge S_clk); S_c_I_done_ready=0; S_c_I_abort=0; S_c_I_acquire_permit=0;
        end
    endtask
    task permit;
        input integer source;
        begin
            repeat(4) begin @(negedge S_clk); if(S_c_O_slot_cmd_valid || S_c_O_done_valid) fail("acquire bypassed frame authorization"); end
            S_c_I_acquire_permit[source]=1;
            wait(S_c_O_slot_cmd_valid);
            @(negedge S_clk); S_c_I_acquire_permit[source]=0;
        end
    endtask
    task acquire;
        input integer source,slot;
        begin start(0,source,slot,S_saved_token[slot],S_saved_generation[slot]); permit(source); result(0,0,1,0); end
    endtask
    task release_source;
        input integer source,slot;
        begin
            start(1,source,slot,S_saved_token[slot],S_saved_generation[slot]);
            wait(S_c_O_retire_request[source]);
            repeat(5) begin @(negedge S_clk); if(S_c_O_slot_cmd_valid || S_c_O_done_valid || !S_c_O_lease_valid[source]) fail("release before real reader retirement"); end
            S_c_I_retire_ack[source]=1;
            wait(!S_c_O_retire_request[source]);
            repeat(4) begin @(negedge S_clk); if(S_c_O_done_valid) fail("release skipped ack return to zero"); end
            S_c_I_retire_ack[source]=0;
            result(0,0,1,0);
        end
    endtask
    integer before_commands;
    initial begin
        reset_all;
        acquire(0,0);
        if(S_c_O_lease_valid!==1 || S_c_O_lease_slots[2:0]!==0 || S_c_O_lease_tokens[31:0]!==S_saved_token[0]) fail("first physical source lease");
        S_c_I_source_idle[0]=0;
        start(0,0,2,S_saved_token[2],11); result(2,0,0,0);
        start(1,0,0,S_saved_token[0],11); result(2,0,0,0);
        acquire(1,1);
        if(S_c_O_lease_valid!==3 || S_m_O_slot_readers[2:0]!==1 || S_m_O_slot_readers[5:3]!==2) fail("two independent physical owners");
        start(0,1,2,S_saved_token[2],11); result(2,0,0,0);
        // Shared slot references release independently; next acquisition rotates source.
        release_source(1,1); acquire(1,0);
        if(S_m_O_slot_readers[2:0]!==3) fail("shared slot did not retain both references");
        S_c_I_source_idle[0]=1;
        start(1,0,0,S_saved_token[0]+1,11); result(3,0,0,0);
        release_source(0,0);
        if(S_m_O_slot_readers[2:0]!==2 || S_c_O_lease_valid!==2) fail("release damaged shared foreground");
        acquire(0,2); release_source(1,0);
        // Card loss preserves held old frame; release still uses original generation.
        @(negedge S_clk); S_m_I_media_valid=0;
        repeat(6) @(negedge S_clk);
        if(S_c_O_lease_valid!==1 || S_c_O_quarantined || !S_m_O_slot_stale[2]) fail("media loss revoked foreground read lock");
        release_source(0,2);
        if(S_m_O_slot_states[2*3+:3]!==0) fail("last stale reference not freed after true retirement");
        start(0,1,3,S_saved_token[3],11); permit(1); result(4,2,0,0);
        acquire(1,5);
        if(S_c_O_lease_resident!==2 || S_c_O_lease_valid!==2) fail("resident page unavailable without media");
        release_source(1,5);
        // Invalid inputs and cancellation before a presented command have no side effects.
        start(0,0,6,1,11); result(1,0,0,0);
        start(0,0,0,0,11); result(1,0,0,0);
        start(1,0,0,S_saved_token[0],11); result(2,0,0,0);
        start(0,0,5,S_saved_token[5],77);
        @(negedge S_clk); S_c_I_abort=1; result(5,0,0,0);
        // Presented acquire survives cancel/permit withdrawal; only true result publishes lease.
        S_cmd_gate=0; S_result_gate=0;
        start(0,0,5,S_saved_token[5],77); permit(0);
        @(negedge S_clk); S_c_I_abort=1;
        repeat(8) begin @(negedge S_clk); if(!S_c_O_slot_cmd_valid || S_c_O_lease_valid[0] || S_c_O_done_valid) fail("late acquire cancel withdrew command"); end
        S_cmd_gate=1;
        wait(S_m_O_result_valid);
        repeat(5) begin @(negedge S_clk); if(S_c_O_lease_valid[0] || S_c_O_done_valid) fail("command acceptance replaced true result"); end
        S_wrong_result=1; S_result_gate=1;
        repeat(5) begin @(negedge S_clk); if(S_c_O_done_valid || S_c_O_lease_valid[0]) fail("wrong result identity acquired lease"); end
        if(S_discards==0) fail("wrong response was not diagnosed");
        S_wrong_result=0; result(5,0,1,1);
        if(S_c_O_lease_valid!==1 || S_c_O_owned!==1) fail("late cancel erased acquired reference");
        // A release waiting for the stale ack to clear is still cancellable.
        S_c_I_retire_ack[0]=1;
        start(1,0,5,S_saved_token[5],77);
        @(negedge S_clk); S_c_I_abort=1;
        result(5,0,0,0);
        if(S_c_O_retire_request!=0 || S_c_O_lease_valid!==1) fail("early release cancellation changed ownership");
        // A stale ack cannot authorize a new release; cancellation is late once retirement starts.
        S_c_I_retire_ack[0]=1; S_cmd_gate=0;
        start(1,0,5,S_saved_token[5],77);
        repeat(5) begin @(negedge S_clk); if(S_c_O_retire_request[0] || S_c_O_slot_cmd_valid) fail("stale ack treated as fresh retirement"); end
        S_c_I_retire_ack[0]=0; wait(S_c_O_retire_request[0]);
        @(negedge S_clk); S_c_I_abort=1;
        repeat(6) begin @(negedge S_clk); if(!S_c_O_retire_request[0] || S_c_O_slot_cmd_valid || S_c_O_done_valid) fail("late release cancel forged retirement"); end
        S_c_I_retire_ack[0]=1; wait(S_c_O_slot_cmd_valid);
        repeat(5) begin @(negedge S_clk); if(!S_c_O_lease_valid[0] || !S_c_O_slot_cmd_valid) fail("release happened before manager accepted"); end
        S_run=0; #160;
        if(S_c_O_done_valid || !S_c_O_retire_request[0]) fail("stopped host clock manufactured completion");
        S_run=1; @(negedge S_clk); S_cmd_gate=1;
        wait(!S_c_O_retire_request[0]);
        if(S_c_O_done_valid) fail("release result did not wait ack zero");
        @(negedge S_clk); S_c_I_retire_ack[0]=0; result(0,0,1,1);
        if(S_c_O_owned!==0 || S_c_O_quarantined) fail("normal cancellation flow leaked lock");
        // Authority loss after retirement starts preserves the lock and quarantines reuse.
        reset_all; acquire(0,0); before_commands=S_commands;
        start(1,0,0,S_saved_token[0],11); wait(S_c_O_retire_request[0]);
        @(negedge S_clk); S_c_I_source_idle[0]=0;
        repeat(3) @(negedge S_clk);
        S_c_I_source_idle[0]=1; S_c_I_retire_ack[0]=1;
        wait(!S_c_O_retire_request[0]); @(negedge S_clk); S_c_I_retire_ack[0]=0;
        result(6,0,0,0);
        if(!S_c_O_quarantined || S_c_O_start_ready || S_c_O_owned!==1 || S_c_O_lease_valid!==1 || S_commands!=before_commands)
            fail("authority loss released/reused unknown source");
        // Once acquire was presented, authority loss cannot erase its real result.
        reset_all; S_cmd_gate=0;
        start(0,1,1,S_saved_token[1],11); permit(1);
        @(negedge S_clk); S_c_I_source_idle[1]=0;
        repeat(4) @(negedge S_clk);
        S_c_I_source_idle[1]=1; S_cmd_gate=1;
        result(6,0,1,0);
        if(!S_c_O_quarantined || S_c_O_owned!==2 || S_c_O_lease_valid!==2) fail("authority loss hid real acquire");
        // Successful result alone is insufficient when actual acquisition evidence disagrees.
        reset_all; S_result_gate=0;
        start(0,0,0,S_saved_token[0],11); permit(0);
        wait(S_m_O_result_valid);
        @(negedge S_clk); S_status_xor=1; S_result_gate=1;
        result(8,0,1,0);
        if(!S_c_O_quarantined || S_c_O_owned!==1 || S_c_O_lease_valid!=0) fail("success without actual lock accepted");
        // A claimed release must agree with the actual removal of the owner reference.
        reset_all; acquire(0,0); S_result_gate=0;
        start(1,0,0,S_saved_token[0],11); wait(S_c_O_retire_request[0]);
        @(negedge S_clk); S_c_I_retire_ack[0]=1;
        wait(S_m_O_result_valid);
        @(negedge S_clk); S_status_xor=1; S_result_gate=1;
        wait(!S_c_O_retire_request[0]);
        @(negedge S_clk); S_c_I_retire_ack[0]=0;
        result(8,0,0,0);
        if(!S_c_O_quarantined || S_c_O_owned!==1 || S_c_O_start_ready) fail("release success ignored surviving reference");
        // Unexpected actual reference loss is sticky even if the observation recovers.
        reset_all; acquire(0,0);
        @(negedge S_clk); S_status_xor=1;
        repeat(3) @(negedge S_clk);
        if(!S_c_O_quarantined || S_c_O_lease_valid[0] || S_c_O_owned!==1) fail("actual lock loss was hidden");
        S_status_xor=0; repeat(3) @(negedge S_clk);
        if(S_c_O_start_ready || !S_c_O_quarantined || S_c_O_lease_valid!==1) fail("isolated ownership silently reusable");
        // A foreign owner0/1 reference not acquired here is also a protocol fault.
        reset_all;
        @(negedge S_clk); S_status_xor=2;
        repeat(3) @(negedge S_clk);
        if(!S_c_O_quarantined || S_c_O_start_ready || S_c_O_owned!=0) fail("orphan reference not isolated");
        reset_all; acquire(1,5); release_source(1,5);
        S_test_pass=1; $display("PASS: display leases/real slot manager/role rotation/shared stale locks/true retirement"); $finish;
    end
endmodule
