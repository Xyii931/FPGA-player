// Host-domain byte console. RX has its own two-line queue while replies transmit.
// Long-operation completion observes real owner busy/terminal signals, not delays.
module player_console #(
    parameter integer LOG_CYCLES=62500000
) (
    input wire I_clk,I_reset,I_rx_valid,I_rx_frame_error,
    input wire [7:0] I_rx_data,
    output wire O_tx_valid,
    input wire I_tx_ready,
    output wire [7:0] O_tx_data,
    output wire O_request_valid,
    input wire I_request_ready,
    output reg [4:0] O_request_op,
    output reg [3:0] O_request_key,
    output reg [15:0] O_request_value,
    output reg [5:0] O_request_text_length,
    output reg [319:0] O_request_text,
    input wire I_result_valid,
    output wire O_result_ready,
    input wire [3:0] I_result_error,
    input wire I_result_pending,
    input wire [15:0] I_result_base,I_result_effective,
    input wire I_player_busy,I_active,I_fault,I_session_busy,I_session_ready,I_board_interrupt,I_selftest,
    input wire [3:0] I_player_error,I_session_error,
    input wire [5:0] I_current_index,
    input wire [6:0] I_count,
    input wire [31:0] I_status,I_video_und,I_audio_und,
    input wire [15:0] I_media_status,
    input wire [15:0] I_fps,
    input wire [20:0] I_mem_busy_cycles,I_mem_grant_cycles,
    output wire O_control_hold,
    output wire [31:0] O_dropped_lines
);
    localparam [3:0] IDLE=0,READ_ADDR=1,READ_WAIT=2,READ_CHAR=3,RELEASE=4,DECODE=5,
        GUARD_A=6,GUARD_B=7,OFFER=8,RESULT=9,SEND=10;
    localparam [4:0] NEXT=0,PREV=1,PLAY=2,PLAY_INDEX=3,PAUSE=4,RESUME=5,
        SET=6,GET=7,DEFAULT=8,SCAN=9,RELOAD=10,MODE=11,SAVE=12,ALERT=13,ALERT_OFF=14,RECOVER=15;
    reg [3:0] S_state;
    wire S_line_valid;
    wire [7:0] S_line_length,S_read_data;
    wire [1:0] S_line_error;
    reg [7:0] S_position;
    reg [127:0] S_tokens[0:2];
    reg [127:0] S_word;
    reg [4:0] S_word_length;
    reg [2:0] S_word_index,S_token_count;
    reg [1:0] S_parse_error;
    reg S_in_text;
    reg [2047:0] S_reply;
    reg [8:0] S_reply_left;
    reg S_hold_dispatch,S_long_active,S_long_scan,S_long_seen_busy;
    reg [15:0] S_next_tag,S_long_tag,S_terminal_tag;
    reg S_terminal_pending;
    reg [3:0] S_terminal_error;
    reg S_log_enabled,S_log_due,S_selftest_due;
    reg [31:0] S_log_count;
    uart_line_buffer u_lines (
        .I_clk(I_clk),.I_reset(I_reset),.I_rx_valid(I_rx_valid),.I_frame_error(I_rx_frame_error),.I_rx_data(I_rx_data),
        .O_line_valid(S_line_valid),.I_line_ready(S_state==RELEASE),.O_line_length(S_line_length),
        .O_line_error(S_line_error),.I_read_address(S_position[6:0]),.O_read_data(S_read_data),.O_dropped_lines(O_dropped_lines)
    );
    assign O_tx_valid=!I_reset && S_state==SEND && S_reply_left!=0;
    assign O_tx_data=S_reply[(S_reply_left-1'b1)*8+:8];
    assign O_request_valid=!I_reset && S_state==OFFER;
    assign O_result_ready=!I_reset && S_state==RESULT;
    assign O_control_hold=S_hold_dispatch || S_long_active;
    function [7:0] upper;
        input [7:0] value;
        begin upper=value>=97 && value<=122 ? value-8'd32 : value; end
    endfunction
    function [32:0] number;
        input [127:0] token;
        integer i;
        reg [7:0] ch;
        reg [31:0] magnitude;
        reg negative,started,digit,good;
        begin
            magnitude=0; negative=0; started=0; digit=0; good=1;
            for(i=15;i>=0;i=i-1) begin
                ch=token[i*8+:8];
                if(ch!=0 || started) begin
                    if(!started && (ch==45 || ch==43)) negative=ch==45;
                    else if(ch>=48 && ch<=57) begin
                        if(magnitude>3276 || magnitude*10+(ch-48)>32768) good=0;
                        else magnitude=magnitude*10+(ch-48);
                        digit=1;
                    end else good=0;
                    started=1;
                end
            end
            if(!negative && magnitude>32767) good=0;
            number={good && digit,negative ? 32'd0-magnitude : magnitude};
        end
    endfunction
    function [4:0] config_key;
        input [127:0] token;
        begin case(token)
            "AUTO":config_key=16;
            "INTERVAL":config_key=17;
            "TRANSITION":config_key=18;
            "TRANSITION_MS":config_key=19;
            "ORDER":config_key=20;
            "LAYOUT":config_key=21;
            "ROTATION":config_key=22;
            "SCALER":config_key=23;
            "BRIGHTNESS":config_key=24;
            "VOLUME":config_key=25;
            "MUTE":config_key=26;
            "AV_OFFSET_MS":config_key=27;
            "HUD":config_key=28;
            "CONTRAST":config_key=29;
            "SATURATION":config_key=30;
            default:config_key=0;
        endcase end
    endfunction
    function [32:0] config_value;
        input [3:0] key;
        input [127:0] token;
        reg [32:0] parsed;
        begin
            parsed=number(token);
            config_value=parsed;
            if(key==6 && parsed[32]) case(parsed[31:0])
                0:config_value={1'b1,32'd0}; 90:config_value={1'b1,32'd1};
                180:config_value={1'b1,32'd2}; 270:config_value={1'b1,32'd3};
                default:config_value=0;
            endcase
            else if(!parsed[32]) begin
                config_value=0;
                case(key)
                    0,10,12:case(token) "ON":config_value={1'b1,32'd1}; "OFF":config_value={1'b1,32'd0}; default:begin end endcase
                    2:case(token)
                        "FADE":config_value={1'b1,32'd0}; "SLIDE":config_value={1'b1,32'd1};
                        "PUSH":config_value={1'b1,32'd2}; "WIPE":config_value={1'b1,32'd3};
                        "BLINDS":config_value={1'b1,32'd4}; "MOSAIC":config_value={1'b1,32'd5};
                        "ZOOM":config_value={1'b1,32'd6}; "RANDOM":config_value={1'b1,32'd7}; default:begin end
                    endcase
                    4:case(token) "LIST":config_value={1'b1,32'd0}; "NAME":config_value={1'b1,32'd1}; "RANDOM":config_value={1'b1,32'd2}; default:begin end endcase
                    5:case(token)
                        "FULL":config_value={1'b1,32'd0}; "PIP":config_value={1'b1,32'd1};
                        "DUAL":config_value={1'b1,32'd2}; "QUAD":config_value={1'b1,32'd3};
                        "THUMB":config_value={1'b1,32'd4}; default:begin end
                    endcase
                    7:case(token) "NEAREST":config_value={1'b1,32'd0}; "BILINEAR":config_value={1'b1,32'd1}; default:begin end endcase
                    default:begin end
                endcase
            end
        end
    endfunction
    function [39:0] decimal;
        input [15:0] value;
        integer i;
        reg [15:0] rest;
        reg [7:0] digit;
        begin
            rest=value; decimal=0;
            for(i=0;i<5;i=i+1) begin digit=8'd48+rest%10; decimal[i*8+:8]=digit; rest=rest/10; end
        end
    endfunction
    function [63:0] hex32;
        input [31:0] value;
        integer i;
        reg [3:0] nibble;
        begin
            for(i=0;i<8;i=i+1) begin
                nibble=value[i*4+:4]; hex32[i*8+:8]=nibble<10 ? 8'd48+nibble : 8'd65+nibble-8'd10;
            end
        end
    endfunction
    task reply;
        input [2047:0] message;
        input [8:0] length;
        begin S_reply<=message; S_reply_left<=length; S_state<=SEND; end
    endtask
    task error_reply;
        input [3:0] error;
        begin case(error)
            1:reply("ERR syntax\r\n",12);
            2:reply("ERR range\r\n",11);
            3:reply("ERR unsupported\r\n",17);
            4:reply("ERR busy\r\n",10);
            5:reply("ERR no_media\r\n",14);
            7:reply("ERR superseded\r\n",16);
            default:reply("ERR io\r\n",8);
        endcase end
    endtask
    task dispatch;
        input [4:0] op;
        input [3:0] key;
        input [15:0] value;
        reg long_command;
        begin
            long_command=op==NEXT || op==PREV || op==PLAY_INDEX || op==SCAN || op==RELOAD;
            if(S_long_active && (long_command || op==DEFAULT || (op==SET && key>=5 && key<=7))) error_reply(4);
            else begin
                O_request_op<=op; O_request_key<=key; O_request_value<=value;
                // Hold AUTO before testing idle/dispatching; closes the idle/AUTO race.
                S_hold_dispatch<=long_command;
                S_state<=long_command ? GUARD_A : OFFER;
            end
        end
    endtask
    task status_reply;
        input selftest;
        begin
            if(selftest) reply({"OK SELFTEST flags=0x",hex32(I_status),
                " hardware_tests=NOT_TESTED resources=UNKNOWN\r\nEND\r\n"},79);
            else reply({"STAT flags=0x",hex32(I_status)," item=",decimal({10'd0,I_current_index}),
                "/",decimal({9'd0,I_count})," fps=",decimal(I_fps)," vund=0x",hex32(I_video_und),
                " aund=0x",hex32(I_audio_und)," mem_busy=0x",hex32({11'd0,I_mem_busy_cycles}),
                " grant=0x",hex32({11'd0,I_mem_grant_cycles})," rd=UNKNOWN dropped=0x",hex32(O_dropped_lines)," media=0x",hex32({16'd0,I_media_status}),"\r\n"},166);
        end
    endtask
    wire [4:0] S_key=config_key(S_tokens[1]);
    wire [32:0] S_value=config_value(S_key[3:0],S_tokens[2]);
    wire [32:0] S_index=number(S_tokens[1]);
    wire [15:0] S_base_magnitude=I_result_base[15] ? 16'd0-I_result_base : I_result_base;
    wire [15:0] S_effective_magnitude=I_result_effective[15] ? 16'd0-I_result_effective : I_result_effective;
    integer S_i;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_position<=0; S_word<=0; S_word_length<=0; S_word_index<=0; S_token_count<=0;
            S_parse_error<=0; S_in_text<=0; for(S_i=0;S_i<3;S_i=S_i+1) S_tokens[S_i]<=0;
            S_reply<=0; S_reply_left<=0; S_hold_dispatch<=0;
            S_long_active<=0; S_long_scan<=0; S_long_seen_busy<=0; S_next_tag<=1; S_long_tag<=0;
            S_terminal_pending<=0; S_terminal_tag<=0; S_terminal_error<=0;
            S_log_enabled<=0; S_log_due<=0; S_log_count<=0; S_selftest_due<=0;
            O_request_op<=0; O_request_key<=0; O_request_value<=0; O_request_text_length<=0; O_request_text<=0;
        end else begin
            if(I_selftest) S_selftest_due<=1;
            if(!S_log_enabled) begin S_log_count<=0; S_log_due<=0; end
            else if(S_log_count==LOG_CYCLES-1) begin S_log_count<=0; S_log_due<=1; end
            else S_log_count<=S_log_count+1'b1;
            if(S_long_active) begin
                if((S_long_scan && I_session_busy) || (!S_long_scan && I_player_busy)) S_long_seen_busy<=1;
                if(I_board_interrupt || I_fault || (!S_long_scan && !I_session_ready) ||
                    (S_long_scan && !I_session_busy && !I_session_ready) || (S_long_seen_busy &&
                    (S_long_scan ? !I_session_busy : !I_player_busy))) begin
                    S_long_active<=0; S_terminal_pending<=1; S_terminal_tag<=S_long_tag;
                    S_terminal_error<=I_board_interrupt ? 4'd7 : (I_fault || (!S_long_scan && !I_session_ready)) ? 4'd6 :
                        (S_long_scan ? (!I_session_ready || I_session_error!=0 ? 4'd6 : 4'd0) :
                            (!I_active || I_player_error!=0 ? 4'd6 : 4'd0));
                end
            end
            case(S_state)
                IDLE:if(S_terminal_pending) begin
                    S_terminal_pending<=0;
                    if(S_terminal_error==0) reply({"DONE tag=",decimal(S_terminal_tag),"\r\n"},16);
                    else if(S_terminal_error==7) reply({"ERR tag=",decimal(S_terminal_tag)," superseded\r\n"},26);
                    else reply({"ERR tag=",decimal(S_terminal_tag)," io\r\n"},18);
                end else if(S_line_valid) begin
                    S_position<=0; S_word<=0; S_word_length<=0; S_word_index<=0; S_token_count<=0;
                    S_parse_error<=0; S_in_text<=0; O_request_text<=0; O_request_text_length<=0;
                    for(S_i=0;S_i<3;S_i=S_i+1) S_tokens[S_i]<=0;
                    if(S_line_error!=0) begin S_token_count<=0; S_state<=RELEASE; end
                    else S_state<=READ_ADDR;
                end else if(S_selftest_due) begin S_selftest_due<=0; status_reply(1); end
                else if(S_log_due) begin S_log_due<=0; status_reply(0); end
                READ_ADDR:S_state<=READ_WAIT;
                READ_WAIT:S_state<=READ_CHAR;
                READ_CHAR:begin
                    if(S_position==S_line_length) begin
                        if(!S_in_text && S_word_length!=0 && S_word_index<3) S_tokens[S_word_index]<=S_word;
                        S_token_count<=S_in_text ? 3'd3 : S_word_index+(S_word_length!=0);
                        S_state<=RELEASE;
                    end else begin
                        S_position<=S_position+1'b1; S_state<=READ_ADDR;
                        if(S_in_text || (S_word_index==2 && S_tokens[0]=="ALERT" && S_read_data!=32 && S_read_data!=9)) begin
                            S_in_text<=1;
                            if(O_request_text_length==40) S_parse_error<=2;
                            else begin O_request_text<={O_request_text[311:0],S_read_data}; O_request_text_length<=O_request_text_length+1'b1; end
                        end else if(S_read_data==32 || S_read_data==9) begin
                            if(S_word_length!=0) begin
                                if(S_word_index<3) S_tokens[S_word_index]<=S_word; else S_parse_error<=1;
                                S_word_index<=S_word_index+1'b1; S_word<=0; S_word_length<=0;
                            end
                        end else if(S_word_index>=3 || S_word_length==16) S_parse_error<=1;
                        else begin S_word<={S_word[119:0],upper(S_read_data)}; S_word_length<=S_word_length+1'b1; end
                    end
                end
                RELEASE:begin
                    // The line slot is released at this edge; cache errors first.
                    if(S_line_error==3) error_reply(4);
                    else if(S_line_error==1) error_reply(2);
                    else if(S_line_error==2) error_reply(6);
                    else S_state<=DECODE;
                end
                DECODE:if(S_parse_error!=0 || S_token_count==0) error_reply(S_parse_error!=0 ? {2'd0,S_parse_error} : 4'd1);
                    else if(S_tokens[0]=="PING" && S_token_count==1) reply("PONG\r\n",6);
                    else if(S_tokens[0]=="VER" && S_token_count==1) reply("OK FPGA-player DEV git=UNKNOWN\r\n",32);
                    else if(S_tokens[0]=="STAT" && S_token_count==1) status_reply(0);
                    else if(S_tokens[0]=="SELFTEST" && S_token_count==1) status_reply(1);
                    else if(S_tokens[0]=="LOG" && S_token_count==2 && (S_tokens[1]=="ON" || S_tokens[1]=="OFF")) begin
                        S_log_enabled<=S_tokens[1]=="ON"; reply("OK\r\n",4);
                    end else if(S_tokens[0]=="NEXT" && S_token_count==1) dispatch(NEXT,0,0);
                    else if(S_tokens[0]=="PREV" && S_token_count==1) dispatch(PREV,0,0);
                    else if(S_tokens[0]=="PLAY" && S_token_count==1) dispatch(PLAY,0,0);
                    else if(S_tokens[0]=="PLAY" && S_token_count==2) begin
                        if(S_index[32] && !S_index[31] && S_index[31:0]<64) dispatch(PLAY_INDEX,0,S_index[15:0]); else error_reply(2);
                    end else if(S_tokens[0]=="PAUSE" && S_token_count==1) dispatch(PAUSE,0,0);
                    else if(S_tokens[0]=="RESUME" && S_token_count==1) dispatch(RESUME,0,0);
                    else if(S_tokens[0]=="SET" && S_token_count==3) begin
                        if(!S_key[4]) error_reply(3);
                        else if(!S_value[32]) error_reply(2);
                        else dispatch(SET,S_key[3:0],S_value[15:0]);
                    end else if(S_tokens[0]=="GET" && S_token_count==2) begin
                        if(!S_key[4]) error_reply(3); else dispatch(GET,S_key[3:0],0);
                    end else if(S_tokens[0]=="DEFAULT" && S_token_count==1) dispatch(DEFAULT,0,0);
                    else if(S_tokens[0]=="SAVE" && S_token_count==1) dispatch(SAVE,0,0);
                    else if(S_tokens[0]=="SCAN" && S_token_count==1) dispatch(SCAN,0,0);
                    else if(S_tokens[0]=="RELOAD" && S_token_count==1) dispatch(RELOAD,0,0);
                    else if(S_tokens[0]=="RECOVER" && S_token_count==1) dispatch(RECOVER,0,0);
                    else if(S_tokens[0]=="MODE" && S_token_count==2) begin
                        case(S_tokens[1])
                            "PLAY":dispatch(MODE,0,0); "THUMB":dispatch(MODE,0,1);
                            "MENU":dispatch(MODE,0,2); "SELFTEST":dispatch(MODE,0,3);
                            default:error_reply(2);
                        endcase
                    end else if(S_tokens[0]=="ALERT" && S_token_count==2 && S_tokens[1]=="OFF") dispatch(ALERT_OFF,0,0);
                    else if(S_tokens[0]=="ALERT" && S_token_count==3 && S_in_text) begin
                        if(!S_index[32] || S_index[31:0]<1 || S_index[31:0]>600) error_reply(2);
                        else dispatch(ALERT,0,S_index[15:0]);
                    end else error_reply(1);
                GUARD_A:S_state<=GUARD_B;
                GUARD_B:S_state<=OFFER;
                OFFER:if(I_request_ready) S_state<=RESULT;
                RESULT:if(I_result_valid) begin
                    S_hold_dispatch<=0;
                    if(I_result_error!=0) error_reply(I_result_error);
                    else if(I_result_pending) begin
                        S_long_active<=1; S_long_scan<=O_request_op==SCAN || O_request_op==RELOAD;
                        S_long_seen_busy<=0; S_long_tag<=S_next_tag;
                        S_next_tag<=S_next_tag==16'hffff ? 16'd1 : S_next_tag+1'b1;
                        reply({"OK pending tag=",decimal(S_next_tag),"\r\n"},22);
                    end else if(O_request_op==GET) reply({"OK base=",I_result_base[15] ? 8'd45 : 8'd43,
                        decimal(S_base_magnitude)," effective=",I_result_effective[15] ? 8'd45 : 8'd43,
                        decimal(S_effective_magnitude),"\r\n"},33);
                    else reply("OK\r\n",4);
                end
                SEND:if(I_tx_ready && S_reply_left!=0) begin
                    S_reply_left<=S_reply_left-1'b1;
                    if(S_reply_left==1) S_state<=IDLE;
                end
                default:begin S_state<=IDLE; S_hold_dispatch<=0; end
            endcase
        end
    end
endmodule
