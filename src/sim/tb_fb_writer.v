`timescale 1ns/1ps
// Real writer, explicit queued completion endpoint; no SDRAM latency model.
module tb_fb_writer;
    reg S_clk=0,S_reset=0,S_media_valid=1,S_start=0,S_grant=1,S_abort=0;
    reg [31:0] S_media_generation=9,S_token=1,S_generation=9,S_clear=32'h000000ff;
    reg [15:0] S_tag=1,S_w=1,S_h=1,S_ix=0,S_iy=0;
    reg [1:0] S_op=1,S_rotation=0;
    reg [2:0] S_slot=0;
    reg S_resident=0,S_bottom=0,S_source_expected=1;
    reg S_iv=0,S_ilast=0;
    reg [15:0] S_x=0,S_y=0;
    reg [31:0] S_rgba=0;
    reg S_source_valid=0;
    reg [15:0] S_source_tag=0;
    reg [31:0] S_source_token=0,S_source_generation=0;
    reg [3:0] S_source_error=0;
    reg S_mem_ready=0,S_allow_command=1,S_allow_response=1,S_zero=0;
    reg S_reply_valid=0;
    reg [31:0] S_reply_tag=0,S_reply_token=0,S_reply_generation=0;
    reg [3:0] S_reply_error=0;
    reg [1:0] S_injection=0;
    reg S_done_ready=0,S_check_memory=1;
    wire S_start_ready,S_pixel_ready,S_source_ready,S_cancel,S_mem_valid,S_mem_wr,S_response_ready;
    wire [20:0] S_addr;
    wire [31:0] S_data,S_mem_tag,S_mem_token,S_mem_generation;
    wire [3:0] S_mask,S_error,S_memory_error,S_source_diagnostic;
    wire S_busy,S_done,S_memory_retired,S_producer_retired,S_discard_response,S_discard_source,S_exhausted,S_small_done;
    wire [15:0] S_out_tag;
    wire [2:0] S_out_slot;
    wire [31:0] S_out_token,S_out_generation,S_accepted,S_retired,S_pixels;
    wire S_response_valid=S_injection!=0 || (S_zero ? S_mem_valid && S_mem_ready : S_reply_valid);
    wire [31:0] S_response_tag=S_injection==2 ? S_reply_tag+32'd1000 : (S_zero ? S_mem_tag : S_reply_tag);
    wire [31:0] S_response_token=S_injection==1 ? S_reply_token^32'h80000000 : (S_zero ? S_mem_token : S_reply_token);
    wire [31:0] S_response_generation=S_zero ? S_mem_generation : S_reply_generation;
    wire [3:0] S_response_error=S_zero ? 4'd0 : S_reply_error;
    reg [31:0] S_qtag[0:31],S_qtoken[0:31],S_qgeneration[0:31];
    integer S_qhead=0,S_qtail=0,S_qcount=0,S_cycles=0,S_delay=0;
    integer S_case=0,S_seen=0,S_completed=0,S_fail_at=-1,S_max_pending=0;
    integer S_gw,S_gh,S_gix,S_giy,S_gr,S_gbottom,S_gslot,S_clear_count,S_expected_total,S_a,S_b,S_j,S_k;
    integer S_index,S_u,S_v,S_ex,S_ey,S_expected_addr;
    reg [31:0] S_job_token,S_job_generation,S_background,S_expected_data,S_last_mem_tag=0;
    reg [15:0] S_job_tag;
    reg S_waiting=0;
    reg [152:0] S_mem_saved;
    reg [190:0] S_saved_result;
    reg S_test_pass=0;
    always #4 S_clk=~S_clk;
    fb_writer u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(S_media_valid),.I_media_generation(S_media_generation),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.I_lease_grant(S_grant),.I_op(S_op),.I_slot(S_slot),
        .I_lease_token(S_token),.I_generation(S_generation),.I_tag(S_tag),.I_resident(S_resident),.I_clear_rgba(S_clear),
        .I_pre_width(S_w),.I_pre_height(S_h),.I_image_x(S_ix),.I_image_y(S_iy),.I_rotation(S_rotation),
        .I_bottom_up(S_bottom),.I_source_expected(S_source_expected),.I_abort(S_abort),
        .I_pixel_valid(S_iv),.O_pixel_ready(S_pixel_ready),.I_rgba(S_rgba),.I_x(S_x),.I_y(S_y),.I_pixel_last(S_ilast),
        .I_source_valid(S_source_valid),.O_source_ready(S_source_ready),.I_source_tag(S_source_tag),
        .I_source_lease_token(S_source_token),.I_source_generation(S_source_generation),.I_source_error(S_source_error),
        .O_cancel_source(S_cancel),.O_mem_valid(S_mem_valid),.I_mem_ready(S_mem_ready),.O_mem_wr(S_mem_wr),
        .O_mem_addr(S_addr),.O_mem_data(S_data),.O_mem_tag(S_mem_tag),.O_mem_mask(S_mask),
        .O_mem_lease_token(S_mem_token),.O_mem_generation(S_mem_generation),
        .I_mem_done_valid(S_response_valid),.O_mem_done_ready(S_response_ready),.I_mem_done_tag(S_response_tag),
        .I_mem_done_lease_token(S_response_token),.I_mem_done_generation(S_response_generation),.I_mem_done_error(S_response_error),
        .O_busy(S_busy),.O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),.O_memory_error(S_memory_error),
        .O_source_error(S_source_diagnostic),.O_tag(S_out_tag),.O_slot(S_out_slot),.O_lease_token(S_out_token),.O_generation(S_out_generation),
        .O_accepted_writes(S_accepted),.O_retired_writes(S_retired),.O_pixels(S_pixels),
        .O_memory_retired(S_memory_retired),.O_producer_retired(S_producer_retired),
        .O_response_discarded(S_discard_response),.O_source_discarded(S_discard_source),.O_tag_exhausted(S_exhausted),
        .I_layout(3'd0),
        .I_clear_x(16'd0),
        .I_clear_y(16'd0),
        .I_clear_width(16'd0),
        .I_clear_height(16'd0)
    );
    fb_writer_tag_case u_tag_case(S_small_done);
    task fail;
        input [511:0] message;
        begin $display("FAIL writer case=%0d writes=%0d retired=%0d: %0s",S_case,S_seen,S_completed,message); $stop; end
    endtask
    function [31:0] color;
        input integer u,v;
        begin color={u[7:0],v[7:0],S_case[7:0],8'hff}; end
    endfunction
    task mapped;
        input integer u,v;
        begin
            case (S_gr)
                0:begin S_ex=u; S_ey=v; end
                1:begin S_ex=S_gh-1-v; S_ey=u; end
                2:begin S_ex=S_gw-1-u; S_ey=S_gh-1-v; end
                3:begin S_ex=v; S_ey=S_gw-1-u; end
            endcase
            S_ex=S_ex+S_gix; S_ey=S_ey+S_giy;
        end
    endtask
    // Queued endpoint permits multiple real logical writes outstanding and arbitrary
    // delayed retirement. It is NOT a claim about physical SDRAM timing.
    always @(negedge S_clk) begin
        S_cycles=S_cycles+1;
        S_mem_ready=S_allow_command && S_cycles%17>2;
        S_reply_valid=!S_zero && S_injection==0 && S_allow_response && S_qcount>0 && S_cycles%11>2;
        if (S_qcount>0) begin
            S_reply_tag=S_qtag[S_qhead]; S_reply_token=S_qtoken[S_qhead]; S_reply_generation=S_qgeneration[S_qhead];
            S_reply_error=S_completed==S_fail_at ? 4'd10 : 4'd0;
        end
    end
    always @(posedge S_clk) begin
        if (S_reset) begin S_qhead=0; S_qtail=0; S_qcount=0; S_waiting=0; S_last_mem_tag=0; end
        else begin
            if (S_waiting && (!S_mem_valid ||
                {S_addr,S_data,S_mem_tag,S_mask,S_mem_token,S_mem_generation}!==S_mem_saved)) fail("presented write changed/withdrawn");
            S_waiting=S_mem_valid && !S_mem_ready;
            S_mem_saved={S_addr,S_data,S_mem_tag,S_mask,S_mem_token,S_mem_generation};
            if (S_mem_valid && S_mem_ready) begin
                if (!(S_mem_tag>S_last_mem_tag)) fail("memory tag reused or wrapped across jobs");
                S_last_mem_tag=S_mem_tag;
                if (S_check_memory) begin
                    if (S_seen<S_clear_count) begin
                        S_expected_addr=S_gslot*307200+S_seen; S_expected_data=S_background;
                    end else begin
                        S_index=S_seen-S_clear_count;
                        S_u=S_index%S_gw; S_v=S_gbottom ? S_gh-1-S_index/S_gw : S_index/S_gw;
                        mapped(S_u,S_v); S_expected_addr=S_gslot*307200+S_ey*640+S_ex;
                        S_expected_data=color(S_u,S_v);
                    end
                    if (S_seen>=S_expected_total || S_addr!==S_expected_addr[20:0] || S_data!==S_expected_data ||
                        S_mask!==4'd0 || !S_mem_wr || S_mem_tag==0 || S_mem_token!==S_job_token || S_mem_generation!==S_job_generation)
                        fail("address/data/mask/identity or excess write");
                end
                S_seen=S_seen+1;
                if (!S_zero) begin
                    if (S_qcount==32) fail("endpoint queue overflow");
                    S_qtag[S_qtail]=S_mem_tag; S_qtoken[S_qtail]=S_mem_token; S_qgeneration[S_qtail]=S_mem_generation;
                    S_qtail=(S_qtail+1)%32; S_qcount=S_qcount+1;
                end
            end
            if (S_response_valid && S_response_ready && S_injection==0) begin
                if (!S_zero) begin
                    if (S_qcount==0) fail("unexpected duplicate completion");
                    S_qhead=(S_qhead+1)%32; S_qcount=S_qcount-1;
                end
                S_completed=S_completed+1;
            end
            if (S_qcount>S_max_pending) S_max_pending=S_qcount;
            if (S_qcount>8) fail("writer exceeded configured pending credits");
        end
    end
    task launch;
        input integer op,slot,w,h,x,y,r,bottom,expected;
        begin
            @(negedge S_clk); if (!S_start_ready || S_qcount!=0) fail("start/reuse while obligations remain");
            S_case=S_case+1; S_seen=0; S_completed=0; S_max_pending=0; S_fail_at=-1;
            S_gslot=slot; S_gw=w; S_gh=h; S_gix=x; S_giy=y; S_gr=r; S_gbottom=bottom;
            S_clear_count=(op==0 || op==2) ? 307200 : 0;
            S_expected_total=S_clear_count+(op==0 ? 0 : w*h);
            S_job_token=32'h12340000+S_case; S_job_generation=S_media_generation; S_job_tag=S_case;
            S_background=32'h112233ff;
            S_op=op; S_slot=slot; S_w=w; S_h=h; S_ix=x; S_iy=y; S_rotation=r; S_bottom=bottom;
            S_source_expected=expected; S_token=S_job_token; S_generation=S_job_generation; S_tag=S_job_tag; S_clear=S_background;
            S_iv=0; S_source_valid=0; S_start=1;
            @(posedge S_clk); @(negedge S_clk); S_start=0;
            S_op=3; S_slot=7; S_w=0; S_h=0; S_ix=65535; S_iy=65535; S_rotation=0; S_bottom=!bottom;
            S_token=0; S_generation=0; S_tag=0; S_clear=0; S_source_expected=0;
        end
    endtask
    task pixel;
        input integer u,v,last;
        begin
            @(negedge S_clk); mapped(u,v);
            S_x=S_ex; S_y=S_ey; S_rgba=color(u,v); S_ilast=last; S_iv=1;
            @(posedge S_clk); while (!S_pixel_ready) @(posedge S_clk);
            @(negedge S_clk); S_iv=0;
        end
    endtask
    task source;
        input integer error,wrong;
        begin
            @(negedge S_clk); S_source_valid=1;
            S_source_tag=S_job_tag; S_source_token=wrong ? S_job_token-1 : S_job_token;
            S_source_generation=S_job_generation; S_source_error=error;
            @(posedge S_clk); if (!S_source_ready) fail("source not drained");
            @(negedge S_clk); S_source_valid=0;
            if (wrong && !S_discard_source) fail("old source identity consumed as current");
        end
    endtask
    task finish;
        input integer error,complete;
        begin
            wait (S_done); @(negedge S_clk);
            if (S_error!==error[3:0] || !S_memory_retired || !S_producer_retired || S_mem_valid ||
                !S_busy || S_pixel_ready || S_out_tag!==S_job_tag || S_out_slot!==S_gslot[2:0] ||
                S_out_token!==S_job_token || S_out_generation!==S_job_generation ||
                S_accepted!==S_seen[31:0] || S_retired!==S_completed[31:0] || S_accepted!==S_retired || S_qcount!=0)
                fail("early/incorrect terminal or identity/counts");
            if (complete && (S_seen!=S_expected_total || S_pixels!=(S_expected_total-S_clear_count))) fail("incomplete job");
            S_saved_result={S_error,S_memory_error,S_source_diagnostic,S_out_tag,S_out_slot,S_out_token,S_out_generation,S_accepted,S_retired,S_pixels};
            S_abort=1;
            repeat (7) begin
                @(posedge S_clk); #1;
                if (!S_done || S_start_ready ||
                    {S_error,S_memory_error,S_source_diagnostic,S_out_tag,S_out_slot,S_out_token,S_out_generation,S_accepted,S_retired,S_pixels}!==S_saved_result)
                    fail("published result not frozen");
            end
            @(negedge S_clk); S_abort=0; S_done_ready=1;
            @(posedge S_clk); @(negedge S_clk); S_done_ready=0;
            if (S_done || S_busy || !S_start_ready) fail("result retirement");
        end
    endtask
    task successful;
        input integer op,slot,w,h,x,y,r,bottom;
        begin
            launch(op,slot,w,h,x,y,r,bottom,op!=0);
            if (op!=0) begin
                for (S_b=0;S_b<h;S_b=S_b+1)
                    for (S_a=0;S_a<w;S_a=S_a+1) pixel(S_a,bottom ? h-1-S_b : S_b,S_a==w-1 && S_b==h-1);
                wait (S_memory_retired); repeat (4) @(negedge S_clk);
                if (S_done || S_producer_retired) fail("memory retirement bypassed source obligation");
                source(0,1); source(0,0);
            end
            finish(0,1);
        end
    endtask
    initial begin
        S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        S_grant=0; S_start=1; repeat (5) begin @(negedge S_clk); if (S_start_ready || S_busy || S_mem_valid) fail("lease grant bypass"); end
        S_start=0; S_grant=1;
        for (S_j=0;S_j<4;S_j=S_j+1)
            for (S_k=0;S_k<2;S_k=S_k+1) successful(1,S_j%6,7,3,13,17,S_j,S_k);
        successful(0,5,1,1,0,0,0,0);
        successful(2,4,13,7,31,43,1,1);
        S_zero=1; successful(1,0,19,11,3,7,2,0); S_zero=0;
        // Present a write under memory backpressure; abort cannot revoke it.
        S_allow_command=0; launch(1,2,2,2,7,9,0,0,1); pixel(0,0,0);
        wait (S_mem_valid); repeat (4) @(negedge S_clk); S_abort=1;
        @(posedge S_clk); @(negedge S_clk); S_abort=0;
        if (!S_mem_valid || S_done || !S_cancel) fail("abort revoked presented command");
        source(6,0); repeat (5) @(negedge S_clk); if (S_done) fail("pending write not retired");
        S_allow_command=1; finish(5,0);
        // Fill pending credits, hold all completions, inject an unrelated identity,
        // then an actual storage error; source cancellation must still retire.
        S_allow_response=0; launch(1,1,13,2,0,0,0,0,1);
        for (S_a=0;S_a<8;S_a=S_a+1) pixel(S_a,0,0);
        repeat (12) @(negedge S_clk);
        if (S_accepted!=8 || S_pixel_ready || S_memory_retired || S_qcount!=8) fail("credit saturation");
        S_injection=1; @(posedge S_clk); @(negedge S_clk); S_injection=0;
        if (!S_discard_response || S_retired!=0 || S_error!=0) fail("old response not isolated");
        S_fail_at=0; S_allow_response=1;
        wait (S_cancel); source(6,0); finish(3,0);
        if (S_memory_error!=10) fail("storage diagnostic lost");
        // Wrong in-lease response tag is an error, not permission to drop the queue.
        S_allow_response=0; launch(1,0,1,1,639,479,0,0,1); pixel(0,0,1);
        wait (S_qcount==1); @(negedge S_clk); S_injection=2;
        @(posedge S_clk); @(negedge S_clk); S_injection=0;
        repeat (4) @(negedge S_clk); if (S_retired!=0 || S_done || !S_cancel) fail("wrong tag retired real obligation");
        source(6,0); S_allow_response=1; finish(4,0);
        // Validly mapped coordinates but wrong last are rejected before memory issue.
        launch(1,0,2,2,0,0,0,0,1); pixel(0,0,1);
        wait (S_cancel); source(6,0); finish(4,0);
        if (S_seen!=0) fail("bad pixel wrote memory");
        launch(1,0,2,2,0,0,0,0,1);
        @(negedge S_clk); S_iv=1; S_x=1; S_y=0; S_rgba=color(0,0); S_ilast=0;
        @(posedge S_clk); while (!S_pixel_ready) @(posedge S_clk);
        @(negedge S_clk); S_iv=0;
        wait (S_cancel); source(6,0); finish(4,0);
        if (S_seen!=0) fail("wrong coordinate wrote memory");
        // Source success before complete coverage is a protocol failure.
        launch(1,0,3,3,0,0,0,0,1); source(0,0); finish(4,0);
        launch(1,0,3,3,0,0,0,0,1); source(2,0); finish(2,0);
        // A transient medium loss sticks until all existing writes and source retire.
        S_allow_response=0; launch(1,3,2,2,0,0,0,0,1); pixel(0,0,0);
        wait (S_qcount==1); @(negedge S_clk); S_media_valid=0;
        @(posedge S_clk); @(negedge S_clk); S_media_valid=1;
        repeat (4) @(negedge S_clk); if (!S_cancel || S_done) fail("transient invalidation lost");
        source(6,0); S_allow_response=1; finish(6,0);
        // Invalid configuration with and without an already-started source.
        launch(1,6,1,1,0,0,0,0,0); finish(1,0);
        launch(1,0,0,1,0,0,0,0,1); wait (S_cancel); source(6,0); finish(1,0);
        launch(1,0,640,480,0,0,1,0,0); finish(1,0);
        launch(1,0,1,1,65535,65535,0,0,0); finish(1,0);
        // Resident safety-page writes ignore TF validity but not normal completion.
        S_resident=1; S_media_valid=0; successful(1,5,3,2,11,13,3,1);
        S_resident=0; S_media_valid=1;
        // Global reset is shared with this endpoint, unlike a forbidden local flush.
        S_allow_response=0; launch(1,0,2,2,0,0,0,0,1); pixel(0,0,0);
        wait (S_qcount==1); @(negedge S_clk); S_reset=1;
        repeat (3) @(negedge S_clk); S_reset=0; S_allow_response=1;
        if (S_done || S_mem_valid || S_busy || S_exhausted) fail("global reset");
        successful(1,0,3,5,7,9,1,1);
        wait (S_small_done);
        S_test_pass=1;
        $display("PASS: framebuffer clear/regions, mapped coordinates, queued/zero-delay real retirement, source join, cancel/identity/errors");
        $finish;
    end
    initial begin #1000000000; fail("timeout"); end
endmodule

module fb_writer_tag_case(output reg O_done);
    reg S_clk=0,S_reset=0,S_start=0,S_iv=0,S_source=0,S_done_ready=0;
    reg [15:0] S_x=0,S_width=4;
    reg [3:0] S_source_code=6;
    wire S_start_ready,S_ready,S_cancel,S_mem_valid,S_done,S_exhausted;
    wire [31:0] S_mem_tag,S_mem_token,S_mem_generation,S_accepted,S_retired;
    wire [3:0] S_error;
    integer S_i;
    always #5 S_clk=~S_clk;
    fb_writer #(.PENDING_BITS(1),.MEM_TAG_BITS(2)) u_small (
        .I_clk(S_clk),.I_reset(S_reset),.I_media_valid(1'b1),.I_media_generation(32'd1),
        .I_start_valid(S_start),.O_start_ready(S_start_ready),.I_lease_grant(1'b1),.I_op(2'd1),.I_slot(3'd0),
        .I_lease_token(32'd1),.I_generation(32'd1),.I_tag(16'd1),.I_resident(1'b0),.I_clear_rgba(32'd0),
        .I_pre_width(S_width),.I_pre_height(16'd1),.I_image_x(16'd0),.I_image_y(16'd0),.I_rotation(2'd0),
        .I_bottom_up(1'b0),.I_source_expected(1'b1),.I_abort(1'b0),
        .I_pixel_valid(S_iv),.O_pixel_ready(S_ready),.I_rgba(32'h123456ff),.I_x(S_x),.I_y(16'd0),.I_pixel_last(S_x==S_width-16'd1),
        .I_source_valid(S_source),.O_source_ready(),.I_source_tag(16'd1),.I_source_lease_token(32'd1),
        .I_source_generation(32'd1),.I_source_error(S_source_code),.O_cancel_source(S_cancel),
        .O_mem_valid(S_mem_valid),.I_mem_ready(1'b1),.O_mem_wr(),.O_mem_addr(),.O_mem_data(),.O_mem_tag(S_mem_tag),
        .O_mem_mask(),.O_mem_lease_token(S_mem_token),.O_mem_generation(S_mem_generation),
        .I_mem_done_valid(S_mem_valid),.O_mem_done_ready(),.I_mem_done_tag(S_mem_tag),
        .I_mem_done_lease_token(S_mem_token),.I_mem_done_generation(S_mem_generation),.I_mem_done_error(4'd0),
        .O_busy(),.O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_error),.O_memory_error(),.O_source_error(),
        .O_tag(),.O_slot(),.O_lease_token(),.O_generation(),.O_accepted_writes(S_accepted),.O_retired_writes(S_retired),.O_pixels(),
        .O_memory_retired(),.O_producer_retired(),.O_response_discarded(),.O_source_discarded(),.O_tag_exhausted(S_exhausted),
        .I_layout(3'd0),
        .I_clear_x(16'd0),
        .I_clear_y(16'd0),
        .I_clear_width(16'd0),
        .I_clear_height(16'd0)
    );
    task launch;
        begin
            @(negedge S_clk); if (!S_start_ready) begin $display("FAIL small writer start"); $stop; end
            S_start=1; @(posedge S_clk); @(negedge S_clk); S_start=0;
        end
    endtask
    task result;
        input integer count;
        begin
            wait (S_cancel); @(negedge S_clk); S_source=1;
            @(posedge S_clk); @(negedge S_clk); S_source=0;
            wait (S_done); @(negedge S_clk);
            if (S_error!=7 || S_accepted!=count || S_retired!=count || !S_exhausted) begin
                $display("FAIL tag exhaustion root/retirement %0d %0d %0d",S_error,S_accepted,S_retired); $stop;
            end
            S_done_ready=1; @(posedge S_clk); @(negedge S_clk); S_done_ready=0;
        end
    endtask
    initial begin
        O_done=0; S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        launch;
        for (S_i=0;S_i<3;S_i=S_i+1) begin
            S_iv=1; S_x=S_i;
            @(posedge S_clk); while (!S_ready) @(posedge S_clk);
            @(negedge S_clk); S_iv=0;
        end
        result(3); launch; result(0);
        // Spending the very last legal tag on the last required write is success.
        @(negedge S_clk); S_reset=1; repeat (3) @(negedge S_clk); S_reset=0;
        S_width=3; S_source_code=0; launch;
        for (S_i=0;S_i<3;S_i=S_i+1) begin
            S_iv=1; S_x=S_i;
            @(posedge S_clk); while (!S_ready) @(posedge S_clk);
            @(negedge S_clk); S_iv=0;
        end
        S_source=1; @(posedge S_clk); @(negedge S_clk); S_source=0;
        wait (S_done); @(negedge S_clk);
        if (S_error!=0 || S_accepted!=3 || S_retired!=3 || !S_exhausted) begin
            $display("FAIL final legal write tag falsely rejected"); $stop;
        end
        O_done=1;
    end
endmodule
