`timescale 1ns/1ps
// Full media-source mount chain: lean_media_source -> fat32_sector_port
// -> sd_storage (83.33/100 MHz) -> sd_spi_card_model.
module tb_scan_chain;
    reg host_clk=0, sd_clk=0, reset=1;
    wire card_ready;
    wire [32:0] capacity;
    wire catalog_ready;
    wire [4:0] image_count;
    wire audio_found, catalog_overflow;
    wire [7:0] catalog_error;
    wire [3:0] phase;
    wire [1:0] port_state, port_flags;

    wire req_valid, req_ready, byte_valid, done_valid;
    wire [7:0] byte_data;
    wire [31:0] req_lba;
    wire [7:0] req_count;
    wire [1:0] req_ctx, req_pri, byte_ctx, done_ctx;
    wire [15:0] req_tag, byte_tag, done_tag;
    wire [3:0] done_error;
    wire sector_last, request_last, port_byte_ready, port_done_ready;

    wire sd_ncs, sd_sclk, sd_mosi, sd_miso;
    wire card_clk, card_ncs, card_mosi, card_miso, card_error;
    wire [3:0] sd_dbg;

    always #6 host_clk = ~host_clk;
    always #5 sd_clk   = ~sd_clk;

    assign #7 card_clk  = sd_sclk;
    assign #7 card_ncs  = sd_ncs;
    assign #7 card_mosi = sd_mosi;
    assign #2 sd_miso   = card_miso;

    sd_spi_card_model #(.OUTPUT_DELAY_NS(14), .BUSY_BYTES(50), .IMAGE_FAT32(1)) u_card (
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

    lean_media_source u_src (
        .I_clk(host_clk), .I_reset(reset), .I_card_ready(card_ready),
        .I_capacity_sectors(capacity),
        .O_catalog_ready(catalog_ready), .O_image_count(image_count),
        .O_audio_found(audio_found), .O_catalog_overflow(catalog_overflow),
        .O_catalog_error(catalog_error), .O_phase(phase),
        .O_port_state(port_state), .O_port_flags(port_flags),
        .I_command_valid(1'b0), .O_command_ready(), .I_command_audio(1'b0),
        .I_image_index(4'd0), .I_offset(32'd0), .I_length(32'd0),
        .O_begin_valid(), .I_begin_ready(1'b1), .O_begin_audio(), .O_file_size(), .O_begin_error(),
        .O_byte_valid(), .I_byte_ready(1'b1), .O_byte_data(), .O_byte_context(), .O_byte_offset(), .O_byte_last(),
        .O_done_valid(), .I_done_ready(1'b1), .O_done_context(), .O_done_error(), .O_done_bytes(), .O_done_eof(),
        .I_cancel(2'd0),
        .O_request_valid(req_valid), .I_request_ready(req_ready),
        .O_lba(req_lba), .O_count(req_count), .O_context(req_ctx), .O_priority(req_pri), .O_tag(req_tag),
        .I_sd_byte_valid(byte_valid), .O_sd_byte_ready(port_byte_ready), .I_sd_byte_data(byte_data),
        .I_sector_last(sector_last), .I_request_last(request_last),
        .I_sd_byte_context(byte_ctx), .I_sd_byte_tag(byte_tag),
        .I_sd_done_valid(done_valid), .O_sd_done_ready(port_done_ready),
        .I_sd_done_context(done_ctx), .I_sd_done_tag(done_tag), .I_sd_done_error(done_error),
        .O_cancel_valid(), .I_cancel_ready(1'b1), .O_cancel_context(), .O_cancel_tag(),
        .I_cancel_done_valid(1'b0), .O_cancel_done_ready(), .I_cancel_done_context(2'd0), .I_cancel_done_tag(16'd0)
    );

    initial begin
        forever begin
            #200000;
            $display("t=%0t phase=%0d catalog_err=%0h cat_ready=%b count=%0d port_st=%0d flags=%b rd_state=%0d card_ready=%b",
                     $time, phase, catalog_error, catalog_ready, image_count,
                     port_state, port_flags, sd_dbg, card_ready);
            if ($time > 400000000) $finish;
        end
    end

    initial begin
        repeat (20) @(posedge host_clk);
        reset <= 0;
        #250000000;
        $display("final phase=%0d catalog_err=%0h cat_ready=%b count=%0d", phase, catalog_error, catalog_ready, image_count);
        if (catalog_ready && image_count == 5'd4) $display("PASS: catalog found 4 images");
        else $display("FAIL: scan did not produce 4 images");
        $finish;
    end
endmodule


