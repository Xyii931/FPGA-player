// One controller per slot. File retirement is completion, not cancel acceptance.
// The audio owner must stop reuse and drain every reference before asserting idle.
module audio_slot_recycle (
    input wire I_decode_clk,I_audio_clk,I_async_reset,
    input wire I_recycle_valid,
    output wire O_recycle_ready,O_available,
    output reg O_done,
    input wire I_source_quiescent,I_source_start_ready,
    output wire O_abort,O_io_retire_request,
    input wire I_io_retired,
    output wire O_audio_stop,
    input wire I_audio_idle,
    output wire O_async_flush
);
    localparam [2:0] FLUSH=0,RECOVER=1,RELEASE=2,IDLE=3,WAIT_IDLE=4;
    reg [2:0] S_state;
    reg [1:0] S_flush_count;
    reg S_pending,S_stop_request,S_flush;
    wire S_decode_reset,S_audio_reset,S_audio_flush_reset;
    reg [1:0] S_stop_sync,S_ack_sync,S_audio_up_sync;
    reg S_audio_ack;

    reset_sync u_decode_reset (
        .I_clk(I_decode_clk),.I_async_reset(I_async_reset),.O_reset(S_decode_reset));
    reset_sync u_audio_reset (
        .I_clk(I_audio_clk),.I_async_reset(I_async_reset),.O_reset(S_audio_reset));
    reset_sync u_audio_flush_reset (
        .I_clk(I_audio_clk),.I_async_reset(O_async_flush),.O_reset(S_audio_flush_reset));

    assign O_async_flush=I_async_reset || S_decode_reset || S_flush;
    assign O_available=!S_decode_reset && S_state==IDLE && !I_io_retired;
    assign O_recycle_ready=O_available;
    assign O_abort=!S_decode_reset && S_state==WAIT_IDLE;
    assign O_io_retire_request=!S_decode_reset && S_pending &&
        (S_state==WAIT_IDLE || S_state==FLUSH || S_state==RECOVER);
    assign O_audio_stop=S_audio_reset || S_stop_sync[1];

    // Four-phase level handshake. Ack survives slot flush, until stop falls.
    always @(posedge I_audio_clk or posedge S_audio_reset) begin
        if (S_audio_reset) begin S_stop_sync<=2'b11; S_audio_ack<=0; end
        else begin
            S_stop_sync<={S_stop_sync[0],S_stop_request};
            if (!S_stop_sync[1]) S_audio_ack<=0;
            else if (I_audio_idle) S_audio_ack<=1;
        end
    end
    always @(posedge I_decode_clk or posedge S_decode_reset) begin
        if (S_decode_reset) begin S_ack_sync<=0; S_audio_up_sync<=0; end
        else begin
            S_ack_sync<={S_ack_sync[0],S_audio_ack};
            S_audio_up_sync<={S_audio_up_sync[0],!S_audio_flush_reset};
        end
    end
    always @(posedge I_decode_clk or posedge S_decode_reset) begin
        if (S_decode_reset) begin
            S_state<=FLUSH; S_flush_count<=0; S_pending<=0; O_done<=0;
            S_stop_request<=1; S_flush<=1;
        end else begin
            O_done<=0;
            case (S_state)
                FLUSH: begin
                    if (S_flush_count==3) begin
                        S_state<=RECOVER; S_flush_count<=0; S_flush<=0;
                    end
                    else S_flush_count<=S_flush_count+2'd1;
                end
                RECOVER: if (I_source_start_ready && S_audio_up_sync[1] && S_ack_sync[1]) begin
                    S_state<=RELEASE; S_stop_request<=0;
                end
                RELEASE: if (!S_ack_sync[1] && !I_io_retired) begin
                    S_state<=IDLE; O_done<=S_pending; S_pending<=0;
                end
                IDLE: if (I_recycle_valid && O_recycle_ready) begin
                    S_pending<=1; S_state<=WAIT_IDLE; S_stop_request<=1;
                end
                WAIT_IDLE: if (S_ack_sync[1] && I_source_quiescent && I_io_retired) begin
                    S_state<=FLUSH; S_flush_count<=0; S_flush<=1;
                end
                default: begin
                    S_state<=FLUSH; S_flush_count<=0; S_pending<=0;
                    S_stop_request<=1; S_flush<=1;
                end
            endcase
        end
    end
endmodule
