// Integrated read-only FAT32 host core. Explicit mount; no FIFO reset on loss.
// Old identities retire before geometry can be replaced. All sd_ ports are host-domain.
module fat32_core (
    input wire I_clk,I_reset,I_card_ready,I_unmount,
    input wire [32:0] I_capacity_sectors,
    input wire I_mount_valid,
    output wire O_mount_ready,
    output reg O_mount_result_valid,
    input wire I_mount_result_ready,
    output reg [7:0] O_mount_error,
    output reg [3:0] O_mount_storage_error,
    output wire [31:0] O_mount_generation,
    output wire O_mounted,O_quiescent,
    output reg [31:0] O_generation,
    output reg [31:0] O_partition_lba,O_volume_sectors,O_fat_lba,O_data_lba,O_cluster_count,O_root_cluster,
    output reg [7:0] O_sectors_per_cluster,
    output reg [2:0] O_cluster_shift,
    input wire I_enum_valid,
    output wire O_enum_ready,
    input wire [15:0] I_enum_tag,
    input wire [6:0] I_enum_path_length,
    input wire [31:0] I_enum_sector_budget,
    input wire I_enum_path_valid,
    output wire O_enum_path_ready,
    input wire [7:0] I_enum_path_data,
    input wire I_enum_path_last,I_enum_stop,I_enum_cancel,
    output wire O_enum_entry_valid,
    input wire I_enum_entry_ready,
    output wire [7:0] O_enum_attr,
    output wire [31:0] O_enum_size,O_enum_first_cluster,
    output wire [87:0] O_enum_alias,
    output wire [6:0] O_enum_name_length,
    output wire O_enum_is_lfn,O_enum_name_valid,
    input wire I_enum_name_ready,
    output wire [7:0] O_enum_name_data,
    output wire O_enum_name_last,O_enum_done_valid,
    input wire I_enum_done_ready,
    output reg [15:0] O_enum_tag,
    output reg [31:0] O_enum_generation,O_enum_sectors,
    output reg [2:0] O_enum_warning,
    output reg [7:0] O_enum_error,
    output reg [3:0] O_enum_storage_error,
    input wire I_open_valid,
    output wire O_open_ready,
    input wire [1:0] I_open_context,
    input wire [15:0] I_open_tag,
    input wire [6:0] I_path_length,
    input wire [31:0] I_sector_budget,
    input wire I_path_valid,
    output wire O_path_ready,
    input wire [7:0] I_path_data,
    input wire I_path_last,I_open_cancel,
    output wire O_open_result_valid,
    input wire I_open_result_ready,
    output reg [1:0] O_open_context,
    output reg [15:0] O_open_tag,
    output reg [31:0] O_open_generation,O_open_size,O_open_first_cluster,O_open_sectors,
    output reg [7:0] O_open_attr,O_open_error,
    output reg [3:0] O_open_storage_error,
    output reg [2:0] O_open_warning,
    output wire [31:0] O_byte_generation,O_done_generation,O_cancel_done_generation,
    input wire  I_close_valid,
    output wire  O_close_ready,
    input wire [1:0] I_close_context,
    input wire  I_read_valid,
    output wire  O_read_ready,
    input wire [1:0] I_read_context,
    input wire [1:0] I_read_priority,
    input wire [31:0] I_offset,
    input wire [31:0] I_length,
    input wire [15:0] I_epoch,
    input wire [2:0] I_urgent_context,
    output wire  O_byte_valid,
    input wire  I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire [1:0] O_byte_context,
    output wire [15:0] O_byte_epoch,
    output wire [31:0] O_byte_offset,
    output wire  O_byte_last,
    output wire  O_done_valid,
    input wire  I_done_ready,
    output wire [1:0] O_done_context,
    output wire [15:0] O_done_epoch,
    output wire [31:0] O_done_bytes,
    output wire  O_done_eof,
    output wire [7:0] O_done_error,
    output wire [3:0] O_done_storage_error,
    input wire  I_cancel_valid,
    output wire  O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_epoch,
    output wire  O_cancel_done_valid,
    input wire  I_cancel_done_ready,
    output wire [1:0] O_cancel_done_context,
    output wire [15:0] O_cancel_done_epoch,
    output wire  O_sd_request_valid,
    input wire  I_sd_request_ready,
    output wire [31:0] O_sd_lba,
    output wire [7:0] O_sd_count,
    output wire [1:0] O_sd_context,
    output wire [1:0] O_sd_priority,
    output wire [15:0] O_sd_tag,
    input wire  I_sd_byte_valid,
    output wire  O_sd_byte_ready,
    input wire [7:0] I_sd_byte_data,
    input wire  I_sd_sector_last,
    input wire  I_sd_request_last,
    input wire [1:0] I_sd_byte_context,
    input wire [15:0] I_sd_byte_tag,
    input wire  I_sd_done_valid,
    output wire  O_sd_done_ready,
    input wire [1:0] I_sd_done_context,
    input wire [15:0] I_sd_done_tag,
    input wire [3:0] I_sd_done_error,
    output wire  O_sd_cancel_valid,
    input wire  I_sd_cancel_ready,
    output wire [1:0] O_sd_cancel_context,
    output wire [15:0] O_sd_cancel_tag,
    input wire  I_sd_cancel_done_valid,
    output wire  O_sd_cancel_done_ready,
    input wire [1:0] I_sd_cancel_done_context,
    input wire [15:0] I_sd_cancel_done_tag
);
    localparam [3:0] OPEN_IDLE=0,LOOKUP=1,LOAD=2,LOAD_WAIT=3,ROLLBACK=4,OPEN_RESULT=5,
        ENUM_LOOKUP=6,ENUM_START=7,ENUM_SCAN=8,ENUM_RESULT=9;
    // One namespace owner; file descriptors remain independent during enumeration.
    reg [3:0] S_open_state;
    reg S_enum_canceled,S_enum_stopped,S_enum_lost;
    reg [31:0] S_enum_budget,S_enum_directory;
    wire S_dir_ready,S_dir_done,S_dir_read_valid,S_dir_read_abort,S_dir_read_result_ready;
    wire [31:0] S_dir_sectors,S_dir_read_lba;
    wire [7:0] S_dir_error;
    wire [3:0] S_dir_storage_error;
    wire [2:0] S_dir_warning;
    wire [8:0] S_dir_buffer_address;
    wire S_enum_owner=S_open_state>=ENUM_LOOKUP;
    wire S_scan_owner=S_open_state==ENUM_SCAN;
    wire S_enum_stop=S_enum_stopped || I_enum_stop;
    wire S_enum_cancel=S_enum_canceled || I_enum_cancel;
    wire S_enum_invalid=S_enum_lost || !O_mounted;
    wire S_enum_accept=I_enum_valid && O_enum_ready;
    wire S_namespace_valid=S_scan_owner ? S_dir_read_valid : S_path_read_valid;
    wire [31:0] S_namespace_lba=S_scan_owner ? S_dir_read_lba : S_path_read_lba;
    wire S_namespace_abort=S_scan_owner ? S_dir_read_abort : S_path_read_abort;
    wire S_namespace_result_ready=S_scan_owner ? S_dir_read_result_ready : S_path_read_result_ready;
    wire [8:0] S_namespace_address=S_scan_owner ? S_dir_buffer_address : S_path_buffer_address;
    reg S_online,S_mount_busy,S_mount_lost,S_open_canceled,S_open_lost,S_cancel_busy;
    reg [2:0] S_descriptors,S_pending;
    reg [31:0] S_read_generation[0:2];
    reg [15:0] S_read_epoch[0:2];
    reg [1:0] S_cancel_context;
    reg [31:0] S_cancel_generation;
    wire S_mount_ready,S_mount_result_valid,S_mount_mounted;
    wire [7:0] S_mount_error,S_mount_sectors_per_cluster;
    wire [3:0] S_mount_storage_error;
    wire [31:0] S_mount_partition_lba,S_mount_volume_sectors,S_mount_fat_lba,S_mount_data_lba;
    wire [31:0] S_mount_cluster_count,S_mount_root_cluster;
    wire [2:0] S_mount_cluster_shift;
    wire S_mount_read_valid,S_mount_read_result_ready;
    wire [31:0] S_mount_read_lba;
    wire [8:0] S_mount_buffer_address;
    wire S_path_ready,S_path_byte_ready,S_path_result_valid,S_path_read_valid,S_path_read_abort,S_path_read_result_ready;
    wire [7:0] S_path_attr,S_path_error;
    wire [3:0] S_path_storage_error;
    wire [31:0] S_path_size,S_path_first_cluster,S_path_sectors,S_path_read_lba;
    wire [2:0] S_path_warning;
    wire [8:0] S_path_buffer_address;
    wire S_load_ready,S_load_result,S_close_ready,S_file_read_ready,S_file_cancel_ready;
    wire [1:0] S_load_context;
    wire [7:0] S_load_error;
    wire S_file_valid,S_file_abort,S_file_result_ready;
    wire [31:0] S_file_lba;
    wire [1:0] S_file_context,S_file_priority;
    wire [8:0] S_file_address;
    wire [2:0] S_ready,S_result;
    wire [23:0] S_error,S_buffer_data;
    wire [11:0] S_storage_error;
    wire S_port_valid,S_port_ready,S_port_abort,S_port_result,S_port_result_ready;
    wire [31:0] S_port_lba;
    wire [1:0] S_port_context,S_port_priority;
    wire [8:0] S_port_address;
    wire [7:0] S_port_error,S_port_data;
    wire [3:0] S_port_storage_error;
    wire S_mount_accept=I_mount_valid && O_mount_ready;
    wire S_open_accept=I_open_valid && O_open_ready;
    wire S_mount_alive=I_card_ready && !I_unmount && (!S_mount_busy || !S_mount_lost);
    wire S_reserved=S_open_state!=OPEN_IDLE && !S_enum_owner;
    wire S_cancel_target=S_cancel_busy && S_cancel_context==I_open_context;
    wire S_target_busy=I_open_context<3 && (S_descriptors[I_open_context] || S_pending[I_open_context] || S_cancel_target);
    wire S_open_allowed=O_mounted && I_open_context<3 && !S_target_busy && !I_open_cancel;
    wire S_path_start=(S_open_accept && S_open_allowed) || (S_enum_accept && O_mounted && !I_enum_cancel);
    wire S_open_stop=S_open_canceled || I_open_cancel;
    wire S_open_invalid=S_open_lost || !O_mounted;
    wire S_load_valid=S_open_state==LOAD && !S_open_stop && !S_open_invalid &&
        !(S_cancel_busy && S_cancel_context==O_open_context);
    wire S_read_allow=O_mounted && !I_mount_valid &&
        !(S_reserved && I_read_context==O_open_context) && !(S_cancel_busy && I_read_context==S_cancel_context) &&
        !(S_open_accept && I_read_context==I_open_context);
    wire S_external_close_allow=!(S_reserved && I_close_context==O_open_context) &&
        !(S_cancel_busy && I_close_context==S_cancel_context) && !S_mount_busy && !S_mount_accept &&
        !(S_open_accept && I_close_context==I_open_context);
    wire S_cancel_allow=!S_mount_busy && !S_cancel_busy && !S_mount_accept &&
        !(S_reserved && I_cancel_context==O_open_context) && !(S_open_accept && I_cancel_context==I_open_context);
    wire S_close_valid=S_open_state==ROLLBACK || (I_close_valid && S_external_close_allow);
    wire [1:0] S_close_context=S_open_state==ROLLBACK ? O_open_context : I_close_context;
    wire S_file_urgent=S_file_context<3 && I_urgent_context[S_file_context];
    wire S_read_accept=I_read_valid && O_read_ready;
    wire S_cancel_accept=I_cancel_valid && O_cancel_ready;
    integer S_i;

    assign O_quiescent=!I_reset && !S_mount_busy && !O_mount_result_valid && S_open_state==OPEN_IDLE &&
        S_pending==0 && !S_cancel_busy && !O_done_valid && !O_cancel_done_valid;
    assign O_mount_ready=O_quiescent && S_mount_ready && I_card_ready && !I_unmount;
    assign O_mount_generation=O_generation;
    assign O_mounted=!I_reset && S_online && I_card_ready && !I_unmount && !S_mount_accept;
    assign O_open_ready=!I_reset && S_open_state==OPEN_IDLE && !S_mount_busy && !O_mount_result_valid &&
        !I_mount_valid && S_path_ready && S_dir_ready;
    assign O_enum_ready=O_open_ready && !I_open_valid;
    assign O_enum_path_ready=S_path_byte_ready && S_open_state==ENUM_LOOKUP;
    assign O_enum_done_valid=!I_reset && S_open_state==ENUM_RESULT;
    assign O_open_result_valid=!I_reset && S_open_state==OPEN_RESULT;
    assign O_path_ready=S_path_byte_ready && S_open_state==LOOKUP;
    assign O_read_ready=S_file_read_ready && S_read_allow;
    assign O_close_ready=S_close_ready && S_external_close_allow && S_open_state!=ROLLBACK;
    assign O_cancel_ready=S_file_cancel_ready && S_cancel_allow;
    assign O_byte_generation=O_byte_context<3 ? S_read_generation[O_byte_context] : 32'd0;
    assign O_done_generation=O_done_context<3 ? S_read_generation[O_done_context] : 32'd0;
    assign O_cancel_done_generation=S_cancel_generation;

    task open_finish;
        input [7:0] error_code;
        begin O_open_error<=error_code; S_open_state<=OPEN_RESULT; end
    endtask
    task enum_finish;
        input [7:0] error_code;
        begin O_enum_error<=error_code; S_open_state<=ENUM_RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_enum_canceled<=0; S_enum_stopped<=0; S_enum_lost<=0; S_enum_budget<=0; S_enum_directory<=0;
            O_enum_tag<=0; O_enum_generation<=0; O_enum_sectors<=0; O_enum_warning<=0;
            O_enum_error<=0; O_enum_storage_error<=0;
            S_online<=0; S_mount_busy<=0; S_mount_lost<=0; S_open_state<=OPEN_IDLE;
            S_open_canceled<=0; S_open_lost<=0; S_descriptors<=0; S_pending<=0;
            S_cancel_busy<=0; S_cancel_context<=0; S_cancel_generation<=0;
            O_mount_result_valid<=0; O_mount_error<=0; O_mount_storage_error<=0; O_generation<=0;
            O_partition_lba<=0; O_volume_sectors<=0; O_fat_lba<=0; O_data_lba<=0;
            O_cluster_count<=0; O_root_cluster<=0; O_sectors_per_cluster<=0; O_cluster_shift<=0;
            O_open_context<=0; O_open_tag<=0; O_open_generation<=0; O_open_size<=0; O_open_first_cluster<=0;
            O_open_attr<=0; O_open_error<=0; O_open_storage_error<=0; O_open_warning<=0; O_open_sectors<=0;
            for(S_i=0;S_i<3;S_i=S_i+1) begin S_read_generation[S_i]<=0; S_read_epoch[S_i]<=0; end
        end else begin
            if(O_mount_result_valid && I_mount_result_ready) O_mount_result_valid<=0;
            if(S_mount_accept) begin
                S_mount_busy<=1; S_mount_lost<=0; S_online<=0; S_descriptors<=0;
                O_generation<=O_generation+32'd1;
            end
            if(S_mount_busy && (!I_card_ready || I_unmount)) S_mount_lost<=1;
            if(S_mount_busy && S_mount_result_valid) begin
                S_mount_busy<=0; O_mount_result_valid<=1; O_mount_storage_error<=S_mount_storage_error;
                O_mount_error<=!S_mount_alive || (S_mount_error==0 && !S_mount_mounted) ? 8'd1 : S_mount_error;
                if(S_mount_alive && S_mount_error==0 && S_mount_mounted) begin
                    S_online<=1; O_partition_lba<=S_mount_partition_lba; O_volume_sectors<=S_mount_volume_sectors;
                    O_fat_lba<=S_mount_fat_lba; O_data_lba<=S_mount_data_lba; O_cluster_count<=S_mount_cluster_count;
                    O_root_cluster<=S_mount_root_cluster; O_sectors_per_cluster<=S_mount_sectors_per_cluster;
                    O_cluster_shift<=S_mount_cluster_shift;
                end else S_online<=0;
            end
            if(S_read_accept) begin
                S_pending[I_read_context]<=1; S_read_generation[I_read_context]<=O_generation;
                S_read_epoch[I_read_context]<=I_epoch;
            end
            if(O_done_valid && I_done_ready) S_pending[O_done_context]<=0;
            if(S_cancel_accept) begin
                S_cancel_busy<=1; S_cancel_context<=I_cancel_context;
                if(I_cancel_context<3 && S_pending[I_cancel_context] && S_read_epoch[I_cancel_context]==I_cancel_epoch)
                    S_cancel_generation<=S_read_generation[I_cancel_context];
                else S_cancel_generation<=O_generation;
            end
            if(O_cancel_done_valid && I_cancel_done_ready) S_cancel_busy<=0;
            if(I_close_valid && O_close_ready && I_close_context<3) S_descriptors[I_close_context]<=0;
            if(S_enum_owner && S_open_state!=ENUM_RESULT) begin
                if(I_enum_cancel) S_enum_canceled<=1;
                if(I_enum_stop) S_enum_stopped<=1;
                if(!O_mounted) S_enum_lost<=1;
            end
            if(S_scan_owner) O_enum_warning<=O_enum_warning | S_dir_warning;
            if(S_reserved && S_open_state!=OPEN_RESULT) begin
                if(I_open_cancel) S_open_canceled<=1;
                if(!O_mounted) S_open_lost<=1;
            end
            case(S_open_state)
                OPEN_IDLE:if(S_open_accept) begin
                    O_open_context<=I_open_context; O_open_tag<=I_open_tag; O_open_generation<=O_generation;
                    O_open_size<=0; O_open_first_cluster<=0; O_open_attr<=0; O_open_error<=0;
                    O_open_storage_error<=0; O_open_warning<=0; O_open_sectors<=0;
                    S_open_canceled<=I_open_cancel; S_open_lost<=!O_mounted;
                    if(!O_mounted) open_finish(8'd1);
                    else if(I_open_context==3) open_finish(8'd7);
                    else if(S_target_busy) open_finish(8'd16);
                    else if(I_open_cancel) open_finish(8'd8);
                    else S_open_state<=LOOKUP;
                end else if(S_enum_accept) begin
                    O_enum_tag<=I_enum_tag; O_enum_generation<=O_generation;
                    O_enum_sectors<=0; O_enum_warning<=0; O_enum_error<=0; O_enum_storage_error<=0;
                    S_enum_budget<=I_enum_sector_budget; S_enum_directory<=0;
                    S_enum_canceled<=I_enum_cancel; S_enum_stopped<=I_enum_stop; S_enum_lost<=!O_mounted;
                    if(!O_mounted) enum_finish(8'd1);
                    else if(I_enum_cancel) enum_finish(8'd8);
                    else S_open_state<=ENUM_LOOKUP;
                end
                LOOKUP:if(S_path_result_valid) begin
                    O_open_size<=S_path_size; O_open_first_cluster<=S_path_first_cluster; O_open_attr<=S_path_attr;
                    O_open_warning<=S_path_warning; O_open_sectors<=S_path_sectors; O_open_storage_error<=S_path_storage_error;
                    if(S_open_invalid) open_finish(8'd1);
                    else if(S_open_stop) open_finish(8'd8);
                    else if(S_path_error!=0) open_finish(S_path_error);
                    else if(S_path_attr[4]) open_finish(8'd17);
                    else S_open_state<=LOAD;
                end
                LOAD:if(S_open_invalid) open_finish(8'd1);
                    else if(S_open_stop) open_finish(8'd8);
                    else if(S_load_ready) S_open_state<=LOAD_WAIT;
                LOAD_WAIT:if(S_load_result) begin
                    if(S_load_error!=0) open_finish(S_open_invalid ? 8'd1 : (S_open_stop ? 8'd8 : S_load_error));
                    else if(S_open_invalid || S_open_stop) S_open_state<=ROLLBACK;
                    else begin S_descriptors[O_open_context]<=1; open_finish(8'd0); end
                end
                ROLLBACK:if(S_close_ready) open_finish(S_open_invalid ? 8'd1 : 8'd8);
                OPEN_RESULT:if(I_open_result_ready) S_open_state<=OPEN_IDLE;
                ENUM_LOOKUP:if(S_path_result_valid) begin
                    O_enum_sectors<=S_path_sectors; O_enum_warning<=S_path_warning;
                    O_enum_storage_error<=S_path_storage_error; S_enum_directory<=S_path_first_cluster;
                    if(S_enum_invalid) enum_finish(8'd1);
                    else if(S_enum_cancel) enum_finish(8'd8);
                    else if(S_path_error!=0) enum_finish(S_path_error);
                    else if(!S_path_attr[4]) enum_finish(8'd15);
                    else if(S_enum_stop) enum_finish(8'd0);
                    else if(S_path_sectors>=S_enum_budget) enum_finish(8'd10);
                    else S_open_state<=ENUM_START;
                end
                ENUM_START:if(S_enum_invalid) enum_finish(8'd1);
                    else if(S_enum_cancel) enum_finish(8'd8);
                    else if(S_enum_stop) enum_finish(8'd0);
                    else if(S_dir_ready) S_open_state<=ENUM_SCAN;
                ENUM_SCAN:if(S_dir_done) begin
                    O_enum_sectors<=O_enum_sectors+S_dir_sectors;
                    O_enum_storage_error<=S_dir_storage_error;
                    if(S_enum_invalid) enum_finish(8'd1);
                    else if(S_enum_cancel) enum_finish(8'd8);
                    else enum_finish(S_dir_error);
                end
                ENUM_RESULT:if(I_enum_done_ready) S_open_state<=OPEN_IDLE;
                default:open_finish(8'd7);
            endcase
            // Loss never alters a published result, and never clears pending I/O.
            if(!I_card_ready || I_unmount) begin S_online<=0; S_descriptors<=0; end
        end
    end

    fat32_mount u_mount (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_card_ready(S_mount_alive),
        .I_capacity_sectors(I_capacity_sectors),
        .I_start_valid(S_mount_accept),
        .O_start_ready(S_mount_ready),
        .O_result_valid(S_mount_result_valid),
        .I_result_ready(S_mount_busy),
        .O_error(S_mount_error),
        .O_storage_error(S_mount_storage_error),
        .O_mounted(S_mount_mounted),
        .O_partition_lba(S_mount_partition_lba),
        .O_volume_sectors(S_mount_volume_sectors),
        .O_fat_lba(S_mount_fat_lba),
        .O_data_lba(S_mount_data_lba),
        .O_cluster_count(S_mount_cluster_count),
        .O_root_cluster(S_mount_root_cluster),
        .O_sectors_per_cluster(S_mount_sectors_per_cluster),
        .O_cluster_shift(S_mount_cluster_shift),
        .O_read_valid(S_mount_read_valid),
        .I_read_ready(S_ready[0]),
        .O_read_lba(S_mount_read_lba),
        .I_read_result_valid(S_result[0]),
        .O_read_result_ready(S_mount_read_result_ready),
        .I_read_error(S_error[7:0]),
        .I_storage_error(S_storage_error[3:0]),
        .O_buffer_address(S_mount_buffer_address),
        .I_buffer_data(S_buffer_data[7:0]));
    fat32_path_lookup u_path (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_mounted(O_mounted),
        .I_fat_lba(O_fat_lba),
        .I_data_lba(O_data_lba),
        .I_cluster_count(O_cluster_count),
        .I_root_cluster(O_root_cluster),
        .I_cluster_shift(O_cluster_shift),
        .I_start_valid(S_path_start),
        .O_start_ready(S_path_ready),
        .I_path_length(S_enum_accept ? I_enum_path_length : I_path_length),
        .I_sector_budget(S_enum_accept ? I_enum_sector_budget : I_sector_budget),
        .I_path_valid(S_enum_owner ? (I_enum_path_valid && S_open_state==ENUM_LOOKUP) : (I_path_valid && S_open_state==LOOKUP)),
        .O_path_ready(S_path_byte_ready),
        .I_path_data(S_enum_owner ? I_enum_path_data : I_path_data),
        .I_path_last(S_enum_owner ? I_enum_path_last : I_path_last),
        // A newly accepted command must not inherit its predecessor's sticky cancel.
        .I_cancel(S_enum_accept ? I_enum_cancel : (S_open_accept ? I_open_cancel :
            (S_enum_owner ? S_enum_cancel : S_open_stop))),
        .O_result_valid(S_path_result_valid),
        .I_result_ready(S_open_state==LOOKUP || S_open_state==ENUM_LOOKUP),
        .O_attr(S_path_attr),
        .O_size(S_path_size),
        .O_first_cluster(S_path_first_cluster),
        .O_sectors(S_path_sectors),
        .O_warning(S_path_warning),
        .O_error(S_path_error),
        .O_storage_error(S_path_storage_error),
        .O_read_valid(S_path_read_valid),
        .I_read_ready(S_ready[1] && !S_scan_owner),
        .O_read_lba(S_path_read_lba),
        .O_read_abort(S_path_read_abort),
        .I_read_result_valid(S_result[1] && !S_scan_owner),
        .O_read_result_ready(S_path_read_result_ready),
        .I_read_error(S_error[15:8]),
        .I_storage_error(S_storage_error[7:4]),
        .O_buffer_address(S_path_buffer_address),
        .I_buffer_data(S_buffer_data[15:8]));
    // The scanner gets client 1 only after lookup has joined and retired.
    fat32_directory u_enum_directory (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(O_mounted && !S_enum_lost),
        .I_fat_lba(O_fat_lba),.I_data_lba(O_data_lba),.I_cluster_count(O_cluster_count),.I_cluster_shift(O_cluster_shift),
        .I_start_valid(S_open_state==ENUM_START && !S_enum_cancel && !S_enum_stop && !S_enum_invalid),
        .O_start_ready(S_dir_ready),.I_first_cluster(S_enum_directory),.I_sector_budget(S_enum_budget-O_enum_sectors),
        .I_stop(S_enum_stop),.I_cancel(S_enum_cancel || S_enum_invalid),
        .O_entry_valid(O_enum_entry_valid),.I_entry_ready(I_enum_entry_ready && S_scan_owner),
        .O_attr(O_enum_attr),.O_size(O_enum_size),.O_first_cluster(O_enum_first_cluster),.O_alias(O_enum_alias),
        .O_name_length(O_enum_name_length),.O_is_lfn(O_enum_is_lfn),
        .O_name_valid(O_enum_name_valid),.I_name_ready(I_enum_name_ready && S_scan_owner),
        .O_name_data(O_enum_name_data),.O_name_last(O_enum_name_last),
        .O_done_valid(S_dir_done),.I_done_ready(S_scan_owner),.O_error(S_dir_error),
        .O_storage_error(S_dir_storage_error),.O_sectors(S_dir_sectors),.O_warning(S_dir_warning),
        .O_read_valid(S_dir_read_valid),.I_read_ready(S_ready[1] && S_scan_owner),.O_read_lba(S_dir_read_lba),
        .O_read_abort(S_dir_read_abort),.I_read_result_valid(S_result[1] && S_scan_owner),
        .O_read_result_ready(S_dir_read_result_ready),.I_read_error(S_error[15:8]),.I_storage_error(S_storage_error[7:4]),
        .O_buffer_address(S_dir_buffer_address),.I_buffer_data(S_buffer_data[15:8]));
    fat32_file_reader u_files (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_mounted(O_mounted),
        .I_fat_lba(O_fat_lba),
        .I_data_lba(O_data_lba),
        .I_cluster_count(O_cluster_count),
        .I_cluster_shift(O_cluster_shift),
        .I_load_valid(S_load_valid),
        .O_load_ready(S_load_ready),
        .I_load_context(O_open_context),
        .I_first_cluster(O_open_first_cluster),
        .I_file_size(O_open_size),
        .O_load_result_valid(S_load_result),
        .I_load_result_ready(S_open_state==LOAD_WAIT),
        .O_load_context(S_load_context),
        .O_load_error(S_load_error),
        .I_close_valid(S_close_valid),
        .O_close_ready(S_close_ready),
        .I_close_context(S_close_context),
        .I_read_valid(I_read_valid && S_read_allow),
        .O_read_ready(S_file_read_ready),
        .I_read_context(I_read_context),
        .I_read_priority(I_read_priority),
        .I_offset(I_offset),
        .I_length(I_length),
        .I_epoch(I_epoch),
        .I_urgent_context(I_urgent_context),
        .O_byte_valid(O_byte_valid),
        .I_byte_ready(I_byte_ready),
        .O_byte_data(O_byte_data),
        .O_byte_context(O_byte_context),
        .O_byte_epoch(O_byte_epoch),
        .O_byte_offset(O_byte_offset),
        .O_byte_last(O_byte_last),
        .O_done_valid(O_done_valid),
        .I_done_ready(I_done_ready),
        .O_done_context(O_done_context),
        .O_done_epoch(O_done_epoch),
        .O_done_bytes(O_done_bytes),
        .O_done_eof(O_done_eof),
        .O_done_error(O_done_error),
        .O_done_storage_error(O_done_storage_error),
        .I_cancel_valid(I_cancel_valid && S_cancel_allow),
        .O_cancel_ready(S_file_cancel_ready),
        .I_cancel_context(I_cancel_context),
        .I_cancel_epoch(I_cancel_epoch),
        .O_cancel_done_valid(O_cancel_done_valid),
        .I_cancel_done_ready(I_cancel_done_ready),
        .O_cancel_done_context(O_cancel_done_context),
        .O_cancel_done_epoch(O_cancel_done_epoch),
        .O_sector_valid(S_file_valid),
        .I_sector_ready(S_ready[2]),
        .O_sector_lba(S_file_lba),
        .O_sector_context(S_file_context),
        .O_sector_priority(S_file_priority),
        .O_sector_abort(S_file_abort),
        .I_sector_result_valid(S_result[2]),
        .O_sector_result_ready(S_file_result_ready),
        .I_sector_error(S_error[23:16]),
        .I_sector_storage_error(S_storage_error[11:8]),
        .O_buffer_address(S_file_address),
        .I_buffer_data(S_buffer_data[23:16]));
    fat32_sector_arbiter u_arbiter (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_card_ready(I_card_ready),
        .I_read_valid({S_file_valid,S_namespace_valid,S_mount_read_valid}),
        .O_read_ready(S_ready),
        .I_read_lba({S_file_lba,S_namespace_lba,S_mount_read_lba}),
        .I_context({S_file_context,2'd0,2'd0}),
        .I_priority({S_file_priority,2'd0,2'd0}),
        .I_urgent({S_file_urgent,2'b00}),
        .I_abort({S_file_abort,S_namespace_abort,1'b0}),
        .O_result_valid(S_result),
        .I_result_ready({S_file_result_ready,S_namespace_result_ready,S_mount_read_result_ready}),
        .O_error(S_error),
        .O_storage_error(S_storage_error),
        .I_buffer_address({S_file_address,S_namespace_address,S_mount_buffer_address}),
        .O_buffer_data(S_buffer_data),
        .O_port_valid(S_port_valid),
        .I_port_ready(S_port_ready),
        .O_port_lba(S_port_lba),
        .O_port_context(S_port_context),
        .O_port_priority(S_port_priority),
        .O_port_abort(S_port_abort),
        .I_port_result_valid(S_port_result),
        .O_port_result_ready(S_port_result_ready),
        .I_port_error(S_port_error),
        .I_port_storage_error(S_port_storage_error),
        .O_port_buffer_address(S_port_address),
        .I_port_buffer_data(S_port_data));
    fat32_sector_port u_port (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_card_ready(I_card_ready),
        .I_start_valid(S_port_valid),
        .O_start_ready(S_port_ready),
        .I_lba(S_port_lba),
        .I_context(S_port_context),
        .I_priority(S_port_priority),
        .I_abort(S_port_abort),
        .O_result_valid(S_port_result),
        .I_result_ready(S_port_result_ready),
        .O_error(S_port_error),
        .O_storage_error(S_port_storage_error),
        .I_buffer_address(S_port_address),
        .O_buffer_data(S_port_data),
        .O_request_valid(O_sd_request_valid),
        .I_request_ready(I_sd_request_ready),
        .O_lba(O_sd_lba),
        .O_count(O_sd_count),
        .O_context(O_sd_context),
        .O_priority(O_sd_priority),
        .O_tag(O_sd_tag),
        .I_byte_valid(I_sd_byte_valid),
        .O_byte_ready(O_sd_byte_ready),
        .I_byte_data(I_sd_byte_data),
        .I_sector_last(I_sd_sector_last),
        .I_request_last(I_sd_request_last),
        .I_byte_context(I_sd_byte_context),
        .I_byte_tag(I_sd_byte_tag),
        .I_done_valid(I_sd_done_valid),
        .O_done_ready(O_sd_done_ready),
        .I_done_context(I_sd_done_context),
        .I_done_tag(I_sd_done_tag),
        .I_done_error(I_sd_done_error),
        .O_cancel_valid(O_sd_cancel_valid),
        .I_cancel_ready(I_sd_cancel_ready),
        .O_cancel_context(O_sd_cancel_context),
        .O_cancel_tag(O_sd_cancel_tag),
        .I_cancel_done_valid(I_sd_cancel_done_valid),
        .O_cancel_done_ready(O_sd_cancel_done_ready),
        .I_cancel_done_context(I_sd_cancel_done_context),
        .I_cancel_done_tag(I_sd_cancel_done_tag));
endmodule
