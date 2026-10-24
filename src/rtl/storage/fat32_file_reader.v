// Three independently opened descriptors and one checked-sector engine.
// Path lookup supplies descriptors. Cancellation never flushes storage CDC.
module fat32_file_reader (
    input wire I_clk,I_reset,I_mounted,
    input wire [31:0] I_fat_lba,I_data_lba,I_cluster_count,
    input wire [2:0] I_cluster_shift,
    input wire I_load_valid,
    output wire O_load_ready,
    input wire [1:0] I_load_context,
    input wire [31:0] I_first_cluster,I_file_size,
    output reg O_load_result_valid,
    input wire I_load_result_ready,
    output reg [1:0] O_load_context,
    output reg [7:0] O_load_error,
    input wire I_close_valid,
    output wire O_close_ready,
    input wire [1:0] I_close_context,
    input wire I_read_valid,
    output wire O_read_ready,
    input wire [1:0] I_read_context,I_read_priority,
    input wire [31:0] I_offset,I_length,
    input wire [15:0] I_epoch,
    input wire [2:0] I_urgent_context,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output reg [7:0] O_byte_data,
    output wire [1:0] O_byte_context,
    output wire [15:0] O_byte_epoch,
    output wire [31:0] O_byte_offset,
    output wire O_byte_last,
    output reg O_done_valid,
    input wire I_done_ready,
    output reg [1:0] O_done_context,
    output reg [15:0] O_done_epoch,
    output reg [31:0] O_done_bytes,
    output reg O_done_eof,
    output reg [7:0] O_done_error,
    output reg [3:0] O_done_storage_error,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_epoch,
    output reg O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output wire [1:0] O_cancel_done_context,
    output wire [15:0] O_cancel_done_epoch,
    // Exclusive ownership of fat32_sector_port's checked command and RAM port.
    output wire O_sector_valid,
    input wire I_sector_ready,
    output wire [31:0] O_sector_lba,
    output wire [1:0] O_sector_context,O_sector_priority,
    output wire O_sector_abort,
    input wire I_sector_result_valid,
    output wire O_sector_result_ready,
    input wire [7:0] I_sector_error,
    input wire [3:0] I_sector_storage_error,
    output wire [8:0] O_buffer_address,
    input wire [7:0] I_buffer_data
);
    localparam [3:0] SCHEDULE=0,PREPARE=1,WALK_START=2,WALK_WAIT=3,
        DATA_SEND=4,DATA_WAIT=5,DATA_ADDRESS=6,DATA_LATCH=7,DATA_OUT=8;
    reg [3:0] S_state;
    reg [2:0] S_open,S_pending,S_terminal,S_canceled,S_lost;
    reg [31:0] S_first[0:2],S_size[0:2],S_cursor[0:2],S_remaining[0:2],S_requested[0:2];
    reg [31:0] S_checkpoint[0:2],S_checkpoint_index[0:2],S_tortoise[0:2],S_power[0:2],S_lam[0:2];
    reg [15:0] S_epoch[0:2];
    reg [1:0] S_priority[0:2];
    reg [7:0] S_error[0:2];
    reg [3:0] S_storage_error[0:2];
    reg [1:0] S_active,S_rr,S_pick,S_terminal_pick;
    reg S_pick_found,S_terminal_found,S_cancel_pending;
    reg [1:0] S_cancel_context;
    reg [15:0] S_cancel_epoch;
    reg [2:0] S_best,S_score;
    integer S_i,S_candidate;
    wire S_cancel_accept=I_cancel_valid && O_cancel_ready;
    wire S_cancel_active=S_cancel_accept && I_cancel_context==S_active && I_cancel_epoch==S_epoch[S_active];
    wire S_stop=S_canceled[S_active] || S_cancel_active;
    wire S_lost_active=S_lost[S_active] || !I_mounted;
    wire [31:0] S_target_index=S_cursor[S_active]>>(5'd9+{2'd0,I_cluster_shift});
    reg [31:0] S_walk_first,S_walk_target,S_walk_base_index;
    wire S_walk_owner=S_state==WALK_START || S_state==WALK_WAIT;
    wire S_walk_ready,S_walk_result_valid,S_walk_eoc;
    wire [31:0] S_walk_cluster,S_walk_hops,S_walk_lba;
    wire [7:0] S_walk_error;
    wire [3:0] S_walk_storage_error;
    wire S_walk_read_valid,S_walk_read_abort,S_walk_read_result_ready;
    wire [8:0] S_walk_address;
    wire [31:0] S_sector_in_cluster=(S_cursor[S_active]>>9)&((32'd1<<I_cluster_shift)-32'd1);
    wire [63:0] S_data_address={32'd0,I_data_lba}+
        (({32'd0,S_checkpoint[S_active]}-64'd2)<<I_cluster_shift)+{32'd0,S_sector_in_cluster};
    wire [63:0] S_volume_data_end={32'd0,I_data_lba}+({32'd0,I_cluster_count}<<I_cluster_shift);
    wire [63:0] S_file_capacity={32'd0,I_cluster_count}<<(5'd9+{2'd0,I_cluster_shift});
    wire S_load_bad=I_load_context==3 || I_cluster_count==0 || I_cluster_count>32'h0fffffee ||
        {32'd0,I_file_size}>S_file_capacity ||
        (I_file_size!=0 && (I_first_cluster<2 || I_first_cluster>I_cluster_count+32'd1)) ||
        (I_file_size==0 && I_first_cluster!=0 && (I_first_cluster<2 || I_first_cluster>I_cluster_count+32'd1));

    assign O_cancel_ready=!I_reset && !S_cancel_pending && !O_cancel_done_valid;
    assign O_close_ready=!I_reset && I_close_context<3 && !S_pending[I_close_context] &&
        !S_terminal[I_close_context] && !I_cancel_valid;
    assign O_load_ready=!I_reset && I_mounted && (!O_load_result_valid || I_load_result_ready) &&
        (I_load_context==3 || (!S_pending[I_load_context] && !S_terminal[I_load_context])) &&
        !I_close_valid && !I_cancel_valid;
    assign O_read_ready=!I_reset && I_mounted && I_read_context<3 && !S_pending[I_read_context] &&
        !S_terminal[I_read_context] && !I_load_valid && !I_close_valid && !I_cancel_valid &&
        !(S_cancel_pending && I_read_context==S_cancel_context && I_epoch==S_cancel_epoch);
    assign O_cancel_done_context=S_cancel_context;
    assign O_cancel_done_epoch=S_cancel_epoch;
    assign O_byte_valid=!I_reset && S_state==DATA_OUT && !S_stop && !S_lost_active;
    assign O_byte_context=S_active;
    assign O_byte_epoch=S_epoch[S_active];
    assign O_byte_offset=S_cursor[S_active];
    assign O_byte_last=S_remaining[S_active]==1;
    assign O_sector_valid=S_walk_owner ? S_walk_read_valid :
        (!I_reset && S_state==DATA_SEND && !S_stop && !S_lost_active);
    assign O_sector_lba=S_walk_owner ? S_walk_lba : S_data_address[31:0];
    assign O_sector_context=S_active;
    assign O_sector_priority=S_priority[S_active];
    assign O_sector_abort=S_walk_owner ? S_walk_read_abort :
        (S_state==DATA_WAIT && (S_stop || S_lost_active));
    assign O_sector_result_ready=S_walk_owner ? S_walk_read_result_ready : (!I_reset && S_state==DATA_WAIT);
    assign O_buffer_address=S_walk_owner ? S_walk_address : S_cursor[S_active][8:0];
    fat32_chain_walk u_walk (
        .I_clk(I_clk),.I_reset(I_reset),.I_mounted(I_mounted && !S_lost[S_active]),
        .I_fat_lba(I_fat_lba),.I_cluster_count(I_cluster_count),
        .I_start_valid(S_state==WALK_START && !S_stop && !S_lost_active),.O_start_ready(S_walk_ready),
        .I_first_cluster(S_walk_first),.I_target_index(S_walk_target),.I_hop_limit(I_cluster_count),.I_cancel(S_stop),
        .O_result_valid(S_walk_result_valid),.I_result_ready(S_state==WALK_WAIT),
        .O_cluster(S_walk_cluster),.O_hops(S_walk_hops),.O_eoc(S_walk_eoc),.O_error(S_walk_error),.O_storage_error(S_walk_storage_error),
        .O_read_valid(S_walk_read_valid),.I_read_ready(I_sector_ready && S_walk_owner),.O_read_lba(S_walk_lba),.O_read_abort(S_walk_read_abort),
        .I_read_result_valid(I_sector_result_valid && S_walk_owner),.O_read_result_ready(S_walk_read_result_ready),
        .I_read_error(I_sector_error),.I_storage_error(I_sector_storage_error),.O_buffer_address(S_walk_address),.I_buffer_data(I_buffer_data));

    always @* begin
        S_pick_found=0; S_pick=0; S_best=0; S_score=0; S_candidate=0;
        S_terminal_found=0; S_terminal_pick=0;
        for(S_i=0;S_i<3;S_i=S_i+1) begin
            S_candidate=S_rr+S_i;
            if(S_candidate>=3) S_candidate=S_candidate-3;
            S_score={I_urgent_context[S_candidate],S_priority[S_candidate]};
            if(S_pending[S_candidate] && (!S_pick_found || S_score>S_best)) begin
                S_pick_found=1; S_pick=S_candidate; S_best=S_score;
            end
            if(S_terminal[S_i] && !S_terminal_found) begin S_terminal_found=1; S_terminal_pick=S_i; end
        end
    end
    task complete;
        input [7:0] error_code;
        begin S_error[S_active]<=error_code; S_pending[S_active]<=0; S_terminal[S_active]<=1; S_state<=SCHEDULE; end
    endtask
    integer S_reset_i;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=SCHEDULE; S_open<=0; S_pending<=0; S_terminal<=0; S_canceled<=0; S_lost<=0;
            S_active<=0; S_rr<=0; S_cancel_pending<=0; S_cancel_context<=0; S_cancel_epoch<=0;
            S_walk_first<=0; S_walk_target<=0; S_walk_base_index<=0;
            O_load_result_valid<=0; O_load_context<=0; O_load_error<=0; O_byte_data<=0;
            O_done_valid<=0; O_done_context<=0; O_done_epoch<=0; O_done_bytes<=0; O_done_eof<=0;
            O_done_error<=0; O_done_storage_error<=0; O_cancel_done_valid<=0;
            for(S_reset_i=0;S_reset_i<3;S_reset_i=S_reset_i+1) begin
                S_first[S_reset_i]<=0; S_size[S_reset_i]<=0; S_cursor[S_reset_i]<=0;
                S_remaining[S_reset_i]<=0; S_requested[S_reset_i]<=0; S_epoch[S_reset_i]<=0;
                S_priority[S_reset_i]<=0; S_error[S_reset_i]<=0; S_storage_error[S_reset_i]<=0;
                S_checkpoint[S_reset_i]<=0; S_checkpoint_index[S_reset_i]<=0;
                S_tortoise[S_reset_i]<=0; S_power[S_reset_i]<=1; S_lam[S_reset_i]<=0;
            end
        end else begin
            if(O_load_result_valid && I_load_result_ready) O_load_result_valid<=0;
            if(I_load_valid && O_load_ready) begin
                O_load_result_valid<=1; O_load_context<=I_load_context; O_load_error<=S_load_bad ? 8'd9 : 8'd0;
                if(I_load_context<3) begin
                    S_open[I_load_context]<=!S_load_bad;
                    if(!S_load_bad) begin
                        S_first[I_load_context]<=I_first_cluster; S_size[I_load_context]<=I_file_size;
                        S_checkpoint[I_load_context]<=I_first_cluster; S_checkpoint_index[I_load_context]<=0;
                        S_tortoise[I_load_context]<=I_first_cluster; S_power[I_load_context]<=1; S_lam[I_load_context]<=0;
                    end
                end
            end
            if(I_close_valid && O_close_ready) S_open[I_close_context]<=0;
            if(I_read_valid && O_read_ready) begin
                S_pending[I_read_context]<=1; S_canceled[I_read_context]<=0; S_lost[I_read_context]<=0;
                S_cursor[I_read_context]<=I_offset; S_epoch[I_read_context]<=I_epoch; S_priority[I_read_context]<=I_read_priority;
                S_error[I_read_context]<=!S_open[I_read_context] ? 8'd7 : (I_offset>S_size[I_read_context] ? 8'd11 : 8'd0);
                S_storage_error[I_read_context]<=0;
                if(I_offset>S_size[I_read_context]) begin S_remaining[I_read_context]<=0; S_requested[I_read_context]<=0; end
                else if(I_length>S_size[I_read_context]-I_offset) begin
                    S_remaining[I_read_context]<=S_size[I_read_context]-I_offset; S_requested[I_read_context]<=S_size[I_read_context]-I_offset;
                end else begin S_remaining[I_read_context]<=I_length; S_requested[I_read_context]<=I_length; end
            end
            if(S_cancel_accept) begin
                S_cancel_pending<=1; S_cancel_context<=I_cancel_context; S_cancel_epoch<=I_cancel_epoch;
                if(I_cancel_context<3 && S_pending[I_cancel_context] && S_epoch[I_cancel_context]==I_cancel_epoch)
                    S_canceled[I_cancel_context]<=1;
            end
            if(S_cancel_pending && !O_cancel_done_valid) begin
                if(S_cancel_context==3) O_cancel_done_valid<=1;
                else if(!((S_pending[S_cancel_context] || S_terminal[S_cancel_context]) &&
                    S_epoch[S_cancel_context]==S_cancel_epoch)) O_cancel_done_valid<=1;
            end
            if(O_cancel_done_valid && I_cancel_done_ready) begin O_cancel_done_valid<=0; S_cancel_pending<=0; end
            if(!O_done_valid && S_terminal_found) begin
                O_done_valid<=1; O_done_context<=S_terminal_pick; O_done_epoch<=S_epoch[S_terminal_pick];
                O_done_error<=S_error[S_terminal_pick]; O_done_storage_error<=S_storage_error[S_terminal_pick];
                O_done_bytes<=S_requested[S_terminal_pick]-S_remaining[S_terminal_pick];
                O_done_eof<=S_cursor[S_terminal_pick]==S_size[S_terminal_pick];
            end
            if(O_done_valid && I_done_ready) begin O_done_valid<=0; S_terminal[O_done_context]<=0; end
            if(!I_mounted) begin
                S_open<=0;
                for(S_reset_i=0;S_reset_i<3;S_reset_i=S_reset_i+1)
                    if(S_pending[S_reset_i]) S_lost[S_reset_i]<=1;
            end
            case(S_state)
                SCHEDULE: if(S_pick_found) begin
                    S_active<=S_pick; S_rr<=S_pick==2 ? 2'd0 : S_pick+2'd1; S_state<=PREPARE;
                end
                PREPARE: begin
                    if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else if(S_error[S_active]!=0) complete(S_error[S_active]);
                    else if(S_remaining[S_active]==0) complete(8'd0);
                    else if(S_target_index>=I_cluster_count) complete(8'd9);
                    else if(S_target_index==S_checkpoint_index[S_active]) begin
                        if(S_data_address>=S_volume_data_end || S_data_address>64'hffffffff) complete(8'd9);
                        else S_state<=DATA_SEND;
                    end else begin
                        if(S_target_index>S_checkpoint_index[S_active]) begin
                            S_walk_first<=S_checkpoint[S_active]; S_walk_target<=S_target_index-S_checkpoint_index[S_active];
                            S_walk_base_index<=S_checkpoint_index[S_active];
                        end else begin
                            S_walk_first<=S_first[S_active]; S_walk_target<=S_target_index; S_walk_base_index<=0;
                            S_tortoise[S_active]<=S_first[S_active]; S_power[S_active]<=1; S_lam[S_active]<=0;
                        end
                        S_state<=WALK_START;
                    end
                end
                WALK_START: if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else if(S_walk_ready) S_state<=WALK_WAIT;
                WALK_WAIT: if(S_walk_result_valid) begin
                    S_storage_error[S_active]<=S_walk_storage_error;
                    if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else if(S_walk_error!=0) complete(S_walk_error);
                    else if(S_walk_eoc) complete(8'd12);
                    else if(S_walk_target==1 && (S_walk_cluster==S_tortoise[S_active] || S_walk_cluster==S_first[S_active])) complete(8'd9);
                    else begin
                        S_checkpoint[S_active]<=S_walk_cluster; S_checkpoint_index[S_active]<=S_walk_base_index+S_walk_hops;
                        if(S_walk_target==1) begin
                            if(S_lam[S_active]+32'd1==S_power[S_active]) begin
                                S_tortoise[S_active]<=S_walk_cluster; S_power[S_active]<=S_power[S_active]<<1; S_lam[S_active]<=0;
                            end else S_lam[S_active]<=S_lam[S_active]+32'd1;
                        end else begin S_tortoise[S_active]<=S_walk_cluster; S_power[S_active]<=1; S_lam[S_active]<=0; end
                        S_state<=PREPARE;
                    end
                end
                DATA_SEND: if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else if(I_sector_ready) S_state<=DATA_WAIT;
                DATA_WAIT: if(I_sector_result_valid) begin
                    S_storage_error[S_active]<=I_sector_storage_error;
                    if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else if(I_sector_error!=0) complete(I_sector_error==1 ? 8'd1 : (I_sector_error==8 ? 8'd8 : 8'd2));
                    else S_state<=DATA_ADDRESS;
                end
                DATA_ADDRESS: if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8); else S_state<=DATA_LATCH;
                DATA_LATCH: if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else begin O_byte_data<=I_buffer_data; S_state<=DATA_OUT; end
                DATA_OUT: if(S_lost_active) complete(8'd1);
                    else if(S_stop) complete(8'd8);
                    else if(I_byte_ready) begin
                        S_cursor[S_active]<=S_cursor[S_active]+32'd1; S_remaining[S_active]<=S_remaining[S_active]-32'd1;
                        if(S_remaining[S_active]==1) complete(8'd0);
                        else if(S_cursor[S_active][8:0]==511) S_state<=SCHEDULE;
                        else S_state<=DATA_ADDRESS;
                    end
                default:S_state<=SCHEDULE;
            endcase
        end
    end
endmodule
