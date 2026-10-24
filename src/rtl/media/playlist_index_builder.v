// Playlist stream to retained index. Source retirement must come from real I/O ownership.
module playlist_index_builder (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_file_size,I_generation,I_seed,
    input wire I_order_override,
    input wire [1:0] I_runtime_order,
    input wire [15:0] I_tag,
    input wire I_abort,I_stream_error,I_byte_valid,
    output wire O_byte_ready,
    input wire [7:0] I_byte_data,
    input wire I_byte_last,
    input wire [15:0] I_byte_tag,
    input wire [31:0] I_byte_generation,
    input wire I_retire_valid,
    output wire O_retire_ready,
    input wire [15:0] I_retire_tag,
    input wire [31:0] I_retire_generation,
    input wire [7:0] I_retire_error,
    output wire O_source_cancel,
    output wire [15:0] O_source_tag,
    output wire [31:0] O_source_generation,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [7:0] O_warning,
    output reg [6:0] O_count,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,
    output wire O_committed,O_fallback_required,
    output wire O_active_valid,
    output wire [6:0] O_active_count,
    output wire [31:0] O_active_generation,O_active_revision,
    input wire I_acquire_valid,
    output wire O_acquire_ready,
    output wire O_snapshot_valid,
    output wire [6:0] O_snapshot_count,
    output wire [31:0] O_snapshot_generation,O_snapshot_revision,
    input wire I_release_valid,
    output wire O_release_ready,
    input wire I_read_valid,
    output wire O_read_ready,
    input wire [5:0] I_read_index,
    input wire [1:0] I_read_kind,
    input wire [6:0] I_read_address,
    input wire [15:0] I_read_tag,
    output wire O_read_result_valid,
    input wire I_read_result_ready,
    output wire [6:0] O_read_file_length,O_read_audio_length,
    output wire [5:0] O_read_title_length,
    output wire [9:0] O_read_duration,O_read_transition_ms,
    output wire [2:0] O_read_transition,
    output wire [6:0] O_read_policy,
    output wire [7:0] O_read_data,
    output wire [15:0] O_read_tag,
    output wire [3:0] O_read_error,
    input wire I_directory_mode,I_directory_lease_grant,
    input wire [31:0] I_directory_sector_budget,
    input wire [9:0] I_directory_duration,I_directory_transition_ms,
    input wire [2:0] I_directory_transition,
    input wire [1:0] I_directory_order,
    output wire O_directory_lease_request,O_directory_lease_active,
    output wire [7:0] O_directory_error,O_directory_primary_error,
    output wire [3:0] O_directory_storage_error,
    output wire [2:0] O_directory_warning,
    output wire [32:0] O_directory_sectors,
    output wire  O_enum_valid,
    input wire  I_enum_ready,
    output wire [15:0] O_enum_tag,
    output wire [6:0] O_enum_path_length,
    output wire [31:0] O_enum_sector_budget,
    output wire  O_enum_path_valid,
    input wire  I_enum_path_ready,
    output wire [7:0] O_enum_path_data,
    output wire  O_enum_path_last,
    output wire  O_enum_stop,
    output wire  O_enum_cancel,
    input wire  I_enum_entry_valid,
    output wire  O_enum_entry_ready,
    input wire [7:0] I_enum_attr,
    input wire [31:0] I_enum_size,
    input wire [31:0] I_enum_first_cluster,
    input wire [6:0] I_enum_name_length,
    input wire  I_enum_name_valid,
    output wire  O_enum_name_ready,
    input wire [7:0] I_enum_name_data,
    input wire  I_enum_name_last,
    input wire  I_enum_done_valid,
    output wire  O_enum_done_ready,
    input wire [15:0] I_enum_tag,
    input wire [31:0] I_enum_generation,
    input wire [31:0] I_enum_sectors,
    input wire [7:0] I_enum_error,
    input wire [3:0] I_enum_storage_error,
    input wire [2:0] I_enum_warning,
    output wire [1:0] O_active_order,
    output wire [1:0] O_active_base_order,
    output wire O_active_base_order_explicit,
    input wire I_reorder_valid,
    output wire O_reorder_ready,
    input wire [1:0] I_reorder_order,
    input wire [31:0] I_reorder_seed,
    input wire [31:0] I_reorder_generation,
    input wire [15:0] I_reorder_tag,
    input wire [5:0] I_reorder_current_index,
    input wire I_reorder_abort,
    output wire O_reorder_done_valid,
    input wire I_reorder_done_ready,
    output wire [3:0] O_reorder_error,
    output wire [15:0] O_reorder_tag,
    output wire [31:0] O_reorder_generation,
    output wire [31:0] O_reorder_revision,
    output wire [5:0] O_reorder_current_index
);

    localparam [3:0] IDLE=0,RUN=1,ITEM=2,READ_ADDRESS=3,READ_CAPTURE=4,
        SEND=5,ACK=6,FINISH=7,COMMIT=8,DRAIN=9,RESULT=10,DIRECTORY=11;
    reg [3:0] S_state;
    reg [31:0] S_size,S_seed;
    reg [32:0] S_delivered;
    reg S_retired,S_parser_done,S_store_done,S_committed;
    reg [1:0] S_kind,S_order,S_runtime_order,S_file_order,S_directory_base_order;
    reg S_order_override,S_file_order_explicit;
    wire S_parser_order_explicit;
    reg [6:0] S_address;
    reg [7:0] S_remaining,S_byte;
    wire S_parser_ready,S_parser_byte_ready,S_parser_item,S_parser_done_valid;
    wire [3:0] S_parser_error;
    wire [7:0] S_parser_warning,S_parser_data;
    wire [6:0] S_parser_count,S_file_length,S_audio_length;
    wire [5:0] S_title_length;
    wire [9:0] S_duration,S_ms;
    wire [2:0] S_transition;
    wire [6:0] S_policy;
    wire [1:0] S_parser_order;
    wire S_store_ready,S_store_item_ready,S_store_string_ready,S_store_finish_ready,S_store_commit_ready,S_store_done_valid;
    wire [3:0] S_store_error;
    wire [6:0] S_staged_count;
    wire S_active=S_state!=IDLE && S_state!=RESULT && S_state!=DIRECTORY;
    wire S_start=I_start_valid && O_start_ready;
    wire S_byte_matches=I_byte_tag==O_tag && I_byte_generation==O_generation;
    wire S_retire_matches=I_retire_tag==O_tag && I_retire_generation==O_generation;
    wire S_retire_accept=I_retire_valid && O_retire_ready && S_retire_matches;
    wire S_byte_accept=I_byte_valid && O_byte_ready && S_byte_matches && !S_retired;
    wire [33:0] S_delivered_now={1'b0,S_delivered}+(S_byte_accept ? 34'd1 : 34'd0);
    wire S_retire_bad=S_retire_accept && (I_retire_error!=0 || S_delivered_now!={2'd0,S_size});
    wire S_media_matches=I_media_valid && I_media_generation==O_generation;
    wire [3:0] S_current_error=!S_media_matches ? 4'd3 : I_abort ? 4'd2 :
        (I_stream_error || S_retire_bad) ? 4'd1 :
        (O_error==0 && S_parser_done_valid && S_parser_error!=0) ? 4'd1 :
        (O_error==0 && S_store_done_valid && S_store_error!=0) ? 4'd4 :
        (O_error==0 && S_parser_done_valid && S_parser_error==0 && S_parser_count==0) ? 4'd5 : 4'd0;
    wire [3:0] S_effective_error=S_committed ? 4'd0 : prefer_error(O_error,S_current_error);
    wire S_stop=S_active && S_effective_error!=0;
    wire S_parser_byte_valid=S_active && !S_parser_done && !S_stop && !S_retired && S_byte_matches && I_byte_valid;
    wire S_parser_item_ready=S_state==ACK && !S_stop;
    wire S_store_item_valid=S_state==ITEM && !S_stop;
    wire S_store_string_valid=S_state==SEND && !S_stop;
    wire S_store_finish_valid=S_state==FINISH && !S_stop;
    wire S_store_commit_valid=S_state==COMMIT && S_retired && !S_stop && !S_committed;
    assign O_start_ready=!I_reset && S_state==IDLE &&
        (I_directory_mode ? S_directory_ready : (S_parser_ready && S_store_ready));
    // Do not feed a retirement verdict back into readiness: retirement checks this
    // edge's byte handshake. Registered failure / independent stop causes can drain.
    assign O_byte_ready=!I_reset && S_active && (!S_byte_matches || O_error!=0 || !S_media_matches ||
        I_abort || I_stream_error || S_parser_done || S_retired || S_parser_byte_ready);
    assign O_retire_ready=!I_reset && S_active && !S_retired;
    assign O_source_cancel=S_active && !S_retired && S_stop;
    assign O_source_tag=O_tag;
    assign O_source_generation=O_generation;
    assign O_busy=S_state!=IDLE;
    assign O_done_valid=S_state==RESULT;
    assign O_committed=S_committed;
    assign O_fallback_required=O_error==5;

    function [2:0] error_rank;
        input [3:0] value;
        begin case(value) 3:error_rank=5; 2:error_rank=4; 1:error_rank=3; 4:error_rank=2; 5:error_rank=1; default:error_rank=0; endcase end
    endfunction
    function [3:0] prefer_error;
        input [3:0] old_error,new_error;
        begin prefer_error=error_rank(new_error)>error_rank(old_error) ? new_error : old_error; end
    endfunction

    wire S_directory_ready,S_directory_done,S_directory_committed;
    wire [3:0] S_directory_error;
    wire [6:0] S_directory_count;
    wire [7:0] S_directory_warnings;
    wire S_directory_selected=S_state==DIRECTORY || (S_state==IDLE && I_directory_mode);
    wire  S_directory_begin_valid;
    wire  S_directory_abort;
    wire  S_directory_item_valid;
    wire [6:0] S_directory_file_length;
    wire [6:0] S_directory_audio_length;
    wire [5:0] S_directory_title_length;
    wire [9:0] S_directory_duration;
    wire [9:0] S_directory_transition_ms;
    wire [2:0] S_directory_transition;
    wire  S_directory_string_valid;
    wire [7:0] S_directory_string_data;
    wire  S_directory_string_last;
    wire  S_directory_finish_valid;
    wire [1:0] S_directory_order;
    wire [31:0] S_directory_seed;
    wire  S_directory_commit_valid;
    wire  S_directory_source_retired;
    wire  S_directory_done_ready;

    playlist_parser u_parser (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_start && !I_directory_mode),.O_start_ready(S_parser_ready),
        .I_file_size(I_file_size),.I_tag(I_tag),.I_generation(I_generation),
        .I_byte_valid(S_parser_byte_valid),.O_byte_ready(S_parser_byte_ready),.I_byte_data(I_byte_data),.I_byte_last(I_byte_last),
        .I_abort(S_stop),.I_stream_error(1'b0),.O_busy(),.O_item_valid(S_parser_item),.I_item_ready(S_parser_item_ready),
        .O_item_index(),.O_policy(S_policy),.O_duration(S_duration),.O_transition_ms(S_ms),.O_transition(S_transition),
        .O_file_length(S_file_length),.O_audio_length(S_audio_length),.O_title_length(S_title_length),
        .I_string_kind(S_kind),.I_string_address(S_address),.O_string_data(S_parser_data),
        .O_done_valid(S_parser_done_valid),.I_done_ready(S_active && !S_parser_done),.O_error(S_parser_error),
        .O_warning(S_parser_warning),.O_item_count(S_parser_count),.O_order(S_parser_order),.O_order_explicit(S_parser_order_explicit),.O_tag(),.O_generation());
    directory_index_source u_directory (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_start_valid(I_start_valid && S_state==IDLE && I_directory_mode),
        .O_start_ready(S_directory_ready),
        .O_lease_request(O_directory_lease_request),
        .O_lease_active(O_directory_lease_active),
        .I_lease_grant(I_directory_lease_grant),
        .I_abort(I_abort),
        .I_tag(I_tag),
        .I_generation(I_generation),
        .I_seed(I_seed),
        .I_sector_budget(I_directory_sector_budget),
        .I_duration(I_directory_duration),
        .I_transition_ms(I_directory_transition_ms),
        .I_transition(I_directory_transition),
        .I_order(I_order_override ? I_runtime_order : I_directory_order),
        .O_done_valid(S_directory_done),
        .I_done_ready(S_state==DIRECTORY),
        .O_error(S_directory_error),
        .O_count(S_directory_count),
        .O_warning(S_directory_warnings),
        .O_directory_error(O_directory_error),
        .O_primary_error(O_directory_primary_error),
        .O_storage_error(O_directory_storage_error),
        .O_directory_warning(O_directory_warning),
        .O_sectors(O_directory_sectors),
        .O_tag(),
        .O_generation(),
        .O_committed(S_directory_committed),
        .O_enum_valid(O_enum_valid),
        .I_enum_ready(I_enum_ready),
        .O_enum_tag(O_enum_tag),
        .O_enum_path_length(O_enum_path_length),
        .O_enum_sector_budget(O_enum_sector_budget),
        .O_enum_path_valid(O_enum_path_valid),
        .I_enum_path_ready(I_enum_path_ready),
        .O_enum_path_data(O_enum_path_data),
        .O_enum_path_last(O_enum_path_last),
        .O_enum_stop(O_enum_stop),
        .O_enum_cancel(O_enum_cancel),
        .I_enum_entry_valid(I_enum_entry_valid),
        .O_enum_entry_ready(O_enum_entry_ready),
        .I_enum_attr(I_enum_attr),
        .I_enum_size(I_enum_size),
        .I_enum_first_cluster(I_enum_first_cluster),
        .I_enum_name_length(I_enum_name_length),
        .I_enum_name_valid(I_enum_name_valid),
        .O_enum_name_ready(O_enum_name_ready),
        .I_enum_name_data(I_enum_name_data),
        .I_enum_name_last(I_enum_name_last),
        .I_enum_done_valid(I_enum_done_valid),
        .O_enum_done_ready(O_enum_done_ready),
        .I_enum_tag(I_enum_tag),
        .I_enum_generation(I_enum_generation),
        .I_enum_sectors(I_enum_sectors),
        .I_enum_error(I_enum_error),
        .I_enum_storage_error(I_enum_storage_error),
        .I_enum_warning(I_enum_warning),
        .O_store_begin_valid(S_directory_begin_valid),
        .I_store_begin_ready(S_store_ready),
        .O_store_abort(S_directory_abort),
        .O_store_item_valid(S_directory_item_valid),
        .I_store_item_ready(S_store_item_ready),
        .O_store_file_length(S_directory_file_length),
        .O_store_audio_length(S_directory_audio_length),
        .O_store_title_length(S_directory_title_length),
        .O_store_duration(S_directory_duration),
        .O_store_transition_ms(S_directory_transition_ms),
        .O_store_transition(S_directory_transition),
        .O_store_string_valid(S_directory_string_valid),
        .I_store_string_ready(S_store_string_ready),
        .O_store_string_data(S_directory_string_data),
        .O_store_string_last(S_directory_string_last),
        .O_store_finish_valid(S_directory_finish_valid),
        .I_store_finish_ready(S_store_finish_ready),
        .O_store_order(S_directory_order),
        .O_store_seed(S_directory_seed),
        .O_store_commit_valid(S_directory_commit_valid),
        .O_store_source_retired(S_directory_source_retired),
        .I_store_commit_ready(S_store_commit_ready),
        .I_store_done_valid(S_store_done_valid),
        .O_store_done_ready(S_directory_done_ready),
        .I_store_error(S_store_error)
    );

    media_index_store u_store (
        .I_clk(I_clk),
        .I_reset(I_reset),
        .I_media_valid(I_media_valid),
        .I_media_generation(I_media_generation),
        .I_begin_valid(S_directory_selected ? S_directory_begin_valid : (S_start)),
        .O_begin_ready(S_store_ready),
        .I_tag(I_tag),
        .I_generation(I_generation),
        .I_abort(S_directory_selected ? S_directory_abort : (S_stop)),
        .I_item_valid(S_directory_selected ? S_directory_item_valid : (S_store_item_valid)),
        .O_item_ready(S_store_item_ready),
        .I_file_length(S_directory_selected ? S_directory_file_length : (S_file_length)),
        .I_audio_length(S_directory_selected ? S_directory_audio_length : (S_audio_length)),
        .I_title_length(S_directory_selected ? S_directory_title_length : (S_title_length)),
        .I_duration(S_directory_selected ? S_directory_duration : (S_duration)),
        .I_transition_ms(S_directory_selected ? S_directory_transition_ms : (S_ms)),
        .I_transition(S_directory_selected ? S_directory_transition : (S_transition)),
        .I_policy(S_directory_selected ? 7'd0 : S_policy),
        .I_string_valid(S_directory_selected ? S_directory_string_valid : (S_store_string_valid)),
        .O_string_ready(S_store_string_ready),
        .I_string_data(S_directory_selected ? S_directory_string_data : (S_byte)),
        .I_string_last(S_directory_selected ? S_directory_string_last : (S_remaining==8'd1)),
        .I_finish_valid(S_directory_selected ? S_directory_finish_valid : (S_store_finish_valid)),
        .O_finish_ready(S_store_finish_ready),
        .I_order(S_directory_selected ? S_directory_order : (S_order)),
        .I_base_order(S_directory_selected ? S_directory_base_order : S_file_order),
        .I_base_order_explicit(!S_directory_selected && S_file_order_explicit),
        .I_seed(S_directory_selected ? S_directory_seed : (S_seed)),
        .I_commit_valid(S_directory_selected ? S_directory_commit_valid : (S_store_commit_valid)),
        .I_source_retired(S_directory_selected ? S_directory_source_retired : (S_retired)),
        .O_commit_ready(S_store_commit_ready),
        .O_busy(),
        .O_staged_count(S_staged_count),
        .O_done_valid(S_store_done_valid),
        .I_done_ready(S_directory_selected ? S_directory_done_ready : (S_active && !S_store_done)),
        .O_error(S_store_error),
        .O_tag(),
        .O_generation(),
        .O_active_valid(O_active_valid),
        .O_active_count(O_active_count),
        .O_active_generation(O_active_generation),
        .O_active_revision(O_active_revision),
        .I_acquire_valid(I_acquire_valid),
        .O_acquire_ready(O_acquire_ready),
        .O_snapshot_valid(O_snapshot_valid),
        .O_snapshot_count(O_snapshot_count),
        .O_snapshot_generation(O_snapshot_generation),
        .O_snapshot_revision(O_snapshot_revision),
        .I_release_valid(I_release_valid),
        .O_release_ready(O_release_ready),
        .I_read_valid(I_read_valid),
        .O_read_ready(O_read_ready),
        .I_read_index(I_read_index),
        .I_read_kind(I_read_kind),
        .I_read_address(I_read_address),
        .I_read_tag(I_read_tag),
        .O_read_result_valid(O_read_result_valid),
        .I_read_result_ready(I_read_result_ready),
        .O_read_file_length(O_read_file_length),
        .O_read_audio_length(O_read_audio_length),
        .O_read_title_length(O_read_title_length),
        .O_read_duration(O_read_duration),
        .O_read_transition_ms(O_read_transition_ms),
        .O_read_transition(O_read_transition),
        .O_read_policy(O_read_policy),
        .O_read_data(O_read_data),
        .O_read_tag(O_read_tag),
        .O_read_error(O_read_error),
        .O_active_order(O_active_order),
        .O_active_base_order(O_active_base_order),
        .O_active_base_order_explicit(O_active_base_order_explicit),
        .I_reorder_valid(I_reorder_valid),
        .O_reorder_ready(O_reorder_ready),
        .I_reorder_order(I_reorder_order),
        .I_reorder_seed(I_reorder_seed),
        .I_reorder_generation(I_reorder_generation),
        .I_reorder_tag(I_reorder_tag),
        .I_reorder_current_index(I_reorder_current_index),
        .I_reorder_abort(I_reorder_abort),
        .O_reorder_done_valid(O_reorder_done_valid),
        .I_reorder_done_ready(I_reorder_done_ready),
        .O_reorder_error(O_reorder_error),
        .O_reorder_tag(O_reorder_tag),
        .O_reorder_generation(O_reorder_generation),
        .O_reorder_revision(O_reorder_revision),
        .O_reorder_current_index(O_reorder_current_index)
    );

    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_size<=0; S_seed<=0; S_delivered<=0;
            S_retired<=0; S_parser_done<=0; S_store_done<=0; S_committed<=0;
            S_kind<=0; S_order<=1; S_runtime_order<=1; S_order_override<=0; S_file_order<=1; S_file_order_explicit<=0;
            S_directory_base_order<=0; S_address<=0; S_remaining<=0; S_byte<=0;
            O_error<=0; O_warning<=0; O_count<=0; O_tag<=0; O_generation<=0;
        end else begin
            if(S_active) begin
                if(!S_committed) O_error<=S_effective_error;
                if(S_byte_accept && !(&S_delivered)) S_delivered<=S_delivered+33'd1;
                if(S_retire_accept) S_retired<=1;
                if(S_parser_done_valid && !S_parser_done) begin
                    S_parser_done<=1; O_warning<=S_parser_warning; S_order<=S_order_override ? S_runtime_order : S_parser_order;
                    S_file_order<=S_parser_order; S_file_order_explicit<=S_parser_order_explicit;
                end
                if(S_store_done_valid && !S_store_done) S_store_done<=1;
            end
            if(S_stop && S_state!=DRAIN) S_state<=DRAIN;
            else case(S_state)
                IDLE:if(S_start) begin
                    S_size<=I_file_size; S_seed<=I_seed; S_runtime_order<=I_runtime_order; S_order_override<=I_order_override;
                    S_directory_base_order<=I_directory_order; S_delivered<=0;
                    S_retired<=0; S_parser_done<=0; S_store_done<=0; S_committed<=0;
                    O_tag<=I_tag; O_generation<=I_generation; O_warning<=0; O_count<=0;
                    O_error<=!I_media_valid || I_media_generation!=I_generation ? 4'd3 :
                        I_abort ? 4'd2 : I_stream_error ? 4'd1 : 4'd0;
                    S_state<=I_directory_mode ? DIRECTORY : RUN;
                end
                DIRECTORY:if(S_directory_done) begin
                    O_error<=S_directory_error; O_warning<=S_directory_warnings; O_count<=S_directory_count;
                    S_committed<=S_directory_committed; S_state<=RESULT;
                end
                RUN:if(S_parser_item) S_state<=ITEM;
                    else if(S_parser_done) S_state<=FINISH;
                ITEM:if(S_store_item_ready) begin
                    S_kind<=0; S_address<=0;
                    S_remaining<={1'b0,S_file_length}+{1'b0,S_audio_length}+{2'd0,S_title_length};
                    S_state<=READ_ADDRESS;
                end
                READ_ADDRESS:S_state<=READ_CAPTURE;
                READ_CAPTURE:begin S_byte<=S_parser_data; S_state<=SEND; end
                SEND:if(S_store_string_ready) begin
                    if(S_remaining==1) S_state<=ACK;
                    else begin
                        S_remaining<=S_remaining-8'd1;
                        if(S_kind==0 && S_address+7'd1==S_file_length) begin
                            S_kind<=S_audio_length!=0 ? 2'd1 : 2'd2; S_address<=0;
                        end else if(S_kind==1 && S_address+7'd1==S_audio_length) begin S_kind<=2; S_address<=0; end
                        else S_address<=S_address+7'd1;
                        S_state<=READ_ADDRESS;
                    end
                end
                ACK:S_state<=RUN;
                FINISH:if(S_store_finish_ready) S_state<=COMMIT;
                COMMIT:if(S_store_commit_valid && S_store_commit_ready) begin
                    S_committed<=1; O_error<=0; S_state<=DRAIN;
                end
                DRAIN:if(S_parser_done && S_store_done && S_retired) begin O_count<=S_staged_count; S_state<=RESULT; end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
