`timescale 1ns/1ps
// Public-port fixtures only. No vendor HDMI, physical phase or board validation.
module tb_player_board;
    reg S_clk=0,S_video_clk=0;
    always #4 S_clk=~S_clk;
    always #20 S_video_clk=~S_video_clk;
    reg S_reset=1;
    reg S_de=0,S_pixel_valid=1,S_ready=0;
    reg [15:0] S_x=0,S_y=0;
    reg [23:0] S_rgb=0;
    wire S_valid,S_user,S_last,S_sink_reset,S_fault;
    wire [23:0] S_data;
    wire [31:0] S_restarts;
    wire [4:0] S_level;
    reg S_scoreboard=1,S_stalled=0;
    reg [25:0] S_previous;
    reg [25:0] S_expected[0:1023];
    integer S_written=0,S_received=0;
    reg S_ready_pattern=0;
    integer S_ready_cycle=0;
    reg S_bridge_done=0,S_controls_done=0,S_cdc_done=0,S_long_done=0,S_color_done=0;
    reg S_test_pass=0;
    scanout_axis_bridge #(.ADDR_BITS(4),.HACTIVE(8),.VACTIVE(4),.PREFILL(4),.RESET_CYCLES(4)) u_bridge (
        .I_clk(S_clk),.I_reset(S_reset),.I_de(S_de),.I_valid(S_pixel_valid),.I_x(S_x),.I_y(S_y),.I_rgb(S_rgb),
        .I_ready(S_ready),.O_valid(S_valid),.O_user(S_user),.O_last(S_last),.O_data(S_data),
        .O_sink_reset(S_sink_reset),.O_fault(S_fault),.O_restart_count(S_restarts),.O_level(S_level)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: %0s",message); $stop; end
    endtask
    always @(negedge S_clk) begin
        if(S_ready_pattern) begin S_ready_cycle=S_ready_cycle+1; S_ready=(S_ready_cycle%4)!=0; end
    end
    always @(posedge S_clk) begin
        if(S_reset || S_sink_reset) S_stalled=0;
        else begin
            if(S_stalled && (!S_valid || {S_user,S_last,S_data}!==S_previous)) fail("AXIS payload changed under backpressure");
            S_stalled=S_valid && !S_ready; S_previous={S_user,S_last,S_data};
            if(S_valid && S_ready && S_scoreboard) begin
                if(S_received>=S_written || {S_user,S_last,S_data}!==S_expected[S_received]) fail("pixel/SOF/EOL mismatch or duplicate");
                S_received=S_received+1;
            end
        end
    end
    task automatic frame;
        input integer identity;
        input integer blank_cycles;
        input integer record_pixels;
        integer tx,ty;
        reg [23:0] pixel;
        begin
            for(ty=0;ty<4;ty=ty+1) begin
                for(tx=0;tx<8;tx=tx+1) begin
                    @(negedge S_clk);
                    S_de=1; S_x=tx; S_y=ty; S_pixel_valid=tx!=5;
                    pixel=identity*256+ty*8+tx; S_rgb=pixel;
                    if(record_pixels) begin
                        S_expected[S_written]={tx==0 && ty==0,tx==7,tx==5 ? 24'd0 : pixel};
                        S_written=S_written+1;
                    end
                end
                @(negedge S_clk); S_de=0;
                repeat(blank_cycles) @(negedge S_clk);
            end
        end
    endtask
    initial begin
        repeat(4) @(negedge S_clk); S_reset=0;
        repeat(8) @(negedge S_clk);
        S_ready_pattern=1;
        frame(1,4,1); frame(2,4,1); frame(3,4,1);
        @(negedge S_clk); S_de=0;
        repeat(40) @(negedge S_clk);
        if(S_received!=96 || S_restarts!=0 || S_fault) fail("normal stream lost data or restarted");
        // Unbounded sink stall is an explicit output-session failure, never hidden loss.
        S_scoreboard=0; S_ready_pattern=0; S_ready=0;
        frame(4,0,0);
        if(S_restarts!=1 || !S_fault || !S_sink_reset) fail("overflow did not restart only the sink session");
        repeat(8) @(negedge S_clk);
        S_received=0; S_written=0; S_scoreboard=1; S_ready=1;
        frame(5,4,1);
        @(negedge S_clk); S_de=0;
        repeat(30) @(negedge S_clk);
        if(S_received!=32 || S_restarts!=1) fail("complete next frame did not recover after overflow");
        S_scoreboard=0;
        @(negedge S_clk); S_de=1; S_x=3; S_y=2;
        @(negedge S_clk); S_de=0;
        if(S_restarts!=2 || !S_sink_reset) fail("coordinate discontinuity accepted as a complete frame");
        S_bridge_done=1;
    end

    reg [3:0] S_key_n=15,S_switch_in=0;
    wire [3:0] S_keys,S_switch,S_release,S_switch_change;
    wire S_switch_initialized,S_auto,S_pause,S_mute,S_next,S_prev,S_reload,S_rescan,S_menu;
    wire [2:0] S_menu_row;
    integer S_prev_count=0,S_next_count=0,S_reload_count=0,S_rescan_count=0;
    board_inputs #(.DEBOUNCE_CYCLES(4)) u_inputs (
        .I_clk(S_clk),.I_reset(S_reset),.I_key_n(S_key_n),.I_switch(S_switch_in),
        .O_keys(S_keys),.O_switch(S_switch),.O_key_release(S_release),.O_switch_changed(S_switch_change),
        .O_switch_initialized(S_switch_initialized)
    );
    player_board_ctrl u_controls (
        .I_clk(S_clk),.I_reset(S_reset),.I_key_release(S_release),.I_switch(S_switch),
        .I_switch_changed(S_switch_change),.I_switch_initialized(S_switch_initialized),
        .O_auto(S_auto),.O_pause(S_pause),.O_mute(S_mute),.O_next(S_next),.O_prev(S_prev),
        .O_reload(S_reload),.O_rescan(S_rescan),.O_menu(S_menu),.O_menu_row(S_menu_row)
    );
    always @(posedge S_clk) if(!S_reset) begin
        if(S_prev) S_prev_count=S_prev_count+1;
        if(S_next) S_next_count=S_next_count+1;
        if(S_reload) S_reload_count=S_reload_count+1;
        if(S_rescan) S_rescan_count=S_rescan_count+1;
    end
    task automatic key;
        input integer which;
        begin
            @(negedge S_clk); S_key_n[which]=0;
            repeat(12) @(negedge S_clk);
            S_key_n[which]=1;
            repeat(12) @(negedge S_clk);
        end
    endtask
    initial begin
        wait(!S_reset); repeat(20) @(negedge S_clk);
        if(!S_switch_initialized || S_auto) fail("startup switch snapshot did not establish AUTO off");
        // A short physical bounce must not emit NEXT.
        S_key_n[1]=0; @(negedge S_clk); S_key_n[1]=1;
        repeat(12) @(negedge S_clk);
        if(S_next_count!=0) fail("key bounce generated navigation");
        key(0); key(1); key(2);
        if(S_prev_count!=1 || S_next_count!=1 || !S_auto) fail("normal navigation/AUTO mapping");
        repeat(12) @(negedge S_clk);
        if(!S_auto) fail("unchanged SW1 overwrote KEY3 AUTO request");
        S_switch_in[0]=1; repeat(16) @(negedge S_clk);
        S_switch_in[0]=0; repeat(16) @(negedge S_clk);
        if(S_auto) fail("SW1 change was not processed");
        key(3); key(1); key(2);
        if(!S_menu || S_menu_row!=1 || !S_pause) fail("menu pause action");
        key(1); key(2);
        if(!S_mute) fail("menu mute action");
        key(1); key(2);
        if(S_menu || S_rescan_count!=1 || S_prev_count!=1 || S_next_count!=1) fail("menu rescan/navigation isolation");
        key(3); key(1); key(2);
        if(S_menu || S_reload_count!=1) fail("menu reload action");
        S_controls_done=1;
    end

    reg [15:0] S_ui_state=0;
    reg S_frame_start=0;
    wire [15:0] S_ui_video;
    video_ui_cdc u_ui (
        .I_host_clk(S_clk),.I_video_clk(S_video_clk),.I_async_reset(S_reset),
        .I_frame_start(S_frame_start),.I_state(S_ui_state),.O_state(S_ui_video)
    );
    initial begin
        wait(!S_reset); repeat(8) @(negedge S_video_clk);
        S_ui_state=16'h12a5;
        repeat(12) @(negedge S_video_clk);
        if(S_ui_video!=0) fail("UI changed outside frame boundary");
        S_frame_start=1; @(negedge S_video_clk); S_frame_start=0;
        if(S_ui_video!=16'h12a5) fail("UI mailbox tore its first payload");
        S_ui_state=16'hbeef;
        repeat(12) @(negedge S_video_clk);
        if(S_ui_video!=16'h12a5) fail("UI changed during active frame");
        S_frame_start=1; @(negedge S_video_clk); S_frame_start=0;
        if(S_ui_video!=16'hbeef) fail("UI mailbox lost subsequent payload");
        S_cdc_done=1;
    end

    reg S_long_key_n=1;
    wire S_global_reset;
    key_long_reset #(.DEBOUNCE_CYCLES(4),.HOLD_CYCLES(20)) u_long (
        .I_clk(S_clk),.I_startup_reset(S_reset),.I_key_n(S_long_key_n),.O_global_reset(S_global_reset)
    );
    initial begin
        wait(!S_reset); repeat(8) @(negedge S_clk);
        S_long_key_n=0; repeat(12) @(negedge S_clk);
        if(S_global_reset) fail("short press caused global reset");
        S_long_key_n=1; repeat(12) @(negedge S_clk);
        S_long_key_n=0; repeat(40) @(negedge S_clk);
        if(!S_global_reset) fail("long press did not cause reset");
        repeat(40) @(negedge S_clk);
        if(!S_global_reset) fail("long detector cleared its own reset request while held");
        S_long_key_n=1; repeat(12) @(negedge S_clk);
        if(S_global_reset) fail("long reset failed to release");
        S_long_done=1;
    end
    reg [23:0] S_color_input=0;
    reg [3:0] S_brightness=0,S_contrast=0;
    reg [4:0] S_saturation=8;
    reg S_color_de=1;
    wire [23:0] S_color_output;
    video_color_adjust u_color (
        .I_de(S_color_de),.I_rgb(S_color_input),.I_brightness(S_brightness),
        .I_contrast(S_contrast),.I_saturation(S_saturation),.O_rgb(S_color_output)
    );
    function integer clip;
        input integer value;
        begin clip=value<0 ? 0 : value>255 ? 255 : value; end
    endfunction
    function integer floor_eighth;
        input integer value;
        begin floor_eighth=value<0 ? -((-value+7)/8) : value/8; end
    endfunction
    // Independent integer/division oracle, deliberately different from RTL widths/shifts.
    function [23:0] reference_color;
        input integer red,green,blue,brightness,contrast,saturation;
        integer rr,gg,bb,yy;
        begin
            rr=clip(floor_eighth((red-128)*(8+contrast)+4)+128);
            gg=clip(floor_eighth((green-128)*(8+contrast)+4)+128);
            bb=clip(floor_eighth((blue-128)*(8+contrast)+4)+128);
            yy=(77*rr+150*gg+29*bb+128)/256;
            rr=clip(clip(floor_eighth((rr-yy)*saturation+4)+yy)+16*brightness);
            gg=clip(clip(floor_eighth((gg-yy)*saturation+4)+yy)+16*brightness);
            bb=clip(clip(floor_eighth((bb-yy)*saturation+4)+yy)+16*brightness);
            reference_color={rr[7:0],gg[7:0],bb[7:0]};
        end
    endfunction
    integer S_cr,S_cg,S_cb,S_cbri,S_ccon,S_csat;
    initial begin
        for(S_cbri=-4;S_cbri<=4;S_cbri=S_cbri+4)
            for(S_ccon=-4;S_ccon<=4;S_ccon=S_ccon+4)
                for(S_csat=0;S_csat<=16;S_csat=S_csat+8)
                    for(S_cr=0;S_cr<=255;S_cr=S_cr+51)
                        for(S_cg=0;S_cg<=255;S_cg=S_cg+51)
                            for(S_cb=0;S_cb<=255;S_cb=S_cb+51) begin
                                S_color_input={S_cr[7:0],S_cg[7:0],S_cb[7:0]};
                                S_brightness=S_cbri; S_contrast=S_ccon; S_saturation=S_csat;
                                #1;
                                if(S_color_output!==reference_color(S_cr,S_cg,S_cb,S_cbri,S_ccon,S_csat))
                                    fail("signed color rounding or stage clipping mismatch");
                            end
        S_color_de=0; #1;
        if(S_color_output!==24'd0) fail("color adjustment changed blanking into active RGB");
        S_color_done=1;
    end
    initial begin
        wait(S_bridge_done && S_controls_done && S_cdc_done && S_long_done && S_color_done);
        $display("PASS: board playback controls, raster/AXIS buffering and frame UI mailbox");
        S_test_pass=1; $finish;
    end
    initial begin #2000000; fail("player_board watchdog"); end
endmodule
