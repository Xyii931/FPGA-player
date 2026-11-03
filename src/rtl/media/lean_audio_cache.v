// Cache one complete, checked WAV after the first image becomes active.
// SDRAM words 0x100000..0x1fffff hold at most 4 MiB of raw file bytes;
// the two picture buffers occupy words 0..614399. Bytes are little endian.
// Publish only after file completion AND every memory write has retired.
module lean_audio_cache #(
    parameter integer MAX_BYTES=4194304
) (
    input wire I_clk,I_reset,I_catalog_ready,I_audio_found,I_enable,
    input wire I_memory_error,I_writes_idle,
    output wire O_ready,O_loading,
    output reg [3:0] O_error,
    output wire O_source_command_valid,
    input wire I_source_command_ready,
    output wire [31:0] O_source_offset,O_source_length,
    input wire I_source_begin_valid,
    output wire O_source_begin_ready,
    input wire [31:0] I_source_file_size,
    input wire [7:0] I_source_begin_error,
    input wire I_source_byte_valid,
    output wire O_source_byte_ready,
    input wire [7:0] I_source_byte_data,
    input wire [31:0] I_source_byte_offset,
    input wire I_source_file_done,
    input wire [7:0] I_source_file_error,
    input wire [31:0] I_source_file_bytes,
    input wire I_source_file_eof,
    output wire O_source_cancel,
    input wire I_command_valid,
    output wire O_command_ready,
    input wire [31:0] I_offset,I_length,
    output wire O_begin_valid,
    input wire I_begin_ready,
    output wire [31:0] O_file_size,
    output wire [7:0] O_begin_error,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire [31:0] O_byte_offset,
    output wire O_file_done,
    output wire [7:0] O_file_error,
    output wire [31:0] O_file_bytes,
    output wire O_file_eof,
    input wire I_cancel,
    output wire O_write_valid,
    input wire I_write_ready,
    output wire [20:0] O_write_address,
    output wire [31:0] O_write_data,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [20:0] O_read_address,
    input wire I_result_valid,
    output wire O_result_ready,
    input wire [31:0] I_result_data,
    input wire [3:0] I_result_error
);
    localparam [2:0] WAIT=0,REQUEST=1,BEGIN=2,FILL=3,DRAIN=4,READY=5,HALT=6;
    localparam [1:0] P_IDLE=0,P_BEGIN=1,P_BYTES=2,P_DONE=3;
    reg [2:0] S_state;
    reg [1:0] S_play_state;
    reg [31:0] S_size,S_received,S_pack,S_write_data;
    reg [20:0] S_write_address;
    reg S_failed,S_write_pending,S_read_busy,S_word_valid;
    reg [31:0] S_cursor,S_remaining,S_transferred,S_word;
    reg [7:0] S_play_error;
    wire S_source_take=I_source_byte_valid && O_source_byte_ready;
    wire S_source_bad_offset=I_source_byte_offset!=S_received || S_received>=S_size;
    wire S_write_take=O_write_valid && I_write_ready;
    wire S_read_take=O_read_valid && I_read_ready;
    wire S_byte_take=O_byte_valid && I_byte_ready;
    assign O_ready=!I_reset && S_state==READY && I_catalog_ready && !I_memory_error;
    assign O_loading=S_state==REQUEST || S_state==BEGIN || S_state==FILL || S_state==DRAIN;
    assign O_source_command_valid=!I_reset && S_state==REQUEST && I_catalog_ready;
    assign O_source_offset=32'd0;
    assign O_source_length=32'hffffffff;
    // A submitted command must retire even if media disappears before BEGIN.
    assign O_source_begin_ready=!I_reset && S_state==BEGIN;
    assign O_source_byte_ready=!I_reset && S_state==FILL &&
        (S_failed || !I_catalog_ready || I_memory_error || !S_write_pending);
    assign O_source_cancel=S_state==FILL && (S_failed || !I_catalog_ready || I_memory_error);
    assign O_write_valid=!I_reset && S_write_pending;
    assign O_write_address=S_write_address;
    assign O_write_data=S_write_data;
    assign O_command_ready=O_ready && S_play_state==P_IDLE && !S_read_busy;
    assign O_begin_valid=O_ready && S_play_state==P_BEGIN;
    assign O_file_size=S_size;
    assign O_begin_error=S_play_error;
    assign O_byte_valid=O_ready && S_play_state==P_BYTES && S_word_valid && S_remaining!=0 && !I_cancel;
    assign O_byte_data=S_word>>(8*S_cursor[1:0]);
    assign O_byte_offset=S_cursor;
    assign O_file_done=O_ready && S_play_state==P_DONE;
    assign O_file_error=S_play_error;
    assign O_file_bytes=S_transferred;
    assign O_file_eof=S_cursor==S_size;
    assign O_read_valid=O_ready && S_play_state==P_BYTES && S_remaining!=0 &&
        !S_word_valid && !S_read_busy && !I_cancel;
    assign O_read_address={1'b1,S_cursor[21:2]};
    // Drain old returns after media loss before accepting a new playback job.
    assign O_result_ready=!I_reset;

    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=WAIT; S_size<=0; S_received<=0; S_pack<=0; S_failed<=0;
            S_write_pending<=0; S_write_address<=0; S_write_data<=0; O_error<=0;
        end else begin
            if(S_write_take) S_write_pending<=0;
            case(S_state)
                WAIT:begin
                    if(!I_catalog_ready) O_error<=0;
                    if(I_catalog_ready && I_audio_found && I_enable && !I_memory_error &&
                        !S_write_pending && !S_read_busy && I_writes_idle) begin
                        S_received<=0; S_pack<=0; S_failed<=0; O_error<=0; S_state<=REQUEST;
                    end
                end
                REQUEST:if(!I_catalog_ready) S_state<=WAIT;
                    else if(I_source_command_ready) S_state<=BEGIN;
                BEGIN:if(I_source_begin_valid) begin
                    S_size<=I_source_file_size;
                    // Failed Begin has no following Byte/Done transaction.
                    S_state<=I_source_begin_error!=0 ? DRAIN : FILL;
                    if(!I_catalog_ready || I_memory_error || I_source_begin_error!=0 ||
                        I_source_file_size<12 || I_source_file_size>MAX_BYTES) begin
                        S_failed<=1;
                        if(I_catalog_ready) O_error<=I_source_file_size>MAX_BYTES ? 4'd1 : 4'd2;
                    end
                end
                FILL:begin
                    if(!I_catalog_ready || I_memory_error) begin
                        S_failed<=1;
                        if(I_memory_error) O_error<=4'd4;
                    end
                    if(S_source_take && !S_failed && I_catalog_ready && !I_memory_error) begin
                        if(S_source_bad_offset) begin S_failed<=1; O_error<=4'd2; end
                        else begin
                            S_received<=S_received+32'd1;
                            S_pack[S_received[1:0]*8+:8]<=I_source_byte_data;
                            if(S_received[1:0]==3 || S_received+32'd1==S_size) begin
                                S_write_pending<=1;
                                S_write_address<={1'b1,S_received[21:2]};
                                case(S_received[1:0])
                                    0:S_write_data<={24'd0,I_source_byte_data};
                                    1:S_write_data<={16'd0,I_source_byte_data,S_pack[7:0]};
                                    2:S_write_data<={8'd0,I_source_byte_data,S_pack[15:0]};
                                    3:S_write_data<={I_source_byte_data,S_pack[23:0]};
                                endcase
                            end
                        end
                    end
                    if(I_source_file_done) begin
                        S_state<=DRAIN;
                        if(I_source_file_error!=0 || !I_source_file_eof ||
                            I_source_file_bytes!=S_size || S_received!=S_size) begin
                            S_failed<=1;
                            if(I_catalog_ready && !S_failed) O_error<=4'd3;
                        end
                    end
                end
                DRAIN:if(!S_write_pending && I_writes_idle) begin
                    if(!I_catalog_ready) S_state<=WAIT;
                    else if(S_failed || I_memory_error) S_state<=HALT;
                    else S_state<=READY;
                end
                READY:if(!I_catalog_ready) S_state<=WAIT;
                    else if(I_memory_error) begin O_error<=4'd4; S_state<=HALT; end
                HALT:if(!I_catalog_ready) S_state<=WAIT;
                default:S_state<=WAIT;
            endcase
        end
    end

    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_play_state<=P_IDLE; S_cursor<=0; S_remaining<=0; S_transferred<=0;
            S_play_error<=0; S_read_busy<=0; S_word_valid<=0; S_word<=0;
        end else begin
            if(S_read_take) S_read_busy<=1;
            if(I_result_valid && O_result_ready) begin
                S_read_busy<=0;
                if(O_ready && S_play_state==P_BYTES && !I_cancel) begin
                    if(I_result_error!=0) begin S_play_error<=8'd2; S_play_state<=P_DONE; end
                    else begin S_word<=I_result_data; S_word_valid<=1; end
                end
            end
            if(!O_ready) begin S_play_state<=P_IDLE; S_word_valid<=0; end
            else if(I_cancel && S_play_state!=P_IDLE && S_play_state!=P_DONE) begin
                S_play_error<=8'd8; S_word_valid<=0; S_play_state<=P_DONE;
            end else case(S_play_state)
                P_IDLE:if(I_command_valid && O_command_ready) begin
                    S_cursor<=I_offset; S_transferred<=0; S_word_valid<=0;
                    S_play_error<=I_offset>S_size ? 8'd11 : 8'd0;
                    S_remaining<=I_offset>S_size ? 32'd0 :
                        (I_length>S_size-I_offset ? S_size-I_offset : I_length);
                    S_play_state<=P_BEGIN;
                end
                P_BEGIN:if(I_begin_ready) S_play_state<=S_remaining==0 ? P_DONE : P_BYTES;
                P_BYTES:if(S_byte_take) begin
                    S_cursor<=S_cursor+32'd1; S_remaining<=S_remaining-32'd1;
                    S_transferred<=S_transferred+32'd1;
                    if(S_cursor[1:0]==3 || S_remaining==1) S_word_valid<=0;
                    if(S_remaining==1) S_play_state<=P_DONE;
                end
                P_DONE:S_play_state<=P_IDLE;
            endcase
        end
    end
    // synthesis translate_off
    initial if(MAX_BYTES<12 || MAX_BYTES>4194304) begin
        $display("FAIL: lean_audio_cache MAX_BYTES outside SDRAM reservation"); $stop;
    end
    // synthesis translate_on
endmodule
