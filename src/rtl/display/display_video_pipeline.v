// Actual video resource pipeline; configuration CDC, host leases and deadlines external.
// All owners, memory and clocks share I_async_reset; no media flush/reset here.
module display_video_pipeline (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_prepare_valid,
    output wire O_prepare_ready,
    input wire [246:0] I_pending_config,
    input wire [31:0] I_pending_epoch,
    input wire [15:0] I_pending_tag,
    input wire I_prepare_abort,I_prepare_deadline_valid,
    input wire [31:0] I_prepare_deadline_epoch,
    input wire [63:0] I_prepare_deadlines,
    output wire O_prepare_done_valid,
    input wire I_prepare_done_ready,
    output reg [3:0] O_prepare_error,
    output wire [31:0] O_prepare_epoch,
    output wire [15:0] O_prepare_tag,
    input wire I_apply_valid,
    output wire O_can_apply,
    input wire I_retire_valid,
    output wire O_retire_ready,
    input wire I_retire_old,
    input wire [246:0] I_retire_config,
    input wire [31:0] I_retire_epoch,
    input wire [15:0] I_retire_tag,
    output wire O_retire_done_valid,
    input wire I_retire_done_ready,
    output reg [3:0] O_retire_error,
    output reg [31:0] O_retire_epoch,
    output reg [15:0] O_retire_tag,
    input wire [1:0] I_authorized,I_source_block,
    input wire [1:0] I_lease_valid,
    input wire [5:0] I_lease_slots,
    input wire [63:0] I_lease_tokens,I_lease_generations,
    input wire I_scan_deadline_valid,
    input wire [8:0] I_scan_deadline_y,
    input wire [31:0] I_scan_deadline_epoch,I_scan_deadline,
    input wire I_scan_stop,
    output wire O_scan_stop_ack,
    input wire [1:0] I_reader_retire_request,
    output wire [1:0] O_reader_retire_ack,O_reader_host_retired,
    output wire [1:0] O_source_in_use,O_source_owner_retired,O_source_pipeline_retired,
    output wire [8:0] O_prefetch_y,
    output wire [31:0] O_active_epoch,
    output wire O_frame_start,O_local_applied,O_busy,
    output wire [3:0] O_bank_busy,
    output reg O_contract_fault,O_quarantined,
    output wire O_valid,O_hsync,O_vsync,O_de,
    output wire [15:0] O_x,O_y,
    output wire [23:0] O_rgb,
    output wire [31:0] O_epoch,
    output wire [15:0] O_tag,
    output wire O_repeated,O_pixel_fault,O_video_und,
    output wire [31:0] O_und_count,O_line_error_count,
    output wire [1:0] O_mem_valid,
    input wire [1:0] I_mem_ready,
    output wire [41:0] O_mem_addr,
    output wire [63:0] O_mem_tag,O_mem_token,O_mem_generation,O_mem_deadline,
    input wire [1:0] I_mem_valid,
    output wire [1:0] O_mem_ready,
    input wire [63:0] I_mem_data,I_mem_tag,I_mem_token,I_mem_generation,
    input wire [7:0] I_mem_error
);
    localparam [3:0] P_IDLE=0,P_PLAN=1,P_QUERY_CONFIG=2,P_QUERY_WAIT=3,
        P_CANDIDATE=4,P_CANDIDATE_WAIT=5,P_DONE=6,P_HELD=7;
    localparam [1:0] R_IDLE=0,R_CANDIDATE=1,R_OLD=2,R_DONE=3;
    reg [3:0] S_state;
    reg [1:0] S_retire_state,S_reserve_mask;
    reg S_pending_valid,S_pending_good,S_cancel,S_revoked,S_active_valid,S_previous_valid,S_retire_old;
    reg [246:0] S_config,S_active_config,S_previous_config;
    reg [31:0] S_epoch,S_active_epoch,S_previous_epoch;
    reg [15:0] S_tag,S_active_tag,S_previous_tag;
    reg [63:0] S_deadlines;
    wire S_reset;
    reg [3:0] S_color_brightness,S_color_contrast;
    reg [4:0] S_color_saturation;
    wire [23:0] S_render_rgb;
    reset_sync u_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_reset));
    wire [1:0] S_cfg_source_mask;
    wire  S_cfg_from_source;
    wire [5:0] S_cfg_slots;
    wire [63:0] S_cfg_tokens;
    wire [63:0] S_cfg_generations;
    wire [1:0] S_cfg_resident;
    wire [2:0] S_cfg_effect;
    wire [15:0] S_cfg_duration_frames;
    wire [16:0] S_cfg_progress;
    wire [3:0] S_cfg_brightness;
    wire [3:0] S_cfg_contrast;
    wire [4:0] S_cfg_saturation;
    wire [2:0] S_cfg_layout;
    wire [1:0] S_cfg_rotation;
    wire  S_cfg_alert;
    wire  S_cfg_audio_required;
    wire [17:0] S_cfg_first_y;
    wire [1:0] S_cfg_first_bank;
    wire [31:0] S_cfg_first_tag;
    assign {S_cfg_source_mask,S_cfg_from_source,S_cfg_slots,S_cfg_tokens,S_cfg_generations,S_cfg_resident,S_cfg_effect,S_cfg_duration_frames,S_cfg_progress,S_cfg_brightness,S_cfg_contrast,S_cfg_saturation,S_cfg_layout,S_cfg_rotation,S_cfg_alert,S_cfg_audio_required,S_cfg_first_y,S_cfg_first_bank,S_cfg_first_tag}=S_config;
    wire [1:0] S_in_source_mask;
    wire  S_in_from_source;
    wire [5:0] S_in_slots;
    wire [63:0] S_in_tokens;
    wire [63:0] S_in_generations;
    wire [1:0] S_in_resident;
    wire [2:0] S_in_effect;
    wire [15:0] S_in_duration_frames;
    wire [16:0] S_in_progress;
    wire [3:0] S_in_brightness;
    wire [3:0] S_in_contrast;
    wire [4:0] S_in_saturation;
    wire [2:0] S_in_layout;
    wire [1:0] S_in_rotation;
    wire  S_in_alert;
    wire  S_in_audio_required;
    wire [17:0] S_in_first_y;
    wire [1:0] S_in_first_bank;
    wire [31:0] S_in_first_tag;
    assign {S_in_source_mask,S_in_from_source,S_in_slots,S_in_tokens,S_in_generations,S_in_resident,S_in_effect,S_in_duration_frames,S_in_progress,S_in_brightness,S_in_contrast,S_in_saturation,S_in_layout,S_in_rotation,S_in_alert,S_in_audio_required,S_in_first_y,S_in_first_bank,S_in_first_tag}=I_pending_config;
    wire  S_p_O_start_ready;
    wire  S_p_O_done_valid;
    wire [3:0] S_p_O_error;
    wire [2:0] S_p_O_effect;
    wire [16:0] S_p_O_progress;
    wire [31:0] S_p_O_epoch;
    wire [15:0] S_p_O_tag;
    wire [9:0] S_p_O_dx;
    wire [9:0] S_p_O_left;
    wire [8:0] S_p_O_dy;
    wire [8:0] S_p_O_top;
    wire [5:0] S_p_O_blind_count;
    wire [8:0] S_p_O_mosaic_count;
    wire [19:0] S_p_O_wipe_threshold;
    wire [31:0] S_p_O_step_x;
    wire [31:0] S_p_O_step_y;
    wire  S_q_O_config_ready;
    wire  S_q_O_configured;
    wire  S_q_O_query_use_a;
    wire  S_q_O_query_use_b;
    wire [8:0] S_q_O_query_a_y;
    wire [8:0] S_q_O_query_b_y;
    wire  S_q_O_valid;
    wire  S_q_O_hsync;
    wire  S_q_O_vsync;
    wire  S_q_O_de;
    wire  S_q_O_frame_start;
    wire  S_q_O_line_start;
    wire [15:0] S_q_O_x;
    wire [15:0] S_q_O_y;
    wire  S_q_O_use_a;
    wire  S_q_O_use_b;
    wire [9:0] S_q_O_a_x;
    wire [9:0] S_q_O_b_x;
    wire [8:0] S_q_O_a_y;
    wire [8:0] S_q_O_b_y;
    wire [16:0] S_q_O_weight;
    wire [31:0] S_q_O_epoch;
    wire [15:0] S_q_O_tag;
    wire  S_c_O_prepare_ready;
    wire  S_c_O_prepare_done_valid;
    wire [3:0] S_c_O_prepare_error;
    wire [3:0] S_c_O_line_error;
    wire [3:0] S_c_O_memory_error;
    wire [31:0] S_c_O_prepare_epoch;
    wire [15:0] S_c_O_prepare_tag;
    wire  S_c_O_adopt_ready;
    wire  S_c_O_adopted;
    wire  S_c_O_retire_ready;
    wire  S_c_O_retire_done_valid;
    wire [3:0] S_c_O_retire_error;
    wire [31:0] S_c_O_retire_epoch;
    wire [15:0] S_c_O_retire_tag;
    wire  S_c_O_busy;
    wire  S_c_O_quarantined;
    wire  S_c_O_contract_fault;
    wire [1:0] S_c_O_source_in_use;
    wire [1:0] S_c_O_source_owner_retired;
    wire [3:0] S_c_O_owned_banks;
    wire [3:0] S_c_O_claim_banks;
    wire  S_c_O_task_valid;
    wire  S_c_O_task_source;
    wire  S_c_O_task_bank;
    wire [2:0] S_c_O_task_slot;
    wire [20:0] S_c_O_task_base;
    wire [8:0] S_c_O_task_y;
    wire [31:0] S_c_O_task_token;
    wire [31:0] S_c_O_task_generation;
    wire [31:0] S_c_O_task_epoch;
    wire [31:0] S_c_O_task_deadline;
    wire [15:0] S_c_O_task_tag;
    wire  S_c_O_line_ready;
    wire [1:0] S_c_O_release_valid;
    wire [1:0] S_c_O_release_bank;
    wire [63:0] S_c_O_release_token;
    wire [63:0] S_c_O_release_generation;
    wire [63:0] S_c_O_release_epoch;
    wire [31:0] S_c_O_release_tag;
    wire [1:0] S_a_O_task_ready;
    wire [3:0] S_a_O_task_reserved;
    wire  S_a_O_reader_task_valid;
    wire [178:0] S_a_O_reader_task_payload;
    wire  S_a_O_reader_line_ready;
    wire [1:0] S_a_O_line_valid;
    wire [206:0] S_a_O_line_payload;
    wire [3:0] S_a_O_release_ready;
    wire [1:0] S_a_O_reader_release_valid;
    wire [225:0] S_a_O_reader_release_payload;
    wire [1:0] S_a_O_source_in_use;
    wire [1:0] S_a_O_source_owner_retired;
    wire  S_a_O_contract_fault;
    wire  S_s_O_config_ready;
    wire  S_s_O_config_applied;
    wire  S_s_O_config_error;
    wire [1:0] S_s_O_source_in_use;
    wire [1:0] S_s_O_source_owner_retired;
    wire [1:0] S_s_O_source_pipeline_retired;
    wire  S_s_O_task_valid;
    wire  S_s_O_task_source;
    wire  S_s_O_task_bank;
    wire [2:0] S_s_O_task_slot;
    wire [20:0] S_s_O_task_base;
    wire [8:0] S_s_O_task_y;
    wire [31:0] S_s_O_task_token;
    wire [31:0] S_s_O_task_generation;
    wire [31:0] S_s_O_task_epoch;
    wire [31:0] S_s_O_task_deadline;
    wire [15:0] S_s_O_task_tag;
    wire  S_s_O_line_ready;
    wire [1:0] S_s_O_read_valid;
    wire [1:0] S_s_O_read_bank;
    wire [19:0] S_s_O_read_x;
    wire [1:0] S_s_O_release_valid;
    wire [1:0] S_s_O_release_bank;
    wire [63:0] S_s_O_release_token;
    wire [63:0] S_s_O_release_generation;
    wire [63:0] S_s_O_release_epoch;
    wire [31:0] S_s_O_release_tag;
    wire [3:0] S_s_O_owned_banks;
    wire  S_s_O_epoch_retired;
    wire  S_s_O_pipeline_idle;
    wire [3:0] S_s_O_last_line_error;
    wire [3:0] S_s_O_last_memory_error;
    wire  S_s_O_contract_fault;
    wire  S_s_O_frame_mark;
    wire  S_s_O_line_start;
    wire  S_r_O_task_ready;
    wire  S_r_O_line_valid;
    wire [3:0] S_r_O_line_error;
    wire [3:0] S_r_O_line_memory_error;
    wire [2:0] S_r_O_line_slot;
    wire [20:0] S_r_O_line_base;
    wire [8:0] S_r_O_line_y;
    wire  S_r_O_line_bank;
    wire [31:0] S_r_O_line_token;
    wire [31:0] S_r_O_line_generation;
    wire [31:0] S_r_O_line_epoch;
    wire [31:0] S_r_O_line_deadline;
    wire [15:0] S_r_O_line_tag;
    wire [9:0] S_r_O_line_accepted;
    wire [9:0] S_r_O_line_retired;
    wire [1:0] S_r_O_read_ready;
    wire [1:0] S_r_O_pixel_valid;
    wire [63:0] S_r_O_rgba;
    wire [1:0] S_r_O_pixel_bank;
    wire [19:0] S_r_O_pixel_x;
    wire [63:0] S_r_O_pixel_token;
    wire [63:0] S_r_O_pixel_generation;
    wire [63:0] S_r_O_pixel_epoch;
    wire [31:0] S_r_O_pixel_tag;
    wire [1:0] S_r_O_release_ready;
    wire [3:0] S_r_O_bank_valid;
    wire [3:0] S_r_O_bank_reserved;
    wire [11:0] S_r_O_bank_slots;
    wire [35:0] S_r_O_bank_rows;
    wire [127:0] S_r_O_bank_tokens;
    wire [127:0] S_r_O_bank_generations;
    wire [127:0] S_r_O_bank_epochs;
    wire [63:0] S_r_O_bank_tags;
    wire [1:0] S_r_O_host_busy;
    wire [1:0] S_r_O_host_tag_exhausted;
    wire [1:0] S_r_O_release_discarded;
    wire [1:0] S_r_O_event_discarded;
    wire [1:0] S_r_O_response_discarded;
    wire  S_r_O_line_source;
    wire S_revoke_now=S_revoked || (S_reserve_mask & (~I_authorized | I_source_block))!=0;
    wire S_cancel_now=S_cancel || I_prepare_abort;
    reg C_input_good,C_targets_free,C_query_good;
    reg [3:0] C_input_banks,C_hold_banks;
    reg [1:0] C_query_mask;
    reg [17:0] C_query_rows;
    integer C_i,C_index;
    wire S_deadline_ready=I_prepare_deadline_valid && I_prepare_deadline_epoch==I_pending_epoch;
    wire S_prepare_fire=I_prepare_valid && O_prepare_ready;
    wire [3:0] S_offer_banks=S_prepare_fire && C_input_good ? C_input_banks : 4'b0000;
    wire [3:0] S_hold_banks=S_pending_valid ? C_hold_banks : 4'b0000;
    assign O_bank_busy=S_r_O_bank_reserved | S_s_O_owned_banks | S_a_O_task_reserved | S_offer_banks | S_hold_banks;
    wire S_candidate_retire_match=!S_pending_valid ||
        (I_retire_config==S_config && I_retire_epoch==S_epoch && I_retire_tag==S_tag);
    wire S_candidate_retire_valid=I_retire_valid && !I_retire_old && S_retire_state==R_IDLE &&
        S_candidate_retire_match && !O_quarantined && (S_state==P_IDLE || S_state==P_HELD);
    wire S_candidate_result_match=S_c_O_retire_epoch==O_retire_epoch && S_c_O_retire_tag==O_retire_tag;
    wire S_finish_candidate=S_retire_state==R_DONE && I_retire_done_ready && !S_retire_old && O_retire_error==0;
    wire S_apply_fire=I_apply_valid && O_can_apply;
    assign O_prepare_ready=!I_async_reset && !S_reset && S_state==P_IDLE && S_retire_state==R_IDLE &&
        !S_c_O_busy && S_p_O_start_ready && !S_previous_valid && !O_quarantined && !I_scan_stop && !I_retire_valid &&
        (!C_input_good || (C_targets_free && (S_in_source_mask & I_source_block)==0 && S_deadline_ready));
    assign O_prepare_done_valid=!S_reset && S_state==P_DONE;
    assign O_prepare_epoch=S_epoch;
    assign O_prepare_tag=S_tag;
    assign O_can_apply=!I_async_reset && !S_reset && S_state==P_HELD && S_pending_good &&
        O_prepare_error==0 && !S_cancel_now && !S_revoke_now && !O_quarantined && !I_scan_stop &&
        S_s_O_config_ready && S_c_O_adopt_ready;
    assign O_local_applied=S_s_O_config_applied;
    assign O_retire_ready=!S_reset && S_retire_state==R_IDLE &&
        (O_quarantined || I_retire_old || !S_candidate_retire_match ||
        ((S_state==P_IDLE || S_state==P_HELD) && S_c_O_retire_ready));
    assign O_retire_done_valid=!S_reset && S_retire_state==R_DONE;
    assign O_busy=S_state!=P_IDLE || S_retire_state!=R_IDLE || O_quarantined;
    wire [1:0] S_preparing_sources=(S_pending_valid ? S_reserve_mask : 2'b00) |
        ((I_prepare_valid && C_input_good && (S_in_source_mask & I_source_block)==0) ? S_in_source_mask : 2'b00);
    assign O_source_in_use=S_reset ? 2'b00 :
        S_s_O_source_in_use | S_c_O_source_in_use | S_a_O_source_in_use | S_preparing_sources;
    assign O_source_owner_retired=S_reset ? 2'b00 :
        S_s_O_source_owner_retired & S_c_O_source_owner_retired & S_a_O_source_owner_retired & ~S_preparing_sources;
    assign O_source_pipeline_retired=S_s_O_source_pipeline_retired;
    always @* begin
        C_input_good=S_in_source_mask!=0 && S_in_source_mask[S_in_from_source] && I_pending_epoch!=0 &&
            (!S_active_valid || I_pending_epoch>S_active_epoch) &&
            S_in_effect<=6 && S_in_progress<=65536 && (S_in_progress==0 || S_in_source_mask[!S_in_from_source]);
        C_targets_free=1; C_input_banks=0; C_hold_banks=0;
        C_query_mask=0; C_query_rows=0; C_query_good=1;
        C_query_mask[S_cfg_from_source]=S_q_O_query_use_a;
        C_query_mask[!S_cfg_from_source]=S_q_O_query_use_b;
        C_query_rows[S_cfg_from_source*9+:9]=S_q_O_query_a_y;
        C_query_rows[(!S_cfg_from_source)*9+:9]=S_q_O_query_b_y;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            C_index=C_i*2+S_in_first_bank[C_i];
            if(S_in_source_mask[C_i]) begin
                C_input_banks[C_index]=1;
                if(S_in_slots[C_i*3+:3]>=6 || S_in_tokens[C_i*32+:32]==0 || S_in_first_y[C_i*9+:9]>=480) C_input_good=0;
                if(S_r_O_bank_reserved[C_index] || S_s_O_owned_banks[C_index] || S_a_O_task_reserved[C_index]) C_targets_free=0;
            end
            C_index=C_i*2+S_cfg_first_bank[C_i];
            if(S_reserve_mask[C_i]) C_hold_banks[C_index]=1;
            if(C_query_mask[C_i] && (!S_cfg_source_mask[C_i] || S_cfg_first_y[C_i*9+:9]!=C_query_rows[C_i*9+:9])) C_query_good=0;
        end
    end
    wire [178:0] S_candidate_task={S_c_O_task_source,S_c_O_task_slot,S_c_O_task_base,S_c_O_task_y,S_c_O_task_bank,
        S_c_O_task_token,S_c_O_task_generation,S_c_O_task_epoch,S_c_O_task_deadline,S_c_O_task_tag};
    wire [178:0] S_scan_task={S_s_O_task_source,S_s_O_task_slot,S_s_O_task_base,S_s_O_task_y,S_s_O_task_bank,
        S_s_O_task_token,S_s_O_task_generation,S_s_O_task_epoch,S_s_O_task_deadline,S_s_O_task_tag};
    wire [225:0] S_candidate_release={S_c_O_release_bank[1],S_c_O_release_token[63:32],S_c_O_release_generation[63:32],
        S_c_O_release_epoch[63:32],S_c_O_release_tag[31:16],S_c_O_release_bank[0],S_c_O_release_token[31:0],
        S_c_O_release_generation[31:0],S_c_O_release_epoch[31:0],S_c_O_release_tag[15:0]};
    wire [225:0] S_scan_release={S_s_O_release_bank[1],S_s_O_release_token[63:32],S_s_O_release_generation[63:32],
        S_s_O_release_epoch[63:32],S_s_O_release_tag[31:16],S_s_O_release_bank[0],S_s_O_release_token[31:0],
        S_s_O_release_generation[31:0],S_s_O_release_epoch[31:0],S_s_O_release_tag[15:0]};
    wire [206:0] S_reader_line={S_r_O_line_error,S_r_O_line_memory_error,S_r_O_line_accepted,S_r_O_line_retired,
        S_r_O_line_source,S_r_O_line_slot,S_r_O_line_base,S_r_O_line_y,S_r_O_line_bank,S_r_O_line_token,
        S_r_O_line_generation,S_r_O_line_epoch,S_r_O_line_deadline,S_r_O_line_tag};
    always @(posedge I_video_clk or posedge S_reset) begin
        if(S_reset) begin
            S_state<=P_IDLE; S_retire_state<=R_IDLE; S_reserve_mask<=0;
            S_pending_valid<=0; S_pending_good<=0; S_cancel<=0; S_revoked<=0; S_active_valid<=0; S_previous_valid<=0; S_retire_old<=0;
            S_config<=0; S_active_config<=0; S_previous_config<=0;
            S_epoch<=0; S_active_epoch<=0; S_previous_epoch<=0; S_tag<=0; S_active_tag<=0; S_previous_tag<=0; S_deadlines<=0;
            O_prepare_error<=0; O_retire_error<=0; O_retire_epoch<=0; O_retire_tag<=0; O_contract_fault<=0; O_quarantined<=0;
        end else begin
            if(S_pending_valid) begin if(I_prepare_abort) S_cancel<=1; if(S_revoke_now) S_revoked<=1; end
            if(S_s_O_contract_fault || S_a_O_contract_fault || S_c_O_quarantined || S_r_O_release_discarded!=0 ||
                (I_apply_valid && !O_can_apply)) begin O_contract_fault<=1; O_quarantined<=1; end
            case(S_state)
                P_IDLE:if(S_prepare_fire) begin
                    S_config<=I_pending_config; S_epoch<=I_pending_epoch; S_tag<=I_pending_tag; S_deadlines<=I_prepare_deadlines;
                    S_pending_valid<=1; S_pending_good<=C_input_good; S_reserve_mask<=C_input_good ? S_in_source_mask : 2'b00;
                    S_cancel<=I_prepare_abort; S_revoked<=C_input_good && (S_in_source_mask & ~I_authorized)!=0;
                    O_prepare_error<=0; S_state<=P_PLAN;
                end
                P_PLAN:if(S_p_O_done_valid) begin
                    if(!S_pending_good || S_p_O_error!=0) begin O_prepare_error<=1; S_state<=P_DONE; end
                    else if(S_revoke_now || S_cancel_now) begin O_prepare_error<=S_revoke_now ? 4'd4 : 4'd3; S_state<=P_DONE; end
                    else S_state<=P_QUERY_CONFIG;
                end
                P_QUERY_CONFIG:if(S_q_O_config_ready) S_state<=P_QUERY_WAIT;
                P_QUERY_WAIT:begin
                    if(S_revoke_now || S_cancel_now) begin O_prepare_error<=S_revoke_now ? 4'd4 : 4'd3; S_state<=P_DONE; end
                    else if(!C_query_good) begin O_prepare_error<=1; S_state<=P_DONE; end
                    else S_state<=P_CANDIDATE;
                end
                P_CANDIDATE:begin
                    if(S_revoke_now || S_cancel_now) begin O_prepare_error<=S_revoke_now ? 4'd4 : 4'd3; S_state<=P_DONE; end
                    else if(S_c_O_prepare_ready && !O_quarantined) S_state<=P_CANDIDATE_WAIT;
                end
                P_CANDIDATE_WAIT:if(S_c_O_prepare_done_valid) begin
                    O_prepare_error<=S_revoke_now ? 4'd4 : S_cancel_now ? 4'd3 : S_c_O_prepare_error;
                    S_state<=P_DONE;
                end
                P_DONE:if(I_prepare_done_ready) S_state<=P_HELD;
                P_HELD:begin end
                default:begin O_contract_fault<=1; O_quarantined<=1; end
            endcase
            if(S_apply_fire) begin
                S_previous_valid<=S_active_valid; S_previous_config<=S_active_config;
                S_previous_epoch<=S_active_epoch; S_previous_tag<=S_active_tag;
                S_active_valid<=1; S_active_config<=S_config; S_active_epoch<=S_epoch; S_active_tag<=S_tag;
                S_pending_valid<=0; S_reserve_mask<=0; S_state<=P_IDLE;
            end
            case(S_retire_state)
                R_IDLE:if(I_retire_valid && O_retire_ready) begin
                    O_retire_epoch<=I_retire_epoch; O_retire_tag<=I_retire_tag; S_retire_old<=I_retire_old; O_retire_error<=0;
                    if(O_quarantined || (!I_retire_old && !S_candidate_retire_match) ||
                        (I_retire_old && (!S_previous_valid || I_retire_config!=S_previous_config ||
                        I_retire_epoch!=S_previous_epoch || I_retire_tag!=S_previous_tag))) begin
                        O_retire_error<=4; O_quarantined<=1; O_contract_fault<=1; S_retire_state<=R_DONE;
                    end else S_retire_state<=I_retire_old ? R_OLD : R_CANDIDATE;
                end
                R_CANDIDATE:if(S_c_O_retire_done_valid && S_candidate_result_match) begin
                    O_retire_error<=S_c_O_retire_error; S_retire_state<=R_DONE;
                    if(S_c_O_retire_error!=0) begin O_quarantined<=1; O_contract_fault<=1; end
                end
                R_OLD:begin
                    if(O_quarantined) begin O_retire_error<=4; S_retire_state<=R_DONE; end
                    else if(S_s_O_epoch_retired) S_retire_state<=R_DONE;
                end
                R_DONE:if(I_retire_done_ready) begin
                    S_retire_state<=R_IDLE;
                    if(O_retire_error==0) begin
                        if(S_retire_old) S_previous_valid<=0;
                        else begin S_pending_valid<=0; S_reserve_mask<=0; S_state<=P_IDLE; end
                    end
                end
            endcase
        end
    end
    transition_plan u_transition_plan (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_start_valid(S_prepare_fire),
        .O_start_ready(S_p_O_start_ready),
        .I_effect(S_in_effect),
        .I_progress(S_in_progress),
        .I_epoch(I_pending_epoch),
        .I_tag(I_pending_tag),
        .O_done_valid(S_p_O_done_valid),
        .I_done_ready(S_apply_fire || S_finish_candidate),
        .O_error(S_p_O_error),
        .O_effect(S_p_O_effect),
        .O_progress(S_p_O_progress),
        .O_epoch(S_p_O_epoch),
        .O_tag(S_p_O_tag),
        .O_dx(S_p_O_dx),
        .O_left(S_p_O_left),
        .O_dy(S_p_O_dy),
        .O_top(S_p_O_top),
        .O_blind_count(S_p_O_blind_count),
        .O_mosaic_count(S_p_O_mosaic_count),
        .O_wipe_threshold(S_p_O_wipe_threshold),
        .O_step_x(S_p_O_step_x),
        .O_step_y(S_p_O_step_y)
    );
    transition_map u_transition_map (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_config_valid(S_state==P_QUERY_CONFIG),
        .O_config_ready(S_q_O_config_ready),
        .O_configured(S_q_O_configured),
        .I_effect(S_p_O_effect),
        .I_progress(S_p_O_progress),
        .I_epoch(S_p_O_epoch),
        .I_tag(S_p_O_tag),
        .I_dx(S_p_O_dx),
        .I_left(S_p_O_left),
        .I_dy(S_p_O_dy),
        .I_top(S_p_O_top),
        .I_blind_count(S_p_O_blind_count),
        .I_mosaic_count(S_p_O_mosaic_count),
        .I_wipe_threshold(S_p_O_wipe_threshold),
        .I_step_x(S_p_O_step_x),
        .I_step_y(S_p_O_step_y),
        .I_valid(1'b0),
        .I_hsync(1'b0),
        .I_vsync(1'b0),
        .I_de(1'b0),
        .I_frame_start(1'b0),
        .I_line_start(1'b0),
        .I_x(16'd0),
        .I_y(16'd0),
        .I_query_y(9'd0),
        .O_query_use_a(S_q_O_query_use_a),
        .O_query_use_b(S_q_O_query_use_b),
        .O_query_a_y(S_q_O_query_a_y),
        .O_query_b_y(S_q_O_query_b_y),
        .O_valid(S_q_O_valid),
        .O_hsync(S_q_O_hsync),
        .O_vsync(S_q_O_vsync),
        .O_de(S_q_O_de),
        .O_frame_start(S_q_O_frame_start),
        .O_line_start(S_q_O_line_start),
        .O_x(S_q_O_x),
        .O_y(S_q_O_y),
        .O_use_a(S_q_O_use_a),
        .O_use_b(S_q_O_use_b),
        .O_a_x(S_q_O_a_x),
        .O_b_x(S_q_O_b_x),
        .O_a_y(S_q_O_a_y),
        .O_b_y(S_q_O_b_y),
        .O_weight(S_q_O_weight),
        .O_epoch(S_q_O_epoch),
        .O_tag(S_q_O_tag)
    );
    display_candidate_ctrl u_display_candidate_ctrl (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_prepare_valid(S_state==P_CANDIDATE && !S_cancel_now && !S_revoke_now && !O_quarantined),
        .O_prepare_ready(S_c_O_prepare_ready),
        .I_source_mask(S_cfg_source_mask),
        .I_first_bank(S_cfg_first_bank),
        .I_source_block(I_source_block),
        .I_authorized(I_authorized),
        .I_slots(S_cfg_slots),
        .I_tokens(S_cfg_tokens),
        .I_generations(S_cfg_generations),
        .I_deadlines(S_deadlines),
        .I_first_y(S_cfg_first_y),
        .I_first_tag(S_cfg_first_tag),
        .I_epoch(S_epoch),
        .I_tag(S_tag),
        .I_prepare_abort(S_cancel_now),
        .O_prepare_done_valid(S_c_O_prepare_done_valid),
        .I_prepare_done_ready(S_state==P_CANDIDATE_WAIT),
        .O_prepare_error(S_c_O_prepare_error),
        .O_line_error(S_c_O_line_error),
        .O_memory_error(S_c_O_memory_error),
        .O_prepare_epoch(S_c_O_prepare_epoch),
        .O_prepare_tag(S_c_O_prepare_tag),
        .I_adopt_valid(S_apply_fire),
        .I_adopt_atomic_ready(S_s_O_config_ready),
        .O_adopt_ready(S_c_O_adopt_ready),
        .I_adopt_epoch(S_epoch),
        .I_adopt_tag(S_tag),
        .O_adopted(S_c_O_adopted),
        .I_retire_valid(S_candidate_retire_valid),
        .O_retire_ready(S_c_O_retire_ready),
        .I_retire_epoch(I_retire_epoch),
        .I_retire_tag(I_retire_tag),
        .O_retire_done_valid(S_c_O_retire_done_valid),
        .I_retire_done_ready(S_retire_state==R_CANDIDATE && S_candidate_result_match),
        .O_retire_error(S_c_O_retire_error),
        .O_retire_epoch(S_c_O_retire_epoch),
        .O_retire_tag(S_c_O_retire_tag),
        .O_busy(S_c_O_busy),
        .O_quarantined(S_c_O_quarantined),
        .O_contract_fault(S_c_O_contract_fault),
        .O_source_in_use(S_c_O_source_in_use),
        .O_source_owner_retired(S_c_O_source_owner_retired),
        .O_owned_banks(S_c_O_owned_banks),
        .O_claim_banks(S_c_O_claim_banks),
        .I_claimed_banks(S_s_O_owned_banks),
        .I_bank_valid(S_r_O_bank_valid),
        .I_bank_reserved(S_r_O_bank_reserved | S_a_O_task_reserved),
        .I_bank_slots(S_r_O_bank_slots),
        .I_bank_rows(S_r_O_bank_rows),
        .I_bank_tokens(S_r_O_bank_tokens),
        .I_bank_generations(S_r_O_bank_generations),
        .I_bank_epochs(S_r_O_bank_epochs),
        .I_bank_tags(S_r_O_bank_tags),
        .O_task_valid(S_c_O_task_valid),
        .I_task_ready(S_a_O_task_ready[1]),
        .O_task_source(S_c_O_task_source),
        .O_task_bank(S_c_O_task_bank),
        .O_task_slot(S_c_O_task_slot),
        .O_task_base(S_c_O_task_base),
        .O_task_y(S_c_O_task_y),
        .O_task_token(S_c_O_task_token),
        .O_task_generation(S_c_O_task_generation),
        .O_task_epoch(S_c_O_task_epoch),
        .O_task_deadline(S_c_O_task_deadline),
        .O_task_tag(S_c_O_task_tag),
        .I_line_valid(S_a_O_line_valid[1]),
        .O_line_ready(S_c_O_line_ready),
        .I_line_source(S_a_O_line_payload[178]),
        .I_line_bank(S_a_O_line_payload[144]),
        .I_line_error(S_a_O_line_payload[206:203]),
        .I_line_memory_error(S_a_O_line_payload[202:199]),
        .I_line_slot(S_a_O_line_payload[177:175]),
        .I_line_base(S_a_O_line_payload[174:154]),
        .I_line_y(S_a_O_line_payload[153:145]),
        .I_line_token(S_a_O_line_payload[143:112]),
        .I_line_generation(S_a_O_line_payload[111:80]),
        .I_line_epoch(S_a_O_line_payload[79:48]),
        .I_line_deadline(S_a_O_line_payload[47:16]),
        .I_line_tag(S_a_O_line_payload[15:0]),
        .O_release_valid(S_c_O_release_valid),
        .I_release_ready(S_a_O_release_ready[3:2]),
        .O_release_bank(S_c_O_release_bank),
        .O_release_token(S_c_O_release_token),
        .O_release_generation(S_c_O_release_generation),
        .O_release_epoch(S_c_O_release_epoch),
        .O_release_tag(S_c_O_release_tag)
    );
    display_reader_arbiter u_display_reader_arbiter (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_task_valid({S_c_O_task_valid,S_s_O_task_valid}),
        .O_task_ready(S_a_O_task_ready),
        .I_task_payload({S_candidate_task,S_scan_task}),
        .I_task_block(8'd0),
        .I_bank_reserved(S_r_O_bank_reserved),
        .O_task_reserved(S_a_O_task_reserved),
        .O_reader_task_valid(S_a_O_reader_task_valid),
        .I_reader_task_ready(S_r_O_task_ready),
        .O_reader_task_payload(S_a_O_reader_task_payload),
        .I_reader_line_valid(S_r_O_line_valid),
        .O_reader_line_ready(S_a_O_reader_line_ready),
        .I_reader_line_payload(S_reader_line),
        .O_line_valid(S_a_O_line_valid),
        .I_line_ready({S_c_O_line_ready,S_s_O_line_ready}),
        .O_line_payload(S_a_O_line_payload),
        .I_release_valid({S_c_O_release_valid,S_s_O_release_valid}),
        .O_release_ready(S_a_O_release_ready),
        .I_release_payload({S_candidate_release,S_scan_release}),
        .O_reader_release_valid(S_a_O_reader_release_valid),
        .I_reader_release_ready(S_r_O_release_ready),
        .O_reader_release_payload(S_a_O_reader_release_payload),
        .O_source_in_use(S_a_O_source_in_use),
        .O_source_owner_retired(S_a_O_source_owner_retired),
        .O_contract_fault(S_a_O_contract_fault)
    );
    // Prepare payloads are not visible until the actual frame apply acceptance.
    always @(posedge I_video_clk or posedge S_reset) begin
        if(S_reset) begin S_color_brightness<=0; S_color_contrast<=0; S_color_saturation<=8; end
        else if(S_apply_fire) begin
            S_color_brightness<=S_cfg_brightness; S_color_contrast<=S_cfg_contrast;
            S_color_saturation<=S_cfg_saturation;
        end
    end
    video_color_adjust u_color (
        .I_de(O_de),.I_rgb(S_render_rgb),.I_brightness(S_color_brightness),
        .I_contrast(S_color_contrast),.I_saturation(S_color_saturation),.O_rgb(O_rgb)
    );
    scanout_engine u_scanout_engine (
        .I_clk(I_video_clk),
        .I_reset(S_reset),
        .I_config_valid(S_apply_fire),
        .O_config_ready(S_s_O_config_ready),
        .O_config_applied(S_s_O_config_applied),
        .O_config_error(S_s_O_config_error),
        .I_source_mask(S_cfg_source_mask),
        .I_source_block(I_source_block),
        .I_seed_valid(1'b1),
        .I_seed_bank(S_cfg_first_bank),
        .I_seed_y(S_cfg_first_y),
        .I_seed_tag(S_cfg_first_tag),
        .O_source_in_use(S_s_O_source_in_use),
        .O_source_owner_retired(S_s_O_source_owner_retired),
        .O_source_pipeline_retired(S_s_O_source_pipeline_retired),
        .I_from_source(S_cfg_from_source),
        .I_slots(S_cfg_slots),
        .I_tokens(S_cfg_tokens),
        .I_generations(S_cfg_generations),
        .I_effect(S_p_O_effect),
        .I_progress(S_p_O_progress),
        .I_epoch(S_p_O_epoch),
        .I_tag(S_p_O_tag),
        .I_dx(S_p_O_dx),
        .I_left(S_p_O_left),
        .I_dy(S_p_O_dy),
        .I_top(S_p_O_top),
        .I_blind_count(S_p_O_blind_count),
        .I_mosaic_count(S_p_O_mosaic_count),
        .I_wipe_threshold(S_p_O_wipe_threshold),
        .I_step_x(S_p_O_step_x),
        .I_step_y(S_p_O_step_y),
        .O_prefetch_y(O_prefetch_y),
        .O_active_epoch(O_active_epoch),
        .I_deadline_valid(I_scan_deadline_valid),
        .I_deadline_y(I_scan_deadline_y),
        .I_deadline_epoch(I_scan_deadline_epoch),
        .I_deadline(I_scan_deadline),
        .O_task_valid(S_s_O_task_valid),
        .I_task_ready(S_a_O_task_ready[0]),
        .O_task_source(S_s_O_task_source),
        .O_task_bank(S_s_O_task_bank),
        .O_task_slot(S_s_O_task_slot),
        .O_task_base(S_s_O_task_base),
        .O_task_y(S_s_O_task_y),
        .O_task_token(S_s_O_task_token),
        .O_task_generation(S_s_O_task_generation),
        .O_task_epoch(S_s_O_task_epoch),
        .O_task_deadline(S_s_O_task_deadline),
        .O_task_tag(S_s_O_task_tag),
        .I_line_valid(S_a_O_line_valid[0]),
        .O_line_ready(S_s_O_line_ready),
        .I_line_source(S_a_O_line_payload[178]),
        .I_line_bank(S_a_O_line_payload[144]),
        .I_line_error(S_a_O_line_payload[206:203]),
        .I_line_memory_error(S_a_O_line_payload[202:199]),
        .I_line_slot(S_a_O_line_payload[177:175]),
        .I_line_base(S_a_O_line_payload[174:154]),
        .I_line_y(S_a_O_line_payload[153:145]),
        .I_line_token(S_a_O_line_payload[143:112]),
        .I_line_generation(S_a_O_line_payload[111:80]),
        .I_line_epoch(S_a_O_line_payload[79:48]),
        .I_line_deadline(S_a_O_line_payload[47:16]),
        .I_line_tag(S_a_O_line_payload[15:0]),
        .I_bank_valid(S_r_O_bank_valid),
        .I_bank_reserved(S_r_O_bank_reserved | S_a_O_task_reserved | S_c_O_claim_banks | S_hold_banks | S_offer_banks),
        .I_bank_slots(S_r_O_bank_slots),
        .I_bank_rows(S_r_O_bank_rows),
        .I_bank_tokens(S_r_O_bank_tokens),
        .I_bank_generations(S_r_O_bank_generations),
        .I_bank_epochs(S_r_O_bank_epochs),
        .I_bank_tags(S_r_O_bank_tags),
        .O_read_valid(S_s_O_read_valid),
        .O_read_bank(S_s_O_read_bank),
        .I_read_ready(S_r_O_read_ready),
        .O_read_x(S_s_O_read_x),
        .I_pixel_valid(S_r_O_pixel_valid),
        .I_pixel_bank(S_r_O_pixel_bank),
        .I_pixel_x(S_r_O_pixel_x),
        .I_rgba(S_r_O_rgba),
        .I_pixel_token(S_r_O_pixel_token),
        .I_pixel_generation(S_r_O_pixel_generation),
        .I_pixel_epoch(S_r_O_pixel_epoch),
        .I_pixel_tag(S_r_O_pixel_tag),
        .O_release_valid(S_s_O_release_valid),
        .O_release_bank(S_s_O_release_bank),
        .I_release_ready(S_a_O_release_ready[1:0]),
        .O_release_token(S_s_O_release_token),
        .O_release_generation(S_s_O_release_generation),
        .O_release_epoch(S_s_O_release_epoch),
        .O_release_tag(S_s_O_release_tag),
        .O_owned_banks(S_s_O_owned_banks),
        .I_retire_epoch(O_retire_epoch),
        .O_epoch_retired(S_s_O_epoch_retired),
        .I_stop_request(I_scan_stop),
        .O_stop_ack(O_scan_stop_ack),
        .O_pipeline_idle(S_s_O_pipeline_idle),
        .O_frame_start(O_frame_start),
        .O_video_und(O_video_und),
        .O_und_count(O_und_count),
        .O_line_error_count(O_line_error_count),
        .O_last_line_error(S_s_O_last_line_error),
        .O_last_memory_error(S_s_O_last_memory_error),
        .O_contract_fault(S_s_O_contract_fault),
        .O_valid(O_valid),
        .O_hsync(O_hsync),
        .O_vsync(O_vsync),
        .O_de(O_de),
        .O_frame_mark(S_s_O_frame_mark),
        .O_line_start(S_s_O_line_start),
        .O_x(O_x),
        .O_y(O_y),
        .O_rgb(S_render_rgb),
        .O_epoch(O_epoch),
        .O_tag(O_tag),
        .O_repeated(O_repeated),
        .O_pixel_fault(O_pixel_fault)
    );
    fb_reader u_fb_reader (
        .I_host_clk(I_host_clk),
        .I_video_clk(I_video_clk),
        .I_async_reset(I_async_reset),
        .I_lease_valid(I_lease_valid),
        .I_lease_slot(I_lease_slots),
        .I_lease_token(I_lease_tokens),
        .I_lease_generation(I_lease_generations),
        .I_task_valid(S_a_O_reader_task_valid),
        .O_task_ready(S_r_O_task_ready),
        .I_task_slot(S_a_O_reader_task_payload[177:175]),
        .I_task_base(S_a_O_reader_task_payload[174:154]),
        .I_task_y(S_a_O_reader_task_payload[153:145]),
        .I_task_bank(S_a_O_reader_task_payload[144]),
        .I_task_token(S_a_O_reader_task_payload[143:112]),
        .I_task_generation(S_a_O_reader_task_payload[111:80]),
        .I_task_epoch(S_a_O_reader_task_payload[79:48]),
        .I_task_deadline(S_a_O_reader_task_payload[47:16]),
        .I_task_tag(S_a_O_reader_task_payload[15:0]),
        .O_line_valid(S_r_O_line_valid),
        .I_line_ready(S_a_O_reader_line_ready),
        .O_line_error(S_r_O_line_error),
        .O_line_memory_error(S_r_O_line_memory_error),
        .O_line_slot(S_r_O_line_slot),
        .O_line_base(S_r_O_line_base),
        .O_line_y(S_r_O_line_y),
        .O_line_bank(S_r_O_line_bank),
        .O_line_token(S_r_O_line_token),
        .O_line_generation(S_r_O_line_generation),
        .O_line_epoch(S_r_O_line_epoch),
        .O_line_deadline(S_r_O_line_deadline),
        .O_line_tag(S_r_O_line_tag),
        .O_line_accepted(S_r_O_line_accepted),
        .O_line_retired(S_r_O_line_retired),
        .I_read_valid(S_s_O_read_valid),
        .O_read_ready(S_r_O_read_ready),
        .I_read_bank(S_s_O_read_bank),
        .I_read_x(S_s_O_read_x),
        .O_pixel_valid(S_r_O_pixel_valid),
        .O_rgba(S_r_O_rgba),
        .O_pixel_bank(S_r_O_pixel_bank),
        .O_pixel_x(S_r_O_pixel_x),
        .O_pixel_token(S_r_O_pixel_token),
        .O_pixel_generation(S_r_O_pixel_generation),
        .O_pixel_epoch(S_r_O_pixel_epoch),
        .O_pixel_tag(S_r_O_pixel_tag),
        .I_release_valid(S_a_O_reader_release_valid),
        .O_release_ready(S_r_O_release_ready),
        .I_release_bank({S_a_O_reader_release_payload[225],S_a_O_reader_release_payload[112]}),
        .I_release_token({S_a_O_reader_release_payload[224:193],S_a_O_reader_release_payload[111:80]}),
        .I_release_generation({S_a_O_reader_release_payload[192:161],S_a_O_reader_release_payload[79:48]}),
        .I_release_epoch({S_a_O_reader_release_payload[160:129],S_a_O_reader_release_payload[47:16]}),
        .I_release_tag({S_a_O_reader_release_payload[128:113],S_a_O_reader_release_payload[15:0]}),
        .O_bank_valid(S_r_O_bank_valid),
        .O_bank_reserved(S_r_O_bank_reserved),
        .O_bank_slots(S_r_O_bank_slots),
        .O_bank_rows(S_r_O_bank_rows),
        .O_bank_tokens(S_r_O_bank_tokens),
        .O_bank_generations(S_r_O_bank_generations),
        .O_bank_epochs(S_r_O_bank_epochs),
        .O_bank_tags(S_r_O_bank_tags),
        .I_retire_request(I_reader_retire_request),
        .O_retire_ack(O_reader_retire_ack),
        .O_host_retired(O_reader_host_retired),
        .O_host_busy(S_r_O_host_busy),
        .O_host_tag_exhausted(S_r_O_host_tag_exhausted),
        .O_release_discarded(S_r_O_release_discarded),
        .O_event_discarded(S_r_O_event_discarded),
        .O_response_discarded(S_r_O_response_discarded),
        .O_mem_valid(O_mem_valid),
        .I_mem_ready(I_mem_ready),
        .O_mem_addr(O_mem_addr),
        .O_mem_tag(O_mem_tag),
        .O_mem_token(O_mem_token),
        .O_mem_generation(O_mem_generation),
        .O_mem_deadline(O_mem_deadline),
        .I_mem_valid(I_mem_valid),
        .O_mem_ready(O_mem_ready),
        .I_mem_data(I_mem_data),
        .I_mem_tag(I_mem_tag),
        .I_mem_token(I_mem_token),
        .I_mem_generation(I_mem_generation),
        .I_mem_error(I_mem_error),
        .I_task_source(S_a_O_reader_task_payload[178]),
        .O_line_source(S_r_O_line_source)
    );
endmodule
