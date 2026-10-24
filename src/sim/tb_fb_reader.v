`timescale 1ns/1ps
// Explicit logical memory endpoints; no physical SDRAM assumptions.
module tb_fb_reader;
    reg S_I_host_clk=0;
    reg S_I_video_clk=0;
    reg S_I_async_reset=0;
    reg [1:0] S_I_lease_valid=0;
    reg [5:0] S_I_lease_slot=0;
    reg [63:0] S_I_lease_token=0;
    reg [63:0] S_I_lease_generation=0;
    reg S_I_task_valid=0;
    wire S_O_task_ready;
    reg [2:0] S_I_task_slot=0;
    reg [20:0] S_I_task_base=0;
    reg [8:0] S_I_task_y=0;
    reg S_I_task_bank=0;
    reg [31:0] S_I_task_token=0;
    reg [31:0] S_I_task_generation=0;
    reg [31:0] S_I_task_epoch=0;
    reg [31:0] S_I_task_deadline=0;
    reg [15:0] S_I_task_tag=0;
    wire S_O_line_valid;
    reg S_I_line_ready=0;
    wire [3:0] S_O_line_error;
    wire [3:0] S_O_line_memory_error;
    wire [2:0] S_O_line_slot;
    wire [20:0] S_O_line_base;
    wire [8:0] S_O_line_y;
    wire S_O_line_bank;
    wire [31:0] S_O_line_token;
    wire [31:0] S_O_line_generation;
    wire [31:0] S_O_line_epoch;
    wire [31:0] S_O_line_deadline;
    wire [15:0] S_O_line_tag;
    wire [9:0] S_O_line_accepted;
    wire [9:0] S_O_line_retired;
    reg [1:0] S_I_read_valid=0;
    wire [1:0] S_O_read_ready;
    reg [1:0] S_I_read_bank=0;
    reg [19:0] S_I_read_x=0;
    wire [1:0] S_O_pixel_valid;
    wire [63:0] S_O_rgba;
    wire [1:0] S_O_pixel_bank;
    wire [19:0] S_O_pixel_x;
    wire [63:0] S_O_pixel_token;
    wire [63:0] S_O_pixel_generation;
    wire [63:0] S_O_pixel_epoch;
    wire [31:0] S_O_pixel_tag;
    reg [1:0] S_I_release_valid=0;
    wire [1:0] S_O_release_ready;
    reg [1:0] S_I_release_bank=0;
    reg [63:0] S_I_release_token=0;
    reg [63:0] S_I_release_generation=0;
    reg [63:0] S_I_release_epoch=0;
    reg [31:0] S_I_release_tag=0;
    wire [3:0] S_O_bank_valid;
    wire [3:0] S_O_bank_reserved;
    wire [11:0] S_O_bank_slots;
    wire [35:0] S_O_bank_rows;
    wire [127:0] S_O_bank_tokens;
    wire [127:0] S_O_bank_generations;
    wire [127:0] S_O_bank_epochs;
    wire [63:0] S_O_bank_tags;
    reg [1:0] S_I_retire_request=0;
    wire [1:0] S_O_retire_ack;
    wire [1:0] S_O_host_retired;
    wire [1:0] S_O_host_busy;
    wire [1:0] S_O_host_tag_exhausted;
    wire [1:0] S_O_release_discarded;
    wire [1:0] S_O_event_discarded;
    wire [1:0] S_O_response_discarded;
    wire [1:0] S_O_mem_valid;
    wire [1:0] S_I_mem_ready;
    wire [41:0] S_O_mem_addr;
    wire [63:0] S_O_mem_tag;
    wire [63:0] S_O_mem_token;
    wire [63:0] S_O_mem_generation;
    wire [63:0] S_O_mem_deadline;
    wire [1:0] S_I_mem_valid;
    wire [1:0] S_O_mem_ready;
    wire [63:0] S_I_mem_data;
    wire [63:0] S_I_mem_tag;
    wire [63:0] S_I_mem_token;
    wire [63:0] S_I_mem_generation;
    wire [7:0] S_I_mem_error;
    reg S_I_task_source=0;
    wire S_O_line_source;
    fb_reader u_dut (
        .I_host_clk(S_I_host_clk),
        .I_video_clk(S_I_video_clk),
        .I_async_reset(S_I_async_reset),
        .I_lease_valid(S_I_lease_valid),
        .I_lease_slot(S_I_lease_slot),
        .I_lease_token(S_I_lease_token),
        .I_lease_generation(S_I_lease_generation),
        .I_task_valid(S_I_task_valid),
        .O_task_ready(S_O_task_ready),
        .I_task_slot(S_I_task_slot),
        .I_task_base(S_I_task_base),
        .I_task_y(S_I_task_y),
        .I_task_bank(S_I_task_bank),
        .I_task_token(S_I_task_token),
        .I_task_generation(S_I_task_generation),
        .I_task_epoch(S_I_task_epoch),
        .I_task_deadline(S_I_task_deadline),
        .I_task_tag(S_I_task_tag),
        .O_line_valid(S_O_line_valid),
        .I_line_ready(S_I_line_ready),
        .O_line_error(S_O_line_error),
        .O_line_memory_error(S_O_line_memory_error),
        .O_line_slot(S_O_line_slot),
        .O_line_base(S_O_line_base),
        .O_line_y(S_O_line_y),
        .O_line_bank(S_O_line_bank),
        .O_line_token(S_O_line_token),
        .O_line_generation(S_O_line_generation),
        .O_line_epoch(S_O_line_epoch),
        .O_line_deadline(S_O_line_deadline),
        .O_line_tag(S_O_line_tag),
        .O_line_accepted(S_O_line_accepted),
        .O_line_retired(S_O_line_retired),
        .I_read_valid(S_I_read_valid),
        .O_read_ready(S_O_read_ready),
        .I_read_bank(S_I_read_bank),
        .I_read_x(S_I_read_x),
        .O_pixel_valid(S_O_pixel_valid),
        .O_rgba(S_O_rgba),
        .O_pixel_bank(S_O_pixel_bank),
        .O_pixel_x(S_O_pixel_x),
        .O_pixel_token(S_O_pixel_token),
        .O_pixel_generation(S_O_pixel_generation),
        .O_pixel_epoch(S_O_pixel_epoch),
        .O_pixel_tag(S_O_pixel_tag),
        .I_release_valid(S_I_release_valid),
        .O_release_ready(S_O_release_ready),
        .I_release_bank(S_I_release_bank),
        .I_release_token(S_I_release_token),
        .I_release_generation(S_I_release_generation),
        .I_release_epoch(S_I_release_epoch),
        .I_release_tag(S_I_release_tag),
        .O_bank_valid(S_O_bank_valid),
        .O_bank_reserved(S_O_bank_reserved),
        .O_bank_slots(S_O_bank_slots),
        .O_bank_rows(S_O_bank_rows),
        .O_bank_tokens(S_O_bank_tokens),
        .O_bank_generations(S_O_bank_generations),
        .O_bank_epochs(S_O_bank_epochs),
        .O_bank_tags(S_O_bank_tags),
        .I_retire_request(S_I_retire_request),
        .O_retire_ack(S_O_retire_ack),
        .O_host_retired(S_O_host_retired),
        .O_host_busy(S_O_host_busy),
        .O_host_tag_exhausted(S_O_host_tag_exhausted),
        .O_release_discarded(S_O_release_discarded),
        .O_event_discarded(S_O_event_discarded),
        .O_response_discarded(S_O_response_discarded),
        .O_mem_valid(S_O_mem_valid),
        .I_mem_ready(S_I_mem_ready),
        .O_mem_addr(S_O_mem_addr),
        .O_mem_tag(S_O_mem_tag),
        .O_mem_token(S_O_mem_token),
        .O_mem_generation(S_O_mem_generation),
        .O_mem_deadline(S_O_mem_deadline),
        .I_mem_valid(S_I_mem_valid),
        .O_mem_ready(S_O_mem_ready),
        .I_mem_data(S_I_mem_data),
        .I_mem_tag(S_I_mem_tag),
        .I_mem_token(S_I_mem_token),
        .I_mem_generation(S_I_mem_generation),
        .I_mem_error(S_I_mem_error),
        .I_task_source(S_I_task_source),
        .O_line_source(S_O_line_source)
    );
    reg S_test_pass=0;
    reg S_host_run=1,S_video_run=1;
    integer S_case=0;
    always #4 if(S_host_run) S_I_host_clk=~S_I_host_clk;
    always #20 if(S_video_run) S_I_video_clk=~S_I_video_clk;
    task fail;
        input [767:0] message;
        begin $display("FAIL: reader case %0d: %0s",S_case,message); $stop; end
    endtask
    initial begin #20000000; fail("watchdog timeout"); end
    wire [1:0] S_allow_return;
    reg [1:0] S_allow_commands=3,S_returns=3,S_faults=0;
    assign S_allow_return=S_returns;
    genvar g;
    generate for(g=0;g<2;g=g+1) begin: GEN_MEMORY
        tb_fb_reader_memory #(.SOURCE(g)) u_memory (
            .I_clk(S_I_host_clk),.I_reset(S_I_async_reset),.I_allow(S_allow_commands[g]),.I_return(S_allow_return[g]),
            .I_fault(S_faults[g]),.I_valid(S_O_mem_valid[g]),.O_ready(S_I_mem_ready[g]),
            .I_addr(S_O_mem_addr[g*21+:21]),.I_tag(S_O_mem_tag[g*32+:32]),
            .I_deadline(S_O_mem_deadline[g*32+:32]),
            .I_token(S_O_mem_token[g*32+:32]),.I_generation(S_O_mem_generation[g*32+:32]),
            .O_valid(S_I_mem_valid[g]),.I_ready(S_O_mem_ready[g]),.O_data(S_I_mem_data[g*32+:32]),
            .O_tag(S_I_mem_tag[g*32+:32]),.O_token(S_I_mem_token[g*32+:32]),
            .O_generation(S_I_mem_generation[g*32+:32]),.O_error(S_I_mem_error[g*4+:4])
        );
    end endgenerate
    task reset_all;
        begin
            @(negedge S_I_video_clk); S_I_async_reset=1; S_I_task_valid=0; S_I_line_ready=0;
            S_I_read_valid=0; S_I_release_valid=0; S_I_retire_request=0;
            S_I_lease_valid=3; S_I_lease_slot={3'd1,3'd0};
            S_I_lease_token={32'hbb123,32'haa123}; S_I_lease_generation={32'd8,32'd7};
            S_allow_commands=3; S_returns=3; S_faults=0;
            repeat(4) @(negedge S_I_video_clk); S_I_async_reset=0;
            repeat(5) @(negedge S_I_video_clk);
        end
    endtask
    task issue;
        input source,bank;
        input [8:0] row;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_video_clk); S_I_task_valid=1; S_I_task_source=source;
            S_I_task_slot=source ? 1 : 0; S_I_task_base=source ? 21'h04b000 : 0;
            S_I_task_y=row; S_I_task_bank=bank; S_I_task_token=source ? 32'hbb123 : 32'haa123;
            S_I_task_generation=source ? 8 : 7; S_I_task_epoch=source ? 102 : 101;
            S_I_task_deadline=source ? 5000 : 4000; S_I_task_tag=tag;
            @(posedge S_I_video_clk); while(!S_O_task_ready) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_I_task_valid=0;
        end
    endtask
    task take_line;
        input source,bank;
        input [8:0] row;
        input [15:0] tag;
        input [3:0] error;
        reg [206:0] saved;
        begin
            wait(S_O_line_valid); #1;
            if(S_O_line_source!==source || S_O_line_bank!==bank || S_O_line_y!==row || S_O_line_tag!==tag ||
                S_O_line_error!==error || S_O_line_slot!==(source ? 3'd1 : 3'd0) ||
                S_O_line_token!==(source ? 32'hbb123 : 32'haa123) ||
                S_O_line_generation!==(source ? 32'd8 : 32'd7) ||
                S_O_line_epoch!==(source ? 32'd102 : 32'd101) ||
                (error==0 && (S_O_line_accepted!==640 || S_O_line_retired!==640))) fail("dual source result route");
            saved={S_O_line_source,S_O_line_error,S_O_line_memory_error,S_O_line_slot,S_O_line_base,S_O_line_y,
                S_O_line_bank,S_O_line_token,S_O_line_generation,S_O_line_epoch,S_O_line_deadline,
                S_O_line_tag,S_O_line_accepted,S_O_line_retired};
            repeat(5) begin @(negedge S_I_video_clk);
                if(!S_O_line_valid || saved!=={S_O_line_source,S_O_line_error,S_O_line_memory_error,S_O_line_slot,
                    S_O_line_base,S_O_line_y,S_O_line_bank,S_O_line_token,S_O_line_generation,S_O_line_epoch,
                    S_O_line_deadline,S_O_line_tag,S_O_line_accepted,S_O_line_retired}) fail("result selection preempted under backpressure"); end
            S_I_line_ready=1; @(negedge S_I_video_clk); S_I_line_ready=0;
        end
    endtask
    task read_both;
        input bank;
        input integer row_a,row_b;
        input [15:0] tag_a,tag_b;
        integer x;
        reg [31:0] expect_a,expect_b;
        begin
            for(x=0;x<640;x=x+1) begin
                @(negedge S_I_video_clk); S_I_read_valid=3; S_I_read_bank={bank,bank}; S_I_read_x={10'd0,10'd0};
                S_I_read_x[9:0]=x; S_I_read_x[19:10]=639-x;
                @(posedge S_I_video_clk); if(S_O_read_ready!==3) fail("parallel read unavailable");
                expect_a=32'h34560000^(row_a*640+x);
                expect_b=32'h34570000^(21'h04b000+row_b*640+639-x);
                #1; if(S_O_pixel_valid!==3 || S_O_rgba!=={expect_b,expect_a} ||
                    S_O_pixel_tag!=={tag_b,tag_a} || S_O_pixel_generation!=={32'd8,32'd7} ||
                    S_O_pixel_epoch!=={32'd102,32'd101} || S_O_pixel_token!=={32'hbb123,32'haa123}) fail("parallel pixel/identity mixup");
            end
            @(negedge S_I_video_clk); S_I_read_valid=0;
        end
    endtask
    task release_a;
        input bank;
        input [15:0] tag;
        begin
            @(negedge S_I_video_clk); S_I_release_valid=1; S_I_release_bank[0]=bank;
            S_I_release_token[31:0]=32'haa123; S_I_release_generation[31:0]=7;
            S_I_release_epoch[31:0]=101; S_I_release_tag[15:0]=tag;
            @(posedge S_I_video_clk); while(!S_O_release_ready[0]) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_I_release_valid=0;
        end
    endtask
    integer x,before_a,before_b;
    initial begin
        reset_all;
        issue(0,0,10,1); issue(1,0,20,2);
        // Both completions are ready before either is accepted by the shared result consumer.
        wait(u_dut.S_line_valid==3);
        take_line(0,0,10,1,0); take_line(1,0,20,2,0);
        before_a=GEN_MEMORY[0].u_memory.S_accepted; before_b=GEN_MEMORY[1].u_memory.S_accepted;
        read_both(0,10,20,1,2); read_both(0,10,20,1,2);
        if(before_a!=GEN_MEMORY[0].u_memory.S_accepted || before_b!=GEN_MEMORY[1].u_memory.S_accepted)
            fail("cache reuse generated storage reads");

        issue(0,1,11,3); issue(1,1,21,4);
        // Previous accepted source was B, so round-robin chooses A for the next pair.
        wait(u_dut.S_line_valid==3); take_line(0,1,11,3,0); take_line(1,1,21,4,0);
        read_both(1,11,21,3,4);
        release_a(0,16'hffff); if(!S_O_bank_valid[0]) fail("old release invalidated current A row");
        release_a(0,1);
        S_returns[0]=0; issue(0,0,12,5);
        wait(GEN_MEMORY[0].u_memory.S_pending>=3);
        @(negedge S_I_video_clk); S_I_retire_request=1;
        // B keeps scanning its complete row while A cancels and retires real reads.
        fork
            begin
                for(x=0;x<128;x=x+1) begin
                    @(negedge S_I_video_clk); S_I_read_valid=2; S_I_read_bank=2;
                    S_I_read_x[19:10]=x;
                    @(posedge S_I_video_clk); #1;
                    if(S_O_pixel_valid!==2 || S_O_rgba[63:32]!==(32'h34570000^(21'h04b000+21*640+x)))
                        fail("retiring A disrupted B scanout");
                end
                @(negedge S_I_video_clk); S_I_read_valid=0;
            end
            begin
                repeat(8) @(negedge S_I_video_clk);
                if(S_O_retire_ack[0] || S_O_host_retired[0]) fail("retired A before real responses");
                S_returns[0]=1; wait(S_O_retire_ack[0]);
                if(S_O_retire_ack[1] || S_O_bank_valid[1:0]!=0 || S_O_bank_valid[3:2]!=3) fail("per-source retirement isolation");
            end
        join
        @(negedge S_I_video_clk); S_I_retire_request=0;
        wait(!S_O_retire_ack[0]); wait(!S_O_host_retired[0]);
        issue(0,0,13,6); take_line(0,0,13,6,0);
        // B is independently retired/rearmed; its next memory error leaves A intact.
        @(negedge S_I_video_clk); S_I_retire_request=2; wait(S_O_retire_ack[1]);
        @(negedge S_I_video_clk); S_I_retire_request=0; wait(!S_O_retire_ack[1]); wait(!S_O_host_retired[1]);
        S_faults=2; issue(1,0,22,7); take_line(1,0,22,7,3);
        if(S_O_line_memory_error!==9 || S_O_bank_valid[2] || !S_O_bank_valid[0]) fail("B storage error corrupted A");
        @(negedge S_I_video_clk); S_I_retire_request=3;
        wait(S_O_retire_ack==3); if(S_O_host_retired!==3) fail("dual retirement barrier");
        @(negedge S_I_video_clk); S_I_retire_request=0; wait(S_O_retire_ack==0);
        S_test_pass=1; $display("PASS: fb_reader dual-source RTL / cache / CDC protocol preparation"); $finish;
    end
endmodule

// Variable-latency queued logical memory endpoint. Not a device implementation.
module tb_fb_reader_memory #(parameter integer SOURCE=0) (
    input wire I_clk,I_reset,I_allow,I_return,I_fault,I_valid,
    output wire O_ready,
    input wire [20:0] I_addr,
    input wire [31:0] I_tag,I_token,I_generation,I_deadline,
    output reg O_valid,
    input wire I_ready,
    output reg [31:0] O_data,O_tag,O_token,O_generation,
    output reg [3:0] O_error
);
    reg [20:0] S_addrs[0:15];
    reg [31:0] S_tags[0:15],S_tokens[0:15],S_gens[0:15];
    reg S_fault[0:15];
    integer S_head=0,S_tail=0,S_pending=0,S_accepted=0,S_returned=0,S_cycle=0;
    assign O_ready=!I_reset && I_allow && S_pending<16 && S_cycle%(SOURCE+3)!=0;
    always @(posedge I_clk) begin
        if(I_reset) begin
            O_valid<=0; O_data<=0; O_tag<=0; O_token<=0; O_generation<=0; O_error<=0;
            S_head=0; S_tail=0; S_pending=0; S_accepted=0; S_returned=0; S_cycle<=0;
        end else begin
            S_cycle<=S_cycle+1;
            if(I_valid && O_ready) begin
                if(I_deadline!==(SOURCE==0 ? 32'd4000 : 32'd5000)) begin
                    $display("FAIL: memory client deadline route"); $stop;
                end
                S_addrs[S_tail]=I_addr; S_tags[S_tail]=I_tag; S_tokens[S_tail]=I_token;
                S_gens[S_tail]=I_generation; S_fault[S_tail]=I_fault;
                S_tail=(S_tail+1)%16; S_pending=S_pending+1; S_accepted=S_accepted+1;
            end
            if(O_valid && I_ready) begin
                O_valid<=0; S_head=(S_head+1)%16; S_pending=S_pending-1; S_returned=S_returned+1;
            end
            if(!O_valid && S_pending>0 && I_return && S_cycle%(SOURCE+2)==0) begin
                O_valid<=1; O_data<=(32'h34560000^(SOURCE<<16))^S_addrs[S_head];
                O_tag<=S_tags[S_head]; O_token<=S_tokens[S_head]; O_generation<=S_gens[S_head];
                O_error<=S_fault[S_head] ? 4'd9 : 4'd0;
            end
        end
    end
endmodule
