// Logical framebuffer write client. The backend must retire EVERY accepted write.
// No physical SDRAM assumptions; no fixed-delay completion; no frame RAM.
module fb_writer #(
    parameter integer PENDING_BITS=3,
    parameter integer MEM_TAG_BITS=32
) (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire I_lease_grant,
    input wire [1:0] I_op,
    input wire [2:0] I_slot,
    input wire [31:0] I_lease_token,I_generation,
    input wire [15:0] I_tag,
    input wire I_resident,
    input wire [31:0] I_clear_rgba,
    input wire [2:0] I_layout,
    input wire [15:0] I_clear_x,I_clear_y,I_clear_width,I_clear_height,
    input wire [15:0] I_pre_width,I_pre_height,I_image_x,I_image_y,
    input wire [1:0] I_rotation,
    input wire I_bottom_up,I_source_expected,I_abort,
    input wire I_pixel_valid,
    output wire O_pixel_ready,
    input wire [31:0] I_rgba,
    input wire [15:0] I_x,I_y,
    input wire I_pixel_last,
    input wire I_source_valid,
    output wire O_source_ready,
    input wire [15:0] I_source_tag,
    input wire [31:0] I_source_lease_token,I_source_generation,
    input wire [3:0] I_source_error,
    output wire O_cancel_source,
    output wire O_mem_valid,
    input wire I_mem_ready,
    output wire O_mem_wr,
    output reg [20:0] O_mem_addr,
    output reg [31:0] O_mem_data,O_mem_tag,
    output wire [3:0] O_mem_mask,
    output wire [31:0] O_mem_lease_token,O_mem_generation,
    input wire I_mem_done_valid,
    output wire O_mem_done_ready,
    input wire [31:0] I_mem_done_tag,I_mem_done_lease_token,I_mem_done_generation,
    input wire [3:0] I_mem_done_error,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,O_memory_error,O_source_error,
    output reg [15:0] O_tag,
    output reg [2:0] O_slot,
    output reg [31:0] O_lease_token,O_generation,
    output reg [31:0] O_accepted_writes,O_retired_writes,O_pixels,
    output wire O_memory_retired,O_producer_retired,
    output reg O_response_discarded,O_source_discarded,
    output reg O_tag_exhausted
);
    localparam [2:0] IDLE=0,CLEAR=1,CLEAR_WAIT=2,PIXELS=3,DRAIN=4,RESULT=5;
    localparam integer DEPTH=1<<PENDING_BITS;
    reg [2:0] S_state;
    reg [1:0] S_op,S_rotation;
    reg S_resident,S_bottom_up,S_source_expected,S_source_seen,S_pixels_complete;
    reg [15:0] S_w,S_h,S_image_x,S_image_y,S_u,S_v;
    reg [20:0] S_base;
    reg [31:0] S_clear_rgba;
    reg [15:0] S_clear_x,S_clear_y,S_clear_width,S_clear_height,S_clear_u,S_clear_v;
    reg [2:0] S_layout;
    reg S_cmd_valid,S_cmd_last;
    reg [MEM_TAG_BITS-1:0] S_next_tag;
    reg [31:0] S_pending_tags[0:DEPTH-1];
    reg [PENDING_BITS-1:0] S_head,S_tail;
    reg [PENDING_BITS:0] S_count;
    reg [15:0] S_local_x,S_local_y;
    wire S_active=S_state!=IDLE && S_state!=RESULT;
    wire S_media_bad=!S_resident && (!I_media_valid || I_media_generation!=O_generation);
    wire S_stop=O_error!=0 || I_abort || S_media_bad;
    wire S_mem_fire=S_cmd_valid && I_mem_ready;
    wire S_response_identity=I_mem_done_lease_token==O_lease_token && I_mem_done_generation==O_generation;
    wire [31:0] S_expected_tag=S_count!=0 ? S_pending_tags[S_head] : O_mem_tag;
    wire S_retire=S_active && I_mem_done_valid && S_response_identity &&
        (S_count!=0 || S_mem_fire) && I_mem_done_tag==S_expected_tag;
    wire S_response_bad=S_active && I_mem_done_valid && S_response_identity && !S_retire;
    wire S_source_match=S_active && S_source_expected && !S_source_seen &&
        I_source_tag==O_tag && I_source_lease_token==O_lease_token && I_source_generation==O_generation;
    wire S_source_fire=I_source_valid && S_source_match;
    wire S_buffer_free=!S_cmd_valid || I_mem_ready;
    // Staged commands reserve a credit, so a held valid never overruns the FIFO.
    wire [PENDING_BITS+1:0] S_reserved={1'b0,S_count}+(S_cmd_valid ? 1'b1 : 1'b0);
    wire S_room=S_reserved<DEPTH || S_retire;
    wire S_last_pixel=S_u==S_w-16'd1 && (S_bottom_up ? S_v==0 : S_v==S_h-16'd1);
    wire [16:0] S_expected_x={1'b0,S_image_x}+{1'b0,S_local_x};
    wire [16:0] S_expected_y={1'b0,S_image_y}+{1'b0,S_local_y};
    wire S_pixel_ok=I_x==S_expected_x && I_y==S_expected_y && I_pixel_last==S_last_pixel;
    wire S_pixel_fire=I_pixel_valid && O_pixel_ready;
    wire S_prepare_clear=S_state==CLEAR && !S_stop && S_buffer_free && S_room && !O_tag_exhausted &&
        !(S_cmd_valid && S_cmd_last);
    wire S_prepare_pixel=S_pixel_fire && S_pixel_ok;
    wire S_prepare=S_prepare_clear || S_prepare_pixel;
    wire [15:0] S_rotated_w=I_rotation[0] ? I_pre_height : I_pre_width;
    wire [15:0] S_rotated_h=I_rotation[0] ? I_pre_width : I_pre_height;
    wire [16:0] S_right={1'b0,I_image_x}+{1'b0,S_rotated_w};
    wire [16:0] S_bottom={1'b0,I_image_y}+{1'b0,S_rotated_h};
    wire [16:0] S_clear_right={1'b0,I_clear_x}+{1'b0,I_clear_width};
    wire [16:0] S_clear_bottom={1'b0,I_clear_y}+{1'b0,I_clear_height};
    wire S_clear_config=I_op!=3 || (I_clear_width!=0 && I_clear_height!=0 &&
        S_clear_right<=640 && S_clear_bottom<=480 && I_image_x>=I_clear_x &&
        I_image_y>=I_clear_y && S_right<=S_clear_right && S_bottom<=S_clear_bottom);
    wire S_config_ok=S_clear_config && I_slot<6 && I_lease_token!=0 && (!I_resident || I_slot==5) &&
        (I_op==0 || (I_source_expected && I_pre_width!=0 && I_pre_width<=640 &&
        I_pre_height!=0 && I_pre_height<=640 && S_right<=640 && S_bottom<=480));
    wire [15:0] S_clear_px=S_clear_x+S_clear_u;
    wire [15:0] S_clear_py=S_clear_y+S_clear_v;
    wire S_clear_last=S_clear_u==S_clear_width-1'b1 && S_clear_v==S_clear_height-1'b1;
    function [31:0] decorate;
        input [31:0] color;
        input [15:0] x,y;
        input [2:0] layout;
        begin
            decorate=color;
            if(layout==1 && x>=460 && x<624 && y>=16 && y<140 &&
                (x<462 || x>=622 || y<18 || y>=138)) decorate=32'hffffffff;
            if(layout==2 && (x==319 || x==320)) decorate=32'hffffffff;
        end
    endfunction
    reg [3:0] S_cycle_error;
    function [3:0] error_rank;
        input [3:0] code;
        begin
            case (code)
                6:error_rank=7;
                5:error_rank=6;
                3:error_rank=5;
                4:error_rank=4;
                2:error_rank=3;
                7:error_rank=2;
                1:error_rank=1;
                default:error_rank=0;
            endcase
        end
    endfunction
    always @* begin
        case (S_rotation)
            0:begin S_local_x=S_u; S_local_y=S_v; end
            1:begin S_local_x=S_h-16'd1-S_v; S_local_y=S_u; end
            2:begin S_local_x=S_w-16'd1-S_u; S_local_y=S_h-16'd1-S_v; end
            default:begin S_local_x=S_v; S_local_y=S_w-16'd1-S_u; end
        endcase
        S_cycle_error=0;
        if (O_tag_exhausted && ((S_state==CLEAR && !(S_cmd_valid && S_cmd_last)) ||
            (S_state==PIXELS && !S_pixels_complete))) S_cycle_error=7;
        if (S_source_fire && I_source_error!=0 && O_error==0) S_cycle_error=2;
        if (S_response_bad || (S_pixel_fire && !S_pixel_ok) ||
            (S_source_fire && I_source_error==0 && O_error==0 && S_op!=0 &&
            !S_pixels_complete && !(S_prepare_pixel && S_last_pixel))) S_cycle_error=4;
        if (S_retire && I_mem_done_error!=0) S_cycle_error=3;
        if (I_abort) S_cycle_error=5;
        if (S_media_bad) S_cycle_error=6;
    end
    assign O_start_ready=!I_reset && S_state==IDLE && I_lease_grant;
    assign O_pixel_ready=S_state==PIXELS && !S_pixels_complete && !S_stop &&
        S_buffer_free && S_room && !O_tag_exhausted;
    assign O_source_ready=!I_reset && S_state!=IDLE;
    assign O_mem_done_ready=!I_reset;
    // Local faults first latch into O_error. Feeding S_cycle_error directly to
    // upstream abort can suppress the very pixel handshake that raised the fault.
    assign O_cancel_source=S_active && S_source_expected && !S_source_seen && S_stop;
    assign O_mem_valid=S_cmd_valid && !I_reset;
    assign O_mem_wr=1'b1;
    assign O_mem_mask=4'b0000;
    assign O_mem_lease_token=O_lease_token;
    assign O_mem_generation=O_generation;
    assign O_busy=S_state!=IDLE;
    assign O_done_valid=S_state==RESULT;
    assign O_memory_retired=S_state!=IDLE && S_count==0 && !S_cmd_valid;
    assign O_producer_retired=S_state!=IDLE && (!S_source_expected || S_source_seen);

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_state<=IDLE; S_op<=0; S_rotation<=0; S_resident<=0; S_bottom_up<=0;
            S_source_expected<=0; S_source_seen<=0; S_pixels_complete<=0;
            S_w<=0; S_h<=0; S_image_x<=0; S_image_y<=0; S_u<=0; S_v<=0;
            S_base<=0; S_clear_rgba<=0; S_layout<=0;
            S_clear_x<=0; S_clear_y<=0; S_clear_width<=0; S_clear_height<=0; S_clear_u<=0; S_clear_v<=0;
            S_cmd_valid<=0; S_cmd_last<=0; S_next_tag<=1; S_head<=0; S_tail<=0; S_count<=0;
            O_mem_addr<=0; O_mem_data<=0; O_mem_tag<=0;
            O_error<=0; O_memory_error<=0; O_source_error<=0;
            O_tag<=0; O_slot<=0; O_lease_token<=0; O_generation<=0;
            O_accepted_writes<=0; O_retired_writes<=0; O_pixels<=0;
            O_response_discarded<=0; O_source_discarded<=0; O_tag_exhausted<=0;
        end else begin
            O_response_discarded<=I_mem_done_valid && !S_retire;
            O_source_discarded<=I_source_valid && O_source_ready && !S_source_match;
            if (S_active) begin
                if (S_mem_fire) begin
                    S_cmd_valid<=0;
                    S_pending_tags[S_tail]<=O_mem_tag; S_tail<=S_tail+1'b1;
                    O_accepted_writes<=O_accepted_writes+32'd1;
                end
                if (S_retire) begin
                    S_head<=S_head+1'b1; O_retired_writes<=O_retired_writes+32'd1;
                    if (I_mem_done_error!=0 && O_memory_error==0) O_memory_error<=I_mem_done_error;
                end
                case ({S_mem_fire,S_retire})
                    2'b10:S_count<=S_count+1'b1;
                    2'b01:S_count<=S_count-1'b1;
                    default:begin end
                endcase
                if (S_source_fire) begin S_source_seen<=1; O_source_error<=I_source_error; end
                if (error_rank(S_cycle_error)>error_rank(O_error)) O_error<=S_cycle_error;
                if (S_prepare) begin
                    S_cmd_valid<=1; O_mem_tag<=S_next_tag;
                    if (&S_next_tag) O_tag_exhausted<=1;
                    else S_next_tag<=S_next_tag+1'b1;
                    if (S_prepare_clear) begin
                        O_mem_addr<=S_base+({5'd0,S_clear_py}<<9)+({5'd0,S_clear_py}<<7)+{5'd0,S_clear_px};
                        O_mem_data<=decorate(S_clear_rgba,S_clear_px,S_clear_py,S_layout);
                        S_cmd_last<=S_clear_last;
                        if(!S_clear_last) begin
                            if(S_clear_u==S_clear_width-1'b1) begin S_clear_u<=0; S_clear_v<=S_clear_v+1'b1; end
                            else S_clear_u<=S_clear_u+1'b1;
                        end
                    end else begin
                        O_mem_addr<=S_base+({5'd0,I_y}<<9)+({5'd0,I_y}<<7)+{5'd0,I_x};
                        O_mem_data<=decorate(I_rgba,I_x,I_y,S_layout); S_cmd_last<=S_last_pixel;
                        O_pixels<=O_pixels+32'd1;
                        if (S_last_pixel) begin S_pixels_complete<=1; S_state<=DRAIN; end
                        else if (S_u==S_w-16'd1) begin
                            S_u<=0; S_v<=S_bottom_up ? S_v-16'd1 : S_v+16'd1;
                        end else S_u<=S_u+16'd1;
                    end
                end
            end
            case (S_state)
                IDLE:if (I_start_valid && O_start_ready) begin
                    S_op<=I_op; S_rotation<=I_rotation; S_resident<=I_resident; S_bottom_up<=I_bottom_up;
                    S_w<=I_pre_width; S_h<=I_pre_height; S_image_x<=I_image_x; S_image_y<=I_image_y;
                    S_u<=0; S_v<=I_bottom_up ? I_pre_height-16'd1 : 16'd0;
                    S_source_expected<=I_source_expected; S_source_seen<=0; S_pixels_complete<=I_op==0;
                    S_clear_rgba<=I_clear_rgba; S_layout<=I_layout;
                    S_clear_x<=I_op==3 ? I_clear_x : 16'd0;
                    S_clear_y<=I_op==3 ? I_clear_y : 16'd0;
                    S_clear_width<=I_op==3 ? I_clear_width : 16'd640;
                    S_clear_height<=I_op==3 ? I_clear_height : 16'd480;
                    S_clear_u<=0; S_clear_v<=0;
                    S_head<=0; S_tail<=0; S_count<=0; S_cmd_valid<=0;
                    O_tag<=I_tag; O_slot<=I_slot; O_lease_token<=I_lease_token; O_generation<=I_generation;
                    O_error<=0; O_memory_error<=0; O_source_error<=0;
                    O_accepted_writes<=0; O_retired_writes<=0; O_pixels<=0;
                    case (I_slot)
                        0:S_base<=21'h000000;
                        1:S_base<=21'h04b000;
                        2:S_base<=21'h096000;
                        3:S_base<=21'h0e1000;
                        4:S_base<=21'h12c000;
                        5:S_base<=21'h177000;
                        default:S_base<=0;
                    endcase
                    S_state<=I_op==1 ? PIXELS : CLEAR;
                    if (!S_config_ok) begin O_error<=1; S_state<=DRAIN; end
                    else if (O_tag_exhausted) begin O_error<=7; S_state<=DRAIN; end
                    if (I_abort) begin O_error<=5; S_state<=DRAIN; end
                    if (!I_resident && (!I_media_valid || I_media_generation!=I_generation)) begin
                        O_error<=6; S_state<=DRAIN;
                    end
                end
                CLEAR:if (S_mem_fire && S_cmd_last) S_state<=CLEAR_WAIT;
                CLEAR_WAIT:if (S_count==0 && !S_cmd_valid) S_state<=S_op==0 ? DRAIN : PIXELS;
                DRAIN:if (S_count==0 && !S_cmd_valid && (!S_source_expected || S_source_seen)) S_state<=RESULT;
                RESULT:if (I_done_ready) S_state<=IDLE;
                default:begin end
            endcase
            if (S_active && S_state!=DRAIN && (S_stop || S_cycle_error!=0)) S_state<=DRAIN;
        end
    end
endmodule
