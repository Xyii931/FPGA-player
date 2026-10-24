// GB2312 menu/HUD builder. Snapshot changes are reconciled after real publication.
// Chinese strings are source constants, glyph bitmaps come from W25Q64.
module osd_menu_builder (
    input wire I_clk,I_reset,
    input wire [47:0] I_ui,
    input wire I_hud,I_fps_valid,I_mem_valid,
    input wire [15:0] I_fps,
    input wire [31:0] I_video_und,I_audio_und,
    input wire [6:0] I_count,
    input wire [5:0] I_index,
    input wire [20:0] I_mem_busy,I_mem_grant,
    input wire [22:0] I_view,
    input wire [2879:0] I_titles,
    input wire [53:0] I_title_lengths,
    input wire I_alert,
    input wire [5:0] I_alert_length,
    input wire [319:0] I_alert_text,
    output wire O_begin_valid,
    input wire I_begin_ready,
    output wire O_line_valid,
    input wire I_line_ready,
    output wire O_layer,
    output wire [3:0] O_line,
    output wire [9:0] O_x,
    output wire [8:0] O_y,
    output wire [1:0] O_color,
    output wire O_lock,
    output wire [5:0] O_length,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire O_byte_last,O_finish_valid,
    input wire I_finish_ready,I_done_valid,
    output wire O_done_ready,O_idle,
    input wire [3:0] I_error,
    output reg [3:0] O_error
);
    localparam [2:0] IDLE=0,BEGIN_FRAME=1,LINE_CMD=2,BYTES=3,LINE_WAIT=4,FINISH=5,RESULT=6;
    reg [2:0] S_state;
    wire [3469:0] S_desired={I_alert,I_alert_length,I_alert_text,I_view,I_titles,I_title_lengths,I_mem_grant,I_mem_busy,I_index,I_count,I_audio_und,I_video_und,I_fps,
        I_mem_valid,I_fps_valid,I_hud,I_ui};
    reg [3469:0] S_snapshot,S_applied;
    reg S_applied_valid;
    reg [4:0] S_row;
    wire S_title_row=S_row<12;
    wire [3:0] S_ui_row=S_row[3:0]-4'd12;
    wire [22:0] S_view=S_snapshot[3142:3120];
    wire [2879:0] S_titles=S_snapshot[3119:240];
    wire [53:0] S_title_lengths=S_snapshot[239:186];
    wire [319:0] S_label=S_row<9 ? S_titles[S_row*320+:320] : 320'd0;
    wire [5:0] S_label_length=S_row<9 ? S_title_lengths[S_row*6+:6] : 6'd0;
    wire [15:0] S_item_number={10'd0,S_snapshot[143:138]}+16'd1;
    reg [5:0] S_byte;
    reg [319:0] S_text;
    reg [5:0] S_length;
    wire [15:0] S_flags=S_snapshot[15:0],S_menu=S_snapshot[31:16],S_value=S_snapshot[47:32];
    wire S_menu_visible=S_flags[3];
    wire [2:0] S_group=S_menu[4:2];
    wire S_root=S_menu[5];
    wire [15:0] S_number=S_menu[11:8]==6 ? S_value*16'd90 : S_value;
    wire [15:0] S_magnitude=S_number[15] ? 16'd0-S_number : S_number;
    reg [319:0] C_text;
    reg [5:0] C_length;
    reg [9:0] C_x;
    reg [8:0] C_y;
    reg [1:0] C_color;
    reg C_layer;
    function [39:0] decimal;
        input [15:0] value;
        integer i;
        reg [15:0] rest;
        begin
            rest=value;
            for(i=0;i<5;i=i+1) begin decimal[i*8+:8]=8'd48+rest%10; rest=rest/10; end
        end
    endfunction
    wire [5:0] S_alert_first_length=clipped_length(S_snapshot[3462:3143],S_snapshot[3468:3463],6'd32);
    wire [319:0] S_alert_tail=S_snapshot[3462:3143] << (S_alert_first_length*8);
    function [63:0] hex32;
        input [31:0] value;
        integer i;
        reg [3:0] digit;
        begin
            for(i=0;i<8;i=i+1) begin digit=value[i*4+:4]; hex32[i*8+:8]=digit<10 ? 8'd48+digit : 8'd55+digit; end
        end
    endfunction
    function [15:0] decimal2;
        input [15:0] value;
        reg [7:0] tens,units;
        begin
            tens=8'd48+(value/16'd10)%16'd10; units=8'd48+value%16'd10;
            decimal2={tens,units};
        end
    endfunction
    function [23:0] decimal3;
        input [15:0] value;
        reg [7:0] hundreds,tens,units;
        begin
            hundreds=8'd48+(value/16'd100)%16'd10;
            tens=8'd48+(value/16'd10)%16'd10; units=8'd48+value%16'd10;
            decimal3={hundreds,tens,units};
        end
    endfunction
    // Count display cells, never truncate between a GB2312 lead and trail byte.
    function [5:0] clipped_length;
        input [319:0] text;
        input [5:0] length,cells;
        integer i;
        reg [5:0] used,bytes;
        reg pending,stopped;
        reg [7:0] value;
        begin
            used=0; bytes=0; pending=0; stopped=0;
            for(i=0;i<40;i=i+1) begin
                value=text >> ((39-i)*8);
                if(i<length && !stopped) begin
                    if(pending) begin bytes=i+1; used=used+1'b1; pending=0; end
                    else if(used>=cells) stopped=1;
                    else if(value>=8'ha1 && value<=8'hfe) pending=1;
                    else begin bytes=i+1; used=used+1'b1; end
                end
            end
            clipped_length=bytes;
        end
    endfunction
    function [15:0] percent;
        input [20:0] cycles;
        reg [27:0] scaled;
        begin
            scaled={7'd0,cycles}*28'd100;
            percent=cycles>=21'd1048576 ? 16'd100 : {8'd0,scaled[27:20]};
        end
    endfunction
    always @* begin
        C_text=0; C_length=0; C_x=144; C_y=104+{5'd0,S_ui_row}*9'd24; C_color=0; C_layer=1;
        if(S_snapshot[3469]) begin
            C_layer=1; C_x=64; C_y=232; C_color=0;
            if(!S_title_row && S_ui_row==0) begin C_text={40'h414c455254,280'd0}; C_length=5; C_y=184; C_color=3; end
            else if(!S_title_row && S_ui_row==1) begin
                C_text=S_snapshot[3462:3143];
                C_length=S_alert_first_length;
            end else if(!S_title_row && S_ui_row==2) begin
                C_text=S_alert_tail; C_y=256;
                C_length=S_snapshot[3468:3463]-S_alert_first_length;
            end
        end else if(S_title_row) begin
            C_x=8; C_y=456; C_layer=0; C_text=S_label; C_length=0;
            if(S_view[22] && !S_flags[7] && S_row<9 && S_label_length!=0) begin
                if(S_view[21:19]==4) begin
                    C_x=(S_row%3)*10'd213+10'd2;
                    C_y=(S_row/3)*9'd160+9'd144;
                    C_length=clipped_length(S_label,S_label_length,6'd13);
                    if({1'b0,S_view[12:7]}=={1'b0,S_view[18:13]}+S_row) C_color=1;
                end else if(S_row==0) C_length=clipped_length(S_label,S_label_length,6'd39);
            end
        end else if(S_menu_visible) begin
            if(S_root) begin
                case(S_ui_row)

                    0:begin C_text=320'h4650474120b2a5b7c5c6f70000000000000000000000000000000000000000000000000000000000; C_length=6'd11; end
                    1:begin C_text=320'hb2a5b7c5c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                    2:begin C_text=320'hcfd4cabec9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                    3:begin C_text=320'hd2f4c6b5c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                    4:begin C_text=320'hcfb5cdb3c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                    5:begin C_text=320'hb9d8d3da000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                    6:begin C_text=320'hb0b4bcfc312f32d2c6b6af20b0b4bcfc33d1a1d4f100000000000000000000000000000000000000; C_length=6'd21; end
                    7:begin C_text=320'hb0b4bcfc34b7b5bbd800000000000000000000000000000000000000000000000000000000000000; C_length=6'd9; end
                    default:begin end
                endcase
                if(S_ui_row>=1 && S_ui_row<=5 && S_ui_row=={1'b0,S_group}+4'd1) C_color=1;
            end else begin
                if(S_ui_row==0) begin
                    case(S_group)
                        0:begin C_text=320'hb2a5b7c5c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                        1:begin C_text=320'hcfd4cabec9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                        2:begin C_text=320'hd2f4c6b5c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                        3:begin C_text=320'hcfb5cdb3c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                        4:begin C_text=320'hb9d8d3da000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                        default:begin end
                    endcase
                end else if(S_ui_row<=6) begin
                    case(S_group)
                        0:case(S_ui_row)
                            1:begin C_text=320'hd7d4b6afb2a5b7c50000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            2:begin C_text=320'hcda3c1f4c3ebcafd0000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            3:begin C_text=320'hd7aab3a1d0a7b9fb0000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            4:begin C_text=320'hd7aab3a1cab1bce40000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            5:begin C_text=320'hb2a5b7c5cbb3d0f20000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            6:begin C_text=320'hd4ddcda3b2a5b7c50000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            default:begin end
                        endcase
                        1:case(S_ui_row)
                            1:begin C_text=320'hcfd4cabeb0e6cabd0000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            2:begin C_text=320'hcdbcc6acd0fdd7aa0000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            3:begin C_text=320'hcbf5b7c5cbe3b7a80000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            4:begin C_text=320'hc1c1b6c8000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                            5:begin C_text=320'hb6d4b1c8b6c800000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd6; end
                            6:begin C_text=320'hb1a5bacdb6c800000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd6; end
                            default:begin end
                        endcase
                        2:case(S_ui_row)
                            1:begin C_text=320'hd2f4c1bf000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                            2:begin C_text=320'hbeb2d2f4000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                            3:begin C_text=320'hd2f4bbadc6abd2c60000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            default:begin end
                        endcase
                        3:case(S_ui_row)
                            1:begin C_text=320'hcfd4cabed7b4ccac0000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            2:begin C_text=320'hd6d8d0c2c9a8c3e80000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            3:begin C_text=320'hd6d8d0c2bcd3d4d8bfa8000000000000000000000000000000000000000000000000000000000000; C_length=6'd10; end
                            4:begin C_text=320'hb1a3b4e6c9e8d6c30000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            5:begin C_text=320'hbbd6b8b4c4acc8cf0000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            6:begin C_text=320'hd7d4bcec000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                            default:begin end
                        endcase
                        4:case(S_ui_row)
                            1:begin C_text=320'hd7b4ccac000000000000000000000000000000000000000000000000000000000000000000000000; C_length=6'd4; end
                            2:begin C_text=320'hb0e6b1be204445560000000000000000000000000000000000000000000000000000000000000000; C_length=6'd8; end
                            3:begin C_text=320'hd3b2bcfeceb4d1e9d6a4000000000000000000000000000000000000000000000000000000000000; C_length=6'd10; end
                            4:begin C_text=320'hb9b9bda8d7cad4b4ceb4d6aa00000000000000000000000000000000000000000000000000000000; C_length=6'd12; end
                            default:begin end
                        endcase
                        default:begin end
                    endcase
                    if(S_ui_row=={1'b0,S_flags[6:4]}+4'd1) C_color=1;
                end else if(S_ui_row==7) begin
                    if(S_menu[15:12]!=0) begin C_text=320'hb2bbbfc9d3c3bbf2c3a6000000000000000000000000000000000000000000000000000000000000; C_length=6'd10; end
                    else if(S_menu[7]) begin C_text=320'hb0b4bcfc33c8b7c8cfbbd6b8b4c4acc8cf0000000000000000000000000000000000000000000000; C_length=6'd17; end
                    else if(S_menu[11:8]<15) begin
                        C_text={ 56'hb5b1c7b0d6b520,S_number[15] ? 8'd45 : 8'd43,decimal(S_magnitude),216'd0 }; C_length=13;
                    end
                end else if(S_ui_row==8) begin C_text=320'hb0b4bcfc34b7b5bbd800000000000000000000000000000000000000000000000000000000000000; C_length=6'd9; end
            end
        end else begin
            C_x=16; C_y=16+{5'd0,S_ui_row}*9'd20; C_layer=1;
            if(S_ui_row==0 && S_flags[11]) begin C_text=320'hd5fdd4dabaf3cca8bcd3d4d800000000000000000000000000000000000000000000000000000000; C_length=6'd12; end
            else if(S_ui_row==1 && (!S_flags[9] || S_flags[10])) begin
                C_y=448; C_layer=1; C_color=2;
                if(S_flags[10]) begin C_text=320'hc3bdcce5b4edcef320b0b4bcfc34b2cbb5a500000000000000000000000000000000000000000000; C_length=6'd18; end
                else if(S_flags[8]) begin C_text=320'hd5fdd4dabcd3d4d8cbd8b2c400000000000000000000000000000000000000000000000000000000; C_length=6'd12; end
                else begin C_text=320'hcedebfa820c7ebb2e5c8eb5446bfa800000000000000000000000000000000000000000000000000; C_length=6'd15; end
            end else if(S_snapshot[48]) begin
                C_x=424;
                case(S_ui_row)
                    2:begin C_text={32'h46505320,S_snapshot[49] ? decimal(S_snapshot[66:51]) : 40'h3f3f3f3f3f,248'd0}; C_length=9; end
                    3:begin C_text={72'hcad3c6b5c7b7d4d820,hex32(S_snapshot[98:67]),184'd0}; C_length=17; end
                    4:begin C_text={72'hd2f4c6b5c7b7d4d820,hex32(S_snapshot[130:99]),184'd0}; C_length=17; end
                    5:begin C_text={40'h4954454d20,decimal2(S_view[22] ? S_item_number : 16'd0),8'h2f,
                        decimal2({9'd0,S_snapshot[137:131]}),240'd0}; C_length=10; end
                    6:begin
                        if(S_snapshot[50]) begin C_text={24'h425720,decimal3(percent(S_snapshot[164:144])),8'h25,16'h2047,
                            decimal3(percent(S_snapshot[185:165])),8'h25,216'd0}; C_length=13; end
                        else begin C_text=320'h425720554e4b4e4f574e0000000000000000000000000000000000000000000000000000000000; C_length=10; end
                    end
                    7:begin C_text=320'hd7cad4b420554e4b4e4f574e00000000000000000000000000000000000000000000000000000000; C_length=6'd12; end
                    default:begin end
                endcase
            end
        end
    end
    assign O_idle=S_state==IDLE;
    assign O_begin_valid=!I_reset && S_state==BEGIN_FRAME;
    assign O_line_valid=!I_reset && S_state==LINE_CMD && C_length!=0;
    assign O_layer=C_layer;
    assign O_line=S_title_row ? S_row[3:0] : S_ui_row;
    assign O_x=C_x;
    assign O_y=C_y;
    assign O_color=C_color;
    assign O_lock=!S_title_row && !(S_snapshot[3469] && (S_ui_row==1 || S_ui_row==2));
    assign O_length=C_length;
    assign O_byte_valid=!I_reset && S_state==BYTES;
    assign O_byte_data=S_text >> ((39-S_byte)*8);
    assign O_byte_last=S_byte+6'd1==S_length;
    assign O_finish_valid=!I_reset && S_state==FINISH;
    assign O_done_ready=!I_reset && S_state==RESULT;
    task next_line;
        begin
            if(S_row==23) S_state<=FINISH;
            else begin S_row<=S_row+1'b1; S_state<=LINE_CMD; end
        end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_snapshot<=0; S_applied<=0; S_applied_valid<=0; S_row<=0; S_byte<=0; S_text<=0; S_length<=0; O_error<=0;
        end else case(S_state)
            IDLE:if(!S_applied_valid || S_desired!=S_applied) begin S_snapshot<=S_desired; S_row<=0; S_state<=BEGIN_FRAME; end
            BEGIN_FRAME:if(I_begin_ready) S_state<=LINE_CMD;
            LINE_CMD:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(C_length==0) next_line;
                else if(I_line_ready) begin S_text<=C_text; S_length<=C_length; S_byte<=0; S_state<=BYTES; end
            BYTES:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(I_byte_ready) begin
                    if(S_byte+6'd1==S_length) S_state<=LINE_WAIT;
                    else S_byte<=S_byte+1'b1;
                end
            LINE_WAIT:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(I_line_ready) next_line;
            FINISH:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(I_finish_ready) S_state<=RESULT;
            RESULT:if(I_done_valid) begin O_error<=I_error; S_applied<=S_snapshot; S_applied_valid<=1; S_state<=IDLE; end
            default:S_state<=IDLE;
        endcase
    end
endmodule
