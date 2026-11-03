// Independent 50 MHz domain. Its output must NEVER reset this detector itself.
module key_long_reset #(
    parameter integer DEBOUNCE_CYCLES=1000000,
    parameter integer HOLD_CYCLES=150000000
) (
    input wire I_clk,I_startup_reset,I_key_n,
    output wire O_global_reset
);
    reg S_meta,S_sync,S_pressed;
    reg [31:0] S_debounce,S_hold;
    reg S_long;
    assign O_global_reset=S_long && S_pressed;
    always @(posedge I_clk or posedge I_startup_reset) begin
        if(I_startup_reset) begin
            S_meta<=1; S_sync<=1; S_pressed<=0; S_debounce<=0; S_hold<=0; S_long<=0;
        end else begin
            S_meta<=I_key_n; S_sync<=S_meta;
            if(S_pressed==!S_sync) S_debounce<=0;
            else if(S_debounce==DEBOUNCE_CYCLES-1) begin S_pressed<=!S_sync; S_debounce<=0; end
            else S_debounce<=S_debounce+1'b1;
            if(!S_pressed) begin S_hold<=0; S_long<=0; end
            else if(!S_long) begin
                if(S_hold==HOLD_CYCLES-1) S_long<=1;
                else S_hold<=S_hold+1'b1;
            end
        end
    end
endmodule
