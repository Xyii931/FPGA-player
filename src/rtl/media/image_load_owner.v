// Host-domain automatic ordinary-slot selection and reliable image handoff.
// OR O_staged_slots with the REAL host pins at the common slot arbiter.
// I_host_reservation is the host-side installed reservation, never a video hold.
module image_load_owner (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [227:0] I_request,
    input wire I_abort,
    input wire [17:0] I_slot_states,I_slot_layouts,I_slot_readers,
    input wire [191:0] I_slot_tokens,I_slot_generations,I_slot_assets,
    input wire [11:0] I_slot_rotations,
    input wire [5:0] I_slot_resident,I_slot_stale,I_pinned_slots,I_mutating_slots,
    input wire [137:0] I_host_reservation,
    output wire O_evict_valid,
    input wire I_evict_ready,
    output wire [114:0] O_evict_command,
    input wire I_evict_result_valid,
    output wire O_evict_result_ready,
    input wire [96:0] I_evict_result,
    output wire O_loader_start_valid,
    input wire I_loader_start_ready,
    output wire [227:0] O_loader_request,
    output wire [2:0] O_loader_slot,
    output wire O_loader_abort,
    input wire I_loader_done_valid,
    output wire O_loader_done_ready,
    input wire [1:0] I_loader_context,
    input wire [15:0] I_loader_tag,
    input wire [31:0] I_loader_generation,I_loader_token,
    input wire [2:0] I_loader_slot,
    input wire [3:0] I_loader_error,
    input wire I_loader_published,I_loader_slot_owned,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output wire [1:0] O_context,
    output wire [15:0] O_tag,
    output wire [31:0] O_generation,
    output wire [2:0] O_slot,
    output reg [31:0] O_token,
    output reg [3:0] O_error,O_loader_error,O_slot_error,
    output reg O_loader_started,O_reused,O_evicted,O_published,
    output reg O_quarantined,O_response_discarded,
    output wire O_stage_valid,
    output wire [5:0] O_staged_slots,
    input wire I_stage_release_valid,
    output wire O_stage_release_ready,
    input wire [2:0] I_stage_slot,
    input wire [31:0] I_stage_token,I_stage_generation,
    input wire I_stage_discard
);
    localparam [3:0] IDLE=0,SELECT=1,EVICT_OFFER=2,EVICT_WAIT=3,
        CHECK_FREE=4,LOAD_OFFER=5,LOAD_WAIT=6,RESULT=7;
    reg [3:0] S_state;
    reg [227:0] S_request;
    reg [2:0] S_slot;
    reg [31:0] S_evict_token,S_evict_generation,S_load_token;
    reg S_cancel,S_media_lost,S_loader_held,S_stage;
    reg [170:0] S_cache_key[0:4];
    reg [31:0] S_cache_token[0:4];
    reg [4:0] S_cache_valid;
    integer S_i;
    reg C_found,C_reuse,C_evict,C_pin_installed;
    reg [2:0] C_slot;
    integer C_i,C_source;
    wire S_media_bad=!I_media_valid || I_media_generation!=S_request[204:173];
    wire S_stop=S_cancel || I_abort || S_media_lost || S_media_bad;
    wire S_request_valid=(!I_request[227] || (I_request[226:223]!=0 && I_request[226:223]<=9)) && I_request[222:221]<3 && I_request[140:138]<=4 &&
        I_request[38:32]!=0 && I_request[38:32]<=64 && I_request[31:0]!=0 &&
        I_request[103:88]!=0 && I_request[87:72]!=0 &&
        ({1'b0,I_request[135:120]}+{1'b0,I_request[103:88]}<=17'd640) &&
        ({1'b0,I_request[119:104]}+{1'b0,I_request[87:72]}<=17'd480);
    wire S_loader_match=I_loader_context==S_request[222:221] &&
        I_loader_tag==S_request[220:205] && I_loader_generation==S_request[204:173] &&
        I_loader_slot==S_slot;
    wire S_token_match=S_load_token==0 || I_loader_token==S_load_token;
    wire S_complete=(I_slot_states[S_slot*3+:3]==2 || I_slot_states[S_slot*3+:3]==3) &&
        I_slot_tokens[S_slot*32+:32]==I_loader_token && I_loader_token!=0 &&
        I_slot_generations[S_slot*32+:32]==S_request[204:173] &&
        I_slot_assets[S_slot*32+:32]==S_request[172:141] &&
        I_slot_layouts[S_slot*3+:3]==S_request[140:138] &&
        I_slot_rotations[S_slot*2+:2]==S_request[137:136] &&
        !I_slot_resident[S_slot] && !I_slot_stale[S_slot];
    wire S_evict_match=I_evict_result[92:90]==4 && I_evict_result[89:87]==S_slot &&
        I_evict_result[86:85]==2 && I_evict_result[84:53]==S_evict_token &&
        I_evict_result[52:21]==S_evict_generation;
    wire S_contract_bad=I_loader_slot_owned || !S_token_match ||
        (I_loader_published && I_loader_token==0) ||
        (I_loader_error==0 && (!I_loader_published || I_loader_token==0 ||
         (!(S_media_lost || S_media_bad) && !S_complete)));
    // Published is a real loader terminal, not last/write acceptance. This lookahead
    // closes the cycle before the stored stage takes over. No mutation feedback here.
    // Contradictory ownership also keeps the selected slot protected until global
    // reset. Stage is a hold; only error=0 makes it a usable image candidate.
    wire S_stage_ahead=S_state==LOAD_WAIT && I_loader_done_valid && S_loader_match &&
        ((I_loader_published && !I_loader_slot_owned && I_loader_token!=0 && S_token_match) || S_contract_bad);
    always @* begin
        C_found=0; C_reuse=0; C_evict=0; C_slot=0;
        // A known complete image may be reused while a real reader/pin holds it.
        for(C_i=0;C_i<5;C_i=C_i+1) begin
            if(!C_found && S_cache_valid[C_i] && S_cache_key[C_i]=={S_request[227:223],S_request[204:39]} &&
                (I_slot_states[C_i*3+:3]==2 || I_slot_states[C_i*3+:3]==3) &&
                I_slot_tokens[C_i*32+:32]==S_cache_token[C_i] && S_cache_token[C_i]!=0 &&
                I_slot_generations[C_i*32+:32]==S_request[204:173] &&
                I_slot_assets[C_i*32+:32]==S_request[172:141] &&
                I_slot_layouts[C_i*3+:3]==S_request[140:138] &&
                I_slot_rotations[C_i*2+:2]==S_request[137:136] &&
                !I_slot_resident[C_i] && !I_slot_stale[C_i] && !I_mutating_slots[C_i]) begin
                C_found=1; C_reuse=1; C_slot=C_i;
            end
        end
        for(C_i=0;C_i<5;C_i=C_i+1) begin
            if(!C_found && (I_slot_states[C_i*3+:3]==0 || I_slot_states[C_i*3+:3]==4) &&
                I_slot_readers[C_i*3+:3]==0 && !I_slot_resident[C_i] &&
                !I_pinned_slots[C_i] && !I_mutating_slots[C_i]) begin
                C_found=1; C_slot=C_i;
            end
        end
        for(C_i=0;C_i<5;C_i=C_i+1) begin
            if(!C_found && I_slot_states[C_i*3+:3]==2 && I_slot_readers[C_i*3+:3]==0 &&
                !I_slot_resident[C_i] && !I_pinned_slots[C_i] && !I_mutating_slots[C_i]) begin
                C_found=1; C_evict=1; C_slot=C_i;
            end
        end
        C_pin_installed=0;
        for(C_source=0;C_source<2;C_source=C_source+1) begin
            if(I_host_reservation[136+C_source] && !I_host_reservation[C_source] &&
                I_host_reservation[130+C_source*3+:3]==S_slot &&
                I_host_reservation[66+C_source*32+:32]==O_token &&
                I_host_reservation[2+C_source*32+:32]==S_request[204:173]) C_pin_installed=1;
        end
    end
    assign O_start_ready=!I_reset && S_state==IDLE && !S_stage && !O_quarantined;
    assign O_busy=S_state!=IDLE || S_stage || O_quarantined;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_context=S_request[222:221];
    assign O_tag=S_request[220:205];
    assign O_generation=S_request[204:173];
    assign O_slot=S_slot;
    assign O_loader_request=S_request;
    assign O_loader_slot=S_slot;
    assign O_evict_valid=!I_reset && S_state==EVICT_OFFER;
    assign O_evict_command={3'd4,S_slot,2'd2,S_evict_token,S_evict_generation,
        32'd0,3'd0,2'd0,1'b0,1'b0,4'b1111};
    assign O_evict_result_ready=!I_reset && S_state==EVICT_WAIT;
    assign O_loader_start_valid=!I_reset && S_state==LOAD_OFFER;
    assign O_loader_abort=(S_state==LOAD_OFFER || S_state==LOAD_WAIT) && S_stop;
    // A matching terminal stays at the actual loader until external consumption.
    assign O_loader_done_ready=!I_reset &&
        ((S_state==LOAD_WAIT && I_loader_done_valid && !S_loader_match) ||
         (S_state==RESULT && S_loader_held && I_done_ready));
    assign O_stage_valid=S_stage || S_stage_ahead;
    assign O_staged_slots=O_stage_valid ? (6'b000001<<S_slot) : 6'b0;
    assign O_stage_release_ready=!I_reset && S_state==IDLE && S_stage && !O_quarantined &&
        I_stage_slot==S_slot && I_stage_token==O_token && I_stage_generation==S_request[204:173] &&
        (I_stage_discard || C_pin_installed);
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_request<=0; S_slot<=0; S_evict_token<=0; S_evict_generation<=0;
            S_load_token<=0; S_cancel<=0; S_media_lost<=0; S_loader_held<=0; S_stage<=0;
            S_cache_valid<=0;
            for(S_i=0;S_i<5;S_i=S_i+1) begin S_cache_key[S_i]<=0; S_cache_token[S_i]<=0; end
            O_token<=0; O_error<=0; O_loader_error<=0; O_slot_error<=0;
            O_loader_started<=0; O_reused<=0; O_evicted<=0; O_published<=0;
            O_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            // Cache validity is tied to the actual immutable allocation token.
            for(S_i=0;S_i<5;S_i=S_i+1) begin
                if(!I_media_valid || I_slot_stale[S_i] || I_slot_resident[S_i] ||
                    I_slot_tokens[S_i*32+:32]!=S_cache_token[S_i] ||
                    I_slot_generations[S_i*32+:32]!=I_media_generation ||
                    (I_slot_states[S_i*3+:3]!=2 && I_slot_states[S_i*3+:3]!=3)) S_cache_valid[S_i]<=0;
            end
            if(S_state!=IDLE && S_state!=RESULT) begin
                if(I_abort) S_cancel<=1;
                if(S_media_bad) S_media_lost<=1;
            end
            if(I_stage_release_valid && O_stage_release_ready) S_stage<=0;
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    S_request<=I_request; S_slot<=0; S_load_token<=0;
                    S_cancel<=0; S_media_lost<=0; S_loader_held<=0;
                    O_token<=0; O_error<=0; O_loader_error<=0; O_slot_error<=0;
                    O_loader_started<=0; O_reused<=0; O_evicted<=0; O_published<=0;
                    if(!I_media_valid || I_request[204:173]!=I_media_generation) begin O_error<=5; S_state<=RESULT; end
                    else if(I_abort) begin O_error<=3; S_state<=RESULT; end
                    else if(!S_request_valid) begin O_error<=1; S_state<=RESULT; end
                    else S_state<=SELECT;
                end
                SELECT:begin
                    if(S_stop) begin O_error<=(S_media_lost || S_media_bad) ? 5 : 3; S_state<=RESULT; end
                    else if(C_found) begin
                        S_slot<=C_slot;
                        if(C_reuse) begin
                            O_token<=S_cache_token[C_slot]; O_reused<=1; O_published<=1;
                            S_stage<=1; S_state<=RESULT;
                        end else begin
                            S_cache_valid[C_slot]<=0;
                            if(C_evict) begin
                                S_evict_token<=I_slot_tokens[C_slot*32+:32];
                                S_evict_generation<=I_slot_generations[C_slot*32+:32]; S_state<=EVICT_OFFER;
                            end else S_state<=LOAD_OFFER;
                        end
                    end
                end
                EVICT_OFFER:if(I_evict_ready) S_state<=EVICT_WAIT;
                EVICT_WAIT:if(I_evict_result_valid) begin
                    if(!S_evict_match) O_response_discarded<=1;
                    else begin
                        O_slot_error<=I_evict_result[96:93];
                        if(I_evict_result[96:93]!=0) begin O_error<=2; S_state<=RESULT; end
                        else begin O_evicted<=1; S_state<=CHECK_FREE; end
                    end
                end
                CHECK_FREE:begin
                    if(S_stop) begin O_error<=(S_media_lost || S_media_bad) ? 5 : 3; S_state<=RESULT; end
                    else if((I_slot_states[S_slot*3+:3]==0 || I_slot_states[S_slot*3+:3]==4) &&
                        I_slot_readers[S_slot*3+:3]==0 && !I_slot_resident[S_slot] &&
                        !I_pinned_slots[S_slot] && !I_mutating_slots[S_slot]) S_state<=LOAD_OFFER;
                    else S_state<=SELECT;
                end
                LOAD_OFFER:if(I_loader_start_ready) begin O_loader_started<=1; S_state<=LOAD_WAIT; end
                LOAD_WAIT:begin
                    if(I_loader_slot_owned && I_loader_token!=0 && S_loader_match && S_load_token==0)
                        S_load_token<=I_loader_token;
                    if(I_loader_done_valid) begin
                        if(!S_loader_match) O_response_discarded<=1;
                        else begin
                            S_loader_held<=1; O_loader_error<=I_loader_error;
                            O_token<=I_loader_token; O_published<=I_loader_published;
                            if(S_stage_ahead) S_stage<=1;
                            if(S_contract_bad) begin
                                O_error<=8; O_quarantined<=1;
                            end else if(S_media_lost || S_media_bad) O_error<=5;
                            else if(S_cancel || I_abort) O_error<=3;
                            else if(I_loader_error!=0) O_error<=4;
                            else begin
                                O_error<=0; S_cache_key[S_slot]<={S_request[227:223],S_request[204:39]};
                                S_cache_token[S_slot]<=I_loader_token; S_cache_valid[S_slot]<=1;
                            end
                            S_state<=RESULT;
                        end
                    end
                end
                RESULT:if(I_done_ready) begin S_loader_held<=0; S_state<=IDLE; end
                default:O_quarantined<=1;
            endcase
        end
    end
endmodule
