// Video-domain adapter: real pin confirmation before start and after final hold.
// Sole caller of both pin updates and transition start/recovery. No clock crossing.
module playback_image_ctrl (
    input wire I_clk,I_reset,I_clock_enable,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [403:0] I_command,
    input wire I_abort,
    output wire O_transition_start_valid,
    input wire I_transition_start_ready,
    output wire [403:0] O_command,
    output wire O_transition_abort,
    input wire I_transition_busy,I_transition_done_valid,
    output wire O_transition_done_ready,
    input wire [31:0] I_transition_epoch,
    input wire [15:0] I_transition_tag,
    input wire [246:0] I_transition_config,
    input wire [1:0] I_transition_hold,
    input wire [3:0] I_transition_error,
    input wire I_transition_settled,I_transition_quarantined,
    input wire I_recover_valid,I_recover_source,
    output wire O_recover_ready,O_transition_recover_valid,O_transition_recover_source,
    input wire I_transition_recover_ready,
    output wire O_pin_update_valid,
    input wire I_pin_update_ready,
    output wire [31:0] O_pin_epoch,
    output wire [15:0] O_pin_tag,
    output wire [137:0] O_pin_reservation,
    input wire I_pin_done_valid,
    output wire O_pin_done_ready,
    input wire [31:0] I_pin_epoch,I_pin_installed_epoch,
    input wire [15:0] I_pin_tag,I_pin_installed_tag,
    input wire [3:0] I_pin_error,
    input wire [137:0] I_pin_installed_reservation,I_images,
    input wire I_pin_quarantined,
    input wire I_retry_pin_valid,
    output wire O_retry_pin_ready,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output wire [31:0] O_epoch,
    output wire [15:0] O_tag,
    output reg [3:0] O_error,O_pin_error,
    output reg O_transition_started,O_sync_required,O_retry_result,O_cancel_late,O_quarantined,O_response_discarded
);
    localparam [2:0] IDLE=0,OFFER=1,WAIT_PIN=2,IMAGES=3,START=4,RUN=5,RESULT=6;
    localparam [1:0] INITIAL=0,FINAL=1,RESTORE=2,RETRY=3;
    reg [2:0] S_state;
    reg [1:0] S_purpose;
    reg [403:0] S_command;
    reg [137:0] S_reservation,S_installed,S_prior;
    reg [31:0] S_last_epoch;
    reg S_cancel,S_hold_result;
    wire [31:0] S_epoch=S_command[403:372];
    wire [15:0] S_tag=S_command[371:356];
    wire [246:0] S_config=S_command[355:109];
    wire [15:0] S_duration=I_command[105:90];
    wire signed [6:0] S_offset=I_command[89:83];
    wire [246:0] S_input_config=I_command[355:109];
    wire [1:0] S_audio_action=I_command[82:81];
    wire S_input_bad=I_command[403:372]==0 || I_command[403:372]<=S_last_epoch ||
        S_input_config[246:245]!=3 || S_input_config[52] || I_command[108:106]>6 ||
        S_duration==0 || S_duration>60 || S_offset< -7'sd50 || S_offset>7'sd50 ||
        (S_audio_action!=0 && I_command[63:32]==0) || (S_audio_action==1 && I_command[80]);
    wire S_fault=O_quarantined || I_pin_quarantined || I_transition_quarantined;
    wire S_abort_now=S_cancel || I_abort || !I_clock_enable || S_fault;
    wire S_pin_match=I_pin_epoch==S_epoch && I_pin_tag==S_tag;
    wire S_installed_match=I_pin_installed_epoch==S_epoch && I_pin_installed_tag==S_tag &&
        I_pin_installed_reservation==S_reservation;
    wire S_images_ok=I_images=={2'b11,S_reservation[135:0]};
    wire [137:0] S_final_reservation={I_transition_hold,S_config[243:238],S_config[237:174],
        S_config[173:110],S_config[109:108]};
    wire S_result_match=I_transition_epoch==S_epoch && I_transition_tag==S_tag && I_transition_config==S_config;
    wire S_hold_ok=(I_transition_settled ? (I_transition_hold==1 || I_transition_hold==2) : I_transition_hold==3) &&
        (I_transition_error!=0 || I_transition_settled);
    assign O_start_ready=!I_reset && S_state==IDLE && !S_fault && !O_sync_required && !I_transition_busy && !I_recover_valid;
    assign O_recover_ready=!I_reset && S_state==IDLE && !S_fault && !O_sync_required && I_transition_recover_ready;
    assign O_transition_recover_valid=I_recover_valid && O_recover_ready;
    assign O_transition_recover_source=I_recover_source;
    assign O_retry_pin_ready=!I_reset && S_state==IDLE && O_sync_required && !S_fault;
    assign O_transition_start_valid=!I_reset && S_state==START;
    assign O_command=S_command;
    assign O_transition_abort=S_abort_now;
    assign O_transition_done_ready=!I_reset && S_state==RESULT && S_hold_result && I_done_ready;
    assign O_pin_update_valid=!I_reset && S_state==OFFER;
    assign {O_pin_epoch,O_pin_tag,O_pin_reservation}={S_epoch,S_tag,S_reservation};
    assign O_pin_done_ready=!I_reset && S_state==WAIT_PIN;
    assign O_busy=S_state!=IDLE || O_sync_required || S_fault || I_transition_busy;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_epoch=S_epoch;
    assign O_tag=S_tag;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_purpose<=INITIAL; S_command<=0; S_reservation<=0; S_installed<=0; S_prior<=0;
            S_last_epoch<=0; S_cancel<=0; S_hold_result<=0;
            O_error<=0; O_pin_error<=0; O_transition_started<=0; O_sync_required<=0; O_retry_result<=0;
            O_cancel_late<=0; O_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            if(S_state!=IDLE && S_state!=RESULT && S_abort_now) begin
                S_cancel<=1;
                if(S_purpose==INITIAL && !O_transition_started && O_error==0)
                    O_error<=!I_clock_enable ? 4'd5 : 4'd3;
            end
            if(S_state!=IDLE && S_state!=RESULT && I_pin_quarantined) O_quarantined<=1;
            if((S_purpose==FINAL || S_purpose==RETRY) && S_state!=IDLE && S_state!=RESULT && I_abort)
                O_cancel_late<=1;
            case(S_state)
                IDLE:if(I_retry_pin_valid && O_retry_pin_ready) begin
                    O_error<=0; O_pin_error<=0; O_retry_result<=1; O_cancel_late<=0;
                    S_purpose<=RETRY; S_cancel<=0; S_state<=OFFER;
                end else if(I_start_valid && O_start_ready) begin
                    S_command<=I_command;
                    S_command[213:198]<=S_duration; // config.duration
                    S_command[160:143]<=0;         // config.first_y
                    S_prior<=S_installed; S_cancel<=I_abort || !I_clock_enable; S_hold_result<=0;
                    O_transition_started<=0; O_retry_result<=0; O_cancel_late<=0; O_pin_error<=0;
                    if(S_input_bad) begin O_error<=1; S_state<=RESULT; end
                    else begin
                        S_last_epoch<=I_command[403:372];
                        S_reservation<={2'b11,S_input_config[243:238],S_input_config[237:174],
                            S_input_config[173:110],S_input_config[109:108]};
                        S_purpose<=INITIAL;
                        if(I_abort || !I_clock_enable) begin O_error<=!I_clock_enable ? 4'd5 : 4'd3; S_state<=RESULT; end
                        else begin O_error<=0; S_state<=OFFER; end
                    end
                end else if(O_transition_recover_valid && I_transition_recover_ready) begin
                    O_error<=0; O_pin_error<=0; O_retry_result<=0; O_cancel_late<=0;
                    O_transition_started<=1; S_cancel<=0; S_purpose<=INITIAL; S_state<=RUN;
                end
                OFFER:if(I_pin_update_ready) S_state<=WAIT_PIN;
                WAIT_PIN:if(I_pin_done_valid) begin
                    if(!S_pin_match) O_response_discarded<=1;
                    else if(I_pin_error!=0 || !S_installed_match) begin
                        O_pin_error<=I_pin_error!=0 ? I_pin_error : 4'd4;
                        if(O_error==0) O_error<=8;
                        if(!S_installed_match && I_pin_error==0) O_quarantined<=1;
                        if(S_purpose!=INITIAL) O_sync_required<=1;
                        S_state<=RESULT;
                    end else begin
                        S_installed<=S_reservation;
                        if(S_purpose==INITIAL) begin
                            if(S_abort_now) begin S_reservation<=S_prior; S_purpose<=RESTORE; S_state<=OFFER; end
                            else S_state<=IMAGES;
                        end else begin O_sync_required<=0; S_state<=RESULT; end
                    end
                end
                IMAGES:if(S_abort_now) begin S_reservation<=S_prior; S_purpose<=RESTORE; S_state<=OFFER; end
                    else if(S_images_ok) S_state<=START;
                START:if(I_transition_start_ready) begin O_transition_started<=1; S_state<=RUN; end
                RUN:if(I_transition_done_valid) begin
                    if(!S_result_match) O_response_discarded<=1;
                    else begin
                        S_hold_result<=1; O_error<=I_transition_error;
                        if(I_transition_quarantined || !S_hold_ok) O_quarantined<=1;
                        if(!S_hold_ok) begin O_error<=8; O_sync_required<=1; S_state<=RESULT; end
                        else begin
                            S_reservation<=S_final_reservation; S_purpose<=FINAL;
                            if(S_fault) begin
                                if(I_transition_error==0) O_error<=8;
                                O_pin_error<=4; O_sync_required<=1; S_state<=RESULT;
                            end
                            else if(S_installed==S_final_reservation) S_state<=RESULT;
                            else S_state<=OFFER;
                        end
                    end
                end
                RESULT:if(I_done_ready) begin S_hold_result<=0; S_state<=IDLE; end
                default:begin O_error<=8; O_sync_required<=1; O_quarantined<=1; S_state<=RESULT; end
            endcase
        end
    end
endmodule
