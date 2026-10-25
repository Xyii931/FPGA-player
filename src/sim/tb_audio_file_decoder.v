`timescale 1ns/1ps
// Independent integer IMA scoreboard; compare every accepted PCM sample.
module tb_audio_file_decoder;
    reg S_clk=0,S_reset=1,S_start=0,S_valid=0,S_last=0,S_abort=0,S_stream_error=0;
    always #4 S_clk=~S_clk;
    reg [31:0] S_size=0;
    reg [7:0] S_byte=0,S_tag=0;
    wire S_start_ready,S_ready,S_busy,S_done,S_err,S_header_valid,S_sample_valid,S_sample_last;
    reg S_header_ready=0,S_sample_ready=0,S_hold=0;
    wire [3:0] S_error;
    wire [7:0] S_result_tag;
    wire [31:0] S_offset,S_data_bytes,S_total,S_sample_index;
    wire [23:0] S_left,S_right;
    reg [7:0] S_file[0:4095];
    reg [15:0] S_expected_l[0:3050],S_expected_r[0:3050];
    integer S_steps[0:88];
    integer S_headers=0,S_samples=0,S_terminals=0,S_ticks=0,S_cases=0;
    integer S_expected_frames=0,S_expected_offset=24,S_expected_bytes=0,S_early_last=-1;
    reg [3:0] S_expected_error=0;
    reg S_wait_header=0,S_wait_sample=0,S_test_pass=0;
    reg [95:0] S_saved_header;
    reg [80:0] S_saved_sample;
    integer S_i;

    audio_file_decoder u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(S_size),.I_tag(S_tag),.I_byte_valid(S_valid),.O_byte_ready(S_ready),
        .I_byte_data(S_byte),.I_byte_last(S_last),.I_abort(S_abort),.I_stream_error(S_stream_error),
        .O_busy(S_busy),.O_done(S_done),.O_err(S_err),.O_error_code(S_error),.O_tag(S_result_tag),
        .O_header_valid(S_header_valid),.I_header_ready(S_header_ready),
        .O_data_offset(S_offset),.O_data_bytes(S_data_bytes),.O_total_frames(S_total),
        .O_sample_valid(S_sample_valid),.I_sample_ready(S_sample_ready),
        .O_left(S_left),.O_right(S_right),.O_sample_index(S_sample_index),.O_sample_last(S_sample_last)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL case %0d: %0s",S_cases,message); $stop; end
    endtask
    always @(negedge S_clk) begin
        S_header_ready=!S_hold && S_ticks%11>=4;
        S_sample_ready=!S_hold && S_ticks%7>=3;
    end
    always @(posedge S_clk) if(!S_reset) begin
        S_ticks=S_ticks+1;
        if(S_wait_header && !S_abort && !S_stream_error &&
            (!S_header_valid || {S_offset,S_data_bytes,S_total}!==S_saved_header)) fail("header changed under backpressure");
        if(S_wait_sample && !S_abort && !S_stream_error &&
            (!S_sample_valid || {S_left,S_right,S_sample_index,S_sample_last}!==S_saved_sample)) fail("sample changed under backpressure");
        S_wait_header=S_header_valid && !S_header_ready;
        S_wait_sample=S_sample_valid && !S_sample_ready;
        S_saved_header={S_offset,S_data_bytes,S_total};
        S_saved_sample={S_left,S_right,S_sample_index,S_sample_last};
        if(S_header_valid && S_header_ready) begin
            S_headers=S_headers+1;
            if(S_headers!=1 || S_total!=S_expected_frames || S_offset!=S_expected_offset || S_data_bytes!=S_expected_bytes)
                fail("header fields/order");
        end
        if(S_sample_valid && S_sample_ready) begin
            if(S_headers!=1 || S_sample_index!=S_samples || S_samples>=S_expected_frames ||
                S_left!=={S_expected_l[S_samples],8'd0} || S_right!=={S_expected_r[S_samples],8'd0} ||
                S_sample_last!==(S_samples+1==S_expected_frames)) fail("independent IMA/PCM sample comparison");
            S_samples=S_samples+1;
        end
        if(S_done) begin
            S_terminals=S_terminals+1;
            if(S_terminals!=1 || S_error!==S_expected_error || S_err!==(S_expected_error!=0) || S_result_tag!==S_tag)
                fail("terminal error/tag/count");
        end
    end
    task put32;
        input integer at,value;
        begin
            S_file[at]=value; S_file[at+1]=value>>8; S_file[at+2]=value>>16; S_file[at+3]=value>>24;
        end
    endtask
    task build_apt;
        input integer frames;
        integer k,b,c,j,base,predictor,index,step,delta,code,word_value;
        begin
            S_size=24+((frames+1016)/1017)*1024;
            S_expected_frames=frames; S_expected_offset=24; S_expected_bytes=S_size-24; S_early_last=-1;
            for(k=0;k<4096;k=k+1) S_file[k]=0;
            S_file[0]="A"; S_file[1]="P"; S_file[2]="T"; S_file[3]="0";
            put32(4,48000); S_file[8]=2; S_file[10]=1; S_file[13]=4; S_file[14]=24; put32(16,frames);
            for(b=0;b<(frames+1016)/1017;b=b+1) begin
                for(c=0;c<2;c=c+1) begin
                    base=24+b*1024+c*512;
                    predictor=c==0 ? 32760-b*10000 : -32760+b*10000;
                    index=(b*35+c*88)%89;
                    word_value=predictor;
                    S_file[base]=word_value; S_file[base+1]=word_value>>8; S_file[base+2]=index;
                    for(k=4;k<512;k=k+1) S_file[base+k]=(k*29+b*17+c*113)%256;
                    for(j=0;j<1017;j=j+1) begin
                        if(j!=0) begin
                            word_value=S_file[base+4+(j-1)/2];
                            code=(j%2==1) ? word_value%16 : word_value/16;
                            step=S_steps[index]; delta=step/8;
                            if(code%2) delta=delta+step/4;
                            if((code/2)%2) delta=delta+step/2;
                            if((code/4)%2) delta=delta+step;
                            predictor=predictor+(code>=8 ? -delta : delta);
                            if(predictor>32767) predictor=32767;
                            if(predictor< -32768) predictor=-32768;
                            case(code%8)
                                4:index=index+2; 5:index=index+4; 6:index=index+6; 7:index=index+8;
                                default:index=index-1;
                            endcase
                            if(index<0) index=0; if(index>88) index=88;
                        end
                        if(b*1017+j<frames) begin
                            if(c==0) S_expected_l[b*1017+j]=predictor;
                            else S_expected_r[b*1017+j]=predictor;
                        end
                    end
                end
            end
        end
    endtask
    task start_job;
        input [3:0] error;
        begin
            wait(S_start_ready); @(negedge S_clk);
            S_headers=0; S_samples=0; S_terminals=0; S_wait_header=0; S_wait_sample=0;
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
        input integer frames,headers;
        begin
            wait(S_terminals==1); repeat(4) @(negedge S_clk);
            if(S_busy || !S_start_ready || S_samples!=frames || S_headers!=headers || S_done) fail("retirement/sample count");
        end
    endtask
    task cancel_decode_stage;
        input [4:0] stage;
        begin
            build_apt(4); start_job(6); send_range(0,S_size);
            wait(u_dut.u_apt.S_state==stage);
            @(negedge S_clk); S_abort=1; S_stream_error=1;
            repeat(6) @(negedge S_clk);
            S_abort=0; S_stream_error=0; finish_job(1,1);
            build_apt(4); start_job(0); send_range(0,S_size); finish_job(4,1);
        end
    endtask
    // Validate large file arithmetic using only the header, then abort before
    // any payload. The reference capacities below are independent 64-bit products.
    task capacity_header;
        input [31:0] file_size,frames;
        input legal;
        begin
            build_apt(0); S_size=file_size; put32(16,frames);
            S_expected_frames=frames; S_expected_bytes=file_size-24;
            start_job(legal ? 6 : 3); send_range(0,24);
            if(legal) begin
                wait(S_headers==1); @(negedge S_clk); S_abort=1;
                repeat(6) @(negedge S_clk); S_abort=0;
                finish_job(0,1);
            end else finish_job(0,0);
        end
    endtask
    initial begin
        // Standard table constants; scoreboard uses integer arithmetic, not DUT functions.
        S_steps[0]=7; S_steps[1]=8; S_steps[2]=9; S_steps[3]=10; S_steps[4]=11; S_steps[5]=12;
        S_steps[6]=13; S_steps[7]=14; S_steps[8]=16; S_steps[9]=17; S_steps[10]=19; S_steps[11]=21;
        S_steps[12]=23; S_steps[13]=25; S_steps[14]=28; S_steps[15]=31; S_steps[16]=34; S_steps[17]=37;
        S_steps[18]=41; S_steps[19]=45; S_steps[20]=50; S_steps[21]=55; S_steps[22]=60; S_steps[23]=66;
        S_steps[24]=73; S_steps[25]=80; S_steps[26]=88; S_steps[27]=97; S_steps[28]=107; S_steps[29]=118;
        S_steps[30]=130; S_steps[31]=143; S_steps[32]=157; S_steps[33]=173; S_steps[34]=190; S_steps[35]=209;
        S_steps[36]=230; S_steps[37]=253; S_steps[38]=279; S_steps[39]=307; S_steps[40]=337; S_steps[41]=371;
        S_steps[42]=408; S_steps[43]=449; S_steps[44]=494; S_steps[45]=544; S_steps[46]=598; S_steps[47]=658;
        S_steps[48]=724; S_steps[49]=796; S_steps[50]=876; S_steps[51]=963; S_steps[52]=1060; S_steps[53]=1166;
        S_steps[54]=1282; S_steps[55]=1411; S_steps[56]=1552; S_steps[57]=1707; S_steps[58]=1878; S_steps[59]=2066;
        S_steps[60]=2272; S_steps[61]=2499; S_steps[62]=2749; S_steps[63]=3024; S_steps[64]=3327; S_steps[65]=3660;
        S_steps[66]=4026; S_steps[67]=4428; S_steps[68]=4871; S_steps[69]=5358; S_steps[70]=5894; S_steps[71]=6484;
        S_steps[72]=7132; S_steps[73]=7845; S_steps[74]=8630; S_steps[75]=9493; S_steps[76]=10442; S_steps[77]=11487;
        S_steps[78]=12635; S_steps[79]=13899; S_steps[80]=15289; S_steps[81]=16818; S_steps[82]=18500; S_steps[83]=20350;
        S_steps[84]=22385; S_steps[85]=24623; S_steps[86]=27086; S_steps[87]=29794; S_steps[88]=32767;
        repeat(5) @(negedge S_clk); S_reset=0;
        build_apt(2060); start_job(0); send_range(0,S_size); finish_job(2060,1);
        build_apt(1017); start_job(0); send_range(0,S_size); finish_job(1017,1);
        build_apt(1); start_job(0); send_range(0,S_size); finish_job(1,1);
        build_apt(0); start_job(0); send_range(0,S_size); finish_job(0,1);
        build_apt(4); S_file[0]="X"; start_job(1); send_range(0,S_size); finish_job(0,0);
        build_apt(4); S_file[4]=0; start_job(2); send_range(0,S_size); finish_job(0,0);
        build_apt(4); S_file[20]=1; start_job(2); send_range(0,S_size); finish_job(0,0);
        build_apt(4); S_size=S_size-1; start_job(3); send_range(0,S_size); finish_job(0,0);
        build_apt(1017); put32(16,1018); start_job(3); send_range(0,S_size); finish_job(0,0);
        build_apt(1); S_file[26]=89; start_job(3); send_range(0,S_size); finish_job(0,1);
        build_apt(1); S_file[24+515]=1; start_job(3); send_range(0,S_size); finish_job(0,1);
        build_apt(4); S_early_last=24; start_job(5); send_range(0,S_size); finish_job(0,1);
        build_apt(4); start_job(6); send_range(0,2);
        @(negedge S_clk); S_abort=1; repeat(4) @(negedge S_clk); S_abort=0; finish_job(0,0);
        build_apt(4); start_job(5); send_range(0,40);
        @(negedge S_clk); S_stream_error=1; repeat(6) @(negedge S_clk); S_stream_error=0; finish_job(0,1);
        build_apt(4); start_job(6); send_range(0,24); S_hold=1;
        wait(S_header_valid); repeat(5) @(negedge S_clk);
        S_abort=1; repeat(6) @(negedge S_clk); S_abort=0; S_hold=0; finish_job(0,0);
        cancel_decode_stage(u_dut.u_apt.DIFF_PAIR);
        cancel_decode_stage(u_dut.u_apt.DIFF_SUM);
        cancel_decode_stage(u_dut.u_apt.ACCUMULATE);
        cancel_decode_stage(u_dut.u_apt.CLIP);
        cancel_decode_stage(u_dut.u_apt.DECODE_COMMIT);
        capacity_header(32'hfffffc18,64'd4194303*64'd1017,1);
        capacity_header(32'hfffffc18,64'd4194302*64'd1017+1,1);
        capacity_header(32'hfffffc18,64'd4194303*64'd1017+1,0);
        capacity_header(32'hfffffc18,64'd4194302*64'd1017,0);
        // A WAV following APT uses the existing real parser without flushing the decoder.
        for(S_i=0;S_i<48;S_i=S_i+1) S_file[S_i]=0;
        S_size=48; S_expected_frames=1; S_expected_offset=44; S_expected_bytes=4; S_early_last=-1;
        S_file[0]="R"; S_file[1]="I"; S_file[2]="F"; S_file[3]="F"; put32(4,40);
        S_file[8]="W"; S_file[9]="A"; S_file[10]="V"; S_file[11]="E";
        S_file[12]="f"; S_file[13]="m"; S_file[14]="t"; S_file[15]=" "; put32(16,16);
        S_file[20]=1; S_file[22]=2; put32(24,48000); put32(28,192000); S_file[32]=4; S_file[34]=16;
        S_file[36]="d"; S_file[37]="a"; S_file[38]="t"; S_file[39]="a"; put32(40,4);
        S_file[45]=8'h80; S_file[46]=8'hff; S_file[47]=8'h7f;
        S_expected_l[0]=16'h8000; S_expected_r[0]=16'h7fff;
        start_job(0); send_range(0,S_size); finish_job(1,1);
        S_test_pass=1; $display("PASS: APT/WAV selection, independent IMA, block boundaries, stalls and errors"); $finish;
    end
    initial begin #5000000; fail("decoder watchdog"); end
endmodule
