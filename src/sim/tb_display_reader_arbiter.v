`timescale 1ns/1ps
// Real candidate + arbiter + dual-clock reader/RAM. Scanout is a protocol endpoint.
module tb_display_reader_arbiter;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_async_reset=0,S_test_pass=0;
    wire S_video_reset;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reset_sync u_video_reset (.I_clk(S_video_clk),.I_async_reset(S_async_reset),.O_reset(S_video_reset));
    reg S_manual=0,S_task_gate=1,S_scan_task_valid=0,S_manual_task_valid=0;
    reg [178:0] S_scan_task=0,S_manual_task=0;
    reg S_scan_line_ready=1,S_manual_line_ready=1,S_fake_line_valid=0;
    reg [206:0] S_fake_line=0;
    reg [7:0] S_task_block=0;
    reg [1:0] S_scan_release_valid=0,S_manual_release_valid=0,S_release_gate=3,S_mem_enable=3;
    reg [225:0] S_scan_release=0,S_manual_release=0;
    reg [1:0] S_read_valid=0,S_read_bank=0;
    reg [19:0] S_read_x=0;
    reg S_check_old=0;
    reg [7:0] S_mem_error=0;
    integer S_case=0,S_scan_lines=0,S_manual_lines=0,S_old_pixels=0;
    reg [206:0] S_last_scan_line=0,S_last_manual_line=0;
    reg  S_c_I_prepare_valid=0;
    wire  S_c_O_prepare_ready;
    reg [1:0] S_c_I_source_mask=0;
    reg [1:0] S_c_I_first_bank=0;
    reg [1:0] S_c_I_source_block=0;
    reg [1:0] S_c_I_authorized=0;
    reg [5:0] S_c_I_slots=0;
    reg [63:0] S_c_I_tokens=0;
    reg [63:0] S_c_I_generations=0;
    reg [63:0] S_c_I_deadlines=0;
    reg [17:0] S_c_I_first_y=0;
    reg [31:0] S_c_I_first_tag=0;
    reg [31:0] S_c_I_epoch=0;
    reg [15:0] S_c_I_tag=0;
    reg  S_c_I_prepare_abort=0;
    wire  S_c_O_prepare_done_valid;
    reg  S_c_I_prepare_done_ready=0;
    wire [3:0] S_c_O_prepare_error;
    wire [3:0] S_c_O_line_error;
    wire [3:0] S_c_O_memory_error;
    wire [31:0] S_c_O_prepare_epoch;
    wire [15:0] S_c_O_prepare_tag;
    reg  S_c_I_adopt_valid=0;
    wire  S_c_O_adopt_ready;
    reg [31:0] S_c_I_adopt_epoch=0;
    reg [15:0] S_c_I_adopt_tag=0;
    wire  S_c_O_adopted;
    reg  S_c_I_retire_valid=0;
    wire  S_c_O_retire_ready;
    reg [31:0] S_c_I_retire_epoch=0;
    reg [15:0] S_c_I_retire_tag=0;
    wire  S_c_O_retire_done_valid;
    reg  S_c_I_retire_done_ready=0;
    wire [3:0] S_c_O_retire_error;
    wire [31:0] S_c_O_retire_epoch;
    wire [15:0] S_c_O_retire_tag;
    wire  S_c_O_busy;
    wire  S_c_O_quarantined;
    wire  S_c_O_contract_fault;
    wire [1:0] S_c_O_source_in_use;
    wire [1:0] S_c_O_source_owner_retired;
    wire [3:0] S_c_O_owned_banks;
    wire [3:0] S_c_O_claim_banks;
    reg [3:0] S_c_I_claimed_banks=0;
    wire  S_c_O_task_valid;
    wire  S_c_O_task_source;
    wire  S_c_O_task_bank;
    wire [2:0] S_c_O_task_slot;
    wire [20:0] S_c_O_task_base;
    wire [8:0] S_c_O_task_y;
    wire [31:0] S_c_O_task_token;
    wire [31:0] S_c_O_task_generation;
    wire [31:0] S_c_O_task_epoch;
    wire [31:0] S_c_O_task_deadline;
    wire [15:0] S_c_O_task_tag;
    wire  S_c_O_line_ready;
    wire [1:0] S_c_O_release_valid;
    wire [1:0] S_c_O_release_bank;
    wire [63:0] S_c_O_release_token;
    wire [63:0] S_c_O_release_generation;
    wire [63:0] S_c_O_release_epoch;
    wire [31:0] S_c_O_release_tag;
    wire [1:0] S_a_O_task_ready;
    wire [3:0] S_a_O_task_reserved;
    wire  S_a_O_reader_task_valid;
    wire [178:0] S_a_O_reader_task_payload;
    wire  S_a_O_reader_line_ready;
    wire [1:0] S_a_O_line_valid;
    wire [206:0] S_a_O_line_payload;
    wire [3:0] S_a_O_release_ready;
    wire [1:0] S_a_O_reader_release_valid;
    wire [225:0] S_a_O_reader_release_payload;
    wire [1:0] S_a_O_source_in_use;
    wire [1:0] S_a_O_source_owner_retired;
    wire  S_a_O_contract_fault;
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
    wire [1:0] S_r_O_retire_ack;
    wire [1:0] S_r_O_host_retired;
    wire [1:0] S_r_O_host_busy;
    wire [1:0] S_r_O_host_tag_exhausted;
    wire [1:0] S_r_O_release_discarded;
    wire [1:0] S_r_O_event_discarded;
    wire [1:0] S_r_O_response_discarded;
    wire [1:0] S_r_O_mem_valid;
    wire [41:0] S_r_O_mem_addr;
    wire [63:0] S_r_O_mem_tag;
    wire [63:0] S_r_O_mem_token;
    wire [63:0] S_r_O_mem_generation;
    wire [63:0] S_r_O_mem_deadline;
    wire [1:0] S_r_O_mem_ready;
    wire  S_r_O_line_source;
    wire [178:0] S_candidate_task={S_c_O_task_source,S_c_O_task_slot,S_c_O_task_base,S_c_O_task_y,S_c_O_task_bank,
        S_c_O_task_token,S_c_O_task_generation,S_c_O_task_epoch,S_c_O_task_deadline,S_c_O_task_tag};
    wire [225:0] S_candidate_release={S_c_O_release_bank[1],S_c_O_release_token[63:32],S_c_O_release_generation[63:32],
        S_c_O_release_epoch[63:32],S_c_O_release_tag[31:16],S_c_O_release_bank[0],S_c_O_release_token[31:0],
        S_c_O_release_generation[31:0],S_c_O_release_epoch[31:0],S_c_O_release_tag[15:0]};
    wire [178:0] S_reader_task=S_a_O_reader_task_payload;
    wire [225:0] S_reader_release=S_a_O_reader_release_payload;
    wire [206:0] S_reader_line={S_r_O_line_error,S_r_O_line_memory_error,S_r_O_line_accepted,S_r_O_line_retired,
        S_r_O_line_source,S_r_O_line_slot,S_r_O_line_base,S_r_O_line_y,S_r_O_line_bank,S_r_O_line_token,
        S_r_O_line_generation,S_r_O_line_epoch,S_r_O_line_deadline,S_r_O_line_tag};
    display_candidate_ctrl u_candidate (
        .I_adopt_atomic_ready(1'b0),
        .I_clk(S_video_clk),
        .I_reset(S_video_reset),
        .I_prepare_valid(S_c_I_prepare_valid),
        .O_prepare_ready(S_c_O_prepare_ready),
        .I_source_mask(S_c_I_source_mask),
        .I_first_bank(S_c_I_first_bank),
        .I_source_block(S_c_I_source_block),
        .I_authorized(S_c_I_authorized),
        .I_slots(S_c_I_slots),
        .I_tokens(S_c_I_tokens),
        .I_generations(S_c_I_generations),
        .I_deadlines(S_c_I_deadlines),
        .I_first_y(S_c_I_first_y),
        .I_first_tag(S_c_I_first_tag),
        .I_epoch(S_c_I_epoch),
        .I_tag(S_c_I_tag),
        .I_prepare_abort(S_c_I_prepare_abort),
        .O_prepare_done_valid(S_c_O_prepare_done_valid),
        .I_prepare_done_ready(S_c_I_prepare_done_ready),
        .O_prepare_error(S_c_O_prepare_error),
        .O_line_error(S_c_O_line_error),
        .O_memory_error(S_c_O_memory_error),
        .O_prepare_epoch(S_c_O_prepare_epoch),
        .O_prepare_tag(S_c_O_prepare_tag),
        .I_adopt_valid(S_c_I_adopt_valid),
        .O_adopt_ready(S_c_O_adopt_ready),
        .I_adopt_epoch(S_c_I_adopt_epoch),
        .I_adopt_tag(S_c_I_adopt_tag),
        .O_adopted(S_c_O_adopted),
        .I_retire_valid(S_c_I_retire_valid),
        .O_retire_ready(S_c_O_retire_ready),
        .I_retire_epoch(S_c_I_retire_epoch),
        .I_retire_tag(S_c_I_retire_tag),
        .O_retire_done_valid(S_c_O_retire_done_valid),
        .I_retire_done_ready(S_c_I_retire_done_ready),
        .O_retire_error(S_c_O_retire_error),
        .O_retire_epoch(S_c_O_retire_epoch),
        .O_retire_tag(S_c_O_retire_tag),
        .O_busy(S_c_O_busy),
        .O_quarantined(S_c_O_quarantined),
        .O_contract_fault(S_c_O_contract_fault),
        .O_source_in_use(S_c_O_source_in_use),
        .O_source_owner_retired(S_c_O_source_owner_retired),
        .O_owned_banks(S_c_O_owned_banks),
        .O_claim_banks(S_c_O_claim_banks),
        .I_claimed_banks(S_c_I_claimed_banks),
        .I_bank_valid(S_r_O_bank_valid),
        .I_bank_reserved(S_r_O_bank_reserved),
        .I_bank_slots(S_r_O_bank_slots),
        .I_bank_rows(S_r_O_bank_rows),
        .I_bank_tokens(S_r_O_bank_tokens),
        .I_bank_generations(S_r_O_bank_generations),
        .I_bank_epochs(S_r_O_bank_epochs),
        .I_bank_tags(S_r_O_bank_tags),
        .O_task_valid(S_c_O_task_valid),
        .I_task_ready(S_a_O_task_ready[1] && !S_manual),
        .O_task_source(S_c_O_task_source),
        .O_task_bank(S_c_O_task_bank),
        .O_task_slot(S_c_O_task_slot),
        .O_task_base(S_c_O_task_base),
        .O_task_y(S_c_O_task_y),
        .O_task_token(S_c_O_task_token),
        .O_task_generation(S_c_O_task_generation),
        .O_task_epoch(S_c_O_task_epoch),
        .O_task_deadline(S_c_O_task_deadline),
        .O_task_tag(S_c_O_task_tag),
        .I_line_valid(S_a_O_line_valid[1] && !S_manual),
        .O_line_ready(S_c_O_line_ready),
        .I_line_source(S_a_O_line_payload[178]),
        .I_line_bank(S_a_O_line_payload[144]),
        .I_line_error(S_a_O_line_payload[206:203]),
        .I_line_memory_error(S_a_O_line_payload[202:199]),
        .I_line_slot(S_a_O_line_payload[177:175]),
        .I_line_base(S_a_O_line_payload[174:154]),
        .I_line_y(S_a_O_line_payload[153:145]),
        .I_line_token(S_a_O_line_payload[143:112]),
        .I_line_generation(S_a_O_line_payload[111:80]),
        .I_line_epoch(S_a_O_line_payload[79:48]),
        .I_line_deadline(S_a_O_line_payload[47:16]),
        .I_line_tag(S_a_O_line_payload[15:0]),
        .O_release_valid(S_c_O_release_valid),
        .I_release_ready(S_a_O_release_ready[3:2] & {2{!S_manual}}),
        .O_release_bank(S_c_O_release_bank),
        .O_release_token(S_c_O_release_token),
        .O_release_generation(S_c_O_release_generation),
        .O_release_epoch(S_c_O_release_epoch),
        .O_release_tag(S_c_O_release_tag)
    );
    display_reader_arbiter u_arbiter (
        .I_clk(S_video_clk),
        .I_reset(S_video_reset),
        .I_task_valid({S_manual ? S_manual_task_valid : S_c_O_task_valid,S_scan_task_valid}),
        .O_task_ready(S_a_O_task_ready),
        .I_task_payload({S_manual ? S_manual_task : S_candidate_task,S_scan_task}),
        .I_task_block(S_task_block),
        .I_bank_reserved(S_r_O_bank_reserved),
        .O_task_reserved(S_a_O_task_reserved),
        .O_reader_task_valid(S_a_O_reader_task_valid),
        .I_reader_task_ready(S_r_O_task_ready && S_task_gate),
        .O_reader_task_payload(S_a_O_reader_task_payload),
        .I_reader_line_valid(S_r_O_line_valid || S_fake_line_valid),
        .O_reader_line_ready(S_a_O_reader_line_ready),
        .I_reader_line_payload(S_fake_line_valid ? S_fake_line : S_reader_line),
        .O_line_valid(S_a_O_line_valid),
        .I_line_ready({S_manual ? S_manual_line_ready : S_c_O_line_ready,S_scan_line_ready}),
        .O_line_payload(S_a_O_line_payload),
        .I_release_valid({S_manual ? S_manual_release_valid : S_c_O_release_valid,S_scan_release_valid}),
        .O_release_ready(S_a_O_release_ready),
        .I_release_payload({S_manual ? S_manual_release : S_candidate_release,S_scan_release}),
        .O_reader_release_valid(S_a_O_reader_release_valid),
        .I_reader_release_ready(S_r_O_release_ready & S_release_gate),
        .O_reader_release_payload(S_a_O_reader_release_payload),
        .O_source_in_use(S_a_O_source_in_use),
        .O_source_owner_retired(S_a_O_source_owner_retired),
        .O_contract_fault(S_a_O_contract_fault)
    );
    fb_reader u_reader (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_async_reset),
        .I_lease_valid(2'b11),
        .I_lease_slot({3'd1,3'd0}),
        .I_lease_token({32'd22,32'd11}),
        .I_lease_generation({32'd202,32'd101}),
        .I_task_valid(S_a_O_reader_task_valid && S_task_gate),
        .O_task_ready(S_r_O_task_ready),
        .I_task_slot(S_reader_task[177:175]),
        .I_task_base(S_reader_task[174:154]),
        .I_task_y(S_reader_task[153:145]),
        .I_task_bank(S_reader_task[144]),
        .I_task_token(S_reader_task[143:112]),
        .I_task_generation(S_reader_task[111:80]),
        .I_task_epoch(S_reader_task[79:48]),
        .I_task_deadline(S_reader_task[47:16]),
        .I_task_tag(S_reader_task[15:0]),
        .O_line_valid(S_r_O_line_valid),
        .I_line_ready(S_a_O_reader_line_ready && !S_fake_line_valid),
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
        .I_read_valid(S_read_valid),
        .O_read_ready(S_r_O_read_ready),
        .I_read_bank(S_read_bank),
        .I_read_x(S_read_x),
        .O_pixel_valid(S_r_O_pixel_valid),
        .O_rgba(S_r_O_rgba),
        .O_pixel_bank(S_r_O_pixel_bank),
        .O_pixel_x(S_r_O_pixel_x),
        .O_pixel_token(S_r_O_pixel_token),
        .O_pixel_generation(S_r_O_pixel_generation),
        .O_pixel_epoch(S_r_O_pixel_epoch),
        .O_pixel_tag(S_r_O_pixel_tag),
        .I_release_valid(S_a_O_reader_release_valid & S_release_gate),
        .O_release_ready(S_r_O_release_ready),
        .I_release_bank({S_reader_release[225],S_reader_release[112]}),
        .I_release_token({S_reader_release[224:193],S_reader_release[111:80]}),
        .I_release_generation({S_reader_release[192:161],S_reader_release[79:48]}),
        .I_release_epoch({S_reader_release[160:129],S_reader_release[47:16]}),
        .I_release_tag({S_reader_release[128:113],S_reader_release[15:0]}),
        .O_bank_valid(S_r_O_bank_valid),
        .O_bank_reserved(S_r_O_bank_reserved),
        .O_bank_slots(S_r_O_bank_slots),
        .O_bank_rows(S_r_O_bank_rows),
        .O_bank_tokens(S_r_O_bank_tokens),
        .O_bank_generations(S_r_O_bank_generations),
        .O_bank_epochs(S_r_O_bank_epochs),
        .O_bank_tags(S_r_O_bank_tags),
        .I_retire_request(2'b00),
        .O_retire_ack(S_r_O_retire_ack),
        .O_host_retired(S_r_O_host_retired),
        .O_host_busy(S_r_O_host_busy),
        .O_host_tag_exhausted(S_r_O_host_tag_exhausted),
        .O_release_discarded(S_r_O_release_discarded),
        .O_event_discarded(S_r_O_event_discarded),
        .O_response_discarded(S_r_O_response_discarded),
        .O_mem_valid(S_r_O_mem_valid),
        .I_mem_ready(S_mem_enable),
        .O_mem_addr(S_r_O_mem_addr),
        .O_mem_tag(S_r_O_mem_tag),
        .O_mem_token(S_r_O_mem_token),
        .O_mem_generation(S_r_O_mem_generation),
        .O_mem_deadline(S_r_O_mem_deadline),
        .I_mem_valid(S_r_O_mem_valid & S_mem_enable),
        .O_mem_ready(S_r_O_mem_ready),
        .I_mem_data({(32'h73c20000 ^ {11'd0,S_r_O_mem_addr[41:21]}),(32'h26a10000 ^ {11'd0,S_r_O_mem_addr[20:0]})}),
        .I_mem_tag(S_r_O_mem_tag),
        .I_mem_token(S_r_O_mem_token),
        .I_mem_generation(S_r_O_mem_generation),
        .I_mem_error(S_mem_error),
        .I_task_source(S_reader_task[178]),
        .O_line_source(S_r_O_line_source)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: reader arbiter case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #20000000; fail("watchdog timeout"); end
    function [178:0] make_task;
        input source,bank;
        input [8:0] row;
        input [31:0] epoch;
        input [15:0] tag;
        begin make_task={source,source ? 3'd1 : 3'd0,source ? 21'd307200 : 21'd0,row,bank,
            source ? 32'd22 : 32'd11,source ? 32'd202 : 32'd101,epoch,32'h87654321,tag}; end
    endfunction
    function [112:0] make_release;
        input [178:0] task_data;
        begin make_release={task_data[144],task_data[143:112],task_data[111:80],task_data[79:48],task_data[15:0]}; end
    endfunction
    reg S_task_held=0,S_line_held=0;
    reg [178:0] S_saved_task;
    reg [206:0] S_saved_line;
    reg [1:0] S_saved_line_owner=0;
    reg [1:0] S_release_held=0;
    reg [112:0] S_saved_release[0:1];
    integer S_i;
    always @(posedge S_video_clk) begin
        if(S_video_reset) begin S_task_held=0; S_line_held=0; S_release_held=0; end
        else begin
            if(S_r_O_release_discarded!=0) fail("arbiter released stale bank identity");
            if(S_task_held && (!S_a_O_reader_task_valid || S_saved_task!==S_a_O_reader_task_payload))
                fail("buffered reader task changed under backpressure");
            S_task_held=S_a_O_reader_task_valid && !(S_r_O_task_ready && S_task_gate);
            S_saved_task=S_a_O_reader_task_payload;
            if(S_line_held && (S_a_O_line_valid!==S_saved_line_owner || S_saved_line!==S_a_O_line_payload))
                fail("line routing/payload changed while owner stalled");
            S_line_held=(|(S_a_O_line_valid)) && !S_a_O_reader_line_ready;
            S_saved_line=S_a_O_line_payload;
            S_saved_line_owner=S_a_O_line_valid;
            for(S_i=0;S_i<2;S_i=S_i+1) begin
                if(S_release_held[S_i] && (!S_a_O_reader_release_valid[S_i] ||
                    S_saved_release[S_i]!==S_a_O_reader_release_payload[S_i*113+:113]))
                    fail("buffered release switched waiting owner");
                S_release_held[S_i]=S_a_O_reader_release_valid[S_i] && !(S_r_O_release_ready[S_i] && S_release_gate[S_i]);
                S_saved_release[S_i]=S_a_O_reader_release_payload[S_i*113+:113];
            end
            if(S_a_O_line_valid==3) fail("line delivered to both owners");
            if(S_a_O_line_valid[0] && S_scan_line_ready) begin S_scan_lines=S_scan_lines+1; S_last_scan_line=S_a_O_line_payload; end
            if(S_manual && S_a_O_line_valid[1] && S_manual_line_ready) begin S_manual_lines=S_manual_lines+1; S_last_manual_line=S_a_O_line_payload; end
            if(S_check_old && S_r_O_pixel_valid[0]) begin
                if(S_r_O_rgba[31:0]!== (32'h26a10000 ^ (20*640+13)) || S_r_O_pixel_epoch[31:0]!==7 ||
                    S_r_O_pixel_tag[15:0]!==16'h1111) fail("candidate arbitration changed old front pixels");
                S_old_pixels=S_old_pixels+1;
            end
        end
    end
    task reset_all;
        begin
            S_case=S_case+1;
            @(negedge S_video_clk); S_async_reset=1;
            S_manual=0; S_task_gate=1; S_scan_task_valid=0; S_manual_task_valid=0;
            S_scan_task=0; S_manual_task=0; S_task_block=0;
            S_scan_line_ready=1; S_manual_line_ready=1; S_fake_line_valid=0; S_fake_line=0;
            S_scan_release_valid=0; S_manual_release_valid=0; S_release_gate=3; S_mem_enable=3;
            S_scan_release=0; S_manual_release=0; S_read_valid=0; S_read_bank=0; S_read_x=0; S_check_old=0;
            S_mem_error=0;
            S_c_I_prepare_valid=0; S_c_I_prepare_abort=0; S_c_I_prepare_done_ready=0;
            S_c_I_adopt_valid=0; S_c_I_retire_valid=0; S_c_I_retire_done_ready=0;
            S_c_I_claimed_banks=0; S_c_I_source_block=0; S_c_I_authorized=3;
            S_c_I_source_mask=3; S_c_I_slots={3'd1,3'd0}; S_c_I_tokens={32'd22,32'd11};
            S_c_I_generations={32'd202,32'd101}; S_c_I_first_bank=3; S_c_I_first_y={9'd17,9'd9};
            S_c_I_first_tag={16'hc202,16'hc101}; S_c_I_deadlines={32'h12345678,32'h13572468};
            S_c_I_epoch=8; S_c_I_tag=16'hca08;
            repeat(6) @(negedge S_video_clk); S_async_reset=0;
            wait(!S_video_reset); repeat(6) @(negedge S_video_clk);
            S_scan_lines=0; S_manual_lines=0; S_old_pixels=0;
        end
    endtask
    task send_scan;
        input [178:0] payload;
        begin
            @(negedge S_video_clk); S_scan_task=payload; S_scan_task_valid=1;
            @(posedge S_video_clk); while(!S_a_O_task_ready[0]) @(posedge S_video_clk);
            @(negedge S_video_clk); S_scan_task_valid=0;
        end
    endtask
    task prepare;
        begin
            @(negedge S_video_clk); S_c_I_prepare_valid=1;
            @(posedge S_video_clk); while(!S_c_O_prepare_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_c_I_prepare_valid=0;
        end
    endtask
    task release_scan;
        input [178:0] payload;
        begin
            @(negedge S_video_clk);
            if(payload[178]) S_scan_release[225:113]=make_release(payload);
            else S_scan_release[112:0]=make_release(payload);
            S_scan_release_valid[payload[178]]=1;
            @(posedge S_video_clk); while(!S_a_O_release_ready[payload[178]]) @(posedge S_video_clk);
            @(negedge S_video_clk); S_scan_release_valid[payload[178]]=0;
        end
    endtask
    initial begin
        // Buffered old-front task cannot be preempted by the actual candidate.
        reset_all; S_task_gate=0; S_mem_enable=0; S_scan_line_ready=0;
        send_scan(make_task(0,0,20,7,16'h1111)); prepare;
        wait(S_c_O_task_valid);
        repeat(8) begin
            @(negedge S_video_clk);
            if(!S_a_O_reader_task_valid || S_a_O_reader_task_payload!==S_scan_task || S_a_O_task_ready[1])
                fail("candidate preempted buffered scan request");
        end
        S_task_gate=1;
        wait(S_a_O_task_reserved[1:0]==3);
        if(!S_a_O_source_in_use[0] || S_a_O_source_owner_retired[0]) fail("accepted task obligation not exposed");
        S_mem_enable=3;
        wait(S_a_O_line_valid[0]);
        repeat(8) begin
            @(negedge S_video_clk);
            if(S_a_O_line_valid!==1 || S_a_O_reader_line_ready || S_c_O_prepare_done_valid)
                fail("stalled scan result escaped to candidate");
        end
        S_scan_line_ready=1;
        wait(S_c_O_prepare_done_valid); #1;
        if(S_c_O_prepare_error!=0 || S_scan_lines!=1 || S_last_scan_line[178:0]!==S_scan_task ||
            S_c_O_owned_banks!==10 || S_r_O_bank_valid!==11 || S_a_O_task_reserved!=0)
            fail("real candidate/scanner line routing");
        @(negedge S_video_clk); S_c_I_prepare_done_ready=1;
        @(negedge S_video_clk); S_c_I_prepare_done_ready=0;
        S_read_valid=1; S_read_x=13; S_check_old=1;
        repeat(12) @(negedge S_video_clk);
        if(S_old_pixels<8) fail("old-front real pixel coverage");
        S_read_valid=0; S_check_old=0;
        repeat(3) @(negedge S_video_clk);
        // Scan source0 and candidate source0/source1 release together. No local
        // capture may acknowledge either owner before actual reader acceptance.
        S_release_gate=0; S_scan_release[112:0]=make_release(S_scan_task); S_scan_release_valid=1;
        S_c_I_retire_epoch=8; S_c_I_retire_tag=16'hca08; S_c_I_retire_valid=1;
        @(posedge S_video_clk); while(!S_c_O_retire_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_c_I_retire_valid=0;
        wait(S_a_O_reader_release_valid==3);
        repeat(8) begin
            @(negedge S_video_clk);
            if(S_a_O_release_ready!=0 || S_c_O_retire_done_valid || S_c_O_owned_banks!==10 ||
                S_a_O_reader_release_payload[112:0]!==make_release(S_scan_task))
                fail("local release capture acknowledged owner early");
        end
        S_release_gate=2;
        wait(!S_c_O_release_valid[1]);
        if(!S_c_O_release_valid[0] || S_c_O_retire_done_valid || !S_a_O_source_in_use[0])
            fail("source1 release bypassed source0 real obligation");
        @(negedge S_video_clk); S_video_run=0;
        repeat(40) @(negedge S_host_clk);
        if(S_c_O_retire_done_valid) fail("video stop fabricated release completion");
        S_video_run=1; S_release_gate=3;
        @(posedge S_video_clk); while(!S_a_O_release_ready[0]) @(posedge S_video_clk);
        @(negedge S_video_clk); S_scan_release_valid=0;
        wait(S_c_O_retire_done_valid); #1;
        if(S_c_O_retire_error!=0 || S_r_O_bank_reserved!=0 || S_a_O_source_in_use!=0 ||
            S_a_O_source_owner_retired!==3 || S_a_O_contract_fault || S_c_O_quarantined)
            fail("actual dual-source release retirement");
        @(negedge S_video_clk); S_c_I_retire_done_ready=1;
        @(negedge S_video_clk); S_c_I_retire_done_ready=0;

        // Same bank cannot be reissued after its result while the reader still
        // reserves the successful line. Release it before granting client1.
        reset_all; S_manual=1;
        @(negedge S_video_clk);
        S_scan_task=make_task(0,0,2,10,16'h2222); S_manual_task=make_task(0,0,3,11,16'h2222);
        S_scan_task_valid=1; S_manual_task_valid=1;
        @(posedge S_video_clk); if(S_a_O_task_ready!==1) fail("initial task round robin");
        @(negedge S_video_clk); S_scan_task_valid=0;
        wait(S_scan_lines==1);
        repeat(8) begin @(negedge S_video_clk); if(S_a_O_task_ready[1] || S_manual_lines!=0)
            fail("successful bank reused before true release"); end
        release_scan(S_scan_task);
        @(posedge S_video_clk); while(!S_a_O_task_ready[1]) @(posedge S_video_clk);
        @(negedge S_video_clk); S_manual_task_valid=0;
        wait(S_manual_lines==1);
        if(S_last_manual_line[178:0]!==S_manual_task || S_last_scan_line[79:48]!==10 ||
            S_a_O_contract_fault) fail("same tag routed by epoch guess rather than actual owner");
        @(negedge S_video_clk); S_manual_release[112:0]=make_release(S_manual_task); S_manual_release_valid=1;
        @(posedge S_video_clk); while(!S_a_O_release_ready[2]) @(posedge S_video_clk);
        @(negedge S_video_clk); S_manual_release_valid=0;

        // A blocked client cannot occupy the output and stall another free bank.
        reset_all; S_manual=1; S_task_block=1;
        @(negedge S_video_clk);
        S_scan_task=make_task(0,0,2,12,1); S_manual_task=make_task(1,0,4,13,1);
        S_scan_task_valid=1; S_manual_task_valid=1;
        @(posedge S_video_clk); if(S_a_O_task_ready!==2) fail("blocked task prevented eligible peer");
        @(negedge S_video_clk); S_manual_task_valid=0;
        wait(S_manual_lines==1);
        if(S_scan_lines!=0 || S_a_O_task_reserved[0]) fail("blocked task acquired obligation");
        @(negedge S_video_clk); S_task_block=0;
        @(posedge S_video_clk); while(!S_a_O_task_ready[0]) @(posedge S_video_clk);
        @(negedge S_video_clk); S_scan_task_valid=0;
        wait(S_scan_lines==1);
        if(S_a_O_contract_fault) fail("blocked task recovery fault");

        // With both clients eligible, advance their payload only after each
        // accepted task. Four different banks retain four independent owners.
        reset_all; S_manual=1; S_mem_enable=0;
        @(negedge S_video_clk);
        S_scan_task=make_task(0,0,2,16,1); S_manual_task=make_task(1,0,3,17,1);
        S_scan_task_valid=1; S_manual_task_valid=1;
        @(posedge S_video_clk); while(S_a_O_task_ready==0) @(posedge S_video_clk);
        if(S_a_O_task_ready!==1) fail("round robin first grant");
        @(negedge S_video_clk); S_scan_task=make_task(0,1,4,18,1);
        @(posedge S_video_clk); while(S_a_O_task_ready==0) @(posedge S_video_clk);
        if(S_a_O_task_ready!==2) fail("round robin second grant");
        @(negedge S_video_clk); S_manual_task=make_task(1,1,5,19,1);
        @(posedge S_video_clk); while(S_a_O_task_ready==0) @(posedge S_video_clk);
        if(S_a_O_task_ready!==1) fail("round robin third grant");
        @(negedge S_video_clk); S_scan_task_valid=0;
        @(posedge S_video_clk); while(S_a_O_task_ready==0) @(posedge S_video_clk);
        if(S_a_O_task_ready!==2) fail("round robin fourth grant");
        @(negedge S_video_clk); S_manual_task_valid=0;
        if(S_a_O_task_reserved!==15) fail("four bank task ledger missing entries");
        S_mem_enable=3;
        wait(S_scan_lines==2 && S_manual_lines==2); #1;
        if(S_a_O_task_reserved!=0 || S_r_O_bank_valid!==15 ||
            S_last_scan_line[79:48]!==18 || S_last_manual_line[79:48]!==19 || S_a_O_contract_fault)
            fail("four bank ledger confused advanced producer payloads");

        // Even an exact identity cannot complete a task before actual reader
        // acceptance. An unknown identity never clears the task ledger either.
        reset_all; S_manual=1; S_task_gate=0; S_mem_enable=0;
        send_scan(make_task(0,0,2,14,2));
        @(negedge S_video_clk); S_fake_line={4'd0,4'd0,10'd640,10'd640,S_scan_task}; S_fake_line_valid=1;
        repeat(5) begin @(negedge S_video_clk); if(S_a_O_reader_line_ready || S_a_O_line_valid!=0 ||
            S_a_O_task_reserved!==1) fail("unsent task falsely completed"); end
        S_fake_line_valid=0; S_task_gate=1;
        wait(S_r_O_mem_valid[0]);
        @(negedge S_video_clk); S_fake_line={4'd0,4'd0,10'd640,10'd640,(S_scan_task ^ 179'd1)}; S_fake_line_valid=1;
        repeat(5) begin @(negedge S_video_clk); if(S_a_O_reader_line_ready || S_a_O_line_valid!=0 ||
            S_a_O_task_reserved!==1) fail("wrong identity cleared ledger"); end
        if(!S_a_O_contract_fault) fail("unmatched result lacked contract diagnostic");
        S_fake_line_valid=0;
        @(negedge S_host_clk); S_host_run=0;
        repeat(8) begin @(negedge S_video_clk); if(S_scan_lines!=0 || S_a_O_source_owner_retired[0])
            fail("host stop fabricated task retirement"); end
        S_host_run=1; S_mem_enable=3;
        wait(S_scan_lines==1); #1;
        if(S_a_O_task_reserved!=0 || S_last_scan_line[178:0]!==S_scan_task) fail("true result did not retire ledger");
        release_scan(S_scan_task);

        // Real error status follows its accepted client, while the candidate's
        // other source completes normally through the same result interface.
        reset_all; S_mem_error=8'h90; S_c_I_source_mask=1;
        send_scan(make_task(1,0,4,7,16'h7777)); prepare;
        wait(S_c_O_prepare_done_valid); wait(S_scan_lines==1); #1;
        if(S_c_O_prepare_error!=0 || S_c_O_owned_banks!==2 ||
            S_last_scan_line[206:203]!==3 || S_last_scan_line[202:199]!==9 ||
            S_last_scan_line[178:0]!==S_scan_task || S_a_O_task_reserved!=0 || S_a_O_contract_fault)
            fail("reader error routed to wrong client");

        // Candidate already accepted by the arbiter may be cancelled while the
        // physical reader is blocked; the arbiter must still send/drain it.
        reset_all; S_task_gate=0; prepare;
        wait(S_a_O_reader_task_valid);
        @(negedge S_video_clk); S_c_I_prepare_abort=1;
        repeat(8) begin @(negedge S_video_clk); if(!S_a_O_reader_task_valid || S_c_O_prepare_done_valid ||
            S_a_O_task_reserved!==2) fail("candidate cancel withdrew buffered reader task"); end
        S_c_I_prepare_abort=0; S_task_gate=1;
        wait(S_c_O_prepare_done_valid); #1;
        if(S_c_O_prepare_error!==3 || S_c_O_owned_banks!==2 || S_r_O_bank_reserved[3:2]!=0 ||
            S_a_O_task_reserved!=0 || S_a_O_contract_fault)
            fail("buffered cancelled task did not truly retire");

        // Producer contract violation diagnoses a held release, but the reader
        // still receives the original registered command and completes it.
        reset_all; S_manual=1;
        send_scan(make_task(0,0,2,15,3)); wait(S_scan_lines==1); S_release_gate=0;
        @(negedge S_video_clk); S_scan_release[112:0]=make_release(S_scan_task); S_scan_release_valid=1;
        wait(S_a_O_reader_release_valid[0]);
        @(negedge S_video_clk); S_scan_release[0]=!S_scan_release[0];
        repeat(5) begin @(negedge S_video_clk); if(S_a_O_reader_release_payload[112:0]!==make_release(S_scan_task))
            fail("upstream release mutation changed presented reader payload"); end
        if(!S_a_O_contract_fault) fail("release producer mutation undiagnosed");
        S_release_gate=3;
        @(posedge S_video_clk); while(!S_a_O_release_ready[0]) @(posedge S_video_clk);
        @(negedge S_video_clk); S_scan_release_valid=0;
        if(S_r_O_bank_reserved!=0) fail("held snapshot not actually released");
        reset_all;
        if(S_a_O_contract_fault || S_a_O_task_reserved!=0 || S_a_O_source_owner_retired!==3)
            fail("global reset recovery");
        S_test_pass=1; $display("PASS: reader arbiter/candidate integration/true task ownership/release acceptance"); $finish;
    end
endmodule
