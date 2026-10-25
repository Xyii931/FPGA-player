// One WAV decoder, bounded 2048-byte refills and one stereo FIFO. No APT/mixer.
// Configuration inputs belong to the VIDEO domain, not the host domain.
module lean_audio (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_catalog_ready,I_audio_found,
    output wire O_command_valid,
    input wire I_command_ready,
    output reg [31:0] O_offset,
    output wire [31:0] O_length,
    input wire I_begin_valid,
    output wire O_begin_ready,
    input wire [31:0] I_file_size,
    input wire [7:0] I_begin_error,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire [31:0] I_byte_offset,
    input wire I_file_done,
    input wire [7:0] I_file_error,
    input wire [31:0] I_file_bytes,
    input wire I_file_eof,
    output wire O_cancel,
    output reg [3:0] O_error,
    input wire I_mute,
    input wire [2:0] I_volume,
    output reg O_sample_valid,
    output reg [23:0] O_left,O_right,
    output wire O_acr_valid,
    output wire [19:0] O_acr_n,O_acr_cts,
    output reg [31:0] O_underflows
);
    localparam [2:0] IDLE=0,REQUEST=1,BEGIN=2,STREAM=3,FILL_WAIT=4,END_WAIT=5,HALT=6;
    reg [2:0] S_state;
    wire S_hrst,S_vrst;
    reset_sync u_hrst(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_hrst));
    reset_sync u_vrst(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_vrst));
    reg S_started,S_parser_seen,S_decode_failed,S_play;
    reg [31:0] S_size;
    wire S_parser_ready,S_parser_done,S_parser_error,S_parser_byte_ready;
    wire S_sample,S_sample_ready;
    wire [23:0] S_left,S_right;
    wire [11:0] S_write_level,S_read_level;
    wire S_fifo_valid,S_fifo_ready;
    wire [23:0] S_fifo_left,S_fifo_right;
    wire S_tick;
    (* ASYNC_REG="TRUE" *) reg S_play_meta,S_play_sync;
    wire S_begin=I_begin_valid && O_begin_ready;
    wire S_abort=O_error!=0 || !I_catalog_ready || (I_file_done && I_file_error!=0);
    assign O_length=32'd2048;
    assign O_command_valid=!S_hrst && S_state==REQUEST && I_catalog_ready;
    assign O_begin_ready=!S_hrst && S_state==BEGIN && (S_started || S_parser_ready);
    assign O_byte_ready=!S_hrst && (S_decode_failed || O_error!=0 || !I_catalog_ready ? 1'b1 : S_parser_byte_ready);
    assign O_cancel=S_state==STREAM && (S_decode_failed || S_abort);
    wav_parser u_parser (
        .I_clk(I_host_clk),.I_reset(S_hrst),
        .I_start_valid(S_begin && !S_started && I_begin_error==0),.O_start_ready(S_parser_ready),
        .I_file_size(I_file_size),.I_tag(8'd0),
        .I_byte_valid(I_byte_valid && S_state==STREAM && !S_decode_failed),.O_byte_ready(S_parser_byte_ready),
        .I_byte_data(I_byte_data),.I_byte_last(I_byte_offset==S_size-32'd1),
        .I_abort(S_abort),.I_stream_error(I_file_done && I_file_error!=0),
        .O_done(S_parser_done),.O_err(S_parser_error),.I_header_ready(1'b1),
        .O_sample_valid(S_sample),.I_sample_ready(S_sample_ready),.O_left(S_left),.O_right(S_right),
        .O_busy(), .O_error_code(), .O_tag(), .O_header_valid(), .O_data_offset(), .O_data_bytes(), .O_total_frames(), .O_sample_index(), .O_sample_last()
    );
    audio_frame_fifo u_fifo (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_flush(I_async_reset),
        .I_valid(S_sample),.O_ready(S_sample_ready),.I_left(S_left),.I_right(S_right),
        .O_valid(S_fifo_valid),.I_ready(S_fifo_ready),.O_left(S_fifo_left),.O_right(S_fifo_right),
        .O_write_level(S_write_level),.O_read_level(S_read_level),
        .O_prefilled(), .O_need_fill()
    );
    samp_tick u_tick(.I_clk(I_video_clk),.I_reset(S_vrst),.O_sample_tick(S_tick));
    acr_gen u_acr(.I_clk(I_video_clk),.I_reset(S_vrst),.I_sample_tick(S_tick),
        .O_acr_valid(O_acr_valid),.O_acr_n(O_acr_n),.O_acr_cts(O_acr_cts),
        .O_measure_overflow()
    );
    assign S_fifo_ready=S_tick && S_play_sync;
    function [23:0] volume;
        input [23:0] sample;
        input [2:0] level;
        reg signed [23:0] signed_sample;
        begin
            signed_sample=sample;
            case(level)
                1:volume=signed_sample>>>3;
                2:volume=signed_sample>>>2;
                3:volume=signed_sample>>>1;
                4:volume=sample;
                default:volume=0;
            endcase
        end
    endfunction
    always @(posedge I_video_clk or posedge S_vrst) begin
        if(S_vrst) begin
            S_play_meta<=0; S_play_sync<=0; O_sample_valid<=0; O_left<=0; O_right<=0; O_underflows<=0;
        end else begin
            S_play_meta<=S_play; S_play_sync<=S_play_meta;
            O_sample_valid<=S_tick;
            if(S_tick) begin
                O_left<=S_play_sync && S_fifo_valid && !I_mute ? volume(S_fifo_left,I_volume) : 24'd0;
                O_right<=S_play_sync && S_fifo_valid && !I_mute ? volume(S_fifo_right,I_volume) : 24'd0;
                if(S_play_sync && !S_fifo_valid) O_underflows<=O_underflows+1'b1;
            end
        end
    end
    always @(posedge I_host_clk or posedge S_hrst) begin
        if(S_hrst) begin
            S_state<=IDLE; O_offset<=0; S_started<=0; S_parser_seen<=0;
            S_decode_failed<=0; O_error<=0; S_size<=0; S_play<=0;
        end else begin
            if(S_write_level>=512) S_play<=1;
            if(S_parser_done) begin
                S_parser_seen<=1;
                if(S_parser_error) begin S_decode_failed<=1; O_error<=4'd2; end
            end
            case(S_state)
                IDLE:if(I_catalog_ready && I_audio_found && S_parser_ready && S_write_level<512) begin
                    O_offset<=0; S_started<=0; S_parser_seen<=0; S_decode_failed<=0; O_error<=0;
                    S_state<=REQUEST;
                end
                REQUEST:if(!I_catalog_ready) S_state<=HALT;
                    else if(I_command_ready) S_state<=BEGIN;
                BEGIN:if(S_begin) begin
                    if(I_begin_error!=0) begin O_error<=1; S_state<=HALT; end
                    else begin S_started<=1; S_size<=I_file_size; S_state<=STREAM; end
                end
                STREAM:if(I_file_done) begin
                    if(I_file_error!=0 || S_decode_failed || O_error!=0 || !I_catalog_ready) begin
                        if(I_file_error!=0) O_error<=3;
                        S_state<=HALT;
                    end else if(I_file_eof) begin S_play<=1; S_state<=END_WAIT; end
                    else begin O_offset<=O_offset+I_file_bytes; S_state<=FILL_WAIT; end
                end
                FILL_WAIT:if(!I_catalog_ready || S_decode_failed) S_state<=HALT;
                    else if(S_write_level<512) S_state<=REQUEST;
                END_WAIT:if(!I_catalog_ready || S_decode_failed) S_state<=HALT;
                    else if(S_parser_seen && S_parser_ready && S_write_level<512) begin
                        O_offset<=0; S_started<=0; S_parser_seen<=0; S_state<=REQUEST;
                    end
                HALT:if(!I_catalog_ready && S_parser_ready) begin
                    S_started<=0; S_parser_seen<=0; S_decode_failed<=0; O_error<=0; S_state<=IDLE;
                end
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
