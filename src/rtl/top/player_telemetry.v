// Actual frame/underrun counters, coherent video->host snapshots; no fake SD speed.
module player_telemetry #(
    parameter integer HOST_HZ=125000000
) (
    input wire I_host_clk,I_video_clk,I_async_reset,I_frame_start,
    input wire [31:0] I_video_und_count,
    input wire [1:0] I_audio_underrun,
    output wire [31:0] O_video_und_count,O_audio_und_count,
    output reg [15:0] O_fps,
    output reg O_fps_valid
);
    wire S_host_reset,S_video_reset;
    reg [31:0] S_frames,S_audio_und;
    wire [95:0] S_snapshot;
    reg [31:0] S_second,S_previous_frames;
    wire [31:0] S_frame_delta=S_snapshot[95:64]-S_previous_frames;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset(.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin S_frames<=0; S_audio_und<=0; end
        else begin
            if(I_frame_start) S_frames<=S_frames+1'b1;
            // Count sample events with any starving track, not both as two pixels.
            if(|I_audio_underrun && S_audio_und!=32'hffffffff) S_audio_und<=S_audio_und+1'b1;
        end
    end
    // Same stable-payload protocol, with source=video and destination=host.
    video_ui_cdc #(.WIDTH(96)) u_snapshot (
        .I_host_clk(I_video_clk),.I_video_clk(I_host_clk),.I_async_reset(I_async_reset),.I_frame_start(1'b1),
        .I_state({S_frames,I_video_und_count,S_audio_und}),.O_state(S_snapshot)
    );
    assign O_video_und_count=S_snapshot[63:32];
    assign O_audio_und_count=S_snapshot[31:0];
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin S_second<=0; S_previous_frames<=0; O_fps<=0; O_fps_valid<=0; end
        else if(S_second==HOST_HZ-1) begin
            S_second<=0; S_previous_frames<=S_snapshot[95:64]; O_fps_valid<=1;
            O_fps<=S_frame_delta>65535 ? 16'hffff : S_frame_delta[15:0];
        end else S_second<=S_second+1'b1;
    end
endmodule
