`timescale 1ns/1ps
// Real candidate owner + reader/CDC/line RAM. Memory and takeover are explicit endpoints.
module tb_display_candidate_ctrl;
    reg S_host_clk=0,S_video_clk=0,S_host_run=1,S_video_run=1,S_async_reset=0,S_test_pass=0;
    wire S_video_reset;
    always #4 if(S_host_run) S_host_clk=~S_host_clk;
    always #20 if(S_video_run) S_video_clk=~S_video_clk;
    reset_sync u_video_reset (.I_clk(S_video_clk),.I_async_reset(S_async_reset),.O_reset(S_video_reset));
    reg S_task_gate=1,S_line_gate=1,S_wrong_line=0,S_external_task=0,S_external_line=0;
    reg [1:0] S_release_gate=3,S_mem_enable=3,S_lease_valid=3,S_read_valid=0;
    reg [1:0] S_read_bank=0;
    reg [19:0] S_read_x=0;
    reg S_mem_error=0,S_check_old=0;
    reg [3:0] S_corrupt_bank=0;
    integer S_case=0,S_old_pixels=0;
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
        .I_bank_valid(S_r_O_bank_valid ^ S_corrupt_bank),
        .I_bank_reserved(S_r_O_bank_reserved),
        .I_bank_slots(S_r_O_bank_slots),
        .I_bank_rows(S_r_O_bank_rows),
        .I_bank_tokens(S_r_O_bank_tokens),
        .I_bank_generations(S_r_O_bank_generations),
        .I_bank_epochs(S_r_O_bank_epochs),
        .I_bank_tags(S_r_O_bank_tags),
        .O_task_valid(S_c_O_task_valid),
        .I_task_ready(S_r_O_task_ready && S_task_gate && !S_external_task),
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
        .I_line_valid(S_r_O_line_valid && S_line_gate && S_r_O_line_epoch!=7),
        .O_line_ready(S_c_O_line_ready),
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
        .I_line_tag(S_r_O_line_tag ^ {15'd0,S_wrong_line}),
        .O_release_valid(S_c_O_release_valid),
        .I_release_ready(S_r_O_release_ready & S_release_gate),
        .O_release_bank(S_c_O_release_bank),
        .O_release_token(S_c_O_release_token),
        .O_release_generation(S_c_O_release_generation),
        .O_release_epoch(S_c_O_release_epoch),
        .O_release_tag(S_c_O_release_tag)
    );
    fb_reader u_reader (
        .I_host_clk(S_host_clk),
        .I_video_clk(S_video_clk),
        .I_async_reset(S_async_reset),
        .I_lease_valid(S_lease_valid),
        .I_lease_slot({3'd1,3'd0}),
        .I_lease_token({32'd22,32'd11}),
        .I_lease_generation({32'd202,32'd101}),
        .I_task_valid(S_external_task || (S_c_O_task_valid && S_task_gate)),
        .O_task_ready(S_r_O_task_ready),
        .I_task_slot(S_external_task ? 3'd0 : S_c_O_task_slot),
        .I_task_base(S_external_task ? 21'd0 : S_c_O_task_base),
        .I_task_y(S_external_task ? 9'd20 : S_c_O_task_y),
        .I_task_bank(S_external_task ? 1'b0 : S_c_O_task_bank),
        .I_task_token(S_external_task ? 32'd11 : S_c_O_task_token),
        .I_task_generation(S_external_task ? 32'd101 : S_c_O_task_generation),
        .I_task_epoch(S_external_task ? 32'd7 : S_c_O_task_epoch),
        .I_task_deadline(S_external_task ? 32'h76543210 : S_c_O_task_deadline),
        .I_task_tag(S_external_task ? 16'h1111 : S_c_O_task_tag),
        .O_line_valid(S_r_O_line_valid),
        .I_line_ready(S_r_O_line_epoch==7 ? S_external_line : (S_c_O_line_ready && S_line_gate)),
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
        .I_release_valid(S_c_O_release_valid & S_release_gate),
        .O_release_ready(S_r_O_release_ready),
        .I_release_bank(S_c_O_release_bank),
        .I_release_token(S_c_O_release_token),
        .I_release_generation(S_c_O_release_generation),
        .I_release_epoch(S_c_O_release_epoch),
        .I_release_tag(S_c_O_release_tag),
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
        .I_mem_error({S_mem_error ? 4'd9 : 4'd0,4'd0}),
        .I_task_source(S_external_task ? 1'b0 : S_c_O_task_source),
        .O_line_source(S_r_O_line_source)
    );
    task fail;
        input [767:0] message;
        begin $display("FAIL: candidate case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #20000000; fail("watchdog timeout"); end
    reg S_task_held=0;
    reg [178:0] S_saved_task,S_now_task;
    reg [1:0] S_release_held=0;
    reg [112:0] S_saved_release[0:1],S_now_release;
    integer S_i;
    always @(posedge S_video_clk) begin
        if(S_video_reset) begin S_task_held=0; S_release_held=0; end
        else begin
            if(S_r_O_release_discarded!=0) fail("candidate sent stale release identity");
            S_now_task={S_c_O_task_source,S_c_O_task_slot,S_c_O_task_base,S_c_O_task_y,S_c_O_task_bank,
                S_c_O_task_token,S_c_O_task_generation,S_c_O_task_epoch,S_c_O_task_deadline,S_c_O_task_tag};
            if(S_task_held && (!S_c_O_task_valid || S_now_task!==S_saved_task)) fail("held task changed");
            S_task_held=S_c_O_task_valid && !(S_r_O_task_ready && S_task_gate && !S_external_task);
            S_saved_task=S_now_task;
            for(S_i=0;S_i<2;S_i=S_i+1) begin
                S_now_release={S_c_O_release_bank[S_i],S_c_O_release_token[S_i*32+:32],
                    S_c_O_release_generation[S_i*32+:32],S_c_O_release_epoch[S_i*32+:32],S_c_O_release_tag[S_i*16+:16]};
                if(S_release_held[S_i] && (!S_c_O_release_valid[S_i] || S_now_release!==S_saved_release[S_i]))
                    fail("held release changed");
                S_release_held[S_i]=S_c_O_release_valid[S_i] && !(S_r_O_release_ready[S_i] && S_release_gate[S_i]);
                S_saved_release[S_i]=S_now_release;
            end
            if(S_check_old && S_r_O_pixel_valid[0]) begin
                if(S_r_O_rgba[31:0]!== (32'h26a10000 ^ (20*640+13)) ||
                    S_r_O_pixel_epoch[31:0]!==7 || S_r_O_pixel_tag[15:0]!==16'h1111)
                    fail("candidate damaged old front pixels");
                S_old_pixels=S_old_pixels+1;
            end
        end
    end
    task reset_all;
        begin
            S_case=S_case+1;
            @(negedge S_video_clk); S_async_reset=1;
            S_c_I_prepare_valid=0; S_c_I_prepare_abort=0; S_c_I_prepare_done_ready=0;
            S_c_I_adopt_valid=0; S_c_I_retire_valid=0; S_c_I_retire_done_ready=0;
            S_c_I_claimed_banks=0; S_c_I_source_block=0; S_c_I_authorized=3;
            S_c_I_source_mask=3; S_c_I_slots={3'd1,3'd0};
            S_c_I_tokens={32'd22,32'd11}; S_c_I_generations={32'd202,32'd101};
            S_c_I_first_bank=3; S_c_I_first_y={9'd17,9'd9}; S_c_I_first_tag={16'hc202,16'hc101};
            S_c_I_deadlines={32'h12345678,32'h13572468}; S_c_I_epoch=8; S_c_I_tag=16'hca08;
            S_task_gate=1; S_line_gate=1; S_wrong_line=0; S_external_task=0; S_external_line=0;
            S_release_gate=3; S_mem_enable=3; S_lease_valid=3; S_mem_error=0;
            S_read_valid=0; S_read_bank=0; S_read_x=0; S_check_old=0; S_corrupt_bank=0; S_old_pixels=0;
            repeat(6) @(negedge S_video_clk); S_async_reset=0;
            wait(!S_video_reset); repeat(6) @(negedge S_video_clk);
        end
    endtask
    task prepare;
        begin
            @(negedge S_video_clk); S_c_I_prepare_valid=1;
            @(posedge S_video_clk); while(!S_c_O_prepare_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_c_I_prepare_valid=0;
        end
    endtask
    task prepared;
        input [3:0] error;
        reg [51:0] saved;
        begin
            wait(S_c_O_prepare_done_valid); #1;
            if(S_c_O_prepare_error!==error || S_c_O_prepare_epoch!==8 || S_c_O_prepare_tag!==16'hca08)
                fail("prepare result identity/error");
            saved={S_c_O_prepare_error,S_c_O_prepare_epoch,S_c_O_prepare_tag};
            repeat(5) begin
                @(negedge S_video_clk);
                if(!S_c_O_prepare_done_valid || saved!=={S_c_O_prepare_error,S_c_O_prepare_epoch,S_c_O_prepare_tag})
                    fail("prepare result not held");
            end
            S_c_I_prepare_done_ready=1;
            @(negedge S_video_clk); S_c_I_prepare_done_ready=0;
        end
    endtask
    task retire;
        input [3:0] error;
        reg [51:0] saved;
        begin
            @(negedge S_video_clk); S_c_I_retire_epoch=8; S_c_I_retire_tag=16'hca08; S_c_I_retire_valid=1;
            @(posedge S_video_clk); while(!S_c_O_retire_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_c_I_retire_valid=0;
            wait(S_c_O_retire_done_valid); #1;
            if(S_c_O_retire_error!==error || S_c_O_retire_epoch!==8 || S_c_O_retire_tag!==16'hca08)
                fail("retire result identity/error");
            saved={S_c_O_retire_error,S_c_O_retire_epoch,S_c_O_retire_tag};
            repeat(5) begin
                @(negedge S_video_clk);
                if(!S_c_O_retire_done_valid || saved!=={S_c_O_retire_error,S_c_O_retire_epoch,S_c_O_retire_tag})
                    fail("retire result not held");
            end
            S_c_I_retire_done_ready=1;
            @(negedge S_video_clk); S_c_I_retire_done_ready=0;
        end
    endtask
    task fill_old;
        begin
            @(negedge S_video_clk); S_external_task=1;
            @(posedge S_video_clk); while(!S_r_O_task_ready) @(posedge S_video_clk);
            @(negedge S_video_clk); S_external_task=0;
            wait(S_r_O_line_valid && S_r_O_line_epoch==7);
            if(S_r_O_line_error!=0) fail("old front fixture failed");
            @(negedge S_video_clk); S_external_line=1;
            @(negedge S_video_clk); S_external_line=0;
            S_c_I_claimed_banks=1; S_read_valid=1; S_read_x=13; S_check_old=1;
        end
    endtask
    initial begin
        // Successful two-source first lines coexist with an old front bank.
        reset_all; fill_old; prepare; prepared(0);
        if(S_c_O_owned_banks!==4'b1010 || S_c_O_claim_banks!==4'b1010 ||
            S_r_O_bank_valid!==4'b1011 || S_c_O_source_in_use!==3) fail("first-line resource ownership");
        S_c_I_adopt_epoch=8; S_c_I_adopt_tag=16'hca08; S_c_I_adopt_valid=1; S_c_I_claimed_banks=3;
        repeat(6) begin @(negedge S_video_clk); if(S_c_O_adopt_ready || S_c_O_adopted) fail("partial takeover accepted"); end
        S_c_I_claimed_banks=11;
        @(posedge S_video_clk); if(!S_c_O_adopt_ready) fail("complete takeover refused");
        @(negedge S_video_clk); S_c_I_adopt_valid=0;
        if(!S_c_O_adopted || S_c_O_busy || S_c_O_owned_banks!=0 || S_c_O_release_valid!=0 ||
            S_r_O_bank_valid!==11 || S_old_pixels<10) fail("takeover released reader banks");

        // Cancel a held task: still accept/drain it, never start the other source.
        reset_all; fill_old; S_task_gate=0; prepare;
        wait(S_c_O_task_valid); @(negedge S_video_clk); S_c_I_prepare_abort=1;
        repeat(8) begin @(negedge S_video_clk); if(!S_c_O_task_valid || S_c_O_prepare_done_valid) fail("cancel withdrew presented task"); end
        S_c_I_prepare_abort=0; S_mem_enable=0; S_task_gate=1;
        wait(S_r_O_mem_valid[0]); @(negedge S_host_clk); S_host_run=0;
        repeat(12) begin @(negedge S_video_clk); if(S_c_O_prepare_done_valid) fail("host stop invented line completion"); end
        S_host_run=1; S_mem_enable=3; S_wrong_line=1;
        wait(S_r_O_line_valid);
        repeat(8) begin @(negedge S_video_clk); if(S_c_O_line_ready || S_c_O_prepare_done_valid) fail("wrong line identity retired task"); end
        S_wrong_line=0; prepared(3);
        if(S_c_O_owned_banks!==2 || S_r_O_bank_reserved[3:2]!=0) fail("cancel started unpresented second source");
        S_release_gate=0;
        @(negedge S_video_clk); S_c_I_retire_epoch=8; S_c_I_retire_tag=16'hca08; S_c_I_retire_valid=1;
        @(posedge S_video_clk); while(!S_c_O_retire_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_c_I_retire_valid=0;
        wait(S_c_O_release_valid[0]);
        repeat(8) begin @(negedge S_video_clk); if(S_c_O_retire_done_valid || !S_r_O_bank_valid[1]) fail("release backpressure invented retirement"); end
        @(negedge S_video_clk); S_video_run=0;
        repeat(40) @(negedge S_host_clk);
        if(S_c_O_retire_done_valid) fail("video stop invented retirement");
        S_video_run=1; S_release_gate=3;
        wait(S_c_O_retire_done_valid);
        if(S_c_O_retire_error!=0 || S_r_O_bank_valid!==1 || S_old_pixels<10) fail("candidate cleanup damaged old front bank");
        @(negedge S_video_clk); S_c_I_retire_done_ready=1;
        @(negedge S_video_clk); S_c_I_retire_done_ready=0;

        // A real second-source memory error retains first source for cleanup.
        reset_all; fill_old; S_mem_error=1; prepare; prepared(2);
        if(S_c_O_line_error!==3 || S_c_O_memory_error!==9 || S_c_O_owned_banks!==2)
            fail("reader error missing successful sibling obligation");
        retire(0);
        if(S_r_O_bank_valid!==1 || S_c_O_busy) fail("error cleanup did not preserve old front");

        // Snapshot isolation and a single authorized source need only one line.
        reset_all; S_c_I_source_mask=2; S_c_I_first_bank=2;
        S_c_I_source_block=1; S_c_I_authorized=2;
        prepare;
        @(negedge S_video_clk); S_c_I_first_tag=0; S_c_I_first_y=0; S_c_I_tokens=0;
        prepared(0);
        if(S_c_O_owned_banks!==8 || S_r_O_bank_tags[63:48]!==16'hc202 ||
            S_r_O_bank_rows[35:27]!==17 || S_c_O_source_in_use!==2)
            fail("single source snapshot changed under producer");
        retire(0);

        // Invalid configuration issues no tasks and still needs matched cleanup.
        reset_all; S_c_I_first_y={9'd17,9'd480}; prepare; prepared(1);
        if(S_c_O_claim_banks!=0 || S_c_O_owned_banks!=0 || S_r_O_bank_reserved!=0)
            fail("invalid configuration acquired banks");
        retire(0);

        // A pulse after publication leaves the frozen result but blocks takeover.
        reset_all; prepare;
        wait(S_c_O_prepare_done_valid);
        @(negedge S_video_clk); S_c_I_prepare_abort=1;
        @(negedge S_video_clk); S_c_I_prepare_abort=0;
        prepared(0); S_c_I_adopt_epoch=8; S_c_I_adopt_tag=16'hca08; S_c_I_claimed_banks=10;
        #1; if(S_c_O_adopt_ready) fail("late cancel pulse forgotten before takeover");
        S_c_I_claimed_banks=0; retire(0);

        // Authority loss is latched independently of a frozen success result.
        reset_all; prepare; prepared(0);
        @(negedge S_video_clk); S_c_I_authorized=2;
        @(negedge S_video_clk); S_c_I_authorized=3;
        S_c_I_adopt_epoch=8; S_c_I_adopt_tag=16'hca08; S_c_I_claimed_banks=10;
        #1; if(S_c_O_adopt_ready || S_c_O_prepare_error!=0) fail("late authority loss forgotten or rewrote result");
        S_c_I_claimed_banks=0; retire(0);

        // No prepare handshake happened: commit's pre-prepare cancel has no banks.
        reset_all; retire(0);
        if(S_c_O_busy || S_c_O_owned_banks!=0 || S_r_O_bank_reserved!=0) fail("unstarted candidate invented obligation");

        // Reserved targets wait; blocked pending does not violate a reservation.
        reset_all; fill_old; S_c_I_first_bank=2;
        @(negedge S_video_clk); S_c_I_prepare_valid=1;
        repeat(8) begin @(negedge S_video_clk); if(S_c_O_prepare_ready || S_c_O_task_valid) fail("occupied target bank stolen"); end
        S_c_I_source_block=1;
        #1; if(S_c_O_source_in_use!=0 || S_c_O_prepare_ready) fail("blocked pending entered source");
        S_c_I_prepare_valid=0;

        // A changed owned identity is uncertainty: no stale release or reuse.
        reset_all; prepare; prepared(0); S_corrupt_bank=2;
        retire(4);
        if(!S_c_O_quarantined || !S_c_O_contract_fault || S_c_O_prepare_ready ||
            S_c_O_owned_banks!==10 || S_c_O_release_valid!=0) fail("lost bank proof silently released ownership");
        // Once a release is presented, even a later proof fault cannot withdraw
        // it. Drain that command and report uncertainty without fake ownership.
        reset_all; prepare; prepared(0); S_release_gate=0;
        @(negedge S_video_clk); S_c_I_retire_epoch=8; S_c_I_retire_tag=16'hca09; S_c_I_retire_valid=1;
        repeat(5) begin @(negedge S_video_clk); if(S_c_O_retire_ready || S_c_O_release_valid!=0)
            fail("wrong retire identity consumed candidate"); end
        S_c_I_retire_tag=16'hca08;
        @(posedge S_video_clk); while(!S_c_O_retire_ready) @(posedge S_video_clk);
        @(negedge S_video_clk); S_c_I_retire_valid=0;
        wait(S_c_O_release_valid==3);
        @(negedge S_video_clk); S_corrupt_bank=2;
        repeat(5) begin @(negedge S_video_clk); if(S_c_O_release_valid!=3 || S_c_O_retire_done_valid)
            fail("late proof fault withdrew held release"); end
        S_release_gate=3;
        wait(S_c_O_retire_done_valid); #1;
        if(S_c_O_retire_error!==4 || !S_c_O_quarantined || S_c_O_owned_banks!==2 || S_c_O_release_valid!=0)
            fail("late proof fault invented successful retirement");
        @(negedge S_video_clk); S_c_I_retire_done_ready=1;
        @(negedge S_video_clk); S_c_I_retire_done_ready=0;
        if(S_c_O_prepare_ready) fail("quarantine accepted another prepare");
        reset_all;
        if(S_c_O_quarantined || !S_c_O_prepare_ready) fail("global reset recovery");
        S_test_pass=1; $display("PASS: candidate true reader preparation/cancel/drain/bank retirement/takeover endpoints"); $finish;
    end
endmodule
