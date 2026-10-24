// RLE1 stream -> uncommitted RGBA candidates. Same public contract as bmp_parser.
// Numeric RGBA is 0xRRGGBBAA; the u32 in each six-byte record is little-endian.
module rle_parser (
    input wire I_clk,I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,
    input wire [7:0] I_tag,
    output wire O_busy,
    output reg O_done,O_err,
    output reg [3:0] O_error_code,
    output reg [7:0] O_tag,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,I_stream_error,I_abort,
    output wire O_header_valid,
    input wire I_header_ready,
    output reg [15:0] O_width,O_height,
    output wire O_bottom_up,
    output wire [5:0] O_bpp,
    output wire [31:0] O_pixel_offset,O_row_bytes,
    output wire O_pixel_valid,
    input wire I_pixel_ready,
    output reg [31:0] O_rgba,
    output reg [15:0] O_x,O_y,
    output wire O_pixel_last
);
    localparam [2:0] IDLE=0,HEADER=1,CHECK=2,META=3,RECORD=4,PIXELS=5,FINISH=6;
    reg [2:0] S_state,S_component;
    reg [127:0] S_header;
    reg [47:0] S_record;
    reg [31:0] S_size,S_position,S_crc,S_emitted,S_total;
    reg [15:0] S_remaining;
    reg S_final_run;
    wire [15:0] S_width=S_header[47:32],S_height=S_header[63:48];
    wire [31:0] S_payload=S_header[95:64],S_expected_crc=S_header[127:96];
    wire [32:0] S_run_end={1'b0,S_emitted}+{17'd0,S_record[15:0]};
    wire [31:0] S_next_crc;
    function [31:0] crc_byte;
        input [31:0] crc;
        input [7:0] value;
        integer i;
        reg [31:0] next_crc;
        begin
            next_crc=crc^{24'd0,value};
            for(i=0;i<8;i=i+1)
                next_crc=next_crc[0] ? (next_crc>>1)^32'hedb88320 : next_crc>>1;
            crc_byte=next_crc;
        end
    endfunction
    assign S_next_crc=crc_byte(S_crc,I_byte_data);
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_busy=S_state!=IDLE;
    assign O_byte_ready=!I_reset && !I_abort && !I_stream_error && (S_state==HEADER || S_state==RECORD);
    assign O_header_valid=!I_reset && !I_abort && !I_stream_error && S_state==META;
    assign O_bottom_up=1'b0;
    assign O_bpp=6'd32;
    assign O_pixel_offset=32'd16;
    assign O_row_bytes={16'd0,O_width}<<2;
    assign O_pixel_valid=!I_reset && !I_abort && !I_stream_error && S_state==PIXELS;
    assign O_pixel_last=S_emitted+32'd1==S_total;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_component<=0; S_header<=0; S_record<=0;
            S_size<=0; S_position<=0; S_crc<=32'hffffffff; S_emitted<=0; S_total<=0;
            S_remaining<=0; S_final_run<=0;
            O_done<=0; O_err<=0; O_error_code<=0; O_tag<=0;
            O_width<=0; O_height<=0; O_rgba<=0; O_x<=0; O_y<=0;
        end else begin
            O_done<=0; O_err<=0;
            if(S_state!=IDLE && S_state!=FINISH && (I_abort || I_stream_error)) begin
                O_error_code<=I_abort ? 4'd6 : 4'd5; S_state<=FINISH;
            end else case(S_state)
                IDLE:if(I_start_valid) begin
                    S_size<=I_file_size; S_position<=0; S_header<=0; S_component<=0;
                    S_crc<=32'hffffffff; S_emitted<=0; S_total<=0; S_remaining<=0; S_final_run<=0;
                    O_tag<=I_tag; O_width<=0; O_height<=0; O_x<=0; O_y<=0;
                    O_error_code<=I_file_size<22 ? 4'd4 : 4'd0;
                    S_state<=I_file_size<22 ? FINISH : HEADER;
                end
                HEADER,RECORD:if(I_byte_valid && O_byte_ready) begin
                    if(I_byte_last!=(S_position+32'd1==S_size)) begin
                        O_error_code<=5; S_state<=FINISH;
                    end else begin
                        S_position<=S_position+1'b1;
                        if(S_state==HEADER) begin
                            S_header[S_position[3:0]*8+:8]<=I_byte_data;
                            if(S_position==15) S_state<=CHECK;
                        end else begin
                            S_record[S_component*8+:8]<=I_byte_data; S_crc<=S_next_crc;
                            if(S_component==5) begin
                                S_component<=0;
                                if(S_record[15:0]==0 || S_run_end>{1'b0,S_total} ||
                                    (I_byte_last && (S_run_end!={1'b0,S_total} ||
                                     (S_next_crc^32'hffffffff)!=S_expected_crc)) ||
                                    (!I_byte_last && S_run_end>={1'b0,S_total})) begin
                                    O_error_code<=4; S_state<=FINISH;
                                end else begin
                                    S_remaining<=S_record[15:0]; S_final_run<=I_byte_last;
                                    O_rgba<={I_byte_data,S_record[39:16]}; S_state<=PIXELS;
                                end
                            end else S_component<=S_component+1'b1;
                        end
                    end
                end
                CHECK:begin
                    if(S_header[31:0]!=32'h31454c52) begin O_error_code<=1; S_state<=FINISH; end
                    else if(S_width==0 || S_width>1920 || S_height==0 || S_height>1080) begin
                        O_error_code<=3; S_state<=FINISH;
                    end else if({1'b0,S_payload}+33'd16!={1'b0,S_size} || S_payload==0 || S_payload%32'd6!=0) begin
                        O_error_code<=4; S_state<=FINISH;
                    end else begin
                        O_width<=S_width; O_height<=S_height;
                        S_total<={16'd0,S_width}*{16'd0,S_height}; S_state<=META;
                    end
                end
                META:if(I_header_ready) S_state<=RECORD;
                PIXELS:if(I_pixel_ready) begin
                    S_emitted<=S_emitted+1'b1; S_remaining<=S_remaining-1'b1;
                    if(O_x+16'd1==O_width) begin O_x<=0; O_y<=O_y+1'b1; end
                    else O_x<=O_x+1'b1;
                    if(S_remaining==1) S_state<=S_final_run ? FINISH : RECORD;
                end
                FINISH:begin O_done<=1; O_err<=O_error_code!=0; S_state<=IDLE; end
                default:begin O_error_code<=4; S_state<=FINISH; end
            endcase
        end
    end
endmodule
