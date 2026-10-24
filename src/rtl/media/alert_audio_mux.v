// Final 48 kHz PCM stage. Alert tone remains audible while source tracks are paused.
// Respect the same volume and hard/user mute; no track/FIFO lifecycle changes.
module alert_audio_mux (
    input wire I_clk,I_reset,I_alert,I_sample_valid,I_mute,
    input wire [4:0] I_volume,
    input wire [23:0] I_left,I_right,
    output reg O_sample_valid,
    output reg [23:0] O_left,O_right
);
    reg [15:0] S_period;
    reg [4:0] S_phase;
    reg S_negative;
    reg [6:0] S_envelope;
    wire S_on=I_alert && S_period<16'd24000;
    wire [6:0] S_next_gain=S_on ? (S_envelope<64 ? S_envelope+1'b1 : 7'd64) :
        (S_envelope!=0 ? S_envelope-1'b1 : 7'd0);
    wire [4:0] S_volume=I_volume>16 ? 5'd16 : I_volume;
    wire [31:0] S_amplitude={25'd0,S_next_gain}*{27'd0,S_volume}*32'd1024;
    wire [23:0] S_tone=I_mute ? 24'd0 : (S_negative ? 24'd0-S_amplitude[23:0] : S_amplitude[23:0]);
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_period<=0; S_phase<=0; S_negative<=0; S_envelope<=0;
            O_sample_valid<=0; O_left<=0; O_right<=0;
        end else begin
            O_sample_valid<=I_sample_valid;
            if(I_sample_valid) begin
                S_envelope<=S_next_gain;
                if(!I_alert) begin S_period<=0; S_phase<=0; S_negative<=0; end
                else begin
                    S_period<=S_period==47999 ? 16'd0 : S_period+1'b1;
                    if(S_phase==23) begin S_phase<=0; S_negative<=!S_negative; end
                    else S_phase<=S_phase+1'b1;
                end
                if(I_alert || S_envelope!=0) begin O_left<=S_tone; O_right<=S_tone; end
                else begin O_left<=I_left; O_right<=I_right; end
            end
        end
    end
endmodule
