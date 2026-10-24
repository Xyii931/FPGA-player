// Four media clients, three descriptor leases, one real FAT namespace. Host domain.
// client0 image, client1/2 audio A/B, client3 scan. See design02 section 5.4.2.
module media_file_mux (
    input wire I_clk,
    input wire I_reset,
    input wire I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_lease_block,
    input wire [3:0] I_lease_request,
    input wire [3:0] I_lease_active,
    input wire [7:0] I_lease_context,
    output wire [3:0] O_lease_grant,
    input wire [3:0] I_client_open_valid,
    output wire [3:0] O_client_open_ready,
    input wire [227:0] I_client_open,
    input wire [3:0] I_client_path_valid,
    output wire [3:0] O_client_path_ready,
    input wire [31:0] I_client_path_data,
    input wire [3:0] I_client_path_last,
    input wire [3:0] I_client_open_cancel,
    output wire [3:0] O_client_open_result_valid,
    input wire [3:0] I_client_open_result_ready,
    output wire [96:0] O_client_open_result,
    input wire [3:0] I_client_read_valid,
    output wire [3:0] O_client_read_ready,
    input wire [335:0] I_client_read,
    output wire [3:0] O_client_byte_valid,
    input wire [3:0] I_client_byte_ready,
    output wire [90:0] O_client_byte,
    output wire [3:0] O_client_done_valid,
    input wire [3:0] I_client_done_ready,
    output wire [379:0] O_client_done,
    input wire [3:0] I_client_cancel_valid,
    output wire [3:0] O_client_cancel_ready,
    input wire [71:0] I_client_cancel,
    output wire [3:0] O_client_cancel_done_valid,
    input wire [3:0] I_client_cancel_done_ready,
    output wire [49:0] O_client_cancel_done,
    input wire [3:0] I_client_close_valid,
    output wire [3:0] O_client_close_ready,
    input wire [7:0] I_client_close_context,
    input wire [3:0] I_client_urgent,
    output wire O_busy,
    output wire O_quiescent,
    output wire [2:0] O_leased_contexts,
    output wire [2:0] O_descriptors,
    output wire [2:0] O_pending_reads,
    output wire O_contract_fault,
    output wire O_response_discarded,
    input wire I_scan_valid,
    output wire O_scan_ready,
    input wire [15:0] I_scan_tag,
    input wire [6:0] I_scan_path_length,
    input wire [31:0] I_scan_sector_budget,
    input wire I_scan_path_valid,
    output wire O_scan_path_ready,
    input wire [7:0] I_scan_path_data,
    input wire I_scan_path_last,
    input wire I_scan_stop,
    input wire I_scan_cancel,
    output wire O_scan_entry_valid,
    input wire I_scan_entry_ready,
    output wire [7:0] O_scan_attr,
    output wire [31:0] O_scan_size,
    output wire [31:0] O_scan_first_cluster,
    output wire [87:0] O_scan_alias,
    output wire [6:0] O_scan_name_length,
    output wire O_scan_is_lfn,
    output wire O_scan_name_valid,
    input wire I_scan_name_ready,
    output wire [7:0] O_scan_name_data,
    output wire O_scan_name_last,
    output wire O_scan_done_valid,
    input wire I_scan_done_ready,
    output wire [15:0] O_scan_tag,
    output wire [31:0] O_scan_generation,
    output wire [31:0] O_scan_sectors,
    output wire [2:0] O_scan_warning,
    output wire [7:0] O_scan_error,
    output wire [3:0] O_scan_storage_error,
    output wire O_core_enum_valid,
    input wire I_core_enum_ready,
    output wire [15:0] O_core_enum_tag,
    output wire [6:0] O_core_enum_path_length,
    output wire [31:0] O_core_enum_sector_budget,
    output wire O_core_enum_path_valid,
    input wire I_core_enum_path_ready,
    output wire [7:0] O_core_enum_path_data,
    output wire O_core_enum_path_last,
    output wire O_core_enum_stop,
    output wire O_core_enum_cancel,
    input wire I_core_enum_entry_valid,
    output wire O_core_enum_entry_ready,
    input wire [7:0] I_core_enum_attr,
    input wire [31:0] I_core_enum_size,
    input wire [31:0] I_core_enum_first_cluster,
    input wire [87:0] I_core_enum_alias,
    input wire [6:0] I_core_enum_name_length,
    input wire I_core_enum_is_lfn,
    input wire I_core_enum_name_valid,
    output wire O_core_enum_name_ready,
    input wire [7:0] I_core_enum_name_data,
    input wire I_core_enum_name_last,
    input wire I_core_enum_done_valid,
    output wire O_core_enum_done_ready,
    input wire [15:0] I_core_enum_tag,
    input wire [31:0] I_core_enum_generation,
    input wire [31:0] I_core_enum_sectors,
    input wire [2:0] I_core_enum_warning,
    input wire [7:0] I_core_enum_error,
    input wire [3:0] I_core_enum_storage_error,
    output wire O_core_open_valid,
    input wire I_core_open_ready,
    output wire [1:0] O_core_open_context,
    output wire [15:0] O_core_open_tag,
    output wire [6:0] O_core_path_length,
    output wire [31:0] O_core_sector_budget,
    output wire O_core_path_valid,
    input wire I_core_path_ready,
    output wire [7:0] O_core_path_data,
    output wire O_core_path_last,
    output wire O_core_open_cancel,
    input wire I_core_open_result_valid,
    output wire O_core_open_result_ready,
    input wire [1:0] I_core_open_context,
    input wire [15:0] I_core_open_tag,
    input wire [31:0] I_core_open_generation,
    input wire [31:0] I_core_open_size,
    input wire [31:0] I_core_open_first_cluster,
    input wire [31:0] I_core_open_sectors,
    input wire [7:0] I_core_open_attr,
    input wire [7:0] I_core_open_error,
    input wire [3:0] I_core_open_storage_error,
    input wire [2:0] I_core_open_warning,
    input wire [31:0] I_core_byte_generation,
    input wire [31:0] I_core_done_generation,
    input wire [31:0] I_core_cancel_done_generation,
    output wire O_core_close_valid,
    input wire I_core_close_ready,
    output wire [1:0] O_core_close_context,
    output wire O_core_read_valid,
    input wire I_core_read_ready,
    output wire [1:0] O_core_read_context,
    output wire [1:0] O_core_read_priority,
    output wire [31:0] O_core_offset,
    output wire [31:0] O_core_length,
    output wire [15:0] O_core_epoch,
    output wire [2:0] O_core_urgent_context,
    input wire I_core_byte_valid,
    output wire O_core_byte_ready,
    input wire [7:0] I_core_byte_data,
    input wire [1:0] I_core_byte_context,
    input wire [15:0] I_core_byte_epoch,
    input wire [31:0] I_core_byte_offset,
    input wire I_core_byte_last,
    input wire I_core_done_valid,
    output wire O_core_done_ready,
    input wire [1:0] I_core_done_context,
    input wire [15:0] I_core_done_epoch,
    input wire [31:0] I_core_done_bytes,
    input wire I_core_done_eof,
    input wire [7:0] I_core_done_error,
    input wire [3:0] I_core_done_storage_error,
    output wire O_core_cancel_valid,
    input wire I_core_cancel_ready,
    output wire [1:0] O_core_cancel_context,
    output wire [15:0] O_core_cancel_epoch,
    input wire I_core_cancel_done_valid,
    output wire O_core_cancel_done_ready,
    input wire [1:0] I_core_cancel_done_context,
    input wire [15:0] I_core_cancel_done_epoch
);
    localparam [1:0] NS_IDLE=0,NS_SEND=1,NS_WAIT=2,NS_LOCAL=3;
    reg [1:0] S_ns_state,S_ns_client;
    reg S_ns_enum,S_ns_cancel;
    reg [56:0] S_ns_command;
    reg [31:0] S_ns_generation;
    reg [2:0] S_ns_next;
    reg [2:0] S_leases,S_descriptors,S_pending,S_sent,S_cancel_pending,S_cancel_sent,S_cancel_used;
    reg [1:0] S_owner[0:2];
    reg [31:0] S_lease_generation[0:2],S_read_generation[0:2];
    reg [15:0] S_read_epoch[0:2];
    reg [1:0] S_lease_next,S_read_next,S_cancel_next,S_close_next;
    reg S_read_offer,S_cancel_offer,S_close_offer;
    reg [2:0] S_result_valid;
    reg [94:0] S_result[0:2];
    reg [83:0] S_read_command;
    reg [17:0] S_cancel_command;
    reg [1:0] S_read_client,S_cancel_client,S_close_client,S_close_context;
    reg S_fault,S_discarded;
    integer S_i;
    reg [3:0] C_grants,C_clients,C_open_ready,C_path_ready,C_open_result_valid;
    reg [3:0] C_read_ready,C_byte_valid,C_done_valid,C_cancel_ready,C_cancel_done_valid,C_close_ready;
    reg [379:0] C_done;
    reg [2:0] C_urgent;
    reg C_lease_found,C_ns_found,C_read_found,C_cancel_found,C_close_found;
    reg [1:0] C_lease_client,C_lease_context,C_read_client,C_cancel_client,C_close_client;
    reg [2:0] C_ns_choice;
    reg [56:0] C_open;
    reg [83:0] C_read;
    reg [17:0] C_cancel;
    reg [1:0] C_context;
    reg [2:0] C_score,C_best;
    integer C_i,C_j;
    wire [1:0] S_read_context=S_read_command[83:82];
    wire [1:0] S_cancel_context=S_cancel_command[17:16];
    wire S_ns_lost=!I_media_valid || S_ns_generation!=I_media_generation;
    wire S_read_lost=!I_media_valid || S_read_generation[S_read_context]!=I_media_generation;
    wire S_open_match=I_core_open_context==S_ns_command[56:55] &&
        I_core_open_tag==S_ns_command[54:39] && I_core_open_generation==S_ns_generation;
    wire S_enum_match=I_core_enum_tag==S_ns_command[54:39] && I_core_enum_generation==S_ns_generation;
    wire S_byte_match=I_core_byte_context<3 && S_leases[I_core_byte_context] &&
        S_pending[I_core_byte_context] && S_sent[I_core_byte_context] && !S_result_valid[I_core_byte_context] &&
        I_core_byte_epoch==S_read_epoch[I_core_byte_context] &&
        I_core_byte_generation==S_read_generation[I_core_byte_context];
    wire S_done_match=I_core_done_context<3 && S_leases[I_core_done_context] &&
        S_pending[I_core_done_context] && S_sent[I_core_done_context] && !S_result_valid[I_core_done_context] &&
        I_core_done_epoch==S_read_epoch[I_core_done_context] &&
        I_core_done_generation==S_read_generation[I_core_done_context];
    wire S_cancel_match=I_core_cancel_done_context<3 && S_leases[I_core_cancel_done_context] &&
        S_cancel_pending[I_core_cancel_done_context] && S_cancel_sent[I_core_cancel_done_context] &&
        I_core_cancel_done_epoch==S_read_epoch[I_core_cancel_done_context] &&
        I_core_cancel_done_generation==S_read_generation[I_core_cancel_done_context];
    function owns;
        input [1:0] client,context;
        begin owns=context<3 && S_leases[context] && S_owner[context]==client; end
    endfunction
    always @* begin
        C_grants=0; C_clients=0; C_urgent=0;
        for(C_i=0;C_i<3;C_i=C_i+1) if(S_leases[C_i]) begin
            C_clients[S_owner[C_i]]=1;
            if(I_lease_active[S_owner[C_i]] || (!I_lease_block && I_media_valid &&
                I_lease_context[S_owner[C_i]*2+:2]==C_i && S_lease_generation[C_i]==I_media_generation))
                C_grants[S_owner[C_i]]=1;
            C_urgent[C_i]=I_client_urgent[S_owner[C_i]] && S_pending[C_i] && S_sent[C_i] && !S_result_valid[C_i];
        end
        C_lease_found=0; C_lease_client=0; C_lease_context=0;
        C_ns_found=0; C_ns_choice=0;
        C_read_found=0; C_read_client=0; C_best=0;
        C_cancel_found=0; C_cancel_client=0; C_close_found=0; C_close_client=0;
        C_open_ready=0; C_path_ready=0; C_open_result_valid=0;
        C_read_ready=0; C_byte_valid=0; C_done_valid=0; C_done=0;
        C_cancel_ready=0; C_cancel_done_valid=0; C_close_ready=0;
        C_open=0; C_read=0; C_cancel=0; C_context=0; C_score=0; C_j=0;
        for(C_i=0;C_i<4;C_i=C_i+1) begin
            C_j=(S_lease_next+C_i)%4; C_context=I_lease_context[C_j*2+:2];
            if(!C_lease_found && I_lease_request[C_j] && !C_clients[C_j] && C_context<3 &&
                !S_leases[C_context] && !I_lease_active[C_j]) begin
                C_lease_found=1; C_lease_client=C_j; C_lease_context=C_context;
            end
        end
        // A namespace command owns its complete path and terminal, not an entire song.
        for(C_i=0;C_i<5;C_i=C_i+1) begin
            C_j=S_ns_next+C_i; if(C_j>=5) C_j=C_j-5;
            if(C_j<4) begin
                C_open=I_client_open[C_j*57+:57]; C_context=C_open[56:55];
                if(!C_ns_found && I_client_open_valid[C_j] && I_lease_active[C_j] && owns(C_j,C_context) &&
                    !S_descriptors[C_context] && !S_pending[C_context] && !S_cancel_pending[C_context] &&
                    S_lease_generation[C_context]==I_media_generation) begin C_ns_found=1; C_ns_choice=C_j; end
            end else if(!C_ns_found && I_scan_valid && I_lease_active[3] && C_clients[3]) begin
                C_ns_found=1; C_ns_choice=4;
            end
        end
        for(C_i=0;C_i<4;C_i=C_i+1) begin
            C_j=(S_read_next+C_i)%4; C_read=I_client_read[C_j*84+:84]; C_context=C_read[83:82];
            C_score={I_client_urgent[C_j],C_read[81:80]};
            if(I_client_read_valid[C_j] && I_lease_active[C_j] && owns(C_j,C_context) &&
                S_descriptors[C_context] && !S_pending[C_context] && !S_cancel_pending[C_context] &&
                !I_client_close_valid[C_j] && !I_client_cancel_valid[C_j] &&
                !(S_close_offer && S_close_context==C_context) &&
                !(S_ns_state!=NS_IDLE && S_ns_client==C_j) &&
                S_lease_generation[C_context]==I_media_generation && (!C_read_found || C_score>C_best)) begin
                C_read_found=1; C_read_client=C_j; C_best=C_score;
            end
            C_j=(S_cancel_next+C_i)%4; C_cancel=I_client_cancel[C_j*18+:18]; C_context=C_cancel[17:16];
            if(!C_cancel_found && I_client_cancel_valid[C_j] && owns(C_j,C_context) &&
                S_descriptors[C_context] && S_sent[C_context] && !S_cancel_pending[C_context] &&
                !(S_close_offer && S_close_context==C_context) &&
                !S_cancel_used[C_context] && C_cancel[15:0]==S_read_epoch[C_context]) begin
                C_cancel_found=1; C_cancel_client=C_j;
            end
            C_j=(S_close_next+C_i)%4; C_context=I_client_close_context[C_j*2+:2];
            if(!C_close_found && I_client_close_valid[C_j] && owns(C_j,C_context) &&
                S_descriptors[C_context] && !S_pending[C_context] && !S_cancel_pending[C_context] &&
                !I_client_cancel_valid[C_j] && !(S_cancel_offer && S_cancel_context==C_context) &&
                !(S_ns_state!=NS_IDLE && S_ns_client==C_j)) begin C_close_found=1; C_close_client=C_j; end
        end
        if(!I_reset) begin
            if(!S_fault && I_media_valid && S_ns_state==NS_IDLE && C_ns_found && C_ns_choice<4)
                C_open_ready[C_ns_choice]=1;
            if(S_ns_state==NS_WAIT && !S_ns_enum) begin
                C_path_ready[S_ns_client]=I_core_path_ready;
                if(I_core_open_result_valid && S_open_match) C_open_result_valid[S_ns_client]=1;
            end
            if(S_ns_state==NS_LOCAL && !S_ns_enum) C_open_result_valid[S_ns_client]=1;
            if(!S_fault && I_media_valid && !S_read_offer && C_read_found)
                C_read_ready[C_read_client]=1;
            if(I_core_byte_valid && S_byte_match) C_byte_valid[S_owner[I_core_byte_context]]=1;
            for(C_i=0;C_i<3;C_i=C_i+1) if(S_result_valid[C_i]) begin
                C_done_valid[S_owner[C_i]]=1;
                C_done[S_owner[C_i]*95+:95]=S_result[C_i];
            end
            if(!S_cancel_offer && C_cancel_found) C_cancel_ready[C_cancel_client]=1;
            if(I_core_cancel_done_valid && S_cancel_match) C_cancel_done_valid[S_owner[I_core_cancel_done_context]]=1;
            // Close is acknowledged only on the physical descriptor close edge.
            if(S_close_offer) C_close_ready[S_close_client]=I_core_close_ready;
        end
    end
    assign O_lease_grant=C_grants & {4{!I_reset}};
    assign O_leased_contexts=S_leases;
    assign O_descriptors=S_descriptors;
    assign O_pending_reads=S_pending;
    assign O_contract_fault=S_fault;
    assign O_response_discarded=S_discarded;
    assign O_quiescent=!I_reset && S_leases==0 && S_descriptors==0 && S_pending==0 && S_cancel_pending==0 &&
        S_ns_state==NS_IDLE && !S_read_offer && !S_cancel_offer && !S_close_offer && S_result_valid==0;
    assign O_busy=!O_quiescent;
    assign O_client_open_ready=C_open_ready;
    assign O_client_path_ready=C_path_ready;
    assign O_client_open_result_valid=C_open_result_valid;
    assign O_client_open_result=S_ns_state==NS_LOCAL ?
        {S_ns_command[56:39],S_ns_generation,32'd0,8'd1,4'd0,3'd0} :
        {I_core_open_context,I_core_open_tag,I_core_open_generation,I_core_open_size,
         I_core_open_error,I_core_open_storage_error,I_core_open_warning};
    assign O_client_read_ready=C_read_ready;
    assign O_client_byte_valid=C_byte_valid;
    assign O_client_byte={I_core_byte_data,I_core_byte_context,I_core_byte_epoch,I_core_byte_generation,I_core_byte_offset,I_core_byte_last};
    assign O_client_done_valid=C_done_valid;
    assign O_client_done=C_done;
    assign O_client_cancel_ready=C_cancel_ready;
    assign O_client_cancel_done_valid=C_cancel_done_valid;
    assign O_client_cancel_done={I_core_cancel_done_context,I_core_cancel_done_epoch,I_core_cancel_done_generation};
    assign O_client_close_ready=C_close_ready;
    assign O_core_open_valid=!I_reset && S_ns_state==NS_SEND && !S_ns_enum && !S_ns_lost;
    assign O_core_open_context=S_ns_command[56:55];
    assign O_core_open_tag=S_ns_command[54:39];
    assign O_core_path_length=S_ns_command[38:32];
    assign O_core_sector_budget=S_ns_command[31:0];
    assign O_core_path_valid=!I_reset && S_ns_state==NS_WAIT && !S_ns_enum && I_client_path_valid[S_ns_client];
    assign O_core_path_data=I_client_path_data[S_ns_client*8+:8];
    assign O_core_path_last=I_client_path_last[S_ns_client];
    assign O_core_open_cancel=S_ns_cancel || I_client_open_cancel[S_ns_client];
    assign O_core_open_result_ready=!I_reset && S_ns_state==NS_WAIT && !S_ns_enum &&
        (S_open_match ? I_client_open_result_ready[S_ns_client] : 1'b1);
    assign O_core_read_valid=!I_reset && S_read_offer && !S_read_lost;
    assign O_core_read_context=S_read_command[83:82];
    assign O_core_read_priority=S_read_command[81:80];
    assign O_core_offset=S_read_command[79:48];
    assign O_core_length=S_read_command[47:16];
    assign O_core_epoch=S_read_command[15:0];
    assign O_core_urgent_context=C_urgent;
    assign O_core_byte_ready=!I_reset && (S_byte_match ? I_client_byte_ready[S_owner[I_core_byte_context]] : 1'b1);
    // One held terminal per context breaks unrelated clients' result backpressure.
    // Client consumption, rather than this capture, retires the mux read debt.
    assign O_core_done_ready=!I_reset;
    assign O_core_cancel_valid=!I_reset && S_cancel_offer;
    assign O_core_cancel_context=S_cancel_context;
    assign O_core_cancel_epoch=S_cancel_command[15:0];
    assign O_core_cancel_done_ready=!I_reset &&
        (S_cancel_match ? I_client_cancel_done_ready[S_owner[I_core_cancel_done_context]] : 1'b1);
    assign O_core_close_valid=!I_reset && S_close_offer;
    assign O_core_close_context=S_close_context;
    assign O_scan_ready=!I_reset && !S_fault && I_media_valid && S_ns_state==NS_IDLE && C_ns_found && C_ns_choice==4;
    assign O_core_enum_valid=!I_reset && S_ns_state==NS_SEND && S_ns_enum && !S_ns_lost;
    assign O_core_enum_tag=S_ns_command[54:39];
    assign O_core_enum_path_length=S_ns_command[38:32];
    assign O_core_enum_sector_budget=S_ns_command[31:0];
    assign O_core_enum_path_valid=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && I_scan_path_valid;
    assign O_core_enum_path_data=I_scan_path_data;
    assign O_core_enum_path_last=I_scan_path_last;
    assign O_core_enum_stop=I_scan_stop;
    assign O_core_enum_cancel=S_ns_cancel || I_scan_cancel;
    assign O_scan_path_ready=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && I_core_enum_path_ready;
    assign O_scan_entry_valid=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && S_enum_match && I_core_enum_entry_valid;
    assign O_core_enum_entry_ready=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && (S_enum_match ? I_scan_entry_ready : 1'b1);
    assign O_scan_attr=I_core_enum_attr;
    assign O_scan_size=I_core_enum_size;
    assign O_scan_first_cluster=I_core_enum_first_cluster;
    assign O_scan_alias=I_core_enum_alias;
    assign O_scan_name_length=I_core_enum_name_length;
    assign O_scan_is_lfn=I_core_enum_is_lfn;
    assign O_scan_name_valid=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && S_enum_match && I_core_enum_name_valid;
    assign O_core_enum_name_ready=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && (S_enum_match ? I_scan_name_ready : 1'b1);
    assign O_scan_name_data=I_core_enum_name_data;
    assign O_scan_name_last=I_core_enum_name_last;
    assign O_scan_done_valid=!I_reset && S_ns_enum &&
        ((S_ns_state==NS_WAIT && S_enum_match && I_core_enum_done_valid) || S_ns_state==NS_LOCAL);
    assign O_core_enum_done_ready=!I_reset && S_ns_state==NS_WAIT && S_ns_enum && (S_enum_match ? I_scan_done_ready : 1'b1);
    assign O_scan_tag=S_ns_state==NS_LOCAL ? S_ns_command[54:39] : I_core_enum_tag;
    assign O_scan_generation=S_ns_state==NS_LOCAL ? S_ns_generation : I_core_enum_generation;
    assign O_scan_sectors=S_ns_state==NS_LOCAL ? 32'd0 : I_core_enum_sectors;
    assign O_scan_warning=S_ns_state==NS_LOCAL ? 3'd0 : I_core_enum_warning;
    assign O_scan_error=S_ns_state==NS_LOCAL ? 8'd1 : I_core_enum_error;
    assign O_scan_storage_error=S_ns_state==NS_LOCAL ? 4'd0 : I_core_enum_storage_error;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_ns_state<=NS_IDLE; S_ns_client<=0; S_ns_enum<=0; S_ns_cancel<=0; S_ns_command<=0;
            S_ns_generation<=0; S_ns_next<=0; S_leases<=0; S_descriptors<=0; S_pending<=0; S_sent<=0;
            S_cancel_pending<=0; S_cancel_sent<=0; S_cancel_used<=0;
            S_lease_next<=0; S_read_next<=0; S_cancel_next<=0; S_close_next<=0;
            S_read_offer<=0; S_cancel_offer<=0; S_close_offer<=0; S_result_valid<=0;
            S_read_command<=0; S_cancel_command<=0; S_read_client<=0; S_cancel_client<=0;
            S_close_client<=0; S_close_context<=0;
            S_fault<=0; S_discarded<=0;
            for(S_i=0;S_i<3;S_i=S_i+1) begin
                S_owner[S_i]<=0; S_lease_generation[S_i]<=0; S_read_generation[S_i]<=0; S_read_epoch[S_i]<=0; S_result[S_i]<=0;
            end
        end else begin
            S_discarded<=0;
            if(!S_fault && !I_lease_block && I_media_valid && C_lease_found) begin
                S_leases[C_lease_context]<=1; S_owner[C_lease_context]<=C_lease_client;
                S_lease_generation[C_lease_context]<=I_media_generation; S_lease_next<=C_lease_client+1'b1;
            end
            for(S_i=0;S_i<3;S_i=S_i+1) if(S_leases[S_i] && !I_lease_active[S_owner[S_i]] &&
                (!I_lease_request[S_owner[S_i]] || I_lease_block || !I_media_valid ||
                 I_lease_context[S_owner[S_i]*2+:2]!=S_i || S_lease_generation[S_i]!=I_media_generation) &&
                !S_descriptors[S_i] && !S_pending[S_i] && !S_cancel_pending[S_i] &&
                !(S_ns_state!=NS_IDLE && S_ns_client==S_owner[S_i]) &&
                !(S_close_offer && S_close_context==S_i)) S_leases[S_i]<=0;
            if(S_ns_state!=NS_IDLE && S_ns_state!=NS_LOCAL) begin
                if(S_ns_enum ? I_scan_cancel : I_client_open_cancel[S_ns_client]) S_ns_cancel<=1;
            end
            case(S_ns_state)
                NS_IDLE:if(!S_fault && I_media_valid && C_ns_found) begin
                    S_ns_enum<=C_ns_choice==4; S_ns_client<=C_ns_choice==4 ? 2'd3 : C_ns_choice[1:0];
                    S_ns_command<=C_ns_choice==4 ? {2'd0,I_scan_tag,I_scan_path_length,I_scan_sector_budget} :
                        I_client_open[C_ns_choice*57+:57];
                    S_ns_generation<=I_media_generation;
                    S_ns_cancel<=C_ns_choice==4 ? I_scan_cancel : I_client_open_cancel[C_ns_choice];
                    S_ns_state<=NS_SEND;
                    S_ns_next<=C_ns_choice==4 ? 3'd0 : C_ns_choice+1'b1;
                end
                NS_SEND:if(S_ns_lost) S_ns_state<=NS_LOCAL;
                    else if(S_ns_enum ? I_core_enum_ready : I_core_open_ready) S_ns_state<=NS_WAIT;
                NS_WAIT:begin
                    if(!S_ns_enum && I_core_open_result_valid && O_core_open_result_ready) begin
                        if(!S_open_match) begin S_fault<=1; S_discarded<=1; end
                        else begin
                            S_descriptors[S_ns_command[56:55]]<=I_core_open_error==0;
                            S_ns_state<=NS_IDLE;
                        end
                    end
                    if(S_ns_enum && I_core_enum_done_valid && O_core_enum_done_ready) begin
                        if(!S_enum_match) begin S_fault<=1; S_discarded<=1; end
                        else S_ns_state<=NS_IDLE;
                    end
                end
                NS_LOCAL:if(S_ns_enum ? I_scan_done_ready : I_client_open_result_ready[S_ns_client]) S_ns_state<=NS_IDLE;
            endcase
            if(|C_read_ready) begin
                S_read_command<=I_client_read[C_read_client*84+:84]; S_read_client<=C_read_client; S_read_offer<=1;
                S_pending[I_client_read[C_read_client*84+82+:2]]<=1;
                S_sent[I_client_read[C_read_client*84+82+:2]]<=0;
                S_cancel_used[I_client_read[C_read_client*84+82+:2]]<=0;
                S_read_epoch[I_client_read[C_read_client*84+82+:2]]<=I_client_read[C_read_client*84+:16];
                S_read_generation[I_client_read[C_read_client*84+82+:2]]<=I_media_generation;
                S_read_next<=C_read_client+1'b1;
            end
            if(S_read_offer) begin
                if(S_read_lost) begin
                    S_result_valid[S_read_context]<=1;
                    S_result[S_read_context]<={S_read_context,S_read_command[15:0],S_read_generation[S_read_context],32'd0,1'b0,8'd1,4'd0};
                    S_read_offer<=0;
                end else if(I_core_read_ready) begin S_read_offer<=0; S_sent[S_read_context]<=1; end
            end
            for(S_i=0;S_i<3;S_i=S_i+1) if(S_result_valid[S_i] && I_client_done_ready[S_owner[S_i]]) begin
                S_result_valid[S_i]<=0; S_pending[S_i]<=0;
            end
            if(I_core_byte_valid && O_core_byte_ready && !S_byte_match) begin S_discarded<=1; S_fault<=1; end
            if(I_core_done_valid && O_core_done_ready) begin
                if(S_done_match) begin
                    S_result_valid[I_core_done_context]<=1;
                    S_result[I_core_done_context]<={I_core_done_context,I_core_done_epoch,I_core_done_generation,
                        I_core_done_bytes,I_core_done_eof,I_core_done_error,I_core_done_storage_error};
                end
                else begin S_discarded<=1; S_fault<=1; end
            end
            if(|C_cancel_ready) begin
                S_cancel_command<=I_client_cancel[C_cancel_client*18+:18]; S_cancel_client<=C_cancel_client;
                S_cancel_offer<=1; S_cancel_next<=C_cancel_client+1'b1;
                S_cancel_pending[I_client_cancel[C_cancel_client*18+16+:2]]<=1;
                S_cancel_sent[I_client_cancel[C_cancel_client*18+16+:2]]<=0;
                S_cancel_used[I_client_cancel[C_cancel_client*18+16+:2]]<=1;
            end
            if(S_cancel_offer && I_core_cancel_ready) begin S_cancel_offer<=0; S_cancel_sent[S_cancel_context]<=1; end
            if(I_core_cancel_done_valid && O_core_cancel_done_ready) begin
                if(S_cancel_match) begin S_cancel_pending[I_core_cancel_done_context]<=0; S_cancel_sent[I_core_cancel_done_context]<=0; end
                else begin S_discarded<=1; S_fault<=1; end
            end
            if(!S_close_offer && C_close_found) begin
                S_close_offer<=1; S_close_client<=C_close_client;
                S_close_context<=I_client_close_context[C_close_client*2+:2]; S_close_next<=C_close_client+1'b1;
            end
            if(S_close_offer && I_core_close_ready) begin
                S_close_offer<=0; S_descriptors[S_close_context]<=0; S_sent[S_close_context]<=0;
                if(!I_client_close_valid[S_close_client] ||
                    I_client_close_context[S_close_client*2+:2]!=S_close_context) S_fault<=1;
            end
        end
    end
endmodule
