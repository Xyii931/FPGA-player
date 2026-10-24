`timescale 1ns/1ps
// Handwritten records and expected sort order; no filesystem or replacement RTL model.
module tb_media_index_store;
    reg S_clk=0,S_reset=1,S_media_valid=1;
    reg [31:0] S_media_generation=32'h12345678,S_generation=32'h12345678;
    reg [15:0] S_tag=0;
    reg S_begin=0,S_abort=0,S_item=0,S_string_valid=0,S_string_last=0;
    wire S_begin_ready,S_item_ready,S_string_ready,S_finish_ready,S_commit_ready,S_busy,S_done;
    reg [6:0] S_file_length=0,S_audio_length=0;
    reg [5:0] S_title_length=0;
    reg [9:0] S_duration=10,S_ms=400;
    reg [2:0] S_effect=0;
    reg [7:0] S_string_data=0;
    reg S_reorder=0,S_reorder_abort=0,S_reorder_take=0;
    reg [1:0] S_reorder_order=1;
    reg [31:0] S_reorder_seed=1,S_reorder_generation=32'h12345678;
    reg [15:0] S_reorder_tag=16'h7000;
    reg [5:0] S_reorder_index=0;
    reg S_owner_enable=0,S_owner_player_busy=0,S_owner_override=0;
    reg [1:0] S_owner_runtime=0;
    reg [5:0] S_owner_current=0;
    wire S_owner_hold,S_owner_busy,S_owner_request,S_owner_abort,S_owner_take,S_owner_applied,S_owner_discarded;
    wire [1:0] S_owner_order;
    wire [31:0] S_owner_seed,S_owner_generation,S_owner_applied_generation,S_owner_revision;
    wire [15:0] S_owner_tag;
    wire [5:0] S_owner_index,S_owner_applied_index;
    wire [3:0] S_owner_error;
    integer S_owner_applies=0,S_order_before=0,S_random_current=0;
    reg S_finish=0,S_commit=0,S_retired=0,S_done_ready=0;
    reg [1:0] S_order=1;
    reg [31:0] S_seed=1;
    wire [6:0] S_count,S_active_count,S_snapshot_count;
    wire [3:0] S_error,S_read_error;
    wire [15:0] S_out_tag;
    wire [31:0] S_out_generation,S_active_generation,S_revision,S_snapshot_generation,S_snapshot_revision;
    wire S_active_valid,S_acquire_ready,S_snapshot_valid,S_release_ready,S_read_ready,S_read_result;
    reg S_acquire=0,S_release=0,S_read=0,S_read_result_ready=0;
    reg [5:0] S_read_index=0;
    reg [1:0] S_read_kind=0;
    reg [6:0] S_read_address=0;
    reg [15:0] S_read_tag=0;
    wire [15:0] S_read_out_tag;
    wire [6:0] S_read_file_length,S_read_audio_length;
    wire [5:0] S_read_title_length;
    wire [9:0] S_read_duration,S_read_ms;
    wire [2:0] S_read_effect;
    wire [7:0] S_read_data;
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
media_index_store u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(S_media_valid),.I_media_generation(S_media_generation),
        .I_begin_valid(S_begin),.O_begin_ready(S_begin_ready),.I_tag(S_tag),.I_generation(S_generation),.I_abort(S_abort),
        .I_item_valid(S_item),.O_item_ready(S_item_ready),.I_file_length(S_file_length),.I_audio_length(S_audio_length),
        .I_title_length(S_title_length),.I_duration(S_duration),.I_transition_ms(S_ms),.I_transition(S_effect),
        .I_string_valid(S_string_valid),.O_string_ready(S_string_ready),.I_string_data(S_string_data),.I_string_last(S_string_last),
        .I_finish_valid(S_finish),.O_finish_ready(S_finish_ready),.I_order(S_order),.I_seed(S_seed),
        .I_commit_valid(S_commit),.I_source_retired(S_retired),.O_commit_ready(S_commit_ready),.O_busy(S_busy),
        .O_staged_count(S_count),.O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),
        .O_tag(S_out_tag),.O_generation(S_out_generation),.O_active_valid(S_active_valid),.O_active_count(S_active_count),
        .O_active_generation(S_active_generation),.O_active_revision(S_revision),.I_acquire_valid(S_acquire),
        .O_acquire_ready(S_acquire_ready),.O_snapshot_valid(S_snapshot_valid),.O_snapshot_count(S_snapshot_count),
        .O_snapshot_generation(S_snapshot_generation),.O_snapshot_revision(S_snapshot_revision),
        .I_release_valid(S_release),.O_release_ready(S_release_ready),.I_read_valid(S_read),.O_read_ready(S_read_ready),
        .I_read_index(S_read_index),.I_read_kind(S_read_kind),.I_read_address(S_read_address),
        .I_read_tag(S_read_tag),.O_read_tag(S_read_out_tag),
        .O_read_result_valid(S_read_result),.I_read_result_ready(S_read_result_ready),
        .O_read_file_length(S_read_file_length),.O_read_audio_length(S_read_audio_length),.O_read_title_length(S_read_title_length),
        .O_read_duration(S_read_duration),.O_read_transition_ms(S_read_ms),.O_read_transition(S_read_effect),
        .O_read_data(S_read_data),.O_read_error(S_read_error),
        .I_policy(7'h07),
        .O_read_policy(S_policy_u_dut_O_read_policy),
        .I_base_order(S_order),
        .I_base_order_explicit(1'b0),
        .O_active_order(S_runtime_u_dut_O_active_order),
        .O_active_base_order(S_runtime_u_dut_O_active_base_order),
        .O_active_base_order_explicit(S_runtime_u_dut_O_active_base_order_explicit),
        .I_reorder_valid(S_owner_enable ? S_owner_request : S_reorder),
        .O_reorder_ready(S_runtime_u_dut_O_reorder_ready),
        .I_reorder_order(S_owner_enable ? S_owner_order : S_reorder_order),
        .I_reorder_seed(S_owner_enable ? S_owner_seed : S_reorder_seed),
        .I_reorder_generation(S_owner_enable ? S_owner_generation : S_reorder_generation),
        .I_reorder_tag(S_owner_enable ? S_owner_tag : S_reorder_tag),
        .I_reorder_current_index(S_owner_enable ? S_owner_index : S_reorder_index),
        .I_reorder_abort(S_owner_enable ? S_owner_abort : S_reorder_abort),
        .O_reorder_done_valid(S_runtime_u_dut_O_reorder_done_valid),
        .I_reorder_done_ready(S_owner_enable ? S_owner_take : S_reorder_take),
        .O_reorder_error(S_runtime_u_dut_O_reorder_error),
        .O_reorder_tag(S_runtime_u_dut_O_reorder_tag),
        .O_reorder_generation(S_runtime_u_dut_O_reorder_generation),
        .O_reorder_revision(S_runtime_u_dut_O_reorder_revision),
        .O_reorder_current_index(S_runtime_u_dut_O_reorder_current_index)
    );
    wire [6:0] S_policy_u_dut_O_read_policy;
    player_order_ctrl u_order (
        .I_clk(S_clk),.I_reset(S_reset),.I_enable(S_owner_enable),.I_session_ready(S_media_valid),
        .I_media_valid(S_media_valid),.I_index_valid(S_active_valid),.I_player_busy(S_owner_player_busy),
        .I_media_generation(S_media_generation),.I_index_generation(S_active_generation),.I_index_revision(S_revision),
        .I_player_active(S_owner_enable),.I_player_generation(S_active_generation),.I_player_revision(S_revision),
        .I_active_order(S_runtime_u_dut_O_active_order),.I_base_order(S_runtime_u_dut_O_active_base_order),
        .I_runtime_order(S_owner_runtime),.I_order_override(S_owner_override),.I_current_index(S_owner_current),
        .O_hold_new(S_owner_hold),.O_busy(S_owner_busy),.O_reorder_valid(S_owner_request),
        .I_reorder_ready(S_runtime_u_dut_O_reorder_ready),.O_reorder_order(S_owner_order),
        .O_reorder_seed(S_owner_seed),.O_reorder_generation(S_owner_generation),.O_reorder_tag(S_owner_tag),
        .O_reorder_current_index(S_owner_index),.O_reorder_abort(S_owner_abort),
        .I_reorder_done_valid(S_runtime_u_dut_O_reorder_done_valid),.O_reorder_done_ready(S_owner_take),
        .I_reorder_error(S_runtime_u_dut_O_reorder_error),.I_reorder_tag(S_runtime_u_dut_O_reorder_tag),
        .I_reorder_generation(S_runtime_u_dut_O_reorder_generation),.I_reorder_revision(S_runtime_u_dut_O_reorder_revision),
        .I_reorder_current_index(S_runtime_u_dut_O_reorder_current_index),.O_applied(S_owner_applied),
        .O_applied_generation(S_owner_applied_generation),.O_applied_revision(S_owner_revision),.O_applied_index(S_owner_applied_index),
        .O_error(S_owner_error),.O_response_discarded(S_owner_discarded)
    );
    always @(posedge S_clk) if(!S_reset && S_owner_applied) begin
        S_owner_current<=S_owner_applied_index; S_owner_applies=S_owner_applies+1;
        if(!S_owner_hold || S_owner_revision!=S_revision || S_owner_applied_generation!=S_media_generation)
            fail("runtime controller did not preserve APPLY boundary or committed identity");
    end
    always #4 S_clk=~S_clk;
    reg [511:0] S_files[0:63],S_audios[0:63];
    reg [319:0] S_titles[0:63];
    integer S_map[0:63],S_random_map[0:63];
    reg [63:0] S_seen;
    reg [511:0] S_text;
    reg S_test_pass=0;
    integer S_case=0,S_i,S_j,S_k,S_old_revision;

    task fail;
        input [639:0] message;
        begin $display("FAIL: index store case %0d: %0s",S_case,message); $stop; end
    endtask
    function integer length;
        input [511:0] value;
        integer index;
        begin length=0; for(index=0;index<64;index=index+1) if(value[index*8+:8]!=0) length=index+1; end
    endfunction
    function integer effect_ms;
        input integer index;
        begin case(index%4) 0:effect_ms=200; 1:effect_ms=400; 2:effect_ms=600; 3:effect_ms=1000; endcase end
    endfunction
    task reset_all;
        begin
            @(negedge S_clk); S_reset=1; S_begin=0; S_item=0; S_string_valid=0; S_finish=0; S_commit=0;
            S_acquire=0; S_release=0; S_read=0; S_read_result_ready=0; S_done_ready=0; S_abort=0; S_retired=0;
            repeat(3) @(negedge S_clk);
            S_reset=0; @(negedge S_clk);
            if(S_busy || S_active_valid || S_snapshot_valid || S_read_result) fail("reset did not clear ownership");
        end
    endtask
    task begin_build;
        begin
            S_case=S_case+1;
            @(negedge S_clk); S_tag=S_case+16'h300; S_generation=S_media_generation; S_begin=1;
            @(posedge S_clk); while(!S_begin_ready) @(posedge S_clk);
            @(negedge S_clk); S_begin=0;
            if(S_count!=0 || !S_busy) fail("begin count/busy");
        end
    endtask
    task item_header;
        input integer file_length,audio_length,title_length,id;
        begin
            @(negedge S_clk); S_file_length=file_length; S_audio_length=audio_length; S_title_length=title_length;
            S_duration=id+1; S_effect=id%8; S_ms=effect_ms(id); S_item=1;
            @(posedge S_clk); while(!S_item_ready) @(posedge S_clk);
            @(negedge S_clk); S_item=0;
        end
    endtask
    task put_byte;
        input [7:0] value;
        input last;
        begin
            @(negedge S_clk); S_string_data=value; S_string_last=last; S_string_valid=1;
            @(posedge S_clk); while(!S_string_ready) @(posedge S_clk);
            @(negedge S_clk); S_string_valid=0;
        end
    endtask
    task append_record;
        input integer id;
        integer kind,address,bytes,total,sent;
        reg [511:0] value;
        begin
            total=length(S_files[id])+length(S_audios[id])+length({192'd0,S_titles[id]}); sent=0;
            item_header(length(S_files[id]),length(S_audios[id]),length({192'd0,S_titles[id]}),id);
            for(kind=0;kind<3;kind=kind+1) begin
                case(kind) 0:value=S_files[id]; 1:value=S_audios[id]; 2:value={192'd0,S_titles[id]}; endcase
                bytes=length(value);
                for(address=0;address<bytes;address=address+1) begin
                    sent=sent+1; put_byte(value[(bytes-1-address)*8+:8],sent==total);
                    if(address%3==0) repeat(2) @(negedge S_clk);
                end
            end
        end
    endtask
    task finish_build;
        input [1:0] order;
        input [31:0] seed;
        begin
            @(negedge S_clk); S_order=order; S_seed=seed; S_finish=1;
            @(posedge S_clk); while(!S_finish_ready) @(posedge S_clk);
            @(negedge S_clk); S_finish=0;
        end
    endtask
    task accept_done;
        input integer error,count;
        reg [127:0] held;
        begin
            wait(S_done); @(negedge S_clk);
            if(S_error!==error || S_count!==count || S_out_tag!==S_tag || S_out_generation!==S_generation)
                fail("done payload/identity");
            held={S_error,S_count,S_out_tag,S_out_generation};
            repeat(5) begin
                @(negedge S_clk);
                if(!S_done || !S_busy || S_begin_ready || held!=={S_error,S_count,S_out_tag,S_out_generation})
                    fail("done backpressure changed result");
            end
            S_done_ready=1; @(negedge S_clk); S_done_ready=0;
            if(S_busy || S_done) fail("done did not retire");
        end
    endtask
    task commit_build;
        input integer count;
        begin
            S_old_revision=S_revision;
            @(negedge S_clk); S_commit=1; S_retired=0;
            repeat(5) begin
                @(negedge S_clk);
                if(S_commit_ready || S_done || S_revision!=S_old_revision) fail("committed before source retirement");
            end
            S_retired=1;
            @(posedge S_clk); while(!S_commit_ready) @(posedge S_clk);
            @(negedge S_clk); S_commit=0; S_retired=0;
            if(!S_active_valid || S_active_count!=count || S_revision!=S_old_revision+1 || S_active_generation!=S_generation)
                fail("atomic commit metadata");
            accept_done(0,count);
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
                            S_read_duration!==id+1 || S_read_effect!==id%8 || S_read_ms!==effect_ms(id))
                        fail("record metadata/string no longer matches permutation");
                    read_accept(0);
                end
            end
        end
    endtask
    task abort_build;
        input integer count;
        begin
            @(negedge S_clk); S_abort=1;
            @(negedge S_clk); S_abort=0; accept_done(2,count);
        end
    endtask

    task reorder_start;
        input [1:0] order;
        input [31:0] seed;
        input [5:0] current;
        begin
            @(negedge S_clk); S_reorder_order=order; S_reorder_seed=seed; S_reorder_index=current;
            S_reorder_tag=S_reorder_tag+1'b1; S_reorder_generation=S_media_generation; S_reorder=1;
            S_order_before=S_revision;
            @(posedge S_clk); while(!S_runtime_u_dut_O_reorder_ready) @(posedge S_clk);
            @(negedge S_clk); S_reorder=0;
        end
    endtask
    task reorder_result;
        input integer error,current;
        reg [89:0] held;
        begin
            wait(S_runtime_u_dut_O_reorder_done_valid); @(negedge S_clk);
            if(S_done || S_runtime_u_dut_O_reorder_error!==error || S_runtime_u_dut_O_reorder_tag!==S_reorder_tag ||
                S_runtime_u_dut_O_reorder_generation!==S_media_generation ||
                S_revision!==(error==0 ? S_order_before+1 : S_order_before)) fail("runtime reorder terminal or revision");
            if(error==0 && S_runtime_u_dut_O_reorder_current_index!==current) fail("current physical item was not relocated");
            held={S_runtime_u_dut_O_reorder_error,S_runtime_u_dut_O_reorder_tag,
                S_runtime_u_dut_O_reorder_generation,S_runtime_u_dut_O_reorder_revision,S_runtime_u_dut_O_reorder_current_index};
            repeat(7) begin
                @(negedge S_clk);
                if(!S_runtime_u_dut_O_reorder_done_valid || held!=={S_runtime_u_dut_O_reorder_error,
                    S_runtime_u_dut_O_reorder_tag,S_runtime_u_dut_O_reorder_generation,
                    S_runtime_u_dut_O_reorder_revision,S_runtime_u_dut_O_reorder_current_index}) fail("held reorder result");
            end
            S_reorder_take=1; @(negedge S_clk); S_reorder_take=0;
            if(S_busy) fail("reorder result did not retire");
        end
    endtask

    initial begin
        for(S_i=0;S_i<64;S_i=S_i+1) begin S_files[S_i]=0; S_audios[S_i]=0; S_titles[S_i]=0; S_map[S_i]=S_i; end
        reset_all;
        if(S_acquire_ready || !S_begin_ready) fail("power-up readiness");
        S_files[0]="/OLD/B.BMP"; S_files[1]="/OLD/A.BMP";
        S_audios[0]="/OLD/B.WAV"; S_titles[0]="OLD B";
        begin_build; append_record(0); append_record(1); finish_build(1,1); commit_build(2);
        acquire(2); check_record(0,0); check_record(1,1);
        // Preserve the original fixture until the retained old snapshot has been read.
        begin_build;
        S_files[2]="/NEW.BMP"; S_audios[2]="/NEW.WAV"; S_titles[2]="NEW"; append_record(2);
        check_record(0,0); finish_build(1,1); commit_build(1);
        if(S_snapshot_count!=2 || S_snapshot_revision==S_revision || S_begin_ready) fail("old bank was not pinned");
        check_record(1,1);
        // A held begin request must remain blocked until the snapshot is explicitly released.
        @(negedge S_clk); S_begin=1; S_tag=16'h3ffe;
        repeat(6) begin @(negedge S_clk); if(S_begin_ready || S_busy) fail("reused pinned bank"); end
        S_begin=0; release_snapshot;
        acquire(1); check_record(0,2); release_snapshot;

        S_files[0]="/b"; S_files[1]="/A"; S_files[2]="/a";
        S_files[3]="/aa"; S_files[4]="/A/x"; S_files[5]="/AB";
        for(S_i=0;S_i<6;S_i=S_i+1) begin S_audios[S_i]=0; S_titles[S_i]="SORT"; end
        S_map[0]=1; S_map[1]=2; S_map[2]=4; S_map[3]=3; S_map[4]=5; S_map[5]=0;
        begin_build; for(S_i=0;S_i<6;S_i=S_i+1) append_record(S_i);
        finish_build(0,1); commit_build(6); acquire(6);
        for(S_i=0;S_i<6;S_i=S_i+1) check_record(S_i,S_map[S_i]);
        read_request(6,0,0); read_accept(7); read_request(0,3,0); read_accept(7);
        read_request(0,0,127); wait(S_read_result); @(negedge S_clk);
        if(S_read_data!==0) fail("out-of-range byte did not return zero"); read_accept(0);
        // Reorder while an old snapshot is retained: data bank stays shared, maps do not.
        reorder_start(1,1,0); check_record(0,1); reorder_result(0,1);
        if(S_snapshot_revision==S_revision || S_runtime_u_dut_O_active_order!=1) fail("snapshot retargeted during reorder");
        for(S_i=0;S_i<6;S_i=S_i+1) check_record(S_i,S_map[S_i]);
        reorder_start(0,1,1); reorder_result(0,0); check_record(5,0);
        release_snapshot; acquire(6);
        for(S_i=0;S_i<6;S_i=S_i+1) check_record(S_i,S_map[S_i]);
        reorder_start(2,32'h13572468,2);
        wait(S_runtime_u_dut_O_reorder_done_valid); S_random_current=S_runtime_u_dut_O_reorder_current_index;
        reorder_result(0,S_random_current); check_record(2,4);
        release_snapshot; acquire(6); S_seen=0;
        for(S_i=0;S_i<6;S_i=S_i+1) begin
            read_request(S_i,0,0); wait(S_read_result); @(negedge S_clk); S_k=S_read_duration-1;
            if(S_k<0 || S_k>=6 || S_seen[S_k]) fail("runtime random is not a bijection");
            S_random_map[S_i]=S_k; S_seen[S_k]=1; read_accept(0); check_record(S_i,S_k);
        end
        reorder_start(1,1,S_random_current); reorder_result(0,4);
        check_record(S_random_current,4);
        reorder_start(2,32'h13572468,4); reorder_result(0,S_random_current);
        release_snapshot; acquire(6);
        for(S_i=0;S_i<6;S_i=S_i+1) check_record(S_i,S_random_map[S_i]);
        reorder_start(0,1,0); @(negedge S_clk); S_reorder_abort=1;
        @(negedge S_clk); S_reorder_abort=0; reorder_result(2,0);
        check_record(0,S_random_map[0]);
        reorder_start(3,1,0); reorder_result(4,0);
        reorder_start(0,1,0); wait(S_runtime_u_dut_O_reorder_done_valid);
        reorder_result(0,S_random_map[0]==0 ? 5 : S_random_map[0]==1 ? 0 : S_random_map[0]==2 ? 1 :
            S_random_map[0]==3 ? 3 : S_random_map[0]==4 ? 2 : 4);
        release_snapshot; acquire(6);

        // Real runtime owner + real store; foreground work delays sorting, never aborts it.
        S_owner_current=0; S_owner_override=1; S_owner_runtime=0; S_owner_player_busy=1; S_owner_enable=1;
        repeat(20) @(negedge S_clk);
        if(!S_owner_hold || S_owner_request || S_busy || S_owner_applies!=0) fail("reorder overlapped foreground image transaction");
        S_owner_player_busy=0; wait(S_owner_applies==1); wait(!S_owner_busy);
        if(S_owner_current!=1 || S_runtime_u_dut_O_active_order!=1 || S_owner_error) fail("runtime LIST did not remap current item");
        check_record(0,1); // Snapshot still sees NAME, independent of new active LIST.
        S_owner_runtime=1; wait(S_owner_request); @(negedge S_clk); S_owner_runtime=0;
        wait(S_owner_applies==3); wait(!S_owner_busy);
        if(S_runtime_u_dut_O_active_order!=1 || S_owner_current!=1) fail("queued settings replaced frozen sort request");
        S_owner_override=0; wait(S_owner_applies==4); wait(!S_owner_busy);
        if(S_runtime_u_dut_O_active_order!=0 || S_owner_current!=0) fail("GLOBAL base order not restored");
        S_owner_enable=0; repeat(4) @(negedge S_clk);
        // Already published response remains stable over media invalidation.
        read_request(0,0,0); wait(S_read_result); @(negedge S_clk); S_media_valid=0;
        read_accept(0); @(negedge S_clk); S_media_valid=1;
        if(S_active_valid || S_acquire_ready) fail("media restored a retired active index");
        read_request(0,0,0); read_accept(3);
        release_snapshot;

        // Same-generation recovery needs a new commit; count zero is an explicit empty index.
        begin_build; finish_build(0,0); commit_build(0); acquire(0);
        read_request(0,0,0); read_accept(7); release_snapshot;
        begin_build; append_record(0); abort_build(1);
        if(!S_active_valid || S_active_count!=0) fail("abort replaced old index");
        begin_build; item_header(0,0,0,0); accept_done(4,0);
        begin_build; item_header(65,0,0,0); accept_done(4,0);
        begin_build; item_header(1,65,0,0); accept_done(4,0);
        begin_build; item_header(1,0,41,0); accept_done(4,0);
        begin_build; @(negedge S_clk); S_duration=0; S_item=1; S_file_length=1; S_audio_length=0; S_title_length=0;
        @(negedge S_clk); S_item=0; accept_done(4,0);
        begin_build; @(negedge S_clk); S_duration=601; S_ms=300; S_item=1;
        @(negedge S_clk); S_item=0; accept_done(4,0);
        begin_build; @(negedge S_clk); S_duration=1; S_ms=300; S_item=1;
        @(negedge S_clk); S_item=0; accept_done(4,0);
        begin_build; item_header(2,0,0,0); put_byte("/",1); accept_done(5,0);
        begin_build; item_header(1,0,0,0); put_byte("/",0); accept_done(5,0);
        begin_build; finish_build(3,0); accept_done(4,0);
        begin_build; item_header(2,0,0,0); put_byte("/",0); abort_build(0);
        begin_build; append_record(0); finish_build(0,0);
        @(negedge S_clk); S_retired=1; wait(S_commit_ready); abort_build(1); S_retired=0;

        // Full-sized strings, all 64 physical slots, and reverse input sorted by name.
        for(S_i=0;S_i<64;S_i=S_i+1) begin
            S_text=0; $sformat(S_text,"/%02d.BMP",S_i); S_files[S_i]=S_text;
            S_audios[S_i]="/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            S_titles[S_i]={38{8'h54}}; S_titles[S_i]=(S_titles[S_i]<<16)|16'hd6d0;
        end
        if(length(S_audios[0])!=64 || length({192'd0,S_titles[0]})!=40) fail("test fixture boundary");
        S_files[63]="/ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
        begin_build; for(S_i=63;S_i>=0;S_i=S_i-1) append_record(S_i);
        if(S_count!=64) fail("64 count wrapped");
        finish_build(0,0); commit_build(64); acquire(64);
        for(S_i=0;S_i<64;S_i=S_i+1) check_record(S_i,S_i);
        release_snapshot;
        // Comparison reaches byte 64 and leaves the long common prefix untouched.
        S_files[0]={8'h2f,{62{8'h41}},8'h62}; S_files[1]={8'h2f,{62{8'h61}},8'h61};
        begin_build; append_record(0); append_record(1); finish_build(0,1); commit_build(2); acquire(2);
        check_record(0,1); check_record(1,0); release_snapshot;
        begin_build; for(S_i=0;S_i<64;S_i=S_i+1) append_record(S_i);
        item_header(1,0,0,0); accept_done(6,64);
        if(S_active_count!=2) fail("capacity failure replaced active");
        begin_build; append_record(0); append_record(1); finish_build(0,1); abort_build(2);
        begin_build; append_record(0); append_record(1); finish_build(0,1);
        @(negedge S_clk); S_media_valid=0;
        @(negedge S_clk); S_media_valid=1; accept_done(3,2);

        // An explicitly stale begin is rejected without accepting item/string input.
        @(negedge S_clk); S_tag=16'h3ffd; S_generation=S_media_generation-1; S_begin=1;
        @(posedge S_clk); while(!S_begin_ready) @(posedge S_clk);
        @(negedge S_clk); S_begin=0; accept_done(3,0);

        // Shuffle: bijection, metadata identity, reproducibility, seed-zero fallback.
        for(S_j=0;S_j<3;S_j=S_j+1) begin
            begin_build; for(S_i=0;S_i<8;S_i=S_i+1) append_record(S_i);
            finish_build(2,S_j==0 ? 32'd0 : 32'd1); commit_build(8); acquire(8); S_seen=0;
            for(S_i=0;S_i<8;S_i=S_i+1) begin
                read_request(S_i,0,0); wait(S_read_result); @(negedge S_clk);
                S_k=S_read_duration-1;
                if(S_k<0 || S_k>=8 || S_seen[S_k]) fail("shuffle is not a permutation");
                S_seen[S_k]=1;
                if(S_j==0) S_random_map[S_i]=S_k;
                else if(S_random_map[S_i]!=S_k) fail("same seed did not reproduce order");
                read_accept(0); check_record(S_i,S_k);
            end
            if(S_seen!=64'hff) fail("shuffle omitted a record"); release_snapshot;
        end

        begin_build; for(S_i=0;S_i<64;S_i=S_i+1) append_record(S_i);
        finish_build(2,32'h7fedabcd); commit_build(64); acquire(64); S_seen=0;
        for(S_i=0;S_i<64;S_i=S_i+1) begin
            read_request(S_i,0,0); wait(S_read_result); @(negedge S_clk); S_k=S_read_duration-1;
            if(S_k<0 || S_k>=64 || S_seen[S_k]) fail("64-item shuffle permutation");
            S_seen[S_k]=1; read_accept(0); check_record(S_i,S_k);
            if(S_i==0) S_random_map[0]=S_k;
        end
        if(S_seen!==64'hffffffffffffffff) fail("64-item shuffle omitted a slot"); release_snapshot;

        // Acquire and commit on the same edge: lease is the pre-commit active index.
        begin_build; append_record(10); finish_build(1,1);
        @(negedge S_clk); S_retired=1; wait(S_commit_ready);
        @(negedge S_clk); S_old_revision=S_revision; S_acquire=1; S_commit=1;
        @(negedge S_clk); S_acquire=0; S_commit=0; S_retired=0;
        if(!S_snapshot_valid || S_snapshot_count!=64 || S_snapshot_revision!=S_old_revision) fail("acquire/commit ordering");
        accept_done(0,1); check_record(0,S_random_map[0]); release_snapshot;
        acquire(1); check_record(0,10);
        // Release wins over a simultaneous read command.
        @(negedge S_clk); S_release=1; S_read=1;
        #1; if(S_read_ready || !S_release_ready) fail("release priority");
        @(negedge S_clk); S_release=0; S_read=0;
        if(S_snapshot_valid || S_read_result) fail("read accepted while releasing");

        acquire(1); read_request(0,0,0);
        @(negedge S_clk); S_media_generation=S_media_generation+1;
        read_accept(3); read_request(0,0,0); read_accept(3);
        if(S_active_valid || S_acquire_ready) fail("stale generation remained visible");
        begin_build; append_record(1); finish_build(1,1); commit_build(1);
        if(S_begin_ready) fail("stale lease was implicitly released"); release_snapshot;
        acquire(1); check_record(0,1); release_snapshot;
        begin_build; item_header(2,0,0,0); put_byte("/",0);
        @(negedge S_clk); S_abort=1; S_media_valid=0;
        @(negedge S_clk); S_abort=0; S_media_valid=1; accept_done(3,0);
        if(S_active_valid) fail("short media loss restored active");
        begin_build; item_header(1,0,0,599); put_byte("/",1); finish_build(1,1); commit_build(1); acquire(1);
        read_request(0,0,0); wait(S_read_result); @(negedge S_clk);
        if(S_read_duration!==10'd600 || S_read_effect!==3'd7 || S_read_ms!==10'd1000 || S_read_data!==8'h2f)
            fail("maximum duration metadata");
        read_accept(0); release_snapshot;
        @(negedge S_clk); S_tag=16'h3ffc; S_generation=S_media_generation; S_begin=1; S_abort=1;
        @(posedge S_clk); while(!S_begin_ready) @(posedge S_clk);
        @(negedge S_clk); S_begin=0; S_abort=0; accept_done(2,0);
        // A published terminal is not rewritten by later loss or abort.
        begin_build; @(negedge S_clk); S_abort=1; @(negedge S_clk); S_abort=0; wait(S_done);
        @(negedge S_clk); S_media_valid=0; S_abort=1; accept_done(2,0);
        S_abort=0; S_media_valid=1;
        begin_build; item_header(3,0,0,0); put_byte("/",0); reset_all;
        begin_build; append_record(0); finish_build(2,32'hbeef); commit_build(1); acquire(1); check_record(0,0);
        release_snapshot; S_test_pass=1; $display("PASS: media_index_store"); $finish;
    end
    initial begin #100000000; fail("watchdog timeout"); end
endmodule
