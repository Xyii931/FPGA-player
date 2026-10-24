// Sequential RIFF/WAVE PCM16 stereo parser. No seek, CDC or playback buffering.
module wav_parser (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [7:0] I_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last, I_abort, I_stream_error,
    output wire O_busy,
    output reg O_done, O_err,
    output reg [3:0] O_error_code,
    output reg [7:0] O_tag,
    output wire O_header_valid,
    input wire I_header_ready,
    output reg [31:0] O_data_offset, O_data_bytes, O_total_frames,
    output reg O_sample_valid,
    input wire I_sample_ready,
    output reg [23:0] O_left, O_right,
    output reg [31:0] O_sample_index,
    output reg O_sample_last
);
    localparam [3:0] IDLE=0, RIFF=1, RIFF_CHECK=2, BOUNDARY=3, CHUNK=4,
        CHUNK_CHECK=5, FMT=6, FMT_CHECK=7, META=8, DATA=9,
        SKIP=10, NEXT=11, PAD=12, TAIL=13, DRAIN=14, FINISH=15;
    reg [3:0] S_state;
    reg [7:0] S_riff [0:11];
    reg [7:0] S_chunk [0:7];
    reg [7:0] S_fmt [0:15];
    reg [3:0] S_header_index;
    reg [31:0] S_pos, S_size, S_riff_end, S_left, S_payload_index, S_frame;
    reg S_fmt_seen, S_data_seen, S_odd;
    reg [1:0] S_component;
    reg [7:0] S_l_lo, S_l_hi, S_r_lo;
    wire [31:0] S_chunk_size = {S_chunk[7],S_chunk[6],S_chunk[5],S_chunk[4]};
    wire [31:0] S_chunk_id = {S_chunk[0],S_chunk[1],S_chunk[2],S_chunk[3]};
    wire [63:0] S_riff_limit = {32'd0,S_riff[7],S_riff[6],S_riff[5],S_riff[4]} + 64'd8;
    wire [63:0] S_chunk_limit = {32'd0,S_pos} + {32'd0,S_chunk_size} + {63'd0,S_chunk_size[0]};
    assign O_start_ready = S_state == IDLE;
    assign O_busy = S_state != IDLE;
    assign O_header_valid = S_state == META && !I_abort && !I_stream_error;
    assign O_byte_ready = !I_abort && !I_stream_error && !O_sample_valid &&
        (S_state == RIFF || S_state == CHUNK || S_state == FMT || S_state == DATA ||
         S_state == SKIP || S_state == PAD || S_state == TAIL);
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=IDLE; S_header_index<=0; S_pos<=0; S_size<=0; S_riff_end<=0;
            S_left<=0; S_payload_index<=0; S_frame<=0; S_fmt_seen<=0; S_data_seen<=0;
            S_odd<=0; S_component<=0; S_l_lo<=0; S_l_hi<=0; S_r_lo<=0;
            O_done<=0; O_err<=0; O_error_code<=0; O_tag<=0;
            O_data_offset<=0; O_data_bytes<=0; O_total_frames<=0;
            O_sample_valid<=0; O_left<=0; O_right<=0; O_sample_index<=0; O_sample_last<=0;
        end else begin
            O_done<=0; O_err<=0;
            if (O_sample_valid && I_sample_ready) O_sample_valid<=0;
            if (O_busy && S_state != FINISH && (I_abort || I_stream_error)) begin
                O_error_code<=I_abort ? 4'd6 : 4'd5;
                O_sample_valid<=0; S_state<=FINISH;
            end else begin
                case (S_state)
                    IDLE: if (I_start_valid) begin
                        S_size<=I_file_size; O_tag<=I_tag; S_pos<=0; S_header_index<=0;
                        S_fmt_seen<=0; S_data_seen<=0; S_frame<=0; S_component<=0;
                        O_sample_valid<=0; O_sample_last<=0;
                        O_data_offset<=0; O_data_bytes<=0; O_total_frames<=0;
                        O_error_code<=I_file_size<12 ? 4'd3 : 4'd0;
                        S_state<=I_file_size<12 ? FINISH : RIFF;
                    end
                    RIFF_CHECK: begin
                        if ({S_riff[0],S_riff[1],S_riff[2],S_riff[3]} != 32'h52494646 ||
                            {S_riff[8],S_riff[9],S_riff[10],S_riff[11]} != 32'h57415645) begin
                            O_error_code<=1; S_state<=FINISH;
                        end else if (S_riff_limit<12 || S_riff_limit>{32'd0,S_size}) begin
                            O_error_code<=3; S_state<=FINISH;
                        end else begin S_riff_end<=S_riff_limit[31:0]; S_state<=BOUNDARY; end
                    end
                    BOUNDARY: begin
                        S_header_index<=0;
                        if (S_pos==S_riff_end) begin
                            if (!S_fmt_seen || !S_data_seen) begin O_error_code<=4; S_state<=FINISH; end
                            else S_state<=S_pos==S_size ? DRAIN : TAIL;
                        end else if (S_pos>S_riff_end || S_riff_end-S_pos<8) begin
                            O_error_code<=3; S_state<=FINISH;
                        end else S_state<=CHUNK;
                    end
                    CHUNK_CHECK: begin
                        S_left<=S_chunk_size; S_payload_index<=0; S_odd<=S_chunk_size[0];
                        if (S_chunk_limit>{32'd0,S_riff_end}) begin O_error_code<=3; S_state<=FINISH; end
                        else if (S_chunk_id==32'h666d7420) begin
                            if (S_fmt_seen || S_data_seen) begin O_error_code<=4; S_state<=FINISH; end
                            else if (S_chunk_size<16) begin O_error_code<=2; S_state<=FINISH; end
                            else S_state<=FMT;
                        end else if (S_chunk_id==32'h64617461) begin
                            if (!S_fmt_seen || S_data_seen) begin O_error_code<=4; S_state<=FINISH; end
                            else if (S_chunk_size[1:0]!=0) begin O_error_code<=3; S_state<=FINISH; end
                            else begin
                                S_data_seen<=1; O_data_offset<=S_pos;
                                O_data_bytes<=S_chunk_size; O_total_frames<=S_chunk_size>>2;
                                S_frame<=0; S_component<=0; S_state<=META;
                            end
                        end else S_state<=S_chunk_size==0 ? NEXT : SKIP;
                    end
                    FMT_CHECK: begin
                        if ({S_fmt[1],S_fmt[0]}!=1 || {S_fmt[3],S_fmt[2]}!=2 ||
                            {S_fmt[7],S_fmt[6],S_fmt[5],S_fmt[4]}!=48000 ||
                            {S_fmt[11],S_fmt[10],S_fmt[9],S_fmt[8]}!=192000 ||
                            {S_fmt[13],S_fmt[12]}!=4 || {S_fmt[15],S_fmt[14]}!=16) begin
                            O_error_code<=2; S_state<=FINISH;
                        end else begin S_fmt_seen<=1; S_state<=NEXT; end
                    end
                    META: if (I_header_ready) S_state<=S_left==0 ? NEXT : DATA;
                    NEXT: S_state<=S_odd ? PAD : BOUNDARY;
                    DRAIN: if (!O_sample_valid || I_sample_ready) S_state<=FINISH;
                    FINISH: begin O_done<=1; O_err<=O_error_code!=0; S_state<=IDLE; end
                    default: begin end
                endcase
                if (I_byte_valid && O_byte_ready) begin
                    if (I_byte_last != (S_pos==S_size-1)) begin
                        O_error_code<=5; O_sample_valid<=0; S_state<=FINISH;
                    end else begin
                        S_pos<=S_pos+1'b1;
                        case (S_state)
                            RIFF: begin
                                S_riff[S_header_index]<=I_byte_data;
                                S_header_index<=S_header_index+1'b1;
                                if (S_header_index==11) S_state<=RIFF_CHECK;
                            end
                            CHUNK: begin
                                S_chunk[S_header_index]<=I_byte_data;
                                S_header_index<=S_header_index+1'b1;
                                if (S_header_index==7) S_state<=CHUNK_CHECK;
                            end
                            FMT: begin
                                if (S_payload_index<16) S_fmt[S_payload_index[3:0]]<=I_byte_data;
                                S_payload_index<=S_payload_index+1'b1; S_left<=S_left-1'b1;
                                if (S_left==1) S_state<=FMT_CHECK;
                            end
                            DATA: begin
                                S_left<=S_left-1'b1;
                                S_component<=S_component+1'b1;
                                case (S_component)
                                    0: S_l_lo<=I_byte_data;
                                    1: S_l_hi<=I_byte_data;
                                    2: S_r_lo<=I_byte_data;
                                    3: begin
                                        O_left<={S_l_hi,S_l_lo,8'd0};
                                        O_right<={I_byte_data,S_r_lo,8'd0};
                                        O_sample_index<=S_frame; S_frame<=S_frame+1'b1;
                                        O_sample_last<=S_left==1; O_sample_valid<=1;
                                    end
                                endcase
                                if (S_left==1) S_state<=NEXT;
                            end
                            SKIP: begin
                                S_left<=S_left-1'b1;
                                if (S_left==1) S_state<=NEXT;
                            end
                            PAD: S_state<=BOUNDARY;
                            TAIL: if (S_pos==S_size-1) S_state<=DRAIN;
                            default: begin end
                        endcase
                    end
                end
            end
        end
    end
endmodule
