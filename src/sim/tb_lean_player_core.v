`timescale 1ns/1ps
// Whole lean control/data integration. Defaults to independent sector and frame
// peers; optional modes select the real SD SPI or native SDRAM controllers.
// Device/sector substitutes cannot prove physical timing, PLL or HDMI behavior.
module tb_lean_player_core #(
    parameter integer USE_SD_SPI=0,
    parameter integer USE_NATIVE_SDRAM=0,
    parameter integer SPI_WORK_DIVIDER=6,
    parameter integer USE_AUDIO_CACHE=0
);
    reg S_host=0,S_video=0,S_reset=1,S_card=1;
    reg [3:0] S_keys=0,S_bad_images=0;
    reg S_rx=0;
    reg [7:0] S_rx_data=0;
    always #6 S_host=~S_host;
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
    reg S_model_result=0;
    reg [31:0] S_model_data=0,S_model_tag=0;
    wire S_result,S_read_ready,S_write_ready,S_idle,S_memory_ready,S_memory_error;
    wire [31:0] S_result_data,S_result_tag;
    wire [3:0] S_result_error;
    reg [31:0] S_memory[0:2097151];
    reg [3:0] S_write_pipe=0;
    integer S_cycle=0,S_audio_samples=0,S_commits=0,S_case=0,S_i;
    integer S_stall_samples=0;
    integer S_image_bytes=0,S_image_before=0,S_total_writes=0,S_image_sectors=0;
    integer S_cache_writes=0,S_audio_commands=0,S_audio_sectors=0,S_audio_sector_snapshot=0;
    time S_first_frame_time,S_switch_start,S_switch_duration;
    time S_reset_time,S_card_time,S_mount_time,S_catalog_time,S_load_time,S_pixels_time;
    integer S_perf_rotation;
    reg S_check_sequence=0,S_have_previous=0,S_block_writes=0;
    reg [15:0] S_previous_sample;
    reg [31:0] S_stall_offset;
    reg S_test_pass=0,S_status_checked=0;
    wire S_request,S_request_ready,S_sd_valid,S_sd_ready,S_last,S_done,S_done_ready,S_cancel,S_cancel_ready,S_ack,S_ack_ready;
    wire [31:0] S_lba;
    wire [7:0] S_count,S_byte;
    wire [1:0] S_context,S_byte_context,S_cancel_context,S_ack_context;
    wire [1:0] S_priority;
    wire [15:0] S_tag,S_byte_tag,S_cancel_tag,S_ack_tag;
    wire [1:0] S_done_context;
    wire [15:0] S_done_tag;
    wire [3:0] S_sd_error;
    wire S_card_ready,S_card_error;
    wire [32:0] S_capacity;
    lean_player_core #(.AUDIO_CACHE(USE_AUDIO_CACHE)) u_player (
        .I_host_clk(S_host),.I_video_clk(S_video),.I_async_reset(S_reset),.I_key_release(S_keys),
        .I_rx_valid(S_rx),.I_rx_error(1'b0),.I_rx_data(S_rx_data),.O_tx_valid(S_tx),.I_tx_ready(1'b1),.O_tx_data(S_tx_data),
        .I_card_ready(S_card_ready),.I_capacity_sectors(S_capacity),.I_memory_ready(S_memory_ready),.I_memory_error(S_memory_error),.I_writes_idle(S_idle),
        .O_read_valid(S_read),.I_read_ready(S_read_ready),.O_read_address(S_read_address),.O_read_tag(S_read_tag),
        .I_result_valid(S_result),.O_result_ready(S_result_ready),.I_result_data(S_result_data),.I_result_tag(S_result_tag),.I_result_error(S_result_error),
        .O_write_valid(S_write),.I_write_ready(S_write_ready),.O_write_address(S_write_address),.O_write_data(S_write_data),
        .O_de(S_de),.O_valid(S_valid),.O_x(S_x),.O_y(S_y),.O_rgb(S_rgb),
        .O_sample_valid(S_sample),.O_audio_left(S_left),.O_audio_right(S_right),
        .O_acr_valid(),.O_acr_n(),.O_acr_cts(),.O_active(S_active),.O_busy(S_busy),.O_current(S_current),.O_count(S_images),.O_error(S_error),
        .O_request_valid(S_request),.I_request_ready(S_request_ready),.O_lba(S_lba),.O_count_sectors(S_count),.O_context(S_context),.O_priority(S_priority),.O_tag(S_tag),
        .I_sd_byte_valid(S_sd_valid),.O_sd_byte_ready(S_sd_ready),.I_sd_byte_data(S_byte),.I_sector_last(S_last),.I_request_last(S_last),
        .I_sd_byte_context(S_byte_context),.I_sd_byte_tag(S_byte_tag),.I_sd_done_valid(S_done),.O_sd_done_ready(S_done_ready),
        .I_sd_done_context(S_done_context),.I_sd_done_tag(S_done_tag),.I_sd_done_error(S_sd_error),
        .O_cancel_valid(S_cancel),.I_cancel_ready(S_cancel_ready),.O_cancel_context(S_cancel_context),.O_cancel_tag(S_cancel_tag),
        .I_cancel_done_valid(S_ack),.O_cancel_done_ready(S_ack_ready),.I_cancel_done_context(S_ack_context),.I_cancel_done_tag(S_ack_tag)
    );
    generate if(USE_NATIVE_SDRAM) begin: g_native
        reg memory_clk=0;
        always @(S_host) memory_clk<=#7 S_host;
        wire sclk,cke,ras,cas,we,clock_fault,memory_error,device_fault;
        wire [10:0] addr;
        wire [1:0] ba;
        wire [3:0] dm;
        wire [31:0] dq;
        assign S_memory_error=clock_fault || memory_error || device_fault;
        lean_frame_memory #(.INIT_CYCLES(USE_SD_SPI ? 25000 : 32)) u_memory (
            .I_clk(S_host),.I_clk_sft(memory_clk),.I_reset(S_reset),
            .I_read_valid(S_read),.O_read_ready(S_read_ready),.I_read_address(S_read_address),.I_read_tag(S_read_tag),
            .O_read_result_valid(S_result),.I_read_result_ready(S_result_ready),
            .O_read_data(S_result_data),.O_read_tag(S_result_tag),.O_read_error(S_result_error),
            .I_write_valid(S_write),.O_write_ready(S_write_ready),.I_write_address(S_write_address),.I_write_data(S_write_data),
            .O_writes_idle(S_idle),.O_initialized(S_memory_ready),.O_clock_fault(clock_fault),.O_memory_error(memory_error),
            .O_sdram_clk(sclk),.O_sdram_cke(cke),.O_sdram_ras_n(ras),.O_sdram_cas_n(cas),.O_sdram_we_n(we),
            .O_sdram_addr(addr),.O_sdram_ba(ba),.O_sdram_dm(dm),.IO_sdram_dq(dq));
        sim_sdr_device u_device (
            .I_clk(sclk),.I_reset(S_reset),.I_cke(cke),.I_ras_n(ras),.I_cas_n(cas),.I_we_n(we),
            .I_addr(addr),.I_ba(ba),.I_dm(dm),.IO_dq(dq),.O_fault(device_fault),
            .O_reads(),.O_writes(),.O_refreshes());
    end else begin: g_ideal
        assign S_read_ready=!S_model_result || S_result_ready;
        assign S_write_ready=!S_block_writes && S_cycle%7!=0;
        assign S_idle=S_write_pipe==0;
        assign S_result=S_model_result;
        assign S_result_data=S_model_data;
        assign S_result_tag=S_model_tag;
        assign S_result_error=4'd0;
        assign S_memory_ready=1'b1;
        assign S_memory_error=1'b0;
    end endgenerate
    generate if(!USE_SD_SPI) begin: g_sector
    assign S_card_ready=S_card;
    assign S_card_error=1'b0;
    assign S_capacity=33'd100000;
    assign S_done_context=S_byte_context;
    assign S_done_tag=S_byte_tag;
    sim_lean_media_card u_card (
        .I_clk(S_host),.I_reset(S_reset),.I_present(S_card),.I_bad_images(S_bad_images),
        .I_request_valid(S_request),.O_request_ready(S_request_ready),.I_lba(S_lba),.I_count(S_count),.I_context(S_context),.I_tag(S_tag),
        .O_byte_valid(S_sd_valid),.I_byte_ready(S_sd_ready),.O_byte_data(S_byte),.O_last(S_last),.O_context(S_byte_context),.O_tag(S_byte_tag),
        .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_error(S_sd_error),
        .I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),.I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),
        .O_cancel_done_valid(S_ack),.I_cancel_done_ready(S_ack_ready),.O_cancel_context(S_ack_context),.O_cancel_tag(S_ack_tag)
    );
    end else begin: g_spi
        reg S_sdclk=0;
        always #10 S_sdclk=~S_sdclk;
        wire ncs,sclk,mosi,miso,card_clk,card_ncs,card_mosi,card_miso,card_error;
        assign S_card_error=card_error;
        assign #7 card_clk=sclk;
        assign #7 card_ncs=ncs;
        assign #7 card_mosi=mosi;
        assign #2 miso=card_miso;
        sd_storage #(.WORK_DIVIDER(SPI_WORK_DIVIDER),.POWERUP_CYCLES(USE_NATIVE_SDRAM ? 32'd100000 : 32'd1000)) u_storage (
            .I_host_clk(S_host),.I_sd_clk(S_sdclk),.I_async_reset(S_reset),
            .I_request_valid(S_request),.O_request_ready(S_request_ready),.I_lba(S_lba),.I_count(S_count),
            .I_context(S_context),.I_priority(S_priority),.I_tag(S_tag),.I_urgent_context(3'd0),
            .O_byte_valid(S_sd_valid),.I_byte_ready(S_sd_ready),.O_byte_data(S_byte),
            .O_sector_last(S_last),.O_request_last(),.O_byte_context(S_byte_context),.O_byte_tag(S_byte_tag),
            .O_done_valid(S_done),.I_done_ready(S_done_ready),.O_done_context(S_done_context),.O_done_tag(S_done_tag),.O_done_error(S_sd_error),
            .I_cancel_valid(S_cancel),.O_cancel_ready(S_cancel_ready),.I_cancel_context(S_cancel_context),.I_cancel_tag(S_cancel_tag),
            .O_cancel_done_valid(S_ack),.I_cancel_done_ready(S_ack_ready),.O_cancel_done_context(S_ack_context),.O_cancel_done_tag(S_ack_tag),
            .O_card_ready(S_card_ready),.O_capacity_sectors(S_capacity),
            .O_sd_ncs(ncs),.O_sd_sclk(sclk),.O_sd_mosi(mosi),.I_sd_miso(miso),
            .O_card_present(),.O_sd_high_capacity(),.O_sd_card_error());
        sd_spi_card_model #(.OUTPUT_DELAY_NS(14),.BUSY_BYTES(50),.IMAGE_LEAN(1)) u_card (
            .I_ncs(card_ncs),.I_sclk(card_clk),.I_mosi(card_mosi),.O_miso(card_miso),
            .I_present(S_card),.I_legacy(1'b0),.I_high_capacity(1'b1),.I_allow_init(1'b1),.I_corrupt_crc(1'b0),
            .O_protocol_error(card_error),.O_read_count(),.O_last_lba(),.O_probe_count(),.O_cmd16_count(),.O_acmd41_count());
    end endgenerate
    task fail;
        input [511:0] text;
        begin $display("FAIL: lean integration case %0d: %0s index=%0d error=%0d state=%0d",S_case,text,S_current,S_error,u_player.S_state); $stop; end
    endtask
    always @(posedge S_host) begin
        if(S_reset) begin S_cycle<=0; S_model_result<=0; S_write_pipe<=0; end
        else begin
            S_cycle<=S_cycle+1;
            if(S_request && S_request_ready && S_context==0 && S_lba>=1233 && S_lba<9233)
                S_image_sectors=S_image_sectors+1;
            if(u_player.S_byte_valid && u_player.S_byte_context==0 && u_player.S_byte_ready)
                S_image_bytes=S_image_bytes+1;
            S_write_pipe<={S_write_pipe[2:0],S_write && S_write_ready};
            if(!USE_NATIVE_SDRAM && S_read_ready) begin
                S_model_result<=S_read;
                if(S_read) begin
                    if(S_read_address>=614400) fail("read outside double buffer");
                    S_model_data<=S_memory[S_read_address]; S_model_tag<=S_read_tag;
                end
            end
            if(S_write && S_write_ready) begin
                if(S_write_address>=614400 && (!USE_AUDIO_CACHE || S_write_address<1048576))
                    fail("write outside frame/cache reservations");
                if(S_write_address<614400 && S_active && (S_write_address>=307200)==u_player.u_scanout.S_slot)
                    fail("active frame overwritten");
                // The native device already stores every write. Keep this
                // shadow RAM only for the independent functional-memory peer.
                if(!USE_NATIVE_SDRAM) S_memory[S_write_address]<=S_write_data;
                if(S_write_address<614400) S_total_writes=S_total_writes+1;
                else S_cache_writes=S_cache_writes+1;
            end
            if(u_player.S_select_audio && u_player.S_command && u_player.S_command_ready) begin
                if(USE_AUDIO_CACHE && !S_active) fail("audio cache delayed the first image");
                S_audio_commands=S_audio_commands+1;
            end
            if(S_request && S_request_ready && S_context==1) S_audio_sectors=S_audio_sectors+1;
            if(u_player.S_commit_done) begin
                if(!S_idle) fail("commit preceded write retirement");
                S_commits=S_commits+1;
            end
        end
    end
    always @(posedge S_video) begin
        #1;
        if(!S_reset && S_check_sequence && S_sample) begin
            if(S_have_previous && S_left[23:8]!==
               ((!$test$plusargs("LONG_AUDIO") && S_previous_sample==($test$plusargs("MED_AUDIO") ? 16'd9191 : 16'd1699)) ? 16'd1000 : S_previous_sample+16'd1))
                fail("audio sample skipped, repeated or muted during stall");
            S_previous_sample=S_left[23:8]; S_have_previous=1;
            S_stall_samples=S_stall_samples+1;
        end
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
            if(commits==1 && index==0 && S_image_sectors!=1801)
                fail("first image re-read data sectors after backpressure");
            if(commits==2 && index==1 && S_image_sectors!=3602)
                fail("second image re-read data sectors after backpressure");
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
    task check_first_frame_memory;
        integer pixel,x,y;
        reg [7:0] red,green,blue;
        begin
            for(pixel=0;pixel<307200;pixel=pixel+1) begin
                x=pixel%640; y=pixel/640;
                red=x; green=y; blue=x^y;
                if(S_memory[pixel]!=={8'hff,red,green,blue})
                    fail("image memory differs after backpressure recovery");
            end
        end
    endtask
    // Compare the actual native device contents after each performance-mode
    // commit, including all quarter-turn side bars. No second frame RAM needed.
    generate if(USE_NATIVE_SDRAM) begin: g_frame_check
        integer pixel,x,y,sx,sy,u,v,base;
        reg [7:0] red,green,blue;
        reg [31:0] expected;
        always @(negedge S_host) if(!S_reset && ($test$plusargs("PERFORMANCE") || $test$plusargs("CACHED_MEDIA")) && u_player.S_commit_done) begin
            base=u_player.S_job_slot ? 307200 : 0;
            for(pixel=0;pixel<307200;pixel=pixel+1) begin
                x=pixel%640; y=pixel/640;
                sx=x; sy=y; u=0; v=0;
                case(u_player.S_job_rotation)
                    1:begin u=y; v=499-x; sx=4*(u/3)+u%3; sy=4*(v/3)+v%3; end
                    2:begin sx=639-x; sy=479-y; end
                    3:begin u=479-y; v=x-140; sx=4*(u/3)+u%3; sy=4*(v/3)+v%3; end
                    default:begin end
                endcase
                red=sx+32*u_player.S_job_index; green=sy; blue=sx^sy^u_player.S_job_index;
                expected=u_player.S_job_rotation[0] && (x<140 || x>=500) ? 32'd0 : {8'hff,red,green,blue};
                if(g_native.u_device.S_memory[base+pixel]!==expected)
                    fail("native frame pixel/rotation/side bar mismatch");
            end
            $display("PERF_FRAME commit=%0d image=%0d rotation=%0d pixels_checked=307200",
                S_commits,u_player.S_job_index,u_player.S_job_rotation);
        end
    end endgenerate
    initial if($test$plusargs("PERFORMANCE")) begin
        wait(!S_reset); S_reset_time=$time;
        wait(S_card_ready); S_card_time=$time;
        wait(u_player.u_source.S_mounted); S_mount_time=$time;
        wait(u_player.S_catalog); S_catalog_time=$time;
        wait(u_player.u_loader.S_state==2); S_load_time=$time;
        wait(u_player.S_loader_done); S_pixels_time=$time;
    end
    initial begin
        wait(!S_reset);
        // Exercise the diagnostic byte through the host-to-video status FIFO.
        // A value with high bits set detects an accidentally implicit 1-bit net.
        force u_player.S_mount_type=8'h8c;
        wait(u_player.S_pending_status[28:21]===8'h8c);
        @(negedge S_video); force u_player.S_frame_start=1'b1;
        @(negedge S_video); release u_player.S_frame_start;
        if(u_player.S_video_status[28:21]!==8'h8c || u_player.u_status_osd.I_dbg_type!==8'h8c)
            fail("partition type did not reach video status intact");
        release u_player.S_mount_type;
        S_status_checked=1;
    end
    initial begin
        if($test$plusargs("CACHED_MEDIA")) begin
            if(!USE_AUDIO_CACHE || !USE_NATIVE_SDRAM) fail("cache integration requires native memory and cache");
            repeat(12) @(negedge S_host); S_reset=0;
            send_byte("A"); send_byte("0"); send_byte(13);
            wait_image(0,1);
            wait(u_player.S_cache_ready && u_player.u_audio.S_play_sync && u_player.S_pending_status[8:6]==4);
            S_check_sequence=1; S_audio_sector_snapshot=S_audio_sectors;
            if(S_audio_commands!=1 || S_cache_writes!=711) fail("cache not loaded exactly once");
            key(2); wait_image(1,2);
            key(8); wait_image(1,3);
            wait(S_stall_samples>=3000);
            if(S_audio_commands!=1 || S_audio_sectors!=S_audio_sector_snapshot ||
                u_player.u_audio.O_underflows!=0 || S_memory_error || S_total_writes!=3*307200)
                fail("cached audio re-read TF, skipped samples or corrupted frames");
            $display("CACHE_PLAY samples=%0d underflows=%0d audio_file_commands=%0d audio_sectors=%0d image_writes=%0d cache_writes=%0d",
                S_stall_samples,u_player.u_audio.O_underflows,S_audio_commands,S_audio_sectors,S_total_writes,S_cache_writes);
            S_check_sequence=0;
            @(negedge S_host); S_card=0;
            wait(!u_player.S_catalog); repeat(20) @(negedge S_host);
            if(u_player.S_cache_ready || u_player.u_audio.S_play_sync) fail("removed media retained its audio cache");
            @(negedge S_host); S_card=1;
            wait(S_audio_commands==2); wait(u_player.S_cache_ready && u_player.u_audio.S_play_sync);
            if(S_cache_writes!=1422 || S_memory_error || S_error!=0) fail("cache media recovery failed");
            S_test_pass=1; $display("PASS: SDRAM cached WAV, first-image priority, native-memory frame/rotation, audio continuity and media recovery"); $finish;
        end
        if($test$plusargs("PERFORMANCE")) begin
            if(!USE_SD_SPI || !USE_NATIVE_SDRAM) fail("performance mode requires both real controllers");
            repeat(12) @(negedge S_host); S_reset=0;
            send_byte("A"); send_byte("0"); send_byte(13);
            wait(u_player.u_audio.S_play_sync && u_player.S_pending_status[8:6]==4);
            S_check_sequence=1;
            wait_image(0,1); S_first_frame_time=$time-S_reset_time;
            $display("PERF_STARTUP divider=%0d card_ns=%0d mount_ns=%0d catalog_ns=%0d load_begin_ns=%0d pixels_done_ns=%0d first_frame_ns=%0d",
                SPI_WORK_DIVIDER,S_card_time-S_reset_time,S_mount_time-S_card_time,
                S_catalog_time-S_mount_time,S_load_time-S_catalog_time,
                S_pixels_time-S_load_time,S_first_frame_time);
            if($test$plusargs("ROTATE_ONLY")) begin
                S_switch_start=$time; key(8); wait_image(0,2);
                $display("PERF_ROTATE divider=%0d rotation=1 duration_ns=%0d",SPI_WORK_DIVIDER,$time-S_switch_start);
                if(S_total_writes!=2*307200 || S_image_sectors!=2*1801 ||
                   S_memory_error || S_card_error || u_player.u_audio.O_underflows!=0 || S_stall_samples<100)
                    fail("startup/rotation counts, memory, protocol or continuous audio failed");
                $display("PERF_TOTAL divider=%0d writes=%0d image_sectors=%0d samples=%0d underflows=%0d",
                    SPI_WORK_DIVIDER,S_total_writes,S_image_sectors,S_stall_samples,u_player.u_audio.O_underflows);
                S_test_pass=1; $display("PASS: performance startup and 90-degree rotation with continuous audio"); $finish;
            end
            check_pixel(321,201,0);
            S_switch_start=$time; key(2); wait_image(1,2);
            S_switch_duration=$time-S_switch_start;
            $display("PERF_SWITCH divider=%0d duration_ns=%0d",SPI_WORK_DIVIDER,S_switch_duration);
            check_pixel(417,302,1);
            for(S_perf_rotation=1;S_perf_rotation<=4;S_perf_rotation=S_perf_rotation+1) begin
                S_switch_start=$time; key(8); wait_image(1,S_perf_rotation+2);
                $display("PERF_ROTATE divider=%0d rotation=%0d duration_ns=%0d",
                    SPI_WORK_DIVIDER,S_perf_rotation%4,$time-S_switch_start);
            end
            if(S_total_writes!=6*307200 || S_image_sectors!=6*1801 ||
               S_memory_error || S_card_error || u_player.u_audio.O_underflows!=0 || S_stall_samples<100)
                fail("performance image counts, memory, protocol or continuous audio failed");
            $display("PERF_TOTAL divider=%0d writes=%0d image_sectors=%0d samples=%0d underflows=%0d",
                SPI_WORK_DIVIDER,S_total_writes,S_image_sectors,S_stall_samples,u_player.u_audio.O_underflows);
            S_test_pass=1; $display("PASS: performance startup, switch and all rotations with continuous audio"); $finish;
        end
        if($test$plusargs("NATIVE_MEDIA")) begin
            repeat(12) @(negedge S_host); S_reset=0;
            send_byte("A"); send_byte("0"); send_byte(13);
            if($test$plusargs("BOARD_MEDIA")) begin
                wait(u_player.u_audio.S_play_sync && u_player.S_pending_status[8:6]==4);
                S_check_sequence=1;
            end
            wait_image(0,1); S_first_frame_time=$time;
            check_pixel(321,201,0);
            if(S_total_writes!=307200 || S_image_sectors!=1801)
                fail("first image performed redundant sector reads or clears/writes");
            S_check_sequence=1; S_switch_start=$time;
            key(2); wait_image(1,2); S_switch_duration=$time-S_switch_start; S_check_sequence=0;
            check_pixel(417,302,1);
            $display("NATIVE_MEDIA first_frame_ns=%0d switch_ns=%0d writes=%0d underflows=%0d samples=%0d",
                S_first_frame_time,S_switch_duration,S_total_writes,u_player.u_audio.O_underflows,S_stall_samples);
            if(S_total_writes!=614400 || S_image_sectors!=3602 || S_memory_error || S_card_error || u_player.u_audio.O_underflows!=0 ||
               S_stall_samples<100) fail("native memory/audio/image integration failed");
            if($test$plusargs("BOARD_MEDIA") && (S_first_frame_time>64'd5000000000 || S_switch_duration>64'd5000000000))
                fail("model startup or image switch exceeded 5 seconds");
            S_test_pass=1; $display("PASS: startup and switch with native SDRAM, active scanout and continuous WAV"); $finish;
        end
        if($test$plusargs("SUSTAINED")) begin
            repeat(12) @(negedge S_host); S_reset=0;
            wait(u_player.u_audio.S_play_sync && u_player.S_pending_status[8:6]==4);
            S_check_sequence=1;
            S_image_before=S_image_bytes;
            #500000000;
            $display("SUSTAINED samples=%0d underflows=%0d image_bytes=%0d fifo=%0d",
                S_stall_samples,u_player.u_audio.O_underflows,S_image_bytes-S_image_before,
                u_player.u_audio.u_fifo.O_write_level);
            if(S_stall_samples<23990 || u_player.u_audio.O_underflows!=0 ||
               S_image_bytes<=S_image_before) fail("sustained shared-storage playback starved");
            S_test_pass=1; $display("PASS: 500ms sustained audio, limited card bandwidth and image progress"); $finish;
        end
        if($test$plusargs("SPI_CONTEND")) begin
            repeat(12) @(negedge S_host); S_reset=0;
            wait(u_player.u_loader.S_state==2 && u_player.u_audio.S_play_sync &&
                 u_player.S_pending_status[8:6]==4);
            S_check_sequence=1;
            S_image_before=S_image_bytes;
            #30000000;
            S_check_sequence=0;
            $display("SPI_AUDIO samples=%0d underflows=%0d image_bytes_in_30ms=%0d", S_stall_samples,u_player.u_audio.O_underflows,S_image_bytes-S_image_before);
            if(S_stall_samples<1400 || S_image_bytes<=S_image_before ||
               u_player.u_audio.O_underflows!=0 || S_card_error)
                fail("SPI playback starved or card protocol failed");
            S_test_pass=1; $display("PASS: real SD SPI controller, file reader, BMP and continuous WAV"); $finish;
        end
        if($test$plusargs("IMAGE_BACKPRESSURE")) begin
            repeat(12) @(negedge S_host); S_reset=0;
            wait(u_player.u_loader.S_state==2 && u_player.u_audio.S_play_sync &&
                 u_player.S_pending_status[8:6]==4);
            // Block a pixel already being written, then let the BMP parser
            // propagate that backpressure into the shared file byte stream.
            wait(u_player.u_loader.S_px_valid);
            @(negedge S_host); S_block_writes=1;
            wait(u_player.S_image_pause && u_player.S_image_count>=8);
            S_stall_offset=u_player.u_audio.O_offset;
            S_check_sequence=1;
            // Exceed even the full 8192-frame FIFO's 170.7 ms capacity:
            // continuity must come from ongoing card service, not stored audio.
            #220000000;
            S_check_sequence=0;
            $display("BACKPRESSURE offsets=%0d->%0d samples=%0d underflows=%0d", S_stall_offset,u_player.u_audio.O_offset,S_stall_samples,u_player.u_audio.O_underflows);
            if(u_player.u_audio.O_offset<=S_stall_offset || S_stall_samples<10500 ||
               u_player.u_audio.O_underflows!=0) fail("audio did not progress during image stall");
            @(negedge S_host); S_block_writes=0;
            wait_image(0,1); check_first_frame_memory; check_pixel(321,201,0);
            if(u_player.u_audio.O_underflows!=0) fail("audio starved after image stall recovery");
            S_test_pass=1; $display("PASS: audio stays continuous during image stall and image resumes intact"); $finish;
        end
        if($test$plusargs("SHARED_CONTENTION")) begin
            // Realistic sustained byte rate with image and WAV reads sharing
            // the actual file/sector arbiter and a fixed-rate audio consumer.
            repeat(12) @(negedge S_host); S_reset=0;
            wait(u_player.u_loader.S_state==2 && u_player.u_audio.S_play_sync);
            $display("AUDIO_START size=%0d samples=%0d fifo=%0d audio_state=%0d", u_player.u_audio.S_size,S_audio_samples,u_player.u_audio.u_fifo.O_write_level,u_player.u_audio.S_state);
            #60000000;
            $display("AUDIO_DIAG underflows=%0d samples=%0d fifo_level=%0d audio_state=%0d file_state=%0d pending=%b", u_player.u_audio.O_underflows,S_audio_samples,u_player.u_audio.u_fifo.O_write_level,u_player.u_audio.S_state,u_player.u_source.u_files.S_state,u_player.u_source.S_pending);
            if(u_player.u_audio.O_underflows!=0 || S_audio_samples<500)
                fail("audio starved during concurrent image load");
            if(u_player.u_loader.S_state!=2) fail("concurrent image load not exercised");
            S_test_pass=1; $display("PASS: concurrent image and audio at limited sector rate"); $finish;
        end
        if($test$plusargs("CLEAR_CONTENTION")) begin
            // Hold image clearing longer than the audio FIFO's capacity. Audio
            // must continue using the shared storage port until clear resumes.
            S_block_writes=1;
            force u_player.S_job_rotation=2'd1;
            repeat(12) @(negedge S_host); S_reset=0;
            wait(u_player.u_loader.S_state==1);
            wait(u_player.u_audio.S_play_sync);
            #40000000;
            if(u_player.u_audio.O_underflows!=0 || S_audio_samples<500)
                fail("audio starved during image clear");
            if(u_player.u_loader.S_state!=1) fail("clear stall not exercised");
            @(negedge S_host); S_block_writes=0;
            release u_player.S_job_rotation;
            S_test_pass=1; $display("PASS: audio progresses during blocked image clear"); $finish;
        end
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
        if(!S_status_checked) fail("diagnostic status test did not finish");
        S_test_pass=1; $display("PASS: lean player four files, UART/keys, concurrent WAV, bad-file skip and card recovery"); $finish;
    end
    initial begin
        if($test$plusargs("PERFORMANCE")) #(64'd36000000000);
        else if($test$plusargs("BOARD_MEDIA")) #(64'd12000000000);
        else #1000000000;
        fail("watchdog");
    end
    initial forever begin
        #10000000;
        $display("PROGRESS: t=%0t case=%0d app=%0d source=%0d loader=%0d lba=%0d byte_offset=%0d commits=%0d",
            $time,S_case,u_player.S_state,u_player.u_source.S_phase,u_player.u_loader.S_state,
            S_lba,u_player.S_byte_offset,S_commits);
    end
endmodule
