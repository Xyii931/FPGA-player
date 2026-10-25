`timescale 1ns/1ps
// Real parser + index store. Source byte and retirement endpoints are test stimulus only.
module tb_playlist_index_builder;
    wire [6:0] S_policy_u_dut_O_read_policy;
    reg S_clk=0;
    reg S_reset=1;
    reg S_media_valid=1;
    reg [31:0] S_media_generation=32'h12345678;
    reg S_start=0,S_order_override=0;
    reg [1:0] S_runtime_order=1;
    wire S_start_ready;
    reg [31:0] S_size=0;
    reg [31:0] S_generation=32'h12345678;
    reg [31:0] S_seed=1;
    reg [15:0] S_tag=0;
    reg S_abort=0;
    reg S_stream_error=0;
    reg S_byte_valid=0;
    wire S_byte_ready;
    reg [7:0] S_byte=0;
    reg S_last=0;
    reg [15:0] S_byte_tag=0;
    reg [31:0] S_byte_generation=0;
    reg S_retire_valid=0;
    wire S_retire_ready;
    reg [15:0] S_retire_tag=0;
    reg [31:0] S_retire_generation=0;
    reg [7:0] S_retire_error=0;
    wire S_cancel;
    wire [15:0] S_source_tag;
    wire [31:0] S_source_generation;
    wire S_busy;
    wire S_done;
    reg S_done_ready=0;
    wire [3:0] S_error;
    wire [7:0] S_warning;
    wire [6:0] S_count;
    wire [15:0] S_out_tag;
    wire [31:0] S_out_generation;
    wire S_committed;
    wire S_fallback;
    wire S_active_valid;
    wire [6:0] S_active_count;
    wire [31:0] S_active_generation;
    wire [31:0] S_revision;
    reg S_acquire=0;
    wire S_acquire_ready;
    wire S_snapshot_valid;
    wire [6:0] S_snapshot_count;
    wire [31:0] S_snapshot_generation;
    wire [31:0] S_snapshot_revision;
    reg S_release=0;
    wire S_release_ready;
    reg S_read=0;
    wire S_read_ready;
    reg [5:0] S_read_index=0;
    reg [1:0] S_read_kind=0;
    reg [6:0] S_read_address=0;
    reg [15:0] S_read_tag=0;
    wire S_read_result;
    reg S_read_result_ready=0;
    wire [6:0] S_read_file_length;
    wire [6:0] S_read_audio_length;
    wire [5:0] S_read_title_length;
    wire [9:0] S_read_duration;
    wire [9:0] S_read_ms;
    wire [2:0] S_read_effect;
    wire [7:0] S_read_data;
    wire [15:0] S_read_out_tag;
    wire [3:0] S_read_error;
        wire [1:0] S_runtime_u_dut_O_active_order;
    wire [1:0] S_runtime_u_dut_O_active_base_order;
    wire S_runtime_u_dut_O_active_base_order_explicit;
    wire S_runtime_u_dut_O_reorder_ready;
    wire S_runtime_u_dut_O_reorder_done_valid;
    wire [3:0] S_runtime_u_dut_O_reorder_error;
    wire [15:0] S_runtime_u_dut_O_reorder_tag;
    wire [31:0] S_runtime_u_dut_O_reorder_generation;
    wire [31:0] S_runtime_u_dut_O_reorder_revision;
    wire [5:0] S_runtime_u_dut_O_reorder_current_index;
playlist_index_builder u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(S_media_valid),
        .I_media_generation(S_media_generation),.I_start_valid(S_start),.O_start_ready(S_start_ready),
        .I_file_size(S_size),.I_generation(S_generation),.I_seed(S_seed),
        .I_tag(S_tag),.I_abort(S_abort),.I_stream_error(S_stream_error),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_byte_last(S_last),.I_byte_tag(S_byte_tag),.I_byte_generation(S_byte_generation),
        .I_retire_valid(S_retire_valid),.O_retire_ready(S_retire_ready),.I_retire_tag(S_retire_tag),
        .I_retire_generation(S_retire_generation),.I_retire_error(S_retire_error),.O_source_cancel(S_cancel),
        .O_source_tag(S_source_tag),.O_source_generation(S_source_generation),.O_busy(S_busy),
        .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),
        .O_warning(S_warning),.O_count(S_count),.O_tag(S_out_tag),
        .O_generation(S_out_generation),.O_committed(S_committed),.O_fallback_required(S_fallback),
        .O_active_valid(S_active_valid),.O_active_count(S_active_count),.O_active_generation(S_active_generation),
        .O_active_revision(S_revision),.I_acquire_valid(S_acquire),.O_acquire_ready(S_acquire_ready),
        .O_snapshot_valid(S_snapshot_valid),.O_snapshot_count(S_snapshot_count),.O_snapshot_generation(S_snapshot_generation),
        .O_snapshot_revision(S_snapshot_revision),.I_release_valid(S_release),.O_release_ready(S_release_ready),
        .I_read_valid(S_read),.O_read_ready(S_read_ready),.I_read_index(S_read_index),
        .I_read_kind(S_read_kind),.I_read_address(S_read_address),.I_read_tag(S_read_tag),
        .O_read_result_valid(S_read_result),.I_read_result_ready(S_read_result_ready),.O_read_file_length(S_read_file_length),
        .O_read_audio_length(S_read_audio_length),.O_read_title_length(S_read_title_length),.O_read_duration(S_read_duration),
        .O_read_transition_ms(S_read_ms),.O_read_transition(S_read_effect),.O_read_data(S_read_data),
        .O_read_tag(S_read_out_tag),.O_read_error(S_read_error),
        .I_directory_mode(1'd0),
        .I_directory_lease_grant(1'd0),
        .I_directory_sector_budget(32'd0),
        .I_directory_duration(10'd0),
        .I_directory_transition_ms(10'd0),
        .I_directory_transition(3'd0),
        .I_directory_order(2'd0),
        .O_directory_lease_request(),
        .O_directory_lease_active(),
        .O_directory_error(),
        .O_directory_primary_error(),
        .O_directory_storage_error(),
        .O_directory_warning(),
        .O_directory_sectors(),
        .O_enum_valid(),
        .I_enum_ready(1'd0),
        .O_enum_tag(),
        .O_enum_path_length(),
        .O_enum_sector_budget(),
        .O_enum_path_valid(),
        .I_enum_path_ready(1'd0),
        .O_enum_path_data(),
        .O_enum_path_last(),
        .O_enum_stop(),
        .O_enum_cancel(),
        .I_enum_entry_valid(1'd0),
        .O_enum_entry_ready(),
        .I_enum_attr(8'd0),
        .I_enum_size(32'd0),
        .I_enum_first_cluster(32'd0),
        .I_enum_name_length(7'd0),
        .I_enum_name_valid(1'd0),
        .O_enum_name_ready(),
        .I_enum_name_data(8'd0),
        .I_enum_name_last(1'd0),
        .I_enum_done_valid(1'd0),
        .O_enum_done_ready(),
        .I_enum_tag(16'd0),
        .I_enum_generation(32'd0),
        .I_enum_sectors(32'd0),
        .I_enum_error(8'd0),
        .I_enum_storage_error(4'd0),
        .I_enum_warning(3'd0),
        .O_read_policy(S_policy_u_dut_O_read_policy),
        .I_order_override(S_order_override),
        .I_runtime_order(S_runtime_order),
        .O_active_order(S_runtime_u_dut_O_active_order),
        .O_active_base_order(S_runtime_u_dut_O_active_base_order),
        .O_active_base_order_explicit(S_runtime_u_dut_O_active_base_order_explicit),
        .I_reorder_valid(1'b0),
        .O_reorder_ready(S_runtime_u_dut_O_reorder_ready),
        .I_reorder_order(2'd0),
        .I_reorder_seed(32'd0),
        .I_reorder_generation(32'd0),
        .I_reorder_tag(16'd0),
        .I_reorder_current_index(6'd0),
        .I_reorder_abort(1'b0),
        .O_reorder_done_valid(S_runtime_u_dut_O_reorder_done_valid),
        .I_reorder_done_ready(1'b0),
        .O_reorder_error(S_runtime_u_dut_O_reorder_error),
        .O_reorder_tag(S_runtime_u_dut_O_reorder_tag),
        .O_reorder_generation(S_runtime_u_dut_O_reorder_generation),
        .O_reorder_revision(S_runtime_u_dut_O_reorder_revision),
        .O_reorder_current_index(S_runtime_u_dut_O_reorder_current_index)
    );
    always #4 S_clk=~S_clk;
    reg [7:0] S_bytes[0:32767];
    reg [511:0] S_files[0:63],S_audios[0:63];
    reg [319:0] S_titles[0:63];
    integer S_durations[0:63],S_effects[0:63],S_times[0:63];
    integer S_first_shuffle[0:63];
    reg [63:0] S_seen;
    reg S_test_pass=0,S_retire_sent=0,S_retire_ok=0;
    integer S_case=0,S_length=0,S_i,S_j,S_id,S_last_mode=0,S_before_revision=0;
    reg [511:0] S_text;

    task fail;
        input [639:0] message;
        begin $display("FAIL: playlist builder case %0d: %0s",S_case,message); $stop; end
    endtask
    function integer length;
        input [4095:0] value;
        integer index;
        begin length=0; for(index=0;index<512;index=index+1) if(value[index*8+:8]!=0) length=index+1; end
    endfunction
    task fixture;
        begin S_length=0; S_last_mode=0; S_case=S_case+1; end
    endtask
    task append;
        input [4095:0] value;
        integer index,bytes;
        begin
            bytes=length(value);
            for(index=0;index<bytes;index=index+1) begin
                S_bytes[S_length]=value[(bytes-1-index)*8+:8]; S_length=S_length+1;
            end
        end
    endtask
    task raw;
        input [7:0] value;
        begin S_bytes[S_length]=value; S_length=S_length+1; end
    endtask
    task expect_record;
        input integer id;
        input [511:0] file_path,audio_path;
        input [319:0] title;
        input integer duration,effect,ms;
        begin
            S_files[id]=file_path; S_audios[id]=audio_path; S_titles[id]=title;
            S_durations[id]=duration; S_effects[id]=effect; S_times[id]=ms;
        end
    endtask
    task start;
        begin
            @(negedge S_clk); S_size=S_length; S_generation=S_media_generation; S_tag=S_case+16'h500;
            S_retire_sent=0; S_retire_ok=0; S_before_revision=S_revision; S_start=1;
            @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
            @(negedge S_clk); S_start=0;
            if(!S_busy || S_cancel || S_source_tag!==S_tag || S_source_generation!==S_generation)
                fail("start ownership");
        end
    endtask
    task put;
        input [7:0] value;
        input last;
        input [15:0] tag;
        input [31:0] generation;
        begin
            @(negedge S_clk); S_byte=value; S_last=last; S_byte_tag=tag; S_byte_generation=generation; S_byte_valid=1;
            @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
            @(negedge S_clk); S_byte_valid=0;
        end
    endtask
    task send_range;
        input integer first,limit;
        integer index;
        reg last;
        begin
            for(index=first;index<limit;index=index+1) begin
                if(index%13==0) begin
                    put(8'he7,1,S_tag^16'h0100,S_generation);
                    put(8'he8,1,S_tag,S_generation^32'h00010000);
                end
                last=index==S_length-1;
                if(S_last_mode==1) last=index==S_length-2;
                if(S_last_mode==2) last=0;
                put(S_bytes[index],last,S_tag,S_generation);
                if(index%7==0) repeat(2) @(negedge S_clk);
            end
        end
    endtask
    task retire;
        input [15:0] tag;
        input [31:0] generation;
        input [7:0] error;
        begin
            @(negedge S_clk); S_retire_tag=tag; S_retire_generation=generation; S_retire_error=error; S_retire_valid=1;
            @(posedge S_clk); while(!S_retire_ready) @(posedge S_clk);
            @(negedge S_clk); S_retire_valid=0;
            if(tag==S_tag && generation==S_generation) begin S_retire_sent=1; S_retire_ok=error==0; end
        end
    endtask
    task wait_without_retirement;
        input integer cycles;
        integer index;
        begin
            for(index=0;index<cycles;index=index+1) begin
                @(negedge S_clk);
                if(S_done || !S_busy || S_revision!=S_before_revision) fail("finished/committed before actual source retirement");
            end
        end
    endtask
    task done;
        input integer error,count;
        reg [159:0] held;
        begin
            wait(S_done); @(negedge S_clk);
            if(!S_retire_sent || S_error!==error || S_count!==count || S_out_tag!==S_tag || S_out_generation!==S_generation ||
                    S_committed!==(error==0) || S_fallback!==(error==5)) fail("done metadata/identity/decision");
            if(error==0 && (!S_retire_ok || S_revision!=S_before_revision+1 || !S_active_valid)) fail("successful commit not atomic");
            if(error!=0 && S_revision!=S_before_revision) fail("failed build replaced active index");
            held={S_error,S_warning,S_count,S_out_tag,S_out_generation,S_committed,S_fallback};
            // Late abort/errors must not rewrite an already published terminal.
            S_abort=1; S_stream_error=1;
            repeat(7) begin
                @(negedge S_clk);
                if(!S_done || !S_busy || S_start_ready || S_cancel || held!==
                    {S_error,S_warning,S_count,S_out_tag,S_out_generation,S_committed,S_fallback}) fail("terminal backpressure");
            end
            S_abort=0; S_stream_error=0; S_done_ready=1;
            @(negedge S_clk); S_done_ready=0;
            if(S_busy || S_done) fail("terminal did not retire");
        end
    endtask
    task acquire;
        input integer count;
        begin
            @(negedge S_clk); S_acquire=1;
            @(posedge S_clk); while(!S_acquire_ready) @(posedge S_clk);
            @(negedge S_clk); S_acquire=0;
            if(!S_snapshot_valid || S_snapshot_count!=count || S_snapshot_generation!=S_media_generation ||
                    S_snapshot_revision!=S_revision) fail("snapshot acquisition");
        end
    endtask
    task release_snapshot;
        begin
            @(negedge S_clk); S_release=1;
            @(posedge S_clk); while(!S_release_ready) @(posedge S_clk);
            @(negedge S_clk); S_release=0;
            if(S_snapshot_valid) fail("snapshot release");
        end
    endtask
    task read_request;
        input integer index,kind,address;
        begin
            @(negedge S_clk); S_read_index=index; S_read_kind=kind; S_read_address=address; S_read_tag=S_read_tag+16'd1; S_read=1;
            @(posedge S_clk); while(!S_read_ready) @(posedge S_clk);
            @(negedge S_clk); S_read=0;
        end
    endtask
    task read_accept;
        input integer error;
        reg [95:0] held;
        reg [15:0] expected_tag;
        begin
            wait(S_read_result); @(negedge S_clk);
            if(S_read_error!==error || S_read_out_tag!==S_read_tag) fail("read error code/tag");
            expected_tag=S_read_tag; S_read_tag=S_read_tag^16'hc000;
            held={S_read_out_tag,S_read_error,S_read_data,S_read_file_length,S_read_audio_length,S_read_title_length,S_read_duration,S_read_effect,S_read_ms};
            repeat(3) begin
                @(negedge S_clk);
                if(!S_read_result || S_release_ready || S_read_ready || held!==
                    {S_read_out_tag,S_read_error,S_read_data,S_read_file_length,S_read_audio_length,S_read_title_length,S_read_duration,S_read_effect,S_read_ms})
                    fail("read result backpressure");
            end
            S_read_tag=expected_tag; S_read_result_ready=1; @(negedge S_clk); S_read_result_ready=0;
        end
    endtask
    task check_record;
        input integer logical_index,id;
        integer kind,address,bytes;
        reg [511:0] value;
        reg [7:0] expected;
        begin
            for(kind=0;kind<3;kind=kind+1) begin
                case(kind) 0:value=S_files[id]; 1:value=S_audios[id]; 2:value={192'd0,S_titles[id]}; endcase
                bytes=length(value);
                // Include first out-of-range address; it must not expose another slot.
                for(address=0;address<=bytes;address=address+1) begin
                    read_request(logical_index,kind,address); wait(S_read_result); @(negedge S_clk);
                    expected=0; if(address<bytes) expected=value[(bytes-1-address)*8+:8];
                    if(S_read_data!==expected || S_read_file_length!==length(S_files[id]) ||
                            S_read_audio_length!==length(S_audios[id]) || S_read_title_length!==length({192'd0,S_titles[id]}) ||
                            S_read_duration!==S_durations[id] || S_read_effect!==S_effects[id] || S_read_ms!==S_times[id])
                        fail("record metadata/string no longer matches permutation");
                    read_accept(0);
                end
            end
        end
    endtask

    // Public protocol invariant: a commit may never precede matching successful retirement.
    always @(negedge S_clk) begin
        if(!S_reset && S_busy && S_revision!=S_before_revision && !S_retire_ok)
            fail("revision changed without matching source retirement");
        if(!S_reset && S_cancel && (S_source_tag!==S_tag || S_source_generation!==S_generation))
            fail("cancel identity changed");
    end

    initial begin
        for(S_i=0;S_i<64;S_i=S_i+1) begin
            S_files[S_i]=0; S_audios[S_i]=0; S_titles[S_i]=0;
            S_durations[S_i]=10; S_effects[S_i]=0; S_times[S_i]=400;
        end
        repeat(4) @(negedge S_clk); S_reset=0;
        fixture;
        append("[GLOBAL]\norder=name\nbgm=AUD/BG.WAV\ninterval=8\ntransition=push\ntransition_ms=600\n");
        append("[ITEM]\nfile=IMG/b.BMP\ntitle=Bee\n[ITEM]\nfile=/a.BMP\naudio=/a.WAV\nduration=9\n");
        append("[ITEM]\nfile=/A.BMP\naudio=bad/../x\ntransition=wipe\ntitle=Alpha");
        expect_record(0,"/PLAY/IMG/b.BMP","/PLAY/AUD/BG.WAV","Bee",8,2,600);
        expect_record(1,"/a.BMP","/a.WAV","",9,2,600);
        expect_record(2,"/A.BMP","/PLAY/AUD/BG.WAV","Alpha",8,3,600);
        start; send_range(0,S_length); wait_without_retirement(3000);
        retire(S_tag^16'h0100,S_generation,0); retire(S_tag,S_generation^32'h00010000,0);
        wait_without_retirement(17); retire(S_tag,S_generation,0); done(0,3);
        if(S_warning!==8'h08) fail("parser warning not forwarded");
        acquire(3); check_record(0,1); check_record(1,2); check_record(2,0);

        // Copy into inactive bank while reading the retained old snapshot.
        fixture; append("[ITEM]\nfile=/new.BMP\naudio=/new.WAV\ntitle=New\n");
        expect_record(3,"/new.BMP","/new.WAV","New",10,0,400);
        start;
        fork
            begin send_range(0,S_length); end
            begin check_record(0,1); check_record(2,0); end
        join
        retire(S_tag,S_generation,0); done(0,1);
        if(S_start_ready || S_snapshot_count!=3 || S_snapshot_revision==S_revision) fail("retained bank was reused");
        check_record(1,2); release_snapshot;
        acquire(1); check_record(0,3); release_snapshot;

        // Source may retire immediately after delivering bytes, before parsing/copying finishes.
        fixture; append("[ITEM]\nfile=/one.BMP"); expect_record(4,"/one.BMP","","",10,0,400);
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,1); acquire(1); check_record(0,4); release_snapshot;
        fixture; append("[GLOBAL]\norder=list\n[ITEM]\nfile=/z\n[ITEM]\nfile=/a\n");
        expect_record(5,"/z","","",10,0,400); expect_record(6,"/a","","",10,0,400);
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,2);
        acquire(2); check_record(0,5); check_record(1,6); release_snapshot;

        // A pinned old bank backpressures the next start request; accepting it is atomic.
        acquire(2);
        fixture; append("[ITEM]\nfile=/pin-new.BMP\n"); expect_record(9,"/pin-new.BMP","","",10,0,400);
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,1);
        fixture; append("[ITEM]\nfile=/after-release.BMP\n"); expect_record(10,"/after-release.BMP","","",10,0,400);
        fork
            begin start; send_range(0,S_length); end
            begin
                repeat(19) begin @(negedge S_clk); if(S_start_ready || S_busy) fail("start accepted while target bank pinned"); end
                check_record(1,6); release_snapshot;
            end
        join
        retire(S_tag,S_generation,0); done(0,1); acquire(1); check_record(0,10); release_snapshot;
        // Restore the two-item baseline used by failure cases below.
        fixture; append("[ITEM]\nfile=/z\n[ITEM]\nfile=/a\n"); start; send_range(0,S_length);
        retire(S_tag,S_generation,0); done(0,2);
        fixture; append("[GLOBAL]\norder=list\n[ITEM]\nfile=/z\n[ITEM]\nfile=/a\n[GLOBAL]\norder=name\n");
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,2);
        acquire(2); check_record(0,6); check_record(1,5); release_snapshot;

        // Empty/invalid list requests fallback without discarding the valid old index.
        fixture; start; wait(S_cancel); wait_without_retirement(23); retire(S_tag,S_generation,0); done(5,0);
        if(S_active_count!=2) fail("empty list replaced active index");
        fixture; append("[ITEM]\ntitle=NO FILE\n"); start; send_range(0,S_length);
        retire(S_tag,S_generation,0); done(5,0); if(!S_warning[5]) fail("missing-file warning");
        fixture; append("[ITEM]\nfile=/valid\n[ITEM]\nfile=/later\n"); start;
        send_range(0,S_length); wait_without_retirement(2000);
        retire(S_tag,S_generation,8'h02); done(1,2);
        if(S_active_count!=2) fail("late source failure replaced active");

        // A successful but early retirement record is still a stream error.
        fixture; append("[ITEM]\nfile=/short\n"); start; send_range(0,4);
        retire(S_tag,S_generation,0); done(1,0);
        fixture; append("[ITEM]\nfile=/badlast\n"); S_last_mode=1; start; send_range(0,S_length);
        wait(S_cancel); wait_without_retirement(19); retire(S_tag,S_generation,1); done(1,0);
        fixture; append("[ITEM]\nfile=/nolast\n"); S_last_mode=2; start; send_range(0,S_length);
        retire(S_tag,S_generation,0); done(1,0);

        // Matching retirement and the final byte on the same edge include that byte.
        fixture; append("[ITEM]\nfile=/same-edge.BMP");
        expect_record(7,"/same-edge.BMP","","",10,0,400); start; send_range(0,S_length-1);
        @(negedge S_clk); while(!S_byte_ready) @(negedge S_clk);
        S_byte=S_bytes[S_length-1]; S_last=1; S_byte_tag=S_tag; S_byte_generation=S_generation; S_byte_valid=1;
        S_retire_valid=1; S_retire_tag=S_tag; S_retire_generation=S_generation; S_retire_error=0;
        // Both valid signals are first asserted together, before a single accepting edge.
        @(posedge S_clk); if(!S_byte_ready || !S_retire_ready) fail("same-edge stimulus readiness");
        @(negedge S_clk); S_byte_valid=0; S_retire_valid=0; S_retire_sent=1; S_retire_ok=1;
        done(0,1); acquire(1); check_record(0,7); release_snapshot;

        // Pulse abort while one string byte is buffered, then keep draining old bytes.
        fixture; append("[ITEM]\nfile=/abort-copy.BMP\n[ITEM]\nfile=/unused.BMP\n"); start;
        fork
            begin send_range(0,S_length); end
            begin
                wait(u_dut.S_state==5); @(negedge S_clk); S_abort=1;
                @(negedge S_clk); S_abort=0;
            end
        join
        wait(S_cancel); wait_without_retirement(23); retire(S_tag,S_generation,8'h08); done(2,0);
        fixture; append("[ITEM]\nfile=/input-abort.BMP\n"); start; send_range(0,3);
        @(negedge S_clk); S_abort=1; @(negedge S_clk); S_abort=0;
        wait(S_cancel); retire(S_tag,S_generation,8'h08); done(2,0);
        fixture; append("[ITEM]\nfile=/stream-error.BMP\n"); start; send_range(0,3);
        @(negedge S_clk); S_stream_error=1; @(negedge S_clk); S_stream_error=0;
        wait(S_cancel); retire(S_tag,S_generation,8'h02); done(1,0);

        // Late stream error after successful parsing still prevents commit while I/O is outstanding.
        fixture; append("[ITEM]\nfile=/late-error.BMP\n"); start; send_range(0,S_length);
        wait(u_dut.S_state==8); @(negedge S_clk); S_stream_error=1;
        @(negedge S_clk); S_stream_error=0; wait(S_cancel);
        retire(S_tag,S_generation,8'h02); done(1,1);

        fixture; append("[ITEM]\nfile=/lost.BMP\n"); start; send_range(0,3);
        @(negedge S_clk); S_media_valid=0; S_abort=1;
        @(negedge S_clk); S_media_valid=1; S_abort=0;
        wait(S_cancel); wait_without_retirement(31); retire(S_tag,S_generation,8'h01); done(3,0);
        if(S_active_valid) fail("short loss restored old active");
        fixture; append("[ITEM]\nfile=/generation.BMP\n"); start; send_range(0,3);
        @(negedge S_clk); S_media_generation=S_media_generation+1;
        // A record carrying the new generation must not release the old request.
        retire(S_tag,S_media_generation,0); wait_without_retirement(11);
        retire(S_tag,S_generation,1); done(3,0);

        // Full path/audio/title capacities are copied through real synchronous parser reads.
        fixture; append("[ITEM]\nfile=/");
        for(S_i=0;S_i<63;S_i=S_i+1) raw(8'h41);
        append("\naudio=/"); for(S_i=0;S_i<63;S_i=S_i+1) raw(8'h42);
        append("\ntitle="); for(S_i=0;S_i<38;S_i=S_i+1) raw(8'h54); raw(8'hd6); raw(8'hd0);
        expect_record(8,{8'h2f,{63{8'h41}}},{8'h2f,{63{8'h42}}},{{38{8'h54}},16'hd6d0},10,0,400);
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,1);
        acquire(1); check_record(0,8); release_snapshot;

        // Parser truncation warning and all 64 records survive the integrated path.
        fixture; append("[GLOBAL]\norder=name\n");
        for(S_i=65;S_i>=0;S_i=S_i-1) begin
            S_text=0; $sformat(S_text,"[ITEM]\nfile=/I%02d.BMP\nduration=%0d\n",S_i,S_i+1); append(S_text);
            if(S_i>=2) begin
                S_text=0; $sformat(S_text,"/I%02d.BMP",S_i);
                expect_record(65-S_i,S_text,"","",S_i+1,0,400);
            end
        end
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,64);
        if(!S_warning[6]) fail("64-item parser capacity warning lost");
        acquire(64); for(S_i=0;S_i<64;S_i=S_i+1) check_record(S_i,63-S_i); release_snapshot;

        // Integrated random order preserves records and the seed across repeated builds.
        for(S_j=0;S_j<2;S_j=S_j+1) begin
            fixture; append("[GLOBAL]\norder=random\n");
            for(S_i=0;S_i<8;S_i=S_i+1) begin
                S_text=0; $sformat(S_text,"[ITEM]\nfile=/R%0d.BMP\nduration=%0d\n",S_i,S_i+1); append(S_text);
                S_text=0; $sformat(S_text,"/R%0d.BMP",S_i); expect_record(S_i,S_text,"","",S_i+1,0,400);
            end
            S_seed=32'h09abcdef; start;
            // Accepted start metadata is a snapshot, regardless of later input changes.
            S_seed=S_j==0 ? 32'h1234abcd : 32'hfedc5678; S_size=S_j;
            send_range(0,S_length); retire(S_tag,S_generation,0); done(0,8); acquire(8); S_seen=0;
            for(S_i=0;S_i<8;S_i=S_i+1) begin
                read_request(S_i,0,0); wait(S_read_result); @(negedge S_clk); S_id=S_read_duration-1;
                if(S_id<0 || S_id>7 || S_seen[S_id]) fail("random candidate lost/duplicated"); S_seen[S_id]=1;
                if(S_j==0) S_first_shuffle[S_i]=S_id; else if(S_first_shuffle[S_i]!=S_id) fail("seed not captured/reproducible");
                read_accept(0); check_record(S_i,S_id);
            end
            if(S_seen!==64'hff) fail("random permutation incomplete"); release_snapshot;
        end

        // Cancel after sorting has begun but before matching source retirement.
        fixture; append("[GLOBAL]\norder=name\n[ITEM]\nfile=/z\n[ITEM]\nfile=/a\n"); start;
        send_range(0,S_length); wait(u_dut.S_state==8);
        @(negedge S_clk); S_abort=1; @(negedge S_clk); S_abort=0;
        wait(S_cancel); retire(S_tag,S_generation,8'h08); done(2,2);

        // Start-time abort and invalid media still require a real no-I/O retirement record.
        fixture;
        @(negedge S_clk); S_size=0; S_tag=S_case+16'h500; S_generation=S_media_generation;
        S_before_revision=S_revision; S_retire_sent=0; S_retire_ok=0; S_abort=1; S_start=1;
        @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
        @(negedge S_clk); S_start=0; S_abort=0;
        wait(S_cancel); wait_without_retirement(13); retire(S_tag,S_generation,8'h08); done(2,0);
        fixture;
        @(negedge S_clk); S_size=0; S_tag=S_case+16'h500; S_generation=S_media_generation;
        S_before_revision=S_revision; S_retire_sent=0; S_retire_ok=0; S_media_valid=0; S_start=1;
        @(posedge S_clk); while(!S_start_ready) @(posedge S_clk);
        @(negedge S_clk); S_start=0; S_media_valid=1;
        wait(S_cancel); retire(S_tag,S_generation,8'h01); done(3,0);

        // The commit edge is the success decision. Later abort/error cannot undo it.
        fixture; append("[ITEM]\nfile=/decided.BMP\n"); expect_record(0,"/decided.BMP","","",10,0,400);
        start; send_range(0,S_length); retire(S_tag,S_generation,0); wait(S_committed);
        @(negedge S_clk); S_abort=1; S_stream_error=1;
        repeat(2) @(negedge S_clk); S_abort=0; S_stream_error=0;
        done(0,1); acquire(1); check_record(0,0); release_snapshot;
        // Explicit global reset drops an unfinished owner; no normal retirement is claimed.
        fixture; append("[ITEM]\nfile=/reset.BMP\n"); start; send_range(0,4);
        @(negedge S_clk); S_reset=1; repeat(4) @(negedge S_clk); S_reset=0;
        if(S_busy || S_active_valid || S_snapshot_valid) fail("global reset ownership");
        fixture; append("[ITEM]\nfile=/fresh.BMP\n"); expect_record(0,"/fresh.BMP","","",10,0,400);
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,1); acquire(1); check_record(0,0); release_snapshot;
        // Runtime override freezes at start and supersedes an explicit file GLOBAL.
        fixture; append("[GLOBAL]\norder=name\norder=bad\n[ITEM]\nfile=/z.BMP\n[ITEM]\nfile=/a.BMP\n");
        expect_record(0,"/z.BMP","","",10,0,400); expect_record(1,"/a.BMP","","",10,0,400);
        S_order_override=1; S_runtime_order=1; start;
        S_order_override=0; S_runtime_order=0;
        send_range(0,S_length); retire(S_tag,S_generation,0); done(0,2);
        if(S_runtime_u_dut_O_active_order!=1 || S_runtime_u_dut_O_active_base_order!=0 ||
            !S_runtime_u_dut_O_active_base_order_explicit) fail("runtime/file order precedence, source or invalid repeat");
        acquire(2); check_record(0,0); check_record(1,1); release_snapshot;
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,2);
        if(S_runtime_u_dut_O_active_order!=0 || !S_runtime_u_dut_O_active_base_order_explicit) fail("explicit file order not used without runtime override");
        acquire(2); check_record(0,1); check_record(1,0); release_snapshot;
        fixture; append("[ITEM]\nfile=/z.BMP\n[ITEM]\nfile=/a.BMP\n");
        start; send_range(0,S_length); retire(S_tag,S_generation,0); done(0,2);
        if(S_runtime_u_dut_O_active_order!=1 || S_runtime_u_dut_O_active_base_order_explicit) fail("implicit list order source");
        acquire(2); check_record(0,0); check_record(1,1); release_snapshot;
        S_test_pass=1; $display("PASS: playlist_index_builder with runtime/GLOBAL order policy"); $finish;
    end
    initial begin #200000000; fail("watchdog timeout"); end
endmodule
