// Pixel-domain arithmetic core after two aligned audio_track_guard outputs.
// No FIFO consumption/context ownership. Assert reset at startup, release in-domain.
module audio_mix #(
    parameter integer FADE_SAMPLES=9600
) (
    input wire I_clk, I_reset, I_sample_tick,
    input wire [23:0] I_a_left, I_a_right, I_b_left, I_b_right,
    input wire [4:0] I_volume,
    input wire I_mute,
    input wire I_prompt_valid,
    input wire [23:0] I_prompt_left, I_prompt_right,
    input wire I_fade_valid,
    output wire O_fade_ready,
    input wire I_target_b,I_target_silent,
    output reg O_sample_valid,
    output reg [23:0] O_left, O_right,
    output reg O_clipped,
    output reg [16:0] O_gain_b, O_volume_gain,
    output wire O_busy,
    output reg O_fade_done,O_fade_started, O_active_b,O_silent
);
    // Guard denominator even for an invalid parameter; simulation reports it below.
    localparam integer DENOM = FADE_SAMPLES<1 ? 1 : FADE_SAMPLES;
    localparam integer STEP = 65536/DENOM;
    localparam integer REMAINDER = 65536%DENOM;
    reg S_busy, S_target_b, S_target_silent,S_input_done;
    reg [16:0] S_progress, S_remainder, S_count, S_volume;
    wire [17:0] S_remainder_sum = {1'b0,S_remainder}+REMAINDER;
    wire S_carry = S_remainder_sum>=DENOM;
    wire [16:0] S_progress_next = S_progress+STEP+S_carry;
    wire [16:0] S_remainder_next = S_carry ? S_remainder_sum-DENOM : S_remainder_sum;
    wire S_same=S_target_silent==O_silent && (S_target_silent || S_target_b==O_active_b);
    wire S_last = S_busy && !S_input_done && (S_same || S_count==DENOM-1);
    wire [16:0] S_blend=(S_input_done || S_same) ? 17'd65536 : S_progress_next;
    wire [16:0] S_gain_b = !S_busy ? ((!O_silent && O_active_b) ? 17'd65536 : 17'd0) :
        ((!O_silent && O_active_b) ? 17'd65536-S_blend : 17'd0)+
        ((!S_target_silent && S_target_b) ? S_blend : 17'd0);
    wire [16:0] S_gain_a = !S_busy ? ((!O_silent && !O_active_b) ? 17'd65536 : 17'd0) :
        ((!O_silent && !O_active_b) ? 17'd65536-S_blend : 17'd0)+
        ((!S_target_silent && !S_target_b) ? S_blend : 17'd0);
    wire [4:0] S_volume_clamped = I_volume>5'd16 ? 5'd16 : I_volume;
    wire [16:0] S_volume_target = I_mute ? 17'd0 : {S_volume_clamped,12'b0};
    wire [16:0] S_volume_distance = S_volume_target>S_volume ?
        S_volume_target-S_volume : S_volume-S_volume_target;
    wire [16:0] S_volume_next = S_volume_distance<=17'd1024 ? S_volume_target :
        (S_volume_target>S_volume ? S_volume+17'd1024 : S_volume-17'd1024);

    reg S_valid_1, S_valid_2, S_last_1, S_last_2;
    reg signed [41:0] S_al, S_ar, S_bl, S_br;
    reg signed [23:0] S_prompt_l, S_prompt_r;
    reg signed [26:0] S_mix_l, S_mix_r;
    reg [16:0] S_gain_b_1, S_gain_b_2, S_volume_1, S_volume_2;
    wire signed [42:0] S_sum_l = $signed({S_al[41],S_al}) +
        $signed({S_bl[41],S_bl}) + $signed({{3{S_prompt_l[23]}},S_prompt_l,16'b0});
    wire signed [42:0] S_sum_r = $signed({S_ar[41],S_ar}) +
        $signed({S_br[41],S_br}) + $signed({{3{S_prompt_r[23]}},S_prompt_r,16'b0});
    wire [24:0] S_result_l, S_result_r;

    function [24:0] attenuate;
        input signed [26:0] sample;
        input [16:0] gain;
        reg signed [44:0] product,scaled;
        begin
            product=sample*$signed({1'b0,gain});
            scaled=product >>> 16;
            if (scaled>45'sd8388607) attenuate={1'b1,24'h7fffff};
            else if (scaled< -45'sd8388608) attenuate={1'b1,24'h800000};
            else attenuate={1'b0,scaled[23:0]};
        end
    endfunction
    assign S_result_l=attenuate(S_mix_l,S_volume_2);
    assign S_result_r=attenuate(S_mix_r,S_volume_2);
    assign O_fade_ready=!I_reset && !S_busy;
    assign O_busy=S_busy;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) O_fade_started<=0;
        else O_fade_started<=I_sample_tick && S_busy && !S_input_done && S_count==0;
    end

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_busy<=0; S_target_b<=0; S_target_silent<=0; S_input_done<=0;
            S_progress<=0; S_remainder<=0; S_count<=0; S_volume<=0;
            O_active_b<=0; O_silent<=0;
        end else begin
            if (I_fade_valid && O_fade_ready) begin
                S_busy<=1; S_target_b<=I_target_b; S_target_silent<=I_target_silent; S_input_done<=0;
                S_progress<=0; S_remainder<=0; S_count<=0;
            end
            if (I_sample_tick) begin
                S_volume<=S_volume_next;
                if (S_busy && !S_input_done) begin
                    S_progress<=S_progress_next;
                    S_remainder<=S_remainder_next;
                    S_count<=S_count+17'd1;
                    if (S_last) S_input_done<=1;
                end
            end
            // Release only when the marked final sample exits the data pipeline.
            if (S_valid_2 && S_last_2) begin
                S_busy<=0; S_input_done<=0; O_active_b<=S_target_b; O_silent<=S_target_silent;
            end
        end
    end

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_valid_1<=0; S_last_1<=0;
            S_al<=0; S_ar<=0; S_bl<=0; S_br<=0;
            S_prompt_l<=0; S_prompt_r<=0; S_gain_b_1<=0; S_volume_1<=0;
        end else begin
            S_valid_1<=I_sample_tick;
            S_last_1<=I_sample_tick && S_last;
            if (I_sample_tick) begin
                S_al<=$signed(I_a_left)*$signed({1'b0,S_gain_a});
                S_ar<=$signed(I_a_right)*$signed({1'b0,S_gain_a});
                S_bl<=$signed(I_b_left)*$signed({1'b0,S_gain_b});
                S_br<=$signed(I_b_right)*$signed({1'b0,S_gain_b});
                S_prompt_l<=I_prompt_valid ? I_prompt_left : 24'd0;
                S_prompt_r<=I_prompt_valid ? I_prompt_right : 24'd0;
                S_gain_b_1<=S_gain_b; S_volume_1<=S_volume_next;
            end
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_valid_2<=0; S_last_2<=0; S_mix_l<=0; S_mix_r<=0;
            S_gain_b_2<=0; S_volume_2<=0;
        end else begin
            S_valid_2<=S_valid_1;
            S_last_2<=S_valid_1 && S_last_1;
            if (S_valid_1) begin
                S_mix_l<=S_sum_l >>> 16; S_mix_r<=S_sum_r >>> 16;
                S_gain_b_2<=S_gain_b_1; S_volume_2<=S_volume_1;
            end
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            O_sample_valid<=0; O_fade_done<=0; O_clipped<=0;
            O_left<=0; O_right<=0; O_gain_b<=0; O_volume_gain<=0;
        end else begin
            O_sample_valid<=S_valid_2;
            O_fade_done<=S_valid_2 && S_last_2;
            if (S_valid_2) begin
                O_left<=S_result_l[23:0]; O_right<=S_result_r[23:0];
                O_clipped<=S_result_l[24] || S_result_r[24];
                O_gain_b<=S_gain_b_2; O_volume_gain<=S_volume_2;
            end
        end
    end
    // synthesis translate_off
    initial begin
        if (FADE_SAMPLES<1 || FADE_SAMPLES>65536) begin
            $display("FAIL: audio_mix FADE_SAMPLES must be 1..65536"); $stop;
        end
    end
    // synthesis translate_on
endmodule
