// Free-running raster to active-only AXIS. Only the HDMI sink may be restarted.
// Finite elasticity, not a framebuffer or a guarantee against unlimited stalls.
module scanout_axis_bridge #(
    parameter integer ADDR_BITS=11,
    parameter integer HACTIVE=640,VACTIVE=480,
    parameter integer PREFILL=640,RESET_CYCLES=16
) (
    input wire I_clk,I_reset,I_de,I_valid,
    input wire [15:0] I_x,I_y,
    input wire [23:0] I_rgb,
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
    wire S_sof=I_x==0 && I_y==0;
    wire S_capture=!I_reset && S_hold==0 && I_de && (!S_wait_frame || S_sof);
    wire S_pop=!I_reset && S_hold==0 && S_count!=0 &&
        (!S_output_valid || (S_streaming && I_ready));
    wire S_bad_position=I_x!=S_expected_x || I_y!=S_expected_y ||
        I_x>=HACTIVE || I_y>=VACTIVE;
    // Do not rely on target RAM read-during-write mode at identical addresses.
    // A completely full RAM ends this session even if the head could pop now.
    wire S_overflow=S_count==DEPTH;
    wire S_fail=S_capture && (S_bad_position || S_overflow);
    wire S_push=S_capture && !S_fail;
    assign O_sink_reset=I_reset || S_hold!=0 || !S_streaming;
    assign O_valid=!O_sink_reset && S_output_valid;
    assign O_user=S_output[25];
    assign O_last=S_output[24];
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
        end else if(S_fail) begin
            // Withdrawing a beat is legal only together with resetting its receiver.
            S_write<=0; S_read<=0; S_count<=0; S_output_valid<=0;
            S_wait_frame<=1; S_streaming<=0; S_expected_x<=0; S_expected_y<=0;
            S_hold<=RESET_CYCLES; O_fault<=1;
            if(O_restart_count!=32'hffffffff) O_restart_count<=O_restart_count+1'b1;
        end else if(S_hold!=0) S_hold<=S_hold-1'b1;
        else begin
            if(!S_streaming && (S_count>=PREFILL ||
                (S_count==PREFILL-1 && S_output_valid))) S_streaming<=1;
            if(S_push) begin
                S_wait_frame<=0; S_write<=S_write+1'b1;
                if(I_x==HACTIVE-1) begin
                    S_expected_x<=0;
                    S_expected_y<=I_y==VACTIVE-1 ? 16'd0 : I_y+1'b1;
                end else S_expected_x<=I_x+1'b1;
            end
            if(S_pop) begin S_read<=S_read+1'b1; S_output_valid<=1; end
            else if(O_valid && I_ready) S_output_valid<=0;
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
            RESET_CYCLES<2 || HACTIVE<1 || VACTIVE<1 || HACTIVE>65535 || VACTIVE>65535) begin
            $display("FAIL: scanout_axis_bridge invalid geometry/buffer parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
