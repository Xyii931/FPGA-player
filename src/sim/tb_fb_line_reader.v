`timescale 1ns/1ps
// Explicit logical memory endpoints; no physical SDRAM assumptions.
module tb_fb_line_reader;
    reg S_I_host_clk=0;
    reg S_I_video_clk=0;
    reg S_I_async_reset=0;
    reg S_I_lease_valid=0;
    reg [2:0] S_I_lease_slot=0;
    reg [31:0] S_I_lease_token=0;
    reg [31:0] S_I_lease_generation=0;
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
    reg S_I_read_valid=0;
    wire S_O_read_ready;
    reg S_I_read_bank=0;
    reg [9:0] S_I_read_x=0;
    wire S_O_pixel_valid;
    wire [31:0] S_O_rgba;
    wire S_O_pixel_bank;
    wire [9:0] S_O_pixel_x;
    wire [31:0] S_O_pixel_token;
    wire [31:0] S_O_pixel_generation;
    wire [31:0] S_O_pixel_epoch;
    wire [15:0] S_O_pixel_tag;
    reg S_I_release_valid=0;
    wire S_O_release_ready;
    reg S_I_release_bank=0;
    reg [31:0] S_I_release_token=0;
    reg [31:0] S_I_release_generation=0;
    reg [31:0] S_I_release_epoch=0;
    reg [15:0] S_I_release_tag=0;
    wire [1:0] S_O_bank_valid;
    wire [1:0] S_O_bank_reserved;
    wire [5:0] S_O_bank_slots;
    wire [17:0] S_O_bank_rows;
    wire [63:0] S_O_bank_tokens;
    wire [63:0] S_O_bank_generations;
    wire [63:0] S_O_bank_epochs;
    wire [31:0] S_O_bank_tags;
    reg S_I_retire_request=0;
    wire S_O_retire_ack;
    wire S_O_host_retired;
    wire S_O_host_busy;
    wire S_O_host_tag_exhausted;
    wire S_O_release_discarded;
    wire S_O_event_discarded;
    wire S_O_response_discarded;
    wire S_O_mem_valid;
    wire S_I_mem_ready;
    wire [20:0] S_O_mem_addr;
    wire [31:0] S_O_mem_tag;
    wire [31:0] S_O_mem_token;
    wire [31:0] S_O_mem_generation;
    wire [31:0] S_O_mem_deadline;
    reg S_I_mem_valid=0;
    wire S_O_mem_ready;
    reg [31:0] S_I_mem_data=0;
    reg [31:0] S_I_mem_tag=0;
    reg [31:0] S_I_mem_token=0;
    reg [31:0] S_I_mem_generation=0;
    reg [3:0] S_I_mem_error=0;
    fb_line_reader u_dut (
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
        .I_mem_error(S_I_mem_error)
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
    reg S_allow_commands=1,S_allow_responses=1;
    reg [1:0] S_inject=0;
    reg S_injected=0,S_real_response=0;
    reg [31:0] S_qaddr[0:15],S_qtag[0:15],S_qtoken[0:15],S_qgen[0:15];
    integer S_head=0,S_tail=0,S_pending=0,S_cycles=0,S_commands=0,S_responses=0,S_discarded=0;
    reg [31:0] S_last_tag=0;
    reg S_held=0;
    reg [148:0] S_saved_cmd;
    wire S_small_pass;
    tb_fb_line_reader_tags u_small_test (.O_pass(S_small_pass));
    assign S_I_mem_ready=S_allow_commands && S_cycles%4!=0;
    always @(posedge S_I_host_clk) begin
        if(S_I_async_reset) begin
            S_I_mem_valid<=0; S_head=0; S_tail=0; S_pending=0; S_cycles<=0;
            S_commands=0; S_responses=0; S_last_tag=0; S_injected<=0; S_discarded=0; S_held<=0;
        end else begin
            S_cycles<=S_cycles+1;
            if(S_O_response_discarded) S_discarded=S_discarded+1;
            if(S_O_mem_valid && S_I_mem_ready) begin
                if(S_last_tag>=S_O_mem_tag || S_pending>=8) fail("read tag monotonicity / outstanding bound");
                if(S_O_mem_deadline!==123456 || S_O_mem_token!==32'hd123 || S_O_mem_generation!==7)
                    fail("memory command lost deadline / lease snapshot");
                S_last_tag=S_O_mem_tag;
                S_qaddr[S_tail]=S_O_mem_addr; S_qtag[S_tail]=S_O_mem_tag;
                S_qtoken[S_tail]=S_O_mem_token; S_qgen[S_tail]=S_O_mem_generation;
                S_tail=(S_tail+1)%16; S_pending=S_pending+1; S_commands=S_commands+1;
            end
            if(S_I_mem_valid && S_O_mem_ready) begin
                S_I_mem_valid<=0;
                if(S_real_response) begin S_head=(S_head+1)%16; S_pending=S_pending-1; S_responses=S_responses+1; end
            end
            if(!S_I_mem_valid && S_pending>0 && S_allow_responses && S_cycles%3!=0) begin
                S_I_mem_valid<=1; S_I_mem_tag<=S_qtag[S_head]; S_I_mem_token<=S_qtoken[S_head];
                S_I_mem_generation<=S_qgen[S_head]; S_I_mem_data<=32'h12340000^S_qaddr[S_head];
                S_I_mem_error<=0; S_real_response<=1;
                if(S_inject!=0 && !S_injected) begin
                    S_injected<=1;
                    case(S_inject)
                        1:begin S_I_mem_token<=S_qtoken[S_head]+1; S_real_response<=0; end
                        2:begin S_I_mem_tag<=S_qtag[S_head]+1; S_real_response<=0; end
                        3:S_I_mem_error<=7;
                    endcase
                end
            end
            if(S_held && (!S_O_mem_valid || S_saved_cmd!=={S_O_mem_addr,S_O_mem_tag,S_O_mem_token,
                S_O_mem_generation,S_O_mem_deadline})) fail("presented read withdrawn/changed");
            S_held<=S_O_mem_valid && !S_I_mem_ready;
            S_saved_cmd<={S_O_mem_addr,S_O_mem_tag,S_O_mem_token,S_O_mem_generation,S_O_mem_deadline};
        end
    end
    task reset_all;
        begin
            S_host_run=1; S_video_run=1;
            @(negedge S_I_video_clk); S_I_async_reset=1; S_I_task_valid=0; S_I_read_valid=0;
            S_I_release_valid=0; S_I_retire_request=0; S_I_line_ready=0;
            S_I_lease_valid=1; S_I_lease_slot=0; S_I_lease_token=32'hd123; S_I_lease_generation=7;
            S_allow_commands=1; S_allow_responses=1; S_inject=0;
            repeat(4) @(negedge S_I_video_clk); S_I_async_reset=0;
            repeat(5) @(negedge S_I_video_clk);
        end
    endtask
    task issue;
        input bank;
        input [8:0] row;
        input [15:0] tag;
        begin
            S_case=S_case+1;
            @(negedge S_I_video_clk); S_I_task_valid=1; S_I_task_slot=0; S_I_task_base=0;
            S_I_task_y=row; S_I_task_bank=bank; S_I_task_token=32'hd123; S_I_task_generation=7;
            S_I_task_epoch=9; S_I_task_deadline=123456; S_I_task_tag=tag;
            @(posedge S_I_video_clk); while(!S_O_task_ready) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_I_task_valid=0;
            // All request fields must already have crossed in the accepted snapshot.
            S_I_task_y=400; S_I_task_epoch=99; S_I_task_tag=16'hffff; S_I_task_deadline=0;
        end
    endtask
    task line_result;
        input [3:0] error;
        input bank;
        input [8:0] row;
        input [15:0] tag;
        reg [205:0] saved;
        begin
            wait(S_O_line_valid); #1;
            if(S_O_line_error!==error || S_O_line_slot!==0 || S_O_line_base!==0 || S_O_line_y!==row ||
                S_O_line_bank!==bank || S_O_line_tag!==tag || S_O_line_epoch!==9 || S_O_line_token!==32'hd123 ||
                S_O_line_generation!==7 || S_O_line_deadline!==123456 || S_O_line_accepted!==S_O_line_retired ||
                (error==0 && S_O_line_retired!==640)) fail("line result identity/counts/error");
            if(S_O_bank_valid[bank]) fail("line published before result consumption");
            saved={S_O_line_error,S_O_line_memory_error,S_O_line_slot,S_O_line_base,S_O_line_y,S_O_line_bank,
                S_O_line_token,S_O_line_generation,S_O_line_epoch,S_O_line_deadline,S_O_line_tag,S_O_line_accepted,S_O_line_retired};
            repeat(4) begin @(negedge S_I_video_clk);
                if(!S_O_line_valid || saved!=={S_O_line_error,S_O_line_memory_error,S_O_line_slot,S_O_line_base,
                    S_O_line_y,S_O_line_bank,S_O_line_token,S_O_line_generation,S_O_line_epoch,S_O_line_deadline,
                    S_O_line_tag,S_O_line_accepted,S_O_line_retired}) fail("line result changed under backpressure"); end
            S_I_line_ready=1; @(negedge S_I_video_clk); S_I_line_ready=0;
            if(S_O_bank_valid[bank] !== (error==0)) fail("failed/valid bank publication");
        end
    endtask
    task read_row;
        input bank;
        input [8:0] row;
        input [15:0] tag;
        integer x;
        begin
            for(x=0;x<640;x=x+1) begin
                @(negedge S_I_video_clk); S_I_read_valid=1; S_I_read_bank=bank; S_I_read_x=x;
                @(posedge S_I_video_clk); if(!S_O_read_ready) fail("owned complete bank not readable");
                #1; if(!S_O_pixel_valid || S_O_rgba!==(32'h12340000^(row*640+x)) || S_O_pixel_x!==x ||
                    S_O_pixel_bank!==bank || S_O_pixel_token!==32'hd123 || S_O_pixel_generation!==7 ||
                    S_O_pixel_epoch!==9 || S_O_pixel_tag!==tag) fail("synchronous line pixel/data/identity");
            end
            @(negedge S_I_video_clk); S_I_read_valid=0;
        end
    endtask
    task release_bank;
        input bank;
        input [15:0] tag;
        begin
            @(negedge S_I_video_clk); S_I_release_valid=1; S_I_release_bank=bank;
            S_I_release_token=32'hd123; S_I_release_generation=7; S_I_release_epoch=9; S_I_release_tag=tag;
            @(posedge S_I_video_clk); while(!S_O_release_ready) @(posedge S_I_video_clk);
            @(negedge S_I_video_clk); S_I_release_valid=0;
        end
    endtask
    task retire;
        begin
            @(negedge S_I_video_clk); S_I_retire_request=1;
            wait(S_O_retire_ack);
            if(!S_O_host_retired || S_pending!=0 || S_O_bank_valid!=0 || S_O_pixel_valid) fail("false retirement ack");
            repeat(4) @(negedge S_I_video_clk);
            S_I_retire_request=0; wait(!S_O_retire_ack); wait(!S_O_host_retired);
            repeat(4) @(negedge S_I_video_clk);
        end
    endtask
    integer before_reads;
    initial begin
        reset_all; S_inject=1; issue(0,21,1);
        S_allow_responses=0;
        wait(S_pending==8); repeat(12) @(negedge S_I_host_clk);
        if(S_commands!=8 || S_O_bank_valid!=0 || S_O_line_valid) fail("credit saturation / half-line readable");
        S_allow_responses=1; line_result(0,0,21,1);
        if(S_discarded==0) fail("foreign identity was not discarded");
        read_row(0,21,1); before_reads=S_commands; read_row(0,21,1);
        if(S_commands!=before_reads) fail("cached source row unexpectedly refetched");

        issue(1,479,2); line_result(0,1,479,2); read_row(1,479,2);
        // A release must wait for the previous synchronous pixel to leave the port.
        S_I_release_valid=1; S_I_release_bank=1; S_I_release_token=32'hd123;
        S_I_release_generation=7; S_I_release_epoch=9; S_I_release_tag=2;
        #1; if(S_O_release_ready || S_O_read_ready) fail("released bank with pixel still in flight");
        @(posedge S_I_video_clk); #1; if(!S_O_release_ready) fail("pixel drain did not unblock release");
        @(negedge S_I_video_clk); // Keep valid for the actual following handshake.
        @(negedge S_I_video_clk); S_I_release_valid=0;
        if(S_O_bank_valid[1]) fail("released bank retained permission");
        issue(1,478,12); line_result(0,1,478,12); read_row(1,478,12);
        S_I_task_bank=0; S_I_task_valid=1;
        repeat(4) begin @(negedge S_I_video_clk); if(S_O_task_ready) fail("owned bank overwritten"); end
        S_I_task_valid=0;
        release_bank(0,16'hffff); if(!S_O_bank_valid[0] || !S_O_release_discarded) fail("stale release changed bank");
        release_bank(0,1); issue(0,0,3); line_result(0,0,0,3); read_row(0,0,3);
        read_row(1,478,12); // Other bank survived refill of bank0.
        retire;

        reset_all; S_inject=2; issue(0,4,4); line_result(4,0,4,4);
        if(S_pending!=0 || S_O_bank_reserved[0]) fail("wrong tag falsely drained / failed bank retained");
        reset_all; S_inject=3; issue(0,5,5); line_result(3,0,5,5);
        if(S_O_line_memory_error!==7) fail("raw memory error lost");

        reset_all; S_allow_responses=0; issue(0,6,6); wait(S_pending>=3);
        @(negedge S_I_host_clk); S_I_lease_valid=0;
        repeat(3) @(negedge S_I_host_clk); S_I_lease_valid=1; S_allow_responses=1;
        line_result(2,0,6,6); // A transient withdrawal cannot restore an old task.

        reset_all;
        @(negedge S_I_video_clk); S_I_task_valid=1; S_I_task_slot=0; S_I_task_base=1;
        S_I_task_bank=0; S_I_task_y=0; S_I_task_token=32'hd123; S_I_task_generation=7;
        S_I_task_epoch=9; S_I_task_deadline=123456; S_I_task_tag=7;
        @(posedge S_I_video_clk); while(!S_O_task_ready) @(posedge S_I_video_clk);
        @(negedge S_I_video_clk); S_I_task_valid=0;
        wait(S_O_line_valid); if(S_O_line_error!==1 || S_commands!=0) fail("invalid base issued memory request");
        S_I_line_ready=1; @(negedge S_I_video_clk); S_I_line_ready=0;
        issue(0,480,11); line_result(1,0,480,11);
        if(S_commands!=0) fail("invalid row issued memory request");
        S_I_lease_generation=8; issue(0,10,12); line_result(2,0,10,12);
        if(S_commands!=0) fail("unheld lease issued memory request");

        // Last word of the sixth fixed framebuffer slot, still inside the device.
        reset_all; S_I_lease_slot=5;
        @(negedge S_I_video_clk); S_I_task_valid=1; S_I_task_slot=5; S_I_task_base=21'h177000;
        S_I_task_y=479; S_I_task_bank=0; S_I_task_token=32'hd123; S_I_task_generation=7;
        S_I_task_epoch=9; S_I_task_deadline=123456; S_I_task_tag=15;
        @(posedge S_I_video_clk); while(!S_O_task_ready) @(posedge S_I_video_clk);
        @(negedge S_I_video_clk); S_I_task_valid=0; wait(S_O_line_valid); #1;
        if(S_O_line_error!==0 || S_O_line_slot!==5 || S_O_line_base!==21'h177000 ||
            S_O_line_y!==479 || S_O_line_retired!==640) fail("slot5 last row address");
        S_I_line_ready=1; @(negedge S_I_video_clk); S_I_line_ready=0;
        S_I_read_valid=1; S_I_read_bank=0; S_I_read_x=639;
        @(posedge S_I_video_clk); #1;
        if(!S_O_pixel_valid || S_O_rgba!==(32'h12340000^21'h1c1fff)) fail("slot5 last word");
        @(negedge S_I_video_clk); S_I_read_valid=0; retire;

        // Stop while a command is presented but not accepted. Two tasks precede the barrier.
        reset_all; S_allow_commands=0; issue(0,7,8); issue(1,8,9); wait(S_O_mem_valid);
        @(negedge S_I_video_clk); S_I_retire_request=1;
        wait(u_dut.S_barrier_sent);
        @(negedge S_I_video_clk); S_video_run=0;
        repeat(20) @(negedge S_I_host_clk);
        if(!S_O_mem_valid || S_O_host_retired || S_O_retire_ack) fail("held read was abandoned on stop");
        S_allow_commands=1; wait(S_O_host_retired);
        if(S_pending!=0 || S_O_retire_ack) fail("retirement did not respect stopped video clock");
        S_video_run=1; wait(S_O_retire_ack);
        @(negedge S_I_video_clk); S_I_retire_request=0; wait(!S_O_retire_ack); wait(!S_O_host_retired);
        issue(0,9,10); line_result(0,0,9,10); read_row(0,9,10);

        // Host stopped: a request/barrier must wait, with no timeout shortcut.
        @(negedge S_I_host_clk); S_host_run=0;
        @(negedge S_I_video_clk); S_I_retire_request=1;
        repeat(12) @(negedge S_I_video_clk); if(S_O_retire_ack) fail("retirement without host clock");
        S_host_run=1; wait(S_O_retire_ack);
        @(negedge S_I_video_clk); S_I_retire_request=0; wait(!S_O_retire_ack);
        reset_all; wait(S_small_pass);
        S_test_pass=1; $display("PASS: fb_line_reader logical protocol / ownership / CDC preparation"); $finish;
    end
endmodule

// A deliberately tiny tag space must fail safely, never wrap or clear on retire.
module tb_fb_line_reader_tags (output reg O_pass=0);
    reg S_hclk=0,S_vclk=0,S_reset=0,S_start=0,S_take=0;
    reg [15:0] S_tag=1;
    wire S_ready,S_result,S_command,S_exhausted;
    wire [31:0] S_command_tag;
    wire [3:0] S_error;
    wire [9:0] S_accepted,S_retired;
    always #4 S_hclk=~S_hclk;
    always #20 S_vclk=~S_vclk;
    // This endpoint retires the accepted read on the same host edge.
    fb_line_reader #(.MEM_TAG_BITS(2)) u_small (
        .I_host_clk(S_hclk),
        .I_video_clk(S_vclk),
        .I_async_reset(S_reset),
        .I_lease_valid(1'b1),
        .I_lease_slot(3'd0),
        .I_lease_token(32'd1),
        .I_lease_generation(32'd1),
        .I_task_valid(S_start),
        .O_task_ready(S_ready),
        .I_task_slot(3'd0),
        .I_task_base(21'd0),
        .I_task_y(9'd0),
        .I_task_bank(1'b0),
        .I_task_token(32'd1),
        .I_task_generation(32'd1),
        .I_task_epoch(32'd1),
        .I_task_deadline(32'd0),
        .I_task_tag(S_tag),
        .O_line_valid(S_result),
        .I_line_ready(S_take),
        .O_line_error(S_error),
        .O_line_memory_error(),
        .O_line_slot(),
        .O_line_base(),
        .O_line_y(),
        .O_line_bank(),
        .O_line_token(),
        .O_line_generation(),
        .O_line_epoch(),
        .O_line_deadline(),
        .O_line_tag(),
        .O_line_accepted(S_accepted),
        .O_line_retired(S_retired),
        .I_read_valid(1'b0),
        .O_read_ready(),
        .I_read_bank(1'b0),
        .I_read_x(10'd0),
        .O_pixel_valid(),
        .O_rgba(),
        .O_pixel_bank(),
        .O_pixel_x(),
        .O_pixel_token(),
        .O_pixel_generation(),
        .O_pixel_epoch(),
        .O_pixel_tag(),
        .I_release_valid(1'b0),
        .O_release_ready(),
        .I_release_bank(1'b0),
        .I_release_token(32'd0),
        .I_release_generation(32'd0),
        .I_release_epoch(32'd0),
        .I_release_tag(16'd0),
        .O_bank_valid(),
        .O_bank_reserved(),
        .O_bank_slots(),
        .O_bank_rows(),
        .O_bank_tokens(),
        .O_bank_generations(),
        .O_bank_epochs(),
        .O_bank_tags(),
        .I_retire_request(1'b0),
        .O_retire_ack(),
        .O_host_retired(),
        .O_host_busy(),
        .O_host_tag_exhausted(S_exhausted),
        .O_release_discarded(),
        .O_event_discarded(),
        .O_response_discarded(),
        .O_mem_valid(S_command),
        .I_mem_ready(1'b1),
        .O_mem_addr(),
        .O_mem_tag(S_command_tag),
        .O_mem_token(),
        .O_mem_generation(),
        .O_mem_deadline(),
        .I_mem_valid(S_command),
        .O_mem_ready(),
        .I_mem_data(32'd0),
        .I_mem_tag(S_command_tag),
        .I_mem_token(32'd1),
        .I_mem_generation(32'd1),
        .I_mem_error(4'd0)
    );
    integer S_job;
    initial begin
        S_reset=1; repeat(4) @(negedge S_vclk); S_reset=0;
        for(S_job=0;S_job<3;S_job=S_job+1) begin
            if(S_job==2) begin
                S_reset=1; repeat(4) @(negedge S_vclk); S_reset=0;
            end
            repeat(4) @(negedge S_vclk); S_tag=S_tag+1; S_start=1;
            @(posedge S_vclk); while(!S_ready) @(posedge S_vclk);
            @(negedge S_vclk); S_start=0; wait(S_result); #1;
            if(S_error!==6 || !S_exhausted || S_accepted!==(S_job==1 ? 10'd0 : 10'd3) || S_retired!==S_accepted) begin
                $display("FAIL: tiny reader tag space / drain / reset"); $stop;
            end
            @(negedge S_vclk); S_take=1;
            @(negedge S_vclk); S_take=0; wait(!S_result);
        end
        O_pass=1;
    end
endmodule
