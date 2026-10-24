// One plan per displayed progress value. Two parallel restoring dividers.
module transition_plan (
    input wire I_clk,I_reset,I_start_valid,
    output wire O_start_ready,
    input wire [2:0] I_effect,
    input wire [16:0] I_progress,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [2:0] O_effect,
    output reg [16:0] O_progress,
    output reg [31:0] O_epoch,
    output reg [15:0] O_tag,
    output reg [9:0] O_dx,O_left,
    output reg [8:0] O_dy,O_top,
    output reg [5:0] O_blind_count,
    output reg [8:0] O_mosaic_count,
    output reg [19:0] O_wipe_threshold,
    output reg [31:0] O_step_x,O_step_y
);
    localparam [1:0] IDLE=0,DIVIDE=1,RESULT=2;
    reg [1:0] S_state;
    reg [5:0] S_bit;
    reg [31:0] S_qx,S_qy,S_rx,S_ry;
    wire [36:0] S_wide_x=37'd640*I_progress+37'd32768;
    wire [36:0] S_wide_y=37'd480*I_progress+37'd32768;
    wire [36:0] S_wide_wipe=37'd614400*I_progress+37'd32768;
    wire [36:0] S_wide_blind=37'd32*I_progress+37'd32768;
    wire [36:0] S_wide_mosaic=37'd256*I_progress+37'd32768;
    wire [9:0] S_dx=S_wide_x[25:16];
    wire [8:0] S_dy=S_wide_y[24:16];
    wire [32:0] S_trial_x={S_rx,S_qx[31]},S_trial_y={S_ry,S_qy[31]};
    wire S_sub_x=S_trial_x>={23'd0,O_dx};
    wire S_sub_y=S_trial_y>={24'd0,O_dy};
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_done_valid=!I_reset && S_state==RESULT;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_bit<=0; S_qx<=0; S_qy<=0; S_rx<=0; S_ry<=0;
            O_error<=0; O_effect<=0; O_progress<=0; O_epoch<=0; O_tag<=0;
            O_dx<=0; O_dy<=0; O_left<=0; O_top<=0; O_blind_count<=0;
            O_mosaic_count<=0; O_wipe_threshold<=0; O_step_x<=0; O_step_y<=0;
        end else case(S_state)
            IDLE:if(I_start_valid && O_start_ready) begin
                O_effect<=I_effect; O_progress<=I_progress; O_epoch<=I_epoch; O_tag<=I_tag;
                O_error<=0; O_step_x<=0; O_step_y<=0;
                O_dx<=S_dx; O_dy<=S_dy; O_left<=(10'd640-S_dx)>>1; O_top<=(9'd480-S_dy)>>1;
                O_blind_count<=S_wide_blind[21:16]; O_mosaic_count<=S_wide_mosaic[24:16];
                O_wipe_threshold<=S_wide_wipe[35:16];
                if(I_effect>6 || I_progress>65536) begin O_error<=1; S_state<=RESULT; end
                else if(I_effect!=6 || S_dx==0 || S_dy==0) S_state<=RESULT;
                else begin
                    S_bit<=0; S_rx<=0; S_ry<=0; S_qx<=32'd41943040; S_qy<=32'd31457280;
                    S_state<=DIVIDE;
                end
            end
            DIVIDE:begin
                S_rx<=S_sub_x ? S_trial_x-{23'd0,O_dx} : S_trial_x;
                S_ry<=S_sub_y ? S_trial_y-{24'd0,O_dy} : S_trial_y;
                S_qx<={S_qx[30:0],S_sub_x}; S_qy<={S_qy[30:0],S_sub_y};
                if(S_bit==31) begin
                    O_step_x<={S_qx[30:0],S_sub_x}; O_step_y<={S_qy[30:0],S_sub_y}; S_state<=RESULT;
                end else S_bit<=S_bit+1'b1;
            end
            RESULT:if(I_done_ready) S_state<=IDLE;
            default:S_state<=IDLE;
        endcase
    end
endmodule
