// Six fixed framebuffer leases. All ports belong to the management clock domain.
// Retirement inputs MUST come from actual producer/memory/reader owners.
// This module neither accesses SDRAM nor commits the complete video configuration.
module fb_slot_manager #(
    parameter integer TOKEN_BITS=32
) (
    input wire I_clk,I_reset,
    input wire I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_cmd_valid,
    output wire O_cmd_ready,
    input wire [2:0] I_cmd_op,I_cmd_slot,
    input wire [1:0] I_cmd_owner,
    input wire [31:0] I_cmd_token,I_cmd_generation,I_cmd_asset,
    input wire [2:0] I_cmd_layout,
    input wire [1:0] I_cmd_rotation,
    input wire I_cmd_resident,I_cmd_success,
    input wire I_producer_retired,I_memory_retired,I_reader_retired,I_frame_boundary,
    output reg O_result_valid,
    input wire I_result_ready,
    output reg [3:0] O_result_error,
    output reg [2:0] O_result_op,O_result_slot,
    output reg [1:0] O_result_owner,
    output reg [31:0] O_result_token,O_result_generation,
    output reg [20:0] O_result_base,
    output wire [17:0] O_slot_states,
    output wire [191:0] O_slot_tokens,O_slot_generations,O_slot_assets,
    output wire [17:0] O_slot_layouts,O_slot_readers,
    output wire [11:0] O_slot_rotations,
    output wire [5:0] O_slot_resident,O_slot_stale,O_cancel_loading,
    output reg O_token_exhausted
);
    localparam [2:0] FREE=0,LOADING=1,READY=2,READ_LOCK=3,ERROR=4;
    localparam [2:0] ALLOC=0,FINISH=1,ACQUIRE=2,RELEASE=3,EVICT=4;
    reg [2:0] S_state[0:5];
    reg [31:0] S_token[0:5],S_generation[0:5],S_asset[0:5];
    reg [2:0] S_layout[0:5],S_readers[0:5];
    reg [1:0] S_rotation[0:5];
    reg [5:0] S_resident,S_stale;
    reg [TOKEN_BITS-1:0] S_next_token;
    reg [2:0] S_owner_valid;
    reg [2:0] S_owner_slot[0:2];
    integer S_i;
    reg [3:0] S_error;
    reg S_wait;
    reg [20:0] S_base;
    reg [2:0] S_selected_state,S_selected_readers,S_owner_mask;
    reg [31:0] S_selected_token,S_selected_generation;
    reg S_selected_stale;
    wire S_slot_ok=I_cmd_slot<6;
    wire S_owner_ok=I_cmd_owner<3;
    wire [31:0] S_alloc_token=S_next_token;

    genvar g;
    generate for (g=0;g<6;g=g+1) begin: GEN_STATUS
        wire S_live_stale=!S_resident[g] &&
            (!I_media_valid || S_generation[g]!=I_media_generation);
        assign O_slot_states[g*3 +: 3]=S_state[g];
        assign O_slot_tokens[g*32 +: 32]=S_token[g];
        assign O_slot_generations[g*32 +: 32]=S_generation[g];
        assign O_slot_assets[g*32 +: 32]=S_asset[g];
        assign O_slot_layouts[g*3 +: 3]=S_layout[g];
        assign O_slot_readers[g*3 +: 3]=S_readers[g];
        assign O_slot_rotations[g*2 +: 2]=S_rotation[g];
        assign O_slot_resident[g]=S_resident[g];
        assign O_slot_stale[g]=S_stale[g];
        assign O_cancel_loading[g]=S_state[g]==LOADING && (S_stale[g] || S_live_stale);
    end endgenerate

    always @* begin
        S_base=0; S_selected_state=FREE; S_selected_readers=0;
        S_selected_token=0; S_selected_generation=0; S_selected_stale=1;
        S_owner_mask=0;
        if (S_owner_ok) S_owner_mask=3'b001<<I_cmd_owner;
        if (S_slot_ok) begin
            case (I_cmd_slot)
                0:S_base=21'h000000;
                1:S_base=21'h04b000;
                2:S_base=21'h096000;
                3:S_base=21'h0e1000;
                4:S_base=21'h12c000;
                5:S_base=21'h177000;
                default:S_base=0;
            endcase
            S_selected_state=S_state[I_cmd_slot];
            S_selected_readers=S_readers[I_cmd_slot];
            S_selected_token=S_token[I_cmd_slot];
            S_selected_generation=S_generation[I_cmd_slot];
            S_selected_stale=S_stale[I_cmd_slot] || (!S_resident[I_cmd_slot] &&
                (!I_media_valid || S_selected_generation!=I_media_generation));
        end
        S_error=0; S_wait=0;
        if (!S_slot_ok || !S_owner_ok || I_cmd_op>EVICT) S_error=4'd1;
        else case (I_cmd_op)
            ALLOC: begin
                if (I_cmd_layout>4 || (I_cmd_resident && I_cmd_slot!=5)) S_error=4'd1;
                else if ((S_selected_state!=FREE && S_selected_state!=ERROR) || S_selected_readers!=0) S_error=4'd2;
                else if (!I_cmd_resident && (!I_media_valid || I_cmd_generation!=I_media_generation)) S_error=4'd4;
                else if (O_token_exhausted) S_error=4'd7;
            end
            FINISH: begin
                if (S_selected_token!=I_cmd_token || S_selected_generation!=I_cmd_generation) S_error=4'd3;
                else if (S_selected_state!=LOADING) S_error=4'd2;
                else begin
                    S_wait=!(I_producer_retired && I_memory_retired);
                    if (S_selected_stale) S_error=4'd4;
                    else if (!I_cmd_success) S_error=4'd6;
                end
            end
            ACQUIRE: begin
                if (S_selected_token!=I_cmd_token || S_selected_generation!=I_cmd_generation) S_error=4'd3;
                else if ((S_selected_state!=READY && S_selected_state!=READ_LOCK) || S_owner_valid[I_cmd_owner]) S_error=4'd2;
                else if (S_selected_stale) S_error=4'd4;
                else S_wait=I_cmd_owner<2 && !I_frame_boundary;
            end
            RELEASE: begin
                if (S_selected_token!=I_cmd_token || S_selected_generation!=I_cmd_generation) S_error=4'd3;
                else if (S_selected_state!=READ_LOCK || !S_owner_valid[I_cmd_owner] ||
                    S_owner_slot[I_cmd_owner]!=I_cmd_slot || (S_selected_readers&S_owner_mask)==0) S_error=4'd2;
                else S_wait=!I_reader_retired;
            end
            EVICT: begin
                if (S_selected_token!=I_cmd_token || S_selected_generation!=I_cmd_generation) S_error=4'd3;
                else if ((S_selected_state!=READY && S_selected_state!=ERROR) || S_selected_readers!=0) S_error=4'd2;
            end
            default:S_error=4'd1;
        endcase
    end
    assign O_cmd_ready=!I_reset && !O_result_valid && !S_wait;

    always @(posedge I_clk or posedge I_reset) begin
        if (I_reset) begin
            S_resident<=0; S_stale<=0; S_next_token<=1; O_token_exhausted<=0;
            S_owner_valid<=0;
            O_result_valid<=0; O_result_error<=0; O_result_op<=0; O_result_slot<=0; O_result_owner<=0;
            O_result_token<=0; O_result_generation<=0; O_result_base<=0;
            for (S_i=0;S_i<6;S_i=S_i+1) begin
                S_state[S_i]<=FREE; S_token[S_i]<=0; S_generation[S_i]<=0; S_asset[S_i]<=0;
                S_layout[S_i]<=0; S_rotation[S_i]<=0; S_readers[S_i]<=0;
            end
            for (S_i=0;S_i<3;S_i=S_i+1) S_owner_slot[S_i]<=0;
        end else begin
            if (O_result_valid && I_result_ready) O_result_valid<=0;
            for (S_i=0;S_i<6;S_i=S_i+1) begin
                if (S_state[S_i]!=FREE && !S_resident[S_i] &&
                    (!I_media_valid || S_generation[S_i]!=I_media_generation)) begin
                    S_stale[S_i]<=1;
                    if (S_state[S_i]==READY || S_state[S_i]==ERROR) S_state[S_i]<=FREE;
                end
            end
            if (I_cmd_valid && O_cmd_ready) begin
                O_result_valid<=1; O_result_error<=S_error;
                O_result_op<=I_cmd_op; O_result_slot<=I_cmd_slot; O_result_owner<=I_cmd_owner;
                O_result_token<=I_cmd_token; O_result_generation<=I_cmd_generation; O_result_base<=S_base;
                if (S_error==0) begin
                    case (I_cmd_op)
                        ALLOC: begin
                            S_state[I_cmd_slot]<=LOADING; S_token[I_cmd_slot]<=S_alloc_token;
                            S_generation[I_cmd_slot]<=I_cmd_generation; S_asset[I_cmd_slot]<=I_cmd_asset;
                            S_layout[I_cmd_slot]<=I_cmd_layout; S_rotation[I_cmd_slot]<=I_cmd_rotation;
                            S_resident[I_cmd_slot]<=I_cmd_resident; S_stale[I_cmd_slot]<=0;
                            S_readers[I_cmd_slot]<=0; O_result_token<=S_alloc_token;
                            if (&S_next_token) O_token_exhausted<=1;
                            else S_next_token<=S_next_token+1'b1;
                        end
                        FINISH:S_state[I_cmd_slot]<=READY;
                        ACQUIRE: begin
                            S_state[I_cmd_slot]<=READ_LOCK;
                            S_readers[I_cmd_slot]<=S_selected_readers|S_owner_mask;
                            S_owner_valid[I_cmd_owner]<=1; S_owner_slot[I_cmd_owner]<=I_cmd_slot;
                        end
                        RELEASE: begin
                            S_readers[I_cmd_slot]<=S_selected_readers&~S_owner_mask;
                            S_owner_valid[I_cmd_owner]<=0;
                            if ((S_selected_readers&~S_owner_mask)==0)
                                S_state[I_cmd_slot]<=S_selected_stale ? FREE : READY;
                        end
                        EVICT:S_state[I_cmd_slot]<=FREE;
                        default:begin end
                    endcase
                end else if (I_cmd_op==FINISH && S_slot_ok && S_owner_ok &&
                    S_selected_state==LOADING && S_selected_token==I_cmd_token &&
                    S_selected_generation==I_cmd_generation) begin
                    // Even a failed/obsolete producer retains the write lease until
                    // both real retirement confirmations permit this handshake.
                    S_state[I_cmd_slot]<=S_selected_stale ? FREE : ERROR;
                end
            end
        end
    end
endmodule
