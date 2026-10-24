`timescale 1ns/1ps
// Actual pins CDC, arbiter and slot manager; explicit producer/reader promises.
module tb_image_reservation_cdc;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_reset=0,S_test_pass=0;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    wire S_host_reset;
    reset_sync u_reset (.I_clk(S_host_clk),.I_async_reset(S_reset),.O_reset(S_host_reset));
    reg S_media_valid=1,S_cmd_gate=1,S_inject_result=0;
    reg [31:0] S_generation=7;
    reg [96:0] S_bad_result=0;
    wire [96:0] S_manager_result;
    reg  S_p_I_video_enable=0;
    reg  S_p_I_update_valid=0;
    wire  S_p_O_update_ready;
    reg [31:0] S_p_I_epoch=0;
    reg [15:0] S_p_I_tag=0;
    reg [137:0] S_p_I_reservation=0;
    wire  S_p_O_done_valid;
    reg  S_p_I_done_ready=0;
    wire [31:0] S_p_O_epoch;
    wire [15:0] S_p_O_tag;
    wire [3:0] S_p_O_error;
    wire [137:0] S_p_O_images;
    wire [137:0] S_p_O_video_reservation;
    wire [31:0] S_p_O_video_epoch;
    wire [15:0] S_p_O_video_tag;
    wire  S_p_O_video_busy;
    wire  S_p_O_video_quarantined;
    wire  S_p_O_video_response_discarded;
    wire [137:0] S_p_O_host_reservation;
    wire [5:0] S_p_O_host_pinned_slots;
    wire  S_p_O_host_busy;
    wire  S_p_O_host_quarantined;
    reg [2:0] S_a_I_client_valid=0;
    wire [2:0] S_a_O_client_ready;
    reg [344:0] S_a_I_client_command=0;
    wire [2:0] S_a_O_client_result_valid;
    reg [2:0] S_a_I_client_result_ready=0;
    wire [96:0] S_a_O_client_result;
    wire  S_a_O_cmd_valid;
    wire [114:0] S_a_O_cmd;
    wire  S_a_O_result_ready;
    wire [5:0] S_a_O_mutating_slots;
    wire  S_a_O_busy;
    wire  S_a_O_contract_fault;
    wire  S_a_O_response_discarded;
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
    image_reservation_cdc u_pins (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_reset),
        .I_video_enable(S_p_I_video_enable),
        .I_update_valid(S_p_I_update_valid),
        .O_update_ready(S_p_O_update_ready),
        .I_epoch(S_p_I_epoch),
        .I_tag(S_p_I_tag),
        .I_reservation(S_p_I_reservation),
        .O_done_valid(S_p_O_done_valid),
        .I_done_ready(S_p_I_done_ready),
        .O_epoch(S_p_O_epoch),
        .O_tag(S_p_O_tag),
        .O_error(S_p_O_error),
        .O_images(S_p_O_images),
        .O_video_reservation(S_p_O_video_reservation),
        .O_video_epoch(S_p_O_video_epoch),
        .O_video_tag(S_p_O_video_tag),
        .O_video_busy(S_p_O_video_busy),
        .O_video_quarantined(S_p_O_video_quarantined),
        .O_video_response_discarded(S_p_O_video_response_discarded),
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_slot_states(S_m_O_slot_states),
        .I_slot_tokens(S_m_O_slot_tokens),
        .I_slot_generations(S_m_O_slot_generations),
        .I_slot_resident(S_m_O_slot_resident),
        .I_slot_stale(S_m_O_slot_stale),
        .I_mutating_slots(S_a_O_mutating_slots),
        .O_host_reservation(S_p_O_host_reservation),
        .O_host_pinned_slots(S_p_O_host_pinned_slots),
        .O_host_busy(S_p_O_host_busy),
        .O_host_quarantined(S_p_O_host_quarantined)
    );
    fb_slot_arbiter u_arbiter (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_pinned_slots(S_p_O_host_pinned_slots),
        .I_client_valid(S_a_I_client_valid),
        .O_client_ready(S_a_O_client_ready),
        .I_client_command(S_a_I_client_command),
        .O_client_result_valid(S_a_O_client_result_valid),
        .I_client_result_ready(S_a_I_client_result_ready),
        .O_client_result(S_a_O_client_result),
        .O_cmd_valid(S_a_O_cmd_valid),
        .I_cmd_ready(S_m_O_cmd_ready && S_cmd_gate),
        .O_cmd(S_a_O_cmd),
        .I_result_valid(S_inject_result || S_m_O_result_valid),
        .O_result_ready(S_a_O_result_ready),
        .I_result(S_inject_result ? S_bad_result : S_manager_result),
        .O_mutating_slots(S_a_O_mutating_slots),
        .O_busy(S_a_O_busy),
        .O_contract_fault(S_a_O_contract_fault),
        .O_response_discarded(S_a_O_response_discarded)
    );
    fb_slot_manager u_slots (
        .I_clk(S_host_clk),
        .I_reset(S_host_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_cmd_valid(S_a_O_cmd_valid && S_cmd_gate),
        .O_cmd_ready(S_m_O_cmd_ready),
        .I_cmd_op(S_a_O_cmd[114:112]),
        .I_cmd_slot(S_a_O_cmd[111:109]),
        .I_cmd_owner(S_a_O_cmd[108:107]),
        .I_cmd_token(S_a_O_cmd[106:75]),
        .I_cmd_generation(S_a_O_cmd[74:43]),
        .I_cmd_asset(S_a_O_cmd[42:11]),
        .I_cmd_layout(S_a_O_cmd[10:8]),
        .I_cmd_rotation(S_a_O_cmd[7:6]),
        .I_cmd_resident(S_a_O_cmd[5]),
        .I_cmd_success(S_a_O_cmd[4]),
        .I_producer_retired(S_a_O_cmd[3]),
        .I_memory_retired(S_a_O_cmd[2]),
        .I_reader_retired(S_a_O_cmd[1]),
        .I_frame_boundary(S_a_O_cmd[0]),
        .O_result_valid(S_m_O_result_valid),
        .I_result_ready(S_a_O_result_ready && !S_inject_result),
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
    assign S_manager_result={S_m_O_result_error,S_m_O_result_op,S_m_O_result_slot,S_m_O_result_owner,
        S_m_O_result_token,S_m_O_result_generation,S_m_O_result_base};
    integer S_case=0,S_manager_commands=0,S_discarded=0;
    reg [31:0] S_tokens[0:5];
    reg [137:0] S_pair=0;
    integer S_i;
    task fail;
        input [767:0] message;
        begin $display("FAIL: image reservation case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #200000000; fail("watchdog timeout"); end
    always @(posedge S_host_clk) begin
        if(S_host_reset) S_manager_commands=0;
        else if(S_a_O_cmd_valid && S_m_O_cmd_ready && S_cmd_gate) begin
            S_manager_commands=S_manager_commands+1;
            if((S_a_O_cmd[114:112]==0 || S_a_O_cmd[114:112]==4) && S_a_O_cmd[111:109]<6 &&
                S_p_O_host_pinned_slots[S_a_O_cmd[111:109]]) fail("real mutation escaped image pin protection");
        end
    end
    always @(posedge S_video_clk) if(!S_reset && S_p_O_video_response_discarded) S_discarded=S_discarded+1;
    function [114:0] command;
        input [2:0] op,slot;
        input [1:0] owner;
        input [31:0] token,generation;
        input resident;
        begin command={op,slot,owner,token,generation,32'd53,3'd0,2'd0,resident,1'b1,4'b1111}; end
    endfunction
    function [137:0] reservation;
        input [1:0] hold;
        input [2:0] a,b;
        begin reservation={hold,b,a,S_tokens[b],S_tokens[a],32'd7,32'd7,2'b00}; end
    endfunction
    task offer;
        input integer client;
        input [114:0] payload;
        begin
            @(negedge S_host_clk); S_a_I_client_command[client*115+:115]=payload; S_a_I_client_valid[client]=1;
            @(posedge S_host_clk); while(!S_a_O_client_ready[client]) @(posedge S_host_clk);
            @(negedge S_host_clk); S_a_I_client_valid[client]=0;
        end
    endtask
    task take;
        input integer client;
        input [3:0] error;
        reg [96:0] held;
        begin
            wait(S_a_O_client_result_valid[client]); #1; held=S_a_O_client_result;
            if(held[96:93]!==error || S_a_O_client_result_valid!==(3'b001<<client)) fail("slot result error or client routing");
            if(held[92:90]==0 && error==0) S_tokens[held[89:87]]=held[84:53];
            repeat(4) begin @(negedge S_host_clk);
                if(!S_a_O_client_result_valid[client] || S_a_O_client_result!==held) fail("slot terminal changed under client backpressure"); end
            S_a_I_client_result_ready[client]=1; @(negedge S_host_clk); S_a_I_client_result_ready[client]=0;
        end
    endtask
    task slot_cmd;
        input integer client;
        input [2:0] op,slot;
        input [1:0] owner;
        input [3:0] error;
        begin offer(client,command(op,slot,owner,op==0 ? 0 : S_tokens[slot],7,0)); take(client,error); end
    endtask
    task load;
        input [2:0] slot;
        begin slot_cmd(0,0,slot,2,0); slot_cmd(0,1,slot,2,0); end
    endtask
    task update;
        input [31:0] epoch;
        input [137:0] desired;
        begin
            @(negedge S_video_clk); S_p_I_epoch=epoch; S_p_I_tag=16'ha000+epoch[15:0];
            S_p_I_reservation=desired; S_p_I_update_valid=1;
            @(posedge S_video_clk); while(!S_p_O_update_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_p_I_update_valid=0;
        end
    endtask
    task done;
        input [3:0] error;
        input [1:0] available;
        reg [51:0] held;
        begin
            wait(S_p_O_done_valid); #1;
            if(S_p_O_error!==error || S_p_O_images[137:136]!==available) fail("pin acknowledgment or reliable availability mismatch");
            held={S_p_O_epoch,S_p_O_tag,S_p_O_error};
            repeat(6) begin @(negedge S_video_clk);
                if(!S_p_O_done_valid || held!=={S_p_O_epoch,S_p_O_tag,S_p_O_error}) fail("pin result changed under backpressure"); end
            S_p_I_done_ready=1; @(negedge S_video_clk); S_p_I_done_ready=0;
        end
    endtask
    task reset_all;
        begin
            S_host_run=1; S_video_run=1; S_reset=1; S_cmd_gate=1; S_inject_result=0;
            S_media_valid=1; S_generation=7; S_a_I_client_valid=0; S_a_I_client_result_ready=0;
            S_p_I_update_valid=0; S_p_I_done_ready=0; S_p_I_video_enable=1; S_p_I_reservation=0;
            for(S_i=0;S_i<6;S_i=S_i+1) S_tokens[S_i]=0;
            repeat(6) @(negedge S_video_clk); S_reset=0; wait(!S_host_reset && S_p_O_update_ready);
        end
    endtask
    initial begin
        S_case=1; reset_all; load(0); load(1); S_pair=reservation(3,0,1);
        update(1,S_pair); done(0,3);
        if(S_p_O_host_pinned_slots!=3 || S_p_O_images[135:0]!==S_pair[135:0]) fail("initial complete image pin identities");

        S_case=2;
        @(negedge S_host_clk); S_a_I_client_command[115+:115]=command(2,0,0,S_tokens[0],7,0);
        S_a_I_client_command[115]=0; S_a_I_client_valid[1]=1;
        repeat(12) begin @(negedge S_host_clk); if(S_a_O_client_ready[1] || S_m_O_slot_readers[2:0]!=0) fail("acquire invented frame permission"); end
        S_a_I_client_command[115]=1;
        @(posedge S_host_clk); while(!S_a_O_client_ready[1]) @(posedge S_host_clk);
        @(negedge S_host_clk); S_a_I_client_valid[1]=0; take(1,0);
        repeat(16) begin @(negedge S_video_clk); if(S_p_O_images[137:136]!=3) fail("READ_LOCK naturally revoked complete image availability"); end
        @(negedge S_host_clk); S_a_I_client_command[115+:115]=command(3,0,0,S_tokens[0],7,0);
        S_a_I_client_command[116]=0; S_a_I_client_valid[1]=1;
        repeat(12) begin @(negedge S_host_clk); if(S_a_O_client_ready[1]) fail("release invented reader retirement"); end
        S_a_I_client_command[116]=1;
        @(posedge S_host_clk); while(!S_a_O_client_ready[1]) @(posedge S_host_clk);
        @(negedge S_host_clk); S_a_I_client_valid[1]=0; take(1,0);

        S_case=3; S_i=S_manager_commands;
        slot_cmd(2,4,0,2,2); slot_cmd(0,0,0,2,2);
        if(S_manager_commands!=S_i || S_p_O_images[137:136]!=3) fail("rejected mutation changed pinned slot or its proof");

        S_case=4; S_pair[137:136]=1; update(1,S_pair); done(0,1);
        slot_cmd(2,4,1,2,0);
        if(S_p_O_host_pinned_slots!=1 || S_m_O_slot_states[5:3]!=0) fail("explicit pin shrink did not allow safe old-slot eviction");

        S_case=5; load(2); update(2,reservation(1,2,1)); done(2,0);
        if(S_p_O_host_pinned_slots!=1) fail("held source identity was replaced in place");
        update(3,S_pair); done(0,1);
        S_pair[137:136]=0; update(3,S_pair); done(0,0); slot_cmd(2,4,0,2,0);

        S_case=6; S_pair=reservation(1,2,1); S_pair[97:66]=32'h11111111;
        update(4,S_pair); done(3,0);
        S_pair=reservation(1,2,1); S_pair[132:130]=6; update(5,S_pair); done(1,0);
        S_pair=reservation(1,2,1); S_pair[0]=1; update(6,S_pair); done(1,0);
        S_pair=reservation(1,2,1); update(0,S_pair); done(1,0);

        S_case=7; load(3); S_cmd_gate=0;
        offer(2,command(4,3,2,S_tokens[3],7,0)); update(7,reservation(1,3,1));
        repeat(30) begin @(negedge S_video_clk);
            if(S_p_O_done_valid || S_p_O_host_pinned_slots[3]) fail("pin raced an admitted slot mutation"); end
        S_cmd_gate=1; take(2,0); done(3,0);

        S_case=8; @(negedge S_host_clk); S_host_run=0;
        update(8,reservation(1,2,1));
        repeat(30) begin @(negedge S_video_clk); if(S_p_O_done_valid || S_p_O_images[137:136]!=0) fail("stopped host fabricated image pin proof"); end
        S_host_run=1; done(0,1);

        S_case=9; S_pair=reservation(1,2,1); update(9,S_pair);
        wait(S_p_O_host_reservation==S_pair && u_pins.S_host_active[185:154]==9);
        @(negedge S_video_clk); S_video_run=0;
        slot_cmd(2,4,2,2,2);
        if(!S_p_O_host_pinned_slots[2]) fail("stopped video lost an installed host pin");
        S_video_run=1; done(0,1);

        S_case=10; slot_cmd(1,2,2,0,0);
        @(negedge S_host_clk); S_media_valid=0;
        @(negedge S_host_clk); S_media_valid=1;
        wait(S_p_O_images[137:136]==0);
        repeat(20) begin @(negedge S_video_clk); if(S_p_O_images[137:136]!=0 || !S_p_O_host_pinned_slots[2]) fail("transient media failure revived or released old pin"); end
        S_pair[137:136]=0; update(10,S_pair); done(0,0);
        slot_cmd(2,4,2,2,2); slot_cmd(1,3,2,0,0);
        if(S_m_O_slot_states[8:6]!=0) fail("stale actual read lock was not released by its real owner");

        S_case=11; reset_all;
        offer(2,command(0,5,2,0,99,1)); take(2,0);
        offer(2,command(1,5,2,S_tokens[5],99,1)); take(2,0);
        S_pair={2'b10,3'd5,3'd0,S_tokens[5],32'd0,32'd99,32'd0,2'b10};
        update(1,S_pair); done(0,2);
        @(negedge S_host_clk); S_media_valid=0; S_generation=42;
        repeat(30) begin @(negedge S_video_clk); if(S_p_O_images[137:136]!=2) fail("resident image depended on TF media"); end

        S_case=12; reset_all; load(0); S_pair=reservation(1,0,1);
        update(1,S_pair); wait(S_p_O_done_valid);
        @(negedge S_host_clk); S_media_valid=0;
        wait(S_p_O_images[137:136]==0); done(0,0);
        if(!S_p_O_host_pinned_slots[0]) fail("status update while done held destroyed pin ownership");

        S_case=13; reset_all; load(0); S_pair=reservation(1,0,1); update(1,S_pair); done(0,1);
        @(negedge S_video_clk); u_pins.S_sequence=32'hffffffff;
        update(2,S_pair); done(7,0);
        if(!S_p_O_video_quarantined || !S_p_O_host_pinned_slots[0] || S_p_O_update_ready) fail("exhausted pin sequence wrapped or dropped ownership");

        S_case=14; reset_all;
        fork
            begin offer(0,command(5,0,0,0,7,0)); take(0,1); end
            begin offer(1,command(5,0,0,0,7,0)); take(1,1); end
            begin offer(2,command(5,0,0,0,7,0)); take(2,1); end
        join
        if(S_manager_commands!=3) fail("simultaneous clients lost a real result");

        S_case=15; reset_all; slot_cmd(0,0,0,2,0);
        @(negedge S_host_clk); S_a_I_client_command[0+:115]=command(1,0,2,S_tokens[0],7,0);
        S_a_I_client_command[3]=0; S_a_I_client_valid[0]=1;
        offer(2,command(5,0,2,0,7,0)); take(2,1);
        if(S_a_O_client_ready[0] || S_m_O_slot_states[2:0]!=1) fail("unretired FINISH blocked eligible client or completed early");
        @(negedge S_host_clk); S_a_I_client_command[3]=1;
        @(posedge S_host_clk); while(!S_a_O_client_ready[0]) @(posedge S_host_clk);
        @(negedge S_host_clk); S_a_I_client_valid[0]=0; take(0,0);

        S_case=16; reset_all; S_cmd_gate=0; offer(2,command(5,0,2,0,7,0));
        S_cmd_gate=1; wait(S_m_O_result_valid);
        @(negedge S_host_clk); S_bad_result=S_manager_result; S_bad_result[86:85]=0; S_inject_result=1;
        @(negedge S_host_clk); S_inject_result=0; take(2,1);
        if(!S_a_O_contract_fault || S_a_O_client_ready!=0) fail("wrong result identity did not quarantine new slot work");

        S_case=17; reset_all; load(0); S_pair=reservation(1,0,1); update(1,S_pair); done(0,1);
        S_pair[137:136]=0; update(1,S_pair);
        // A producer may change command inputs after acceptance: old values must
        // not revive proof after host has already released the old reservation.
        S_pair[137:136]=1; S_p_I_reservation=S_pair;
        wait(S_p_O_host_pinned_slots==0); done(0,0);
        if(S_p_O_images[137:136]!=0) fail("old inputs revived a pin released by an in-flight update");
        update(2,S_pair); done(0,1);

        S_case=18; @(negedge S_video_clk); S_p_I_video_enable=0; #1;
        if(S_p_O_images[137:136]!=0 || !S_p_O_host_pinned_slots[0]) fail("video permission withdrawal changed actual pin ownership");
        repeat(10) @(negedge S_video_clk);
        S_p_I_video_enable=1; #1;
        if(S_p_O_images[137:136]!=1) fail("video permission recovery lost a still-installed real pin");

        $display("PASS: 18 image pin/slot scenarios; actual CDC FIFO, arbiter and slot manager, explicit producer/reader peers");
        S_test_pass=1; $finish;
    end
endmodule
