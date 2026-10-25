// Root-only FAT32 catalog and two file streams. No paths, playlist, demo or mux tree.
// All ports are host-domain. The checked sector RAM has exactly one phase owner.
module lean_media_source (
    input wire I_clk,I_reset,I_card_ready,
    input wire [32:0] I_capacity_sectors,
    output reg O_catalog_ready,
    output reg [4:0] O_image_count,
    output reg O_audio_found,O_catalog_overflow,
    output reg [7:0] O_catalog_error,
    input wire I_command_valid,
    output wire O_command_ready,
    input wire I_command_audio,
    input wire [3:0] I_image_index,
    input wire [31:0] I_offset,I_length,
    output wire O_begin_valid,
    input wire I_begin_ready,
    output wire O_begin_audio,
    output reg [31:0] O_file_size,
    output reg [7:0] O_begin_error,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire [1:0] O_byte_context,
    output wire [31:0] O_byte_offset,
    output wire O_byte_last,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [1:0] O_done_context,
    output wire [7:0] O_done_error,
    output wire [31:0] O_done_bytes,
    output wire O_done_eof,
    input wire [1:0] I_cancel,
    output wire O_request_valid,
    input wire I_request_ready,
    output wire [31:0] O_lba,
    output wire [7:0] O_count,
    output wire [1:0] O_context,O_priority,
    output wire [15:0] O_tag,
    input wire I_sd_byte_valid,
    output wire O_sd_byte_ready,
    input wire [7:0] I_sd_byte_data,
    input wire I_sector_last,I_request_last,
    input wire [1:0] I_sd_byte_context,
    input wire [15:0] I_sd_byte_tag,
    input wire I_sd_done_valid,
    output wire O_sd_done_ready,
    input wire [1:0] I_sd_done_context,
    input wire [15:0] I_sd_done_tag,
    input wire [3:0] I_sd_done_error,
    output wire O_cancel_valid,
    input wire I_cancel_ready,
    output wire [1:0] O_cancel_context,
    output wire [15:0] O_cancel_tag,
    input wire I_cancel_done_valid,
    output wire O_cancel_done_ready,
    input wire [1:0] I_cancel_done_context,
    input wire [15:0] I_cancel_done_tag
);
    localparam [3:0] WAIT_CARD=0,MOUNT_START=1,MOUNT_WAIT=2,
        SCAN_START=3,SCAN_WAIT=4,ONLINE=5,RETIRE=6,RETRY=7;
    localparam [2:0] CMD_IDLE=0,META_WAIT=1,LOAD=2,LOAD_WAIT=3,BEGIN=4,READ=5,META_PRIME=6;
    reg [3:0] S_phase;
    reg [2:0] S_command;
    reg S_audio,S_audio_loaded,S_cancel_active;
    reg [1:0] S_pending,S_cancel_seen;
    reg [31:0] S_offset,S_length,S_first,S_audio_first,S_audio_size;
    reg [3:0] S_index;
    reg [23:0] S_retry;
    // 16 descriptors, synchronous read; no reset of the memory itself.
    (* ram_style="dram" *) reg [63:0] S_images[0:15];
    reg [63:0] S_metadata;
    reg S_local_done,S_local_audio;
    wire S_file_done,S_file_eof;
    wire [1:0] S_file_done_context;
    wire [7:0] S_file_done_error;
    wire [31:0] S_file_done_bytes;
    wire S_mount_ready,S_mount_done,S_mounted;
    wire [7:0] S_mount_error;
    wire [31:0] S_fat,S_data,S_clusters,S_root;
    wire [2:0] S_shift;
    wire S_m_valid,S_m_ready,S_m_result,S_m_take;
    wire [31:0] S_m_lba;
    wire [8:0] S_m_address;
    wire S_d_valid,S_d_ready,S_d_result,S_d_take,S_d_abort;
    wire [31:0] S_d_lba;
    wire [8:0] S_d_address;
    wire S_scan_ready,S_scan_done,S_entry;
    wire [7:0] S_scan_error;
    wire [31:0] S_entry_size,S_entry_first;
    wire S_entry_audio;
    wire S_bmp=!S_entry_audio;
    wire S_wav=S_entry_audio;
    wire S_f_valid,S_f_ready,S_f_result,S_f_take,S_f_abort;
    wire [31:0] S_f_lba;
    wire [1:0] S_f_context,S_f_priority;
    wire [8:0] S_f_address;
    wire S_port_ready,S_port_result,S_port_take;
    wire [7:0] S_port_error,S_buffer_data;
    wire [3:0] S_port_storage;
    wire S_mount_owner=S_phase==MOUNT_START || S_phase==MOUNT_WAIT;
    wire S_scan_owner=S_phase==SCAN_START || S_phase==SCAN_WAIT;
    wire S_port_valid=S_mount_owner ? S_m_valid : S_scan_owner ? S_d_valid : S_f_valid;
    wire [31:0] S_port_lba=S_mount_owner ? S_m_lba : S_scan_owner ? S_d_lba : S_f_lba;
    wire [8:0] S_port_address=S_mount_owner ? S_m_address : S_scan_owner ? S_d_address : S_f_address;
    wire S_port_abort=S_scan_owner ? S_d_abort : !S_mount_owner && S_f_abort;
    wire S_load_ready,S_load_done,S_read_ready;
    wire [7:0] S_load_error;
    wire S_file_cancel_ready,S_file_cancel_done;
    wire [1:0] S_file_cancel_context;
    wire S_cancel_request=|(I_cancel & S_pending & ~S_cancel_seen);
    wire [1:0] S_cancel_pick=(I_cancel[1] && S_pending[1] && !S_cancel_seen[1]) ? 2'd1 : 2'd0;
    wire S_read_fire=S_command==READ && S_read_ready && O_catalog_ready && I_card_ready;
    wire S_load_fire=S_command==LOAD && S_load_ready && O_catalog_ready && I_card_ready;
    assign O_command_ready=!I_reset && O_catalog_ready && I_card_ready &&
        S_command==CMD_IDLE && !S_local_done && !S_pending[I_command_audio] &&
        !I_cancel[I_command_audio] && (!I_command_audio || O_audio_found);
    assign O_begin_valid=!I_reset && S_command==BEGIN;
    assign O_begin_audio=S_audio;
    assign O_done_valid=S_file_done || S_local_done;
    assign O_done_context=S_file_done ? S_file_done_context : {1'b0,S_local_audio};
    assign O_done_error=S_file_done ? S_file_done_error : 8'd1;
    assign O_done_bytes=S_file_done ? S_file_done_bytes : 32'd0;
    assign O_done_eof=S_file_done && S_file_eof;
    assign S_m_ready=S_port_ready && S_mount_owner;
    assign S_d_ready=S_port_ready && S_scan_owner;
    assign S_f_ready=S_port_ready && !S_mount_owner && !S_scan_owner;
    assign S_m_result=S_port_result && S_mount_owner;
    assign S_d_result=S_port_result && S_scan_owner;
    assign S_f_result=S_port_result && !S_mount_owner && !S_scan_owner;
    assign S_port_take=S_mount_owner ? S_m_take : S_scan_owner ? S_d_take : S_f_take;

    fat32_mount u_mount (
        .I_clk(I_clk),.I_reset(I_reset),.I_card_ready(I_card_ready),.I_capacity_sectors(I_capacity_sectors),
        .I_start_valid(S_phase==MOUNT_START),.O_start_ready(S_mount_ready),
        .O_result_valid(S_mount_done),.I_result_ready(S_phase==MOUNT_WAIT),
        .O_error(S_mount_error),.O_mounted(S_mounted),.O_fat_lba(S_fat),.O_data_lba(S_data),
        .O_cluster_count(S_clusters),.O_root_cluster(S_root),.O_cluster_shift(S_shift),
        .O_read_valid(S_m_valid),.I_read_ready(S_m_ready),.O_read_lba(S_m_lba),
        .I_read_result_valid(S_m_result),.O_read_result_ready(S_m_take),
        .I_read_error(S_port_error),.I_storage_error(S_port_storage),
        .O_buffer_address(S_m_address),.I_buffer_data(S_buffer_data),
        .O_storage_error(), .O_partition_lba(), .O_volume_sectors(), .O_sectors_per_cluster()
    );
    lean_root_scan u_directory (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(S_mounted && I_card_ready),
        .I_fat_lba(S_fat),.I_data_lba(S_data),.I_cluster_count(S_clusters),.I_cluster_shift(S_shift),
        .I_start_valid(S_phase==SCAN_START),.O_start_ready(S_scan_ready),
        .I_first_cluster(S_root),.O_entry_valid(S_entry),.O_entry_audio(S_entry_audio),
        .O_size(S_entry_size),.O_first_cluster(S_entry_first),
        .O_done_valid(S_scan_done),.I_done_ready(S_phase==SCAN_WAIT),.O_error(S_scan_error),
        .O_read_valid(S_d_valid),.I_read_ready(S_d_ready),.O_read_lba(S_d_lba),.O_read_abort(S_d_abort),
        .I_read_result_valid(S_d_result),.O_read_result_ready(S_d_take),
        .I_read_error(S_port_error),.I_storage_error(S_port_storage),
        .O_buffer_address(S_d_address),.I_buffer_data(S_buffer_data)
    );
    fat32_file_reader #(.CONTEXTS(2)) u_files (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(O_catalog_ready && I_card_ready),
        .I_fat_lba(S_fat),.I_data_lba(S_data),.I_cluster_count(S_clusters),.I_cluster_shift(S_shift),
        .I_load_valid(S_command==LOAD && O_catalog_ready && I_card_ready),.O_load_ready(S_load_ready),
        .I_load_context({1'b0,S_audio}),.I_first_cluster(S_first),.I_file_size(O_file_size),
        .O_load_result_valid(S_load_done),.I_load_result_ready(S_command==LOAD_WAIT),.O_load_error(S_load_error),
        .I_close_valid(1'b0),.I_close_context(2'd0),
        .I_read_valid(S_command==READ && O_catalog_ready && I_card_ready),.O_read_ready(S_read_ready),
        .I_read_context({1'b0,S_audio}),.I_read_priority(S_audio ? 2'd2 : 2'd0),
        .I_offset(S_offset),.I_length(S_length),.I_epoch(16'd0),.I_urgent_context(3'd0),
        .O_byte_valid(O_byte_valid),.I_byte_ready(I_byte_ready),.O_byte_data(O_byte_data),
        .O_byte_context(O_byte_context),.O_byte_offset(O_byte_offset),.O_byte_last(O_byte_last),
        .O_done_valid(S_file_done),.I_done_ready(I_done_ready),.O_done_context(S_file_done_context),
        .O_done_bytes(S_file_done_bytes),.O_done_eof(S_file_eof),.O_done_error(S_file_done_error),
        .I_cancel_valid(S_cancel_request && !S_cancel_active),.O_cancel_ready(S_file_cancel_ready),
        .I_cancel_context(S_cancel_pick),.I_cancel_epoch(16'd0),
        .O_cancel_done_valid(S_file_cancel_done),.I_cancel_done_ready(1'b1),.O_cancel_done_context(S_file_cancel_context),
        .O_sector_valid(S_f_valid),.I_sector_ready(S_f_ready),.O_sector_lba(S_f_lba),
        .O_sector_context(S_f_context),.O_sector_priority(S_f_priority),.O_sector_abort(S_f_abort),
        .I_sector_result_valid(S_f_result),.O_sector_result_ready(S_f_take),
        .I_sector_error(S_port_error),.I_sector_storage_error(S_port_storage),
        .O_buffer_address(S_f_address),.I_buffer_data(S_buffer_data),
        .O_load_context(), .O_close_ready(), .O_byte_epoch(), .O_done_epoch(), .O_done_storage_error(), .O_cancel_done_epoch()
    );
    fat32_sector_port u_sector (
        .I_clk(I_clk),.I_reset(I_reset),.I_card_ready(I_card_ready),
        .I_start_valid(S_port_valid),.O_start_ready(S_port_ready),.I_lba(S_port_lba),
        .I_context(S_mount_owner || S_scan_owner ? 2'd0 : S_f_context),
        .I_priority(S_mount_owner || S_scan_owner ? 2'd0 : S_f_priority),.I_abort(S_port_abort),
        .O_result_valid(S_port_result),.I_result_ready(S_port_take),.O_error(S_port_error),.O_storage_error(S_port_storage),
        .I_buffer_address(S_port_address),.O_buffer_data(S_buffer_data),
        .O_request_valid(O_request_valid),.I_request_ready(I_request_ready),.O_lba(O_lba),.O_count(O_count),
        .O_context(O_context),.O_priority(O_priority),.O_tag(O_tag),
        .I_byte_valid(I_sd_byte_valid),.O_byte_ready(O_sd_byte_ready),.I_byte_data(I_sd_byte_data),
        .I_sector_last(I_sector_last),.I_request_last(I_request_last),.I_byte_context(I_sd_byte_context),.I_byte_tag(I_sd_byte_tag),
        .I_done_valid(I_sd_done_valid),.O_done_ready(O_sd_done_ready),.I_done_context(I_sd_done_context),
        .I_done_tag(I_sd_done_tag),.I_done_error(I_sd_done_error),
        .O_cancel_valid(O_cancel_valid),.I_cancel_ready(I_cancel_ready),.O_cancel_context(O_cancel_context),.O_cancel_tag(O_cancel_tag),
        .I_cancel_done_valid(I_cancel_done_valid),.O_cancel_done_ready(O_cancel_done_ready),
        .I_cancel_done_context(I_cancel_done_context),.I_cancel_done_tag(I_cancel_done_tag)
    );
    always @(posedge I_clk) begin
        S_metadata<=S_images[S_index];
        if(S_phase==SCAN_WAIT && S_entry && S_bmp && O_image_count<16)
            S_images[O_image_count[3:0]]<={S_entry_first,S_entry_size};
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_phase<=WAIT_CARD; S_command<=CMD_IDLE; S_pending<=0; S_audio<=0; S_audio_loaded<=0;
            S_offset<=0; S_length<=0; S_first<=0; S_index<=0; S_retry<=0;
            S_audio_first<=0; S_audio_size<=0; S_cancel_active<=0; S_cancel_seen<=0;
            S_local_done<=0; S_local_audio<=0;
            O_catalog_ready<=0; O_image_count<=0; O_audio_found<=0; O_catalog_overflow<=0;
            O_catalog_error<=0; O_file_size<=0; O_begin_error<=0;
        end else begin
            if(S_local_done && !S_file_done && I_done_ready) S_local_done<=0;
            if(S_read_fire) begin S_pending[S_audio]<=1; S_cancel_seen[S_audio]<=0; end
            if(O_done_valid && I_done_ready) S_pending[O_done_context[0]]<=0;
            if(S_cancel_request && !S_cancel_active && S_file_cancel_ready) begin
                S_cancel_active<=1; S_cancel_seen[S_cancel_pick[0]]<=1;
            end
            if(S_file_cancel_done) S_cancel_active<=0;
            if(!I_card_ready) begin O_catalog_ready<=0; S_audio_loaded<=0; end
            case(S_phase)
                WAIT_CARD: if(I_card_ready) begin
                    O_image_count<=0; O_audio_found<=0; O_catalog_overflow<=0; O_catalog_error<=0;
                    S_phase<=MOUNT_START;
                end
                MOUNT_START: if(S_mount_ready) S_phase<=MOUNT_WAIT;
                MOUNT_WAIT: if(S_mount_done) begin
                    if(S_mount_error!=0 || !I_card_ready) begin
                        O_catalog_error<=S_mount_error; S_phase<=RETIRE;
                    end else S_phase<=SCAN_START;
                end
                SCAN_START: if(S_scan_ready) S_phase<=SCAN_WAIT;
                SCAN_WAIT: begin
                    if(S_entry) begin
                        if(S_bmp) begin
                            if(O_image_count<16) O_image_count<=O_image_count+1'b1;
                            else O_catalog_overflow<=1;
                        end
                        if(S_wav && !O_audio_found) begin
                            O_audio_found<=1; S_audio_first<=S_entry_first; S_audio_size<=S_entry_size;
                        end
                    end
                    if(S_scan_done) begin
                        if(S_scan_error!=0 || !I_card_ready || O_image_count==0) begin
                            O_catalog_error<=S_scan_error!=0 ? S_scan_error : 8'h80; S_phase<=RETIRE;
                        end else begin O_catalog_ready<=1; S_phase<=ONLINE; end
                    end
                end
                ONLINE: if(!I_card_ready) S_phase<=RETIRE;
                RETIRE: if(S_pending==0 && S_port_ready && S_command==CMD_IDLE && !S_cancel_active) begin
                    S_retry<=0; S_phase<=RETRY;
                end
                RETRY: begin
                    S_retry<=S_retry+1'b1;
                    if(!I_card_ready || &S_retry) S_phase<=WAIT_CARD;
                end
                default:S_phase<=WAIT_CARD;
            endcase
            case(S_command)
                CMD_IDLE: if(I_command_valid && O_command_ready) begin
                    S_audio<=I_command_audio; S_index<=I_image_index; S_offset<=I_offset; S_length<=I_length;
                    O_begin_error<=(!I_command_audio && {1'b0,I_image_index}>=O_image_count) ? 8'd7 : 8'd0;
                    // Two clock edges before consuming the synchronous descriptor.
                    S_command<=META_PRIME;
                end
                META_PRIME:S_command<=META_WAIT;
                META_WAIT: begin
                    S_first<=S_audio ? S_audio_first : S_metadata[63:32];
                    O_file_size<=S_audio ? S_audio_size : S_metadata[31:0];
                    if(!O_catalog_ready || !I_card_ready) begin O_begin_error<=1; S_command<=BEGIN; end
                    else if(O_begin_error!=0) S_command<=BEGIN;
                    else S_command<=S_audio && S_audio_loaded ? BEGIN : LOAD;
                end
                LOAD: if(!O_catalog_ready || !I_card_ready) begin O_begin_error<=1; S_command<=BEGIN; end
                    else if(S_load_fire) S_command<=LOAD_WAIT;
                LOAD_WAIT: if(S_load_done) begin
                    O_begin_error<=S_load_error;
                    if(S_audio && S_load_error==0) S_audio_loaded<=1;
                    S_command<=BEGIN;
                end
                BEGIN: if(I_begin_ready) begin
                    if(O_begin_error!=0) S_command<=CMD_IDLE;
                    else S_command<=READ;
                end
                READ: if(!O_catalog_ready || !I_card_ready) begin
                    S_local_done<=1; S_local_audio<=S_audio; S_command<=CMD_IDLE;
                end else if(S_read_fire) S_command<=CMD_IDLE;
                default:S_command<=CMD_IDLE;
            endcase
        end
    end
endmodule
