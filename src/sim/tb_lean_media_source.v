`timescale 1ns/1ps
module tb_lean_media_source;
    reg S_clk=0,S_reset=1,S_card=1,S_command=0,S_audio=0,S_begin_ready=0,S_byte_ready=0;
    reg [3:0] S_image=0;
    reg [31:0] S_offset=0,S_length=32'hffffffff;
    reg [1:0] S_cancel=0;
    wire S_catalog,S_audio_found,S_overflow,S_command_ready,S_begin,S_begin_audio;
    wire [4:0] S_count;
    wire [7:0] S_catalog_error,S_begin_error,S_byte,S_done_error;
    wire [31:0] S_size,S_byte_offset,S_done_bytes;
    wire S_valid,S_last,S_done,S_eof;
    wire [1:0] S_byte_context,S_done_context;
    wire S_request,S_return_ready,S_terminal_ready,S_abort,S_ack_ready;
    wire [31:0] S_lba;
    wire [7:0] S_sd_count;
    wire [1:0] S_context,S_priority,S_abort_context;
    wire [15:0] S_tag,S_abort_tag;
    reg S_sd_ready=0,S_sd_valid=0,S_sd_done=0,S_ack=0;
    reg [7:0] S_sd_data=0;
    reg [1:0] S_return_context=0;
    reg [15:0] S_return_tag=0;
    reg [3:0] S_sd_error=0;
    reg S_sd_last=0,S_bad_marker=0,S_ack_pending=0;
    reg [1:0] S_ack_context=0;
    reg [15:0] S_ack_tag=0;
    reg [7:0] S_boot[0:511],S_root[0:1023],S_fat[0:511];
    integer S_i,S_j,S_model_state=0,S_model_index=0,S_model_delay=0;
    reg [31:0] S_model_lba;
    integer S_seen[0:1],S_terminals=0,S_cases=0;
    reg S_check=0,S_test_pass=0,S_image_pause=0;
    reg [31:0] S_expected_offset[0:1];
    reg [7:0] S_expected_mask[0:1];
    always #4 S_clk=~S_clk;
    lean_media_source u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_card_ready(S_card),.I_capacity_sectors(33'd100000),
        .O_catalog_ready(S_catalog),.O_image_count(S_count),.O_audio_found(S_audio_found),
        .O_catalog_overflow(S_overflow),.O_catalog_error(S_catalog_error),
        .I_command_valid(S_command),.O_command_ready(S_command_ready),.I_image_pause(S_image_pause),.I_command_audio(S_audio),.I_image_index(S_image),
        .I_offset(S_offset),.I_length(S_length),.O_begin_valid(S_begin),.I_begin_ready(S_begin_ready),
        .O_begin_audio(S_begin_audio),.O_file_size(S_size),.O_begin_error(S_begin_error),
        .O_byte_valid(S_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),.O_byte_context(S_byte_context),
        .O_byte_offset(S_byte_offset),.O_byte_last(S_last),.O_done_valid(S_done),.I_done_ready(1'b1),
        .O_done_context(S_done_context),.O_done_error(S_done_error),.O_done_bytes(S_done_bytes),.O_done_eof(S_eof),.I_cancel(S_cancel),
        .O_request_valid(S_request),.I_request_ready(S_sd_ready),.O_lba(S_lba),.O_count(S_sd_count),.O_context(S_context),
        .O_priority(S_priority),.O_tag(S_tag),.I_sd_byte_valid(S_sd_valid),.O_sd_byte_ready(S_return_ready),.I_sd_byte_data(S_sd_data),
        .I_sector_last(S_sd_last),.I_request_last(S_sd_last),.I_sd_byte_context(S_return_context),.I_sd_byte_tag(S_return_tag),
        .I_sd_done_valid(S_sd_done),.O_sd_done_ready(S_terminal_ready),.I_sd_done_context(S_return_context),
        .I_sd_done_tag(S_return_tag),.I_sd_done_error(S_sd_error),.O_cancel_valid(S_abort),.I_cancel_ready(1'b1),
        .O_cancel_context(S_abort_context),.O_cancel_tag(S_abort_tag),.I_cancel_done_valid(S_ack),
        .O_cancel_done_ready(S_ack_ready),.I_cancel_done_context(S_ack_context),.I_cancel_done_tag(S_ack_tag)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: lean storage case %0d: %0s",S_cases,message); $stop; end
    endtask
    task boot32;
        input integer address;
        input [31:0] value;
        begin for(S_j=0;S_j<4;S_j=S_j+1) S_boot[address+S_j]=value>>(8*S_j); end
    endtask
    task entry;
        input integer slot;
        input [87:0] name;
        input integer cluster,size;
        begin
            for(S_j=0;S_j<11;S_j=S_j+1) S_root[slot*32+S_j]=name>>(8*(10-S_j));
            S_root[slot*32+11]=8'h20; S_root[slot*32+26]=cluster;
            for(S_j=0;S_j<4;S_j=S_j+1) S_root[slot*32+28+S_j]=size>>(8*S_j);
        end
    endtask
    function [7:0] disk_byte;
        input [31:0] lba;
        input integer pos;
        begin
            case(lba)
                0:disk_byte=S_boot[pos];
                32:disk_byte=S_fat[pos];
                1232:disk_byte=S_root[pos];
                1238:disk_byte=S_root[pos+512];
                1233,1239:disk_byte=pos[7:0]^8'h5a;
                1234:disk_byte=pos[7:0]^8'ha5;
                1235:disk_byte=pos[7:0]^8'h3c;
                1236:disk_byte=pos[7:0]^8'hc3;
                1237:disk_byte=pos[7:0]^8'h77;
                default:disk_byte=0;
            endcase
        end
    endfunction
    // Peer supports backpressure, terminal delay and delayed physical cancel ack.
    always @(negedge S_clk) begin
        S_sd_ready=0; S_sd_valid=0; S_sd_done=0; S_ack=0;
        if(S_reset) begin S_model_state=0; S_ack_pending=0; end
        else begin
            if(S_abort && !S_ack_pending) begin
                S_ack_pending=1; S_ack_context=S_abort_context; S_ack_tag=S_abort_tag;
            end
            case(S_model_state)
                0:begin S_sd_ready=1; if(S_request) begin
                    if(S_sd_count!=1) fail("non-single sector request");
                    S_model_lba=S_lba; S_return_context=S_context; S_return_tag=S_tag;
                    S_model_index=0; S_model_state=1;
                end end
                1:begin
                    S_sd_valid=1; S_sd_data=disk_byte(S_model_lba,S_model_index);
                    S_sd_last=(S_model_index==511) ^ (S_bad_marker && S_model_lba==1233);
                    if(S_return_ready) begin
                        if(S_model_index==511) begin S_model_state=2; S_model_delay=3; end
                        else S_model_index=S_model_index+1;
                    end
                end
                2:if(S_model_delay!=0) S_model_delay=S_model_delay-1;
                    else begin S_sd_done=1; S_model_state=3; end
                3:begin
                    if(S_ack_pending) begin S_ack=1; S_ack_pending=0; end
                    S_model_state=0;
                end
            endcase
        end
    end
    always @(posedge S_clk) if(!S_reset) begin
        if(S_check && S_valid && S_byte_ready) begin
            if(S_byte_context>1) fail("invalid byte context");
            if(S_byte_offset!==S_expected_offset[S_byte_context]) fail("byte offset discontinuity");
            if(S_byte!==(S_byte_offset[7:0]^S_expected_mask[S_byte_context])) fail("file content mismatch");
            S_expected_offset[S_byte_context]=S_expected_offset[S_byte_context]+1;
            S_seen[S_byte_context]=S_seen[S_byte_context]+1;
        end
        if(S_done) S_terminals=S_terminals+1;
    end
    task command;
        input audio;
        input [3:0] image;
        input [31:0] offset,length;
        input [7:0] expected_error;
        reg [40:0] held;
        begin
            @(negedge S_clk); S_audio=audio; S_image=image; S_offset=offset; S_length=length; S_command=1;
            @(posedge S_clk); while(!S_command_ready) @(posedge S_clk);
            @(negedge S_clk); S_command=0;
            wait(S_begin); #1;
            held={S_begin_audio,S_size,S_begin_error};
            repeat(4) begin @(posedge S_clk); #1;
                if(!S_begin || {S_begin_audio,S_size,S_begin_error}!==held) fail("unstable begin under backpressure");
            end
            if(S_begin_audio!==audio || S_begin_error!==expected_error) fail("begin result mismatch");
            @(negedge S_clk); S_begin_ready=1;
            @(negedge S_clk); S_begin_ready=0;
        end
    endtask
    integer S_before;
    initial begin
        for(S_i=0;S_i<512;S_i=S_i+1) begin S_boot[S_i]=0; S_root[S_i]=0; S_fat[S_i]=0; end
        for(S_i=512;S_i<1024;S_i=S_i+1) S_root[S_i]=0;
        S_boot[0]=8'heb; S_boot[2]=8'h90; S_boot[11]=0; S_boot[12]=2; S_boot[13]=1;
        S_boot[14]=32; S_boot[16]=2; boot32(32,70000); boot32(36,600); boot32(44,2);
        S_boot[510]=8'h55; S_boot[511]=8'haa;
        S_fat[12]=9; S_fat[36]=8'hff; S_fat[37]=8'hff; S_fat[38]=8'hff; S_fat[39]=8'h0f;
        entry(0,"ONE     BMP",3,700); entry(1,"TWO     BMP",4,77);
        entry(2,"THREE   BMP",5,55); entry(3,"FOUR    BMP",6,33); entry(4,"BGM     WAV",7,64);
        entry(5,"FOLDER  BMP",11,700); S_root[5*32+11]=8'h10;
        entry(6,"LONGNAMEBMP",11,700); S_root[6*32+11]=8'h0f;
        entry(7,"DELETED BMP",11,700); S_root[7*32]=8'he5;
        entry(8,"OTHER   TXT",11,700); entry(9,"EMPTY   BMP",11,0);
        // Slot 10 remains a zero end marker; valid-looking trailing garbage is ignored.
        entry(11,"AFTER   BMP",11,700);
        S_seen[0]=0; S_seen[1]=0; S_expected_offset[0]=0; S_expected_offset[1]=0;
        S_expected_mask[0]=8'h5a; S_expected_mask[1]=8'h77;
        repeat(6) @(negedge S_clk); S_reset=0;
        wait(S_catalog); #1;
        if(S_count!=4 || !S_audio_found || S_catalog_error!=0 || S_overflow) fail("root catalog mismatch");
        S_cases=1; S_check=1; S_image_pause=1;
        command(0,0,0,32'hffffffff,0);
        command(1,0,0,64,0);
        S_byte_ready=1;
        wait(S_terminals==1); #1;
        if(S_seen[0]!=0 || S_seen[1]!=64) fail("paused image blocked audio");
        S_image_pause=0;
        wait(S_terminals==2); #1;
        if(S_seen[0]!=700 || S_seen[1]!=64) fail("concurrent fragmented reads incomplete");
        // A paused request can still be canceled without waiting for resume.
        S_check=0; S_image_pause=1; S_before=S_terminals;
        command(0,0,0,700,0);
        wait(u_dut.S_pending[0]); @(negedge S_clk); S_cancel=1;
        wait(S_done); if(S_done_error!=8) fail("paused cancel terminal mismatch");
        wait(S_terminals==S_before+1); @(negedge S_clk); S_cancel=0; S_image_pause=0; S_check=1;
        S_cases=2; command(0,15,0,20,7);
        S_cases=3; S_expected_offset[0]=3; S_expected_mask[0]=8'ha5;
        S_before=S_terminals; command(0,1,3,70,0);
        wait(S_terminals==S_before+1); #1;
        if(S_seen[0]!=770) fail("synchronous descriptor selected wrong file");
        S_cases=4; S_check=0; S_bad_marker=1; S_before=S_terminals;
        command(0,0,0,700,0);
        wait(S_done); if(S_done_error==0) fail("bad sector marker accepted");
        wait(S_terminals==S_before+1); S_bad_marker=0;
        S_cases=5; S_before=S_terminals; command(0,0,0,700,0);
        wait(S_valid); @(negedge S_clk); S_cancel=1;
        wait(S_done); if(S_done_error!=8) fail("cancel terminal mismatch");
        wait(S_terminals==S_before+1); @(negedge S_clk); S_cancel=0;
        S_cases=6; S_before=S_terminals; command(0,0,0,700,0);
        wait(S_request); @(negedge S_clk); S_card=0;
        wait(S_done); if(S_done_error!=1) fail("card loss not reported");
        wait(S_terminals==S_before+1); repeat(8) @(negedge S_clk);
        if(S_catalog) fail("catalog survived card loss");
        S_card=1; wait(S_catalog); #1;
        if(S_count!=4 || !S_audio_found) fail("remount failed");
        // A directory chain extends into a second checked sector. Keep the first
        // 16 images, report truncation, and still discover the background WAV.
        S_cases=7; @(negedge S_clk); S_card=0;
        repeat(10) @(negedge S_clk);
        for(S_i=5;S_i<18;S_i=S_i+1) entry(S_i,"EXTRA   BMP",11,10);
        S_fat[8]=8; S_fat[32]=8'hff; S_fat[33]=8'hff; S_fat[34]=8'hff; S_fat[35]=8'h0f;
        S_card=1; wait(S_catalog); #1;
        if(S_count!=16 || !S_overflow || !S_audio_found) fail("catalog limit or chained root mismatch");
        // Exhaust both root clusters without a 00 marker, then point cluster
        // 8 back to the first cluster. The directory stream must reject the
        // loop even though each individual one-hop walker request succeeds.
        S_cases=8; @(negedge S_clk); S_card=0;
        repeat(10) @(negedge S_clk);
        for(S_i=18;S_i<32;S_i=S_i+1) S_root[S_i*32]=8'he5;
        S_fat[32]=2; S_fat[33]=0; S_fat[34]=0; S_fat[35]=0;
        S_card=1; wait(S_catalog_error!=0); #1;
        if(S_catalog || S_catalog_error!=9) fail("looping root directory accepted");
        S_cases=9; @(negedge S_clk); S_card=0;
        repeat(10) @(negedge S_clk);
        S_fat[32]=8'hff; S_fat[33]=8'hff; S_fat[34]=8'hff; S_fat[35]=8'h0f;
        S_card=1; wait(S_catalog); #1;
        if(S_count!=16 || !S_overflow || S_catalog_error!=0) fail("directory EOC recovery failed");
        S_test_pass=1; $display("PASS: lean FAT32 catalog, fragmented/looping root, descriptors, streams, cancel and remount"); $finish;
    end
    initial begin #20000000; fail("watchdog"); end
endmodule
