`timescale 1ns/1ps
module tb_bmp_frame_loader;
    reg S_I_compose=0,S_I_part_valid=0;
    reg [3:0] S_I_parts=1;
    reg [6:0] S_I_part_path_length=9;
    wire S_O_part_needed,S_O_part_ready;
    wire [3:0] S_O_part_index;
    reg S_I_clk=0;
    reg S_I_reset=0;
    reg S_I_media_valid=0;
    reg [31:0] S_I_media_generation=0;
    reg S_I_start_valid=0;
    wire S_O_start_ready;
    wire S_O_lease_request;
    wire S_O_lease_active;
    reg S_I_lease_grant=0;
    reg [1:0] S_I_context=0;
    reg [15:0] S_I_tag=0;
    reg [31:0] S_I_generation=0;
    reg [31:0] S_I_asset=0;
    reg [2:0] S_I_slot=0;
    reg [2:0] S_I_layout=0;
    reg [1:0] S_I_rotation=0;
    reg S_I_abort=0;
    wire S_O_slot_cmd_valid;
    wire S_I_slot_cmd_ready;
    wire [2:0] S_O_slot_cmd_op;
    wire [2:0] S_O_slot_cmd_slot;
    wire [1:0] S_O_slot_cmd_owner;
    wire [31:0] S_O_slot_cmd_token;
    wire [31:0] S_O_slot_cmd_generation;
    wire [31:0] S_O_slot_cmd_asset;
    wire [2:0] S_O_slot_cmd_layout;
    wire [1:0] S_O_slot_cmd_rotation;
    wire S_O_slot_cmd_resident;
    wire S_O_slot_cmd_success;
    wire S_O_producer_retired;
    wire S_O_memory_retired;
    wire S_I_slot_result_valid;
    wire S_O_slot_result_ready;
    wire [3:0] S_I_slot_result_error;
    wire [2:0] S_I_slot_result_op;
    wire [2:0] S_I_slot_result_slot;
    wire [1:0] S_I_slot_result_owner;
    wire [31:0] S_I_slot_result_token;
    wire [31:0] S_I_slot_result_generation;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [1:0] S_O_context;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_generation;
    wire [31:0] S_O_lease_token;
    wire [2:0] S_O_slot;
    wire S_O_published;
    wire S_O_slot_owned;
    wire S_O_file_started;
    wire S_O_transform_started;
    wire S_O_writer_started;
    wire [3:0] S_O_file_source_error;
    wire [3:0] S_O_parser_error;
    wire [3:0] S_O_storage_error;
    wire [3:0] S_O_transform_error;
    wire [3:0] S_O_writer_error;
    wire [3:0] S_O_memory_error;
    wire [7:0] S_O_file_error;
    wire [2:0] S_O_path_warning;
    wire [31:0] S_O_file_size;
    wire [31:0] S_O_accepted_writes;
    wire [31:0] S_O_retired_writes;
    wire [31:0] S_O_pixels;
    wire S_O_response_discarded;
    reg [31:0] S_I_sector_budget=0;
    reg [6:0] S_I_path_length=0;
    reg S_I_path_valid=0;
    wire S_O_path_ready;
    reg [7:0] S_I_path_data=0;
    reg S_I_path_last=0;
    wire S_O_fs_open_valid;
    reg S_I_fs_open_ready=0;
    wire [1:0] S_O_fs_open_context;
    wire [15:0] S_O_fs_open_tag;
    wire [6:0] S_O_fs_path_length;
    wire [31:0] S_O_fs_sector_budget;
    wire S_O_fs_path_valid;
    reg S_I_fs_path_ready=0;
    wire [7:0] S_O_fs_path_data;
    wire S_O_fs_path_last;
    wire S_O_fs_open_cancel;
    reg S_I_fs_open_result_valid=0;
    wire S_O_fs_open_result_ready;
    reg [1:0] S_I_fs_open_context=0;
    reg [15:0] S_I_fs_open_tag=0;
    reg [31:0] S_I_fs_open_generation=0;
    reg [31:0] S_I_fs_open_size=0;
    reg [7:0] S_I_fs_open_error=0;
    reg [3:0] S_I_fs_open_storage_error=0;
    reg [2:0] S_I_fs_open_warning=0;
    wire S_O_fs_read_valid;
    reg S_I_fs_read_ready=0;
    wire [1:0] S_O_fs_read_context;
    wire [1:0] S_O_fs_read_priority;
    wire [31:0] S_O_fs_offset;
    wire [31:0] S_O_fs_length;
    wire [15:0] S_O_fs_epoch;
    reg S_I_fs_byte_valid=0;
    wire S_O_fs_byte_ready;
    reg [7:0] S_I_fs_byte_data=0;
    reg [1:0] S_I_fs_byte_context=0;
    reg [15:0] S_I_fs_byte_epoch=0;
    reg [31:0] S_I_fs_byte_generation=0;
    reg [31:0] S_I_fs_byte_offset=0;
    reg S_I_fs_byte_last=0;
    reg S_I_fs_done_valid=0;
    wire S_O_fs_done_ready;
    reg [1:0] S_I_fs_done_context=0;
    reg [15:0] S_I_fs_done_epoch=0;
    reg [31:0] S_I_fs_done_generation=0;
    reg [31:0] S_I_fs_done_bytes=0;
    reg S_I_fs_done_eof=0;
    reg [7:0] S_I_fs_done_error=0;
    reg [3:0] S_I_fs_done_storage_error=0;
    wire S_O_fs_cancel_valid;
    reg S_I_fs_cancel_ready=0;
    wire [1:0] S_O_fs_cancel_context;
    wire [15:0] S_O_fs_cancel_epoch;
    reg S_I_fs_cancel_done_valid=0;
    wire S_O_fs_cancel_done_ready;
    reg [1:0] S_I_fs_cancel_done_context=0;
    reg [15:0] S_I_fs_cancel_done_epoch=0;
    reg [31:0] S_I_fs_cancel_done_generation=0;
    wire S_O_fs_close_valid;
    reg S_I_fs_close_ready=0;
    wire [1:0] S_O_fs_close_context;
    wire S_O_mem_valid;
    wire S_I_mem_ready;
    wire S_O_mem_wr;
    wire [20:0] S_O_mem_addr;
    wire [31:0] S_O_mem_data;
    wire [31:0] S_O_mem_tag;
    wire [3:0] S_O_mem_mask;
    wire [31:0] S_O_mem_lease_token;
    wire [31:0] S_O_mem_generation;
    wire S_I_mem_done_valid;
    wire S_O_mem_done_ready;
    reg [31:0] S_I_mem_done_tag=0;
    reg [31:0] S_I_mem_done_lease_token=0;
    reg [31:0] S_I_mem_done_generation=0;
    reg [3:0] S_I_mem_done_error=0;
    reg [15:0] S_I_rect_x=0;
    reg [15:0] S_I_rect_y=0;
    reg [15:0] S_I_rect_width=0;
    reg [15:0] S_I_rect_height=0;
    reg S_I_bilinear=0;
    reg [31:0] S_I_clear_rgba=0;
    bmp_frame_loader u_dut (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_start_valid(S_I_start_valid),
        .O_start_ready(S_O_start_ready),
        .O_lease_request(S_O_lease_request),
        .O_lease_active(S_O_lease_active),
        .I_lease_grant(S_I_lease_grant),
        .I_context(S_I_context),
        .I_tag(S_I_tag),
        .I_generation(S_I_generation),
        .I_asset(S_I_asset),
        .I_slot(S_I_slot),
        .I_layout(S_I_layout),
        .I_rotation(S_I_rotation),
        .I_abort(S_I_abort),
        .O_slot_cmd_valid(S_O_slot_cmd_valid),
        .I_slot_cmd_ready(S_I_slot_cmd_ready),
        .O_slot_cmd_op(S_O_slot_cmd_op),
        .O_slot_cmd_slot(S_O_slot_cmd_slot),
        .O_slot_cmd_owner(S_O_slot_cmd_owner),
        .O_slot_cmd_token(S_O_slot_cmd_token),
        .O_slot_cmd_generation(S_O_slot_cmd_generation),
        .O_slot_cmd_asset(S_O_slot_cmd_asset),
        .O_slot_cmd_layout(S_O_slot_cmd_layout),
        .O_slot_cmd_rotation(S_O_slot_cmd_rotation),
        .O_slot_cmd_resident(S_O_slot_cmd_resident),
        .O_slot_cmd_success(S_O_slot_cmd_success),
        .O_producer_retired(S_O_producer_retired),
        .O_memory_retired(S_O_memory_retired),
        .I_slot_result_valid(S_I_slot_result_valid),
        .O_slot_result_ready(S_O_slot_result_ready),
        .I_slot_result_error(S_I_slot_result_error),
        .I_slot_result_op(S_I_slot_result_op),
        .I_slot_result_slot(S_I_slot_result_slot),
        .I_slot_result_owner(S_I_slot_result_owner),
        .I_slot_result_token(S_I_slot_result_token),
        .I_slot_result_generation(S_I_slot_result_generation),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_context(S_O_context),
        .O_tag(S_O_tag),
        .O_generation(S_O_generation),
        .O_lease_token(S_O_lease_token),
        .O_slot(S_O_slot),
        .O_published(S_O_published),
        .O_slot_owned(S_O_slot_owned),
        .O_file_started(S_O_file_started),
        .O_transform_started(S_O_transform_started),
        .O_writer_started(S_O_writer_started),
        .O_file_source_error(S_O_file_source_error),
        .O_parser_error(S_O_parser_error),
        .O_storage_error(S_O_storage_error),
        .O_transform_error(S_O_transform_error),
        .O_writer_error(S_O_writer_error),
        .O_memory_error(S_O_memory_error),
        .O_file_error(S_O_file_error),
        .O_path_warning(S_O_path_warning),
        .O_file_size(S_O_file_size),
        .O_accepted_writes(S_O_accepted_writes),
        .O_retired_writes(S_O_retired_writes),
        .O_pixels(S_O_pixels),
        .O_response_discarded(S_O_response_discarded),
        .I_sector_budget(S_I_sector_budget),
        .I_path_length(S_I_path_length),
        .I_path_valid(S_I_path_valid),
        .O_path_ready(S_O_path_ready),
        .I_path_data(S_I_path_data),
        .I_path_last(S_I_path_last),
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
        .O_mem_valid(S_O_mem_valid),
        .I_mem_ready(S_I_mem_ready),
        .O_mem_wr(S_O_mem_wr),
        .O_mem_addr(S_O_mem_addr),
        .O_mem_data(S_O_mem_data),
        .O_mem_tag(S_O_mem_tag),
        .O_mem_mask(S_O_mem_mask),
        .O_mem_lease_token(S_O_mem_lease_token),
        .O_mem_generation(S_O_mem_generation),
        .I_mem_done_valid(S_I_mem_done_valid),
        .O_mem_done_ready(S_O_mem_done_ready),
        .I_mem_done_tag(S_I_mem_done_tag),
        .I_mem_done_lease_token(S_I_mem_done_lease_token),
        .I_mem_done_generation(S_I_mem_done_generation),
        .I_mem_done_error(S_I_mem_done_error),
        .I_rect_x(S_I_rect_x),
        .I_rect_y(S_I_rect_y),
        .I_rect_width(S_I_rect_width),
        .I_rect_height(S_I_rect_height),
        .I_bilinear(S_I_bilinear),
        .I_clear_rgba(S_I_clear_rgba),
        .I_compose(S_I_compose),
        .I_parts(S_I_parts),
        .O_part_needed(S_O_part_needed),
        .O_part_index(S_O_part_index),
        .I_part_valid(S_I_part_valid),
        .O_part_ready(S_O_part_ready),
        .I_part_path_length(S_I_part_path_length)
    );
    always #4 S_I_clk=~S_I_clk;
    reg S_test_pass=0;
    integer S_case=0;
    task fail;
        input [767:0] message;
        begin $display("FAIL: case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #1000000000; fail("watchdog timeout"); end
    // Keep long full-frame runs observable, including the owner waiting on I/O.
    initial begin
        forever begin
            #1000000;
            $display("PROGRESS: t=%0t case=%0d ctrl=%0d writes=%0d replies=%0d byte=%0d file=%b transform=%b writer=%b",
                $time,S_case,u_dut.u_ctrl.S_state,S_writes,S_replies,S_I_fs_byte_offset,
                u_dut.u_ctrl.S_file_seen,u_dut.u_ctrl.S_transform_seen,u_dut.u_ctrl.S_writer_seen);
            $display("PROGRESS: source=%0d decoder=%0d parser=%0d parse_error=%0d transform=%0d writer=%0d pixels=%0d",
                u_dut.u_file.S_state,u_dut.u_file.u_parser.S_state,u_dut.u_file.u_parser.u_bmp.S_state,
                u_dut.u_file.O_parser_error,u_dut.u_transform.S_state,u_dut.u_writer.S_state,S_O_pixels);
        end
    end
    wire [17:0] S_states;
    fb_slot_manager u_slots (
        .I_clk(S_I_clk),
        .I_reset(S_I_reset),
        .I_media_valid(S_I_media_valid),
        .I_media_generation(S_I_media_generation),
        .I_cmd_valid(S_O_slot_cmd_valid),
        .O_cmd_ready(S_I_slot_cmd_ready),
        .I_cmd_op(S_O_slot_cmd_op),
        .I_cmd_slot(S_O_slot_cmd_slot),
        .I_cmd_owner(S_O_slot_cmd_owner),
        .I_cmd_token(S_O_slot_cmd_token),
        .I_cmd_generation(S_O_slot_cmd_generation),
        .I_cmd_asset(S_O_slot_cmd_asset),
        .I_cmd_layout(S_O_slot_cmd_layout),
        .I_cmd_rotation(S_O_slot_cmd_rotation),
        .I_cmd_resident(S_O_slot_cmd_resident),
        .I_cmd_success(S_O_slot_cmd_success),
        .I_producer_retired(S_O_producer_retired),
        .I_memory_retired(S_O_memory_retired),
        .I_reader_retired(1'b1),
        .I_frame_boundary(1'b0),
        .O_result_valid(S_I_slot_result_valid),
        .I_result_ready(S_O_slot_result_ready),
        .O_result_error(S_I_slot_result_error),
        .O_result_op(S_I_slot_result_op),
        .O_result_slot(S_I_slot_result_slot),
        .O_result_owner(S_I_slot_result_owner),
        .O_result_token(S_I_slot_result_token),
        .O_result_generation(S_I_slot_result_generation),
        .O_result_base(),
        .O_slot_states(S_states),
        .O_slot_tokens(),
        .O_slot_generations(),
        .O_slot_assets(),
        .O_slot_layouts(),
        .O_slot_readers(),
        .O_slot_rotations(),
        .O_slot_resident(),
        .O_slot_stale(),
        .O_cancel_loading(),
        .O_token_exhausted()
    );

    // A single registered logical write response. Not a model of SDRAM timing.
    reg S_allow_memory=1,S_inject_write_error=0,S_response_hold=0;
    reg S_endpoint_valid=0,S_hold_last_response=0;
    reg [31:0] S_frame[0:307199];
    integer S_writes=0,S_replies=0,S_closes=0,S_cycle=0;
    reg [7:0] S_bmp[0:699];
    integer S_i,S_j,S_bpp=24;
    integer S_bad_config=0;
    reg S_top_down=0;
    reg [1:0] S_rotation=0;
    reg S_mem_held=0;
    reg [153:0] S_mem_saved;
    assign S_I_mem_done_valid=S_endpoint_valid && !S_response_hold;
    assign S_I_mem_ready=S_allow_memory &&
        (!S_endpoint_valid || (S_O_mem_done_ready && !S_response_hold)) && S_cycle%5!=0;
    always @(posedge S_I_clk) begin
        if(S_I_reset) begin
            S_endpoint_valid<=0; S_writes=0; S_replies=0; S_closes=0; S_cycle<=0; S_mem_held<=0;
        end else begin
            S_cycle<=S_cycle+1;
            if(S_I_mem_done_valid && S_O_mem_done_ready && !S_response_hold) begin
                S_endpoint_valid<=0; S_replies=S_replies+1;
            end
            if(S_O_mem_valid && S_I_mem_ready) begin
                if(!S_O_mem_wr || S_O_mem_mask!==0 || S_O_mem_addr>=307200 ||
                    S_O_mem_lease_token!==S_O_lease_token || S_O_mem_generation!==7) fail("logical write identity/address/mask");
                S_frame[S_O_mem_addr]=S_O_mem_data;
                S_writes=S_writes+1;
                S_endpoint_valid<=1; S_I_mem_done_tag<=S_O_mem_tag;
                S_I_mem_done_lease_token<=S_O_mem_lease_token; S_I_mem_done_generation<=S_O_mem_generation;
                S_I_mem_done_error<=S_inject_write_error ? 4'd9 : 4'd0;
                // Hold BEFORE this response is first published, never withdraw valid.
                if(S_hold_last_response && S_writes==307206) S_response_hold<=1;
            end
            if(S_mem_held && (!S_O_mem_valid || S_mem_saved!=={S_O_mem_wr,S_O_mem_addr,S_O_mem_data,
                S_O_mem_tag,S_O_mem_mask,S_O_mem_lease_token,S_O_mem_generation})) fail("write command changed during stall");
            S_mem_held<=S_O_mem_valid && !S_I_mem_ready;
            S_mem_saved<={S_O_mem_wr,S_O_mem_addr,S_O_mem_data,S_O_mem_tag,S_O_mem_mask,S_O_mem_lease_token,S_O_mem_generation};
            if(S_O_fs_close_valid && S_I_fs_close_ready) S_closes=S_closes+1;
            if(S_states[2:0]==3'd2 && (!S_O_published && !S_O_done_valid &&
                !(S_I_slot_result_valid && S_I_slot_result_op==1 && S_I_slot_result_error==0)))
                fail("READY without successful FINISH");
        end
    end
    task bmp32;
        input integer address;
        input [31:0] value;
        begin S_bmp[address]=value; S_bmp[address+1]=value>>8;
            S_bmp[address+2]=value>>16; S_bmp[address+3]=value>>24; end
    endtask
    task make_bmp;
        input integer bpp;
        input top_down;
        begin
            S_bpp=bpp; S_top_down=top_down;
            for(S_i=0;S_i<700;S_i=S_i+1) S_bmp[S_i]=0;
            S_bmp[0]="B"; S_bmp[1]="M";
            bmp32(2,700); bmp32(10,510); bmp32(14,40); bmp32(18,3);
            bmp32(22,top_down ? 32'hfffffffe : 32'd2);
            S_bmp[26]=1; S_bmp[28]=bpp; bmp32(34,24);
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                S_j=510+(S_i/3)*12+(S_i%3)*(bpp/8);
                S_bmp[S_j]=8'h30+S_i; S_bmp[S_j+1]=8'h20+S_i; S_bmp[S_j+2]=8'h10+S_i;
                if(bpp==32) S_bmp[S_j+3]=S_i;
            end
            for(S_i=534;S_i<700;S_i=S_i+1) S_bmp[S_i]=8'ha5;
        end
    endtask
    task reset_all;
        begin
            @(negedge S_I_clk); S_I_reset=1; S_I_abort=0; S_I_start_valid=0; S_I_done_ready=0;
            S_I_media_valid=1; S_I_media_generation=7; S_I_lease_grant=1;
            S_I_fs_open_ready=1; S_I_fs_path_ready=1; S_I_fs_read_ready=1; S_I_fs_close_ready=1;
            S_I_fs_open_result_valid=0; S_I_fs_byte_valid=0; S_I_fs_done_valid=0;
            S_I_fs_cancel_ready=0; S_I_fs_cancel_done_valid=0; S_I_path_valid=0;
            S_allow_memory=1; S_response_hold=0; S_inject_write_error=0; S_hold_last_response=0; S_bad_config=0;
            repeat(4) @(negedge S_I_clk); S_I_reset=0;
        end
    endtask
    task launch;
        begin
            S_case=S_case+1;
            @(negedge S_I_clk); S_I_context=1; S_I_tag=16'hf135; S_I_generation=7;
            S_I_slot=0; S_I_asset=53; S_I_layout=0; S_I_rotation=S_rotation;
            S_I_rect_x=S_bad_config==2 ? 65535 : 11;
            S_I_rect_y=19; S_I_rect_width=S_rotation[0] ? 2 : 3;
            S_I_rect_height=S_rotation[0] ? 3 : 2; S_I_bilinear=S_case%2;
            S_I_clear_rgba=32'h040506ff; S_I_path_length=S_bad_config==1 ? 65 : 9; S_I_sector_budget=8;
            S_I_start_valid=1;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task send_path;
        reg [71:0] path;
        integer j;
        begin
            path="/TEST.BMP";
            for(j=0;j<9;j=j+1) begin
                @(negedge S_I_clk); S_I_path_valid=1; S_I_path_data=path[(8-j)*8+:8]; S_I_path_last=j==8;
                @(posedge S_I_clk); while(!S_O_path_ready) @(posedge S_I_clk);
            end
            @(negedge S_I_clk); S_I_path_valid=0;
        end
    endtask
    task open_result;
        input [7:0] error;
        begin
            @(negedge S_I_clk); S_I_fs_open_context=1; S_I_fs_open_tag=16'hf135;
            S_I_fs_open_generation=7; S_I_fs_open_size=700; S_I_fs_open_error=error;
            S_I_fs_open_result_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_open_result_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_open_result_valid=0;
        end
    endtask
    task byte_in;
        input integer offset;
        begin
            @(negedge S_I_clk); S_I_fs_byte_context=1; S_I_fs_byte_epoch=16'hf135;
            S_I_fs_byte_generation=7; S_I_fs_byte_offset=offset; S_I_fs_byte_data=S_bmp[offset];
            S_I_fs_byte_last=offset==699; S_I_fs_byte_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_byte_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_byte_valid=0;
        end
    endtask
    task read_done;
        input [31:0] count;
        input [7:0] error;
        begin
            @(negedge S_I_clk); S_I_fs_done_context=1; S_I_fs_done_epoch=16'hf135;
            S_I_fs_done_generation=7; S_I_fs_done_bytes=count; S_I_fs_done_error=error;
            S_I_fs_done_eof=error==0; S_I_fs_done_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_done_valid=0;
        end
    endtask
    task cancel_ack;
        begin
            @(negedge S_I_clk); S_I_fs_cancel_done_context=1; S_I_fs_cancel_done_epoch=16'hf135;
            S_I_fs_cancel_done_generation=7; S_I_fs_cancel_done_valid=1;
            @(posedge S_I_clk); while(!S_O_fs_cancel_done_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_fs_cancel_done_valid=0;
        end
    endtask
    task assert_loading;
        begin
            repeat(8) begin @(negedge S_I_clk);
                if(S_states[2:0]!==1 || S_O_done_valid || S_O_published) fail("premature publication or lease release"); end
        end
    endtask
    task take_result;
        input [3:0] error;
        input published;
        reg [161:0] saved;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_published!==published || S_O_slot_owned || !S_O_lease_active ||
                (published && (S_states[2:0]!==2 || S_O_pixels!==6 || S_O_accepted_writes!==307206 ||
                 S_O_retired_writes!==307206 || S_closes!=1))) fail("loader result/retirement counts");
            saved={S_O_error,S_O_published,S_O_slot_owned,S_O_lease_token,S_O_file_source_error,
                S_O_parser_error,S_O_file_error,S_O_transform_error,S_O_writer_error,S_O_memory_error,
                S_O_accepted_writes,S_O_retired_writes,S_O_pixels};
            repeat(5) begin @(negedge S_I_clk);
                if(!S_O_done_valid || saved!=={S_O_error,S_O_published,S_O_slot_owned,S_O_lease_token,
                    S_O_file_source_error,S_O_parser_error,S_O_file_error,S_O_transform_error,S_O_writer_error,
                    S_O_memory_error,S_O_accepted_writes,S_O_retired_writes,S_O_pixels}) fail("held result"); end
            S_I_done_ready=1; @(negedge S_I_clk); S_I_done_ready=0;
            if(S_O_busy || S_O_lease_active) fail("root namespace lease not released");
        end
    endtask
    task check_frame;
        integer u,v,px,py,k,at;
        reg [31:0] expected;
        begin
            // Independent direct inverse mapping for this unscaled 3x2 image.
            for(at=0;at<307200;at=at+1) begin
                expected=32'h040506ff;
                for(v=0;v<2;v=v+1) for(u=0;u<3;u=u+1) begin
                    case(S_rotation)
                        0:begin px=u; py=v; end
                        1:begin px=1-v; py=u; end
                        2:begin px=2-u; py=1-v; end
                        3:begin px=v; py=2-u; end
                    endcase
                    if(at==(19+py)*640+11+px) begin
                        k=(S_top_down ? v : 1-v)*3+u;
                        expected={8'h10+k[7:0],8'h20+k[7:0],8'h30+k[7:0],8'hff};
                    end
                end
                if(S_frame[at]!==expected) fail("full frame RGBA/black border/rotation");
            end
        end
    endtask
    integer k,r;
    integer S_layout_case,S_part_case,S_expected_pixels,S_part_pixels,S_before_part;
    reg [31:0] S_compose_token;
    task compose_launch;
        input [2:0] layout;
        input [3:0] parts;
        begin
            @(negedge S_I_clk); S_I_compose=1; S_I_parts=parts; S_I_layout=layout;
            S_I_context=1; S_I_tag=16'hf135; S_I_generation=7; S_I_slot=0; S_I_asset=91;
            S_I_rotation=0; S_I_bilinear=0; S_I_clear_rgba=32'h000000ff;
            S_I_rect_x=0; S_I_rect_y=0; S_I_rect_width=640; S_I_rect_height=480;
            S_I_sector_budget=8; S_I_path_length=9; S_I_start_valid=1;
            @(posedge S_I_clk); while(!S_O_start_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_start_valid=0;
        end
    endtask
    task next_part;
        input integer ordinal;
        begin
            wait(S_O_part_needed); assert_loading;
            if(S_O_part_index!==ordinal || S_O_lease_token!==S_compose_token || !S_O_lease_active)
                fail("composition changed lease or part ordinal");
            S_before_part=S_writes;
            repeat(12) @(negedge S_I_clk);
            if(S_writes!=S_before_part) fail("part wait fabricated writes");
            @(negedge S_I_clk); S_I_part_valid=1;
            @(posedge S_I_clk); while(!S_O_part_ready) @(posedge S_I_clk);
            @(negedge S_I_clk); S_I_part_valid=0;
        end
    endtask
    task check_composed_frame;
        input integer layout;
        input integer parts;
        integer at,x,y,p,rx,ry,rw,rh,iw,ih,ix,iy;
        reg [31:0] expected;
        begin
            // Independent reference rectangles for solid 3:2 test images.
            // No DUT geometry helper is used by this expected-frame comparison.
            for(at=0;at<307200;at=at+1) begin
                x=at%640; y=at/640; expected=32'h000000ff;
                for(p=0;p<parts;p=p+1) begin
                    rx=0; ry=0; rw=640; rh=480;
                    case(layout)
                        1:if(p==1) begin rx=462; ry=18; rw=160; rh=120; end
                        2:begin rx=p*320; rw=320; end
                        3:begin rx=(p%2)*320; ry=(p/2)*240; rw=320; rh=240; end
                        4:begin rx=(p%3)*213; ry=(p/3)*160; rw=213; rh=144; end
                        default:begin end
                    endcase
                    iw=rw; ih=rw*2/3; ix=rx; iy=ry+(rh-ih)/2;
                    if(layout==1 && p==1 && x>=rx && x<rx+rw && y>=ry && y<ry+rh)
                        expected=32'h000000ff;
                    if(x>=ix && x<ix+iw && y>=iy && y<iy+ih)
                        expected={8'h10+p[7:0],8'h20+p[7:0],8'h30+p[7:0],8'hff};
                end
                if(layout==1 && x>=460 && x<624 && y>=16 && y<140 &&
                    (x<462 || x>=622 || y<18 || y>=138)) expected=32'hffffffff;
                if(layout==2 && (x==319 || x==320)) expected=32'hffffffff;
                if(S_frame[at]!==expected) fail("composed FULL/PIP/DUAL/QUAD/THUMB frame mismatch");
            end
        end
    endtask
    initial begin
        // Four rotations, both BMP formats, top/bottom row order; no reset inside a job.
        for(r=0;r<4;r=r+1) begin
            reset_all; S_rotation=r; S_hold_last_response=r==3;
            make_bmp(r[0] ? 32 : 24,r[1]); launch; send_path; open_result(0);
            // Root command snapshot is independent of current upstream values.
            S_I_tag=2; S_I_generation=99; S_I_rect_width=600; S_I_rotation=3; S_I_clear_rgba=0;
            for(k=0;k<700;k=k+1) byte_in(k);
            if(u_dut.u_file.O_error!=0 || u_dut.u_file.O_parser_error!=0)
                fail("unexpected source/parser failure before file retirement");
            wait(u_dut.u_ctrl.S_transform_seen); assert_loading;
            if(u_dut.u_ctrl.S_file_seen) fail("file done inferred from final pixel/byte");
            S_I_fs_close_ready=0; read_done(700,0); wait(S_O_fs_close_valid); assert_loading;
            @(negedge S_I_clk); S_I_fs_close_ready=1;
            if(r==3) begin
                wait(u_dut.u_ctrl.S_file_seen && S_response_hold); assert_loading;
                if(u_dut.u_ctrl.S_writer_seen) fail("memory response inferred from command acceptance");
                @(negedge S_I_clk); S_response_hold=0;
            end
            take_result(0,1); check_frame;
        end

        // Transform and all pixels succeeded, but the real file terminal fails late.
        reset_all; S_rotation=0; make_bmp(24,0); launch; send_path; open_result(0);
        for(k=0;k<700;k=k+1) byte_in(k);
        wait(u_dut.u_ctrl.S_transform_seen); assert_loading; read_done(700,9);
        take_result(3,0);
        if(S_states[2:0]!==4 || S_O_file_error!==9 || S_O_transform_error!==0) fail("late file failure published candidate");

        // Write failure before pixels: cancel accepts, but read.done/ack/close are separate debts.
        reset_all; S_rotation=0; make_bmp(32,1); launch; send_path; open_result(0);
        S_inject_write_error=1;
        for(k=0;k<54;k=k+1) byte_in(k);
        wait(S_O_fs_cancel_valid); assert_loading;
        @(negedge S_I_clk); S_I_fs_cancel_ready=1; S_I_fs_close_ready=0;
        @(negedge S_I_clk); S_I_fs_cancel_ready=0;
        read_done(54,8); assert_loading;
        if(S_O_fs_close_valid) fail("read done without cancel ack closed file");
        cancel_ack; wait(S_O_fs_close_valid); assert_loading;
        @(negedge S_I_clk); S_I_fs_close_ready=1;
        take_result(5,0);
        if(S_O_memory_error!==9 || S_O_writer_error!==3 || S_states[2:0]!==4) fail("writer root cause lost to peer abort");

        // Open failure has no parser/transform/writer or memory obligation.
        reset_all; launch; send_path; open_result(2); take_result(3,0);
        if(S_O_transform_started || S_O_writer_started || S_writes!=0 || S_closes!=0) fail("unstarted obligations fabricated");
        // ERROR may be reallocated only after the previous real result was consumed.
        launch; send_path; open_result(2); take_result(3,0);
        if(S_O_lease_token!==2 || S_O_transform_started || S_O_writer_started || S_writes!=0)
            fail("successive owner transaction without local reset");

        // Media outage is sticky across recovery and still requires real file retirement.
        reset_all; launch; send_path; open_result(0);
        for(k=0;k<54;k=k+1) byte_in(k);
        @(negedge S_I_clk); S_I_media_valid=0;
        @(negedge S_I_clk); S_I_media_valid=1;
        wait(S_O_fs_cancel_valid);
        @(negedge S_I_clk); S_I_fs_cancel_ready=1;
        @(negedge S_I_clk); S_I_fs_cancel_ready=0;
        read_done(54,8); assert_loading; cancel_ack; take_result(6,0);
        if(S_states[2:0]!==0) fail("stale loading slot was not retired");

        reset_all; S_bad_config=1; launch; take_result(1,0);
        if(S_O_file_started || S_states[2:0]!==0 || S_writes!=0) fail("bad path length allocated work");
        reset_all; S_bad_config=2; launch; take_result(1,0);
        if(S_O_file_started || S_states[2:0]!==0 || S_writes!=0) fail("rectangle addition wrapped to legal range");

        // All layouts really pass through parser/scaler/writer and one LOADING token.
        for(S_layout_case=0;S_layout_case<5;S_layout_case=S_layout_case+1) begin
            reset_all; S_I_compose=0;
            compose_launch(S_layout_case,S_layout_case==0 ? 1 : S_layout_case<3 ? 2 : S_layout_case==3 ? 4 : 9);
            S_expected_pixels=0;
            for(S_part_case=0;S_part_case<S_I_parts;S_part_case=S_part_case+1) begin
                if(S_part_case!=0) next_part(S_part_case);
                make_bmp(24,1);
                for(k=0;k<6;k=k+1) begin
                    S_j=510+(k/3)*12+(k%3)*3;
                    S_bmp[S_j]=8'h30+S_part_case; S_bmp[S_j+1]=8'h20+S_part_case;
                    S_bmp[S_j+2]=8'h10+S_part_case;
                end
                send_path; open_result(0);
                if(S_part_case==0) S_compose_token=S_O_lease_token;
                case(S_layout_case)
                    0:S_part_pixels=640*426;
                    1:S_part_pixels=S_part_case==0 ? 640*426 : 160*106;
                    2,3:S_part_pixels=320*213;
                    default:S_part_pixels=213*142;
                endcase
                S_expected_pixels=S_expected_pixels+S_part_pixels;
                for(k=0;k<700;k=k+1) byte_in(k);
                read_done(700,0);
            end
            wait(S_O_done_valid); #1;
            if(S_O_error || !S_O_published || S_O_slot_owned || S_states[2:0]!==2 ||
                S_O_pixels!==S_expected_pixels || S_O_accepted_writes!==S_O_retired_writes ||
                S_O_retired_writes!==307200+S_expected_pixels+(S_layout_case==1 ? 19200 : 0) ||
                S_closes!=S_I_parts) fail("composition published before all parts actually retired");
            check_composed_frame(S_layout_case,S_I_parts);
            @(negedge S_I_clk); S_I_done_ready=1;
            @(negedge S_I_clk); S_I_done_ready=0; S_I_compose=0;
        end
        // Cancel while waiting for a second path must retire the original LOADING lease.
        reset_all; compose_launch(2,2); make_bmp(24,1); send_path; open_result(0);
        for(k=0;k<700;k=k+1) byte_in(k);
        read_done(700,0); wait(S_O_part_needed); assert_loading;
        @(negedge S_I_clk); S_I_abort=1;
        take_result(7,0);
        if(S_states[2:0]!==4) fail("canceled partial frame remained reusable");
        S_test_pass=1; $display("PASS: real single/composed BMP frame loader + slot manager; file/memory endpoints only"); $finish;
    end
endmodule
