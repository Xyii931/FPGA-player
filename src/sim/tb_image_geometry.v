`timescale 1ns/1ps
module tb_image_geometry;
    reg S_clk=0,S_reset=0,S_start=0,S_abort=0,S_result_ready=0;
    reg [15:0] S_sw=1,S_sh=1,S_rx=0,S_ry=0,S_rw=1,S_rh=1,S_tag=0;
    reg [31:0] S_generation=0;
    reg [1:0] S_rotation=0;
    wire S_ready,S_busy,S_result,S_rotate_done;
    wire [3:0] S_error;
    wire [15:0] S_out_tag,S_pw,S_ph,S_x,S_y,S_w,S_h;
    wire [31:0] S_out_generation;
    integer S_case=0,S_i,S_ex,S_ey,S_ew,S_eh,S_epw,S_eph,S_rrw,S_rrh;
    integer S_a,S_b;
    reg S_test_pass=0;
    always #4 S_clk=~S_clk;
    image_geometry u_geometry (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_ready),
        .I_src_width(S_sw),.I_src_height(S_sh),.I_rect_x(S_rx),.I_rect_y(S_ry),
        .I_rect_width(S_rw),.I_rect_height(S_rh),.I_rotation(S_rotation),
        .I_tag(S_tag),.I_generation(S_generation),.I_abort(S_abort),
        .O_busy(S_busy),.O_result_valid(S_result),.I_result_ready(S_result_ready),
        .O_error(S_error),.O_tag(S_out_tag),.O_generation(S_out_generation),
        .O_pre_width(S_pw),.O_pre_height(S_ph),.O_image_x(S_x),.O_image_y(S_y),
        .O_image_width(S_w),.O_image_height(S_h)
    );
    image_rotate_case u_rotate_case(S_rotate_done);
    task fail;
        input [511:0] message;
        begin $display("FAIL geometry case=%0d: %0s",S_case,message); $stop; end
    endtask
    task launch;
        input integer sw,sh,x,y,w,h,rotation;
        begin
            @(negedge S_clk);
            if (!S_ready) fail("not ready");
            S_case=S_case+1; S_sw=sw; S_sh=sh; S_rx=x; S_ry=y; S_rw=w; S_rh=h;
            S_rotation=rotation; S_tag=S_case; S_generation=32'h98760000+S_case; S_start=1;
            // Independent integer reference uses direct division, no serial divider.
            S_rrw=(rotation%2) ? sh : sw; S_rrh=(rotation%2) ? sw : sh;
            S_ew=w; S_eh=h;
            if (sw>0 && sh>0) begin
                if (w*S_rrh<=h*S_rrw) begin S_eh=(S_rrh*w)/S_rrw; if (S_eh<1) S_eh=1; end
                else begin S_ew=(S_rrw*h)/S_rrh; if (S_ew<1) S_ew=1; end
            end
            S_ex=x+(w-S_ew)/2; S_ey=y+(h-S_eh)/2;
            S_epw=(rotation%2) ? S_eh : S_ew; S_eph=(rotation%2) ? S_ew : S_eh;
            @(posedge S_clk); @(negedge S_clk); S_start=0;
            S_sw=1; S_sh=1; S_rx=65535; S_ry=65535; S_rw=0; S_rh=0;
            S_rotation=0; S_tag=0; S_generation=0;
        end
    endtask
    task finish;
        input integer error;
        begin
            wait (S_result); @(negedge S_clk);
            if (S_error!==error[3:0] || S_out_tag!==S_case[15:0] ||
                S_out_generation!==(32'h98760000+S_case) || !S_busy || S_ready) fail("result/identity");
            if (error==0) begin
                if (S_pw!=S_epw || S_ph!=S_eph || S_x!=S_ex || S_y!=S_ey || S_w!=S_ew || S_h!=S_eh)
                    fail("aspect fit/centering/transpose");
            end else if ({S_pw,S_ph,S_x,S_y,S_w,S_h}!==96'd0) fail("error leaked geometry");
            S_abort=1;
            repeat (7) begin
                @(posedge S_clk); #1;
                if (!S_result || S_error!==error[3:0] || S_out_tag!==S_case[15:0]) fail("result changed");
            end
            @(negedge S_clk); S_abort=0; S_result_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_result_ready=0;
            if (!S_ready || S_result || S_busy) fail("result consumption");
        end
    endtask
    initial begin
        S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        launch(640,480,0,0,640,480,1); finish(0);
        for (S_i=0;S_i<4;S_i=S_i+1) begin
            launch(1920,1080,0,0,640,480,S_i); finish(0);
            launch(1,1080,19,17,213,144,S_i); finish(0);
            launch(1920,1,320,0,320,480,S_i); finish(0);
            launch(1,1,639,479,1,1,S_i); finish(0);
            launch(7,3,3,5,211,157,S_i); finish(0);
        end
        for (S_i=0;S_i<256;S_i=S_i+1) begin
            S_a=(S_i*31)%640; S_b=(S_i*17)%480;
            launch(1+(S_i*37)%1920,1+(S_i*71)%1080,S_a,S_b,
                1+(S_i*19)%(640-S_a),1+(S_i*23)%(480-S_b),S_i%4);
            finish(0);
        end
        launch(0,1,0,0,640,480,0); finish(1);
        launch(1921,1,0,0,640,480,0); finish(1);
        launch(1,1081,0,0,640,480,0); finish(1);
        launch(2,3,0,0,0,480,0); finish(1);
        launch(2,3,639,0,2,480,0); finish(1);
        launch(2,3,0,479,640,2,0); finish(1);
        launch(2,3,65535,65535,2,2,0); finish(1);
        launch(640,480,0,0,640,480,3);
        repeat (12) @(negedge S_clk); S_abort=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0; finish(2);
        launch(640,480,0,0,640,480,3);
        repeat (5) @(negedge S_clk); S_reset=1;
        repeat (3) @(negedge S_clk); S_reset=0;
        if (S_result || !S_ready) fail("reset generated result");
        launch(300,200,16,16,160,120,2); finish(0);
        wait (S_rotate_done);
        S_test_pass=1;
        $display("PASS: geometry direct aspect golden, clipping rejection, snapshots; four rotations and stream protocol");
        $finish;
    end
    initial begin #100000000; fail("timeout"); end
endmodule

module image_rotate_case(output reg O_done);
    reg S_clk=0,S_reset=0,S_start=0,S_abort=0,S_stream_error=0,S_done_ready=0;
    reg [15:0] S_w=1,S_h=1,S_ix=0,S_iy=0,S_tag=0;
    reg [31:0] S_generation=0;
    reg [1:0] S_rotation=0;
    reg S_bottom=0,S_iv=0,S_ilast=0,S_ready=0,S_hold=0;
    reg [31:0] S_data=0;
    reg [15:0] S_u=0,S_v=0;
    wire S_start_ready,S_in_ready,S_valid,S_last,S_busy,S_done;
    wire [31:0] S_rgba,S_out_generation;
    wire [15:0] S_x,S_y,S_out_tag;
    wire [3:0] S_error;
    integer S_case=0,S_cycles=0,S_count=0,S_gw,S_gh,S_gx,S_gy,S_gr,S_gbottom;
    integer S_a,S_b,S_i,S_j,S_r,S_ex,S_ey,S_eu,S_ev;
    reg S_waiting=0;
    reg [64:0] S_saved;
    always #4 S_clk=~S_clk;
    image_rotate u_rotate (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_pre_width(S_w),.I_pre_height(S_h),.I_image_x(S_ix),.I_image_y(S_iy),
        .I_rotation(S_rotation),.I_bottom_up(S_bottom),.I_tag(S_tag),.I_generation(S_generation),
        .I_abort(S_abort),.I_stream_error(S_stream_error),.I_pixel_valid(S_iv),.O_pixel_ready(S_in_ready),
        .I_rgba(S_data),.I_x(S_u),.I_y(S_v),.I_pixel_last(S_ilast),
        .O_pixel_valid(S_valid),.I_pixel_ready(S_ready),.O_rgba(S_rgba),.O_x(S_x),.O_y(S_y),.O_pixel_last(S_last),
        .O_busy(S_busy),.O_done_valid(S_done),.I_done_ready(S_done_ready),
        .O_error(S_error),.O_tag(S_out_tag),.O_generation(S_out_generation)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL rotate case=%0d output=%0d: %0s",S_case,S_count,message); $stop; end
    endtask
    function [31:0] pattern;
        input integer u,v;
        begin pattern={u[7:0],v[7:0],8'h3c,8'hff}; end
    endfunction
    always @(negedge S_clk) begin
        S_cycles=S_cycles+1; S_ready=!S_hold && S_cycles%13>2;
    end
    always @(posedge S_clk) begin
        if (S_reset || S_abort || S_stream_error) S_waiting=0;
        else begin
            if (S_waiting && (!S_valid || {S_rgba,S_x,S_y,S_last}!==S_saved)) fail("stall stability");
            S_waiting=S_valid && !S_ready; S_saved={S_rgba,S_x,S_y,S_last};
            if (S_valid && S_ready) begin
                S_eu=S_count%S_gw; S_ev=S_gbottom ? S_gh-1-S_count/S_gw : S_count/S_gw;
                case (S_gr)
                    0: begin S_ex=S_eu; S_ey=S_ev; end
                    1: begin S_ex=S_gh-1-S_ev; S_ey=S_eu; end
                    2: begin S_ex=S_gw-1-S_eu; S_ey=S_gh-1-S_ev; end
                    3: begin S_ex=S_ev; S_ey=S_gw-1-S_eu; end
                endcase
                S_ex=S_ex+S_gx; S_ey=S_ey+S_gy;
                if (S_count>=S_gw*S_gh || S_x!=S_ex || S_y!=S_ey || S_x>=640 || S_y>=480 ||
                    S_rgba!==pattern(S_eu,S_ev) || S_last!==(S_count==S_gw*S_gh-1)) fail("rotated coordinate/data/last");
                S_count=S_count+1;
            end
        end
    end
    task launch;
        input integer w,h,x,y,r,bottom;
        begin
            @(negedge S_clk); if (!S_start_ready) fail("not ready");
            S_case=S_case+1; S_count=0;
            S_gw=w; S_gh=h; S_gx=x; S_gy=y; S_gr=r; S_gbottom=bottom;
            S_w=w; S_h=h; S_ix=x; S_iy=y; S_rotation=r; S_bottom=bottom;
            S_tag=S_case; S_generation=32'h11220000+S_case; S_start=1;
            @(posedge S_clk); @(negedge S_clk); S_start=0;
            S_w=0; S_h=0; S_ix=65535; S_iy=65535; S_rotation=0; S_bottom=!bottom;
            S_tag=0; S_generation=0;
        end
    endtask
    task finish;
        input integer error;
        begin
            wait (S_done); @(negedge S_clk);
            if (S_error!==error[3:0] || !S_busy || S_valid || S_in_ready || S_start_ready ||
                S_out_tag!==S_case[15:0] || S_out_generation!==(32'h11220000+S_case)) fail("terminal");
            if (error==0 && S_count!=S_gw*S_gh) fail("early terminal");
            S_abort=1;
            repeat (5) begin @(posedge S_clk); #1; if (!S_done || S_error!==error[3:0]) fail("result freeze"); end
            @(negedge S_clk); S_abort=0; S_done_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_done_ready=0;
        end
    endtask
    task send;
        input integer u,v,last;
        begin
            S_iv=1; S_u=u; S_v=v; S_data=pattern(u,v); S_ilast=last;
            @(posedge S_clk); while (!S_in_ready) @(posedge S_clk);
            @(negedge S_clk); S_iv=0;
        end
    endtask
    task successful;
        input integer w,h,x,y,r,bottom;
        begin
            launch(w,h,x,y,r,bottom);
            for (S_b=0;S_b<h;S_b=S_b+1)
                for (S_a=0;S_a<w;S_a=S_a+1)
                    send(S_a,bottom ? h-1-S_b : S_b,S_a==w-1 && S_b==h-1);
            finish(0);
        end
    endtask
    initial begin
        O_done=0;
        S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        for (S_i=0;S_i<4;S_i=S_i+1)
            for (S_j=0;S_j<2;S_j=S_j+1) begin
                successful(3,2,5,7,S_i,S_j);
                successful(1,1,639,479,S_i,S_j);
            end
        successful(640,480,0,0,0,0);
        successful(480,360,140,0,1,1);
        successful(480,360,140,0,3,0);
        launch(0,1,0,0,0,0); finish(1);
        launch(641,1,0,0,0,0); finish(1);
        launch(640,480,0,0,1,0); finish(1);
        launch(2,2,65535,0,0,0); finish(1);
        launch(2,2,0,479,0,0); finish(1);
        launch(2,2,0,0,0,0); send(1,0,0); finish(2);
        launch(2,2,0,0,0,1); send(0,0,0); finish(2);
        launch(2,2,0,0,0,0); send(0,0,1); finish(2);
        launch(1,1,0,0,0,0); send(0,0,0); finish(2);
        launch(2,2,0,0,0,0); S_stream_error=1;
        @(posedge S_clk); @(negedge S_clk); S_stream_error=0; finish(3);
        launch(1,1,0,0,0,0); S_hold=1; send(0,0,1);
        wait (S_valid); repeat (4) @(negedge S_clk);
        if (S_done) fail("last output did not wait");
        S_abort=1; S_stream_error=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0; S_stream_error=0; S_hold=0; finish(4);
        launch(1,1,0,0,0,0); S_hold=1; send(0,0,1);
        wait (S_valid); @(negedge S_clk); S_reset=1;
        repeat (3) @(negedge S_clk); S_reset=0; S_hold=0;
        if (S_valid || S_done || !S_start_ready) fail("reset flush");
        successful(7,3,11,13,2,1);
        O_done=1;
    end
endmodule
