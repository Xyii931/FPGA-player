`timescale 1ns/1ps
// Real source + parser + store; FAT32 protocol endpoints are explicit stimulus.
// This case checks adverse routing/retirement, not FAT geometry or actual SD I/O.
module tb_playlist_file_source;
    reg S_allow_build=1,S_allow_byte=1,S_allow_retire=0,S_builder_done_ready=0;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    reg  S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg  S_I_start_valid=0;
    wire  S_O_start_ready;
    wire  S_O_lease_request;
    reg  S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_seed=0;
    reg [31:0] S_I_sector_budget=0;
    reg  S_I_abort=0;
    wire  S_O_lease_active;
    wire  S_O_busy;
    wire  S_O_done_valid;
    reg  S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [7:0] S_O_file_error;
    wire [3:0] S_O_storage_error;
    wire [2:0] S_O_path_warning;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_file_size;
    wire  S_O_builder_started;
    wire  S_O_missing;
    wire  S_O_build_start_valid;
    reg  S_I_build_start_ready=0;
    wire [31:0] S_O_build_file_size;
    wire [31:0] S_O_build_generation;
    wire [31:0] S_O_build_seed;
    wire [15:0] S_O_build_tag;
    wire  S_O_build_byte_valid;
    reg  S_I_build_byte_ready=0;
    wire [7:0] S_O_build_byte_data;
    wire  S_O_build_byte_last;
    wire [15:0] S_O_build_byte_tag;
    wire [31:0] S_O_build_byte_generation;
    wire  S_O_build_retire_valid;
    reg  S_I_build_retire_ready=0;
    wire [15:0] S_O_build_retire_tag;
    wire [31:0] S_O_build_retire_generation;
    wire [7:0] S_O_build_retire_error;
    wire  S_O_build_stream_error;
    reg  S_I_build_cancel=0;
    reg [15:0] S_I_build_cancel_tag=0;
    reg [31:0] S_I_build_cancel_generation=0;
    wire  S_O_fs_open_valid;
    reg  S_I_fs_open_ready=0;
    wire [1:0] S_O_fs_open_context;
    wire [15:0] S_O_fs_open_tag;
    wire [6:0] S_O_fs_path_length;
    wire [31:0] S_O_fs_sector_budget;
    wire  S_O_fs_path_valid;
    reg  S_I_fs_path_ready=0;
    wire [7:0] S_O_fs_path_data;
    wire  S_O_fs_path_last;
    wire  S_O_fs_open_cancel;
    reg  S_I_fs_open_result_valid=0;
    wire  S_O_fs_open_result_ready;
    reg [1:0] S_I_fs_open_context=0;
    reg [15:0] S_I_fs_open_tag=0;
    reg [31:0] S_I_fs_open_generation=0;
    reg [31:0] S_I_fs_open_size=0;
    reg [7:0] S_I_fs_open_error=0;
    reg [3:0] S_I_fs_open_storage_error=0;
    reg [2:0] S_I_fs_open_warning=0;
    wire  S_O_fs_read_valid;
    reg  S_I_fs_read_ready=0;
    wire [1:0] S_O_fs_read_context;
    wire [1:0] S_O_fs_read_priority;
    wire [31:0] S_O_fs_offset;
    wire [31:0] S_O_fs_length;
    wire [15:0] S_O_fs_epoch;
    reg  S_I_fs_byte_valid=0;
    wire  S_O_fs_byte_ready;
    reg [7:0] S_I_fs_byte_data=0;
    reg [1:0] S_I_fs_byte_context=0;
    reg [15:0] S_I_fs_byte_epoch=0;
    reg [31:0] S_I_fs_byte_generation=0;
    reg [31:0] S_I_fs_byte_offset=0;
    reg  S_I_fs_byte_last=0;
    reg  S_I_fs_done_valid=0;
    wire  S_O_fs_done_ready;
    reg [1:0] S_I_fs_done_context=0;
    reg [15:0] S_I_fs_done_epoch=0;
    reg [31:0] S_I_fs_done_generation=0;
    reg [31:0] S_I_fs_done_bytes=0;
    reg  S_I_fs_done_eof=0;
    reg [7:0] S_I_fs_done_error=0;
    reg [3:0] S_I_fs_done_storage_error=0;
    wire  S_O_fs_cancel_valid;
    reg  S_I_fs_cancel_ready=0;
    wire [1:0] S_O_fs_cancel_context;
    wire [15:0] S_O_fs_cancel_epoch;
    reg  S_I_fs_cancel_done_valid=0;
    wire  S_O_fs_cancel_done_ready;
    reg [1:0] S_I_fs_cancel_done_context=0;
    reg [15:0] S_I_fs_cancel_done_epoch=0;
    reg [31:0] S_I_fs_cancel_done_generation=0;
    wire  S_O_fs_close_valid;
    reg  S_I_fs_close_ready=0;
    wire [1:0] S_O_fs_close_context;
    playlist_file_source u_source (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_seed(S_I_seed),
        .I_sector_budget(S_I_sector_budget),
        .I_abort(S_I_abort),
        .O_lease_active(S_O_lease_active),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_file_error(S_O_file_error),
        .O_storage_error(S_O_storage_error),
        .O_path_warning(S_O_path_warning),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_file_size(S_O_file_size),
        .O_builder_started(S_O_builder_started),
        .O_missing(S_O_missing),
        .O_build_start_valid(S_O_build_start_valid),
        .I_build_start_ready(S_I_build_start_ready),
        .O_build_file_size(S_O_build_file_size),
        .O_build_generation(S_O_build_generation),
        .O_build_seed(S_O_build_seed),
        .O_build_tag(S_O_build_tag),
        .O_build_byte_valid(S_O_build_byte_valid),
        .I_build_byte_ready(S_I_build_byte_ready),
        .O_build_byte_data(S_O_build_byte_data),
        .O_build_byte_last(S_O_build_byte_last),
        .O_build_byte_tag(S_O_build_byte_tag),
        .O_build_byte_generation(S_O_build_byte_generation),
        .O_build_retire_valid(S_O_build_retire_valid),
        .I_build_retire_ready(S_I_build_retire_ready),
        .O_build_retire_tag(S_O_build_retire_tag),
        .O_build_retire_generation(S_O_build_retire_generation),
        .O_build_retire_error(S_O_build_retire_error),
        .O_build_stream_error(S_O_build_stream_error),
        .I_build_cancel(S_I_build_cancel),
        .I_build_cancel_tag(S_I_build_cancel_tag),
        .I_build_cancel_generation(S_I_build_cancel_generation),
        .O_fs_open_valid(S_O_fs_open_valid),
        .I_fs_open_ready(S_I_fs_open_ready),
        .O_fs_open_context(S_O_fs_open_context),
        .O_fs_open_tag(S_O_fs_open_tag),
        .O_fs_path_length(S_O_fs_path_length),
        .O_fs_sector_budget(S_O_fs_sector_budget),
        .O_fs_path_valid(S_O_fs_path_valid),
        .I_fs_path_ready(S_I_fs_path_ready),
        .O_fs_path_data(S_O_fs_path_data),
        .O_fs_path_last(S_O_fs_path_last),
        .O_fs_open_cancel(S_O_fs_open_cancel),
        .I_fs_open_result_valid(S_I_fs_open_result_valid),
        .O_fs_open_result_ready(S_O_fs_open_result_ready),
        .I_fs_open_context(S_I_fs_open_context),
        .I_fs_open_tag(S_I_fs_open_tag),
        .I_fs_open_generation(S_I_fs_open_generation),
        .I_fs_open_size(S_I_fs_open_size),
        .I_fs_open_error(S_I_fs_open_error),
        .I_fs_open_storage_error(S_I_fs_open_storage_error),
        .I_fs_open_warning(S_I_fs_open_warning),
        .O_fs_read_valid(S_O_fs_read_valid),
        .I_fs_read_ready(S_I_fs_read_ready),
        .O_fs_read_context(S_O_fs_read_context),
        .O_fs_read_priority(S_O_fs_read_priority),
        .O_fs_offset(S_O_fs_offset),
        .O_fs_length(S_O_fs_length),
        .O_fs_epoch(S_O_fs_epoch),
        .I_fs_byte_valid(S_I_fs_byte_valid),
        .O_fs_byte_ready(S_O_fs_byte_ready),
        .I_fs_byte_data(S_I_fs_byte_data),
        .I_fs_byte_context(S_I_fs_byte_context),
        .I_fs_byte_epoch(S_I_fs_byte_epoch),
        .I_fs_byte_generation(S_I_fs_byte_generation),
        .I_fs_byte_offset(S_I_fs_byte_offset),
        .I_fs_byte_last(S_I_fs_byte_last),
        .I_fs_done_valid(S_I_fs_done_valid),
        .O_fs_done_ready(S_O_fs_done_ready),
        .I_fs_done_context(S_I_fs_done_context),
        .I_fs_done_epoch(S_I_fs_done_epoch),
        .I_fs_done_generation(S_I_fs_done_generation),
        .I_fs_done_bytes(S_I_fs_done_bytes),
        .I_fs_done_eof(S_I_fs_done_eof),
        .I_fs_done_error(S_I_fs_done_error),
        .I_fs_done_storage_error(S_I_fs_done_storage_error),
        .O_fs_cancel_valid(S_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_I_fs_cancel_ready),
        .O_fs_cancel_context(S_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(S_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(S_I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(S_I_fs_cancel_done_generation),
        .O_fs_close_valid(S_O_fs_close_valid),
        .I_fs_close_ready(S_I_fs_close_ready),
        .O_fs_close_context(S_O_fs_close_context)
    );
    wire [6:0] S_policy_u_builder_O_read_policy;
    wire  S_B_O_start_ready;
    wire  S_B_O_byte_ready;
    wire  S_B_O_retire_ready;
    wire  S_B_O_source_cancel;
    wire [15:0] S_B_O_source_tag;
    wire [31:0] S_B_O_source_generation;
    wire  S_B_O_busy;
    wire  S_B_O_done_valid;
    wire [3:0] S_B_O_error;
    wire [7:0] S_B_O_warning;
    wire [6:0] S_B_O_count;
    wire [15:0] S_B_O_tag;
    wire [31:0] S_B_O_generation;
    wire  S_B_O_committed;
    wire  S_B_O_fallback_required;
    wire  S_B_O_active_valid;
    wire [6:0] S_B_O_active_count;
    wire [31:0] S_B_O_active_generation;
    wire [31:0] S_B_O_active_revision;
    wire  S_B_O_acquire_ready;
    wire  S_B_O_snapshot_valid;
    wire [6:0] S_B_O_snapshot_count;
    wire [31:0] S_B_O_snapshot_generation;
    wire [31:0] S_B_O_snapshot_revision;
    wire  S_B_O_release_ready;
    wire  S_B_O_read_ready;
    wire  S_B_O_read_result_valid;
    wire [6:0] S_B_O_read_file_length;
    wire [6:0] S_B_O_read_audio_length;
    wire [5:0] S_B_O_read_title_length;
    wire [9:0] S_B_O_read_duration;
    wire [9:0] S_B_O_read_transition_ms;
    wire [2:0] S_B_O_read_transition;
    wire [7:0] S_B_O_read_data;
    wire [15:0] S_B_O_read_tag;
    wire [3:0] S_B_O_read_error;
        wire [1:0] S_runtime_u_builder_O_active_order;
    wire [1:0] S_runtime_u_builder_O_active_base_order;
    wire S_runtime_u_builder_O_active_base_order_explicit;
    wire S_runtime_u_builder_O_reorder_ready;
    wire S_runtime_u_builder_O_reorder_done_valid;
    wire [3:0] S_runtime_u_builder_O_reorder_error;
    wire [15:0] S_runtime_u_builder_O_reorder_tag;
    wire [31:0] S_runtime_u_builder_O_reorder_generation;
    wire [31:0] S_runtime_u_builder_O_reorder_revision;
    wire [5:0] S_runtime_u_builder_O_reorder_current_index;
playlist_index_builder u_builder (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_O_build_start_valid && S_allow_build),
        .O_start_ready(S_B_O_start_ready),
        .I_file_size(S_O_build_file_size),
        .I_generation(S_O_build_generation),
        .I_seed(S_O_build_seed),
        .I_tag(S_O_build_tag),
        .I_abort(S_I_abort),
        .I_stream_error(S_O_build_stream_error),
        .I_byte_valid(S_O_build_byte_valid && S_allow_byte),
        .O_byte_ready(S_B_O_byte_ready),
        .I_byte_data(S_O_build_byte_data),
        .I_byte_last(S_O_build_byte_last),
        .I_byte_tag(S_O_build_byte_tag),
        .I_byte_generation(S_O_build_byte_generation),
        .I_retire_valid(S_O_build_retire_valid && S_allow_retire),
        .O_retire_ready(S_B_O_retire_ready),
        .I_retire_tag(S_O_build_retire_tag),
        .I_retire_generation(S_O_build_retire_generation),
        .I_retire_error(S_O_build_retire_error),
        .O_source_cancel(S_B_O_source_cancel),
        .O_source_tag(S_B_O_source_tag),
        .O_source_generation(S_B_O_source_generation),
        .O_busy(S_B_O_busy),
        .O_done_valid(S_B_O_done_valid),
        .I_done_ready(S_builder_done_ready),
        .O_error(S_B_O_error),
        .O_warning(S_B_O_warning),
        .O_count(S_B_O_count),
        .O_tag(S_B_O_tag),
        .O_generation(S_B_O_generation),
        .O_committed(S_B_O_committed),
        .O_fallback_required(S_B_O_fallback_required),
        .O_active_valid(S_B_O_active_valid),
        .O_active_count(S_B_O_active_count),
        .O_active_generation(S_B_O_active_generation),
        .O_active_revision(S_B_O_active_revision),
        .I_acquire_valid(1'b0),
        .O_acquire_ready(S_B_O_acquire_ready),
        .O_snapshot_valid(S_B_O_snapshot_valid),
        .O_snapshot_count(S_B_O_snapshot_count),
        .O_snapshot_generation(S_B_O_snapshot_generation),
        .O_snapshot_revision(S_B_O_snapshot_revision),
        .I_release_valid(1'b0),
        .O_release_ready(S_B_O_release_ready),
        .I_read_valid(1'b0),
        .O_read_ready(S_B_O_read_ready),
        .I_read_index(6'd0),
        .I_read_kind(2'd0),
        .I_read_address(7'd0),
        .I_read_tag(16'd0),
        .O_read_result_valid(S_B_O_read_result_valid),
        .I_read_result_ready(1'b1),
        .O_read_file_length(S_B_O_read_file_length),
        .O_read_audio_length(S_B_O_read_audio_length),
        .O_read_title_length(S_B_O_read_title_length),
        .O_read_duration(S_B_O_read_duration),
        .O_read_transition_ms(S_B_O_read_transition_ms),
        .O_read_transition(S_B_O_read_transition),
        .O_read_data(S_B_O_read_data),
        .O_read_tag(S_B_O_read_tag),
        .O_read_error(S_B_O_read_error),
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
        .O_read_policy(S_policy_u_builder_O_read_policy),
        .I_order_override(1'b0),
        .I_runtime_order(2'd0),
        .O_active_order(S_runtime_u_builder_O_active_order),
        .O_active_base_order(S_runtime_u_builder_O_active_base_order),
        .O_active_base_order_explicit(S_runtime_u_builder_O_active_base_order_explicit),
        .I_reorder_valid(1'b0),
        .O_reorder_ready(S_runtime_u_builder_O_reorder_ready),
        .I_reorder_order(2'd0),
        .I_reorder_seed(32'd0),
        .I_reorder_generation(32'd0),
        .I_reorder_tag(16'd0),
        .I_reorder_current_index(6'd0),
        .I_reorder_abort(1'b0),
        .O_reorder_done_valid(S_runtime_u_builder_O_reorder_done_valid),
        .I_reorder_done_ready(1'b0),
        .O_reorder_error(S_runtime_u_builder_O_reorder_error),
        .O_reorder_tag(S_runtime_u_builder_O_reorder_tag),
        .O_reorder_generation(S_runtime_u_builder_O_reorder_generation),
        .O_reorder_revision(S_runtime_u_builder_O_reorder_revision),
        .O_reorder_current_index(S_runtime_u_builder_O_reorder_current_index)
    );
    always #4 S_I_clk=~S_I_clk;
    always @* begin
        S_I_build_start_ready=S_B_O_start_ready && S_allow_build;
        S_I_build_byte_ready=S_B_O_byte_ready && S_allow_byte;
        S_I_build_retire_ready=S_B_O_retire_ready && S_allow_retire;
        S_I_build_cancel=S_B_O_source_cancel;
        S_I_build_cancel_tag=S_B_O_source_tag;
        S_I_build_cancel_generation=S_B_O_source_generation;
    end
    reg S_test_pass=0,S_drop_at_retire=0;
    reg [4095:0] S_text;
    reg [143:0] S_path="/PLAY/PLAYLIST.TXT";
    reg [159:0] S_held;
    integer S_length,S_i,S_case=0,S_builds=0,S_reads=0,S_closes=0,S_retires=0,S_cancels=0;
    integer S_revision=0,S_before;
    task fail;
        input [767:0] message;
        begin $display("FAIL: playlist_file_source case %0d: %0s",S_case,message); $stop; end
    endtask
    task start_source;
        input [1:0] context;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_start_valid=1; S_I_context=context; S_I_tag=tag;
            S_I_generation=S_I_media_generation; S_I_seed=32'h12345678; S_I_sector_budget=8;
            S_allow_retire=0;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
            // Every subsequent command must use the accepted payload.
            S_I_context=0; S_I_tag=16'hffff; S_I_generation=32'hbadbad00;
            S_I_seed=0; S_I_sector_budget=0;
        end
    endtask
    task open_header;
        begin
            wait(S_O_fs_open_valid);
            if(S_O_fs_open_context!==S_O_context || S_O_fs_open_tag!==S_O_tag ||
                S_O_fs_path_length!==18 || S_O_fs_sector_budget!==8) fail("open command payload/latching");
            repeat(3) @(negedge S_I_clk);
            S_I_fs_open_ready=1;
            @(posedge S_I_clk); if(!S_O_fs_open_valid) fail("open command withdrawn without stop");
            @(negedge S_I_clk); S_I_fs_open_ready=0;
        end
    endtask
    task open_response;
        input integer size;
        input [7:0] error;
        begin
            @(negedge S_I_clk); S_I_fs_open_result_valid=1;
            S_I_fs_open_context=S_O_context==2 ? 1 : 2; S_I_fs_open_tag=S_O_tag;
            S_I_fs_open_generation=S_O_generation; S_I_fs_open_size=size;
            S_I_fs_open_error=error; S_I_fs_open_storage_error=0; S_I_fs_open_warning=3;
            repeat(3) begin
                @(negedge S_I_clk);
                if(S_O_fs_open_result_ready) fail("consumed another context's open result");
            end
            S_I_fs_open_context=S_O_context; S_I_fs_open_tag=S_O_tag^16'h0100;
            @(posedge S_I_clk); if(!S_O_fs_open_result_ready) fail("stale owned open tag not drained");
            @(negedge S_I_clk); S_I_fs_open_tag=S_O_tag; S_I_fs_open_generation=S_O_generation+1;
            @(posedge S_I_clk); if(!S_O_fs_open_result_ready) fail("stale owned open generation not drained");
            @(negedge S_I_clk); S_I_fs_open_generation=S_O_generation;
            if(S_O_build_start_valid || S_O_fs_close_valid || S_O_done_valid)
                fail("stale open identity ended current wait");
            @(posedge S_I_clk); while(!S_O_fs_open_result_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_open_result_valid=0;
        end
    endtask
    task open_file;
        input integer size;
        input [7:0] error;
        begin
            open_header;
            S_I_fs_path_ready=1;
            for(S_i=0;S_i<18;S_i=S_i+1) begin
                @(posedge S_I_clk); while(!S_O_fs_path_valid) @(posedge S_I_clk);
                if(S_O_fs_path_data!==S_path[(17-S_i)*8+:8] || S_O_fs_path_last!==(S_i==17))
                    fail("fixed playlist path bytes/last");
                @(negedge S_I_clk);
            end
            S_I_fs_path_ready=0;
            open_response(size,error);
        end
    endtask
    task accept_read;
        begin
            wait(S_O_fs_read_valid);
            if(!S_O_builder_started || S_O_fs_length!==S_length || S_O_fs_offset!==0 ||
                S_O_fs_epoch!==S_O_tag || S_O_fs_read_context!==S_O_context || S_O_fs_read_priority!==0 ||
                S_O_build_seed!==32'h12345678) fail("read before builder / read payload");
            @(negedge S_I_clk); S_I_fs_read_ready=1;
            @(posedge S_I_clk); while(!S_O_fs_read_valid) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_read_ready=0;
        end
    endtask
    task byte_at;
        input integer offset;
        input [7:0] data;
        input last;
        begin
            @(negedge S_I_clk); S_I_fs_byte_valid=1; S_I_fs_byte_context=S_O_context;
            S_I_fs_byte_epoch=S_O_tag; S_I_fs_byte_generation=S_O_generation;
            S_I_fs_byte_offset=offset; S_I_fs_byte_data=data; S_I_fs_byte_last=last;
            @(posedge S_I_clk); while(!S_O_fs_byte_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_byte_valid=0;
        end
    endtask
    task send_text;
        begin
            for(S_i=0;S_i<S_length;S_i=S_i+1)
                byte_at(S_i,S_text[(S_length-1-S_i)*8+:8],S_i==S_length-1);
        end
    endtask
    task file_done;
        input [7:0] error;
        input integer count;
        input eof;
        begin
            @(negedge S_I_clk); S_I_fs_done_valid=1; S_I_fs_done_context=S_O_context;
            S_I_fs_done_epoch=S_O_tag; S_I_fs_done_generation=S_O_generation;
            S_I_fs_done_error=error; S_I_fs_done_bytes=count; S_I_fs_done_eof=eof;
            @(posedge S_I_clk); while(!S_O_fs_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_done_valid=0; S_I_fs_done_storage_error=0;
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_I_abort=1; @(negedge S_I_clk); S_I_abort=0; end
    endtask
    task accept_cancel;
        begin
            wait(S_O_fs_cancel_valid);
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_fs_cancel_valid || S_O_fs_close_valid || S_O_build_retire_valid)
                    fail("cancel waiting for acceptance lost / early retirement");
            end
            S_I_fs_cancel_ready=1;
            @(posedge S_I_clk); if(!S_O_fs_cancel_valid) fail("cancel acceptance");
            @(negedge S_I_clk); S_I_fs_cancel_ready=0;
        end
    endtask
    task cancel_ack;
        begin
            repeat(12) begin
                @(negedge S_I_clk);
                if(S_O_fs_close_valid || S_O_build_retire_valid || S_O_done_valid)
                    fail("file.done / cancel acceptance mistaken for retirement");
            end
            S_I_fs_cancel_done_valid=1; S_I_fs_cancel_done_context=S_O_context==2 ? 1 : 2;
            repeat(3) begin
                @(negedge S_I_clk);
                if(S_O_fs_cancel_done_ready) fail("consumed another context's cancel result");
            end
            S_I_fs_cancel_done_context=S_O_context;
            S_I_fs_cancel_done_epoch=S_O_tag^16'h0100; S_I_fs_cancel_done_generation=S_O_generation;
            @(posedge S_I_clk); if(!S_O_fs_cancel_done_ready) fail("owned stale cancel result not drained");
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
            repeat(3) @(negedge S_I_clk);
            if(S_O_fs_close_valid) fail("wrong cancel epoch released context");
            S_I_fs_cancel_done_valid=1; S_I_fs_cancel_done_epoch=S_O_tag;
            S_I_fs_cancel_done_generation=S_O_generation+1;
            @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
            repeat(3) @(negedge S_I_clk);
            if(S_O_fs_close_valid) fail("wrong cancel generation released context");
            S_I_fs_cancel_done_valid=1; S_I_fs_cancel_done_generation=S_O_generation;
            @(posedge S_I_clk); while(!S_O_fs_cancel_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
        end
    endtask
    task finish_case;
        input [3:0] error,builder_error;
        input started,opened,committed;
        begin
            if(opened) begin
                wait(S_O_fs_close_valid);
                repeat(5) begin
                    @(negedge S_I_clk);
                    if(!S_O_fs_close_valid || S_O_build_retire_valid || S_O_done_valid)
                        fail("close is not persistent / retirement before close");
                end
                S_I_fs_close_ready=1;
                @(posedge S_I_clk); if(!S_O_fs_close_valid) fail("close acceptance");
                @(negedge S_I_clk); S_I_fs_close_ready=0;
            end
            if(started) begin
                wait(S_O_build_retire_valid);
                S_held={S_O_build_retire_error,S_O_build_retire_tag,S_O_build_retire_generation};
                if(S_drop_at_retire) begin
                    @(negedge S_I_clk); S_I_media_valid=0;
                    @(negedge S_I_clk); S_I_media_valid=1;
                end
                repeat(7) begin
                    @(negedge S_I_clk);
                    if(!S_O_build_retire_valid || S_O_done_valid ||
                        {S_O_build_retire_error,S_O_build_retire_tag,S_O_build_retire_generation}!==S_held)
                        fail("retirement record unstable / source done too early");
                end
                if(S_O_build_retire_error!=={4'd0,error}) fail("retirement error");
                S_allow_retire=1;
            end
            wait(S_O_done_valid);
            if(started) wait(S_B_O_done_valid);
            if(S_O_error!==error || S_O_builder_started!==started || S_O_lease_active!==1 ||
                S_O_missing!==(error==5)) fail("source completion");
            if(started && (S_B_O_error!==builder_error || S_B_O_committed!==committed ||
                S_B_O_tag!==S_O_tag || S_B_O_generation!==S_O_generation)) fail("builder completion");
            if(committed) begin
                S_revision=S_revision+1;
                if(!S_B_O_active_valid || S_B_O_active_count!==1 || S_B_O_active_revision!==S_revision)
                    fail("real parser/store index commit");
            end else if(S_B_O_active_revision!==S_revision) fail("failed source changed index revision");
            S_held={S_O_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_builder_started};
            // Once published, terminal payloads cannot be changed by a later abort.
            S_I_abort=1;
            repeat(6) begin
                @(negedge S_I_clk);
                S_I_abort=0;
                if(!S_O_done_valid || S_O_start_ready ||
                    {S_O_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                        S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_builder_started}!==S_held)
                    fail("source terminal under backpressure");
            end
            S_I_done_ready=1; S_builder_done_ready=1;
            @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_done_ready=0; S_builder_done_ready=0;
            if(S_O_lease_active || S_O_busy) fail("lease not released after done");
            S_allow_retire=0;
        end
    endtask

    always @(posedge S_I_clk) if(!S_I_reset) begin
        if(S_O_build_start_valid && S_I_build_start_ready) S_builds=S_builds+1;
        if(S_O_fs_read_valid && S_I_fs_read_ready) S_reads=S_reads+1;
        if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
        if(S_O_build_retire_valid && S_I_build_retire_ready) S_retires=S_retires+1;
        if(S_O_fs_cancel_valid && S_I_fs_cancel_ready) S_cancels=S_cancels+1;
        if(S_O_build_retire_valid && (S_O_fs_close_valid || S_O_fs_cancel_valid || !S_O_builder_started))
            fail("retirement overlaps an unclosed or unstarted owner");
        if(S_B_O_active_revision>S_retires) fail("index commit without source retirement");
    end

    initial begin
        S_I_reset=1; S_I_media_valid=1; S_I_media_generation=32'h7654abcd;
        S_text="[GLOBAL]\norder=list\n[ITEM]\nfile=one.bmp\ntitle=one\n";
        S_length=50;
        #35; @(negedge S_I_clk); S_I_reset=0;
        // Explicit lease: busy playback contexts must not be touched.
        S_I_context=2; S_I_start_valid=1;
        repeat(7) begin
            @(negedge S_I_clk);
            if(!S_O_lease_request || S_O_start_ready || S_O_fs_open_valid || S_O_lease_active)
                fail("source bypassed context grant");
        end
        S_I_context=3; #1;
        if(S_O_lease_request || S_O_start_ready) fail("illegal context lease");
        S_I_start_valid=0; S_I_lease_grant=1;
        start_source(2,16'h8100); open_file(S_length,0); accept_read;
        // Real builder byte backpressure must propagate without consuming the byte.
        S_allow_byte=0;
        @(negedge S_I_clk); S_I_fs_byte_valid=1; S_I_fs_byte_context=S_O_context;
        S_I_fs_byte_epoch=S_O_tag; S_I_fs_byte_generation=S_O_generation;
        S_I_fs_byte_offset=0; S_I_fs_byte_data="["; S_I_fs_byte_last=0;
        repeat(5) begin @(negedge S_I_clk); if(S_O_fs_byte_ready) fail("byte backpressure lost"); end
        S_I_fs_byte_valid=0; S_allow_byte=1;
        send_text; file_done(0,S_length,1); finish_case(0,0,1,1,1);

        // A missing list never starts the builder and never closes someone else's slot.
        start_source(0,16'h8101); open_file(0,14); finish_case(5,0,0,0,0);
        if(S_O_file_error!==14) fail("missing-list raw filesystem error");
        // Empty list still performs a real length-zero read and retirement.
        S_length=0;
        start_source(1,16'h8102); open_file(0,0); accept_read;
        file_done(0,0,1); finish_case(0,5,1,1,0);
        if(!S_B_O_fallback_required || !S_B_O_active_valid) fail("empty-list fallback lost previous index");

        // Cancel before any command is accepted.
        S_I_abort=1; start_source(0,16'h8103); S_I_abort=0;
        finish_case(2,0,0,0,0);
        // Early namespace terminal while the path frame is still incomplete.
        start_source(1,16'h8104); open_header;
        @(negedge S_I_clk); S_I_fs_path_ready=1;
        repeat(3) @(negedge S_I_clk);
        S_I_fs_path_ready=0; pulse_abort;
        if(!S_O_fs_open_cancel) fail("open cancel not held");
        open_response(0,8); finish_case(2,0,0,0,0);

        // Successfully opened file waiting for the builder's bank must remain cancellable.
        S_allow_build=0;
        start_source(0,16'h8105); open_file(50,0);
        repeat(6) begin @(negedge S_I_clk); if(S_O_fs_read_valid) fail("read bypassed builder start"); end
        pulse_abort; finish_case(2,0,0,1,0); S_allow_build=1;

        // Started builder but no accepted read still receives a close-then-retire record.
        S_length=50;
        start_source(1,16'h8106); open_file(S_length,0); wait(S_O_fs_read_valid);
        pulse_abort; finish_case(2,2,1,1,0);

        // Accepted cancel must wait for file.done AND the delayed matching cancel_done.
        start_source(2,16'h8107); open_file(S_length,0); accept_read;
        byte_at(0,"[",0); pulse_abort; accept_cancel;
        byte_at(1,"G",0); file_done(8,2,0); cancel_ack; finish_case(2,2,1,1,0);

        // Done can win while cancel_ready is low; no unaccepted cancel ack is owed.
        start_source(0,16'h8108); open_file(S_length,0); accept_read;
        pulse_abort; wait(S_O_fs_cancel_valid); S_before=S_cancels;
        file_done(8,0,0); finish_case(2,2,1,1,0);
        if(S_cancels!=S_before) fail("created cancel obligation after done");

        // Both accept together: cancel_done is still mandatory after file.done.
        start_source(2,16'h8188); open_file(S_length,0); accept_read;
        pulse_abort; wait(S_O_fs_cancel_valid);
        @(negedge S_I_clk); S_I_fs_cancel_ready=1;
        S_I_fs_done_valid=1; S_I_fs_done_context=S_O_context;
        S_I_fs_done_epoch=S_O_tag; S_I_fs_done_generation=S_O_generation;
        S_I_fs_done_error=8; S_I_fs_done_bytes=0; S_I_fs_done_eof=0;
        @(posedge S_I_clk);
        if(!S_O_fs_cancel_valid || !S_O_fs_done_ready) fail("simultaneous cancel/done handshake");
        @(negedge S_I_clk); S_I_fs_cancel_ready=0; S_I_fs_done_valid=0;
        cancel_ack; finish_case(2,2,1,1,0);

        // Wrong context is untouched; stale identities for this leased context are drained.
        start_source(1,16'h8209); open_file(S_length,0); accept_read;
        @(negedge S_I_clk); S_I_fs_byte_valid=1; S_I_fs_byte_context=2;
        S_I_fs_done_valid=1; S_I_fs_done_context=2;
        repeat(4) begin
            @(negedge S_I_clk);
            if(S_O_fs_byte_ready || S_O_fs_done_ready) fail("consumed another context");
        end
        S_I_fs_byte_context=1; S_I_fs_byte_epoch=S_O_tag^16'h0100;
        S_I_fs_byte_generation=S_O_generation; S_I_fs_byte_data=8'hff;
        S_I_fs_done_context=1; S_I_fs_done_epoch=S_O_tag;
        S_I_fs_done_generation=S_O_generation+1;
        @(posedge S_I_clk);
        if(!S_O_fs_byte_ready || !S_O_fs_done_ready || S_O_build_byte_valid) fail("stale return routing");
        @(negedge S_I_clk); S_I_fs_byte_epoch=S_O_tag; S_I_fs_byte_generation=S_O_generation+1;
        @(posedge S_I_clk);
        if(!S_O_fs_byte_ready || S_O_build_byte_valid) fail("stale byte generation routing");
        @(negedge S_I_clk); S_I_fs_byte_valid=0; S_I_fs_done_valid=0;
        // Final byte and done handshake on precisely the same edge.
        for(S_i=0;S_i<S_length-1;S_i=S_i+1)
            byte_at(S_i,S_text[(S_length-1-S_i)*8+:8],0);
        @(negedge S_I_clk); S_I_fs_byte_valid=0; S_I_fs_byte_context=1;
        S_I_fs_byte_epoch=S_O_tag; S_I_fs_byte_generation=S_O_generation;
        S_I_fs_byte_offset=S_length-1; S_I_fs_byte_data=8'h0a; S_I_fs_byte_last=1;
        S_I_fs_done_valid=0; S_I_fs_done_context=1; S_I_fs_done_epoch=S_O_tag;
        S_I_fs_done_generation=S_O_generation; S_I_fs_done_error=0;
        S_I_fs_done_bytes=S_length; S_I_fs_done_eof=1;
        #1; while(!S_O_fs_byte_ready) @(negedge S_I_clk);
        S_I_fs_byte_valid=1; S_I_fs_done_valid=1;
        @(posedge S_I_clk);
        if(!S_O_fs_done_ready) fail("simultaneous final byte/done acceptance");
        @(negedge S_I_clk); S_I_fs_byte_valid=0; S_I_fs_done_valid=0;
        finish_case(0,0,1,1,1);

        // Raw filesystem/storage error is not overwritten by the builder's cancel echo.
        start_source(0,16'h8110); open_file(S_length,0); accept_read;
        byte_at(0,"[",0); S_I_fs_done_storage_error=4;
        file_done(2,1,0); finish_case(1,1,1,1,0);
        if(S_O_file_error!==2 || S_O_storage_error!==4) fail("raw I/O diagnostics");

        // Offset protocol violation, while keeping byte count and parser payload otherwise valid.
        start_source(2,16'h8111); open_file(S_length,0); accept_read;
        byte_at(1,"[",0); accept_cancel; file_done(8,1,0); cancel_ack;
        finish_case(4,1,1,1,0);
        // A successful but short terminal is a protocol error.
        start_source(1,16'h8112); open_file(S_length,0); accept_read;
        file_done(0,0,0); finish_case(4,1,1,1,0);

        // Accurate payload alone does not authorize a bad count or EOF terminal.
        start_source(0,16'h8192); open_file(S_length,0); accept_read;
        send_text; file_done(0,S_length-1,1); finish_case(4,1,1,1,0);
        start_source(2,16'h8193); open_file(S_length,0); accept_read;
        send_text; file_done(0,S_length,0); finish_case(4,1,1,1,0);

        // A published retirement remains stable while the builder separately sees loss.
        S_drop_at_retire=1;
        start_source(1,16'h8194); open_file(S_length,0); accept_read;
        send_text; file_done(0,S_length,1); finish_case(0,3,1,1,0);
        S_drop_at_retire=0;
        if(S_B_O_active_valid) fail("loss during retirement revived an old index");

        // Short media loss is sticky even if the same generation appears ready again.
        start_source(0,16'h8113); open_file(S_length,0); accept_read;
        byte_at(0,"[",0);
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        accept_cancel; file_done(1,1,0); cancel_ack; finish_case(3,3,1,1,0);
        if(S_B_O_active_valid) fail("media restoration revived old active index");
        S_I_media_generation=S_I_media_generation+1;
        start_source(2,16'h8114); open_file(S_length,0); accept_read;
        send_text; file_done(0,S_length,1); finish_case(0,0,1,1,1);

        // Reset is a global forced discard, not a normal file retirement.
        start_source(1,16'h8115); open_file(S_length,0); accept_read;
        @(negedge S_I_clk); S_I_reset=1;
        repeat(4) @(negedge S_I_clk);
        S_I_reset=0; S_revision=0;
        S_builds=0; S_reads=0; S_closes=0; S_retires=0; S_cancels=0;
        if(S_O_busy || S_O_lease_active || S_B_O_active_valid) fail("global reset cleanup");
        start_source(0,16'h8116); open_file(S_length,0); accept_read;
        send_text; file_done(0,S_length,1); finish_case(0,0,1,1,1);

        if(S_builds!=S_retires || S_closes<S_retires || S_reads>S_builds)
            fail("one retirement per started builder / ownership accounting");
        S_test_pass=1;
        $display("PASS: playlist_file_source protocol endpoints and real parser/store integration");
        $finish;
    end
    initial begin #30000000; fail("watchdog: source retirement or handshake did not complete"); end
endmodule
