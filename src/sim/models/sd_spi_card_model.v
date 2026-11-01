`timescale 1ns/1ps
// Test-only SD card peer for initialization and CMD17. Not a vendor card model.
// Configurable legacy/SDSC/SDHC, delayed ACMD41, CRC damage and card removal.
module sd_spi_card_model #(
    parameter integer OUTPUT_DELAY_NS=0,
    parameter integer BUSY_BYTES=0,
    parameter integer IMAGE_FAT32=0
) (
    input wire I_ncs,I_sclk,I_mosi,
    output wire O_miso,
    input wire I_present,I_legacy,I_high_capacity,I_allow_init,I_corrupt_crc,
    output reg [31:0] O_read_count=0,O_last_lba=0,O_probe_count=0,
    output reg [31:0] O_cmd16_count=0,O_acmd41_count=0,
    output reg O_protocol_error=0
);
    reg [7:0] S_queue[0:1023],S_packet[0:5];
    reg [7:0] S_tx=8'hff,S_rx=0;
    integer S_qread=0,S_qwrite=0,S_bits=0,S_packet_count=0,S_attempts=0;
    reg S_idle=1,S_app=0,S_selected=0;
    assign #(OUTPUT_DELAY_NS) O_miso=(!I_present || !S_selected || I_ncs) ? 1'b1 : S_tx[7];
    // Optional sparse FAT32 image for scan tests. Only the boot sector, both
    // FAT copies and the root-directory cluster carry content; everything
    // else reads as 0x00.
    reg [7:0] S_mbr[0:511];
    reg [7:0] S_boot[0:511];
    reg [7:0] S_dir[0:511];
    integer S_img_i;
    initial begin
        for (S_img_i=0;S_img_i<512;S_img_i=S_img_i+1) begin
            S_boot[S_img_i]=8'h00; S_dir[S_img_i]=8'h00;
        end
        S_boot[0]=8'hEB; S_boot[1]=8'h3C; S_boot[2]=8'h90;
        S_boot[3]=8'h4D; S_boot[4]=8'h53; S_boot[5]=8'h44; S_boot[6]=8'h4F; S_boot[7]=8'h53; S_boot[8]=8'h35;
        S_boot[11]=8'h00; S_boot[12]=8'h02;
        S_boot[13]=8'h01;
        S_boot[14]=8'h20; S_boot[15]=8'h00;
        S_boot[16]=8'h02;
        S_boot[21]=8'hF8;
        S_boot[24]=8'h3F; S_boot[25]=8'h00;
        S_boot[26]=8'hFF; S_boot[27]=8'h00;
        S_boot[32]=8'h00; S_boot[33]=8'h00; S_boot[34]=8'h02; S_boot[35]=8'h00;
        S_boot[36]=8'h00; S_boot[37]=8'h04; S_boot[38]=8'h00; S_boot[39]=8'h00;
        S_boot[44]=8'h02; S_boot[45]=8'h00; S_boot[46]=8'h00; S_boot[47]=8'h00;
        S_boot[82]=8'h46; S_boot[83]=8'h41; S_boot[84]=8'h54; S_boot[85]=8'h33; S_boot[86]=8'h32;
        S_boot[510]=8'h55; S_boot[511]=8'hAA;
        // MBR: one FAT32-LBA primary partition starting at LBA 2048.
        for (S_img_i=0;S_img_i<512;S_img_i=S_img_i+1) S_mbr[S_img_i]=8'h00;
        S_mbr[446]=8'h00; S_mbr[447]=8'h00; S_mbr[448]=8'h00; S_mbr[449]=8'h00;
        S_mbr[450]=8'h0C; S_mbr[451]=8'hFE; S_mbr[452]=8'hFF; S_mbr[453]=8'hFF;
        S_mbr[454]=8'h00; S_mbr[455]=8'h08; S_mbr[456]=8'h00; S_mbr[457]=8'h00;
        S_mbr[458]=8'h00; S_mbr[459]=8'h00; S_mbr[460]=8'h02; S_mbr[461]=8'h00;
        S_mbr[510]=8'h55; S_mbr[511]=8'hAA;
        for (S_img_i=0;S_img_i<4;S_img_i=S_img_i+1) begin
            S_dir[S_img_i*32+0]=8'h49; S_dir[S_img_i*32+1]=8'h4D; S_dir[S_img_i*32+2]=8'h47;
            S_dir[S_img_i*32+3]=8'h31+S_img_i[7:0];
            S_dir[S_img_i*32+8]=8'h42; S_dir[S_img_i*32+9]=8'h4D; S_dir[S_img_i*32+10]=8'h50;
            S_dir[S_img_i*32+11]=8'h20;
            S_dir[S_img_i*32+26]=8'h02+S_img_i[7:0];
            S_dir[S_img_i*32+28]=8'h00; S_dir[S_img_i*32+29]=8'h10;
            S_dir[S_img_i*32+30]=8'h0E; S_dir[S_img_i*32+31]=8'h00;
        end
    end
    function [7:0] img_byte;
        input [31:0] lba;
        input [15:0] off;
        begin
            if (lba==32'd0) img_byte=S_mbr[off[8:0]];
            else if (lba==32'd2080 || lba==32'd3104) begin
                if (off[8:2]==7'd0) img_byte=(off[1:0]==2'd0)?8'hF8:((off[1:0]==2'd3)?8'h0F:8'hFF);
                else if (off[8:2]<=7'd5) img_byte=(off[1:0]==2'd3)?8'h0F:8'hFF;
                else img_byte=8'h00;
            end
            else if (lba==32'd2048) img_byte=S_boot[off[8:0]];
            else if (lba==32'd4128) img_byte=S_dir[off[8:0]];
            else img_byte=8'h00;
        end
    endfunction
    task push;
        input [7:0] byte_value;
        begin
            if(S_qwrite<1024) begin S_queue[S_qwrite]=byte_value; S_qwrite=S_qwrite+1; end
            else O_protocol_error=1;
        end
    endtask
    function [15:0] crc_byte;
        input [15:0] previous;
        input [7:0] byte_value;
        reg [15:0] crc;
        integer bit_index;
        begin
            crc=previous^{byte_value,8'd0};
            for(bit_index=0;bit_index<8;bit_index=bit_index+1)
                if(crc[15]) crc=(crc<<1)^16'h1021; else crc=crc<<1;
            crc_byte=crc;
        end
    endfunction
    task command;
        input [7:0] last;
        integer cmd,k;
        reg [31:0] arg,lba;
        reg [7:0] value;
        reg [15:0] crc;
        reg [127:0] csd;
        begin
            cmd=S_packet[0]&63; arg={S_packet[1],S_packet[2],S_packet[3],S_packet[4]};
            if(!last[0]) O_protocol_error=1;
            push(8'hff);
            case(cmd)
                0: begin
                    if(arg!=0 || last!=8'h95) O_protocol_error=1;
                    S_idle=1; S_app=0; S_attempts=0; push(1);
                end
                8: begin
                    if(arg!=32'h1aa || last!=8'h87) O_protocol_error=1;
                    if(I_legacy) push(5);
                    else begin push(1); push(0); push(0); push(1); push(8'haa); end
                end
                55: begin S_app=1; push(S_idle ? 1 : 0); end
                41: begin
                    if(!S_app || (I_legacy ? arg!=0 : arg!=32'h40000000)) O_protocol_error=1;
                    S_app=0; S_attempts=S_attempts+1; O_acmd41_count=O_acmd41_count+1;
                    if(S_attempts>=3 && I_allow_init) S_idle=0;
                    push(S_idle ? 1 : 0);
                end
                58: begin
                    push(S_idle ? 1 : 0); push((!I_legacy && I_high_capacity) ? 8'hc0 : 8'h80);
                    push(8'hff); push(8'h80); push(0);
                end
                16: begin
                    O_cmd16_count=O_cmd16_count+1;
                    if(arg!=512 || (!I_legacy && I_high_capacity)) O_protocol_error=1;
                    push(0);
                end
                13: begin O_probe_count=O_probe_count+1; push(S_idle ? 1 : 0); push(0); end
                9: begin
                    csd=0; csd[0]=1; csd[83:80]=9;
                    if(!I_legacy && I_high_capacity) begin csd[127:126]=1; csd[69:48]=22'd8191; end
                    else begin csd[73:62]=12'd1023; csd[49:47]=3'd7; end
                    // SDHC: 8,388,608 sectors; SDSC: 524,288 sectors.
                    push(0); push(8'hff); push(8'hfe); crc=0;
                    for(k=15;k>=0;k=k-1) begin value=csd[k*8+:8]; push(value); crc=crc_byte(crc,value); end
                    push(crc[15:8]); push(crc[7:0]);
                end
                17: begin
                    if(S_idle) begin O_protocol_error=1; push(1); end
                    else begin
                        lba=(!I_legacy && I_high_capacity) ? arg : arg>>9;
                        if((I_legacy || !I_high_capacity) && arg[8:0]!=0) O_protocol_error=1;
                        O_last_lba=lba; O_read_count=O_read_count+1;
                        push(0); push(8'hff);
            for(k=0;k<BUSY_BYTES;k=k+1) push(8'hff);
            push(8'hfe); crc=0;
                        for(k=0;k<512;k=k+1) begin value=IMAGE_FAT32 ? img_byte(lba,k) : (lba+k); push(value); crc=crc_byte(crc,value); end
                        push(crc[15:8]); push(crc[7:0]^(I_corrupt_crc ? 8'h01 : 8'h00));
                    end
                end
                default: begin O_protocol_error=1; push(4); end
            endcase
        end
    endtask
    always @(negedge I_ncs) begin
        S_selected=I_present;
        S_qread=0; S_qwrite=0; S_bits=0; S_packet_count=0; S_tx=8'hff; S_rx=0;
    end
    always @(negedge I_present) begin S_selected=0; S_idle=1; S_app=0; S_attempts=0; end
    always @(posedge I_sclk) if(!I_ncs && I_present && S_selected) begin
        S_rx={S_rx[6:0],I_mosi}; S_bits=S_bits+1;
        if(S_bits==8) begin
            S_bits=0;
            if(S_packet_count==0) begin
                if(S_rx[7:6]==1) begin S_packet[0]=S_rx; S_packet_count=1; end
            end else if(S_packet_count==5) begin command(S_rx); S_packet_count=0; end
            else begin S_packet[S_packet_count]=S_rx; S_packet_count=S_packet_count+1; end
        end
    end
    always @(negedge I_sclk) if(!I_ncs && I_present && S_selected) begin
        if(S_bits==0) begin
            if(S_qread<S_qwrite) begin S_tx=S_queue[S_qread]; S_qread=S_qread+1; end
            else S_tx=8'hff;
        end else S_tx={S_tx[6:0],1'b1};
    end
endmodule






