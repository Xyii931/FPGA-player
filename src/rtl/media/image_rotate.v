// Address-coordinate rotation only. Output retains source arrival order.
// A 90/270 degree job writes columns; the receiver must accept arbitrary x/y.
module image_rotate (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [15:0] I_pre_width, I_pre_height, I_image_x, I_image_y,
    input wire [1:0] I_rotation,
    input wire I_bottom_up,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire I_abort, I_stream_error,
    input wire I_pixel_valid,
    output wire O_pixel_ready,
    input wire [31:0] I_rgba,
    input wire [15:0] I_x, I_y,
    input wire I_pixel_last,
    output wire O_pixel_valid,
    input wire I_pixel_ready,
    output reg [31:0] O_rgba,
    output reg [15:0] O_x, O_y,
    output reg O_pixel_last,
    output wire O_busy, O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation
);
    localparam [1:0] ST_IDLE=0,ST_ACTIVE=1,ST_DRAIN=2,ST_DONE=3;
    reg [1:0] S_state,S_rotation;
    reg [15:0] S_w,S_h,S_image_x,S_image_y,S_x,S_y;
    reg S_bottom_up,S_valid;
    reg [15:0] S_local_x,S_local_y;
    wire [15:0] S_rotated_w=I_rotation[0] ? I_pre_height : I_pre_width;
    wire [15:0] S_rotated_h=I_rotation[0] ? I_pre_width : I_pre_height;
    wire [16:0] S_right={1'b0,I_image_x}+{1'b0,S_rotated_w};
    wire [16:0] S_bottom={1'b0,I_image_y}+{1'b0,S_rotated_h};
    wire S_last=S_x==S_w-16'd1 && (S_bottom_up ? S_y==0 : S_y==S_h-16'd1);
    always @* begin
        case (S_rotation)
            0: begin S_local_x=I_x; S_local_y=I_y; end
            1: begin S_local_x=S_h-16'd1-I_y; S_local_y=I_x; end
            2: begin S_local_x=S_w-16'd1-I_x; S_local_y=S_h-16'd1-I_y; end
            default: begin S_local_x=I_y; S_local_y=S_w-16'd1-I_x; end
        endcase
    end
    assign O_start_ready=S_state==ST_IDLE;
    assign O_busy=S_state!=ST_IDLE;
    assign O_done_valid=S_state==ST_DONE;
    assign O_pixel_valid=S_valid && !I_abort && !I_stream_error;
    assign O_pixel_ready=S_state==ST_ACTIVE && (!S_valid || I_pixel_ready) && !I_abort && !I_stream_error;
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=ST_IDLE; S_rotation<=0;
            S_w<=0; S_h<=0; S_image_x<=0; S_image_y<=0; S_x<=0; S_y<=0;
            S_bottom_up<=0; S_valid<=0;
            O_rgba<=0; O_x<=0; O_y<=0; O_pixel_last<=0;
            O_error<=0; O_tag<=0; O_generation<=0;
        end else if (S_state!=ST_IDLE && S_state!=ST_DONE && (I_abort || I_stream_error)) begin
            S_valid<=0; O_error<=I_abort ? 4'd4 : 4'd3; S_state<=ST_DONE;
        end else begin
            if (S_valid && I_pixel_ready) S_valid<=0;
            case (S_state)
                ST_IDLE: if (I_start_valid) begin
                    S_w<=I_pre_width; S_h<=I_pre_height; S_image_x<=I_image_x; S_image_y<=I_image_y;
                    S_rotation<=I_rotation; S_bottom_up<=I_bottom_up;
                    S_x<=0; S_y<=I_bottom_up ? I_pre_height-16'd1 : 16'd0; S_valid<=0;
                    O_error<=0; O_tag<=I_tag; O_generation<=I_generation;
                    if (I_abort || I_stream_error) begin
                        O_error<=I_abort ? 4'd4 : 4'd3; S_state<=ST_DONE;
                    end else if (I_pre_width==0 || I_pre_width>640 || I_pre_height==0 || I_pre_height>640 ||
                        S_right>17'd640 || S_bottom>17'd480) begin
                        O_error<=4'd1; S_state<=ST_DONE;
                    end else S_state<=ST_ACTIVE;
                end
                ST_ACTIVE: if (I_pixel_valid && O_pixel_ready) begin
                    if (I_x!=S_x || I_y!=S_y || I_pixel_last!=S_last) begin
                        S_valid<=0; O_error<=4'd2; S_state<=ST_DONE;
                    end else begin
                        O_rgba<=I_rgba; O_x<=S_image_x+S_local_x; O_y<=S_image_y+S_local_y;
                        O_pixel_last<=I_pixel_last; S_valid<=1;
                        if (S_last) S_state<=ST_DRAIN;
                        else if (S_x==S_w-16'd1) begin
                            S_x<=0; S_y<=S_bottom_up ? S_y-16'd1 : S_y+16'd1;
                        end else S_x<=S_x+16'd1;
                    end
                end
                ST_DRAIN: if (!S_valid || I_pixel_ready) S_state<=ST_DONE;
                ST_DONE: if (I_done_ready) S_state<=ST_IDLE;
                default: S_state<=ST_IDLE;
            endcase
        end
    end
endmodule
