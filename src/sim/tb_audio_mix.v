`timescale 1ns/1ps
module tb_audio_mix;
    wire [3:0] S_done;
    reg S_test_pass=0;
    audio_mix_case #(9600) u_production(S_done[0]);
    audio_mix_case #(7) u_fractional(S_done[1]);
    audio_mix_case #(1) u_single(S_done[2]);
    audio_mix_case #(65536) u_maximum(S_done[3]);
    initial begin
        wait (&S_done); S_test_pass=1;
        $display("PASS: audio mix PCM reference, volume/mute, saturation, exact fades and pipeline reset");
        $finish;
    end
    initial begin #20000000; $display("FAIL: audio mix timeout"); $stop; end
endmodule

module audio_mix_case #(parameter integer N=9600) (output reg O_done);
    wire S_silence_u_dut_O_silent;
    wire S_silence_u_dut_O_fade_started;
    reg S_clk=0,S_reset=0,S_tick=0,S_command=0,S_target=0;
    reg [23:0] S_al=0,S_ar=0,S_bl=0,S_br=0;
    reg [4:0] S_volume=16;
    reg S_mute=0,S_prompt=0;
    wire S_ready,S_valid,S_busy,S_done,S_active,S_clipped;
    wire [23:0] S_left,S_right;
    wire [16:0] S_gain,S_volume_gain;
    integer S_expected_gain=0,S_reference_volume=0,S_sequence=0;
    reg S_expected_last=0,S_reference_active=0;
    reg S_ev[0:2],S_ed[0:2];
    reg [24:0] S_el[0:2],S_er[0:2];
    integer S_eg[0:2],S_ew[0:2];
    integer S_i,S_k,S_target_volume,S_delta,S_outputs=0,S_completions=0,S_clips=0;
    reg [23:0] S_held_l,S_held_r;
    reg [16:0] S_held_g,S_held_v;
    reg S_held_clip;
    always #20 S_clk=~S_clk;
    audio_mix #(.FADE_SAMPLES(N)) u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_sample_tick(S_tick),
        .I_a_left(S_al),.I_a_right(S_ar),.I_b_left(S_bl),.I_b_right(S_br),
        .I_volume(S_volume),.I_mute(S_mute),.I_prompt_valid(S_prompt),
        .I_prompt_left(24'h7fffff),.I_prompt_right(24'h800000),
        .I_fade_valid(S_command),.O_fade_ready(S_ready),.I_target_b(S_target),
        .O_sample_valid(S_valid),.O_left(S_left),.O_right(S_right),.O_clipped(S_clipped),
        .O_gain_b(S_gain),.O_volume_gain(S_volume_gain),.O_busy(S_busy),
        .O_fade_done(S_done),.O_active_b(S_active),
        .I_target_silent(1'b0),
        .O_silent(S_silence_u_dut_O_silent),
        .O_fade_started(S_silence_u_dut_O_fade_started)
    );

    function signed [63:0] floor_q16;
        input signed [63:0] value;
        begin
            if (value<0) floor_q16=-((-value+65535)/65536);
            else floor_q16=value/65536;
        end
    endfunction
    function [24:0] reference;
        input [23:0] a,b,prompt;
        input integer gain,volume;
        reg signed [63:0] av,bv,pv,result;
        begin
            av=$signed(a); bv=$signed(b); pv=$signed(prompt);
            result=floor_q16(av*(65536-gain)+bv*gain);
            result=floor_q16((result+pv)*volume);
            if (result>8388607) reference={1'b1,24'h7fffff};
            else if (result< -8388608) reference={1'b1,24'h800000};
            else reference={1'b0,result[23:0]};
        end
    endfunction
    // Three-slot expected pipeline. No DUT internals or DDA recurrence in the model.
    always @(posedge S_clk or posedge S_reset) begin
        if (S_reset) begin
            for (S_i=0; S_i<3; S_i=S_i+1) begin
                S_ev[S_i]=0; S_ed[S_i]=0;
                S_el[S_i]=0; S_er[S_i]=0; S_eg[S_i]=0; S_ew[S_i]=0;
            end
            S_reference_volume=0; S_reference_active=0;
            #1;
            if (S_valid || S_done || S_ready || S_busy || S_active || S_left!=0 || S_right!=0) begin
                $display("FAIL in %m: asynchronous reset"); $stop;
            end
        end else if (!O_done) begin
            S_held_l=S_left; S_held_r=S_right;
            S_held_g=S_gain; S_held_v=S_volume_gain; S_held_clip=S_clipped;
            for (S_i=2; S_i>0; S_i=S_i-1) begin
                S_ev[S_i]=S_ev[S_i-1]; S_ed[S_i]=S_ed[S_i-1];
                S_el[S_i]=S_el[S_i-1]; S_er[S_i]=S_er[S_i-1];
                S_eg[S_i]=S_eg[S_i-1]; S_ew[S_i]=S_ew[S_i-1];
            end
            S_ev[0]=S_tick; S_ed[0]=S_tick && S_expected_last;
            if (S_tick) begin
                S_target_volume=S_mute ? 0 : (S_volume>16 ? 65536 : S_volume*4096);
                S_delta=S_target_volume-S_reference_volume;
                if (S_delta>1024) S_delta=1024;
                if (S_delta< -1024) S_delta=-1024;
                S_reference_volume=S_reference_volume+S_delta;
                S_el[0]=reference(S_al,S_bl,S_prompt ? 24'h7fffff : 24'd0,
                    S_expected_gain,S_reference_volume);
                S_er[0]=reference(S_ar,S_br,S_prompt ? 24'h800000 : 24'd0,
                    S_expected_gain,S_reference_volume);
                S_eg[0]=S_expected_gain; S_ew[0]=S_reference_volume;
            end
            if (S_ed[2]) S_reference_active=(S_eg[2]!=0);
            #1;
            if (S_valid!==S_ev[2] || S_done!==S_ed[2] || S_active!==S_reference_active) begin
                $display("FAIL in %m: valid/done/active alignment outputs=%0d",S_outputs); $stop;
            end
            if (S_ev[2]) begin
                if (S_left!==S_el[2][23:0] || S_right!==S_er[2][23:0] ||
                    S_clipped!==(S_el[2][24] || S_er[2][24]) ||
                    S_gain!==S_eg[2] || S_volume_gain!==S_ew[2]) begin
                    $display("FAIL in %m: PCM/gain output %0d L/R=%h/%h expected=%h/%h B=%0d/%0d V=%0d/%0d",
                        S_outputs,S_left,S_right,S_el[2][23:0],S_er[2][23:0],
                        S_gain,S_eg[2],S_volume_gain,S_ew[2]); $stop;
                end
                S_outputs=S_outputs+1;
                if (S_clipped) S_clips=S_clips+1;
            end else if (S_left!==S_held_l || S_right!==S_held_r ||
                S_gain!==S_held_g || S_volume_gain!==S_held_v || S_clipped!==S_held_clip) begin
                $display("FAIL in %m: payload changed without valid"); $stop;
            end
            if (S_done) begin
                S_completions=S_completions+1;
                if (S_busy || !S_ready) begin $display("FAIL in %m: completion did not release busy"); $stop; end
            end
        end
    end
    task payload;
        begin
            case (S_sequence%6)
                0: begin S_al=24'h7fffff; S_ar=24'h800000; S_bl=24'h800000; S_br=24'h7fffff; end
                1: begin S_al=24'hffffff; S_ar=1; S_bl=1; S_br=24'hffffff; end
                2: begin S_al=24'h7fffff; S_ar=24'h7fffff; S_bl=S_al; S_br=S_ar; end
                3: begin S_al=24'h800000; S_ar=24'h800000; S_bl=S_al; S_br=S_ar; end
                default: begin
                    S_al=24'h123457*S_sequence; S_ar=~S_al;
                    S_bl=24'h9abcdf*S_sequence; S_br=~S_bl;
                end
            endcase
            S_sequence=S_sequence+1;
        end
    endtask
    task send;
        input integer gain;
        input last;
        begin
            @(negedge S_clk);
            S_tick=1; S_command=0; S_expected_gain=gain; S_expected_last=last; payload;
            @(posedge S_clk); #2;
        end
    endtask
    task idle;
        input integer cycles;
        integer index;
        begin
            for (index=0; index<cycles; index=index+1) begin
                @(negedge S_clk); S_tick=0; S_command=0; S_expected_last=0;
                @(posedge S_clk); #2;
            end
        end
    endtask
    task command;
        input target,with_sample;
        begin
            @(negedge S_clk);
            if (!S_ready) begin $display("FAIL in %m: idle command not ready"); $stop; end
            S_command=1; S_target=target; S_tick=with_sample;
            S_expected_gain=S_active ? 65536 : 0; S_expected_last=0; payload;
            @(posedge S_clk); #2;
            if (!S_busy || S_ready) begin $display("FAIL in %m: command was not accepted"); $stop; end
        end
    endtask
    task reset_mix;
        begin
            S_tick=0; S_command=0; S_expected_last=0;
            #2; S_reset=1; #2;
            @(negedge S_clk); S_reset=0;
        end
    endtask
    initial begin
        O_done=0;
        reset_mix; idle(5);
        repeat (70) send(0,0);
        for (S_k=0; S_k<32; S_k=S_k+1) begin
            S_volume=S_k;
            repeat (70) send(0,0);
        end
        S_mute=1; repeat (70) send(0,0);
        S_mute=0; repeat (70) send(0,0);
        // Retarget a volume ramp before settling, at sample boundaries.
        S_volume=0; repeat (9) send(0,0);
        S_volume=12; repeat (11) send(0,0);
        S_volume=16; repeat (70) send(0,0);
        S_prompt=1; repeat (70) send(0,0); S_prompt=0;
        command(1,1); idle(5);
        if (!S_busy || S_active || S_ready) begin $display("FAIL in %m: no-tick fade advanced"); $stop; end
        for (S_k=1; S_k<=N; S_k=S_k+1) begin
            send((64'd65536*S_k)/N,S_k==N);
            if (!S_busy || S_ready) begin $display("FAIL in %m: ready during A to B fade"); $stop; end
            if (S_k<N && S_k%257==0) idle(2);
        end
        if (!S_busy) begin $display("FAIL in %m: early release on final input"); $stop; end
        idle(1);
        if (!S_busy) begin $display("FAIL in %m: early release while pipeline drains"); $stop; end
        idle(3);
        if (S_busy || !S_active) begin $display("FAIL in %m: A to B endpoint"); $stop; end
        command(0,0);
        for (S_k=1; S_k<=N; S_k=S_k+1) begin
            // 64-bit intermediate prevents overflow for N=65536.
            send(65536-(64'd65536*S_k)/N,S_k==N);
            if (!S_busy || S_ready) begin $display("FAIL in %m: ready during B to A fade"); $stop; end
            if (S_k<N && S_k%251==0) idle(1);
        end
        idle(4);
        if (S_busy || S_active) begin $display("FAIL in %m: B to A endpoint"); $stop; end
        command(0,0); send(0,1); idle(4);
        // Cancel a command and a nonempty data pipeline before any final output.
        command(1,0); send(65536/N,N==1);
        reset_mix; idle(5); repeat (5) send(0,0); idle(4);
        if (S_completions!=3 || S_clips==0 || S_busy || !S_ready) begin
            $display("FAIL in %m: totals done=%0d clips=%0d",S_completions,S_clips); $stop;
        end
        O_done=1;
    end
endmodule
