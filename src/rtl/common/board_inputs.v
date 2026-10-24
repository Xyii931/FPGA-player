// Host-domain stable input levels and release events. Independent bit debounce.
// KEY1 long hold globally resets this domain; no PREV is emitted on its release.
module board_inputs #(
    parameter integer DEBOUNCE_CYCLES=2500000
) (
    input wire I_clk,I_reset,
    input wire [3:0] I_key_n,I_switch,
    output wire [3:0] O_keys,O_switch,
    output wire [3:0] O_key_release,O_switch_changed,
    output reg O_switch_initialized
);
    reg [7:0] S_meta,S_sync,S_level;
    reg [7:0] S_changed,S_seen;
    assign O_keys=S_level[3:0];
    assign O_switch=S_level[7:4];
    assign O_key_release=S_changed[3:0] & ~S_level[3:0];
    assign O_switch_changed=S_changed[7:4];
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin S_meta<=0; S_sync<=0; O_switch_initialized<=0; end
        else begin
            S_meta<={I_switch,~I_key_n}; S_sync<=S_meta;
            O_switch_initialized<=&S_seen[7:4];
        end
    end
    genvar g;
    generate for(g=0;g<8;g=g+1) begin:g_input
        reg [31:0] S_count;
        always @(posedge I_clk or posedge I_reset) begin
            if(I_reset) begin S_count<=0; S_level[g]<=0; S_changed[g]<=0; S_seen[g]<=0; end
            else begin
                S_changed[g]<=0;
                if(!S_seen[g]) begin
                    // Restart startup sampling whenever this individual input changes.
                    if(S_sync[g]!=S_meta[g]) S_count<=0;
                    else if(S_count==DEBOUNCE_CYCLES-1) begin
                        S_seen[g]<=1; S_level[g]<=S_sync[g]; S_count<=0;
                        if(g>=4) S_changed[g]<=1;
                    end else S_count<=S_count+1'b1;
                end else if(S_sync[g]==S_level[g]) S_count<=0;
                else if(S_count==DEBOUNCE_CYCLES-1) begin
                    S_level[g]<=S_sync[g]; S_count<=0; S_changed[g]<=1;
                end else S_count<=S_count+1'b1;
            end
        end
    end endgenerate
endmodule
