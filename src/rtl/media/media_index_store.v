// Two-bank tentative media index with explicit commit and one retained read snapshot.
// All ports are in I_clk. Source retirement and validated paths belong to the caller.
module media_index_store (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_begin_valid,
    output wire O_begin_ready,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire I_abort,
    input wire I_item_valid,
    output wire O_item_ready,
    input wire [6:0] I_file_length,I_audio_length,
    input wire [5:0] I_title_length,
    input wire [9:0] I_duration,I_transition_ms,
    input wire [2:0] I_transition,
    input wire [6:0] I_policy,
    input wire I_string_valid,
    output wire O_string_ready,
    input wire [7:0] I_string_data,
    input wire I_string_last,I_finish_valid,
    output wire O_finish_ready,
    input wire [1:0] I_order,
    input wire [31:0] I_seed,
    input wire [1:0] I_base_order,
    input wire I_base_order_explicit,
    output reg [1:0] O_active_order,O_active_base_order,
    output reg O_active_base_order_explicit,
    input wire I_reorder_valid,
    output wire O_reorder_ready,
    input wire [1:0] I_reorder_order,
    input wire [31:0] I_reorder_seed,I_reorder_generation,
    input wire [15:0] I_reorder_tag,
    input wire [5:0] I_reorder_current_index,
    input wire I_reorder_abort,
    output wire O_reorder_done_valid,
    input wire I_reorder_done_ready,
    output wire [3:0] O_reorder_error,
    output wire [15:0] O_reorder_tag,
    output wire [31:0] O_reorder_generation,O_reorder_revision,
    output reg [5:0] O_reorder_current_index,
    input wire I_commit_valid,I_source_retired,
    output wire O_commit_ready,O_busy,
    output reg [6:0] O_staged_count,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,
    output wire O_active_valid,
    output reg [6:0] O_active_count,
    output reg [31:0] O_active_generation,O_active_revision,
    input wire I_acquire_valid,
    output wire O_acquire_ready,
    output reg O_snapshot_valid,
    output reg [6:0] O_snapshot_count,
    output reg [31:0] O_snapshot_generation,O_snapshot_revision,
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
    output reg [7:0] O_read_data,
    output reg [15:0] O_read_tag,
    output reg [3:0] O_read_error
);
    localparam [4:0] IDLE=0,APPEND=1,STRINGS=2,PAIR=3,META_A=4,
        META_A_WAIT=5,META_B=6,META_B_WAIT=7,CHAR_A=8,CHAR_A_WAIT=9,
        CHAR_B=10,CHAR_B_WAIT=11,SHUFFLE=12,PREPARED=13,RESULT=14,REORDER_INIT=15,REORDER_FIND=16,REORDER_COMMIT=17;
    localparam [1:0] READ_IDLE=0,READ_ISSUE=1,READ_CAPTURE=2,READ_RESULT=3;
    reg [4:0] S_state;
    reg [1:0] S_read_state;
    reg S_active_valid,S_active_bank,S_build_bank,S_snapshot_bank,S_snapshot_invalid;
    reg [5:0] S_permutation[0:191];
    reg [1:0] S_active_map,S_snapshot_map,S_build_map,S_order,S_base_order;
    reg S_reorder,S_base_explicit;
    reg [5:0] S_reorder_physical,S_reorder_cursor;
    reg [31:0] S_reorder_revision;
    reg [1:0] C_free_map;
    integer C_map;
    always @* begin
        C_free_map=0;
        for(C_map=2;C_map>=0;C_map=C_map-1)
            if((!S_active_valid || C_map!=S_active_map) &&
                (!O_snapshot_valid || C_map!=S_snapshot_map)) C_free_map=C_map;
    end
    assign O_reorder_ready=!I_reset && S_state==IDLE && !I_begin_valid;
    assign O_reorder_done_valid=!I_reset && S_state==RESULT && S_reorder;
    assign O_reorder_error=O_error;
    assign O_reorder_tag=O_tag;
    assign O_reorder_generation=O_generation;
    assign O_reorder_revision=S_reorder_revision;
    reg [6:0] S_file_length,S_audio_length;
    reg [1:0] S_string_kind;
    reg [6:0] S_string_address;
    reg [7:0] S_remaining;
    reg [5:0] S_pair,S_left,S_right,S_character,S_shuffle_index;
    reg [6:0] S_limit,S_left_length,S_right_length;
    reg [7:0] S_left_character;
    reg S_swapped;
    reg [31:0] S_random;
    reg [99:0] S_sort_meta_q,S_read_meta_q;
    reg [15:0] S_sort_file_q,S_read_file_q,S_read_audio_q,S_read_title_q;
    reg [5:0] S_read_physical;
    reg [1:0] S_read_kind;
    reg [6:0] S_read_address;
    reg [49:0] S_result_meta;
    wire S_media_matches=I_media_valid && I_media_generation==O_generation;
    wire S_snapshot_matches=!S_snapshot_invalid && I_media_valid && I_media_generation==O_snapshot_generation;
    wire S_target_bank=~S_active_bank;
    wire S_metadata_ok=I_file_length!=0 && I_file_length<=64 &&
        I_audio_length<=64 && I_title_length<=40 && I_transition<=7 && I_duration!=0 && I_duration<=600 &&
        (I_transition_ms==200 || I_transition_ms==400 || I_transition_ms==600 || I_transition_ms==1000);
    wire S_write_meta=I_item_valid && O_item_ready && S_metadata_ok && O_staged_count<64;
    wire S_frame_end=S_remaining==1;
    wire S_write_string=I_string_valid && O_string_ready && I_string_last==S_frame_end;
    wire [49:0] S_input_meta={I_policy,I_transition_ms,I_transition,I_duration,I_title_length,I_audio_length,I_file_length};
    wire S_sort_meta_read=S_state==META_A || S_state==META_B;
    wire S_sort_file_read=S_state==CHAR_A || S_state==CHAR_B;
    wire [5:0] S_sort_physical=S_state==META_A || S_state==CHAR_A ? S_left : S_right;
    wire [49:0] S_sort_meta=S_build_bank ? S_sort_meta_q[99:50] : S_sort_meta_q[49:0];
    wire [7:0] S_sort_file=S_build_bank ? S_sort_file_q[15:8] : S_sort_file_q[7:0];
    wire [49:0] S_read_meta=S_snapshot_bank ? S_read_meta_q[99:50] : S_read_meta_q[49:0];
    wire [7:0] S_read_file=S_snapshot_bank ? S_read_file_q[15:8] : S_read_file_q[7:0];
    wire [7:0] S_read_audio=S_snapshot_bank ? S_read_audio_q[15:8] : S_read_audio_q[7:0];
    wire [7:0] S_read_title=S_snapshot_bank ? S_read_title_q[15:8] : S_read_title_q[7:0];
    assign O_begin_ready=!I_reset && S_state==IDLE && !(O_snapshot_valid && S_snapshot_bank==S_target_bank);
    assign O_item_ready=!I_reset && S_state==APPEND && S_media_matches && !I_abort;
    assign O_string_ready=!I_reset && S_state==STRINGS && S_media_matches && !I_abort;
    assign O_finish_ready=!I_reset && S_state==APPEND && !I_item_valid && S_media_matches && !I_abort;
    assign O_commit_ready=!I_reset && S_state==PREPARED && !S_reorder && I_source_retired && S_media_matches && !I_abort;
    assign O_busy=S_state!=IDLE;
    assign O_done_valid=S_state==RESULT && !S_reorder;
    assign O_active_valid=S_active_valid && I_media_valid && I_media_generation==O_active_generation;
    assign O_acquire_ready=!I_reset && O_active_valid && !O_snapshot_valid;
    assign O_release_ready=!I_reset && O_snapshot_valid && S_read_state==READ_IDLE;
    assign O_read_ready=!I_reset && O_snapshot_valid && S_read_state==READ_IDLE && !I_release_valid;
    assign O_read_result_valid=S_read_state==READ_RESULT;
    assign O_read_file_length=S_result_meta[6:0];
    assign O_read_audio_length=S_result_meta[13:7];
    assign O_read_title_length=S_result_meta[19:14];
    assign O_read_duration=S_result_meta[29:20];
    assign O_read_transition=S_result_meta[32:30];
    assign O_read_transition_ms=S_result_meta[42:33];
    assign O_read_policy=S_result_meta[49:43];

    function [7:0] fold;
        input [7:0] value;
        begin fold=value>=8'h41 && value<=8'h5a ? value+8'd32 : value; end
    endfunction
    function [31:0] random_next;
        input [31:0] value;
        reg [31:0] temporary;
        begin
            temporary=value^(value<<13); temporary=temporary^(temporary>>17);
            random_next=temporary^(temporary<<5);
        end
    endfunction

    // Each physical bank has one build/sort port and one independent snapshot read port.
    // Arrays are not reset. Unwritten entries are excluded by committed lengths/counts.
    genvar bank;
    generate for(bank=0;bank<2;bank=bank+1) begin: g_bank
        reg [49:0] S_meta[0:63];
        reg [7:0] S_file[0:4095],S_audio[0:4095],S_title[0:2559];
        wire [11:0] S_write_path_address={O_staged_count[5:0],S_string_address[5:0]};
        wire [11:0] S_write_title_address={6'd0,O_staged_count[5:0]}*12'd40+{5'd0,S_string_address};
        wire [11:0] S_read_path_address={S_read_physical,S_read_address[5:0]};
        wire [11:0] S_read_title_address={6'd0,S_read_physical}*12'd40+{5'd0,S_read_address};
        always @(posedge I_clk) begin
            if(S_write_meta && S_build_bank==bank) S_meta[O_staged_count[5:0]]<=S_input_meta;
            else if(S_sort_meta_read && S_build_bank==bank)
                S_sort_meta_q[bank*50+:50]<=S_meta[S_sort_physical];
            if(S_write_string && S_build_bank==bank && S_string_kind==0)
                S_file[S_write_path_address]<=I_string_data;
            else if(S_sort_file_read && S_build_bank==bank)
                S_sort_file_q[bank*8+:8]<=S_file[{S_sort_physical,S_character}];
            if(S_write_string && S_build_bank==bank && S_string_kind==1)
                S_audio[S_write_path_address]<=I_string_data;
            if(S_write_string && S_build_bank==bank && S_string_kind==2)
                S_title[S_write_title_address]<=I_string_data;
            if(S_read_state==READ_ISSUE && S_snapshot_bank==bank) begin
                S_read_meta_q[bank*50+:50]<=S_meta[S_read_physical];
                S_read_file_q[bank*8+:8]<=S_file[S_read_path_address];
                S_read_audio_q[bank*8+:8]<=S_audio[S_read_path_address];
                // Guard title addressing even for an invalid/out-of-range string request.
                if(S_read_address<40) S_read_title_q[bank*8+:8]<=S_title[S_read_title_address];
                else S_read_title_q[bank*8+:8]<=0;
            end
        end
    end endgenerate

    task finish_pair;
        input exchange;
        begin
            if(exchange) begin
                S_permutation[{S_build_map,S_pair}]<=S_right;
                S_permutation[{S_build_map,S_pair}+7'd1]<=S_left;
            end
            if({1'b0,S_pair}+7'd1>=S_limit) begin
                if(S_limit<=1 || !(S_swapped || exchange)) S_state<=PREPARED;
                else begin S_limit<=S_limit-7'd1; S_pair<=0; S_swapped<=0; S_state<=PAIR; end
            end else begin S_pair<=S_pair+6'd1; S_swapped<=S_swapped || exchange; S_state<=PAIR; end
        end
    endtask

    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_active_valid<=0; S_active_bank<=1; S_build_bank<=0;
            S_active_map<=0; S_build_map<=0; S_order<=1; S_base_order<=1; S_base_explicit<=0;
            S_reorder<=0; S_reorder_physical<=0; S_reorder_cursor<=0; S_reorder_revision<=0;
            O_reorder_current_index<=0; O_active_order<=1; O_active_base_order<=1; O_active_base_order_explicit<=0;
            O_staged_count<=0; O_error<=0; O_tag<=0; O_generation<=0;
            O_active_count<=0; O_active_generation<=0; O_active_revision<=0;
            S_file_length<=0; S_audio_length<=0;
            S_string_kind<=0; S_string_address<=0; S_remaining<=0;
            S_pair<=0; S_left<=0; S_right<=0; S_character<=0; S_shuffle_index<=0;
            S_limit<=0; S_left_length<=0; S_right_length<=0; S_left_character<=0;
            S_swapped<=0; S_random<=1;
        end else begin
            if(!I_media_valid || I_media_generation!=O_active_generation) S_active_valid<=0;
            if(S_state!=IDLE && S_state!=RESULT && (!S_media_matches || (S_reorder ? I_reorder_abort : I_abort))) begin
                O_error<=!S_media_matches ? 4'd3 : 4'd2; S_state<=RESULT;
            end else case(S_state)
                IDLE:if(I_begin_valid && O_begin_ready) begin
                    O_tag<=I_tag; O_generation<=I_generation; O_staged_count<=0; O_error<=0;
                    S_build_bank<=S_target_bank; S_build_map<=C_free_map; S_reorder<=0;
                    if(!I_media_valid || I_generation!=I_media_generation || I_abort) begin
                        O_error<=!I_media_valid || I_generation!=I_media_generation ? 4'd3 : 4'd2;
                        S_state<=RESULT;
                    end else S_state<=APPEND;
                end else if(I_reorder_valid && O_reorder_ready) begin
                    S_reorder<=1; O_tag<=I_reorder_tag; O_generation<=I_reorder_generation;
                    S_build_bank<=S_active_bank; S_build_map<=C_free_map;
                    O_staged_count<=O_active_count; O_error<=0;
                    S_order<=I_reorder_order; S_base_order<=O_active_base_order;
                    S_base_explicit<=O_active_base_order_explicit;
                    S_random<=I_reorder_seed==0 ? 32'd1 : I_reorder_seed;
                    S_reorder_revision<=O_active_revision; O_reorder_current_index<=I_reorder_current_index;
                    S_reorder_cursor<=0;
                    S_reorder_physical<=S_permutation[{S_active_map,I_reorder_current_index}];
                    if(!O_active_valid || I_reorder_generation!=O_active_generation) begin O_error<=3; S_state<=RESULT; end
                    else if(I_reorder_abort) begin O_error<=2; S_state<=RESULT; end
                    else if(I_reorder_order>=3 || {1'b0,I_reorder_current_index}>=O_active_count ||
                        O_active_count==0 || &O_active_revision) begin O_error<=4; S_state<=RESULT; end
                    else S_state<=REORDER_INIT;
                end
                REORDER_INIT:begin
                    S_permutation[{S_build_map,S_reorder_cursor}]<=S_reorder_cursor;
                    if({1'b0,S_reorder_cursor}+7'd1>=O_staged_count) begin
                        S_pair<=0; S_limit<=O_staged_count-1'b1; S_swapped<=0;
                        S_shuffle_index<=O_staged_count[5:0]-1'b1;
                        if(O_staged_count<2 || S_order==1) S_state<=PREPARED;
                        else S_state<=S_order==0 ? PAIR : SHUFFLE;
                    end else S_reorder_cursor<=S_reorder_cursor+1'b1;
                end
                APPEND:if(I_item_valid && O_item_ready) begin
                    if(O_staged_count==64) begin O_error<=6; S_state<=RESULT; end
                    else if(!S_metadata_ok) begin O_error<=4; S_state<=RESULT; end
                    else begin
                        S_permutation[{S_build_map,O_staged_count[5:0]}]<=O_staged_count[5:0];
                        S_file_length<=I_file_length; S_audio_length<=I_audio_length;
                        S_remaining<={1'b0,I_file_length}+{1'b0,I_audio_length}+{2'd0,I_title_length};
                        S_string_kind<=0; S_string_address<=0; S_state<=STRINGS;
                    end
                end else if(I_finish_valid && O_finish_ready) begin
                    S_order<=I_order; S_base_order<=I_base_order; S_base_explicit<=I_base_order_explicit;
                    S_pair<=0; S_limit<=O_staged_count-7'd1; S_swapped<=0;
                    S_shuffle_index<=O_staged_count[5:0]-6'd1; S_random<=I_seed==0 ? 32'd1 : I_seed;
                    if(I_order==3) begin O_error<=4; S_state<=RESULT; end
                    else if(O_staged_count<2 || I_order==1) S_state<=PREPARED;
                    else if(I_order==0) S_state<=PAIR;
                    else S_state<=SHUFFLE;
                end
                STRINGS:if(I_string_valid && O_string_ready) begin
                    if(I_string_last!=S_frame_end) begin O_error<=5; S_state<=RESULT; end
                    else if(S_frame_end) begin O_staged_count<=O_staged_count+7'd1; S_state<=APPEND; end
                    else begin
                        S_remaining<=S_remaining-8'd1;
                        if(S_string_kind==0 && S_string_address+7'd1==S_file_length) begin
                            S_string_kind<=S_audio_length!=0 ? 2'd1 : 2'd2; S_string_address<=0;
                        end else if(S_string_kind==1 && S_string_address+7'd1==S_audio_length) begin
                            S_string_kind<=2; S_string_address<=0;
                        end else S_string_address<=S_string_address+7'd1;
                    end
                end
                PAIR:begin
                    S_left<=S_permutation[{S_build_map,S_pair}];
                    S_right<=S_permutation[{S_build_map,S_pair}+7'd1]; S_state<=META_A;
                end
                META_A:S_state<=META_A_WAIT;
                META_A_WAIT:begin S_left_length<=S_sort_meta[6:0]; S_state<=META_B; end
                META_B:S_state<=META_B_WAIT;
                META_B_WAIT:begin S_right_length<=S_sort_meta[6:0]; S_character<=0; S_state<=CHAR_A; end
                CHAR_A:S_state<=CHAR_A_WAIT;
                CHAR_A_WAIT:begin S_left_character<=fold(S_sort_file); S_state<=CHAR_B; end
                CHAR_B:S_state<=CHAR_B_WAIT;
                CHAR_B_WAIT:begin
                    if(S_left_character>fold(S_sort_file)) finish_pair(1'b1);
                    else if(S_left_character<fold(S_sort_file)) finish_pair(1'b0);
                    else if({1'b0,S_character}+7'd1>=S_left_length ||
                            {1'b0,S_character}+7'd1>=S_right_length)
                        finish_pair(S_left_length>S_right_length);
                    else begin S_character<=S_character+6'd1; S_state<=CHAR_A; end
                end
                SHUFFLE:begin
                    S_random<=random_next(S_random);
                    if(S_random[5:0]<=S_shuffle_index) begin
                        S_permutation[{S_build_map,S_shuffle_index}]<=S_permutation[{S_build_map,S_random[5:0]}];
                        S_permutation[{S_build_map,S_random[5:0]}]<=S_permutation[{S_build_map,S_shuffle_index}];
                        if(S_shuffle_index==1) S_state<=PREPARED;
                        else S_shuffle_index<=S_shuffle_index-6'd1;
                    end
                end
                PREPARED:if(S_reorder) begin S_reorder_cursor<=0; S_state<=REORDER_FIND; end
                else if(I_commit_valid && O_commit_ready) begin
                    S_active_valid<=1; S_active_bank<=S_build_bank; S_active_map<=S_build_map;
                    O_active_order<=S_order; O_active_base_order<=S_base_order;
                    O_active_base_order_explicit<=S_base_explicit; O_active_count<=O_staged_count;
                    O_active_generation<=O_generation; O_active_revision<=O_active_revision+32'd1;
                    O_error<=0; S_state<=RESULT;
                end
                REORDER_FIND:if(S_permutation[{S_build_map,S_reorder_cursor}]==S_reorder_physical) begin
                    O_reorder_current_index<=S_reorder_cursor; S_state<=REORDER_COMMIT;
                end else if({1'b0,S_reorder_cursor}+7'd1>=O_staged_count) begin O_error<=4; S_state<=RESULT; end
                else S_reorder_cursor<=S_reorder_cursor+1'b1;
                REORDER_COMMIT:begin
                    S_active_map<=S_build_map; O_active_revision<=O_active_revision+32'd1;
                    S_reorder_revision<=O_active_revision+32'd1; O_active_order<=S_order;
                    O_error<=0; S_state<=RESULT;
                end
                RESULT:if(S_reorder ? I_reorder_done_ready : I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end

    always @(posedge I_clk) begin
        if(I_reset) begin
            S_read_state<=READ_IDLE; O_snapshot_valid<=0; S_snapshot_bank<=0; S_snapshot_map<=0; S_snapshot_invalid<=0;
            O_snapshot_count<=0; O_snapshot_generation<=0; O_snapshot_revision<=0;
            S_read_physical<=0; S_read_kind<=0; S_read_address<=0;
            S_result_meta<=0; O_read_data<=0; O_read_error<=0; O_read_tag<=0;
        end else begin
            if(I_acquire_valid && O_acquire_ready) begin
                O_snapshot_valid<=1; S_snapshot_bank<=S_active_bank; S_snapshot_map<=S_active_map; O_snapshot_count<=O_active_count;
                O_snapshot_generation<=O_active_generation; O_snapshot_revision<=O_active_revision;
                S_snapshot_invalid<=0;
            end else if(I_release_valid && O_release_ready) O_snapshot_valid<=0;
            // A short media-ready loss must not resurrect a held snapshot on recovery.
            if(O_snapshot_valid && (!I_media_valid || I_media_generation!=O_snapshot_generation))
                S_snapshot_invalid<=1;
            case(S_read_state)
                READ_IDLE:if(I_read_valid && O_read_ready) begin
                    O_read_tag<=I_read_tag;
                    S_read_kind<=I_read_kind; S_read_address<=I_read_address;
                    S_result_meta<=0; O_read_data<=0; O_read_error<=0;
                    if(!S_snapshot_matches || {1'b0,I_read_index}>=O_snapshot_count || I_read_kind==3) begin
                        O_read_error<=!S_snapshot_matches ? 4'd3 : 4'd7; S_read_state<=READ_RESULT;
                    end else begin
                        S_read_physical<=S_permutation[{S_snapshot_map,I_read_index}]; S_read_state<=READ_ISSUE;
                    end
                end
                READ_ISSUE:S_read_state<=READ_CAPTURE;
                READ_CAPTURE:begin
                    if(!S_snapshot_matches) begin S_result_meta<=0; O_read_data<=0; O_read_error<=3; end
                    else begin
                        S_result_meta<=S_read_meta;
                        case(S_read_kind)
                            0:O_read_data<=S_read_address<S_read_meta[6:0] ? S_read_file : 8'd0;
                            1:O_read_data<=S_read_address<S_read_meta[13:7] ? S_read_audio : 8'd0;
                            2:O_read_data<=S_read_address<S_read_meta[19:14] ? S_read_title : 8'd0;
                            default:O_read_data<=0;
                        endcase
                    end
                    S_read_state<=READ_RESULT;
                end
                READ_RESULT:if(I_read_result_ready) S_read_state<=READ_IDLE;
                default:S_read_state<=READ_IDLE;
            endcase
        end
    end
endmodule
