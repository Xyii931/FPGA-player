`timescale 1ns/1ps
// Real WAV file owner; real core and audio slot; SD sectors and a PCM sink are test endpoints.
module tb_wav_file_fat32;
    reg  S_I_clk=0;
    reg  S_I_reset=0;
    wire  S_I_media_valid;
    wire [31:0] S_I_media_generation;
    reg  S_I_start_valid=0;
    wire  S_O_start_ready;
    wire  S_O_lease_request;
    reg  S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [1:0] S_I_read_priority=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_sector_budget=0;
    reg [6:0] S_I_path_length=0;
    reg  S_I_path_valid=0;
    wire  S_O_path_ready;
    reg [7:0] S_I_path_data=0;
    reg  S_I_path_last=0;
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
    wire  S_O_track_started;
    wire  S_O_track_start_valid;
    wire  S_I_track_start_ready;
    wire [31:0] S_O_track_file_size;
    wire [15:0] S_O_track_epoch;
    wire  S_O_track_byte_valid;
    wire  S_I_track_byte_ready;
    wire [7:0] S_O_track_byte_data;
    wire  S_O_track_byte_last;
    wire [15:0] S_O_track_byte_epoch;
    wire  S_O_track_stream_error;
    wire [15:0] S_O_track_stream_error_epoch;
    wire  S_I_track_cancel_valid;
    wire  S_O_track_cancel_ready;
    wire [15:0] S_I_track_cancel_epoch;
    wire  S_I_io_retire_request;
    wire  S_O_io_retired;
    wire  S_O_fs_open_valid;
    wire  S_I_fs_open_ready;
    wire [1:0] S_O_fs_open_context;
    wire [15:0] S_O_fs_open_tag;
    wire [6:0] S_O_fs_path_length;
    wire [31:0] S_O_fs_sector_budget;
    wire  S_O_fs_path_valid;
    wire  S_I_fs_path_ready;
    wire [7:0] S_O_fs_path_data;
    wire  S_O_fs_path_last;
    wire  S_O_fs_open_cancel;
    wire  S_I_fs_open_result_valid;
    wire  S_O_fs_open_result_ready;
    wire [1:0] S_I_fs_open_context;
    wire [15:0] S_I_fs_open_tag;
    wire [31:0] S_I_fs_open_generation;
    wire [31:0] S_I_fs_open_size;
    wire [7:0] S_I_fs_open_error;
    wire [3:0] S_I_fs_open_storage_error;
    wire [2:0] S_I_fs_open_warning;
    wire  S_O_fs_read_valid;
    wire  S_I_fs_read_ready;
    wire [1:0] S_O_fs_read_context;
    wire [1:0] S_O_fs_read_priority;
    wire [31:0] S_O_fs_offset;
    wire [31:0] S_O_fs_length;
    wire [15:0] S_O_fs_epoch;
    wire  S_I_fs_byte_valid;
    wire  S_O_fs_byte_ready;
    wire [7:0] S_I_fs_byte_data;
    wire [1:0] S_I_fs_byte_context;
    wire [15:0] S_I_fs_byte_epoch;
    wire [31:0] S_I_fs_byte_generation;
    wire [31:0] S_I_fs_byte_offset;
    wire  S_I_fs_byte_last;
    wire  S_I_fs_done_valid;
    wire  S_O_fs_done_ready;
    wire [1:0] S_I_fs_done_context;
    wire [15:0] S_I_fs_done_epoch;
    wire [31:0] S_I_fs_done_generation;
    wire [31:0] S_I_fs_done_bytes;
    wire  S_I_fs_done_eof;
    wire [7:0] S_I_fs_done_error;
    wire [3:0] S_I_fs_done_storage_error;
    wire  S_O_fs_cancel_valid;
    wire  S_I_fs_cancel_ready;
    wire [1:0] S_O_fs_cancel_context;
    wire [15:0] S_O_fs_cancel_epoch;
    wire  S_I_fs_cancel_done_valid;
    wire  S_O_fs_cancel_done_ready;
    wire [1:0] S_I_fs_cancel_done_context;
    wire [15:0] S_I_fs_cancel_done_epoch;
    wire [31:0] S_I_fs_cancel_done_generation;
    wire  S_O_fs_close_valid;
    wire  S_I_fs_close_ready;
    wire [1:0] S_O_fs_close_context;
    wav_file_source u_source (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_read_priority(S_I_read_priority),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_sector_budget(S_I_sector_budget),
        .I_path_length(S_I_path_length),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
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
        .O_track_started(S_O_track_started),
        .O_track_start_valid(S_O_track_start_valid),
        .I_track_start_ready(S_I_track_start_ready),
        .O_track_file_size(S_O_track_file_size),
        .O_track_epoch(S_O_track_epoch),
        .O_track_byte_valid(S_O_track_byte_valid),
        .I_track_byte_ready(S_I_track_byte_ready),
        .O_track_byte_data(S_O_track_byte_data),
        .O_track_byte_last(S_O_track_byte_last),
        .O_track_byte_epoch(S_O_track_byte_epoch),
        .O_track_stream_error(S_O_track_stream_error),
        .O_track_stream_error_epoch(S_O_track_stream_error_epoch),
        .I_track_cancel_valid(S_I_track_cancel_valid),
        .O_track_cancel_ready(S_O_track_cancel_ready),
        .I_track_cancel_epoch(S_I_track_cancel_epoch),
        .I_io_retire_request(S_I_io_retire_request),
        .O_io_retired(S_O_io_retired),
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
        .O_fs_close_context(S_O_fs_close_context),
        .I_start_index(32'd0),
        .O_track_start_index()
    );
    always #4 S_I_clk=~S_I_clk;
    reg  S_F_I_card_ready=0;
    reg  S_F_I_unmount=0;
    reg  S_F_I_mount_valid=0;
    wire  S_F_O_mount_ready;
    wire  S_F_O_mount_result_valid;
    reg  S_F_I_mount_result_ready=0;
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
    reg  S_F_I_sd_request_ready=0;
    wire [31:0] S_F_O_sd_lba;
    wire [7:0] S_F_O_sd_count;
    wire [1:0] S_F_O_sd_context;
    wire [1:0] S_F_O_sd_priority;
    wire [15:0] S_F_O_sd_tag;
    reg  S_F_I_sd_byte_valid=0;
    wire  S_F_O_sd_byte_ready;
    reg [7:0] S_F_I_sd_byte_data=0;
    reg  S_F_I_sd_sector_last=0;
    reg  S_F_I_sd_request_last=0;
    reg [1:0] S_F_I_sd_byte_context=0;
    reg [15:0] S_F_I_sd_byte_tag=0;
    reg  S_F_I_sd_done_valid=0;
    wire  S_F_O_sd_done_ready;
    reg [1:0] S_F_I_sd_done_context=0;
    reg [15:0] S_F_I_sd_done_tag=0;
    reg [3:0] S_F_I_sd_done_error=0;
    wire  S_F_O_sd_cancel_valid;
    reg  S_F_I_sd_cancel_ready=0;
    wire [1:0] S_F_O_sd_cancel_context;
    wire [15:0] S_F_O_sd_cancel_tag;
    reg  S_F_I_sd_cancel_done_valid=0;
    wire  S_F_O_sd_cancel_done_ready;
    reg [1:0] S_F_I_sd_cancel_done_context=0;
    reg [15:0] S_F_I_sd_cancel_done_tag=0;
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
        .I_enum_valid(1'd0),
        .O_enum_ready(),
        .I_enum_tag(16'd0),
        .I_enum_path_length(7'd0),
        .I_enum_sector_budget(32'd0),
        .I_enum_path_valid(1'd0),
        .O_enum_path_ready(),
        .I_enum_path_data(8'd0),
        .I_enum_path_last(1'd0),
        .I_enum_stop(1'd0),
        .I_enum_cancel(1'd0),
        .O_enum_entry_valid(),
        .I_enum_entry_ready(1'd0),
        .O_enum_attr(),
        .O_enum_size(),
        .O_enum_first_cluster(),
        .O_enum_alias(),
        .O_enum_name_length(),
        .O_enum_is_lfn(),
        .O_enum_name_valid(),
        .I_enum_name_ready(1'd0),
        .O_enum_name_data(),
        .O_enum_name_last(),
        .O_enum_done_valid(),
        .I_enum_done_ready(1'd0),
        .O_enum_tag(),
        .O_enum_generation(),
        .O_enum_sectors(),
        .O_enum_warning(),
        .O_enum_error(),
        .O_enum_storage_error(),
        .I_open_valid(S_O_fs_open_valid),
        .O_open_ready(S_I_fs_open_ready),
        .I_open_context(S_O_fs_open_context),
        .I_open_tag(S_O_fs_open_tag),
        .I_path_length(S_O_fs_path_length),
        .I_sector_budget(S_O_fs_sector_budget),
        .I_path_valid(S_O_fs_path_valid),
        .O_path_ready(S_I_fs_path_ready),
        .I_path_data(S_O_fs_path_data),
        .I_path_last(S_O_fs_path_last),
        .I_open_cancel(S_O_fs_open_cancel),
        .O_open_result_valid(S_I_fs_open_result_valid),
        .I_open_result_ready(S_O_fs_open_result_ready),
        .O_open_context(S_I_fs_open_context),
        .O_open_tag(S_I_fs_open_tag),
        .O_open_generation(S_I_fs_open_generation),
        .O_open_size(S_I_fs_open_size),
        .O_open_first_cluster(S_F_O_open_first_cluster),
        .O_open_sectors(S_F_O_open_sectors),
        .O_open_attr(S_F_O_open_attr),
        .O_open_error(S_I_fs_open_error),
        .O_open_storage_error(S_I_fs_open_storage_error),
        .O_open_warning(S_I_fs_open_warning),
        .O_byte_generation(S_I_fs_byte_generation),
        .O_done_generation(S_I_fs_done_generation),
        .O_cancel_done_generation(S_I_fs_cancel_done_generation),
        .I_close_valid(S_O_fs_close_valid),
        .O_close_ready(S_I_fs_close_ready),
        .I_close_context(S_O_fs_close_context),
        .I_read_valid(S_O_fs_read_valid),
        .O_read_ready(S_I_fs_read_ready),
        .I_read_context(S_O_fs_read_context),
        .I_read_priority(S_O_fs_read_priority),
        .I_offset(S_O_fs_offset),
        .I_length(S_O_fs_length),
        .I_epoch(S_O_fs_epoch),
        .I_urgent_context(3'd0),
        .O_byte_valid(S_I_fs_byte_valid),
        .I_byte_ready(S_O_fs_byte_ready),
        .O_byte_data(S_I_fs_byte_data),
        .O_byte_context(S_I_fs_byte_context),
        .O_byte_epoch(S_I_fs_byte_epoch),
        .O_byte_offset(S_I_fs_byte_offset),
        .O_byte_last(S_I_fs_byte_last),
        .O_done_valid(S_I_fs_done_valid),
        .I_done_ready(S_O_fs_done_ready),
        .O_done_context(S_I_fs_done_context),
        .O_done_epoch(S_I_fs_done_epoch),
        .O_done_bytes(S_I_fs_done_bytes),
        .O_done_eof(S_I_fs_done_eof),
        .O_done_error(S_I_fs_done_error),
        .O_done_storage_error(S_I_fs_done_storage_error),
        .I_cancel_valid(S_O_fs_cancel_valid),
        .O_cancel_ready(S_I_fs_cancel_ready),
        .I_cancel_context(S_O_fs_cancel_context),
        .I_cancel_epoch(S_O_fs_cancel_epoch),
        .O_cancel_done_valid(S_I_fs_cancel_done_valid),
        .I_cancel_done_ready(S_O_fs_cancel_done_ready),
        .O_cancel_done_context(S_I_fs_cancel_done_context),
        .O_cancel_done_epoch(S_I_fs_cancel_done_epoch),
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



    reg S_audio_clk=0,S_audio_run=1,S_pcm_enable=0,S_recycle=0,S_event_ready=1;
    wire S_recycle_ready,S_recycle_done,S_slot_available,S_slot_stop,S_slot_clear;
    wire S_pcm_valid,S_load_valid,S_decode_busy,S_failed,S_event_valid,S_event_header;
    wire S_prefilled,S_need_fill,S_discarded;
    wire [4:0] S_level;
    wire [23:0] S_left,S_right;
    wire [31:0] S_written,S_total,S_event_total,S_event_written;
    wire [15:0] S_event_epoch;
    wire [3:0] S_event_error;
    always #20 if(S_audio_run) S_audio_clk=~S_audio_clk;
    // No PCM sink pipeline exists here: once stop is visible, it owns no references.
    wav_audio_slot #(.FIFO_ADDR_BITS(4),.PREFILL_FRAMES(8),.LOW_FRAMES(4)) u_slot (
        .I_decode_clk(S_I_clk),
        .I_audio_clk(S_audio_clk),
        .I_async_reset(S_I_reset),
        .I_start_valid(S_O_track_start_valid),
        .O_start_ready(S_I_track_start_ready),
        .I_file_size(S_O_track_file_size),
        .I_epoch(S_O_track_epoch),
        .I_byte_valid(S_O_track_byte_valid),
        .I_byte_last(S_O_track_byte_last),
        .I_byte_data(S_O_track_byte_data),
        .I_byte_epoch(S_O_track_byte_epoch),
        .O_byte_ready(S_I_track_byte_ready),
        .O_byte_discarded(S_discarded),
        .I_stream_error_valid(S_O_track_stream_error),
        .I_stream_error_epoch(S_O_track_stream_error_epoch),
        .I_recycle_valid(S_recycle),
        .O_recycle_ready(S_recycle_ready),
        .O_recycle_done(S_recycle_done),
        .O_available(S_slot_available),
        .O_cancel_valid(S_I_track_cancel_valid),
        .I_cancel_ready(S_O_track_cancel_ready),
        .O_cancel_epoch(S_I_track_cancel_epoch),
        .O_io_retire_request(S_I_io_retire_request),
        .I_io_retired(S_O_io_retired),
        .O_source_busy(S_decode_busy),
        .O_written_frames(S_written),
        .O_stop(S_slot_stop),
        .O_clear(S_slot_clear),
        .I_idle(S_slot_stop),
        .O_pcm_valid(S_pcm_valid),
        .I_pcm_ready(S_pcm_enable && !S_slot_stop && !S_slot_clear),
        .O_left(S_left),
        .O_right(S_right),
        .O_level(S_level),
        .O_prefilled(S_prefilled),
        .O_need_fill(S_need_fill),
        .O_failed(S_failed),
        .O_load_valid(S_load_valid),
        .I_load_ready(1'b1),
        .O_total_frames(S_total),
        .O_event_valid(S_event_valid),
        .I_event_ready(S_event_ready),
        .O_event_header(S_event_header),
        .O_event_epoch(S_event_epoch),
        .O_event_total_frames(S_event_total),
        .O_event_written_frames(S_event_written),
        .O_event_error(S_event_error),
        .I_start_index(32'd0),
        .O_start_index()
    );

    reg S_test_pass=0;
    integer S_case=0,S_bytes=0,S_reads=0,S_closes=0,S_track_starts=0;
    reg [1:0] S_expected_priority=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: WAV file case %0d: %0s",S_case,message); $stop; end
    endtask
    always @(posedge S_I_clk) begin
        if(!S_I_reset) begin
            if(S_O_fs_read_valid && S_I_fs_read_ready) begin
                S_reads=S_reads+1;
                if(S_O_fs_offset!==0 || S_O_fs_length!==S_O_file_size || S_O_fs_epoch!==S_O_tag ||
                    S_O_fs_read_context!==S_O_context || S_O_fs_read_priority!==S_expected_priority)
                    fail("read identity/length/priority");
            end
            if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
            if(S_O_track_start_valid && S_I_track_start_ready) begin
                S_track_starts=S_track_starts+1;
                if(S_O_track_epoch!==S_O_tag || S_O_track_file_size!==S_O_file_size) fail("track start identity");
            end
            if(S_O_track_byte_valid && S_I_track_byte_ready) begin
                if(S_O_track_byte_epoch!==S_O_tag || S_O_track_byte_last!==(S_bytes+1==S_O_file_size))
                    fail("track byte epoch/last");
                S_bytes=S_bytes+1;
            end
            if(S_O_io_retired && (S_O_fs_open_valid || S_O_fs_read_valid || S_O_fs_cancel_valid || S_O_fs_close_valid))
                fail("retired while file obligations offered");
        end
    end
    task start_source;
        input [1:0] context;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_context=context; S_I_tag=tag; S_I_generation=S_I_media_generation;
            S_I_path_length=9; S_I_sector_budget=8; S_I_read_priority=S_expected_priority;
            S_bytes=0; S_I_start_valid=1;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task send_path;
        reg [71:0] path;
        integer k;
        begin
            path="/TEST.WAV";
            for(k=0;k<9;k=k+1) begin
                @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=path[(8-k)*8+:8]; S_I_path_last=k==8;
                @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
                if(S_O_fs_path_data!==path[(8-k)*8+:8] || S_O_fs_path_last!==(k==8) || S_O_fs_path_length!==9)
                    fail("path forwarding/snapshot");
            end
            @(negedge S_I_clk); S_I_path_valid=0; S_I_path_last=0;
        end
    endtask
    task take_result;
        input [3:0] error;
        reg [101:0] terminal;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || !S_O_lease_active || S_O_start_ready) fail("file terminal/lease");
            terminal={S_O_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_track_started};
            repeat(5) begin
                @(negedge S_I_clk);
                if(!S_O_done_valid || {S_O_error,S_O_file_error,S_O_storage_error,S_O_path_warning,
                    S_O_context,S_O_tag,S_O_generation,S_O_file_size,S_O_track_started}!==terminal)
                    fail("file terminal backpressure");
            end
            S_I_done_ready=1; @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_busy) fail("file lease did not release");
        end
    endtask
    task pulse_abort;
        begin @(negedge S_I_clk); S_I_abort=1; @(negedge S_I_clk); S_I_abort=0; end
    endtask
    initial begin #20000000; fail("watchdog"); end

    reg [7:0] S_disk[0:3071],S_sector[0:511],S_wav[0:699];
    reg [2:0] S_host_state=0;
    reg S_canceled=0,S_cancel_seen=0,S_injected=0,S_check_pcm=1;
    reg [31:0] S_fail_lba=32'hffffffff,S_mount_generation=0;
    integer S_cycle=0,S_index=0,S_base=0,S_delay=0,S_cancel_acks=0,S_before,S_i,S_j,k;
    integer S_frames=40,S_pcm_count=0,S_headers=0,S_terminals=0,S_terminal_error=0;
    reg [15:0] S_seed=16'h8100,S_word;
    reg [15:0] S_expected_epoch=0;
    reg S_event_held=0;
    reg [84:0] S_held_event;
    task wav32;
        input integer address;
        input [31:0] value;
        begin S_wav[address]=value; S_wav[address+1]=value>>8; S_wav[address+2]=value>>16; S_wav[address+3]=value>>24; end
    endtask
    task make_wav;
        input integer frames;
        input [15:0] seed;
        begin
            S_frames=frames; S_seed=seed;
            for(S_i=0;S_i<700;S_i=S_i+1) S_wav[S_i]=0;
            {S_wav[0],S_wav[1],S_wav[2],S_wav[3]}="RIFF";
            wav32(4,502+frames*4); {S_wav[8],S_wav[9],S_wav[10],S_wav[11]}="WAVE";
            {S_wav[12],S_wav[13],S_wav[14],S_wav[15]}="fmt "; wav32(16,16);
            S_wav[20]=1; S_wav[22]=2; wav32(24,48000); wav32(28,192000); S_wav[32]=4; S_wav[34]=16;
            {S_wav[36],S_wav[37],S_wav[38],S_wav[39]}="JUNK"; wav32(40,457); S_wav[501]=8'hee;
            {S_wav[502],S_wav[503],S_wav[504],S_wav[505]}="data"; wav32(506,frames*4);
            for(S_i=0;S_i<frames;S_i=S_i+1) begin
                S_word=seed+S_i*17;
                S_wav[510+S_i*4]=S_word; S_wav[511+S_i*4]=S_word>>8;
                S_wav[512+S_i*4]=~S_word[7:0]; S_wav[513+S_i*4]=~S_word[15:8];
            end
            for(S_i=510+frames*4;S_i<700;S_i=S_i+1) S_wav[S_i]=8'ha5;
            for(S_i=0;S_i<700;S_i=S_i+1) S_disk[(S_i<512 ? 2048 : 2560)+(S_i<512 ? S_i : S_i-512)]=S_wav[S_i];
        end
    endtask
    always @(posedge S_audio_clk) begin
        if(S_slot_clear) S_event_held<=0;
        else begin
            if(S_event_held && (!S_event_valid || {S_event_header,S_event_epoch,S_event_total,S_event_written,S_event_error}!==S_held_event))
                fail("audio event changed under backpressure");
            S_event_held<=S_event_valid && !S_event_ready;
            S_held_event<={S_event_header,S_event_epoch,S_event_total,S_event_written,S_event_error};
            if(S_event_valid && S_event_ready) begin
                if(S_event_epoch!==S_expected_epoch) fail("event epoch leaked across flush");
                if(S_event_header) begin
                    S_headers=S_headers+1; if(S_check_pcm && S_event_total!==S_frames) fail("declared frames");
                end else begin
                    S_terminals=S_terminals+1; S_terminal_error=S_event_error;
                    if(S_check_pcm && (S_event_error!==0 || S_event_written!==S_frames)) fail("terminal frames/error");
                end
            end
            if(S_pcm_valid && S_pcm_enable && !S_slot_stop) begin
                if(S_check_pcm) begin
                    S_word=S_seed+S_pcm_count*17;
                    if(S_pcm_count>=S_frames || S_left!=={S_word,8'd0} || S_right!=={~S_word,8'd0})
                        fail("fragmented WAV PCM24/stereo/order");
                end
                S_pcm_count=S_pcm_count+1;
            end
        end
    end
    task launch;
        input [1:0] context;
        input [15:0] tag;
        begin
            if(u_files.S_descriptors[context] || u_files.S_pending[context] || u_files.S_cancel_busy || u_files.S_open_state!=0)
                fail("fixture granted occupied namespace/context");
            S_expected_epoch=tag; S_pcm_count=0; S_headers=0; S_terminals=0; S_terminal_error=0;
            start_source(context,tag); send_path;
        end
    endtask
    task finish_file;
        input [3:0] error;
        begin
            wait(S_O_done_valid);
            if(u_files.S_descriptors[S_O_context] || u_files.S_pending[S_O_context] || u_files.S_cancel_busy)
                fail("file done before core retirement/close");
            take_result(error);
        end
    endtask
    task request_recycle;
        begin
            @(negedge S_I_clk); S_recycle=1;
            @(posedge S_I_clk); while(!S_recycle_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_recycle=0;
        end
    endtask
    task finish_recycle;
        begin
            wait(S_recycle_done); @(negedge S_I_clk);
            if(S_I_io_retire_request || S_O_io_retired || !S_slot_available || !S_I_track_start_ready)
                fail("slot reused before four-phase completion and flush release");
        end
    endtask
    initial begin
        S_I_reset=1; S_F_I_card_ready=1; S_I_lease_grant=1; S_expected_priority=2;
        for(S_i=0;S_i<3072;S_i=S_i+1) S_disk[S_i]=0;
        S_disk[0]=8'heb; S_disk[2]=8'h90; put16(11,512); S_disk[13]=1;
        put16(14,32); S_disk[16]=2; put32(32,70000); put32(36,600); put32(44,2); put16(510,16'haa55);
        put32(512+2*4,32'h0fffffff); put32(512+4*4,6); put32(512+6*4,32'h0fffffff);
        short_entry(1024,"TEST    WAV",32,4,700); make_wav(40,16'h8100);
        repeat(4) @(negedge S_I_clk); S_I_reset=0; mount_card;
        wait(S_slot_available); S_event_ready=0; launch(0,16'hffff);
        wait(u_slot.u_source.S_write_level==16);
        repeat(8) begin @(negedge S_I_clk); if(S_O_done_valid || S_pcm_count) fail("PCM FIFO backpressure"); end
        S_event_ready=1; S_pcm_enable=1; finish_file(0);
        wait(S_pcm_count==40 && S_terminals==1);
        if(S_headers!==1 || S_written!==40 || S_bytes!==700) fail("real fragmented WAV decode");
        // No automatic flush or new start merely because file I/O finished.
        if(S_O_start_ready || !S_slot_available || S_I_track_start_ready) fail("file done reused unflushed decoder");
        request_recycle; finish_recycle;
        make_wav(4,16'h1200); launch(2,16'h00ff); finish_file(0);
        wait(S_pcm_count==4 && S_terminals==1); request_recycle; finish_recycle;
        make_wav(0,0); launch(1,16'h0100); finish_file(0);
        wait(S_terminals==1); if(S_pcm_count || S_headers!==1) fail("zero data chunk");
        request_recycle; finish_recycle;
        // Bad signature leads to decoder cancellation, independently of file error diagnostics.
        S_check_pcm=0; make_wav(40,16'h2200); S_disk[2048]="X";
        launch(0,16'h1001); finish_file(5); wait(S_terminals==1);
        if(S_terminal_error!==1 || S_I_track_cancel_epoch!==16'h1001) fail("bad WAV decoder diagnostic");
        request_recycle; finish_recycle;
        // Missing file starts no decoder, but empty slot retirement still completes.
        S_disk[1024]=8'he5; launch(0,16'h1002); finish_file(1);
        if(S_O_track_started || S_terminals) fail("missing file started decoder");
        request_recycle; finish_recycle; short_entry(1024,"TEST    WAV",32,4,700);
        make_wav(40,16'h3300); S_fail_lba=1236;
        launch(1,16'h1003); finish_file(1); wait(S_terminals==1);
        if(S_O_storage_error!==4 || S_terminal_error!==5) fail("file versus decoder transport errors");
        request_recycle; finish_recycle; S_fail_lba=32'hffffffff;
        // Real recycle request cancels physical I/O and cannot confirm before delayed SD ack.
        launch(2,16'h1004); wait(S_host_state==1 && S_F_O_sd_lba==1236); S_before=S_cancel_acks;
        request_recycle; finish_file(2); finish_recycle;
        if(S_cancel_acks<=S_before) fail("physical cancel ack missing");
        // Dropped and immediately recovered card never reuses old mount generation.
        launch(0,16'h1005); wait(S_host_state==1 && S_F_O_sd_lba==1234);
        @(negedge S_I_clk); S_F_I_card_ready=0;
        @(negedge S_I_clk); S_F_I_card_ready=1;
        finish_file(3); wait(S_terminals==1); request_recycle; finish_recycle;
        if(S_I_media_valid) fail("card_ready automatically remounted");
        mount_card; S_check_pcm=1; make_wav(40,16'h4400); launch(0,16'h1006);
        finish_file(0); wait(S_pcm_count==40 && S_terminals==1);
        if(S_O_generation!==S_mount_generation) fail("remount generation");
        request_recycle; finish_recycle;
        // Audio clock stopped during recycling: file closure still progresses; no early slot reuse.
        S_check_pcm=0; make_wav(40,16'h5500); launch(1,16'h1007);
        wait(S_host_state==1 && S_F_O_sd_lba==1236);
        @(negedge S_audio_clk); S_audio_run=0; request_recycle; finish_file(2);
        wait(S_O_io_retired); repeat(10) begin @(negedge S_I_clk); if(S_recycle_done || S_O_start_ready) fail("audio stopped but slot reused"); end
        S_audio_run=1; finish_recycle;
        S_test_pass=1; $display("PASS: wav_file_fat32 real core/slot; SD and PCM sink are fixtures"); $finish;
    end
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
                        1233:S_base=1536; 1234:S_base=2048; 1236:S_base=2560;
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
            if(S_O_fs_close_valid && (u_files.S_pending[S_O_context] || u_files.S_cancel_busy))
                fail("source offered close before real file retirement");
        end
    end
endmodule
