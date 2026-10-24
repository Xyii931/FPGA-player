// Real BMP file -> geometry/scaler/rotate -> whole-frame CLEAR_REGION writer.
// No filesystem, slot manager, physical memory, path RAM or pixel RAM is duplicated.
module bmp_frame_loader #(
    parameter integer PENDING_BITS=3,
    parameter integer MEM_TAG_BITS=32
) (
    input wire I_clk,
    input wire I_reset,
    input wire I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,
    output wire O_lease_request,
    output wire O_lease_active,
    input wire I_lease_grant,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire [31:0] I_asset,
    input wire [2:0] I_slot,
    input wire [2:0] I_layout,
    input wire I_compose,
    input wire [3:0] I_parts,
    output wire O_part_needed,
    output wire [3:0] O_part_index,
    input wire I_part_valid,
    output wire O_part_ready,
    input wire [6:0] I_part_path_length,
    input wire [1:0] I_rotation,
    input wire I_abort,
    output wire O_slot_cmd_valid,
    input wire I_slot_cmd_ready,
    output wire [2:0] O_slot_cmd_op,
    output wire [2:0] O_slot_cmd_slot,
    output wire [1:0] O_slot_cmd_owner,
    output wire [31:0] O_slot_cmd_token,
    output wire [31:0] O_slot_cmd_generation,
    output wire [31:0] O_slot_cmd_asset,
    output wire [2:0] O_slot_cmd_layout,
    output wire [1:0] O_slot_cmd_rotation,
    output wire O_slot_cmd_resident,
    output wire O_slot_cmd_success,
    output wire O_producer_retired,
    output wire O_memory_retired,
    input wire I_slot_result_valid,
    output wire O_slot_result_ready,
    input wire [3:0] I_slot_result_error,
    input wire [2:0] I_slot_result_op,
    input wire [2:0] I_slot_result_slot,
    input wire [1:0] I_slot_result_owner,
    input wire [31:0] I_slot_result_token,
    input wire [31:0] I_slot_result_generation,
    output wire O_busy,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [3:0] O_error,
    output wire [1:0] O_context,
    output wire [15:0] O_tag,
    output wire [31:0] O_generation,
    output wire [31:0] O_lease_token,
    output wire [2:0] O_slot,
    output wire O_published,
    output wire O_slot_owned,
    output wire O_file_started,
    output wire O_transform_started,
    output wire O_writer_started,
    output wire [3:0] O_file_source_error,
    output wire [3:0] O_parser_error,
    output wire [3:0] O_storage_error,
    output wire [3:0] O_transform_error,
    output wire [3:0] O_writer_error,
    output wire [3:0] O_memory_error,
    output wire [7:0] O_file_error,
    output wire [2:0] O_path_warning,
    output wire [31:0] O_file_size,
    output wire [31:0] O_accepted_writes,
    output wire [31:0] O_retired_writes,
    output wire [31:0] O_pixels,
    output wire O_response_discarded,
    input wire [31:0] I_sector_budget,
    input wire [6:0] I_path_length,
    input wire I_path_valid,
    output wire O_path_ready,
    input wire [7:0] I_path_data,
    input wire I_path_last,
    output wire O_fs_open_valid,
    input wire I_fs_open_ready,
    output wire [1:0] O_fs_open_context,
    output wire [15:0] O_fs_open_tag,
    output wire [6:0] O_fs_path_length,
    output wire [31:0] O_fs_sector_budget,
    output wire O_fs_path_valid,
    input wire I_fs_path_ready,
    output wire [7:0] O_fs_path_data,
    output wire O_fs_path_last,
    output wire O_fs_open_cancel,
    input wire I_fs_open_result_valid,
    output wire O_fs_open_result_ready,
    input wire [1:0] I_fs_open_context,
    input wire [15:0] I_fs_open_tag,
    input wire [31:0] I_fs_open_generation,
    input wire [31:0] I_fs_open_size,
    input wire [7:0] I_fs_open_error,
    input wire [3:0] I_fs_open_storage_error,
    input wire [2:0] I_fs_open_warning,
    output wire O_fs_read_valid,
    input wire I_fs_read_ready,
    output wire [1:0] O_fs_read_context,
    output wire [1:0] O_fs_read_priority,
    output wire [31:0] O_fs_offset,
    output wire [31:0] O_fs_length,
    output wire [15:0] O_fs_epoch,
    input wire I_fs_byte_valid,
    output wire O_fs_byte_ready,
    input wire [7:0] I_fs_byte_data,
    input wire [1:0] I_fs_byte_context,
    input wire [15:0] I_fs_byte_epoch,
    input wire [31:0] I_fs_byte_generation,
    input wire [31:0] I_fs_byte_offset,
    input wire I_fs_byte_last,
    input wire I_fs_done_valid,
    output wire O_fs_done_ready,
    input wire [1:0] I_fs_done_context,
    input wire [15:0] I_fs_done_epoch,
    input wire [31:0] I_fs_done_generation,
    input wire [31:0] I_fs_done_bytes,
    input wire I_fs_done_eof,
    input wire [7:0] I_fs_done_error,
    input wire [3:0] I_fs_done_storage_error,
    output wire O_fs_cancel_valid,
    input wire I_fs_cancel_ready,
    output wire [1:0] O_fs_cancel_context,
    output wire [15:0] O_fs_cancel_epoch,
    input wire I_fs_cancel_done_valid,
    output wire O_fs_cancel_done_ready,
    input wire [1:0] I_fs_cancel_done_context,
    input wire [15:0] I_fs_cancel_done_epoch,
    input wire [31:0] I_fs_cancel_done_generation,
    output wire O_fs_close_valid,
    input wire I_fs_close_ready,
    output wire [1:0] O_fs_close_context,
    output wire O_mem_valid,
    input wire I_mem_ready,
    output wire O_mem_wr,
    output wire [20:0] O_mem_addr,
    output wire [31:0] O_mem_data,
    output wire [31:0] O_mem_tag,
    output wire [3:0] O_mem_mask,
    output wire [31:0] O_mem_lease_token,
    output wire [31:0] O_mem_generation,
    input wire I_mem_done_valid,
    output wire O_mem_done_ready,
    input wire [31:0] I_mem_done_tag,
    input wire [31:0] I_mem_done_lease_token,
    input wire [31:0] I_mem_done_generation,
    input wire [3:0] I_mem_done_error,
    input wire [15:0] I_rect_x,
    input wire [15:0] I_rect_y,
    input wire [15:0] I_rect_width,
    input wire [15:0] I_rect_height,
    input wire I_bilinear,
    input wire [31:0] I_clear_rgba
);
    reg S_compose;
    reg [3:0] S_parts,S_part;
    reg [2:0] S_layout;
    wire [3:0] S_geometry_part=I_start_valid && O_start_ready ? 4'd0 : S_part+1'b1;
    wire [2:0] S_geometry_layout=I_start_valid && O_start_ready ? I_layout : S_layout;
    wire [15:0] S_layout_x,S_layout_y,S_layout_width,S_layout_height;
    layout_geometry u_layout (.I_layout(S_geometry_layout),.I_part(S_geometry_part),
        .O_x(S_layout_x),.O_y(S_layout_y),.O_width(S_layout_width),.O_height(S_layout_height));
    assign O_part_index=S_part+1'b1;
    wire S_part_config=I_part_path_length!=0 && I_part_path_length<=64;
    wire S_ctrl_part_needed,S_ctrl_part_ready;
    assign O_part_needed=S_ctrl_part_needed;
    assign O_part_ready=S_ctrl_part_ready && S_part_config;
    wire S_parts_ok=I_parts!=0 && I_parts<=9 &&
        ((I_layout==0 && I_parts==1) || ((I_layout==1 || I_layout==2) && I_parts==2) ||
        (I_layout==3 && I_parts==4) || I_layout==4);
    reg [6:0] S_path_length;
    reg [31:0] S_sector_budget;
    reg [15:0] S_rect_x;
    reg [15:0] S_rect_y;
    reg [15:0] S_rect_width;
    reg [15:0] S_rect_height;
    reg [1:0] S_rotation;
    reg S_bilinear;
    reg [31:0] S_clear_rgba;
    wire S_ctrl_file_start_valid;
    wire S_ctrl_file_start_ready;
    wire S_ctrl_file_header_valid;
    wire S_ctrl_file_header_ready;
    wire S_ctrl_transform_start_valid;
    wire S_ctrl_transform_start_ready;
    wire S_ctrl_geometry_valid;
    wire S_ctrl_geometry_ready;
    wire S_ctrl_writer_start_valid;
    wire S_ctrl_writer_start_ready;
    wire S_ctrl_writer_lease_grant;
    wire S_ctrl_file_abort;
    wire S_ctrl_transform_abort;
    wire S_ctrl_writer_abort;
    wire S_ctrl_writer_cancel_source;
    wire S_ctrl_file_done_valid;
    wire S_ctrl_file_done_ready;
    wire [1:0] S_ctrl_file_context;
    wire [15:0] S_ctrl_file_tag;
    wire [31:0] S_ctrl_file_generation;
    wire [31:0] S_ctrl_file_size;
    wire [3:0] S_ctrl_file_error;
    wire [3:0] S_ctrl_parser_error;
    wire [3:0] S_ctrl_storage_error;
    wire [7:0] S_ctrl_fs_error;
    wire [2:0] S_ctrl_path_warning;
    wire S_ctrl_transform_done_valid;
    wire S_ctrl_transform_done_ready;
    wire [15:0] S_ctrl_transform_tag;
    wire [31:0] S_ctrl_transform_generation;
    wire [3:0] S_ctrl_transform_error;
    wire S_ctrl_writer_done_valid;
    wire S_ctrl_writer_done_ready;
    wire [15:0] S_ctrl_writer_tag;
    wire [2:0] S_ctrl_writer_slot;
    wire [31:0] S_ctrl_writer_generation;
    wire [31:0] S_ctrl_writer_token;
    wire [3:0] S_ctrl_writer_error;
    wire [3:0] S_ctrl_memory_error;
    wire [31:0] S_ctrl_accepted_writes;
    wire [31:0] S_ctrl_retired_writes;
    wire [31:0] S_ctrl_pixels;
    wire S_ctrl_source_valid;
    wire S_ctrl_source_ready;
    wire [3:0] S_ctrl_source_error;
    wire S_file_lease_request;
    wire S_file_lease_active;
    wire S_file_busy;
    wire S_file_parser_started;
    wire [15:0] S_file_width;
    wire [15:0] S_file_height;
    wire S_file_bottom_up;
    wire [5:0] S_file_bpp;
    wire [31:0] S_file_pixel_offset;
    wire [31:0] S_file_row_bytes;
    wire S_file_pixel_valid;
    wire S_file_pixel_ready;
    wire [31:0] S_file_rgba;
    wire [15:0] S_file_x;
    wire [15:0] S_file_y;
    wire S_file_pixel_last;
    wire [15:0] S_transform_pre_width;
    wire [15:0] S_transform_pre_height;
    wire [15:0] S_transform_image_x;
    wire [15:0] S_transform_image_y;
    wire [15:0] S_transform_image_width;
    wire [15:0] S_transform_image_height;
    wire S_transform_pixel_valid;
    wire S_transform_pixel_ready;
    wire [31:0] S_transform_rgba;
    wire [15:0] S_transform_x;
    wire [15:0] S_transform_y;
    wire S_transform_pixel_last;
    wire S_transform_busy;
    wire S_writer_busy;
    wire [3:0] S_writer_source_error;
    wire S_writer_memory_retired;
    wire S_writer_producer_retired;
    wire S_writer_response_discarded;
    wire S_writer_source_discarded;
    wire S_writer_tag_exhausted;
    wire S_config_valid=(!I_compose || S_parts_ok) && I_path_length!=0 && I_path_length<=64 && I_sector_budget!=0 &&
        I_rect_width!=0 && I_rect_height!=0 &&
        ({1'b0,I_rect_x}+{1'b0,I_rect_width}<=17'd640) &&
        ({1'b0,I_rect_y}+{1'b0,I_rect_height}<=17'd480);
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_compose<=0; S_parts<=1; S_part<=0; S_layout<=0;
            S_path_length<=0;
            S_sector_budget<=0;
            S_rect_x<=0;
            S_rect_y<=0;
            S_rect_width<=0;
            S_rect_height<=0;
            S_rotation<=0;
            S_bilinear<=0;
            S_clear_rgba<=0;
        end else if (I_start_valid && O_start_ready) begin
            S_compose<=I_compose; S_parts<=I_compose ? I_parts : 4'd1; S_part<=0; S_layout<=I_layout;
            S_path_length<=I_path_length;
            S_sector_budget<=I_sector_budget;
            S_rect_x<=I_compose ? S_layout_x : I_rect_x;
            S_rect_y<=I_compose ? S_layout_y : I_rect_y;
            S_rect_width<=I_compose ? S_layout_width : I_rect_width;
            S_rect_height<=I_compose ? S_layout_height : I_rect_height;
            S_rotation<=I_rotation;
            S_bilinear<=I_bilinear;
            S_clear_rgba<=I_clear_rgba;
        end else if(I_part_valid && O_part_ready) begin
            S_part<=S_part+1'b1; S_path_length<=I_part_path_length;
            S_rect_x<=S_layout_x; S_rect_y<=S_layout_y;
            S_rect_width<=S_layout_width; S_rect_height<=S_layout_height;
        end
    end
    bmp_frame_load_ctrl u_ctrl (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_start_valid(I_start_valid),
        .O_start_ready(O_start_ready),
        .O_lease_request(O_lease_request),
        .O_lease_active(O_lease_active),
        .I_lease_grant(I_lease_grant),
        .I_config_valid(S_config_valid),
        .I_context(I_context),
        .I_tag(I_tag),
        .I_generation(I_generation),
        .I_asset(I_asset),
        .I_slot(I_slot),
        .I_layout(I_layout),
        .I_rotation(I_rotation),
        .I_abort(I_abort || (I_part_valid && !S_part_config)),
        .I_more_parts(S_compose && S_part+1'b1<S_parts),
        .I_part_valid(I_part_valid && S_part_config),
        .O_part_needed(S_ctrl_part_needed),
        .O_part_ready(S_ctrl_part_ready),
        .O_file_start_valid(S_ctrl_file_start_valid),
        .I_file_start_ready(S_ctrl_file_start_ready),
        .I_file_header_valid(S_ctrl_file_header_valid),
        .O_file_header_ready(S_ctrl_file_header_ready),
        .O_transform_start_valid(S_ctrl_transform_start_valid),
        .I_transform_start_ready(S_ctrl_transform_start_ready),
        .I_geometry_valid(S_ctrl_geometry_valid),
        .O_geometry_ready(S_ctrl_geometry_ready),
        .O_writer_start_valid(S_ctrl_writer_start_valid),
        .I_writer_start_ready(S_ctrl_writer_start_ready),
        .O_writer_lease_grant(S_ctrl_writer_lease_grant),
        .O_file_abort(S_ctrl_file_abort),
        .O_transform_abort(S_ctrl_transform_abort),
        .O_writer_abort(S_ctrl_writer_abort),
        .I_writer_cancel_source(S_ctrl_writer_cancel_source),
        .I_file_done_valid(S_ctrl_file_done_valid),
        .O_file_done_ready(S_ctrl_file_done_ready),
        .I_file_context(S_ctrl_file_context),
        .I_file_tag(S_ctrl_file_tag),
        .I_file_generation(S_ctrl_file_generation),
        .I_file_size(S_ctrl_file_size),
        .I_file_error(S_ctrl_file_error),
        .I_parser_error(S_ctrl_parser_error),
        .I_storage_error(S_ctrl_storage_error),
        .I_fs_error(S_ctrl_fs_error),
        .I_path_warning(S_ctrl_path_warning),
        .I_transform_done_valid(S_ctrl_transform_done_valid),
        .O_transform_done_ready(S_ctrl_transform_done_ready),
        .I_transform_tag(S_ctrl_transform_tag),
        .I_transform_generation(S_ctrl_transform_generation),
        .I_transform_error(S_ctrl_transform_error),
        .I_writer_done_valid(S_ctrl_writer_done_valid),
        .O_writer_done_ready(S_ctrl_writer_done_ready),
        .I_writer_tag(S_ctrl_writer_tag),
        .I_writer_slot(S_ctrl_writer_slot),
        .I_writer_generation(S_ctrl_writer_generation),
        .I_writer_token(S_ctrl_writer_token),
        .I_writer_error(S_ctrl_writer_error),
        .I_memory_error(S_ctrl_memory_error),
        .I_accepted_writes(S_ctrl_accepted_writes),
        .I_retired_writes(S_ctrl_retired_writes),
        .I_pixels(S_ctrl_pixels),
        .O_source_valid(S_ctrl_source_valid),
        .I_source_ready(S_ctrl_source_ready),
        .O_source_error(S_ctrl_source_error),
        .O_slot_cmd_valid(O_slot_cmd_valid),
        .I_slot_cmd_ready(I_slot_cmd_ready),
        .O_slot_cmd_op(O_slot_cmd_op),
        .O_slot_cmd_slot(O_slot_cmd_slot),
        .O_slot_cmd_owner(O_slot_cmd_owner),
        .O_slot_cmd_token(O_slot_cmd_token),
        .O_slot_cmd_generation(O_slot_cmd_generation),
        .O_slot_cmd_asset(O_slot_cmd_asset),
        .O_slot_cmd_layout(O_slot_cmd_layout),
        .O_slot_cmd_rotation(O_slot_cmd_rotation),
        .O_slot_cmd_resident(O_slot_cmd_resident),
        .O_slot_cmd_success(O_slot_cmd_success),
        .O_producer_retired(O_producer_retired),
        .O_memory_retired(O_memory_retired),
        .I_slot_result_valid(I_slot_result_valid),
        .O_slot_result_ready(O_slot_result_ready),
        .I_slot_result_error(I_slot_result_error),
        .I_slot_result_op(I_slot_result_op),
        .I_slot_result_slot(I_slot_result_slot),
        .I_slot_result_owner(I_slot_result_owner),
        .I_slot_result_token(I_slot_result_token),
        .I_slot_result_generation(I_slot_result_generation),
        .O_busy(O_busy),
        .O_done_valid(O_done_valid),
        .I_done_ready(I_done_ready),
        .O_error(O_error),
        .O_context(O_context),
        .O_tag(O_tag),
        .O_generation(O_generation),
        .O_lease_token(O_lease_token),
        .O_slot(O_slot),
        .O_published(O_published),
        .O_slot_owned(O_slot_owned),
        .O_file_started(O_file_started),
        .O_transform_started(O_transform_started),
        .O_writer_started(O_writer_started),
        .O_file_source_error(O_file_source_error),
        .O_parser_error(O_parser_error),
        .O_storage_error(O_storage_error),
        .O_transform_error(O_transform_error),
        .O_writer_error(O_writer_error),
        .O_memory_error(O_memory_error),
        .O_file_error(O_file_error),
        .O_path_warning(O_path_warning),
        .O_file_size(O_file_size),
        .O_accepted_writes(O_accepted_writes),
        .O_retired_writes(O_retired_writes),
        .O_pixels(O_pixels),
        .O_response_discarded(O_response_discarded)
    );
    bmp_file_source u_file (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_start_valid(S_ctrl_file_start_valid),
        .O_start_ready(S_ctrl_file_start_ready),
        .O_lease_request(S_file_lease_request),
        .I_lease_grant(O_lease_active),
        .I_context(O_context),
        .I_tag(O_tag),
        .I_generation(O_generation),
        .I_sector_budget(S_sector_budget),
        .I_path_length(S_path_length),
        .I_path_valid(I_path_valid),
        .O_path_ready(O_path_ready),
        .I_path_data(I_path_data),
        .I_path_last(I_path_last),
        .I_abort(S_ctrl_file_abort),
        .O_lease_active(S_file_lease_active),
        .O_busy(S_file_busy),
        .O_done_valid(S_ctrl_file_done_valid),
        .I_done_ready(S_ctrl_file_done_ready),
        .O_error(S_ctrl_file_error),
        .O_parser_error(S_ctrl_parser_error),
        .O_file_error(S_ctrl_fs_error),
        .O_storage_error(S_ctrl_storage_error),
        .O_path_warning(S_ctrl_path_warning),
        .O_context(S_ctrl_file_context),
        .O_tag(S_ctrl_file_tag),
        .O_generation(S_ctrl_file_generation),
        .O_file_size(S_ctrl_file_size),
        .O_parser_started(S_file_parser_started),
        .O_header_valid(S_ctrl_file_header_valid),
        .I_header_ready(S_ctrl_file_header_ready),
        .O_width(S_file_width),
        .O_height(S_file_height),
        .O_bottom_up(S_file_bottom_up),
        .O_bpp(S_file_bpp),
        .O_pixel_offset(S_file_pixel_offset),
        .O_row_bytes(S_file_row_bytes),
        .O_pixel_valid(S_file_pixel_valid),
        .I_pixel_ready(S_file_pixel_ready),
        .O_rgba(S_file_rgba),
        .O_x(S_file_x),
        .O_y(S_file_y),
        .O_pixel_last(S_file_pixel_last),
        .O_fs_open_valid(O_fs_open_valid),
        .I_fs_open_ready(I_fs_open_ready),
        .O_fs_open_context(O_fs_open_context),
        .O_fs_open_tag(O_fs_open_tag),
        .O_fs_path_length(O_fs_path_length),
        .O_fs_sector_budget(O_fs_sector_budget),
        .O_fs_path_valid(O_fs_path_valid),
        .I_fs_path_ready(I_fs_path_ready),
        .O_fs_path_data(O_fs_path_data),
        .O_fs_path_last(O_fs_path_last),
        .O_fs_open_cancel(O_fs_open_cancel),
        .I_fs_open_result_valid(I_fs_open_result_valid),
        .O_fs_open_result_ready(O_fs_open_result_ready),
        .I_fs_open_context(I_fs_open_context),
        .I_fs_open_tag(I_fs_open_tag),
        .I_fs_open_generation(I_fs_open_generation),
        .I_fs_open_size(I_fs_open_size),
        .I_fs_open_error(I_fs_open_error),
        .I_fs_open_storage_error(I_fs_open_storage_error),
        .I_fs_open_warning(I_fs_open_warning),
        .O_fs_read_valid(O_fs_read_valid),
        .I_fs_read_ready(I_fs_read_ready),
        .O_fs_read_context(O_fs_read_context),
        .O_fs_read_priority(O_fs_read_priority),
        .O_fs_offset(O_fs_offset),
        .O_fs_length(O_fs_length),
        .O_fs_epoch(O_fs_epoch),
        .I_fs_byte_valid(I_fs_byte_valid),
        .O_fs_byte_ready(O_fs_byte_ready),
        .I_fs_byte_data(I_fs_byte_data),
        .I_fs_byte_context(I_fs_byte_context),
        .I_fs_byte_epoch(I_fs_byte_epoch),
        .I_fs_byte_generation(I_fs_byte_generation),
        .I_fs_byte_offset(I_fs_byte_offset),
        .I_fs_byte_last(I_fs_byte_last),
        .I_fs_done_valid(I_fs_done_valid),
        .O_fs_done_ready(O_fs_done_ready),
        .I_fs_done_context(I_fs_done_context),
        .I_fs_done_epoch(I_fs_done_epoch),
        .I_fs_done_generation(I_fs_done_generation),
        .I_fs_done_bytes(I_fs_done_bytes),
        .I_fs_done_eof(I_fs_done_eof),
        .I_fs_done_error(I_fs_done_error),
        .I_fs_done_storage_error(I_fs_done_storage_error),
        .O_fs_cancel_valid(O_fs_cancel_valid),
        .I_fs_cancel_ready(I_fs_cancel_ready),
        .O_fs_cancel_context(O_fs_cancel_context),
        .O_fs_cancel_epoch(O_fs_cancel_epoch),
        .I_fs_cancel_done_valid(I_fs_cancel_done_valid),
        .O_fs_cancel_done_ready(O_fs_cancel_done_ready),
        .I_fs_cancel_done_context(I_fs_cancel_done_context),
        .I_fs_cancel_done_epoch(I_fs_cancel_done_epoch),
        .I_fs_cancel_done_generation(I_fs_cancel_done_generation),
        .O_fs_close_valid(O_fs_close_valid),
        .I_fs_close_ready(I_fs_close_ready),
        .O_fs_close_context(O_fs_close_context)
    );
    image_transform u_transform (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_start_valid(S_ctrl_transform_start_valid),
        .O_start_ready(S_ctrl_transform_start_ready),
        .I_src_width(S_file_width),
        .I_src_height(S_file_height),
        .I_rect_x(S_rect_x),
        .I_rect_y(S_rect_y),
        .I_rect_width(S_rect_width),
        .I_rect_height(S_rect_height),
        .I_rotation(S_rotation),
        .I_bilinear(S_bilinear),
        .I_bottom_up(S_file_bottom_up),
        .I_tag(O_tag),
        .I_generation(O_generation),
        .I_abort(S_ctrl_transform_abort),
        .I_stream_error(1'b0),
        .O_geometry_valid(S_ctrl_geometry_valid),
        .I_geometry_ready(S_ctrl_geometry_ready),
        .O_pre_width(S_transform_pre_width),
        .O_pre_height(S_transform_pre_height),
        .O_image_x(S_transform_image_x),
        .O_image_y(S_transform_image_y),
        .O_image_width(S_transform_image_width),
        .O_image_height(S_transform_image_height),
        .I_pixel_valid(S_file_pixel_valid),
        .O_pixel_ready(S_file_pixel_ready),
        .I_rgba(S_file_rgba),
        .I_x(S_file_x),
        .I_y(S_file_y),
        .I_pixel_last(S_file_pixel_last),
        .O_pixel_valid(S_transform_pixel_valid),
        .I_pixel_ready(S_transform_pixel_ready),
        .O_rgba(S_transform_rgba),
        .O_x(S_transform_x),
        .O_y(S_transform_y),
        .O_pixel_last(S_transform_pixel_last),
        .O_busy(S_transform_busy),
        .O_done_valid(S_ctrl_transform_done_valid),
        .I_done_ready(S_ctrl_transform_done_ready),
        .O_error(S_ctrl_transform_error),
        .O_tag(S_ctrl_transform_tag),
        .O_generation(S_ctrl_transform_generation)
    );
    fb_writer #(.PENDING_BITS(PENDING_BITS),.MEM_TAG_BITS(MEM_TAG_BITS)) u_writer (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_start_valid(S_ctrl_writer_start_valid),
        .O_start_ready(S_ctrl_writer_start_ready),
        .I_lease_grant(S_ctrl_writer_lease_grant),
        .I_op(S_part==0 ? 2'd2 : S_layout==1 ? 2'd3 : 2'd1),
        .I_layout(S_compose ? S_layout : 3'd0),
        .I_clear_x(S_rect_x),.I_clear_y(S_rect_y),
        .I_clear_width(S_rect_width),.I_clear_height(S_rect_height),
        .I_slot(O_slot),
        .I_lease_token(O_lease_token),
        .I_generation(O_generation),
        .I_tag(O_tag),
        .I_resident(1'b0),
        .I_clear_rgba(S_clear_rgba),
        .I_pre_width(S_transform_pre_width),
        .I_pre_height(S_transform_pre_height),
        .I_image_x(S_transform_image_x),
        .I_image_y(S_transform_image_y),
        .I_rotation(S_rotation),
        .I_bottom_up(S_file_bottom_up),
        .I_source_expected(1'b1),
        .I_abort(S_ctrl_writer_abort),
        .I_pixel_valid(S_transform_pixel_valid),
        .O_pixel_ready(S_transform_pixel_ready),
        .I_rgba(S_transform_rgba),
        .I_x(S_transform_x),
        .I_y(S_transform_y),
        .I_pixel_last(S_transform_pixel_last),
        .I_source_valid(S_ctrl_source_valid),
        .O_source_ready(S_ctrl_source_ready),
        .I_source_tag(O_tag),
        .I_source_lease_token(O_lease_token),
        .I_source_generation(O_generation),
        .I_source_error(S_ctrl_source_error),
        .O_cancel_source(S_ctrl_writer_cancel_source),
        .O_mem_valid(O_mem_valid),
        .I_mem_ready(I_mem_ready),
        .O_mem_wr(O_mem_wr),
        .O_mem_addr(O_mem_addr),
        .O_mem_data(O_mem_data),
        .O_mem_tag(O_mem_tag),
        .O_mem_mask(O_mem_mask),
        .O_mem_lease_token(O_mem_lease_token),
        .O_mem_generation(O_mem_generation),
        .I_mem_done_valid(I_mem_done_valid),
        .O_mem_done_ready(O_mem_done_ready),
        .I_mem_done_tag(I_mem_done_tag),
        .I_mem_done_lease_token(I_mem_done_lease_token),
        .I_mem_done_generation(I_mem_done_generation),
        .I_mem_done_error(I_mem_done_error),
        .O_busy(S_writer_busy),
        .O_done_valid(S_ctrl_writer_done_valid),
        .I_done_ready(S_ctrl_writer_done_ready),
        .O_error(S_ctrl_writer_error),
        .O_memory_error(S_ctrl_memory_error),
        .O_source_error(S_writer_source_error),
        .O_tag(S_ctrl_writer_tag),
        .O_slot(S_ctrl_writer_slot),
        .O_lease_token(S_ctrl_writer_token),
        .O_generation(S_ctrl_writer_generation),
        .O_accepted_writes(S_ctrl_accepted_writes),
        .O_retired_writes(S_ctrl_retired_writes),
        .O_pixels(S_ctrl_pixels),
        .O_memory_retired(S_writer_memory_retired),
        .O_producer_retired(S_writer_producer_retired),
        .O_response_discarded(S_writer_response_discarded),
        .O_source_discarded(S_writer_source_discarded),
        .O_tag_exhausted(S_writer_tag_exhausted)
    );
endmodule
