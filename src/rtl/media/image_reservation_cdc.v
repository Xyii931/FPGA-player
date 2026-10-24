// Reliable image pins are distinct from display READ_LOCK leases.
// Every ALLOC/EVICT must use the arbiter protected by O_host_pinned_slots.
// Shared global reset only; resetting either side alone would discard pin debt.
module image_reservation_cdc (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_video_enable,
    input wire I_update_valid,
    output wire O_update_ready,
    input wire [31:0] I_epoch,
    input wire [15:0] I_tag,
    input wire [137:0] I_reservation,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [31:0] O_epoch,
    output wire [15:0] O_tag,
    output reg [3:0] O_error,
    output wire [137:0] O_images,
    output wire [137:0] O_video_reservation,
    output wire [31:0] O_video_epoch,
    output wire [15:0] O_video_tag,
    output wire O_video_busy,
    output reg O_video_quarantined,O_video_response_discarded,
    input wire I_media_valid,
    input wire [31:0] I_media_generation,
    input wire [17:0] I_slot_states,
    input wire [191:0] I_slot_tokens,I_slot_generations,
    input wire [5:0] I_slot_resident,I_slot_stale,I_mutating_slots,
    output reg [137:0] O_host_reservation,
    output reg [5:0] O_host_pinned_slots,
    output wire O_host_busy,
    output reg O_host_quarantined
);
    localparam [1:0] V_IDLE=0,V_SEND=1,V_WAIT=2,V_RESULT=3;
    localparam [1:0] H_IDLE=0,H_EVAL=1,H_REPLY=2;
    reg [1:0] S_vstate,S_hstate;
    reg [31:0] S_sequence;
    reg [217:0] S_request,S_pending,S_host_active,S_video_active;
    reg [224:0] S_response;
    reg [1:0] S_available,S_last_available;
    reg S_host_valid,S_video_valid;
    reg S_host_fault_meta,S_host_fault_sync,S_video_fault_meta,S_video_fault_sync;
    wire S_hreset,S_vreset,S_req_wready,S_req_valid,S_req_ready,S_rsp_wready,S_rsp_valid;
    wire [217:0] S_req_data;
    wire [224:0] S_rsp_data;
    wire S_rsp_status=S_rsp_data[224];
    wire [217:0] S_rsp_command=S_rsp_data[223:6];
    wire [1:0] S_rsp_available=S_rsp_data[5:4];
    wire [3:0] S_rsp_error=S_rsp_data[3:0];
    wire [137:0] S_wanted=S_pending[137:0];
    wire S_proof_match=S_video_valid && I_epoch==S_video_active[185:154] &&
        I_tag==S_video_active[153:138] && I_reservation==S_video_active[137:0];
    function identity_matches;
        input [137:0] a,b;
        input source;
        begin identity_matches=a[130+source*3+:3]==b[130+source*3+:3] &&
            a[66+source*32+:32]==b[66+source*32+:32] &&
            a[2+source*32+:32]==b[2+source*32+:32] && a[source]==b[source]; end
    endfunction
    function complete_image;
        input [137:0] reservation;
        input source;
        input [17:0] states;
        input [191:0] tokens,generations;
        input [5:0] resident;
        reg [2:0] slot;
        begin
            slot=reservation[130+source*3+:3]; complete_image=0;
            if(slot<6) complete_image=(states[slot*3+:3]==2 || states[slot*3+:3]==3) &&
                tokens[slot*32+:32]==reservation[66+source*32+:32] &&
                generations[slot*32+:32]==reservation[2+source*32+:32] &&
                resident[slot]==reservation[source];
        end
    endfunction
    reg [1:0] C_live_available,C_new_available;
    wire [1:0] S_live_available=C_live_available,S_new_available=C_new_available;
    reg C_range,C_conflict,C_complete,C_mutating;
    integer C_i,C_slot;
    always @* begin
        C_range=S_pending[185:154]!=0; C_conflict=0; C_complete=1; C_mutating=0;
        C_new_available=0; C_live_available=0;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            C_slot=S_wanted[130+C_i*3+:3];
            if(S_wanted[136+C_i]) begin
                if(C_slot>=6 || S_wanted[66+C_i*32+:32]==0 || (S_wanted[C_i] && C_slot!=5)) C_range=0;
                if(O_host_reservation[136+C_i]) begin
                    if(!identity_matches(S_wanted,O_host_reservation,C_i)) C_conflict=1;
                end else if(!complete_image(S_wanted,C_i,I_slot_states,I_slot_tokens,I_slot_generations,I_slot_resident)) C_complete=0;
                if(C_slot<6 && I_mutating_slots[C_slot]) C_mutating=1;
                if(C_slot<6) C_new_available[C_i]=complete_image(S_wanted,C_i,I_slot_states,I_slot_tokens,I_slot_generations,I_slot_resident) &&
                    !I_slot_stale[C_slot] && !I_mutating_slots[C_slot] &&
                    (S_wanted[C_i] || (I_media_valid && I_media_generation==S_wanted[2+C_i*32+:32]));
            end
        end
        O_host_pinned_slots=0;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            C_slot=O_host_reservation[130+C_i*3+:3];
            if(O_host_reservation[136+C_i] && C_slot<6) begin
                O_host_pinned_slots[C_slot]=1;
                C_live_available[C_i]=complete_image(O_host_reservation,C_i,I_slot_states,I_slot_tokens,I_slot_generations,I_slot_resident) &&
                    !I_slot_stale[C_slot] && !I_mutating_slots[C_slot] &&
                    (O_host_reservation[C_i] || (I_media_valid && I_media_generation==O_host_reservation[2+C_i*32+:32]));
            end
        end
    end
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_hreset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_vreset));
    async_fifo #(.DATA_BITS(218),.ADDR_BITS(2)) u_requests (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_vstate==V_SEND),.O_write_ready(S_req_wready),.I_write_data(S_request),
        .O_write_full(),.O_write_level(),.O_read_valid(S_req_valid),.I_read_ready(S_req_ready),
        .O_read_data(S_req_data),.O_read_empty(),.O_read_level()
    );
    async_fifo #(.DATA_BITS(225),.ADDR_BITS(2)) u_responses (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_hstate==H_REPLY),.O_write_ready(S_rsp_wready),.I_write_data(S_response),
        .O_write_full(),.O_write_level(),.O_read_valid(S_rsp_valid),.I_read_ready(!S_vreset),
        .O_read_data(S_rsp_data),.O_read_empty(),.O_read_level()
    );
    assign O_update_ready=!I_async_reset && !S_vreset && S_vstate==V_IDLE && !O_video_quarantined && !S_host_fault_sync;
    assign O_done_valid=!I_async_reset && !S_vreset && S_vstate==V_RESULT;
    assign O_epoch=S_request[185:154];
    assign O_tag=S_request[153:138];
    assign O_video_reservation=S_video_active[137:0];
    assign O_video_epoch=S_video_active[185:154];
    assign O_video_tag=S_video_active[153:138];
    assign O_images={((!I_async_reset && !S_vreset && I_video_enable && S_proof_match &&
        !O_video_quarantined && !S_host_fault_sync) ? S_available : 2'b00),S_video_active[135:0]};
    assign O_video_busy=S_vstate!=V_IDLE || O_video_quarantined || S_host_fault_sync;
    assign S_req_ready=!S_hreset && S_hstate==H_IDLE && !O_host_quarantined && !S_video_fault_sync;
    assign O_host_busy=S_hstate!=H_IDLE || O_host_quarantined || S_video_fault_sync;
    always @(posedge I_host_clk or posedge S_hreset) begin
        if(S_hreset) begin
            S_hstate<=H_IDLE; S_pending<=0; S_host_active<=0; S_host_valid<=0; S_response<=0;
            O_host_reservation<=0; S_last_available<=0; O_host_quarantined<=0;
            S_video_fault_meta<=0; S_video_fault_sync<=0;
        end else begin
            S_video_fault_meta<=O_video_quarantined; S_video_fault_sync<=S_video_fault_meta;
            if(S_video_fault_sync) O_host_quarantined<=1;
            case(S_hstate)
                H_IDLE:if(S_req_valid && S_req_ready) begin S_pending<=S_req_data; S_hstate<=H_EVAL; end
                    else if(S_host_valid && S_live_available!=S_last_available) begin
                        S_response<={1'b1,S_host_active,S_live_available,4'd0};
                        S_last_available<=S_live_available; S_hstate<=H_REPLY;
                    end
                H_EVAL:if(!C_range || C_conflict || (!C_mutating && !C_complete) || O_host_quarantined) begin
                    S_response<={1'b0,S_pending,2'b00,(O_host_quarantined ? 4'd4 : !C_range ? 4'd1 : C_conflict ? 4'd2 : 4'd3)};
                    S_hstate<=H_REPLY;
                end else if(!C_mutating) begin
                    O_host_reservation<=S_wanted; S_host_active<=S_pending; S_host_valid<=1;
                    S_last_available<=S_new_available;
                    S_response<={1'b0,S_pending,S_new_available,4'd0}; S_hstate<=H_REPLY;
                end
                H_REPLY:if(S_rsp_wready) S_hstate<=H_IDLE;
                default:begin O_host_quarantined<=1; end
            endcase
        end
    end
    always @(posedge I_video_clk or posedge S_vreset) begin
        if(S_vreset) begin
            S_vstate<=V_IDLE; S_sequence<=0; S_request<=0; S_video_active<=0; S_video_valid<=0;
            S_available<=0; O_error<=0; O_video_quarantined<=0; O_video_response_discarded<=0;
            S_host_fault_meta<=0; S_host_fault_sync<=0;
        end else begin
            S_host_fault_meta<=O_host_quarantined; S_host_fault_sync<=S_host_fault_meta;
            if(S_host_fault_sync) O_video_quarantined<=1;
            O_video_response_discarded<=0;
            case(S_vstate)
                V_IDLE:if(I_update_valid && O_update_ready) begin
                    S_request<={S_sequence+1'b1,I_epoch,I_tag,I_reservation}; O_error<=0;
                    // Inputs may change after acceptance. Never revive the old proof
                    // while its pin release/replacement can already be in flight.
                    S_video_valid<=0; S_available<=0;
                    if(&S_sequence) begin O_error<=7; O_video_quarantined<=1; S_vstate<=V_RESULT; end
                    else begin S_sequence<=S_sequence+1'b1; S_vstate<=V_SEND; end
                end
                V_SEND:if(S_req_wready) S_vstate<=V_WAIT;
                V_WAIT:begin end
                V_RESULT:if(I_done_ready) S_vstate<=V_IDLE;
                default:begin O_video_quarantined<=1; end
            endcase
            if(S_rsp_valid) begin
                if(S_rsp_status) begin
                    if(S_video_valid && S_rsp_command==S_video_active && S_rsp_error==0) S_available<=S_rsp_available;
                    else O_video_response_discarded<=1;
                end else if(S_vstate==V_WAIT && S_rsp_command==S_request) begin
                    O_error<=S_rsp_error;
                    if(S_rsp_error==0) begin
                        S_video_active<=S_rsp_command; S_video_valid<=1; S_available<=S_rsp_available;
                    end
                    S_vstate<=V_RESULT;
                end else O_video_response_discarded<=1;
            end
        end
    end
endmodule
