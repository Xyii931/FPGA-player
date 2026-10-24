`timescale 1ns/1ps
// Handwritten byte fixtures and expected records, not an executable RTL surrogate.
module tb_playlist_parser;
    reg S_clk=0,S_reset=0,S_start=0,S_byte_valid=0,S_last=0,S_abort=0,S_stream_error=0;
    reg [31:0] S_size=0,S_generation=0;
    reg [15:0] S_tag=0;
    reg [7:0] S_byte=0;
    wire S_start_ready,S_byte_ready,S_busy,S_item_valid,S_done_valid;
    reg S_item_ready=0,S_done_ready=0;
    wire [5:0] S_item_index,S_title_length;
    wire [9:0] S_duration,S_ms;
    wire [2:0] S_transition;
    wire [6:0] S_file_length,S_audio_length,S_count;
    reg [1:0] S_string_kind=0;
    reg [6:0] S_string_address=0;
    wire [7:0] S_string_data,S_warning;
    wire [3:0] S_error;
    wire [1:0] S_order;
    wire [15:0] S_out_tag;
    wire [31:0] S_out_generation;
        wire S_runtime_u_dut_O_order_explicit;
playlist_parser u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(S_size),.I_tag(S_tag),.I_generation(S_generation),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),.I_byte_last(S_last),
        .I_abort(S_abort),.I_stream_error(S_stream_error),.O_busy(S_busy),
        .O_item_valid(S_item_valid),.I_item_ready(S_item_ready),.O_item_index(S_item_index),
        .O_duration(S_duration),.O_transition_ms(S_ms),.O_transition(S_transition),
        .O_file_length(S_file_length),.O_audio_length(S_audio_length),.O_title_length(S_title_length),
        .I_string_kind(S_string_kind),.I_string_address(S_string_address),.O_string_data(S_string_data),
        .O_done_valid(S_done_valid),.I_done_ready(S_done_ready),.O_error(S_error),.O_warning(S_warning),
        .O_item_count(S_count),.O_order(S_order),.O_tag(S_out_tag),.O_generation(S_out_generation),
        .O_policy(S_policy_u_dut_O_policy),
        .O_order_explicit(S_runtime_u_dut_O_order_explicit)
    );
    wire [6:0] S_policy_u_dut_O_policy;
    always #4 S_clk=~S_clk;
    reg [7:0] S_bytes[0:32767];
    reg [511:0] S_files[0:63],S_audios[0:63];
    reg [319:0] S_titles[0:63];
    integer S_file_lengths[0:63],S_audio_lengths[0:63],S_title_lengths[0:63];
    integer S_durations[0:63],S_effects[0:63],S_times[0:63];
    integer S_policies[0:63];
    integer S_length=0,S_expected=0,S_seen=0,S_case=0,S_cycle=0,S_i;
    integer S_consumer,S_kind,S_address,S_string_length,S_last_mode=0;
    reg [511:0] S_expected_string;
    reg [255:0] S_held;
    reg S_test_pass=0;
    task fail;
        input [511:0] message;
        begin $display("FAIL: playlist case %0d: %0s",S_case,message); $stop; end
    endtask
    function integer string_length;
        input [4095:0] value;
        integer index;
        begin
            string_length=0;
            for(index=0;index<512;index=index+1) if(value[index*8+:8]!=0) string_length=index+1;
        end
    endfunction
    task fixture;
        begin S_length=0; S_expected=0; S_seen=0; S_last_mode=0; S_case=S_case+1; end
    endtask
    task append;
        input [4095:0] value;
        integer index,length;
        begin
            length=string_length(value);
            for(index=0;index<length;index=index+1) begin
                S_bytes[S_length]=value[(length-1-index)*8+:8]; S_length=S_length+1;
            end
        end
    endtask
    task raw;
        input [7:0] value;
        begin S_bytes[S_length]=value; S_length=S_length+1; end
    endtask
    task expect_item;
        input [511:0] file_path,audio_path;
        input [319:0] title;
        input integer duration,effect,ms;
        begin
            S_files[S_expected]=file_path; S_audios[S_expected]=audio_path; S_titles[S_expected]=title;
            S_file_lengths[S_expected]=string_length(file_path); S_audio_lengths[S_expected]=string_length(audio_path);
            S_title_lengths[S_expected]=string_length(title); S_durations[S_expected]=duration;
            S_effects[S_expected]=effect; S_times[S_expected]=ms; S_policies[S_expected]=-1; S_expected=S_expected+1;
        end
    endtask
    task start;
        begin
            @(negedge S_clk); S_size=S_length; S_tag=S_case+16'h100; S_generation=S_case+32'h12340000; S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
        end
    endtask
    task send_bytes;
        input integer first,limit;
        integer index;
        begin
            for(index=first;index<limit && !S_done_valid;index=index+1) begin
                @(negedge S_clk); S_byte=S_bytes[index]; S_byte_valid=1;
                S_last=S_last_mode==1 ? index==S_length/2 : (S_last_mode==2 ? 1'b0 : index==S_length-1);
                @(posedge S_clk); while(!S_byte_ready && !S_done_valid) @(posedge S_clk);
                @(negedge S_clk); S_byte_valid=0; S_last=0;
                if(index%7==0) repeat(2) @(negedge S_clk);
            end
        end
    endtask
    task receive_items;
        begin
            for(S_consumer=0;S_consumer<S_expected;S_consumer=S_consumer+1) begin
                wait(S_item_valid || S_done_valid); #1;
                if(!S_item_valid) fail("missing expected item");
                if(S_item_index!==S_consumer || S_duration!==S_durations[S_consumer] ||
                    S_transition!==S_effects[S_consumer] || S_ms!==S_times[S_consumer] ||
                    S_file_length!==S_file_lengths[S_consumer] || S_audio_length!==S_audio_lengths[S_consumer] ||
                    S_title_length!==S_title_lengths[S_consumer]) fail("item metadata/default/override");
                if(S_policies[S_consumer]>=0 && S_policy_u_dut_O_policy!==S_policies[S_consumer])
                    fail("ITEM/GLOBAL/BGM explicit source policy");
                S_held={S_policy_u_dut_O_policy,S_item_index,S_duration,S_transition,S_ms,S_file_length,S_audio_length,S_title_length,S_out_tag,S_out_generation};
                repeat(5) begin
                    @(negedge S_clk);
                    if(!S_item_valid || S_byte_ready || S_done_valid ||
                        {S_policy_u_dut_O_policy,S_item_index,S_duration,S_transition,S_ms,S_file_length,S_audio_length,S_title_length,S_out_tag,S_out_generation}!==S_held)
                        fail("item payload changed under backpressure");
                end
                for(S_kind=0;S_kind<4;S_kind=S_kind+1) begin
                    case(S_kind)
                        0:begin S_expected_string=S_files[S_consumer]; S_string_length=S_file_lengths[S_consumer]; end
                        1:begin S_expected_string=S_audios[S_consumer]; S_string_length=S_audio_lengths[S_consumer]; end
                        2:begin S_expected_string=S_titles[S_consumer]; S_string_length=S_title_lengths[S_consumer]; end
                        default:begin S_expected_string=0; S_string_length=0; end
                    endcase
                    // Include one out-of-range address even for a 64-byte path.
                    for(S_address=0;S_address<=S_string_length;S_address=S_address+1) begin
                        @(negedge S_clk); S_string_kind=S_kind; S_string_address=S_address;
                        @(posedge S_clk); #1;
                        if(S_string_data!==(S_address==S_string_length ? 8'd0 :
                            S_expected_string[(S_string_length-1-S_address)*8+:8])) fail("synchronous string data/bounds");
                    end
                end
                @(negedge S_clk); S_item_ready=1;
                @(negedge S_clk); S_item_ready=0;
            end
        end
    endtask
    task result;
        input [3:0] error;
        input [7:0] warning;
        input [1:0] order;
        begin
            wait(S_done_valid); #1;
            if(S_error!==error || S_warning!==warning || S_count!==S_expected || S_seen!=S_expected ||
                S_order!==order || S_out_tag!==S_tag || S_out_generation!==S_generation) fail("terminal fields/count/identity");
            S_held={S_error,S_warning,S_count,S_order,S_out_tag,S_out_generation};
            @(negedge S_clk); S_abort=1; S_stream_error=1; S_start=1;
            repeat(5) begin
                @(negedge S_clk);
                if(!S_done_valid || S_start_ready || S_byte_ready || S_item_valid ||
                    {S_error,S_warning,S_count,S_order,S_out_tag,S_out_generation}!==S_held) fail("terminal not held");
            end
            S_abort=0; S_stream_error=0; S_start=0; S_done_ready=1;
            @(negedge S_clk); S_done_ready=0; #1;
            if(!S_start_ready || S_busy) fail("parser did not return idle");
        end
    endtask
    task run_fixture;
        input [3:0] error;
        input [7:0] warning;
        input [1:0] order;
        begin
            start;
            fork send_bytes(0,S_length); receive_items; join
            result(error,warning,order);
        end
    endtask
    always @(posedge S_clk) begin
        S_cycle<=S_cycle+1;
        if(!S_reset) begin
            if(S_item_valid && S_item_ready) begin
                if(S_seen>=S_expected) fail("unexpected extra item");
                S_seen=S_seen+1;
            end
            if(S_busy && (S_out_tag!==S_tag || S_out_generation!==S_generation)) fail("transaction identity changed");
        end
    end
    initial begin
        S_reset=1; #29; S_reset=0;
        fixture; run_fixture(0,0,1);
        fixture; append("[GLOBAL]\ninterval=30\ntransition=random\ntransition_ms=600\nbgm=/PLAY/A.WAV\n");
        append("[ITEM]\nfile=0.BMP\nduration=8\ntransition=push\ntransition_ms=200\n[ITEM]\nfile=1.BMP\n");
        append("[ITEM]\nfile=2.BMP\naudio=/PLAY/B.WAV\nduration=11\nduration=0\ntransition=slide\ntransition=bogus\n");
        expect_item("/PLAY/0.BMP","/PLAY/A.WAV","",8,2,200); S_policies[0]=7'h7f;
        expect_item("/PLAY/1.BMP","/PLAY/A.WAV","",30,7,600); S_policies[1]=7'h78;
        expect_item("/PLAY/2.BMP","/PLAY/B.WAV","",11,1,600); S_policies[2]=7'h3b;
        run_fixture(0,8'h04,1);
        fixture; append(" # comment\015\n\t\n[GLOBAL]\015\ninterval=12\015transition=ZOOM\ntransition_ms=1000\norder=NAME\nbgm=aud/base.wav\n");
        append("[ITEM]\nfile=img/One.bmp\ntitle=First\n[ITEM]\nfile=/ROOT//Two.BMP\naudio=AUD/own.wav\nduration=8\ntransition=push\ntransition_ms=600");
        expect_item("/PLAY/img/One.bmp","/PLAY/aud/base.wav","First",12,6,1000);
        expect_item("/ROOT/Two.BMP","/PLAY/AUD/own.wav","",8,2,600); run_fixture(0,0,0);
        // A later GLOBAL section changes only items that start after it.
        fixture; append("[item]\nfile=a.bmp\n[global]\ninterval=33\nbgm=/song.wav\norder=random\n[item]\nfile=b.bmp\n");
        expect_item("/PLAY/a.bmp","","",10,0,400);
        expect_item("/PLAY/b.bmp","/song.wav","",33,0,400); run_fixture(0,0,2);
        // Last valid duplicate wins; invalid values preserve prior valid values.
        fixture; append("[GLOBAL]\ninterval=20\ninterval=0\ntransition=slide\ntransition=bad\ntransition_ms=200\ntransition_ms=999\norder=list\norder=no\n");
        append("[ITEM]\nfile=a.bmp\nfile=b.bmp\nfile=../bad.bmp\naudio=ok.wav\naudio=\nduration=6\nduration=999999999999999999999999\ntransition=blinds\ntransition=no\ntransition_ms=600\ntransition_ms=1\ntitle=OK\ntitle=");
        expect_item("/PLAY/b.bmp","/PLAY/ok.wav","",6,4,600); run_fixture(0,8'h0c,1);
        fixture; append("outside=yes\n[UNKNOWN]\nfile=no.bmp\n[ITEM]\nmissing equals\nwhat=1\n[ITEM]\nfile=real.bmp\n");
        expect_item("/PLAY/real.bmp","","",10,0,400); run_fixture(0,8'h23,1);
        // Empty/unsafe paths are rejected, and valid paths remain usable.
        fixture; append("[ITEM]\nfile=\n[ITEM]\nfile=./bad.bmp\n[ITEM]\nfile=folder/../bad.bmp\n[ITEM]\nfile=/\n[ITEM]\nfile=a/\n[ITEM]\nfile=x\\y.bmp\n[ITEM]\nfile=bad?.bmp\n[ITEM]\nfile=//a///b.bmp\n");
        expect_item("/a/b.bmp","","",10,0,400); run_fixture(0,8'h28,1);
        // Exactly 64 bytes after adding /PLAY/, then an overlong duplicate.
        fixture; append("[ITEM]\nfile=");
        for(S_i=0;S_i<58;S_i=S_i+1) raw(97); raw(10);
        append("file="); for(S_i=0;S_i<59;S_i=S_i+1) raw(98); raw(10);
        expect_item("/PLAY/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","","",10,0,400);
        run_fixture(0,8'h08,1);
        // 255-byte comment accepted, 256-byte assignment wholly discarded.
        fixture; raw(35); for(S_i=0;S_i<254;S_i=S_i+1) raw(99); raw(10);
        append("[ITEM]\nfile=keep.bmp\ntitle="); for(S_i=0;S_i<250;S_i=S_i+1) raw(116); raw(10);
        append("duration=9\n"); expect_item("/PLAY/keep.bmp","","",9,0,400); run_fixture(0,8'h80,1);
        // 39 ASCII bytes followed by a pair: truncate before the pair, keep prefix.
        fixture; append("[ITEM]\nfile=a.bmp\ntitle=");
        for(S_i=0;S_i<39;S_i=S_i+1) raw(65); raw(8'hd6); raw(8'hd0); raw(10);
        expect_item("/PLAY/a.bmp","","AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",10,0,400); run_fixture(0,8'h10,1);
        // Legal pair is retained verbatim; invalid duplicate cannot erase it.
        fixture; append("[ITEM]\nfile=a.bmp\ntitle="); raw(8'hd6); raw(8'hd0); append("OK\ntitle="); raw(8'ha1); raw(10);
        expect_item("/PLAY/a.bmp","",{8'hd6,8'hd0,"OK"},10,0,400); run_fixture(0,8'h10,1);
        // Whitespace/key folding, numeric boundaries and an exact 40-byte title.
        fixture; append("\t[ItEm] \015\n\tFiLe \t=\t Keep.BMP \t\015\n duration=600\n duration=601\n transition_ms=1000\n=bad\n title=");
        for(S_i=0;S_i<38;S_i=S_i+1) raw(66); raw(8'hd6); raw(8'hd0); raw(13);
        expect_item("/PLAY/Keep.BMP","",{"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",8'hd6,8'hd0},600,0,1000);
        run_fixture(0,8'h06,1);
        // A 255-byte numeric assignment is legal if its value stays in range.
        fixture; append("[ITEM]\nfile=a.bmp\nduration=");
        for(S_i=0;S_i<245;S_i=S_i+1) raw(48); raw(49); raw(10);
        expect_item("/PLAY/a.bmp","","",1,0,400); run_fixture(0,0,1);
        // An overlong final line is discarded; the prior file key still applies.
        fixture; append("[ITEM]\nfile=a.bmp\ntitle="); for(S_i=0;S_i<251;S_i=S_i+1) raw(65);
        expect_item("/PLAY/a.bmp","","",10,0,400); run_fixture(0,8'h80,1);
        // All eight transition values and all allowed transition durations.
        fixture; append("[ITEM]\nfile=a.bmp\ntransition=fade\ntransition_ms=200\n[ITEM]\nfile=a.bmp\ntransition=slide\ntransition_ms=400\n");
        append("[ITEM]\nfile=a.bmp\ntransition=push\ntransition_ms=600\n[ITEM]\nfile=a.bmp\ntransition=wipe\ntransition_ms=1000\n");
        append("[ITEM]\nfile=a.bmp\ntransition=blinds\n[ITEM]\nfile=a.bmp\ntransition=mosaic\n[ITEM]\nfile=a.bmp\ntransition=zoom\n[ITEM]\nfile=a.bmp\ntransition=random\n");
        for(S_i=0;S_i<8;S_i=S_i+1) expect_item("/PLAY/a.bmp","","",10,S_i,S_i==0 ? 200 : (S_i==2 ? 600 : (S_i==3 ? 1000 : 400)));
        run_fixture(0,0,1);
        fixture;
        for(S_i=0;S_i<66;S_i=S_i+1) begin
            append("[ITEM]\nfile=a.bmp\n"); if(S_i<64) expect_item("/PLAY/a.bmp","","",10,0,400);
        end
        run_fixture(0,8'h40,1);
        // Input framing errors cannot commit the currently accumulating item.
        fixture; append("[ITEM]\nfile=some-long-name.bmp\ntitle=still building\n"); S_last_mode=1; run_fixture(1,0,1);
        fixture; append("[ITEM]\nfile=a.bmp"); S_last_mode=2; run_fixture(1,0,1);
        // Abort in line reception, and a fresh transaction after the held result.
        fixture; append("[ITEM]\nfile=a.bmp\n"); start; send_bytes(0,10);
        @(negedge S_clk); S_abort=1; @(negedge S_clk); S_abort=0; result(2,0,1);
        fixture; append("[ITEM]\nfile=a.bmp\n"); start; send_bytes(0,10);
        @(negedge S_clk); S_stream_error=1; @(negedge S_clk); S_stream_error=0; result(1,0,1);
        // Cancel a held candidate, before item_ready. Its data is never committed.
        fixture; append("[ITEM]\nfile=a.bmp"); start;
        fork
            send_bytes(0,S_length);
            begin wait(S_item_valid); @(negedge S_clk); S_abort=1; @(negedge S_clk); S_abort=0; end
        join
        result(2,0,1);
        // A later stream failure revokes a held candidate just like cancellation.
        fixture; append("[ITEM]\nfile=a.bmp"); start;
        fork
            send_bytes(0,S_length);
            begin wait(S_item_valid); @(negedge S_clk); S_stream_error=1; @(negedge S_clk); S_stream_error=0; end
        join
        result(1,0,1);
        // Previously handed-off items stay counted, but remain tentative to caller.
        fixture; append("[ITEM]\nfile=first.bmp\n[ITEM]\nfile=second.bmp");
        expect_item("/PLAY/first.bmp","","",10,0,400); start;
        fork
            send_bytes(0,S_length);
            receive_items;
            begin
                wait(S_count==1 && S_item_valid); @(negedge S_clk); S_stream_error=1;
                @(negedge S_clk); S_stream_error=0;
            end
        join
        result(1,0,1);
        fixture; append("unread bytes"); S_abort=1; start; S_abort=0; result(2,0,1);
        // Reset discards a partial transaction without publishing a terminal.
        fixture; append("[ITEM]\nfile=a.bmp\n"); start; send_bytes(0,10);
        @(negedge S_clk); S_reset=1; @(negedge S_clk); S_reset=0; #1;
        if(S_done_valid || S_item_valid || !S_start_ready) fail("reset retained a partial transaction");
        fixture; append("[ITEM]\nfile=after.bmp\n"); expect_item("/PLAY/after.bmp","","",10,0,400); run_fixture(0,0,1);
        if(S_start_ready!==1) fail("not idle at test end");
        S_test_pass=1; $display("PASS: playlist parser fixtures, inheritance, strings, limits, backpressure and cancellation"); $finish;
    end
    initial begin #10000000; fail("playlist watchdog"); end
endmodule
