// Design04 section6 fixed-point formulas. No latency or throughput change.
// Caller commits parameters at a real raster frame boundary.
module video_color_adjust (
    input wire I_de,
    input wire [23:0] I_rgb,
    input wire [3:0] I_brightness,I_contrast,
    input wire [4:0] I_saturation,
    output wire [23:0] O_rgb
);
    function [7:0] clamp;
        input signed [15:0] value;
        begin clamp=value<0 ? 8'd0 : value>255 ? 8'd255 : value[7:0]; end
    endfunction
    function [7:0] contrast;
        input [7:0] channel;
        input [3:0] setting;
        reg signed [8:0] delta;
        reg signed [4:0] gain;
        reg signed [13:0] product;
        reg signed [15:0] rounded;
        begin
            delta=$signed({1'b0,channel})-9'sd128;
            gain=5'sd8+$signed({setting[3],setting});
            product=delta*gain;
            rounded=(($signed({{2{product[13]}},product})+16'sd4)>>>3)+16'sd128;
            contrast=clamp(rounded);
        end
    endfunction
    function [7:0] saturate;
        input [7:0] channel,gray;
        input [4:0] setting;
        reg signed [8:0] delta;
        reg signed [14:0] product;
        reg signed [15:0] rounded;
        begin
            delta=$signed({1'b0,channel})-$signed({1'b0,gray});
            product=delta*$signed({1'b0,setting});
            rounded=(($signed({product[14],product})+16'sd4)>>>3)+$signed({8'd0,gray});
            saturate=clamp(rounded);
        end
    endfunction
    function [7:0] brighten;
        input [7:0] channel;
        input [3:0] setting;
        reg signed [15:0] result;
        begin
            result=$signed({8'd0,channel})+($signed({{12{setting[3]}},setting})<<<4);
            brighten=clamp(result);
        end
    endfunction
    wire [7:0] S_r=contrast(I_rgb[23:16],I_contrast);
    wire [7:0] S_g=contrast(I_rgb[15:8],I_contrast);
    wire [7:0] S_b=contrast(I_rgb[7:0],I_contrast);
    wire [16:0] S_luma=17'd77*S_r+17'd150*S_g+17'd29*S_b+17'd128;
    wire [7:0] S_gray=S_luma[15:8];
    assign O_rgb=!I_de ? 24'd0 : {
        brighten(saturate(S_r,S_gray,I_saturation),I_brightness),
        brighten(saturate(S_g,S_gray,I_saturation),I_brightness),
        brighten(saturate(S_b,S_gray,I_saturation),I_brightness)};
endmodule
