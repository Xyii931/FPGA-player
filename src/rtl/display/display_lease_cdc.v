// Full lease publication: host receipt is separate from actual video installation.
// Shared global reset MUST cover slot/owner/guard/reader and both FIFO directions.
// Multi-bit payloads cross only u_requests/u_results. Query/proofs belong to video.
// Install enable permits an attempt; live proofs are checked on that actual edge.
module display_lease_cdc #(
    parameter integer QUEUE_BITS=2
) (
    input wire I_host_clk,I_video_clk,I_async_reset,
    input wire I_publish_valid,
    output wire O_publish_ready,
    input wire [137:0] I_publish_leases,
    input wire [31:0] I_publish_version,
    output wire O_done_valid,
    input wire I_done_ready,
    output wire [31:0] O_done_version,
    output reg [3:0] O_error,
    output wire O_host_busy,
    output reg O_host_quarantined,O_host_response_discarded,
    input wire I_video_install_enable,
    input wire [1:0] I_video_block,I_video_in_use,I_video_owner_retired,I_video_pipeline_retired,I_video_guard_fault,
    input wire [246:0] I_video_query_config,
    output reg [137:0] O_video_leases,
    output reg [31:0] O_video_version,
    output reg O_video_installed,O_video_quarantined,
    output reg [1:0] O_video_authorized
);
    localparam [1:0] H_IDLE=0,H_SEND=1,H_WAIT=2,H_RESULT=3;
    localparam [1:0] V_IDLE=0,V_INSTALL=1,V_REPLY=2;
    reg [1:0] S_host_state,S_video_state;
    reg [169:0] S_request,S_command;
    reg [35:0] S_response;
    reg [31:0] S_host_version;
    (* ASYNC_REG="TRUE" *) reg S_fault_meta,S_fault_sync;
    wire S_host_reset,S_video_reset;
    wire S_request_write_ready,S_request_valid,S_request_ready;
    wire [169:0] S_request_data;
    wire S_result_write_ready,S_result_valid,S_result_ready;
    wire [35:0] S_result_data;
    wire [31:0] S_command_version=S_command[169:138];
    wire [137:0] S_command_leases=S_command[137:0];
    wire [3:0] S_result_error=S_result_data[35:32];
    wire S_result_match=S_result_data[31:0]==S_request[169:138];
    wire S_host_sequence_ok=I_publish_version!=0 && !(&S_host_version) && I_publish_version==S_host_version+1'b1;
    wire S_video_sequence_ok=S_command_version!=0 && !(&O_video_version) && S_command_version==O_video_version+1'b1;
    reset_sync u_host_reset (.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_video_reset (.I_clk(I_video_clk),.I_async_reset(I_async_reset),.O_reset(S_video_reset));
    async_fifo #(.DATA_BITS(170),.ADDR_BITS(QUEUE_BITS)) u_requests (
        .I_write_clk(I_host_clk),.I_read_clk(I_video_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_host_state==H_SEND),.O_write_ready(S_request_write_ready),.I_write_data(S_request),
        .O_write_full(),.O_write_level(),.O_read_valid(S_request_valid),.I_read_ready(S_request_ready),
        .O_read_data(S_request_data),.O_read_empty(),.O_read_level()
    );
    async_fifo #(.DATA_BITS(36),.ADDR_BITS(QUEUE_BITS)) u_results (
        .I_write_clk(I_video_clk),.I_read_clk(I_host_clk),.I_async_reset(I_async_reset),
        .I_write_valid(S_video_state==V_REPLY),.O_write_ready(S_result_write_ready),.I_write_data(S_response),
        .O_write_full(),.O_write_level(),.O_read_valid(S_result_valid),.I_read_ready(S_result_ready),
        .O_read_data(S_result_data),.O_read_empty(),.O_read_level()
    );
    assign O_publish_ready=!I_async_reset && !S_host_reset && S_host_state==H_IDLE && !O_host_quarantined && !S_fault_sync;
    assign O_host_busy=S_host_state!=H_IDLE || O_host_quarantined;
    assign O_done_valid=!I_async_reset && !S_host_reset && S_host_state==H_RESULT;
    assign O_done_version=S_request[169:138];
    assign S_request_ready=!I_async_reset && !S_video_reset && S_video_state==V_IDLE;
    assign S_result_ready=!I_async_reset && !S_host_reset && S_host_state==H_WAIT;
    // Compare ALL source identity fields, including invalidated lease metadata.
    reg C_range_ok,C_permission_ok;
    reg [1:0] C_changed;
    integer C_i;
    always @* begin
        C_range_ok=1; C_changed=0;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            if(S_command_leases[136+C_i] && (S_command_leases[130+C_i*3+:3]>=6 ||
                S_command_leases[66+C_i*32+:32]==0 || (S_command_leases[C_i] && S_command_leases[130+C_i*3+:3]!=5)))
                C_range_ok=0;
            C_changed[C_i]={S_command_leases[136+C_i],S_command_leases[130+C_i*3+:3],
                S_command_leases[66+C_i*32+:32],S_command_leases[2+C_i*32+:32],S_command_leases[C_i]}!=
                {O_video_leases[136+C_i],O_video_leases[130+C_i*3+:3],O_video_leases[66+C_i*32+:32],
                O_video_leases[2+C_i*32+:32],O_video_leases[C_i]};
        end
        C_permission_ok=(C_changed & (~I_video_block | I_video_in_use | ~I_video_owner_retired |
            ~I_video_pipeline_retired | I_video_guard_fault))==0;
        O_video_authorized=0;
        for(C_i=0;C_i<2;C_i=C_i+1)
            O_video_authorized[C_i]=!I_async_reset && !S_video_reset && !O_video_quarantined &&
                !I_video_block[C_i] && !I_video_guard_fault[C_i] && O_video_leases[136+C_i] &&
                I_video_query_config[245+C_i] &&
                I_video_query_config[238+C_i*3+:3]==O_video_leases[130+C_i*3+:3] &&
                I_video_query_config[174+C_i*32+:32]==O_video_leases[66+C_i*32+:32] &&
                I_video_query_config[110+C_i*32+:32]==O_video_leases[2+C_i*32+:32] &&
                I_video_query_config[108+C_i]==O_video_leases[C_i];
    end
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin
            S_host_state<=H_IDLE; S_request<=0; S_host_version<=0;
            O_error<=0; O_host_quarantined<=0; O_host_response_discarded<=0;
            S_fault_meta<=0; S_fault_sync<=0;
        end else begin
            S_fault_meta<=O_video_quarantined; S_fault_sync<=S_fault_meta;
            if(S_fault_sync) O_host_quarantined<=1;
            O_host_response_discarded<=S_result_valid && S_result_ready && !S_result_match;
            case(S_host_state)
                H_IDLE:if(I_publish_valid && O_publish_ready) begin
                    S_request<={I_publish_version,I_publish_leases}; O_error<=0;
                    if(!S_host_sequence_ok) begin O_error<=2; O_host_quarantined<=1; S_host_state<=H_RESULT; end
                    else S_host_state<=H_SEND;
                end
                H_SEND:if(S_request_write_ready) S_host_state<=H_WAIT;
                H_WAIT:if(S_result_valid && S_result_ready && S_result_match) begin
                    O_error<=S_result_error!=0 ? S_result_error : S_fault_sync ? 4'd4 : 4'd0;
                    if(S_result_error!=0 || S_fault_sync) O_host_quarantined<=1;
                    else S_host_version<=S_request[169:138];
                    S_host_state<=H_RESULT;
                end
                H_RESULT:if(I_done_ready) S_host_state<=H_IDLE;
                default:begin O_error<=4; O_host_quarantined<=1; S_host_state<=H_RESULT; end
            endcase
        end
    end
    always @(posedge I_video_clk or posedge S_video_reset) begin
        if(S_video_reset) begin
            S_video_state<=V_IDLE; S_command<=0; S_response<=0;
            O_video_leases<=0; O_video_version<=0; O_video_installed<=0; O_video_quarantined<=0;
        end else begin
            O_video_installed<=0;
            case(S_video_state)
                V_IDLE:if(S_request_valid && S_request_ready) begin S_command<=S_request_data; S_video_state<=V_INSTALL; end
                V_INSTALL:if(I_video_install_enable) begin
                    S_response<={4'd0,S_command_version};
                    if(O_video_quarantined) S_response<={4'd4,S_command_version};
                    else if(!S_video_sequence_ok) begin S_response<={4'd2,S_command_version}; O_video_quarantined<=1; end
                    else if(!C_range_ok) begin S_response<={4'd1,S_command_version}; O_video_quarantined<=1; end
                    else if(!C_permission_ok) begin S_response<={4'd3,S_command_version}; O_video_quarantined<=1; end
                    else begin
                        O_video_leases<=S_command_leases; O_video_version<=S_command_version; O_video_installed<=1;
                    end
                    S_video_state<=V_REPLY;
                end
                V_REPLY:if(S_result_write_ready) S_video_state<=V_IDLE;
                default:begin O_video_quarantined<=1; S_response<={4'd4,S_command_version}; S_video_state<=V_REPLY; end
            endcase
        end
    end
endmodule
