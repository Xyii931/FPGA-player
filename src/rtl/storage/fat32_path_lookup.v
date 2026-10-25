// Root-relative ASCII path resolver. Results describe an entry, not an open fd.
// A match stops the scanner, but the scanner's joined terminal still owns I/O.
module fat32_path_lookup (
    input wire I_clk,I_reset,I_mounted,
    input wire [31:0] I_fat_lba,I_data_lba,I_cluster_count,I_root_cluster,
    input wire [2:0] I_cluster_shift,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [6:0] I_path_length,
    input wire [31:0] I_sector_budget,
    input wire I_path_valid,
    output wire O_path_ready,
    input wire [7:0] I_path_data,
    input wire I_path_last,I_cancel,
    output wire O_result_valid,
    input wire I_result_ready,
    output reg [7:0] O_attr,
    output reg [31:0] O_size,O_first_cluster,O_sectors,
    output reg [2:0] O_warning,
    output reg [7:0] O_error,
    output reg [3:0] O_storage_error,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [31:0] O_read_lba,
    output wire O_read_abort,
    input wire I_read_result_valid,
    output wire O_read_result_ready,
    input wire [7:0] I_read_error,
    input wire [3:0] I_storage_error,
    output wire [8:0] O_buffer_address,
    input wire [7:0] I_buffer_data
);
    localparam [3:0] IDLE=0,RECEIVE=1,TOKEN_START=2,TOKEN_SCAN=3,TOKEN_END=4,
        NEXT_SKIP=5,DIR_START=6,DIR_SCAN=7,RESULT=8,VALIDATE=9;
    reg [3:0] S_state;
    reg [7:0] S_path[0:63];
    reg [6:0] S_length,S_received,S_scan,S_token_start,S_token_length,S_next_start,S_name_index;
    reg [31:0] S_budget,S_directory;
    reg S_canceled,S_lost,S_bad_path,S_final,S_require_dir,S_found,S_name_equal,S_alias_equal,S_dots;
    reg [7:0] S_attr;
    reg [31:0] S_size,S_cluster;
    wire S_dir_ready,S_entry_valid,S_name_valid,S_name_last,S_dir_done,S_is_lfn;
    wire [7:0] S_entry_attr,S_name,S_dir_error;
    wire [31:0] S_entry_size,S_entry_cluster,S_dir_sectors;
    wire [87:0] S_alias;
    wire [95:0] S_alias_padded={8'd0,S_alias};
    wire [6:0] S_name_length;
    wire [3:0] S_dir_storage_error;
    wire [2:0] S_warning;
    wire S_invalid=S_lost || !I_mounted;
    wire S_cancel=S_canceled || I_cancel;
    wire S_compare_byte=S_name_index<S_token_length &&
        fold_ascii(S_name)==fold_ascii(S_path[(S_token_start+S_name_index)&7'h3f]);
    reg [3:0] S_base_length,S_ext_length;
    reg [4:0] S_alias_length;
    reg S_alias_match;
    reg [7:0] S_alias_byte;
    integer S_i;

    function [7:0] fold_ascii;
        input [7:0] value;
        begin fold_ascii=value>=8'h41 && value<=8'h5a ? value+8'd32 : value; end
    endfunction
    function legal_path;
        input [7:0] value;
        begin
            legal_path=value>=32 && value<=126 && value!=8'h22 && value!=8'h2a &&
                value!=8'h3a && value!=8'h3c && value!=8'h3e && value!=8'h3f && value!=8'h5c && value!=8'h7c;
        end
    endfunction
    // Parser already validated the alias; trim its space padding and insert dot.
    always @* begin
        S_base_length=0; S_ext_length=0;
        for(S_i=0;S_i<8;S_i=S_i+1) if(S_alias[S_i*8+:8]!=8'h20) S_base_length=S_i+1;
        for(S_i=0;S_i<3;S_i=S_i+1) if(S_alias[(S_i+8)*8+:8]!=8'h20) S_ext_length=S_i+1;
        S_alias_length={1'b0,S_base_length}+(S_ext_length!=0 ? 5'd1+{1'b0,S_ext_length} : 5'd0);
        S_alias_match=S_token_length=={2'd0,S_alias_length}; S_alias_byte=0;
        for(S_i=0;S_i<12;S_i=S_i+1) begin
            S_alias_byte=0;
            // TD checks every unrolled slice, including i=8..11 behind this guard.
            // Padding keeps those unreachable base-byte reads in range.
            if(S_i<S_base_length) S_alias_byte=S_alias_padded[S_i*8+:8];
            else if(S_i==S_base_length) S_alias_byte=8'h2e;
            else if(S_i<S_alias_length) S_alias_byte=S_alias[(8+S_i-S_base_length-1)*8+:8];
            if(S_i<S_alias_length && fold_ascii(S_path[(S_token_start+S_i)&63])!=fold_ascii(S_alias_byte))
                S_alias_match=0;
        end
    end
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_path_ready=!I_reset && S_state==RECEIVE && !S_cancel && !S_invalid;
    assign O_result_valid=!I_reset && S_state==RESULT;
    fat32_directory u_directory (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(I_mounted && !S_lost),
        .I_fat_lba(I_fat_lba),.I_data_lba(I_data_lba),.I_cluster_count(I_cluster_count),.I_cluster_shift(I_cluster_shift),
        .I_start_valid(S_state==DIR_START && !S_cancel && !S_invalid),.O_start_ready(S_dir_ready),
        .I_first_cluster(S_directory),.I_sector_budget(S_budget-O_sectors),.I_stop(S_found),.I_cancel(S_cancel),
        .O_entry_valid(S_entry_valid),.I_entry_ready(S_state==DIR_SCAN && !S_found),
        .O_attr(S_entry_attr),.O_size(S_entry_size),.O_first_cluster(S_entry_cluster),.O_alias(S_alias),
        .O_name_length(S_name_length),.O_is_lfn(S_is_lfn),.O_name_valid(S_name_valid),
        .I_name_ready(S_state==DIR_SCAN && !S_found),.O_name_data(S_name),.O_name_last(S_name_last),
        .O_done_valid(S_dir_done),.I_done_ready(S_state==DIR_SCAN),.O_error(S_dir_error),
        .O_storage_error(S_dir_storage_error),.O_sectors(S_dir_sectors),.O_warning(S_warning),
        .O_read_valid(O_read_valid),.I_read_ready(I_read_ready),.O_read_lba(O_read_lba),.O_read_abort(O_read_abort),
        .I_read_result_valid(I_read_result_valid),.O_read_result_ready(O_read_result_ready),
        .I_read_error(I_read_error),.I_storage_error(I_storage_error),.O_buffer_address(O_buffer_address),.I_buffer_data(I_buffer_data));
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_length<=0; S_received<=0; S_scan<=0; S_token_start<=0; S_token_length<=0;
            S_next_start<=0; S_name_index<=0; S_budget<=0; S_directory<=0;
            S_canceled<=0; S_lost<=0; S_bad_path<=0; S_final<=0; S_require_dir<=0;
            S_found<=0; S_name_equal<=0; S_alias_equal<=0; S_dots<=0; S_attr<=0; S_size<=0; S_cluster<=0;
            O_attr<=0; O_size<=0; O_first_cluster<=0; O_sectors<=0; O_warning<=0; O_error<=0; O_storage_error<=0;
        end else begin
            if(S_state!=IDLE && S_state!=RESULT) begin
                if(I_cancel) S_canceled<=1;
                if(!I_mounted) S_lost<=1;
            end
            if(S_state==DIR_SCAN) O_warning<=O_warning | S_warning;
            case(S_state)
                IDLE: if(I_start_valid) begin
                    S_length<=I_path_length; S_received<=0; S_scan<=0; S_budget<=I_sector_budget;
                    S_directory<=I_root_cluster; S_canceled<=0; S_lost<=0; S_bad_path<=0;
                    S_found<=0; S_final<=0; S_require_dir<=0;
                    O_attr<=0; O_size<=0; O_first_cluster<=0; O_sectors<=0; O_warning<=0; O_error<=0; O_storage_error<=0;
                    if(!I_mounted) finish(8'd1);
                    else if(I_cancel) finish(8'd8);
                    else if(I_path_length==0 || I_path_length>64) finish(8'd13);
                    else if(I_root_cluster<2 || I_root_cluster>I_cluster_count+32'd1 ||
                        I_cluster_count==0 || I_cluster_count>32'h0fffffee) finish(8'd9);
                    else S_state<=RECEIVE;
                end
                RECEIVE: if(I_path_valid && O_path_ready) begin
                    S_path[S_received[5:0]]<=I_path_data; S_received<=S_received+7'd1;
                    if(!legal_path(I_path_data)) S_bad_path<=1;
                    if(I_path_last!=(S_received+7'd1==S_length)) finish(8'd13);
                    else if(I_path_last) begin
                        S_require_dir<=I_path_data==8'h2f;
                        if(S_bad_path || !legal_path(I_path_data)) finish(8'd13);
                        else begin S_scan<=0; S_token_length<=0; S_dots<=1; S_state<=VALIDATE; end
                    end
                end
                VALIDATE: begin
                    if(S_scan==S_length || S_path[S_scan[5:0]]==8'h2f) begin
                        if(S_dots && (S_token_length==1 || S_token_length==2)) finish(8'd13);
                        else if(S_scan==S_length) begin S_scan<=0; S_state<=TOKEN_START; end
                        else begin S_scan<=S_scan+7'd1; S_token_length<=0; S_dots<=1; end
                    end else begin
                        S_scan<=S_scan+7'd1; S_token_length<=S_token_length+7'd1;
                        S_dots<=S_dots && S_path[S_scan[5:0]]==8'h2e;
                    end
                end
                TOKEN_START: begin
                    if(S_scan==S_length) begin
                        O_attr<=8'h10; O_size<=0; O_first_cluster<=S_directory; finish(8'd0);
                    end else if(S_path[S_scan[5:0]]==8'h2f) S_scan<=S_scan+7'd1;
                    else begin S_token_start<=S_scan; S_token_length<=0; S_state<=TOKEN_SCAN; end
                end
                TOKEN_SCAN: begin
                    if(S_scan==S_length || S_path[S_scan[5:0]]==8'h2f) S_state<=TOKEN_END;
                    else begin S_token_length<=S_token_length+7'd1; S_scan<=S_scan+7'd1; end
                end
                TOKEN_END: begin
                    if((S_token_length==1 && S_path[S_token_start[5:0]]==8'h2e) ||
                        (S_token_length==2 && S_path[S_token_start[5:0]]==8'h2e &&
                            S_path[(S_token_start+7'd1)&7'h3f]==8'h2e)) finish(8'd13);
                    else S_state<=NEXT_SKIP;
                end
                NEXT_SKIP: begin
                    if(S_scan<S_length && S_path[S_scan[5:0]]==8'h2f) S_scan<=S_scan+7'd1;
                    else begin
                        S_next_start<=S_scan; S_final<=S_scan==S_length; S_found<=0; S_state<=DIR_START;
                    end
                end
                DIR_START: if(S_dir_ready && !S_cancel && !S_invalid) S_state<=DIR_SCAN;
                DIR_SCAN: begin
                    if(S_entry_valid && !S_found) begin
                        S_attr<=S_entry_attr; S_size<=S_entry_size; S_cluster<=S_entry_cluster;
                        S_alias_equal<=S_alias_match; S_name_equal<=S_name_length==S_token_length; S_name_index<=0;
                    end
                    if(S_name_valid && !S_found) begin
                        S_name_equal<=S_name_equal && S_compare_byte; S_name_index<=S_name_index+7'd1;
                        if(S_name_last && (S_alias_equal || (S_name_equal && S_compare_byte))) S_found<=1;
                    end
                    if(S_dir_done) begin
                        O_sectors<=O_sectors+S_dir_sectors; O_storage_error<=S_dir_storage_error;
                        if(S_invalid) finish(8'd1);
                        else if(S_cancel) finish(8'd8);
                        else if(S_dir_error!=0) finish(S_dir_error);
                        else if(!S_found) finish(8'd14);
                        else if((!S_final || S_require_dir) && !S_attr[4]) finish(8'd15);
                        else if(S_attr[4] && (S_cluster<2 || S_cluster>I_cluster_count+32'd1)) finish(8'd9);
                        else if(S_final) begin
                            O_attr<=S_attr; O_size<=S_size; O_first_cluster<=S_cluster; finish(8'd0);
                        end else begin S_directory<=S_cluster; S_scan<=S_next_start; S_state<=TOKEN_START; end
                    end
                end
                RESULT: if(I_result_ready) S_state<=IDLE;
                default:finish(8'd13);
            endcase
            // Only DIR_SCAN can have an active child; it must finish the join.
            if(S_state!=IDLE && S_state!=RESULT && S_state!=DIR_SCAN) begin
                if(S_invalid) finish(8'd1);
                else if(S_cancel) finish(8'd8);
            end
        end
    end
endmodule
