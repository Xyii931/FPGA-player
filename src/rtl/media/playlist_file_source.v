// One explicitly leased, initially closed FAT32 context. All ports are host-domain.
// Return buses may be shared: never consume another context's response.
module playlist_file_source (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,O_lease_request,
    input wire I_lease_grant,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,I_seed,I_sector_budget,
    input wire I_abort,
    output wire O_lease_active,O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [7:0] O_file_error,
    output reg [3:0] O_storage_error,
    output reg [2:0] O_path_warning,
    output reg [1:0] O_context,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,O_file_size,
    output reg O_builder_started,
    output wire O_missing,

    output wire O_build_start_valid,
    input wire I_build_start_ready,
    output wire [31:0] O_build_file_size,O_build_generation,O_build_seed,
    output wire [15:0] O_build_tag,
    output wire O_build_byte_valid,
    input wire I_build_byte_ready,
    output wire [7:0] O_build_byte_data,
    output wire O_build_byte_last,
    output wire [15:0] O_build_byte_tag,
    output wire [31:0] O_build_byte_generation,
    output wire O_build_retire_valid,
    input wire I_build_retire_ready,
    output wire [15:0] O_build_retire_tag,
    output wire [31:0] O_build_retire_generation,
    output wire [7:0] O_build_retire_error,
    output wire O_build_stream_error,
    input wire I_build_cancel,
    input wire [15:0] I_build_cancel_tag,
    input wire [31:0] I_build_cancel_generation,

    output wire O_fs_open_valid,
    input wire I_fs_open_ready,
    output wire [1:0] O_fs_open_context,
    output wire [15:0] O_fs_open_tag,
    output wire [6:0] O_fs_path_length,
    output wire [31:0] O_fs_sector_budget,
    output wire O_fs_path_valid,
    input wire I_fs_path_ready,
    output wire [7:0] O_fs_path_data,
    output wire O_fs_path_last,O_fs_open_cancel,
    input wire I_fs_open_result_valid,
    output wire O_fs_open_result_ready,
    input wire [1:0] I_fs_open_context,
    input wire [15:0] I_fs_open_tag,
    input wire [31:0] I_fs_open_generation,I_fs_open_size,
    input wire [7:0] I_fs_open_error,
    input wire [3:0] I_fs_open_storage_error,
    input wire [2:0] I_fs_open_warning,

    output wire O_fs_read_valid,
    input wire I_fs_read_ready,
    output wire [1:0] O_fs_read_context,O_fs_read_priority,
    output wire [31:0] O_fs_offset,O_fs_length,
    output wire [15:0] O_fs_epoch,
    input wire I_fs_byte_valid,
    output wire O_fs_byte_ready,
    input wire [7:0] I_fs_byte_data,
    input wire [1:0] I_fs_byte_context,
    input wire [15:0] I_fs_byte_epoch,
    input wire [31:0] I_fs_byte_generation,I_fs_byte_offset,
    input wire I_fs_byte_last,
    input wire I_fs_done_valid,
    output wire O_fs_done_ready,
    input wire [1:0] I_fs_done_context,
    input wire [15:0] I_fs_done_epoch,
    input wire [31:0] I_fs_done_generation,I_fs_done_bytes,
    input wire I_fs_done_eof,
    input wire [7:0] I_fs_done_error,
    input wire [3:0] I_fs_done_storage_error,

    output wire O_fs_cancel_valid,
    input wire I_fs_cancel_ready,
    output wire [1:0] O_fs_cancel_context,
    output wire [15:0] O_fs_cancel_epoch,
    input wire I_fs_cancel_done_valid,
    output wire O_fs_cancel_done_ready,
    input wire [1:0] I_fs_cancel_done_context,
    input wire [15:0] I_fs_cancel_done_epoch,
    input wire [31:0] I_fs_cancel_done_generation,
    output wire O_fs_close_valid,
    input wire I_fs_close_ready,
    output wire [1:0] O_fs_close_context
);
    localparam [3:0] IDLE=0,OPEN_CMD=1,PATH=2,OPEN_WAIT=3,BUILD_START=4,
        READ_CMD=5,TRANSFER=6,CLOSE=7,RETIRE=8,RESULT=9;
    localparam [143:0] PLAYLIST_PATH="/PLAY/PLAYLIST.TXT";
    reg [3:0] S_state;
    reg [4:0] S_path_index;
    reg [31:0] S_seed,S_budget;
    reg [32:0] S_received;
    reg S_done_seen,S_cancel_sent,S_cancel_acked;
    wire S_work=S_state!=IDLE && S_state!=RETIRE && S_state!=RESULT;
    wire S_media_matches=I_media_valid && I_media_generation==O_generation;
    wire S_build_cancel=O_builder_started && I_build_cancel &&
        I_build_cancel_tag==O_tag && I_build_cancel_generation==O_generation &&
        S_received!={1'b0,O_file_size};
    wire [3:0] S_current_error=!S_media_matches ? 4'd3 :
        (I_abort || (S_build_cancel && O_error==0)) ? 4'd2 : 4'd0;
    wire [3:0] S_effective_error=prefer_error(O_error,S_current_error);
    wire S_stop=S_effective_error!=0;
    wire S_open_wait=S_state==PATH || S_state==OPEN_WAIT;
    wire S_open_matches=I_fs_open_context==O_context && I_fs_open_tag==O_tag &&
        I_fs_open_generation==O_generation;
    wire S_open_accept=I_fs_open_result_valid && O_fs_open_result_ready && S_open_matches;
    wire S_byte_matches=I_fs_byte_context==O_context && I_fs_byte_epoch==O_tag &&
        I_fs_byte_generation==O_generation;
    wire S_byte_accept=I_fs_byte_valid && O_fs_byte_ready && S_byte_matches && !S_done_seen;
    wire [33:0] S_received_now={1'b0,S_received}+(S_byte_accept ? 34'd1 : 34'd0);
    wire S_byte_bad=S_byte_accept && (S_received>={1'b0,O_file_size} ||
        {1'b0,I_fs_byte_offset}!=S_received ||
        I_fs_byte_last!=(S_received+33'd1=={1'b0,O_file_size}));
    wire S_done_matches=I_fs_done_context==O_context && I_fs_done_epoch==O_tag &&
        I_fs_done_generation==O_generation;
    wire S_done_accept=I_fs_done_valid && O_fs_done_ready && S_done_matches && !S_done_seen;
    wire S_expected_cancel=I_fs_done_error==8 && S_effective_error!=0 &&
        (S_cancel_sent || (O_fs_cancel_valid && I_fs_cancel_ready)) &&
        (I_fs_done_storage_error==0 || I_fs_done_storage_error==6);
    wire S_cancel_matches=I_fs_cancel_done_context==O_context && I_fs_cancel_done_epoch==O_tag &&
        I_fs_cancel_done_generation==O_generation;

    function [2:0] error_rank;
        input [3:0] value;
        begin case(value) 3:error_rank=5; 2:error_rank=4; 1:error_rank=3;
            4:error_rank=2; 5:error_rank=1; default:error_rank=0; endcase end
    endfunction
    function [3:0] prefer_error;
        input [3:0] old_error,new_error;
        begin prefer_error=error_rank(new_error)>error_rank(old_error) ? new_error : old_error; end
    endfunction

    assign O_start_ready=!I_reset && S_state==IDLE && I_lease_grant && I_context<3;
    assign O_lease_request=!I_reset && S_state==IDLE && I_start_valid && I_context<3;
    assign O_lease_active=!I_reset && S_state!=IDLE;
    assign O_busy=O_lease_active;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_missing=O_error==5;
    assign O_build_start_valid=!I_reset && S_state==BUILD_START && !S_stop;
    assign O_build_file_size=O_file_size;
    assign O_build_generation=O_generation;
    assign O_build_seed=S_seed;
    assign O_build_tag=O_tag;
    assign O_build_byte_valid=!I_reset && S_state==TRANSFER && !S_done_seen &&
        !S_stop && S_byte_matches && I_fs_byte_valid;
    assign O_build_byte_data=I_fs_byte_data;
    assign O_build_byte_last=I_fs_byte_last;
    assign O_build_byte_tag=O_tag;
    assign O_build_byte_generation=O_generation;
    assign O_build_retire_valid=!I_reset && S_state==RETIRE;
    assign O_build_retire_tag=O_tag;
    assign O_build_retire_generation=O_generation;
    assign O_build_retire_error={4'd0,O_error};
    assign O_build_stream_error=O_builder_started && (O_error==1 || O_error==4);

    assign O_fs_open_valid=!I_reset && S_state==OPEN_CMD && !S_stop;
    assign O_fs_open_context=O_context;
    assign O_fs_open_tag=O_tag;
    assign O_fs_path_length=7'd18;
    assign O_fs_sector_budget=S_budget;
    assign O_fs_path_valid=!I_reset && S_state==PATH && !S_stop && !S_open_accept;
    assign O_fs_path_data=PLAYLIST_PATH[(17-S_path_index)*8+:8];
    assign O_fs_path_last=S_path_index==17;
    assign O_fs_open_cancel=!I_reset && S_open_wait && S_stop;
    assign O_fs_open_result_ready=!I_reset && S_open_wait && I_fs_open_context==O_context;
    assign O_fs_read_valid=!I_reset && S_state==READ_CMD && !S_stop;
    assign O_fs_read_context=O_context;
    assign O_fs_read_priority=2'd0;
    assign O_fs_offset=32'd0;
    assign O_fs_length=O_file_size;
    assign O_fs_epoch=O_tag;
    assign O_fs_byte_ready=!I_reset && S_state==TRANSFER && I_fs_byte_context==O_context &&
        (!S_byte_matches || S_stop || S_done_seen || I_build_byte_ready);
    assign O_fs_done_ready=!I_reset && S_state==TRANSFER && I_fs_done_context==O_context;
    // A terminal accepted before cancel acceptance removes the need for a new cancel.
    // If both handshake together, retain the cancel obligation until its real ack.
    assign O_fs_cancel_valid=!I_reset && S_state==TRANSFER && S_stop && !S_done_seen && !S_cancel_sent;
    assign O_fs_cancel_context=O_context;
    assign O_fs_cancel_epoch=O_tag;
    assign O_fs_cancel_done_ready=!I_reset && S_state==TRANSFER && S_cancel_sent &&
        I_fs_cancel_done_context==O_context;
    assign O_fs_close_valid=!I_reset && S_state==CLOSE;
    assign O_fs_close_context=O_context;

    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_path_index<=0; S_seed<=0; S_budget<=0; S_received<=0;
            S_done_seen<=0; S_cancel_sent<=0; S_cancel_acked<=0;
            O_error<=0; O_file_error<=0; O_storage_error<=0; O_path_warning<=0;
            O_context<=0; O_tag<=0; O_generation<=0; O_file_size<=0; O_builder_started<=0;
        end else begin
            if(S_work) O_error<=S_effective_error;
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    O_context<=I_context; O_tag<=I_tag; O_generation<=I_generation;
                    S_seed<=I_seed; S_budget<=I_sector_budget; S_path_index<=0; S_received<=0;
                    S_done_seen<=0; S_cancel_sent<=0; S_cancel_acked<=0;
                    O_file_size<=0; O_builder_started<=0; O_file_error<=0;
                    O_storage_error<=0; O_path_warning<=0;
                    O_error<=!I_media_valid || I_media_generation!=I_generation ? 4'd3 :
                        I_abort ? 4'd2 : 4'd0;
                    S_state<=OPEN_CMD;
                end
                OPEN_CMD:if(S_stop) S_state<=RESULT;
                    else if(I_fs_open_ready) S_state<=PATH;
                PATH,OPEN_WAIT:begin
                    if(S_open_accept) begin
                        O_file_error<=I_fs_open_error; O_storage_error<=I_fs_open_storage_error;
                        O_path_warning<=I_fs_open_warning; O_file_size<=I_fs_open_size;
                        if(I_fs_open_error!=0) begin
                            O_error<=prefer_error(S_effective_error,
                                I_fs_open_error==14 && I_fs_open_storage_error==0 ? 4'd5 : 4'd1);
                            S_state<=RESULT;
                        end else if(I_fs_open_storage_error!=0) begin
                            O_error<=prefer_error(S_effective_error,4'd1); S_state<=CLOSE;
                        end else S_state<=S_stop ? CLOSE : BUILD_START;
                    end else if(S_state==PATH) begin
                        if(S_stop) S_state<=OPEN_WAIT;
                        else if(O_fs_path_valid && I_fs_path_ready) begin
                            if(S_path_index==17) S_state<=OPEN_WAIT;
                            else S_path_index<=S_path_index+5'd1;
                        end
                    end
                end
                BUILD_START:if(S_stop) S_state<=CLOSE;
                    else if(I_build_start_ready) begin O_builder_started<=1; S_state<=READ_CMD; end
                READ_CMD:if(S_stop) S_state<=CLOSE;
                    else if(I_fs_read_ready) S_state<=TRANSFER;
                TRANSFER:begin
                    if(S_byte_accept && !(&S_received)) S_received<=S_received+33'd1;
                    if(S_byte_bad) O_error<=prefer_error(S_effective_error,4'd4);
                    if(O_fs_cancel_valid && I_fs_cancel_ready) S_cancel_sent<=1;
                    if(I_fs_cancel_done_valid && O_fs_cancel_done_ready && S_cancel_matches) S_cancel_acked<=1;
                    if(S_done_accept) begin
                        S_done_seen<=1; O_file_error<=I_fs_done_error; O_storage_error<=I_fs_done_storage_error;
                        // An acknowledgement of our own cancellation is not a new I/O fault.
                        // Preserve the original protocol/abort/loss cause and raw diagnostics.
                        if(S_expected_cancel) O_error<=prefer_error(S_effective_error,S_byte_bad ? 4'd4 : 4'd0);
                        else if(I_fs_done_error!=0 || I_fs_done_storage_error!=0)
                            O_error<=prefer_error(S_effective_error,4'd1);
                        else if(S_received_now!={2'd0,O_file_size} || I_fs_done_bytes!=O_file_size || !I_fs_done_eof || S_byte_bad)
                            O_error<=prefer_error(S_effective_error,4'd4);
                    end
                    if(S_done_seen && (!S_cancel_sent || S_cancel_acked)) S_state<=CLOSE;
                end
                CLOSE:if(I_fs_close_ready) S_state<=O_builder_started ? RETIRE : RESULT;
                // The retirement record is already published: keep every field stable.
                RETIRE:if(I_build_retire_ready) S_state<=RESULT;
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
