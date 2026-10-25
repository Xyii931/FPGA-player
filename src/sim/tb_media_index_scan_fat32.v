`timescale 1ns/1ps
// Real automatic scan + FAT32; only SD host sector traffic is a fixture.
module tb_media_index_scan_fat32;
    // Declare shared endpoints before instances and continuous assignments.
    reg S_I_clk=0,S_I_reset=0;
    reg S_W_I_start_valid=0;
    reg S_W_I_lease_grant=0;
    reg S_W_I_abort=0;
    reg [1:0] S_W_I_context=0;
    reg [15:0] S_W_I_tag=0;
    reg [31:0] S_W_I_generation=0;
    reg [31:0] S_W_I_seed=0;
    reg [31:0] S_W_I_sector_budget=0;
    reg [31:0] S_W_I_directory_sector_budget=0;
    reg [9:0] S_W_I_directory_duration=0;
    reg [9:0] S_W_I_directory_transition_ms=0;
    reg [2:0] S_W_I_directory_transition=0;
    reg [1:0] S_W_I_directory_order=0;
    reg S_W_I_done_ready=0;
    reg S_W_I_acquire_valid=0;
    reg S_W_I_release_valid=0;
    reg S_W_I_read_valid=0;
    reg [5:0] S_W_I_read_index=0;
    reg [1:0] S_W_I_read_kind=0;
    reg [6:0] S_W_I_read_address=0;
    reg [15:0] S_W_I_read_tag=0;
    reg S_W_I_read_result_ready=0;
    reg  S_F_I_card_ready=0;
    reg  S_F_I_unmount=0;
    reg  S_F_I_mount_valid=0;
    reg  S_F_I_mount_result_ready=0;
    reg  S_F_I_sd_request_ready=0;
    reg  S_F_I_sd_byte_valid=0;
    reg [7:0] S_F_I_sd_byte_data=0;
    reg  S_F_I_sd_sector_last=0;
    reg  S_F_I_sd_request_last=0;
    reg [1:0] S_F_I_sd_byte_context=0;
    reg [15:0] S_F_I_sd_byte_tag=0;
    reg  S_F_I_sd_done_valid=0;
    reg [1:0] S_F_I_sd_done_context=0;
    reg [15:0] S_F_I_sd_done_tag=0;
    reg [3:0] S_F_I_sd_done_error=0;
    reg  S_F_I_sd_cancel_ready=0;
    reg  S_F_I_sd_cancel_done_valid=0;
    reg [1:0] S_F_I_sd_cancel_done_context=0;
    reg [15:0] S_F_I_sd_cancel_done_tag=0;
    reg S_test_pass=0;
    reg [7:0] S_disk[0:4095],S_sector[0:511];
    reg [4095:0] S_text="[GLOBAL]\norder=list\n[ITEM]\nfile=one.bmp\ntitle=one\n";
    reg [103:0] S_expected_path="/PLAY/one.bmp";
    reg [2:0] S_host_state=0;
    reg S_canceled=0,S_cancel_seen=0,S_injected=0;
    reg [31:0] S_fail_lba=32'hffffffff;
    integer S_cycle=0,S_index=0,S_base=0,S_delay=0,S_i,S_j,S_case=0;
    integer S_revision=0,S_cancel_acks=0,S_before;
    reg [31:0] S_mount_generation=0;
    reg [15:0] S_command_tag=0;
    integer S_enum_count=0;
    reg [159:0] S_held;
    wire S_I_media_valid;
    wire [31:0] S_I_media_generation;
    wire S_W_O_start_ready;
    wire S_W_O_lease_request;
    wire S_W_O_lease_active;
    wire S_W_O_busy;
    wire S_W_O_done_valid;
    wire [3:0] S_W_O_error;
    wire [3:0] S_W_O_list_source_error;
    wire [3:0] S_W_O_list_build_error;
    wire [3:0] S_W_O_directory_build_error;
    wire [6:0] S_W_O_count;
    wire S_W_O_committed;
    wire S_W_O_used_directory;
    wire S_W_O_list_missing;
    wire S_W_O_list_started;
    wire S_W_O_directory_started;
    wire [7:0] S_W_O_list_warning;
    wire [7:0] S_W_O_directory_warning;
    wire [1:0] S_W_O_context;
    wire [15:0] S_W_O_tag;
    wire [31:0] S_W_O_generation;
    wire [7:0] S_W_O_file_error;
    wire [3:0] S_W_O_storage_error;
    wire [2:0] S_W_O_path_warning;
    wire [31:0] S_W_O_file_size;
    wire S_W_O_fs_open_valid;
    wire S_W_I_fs_open_ready;
    wire [1:0] S_W_O_fs_open_context;
    wire [15:0] S_W_O_fs_open_tag;
    wire [6:0] S_W_O_fs_path_length;
    wire [31:0] S_W_O_fs_sector_budget;
    wire S_W_O_fs_path_valid;
    wire S_W_I_fs_path_ready;
    wire [7:0] S_W_O_fs_path_data;
    wire S_W_O_fs_path_last;
    wire S_W_O_fs_open_cancel;
    wire S_W_I_fs_open_result_valid;
    wire S_W_O_fs_open_result_ready;
    wire [1:0] S_W_I_fs_open_context;
    wire [15:0] S_W_I_fs_open_tag;
    wire [31:0] S_W_I_fs_open_generation;
    wire [31:0] S_W_I_fs_open_size;
    wire [7:0] S_W_I_fs_open_error;
    wire [3:0] S_W_I_fs_open_storage_error;
    wire [2:0] S_W_I_fs_open_warning;
    wire S_W_O_fs_read_valid;
    wire S_W_I_fs_read_ready;
    wire [1:0] S_W_O_fs_read_context;
    wire [1:0] S_W_O_fs_read_priority;
    wire [31:0] S_W_O_fs_offset;
    wire [31:0] S_W_O_fs_length;
    wire [15:0] S_W_O_fs_epoch;
    wire S_W_I_fs_byte_valid;
    wire S_W_O_fs_byte_ready;
    wire [7:0] S_W_I_fs_byte_data;
    wire [1:0] S_W_I_fs_byte_context;
    wire [15:0] S_W_I_fs_byte_epoch;
    wire [31:0] S_W_I_fs_byte_generation;
    wire [31:0] S_W_I_fs_byte_offset;
    wire S_W_I_fs_byte_last;
    wire S_W_I_fs_done_valid;
    wire S_W_O_fs_done_ready;
    wire [1:0] S_W_I_fs_done_context;
    wire [15:0] S_W_I_fs_done_epoch;
    wire [31:0] S_W_I_fs_done_generation;
    wire [31:0] S_W_I_fs_done_bytes;
    wire S_W_I_fs_done_eof;
    wire [7:0] S_W_I_fs_done_error;
    wire [3:0] S_W_I_fs_done_storage_error;
    wire S_W_O_fs_cancel_valid;
    wire S_W_I_fs_cancel_ready;
    wire [1:0] S_W_O_fs_cancel_context;
    wire [15:0] S_W_O_fs_cancel_epoch;
    wire S_W_I_fs_cancel_done_valid;
    wire S_W_O_fs_cancel_done_ready;
    wire [1:0] S_W_I_fs_cancel_done_context;
    wire [15:0] S_W_I_fs_cancel_done_epoch;
    wire [31:0] S_W_I_fs_cancel_done_generation;
    wire S_W_O_fs_close_valid;
    wire S_W_I_fs_close_ready;
    wire [1:0] S_W_O_fs_close_context;
    wire S_W_O_active_valid;
    wire [6:0] S_W_O_active_count;
    wire [31:0] S_W_O_active_generation;
    wire [31:0] S_W_O_active_revision;
    wire S_W_O_acquire_ready;
    wire S_W_O_snapshot_valid;
    wire [6:0] S_W_O_snapshot_count;
    wire [31:0] S_W_O_snapshot_generation;
    wire [31:0] S_W_O_snapshot_revision;
    wire S_W_O_release_ready;
    wire S_W_O_read_ready;
    wire S_W_O_read_result_valid;
    wire [6:0] S_W_O_read_file_length;
    wire [6:0] S_W_O_read_audio_length;
    wire [5:0] S_W_O_read_title_length;
    wire [9:0] S_W_O_read_duration;
    wire [9:0] S_W_O_read_transition_ms;
    wire [2:0] S_W_O_read_transition;
    wire [7:0] S_W_O_read_data;
    wire [15:0] S_W_O_read_tag;
    wire [3:0] S_W_O_read_error;
    wire [7:0] S_W_O_directory_error;
    wire [7:0] S_W_O_directory_primary_error;
    wire [3:0] S_W_O_directory_storage_error;
    wire [2:0] S_W_O_enum_warning;
    wire [32:0] S_W_O_directory_sectors;
    wire S_W_O_enum_valid;
    wire S_W_I_enum_ready;
    wire [15:0] S_W_O_enum_tag;
    wire [6:0] S_W_O_enum_path_length;
    wire [31:0] S_W_O_enum_sector_budget;
    wire S_W_O_enum_path_valid;
    wire S_W_I_enum_path_ready;
    wire [7:0] S_W_O_enum_path_data;
    wire S_W_O_enum_path_last;
    wire S_W_O_enum_stop;
    wire S_W_O_enum_cancel;
    wire S_W_I_enum_entry_valid;
    wire S_W_O_enum_entry_ready;
    wire [7:0] S_W_I_enum_attr;
    wire [31:0] S_W_I_enum_size;
    wire [31:0] S_W_I_enum_first_cluster;
    wire [6:0] S_W_I_enum_name_length;
    wire S_W_I_enum_name_valid;
    wire S_W_O_enum_name_ready;
    wire [7:0] S_W_I_enum_name_data;
    wire S_W_I_enum_name_last;
    wire S_W_I_enum_done_valid;
    wire S_W_O_enum_done_ready;
    wire [15:0] S_W_I_enum_tag;
    wire [31:0] S_W_I_enum_generation;
    wire [31:0] S_W_I_enum_sectors;
    wire [7:0] S_W_I_enum_error;
    wire [3:0] S_W_I_enum_storage_error;
    wire [2:0] S_W_I_enum_warning;
    wire [1:0] S_runtime_u_scan_O_active_base_order;
    wire S_runtime_u_scan_O_active_base_order_explicit;
    wire S_runtime_u_scan_O_reorder_ready;
    wire S_runtime_u_scan_O_reorder_done_valid;
    wire [3:0] S_runtime_u_scan_O_reorder_error;
    wire [15:0] S_runtime_u_scan_O_reorder_tag;
    wire [31:0] S_runtime_u_scan_O_reorder_generation;
    wire [31:0] S_runtime_u_scan_O_reorder_revision;
    wire [5:0] S_runtime_u_scan_O_reorder_current_index;
    wire [6:0] S_policy_u_scan_O_read_policy;
    wire  S_F_O_mount_ready;
    wire  S_F_O_mount_result_valid;
    wire [7:0] S_F_O_mount_error;
    wire [3:0] S_F_O_mount_storage_error;
    wire [31:0] S_F_O_mount_generation;
    wire  S_F_O_quiescent;
    wire [31:0] S_F_O_partition_lba;
    wire [31:0] S_F_O_volume_sectors;
    wire [31:0] S_F_O_fat_lba;
    wire [31:0] S_F_O_data_lba;
    wire [31:0] S_F_O_cluster_count;
    wire [31:0] S_F_O_root_cluster;
    wire [7:0] S_F_O_sectors_per_cluster;
    wire [2:0] S_F_O_cluster_shift;
    wire [31:0] S_F_O_open_first_cluster;
    wire [31:0] S_F_O_open_sectors;
    wire [7:0] S_F_O_open_attr;
    wire  S_F_O_sd_request_valid;
    wire [31:0] S_F_O_sd_lba;
    wire [7:0] S_F_O_sd_count;
    wire [1:0] S_F_O_sd_context;
    wire [1:0] S_F_O_sd_priority;
    wire [15:0] S_F_O_sd_tag;
    wire  S_F_O_sd_byte_ready;
    wire  S_F_O_sd_done_ready;
    wire  S_F_O_sd_cancel_valid;
    wire [1:0] S_F_O_sd_cancel_context;
    wire [15:0] S_F_O_sd_cancel_tag;
    wire  S_F_O_sd_cancel_done_ready;
    wire [15:0] S_expected_enum_tag=S_command_tag+16'd1+S_enum_count;
    always #4 S_I_clk=~S_I_clk;
        wire [1:0] S_runtime_u_scan_O_active_order;
media_index_scan u_scan (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_W_I_start_valid),
        .O_start_ready(S_W_O_start_ready),
        .O_lease_request(S_W_O_lease_request),
        .I_lease_grant(S_W_I_lease_grant),
        .I_abort(S_W_I_abort),
        .I_context(S_W_I_context),
        .I_tag(S_W_I_tag),
        .I_generation(S_W_I_generation),
        .I_seed(S_W_I_seed),
        .I_sector_budget(S_W_I_sector_budget),
        .I_directory_sector_budget(S_W_I_directory_sector_budget),
        .I_directory_duration(S_W_I_directory_duration),
        .I_directory_transition_ms(S_W_I_directory_transition_ms),
        .I_directory_transition(S_W_I_directory_transition),
        .I_directory_order(S_W_I_directory_order),
        .O_lease_active(S_W_O_lease_active),
        .O_busy(S_W_O_busy),
        .O_done_valid(S_W_O_done_valid),
        .I_done_ready(S_W_I_done_ready),
        .O_error(S_W_O_error),
        .O_list_source_error(S_W_O_list_source_error),
        .O_list_build_error(S_W_O_list_build_error),
        .O_directory_build_error(S_W_O_directory_build_error),
        .O_count(S_W_O_count),
        .O_committed(S_W_O_committed),
        .O_used_directory(S_W_O_used_directory),
        .O_list_missing(S_W_O_list_missing),
        .O_list_started(S_W_O_list_started),
        .O_directory_started(S_W_O_directory_started),
        .O_list_warning(S_W_O_list_warning),
        .O_directory_warning(S_W_O_directory_warning),
        .O_context(S_W_O_context),
        .O_tag(S_W_O_tag),
        .O_generation(S_W_O_generation),
        .O_file_error(S_W_O_file_error),
        .O_storage_error(S_W_O_storage_error),
        .O_path_warning(S_W_O_path_warning),
        .O_file_size(S_W_O_file_size),
        .O_fs_open_valid(S_W_O_fs_open_valid),
        .I_fs_open_ready(S_W_I_fs_open_ready),
        .O_fs_open_context(S_W_O_fs_open_context),
        .O_fs_open_tag(S_W_O_fs_open_tag),
        .O_fs_path_length(S_W_O_fs_path_length),
        .O_fs_sector_budget(S_W_O_fs_sector_budget),
        .O_fs_path_valid(S_W_O_fs_path_valid),
        .I_fs_path_ready(S_W_I_fs_path_ready),
        .O_fs_path_data(S_W_O_fs_path_data),
        .O_fs_path_last(S_W_O_fs_path_last),
        .O_fs_open_cancel(S_W_O_fs_open_cancel),
        .I_fs_open_result_valid(S_W_I_fs_open_result_valid),
        .O_fs_open_result_ready(S_W_O_fs_open_result_ready),
        .I_fs_open_context(S_W_I_fs_open_context),
        .I_fs_open_tag(S_W_I_fs_open_tag),
        .I_fs_open_generation(S_W_I_fs_open_generation),
        .I_fs_open_size(S_W_I_fs_open_size),
        .I_fs_open_error(S_W_I_fs_open_error),
        .I_fs_open_storage_error(S_W_I_fs_open_storage_error),
        .I_fs_open_warning(S_W_I_fs_open_warning),
        .O_fs_read_valid(S_W_O_fs_read_valid),
        .I_fs_read_ready(S_W_I_fs_read_ready),
        .O_fs_read_context(S_W_O_fs_read_context),
        .O_fs_read_priority(S_W_O_fs_read_priority),
        .O_fs_offset(S_W_O_fs_offset),
        .O_fs_length(S_W_O_fs_length),
        .O_fs_epoch(S_W_O_fs_epoch),
        .I_fs_byte_valid(S_W_I_fs_byte_valid),
        .O_fs_byte_ready(S_W_O_fs_byte_ready),
        .I_fs_byte_data(S_W_I_fs_byte_data),
        .I_fs_byte_context(S_W_I_fs_byte_context),
        .I_fs_byte_epoch(S_W_I_fs_byte_epoch),
        .I_fs_byte_generation(S_W_I_fs_byte_generation),
        .I_fs_byte_offset(S_W_I_fs_byte_offset),
        .I_fs_byte_last(S_W_I_fs_byte_last),
        .I_fs_done_valid(S_W_I_fs_done_valid),
        .O_fs_done_ready(S_W_O_fs_done_ready),
        .I_fs_done_context(S_W_I_fs_done_context),
        .I_fs_done_epoch(S_W_I_fs_done_epoch),
        .I_fs_done_generation(S_W_I_fs_done_generation),
        .I_fs_done_bytes(S_W_I_fs_done_bytes),
        .I_fs_done_eof(S_W_I_fs_done_eof),
        .I_fs_done_error(S_W_I_fs_done_error),
        .I_fs_done_storage_error(S_W_I_fs_done_storage_error),
        .O_fs_cancel_valid(S_W_O_fs_cancel_valid),
        .I_fs_cancel_ready(S_W_I_fs_cancel_ready),
        .O_fs_cancel_context(S_W_O_fs_cancel_context),
        .O_fs_cancel_epoch(S_W_O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(S_W_I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(S_W_O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(S_W_I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(S_W_I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(S_W_I_fs_cancel_done_generation),
        .O_fs_close_valid(S_W_O_fs_close_valid),
        .I_fs_close_ready(S_W_I_fs_close_ready),
        .O_fs_close_context(S_W_O_fs_close_context),
        .O_active_valid(S_W_O_active_valid),
        .O_active_count(S_W_O_active_count),
        .O_active_generation(S_W_O_active_generation),
        .O_active_revision(S_W_O_active_revision),
        .I_acquire_valid(S_W_I_acquire_valid),
        .O_acquire_ready(S_W_O_acquire_ready),
        .O_snapshot_valid(S_W_O_snapshot_valid),
        .O_snapshot_count(S_W_O_snapshot_count),
        .O_snapshot_generation(S_W_O_snapshot_generation),
        .O_snapshot_revision(S_W_O_snapshot_revision),
        .I_release_valid(S_W_I_release_valid),
        .O_release_ready(S_W_O_release_ready),
        .I_read_valid(S_W_I_read_valid),
        .O_read_ready(S_W_O_read_ready),
        .I_read_index(S_W_I_read_index),
        .I_read_kind(S_W_I_read_kind),
        .I_read_address(S_W_I_read_address),
        .I_read_tag(S_W_I_read_tag),
        .O_read_result_valid(S_W_O_read_result_valid),
        .I_read_result_ready(S_W_I_read_result_ready),
        .O_read_file_length(S_W_O_read_file_length),
        .O_read_audio_length(S_W_O_read_audio_length),
        .O_read_title_length(S_W_O_read_title_length),
        .O_read_duration(S_W_O_read_duration),
        .O_read_transition_ms(S_W_O_read_transition_ms),
        .O_read_transition(S_W_O_read_transition),
        .O_read_data(S_W_O_read_data),
        .O_read_tag(S_W_O_read_tag),
        .O_read_error(S_W_O_read_error),
        .O_directory_error(S_W_O_directory_error),
        .O_directory_primary_error(S_W_O_directory_primary_error),
        .O_directory_storage_error(S_W_O_directory_storage_error),
        .O_enum_warning(S_W_O_enum_warning),
        .O_directory_sectors(S_W_O_directory_sectors),
        .O_enum_valid(S_W_O_enum_valid),
        .I_enum_ready(S_W_I_enum_ready),
        .O_enum_tag(S_W_O_enum_tag),
        .O_enum_path_length(S_W_O_enum_path_length),
        .O_enum_sector_budget(S_W_O_enum_sector_budget),
        .O_enum_path_valid(S_W_O_enum_path_valid),
        .I_enum_path_ready(S_W_I_enum_path_ready),
        .O_enum_path_data(S_W_O_enum_path_data),
        .O_enum_path_last(S_W_O_enum_path_last),
        .O_enum_stop(S_W_O_enum_stop),
        .O_enum_cancel(S_W_O_enum_cancel),
        .I_enum_entry_valid(S_W_I_enum_entry_valid),
        .O_enum_entry_ready(S_W_O_enum_entry_ready),
        .I_enum_attr(S_W_I_enum_attr),
        .I_enum_size(S_W_I_enum_size),
        .I_enum_first_cluster(S_W_I_enum_first_cluster),
        .I_enum_name_length(S_W_I_enum_name_length),
        .I_enum_name_valid(S_W_I_enum_name_valid),
        .O_enum_name_ready(S_W_O_enum_name_ready),
        .I_enum_name_data(S_W_I_enum_name_data),
        .I_enum_name_last(S_W_I_enum_name_last),
        .I_enum_done_valid(S_W_I_enum_done_valid),
        .O_enum_done_ready(S_W_O_enum_done_ready),
        .I_enum_tag(S_W_I_enum_tag),
        .I_enum_generation(S_W_I_enum_generation),
        .I_enum_sectors(S_W_I_enum_sectors),
        .I_enum_error(S_W_I_enum_error),
        .I_enum_storage_error(S_W_I_enum_storage_error),
        .I_enum_warning(S_W_I_enum_warning),
        .O_read_policy(S_policy_u_scan_O_read_policy),
        .O_active_order(S_runtime_u_scan_O_active_order),
        .O_active_base_order(S_runtime_u_scan_O_active_base_order),
        .O_active_base_order_explicit(S_runtime_u_scan_O_active_base_order_explicit),
        .I_reorder_valid(1'b0),
        .O_reorder_ready(S_runtime_u_scan_O_reorder_ready),
        .I_reorder_order(2'd0),
        .I_reorder_seed(32'd0),
        .I_reorder_generation(32'd0),
        .I_reorder_tag(16'd0),
        .I_reorder_current_index(6'd0),
        .I_reorder_abort(1'b0),
        .O_reorder_done_valid(S_runtime_u_scan_O_reorder_done_valid),
        .I_reorder_done_ready(1'b0),
        .O_reorder_error(S_runtime_u_scan_O_reorder_error),
        .O_reorder_tag(S_runtime_u_scan_O_reorder_tag),
        .O_reorder_generation(S_runtime_u_scan_O_reorder_generation),
        .O_reorder_revision(S_runtime_u_scan_O_reorder_revision),
        .O_reorder_current_index(S_runtime_u_scan_O_reorder_current_index),
        .I_order_override(1'b0),
        .I_runtime_order(2'd0)
    );

    fat32_core u_files (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_card_ready(S_F_I_card_ready),
        .I_unmount(S_F_I_unmount),
        .I_capacity_sectors(33'd100000),
        .I_mount_valid(S_F_I_mount_valid),
        .O_mount_ready(S_F_O_mount_ready),
        .O_mount_result_valid(S_F_O_mount_result_valid),
        .I_mount_result_ready(S_F_I_mount_result_ready),
        .O_mount_error(S_F_O_mount_error),
        .O_mount_storage_error(S_F_O_mount_storage_error),
        .O_mount_generation(S_F_O_mount_generation),
        .O_mounted(S_I_media_valid),
        .O_quiescent(S_F_O_quiescent),
        .O_generation(S_I_media_generation),
        .O_partition_lba(S_F_O_partition_lba),
        .O_volume_sectors(S_F_O_volume_sectors),
        .O_fat_lba(S_F_O_fat_lba),
        .O_data_lba(S_F_O_data_lba),
        .O_cluster_count(S_F_O_cluster_count),
        .O_root_cluster(S_F_O_root_cluster),
        .O_sectors_per_cluster(S_F_O_sectors_per_cluster),
        .O_cluster_shift(S_F_O_cluster_shift),
        .I_enum_valid(S_W_O_enum_valid),
        .O_enum_ready(S_W_I_enum_ready),
        .I_enum_tag(S_W_O_enum_tag),
        .I_enum_path_length(S_W_O_enum_path_length),
        .I_enum_sector_budget(S_W_O_enum_sector_budget),
        .I_enum_path_valid(S_W_O_enum_path_valid),
        .O_enum_path_ready(S_W_I_enum_path_ready),
        .I_enum_path_data(S_W_O_enum_path_data),
        .I_enum_path_last(S_W_O_enum_path_last),
        .I_enum_stop(S_W_O_enum_stop),
        .I_enum_cancel(S_W_O_enum_cancel),
        .O_enum_entry_valid(S_W_I_enum_entry_valid),
        .I_enum_entry_ready(S_W_O_enum_entry_ready),
        .O_enum_attr(S_W_I_enum_attr),
        .O_enum_size(S_W_I_enum_size),
        .O_enum_first_cluster(S_W_I_enum_first_cluster),
        .O_enum_alias(),
        .O_enum_name_length(S_W_I_enum_name_length),
        .O_enum_is_lfn(),
        .O_enum_name_valid(S_W_I_enum_name_valid),
        .I_enum_name_ready(S_W_O_enum_name_ready),
        .O_enum_name_data(S_W_I_enum_name_data),
        .O_enum_name_last(S_W_I_enum_name_last),
        .O_enum_done_valid(S_W_I_enum_done_valid),
        .I_enum_done_ready(S_W_O_enum_done_ready),
        .O_enum_tag(S_W_I_enum_tag),
        .O_enum_generation(S_W_I_enum_generation),
        .O_enum_sectors(S_W_I_enum_sectors),
        .O_enum_warning(S_W_I_enum_warning),
        .O_enum_error(S_W_I_enum_error),
        .O_enum_storage_error(S_W_I_enum_storage_error),
        .I_open_valid(S_W_O_fs_open_valid),
        .O_open_ready(S_W_I_fs_open_ready),
        .I_open_context(S_W_O_fs_open_context),
        .I_open_tag(S_W_O_fs_open_tag),
        .I_path_length(S_W_O_fs_path_length),
        .I_sector_budget(S_W_O_fs_sector_budget),
        .I_path_valid(S_W_O_fs_path_valid),
        .O_path_ready(S_W_I_fs_path_ready),
        .I_path_data(S_W_O_fs_path_data),
        .I_path_last(S_W_O_fs_path_last),
        .I_open_cancel(S_W_O_fs_open_cancel),
        .O_open_result_valid(S_W_I_fs_open_result_valid),
        .I_open_result_ready(S_W_O_fs_open_result_ready),
        .O_open_context(S_W_I_fs_open_context),
        .O_open_tag(S_W_I_fs_open_tag),
        .O_open_generation(S_W_I_fs_open_generation),
        .O_open_size(S_W_I_fs_open_size),
        .O_open_first_cluster(S_F_O_open_first_cluster),
        .O_open_sectors(S_F_O_open_sectors),
        .O_open_attr(S_F_O_open_attr),
        .O_open_error(S_W_I_fs_open_error),
        .O_open_storage_error(S_W_I_fs_open_storage_error),
        .O_open_warning(S_W_I_fs_open_warning),
        .O_byte_generation(S_W_I_fs_byte_generation),
        .O_done_generation(S_W_I_fs_done_generation),
        .O_cancel_done_generation(S_W_I_fs_cancel_done_generation),
        .I_close_valid(S_W_O_fs_close_valid),
        .O_close_ready(S_W_I_fs_close_ready),
        .I_close_context(S_W_O_fs_close_context),
        .I_read_valid(S_W_O_fs_read_valid),
        .O_read_ready(S_W_I_fs_read_ready),
        .I_read_context(S_W_O_fs_read_context),
        .I_read_priority(S_W_O_fs_read_priority),
        .I_offset(S_W_O_fs_offset),
        .I_length(S_W_O_fs_length),
        .I_epoch(S_W_O_fs_epoch),
        .I_urgent_context(3'd0),
        .O_byte_valid(S_W_I_fs_byte_valid),
        .I_byte_ready(S_W_O_fs_byte_ready),
        .O_byte_data(S_W_I_fs_byte_data),
        .O_byte_context(S_W_I_fs_byte_context),
        .O_byte_epoch(S_W_I_fs_byte_epoch),
        .O_byte_offset(S_W_I_fs_byte_offset),
        .O_byte_last(S_W_I_fs_byte_last),
        .O_done_valid(S_W_I_fs_done_valid),
        .I_done_ready(S_W_O_fs_done_ready),
        .O_done_context(S_W_I_fs_done_context),
        .O_done_epoch(S_W_I_fs_done_epoch),
        .O_done_bytes(S_W_I_fs_done_bytes),
        .O_done_eof(S_W_I_fs_done_eof),
        .O_done_error(S_W_I_fs_done_error),
        .O_done_storage_error(S_W_I_fs_done_storage_error),
        .I_cancel_valid(S_W_O_fs_cancel_valid),
        .O_cancel_ready(S_W_I_fs_cancel_ready),
        .I_cancel_context(S_W_O_fs_cancel_context),
        .I_cancel_epoch(S_W_O_fs_cancel_epoch),
        .O_cancel_done_valid(S_W_I_fs_cancel_done_valid),
        .I_cancel_done_ready(S_W_O_fs_cancel_done_ready),
        .O_cancel_done_context(S_W_I_fs_cancel_done_context),
        .O_cancel_done_epoch(S_W_I_fs_cancel_done_epoch),
        .O_sd_request_valid(S_F_O_sd_request_valid),
        .I_sd_request_ready(S_F_I_sd_request_ready),
        .O_sd_lba(S_F_O_sd_lba),
        .O_sd_count(S_F_O_sd_count),
        .O_sd_context(S_F_O_sd_context),
        .O_sd_priority(S_F_O_sd_priority),
        .O_sd_tag(S_F_O_sd_tag),
        .I_sd_byte_valid(S_F_I_sd_byte_valid),
        .O_sd_byte_ready(S_F_O_sd_byte_ready),
        .I_sd_byte_data(S_F_I_sd_byte_data),
        .I_sd_sector_last(S_F_I_sd_sector_last),
        .I_sd_request_last(S_F_I_sd_request_last),
        .I_sd_byte_context(S_F_I_sd_byte_context),
        .I_sd_byte_tag(S_F_I_sd_byte_tag),
        .I_sd_done_valid(S_F_I_sd_done_valid),
        .O_sd_done_ready(S_F_O_sd_done_ready),
        .I_sd_done_context(S_F_I_sd_done_context),
        .I_sd_done_tag(S_F_I_sd_done_tag),
        .I_sd_done_error(S_F_I_sd_done_error),
        .O_sd_cancel_valid(S_F_O_sd_cancel_valid),
        .I_sd_cancel_ready(S_F_I_sd_cancel_ready),
        .O_sd_cancel_context(S_F_O_sd_cancel_context),
        .O_sd_cancel_tag(S_F_O_sd_cancel_tag),
        .I_sd_cancel_done_valid(S_F_I_sd_cancel_done_valid),
        .O_sd_cancel_done_ready(S_F_O_sd_cancel_done_ready),
        .I_sd_cancel_done_context(S_F_I_sd_cancel_done_context),
        .I_sd_cancel_done_tag(S_F_I_sd_cancel_done_tag)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: media_index_scan_fat32 case %0d: %0s",S_case,message); $stop; end
    endtask
    task put16;
        input integer address,value;
        begin S_disk[address]=value; S_disk[address+1]=value>>8; end
    endtask
    task put32;
        input integer address;
        input [31:0] value;
        begin
            S_disk[address]=value[7:0]; S_disk[address+1]=value[15:8];
            S_disk[address+2]=value[23:16]; S_disk[address+3]=value[31:24];
        end
    endtask
    task short_entry;
        input integer address;
        input [87:0] alias;
        input [7:0] attr;
        input integer cluster,size;
        begin
            for(S_j=0;S_j<11;S_j=S_j+1) S_disk[address+S_j]=alias[(10-S_j)*8+:8];
            S_disk[address+11]=attr; put16(address+20,cluster>>16);
            put16(address+26,cluster); put32(address+28,size);
        end
    endtask
    task mount_card;
        begin
            @(negedge S_I_clk); S_F_I_mount_valid=1;
            @(posedge S_I_clk); while(!S_F_O_mount_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_F_I_mount_valid=0;
            wait(S_F_O_mount_result_valid); #1;
            if(S_F_O_mount_error!==0 || !S_I_media_valid ||
                S_I_media_generation!==S_mount_generation+1) fail("real mount/generation");
            S_mount_generation=S_mount_generation+1;
            @(negedge S_I_clk); S_F_I_mount_result_ready=1;
            @(negedge S_I_clk); S_F_I_mount_result_ready=0;
        end
    endtask

    // This is the SD host request contract, not a card or FAT32 replacement.
    // Each accepted sector snapshots its fixture bytes, then returns real valid/ready traffic.
    always @* begin
        S_F_I_sd_request_ready=S_host_state==0;
        S_F_I_sd_cancel_ready=S_host_state!=0 && !S_cancel_seen;
    end
    always @(posedge S_I_clk) begin
        S_cycle<=S_cycle+1;
        if(S_I_reset) begin
            S_host_state<=0; S_canceled<=0; S_cancel_seen<=0;
            S_F_I_sd_byte_valid<=0; S_F_I_sd_done_valid<=0; S_F_I_sd_cancel_done_valid<=0;
        end else begin
            if(S_F_O_sd_cancel_valid && S_F_I_sd_cancel_ready) begin
                if(S_F_O_sd_cancel_context!==S_F_I_sd_done_context || S_F_O_sd_cancel_tag!==S_F_I_sd_done_tag)
                    fail("physical cancel identity");
                S_canceled<=1; S_cancel_seen<=1;
            end
            case(S_host_state)
                0:if(S_F_O_sd_request_valid && S_F_I_sd_request_ready) begin
                    if(S_F_O_sd_count!==1) fail("sector request count");
                    case(S_F_O_sd_lba)
                        0:S_base=0; 32:S_base=512; 1232:S_base=1024;
                        1233:S_base=1536; 1234:S_base=2048; 1236:S_base=2560; 1238:S_base=3072;
                        default:begin S_base=0; fail("unexpected fixture LBA"); end
                    endcase
                    for(S_index=0;S_index<512;S_index=S_index+1) S_sector[S_index]=S_disk[S_base+S_index];
                    S_index=0; S_host_state<=1; S_canceled<=0; S_cancel_seen<=0;
                    S_injected<=S_F_O_sd_lba==S_fail_lba;
                    S_F_I_sd_byte_context<=S_F_O_sd_context; S_F_I_sd_byte_tag<=S_F_O_sd_tag;
                    S_F_I_sd_done_context<=S_F_O_sd_context; S_F_I_sd_done_tag<=S_F_O_sd_tag;
                    S_F_I_sd_cancel_done_context<=S_F_O_sd_context; S_F_I_sd_cancel_done_tag<=S_F_O_sd_tag;
                end
                1:begin
                    if(S_F_I_sd_byte_valid && S_F_O_sd_byte_ready) begin
                        S_F_I_sd_byte_valid<=0;
                        if(S_index==511 || S_canceled) begin S_delay=9; S_host_state<=2; end
                        else S_index=S_index+1;
                    end else if(!S_F_I_sd_byte_valid && S_cycle%4!=0) begin
                        S_F_I_sd_byte_data<=S_sector[S_index]; S_F_I_sd_byte_valid<=1;
                        S_F_I_sd_sector_last<=S_index==511; S_F_I_sd_request_last<=S_index==511;
                    end
                end
                2:if(S_delay==0) begin
                    S_F_I_sd_done_error<=S_canceled ? 4'd6 : (S_injected ? 4'd4 : 4'd0);
                    S_F_I_sd_done_valid<=1; S_host_state<=3;
                end else S_delay=S_delay-1;
                3:if(S_F_I_sd_done_valid && S_F_O_sd_done_ready) begin
                    S_F_I_sd_done_valid<=0; S_delay=40; S_host_state<=4;
                end
                4:if(S_delay==0) begin
                    if(S_cancel_seen) begin S_F_I_sd_cancel_done_valid<=1; S_host_state<=5; end
                    else if(!(S_F_O_sd_cancel_valid && S_F_I_sd_cancel_ready)) S_host_state<=0;
                end else S_delay=S_delay-1;
                5:if(S_F_I_sd_cancel_done_valid && S_F_O_sd_cancel_done_ready) begin
                    S_F_I_sd_cancel_done_valid<=0; S_cancel_acks=S_cancel_acks+1; S_host_state<=0;
                end
                default:fail("SD fixture state");
            endcase
            if(S_W_O_fs_close_valid && (u_files.S_pending[S_W_O_context] || u_files.S_cancel_busy))
                fail("source offered close before real file retirement");
        end
    end


    always @(posedge S_I_clk) if(!S_I_reset) begin
        if(S_W_O_enum_valid && S_W_I_enum_ready) begin
            if(S_W_O_enum_tag!==S_expected_enum_tag ||
                u_scan.u_source.O_lease_active || u_files.S_descriptors!=0)
                fail("enum identity / overlapped unretired list");
            S_enum_count=S_enum_count+1;
        end
    end
    task start_scan;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_W_I_start_valid=1; S_W_I_context=0; S_W_I_tag=tag;
            S_W_I_generation=S_I_media_generation; S_W_I_seed=1;
            S_W_I_sector_budget=8; S_W_I_directory_sector_budget=8;
            S_W_I_directory_duration=25; S_W_I_directory_transition_ms=600;
            S_W_I_directory_transition=3; S_W_I_directory_order=0;
            S_command_tag=tag; S_enum_count=0;
            @(posedge S_I_clk); while(!S_W_O_start_ready) @(posedge S_I_clk);
            if(u_files.S_descriptors!=0 || u_files.S_pending!=0 || !S_F_O_quiescent)
                fail("test lease granted before filesystem idle");
            @(negedge S_I_clk); S_W_I_start_valid=0;
            S_W_I_context=3; S_W_I_tag=0; S_W_I_generation=0; S_W_I_seed=0;
            S_W_I_sector_budget=0; S_W_I_directory_sector_budget=0;
            S_W_I_directory_duration=1; S_W_I_directory_transition_ms=200;
            S_W_I_directory_transition=0; S_W_I_directory_order=3;
        end
    endtask
    task finish_scan;
        input [3:0] error;
        input integer count,enums;
        input committed,directory,missing;
        begin
            wait(S_W_O_done_valid); #1;
            if(S_W_O_error!==error || S_W_O_count!==count || S_W_O_committed!==committed ||
                S_W_O_used_directory!==directory || S_W_O_list_missing!==missing ||
                S_W_O_tag!==S_command_tag || S_W_O_generation!==S_I_media_generation || S_enum_count!==enums)
                fail("automatic scan final result/identity/enum count");
            if(committed) begin
                S_revision=S_revision+1;
                if(!S_W_O_active_valid || S_W_O_active_count!==count || S_W_O_active_revision!==S_revision)
                    fail("single shared index atomic commit");
            end else if(S_W_O_active_revision!==S_revision) fail("failed scan changed index revision");
            if(u_files.S_descriptors!=0 || u_files.S_pending!=0 || u_files.S_cancel_busy || !S_F_O_quiescent ||
                u_scan.u_source.O_busy || u_scan.u_builder.O_busy) fail("done before actual child/I/O retirement");
            S_held={S_W_O_error,S_W_O_count,S_W_O_committed,S_W_O_used_directory,S_W_O_list_missing,
                S_W_O_list_warning,S_W_O_directory_warning,S_W_O_tag,S_W_O_generation};
            repeat(6) begin
                @(negedge S_I_clk);
                if(!S_W_O_done_valid || !S_W_O_lease_active || S_W_O_start_ready ||
                    {S_W_O_error,S_W_O_count,S_W_O_committed,S_W_O_used_directory,S_W_O_list_missing,
                     S_W_O_list_warning,S_W_O_directory_warning,S_W_O_tag,S_W_O_generation}!==S_held)
                    fail("scan result backpressure / lease retention");
            end
            S_W_I_done_ready=1;
            @(negedge S_I_clk); S_W_I_done_ready=0;
            if(S_W_O_lease_active) fail("outer lease not released");
        end
    endtask
    task check_record;
        input [5:0] index;
        input [511:0] path;
        input integer length;
        input [319:0] title;
        input integer title_length,duration;
        begin
            @(negedge S_I_clk); S_W_I_acquire_valid=1;
            @(posedge S_I_clk); while(!S_W_O_acquire_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_W_I_acquire_valid=0;
            if(!S_W_O_snapshot_valid || S_W_O_snapshot_generation!==S_I_media_generation) fail("snapshot identity");
            for(S_i=0;S_i<length+title_length+2;S_i=S_i+1) begin
                S_W_I_read_valid=1; S_W_I_read_index=index; S_W_I_read_tag=16'h9876;
                S_W_I_read_kind=S_i<=length ? 0 : 2;
                S_W_I_read_address=S_i<=length ? S_i : S_i-length-1;
                @(posedge S_I_clk); while(!S_W_O_read_ready) @(posedge S_I_clk);
                @(negedge S_I_clk); S_W_I_read_valid=0;
                wait(S_W_O_read_result_valid); #1;
                if(S_W_O_read_error!==0 || S_W_O_read_tag!==16'h9876 ||
                    S_W_O_read_file_length!==length || S_W_O_read_title_length!==title_length ||
                    S_W_O_read_audio_length!==0 || S_W_O_read_duration!==duration ||
                    S_W_O_read_data!==(S_i<length ? path[(length-1-S_i)*8+:8] :
                      S_i==length || S_i==length+title_length+1 ? 8'd0 : title[(title_length-1-(S_i-length-1))*8+:8]))
                    fail("real scan snapshot path/title/defaults");
                if(duration==25 && (S_W_O_read_transition!==3 || S_W_O_read_transition_ms!==600))
                    fail("directory command defaults not retained");
                @(negedge S_I_clk); S_W_I_read_result_ready=1;
                @(negedge S_I_clk); S_W_I_read_result_ready=0;
            end
            S_W_I_release_valid=1;
            @(posedge S_I_clk); while(!S_W_O_release_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_W_I_release_valid=0;
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_W_I_abort=1; @(negedge S_I_clk); S_W_I_abort=0; end
    endtask
    task restore_playlist;
        begin
            short_entry(1536,"PLAYLISTTXT",32,4,700);
            for(S_i=0;S_i<50;S_i=S_i+1) S_disk[2048+S_i]=S_text[(49-S_i)*8+:8];
        end
    endtask
    task check_held_list;
        begin
            if(!S_W_O_snapshot_valid || S_W_O_snapshot_count!==1 ||
                S_W_O_snapshot_revision!==1) fail("old list snapshot lost across directory commit");
            @(negedge S_I_clk); S_W_I_read_valid=1; S_W_I_read_index=0;
            S_W_I_read_kind=0; S_W_I_read_address=0; S_W_I_read_tag=16'h9877;
            @(posedge S_I_clk); while(!S_W_O_read_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_W_I_read_valid=0;
            wait(S_W_O_read_result_valid); #1;
            if(S_W_O_read_error!==0 || S_W_O_read_data!==8'h2f || S_W_O_read_file_length!==13 ||
                S_W_O_read_duration!==10 || S_W_O_read_tag!==16'h9877) fail("old bank was overwritten");
            @(negedge S_I_clk); S_W_I_read_result_ready=1;
            @(negedge S_I_clk); S_W_I_read_result_ready=0;
        end
    endtask

    initial begin
        S_I_reset=1; S_F_I_card_ready=1; S_W_I_lease_grant=1;
        for(S_i=0;S_i<4096;S_i=S_i+1) S_disk[S_i]=0;
        S_disk[0]=8'heb; S_disk[2]=8'h90; put16(11,512); S_disk[13]=1;
        put16(14,32); S_disk[16]=2; put32(32,70000); put32(36,600);
        put32(44,2); put16(510,16'haa55);
        put32(512+2*4,32'h0fffffff); put32(512+3*4,32'h0fffffff);
        put32(512+4*4,6); put32(512+6*4,32'h0fffffff); put32(512+8*4,32'h0fffffff);
        short_entry(1024,"PLAY       ",16,3,0); short_entry(1056,"ROOT    BMP",32,10,54);
        short_entry(1088,"README  TXT",32,14,20);
        short_entry(1536,"PLAYLISTTXT",32,4,700); short_entry(1568,"IMG        ",16,8,0);
        short_entry(3072,"B       BMP",32,10,54); short_entry(3104,"A       BMP",32,11,100);
        short_entry(3136,"TINY    BMP",32,12,53); short_entry(3168,"FOLDER     ",16,13,0);
        short_entry(3200,"NOTE    TXT",32,14,20);
        for(S_i=0;S_i<700;S_i=S_i+1) begin
            if(S_i<50) S_disk[2048+S_i]=S_text[(49-S_i)*8+:8];
            else case((S_i-50)%3)
                0:S_disk[(S_i<512 ? 2048 : 2560)+(S_i<512 ? S_i : S_i-512)]=";";
                1:S_disk[(S_i<512 ? 2048 : 2560)+(S_i<512 ? S_i : S_i-512)]="x";
                2:S_disk[(S_i<512 ? 2048 : 2560)+(S_i<512 ? S_i : S_i-512)]=8'h0a;
            endcase
        end
        S_disk[2560+187]=8'h0a;
        #35; @(negedge S_I_clk); S_I_reset=0;


        mount_card;
        start_scan(16'h9400); finish_scan(0,1,0,1,0,0);
        check_record(0,"/PLAY/one.bmp",13,"one",3,10);
        // Keep the first list snapshot while a directory scan commits the other bank.
        @(negedge S_I_clk); S_W_I_acquire_valid=1;
        @(posedge S_I_clk); while(!S_W_O_acquire_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_W_I_acquire_valid=0;
        // Missing playlist automatically selects directory; no test drives a mode switch.
        S_disk[1536]=8'he5;
        start_scan(16'h9401); finish_scan(0,2,1,1,1,1);
        if(S_W_O_list_source_error!==5 || S_W_O_file_error!==14 || S_W_O_directory_warning!==4)
            fail("missing list / primary directory diagnostics");
        check_held_list;
        // The next build must wait for that old bank. Cancellation closes the file
        // without waiting for a builder terminal from a start that never happened.
        restore_playlist; start_scan(16'h9420);
        wait(u_scan.u_source.O_build_start_valid);
        repeat(6) begin
            @(negedge S_I_clk);
            if(u_scan.S_builder_ready || S_W_O_done_valid) fail("retained bank did not block new builder start");
        end
        pulse_abort; finish_scan(2,0,0,0,0,0); check_held_list;
        S_W_I_release_valid=1;
        @(posedge S_I_clk); while(!S_W_O_release_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_W_I_release_valid=0;
        check_record(0,"/PLAY/IMG/A.BMP",15,"A",1,25);
        check_record(1,"/PLAY/IMG/B.BMP",15,"B",1,25);
        // Zero-length list still does a real file read/close and joins both terminals.
        short_entry(1536,"PLAYLISTTXT",32,4,0);
        start_scan(16'h9402); finish_scan(0,2,1,1,1,0);
        if(S_W_O_list_source_error!==0 || S_W_O_list_build_error!==5) fail("empty list join");
        // Nonempty comments-only list takes the same zero-candidate path.
        restore_playlist;
        for(S_i=0;S_i<50;S_i=S_i+1) S_disk[2048+S_i]=8'h0a;
        start_scan(16'h9403); finish_scan(0,2,1,1,1,0);
        // Missing IMG falls back once more to root, including tag wrap across both phases.
        S_disk[1536]=8'he5; S_disk[1568]=8'he5;
        start_scan(16'hffff); finish_scan(0,1,2,1,1,1);
        check_record(0,"/ROOT.BMP",9,"ROOT",4,25);
        if(S_W_O_directory_primary_error!==14 || S_W_O_directory_warning!==8'h21)
            fail("root fallback diagnostic identity");
        short_entry(1568,"IMG        ",16,8,0); S_disk[3072]=0; S_disk[1056]=8'he5;
        start_scan(16'h9405); finish_scan(5,0,2,0,1,1);
        if(!S_W_O_active_valid) fail("empty directory replaced old active");
        check_record(0,"/ROOT.BMP",9,"ROOT",4,25);
        short_entry(1056,"ROOT    BMP",32,10,54); short_entry(3072,"B       BMP",32,10,54);
        // A playlist read failure must not be relabelled as directory fallback.
        restore_playlist; S_fail_lba=1234;
        start_scan(16'h9406); finish_scan(1,0,0,0,0,0);
        if(S_W_O_storage_error!==4) fail("list storage error lost");
        S_fail_lba=1238; S_disk[1536]=8'he5;
        start_scan(16'h9407); finish_scan(1,0,1,0,1,1);
        if(S_W_O_directory_storage_error!==4 || S_W_O_directory_warning[0]) fail("directory I/O failure fell back");
        S_fail_lba=32'hffffffff; restore_playlist;
        start_scan(16'h9408);
        wait(S_F_O_sd_request_valid && S_F_O_sd_lba==1234);
        @(posedge S_I_clk); while(!S_F_I_sd_request_ready) @(posedge S_I_clk);
        S_before=S_cancel_acks; pulse_abort; finish_scan(2,0,0,0,0,0);
        if(S_cancel_acks<=S_before) fail("list cancel skipped physical acknowledgement");
        S_disk[1536]=8'he5;
        start_scan(16'h9409);
        wait(S_F_O_sd_request_valid && S_F_O_sd_lba==1238);
        @(posedge S_I_clk); while(!S_F_I_sd_request_ready) @(posedge S_I_clk);
        S_before=S_cancel_acks; pulse_abort; finish_scan(2,0,1,0,1,1);
        if(S_cancel_acks<=S_before) fail("directory cancel skipped physical acknowledgement");
        start_scan(16'h9410);
        wait(S_F_O_sd_request_valid && S_F_O_sd_lba==1238);
        @(posedge S_I_clk); while(!S_F_I_sd_request_ready) @(posedge S_I_clk);
        @(negedge S_I_clk); S_F_I_card_ready=0;
        repeat(3) @(negedge S_I_clk);
        S_F_I_card_ready=1; finish_scan(3,0,1,0,1,1);
        if(S_I_media_valid || S_W_O_active_valid) fail("short media loss revived mounted/index state");
        mount_card; start_scan(16'h9411); finish_scan(0,2,1,1,1,1);
        check_record(0,"/PLAY/IMG/A.BMP",15,"A",1,25);
        S_test_pass=1;
        $display("PASS: automatic playlist/directory scan with real FAT32 and one retained index");
        $finish;
    end
    initial begin #200000000; fail("watchdog: automatic scan/core did not retire"); end
endmodule
