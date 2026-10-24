`timescale 1ns/1ps
// Real two-bank index and real item-copy owner, no FAT/files/media model.
module tb_media_item_fetch;
    reg S_clk=0,S_reset=1,S_media_valid=1;
    reg [31:0] S_generation=7;
    always #4 S_clk=~S_clk;
    reg S_test_pass=0;
    reg S_f_I_start_valid=0;
    wire S_f_O_start_ready;
    reg [5:0] S_f_I_index=0;
    reg [15:0] S_f_I_tag=0;
    reg [31:0] S_f_I_revision=0;
    reg S_f_I_abort=0;
    wire S_f_O_busy;
    wire S_f_O_done_valid;
    reg S_f_I_done_ready=0;
    wire [3:0] S_f_O_error;
    wire [5:0] S_f_O_index;
    wire [15:0] S_f_O_tag;
    wire [31:0] S_f_O_generation;
    wire [31:0] S_f_O_revision;
    wire [6:0] S_f_O_count;
    wire [6:0] S_f_O_file_length;
    wire [6:0] S_f_O_audio_length;
    wire [5:0] S_f_O_title_length;
    wire [9:0] S_f_O_duration;
    wire [9:0] S_f_O_transition_ms;
    wire [2:0] S_f_O_transition;
    reg [1:0] S_f_I_string_kind=0;
    reg [6:0] S_f_I_string_address=0;
    wire [7:0] S_f_O_string_data;
    wire S_f_O_acquire_valid;
    wire S_f_O_release_valid;
    wire S_f_O_read_valid;
    wire [5:0] S_f_O_read_index;
    wire [1:0] S_f_O_read_kind;
    wire [6:0] S_f_O_read_address;
    wire [15:0] S_f_O_read_tag;
    wire S_f_O_read_result_ready;
    wire S_f_O_response_discarded;
    media_item_fetch u_f (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_start_valid(S_f_I_start_valid),
        .O_start_ready(S_f_O_start_ready),
        .I_index(S_f_I_index),
        .I_tag(S_f_I_tag),
        .I_revision(S_f_I_revision),
        .I_abort(S_f_I_abort),
        .O_busy(S_f_O_busy),
        .O_done_valid(S_f_O_done_valid),
        .I_done_ready(S_f_I_done_ready),
        .O_error(S_f_O_error),
        .O_index(S_f_O_index),
        .O_tag(S_f_O_tag),
        .O_generation(S_f_O_generation),
        .O_revision(S_f_O_revision),
        .O_count(S_f_O_count),
        .O_file_length(S_f_O_file_length),
        .O_audio_length(S_f_O_audio_length),
        .O_title_length(S_f_O_title_length),
        .O_duration(S_f_O_duration),
        .O_transition_ms(S_f_O_transition_ms),
        .O_transition(S_f_O_transition),
        .I_string_kind(S_f_I_string_kind),
        .I_string_address(S_f_I_string_address),
        .O_string_data(S_f_O_string_data),
        .O_acquire_valid(S_f_O_acquire_valid),
        .I_acquire_ready(S_s_O_acquire_ready),
        .I_snapshot_valid(S_s_O_snapshot_valid),
        .I_snapshot_count(S_s_O_snapshot_count),
        .I_snapshot_generation(S_s_O_snapshot_generation),
        .I_snapshot_revision(S_s_O_snapshot_revision),
        .O_release_valid(S_f_O_release_valid),
        .I_release_ready(S_s_O_release_ready),
        .O_read_valid(S_f_O_read_valid),
        .I_read_ready(S_s_O_read_ready),
        .O_read_index(S_f_O_read_index),
        .O_read_kind(S_f_O_read_kind),
        .O_read_address(S_f_O_read_address),
        .O_read_tag(S_f_O_read_tag),
        .I_read_result_valid(S_s_O_read_result_valid),
        .O_read_result_ready(S_f_O_read_result_ready),
        .I_read_file_length(S_s_O_read_file_length),
        .I_read_audio_length(S_s_O_read_audio_length),
        .I_read_title_length(S_s_O_read_title_length),
        .I_read_duration(S_s_O_read_duration),
        .I_read_transition_ms(S_s_O_read_transition_ms),
        .I_read_transition(S_s_O_read_transition),
        .I_read_data(S_s_O_read_data),
        .I_read_tag(S_s_O_read_tag),
        .I_read_error(S_s_O_read_error),
        .O_response_discarded(S_f_O_response_discarded),
        .I_read_policy(S_policy_u_s_O_read_policy),
        .O_policy(S_policy_u_f_O_policy)
    );
    wire [6:0] S_policy_u_s_O_read_policy;
    wire [6:0] S_policy_u_f_O_policy;
    reg S_s_I_begin_valid=0;
    wire S_s_O_begin_ready;
    reg [15:0] S_s_I_tag=0;
    reg [31:0] S_s_I_generation=0;
    reg S_s_I_abort=0;
    reg S_s_I_item_valid=0;
    wire S_s_O_item_ready;
    reg [6:0] S_s_I_file_length=0;
    reg [6:0] S_s_I_audio_length=0;
    reg [5:0] S_s_I_title_length=0;
    reg [9:0] S_s_I_duration=0;
    reg [9:0] S_s_I_transition_ms=0;
    reg [2:0] S_s_I_transition=0;
    reg S_s_I_string_valid=0;
    wire S_s_O_string_ready;
    reg [7:0] S_s_I_string_data=0;
    reg S_s_I_string_last=0;
    reg S_s_I_finish_valid=0;
    wire S_s_O_finish_ready;
    reg [1:0] S_s_I_order=0;
    reg [31:0] S_s_I_seed=0;
    reg S_s_I_commit_valid=0;
    reg S_s_I_source_retired=0;
    wire S_s_O_commit_ready;
    wire S_s_O_busy;
    wire [6:0] S_s_O_staged_count;
    wire S_s_O_done_valid;
    reg S_s_I_done_ready=0;
    wire [3:0] S_s_O_error;
    wire [15:0] S_s_O_tag;
    wire [31:0] S_s_O_generation;
    wire S_s_O_active_valid;
    wire [6:0] S_s_O_active_count;
    wire [31:0] S_s_O_active_generation;
    wire [31:0] S_s_O_active_revision;
    wire S_s_O_acquire_ready;
    wire S_s_O_snapshot_valid;
    wire [6:0] S_s_O_snapshot_count;
    wire [31:0] S_s_O_snapshot_generation;
    wire [31:0] S_s_O_snapshot_revision;
    wire S_s_O_release_ready;
    wire S_s_O_read_ready;
    wire S_s_O_read_result_valid;
    wire [6:0] S_s_O_read_file_length;
    wire [6:0] S_s_O_read_audio_length;
    wire [5:0] S_s_O_read_title_length;
    wire [9:0] S_s_O_read_duration;
    wire [9:0] S_s_O_read_transition_ms;
    wire [2:0] S_s_O_read_transition;
    wire [7:0] S_s_O_read_data;
    wire [15:0] S_s_O_read_tag;
    wire [3:0] S_s_O_read_error;
        wire [1:0] S_runtime_u_s_O_active_order;
    wire [1:0] S_runtime_u_s_O_active_base_order;
    wire S_runtime_u_s_O_active_base_order_explicit;
    wire S_runtime_u_s_O_reorder_ready;
    wire S_runtime_u_s_O_reorder_done_valid;
    wire [3:0] S_runtime_u_s_O_reorder_error;
    wire [15:0] S_runtime_u_s_O_reorder_tag;
    wire [31:0] S_runtime_u_s_O_reorder_generation;
    wire [31:0] S_runtime_u_s_O_reorder_revision;
    wire [5:0] S_runtime_u_s_O_reorder_current_index;
media_index_store u_s (
        .I_clk(S_clk),
        .I_reset(S_reset),
        .I_media_valid(S_media_valid),
        .I_media_generation(S_generation),
        .I_begin_valid(S_s_I_begin_valid),
        .O_begin_ready(S_s_O_begin_ready),
        .I_tag(S_s_I_tag),
        .I_generation(S_s_I_generation),
        .I_abort(S_s_I_abort),
        .I_item_valid(S_s_I_item_valid),
        .O_item_ready(S_s_O_item_ready),
        .I_file_length(S_s_I_file_length),
        .I_audio_length(S_s_I_audio_length),
        .I_title_length(S_s_I_title_length),
        .I_duration(S_s_I_duration),
        .I_transition_ms(S_s_I_transition_ms),
        .I_transition(S_s_I_transition),
        .I_string_valid(S_s_I_string_valid),
        .O_string_ready(S_s_O_string_ready),
        .I_string_data(S_s_I_string_data),
        .I_string_last(S_s_I_string_last),
        .I_finish_valid(S_s_I_finish_valid),
        .O_finish_ready(S_s_O_finish_ready),
        .I_order(S_s_I_order),
        .I_seed(S_s_I_seed),
        .I_commit_valid(S_s_I_commit_valid),
        .I_source_retired(S_s_I_source_retired),
        .O_commit_ready(S_s_O_commit_ready),
        .O_busy(S_s_O_busy),
        .O_staged_count(S_s_O_staged_count),
        .O_done_valid(S_s_O_done_valid),
        .I_done_ready(S_s_I_done_ready),
        .O_error(S_s_O_error),
        .O_tag(S_s_O_tag),
        .O_generation(S_s_O_generation),
        .O_active_valid(S_s_O_active_valid),
        .O_active_count(S_s_O_active_count),
        .O_active_generation(S_s_O_active_generation),
        .O_active_revision(S_s_O_active_revision),
        .I_acquire_valid(S_f_O_acquire_valid),
        .O_acquire_ready(S_s_O_acquire_ready),
        .O_snapshot_valid(S_s_O_snapshot_valid),
        .O_snapshot_count(S_s_O_snapshot_count),
        .O_snapshot_generation(S_s_O_snapshot_generation),
        .O_snapshot_revision(S_s_O_snapshot_revision),
        .I_release_valid(S_f_O_release_valid),
        .O_release_ready(S_s_O_release_ready),
        .I_read_valid(S_f_O_read_valid),
        .O_read_ready(S_s_O_read_ready),
        .I_read_index(S_f_O_read_index),
        .I_read_kind(S_f_O_read_kind),
        .I_read_address(S_f_O_read_address),
        .I_read_tag(S_f_O_read_tag),
        .O_read_result_valid(S_s_O_read_result_valid),
        .I_read_result_ready(S_f_O_read_result_ready),
        .O_read_file_length(S_s_O_read_file_length),
        .O_read_audio_length(S_s_O_read_audio_length),
        .O_read_title_length(S_s_O_read_title_length),
        .O_read_duration(S_s_O_read_duration),
        .O_read_transition_ms(S_s_O_read_transition_ms),
        .O_read_transition(S_s_O_read_transition),
        .O_read_data(S_s_O_read_data),
        .O_read_tag(S_s_O_read_tag),
        .O_read_error(S_s_O_read_error),
        .I_policy(7'h07),
        .O_read_policy(S_policy_u_s_O_read_policy),
        .I_base_order(2'd0),
        .I_base_order_explicit(1'b0),
        .O_active_order(S_runtime_u_s_O_active_order),
        .O_active_base_order(S_runtime_u_s_O_active_base_order),
        .O_active_base_order_explicit(S_runtime_u_s_O_active_base_order_explicit),
        .I_reorder_valid(1'b0),
        .O_reorder_ready(S_runtime_u_s_O_reorder_ready),
        .I_reorder_order(2'd0),
        .I_reorder_seed(32'd0),
        .I_reorder_generation(32'd0),
        .I_reorder_tag(16'd0),
        .I_reorder_current_index(6'd0),
        .I_reorder_abort(1'b0),
        .O_reorder_done_valid(S_runtime_u_s_O_reorder_done_valid),
        .I_reorder_done_ready(1'b0),
        .O_reorder_error(S_runtime_u_s_O_reorder_error),
        .O_reorder_tag(S_runtime_u_s_O_reorder_tag),
        .O_reorder_generation(S_runtime_u_s_O_reorder_generation),
        .O_reorder_revision(S_runtime_u_s_O_reorder_revision),
        .O_reorder_current_index(S_runtime_u_s_O_reorder_current_index)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL media_item_fetch: %0s",message); $finish; end
    endtask
    task string_byte;
        input [7:0] data;
        input last;
        begin
            @(negedge S_clk); S_s_I_string_valid=1; S_s_I_string_data=data; S_s_I_string_last=last;
            while(!S_s_O_string_ready) @(negedge S_clk);
            @(negedge S_clk); S_s_I_string_valid=0;
        end
    endtask
    task start_fetch;
        input [5:0] index;
        begin
            @(negedge S_clk); S_f_I_index=index; S_f_I_tag=16'h1234; S_f_I_start_valid=1;
            while(!S_f_O_start_ready) @(negedge S_clk);
            @(negedge S_clk); S_f_I_start_valid=0;
        end
    endtask
    task consume_fetch;
        begin
            wait(S_f_O_done_valid);
            if(S_s_O_snapshot_valid || S_s_O_read_result_valid) fail("published before actual snapshot release");
            @(negedge S_clk); S_f_I_done_ready=1;
            @(negedge S_clk); S_f_I_done_ready=0;
        end
    endtask
    task check_byte;
        input [1:0] kind;
        input [6:0] address;
        input [7:0] expected;
        begin
            @(negedge S_clk); S_f_I_string_kind=kind; S_f_I_string_address=address;
            @(posedge S_clk); #1;
            if(S_f_O_string_data!==expected) fail("copied string / synchronous read / retained buffer incorrect");
        end
    endtask
    initial begin
        #41; S_reset=0;
        @(negedge S_clk); S_s_I_generation=7; S_s_I_tag=5; S_s_I_begin_valid=1;
        while(!S_s_O_begin_ready) @(negedge S_clk);
        @(negedge S_clk); S_s_I_begin_valid=0;
        S_s_I_file_length=3; S_s_I_audio_length=2; S_s_I_title_length=1;
        S_s_I_duration=10; S_s_I_transition_ms=200; S_s_I_item_valid=1;
        while(!S_s_O_item_ready) @(negedge S_clk);
        @(negedge S_clk); S_s_I_item_valid=0;
        string_byte("a",0); string_byte(".",0); string_byte("b",0);
        string_byte("x",0); string_byte("y",0); string_byte("T",1);
        @(negedge S_clk); S_s_I_finish_valid=1;
        while(!S_s_O_finish_ready) @(negedge S_clk);
        @(negedge S_clk); S_s_I_finish_valid=0; S_s_I_source_retired=1; S_s_I_commit_valid=1;
        while(!S_s_O_commit_ready) @(negedge S_clk);
        @(negedge S_clk); S_s_I_commit_valid=0;
        wait(S_s_O_done_valid); @(negedge S_clk); S_s_I_done_ready=1;
        @(negedge S_clk); S_s_I_done_ready=0;
        start_fetch(0); wait(S_f_O_done_valid);
        if(S_f_O_error || S_f_O_count!=1 || S_f_O_file_length!=3 ||
            S_f_O_audio_length!=2 || S_f_O_title_length!=1 || S_f_O_generation!=7 || S_f_O_revision!=1 ||
            S_policy_u_f_O_policy!=7'h07)
            fail("metadata/identity not copied");
        repeat(12) @(negedge S_clk);
        if(!S_f_O_done_valid || S_s_O_snapshot_valid) fail("result backpressure retained index bank");
        consume_fetch;
        check_byte(0,0,"a"); check_byte(0,1,"."); check_byte(0,2,"b");
        check_byte(1,0,"x"); check_byte(1,1,"y"); check_byte(2,0,"T"); check_byte(3,0,0);
        start_fetch(63); wait(S_f_O_done_valid);
        if(S_f_O_error!=1) fail("invalid item not rejected"); consume_fetch;
        start_fetch(0);
        wait(S_f_O_read_valid && S_s_O_read_ready);
        @(negedge S_clk); S_media_valid=0;
        wait(S_f_O_done_valid);
        if(S_f_O_error!=3) fail("media removal did not invalidate copy");
        S_media_valid=1; repeat(8) @(negedge S_clk);
        if(S_f_O_error!=3 || S_s_O_snapshot_valid) fail("media recovery resurrected old snapshot");
        consume_fetch;
        S_test_pass=1; $display("PASS media_item_fetch with real media_index_store; no FAT/media behavior simulated"); $finish;
    end
    initial begin #1000000; fail("timeout"); end
endmodule
