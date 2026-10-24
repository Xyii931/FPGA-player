// Video-domain scanout. Reader/lease/resource ownership outside this module.
// Shared global reset only; a presented task/release is never withdrawn.
module scanout_engine #(
    parameter integer HTOTAL=800,HSA=96,HBP=48,HFP=16,
    parameter integer VTOTAL=525,VSA=2,VBP=33,VFP=10,
    parameter HS_POL=1'b0,VS_POL=1'b0
) (
    input wire I_clk,I_reset,I_config_valid,
    output wire O_config_ready,
    output reg O_config_applied,O_config_error,
    input wire [1:0] I_source_mask,
    input wire [1:0] I_source_block,
    input wire I_seed_valid,
    input wire [1:0] I_seed_bank,
    input wire [17:0] I_seed_y,
    input wire [31:0] I_seed_tag,
    output reg [1:0] O_source_in_use,O_source_owner_retired,O_source_pipeline_retired,
    input wire I_from_source,
    input wire [5:0] I_slots,
    input wire [63:0] I_tokens,I_generations,
    input wire [2:0] I_effect,
    input wire [16:0] I_progress,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    input wire [9:0] I_dx,I_left,
    input wire [8:0] I_dy,I_top,
    input wire [5:0] I_blind_count,
    input wire [8:0] I_mosaic_count,
    input wire [19:0] I_wipe_threshold,
    input wire [31:0] I_step_x,I_step_y,
    output wire [8:0] O_prefetch_y,
    output wire [31:0] O_active_epoch,
    input wire I_deadline_valid,
    input wire [8:0] I_deadline_y,
    input wire [31:0] I_deadline_epoch,I_deadline,
    output reg O_task_valid,
    input wire I_task_ready,
    output reg O_task_source,O_task_bank,
    output reg [2:0] O_task_slot,
    output wire [20:0] O_task_base,
    output reg [8:0] O_task_y,
    output reg [31:0] O_task_token,O_task_generation,O_task_epoch,O_task_deadline,
    output reg [15:0] O_task_tag,
    input wire I_line_valid,
    output wire O_line_ready,
    input wire I_line_source,I_line_bank,
    input wire [3:0] I_line_error,I_line_memory_error,
    input wire [2:0] I_line_slot,
    input wire [20:0] I_line_base,
    input wire [8:0] I_line_y,
    input wire [31:0] I_line_token,I_line_generation,I_line_epoch,I_line_deadline,
    input wire [15:0] I_line_tag,
    input wire [3:0] I_bank_valid,I_bank_reserved,
    input wire [11:0] I_bank_slots,
    input wire [35:0] I_bank_rows,
    input wire [127:0] I_bank_tokens,I_bank_generations,I_bank_epochs,
    input wire [63:0] I_bank_tags,
    output wire [1:0] O_read_valid,O_read_bank,
    input wire [1:0] I_read_ready,
    output wire [19:0] O_read_x,
    input wire [1:0] I_pixel_valid,I_pixel_bank,
    input wire [19:0] I_pixel_x,
    input wire [63:0] I_rgba,I_pixel_token,I_pixel_generation,I_pixel_epoch,
    input wire [31:0] I_pixel_tag,
    output reg [1:0] O_release_valid,O_release_bank,
    input wire [1:0] I_release_ready,
    output reg [63:0] O_release_token,O_release_generation,O_release_epoch,
    output reg [31:0] O_release_tag,
    output wire [3:0] O_owned_banks,
    input wire [31:0] I_retire_epoch,
    output reg O_epoch_retired,
    input wire I_stop_request,
    output reg O_stop_ack,
    output wire O_pipeline_idle,
    output wire O_frame_start,
    output reg O_video_und,
    output reg [31:0] O_und_count,O_line_error_count,
    output reg [3:0] O_last_line_error,O_last_memory_error,
    output reg O_contract_fault,
    output wire O_valid,O_hsync,O_vsync,O_de,O_frame_mark,O_line_start,
    output wire [15:0] O_x,O_y,
    output wire [23:0] O_rgb,
    output wire [31:0] O_epoch,
    output wire [15:0] O_tag,
    output reg O_repeated,O_pixel_fault
);
    function [20:0] slot_base;
        input [2:0] slot;
        begin case(slot)
            0:slot_base=21'h000000; 1:slot_base=21'h04b000; 2:slot_base=21'h096000;
            3:slot_base=21'h0e1000; 4:slot_base=21'h12c000; 5:slot_base=21'h177000;
            default:slot_base=21'h1fffff;
        endcase end
    endfunction
    wire S_hsync,S_vsync,S_de,S_line_start;
    wire [15:0] S_x,S_y,S_raster_x,S_raster_y;
    video_timing #(.HTOTAL(HTOTAL),.HSA(HSA),.HBP(HBP),.HACTIVE(640),.HFP(HFP),
        .VTOTAL(VTOTAL),.VSA(VSA),.VBP(VBP),.VACTIVE(480),.VFP(VFP),.HS_POL(HS_POL),.VS_POL(VS_POL)) u_timing (
        .I_clk(I_clk),.I_reset(I_reset),.O_hsync(S_hsync),.O_vsync(S_vsync),.O_de(S_de),
        .O_x(S_x),.O_y(S_y),.O_frame_start(O_frame_start),.O_line_start(S_line_start),
        .O_raster_x(S_raster_x),.O_raster_y(S_raster_y)
    );
    reg S_configured,S_config_taken,S_stopping,S_prefer;
    reg [1:0] S_source_mask;
    reg S_from;
    reg [5:0] S_slots;
    reg [63:0] S_tokens,S_generations;
    reg [31:0] S_epoch;
    reg [8:0] S_want_y,S_held_y;
    reg S_held_valid,S_row_repeated;
    reg [1:0] S_held_use,S_held_bank;
    reg [3:0] S_owned,S_requested;
    reg [2:0] S_meta_slot[0:3];
    reg [8:0] S_meta_y[0:3];
    reg [31:0] S_meta_token[0:3],S_meta_generation[0:3],S_meta_epoch[0:3],S_meta_deadline[0:3];
    reg [15:0] S_meta_tag[0:3];
    reg [15:0] S_next_tag;
    reg [1:0] S_failed;
    reg [8:0] S_failed_y[0:1];
    reg [4:0] S_active_pipe;
    reg [4:0] S_bank_refs[0:3];
    wire S_quiet=!S_de && S_active_pipe==0;
    wire S_active_line=S_raster_y>=VSA+VBP && S_raster_y<VSA+VBP+480;
    wire S_choose_line=S_line_start && S_active_line;
    wire [8:0] S_screen_row=S_raster_y-(VSA+VBP);
    wire [8:0] S_query_y=S_choose_line ? S_screen_row : S_want_y;
    wire S_map_ready,S_map_configured;
    reg C_config_ok,C_seed_ok;
    assign O_config_ready=!I_reset && !S_stopping && !I_stop_request &&
        S_raster_y==0 && (!S_config_taken || O_frame_start) && S_quiet &&
        !O_task_valid && S_requested==0 && O_release_valid==0 && S_map_ready &&
        (!C_config_ok || ((I_source_mask & I_source_block)==0 && C_seed_ok));
    wire S_config_fire=I_config_valid && O_config_ready;
    wire S_install=S_config_fire && C_config_ok;
    assign O_prefetch_y=S_want_y;
    assign O_active_epoch=S_epoch;
    assign O_task_base=slot_base(O_task_slot);
    assign O_owned_banks=S_owned;
    assign O_pipeline_idle=S_quiet;
    wire S_query_a,S_query_b;
    wire [8:0] S_query_ay,S_query_by;
    wire S_map_valid,S_map_hsync,S_map_vsync,S_map_de,S_map_frame,S_map_line,S_map_a,S_map_b;
    wire [15:0] S_map_x,S_map_y;
    wire [9:0] S_map_ax,S_map_bx;
    wire [8:0] S_map_ay,S_map_by;
    wire [16:0] S_map_weight;
    wire [31:0] S_map_epoch;
    wire [15:0] S_map_tag;
    transition_map u_map (
        .I_clk(I_clk),.I_reset(I_reset),.I_config_valid(S_install),.O_config_ready(S_map_ready),
        .O_configured(S_map_configured),.I_effect(I_effect),.I_progress(I_progress),.I_epoch(I_epoch),.I_tag(I_tag),
        .I_dx(I_dx),.I_dy(I_dy),.I_left(I_left),.I_top(I_top),.I_blind_count(I_blind_count),
        .I_mosaic_count(I_mosaic_count),.I_wipe_threshold(I_wipe_threshold),.I_step_x(I_step_x),.I_step_y(I_step_y),
        .I_valid(S_de && S_configured && !S_stopping && !I_stop_request),
        .I_hsync(S_hsync),.I_vsync(S_vsync),.I_de(S_de),.I_frame_start(O_frame_start),.I_line_start(S_line_start),
        .I_x(S_x),.I_y({7'd0,S_held_y}),.I_query_y(S_query_y),
        .O_query_use_a(S_query_a),.O_query_use_b(S_query_b),.O_query_a_y(S_query_ay),.O_query_b_y(S_query_by),
        .O_valid(S_map_valid),.O_hsync(S_map_hsync),.O_vsync(S_map_vsync),.O_de(S_map_de),
        .O_frame_start(S_map_frame),.O_line_start(S_map_line),.O_x(S_map_x),.O_y(S_map_y),
        .O_use_a(S_map_a),.O_use_b(S_map_b),.O_a_x(S_map_ax),.O_a_y(S_map_ay),
        .O_b_x(S_map_bx),.O_b_y(S_map_by),.O_weight(S_map_weight),.O_epoch(S_map_epoch),.O_tag(S_map_tag)
    );
    reg [1:0] C_need,C_found,C_exists,C_bank;
    reg [17:0] C_rows;
    reg [3:0] C_protect,C_owned_match;
    reg C_all_ready,C_new_task,C_task_source,C_task_bank;
    reg C_line_match;
    integer C_i,C_s,C_b,C_index,C_order;
    wire [1:0] S_line_index={I_line_source,I_line_bank};
    wire [1:0] S_cmd_index={O_task_source,O_task_bank};
    always @* begin
        C_config_ok=I_source_mask!=0 && I_source_mask[I_from_source] && I_effect<=6 &&
            I_progress<=65536 && (I_progress==0 || I_source_mask[!I_from_source]) &&
            I_epoch!=0 && I_epoch>=S_epoch;
        if(I_epoch==S_epoch && (I_source_mask!=S_source_mask || I_from_source!=S_from ||
            I_slots!=S_slots || I_tokens!=S_tokens || I_generations!=S_generations)) C_config_ok=0;
        for(C_i=0;C_i<2;C_i=C_i+1)
            if(I_source_mask[C_i] && (I_slots[C_i*3+:3]>=6 || I_tokens[C_i*32+:32]==0)) C_config_ok=0;
        C_seed_ok=1;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            C_index=C_i*2+I_seed_bank[C_i];
            if(I_seed_valid && I_source_mask[C_i] &&
                (!I_bank_valid[C_index] || !I_bank_reserved[C_index] || S_owned[C_index] ||
                I_bank_slots[C_index*3+:3]!=I_slots[C_i*3+:3] ||
                I_bank_rows[C_index*9+:9]!=I_seed_y[C_i*9+:9] ||
                I_bank_tokens[C_index*32+:32]!=I_tokens[C_i*32+:32] ||
                I_bank_generations[C_index*32+:32]!=I_generations[C_i*32+:32] ||
                I_bank_epochs[C_index*32+:32]!=I_epoch || I_bank_tags[C_index*16+:16]!=I_seed_tag[C_i*16+:16])) C_seed_ok=0;
        end
        C_need=0; C_rows=0;
        C_need[S_from]=S_query_a; C_need[!S_from]=S_query_b;
        C_rows[S_from*9+:9]=S_query_ay; C_rows[(!S_from)*9+:9]=S_query_by;
        C_found=0; C_exists=0; C_bank=0; C_protect=0; C_owned_match=0;
        for(C_i=0;C_i<4;C_i=C_i+1) begin
            C_owned_match[C_i]=I_bank_valid[C_i] && I_bank_slots[C_i*3+:3]==S_meta_slot[C_i] &&
                I_bank_rows[C_i*9+:9]==S_meta_y[C_i] && I_bank_tokens[C_i*32+:32]==S_meta_token[C_i] &&
                I_bank_generations[C_i*32+:32]==S_meta_generation[C_i] &&
                I_bank_epochs[C_i*32+:32]==S_meta_epoch[C_i] && I_bank_tags[C_i*16+:16]==S_meta_tag[C_i];
            if(S_requested[C_i] || (O_task_valid && S_cmd_index==C_i)) C_protect[C_i]=1;
        end
        for(C_s=0;C_s<2;C_s=C_s+1) begin
            for(C_b=0;C_b<2;C_b=C_b+1) begin
                C_index=C_s*2+C_b;
                if(S_configured && !S_stopping && !I_stop_request && C_need[C_s] && S_source_mask[C_s]) begin
                    if(I_bank_valid[C_index] && !(O_release_valid[C_s] && O_release_bank[C_s]==C_b) &&
                        I_bank_slots[C_index*3+:3]==S_slots[C_s*3+:3] && I_bank_rows[C_index*9+:9]==C_rows[C_s*9+:9] &&
                        I_bank_tokens[C_index*32+:32]==S_tokens[C_s*32+:32] &&
                        I_bank_generations[C_index*32+:32]==S_generations[C_s*32+:32] &&
                        I_bank_epochs[C_index*32+:32]==S_epoch && !C_found[C_s]) begin
                        C_found[C_s]=1; C_bank[C_s]=C_b; C_exists[C_s]=1; C_protect[C_index]=1;
                    end
                    if((S_requested[C_index] || (O_task_valid && S_cmd_index==C_index)) &&
                        S_meta_slot[C_index]==S_slots[C_s*3+:3] && S_meta_y[C_index]==C_rows[C_s*9+:9] &&
                        S_meta_token[C_index]==S_tokens[C_s*32+:32] && S_meta_generation[C_index]==S_generations[C_s*32+:32] &&
                        S_meta_epoch[C_index]==S_epoch) C_exists[C_s]=1;
                end
            end
            if(S_held_valid && S_held_use[C_s] && !S_stopping && !I_stop_request)
                C_protect[C_s*2+S_held_bank[C_s]]=1;
        end
        C_all_ready=(!S_query_a || (S_source_mask[S_from] && C_found[S_from])) &&
            (!S_query_b || (S_source_mask[!S_from] && C_found[!S_from]));
        C_line_match=S_requested[S_line_index] && I_line_slot==S_meta_slot[S_line_index] &&
            I_line_base==slot_base(S_meta_slot[S_line_index]) && I_line_y==S_meta_y[S_line_index] &&
            I_line_token==S_meta_token[S_line_index] && I_line_generation==S_meta_generation[S_line_index] &&
            I_line_epoch==S_meta_epoch[S_line_index] && I_line_deadline==S_meta_deadline[S_line_index] &&
            I_line_tag==S_meta_tag[S_line_index];
        C_new_task=0; C_task_source=0; C_task_bank=0;
        for(C_order=0;C_order<2;C_order=C_order+1) begin
            C_s=C_order==0 ? S_prefer : !S_prefer;
            for(C_b=0;C_b<2;C_b=C_b+1) begin
                C_index=C_s*2+C_b;
                if(!C_new_task && S_configured && !S_stopping && !I_stop_request && !S_config_fire &&
                    !O_frame_start && !S_choose_line && S_want_y<480 && !O_task_valid &&
                    I_deadline_valid && I_deadline_epoch==S_epoch && I_deadline_y==S_want_y &&
                    C_need[C_s] && S_source_mask[C_s] && !C_exists[C_s] &&
                    !(S_failed[C_s] && S_failed_y[C_s]==C_rows[C_s*9+:9]) &&
                    !I_bank_reserved[C_index] && !S_owned[C_index] &&
                    !(O_release_valid[C_s] && O_release_bank[C_s]==C_b)) begin
                    C_new_task=1; C_task_source=C_s; C_task_bank=C_b;
                end
            end
        end
        O_epoch_retired=!I_reset && !(S_configured && !S_stopping && S_epoch==I_retire_epoch);
        if(!S_quiet && S_epoch==I_retire_epoch) O_epoch_retired=0;
        for(C_i=0;C_i<4;C_i=C_i+1)
            if(S_owned[C_i] && S_meta_epoch[C_i]==I_retire_epoch) O_epoch_retired=0;
    end
    assign O_line_ready=!I_reset && C_line_match;

    // Local evidence only: the enclosing owner must add its candidate/task refs.
    // Keep in_use until releases drain, before the guard may stop the reader.
    integer C_source;
    always @* begin
        O_source_in_use=0; O_source_owner_retired=0; O_source_pipeline_retired=0;
        for(C_source=0;C_source<2;C_source=C_source+1) begin
            O_source_owner_retired[C_source]=!I_reset &&
                S_owned[C_source*2+:2]==0 && S_requested[C_source*2+:2]==0 &&
                !(O_task_valid && O_task_source==C_source) && !O_release_valid[C_source] &&
                !(C_new_task && C_task_source==C_source) && !(C_found[C_source] && !S_config_fire);
            O_source_pipeline_retired[C_source]=!I_reset &&
                S_bank_refs[C_source*2]==0 && S_bank_refs[C_source*2+1]==0 &&
                !(S_de && S_held_valid && S_held_use[C_source]);
            O_source_in_use[C_source]=!I_reset &&
                ((S_configured && S_source_mask[C_source]) ||
                (I_config_valid && C_config_ok && !S_stopping && !I_stop_request &&
                (I_source_mask & I_source_block)==0 && I_source_mask[C_source]) ||
                !O_source_owner_retired[C_source] || !O_source_pipeline_retired[C_source]);
        end
    end

    integer S_i,S_s,S_index;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_configured<=0; S_config_taken<=0; S_stopping<=0; S_prefer<=0;
            S_source_mask<=0; S_from<=0; S_slots<=0; S_tokens<=0; S_generations<=0; S_epoch<=0;
            S_want_y<=480; S_held_y<=0; S_held_valid<=0; S_row_repeated<=0; S_held_use<=0; S_held_bank<=0;
            S_owned<=0; S_requested<=0; S_next_tag<=0; S_failed<=0; S_active_pipe<=0;
            O_config_applied<=0; O_config_error<=0; O_stop_ack<=0; O_video_und<=0; O_und_count<=0;
            O_line_error_count<=0; O_last_line_error<=0; O_last_memory_error<=0; O_contract_fault<=0;
            O_task_valid<=0; O_task_source<=0; O_task_bank<=0; O_task_slot<=0; O_task_y<=0;
            O_task_token<=0; O_task_generation<=0; O_task_epoch<=0; O_task_deadline<=0; O_task_tag<=0;
            O_release_valid<=0; O_release_bank<=0; O_release_token<=0; O_release_generation<=0; O_release_epoch<=0; O_release_tag<=0;
            for(S_i=0;S_i<4;S_i=S_i+1) begin
                S_meta_slot[S_i]<=0; S_meta_y[S_i]<=0; S_meta_token[S_i]<=0;
                S_meta_generation[S_i]<=0; S_meta_epoch[S_i]<=0; S_meta_deadline[S_i]<=0; S_meta_tag[S_i]<=0;
                S_bank_refs[S_i]<=0;
            end
            for(S_i=0;S_i<2;S_i=S_i+1) S_failed_y[S_i]<=0;
        end else begin
            S_active_pipe<={S_active_pipe[3:0],S_de};
            for(S_i=0;S_i<4;S_i=S_i+1)
                S_bank_refs[S_i]<={S_bank_refs[S_i][3:0],S_de && S_held_valid &&
                    S_held_use[S_i>>1] && S_held_bank[S_i>>1]==(S_i&1)};
            O_config_applied<=S_install; O_config_error<=S_config_fire && !C_config_ok; O_video_und<=0;
            if(O_frame_start) begin S_config_taken<=0; S_want_y<=0; S_failed<=0; end
            if(S_config_fire) S_config_taken<=1;
            if(S_install) begin
                S_configured<=1; S_source_mask<=I_source_mask; S_from<=I_from_source;
                S_slots<=I_slots; S_tokens<=I_tokens; S_generations<=I_generations; S_epoch<=I_epoch;
                S_want_y<=0; S_held_valid<=0; S_held_use<=0; S_row_repeated<=0; S_failed<=0;
                for(S_i=0;S_i<2;S_i=S_i+1) begin
                    S_index=S_i*2+I_seed_bank[S_i];
                    if(I_seed_valid && I_source_mask[S_i]) begin
                        S_owned[S_index]<=1; S_meta_slot[S_index]<=I_slots[S_i*3+:3];
                        S_meta_y[S_index]<=I_seed_y[S_i*9+:9]; S_meta_token[S_index]<=I_tokens[S_i*32+:32];
                        S_meta_generation[S_index]<=I_generations[S_i*32+:32]; S_meta_epoch[S_index]<=I_epoch;
                        S_meta_deadline[S_index]<=0; S_meta_tag[S_index]<=I_seed_tag[S_i*16+:16];
                    end
                end
            end
            if(S_choose_line && S_configured && !S_stopping && !I_stop_request) begin
                S_want_y<=S_screen_row==479 ? 9'd480 : S_screen_row+1'b1; S_failed<=0;
                S_row_repeated<=!C_all_ready;
                if(C_all_ready) begin
                    S_held_valid<=1; S_held_y<=S_screen_row; S_held_use<=C_need; S_held_bank<=C_bank;
                end else begin O_video_und<=1; if(!(&O_und_count)) O_und_count<=O_und_count+1'b1; end
            end
            for(S_i=0;S_i<2;S_i=S_i+1) begin
                S_index=S_i*2+C_bank[S_i];
                if(C_found[S_i] && !S_owned[S_index] && !S_config_fire) begin
                    S_owned[S_index]<=1; S_meta_slot[S_index]<=I_bank_slots[S_index*3+:3];
                    S_meta_y[S_index]<=I_bank_rows[S_index*9+:9]; S_meta_token[S_index]<=I_bank_tokens[S_index*32+:32];
                    S_meta_generation[S_index]<=I_bank_generations[S_index*32+:32];
                    S_meta_epoch[S_index]<=I_bank_epochs[S_index*32+:32]; S_meta_tag[S_index]<=I_bank_tags[S_index*16+:16];
                end
                if(O_release_valid[S_i] && I_release_ready[S_i]) begin
                    O_release_valid[S_i]<=0; S_owned[S_i*2+O_release_bank[S_i]]<=0;
                end
                for(S_s=0;S_s<2;S_s=S_s+1) begin
                    S_index=S_i*2+S_s;
                    if(S_bank_refs[S_index]==0 && !S_config_fire && !O_release_valid[S_i] && S_owned[S_index] &&
                        C_owned_match[S_index] && !C_protect[S_index] &&
                        // Select only one bank for each held release output.
                        (S_s==0 || !(S_owned[S_i*2] && C_owned_match[S_i*2] && !C_protect[S_i*2]))) begin
                        O_release_valid[S_i]<=1; O_release_bank[S_i]<=S_s;
                        O_release_token[S_i*32+:32]<=S_meta_token[S_index];
                        O_release_generation[S_i*32+:32]<=S_meta_generation[S_index];
                        O_release_epoch[S_i*32+:32]<=S_meta_epoch[S_index]; O_release_tag[S_i*16+:16]<=S_meta_tag[S_index];
                    end
                    if(S_owned[S_index] && !S_requested[S_index] && !(O_task_valid && S_cmd_index==S_index) &&
                        !C_owned_match[S_index]) O_contract_fault<=1;
                end
            end
            if(C_new_task) begin
                O_task_valid<=1; O_task_source<=C_task_source; O_task_bank<=C_task_bank;
                O_task_slot<=S_slots[C_task_source*3+:3]; O_task_y<=C_rows[C_task_source*9+:9];
                O_task_token<=S_tokens[C_task_source*32+:32]; O_task_generation<=S_generations[C_task_source*32+:32];
                O_task_epoch<=S_epoch; O_task_deadline<=I_deadline; O_task_tag<=S_next_tag; S_next_tag<=S_next_tag+1'b1;
                S_index=C_task_source*2+C_task_bank; S_owned[S_index]<=1;
                S_meta_slot[S_index]<=S_slots[C_task_source*3+:3]; S_meta_y[S_index]<=C_rows[C_task_source*9+:9];
                S_meta_token[S_index]<=S_tokens[C_task_source*32+:32]; S_meta_generation[S_index]<=S_generations[C_task_source*32+:32];
                S_meta_epoch[S_index]<=S_epoch; S_meta_deadline[S_index]<=I_deadline; S_meta_tag[S_index]<=S_next_tag;
            end
            if(O_task_valid && I_task_ready) begin
                O_task_valid<=0; S_requested[S_cmd_index]<=1; S_prefer<=!O_task_source;
            end
            if(I_line_valid && O_line_ready) begin
                S_requested[S_line_index]<=0;
                if(I_line_error!=0) begin
                    S_owned[S_line_index]<=0; S_failed[I_line_source]<=1; S_failed_y[I_line_source]<=I_line_y;
                    O_last_line_error<=I_line_error; O_last_memory_error<=I_line_memory_error;
                    if(!(&O_line_error_count)) O_line_error_count<=O_line_error_count+1'b1;
                end
            end
            if(S_read_valid && !C_pixel_good) O_contract_fault<=1;
            if(I_stop_request) begin S_stopping<=1; S_configured<=0; S_held_valid<=0; S_held_use<=0; end
            if(S_stopping && S_owned==0 && S_requested==0 && !O_task_valid && O_release_valid==0 && S_quiet) O_stop_ack<=1;
            if(O_stop_ack && !I_stop_request) begin S_stopping<=0; O_stop_ack<=0; end
        end
    end

    // Two sidecar stages track real screen coordinates while map may repeat y.
    reg [15:0] S_real_y[0:1];
    reg [1:0] S_bank_pipe[0:1];
    reg [1:0] S_have_pipe,S_repeat_pipe;
    reg [1:0] S_from_pipe;
    reg [1:0] C_read_mask;
    reg [19:0] C_read_x;
    integer C_src;
    always @* begin
        C_read_mask=0; C_read_x=0;
        if(S_map_valid && S_map_de && S_have_pipe[1]) begin
            C_read_mask[S_from_pipe[1]]=S_map_a; C_read_mask[!S_from_pipe[1]]=S_map_b;
            C_read_x[S_from_pipe[1]*10+:10]=S_map_ax; C_read_x[(!S_from_pipe[1])*10+:10]=S_map_bx;
        end
    end
    assign O_read_valid=C_read_mask;
    assign O_read_bank=S_bank_pipe[1];
    assign O_read_x=C_read_x;
    reg S_read_valid,S_read_hsync,S_read_vsync,S_read_de,S_read_frame,S_read_line,S_read_from,S_read_repeated;
    reg [15:0] S_read_x,S_read_y,S_read_tag;
    reg [31:0] S_read_epoch;
    reg [16:0] S_read_weight;
    reg [1:0] S_read_mask,S_read_fired,S_expected_bank;
    reg [19:0] S_expected_x;
    reg [63:0] S_expected_token,S_expected_generation,S_expected_epoch;
    reg [31:0] S_expected_tag;
    reg C_pixel_good;
    always @* begin
        C_pixel_good=1;
        for(C_src=0;C_src<2;C_src=C_src+1)
            if(S_read_mask[C_src] && (!S_read_fired[C_src] || !I_pixel_valid[C_src] ||
                I_pixel_bank[C_src]!=S_expected_bank[C_src] || I_pixel_x[C_src*10+:10]!=S_expected_x[C_src*10+:10] ||
                I_pixel_token[C_src*32+:32]!=S_expected_token[C_src*32+:32] ||
                I_pixel_generation[C_src*32+:32]!=S_expected_generation[C_src*32+:32] ||
                I_pixel_epoch[C_src*32+:32]!=S_expected_epoch[C_src*32+:32] ||
                I_pixel_tag[C_src*16+:16]!=S_expected_tag[C_src*16+:16])) C_pixel_good=0;
    end
    wire [23:0] S_a_rgb=S_read_from ? I_rgba[63:40] : I_rgba[31:8];
    wire [23:0] S_b_rgb=S_read_from ? I_rgba[31:8] : I_rgba[63:40];
    wire S_blend_error;
    blend_unit u_blend (
        .I_clk(I_clk),.I_reset(I_reset),.I_valid(S_read_valid),.I_hsync(S_read_hsync),.I_vsync(S_read_vsync),
        .I_de(S_read_de),.I_frame_start(S_read_frame),.I_line_start(S_read_line),.I_x(S_read_x),.I_y(S_read_y),
        .I_a_rgb(S_a_rgb),.I_b_rgb(S_b_rgb),.I_use_a(S_read_mask[S_read_from] && C_pixel_good),
        .I_use_b(S_read_mask[!S_read_from] && C_pixel_good),.I_weight(S_read_weight),.I_epoch(S_read_epoch),.I_tag(S_read_tag),
        .O_valid(O_valid),.O_hsync(O_hsync),.O_vsync(O_vsync),.O_de(O_de),.O_frame_start(O_frame_mark),.O_line_start(O_line_start),
        .O_x(O_x),.O_y(O_y),.O_rgb(O_rgb),.O_epoch(O_epoch),.O_tag(O_tag),.O_weight_error(S_blend_error)
    );
    reg S_fault_stage,S_repeat_stage;
    integer S_p,S_bindex;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_real_y[0]<=0; S_real_y[1]<=0; S_bank_pipe[0]<=0; S_bank_pipe[1]<=0;
            S_have_pipe<=0; S_repeat_pipe<=0; S_from_pipe<=0;
            S_read_valid<=0; S_read_hsync<=0; S_read_vsync<=0; S_read_de<=0; S_read_frame<=0; S_read_line<=0;
            S_read_from<=0; S_read_repeated<=0; S_read_x<=0; S_read_y<=0; S_read_tag<=0; S_read_epoch<=0; S_read_weight<=0;
            S_read_mask<=0; S_read_fired<=0; S_expected_bank<=0; S_expected_x<=0;
            S_expected_token<=0; S_expected_generation<=0; S_expected_epoch<=0; S_expected_tag<=0;
            S_fault_stage<=0; S_repeat_stage<=0; O_pixel_fault<=0; O_repeated<=0;
        end else begin
            S_real_y[0]<=S_y; S_real_y[1]<=S_real_y[0];
            S_bank_pipe[0]<=S_held_bank; S_bank_pipe[1]<=S_bank_pipe[0];
            S_have_pipe<={S_have_pipe[0],S_held_valid}; S_repeat_pipe<={S_repeat_pipe[0],S_row_repeated};
            S_from_pipe<={S_from_pipe[0],S_from};
            S_read_valid<=S_map_valid; S_read_hsync<=S_map_hsync; S_read_vsync<=S_map_vsync; S_read_de<=S_map_de;
            S_read_frame<=S_map_frame; S_read_line<=S_map_line; S_read_x<=S_map_x; S_read_y<=S_real_y[1];
            S_read_epoch<=S_map_epoch; S_read_tag<=S_map_tag; S_read_weight<=S_map_weight;
            S_read_from<=S_from_pipe[1]; S_read_repeated<=S_repeat_pipe[1];
            S_read_mask<=C_read_mask; S_read_fired<=C_read_mask & I_read_ready;
            S_expected_bank<=O_read_bank; S_expected_x<=O_read_x;
            for(S_p=0;S_p<2;S_p=S_p+1) begin
                S_bindex=S_p*2+O_read_bank[S_p];
                S_expected_token[S_p*32+:32]<=I_bank_tokens[S_bindex*32+:32];
                S_expected_generation[S_p*32+:32]<=I_bank_generations[S_bindex*32+:32];
                S_expected_epoch[S_p*32+:32]<=I_bank_epochs[S_bindex*32+:32]; S_expected_tag[S_p*16+:16]<=I_bank_tags[S_bindex*16+:16];
            end
            S_fault_stage<=S_read_valid && !C_pixel_good; O_pixel_fault<=S_fault_stage;
            S_repeat_stage<=S_read_repeated; O_repeated<=S_repeat_stage;
        end
    end
endmodule
