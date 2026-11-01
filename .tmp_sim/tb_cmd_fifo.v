`timescale 1ns/1ps
// Focused test for the command FIFO instance used by sector_cdc_bridge:
// DATA_BITS=61, ADDR_BITS=3, write 83.33 MHz, read 100 MHz.
module tb_cmd_fifo;
    localparam integer N = 24;
    reg wclk=0, rclk=0, reset=1;
    reg wvalid=0; wire wready;
    reg [60:0] wdata=0;
    wire [3:0] wlevel;
    wire rvalid; reg rready=1;
    wire [60:0] rdata;
    wire [3:0] rlevel;
    wire full, empty;

    always #6 wclk = ~wclk;   // 83.33 MHz
    always #5 rclk = ~rclk;   // 100 MHz

    async_fifo #(.DATA_BITS(61), .ADDR_BITS(3)) dut (
        .I_write_clk(wclk), .I_read_clk(rclk), .I_async_reset(reset),
        .I_write_valid(wvalid), .O_write_ready(wready), .I_write_data(wdata),
        .O_write_full(full), .O_write_level(wlevel),
        .O_read_valid(rvalid), .I_read_ready(rready), .O_read_data(rdata),
        .O_read_empty(empty), .O_read_level(rlevel)
    );

    integer pushed=0, popped=0, errors=0;
    reg [60:0] expect = 61'd0;

    // writer
    always @(posedge wclk) begin
        if (reset) begin
            wvalid <= 0; pushed <= 0; wdata <= 61'd0;
        end else if (pushed < N) begin
            if (!wvalid || wready) begin
                if (wready) begin
                    pushed <= pushed + 1;
                    wdata <= wdata + 61'd1;
                    wvalid <= (pushed + 1 < N);
                end else begin
                    wvalid <= 1'b1;
                end
            end
        end else begin
            wvalid <= 1'b0;
        end
    end

    // reader
    always @(posedge rclk) begin
        if (reset) begin
            popped <= 0; errors <= 0; expect <= 61'd0;
        end else if (rvalid && rready) begin
            if (rdata !== expect) begin
                if (errors < 6)
                    $display("MISMATCH at %0d: got %0d expected %0d", popped, rdata, expect);
                errors <= errors + 1;
            end
            expect <= expect + 61'd1;
            popped <= popped + 1;
        end
    end

    initial begin
        repeat (20) @(posedge wclk);
        reset <= 0;
        wait (popped == N || $time > 20000000);
        repeat (10) @(posedge wclk);
        $display("pushed=%0d popped=%0d errors=%0d wlevel=%0d rlevel=%0d",
                 pushed, popped, errors, wlevel, rlevel);
        if (pushed == N && popped == N && errors == 0) $display("PASS: fifo delivered every entry");
        else $display("FAIL: fifo lost or corrupted entries");
        $finish;
    end
endmodule
