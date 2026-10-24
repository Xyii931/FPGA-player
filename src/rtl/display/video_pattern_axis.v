// Active pixels only. The HDMI IP owns the output raster and applies backpressure.
module video_pattern_axis #(
    parameter integer ACTIVE_W = 640, ACTIVE_H = 480
) (
    input wire I_clk, I_reset,
    input wire [1:0] I_pattern,
    input wire I_ready,
    output reg O_valid,
    output wire O_user, O_last,
    output reg [23:0] O_data
);
    reg [15:0] S_x, S_y;
    reg [1:0] S_pattern;
    reg [31:0] S_bar;
    reg [7:0] S_gray;
    assign O_user = O_valid && S_x == 0 && S_y == 0;
    assign O_last = O_valid && S_x == ACTIVE_W-1;
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            O_valid <= 1'b0;
            S_x <= 16'd0;
            S_y <= 16'd0;
            S_pattern <= 2'd0;
        end else if (!O_valid) begin
            O_valid <= 1'b1;
            S_pattern <= I_pattern;
        end else if (I_ready) begin
            if (S_x == ACTIVE_W-1) begin
                S_x <= 16'd0;
                if (S_y == ACTIVE_H-1) begin
                    S_y <= 16'd0;
                    S_pattern <= I_pattern;
                end else S_y <= S_y + 1'b1;
            end else S_x <= S_x + 1'b1;
        end
    end
    always @* begin
        O_data = 24'd0;
        S_bar = 32'd0;
        S_gray = 8'd0;
        if (O_valid) begin
            case (S_pattern)
                2'd0: begin
                    S_bar = (S_x * 32'd8) / ACTIVE_W;
                    case (S_bar)
                        0: O_data = 24'hffffff;
                        1: O_data = 24'hffff00;
                        2: O_data = 24'h00ffff;
                        3: O_data = 24'h00ff00;
                        4: O_data = 24'hff00ff;
                        5: O_data = 24'hff0000;
                        6: O_data = 24'h0000ff;
                        default: O_data = 24'h000000;
                    endcase
                end
                2'd1: begin
                    // Generate a black single-pixel ramp without division by zero.
                    S_gray = (S_x * 32'd255) / ((ACTIVE_W > 1) ? ACTIVE_W-1 : 1);
                    O_data = {S_gray, S_gray, S_gray};
                end
                2'd2: if (S_x == 0 || S_x == ACTIVE_W-1 || S_y == 0 ||
                    S_y == ACTIVE_H-1 || S_x == ACTIVE_W/2 || S_y == ACTIVE_H/2)
                    O_data = 24'hffffff;
                2'd3: O_data = (S_x[0] ^ S_y[0]) ? 24'hffffff : 24'h000000;
            endcase
        end
    end
    // synthesis translate_off
    initial begin
        if (ACTIVE_W < 1 || ACTIVE_H < 1 || ACTIVE_W > 65536 || ACTIVE_H > 65536) begin
            $display("FAIL: video_pattern_axis invalid geometry"); $stop;
        end
    end
    // synthesis translate_on
endmodule
