`timescale 1ns/1ps
// Real BMP parser, lean loader/scanout/native SDRAM; independent command fixture.
// Pixel reference inverts each destination transform, not the DUT's forward map.
module tb_lean_video;
    reg S_host=0,S_video=0,S_reset=1,S_start=0,S_slot=0,S_byte_valid=0,S_last=0,S_file_done=0;
    reg [1:0] S_rotation=0;
    reg [7:0] S_byte=0,S_file_error=0;
    wire S_start_ready,S_byte_ready,S_cancel,S_done;
    wire [3:0] S_error;
    wire [18:0] S_pixels;
    wire S_write,S_write_ready,S_idle,S_read,S_read_ready,S_result,S_result_ready,S_initialized,S_clock_fault,S_mem_error;
    wire [20:0] S_write_address,S_read_address;
    wire [31:0] S_write_data,S_read_tag,S_result_tag,S_result_data;
    wire [3:0] S_result_error;
    reg S_commit=0,S_done_ready=0;
    wire S_commit_ready,S_commit_done,S_de,S_valid,S_frame,S_scan_fault;
    wire [15:0] S_x,S_y;
    wire [23:0] S_rgb;
    wire [31:0] S_underflows;
    wire S_sclk,S_cke,S_ras,S_cas,S_we;
    wire [10:0] S_addr;
    wire [1:0] S_ba;
    wire [3:0] S_dm;
    wire [31:0] S_dq;
    wire S_device_fault;
    reg S_test_pass=0,S_active=0,S_active_slot=0;
    integer S_i,S_rot,S_count,S_byte_index,S_wait,S_cases=0;
    reg S_bottom=1;
    always #4 S_host=~S_host;
    always #20 S_video=~S_video;
    lean_image_loader u_loader (
        .I_clk(S_host),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(32'd921654),.I_rotation(S_rotation),.I_slot(S_slot),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),.I_byte_last(S_last),
        .I_file_done(S_file_done),.I_file_error(S_file_error),.I_memory_error(S_clock_fault || S_mem_error),.I_writes_idle(S_idle),
        .O_cancel(S_cancel),.O_write_valid(S_write),.I_write_ready(S_write_ready),.O_write_address(S_write_address),
        .O_write_data(S_write_data),.O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),.O_pixels(S_pixels)
    );
    lean_scanout u_scan (
        .I_host_clk(S_host),.I_video_clk(S_video),.I_async_reset(S_reset),
        .I_commit_valid(S_commit),.O_commit_ready(S_commit_ready),.I_commit_slot(S_slot),.O_commit_done(S_commit_done),
        .O_read_valid(S_read),.I_read_ready(S_read_ready),.O_read_address(S_read_address),.O_read_tag(S_read_tag),
        .I_result_valid(S_result),.O_result_ready(S_result_ready),.I_result_data(S_result_data),.I_result_tag(S_result_tag),
        .I_result_error(S_result_error),.O_de(S_de),.O_valid(S_valid),.O_x(S_x),.O_y(S_y),.O_rgb(S_rgb),
        .O_frame_start(S_frame),.O_fault(S_scan_fault),.O_underflow_lines(S_underflows)
    );
    lean_frame_memory #(.INIT_CYCLES(32)) u_memory (
        .I_clk(S_host),.I_clk_sft(~S_host),.I_reset(S_reset),
        .I_read_valid(S_read),.O_read_ready(S_read_ready),.I_read_address(S_read_address),.I_read_tag(S_read_tag),
        .O_read_result_valid(S_result),.I_read_result_ready(S_result_ready),.O_read_data(S_result_data),.O_read_tag(S_result_tag),.O_read_error(S_result_error),
        .I_write_valid(S_write),.O_write_ready(S_write_ready),.I_write_address(S_write_address),.I_write_data(S_write_data),
        .O_writes_idle(S_idle),.O_initialized(S_initialized),.O_clock_fault(S_clock_fault),.O_memory_error(S_mem_error),
        .O_sdram_clk(S_sclk),.O_sdram_cke(S_cke),.O_sdram_ras_n(S_ras),.O_sdram_cas_n(S_cas),.O_sdram_we_n(S_we),
        .O_sdram_addr(S_addr),.O_sdram_ba(S_ba),.O_sdram_dm(S_dm),.IO_sdram_dq(S_dq)
    );
    sim_sdr_device u_device (
        .I_clk(S_sclk),.I_reset(S_reset),.I_cke(S_cke),.I_ras_n(S_ras),.I_cas_n(S_cas),.I_we_n(S_we),
        .I_addr(S_addr),.I_ba(S_ba),.I_dm(S_dm),.IO_dq(S_dq),.O_fault(S_device_fault),
        .O_reads(), .O_writes(), .O_refreshes()
    );
    task fail;
        input [511:0] text;
        begin $display("FAIL: lean video case %0d: %0s x=%0d y=%0d rgb=%h",S_cases,text,S_x,S_y,S_rgb); $stop; end
    endtask
    function [7:0] file_byte;
        input integer pos;
        integer x,y,component,offset;
        reg [31:0] value;
        begin
            file_byte=0;
            if(pos<54) begin
                case(pos)
                    0:file_byte="B"; 1:file_byte="M"; 10:file_byte=54; 14:file_byte=40;
                    18:file_byte=8'h80; 19:file_byte=2; 26:file_byte=1; 28:file_byte=24;
                    default:begin end
                endcase
                if(pos>=2 && pos<6) begin value=921654; file_byte=value>>((pos-2)*8); end
                if(pos>=22 && pos<26) begin value=S_bottom ? 32'd480 : -32'd480; file_byte=value>>((pos-22)*8); end
            end else begin
                offset=pos-54; y=offset/1920; x=(offset%1920)/3; component=offset%3;
                if(S_bottom) y=479-y;
                case(component)
                    0:file_byte=x^y;
                    1:file_byte=y;
                    2:file_byte=x;
                endcase
            end
        end
    endfunction
    function [23:0] reference;
        input integer x,y,rotation;
        integer sx,sy;
        begin
            sx=0; sy=0;
            case(rotation)
                0:begin sx=x; sy=y; end
                1:begin sx=y*4/3; sy=(499-x)*4/3; end
                2:begin sx=639-x; sy=479-y; end
                3:begin sx=(479-y)*4/3; sy=(x-140)*4/3; end
            endcase
            if((rotation==1 || rotation==3) && (x<140 || x>=500)) reference=0;
            else reference={sx[7:0],sy[7:0],(sx[7:0]^sy[7:0])};
        end
    endfunction
    always @(posedge S_host) if(!S_reset) begin
        if(S_device_fault || S_clock_fault || S_mem_error || S_scan_fault) fail("memory/scan fault");
        if(S_write && S_write_ready && S_active && (S_write_address<307200)==!S_active_slot)
            fail("writer touched active frame before swap retirement");
    end
    initial begin
        repeat(10) @(negedge S_host); S_reset=0; wait(S_initialized);
        // Each direction is a complete image, not a reduced-size smoke case.
        for(S_rot=0;S_rot<4;S_rot=S_rot+1) begin
            S_cases=S_rot+1; S_rotation=S_rot; S_slot=S_rot[0]; S_bottom=!S_rot[0];
            @(negedge S_host); S_start=1;
            @(posedge S_host); while(!S_start_ready) @(posedge S_host);
            @(negedge S_host); S_start=0;
            for(S_byte_index=0;S_byte_index<921654;S_byte_index=S_byte_index+1) begin
                @(negedge S_host); S_byte_valid=1; S_byte=file_byte(S_byte_index); S_last=S_byte_index==921653;
                @(posedge S_host); while(!S_byte_ready) @(posedge S_host);
            end
            @(negedge S_host); S_byte_valid=0; S_last=0;
            repeat(12) @(negedge S_host);
            if(S_done) fail("published before file terminal");
            S_file_done=1; @(negedge S_host); S_file_done=0;
            wait(S_done); #1;
            if(S_error!=0 || !S_idle || S_pixels!=(S_rot[0] ? 172800 : 307200)) fail("loader result/count mismatch");
            @(negedge S_host); S_commit=1;
            @(posedge S_host); while(!S_commit_ready) @(posedge S_host);
            @(negedge S_host); S_commit=0;
            wait(S_commit_done); @(negedge S_host); S_active=1; S_active_slot=S_slot;
            S_count=0;
            // Skip to the first complete active raster after the swap.
            @(posedge S_video); #1;
            while(!(S_de && S_x==0 && S_y==0)) begin @(posedge S_video); #1; end
            begin: frame_check
                forever begin
                    if(S_de) begin
                        if(!S_valid || S_rgb!==reference(S_x,S_y,S_rot)) fail("golden pixel mismatch");
                        S_count=S_count+1;
                        if(S_x==639 && S_y==479) disable frame_check;
                    end
                    @(posedge S_video); #1;
                end
            end
            if(S_count!=307200 || S_underflows!=0) fail("raster coverage or line underflow");
            $display("PASS: lean video full rotation %0d",S_rot);
            // Consume the held loader result without resetting the running display.
            @(negedge S_host); S_done_ready=1;
            @(negedge S_host); S_done_ready=0;
        end
        S_test_pass=1; $display("PASS: lean BMP/rotation/native SDRAM/scanout complete"); $finish;
    end
    initial begin #1000000000; fail("watchdog"); end
endmodule
