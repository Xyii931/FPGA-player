// Free-running raster to DE-paced AXIS for the Anlogic HDMI 1.4b core.
//
// Why DE-paced: the core delimits lines by the gaps in I_axis_s_valid. The
// proven vendor reference feeds it color_bar's DE (640 valid pixels, then 160
// idle) and never uses O_axis_s_ready. The previous version of this bridge kept
// O_valid high for the whole stream and popped on I_ready, which left the core
// without per-line boundaries and produced no locked raster on hardware.
//
// The output raster is held at h=0,v=0 until S_streaming rises, i.e. until the
// core is released from reset, so the first popped pixel (the frame's SOF) is
// presented at the first active pixel of the output frame. From then on both
// sides advance 640 pixels per line / 480 lines per frame, keeping the stored
// frame aligned with the raster without any absolute phase assumption.
//
// Finite elasticity, not a framebuffer or a guarantee against unlimited stalls.
//
// Output geometry follows APUG092: line_length=HACTIVE, line_space=HTOTAL,
// frame_space=VTOTAL. The active burst therefore starts at h=0,v=0 of the
// local raster and runs 640 continuous beats, then 160 idle, then 45 idle
// lines. The core's internal phase matcher locks onto that spacing.
module scanout_axis_bridge #(
    parameter integer ADDR_BITS=11,
    parameter integer HACTIVE=640,VACTIVE=480,
    parameter integer HTOTAL=800,VTOTAL=525,
    parameter integer HSTART=0,VSTART=0,
    parameter integer PREFILL=1280,RESET_CYCLES=16
) (
    input wire I_clk,I_reset,I_de,I_valid,
    input wire [15:0] I_x,I_y,
    input wire [23:0] I_rgb,
    // Retained for interface stability; the core is paced by the local raster,
    // exactly as in the vendor reference (which ignores axis_s_ready too).
    input wire I_ready,
    output wire O_valid,O_user,O_last,
    output wire [23:0] O_data,
    output wire O_sink_reset,
    output reg O_fault,
    output reg [31:0] O_restart_count,
    output wire [ADDR_BITS:0] O_level
);
    localparam integer DEPTH=2**ADDR_BITS;
    reg [25:0] S_memory[0:DEPTH-1];
    reg [ADDR_BITS-1:0] S_write,S_read;
    reg [ADDR_BITS:0] S_count;
    reg [25:0] S_output;
    reg S_output_valid,S_wait_frame,S_streaming;
    reg [15:0] S_expected_x,S_expected_y;
    reg [31:0] S_hold;
    reg [15:0] S_ohc,S_ovc;

    wire S_sof=I_x==0 && I_y==0;
    wire S_capture=!I_reset && S_hold==0 && I_de && (!S_wait_frame || S_sof);
    wire S_bad_position=I_x!=S_expected_x || I_y!=S_expected_y ||
        I_x>=HACTIVE || I_y>=VACTIVE;
    // Do not rely on target RAM read-during-write mode at identical addresses.
    // A completely full RAM ends this session even if the head could pop now.
    wire S_overflow=S_count==DEPTH;
    wire S_fail=S_capture && (S_bad_position || S_overflow);
    wire S_push=S_capture && !S_fail;

    // Output raster, frozen until the sink is released from reset.
    wire S_oh_active=(S_ohc>=HSTART) && (S_ohc<HSTART+HACTIVE);
    wire S_ov_active=(S_ovc>=VSTART) && (S_ovc<VSTART+VACTIVE);
    wire S_oactive=S_oh_active && S_ov_active;

    assign O_sink_reset=I_reset || S_hold!=0 || !S_streaming;

    wire S_present=!O_sink_reset && S_oactive && S_output_valid;
    wire S_pop=S_count!=0 && (!S_output_valid || S_present);

    assign O_valid=S_present;
    assign O_user=S_present && (S_ohc==HSTART) && (S_ovc==VSTART);
    assign O_last=S_present && (S_ohc==HSTART+HACTIVE-1);
    assign O_data=S_output[23:0];
    assign O_level=S_count;

    // No RAM reset: infer a synchronous simple dual-port memory.
    always @(posedge I_clk) begin
        if(S_push) S_memory[S_write]<={S_sof,I_x==HACTIVE-1,I_valid ? I_rgb : 24'd0};
        if(S_pop) S_output<=S_memory[S_read];
    end

    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_write<=0; S_read<=0; S_count<=0; S_output_valid<=0;
            S_wait_frame<=1; S_streaming<=0; S_expected_x<=0; S_expected_y<=0;
            S_hold<=RESET_CYCLES; O_fault<=0; O_restart_count<=0;
            S_ohc<=0; S_ovc<=0;
        end else if(S_fail) begin
            // Withdrawing a beat is legal only together with resetting its receiver.
            S_write<=0; S_read<=0; S_count<=0; S_output_valid<=0;
            S_wait_frame<=1; S_streaming<=0; S_expected_x<=0; S_expected_y<=0;
            S_hold<=RESET_CYCLES; O_fault<=1;
            S_ohc<=0; S_ovc<=0;
            if(O_restart_count!=32'hffffffff) O_restart_count<=O_restart_count+1'b1;
        end else if(S_hold!=0) begin
            S_hold<=S_hold-1'b1;
            S_ohc<=0; S_ovc<=0;
        end else begin
            if(!S_streaming && (S_count>=PREFILL ||
                (S_count==PREFILL-1 && S_output_valid))) S_streaming<=1;

            // Output raster is frozen while the sink is held in reset.
            if(O_sink_reset) begin
                S_ohc<=0; S_ovc<=0;
            end else if(S_ohc==HTOTAL-1) begin
                S_ohc<=0;
                if(S_ovc==VTOTAL-1) S_ovc<=0;
                else S_ovc<=S_ovc+1'b1;
            end else begin
                S_ohc<=S_ohc+1'b1;
            end

            if(S_push) begin
                S_wait_frame<=0; S_write<=S_write+1'b1;
                if(I_x==HACTIVE-1) begin
                    S_expected_x<=0;
                    S_expected_y<=I_y==VACTIVE-1 ? 16'd0 : I_y+1'b1;
                end else S_expected_x<=I_x+1'b1;
            end
            if(S_pop) begin S_read<=S_read+1'b1; S_output_valid<=1; end
            else if(S_present) S_output_valid<=0;
            case({S_push,S_pop})
                2'b10:S_count<=S_count+1'b1;
                2'b01:S_count<=S_count-1'b1;
                default:begin end
            endcase
        end
    end
    // synthesis translate_off
    initial begin
        if(ADDR_BITS<2 || ADDR_BITS>16 || PREFILL<1 || PREFILL>=DEPTH ||
            RESET_CYCLES<2 || HACTIVE<1 || VACTIVE<1 || HACTIVE>65535 || VACTIVE>65535 ||
            HSTART+HACTIVE>HTOTAL || VSTART+VACTIVE>VTOTAL) begin
            $display("FAIL: scanout_axis_bridge invalid geometry/buffer parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
