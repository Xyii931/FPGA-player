`timescale 1ns/1ps
module tb_video_pattern_axis;
    wire [5:0] S_done;
    reg S_test_pass = 1'b0;
    video_pattern_axis_case #(8, 4) u_small(S_done[0]);
    video_pattern_axis_case #(640, 480) u_full(S_done[1]);
    video_pattern_axis_case #(1, 1) u_single(S_done[2]);
    video_pattern_axis_case #(2, 2) u_two(S_done[3]);
    video_pattern_axis_case #(3, 2) u_odd(S_done[4]);
    video_pattern_axis_case #(257, 2) u_gray_boundary(S_done[5]);
    initial begin
        wait (&S_done);
        S_test_pass = 1'b1;
        $display("PASS: AXIS patterns, SOF/EOL, backpressure, frame mode and reset");
        $finish;
    end
    initial begin
        #200000000;
        $display("FAIL: AXIS pattern test timeout"); $stop;
    end
endmodule

module video_pattern_axis_case #(
    parameter integer W = 8, H = 4
) (output reg O_done);
    reg S_clk = 1'b0;
    reg S_reset = 1'b0;
    reg S_ready = 1'b0;
    reg [1:0] S_pattern = 2'd0;
    wire S_valid, S_user, S_last;
    wire [23:0] S_data;
    reg [15:0] S_lfsr = 16'hcafe;
    integer S_x = 0, S_y = 0, S_frames = 0, S_mode = 0;
    integer S_cycles = 0, S_stalls = 0, S_accepts = 0;
    integer S_last_stall_frame = -1, S_hold = 0;
    reg S_was_stalled = 1'b0;
    reg [25:0] S_held_payload;
    reg S_force_stall = 1'b0;
    always #20 S_clk = ~S_clk;
    video_pattern_axis #(.ACTIVE_W(W), .ACTIVE_H(H)) u_dut (
        .I_clk(S_clk), .I_reset(S_reset), .I_pattern(S_pattern), .I_ready(S_ready),
        .O_valid(S_valid), .O_user(S_user), .O_last(S_last), .O_data(S_data)
    );
    function [23:0] color;
        input integer mode, x, y;
        integer gray, bar;
        begin
            color = 0;
            case (mode)
                0: begin
                    bar = x * 8 / W;
                    case (bar)
                        0: color = 24'hffffff;
                        1: color = 24'hffff00;
                        2: color = 24'h00ffff;
                        3: color = 24'h00ff00;
                        4: color = 24'hff00ff;
                        5: color = 24'hff0000;
                        6: color = 24'h0000ff;
                        default: color = 0;
                    endcase
                end
                1: begin
                    gray = 0;
                    if (W > 1) gray = x * 255 / (W-1);
                    color = {gray[7:0], gray[7:0], gray[7:0]};
                end
                2: if (x == 0 || y == 0 || x == W-1 || y == H-1 || x == W/2 || y == H/2)
                    color = 24'hffffff;
                3: if ((x+y) % 2) color = 24'hffffff;
            endcase
        end
    endfunction
    // Drive between edges; deterministic random bursts plus guaranteed EOL stalls.
    always @(negedge S_clk) begin
        if (S_reset) begin
            S_ready = 1'b0;
            S_pattern = 2'd0;
            S_cycles = 0;
            S_last_stall_frame = -1;
            S_hold = 0;
        end else if (!O_done) begin
            S_cycles = S_cycles + 1;
            S_lfsr = {S_lfsr[14:0], S_lfsr[15]^S_lfsr[13]^S_lfsr[12]^S_lfsr[10]};
            if (S_valid) S_pattern = (S_frames + 1) % 4;
            if (S_valid && S_x == W-1 && S_y == 0 && S_last_stall_frame != S_frames) begin
                S_last_stall_frame = S_frames;
                S_hold = 5;
            end
            S_ready = !S_force_stall && S_cycles > 12 && S_hold == 0 &&
                (S_frames == 2 || (S_cycles % 37 >= 8 && S_lfsr[0]));
            if (S_hold > 0) S_hold = S_hold - 1;
        end
    end
    // Compare only at protocol sampling edges, never inspect DUT coordinates.
    always @(posedge S_clk) begin
        if (S_reset) begin
            S_x = 0; S_y = 0; S_frames = 0; S_mode = 0;
            S_stalls = 0; S_accepts = 0; S_was_stalled = 1'b0;
        end else if (!O_done) begin
            if (S_was_stalled && (!S_valid || {S_user, S_last, S_data} !== S_held_payload)) begin
                $display("FAIL in %m: payload changed under backpressure"); $stop;
            end
            if (S_valid) begin
                if (S_user !== (S_x == 0 && S_y == 0) || S_last !== (S_x == W-1) ||
                    S_data !== color(S_mode, S_x, S_y)) begin
                    $display("FAIL in %m: frame=%0d xy=%0d,%0d mode=%0d data=%h",
                        S_frames, S_x, S_y, S_mode, S_data); $stop;
                end
                if (!S_ready) S_stalls = S_stalls + 1;
            end
            S_was_stalled = S_valid && !S_ready;
            S_held_payload = {S_user, S_last, S_data};
            if (S_valid && S_ready) begin
                S_accepts = S_accepts + 1;
                if (S_x == W-1) begin
                    S_x = 0;
                    if (S_y == H-1) begin
                        S_y = 0;
                        S_frames = S_frames + 1;
                        S_mode = S_pattern;
                    end else S_y = S_y + 1;
                end else S_x = S_x + 1;
            end
        end
    end
    initial begin
        O_done = 1'b0;
        #1; S_reset = 1'b1;
        repeat (2) @(posedge S_clk);
        #2; S_reset = 1'b0;
        wait (S_frames == 4);
        if (S_accepts != 4*W*H || S_stalls < 20) begin
            $display("FAIL in %m: coverage totals"); $stop;
        end
        // Cancel a held transaction, then require SOF/first pixel after reset.
        @(posedge S_clk); #2; S_force_stall = 1'b1;
        repeat (8) @(posedge S_clk);
        #2; S_reset = 1'b1;
        #1;
        if ({S_valid, S_user, S_last, S_data} !== 27'd0) begin
            $display("FAIL in %m: reset while stalled"); $stop;
        end
        repeat (2) @(posedge S_clk);
        #2; S_force_stall = 1'b0; S_reset = 1'b0;
        wait (S_frames == 1);
        #2; O_done = 1'b1;
    end
endmodule
