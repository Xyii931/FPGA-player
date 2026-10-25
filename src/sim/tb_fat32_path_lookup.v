`timescale 1ns/1ps
// Real lookup/directory/parser/walker; checked-sector endpoint only, not SPI.
module tb_fat32_path_lookup;
    reg S_clk=0,S_reset=1,S_mounted=1,S_start=0,S_cancel=0,S_result_ready=0;
    always #4 S_clk=~S_clk;
    reg [6:0] S_path_length=0;
    reg [31:0] S_budget=16;
    reg S_path_valid=0,S_path_last=0;
    reg [7:0] S_path_data=0;
    wire S_start_ready,S_path_ready,S_result;
    wire [7:0] S_attr,S_error;
    wire [31:0] S_size,S_cluster,S_sectors;
    wire [2:0] S_warning;
    wire [3:0] S_storage_error;
    wire S_read_valid,S_read_abort,S_read_result_ready;
    wire [31:0] S_lba;
    wire [8:0] S_address;
    reg [7:0] S_data=0;
    reg [7:0] S_disk[0:1535],S_ram[0:511];
    reg [1:0] S_model_state=0;
    reg S_model_abort=0,S_model_lost=0,S_force_error=0;
    reg [7:0] S_model_error=0;
    reg [3:0] S_model_storage_error=0;
    integer S_delay=0,S_requests=0,S_before=0,S_cases=0;
    integer S_i,S_j,S_k,S_index,S_base,S_offset,S_units,S_part,S_ordinal,S_at;
    reg [7:0] S_sum,S_char;
    reg [511:0] S_long_name;
    reg [118:0] S_held;
    reg S_test_pass=0;
    fat32_path_lookup u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_mounted(S_mounted),.I_fat_lba(32'd32),.I_data_lba(32'd1232),
        .I_cluster_count(32'd68768),.I_root_cluster(32'd2),.I_cluster_shift(3'd0),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.I_path_length(S_path_length),.I_sector_budget(S_budget),
        .I_path_valid(S_path_valid),.O_path_ready(S_path_ready),.I_path_data(S_path_data),.I_path_last(S_path_last),
        .I_cancel(S_cancel),.O_result_valid(S_result),.I_result_ready(S_result_ready),
        .O_attr(S_attr),.O_size(S_size),.O_first_cluster(S_cluster),.O_sectors(S_sectors),
        .O_warning(S_warning),.O_error(S_error),.O_storage_error(S_storage_error),
        .O_read_valid(S_read_valid),.I_read_ready(S_model_state==0),.O_read_lba(S_lba),.O_read_abort(S_read_abort),
        .I_read_result_valid(S_model_state==2),.O_read_result_ready(S_read_result_ready),
        .I_read_error(S_model_error),.I_storage_error(S_model_storage_error),
        .O_buffer_address(S_address),.I_buffer_data(S_data));
    task fail;
        input [511:0] message;
        begin $display("FAIL: path case %0d: %0s",S_cases,message); $stop; end
    endtask
    task short_entry;
        input integer address;
        input [87:0] alias;
        input [7:0] attr;
        input [31:0] cluster,size;
        begin
            for(S_j=0;S_j<32;S_j=S_j+1) S_disk[address+S_j]=0;
            for(S_j=0;S_j<11;S_j=S_j+1) S_disk[address+S_j]=alias[(10-S_j)*8+:8];
            S_disk[address+11]=attr;
            S_disk[address+20]=cluster[23:16]; S_disk[address+21]=cluster[31:24];
            S_disk[address+26]=cluster[7:0]; S_disk[address+27]=cluster[15:8];
            for(S_j=0;S_j<4;S_j=S_j+1) S_disk[address+28+S_j]=size[S_j*8+:8];
        end
    endtask
    task long_entry;
        input integer address,length;
        input [511:0] name;
        input [87:0] alias;
        input [31:0] cluster,size;
        begin
            S_sum=0;
            for(S_j=0;S_j<11;S_j=S_j+1) S_sum={S_sum[0],S_sum[7:1]}+alias[(10-S_j)*8+:8];
            S_units=(length+12)/13;
            for(S_part=0;S_part<S_units;S_part=S_part+1) begin
                S_ordinal=S_units-S_part; S_at=address+S_part*32;
                for(S_j=0;S_j<32;S_j=S_j+1) S_disk[S_at+S_j]=0;
                S_disk[S_at]=S_ordinal+(S_part==0 ? 64 : 0); S_disk[S_at+11]=15; S_disk[S_at+13]=S_sum;
                for(S_j=0;S_j<13;S_j=S_j+1) begin
                    case(S_j)
                        0:S_offset=1; 1:S_offset=3; 2:S_offset=5; 3:S_offset=7; 4:S_offset=9;
                        5:S_offset=14; 6:S_offset=16; 7:S_offset=18; 8:S_offset=20; 9:S_offset=22;
                        10:S_offset=24; 11:S_offset=28; default:S_offset=30;
                    endcase
                    S_index=(S_ordinal-1)*13+S_j;
                    if(S_index<length) begin
                        S_disk[S_at+S_offset]=name[(length-1-S_index)*8+:8]; S_disk[S_at+S_offset+1]=0;
                    end else if(S_index==length) begin S_disk[S_at+S_offset]=0; S_disk[S_at+S_offset+1]=0; end
                    else begin S_disk[S_at+S_offset]=255; S_disk[S_at+S_offset+1]=255; end
                end
            end
            short_entry(address+S_units*32,alias,8'h20,cluster,size);
        end
    endtask
    task header;
        input integer length,budget;
        begin
            S_cases=S_cases+1; S_before=S_requests;
            @(negedge S_clk); S_path_length=length; S_budget=budget; S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
        end
    endtask
    task send_path;
        input [511:0] path;
        input integer length,budget;
        begin
            header(length,budget);
            if(length>0 && length<=64) begin
                for(S_k=0;S_k<length;S_k=S_k+1) begin
                    @(negedge S_clk); S_path_valid=1; S_path_data=path[(length-1-S_k)*8+:8]; S_path_last=S_k==length-1;
                    @(posedge S_clk); while(!S_path_ready && !S_result) @(posedge S_clk);
                    if(S_result) fail("path ended before advertised frame length");
                    @(negedge S_clk); S_path_valid=0;
                end
                S_path_last=0;
            end
        end
    endtask
    task finish;
        input [7:0] error,attr;
        input [31:0] cluster,size;
        input integer sectors;
        begin
            wait(S_result); #1;
            if(S_error!==error || S_sectors!==sectors || S_model_state!=0) begin
                $display("Expected error=%0d sectors=%0d idle=0; got error=%0d sectors=%0d model=%0d",
                    error,sectors,S_error,S_sectors,S_model_state);
                fail("error, budget or premature result");
            end
            if(error==0 && {S_attr,S_cluster,S_size}!=={attr,cluster,size}) fail("entry identity");
            S_held={S_attr,S_size,S_cluster,S_sectors,S_warning,S_error,S_storage_error};
            repeat(9) begin
                @(negedge S_clk);
                if(!S_result || {S_attr,S_size,S_cluster,S_sectors,S_warning,S_error,S_storage_error}!==S_held)
                    fail("result changed under backpressure");
            end
            S_result_ready=1; @(negedge S_clk); S_result_ready=0;
        end
    endtask
    always @(posedge S_clk) begin
        S_data<=S_ram[S_address];
        if(!S_reset) begin
            if(S_model_state==0 && S_read_valid) begin
                S_requests=S_requests+1; S_model_abort=0; S_model_lost=0; S_delay=40;
                S_model_error=0; S_model_storage_error=0; S_model_state<=1;
                case(S_lba)
                    1232:S_base=0; 1235:S_base=512; 1237:S_base=1024;
                    default:begin S_base=0; fail("unexpected directory or FAT request"); end
                endcase
                for(S_index=0;S_index<512;S_index=S_index+1) S_ram[S_index]=S_disk[S_base+S_index];
            end else if(S_model_state==1) begin
                if(S_read_abort) S_model_abort=1;
                if(!S_mounted) S_model_lost=1;
                if(S_delay==0) begin
                    S_model_error=S_model_lost ? 8'd1 : (S_model_abort ? 8'd8 : (S_force_error ? 8'd2 : 8'd0));
                    S_model_storage_error=S_force_error ? 4'd4 : 4'd0; S_model_state<=2;
                end else S_delay=S_delay-1;
            end else if(S_model_state==2 && S_read_result_ready) S_model_state<=0;
        end
    end
    initial begin
        for(S_i=0;S_i<1536;S_i=S_i+1) S_disk[S_i]=0;
        short_entry(0,"MUSIC      ",16,5,0);
        long_entry(32,15,"Cover Image.bmp","COVER~1 BMP",10,54);
        short_entry(128,"EMPTY   WAV",32,0,0);
        S_long_name=0;
        for(S_i=0;S_i<60;S_i=S_i+1) S_long_name[(63-S_i)*8+:8]=8'h61;
        S_long_name[31:0]=".wav";
        long_entry(160,64,S_long_name,"LONG~1  WAV",12,2048);
        short_entry(352,"ABCDEFGHTXT",32,13,100);
        short_entry(384,"EIGHTCHR   ",32,14,200);
        short_entry(512,"SUB        ",16,7,0);
        long_entry(544,13,"Theme One.wav","THEME~1 WAV",8,1024);
        short_entry(1024,"TRACK   WAV",32,11,100);
        #39; S_reset=0;
        send_path("/",1,0); finish(0,16,2,0,0);
        send_path("///",3,0); finish(0,16,2,0,0);
        send_path("MUSIC/theme one.WAV",19,16); finish(0,32,8,1024,2);
        send_path("/music/THEME~1.WAV",18,16); finish(0,32,8,1024,2);
        send_path("cover IMAGE.BMP",15,16); finish(0,32,10,54,1);
        send_path("cover~1.bmp",11,16); finish(0,32,10,54,1);
        // Non-ASCII LFN falls back to the alias, and warning survives the scan.
        S_disk[34]=1;
        send_path("cover~1.bmp",11,16); finish(0,32,10,54,1);
        if(!S_warning[0]) fail("LFN fallback warning was not accumulated");
        send_path("Cover Image.bmp",15,16); finish(14,0,0,0,1);
        if(!S_warning[0]) fail("warning disappeared before missing-path result");
        S_disk[34]=0;
        send_path("//MuSiC//sUb//track.wav",23,16); finish(0,32,11,100,3);
        send_path("music/",6,16); finish(0,16,5,0,1);
        send_path("empty.wav",9,16); finish(0,32,0,0,1);
        send_path("abcdefgh.txt",12,16); finish(0,32,13,100,1);
        send_path("eightchr",8,16); finish(0,32,14,200,1);
        send_path(S_long_name,64,16); finish(0,32,12,2048,1);
        send_path("missing",7,16); finish(14,0,0,0,1);
        send_path("music/missing",13,16); finish(14,0,0,0,2);
        send_path("empty.wav/x",11,16); finish(15,0,0,0,1);
        send_path("empty.wav/",10,16); finish(15,0,0,0,1);
        send_path("music/sub/track.wav",19,2); finish(10,0,0,0,2);
        send_path("music",5,0); finish(10,0,0,0,0);
        send_path(0,0,16); finish(13,0,0,0,0);
        send_path(0,65,16); finish(13,0,0,0,0);
        send_path(".",1,16); finish(13,0,0,0,0);
        send_path("..",2,16); finish(13,0,0,0,0);
        send_path("music/../x",10,16); finish(13,0,0,0,0);
        if(S_requests!=S_before) fail("dot components performed I/O before validation");
        send_path("bad:name",8,16); finish(13,0,0,0,0);
        send_path(8'h80,1,16); finish(13,0,0,0,0);
        header(4,16); @(negedge S_clk); S_path_valid=1; S_path_data="a"; S_path_last=1;
        @(negedge S_clk); S_path_valid=0; S_path_last=0; finish(13,0,0,0,0);
        header(1,16); @(negedge S_clk); S_path_valid=1; S_path_data="a"; S_path_last=0;
        @(negedge S_clk); S_path_valid=0; finish(13,0,0,0,0);
        header(5,16); @(negedge S_clk); S_cancel=1; @(negedge S_clk); S_cancel=0; finish(8,0,0,0,0);
        send_path("music",5,16); wait(S_model_state==1); @(negedge S_clk); S_cancel=1;
        @(negedge S_clk); S_cancel=0; finish(8,0,0,0,0);
        send_path("music",5,16); wait(u_dut.S_name_valid); @(negedge S_clk); S_cancel=1;
        @(negedge S_clk); S_cancel=0; finish(8,0,0,0,1);
        send_path("music",5,16); wait(S_model_state==1); @(negedge S_clk); S_mounted=0;
        @(negedge S_clk); S_mounted=1; finish(1,0,0,0,0);
        S_force_error=1; send_path("music",5,16); finish(2,0,0,0,0); S_force_error=0;
        send_path("music/sub/track.wav",19,16); finish(0,32,11,100,3);
        S_test_pass=1; $display("PASS: bounded paths, LFN/alias, root/nesting, invalid frames, cancellation and joined retirement"); $finish;
    end
    initial begin #8000000; fail("path watchdog"); end
endmodule
