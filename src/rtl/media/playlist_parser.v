// Read-only PLAYLIST.TXT stream parser. Outputs are tentative index candidates.
// Strings must be copied while item_valid is held, before acknowledging the item.
module playlist_parser (
    input wire I_clk,I_reset,I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,I_abort,I_stream_error,
    output wire O_busy,O_item_valid,
    input wire I_item_ready,
    output wire [5:0] O_item_index,
    output reg [9:0] O_duration,O_transition_ms,
    output reg [2:0] O_transition,
    output reg [6:0] O_policy,
    output reg [6:0] O_file_length,O_audio_length,
    output reg [5:0] O_title_length,
    input wire [1:0] I_string_kind,
    input wire [6:0] I_string_address,
    output reg [7:0] O_string_data,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [7:0] O_warning,
    output reg [6:0] O_item_count,
    output reg [1:0] O_order,
    output reg O_order_explicit,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation
);
    localparam [4:0] IDLE=0,RECEIVE=1,LEFT=2,RIGHT=3,CLASSIFY=4,EQUAL=5,
        KEY_RIGHT=6,VALUE_LEFT=7,VALUE_RIGHT=8,DECODE=9,NUMBER=10,
        PATH_START=11,PATH_SCAN=12,PATH_END=13,PATH_COPY=14,
        TITLE_START=15,TITLE_SCAN=16,TITLE_COPY=17,BOUNDARY=18,
        EMIT=19,APPLY_SECTION=20,INIT_ITEM=21,RESULT=22,TOKEN_SCAN=23,
        SECTION_DECODE=24,KEY_DECODE=25;
    localparam [1:0] NO_SECTION=0,GLOBAL=1,ITEM=2;
    localparam [3:0] NO_KEY=0,INTERVAL=1,TRANSITION=2,TRANSITION_MS=3,
        ORDER=4,BGM=5,FILE=6,AUDIO=7,TITLE=8,DURATION=9;
    reg [4:0] S_state;
    reg [7:0] S_line[0:254];
    reg [7:0] S_file[0:63],S_audio[0:63],S_bgm[0:63],S_path[0:63];
    reg [7:0] S_title[0:39];
    reg [8:0] S_length,S_lo,S_hi,S_cursor,S_value_lo,S_value_hi;
    reg [31:0] S_size,S_position;
    reg S_eof,S_skip_lf,S_overflow,S_boundary_final;
    reg [1:0] S_section,S_next_section;
    reg [3:0] S_key;
    reg [9:0] S_interval,S_global_ms;
    reg [2:0] S_global_transition;
    reg [2:0] S_global_explicit;
    reg [6:0] S_bgm_length,S_path_length,S_component_length,S_copy;
    reg S_component_dots,S_path_bad,S_title_bad,S_title_truncated;
    reg [5:0] S_title_length;
    reg [19:0] S_number;
    reg S_number_bad;
    reg [127:0] S_token;
    reg [4:0] S_token_length,S_token_return;
    wire S_input_end=S_position+32'd1==S_size;
    wire [7:0] S_char=S_cursor<255 ? S_line[S_cursor[7:0]] : 8'd0;
    wire S_value_done=S_cursor==S_value_hi;
    wire S_relative=S_value_lo<S_value_hi && S_line[S_value_lo[7:0]]!=8'h2f;

    function [7:0] fold;
        input [7:0] value;
        begin fold=value>=65 && value<=90 ? value+8'd32 : value; end
    endfunction
    function space;
        input [7:0] value;
        begin space=value==8'h20 || value==8'h09; end
    endfunction
    function legal_path;
        input [7:0] value;
        begin legal_path=value>=32 && value<=126 && value!=34 && value!=42 &&
            value!=58 && value!=60 && value!=62 && value!=63 && value!=92 && value!=124; end
    endfunction
    // Tokens are collected serially; never expand 16 dynamic reads of S_line.
    function token;
        input [127:0] expected;
        input integer length;
        begin token=S_token_length==length && S_token==expected; end
    endfunction
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_busy=!I_reset && S_state!=IDLE;
    assign O_byte_ready=!I_reset && S_state==RECEIVE && !I_abort && !I_stream_error;
    assign O_item_valid=!I_reset && S_state==EMIT && !I_abort && !I_stream_error;
    assign O_item_index=O_item_count[5:0];
    assign O_done_valid=!I_reset && S_state==RESULT;
    // No combinational string bus; bounds follow the current candidate's lengths.
    always @(posedge I_clk) begin
        O_string_data<=0;
        if(O_item_valid) begin
            case(I_string_kind)
                0:if(I_string_address<O_file_length) O_string_data<=S_file[I_string_address[5:0]];
                1:if(I_string_address<O_audio_length) O_string_data<=S_audio[I_string_address[5:0]];
                2:if(I_string_address<O_title_length) O_string_data<=S_title[I_string_address[5:0]];
                default:O_string_data<=0;
            endcase
        end
    end
    task line_finish;
        begin
            S_length<=0; S_overflow<=0;
            if(S_eof) begin S_next_section<=NO_SECTION; S_boundary_final<=1; S_state<=BOUNDARY; end
            else S_state<=RECEIVE;
        end
    endtask
    task bad_value;
        input integer bit_index;
        begin O_warning[bit_index]<=1; line_finish; end
    endtask
    task set_transition;
        input [2:0] value;
        begin
            if(S_section==GLOBAL) begin S_global_transition<=value; S_global_explicit[1]<=1; end
            else begin O_transition<=value; O_policy[1]<=1; end
        end
    endtask
    task begin_token;
        input [4:0] return_state;
        begin
            S_token<=0; S_token_length<=0; S_token_return<=return_state;
            S_cursor<=S_lo; S_state<=TOKEN_SCAN;
        end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_length<=0; S_lo<=0; S_hi<=0; S_cursor<=0;
            S_value_lo<=0; S_value_hi<=0; S_size<=0; S_position<=0;
            S_eof<=0; S_skip_lf<=0; S_overflow<=0; S_boundary_final<=0;
            S_section<=NO_SECTION; S_next_section<=NO_SECTION; S_key<=NO_KEY;
            S_interval<=10; S_global_ms<=400; S_global_transition<=0;
            S_global_explicit<=0; O_policy<=0;
            S_bgm_length<=0; S_path_length<=0; S_component_length<=0; S_copy<=0;
            S_component_dots<=0; S_path_bad<=0; S_title_bad<=0; S_title_truncated<=0;
            S_title_length<=0; S_number<=0; S_number_bad<=0;
            S_token<=0; S_token_length<=0; S_token_return<=0;
            O_duration<=10; O_transition_ms<=400; O_transition<=0;
            O_file_length<=0; O_audio_length<=0; O_title_length<=0;
            O_error<=0; O_warning<=0; O_item_count<=0; O_order<=1; O_order_explicit<=0; O_tag<=0; O_generation<=0;
        end else begin
            if(S_state!=IDLE && S_state!=RESULT && (I_abort || I_stream_error)) begin
                O_error<=I_abort ? 4'd2 : 4'd1; S_state<=RESULT;
            end else case(S_state)
                IDLE:if(I_start_valid) begin
                    S_size<=I_file_size; S_position<=0; O_tag<=I_tag; O_generation<=I_generation;
                    O_error<=0; O_warning<=0; O_item_count<=0; O_order<=1; O_order_explicit<=0;
                    S_length<=0; S_eof<=0; S_skip_lf<=0; S_overflow<=0;
                    S_section<=NO_SECTION; S_next_section<=NO_SECTION; S_boundary_final<=0;
                    S_interval<=10; S_global_ms<=400; S_global_transition<=0; S_bgm_length<=0;
                    S_global_explicit<=0; O_policy<=0;
                    O_file_length<=0; O_audio_length<=0; O_title_length<=0;
                    if(I_abort || I_stream_error) begin O_error<=I_abort ? 4'd2 : 4'd1; S_state<=RESULT; end
                    else S_state<=I_file_size==0 ? RESULT : RECEIVE;
                end
                RECEIVE:if(I_byte_valid && O_byte_ready) begin
                    S_position<=S_position+32'd1; S_eof<=S_input_end;
                    S_skip_lf<=I_byte_data==13;
                    if(I_byte_last!=S_input_end) begin O_error<=1; S_state<=RESULT; end
                    else if(S_skip_lf && I_byte_data==10) begin
                        if(S_input_end) begin S_lo<=0; S_hi<=0; S_state<=CLASSIFY; end
                    end else if(I_byte_data==10 || I_byte_data==13) begin
                        S_lo<=0; S_hi<=S_length; S_state<=LEFT;
                    end else begin
                        if(S_length<255) begin S_line[S_length[7:0]]<=I_byte_data; S_length<=S_length+9'd1; end
                        else begin S_overflow<=1; O_warning[7]<=1; end
                        if(S_input_end) begin S_lo<=0; S_hi<=S_length<255 ? S_length+9'd1 : S_length; S_state<=LEFT; end
                    end
                end
                LEFT:if(S_overflow) line_finish;
                    else if(S_lo<S_hi && space(S_line[S_lo[7:0]])) S_lo<=S_lo+9'd1;
                    else S_state<=RIGHT;
                RIGHT:if(S_hi>S_lo && space(S_line[S_hi-9'd1])) S_hi<=S_hi-9'd1;
                    else S_state<=CLASSIFY;
                CLASSIFY:if(S_lo==S_hi || S_line[S_lo[7:0]]==35) line_finish;
                    else if(S_line[S_lo[7:0]]==91) begin_token(SECTION_DECODE);
                    else if(S_section==NO_SECTION) bad_value(0);
                    else begin S_cursor<=S_lo; S_state<=EQUAL; end
                TOKEN_SCAN:if(S_cursor==S_hi) S_state<=S_token_return;
                    else begin
                        if(S_token_length<16) S_token<={S_token[119:0],fold(S_char)};
                        if(S_token_length<17) S_token_length<=S_token_length+5'd1;
                        S_cursor<=S_cursor+9'd1;
                    end
                SECTION_DECODE:begin
                    if(token("[global]",8)) S_next_section<=GLOBAL;
                    else if(token("[item]",6)) S_next_section<=ITEM;
                    else begin S_next_section<=NO_SECTION; O_warning[0]<=1; end
                    S_boundary_final<=0; S_state<=BOUNDARY;
                end
                EQUAL:if(S_cursor==S_hi) bad_value(1);
                    else if(S_char==61) begin S_value_lo<=S_cursor+9'd1; S_value_hi<=S_hi; S_hi<=S_cursor; S_state<=KEY_RIGHT; end
                    else S_cursor<=S_cursor+9'd1;
                KEY_RIGHT:if(S_hi==S_lo) bad_value(1);
                    else if(S_hi>S_lo && space(S_line[S_hi-9'd1])) S_hi<=S_hi-9'd1;
                    else begin_token(KEY_DECODE);
                KEY_DECODE:begin
                    S_key<=NO_KEY;
                    if(S_section==GLOBAL && token("interval",8)) S_key<=INTERVAL;
                    else if(token("transition",10)) S_key<=TRANSITION;
                    else if(token("transition_ms",13)) S_key<=TRANSITION_MS;
                    else if(S_section==GLOBAL && token("order",5)) S_key<=ORDER;
                    else if(S_section==GLOBAL && token("bgm",3)) S_key<=BGM;
                    else if(S_section==ITEM && token("file",4)) S_key<=FILE;
                    else if(S_section==ITEM && token("audio",5)) S_key<=AUDIO;
                    else if(S_section==ITEM && token("title",5)) S_key<=TITLE;
                    else if(S_section==ITEM && token("duration",8)) S_key<=DURATION;
                    S_lo<=S_value_lo; S_hi<=S_value_hi; S_state<=VALUE_LEFT;
                end
                VALUE_LEFT:if(S_lo<S_hi && space(S_line[S_lo[7:0]])) S_lo<=S_lo+9'd1;
                    else S_state<=VALUE_RIGHT;
                VALUE_RIGHT:if(S_hi>S_lo && space(S_line[S_hi-9'd1])) S_hi<=S_hi-9'd1;
                    else begin
                        S_value_lo<=S_lo; S_value_hi<=S_hi; S_cursor<=S_lo;
                        if(S_key==TRANSITION || S_key==ORDER) begin_token(DECODE);
                        else S_state<=DECODE;
                    end
                DECODE:begin
                    if(S_key==NO_KEY) bad_value(0);
                    else if(S_key==INTERVAL || S_key==DURATION || S_key==TRANSITION_MS) begin
                        S_number<=0; S_number_bad<=S_lo==S_hi; S_state<=NUMBER;
                    end else if(S_key==TRANSITION) begin
                        if(token("fade",4)) set_transition(0);
                        else if(token("slide",5)) set_transition(1);
                        else if(token("push",4)) set_transition(2);
                        else if(token("wipe",4)) set_transition(3);
                        else if(token("blinds",6)) set_transition(4);
                        else if(token("mosaic",6)) set_transition(5);
                        else if(token("zoom",4)) set_transition(6);
                        else if(token("random",6)) set_transition(7);
                        else O_warning[2]<=1;
                        line_finish;
                    end else if(S_key==ORDER) begin
                        if(token("name",4)) begin O_order<=0; O_order_explicit<=1; end
                        else if(token("list",4)) begin O_order<=1; O_order_explicit<=1; end
                        else if(token("random",6)) begin O_order<=2; O_order_explicit<=1; end
                        else O_warning[2]<=1;
                        line_finish;
                    end else if(S_key==TITLE) S_state<=TITLE_START;
                    else S_state<=PATH_START;
                end
                NUMBER:if(S_value_done) begin
                    if(S_number_bad ||
                        (S_key!=TRANSITION_MS && (S_number<1 || S_number>600)) ||
                        (S_key==TRANSITION_MS && S_number!=200 && S_number!=400 && S_number!=600 && S_number!=1000))
                        O_warning[2]<=1;
                    else if(S_key==INTERVAL) begin S_interval<=S_number[9:0]; S_global_explicit[0]<=1; end
                    else if(S_key==DURATION) begin O_duration<=S_number[9:0]; O_policy[0]<=1; end
                    else if(S_section==GLOBAL) begin S_global_ms<=S_number[9:0]; S_global_explicit[2]<=1; end
                    else begin O_transition_ms<=S_number[9:0]; O_policy[2]<=1; end
                    line_finish;
                end else begin
                    if(S_char<48 || S_char>57 || S_number>20'd10000) S_number_bad<=1;
                    else S_number<=(S_number<<3)+(S_number<<1)+{12'd0,S_char}-20'd48;
                    S_cursor<=S_cursor+9'd1;
                end
                PATH_START:begin
                    S_path_length<=S_relative ? 7'd6 : 7'd0;
                    if(S_relative) begin
                        S_path[0]<=47; S_path[1]<=80; S_path[2]<=76; S_path[3]<=65; S_path[4]<=89; S_path[5]<=47;
                    end
                    S_component_length<=0; S_component_dots<=1; S_path_bad<=S_value_lo==S_value_hi;
                    S_state<=PATH_SCAN;
                end
                PATH_SCAN:if(S_value_done) S_state<=PATH_END;
                    else begin
                        if(!legal_path(S_char)) S_path_bad<=1;
                        if(S_char==47) begin
                            if(S_component_length!=0 && S_component_dots && S_component_length<=2) S_path_bad<=1;
                            S_component_length<=0; S_component_dots<=1;
                            if(S_path_length==0 || S_component_length!=0) begin
                                if(S_path_length<64) begin S_path[S_path_length[5:0]]<=47; S_path_length<=S_path_length+7'd1; end
                                else S_path_bad<=1;
                            end
                        end else begin
                            if(S_path_length<64) begin S_path[S_path_length[5:0]]<=S_char; S_path_length<=S_path_length+7'd1; end
                            else S_path_bad<=1;
                            // Saturate: long components must never wrap back to '.' or '..'.
                            if(S_component_length<65) S_component_length<=S_component_length+7'd1;
                            S_component_dots<=S_component_dots && S_char==46;
                        end
                        S_cursor<=S_cursor+9'd1;
                    end
                PATH_END:if(S_path_bad || S_component_length==0 || (S_component_dots && S_component_length<=2)) bad_value(3);
                    else begin S_copy<=0; S_state<=PATH_COPY; end
                PATH_COPY:begin
                    if(S_key==FILE) S_file[S_copy[5:0]]<=S_path[S_copy[5:0]];
                    else if(S_key==AUDIO) S_audio[S_copy[5:0]]<=S_path[S_copy[5:0]];
                    else S_bgm[S_copy[5:0]]<=S_path[S_copy[5:0]];
                    if(S_copy+7'd1==S_path_length) begin
                        if(S_key==FILE) O_file_length<=S_path_length;
                        else if(S_key==AUDIO) begin O_audio_length<=S_path_length; O_policy[6]<=0; end
                        else S_bgm_length<=S_path_length;
                        line_finish;
                    end else S_copy<=S_copy+7'd1;
                end
                TITLE_START:begin S_title_length<=0; S_title_bad<=0; S_title_truncated<=0; S_state<=TITLE_SCAN; end
                TITLE_SCAN:if(S_value_done) begin
                    if(S_title_bad) bad_value(4);
                    else begin S_copy<=0; if(S_title_truncated) O_warning[4]<=1;
                        if(S_title_length==0) begin O_title_length<=0; line_finish; end
                        else S_state<=TITLE_COPY;
                    end
                end else if(S_char>=32 && S_char<=126) begin
                    if(!S_title_truncated && S_title_length<40) S_title_length<=S_title_length+6'd1;
                    else S_title_truncated<=1;
                    S_cursor<=S_cursor+9'd1;
                end else if(S_char>=161 && S_char<=254 && S_cursor+9'd1<S_value_hi &&
                    S_line[S_cursor+9'd1]>=161 && S_line[S_cursor+9'd1]<=254) begin
                    if(!S_title_truncated && S_title_length<=38) S_title_length<=S_title_length+6'd2;
                    else S_title_truncated<=1;
                    S_cursor<=S_cursor+9'd2;
                end else begin S_title_bad<=1; S_cursor<=S_cursor+9'd1; end
                TITLE_COPY:begin
                    S_title[S_copy[5:0]]<=S_line[S_value_lo+{2'd0,S_copy}];
                    if(S_copy+7'd1=={1'b0,S_title_length}) begin O_title_length<=S_title_length; line_finish; end
                    else S_copy<=S_copy+7'd1;
                end
                BOUNDARY:if(S_section==ITEM) begin
                    if(O_file_length==0) begin O_warning[5]<=1; S_state<=APPLY_SECTION; end
                    else if(O_item_count==64) begin O_warning[6]<=1; S_state<=APPLY_SECTION; end
                    else S_state<=EMIT;
                end else S_state<=APPLY_SECTION;
                EMIT:if(I_item_ready) begin O_item_count<=O_item_count+7'd1; S_state<=APPLY_SECTION; end
                APPLY_SECTION:begin
                    S_section<=S_next_section;
                    if(S_boundary_final) S_state<=RESULT;
                    else if(S_next_section==ITEM) begin
                        O_file_length<=0; O_title_length<=0; O_audio_length<=S_bgm_length;
                        O_duration<=S_interval; O_transition<=S_global_transition; O_transition_ms<=S_global_ms;
                        O_policy<={S_bgm_length!=0,S_global_explicit,3'd0};
                        S_copy<=0; S_state<=INIT_ITEM;
                    end else line_finish;
                end
                INIT_ITEM:if(S_copy<S_bgm_length) begin S_audio[S_copy[5:0]]<=S_bgm[S_copy[5:0]]; S_copy<=S_copy+7'd1; end
                    else line_finish;
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin O_error<=1; S_state<=RESULT; end
            endcase
        end
    end
endmodule
