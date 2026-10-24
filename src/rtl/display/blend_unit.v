// Two stages, three simultaneous channels, one sample each video clock.
module blend_unit (
    input wire I_clk,I_reset,I_valid,I_hsync,I_vsync,I_de,I_frame_start,I_line_start,
    input wire [15:0] I_x,I_y,
    input wire [23:0] I_a_rgb,I_b_rgb,
    input wire I_use_a,I_use_b,
    input wire [16:0] I_weight,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    output reg O_valid,O_hsync,O_vsync,O_de,O_frame_start,O_line_start,
    output reg [15:0] O_x,O_y,
    output reg [23:0] O_rgb,
    output reg [31:0] O_epoch,
    output reg [15:0] O_tag,
    output reg O_weight_error
);
    wire [16:0] S_weight=I_weight>65536 ? 17'd65536 : I_weight;
    wire [16:0] S_a_weight=17'd65536-S_weight;
    wire [23:0] S_a=I_use_a ? I_a_rgb : 24'd0;
    wire [23:0] S_b=I_use_b ? I_b_rgb : 24'd0;
    reg [24:0] S_ar,S_ag,S_ab,S_br,S_bg,S_bb;
    wire [25:0] S_r={1'b0,S_ar}+{1'b0,S_br}+26'd32768;
    wire [25:0] S_g={1'b0,S_ag}+{1'b0,S_bg}+26'd32768;
    wire [25:0] S_blue={1'b0,S_ab}+{1'b0,S_bb}+26'd32768;
    reg S_valid,S_hsync,S_vsync,S_de,S_frame_start,S_line_start,S_weight_error;
    reg [15:0] S_x,S_y,S_tag;
    reg [31:0] S_epoch;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_ar<=0; S_ag<=0; S_ab<=0; S_br<=0; S_bg<=0; S_bb<=0;
            S_valid<=0; S_hsync<=0; S_vsync<=0; S_de<=0; S_frame_start<=0; S_line_start<=0;
            S_weight_error<=0; S_x<=0; S_y<=0; S_epoch<=0; S_tag<=0;
            O_valid<=0; O_hsync<=0; O_vsync<=0; O_de<=0; O_frame_start<=0; O_line_start<=0;
            O_x<=0; O_y<=0; O_epoch<=0; O_tag<=0; O_rgb<=0; O_weight_error<=0;
        end else begin
            S_ar<=S_a[23:16]*S_a_weight; S_ag<=S_a[15:8]*S_a_weight; S_ab<=S_a[7:0]*S_a_weight;
            S_br<=S_b[23:16]*S_weight; S_bg<=S_b[15:8]*S_weight; S_bb<=S_b[7:0]*S_weight;
            S_valid<=I_valid; S_hsync<=I_hsync; S_vsync<=I_vsync; S_de<=I_de;
            S_frame_start<=I_frame_start; S_line_start<=I_line_start; S_weight_error<=I_weight>65536;
            S_x<=I_x; S_y<=I_y; S_epoch<=I_epoch; S_tag<=I_tag;
            O_valid<=S_valid; O_hsync<=S_hsync; O_vsync<=S_vsync; O_de<=S_de;
            O_frame_start<=S_frame_start; O_line_start<=S_line_start; O_x<=S_x; O_y<=S_y;
            O_epoch<=S_epoch; O_tag<=S_tag; O_weight_error<=S_weight_error;
            O_rgb<=!S_de ? 24'd0 : {S_r[25:16]>255 ? 8'hff : S_r[23:16],
                S_g[25:16]>255 ? 8'hff : S_g[23:16],S_blue[25:16]>255 ? 8'hff : S_blue[23:16]};
        end
    end
endmodule
