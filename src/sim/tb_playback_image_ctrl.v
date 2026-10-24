`timescale 1ns/1ps
// Controller only. Pin/transition peers below are explicit protocol fixtures.
module tb_playback_image_ctrl;
    reg S_clk=0,S_reset=0,S_test_pass=0;
    always #20 S_clk=~S_clk;
    reg S_I_clock_enable=0;
    reg S_I_start_valid=0;
    wire S_O_start_ready;
    reg [403:0] S_I_command=0;
    reg S_I_abort=0;
    wire S_O_transition_start_valid;
    reg S_I_transition_start_ready=0;
    wire [403:0] S_O_command;
    wire S_O_transition_abort;
    reg S_I_transition_busy=0;
    reg S_I_transition_done_valid=0;
    wire S_O_transition_done_ready;
    reg [31:0] S_I_transition_epoch=0;
    reg [15:0] S_I_transition_tag=0;
    reg [246:0] S_I_transition_config=0;
    reg [1:0] S_I_transition_hold=0;
    reg [3:0] S_I_transition_error=0;
    reg S_I_transition_settled=0;
    reg S_I_transition_quarantined=0;
    reg S_I_recover_valid=0;
    reg S_I_recover_source=0;
    wire S_O_recover_ready;
    wire S_O_transition_recover_valid;
    wire S_O_transition_recover_source;
    reg S_I_transition_recover_ready=0;
    wire S_O_pin_update_valid;
    reg S_I_pin_update_ready=0;
    wire [31:0] S_O_pin_epoch;
    wire [15:0] S_O_pin_tag;
    wire [137:0] S_O_pin_reservation;
    reg S_I_pin_done_valid=0;
    wire S_O_pin_done_ready;
    reg [31:0] S_I_pin_epoch=0;
    reg [31:0] S_I_pin_installed_epoch=0;
    reg [15:0] S_I_pin_tag=0;
    reg [15:0] S_I_pin_installed_tag=0;
    reg [3:0] S_I_pin_error=0;
    reg [137:0] S_I_pin_installed_reservation=0;
    reg [137:0] S_I_images=0;
    reg S_I_pin_quarantined=0;
    reg S_I_retry_pin_valid=0;
    wire S_O_retry_pin_ready;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [31:0] S_O_epoch;
    wire [15:0] S_O_tag;
    wire [3:0] S_O_error;
    wire [3:0] S_O_pin_error;
    wire S_O_transition_started;
    wire S_O_sync_required;
    wire S_O_retry_result;
    wire S_O_cancel_late;
    wire S_O_quarantined;
    wire S_O_response_discarded;
    playback_image_ctrl u_ctrl (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_clock_enable(S_I_clock_enable),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .I_command(S_I_command),
        .I_abort(S_I_abort),
        .O_transition_start_valid(S_O_transition_start_valid),
        .I_transition_start_ready(S_I_transition_start_ready),
        .O_command(S_O_command),
        .O_transition_abort(S_O_transition_abort),
        .I_transition_busy(S_I_transition_busy),
        .I_transition_done_valid(S_I_transition_done_valid),
        .O_transition_done_ready(S_O_transition_done_ready),
        .I_transition_epoch(S_I_transition_epoch),
        .I_transition_tag(S_I_transition_tag),
        .I_transition_config(S_I_transition_config),
        .I_transition_hold(S_I_transition_hold),
        .I_transition_error(S_I_transition_error),
        .I_transition_settled(S_I_transition_settled),
        .I_transition_quarantined(S_I_transition_quarantined),
        .I_recover_valid(S_I_recover_valid),
        .I_recover_source(S_I_recover_source),
        .O_recover_ready(S_O_recover_ready),
        .O_transition_recover_valid(S_O_transition_recover_valid),
        .O_transition_recover_source(S_O_transition_recover_source),
        .I_transition_recover_ready(S_I_transition_recover_ready),
        .O_pin_update_valid(S_O_pin_update_valid),
        .I_pin_update_ready(S_I_pin_update_ready),
        .O_pin_epoch(S_O_pin_epoch),
        .O_pin_tag(S_O_pin_tag),
        .O_pin_reservation(S_O_pin_reservation),
        .I_pin_done_valid(S_I_pin_done_valid),
        .O_pin_done_ready(S_O_pin_done_ready),
        .I_pin_epoch(S_I_pin_epoch),
        .I_pin_installed_epoch(S_I_pin_installed_epoch),
        .I_pin_tag(S_I_pin_tag),
        .I_pin_installed_tag(S_I_pin_installed_tag),
        .I_pin_error(S_I_pin_error),
        .I_pin_installed_reservation(S_I_pin_installed_reservation),
        .I_images(S_I_images),
        .I_pin_quarantined(S_I_pin_quarantined),
        .I_retry_pin_valid(S_I_retry_pin_valid),
        .O_retry_pin_ready(S_O_retry_pin_ready),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_epoch(S_O_epoch),
        .O_tag(S_O_tag),
        .O_error(S_O_error),
        .O_pin_error(S_O_pin_error),
        .O_transition_started(S_O_transition_started),
        .O_sync_required(S_O_sync_required),
        .O_retry_result(S_O_retry_result),
        .O_cancel_late(S_O_cancel_late),
        .O_quarantined(S_O_quarantined),
        .O_response_discarded(S_O_response_discarded)
    );
    integer S_case=0,S_updates=0,S_starts=0,S_transitions=0;
    reg S_pin_gate=1,S_pin_return=1,S_images_gate=1,S_start_gate=1,S_transition_return=1;
    reg S_pin_pending=0,S_t_pending=0,S_pin_wrong_identity=0,S_pin_bad_install=0,S_bad_hold=0;
    reg [3:0] S_next_pin_error=0,S_snapshot_pin_error=0,S_next_transition_error=0;
    reg [137:0] S_pin_snapshot=0;
    reg [31:0] S_pin_epoch=0;
    reg [15:0] S_pin_tag=0;
    reg [403:0] S_t_command=0;
    reg [246:0] S_config=0;
    reg [1:0] S_final_hold=2;
    reg [137:0] S_retained=0;
    reg [59:0] S_held_result;
    task fail;
        input [767:0] message;
        begin $display("FAIL: image ctrl case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #20000000; fail("watchdog timeout"); end
    always @* begin
        S_I_pin_update_ready=S_pin_gate && !S_pin_pending && !S_I_pin_done_valid;
        S_I_transition_start_ready=S_start_gate && !S_I_transition_busy;
        S_I_transition_recover_ready=S_I_transition_busy && !S_t_pending && !S_I_transition_done_valid;
        S_I_images={((S_images_gate && S_I_pin_installed_epoch==S_O_pin_epoch &&
            S_I_pin_installed_tag==S_O_pin_tag && S_I_pin_installed_reservation==S_O_pin_reservation) ?
            S_I_pin_installed_reservation[137:136] : 2'b00),S_I_pin_installed_reservation[135:0]};
    end
    // Pin peer explicitly holds update/installation and result separately.
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin
            S_pin_pending<=0; S_I_pin_done_valid<=0; S_I_pin_installed_reservation<=0;
            S_I_pin_installed_epoch<=0; S_I_pin_installed_tag<=0; S_updates<=0;
        end else begin
            if(S_O_pin_update_valid && S_I_pin_update_ready) begin
                S_updates<=S_updates+1; S_pin_pending<=1; S_pin_snapshot<=S_O_pin_reservation;
                S_pin_epoch<=S_O_pin_epoch; S_pin_tag<=S_O_pin_tag; S_snapshot_pin_error<=S_next_pin_error;
            end
            if(S_pin_pending && !S_I_pin_done_valid && S_pin_return) begin
                S_I_pin_epoch<=S_pin_epoch; S_I_pin_tag<=S_pin_wrong_identity ? S_pin_tag+1'b1 : S_pin_tag;
                S_I_pin_error<=S_snapshot_pin_error; S_I_pin_done_valid<=1;
                if(S_snapshot_pin_error==0) begin
                    S_I_pin_installed_epoch<=S_pin_epoch; S_I_pin_installed_tag<=S_pin_tag;
                    S_I_pin_installed_reservation<=S_pin_bad_install ? 0 : S_pin_snapshot;
                end
            end
            if(S_I_pin_done_valid && S_O_pin_done_ready) begin
                S_I_pin_done_valid<=0;
                if(!S_pin_wrong_identity) S_pin_pending<=0;
            end
        end
    end
    // Transition peer reports actual protocol completion only under a test gate.
    always @(posedge S_clk or posedge S_reset) begin
        if(S_reset) begin
            S_t_pending<=0; S_I_transition_busy<=0; S_I_transition_done_valid<=0; S_starts<=0; S_transitions<=0;
        end else begin
            if(S_O_transition_start_valid && S_I_transition_start_ready) begin
                S_t_command<=S_O_command; S_t_pending<=1; S_I_transition_busy<=1; S_starts<=S_starts+1;
            end
            if(S_O_transition_recover_valid && S_I_transition_recover_ready) S_t_pending<=1;
            if(S_t_pending && S_transition_return && !S_I_transition_done_valid) begin
                S_I_transition_epoch<=S_t_command[403:372]; S_I_transition_tag<=S_t_command[371:356];
                S_I_transition_config<=S_t_command[355:109];
                S_I_transition_error<=S_O_transition_abort ? 4'd3 : S_next_transition_error;
                S_I_transition_settled<=S_final_hold!=3;
                S_I_transition_hold<=S_bad_hold ? 0 : S_final_hold;
                S_I_transition_done_valid<=1; S_t_pending<=0; S_transitions<=S_transitions+1;
            end
            if(S_I_transition_done_valid && S_O_transition_done_ready) begin
                S_I_transition_done_valid<=0; S_I_transition_busy<=S_I_transition_hold==3;
            end
        end
    end
    task reset_all;
        begin
            S_reset=1; S_I_clock_enable=1; S_I_start_valid=0; S_I_done_ready=0; S_I_abort=0;
            S_I_recover_valid=0; S_I_recover_source=0; S_I_retry_pin_valid=0;
            S_I_pin_quarantined=0; S_I_transition_quarantined=0;
            S_pin_gate=1; S_pin_return=1; S_images_gate=1; S_start_gate=1; S_transition_return=1;
            S_pin_wrong_identity=0; S_pin_bad_install=0; S_bad_hold=0; S_next_pin_error=0; S_next_transition_error=0; S_final_hold=2;
            S_config={2'b11,1'b0,3'd1,3'd0,32'd22,32'd11,32'd7,32'd7,2'b00,
                3'd0,16'd2,17'd0,4'd0,4'd0,5'd8,3'd0,2'd0,1'b0,1'b0,18'd0,2'd0,32'd0};
            repeat(5) @(negedge S_clk); S_reset=0;
        end
    endtask
    task start;
        input [31:0] epoch;
        begin
            @(negedge S_clk); S_I_command={epoch,16'h1234,S_config,3'd2,16'd2,7'd0,2'd0,1'b0,16'd0,32'd0,32'd0};
            S_I_start_valid=1;
            @(posedge S_clk); while(!S_O_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_I_start_valid=0;
        end
    endtask
    task result;
        input [3:0] error,pin_error;
        input started,sync_required;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_pin_error!==pin_error || S_O_transition_started!==started || S_O_sync_required!==sync_required)
                fail("controller terminal did not reflect true pin/transition obligations");
            S_held_result={S_O_epoch,S_O_tag,S_O_error,S_O_pin_error,S_O_transition_started,S_O_sync_required,S_O_retry_result,S_O_cancel_late};
            S_I_abort=1;
            repeat(10) begin @(negedge S_clk);
                if(!S_O_done_valid || S_held_result!=={S_O_epoch,S_O_tag,S_O_error,S_O_pin_error,
                    S_O_transition_started,S_O_sync_required,S_O_retry_result,S_O_cancel_late}) fail("backpressured result changed on new abort"); end
            S_I_done_ready=1; @(negedge S_clk); S_I_done_ready=0; S_I_abort=0;
        end
    endtask
    initial begin
        S_case=1; reset_all; start(1); S_I_command=0; result(0,0,1,0);
        if(S_updates!=2 || S_starts!=1 || S_I_pin_installed_reservation[137:136]!=2) fail("normal initial/final pin sequence or command snapshot");

        S_case=2; reset_all; S_pin_return=0; start(1);
        repeat(20) begin @(negedge S_clk); if(S_starts!=0 || S_O_done_valid) fail("pin request acceptance fabricated installation"); end
        S_pin_return=1; result(0,0,1,0);

        S_case=3; reset_all; S_images_gate=0; start(1); wait(u_ctrl.S_state==3);
        repeat(20) begin @(negedge S_clk); if(S_starts!=0 || S_O_done_valid) fail("pin done without available images started transition"); end
        S_images_gate=1; result(0,0,1,0);

        S_case=4; reset_all; S_pin_gate=0; start(1); S_I_abort=1;
        repeat(20) begin @(negedge S_clk); if(!S_O_pin_update_valid || S_O_done_valid) fail("abort withdrew already presented pin update"); end
        S_pin_gate=1; result(3,0,0,0);
        if(S_updates!=2 || S_I_pin_installed_reservation[137:136]!=0 || S_starts!=0) fail("cancel did not reliably restore empty prior pins");

        S_case=5; reset_all; start(1); result(0,0,1,0); S_retained=S_I_pin_installed_reservation;
        S_images_gate=0; start(2); wait(u_ctrl.S_state==3); S_I_abort=1; result(3,0,0,0);
        if(S_I_pin_installed_reservation!==S_retained || S_starts!=1) fail("prestart cancel lost previous actual retained image pin");

        S_case=6; reset_all; S_start_gate=0; start(1); wait(S_O_transition_start_valid); S_I_abort=1;
        repeat(20) begin @(negedge S_clk); if(!S_O_transition_start_valid || !S_O_transition_abort) fail("presented transition start was withdrawn on cancel"); end
        S_start_gate=1; result(3,0,1,0);

        S_case=7; reset_all; S_transition_return=0; start(1); wait(S_starts==1);
        repeat(20) begin @(negedge S_clk); if(S_O_done_valid || S_updates!=1) fail("transition command acceptance fabricated actual result"); end
        S_transition_return=1; result(0,0,1,0);

        S_case=8; reset_all; S_pin_gate=1; start(1); wait(S_starts==1);
        S_pin_gate=0; wait(S_O_pin_update_valid);
        repeat(20) begin @(negedge S_clk);
            if(S_O_done_valid || !S_I_transition_done_valid || S_O_transition_done_ready) fail("final pin stall consumed real held transition result"); end
        S_pin_gate=1; result(0,0,1,0);

        S_case=9; reset_all; S_next_pin_error=3; start(1); result(8,3,0,0);
        if(S_starts!=0 || S_I_pin_installed_reservation!=0) fail("initial pin rejection started transition");
        S_next_pin_error=0; start(2); result(0,0,1,0);

        S_case=10; reset_all; S_transition_return=0; start(1); wait(S_starts==1);
        S_next_pin_error=3; S_transition_return=1; result(8,3,1,1);
        if(S_I_pin_installed_reservation[137:136]!=3 || S_O_start_ready) fail("failed shrink freed old pins or opened next start");
        S_next_pin_error=0; wait(S_O_retry_pin_ready);
        @(negedge S_clk); S_I_retry_pin_valid=1; @(negedge S_clk); S_I_retry_pin_valid=0;
        result(0,0,1,0);
        if(!S_O_retry_result || S_starts!=1 || S_I_pin_installed_reservation[137:136]!=2) fail("pin retry reran display or lost frozen target pin");

        S_case=11; reset_all; S_images_gate=0; start(1); wait(u_ctrl.S_state==3);
        S_next_pin_error=3; S_I_abort=1; result(3,3,0,1);
        S_next_pin_error=0; @(negedge S_clk); S_I_retry_pin_valid=1;
        @(negedge S_clk); S_I_retry_pin_valid=0; result(0,0,0,0);
        if(S_I_pin_installed_reservation[137:136]!=0 || S_starts!=0) fail("restoration retry lost prior empty reservation");

        S_case=12; reset_all; S_pin_wrong_identity=1; start(1); wait(S_O_response_discarded);
        repeat(10) begin @(negedge S_clk); if(S_O_done_valid || S_starts!=0) fail("wrong pin result identity retired current command"); end
        S_pin_wrong_identity=0; result(0,0,1,0);

        S_case=13; reset_all; S_pin_bad_install=1; start(1); result(8,4,0,0);
        if(!S_O_quarantined || S_O_start_ready) fail("pin success without matching installed tuple escaped quarantine");

        S_case=14; reset_all; S_bad_hold=1; start(1); result(8,0,1,1);
        if(!S_O_quarantined || S_updates!=1) fail("invalid final hold caused unsafe pin mutation");

        S_case=15; reset_all; S_next_transition_error=4; S_final_hold=3; start(1); result(4,0,1,0);
        if(S_updates!=1 || S_I_pin_installed_reservation[137:136]!=3) fail("unsettled transition dropped both image pins");
        S_next_transition_error=0; S_final_hold=2;
        wait(S_O_recover_ready); @(negedge S_clk); S_I_recover_source=1; S_I_recover_valid=1;
        @(negedge S_clk); S_I_recover_valid=0; result(0,0,1,0);
        if(S_starts!=1 || S_transitions!=2 || S_updates!=2) fail("explicit transition recovery did not synchronize final single pin");

        S_case=16; reset_all; S_I_clock_enable=0; start(1); result(5,0,0,0);
        if(S_updates!=0 || S_starts!=0) fail("disabled clock permission created resource work");

        S_case=17; reset_all; S_config[52]=1; start(1); result(1,0,0,0);
        if(S_updates!=0 || S_starts!=0) fail("illegal config installed pins before validation");

        S_case=18; reset_all; S_transition_return=0; start(1); wait(S_starts==1); S_transition_return=1;
        wait(u_ctrl.S_purpose==1 && S_O_pin_update_valid); S_I_abort=1; result(0,0,1,0);
        if(!S_O_cancel_late) fail("abort during final pin sync lost late cancellation fact");

        $display("PASS: 18 image/transition controller protocol scenarios; pin and transition endpoints are fixtures");
        S_test_pass=1; $finish;
    end
endmodule
