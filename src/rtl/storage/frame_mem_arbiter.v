// Six host-domain scalar clients. Client 0/1 scan EDF, 2..4 background, 5 lowest.
// Result capacity is reserved at command acceptance, independently for each client.
module frame_mem_arbiter #(
    parameter integer CLIENT_BITS=3,
    parameter integer PENDING_BITS=4,
    parameter integer MAX_BURST=32,
    parameter integer AGE_LIMIT=256,
    parameter integer SERVICE_BOUND=64,
    parameter integer WINDOW_BITS=20
) (
    input wire I_clk,I_reset,
    input wire [31:0] I_time,
    input wire [5:0] I_client_valid,
    output reg [5:0] O_client_ready,
    input wire [5:0] I_client_wr,
    input wire [125:0] I_client_addr,
    input wire [191:0] I_client_data,I_client_tag,I_client_token,I_client_generation,I_client_deadline,
    input wire [23:0] I_client_mask,
    output wire [5:0] O_client_result_valid,
    input wire [5:0] I_client_result_ready,
    output wire [5:0] O_client_result_wr,
    output wire [191:0] O_client_result_data,O_client_result_tag,O_client_result_token,O_client_result_generation,
    output wire [23:0] O_client_result_error,
    output wire O_mem_valid,
    input wire I_mem_ready,
    output wire O_mem_wr,
    output wire [20:0] O_mem_addr,
    output wire [31:0] O_mem_data,O_mem_tag,
    output wire [3:0] O_mem_mask,
    input wire I_mem_result_valid,
    output wire O_mem_result_ready,
    input wire I_mem_result_wr,
    input wire [31:0] I_mem_result_data,I_mem_result_tag,
    input wire [3:0] I_mem_result_error,
    input wire I_device_busy,I_clear_stats,
    output wire O_busy,
    output reg O_contract_fault,O_response_discarded,O_issue_exhausted,
    output reg O_window_valid,
    output reg [WINDOW_BITS:0] O_busy_cycles,O_grant_cycles,
    output reg [191:0] O_client_grants
);
    localparam integer CLIENT_DEPTH=1<<CLIENT_BITS,PENDING_DEPTH=1<<PENDING_BITS;
    localparam integer BG_GUARD=SERVICE_BOUND*(PENDING_DEPTH+MAX_BURST+1);
    reg S_offer;
    reg [2:0] S_selected,S_last,S_round;
    reg [5:0] S_burst;
    reg S_wr;
    reg [20:0] S_addr;
    reg [31:0] S_data,S_tag,S_token,S_generation;
    reg [3:0] S_mask;
    reg [31:0] S_next_issue;
    // Pending = issue32/client3/wr1/original tag32/token32/generation32.
    reg [131:0] S_pending[0:PENDING_DEPTH-1];
    reg [PENDING_BITS-1:0] S_head,S_tail;
    reg [PENDING_BITS:0] S_count;
    reg [CLIENT_BITS:0] S_credit[0:5],S_result_count[0:5];
    reg [CLIENT_BITS-1:0] S_result_head[0:5],S_result_tail[0:5];
    reg [15:0] S_age[0:5];
    reg [WINDOW_BITS-1:0] S_window;
    reg [WINDOW_BITS:0] S_busy_cycles,S_grant_cycles;
    reg [5:0] C_eligible;
    reg C_found,C_scan_found,C_bg_found,C_aged,C_slack;
    reg [2:0] C_choice,C_scan,C_bg;
    reg [15:0] C_age;
    reg [31:0] C_deadline,C_slack_time,C_difference;
    integer C_i,C_j,S_i;
    wire S_accept=O_mem_valid && I_mem_ready;
    wire [131:0] S_expected=S_count!=0 ? S_pending[S_head] :
        {S_next_issue,S_selected,S_wr,S_tag,S_token,S_generation};
    wire S_response_match=(S_count!=0 || S_accept) && I_mem_result_tag==S_expected[131:100] &&
        I_mem_result_wr==S_expected[96];
    wire S_response=I_mem_result_valid && O_mem_result_ready && S_response_match;
    wire [2:0] S_response_client=S_expected[99:97];
    wire [5:0] S_result_take=O_client_result_valid & I_client_result_ready;
    wire S_any_credit=S_credit[0]!=0 || S_credit[1]!=0 || S_credit[2]!=0 ||
        S_credit[3]!=0 || S_credit[4]!=0 || S_credit[5]!=0;
    assign O_mem_valid=!I_reset && S_offer;
    assign {O_mem_wr,O_mem_addr,O_mem_data,O_mem_mask,O_mem_tag}={S_wr,S_addr,S_data,S_mask,S_next_issue};
    // Every correctly reserved response has space, even if a client is stalled.
    // An unrelated response is consumed/diagnosed but cannot clear expected debt.
    assign O_mem_result_ready=!I_reset;
    assign O_busy=S_offer || S_count!=0 || S_any_credit;
    // Physically separate banks: each has only one write and one read address.
    // No reset on data storage; valid/counts delimit entries written by this owner.
    genvar client;
    generate for(client=0;client<6;client=client+1) begin: g_results
        reg [132:0] S_results[0:CLIENT_DEPTH-1];
        always @(posedge I_clk) begin
            if(!I_reset && S_response && S_response_client==client)
                S_results[S_result_tail[client]]<={I_mem_result_wr,I_mem_result_data,S_expected[95:0],I_mem_result_error};
        end
        assign O_client_result_valid[client]=!I_reset && S_result_count[client]!=0;
        assign {O_client_result_wr[client],O_client_result_data[client*32+:32],O_client_result_tag[client*32+:32],
            O_client_result_token[client*32+:32],O_client_result_generation[client*32+:32],
            O_client_result_error[client*4+:4]}=S_results[S_result_head[client]];
    end endgenerate
    always @* begin
        C_eligible=0;
        for(C_i=0;C_i<6;C_i=C_i+1)
            C_eligible[C_i]=I_client_valid[C_i] && S_credit[C_i]<CLIENT_DEPTH;
        C_scan_found=0; C_scan=0; C_deadline=0; C_difference=0;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            if(C_eligible[C_i]) begin
                C_difference=I_client_deadline[C_i*32+:32]-C_deadline;
                if(!C_scan_found || C_difference[31] ||
                    (C_difference==0 && ((S_last==C_i && S_burst<MAX_BURST) ||
                    (S_last==C_scan && S_burst>=MAX_BURST)))) begin
                    C_scan_found=1; C_scan=C_i; C_deadline=I_client_deadline[C_i*32+:32];
                end
            end
        end
        C_bg_found=0; C_bg=2; C_age=0; C_aged=0;
        // S_round visits the three background clients in cyclic order.
        for(C_i=0;C_i<3;C_i=C_i+1) begin
            C_j=S_round+C_i;
            if(C_j>=5) C_j=C_j-3;
            if(C_eligible[C_j] && (!C_bg_found ||
                (S_age[C_j]>=AGE_LIMIT && S_age[C_j]>C_age))) begin
                C_bg_found=1; C_bg=C_j; C_age=S_age[C_j];
            end
        end
        C_aged=C_bg_found && C_age>=AGE_LIMIT;
        if(!C_aged && S_last>=2 && S_last<=4 && S_burst<MAX_BURST && C_eligible[S_last]) begin
            C_bg_found=1; C_bg=S_last;
        end
        C_slack_time=C_deadline-I_time;
        C_slack=C_scan_found && !C_slack_time[31] && C_slack_time>BG_GUARD;
        C_found=0; C_choice=0;
        if(C_scan_found && !(C_aged && C_slack)) begin C_found=1; C_choice=C_scan; end
        else if(C_bg_found) begin C_found=1; C_choice=C_bg; end
        else if(C_eligible[5]) begin C_found=1; C_choice=5; end
        O_client_ready=0;
        if(S_accept) O_client_ready[S_selected]=1;
    end
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_offer<=0; S_selected<=0; S_last<=5; S_round<=2; S_burst<=0;
            S_wr<=0; S_addr<=0; S_data<=0; S_tag<=0; S_token<=0; S_generation<=0; S_mask<=0;
            S_next_issue<=1; S_head<=0; S_tail<=0; S_count<=0;
            S_window<=0; S_busy_cycles<=0; S_grant_cycles<=0; O_window_valid<=0;
            O_busy_cycles<=0; O_grant_cycles<=0; O_client_grants<=0;
            O_contract_fault<=0; O_response_discarded<=0; O_issue_exhausted<=0;
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                S_credit[S_i]<=0; S_result_count[S_i]<=0;
                S_result_head[S_i]<=0; S_result_tail[S_i]<=0; S_age[S_i]<=0;
            end
        end else begin
            O_response_discarded<=0; O_window_valid<=0;
            if(I_clear_stats) begin
                S_window<=0; S_busy_cycles<=0; S_grant_cycles<=0;
                O_busy_cycles<=0; O_grant_cycles<=0; O_client_grants<=0;
            end else begin
                S_window<=S_window+1'b1;
                if(&S_window) begin
                    O_window_valid<=1; O_busy_cycles<=S_busy_cycles+I_device_busy;
                    O_grant_cycles<=S_grant_cycles+S_accept;
                    S_busy_cycles<=0; S_grant_cycles<=0;
                end else begin
                    S_busy_cycles<=S_busy_cycles+I_device_busy; S_grant_cycles<=S_grant_cycles+S_accept;
                end
                if(S_accept && O_client_grants[S_selected*32+:32]!=32'hffffffff)
                    O_client_grants[S_selected*32+:32]<=O_client_grants[S_selected*32+:32]+32'd1;
            end
            for(S_i=0;S_i<6;S_i=S_i+1) begin
                if(!I_client_valid[S_i] || (S_accept && S_selected==S_i)) S_age[S_i]<=0;
                else if(S_age[S_i]!=16'hffff) S_age[S_i]<=S_age[S_i]+1'b1;
                case({S_accept && S_selected==S_i,S_result_take[S_i]})
                    2'b10:S_credit[S_i]<=S_credit[S_i]+1'b1;
                    2'b01:S_credit[S_i]<=S_credit[S_i]-1'b1;
                    default:begin end
                endcase
                case({S_response && S_response_client==S_i,S_result_take[S_i]})
                    2'b10:S_result_count[S_i]<=S_result_count[S_i]+1'b1;
                    2'b01:S_result_count[S_i]<=S_result_count[S_i]-1'b1;
                    default:begin end
                endcase
                if(S_result_take[S_i]) S_result_head[S_i]<=S_result_head[S_i]+1'b1;
            end
            case({S_accept,S_response})
                2'b10:S_count<=S_count+1'b1;
                2'b01:S_count<=S_count-1'b1;
                default:begin end
            endcase
            if(I_mem_result_valid && !S_response_match) begin
                O_response_discarded<=1; O_contract_fault<=1;
            end
            if(S_response) begin
                S_result_tail[S_response_client]<=S_result_tail[S_response_client]+1'b1;
                S_head<=S_head+1'b1;
            end
            if(S_accept) begin
                S_pending[S_tail]<={S_next_issue,S_selected,S_wr,S_tag,S_token,S_generation};
                S_tail<=S_tail+1'b1; S_offer<=0;
                if(S_next_issue==32'hffffffff) O_issue_exhausted<=1;
                else S_next_issue<=S_next_issue+1'b1;
                S_last<=S_selected;
                S_burst<=S_last==S_selected && S_burst<MAX_BURST ? S_burst+1'b1 : 6'd1;
                if(S_selected>=2 && S_selected<=4) S_round<=S_selected==4 ? 3'd2 : S_selected+1'b1;
                if(!I_client_valid[S_selected]) O_contract_fault<=1;
            end
            if(!S_offer && !O_contract_fault && !O_issue_exhausted &&
                !(I_mem_result_valid && !S_response_match) && S_count<PENDING_DEPTH && C_found) begin
                S_offer<=1; S_selected<=C_choice;
                S_wr<=I_client_wr[C_choice]; S_addr<=I_client_addr[C_choice*21+:21];
                S_data<=I_client_data[C_choice*32+:32]; S_mask<=I_client_mask[C_choice*4+:4];
                S_tag<=I_client_tag[C_choice*32+:32]; S_token<=I_client_token[C_choice*32+:32];
                S_generation<=I_client_generation[C_choice*32+:32];
            end
        end
    end
    // synthesis translate_off
    initial begin
        if(CLIENT_BITS<1 || CLIENT_BITS>5 || PENDING_BITS<2 || PENDING_BITS>6 ||
            MAX_BURST<1 || MAX_BURST>32 || AGE_LIMIT<1 || AGE_LIMIT>65535 ||
            SERVICE_BOUND<1 || BG_GUARD>=32'h40000000 || WINDOW_BITS<2 || WINDOW_BITS>30) begin
            $display("FAIL: frame_mem_arbiter invalid queue/QoS/statistics parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
