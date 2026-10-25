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
    localparam [16:0] GRAY_DENOM = (ACTIVE_W > 1) ? ACTIVE_W-1 : 1;
    localparam [7:0] GRAY_STEP = 255 / GRAY_DENOM;
    localparam [15:0] GRAY_REMAINDER = 255 % GRAY_DENOM;
    reg [7:0] S_gray;
    reg [15:0] S_gray_error;
    wire [16:0] S_gray_next_error = {1'b0,S_gray_error} + {1'b0,GRAY_REMAINDER};
    assign O_user = O_valid && S_x == 0 && S_y == 0;
    assign O_last = O_valid && S_x == ACTIVE_W-1;
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            O_valid <= 1'b0;
            S_x <= 16'd0;
            S_y <= 16'd0;
            S_pattern <= 2'd0;
            S_gray <= 8'd0;
            S_gray_error <= 16'd0;
        end else if (!O_valid) begin
            O_valid <= 1'b1;
            S_pattern <= I_pattern;
        end else if (I_ready) begin
            if (S_x == ACTIVE_W-1) begin
                S_x <= 16'd0;
                S_gray <= 8'd0;
                S_gray_error <= 16'd0;
                if (S_y == ACTIVE_H-1) begin
                    S_y <= 16'd0;
                    S_pattern <= I_pattern;
                end else S_y <= S_y + 1'b1;
            end else begin
                S_x <= S_x + 1'b1;
                // Exact floor(x*255/(W-1)), advancing only with accepted pixels.
                // Quotient/remainder constants avoid a pixel-path divider or DSP.
                if (S_gray_next_error >= GRAY_DENOM) begin
                    S_gray <= S_gray + GRAY_STEP + 8'd1;
                    S_gray_error <= S_gray_next_error - GRAY_DENOM;
                end else begin
                    S_gray <= S_gray + GRAY_STEP;
                    S_gray_error <= S_gray_next_error[15:0];
                end
            end
        end
    end
    always @* begin
        O_data = 24'd0;
        if (O_valid) begin
            case (S_pattern)
                2'd0: begin
                    // ceil(k*W/8) boundaries preserve floor(x*8/W) for any W.
                    if      (S_x < (  ACTIVE_W+7)/8) O_data = 24'hffffff;
                    else if (S_x < (2*ACTIVE_W+7)/8) O_data = 24'hffff00;
                    else if (S_x < (3*ACTIVE_W+7)/8) O_data = 24'h00ffff;
                    else if (S_x < (4*ACTIVE_W+7)/8) O_data = 24'h00ff00;
                    else if (S_x < (5*ACTIVE_W+7)/8) O_data = 24'hff00ff;
                    else if (S_x < (6*ACTIVE_W+7)/8) O_data = 24'hff0000;
                    else if (S_x < (7*ACTIVE_W+7)/8) O_data = 24'h0000ff;
                end
                2'd1: begin
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
