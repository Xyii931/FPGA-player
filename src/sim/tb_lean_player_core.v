`timescale 1ns/1ps
// Whole lean control/data integration with independent sector and frame-memory
// peers. Native SDRAM is exercised separately by tb_lean_video, not replaced here
// as evidence for the physical device, vendor HDMI, PLL or SD SPI.
module tb_lean_player_core;
    reg S_host=0,S_video=0,S_reset=1,S_card=1;
    reg [3:0] S_keys=0,S_bad_images=0;
    reg S_rx=0;
    reg [7:0] S_rx_data=0;
    always #4 S_host=~S_host;
    always #20 S_video=~S_video;
    wire S_tx;
    wire [7:0] S_tx_data;
    wire S_read,S_result_ready,S_write,S_de,S_valid,S_sample,S_active,S_busy;
    wire [20:0] S_read_address,S_write_address;
    wire [31:0] S_read_tag,S_write_data;
    wire [15:0] S_x,S_y;
    wire [23:0] S_rgb,S_left,S_right;
    wire [3:0] S_current,S_error;
    wire [4:0] S_images;
    reg S_result=0;
    reg [31:0] S_result_data=0,S_result_tag=0;
    reg [31:0] S_memory[0:614399];
    reg [3:0] S_write_pipe=0;
    integer S_cycle=0,S_audio_samples=0,S_commits=0,S_case=0,S_i;
    reg S_test_pass=0;
    wire S_read_ready=!S_result || S_result_ready;
    wire S_write_ready=S_cycle%7!=0;
    wire S_idle=S_write_pipe==0;
    wire S_request,S_request_ready,S_sd_valid,S_sd_ready,S_last,S_done,S_done_ready,S_cancel,S_cancel_ready,S_ack,S_ack_ready;
    wire [31:0] S_lba;
    wire [7:0] S_count,S_byte;
    wire [1:0] S_context,S_byte_context,S_cancel_context,S_ack_context;
    wire [15:0] S_tag,S_byte_tag,S_cancel_tag,S_ack_tag;
    wire [3:0] S_sd_error;
    lean_player_core u_player (
        .I_host_clk(S_host),.I_video_clk(S_video),.I_async_reset(S_reset),.I_key_release(S_keys),
        .I_rx_valid(S_rx),.I_rx_error(1'b0),.I_rx_data(S_rx_data),.O_tx_valid(S_tx),.I_tx_ready(1'b1),.O_tx_data(S_tx_data),
        .I_card_ready(S_card),.I_capacity_sectors(33'd100000),.I_memory_ready(1'b1),.I_memory_error(1'b0),.I_writes_idle(S_idle),
        .O_read_valid(S_read),.I_read_ready(S_read_ready),.O_read_address(S_read_address),.O_read_tag(S_read_tag),
        .I_result_valid(S_result),.O_result_ready(S_result_ready),.I_result_data(S_result_data),.I_result_tag(S_result_tag),.I_result_error(4'd0),
        .O_write_valid(S_write),.I_write_ready(S_write_ready),.O_write_address(S_write_address),.O_write_data(S_write_data),
        .O_de(S_de),.O_valid(S_valid),.O_x(S_x),.O_y(S_y),.O_rgb(S_rgb),
        .O_sample_valid(S_sample),.O_audio_left(S_left),.O_audio_right(S_right),
        .O_acr_valid(),.O_acr_n(),.O_acr_cts(),.O_active(S_active),.O_busy(S_busy),.O_current(S_current),.O_count(S_images),.O_error(S_error),
        .O_request_valid(S_request),.I_request_ready(S_request_ready),.O_lba(S_lba),.O_count_sectors(S_count),.O_context(S_context),.O_priority(),.O_tag(S_tag),
        .I_sd_byte_valid(S_sd_valid),.O_sd_byte_ready(S_sd_ready),.I_sd_byte_data(S_byte),.I_sector_last(S_last),.I_request_last(S_last),
        .I_sd_byte_context(S_byte_context),.I_sd_byte_tag(S_byte_tag),.I_sd_done_valid(S_done),.O_sd_done_ready(S_done_ready),
        .I_sd_done_context(S_byte_context),.I_sd_done_tag(S_byte_tag),.I_sd_done_error(S_sd_error),
        .O_cancel_valid(S_cancel),.I_cancel_ready(S_cancel_ready),.O_cancel_context(S_cancel_context),.O_cancel_tag(S_cancel_tag),
        .I_cancel_done_valid(S_ack),.O_cancel_done_ready(S_ack_ready),.I_cancel_done_context(S_ack_context),.I_cancel_done_tag(S_ack_tag)
    );
    sim_lean_media_card u_card (
        .I_clk(S_host),.I_reset(S_reset),.I_present(S_card),.I_bad_images(S_bad_images),
        .I_request_valid(S_request),.O_request_ready(S_request_ready),.I_lba(S_lba),.I_count(S_count),.I_context(S_context),.I_tag(S_tag),
        .O_byte_valid(S_sd_valid),.I_byte_ready(S_sd_ready),.O_byte_data(S_byte),.O_last(S_last),.O_context(S_byte_context),.O_tag(S_byte_tag),
        .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_sd_error),
        .I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),.I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),
        .O_cancel_done_valid(S_ack),.I_cancel_done_ready(S_ack_ready),.O_cancel_context(S_ack_context),.O_cancel_tag(S_ack_tag)
    );
    task fail;
        input [511:0] text;
        begin $display("FAIL: lean integration case %0d: %0s index=%0d error=%0d state=%0d",S_case,text,S_current,S_error,u_player.S_state); $stop; end
    endtask
    always @(posedge S_host) begin
        if(S_reset) begin S_cycle<=0; S_result<=0; S_write_pipe<=0; end
        else begin
            S_cycle<=S_cycle+1;
            S_write_pipe<={S_write_pipe[2:0],S_write && S_write_ready};
            if(S_read_ready) begin
                S_result<=S_read;
                if(S_read) begin
                    if(S_read_address>=614400) fail("read outside double buffer");
                    S_result_data<=S_memory[S_read_address]; S_result_tag<=S_read_tag;
                end
            end
            if(S_write && S_write_ready) begin
                if(S_write_address>=614400) fail("write outside double buffer");
                if(S_active && (S_write_address>=307200)==u_player.u_scanout.S_slot) fail("active frame overwritten");
                S_memory[S_write_address]<=S_write_data;
            end
            if(u_player.S_commit_done) begin
                if(!S_idle) fail("commit preceded write retirement");
                S_commits=S_commits+1;
            end
        end
    end
    always @(posedge S_video) begin
        #1;
        if(!S_reset && S_sample && (S_left!=0 || S_right!=0)) begin
            if($signed(S_left)!==-$signed(S_right)) fail("audio channels corrupt");
            S_audio_samples=S_audio_samples+1;
        end
    end
    task send_byte;
        input [7:0] value;
        begin @(negedge S_host); S_rx=1; S_rx_data=value; @(negedge S_host); S_rx=0; end
    endtask
    task key;
        input [3:0] value;
        begin @(negedge S_host); S_keys=value; @(negedge S_host); S_keys=0; end
    endtask
    task wait_image;
        input integer index;
        input integer commits;
        begin
            wait(S_active && !S_busy && S_current==index && S_commits>=commits);
            if(S_images!=4 || S_error!=0) fail("catalog or load failed");
            $display("PASS: lean integrated image %0d commit %0d",index,S_commits);
        end
    endtask
    task check_pixel;
        input integer x,y,image;
        reg [23:0] expected;
        reg [7:0] red,green,blue;
        begin
            red=x+32*image; green=y; blue=x^y^image; expected={red,green,blue};
            @(posedge S_video); #1;
            while(!(S_de && S_x==x && S_y==y)) begin @(posedge S_video); #1; end
            if(!S_valid || S_rgb!==expected) fail("displayed frame does not match selected file");
        end
    endtask
    initial begin
        repeat(12) @(negedge S_host); S_reset=0;
        send_byte("A"); send_byte("0"); send_byte(13);
        S_case=1; wait_image(0,1); check_pixel(321,201,0);
        S_case=2; key(2); wait_image(1,2); check_pixel(417,302,1);
        S_case=3; key(2); wait_image(2,3); check_pixel(119,77,2);
        S_case=4; key(2); wait_image(3,4); check_pixel(639,479,3);
        if(S_audio_samples<100) fail("no concurrent file audio");
        // A broken first image must never replace the old frame. Skip to item 1.
        S_case=5; S_bad_images=1; key(2); wait_image(1,5); check_pixel(321,201,1);
        // Losing the card while idle retains the committed frame and retires I/O.
        S_case=6; @(negedge S_host); S_card=0;
        repeat(5000) @(negedge S_host); check_pixel(321,201,1);
        S_bad_images=0; @(negedge S_host); S_card=1;
        wait_image(0,6); check_pixel(321,201,0);
        S_test_pass=1; $display("PASS: lean player four files, UART/keys, concurrent WAV, bad-file skip and card recovery"); $finish;
    end
    initial begin #1000000000; fail("watchdog"); end
    initial forever begin
        #10000000;
        $display("PROGRESS: t=%0t case=%0d app=%0d source=%0d loader=%0d lba=%0d byte_offset=%0d commits=%0d",
            $time,S_case,u_player.S_state,u_player.u_source.S_phase,u_player.u_loader.S_state,
            S_lba,u_player.S_byte_offset,S_commits);
    end
endmodule
