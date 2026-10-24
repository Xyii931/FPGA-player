// Audio and video MUST share the same physical clock. No decode-domain inputs here.
// Preparation is an identity/PCM proof, not an audio start or timeline command.
module audio_prepare_guard #(
    parameter integer FIFO_ADDR_BITS=11
) (
    input wire I_clk,I_reset,
    input wire [1:0] I_clear,I_stop,I_failed,I_loaded,I_enabled,I_end,
    input wire [1:0] I_pcm_valid,I_prefilled,
    input wire [2*(FIFO_ADDR_BITS+1)-1:0] I_level,
    input wire [63:0] I_next_index,
    input wire [1:0] I_event_valid,I_event_ready,I_event_header,
    input wire [31:0] I_event_epoch,
    input wire [63:0] I_event_total,I_event_written,
    input wire [7:0] I_event_error,
    input wire I_bind_valid,
    output wire O_bind_ready,
    input wire [31:0] I_bind_display_epoch,
    input wire [15:0] I_bind_display_tag,
    input wire I_bind_slot,
    input wire [15:0] I_bind_track_epoch,
    input wire [31:0] I_bind_track_serial,I_bind_start_index,
    input wire I_bind_reuse_active,
    input wire I_unbind,I_abort,I_pause_busy,I_playback_busy,
    input wire I_pending_valid,
    input wire [31:0] I_pending_epoch,
    input wire [15:0] I_pending_tag,
    input wire I_display_audio_applied,
    output wire O_audio_ready,
    output wire [31:0] O_audio_epoch,
    output wire [1:0] O_track_known,
    output wire [31:0] O_track_epochs,
    output wire [63:0] O_track_serials,O_track_totals,
    output reg O_bound,O_binding_revoked,
    output reg [3:0] O_bind_error,
    output reg O_accepted,
    output reg [31:0] O_accepted_epoch,
    output reg [15:0] O_accepted_tag,
    output reg O_contract_fault,O_quarantined,O_response_discarded
);
    reg [1:0] S_header_seen,S_terminal_seen,S_track_failed;
    reg [31:0] S_track_epochs;
    reg [63:0] S_track_serials,S_track_totals;
    reg [31:0] S_display_epoch,S_track_serial,S_start_index;
    reg [15:0] S_display_tag,S_track_epoch;
    reg S_slot,S_reuse,S_ready_previous;
    reg [3:0] C_bind_error;
    integer S_i;
    wire [31:0] S_next=I_next_index[S_slot*32+:32];
    wire [31:0] S_total=S_track_totals[S_slot*32+:32];
    wire [31:0] S_remaining=S_total-S_next;
    wire [FIFO_ADDR_BITS:0] S_level=I_level[S_slot*(FIFO_ADDR_BITS+1)+:(FIFO_ADDR_BITS+1)];
    wire S_identity_live=O_track_known[S_slot] && S_track_epochs[S_slot*16+:16]==S_track_epoch &&
        S_track_serials[S_slot*32+:32]==S_track_serial && S_next<=S_total &&
        (S_reuse ? I_enabled[S_slot] : (!I_enabled[S_slot] && S_next==S_start_index));
    wire S_pending_match=I_pending_valid && I_pending_epoch==S_display_epoch && I_pending_tag==S_display_tag;
    wire S_data_ready=S_remaining==0 ? I_end[S_slot] :
        (I_pcm_valid[S_slot] && (I_prefilled[S_slot] || S_level>=S_remaining));
    assign O_track_known=S_header_seen & ~S_track_failed & ~I_clear & ~I_stop & ~I_failed & I_loaded &
        {2{!I_reset && !O_quarantined}};
    assign O_track_epochs=S_track_epochs;
    assign O_track_serials=S_track_serials;
    assign O_track_totals=S_track_totals;
    assign O_bind_ready=!I_reset && !O_quarantined && !O_bound && !I_unbind && !I_abort;
    assign O_audio_epoch=S_display_epoch;
    assign O_audio_ready=!I_reset && !O_quarantined && O_bound && !O_binding_revoked &&
        !I_unbind && !I_abort && !I_pause_busy && !I_playback_busy && S_identity_live && S_pending_match &&
        (S_reuse || S_data_ready);
    always @* begin
        C_bind_error=0;
        if(I_bind_display_epoch==0 || I_bind_track_serial==0) C_bind_error=1;
        else if(!I_pending_valid || I_bind_display_epoch!=I_pending_epoch || I_bind_display_tag!=I_pending_tag)
            C_bind_error=2;
        else if(!O_track_known[I_bind_slot] || S_track_epochs[I_bind_slot*16+:16]!=I_bind_track_epoch ||
            S_track_serials[I_bind_slot*32+:32]!=I_bind_track_serial) C_bind_error=3;
        else if(I_next_index[I_bind_slot*32+:32]>S_track_totals[I_bind_slot*32+:32] ||
            (I_bind_reuse_active ? !I_enabled[I_bind_slot] :
            (I_enabled[I_bind_slot] || I_next_index[I_bind_slot*32+:32]!=I_bind_start_index))) C_bind_error=4;
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_header_seen<=0; S_terminal_seen<=0; S_track_failed<=0;
            S_track_epochs<=0; S_track_serials<=0; S_track_totals<=0;
            S_display_epoch<=0; S_display_tag<=0; S_track_epoch<=0; S_track_serial<=0;
            S_start_index<=0; S_slot<=0; S_reuse<=0; S_ready_previous<=0;
            O_bound<=0; O_binding_revoked<=0; O_bind_error<=0;
            O_accepted<=0; O_accepted_epoch<=0; O_accepted_tag<=0;
            O_contract_fault<=0; O_quarantined<=0; O_response_discarded<=0;
        end else begin
            O_bind_error<=0; O_accepted<=0; O_response_discarded<=0;
            // This is the proof at the SAME edge as display's actual apply decision.
            S_ready_previous<=O_audio_ready;
            for(S_i=0;S_i<2;S_i=S_i+1) begin
                if(I_clear[S_i]) begin
                    S_header_seen[S_i]<=0; S_terminal_seen[S_i]<=0; S_track_failed[S_i]<=0;
                    S_track_epochs[S_i*16+:16]<=0; S_track_totals[S_i*32+:32]<=0;
                    // Lifetime serial survives every local flush, including same-epoch reuse.
                end else if(I_event_valid[S_i] && I_event_ready[S_i]) begin
                    if(I_stop[S_i]) O_response_discarded<=1;
                    else if(I_event_header[S_i]) begin
                        if(S_header_seen[S_i] || S_terminal_seen[S_i] || !I_loaded[S_i] ||
                            I_event_error[S_i*4+:4]!=0 || I_event_written[S_i*32+:32]!=0 ||
                            (&S_track_serials[S_i*32+:32])) begin
                            O_contract_fault<=1; O_quarantined<=1;
                        end else begin
                            S_header_seen[S_i]<=1;
                            S_track_epochs[S_i*16+:16]<=I_event_epoch[S_i*16+:16];
                            S_track_totals[S_i*32+:32]<=I_event_total[S_i*32+:32];
                            S_track_serials[S_i*32+:32]<=S_track_serials[S_i*32+:32]+1'b1;
                        end
                    end else begin
                        S_terminal_seen[S_i]<=1;
                        if(I_event_error[S_i*4+:4]!=0) S_track_failed[S_i]<=1;
                        if(S_terminal_seen[S_i] ||
                            (S_header_seen[S_i] && (I_event_epoch[S_i*16+:16]!=S_track_epochs[S_i*16+:16] ||
                            I_event_total[S_i*32+:32]!=S_track_totals[S_i*32+:32] ||
                            I_event_written[S_i*32+:32]>S_track_totals[S_i*32+:32])) ||
                            (!S_header_seen[S_i] && (I_event_error[S_i*4+:4]==0 ||
                            I_event_total[S_i*32+:32]!=0 || I_event_written[S_i*32+:32]!=0)) ||
                            (I_event_error[S_i*4+:4]==0 && I_event_written[S_i*32+:32]!=I_event_total[S_i*32+:32])) begin
                            O_contract_fault<=1; O_quarantined<=1;
                        end
                    end
                end
            end
            if(O_bound && (!S_identity_live || !S_pending_match || I_abort)) O_binding_revoked<=1;
            if(I_display_audio_applied && O_bound) begin
                // The public registered apply pulse arrives one clock AFTER the decision.
                if(!S_ready_previous) begin O_contract_fault<=1; O_quarantined<=1; end
                else begin
                    O_accepted<=1; O_accepted_epoch<=S_display_epoch; O_accepted_tag<=S_display_tag;
                    O_bound<=0; O_binding_revoked<=0;
                end
            end else if(I_unbind) begin O_bound<=0; O_binding_revoked<=0; end
            else if(I_bind_valid && O_bind_ready) begin
                O_bind_error<=C_bind_error;
                if(C_bind_error==0) begin
                    O_bound<=1; O_binding_revoked<=0;
                    S_display_epoch<=I_bind_display_epoch; S_display_tag<=I_bind_display_tag;
                    S_slot<=I_bind_slot; S_track_epoch<=I_bind_track_epoch; S_track_serial<=I_bind_track_serial;
                    S_start_index<=I_bind_start_index; S_reuse<=I_bind_reuse_active;
                end
            end
        end
    end
    // synthesis translate_off
    initial begin
        if(FIFO_ADDR_BITS<2 || FIFO_ADDR_BITS>16) begin
            $display("FAIL: audio_prepare_guard invalid FIFO width"); $stop;
        end
    end
    // synthesis translate_on
endmodule
