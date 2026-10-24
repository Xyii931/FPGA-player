// Read-domain, single-track starvation envelope. Not a PAUSE controller.
// External context owns EOF, tail readiness, consumed index and late recovery.
// Assert reset at startup; release it synchronously in this clock domain.
module audio_track_guard (
    input wire I_clk, I_reset, I_sample_tick, I_enable,
    input wire I_valid,
    output wire O_ready,
    input wire [23:0] I_left, I_right,
    input wire I_prefilled, I_tail_ready, I_end,
    output reg O_sample_valid,
    output reg [23:0] O_left, O_right,
    output reg O_consumed, O_underrun,
    output wire O_waiting, O_running, O_fading
);
    localparam [1:0] WAIT_FILL=0, PLAY=1, FADE=2;
    reg [1:0] S_state;
    reg [6:0] S_gain, S_remaining;
    reg [23:0] S_anchor_left, S_anchor_right;
    wire [6:0] S_next_gain = S_gain<7'd64 ? S_gain+7'd1 : 7'd64;
    wire S_fire = I_valid && O_ready;

    function [23:0] scale;
        input signed [23:0] value;
        input [6:0] gain;
        reg signed [31:0] product;
        begin
            product = value * $signed({1'b0,gain});
            scale = product >>> 6;
        end
    endfunction

    assign O_ready = !I_reset && I_sample_tick && I_enable &&
        ((S_state==PLAY) || (S_state==WAIT_FILL && (I_prefilled || I_tail_ready)));
    assign O_waiting = S_state==WAIT_FILL;
    assign O_running = S_state==PLAY;
    assign O_fading = S_state==FADE;

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state <= WAIT_FILL;
            S_gain <= 0; S_remaining <= 0;
            S_anchor_left <= 0; S_anchor_right <= 0;
            O_sample_valid <= 0; O_left <= 0; O_right <= 0;
            O_consumed <= 0; O_underrun <= 0;
        end else begin
            O_sample_valid <= I_sample_tick;
            O_consumed <= S_fire;
            O_underrun <= 0;
            if (I_sample_tick) begin
                case (S_state)
                    WAIT_FILL: begin
                        if (S_fire) begin
                            O_left <= scale(I_left,7'd1);
                            O_right <= scale(I_right,7'd1);
                            S_gain <= 7'd1;
                            S_state <= PLAY;
                        end else begin
                            O_left <= 0; O_right <= 0;
                        end
                    end
                    PLAY: begin
                        if (S_fire) begin
                            O_left <= scale(I_left,S_next_gain);
                            O_right <= scale(I_right,S_next_gain);
                            S_gain <= S_next_gain;
                        end else begin
                            // Count this first missing/stopped sample as fade step 1.
                            S_anchor_left <= O_left; S_anchor_right <= O_right;
                            O_left <= scale(O_left,7'd63);
                            O_right <= scale(O_right,7'd63);
                            S_remaining <= 7'd62;
                            S_gain <= 0;
                            S_state <= FADE;
                            O_underrun <= I_enable && !I_end;
                        end
                    end
                    FADE: begin
                        O_left <= scale(S_anchor_left,S_remaining);
                        O_right <= scale(S_anchor_right,S_remaining);
                        if (S_remaining==0) S_state <= WAIT_FILL;
                        else S_remaining <= S_remaining-7'd1;
                    end
                    default: begin
                        S_state <= WAIT_FILL; S_gain <= 0;
                        O_left <= 0; O_right <= 0;
                    end
                endcase
            end
        end
    end
endmodule
