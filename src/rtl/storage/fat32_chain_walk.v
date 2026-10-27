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
        ENTRY_ADDRESS=4,ENTRY_BYTE=5,CHECK_ENTRY=6,RESULT=7,READ_CHECK=8,CHECK_START=9,
        ADVANCE_ENTRY=10;
    reg [3:0] S_state;
    reg [31:0] S_fat_lba,S_count,S_first,S_target,S_limit,S_current;
    reg [31:0] S_cache_lba,S_entry,S_tortoise,S_power,S_lam;
    reg [31:0] S_last_cluster;
    reg [1:0] S_entry_byte;
    reg S_cache_valid,S_canceled,S_lost;
    reg [7:0] S_read_error;
    reg S_at_target,S_checkpoint_due;
    wire [32:0] S_entry_lba={1'b0,S_fat_lba}+{8'd0,S_current[31:7]};
    wire [31:0] S_next={4'd0,S_entry[27:0]};
    // Zero-latency equivalent of the EOC/reserved checks: >= 0x0FFFFFF0 means
    // bit [31:28] nonzero or bits [27:4] all ones. EOC additionally requires
    // bits [3:0] >= 8. Sharing this chain halves the wide-compare cost.
    wire S_next_high_bad=(|S_next[31:28]) || (&S_next[27:4]);
    wire S_next_eoc=S_next_high_bad && S_next[3:0]>=4'd8;
    wire S_next_lt2=!(|S_next[31:1]);
    wire S_next_over=S_next>S_last_cluster;
    wire S_next_loop=S_next==S_tortoise || S_next==S_first;
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
            S_last_cluster<=0;
            S_cache_valid<=0; S_canceled<=0; S_lost<=0; S_read_error<=0;
            S_at_target<=0; S_checkpoint_due<=0;
            O_cluster<=0; O_hops<=0; O_eoc<=0; O_error<=0; O_storage_error<=0;
        end else begin
            if(S_state!=IDLE && S_state!=RESULT) begin
                if(I_cancel) S_canceled<=1;
                if(!I_mounted) S_lost<=1;
            end
            case(S_state)
                IDLE: if(I_start_valid) begin
                    S_fat_lba<=I_fat_lba; S_count<=I_cluster_count; S_first<=I_first_cluster;
                    S_target<=I_target_index; S_limit<=I_hop_limit;
                    S_last_cluster<=I_cluster_count+32'd1;
                    S_current<=I_first_cluster; S_tortoise<=I_first_cluster; S_power<=1; S_lam<=0;
                    S_cache_valid<=0; S_canceled<=0; S_lost<=0; S_entry_byte<=0;
                    O_cluster<=I_first_cluster; O_hops<=0; O_eoc<=0; O_error<=0; O_storage_error<=0;
                    S_state<=CHECK_START;
                end
                CHECK_START: begin
                    // Validate a captured request, not the mount/share mux and
                    // its count+1 arithmetic in the same command-accept cycle.
                    S_limit<=S_limit<S_count ? S_limit : S_count;
                    if(S_count==0 || S_count>32'h0fffffee || S_first<2 ||
                        S_first>S_last_cluster) finish(8'd9);
                    else if(S_limit==0 || S_target>=S_count || S_target>S_limit) finish(8'd10);
                    else if(S_target==0) finish(8'd0);
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
                    S_read_error<=I_read_error; S_state<=READ_CHECK;
                end
                READ_CHECK: begin
                    if(S_lost || !I_mounted || S_read_error==1) finish(8'd1);
                    else if(S_canceled || I_cancel || S_read_error==8) finish(8'd8);
                    else if(S_read_error!=0) finish(8'd2);
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
                    // Keep entry classification out of the enables for every
                    // cluster/checkpoint register; arithmetic retires next cycle.
                    S_at_target<=O_hops+32'd1==S_target;
                    S_checkpoint_due<=S_lam+32'd1==S_power;
                    if(S_next_eoc) begin O_eoc<=1; finish(8'd0); end
                    else if(S_next_lt2 || S_next_high_bad || S_next_over ||
                        S_next==S_current || S_next_loop) finish(8'd9);
                    else S_state<=ADVANCE_ENTRY;
                end
                ADVANCE_ENTRY: begin
                    S_current<=S_next; O_cluster<=S_next; O_hops<=O_hops+32'd1;
                    if(S_checkpoint_due) begin
                        S_tortoise<=S_next; S_power<=S_power<<1; S_lam<=0;
                    end else S_lam<=S_lam+32'd1;
                    if(S_at_target) finish(8'd0);
                    else S_state<=NEED_FAT;
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

// One chain walker shared by the directory scan and the file reader. The two
// owners are active in different media-source phases; a busy latch keeps a new
// owner from changing the walker inputs mid-operation.
module fat32_chain_share (
    input wire I_clk,I_reset,
    input wire [31:0] I_fat_lba,I_cluster_count,
    input wire [7:0] I_buffer_data,
    input wire [7:0] I_read_error,
    input wire [3:0] I_storage_error,
    // Directory side
    input wire D_start,D_mounted,D_cancel,D_result_ready,D_read_ready,D_read_result_valid,
    input wire [31:0] D_first,D_target,D_hop_limit,
    output wire D_start_ready,D_result_valid,D_eoc,D_read_valid,D_read_abort,D_read_result_ready,
    output wire [31:0] D_cluster,D_hops,D_lba,
    output wire [7:0] D_error,
    output wire [3:0] D_storage_error,
    output wire [8:0] D_address,
    // File side
    input wire F_start,F_mounted,F_cancel,F_result_ready,F_read_ready,F_read_result_valid,
    input wire [31:0] F_first,F_target,F_hop_limit,
    output wire F_start_ready,F_result_valid,F_eoc,F_read_valid,F_read_abort,F_read_result_ready,
    output wire [31:0] F_cluster,F_hops,F_lba,
    output wire [7:0] F_error,
    output wire [3:0] F_storage_error,
    output wire [8:0] F_address
);
    reg S_busy,S_owner,S_launch;
    reg [31:0] S_first,S_target,S_limit;
    wire S_sel=S_owner;
    wire S_req=!I_reset && !S_busy && (D_start || F_start);
    wire S_walk_ready,S_walk_result,S_walk_eoc;
    wire [31:0] S_walk_cluster,S_walk_hops,S_walk_lba;
    wire [7:0] S_walk_error;
    wire [3:0] S_walk_storage_error;
    wire S_walk_read_valid,S_walk_read_abort,S_walk_read_result_ready;
    wire [8:0] S_walk_address;
    wire S_result_ready=S_sel ? F_result_ready : D_result_ready;
    wire S_read_ready=S_sel ? F_read_ready : D_read_ready;
    wire S_read_result_valid=S_sel ? F_read_result_valid : D_read_result_valid;
    wire S_start_accept=S_req;
    wire S_result_take=S_walk_result && S_result_ready;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_busy<=0; S_owner<=0; S_launch<=0; S_first<=0; S_target<=0; S_limit<=0;
        end else begin
            if(S_start_accept) begin
                S_busy<=1; S_owner<=!D_start; S_launch<=1;
                S_first<=D_start ? D_first : F_first;
                S_target<=D_start ? D_target : F_target;
                S_limit<=D_start ? D_hop_limit : F_hop_limit;
            end
            if(S_launch && S_walk_ready) S_launch<=0;
            if(S_result_take) S_busy<=0;
        end
    end
    fat32_chain_walk u_walk (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(S_sel ? F_mounted : D_mounted),
        .I_fat_lba(I_fat_lba),.I_cluster_count(I_cluster_count),
        .I_start_valid(S_launch),.O_start_ready(S_walk_ready),
        .I_first_cluster(S_first),
        .I_target_index(S_target),
        .I_hop_limit(S_limit),
        .I_cancel(S_sel ? F_cancel : D_cancel),
        .O_result_valid(S_walk_result),.I_result_ready(S_result_ready),
        .O_cluster(S_walk_cluster),.O_hops(S_walk_hops),.O_eoc(S_walk_eoc),
        .O_error(S_walk_error),.O_storage_error(S_walk_storage_error),
        .O_read_valid(S_walk_read_valid),.I_read_ready(S_read_ready),
        .O_read_lba(S_walk_lba),.O_read_abort(S_walk_read_abort),
        .I_read_result_valid(S_read_result_valid),.O_read_result_ready(S_walk_read_result_ready),
        .I_read_error(I_read_error),.I_storage_error(I_storage_error),
        .O_buffer_address(S_walk_address),.I_buffer_data(I_buffer_data));
    assign D_start_ready=!I_reset && !S_busy;
    assign F_start_ready=!I_reset && !S_busy && !D_start;
    assign D_result_valid=S_walk_result && !S_owner;
    assign F_result_valid=S_walk_result && S_owner;
    assign D_eoc=S_walk_eoc; assign F_eoc=S_walk_eoc;
    assign D_cluster=S_walk_cluster; assign F_cluster=S_walk_cluster;
    assign D_hops=S_walk_hops; assign F_hops=S_walk_hops;
    assign D_error=S_walk_error; assign F_error=S_walk_error;
    assign D_storage_error=S_walk_storage_error; assign F_storage_error=S_walk_storage_error;
    assign D_read_valid=S_walk_read_valid && !S_owner;
    assign F_read_valid=S_walk_read_valid && S_owner;
    assign D_lba=S_walk_lba; assign F_lba=S_walk_lba;
    assign D_read_abort=S_walk_read_abort; assign F_read_abort=S_walk_read_abort;
    assign D_read_result_ready=S_walk_read_result_ready;
    assign F_read_result_ready=S_walk_read_result_ready;
    assign D_address=S_walk_address; assign F_address=S_walk_address;
endmodule
