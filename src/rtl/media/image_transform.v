// Geometry -> scaler -> coordinate rotation, one command at a time.
// Success retires pixels only: file retirement and SDRAM writes remain external.
module image_transform (
    input wire I_clk, I_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [15:0] I_src_width, I_src_height,
    input wire [15:0] I_rect_x, I_rect_y, I_rect_width, I_rect_height,
    input wire [1:0] I_rotation,
    input wire I_bilinear, I_bottom_up,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,
    input wire I_abort, I_stream_error,
    output wire O_geometry_valid,
    input wire I_geometry_ready,
    output wire [15:0] O_pre_width, O_pre_height,
    output wire [15:0] O_image_x, O_image_y, O_image_width, O_image_height,
    input wire I_pixel_valid,
    output wire O_pixel_ready,
    input wire [31:0] I_rgba,
    input wire [15:0] I_x, I_y,
    input wire I_pixel_last,
    output wire O_pixel_valid,
    input wire I_pixel_ready,
    output wire [31:0] O_rgba,
    output wire [15:0] O_x, O_y,
    output wire O_pixel_last,
    output wire O_busy, O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation
);
    localparam [1:0] ST_IDLE=0, ST_PLAN=1, ST_RUN=2, ST_DONE=3;
    reg [1:0] S_state,S_rotation;
    reg [15:0] S_src_w,S_src_h;
    reg S_bilinear,S_bottom_up,S_scaler_seen,S_rotate_seen;
    wire S_geometry_ready,S_geometry_result,S_geometry_consume;
    wire [3:0] S_geometry_error;
    wire S_scaler_ready,S_scaler_in_ready,S_scaler_valid,S_scaler_last,S_scaler_done;
    wire [31:0] S_scaler_rgba;
    wire [15:0] S_scaler_x,S_scaler_y;
    wire [3:0] S_scaler_error;
    wire S_rotate_ready,S_rotate_in_ready,S_rotate_valid,S_rotate_done;
    wire [3:0] S_rotate_error;
    wire S_cancel=I_abort || I_stream_error || (S_state!=ST_IDLE && O_error!=0);
    wire S_launch=O_geometry_valid && I_geometry_ready && S_scaler_ready && S_rotate_ready;
    wire S_pipeline_abort=S_state==ST_RUN && S_cancel;
    assign O_start_ready=S_state==ST_IDLE && S_geometry_ready;
    assign O_busy=S_state!=ST_IDLE;
    assign O_done_valid=S_state==ST_DONE;
    assign O_geometry_valid=S_state==ST_PLAN && S_geometry_result && S_geometry_error==0 && !S_cancel;
    assign S_geometry_consume=S_state==ST_PLAN && S_geometry_result &&
        (S_geometry_error!=0 || S_cancel || S_launch);
    assign O_pixel_ready=S_state==ST_RUN && !S_cancel && S_scaler_in_ready;
    assign O_pixel_valid=S_state==ST_RUN && !S_cancel && S_rotate_valid;

    image_geometry u_geometry (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(I_start_valid && S_state==ST_IDLE),
        .O_start_ready(S_geometry_ready),.I_src_width(I_src_width),.I_src_height(I_src_height),
        .I_rect_x(I_rect_x),.I_rect_y(I_rect_y),.I_rect_width(I_rect_width),.I_rect_height(I_rect_height),
        .I_rotation(I_rotation),.I_tag(I_tag),.I_generation(I_generation),
        .I_abort(I_abort || I_stream_error || (S_state==ST_PLAN && O_error!=0)),
        .O_busy(),.O_result_valid(S_geometry_result),.I_result_ready(S_geometry_consume),
        .O_error(S_geometry_error),.O_tag(),.O_generation(),
        .O_pre_width(O_pre_width),.O_pre_height(O_pre_height),.O_image_x(O_image_x),.O_image_y(O_image_y),
        .O_image_width(O_image_width),.O_image_height(O_image_height)
    );
    image_scaler u_scaler (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_launch),.O_start_ready(S_scaler_ready),
        .I_src_width(S_src_w),.I_src_height(S_src_h),.I_dst_width(O_pre_width),.I_dst_height(O_pre_height),
        .I_bilinear(S_bilinear),.I_bottom_up(S_bottom_up),.I_tag(O_tag),.I_generation(O_generation),
        .I_abort(S_pipeline_abort),.I_stream_error(1'b0),
        .I_pixel_valid(I_pixel_valid && S_state==ST_RUN && !S_cancel),.O_pixel_ready(S_scaler_in_ready),
        .I_rgba(I_rgba),.I_x(I_x),.I_y(I_y),.I_pixel_last(I_pixel_last),
        .O_pixel_valid(S_scaler_valid),.I_pixel_ready(S_rotate_in_ready),.O_rgba(S_scaler_rgba),
        .O_x(S_scaler_x),.O_y(S_scaler_y),.O_pixel_last(S_scaler_last),
        .O_busy(),.O_done_valid(S_scaler_done),.I_done_ready(S_state==ST_RUN && !S_scaler_seen),
        .O_error(S_scaler_error),.O_tag(),.O_generation()
    );
    image_rotate u_rotate (
        .I_clk(I_clk),.I_reset(I_reset),.I_start_valid(S_launch),.O_start_ready(S_rotate_ready),
        .I_pre_width(O_pre_width),.I_pre_height(O_pre_height),.I_image_x(O_image_x),.I_image_y(O_image_y),
        .I_rotation(S_rotation),.I_bottom_up(S_bottom_up),.I_tag(O_tag),.I_generation(O_generation),
        .I_abort(S_pipeline_abort),.I_stream_error(1'b0),
        .I_pixel_valid(S_scaler_valid),.O_pixel_ready(S_rotate_in_ready),.I_rgba(S_scaler_rgba),
        .I_x(S_scaler_x),.I_y(S_scaler_y),.I_pixel_last(S_scaler_last),
        .O_pixel_valid(S_rotate_valid),.I_pixel_ready(I_pixel_ready && S_state==ST_RUN && !S_cancel),
        .O_rgba(O_rgba),.O_x(O_x),.O_y(O_y),.O_pixel_last(O_pixel_last),
        .O_busy(),.O_done_valid(S_rotate_done),.I_done_ready(S_state==ST_RUN && !S_rotate_seen),
        .O_error(S_rotate_error),.O_tag(),.O_generation()
    );
    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=ST_IDLE; S_rotation<=0; S_src_w<=0; S_src_h<=0;
            S_bilinear<=0; S_bottom_up<=0; S_scaler_seen<=0; S_rotate_seen<=0;
            O_error<=0; O_tag<=0; O_generation<=0;
        end else begin
            case (S_state)
                ST_IDLE: if (I_start_valid && O_start_ready) begin
                    S_src_w<=I_src_width; S_src_h<=I_src_height; S_rotation<=I_rotation;
                    S_bilinear<=I_bilinear; S_bottom_up<=I_bottom_up;
                    O_tag<=I_tag; O_generation<=I_generation;
                    O_error<=I_abort ? 4'd4 : (I_stream_error ? 4'd3 : 4'd0);
                    S_scaler_seen<=0; S_rotate_seen<=0; S_state<=ST_PLAN;
                end
                ST_PLAN: if (S_geometry_result && S_geometry_consume) begin
                    if (S_launch) S_state<=ST_RUN;
                    else begin
                        if (O_error==0) O_error<=S_geometry_error==2 ? 4'd4 : S_geometry_error;
                        S_state<=ST_DONE;
                    end
                end
                ST_RUN: begin
                    if (S_scaler_done && !S_scaler_seen) S_scaler_seen<=1;
                    if (S_rotate_done && !S_rotate_seen) S_rotate_seen<=1;
                    // Peer aborts retire obligations; retain the first actual root cause.
                    if (O_error==0) begin
                        if (S_scaler_done && !S_scaler_seen && S_scaler_error!=0) O_error<=S_scaler_error;
                        else if (S_rotate_done && !S_rotate_seen && S_rotate_error!=0) O_error<=S_rotate_error;
                    end
                    if ((S_scaler_seen || S_scaler_done) && (S_rotate_seen || S_rotate_done)) S_state<=ST_DONE;
                end
                ST_DONE: if (I_done_ready) S_state<=ST_IDLE;
                default: S_state<=ST_IDLE;
            endcase
            if (S_state==ST_PLAN || S_state==ST_RUN) begin
                if (I_abort) O_error<=4'd4;
                else if (I_stream_error && O_error!=4'd4) O_error<=4'd3;
            end
        end
    end
endmodule
