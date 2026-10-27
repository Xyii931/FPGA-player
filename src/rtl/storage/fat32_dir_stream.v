// Read checked directory bytes across a bounded, possibly fragmented chain.
// The owner stops this stream when the parser sees 00 or path lookup succeeds.
module fat32_dir_stream (
    input wire I_clk,I_reset,I_mounted,
    input wire [31:0] I_fat_lba,I_data_lba,I_cluster_count,
    input wire [2:0] I_cluster_shift,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [31:0] I_first_cluster,I_sector_budget,
    input wire I_stop,I_cancel,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output reg [7:0] O_byte_data,
    output wire O_end_valid,
    input wire I_end_ready,
    output reg [7:0] O_error,
    output reg [3:0] O_storage_error,
    output reg [31:0] O_sectors,
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
    // Shared FAT chain walker interface (owned by lean_media_source).
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
    localparam [3:0] IDLE=0,PREPARE=1,READ_SEND=2,READ_WAIT=3,ADDRESS=4,LATCH=5,
        BYTE_OUT=6,WALK_START=7,WALK_WAIT=8,RESULT=9,SETUP_END=10,SETUP_LBA=11,
        WALK_CHECK=12,WALK_UPDATE=13,SETUP_OFFSET=14;
    reg [3:0] S_state;
    reg [31:0] S_current,S_first,S_budget,S_tortoise,S_power,S_lam,S_hops;
    reg [36:0] S_end_lba,S_cluster_lba;
    reg [6:0] S_sector;
    reg [8:0] S_byte;
    reg S_stopped,S_canceled,S_lost;
    reg [31:0] S_next_cluster;
    reg [7:0] S_next_error;
    reg S_next_eoc;
    wire S_stop=S_stopped || I_stop;
    wire S_cancel=S_canceled || I_cancel;
    wire S_invalid=S_lost || !I_mounted;
    wire S_walk_owner=S_state==WALK_START || S_state==WALK_WAIT;
    wire S_walk_ready=I_walk_start_ready;
    wire S_walk_result=I_walk_result_valid;
    wire S_walk_eoc=I_walk_eoc;
    wire [31:0] S_walk_cluster=I_walk_cluster;
    wire [31:0] S_walk_hops=I_walk_hops;
    wire [31:0] S_walk_lba=I_walk_read_lba;
    wire [7:0] S_walk_error=I_walk_error;
    wire [3:0] S_walk_storage_error=I_walk_storage_error;
    wire S_walk_valid=I_walk_read_valid;
    wire S_walk_abort=I_walk_read_abort;
    wire S_walk_result_ready=I_walk_read_result_ready;
    wire [8:0] S_walk_address=I_walk_address;
    // Cluster count <= 0x0fffffee and shift <= 7, so the sector offsets fit
    // in 36 bits. LBA arithmetic stays 37 bits: a wider result would already
    // fail the 32-bit volume-address check.
    wire [35:0] S_end_offset=({4'd0,I_cluster_count}<<I_cluster_shift);
    wire [35:0] S_cluster_offset=({4'd0,S_current}-36'd2)<<I_cluster_shift;
    wire [36:0] S_lba_c=S_cluster_lba+{30'd0,S_sector};
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_end_valid=!I_reset && S_state==RESULT;
    assign O_byte_valid=!I_reset && S_state==BYTE_OUT && !S_stop && !S_cancel && !S_invalid;
    assign O_read_valid=S_walk_owner ? S_walk_valid :
        (!I_reset && S_state==READ_SEND && !S_stop && !S_cancel && !S_invalid);
    assign O_read_lba=S_walk_owner ? S_walk_lba : S_lba_c[31:0];
    assign O_read_abort=S_walk_owner ? S_walk_abort :
        (S_state==READ_WAIT && (S_stop || S_cancel || S_invalid));
    assign O_read_result_ready=S_walk_owner ? S_walk_result_ready : (!I_reset && S_state==READ_WAIT);
    assign O_buffer_address=S_walk_owner ? S_walk_address : S_byte;
    assign O_walk_start=S_state==WALK_START && S_hops<I_cluster_count && !S_stop && !S_cancel && !S_invalid;
    assign O_walk_mounted=I_mounted && !S_lost;
    assign O_walk_cancel=S_stop || S_cancel;
    assign O_walk_first=S_current;
    assign O_walk_target=32'd1;
    assign O_walk_hop_limit=I_cluster_count;
    assign O_walk_result_ready=S_state==WALK_WAIT;
    assign O_walk_read_ready=I_read_ready && S_walk_owner;
    assign O_walk_read_result_valid=I_read_result_valid && S_walk_owner;
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_current<=0; S_first<=0; S_budget<=0; S_tortoise<=0;
            S_power<=1; S_lam<=0; S_hops<=0; S_sector<=0; S_byte<=0;
            S_end_lba<=0; S_cluster_lba<=0;
            S_stopped<=0; S_canceled<=0; S_lost<=0;
            S_next_cluster<=0; S_next_error<=0; S_next_eoc<=0;
            O_byte_data<=0; O_error<=0; O_storage_error<=0; O_sectors<=0;
        end else begin
            if(S_state!=IDLE && S_state!=RESULT) begin
                if(I_stop) S_stopped<=1;
                if(I_cancel) S_canceled<=1;
                if(!I_mounted) S_lost<=1;
            end
            case(S_state)
                IDLE: if(I_start_valid) begin
                    S_current<=I_first_cluster; S_first<=I_first_cluster; S_budget<=I_sector_budget;
                    S_tortoise<=I_first_cluster; S_power<=1; S_lam<=0; S_hops<=0; S_sector<=0; S_byte<=0;
                    S_stopped<=0; S_canceled<=0; S_lost<=0; O_error<=0; O_storage_error<=0; O_sectors<=0;
                    if(!I_mounted) finish(8'd1);
                    else if(I_cancel) finish(8'd8);
                    else if(I_stop) finish(8'd0);
                    else if(I_first_cluster<2 || I_first_cluster>I_cluster_count+32'd1 ||
                        I_cluster_count==0 || I_cluster_count>32'h0fffffee) finish(8'd9);
                    else if(I_sector_budget==0) finish(8'd10);
                    else S_state<=SETUP_END;
                end
                SETUP_END: begin
                    S_end_lba<={5'd0,I_data_lba}+{1'b0,S_end_offset};
                    S_state<=SETUP_OFFSET;
                end
                SETUP_OFFSET: begin
                    // Compute cluster subtraction/shift before the base add.
                    S_cluster_lba<={1'b0,S_cluster_offset};
                    S_state<=SETUP_LBA;
                end
                SETUP_LBA: begin
                    S_cluster_lba<={5'd0,I_data_lba}+S_cluster_lba;
                    S_state<=PREPARE;
                end
                PREPARE: if(O_sectors>=S_budget) finish(8'd10);
                    else if(|S_lba_c[36:32] || S_lba_c>=S_end_lba) finish(8'd9);
                    else S_state<=READ_SEND;
                READ_SEND: if(O_read_valid && I_read_ready) S_state<=READ_WAIT;
                READ_WAIT: if(I_read_result_valid) begin
                    O_storage_error<=I_storage_error;
                    if(S_invalid) finish(8'd1);
                    else if(S_cancel) finish(8'd8);
                    else if(S_stop) finish(8'd0);
                    else if(I_read_error!=0) finish(8'd2);
                    else begin O_sectors<=O_sectors+32'd1; S_byte<=0; S_state<=ADDRESS; end
                end
                ADDRESS:S_state<=LATCH;
                LATCH:begin O_byte_data<=I_buffer_data; S_state<=BYTE_OUT; end
                BYTE_OUT: if(I_byte_ready) begin
                    if(S_byte!=511) begin S_byte<=S_byte+9'd1; S_state<=ADDRESS; end
                    else if({1'b0,S_sector}+8'd1==(8'd1<<I_cluster_shift)) begin
                        S_sector<=0; S_state<=WALK_START;
                    end else begin S_sector<=S_sector+7'd1; S_state<=PREPARE; end
                end
                WALK_START: if(S_hops>=I_cluster_count) finish(8'd10);
                    else if(S_walk_ready) S_state<=WALK_WAIT;
                WALK_WAIT: if(S_walk_result) begin
                    O_storage_error<=S_walk_storage_error;
                    S_next_cluster<=S_walk_cluster; S_next_error<=S_walk_error; S_next_eoc<=S_walk_eoc;
                    S_state<=WALK_CHECK;
                end
                WALK_CHECK: begin
                    if(S_invalid) finish(8'd1);
                    else if(S_cancel) finish(8'd8);
                    else if(S_stop) finish(8'd0);
                    else if(S_next_error!=0) finish(S_next_error);
                    else if(S_next_eoc) finish(8'd0);
                    else if(S_next_cluster==S_first || S_next_cluster==S_tortoise) finish(8'd9);
                    else S_state<=WALK_UPDATE;
                end
                WALK_UPDATE: begin
                    // A loop-counter carry/compare must not also gate the
                    // directory error, shared walker and SD command enables.
                    S_current<=S_next_cluster; S_hops<=S_hops+32'd1;
                    if(S_lam+32'd1==S_power) begin S_tortoise<=S_next_cluster; S_power<=S_power<<1; S_lam<=0; end
                    else S_lam<=S_lam+32'd1;
                    S_state<=SETUP_OFFSET;
                end
                RESULT:if(I_end_ready) S_state<=IDLE;
                default:finish(8'd3);
            endcase
            if(S_state!=IDLE && S_state!=RESULT && S_state!=READ_WAIT && S_state!=WALK_WAIT) begin
                if(S_invalid) finish(8'd1);
                else if(S_cancel) finish(8'd8);
                else if(S_stop) finish(8'd0);
            end
        end
    end
endmodule
