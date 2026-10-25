// GB2312 menu/HUD builder. Snapshot changes are reconciled after real publication.
// Chinese strings are source constants, glyph bitmaps come from W25Q64.
module osd_menu_builder #(
    parameter integer EXTERNAL_SNAPSHOT=0,
    parameter integer EXTERNAL_TITLES=0
) (
    input wire I_clk,I_reset,
    input wire I_snapshot_valid,
    output wire O_snapshot_done,
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
    output wire O_title_read,
    output wire [3:0] O_title_line,
    output wire [5:0] O_title_address,
    input wire [7:0] I_title_data,
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
    localparam [3:0] IDLE=0,BEGIN_FRAME=1,LINE_CMD=2,BYTES=3,LINE_WAIT=4,FINISH=5,RESULT=6,
        NUMBER_A=7,WAIT_A=8,NUMBER_B=9,WAIT_B=10,CLIP_START=11,CLIP_SCAN=12,SKIP_BYTES=13,
        TITLE_FETCH=14,TITLE_WAIT=15;
    reg [3:0] S_state;
    reg [319:0] S_serial_label;
    reg [5:0] S_title_byte;
    wire [3469:0] S_desired={I_alert,I_alert_length,I_alert_text,I_view,I_titles,I_title_lengths,I_mem_grant,I_mem_busy,I_index,I_count,I_audio_und,I_video_und,I_fps,
        I_mem_valid,I_fps_valid,I_hud,I_ui};
    wire [3469:0] S_snapshot;
    reg S_applied_valid;
    wire S_start=EXTERNAL_SNAPSHOT!=0 ? I_snapshot_valid :
        (!S_applied_valid || S_desired!=S_snapshot);
    generate if(EXTERNAL_SNAPSHOT!=0) begin: g_external
        // The mailbox owns this payload until O_snapshot_done acknowledges it.
        assign S_snapshot=S_desired;
    end else begin: g_internal
        reg [3469:0] S_saved;
        assign S_snapshot=S_saved;
        always @(posedge I_clk or posedge I_reset) begin
            if(I_reset) S_saved<=0;
            else if(S_state==IDLE && S_start) S_saved<=S_desired;
        end
    end endgenerate
    reg [4:0] S_row;
    wire S_title_row=S_row<12;
    wire [3:0] S_ui_row=S_row[3:0]-4'd12;
    wire [22:0] S_view=S_snapshot[3142:3120];
    wire [2879:0] S_titles=S_snapshot[3119:240];
    wire [53:0] S_title_lengths=S_snapshot[239:186];
    reg [319:0] S_label;
    reg [5:0] S_label_length;
    // Explicit word selection avoids a bit-addressed 2880-bit barrel shifter.
    always @* begin
        S_label=0; S_label_length=0;
        case(S_row)
            0:begin S_label=S_titles[0+:320]; S_label_length=S_title_lengths[0+:6]; end
            1:begin S_label=S_titles[320+:320]; S_label_length=S_title_lengths[6+:6]; end
            2:begin S_label=S_titles[640+:320]; S_label_length=S_title_lengths[12+:6]; end
            3:begin S_label=S_titles[960+:320]; S_label_length=S_title_lengths[18+:6]; end
            4:begin S_label=S_titles[1280+:320]; S_label_length=S_title_lengths[24+:6]; end
            5:begin S_label=S_titles[1600+:320]; S_label_length=S_title_lengths[30+:6]; end
            6:begin S_label=S_titles[1920+:320]; S_label_length=S_title_lengths[36+:6]; end
            7:begin S_label=S_titles[2240+:320]; S_label_length=S_title_lengths[42+:6]; end
            8:begin S_label=S_titles[2560+:320]; S_label_length=S_title_lengths[48+:6]; end
            default:begin end
        endcase
        if(EXTERNAL_TITLES!=0) S_label=S_serial_label;
    end
    wire S_fetch_title=EXTERNAL_TITLES!=0 && !S_snapshot[3469] && S_row<9 &&
        S_view[22] && !S_snapshot[7] && S_label_length!=0;
    assign O_title_read=!I_reset && S_state==TITLE_FETCH && S_fetch_title;
    assign O_title_line=S_row[3:0];
    assign O_title_address=S_title_byte;
    wire [15:0] S_item_number={10'd0,S_snapshot[143:138]}+16'd1;
    reg [5:0] S_byte;
    reg [5:0] S_skip;
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
    reg S_cmd_layer,S_cmd_lock;
    reg [3:0] S_cmd_line;
    reg [9:0] S_cmd_x;
    reg [8:0] S_cmd_y;
    reg [1:0] S_cmd_color;
    reg [5:0] S_cmd_length;
    // ASCII formatting consumes BCD from one shared sequential converter.
    reg [19:0] S_digits_a,S_digits_b;
    reg [15:0] C_number_a,C_number_b;
    wire S_number_ready,S_number_done;
    wire [19:0] S_number_digits;
    osd_binary_decimal u_decimal (
        .I_clk(I_clk),.I_reset(I_reset),
        .I_start_valid(S_state==NUMBER_A || S_state==NUMBER_B),.O_start_ready(S_number_ready),
        .I_value(S_state==NUMBER_B ? C_number_b : C_number_a),
        .O_done_valid(S_number_done),.I_done_ready(S_state==WAIT_A || S_state==WAIT_B),
        .O_digits(S_number_digits));
    always @* begin
        C_number_a=0; C_number_b=0;
        if(S_menu_visible && !S_root && S_ui_row==7) C_number_a=S_magnitude;
        else case(S_ui_row)
            2:C_number_a=S_snapshot[66:51];
            5:begin
                C_number_a=S_view[22] ? S_item_number : 16'd0;
                C_number_b={9'd0,S_snapshot[137:131]};
            end
            6:begin
                C_number_a=percent(S_snapshot[164:144]);
                C_number_b=percent(S_snapshot[185:165]);
            end
            default:begin end
        endcase
    end
    function [39:0] decimal;
        input [19:0] digits;
        integer i;
        begin
            for(i=0;i<5;i=i+1) decimal[i*8+:8]=8'd48+{4'd0,digits[i*4+:4]};
        end
    endfunction
    // One byte per cycle instead of unrolling three forty-byte clipping chains.
    reg [5:0] S_clip_index,S_clip_used,S_clip_length;
    reg [5:0] S_clip_limit,S_clip_cells;
    reg S_clip_pending;
    wire S_clip_alert=S_snapshot[3469];
    wire [7:0] S_clip_value=S_text[319:312];
    wire [5:0] S_byte_offset=S_clip_alert && !S_title_row && S_ui_row==2 ? S_clip_length : 6'd0;
    function [63:0] hex32;
        input [31:0] value;
        integer i;
        reg [3:0] digit;
        begin
            for(i=0;i<8;i=i+1) begin digit=value[i*4+:4]; hex32[i*8+:8]=digit<10 ? 8'd48+digit : 8'd55+digit; end
        end
    endfunction
    function [15:0] decimal2;
        input [19:0] digits;
        begin
            decimal2={8'd48+{4'd0,digits[7:4]},8'd48+{4'd0,digits[3:0]}};
        end
    endfunction
    function [23:0] decimal3;
        input [19:0] digits;
        begin
            decimal3={8'd48+{4'd0,digits[11:8]},8'd48+{4'd0,digits[7:4]},8'd48+{4'd0,digits[3:0]}};
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
                C_length=S_clip_length;
            end else if(!S_title_row && S_ui_row==2) begin
                C_text=S_snapshot[3462:3143]; C_y=256;
                C_length=S_snapshot[3468:3463]-S_clip_length;
            end
        end else if(S_title_row) begin
            C_x=8; C_y=456; C_layer=0; C_text=S_label; C_length=0;
            if(S_view[22] && !S_flags[7] && S_row<9 && S_label_length!=0) begin
                if(S_view[21:19]==4) begin
                    case(S_row)
                        0,3,6:C_x=2;
                        1,4,7:C_x=215;
                        default:C_x=428;
                    endcase
                    case(S_row)
                        0,1,2:C_y=144;
                        3,4,5:C_y=304;
                        default:C_y=464;
                    endcase
                    C_length=S_clip_length;
                    if({1'b0,S_view[12:7]}=={1'b0,S_view[18:13]}+S_row) C_color=1;
                end else if(S_row==0) C_length=S_clip_length;
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
                        C_text={ 56'hb5b1c7b0d6b520,S_number[15] ? 8'd45 : 8'd43,decimal(S_digits_a),216'd0 }; C_length=13;
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
                    2:begin C_text={32'h46505320,S_snapshot[49] ? decimal(S_digits_a) : 40'h3f3f3f3f3f,248'd0}; C_length=9; end
                    3:begin C_text={72'hcad3c6b5c7b7d4d820,hex32(S_snapshot[98:67]),184'd0}; C_length=17; end
                    4:begin C_text={72'hd2f4c6b5c7b7d4d820,hex32(S_snapshot[130:99]),184'd0}; C_length=17; end
                    5:begin C_text={40'h4954454d20,decimal2(S_digits_a),8'h2f,
                        decimal2(S_digits_b),240'd0}; C_length=10; end
                    6:begin
                        if(S_snapshot[50]) begin C_text={24'h425720,decimal3(S_digits_a),8'h25,16'h2047,
                            decimal3(S_digits_b),8'h25,216'd0}; C_length=13; end
                        else begin C_text=320'h425720554e4b4e4f574e0000000000000000000000000000000000000000000000000000000000; C_length=10; end
                    end
                    7:begin C_text=320'hd7cad4b420554e4b4e4f574e00000000000000000000000000000000000000000000000000000000; C_length=6'd12; end
                    default:begin end
                endcase
            end
        end
    end
    assign O_idle=S_state==IDLE;
    assign O_snapshot_done=EXTERNAL_SNAPSHOT!=0 && S_state==RESULT && I_done_valid && !I_reset;
    assign O_begin_valid=!I_reset && S_state==BEGIN_FRAME;
    assign O_line_valid=!I_reset && S_state==LINE_CMD && S_cmd_length!=0;
    assign O_layer=S_cmd_layer;
    assign O_line=S_cmd_line;
    assign O_x=S_cmd_x;
    assign O_y=S_cmd_y;
    assign O_color=S_cmd_color;
    assign O_lock=S_cmd_lock;
    assign O_length=S_cmd_length;
    assign O_byte_valid=!I_reset && S_state==BYTES;
    assign O_byte_data=S_text[319:312];
    assign O_byte_last=S_byte+6'd1==S_length;
    assign O_finish_valid=!I_reset && S_state==FINISH;
    assign O_done_ready=!I_reset && S_state==RESULT;
    task next_line;
        begin
            if(S_row==23) S_state<=FINISH;
            else begin
                S_row<=S_row+1'b1; S_serial_label<=0; S_title_byte<=0;
                S_state<=EXTERNAL_TITLES!=0 ? TITLE_FETCH : CLIP_START;
            end
        end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_applied_valid<=0; S_row<=0; S_byte<=0; S_skip<=0; S_text<=0; S_length<=0;
            S_digits_a<=0; S_digits_b<=0; O_error<=0;
            S_clip_index<=0; S_clip_used<=0; S_clip_length<=0; S_clip_pending<=0;
            S_clip_limit<=0; S_clip_cells<=0;
            S_cmd_layer<=0; S_cmd_lock<=0; S_cmd_line<=0; S_cmd_x<=0;
            S_cmd_y<=0; S_cmd_color<=0; S_cmd_length<=0;
            S_serial_label<=0; S_title_byte<=0;
        end else case(S_state)
            IDLE:if(S_start) begin S_row<=0; S_serial_label<=0; S_title_byte<=0; S_state<=BEGIN_FRAME; end
            BEGIN_FRAME:if(I_begin_ready) S_state<=EXTERNAL_TITLES!=0 ? TITLE_FETCH : CLIP_START;
            TITLE_FETCH:S_state<=S_fetch_title ? TITLE_WAIT : CLIP_START;
            TITLE_WAIT:begin
                S_serial_label<={S_serial_label[311:0],I_title_data};
                if(S_title_byte==39) S_state<=CLIP_START;
                else begin S_title_byte<=S_title_byte+6'd1; S_state<=TITLE_FETCH; end
            end
            CLIP_START:begin
                S_clip_index<=0; S_clip_used<=0; S_clip_length<=0; S_clip_pending<=0;
                S_text<=C_text;
                S_clip_limit<=S_clip_alert ? S_snapshot[3468:3463] : S_label_length;
                S_clip_cells<=S_clip_alert ? 6'd32 : (S_view[21:19]==4 ? 6'd13 : 6'd39);
                if((S_clip_alert && !S_title_row && (S_ui_row==1 || S_ui_row==2)) ||
                    (!S_clip_alert && S_title_row && S_row<9 && S_view[22] && !S_flags[7]))
                    S_state<=CLIP_SCAN;
                else S_state<=NUMBER_A;
            end
            CLIP_SCAN:begin
                if(S_clip_index>=S_clip_limit || S_clip_index==40 ||
                    (!S_clip_pending && S_clip_used>=S_clip_cells)) S_state<=NUMBER_A;
                else begin
                    S_text<={S_text[311:0],8'd0};
                    S_clip_index<=S_clip_index+1'b1;
                    if(S_clip_pending) begin
                        S_clip_length<=S_clip_index+1'b1; S_clip_used<=S_clip_used+1'b1; S_clip_pending<=0;
                    end else if(S_clip_value>=8'ha1 && S_clip_value<=8'hfe) S_clip_pending<=1;
                    else begin S_clip_length<=S_clip_index+1'b1; S_clip_used<=S_clip_used+1'b1; end
                end
            end
            NUMBER_A:if(S_number_ready) S_state<=WAIT_A;
            WAIT_A:if(S_number_done) begin S_digits_a<=S_number_digits; S_state<=NUMBER_B; end
            NUMBER_B:if(S_number_ready) S_state<=WAIT_B;
            WAIT_B:if(S_number_done) begin
                S_digits_b<=S_number_digits; S_state<=LINE_CMD;
                S_cmd_layer<=C_layer; S_cmd_line<=S_title_row ? S_row[3:0] : S_ui_row;
                S_cmd_x<=C_x; S_cmd_y<=C_y; S_cmd_color<=C_color; S_cmd_length<=C_length;
                S_cmd_lock<=!S_title_row && !(S_snapshot[3469] && (S_ui_row==1 || S_ui_row==2));
            end
            LINE_CMD:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(S_cmd_length==0) next_line;
                else if(I_line_ready) begin
                    S_text<=C_text; S_length<=S_cmd_length; S_byte<=0; S_skip<=S_byte_offset;
                    S_state<=S_byte_offset==0 ? BYTES : SKIP_BYTES;
                end
            SKIP_BYTES:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else begin
                    S_text<={S_text[311:0],8'd0}; S_skip<=S_skip-1'b1;
                    if(S_skip==1) S_state<=BYTES;
                end
            BYTES:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(I_byte_ready) begin
                    S_text<={S_text[311:0],8'd0};
                    if(S_byte+6'd1==S_length) S_state<=LINE_WAIT;
                    else S_byte<=S_byte+1'b1;
                end
            LINE_WAIT:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(I_line_ready) next_line;
            FINISH:if(I_done_valid) begin O_error<=I_error; S_state<=RESULT; end
                else if(I_finish_ready) S_state<=RESULT;
            RESULT:if(I_done_valid) begin O_error<=I_error; S_applied_valid<=1; S_state<=IDLE; end
            default:S_state<=IDLE;
        endcase
    end
endmodule

// Unsigned 16-bit binary -> five packed BCD digits, one input bit per cycle.
module osd_binary_decimal (
    input wire I_clk,I_reset,I_start_valid,
    output wire O_start_ready,
    input wire [15:0] I_value,
    output reg O_done_valid,
    input wire I_done_ready,
    output reg [19:0] O_digits
);
    reg S_busy;
    reg [3:0] S_bit;
    reg [15:0] S_binary;
    reg [19:0] S_digits;
    reg [19:0] C_adjust;
    wire [19:0] S_next={C_adjust[18:0],S_binary[15]};
    integer i;
    assign O_start_ready=!I_reset && !S_busy && !O_done_valid;
    always @* begin
        C_adjust=S_digits;
        for(i=0;i<5;i=i+1)
            if(S_digits[i*4+:4]>=5) C_adjust[i*4+:4]=S_digits[i*4+:4]+4'd3;
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_busy<=0; S_bit<=0; S_binary<=0; S_digits<=0; O_digits<=0; O_done_valid<=0;
        end else begin
            if(O_done_valid && I_done_ready) O_done_valid<=0;
            if(I_start_valid && O_start_ready) begin
                S_busy<=1; S_bit<=0; S_binary<=I_value; S_digits<=0;
            end else if(S_busy) begin
                S_digits<=S_next; S_binary<={S_binary[14:0],1'b0}; S_bit<=S_bit+1'b1;
                if(S_bit==15) begin O_digits<=S_next; O_done_valid<=1; S_busy<=0; end
            end
        end
    end
endmodule
