// Directory candidates -> one externally owned index store. All ports are host-domain.
// A namespace/store lease is explicit; accepted enum requests retire through enum_done.
module directory_index_source (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,O_lease_request,O_lease_active,
    input wire I_lease_grant,I_abort,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,I_seed,I_sector_budget,
    input wire [9:0] I_duration,I_transition_ms,
    input wire [2:0] I_transition,
    input wire [1:0] I_order,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [6:0] O_count,
    output reg [7:0] O_warning,O_directory_error,O_primary_error,
    output reg [3:0] O_storage_error,
    output reg [2:0] O_directory_warning,
    output reg [32:0] O_sectors,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,
    output reg O_committed,

    output wire O_enum_valid,
    input wire I_enum_ready,
    output wire [15:0] O_enum_tag,
    output wire [6:0] O_enum_path_length,
    output wire [31:0] O_enum_sector_budget,
    output wire O_enum_path_valid,
    input wire I_enum_path_ready,
    output wire [7:0] O_enum_path_data,
    output wire O_enum_path_last,O_enum_stop,O_enum_cancel,
    input wire I_enum_entry_valid,
    output wire O_enum_entry_ready,
    input wire [7:0] I_enum_attr,
    input wire [31:0] I_enum_size,I_enum_first_cluster,
    input wire [6:0] I_enum_name_length,
    input wire I_enum_name_valid,
    output wire O_enum_name_ready,
    input wire [7:0] I_enum_name_data,
    input wire I_enum_name_last,I_enum_done_valid,
    output wire O_enum_done_ready,
    input wire [15:0] I_enum_tag,
    input wire [31:0] I_enum_generation,I_enum_sectors,
    input wire [7:0] I_enum_error,
    input wire [3:0] I_enum_storage_error,
    input wire [2:0] I_enum_warning,

    output wire O_store_begin_valid,
    input wire I_store_begin_ready,
    output wire O_store_abort,O_store_item_valid,
    input wire I_store_item_ready,
    output wire [6:0] O_store_file_length,O_store_audio_length,
    output wire [5:0] O_store_title_length,
    output reg [9:0] O_store_duration,O_store_transition_ms,
    output reg [2:0] O_store_transition,
    output wire O_store_string_valid,
    input wire I_store_string_ready,
    output wire [7:0] O_store_string_data,
    output wire O_store_string_last,O_store_finish_valid,
    input wire I_store_finish_ready,
    output reg [1:0] O_store_order,
    output reg [31:0] O_store_seed,
    output wire O_store_commit_valid,O_store_source_retired,
    input wire I_store_commit_ready,I_store_done_valid,
    output wire O_store_done_ready,
    input wire [3:0] I_store_error
);
    localparam [3:0] IDLE=0,ENUM_CMD=1,PATH=2,SCAN=3,NAME=4,FILTER=5,
        ITEM=6,READ_ADDRESS=7,READ_CAPTURE=8,SEND=9,FINISH=10,COMMIT=11,DRAIN=12,RESULT=13;
    localparam [71:0] PRIMARY_PATH="/PLAY/IMG";
    localparam [79:0] PRIMARY_PREFIX="/PLAY/IMG/";
    reg [3:0] S_state;
    reg S_root,S_pending,S_retired,S_store_done,S_limit,S_candidate,S_name_bad,S_hint_bad;
    reg [31:0] S_budget;
    reg [3:0] S_path_index;
    reg [6:0] S_name_length,S_name_index;
    reg [7:0] S_name[0:63];
    reg [31:0] S_suffix;
    reg [7:0] S_last_char,S_name_q,S_byte,S_send_index;
    wire S_active=S_state!=IDLE && S_state!=RESULT;
    wire S_start=I_start_valid && O_start_ready;
    wire S_media_matches=I_media_valid && I_media_generation==O_generation;
    wire S_matches=I_enum_tag==O_enum_tag && I_enum_generation==O_generation;
    wire S_store_fault=I_store_done_valid && !S_store_done && !O_committed;
    wire S_early_end=I_enum_done_valid && S_pending && S_matches && S_state==NAME &&
        I_enum_error==0 && I_enum_storage_error==0;
    wire [3:0] S_current_error=!S_media_matches ? 4'd3 : I_abort ? 4'd2 :
        (S_store_fault || S_early_end) && O_error==0 ? 4'd4 : 4'd0;
    wire [3:0] S_effective_error=O_committed ? 4'd0 : prefer_error(O_error,S_current_error);
    wire S_stop=S_active && S_effective_error!=0;
    wire S_enum_accept=O_enum_valid && I_enum_ready;
    wire S_enum_done=I_enum_done_valid && O_enum_done_ready && S_matches;
    wire S_name_accept=I_enum_name_valid && O_enum_name_ready && S_matches && !S_stop;
    wire [32:0] S_spent_now=O_sectors+{1'b0,I_enum_sectors};
    wire [6:0] S_prefix_length=S_root ? 7'd1 : 7'd10;
    wire [7:0] S_file_length={1'b0,S_prefix_length}+{1'b0,S_name_length};
    wire [6:0] S_stem_length=S_name_length-7'd4;
    wire [7:0] S_total_length={1'b0,O_store_file_length}+{2'd0,O_store_title_length};
    wire [7:0] S_ram_address=S_send_index<{1'b0,O_store_file_length} ?
        S_send_index-{1'b0,S_prefix_length} : S_send_index-{1'b0,O_store_file_length};
    wire S_prefix_byte=S_send_index<{1'b0,S_prefix_length};
    wire S_defaults_ok=I_duration>=1 && I_duration<=600 && I_order<3 &&
        (I_transition_ms==200 || I_transition_ms==400 || I_transition_ms==600 || I_transition_ms==1000);

    function [2:0] error_rank;
        input [3:0] value;
        begin case(value) 3:error_rank=5; 2:error_rank=4; 1:error_rank=3;
            4:error_rank=2; 5:error_rank=1; default:error_rank=0; endcase end
    endfunction
    function [3:0] prefer_error;
        input [3:0] old_error,new_error;
        begin prefer_error=error_rank(new_error)>error_rank(old_error) ? new_error : old_error; end
    endfunction
    function [7:0] fold;
        input [7:0] value;
        begin fold=value>=65 && value<=90 ? value+8'd32 : value; end
    endfunction
    function legal_name;
        input [7:0] value;
        begin legal_name=value>=32 && value<=126 && value!=34 && value!=42 && value!=47 &&
            value!=58 && value!=60 && value!=62 && value!=63 && value!=92 && value!=124; end
    endfunction

    assign O_start_ready=!I_reset && S_state==IDLE && I_lease_grant && I_store_begin_ready;
    assign O_lease_request=!I_reset && S_state==IDLE && I_start_valid;
    assign O_lease_active=!I_reset && S_state!=IDLE;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_enum_valid=!I_reset && S_state==ENUM_CMD && !S_stop;
    assign O_enum_tag=O_tag+(S_root ? 16'd1 : 16'd0);
    assign O_enum_path_length=S_root ? 7'd1 : 7'd9;
    assign O_enum_sector_budget=O_sectors<{1'b0,S_budget} ? S_budget-O_sectors[31:0] : 32'd0;
    assign O_enum_path_valid=!I_reset && S_state==PATH && !S_stop && !S_enum_done;
    assign O_enum_path_data=S_root ? 8'h2f : PRIMARY_PATH[(8-S_path_index)*8+:8];
    assign O_enum_path_last=S_root || S_path_index==8;
    assign O_enum_stop=!I_reset && S_pending && S_limit && !S_stop;
    assign O_enum_cancel=!I_reset && S_pending && S_stop;
    assign O_enum_entry_ready=!I_reset && S_pending && (!S_matches || S_stop || S_limit || S_state==SCAN);
    assign O_enum_name_ready=!I_reset && S_pending && (!S_matches || S_stop || S_limit || S_state==NAME);
    // Successful EOF may arrive while the last name is still being copied to the store.
    assign O_enum_done_ready=!I_reset && S_pending && (!S_matches || S_stop ||
        I_enum_error!=0 || I_enum_storage_error!=0 || S_state==SCAN || S_state==PATH);
    assign O_store_begin_valid=S_start;
    assign O_store_abort=S_stop;
    assign O_store_item_valid=!I_reset && S_state==ITEM && !S_stop;
    assign O_store_file_length=S_file_length[6:0];
    assign O_store_audio_length=7'd0;
    assign O_store_title_length=S_stem_length>40 ? 6'd40 : S_stem_length[5:0];
    assign O_store_string_valid=!I_reset && S_state==SEND && !S_stop;
    assign O_store_string_data=S_byte;
    assign O_store_string_last=S_send_index+8'd1==S_total_length;
    assign O_store_finish_valid=!I_reset && S_state==FINISH && !S_stop;
    assign O_store_commit_valid=!I_reset && S_state==COMMIT && S_retired && !S_stop;
    assign O_store_source_retired=S_retired && !S_pending;
    assign O_store_done_ready=!I_reset && S_active && !S_store_done;

    // One bounded synchronous RAM read port; never reset the name array.
    always @(posedge I_clk) begin
        if(S_name_accept && S_state==NAME) S_name[S_name_index[5:0]]<=I_enum_name_data;
        if(S_state==READ_ADDRESS && !S_prefix_byte) S_name_q<=S_name[S_ram_address[5:0]];
    end
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_root<=0; S_pending<=0; S_retired<=0; S_store_done<=0;
            S_limit<=0; S_candidate<=0; S_name_bad<=0; S_hint_bad<=0; S_budget<=0;
            S_path_index<=0; S_name_length<=0; S_name_index<=0; S_suffix<=0;
            S_last_char<=0; S_byte<=0; S_send_index<=0;
            O_error<=0; O_count<=0; O_warning<=0; O_directory_error<=0; O_primary_error<=0;
            O_storage_error<=0; O_directory_warning<=0; O_sectors<=0; O_tag<=0; O_generation<=0;
            O_committed<=0; O_store_duration<=0; O_store_transition_ms<=0;
            O_store_transition<=0; O_store_order<=0; O_store_seed<=0;
        end else begin
            if(S_active) begin
                if(!O_committed) O_error<=S_effective_error;
                if(I_store_done_valid && O_store_done_ready) S_store_done<=1;
            end
            if(S_enum_accept) S_pending<=1;
            if(S_enum_done) begin
                S_pending<=0; O_sectors<=S_spent_now;
                O_directory_error<=I_enum_error; O_storage_error<=I_enum_storage_error;
                O_directory_warning<=O_directory_warning | I_enum_warning;
                if(I_enum_warning!=0) O_warning[4]<=1;
                if(!S_root) O_primary_error<=I_enum_error;
                if(S_effective_error!=0) begin S_retired<=1; S_state<=DRAIN; end
                else if({1'b0,I_enum_sectors}>{1'b0,O_enum_sector_budget}) begin
                    O_error<=4; S_retired<=1; S_state<=DRAIN;
                end else if(!S_root && O_count==0 && I_enum_storage_error==0 &&
                    (I_enum_error==0 || I_enum_error==14 || I_enum_error==15)) begin
                    if(S_spent_now>={1'b0,S_budget}) begin
                        O_error<=1; O_directory_error<=10; S_retired<=1; S_state<=DRAIN;
                    end else begin
                        S_root<=1; O_warning[0]<=1;
                        if(I_enum_error!=0) O_warning[5]<=1;
                        S_path_index<=0; S_state<=ENUM_CMD;
                    end
                end else begin
                    S_retired<=1;
                    if(I_enum_error!=0 || I_enum_storage_error!=0) begin O_error<=1; S_state<=DRAIN; end
                    else if(O_count==0) begin O_error<=5; S_state<=DRAIN; end
                    else S_state<=FINISH;
                end
            end else if(S_stop && S_state!=DRAIN) begin
                if(!S_pending) S_retired<=1;
                S_state<=DRAIN;
            end else case(S_state)
                IDLE:if(S_start) begin
                    O_tag<=I_tag; O_generation<=I_generation; S_budget<=I_sector_budget;
                    O_store_seed<=I_seed; O_store_order<=I_order; O_store_duration<=I_duration;
                    O_store_transition<=I_transition; O_store_transition_ms<=I_transition_ms;
                    O_error<=!I_media_valid || I_media_generation!=I_generation ? 4'd3 :
                        I_abort ? 4'd2 : !S_defaults_ok || I_sector_budget==0 ? 4'd4 : 4'd0;
                    O_count<=0; O_warning<=0; O_directory_error<=0; O_primary_error<=0;
                    O_storage_error<=0; O_directory_warning<=0; O_sectors<=0; O_committed<=0;
                    S_root<=0; S_pending<=0; S_retired<=0; S_store_done<=0; S_limit<=0;
                    S_path_index<=0; S_state<=ENUM_CMD;
                end
                ENUM_CMD:if(S_enum_accept) begin S_path_index<=0; S_state<=PATH; end
                PATH:if(O_enum_path_valid && I_enum_path_ready) begin
                    if(O_enum_path_last) S_state<=SCAN;
                    else S_path_index<=S_path_index+4'd1;
                end
                SCAN:if(I_enum_entry_valid && O_enum_entry_ready && S_matches && !S_limit) begin
                    if(I_enum_name_length==0 || I_enum_name_length>64) O_error<=4;
                    else begin
                        S_name_length<=I_enum_name_length; S_name_index<=0; S_suffix<=0; S_name_bad<=0;
                        S_candidate<=!(I_enum_attr[3] || I_enum_attr[4]);
                        S_hint_bad<=I_enum_size<54 || I_enum_first_cluster<2;
                        S_state<=NAME;
                    end
                end
                NAME:if(S_name_accept) begin
                    S_suffix<={S_suffix[23:0],fold(I_enum_name_data)}; S_last_char<=I_enum_name_data;
                    if(!legal_name(I_enum_name_data)) S_name_bad<=1;
                    if(I_enum_name_last!=(S_name_index+7'd1==S_name_length)) O_error<=4;
                    else if(I_enum_name_last) S_state<=FILTER;
                    else S_name_index<=S_name_index+7'd1;
                end
                FILTER:begin
                    if(!S_candidate || S_suffix!=".bmp") S_state<=SCAN;
                    else if(S_name_length<=4 || S_name_bad || S_last_char==32 || S_last_char==46 || S_file_length>64) begin
                        O_warning[1]<=1; S_state<=SCAN;
                    end else if(S_hint_bad) begin O_warning[2]<=1; S_state<=SCAN; end
                    else begin
                        if(S_stem_length>40) O_warning[6]<=1;
                        S_state<=ITEM;
                    end
                end
                ITEM:if(I_store_item_ready) begin S_send_index<=0; S_state<=READ_ADDRESS; end
                READ_ADDRESS:S_state<=READ_CAPTURE;
                READ_CAPTURE:begin
                    S_byte<=S_prefix_byte ? (S_root ? 8'h2f : PRIMARY_PREFIX[(9-S_send_index)*8+:8]) : S_name_q;
                    S_state<=SEND;
                end
                SEND:if(I_store_string_ready) begin
                    if(O_store_string_last) begin
                        O_count<=O_count+7'd1; S_state<=SCAN;
                        if(O_count==63) begin S_limit<=1; O_warning[3]<=1; end
                    end else begin S_send_index<=S_send_index+8'd1; S_state<=READ_ADDRESS; end
                end
                FINISH:if(I_store_finish_ready) S_state<=COMMIT;
                COMMIT:if(O_store_commit_valid && I_store_commit_ready) begin O_committed<=1; O_error<=0; S_state<=DRAIN; end
                DRAIN:if(S_retired && S_store_done) S_state<=RESULT;
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
