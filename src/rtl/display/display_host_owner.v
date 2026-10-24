// Host display transaction owner. Real lease/guard; publisher and commit are endpoints.
// Publish done MUST prove video installation, not merely local queue acceptance.
module display_host_owner (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [246:0] I_config,
    input wire [15:0] I_tag,
    input wire I_abort,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,O_lease_error,O_slot_error,O_commit_error,O_prepare_error,O_retire_error,
    output reg [15:0] O_tag,
    output reg [31:0] O_epoch,O_previous_epoch,
    output reg O_applied,O_retired,O_cancel_late,O_quarantined,O_response_discarded,
    output reg [1:0] O_acquired_mask,O_released_mask,O_active_mask,
    output reg O_active_valid,
    output reg [31:0] O_active_epoch,
    output reg [246:0] O_active_config,
    output reg [1:0] O_host_reserve,
    output wire [1:0] O_source_idle,O_source_busy,
    output wire O_publish_valid,
    input wire I_publish_ready,
    output reg [137:0] O_publish_leases,
    output reg [31:0] O_publish_version,
    input wire I_publish_done_valid,
    output wire O_publish_done_ready,
    input wire [31:0] I_publish_done_version,
    input wire [3:0] I_publish_error,
    output wire O_commit_valid,
    input wire I_commit_ready,
    output wire [246:0] O_commit_config,
    output wire [15:0] O_commit_tag,
    output wire O_commit_abort,
    input wire [31:0] I_commit_next_epoch,
    input wire I_commit_done_valid,
    output wire O_commit_done_ready,
    input wire [15:0] I_commit_tag,
    input wire [31:0] I_commit_epoch,I_commit_previous_epoch,
    input wire [3:0] I_commit_error,I_commit_prepare_error,I_commit_retire_error,
    input wire I_commit_applied,I_commit_retired,I_commit_quarantined,
    output wire [1:0] O_owned,
    output wire [1:0] O_lease_valid,
    output wire [5:0] O_lease_slots,
    output wire [63:0] O_lease_tokens,
    output wire [63:0] O_lease_generations,
    output wire [1:0] O_lease_resident,
    input wire [17:0] I_slot_states,
    input wire [17:0] I_slot_readers,
    input wire [191:0] I_slot_tokens,
    input wire [191:0] I_slot_generations,
    input wire [5:0] I_slot_resident,
    output wire  O_slot_cmd_valid,
    input wire  I_slot_cmd_ready,
    output wire [2:0] O_slot_cmd_op,
    output wire [2:0] O_slot_cmd_slot,
    output wire [1:0] O_slot_cmd_owner,
    output wire [31:0] O_slot_cmd_token,
    output wire [31:0] O_slot_cmd_generation,
    output wire  O_slot_frame_boundary,
    output wire  O_slot_reader_retired,
    input wire  I_slot_result_valid,
    output wire  O_slot_result_ready,
    input wire [3:0] I_slot_result_error,
    input wire [2:0] I_slot_result_op,
    input wire [2:0] I_slot_result_slot,
    input wire [1:0] I_slot_result_owner,
    input wire [31:0] I_slot_result_token,
    input wire [31:0] I_slot_result_generation,
    input wire [20:0] I_slot_result_base,
    input wire  I_video_frame_start,
    input wire [1:0] I_video_in_use,
    input wire [1:0] I_video_reader_ack,
    input wire [1:0] I_video_owner_retired,
    input wire [1:0] I_video_pipeline_retired,
    output wire [1:0] O_video_block,
    output wire [1:0] O_video_reader_stop,
    output wire [1:0] O_video_retire_ack,
    output wire [1:0] O_video_fault
);
    wire  S_l_O_start_ready;
    wire [1:0] S_l_O_retire_request;
    wire  S_l_O_busy;
    wire  S_l_O_done_valid;
    wire [3:0] S_l_O_error;
    wire  S_l_O_op;
    wire  S_l_O_source;
    wire [2:0] S_l_O_slot;
    wire [31:0] S_l_O_token;
    wire [31:0] S_l_O_generation;
    wire [15:0] S_l_O_tag;
    wire  S_l_O_changed;
    wire  S_l_O_cancel_late;
    wire  S_l_O_quarantined;
    wire  S_l_O_response_discarded;
    wire [3:0] S_l_O_slot_error;
    wire [1:0] S_g_O_host_acquire_permit,S_g_O_host_retire_ack,S_g_O_host_fault;
    wire S_reset;
    reset_sync u_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_reset));
    localparam [3:0] IDLE=0,ACQUIRE_SELECT=1,CLEANUP_SELECT=2,GUARD_WAIT=3,
        LEASE_SEND=4,LEASE_WAIT=5,PUBLISH_SEND=6,PUBLISH_WAIT=7,
        UNRESERVE=8,GUARD_CLEAR=9,COMMIT_SEND=10,COMMIT_WAIT=11,FINISH_WAIT=12,RESULT=13;
    reg [3:0] S_state;
    reg [246:0] S_config;
    reg [1:0] S_need_acquire,S_cleanup,S_new_owned;
    reg S_source,S_releasing,S_cleanup_mode,S_cancel,S_commit_started;
    reg [31:0] S_expected_epoch;
    reg [2:0] S_release_slot;
    reg [31:0] S_release_token,S_release_generation;
    wire S_cancel_now=S_cancel || I_abort;
    wire [1:0] S_mask=S_config[246:245];
    wire [5:0] S_slots=S_config[243:238];
    wire [63:0] S_tokens=S_config[237:174],S_generations=S_config[173:110];
    wire [2:0] S_lease_slot=S_releasing ? S_release_slot : S_slots[S_source*3+:3];
    wire [31:0] S_lease_token=S_releasing ? S_release_token : S_tokens[S_source*32+:32];
    wire [31:0] S_lease_generation=S_releasing ? S_release_generation : S_generations[S_source*32+:32];
    wire S_live_fault=S_l_O_quarantined || |S_g_O_host_fault;
    wire S_fault=O_quarantined || S_live_fault;
    wire S_lease_start=!S_reset && S_state==LEASE_SEND;
    wire S_publish_match=I_publish_done_version==O_publish_version;
    wire S_commit_match=I_commit_tag==O_tag &&
        I_commit_previous_epoch==(I_commit_applied ? O_active_epoch : 32'd0) &&
        (I_commit_epoch==S_expected_epoch || (!I_commit_applied && I_commit_error!=0 && I_commit_epoch==0));
    wire S_lease_match=S_l_O_op==S_releasing && S_l_O_source==S_source &&
        S_l_O_slot==S_lease_slot && S_l_O_token==S_lease_token &&
        S_l_O_generation==S_lease_generation && S_l_O_tag==O_tag;
    assign O_start_ready=!I_async_reset && !S_reset && S_state==IDLE && !S_fault;
    assign O_busy=S_state!=IDLE || O_quarantined;
    assign O_done_valid=!S_reset && S_state==RESULT;
    assign O_publish_valid=!S_reset && S_state==PUBLISH_SEND;
    assign O_publish_done_ready=!S_reset && (S_state==PUBLISH_WAIT || (S_state==PUBLISH_SEND && I_publish_ready));
    assign O_commit_valid=!S_reset && S_state==COMMIT_SEND;
    assign O_commit_config=S_config;
    assign O_commit_tag=O_tag;
    assign O_commit_abort=(S_state==COMMIT_SEND || S_state==COMMIT_WAIT) && (S_cancel_now || S_fault);
    assign O_commit_done_ready=!S_reset && S_state==COMMIT_WAIT;
    reg C_range_ok,C_conflict;
    integer C_i,C_slot;
    always @* begin
        C_range_ok=I_config[246:245]!=0 &&
            (I_config[244] ? I_config[246] : I_config[245]) &&
            I_config[107:105]<=6 && I_config[88:72]<=65536 &&
            (I_config[88:72]==0 || I_config[246:245]==3) &&
            (I_config[246:245]!=3 || I_config[104:89]!=0) &&
            (I_config[71:68]<=4 || I_config[71:68]>=12) &&
            (I_config[67:64]<=4 || I_config[67:64]>=12) &&
            I_config[63:59]<=16 && I_config[58:56]<=4;
        C_conflict=0; C_slot=0;
        for(C_i=0;C_i<2;C_i=C_i+1) if(I_config[245+C_i]) begin
            C_slot=I_config[238+C_i*3+:3];
            if(C_slot>=6 || I_config[174+C_i*32+:32]==0 ||
                I_config[34+C_i*9+:9]>=480 || (I_config[108+C_i] && C_slot!=5)) C_range_ok=0;
            if(O_owned[C_i] && (!O_lease_valid[C_i] || O_lease_slots[C_i*3+:3]!=C_slot ||
                O_lease_tokens[C_i*32+:32]!=I_config[174+C_i*32+:32] ||
                O_lease_generations[C_i*32+:32]!=I_config[110+C_i*32+:32] ||
                O_lease_resident[C_i]!=I_config[108+C_i])) C_conflict=1;
        end
    end
    always @(posedge I_host_clk or posedge S_reset) begin
        if(S_reset) begin
            S_state<=IDLE; S_config<=0; S_need_acquire<=0; S_cleanup<=0; S_new_owned<=0;
            S_source<=0; S_releasing<=0; S_cleanup_mode<=0; S_cancel<=0; S_commit_started<=0;
            S_expected_epoch<=0; S_release_slot<=0; S_release_token<=0; S_release_generation<=0;
            O_error<=0; O_lease_error<=0; O_slot_error<=0; O_commit_error<=0; O_prepare_error<=0; O_retire_error<=0;
            O_tag<=0; O_epoch<=0; O_previous_epoch<=0; O_applied<=0; O_retired<=0; O_cancel_late<=0;
            O_quarantined<=0; O_response_discarded<=0; O_acquired_mask<=0; O_released_mask<=0;
            O_active_valid<=0; O_active_epoch<=0; O_active_mask<=0; O_active_config<=0; O_host_reserve<=0;
            O_publish_leases<=0; O_publish_version<=0;
        end else begin
            O_response_discarded<=S_l_O_response_discarded;
            if(S_state!=IDLE && S_state!=RESULT && I_abort) begin
                S_cancel<=1; if(O_applied) O_cancel_late<=1;
            end
            if(S_live_fault) begin
                O_quarantined<=1;
                if(S_state!=RESULT) O_error<=8;
            end
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    S_config<=I_config; O_tag<=I_tag; S_cancel<=I_abort;
                    S_need_acquire<=I_config[246:245] & ~O_owned; S_cleanup<=0; S_new_owned<=0;
                    S_cleanup_mode<=0; S_commit_started<=0;
                    O_error<=0; O_lease_error<=0; O_slot_error<=0; O_commit_error<=0; O_prepare_error<=0; O_retire_error<=0;
                    O_epoch<=0; O_previous_epoch<=0; O_applied<=0; O_retired<=0; O_cancel_late<=0;
                    O_acquired_mask<=0; O_released_mask<=0;
                    if(!C_range_ok) begin O_error<=1; S_state<=RESULT; end
                    else if(C_conflict) begin O_error<=2; S_state<=RESULT; end
                    else if(I_abort) begin O_error<=3; S_state<=RESULT; end
                    else S_state<=ACQUIRE_SELECT;
                end
                ACQUIRE_SELECT:begin
                    if(S_fault) S_state<=RESULT;
                    else if(S_cancel_now) begin
                        O_error<=3; S_cleanup<=S_new_owned; S_cleanup_mode<=1; S_state<=CLEANUP_SELECT;
                    end else if(S_need_acquire==0) S_state<=COMMIT_SEND;
                    else begin
                        S_source<=!S_need_acquire[0]; S_releasing<=0;
                        O_host_reserve<=S_need_acquire[0] ? 2'b01 : 2'b10; S_state<=GUARD_WAIT;
                    end
                end
                CLEANUP_SELECT:begin
                    if(S_fault) S_state<=RESULT;
                    else if(S_cleanup==0) S_state<=FINISH_WAIT;
                    else begin
                        S_source<=!S_cleanup[0]; S_releasing<=1;
                        S_release_slot<=S_cleanup[0] ? O_lease_slots[2:0] : O_lease_slots[5:3];
                        S_release_token<=S_cleanup[0] ? O_lease_tokens[31:0] : O_lease_tokens[63:32];
                        S_release_generation<=S_cleanup[0] ? O_lease_generations[31:0] : O_lease_generations[63:32];
                        O_host_reserve<=S_cleanup[0] ? 2'b01 : 2'b10; S_state<=GUARD_WAIT;
                    end
                end
                GUARD_WAIT:begin
                    if(S_fault) S_state<=RESULT;
                    else if(!S_releasing && S_cancel_now) begin
                        O_error<=3; S_cleanup<=S_new_owned; S_cleanup_mode<=1; S_state<=UNRESERVE;
                    end else if(O_source_idle[S_source] && S_g_O_host_acquire_permit[S_source]) S_state<=LEASE_SEND;
                end
                LEASE_SEND:if(S_lease_start && S_l_O_start_ready) S_state<=LEASE_WAIT;
                LEASE_WAIT:if(S_l_O_done_valid) begin
                    if(O_lease_error==0) begin O_lease_error<=S_l_O_error; O_slot_error<=S_l_O_slot_error; end
                    if(S_l_O_cancel_late) O_cancel_late<=1;
                    if(!S_lease_match || S_fault || (S_l_O_error==0 && !S_l_O_changed)) begin
                        O_error<=8; O_quarantined<=1; S_state<=RESULT;
                    end else begin
                        if(S_releasing) begin
                            if(S_l_O_error!=0 || !S_l_O_changed || O_owned[S_source]) begin
                                O_error<=6; O_quarantined<=1; S_state<=RESULT;
                            end else begin
                                S_cleanup[S_source]<=0; S_new_owned[S_source]<=0; O_released_mask[S_source]<=1;
                                S_state<=PUBLISH_SEND;
                            end
                        end else begin
                            S_need_acquire[S_source]<=0;
                            if(S_l_O_changed) begin S_new_owned[S_source]<=1; O_acquired_mask[S_source]<=1; end
                            if(S_l_O_error!=0 || S_cancel_now) begin
                                O_error<=S_cancel_now || S_l_O_error==5 ? 4'd3 : 4'd4;
                                S_cleanup<=S_new_owned | (S_l_O_changed ? (2'b01<<S_source) : 2'b00);
                                S_cleanup_mode<=1;
                            end
                            S_state<=S_l_O_changed ? PUBLISH_SEND : UNRESERVE;
                        end
                        if(S_l_O_changed && (!S_releasing || S_l_O_error==0)) begin
                            if(&O_publish_version) begin O_error<=9; O_quarantined<=1; S_state<=RESULT; end
                            else begin
                                O_publish_version<=O_publish_version+1'b1;
                                O_publish_leases<={O_lease_valid,O_lease_slots,O_lease_tokens,O_lease_generations,O_lease_resident};
                            end
                        end
                    end
                end
                PUBLISH_SEND:if(I_publish_ready) S_state<=PUBLISH_WAIT;
                PUBLISH_WAIT:begin end
                UNRESERVE:begin O_host_reserve[S_source]<=0; S_state<=GUARD_CLEAR; end
                GUARD_CLEAR:begin
                    if(S_fault) S_state<=RESULT;
                    else if(!O_source_busy[S_source] && !O_source_idle[S_source] && !S_g_O_host_retire_ack[S_source])
                        S_state<=S_cleanup_mode ? CLEANUP_SELECT : ACQUIRE_SELECT;
                end
                COMMIT_SEND:if(I_commit_ready) begin
                    S_expected_epoch<=I_commit_next_epoch; S_commit_started<=1; S_state<=COMMIT_WAIT;
                end
                COMMIT_WAIT:if(I_commit_done_valid) begin
                    if(!S_commit_match) O_response_discarded<=1;
                    else begin
                        O_epoch<=I_commit_epoch; O_previous_epoch<=I_commit_previous_epoch;
                        O_commit_error<=I_commit_error; O_prepare_error<=I_commit_prepare_error; O_retire_error<=I_commit_retire_error;
                        O_applied<=I_commit_applied; O_retired<=I_commit_retired;
                        if(I_commit_applied) begin
                            O_active_valid<=1; O_active_epoch<=I_commit_epoch; O_active_config<=S_config; O_active_mask<=S_mask;
                            if(S_cancel_now) O_cancel_late<=1;
                        end
                        if(S_fault || I_commit_quarantined || I_commit_retire_error!=0 ||
                            (I_commit_applied && (I_commit_error!=0 || !I_commit_retired || I_commit_epoch==0)) ||
                            (I_commit_error==0 && (!I_commit_applied || !I_commit_retired || I_commit_epoch==0)) ||
                            (!I_commit_applied && !I_commit_retired && I_commit_epoch!=0)) begin
                            O_error<=8; O_quarantined<=1; S_state<=RESULT;
                        end else begin
                            O_error<=I_commit_error==0 ? 4'd0 : I_commit_error==3 ? 4'd3 : 4'd5;
                            S_cleanup<=I_commit_applied ? (O_owned & ~S_mask) : S_new_owned;
                            S_cleanup_mode<=1; S_state<=CLEANUP_SELECT;
                        end
                    end
                end
                FINISH_WAIT:begin
                    if(S_fault) S_state<=RESULT;
                    else if(!S_commit_started || I_commit_ready) S_state<=RESULT;
                end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin O_error<=8; O_quarantined<=1; S_state<=RESULT; end
            endcase
            if(I_publish_done_valid && O_publish_done_ready) begin
                if(!S_publish_match) O_response_discarded<=1;
                else if(I_publish_error!=0 || S_fault) begin O_error<=7; O_quarantined<=1; S_state<=RESULT; end
                else S_state<=UNRESERVE;
            end
        end
    end
    display_lease_ctrl u_display_lease_ctrl (
        .I_clk(I_host_clk),
        .I_reset(S_reset),
        .I_start_valid(S_lease_start),
        .O_start_ready(S_l_O_start_ready),
        .I_op(S_releasing),
        .I_source(S_source),
        .I_slot(S_lease_slot),
        .I_token(S_lease_token),
        .I_generation(S_lease_generation),
        .I_tag(O_tag),
        .I_abort(!S_releasing && S_cancel_now),
        .I_source_idle(O_source_idle),
        .I_acquire_permit(S_g_O_host_acquire_permit),
        .I_retire_ack(S_g_O_host_retire_ack),
        .O_retire_request(S_l_O_retire_request),
        .O_busy(S_l_O_busy),
        .O_done_valid(S_l_O_done_valid),
        .I_done_ready(S_state==LEASE_WAIT),
        .O_error(S_l_O_error),
        .O_slot_error(S_l_O_slot_error),
        .O_op(S_l_O_op),
        .O_source(S_l_O_source),
        .O_slot(S_l_O_slot),
        .O_token(S_l_O_token),
        .O_generation(S_l_O_generation),
        .O_tag(S_l_O_tag),
        .O_changed(S_l_O_changed),
        .O_cancel_late(S_l_O_cancel_late),
        .O_quarantined(S_l_O_quarantined),
        .O_response_discarded(S_l_O_response_discarded),
        .O_owned(O_owned),
        .O_lease_valid(O_lease_valid),
        .O_lease_slots(O_lease_slots),
        .O_lease_tokens(O_lease_tokens),
        .O_lease_generations(O_lease_generations),
        .O_lease_resident(O_lease_resident),
        .I_slot_states(I_slot_states),
        .I_slot_readers(I_slot_readers),
        .I_slot_tokens(I_slot_tokens),
        .I_slot_generations(I_slot_generations),
        .I_slot_resident(I_slot_resident),
        .O_slot_cmd_valid(O_slot_cmd_valid),
        .I_slot_cmd_ready(I_slot_cmd_ready),
        .O_slot_cmd_op(O_slot_cmd_op),
        .O_slot_cmd_slot(O_slot_cmd_slot),
        .O_slot_cmd_owner(O_slot_cmd_owner),
        .O_slot_cmd_token(O_slot_cmd_token),
        .O_slot_cmd_generation(O_slot_cmd_generation),
        .O_slot_frame_boundary(O_slot_frame_boundary),
        .O_slot_reader_retired(O_slot_reader_retired),
        .I_slot_result_valid(I_slot_result_valid),
        .O_slot_result_ready(O_slot_result_ready),
        .I_slot_result_error(I_slot_result_error),
        .I_slot_result_op(I_slot_result_op),
        .I_slot_result_slot(I_slot_result_slot),
        .I_slot_result_owner(I_slot_result_owner),
        .I_slot_result_token(I_slot_result_token),
        .I_slot_result_generation(I_slot_result_generation),
        .I_slot_result_base(I_slot_result_base)
    );
    display_source_guard u_display_source_guard (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_host_reserve(O_host_reserve),
        .I_host_retire_request(S_l_O_retire_request),
        .O_host_source_idle(O_source_idle),
        .O_host_acquire_permit(S_g_O_host_acquire_permit),
        .O_host_retire_ack(S_g_O_host_retire_ack),
        .O_host_busy(O_source_busy),
        .O_host_fault(S_g_O_host_fault),
        .I_video_frame_start(I_video_frame_start),
        .I_video_in_use(I_video_in_use),
        .I_video_reader_ack(I_video_reader_ack),
        .I_video_owner_retired(I_video_owner_retired),
        .I_video_pipeline_retired(I_video_pipeline_retired),
        .O_video_block(O_video_block),
        .O_video_reader_stop(O_video_reader_stop),
        .O_video_retire_ack(O_video_retire_ack),
        .O_video_fault(O_video_fault)
    );
endmodule
