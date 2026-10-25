// APT0 stereo IMA decoder. One 1024-byte compressed block, no decoded block RAM.
// Format is project design 02 section 4.5; it is not Microsoft IMA WAV layout.
module apt_parser (
    input wire I_clk,I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [7:0] I_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,I_abort,I_stream_error,
    output wire O_busy,
    output reg O_done,O_err,
    output reg [3:0] O_error_code,
    output reg [7:0] O_tag,
    output wire O_header_valid,
    input wire I_header_ready,
    output reg [31:0] O_data_offset,O_data_bytes,O_total_frames,
    output reg O_sample_valid,
    input wire I_sample_ready,
    output reg [23:0] O_left,O_right,
    output reg [31:0] O_sample_index,
    output reg O_sample_last
);
    localparam [4:0] IDLE=0,HEADER=1,CHECK=2,META=3,FILL=4,BLOCK_CHECK=5,
        LEFT_READ=6,LEFT_DECODE=7,RIGHT_READ=8,RIGHT_DECODE=9,OUTPUT=10,DRAIN=11,FINISH=12,
        DIFF_PAIR=13,DIFF_SUM=14,ACCUMULATE=15,CLIP=16,DECODE_COMMIT=17,
        CAPACITY=18,CAPACITY_SUM=19;
    reg [4:0] S_state;
    reg [7:0] S_header[0:23];
    reg [4:0] S_header_pos;
    reg [31:0] S_size,S_pos,S_frame;
    reg [9:0] S_block_pos,S_block_frame;
    reg [15:0] S_l_predictor,S_r_predictor;
    reg [7:0] S_l_header_index,S_r_header_index,S_l_reserved,S_r_reserved;
    reg [6:0] S_l_index,S_r_index;
    reg [7:0] S_block[0:1023];
    reg [7:0] S_read_byte;
    wire [31:0] S_declared_frames={S_header[19],S_header[18],S_header[17],S_header[16]};
    wire [31:0] S_payload_bytes=S_size-32'd24;
    wire [21:0] S_blocks=S_payload_bytes[31:10];
    reg [31:0] S_capacity_base,S_capacity;
    reg S_decode_right;
    reg [15:0] S_decode_predictor,S_step,S_clipped;
    reg [6:0] S_decode_index,S_clipped_index;
    reg [3:0] S_decode_code;
    reg [16:0] S_pair_a,S_pair_b,S_difference;
    reg signed [18:0] S_accumulated;
    reg signed [8:0] S_next_index;
    wire S_length_ok=S_size>=24 && S_payload_bytes[9:0]==0 &&
        (S_blocks==0 ? S_declared_frames==0 :
        (S_declared_frames>S_capacity-32'd1017 && S_declared_frames<=S_capacity));
    wire [9:0] S_code_index=S_block_frame-10'd1;
    wire [9:0] S_read_address=(S_state==RIGHT_READ ? 10'd516 : 10'd4)+{1'b0,S_code_index[9:1]};
    wire [3:0] S_code=S_code_index[0] ? S_read_byte[7:4] : S_read_byte[3:0];
    assign O_start_ready=S_state==IDLE && !I_reset;
    assign O_busy=S_state!=IDLE;
    assign O_header_valid=S_state==META && !I_abort && !I_stream_error && !I_reset;
    assign O_byte_ready=(S_state==HEADER || S_state==FILL) && !I_abort && !I_stream_error && !I_reset;

    function [15:0] ima_step;
        input [6:0] index;
        begin
            case(index)
                0:ima_step=7; 1:ima_step=8; 2:ima_step=9; 3:ima_step=10;
                4:ima_step=11; 5:ima_step=12; 6:ima_step=13; 7:ima_step=14;
                8:ima_step=16; 9:ima_step=17; 10:ima_step=19; 11:ima_step=21;
                12:ima_step=23; 13:ima_step=25; 14:ima_step=28; 15:ima_step=31;
                16:ima_step=34; 17:ima_step=37; 18:ima_step=41; 19:ima_step=45;
                20:ima_step=50; 21:ima_step=55; 22:ima_step=60; 23:ima_step=66;
                24:ima_step=73; 25:ima_step=80; 26:ima_step=88; 27:ima_step=97;
                28:ima_step=107; 29:ima_step=118; 30:ima_step=130; 31:ima_step=143;
                32:ima_step=157; 33:ima_step=173; 34:ima_step=190; 35:ima_step=209;
                36:ima_step=230; 37:ima_step=253; 38:ima_step=279; 39:ima_step=307;
                40:ima_step=337; 41:ima_step=371; 42:ima_step=408; 43:ima_step=449;
                44:ima_step=494; 45:ima_step=544; 46:ima_step=598; 47:ima_step=658;
                48:ima_step=724; 49:ima_step=796; 50:ima_step=876; 51:ima_step=963;
                52:ima_step=1060; 53:ima_step=1166; 54:ima_step=1282; 55:ima_step=1411;
                56:ima_step=1552; 57:ima_step=1707; 58:ima_step=1878; 59:ima_step=2066;
                60:ima_step=2272; 61:ima_step=2499; 62:ima_step=2749; 63:ima_step=3024;
                64:ima_step=3327; 65:ima_step=3660; 66:ima_step=4026; 67:ima_step=4428;
                68:ima_step=4871; 69:ima_step=5358; 70:ima_step=5894; 71:ima_step=6484;
                72:ima_step=7132; 73:ima_step=7845; 74:ima_step=8630; 75:ima_step=9493;
                76:ima_step=10442; 77:ima_step=11487; 78:ima_step=12635; 79:ima_step=13899;
                80:ima_step=15289; 81:ima_step=16818; 82:ima_step=18500; 83:ima_step=20350;
                84:ima_step=22385; 85:ima_step=24623; 86:ima_step=27086; 87:ima_step=29794;
                88:ima_step=32767;
                default:ima_step=7;
            endcase
        end
    endfunction
    // Decode scratch advances through registered ROM, pair sums, difference,
    // signed accumulation and clipping. No intermediate sample is published.
    // Reset/abort revoke the FSM; every scratch field is overwritten before use.
    always @(posedge I_clk) begin
        case(S_state)
            CAPACITY: S_capacity_base<=({S_blocks,10'd0}-{S_blocks,3'd0});
            CAPACITY_SUM: S_capacity<=S_capacity_base+{10'd0,S_blocks};
            LEFT_DECODE,RIGHT_DECODE: begin
                S_decode_right<=S_state==RIGHT_DECODE;
                S_decode_predictor<=S_state==RIGHT_DECODE ? S_r_predictor : S_l_predictor;
                S_decode_index<=S_state==RIGHT_DECODE ? S_r_index : S_l_index;
                S_step<=ima_step(S_state==RIGHT_DECODE ? S_r_index : S_l_index);
                S_decode_code<=S_code;
            end
            DIFF_PAIR: begin
                S_pair_a<={4'd0,S_step[15:3]}+(S_decode_code[0] ? {3'd0,S_step[15:2]} : 17'd0);
                S_pair_b<=(S_decode_code[1] ? {2'd0,S_step[15:1]} : 17'd0)+
                    (S_decode_code[2] ? {1'b0,S_step} : 17'd0);
                case(S_decode_code[2:0])
                    4:S_next_index<=$signed({2'd0,S_decode_index})+9'sd2;
                    5:S_next_index<=$signed({2'd0,S_decode_index})+9'sd4;
                    6:S_next_index<=$signed({2'd0,S_decode_index})+9'sd6;
                    7:S_next_index<=$signed({2'd0,S_decode_index})+9'sd8;
                    default:S_next_index<=$signed({2'd0,S_decode_index})-9'sd1;
                endcase
            end
            DIFF_SUM: S_difference<=S_pair_a+S_pair_b;
            ACCUMULATE: begin
                if(S_decode_code[3]) S_accumulated<=
                    $signed({{3{S_decode_predictor[15]}},S_decode_predictor})-$signed({2'd0,S_difference});
                else S_accumulated<=
                    $signed({{3{S_decode_predictor[15]}},S_decode_predictor})+$signed({2'd0,S_difference});
            end
            CLIP: begin
                if(S_accumulated>19'sd32767) S_clipped<=16'h7fff;
                else if(S_accumulated< -19'sd32768) S_clipped<=16'h8000;
                else S_clipped<=S_accumulated[15:0];
                if(S_next_index<0) S_clipped_index<=0;
                else if(S_next_index>88) S_clipped_index<=88;
                else S_clipped_index<=S_next_index[6:0];
            end
            default: begin end
        endcase
    end

    // A single synchronous read/write port; RAM contents are excluded until filled.
    always @(posedge I_clk) begin
        if(S_state==FILL && I_byte_valid && O_byte_ready &&
            I_byte_last==(S_pos==S_size-1)) S_block[S_block_pos]<=I_byte_data;
        else if(S_state==LEFT_READ || S_state==RIGHT_READ) S_read_byte<=S_block[S_read_address];
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_header_pos<=0; S_size<=0; S_pos<=0; S_frame<=0;
            S_block_pos<=0; S_block_frame<=0; S_l_predictor<=0; S_r_predictor<=0;
            S_l_header_index<=0; S_r_header_index<=0; S_l_reserved<=0; S_r_reserved<=0;
            S_l_index<=0; S_r_index<=0;
            O_done<=0; O_err<=0; O_error_code<=0; O_tag<=0;
            O_data_offset<=0; O_data_bytes<=0; O_total_frames<=0;
            O_sample_valid<=0; O_left<=0; O_right<=0; O_sample_index<=0; O_sample_last<=0;
        end else begin
            O_done<=0; O_err<=0;
            if(O_sample_valid && I_sample_ready) O_sample_valid<=0;
            if(S_state!=IDLE && S_state!=FINISH && (I_abort || I_stream_error)) begin
                O_error_code<=I_abort ? 4'd6 : 4'd5; O_sample_valid<=0; S_state<=FINISH;
            end else begin
                case(S_state)
                    IDLE:if(I_start_valid) begin
                        S_size<=I_file_size; O_tag<=I_tag; S_pos<=0; S_header_pos<=0; S_frame<=0;
                        S_block_pos<=0; S_block_frame<=0; O_sample_valid<=0; O_sample_last<=0;
                        O_data_offset<=0; O_data_bytes<=0; O_total_frames<=0;
                        O_error_code<=I_file_size<24 ? 4'd3 : 4'd0;
                        S_state<=I_file_size<24 ? FINISH : HEADER;
                    end
                    CHECK:begin
                        if({S_header[0],S_header[1],S_header[2],S_header[3]}!=32'h41505430) begin
                            O_error_code<=1; S_state<=FINISH;
                        end else if({S_header[7],S_header[6],S_header[5],S_header[4]}!=48000 ||
                            {S_header[9],S_header[8]}!=2 || {S_header[11],S_header[10]}!=1 ||
                            {S_header[13],S_header[12]}!=1024 || {S_header[15],S_header[14]}!=24 ||
                            {S_header[23],S_header[22],S_header[21],S_header[20]}!=0) begin
                            O_error_code<=2; S_state<=FINISH;
                        end else if(!S_length_ok) begin O_error_code<=3; S_state<=FINISH; end
                        else begin
                            O_data_offset<=24; O_data_bytes<=S_payload_bytes; O_total_frames<=S_declared_frames;
                            S_state<=META;
                        end
                    end
                    META:if(I_header_ready) S_state<=O_total_frames==0 ? DRAIN : FILL;
                    BLOCK_CHECK:begin
                        if(S_l_header_index>88 || S_r_header_index>88 || S_l_reserved!=0 || S_r_reserved!=0) begin
                            O_error_code<=3; S_state<=FINISH;
                        end else begin
                            S_l_index<=S_l_header_index[6:0]; S_r_index<=S_r_header_index[6:0];
                            S_block_frame<=0; O_left<={S_l_predictor,8'd0}; O_right<={S_r_predictor,8'd0};
                            O_sample_index<=S_frame; O_sample_last<=S_frame+32'd1==O_total_frames;
                            O_sample_valid<=1; S_state<=OUTPUT;
                        end
                    end
                    LEFT_READ:S_state<=LEFT_DECODE;
                    LEFT_DECODE,RIGHT_DECODE:S_state<=DIFF_PAIR;
                    DIFF_PAIR:S_state<=DIFF_SUM;
                    DIFF_SUM:S_state<=ACCUMULATE;
                    ACCUMULATE:S_state<=CLIP;
                    CLIP:S_state<=DECODE_COMMIT;
                    DECODE_COMMIT:begin
                        if(S_decode_right) begin
                            S_r_predictor<=S_clipped; S_r_index<=S_clipped_index;
                            O_left<={S_l_predictor,8'd0}; O_right<={S_clipped,8'd0};
                            O_sample_index<=S_frame; O_sample_last<=S_frame+32'd1==O_total_frames;
                            O_sample_valid<=1; S_state<=OUTPUT;
                        end else begin
                            S_l_predictor<=S_clipped; S_l_index<=S_clipped_index;
                            S_state<=RIGHT_READ;
                        end
                    end
                    RIGHT_READ:S_state<=RIGHT_DECODE;
                    CAPACITY:S_state<=CAPACITY_SUM;
                    CAPACITY_SUM:S_state<=CHECK;
                    OUTPUT:if(O_sample_valid && I_sample_ready) begin
                        S_frame<=S_frame+32'd1;
                        if(O_sample_last) S_state<=DRAIN;
                        else if(S_block_frame==1016) begin S_block_pos<=0; S_state<=FILL; end
                        else begin S_block_frame<=S_block_frame+10'd1; S_state<=LEFT_READ; end
                    end
                    DRAIN:S_state<=FINISH;
                    FINISH:begin O_done<=1; O_err<=O_error_code!=0; S_state<=IDLE; end
                    default:begin end
                endcase
                if(I_byte_valid && O_byte_ready) begin
                    if(I_byte_last!=(S_pos==S_size-1)) begin
                        O_error_code<=5; O_sample_valid<=0; S_state<=FINISH;
                    end else begin
                        S_pos<=S_pos+32'd1;
                        if(S_state==HEADER) begin
                            S_header[S_header_pos]<=I_byte_data; S_header_pos<=S_header_pos+1'b1;
                            if(S_header_pos==23) S_state<=CAPACITY;
                        end else begin
                            S_block_pos<=S_block_pos+1'b1;
                            case(S_block_pos)
                                0:S_l_predictor[7:0]<=I_byte_data;
                                1:S_l_predictor[15:8]<=I_byte_data;
                                2:S_l_header_index<=I_byte_data;
                                3:S_l_reserved<=I_byte_data;
                                512:S_r_predictor[7:0]<=I_byte_data;
                                513:S_r_predictor[15:8]<=I_byte_data;
                                514:S_r_header_index<=I_byte_data;
                                515:S_r_reserved<=I_byte_data;
                                default:begin end
                            endcase
                            if(S_block_pos==1023) S_state<=BLOCK_CHECK;
                        end
                    end
                end
            end
        end
    end
endmodule
