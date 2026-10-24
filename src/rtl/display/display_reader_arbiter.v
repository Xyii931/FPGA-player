// Video-domain task/result/release routing. Client0=scanout, client1=candidate.
// Global reset only. Allocation and release ownership remain with the clients.
module display_reader_arbiter (
    input wire I_clk,I_reset,
    input wire [1:0] I_task_valid,
    output reg [1:0] O_task_ready,
    input wire [357:0] I_task_payload,
    input wire [7:0] I_task_block,
    input wire [3:0] I_bank_reserved,
    output wire [3:0] O_task_reserved,
    output wire O_reader_task_valid,
    input wire I_reader_task_ready,
    output wire [178:0] O_reader_task_payload,
    input wire I_reader_line_valid,
    output wire O_reader_line_ready,
    input wire [206:0] I_reader_line_payload,
    output reg [1:0] O_line_valid,
    input wire [1:0] I_line_ready,
    output wire [206:0] O_line_payload,
    input wire [3:0] I_release_valid,
    output reg [3:0] O_release_ready,
    input wire [451:0] I_release_payload,
    output wire [1:0] O_reader_release_valid,
    input wire [1:0] I_reader_release_ready,
    output wire [225:0] O_reader_release_payload,
    output reg [1:0] O_source_in_use,O_source_owner_retired,
    output reg O_contract_fault
);
    reg S_task_valid,S_prefer;
    reg [178:0] S_task_payload;
    reg [3:0] S_busy,S_sent,S_owner;
    reg [178:0] S_expected[0:3];
    reg [1:0] S_release_valid,S_release_owner,S_release_prefer;
    reg [225:0] S_release_payload;
    wire [1:0] S_task_index={S_task_payload[178],S_task_payload[144]};
    wire [1:0] S_line_index={I_reader_line_payload[178],I_reader_line_payload[144]};
    wire S_reader_task_fire=O_reader_task_valid && I_reader_task_ready;
    wire S_line_match=S_busy[S_line_index] &&
        (S_sent[S_line_index] || (S_reader_task_fire && S_task_index==S_line_index)) &&
        I_reader_line_payload[178:0]==S_expected[S_line_index];
    assign O_task_reserved=S_busy;
    assign O_reader_task_valid=!I_reset && S_task_valid;
    assign O_reader_task_payload=S_task_payload;
    assign O_line_payload=I_reader_line_payload;
    assign O_reader_line_ready=!I_reset && S_line_match && I_line_ready[S_owner[S_line_index]];
    assign O_reader_release_valid=I_reset ? 2'b00 : S_release_valid;
    assign O_reader_release_payload=S_release_payload;
    reg [1:0] C_eligible,C_release_pick,C_release_any;
    reg C_pick,C_any;
    reg [1:0] C_task_index;
    integer C_i,C_s,C_p;
    always @* begin
        C_eligible=0; C_task_index=0; C_any=0; C_pick=0;
        C_release_pick=0; C_release_any=0;
        O_task_ready=0; O_line_valid=0; O_release_ready=0;
        O_source_in_use=0; O_source_owner_retired=0;
        for(C_i=0;C_i<2;C_i=C_i+1) begin
            C_task_index={I_task_payload[C_i*179+178],I_task_payload[C_i*179+144]};
            C_eligible[C_i]=I_task_valid[C_i] && !S_busy[C_task_index] &&
                !I_bank_reserved[C_task_index] && !I_task_block[C_i*4+C_task_index];
            if(I_task_valid[C_i]) O_source_in_use[I_task_payload[C_i*179+178]]=1;
        end
        C_any=|C_eligible;
        C_pick=C_eligible[S_prefer] ? S_prefer : !S_prefer;
        if(!I_reset && !S_task_valid && C_any) O_task_ready[C_pick]=1;
        if(!I_reset && I_reader_line_valid && S_line_match) O_line_valid[S_owner[S_line_index]]=1;
        for(C_s=0;C_s<2;C_s=C_s+1) begin
            C_release_any[C_s]=I_release_valid[C_s] || I_release_valid[2+C_s];
            C_p=S_release_prefer[C_s]*2+C_s;
            C_release_pick[C_s]=I_release_valid[C_p] ? S_release_prefer[C_s] : !S_release_prefer[C_s];
            C_p=S_release_owner[C_s]*2+C_s;
            if(!I_reset && S_release_valid[C_s] && I_reader_release_ready[C_s]) O_release_ready[C_p]=1;
            if(S_busy[C_s*2+:2]!=0 || (S_task_valid && S_task_payload[178]==C_s) ||
                C_release_any[C_s] || S_release_valid[C_s]) O_source_in_use[C_s]=1;
            O_source_in_use[C_s]=!I_reset && O_source_in_use[C_s];
            O_source_owner_retired[C_s]=!I_reset && !O_source_in_use[C_s];
        end
    end
    integer S_i,S_p,S_index;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_task_valid<=0; S_task_payload<=0; S_prefer<=0;
            S_busy<=0; S_sent<=0; S_owner<=0;
            S_release_valid<=0; S_release_owner<=0; S_release_prefer<=0; S_release_payload<=0;
            O_contract_fault<=0;
            for(S_i=0;S_i<4;S_i=S_i+1) S_expected[S_i]<=0;
        end else begin
            if(|(I_task_valid & O_task_ready)) begin
                S_task_payload<=I_task_payload[C_pick*179+:179]; S_task_valid<=1; S_prefer<=!C_pick;
                S_index=I_task_payload[C_pick*179+178]*2+I_task_payload[C_pick*179+144];
                S_busy[S_index]<=1; S_sent[S_index]<=0; S_owner[S_index]<=C_pick;
                S_expected[S_index]<=I_task_payload[C_pick*179+:179];
            end
            if(S_reader_task_fire) begin S_task_valid<=0; S_sent[S_task_index]<=1; end
            if(I_reader_line_valid && !S_line_match) O_contract_fault<=1;
            if(I_reader_line_valid && O_reader_line_ready) begin S_busy[S_line_index]<=0; S_sent[S_line_index]<=0; end
            for(S_i=0;S_i<2;S_i=S_i+1) begin
                if(!S_release_valid[S_i] && C_release_any[S_i]) begin
                    S_p=C_release_pick[S_i]*2+S_i;
                    S_release_valid[S_i]<=1; S_release_owner[S_i]<=C_release_pick[S_i];
                    S_release_payload[S_i*113+:113]<=I_release_payload[S_p*113+:113];
                end
                if(S_release_valid[S_i]) begin
                    S_p=S_release_owner[S_i]*2+S_i;
                    if(!I_release_valid[S_p] || I_release_payload[S_p*113+:113]!=S_release_payload[S_i*113+:113])
                        O_contract_fault<=1;
                    if(I_reader_release_ready[S_i]) begin
                        S_release_valid[S_i]<=0; S_release_prefer[S_i]<=!S_release_owner[S_i];
                    end
                end
            end
        end
    end
endmodule
