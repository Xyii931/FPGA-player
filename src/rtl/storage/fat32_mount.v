// FAT32 geometry validation. Sector data comes only from a checked sector port.
// No file pointers, card writes, FSInfo dependence or repair of malformed media.
module fat32_mount (
    input wire I_clk,I_reset,I_card_ready,
    input wire [32:0] I_capacity_sectors,
    input wire I_start_valid,
    output wire O_start_ready,
    output wire O_result_valid,
    input wire I_result_ready,
    output reg [7:0] O_error,
    output reg [3:0] O_storage_error,
    output reg O_mounted,
    output reg [31:0] O_partition_lba,O_volume_sectors,O_fat_lba,O_data_lba,
    output reg [31:0] O_cluster_count,O_root_cluster,
    output reg [7:0] O_sectors_per_cluster,
    output reg [2:0] O_cluster_shift,
    output wire O_read_valid,
    input wire I_read_ready,
    output reg [31:0] O_read_lba,
    input wire I_read_result_valid,
    output wire O_read_result_ready,
    input wire [7:0] I_read_error,
    input wire [3:0] I_storage_error,
    output wire [8:0] O_buffer_address,
    input wire [7:0] I_buffer_data
);
    localparam [3:0] IDLE=0,FETCH=1,FETCH_WAIT=2,SCAN_ADDRESS=3,SCAN_BYTE=4,
        IDENTIFY=5,SELECT_PARTITION=6,VALIDATE=7,RESULT=8;
    reg [3:0] S_state;
    reg [8:0] S_scan;
    reg S_partition_sector;
    reg [2:0] S_partition_index;
    reg [32:0] S_capacity,S_partition_length;
    reg [31:0] S_partition_lba;
    reg [7:0] S_jump,S_spc,S_fats;
    reg [15:0] S_signature,S_bps,S_reserved,S_root_entries,S_total16,S_fat16,S_flags,S_version;
    reg [31:0] S_total32,S_fat_size,S_root_cluster;
    reg [7:0] S_partition_type[0:3],S_partition_boot[0:3];
    reg [31:0] S_partition_start[0:3],S_partition_size[0:3];
    wire [8:0] S_partition_offset=S_scan-9'd446;
    wire [1:0] S_entry_index=S_partition_offset[5:4];
    wire [63:0] S_selected_partition_end={32'd0,S_partition_start[S_partition_index]}+
        {32'd0,S_partition_size[S_partition_index]};
    reg S_spc_valid;
    reg [2:0] S_shift;
    reg [63:0] S_total,S_overhead,S_clusters,S_fat_base,S_data_base,S_volume_end,S_partition_end,S_fat_entries;
    integer S_i;
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_result_valid=!I_reset && S_state==RESULT;
    assign O_read_valid=!I_reset && S_state==FETCH && I_card_ready;
    assign O_read_result_ready=!I_reset && S_state==FETCH_WAIT;
    assign O_buffer_address=S_scan;

    always @* begin
        S_spc_valid=1; S_shift=0;
        case(S_spc)
            1:S_shift=0; 2:S_shift=1; 4:S_shift=2; 8:S_shift=3;
            16:S_shift=4; 32:S_shift=5; 64:S_shift=6; 128:S_shift=7;
            default:S_spc_valid=0;
        endcase
        S_total=S_total16!=0 ? {48'd0,S_total16} : {32'd0,S_total32};
        S_overhead={48'd0,S_reserved}+{56'd0,S_fats}*{32'd0,S_fat_size};
        S_clusters=S_total>S_overhead ? (S_total-S_overhead)>>S_shift : 64'd0;
        S_fat_base={32'd0,S_partition_lba}+{48'd0,S_reserved};
        if(S_flags[7]) S_fat_base=S_fat_base+{60'd0,S_flags[3:0]}*{32'd0,S_fat_size};
        S_data_base={32'd0,S_partition_lba}+S_overhead;
        S_volume_end={32'd0,S_partition_lba}+S_total;
        S_partition_end={32'd0,S_partition_lba}+{31'd0,S_partition_length};
        S_fat_entries={32'd0,S_fat_size}<<7;
    end
    task clear_fields;
        begin
            S_jump<=0; S_signature<=0; S_bps<=0; S_spc<=0; S_reserved<=0;
            S_fats<=0; S_root_entries<=0; S_total16<=0; S_fat16<=0;
            S_total32<=0; S_fat_size<=0; S_flags<=0; S_version<=0; S_root_cluster<=0;
            for(S_i=0;S_i<4;S_i=S_i+1) begin
                S_partition_type[S_i]<=0; S_partition_boot[S_i]<=0;
                S_partition_start[S_i]<=0; S_partition_size[S_i]<=0;
            end
        end
    endtask
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_scan<=0; S_partition_sector<=0; S_partition_index<=0;
            S_capacity<=0; S_partition_length<=0; S_partition_lba<=0;
            O_error<=0; O_storage_error<=0; O_mounted<=0; O_read_lba<=0;
            O_partition_lba<=0; O_volume_sectors<=0; O_fat_lba<=0; O_data_lba<=0;
            O_cluster_count<=0; O_root_cluster<=0; O_sectors_per_cluster<=0; O_cluster_shift<=0;
            clear_fields;
        end else begin
            case(S_state)
                IDLE: if(I_start_valid) begin
                    O_mounted<=0; O_error<=0; O_storage_error<=0;
                    S_capacity<=I_capacity_sectors; S_partition_length<=I_capacity_sectors;
                    S_partition_lba<=0; S_partition_sector<=0; O_read_lba<=0;
                    if(!I_card_ready) finish(8'd1);
                    else if(I_capacity_sectors==0 || I_capacity_sectors>33'h100000000) finish(8'd5);
                    else S_state<=FETCH;
                end
                FETCH: if(I_read_ready) S_state<=FETCH_WAIT;
                FETCH_WAIT: if(I_read_result_valid) begin
                    O_storage_error<=I_storage_error;
                    if(!I_card_ready || I_read_error==1) finish(8'd1);
                    else if(I_read_error!=0) finish(8'd2);
                    else begin clear_fields; S_scan<=0; S_state<=SCAN_ADDRESS; end
                end
                SCAN_ADDRESS: S_state<=SCAN_BYTE;
                SCAN_BYTE: begin
                    case(S_scan)
                        0:S_jump<=I_buffer_data;
                        11:S_bps[7:0]<=I_buffer_data; 12:S_bps[15:8]<=I_buffer_data;
                        13:S_spc<=I_buffer_data;
                        14:S_reserved[7:0]<=I_buffer_data; 15:S_reserved[15:8]<=I_buffer_data;
                        16:S_fats<=I_buffer_data;
                        17:S_root_entries[7:0]<=I_buffer_data; 18:S_root_entries[15:8]<=I_buffer_data;
                        19:S_total16[7:0]<=I_buffer_data; 20:S_total16[15:8]<=I_buffer_data;
                        22:S_fat16[7:0]<=I_buffer_data; 23:S_fat16[15:8]<=I_buffer_data;
                        32,33,34,35:S_total32[(S_scan-32)*8+:8]<=I_buffer_data;
                        36,37,38,39:S_fat_size[(S_scan-36)*8+:8]<=I_buffer_data;
                        40:S_flags[7:0]<=I_buffer_data; 41:S_flags[15:8]<=I_buffer_data;
                        42:S_version[7:0]<=I_buffer_data; 43:S_version[15:8]<=I_buffer_data;
                        44,45,46,47:S_root_cluster[(S_scan-44)*8+:8]<=I_buffer_data;
                        510:S_signature[7:0]<=I_buffer_data; 511:S_signature[15:8]<=I_buffer_data;
                        default:begin end
                    endcase
                    if(S_scan>=446 && S_scan<=509) begin
                        case(S_partition_offset[3:0])
                            0:S_partition_boot[S_entry_index]<=I_buffer_data;
                            4:S_partition_type[S_entry_index]<=I_buffer_data;
                            8,9,10,11:S_partition_start[S_entry_index][(S_partition_offset[3:0]-8)*8+:8]<=I_buffer_data;
                            12,13,14,15:S_partition_size[S_entry_index][(S_partition_offset[3:0]-12)*8+:8]<=I_buffer_data;
                            default:begin end
                        endcase
                    end
                    if(S_scan==511) S_state<=S_partition_sector ? VALIDATE : IDENTIFY;
                    else begin S_scan<=S_scan+9'd1; S_state<=SCAN_ADDRESS; end
                end
                IDENTIFY: begin
                    if(S_signature!=16'haa55) finish(8'd3);
                    else if(S_bps==512 || ((S_jump==8'heb || S_jump==8'he9) &&
                        S_reserved!=0 && S_fats!=0 && S_fat_size!=0 && S_root_entries==0 && S_fat16==0))
                        S_state<=VALIDATE;
                    else begin S_partition_index<=0; S_state<=SELECT_PARTITION; end
                end
                SELECT_PARTITION: begin
                    if(S_partition_index==4) finish(8'd4);
                    else if(S_partition_type[S_partition_index]==8'h0b || S_partition_type[S_partition_index]==8'h0c ||
                        S_partition_type[S_partition_index]==8'h1b || S_partition_type[S_partition_index]==8'h1c) begin
                        if((S_partition_boot[S_partition_index]!=0 && S_partition_boot[S_partition_index]!=8'h80) ||
                            S_partition_start[S_partition_index]==0 || S_partition_size[S_partition_index]==0 ||
                            S_selected_partition_end>{31'd0,S_capacity})
                            finish(8'd5);
                        else begin
                            S_partition_lba<=S_partition_start[S_partition_index];
                            S_partition_length<={1'b0,S_partition_size[S_partition_index]};
                            O_read_lba<=S_partition_start[S_partition_index];
                            S_partition_sector<=1; S_state<=FETCH;
                        end
                    end else S_partition_index<=S_partition_index+3'd1;
                end
                VALIDATE: begin
                    if(S_signature!=16'haa55 || (S_jump!=8'heb && S_jump!=8'he9) || S_bps!=512 ||
                        S_root_entries!=0 || S_fat16!=0 || S_version!=0) finish(8'd3);
                    else if(!S_spc_valid || S_reserved==0 || (S_fats!=1 && S_fats!=2) || S_fat_size==0 ||
                        (S_flags[7] && S_flags[3:0]>=S_fats) || S_total<=S_overhead ||
                        S_clusters<65525 || S_clusters>64'h0fffffee || S_fat_entries<S_clusters+2 ||
                        S_root_cluster<2 || {32'd0,S_root_cluster}>S_clusters+1) finish(8'd6);
                    else if(S_total>{31'd0,S_partition_length} || S_volume_end>{31'd0,S_capacity} ||
                        S_partition_end>{31'd0,S_capacity} || S_volume_end>64'h100000000 ||
                        S_fat_base>64'hffffffff || S_data_base>64'hffffffff) finish(8'd5);
                    else begin
                        O_partition_lba<=S_partition_lba; O_volume_sectors<=S_total[31:0];
                        O_fat_lba<=S_fat_base[31:0]; O_data_lba<=S_data_base[31:0];
                        O_cluster_count<=S_clusters[31:0]; O_root_cluster<=S_root_cluster;
                        O_sectors_per_cluster<=S_spc; O_cluster_shift<=S_shift; O_mounted<=1; finish(8'd0);
                    end
                end
                RESULT: if(I_result_ready) S_state<=IDLE;
                default:finish(8'd3);
            endcase
            if(!I_card_ready) begin
                O_mounted<=0;
                if(S_state!=IDLE && S_state!=FETCH_WAIT && S_state!=RESULT) finish(8'd1);
            end
        end
    end
endmodule
