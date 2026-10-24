`timescale 1ns/1ps
// Real playback and BGM mailbox. PCM/header/clear and stop-I/O peers are fixtures.
// No WAV/FAT/physical clock or memory claim is made by this test.
module tb_player_audio_policy;
    reg S_host_clk=0,S_clk=0,S_reset=1,S_tick=0;
    always #4 S_host_clk=~S_host_clk;
    always #20 S_clk=~S_clk;
    reg S_a_load=0,S_b_load=0,S_a_clear=0,S_b_clear=0,S_start=0,S_silence=0,S_pause=0;
    reg S_loop=0,S_slot=1,S_abort=0,S_done_ready=0,S_transition_busy=0;
    reg [15:0] S_epoch=2;
    reg [31:0] S_epochs={16'd2,16'd1};
    reg [63:0] S_serials={32'd2,32'd1};
    wire S_loop_ready,S_need,S_result_valid;
    wire [7:0] S_result;
    wire S_loop_fade,S_target,S_loop_busy,S_stop_request;
    wire S_a_load_ready,S_b_load_ready,S_start_ready,S_fade_ready;
    wire S_silence_ready,S_silence_started,S_silence_done;
    wire S_a_idle,S_b_idle,S_a_ready,S_b_ready,S_a_enabled,S_b_enabled;
    wire S_a_loaded,S_b_loaded,S_a_error,S_b_error,S_a_end,S_b_end;
    wire S_a_consumed,S_b_consumed,S_a_und,S_b_und,S_release_a,S_release_b;
    wire S_sample_valid,S_clipped,S_fade_done,S_active_b,S_busy,S_started,S_paused,S_pause_busy;
    wire [23:0] S_left,S_right;
    wire [31:0] S_a_next,S_b_next;
    reg S_stop=0,S_stop_ack=0;
    reg S_manual_fade=0,S_manual_target=0;
    reg S_test_pass=0;
    integer S_i,S_started_events=0,S_silence_events=0,S_fade_events=0;
    reg [31:0] S_held_index;
    bgm_loop_cdc #(.PREFETCH_FRAMES(20),.FADE_FRAMES(7)) u_loop (
        .I_host_clk(S_host_clk),.I_video_clk(S_clk),.I_async_reset(S_reset),
        .I_start_valid(S_loop),.O_start_ready(S_loop_ready),.O_need(S_need),
        .I_slot(S_slot),.I_track_epoch(S_epoch),.I_abort(S_abort),
        .O_done_valid(S_result_valid),.I_done_ready(S_done_ready),.O_result(S_result),
        .I_clock_enable(1'b1),.I_pause(S_pause),.I_media_abort(1'b0),.I_transition_busy(S_transition_busy),
        .I_track_known(2'b11),.I_track_enabled({S_b_enabled,S_a_enabled}),.I_track_failed(2'b00),
        .I_track_epochs(S_epochs),.I_track_serials(S_serials),.I_track_totals({32'd400,32'd100}),
        .I_track_next_index({S_b_next,S_a_next}),.I_active_b(S_active_b),
        .I_fade_ready(S_fade_ready),.I_fade_done(S_fade_done),
        .O_fade_valid(S_loop_fade),.O_target_b(S_target),.O_video_busy(S_loop_busy),
        .O_stop_request(S_stop_request),.I_stop_ack(S_stop_ack)
    );
    audio_playback #(.FIFO_ADDR_BITS(7),.FADE_SAMPLES(7)) u_playback (
        .I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),
        .I_a_stop(S_stop),.I_b_stop(S_stop),.I_a_clear(S_a_clear),.I_b_clear(S_b_clear),
        .O_a_idle(S_a_idle),.O_b_idle(S_b_idle),.I_a_valid(1'b1),.I_b_valid(1'b1),
        .O_a_ready(S_a_ready),.O_b_ready(S_b_ready),
        .I_a_left(24'h400000),.I_a_right(24'hc00000),.I_b_left(24'h200000),.I_b_right(24'he00000),
        .I_a_level(8'd100),.I_b_level(8'd100),.I_a_prefilled(1'b1),.I_b_prefilled(1'b1),
        .I_a_load_valid(S_a_load),.I_b_load_valid(S_b_load),
        .O_a_load_ready(S_a_load_ready),.O_b_load_ready(S_b_load_ready),
        .I_a_total_frames(32'd100),.I_b_total_frames(32'd400),.I_a_start_index(32'd0),.I_b_start_index(32'd0),
        .O_a_load_error(S_a_error),.O_b_load_error(S_b_error),.O_a_loaded(S_a_loaded),.O_b_loaded(S_b_loaded),
        .O_a_next_index(S_a_next),.O_b_next_index(S_b_next),.O_a_end(S_a_end),.O_b_end(S_b_end),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_fade_valid(S_loop_fade || S_manual_fade),.I_target_b(S_loop_busy ? S_target : S_manual_target),.O_fade_ready(S_fade_ready),
        .I_silence_valid(S_silence),.O_silence_ready(S_silence_ready),
        .O_silence_started(S_silence_started),.O_silence_done(S_silence_done),
        .I_pause(S_pause),.I_pause_allow(1'b1),.O_paused(S_paused),.O_pause_busy(S_pause_busy),
        .O_a_enabled(S_a_enabled),.O_b_enabled(S_b_enabled),.O_a_consumed(S_a_consumed),.O_b_consumed(S_b_consumed),
        .O_a_underrun(S_a_und),.O_b_underrun(S_b_und),.O_release_a(S_release_a),.O_release_b(S_release_b),
        .I_volume(5'd16),.I_mute(1'b0),.I_prompt_valid(1'b0),.I_prompt_left(24'd0),.I_prompt_right(24'd0),
        .O_sample_valid(S_sample_valid),.O_left(S_left),.O_right(S_right),.O_clipped(S_clipped),
        .O_fade_done(S_fade_done),.O_active_b(S_active_b),.O_busy(S_busy),.O_started(S_started)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL audio policy: %0s",message); $stop; end
    endtask
    always @(posedge S_clk) if(!S_reset) begin
        if(S_silence_started) S_started_events=S_started_events+1;
        if(S_silence_done) begin
            S_silence_events=S_silence_events+1;
            if(!S_sample_valid || S_left!=0 || S_right!=0 || S_a_enabled || S_b_enabled)
                fail("silence completion precedes actual zero output/release");
        end
        if(S_fade_done) S_fade_events=S_fade_events+1;
        if(S_a_und || S_b_und) fail("continuous fixture reported underrun");
    end
    // Read-side stop proof is real; this fixture has no outstanding file I/O.
    always @(posedge S_clk) begin
        if(S_reset) begin S_stop<=0; S_stop_ack<=0; end
        else begin
            if(S_stop_request) S_stop<=1;
            if(S_stop && S_a_idle && S_b_idle) S_stop_ack<=1;
            if(S_stop_ack && !S_stop_request) begin S_stop<=0; S_stop_ack<=0; end
        end
    end
    task tick;
        begin
            @(negedge S_clk); S_tick=1;
            @(negedge S_clk); S_tick=0;
            repeat(7) @(negedge S_clk);
        end
    endtask
    task offer_loop;
        input slot;
        input [15:0] epoch;
        begin
            wait(S_loop_ready); @(negedge S_host_clk); S_slot=slot; S_epoch=epoch; S_loop=1;
            @(negedge S_host_clk); S_loop=0;
            repeat(12) @(negedge S_clk);
        end
    endtask
    task consume_result;
        input [3:0] error;
        input not_started;
        begin
            wait(S_result_valid); @(negedge S_host_clk);
            if(S_result[7:4]!=error || S_result[3]!=not_started) fail("loop terminal/cancel proof");
            repeat(8) begin @(negedge S_host_clk); if(!S_result_valid) fail("loop result not held"); end
            S_done_ready=1; @(negedge S_host_clk); S_done_ready=0; S_abort=0;
            wait(S_loop_ready);
        end
    endtask
    initial begin
        repeat(6) @(negedge S_clk); S_reset=0; repeat(8) @(negedge S_clk);
        S_a_load=1; S_b_load=1; @(negedge S_clk); S_a_load=0; S_b_load=0;
        wait(S_start_ready); S_start=1; @(negedge S_clk); S_start=0;
        repeat(80) tick(); wait(S_need);
        offer_loop(1,2);
        if(S_result_valid || S_b_enabled) fail("loop accepted before old tail threshold");
        S_transition_busy=1; repeat(15) tick();
        if(S_loop_fade || S_b_enabled) fail("loop overlaps image transition");
        S_transition_busy=0;
        repeat(10) tick(); consume_result(0,0);
        if(!S_active_b || S_a_enabled || !S_b_enabled || S_fade_events!=1) fail("real BGM A to B loop completion");
        // Reload a genuinely disabled old slot; its new epoch/serial is distinct.
        @(negedge S_clk); S_a_clear=1; @(negedge S_clk); S_a_clear=0;
        S_epochs[15:0]=3; S_serials[31:0]=3;
        wait(S_a_load_ready); S_a_load=1; @(negedge S_clk); S_a_load=0;
        offer_loop(0,3);
        S_held_index=S_b_next;
        S_pause=1; repeat(75) tick();
        if(!S_paused || S_loop_fade || S_a_enabled) fail("paused BGM loop triggered");
        repeat(4) tick(); if(S_b_next!=S_held_index+64) fail("pause consumed beyond fade-out envelope");
        S_abort=1; consume_result(3,1);
        if(!S_b_enabled || S_a_enabled) fail("unoffered cancel stopped old BGM");
        S_pause=0; repeat(65) tick();
        // A no-audio item fades the active track to an actual zero endpoint.
        wait(S_silence_ready); @(negedge S_clk); S_silence=1;
        @(negedge S_clk); S_silence=0;
        for(S_i=1;S_i<=7;S_i=S_i+1) begin
            tick();
            if(S_left!==(64'd2097152*(65536-(64'd65536*S_i)/7))/65536)
                fail("silence PCM ramp differs from the sample-based gain");
        end
        if(S_silence_events!=1 || S_started_events!=1 || S_a_enabled || S_b_enabled || S_left!=0 || S_right!=0)
            fail("explicit silence event did not drain");
        // A later file resumes with a real fade from silence, including target==old active.
        @(negedge S_clk); S_a_clear=1; @(negedge S_clk); S_a_clear=0;
        wait(S_a_load_ready); S_a_load=1; @(negedge S_clk); S_a_load=0;
        S_manual_target=0; wait(S_fade_ready); S_manual_fade=1;
        @(negedge S_clk); S_manual_fade=0; repeat(70) tick();
        if(!S_a_enabled || S_b_enabled || S_active_b || S_left!=24'h400000 || S_right!=24'hc00000)
            fail("fade from silence did not restore samples");
        // Cancel after presenting a real fade: require actual read-side stop proof.
        @(negedge S_clk); S_b_clear=1; @(negedge S_clk); S_b_clear=0;
        S_epochs[31:16]=4; S_serials[63:32]=4;
        wait(S_b_load_ready); S_b_load=1; @(negedge S_clk); S_b_load=0;
        offer_loop(1,4);
        fork
            begin wait(S_loop_fade); @(negedge S_host_clk); S_abort=1; end
            begin repeat(90) tick(); end
        join
        consume_result(3,0);
        if(S_a_enabled || S_b_enabled || S_stop || S_stop_ack) fail("late cancel fabricated stop/retirement");
        S_test_pass=1; $display("PASS: real BGM mailbox/playback loop, exclusion, pause/cancel, silence and restart"); $finish;
    end
    initial begin #5000000; fail("watchdog"); end
endmodule
