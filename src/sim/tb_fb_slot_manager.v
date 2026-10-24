`timescale 1ns/1ps
module tb_fb_slot_manager;
    reg S_clk=0,S_reset=0,S_media_valid=1;
    reg [31:0] S_media_generation=11;
    reg S_cmd_valid=0,S_result_ready=0;
    reg [2:0] S_op=0,S_slot=0,S_layout=0;
    reg [1:0] S_owner=0,S_rotation=0;
    reg [31:0] S_token=0,S_generation=11,S_asset=0;
    reg S_resident=0,S_success=1,S_producer_retired=1,S_memory_retired=1,S_reader_retired=1,S_boundary=1;
    wire S_ready,S_result,S_exhausted,S_exhaustion_done;
    wire [3:0] S_error;
    wire [2:0] S_result_op,S_result_slot;
    wire [1:0] S_result_owner;
    wire [31:0] S_result_token,S_result_generation;
    wire [20:0] S_base;
    wire [17:0] S_states,S_layouts,S_readers;
    wire [191:0] S_tokens,S_generations,S_assets;
    wire [11:0] S_rotations;
    wire [5:0] S_residents,S_stale,S_cancel;
    reg [31:0] S_saved_token[0:5];
    integer S_case=0,S_i,S_expected_error,S_request_op,S_request_slot,S_request_owner;
    reg [31:0] S_request_token,S_request_generation,S_old_token;
    reg [96:0] S_saved_result;
    reg S_test_pass=0;
    always #4 S_clk=~S_clk;
    fb_slot_manager u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(S_media_valid),.I_media_generation(S_media_generation),
        .I_cmd_valid(S_cmd_valid),.O_cmd_ready(S_ready),.I_cmd_op(S_op),.I_cmd_slot(S_slot),.I_cmd_owner(S_owner),
        .I_cmd_token(S_token),.I_cmd_generation(S_generation),.I_cmd_asset(S_asset),.I_cmd_layout(S_layout),
        .I_cmd_rotation(S_rotation),.I_cmd_resident(S_resident),.I_cmd_success(S_success),
        .I_producer_retired(S_producer_retired),.I_memory_retired(S_memory_retired),
        .I_reader_retired(S_reader_retired),.I_frame_boundary(S_boundary),
        .O_result_valid(S_result),.I_result_ready(S_result_ready),.O_result_error(S_error),
        .O_result_op(S_result_op),.O_result_slot(S_result_slot),.O_result_owner(S_result_owner),
        .O_result_token(S_result_token),.O_result_generation(S_result_generation),.O_result_base(S_base),
        .O_slot_states(S_states),.O_slot_tokens(S_tokens),.O_slot_generations(S_generations),.O_slot_assets(S_assets),
        .O_slot_layouts(S_layouts),.O_slot_readers(S_readers),.O_slot_rotations(S_rotations),
        .O_slot_resident(S_residents),.O_slot_stale(S_stale),.O_cancel_loading(S_cancel),.O_token_exhausted(S_exhausted)
    );
    fb_slot_exhaustion_case u_exhaustion(S_exhaustion_done);
    task fail;
        input [511:0] message;
        begin $display("FAIL fb_slot_manager command=%0d op=%0d slot=%0d: %0s",S_case,S_request_op,S_request_slot,message); $stop; end
    endtask
    task slot_state;
        input integer slot,state,readers,stale,resident;
        begin
            if (S_states[slot*3 +: 3]!==state[2:0] || S_readers[slot*3 +: 3]!==readers[2:0] ||
                S_stale[slot]!==stale[0] || S_residents[slot]!==resident[0]) begin
                $display("slot%0d state=%0d readers=%b stale=%b resident=%b",slot,
                    S_states[slot*3 +: 3],S_readers[slot*3 +: 3],S_stale[slot],S_residents[slot]);
                fail("slot state/read references/invalidation");
            end
        end
    endtask
    task request;
        input integer op,slot,owner;
        input [31:0] token,generation;
        begin
            @(negedge S_clk);
            if (S_result) fail("previous result not consumed");
            S_case=S_case+1; S_request_op=op; S_request_slot=slot; S_request_owner=owner;
            S_request_token=token; S_request_generation=generation;
            S_op=op; S_slot=slot; S_owner=owner; S_token=token; S_generation=generation;
            S_cmd_valid=1;
        end
    endtask
    task blocked;
        input integer cycles;
        begin
            repeat (cycles) begin
                @(posedge S_clk); #1;
                if (S_ready || S_result) fail("retirement or frame boundary bypassed");
            end
            @(negedge S_clk);
        end
    endtask
    task accept;
        input integer error;
        reg [20:0] expected_base;
        begin
            @(posedge S_clk);
            if (!S_ready) fail("unexpected command backpressure");
            @(negedge S_clk); S_cmd_valid=0;
            expected_base=S_request_slot<6 ? S_request_slot*307200 : 0;
            if (!S_result || S_error!==error[3:0] || S_result_op!==S_request_op[2:0] ||
                S_result_slot!==S_request_slot[2:0] || S_result_owner!==S_request_owner[1:0] ||
                S_result_generation!==S_request_generation || S_base!==expected_base)
                fail("result identity/base/error");
            if (S_request_op==0 && error==0) begin
                if (S_result_token==0 || !(S_result_token>S_old_token)) fail("nonmonotonic lease token");
                S_saved_token[S_request_slot]=S_result_token; S_old_token=S_result_token;
            end else if (S_result_token!==S_request_token) fail("result token not preserved");
            S_saved_result={S_error,S_result_op,S_result_slot,S_result_owner,S_result_token,S_result_generation,S_base};
        end
    endtask
    task consume;
        begin
            // Mutate unrelated commands while the result is stalled: no new request.
            S_op=7; S_slot=7; S_owner=3; S_token=32'hdeadbeef; S_generation=32'hffffffff;
            S_cmd_valid=1;
            repeat (5) begin
                @(posedge S_clk); #1;
                if (!S_result || S_ready ||
                    {S_error,S_result_op,S_result_slot,S_result_owner,S_result_token,S_result_generation,S_base}!==S_saved_result)
                    fail("result not held or accepted extra command");
            end
            @(negedge S_clk); S_cmd_valid=0; S_result_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_result_ready=0;
            if (S_result) fail("result did not retire");
        end
    endtask
    task command;
        input integer op,slot,owner;
        input [31:0] token,generation;
        input integer error;
        begin request(op,slot,owner,token,generation); accept(error); consume; end
    endtask
    task allocate;
        input integer slot;
        input [31:0] generation;
        begin
            S_asset=32'h10203040+slot; S_layout=slot%5; S_rotation=slot%4;
            command(0,slot,0,0,generation,0);
            if (S_assets[slot*32 +: 32]!==32'h10203040+slot || S_layouts[slot*3 +: 3]!==slot%5 ||
                S_rotations[slot*2 +: 2]!==slot%4 || S_generations[slot*32 +: 32]!==generation)
                fail("allocation metadata snapshot");
        end
    endtask
    initial begin
        S_old_token=0;
        for (S_i=0;S_i<6;S_i=S_i+1) S_saved_token[S_i]=0;
        S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        if (S_states!==18'd0 || S_readers!==18'd0 || S_cancel!==6'd0 || S_exhausted) fail("reset state");
        allocate(0,11); slot_state(0,1,0,0,0);
        command(2,0,0,S_saved_token[0],11,2);
        command(4,0,0,S_saved_token[0],11,2);
        S_producer_retired=0; S_memory_retired=0;
        command(1,0,0,S_saved_token[0]+1,11,3); // Invalid identity cannot hang on retirement inputs.
        request(1,0,0,S_saved_token[0],11); blocked(8); slot_state(0,1,0,0,0);
        S_producer_retired=1; blocked(5); S_producer_retired=0; S_memory_retired=1; blocked(5);
        S_producer_retired=1; accept(0); consume; slot_state(0,2,0,0,0);
        S_boundary=0; request(2,0,0,S_saved_token[0],11); blocked(7);
        S_boundary=1; accept(0); consume; slot_state(0,3,1,0,0);
        command(2,0,1,S_saved_token[0],11,0); slot_state(0,3,3,0,0);
        S_boundary=0; command(2,0,2,S_saved_token[0],11,0); slot_state(0,3,7,0,0);
        command(0,0,0,0,11,2);
        command(4,0,0,S_saved_token[0],11,2);
        allocate(1,11); command(1,1,0,S_saved_token[1],11,0);
        S_boundary=1; command(2,1,0,S_saved_token[1],11,2); // Owner already holds slot0.
        command(3,0,0,S_saved_token[0],12,3);
        S_reader_retired=0; request(3,0,0,S_saved_token[0],11); blocked(9); slot_state(0,3,7,0,0);
        S_reader_retired=1; accept(0); consume; slot_state(0,3,6,0,0);
        command(2,1,0,S_saved_token[1],11,0); slot_state(1,3,1,0,0);
        command(3,0,1,S_saved_token[0],11,0); slot_state(0,3,4,0,0);
        command(3,0,2,S_saved_token[0],11,0); slot_state(0,2,0,0,0);
        // A published result stays frozen even if its freshly READY slot invalidates.
        allocate(2,11); request(1,2,0,S_saved_token[2],11); accept(0);
        @(negedge S_clk); S_media_valid=0;
        @(posedge S_clk); @(negedge S_clk); S_media_valid=1;
        slot_state(0,0,0,1,0); slot_state(1,3,1,1,0); slot_state(2,0,0,1,0);
        consume;
        command(2,1,1,S_saved_token[1],11,4); // Cannot add a reader to the frozen old foreground.
        command(3,1,0,S_saved_token[1],11,0); slot_state(1,0,0,1,0);
        // Short media failure while loading remains sticky even after valid returns.
        allocate(3,11);
        @(negedge S_clk); S_media_valid=0; #1;
        if (!S_cancel[3]) fail("cancel not immediate");
        @(posedge S_clk); @(negedge S_clk); S_media_valid=1;
        slot_state(3,1,0,1,0);
        S_memory_retired=0; request(1,3,0,S_saved_token[3],11); blocked(7);
        if (!S_cancel[3]) fail("cancel lost while real writes outstanding");
        S_memory_retired=1; accept(4); consume; slot_state(3,0,0,1,0);
        if (S_cancel[3]) fail("cancel survived retirement");
        // Generation replacement, old identities, failed load retry and explicit eviction.
        S_media_generation=12;
        command(0,0,0,0,11,4);
        allocate(0,12);
        command(1,0,0,1,11,3); slot_state(0,1,0,0,0);
        S_success=0; command(1,0,0,S_saved_token[0],12,6); slot_state(0,4,0,0,0);
        S_success=1; allocate(0,12); command(1,0,0,S_saved_token[0],12,0);
        command(0,0,0,0,12,2); command(4,0,0,S_saved_token[0],12,0); slot_state(0,0,0,0,0);
        allocate(4,12); command(1,4,0,S_saved_token[4],12,0);
        @(negedge S_clk); S_media_generation=13;
        @(posedge S_clk); @(negedge S_clk); slot_state(4,0,0,1,0);
        // Resident safe frame is still subject to writer/reader exclusivity.
        S_resident=1; allocate(5,32'hfeed1234);
        S_media_valid=0; repeat (3) @(negedge S_clk); slot_state(5,1,0,0,1);
        if (S_cancel[5]) fail("resident loading canceled by TF invalidation");
        command(1,5,0,S_saved_token[5],32'hfeed1234,0); slot_state(5,2,0,0,1);
        command(2,5,0,S_saved_token[5],32'hfeed1234,0); slot_state(5,3,1,0,1);
        command(0,5,0,0,32'hfeed1234,2);
        command(3,5,0,S_saved_token[5],32'hfeed1234,0);
        command(4,5,0,S_saved_token[5],32'hfeed1234,0);
        command(0,4,0,0,13,1); // Persistent metadata belongs only to slot5.
        S_resident=0; command(0,5,0,0,13,4);
        S_media_valid=1; S_media_generation=13;
        // Losing the medium exactly at FINISH must not transiently publish READY.
        allocate(2,13); request(1,2,0,S_saved_token[2],13);
        S_media_valid=0; accept(4); consume; slot_state(2,0,0,1,0);
        S_media_valid=1;
        // Invalid op, slot, owner and layout cannot mutate state or wait forever.
        command(7,0,0,0,13,1); command(0,6,0,0,13,1); command(0,7,3,0,13,1);
        command(0,0,3,0,13,1); S_layout=5; command(0,0,0,0,13,1); S_layout=0;
        command(3,0,0,S_saved_token[0],12,2);
        // Global reset cancels held result and all leases; no local reset exists.
        allocate(0,13); request(1,0,0,S_saved_token[0],13); accept(0);
        @(negedge S_clk); S_reset=1;
        repeat (3) @(negedge S_clk); S_reset=0;
        if (S_result || S_states!==18'd0 || S_tokens!==192'd0 || S_readers!==18'd0 || S_exhausted) fail("global reset");
        wait (S_exhaustion_done);
        S_test_pass=1;
        $display("PASS: frame leases, bases/metadata, three reader owners, actual retirement gates, sticky invalidation and resident safety");
        $finish;
    end
    initial begin #10000000; fail("timeout"); end
endmodule

// Small lease space proves saturation without forcing internal DUT registers.
module fb_slot_exhaustion_case(output reg O_done);
    reg S_clk=0,S_reset=0,S_valid=0,S_result_ready=0;
    reg [2:0] S_op=0;
    reg [31:0] S_token=0;
    wire S_ready,S_result,S_exhausted;
    wire [3:0] S_error;
    wire [31:0] S_result_token;
    integer S_i;
    always #5 S_clk=~S_clk;
    fb_slot_manager #(.TOKEN_BITS(2)) u_small (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(1'b1),.I_media_generation(32'd1),
        .I_cmd_valid(S_valid),.O_cmd_ready(S_ready),.I_cmd_op(S_op),.I_cmd_slot(3'd0),.I_cmd_owner(2'd0),
        .I_cmd_token(S_token),.I_cmd_generation(32'd1),.I_cmd_asset(32'd0),.I_cmd_layout(3'd0),
        .I_cmd_rotation(2'd0),.I_cmd_resident(1'b0),.I_cmd_success(1'b1),
        .I_producer_retired(1'b1),.I_memory_retired(1'b1),.I_reader_retired(1'b1),.I_frame_boundary(1'b1),
        .O_result_valid(S_result),.I_result_ready(S_result_ready),.O_result_error(S_error),
        .O_result_op(),.O_result_slot(),.O_result_owner(),.O_result_token(S_result_token),.O_result_generation(),.O_result_base(),
        .O_slot_states(),.O_slot_tokens(),.O_slot_generations(),.O_slot_assets(),.O_slot_layouts(),.O_slot_readers(),
        .O_slot_rotations(),.O_slot_resident(),.O_slot_stale(),.O_cancel_loading(),.O_token_exhausted(S_exhausted)
    );
    task cmd;
        input integer op,error;
        begin
            @(negedge S_clk); S_op=op; S_valid=1;
            @(posedge S_clk); if (!S_ready) begin $display("FAIL small lease ready"); $stop; end
            @(negedge S_clk); S_valid=0;
            if (!S_result || S_error!==error[3:0]) begin $display("FAIL small lease result %0d",S_error); $stop; end
            if (op==0 && error==0) begin
                if (S_result_token!==S_i[31:0]) begin $display("FAIL token sequence/wrap"); $stop; end
                S_token=S_result_token;
            end
            S_result_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_result_ready=0;
        end
    endtask
    initial begin
        O_done=0; S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        for (S_i=1;S_i<=3;S_i=S_i+1) begin cmd(0,0); cmd(1,0); cmd(4,0); end
        if (!S_exhausted) begin $display("FAIL lease exhaustion not sticky"); $stop; end
        repeat (4) cmd(0,7);
        @(negedge S_clk); S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        S_i=1; cmd(0,0);
        if (S_exhausted) begin $display("FAIL lease reset"); $stop; end
        O_done=1;
    end
endmodule
