`timescale 1ns/1ps
module tb_sd_csd_decode;
    reg [127:0] S_csd=0;
    reg S_high_capacity=0,S_test_pass=0;
    wire S_valid;
    wire [32:0] S_capacity;
    sd_csd_decode u_dut (.I_csd(S_csd),.I_high_capacity(S_high_capacity),
        .O_valid(S_valid),.O_capacity_sectors(S_capacity));
    task expect_capacity;
        input valid;
        input [32:0] sectors;
        begin
            #2;
            if(S_valid!==valid || S_capacity!==sectors) begin
                $display("FAIL: CSD valid=%b capacity=%h expected=%b/%h",S_valid,S_capacity,valid,sectors); $stop;
            end
        end
    endtask
    initial begin
        expect_capacity(0,0);
        S_csd=0; S_csd[0]=1; S_csd[83:80]=9; S_csd[73:62]=1023; S_csd[49:47]=7;
        expect_capacity(1,33'd524288);
        S_csd[83:80]=10; expect_capacity(1,33'd1048576);
        S_csd[83:80]=11; expect_capacity(1,33'd2097152);
        S_csd[83:80]=8; expect_capacity(0,0);
        S_csd[83:80]=12; expect_capacity(0,0);
        S_high_capacity=1; S_csd=0; S_csd[0]=1; S_csd[127:126]=1;
        S_csd[83:80]=9; S_csd[69:48]=8191; expect_capacity(1,33'd8388608);
        S_csd[69:48]=0; expect_capacity(1,33'd1024);
        S_csd[69:48]=22'h3fffff; expect_capacity(1,33'h100000000);
        S_high_capacity=0; expect_capacity(0,0);
        S_high_capacity=1; S_csd[0]=0; expect_capacity(0,0);
        S_csd[0]=1; S_csd[83:80]=10; expect_capacity(0,0);
        S_csd[83:80]=9; S_csd[127:126]=2; expect_capacity(0,0);
        S_test_pass=1; $display("PASS: CSD v1/v2 capacity, CCS consistency and 2^32 sector limit"); $finish;
    end
endmodule
