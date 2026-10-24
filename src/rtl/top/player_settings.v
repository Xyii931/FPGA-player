// One boot result and one-at-a-time SAVE mailbox, host125 <-> Flash100.
// Mailbox payloads stay frozen until the synchronized request/ack cycle completes.
module player_settings #(
    parameter integer FLASH_TIMEOUT_CYCLES=100000000
) (
    input wire I_host_clk,I_flash_clk,I_async_reset,
    output reg O_initialized,O_restore_valid,
    input wire I_restore_ready,
    output reg O_restore_found,
    output reg [239:0] O_restore_config,
    output reg [3:0] O_restore_override,O_load_error,
    input wire I_save_valid,
    output wire O_save_ready,
    input wire [239:0] I_config,
    input wire [3:0] I_override,
    output reg O_save_done_valid,
    input wire I_save_done_ready,
    output reg [3:0] O_save_error,
    // Font client belongs to I_flash_clk, including ready/results.
    input wire I_font_valid,
    output wire O_font_ready,
    input wire [23:0] I_font_address,
    input wire [15:0] I_font_tag,
    output wire O_font_read_valid,
    input wire I_font_read_ready,
    output wire [7:0] O_font_read_data,
    output wire O_font_read_last,O_font_done_valid,
    input wire I_font_done_ready,
    output wire [3:0] O_font_error,
    output wire [15:0] O_font_tag,
    // Read-only demo client, Flash100 domain. Result owns the route until consumed.
    input wire I_demo_valid,
    output wire O_demo_ready,
    input wire [23:0] I_demo_address,
    input wire [15:0] I_demo_length,I_demo_tag,
    output wire O_demo_read_valid,
    input wire I_demo_read_ready,
    output wire [7:0] O_demo_read_data,
    output wire O_demo_read_last,O_demo_done_valid,
    input wire I_demo_done_ready,
    output wire [3:0] O_demo_error,
    output wire [15:0] O_demo_tag,
    output wire O_flash_cs_n,O_flash_sclk,O_flash_mosi,
    input wire I_flash_miso
);
    wire S_host_reset,S_flash_reset;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_flash_reset(.I_clk(I_flash_clk),.I_async_reset(I_async_reset),.O_reset(S_flash_reset));
    localparam [2:0] BOOT=0,BOOT_WAIT=1,READY=2,SAVE_START=3,SAVE_WAIT=4;
    reg [2:0] S_flash_state;
    reg S_boot_complete,S_boot_found;
    reg [243:0] S_boot_payload;
    reg [3:0] S_boot_error,S_save_result;
    reg [243:0] S_request_payload;
    reg [1023:0] S_store_payload;
    reg S_request,S_ack,S_save_busy;
    (* async_reg="true" *) reg S_request_meta,S_request_sync,S_ack_meta,S_ack_sync,S_boot_meta,S_boot_sync;
    reg S_boot_captured;
    wire S_load_ready,S_save_ready,S_done_valid,S_done_save,S_store_initialized,S_found,S_store_busy;
    wire [3:0] S_store_error;
    wire [1023:0] S_store_config;
    wire [31:0] S_sequence;
    wire S_flash_valid,S_flash_ready,S_write_valid,S_write_ready,S_write_last,S_read_valid,S_read_ready,S_read_last;
    wire S_flash_done,S_flash_done_ready,S_flash_busy;
    wire [1:0] S_flash_op;
    wire [23:0] S_flash_address;
    wire [15:0] S_flash_length,S_flash_tag,S_result_tag;
    wire [7:0] S_write_data,S_read_data;
    wire [3:0] S_flash_error;
    wire [1:0] S_arb_cmd_ready,S_arb_write_ready,S_arb_read_valid,S_arb_done_valid;
    wire S_arb_busy,S_phy_valid,S_phy_ready,S_phy_write_valid,S_phy_write_ready,S_phy_write_last;
    wire S_phy_read_valid,S_phy_read_ready,S_phy_read_last,S_phy_done_valid,S_phy_done_ready;
    wire [1:0] S_phy_op;
    wire [23:0] S_phy_address;
    wire [15:0] S_phy_length,S_phy_tag,S_phy_result_tag;
    wire [7:0] S_phy_write_data,S_phy_read_data;
    wire [3:0] S_phy_error;
    wire S_font_allow=S_flash_state==READY && S_request_sync==S_ack;
    assign S_flash_ready=S_arb_cmd_ready[0];
    assign S_write_ready=S_arb_write_ready[0];
    assign S_read_valid=S_arb_read_valid[0];
    assign S_flash_done=S_arb_done_valid[0];
    wire S_resource_valid,S_resource_read_ready,S_resource_done_ready;
    wire [23:0] S_resource_address;
    wire [15:0] S_resource_length,S_resource_tag;
    wire [1:0] S_resource_cmd_ready,S_resource_write_ready,S_resource_read_valid,S_resource_done_valid;
    wire S_resource_busy,S_resource_write_valid,S_resource_write_last;
    wire [1:0] S_resource_op;
    wire [7:0] S_resource_write_data,S_resource_read_data;
    wire S_resource_read_last;
    wire [3:0] S_resource_error;
    wire [15:0] S_resource_result_tag;
    assign O_font_ready=S_resource_cmd_ready[0];
    assign O_demo_ready=S_resource_cmd_ready[1];
    assign O_font_read_valid=S_resource_read_valid[0];
    assign O_demo_read_valid=S_resource_read_valid[1];
    assign O_font_done_valid=S_resource_done_valid[0];
    assign O_demo_done_valid=S_resource_done_valid[1];
    assign O_font_read_data=S_read_data;
    assign O_demo_read_data=S_read_data;
    assign O_font_read_last=S_read_last;
    assign O_demo_read_last=S_read_last;
    assign O_font_error=S_flash_error;
    assign O_demo_error=S_flash_error;
    assign O_font_tag=S_result_tag;
    assign O_demo_tag=S_result_tag;
    flash_cmd_arbiter #(.ROUND_ROBIN(1)) u_resources (
        .I_clk(I_flash_clk),.I_reset(S_flash_reset),.I_allow({S_font_allow,S_font_allow}),
        .I_cmd_valid({I_demo_valid,I_font_valid}),.O_cmd_ready(S_resource_cmd_ready),
        .I_op(4'd0),.I_address({I_demo_address,I_font_address}),
        .I_length({I_demo_length,16'd32}),.I_tag({I_demo_tag,I_font_tag}),
        .I_write_valid(2'd0),.O_write_ready(S_resource_write_ready),.I_write_data(16'd0),.I_write_last(2'd0),
        .O_read_valid(S_resource_read_valid),.I_read_ready({I_demo_read_ready,I_font_read_ready}),
        .O_read_data(S_resource_read_data),.O_read_last(S_resource_read_last),.O_done_valid(S_resource_done_valid),
        .I_done_ready({I_demo_done_ready,I_font_done_ready}),.O_error(S_resource_error),.O_tag(S_resource_result_tag),.O_busy(S_resource_busy),
        .O_phy_valid(S_resource_valid),.I_phy_ready(S_arb_cmd_ready[1]),.O_phy_op(S_resource_op),
        .O_phy_address(S_resource_address),.O_phy_length(S_resource_length),.O_phy_tag(S_resource_tag),
        .O_phy_write_valid(S_resource_write_valid),.I_phy_write_ready(1'b0),.O_phy_write_data(S_resource_write_data),.O_phy_write_last(S_resource_write_last),
        .I_phy_read_valid(S_arb_read_valid[1]),.O_phy_read_ready(S_resource_read_ready),
        .I_phy_read_data(S_read_data),.I_phy_read_last(S_read_last),.I_phy_done_valid(S_arb_done_valid[1]),
        .O_phy_done_ready(S_resource_done_ready),.I_phy_error(S_flash_error),.I_phy_tag(S_result_tag)
    );
    assign O_save_ready=O_initialized && O_load_error==0 && !S_host_reset && !S_save_busy && !O_save_done_valid && S_ack_sync==S_request;

    settings_store u_store (
        .I_clk(I_flash_clk),.I_reset(S_flash_reset),.I_load_valid(S_flash_state==BOOT),.I_save_valid(S_flash_state==SAVE_START),
        .O_load_ready(S_load_ready),.O_save_ready(S_save_ready),.I_config(S_store_payload),
        .O_done_valid(S_done_valid),.I_done_ready(S_flash_state==BOOT_WAIT || S_flash_state==SAVE_WAIT),
        .O_done_save(S_done_save),.O_initialized(S_store_initialized),.O_found(S_found),.O_error(S_store_error),
        .O_config(S_store_config),.O_sequence(S_sequence),.O_busy(S_store_busy),
        .O_flash_valid(S_flash_valid),.I_flash_ready(S_flash_ready),.O_flash_op(S_flash_op),
        .O_flash_address(S_flash_address),.O_flash_length(S_flash_length),.O_flash_tag(S_flash_tag),
        .O_write_valid(S_write_valid),.I_write_ready(S_write_ready),.O_write_data(S_write_data),.O_write_last(S_write_last),
        .I_read_valid(S_read_valid),.O_read_ready(S_read_ready),.I_read_data(S_read_data),.I_read_last(S_read_last),
        .I_flash_done_valid(S_flash_done),.O_flash_done_ready(S_flash_done_ready),.I_flash_error(S_flash_error),.I_flash_tag(S_result_tag)
    );
    flash_cmd_arbiter u_arbiter (
        .I_clk(I_flash_clk),.I_reset(S_flash_reset),.I_allow({S_font_allow,1'b1}),
        .I_cmd_valid({S_resource_valid,S_flash_valid}),.O_cmd_ready(S_arb_cmd_ready),
        .I_op({2'd0,S_flash_op}),.I_address({S_resource_address,S_flash_address}),
        .I_length({S_resource_length,S_flash_length}),.I_tag({S_resource_tag,S_flash_tag}),
        .I_write_valid({1'b0,S_write_valid}),.O_write_ready(S_arb_write_ready),
        .I_write_data({8'd0,S_write_data}),.I_write_last({1'b0,S_write_last}),
        .O_read_valid(S_arb_read_valid),.I_read_ready({S_resource_read_ready,S_read_ready}),
        .O_read_data(S_read_data),.O_read_last(S_read_last),.O_done_valid(S_arb_done_valid),
        .I_done_ready({S_resource_done_ready,S_flash_done_ready}),.O_error(S_flash_error),.O_tag(S_result_tag),.O_busy(S_arb_busy),
        .O_phy_valid(S_phy_valid),.I_phy_ready(S_phy_ready),.O_phy_op(S_phy_op),.O_phy_address(S_phy_address),
        .O_phy_length(S_phy_length),.O_phy_tag(S_phy_tag),.O_phy_write_valid(S_phy_write_valid),.I_phy_write_ready(S_phy_write_ready),
        .O_phy_write_data(S_phy_write_data),.O_phy_write_last(S_phy_write_last),.I_phy_read_valid(S_phy_read_valid),
        .O_phy_read_ready(S_phy_read_ready),.I_phy_read_data(S_phy_read_data),.I_phy_read_last(S_phy_read_last),
        .I_phy_done_valid(S_phy_done_valid),.O_phy_done_ready(S_phy_done_ready),.I_phy_error(S_phy_error),.I_phy_tag(S_phy_result_tag)
    );
    flash_ctrl #(.TIMEOUT_CYCLES(FLASH_TIMEOUT_CYCLES)) u_flash (
        .I_clk(I_flash_clk),.I_reset(S_flash_reset),.I_cmd_valid(S_phy_valid),.O_cmd_ready(S_phy_ready),
        .I_op(S_phy_op),.I_address(S_phy_address),.I_length(S_phy_length),.I_tag(S_phy_tag),
        .I_write_valid(S_phy_write_valid),.O_write_ready(S_phy_write_ready),.I_write_data(S_phy_write_data),.I_write_last(S_phy_write_last),
        .O_read_valid(S_phy_read_valid),.I_read_ready(S_phy_read_ready),.O_read_data(S_phy_read_data),.O_read_last(S_phy_read_last),
        .O_done_valid(S_phy_done_valid),.I_done_ready(S_phy_done_ready),.O_error(S_phy_error),.O_tag(S_phy_result_tag),.O_busy(S_flash_busy),
        .O_cs_n(O_flash_cs_n),.O_sclk(O_flash_sclk),.O_mosi(O_flash_mosi),.I_miso(I_flash_miso)
    );
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_request<=0; S_request_payload<=0; S_save_busy<=0; S_ack_meta<=0; S_ack_sync<=0;
            S_boot_meta<=0; S_boot_sync<=0; S_boot_captured<=0;
            O_initialized<=0; O_restore_valid<=0; O_restore_found<=0; O_restore_config<=0;
            O_restore_override<=0; O_load_error<=0; O_save_done_valid<=0; O_save_error<=0;
        end else begin
            S_ack_meta<=S_ack; S_ack_sync<=S_ack_meta;
            S_boot_meta<=S_boot_complete; S_boot_sync<=S_boot_meta;
            if(S_boot_sync && !S_boot_captured) begin
                S_boot_captured<=1; O_restore_valid<=1; O_restore_found<=S_boot_found;
                {O_restore_override,O_restore_config}<=S_boot_payload; O_load_error<=S_boot_error;
            end
            if(O_restore_valid && I_restore_ready) begin O_restore_valid<=0; O_initialized<=1; end
            if(I_save_valid && O_save_ready) begin
                S_request_payload<={I_override,I_config}; S_request<=!S_request; S_save_busy<=1;
            end
            if(S_save_busy && S_ack_sync==S_request) begin
                O_save_done_valid<=1; O_save_error<=S_save_result; S_save_busy<=0;
            end
            if(O_save_done_valid && I_save_done_ready) O_save_done_valid<=0;
        end
    end
    always @(posedge I_flash_clk or posedge S_flash_reset) begin
        if(S_flash_reset) begin
            S_flash_state<=BOOT; S_request_meta<=0; S_request_sync<=0; S_ack<=0;
            S_boot_complete<=0; S_boot_found<=0; S_boot_payload<=0; S_boot_error<=0; S_save_result<=0; S_store_payload<=0;
        end else begin
            S_request_meta<=S_request; S_request_sync<=S_request_meta;
            case(S_flash_state)
                BOOT:if(S_load_ready) S_flash_state<=BOOT_WAIT;
                BOOT_WAIT:if(S_done_valid) begin
                    S_boot_payload<={S_store_config[243:240],S_store_config[239:0]};
                    S_boot_found<=S_found; S_boot_error<=S_store_error; S_boot_complete<=1; S_flash_state<=READY;
                end
                READY:if(S_request_sync!=S_ack) begin
                    S_store_payload<={768'd0,12'd0,S_request_payload}; S_flash_state<=SAVE_START;
                end
                SAVE_START:if(S_save_ready) S_flash_state<=SAVE_WAIT;
                SAVE_WAIT:if(S_done_valid) begin S_save_result<=S_store_error; S_ack<=S_request_sync; S_flash_state<=READY; end
                default:S_flash_state<=READY;
            endcase
        end
    end
endmodule
