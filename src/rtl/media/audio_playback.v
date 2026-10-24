// Read-domain integration. External FIFOs own CDC/storage and shared flushing.
// Metadata must already be synchronized. This block does not identify old writes.
module audio_playback #(
    parameter integer FIFO_ADDR_BITS=11,
    parameter integer FADE_SAMPLES=9600
) (
    input wire I_clk,I_reset,I_sample_tick,
    input wire I_a_stop,I_b_stop,I_a_clear,I_b_clear,
    output wire O_a_idle,O_b_idle,
    input wire I_a_valid,I_b_valid,
    output wire O_a_ready,O_b_ready,
    input wire [23:0] I_a_left,I_a_right,I_b_left,I_b_right,
    input wire [FIFO_ADDR_BITS:0] I_a_level,I_b_level,
    input wire I_a_prefilled,I_b_prefilled,
    input wire I_a_load_valid,I_b_load_valid,
    output wire O_a_load_ready,O_b_load_ready,
    input wire [31:0] I_a_total_frames,I_a_start_index,I_b_total_frames,I_b_start_index,
    output reg O_a_load_error,O_b_load_error,O_a_loaded,O_b_loaded,
    output reg [31:0] O_a_next_index,O_b_next_index,
    output wire O_a_end,O_b_end,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire I_fade_valid,I_target_b,
    output wire O_fade_ready,
    input wire I_silence_valid,
    output wire O_silence_ready,O_silence_started,
    output reg O_silence_done,
    input wire I_pause,I_pause_allow,
    output wire O_paused,O_pause_busy,
    output reg O_a_enabled,O_b_enabled,
    output wire O_a_consumed,O_b_consumed,O_a_underrun,O_b_underrun,
    output reg O_release_a,O_release_b,
    input wire [4:0] I_volume,
    input wire I_mute,I_prompt_valid,
    input wire [23:0] I_prompt_left,I_prompt_right,
    output reg O_sample_valid,
    output reg [23:0] O_left,O_right,
    output reg O_clipped,O_fade_done,O_active_b,
    output wire O_busy,O_started
);
    localparam [2:0] RUN=0,FADE_OUT=1,DRAIN=2,PAUSED=3,FADE_IN=4;
    reg [2:0] S_pause_state;
    reg [6:0] S_pause_gain;
    reg S_started,S_switching,S_target_b,S_target_silent,S_mix_command,S_mix_tick;
    reg [31:0] S_a_total,S_b_total;
    wire [31:0] S_a_remaining=S_a_total-O_a_next_index;
    wire [31:0] S_b_remaining=S_b_total-O_b_next_index;
    wire S_a_tail=O_a_loaded && S_a_remaining!=0 && I_a_valid && I_a_level>=S_a_remaining;
    wire S_b_tail=O_b_loaded && S_b_remaining!=0 && I_b_valid && I_b_level>=S_b_remaining;
    wire S_a_prepared=O_a_loaded && (O_a_end || (I_a_valid && (I_a_prefilled || S_a_tail)));
    wire S_b_prepared=O_b_loaded && (O_b_end || (I_b_valid && (I_b_prefilled || S_b_tail)));
    wire S_a_running,S_b_running;
    wire S_a_resume=O_a_end || (I_a_valid && (S_a_running || I_a_prefilled || S_a_tail));
    wire S_b_resume=O_b_end || (I_b_valid && (S_b_running || I_b_prefilled || S_b_tail));
    wire S_resume_ready=(!O_a_enabled || S_a_resume) && (!O_b_enabled || S_b_resume);
    wire S_resume=S_pause_state==PAUSED && !I_pause && S_resume_ready;
    wire S_mix_busy,S_mix_ready,S_mix_valid,S_mix_done,S_mix_started,S_mix_active,S_mix_silent,S_mix_clip;
    wire [23:0] S_mix_left,S_mix_right;
    wire S_pause_request=I_pause && I_pause_allow && !S_switching && !S_mix_busy;
    wire S_guard_run=S_pause_state==RUN || S_pause_state==FADE_OUT ||
        S_pause_state==FADE_IN || S_resume;
    wire [6:0] S_gain_now=(S_pause_state==RUN) ? (S_pause_request ? 7'd63 : 7'd64) :
        ((S_pause_state==FADE_OUT) ? S_pause_gain-7'd1 :
        ((S_pause_state==FADE_IN) ? S_pause_gain+7'd1 : (S_resume ? 7'd1 : 7'd0)));
    wire S_pause_zero=I_sample_tick && S_pause_state==FADE_OUT && S_pause_gain==1;
    wire S_a_load=I_a_load_valid && O_a_load_ready;
    wire S_b_load=I_b_load_valid && O_b_load_ready;
    wire S_start=I_start_valid && O_start_ready;
    wire S_fade=I_fade_valid && O_fade_ready;
    wire S_silence=I_silence_valid && O_silence_ready;
    wire S_a_guard_reset=I_reset || I_a_clear || S_a_load || S_start || (S_fade && !I_target_b && O_active_b);
    wire S_b_guard_reset=I_reset || I_b_clear || S_b_load || (S_fade && I_target_b && !O_active_b);
    wire S_a_guard_ready,S_b_guard_ready;
    wire S_a_data_valid=I_a_valid && O_a_loaded && !O_a_end;
    wire S_b_data_valid=I_b_valid && O_b_loaded && !O_b_end;
    wire [23:0] S_a_left,S_a_right,S_b_left,S_b_right;
    wire S_a_sample_valid,S_b_sample_valid,S_a_waiting,S_b_waiting,S_a_fading,S_b_fading;
    wire [16:0] S_mix_gain,S_mix_volume;
    reg [4:0] S_volume;
    reg S_mute,S_prompt_valid;
    reg [23:0] S_prompt_left,S_prompt_right;
    reg [6:0] S_gain_pipe [0:3];
    reg [3:0] S_zero_pipe;
    integer S_pipe_index;
    reg [2:0] S_a_drain,S_b_drain;

    assign O_a_end=O_a_loaded && O_a_next_index==S_a_total;
    assign O_b_end=O_b_loaded && O_b_next_index==S_b_total;
    assign O_a_ready=S_a_guard_ready && O_a_loaded && !O_a_end;
    assign O_b_ready=S_b_guard_ready && O_b_loaded && !O_b_end;
    assign O_a_load_ready=!I_reset && !I_a_stop && !I_a_clear && !O_a_enabled && !S_switching && !I_start_valid && !I_fade_valid && !I_silence_valid;
    assign O_b_load_ready=!I_reset && !I_b_stop && !I_b_clear && !O_b_enabled && !S_switching && !I_start_valid && !I_fade_valid && !I_silence_valid;
    assign O_start_ready=!I_reset && !I_a_stop && !I_b_stop && !I_a_clear && !I_b_clear && !S_started && !I_pause && S_pause_state==RUN &&
        S_a_prepared && !I_a_load_valid && !I_silence_valid;
    assign O_fade_ready=!I_reset && !I_a_stop && !I_b_stop && !I_a_clear && !I_b_clear && S_started && !S_switching && S_mix_ready &&
        !I_pause && S_pause_state==RUN && !I_start_valid && !I_silence_valid &&
        (I_target_b ? (S_b_prepared && !I_b_load_valid) : (S_a_prepared && !I_a_load_valid));
    assign O_silence_ready=!I_reset && !I_a_stop && !I_b_stop && !I_a_clear && !I_b_clear &&
        !S_switching && S_mix_ready && !I_pause && S_pause_state==RUN;
    // Registered mixer fact; the consumer observes the first input sample one clock later.
    assign O_silence_started=S_mix_started && S_target_silent;
    assign O_paused=S_pause_state==PAUSED;
    assign O_pause_busy=I_pause || S_pause_state!=RUN;
    assign O_busy=S_switching;
    // Lifetime playback admission state; slot recycling deliberately preserves it.
    assign O_started=S_started;
    assign O_a_idle=I_a_stop && !O_a_enabled && !S_switching && S_a_drain==5;
    assign O_b_idle=I_b_stop && !O_b_enabled && !S_switching && S_b_drain==5;

    // After guard zero, wait the entire fixed audio pipeline, not FIFO empty.
    // This state belongs to the global owner and survives a per-slot clear.
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin S_a_drain<=0; S_b_drain<=0; end
        else begin
            if (!I_a_stop || O_a_enabled || S_switching || !S_a_waiting || S_a_left!=0 || S_a_right!=0)
                S_a_drain<=0;
            else if (S_a_drain<5) S_a_drain<=S_a_drain+3'd1;
            if (!I_b_stop || O_b_enabled || S_switching || !S_b_waiting || S_b_left!=0 || S_b_right!=0)
                S_b_drain<=0;
            else if (S_b_drain<5) S_b_drain<=S_b_drain+3'd1;
        end
    end

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_a_total<=0; S_b_total<=0; O_a_next_index<=0; O_b_next_index<=0;
            O_a_loaded<=0; O_b_loaded<=0; O_a_load_error<=0; O_b_load_error<=0;
        end else begin
            O_a_load_error<=0; O_b_load_error<=0;
            if (I_a_clear) begin
                S_a_total<=0; O_a_next_index<=0; O_a_loaded<=0;
            end else if (S_a_load) begin
                O_a_loaded<=(I_a_start_index<=I_a_total_frames);
                O_a_load_error<=I_a_start_index>I_a_total_frames;
                S_a_total<=I_a_total_frames; O_a_next_index<=I_a_start_index;
            end else if (I_a_valid && O_a_ready) O_a_next_index<=O_a_next_index+32'd1;
            if (I_b_clear) begin
                S_b_total<=0; O_b_next_index<=0; O_b_loaded<=0;
            end else if (S_b_load) begin
                O_b_loaded<=(I_b_start_index<=I_b_total_frames);
                O_b_load_error<=I_b_start_index>I_b_total_frames;
                S_b_total<=I_b_total_frames; O_b_next_index<=I_b_start_index;
            end else if (I_b_valid && O_b_ready) O_b_next_index<=O_b_next_index+32'd1;
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_started<=0; S_switching<=0; S_target_b<=0; S_target_silent<=0; S_mix_command<=0;
            O_a_enabled<=0; O_b_enabled<=0; O_release_a<=0; O_release_b<=0;
        end else begin
            S_mix_command<=S_fade || S_silence;
            O_release_a<=0; O_release_b<=0;
            if (I_a_stop || I_a_clear) O_a_enabled<=0;
            if (I_b_stop || I_b_clear) O_b_enabled<=0;
            if (S_start) begin S_started<=1; O_a_enabled<=1; end
            if (S_fade) begin
                S_switching<=1; S_target_b<=I_target_b; S_target_silent<=0;
                if (I_target_b) O_b_enabled<=1;
                else O_a_enabled<=1;
            end
            if(S_silence) begin
                S_started<=1; S_switching<=1; S_target_b<=O_active_b; S_target_silent<=1;
            end
            if (S_mix_done) begin
                S_switching<=0;
                if(S_mix_silent) begin
                    O_release_a<=O_a_enabled; O_release_b<=O_b_enabled;
                    O_a_enabled<=0; O_b_enabled<=0;
                end else if (S_mix_active) begin
                    O_release_a<=O_a_enabled; O_a_enabled<=0;
                end else begin
                    O_release_b<=O_b_enabled; O_b_enabled<=0;
                end
            end
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin S_pause_state<=RUN; S_pause_gain<=64; end
        else begin
            if (I_sample_tick) begin
                S_pause_gain<=S_gain_now;
                case (S_pause_state)
                    RUN: if (S_pause_request) S_pause_state<=FADE_OUT;
                    FADE_OUT: if (S_gain_now==0) S_pause_state<=DRAIN;
                    PAUSED: if (S_resume) S_pause_state<=FADE_IN;
                    FADE_IN: if (S_gain_now==64) S_pause_state<=RUN;
                    default: begin end
                endcase
            end
            if (S_mix_valid && S_zero_pipe[3] && S_pause_state==DRAIN) S_pause_state<=PAUSED;
        end
    end
    // Both guards see the original tick except while their state is frozen by pause.
    audio_track_guard u_a_guard (
        .I_clk(I_clk),.I_reset(S_a_guard_reset),.I_sample_tick(I_sample_tick && (S_guard_run || I_a_stop)),
        .I_enable(O_a_enabled && !I_a_stop && !I_a_clear),.I_valid(S_a_data_valid),.O_ready(S_a_guard_ready),
        .I_left(I_a_left),.I_right(I_a_right),.I_prefilled(I_a_prefilled),
        .I_tail_ready(S_a_tail),.I_end(O_a_end),.O_sample_valid(S_a_sample_valid),
        .O_left(S_a_left),.O_right(S_a_right),.O_consumed(O_a_consumed),.O_underrun(O_a_underrun),
        .O_waiting(S_a_waiting),.O_running(S_a_running),.O_fading(S_a_fading));
    audio_track_guard u_b_guard (
        .I_clk(I_clk),.I_reset(S_b_guard_reset),.I_sample_tick(I_sample_tick && (S_guard_run || I_b_stop)),
        .I_enable(O_b_enabled && !I_b_stop && !I_b_clear),.I_valid(S_b_data_valid),.O_ready(S_b_guard_ready),
        .I_left(I_b_left),.I_right(I_b_right),.I_prefilled(I_b_prefilled),
        .I_tail_ready(S_b_tail),.I_end(O_b_end),.O_sample_valid(S_b_sample_valid),
        .O_left(S_b_left),.O_right(S_b_right),.O_consumed(O_b_consumed),.O_underrun(O_b_underrun),
        .O_waiting(S_b_waiting),.O_running(S_b_running),.O_fading(S_b_fading));
    audio_mix #(.FADE_SAMPLES(FADE_SAMPLES)) u_mix (
        .I_clk(I_clk),.I_reset(I_reset),.I_sample_tick(S_mix_tick),
        .I_a_left(S_a_left),.I_a_right(S_a_right),.I_b_left(S_b_left),.I_b_right(S_b_right),
        .I_volume(S_volume),.I_mute(S_mute),.I_prompt_valid(S_prompt_valid),
        .I_prompt_left(S_prompt_left),.I_prompt_right(S_prompt_right),
        .I_fade_valid(S_mix_command),.O_fade_ready(S_mix_ready),.I_target_b(S_target_b),.I_target_silent(S_target_silent),
        .O_sample_valid(S_mix_valid),.O_left(S_mix_left),.O_right(S_mix_right),
        .O_clipped(S_mix_clip),.O_gain_b(S_mix_gain),.O_volume_gain(S_mix_volume),
        .O_busy(S_mix_busy),.O_fade_done(S_mix_done),.O_fade_started(S_mix_started),.O_active_b(S_mix_active),.O_silent(S_mix_silent));

    function [23:0] pause_scale;
        input signed [23:0] sample;
        input [6:0] gain;
        reg signed [31:0] product;
        begin product=sample*$signed({1'b0,gain}); pause_scale=product >>> 6; end
    endfunction
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_mix_tick<=0; S_volume<=0; S_mute<=0; S_prompt_valid<=0;
            S_prompt_left<=0; S_prompt_right<=0; S_zero_pipe<=0;
            for (S_pipe_index=0; S_pipe_index<4; S_pipe_index=S_pipe_index+1) S_gain_pipe[S_pipe_index]<=0;
            O_sample_valid<=0; O_left<=0; O_right<=0;
            O_clipped<=0; O_fade_done<=0; O_silence_done<=0; O_active_b<=0;
        end else begin
            S_mix_tick<=I_sample_tick;
            S_gain_pipe[0]<=S_gain_now;
            for (S_pipe_index=1; S_pipe_index<4; S_pipe_index=S_pipe_index+1)
                S_gain_pipe[S_pipe_index]<=S_gain_pipe[S_pipe_index-1];
            S_zero_pipe<={S_zero_pipe[2:0],S_pause_zero};
            if (I_sample_tick) begin
                S_volume<=I_volume; S_mute<=I_mute; S_prompt_valid<=I_prompt_valid;
                S_prompt_left<=I_prompt_left; S_prompt_right<=I_prompt_right;
            end
            O_sample_valid<=S_mix_valid;
            O_fade_done<=S_mix_done;
            O_silence_done<=S_mix_done && S_target_silent;
            if (S_mix_valid) begin
                O_left<=pause_scale(S_mix_left,S_gain_pipe[3]);
                O_right<=pause_scale(S_mix_right,S_gain_pipe[3]); O_clipped<=S_mix_clip;
            end
            if (S_mix_done) O_active_b<=S_mix_active;
        end
    end
endmodule
