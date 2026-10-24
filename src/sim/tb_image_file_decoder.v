`timescale 1ns/1ps
// Real BMP/RLE routing and parsers. CRC/pixel fixtures are independent test input.
// This test source has been prepared, not executed.
module tb_image_file_decoder;
    reg S_clk=0,S_reset=1,S_start=0,S_valid=0,S_last=0,S_abort=0,S_stream_error=0;
    always #4 S_clk=~S_clk;
    reg [31:0] S_size=0;
    reg [7:0] S_byte=0,S_tag=0;
    wire S_start_ready,S_ready,S_busy,S_done,S_err,S_header_valid,S_pixel_valid,S_pixel_last,S_bottom;
    reg S_header_ready=0,S_pixel_ready=0,S_hold=0;
    wire [3:0] S_error;
    wire [7:0] S_result_tag;
    wire [15:0] S_width,S_height,S_x,S_y;
    wire [5:0] S_bpp;
    wire [31:0] S_offset,S_row_bytes,S_rgba;
    reg [7:0] S_file[0:127];
    integer S_headers=0,S_pixels=0,S_terminals=0,S_ticks=0,S_cases=0,S_i,S_early_last=-1;
    reg [3:0] S_expected_error=0;
    reg S_is_bmp=0,S_wait_header=0,S_wait_pixel=0,S_test_pass=0;
    reg [102:0] S_saved_header;
    reg [64:0] S_saved_pixel;
    reg [31:0] S_expected_color;
    image_file_decoder u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(S_size),.I_tag(S_tag),.I_byte_valid(S_valid),.O_byte_ready(S_ready),
        .I_byte_data(S_byte),.I_byte_last(S_last),.I_abort(S_abort),.I_stream_error(S_stream_error),
        .O_busy(S_busy),.O_done(S_done),.O_err(S_err),.O_error_code(S_error),.O_tag(S_result_tag),
        .O_header_valid(S_header_valid),.I_header_ready(S_header_ready),
        .O_width(S_width),.O_height(S_height),.O_bottom_up(S_bottom),.O_bpp(S_bpp),
        .O_pixel_offset(S_offset),.O_row_bytes(S_row_bytes),
        .O_pixel_valid(S_pixel_valid),.I_pixel_ready(S_pixel_ready),
        .O_rgba(S_rgba),.O_x(S_x),.O_y(S_y),.O_pixel_last(S_pixel_last)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL image case %0d: %0s",S_cases,message); $stop; end
    endtask
    always @(negedge S_clk) begin
        S_header_ready=!S_hold && S_ticks%11>=4;
        S_pixel_ready=!S_hold && S_ticks%7>=3;
    end
    always @(posedge S_clk) if(!S_reset) begin
        S_ticks=S_ticks+1;
        if(S_wait_header && !S_abort && !S_stream_error &&
            (!S_header_valid || {S_width,S_height,S_bottom,S_bpp,S_offset,S_row_bytes}!==S_saved_header)) fail("header stability");
        if(S_wait_pixel && !S_abort && !S_stream_error &&
            (!S_pixel_valid || {S_rgba,S_x,S_y,S_pixel_last}!==S_saved_pixel)) fail("pixel stability");
        S_wait_header=S_header_valid && !S_header_ready;
        S_wait_pixel=S_pixel_valid && !S_pixel_ready;
        S_saved_header={S_width,S_height,S_bottom,S_bpp,S_offset,S_row_bytes};
        S_saved_pixel={S_rgba,S_x,S_y,S_pixel_last};
        if(S_header_valid && S_header_ready) begin
            S_headers=S_headers+1;
            if(S_headers!=1 || S_width!=(S_is_bmp ? 1 : 3) || S_height!=(S_is_bmp ? 1 : 2) ||
                S_bottom!==S_is_bmp || S_bpp!=(S_is_bmp ? 24 : 32) || S_offset!=(S_is_bmp ? 54 : 16) ||
                S_row_bytes!=(S_is_bmp ? 4 : 12)) fail("header contents/signature routing");
        end
        if(S_pixel_valid && S_pixel_ready) begin
            S_expected_color=S_is_bmp ? 32'h332211ff : (S_pixels<2 ? 32'hff0000ff : S_pixels<5 ? 32'h00ff00ff : 32'h0000ffff);
            if(S_headers!=1 || S_rgba!==S_expected_color || S_x!==(S_is_bmp ? 0 : S_pixels%3) ||
                S_y!==(S_is_bmp ? 0 : S_pixels/3) || S_pixel_last!==(S_is_bmp || S_pixels==5)) fail("RGBA/run/row/last expansion");
            S_pixels=S_pixels+1;
        end
        if(S_done) begin
            S_terminals=S_terminals+1;
            if(S_terminals!=1 || S_error!==S_expected_error || S_err!==(S_expected_error!=0) || S_result_tag!==S_tag)
                fail("terminal status/tag/count");
        end
    end
    task put32;
        input integer at;
        input [31:0] value;
        begin
            S_file[at]=value; S_file[at+1]=value>>8; S_file[at+2]=value>>16; S_file[at+3]=value>>24;
        end
    endtask
    task checksum;
        integer k,b;
        reg [31:0] crc;
        begin
            crc=32'hffffffff;
            for(k=16;k<S_size;k=k+1) begin
                crc=crc^S_file[k];
                for(b=0;b<8;b=b+1) begin
                    if(crc[0]) crc=(crc>>1)^32'hedb88320; else crc=crc>>1;
                end
            end
            put32(12,crc^32'hffffffff);
        end
    endtask
    task build_rle;
        begin
            for(S_i=0;S_i<128;S_i=S_i+1) S_file[S_i]=0;
            S_size=34; S_is_bmp=0; S_early_last=-1;
            put32(0,32'h31454c52); S_file[4]=3; S_file[6]=2; put32(8,18);
            S_file[16]=2; put32(18,32'hff0000ff);
            S_file[22]=3; put32(24,32'h00ff00ff);
            S_file[28]=1; put32(30,32'h0000ffff); checksum;
        end
    endtask
    task start_job;
        input [3:0] error;
        begin
            wait(S_start_ready); @(negedge S_clk);
            S_headers=0; S_pixels=0; S_terminals=0; S_wait_header=0; S_wait_pixel=0;
            S_expected_error=error; S_cases=S_cases+1; S_tag=S_tag+1; S_start=1;
            @(negedge S_clk); S_start=0;
        end
    endtask
    task send_range;
        input integer first,count;
        integer k;
        begin
            for(k=first;k<first+count && S_terminals==0;k=k+1) begin
                @(negedge S_clk);
                if(S_terminals==0) begin
                    S_byte=S_file[k]; S_last=(k==S_size-1 || k==S_early_last); S_valid=1;
                    @(posedge S_clk); while(!S_ready && S_terminals==0) @(posedge S_clk);
                    @(negedge S_clk); S_valid=0;
                end
            end
        end
    endtask
    task finish_job;
        input integer pixels,headers;
        begin
            wait(S_terminals==1); repeat(4) @(negedge S_clk);
            if(S_busy || !S_start_ready || S_pixels!=pixels || S_headers!=headers || S_done) fail("pixel/retirement counts");
        end
    endtask
    initial begin
        repeat(5) @(negedge S_clk); S_reset=0;
        build_rle; start_job(0); send_range(0,S_size); finish_job(6,1);
        build_rle; S_file[0]="X"; start_job(1); send_range(0,S_size); finish_job(0,0);
        build_rle; S_file[4]=0; start_job(3); send_range(0,S_size); finish_job(0,0);
        build_rle; S_file[8]=17; start_job(4); send_range(0,S_size); finish_job(0,0);
        build_rle; S_file[16]=0; checksum; start_job(4); send_range(0,S_size); finish_job(0,1);
        build_rle; S_file[28]=2; checksum; start_job(4); send_range(0,S_size); finish_job(5,1);
        build_rle; S_file[28]=0; checksum; start_job(4); send_range(0,S_size); finish_job(5,1);
        build_rle; S_file[12]=S_file[12]^1; start_job(4); send_range(0,S_size); finish_job(5,1);
        build_rle; S_early_last=18; start_job(5); send_range(0,19); finish_job(0,1);
        build_rle; start_job(6); send_range(0,2);
        @(negedge S_clk); S_abort=1; repeat(5) @(negedge S_clk); S_abort=0; finish_job(0,0);
        build_rle; start_job(5); send_range(0,16); S_hold=1;
        wait(S_header_valid); repeat(5) @(negedge S_clk);
        S_stream_error=1; repeat(5) @(negedge S_clk); S_stream_error=0; S_hold=0; finish_job(0,0);
        // A BMP after RLE uses the original parser and preserves BMP alpha policy.
        for(S_i=0;S_i<128;S_i=S_i+1) S_file[S_i]=0;
        S_is_bmp=1; S_size=58; S_early_last=-1;
        S_file[0]="B"; S_file[1]="M"; put32(2,58); put32(10,54); put32(14,40);
        put32(18,1); put32(22,1); S_file[26]=1; S_file[28]=24; put32(34,4);
        S_file[54]=8'h11; S_file[55]=8'h22; S_file[56]=8'h33;
        start_job(0); send_range(0,S_size); finish_job(1,1);
        S_test_pass=1; $display("PASS: real BMP/RLE selection, runs, CRC, stalls, shape and cancellation"); $finish;
    end
    initial begin #2000000; fail("watchdog"); end
endmodule
