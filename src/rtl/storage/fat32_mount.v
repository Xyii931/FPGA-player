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
    output reg [7:0] O_dbg_type,
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
        IDENTIFY=5,SELECT_PARTITION=6,VALIDATE=7,RESULT=8,
        GEO_PREP=9,GEO_BASES=10,GEO_SUB=11,GEO_CLUSTERS=12,VALIDATE_FINAL=13,GEO_CHECK=14,GEO_LIMITS=15;
    reg [3:0] S_state;
    reg [8:0] S_scan;
    reg S_partition_sector;
    reg [32:0] S_capacity,S_partition_length;
    reg [31:0] S_partition_lba;
    reg [7:0] S_jump,S_spc,S_fats;
    reg [15:0] S_signature,S_bps,S_reserved,S_root_entries,S_total16,S_fat16,S_flags,S_version;
    reg [31:0] S_total32,S_fat_size,S_root_cluster;
    // Only the first FAT32 partition is ever used; keep that candidate instead
    // of storing all four MBR entries and muxing them later.
    reg [7:0] S_entry_boot,S_partition_boot;
    reg [31:0] S_partition_start,S_partition_size;
    reg S_partition_found;
    reg [1:0] S_candidate_index;
    wire [8:0] S_partition_offset=S_scan-9'd446;
    wire [1:0] S_entry_index=S_partition_offset[5:4];
    wire [32:0] S_selected_partition_end={1'b0,S_partition_start}+{1'b0,S_partition_size};
    reg S_spc_valid;
    reg [2:0] S_shift;
    reg [23:0] S_wait_count;
    // Geometry stays in the widths the fields can actually reach: 32-bit
    // totals, 33/34-bit byte/sector sums, 39-bit FAT entry count. This keeps
    // the same range checks without 64-bit carry chains.
    reg [31:0] S_total,S_clusters,S_data_sectors;
    reg [33:0] S_overhead,S_data_base;
    reg [32:0] S_fat_base,S_volume_end,S_partition_end;
    reg [38:0] S_fat_entries;
    reg [32:0] S_required_entries,S_last_cluster;
    reg [2:0] S_geometry_bad;
    reg S_address_bad;
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
        S_total=S_total16!=0 ? {16'd0,S_total16} : S_total32;
        S_fat_entries={7'd0,S_fat_size}<<7;
    end
    // Mounting is a one-shot operation. Validate the allowed FAT counts before
    // arithmetic, then split geometry over clocks instead of synthesizing two
    // variable multipliers, chained additions, subtraction and a barrel shift.
    // Scratch values are overwritten before VALIDATE_FINAL; no RAM/data reset.
    always @(posedge I_clk) begin
        if(S_state==GEO_PREP) begin
            S_overhead<={18'd0,S_reserved}+(S_fats==2 ? {1'b0,S_fat_size,1'b0} : {1'b0,S_fat_size});
            S_fat_base<={1'b0,S_partition_lba}+{17'd0,S_reserved};
        end
        if(S_state==GEO_BASES) begin
            S_data_base<={1'b0,S_partition_lba}+S_overhead;
            S_volume_end<={1'b0,S_partition_lba}+{1'b0,S_total};
            S_partition_end<={1'b0,S_partition_lba}+S_partition_length;
            // Flags can select only FAT0 or FAT1 after structural validation.
            S_fat_base<=S_fat_base+((S_flags[7] && S_flags[0]) ? {1'b0,S_fat_size} : 33'd0);
        end
        if(S_state==GEO_SUB) S_data_sectors<=S_total>{1'b0,S_overhead} ? S_total-S_overhead : 32'd0;
        if(S_state==GEO_CLUSTERS) S_clusters<=S_data_sectors>>S_shift;
        // Keep cluster-limit additions out of the geometry classification path.
        // This one-time extra clock does not add a card read or alter the BPB.
        if(S_state==GEO_LIMITS) begin
            S_required_entries<={1'b0,S_clusters}+33'd2;
            S_last_cluster<={1'b0,S_clusters}+33'd1;
        end
        // Separate range arithmetic from publishing the mounted geometry.
        if(S_state==GEO_CHECK) begin
            S_geometry_bad[0]<=S_total<={1'b0,S_overhead} ||
                S_clusters<16'd65525 || S_clusters>32'h0fffffee;
            S_geometry_bad[1]<=S_fat_entries<{6'd0,S_required_entries};
            S_geometry_bad[2]<=S_root_cluster<2 || {1'b0,S_root_cluster}>S_last_cluster;
            S_address_bad<={1'b0,S_total}>S_partition_length || S_volume_end>S_capacity ||
                S_partition_end>S_capacity || S_volume_end>33'h100000000 ||
                S_fat_base>33'h0ffffffff || S_data_base>34'h0ffffffff;
        end
    end
    task clear_fields;
        begin
            S_jump<=0; S_signature<=0; S_bps<=0; S_spc<=0; S_reserved<=0;
            S_fats<=0; S_root_entries<=0; S_total16<=0; S_fat16<=0;
            S_total32<=0; S_fat_size<=0; S_flags<=0; S_version<=0; S_root_cluster<=0;
            S_entry_boot<=0; S_partition_boot<=0; S_partition_start<=0;
            S_partition_size<=0; S_partition_found<=0; O_dbg_type<=0; S_candidate_index<=0;
        end
    endtask
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_scan<=0; S_partition_sector<=0;
            S_capacity<=0; S_partition_length<=0; S_partition_lba<=0;
            O_error<=0; O_storage_error<=0; O_mounted<=0; O_read_lba<=0;
            S_wait_count<=24'd0;
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
                FETCH: begin
                    // A card loss or a stalled sector handshake must not hang the
                    // mount forever; both end the attempt so the caller can retry.
                    if(!I_card_ready) finish(8'd1);
                    else if(I_read_ready) begin S_wait_count<=24'd0; S_state<=FETCH_WAIT; end
                    else if(&S_wait_count) finish(8'd9);
                    else S_wait_count<=S_wait_count+1'b1;
                end
                FETCH_WAIT: begin
                    // Once the sector port accepted the request it owns the
                    // transaction until its terminal result. Abandoning it on
                    // a local timeout leaves that result unconsumed and blocks
                    // the shared port. The SD reader has its own timeouts.
                    if(I_read_result_valid) begin
                        O_storage_error<=I_storage_error;
                        if(!I_card_ready || I_read_error==1) finish(8'd1);
                        else if(I_read_error!=0) finish(8'd2);
                        else begin clear_fields; S_scan<=0; S_wait_count<=24'd0; S_state<=SCAN_ADDRESS; end
                    end
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
                    if(S_scan>=446 && S_scan<=509 && S_partition_offset[3:0]==4'd4 && I_buffer_data!=8'h00)
                        O_dbg_type<=I_buffer_data;
                    if(S_scan>=446 && S_scan<=509) begin
                        case(S_partition_offset[3:0])
                            0:S_entry_boot<=I_buffer_data;
                            4:if(!S_partition_found && (I_buffer_data==8'h0b || I_buffer_data==8'h0c ||
                                I_buffer_data==8'h1b || I_buffer_data==8'h1c)) begin
                                S_partition_found<=1; S_partition_boot<=S_entry_boot;
                                S_candidate_index<=S_entry_index;
                            end
                            8,9,10,11:if(S_partition_found && S_entry_index==S_candidate_index)
                                S_partition_start[(S_partition_offset[3:0]-8)*8+:8]<=I_buffer_data;
                            12,13,14,15:if(S_partition_found && S_entry_index==S_candidate_index)
                                S_partition_size[(S_partition_offset[3:0]-12)*8+:8]<=I_buffer_data;
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
                    else S_state<=SELECT_PARTITION;
                end
                SELECT_PARTITION: begin
                    if(!S_partition_found) finish(8'd4);
                    else if((S_partition_boot!=0 && S_partition_boot!=8'h80) ||
                        S_partition_start==0 || S_partition_size==0 ||
                        S_selected_partition_end>{31'd0,S_capacity}) finish(8'd5);
                    else begin
                        S_partition_lba<=S_partition_start;
                        S_partition_length<={1'b0,S_partition_size};
                        O_read_lba<=S_partition_start;
                        S_partition_sector<=1; S_state<=FETCH;
                    end
                end
                VALIDATE: begin
                    if(S_signature!=16'haa55 || (S_jump!=8'heb && S_jump!=8'he9) || S_bps!=512 ||
                        S_root_entries!=0 || S_fat16!=0 || S_version!=0) finish(8'd3);
                    else if(!S_spc_valid || S_reserved==0 || (S_fats!=1 && S_fats!=2) || S_fat_size==0 ||
                        (S_flags[7] && S_flags[3:0]>=S_fats)) finish(8'd6);
                    else S_state<=GEO_PREP;
                end
                GEO_PREP:S_state<=GEO_BASES;
                GEO_BASES:S_state<=GEO_SUB;
                GEO_SUB:S_state<=GEO_CLUSTERS;
                GEO_CLUSTERS:S_state<=GEO_LIMITS;
                GEO_LIMITS:S_state<=GEO_CHECK;
                GEO_CHECK:S_state<=VALIDATE_FINAL;
                VALIDATE_FINAL: begin
                    if(|S_geometry_bad) finish(8'd6);
                    else if(S_address_bad) finish(8'd5);
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




