// One explicitly leased scan: playlist I/O + index join, then optional directory build.
// All signals are host-domain. No timeout may substitute for real retirement.
module media_scan_ctrl (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,O_lease_request,
    input wire I_lease_grant,I_abort,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    input wire [31:0] I_generation,I_seed,I_sector_budget,I_directory_sector_budget,
    input wire [9:0] I_directory_duration,I_directory_transition_ms,
    input wire [2:0] I_directory_transition,
    input wire [1:0] I_directory_order,
    output wire O_lease_active,O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,O_list_source_error,O_list_build_error,O_directory_build_error,
    output reg [6:0] O_count,
    output reg O_committed,O_used_directory,O_list_missing,O_list_started,O_directory_started,
    output reg [7:0] O_list_warning,O_directory_warning,
    output reg [1:0] O_context,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,O_seed,O_sector_budget,O_directory_sector_budget,
    output reg [9:0] O_directory_duration,O_directory_transition_ms,
    output reg [2:0] O_directory_transition,
    output reg [1:0] O_directory_order,
    output wire O_list_start_valid,
    input wire I_list_start_ready,
    output wire O_child_abort,
    input wire I_list_build_start,
    input wire I_source_done_valid,
    output wire O_source_done_ready,
    input wire [3:0] I_source_error,
    input wire I_source_builder_started,
    input wire [15:0] I_source_tag,
    input wire [31:0] I_source_generation,
    output wire O_directory_mode,O_directory_start_valid,
    input wire I_directory_start_ready,
    output wire [15:0] O_directory_tag,
    input wire I_build_committed,I_build_done_valid,
    output wire O_build_done_ready,
    input wire [3:0] I_build_error,
    input wire [6:0] I_build_count,
    input wire [7:0] I_build_warning,
    input wire [15:0] I_build_tag,
    input wire [31:0] I_build_generation
);
    localparam [2:0] IDLE=0,LIST_START=1,LIST_WAIT=2,DIR_START=3,DIR_WAIT=4,RESULT=5;
    reg [2:0] S_state;
    reg [3:0] S_error;
    reg S_source_seen,S_source_started,S_build_seen,S_phase_started,S_commit_seen;
    wire S_work=S_state!=IDLE && S_state!=RESULT;
    wire S_commit=S_commit_seen || (S_phase_started && I_build_committed);
    wire [3:0] S_current_error=!I_media_valid || I_media_generation!=O_generation ? 4'd3 :
        I_abort ? 4'd2 : 4'd0;
    wire [3:0] S_effective_error=S_commit ? 4'd0 : prefer_error(S_error,S_current_error);
    wire S_source_matches=I_source_tag==O_tag && I_source_generation==O_generation;
    wire S_build_matches=I_build_tag==(O_directory_mode ? O_directory_tag : O_tag) &&
        I_build_generation==O_generation;
    wire S_source_accept=I_source_done_valid && O_source_done_ready && S_source_matches;
    wire S_build_accept=I_build_done_valid && O_build_done_ready && S_build_matches;
    wire S_config_ok=I_context<3 && I_sector_budget!=0 && I_directory_sector_budget!=0 &&
        I_directory_duration>=1 && I_directory_duration<=600 && I_directory_order<3 &&
        (I_directory_transition_ms==200 || I_directory_transition_ms==400 ||
         I_directory_transition_ms==600 || I_directory_transition_ms==1000);
    // The file source may have obeyed the builder's cancel after a parse failure.
    // Preserve that underlying failure unless this scan itself was cancelled.
    wire [3:0] S_source_cause=O_list_source_error==2 && S_build_seen &&
        O_list_build_error!=0 && S_effective_error==0 ? 4'd0 : O_list_source_error;
    wire [3:0] S_list_error=prefer_error(S_effective_error,
        prefer_error(S_source_cause,S_phase_started ? O_list_build_error : 4'd0));

    function [2:0] error_rank;
        input [3:0] value;
        begin case(value) 3:error_rank=5; 2:error_rank=4; 1:error_rank=3;
            4:error_rank=2; 5:error_rank=1; default:error_rank=0; endcase end
    endfunction
    function [3:0] prefer_error;
        input [3:0] old_error,new_error;
        begin prefer_error=error_rank(new_error)>error_rank(old_error) ? new_error : old_error; end
    endfunction

    assign O_start_ready=!I_reset && S_state==IDLE && I_lease_grant;
    assign O_lease_request=!I_reset && S_state==IDLE && I_start_valid;
    assign O_lease_active=!I_reset && S_state!=IDLE;
    assign O_busy=O_lease_active;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_list_start_valid=!I_reset && S_state==LIST_START && S_effective_error==0;
    assign O_child_abort=!I_reset && S_work && S_effective_error!=0;
    assign O_source_done_ready=!I_reset && S_state==LIST_WAIT && !S_source_seen;
    assign O_directory_mode=S_state==DIR_START || S_state==DIR_WAIT;
    assign O_directory_start_valid=!I_reset && S_state==DIR_START && S_effective_error==0;
    assign O_directory_tag=O_tag+16'd1;
    assign O_build_done_ready=!I_reset && !S_build_seen &&
        ((S_state==LIST_WAIT && (S_phase_started || I_list_build_start)) || S_state==DIR_WAIT);

    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_error<=0; S_source_seen<=0; S_source_started<=0;
            S_build_seen<=0; S_phase_started<=0; S_commit_seen<=0;
            O_error<=0; O_list_source_error<=0; O_list_build_error<=0; O_directory_build_error<=0;
            O_count<=0; O_committed<=0; O_used_directory<=0; O_list_missing<=0;
            O_list_started<=0; O_directory_started<=0;
            O_list_warning<=0; O_directory_warning<=0; O_context<=0; O_tag<=0;
            O_generation<=0; O_seed<=0; O_sector_budget<=0; O_directory_sector_budget<=0;
            O_directory_duration<=0; O_directory_transition_ms<=0;
            O_directory_transition<=0; O_directory_order<=0;
        end else begin
            if(S_work) begin
                S_error<=S_effective_error;
                if(S_phase_started && I_build_committed) S_commit_seen<=1;
            end
            if(S_state==LIST_WAIT && I_list_build_start) S_phase_started<=1;
            if(S_source_accept) begin
                S_source_seen<=1; S_source_started<=I_source_builder_started;
                O_list_source_error<=I_source_error;
                O_list_missing<=I_source_error==5 && !I_source_builder_started;
            end
            if(S_build_accept) begin
                S_build_seen<=1; O_count<=I_build_count; O_committed<=I_build_committed;
                if(S_state==DIR_WAIT) begin
                    O_directory_build_error<=I_build_error; O_directory_warning<=I_build_warning;
                end else begin O_list_build_error<=I_build_error; O_list_warning<=I_build_warning; end
            end
            case(S_state)
                IDLE:if(I_start_valid && O_start_ready) begin
                    O_context<=I_context; O_tag<=I_tag; O_generation<=I_generation; O_seed<=I_seed;
                    O_sector_budget<=I_sector_budget; O_directory_sector_budget<=I_directory_sector_budget;
                    O_directory_duration<=I_directory_duration; O_directory_transition_ms<=I_directory_transition_ms;
                    O_directory_transition<=I_directory_transition; O_directory_order<=I_directory_order;
                    S_error<=!I_media_valid || I_media_generation!=I_generation ? 4'd3 :
                        I_abort ? 4'd2 : !S_config_ok ? 4'd4 : 4'd0;
                    S_source_seen<=0; S_source_started<=0; S_build_seen<=0;
                    S_phase_started<=0; S_commit_seen<=0;
                    O_error<=0; O_count<=0; O_committed<=0; O_used_directory<=0; O_list_missing<=0;
                    O_list_started<=0; O_directory_started<=0;
                    O_list_source_error<=0; O_list_build_error<=0; O_directory_build_error<=0;
                    O_list_warning<=0; O_directory_warning<=0; S_state<=LIST_START;
                end
                LIST_START:if(S_effective_error!=0) begin O_error<=S_effective_error; S_state<=RESULT; end
                    else if(I_list_start_ready) begin O_list_started<=1; S_state<=LIST_WAIT; end
                LIST_WAIT:if(S_source_seen && (!S_phase_started || S_build_seen)) begin
                    if(S_source_started!=S_phase_started) begin
                        O_error<=prefer_error(S_effective_error,4'd4); S_state<=RESULT;
                    end else if(S_effective_error==0 &&
                        ((O_list_source_error==5 && !S_phase_started) ||
                         (O_list_source_error==0 && S_phase_started && O_list_build_error==5 &&
                          O_count==0 && !O_committed))) begin
                        O_used_directory<=1; S_phase_started<=0; S_build_seen<=0;
                        S_commit_seen<=0; O_count<=0; O_committed<=0; S_state<=DIR_START;
                    end else begin
                        O_error<=S_list_error!=0 ? S_list_error :
                            (!S_phase_started || !O_committed || O_count==0) ? 4'd4 : 4'd0;
                        S_state<=RESULT;
                    end
                end
                DIR_START:if(S_effective_error!=0) begin O_error<=S_effective_error; S_state<=RESULT; end
                    else if(I_directory_start_ready) begin
                        O_directory_started<=1; S_phase_started<=1; S_state<=DIR_WAIT;
                    end
                DIR_WAIT:if(S_build_seen) begin
                    O_error<=prefer_error(S_effective_error,O_directory_build_error)!=0 ?
                        prefer_error(S_effective_error,O_directory_build_error) :
                        (!O_committed || O_count==0) ? 4'd4 : 4'd0;
                    S_state<=RESULT;
                end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:S_state<=IDLE;
            endcase
        end
    end
endmodule
