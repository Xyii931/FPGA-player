// Bounded lookup of the Nth cluster in a FAT32 chain. This is not file I/O.
// The checked sector port and its buffer belong exclusively to this operation.
module fat32_chain_walk (
    input wire I_clk,I_reset,I_mounted,
    input wire [31:0] I_fat_lba,I_cluster_count,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_first_cluster,I_target_index,I_hop_limit,
    input wire I_cancel,
    output wire O_result_valid,
    input wire I_result_ready,
    output reg [31:0] O_cluster,O_hops,
    output reg O_eoc,
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
    localparam [3:0] IDLE=0,NEED_FAT=1,READ_SEND=2,READ_WAIT=3,
        ENTRY_ADDRESS=4,ENTRY_BYTE=5,CHECK_ENTRY=6,RESULT=7;
    reg [3:0] S_state;
    reg [31:0] S_fat_lba,S_count,S_first,S_target,S_limit,S_current;
    reg [31:0] S_cache_lba,S_entry,S_tortoise,S_power,S_lam;
    reg [1:0] S_entry_byte;
    reg S_cache_valid,S_canceled,S_lost;
    wire [32:0] S_entry_lba={1'b0,S_fat_lba}+{8'd0,S_current[31:7]};
    wire [31:0] S_next={4'd0,S_entry[27:0]};
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_result_valid=!I_reset && S_state==RESULT;
    assign O_read_valid=!I_reset && I_mounted && S_state==READ_SEND && !S_canceled && !I_cancel;
    assign O_read_lba=S_entry_lba[31:0];
    assign O_read_abort=S_state==READ_WAIT && (S_canceled || I_cancel || S_lost || !I_mounted);
    assign O_read_result_ready=!I_reset && S_state==READ_WAIT;
    assign O_buffer_address={S_current[6:0],2'b00}+{7'd0,S_entry_byte};
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_fat_lba<=0; S_count<=0; S_first<=0; S_target<=0; S_limit<=0; S_current<=0;
            S_cache_lba<=0; S_entry<=0; S_tortoise<=0; S_power<=1; S_lam<=0; S_entry_byte<=0;
            S_cache_valid<=0; S_canceled<=0; S_lost<=0;
            O_cluster<=0; O_hops<=0; O_eoc<=0; O_error<=0; O_storage_error<=0;
        end else begin
            if(S_state!=IDLE && S_state!=RESULT) begin
                if(I_cancel) S_canceled<=1;
                if(!I_mounted) S_lost<=1;
            end
            case(S_state)
                IDLE: if(I_start_valid) begin
                    S_fat_lba<=I_fat_lba; S_count<=I_cluster_count; S_first<=I_first_cluster;
                    S_target<=I_target_index; S_limit<=I_hop_limit<I_cluster_count ? I_hop_limit : I_cluster_count;
                    S_current<=I_first_cluster; S_tortoise<=I_first_cluster; S_power<=1; S_lam<=0;
                    S_cache_valid<=0; S_canceled<=0; S_lost<=0; S_entry_byte<=0;
                    O_cluster<=I_first_cluster; O_hops<=0; O_eoc<=0; O_error<=0; O_storage_error<=0;
                    if(!I_mounted) finish(8'd1);
                    else if(I_cancel) finish(8'd8);
                    else if(I_cluster_count==0 || I_cluster_count>32'h0fffffee || I_first_cluster<2 ||
                        {1'b0,I_first_cluster}>{1'b0,I_cluster_count}+33'd1) finish(8'd9);
                    else if(I_hop_limit==0 || I_target_index>=I_cluster_count || I_target_index>I_hop_limit) finish(8'd10);
                    else if(I_target_index==0) finish(8'd0);
                    else S_state<=NEED_FAT;
                end
                NEED_FAT: begin
                    if(O_hops>=S_limit) finish(8'd10);
                    else if(S_entry_lba[32]) finish(8'd9);
                    else if(S_cache_valid && S_cache_lba==S_entry_lba[31:0]) begin
                        S_entry_byte<=0; S_state<=ENTRY_ADDRESS;
                    end else S_state<=READ_SEND;
                end
                READ_SEND: if(O_read_valid && I_read_ready) S_state<=READ_WAIT;
                READ_WAIT: if(I_read_result_valid) begin
                    O_storage_error<=I_storage_error;
                    if(S_lost || !I_mounted || I_read_error==1) finish(8'd1);
                    else if(S_canceled || I_cancel || I_read_error==8) finish(8'd8);
                    else if(I_read_error!=0) finish(8'd2);
                    else begin
                        S_cache_valid<=1; S_cache_lba<=S_entry_lba[31:0]; S_entry_byte<=0; S_state<=ENTRY_ADDRESS;
                    end
                end
                ENTRY_ADDRESS: S_state<=ENTRY_BYTE;
                ENTRY_BYTE: begin
                    S_entry[S_entry_byte*8+:8]<=I_buffer_data;
                    if(S_entry_byte==3) S_state<=CHECK_ENTRY;
                    else begin S_entry_byte<=S_entry_byte+2'd1; S_state<=ENTRY_ADDRESS; end
                end
                CHECK_ENTRY: begin
                    if(S_next>=32'h0ffffff8) begin O_eoc<=1; finish(8'd0); end
                    else if(S_next<2 || S_next>=32'h0ffffff0 || S_next>S_count+32'd1 ||
                        S_next==S_current || S_next==S_tortoise || S_next==S_first) finish(8'd9);
                    else begin
                        S_current<=S_next; O_cluster<=S_next; O_hops<=O_hops+32'd1;
                        if(S_lam+32'd1==S_power) begin
                            S_tortoise<=S_next; S_power<=S_power<<1; S_lam<=0;
                        end else S_lam<=S_lam+32'd1;
                        if(O_hops+32'd1==S_target) finish(8'd0);
                        else S_state<=NEED_FAT;
                    end
                end
                RESULT: if(I_result_ready) S_state<=IDLE;
                default:finish(8'd9);
            endcase
            // READ_WAIT must retire its submitted physical/CDC transaction first.
            if(S_state!=IDLE && S_state!=RESULT && S_state!=READ_WAIT) begin
                if(S_lost || !I_mounted) finish(8'd1);
                else if(S_canceled || I_cancel) finish(8'd8);
            end
        end
    end
endmodule
