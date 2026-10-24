// Host-domain automatic mount -> scan. Timers delay retries, never retire I/O.
module media_session_ctrl #(
    parameter [31:0] RETRY_CYCLES=32'd125000000
) (
    input wire I_clk,I_reset,I_enable,I_reload,I_rescan,
    input wire I_card_ready,I_storage_quiescent,I_mounted,
    input wire [31:0] I_generation,
    output wire O_unmount,O_mount_valid,
    input wire I_mount_ready,I_mount_result_valid,
    output wire O_mount_result_ready,
    input wire [7:0] I_mount_error,
    input wire [3:0] I_mount_storage_error,
    input wire [31:0] I_mount_generation,
    output wire O_scan_start_valid,
    input wire I_scan_start_ready,I_scan_done_valid,
    output wire O_scan_done_ready,O_scan_abort,
    output wire [15:0] O_scan_tag,
    output wire [31:0] O_scan_generation,
    input wire [3:0] I_scan_error,
    input wire [6:0] I_scan_count,
    input wire I_scan_committed,
    input wire [31:0] I_scan_generation,
    output wire O_client_abort,O_allow_start,O_ready,O_busy,
    output reg O_scan_done,
    output reg [6:0] O_count,
    output reg [3:0] O_error,O_scan_error,
    output reg [7:0] O_mount_error,
    output reg [3:0] O_mount_storage_error,
    output reg [31:0] O_generation
);
    localparam [3:0] OFF=0,DRAIN=1,MOUNT_SEND=2,MOUNT_WAIT=3,RETRY=4,
        SCAN_SEND=5,SCAN_WAIT=6,READY=7,FAILED=8;
    reg [3:0] S_state;
    reg S_restart,S_rescan;
    reg [31:0] S_retry;
    reg [15:0] S_next_tag,S_tag;
    wire S_stop=!I_enable || !I_card_ready || I_reload || S_restart;
    wire S_lost=!I_mounted || I_generation!=O_generation;
    wire S_session=S_state==SCAN_SEND || S_state==SCAN_WAIT || S_state==READY || S_state==FAILED;
    assign O_client_abort=!I_reset && (S_stop || !I_mounted ||
        S_state==OFF || S_state==DRAIN || S_state==MOUNT_SEND || S_state==MOUNT_WAIT ||
        S_state==RETRY || (S_session && S_lost));
    assign O_scan_abort=O_client_abort;
    assign O_unmount=!I_reset && (!I_enable || I_reload || S_state==DRAIN);
    assign O_mount_valid=!I_reset && S_state==MOUNT_SEND && !S_stop;
    assign O_mount_result_ready=!I_reset && S_state==MOUNT_WAIT;
    assign O_scan_start_valid=!I_reset && S_state==SCAN_SEND && !S_stop && !S_lost;
    assign O_scan_done_ready=!I_reset && S_state==SCAN_WAIT;
    assign O_scan_tag=S_tag;
    assign O_scan_generation=O_generation;
    assign O_ready=!I_reset && S_state==READY && !S_stop && !S_lost;
    assign O_allow_start=O_ready && !I_rescan && !S_rescan;
    assign O_busy=!I_reset && S_state!=OFF && S_state!=READY && S_state!=FAILED;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=OFF; S_restart<=0; S_rescan<=0; S_retry<=0;
            S_next_tag<=16'd1; S_tag<=0;
            O_scan_done<=0; O_count<=0; O_error<=0; O_scan_error<=0;
            O_mount_error<=0; O_mount_storage_error<=0; O_generation<=0;
        end else begin
            O_scan_done<=0;
            if(I_rescan) S_rescan<=1;
            if(!I_enable || !I_card_ready || I_reload) S_restart<=1;
            case(S_state)
                OFF:begin
                    S_restart<=0; O_count<=0;
                    if(I_enable && I_card_ready && !I_reload) S_state<=DRAIN;
                end
                DRAIN:begin
                    S_restart<=0; O_count<=0;
                    if(!I_enable || !I_card_ready) S_state<=OFF;
                    else if(!I_reload && I_storage_quiescent) S_state<=MOUNT_SEND;
                end
                MOUNT_SEND:if(S_stop) S_state<=DRAIN;
                    else if(I_mount_ready) S_state<=MOUNT_WAIT;
                MOUNT_WAIT:if(I_mount_result_valid) begin
                    O_mount_error<=I_mount_error; O_mount_storage_error<=I_mount_storage_error;
                    if(S_stop) S_state<=DRAIN;
                    else if(I_mount_error!=0 || I_mount_storage_error!=0 || !I_mounted ||
                        I_mount_generation!=I_generation) begin
                        O_error<=1; S_retry<=RETRY_CYCLES>0 ? RETRY_CYCLES-1'b1 : 0; S_state<=RETRY;
                    end else begin
                        O_generation<=I_mount_generation; O_error<=0; O_scan_error<=0;
                        S_tag<=S_next_tag; S_state<=SCAN_SEND;
                    end
                end
                RETRY:if(S_stop) S_state<=DRAIN;
                    else if(S_retry==0) S_state<=DRAIN;
                    else S_retry<=S_retry-1'b1;
                SCAN_SEND:if(S_stop || S_lost) S_state<=DRAIN;
                    else if(I_scan_start_ready) begin
                        S_next_tag<=S_next_tag+16'd2; S_rescan<=I_rescan; S_state<=SCAN_WAIT;
                    end
                SCAN_WAIT:begin
                    if(S_lost) S_restart<=1;
                    if(I_scan_done_valid) begin
                        O_scan_done<=1; O_scan_error<=I_scan_error;
                        if(S_stop || S_lost) S_state<=DRAIN;
                        else if(I_scan_error!=0 || !I_scan_committed || I_scan_count==0 ||
                            I_scan_generation!=O_generation) begin
                            O_count<=0; O_error<=2; S_state<=FAILED;
                        end else begin O_count<=I_scan_count; O_error<=0; S_state<=READY; end
                    end
                end
                READY,FAILED:if(S_stop || S_lost) S_state<=DRAIN;
                    else if(S_rescan || I_rescan) begin S_tag<=S_next_tag; S_state<=SCAN_SEND; end
                default:S_state<=DRAIN;
            endcase
        end
    end
endmodule
