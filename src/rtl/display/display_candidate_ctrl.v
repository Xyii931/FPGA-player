// Video-domain owner for candidate first-line banks, not the active frame owner.
// Task/result/release arbitration and global reset sequencing are external.
module display_candidate_ctrl (
    input wire I_clk,I_reset,I_prepare_valid,
    output wire O_prepare_ready,
    input wire [1:0] I_source_mask,I_first_bank,I_source_block,I_authorized,
    input wire [5:0] I_slots,
    input wire [63:0] I_tokens,I_generations,I_deadlines,
    input wire [17:0] I_first_y,
    input wire [31:0] I_first_tag,I_epoch,
    input wire [15:0] I_tag,
    input wire I_prepare_abort,
    output wire O_prepare_done_valid,
    input wire I_prepare_done_ready,
    output reg [3:0] O_prepare_error,O_line_error,O_memory_error,
    output wire [31:0] O_prepare_epoch,
    output wire [15:0] O_prepare_tag,
    input wire I_adopt_valid,
    input wire I_adopt_atomic_ready,
    output wire O_adopt_ready,
    input wire [31:0] I_adopt_epoch,
    input wire [15:0] I_adopt_tag,
    output reg O_adopted,
    input wire I_retire_valid,
    output wire O_retire_ready,
    input wire [31:0] I_retire_epoch,
    input wire [15:0] I_retire_tag,
    output wire O_retire_done_valid,
    input wire I_retire_done_ready,
    output reg [3:0] O_retire_error,
    output wire [31:0] O_retire_epoch,
    output wire [15:0] O_retire_tag,
    output wire O_busy,
    output reg O_quarantined,O_contract_fault,
    output reg [1:0] O_source_in_use,O_source_owner_retired,
    output reg [3:0] O_owned_banks,O_claim_banks,
    input wire [3:0] I_claimed_banks,I_bank_valid,I_bank_reserved,
    input wire [11:0] I_bank_slots,
    input wire [35:0] I_bank_rows,
    input wire [127:0] I_bank_tokens,I_bank_generations,I_bank_epochs,
    input wire [63:0] I_bank_tags,
    output reg O_task_valid,
    input wire I_task_ready,
    output reg O_task_source,
    output wire O_task_bank,
    output wire [2:0] O_task_slot,
    output wire [20:0] O_task_base,
    output wire [8:0] O_task_y,
    output wire [31:0] O_task_token,O_task_generation,O_task_epoch,O_task_deadline,
    output wire [15:0] O_task_tag,
    input wire I_line_valid,
    output wire O_line_ready,
    input wire I_line_source,I_line_bank,
    input wire [3:0] I_line_error,I_line_memory_error,
    input wire [2:0] I_line_slot,
    input wire [20:0] I_line_base,
    input wire [8:0] I_line_y,
    input wire [31:0] I_line_token,I_line_generation,I_line_epoch,I_line_deadline,
    input wire [15:0] I_line_tag,
    output reg [1:0] O_release_valid,
    input wire [1:0] I_release_ready,
    output wire [1:0] O_release_bank,
    output wire [63:0] O_release_token,O_release_generation,O_release_epoch,
    output wire [31:0] O_release_tag
);
    localparam [3:0] IDLE=0,SELECT=1,SEND=2,WAIT_LINE=3,PREP_DONE=4,
        HELD=5,RETIRE_CHECK=6,RELEASE=7,RETIRE_DONE=8,QUARANTINE=9;
    reg [3:0] S_state;
    reg [1:0] S_mask,S_banks,S_sent,S_filled;
    reg [5:0] S_slots;
    reg [63:0] S_tokens,S_generations,S_deadlines;
    reg [17:0] S_rows;
    reg [31:0] S_tags,S_epoch;
    reg [15:0] S_tag;
    reg S_cancelled,S_revoked_seen;
    reg C_range_ok,C_targets_free,C_full_match;
    reg [1:0] C_bank_match;
    integer C_i,C_index;
    function [20:0] slot_base;
        input [2:0] slot;
        begin case(slot)
            0:slot_base=21'h000000; 1:slot_base=21'h04b000; 2:slot_base=21'h096000;
            3:slot_base=21'h0e1000; 4:slot_base=21'h12c000; 5:slot_base=21'h177000;
            default:slot_base=21'h1fffff;
        endcase end
    endfunction
    wire S_revoked=(S_mask & (~I_authorized | I_source_block))!=0;
    wire [3:0] S_live_error=S_revoked || S_revoked_seen || O_prepare_error==4 ? 4'd4 :
        I_prepare_abort || S_cancelled || O_prepare_error==3 ? 4'd3 : O_prepare_error;
    assign O_prepare_ready=!I_reset && S_state==IDLE && !O_quarantined && !I_retire_valid &&
        (!C_range_ok || ((I_source_mask & I_source_block)==0 && C_targets_free));
    assign O_prepare_done_valid=!I_reset && S_state==PREP_DONE;
    assign O_prepare_epoch=S_epoch;
    assign O_prepare_tag=S_tag;
    assign O_retire_ready=!I_reset && !O_quarantined &&
        (S_state==IDLE || (S_state==HELD && I_retire_epoch==S_epoch && I_retire_tag==S_tag));
    assign O_retire_done_valid=!I_reset && S_state==RETIRE_DONE;
    assign O_retire_epoch=S_epoch;
    assign O_retire_tag=S_tag;
    assign O_adopt_ready=!I_reset && S_state==HELD && !I_retire_valid &&
        I_adopt_epoch==S_epoch && I_adopt_tag==S_tag && S_live_error==0 &&
        S_filled==S_mask && C_full_match &&
        (I_adopt_atomic_ready || (I_claimed_banks & O_owned_banks)==O_owned_banks);
    assign O_busy=S_state!=IDLE || O_quarantined;
    assign O_task_bank=S_banks[O_task_source];
    assign O_task_slot=S_slots[O_task_source*3+:3];
    assign O_task_base=slot_base(O_task_slot);
    assign O_task_y=S_rows[O_task_source*9+:9];
    assign O_task_token=S_tokens[O_task_source*32+:32];
    assign O_task_generation=S_generations[O_task_source*32+:32];
    assign O_task_epoch=S_epoch;
    assign O_task_deadline=S_deadlines[O_task_source*32+:32];
    assign O_task_tag=S_tags[O_task_source*16+:16];
    assign O_line_ready=!I_reset && S_state==WAIT_LINE &&
        I_line_source==O_task_source && I_line_bank==O_task_bank && I_line_slot==O_task_slot &&
        I_line_base==O_task_base && I_line_y==O_task_y && I_line_token==O_task_token &&
        I_line_generation==O_task_generation && I_line_epoch==O_task_epoch &&
        I_line_deadline==O_task_deadline && I_line_tag==O_task_tag;
    assign O_release_bank=S_banks;
    assign O_release_token=S_tokens;
    assign O_release_generation=S_generations;
    assign O_release_epoch={S_epoch,S_epoch};
    assign O_release_tag=S_tags;
    always @* begin
        C_range_ok=I_source_mask!=0 && I_epoch!=0;
        C_targets_free=1; C_bank_match=0; C_full_match=1;
        O_owned_banks=0; O_claim_banks=0; O_source_in_use=0; O_source_owner_retired=0;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            if(I_source_mask[C_i]) begin
                if(I_slots[C_i*3+:3]>=6 || I_tokens[C_i*32+:32]==0 || I_first_y[C_i*9+:9]>=480) C_range_ok=0;
                C_index=C_i*2+I_first_bank[C_i];
                if(I_bank_reserved[C_index] || I_claimed_banks[C_index]) C_targets_free=0;
            end
            C_index=C_i*2+S_banks[C_i];
            if(S_state!=IDLE && S_mask[C_i]) O_claim_banks[C_index]=1;
            C_bank_match[C_i]=I_bank_valid[C_index] && I_bank_reserved[C_index] &&
                I_bank_slots[C_index*3+:3]==S_slots[C_i*3+:3] && I_bank_rows[C_index*9+:9]==S_rows[C_i*9+:9] &&
                I_bank_tokens[C_index*32+:32]==S_tokens[C_i*32+:32] &&
                I_bank_generations[C_index*32+:32]==S_generations[C_i*32+:32] &&
                I_bank_epochs[C_index*32+:32]==S_epoch && I_bank_tags[C_index*16+:16]==S_tags[C_i*16+:16];
            if(S_filled[C_i]) begin O_owned_banks[C_index]=1; if(!C_bank_match[C_i]) C_full_match=0; end
        end
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            O_source_in_use[C_i]=!I_reset &&
                ((S_state!=IDLE && S_mask[C_i]) ||
                (I_prepare_valid && C_range_ok && (I_source_mask & I_source_block)==0 && I_source_mask[C_i]));
            O_source_owner_retired[C_i]=!I_reset && !O_source_in_use[C_i];
        end
    end
    integer S_i;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_mask<=0; S_banks<=0; S_sent<=0; S_filled<=0; S_slots<=0;
            S_tokens<=0; S_generations<=0; S_deadlines<=0; S_rows<=0; S_tags<=0; S_epoch<=0; S_tag<=0;
            O_prepare_error<=0; O_line_error<=0; O_memory_error<=0; O_retire_error<=0;
            O_quarantined<=0; O_contract_fault<=0; O_adopted<=0; O_task_valid<=0; O_task_source<=0; O_release_valid<=0;
            S_cancelled<=0; S_revoked_seen<=0;
        end else begin
            O_adopted<=0;
            if(S_state!=IDLE) begin
                if(I_prepare_abort) S_cancelled<=1;
                if(S_revoked) S_revoked_seen<=1;
            end
            if((S_state==SELECT || S_state==SEND || S_state==WAIT_LINE) && S_live_error!=0)
                O_prepare_error<=S_live_error;
            case(S_state)
                IDLE:begin
                    if(I_retire_valid && O_retire_ready) begin
                        S_mask<=0; S_filled<=0; S_epoch<=I_retire_epoch; S_tag<=I_retire_tag;
                        O_retire_error<=0; S_state<=RETIRE_DONE;
                    end else if(I_prepare_valid && O_prepare_ready) begin
                        S_mask<=C_range_ok ? I_source_mask : 2'b00; S_banks<=I_first_bank; S_sent<=0; S_filled<=0;
                        S_cancelled<=I_prepare_abort; S_revoked_seen<=(I_source_mask & ~I_authorized)!=0;
                        S_slots<=I_slots; S_tokens<=I_tokens; S_generations<=I_generations; S_deadlines<=I_deadlines;
                        S_rows<=I_first_y; S_tags<=I_first_tag; S_epoch<=I_epoch; S_tag<=I_tag;
                        O_line_error<=0; O_memory_error<=0; O_retire_error<=0;
                        O_prepare_error<=!C_range_ok ? 4'd1 :
                            (I_source_mask & ~I_authorized)!=0 ? 4'd4 : I_prepare_abort ? 4'd3 : 4'd0;
                        S_state<=SELECT;
                    end
                end
                SELECT:begin
                    if(!C_full_match) begin O_prepare_error<=4; O_contract_fault<=1; S_state<=PREP_DONE; end
                    else if(S_live_error!=0 || S_sent==S_mask) S_state<=PREP_DONE;
                    else begin
                        O_task_source<=S_mask[0] && !S_sent[0] ? 1'b0 : 1'b1;
                        O_task_valid<=1; S_state<=SEND;
                    end
                end
                SEND:if(O_task_valid && I_task_ready) begin
                    O_task_valid<=0; S_sent[O_task_source]<=1; S_state<=WAIT_LINE;
                end
                WAIT_LINE:if(I_line_valid && O_line_ready) begin
                    if(I_line_error==0) S_filled[O_task_source]<=1;
                    else begin
                        O_line_error<=I_line_error; O_memory_error<=I_line_memory_error;
                        if(S_live_error==0) O_prepare_error<=2;
                    end
                    S_state<=SELECT;
                end
                PREP_DONE:if(I_prepare_done_ready) S_state<=HELD;
                HELD:begin
                    if(I_retire_valid && O_retire_ready) begin O_retire_error<=0; S_state<=RETIRE_CHECK; end
                    else if(I_adopt_valid && O_adopt_ready) begin
                        S_filled<=0; S_mask<=0; O_adopted<=1; S_state<=IDLE;
                    end
                end
                RETIRE_CHECK:begin
                    if(!C_full_match || (I_claimed_banks & O_owned_banks)!=0) begin
                        O_retire_error<=4; O_quarantined<=1; O_contract_fault<=1; S_state<=RETIRE_DONE;
                    end else if(S_filled==0) begin S_mask<=0; S_state<=RETIRE_DONE; end
                    else begin O_release_valid<=S_filled; S_state<=RELEASE; end
                end
                RELEASE:begin
                    for(S_i=0;S_i<2;S_i=S_i+1)
                        if(O_release_valid[S_i] && I_release_ready[S_i]) begin
                            O_release_valid[S_i]<=0;
                            if(C_bank_match[S_i] && !I_claimed_banks[S_i*2+S_banks[S_i]]) S_filled[S_i]<=0;
                            else begin O_retire_error<=4; O_quarantined<=1; O_contract_fault<=1; end
                        end
                    if(O_release_valid==0) begin
                        if(!O_quarantined) S_mask<=0;
                        S_state<=RETIRE_DONE;
                    end
                end
                RETIRE_DONE:if(I_retire_done_ready) begin
                    if(O_quarantined) S_state<=QUARANTINE;
                    else S_state<=IDLE;
                end
                QUARANTINE:begin end
                default:begin O_quarantined<=1; O_contract_fault<=1; S_state<=QUARANTINE; end
            endcase
        end
    end
endmodule
