`timescale 1ns/1ps
// Golden arithmetic exists only in this unexecuted Verilog self-check.
module tb_transition_pixel;
    reg S_clk=0,S_reset=0,S_test_pass=0;
    integer S_case=0;
    always #20 S_clk=~S_clk;
    task fail;
        input [767:0] message;
        begin $display("FAIL: transition_pixel case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #1000000000; fail("watchdog timeout"); end
    reg S_cmd_start_valid=0;
    wire S_plan_start_ready;
    reg [2:0] S_cmd_effect=0;
    reg [16:0] S_cmd_progress=0;
    reg [31:0] S_cmd_epoch=0;
    reg [15:0] S_cmd_tag=0;
    wire S_plan_done_valid;
    reg S_cmd_done_ready=0;
    wire [3:0] S_plan_error;
    wire [2:0] S_plan_effect;
    wire [16:0] S_plan_progress;
    wire [31:0] S_plan_epoch;
    wire [15:0] S_plan_tag;
    wire [9:0] S_plan_dx;
    wire [9:0] S_plan_left;
    wire [8:0] S_plan_dy;
    wire [8:0] S_plan_top;
    wire [5:0] S_plan_blind_count;
    wire [8:0] S_plan_mosaic_count;
    wire [19:0] S_plan_wipe_threshold;
    wire [31:0] S_plan_step_x;
    wire [31:0] S_plan_step_y;
    wire S_map_config_ready;
    wire S_map_configured;
    reg S_in_valid=0;
    reg S_in_hsync=0;
    reg S_in_vsync=0;
    reg S_in_de=0;
    reg S_in_frame_start=0;
    reg S_in_line_start=0;
    reg [15:0] S_in_x=0;
    reg [15:0] S_in_y=0;
    reg [8:0] S_in_query_y=0;
    wire S_map_query_use_a;
    wire S_map_query_use_b;
    wire [8:0] S_map_query_a_y;
    wire [8:0] S_map_query_b_y;
    wire S_map_valid;
    wire S_map_hsync;
    wire S_map_vsync;
    wire S_map_de;
    wire S_map_frame_start;
    wire S_map_line_start;
    wire [15:0] S_map_x;
    wire [15:0] S_map_y;
    wire S_map_use_a;
    wire S_map_use_b;
    wire [9:0] S_map_a_x;
    wire [9:0] S_map_b_x;
    wire [8:0] S_map_a_y;
    wire [8:0] S_map_b_y;
    wire [16:0] S_map_weight;
    wire [31:0] S_map_epoch;
    wire [15:0] S_map_tag;
    wire S_config_valid;
    wire [23:0] S_color_a_rgb;
    wire [23:0] S_color_b_rgb;
    wire S_blend_valid;
    wire S_blend_hsync;
    wire S_blend_vsync;
    wire S_blend_de;
    wire S_blend_frame_start;
    wire S_blend_line_start;
    wire [15:0] S_blend_x;
    wire [15:0] S_blend_y;
    wire [23:0] S_blend_rgb;
    wire [31:0] S_blend_epoch;
    wire [15:0] S_blend_tag;
    wire S_blend_weight_error;
    assign S_config_valid=S_plan_done_valid && S_plan_error==0 && !S_hold_plan;
    always @* S_cmd_done_ready=!S_hold_plan && (S_plan_error!=0 || S_map_config_ready);
    assign S_color_a_rgb={S_map_a_x[7:0],S_map_a_y[7:0],(S_map_a_x[7:0]^S_map_a_y[7:0])};
    assign S_color_b_rgb={(8'hff-S_map_b_x[7:0]),(8'h7f^S_map_b_y[7:0]),(S_map_b_x[7:0]+S_map_b_y[7:0])};
    transition_plan u_plan (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_start_valid(S_cmd_start_valid),
        .O_start_ready(S_plan_start_ready),
        .I_effect(S_cmd_effect),
        .I_progress(S_cmd_progress),
        .I_epoch(S_cmd_epoch),
        .I_tag(S_cmd_tag),
        .O_done_valid(S_plan_done_valid),
        .I_done_ready(S_cmd_done_ready),
        .O_error(S_plan_error),
        .O_effect(S_plan_effect),
        .O_progress(S_plan_progress),
        .O_epoch(S_plan_epoch),
        .O_tag(S_plan_tag),
        .O_dx(S_plan_dx),
        .O_left(S_plan_left),
        .O_dy(S_plan_dy),
        .O_top(S_plan_top),
        .O_blind_count(S_plan_blind_count),
        .O_mosaic_count(S_plan_mosaic_count),
        .O_wipe_threshold(S_plan_wipe_threshold),
        .O_step_x(S_plan_step_x),
        .O_step_y(S_plan_step_y)
    );
    transition_map u_map (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_config_valid(S_config_valid),
        .O_config_ready(S_map_config_ready),
        .O_configured(S_map_configured),
        .I_effect(S_plan_effect),
        .I_progress(S_plan_progress),
        .I_epoch(S_plan_epoch),
        .I_tag(S_plan_tag),
        .I_dx(S_plan_dx),
        .I_left(S_plan_left),
        .I_dy(S_plan_dy),
        .I_top(S_plan_top),
        .I_blind_count(S_plan_blind_count),
        .I_mosaic_count(S_plan_mosaic_count),
        .I_wipe_threshold(S_plan_wipe_threshold),
        .I_step_x(S_plan_step_x),
        .I_step_y(S_plan_step_y),
        .I_valid(S_in_valid),
        .I_hsync(S_in_hsync),
        .I_vsync(S_in_vsync),
        .I_de(S_in_de),
        .I_frame_start(S_in_frame_start),
        .I_line_start(S_in_line_start),
        .I_x(S_in_x),
        .I_y(S_in_y),
        .I_query_y(S_in_query_y),
        .O_query_use_a(S_map_query_use_a),
        .O_query_use_b(S_map_query_use_b),
        .O_query_a_y(S_map_query_a_y),
        .O_query_b_y(S_map_query_b_y),
        .O_valid(S_map_valid),
        .O_hsync(S_map_hsync),
        .O_vsync(S_map_vsync),
        .O_de(S_map_de),
        .O_frame_start(S_map_frame_start),
        .O_line_start(S_map_line_start),
        .O_x(S_map_x),
        .O_y(S_map_y),
        .O_use_a(S_map_use_a),
        .O_use_b(S_map_use_b),
        .O_a_x(S_map_a_x),
        .O_b_x(S_map_b_x),
        .O_a_y(S_map_a_y),
        .O_b_y(S_map_b_y),
        .O_weight(S_map_weight),
        .O_epoch(S_map_epoch),
        .O_tag(S_map_tag)
    );
    blend_unit u_blend (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_valid(S_map_valid),
        .I_hsync(S_map_hsync),
        .I_vsync(S_map_vsync),
        .I_de(S_map_de),
        .I_frame_start(S_map_frame_start),
        .I_line_start(S_map_line_start),
        .I_x(S_map_x),
        .I_y(S_map_y),
        .I_a_rgb(S_color_a_rgb),
        .I_b_rgb(S_color_b_rgb),
        .I_use_a(S_map_use_a),
        .I_use_b(S_map_use_b),
        .I_weight(S_map_weight),
        .I_epoch(S_map_epoch),
        .I_tag(S_map_tag),
        .O_valid(S_blend_valid),
        .O_hsync(S_blend_hsync),
        .O_vsync(S_blend_vsync),
        .O_de(S_blend_de),
        .O_frame_start(S_blend_frame_start),
        .O_line_start(S_blend_line_start),
        .O_x(S_blend_x),
        .O_y(S_blend_y),
        .O_rgb(S_blend_rgb),
        .O_epoch(S_blend_epoch),
        .O_tag(S_blend_tag),
        .O_weight_error(S_blend_weight_error)
    );
    integer S_effect=0,S_progress=0,S_dx=0,S_dy=0,S_left=0,S_top=0;
    integer S_issued=0,S_map_checked=0,S_blend_checked=0;
    reg [31:0] S_epoch=0;
    reg [15:0] S_tag=0;
    reg S_hold_plan=0;
    reg S_prev_valid=0;
    reg [141:0] S_prev_map=0,S_current_map;
    reg [109:0] S_expected_blend[0:2];
    reg [2:0] S_blend_valid_queue=0;
    reg [109:0] S_current_blend;
    reg G_a,G_b;
    integer G_ax,G_ay,G_bx,G_by,G_weight,G_q,G_rank,G_local,G_w,G_c,G_value;
    reg [63:0] G_scaled,G_step;
    reg [23:0] G_argb,G_brgb,G_rgb;
    function [23:0] color_a;
        input integer x,y;
        begin color_a={x[7:0],y[7:0],x[7:0]^y[7:0]}; end
    endfunction
    function [23:0] color_b;
        input integer x,y;
        begin color_b={(8'hff-x[7:0]),(8'h7f^y[7:0]),(x[7:0]+y[7:0])}; end
    endfunction
    task golden;
        input integer x,y;
        input de;
        begin
            G_a=0; G_b=0; G_ax=x; G_ay=y; G_bx=x; G_by=y; G_weight=0;
            if(de && x<640 && y<480) begin
                if(S_progress==0) G_a=1;
                else if(S_progress==65536) begin G_b=1; G_weight=65536; end
                else case(S_effect)
                    0:begin G_a=1; G_b=1; G_weight=S_progress; end
                    1,2:if(x>=640-S_dx) begin G_b=1; G_bx=x-(640-S_dx); G_weight=65536; end
                        else begin G_a=1; if(S_effect==2) G_ax=x+S_dx; end
                    3:begin
                        G_q=x*480+y*640;
                        G_scaled=64'd614400*S_progress+32768;
                        G_b=G_q<G_scaled/65536; G_a=!G_b; G_weight=G_b ? 65536 : 0;
                    end
                    4:begin
                        G_local=(x/32)%2==0 ? x%32 : 31-x%32;
                        G_b=G_local<(32*S_progress+32768)/65536; G_a=!G_b; G_weight=G_b ? 65536 : 0;
                    end
                    5:begin
                        G_rank=(((x/8)*37)^((y/8)*73))&255;
                        G_b=G_rank<(256*S_progress+32768)/65536; G_a=!G_b; G_weight=G_b ? 65536 : 0;
                    end
                    6:begin
                        G_b=S_dx>0 && S_dy>0 && x>=S_left && x<S_left+S_dx && y>=S_top && y<S_top+S_dy;
                        G_a=!G_b; G_weight=G_b ? 65536 : 0;
                        if(G_b) begin
                            G_step=64'd41943040/S_dx;
                            G_bx=((x-S_left)*G_step+G_step/2)/65536;
                            G_step=64'd31457280/S_dy;
                            G_by=((y-S_top)*G_step+G_step/2)/65536;
                            if(G_bx>639) G_bx=639;
                            if(G_by>479) G_by=479;
                        end
                    end
                endcase
            end
            if(!G_a) begin G_ax=0; G_ay=0; end
            if(!G_b) begin G_bx=0; G_by=0; end
            G_argb=G_a ? color_a(G_ax,G_ay) : 24'd0;
            G_brgb=G_b ? color_b(G_bx,G_by) : 24'd0;
            G_rgb=0;
            for(G_c=0;G_c<3;G_c=G_c+1) begin
                G_value=(G_argb[G_c*8+:8]*(65536-G_weight)+G_brgb[G_c*8+:8]*G_weight+32768)/65536;
                if(G_value>255) G_value=255;
                G_rgb[G_c*8+:8]=G_value;
            end
        end
    endtask
    always @(posedge S_clk) begin
        if(S_reset) begin S_prev_valid=0; S_blend_valid_queue=0; end
        else begin
            golden(S_in_x,S_in_y,S_in_de);
            S_current_map={S_in_hsync,S_in_vsync,S_in_de,S_in_frame_start,S_in_line_start,S_in_x,S_in_y,
                G_a,G_b,G_ax[9:0],G_ay[8:0],G_bx[9:0],G_by[8:0],G_weight[16:0],S_epoch,S_tag};
            S_current_blend={S_in_hsync,S_in_vsync,S_in_de,S_in_frame_start,S_in_line_start,S_in_x,S_in_y,
                S_in_de ? G_rgb : 24'd0,S_epoch,S_tag,1'b0};
            #1;
            if(S_map_valid!==S_prev_valid) fail("map valid latency");
            if(S_prev_valid) begin
                if({S_map_hsync,S_map_vsync,S_map_de,S_map_frame_start,S_map_line_start,S_map_x,S_map_y,
                    S_map_use_a,S_map_use_b,S_map_a_x,S_map_a_y,S_map_b_x,S_map_b_y,S_map_weight,S_map_epoch,S_map_tag}!==S_prev_map)
                    fail("seven-effect mapping/control/identity vs independent integer reference");
                S_map_checked=S_map_checked+1;
            end
            if(S_blend_valid!==S_blend_valid_queue[2]) fail("combined map/blend valid latency");
            if(S_blend_valid_queue[2]) begin
                if({S_blend_hsync,S_blend_vsync,S_blend_de,S_blend_frame_start,S_blend_line_start,S_blend_x,
                    S_blend_y,S_blend_rgb,S_blend_epoch,S_blend_tag,S_blend_weight_error}!==S_expected_blend[2])
                    fail("combined map/blend independent RGB/control/identity");
                S_blend_checked=S_blend_checked+1;
            end
            S_prev_map=S_current_map; S_prev_valid=S_in_valid && S_map_configured;
            S_expected_blend[2]=S_expected_blend[1]; S_expected_blend[1]=S_expected_blend[0]; S_expected_blend[0]=S_current_blend;
            S_blend_valid_queue={S_blend_valid_queue[1:0],S_in_valid && S_map_configured};
        end
    end
    task configure;
        input integer effect,progress;
        reg [208:0] saved;
        reg [63:0] value;
        begin
            S_case=S_case+1; S_effect=effect; S_progress=progress; S_epoch=S_epoch+1; S_tag=S_tag+1; S_hold_plan=1;
            S_dx=(640*progress+32768)/65536; S_dy=(480*progress+32768)/65536;
            S_left=(640-S_dx)/2; S_top=(480-S_dy)/2;
            @(negedge S_clk); S_cmd_effect=effect; S_cmd_progress=progress;
            S_cmd_epoch=S_epoch; S_cmd_tag=S_tag; S_cmd_start_valid=1;
            @(posedge S_clk); while(!S_plan_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_cmd_start_valid=0;
            S_cmd_effect=7; S_cmd_progress=131071; S_cmd_epoch=0; S_cmd_tag=0;
            wait(S_plan_done_valid); #1;
            value=64'd614400*progress+32768;
            if(S_plan_error!==0 || S_plan_effect!==effect || S_plan_progress!==progress ||
                S_plan_epoch!==S_epoch || S_plan_tag!==S_tag || S_plan_dx!==S_dx || S_plan_dy!==S_dy ||
                S_plan_left!==S_left || S_plan_top!==S_top || S_plan_blind_count!==(32*progress+32768)/65536 ||
                S_plan_mosaic_count!==(256*progress+32768)/65536 || S_plan_wipe_threshold!==value/65536)
                fail("plan snapshot/rounded constants");
            if(effect==6 && S_dx!=0 && S_dy!=0 &&
                (S_plan_step_x!==64'd41943040/S_dx || S_plan_step_y!==64'd31457280/S_dy)) fail("restoring divide vs direct quotient");
            saved={S_plan_error,S_plan_effect,S_plan_progress,S_plan_epoch,S_plan_tag,S_plan_dx,S_plan_left,
                S_plan_dy,S_plan_top,S_plan_blind_count,S_plan_mosaic_count,S_plan_wipe_threshold,S_plan_step_x,S_plan_step_y};
            repeat(4) begin @(negedge S_clk);
                if(!S_plan_done_valid || saved!=={S_plan_error,S_plan_effect,S_plan_progress,S_plan_epoch,S_plan_tag,
                    S_plan_dx,S_plan_left,S_plan_dy,S_plan_top,S_plan_blind_count,S_plan_mosaic_count,
                    S_plan_wipe_threshold,S_plan_step_x,S_plan_step_y}) fail("plan result changed during backpressure"); end
            S_hold_plan=0;
            wait(!S_plan_done_valid); @(negedge S_clk);
            if(!S_map_configured) fail("valid plan not installed");
        end
    endtask
    task sample;
        input integer x,y;
        input de;
        begin
            @(negedge S_clk); S_in_valid=1; S_in_x=x; S_in_y=y; S_in_de=de;
            S_in_hsync=x%7==0; S_in_vsync=y%11==0; S_in_frame_start=x==0 && y==0; S_in_line_start=x==0;
            S_issued=S_issued+1;
            #1; if(S_map_config_ready) fail("configuration accepted while raster input active");
        end
    endtask
    task drain;
        begin
            @(negedge S_clk); S_in_valid=0;
            repeat(6) @(negedge S_clk);
            if(S_map_checked!=S_issued || S_blend_checked!=S_issued) fail("dropped/duplicated map/blend pixel");
        end
    endtask
    task query_rows;
        integer row,x;
        reg seen_a,seen_b;
        reg [8:0] ay,by;
        begin
            for(row=0;row<480;row=row+1) begin
                @(negedge S_clk); S_in_query_y=row; #1;
                seen_a=0; seen_b=0; ay=0; by=0;
                for(x=0;x<640;x=x+1) begin
                    golden(x,row,1);
                    if(G_a) begin seen_a=1; ay=G_ay; end
                    if(G_b) begin seen_b=1; by=G_by; end
                end
                if((seen_a && (!S_map_query_use_a || S_map_query_a_y!==ay)) ||
                    (seen_b && (!S_map_query_use_b || S_map_query_b_y!==by))) fail("line query omitted a source row");
                if(S_map_query_use_a && S_map_query_a_y>=480) fail("query A out of bounds");
                if(S_map_query_use_b && S_map_query_b_y>=480) fail("query B out of bounds");
            end
            @(negedge S_clk); S_in_query_y=480; #1;
            if(S_map_query_use_a || S_map_query_use_b) fail("invalid query row");
        end
    endtask
    integer effect,p,x,y,t;
    initial begin
        S_reset=1; repeat(4) @(negedge S_clk); S_reset=0;
        for(effect=0;effect<7;effect=effect+1) begin
            for(p=0;p<7;p=p+1) begin
                case(p) 0:t=0; 1:t=1; 2:t=69; 3:t=16384; 4:t=32768; 5:t=65535; 6:t=65536; endcase
                configure(effect,t); query_rows;
                if(p==0 || p==4 || p==6) begin
                    for(y=0;y<480;y=y+1) for(x=0;x<640;x=x+1) sample(x,y,1);
                end else begin
                    for(y=0;y<480;y=y+7) for(x=0;x<640;x=x+5) sample(x,y,1);
                    sample(S_left,S_top,1); sample(S_left+S_dx-1,S_top+S_dy-1,1);
                end
                sample(640,480,1); sample(65535,65535,0); sample(0,0,0); drain;
            end
        end
        // Illegal plan cannot overwrite the last installed valid mapping.
        @(negedge S_clk); S_cmd_effect=7; S_cmd_progress=32768; S_cmd_start_valid=1;
        @(negedge S_clk); S_cmd_start_valid=0;
        wait(S_plan_done_valid); #1; if(S_plan_error!==1) fail("invalid effect plan");
        wait(!S_plan_done_valid);
        @(negedge S_clk); S_cmd_effect=0; S_cmd_progress=65537; S_cmd_start_valid=1;
        @(negedge S_clk); S_cmd_start_valid=0;
        wait(S_plan_done_valid); #1; if(S_plan_error!==1) fail("invalid progress plan");
        wait(!S_plan_done_valid);
        // Invalid plans leave the last valid full-B image and identity installed.
        sample(17,23,1); sample(639,479,1); drain;
        // A one-pixel-wide but zero-height zoom rectangle remains empty.
        configure(6,52); query_rows;
        sample(S_left,S_top,1); sample(0,0,1); sample(639,479,1); drain;
        // Sparse input must preserve exactly the same two-plus-two-stage latency.
        configure(6,32768);
        for(x=0;x<64;x=x+1) begin
            sample(x*9,(x*13)%480,1);
            @(negedge S_clk); S_in_valid=0;
            repeat(x%4) @(negedge S_clk);
        end
        drain;
        // Interrupt an in-flight divider; reset must discard the pending plan.
        @(negedge S_clk); S_hold_plan=1; S_cmd_effect=6; S_cmd_progress=16384; S_cmd_start_valid=1;
        @(negedge S_clk); S_cmd_start_valid=0;
        repeat(8) @(negedge S_clk);
        if(S_plan_done_valid || S_plan_start_ready) fail("zoom plan skipped iterative division");
        S_reset=1;
        repeat(3) @(negedge S_clk); S_reset=0; S_hold_plan=0;
        S_issued=0; S_map_checked=0; S_blend_checked=0;
        if(S_plan_done_valid || S_map_configured || S_map_valid || S_blend_valid)
            fail("reset retained plan/configuration/pixels");
        // Raster input before configuration cannot publish a valid sample.
        S_in_valid=1;
        repeat(4) @(negedge S_clk);
        S_in_valid=0;
        repeat(5) @(negedge S_clk);
        configure(0,32768); sample(31,37,1); drain;
        // Interrupt pixels between the mapper and blender, then recover afresh.
        sample(101,103,1);
        @(negedge S_clk); S_reset=1;
        S_in_valid=0;
        repeat(3) @(negedge S_clk); S_reset=0;
        S_issued=0; S_map_checked=0; S_blend_checked=0;
        if(S_map_configured || S_map_valid || S_blend_valid) fail("reset retained active mapping/pixels");
        configure(6,65536); sample(13,19,1); sample(639,479,1); drain;
        S_test_pass=1; $display("PASS: seven transitions/row queries/real blend matched independent reference"); $finish;
    end
endmodule
