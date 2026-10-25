// Ordered directory scan + ASCII name parser. Completion joins both owners:
// parser end alone never grants permission to recycle an outstanding sector.
module fat32_directory (
    input wire I_clk,I_reset,I_mounted,
    input wire [31:0] I_fat_lba,I_data_lba,I_cluster_count,
    input wire [2:0] I_cluster_shift,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_first_cluster,I_sector_budget,
    input wire I_stop,I_cancel,
    output wire O_entry_valid,
    input wire I_entry_ready,
    output wire [7:0] O_attr,
    output wire [31:0] O_size,O_first_cluster,
    output wire [87:0] O_alias,
    output wire [6:0] O_name_length,
    output wire O_is_lfn,
    output wire O_name_valid,
    input wire I_name_ready,
    output wire [7:0] O_name_data,
    output wire O_name_last,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [7:0] O_error,
    output wire [3:0] O_storage_error,
    output wire [31:0] O_sectors,
    output wire [2:0] O_warning,
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
    wire S_stream_ready,S_parser_ready,S_byte_valid,S_byte_ready;
    wire [7:0] S_byte,S_stream_error,S_parser_error;
    wire S_stream_done,S_parser_done,S_parser_end_ready;
    wire S_start=I_start_valid && O_start_ready;
    reg S_busy,S_stopped,S_canceled;
    // Sticky termination belongs to the active scan, never its next start.
    wire S_stop=I_stop || (S_busy && S_stopped);
    wire S_cancel=I_cancel || (S_busy && S_canceled);
    assign O_start_ready=!I_reset && !S_busy && S_stream_ready && S_parser_ready;
    assign O_done_valid=!I_reset && S_stream_done && S_parser_done;
    assign O_error=S_stream_error==1 ? 8'd1 : (S_canceled ? 8'd8 :
        (S_stream_error!=0 ? S_stream_error : (S_stopped && S_parser_error==8 ? 8'd0 : S_parser_error)));
    fat32_dir_stream u_stream (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(I_mounted),.I_fat_lba(I_fat_lba),.I_data_lba(I_data_lba),
        .I_cluster_count(I_cluster_count),.I_cluster_shift(I_cluster_shift),
        .I_start_valid(S_start),.O_start_ready(S_stream_ready),.I_first_cluster(I_first_cluster),.I_sector_budget(I_sector_budget),
        .I_stop(S_stop || (S_busy && S_parser_done)),.I_cancel(S_cancel),
        .O_byte_valid(S_byte_valid),.I_byte_ready(S_byte_ready),.O_byte_data(S_byte),
        .O_end_valid(S_stream_done),.I_end_ready(I_done_ready && S_parser_done),.O_error(S_stream_error),
        .O_storage_error(O_storage_error),.O_sectors(O_sectors),
        .O_read_valid(O_read_valid),.I_read_ready(I_read_ready),.O_read_lba(O_read_lba),.O_read_abort(O_read_abort),
        .I_read_result_valid(I_read_result_valid),.O_read_result_ready(O_read_result_ready),
        .I_read_error(I_read_error),.I_storage_error(I_storage_error),.O_buffer_address(O_buffer_address),.I_buffer_data(I_buffer_data));
    fat32_dir_parser u_parser (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_start),.O_start_ready(S_parser_ready),
        .I_byte_valid(S_byte_valid),.O_byte_ready(S_byte_ready),.I_byte_data(S_byte),
        .I_end_valid(S_stream_done && !S_parser_done),.O_end_ready(S_parser_end_ready),.I_end_error(S_stream_error),
        .I_cancel(S_stop || S_cancel || (S_busy && S_stream_done && S_stream_error!=0)),
        .O_entry_valid(O_entry_valid),.I_entry_ready(I_entry_ready),.O_attr(O_attr),.O_size(O_size),.O_first_cluster(O_first_cluster),
        .O_alias(O_alias),.O_name_length(O_name_length),.O_is_lfn(O_is_lfn),
        .O_name_valid(O_name_valid),.I_name_ready(I_name_ready),.O_name_data(O_name_data),.O_name_last(O_name_last),
        .O_done_valid(S_parser_done),.I_done_ready(I_done_ready && S_stream_done),.O_error(S_parser_error),.O_warning(O_warning));
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin S_busy<=0; S_stopped<=0; S_canceled<=0; end
        else begin
            if(S_start) begin S_busy<=1; S_stopped<=I_stop; S_canceled<=I_cancel; end
            else if(S_busy && !O_done_valid) begin
                if(I_stop) S_stopped<=1;
                if(I_cancel) S_canceled<=1;
            end
            if(O_done_valid && I_done_ready) S_busy<=0;
        end
    end
endmodule
