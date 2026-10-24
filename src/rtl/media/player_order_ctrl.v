// Host-domain runtime-order owner. Reorders only retained index mappings, no TF I/O.
// Frozen request survives UI changes; new settings are reconciled after real result.
module player_order_ctrl (
    input wire I_clk,I_reset,I_enable,I_session_ready,I_media_valid,I_index_valid,I_player_busy,
    input wire [31:0] I_media_generation,I_index_generation,I_index_revision,
    input wire I_player_active,
    input wire [31:0] I_player_generation,I_player_revision,
    input wire [1:0] I_active_order,I_base_order,I_runtime_order,
    input wire I_order_override,
    input wire [5:0] I_current_index,
    output wire O_hold_new,O_busy,
    output wire O_reorder_valid,
    input wire I_reorder_ready,
    output reg [1:0] O_reorder_order,
    output reg [31:0] O_reorder_seed,O_reorder_generation,
    output reg [15:0] O_reorder_tag,
    output reg [5:0] O_reorder_current_index,
    output wire O_reorder_abort,
    input wire I_reorder_done_valid,
    output wire O_reorder_done_ready,
    input wire [3:0] I_reorder_error,
    input wire [15:0] I_reorder_tag,
    input wire [31:0] I_reorder_generation,I_reorder_revision,
    input wire [5:0] I_reorder_current_index,
    output wire O_applied,
    output reg [31:0] O_applied_generation,O_applied_revision,
    output reg [5:0] O_applied_index,
    output reg [3:0] O_error,
    output reg O_response_discarded
);
    localparam [2:0] IDLE=0,OFFER=1,WAIT_RESULT=2,APPLY=3,FAILED=4;
    reg [2:0] S_state;
    reg [15:0] S_next_tag;
    reg [31:0] S_random,S_failed_revision;
    reg [1:0] S_failed_order;
    reg S_cancel;
    wire [1:0] S_desired=I_order_override ?
        (I_runtime_order==0 ? 2'd1 : I_runtime_order==1 ? 2'd0 : I_runtime_order) : I_base_order;
    wire S_available=I_enable && I_session_ready && I_media_valid && I_index_valid &&
        I_index_generation==I_media_generation;
    wire S_player_matches=!I_player_active ||
        (I_player_generation==I_index_generation && I_player_revision==I_index_revision);
    wire S_pending=S_available && S_player_matches && S_desired<3 && S_desired!=I_active_order;
    wire S_lost=!S_available || I_media_generation!=O_reorder_generation;
    wire S_match=I_reorder_tag==O_reorder_tag && I_reorder_generation==O_reorder_generation;
    function [31:0] random_next;
        input [31:0] value;
        reg [31:0] next_value;
        begin
            next_value=value^(value<<13); next_value=next_value^(next_value>>17);
            random_next=next_value^(next_value<<5);
        end
    endfunction
    assign O_hold_new=(S_state==IDLE && S_pending) || S_state==OFFER || S_state==WAIT_RESULT || S_state==APPLY;
    assign O_busy=O_hold_new;
    assign O_reorder_valid=!I_reset && S_state==OFFER && !S_lost && !S_cancel;
    assign O_reorder_abort=(S_state==OFFER || S_state==WAIT_RESULT) && (S_lost || S_cancel);
    assign O_reorder_done_ready=!I_reset && S_state==WAIT_RESULT;
    assign O_applied=!I_reset && S_state==APPLY;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_next_tag<=1; S_random<=32'h4f524452; S_cancel<=0;
            S_failed_revision<=0; S_failed_order<=0;
            O_reorder_order<=1; O_reorder_seed<=0; O_reorder_generation<=0; O_reorder_tag<=0;
            O_reorder_current_index<=0; O_applied_generation<=0; O_applied_revision<=0; O_applied_index<=0;
            O_error<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            if((S_state==OFFER || S_state==WAIT_RESULT) && S_lost) S_cancel<=1;
            case(S_state)
                IDLE:if(!S_available || !S_pending) O_error<=0;
                else if(S_pending && !I_player_busy) begin
                    O_reorder_order<=S_desired; O_reorder_generation<=I_media_generation;
                    O_reorder_seed<=S_random; S_random<=random_next(S_random);
                    O_reorder_current_index<=I_current_index; O_reorder_tag<=S_next_tag;
                    S_next_tag<=S_next_tag+1'b1; S_cancel<=0; O_error<=0; S_state<=OFFER;
                end
                OFFER:if(S_lost || S_cancel) S_state<=IDLE;
                    else if(I_reorder_ready) S_state<=WAIT_RESULT;
                WAIT_RESULT:if(I_reorder_done_valid) begin
                    if(!S_match) O_response_discarded<=1;
                    else if(I_reorder_error!=0 || S_lost || S_cancel) begin
                        O_error<=I_reorder_error!=0 ? I_reorder_error : 4'd3;
                        S_failed_order<=S_desired; S_failed_revision<=I_index_revision;
                        S_state<=FAILED;
                    end else begin
                        O_applied_generation<=I_reorder_generation; O_applied_revision<=I_reorder_revision;
                        O_applied_index<=I_reorder_current_index; O_error<=0; S_state<=APPLY;
                    end
                end
                APPLY:S_state<=IDLE;
                FAILED:if(!S_available || S_desired!=S_failed_order || I_index_revision!=S_failed_revision) S_state<=IDLE;
                default:S_state<=FAILED;
            endcase
        end
    end
endmodule
