`timescale 1ns/1ps
// Real parser + real scaler. Byte producer and candidate-pixel receiver are fixtures.
// The small owner below joins both terminal results; it is not a framebuffer owner.
module tb_bmp_image_scaler;
    reg S_clk=0,S_reset=0,S_start=0,S_abort=0,S_stream_error=0;
    reg [31:0] S_size=0;
    reg [7:0] S_tag=0,S_byte=0;
    reg S_byte_valid=0,S_byte_last=0,S_meta_allow=0,S_ready=0,S_result_ready=0;
    reg [15:0] S_dw=1,S_dh=1;
    reg S_bilinear=0;
    wire S_start_ready,S_parser_busy,S_parser_done,S_parser_err,S_byte_ready,S_header;
    wire S_pixel_valid,S_pixel_ready,S_bottom_up,S_in_last;
    wire [3:0] S_parser_code;
    wire [7:0] S_parser_tag;
    wire [15:0] S_sw,S_sh,S_in_x,S_in_y;
    wire [5:0] S_bpp;
    wire [31:0] S_offset,S_stride,S_in_rgba;
    wire S_scaler_ready,S_scaler_busy,S_done,S_valid,S_last;
    wire [3:0] S_code;
    wire [31:0] S_rgba,S_generation;
    wire [15:0] S_x,S_y,S_out_tag;
    reg [7:0] S_file[0:16383];
    integer S_w,S_h,S_target_w,S_target_h,S_bits,S_mode,S_bottom,S_total,S_rowbytes;
    integer S_i,S_r,S_c,S_k,S_at,S_case=0,S_cycles=0,S_count=0,S_headers=0,S_terminals=0;
    integer S_expected_code=0,S_expected_x,S_expected_y;
    reg S_test_pass=0,S_waiting=0;
    reg [64:0] S_saved;
    reg S_seen_scaler_first=0,S_inject_late_error=0,S_file_failed=0;
    always #4 S_clk=~S_clk;

    bmp_parser u_parser (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(S_size),.I_tag(S_tag),.O_busy(S_parser_busy),.O_done(S_parser_done),.O_err(S_parser_err),
        .O_error_code(S_parser_code),.O_tag(S_parser_tag),.I_byte_valid(S_byte_valid),
        .O_byte_ready(S_byte_ready),.I_byte_data(S_byte),.I_byte_last(S_byte_last),
        .I_stream_error(S_stream_error),.I_abort(S_abort),.O_header_valid(S_header),
        .I_header_ready(S_meta_allow && S_scaler_ready),.O_width(S_sw),.O_height(S_sh),
        .O_bottom_up(S_bottom_up),.O_bpp(S_bpp),.O_pixel_offset(S_offset),.O_row_bytes(S_stride),
        .O_pixel_valid(S_pixel_valid),.I_pixel_ready(S_pixel_ready),.O_rgba(S_in_rgba),
        .O_x(S_in_x),.O_y(S_in_y),.O_pixel_last(S_in_last)
    );
    image_scaler u_scaler (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_header && S_meta_allow),.O_start_ready(S_scaler_ready),
        .I_src_width(S_sw),.I_src_height(S_sh),.I_dst_width(S_dw),.I_dst_height(S_dh),
        .I_bilinear(S_bilinear),.I_bottom_up(S_bottom_up),.I_tag({8'd0,S_tag}),.I_generation(32'h87654321),
        .I_abort(S_abort),.I_stream_error(S_stream_error || (S_parser_done && S_parser_err)),
        .I_pixel_valid(S_pixel_valid),.O_pixel_ready(S_pixel_ready),.I_rgba(S_in_rgba),
        .I_x(S_in_x),.I_y(S_in_y),.I_pixel_last(S_in_last),
        .O_pixel_valid(S_valid),.I_pixel_ready(S_ready),.O_rgba(S_rgba),.O_x(S_x),.O_y(S_y),.O_pixel_last(S_last),
        .O_busy(S_scaler_busy),.O_done_valid(S_done),.I_done_ready(S_result_ready),
        .O_error(S_code),.O_tag(S_out_tag),.O_generation(S_generation)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL BMP scaler case=%0d output=%0d: %0s",S_case,S_count,message); $stop; end
    endtask
    function [7:0] component;
        input integer x,y,c;
        begin component=(x*53+y*97+c*31+S_case*13)&255; end
    endfunction
    function [31:0] golden;
        input integer dx,dy;
        reg signed [63:0] px,py,sx,sy;
        reg [63:0] fx,fy,sum;
        integer x0,x1,y0,y1,c;
        begin
            sx=(S_w*64'd65536)/S_target_w; sy=(S_h*64'd65536)/S_target_h;
            px=(sx/2)-32768+dx*sx; py=(sy/2)-32768+dy*sy;
            if (!S_mode) begin px=px+32768; py=py+32768; end
            if (px<0) px=0; if (py<0) py=0;
            if (px>(S_w-1)*64'sd65536) px=(S_w-1)*64'sd65536;
            if (py>(S_h-1)*64'sd65536) py=(S_h-1)*64'sd65536;
            x0=px/65536; y0=py/65536;
            x1=x0+1<S_w ? x0+1 : x0; y1=y0+1<S_h ? y0+1 : y0;
            fx=S_mode ? px%65536 : 0; fy=S_mode ? py%65536 : 0;
            for (c=0;c<3;c=c+1) begin
                sum=component(x0,y0,c)*(64'd65536-fx)*(64'd65536-fy)+
                    component(x1,y0,c)*fx*(64'd65536-fy)+
                    component(x0,y1,c)*(64'd65536-fx)*fy+component(x1,y1,c)*fx*fy+64'd2147483648;
                golden[31-c*8 -: 8]=sum>>32;
            end
            golden[7:0]=255;
        end
    endfunction
    task put32;
        input integer at;
        input [31:0] value;
        begin
            S_file[at]=value[7:0]; S_file[at+1]=value[15:8];
            S_file[at+2]=value[23:16]; S_file[at+3]=value[31:24];
        end
    endtask
    task build;
        input integer w,h,bits,bottom,dw,dh,mode;
        begin
            S_w=w; S_h=h; S_bits=bits; S_bottom=bottom;
            S_target_w=dw; S_target_h=dh; S_mode=mode;
            S_rowbytes=((w*(bits/8)+3)/4)*4;
            // Offset 61 tests a gap; padding and 97 trailing bytes are nonzero.
            S_total=61+S_rowbytes*h+97;
            if (S_total>16384) fail("fixture capacity");
            for (S_i=0;S_i<S_total;S_i=S_i+1) S_file[S_i]=8'ha5;
            for (S_i=0;S_i<54;S_i=S_i+1) S_file[S_i]=0;
            S_file[0]=8'h42; S_file[1]=8'h4d;
            put32(2,S_total); put32(10,61); put32(14,40); put32(18,w);
            put32(22,bottom ? h : -h); S_file[26]=1; S_file[28]=bits;
            put32(34,S_rowbytes*h);
            for (S_r=0;S_r<h;S_r=S_r+1)
                for (S_c=0;S_c<w;S_c=S_c+1) begin
                    S_at=61+S_r*S_rowbytes+S_c*(bits/8);
                    S_file[S_at]=component(S_c,bottom ? h-1-S_r : S_r,2);
                    S_file[S_at+1]=component(S_c,bottom ? h-1-S_r : S_r,1);
                    S_file[S_at+2]=component(S_c,bottom ? h-1-S_r : S_r,0);
                    if (bits==32) S_file[S_at+3]=0; // Parser must force opaque alpha.
                end
        end
    endtask
    always @(negedge S_clk) begin
        S_cycles=S_cycles+1;
        S_ready=S_cycles%23>6;
        S_meta_allow=S_cycles%31>11;
    end
    always @(posedge S_clk) begin
        if (S_reset || S_abort || S_stream_error) S_waiting=0;
        else begin
            if (S_waiting && (!S_valid || {S_rgba,S_x,S_y,S_last}!==S_saved)) fail("unstable candidate");
            S_waiting=S_valid && !S_ready; S_saved={S_rgba,S_x,S_y,S_last};
            if (S_header && S_meta_allow && S_scaler_ready) begin
                S_headers=S_headers+1;
                if (S_sw!=S_w || S_sh!=S_h || S_bottom_up!==S_bottom[0] || S_bpp!=S_bits ||
                    S_offset!=61 || S_stride!=S_rowbytes) fail("header bridge mismatch");
            end
            if (S_valid && S_ready) begin
                S_expected_x=S_count%S_target_w;
                S_expected_y=S_bottom ? S_target_h-1-S_count/S_target_w : S_count/S_target_w;
                if (S_count>=S_target_w*S_target_h || S_x!==S_expected_x[15:0] ||
                    S_y!==S_expected_y[15:0] || S_rgba!==golden(S_expected_x,S_expected_y) ||
                    S_last!==(S_count==S_target_w*S_target_h-1)) fail("golden pixel/coordinate/alpha/last mismatch");
                S_count=S_count+1;
            end
        end
        if (!S_reset && S_parser_done) begin
            S_terminals=S_terminals+1;
            S_file_failed=S_parser_err;
            if (S_parser_code!==S_expected_code[3:0] || S_parser_err!==(S_expected_code!=0) || S_parser_tag!==S_tag)
                fail("parser terminal");
        end
        if (S_done && S_terminals==0) S_seen_scaler_first=1;
    end
    task run_case;
        input integer w,h,bits,bottom,dw,dh,mode,late_error;
        integer at;
        begin
            @(negedge S_clk); S_case=S_case+1;
            S_count=0; S_headers=0; S_terminals=0; S_seen_scaler_first=0; S_file_failed=0;
            build(w,h,bits,bottom,dw,dh,mode);
            S_dw=dw; S_dh=dh; S_bilinear=mode; S_size=S_total; S_tag=S_case;
            S_expected_code=late_error ? 5 : 0; S_inject_late_error=late_error;
            if (!S_start_ready || !S_scaler_ready) fail("start busy");
            S_start=1;
            @(posedge S_clk); @(negedge S_clk); S_start=0;
            for (at=0;at<S_total;at=at+1) begin
                @(negedge S_clk);
                // Leave the parser waiting for tail bytes until scaler really retires.
                if (at==61+S_rowbytes*h) begin
                    wait (S_done); @(negedge S_clk);
                    if (S_code!=0 || S_terminals!=0 || S_count!=dw*dh) fail("independent scaler retirement");
                    repeat (8) @(negedge S_clk);
                    if (S_inject_late_error) begin
                        S_stream_error=1;
                        @(posedge S_clk); @(negedge S_clk); S_stream_error=0;
                        at=S_total; // File owner stops sending after the parser error.
                    end
                end
                if (at<S_total) begin
                    S_byte_valid=1; S_byte=S_file[at]; S_byte_last=at==S_total-1;
                    @(posedge S_clk); while (!S_byte_ready) @(posedge S_clk);
                    @(negedge S_clk); S_byte_valid=0;
                end
            end
            wait (S_terminals==1 && S_done);
            repeat (6) @(negedge S_clk);
            if (S_code!=0 || S_out_tag!={8'd0,S_tag} || S_generation!=32'h87654321 ||
                S_headers!=1 || S_count!=dw*dh || !S_seen_scaler_first) fail("joined result totals");
            // Even with scaler success, late_error makes the overall candidate invalid.
            if (late_error && (!S_file_failed || S_parser_code!=5)) fail("late file failure lost");
            S_result_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_result_ready=0;
        end
    endtask
    initial begin
        S_reset=1; repeat (4) @(negedge S_clk); S_reset=0;
        for (S_k=0;S_k<8;S_k=S_k+1)
            run_case(7,5,(S_k%2) ? 32 : 24,(S_k/2)%2,13,9,S_k/4,0);
        run_case(31,11,24,1,3,1,1,0);
        run_case(1,1,32,0,17,13,1,0);
        run_case(9,7,24,0,4,3,1,1);
        run_case(3,5,32,1,8,7,0,0);
        S_test_pass=1;
        $display("PASS: real BMP parser/scaler, both formats/directions/algorithms, padding/gap/tail, late failure isolation");
        $finish;
    end
    initial begin #20000000; fail("timeout"); end
endmodule
