`timescale 1ns/1ps
// Sequential multi-sector reads through the main-design chain:
//   fat32_sector_port -> sd_storage (83.33/100 MHz) -> sd_spi_card_model
// Reproduces the repeated-request pattern used by the root-directory scan.
module tb_seq_reads;
    reg host_clk=0, sd_clk=0, reset=1;
    reg [31:0] lba;
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

    wire p_start, p_ready, p_result, p_take;
    wire [8:0] p_addr;
    wire [7:0] p_data, p_error;
    wire [3:0] p_storage;
    wire [1:0] p_state, p_flags;

    wire sd_ncs, sd_sclk, sd_mosi, sd_miso;
    wire card_clk, card_ncs, card_mosi, card_miso, card_error;
    wire [3:0] sd_dbg;

    always #6 host_clk = ~host_clk;
    always #5 sd_clk   = ~sd_clk;

    assign #7 card_clk  = sd_sclk;
    assign #7 card_ncs  = sd_ncs;
    assign #7 card_mosi = sd_mosi;
    assign #2 sd_miso   = card_miso;

    sd_spi_card_model #(.OUTPUT_DELAY_NS(14), .BUSY_BYTES(200)) u_card (
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
        .I_start_valid(p_start), .O_start_ready(p_ready), .I_lba(lba),
        .I_context(2'd0), .I_priority(2'd0), .I_abort(1'b0),
        .O_result_valid(p_result), .I_result_ready(p_take),
        .O_error(p_error), .O_storage_error(p_storage),
        .I_buffer_address(p_addr), .O_buffer_data(p_data),
        .O_dbg_state(p_state), .O_dbg_match(), .O_dbg_flags(p_flags),
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

    // Sequential requester: N single-sector reads, one outstanding at a time.
    localparam integer N = 10;
    reg start_r;
    reg [2:0] st;
    integer done_count = 0;
    integer fifo_writes = 0;
    integer sd_cycles = 0;
    integer host_cycles = 0;
    always @(posedge sd_clk) sd_cycles <= sd_cycles + 1;
    always @(posedge host_clk) host_cycles <= host_cycles + 1;
    reg [7:0] last_error;

    assign p_start = start_r;
    assign p_take  = (st == 3'd2);

    always @(posedge host_clk) begin
        if (reset) begin
            st <= 3'd0; start_r <= 1'b0; lba <= 32'd0; done_count <= 0;
        end else begin
            case (st)
                3'd0: if (card_ready) begin start_r <= 1'b1; st <= 3'd1; end
                3'd1: if (p_ready) begin start_r <= 1'b0; st <= 3'd2; end
                3'd2: if (p_result) begin
                    last_error <= p_error;
                    done_count <= done_count + 1;
                    if (done_count + 1 >= N) st <= 3'd3;
                    else begin lba <= lba + 32'd1; st <= 3'd0; end
                end
                default: ;
            endcase
        end
    end

    always @(posedge host_clk) if (!reset && u_storage.u_bridge.u_commands.I_write_valid && u_storage.u_bridge.u_commands.O_write_ready) fifo_writes <= fifo_writes + 1;

    reg [3:0] prev_wgray = 4'd0;
    always @(posedge host_clk) if (!reset) begin
        if (u_storage.u_bridge.u_commands.S_write_gray !== prev_wgray) begin
            $display("T=%0t WGRAY %b -> %b (bin=%0d)", $time, prev_wgray,
                u_storage.u_bridge.u_commands.S_write_gray, u_storage.u_bridge.u_commands.S_write_binary);
            prev_wgray <= u_storage.u_bridge.u_commands.S_write_gray;
        end
    end

    always @(posedge sd_clk) if (!reset && u_storage.u_bridge.S_command_valid)
        $display("T=%0t CMDV reject=%b sdvalid=%b sdready=%b rdstate=%0d media=%0d card=%b",
            $time, u_storage.u_bridge.S_reject, u_storage.u_bridge.O_sd_request_valid,
            u_storage.u_bridge.I_sd_request_ready, u_storage.u_reader.S_state,
            u_storage.u_bridge.S_media_state, u_storage.u_bridge.I_sd_card_ready);

    always @(posedge host_clk) if (!reset) begin
        if (req_valid && req_ready)
            $display("T=%0t ISSUE  tag=%0d lba=%0d", $time, req_tag, req_lba);
        if (u_storage.u_bridge.S_command_write_valid)
            $display("T=%0t CMD_WR tag=%0d lba=%0d", $time, u_storage.u_bridge.I_tag, u_storage.u_bridge.I_lba);
        if (u_storage.u_reader.S_valid[0]) $display("T=%0t RD_V0", $time);
    end

    task report;
        begin
            $display("fifo_writes=%0d reads=%0d/%0d last_error=%0d port_state=%0d flags=%b rd_state=%0d card_ready=%b",
                     fifo_writes, done_count, N, last_error, p_state, p_flags, sd_dbg, card_ready);
            if (done_count == N) $display("PASS: all sequential reads completed");
            else $display("FAIL: sequential reads stalled");
            $finish;
        end
    endtask

    initial begin
        repeat (20) @(posedge host_clk);
        reset <= 0;
    end

    always @(posedge host_clk) if (!reset && st == 3'd3) report;
    initial begin #400000000; $display("TIMEOUT at %0t", $time); report; end
endmodule
















