`timescale 1ns/1ps
// Explicit slot and loader protocol peers, independent of the real loader test.
module tb_image_load_owner;
    reg S_clk=0,S_reset=0,S_test_pass=0;
    always #4 S_clk=~S_clk;
    reg S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg S_I_start_valid=0;
    wire S_O_start_ready;
    reg [227:0] S_I_request=0;
    reg S_I_abort=0;
    reg [17:0] S_I_slot_states=0;
    reg [17:0] S_I_slot_layouts=0;
    reg [17:0] S_I_slot_readers=0;
    reg [191:0] S_I_slot_tokens=0;
    reg [191:0] S_I_slot_generations=0;
    reg [191:0] S_I_slot_assets=0;
    reg [11:0] S_I_slot_rotations=0;
    reg [5:0] S_I_slot_resident=0;
    reg [5:0] S_I_slot_stale=0;
    reg [5:0] S_I_pinned_slots=0;
    reg [5:0] S_I_mutating_slots=0;
    reg [137:0] S_I_host_reservation=0;
    wire S_O_evict_valid;
    reg S_I_evict_ready=0;
    wire [114:0] S_O_evict_command;
    reg S_I_evict_result_valid=0;
    wire S_O_evict_result_ready;
    reg [96:0] S_I_evict_result=0;
    wire S_O_loader_start_valid;
    reg S_I_loader_start_ready=0;
    wire [227:0] S_O_loader_request;
    wire [2:0] S_O_loader_slot;
    wire S_O_loader_abort;
    reg S_I_loader_done_valid=0;
    wire S_O_loader_done_ready;
    reg [1:0] S_I_loader_context=0;
    reg [15:0] S_I_loader_tag=0;
    reg [31:0] S_I_loader_generation=0;
    reg [31:0] S_I_loader_token=0;
    reg [2:0] S_I_loader_slot=0;
    reg [3:0] S_I_loader_error=0;
    reg S_I_loader_published=0;
    reg S_I_loader_slot_owned=0;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [2:0] S_O_slot;
    wire [31:0] S_O_token;
    wire [3:0] S_O_error;
    wire [3:0] S_O_loader_error;
    wire [3:0] S_O_slot_error;
    wire S_O_loader_started;
    wire S_O_reused;
    wire S_O_evicted;
    wire S_O_published;
    wire S_O_quarantined;
    wire S_O_response_discarded;
    wire S_O_stage_valid;
    wire [5:0] S_O_staged_slots;
    reg S_I_stage_release_valid=0;
    wire S_O_stage_release_ready;
    reg [2:0] S_I_stage_slot=0;
    reg [31:0] S_I_stage_token=0;
    reg [31:0] S_I_stage_generation=0;
    reg S_I_stage_discard=0;
    image_load_owner u_owner (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .I_request(S_I_request),
        .I_abort(S_I_abort),
        .I_slot_states(S_I_slot_states),
        .I_slot_layouts(S_I_slot_layouts),
        .I_slot_readers(S_I_slot_readers),
        .I_slot_tokens(S_I_slot_tokens),
        .I_slot_generations(S_I_slot_generations),
        .I_slot_assets(S_I_slot_assets),
        .I_slot_rotations(S_I_slot_rotations),
        .I_slot_resident(S_I_slot_resident),
        .I_slot_stale(S_I_slot_stale),
        .I_pinned_slots(S_I_pinned_slots),
        .I_mutating_slots(S_I_mutating_slots),
        .I_host_reservation(S_I_host_reservation),
        .O_evict_valid(S_O_evict_valid),
        .I_evict_ready(S_I_evict_ready),
        .O_evict_command(S_O_evict_command),
        .I_evict_result_valid(S_I_evict_result_valid),
        .O_evict_result_ready(S_O_evict_result_ready),
        .I_evict_result(S_I_evict_result),
        .O_loader_start_valid(S_O_loader_start_valid),
        .I_loader_start_ready(S_I_loader_start_ready),
        .O_loader_request(S_O_loader_request),
        .O_loader_slot(S_O_loader_slot),
        .O_loader_abort(S_O_loader_abort),
        .I_loader_done_valid(S_I_loader_done_valid),
        .O_loader_done_ready(S_O_loader_done_ready),
        .I_loader_context(S_I_loader_context),
        .I_loader_tag(S_I_loader_tag),
        .I_loader_generation(S_I_loader_generation),
        .I_loader_token(S_I_loader_token),
        .I_loader_slot(S_I_loader_slot),
        .I_loader_error(S_I_loader_error),
        .I_loader_published(S_I_loader_published),
        .I_loader_slot_owned(S_I_loader_slot_owned),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_slot(S_O_slot),
        .O_token(S_O_token),
        .O_error(S_O_error),
        .O_loader_error(S_O_loader_error),
        .O_slot_error(S_O_slot_error),
        .O_loader_started(S_O_loader_started),
        .O_reused(S_O_reused),
        .O_evicted(S_O_evicted),
        .O_published(S_O_published),
        .O_quarantined(S_O_quarantined),
        .O_response_discarded(S_O_response_discarded),
        .O_stage_valid(S_O_stage_valid),
        .O_staged_slots(S_O_staged_slots),
        .I_stage_release_valid(S_I_stage_release_valid),
        .O_stage_release_ready(S_O_stage_release_ready),
        .I_stage_slot(S_I_stage_slot),
        .I_stage_token(S_I_stage_token),
        .I_stage_generation(S_I_stage_generation),
        .I_stage_discard(S_I_stage_discard)
    );
    integer S_case=0,S_discarded=0;
    reg [227:0] S_request,S_changed;
    reg [114:0] S_saved_evict;
    task fail;
        input [767:0] message;
        begin $display("FAIL: image_load_owner case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #5000000; fail("watchdog timeout"); end
    always @(posedge S_clk) if(!S_reset && S_O_response_discarded) S_discarded=S_discarded+1;
    task clear;
        begin
            @(negedge S_clk); S_reset=1; S_I_start_valid=0; S_I_abort=0; S_I_done_ready=0;
            S_I_media_valid=1; S_I_media_generation=7;
            S_I_slot_states=0; S_I_slot_layouts=0; S_I_slot_readers=0; S_I_slot_tokens=0;
            S_I_slot_generations=0; S_I_slot_assets=0; S_I_slot_rotations=0;
            S_I_slot_resident=6'b100000; S_I_slot_stale=0; S_I_pinned_slots=0; S_I_mutating_slots=0;
            S_I_host_reservation=0; S_I_evict_ready=0; S_I_evict_result_valid=0;
            S_I_loader_start_ready=0; S_I_loader_done_valid=0; S_I_loader_slot_owned=0;
            S_I_loader_token=0; S_I_stage_release_valid=0; S_I_stage_discard=0;
            S_discarded=0;
            S_request={2'd1,16'h1234,32'd7,32'd53,3'd0,2'd0,16'd11,16'd19,
                16'd3,16'd2,1'b0,32'h040506ff,7'd9,32'd8};
            repeat(4) @(negedge S_clk); S_reset=0; @(negedge S_clk);
        end
    endtask
    task start;
        input [227:0] request;
        begin
            @(negedge S_clk); S_I_request=request; S_I_start_valid=1;
            @(posedge S_clk); while(!S_O_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_I_start_valid=0;
        end
    endtask
    task busy_slots;
        integer j;
        begin for(j=0;j<6;j=j+1) S_I_slot_states[j*3+:3]=1; end
    endtask
    task metadata;
        input [2:0] slot;
        input [2:0] state;
        input [31:0] token;
        begin
            S_I_slot_states[slot*3+:3]=state; S_I_slot_tokens[slot*32+:32]=token;
            S_I_slot_generations[slot*32+:32]=7; S_I_slot_assets[slot*32+:32]=53;
            S_I_slot_layouts[slot*3+:3]=S_request[140:138];
            S_I_slot_rotations[slot*2+:2]=S_request[137:136];
        end
    endtask
    task loader_accept;
        input [2:0] slot;
        begin
            wait(S_O_loader_start_valid); #1;
            if(S_O_loader_slot!==slot || S_O_loader_request!==S_request || S_O_staged_slots!=0)
                fail("selection, frozen request or premature stage");
            repeat(4) begin @(negedge S_clk);
                if(!S_O_loader_start_valid || S_O_loader_slot!==slot || S_O_loader_request!==S_request)
                    fail("loader offer changed while backpressured"); end
            S_I_loader_context=S_request[222:221]; S_I_loader_tag=S_request[220:205];
            S_I_loader_generation=S_request[204:173]; S_I_loader_slot=slot;
            S_I_loader_error=0; S_I_loader_published=0; S_I_loader_start_ready=1;
            @(negedge S_clk); S_I_loader_start_ready=0;
        end
    endtask
    task terminal;
        input [31:0] token;
        input [3:0] error;
        input published,owned;
        begin
            @(negedge S_clk); S_I_loader_token=token; S_I_loader_error=error;
            S_I_loader_published=published; S_I_loader_slot_owned=owned; S_I_loader_done_valid=1;
        end
    endtask
    task take;
        input [3:0] error;
        input stage;
        reg [96:0] held;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_stage_valid!==stage) fail("terminal error or stage");
            held={S_O_context,S_O_tag,S_O_generation,S_O_slot,S_O_token,S_O_error,
                S_O_loader_error,S_O_slot_error};
            repeat(5) begin @(negedge S_clk);
                if(!S_O_done_valid || S_O_loader_done_ready || held!=={S_O_context,S_O_tag,
                    S_O_generation,S_O_slot,S_O_token,S_O_error,S_O_loader_error,S_O_slot_error})
                    fail("result identity/diagnostics changed under backpressure"); end
            S_I_done_ready=1; #1;
            if(S_O_loader_started && !S_O_loader_done_ready) fail("real loader terminal was not consumed with external result");
            @(negedge S_clk); S_I_done_ready=0; S_I_loader_done_valid=0;
            if(stage && (!S_O_stage_valid || S_O_start_ready)) fail("result consumption prematurely released stage");
        end
    endtask
    task release_stage;
        input discard;
        begin
            @(negedge S_clk); S_I_stage_slot=S_O_slot; S_I_stage_token=S_O_token;
            S_I_stage_generation=S_O_generation; S_I_stage_discard=discard; S_I_stage_release_valid=1;
            @(posedge S_clk); while(!S_O_stage_release_ready) @(posedge S_clk);
            @(negedge S_clk); S_I_stage_release_valid=0;
            if(S_O_stage_valid || !S_O_start_ready) fail("explicit stage release failed");
        end
    endtask
    task evict_accept;
        input [2:0] slot;
        input [31:0] token;
        begin
            wait(S_O_evict_valid); #1; S_saved_evict=S_O_evict_command;
            if(S_saved_evict[114:112]!=4 || S_saved_evict[111:109]!=slot ||
                S_saved_evict[108:107]!=2 || S_saved_evict[106:75]!=token ||
                S_saved_evict[74:43]!=7 || S_O_loader_start_valid) fail("EVICT command identity/order");
            repeat(5) begin @(negedge S_clk);
                if(!S_O_evict_valid || S_O_evict_command!==S_saved_evict) fail("EVICT offer changed"); end
            S_I_evict_ready=1; @(negedge S_clk); S_I_evict_ready=0;
        end
    endtask
    task evict_return;
        input [3:0] error;
        begin
            @(negedge S_clk); S_I_evict_result={error,S_saved_evict[114:107],S_saved_evict[106:75],S_saved_evict[74:43],21'd0};
            S_I_evict_result_valid=1;
            @(posedge S_clk); while(!S_O_evict_result_ready) @(posedge S_clk);
            @(negedge S_clk); S_I_evict_result_valid=0;
        end
    endtask
    initial begin
        S_case=1; clear; start(S_request); S_I_request=0; loader_accept(0);
        @(negedge S_clk); metadata(0,2,32'd91); terminal(91,0,1,0); #1;
        if(S_O_staged_slots!=1 || S_O_loader_done_ready) fail("published lookahead gap before stage register");
        take(0,1);
        S_I_stage_slot=0; S_I_stage_token=90; S_I_stage_generation=7; S_I_stage_discard=1;
        S_I_stage_release_valid=1; repeat(3) @(negedge S_clk);
        if(S_O_stage_release_ready || !S_O_stage_valid) fail("wrong stage token released candidate");
        S_I_stage_token=91; S_I_stage_discard=0;
        S_I_host_reservation={2'b01,3'd0,3'd0,32'd0,32'd90,32'd0,32'd7,2'b00};
        repeat(3) @(negedge S_clk);
        if(S_O_stage_release_ready) fail("wrong installed pin identity accepted as handoff");
        S_I_stage_release_valid=0;
        S_I_host_reservation[97:66]=91; release_stage(0);

        S_case=2; S_I_slot_readers[2:0]=1; S_I_slot_states[2:0]=3; S_I_pinned_slots=1;
        start(S_request); take(0,1);
        if(!S_O_reused || S_O_loader_started || S_O_token!=91) fail("exact cache hit did not reuse READ_LOCK safely");
        release_stage(0);

        S_case=3; S_changed=S_request; S_changed[135:120]=12; S_request=S_changed;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        if(S_O_loader_error!=2 || S_O_reused) fail("geometry change reused stale complete image");

        S_case=4; clear; busy_slots; metadata(1,0,0); metadata(2,4,40); metadata(3,0,0);
        S_I_pinned_slots=2; S_I_mutating_slots=8; start(S_request); loader_accept(2);
        terminal(0,2,0,0); take(4,0);

        S_case=5; clear; busy_slots; metadata(0,2,10); S_I_pinned_slots=1;
        metadata(1,3,11); S_I_slot_readers[5:3]=1; metadata(2,2,12); S_I_slot_resident[2]=1;
        metadata(3,2,13); S_I_mutating_slots[3]=1; metadata(4,2,14);
        start(S_request); evict_accept(4,14);
        repeat(6) begin @(negedge S_clk); if(S_O_loader_start_valid) fail("EVICT acceptance used as retirement"); end
        S_I_slot_states[14:12]=0; evict_return(0); loader_accept(4);
        terminal(0,2,0,0); take(4,0); if(!S_O_evicted) fail("real successful EVICT fact lost");

        S_case=6; clear; busy_slots; metadata(5,0,0); start(S_request);
        repeat(30) begin @(negedge S_clk);
            if(S_O_evict_valid || S_O_loader_start_valid || S_O_done_valid) fail("all-busy used slot5 or fabricated completion"); end
        S_I_abort=1; take(3,0);

        S_case=7; clear; busy_slots; metadata(0,2,51); start(S_request); wait(S_O_evict_valid);
        @(negedge S_clk); S_I_abort=1; evict_accept(0,51);
        S_I_slot_states[2:0]=0; evict_return(0); take(3,0);
        if(S_O_loader_started) fail("cancelled EVICT started a file");

        S_case=8; clear; start(S_request); wait(S_O_loader_start_valid);
        @(negedge S_clk); S_I_abort=1;
        loader_accept(0); if(!S_O_loader_abort) fail("held start cancellation not delivered to loader");
        terminal(0,7,0,0); take(3,0);

        S_case=9; clear; start(S_request); loader_accept(0);
        terminal(0,2,0,0); S_I_loader_tag=16'h9999;
        repeat(5) @(negedge S_clk);
        if(S_O_done_valid || S_discarded==0) fail("foreign loader terminal cleared correct debt");
        S_I_loader_tag=16'h1234; take(4,0);

        S_case=10; clear; busy_slots; metadata(0,2,61); start(S_request); evict_accept(0,61);
        @(negedge S_clk); S_I_evict_result={4'd0,3'd4,3'd0,2'd2,32'd60,32'd7,21'd0}; S_I_evict_result_valid=1;
        repeat(4) @(negedge S_clk); S_I_evict_result_valid=0;
        if(S_discarded==0 || S_O_loader_start_valid || S_O_done_valid) fail("foreign EVICT token cleared debt");
        evict_return(2); take(2,0); if(S_O_slot_error!=2) fail("real slot error lost");

        S_case=11; clear; start(S_request); loader_accept(0);
        terminal(71,0,0,0); take(8,1);
        if(!S_O_quarantined || S_O_start_ready) fail("unpublished success escaped isolation");

        S_case=12; clear; start(S_request); loader_accept(0);
        terminal(72,8,0,1); take(8,1);
        if(!S_O_quarantined || S_O_start_ready) fail("unknown owned slot escaped isolation");

        S_case=13; clear; start(S_request); loader_accept(0);
        @(negedge S_clk); S_I_loader_token=81; S_I_loader_slot_owned=1;
        repeat(3) @(negedge S_clk); metadata(0,2,82); terminal(82,0,1,0); take(8,1);
        if(!S_O_quarantined) fail("allocation token changed across actual loader transaction");

        S_case=14; clear; start(S_request); loader_accept(0);
        @(negedge S_clk); metadata(0,2,91); terminal(91,0,1,0); take(0,1);
        @(negedge S_clk); S_I_media_valid=0; S_I_slot_states[2:0]=0;
        repeat(8) @(negedge S_clk);
        if(!S_O_stage_valid || S_O_start_ready) fail("media fault silently dropped staged identity");
        release_stage(1);

        S_case=15; clear; S_changed=S_request; S_changed[135:120]=65535;
        start(S_changed); take(1,0); if(S_O_loader_started || S_O_evicted) fail("invalid rectangle performed IO");

        S_case=16; clear; start(S_request); loader_accept(0);
        @(negedge S_clk); S_I_media_valid=0;
        repeat(4) @(negedge S_clk); if(!S_O_loader_abort || S_O_done_valid) fail("media failure did not await real loader drain");
        S_I_media_valid=1; terminal(0,6,0,0); take(5,0);

        S_case=17; clear; start(S_request); loader_accept(0);
        @(negedge S_clk); metadata(0,2,101); terminal(101,0,1,0); take(0,1); release_stage(1);
        // Equal metadata but a new real allocation token must never hit the cache.
        @(negedge S_clk); metadata(0,2,102); start(S_request); loader_accept(1);
        terminal(0,2,0,0); take(4,0); if(S_O_reused) fail("external reload inherited geometry proof");

        S_case=18; clear; start(S_request); loader_accept(0);
        @(negedge S_clk); metadata(0,2,111); terminal(111,0,1,0); wait(S_O_done_valid);
        @(negedge S_clk); S_I_abort=1; take(0,1);
        if(!S_O_published || S_O_error!=0) fail("late abort rewrote published terminal");
        release_stage(1);

        S_case=19; clear; start(S_request); loader_accept(0);
        @(negedge S_clk); metadata(0,2,121); terminal(121,0,1,0); take(0,1); release_stage(1);
        S_changed=S_request;
        // Independently change each pixel key field; failed loads must not replace
        // the successful cached image. These are explicit requests, no DUT model.
        S_request=S_changed; S_request[71]=1;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        S_request=S_changed; S_request[70:39]=32'h112233ff;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        S_request=S_changed; S_request[137:136]=1;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        S_request=S_changed; S_request[119:104]=20;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        S_request=S_changed; S_request[103:88]=4;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        S_request=S_changed; S_request[87:72]=3;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);
        S_request=S_changed; S_request[140:138]=1;
        start(S_request); loader_accept(1); terminal(0,2,0,0); take(4,0);

        $display("PASS: 19 explicit slot/loader protocol scenarios; no real file, writer or CDC in this test");
        S_test_pass=1; $finish;
    end
endmodule
