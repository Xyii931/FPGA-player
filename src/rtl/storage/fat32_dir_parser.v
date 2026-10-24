// Directory entry decoder only. The scanner supplies checked, ordered bytes.
// ASCII LFN is bounded to 64 bytes; OEM/non-ASCII names use a legal short alias.
module fat32_dir_parser (
    input wire I_clk,I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_end_valid,
    output wire O_end_ready,
    input wire [7:0] I_end_error,
    input wire I_cancel,
    output wire O_entry_valid,
    input wire I_entry_ready,
    output reg [7:0] O_attr,
    output reg [31:0] O_size,O_first_cluster,
    output reg [87:0] O_alias,
    output reg [6:0] O_name_length,
    output reg O_is_lfn,
    output wire O_name_valid,
    input wire I_name_ready,
    output wire [7:0] O_name_data,
    output wire O_name_last,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [7:0] O_error,
    output reg [2:0] O_warning
);
    localparam [3:0] IDLE=0,READ_ENTRY=1,CLASSIFY=2,LFN_UNIT=3,
        SHORT_CHECK=4,BUILD_SHORT=5,ENTRY=6,NAME=7,RESULT=8;
    reg [3:0] S_state;
    reg [255:0] S_entry;
    reg [4:0] S_byte_index,S_expected,S_ordinal;
    reg [3:0] S_unit;
    reg [7:0] S_checksum;
    reg [8:0] S_lfn_length;
    reg S_sequence,S_format,S_ascii,S_terminated;
    reg [7:0] S_name[0:63];
    reg [6:0] S_name_index;
    reg [3:0] S_base_length;
    reg [3:0] S_base_trim,S_ext_trim;
    reg [7:0] S_short_byte;
    reg [3:0] S_short_index;
    integer S_i;
    function [7:0] entry_byte;
        input [4:0] index;
        begin entry_byte=S_entry[index*8+:8]; end
    endfunction
    function [4:0] unit_offset;
        input [3:0] unit;
        begin
            case(unit)
                0:unit_offset=1; 1:unit_offset=3; 2:unit_offset=5; 3:unit_offset=7; 4:unit_offset=9;
                5:unit_offset=14; 6:unit_offset=16; 7:unit_offset=18; 8:unit_offset=20; 9:unit_offset=22;
                10:unit_offset=24; 11:unit_offset=28; default:unit_offset=30;
            endcase
        end
    endfunction
    function [7:0] short_checksum;
        input [87:0] alias;
        reg [7:0] sum;
        integer k;
        begin
            sum=0;
            for(k=0;k<11;k=k+1) sum={sum[0],sum[7:1]}+alias[k*8+:8];
            short_checksum=sum;
        end
    endfunction
    function legal_lfn;
        input [7:0] value;
        begin
            legal_lfn=value>=32 && value<=126 && value!=8'h22 && value!=8'h2a && value!=8'h2f &&
                value!=8'h3a && value!=8'h3c && value!=8'h3e && value!=8'h3f && value!=8'h5c && value!=8'h7c;
        end
    endfunction
    function legal_short;
        input [7:0] value;
        begin
            legal_short=legal_lfn(value) && value!=32 && value!=8'h2e && value!=8'h2b && value!=8'h2c &&
                value!=8'h3b && value!=8'h3d && value!=8'h5b && value!=8'h5d;
        end
    endfunction
    wire [4:0] S_unit_offset=unit_offset(S_unit);
    wire [15:0] S_word={entry_byte(S_unit_offset+5'd1),entry_byte(S_unit_offset)};
    wire [8:0] S_unit_index=({4'd0,S_ordinal}-9'd1)*9'd13+{5'd0,S_unit};
    wire [7:0] S_order_byte=entry_byte(0);
    wire [4:0] S_order=S_order_byte[4:0];
    wire S_lfn_header_ok=S_order!=0 && S_order<=20 && !S_order_byte[7] && !S_order_byte[5] &&
        entry_byte(12)==0 && entry_byte(26)==0 && entry_byte(27)==0;
    wire S_valid_long=S_sequence && S_format && S_ascii && S_expected==0 &&
        S_checksum==short_checksum(S_entry[87:0]) && S_lfn_length!=0;
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_byte_ready=!I_reset && S_state==READ_ENTRY && !I_end_valid && !I_cancel;
    assign O_end_ready=!I_reset && S_state==READ_ENTRY && !I_cancel;
    assign O_entry_valid=!I_reset && S_state==ENTRY && !I_cancel;
    assign O_name_valid=!I_reset && S_state==NAME && !I_cancel;
    assign O_name_data=S_name[S_name_index[5:0]];
    assign O_name_last=S_name_index+7'd1==O_name_length;
    assign O_done_valid=!I_reset && S_state==RESULT;
    always @* begin
        S_base_trim=0; S_ext_trim=0;
        for(S_i=0;S_i<8;S_i=S_i+1) if(S_entry[S_i*8+:8]!=8'h20) S_base_trim=S_i+1;
        for(S_i=0;S_i<3;S_i=S_i+1) if(S_entry[(S_i+8)*8+:8]!=8'h20) S_ext_trim=S_i+1;
        S_short_index=S_name_index<S_base_length ? S_name_index[3:0] : 4'd8+S_name_index-S_base_length-1;
        S_short_byte=entry_byte({1'b0,S_short_index});
        if(S_name_index==S_base_length) S_short_byte=8'h2e;
        else if(S_short_byte>=8'h41 && S_short_byte<=8'h5a &&
            ((S_name_index<S_base_length && S_entry[12*8+3]) ||
             (S_name_index>S_base_length && S_entry[12*8+4]))) S_short_byte=S_short_byte+8'd32;
    end
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_entry<=0; S_byte_index<=0; S_expected<=0; S_ordinal<=0; S_unit<=0;
            S_checksum<=0; S_lfn_length<=0; S_sequence<=0; S_format<=0; S_ascii<=0; S_terminated<=0;
            S_name_index<=0; S_base_length<=0;
            O_attr<=0; O_size<=0; O_first_cluster<=0; O_alias<=0;
            O_name_length<=0; O_is_lfn<=0; O_error<=0; O_warning<=0;
        end else begin
            O_warning<=0;
            case(S_state)
                IDLE: if(I_start_valid) begin
                    S_sequence<=0; S_byte_index<=0; O_error<=0; S_state<=READ_ENTRY;
                end
                READ_ENTRY: begin
                    if(I_end_valid && O_end_ready) finish(I_end_error!=0 ? I_end_error : (S_byte_index==0 ? 8'd0 : 8'd3));
                    else if(I_byte_valid && O_byte_ready) begin
                        if(S_byte_index==0 && I_byte_data==0) finish(8'd0);
                        else begin
                            S_entry[S_byte_index*8+:8]<=I_byte_data;
                            if(S_byte_index==31) begin S_byte_index<=0; S_state<=CLASSIFY; end
                            else S_byte_index<=S_byte_index+5'd1;
                        end
                    end
                end
                CLASSIFY: begin
                    if(entry_byte(0)==8'he5) begin S_sequence<=0; S_state<=READ_ENTRY; end
                    else if(entry_byte(11)==8'h0f) begin
                        if(!S_lfn_header_ok) begin S_sequence<=0; O_warning[0]<=1; S_state<=READ_ENTRY; end
                        else if(S_order_byte[6]) begin
                            S_sequence<=1; S_format<=1; S_ascii<=1; S_terminated<=0;
                            S_checksum<=entry_byte(13); S_lfn_length<={4'd0,S_order}*9'd13;
                            S_expected<=S_order-5'd1; S_ordinal<=S_order; S_unit<=0; S_state<=LFN_UNIT;
                        end else if(S_sequence && S_order==S_expected && S_checksum==entry_byte(13)) begin
                            S_expected<=S_order-5'd1; S_ordinal<=S_order; S_unit<=0; S_state<=LFN_UNIT;
                        end else begin S_sequence<=0; O_warning[0]<=1; S_state<=READ_ENTRY; end
                    end else if(S_entry[11*8+3] || entry_byte(0)==8'h2e || S_entry[11*8+6] || S_entry[11*8+7]) begin
                        S_sequence<=0; S_state<=READ_ENTRY;
                    end else S_state<=SHORT_CHECK;
                end
                LFN_UNIT: begin
                    if(S_word==0) begin
                        if(S_terminated) S_format<=0;
                        S_terminated<=1; S_lfn_length<=S_unit_index;
                    end else if(S_word==16'hffff) begin
                        if(!S_terminated || S_unit_index<=S_lfn_length) S_format<=0;
                    end else begin
                        if(S_terminated && S_unit_index>=S_lfn_length) S_format<=0;
                        if(S_word[15:8]!=0 || !legal_lfn(S_word[7:0])) S_ascii<=0;
                        if(S_unit_index<64) S_name[S_unit_index[5:0]]<=S_word[7:0];
                    end
                    if(S_unit==12) S_state<=READ_ENTRY;
                    else S_unit<=S_unit+4'd1;
                end
                SHORT_CHECK: begin
                    S_sequence<=0; S_name_index<=0; O_attr<=entry_byte(11); O_size<=S_entry[28*8+:32];
                    O_first_cluster<={4'd0,S_entry[21*8+:4],entry_byte(20),entry_byte(27),entry_byte(26)};
                    O_alias<=S_entry[87:0]; O_is_lfn<=0;
                    if(S_valid_long && S_lfn_length>64) begin O_warning[1]<=1; S_state<=READ_ENTRY; end
                    else if(S_valid_long && S_name[S_lfn_length-1]!=32 && S_name[S_lfn_length-1]!=8'h2e) begin
                        O_name_length<=S_lfn_length[6:0]; O_is_lfn<=1; S_state<=ENTRY;
                    end else if(S_base_trim==0) begin O_warning[2]<=1; S_state<=READ_ENTRY; end
                    else begin
                        if(S_sequence) O_warning[0]<=1;
                        S_base_length<=S_base_trim;
                        O_name_length<={3'd0,S_base_trim}+(S_ext_trim!=0 ? 7'd1+{3'd0,S_ext_trim} : 7'd0);
                        S_state<=BUILD_SHORT;
                    end
                end
                BUILD_SHORT: begin
                    if(S_name_index!=S_base_length && !legal_short(S_short_byte)) begin
                        O_warning[2]<=1; S_state<=READ_ENTRY;
                    end else begin
                        S_name[S_name_index[5:0]]<=S_short_byte;
                        if(S_name_index+7'd1==O_name_length) S_state<=ENTRY;
                        else S_name_index<=S_name_index+7'd1;
                    end
                end
                ENTRY: if(I_entry_ready) begin S_name_index<=0; S_state<=NAME; end
                NAME: if(I_name_ready) begin
                    if(O_name_last) S_state<=READ_ENTRY;
                    else S_name_index<=S_name_index+7'd1;
                end
                RESULT: if(I_done_ready) S_state<=IDLE;
                default:finish(8'd3);
            endcase
            if(I_cancel && S_state!=IDLE && S_state!=RESULT) finish(8'd8);
        end
    end
endmodule
