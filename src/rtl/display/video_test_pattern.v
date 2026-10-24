module video_test_pattern #(
    parameter integer ACTIVE_W = 640, ACTIVE_H = 480
) (
    input wire I_clk, I_reset,
    input wire I_hsync, I_vsync, I_de,
    input wire [15:0] I_x, I_y,
    input wire I_frame_start, I_line_start,
    input wire [1:0] I_pattern,
    output reg O_hsync, O_vsync, O_de,
    output reg [15:0] O_x, O_y,
    output reg O_frame_start, O_line_start,
    output reg [23:0] O_rgb
);
    reg [1:0] S_pattern;
    reg [23:0] S_rgb;
    reg [7:0] S_gray;
    reg [31:0] S_bar;
    always @* begin
        S_rgb = 24'h000000;
        S_gray = 8'd0;
        S_bar = 32'd0;
        if (I_de) begin
            case (S_pattern)
                2'd0: begin
                    S_bar = (I_x * 32'd8) / ACTIVE_W;
                    case (S_bar)
                        0: S_rgb = 24'hffffff;
                        1: S_rgb = 24'hffff00;
                        2: S_rgb = 24'h00ffff;
                        3: S_rgb = 24'h00ff00;
                        4: S_rgb = 24'hff00ff;
                        5: S_rgb = 24'hff0000;
                        6: S_rgb = 24'h0000ff;
                        default: S_rgb = 24'h000000;
                    endcase
                end
                2'd1: begin
                    if (ACTIVE_W > 1) S_gray = (I_x * 32'd255) / (ACTIVE_W-1);
                    S_rgb = {S_gray, S_gray, S_gray};
                end
                2'd2: begin
                    if (I_x == 0 || I_x == ACTIVE_W-1 || I_y == 0 ||
                        I_y == ACTIVE_H-1 || I_x == ACTIVE_W/2 || I_y == ACTIVE_H/2)
                        S_rgb = 24'hffffff;
                end
                2'd3: S_rgb = (I_x[0] ^ I_y[0]) ? 24'hffffff : 24'h000000;
            endcase
        end
    end
    // RGB and all controls have exactly the same one-cycle latency.
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_pattern <= 2'd0;
            O_hsync <= 1'b1;
            O_vsync <= 1'b1;
            O_de <= 1'b0;
            O_x <= 16'd0;
            O_y <= 16'd0;
            O_frame_start <= 1'b0;
            O_line_start <= 1'b0;
            O_rgb <= 24'd0;
        end else begin
            if (I_frame_start) S_pattern <= I_pattern;
            O_hsync <= I_hsync;
            O_vsync <= I_vsync;
            O_de <= I_de;
            O_x <= I_x;
            O_y <= I_y;
            O_frame_start <= I_frame_start;
            O_line_start <= I_line_start;
            O_rgb <= S_rgb;
        end
    end
    // synthesis translate_off
    initial begin
        if (ACTIVE_W < 1 || ACTIVE_H < 1 || ACTIVE_W > 65536 || ACTIVE_H > 65536) begin
            $display("FAIL: video_test_pattern invalid active dimensions"); $stop;
        end
    end
    // synthesis translate_on
endmodule
