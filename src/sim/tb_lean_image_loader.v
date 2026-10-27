`timescale 1ns/1ps
// Focused cancellation/retirement checks; complete pixel transforms and native
// SDRAM are covered by tb_lean_video, not by this always-ready memory peer.
module tb_lean_image_loader;
    reg S_clk=0,S_reset=1,S_start=0,S_valid=0,S_last=0,S_file_done=0;
    reg S_idle=1,S_done_ready=0,S_write_ready=1;
    reg [7:0] S_byte=0;
    wire S_ready,S_byte_ready,S_cancel,S_write,S_done;
    wire [3:0] S_error;
    wire [18:0] S_pixels;
    wire [20:0] S_address;
    wire [31:0] S_data;
    reg [7:0] S_header[0:53];
    integer S_i,S_case=0,S_writes=0;
    reg S_test_pass=0;
    always #4 S_clk=~S_clk;
    lean_image_loader u_dut (
        .I_clk(S_clk),.I_reset(S_reset),.I_start_valid(S_start),.O_start_ready(S_ready),
        .I_file_size(32'd921654),.I_rotation(2'd0),.I_slot(1'b1),
        .I_byte_valid(S_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),.I_byte_last(S_last),
        .I_file_done(S_file_done),.I_file_error(8'd0),.I_memory_error(1'b0),.I_writes_idle(S_idle),
        .O_cancel(S_cancel),.O_write_valid(S_write),.I_write_ready(S_write_ready),
        .O_write_address(S_address),.O_write_data(S_data),.O_done_valid(S_done),
        .I_done_ready(S_done_ready),.O_error(S_error),.O_pixels(S_pixels)
    );
    task fail;
        input [511:0] message;
        begin $display("FAIL: lean loader case %0d: %0s",S_case,message); $stop; end
    endtask
    task put32;
        input integer offset;
        input [31:0] value;
        begin
            S_header[offset]=value[7:0]; S_header[offset+1]=value[15:8];
            S_header[offset+2]=value[23:16]; S_header[offset+3]=value[31:24];
        end
    endtask
    always @(posedge S_clk) if(!S_reset && S_write && S_write_ready) begin
        if(S_writes<307200) begin
            if(S_address!==21'd307200+S_writes || S_data!==0)
                fail("clear address/data changed or invalid header emitted pixels");
        end else if(S_case!=3 || S_address!==307200+
            640*(479-(S_writes-307200)/640)+(S_writes-307200)%640 || S_data!==32'hff333333)
            fail("successful image pixel/address mismatch");
        S_writes=S_writes+1;
    end
    initial begin
        for(S_i=0;S_i<54;S_i=S_i+1) S_header[S_i]=0;
        S_header[0]="B"; S_header[1]="M"; S_header[26]=1; S_header[28]=24;
        put32(2,921654); put32(10,54); put32(14,40); put32(22,480);
        repeat(3) @(negedge S_clk); S_reset=0;
        for(S_case=1;S_case<=2;S_case=S_case+1) begin
            // 639 is valid BMP geometry but outside the lean loader contract.
            // Then reuse the same parser with a corrupted signature.
            put32(18,S_case==1 ? 639 : 640);
            if(S_case==2) S_header[0]=0;
            S_writes=0;
            @(negedge S_clk); S_start=1;
            @(posedge S_clk); if(!S_ready) fail("not reusable after failure");
            @(negedge S_clk); S_start=0;
            for(S_i=0;S_i<54;S_i=S_i+1) begin
                S_valid=1; S_byte=S_header[S_i];
                @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
                @(negedge S_clk);
            end
            S_valid=0;
            wait(S_cancel); @(negedge S_clk);
            if(S_done || S_pixels!=0 || S_writes!=307200) fail("published failed job early");
            repeat(12) begin
                @(negedge S_clk);
                if(!S_cancel || S_done || S_write) fail("cancel not held until file retirement");
            end
            S_idle=0; S_file_done=1;
            @(negedge S_clk); S_file_done=0;
            repeat(12) begin
                @(negedge S_clk);
                if(S_done) fail("ignored pending memory writes");
            end
            S_idle=1; wait(S_done);
            repeat(6) begin
                @(negedge S_clk);
                if(!S_done || S_error!=(S_case==1 ? 1 : 3) || S_pixels!=0 || S_cancel || S_write)
                    fail("failure result not held or incorrect");
            end
            S_done_ready=1;
            @(negedge S_clk); S_done_ready=0;
            wait(S_ready);
        end
        // Keep the last buffered pixel stalled across the parser's one-cycle
        // done pulse. Completion must be remembered until that write retires.
        S_case=3; S_writes=0; S_header[0]="B"; put32(18,640);
        @(negedge S_clk); S_start=1;
        @(negedge S_clk); S_start=0;
        fork
            begin
                for(S_i=0;S_i<921654;S_i=S_i+1) begin
                    S_valid=1; S_byte=S_i<54 ? S_header[S_i] : 8'h33;
                    S_last=S_i==921653;
                    @(posedge S_clk); while(!S_byte_ready) @(posedge S_clk);
                    @(negedge S_clk);
                end
                S_valid=0; S_last=0; S_file_done=1;
                @(negedge S_clk); S_file_done=0;
            end
            begin
                wait(S_pixels==307200);
                @(negedge S_clk); S_write_ready=0;
                repeat(12) begin
                    @(negedge S_clk);
                    if(S_done || S_error || !S_write) fail("last pixel not held until accepted");
                end
                S_write_ready=1;
            end
        join
        wait(S_done);
        if(S_error || S_pixels!=307200 || S_writes!=614400)
            fail("successful image did not retire after last-pixel stall");
        S_test_pass=1;
        $display("PASS: lean loader errors, cancellation, retirement, reuse and stalled final pixel");
        $finish;
    end
    initial begin #100000000; fail("watchdog"); end
endmodule
