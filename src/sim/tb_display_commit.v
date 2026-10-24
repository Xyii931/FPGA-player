`timescale 1ns/1ps
module tb_display_commit;
    reg S_I_host_clk=0;
    reg S_I_video_clk=0;
    reg S_I_async_reset=0;
    reg S_I_submit_valid=0;
    wire S_O_submit_ready;
    reg [15:0] S_I_tag=0;
    reg S_I_abort=0;
    wire [31:0] S_O_next_epoch;
    wire S_O_busy;
    wire S_O_done_valid;
    reg S_I_done_ready=0;
    wire [3:0] S_O_error;
    wire [3:0] S_O_prepare_error;
    wire [3:0] S_O_retire_error;
    wire [15:0] S_O_tag;
    wire [31:0] S_O_epoch;
    wire [31:0] S_O_previous_epoch;
    wire S_O_applied;
    wire S_O_retired;
    wire S_O_quarantined;
    wire S_O_host_response_discarded;
    wire S_O_pending_valid;
    wire [15:0] S_O_pending_tag;
    wire [31:0] S_O_pending_epoch;
    wire S_O_prepare_valid;
    reg S_I_prepare_ready=0;
    wire S_O_prepare_abort;
    reg S_I_prepare_done_valid=0;
    wire S_O_prepare_done_ready;
    reg [15:0] S_I_prepare_done_tag=0;
    reg [31:0] S_I_prepare_done_epoch=0;
    reg [3:0] S_I_prepare_done_error=0;
    reg S_I_frame_start=0;
    reg S_I_allow_apply=0;
    reg S_I_video_abort=0;
    wire S_O_active_valid;
    wire [15:0] S_O_active_tag;
    wire [31:0] S_O_active_epoch;
    wire S_O_applied_pulse;
    wire S_O_retire_valid;
    reg S_I_retire_ready=0;
    wire [15:0] S_O_retire_tag;
    wire [31:0] S_O_retire_epoch;
    wire S_O_retire_old;
    reg S_I_retire_done_valid=0;
    wire S_O_retire_done_ready;
    reg [15:0] S_I_retire_done_tag=0;
    reg [31:0] S_I_retire_done_epoch=0;
    reg [3:0] S_I_retire_done_error=0;
    wire S_O_video_quarantined;
    wire S_O_video_response_discarded;
    reg [1:0] S_I_source_mask=0;
    wire [1:0] S_O_pending_source_mask;
    wire [1:0] S_O_active_source_mask;
    wire [1:0] S_O_retire_source_mask;
    reg S_I_from_source=0;
    wire S_O_pending_from_source;
    wire S_O_active_from_source;
    wire S_O_retire_from_source;
    reg [5:0] S_I_slots=0;
    wire [5:0] S_O_pending_slots;
    wire [5:0] S_O_active_slots;
    wire [5:0] S_O_retire_slots;
    reg [63:0] S_I_tokens=0;
    wire [63:0] S_O_pending_tokens;
    wire [63:0] S_O_active_tokens;
    wire [63:0] S_O_retire_tokens;
    reg [63:0] S_I_generations=0;
    wire [63:0] S_O_pending_generations;
    wire [63:0] S_O_active_generations;
    wire [63:0] S_O_retire_generations;
    reg [1:0] S_I_resident=0;
    wire [1:0] S_O_pending_resident;
    wire [1:0] S_O_active_resident;
    wire [1:0] S_O_retire_resident;
    reg [2:0] S_I_effect=0;
    wire [2:0] S_O_pending_effect;
    wire [2:0] S_O_active_effect;
    wire [2:0] S_O_retire_effect;
    reg [15:0] S_I_duration_frames=0;
    wire [15:0] S_O_pending_duration_frames;
    wire [15:0] S_O_active_duration_frames;
    wire [15:0] S_O_retire_duration_frames;
    reg [16:0] S_I_progress=0;
    wire [16:0] S_O_pending_progress;
    wire [16:0] S_O_active_progress;
    wire [16:0] S_O_retire_progress;
    reg [3:0] S_I_brightness=0;
    wire [3:0] S_O_pending_brightness;
    wire [3:0] S_O_active_brightness;
    wire [3:0] S_O_retire_brightness;
    reg [3:0] S_I_contrast=0;
    wire [3:0] S_O_pending_contrast;
    wire [3:0] S_O_active_contrast;
    wire [3:0] S_O_retire_contrast;
    reg [4:0] S_I_saturation=0;
    wire [4:0] S_O_pending_saturation;
    wire [4:0] S_O_active_saturation;
    wire [4:0] S_O_retire_saturation;
    reg [2:0] S_I_layout=0;
    wire [2:0] S_O_pending_layout;
    wire [2:0] S_O_active_layout;
    wire [2:0] S_O_retire_layout;
    reg [1:0] S_I_rotation=0;
    wire [1:0] S_O_pending_rotation;
    wire [1:0] S_O_active_rotation;
    wire [1:0] S_O_retire_rotation;
    reg S_I_alert=0;
    wire S_O_pending_alert;
    wire S_O_active_alert;
    wire S_O_retire_alert;
    reg S_I_audio_required=0;
    wire S_O_pending_audio_required;
    wire S_O_active_audio_required;
    wire S_O_retire_audio_required;
    reg [17:0] S_I_first_y=0;
    wire [17:0] S_O_pending_first_y;
    wire [17:0] S_O_active_first_y;
    wire [17:0] S_O_retire_first_y;
    reg [1:0] S_I_first_bank=0;
    wire [1:0] S_O_pending_first_bank;
    wire [1:0] S_O_active_first_bank;
    wire [1:0] S_O_retire_first_bank;
    reg [31:0] S_I_first_tag=0;
    wire [31:0] S_O_pending_first_tag;
    wire [31:0] S_O_active_first_tag;
    wire [31:0] S_O_retire_first_tag;
    reg [1:0] S_I_lease_valid=0;
    reg [5:0] S_I_lease_slots=0;
    reg [63:0] S_I_lease_tokens=0;
    reg [63:0] S_I_lease_generations=0;
    reg [1:0] S_I_lease_resident=0;
    wire [3:0] S_I_bank_valid;
    wire [11:0] S_I_bank_slots;
    wire [35:0] S_I_bank_rows;
    wire [127:0] S_I_bank_tokens;
    wire [127:0] S_I_bank_generations;
    wire [127:0] S_I_bank_epochs;
    wire [63:0] S_I_bank_tags;
    reg S_I_audio_ready=0;
    reg [31:0] S_I_audio_epoch=0;
    display_commit u_dut (
        .O_apply_valid(),
        .I_host_clk(S_I_host_clk),
        .I_video_clk(S_I_video_clk),
        .I_async_reset(S_I_async_reset),
        .I_submit_valid(S_I_submit_valid),
        .O_submit_ready(S_O_submit_ready),
        .I_tag(S_I_tag),
        .I_abort(S_I_abort),
        .O_next_epoch(S_O_next_epoch),
        .O_busy(S_O_busy),
        .O_done_valid(S_O_done_valid),
        .I_done_ready(S_I_done_ready),
        .O_error(S_O_error),
        .O_prepare_error(S_O_prepare_error),
        .O_retire_error(S_O_retire_error),
        .O_tag(S_O_tag),
        .O_epoch(S_O_epoch),
        .O_previous_epoch(S_O_previous_epoch),
        .O_applied(S_O_applied),
        .O_retired(S_O_retired),
        .O_quarantined(S_O_quarantined),
        .O_host_response_discarded(S_O_host_response_discarded),
        .O_pending_valid(S_O_pending_valid),
        .O_pending_tag(S_O_pending_tag),
        .O_pending_epoch(S_O_pending_epoch),
        .O_prepare_valid(S_O_prepare_valid),
        .I_prepare_ready(S_I_prepare_ready),
        .O_prepare_abort(S_O_prepare_abort),
        .I_prepare_done_valid(S_I_prepare_done_valid),
        .O_prepare_done_ready(S_O_prepare_done_ready),
        .I_prepare_done_tag(S_I_prepare_done_tag),
        .I_prepare_done_epoch(S_I_prepare_done_epoch),
        .I_prepare_done_error(S_I_prepare_done_error),
        .I_frame_start(S_I_frame_start),
        .I_allow_apply(S_I_allow_apply),
        .I_video_abort(S_I_video_abort),
        .O_active_valid(S_O_active_valid),
        .O_active_tag(S_O_active_tag),
        .O_active_epoch(S_O_active_epoch),
        .O_applied_pulse(S_O_applied_pulse),
        .O_retire_valid(S_O_retire_valid),
        .I_retire_ready(S_I_retire_ready),
        .O_retire_tag(S_O_retire_tag),
        .O_retire_epoch(S_O_retire_epoch),
        .O_retire_old(S_O_retire_old),
        .I_retire_done_valid(S_I_retire_done_valid),
        .O_retire_done_ready(S_O_retire_done_ready),
        .I_retire_done_tag(S_I_retire_done_tag),
        .I_retire_done_epoch(S_I_retire_done_epoch),
        .I_retire_done_error(S_I_retire_done_error),
        .O_video_quarantined(S_O_video_quarantined),
        .O_video_response_discarded(S_O_video_response_discarded),
        .I_source_mask(S_I_source_mask),
        .O_pending_source_mask(S_O_pending_source_mask),
        .O_active_source_mask(S_O_active_source_mask),
        .O_retire_source_mask(S_O_retire_source_mask),
        .I_from_source(S_I_from_source),
        .O_pending_from_source(S_O_pending_from_source),
        .O_active_from_source(S_O_active_from_source),
        .O_retire_from_source(S_O_retire_from_source),
        .I_slots(S_I_slots),
        .O_pending_slots(S_O_pending_slots),
        .O_active_slots(S_O_active_slots),
        .O_retire_slots(S_O_retire_slots),
        .I_tokens(S_I_tokens),
        .O_pending_tokens(S_O_pending_tokens),
        .O_active_tokens(S_O_active_tokens),
        .O_retire_tokens(S_O_retire_tokens),
        .I_generations(S_I_generations),
        .O_pending_generations(S_O_pending_generations),
        .O_active_generations(S_O_active_generations),
        .O_retire_generations(S_O_retire_generations),
        .I_resident(S_I_resident),
        .O_pending_resident(S_O_pending_resident),
        .O_active_resident(S_O_active_resident),
        .O_retire_resident(S_O_retire_resident),
        .I_effect(S_I_effect),
        .O_pending_effect(S_O_pending_effect),
        .O_active_effect(S_O_active_effect),
        .O_retire_effect(S_O_retire_effect),
        .I_duration_frames(S_I_duration_frames),
        .O_pending_duration_frames(S_O_pending_duration_frames),
        .O_active_duration_frames(S_O_active_duration_frames),
        .O_retire_duration_frames(S_O_retire_duration_frames),
        .I_progress(S_I_progress),
        .O_pending_progress(S_O_pending_progress),
        .O_active_progress(S_O_active_progress),
        .O_retire_progress(S_O_retire_progress),
        .I_brightness(S_I_brightness),
        .O_pending_brightness(S_O_pending_brightness),
        .O_active_brightness(S_O_active_brightness),
        .O_retire_brightness(S_O_retire_brightness),
        .I_contrast(S_I_contrast),
        .O_pending_contrast(S_O_pending_contrast),
        .O_active_contrast(S_O_active_contrast),
        .O_retire_contrast(S_O_retire_contrast),
        .I_saturation(S_I_saturation),
        .O_pending_saturation(S_O_pending_saturation),
        .O_active_saturation(S_O_active_saturation),
        .O_retire_saturation(S_O_retire_saturation),
        .I_layout(S_I_layout),
        .O_pending_layout(S_O_pending_layout),
        .O_active_layout(S_O_active_layout),
        .O_retire_layout(S_O_retire_layout),
        .I_rotation(S_I_rotation),
        .O_pending_rotation(S_O_pending_rotation),
        .O_active_rotation(S_O_active_rotation),
        .O_retire_rotation(S_O_retire_rotation),
        .I_alert(S_I_alert),
        .O_pending_alert(S_O_pending_alert),
        .O_active_alert(S_O_active_alert),
        .O_retire_alert(S_O_retire_alert),
        .I_audio_required(S_I_audio_required),
        .O_pending_audio_required(S_O_pending_audio_required),
        .O_active_audio_required(S_O_active_audio_required),
        .O_retire_audio_required(S_O_retire_audio_required),
        .I_first_y(S_I_first_y),
        .O_pending_first_y(S_O_pending_first_y),
        .O_active_first_y(S_O_active_first_y),
        .O_retire_first_y(S_O_retire_first_y),
        .I_first_bank(S_I_first_bank),
        .O_pending_first_bank(S_O_pending_first_bank),
        .O_active_first_bank(S_O_active_first_bank),
        .O_retire_first_bank(S_O_retire_first_bank),
        .I_first_tag(S_I_first_tag),
        .O_pending_first_tag(S_O_pending_first_tag),
        .O_active_first_tag(S_O_active_first_tag),
        .O_retire_first_tag(S_O_retire_first_tag),
        .I_lease_valid(S_I_lease_valid),
        .I_lease_slots(S_I_lease_slots),
        .I_lease_tokens(S_I_lease_tokens),
        .I_lease_generations(S_I_lease_generations),
        .I_lease_resident(S_I_lease_resident),
        .I_bank_valid(S_I_bank_valid),
        .I_bank_slots(S_I_bank_slots),
        .I_bank_rows(S_I_bank_rows),
        .I_bank_tokens(S_I_bank_tokens),
        .I_bank_generations(S_I_bank_generations),
        .I_bank_epochs(S_I_bank_epochs),
        .I_bank_tags(S_I_bank_tags),
        .I_audio_ready(S_I_audio_ready),
        .I_audio_epoch(S_I_audio_epoch)
    );
    reg S_test_pass=0,S_host_run=1,S_video_run=1;
    integer S_case=0;
    always #4 if(S_host_run) S_I_host_clk=~S_I_host_clk;
    always #20 if(S_video_run) S_I_video_clk=~S_I_video_clk;
    task fail;
        input [767:0] message;
        begin $display("FAIL: commit case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #20000000; fail("watchdog timeout"); end
    reg S_reader_task_valid=0;
    wire S_reader_task_ready;
    reg [2:0] S_reader_task_slot=0;
    reg [20:0] S_reader_task_base=0;
    reg [8:0] S_reader_task_y=0;
    reg S_reader_task_bank=0;
    reg [31:0] S_reader_task_token=0;
    reg [31:0] S_reader_task_generation=0;
    reg [31:0] S_reader_task_epoch=0;
    reg [31:0] S_reader_task_deadline=0;
    reg [15:0] S_reader_task_tag=0;
    wire S_reader_line_valid;
    reg S_reader_line_ready=0;
    wire [3:0] S_reader_line_error;
    wire [3:0] S_reader_line_memory_error;
    wire [2:0] S_reader_line_slot;
    wire [20:0] S_reader_line_base;
    wire [8:0] S_reader_line_y;
    wire S_reader_line_bank;
    wire [31:0] S_reader_line_token;
    wire [31:0] S_reader_line_generation;
    wire [31:0] S_reader_line_epoch;
    wire [31:0] S_reader_line_deadline;
    wire [15:0] S_reader_line_tag;
    wire [9:0] S_reader_line_accepted;
    wire [9:0] S_reader_line_retired;
    reg [1:0] S_reader_read_valid=0;
    wire [1:0] S_reader_read_ready;
    reg [1:0] S_reader_read_bank=0;
    reg [19:0] S_reader_read_x=0;
    wire [1:0] S_reader_pixel_valid;
    wire [63:0] S_reader_rgba;
    wire [1:0] S_reader_pixel_bank;
    wire [19:0] S_reader_pixel_x;
    wire [63:0] S_reader_pixel_token;
    wire [63:0] S_reader_pixel_generation;
    wire [63:0] S_reader_pixel_epoch;
    wire [31:0] S_reader_pixel_tag;
    reg [1:0] S_reader_release_valid=0;
    wire [1:0] S_reader_release_ready;
    reg [1:0] S_reader_release_bank=0;
    reg [63:0] S_reader_release_token=0;
    reg [63:0] S_reader_release_generation=0;
    reg [63:0] S_reader_release_epoch=0;
    reg [31:0] S_reader_release_tag=0;
    wire [3:0] S_reader_bank_reserved;
    reg [1:0] S_reader_retire_request=0;
    wire [1:0] S_reader_retire_ack;
    wire [1:0] S_reader_host_retired;
    wire [1:0] S_reader_host_busy;
    wire [1:0] S_reader_host_tag_exhausted;
    wire [1:0] S_reader_release_discarded;
    wire [1:0] S_reader_event_discarded;
    wire [1:0] S_reader_response_discarded;
    wire [1:0] S_reply_mem_valid;
    wire [1:0] S_reply_mem_ready;
    wire [41:0] S_reader_mem_addr;
    wire [63:0] S_reply_mem_tag;
    wire [63:0] S_reply_mem_token;
    wire [63:0] S_reply_mem_generation;
    wire [63:0] S_reader_mem_deadline;
    wire [1:0] S_reader_mem_valid;
    wire [1:0] S_reader_mem_ready;
    wire [63:0] S_reply_mem_data;
    wire [63:0] S_reader_mem_tag;
    wire [63:0] S_reader_mem_token;
    wire [63:0] S_reader_mem_generation;
    wire [7:0] S_reply_mem_error;
    reg S_reader_task_source=0;
    wire S_reader_line_source;
    fb_reader u_reader (
        .I_host_clk(S_I_host_clk),
        .I_video_clk(S_I_video_clk),
        .I_async_reset(S_I_async_reset),
        .I_lease_valid(S_I_lease_valid),
        .I_lease_slot(S_I_lease_slots),
        .I_lease_token(S_I_lease_tokens),
        .I_lease_generation(S_I_lease_generations),
        .I_task_valid(S_reader_task_valid),
        .O_task_ready(S_reader_task_ready),
        .I_task_slot(S_reader_task_slot),
        .I_task_base(S_reader_task_base),
        .I_task_y(S_reader_task_y),
        .I_task_bank(S_reader_task_bank),
        .I_task_token(S_reader_task_token),
        .I_task_generation(S_reader_task_generation),
        .I_task_epoch(S_reader_task_epoch),
        .I_task_deadline(S_reader_task_deadline),
        .I_task_tag(S_reader_task_tag),
        .O_line_valid(S_reader_line_valid),
        .I_line_ready(S_reader_line_ready),
        .O_line_error(S_reader_line_error),
        .O_line_memory_error(S_reader_line_memory_error),
        .O_line_slot(S_reader_line_slot),
        .O_line_base(S_reader_line_base),
        .O_line_y(S_reader_line_y),
        .O_line_bank(S_reader_line_bank),
        .O_line_token(S_reader_line_token),
        .O_line_generation(S_reader_line_generation),
        .O_line_epoch(S_reader_line_epoch),
        .O_line_deadline(S_reader_line_deadline),
        .O_line_tag(S_reader_line_tag),
        .O_line_accepted(S_reader_line_accepted),
        .O_line_retired(S_reader_line_retired),
        .I_read_valid(S_reader_read_valid),
        .O_read_ready(S_reader_read_ready),
        .I_read_bank(S_reader_read_bank),
        .I_read_x(S_reader_read_x),
        .O_pixel_valid(S_reader_pixel_valid),
        .O_rgba(S_reader_rgba),
        .O_pixel_bank(S_reader_pixel_bank),
        .O_pixel_x(S_reader_pixel_x),
        .O_pixel_token(S_reader_pixel_token),
        .O_pixel_generation(S_reader_pixel_generation),
        .O_pixel_epoch(S_reader_pixel_epoch),
        .O_pixel_tag(S_reader_pixel_tag),
        .I_release_valid(S_reader_release_valid),
        .O_release_ready(S_reader_release_ready),
        .I_release_bank(S_reader_release_bank),
        .I_release_token(S_reader_release_token),
        .I_release_generation(S_reader_release_generation),
        .I_release_epoch(S_reader_release_epoch),
        .I_release_tag(S_reader_release_tag),
        .O_bank_valid(S_I_bank_valid),
        .O_bank_reserved(S_reader_bank_reserved),
        .O_bank_slots(S_I_bank_slots),
        .O_bank_rows(S_I_bank_rows),
        .O_bank_tokens(S_I_bank_tokens),
        .O_bank_generations(S_I_bank_generations),
        .O_bank_epochs(S_I_bank_epochs),
        .O_bank_tags(S_I_bank_tags),
        .I_retire_request(S_reader_retire_request),
        .O_retire_ack(S_reader_retire_ack),
        .O_host_retired(S_reader_host_retired),
        .O_host_busy(S_reader_host_busy),
        .O_host_tag_exhausted(S_reader_host_tag_exhausted),
        .O_release_discarded(S_reader_release_discarded),
        .O_event_discarded(S_reader_event_discarded),
        .O_response_discarded(S_reader_response_discarded),
        .O_mem_valid(S_reader_mem_valid),
        .I_mem_ready(S_reply_mem_ready),
        .O_mem_addr(S_reader_mem_addr),
        .O_mem_tag(S_reader_mem_tag),
        .O_mem_token(S_reader_mem_token),
        .O_mem_generation(S_reader_mem_generation),
        .O_mem_deadline(S_reader_mem_deadline),
        .I_mem_valid(S_reply_mem_valid),
        .O_mem_ready(S_reader_mem_ready),
        .I_mem_data(S_reply_mem_data),
        .I_mem_tag(S_reply_mem_tag),
        .I_mem_token(S_reply_mem_token),
        .I_mem_generation(S_reply_mem_generation),
        .I_mem_error(S_reply_mem_error),
        .I_task_source(S_reader_task_source),
        .O_line_source(S_reader_line_source)
    );
    // Explicit zero-latency logical memory endpoint. Not a hardware latency claim.
    assign S_reply_mem_ready=2'b11;
    assign S_reply_mem_valid=S_reader_mem_valid & S_reply_mem_ready;
    assign S_reply_mem_tag=S_reader_mem_tag;
    assign S_reply_mem_token=S_reader_mem_token;
    assign S_reply_mem_generation=S_reader_mem_generation;
    assign S_reply_mem_error=8'd0;
    assign S_reply_mem_data={32'habcd0000^{11'd0,S_reader_mem_addr[41:21]},
        32'habcd0000^{11'd0,S_reader_mem_addr[20:0]}};
    reg S_bad_line_epoch=0;
    task reset_all;
        begin
            @(negedge S_I_host_clk); S_I_async_reset=1; S_I_submit_valid=0; S_I_done_ready=0; S_I_abort=0;
            S_I_prepare_ready=0; S_I_prepare_done_valid=0; S_I_retire_ready=0; S_I_retire_done_valid=0;
            S_I_frame_start=0; S_I_allow_apply=1; S_I_video_abort=0; S_I_audio_ready=0; S_I_audio_epoch=0;
            S_I_source_mask=3; S_I_from_source=0; S_I_slots={3'd1,3'd0};
            S_I_tokens={32'd22,32'd11}; S_I_generations={32'd8,32'd7}; S_I_resident=0;
            S_I_effect=2; S_I_duration_frames=24; S_I_progress=32768; S_I_brightness=4'hf;
            S_I_contrast=2; S_I_saturation=8; S_I_layout=0; S_I_rotation=0; S_I_alert=0;
            S_I_audio_required=1; S_I_first_y={9'd20,9'd10}; S_I_first_bank=0; S_I_first_tag={16'd102,16'd101};
            S_I_lease_valid=3; S_I_lease_slots=S_I_slots; S_I_lease_tokens=S_I_tokens;
            S_I_lease_generations=S_I_generations; S_I_lease_resident=0;
            S_reader_task_valid=0; S_reader_line_ready=1; S_reader_read_valid=0;
            S_reader_release_valid=0; S_reader_retire_request=0; S_bad_line_epoch=0;
            repeat(8) @(negedge S_I_host_clk); S_I_async_reset=0; wait(S_O_submit_ready);
        end
    endtask
    task submit;
        input [15:0] tag;
        begin
            S_case=S_case+1; @(negedge S_I_host_clk); S_I_tag=tag; S_I_submit_valid=1;
            @(posedge S_I_host_clk); while(!S_O_submit_ready) @(posedge S_I_host_clk);
            @(negedge S_I_host_clk); S_I_submit_valid=0;
        end
    endtask
    task prepare_start;
        begin
            wait(S_O_prepare_valid); @(negedge S_I_video_clk); S_I_prepare_ready=1;
            @(negedge S_I_video_clk); S_I_prepare_ready=0;
        end
    endtask
    task fill_source;
        input source;
        integer index;
        begin
            @(negedge S_I_video_clk); S_reader_task_valid=1; S_reader_task_source=source;
            S_reader_task_slot=S_O_pending_slots[source*3+:3];
            S_reader_task_base=source ? 21'h04b000 : 0;
            S_reader_task_y=S_O_pending_first_y[source*9+:9]; S_reader_task_bank=S_O_pending_first_bank[source];
            S_reader_task_token=S_O_pending_tokens[source*32+:32];
            S_reader_task_generation=S_O_pending_generations[source*32+:32];
            S_reader_task_epoch=S_O_pending_epoch+(S_bad_line_epoch ? 1 : 0); S_reader_task_deadline=1234;
            S_reader_task_tag=S_O_pending_first_tag[source*16+:16];
            @(posedge S_I_video_clk); while(!S_reader_task_ready) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_reader_task_valid=0;
            index=source*2+S_O_pending_first_bank[source]; wait(S_I_bank_valid[index]);
            if(S_reader_line_error!==0) fail("real reader could not prepare first row");
        end
    endtask
    task prepare_done;
        input [3:0] error;
        begin
            @(negedge S_I_video_clk); S_I_prepare_done_valid=1; S_I_prepare_done_tag=S_O_pending_tag;
            S_I_prepare_done_epoch=S_O_pending_epoch; S_I_prepare_done_error=error;
            @(posedge S_I_video_clk); while(!S_O_prepare_done_ready) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_I_prepare_done_valid=0;
        end
    endtask
    task frame;
        begin @(negedge S_I_video_clk); S_I_frame_start=1;
            @(negedge S_I_video_clk); S_I_frame_start=0; end
    endtask
    task result;
        input [3:0] error;
        input applied;
        input [31:0] epoch,previous;
        reg [94:0] saved;
        begin
            wait(S_O_done_valid); #1;
            if(S_O_error!==error || S_O_applied!==applied || !S_O_retired || S_O_quarantined ||
                S_O_epoch!==epoch || S_O_previous_epoch!==previous) fail("display result facts");
            saved={S_O_error,S_O_prepare_error,S_O_retire_error,S_O_applied,S_O_retired,S_O_quarantined,
                S_O_tag,S_O_epoch,S_O_previous_epoch};
            repeat(5) begin @(negedge S_I_host_clk);
                if(!S_O_done_valid || saved!=={S_O_error,S_O_prepare_error,S_O_retire_error,S_O_applied,
                    S_O_retired,S_O_quarantined,S_O_tag,S_O_epoch,S_O_previous_epoch}) fail("display result changed"); end
            S_I_done_ready=1; @(negedge S_I_host_clk); S_I_done_ready=0; S_I_abort=0;
            wait(S_O_submit_ready);
        end
    endtask
    task local_error;
        input [3:0] error;
        begin
            submit(16'hdead); wait(S_O_done_valid);
            if(S_O_error!==error || S_O_applied || S_O_epoch!==0 || S_O_prepare_valid || S_O_retire_valid)
                fail("invalid display command transferred ownership");
            @(negedge S_I_host_clk); S_I_done_ready=1;
            @(negedge S_I_host_clk); S_I_done_ready=0; wait(S_O_submit_ready);
        end
    endtask
    task release_retired_config;
        input old;
        input [31:0] epoch;
        integer source,index;
        begin
            wait(S_O_retire_valid); #1;
            if(S_O_retire_old!==old || S_O_retire_epoch!==epoch || S_O_retire_tokens!=={32'd22,32'd11})
                fail("resource retirement identity");
            @(negedge S_I_video_clk); S_I_retire_ready=1;
            @(negedge S_I_video_clk); S_I_retire_ready=0;
            // Represents external scanout/mix pipeline retirement; does not retire memory.
            repeat(8) begin @(negedge S_I_video_clk); if(S_O_done_valid) fail("retire request acceptance is not completion"); end
            for(source=0;source<2;source=source+1) if(S_O_retire_source_mask[source]) begin
                index=source*2+S_O_retire_first_bank[source];
                if(S_I_bank_valid[index] && S_I_bank_epochs[index*32+:32]==epoch) begin
                    S_reader_release_bank[source]=S_O_retire_first_bank[source];
                    S_reader_release_token[source*32+:32]=S_O_retire_tokens[source*32+:32];
                    S_reader_release_generation[source*32+:32]=S_O_retire_generations[source*32+:32];
                    S_reader_release_epoch[source*32+:32]=epoch;
                    S_reader_release_tag[source*16+:16]=S_O_retire_first_tag[source*16+:16];
                    S_reader_release_valid[source]=1;
                    @(posedge S_I_video_clk); while(!S_reader_release_ready[source]) @(posedge S_I_video_clk);
                    @(negedge S_I_video_clk); S_reader_release_valid[source]=0;
                end
            end
            S_I_retire_done_tag=S_O_retire_tag; S_I_retire_done_epoch=epoch; S_I_retire_done_error=0;
            S_I_retire_done_valid=1;
            @(negedge S_I_video_clk); S_I_retire_done_valid=0;
        end
    endtask
    task read_active;
        input bank;
        input [31:0] epoch;
        integer x;
        begin
            for(x=0;x<64;x=x+1) begin
                @(negedge S_I_video_clk); S_reader_read_valid=3; S_reader_read_bank={bank,bank};
                S_reader_read_x[9:0]=x; S_reader_read_x[19:10]=639-x;
                @(posedge S_I_video_clk); #1;
                if(S_reader_pixel_valid!==3 || S_reader_pixel_epoch!=={epoch,epoch}) fail("active lines lost after commit/retire");
            end
            @(negedge S_I_video_clk); S_reader_read_valid=0;
        end
    endtask
    initial begin
        reset_all;
        S_I_source_mask=0; local_error(1); S_I_source_mask=3;
        S_I_progress=65537; local_error(1); S_I_progress=32768;
        S_I_brightness=5; local_error(1); S_I_brightness=4'hf;
        S_I_saturation=17; local_error(1); S_I_saturation=8;
        S_I_lease_tokens[31:0]=12; local_error(4); S_I_lease_tokens[31:0]=11;
        if(S_O_next_epoch!==1) fail("local errors used epoch space");

        submit(1); prepare_start;
        // Real reader bank0 only for A; lying prepare.done cannot bypass absent B.
        S_bad_line_epoch=1; fill_source(0); prepare_done(0);
        S_I_audio_ready=1; S_I_audio_epoch=1;
        frame; if(S_O_active_valid) fail("missing B first row ignored");
        fill_source(1);
        frame; if(S_O_active_valid) fail("old epoch complete rows authorized new config");
        // Release the complete but wrong-epoch rows and refill for this command.
        S_reader_release_valid=3; S_reader_release_bank=0;
        S_reader_release_token=S_O_pending_tokens; S_reader_release_generation=S_O_pending_generations;
        S_reader_release_epoch={32'd2,32'd2}; S_reader_release_tag=S_O_pending_first_tag;
        @(negedge S_I_video_clk); S_reader_release_valid=0;
        S_bad_line_epoch=0; fill_source(0); fill_source(1); S_I_audio_epoch=99;
        frame; if(S_O_active_valid) fail("wrong audio display epoch ignored");
        S_I_audio_epoch=1; S_I_allow_apply=0;
        frame; if(S_O_active_valid) fail("external authorization ignored");
        S_I_allow_apply=1;
        // Mutated input config cannot leak into the accepted snapshot.
        S_I_effect=6; S_I_layout=4; S_I_progress=65536;
        frame; if(!S_O_active_valid || S_O_active_epoch!==1 || S_O_active_effect!==2 ||
            S_O_active_layout!==0 || S_O_active_progress!==32768 || S_O_active_brightness!==4'hf)
            fail("whole display configuration not atomically snapshotted");
        result(0,1,1,0); read_active(0,1);

        // Same held READ_LOCKs, alternate banks/epochs; old banks release individually.
        S_I_first_bank=3; S_I_first_tag={16'd202,16'd201}; S_I_audio_epoch=2;
        submit(2); prepare_start; fill_source(0); fill_source(1); prepare_done(0);
        if(S_O_active_epoch!==1) fail("midframe replacement");
        frame; if(S_O_active_epoch!==2 || S_O_active_effect!==6 || S_O_active_layout!==4) fail("second atomic apply");
        S_I_abort=1; // Host cancel after apply cannot undo the new active config.
        release_retired_config(1,1); result(0,1,2,1);
        if(S_I_bank_valid!==4'b1010) fail("old bank retirement flushed new foreground");
        read_active(1,2);

        // Preparation fails after only one candidate row was loaded into now-free bank0.
        S_I_first_bank=0; S_I_first_tag={16'd302,16'd301}; S_I_audio_epoch=3;
        submit(3); prepare_start; fill_source(0); prepare_done(9);
        release_retired_config(0,3); result(2,0,3,0);
        if(S_O_active_epoch!==2 || S_I_bank_valid!==4'b1010 || S_O_prepare_error!==9)
            fail("candidate failure damaged old foreground");
        read_active(1,2);
        S_test_pass=1; $display("PASS: display_commit with real dual reader first-line identities"); $finish;
    end
endmodule
