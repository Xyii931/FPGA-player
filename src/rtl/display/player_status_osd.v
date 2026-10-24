// Small built-in ASCII playback panel; no Flash/Chinese glyph support here.
// Combinational overlay preserves the incoming pixel/raster stage exactly.
module player_status_osd #(
    parameter integer CHINESE_MENU=0
) (
    input wire I_de,I_valid,
    input wire [15:0] I_x,I_y,I_state,
    input wire [15:0] I_menu_info,I_menu_value,
    input wire [22:0] I_view,
    input wire [23:0] I_rgb,
    output reg [23:0] O_rgb
);
    function [34:0] glyph;
        input [7:0] ch;
        begin case(ch)
            "A":glyph=35'b01110_10001_10001_11111_10001_10001_10001;
            "B":glyph=35'b11110_10001_10001_11110_10001_10001_11110;
            "C":glyph=35'b01111_10000_10000_10000_10000_10000_01111;
            "D":glyph=35'b11110_10001_10001_10001_10001_10001_11110;
            "E":glyph=35'b11111_10000_10000_11110_10000_10000_11111;
            "F":glyph=35'b11111_10000_10000_11110_10000_10000_10000;
            "G":glyph=35'b01111_10000_10000_10111_10001_10001_01111;
            "H":glyph=35'b10001_10001_10001_11111_10001_10001_10001;
            "I":glyph=35'b01110_00100_00100_00100_00100_00100_01110;
            "J":glyph=35'b00111_00010_00010_00010_00010_10010_01100;
            "K":glyph=35'b10001_10010_10100_11000_10100_10010_10001;
            "L":glyph=35'b10000_10000_10000_10000_10000_10000_11111;
            "M":glyph=35'b10001_11011_10101_10101_10001_10001_10001;
            "N":glyph=35'b10001_11001_10101_10011_10001_10001_10001;
            "O":glyph=35'b01110_10001_10001_10001_10001_10001_01110;
            "P":glyph=35'b11110_10001_10001_11110_10000_10000_10000;
            "Q":glyph=35'b01110_10001_10001_10001_10101_10010_01101;
            "R":glyph=35'b11110_10001_10001_11110_10100_10010_10001;
            "S":glyph=35'b01111_10000_10000_01110_00001_00001_11110;
            "T":glyph=35'b11111_00100_00100_00100_00100_00100_00100;
            "U":glyph=35'b10001_10001_10001_10001_10001_10001_01110;
            "V":glyph=35'b10001_10001_10001_10001_10001_01010_00100;
            "W":glyph=35'b10001_10001_10001_10101_10101_10101_01010;
            "X":glyph=35'b10001_10001_01010_00100_01010_10001_10001;
            "Y":glyph=35'b10001_10001_01010_00100_00100_00100_00100;
            "Z":glyph=35'b11111_00001_00010_00100_01000_10000_11111;
            "0":glyph=35'b01110_10001_10011_10101_11001_10001_01110;
            "1":glyph=35'b00100_01100_00100_00100_00100_00100_01110;
            "2":glyph=35'b01110_10001_00001_00010_00100_01000_11111;
            "3":glyph=35'b11110_00001_00001_01110_00001_00001_11110;
            "4":glyph=35'b00010_00110_01010_10010_11111_00010_00010;
            "5":glyph=35'b11111_10000_10000_11110_00001_00001_11110;
            "6":glyph=35'b01110_10000_10000_11110_10001_10001_01110;
            "7":glyph=35'b11111_00001_00010_00100_01000_01000_01000;
            "8":glyph=35'b01110_10001_10001_01110_10001_10001_01110;
            "9":glyph=35'b01110_10001_10001_01111_00001_00001_01110;
            "+":glyph=35'b00000_00100_00100_11111_00100_00100_00000;
            "-":glyph=35'b00000_00000_00000_11111_00000_00000_00000;
            "/":glyph=35'b00001_00001_00010_00100_01000_10000_10000;
            ">":glyph=35'b10000_01000_00100_00010_00100_01000_10000;
            default:glyph=0;
        endcase end
    endfunction
    function [255:0] group_title;
        input [2:0] group;
        begin case(group)
            0:group_title="PLAYBACK                        ";
            1:group_title="DISPLAY                         ";
            2:group_title="AUDIO                           ";
            3:group_title="SYSTEM                          ";
            default:group_title="ABOUT                           ";
        endcase end
    endfunction
    function [255:0] menu_label;
        input [2:0] group;
        input [3:0] row;
        begin
            menu_label=0;
            case(group)
                0:case(row)
                    0:menu_label="  AUTO                          ";
                    1:menu_label="  INTERVAL                      ";
                    2:menu_label="  TRANSITION                    ";
                    3:menu_label="  TRANSITION MS                 ";
                    4:menu_label="  ORDER                         ";
                    5:menu_label="  PAUSE                         "; default:begin end
                endcase
                1:case(row)
                    0:menu_label="  LAYOUT                        ";
                    1:menu_label="  ROTATION                      ";
                    2:menu_label="  SCALER                        ";
                    3:menu_label="  BRIGHTNESS                    ";
                    4:menu_label="  CONTRAST                      ";
                    5:menu_label="  SATURATION                    "; default:begin end
                endcase
                2:case(row)
                    0:menu_label="  VOLUME                        ";
                    1:menu_label="  MUTE                          ";
                    2:menu_label="  AV OFFSET MS                  "; default:begin end
                endcase
                3:case(row)
                    0:menu_label="  HUD                           ";
                    1:menu_label="  RESCAN                        ";
                    2:menu_label="  RELOAD CARD                   ";
                    3:menu_label="  SAVE SETTINGS                 ";
                    4:menu_label="  RESTORE DEFAULTS              ";
                    5:menu_label="  SELFTEST                      "; default:begin end
                endcase
                4:case(row)
                    0:menu_label="  STATUS                        ";
                    1:menu_label="  VERSION DEV                   ";
                    2:menu_label="HARDWARE NOT TESTED             ";
                    3:menu_label="BUILD RESOURCES UNKNOWN         "; default:begin end
                endcase
                default:begin end
            endcase
        end
    endfunction
    function [39:0] decimal;
        input [15:0] value;
        integer i;
        reg [15:0] rest;
        begin
            rest=value;
            for(i=0;i<5;i=i+1) begin decimal[i*8+:8]=8'd48+rest%10; rest=rest/10; end
        end
    endfunction
    function [7:0] digit;
        input [31:0] value;
        begin digit=8'd48+value; end
    endfunction
    reg [255:0] C_text;
    reg [7:0] C_char;
    reg [34:0] C_glyph;
    reg [23:0] C_base;
    integer C_row,C_col,C_gx,C_gy,C_bit;
    integer C_cell_x,C_cell_y,C_cell,C_number,C_focus,C_page,C_pages;
    reg C_thumb_border;
    reg C_panel,C_ink,C_selected;
    wire [2:0] S_group=I_menu_info[4:2];
    wire S_root=I_menu_info[5],S_edit=I_menu_info[6],S_confirm=I_menu_info[7];
    wire [15:0] S_menu_number=I_menu_info[11:8]==6 ? I_menu_value*16'd90 : I_menu_value;
    wire [15:0] S_magnitude=S_menu_number[15] ? 16'd0-S_menu_number : S_menu_number;
    always @* begin
        C_base=I_state[12] ? 24'h101820 : I_valid ? I_rgb : 24'd0;
        if(I_state[7]) begin
            // Built-in demo replaces only RGB, never the raster or resource owner.
            if(I_x<80) C_base=24'hffffff;
            else if(I_x<160) C_base=24'hffff00;
            else if(I_x<240) C_base=24'h00ffff;
            else if(I_x<320) C_base=24'h00ff00;
            else if(I_x<400) C_base=24'hff00ff;
            else if(I_x<480) C_base=24'hff0000;
            else if(I_x<560) C_base=24'h0000ff;
            else C_base=0;
        end
        C_panel=0; C_text=0; C_row=0; C_col=0; C_gx=0; C_gy=0; C_bit=0;
        C_char=0; C_glyph=0; C_ink=0; C_selected=0;
        C_cell_x=0; C_cell_y=0; C_cell=0; C_number=0; C_focus=0; C_page=0; C_pages=0;
        C_thumb_border=0;
        if(I_state[3] && I_x>=120 && I_x<520 && I_y>=80 && I_y<400) begin
            C_panel=1;
            if(I_x>=144 && I_x<504 && I_y>=104 && I_y<360) begin
                C_row=(I_y-104)>>5; C_col=(I_x-144)/12;
                C_gx=((I_x-144)%12)>>1; C_gy=((I_y-104)%32)>>1;
                if(S_root) begin
                    if(C_row==0) C_text="FPGA PLAYER                     ";
                    else if(C_row>=1 && C_row<=5) begin
                        C_text=group_title(C_row-1); C_text=C_text>>16;
                    end
                    else if(C_row==6) C_text="KEY1/2 MOVE  KEY3 SELECT        ";
                    else C_text="KEY4 CLOSE                      ";
                    C_selected=C_row>=1 && C_row<=5 && C_row=={29'd0,S_group}+1;
                end else begin
                    if(C_row==0) C_text=group_title(S_group);
                    else if(C_row==7) begin
                        if(I_menu_info[15:12]!=0) C_text="NOT AVAILABLE OR BUSY           ";
                        else if(S_confirm) C_text="KEY3 CONFIRM DEFAULTS           ";
                        else if(I_menu_info[11:8]<15) C_text={"VALUE ",S_menu_number[15] ? 8'd45 : 8'd43,
                            decimal(S_magnitude),S_edit ? " KEY1/2 EDIT        " : " KEY3 EDIT          "};
                        else C_text="KEY3 SELECT  KEY4 BACK          ";
                    end else if(S_group==0 && C_row==6) C_text=I_state[1] ? "  PAUSE      ON                 " : "  PAUSE      OFF                ";
                    else C_text=menu_label(S_group,C_row-1);
                    C_selected=C_row>=1 && C_row<=6 && C_row=={29'd0,I_state[6:4]}+1;
                end
                C_char=C_selected && C_col==0 ? ">" : (C_text >> ((31-C_col)*8));
                C_glyph=glyph(C_char);
                C_bit=34-(C_gy*5+C_gx);
                if(C_gx<5 && C_gy<7) C_ink=C_glyph[C_bit];
            end
        end else if(I_view[22] && I_view[21:19]==4 && !I_state[7] && I_x<639 && I_y<480) begin
            C_cell_x=I_x/213; C_cell_y=I_y/160; C_cell=C_cell_y*3+C_cell_x;
            C_number={26'd0,I_view[18:13]}+C_cell+1;
            C_focus={26'd0,I_view[12:7]}-{26'd0,I_view[18:13]};
            C_page={26'd0,I_view[18:13]}/9+1;
            C_pages=({25'd0,I_view[6:0]}+8)/9;
            C_selected=C_cell==C_focus && C_number<={25'd0,I_view[6:0]};
            C_thumb_border=C_selected && (I_x%213<2 || I_x%213>=211 || I_y%160<2 || I_y%160>=158);
            if(C_number<={25'd0,I_view[6:0]} && I_y%160>=144 && I_y%160<158 &&
                I_x%213>=8 && I_x%213<200) begin
                C_panel=1; C_col=(I_x%213-8)/12; C_gx=((I_x%213-8)%12)>>1; C_gy=(I_y%160-144)>>1;
                C_text={decimal(C_number),"  PAGE ",digit(C_page),"/",digit(C_pages),{17{8'd32}}};
                C_char=C_col<32 ? (C_text >> ((31-C_col)*8)) : 8'd32;
                C_glyph=glyph(C_char); C_bit=34-(C_gy*5+C_gx);
                if(C_gx<5 && C_gy<7) C_ink=C_glyph[C_bit];
            end
        end else if(!I_state[9] && I_y>=448 && I_y<464 && I_x>=16 && I_x<400) begin
            C_panel=1; C_col=(I_x-16)/12; C_gx=((I_x-16)%12)>>1; C_gy=(I_y-448)>>1;
            if(I_state[10]) C_text="MEDIA ERROR  KEY4 FOR MENU      ";
            else if(I_state[15]) C_text="SCANNING CONTIGUOUS BMP          ";
            else if(I_state[14]) C_text="LOADING FLASH DEMO              ";
            else if(I_state[8]) C_text="LOADING MEDIA                   ";
            else C_text="WAITING FOR TF CARD             ";
            C_char=C_col<32 ? (C_text >> ((31-C_col)*8)) : 8'd32;
            C_glyph=glyph(C_char); C_bit=34-(C_gy*5+C_gx);
            if(C_gx<5 && C_gy<7) C_ink=C_glyph[C_bit];
        end
        if(I_state[11] && I_state[9] && !I_state[3] && !I_state[7] &&
            I_x>=16 && I_x<112 && I_y>=16 && I_y<30) begin
            C_thumb_border=0; C_selected=0; C_panel=1; C_text="LOADING                         ";
            C_col=(I_x-16)/12; C_gx=((I_x-16)%12)>>1; C_gy=(I_y-16)>>1;
            C_char=C_text >> ((31-C_col)*8); C_glyph=glyph(C_char);
            C_bit=34-(C_gy*5+C_gx); C_ink=0;
            if(C_gx<5 && C_gy<7) C_ink=C_glyph[C_bit];
        end
        if(CHINESE_MENU && (I_state[3] || (I_view[22] && I_view[21:19]==4) ||
            (!I_state[12] && !I_state[9] && I_y>=448 && I_y<464) ||
            (I_state[11] && I_state[9] && !I_state[7] && I_x<112 && I_y>=16 && I_y<30))) C_ink=0;
        O_rgb=!I_de ? 24'd0 : C_thumb_border ? 24'hffff40 : C_ink ? (C_selected ? 24'h40c0ff : 24'hffffff) :
            C_panel ? {2'd0,C_base[23:18],2'd0,C_base[15:10],2'd0,C_base[7:2]} : C_base;
    end
endmodule
