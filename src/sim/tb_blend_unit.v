`timescale 1ns/1ps
// Golden arithmetic exists only in this unexecuted Verilog self-check.
module tb_blend_unit;
    reg S_clk=0,S_reset=0,S_test_pass=0;
    integer S_case=0;
    always #20 S_clk=~S_clk;
    task fail;
        input [767:0] message;
        begin $display("FAIL: blend_unit case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #1000000000; fail("watchdog timeout"); end
    reg S_I_valid=0;
    reg S_I_hsync=0;
    reg S_I_vsync=0;
    reg S_I_de=0;
    reg S_I_frame_start=0;
    reg S_I_line_start=0;
    reg [15:0] S_I_x=0;
    reg [15:0] S_I_y=0;
    reg [23:0] S_I_a_rgb=0;
    reg [23:0] S_I_b_rgb=0;
    reg S_I_use_a=0;
    reg S_I_use_b=0;
    reg [16:0] S_I_weight=0;
    reg [31:0] S_I_epoch=0;
    reg [15:0] S_I_tag=0;
    wire S_O_valid;
    wire S_O_hsync;
    wire S_O_vsync;
    wire S_O_de;
    wire S_O_frame_start;
    wire S_O_line_start;
    wire [15:0] S_O_x;
    wire [15:0] S_O_y;
    wire [23:0] S_O_rgb;
    wire [31:0] S_O_epoch;
    wire [15:0] S_O_tag;
    wire S_O_weight_error;
    blend_unit u_dut (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_valid(S_I_valid),
        .I_hsync(S_I_hsync),
        .I_vsync(S_I_vsync),
        .I_de(S_I_de),
        .I_frame_start(S_I_frame_start),
        .I_line_start(S_I_line_start),
        .I_x(S_I_x),
        .I_y(S_I_y),
        .I_a_rgb(S_I_a_rgb),
        .I_b_rgb(S_I_b_rgb),
        .I_use_a(S_I_use_a),
        .I_use_b(S_I_use_b),
        .I_weight(S_I_weight),
        .I_epoch(S_I_epoch),
        .I_tag(S_I_tag),
        .O_valid(S_O_valid),
        .O_hsync(S_O_hsync),
        .O_vsync(S_O_vsync),
        .O_de(S_O_de),
        .O_frame_start(S_O_frame_start),
        .O_line_start(S_O_line_start),
        .O_x(S_O_x),
        .O_y(S_O_y),
        .O_rgb(S_O_rgb),
        .O_epoch(S_O_epoch),
        .O_tag(S_O_tag),
        .O_weight_error(S_O_weight_error)
    );
    reg S_expected_valid=0;
    reg [109:0] S_expected=0,S_current;
    integer S_sent=0,S_checked=0,S_weight,S_c,S_sum;
    reg [23:0] S_a,S_b,S_rgb;
    always @(posedge S_clk) begin
        if(S_reset) S_expected_valid=0;
        else begin
            S_weight=S_I_weight>65536 ? 65536 : S_I_weight;
            S_a=S_I_use_a ? S_I_a_rgb : 24'd0; S_b=S_I_use_b ? S_I_b_rgb : 24'd0; S_rgb=0;
            for(S_c=0;S_c<3;S_c=S_c+1) begin
                S_sum=(S_a[S_c*8+:8]*(65536-S_weight)+S_b[S_c*8+:8]*S_weight+32768)/65536;
                if(S_sum>255) S_sum=255;
                S_rgb[S_c*8+:8]=S_sum;
            end
            S_current={S_I_hsync,S_I_vsync,S_I_de,S_I_frame_start,S_I_line_start,S_I_x,S_I_y,
                S_I_de ? S_rgb : 24'd0,S_I_epoch,S_I_tag,S_I_weight>65536};
            #1;
            if(S_O_valid!==S_expected_valid) fail("blend valid pipeline latency");
            if(S_expected_valid) begin
                if({S_O_hsync,S_O_vsync,S_O_de,S_O_frame_start,S_O_line_start,S_O_x,S_O_y,S_O_rgb,
                    S_O_epoch,S_O_tag,S_O_weight_error}!==S_expected) fail("RGB channels/control/identity reference mismatch");
                S_checked=S_checked+1;
            end
            S_expected=S_current; S_expected_valid=S_I_valid;
        end
    end
    task sample;
        input [23:0] a,b;
        input [16:0] weight;
        input use_a,use_b,de;
        begin
            @(negedge S_clk); S_I_valid=1; S_I_a_rgb=a; S_I_b_rgb=b; S_I_weight=weight;
            S_I_use_a=use_a; S_I_use_b=use_b; S_I_de=de;
            S_I_x=S_sent%640; S_I_y=(S_sent/640)%480;
            S_I_hsync=S_sent%7==0; S_I_vsync=S_sent%11==0;
            S_I_frame_start=S_sent%307200==0; S_I_line_start=S_sent%640==0;
            S_I_epoch=32'h76540000+S_sent; S_I_tag=S_sent;
            S_sent=S_sent+1;
        end
    endtask
    task drain;
        begin
            @(negedge S_clk); S_I_valid=0; repeat(3) @(negedge S_clk);
            if(S_sent!=S_checked) fail("lost/duplicated pixel");
        end
    endtask
    integer w,c,a,b;
    reg [23:0] rgb_a,rgb_b;
    initial begin
        S_reset=1; repeat(4) @(negedge S_clk); S_reset=0;
        // Every legal Q16 weight, asymmetric color channels and endpoint rounding.
        for(w=0;w<=65536;w=w+1) begin
            rgb_a={w[7:0],(8'hff-w[7:0]),(8'h55^w[7:0])};
            rgb_b={(8'haa^w[7:0]),w[15:8],(8'h33+w[7:0])};
            sample(rgb_a,rgb_b,w,1,1,1);
        end
        for(c=0;c<3;c=c+1) for(a=0;a<256;a=a+1) begin
            rgb_a=0; rgb_b=0; rgb_a[c*8+:8]=a; rgb_b[(c+1)%3*8+:8]=255-a;
            sample(rgb_a,rgb_b,32768,1,1,1);
        end
        for(a=0;a<2;a=a+1) for(b=0;b<2;b=b+1) begin
            sample(24'hffffff,24'hffffff,0,a,b,1);
            sample(24'hffffff,24'hffffff,32768,a,b,1);
            sample(24'hffffff,24'hffffff,65536,a,b,1);
            sample(24'hffffff,24'hffffff,65537,a,b,1);
            sample(24'h123456,24'hfedcba,131071,a,b,0);
        end
        drain;
        // Sparse valid and repeated bubbles cannot skew the controls or the channels.
        for(w=0;w<512;w=w+1) begin
            sample(24'hf0017f,24'h0280ff,w*127,1,1,w%3!=0);
            @(negedge S_clk); S_I_valid=0;
            repeat(w%4) @(negedge S_clk);
        end
        drain;
        sample(24'hffffff,24'h000000,32768,1,1,1);
        @(negedge S_clk); S_I_valid=0; S_reset=1;
        repeat(3) @(negedge S_clk); S_reset=0; S_sent=0; S_checked=0;
        if(S_O_valid) fail("reset did not clear pending output");
        sample(24'h112233,24'habcdef,65536,1,1,1); drain;
        S_test_pass=1; $display("PASS: blend_unit all Q16 weights/channel isolation/control latency"); $finish;
    end
endmodule
