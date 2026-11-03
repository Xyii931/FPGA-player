// CSD arrives most-significant byte first. Capacity is a count of 512-byte sectors.
// 33 bits represent the SDHC/SDXC upper limit of exactly 2^32 sectors.
module sd_csd_decode (
    input wire [127:0] I_csd,
    input wire I_high_capacity,
    output reg O_valid,
    output reg [32:0] O_capacity_sectors
);
    reg [63:0] S_capacity;
    reg [4:0] S_shift;
    always @* begin
        O_valid=0; O_capacity_sectors=0; S_capacity=0; S_shift=0;
        if(I_csd[0]) begin
            if(I_csd[127:126]==2'b01 && I_high_capacity && I_csd[83:80]==4'd9) begin
                S_capacity=({42'd0,I_csd[69:48]}+64'd1)<<10;
                O_valid=1;
            end else if(I_csd[127:126]==0 && !I_high_capacity &&
                I_csd[83:80]>=9 && I_csd[83:80]<=11) begin
                S_shift={2'd0,I_csd[49:47]}+{1'b0,I_csd[83:80]}-5'd7;
                S_capacity=({52'd0,I_csd[73:62]}+64'd1)<<S_shift;
                O_valid=1;
            end
        end
        if(S_capacity==0 || S_capacity>64'h0000000100000000) O_valid=0;
        if(O_valid) O_capacity_sectors=S_capacity[32:0];
    end
endmodule

// Pipelined variant for the 100 MHz card-init path. The combinational module
// above stays the unit-test reference; this one splits add, shift and limit
// checks across register stages so the CSD branch no longer drives card-ready
// combinationally.
module sd_csd_decode_pipe (
    input wire I_clk,
    input wire [127:0] I_csd,
    input wire I_high_capacity,
    output reg O_valid,
    output reg [32:0] O_capacity_sectors
);
    // CSD is stable for the whole CSD_DECODE cycle; only the decoded fields
    // need registering, so do not duplicate the 128-bit CSD register here.
    reg [22:0] S_size_q;
    reg [4:0] S_shift_q;
    reg S_field_valid_q;
    reg [22:0] S_size_c;
    reg [4:0] S_shift_c;
    reg S_field_valid_c;
    always @* begin
        S_size_c=0; S_shift_c=0; S_field_valid_c=0;
        if(I_csd[0]) begin
            if(I_csd[127:126]==2'b01 && I_high_capacity && I_csd[83:80]==4'd9) begin
                S_size_c={1'b0,I_csd[69:48]}+23'd1;
                S_shift_c=5'd10;
                S_field_valid_c=1;
            end else if(I_csd[127:126]==0 && !I_high_capacity &&
                I_csd[83:80]>=9 && I_csd[83:80]<=11) begin
                S_size_c={10'd0,I_csd[73:62]}+23'd1;
                S_shift_c={2'd0,I_csd[49:47]}+{1'b0,I_csd[83:80]}-5'd7;
                S_field_valid_c=1;
            end
        end
    end
    always @(posedge I_clk) begin
        S_size_q<=S_size_c;
        S_shift_q<=S_shift_c;
        S_field_valid_q<=S_field_valid_c;
    end
    reg [40:0] S_capacity_q;
    always @(posedge I_clk) begin
        S_capacity_q<={18'd0,S_size_q}<<S_shift_q;
    end
    always @(posedge I_clk) begin
        if(S_field_valid_q && S_capacity_q!=0 && S_capacity_q<=41'h100000000) begin
            O_valid<=1'b1;
            O_capacity_sectors<=S_capacity_q[32:0];
        end else begin
            O_valid<=1'b0;
            O_capacity_sectors<=33'd0;
        end
    end
endmodule
