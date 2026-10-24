// Signature-selected WAV/APT0 streaming decoder, instantiated independently per slot.
// Four captured signature bytes are replayed once; external offsets remain unchanged.
module audio_file_decoder (
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
    output wire [31:0] O_data_offset,O_data_bytes,O_total_frames,
    output wire O_sample_valid,
    input wire I_sample_ready,
    output wire [23:0] O_left,O_right,
    output wire [31:0] O_sample_index,
    output wire O_sample_last
);
    localparam [2:0] IDLE=0,SNIFF=1,SELECT=2,START=3,REPLAY=4,RUN=5,FINISH=6;
    reg [2:0] S_state;
    reg [7:0] S_prefix[0:3];
    reg [1:0] S_prefix_index;
    reg [31:0] S_size;
    reg S_apt;
    wire [1:0] S_start_ready,S_byte_ready,S_done,S_err,S_header_valid,S_sample_valid,S_sample_last;
    wire [7:0] S_error;
    wire [15:0] S_tag;
    wire [63:0] S_data_offset,S_data_bytes,S_total_frames,S_sample_index;
    wire [47:0] S_left,S_right;
    wire [1:0] S_busy;
    wire S_child_active=S_state==REPLAY || S_state==RUN;
    wire S_child_byte_valid=(S_state==REPLAY || (S_state==RUN && I_byte_valid)) && !I_reset;
    wire [7:0] S_child_byte=S_state==REPLAY ? S_prefix[S_prefix_index] : I_byte_data;
    wire S_child_last=S_state==REPLAY ? (S_size==4 && S_prefix_index==3) : I_byte_last;
    wire S_child_start=S_state==START && !I_abort && !I_stream_error && !I_reset;
    assign O_start_ready=S_state==IDLE && !I_reset;
    assign O_busy=S_state!=IDLE;
    assign O_byte_ready=!I_reset && !I_abort && !I_stream_error &&
        (S_state==SNIFF || (S_state==RUN && S_byte_ready[S_apt]));
    assign O_header_valid=S_state==RUN && S_header_valid[S_apt];
    assign O_data_offset=S_data_offset[S_apt*32+:32];
    assign O_data_bytes=S_data_bytes[S_apt*32+:32];
    assign O_total_frames=S_total_frames[S_apt*32+:32];
    assign O_sample_valid=S_state==RUN && S_sample_valid[S_apt];
    assign O_left=S_left[S_apt*24+:24];
    assign O_right=S_right[S_apt*24+:24];
    assign O_sample_index=S_sample_index[S_apt*32+:32];
    assign O_sample_last=S_sample_last[S_apt];

    wav_parser u_wav (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_child_start && !S_apt),.O_start_ready(S_start_ready[0]),
        .I_file_size(S_size),.I_tag(O_tag),.I_byte_valid(S_child_byte_valid && !S_apt),.O_byte_ready(S_byte_ready[0]),
        .I_byte_data(S_child_byte),.I_byte_last(S_child_last),
        .I_abort(I_abort && S_child_active && !S_apt),.I_stream_error(I_stream_error && S_child_active && !S_apt),
        .O_busy(S_busy[0]),.O_done(S_done[0]),.O_err(S_err[0]),.O_error_code(S_error[3:0]),.O_tag(S_tag[7:0]),
        .O_header_valid(S_header_valid[0]),.I_header_ready(I_header_ready && S_state==RUN && !S_apt),
        .O_data_offset(S_data_offset[31:0]),.O_data_bytes(S_data_bytes[31:0]),.O_total_frames(S_total_frames[31:0]),
        .O_sample_valid(S_sample_valid[0]),.I_sample_ready(I_sample_ready && S_state==RUN && !S_apt),
        .O_left(S_left[23:0]),.O_right(S_right[23:0]),.O_sample_index(S_sample_index[31:0]),.O_sample_last(S_sample_last[0])
    );
    apt_parser u_apt (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_child_start && S_apt),.O_start_ready(S_start_ready[1]),
        .I_file_size(S_size),.I_tag(O_tag),.I_byte_valid(S_child_byte_valid && S_apt),.O_byte_ready(S_byte_ready[1]),
        .I_byte_data(S_child_byte),.I_byte_last(S_child_last),
        .I_abort(I_abort && S_child_active && S_apt),.I_stream_error(I_stream_error && S_child_active && S_apt),
        .O_busy(S_busy[1]),.O_done(S_done[1]),.O_err(S_err[1]),.O_error_code(S_error[7:4]),.O_tag(S_tag[15:8]),
        .O_header_valid(S_header_valid[1]),.I_header_ready(I_header_ready && S_state==RUN && S_apt),
        .O_data_offset(S_data_offset[63:32]),.O_data_bytes(S_data_bytes[63:32]),.O_total_frames(S_total_frames[63:32]),
        .O_sample_valid(S_sample_valid[1]),.I_sample_ready(I_sample_ready && S_state==RUN && S_apt),
        .O_left(S_left[47:24]),.O_right(S_right[47:24]),.O_sample_index(S_sample_index[63:32]),.O_sample_last(S_sample_last[1])
    );
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_size<=0; S_prefix_index<=0; S_apt<=0;
            O_done<=0; O_err<=0; O_error_code<=0; O_tag<=0;
        end else begin
            O_done<=0; O_err<=0;
            if((S_state==SNIFF || S_state==SELECT || S_state==START) && (I_abort || I_stream_error)) begin
                O_error_code<=I_abort ? 4'd6 : 4'd5; S_state<=FINISH;
            end else case(S_state)
                IDLE:if(I_start_valid) begin
                    S_size<=I_file_size; O_tag<=I_tag; S_prefix_index<=0;
                    O_error_code<=I_file_size<4 ? 4'd3 : 4'd0;
                    S_state<=I_file_size<4 ? FINISH : SNIFF;
                end
                SNIFF:if(I_byte_valid && O_byte_ready) begin
                    if(I_byte_last!=(S_size==4 && S_prefix_index==3)) begin O_error_code<=5; S_state<=FINISH; end
                    else begin
                        S_prefix[S_prefix_index]<=I_byte_data; S_prefix_index<=S_prefix_index+1'b1;
                        if(S_prefix_index==3) S_state<=SELECT;
                    end
                end
                SELECT:begin
                    if({S_prefix[0],S_prefix[1],S_prefix[2],S_prefix[3]}==32'h52494646) begin S_apt<=0; S_state<=START; end
                    else if({S_prefix[0],S_prefix[1],S_prefix[2],S_prefix[3]}==32'h41505430) begin S_apt<=1; S_state<=START; end
                    else begin O_error_code<=1; S_state<=FINISH; end
                end
                START:if(S_start_ready[S_apt]) begin S_prefix_index<=0; S_state<=REPLAY; end
                REPLAY:if(S_done[S_apt]) begin O_error_code<=S_error[S_apt*4+:4]; S_state<=FINISH; end
                    else if(S_child_byte_valid && S_byte_ready[S_apt]) begin
                        S_prefix_index<=S_prefix_index+1'b1;
                        if(S_prefix_index==3) S_state<=RUN;
                    end
                RUN:if(S_done[S_apt]) begin O_error_code<=S_error[S_apt*4+:4]; S_state<=FINISH; end
                FINISH:begin O_done<=1; O_err<=O_error_code!=0; S_state<=IDLE; end
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
