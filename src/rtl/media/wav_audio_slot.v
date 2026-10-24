// One file transaction, two clock domains, one independently recyclable slot.
// File retirement completion is supplied by the real I/O owner, never fabricated.
module wav_audio_slot #(
    parameter integer FIFO_ADDR_BITS=11,
    parameter integer PREFILL_FRAMES=1024,
    parameter integer LOW_FRAMES=512
) (
    input wire I_decode_clk,I_audio_clk,I_async_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,I_start_index,
    input wire [15:0] I_epoch,
    input wire I_byte_valid,I_byte_last,
    input wire [7:0] I_byte_data,
    input wire [15:0] I_byte_epoch,
    output wire O_byte_ready,O_byte_discarded,
    input wire I_stream_error_valid,
    input wire [15:0] I_stream_error_epoch,
    input wire I_recycle_valid,
    output wire O_recycle_ready,O_recycle_done,O_available,
    output wire O_cancel_valid,
    input wire I_cancel_ready,
    output wire [15:0] O_cancel_epoch,
    output wire O_io_retire_request,
    input wire I_io_retired,
    output wire O_source_busy,
    output wire [31:0] O_written_frames,
    output wire O_stop,O_clear,
    input wire I_idle,
    output wire O_pcm_valid,
    input wire I_pcm_ready,
    output wire [23:0] O_left,O_right,
    output wire [FIFO_ADDR_BITS:0] O_level,
    output wire O_prefilled,O_need_fill,O_failed,
    output wire O_load_valid,
    input wire I_load_ready,
    output wire [31:0] O_total_frames,O_start_index,
    output reg O_event_valid,
    input wire I_event_ready,
    output wire O_event_header,
    output wire [15:0] O_event_epoch,
    output wire [31:0] O_event_total_frames,O_event_written_frames,
    output wire [3:0] O_event_error
);
    wire S_flush,S_stop,S_abort,S_quiet,S_start_ready;
    wire S_pcm_valid,S_header_seen;
    wire [15:0] S_pcm_epoch;
    wire [FIFO_ADDR_BITS:0] S_write_level;
    wire S_event_valid,S_event_header;
    wire [15:0] S_event_epoch;
    wire [31:0] S_event_total,S_event_written,S_event_start_index;
    wire [3:0] S_event_error;
    reg [84:0] S_event;
    wire S_buffer_ready=!O_event_valid || I_event_ready;
    wire S_event_ready=S_buffer_ready && (!S_event_header || O_stop || I_load_ready);

    audio_slot_recycle u_recycle (
        .I_decode_clk(I_decode_clk),.I_audio_clk(I_audio_clk),.I_async_reset(I_async_reset),
        .I_recycle_valid(I_recycle_valid),.O_recycle_ready(O_recycle_ready),
        .O_available(O_available),.O_done(O_recycle_done),
        .I_source_quiescent(S_quiet),.I_source_start_ready(S_start_ready),
        .O_abort(S_abort),.O_io_retire_request(O_io_retire_request),.I_io_retired(I_io_retired),
        .O_audio_stop(S_stop),.I_audio_idle(I_idle),.O_async_flush(S_flush));
    reset_sync u_slot_clear (
        .I_clk(I_audio_clk),.I_async_reset(S_flush),.O_reset(O_clear));
    assign O_start_ready=O_available && !I_recycle_valid && S_start_ready;
    assign O_stop=S_stop || O_failed;
    assign O_pcm_valid=S_pcm_valid && !O_stop && !O_clear;
    assign O_load_valid=S_event_valid && S_event_header && !O_stop && !O_clear && S_buffer_ready;
    assign O_total_frames=S_event_total;
    assign O_start_index=S_event_start_index;
    assign {O_event_header,O_event_epoch,O_event_total_frames,O_event_written_frames,O_event_error}=S_event;

    wav_track_source #(.FIFO_ADDR_BITS(FIFO_ADDR_BITS),
        .PREFILL_FRAMES(PREFILL_FRAMES),.LOW_FRAMES(LOW_FRAMES)) u_source (
        .I_decode_clk(I_decode_clk),.I_audio_clk(I_audio_clk),.I_async_flush(S_flush),
        .I_start_valid(I_start_valid && O_start_ready),.O_start_ready(S_start_ready),
        .I_file_size(I_file_size),.I_start_index(I_start_index),.I_epoch(I_epoch),
        .I_byte_valid(I_byte_valid),.O_byte_ready(O_byte_ready),.I_byte_data(I_byte_data),
        .I_byte_last(I_byte_last),.I_byte_epoch(I_byte_epoch),.I_abort(S_abort),
        .I_stream_error_valid(I_stream_error_valid),.I_stream_error_epoch(I_stream_error_epoch),
        .O_byte_discarded(O_byte_discarded),.O_cancel_valid(O_cancel_valid),
        .I_cancel_ready(I_cancel_ready),.O_cancel_epoch(O_cancel_epoch),
        .O_busy(O_source_busy),.O_quiescent(S_quiet),.O_written_frames(O_written_frames),
        .O_valid(S_pcm_valid),.I_ready(I_pcm_ready && !O_stop && !O_clear),
        .O_left(O_left),.O_right(O_right),.O_pcm_epoch(S_pcm_epoch),
        .O_write_level(S_write_level),.O_read_level(O_level),
        .O_prefilled(O_prefilled),.O_need_fill(O_need_fill),
        .O_header_seen(S_header_seen),.O_failed(O_failed),
        .O_event_valid(S_event_valid),.I_event_ready(S_event_ready),
        .O_event_header(S_event_header),.O_event_epoch(S_event_epoch),
        .O_event_total_frames(S_event_total),.O_event_written_frames(S_event_written),.O_event_start_index(S_event_start_index),
        .O_event_error(S_event_error));

    // An elastic event register decouples external backpressure from load ready.
    // A shared slot flush explicitly cancels any old event still being offered.
    always @(posedge I_audio_clk or posedge O_clear) begin
        if (O_clear) begin O_event_valid<=0; S_event<=0; end
        else if (S_buffer_ready) begin
            O_event_valid<=S_event_valid && S_event_ready;
            if (S_event_valid && S_event_ready)
                S_event<={S_event_header,S_event_epoch,S_event_total,S_event_written,S_event_error};
        end
    end
endmodule
