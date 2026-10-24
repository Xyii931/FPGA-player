`timescale 1ns/1ps
// Real reader/CDC/RAM plus explicit logical memory endpoint; no physical IP model.
module tb_scanout_engine;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_async_reset=0,S_test_pass=0;
    wire S_video_reset;
    reg S_arm=0,S_deadline_enable=1,S_task_gate=1,S_line_gate=1,S_wrong_line=0;
    reg [1:0] S_release_gate=3;
    reg S_mem_enable=1,S_delay_row7=0,S_inject_memory=0,S_inject_pixel=0;
    reg S_external_task_valid=0,S_external_bank=0,S_external_line_ready=0;
    reg [1:0] S_guard_reserve=0,S_guard_retire=0;
    wire [1:0] S_source_in_use,S_source_owner_retired,S_source_pipeline_retired;
    wire [1:0] S_guard_idle,S_guard_permit,S_guard_ack,S_guard_busy,S_guard_host_fault;
    wire [1:0] S_guard_block,S_guard_stop,S_guard_video_ack,S_guard_video_fault;
    wire S_bad_pixel;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reset_sync u_video_reset (.I_clk(S_video_clk),.I_async_reset(S_async_reset),.O_reset(S_video_reset));
    wire  S_e_O_config_ready;
    wire  S_e_O_config_applied;
    wire  S_e_O_config_error;
    reg [1:0] S_e_I_source_mask=0;
    reg  S_e_I_from_source=0;
    reg [5:0] S_e_I_slots=0;
    reg [63:0] S_e_I_tokens=0;
    reg [63:0] S_e_I_generations=0;
    wire [8:0] S_e_O_prefetch_y;
    wire [31:0] S_e_O_active_epoch;
    wire  S_e_O_task_valid;
    wire  S_e_O_task_source;
    wire  S_e_O_task_bank;
    wire [2:0] S_e_O_task_slot;
    wire [20:0] S_e_O_task_base;
    wire [8:0] S_e_O_task_y;
    wire [31:0] S_e_O_task_token;
    wire [31:0] S_e_O_task_generation;
    wire [31:0] S_e_O_task_epoch;
    wire [31:0] S_e_O_task_deadline;
    wire [15:0] S_e_O_task_tag;
    wire  S_e_O_line_ready;
    wire [1:0] S_e_O_read_valid;
    wire [1:0] S_e_O_read_bank;
    wire [19:0] S_e_O_read_x;
    wire [1:0] S_e_O_release_valid;
    wire [1:0] S_e_O_release_bank;
    wire [63:0] S_e_O_release_token;
    wire [63:0] S_e_O_release_generation;
    wire [63:0] S_e_O_release_epoch;
    wire [31:0] S_e_O_release_tag;
    wire [3:0] S_e_O_owned_banks;
    reg [31:0] S_e_I_retire_epoch=0;
    wire  S_e_O_epoch_retired;
    reg  S_e_I_stop_request=0;
    wire  S_e_O_stop_ack;
    wire  S_e_O_pipeline_idle;
    wire  S_e_O_frame_start;
    wire  S_e_O_video_und;
    wire [31:0] S_e_O_und_count;
    wire [31:0] S_e_O_line_error_count;
    wire [3:0] S_e_O_last_line_error;
    wire [3:0] S_e_O_last_memory_error;
    wire  S_e_O_contract_fault;
    wire  S_e_O_valid;
    wire  S_e_O_hsync;
    wire  S_e_O_vsync;
    wire  S_e_O_de;
    wire  S_e_O_frame_mark;
    wire  S_e_O_line_start;
    wire [15:0] S_e_O_x;
    wire [15:0] S_e_O_y;
    wire [23:0] S_e_O_rgb;
    wire [31:0] S_e_O_epoch;
    wire [15:0] S_e_O_tag;
    wire  S_e_O_repeated;
    wire  S_e_O_pixel_fault;
    reg [1:0] S_r_I_lease_valid=0;
    reg [5:0] S_r_I_lease_slot=0;
    reg [63:0] S_r_I_lease_token=0;
    reg [63:0] S_r_I_lease_generation=0;
    wire  S_r_O_task_ready;
    wire  S_r_O_line_valid;
    wire [3:0] S_r_O_line_error;
    wire [3:0] S_r_O_line_memory_error;
    wire [2:0] S_r_O_line_slot;
    wire [20:0] S_r_O_line_base;
    wire [8:0] S_r_O_line_y;
    wire  S_r_O_line_bank;
    wire [31:0] S_r_O_line_token;
    wire [31:0] S_r_O_line_generation;
    wire [31:0] S_r_O_line_epoch;
    wire [31:0] S_r_O_line_deadline;
    wire [15:0] S_r_O_line_tag;
    wire [9:0] S_r_O_line_accepted;
    wire [9:0] S_r_O_line_retired;
    wire [1:0] S_r_O_read_ready;
    wire [1:0] S_r_O_pixel_valid;
    wire [63:0] S_r_O_rgba;
    wire [1:0] S_r_O_pixel_bank;
    wire [19:0] S_r_O_pixel_x;
    wire [63:0] S_r_O_pixel_token;
    wire [63:0] S_r_O_pixel_generation;
    wire [63:0] S_r_O_pixel_epoch;
    wire [31:0] S_r_O_pixel_tag;
    wire [1:0] S_r_O_release_ready;
    wire [3:0] S_r_O_bank_valid;
    wire [3:0] S_r_O_bank_reserved;
    wire [11:0] S_r_O_bank_slots;
    wire [35:0] S_r_O_bank_rows;
    wire [127:0] S_r_O_bank_tokens;
    wire [127:0] S_r_O_bank_generations;
    wire [127:0] S_r_O_bank_epochs;
    wire [63:0] S_r_O_bank_tags;
    wire [1:0] S_r_I_retire_request=S_guard_stop;
    wire [1:0] S_r_O_retire_ack;
    wire [1:0] S_r_O_host_retired;
    wire [1:0] S_r_O_host_busy;
    wire [1:0] S_r_O_host_tag_exhausted;
    wire [1:0] S_r_O_release_discarded;
    wire [1:0] S_r_O_event_discarded;
    wire [1:0] S_r_O_response_discarded;
    wire [1:0] S_r_O_mem_valid;
    wire [1:0] S_r_I_mem_ready;
    wire [41:0] S_r_O_mem_addr;
    wire [63:0] S_r_O_mem_tag;
    wire [63:0] S_r_O_mem_token;
    wire [63:0] S_r_O_mem_generation;
    wire [63:0] S_r_O_mem_deadline;
    wire [1:0] S_r_I_mem_valid;
    wire [1:0] S_r_O_mem_ready;
    wire [63:0] S_r_I_mem_data;
    wire [63:0] S_r_I_mem_tag;
    wire [63:0] S_r_I_mem_token;
    wire [63:0] S_r_I_mem_generation;
    wire [7:0] S_r_I_mem_error;
    wire  S_r_O_line_source;
    reg  S_p_I_start_valid=0;
    wire  S_p_O_start_ready;
    reg [2:0] S_p_I_effect=0;
    reg [16:0] S_p_I_progress=0;
    reg [31:0] S_p_I_epoch=0;
    reg [15:0] S_p_I_tag=0;
    wire  S_p_O_done_valid;
    wire [3:0] S_p_O_error;
    wire [2:0] S_p_O_effect;
    wire [16:0] S_p_O_progress;
    wire [31:0] S_p_O_epoch;
    wire [15:0] S_p_O_tag;
    wire [9:0] S_p_O_dx;
    wire [9:0] S_p_O_left;
    wire [8:0] S_p_O_dy;
    wire [8:0] S_p_O_top;
    wire [5:0] S_p_O_blind_count;
    wire [8:0] S_p_O_mosaic_count;
    wire [19:0] S_p_O_wipe_threshold;
    wire [31:0] S_p_O_step_x;
    wire [31:0] S_p_O_step_y;
    // This fixture has no external candidate owner during guard scenarios.
    display_source_guard u_guard (
        .I_host_clk(S_host_clk),.I_video_clk(S_video_clk),.I_async_reset(S_async_reset),
        .I_host_reserve(S_guard_reserve),.I_host_retire_request(S_guard_retire),
        .O_host_source_idle(S_guard_idle),.O_host_acquire_permit(S_guard_permit),
        .O_host_retire_ack(S_guard_ack),.O_host_busy(S_guard_busy),.O_host_fault(S_guard_host_fault),
        .I_video_frame_start(S_e_O_frame_start),.I_video_in_use(S_source_in_use),
        .I_video_reader_ack(S_r_O_retire_ack),.I_video_owner_retired(S_source_owner_retired),
        .I_video_pipeline_retired(S_source_pipeline_retired),.O_video_block(S_guard_block),
        .O_video_reader_stop(S_guard_stop),.O_video_retire_ack(S_guard_video_ack),.O_video_fault(S_guard_video_fault)
    );
    scanout_engine u_engine (
        .I_seed_valid(1'b0),.I_seed_bank(2'b00),.I_seed_y(18'd0),.I_seed_tag(32'd0),
        .I_clk(S_video_clk),
        .I_reset(S_video_reset),
        .I_config_valid(S_p_O_done_valid && S_p_O_error==0 && S_arm),
        .O_config_ready(S_e_O_config_ready),
        .O_config_applied(S_e_O_config_applied),
        .O_config_error(S_e_O_config_error),
        .I_source_mask(S_e_I_source_mask),
        .I_source_block(S_guard_block),
        .O_source_in_use(S_source_in_use),
        .O_source_owner_retired(S_source_owner_retired),
        .O_source_pipeline_retired(S_source_pipeline_retired),
        .I_from_source(S_e_I_from_source),
        .I_slots(S_e_I_slots),
        .I_tokens(S_e_I_tokens),
        .I_generations(S_e_I_generations),
        .I_effect(S_p_O_effect),
        .I_progress(S_p_O_progress),
        .I_epoch(S_p_O_epoch),
        .I_tag(S_p_O_tag),
        .I_dx(S_p_O_dx),
        .I_left(S_p_O_left),
        .I_dy(S_p_O_dy),
        .I_top(S_p_O_top),
        .I_blind_count(S_p_O_blind_count),
        .I_mosaic_count(S_p_O_mosaic_count),
        .I_wipe_threshold(S_p_O_wipe_threshold),
        .I_step_x(S_p_O_step_x),
        .I_step_y(S_p_O_step_y),
        .O_prefetch_y(S_e_O_prefetch_y),
        .O_active_epoch(S_e_O_active_epoch),
        .I_deadline_valid(S_deadline_enable),
        .I_deadline_y(S_e_O_prefetch_y),
        .I_deadline_epoch(S_e_O_active_epoch),
        .I_deadline(32'h12345678),
        .O_task_valid(S_e_O_task_valid),
        .I_task_ready(S_r_O_task_ready && S_task_gate && !S_external_task_valid),
        .O_task_source(S_e_O_task_source),
        .O_task_bank(S_e_O_task_bank),
        .O_task_slot(S_e_O_task_slot),
        .O_task_base(S_e_O_task_base),
        .O_task_y(S_e_O_task_y),
        .O_task_token(S_e_O_task_token),
        .O_task_generation(S_e_O_task_generation),
        .O_task_epoch(S_e_O_task_epoch),
        .O_task_deadline(S_e_O_task_deadline),
        .O_task_tag(S_e_O_task_tag),
        .I_line_valid(S_r_O_line_valid && S_line_gate),
        .O_line_ready(S_e_O_line_ready),
        .I_line_source(S_r_O_line_source),
        .I_line_bank(S_r_O_line_bank),
        .I_line_error(S_r_O_line_error),
        .I_line_memory_error(S_r_O_line_memory_error),
        .I_line_slot(S_r_O_line_slot),
        .I_line_base(S_r_O_line_base),
        .I_line_y(S_r_O_line_y),
        .I_line_token(S_r_O_line_token),
        .I_line_generation(S_r_O_line_generation),
        .I_line_epoch(S_r_O_line_epoch),
        .I_line_deadline(S_r_O_line_deadline),
        .I_line_tag(S_r_O_line_tag ^ (S_wrong_line ? 16'd1 : 16'd0)),
        .I_bank_valid(S_r_O_bank_valid),
        .I_bank_reserved(S_r_O_bank_reserved),
        .I_bank_slots(S_r_O_bank_slots),
        .I_bank_rows(S_r_O_bank_rows),
        .I_bank_tokens(S_r_O_bank_tokens),
        .I_bank_generations(S_r_O_bank_generations),
        .I_bank_epochs(S_r_O_bank_epochs),
        .I_bank_tags(S_r_O_bank_tags),
        .O_read_valid(S_e_O_read_valid),
        .O_read_bank(S_e_O_read_bank),
        .I_read_ready(S_r_O_read_ready),
        .O_read_x(S_e_O_read_x),
        .I_pixel_valid(S_r_O_pixel_valid),
        .I_pixel_bank(S_r_O_pixel_bank),
        .I_pixel_x(S_r_O_pixel_x),
        .I_rgba(S_r_O_rgba),
        .I_pixel_token(S_r_O_pixel_token),
        .I_pixel_generation(S_r_O_pixel_generation),
        .I_pixel_epoch(S_r_O_pixel_epoch),
        .I_pixel_tag(S_r_O_pixel_tag ^ (S_bad_pixel ? 32'd1 : 32'd0)),
        .O_release_valid(S_e_O_release_valid),
        .O_release_bank(S_e_O_release_bank),
        .I_release_ready(S_r_O_release_ready & S_release_gate),
        .O_release_token(S_e_O_release_token),
        .O_release_generation(S_e_O_release_generation),
        .O_release_epoch(S_e_O_release_epoch),
        .O_release_tag(S_e_O_release_tag),
        .O_owned_banks(S_e_O_owned_banks),
        .I_retire_epoch(S_e_I_retire_epoch),
        .O_epoch_retired(S_e_O_epoch_retired),
        .I_stop_request(S_e_I_stop_request),
        .O_stop_ack(S_e_O_stop_ack),
        .O_pipeline_idle(S_e_O_pipeline_idle),
        .O_frame_start(S_e_O_frame_start),
        .O_video_und(S_e_O_video_und),
        .O_und_count(S_e_O_und_count),
        .O_line_error_count(S_e_O_line_error_count),
        .O_last_line_error(S_e_O_last_line_error),
        .O_last_memory_error(S_e_O_last_memory_error),
        .O_contract_fault(S_e_O_contract_fault),
        .O_valid(S_e_O_valid),
        .O_hsync(S_e_O_hsync),
        .O_vsync(S_e_O_vsync),
        .O_de(S_e_O_de),
        .O_frame_mark(S_e_O_frame_mark),
        .O_line_start(S_e_O_line_start),
        .O_x(S_e_O_x),
        .O_y(S_e_O_y),
        .O_rgb(S_e_O_rgb),
        .O_epoch(S_e_O_epoch),
        .O_tag(S_e_O_tag),
        .O_repeated(S_e_O_repeated),
        .O_pixel_fault(S_e_O_pixel_fault)
    );
    fb_reader u_reader (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_async_reset),
        .I_lease_valid(S_r_I_lease_valid),
        .I_lease_slot(S_r_I_lease_slot),
        .I_lease_token(S_r_I_lease_token),
        .I_lease_generation(S_r_I_lease_generation),
        .I_task_valid(S_external_task_valid || (S_e_O_task_valid && S_task_gate)),
        .O_task_ready(S_r_O_task_ready),
        .I_task_slot(S_external_task_valid ? 3'd0 : S_e_O_task_slot),
        .I_task_base(S_external_task_valid ? 21'd0 : S_e_O_task_base),
        .I_task_y(S_external_task_valid ? 9'd123 : S_e_O_task_y),
        .I_task_bank(S_external_task_valid ? S_external_bank : S_e_O_task_bank),
        .I_task_token(S_external_task_valid ? 32'd11 : S_e_O_task_token),
        .I_task_generation(S_external_task_valid ? 32'd101 : S_e_O_task_generation),
        .I_task_epoch(S_external_task_valid ? 32'd99 : S_e_O_task_epoch),
        .I_task_deadline(S_external_task_valid ? 32'h87654321 : S_e_O_task_deadline),
        .I_task_tag(S_external_task_valid ? 16'hbeef : S_e_O_task_tag),
        .O_line_valid(S_r_O_line_valid),
        .I_line_ready(S_r_O_line_epoch==32'd99 ? S_external_line_ready : (S_e_O_line_ready && S_line_gate)),
        .O_line_error(S_r_O_line_error),
        .O_line_memory_error(S_r_O_line_memory_error),
        .O_line_slot(S_r_O_line_slot),
        .O_line_base(S_r_O_line_base),
        .O_line_y(S_r_O_line_y),
        .O_line_bank(S_r_O_line_bank),
        .O_line_token(S_r_O_line_token),
        .O_line_generation(S_r_O_line_generation),
        .O_line_epoch(S_r_O_line_epoch),
        .O_line_deadline(S_r_O_line_deadline),
        .O_line_tag(S_r_O_line_tag),
        .O_line_accepted(S_r_O_line_accepted),
        .O_line_retired(S_r_O_line_retired),
        .I_read_valid(S_e_O_read_valid),
        .O_read_ready(S_r_O_read_ready),
        .I_read_bank(S_e_O_read_bank),
        .I_read_x(S_e_O_read_x),
        .O_pixel_valid(S_r_O_pixel_valid),
        .O_rgba(S_r_O_rgba),
        .O_pixel_bank(S_r_O_pixel_bank),
        .O_pixel_x(S_r_O_pixel_x),
        .O_pixel_token(S_r_O_pixel_token),
        .O_pixel_generation(S_r_O_pixel_generation),
        .O_pixel_epoch(S_r_O_pixel_epoch),
        .O_pixel_tag(S_r_O_pixel_tag),
        .I_release_valid(S_e_O_release_valid & S_release_gate),
        .O_release_ready(S_r_O_release_ready),
        .I_release_bank(S_e_O_release_bank),
        .I_release_token(S_e_O_release_token),
        .I_release_generation(S_e_O_release_generation),
        .I_release_epoch(S_e_O_release_epoch),
        .I_release_tag(S_e_O_release_tag),
        .O_bank_valid(S_r_O_bank_valid),
        .O_bank_reserved(S_r_O_bank_reserved),
        .O_bank_slots(S_r_O_bank_slots),
        .O_bank_rows(S_r_O_bank_rows),
        .O_bank_tokens(S_r_O_bank_tokens),
        .O_bank_generations(S_r_O_bank_generations),
        .O_bank_epochs(S_r_O_bank_epochs),
        .O_bank_tags(S_r_O_bank_tags),
        .I_retire_request(S_r_I_retire_request),
        .O_retire_ack(S_r_O_retire_ack),
        .O_host_retired(S_r_O_host_retired),
        .O_host_busy(S_r_O_host_busy),
        .O_host_tag_exhausted(S_r_O_host_tag_exhausted),
        .O_release_discarded(S_r_O_release_discarded),
        .O_event_discarded(S_r_O_event_discarded),
        .O_response_discarded(S_r_O_response_discarded),
        .O_mem_valid(S_r_O_mem_valid),
        .I_mem_ready(S_r_I_mem_ready),
        .O_mem_addr(S_r_O_mem_addr),
        .O_mem_tag(S_r_O_mem_tag),
        .O_mem_token(S_r_O_mem_token),
        .O_mem_generation(S_r_O_mem_generation),
        .O_mem_deadline(S_r_O_mem_deadline),
        .I_mem_valid(S_r_I_mem_valid),
        .O_mem_ready(S_r_O_mem_ready),
        .I_mem_data(S_r_I_mem_data),
        .I_mem_tag(S_r_I_mem_tag),
        .I_mem_token(S_r_I_mem_token),
        .I_mem_generation(S_r_I_mem_generation),
        .I_mem_error(S_r_I_mem_error),
        .I_task_source(S_external_task_valid ? 1'b0 : S_e_O_task_source),
        .O_line_source(S_r_O_line_source)
    );
    transition_plan u_plan (
        .I_clk(S_video_clk),
        .I_reset(S_video_reset),
        .I_start_valid(S_p_I_start_valid),
        .O_start_ready(S_p_O_start_ready),
        .I_effect(S_p_I_effect),
        .I_progress(S_p_I_progress),
        .I_epoch(S_p_I_epoch),
        .I_tag(S_p_I_tag),
        .O_done_valid(S_p_O_done_valid),
        .I_done_ready(S_arm && S_e_O_config_ready),
        .O_error(S_p_O_error),
        .O_effect(S_p_O_effect),
        .O_progress(S_p_O_progress),
        .O_epoch(S_p_O_epoch),
        .O_tag(S_p_O_tag),
        .O_dx(S_p_O_dx),
        .O_left(S_p_O_left),
        .O_dy(S_p_O_dy),
        .O_top(S_p_O_top),
        .O_blind_count(S_p_O_blind_count),
        .O_mosaic_count(S_p_O_mosaic_count),
        .O_wipe_threshold(S_p_O_wipe_threshold),
        .O_step_x(S_p_O_step_x),
        .O_step_y(S_p_O_step_y)
    );
    integer S_case=0,S_mode=0,S_pixels=0,S_faults=0,S_repeats=0;
    reg S_check_pixels=1;
    task fail;
        input [767:0] message;
        begin $display("FAIL: scanout_engine case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #1000000000; fail("watchdog timeout"); end
    function [23:0] color;
        input integer source,x,y;
        reg [7:0] r,g,b;
        begin r=x*3+y*7+source*41; g=x*11+y*5+source*83; b=x^y^(source*113); color={r,g,b}; end
    endfunction
    function [31:0] memory_word;
        input integer source,address;
        integer offset;
        begin offset=address-(source==0 ? 0 : 307200); memory_word={color(source,offset%640,offset/640),8'hff}; end
    endfunction
    wire [20:0] S_addr_a=S_r_O_mem_addr[20:0],S_addr_b=S_r_O_mem_addr[41:21];
    assign S_r_I_mem_ready={S_mem_enable && !(S_delay_row7 && (S_addr_b-307200)/640==7),S_mem_enable};
    assign S_r_I_mem_valid=S_r_O_mem_valid & S_r_I_mem_ready;
    assign S_r_I_mem_tag=S_r_O_mem_tag;
    assign S_r_I_mem_token=S_r_O_mem_token;
    assign S_r_I_mem_generation=S_r_O_mem_generation;
    assign S_r_I_mem_data={memory_word(1,S_addr_b),memory_word(0,S_addr_a)};
    assign S_r_I_mem_error={S_inject_memory && S_addr_b==307200+3*640+5 ? 4'd9 : 4'd0,4'd0};
    assign S_bad_pixel=S_inject_pixel && S_r_O_pixel_valid[0] && S_r_O_pixel_x[9:0]==101 &&
        S_r_O_bank_rows[S_r_O_pixel_bank[0]*9+:9]==5;

    integer G_h=0,G_v=0,G_effect=0,G_progress=0,G_from=0,G_dx,G_dy,G_left,G_top;
    reg G_configured=0;
    reg [31:0] G_epoch=0;
    reg [15:0] G_tag=0;
    integer G_x,G_y,G_row,G_ax,G_ay,G_bx,G_by,G_weight,G_local,G_rank,G_c,G_sum;
    reg G_de,G_a,G_b,G_repeat,G_fault;
    reg [63:0] G_step,G_scaled;
    reg [23:0] G_argb,G_brgb,G_rgb;
    task golden;
        input integer x,y;
        begin
            G_a=0; G_b=0; G_ax=x; G_ay=y; G_bx=x; G_by=y; G_weight=0;
            if(G_progress==0) G_a=1;
            else if(G_progress==65536) begin G_b=1; G_weight=65536; end
            else case(G_effect)
                0:begin G_a=1; G_b=1; G_weight=G_progress; end
                1,2:if(x>=640-G_dx) begin G_b=1; G_bx=x-(640-G_dx); G_weight=65536; end
                    else begin G_a=1; if(G_effect==2) G_ax=x+G_dx; end
                3:begin G_scaled=64'd614400*G_progress+32768; G_b=x*480+y*640<G_scaled/65536; G_a=!G_b; G_weight=G_b ? 65536 : 0; end
                4:begin G_local=(x/32)%2==0 ? x%32 : 31-x%32; G_b=G_local<(32*G_progress+32768)/65536; G_a=!G_b; G_weight=G_b ? 65536 : 0; end
                5:begin G_rank=(((x/8)*37)^((y/8)*73))&255; G_b=G_rank<(256*G_progress+32768)/65536; G_a=!G_b; G_weight=G_b ? 65536 : 0; end
                6:begin
                    G_b=G_dx>0 && G_dy>0 && x>=G_left && x<G_left+G_dx && y>=G_top && y<G_top+G_dy;
                    G_a=!G_b; G_weight=G_b ? 65536 : 0;
                    if(G_b) begin
                        G_step=64'd41943040/G_dx; G_bx=((x-G_left)*G_step+G_step/2)/65536;
                        G_step=64'd31457280/G_dy; G_by=((y-G_top)*G_step+G_step/2)/65536;
                        if(G_bx>639) G_bx=639; if(G_by>479) G_by=479;
                    end
                end
            endcase
            G_argb=G_a ? color(G_from,G_ax,G_ay) : 24'd0;
            G_brgb=G_b ? color(1-G_from,G_bx,G_by) : 24'd0;
            G_rgb=0;
            for(G_c=0;G_c<3;G_c=G_c+1) begin
                G_sum=(G_argb[G_c*8+:8]*(65536-G_weight)+G_brgb[G_c*8+:8]*G_weight+32768)/65536;
                if(G_sum>255) G_sum=255; G_rgb[G_c*8+:8]=G_sum;
            end
        end
    endtask
    reg [111:0] S_expected[0:3],S_current,S_actual;
    integer S_filled=0,S_i;
    reg S_task_held=0;
    reg [178:0] S_task_saved,S_task_now;
    reg [1:0] S_release_held=0;
    reg [112:0] S_release_saved[0:1];
    reg [112:0] S_release_now;
    always @(posedge S_video_clk) begin
        if(S_video_reset) begin
            G_h=0; G_v=0; G_configured=0; G_epoch=0; G_tag=0; S_filled=0;
            S_task_held=0; S_release_held=0;
        end else begin
            if(S_p_O_done_valid && S_p_O_error==0 && S_arm && S_e_O_config_ready &&
                S_p_O_epoch!=0 && S_p_O_epoch>=G_epoch) begin
                G_configured=1; G_effect=S_p_O_effect; G_progress=S_p_O_progress; G_from=S_e_I_from_source;
                G_epoch=S_p_O_epoch; G_tag=S_p_O_tag;
                G_dx=(640*G_progress+32768)/65536; G_dy=(480*G_progress+32768)/65536;
                G_left=(640-G_dx)/2; G_top=(480-G_dy)/2;
            end
            if(S_e_I_stop_request) G_configured=0;
            G_de=G_h>=144 && G_h<784 && G_v>=35 && G_v<515;
            G_x=G_de ? G_h-144 : 0; G_y=G_de ? G_v-35 : 0; G_row=G_y;
            G_repeat=G_de && ((S_mode==1 && G_y==7) || (S_mode==2 && G_y==3));
            if(G_repeat) G_row=S_mode==1 ? 6 : 2;
            G_fault=G_de && S_mode==3 && G_x==101 && G_y==5;
            G_rgb=0;
            if(G_de && G_configured) begin golden(G_x,G_row); if(G_fault) G_rgb=0; end
            S_current={G_de && G_configured,G_h>=96,G_v>=2,G_de,G_h==0 && G_v==0,G_h==0,
                G_x[15:0],G_y[15:0],G_rgb,G_epoch,G_tag,G_repeat,G_fault};
            S_task_now={S_e_O_task_source,S_e_O_task_slot,S_e_O_task_base,S_e_O_task_y,S_e_O_task_bank,
                S_e_O_task_token,S_e_O_task_generation,S_e_O_task_epoch,S_e_O_task_deadline,S_e_O_task_tag};
            if(S_task_held && (!S_e_O_task_valid || S_task_now!==S_task_saved)) fail("presented task changed before handshake");
            S_task_held=S_e_O_task_valid && !(S_r_O_task_ready && S_task_gate && !S_external_task_valid); S_task_saved=S_task_now;
            for(S_i=0;S_i<2;S_i=S_i+1) begin
                if(S_source_owner_retired[S_i] && (S_e_O_owned_banks[S_i*2+:2]!=0 ||
                    (S_e_O_task_valid && S_e_O_task_source==S_i) || S_e_O_release_valid[S_i]))
                    fail("local owner proof ignored visible obligation");
                if(S_source_pipeline_retired[S_i] && (S_e_O_read_valid[S_i] || S_r_O_pixel_valid[S_i]))
                    fail("local pipeline proof ignored real reader pixels");
                S_release_now={S_e_O_release_bank[S_i],S_e_O_release_token[S_i*32+:32],S_e_O_release_generation[S_i*32+:32],
                    S_e_O_release_epoch[S_i*32+:32],S_e_O_release_tag[S_i*16+:16]};
                if(S_release_held[S_i] && (!S_e_O_release_valid[S_i] || S_release_now!==S_release_saved[S_i])) fail("release changed before handshake");
                S_release_held[S_i]=S_e_O_release_valid[S_i] && !(S_r_O_release_ready[S_i] && S_release_gate[S_i]);
                S_release_saved[S_i]=S_release_now;
            end
            if(G_h==799) begin G_h=0; G_v=G_v==524 ? 0 : G_v+1; end else G_h=G_h+1;
            #1;
            S_actual={S_e_O_valid,S_e_O_hsync,S_e_O_vsync,S_e_O_de,S_e_O_frame_mark,S_e_O_line_start,
                S_e_O_x,S_e_O_y,S_e_O_rgb,S_e_O_epoch,S_e_O_tag,S_e_O_repeated,S_e_O_pixel_fault};
            if(S_filled==4) begin
                if(S_actual[111:74]!==S_expected[3][111:74]) fail("five-stage raster/control/valid latency");
                if(S_check_pixels && S_actual[73:50]!==S_expected[3][73:50]) fail("real reader RGB vs independent coordinates/mix");
                if(S_actual[111]) begin
                    if(S_actual[49:2]!==S_expected[3][49:2]) fail("epoch/tag alignment");
                    if(S_check_pixels && S_actual[1:0]!==S_expected[3][1:0]) fail("repeated/fault alignment");
                    S_pixels=S_pixels+1;
                    if(S_e_O_repeated) S_repeats=S_repeats+1;
                    if(S_e_O_pixel_fault) S_faults=S_faults+1;
                end
            end else S_filled=S_filled+1;
            S_expected[3]=S_expected[2]; S_expected[2]=S_expected[1]; S_expected[1]=S_expected[0]; S_expected[0]=S_current;
        end
    end
    task reset_all;
        begin
            S_case=S_case+1;
            @(negedge S_video_clk); S_async_reset=1; S_arm=0; S_p_I_start_valid=0; S_e_I_stop_request=0;
            S_task_gate=1; S_line_gate=1; S_release_gate=3; S_mem_enable=1; S_wrong_line=0;
            S_delay_row7=0; S_inject_memory=0; S_inject_pixel=0; S_mode=0; S_check_pixels=1;
            S_external_task_valid=0; S_external_line_ready=0; S_deadline_enable=1;
            S_guard_reserve=0; S_guard_retire=0;
            S_e_I_source_mask=3; S_e_I_from_source=0; S_e_I_slots={3'd1,3'd0};
            S_e_I_tokens={32'd22,32'd11}; S_e_I_generations={32'd202,32'd101};
            S_r_I_lease_valid=3; S_r_I_lease_slot=S_e_I_slots; S_r_I_lease_token=S_e_I_tokens; S_r_I_lease_generation=S_e_I_generations;
            #1;
            if(S_source_owner_retired!==0 || S_source_pipeline_retired!==0 || S_source_in_use!==0)
                fail("reset published local retirement proof");
            repeat(6) @(negedge S_video_clk); S_async_reset=0;
            wait(!S_video_reset); repeat(5) @(negedge S_video_clk);
            S_pixels=0; S_faults=0; S_repeats=0;
        end
    endtask
    task configure;
        input integer effect,progress,epoch,from_source;
        begin
            S_case=S_case+1; S_arm=0;
            @(negedge S_video_clk); S_p_I_effect=effect; S_p_I_progress=progress;
            S_p_I_epoch=epoch; S_p_I_tag=16'h4500+epoch; S_p_I_start_valid=1; S_e_I_from_source=from_source;
            @(posedge S_video_clk); while(!S_p_O_start_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_p_I_start_valid=0;
            wait(S_p_O_done_valid); if(S_p_O_error!==0) fail("legal plan rejected");
            @(negedge S_video_clk); S_arm=1;
            wait(S_e_O_config_applied); #1;
            if(S_e_O_config_error || S_e_O_active_epoch!==epoch) fail("frame-window install");
            @(negedge S_video_clk); S_arm=0;
        end
    endtask
    task finish_frame;
        begin
            wait(S_e_O_valid && S_e_O_x==639 && S_e_O_y==479);
            repeat(10) @(negedge S_video_clk);
        end
    endtask
    task raster_at;
        input integer h,v;
        begin @(negedge S_video_clk); while(G_h!=h || G_v!=v) @(negedge S_video_clk); end
    endtask
    integer effect;
    reg [31:0] old_und;
    initial begin
        reset_all;
        // All seven effects through actual dual-clock reader RAM, both role maps.
        for(effect=0;effect<7;effect=effect+1) begin
            old_und=S_e_O_und_count; configure(effect,32768,effect+1,effect%2); finish_frame;
            if(S_e_O_und_count!==old_und || S_e_O_contract_fault || S_e_O_line_error_count!=0)
                fail("normal memory endpoint missed line deadline or identity");
        end
        if(S_pixels<7*307200) fail("normal seven complete frames not checked");
        // A rejected backward epoch cannot change the old mapping or its identity.
        S_case=S_case+1;
        @(negedge S_video_clk); S_p_I_effect=0; S_p_I_progress=32768; S_p_I_epoch=1; S_p_I_tag=1; S_p_I_start_valid=1;
        @(negedge S_video_clk); S_p_I_start_valid=0;
        wait(S_p_O_done_valid); @(negedge S_video_clk); S_arm=1;
        wait(S_e_O_config_error); #1;
        if(S_e_O_config_applied || S_e_O_active_epoch!==7) fail("rejected epoch overwrote active configuration");
        @(negedge S_video_clk); S_arm=0; finish_frame;
        // An externally prepared, unowned future-epoch bank survives local stop.
        S_case=S_case+1;
        @(negedge S_video_clk); S_external_bank=S_r_O_bank_reserved[0] ? 1'b1 : 1'b0;
        if(S_r_O_bank_reserved[S_external_bank] || S_e_O_owned_banks[S_external_bank]) fail("no free candidate bank");
        S_external_task_valid=1;
        @(posedge S_video_clk); while(!S_r_O_task_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_external_task_valid=0;
        wait(S_r_O_line_valid && S_r_O_line_epoch==99);
        if(S_r_O_line_error!=0) fail("external candidate fill");
        @(negedge S_video_clk); S_external_line_ready=1;
        @(negedge S_video_clk); S_external_line_ready=0; S_e_I_stop_request=1; S_e_I_retire_epoch=7;
        wait(S_e_O_stop_ack); #1;
        if(S_e_O_owned_banks!==0 || !S_e_O_epoch_retired || !S_r_O_bank_valid[S_external_bank] ||
            S_r_O_bank_epochs[S_external_bank*32+:32]!==99) fail("local retirement destroyed foreign candidate bank");
        // Missing deadline authorization prevents prefetch while the raster runs.
        reset_all; S_deadline_enable=0;
        configure(0,32768,1,0);
        raster_at(0,34);
        if(S_e_O_task_valid || S_e_O_owned_banks!=0) fail("task issued without deadline authorization");
        S_deadline_enable=1; finish_frame;
        if(S_e_O_und_count!=0 || S_e_O_contract_fault) fail("deadline authorization did not recover before first line");
        // One source misses row 7. Late completion cannot change that row halfway.
        reset_all; S_mode=1; S_delay_row7=1;
        configure(0,32768,1,1);
        raster_at(200,35+7); S_delay_row7=0;
        finish_frame;
        if(S_e_O_und_count!==1 || S_repeats!=640 || S_faults!=0 || S_e_O_contract_fault)
            fail("whole-line repeat and next-line recovery");
        // Actual reader error cannot publish a half-filled line.
        reset_all; S_mode=2; S_inject_memory=1;
        configure(0,32768,1,0); finish_frame;
        if(S_e_O_und_count!==1 || S_repeats!=640 || S_e_O_line_error_count!==1 ||
            S_e_O_last_line_error!==3 || S_e_O_last_memory_error!==9 || S_faults!=0)
            fail("memory error retirement/whole-row fallback");
        // Unexpected pixel identity is diagnosed, and both colors become black.
        reset_all; S_mode=3; S_inject_pixel=1;
        configure(0,32768,1,0); finish_frame;
        if(S_faults!=1 || !S_e_O_contract_fault || S_e_O_und_count!=0) fail("pixel identity fault diagnostic");
        // Stop cannot withdraw a presented task or manufacture a real retirement.
        reset_all; S_check_pixels=0;
        configure(0,32768,1,0);
        wait(S_e_O_task_valid); @(negedge S_video_clk); S_task_gate=0; S_mem_enable=0; S_e_I_stop_request=1; S_e_I_retire_epoch=1;
        repeat(8) begin @(negedge S_video_clk); if(S_e_O_stop_ack || !S_e_O_task_valid) fail("stop dropped held task"); end
        S_task_gate=1;
        wait(|S_r_O_mem_valid);
        @(negedge S_host_clk); S_host_run=0;
        repeat(12) begin @(negedge S_video_clk); if(S_e_O_stop_ack) fail("host stop invented completion"); end
        S_host_run=1; S_wrong_line=1; S_mem_enable=1; S_release_gate=0;
        @(negedge S_video_clk); S_video_run=0;
        repeat(40) @(negedge S_host_clk);
        if(S_e_O_stop_ack) fail("video stop invented completion");
        S_video_run=1;
        wait(S_r_O_line_valid);
        repeat(8) begin @(negedge S_video_clk); if(S_e_O_line_ready || S_e_O_stop_ack) fail("wrong line tag retired task"); end
        S_wrong_line=0;
        wait(|S_e_O_release_valid);
        repeat(8) begin @(negedge S_video_clk); if(S_e_O_stop_ack) fail("release backpressure ignored"); end
        S_release_gate=3;
        wait(S_e_O_stop_ack); #1;
        if(S_e_O_owned_banks!==0 || !S_e_O_epoch_retired) fail("stop ack retained bank/epoch reference");
        @(negedge S_video_clk); S_e_I_stop_request=0;
        wait(!S_e_O_stop_ack); S_check_pixels=1;
        configure(6,65536,2,1); finish_frame;
        if(S_e_O_contract_fault || S_faults!=0) fail("scanout not reusable after real stop");
        // Actual local evidence: remove source0, retain source1 and backpressure
        // source0's real bank release across a frame. Reader stop must wait.
        reset_all; configure(0,32768,1,0);
        raster_at(200,38);
        if(S_source_in_use!==3 || S_source_pipeline_retired!==0)
            fail("active two-source references not visible");
        @(negedge S_host_clk); S_guard_reserve=1;
        raster_at(100,520);
        if(S_guard_idle!=0 || S_guard_block!=0 || S_guard_stop!=0)
            fail("guard reserved active scanout source");
        if(S_e_O_owned_banks[1:0]==0) fail("missing old source bank for retirement test");
        S_release_gate=2; S_e_I_source_mask=2;
        configure(0,0,2,1);
        wait(S_e_O_release_valid[0]);
        if(S_source_owner_retired[0] || !S_source_in_use[0])
            fail("source mask removal hid real release obligation");
        wait(S_e_O_valid && S_e_O_x==100 && S_e_O_y==3); #1;
        if(!S_source_pipeline_retired[0] || S_source_pipeline_retired[1] ||
            S_source_owner_retired[0] || S_guard_stop!=0)
            fail("source proof not isolated from opposite scanout");
        raster_at(0,0); repeat(4) @(negedge S_video_clk);
        if(S_guard_idle!=0 || S_guard_block!=0 || S_guard_stop!=0)
            fail("frame boundary bypassed held bank release");
        S_release_gate=3;
        wait(!S_source_in_use[0]);
        if(!S_source_owner_retired[0] || !S_source_pipeline_retired[0])
            fail("source idle without true local proof");
        wait(S_guard_block[0]); wait(S_guard_idle[0]);
        @(negedge S_host_clk); S_guard_retire=1;
        wait(S_guard_ack[0]);
        if(!S_r_O_retire_ack[0] || S_r_O_retire_ack[1] || S_guard_stop!==1 ||
            S_guard_host_fault!=0 || S_guard_video_fault!=0)
            fail("guard did not use real isolated reader retirement");
        // Offer a legal configuration using the reserved source. It must remain
        // pending without manufacturing in_use or overwriting the old active.
        @(negedge S_video_clk); S_e_I_source_mask=3;
        S_p_I_effect=0; S_p_I_progress=32768; S_p_I_epoch=3; S_p_I_tag=16'h4503; S_p_I_start_valid=1;
        @(posedge S_video_clk); while(!S_p_O_start_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_p_I_start_valid=0;
        wait(S_p_O_done_valid); @(negedge S_video_clk); S_arm=1;
        raster_at(0,0); repeat(8) @(negedge S_video_clk);
        if(S_e_O_config_ready || S_e_O_config_applied || S_e_O_active_epoch!==2 ||
            S_source_in_use[0] || S_guard_host_fault!=0 || S_guard_video_fault!=0)
            fail("blocked config escaped source reservation");
        wait(S_e_O_valid && S_e_O_x==100 && S_e_O_y==3); #1;
        if(S_source_pipeline_retired[1] || !S_source_pipeline_retired[0] || S_faults!=0)
            fail("reserved source disrupted opposite real pixels");
        @(negedge S_host_clk); S_guard_retire=0;
        wait(!S_guard_ack[0]);
        if(S_r_O_retire_ack[0]) fail("host ack cleared before real reader ack");
        @(negedge S_host_clk); S_guard_reserve=0;
        wait(!S_guard_busy[0]); wait(S_e_O_config_applied);
        @(negedge S_video_clk); S_arm=0;
        finish_frame;
        if(S_e_O_active_epoch!==3 || S_e_O_contract_fault || S_faults!=0 ||
            S_guard_host_fault!=0 || S_guard_video_fault!=0)
            fail("source reuse after real guard handshake");
        // Unblocked legal pending config counts before the install edge, so a
        // simultaneous reserve reaching the next frame cannot win the source.
        reset_all; S_e_I_source_mask=1;
        @(negedge S_host_clk); S_guard_reserve=1;
        configure(0,0,1,0);
        repeat(8) @(negedge S_video_clk);
        if(!S_source_in_use[0] || S_guard_block!=0 || S_guard_idle!=0 || S_guard_video_fault!=0)
            fail("pending install lost frame-boundary reservation race");
        raster_at(200,38);
        @(negedge S_video_clk); S_video_run=0;
        repeat(32) @(negedge S_host_clk);
        if(S_source_pipeline_retired[0] || !S_source_in_use[0] || S_guard_block!=0 || S_guard_idle!=0)
            fail("stopped scanout invented local retirement proof");
        S_video_run=1;
        finish_frame;
        if(S_e_O_contract_fault || S_faults!=0) fail("pending race corrupted pixels");
        S_test_pass=1; $display("PASS: scanout real reader/seven effects/source proofs/guard integration/true retirement"); $finish;
    end
endmodule
