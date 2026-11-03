// Image playback, WAV caching, memory arbitration and user control.
// The board wrapper supplies SD SPI, native SDRAM and the HDMI transmitter.
module lean_player_core #(
    parameter integer HOST_CLOCK_HZ=83333333,
    parameter integer AUDIO_CACHE=1
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire [3:0] I_key_release,
    input wire I_rx_valid,I_rx_error,
    input wire [7:0] I_rx_data,
    output wire O_tx_valid,
    input wire I_tx_ready,
    output wire [7:0] O_tx_data,
    input wire I_card_ready,
    input wire [32:0] I_capacity_sectors,
    input wire I_memory_ready,I_memory_error,I_writes_idle,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [20:0] O_read_address,
    output wire [31:0] O_read_tag,
    input wire I_result_valid,
    output wire O_result_ready,
    input wire [31:0] I_result_data,I_result_tag,
    input wire [3:0] I_result_error,
    output wire O_write_valid,
    input wire I_write_ready,
    output wire [20:0] O_write_address,
    output wire [31:0] O_write_data,
    output wire O_de,O_valid,
    output wire [15:0] O_x,O_y,
    output wire [23:0] O_rgb,
    output wire O_sample_valid,
    output wire [23:0] O_audio_left,O_audio_right,
    output wire O_acr_valid,
    output wire [19:0] O_acr_n,O_acr_cts,
    output reg O_active,
    output wire O_busy,
    output reg [3:0] O_current,
    output wire [4:0] O_count,
    output wire [3:0] O_error,
    output wire O_request_valid,
    input wire I_request_ready,
    output wire [31:0] O_lba,
    output wire [7:0] O_count_sectors,
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
    localparam [2:0] IDLE=0,COMMAND=1,BEGIN=2,LOAD=3,COMMIT=4,ACK=5,FAILED=6;
    reg [2:0] S_state;
    wire S_hrst,S_vrst;
    reset_sync u_hrst(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_hrst));
    reset_sync u_vrst(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_vrst));
    wire S_catalog,S_audio_found;
    wire [7:0] S_catalog_error,S_mount_type;
    wire S_next,S_prev,S_reload,S_auto,S_mute;
    wire [1:0] S_rotation;
    wire [2:0] S_volume;
    wire [5:0] S_interval;
    reg S_media_seen,S_need,S_active_slot,S_job_slot,S_changed;
    reg [3:0] S_target,S_job_index,S_image_error;
    reg [1:0] S_job_rotation,S_active_rotation;
    reg [4:0] S_failures;
    wire S_command_ready,S_begin,S_begin_ready,S_begin_audio;
    wire [31:0] S_file_size,S_byte_offset,S_file_bytes;
    wire [7:0] S_begin_error,S_byte,S_file_error;
    wire S_byte_valid,S_byte_ready,S_byte_last,S_file_done,S_file_eof;
    wire [1:0] S_byte_context,S_file_context;
    wire S_loader_ready,S_loader_done,S_loader_cancel;
    wire [3:0] S_loader_error;
    wire S_image_byte_ready,S_image_stream_pause,S_audio_reserve;
    wire S_cache_ready,S_cache_loading,S_source_audio_request,S_source_audio_begin_ready;
    wire S_source_audio_byte_ready,S_source_audio_cancel;
    wire [31:0] S_source_audio_offset,S_source_audio_length;
    wire S_audio_begin_valid,S_audio_file_done,S_audio_file_eof;
    wire [31:0] S_audio_file_size,S_audio_byte_offset,S_audio_file_bytes;
    wire [7:0] S_audio_begin_error,S_audio_byte,S_audio_file_error;
    wire S_audio_byte_valid;
    wire [3:0] S_cache_error;
    wire S_cache_read,S_cache_read_ready,S_cache_result_ready,S_cache_write,S_cache_write_ready;
    wire [20:0] S_cache_read_address,S_cache_write_address;
    wire [31:0] S_cache_write_data;
    wire S_scan_read,S_scan_read_ready,S_scan_result_ready,S_loader_write,S_loader_write_ready,S_all_writes_idle;
    wire [20:0] S_scan_read_address,S_loader_write_address;
    wire [31:0] S_scan_read_tag,S_loader_write_data;
    // Reserve a whole checked sector before admitting an image read. SDRAM
    // stalls cannot strand audio behind a partly consumed image sector.
    (* ram_style="bram" *) reg [8:0] S_image_queue[0:1023];
    reg [9:0] S_image_wr,S_image_rd;
    reg [10:0] S_image_count;
    reg [8:0] S_image_head;
    reg S_image_valid;
    wire S_image_push=S_byte_valid && S_byte_context==0 && S_byte_ready;
    wire S_image_pop=S_image_valid && S_image_byte_ready;
    wire S_image_pause=S_image_stream_pause || S_image_count>512 ||
        (AUDIO_CACHE ? S_cache_loading : S_audio_reserve);
    wire [9:0] S_image_read_address=S_image_rd+S_image_pop;
    wire S_image_head_available=S_image_count>{10'd0,S_image_pop};
    always @(posedge I_host_clk) begin
        if(S_image_push) S_image_queue[S_image_wr]<={S_byte_last,S_byte};
        if((!S_image_valid || S_image_byte_ready) && S_image_head_available)
            S_image_head<=S_image_queue[S_image_read_address];
    end
    always @(posedge I_host_clk or posedge S_hrst) begin
        if(S_hrst) begin S_image_wr<=0; S_image_rd<=0; S_image_count<=0; S_image_valid<=0; end
        else if(!S_catalog || !I_card_ready || S_loader_cancel) begin
            S_image_wr<=0; S_image_rd<=0; S_image_count<=0; S_image_valid<=0;
        end else begin
            if(!S_image_valid || S_image_byte_ready) S_image_valid<=S_image_head_available;
            if(S_image_push) begin
                S_image_wr<=S_image_wr+1'b1;
            end
            if(S_image_pop) S_image_rd<=S_image_rd+1'b1;
            case({S_image_push,S_image_pop})
                2'b10:S_image_count<=S_image_count+1'b1;
                2'b01:S_image_count<=S_image_count-1'b1;
                default:begin end
            endcase
        end
    end
    wire S_audio_request,S_audio_command_ready,S_audio_begin_ready,S_audio_byte_ready,S_audio_cancel;
    wire [31:0] S_audio_offset,S_audio_length;
    wire [3:0] S_audio_error;
    wire S_commit_ready,S_commit_done,S_scanout_fault,S_frame_start;
    wire [23:0] S_rgb;
    assign O_busy=S_state!=IDLE || S_need;
    assign O_error=I_memory_error || S_scanout_fault ? 4'd1 : S_image_error!=0 ? S_image_error :
        (S_audio_error!=0 || S_cache_error!=0) ? 4'd3 : S_catalog_error!=0 ? 4'd4 : 4'd0;
    wire S_select_audio=S_source_audio_request;
    wire S_command=S_select_audio || S_state==COMMAND;
    assign S_begin_ready=S_begin_audio ? S_source_audio_begin_ready :
        S_state==BEGIN && (S_begin_error!=0 || S_loader_ready);
    assign S_byte_ready=S_byte_context==1 ? S_source_audio_byte_ready : S_image_count<1024;
    lean_media_source u_source (
        .I_clk(I_host_clk),.I_reset(S_hrst),.I_card_ready(I_card_ready),.I_capacity_sectors(I_capacity_sectors),
        .O_catalog_ready(S_catalog),.O_image_count(O_count),.O_audio_found(S_audio_found),.O_catalog_error(S_catalog_error),.O_dbg_type(S_mount_type),
        .I_command_valid(S_command),.O_command_ready(S_command_ready),.I_command_audio(S_select_audio),
        .I_image_pause(S_image_pause),
        .I_image_index(S_job_index),.I_offset(S_select_audio ? S_source_audio_offset : 32'd0),
        .I_length(S_select_audio ? S_source_audio_length : 32'hffffffff),
        .O_begin_valid(S_begin),.I_begin_ready(S_begin_ready),.O_begin_audio(S_begin_audio),.O_file_size(S_file_size),.O_begin_error(S_begin_error),
        .O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),.O_byte_context(S_byte_context),
        .O_byte_offset(S_byte_offset),.O_byte_last(S_byte_last),
        .O_done_valid(S_file_done),.I_done_ready(1'b1),.O_done_context(S_file_context),.O_done_error(S_file_error),
        .O_done_bytes(S_file_bytes),.O_done_eof(S_file_eof),.I_cancel({S_source_audio_cancel,S_loader_cancel}),
        .O_request_valid(O_request_valid),.I_request_ready(I_request_ready),.O_lba(O_lba),.O_count(O_count_sectors),
        .O_context(O_context),.O_priority(O_priority),.O_tag(O_tag),
        .I_sd_byte_valid(I_sd_byte_valid),.O_sd_byte_ready(O_sd_byte_ready),.I_sd_byte_data(I_sd_byte_data),
        .I_sector_last(I_sector_last),.I_request_last(I_request_last),.I_sd_byte_context(I_sd_byte_context),.I_sd_byte_tag(I_sd_byte_tag),
        .I_sd_done_valid(I_sd_done_valid),.O_sd_done_ready(O_sd_done_ready),.I_sd_done_context(I_sd_done_context),
        .I_sd_done_tag(I_sd_done_tag),.I_sd_done_error(I_sd_done_error),
        .O_cancel_valid(O_cancel_valid),.I_cancel_ready(I_cancel_ready),.O_cancel_context(O_cancel_context),.O_cancel_tag(O_cancel_tag),
        .I_cancel_done_valid(I_cancel_done_valid),.O_cancel_done_ready(O_cancel_done_ready),
        .I_cancel_done_context(I_cancel_done_context),.I_cancel_done_tag(I_cancel_done_tag),
        .O_catalog_overflow()
    );
    lean_image_loader u_loader (
        .I_clk(I_host_clk),.I_reset(S_hrst),
        .I_start_valid(S_begin && !S_begin_audio && S_state==BEGIN && S_begin_error==0),.O_start_ready(S_loader_ready),
        .I_file_size(S_file_size),.I_rotation(S_job_rotation),.I_slot(S_job_slot),
        .I_byte_valid(S_image_valid),.O_byte_ready(S_image_byte_ready),.O_stream_pause(S_image_stream_pause),
        .I_byte_data(S_image_head[7:0]),.I_byte_last(S_image_head[8]),
        .I_file_done(S_file_done && S_file_context==0),.I_file_error(S_file_error),
        .I_memory_error(I_memory_error || S_scanout_fault),.I_writes_idle(S_all_writes_idle),
        .O_cancel(S_loader_cancel),.O_write_valid(S_loader_write),.I_write_ready(S_loader_write_ready),
        .O_write_address(S_loader_write_address),.O_write_data(S_loader_write_data),
        .O_done_valid(S_loader_done),.I_done_ready(S_state==LOAD),.O_error(S_loader_error),
        .O_pixels()
    );
    lean_scanout u_scanout (
        .I_host_clk(I_host_clk),.I_video_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_commit_valid(S_state==COMMIT),.O_commit_ready(S_commit_ready),.I_commit_slot(S_job_slot),.O_commit_done(S_commit_done),
        .O_read_valid(S_scan_read),.I_read_ready(S_scan_read_ready),.O_read_address(S_scan_read_address),.O_read_tag(S_scan_read_tag),
        .I_result_valid(I_result_valid && (!AUDIO_CACHE || !I_result_tag[31])),.O_result_ready(S_scan_result_ready),.I_result_data(I_result_data),.I_result_tag(I_result_tag),
        .I_result_error(I_result_error),.O_de(O_de),.O_valid(O_valid),.O_x(O_x),.O_y(O_y),.O_rgb(S_rgb),
        .O_frame_start(S_frame_start),.O_fault(S_scanout_fault),
        .O_underflow_lines()
    );
    lean_player_ctrl #(.CLOCK_HZ(HOST_CLOCK_HZ)) u_control (
        .I_clk(I_host_clk),.I_reset(S_hrst),.I_key_release(I_key_release),
        .I_rx_valid(I_rx_valid),.I_rx_error(I_rx_error),.I_rx_data(I_rx_data),
        .O_tx_valid(O_tx_valid),.I_tx_ready(I_tx_ready),.O_tx_data(O_tx_data),
        .I_active(O_active),.I_busy(O_busy),.I_changed(S_changed),.I_current(O_current),.I_count(O_count),.I_error(O_error),
        .O_next(S_next),.O_prev(S_prev),.O_reload(S_reload),.O_auto(S_auto),.O_mute(S_mute),
        .O_rotation(S_rotation),.O_volume(S_volume),.O_interval(S_interval),
        .O_dropped()
    );
    wire [28:0] S_status={S_mount_type,O_current,O_count,S_auto,S_active_rotation,S_volume,S_mute,O_busy,O_error};
    reg [28:0] S_sent,S_video_status,S_pending_status;
    wire S_status_ready,S_status_valid;
    wire [28:0] S_status_data;
    wire S_status_write=S_status!=S_sent;
    async_fifo #(.DATA_BITS(29),.ADDR_BITS(2)) u_status (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_status_write),.O_write_ready(S_status_ready),.I_write_data(S_status),
        .O_read_valid(S_status_valid),.I_read_ready(1'b1),.O_read_data(S_status_data),
        .O_write_full(), .O_write_level(), .O_read_empty(), .O_read_level()
    );
    always @(posedge I_host_clk or posedge S_hrst) begin
        if(S_hrst) S_sent<=29'h1fffffff;
        else if(S_status_write && S_status_ready) S_sent<=S_status;
    end
    always @(posedge I_video_clk or posedge S_vrst) begin
        if(S_vrst) begin S_video_status<=0; S_pending_status<=0; end
        else begin
            if(S_status_valid) S_pending_status<=S_status_data;
            if(S_frame_start) S_video_status<=S_pending_status;
        end
    end
    lean_status_osd u_status_osd (
        .I_de(O_de),.I_valid(O_valid),.I_x(O_x),.I_y(O_y),.I_rgb(S_rgb),
        .I_current(S_video_status[20:17]),.I_count(S_video_status[16:12]),.I_auto(S_video_status[11]),
        .I_dbg_type(S_video_status[28:21]),.I_rotation(S_video_status[10:9]),.I_volume(S_video_status[8:6]),.I_mute(S_video_status[5]),
        .I_busy(S_video_status[4]),.I_error(S_video_status[3:0]),.O_rgb(O_rgb)
    );
    lean_audio u_audio (
        .I_host_clk(I_host_clk),.I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset || (AUDIO_CACHE && !S_cache_ready)),
        .I_catalog_ready(S_catalog && (!AUDIO_CACHE || S_cache_ready)),.I_audio_found(S_audio_found),
        .O_command_valid(S_audio_request),.I_command_ready(S_audio_command_ready),.O_offset(S_audio_offset),.O_length(S_audio_length),
        .I_begin_valid(S_audio_begin_valid),.O_begin_ready(S_audio_begin_ready),.I_file_size(S_audio_file_size),.I_begin_error(S_audio_begin_error),
        .I_byte_valid(S_audio_byte_valid),.O_byte_ready(S_audio_byte_ready),.I_byte_data(S_audio_byte),.I_byte_offset(S_audio_byte_offset),
        .I_file_done(S_audio_file_done),.I_file_error(S_audio_file_error),.I_file_bytes(S_audio_file_bytes),.I_file_eof(S_audio_file_eof),
        .O_cancel(S_audio_cancel),.O_reserve_storage(S_audio_reserve),.O_error(S_audio_error),
        .I_mute(S_pending_status[5]),.I_volume(S_pending_status[8:6]),
        .O_sample_valid(O_sample_valid),.O_left(O_audio_left),.O_right(O_audio_right),
        .O_acr_valid(O_acr_valid),.O_acr_n(O_acr_n),.O_acr_cts(O_acr_cts),
        .O_underflows()
    );
    generate if(AUDIO_CACHE) begin: g_audio_cache
        lean_audio_cache u_cache (
            .I_clk(I_host_clk),.I_reset(S_hrst),.I_catalog_ready(S_catalog),.I_audio_found(S_audio_found),
            .I_enable(O_active && S_media_seen && !S_need && S_state==IDLE),
            .I_memory_error(I_memory_error || S_scanout_fault),.I_writes_idle(S_all_writes_idle),
            .O_ready(S_cache_ready),.O_loading(S_cache_loading),.O_error(S_cache_error),
            .O_source_command_valid(S_source_audio_request),.I_source_command_ready(S_command_ready && S_select_audio),
            .O_source_offset(S_source_audio_offset),.O_source_length(S_source_audio_length),
            .I_source_begin_valid(S_begin && S_begin_audio),.O_source_begin_ready(S_source_audio_begin_ready),
            .I_source_file_size(S_file_size),.I_source_begin_error(S_begin_error),
            .I_source_byte_valid(S_byte_valid && S_byte_context==1),.O_source_byte_ready(S_source_audio_byte_ready),
            .I_source_byte_data(S_byte),.I_source_byte_offset(S_byte_offset),
            .I_source_file_done(S_file_done && S_file_context==1),.I_source_file_error(S_file_error),
            .I_source_file_bytes(S_file_bytes),.I_source_file_eof(S_file_eof),.O_source_cancel(S_source_audio_cancel),
            .I_command_valid(S_audio_request),.O_command_ready(S_audio_command_ready),.I_offset(S_audio_offset),.I_length(S_audio_length),
            .O_begin_valid(S_audio_begin_valid),.I_begin_ready(S_audio_begin_ready),.O_file_size(S_audio_file_size),.O_begin_error(S_audio_begin_error),
            .O_byte_valid(S_audio_byte_valid),.I_byte_ready(S_audio_byte_ready),.O_byte_data(S_audio_byte),.O_byte_offset(S_audio_byte_offset),
            .O_file_done(S_audio_file_done),.O_file_error(S_audio_file_error),.O_file_bytes(S_audio_file_bytes),.O_file_eof(S_audio_file_eof),.I_cancel(S_audio_cancel),
            .O_write_valid(S_cache_write),.I_write_ready(S_cache_write_ready),.O_write_address(S_cache_write_address),.O_write_data(S_cache_write_data),
            .O_read_valid(S_cache_read),.I_read_ready(S_cache_read_ready),.O_read_address(S_cache_read_address),
            .I_result_valid(I_result_valid && I_result_tag[31]),.O_result_ready(S_cache_result_ready),.I_result_data(I_result_data),.I_result_error(I_result_error)
        );
        // Register each arbitrated command. A blocked request never changes
        // owner/address, and video reads retain priority over cache accesses.
        reg S_rvalid;
        reg [20:0] S_raddress;
        reg [31:0] S_rtag;
        reg S_wvalid;
        reg [20:0] S_waddress;
        reg [31:0] S_wdata;
        wire S_read_room=!S_rvalid || I_read_ready;
        wire S_write_room=!S_wvalid || I_write_ready;
        assign S_scan_read_ready=!S_hrst && S_read_room;
        assign S_cache_read_ready=S_scan_read_ready && !S_scan_read;
        assign S_cache_write_ready=!S_hrst && S_write_room;
        assign S_loader_write_ready=S_cache_write_ready && !S_cache_write;
        assign O_read_valid=!S_hrst && S_rvalid;
        assign O_read_address=S_raddress;
        assign O_read_tag=S_rtag;
        assign O_write_valid=!S_hrst && S_wvalid;
        assign O_write_address=S_waddress;
        assign O_write_data=S_wdata;
        assign S_all_writes_idle=I_writes_idle && !S_wvalid;
        assign O_result_ready=I_result_tag[31] ? S_cache_result_ready : S_scan_result_ready;
        always @(posedge I_host_clk or posedge S_hrst) begin
            if(S_hrst) begin S_rvalid<=0; S_raddress<=0; S_rtag<=0; S_wvalid<=0; S_waddress<=0; S_wdata<=0; end
            else begin
                if(S_read_room) begin
                    S_rvalid<=S_scan_read || S_cache_read;
                    S_raddress<=S_scan_read ? S_scan_read_address : S_cache_read_address;
                    S_rtag<=S_scan_read ? S_scan_read_tag : 32'h80000000;
                end
                if(S_write_room) begin
                    S_wvalid<=S_cache_write || S_loader_write;
                    S_waddress<=S_cache_write ? S_cache_write_address : S_loader_write_address;
                    S_wdata<=S_cache_write ? S_cache_write_data : S_loader_write_data;
                end
            end
        end
    end else begin: g_stream_audio
        assign S_cache_ready=1'b0; assign S_cache_loading=1'b0; assign S_cache_error=4'd0;
        assign S_source_audio_request=S_audio_request;
        assign S_audio_command_ready=S_command_ready && S_select_audio;
        assign S_source_audio_begin_ready=S_audio_begin_ready;
        assign S_source_audio_byte_ready=S_audio_byte_ready;
        assign S_source_audio_cancel=S_audio_cancel;
        assign S_source_audio_offset=S_audio_offset; assign S_source_audio_length=S_audio_length;
        assign S_audio_begin_valid=S_begin && S_begin_audio;
        assign S_audio_file_size=S_file_size; assign S_audio_begin_error=S_begin_error;
        assign S_audio_byte_valid=S_byte_valid && S_byte_context==1;
        assign S_audio_byte=S_byte; assign S_audio_byte_offset=S_byte_offset;
        assign S_audio_file_done=S_file_done && S_file_context==1;
        assign S_audio_file_error=S_file_error; assign S_audio_file_bytes=S_file_bytes; assign S_audio_file_eof=S_file_eof;
        assign O_read_valid=S_scan_read; assign S_scan_read_ready=I_read_ready;
        assign O_read_address=S_scan_read_address; assign O_read_tag=S_scan_read_tag;
        assign O_result_ready=S_scan_result_ready;
        assign O_write_valid=S_loader_write; assign S_loader_write_ready=I_write_ready;
        assign O_write_address=S_loader_write_address; assign O_write_data=S_loader_write_data;
        assign S_all_writes_idle=I_writes_idle;
    end endgenerate
    always @(posedge I_host_clk or posedge S_hrst) begin
        if(S_hrst) begin
            S_state<=IDLE; S_media_seen<=0; S_need<=0; S_target<=0; S_job_index<=0;
            S_active_slot<=0; S_job_slot<=0; S_job_rotation<=0; S_active_rotation<=0; S_image_error<=0; S_failures<=0;
            O_active<=0; O_current<=0; S_changed<=0;
        end else begin
            S_changed<=0;
            if(!S_catalog) begin S_media_seen<=0; S_need<=0; end
            else if(!S_media_seen && S_state==IDLE) begin
                S_media_seen<=1; S_target<=0; S_need<=1; S_failures<=0;
            end
            case(S_state)
                IDLE:if(S_catalog && S_need && I_memory_ready && !I_memory_error && !S_scanout_fault) begin
                    S_job_index<=S_target; S_job_rotation<=S_rotation;
                    S_job_slot<=O_active ? !S_active_slot : 1'b0;
                    S_need<=0; S_state<=COMMAND;
                end
                COMMAND:if(!S_catalog) S_state<=FAILED;
                    else if(S_command_ready && !S_select_audio) S_state<=BEGIN;
                BEGIN:if(S_begin && !S_begin_audio && S_begin_ready) begin
                    if(S_begin_error!=0) begin S_image_error<=2; S_state<=FAILED; end
                    else S_state<=LOAD;
                end
                LOAD:if(S_loader_done) begin
                    if(S_loader_error!=0) begin S_image_error<=2; S_state<=FAILED; end
                    else S_state<=COMMIT;
                end
                COMMIT:if(S_commit_ready) S_state<=ACK;
                ACK:if(S_commit_done) begin
                    O_current<=S_job_index; S_active_slot<=S_job_slot; O_active<=1;
                    S_active_rotation<=S_job_rotation;
                    S_changed<=1; S_failures<=0; S_image_error<=0; S_state<=IDLE;
                end
                FAILED:begin
                    if(S_catalog && !S_need && S_failures+5'd1<O_count) begin
                        S_target<=({1'b0,S_job_index}+5'd1>=O_count) ? 4'd0 : S_job_index+1'b1;
                        S_need<=1; S_failures<=S_failures+1'b1;
                    end
                    S_state<=IDLE;
                end
                default:S_state<=IDLE;
            endcase
            // Latest user target survives an in-progress load/commit. No active
            // slot changes until the ordered video-boundary ACK has returned.
            if(S_catalog && (S_next || S_prev || S_reload)) begin
                S_need<=1; S_failures<=0;
                if(S_next) S_target<=({1'b0,S_target}+5'd1>=O_count) ? 4'd0 : S_target+1'b1;
                else if(S_prev) S_target<=S_target==0 ? O_count[3:0]-1'b1 : S_target-1'b1;
            end
        end
    end
endmodule



