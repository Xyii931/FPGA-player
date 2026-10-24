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
