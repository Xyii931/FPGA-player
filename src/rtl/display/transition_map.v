// Seven hard-edge transitions, logical A=from/B=to. Two video clock stages.
// Configure only with a trusted transition_plan and an external frame-boundary owner.
module transition_map (
    input wire I_clk,I_reset,I_config_valid,
    output wire O_config_ready,O_configured,
    input wire [2:0] I_effect,
    input wire [16:0] I_progress,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    input wire [9:0] I_dx,I_left,
    input wire [8:0] I_dy,I_top,
    input wire [5:0] I_blind_count,
    input wire [8:0] I_mosaic_count,
    input wire [19:0] I_wipe_threshold,
    input wire [31:0] I_step_x,I_step_y,
    input wire I_valid,I_hsync,I_vsync,I_de,I_frame_start,I_line_start,
    input wire [15:0] I_x,I_y,
    input wire [8:0] I_query_y,
    output reg O_query_use_a,O_query_use_b,
    output reg [8:0] O_query_a_y,O_query_b_y,
    output reg O_valid,O_hsync,O_vsync,O_de,O_frame_start,O_line_start,
    output reg [15:0] O_x,O_y,
    output reg O_use_a,O_use_b,
    output reg [9:0] O_a_x,O_b_x,
    output reg [8:0] O_a_y,O_b_y,
    output reg [16:0] O_weight,
    output reg [31:0] O_epoch,
    output reg [15:0] O_tag
);
    reg S_configured;
    reg [2:0] S_effect;
    reg [16:0] S_progress;
    reg [31:0] S_epoch,S_step_x,S_step_y;
    reg [15:0] S_tag;
    reg [9:0] S_dx,S_left;
    reg [8:0] S_dy,S_top;
    reg [5:0] S_blind_count;
    reg [8:0] S_mosaic_count;
    reg [19:0] S_wipe_threshold;
    reg S_valid,S_hsync,S_vsync,S_de,S_frame_start,S_line_start;
    reg [15:0] S_x,S_y;
    reg S_use_a,S_use_b,S_zoom;
    reg [9:0] S_a_x,S_b_x;
    reg [8:0] S_a_y,S_b_y;
    reg [16:0] S_weight;
    reg [41:0] S_zoom_x,S_zoom_y;
    reg C_a,C_b,C_zoom;
    reg [9:0] C_ax,C_bx;
    reg [8:0] C_ay,C_by;
    reg [16:0] C_weight;
    wire S_inside=I_x<640 && I_y<480;
    wire [19:0] S_q=20'd480*I_x+20'd640*I_y;
    wire [5:0] S_blind_x=I_x[5] ? 6'd31-{1'b0,I_x[4:0]} : {1'b0,I_x[4:0]};
    wire [15:0] S_hash_x=16'd37*(I_x>>3),S_hash_y=16'd73*(I_y>>3);
    wire [7:0] S_rank=S_hash_x[7:0]^S_hash_y[7:0];
    wire [10:0] S_right={1'b0,S_left}+{1'b0,S_dx};
    wire [9:0] S_bottom={1'b0,S_top}+{1'b0,S_dy};
    wire S_zoom_inside=S_dx!=0 && S_dy!=0 && I_x>=S_left && I_x<S_right && I_y>=S_top && I_y<S_bottom;
    wire [9:0] S_local_x=I_x-S_left;
    wire [8:0] S_local_y=I_y-S_top;
    wire [8:0] S_query_local=I_query_y-S_top;
    wire [41:0] S_query_scaled={10'd0,S_step_y}*S_query_local+{10'd0,(S_step_y>>1)};
    wire [19:0] S_query_min=20'd640*I_query_y;
    wire [19:0] S_query_max=S_query_min+20'd306720;
    assign O_config_ready=!I_reset && !I_valid && !S_valid && !O_valid;
    assign O_configured=S_configured && !I_reset;
    always @* begin
        C_a=0; C_b=0; C_zoom=0; C_weight=0;
        C_ax=I_x[9:0]; C_ay=I_y[8:0]; C_bx=I_x[9:0]; C_by=I_y[8:0];
        if(S_configured && I_de && S_inside) begin
            if(S_progress==0) C_a=1;
            else if(S_progress==65536) begin C_b=1; C_weight=65536; end
            else case(S_effect)
                0:begin C_a=1; C_b=1; C_weight=S_progress; end
                1,2:begin
                    if(I_x>=10'd640-S_dx) begin C_b=1; C_bx=I_x-(10'd640-S_dx); C_weight=65536; end
                    else begin C_a=1; if(S_effect==2) C_ax=I_x+S_dx; end
                end
                3:begin C_b=S_q<S_wipe_threshold; C_a=!C_b; C_weight=C_b ? 17'd65536 : 17'd0; end
                4:begin C_b=S_blind_x<S_blind_count; C_a=!C_b; C_weight=C_b ? 17'd65536 : 17'd0; end
                5:begin C_b={1'b0,S_rank}<S_mosaic_count; C_a=!C_b; C_weight=C_b ? 17'd65536 : 17'd0; end
                6:begin C_b=S_zoom_inside; C_a=!C_b; C_zoom=C_b; C_weight=C_b ? 17'd65536 : 17'd0; end
                default:begin end
            endcase
        end
        if(!C_a) begin C_ax=0; C_ay=0; end
        if(!C_b) begin C_bx=0; C_by=0; end

        O_query_use_a=0; O_query_use_b=0; O_query_a_y=0; O_query_b_y=0;
        if(S_configured && I_query_y<480) begin
            O_query_a_y=I_query_y; O_query_b_y=I_query_y;
            if(S_progress==0) O_query_use_a=1;
            else if(S_progress==65536) O_query_use_b=1;
            else case(S_effect)
                0:begin O_query_use_a=1; O_query_use_b=1; end
                1,2:begin O_query_use_a=S_dx<640; O_query_use_b=S_dx!=0; end
                3:begin O_query_use_a=S_wipe_threshold<=S_query_max; O_query_use_b=S_wipe_threshold>S_query_min; end
                4:begin O_query_use_a=S_blind_count<32; O_query_use_b=S_blind_count!=0; end
                // Conservatively prefetch both rows at intermediate mosaic thresholds.
                5:begin O_query_use_a=S_mosaic_count<256; O_query_use_b=S_mosaic_count!=0; end
                6:begin
                    O_query_use_b=S_dx!=0 && S_dy!=0 && I_query_y>=S_top && I_query_y<S_bottom;
                    O_query_use_a=!O_query_use_b || S_dx<640;
                    O_query_b_y=S_query_scaled[41:16]>479 ? 9'd479 : S_query_scaled[24:16];
                end
                default:begin end
            endcase
            if(!O_query_use_a) O_query_a_y=0;
            if(!O_query_use_b) O_query_b_y=0;
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_configured<=0; S_effect<=0; S_progress<=0; S_epoch<=0; S_tag<=0;
            S_dx<=0; S_dy<=0; S_left<=0; S_top<=0; S_blind_count<=0;
            S_mosaic_count<=0; S_wipe_threshold<=0; S_step_x<=0; S_step_y<=0;
            S_valid<=0; S_hsync<=0; S_vsync<=0; S_de<=0; S_frame_start<=0; S_line_start<=0;
            S_x<=0; S_y<=0; S_use_a<=0; S_use_b<=0; S_zoom<=0;
            S_a_x<=0; S_a_y<=0; S_b_x<=0; S_b_y<=0; S_weight<=0; S_zoom_x<=0; S_zoom_y<=0;
            O_valid<=0; O_hsync<=0; O_vsync<=0; O_de<=0; O_frame_start<=0; O_line_start<=0;
            O_x<=0; O_y<=0; O_use_a<=0; O_use_b<=0; O_a_x<=0; O_a_y<=0;
            O_b_x<=0; O_b_y<=0; O_weight<=0; O_epoch<=0; O_tag<=0;
        end else begin
            if(I_config_valid && O_config_ready) begin
                S_configured<=1; S_effect<=I_effect; S_progress<=I_progress; S_epoch<=I_epoch; S_tag<=I_tag;
                S_dx<=I_dx; S_dy<=I_dy; S_left<=I_left; S_top<=I_top; S_blind_count<=I_blind_count;
                S_mosaic_count<=I_mosaic_count; S_wipe_threshold<=I_wipe_threshold;
                S_step_x<=I_step_x; S_step_y<=I_step_y;
            end
            S_valid<=I_valid && S_configured;
            S_hsync<=I_hsync; S_vsync<=I_vsync; S_de<=I_de; S_frame_start<=I_frame_start; S_line_start<=I_line_start;
            S_x<=I_x; S_y<=I_y; S_use_a<=C_a; S_use_b<=C_b; S_a_x<=C_ax; S_a_y<=C_ay;
            S_b_x<=C_bx; S_b_y<=C_by; S_weight<=C_weight; S_zoom<=C_zoom;
            S_zoom_x<={10'd0,S_step_x}*S_local_x+{10'd0,(S_step_x>>1)};
            S_zoom_y<={10'd0,S_step_y}*S_local_y+{10'd0,(S_step_y>>1)};
            O_valid<=S_valid; O_hsync<=S_hsync; O_vsync<=S_vsync; O_de<=S_de;
            O_frame_start<=S_frame_start; O_line_start<=S_line_start; O_x<=S_x; O_y<=S_y;
            O_use_a<=S_use_a; O_use_b<=S_use_b; O_a_x<=S_a_x; O_a_y<=S_a_y;
            O_b_x<=S_zoom ? (S_zoom_x[41:16]>639 ? 10'd639 : S_zoom_x[25:16]) : S_b_x;
            O_b_y<=S_zoom ? (S_zoom_y[41:16]>479 ? 9'd479 : S_zoom_y[24:16]) : S_b_y;
            O_weight<=S_weight; O_epoch<=S_epoch; O_tag<=S_tag;
        end
    end
endmodule
