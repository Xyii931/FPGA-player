`timescale 1ns/1ps
// Real transform, writer and slot manager. Only source pixels and logical write
// completions are endpoints. There is no file owner or physical SDRAM model.
module tb_image_transform_writer;
    reg S_clk=0,S_reset=0,S_start=0,S_abort=0,S_manager_valid=0,S_manager_result_ready=0;
    reg [2:0] S_manager_op=0;
    reg [31:0] S_token=0;
    reg [1:0] S_rotation=0;
    reg S_mode=0,S_bottom=0,S_iv=0,S_ilast=0,S_allow_source=1,S_hold_tail=0;
    reg [15:0] S_x=0,S_y=0,S_tag=0;
    reg [31:0] S_data=0;
    wire S_tready,S_geometry,S_geometry_ready,S_pixel_valid,S_pixel_ready,S_pixel_last,S_tdone,S_tdone_ready,S_tcancel;
    wire [31:0] S_pixel,S_wgeneration;
    wire [15:0] S_pw,S_ph,S_ix,S_iy,S_iw,S_ih,S_px,S_py;
    wire [3:0] S_terror;
    wire S_wready,S_wdone,S_memory_retired,S_producer_retired,S_mem_valid,S_mem_response_ready;
    wire S_geometry_ready_pixel,S_wsource_ready;
    wire [3:0] S_werror;
    wire [31:0] S_mem_tag,S_mem_token,S_mem_generation,S_accepted,S_retired,S_pixels;
    wire [20:0] S_mem_addr;
    wire [31:0] S_mem_data;
    reg S_mem_ready=0,S_reply=0;
    reg [31:0] S_reply_tag=0;
    reg [31:0] S_qtags[0:15];
    integer S_head=0,S_tail=0,S_pending=0,S_cycles=0,S_writes=0,S_completions=0;
    reg [31:0] S_frame[0:307199];
    wire S_manager_ready,S_manager_result;
    wire [3:0] S_manager_error;
    wire [31:0] S_manager_token;
    wire [17:0] S_states;
    wire [191:0] S_tokens;
    wire S_grant=S_states[5:3]==3'd1 && S_tokens[63:32]==S_token;
    reg S_transform_retired=0;
    integer S_case=0,S_r,S_a,S_b,S_i,S_gpw,S_gph,S_gix,S_giy,S_giw,S_gih,S_rw,S_rh;
    integer S_u,S_v,S_xout,S_yout,S_at;
    reg [31:0] S_expected;
    reg S_test_pass=0;
    always #4 S_clk=~S_clk;
    image_transform u_transform (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_tready),
        .I_src_width(16'd9),.I_src_height(16'd5),.I_rect_x(16'd11),.I_rect_y(16'd19),
        .I_rect_width(16'd17),.I_rect_height(16'd13),.I_rotation(S_rotation),.I_bilinear(S_mode),.I_bottom_up(S_bottom),
        .I_tag(S_tag),.I_generation(32'd7),.I_abort(S_abort || S_tcancel),.I_stream_error(1'b0),
        .O_geometry_valid(S_geometry),.I_geometry_ready(S_geometry_ready),.O_pre_width(S_pw),.O_pre_height(S_ph),
        .O_image_x(S_ix),.O_image_y(S_iy),.O_image_width(S_iw),.O_image_height(S_ih),
        .I_pixel_valid(S_iv),.O_pixel_ready(S_pixel_ready),.I_rgba(S_data),.I_x(S_x),.I_y(S_y),.I_pixel_last(S_ilast),
        .O_pixel_valid(S_pixel_valid),.I_pixel_ready(S_geometry_ready_pixel),.O_rgba(S_pixel),.O_x(S_px),.O_y(S_py),.O_pixel_last(S_pixel_last),
        .O_busy(),.O_done_valid(S_tdone),.I_done_ready(S_tdone_ready),.O_error(S_terror),.O_tag(),.O_generation()
    );
    assign S_geometry_ready=S_wready;
    assign S_tdone_ready=S_allow_source && S_wsource_ready;
    fb_writer u_writer (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(1'b1),.I_media_generation(32'd7),
        .I_start_valid(S_geometry),.O_start_ready(S_wready),.I_lease_grant(S_grant),.I_op(2'd2),.I_slot(3'd1),
        .I_lease_token(S_token),.I_generation(32'd7),.I_tag(S_tag),.I_resident(1'b0),.I_clear_rgba(32'h000000ff),
        .I_pre_width(S_pw),.I_pre_height(S_ph),.I_image_x(S_ix),.I_image_y(S_iy),.I_rotation(S_rotation),
        .I_bottom_up(S_bottom),.I_source_expected(1'b1),.I_abort(S_abort),
        .I_pixel_valid(S_pixel_valid),.O_pixel_ready(S_geometry_ready_pixel),.I_rgba(S_pixel),.I_x(S_px),.I_y(S_py),.I_pixel_last(S_pixel_last),
        .I_source_valid(S_tdone && S_allow_source),.O_source_ready(S_wsource_ready),.I_source_tag(S_tag),
        .I_source_lease_token(S_token),.I_source_generation(32'd7),.I_source_error(S_terror),.O_cancel_source(S_tcancel),
        .O_mem_valid(S_mem_valid),.I_mem_ready(S_mem_ready),.O_mem_wr(),.O_mem_addr(S_mem_addr),.O_mem_data(S_mem_data),
        .O_mem_tag(S_mem_tag),.O_mem_mask(),.O_mem_lease_token(S_mem_token),.O_mem_generation(S_mem_generation),
        .I_mem_done_valid(S_reply),.O_mem_done_ready(S_mem_response_ready),.I_mem_done_tag(S_reply_tag),
        .I_mem_done_lease_token(S_token),.I_mem_done_generation(32'd7),.I_mem_done_error(4'd0),
        .O_busy(),.O_done_valid(S_wdone),.I_done_ready(S_manager_result && S_manager_result_ready),
        .O_error(S_werror),.O_memory_error(),.O_source_error(),.O_tag(),.O_slot(),.O_lease_token(),.O_generation(S_wgeneration),
        .O_accepted_writes(S_accepted),.O_retired_writes(S_retired),.O_pixels(S_pixels),
        .O_memory_retired(S_memory_retired),.O_producer_retired(S_producer_retired),
        .O_response_discarded(),.O_source_discarded(),.O_tag_exhausted(),
        .I_layout(3'd0),
        .I_clear_x(16'd0),
        .I_clear_y(16'd0),
        .I_clear_width(16'd0),
        .I_clear_height(16'd0)
    );
    fb_slot_manager u_slots (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(1'b1),.I_media_generation(32'd7),
        .I_cmd_valid(S_manager_valid),.O_cmd_ready(S_manager_ready),.I_cmd_op(S_manager_op),.I_cmd_slot(3'd1),.I_cmd_owner(2'd0),
        .I_cmd_token(S_token),.I_cmd_generation(32'd7),.I_cmd_asset(32'd123),.I_cmd_layout(3'd0),.I_cmd_rotation(S_rotation),
        .I_cmd_resident(1'b0),.I_cmd_success(S_werror==0),
        .I_producer_retired(S_wdone && S_producer_retired),.I_memory_retired(S_wdone && S_memory_retired),
        .I_reader_retired(1'b0),.I_frame_boundary(1'b0),.O_result_valid(S_manager_result),.I_result_ready(S_manager_result_ready),
        .O_result_error(S_manager_error),.O_result_op(),.O_result_slot(),.O_result_owner(),
        .O_result_token(S_manager_token),.O_result_generation(),.O_result_base(),.O_slot_states(S_states),
        .O_slot_tokens(S_tokens),.O_slot_generations(),.O_slot_assets(),.O_slot_layouts(),.O_slot_readers(),
        .O_slot_rotations(),.O_slot_resident(),.O_slot_stale(),.O_cancel_loading(),.O_token_exhausted()
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL transform-writer case=%0d writes=%0d pending=%0d: %0s",S_case,S_writes,S_pending,message); $stop; end
    endtask
    function [31:0] image;
        input integer x,y;
        begin
            image[31:24]=(x*37+y*19+13)&255;
            image[23:16]=(x*11+y*71+27)&255;
            image[15:8]=(x*97+y*7+41)&255;
            image[7:0]=255;
        end
    endfunction
    function [31:0] golden;
        input integer u,v;
        reg signed [63:0] px,py,sx,sy;
        reg [63:0] fx,fy,wx,wy,total;
        reg [31:0] a,b,c,d;
        integer x0,y0,x1,y1,ch;
        begin
            sx=(9*64'd65536)/S_gpw; sy=(5*64'd65536)/S_gph;
            px=(sx/2)-32768+u*sx; py=(sy/2)-32768+v*sy;
            if (!S_mode) begin px=px+32768; py=py+32768; end
            if (px<0) px=0; if (py<0) py=0;
            if (px>8*64'sd65536) px=8*64'sd65536;
            if (py>4*64'sd65536) py=4*64'sd65536;
            x0=px/65536; y0=py/65536; x1=x0<8 ? x0+1 : x0; y1=y0<4 ? y0+1 : y0;
            fx=S_mode ? px%65536 : 0; fy=S_mode ? py%65536 : 0; wx=65536-fx; wy=65536-fy;
            a=image(x0,y0); b=image(x1,y0); c=image(x0,y1); d=image(x1,y1);
            for (ch=0;ch<4;ch=ch+1) begin
                total=a[31-ch*8 -: 8]*wx*wy+b[31-ch*8 -: 8]*fx*wy+
                    c[31-ch*8 -: 8]*wx*fy+d[31-ch*8 -: 8]*fx*fy+64'd2147483648;
                golden[31-ch*8 -: 8]=total>>32;
            end
        end
    endfunction
    always @(negedge S_clk) begin
        S_cycles=S_cycles+1; S_mem_ready=S_cycles%13>2;
        S_reply=S_pending>0 && S_cycles%5==0 && !(S_hold_tail && S_pixels==S_gpw*S_gph);
        if (S_pending>0) S_reply_tag=S_qtags[S_head];
    end
    always @(posedge S_clk) begin
        if (S_reset) begin S_head=0; S_tail=0; S_pending=0; S_transform_retired=0; end
        else begin
            if (S_mem_valid && S_mem_ready) begin
                if (S_mem_addr<21'd307200 || S_mem_addr>=21'd614400 || S_mem_token!=S_token || S_mem_generation!=7)
                    fail("write escaped held lease");
                S_frame[S_mem_addr-307200]=S_mem_data;
                S_qtags[S_tail]=S_mem_tag; S_tail=(S_tail+1)%16; S_pending=S_pending+1; S_writes=S_writes+1;
            end
            if (S_reply && S_mem_response_ready) begin
                S_head=(S_head+1)%16; S_pending=S_pending-1; S_completions=S_completions+1;
            end
            if (S_pending>8) fail("pending credit overflow");
            if (S_tdone && S_tdone_ready) begin
                if (S_terror!=0) fail("transform rejected normal job");
                S_transform_retired=1;
            end
            if (S_manager_valid && S_manager_op==1 && !S_wdone && S_manager_ready)
                fail("READY permission before writer joined source and memory");
        end
    end
    task pixel;
        input integer x,y,last;
        begin
            @(negedge S_clk); S_iv=1; S_x=x; S_y=y; S_data=image(x,y); S_ilast=last;
            @(posedge S_clk); while (!S_pixel_ready) @(posedge S_clk);
            @(negedge S_clk); S_iv=0;
        end
    endtask
    task manager;
        input integer op;
        begin
            @(negedge S_clk); S_manager_op=op; S_manager_valid=1;
            @(posedge S_clk); while (!S_manager_ready) @(posedge S_clk);
            @(negedge S_clk); S_manager_valid=0;
            if (!S_manager_result || S_manager_error!=0) fail("slot command failed");
            if (op==0) S_token=S_manager_token;
            S_manager_result_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_manager_result_ready=0;
        end
    endtask
    initial begin
        S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        for (S_r=0;S_r<4;S_r=S_r+1) begin
            S_case=S_r+1; S_rotation=S_r; S_mode=S_r%2; S_bottom=S_r/2; S_tag=S_case;
            S_writes=0; S_completions=0; S_transform_retired=0;
            S_rw=(S_r%2) ? 5 : 9; S_rh=(S_r%2) ? 9 : 5;
            S_giw=17; S_gih=13;
            if (17*S_rh<=13*S_rw) S_gih=(S_rh*17)/S_rw; else S_giw=(S_rw*13)/S_rh;
            S_gix=11+(17-S_giw)/2; S_giy=19+(13-S_gih)/2;
            S_gpw=(S_r%2) ? S_gih : S_giw; S_gph=(S_r%2) ? S_giw : S_gih;
            for (S_i=0;S_i<307200;S_i=S_i+1) S_frame[S_i]=32'hff00ffff;
            manager(0);
            @(negedge S_clk); S_start=1;
            @(posedge S_clk); if (!S_tready) fail("transform not ready");
            @(negedge S_clk); S_start=0;
            // Hold one side of the join; both directions must keep the slot LOADING.
            S_allow_source=S_r%2; S_hold_tail=S_r%2;
            wait (S_geometry && S_geometry_ready);
            @(posedge S_clk); @(negedge S_clk);
            S_manager_op=1; S_manager_valid=1;
            for (S_b=0;S_b<5;S_b=S_b+1)
                for (S_a=0;S_a<9;S_a=S_a+1) pixel(S_a,S_bottom ? 4-S_b : S_b,S_a==8 && S_b==4);
            if (S_r%2) begin
                wait (S_transform_retired); repeat (5) @(negedge S_clk);
                if (S_wdone || S_states[5:3]!=1 || S_pending==0) fail("source completion bypassed memory retirement");
                S_hold_tail=0;
            end else begin
                wait (S_pixels==S_gpw*S_gph && S_memory_retired);
                repeat (5) @(negedge S_clk);
                if (S_wdone || S_states[5:3]!=1 || S_producer_retired) fail("memory completion bypassed source retirement");
                S_allow_source=1;
            end
            @(posedge S_clk); while (!S_manager_ready) @(posedge S_clk);
            @(negedge S_clk); S_manager_valid=0;
            if (!S_manager_result || S_manager_error!=0 || !S_wdone || S_werror!=0 || S_states[5:3]!=2 ||
                S_writes!=307200+S_gpw*S_gph || S_completions!=S_writes || S_accepted!=S_retired ||
                S_wgeneration!=7 || S_pending!=0 || !S_transform_retired) fail("joined commit/retirement totals");
            // Check every background pixel and every rotated/scaled region pixel.
            for (S_i=0;S_i<307200;S_i=S_i+1) begin
                S_xout=S_i%640; S_yout=S_i/640;
                if (S_xout<S_gix || S_xout>=S_gix+S_giw || S_yout<S_giy || S_yout>=S_giy+S_gih)
                    if (S_frame[S_i]!==32'h000000ff) fail("uncleared background");
            end
            for (S_v=0;S_v<S_gph;S_v=S_v+1)
                for (S_u=0;S_u<S_gpw;S_u=S_u+1) begin
                    case (S_r)
                        0:begin S_xout=S_u; S_yout=S_v; end
                        1:begin S_xout=S_gph-1-S_v; S_yout=S_u; end
                        2:begin S_xout=S_gpw-1-S_u; S_yout=S_gph-1-S_v; end
                        3:begin S_xout=S_v; S_yout=S_gpw-1-S_u; end
                    endcase
                    S_at=(S_giy+S_yout)*640+S_gix+S_xout; S_expected=golden(S_u,S_v);
                    if (S_frame[S_at]!==S_expected) fail("final golden pixel mismatch");
                end
            S_manager_result_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_manager_result_ready=0;
            manager(4);
        end
        S_test_pass=1;
        $display("PASS: real transform/writer/slot manager, complete clear and golden frame, four rotations, both retirement orders");
        $finish;
    end
    initial begin #1000000000; fail("timeout"); end
endmodule
