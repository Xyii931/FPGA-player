`timescale 1ns/1ps
// Real WAV parser and dual-clock audio FIFO, with a separate bounded file peer.
module tb_lean_audio;
    reg S_host=0,S_video=0,S_reset=1,S_catalog=1,S_found=1,S_mute=0;
    reg [2:0] S_volume=4;
    always #4 S_host=~S_host;
    always #20 S_video=~S_video;
    wire S_command,S_begin_ready,S_byte_ready,S_cancel,S_sample,S_acr;
    wire [31:0] S_offset,S_length,S_underflows;
    wire [23:0] S_left,S_right;
    wire [19:0] S_n,S_cts;
    wire [3:0] S_error;
    reg [2:0] S_peer=0;
    reg [31:0] S_cursor=0,S_end=0,S_done_bytes=0;
    integer S_cycle=0,S_requests=0,S_samples=0,S_acrs=0,S_loops=0;
    reg S_started=0,S_test_pass=0,S_hold=0,S_hold_done=0;
    wire S_ready=S_peer==0 && !S_hold;
    wire S_begin=S_peer==1;
    wire S_bytes=S_peer==2 && S_cycle%5!=0;
    wire S_done=S_peer==3;
    function [7:0] file_byte;
        input integer pos;
        integer component,index;
        reg [31:0] value;
        reg [15:0] left,right;
        begin
            file_byte=0;
            if(pos<44) begin
                case(pos)
                    0:file_byte="R"; 1:file_byte="I"; 2,3:file_byte="F";
                    8:file_byte="W"; 9:file_byte="A"; 10:file_byte="V"; 11:file_byte="E";
                    12:file_byte="f"; 13:file_byte="m"; 14:file_byte="t"; 15:file_byte=" ";
                    16:file_byte=16; 20:file_byte=1; 22:file_byte=2;
                    24:file_byte=8'h80; 25:file_byte=8'hbb;
                    28:file_byte=0; 29:file_byte=8'hee; 30:file_byte=2;
                    32:file_byte=4; 34:file_byte=16;
                    36:file_byte="d"; 37:file_byte="a"; 38:file_byte="t"; 39:file_byte="a";
                    default:begin end
                endcase
                if(pos>=4 && pos<8) begin value=2836; file_byte=value>>((pos-4)*8); end
                if(pos>=40 && pos<44) begin value=2800; file_byte=value>>((pos-40)*8); end
            end else begin
                index=(pos-44)/4; component=(pos-44)%4;
                left=1000+index; right=-1000-index;
                case(component)
                    0:file_byte=left[7:0]; 1:file_byte=left[15:8];
                    2:file_byte=right[7:0]; 3:file_byte=right[15:8];
                endcase
            end
        end
    endfunction
    lean_audio u_dut (
        .I_host_clk(S_host),.I_video_clk(S_video),.I_async_reset(S_reset),.I_catalog_ready(S_catalog),.I_audio_found(S_found),
        .O_command_valid(S_command),.I_command_ready(S_ready),.O_offset(S_offset),.O_length(S_length),
        .I_begin_valid(S_begin),.O_begin_ready(S_begin_ready),.I_file_size(32'd2844),.I_begin_error(8'd0),
        .I_byte_valid(S_bytes),.O_byte_ready(S_byte_ready),.I_byte_data(file_byte(S_cursor)),.I_byte_offset(S_cursor),
        .I_file_done(S_done),.I_file_error(8'd0),.I_file_bytes(S_done_bytes),.I_file_eof(S_end==2844),
        .O_cancel(S_cancel),.O_reserve_storage(),.O_error(S_error),.I_mute(S_mute),.I_volume(S_volume),
        .O_sample_valid(S_sample),.O_left(S_left),.O_right(S_right),.O_acr_valid(S_acr),.O_acr_n(S_n),.O_acr_cts(S_cts),.O_underflows(S_underflows)
    );
    task fail;
        input [511:0] text;
        begin $display("FAIL: lean audio sample %0d: %0s L=%h R=%h",S_samples,text,S_left,S_right); $stop; end
    endtask
    always @(posedge S_host) begin
        if(S_reset) begin S_peer<=0; S_cursor<=0; S_cycle<=0; end
        else begin
            S_cycle<=S_cycle+1;
            if(S_error!=0 || S_cancel) fail("unexpected parser/cancel error");
            case(S_peer)
                0:if(S_command && S_ready) begin
                    if(S_length!=2048 || (S_offset!=0 && S_offset!=2048)) fail("unbounded or incorrect refill");
                    S_requests=S_requests+1;
                    if(S_offset==0) S_loops=S_loops+1;
                    S_cursor<=S_offset; S_end<=S_offset+S_length>2844 ? 2844 : S_offset+S_length;
                    S_done_bytes<=S_offset==0 ? 2048 : 796; S_peer<=1;
                end
                1:if(S_begin_ready) S_peer<=2;
                2:if(S_bytes && S_byte_ready) begin
                    S_cursor<=S_cursor+1;
                    if(S_cursor+1==S_end) S_peer<=3;
                end
                3:S_peer<=0;
            endcase
        end
    end
    reg signed [23:0] S_expected_left,S_expected_right;
    integer S_shift;
    always @(posedge S_video) begin
        #1;
        if(!S_reset) begin
            if(S_acr) begin
                if(S_n!=6144 || S_cts!=25000) fail("ACR mismatch");
                S_acrs=S_acrs+1;
            end
            if(S_sample) begin
                if(!S_started && S_left!=0) S_started=1;
                if(S_started) begin
                    S_expected_left=(1000+(S_samples%700))*256;
                    S_expected_right=(-1000-(S_samples%700))*256;
                    S_shift=4-S_volume;
                    if(S_mute || S_volume==0) begin S_expected_left=0; S_expected_right=0; end
                    else begin S_expected_left=S_expected_left>>>S_shift; S_expected_right=S_expected_right>>>S_shift; end
                    if(S_left!==S_expected_left || S_right!==S_expected_right) fail("PCM/channel/volume/loop mismatch");
                    S_samples=S_samples+1;
                end
            end
        end
    end
    initial begin
        repeat(8) @(negedge S_host); S_reset=0;
        wait(S_samples>=800); @(negedge S_video); S_volume=2;
        wait(S_samples>=1000); @(negedge S_video); S_mute=1;
        wait(S_samples>=1032); @(negedge S_video); S_mute=0; S_volume=4;
        wait(S_hold_done);
        // More than two complete 8192-frame address wraps exercise banking
        // and pointer reuse when the installed TD RAM model is selected.
        wait(S_samples>=($test$plusargs("FIFO_WRAP") ? 18000 : 3000)); @(negedge S_video);
        if(S_underflows!=0 || S_loops<3 || S_acrs<2 || !S_hold_done) fail("refill continuity or ACR coverage missing");
        S_test_pass=1; $display("PASS: lean WAV bounded refills, signed PCM, loop, mute, volume and ACR"); $finish;
    end
    // Emulate a temporary shared-storage delay while preserving the real
    // playback clock. PCM comparisons above catch skipped/zero samples.
    initial begin
        wait(S_samples>=100);
        @(negedge S_host); S_hold=1;
        #100000000;
        @(negedge S_host); S_hold=0; S_hold_done=1;
    end
    initial begin
        if($test$plusargs("FIFO_WRAP")) #500000000;
        else #300000000;
        fail("watchdog");
    end
endmodule
