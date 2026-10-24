`timescale 1ns/1ps
module tb_audio_playback;
    wire S_silence_u_dut_O_started;
    wire S_silence_u_dut_O_silence_ready;
    wire S_silence_u_dut_O_silence_started;
    wire S_silence_u_dut_O_silence_done;
    reg S_clk=0,S_write_clk=0,S_reset=0,S_tick=0;
    reg S_a_load=0,S_b_load=0,S_start=0,S_fade=0,S_target=0,S_pause=0,S_allow=1;
    reg [31:0] S_a_total=4000,S_b_total=4000,S_a_base=0,S_b_base=0;
    wire S_a_lr,S_b_lr,S_start_ready,S_fade_ready,S_paused,S_pause_busy;
    wire S_a_loaded,S_b_loaded,S_a_error,S_b_error,S_a_end,S_b_end;
    wire S_a_en,S_b_en,S_a_consumed,S_b_consumed,S_a_und,S_b_und,S_ra,S_rb;
    wire S_valid,S_clip,S_done,S_active,S_busy;
    wire [23:0] S_left,S_right,S_al,S_ar,S_bl,S_br;
    wire [31:0] S_a_next,S_b_next;
    wire S_av,S_bv,S_a_ready,S_b_ready,S_ap,S_bp,S_an,S_bn,S_awr,S_bwr;
    wire [4:0] S_awlevel,S_arlevel,S_bwlevel,S_brlevel;
    reg S_awvalid=0,S_bwvalid=0,S_ataken=0,S_btaken=0;
    reg [23:0] S_awdata=0,S_bwdata=0;
    integer S_asent=0,S_bsent=0,S_alimit=4000,S_blimit=4000;
    integer S_ea=0,S_eb=0,S_volume_gain=0,S_ticks=0,S_outputs=0,S_unders=0,S_completions=0,S_i;
    reg [23:0] S_eal=0,S_ear=0,S_ebl=0,S_ebr=0,S_anchor_l,S_anchor_r;
    reg [4:0] S_valid_pipe=0;
    reg S_test_pass=0;
    always #20 S_clk=~S_clk;
    always #4 S_write_clk=~S_write_clk;
    function [23:0] sample;
        input integer track,index;
        begin sample=track ? 24'he00000+index*24'h203 : 24'h100000+index*24'h101; end
    endfunction
    function [23:0] scaled;
        input [23:0] value;
        input integer gain,denom;
        reg signed [63:0] wide;
        begin
            wide=$signed(value); wide=wide*gain;
            if (wide<0) wide=-((-wide+denom-1)/denom);
            else wide=wide/denom;
            scaled=wide[23:0];
        end
    endfunction
    function [23:0] mixed;
        input [23:0] a,b;
        input integer weight,volume,pause_gain;
        reg signed [63:0] av,bv,wide;
        reg [23:0] value;
        begin
            av=$signed(a); bv=$signed(b); wide=av*(65536-weight)+bv*weight;
            if (wide<0) wide=-((-wide+65535)/65536); else wide=wide/65536;
            value=scaled(wide[23:0],volume,65536);
            mixed=scaled(value,pause_gain,64);
        end
    endfunction
    always @(posedge S_write_clk or posedge S_reset) begin
        if (S_reset) begin S_asent=0; S_bsent=0; S_ataken=0; S_btaken=0; end
        else begin
            S_ataken=S_awvalid && S_awr; S_btaken=S_bwvalid && S_bwr;
            if (S_ataken) S_asent=S_asent+1;
            if (S_btaken) S_bsent=S_bsent+1;
        end
    end
    always @(negedge S_write_clk or posedge S_reset) begin
        if (S_reset) begin S_awvalid=0; S_bwvalid=0; end
        else begin
            if (!S_awvalid || S_ataken) begin
                S_awvalid=S_asent<S_alimit; S_awdata=sample(0,S_asent+S_a_base);
            end
            if (!S_bwvalid || S_btaken) begin
                S_bwvalid=S_bsent<S_blimit; S_bwdata=sample(1,S_bsent+S_b_base);
            end
        end
    end
    audio_frame_fifo #(.ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4)) u_a_fifo (
        .I_write_clk(S_write_clk),.I_read_clk(S_clk),.I_async_flush(S_reset),
        .I_valid(S_awvalid),.O_ready(S_awr),.I_left(S_awdata),.I_right(~S_awdata),
        .O_valid(S_av),.I_ready(S_a_ready),.O_left(S_al),.O_right(S_ar),
        .O_write_level(S_awlevel),.O_read_level(S_arlevel),.O_prefilled(S_ap),.O_need_fill(S_an));
    audio_frame_fifo #(.ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4)) u_b_fifo (
        .I_write_clk(S_write_clk),.I_read_clk(S_clk),.I_async_flush(S_reset),
        .I_valid(S_bwvalid),.O_ready(S_bwr),.I_left(S_bwdata),.I_right(~S_bwdata),
        .O_valid(S_bv),.I_ready(S_b_ready),.O_left(S_bl),.O_right(S_br),
        .O_write_level(S_bwlevel),.O_read_level(S_brlevel),.O_prefilled(S_bp),.O_need_fill(S_bn));
    audio_playback #(.FIFO_ADDR_BITS(4),.FADE_SAMPLES(7)) u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),
        .I_a_stop(1'b0),.I_b_stop(1'b0),.I_a_clear(1'b0),.I_b_clear(1'b0),
        .O_a_idle(),.O_b_idle(),
        .I_a_valid(S_av),.I_b_valid(S_bv),.O_a_ready(S_a_ready),.O_b_ready(S_b_ready),
        .I_a_left(S_al),.I_a_right(S_ar),.I_b_left(S_bl),.I_b_right(S_br),
        .I_a_level(S_arlevel),.I_b_level(S_brlevel),.I_a_prefilled(S_ap),.I_b_prefilled(S_bp),
        .I_a_load_valid(S_a_load),.I_b_load_valid(S_b_load),
        .O_a_load_ready(S_a_lr),.O_b_load_ready(S_b_lr),
        .I_a_total_frames(S_a_total),.I_a_start_index(S_a_base),
        .I_b_total_frames(S_b_total),.I_b_start_index(S_b_base),
        .O_a_load_error(S_a_error),.O_b_load_error(S_b_error),
        .O_a_loaded(S_a_loaded),.O_b_loaded(S_b_loaded),
        .O_a_next_index(S_a_next),.O_b_next_index(S_b_next),.O_a_end(S_a_end),.O_b_end(S_b_end),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_fade_valid(S_fade),.O_fade_ready(S_fade_ready),.I_target_b(S_target),
        .I_pause(S_pause),.I_pause_allow(S_allow),.O_paused(S_paused),.O_pause_busy(S_pause_busy),
        .O_a_enabled(S_a_en),.O_b_enabled(S_b_en),
        .O_a_consumed(S_a_consumed),.O_b_consumed(S_b_consumed),
        .O_a_underrun(S_a_und),.O_b_underrun(S_b_und),.O_release_a(S_ra),.O_release_b(S_rb),
        .I_volume(5'd16),.I_mute(1'b0),.I_prompt_valid(1'b0),
        .I_prompt_left(24'd0),.I_prompt_right(24'd0),
        .O_sample_valid(S_valid),.O_left(S_left),.O_right(S_right),.O_clipped(S_clip),
        .O_fade_done(S_done),.O_active_b(S_active),.O_busy(S_busy),
        .I_silence_valid(1'b0),
        .O_silence_ready(S_silence_u_dut_O_silence_ready),
        .O_silence_started(S_silence_u_dut_O_silence_started),
        .O_silence_done(S_silence_u_dut_O_silence_done),
        .O_started(S_silence_u_dut_O_started)
    );

    // Independent cadence check: raw tick must emerge exactly four clocks later.
    always @(posedge S_clk or posedge S_reset) begin
        if (S_reset) S_valid_pipe=0;
        else begin
            S_valid_pipe={S_valid_pipe[3:0],S_tick};
            if (!S_tick && (S_a_ready || S_b_ready)) begin
                $display("FAIL: playback read ready outside sample tick"); $stop;
            end
            #1;
            if (S_valid!==S_valid_pipe[4]) begin $display("FAIL: playback valid alignment"); $stop; end
            if (S_valid) S_outputs=S_outputs+1;
        end
    end
    task idle;
        input integer count;
        integer k;
        begin
            for (k=0; k<count; k=k+1) begin
                @(negedge S_clk); S_tick=0;
                @(posedge S_clk); #2;
            end
        end
    endtask
    task pulse;
        input integer gain_a,gain_b,weight,pause_gain;
        input consume_a,consume_b,done,paused,underrun;
        reg [23:0] expected_l,expected_r;
        begin
            if (consume_a) begin
                S_eal=scaled(sample(0,S_ea),gain_a,64);
                S_ear=scaled(~sample(0,S_ea),gain_a,64);
            end
            if (consume_b) begin
                S_ebl=scaled(sample(1,S_eb),gain_b,64);
                S_ebr=scaled(~sample(1,S_eb),gain_b,64);
            end
            if (S_volume_gain<65536) S_volume_gain=S_volume_gain+1024;
            expected_l=mixed(S_eal,S_ebl,weight,S_volume_gain,pause_gain);
            expected_r=mixed(S_ear,S_ebr,weight,S_volume_gain,pause_gain);
            @(negedge S_clk); S_tick=1; #1;
            if ((S_a_ready && S_av)!==consume_a || (S_b_ready && S_bv)!==consume_b) begin
                $display("FAIL: playback read handshake at tick %0d",S_ticks); $stop;
            end
            @(posedge S_clk); #2;
            if (consume_a) S_ea=S_ea+1;
            if (consume_b) S_eb=S_eb+1;
            if (S_a_next!==S_ea || S_b_next!==S_eb ||
                S_a_consumed!==consume_a || S_b_consumed!==consume_b ||
                (S_a_und || S_b_und)!==underrun) begin
                $display("FAIL: playback index/consume/und at tick %0d indexes=%0d/%0d expected=%0d/%0d",
                    S_ticks,S_a_next,S_b_next,S_ea,S_eb); $stop;
            end
            if (underrun) S_unders=S_unders+1;
            idle(4);
            if (!S_valid || S_left!==expected_l || S_right!==expected_r || S_clip ||
                S_done!==done || S_paused!==paused) begin
                $display("FAIL: playback PCM/control tick %0d L/R=%h/%h expected=%h/%h done=%b pause=%b",
                    S_ticks,S_left,S_right,expected_l,expected_r,S_done,S_paused); $stop;
            end
            if (done) S_completions=S_completions+1;
            S_ticks=S_ticks+1;
        end
    endtask
    task new_epoch;
        input integer total_a,total_b,limit_a,limit_b,base_a;
        begin
            S_tick=0; S_start=0; S_fade=0; S_a_load=0; S_b_load=0; S_pause=0; S_allow=1;
            #2; S_reset=1;
            S_a_total=total_a; S_b_total=total_b; S_a_base=base_a; S_b_base=0;
            S_alimit=limit_a; S_blimit=limit_b;
            S_ea=base_a; S_eb=0; S_volume_gain=0; S_eal=0; S_ear=0; S_ebl=0; S_ebr=0;
            repeat (4) @(negedge S_clk);
            S_reset=0; idle(12);
            @(negedge S_clk);
            if (!S_a_lr || !S_b_lr) begin $display("FAIL: metadata load blocked"); $stop; end
            S_a_load=1; S_b_load=1;
            @(posedge S_clk); #2;
            if (!S_a_loaded || !S_b_loaded || S_a_error || S_b_error) begin
                $display("FAIL: metadata load"); $stop;
            end
            @(negedge S_clk); S_a_load=0; S_b_load=0;
            idle(4);
        end
    endtask
    task start_a;
        begin
            wait (S_start_ready);
            @(negedge S_clk); S_start=1;
            @(posedge S_clk); #2;
            @(negedge S_clk); S_start=0;
            idle(2);
        end
    endtask
    task fade_to;
        input target;
        begin
            @(negedge S_clk); S_target=target; #1;
            if (!S_fade_ready) begin $display("FAIL: prepared fade not ready"); $stop; end
            S_fade=1;
            @(posedge S_clk); #2;
            @(negedge S_clk); S_fade=0;
            idle(2);
        end
    endtask
    initial begin
        new_epoch(4000,4000,4000,4000,0); start_a;
        for (S_i=1; S_i<=64; S_i=S_i+1) pulse(S_i,0,0,64,1,0,0,0,0);
        if (S_b_next!=0 || S_b_en) begin $display("FAIL: inactive B consumed"); $stop; end
        fade_to(1);
        S_pause=1; // Must wait for this already accepted fade to drain.
        for (S_i=1; S_i<=7; S_i=S_i+1) pulse(64,S_i,(S_i*65536)/7,64,1,1,S_i==7,0,0);
        if (!S_ra || S_a_en || !S_b_en || !S_active) begin $display("FAIL: A release boundary"); $stop; end
        S_pause=1; S_allow=0;
        for (S_i=8; S_i<=10; S_i=S_i+1) pulse(0,S_i,65536,64,0,1,0,0,0);
        if (S_fade_ready || S_paused) begin $display("FAIL: pause allow/command gate"); $stop; end
        S_allow=1;
        for (S_i=63; S_i>=0; S_i=S_i-1)
            pulse(0,(74-S_i)>64 ? 64 : 74-S_i,65536,S_i,0,1,0,S_i==0,0);
        repeat (5) pulse(0,0,65536,0,0,0,0,1,0);
        if (!S_pause_busy) begin $display("FAIL: paused state"); $stop; end
        S_pause=0;
        for (S_i=1; S_i<=64; S_i=S_i+1) pulse(0,64,65536,S_i,0,1,0,0,0);
        if (S_pause_busy) begin $display("FAIL: resume did not finish"); $stop; end
        fade_to(0);
        for (S_i=1; S_i<=7; S_i=S_i+1) pulse(S_i,64,65536-(S_i*65536)/7,64,1,1,S_i==7,0,0);
        if (!S_rb || S_b_en || !S_a_en || S_active) begin $display("FAIL: B release boundary"); $stop; end

        // A resumed file fragment below normal prefill: absolute index 5..7.
        new_epoch(8,0,3,0,5); start_a;
        for (S_i=1; S_i<=3; S_i=S_i+1) pulse(S_i,0,0,64,1,0,0,0,0);
        if (!S_a_end || S_a_next!=8) begin $display("FAIL: short tail EOF/index"); $stop; end
        S_anchor_l=S_eal; S_anchor_r=S_ear;
        for (S_i=63; S_i>=0; S_i=S_i-1) begin
            S_eal=scaled(S_anchor_l,S_i,64); S_ear=scaled(S_anchor_r,S_i,64);
            pulse(0,0,0,64,0,0,0,0,0);
        end
        repeat (3) pulse(0,0,0,64,0,0,0,0,0);

        // Starvation is distinct from EOF. Later data reaches the same context.
        new_epoch(20,0,8,0,0); start_a;
        for (S_i=1; S_i<=8; S_i=S_i+1) pulse(S_i,0,0,64,1,0,0,0,0);
        S_anchor_l=S_eal; S_anchor_r=S_ear;
        for (S_i=63; S_i>=0; S_i=S_i-1) begin
            S_eal=scaled(S_anchor_l,S_i,64); S_ear=scaled(S_anchor_r,S_i,64);
            pulse(0,0,0,64,0,0,0,0,S_i==63);
        end
        repeat (3) pulse(0,0,0,64,0,0,0,0,0);
        S_alimit=20; wait (S_ap); idle(8);
        for (S_i=1; S_i<=12; S_i=S_i+1) pulse(S_i,0,0,64,1,0,0,0,0);
        if (!S_a_end || S_a_next!=20) begin $display("FAIL: starvation recovery index"); $stop; end

        new_epoch(0,0,0,0,0); start_a;
        repeat (5) pulse(0,0,0,64,0,0,0,0,0);
        // Bad metadata cannot activate an unused slot; it may be corrected later.
        @(negedge S_clk); S_b_base=1; S_b_load=1;
        @(posedge S_clk); #2;
        if (!S_b_error || S_b_loaded) begin $display("FAIL: invalid metadata accepted"); $stop; end
        @(negedge S_clk); S_b_load=0; idle(2);
        if (S_b_error) begin $display("FAIL: metadata error was not a pulse"); $stop; end
        @(negedge S_clk); S_b_base=0; S_b_load=1;
        @(posedge S_clk); #2;
        if (S_b_error || !S_b_loaded) begin $display("FAIL: corrected metadata rejected"); $stop; end
        @(negedge S_clk); S_b_load=0;
        if (!S_a_end || S_unders!=1 || S_completions!=2 || S_ticks!=S_outputs) begin
            $display("FAIL: playback totals ticks=%0d outputs=%0d und=%0d done=%0d",
                S_ticks,S_outputs,S_unders,S_completions); $stop;
        end
        S_test_pass=1;
        $display("PASS: actual dual-clock FIFOs, guard/mix alignment, pause/retained resume, release, tail/EOF and recovery");
        $finish;
    end
    initial begin #5000000; $display("FAIL: audio playback timeout"); $stop; end
endmodule
