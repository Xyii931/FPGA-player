// Actual shared media file service + one FAT32 core. SD host-sector interface.
module media_file_service (
    input wire I_clk,
    input wire [3:0] I_lease_request,
    input wire [3:0] I_lease_active,
    input wire [7:0] I_lease_context,
    output wire [3:0] O_lease_grant,
    input wire [3:0] I_client_open_valid,
    output wire [3:0] O_client_open_ready,
    input wire [227:0] I_client_open,
    input wire [3:0] I_client_path_valid,
    output wire [3:0] O_client_path_ready,
    input wire [31:0] I_client_path_data,
    input wire [3:0] I_client_path_last,
    input wire [3:0] I_client_open_cancel,
    output wire [3:0] O_client_open_result_valid,
    input wire [3:0] I_client_open_result_ready,
    output wire [96:0] O_client_open_result,
    input wire [3:0] I_client_read_valid,
    output wire [3:0] O_client_read_ready,
    input wire [335:0] I_client_read,
    output wire [3:0] O_client_byte_valid,
    input wire [3:0] I_client_byte_ready,
    output wire [90:0] O_client_byte,
    output wire [3:0] O_client_done_valid,
    input wire [3:0] I_client_done_ready,
    output wire [379:0] O_client_done,
    input wire [3:0] I_client_cancel_valid,
    output wire [3:0] O_client_cancel_ready,
    input wire [71:0] I_client_cancel,
    output wire [3:0] O_client_cancel_done_valid,
    input wire [3:0] I_client_cancel_done_ready,
    output wire [49:0] O_client_cancel_done,
    input wire [3:0] I_client_close_valid,
    output wire [3:0] O_client_close_ready,
    input wire [7:0] I_client_close_context,
    input wire [3:0] I_client_urgent,
    output wire O_busy,
    output wire O_quiescent,
    output wire [2:0] O_leased_contexts,
    output wire [2:0] O_descriptors,
    output wire [2:0] O_pending_reads,
    output wire O_contract_fault,
    output wire O_response_discarded,
    input wire I_scan_valid,
    output wire O_scan_ready,
    input wire [15:0] I_scan_tag,
    input wire [6:0] I_scan_path_length,
    input wire [31:0] I_scan_sector_budget,
    input wire I_scan_path_valid,
    output wire O_scan_path_ready,
    input wire [7:0] I_scan_path_data,
    input wire I_scan_path_last,
    input wire I_scan_stop,
    input wire I_scan_cancel,
    output wire O_scan_entry_valid,
    input wire I_scan_entry_ready,
    output wire [7:0] O_scan_attr,
    output wire [31:0] O_scan_size,
    output wire [31:0] O_scan_first_cluster,
    output wire [87:0] O_scan_alias,
    output wire [6:0] O_scan_name_length,
    output wire O_scan_is_lfn,
    output wire O_scan_name_valid,
    input wire I_scan_name_ready,
    output wire [7:0] O_scan_name_data,
    output wire O_scan_name_last,
    output wire O_scan_done_valid,
    input wire I_scan_done_ready,
    output wire [15:0] O_scan_tag,
    output wire [31:0] O_scan_generation,
    output wire [31:0] O_scan_sectors,
    output wire [2:0] O_scan_warning,
    output wire [7:0] O_scan_error,
    output wire [3:0] O_scan_storage_error,
    input wire I_reset,
    output wire [2:0] O_urgent_context,
    input wire I_card_ready,
    input wire I_unmount,
    input wire [32:0] I_capacity_sectors,
    input wire I_mount_valid,
    output wire O_mount_ready,
    output wire O_mount_result_valid,
    input wire I_mount_result_ready,
    output wire [7:0] O_mount_error,
    output wire [3:0] O_mount_storage_error,
    output wire [31:0] O_mount_generation,
    output wire O_mounted,
    output wire [31:0] O_generation,
    output wire O_sd_request_valid,
    input wire I_sd_request_ready,
    output wire [31:0] O_sd_lba,
    output wire [7:0] O_sd_count,
    output wire [1:0] O_sd_context,
    output wire [1:0] O_sd_priority,
    output wire [15:0] O_sd_tag,
    input wire I_sd_byte_valid,
    output wire O_sd_byte_ready,
    input wire [7:0] I_sd_byte_data,
    input wire I_sd_sector_last,
    input wire I_sd_request_last,
    input wire [1:0] I_sd_byte_context,
    input wire [15:0] I_sd_byte_tag,
    input wire I_sd_done_valid,
    output wire O_sd_done_ready,
    input wire [1:0] I_sd_done_context,
    input wire [15:0] I_sd_done_tag,
    input wire [3:0] I_sd_done_error,
    output wire O_sd_cancel_valid,
    input wire I_sd_cancel_ready,
    output wire [1:0] O_sd_cancel_context,
    output wire [15:0] O_sd_cancel_tag,
    input wire I_sd_cancel_done_valid,
    output wire O_sd_cancel_done_ready,
    input wire [1:0] I_sd_cancel_done_context,
    input wire [15:0] I_sd_cancel_done_tag
);
    wire S_I_enum_valid;
    wire S_O_enum_ready;
    wire [15:0] S_I_enum_tag;
    wire [6:0] S_I_enum_path_length;
    wire [31:0] S_I_enum_sector_budget;
    wire S_I_enum_path_valid;
    wire S_O_enum_path_ready;
    wire [7:0] S_I_enum_path_data;
    wire S_I_enum_path_last;
    wire S_I_enum_stop;
    wire S_I_enum_cancel;
    wire S_O_enum_entry_valid;
    wire S_I_enum_entry_ready;
    wire [7:0] S_O_enum_attr;
    wire [31:0] S_O_enum_size;
    wire [31:0] S_O_enum_first_cluster;
    wire [87:0] S_O_enum_alias;
    wire [6:0] S_O_enum_name_length;
    wire S_O_enum_is_lfn;
    wire S_O_enum_name_valid;
    wire S_I_enum_name_ready;
    wire [7:0] S_O_enum_name_data;
    wire S_O_enum_name_last;
    wire S_O_enum_done_valid;
    wire S_I_enum_done_ready;
    wire [15:0] S_O_enum_tag;
    wire [31:0] S_O_enum_generation;
    wire [31:0] S_O_enum_sectors;
    wire [2:0] S_O_enum_warning;
    wire [7:0] S_O_enum_error;
    wire [3:0] S_O_enum_storage_error;
    wire S_I_open_valid;
    wire S_O_open_ready;
    wire [1:0] S_I_open_context;
    wire [15:0] S_I_open_tag;
    wire [6:0] S_I_path_length;
    wire [31:0] S_I_sector_budget;
    wire S_I_path_valid;
    wire S_O_path_ready;
    wire [7:0] S_I_path_data;
    wire S_I_path_last;
    wire S_I_open_cancel;
    wire S_O_open_result_valid;
    wire S_I_open_result_ready;
    wire [1:0] S_O_open_context;
    wire [15:0] S_O_open_tag;
    wire [31:0] S_O_open_generation;
    wire [31:0] S_O_open_size;
    wire [31:0] S_O_open_first_cluster;
    wire [31:0] S_O_open_sectors;
    wire [7:0] S_O_open_attr;
    wire [7:0] S_O_open_error;
    wire [3:0] S_O_open_storage_error;
    wire [2:0] S_O_open_warning;
    wire [31:0] S_O_byte_generation;
    wire [31:0] S_O_done_generation;
    wire [31:0] S_O_cancel_done_generation;
    wire S_I_close_valid;
    wire S_O_close_ready;
    wire [1:0] S_I_close_context;
    wire S_I_read_valid;
    wire S_O_read_ready;
    wire [1:0] S_I_read_context;
    wire [1:0] S_I_read_priority;
    wire [31:0] S_I_offset;
    wire [31:0] S_I_length;
    wire [15:0] S_I_epoch;
    wire [2:0] S_I_urgent_context;
    wire S_O_byte_valid;
    wire S_I_byte_ready;
    wire [7:0] S_O_byte_data;
    wire [1:0] S_O_byte_context;
    wire [15:0] S_O_byte_epoch;
    wire [31:0] S_O_byte_offset;
    wire S_O_byte_last;
    wire S_O_done_valid;
    wire S_I_done_ready;
    wire [1:0] S_O_done_context;
    wire [15:0] S_O_done_epoch;
    wire [31:0] S_O_done_bytes;
    wire S_O_done_eof;
    wire [7:0] S_O_done_error;
    wire [3:0] S_O_done_storage_error;
    wire S_I_cancel_valid;
    wire S_O_cancel_ready;
    wire [1:0] S_I_cancel_context;
    wire [15:0] S_I_cancel_epoch;
    wire S_O_cancel_done_valid;
    wire S_I_cancel_done_ready;
    wire [1:0] S_O_cancel_done_context;
    wire [15:0] S_O_cancel_done_epoch;
    wire [31:0] S_O_partition_lba;
    wire [31:0] S_O_volume_sectors;
    wire [31:0] S_O_fat_lba;
    wire [31:0] S_O_data_lba;
    wire [31:0] S_O_cluster_count;
    wire [31:0] S_O_root_cluster;
    wire [7:0] S_O_sectors_per_cluster;
    wire [2:0] S_O_cluster_shift;
    wire S_mux_idle,S_mux_busy,S_core_idle,S_mount_ready;
    media_file_mux u_mux (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(O_mounted),
        .I_media_generation(O_generation),
        .I_lease_block(I_mount_valid),
        .I_lease_request(I_lease_request),
        .I_lease_active(I_lease_active),
        .I_lease_context(I_lease_context),
        .O_lease_grant(O_lease_grant),
        .I_client_open_valid(I_client_open_valid),
        .O_client_open_ready(O_client_open_ready),
        .I_client_open(I_client_open),
        .I_client_path_valid(I_client_path_valid),
        .O_client_path_ready(O_client_path_ready),
        .I_client_path_data(I_client_path_data),
        .I_client_path_last(I_client_path_last),
        .I_client_open_cancel(I_client_open_cancel),
        .O_client_open_result_valid(O_client_open_result_valid),
        .I_client_open_result_ready(I_client_open_result_ready),
        .O_client_open_result(O_client_open_result),
        .I_client_read_valid(I_client_read_valid),
        .O_client_read_ready(O_client_read_ready),
        .I_client_read(I_client_read),
        .O_client_byte_valid(O_client_byte_valid),
        .I_client_byte_ready(I_client_byte_ready),
        .O_client_byte(O_client_byte),
        .O_client_done_valid(O_client_done_valid),
        .I_client_done_ready(I_client_done_ready),
        .O_client_done(O_client_done),
        .I_client_cancel_valid(I_client_cancel_valid),
        .O_client_cancel_ready(O_client_cancel_ready),
        .I_client_cancel(I_client_cancel),
        .O_client_cancel_done_valid(O_client_cancel_done_valid),
        .I_client_cancel_done_ready(I_client_cancel_done_ready),
        .O_client_cancel_done(O_client_cancel_done),
        .I_client_close_valid(I_client_close_valid),
        .O_client_close_ready(O_client_close_ready),
        .I_client_close_context(I_client_close_context),
        .I_client_urgent(I_client_urgent),
        .O_busy(S_mux_busy),
        .O_quiescent(S_mux_idle),
        .O_leased_contexts(O_leased_contexts),
        .O_descriptors(O_descriptors),
        .O_pending_reads(O_pending_reads),
        .O_contract_fault(O_contract_fault),
        .O_response_discarded(O_response_discarded),
        .I_scan_valid(I_scan_valid),
        .O_scan_ready(O_scan_ready),
        .I_scan_tag(I_scan_tag),
        .I_scan_path_length(I_scan_path_length),
        .I_scan_sector_budget(I_scan_sector_budget),
        .I_scan_path_valid(I_scan_path_valid),
        .O_scan_path_ready(O_scan_path_ready),
        .I_scan_path_data(I_scan_path_data),
        .I_scan_path_last(I_scan_path_last),
        .I_scan_stop(I_scan_stop),
        .I_scan_cancel(I_scan_cancel),
        .O_scan_entry_valid(O_scan_entry_valid),
        .I_scan_entry_ready(I_scan_entry_ready),
        .O_scan_attr(O_scan_attr),
        .O_scan_size(O_scan_size),
        .O_scan_first_cluster(O_scan_first_cluster),
        .O_scan_alias(O_scan_alias),
        .O_scan_name_length(O_scan_name_length),
        .O_scan_is_lfn(O_scan_is_lfn),
        .O_scan_name_valid(O_scan_name_valid),
        .I_scan_name_ready(I_scan_name_ready),
        .O_scan_name_data(O_scan_name_data),
        .O_scan_name_last(O_scan_name_last),
        .O_scan_done_valid(O_scan_done_valid),
        .I_scan_done_ready(I_scan_done_ready),
        .O_scan_tag(O_scan_tag),
        .O_scan_generation(O_scan_generation),
        .O_scan_sectors(O_scan_sectors),
        .O_scan_warning(O_scan_warning),
        .O_scan_error(O_scan_error),
        .O_scan_storage_error(O_scan_storage_error),
        .O_core_enum_valid(S_I_enum_valid),
        .I_core_enum_ready(S_O_enum_ready),
        .O_core_enum_tag(S_I_enum_tag),
        .O_core_enum_path_length(S_I_enum_path_length),
        .O_core_enum_sector_budget(S_I_enum_sector_budget),
        .O_core_enum_path_valid(S_I_enum_path_valid),
        .I_core_enum_path_ready(S_O_enum_path_ready),
        .O_core_enum_path_data(S_I_enum_path_data),
        .O_core_enum_path_last(S_I_enum_path_last),
        .O_core_enum_stop(S_I_enum_stop),
        .O_core_enum_cancel(S_I_enum_cancel),
        .I_core_enum_entry_valid(S_O_enum_entry_valid),
        .O_core_enum_entry_ready(S_I_enum_entry_ready),
        .I_core_enum_attr(S_O_enum_attr),
        .I_core_enum_size(S_O_enum_size),
        .I_core_enum_first_cluster(S_O_enum_first_cluster),
        .I_core_enum_alias(S_O_enum_alias),
        .I_core_enum_name_length(S_O_enum_name_length),
        .I_core_enum_is_lfn(S_O_enum_is_lfn),
        .I_core_enum_name_valid(S_O_enum_name_valid),
        .O_core_enum_name_ready(S_I_enum_name_ready),
        .I_core_enum_name_data(S_O_enum_name_data),
        .I_core_enum_name_last(S_O_enum_name_last),
        .I_core_enum_done_valid(S_O_enum_done_valid),
        .O_core_enum_done_ready(S_I_enum_done_ready),
        .I_core_enum_tag(S_O_enum_tag),
        .I_core_enum_generation(S_O_enum_generation),
        .I_core_enum_sectors(S_O_enum_sectors),
        .I_core_enum_warning(S_O_enum_warning),
        .I_core_enum_error(S_O_enum_error),
        .I_core_enum_storage_error(S_O_enum_storage_error),
        .O_core_open_valid(S_I_open_valid),
        .I_core_open_ready(S_O_open_ready),
        .O_core_open_context(S_I_open_context),
        .O_core_open_tag(S_I_open_tag),
        .O_core_path_length(S_I_path_length),
        .O_core_sector_budget(S_I_sector_budget),
        .O_core_path_valid(S_I_path_valid),
        .I_core_path_ready(S_O_path_ready),
        .O_core_path_data(S_I_path_data),
        .O_core_path_last(S_I_path_last),
        .O_core_open_cancel(S_I_open_cancel),
        .I_core_open_result_valid(S_O_open_result_valid),
        .O_core_open_result_ready(S_I_open_result_ready),
        .I_core_open_context(S_O_open_context),
        .I_core_open_tag(S_O_open_tag),
        .I_core_open_generation(S_O_open_generation),
        .I_core_open_size(S_O_open_size),
        .I_core_open_first_cluster(S_O_open_first_cluster),
        .I_core_open_sectors(S_O_open_sectors),
        .I_core_open_attr(S_O_open_attr),
        .I_core_open_error(S_O_open_error),
        .I_core_open_storage_error(S_O_open_storage_error),
        .I_core_open_warning(S_O_open_warning),
        .I_core_byte_generation(S_O_byte_generation),
        .I_core_done_generation(S_O_done_generation),
        .I_core_cancel_done_generation(S_O_cancel_done_generation),
        .O_core_close_valid(S_I_close_valid),
        .I_core_close_ready(S_O_close_ready),
        .O_core_close_context(S_I_close_context),
        .O_core_read_valid(S_I_read_valid),
        .I_core_read_ready(S_O_read_ready),
        .O_core_read_context(S_I_read_context),
        .O_core_read_priority(S_I_read_priority),
        .O_core_offset(S_I_offset),
        .O_core_length(S_I_length),
        .O_core_epoch(S_I_epoch),
        .O_core_urgent_context(S_I_urgent_context),
        .I_core_byte_valid(S_O_byte_valid),
        .O_core_byte_ready(S_I_byte_ready),
        .I_core_byte_data(S_O_byte_data),
        .I_core_byte_context(S_O_byte_context),
        .I_core_byte_epoch(S_O_byte_epoch),
        .I_core_byte_offset(S_O_byte_offset),
        .I_core_byte_last(S_O_byte_last),
        .I_core_done_valid(S_O_done_valid),
        .O_core_done_ready(S_I_done_ready),
        .I_core_done_context(S_O_done_context),
        .I_core_done_epoch(S_O_done_epoch),
        .I_core_done_bytes(S_O_done_bytes),
        .I_core_done_eof(S_O_done_eof),
        .I_core_done_error(S_O_done_error),
        .I_core_done_storage_error(S_O_done_storage_error),
        .O_core_cancel_valid(S_I_cancel_valid),
        .I_core_cancel_ready(S_O_cancel_ready),
        .O_core_cancel_context(S_I_cancel_context),
        .O_core_cancel_epoch(S_I_cancel_epoch),
        .I_core_cancel_done_valid(S_O_cancel_done_valid),
        .O_core_cancel_done_ready(S_I_cancel_done_ready),
        .I_core_cancel_done_context(S_O_cancel_done_context),
        .I_core_cancel_done_epoch(S_O_cancel_done_epoch)
    );
    fat32_core u_core (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_card_ready(I_card_ready),
        .I_unmount(I_unmount),
        .I_capacity_sectors(I_capacity_sectors),
        .I_mount_valid(I_mount_valid && S_mux_idle),
        .O_mount_ready(S_mount_ready),
        .O_mount_result_valid(O_mount_result_valid),
        .I_mount_result_ready(I_mount_result_ready),
        .O_mount_error(O_mount_error),
        .O_mount_storage_error(O_mount_storage_error),
        .O_mount_generation(O_mount_generation),
        .O_mounted(O_mounted),
        .O_quiescent(S_core_idle),
        .O_generation(O_generation),
        .O_partition_lba(S_O_partition_lba),
        .O_volume_sectors(S_O_volume_sectors),
        .O_fat_lba(S_O_fat_lba),
        .O_data_lba(S_O_data_lba),
        .O_cluster_count(S_O_cluster_count),
        .O_root_cluster(S_O_root_cluster),
        .O_sectors_per_cluster(S_O_sectors_per_cluster),
        .O_cluster_shift(S_O_cluster_shift),
        .I_enum_valid(S_I_enum_valid),
        .O_enum_ready(S_O_enum_ready),
        .I_enum_tag(S_I_enum_tag),
        .I_enum_path_length(S_I_enum_path_length),
        .I_enum_sector_budget(S_I_enum_sector_budget),
        .I_enum_path_valid(S_I_enum_path_valid),
        .O_enum_path_ready(S_O_enum_path_ready),
        .I_enum_path_data(S_I_enum_path_data),
        .I_enum_path_last(S_I_enum_path_last),
        .I_enum_stop(S_I_enum_stop),
        .I_enum_cancel(S_I_enum_cancel),
        .O_enum_entry_valid(S_O_enum_entry_valid),
        .I_enum_entry_ready(S_I_enum_entry_ready),
        .O_enum_attr(S_O_enum_attr),
        .O_enum_size(S_O_enum_size),
        .O_enum_first_cluster(S_O_enum_first_cluster),
        .O_enum_alias(S_O_enum_alias),
        .O_enum_name_length(S_O_enum_name_length),
        .O_enum_is_lfn(S_O_enum_is_lfn),
        .O_enum_name_valid(S_O_enum_name_valid),
        .I_enum_name_ready(S_I_enum_name_ready),
        .O_enum_name_data(S_O_enum_name_data),
        .O_enum_name_last(S_O_enum_name_last),
        .O_enum_done_valid(S_O_enum_done_valid),
        .I_enum_done_ready(S_I_enum_done_ready),
        .O_enum_tag(S_O_enum_tag),
        .O_enum_generation(S_O_enum_generation),
        .O_enum_sectors(S_O_enum_sectors),
        .O_enum_warning(S_O_enum_warning),
        .O_enum_error(S_O_enum_error),
        .O_enum_storage_error(S_O_enum_storage_error),
        .I_open_valid(S_I_open_valid),
        .O_open_ready(S_O_open_ready),
        .I_open_context(S_I_open_context),
        .I_open_tag(S_I_open_tag),
        .I_path_length(S_I_path_length),
        .I_sector_budget(S_I_sector_budget),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
        .I_open_cancel(S_I_open_cancel),
        .O_open_result_valid(S_O_open_result_valid),
        .I_open_result_ready(S_I_open_result_ready),
        .O_open_context(S_O_open_context),
        .O_open_tag(S_O_open_tag),
        .O_open_generation(S_O_open_generation),
        .O_open_size(S_O_open_size),
        .O_open_first_cluster(S_O_open_first_cluster),
        .O_open_sectors(S_O_open_sectors),
        .O_open_attr(S_O_open_attr),
        .O_open_error(S_O_open_error),
        .O_open_storage_error(S_O_open_storage_error),
        .O_open_warning(S_O_open_warning),
        .O_byte_generation(S_O_byte_generation),
        .O_done_generation(S_O_done_generation),
        .O_cancel_done_generation(S_O_cancel_done_generation),
        .I_close_valid(S_I_close_valid),
        .O_close_ready(S_O_close_ready),
        .I_close_context(S_I_close_context),
        .I_read_valid(S_I_read_valid),
        .O_read_ready(S_O_read_ready),
        .I_read_context(S_I_read_context),
        .I_read_priority(S_I_read_priority),
        .I_offset(S_I_offset),
        .I_length(S_I_length),
        .I_epoch(S_I_epoch),
        .I_urgent_context(S_I_urgent_context),
        .O_byte_valid(S_O_byte_valid),
        .I_byte_ready(S_I_byte_ready),
        .O_byte_data(S_O_byte_data),
        .O_byte_context(S_O_byte_context),
        .O_byte_epoch(S_O_byte_epoch),
        .O_byte_offset(S_O_byte_offset),
        .O_byte_last(S_O_byte_last),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_done_context(S_O_done_context),
        .O_done_epoch(S_O_done_epoch),
        .O_done_bytes(S_O_done_bytes),
        .O_done_eof(S_O_done_eof),
        .O_done_error(S_O_done_error),
        .O_done_storage_error(S_O_done_storage_error),
        .I_cancel_valid(S_I_cancel_valid),
        .O_cancel_ready(S_O_cancel_ready),
        .I_cancel_context(S_I_cancel_context),
        .I_cancel_epoch(S_I_cancel_epoch),
        .O_cancel_done_valid(S_O_cancel_done_valid),
        .I_cancel_done_ready(S_I_cancel_done_ready),
        .O_cancel_done_context(S_O_cancel_done_context),
        .O_cancel_done_epoch(S_O_cancel_done_epoch),
        .O_sd_request_valid(O_sd_request_valid),
        .I_sd_request_ready(I_sd_request_ready),
        .O_sd_lba(O_sd_lba),
        .O_sd_count(O_sd_count),
        .O_sd_context(O_sd_context),
        .O_sd_priority(O_sd_priority),
        .O_sd_tag(O_sd_tag),
        .I_sd_byte_valid(I_sd_byte_valid),
        .O_sd_byte_ready(O_sd_byte_ready),
        .I_sd_byte_data(I_sd_byte_data),
        .I_sd_sector_last(I_sd_sector_last),
        .I_sd_request_last(I_sd_request_last),
        .I_sd_byte_context(I_sd_byte_context),
        .I_sd_byte_tag(I_sd_byte_tag),
        .I_sd_done_valid(I_sd_done_valid),
        .O_sd_done_ready(O_sd_done_ready),
        .I_sd_done_context(I_sd_done_context),
        .I_sd_done_tag(I_sd_done_tag),
        .I_sd_done_error(I_sd_done_error),
        .O_sd_cancel_valid(O_sd_cancel_valid),
        .I_sd_cancel_ready(I_sd_cancel_ready),
        .O_sd_cancel_context(O_sd_cancel_context),
        .O_sd_cancel_tag(O_sd_cancel_tag),
        .I_sd_cancel_done_valid(I_sd_cancel_done_valid),
        .O_sd_cancel_done_ready(O_sd_cancel_done_ready),
        .I_sd_cancel_done_context(I_sd_cancel_done_context),
        .I_sd_cancel_done_tag(I_sd_cancel_done_tag)
    );
    assign O_urgent_context=S_I_urgent_context;
    assign O_mount_ready=S_mount_ready && S_mux_idle;
    assign O_busy=S_mux_busy || !S_core_idle;
    assign O_quiescent=S_mux_idle && S_core_idle;
endmodule
