// One PCM WAV or APT0 transaction per shared flush. Instantiate once per audio slot.
// External lifecycle control must retire the reader and cancel/drain old file I/O.
module wav_track_source #(
    parameter integer FIFO_ADDR_BITS=11,
    parameter integer PREFILL_FRAMES=1024,
    parameter integer LOW_FRAMES=512
) (
    input wire I_decode_clk,I_audio_clk,I_async_flush,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,I_start_index,
    input wire [15:0] I_epoch,
    input wire I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,
    input wire [15:0] I_byte_epoch,
    input wire I_abort,I_stream_error_valid,
    input wire [15:0] I_stream_error_epoch,
    output reg O_byte_discarded,O_cancel_valid,
    input wire I_cancel_ready,
    output wire [15:0] O_cancel_epoch,
    output wire O_busy,O_quiescent,
    output reg [31:0] O_written_frames,
    output wire O_valid,
    input wire I_ready,
    output wire [23:0] O_left,O_right,
    output reg [15:0] O_pcm_epoch,
    output wire [FIFO_ADDR_BITS:0] O_write_level,O_read_level,
    output wire O_prefilled,O_need_fill,
    output reg O_header_seen,O_failed,
    output wire O_event_valid,
    input wire I_event_ready,
    output wire O_event_header,
    output wire [15:0] O_event_epoch,
    output wire [31:0] O_event_total_frames,O_event_written_frames,O_event_start_index,
    output wire [3:0] O_event_error
);
    wire S_decode_reset,S_audio_reset;
    reg S_started,S_reported,S_terminal_pending;
    reg [15:0] S_epoch;
    reg [31:0] S_declared_total,S_start_index;
    reg S_seek_error;
    reg [3:0] S_terminal_error;
    wire S_parser_ready,S_parser_busy,S_parser_byte_ready,S_parser_done,S_parser_err;
    wire [3:0] S_parser_error;
    wire [7:0] S_parser_tag;
    wire S_header_valid,S_header_ready,S_sample_valid,S_sample_ready,S_sample_last;
    wire [31:0] S_data_offset,S_data_bytes,S_total_frames,S_sample_index;
    wire [23:0] S_left,S_right;
    wire S_active=S_started && S_parser_busy;
    wire S_matches=I_byte_epoch==S_epoch;
    wire S_abort=I_abort && S_active;
    wire S_read_error=I_stream_error_valid && I_stream_error_epoch==S_epoch && S_active;
    wire S_forward=S_active && S_matches;
    wire S_pcm_write_ready,S_pcm_valid,S_pcm_prefilled,S_pcm_need_fill;
    wire S_skip=S_sample_index<S_start_index;
    wire S_pcm_write_valid=S_sample_valid && !S_skip && !S_abort && !S_read_error;
    wire [116:0] S_event_write_data;
    wire S_event_write_ready,S_event_write_valid;
    wire S_event_full,S_event_empty;
    wire [2:0] S_event_write_level,S_event_read_level;
    wire S_event_fire=O_event_valid && I_event_ready;

    reset_sync u_decode_reset (
        .I_clk(I_decode_clk),.I_async_reset(I_async_flush),.O_reset(S_decode_reset));
    reset_sync u_audio_reset (
        .I_clk(I_audio_clk),.I_async_reset(I_async_flush),.O_reset(S_audio_reset));
    assign O_start_ready=!I_async_flush && !S_decode_reset && !S_started && S_parser_ready;
    assign O_byte_ready=!I_async_flush && !S_decode_reset &&
        (!S_forward || S_parser_byte_ready);
    assign O_cancel_epoch=S_epoch;
    assign O_quiescent=!I_async_flush && !S_decode_reset && !S_parser_busy &&
        !S_terminal_pending && !O_cancel_valid && (!S_started || S_reported);
    assign O_busy=S_started && !O_quiescent;
    assign S_sample_ready=(S_skip || S_pcm_write_ready) && !S_abort && !S_read_error;
    assign S_header_ready=S_event_write_ready && !S_terminal_pending;
    assign S_event_write_valid=S_terminal_pending || S_header_valid;
    assign S_event_write_data=S_terminal_pending ?
        {1'b0,S_epoch,S_declared_total,O_written_frames,S_terminal_error,S_start_index} :
        {1'b1,S_epoch,S_total_frames,32'd0,4'd0,
            S_start_index>S_total_frames ? S_total_frames : S_start_index};

    audio_file_decoder u_parser (
        .I_clk(I_decode_clk),.I_reset(S_decode_reset),
        .I_start_valid(I_start_valid && O_start_ready),.O_start_ready(S_parser_ready),
        .I_file_size(I_file_size),.I_tag(I_epoch[7:0]),
        .I_byte_valid(I_byte_valid && S_forward),.O_byte_ready(S_parser_byte_ready),
        .I_byte_data(I_byte_data),.I_byte_last(I_byte_last),.I_abort(S_abort),.I_stream_error(S_read_error),
        .O_busy(S_parser_busy),.O_done(S_parser_done),.O_err(S_parser_err),
        .O_error_code(S_parser_error),.O_tag(S_parser_tag),
        .O_header_valid(S_header_valid),.I_header_ready(S_header_ready),
        .O_data_offset(S_data_offset),.O_data_bytes(S_data_bytes),.O_total_frames(S_total_frames),
        .O_sample_valid(S_sample_valid),.I_sample_ready(S_sample_ready),
        .O_left(S_left),.O_right(S_right),.O_sample_index(S_sample_index),.O_sample_last(S_sample_last));
    audio_frame_fifo #(.ADDR_BITS(FIFO_ADDR_BITS),.PREFILL_FRAMES(PREFILL_FRAMES),.LOW_FRAMES(LOW_FRAMES)) u_pcm (
        .I_write_clk(I_decode_clk),.I_read_clk(I_audio_clk),.I_async_flush(I_async_flush),
        .I_valid(S_pcm_write_valid),.O_ready(S_pcm_write_ready),.I_left(S_left),.I_right(S_right),
        .O_valid(S_pcm_valid),.I_ready(I_ready && O_header_seen && !O_failed && !S_audio_reset),
        .O_left(O_left),.O_right(O_right),.O_write_level(O_write_level),.O_read_level(O_read_level),
        .O_prefilled(S_pcm_prefilled),.O_need_fill(S_pcm_need_fill));
    async_fifo #(.DATA_BITS(117),.ADDR_BITS(2)) u_events (
        .I_write_clk(I_decode_clk),.I_read_clk(I_audio_clk),.I_async_reset(I_async_flush),
        .I_write_valid(S_event_write_valid),.O_write_ready(S_event_write_ready),
        .I_write_data(S_event_write_data),.O_write_full(S_event_full),.O_write_level(S_event_write_level),
        .O_read_valid(O_event_valid),.I_read_ready(I_event_ready),
        .O_read_data({O_event_header,O_event_epoch,O_event_total_frames,O_event_written_frames,O_event_error,O_event_start_index}),
        .O_read_empty(S_event_empty),.O_read_level(S_event_read_level));
    assign O_valid=!I_async_flush && !S_audio_reset && O_header_seen && !O_failed && S_pcm_valid;
    assign O_prefilled=O_header_seen && !O_failed && S_pcm_prefilled;
    assign O_need_fill=O_header_seen && !O_failed && S_pcm_need_fill;

    always @(posedge I_decode_clk or posedge S_decode_reset) begin
        if (S_decode_reset) begin
            S_started<=0; S_reported<=0; S_terminal_pending<=0; S_epoch<=0;
            S_declared_total<=0; S_start_index<=0; S_seek_error<=0; S_terminal_error<=0; O_written_frames<=0;
            O_byte_discarded<=0; O_cancel_valid<=0;
        end else begin
            O_byte_discarded<=I_byte_valid && O_byte_ready && !S_forward;
            if (I_start_valid && O_start_ready) begin S_started<=1; S_epoch<=I_epoch; S_start_index<=I_start_index; end
            if (S_header_valid && S_header_ready) begin
                S_declared_total<=S_total_frames; S_seek_error<=S_start_index>S_total_frames;
            end
            if (S_sample_valid && S_sample_ready) O_written_frames<=O_written_frames+32'd1;
            if (O_cancel_valid && I_cancel_ready) O_cancel_valid<=0;
            if (S_terminal_pending && S_event_write_ready) begin
                S_terminal_pending<=0; S_reported<=1;
            end
            if (S_parser_done) begin
                S_terminal_pending<=1; S_terminal_error<=S_parser_error!=0 ? S_parser_error : S_seek_error ? 4'd6 : 4'd0;
                if (S_parser_err || S_seek_error) O_cancel_valid<=1;
            end
        end
    end
    always @(posedge I_audio_clk or posedge S_audio_reset) begin
        if (S_audio_reset) begin O_header_seen<=0; O_failed<=0; O_pcm_epoch<=0; end
        else if (S_event_fire) begin
            if (O_event_header) begin O_header_seen<=1; O_pcm_epoch<=O_event_epoch; end
            else if (O_event_error!=0) O_failed<=1;
        end
    end
endmodule
