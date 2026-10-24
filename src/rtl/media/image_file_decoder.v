// Four signature bytes are captured and replayed once to the actual BMP/RLE1 parser.
module image_file_decoder (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [7:0] I_tag,
    output wire O_busy,
    output reg O_done, O_err,
    output reg [3:0] O_error_code,
    output reg [7:0] O_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,
    input wire I_stream_error, I_abort,
    output wire O_header_valid,
    input wire I_header_ready,
    output wire [15:0] O_width, O_height,
    output wire O_bottom_up,
    output wire [5:0] O_bpp,
    output wire [31:0] O_pixel_offset, O_row_bytes,
    output wire O_pixel_valid,
    input wire I_pixel_ready,
    output wire [31:0] O_rgba,
    output wire [15:0] O_x, O_y,
    output wire O_pixel_last
);
    wire [1:0] S_start_ready;
    wire [1:0] S_byte_ready;
    wire [1:0] S_done;
    wire [1:0] S_err;
    wire [1:0] S_header_valid;
    wire [1:0] S_pixel_valid;
    wire [1:0] S_pixel_last;
    wire [7:0] S_error_code;
    wire [15:0] S_tag;
    wire [31:0] S_width;
    wire [31:0] S_height;
    wire [1:0] S_bottom_up;
    wire [11:0] S_bpp;
    wire [63:0] S_pixel_offset;
    wire [63:0] S_row_bytes;
    wire [63:0] S_rgba;
    wire [31:0] S_x;
    wire [31:0] S_y;
    wire [1:0] S_busy;
    localparam [2:0] IDLE=0,SNIFF=1,SELECT=2,START=3,REPLAY=4,RUN=5,FINISH=6;
    reg [2:0] S_state;
    reg [7:0] S_prefix[0:3];
    reg [1:0] S_prefix_index;
    reg [31:0] S_size;
    reg S_rle;
    wire S_child_active=S_state==REPLAY || S_state==RUN;
    wire S_child_byte_valid=(S_state==REPLAY || (S_state==RUN && I_byte_valid)) && !I_reset;
    wire [7:0] S_child_byte=S_state==REPLAY ? S_prefix[S_prefix_index] : I_byte_data;
    wire S_child_last=S_state==REPLAY ? (S_size==4 && S_prefix_index==3) : I_byte_last;
    wire S_child_start=S_state==START && !I_abort && !I_stream_error && !I_reset;
    assign O_start_ready=S_state==IDLE && !I_reset;
    assign O_busy=S_state!=IDLE;
    assign O_byte_ready=!I_reset && !I_abort && !I_stream_error &&
        (S_state==SNIFF || (S_state==RUN && S_byte_ready[S_rle]));
    assign O_header_valid=S_state==RUN && S_header_valid[S_rle];
    assign O_pixel_valid=S_state==RUN && S_pixel_valid[S_rle];
    assign O_pixel_last=S_pixel_last[S_rle];
    assign O_width=S_width[S_rle*16+:16];
    assign O_height=S_height[S_rle*16+:16];
    assign O_bottom_up=S_bottom_up[S_rle];
    assign O_bpp=S_bpp[S_rle*6+:6];
    assign O_pixel_offset=S_pixel_offset[S_rle*32+:32];
    assign O_row_bytes=S_row_bytes[S_rle*32+:32];
    assign O_rgba=S_rgba[S_rle*32+:32];
    assign O_x=S_x[S_rle*16+:16];
    assign O_y=S_y[S_rle*16+:16];
    bmp_parser u_bmp (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_start_valid(S_child_start && !S_rle),
        .I_file_size(S_size),
        .I_tag(O_tag),
        .I_byte_valid(S_child_byte_valid && !S_rle),
        .I_byte_data(S_child_byte),
        .I_byte_last(S_child_last),
        .I_stream_error(I_stream_error && S_child_active && !S_rle),
        .I_abort(I_abort && S_child_active && !S_rle),
        .I_header_ready(I_header_ready && S_state==RUN && !S_rle),
        .I_pixel_ready(I_pixel_ready && S_state==RUN && !S_rle),
        .O_start_ready(S_start_ready[0]),
        .O_byte_ready(S_byte_ready[0]),
        .O_done(S_done[0]),
        .O_err(S_err[0]),
        .O_header_valid(S_header_valid[0]),
        .O_pixel_valid(S_pixel_valid[0]),
        .O_pixel_last(S_pixel_last[0]),
        .O_error_code(S_error_code[0+:4]),
        .O_tag(S_tag[0+:8]),
        .O_width(S_width[0+:16]),
        .O_height(S_height[0+:16]),
        .O_bottom_up(S_bottom_up[0]),
        .O_bpp(S_bpp[0+:6]),
        .O_pixel_offset(S_pixel_offset[0+:32]),
        .O_row_bytes(S_row_bytes[0+:32]),
        .O_rgba(S_rgba[0+:32]),
        .O_x(S_x[0+:16]),
        .O_y(S_y[0+:16]),
        .O_busy(S_busy[0])
    );
    rle_parser u_rle (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_start_valid(S_child_start && S_rle),
        .I_file_size(S_size),
        .I_tag(O_tag),
        .I_byte_valid(S_child_byte_valid && S_rle),
        .I_byte_data(S_child_byte),
        .I_byte_last(S_child_last),
        .I_stream_error(I_stream_error && S_child_active && S_rle),
        .I_abort(I_abort && S_child_active && S_rle),
        .I_header_ready(I_header_ready && S_state==RUN && S_rle),
        .I_pixel_ready(I_pixel_ready && S_state==RUN && S_rle),
        .O_start_ready(S_start_ready[1]),
        .O_byte_ready(S_byte_ready[1]),
        .O_done(S_done[1]),
        .O_err(S_err[1]),
        .O_header_valid(S_header_valid[1]),
        .O_pixel_valid(S_pixel_valid[1]),
        .O_pixel_last(S_pixel_last[1]),
        .O_error_code(S_error_code[4+:4]),
        .O_tag(S_tag[8+:8]),
        .O_width(S_width[16+:16]),
        .O_height(S_height[16+:16]),
        .O_bottom_up(S_bottom_up[1]),
        .O_bpp(S_bpp[6+:6]),
        .O_pixel_offset(S_pixel_offset[32+:32]),
        .O_row_bytes(S_row_bytes[32+:32]),
        .O_rgba(S_rgba[32+:32]),
        .O_x(S_x[16+:16]),
        .O_y(S_y[16+:16]),
        .O_busy(S_busy[1])
    );
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_size<=0; S_prefix_index<=0; S_rle<=0;
            O_done<=0; O_err<=0; O_error_code<=0; O_tag<=0;
        end else begin
            O_done<=0; O_err<=0;
            if((S_state==SNIFF || S_state==SELECT || S_state==START) && (I_abort || I_stream_error)) begin
                O_error_code<=I_abort ? 4'd6 : 4'd5; S_state<=FINISH;
            end else case(S_state)
                IDLE:if(I_start_valid) begin
                    S_size<=I_file_size; O_tag<=I_tag; S_prefix_index<=0;
                    O_error_code<=I_file_size<22 ? 4'd4 : 4'd0;
                    S_state<=I_file_size<22 ? FINISH : SNIFF;
                end
                SNIFF:if(I_byte_valid && O_byte_ready) begin
                    if(I_byte_last!=(S_size==4 && S_prefix_index==3)) begin O_error_code<=5; S_state<=FINISH; end
                    else begin
                        S_prefix[S_prefix_index]<=I_byte_data; S_prefix_index<=S_prefix_index+1'b1;
                        if(S_prefix_index==3) S_state<=SELECT;
                    end
                end
                SELECT:begin
                    if({S_prefix[0],S_prefix[1]}==16'h424d) begin S_rle<=0; S_state<=START; end
                    else if({S_prefix[0],S_prefix[1],S_prefix[2],S_prefix[3]}==32'h524c4531) begin S_rle<=1; S_state<=START; end
                    else begin O_error_code<=1; S_state<=FINISH; end
                end
                START:if(S_start_ready[S_rle]) begin S_prefix_index<=0; S_state<=REPLAY; end
                REPLAY:if(S_done[S_rle]) begin O_error_code<=S_error_code[S_rle*4+:4]; S_state<=FINISH; end
                    else if(S_child_byte_valid && S_byte_ready[S_rle]) begin
                        S_prefix_index<=S_prefix_index+1'b1;
                        if(S_prefix_index==3) S_state<=RUN;
                    end
                RUN:if(S_done[S_rle]) begin O_error_code<=S_error_code[S_rle*4+:4]; S_state<=FINISH; end
                FINISH:begin O_done<=1; O_err<=O_error_code!=0; S_state<=IDLE; end
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
