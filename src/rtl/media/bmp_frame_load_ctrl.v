// One TF BMP -> one complete offscreen framebuffer lease. Host clock domain.
// Global reset must also reset the file/core and memory transaction owners.
module bmp_frame_load_ctrl (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,O_lease_request,O_lease_active,
    input wire I_lease_grant,I_config_valid,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,I_asset,
    input wire [2:0] I_slot,I_layout,
    input wire [1:0] I_rotation,
    input wire I_abort,
    input wire I_more_parts,I_part_valid,
    output wire O_part_needed,O_part_ready,
    output wire O_file_start_valid,
    input wire I_file_start_ready,I_file_header_valid,
    output wire O_file_header_ready,O_transform_start_valid,
    input wire I_transform_start_ready,I_geometry_valid,
    output wire O_geometry_ready,O_writer_start_valid,
    input wire I_writer_start_ready,
    output wire O_writer_lease_grant,O_file_abort,O_transform_abort,O_writer_abort,
    input wire I_writer_cancel_source,
    input wire I_file_done_valid,
    output wire O_file_done_ready,
    input wire [1:0] I_file_context,
    input wire [15:0] I_file_tag,
    input wire [31:0] I_file_generation,I_file_size,
    input wire [3:0] I_file_error,I_parser_error,I_storage_error,
    input wire [7:0] I_fs_error,
    input wire [2:0] I_path_warning,
    input wire I_transform_done_valid,
    output wire O_transform_done_ready,
    input wire [15:0] I_transform_tag,
    input wire [31:0] I_transform_generation,
    input wire [3:0] I_transform_error,
    input wire I_writer_done_valid,
    output wire O_writer_done_ready,
    input wire [15:0] I_writer_tag,
    input wire [2:0] I_writer_slot,
    input wire [31:0] I_writer_generation,I_writer_token,
    input wire [3:0] I_writer_error,I_memory_error,
    input wire [31:0] I_accepted_writes,I_retired_writes,I_pixels,
    output wire O_source_valid,
    input wire I_source_ready,
    output wire [3:0] O_source_error,
    output wire O_slot_cmd_valid,
    input wire I_slot_cmd_ready,
    output wire [2:0] O_slot_cmd_op,O_slot_cmd_slot,
    output wire [1:0] O_slot_cmd_owner,
    output wire [31:0] O_slot_cmd_token,O_slot_cmd_generation,O_slot_cmd_asset,
    output wire [2:0] O_slot_cmd_layout,
    output wire [1:0] O_slot_cmd_rotation,
    output wire O_slot_cmd_resident,O_slot_cmd_success,O_producer_retired,O_memory_retired,
    input wire I_slot_result_valid,
    output wire O_slot_result_ready,
    input wire [3:0] I_slot_result_error,
    input wire [2:0] I_slot_result_op,I_slot_result_slot,
    input wire [1:0] I_slot_result_owner,
    input wire [31:0] I_slot_result_token,I_slot_result_generation,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [1:0] O_context,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,O_lease_token,
    output reg [2:0] O_slot,
    output reg O_published,O_slot_owned,O_file_started,O_transform_started,O_writer_started,
    output reg [3:0] O_file_source_error,O_parser_error,O_storage_error,O_transform_error,O_writer_error,O_memory_error,
    output reg [7:0] O_file_error,
    output reg [2:0] O_path_warning,
    output reg [31:0] O_file_size,O_accepted_writes,O_retired_writes,O_pixels,
    output reg O_response_discarded
);
    localparam [3:0] IDLE=0,ALLOC_SEND=1,ALLOC_WAIT=2,WORK=3,
        FINISH_PREP=4,FINISH_SEND=5,FINISH_WAIT=6,RESULT=7,NEXT_PART=8;
    reg [3:0] S_state;
    reg [31:0] S_asset;
    reg [2:0] S_layout;
    reg [1:0] S_rotation;
    reg S_file_seen,S_transform_seen,S_writer_seen,S_source_sent,S_finish_success;
    reg [3:0] S_source_error;
    wire S_work=S_state==WORK;
    wire S_active=S_state!=IDLE && S_state!=RESULT;
    wire S_media_bad=!I_media_valid || I_media_generation!=O_generation;
    wire S_file_fire=I_file_done_valid && O_file_done_ready && O_file_started && !S_file_seen &&
        I_file_context==O_context && I_file_tag==O_tag && I_file_generation==O_generation;
    wire S_transform_fire=I_transform_done_valid && O_transform_done_ready && O_transform_started &&
        !S_transform_seen && I_transform_tag==O_tag && I_transform_generation==O_generation;
    wire S_writer_fire=I_writer_done_valid && O_writer_done_ready && O_writer_started && !S_writer_seen &&
        I_writer_tag==O_tag && I_writer_slot==O_slot && I_writer_token==O_lease_token &&
        I_writer_generation==O_generation;
    // Only genuine terminal errors feed writer.abort. Never feed cancel_source
    // combinationally back into writer.abort (the writer derives cancel from abort).
    wire S_terminal_bad=(S_file_fire && I_file_error!=0) ||
        (S_transform_fire && I_transform_error!=0) || (S_writer_fire && I_writer_error!=0);
    wire S_stop=O_error!=0 || I_abort || S_media_bad || S_terminal_bad;
    wire S_launch_stop=S_stop || I_writer_cancel_source;
    wire S_file_start=O_file_start_valid && I_file_start_ready;
    wire S_transform_start=O_transform_start_valid && I_transform_start_ready;
    wire S_writer_start=O_writer_start_valid && I_writer_start_ready;
    wire S_slot_match=I_slot_result_slot==O_slot && I_slot_result_owner==O_context &&
        I_slot_result_generation==O_generation &&
        ((S_state==ALLOC_WAIT && I_slot_result_op==0) ||
         (S_state==FINISH_WAIT && I_slot_result_op==1 && I_slot_result_token==O_lease_token));
    wire S_slot_fire=I_slot_result_valid && O_slot_result_ready && S_slot_match;
    reg [3:0] S_next_error;
    always @* begin
        S_next_error=O_error;
        if (S_work && S_next_error==0) begin
            if (S_file_fire && I_file_error!=0) S_next_error=3;
            else if (S_transform_fire && I_transform_error!=0) S_next_error=4;
            else if ((S_writer_fire && I_writer_error!=0) || I_writer_cancel_source) S_next_error=5;
        end
        // The FINISH success payload has a fixed decision boundary. Late user
        // abort cannot rewrite a presented command; media invalidation still can fail it.
        if (I_abort && (S_state<=FINISH_PREP || S_state==NEXT_PART) && S_next_error!=6) S_next_error=7;
        if (S_media_bad) S_next_error=6;
    end
    assign O_part_needed=!I_reset && S_state==NEXT_PART && !S_stop;
    assign O_part_ready=O_part_needed;
    assign O_start_ready=!I_reset && S_state==IDLE && !O_slot_owned && I_context<3 && I_lease_grant;
    assign O_lease_request=!I_reset && S_state==IDLE && !O_slot_owned && I_context<3 && I_start_valid;
    assign O_lease_active=S_state!=IDLE;
    assign O_busy=S_state!=IDLE || O_slot_owned;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_file_start_valid=!I_reset && S_work && !O_file_started && !S_launch_stop;
    assign O_transform_start_valid=!I_reset && S_work && O_file_started && !S_file_seen &&
        !O_transform_started && !S_launch_stop && I_file_header_valid;
    assign O_file_header_ready=!I_reset && S_work && O_file_started && !S_file_seen &&
        !O_transform_started && !S_launch_stop && I_transform_start_ready;
    assign O_writer_start_valid=!I_reset && S_work && O_transform_started && !S_transform_seen &&
        !O_writer_started && !S_launch_stop && I_geometry_valid;
    assign O_geometry_ready=!I_reset && S_work && O_transform_started && !S_transform_seen &&
        !O_writer_started && !S_launch_stop && I_writer_start_ready;
    assign O_writer_lease_grant=!I_reset && S_work && O_slot_owned;
    // After a writer-origin failure, peer abort terminals are diagnostics. Sending
    // that cause back as user abort would overwrite the writer's original code.
    assign O_writer_abort=S_work && (I_abort || S_media_bad || (O_error!=0 && O_error!=5) ||
        (O_error==0 && ((S_file_fire && I_file_error!=0) || (S_transform_fire && I_transform_error!=0))));
    assign O_file_abort=S_work && (S_stop || I_writer_cancel_source);
    assign O_transform_abort=O_file_abort;
    assign O_file_done_ready=!I_reset && S_work;
    assign O_transform_done_ready=!I_reset && S_work;
    assign O_writer_done_ready=!I_reset && S_work;
    // Registered union of the REAL file and transform terminals, never pixel_last.
    assign O_source_valid=!I_reset && S_work && O_writer_started && S_file_seen && S_transform_seen && !S_source_sent;
    assign O_source_error=S_source_error;
    assign O_slot_cmd_valid=!I_reset && (S_state==ALLOC_SEND || S_state==FINISH_SEND);
    assign O_slot_cmd_op=S_state==ALLOC_SEND || S_state==ALLOC_WAIT ? 3'd0 : 3'd1;
    assign O_slot_cmd_slot=O_slot;
    assign O_slot_cmd_owner=O_context;
    assign O_slot_cmd_token=O_lease_token;
    assign O_slot_cmd_generation=O_generation;
    assign O_slot_cmd_asset=S_asset;
    assign O_slot_cmd_layout=S_layout;
    assign O_slot_cmd_rotation=S_rotation;
    assign O_slot_cmd_resident=1'b0;
    assign O_slot_cmd_success=S_finish_success;
    assign O_producer_retired=(!O_file_started || S_file_seen) && (!O_transform_started || S_transform_seen);
    assign O_memory_retired=!O_writer_started || S_writer_seen;
    assign O_slot_result_ready=!I_reset && (S_state==ALLOC_WAIT || S_state==FINISH_WAIT);

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=IDLE; S_asset<=0; S_layout<=0; S_rotation<=0;
            S_file_seen<=0; S_transform_seen<=0; S_writer_seen<=0; S_source_sent<=0;
            S_source_error<=0; S_finish_success<=0;
            O_error<=0; O_context<=0; O_tag<=0; O_generation<=0; O_lease_token<=0; O_slot<=0;
            O_published<=0; O_slot_owned<=0; O_file_started<=0; O_transform_started<=0; O_writer_started<=0;
            O_file_source_error<=0; O_parser_error<=0; O_storage_error<=0; O_file_error<=0;
            O_transform_error<=0; O_writer_error<=0; O_memory_error<=0; O_path_warning<=0;
            O_file_size<=0; O_accepted_writes<=0; O_retired_writes<=0; O_pixels<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=(I_file_done_valid && O_file_done_ready && !S_file_fire) ||
                (I_transform_done_valid && O_transform_done_ready && !S_transform_fire) ||
                (I_writer_done_valid && O_writer_done_ready && !S_writer_fire) ||
                (I_slot_result_valid && O_slot_result_ready && !S_slot_match);
            if (S_active) O_error<=S_next_error;
            if (S_file_fire) begin
                S_file_seen<=1; O_file_source_error<=I_file_error; O_parser_error<=I_parser_error;
                O_file_error<=I_fs_error; O_storage_error<=I_storage_error;
                O_path_warning<=I_path_warning; O_file_size<=O_file_size+I_file_size;
            end
            if (S_transform_fire) begin S_transform_seen<=1; O_transform_error<=I_transform_error; end
            if (S_writer_fire) begin
                S_writer_seen<=1; O_writer_error<=I_writer_error; O_memory_error<=I_memory_error;
                O_accepted_writes<=O_accepted_writes+I_accepted_writes; O_retired_writes<=O_retired_writes+I_retired_writes; O_pixels<=O_pixels+I_pixels;
            end
            // Once both source records exist, freeze their joint error before valid.
            if (S_work && (!S_file_seen || !S_transform_seen)) begin
                if ((S_file_fire && I_file_error!=0) || (S_transform_fire && I_transform_error!=0)) S_source_error<=1;
            end
            if (O_source_valid && I_source_ready) S_source_sent<=1;
            if (S_file_start) O_file_started<=1;
            if (S_transform_start) O_transform_started<=1;
            if (S_writer_start) O_writer_started<=1;
            case (S_state)
                IDLE:if (I_start_valid && O_start_ready) begin
                    O_context<=I_context; O_tag<=I_tag; O_generation<=I_generation; O_slot<=I_slot;
                    S_asset<=I_asset; S_layout<=I_layout; S_rotation<=I_rotation; O_lease_token<=0;
                    O_published<=0; O_file_started<=0; O_transform_started<=0; O_writer_started<=0;
                    S_file_seen<=0; S_transform_seen<=0; S_writer_seen<=0; S_source_sent<=0;
                    S_source_error<=0; S_finish_success<=0;
                    O_file_source_error<=0; O_parser_error<=0; O_storage_error<=0; O_file_error<=0;
                    O_transform_error<=0; O_writer_error<=0; O_memory_error<=0; O_path_warning<=0;
                    O_file_size<=0; O_accepted_writes<=0; O_retired_writes<=0; O_pixels<=0;
                    if (!I_media_valid || I_media_generation!=I_generation) begin O_error<=6; S_state<=RESULT; end
                    else if (I_abort) begin O_error<=7; S_state<=RESULT; end
                    else if (!I_config_valid || I_slot>=6 || I_layout>4) begin O_error<=1; S_state<=RESULT; end
                    else begin O_error<=0; S_state<=ALLOC_SEND; end
                end
                ALLOC_SEND:if (I_slot_cmd_ready) S_state<=ALLOC_WAIT;
                ALLOC_WAIT:if (S_slot_fire) begin
                    if (I_slot_result_error!=0) begin
                        if (S_next_error==0) O_error<=I_slot_result_error==4 ? 4'd6 : 4'd2;
                        S_state<=RESULT;
                    end else begin
                        O_slot_owned<=1; O_lease_token<=I_slot_result_token;
                        if (I_slot_result_token==0) begin
                            if (S_next_error==0) O_error<=8;
                            S_state<=RESULT; // Unknown lease cannot safely be FINISHed or reused.
                        end else S_state<=WORK;
                    end
                end
                WORK:begin
                    // Do not infer completion from the initial all-unstarted state.
                    if ((S_file_seen || S_next_error!=0) &&
                        (!O_file_started || S_file_seen) && (!O_transform_started || S_transform_seen) &&
                        (!O_writer_started || S_writer_seen) && !S_file_start && !S_transform_start && !S_writer_start) begin
                        if (S_next_error==0 && !(O_file_started && O_transform_started && O_writer_started)) O_error<=8;
                        if(S_next_error==0 && O_file_started && O_transform_started && O_writer_started && I_more_parts)
                            S_state<=NEXT_PART;
                        else S_state<=FINISH_PREP;
                    end
                end
                NEXT_PART:if(S_stop) S_state<=FINISH_PREP;
                    else if(I_part_valid && O_part_ready) begin
                        O_file_started<=0; O_transform_started<=0; O_writer_started<=0;
                        S_file_seen<=0; S_transform_seen<=0; S_writer_seen<=0;
                        S_source_sent<=0; S_source_error<=0; S_state<=WORK;
                    end
                FINISH_PREP:begin S_finish_success<=S_next_error==0; S_state<=FINISH_SEND; end
                FINISH_SEND:if (I_slot_cmd_ready) S_state<=FINISH_WAIT;
                FINISH_WAIT:if (S_slot_fire) begin
                    if (I_slot_result_error==0 || I_slot_result_error==4 || I_slot_result_error==6) begin
                        O_slot_owned<=0;
                        if (I_slot_result_error==0) begin
                            O_published<=1;
                            if (!S_finish_success && S_next_error==0) O_error<=8;
                        end else if (I_slot_result_error==4) O_error<=6;
                        else if (S_next_error==0) O_error<=8;
                    end else if (S_next_error!=6 && S_next_error!=7) O_error<=8;
                    S_state<=RESULT;
                end
                RESULT:if (I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
