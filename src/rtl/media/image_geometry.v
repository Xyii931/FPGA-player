// Aspect-fit geometry on a 640x480 canvas. No image or path storage.
module image_geometry (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [15:0] I_src_width, I_src_height,
    input wire [15:0] I_rect_x, I_rect_y, I_rect_width, I_rect_height,
    input wire [1:0] I_rotation,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire I_abort,
    output wire O_busy, O_result_valid,
    input wire I_result_ready,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,
    output reg [15:0] O_pre_width, O_pre_height,
    output reg [15:0] O_image_x, O_image_y, O_image_width, O_image_height
);
    localparam [2:0] ST_IDLE=0, ST_CHOOSE=1, ST_DIVIDE=2, ST_FINISH=3, ST_RESULT=4;
    reg [2:0] S_state;
    reg [15:0] S_rw,S_rh,S_rect_x,S_rect_y,S_rect_w,S_rect_h;
    reg S_transpose,S_width_limited;
    reg [31:0] S_div_num;
    reg [32:0] S_div_rem;
    reg [15:0] S_divisor;
    reg [5:0] S_div_count;
    wire [31:0] S_width_product=S_rect_w*S_rh;
    wire [31:0] S_height_product=S_rect_h*S_rw;
    wire [32:0] S_trial={S_div_rem[31:0],S_div_num[31]};
    wire S_subtract=S_trial>={17'd0,S_divisor};
    wire [31:0] S_next={S_div_num[30:0],S_subtract};
    wire [15:0] S_other=S_div_num==0 ? 16'd1 : S_div_num[15:0];
    wire [15:0] S_fit_w=S_width_limited ? S_rect_w : S_other;
    wire [15:0] S_fit_h=S_width_limited ? S_other : S_rect_h;
    wire [16:0] S_right={1'b0,I_rect_x}+{1'b0,I_rect_width};
    wire [16:0] S_bottom={1'b0,I_rect_y}+{1'b0,I_rect_height};
    assign O_start_ready=S_state==ST_IDLE;
    assign O_busy=S_state!=ST_IDLE;
    assign O_result_valid=S_state==ST_RESULT;
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=ST_IDLE;
            S_rw<=0; S_rh<=0; S_rect_x<=0; S_rect_y<=0; S_rect_w<=0; S_rect_h<=0;
            S_transpose<=0; S_width_limited<=0;
            S_div_num<=0; S_div_rem<=0; S_divisor<=0; S_div_count<=0;
            O_error<=0; O_tag<=0; O_generation<=0;
            O_pre_width<=0; O_pre_height<=0;
            O_image_x<=0; O_image_y<=0; O_image_width<=0; O_image_height<=0;
        end else if (S_state!=ST_IDLE && S_state!=ST_RESULT && I_abort) begin
            O_error<=4'd2; S_state<=ST_RESULT;
        end else begin
            case (S_state)
                ST_IDLE: if (I_start_valid) begin
                    S_rw<=I_rotation[0] ? I_src_height : I_src_width;
                    S_rh<=I_rotation[0] ? I_src_width : I_src_height;
                    S_rect_x<=I_rect_x; S_rect_y<=I_rect_y;
                    S_rect_w<=I_rect_width; S_rect_h<=I_rect_height;
                    S_transpose<=I_rotation[0];
                    O_error<=0; O_tag<=I_tag; O_generation<=I_generation;
                    O_pre_width<=0; O_pre_height<=0;
                    O_image_x<=0; O_image_y<=0; O_image_width<=0; O_image_height<=0;
                    if (I_abort) begin O_error<=4'd2; S_state<=ST_RESULT; end
                    else if (I_src_width==0 || I_src_width>1920 || I_src_height==0 || I_src_height>1080 ||
                        I_rect_width==0 || I_rect_height==0 || S_right>17'd640 || S_bottom>17'd480) begin
                        O_error<=4'd1; S_state<=ST_RESULT;
                    end else S_state<=ST_CHOOSE;
                end
                ST_CHOOSE: begin
                    S_width_limited<=(S_width_product<=S_height_product);
                    S_div_num<=(S_width_product<=S_height_product) ? S_width_product : S_height_product;
                    S_divisor<=(S_width_product<=S_height_product) ? S_rw : S_rh;
                    S_div_rem<=0; S_div_count<=0; S_state<=ST_DIVIDE;
                end
                ST_DIVIDE: begin
                    S_div_num<=S_next;
                    S_div_rem<=S_subtract ? S_trial-{17'd0,S_divisor} : S_trial;
                    S_div_count<=S_div_count+1'b1;
                    if (S_div_count==31) S_state<=ST_FINISH;
                end
                ST_FINISH: begin
                    O_image_width<=S_fit_w; O_image_height<=S_fit_h;
                    O_image_x<=S_rect_x+((S_rect_w-S_fit_w)>>1);
                    O_image_y<=S_rect_y+((S_rect_h-S_fit_h)>>1);
                    O_pre_width<=S_transpose ? S_fit_h : S_fit_w;
                    O_pre_height<=S_transpose ? S_fit_w : S_fit_h;
                    S_state<=ST_RESULT;
                end
                ST_RESULT: if (I_result_ready) S_state<=ST_IDLE;
                default: S_state<=ST_IDLE;
            endcase
        end
    end
endmodule
