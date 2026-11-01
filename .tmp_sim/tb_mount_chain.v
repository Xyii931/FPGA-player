`timescale 1ns/1ps
// Main-design mount chain: fat32_mount -> fat32_sector_port -> sd_storage
// (host 83.33 MHz / SD 100 MHz) -> sd_spi_card_model at the SPI pins.
module tb_mount_chain;
    reg host_clk=0, sd_clk=0, reset=1;
    wire card_ready;
    wire [32:0] capacity;

    wire req_valid, req_ready, byte_valid, done_valid;
    wire [7:0] byte_data;
    wire [31:0] req_lba;
    wire [7:0] req_count;
    wire [1:0] req_ctx, req_pri, byte_ctx, done_ctx;
    wire [15:0] req_tag, byte_tag, done_tag;
    wire [3:0] done_error;
    wire sector_last, request_last, port_byte_ready, port_done_ready;

    wire m_read, m_ready, m_result, m_take;
    wire [31:0] m_lba;
    wire [8:0] m_addr;
    wire [7:0] m_data, port_error, mount_error;
    wire [3:0] port_storage, mount_storage;
    wire m_start_ready, mount_mounted, m_sresult;
    wire sd_ncs, sd_sclk, sd_mosi, sd_miso;
    wire card_clk, card_ncs, card_mosi, card_miso, card_error;
    wire [3:0] sd_dbg;
    reg [1:0] st;

    always #6 host_clk = ~host_clk;   // 83.33 MHz
    always #5 sd_clk   = ~sd_clk;     // 100 MHz

    assign #7 card_clk  = sd_sclk;
    assign #7 card_ncs  = sd_ncs;
    assign #7 card_mosi = sd_mosi;
    assign #2 sd_miso   = card_miso;

    sd_spi_card_model #(.OUTPUT_DELAY_NS(14)) u_card (
        .I_ncs(card_ncs), .I_sclk(card_clk), .I_mosi(card_mosi), .O_miso(card_miso),
        .I_present(1'b1), .I_legacy(1'b0), .I_high_capacity(1'b1),
        .I_allow_init(1'b1), .I_corrupt_crc(1'b0),
        .O_read_count(), .O_last_lba(), .O_probe_count(), .O_cmd16_count(),
        .O_acmd41_count(), .O_protocol_error(card_error)
    );

    sd_storage #(.WORK_DIVIDER(16'd250)) u_storage (
        .I_host_clk(host_clk), .I_sd_clk(sd_clk), .I_async_reset(reset),
        .I_request_valid(req_valid), .O_request_ready(req_ready),
        .I_lba(req_lba), .I_count(req_count), .I_context(req_ctx), .I_priority(req_pri),
        .I_tag(req_tag), .I_urgent_context(3'd0),
        .O_byte_valid(byte_valid), .I_byte_ready(port_byte_ready), .O_byte_data(byte_data),
        .O_sector_last(sector_last), .O_request_last(request_last),
        .O_byte_context(byte_ctx), .O_byte_tag(byte_tag),
        .O_done_valid(done_valid), .I_done_ready(port_done_ready),
        .O_done_context(done_ctx), .O_done_tag(done_tag), .O_done_error(done_error),
        .I_cancel_valid(1'b0), .O_cancel_ready(), .I_cancel_context(2'd0), .I_cancel_tag(16'd0),
        .O_cancel_done_valid(), .I_cancel_done_ready(1'b0),
        .O_cancel_done_context(), .O_cancel_done_tag(),
        .O_card_ready(card_ready), .O_card_present(), .O_capacity_sectors(capacity),
        .O_sd_high_capacity(), .O_sd_card_error(), .O_sd_dbg_state(sd_dbg),
        .O_sd_ncs(sd_ncs), .O_sd_sclk(sd_sclk), .O_sd_mosi(sd_mosi), .I_sd_miso(sd_miso)
    );

    fat32_sector_port u_port (
        .I_clk(host_clk), .I_reset(reset), .I_card_ready(card_ready),
        .I_start_valid(m_read), .O_start_ready(m_ready), .I_lba(m_lba),
        .I_context(2'd0), .I_priority(2'd0), .I_abort(1'b0),
        .O_result_valid(m_result), .I_result_ready(m_take),
        .O_error(port_error), .O_storage_error(port_storage),
        .I_buffer_address(m_addr), .O_buffer_data(m_data),
        .O_dbg_state(), .O_dbg_match(), .O_dbg_flags(),
        .O_request_valid(req_valid), .I_request_ready(req_ready),
        .O_lba(req_lba), .O_count(req_count), .O_context(req_ctx), .O_priority(req_pri), .O_tag(req_tag),
        .I_byte_valid(byte_valid), .O_byte_ready(port_byte_ready), .I_byte_data(byte_data),
        .I_sector_last(sector_last), .I_request_last(request_last),
        .I_byte_context(byte_ctx), .I_byte_tag(byte_tag),
        .I_done_valid(done_valid), .O_done_ready(port_done_ready),
        .I_done_context(done_ctx), .I_done_tag(done_tag), .I_done_error(done_error),
        .O_cancel_valid(), .I_cancel_ready(1'b0), .O_cancel_context(), .O_cancel_tag(),
        .I_cancel_done_valid(1'b0), .O_cancel_done_ready(),
        .I_cancel_done_context(2'd0), .I_cancel_done_tag(16'd0)
    );

    fat32_mount u_mount (
        .I_clk(host_clk), .I_reset(reset), .I_card_ready(card_ready),
        .I_capacity_sectors(capacity),
        .I_start_valid(st == 2'd0 && card_ready), .O_start_ready(m_start_ready),
        .O_result_valid(m_sresult), .I_result_ready(st == 2'd2),
        .O_error(mount_error), .O_storage_error(mount_storage), .O_mounted(mount_mounted),
        .O_fat_lba(), .O_data_lba(), .O_cluster_count(), .O_root_cluster(),
        .O_partition_lba(), .O_volume_sectors(),
        .O_cluster_shift(), .O_sectors_per_cluster(),
        .O_read_valid(m_read), .I_read_ready(m_ready), .O_read_lba(m_lba),
        .I_read_result_valid(m_result), .I_read_error(port_error),
        .I_storage_error(port_storage), .O_read_result_ready(m_take),
        .O_buffer_address(m_addr), .I_buffer_data(m_data)
    );

    integer cycles = 0;
    always @(posedge host_clk) begin
        cycles <= cycles + 1;
        if (reset) st <= 2'd0;
        else begin
            if (st == 2'd0 && card_ready && m_start_ready) st <= 2'd1;
            else if (st == 2'd1 && m_sresult) st <= 2'd2;
        end
    end

    initial begin
        forever begin
            #200000;
            $display("t=%0t st=%0d m_read=%b m_ready=%b port_st=%0d mount_st=%0d port_req=%b port_rdy=%b rd_state=%0d card_ready=%b",
                     $time, st, m_read, m_ready, u_port.S_state, u_mount.S_state,
                     req_valid, req_ready, sd_dbg, card_ready);
            if ($time > 20000000) $finish;
        end
    end

    initial begin
        repeat (20) @(posedge host_clk);
        reset <= 0;
        wait (st == 2'd2 || cycles > 2000000);
        repeat (10) @(posedge host_clk);
        $display("cycles=%0d st=%0d mounted=%b mount_error=%0d card_ready=%b card_err=%b sd_state=%0d",
                 cycles, st, mount_mounted, mount_error, card_ready, card_error, sd_dbg);
        if (st == 2'd2) $display("PASS: mount returned a result");
        else $display("FAIL: mount did not return within the window");
        $finish;
    end
endmodule

