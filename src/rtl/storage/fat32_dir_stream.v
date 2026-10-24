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
    input wire [7:0] I_buffer_data
);
    localparam [3:0] IDLE=0,PREPARE=1,READ_SEND=2,READ_WAIT=3,ADDRESS=4,LATCH=5,
        BYTE_OUT=6,WALK_START=7,WALK_WAIT=8,RESULT=9;
    reg [3:0] S_state;
    reg [31:0] S_current,S_first,S_budget,S_tortoise,S_power,S_lam,S_hops;
    reg [6:0] S_sector;
    reg [8:0] S_byte;
    reg S_stopped,S_canceled,S_lost;
    wire S_stop=S_stopped || I_stop;
    wire S_cancel=S_canceled || I_cancel;
    wire S_invalid=S_lost || !I_mounted;
    wire S_walk_owner=S_state==WALK_START || S_state==WALK_WAIT;
    wire S_walk_ready,S_walk_result,S_walk_eoc,S_walk_valid,S_walk_abort,S_walk_result_ready;
    wire [31:0] S_walk_cluster,S_walk_hops,S_walk_lba;
    wire [7:0] S_walk_error;
    wire [3:0] S_walk_storage_error;
    wire [8:0] S_walk_address;
    wire [63:0] S_lba={32'd0,I_data_lba}+(({32'd0,S_current}-64'd2)<<I_cluster_shift)+{57'd0,S_sector};
    wire [63:0] S_data_end={32'd0,I_data_lba}+({32'd0,I_cluster_count}<<I_cluster_shift);
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_end_valid=!I_reset && S_state==RESULT;
    assign O_byte_valid=!I_reset && S_state==BYTE_OUT && !S_stop && !S_cancel && !S_invalid;
    assign O_read_valid=S_walk_owner ? S_walk_valid :
        (!I_reset && S_state==READ_SEND && !S_stop && !S_cancel && !S_invalid);
    assign O_read_lba=S_walk_owner ? S_walk_lba : S_lba[31:0];
    assign O_read_abort=S_walk_owner ? S_walk_abort :
        (S_state==READ_WAIT && (S_stop || S_cancel || S_invalid));
    assign O_read_result_ready=S_walk_owner ? S_walk_result_ready : (!I_reset && S_state==READ_WAIT);
    assign O_buffer_address=S_walk_owner ? S_walk_address : S_byte;
    fat32_chain_walk u_walk (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(I_mounted && !S_lost),.I_fat_lba(I_fat_lba),.I_cluster_count(I_cluster_count),
        .I_start_valid(S_state==WALK_START && S_hops<I_cluster_count && !S_stop && !S_cancel && !S_invalid),
        .O_start_ready(S_walk_ready),
        .I_first_cluster(S_current),.I_target_index(32'd1),.I_hop_limit(I_cluster_count),.I_cancel(S_stop || S_cancel),
        .O_result_valid(S_walk_result),.I_result_ready(S_state==WALK_WAIT),.O_cluster(S_walk_cluster),.O_hops(S_walk_hops),
        .O_eoc(S_walk_eoc),.O_error(S_walk_error),.O_storage_error(S_walk_storage_error),
        .O_read_valid(S_walk_valid),.I_read_ready(I_read_ready && S_walk_owner),.O_read_lba(S_walk_lba),.O_read_abort(S_walk_abort),
        .I_read_result_valid(I_read_result_valid && S_walk_owner),.O_read_result_ready(S_walk_result_ready),
        .I_read_error(I_read_error),.I_storage_error(I_storage_error),.O_buffer_address(S_walk_address),.I_buffer_data(I_buffer_data));
    task finish;
        input [7:0] error_code;
        begin O_error<=error_code; S_state<=RESULT; end
    endtask
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_current<=0; S_first<=0; S_budget<=0; S_tortoise<=0;
            S_power<=1; S_lam<=0; S_hops<=0; S_sector<=0; S_byte<=0;
            S_stopped<=0; S_canceled<=0; S_lost<=0;
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
                    else S_state<=PREPARE;
                end
                PREPARE: if(O_sectors>=S_budget) finish(8'd10);
                    else if(S_lba>=S_data_end || S_lba>64'hffffffff) finish(8'd9);
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
                    if(S_invalid) finish(8'd1);
                    else if(S_cancel) finish(8'd8);
                    else if(S_stop) finish(8'd0);
                    else if(S_walk_error!=0) finish(S_walk_error);
                    else if(S_walk_eoc) finish(8'd0);
                    else if(S_walk_cluster==S_first || S_walk_cluster==S_tortoise) finish(8'd9);
                    else begin
                        S_current<=S_walk_cluster; S_hops<=S_hops+32'd1;
                        if(S_lam+32'd1==S_power) begin S_tortoise<=S_walk_cluster; S_power<=S_power<<1; S_lam<=0; end
                        else S_lam<=S_lam+32'd1;
                        S_state<=PREPARE;
                    end
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
