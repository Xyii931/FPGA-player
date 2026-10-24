// Select only after real old sector transactions and file owners have retired.
// The TF controller remains alive while DEM1 uses the same FAT/decoder pipeline.
module player_sector_source (
    input wire I_host_clk,I_sd_clk,I_async_reset,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [31:0] I_lba,
    input wire [7:0] I_count,
    input wire [1:0] I_context,I_priority,
    input wire [15:0] I_tag,
    input wire [2:0] I_urgent_context,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output wire [7:0] O_byte_data,
    output wire O_sector_last,O_request_last,
    output wire [1:0] O_byte_context,
    output wire [15:0] O_byte_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [1:0] O_done_context,
    output wire [15:0] O_done_tag,
    output wire [3:0] O_done_error,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_tag,
    output wire O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output wire [1:0] O_cancel_done_context,
    output wire [15:0] O_cancel_done_tag,
    output wire O_card_ready,O_card_present,
    output wire [32:0] O_capacity_sectors,
    // Native SD-domain diagnostics; synchronize a snapshot before host use.
    output wire O_sd_high_capacity,
    output wire [3:0] O_sd_card_error,
    output wire O_sd_ncs,O_sd_sclk,O_sd_mosi,
    input wire I_sd_miso,
    input wire I_demo,I_recovery,I_service_quiescent,
    output wire O_demo_active,O_demo_ready,O_recovery_active,
    output wire [3:0] O_demo_error,
    output wire O_flash_valid,
    input wire I_flash_ready,
    output wire [23:0] O_flash_address,
    output wire [15:0] O_flash_length,O_flash_tag,
    input wire I_flash_read_valid,
    output wire O_flash_read_ready,
    input wire [7:0] I_flash_read_data,
    input wire I_flash_read_last,I_flash_done_valid,
    output wire O_flash_done_ready,
    input wire [3:0] I_flash_error,
    input wire [15:0] I_flash_tag
);
    wire S_tf_O_request_ready;
    wire S_demo_O_request_ready;
    wire S_tf_O_byte_valid;
    wire S_demo_O_byte_valid;
    wire [7:0] S_tf_O_byte_data;
    wire [7:0] S_demo_O_byte_data;
    wire S_tf_O_sector_last;
    wire S_demo_O_sector_last;
    wire S_tf_O_request_last;
    wire S_demo_O_request_last;
    wire [1:0] S_tf_O_byte_context;
    wire [1:0] S_demo_O_byte_context;
    wire [15:0] S_tf_O_byte_tag;
    wire [15:0] S_demo_O_byte_tag;
    wire S_tf_O_done_valid;
    wire S_demo_O_done_valid;
    wire [1:0] S_tf_O_done_context;
    wire [1:0] S_demo_O_done_context;
    wire [15:0] S_tf_O_done_tag;
    wire [15:0] S_demo_O_done_tag;
    wire [3:0] S_tf_O_done_error;
    wire [3:0] S_demo_O_done_error;
    wire S_tf_O_cancel_ready;
    wire S_demo_O_cancel_ready;
    wire S_tf_O_cancel_done_valid;
    wire S_demo_O_cancel_done_valid;
    wire [1:0] S_tf_O_cancel_done_context;
    wire [1:0] S_demo_O_cancel_done_context;
    wire [15:0] S_tf_O_cancel_done_tag;
    wire [15:0] S_demo_O_cancel_done_tag;
    wire S_tf_O_card_ready;
    wire S_tf_O_card_present;
    wire [32:0] S_tf_O_capacity_sectors;
    wire S_recovery_O_request_ready;
    wire S_recovery_O_byte_valid;
    wire [7:0] S_recovery_O_byte_data;
    wire S_recovery_O_sector_last;
    wire S_recovery_O_request_last;
    wire [1:0] S_recovery_O_byte_context;
    wire [15:0] S_recovery_O_byte_tag;
    wire S_recovery_O_done_valid;
    wire [1:0] S_recovery_O_done_context;
    wire [15:0] S_recovery_O_done_tag;
    wire [3:0] S_recovery_O_done_error;
    wire S_recovery_O_cancel_ready;
    wire S_recovery_O_cancel_done_valid;
    wire [1:0] S_recovery_O_cancel_done_context;
    wire [15:0] S_recovery_O_cancel_done_tag;
    wire S_recovery_ready,S_recovery_quiet;
    wire [3:0] S_recovery_error;
    wire S_raw_request_valid,S_raw_byte_ready,S_raw_done_ready;
    wire [31:0] S_raw_lba;
    wire [15:0] S_raw_tag;
    wire S_reset,S_verified,S_demo_quiet;
    wire [3:0] S_demo_error;
    reg [1:0] S_mode;
    reg S_switch;
    wire S_demo=S_mode==1;
    wire S_recovery=S_mode==2;
    reg [4:0] S_pending,S_cancels;
    wire [1:0] S_desired=I_demo ? 2'd1 : I_recovery ? 2'd2 : !S_tf_O_card_ready ? 2'd1 : 2'd0;
    wire S_request_fire=I_request_valid && O_request_ready;
    wire S_done_fire=O_done_valid && I_done_ready;
    wire S_cancel_fire=I_cancel_valid && O_cancel_ready;
    wire S_cancel_done_fire=O_cancel_done_valid && I_cancel_done_ready;
    reset_sync u_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_reset));
    assign O_demo_active=S_demo;
    assign O_recovery_active=S_recovery;
    assign O_demo_ready=S_verified;
    assign O_demo_error=S_recovery ? S_recovery_error : S_demo_error;
    assign O_card_ready=!S_switch && S_desired==S_mode && (S_demo ? S_verified : S_recovery ? S_recovery_ready && S_tf_O_card_ready : S_tf_O_card_ready);
    assign O_card_present=O_card_ready;
    assign O_capacity_sectors=S_mode!=0 ? 33'd4194304 : S_tf_O_capacity_sectors;
    always @(posedge I_host_clk or posedge S_reset) begin
        if(S_reset) begin S_mode<=0; S_switch<=0; S_pending<=0; S_cancels<=0; end
        else begin
            case({S_request_fire,S_done_fire})
                2'b10:S_pending<=S_pending+1'b1;
                2'b01:S_pending<=S_pending-1'b1;
                default:begin end
            endcase
            case({S_cancel_fire,S_cancel_done_fire})
                2'b10:S_cancels<=S_cancels+1'b1;
                2'b01:S_cancels<=S_cancels-1'b1;
                default:begin end
            endcase
            if(S_desired!=S_mode) S_switch<=1;
            if(S_switch && S_pending==0 && S_cancels==0 && I_service_quiescent && (!S_recovery || S_recovery_quiet)) begin
                S_mode<=S_desired; S_switch<=0;
            end
        end
    end
    sd_storage u_tf (
        .I_host_clk(I_host_clk),
        .I_sd_clk(I_sd_clk),
        .I_async_reset(I_async_reset),
        .I_request_valid(S_recovery ? S_raw_request_valid : (I_request_valid && S_mode==0 && !S_switch && S_desired==S_mode)),
        .O_request_ready(S_tf_O_request_ready),
        .I_lba(S_recovery ? S_raw_lba : I_lba),
        .I_count(S_recovery ? 8'd1 : I_count),
        .I_context(S_recovery ? 2'd0 : I_context),
        .I_priority(S_recovery ? 2'd1 : I_priority),
        .I_tag(S_recovery ? S_raw_tag : I_tag),
        .I_urgent_context(I_urgent_context),
        .O_byte_valid(S_tf_O_byte_valid),
        .I_byte_ready(S_recovery ? S_raw_byte_ready : (I_byte_ready && S_mode==0)),
        .O_byte_data(S_tf_O_byte_data),
        .O_sector_last(S_tf_O_sector_last),
        .O_request_last(S_tf_O_request_last),
        .O_byte_context(S_tf_O_byte_context),
        .O_byte_tag(S_tf_O_byte_tag),
        .O_done_valid(S_tf_O_done_valid),
        .I_done_ready(S_recovery ? S_raw_done_ready : (I_done_ready && S_mode==0)),
        .O_done_context(S_tf_O_done_context),
        .O_done_tag(S_tf_O_done_tag),
        .O_done_error(S_tf_O_done_error),
        .I_cancel_valid(I_cancel_valid && S_mode==0),
        .O_cancel_ready(S_tf_O_cancel_ready),
        .I_cancel_context(I_cancel_context),
        .I_cancel_tag(I_cancel_tag),
        .O_cancel_done_valid(S_tf_O_cancel_done_valid),
        .I_cancel_done_ready(I_cancel_done_ready && S_mode==0),
        .O_cancel_done_context(S_tf_O_cancel_done_context),
        .O_cancel_done_tag(S_tf_O_cancel_done_tag),
        .O_card_ready(S_tf_O_card_ready),
        .O_card_present(S_tf_O_card_present),
        .O_capacity_sectors(S_tf_O_capacity_sectors),
        .O_sd_high_capacity(O_sd_high_capacity),
        .O_sd_card_error(O_sd_card_error),
        .O_sd_ncs(O_sd_ncs),
        .O_sd_sclk(O_sd_sclk),
        .O_sd_mosi(O_sd_mosi),
        .I_sd_miso(I_sd_miso)
    );
    wire S_read_valid,S_read_ready,S_read_byte_valid,S_read_byte_ready,S_read_last,S_read_done,S_read_done_ready;
    wire [23:0] S_read_address;
    wire [9:0] S_read_length;
    wire [7:0] S_read_byte;
    wire [3:0] S_read_error;
    demo_sector_source u_demo (
        .I_recovery_enable(1'b0),
        .I_raw_card_ready(1'b0),
        .O_raw_request_valid(),
        .I_raw_request_ready(1'b0),
        .O_raw_lba(),
        .O_raw_tag(),
        .I_raw_byte_valid(1'b0),
        .O_raw_byte_ready(),
        .I_raw_byte_data(8'd0),
        .I_raw_sector_last(1'b0),
        .I_raw_request_last(1'b0),
        .I_raw_byte_tag(16'd0),
        .I_raw_done_valid(1'b0),
        .O_raw_done_ready(),
        .I_raw_done_error(4'd0),
        .I_raw_done_tag(16'd0),

        .I_byte_ready(I_byte_ready && S_demo),
        .I_cancel_context(I_cancel_context),
        .I_cancel_done_ready(I_cancel_done_ready && S_demo),
        .I_cancel_tag(I_cancel_tag),
        .I_cancel_valid(I_cancel_valid && S_demo),
        .I_clk(I_host_clk),
        .I_context(I_context),
        .I_count(I_count),
        .I_done_ready(I_done_ready && S_demo),
        .I_flash_byte_data(S_read_byte),
        .I_flash_byte_last(S_read_last),
        .I_flash_byte_valid(S_read_byte_valid),
        .I_flash_done_valid(S_read_done),
        .I_flash_error(S_read_error),
        .I_flash_ready(S_read_ready),
        .I_lba(I_lba),
        .I_request_valid(I_request_valid && S_demo && !S_switch && S_desired==S_mode),
        .I_reset(S_reset),
        .I_tag(I_tag),
        .O_byte_context(S_demo_O_byte_context),
        .O_byte_data(S_demo_O_byte_data),
        .O_byte_tag(S_demo_O_byte_tag),
        .O_byte_valid(S_demo_O_byte_valid),
        .O_cancel_done_context(S_demo_O_cancel_done_context),
        .O_cancel_done_tag(S_demo_O_cancel_done_tag),
        .O_cancel_done_valid(S_demo_O_cancel_done_valid),
        .O_cancel_ready(S_demo_O_cancel_ready),
        .O_done_context(S_demo_O_done_context),
        .O_done_error(S_demo_O_done_error),
        .O_done_tag(S_demo_O_done_tag),
        .O_done_valid(S_demo_O_done_valid),
        .O_error(S_demo_error),
        .O_flash_address(S_read_address),
        .O_flash_byte_ready(S_read_byte_ready),
        .O_flash_done_ready(S_read_done_ready),
        .O_flash_length(S_read_length),
        .O_flash_valid(S_read_valid),
        .O_quiescent(S_demo_quiet),
        .O_ready(S_verified),
        .O_request_last(S_demo_O_request_last),
        .O_request_ready(S_demo_O_request_ready),
        .O_sector_last(S_demo_O_sector_last)
    );
    demo_sector_source #(.RECOVERY(1)) u_recovery (
        .I_clk(I_host_clk),
        .I_reset(S_reset),
        .I_recovery_enable(S_recovery && !S_switch && S_desired==S_mode),
        .I_raw_card_ready(S_tf_O_card_ready),
        .O_raw_request_valid(S_raw_request_valid),
        .I_raw_request_ready(S_tf_O_request_ready && S_recovery),
        .O_raw_lba(S_raw_lba),
        .O_raw_tag(S_raw_tag),
        .I_raw_byte_valid(S_tf_O_byte_valid && S_recovery),
        .O_raw_byte_ready(S_raw_byte_ready),
        .I_raw_byte_data(S_tf_O_byte_data),
        .I_raw_sector_last(S_tf_O_sector_last),
        .I_raw_request_last(S_tf_O_request_last),
        .I_raw_byte_tag(S_tf_O_byte_tag),
        .I_raw_done_valid(S_tf_O_done_valid && S_recovery),
        .O_raw_done_ready(S_raw_done_ready),
        .I_raw_done_error(S_tf_O_done_error),
        .I_raw_done_tag(S_tf_O_done_tag),
        .O_ready(S_recovery_ready),
        .O_error(S_recovery_error),
        .O_flash_valid(),
        .I_flash_ready(1'b0),
        .O_flash_address(),
        .O_flash_length(),
        .I_flash_byte_valid(1'b0),
        .O_flash_byte_ready(),
        .I_flash_byte_data(8'd0),
        .I_flash_byte_last(1'b0),
        .I_flash_done_valid(1'b0),
        .O_flash_done_ready(),
        .I_flash_error(4'd0),
        .I_request_valid(I_request_valid && S_recovery && !S_switch && S_desired==S_mode),
        .O_request_ready(S_recovery_O_request_ready),
        .I_lba(I_lba),
        .I_count(I_count),
        .I_context(I_context),
        .I_tag(I_tag),
        .O_byte_valid(S_recovery_O_byte_valid),
        .I_byte_ready(I_byte_ready && S_recovery),
        .O_byte_data(S_recovery_O_byte_data),
        .O_sector_last(S_recovery_O_sector_last),
        .O_request_last(S_recovery_O_request_last),
        .O_byte_context(S_recovery_O_byte_context),
        .O_done_context(S_recovery_O_done_context),
        .O_cancel_done_context(S_recovery_O_cancel_done_context),
        .O_byte_tag(S_recovery_O_byte_tag),
        .O_done_tag(S_recovery_O_done_tag),
        .O_cancel_done_tag(S_recovery_O_cancel_done_tag),
        .O_done_valid(S_recovery_O_done_valid),
        .I_done_ready(I_done_ready && S_recovery),
        .O_done_error(S_recovery_O_done_error),
        .I_cancel_valid(I_cancel_valid && S_recovery),
        .O_cancel_ready(S_recovery_O_cancel_ready),
        .I_cancel_context(I_cancel_context),
        .I_cancel_tag(I_cancel_tag),
        .O_cancel_done_valid(S_recovery_O_cancel_done_valid),
        .I_cancel_done_ready(I_cancel_done_ready && S_recovery),
        .O_quiescent(S_recovery_quiet)
    );
    flash_read_cdc u_flash (
        .I_host_clk(I_host_clk),
        .I_flash_clk(I_sd_clk),
        .I_async_reset(I_async_reset),
        .I_valid(S_read_valid),
        .O_ready(S_read_ready),
        .I_address(S_read_address),
        .I_length(S_read_length),
        .O_byte_valid(S_read_byte_valid),
        .I_byte_ready(S_read_byte_ready),
        .O_byte_data(S_read_byte),
        .O_byte_last(S_read_last),
        .O_done_valid(S_read_done),
        .I_done_ready(S_read_done_ready),
        .O_error(S_read_error),
        .O_flash_valid(O_flash_valid),
        .I_flash_ready(I_flash_ready),
        .O_flash_address(O_flash_address),
        .O_flash_length(O_flash_length),
        .O_flash_tag(O_flash_tag),
        .I_flash_read_valid(I_flash_read_valid),
        .O_flash_read_ready(O_flash_read_ready),
        .I_flash_read_data(I_flash_read_data),
        .I_flash_read_last(I_flash_read_last),
        .I_flash_done_valid(I_flash_done_valid),
        .O_flash_done_ready(O_flash_done_ready),
        .I_flash_error(I_flash_error),
        .I_flash_tag(I_flash_tag)
    );
    assign O_request_ready=!S_switch && S_desired==S_mode && (S_demo ? S_demo_O_request_ready : S_recovery ? S_recovery_O_request_ready : S_tf_O_request_ready);
    assign O_byte_valid=S_demo ? S_demo_O_byte_valid : S_recovery ? S_recovery_O_byte_valid : S_tf_O_byte_valid;
    assign O_byte_data=S_demo ? S_demo_O_byte_data : S_recovery ? S_recovery_O_byte_data : S_tf_O_byte_data;
    assign O_sector_last=S_demo ? S_demo_O_sector_last : S_recovery ? S_recovery_O_sector_last : S_tf_O_sector_last;
    assign O_request_last=S_demo ? S_demo_O_request_last : S_recovery ? S_recovery_O_request_last : S_tf_O_request_last;
    assign O_byte_context=S_demo ? S_demo_O_byte_context : S_recovery ? S_recovery_O_byte_context : S_tf_O_byte_context;
    assign O_byte_tag=S_demo ? S_demo_O_byte_tag : S_recovery ? S_recovery_O_byte_tag : S_tf_O_byte_tag;
    assign O_done_valid=S_demo ? S_demo_O_done_valid : S_recovery ? S_recovery_O_done_valid : S_tf_O_done_valid;
    assign O_done_context=S_demo ? S_demo_O_done_context : S_recovery ? S_recovery_O_done_context : S_tf_O_done_context;
    assign O_done_tag=S_demo ? S_demo_O_done_tag : S_recovery ? S_recovery_O_done_tag : S_tf_O_done_tag;
    assign O_done_error=S_demo ? S_demo_O_done_error : S_recovery ? S_recovery_O_done_error : S_tf_O_done_error;
    assign O_cancel_ready=S_demo ? S_demo_O_cancel_ready : S_recovery ? S_recovery_O_cancel_ready : S_tf_O_cancel_ready;
    assign O_cancel_done_valid=S_demo ? S_demo_O_cancel_done_valid : S_recovery ? S_recovery_O_cancel_done_valid : S_tf_O_cancel_done_valid;
    assign O_cancel_done_context=S_demo ? S_demo_O_cancel_done_context : S_recovery ? S_recovery_O_cancel_done_context : S_tf_O_cancel_done_context;
    assign O_cancel_done_tag=S_demo ? S_demo_O_cancel_done_tag : S_recovery ? S_recovery_O_cancel_done_tag : S_tf_O_cancel_done_tag;
endmodule
