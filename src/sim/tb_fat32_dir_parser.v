`timescale 1ns/1ps
module tb_fat32_dir_parser;
    reg S_clk=0,S_reset=1,S_start=0,S_byte_valid=0,S_end_valid=0,S_cancel=0;
    always #4 S_clk=~S_clk;
    wire S_start_ready,S_byte_ready,S_end_ready,S_entry_valid,S_name_valid,S_name_last,S_done;
    reg [7:0] S_byte=0,S_end_error=0;
    reg S_entry_ready=0,S_name_ready=0,S_done_ready=0;
    wire [7:0] S_attr,S_name,S_error;
    wire [31:0] S_size,S_cluster;
    wire [87:0] S_alias;
    wire [6:0] S_length;
    wire S_lfn;
    wire [2:0] S_warning;
    reg [7:0] S_entry[0:31],S_text[0:259];
    reg [87:0] S_short;
    reg [7:0] S_sum;
    integer S_i,S_j,S_offset,S_entries=0,S_names=0,S_position=0,S_expected_length=0,S_expected_entries=0,S_cycle=0;
    integer S_warn_bad=0,S_warn_long=0,S_warn_short=0,S_cases=0;
    reg [7:0] S_expected[0:63];
    reg S_expected_lfn=0,S_wait_entry=0,S_wait_name=0,S_test_pass=0;
    reg [167:0] S_held_entry;
    reg [8:0] S_held_name;
    fat32_dir_parser u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_end_valid(S_end_valid),.O_end_ready(S_end_ready),.I_end_error(S_end_error),.I_cancel(S_cancel),
        .O_entry_valid(S_entry_valid),.I_entry_ready(S_entry_ready),.O_attr(S_attr),.O_size(S_size),.O_first_cluster(S_cluster),
        .O_alias(S_alias),.O_name_length(S_length),.O_is_lfn(S_lfn),
        .O_name_valid(S_name_valid),.I_name_ready(S_name_ready),.O_name_data(S_name),.O_name_last(S_name_last),
        .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),.O_warning(S_warning));
    task fail;
        input [511:0] message;
        begin $display("FAIL: directory case %0d: %0s",S_cases,message); $stop; end
    endtask
    task send_byte;
        input [7:0] value;
        begin
            @(negedge S_clk); S_byte=value; S_byte_valid=1;
            @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
            @(negedge S_clk); S_byte_valid=0;
        end
    endtask
    task send_entry;
        integer k;
        begin for(k=0;k<32;k=k+1) send_byte(S_entry[k]); end
    endtask
    task short_entry;
        integer k;
        begin
            for(k=0;k<32;k=k+1) S_entry[k]=0;
            S_short={8'h56,8'h41,8'h57,8'h20,8'h20,8'h20,8'h20,8'h20,8'h47,8'h4e,8'h53}; // SNG     WAV
            S_sum=0;
            for(k=0;k<11;k=k+1) begin
                S_entry[k]=S_short[k*8+:8]; S_sum={S_sum[0],S_sum[7:1]}+S_entry[k];
            end
            S_entry[11]=8'h20; S_entry[26]=7; S_entry[28]=8'h34; S_entry[29]=8'h12;
        end
    endtask
    task make_lfn;
        input integer ordinal,last,length;
        integer k,index,at;
        begin
            for(k=0;k<32;k=k+1) S_entry[k]=0;
            S_entry[0]=ordinal|(last ? 64 : 0); S_entry[11]=15; S_entry[13]=S_sum;
            for(k=0;k<13;k=k+1) begin
                case(k)
                    0:at=1; 1:at=3; 2:at=5; 3:at=7; 4:at=9; 5:at=14; 6:at=16;
                    7:at=18; 8:at=20; 9:at=22; 10:at=24; 11:at=28; default:at=30;
                endcase
                index=(ordinal-1)*13+k;
                if(index<length) begin S_entry[at]=S_text[index]; S_entry[at+1]=0; end
                else if(index==length) begin S_entry[at]=0; S_entry[at+1]=0; end
                else begin S_entry[at]=255; S_entry[at+1]=255; end
            end
        end
    endtask
    task start;
        begin
            S_cases=S_cases+1; S_expected_entries=S_entries; S_expected_length=0;
            @(negedge S_clk); S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
        end
    endtask
    task expect_short;
        integer k;
        begin
            S_expected_lfn=0; S_expected_length=7;
            S_expected[0]="S"; S_expected[1]="N"; S_expected[2]="G"; S_expected[3]=".";
            S_expected[4]="W"; S_expected[5]="A"; S_expected[6]="V";
        end
    endtask
    task expect_long;
        input integer length;
        integer k;
        begin
            S_expected_lfn=1; S_expected_length=length;
            for(k=0;k<length;k=k+1) S_expected[k]=S_text[k];
        end
    endtask
    task finish;
        input [7:0] error;
        input integer count;
        begin
            wait(S_done); #1;
            if(S_error!==error || S_entries-S_expected_entries!=count) fail("directory terminal/entry count");
            repeat(5) begin @(negedge S_clk); if(!S_done || S_error!==error) fail("done under backpressure"); end
            S_done_ready=1; @(negedge S_clk); S_done_ready=0;
        end
    endtask
    task end_stream;
        input [7:0] error;
        begin
            @(negedge S_clk); S_end_error=error; S_end_valid=1;
            @(posedge S_clk); while(!S_end_ready) @(posedge S_clk);
            @(negedge S_clk); S_end_valid=0;
        end
    endtask
    always @(negedge S_clk) begin
        S_cycle=S_cycle+1; S_entry_ready=S_cycle%9>=4; S_name_ready=S_cycle%7>=2;
    end
    always @(posedge S_clk) if(!S_reset) begin
        if(S_warning[0]) S_warn_bad=S_warn_bad+1;
        if(S_warning[1]) S_warn_long=S_warn_long+1;
        if(S_warning[2]) S_warn_short=S_warn_short+1;
        if(S_wait_entry && !S_cancel && (!S_entry_valid ||
            {S_attr,S_size,S_cluster,S_alias,S_length,S_lfn}!==S_held_entry)) fail("entry changed under backpressure");
        if(S_wait_name && !S_cancel && (!S_name_valid || {S_name_last,S_name}!==S_held_name)) fail("name under backpressure");
        S_wait_entry=S_entry_valid && !S_entry_ready; S_held_entry={S_attr,S_size,S_cluster,S_alias,S_length,S_lfn};
        S_wait_name=S_name_valid && !S_name_ready; S_held_name={S_name_last,S_name};
        if(S_entry_valid && S_entry_ready) begin
            if(S_length!=S_expected_length || S_lfn!==S_expected_lfn || S_attr!=32 || S_size!=32'h1234 ||
                S_cluster!=7 || S_alias!==S_short) fail("entry metadata/name selection");
            S_entries=S_entries+1; S_position=0;
        end
        if(S_name_valid && S_name_ready) begin
            if(S_name!==S_expected[S_position] || S_name_last!==(S_position+1==S_expected_length)) fail("name bytes/last");
            S_position=S_position+1; if(S_name_last) S_names=S_names+1;
        end
    end
    initial begin
        for(S_i=0;S_i<260;S_i=S_i+1) S_text[S_i]=65+S_i%26;
        #37; S_reset=0;
        start; short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        start; short_entry; S_entry[12]=24; expect_short;
        for(S_i=0;S_i<7;S_i=S_i+1) if(S_expected[S_i]>="A" && S_expected[S_i]<="Z") S_expected[S_i]=S_expected[S_i]+32;
        send_entry; send_byte(0); finish(0,1);
        start; short_entry; make_lfn(1,1,12); send_entry;
        short_entry; expect_long(12); send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(2,1,26); send_entry; make_lfn(1,0,26); send_entry;
        short_entry; expect_long(26); send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(3,1,32); send_entry; make_lfn(2,0,32); send_entry; make_lfn(1,0,32); send_entry;
        short_entry; expect_long(32); send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(5,1,64); send_entry;
        for(S_j=4;S_j>0;S_j=S_j-1) begin make_lfn(S_j,0,64); send_entry; end
        short_entry; expect_long(64); send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(5,1,65); send_entry;
        for(S_j=4;S_j>0;S_j=S_j-1) begin make_lfn(S_j,0,65); send_entry; end
        short_entry; send_entry; end_stream(0); finish(0,0);
        if(S_warn_long!=1) fail("long name was truncated instead of rejected");
        start; short_entry; make_lfn(1,1,12); S_entry[2]=1; send_entry;
        short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(1,1,12); S_entry[13]=S_sum+1; send_entry;
        short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(2,1,20); send_entry;
        make_lfn(1,0,20); S_entry[12]=1; send_entry;
        short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(2,1,20); send_entry;
        short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        start; short_entry; make_lfn(1,1,5); S_entry[16]=65; S_entry[17]=0; send_entry;
        short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        start; short_entry; S_entry[0]=8'he5; send_entry;
        short_entry; S_entry[11]=8; send_entry;
        short_entry; S_entry[0]="."; send_entry;
        short_entry; expect_short; send_entry; send_byte(0); finish(0,1);
        start; short_entry; S_entry[0]=8'h05; send_entry; end_stream(0); finish(0,0);
        start; short_entry; S_entry[1]=32; expect_short; send_entry; end_stream(0); finish(0,0);
        start; send_byte(65); end_stream(0); finish(3,0);
        start; end_stream(2); finish(2,0);
        start; short_entry; make_lfn(1,1,12); send_entry;
        @(negedge S_clk); S_cancel=1; @(negedge S_clk); S_cancel=0; finish(8,0);
        start; short_entry; expect_short; send_entry; end_stream(0); finish(0,1);
        if(S_names!=S_entries || S_warn_bad<4 || S_warn_short<2) fail("missing warning/name completion");
        S_test_pass=1; $display("PASS: directory short names, ASCII LFN, checksum/order/UTF16 validation, bounds, backpressure and cancel"); $finish;
    end
    initial begin #2000000; fail("directory watchdog"); end
endmodule
