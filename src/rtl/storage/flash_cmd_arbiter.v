// Two clients, one captured command and one physical transaction at a time.
module flash_cmd_arbiter #(parameter integer ROUND_ROBIN=0) (
    input wire I_clk,I_reset,
    input wire [1:0] I_allow,I_cmd_valid,
    output reg [1:0] O_cmd_ready,
    input wire [3:0] I_op,
    input wire [47:0] I_address,
    input wire [31:0] I_length,I_tag,
    input wire [1:0] I_write_valid,
    output reg [1:0] O_write_ready,
    input wire [15:0] I_write_data,
    input wire [1:0] I_write_last,
    output reg [1:0] O_read_valid,
    input wire [1:0] I_read_ready,
    output wire [7:0] O_read_data,
    output wire O_read_last,
    output reg [1:0] O_done_valid,
    input wire [1:0] I_done_ready,
    output wire [3:0] O_error,
    output wire [15:0] O_tag,
    output wire O_busy,
    output wire O_phy_valid,
    input wire I_phy_ready,
    output reg [1:0] O_phy_op,
    output reg [23:0] O_phy_address,
    output reg [15:0] O_phy_length,O_phy_tag,
    output wire O_phy_write_valid,
    input wire I_phy_write_ready,
    output wire [7:0] O_phy_write_data,
    output wire O_phy_write_last,
    input wire I_phy_read_valid,
    output wire O_phy_read_ready,
    input wire [7:0] I_phy_read_data,
    input wire I_phy_read_last,I_phy_done_valid,
    output wire O_phy_done_ready,
    input wire [3:0] I_phy_error,
    input wire [15:0] I_phy_tag
);
    localparam [1:0] IDLE=0,OFFER=1,TRANSFER=2;
    reg [1:0] S_state;
    reg S_owner,S_last;
    wire [1:0] S_pending=I_cmd_valid & I_allow;
    wire S_select=S_pending==3 && ROUND_ROBIN!=0 ? !S_last : !S_pending[0];
    assign O_busy=S_state!=IDLE;
    assign O_phy_valid=!I_reset && S_state==OFFER;
    assign O_phy_write_valid=!I_reset && S_state==TRANSFER && I_write_valid[S_owner];
    assign O_phy_write_data=I_write_data[S_owner*8+:8];
    assign O_phy_write_last=I_write_last[S_owner];
    assign O_phy_read_ready=!I_reset && S_state==TRANSFER && I_read_ready[S_owner];
    assign O_phy_done_ready=!I_reset && S_state==TRANSFER && I_done_ready[S_owner];
    assign O_read_data=I_phy_read_data;
    assign O_read_last=I_phy_read_last;
    assign O_error=I_phy_error;
    assign O_tag=I_phy_tag;
    always @* begin
        O_cmd_ready=0; O_write_ready=0; O_read_valid=0; O_done_valid=0;
        if(!I_reset && S_state==IDLE && I_allow[S_select]) O_cmd_ready[S_select]=1;
        if(!I_reset && S_state==TRANSFER) begin
            O_write_ready[S_owner]=I_phy_write_ready;
            O_read_valid[S_owner]=I_phy_read_valid;
            O_done_valid[S_owner]=I_phy_done_valid;
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_owner<=0; S_last<=1; O_phy_op<=0; O_phy_address<=0; O_phy_length<=0; O_phy_tag<=0;
        end else case(S_state)
            IDLE:if(I_cmd_valid[S_select] && O_cmd_ready[S_select]) begin
                S_owner<=S_select; S_last<=S_select; O_phy_op<=I_op[S_select*2+:2];
                O_phy_address<=I_address[S_select*24+:24]; O_phy_length<=I_length[S_select*16+:16];
                O_phy_tag<=I_tag[S_select*16+:16]; S_state<=OFFER;
            end
            OFFER:if(I_phy_ready) S_state<=TRANSFER;
            TRANSFER:if(I_phy_done_valid && O_phy_done_ready) S_state<=IDLE;
            default:S_state<=IDLE;
        endcase
    end
endmodule
