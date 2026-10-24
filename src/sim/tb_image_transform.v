`timescale 1ns/1ps
// Real geometry + scaler + rotate. No framebuffer or real file ownership.
module tb_image_transform;
    reg S_clk=0,S_reset=0,S_start=0,S_abort=0,S_stream_error=0;
    reg [15:0] S_sw=1,S_sh=1,S_rx=0,S_ry=0,S_rw=1,S_rh=1,S_tag=0;
    reg [31:0] S_generation=0;
    reg [1:0] S_rotation=0;
    reg S_bilinear=0,S_bottom_up=0,S_geometry_ready=0,S_ready=0,S_done_ready=0,S_hold=0;
    reg S_in_valid=0,S_in_last=0;
    reg [31:0] S_data=0;
    reg [15:0] S_in_x=0,S_in_y=0;
    wire S_start_ready,S_geometry_valid,S_in_ready,S_valid,S_last,S_busy,S_done;
    wire [15:0] S_pw,S_ph,S_ix,S_iy,S_iw,S_ih,S_x,S_y,S_out_tag;
    wire [31:0] S_rgba,S_out_generation;
    wire [3:0] S_error;
    integer S_case=0,S_cycles=0,S_count=0,S_inputs=0,S_headers=0,S_a,S_b,S_j,S_k;
    integer S_gsw,S_gsh,S_gpw,S_gph,S_gx,S_gy,S_gw,S_gh,S_gr,S_gmode,S_gbottom;
    integer S_rrw,S_rrh,S_u,S_v,S_ex,S_ey;
    reg S_test_pass=0,S_waiting=0,S_gwaiting=0;
    reg [64:0] S_saved;
    reg [95:0] S_gsaved;
    always #4 S_clk=~S_clk;
    image_transform u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_src_width(S_sw),.I_src_height(S_sh),.I_rect_x(S_rx),.I_rect_y(S_ry),
        .I_rect_width(S_rw),.I_rect_height(S_rh),.I_rotation(S_rotation),
        .I_bilinear(S_bilinear),.I_bottom_up(S_bottom_up),.I_tag(S_tag),.I_generation(S_generation),
        .I_abort(S_abort),.I_stream_error(S_stream_error),
        .O_geometry_valid(S_geometry_valid),.I_geometry_ready(S_geometry_ready),
        .O_pre_width(S_pw),.O_pre_height(S_ph),.O_image_x(S_ix),.O_image_y(S_iy),.O_image_width(S_iw),.O_image_height(S_ih),
        .I_pixel_valid(S_in_valid),.O_pixel_ready(S_in_ready),.I_rgba(S_data),.I_x(S_in_x),.I_y(S_in_y),.I_pixel_last(S_in_last),
        .O_pixel_valid(S_valid),.I_pixel_ready(S_ready),.O_rgba(S_rgba),.O_x(S_x),.O_y(S_y),.O_pixel_last(S_last),
        .O_busy(S_busy),.O_done_valid(S_done),.I_done_ready(S_done_ready),
        .O_error(S_error),.O_tag(S_out_tag),.O_generation(S_out_generation)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL transform case=%0d input=%0d output=%0d: %0s",S_case,S_inputs,S_count,message); $stop; end
    endtask
    function [31:0] source_pixel;
        input integer x,y;
        begin
            source_pixel[31:24]=(x*37+y*19+S_case*7)&255;
            source_pixel[23:16]=(x*11+y*71+S_case*13)&255;
            source_pixel[15:8]=(x*97+y*7+S_case*31)&255;
            source_pixel[7:0]=(x*3+y*13+S_case*17)&255;
        end
    endfunction
    function [31:0] golden;
        input integer u,v;
        reg signed [63:0] px,py,sx,sy;
        reg [63:0] fx,fy,wx,wy,total;
        reg [31:0] a,b,c,d;
        integer x0,y0,x1,y1,ch;
        begin
            sx=(S_gsw*64'd65536)/S_gpw; sy=(S_gsh*64'd65536)/S_gph;
            px=(sx/2)-32768+u*sx; py=(sy/2)-32768+v*sy;
            if (!S_gmode) begin px=px+32768; py=py+32768; end
            if (px<0) px=0; if (py<0) py=0;
            if (px>(S_gsw-1)*64'sd65536) px=(S_gsw-1)*64'sd65536;
            if (py>(S_gsh-1)*64'sd65536) py=(S_gsh-1)*64'sd65536;
            x0=px/65536; y0=py/65536;
            x1=x0+1<S_gsw ? x0+1 : x0; y1=y0+1<S_gsh ? y0+1 : y0;
            fx=S_gmode ? px%65536 : 0; fy=S_gmode ? py%65536 : 0;
            wx=65536-fx; wy=65536-fy;
            a=source_pixel(x0,y0); b=source_pixel(x1,y0); c=source_pixel(x0,y1); d=source_pixel(x1,y1);
            for (ch=0;ch<4;ch=ch+1) begin
                total=a[31-ch*8 -: 8]*wx*wy+b[31-ch*8 -: 8]*fx*wy+
                    c[31-ch*8 -: 8]*wx*fy+d[31-ch*8 -: 8]*fx*fy+64'd2147483648;
                golden[31-ch*8 -: 8]=total>>32;
            end
        end
    endfunction
    always @(negedge S_clk) begin
        S_cycles=S_cycles+1; S_ready=!S_hold && S_cycles%19>5;
    end
    always @(posedge S_clk) begin
        if (S_reset || S_abort || S_stream_error || S_error!=0) begin S_waiting=0; S_gwaiting=0; end
        else begin
            if (S_waiting && (!S_valid || {S_rgba,S_x,S_y,S_last}!==S_saved)) fail("pixel changed during stall");
            if (S_gwaiting && (!S_geometry_valid || {S_pw,S_ph,S_ix,S_iy,S_iw,S_ih}!==S_gsaved)) fail("geometry changed during stall");
            S_waiting=S_valid && !S_ready; S_saved={S_rgba,S_x,S_y,S_last};
            S_gwaiting=S_geometry_valid && !S_geometry_ready; S_gsaved={S_pw,S_ph,S_ix,S_iy,S_iw,S_ih};
            if (S_geometry_valid && S_geometry_ready) begin
                S_headers=S_headers+1;
                if (S_pw!=S_gpw || S_ph!=S_gph || S_ix!=S_gx || S_iy!=S_gy || S_iw!=S_gw || S_ih!=S_gh)
                    fail("geometry mismatch");
            end
            if (S_in_valid && S_in_ready) S_inputs=S_inputs+1;
            if (S_valid && S_ready) begin
                S_u=S_count%S_gpw; S_v=S_gbottom ? S_gph-1-S_count/S_gpw : S_count/S_gpw;
                case (S_gr)
                    0: begin S_ex=S_u; S_ey=S_v; end
                    1: begin S_ex=S_gph-1-S_v; S_ey=S_u; end
                    2: begin S_ex=S_gpw-1-S_u; S_ey=S_gph-1-S_v; end
                    3: begin S_ex=S_v; S_ey=S_gpw-1-S_u; end
                endcase
                S_ex=S_ex+S_gx; S_ey=S_ey+S_gy;
                if (S_count>=S_gpw*S_gph || S_x!=S_ex || S_y!=S_ey || S_rgba!==golden(S_u,S_v) ||
                    S_last!==(S_count==S_gpw*S_gph-1) || S_x<S_gx || S_x>=S_gx+S_gw ||
                    S_y<S_gy || S_y>=S_gy+S_gh || S_x>=640 || S_y>=480) fail("pixel/value/rotation/bounds/last");
                S_count=S_count+1;
            end
        end
    end
    task launch;
        input integer sw,sh,x,y,w,h,r,mode,bottom;
        begin
            @(negedge S_clk); if (!S_start_ready) fail("not ready");
            S_case=S_case+1; S_count=0; S_inputs=0; S_headers=0;
            S_gsw=sw; S_gsh=sh; S_gr=r; S_gmode=mode; S_gbottom=bottom;
            S_rrw=(r%2) ? sh : sw; S_rrh=(r%2) ? sw : sh;
            S_gw=w; S_gh=h;
            if (sw>0 && sh>0) begin
                if (w*S_rrh<=h*S_rrw) begin S_gh=(S_rrh*w)/S_rrw; if (S_gh<1) S_gh=1; end
                else begin S_gw=(S_rrw*h)/S_rrh; if (S_gw<1) S_gw=1; end
            end
            S_gx=x+(w-S_gw)/2; S_gy=y+(h-S_gh)/2;
            S_gpw=(r%2) ? S_gh : S_gw; S_gph=(r%2) ? S_gw : S_gh;
            S_sw=sw; S_sh=sh; S_rx=x; S_ry=y; S_rw=w; S_rh=h;
            S_rotation=r; S_bilinear=mode; S_bottom_up=bottom;
            S_tag=S_case; S_generation=32'h13570000+S_case; S_geometry_ready=0; S_start=1;
            @(posedge S_clk); @(negedge S_clk); S_start=0;
            S_sw=0; S_sh=0; S_rx=65535; S_ry=65535; S_rw=0; S_rh=0;
            S_rotation=0; S_bilinear=!mode; S_bottom_up=!bottom; S_tag=0; S_generation=0;
        end
    endtask
    task accept_geometry;
        begin
            wait (S_geometry_valid); repeat (9) begin
                @(negedge S_clk);
                if (S_in_ready || S_valid || S_done || !S_busy) fail("pipeline started before geometry grant");
            end
            S_geometry_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_geometry_ready=0;
        end
    endtask
    task pixel;
        input integer x,y,last;
        begin
            @(negedge S_clk); S_in_valid=1; S_in_x=x; S_in_y=y; S_in_last=last; S_data=source_pixel(x,y);
            @(posedge S_clk); while (!S_in_ready) @(posedge S_clk);
            @(negedge S_clk); S_in_valid=0;
        end
    endtask
    task result;
        input integer code,complete;
        begin
            wait (S_done); @(negedge S_clk);
            if (S_error!==code[3:0] || S_out_tag!==S_case[15:0] || S_out_generation!==(32'h13570000+S_case) ||
                !S_busy || S_start_ready || S_valid || S_in_ready || S_geometry_valid) fail("result status/identity/endpoints");
            if (complete && (S_count!=S_gpw*S_gph || S_inputs!=S_gsw*S_gsh || S_headers!=1)) fail("early/incomplete success");
            S_abort=1; S_stream_error=1;
            repeat (7) begin @(posedge S_clk); #1; if (!S_done || S_error!==code[3:0]) fail("published result changed"); end
            @(negedge S_clk); S_abort=0; S_stream_error=0; S_done_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_done_ready=0;
            if (!S_start_ready || S_done || S_busy) fail("retirement/reuse");
        end
    endtask
    task successful;
        input integer sw,sh,x,y,w,h,r,mode,bottom;
        begin
            launch(sw,sh,x,y,w,h,r,mode,bottom); accept_geometry;
            for (S_b=0;S_b<sh;S_b=S_b+1)
                for (S_a=0;S_a<sw;S_a=S_a+1) begin
                    if ((S_a+S_b)%31==7) repeat (3) @(negedge S_clk);
                    pixel(S_a,bottom ? sh-1-S_b : S_b,S_a==sw-1 && S_b==sh-1);
                end
            result(0,1);
        end
    endtask
    initial begin
        S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        for (S_j=0;S_j<4;S_j=S_j+1)
            for (S_k=0;S_k<4;S_k=S_k+1)
                successful(7,5,13,17,19,13,S_j,S_k%2,S_k/2);
        successful(640,480,0,0,640,480,1,0,0);
        successful(300,200,0,0,640,480,2,1,1);
        successful(1920,1080,16,16,160,120,3,1,1);
        successful(1,1080,639,0,1,480,0,1,1);
        successful(1,1,639,479,1,1,3,1,0);
        launch(0,1,0,0,640,480,0,0,0); result(1,0);
        launch(2,3,65535,0,2,3,0,0,0); result(1,0);
        // Cancel setup and cancel a valid geometry stalled before any pixel task.
        launch(640,480,0,0,640,480,1,0,0);
        S_stream_error=1; @(posedge S_clk); @(negedge S_clk); S_stream_error=0; result(3,0);
        launch(640,480,0,0,640,480,1,0,0);
        wait (S_geometry_valid); @(negedge S_clk); S_abort=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0; result(4,0);
        // Real scaler protocol failure aborts its peer without masking the root as 4.
        launch(2,2,0,0,2,2,0,1,0); accept_geometry; pixel(1,0,0); result(2,0);
        // Rotate can finish first, but source trailing rows still belong to this job.
        launch(1,4,0,0,1,1,3,0,0); accept_geometry;
        pixel(0,0,0); pixel(0,1,0); pixel(0,2,0);
        wait (S_count==1); repeat (5) @(negedge S_clk);
        if (S_done || !S_busy) fail("rotate completion bypassed scaler tail drain");
        pixel(0,3,0); result(2,0);
        // Last output still held in rotate's elastic register; abort must retire both.
        launch(1,1,0,0,1,1,1,1,0); accept_geometry; S_hold=1; pixel(0,0,1);
        wait (S_valid); repeat (6) @(negedge S_clk);
        if (S_done) fail("pending output treated as retired");
        S_abort=1; S_stream_error=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0; S_stream_error=0; S_hold=0; result(4,0);
        launch(2,3,7,9,11,13,2,1,1); accept_geometry; S_stream_error=1;
        @(posedge S_clk); @(negedge S_clk); S_stream_error=0; result(3,0);
        launch(1,1,0,0,2,2,1,1,0); accept_geometry; S_hold=1; pixel(0,0,1);
        wait (S_valid); @(negedge S_clk); S_reset=1;
        repeat (3) @(negedge S_clk); S_reset=0; S_hold=0;
        if (S_done || S_valid || S_geometry_valid || !S_start_ready) fail("global reset cancellation");
        successful(5,9,3,7,13,17,3,1,1);
        S_test_pass=1;
        $display("PASS: real fit/scaler/rotate, golden RGBA and coordinates, all directions/modes, joined retirement/errors/reset");
        $finish;
    end
    initial begin #1000000000; fail("timeout"); end
endmodule
