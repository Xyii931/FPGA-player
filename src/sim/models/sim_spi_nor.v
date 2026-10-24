`timescale 1ns/1ps
// Pin-level NOR peer; default is the 8 KiB CFG1 region, not a timing model.
// Memory survives controller reset. WREN/status/AND programming/erase are explicit.
module sim_spi_nor #(
    parameter integer MEMORY_BYTES=8192
) (
    input wire I_clk,I_cs_n,I_sclk,I_mosi,I_reject_wren,I_busy_stuck,I_corrupt_program,
    output reg O_miso=1
);
    reg [7:0] S_memory[0:MEMORY_BYTES-1];
    reg [7:0] S_program[0:255];
    reg [7:0] S_command=0,S_shift=0,S_reply=8'hff;
    reg [23:0] S_address=0;
    reg S_wel=0;
    integer S_busy=0,S_bit=0,S_byte=0,S_program_bytes=0,S_i,S_target;
    integer S_programs=0,S_erases=0,S_reads=0;
    initial for(S_i=0;S_i<MEMORY_BYTES;S_i=S_i+1) S_memory[S_i]=8'hff;
    always @(posedge I_clk) if(S_busy!=0) S_busy=S_busy-1;
    always @(negedge I_cs_n) begin
        S_command=0; S_shift=0; S_reply=8'hff; S_address=0; S_bit=0; S_byte=0; S_program_bytes=0; O_miso=1;
    end
    always @(posedge I_sclk) if(!I_cs_n) begin
        S_shift={S_shift[6:0],I_mosi};
        if(S_bit==7) begin
            if(S_byte==0) S_command=S_shift;
            else if(S_byte<=3 && (S_command==8'h03 || S_command==8'h02 || S_command==8'h20))
                S_address={S_address[15:0],S_shift};
            else if(S_byte>=4 && S_command==8'h02 && S_program_bytes<256) begin
                S_program[S_program_bytes]=S_shift; S_program_bytes=S_program_bytes+1;
            end
            if(S_command==8'h05) S_reply={6'd0,S_wel,(S_busy!=0 || I_busy_stuck)};
            else if(S_command==8'h03 && S_byte>=3) begin
                if(S_byte>3) S_address=S_address+1;
                S_reply=S_address<MEMORY_BYTES ? S_memory[S_address] : 8'hff;
            end else S_reply=8'hff;
            S_bit=0; S_byte=S_byte+1;
        end else S_bit=S_bit+1;
    end
    always @(negedge I_sclk) if(!I_cs_n) O_miso=S_reply[7-S_bit];
    always @(posedge I_cs_n) begin
        O_miso=1;
        if(S_command==8'h03 && S_byte>=4) S_reads=S_reads+1;
        if(S_command==8'h06 && S_busy==0 && !I_busy_stuck && !I_reject_wren) S_wel=1;
        else if(S_command==8'h02 && S_byte>=5 && S_wel && S_busy==0 && !I_busy_stuck) begin
            for(S_i=0;S_i<S_program_bytes;S_i=S_i+1) begin
                S_target={S_address[23:8],8'd0}+((S_address[7:0]+S_i)%256);
                if(S_target<MEMORY_BYTES) S_memory[S_target]=S_memory[S_target]&S_program[S_i];
            end
            if(I_corrupt_program && S_address<MEMORY_BYTES) S_memory[S_address]=0;
            S_programs=S_programs+1; S_wel=0; S_busy=100;
        end else if(S_command==8'h20 && S_byte==4 && S_wel && S_busy==0 && !I_busy_stuck) begin
            for(S_i=0;S_i<4096;S_i=S_i+1) begin
                S_target={S_address[23:12],12'd0}+S_i;
                if(S_target<MEMORY_BYTES) S_memory[S_target]=8'hff;
            end
            S_erases=S_erases+1; S_wel=0; S_busy=200;
        end
    end
endmodule
