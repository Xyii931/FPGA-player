// Root catalog only: consume short-entry metadata, ignore LFN text and folders.
// Files with LFN entries still have a short alias and are located by cluster;
// this player never builds or resolves their names. Chain/budget checks remain
// in the existing checked FAT32 directory stream.
module lean_root_scan (
    input wire I_clk,I_reset,I_mounted,
    input wire [31:0] I_fat_lba,I_data_lba,I_cluster_count,I_first_cluster,
    input wire [2:0] I_cluster_shift,
    input wire I_start_valid,
    output wire O_start_ready,
    output reg O_entry_valid,O_entry_audio,
    output reg [31:0] O_size,O_first_cluster,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [7:0] O_error,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [31:0] O_read_lba,
    output wire O_read_abort,
    input wire I_read_result_valid,
    output wire O_read_result_ready,
    input wire [7:0] I_read_error,
    input wire [3:0] I_storage_error,
    output wire [8:0] O_buffer_address,
    input wire [7:0] I_buffer_data,
    // Shared FAT chain walker pass-through.
    output wire O_walk_start,O_walk_mounted,O_walk_cancel,O_walk_result_ready,
    output wire O_walk_read_ready,O_walk_read_result_valid,
    output wire [31:0] O_walk_first,O_walk_target,O_walk_hop_limit,
    input wire I_walk_start_ready,I_walk_result_valid,I_walk_eoc,
    input wire [31:0] I_walk_cluster,I_walk_hops,I_walk_read_lba,
    input wire [7:0] I_walk_error,
    input wire [3:0] I_walk_storage_error,
    input wire I_walk_read_valid,I_walk_read_abort,I_walk_read_result_ready,
    input wire [8:0] I_walk_address
);
    wire S_byte_valid,S_end;
    wire [7:0] S_byte;
    reg S_stop;
    reg [4:0] S_index;
    reg [7:0] S_first_byte,S_attr;
    reg [23:0] S_extension,S_size_low;
    reg [31:0] S_first;
    wire S_bmp=S_extension==24'h504d42;
    wire S_wav=S_extension==24'h564157;
    wire S_regular=S_first_byte!=8'he5 && S_first_byte!=0 && (S_attr & 8'h18)==0;
    wire S_start=I_start_valid && O_start_ready;
    assign O_done_valid=S_end && !O_entry_valid;
    fat32_dir_stream u_stream (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(I_mounted),.I_fat_lba(I_fat_lba),.I_data_lba(I_data_lba),
        .I_cluster_count(I_cluster_count),.I_cluster_shift(I_cluster_shift),
        .I_start_valid(I_start_valid),.O_start_ready(O_start_ready),.I_first_cluster(I_first_cluster),.I_sector_budget(32'd4096),
        .I_stop(S_stop && !S_start),.I_cancel(!I_mounted),.O_byte_valid(S_byte_valid),.I_byte_ready(1'b1),.O_byte_data(S_byte),
        .O_end_valid(S_end),.I_end_ready(I_done_ready && !O_entry_valid),.O_error(O_error),.O_storage_error(),.O_sectors(),
        .O_read_valid(O_read_valid),.I_read_ready(I_read_ready),.O_read_lba(O_read_lba),.O_read_abort(O_read_abort),
        .I_read_result_valid(I_read_result_valid),.O_read_result_ready(O_read_result_ready),.I_read_error(I_read_error),
        .I_storage_error(I_storage_error),.O_buffer_address(O_buffer_address),.I_buffer_data(I_buffer_data),
        .O_walk_start(O_walk_start),.O_walk_mounted(O_walk_mounted),.O_walk_cancel(O_walk_cancel),
        .O_walk_result_ready(O_walk_result_ready),.O_walk_read_ready(O_walk_read_ready),
        .O_walk_read_result_valid(O_walk_read_result_valid),.O_walk_first(O_walk_first),
        .O_walk_target(O_walk_target),.O_walk_hop_limit(O_walk_hop_limit),
        .I_walk_start_ready(I_walk_start_ready),.I_walk_result_valid(I_walk_result_valid),
        .I_walk_eoc(I_walk_eoc),.I_walk_cluster(I_walk_cluster),.I_walk_hops(I_walk_hops),
        .I_walk_read_lba(I_walk_read_lba),.I_walk_error(I_walk_error),
        .I_walk_storage_error(I_walk_storage_error),.I_walk_read_valid(I_walk_read_valid),
        .I_walk_read_abort(I_walk_read_abort),.I_walk_read_result_ready(I_walk_read_result_ready),
        .I_walk_address(I_walk_address)
    );
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_stop<=0; S_index<=0; S_first_byte<=0; S_attr<=0; S_extension<=0; S_first<=0; S_size_low<=0;
            O_entry_valid<=0; O_entry_audio<=0; O_size<=0; O_first_cluster<=0;
        end else begin
            O_entry_valid<=0;
            if(I_start_valid && O_start_ready) begin S_stop<=0; S_index<=0; end
            if(S_byte_valid) begin
                S_index<=S_index+1'b1;
                case(S_index)
                    0:begin S_first_byte<=S_byte; if(S_byte==0) S_stop<=1; end
                    8:S_extension[7:0]<=S_byte;
                    9:S_extension[15:8]<=S_byte;
                    10:S_extension[23:16]<=S_byte;
                    11:S_attr<=S_byte;
                    20:S_first[23:16]<=S_byte;
                    21:S_first[31:24]<=S_byte;
                    26:S_first[7:0]<=S_byte;
                    27:S_first[15:8]<=S_byte;
                    28:S_size_low[7:0]<=S_byte;
                    29:S_size_low[15:8]<=S_byte;
                    30:S_size_low[23:16]<=S_byte;
                    31:if(S_regular && (S_bmp || S_wav) && {S_byte,S_size_low}!=0) begin
                        O_entry_valid<=1; O_entry_audio<=S_wav; O_size<={S_byte,S_size_low}; O_first_cluster<=S_first;
                    end
                    default:begin end
                endcase
            end
        end
    end
endmodule
