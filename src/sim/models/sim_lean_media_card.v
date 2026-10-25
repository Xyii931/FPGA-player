`timescale 1ns/1ps
// Sparse host-sector fixture, NOT an SD SPI card or vendor model. Four complete
// BMPs and one WAV in a valid FAT32 root; image/header faults are controllable.
module sim_lean_media_card (
    input wire I_clk,I_reset,I_present,
    input wire [3:0] I_bad_images,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [31:0] I_lba,
    input wire [7:0] I_count,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire O_last,
    output reg [1:0] O_context,
    output reg [15:0] O_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_tag,
    output wire O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output reg [1:0] O_cancel_context,
    output reg [15:0] O_cancel_tag
);
    reg [1:0] S_state;
    reg [31:0] S_lba,S_cycle;
    reg [8:0] S_index;
    reg S_ack;
    reg [7:0] S_boot[0:511],S_root[0:511];
    integer S_i,S_j,S_base,S_cluster;
    task put32;
        input integer address;
        input [31:0] value;
        begin for(S_j=0;S_j<4;S_j=S_j+1) S_boot[address+S_j]=value>>(S_j*8); end
    endtask
    task entry;
        input integer slot,first,size;
        input [87:0] name;
        begin
            S_base=slot*32;
            for(S_j=0;S_j<11;S_j=S_j+1) S_root[S_base+S_j]=name>>(8*(10-S_j));
            S_root[S_base+11]=8'h20; S_root[S_base+26]=first; S_root[S_base+27]=first>>8;
            for(S_j=0;S_j<4;S_j=S_j+1) S_root[S_base+28+S_j]=size>>(S_j*8);
        end
    endtask
    initial begin
        for(S_i=0;S_i<512;S_i=S_i+1) begin S_boot[S_i]=0; S_root[S_i]=0; end
        S_boot[0]=8'heb; S_boot[2]=8'h90; S_boot[12]=2; S_boot[13]=1; S_boot[14]=32; S_boot[16]=2;
        put32(32,70000); put32(36,600); put32(44,2); S_boot[510]=8'h55; S_boot[511]=8'haa;
        entry(0,3,921654,"ONE     BMP"); entry(1,2003,921654,"TWO     BMP");
        entry(2,4003,921654,"THREE   BMP"); entry(3,6003,921654,"FOUR    BMP");
        entry(4,9003,2844,"BGM     WAV");
    end
    function [31:0] fat_value;
        input integer cluster;
        integer image,first;
        begin
            fat_value=0;
            if(cluster<=2) fat_value=32'h0fffffff;
            for(image=0;image<4;image=image+1) begin
                first=3+2000*image;
                if(cluster>=first && cluster<first+1800) fat_value=cluster+1;
                if(cluster==first+1800) fat_value=32'h0fffffff;
            end
            if(cluster>=9003 && cluster<9008) fat_value=cluster+1;
            if(cluster==9008) fat_value=32'h0fffffff;
        end
    endfunction
    function [7:0] bmp_byte;
        input integer image,pos;
        integer x,y;
        reg [31:0] value;
        begin
            bmp_byte=0;
            if(pos<54) begin
                case(pos)
                    0:bmp_byte="B"; 1:bmp_byte="M";
                    10:bmp_byte=54; 14:bmp_byte=40; 18:bmp_byte=I_bad_images[image] ? 8'h7f : 8'h80; 19:bmp_byte=2;
                    22:bmp_byte=8'he0; 23:bmp_byte=1; 26:bmp_byte=1; 28:bmp_byte=24;
                    default:begin end
                endcase
                if(pos>=2 && pos<6) begin value=921654; bmp_byte=value>>((pos-2)*8); end
            end else begin
                x=((pos-54)%1920)/3; y=479-(pos-54)/1920;
                case((pos-54)%3)
                    0:bmp_byte=x^y^image;
                    1:bmp_byte=y;
                    2:bmp_byte=x+32*image;
                endcase
            end
        end
    endfunction
    function [7:0] wav_byte;
        input integer pos;
        reg [31:0] value;
        reg [15:0] left,right;
        begin
            wav_byte=0;
            if(pos<44) begin
                case(pos)
                    0:wav_byte="R"; 1:wav_byte="I"; 2,3:wav_byte="F";
                    8:wav_byte="W"; 9:wav_byte="A"; 10:wav_byte="V"; 11:wav_byte="E";
                    12:wav_byte="f"; 13:wav_byte="m"; 14:wav_byte="t"; 15:wav_byte=" ";
                    16:wav_byte=16; 20:wav_byte=1; 22:wav_byte=2; 24:wav_byte=8'h80; 25:wav_byte=8'hbb;
                    29:wav_byte=8'hee; 30:wav_byte=2; 32:wav_byte=4; 34:wav_byte=16;
                    36:wav_byte="d"; 37:wav_byte="a"; 38:wav_byte="t"; 39:wav_byte="a";
                    default:begin end
                endcase
                if(pos>=4 && pos<8) begin value=2836; wav_byte=value>>((pos-4)*8); end
                if(pos>=40 && pos<44) begin value=2800; wav_byte=value>>((pos-40)*8); end
            end else begin
                left=1000+(pos-44)/4; right=-1000-(pos-44)/4;
                case((pos-44)%4)
                    0:wav_byte=left[7:0]; 1:wav_byte=left[15:8]; 2:wav_byte=right[7:0]; 3:wav_byte=right[15:8];
                endcase
            end
        end
    endfunction
    function [7:0] disk_byte;
        input [31:0] lba;
        input integer pos;
        integer cluster,image,first,offset;
        reg [31:0] value;
        begin
            disk_byte=0;
            if(lba==0) disk_byte=S_boot[pos];
            else if(lba>=32 && lba<632) begin
                value=fat_value((lba-32)*128+pos/4); disk_byte=value>>((pos%4)*8);
            end else if(lba==1232) disk_byte=S_root[pos];
            else begin
                cluster=lba-1230;
                for(image=0;image<4;image=image+1) begin
                    first=3+2000*image;
                    if(cluster>=first && cluster<=first+1800) disk_byte=bmp_byte(image,(cluster-first)*512+pos);
                end
                if(cluster>=9003 && cluster<=9008) disk_byte=wav_byte((cluster-9003)*512+pos);
            end
        end
    endfunction
    assign O_request_ready=S_state==0 && !S_ack;
    assign O_byte_valid=S_state==1 && S_cycle[2:0]!=0;
    assign O_byte_data=disk_byte(S_lba,S_index);
    assign O_last=S_index==511;
    assign O_done_valid=S_state==2;
    assign O_cancel_ready=!S_ack;
    assign O_cancel_done_valid=S_state==0 && S_ack;
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=0; S_lba<=0; S_cycle<=0; S_index<=0; S_ack<=0;
            O_context<=0; O_tag<=0; O_error<=0; O_cancel_context<=0; O_cancel_tag<=0;
        end else begin
            S_cycle<=S_cycle+1'b1;
            if(O_cancel_done_valid && I_cancel_done_ready) S_ack<=0;
            case(S_state)
                0:if(I_request_valid && O_request_ready) begin
                    if(I_count!=1) begin $display("FAIL: sparse card needs one sector per request"); $stop; end
                    S_lba<=I_lba; S_index<=0; O_context<=I_context; O_tag<=I_tag; O_error<=0; S_state<=1;
                end
                1:if(O_byte_valid && I_byte_ready) begin
                    if(S_index==511) begin O_error<=I_present ? 4'd0 : 4'd11; S_state<=2; end
                    else S_index<=S_index+1'b1;
                end
                2:if(I_done_ready) S_state<=0;
            endcase
            if(I_cancel_valid && O_cancel_ready) begin
                S_ack<=1; O_cancel_context<=I_cancel_context; O_cancel_tag<=I_cancel_tag;
                if(S_state==1 && I_cancel_context==O_context && I_cancel_tag==O_tag) begin
                    O_error<=6; S_state<=2;
                end
            end
        end
    end
endmodule
