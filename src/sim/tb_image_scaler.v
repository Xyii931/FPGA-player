`timescale 1ns/1ps
module tb_image_scaler;
    reg S_clk=0, S_reset=0, S_start=0, S_abort=0, S_stream_error=0;
    reg [15:0] S_sw=1,S_sh=1,S_dw=1,S_dh=1,S_tag=0;
    reg [31:0] S_generation=0;
    reg S_bilinear=0,S_bottom_up=0;
    reg S_in_valid=0,S_in_last=0,S_out_ready=0,S_done_ready=0;
    reg [31:0] S_in_rgba=0;
    reg [15:0] S_in_x=0,S_in_y=0;
    wire S_start_ready,S_in_ready,S_valid,S_last,S_busy,S_done;
    wire [31:0] S_rgba,S_out_generation;
    wire [15:0] S_x,S_y,S_out_tag;
    wire [3:0] S_error;
    reg S_test_pass=0,S_check=0,S_force_stall=0;
    integer S_gsw,S_gsh,S_gdw,S_gdh,S_seed,S_mode,S_bottom;
    integer S_count=0,S_cycles=0,S_case=0,S_tx,S_ty,S_j;
    reg S_held=0;
    reg [64:0] S_held_payload;
    reg [31:0] S_expected;
    integer S_expected_x,S_expected_y;
    always #4 S_clk=~S_clk;
    image_scaler u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_src_width(S_sw),.I_src_height(S_sh),.I_dst_width(S_dw),.I_dst_height(S_dh),
        .I_bilinear(S_bilinear),.I_bottom_up(S_bottom_up),.I_tag(S_tag),.I_generation(S_generation),
        .I_abort(S_abort),.I_stream_error(S_stream_error),
        .I_pixel_valid(S_in_valid),.O_pixel_ready(S_in_ready),.I_rgba(S_in_rgba),
        .I_x(S_in_x),.I_y(S_in_y),.I_pixel_last(S_in_last),
        .O_pixel_valid(S_valid),.I_pixel_ready(S_out_ready),.O_rgba(S_rgba),
        .O_x(S_x),.O_y(S_y),.O_pixel_last(S_last),
        .O_busy(S_busy),.O_done_valid(S_done),.I_done_ready(S_done_ready),
        .O_error(S_error),.O_tag(S_out_tag),.O_generation(S_out_generation)
    );

    // Procedural source image, asymmetric in x/y and channels, with nonconstant alpha.
    function [31:0] source_pixel;
        input integer x,y,seed;
        begin
            source_pixel={8'd0,8'd0,8'd0,8'd0};
            source_pixel[31:24]=(x*37+y*19+seed)&255;
            source_pixel[23:16]=(x*11+y*71+seed*3)&255;
            source_pixel[15:8]=(x*97+y*7+seed*5)&255;
            source_pixel[7:0]=(x*3+y*13+seed*17)&255;
        end
    endfunction
    // Independent direct-coordinate, four-term 64-bit reference. No DUT helpers.
    function [31:0] golden_pixel;
        input integer dx,dy;
        reg signed [63:0] px,py,stepx,stepy;
        reg [63:0] fx,fy,wx,wy,total;
        reg [31:0] p00,p01,p10,p11;
        integer x0,x1,y0,y1,c;
        begin
            stepx=(S_gsw*64'd65536)/S_gdw;
            stepy=(S_gsh*64'd65536)/S_gdh;
            px=(stepx/2)-32768+dx*stepx;
            py=(stepy/2)-32768+dy*stepy;
            if (!S_mode) begin
                x0=(px+32768)/65536; y0=(py+32768)/65536;
                if (x0<0) x0=0; if (x0>=S_gsw) x0=S_gsw-1;
                if (y0<0) y0=0; if (y0>=S_gsh) y0=S_gsh-1;
                golden_pixel=source_pixel(x0,y0,S_seed);
            end else begin
                if (px<0) px=0;
                if (py<0) py=0;
                if (px>(S_gsw-1)*64'sd65536) px=(S_gsw-1)*64'sd65536;
                if (py>(S_gsh-1)*64'sd65536) py=(S_gsh-1)*64'sd65536;
                x0=px/65536; y0=py/65536;
                x1=(x0+1<S_gsw) ? x0+1 : x0;
                y1=(y0+1<S_gsh) ? y0+1 : y0;
                fx=px%65536; fy=py%65536; wx=65536-fx; wy=65536-fy;
                p00=source_pixel(x0,y0,S_seed); p01=source_pixel(x1,y0,S_seed);
                p10=source_pixel(x0,y1,S_seed); p11=source_pixel(x1,y1,S_seed);
                for (c=0;c<4;c=c+1) begin
                    total=p00[31-c*8 -: 8]*wx*wy+p01[31-c*8 -: 8]*fx*wy+
                        p10[31-c*8 -: 8]*wx*fy+p11[31-c*8 -: 8]*fx*fy+64'd2147483648;
                    golden_pixel[31-c*8 -: 8]=total>>32;
                end
            end
        end
    endfunction
    task fail;
        input [511:0] message;
        begin $display("FAIL scaler case=%0d cycle=%0d count=%0d: %0s",S_case,S_cycles,S_count,message); $stop; end
    endtask

    always @(negedge S_clk) begin
        S_cycles=S_cycles+1;
        S_out_ready=!S_force_stall && S_cycles%11!=0 && S_cycles%11!=1 && S_cycles%17!=4;
    end
    always @(posedge S_clk) begin
        if (S_reset || S_abort || S_stream_error) S_held=0;
        else begin
            if (S_held && (!S_valid || {S_rgba,S_x,S_y,S_last} !== S_held_payload))
                fail("output changed under backpressure");
            S_held=S_valid && !S_out_ready;
            S_held_payload={S_rgba,S_x,S_y,S_last};
            if (S_valid && S_out_ready && S_check) begin
                S_expected_x=S_count%S_gdw;
                S_expected_y=S_bottom ? S_gdh-1-S_count/S_gdw : S_count/S_gdw;
                S_expected=golden_pixel(S_expected_x,S_expected_y);
                if (S_count>=S_gdw*S_gdh || S_x!==S_expected_x[15:0] || S_y!==S_expected_y[15:0] ||
                    S_rgba!==S_expected || S_last!==(S_count==S_gdw*S_gdh-1)) begin
                    $display("expected xy=%0d,%0d rgba=%h actual=%0d,%0d %h last=%b",
                        S_expected_x,S_expected_y,S_expected,S_x,S_y,S_rgba,S_last);
                    fail("pixel mismatch/duplicate/missing/last");
                end
                S_count=S_count+1;
            end
        end
    end

    task launch;
        input integer sw,sh,dw,dh,mode,bottom,seed;
        begin
            @(negedge S_clk);
            if (!S_start_ready) fail("start not ready");
            S_case=S_case+1; S_count=0;
            S_gsw=sw; S_gsh=sh; S_gdw=dw; S_gdh=dh;
            S_mode=mode; S_bottom=bottom; S_seed=seed;
            S_sw=sw; S_sh=sh; S_dw=dw; S_dh=dh; S_bilinear=mode; S_bottom_up=bottom;
            S_tag=S_case; S_generation=32'h12340000+S_case;
            S_start=1; S_in_valid=0; S_abort=0; S_stream_error=0;
            @(posedge S_clk); @(negedge S_clk); S_start=0;
            // Mutate all command fields after acceptance; only snapshots may affect work.
            S_sw=1; S_sh=1; S_dw=1; S_dh=1; S_bilinear=!mode; S_bottom_up=!bottom;
            S_tag=16'hffff; S_generation=32'hffffffff;
        end
    endtask
    task pixel;
        input integer x,y;
        input last;
        begin
            @(negedge S_clk);
            S_in_valid=1; S_in_x=x; S_in_y=y;
            S_in_rgba=source_pixel(x,y,S_seed); S_in_last=last;
            @(posedge S_clk);
            while (!S_in_ready) @(posedge S_clk);
            @(negedge S_clk); S_in_valid=0;
        end
    endtask
    task result;
        input integer code,full;
        begin
            wait (S_done); @(negedge S_clk);
            if (S_error!==code[3:0] || S_out_tag!==S_case[15:0] ||
                S_out_generation!==(32'h12340000+S_case) || !S_busy || S_start_ready || S_valid || S_in_ready)
                fail("terminal status/identity/endpoint mismatch");
            if (full && S_count!=S_gdw*S_gdh) fail("incomplete destination");
            S_abort=1; S_stream_error=1;
            repeat (9) begin
                @(posedge S_clk); #1;
                if (!S_done || S_error!==code[3:0] || S_start_ready) fail("done not held/frozen");
            end
            @(negedge S_clk); S_abort=0; S_stream_error=0; S_done_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_done_ready=0; S_check=0;
            if (!S_start_ready || S_done || S_busy) fail("result retirement");
        end
    endtask
    task successful;
        input integer sw,sh,dw,dh,mode,bottom,seed;
        begin
            launch(sw,sh,dw,dh,mode,bottom,seed); S_check=1;
            for (S_ty=0;S_ty<sh;S_ty=S_ty+1) begin
                for (S_tx=0;S_tx<sw;S_tx=S_tx+1) begin
                    if ((S_tx+S_ty)%29==7) repeat (2) @(negedge S_clk);
                    pixel(S_tx,bottom ? sh-1-S_ty : S_ty,S_tx==sw-1 && S_ty==sh-1);
                end
            end
            result(0,1);
        end
    endtask
    initial begin
        S_reset=1; repeat (4) @(negedge S_clk); S_reset=0;
        // Identity, half-pixel ties, repeated source rows/columns, trailing-row drain,
        // maximum source width/height, pre-rotation portrait and full-size inputs.
        for (S_j=0;S_j<4;S_j=S_j+1) begin
            successful(1,1,1,1,S_j%2,S_j/2,1);
            successful(1,1,13,9,S_j%2,S_j/2,2);
            successful(2,2,3,5,S_j%2,S_j/2,3);
            successful(13,9,2,1,S_j%2,S_j/2,4);
            successful(17,13,17,13,S_j%2,S_j/2,5);
            successful(7,19,31,23,S_j%2,S_j/2,6);
            successful(300,200,17,23,S_j%2,S_j/2,7);
            successful(1920,2,640,1,S_j%2,S_j/2,8);
            successful(1,1080,1,640,S_j%2,S_j/2,9);
        end
        successful(640,480,640,480,0,0,11);
        successful(640,480,360,480,1,1,12);
        successful(1920,1080,640,360,1,0,13);
        successful(1920,1080,640,360,0,1,14);
        successful(1920,1080,1,1,0,0,15);
        successful(1920,1080,1,1,1,1,16);
        // Invalid geometry must not consume source pixels.
        launch(0,2,2,2,0,0,0); result(1,0);
        launch(1921,2,2,2,0,0,0); result(1,0);
        launch(2,1081,2,2,0,0,0); result(1,0);
        launch(2,2,0,2,0,0,0); result(1,0);
        launch(2,2,2,641,0,0,0); result(1,0);
        // Coordinate order, direction and exact source last.
        launch(2,2,1,1,1,0,0); pixel(1,0,0); result(2,0);
        launch(2,2,1,1,1,1,0); pixel(0,0,0); result(2,0);
        launch(2,2,1,1,1,0,0); pixel(0,0,1); result(2,0);
        launch(1,1,1,1,0,0,0); pixel(0,0,0); result(2,0);
        // The destination is already complete when a skipped trailing row is bad.
        launch(1,4,1,1,0,0,18); S_check=1;
        pixel(0,0,0); pixel(0,1,0); pixel(0,2,0); pixel(0,3,0); result(2,1);
        // Errors during setup and while the output is stalled; abort wins.
        launch(2,2,3,3,1,0,0); S_stream_error=1;
        @(posedge S_clk); @(negedge S_clk); S_stream_error=0; result(3,0);
        launch(1,1,1,1,1,0,0); S_force_stall=1; pixel(0,0,1);
        wait (S_valid); repeat (5) @(negedge S_clk); S_abort=1; S_stream_error=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0; S_stream_error=0;
        S_force_stall=0; result(4,0);
        // Abort a partially loaded line, then reuse the RAM without clearing it.
        launch(4,3,7,5,1,1,21); pixel(0,2,0); S_abort=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0; result(4,0);
        successful(3,2,8,7,1,0,22);
        // Global reset revokes a pending output, creates no done and allows clean reuse.
        launch(1,1,2,2,1,0,23); S_force_stall=1; pixel(0,0,1);
        wait (S_valid); @(negedge S_clk); S_reset=1;
        repeat (3) @(negedge S_clk);
        S_reset=0; S_force_stall=0;
        if (S_done || S_valid || !S_start_ready) fail("reset did not revoke work");
        successful(5,7,3,4,1,1,24);
        S_test_pass=1;
        $display("PASS: scaler direct Q16 golden pixels, both algorithms/directions, full maximum source, stalls/errors/reset");
        $finish;
    end
    initial begin #1000000000; fail("timeout"); end
endmodule
