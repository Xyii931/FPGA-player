// Actual resident slot 5 allocation -> generated RGBA writes -> genuine FINISH.
// Infrastructure reset only. Media removal never resets a resident transaction.
module resident_frame_init (
    input wire I_clk,I_reset,I_enable,
    output wire O_slot_valid,
    input wire I_slot_ready,
    output wire [114:0] O_slot_command,
    input wire I_slot_result_valid,
    output wire O_slot_result_ready,
    input wire [96:0] I_slot_result,
    output wire O_mem_valid,
    input wire I_mem_ready,
    output wire O_mem_wr,
    output wire [20:0] O_mem_addr,
    output wire [31:0] O_mem_data,O_mem_tag,O_mem_token,O_mem_generation,
    output wire [3:0] O_mem_mask,
    input wire I_mem_result_valid,
    output wire O_mem_result_ready,
    input wire I_mem_result_wr,
    input wire [31:0] I_mem_result_tag,I_mem_result_token,I_mem_result_generation,
    input wire [3:0] I_mem_result_error,
    output wire O_busy,O_ready,
    output reg [31:0] O_token,
    output wire [31:0] O_generation,
    output reg [3:0] O_error,
    output reg O_response_discarded
);
    localparam [3:0] IDLE=0,ALLOC_SEND=1,ALLOC_WAIT=2,WRITE_SEND=3,WRITE_WAIT=4,
        FINISH_SEND=5,FINISH_WAIT=6,READY=7,FAULT=8;
    reg [3:0] S_state;
    reg [18:0] S_index;
    reg [9:0] S_x;
    reg [8:0] S_y;
    wire S_finish=S_state==FINISH_SEND || S_state==FINISH_WAIT;
    wire S_slot_match=I_slot_result[92:90]==(S_finish ? 3'd1 : 3'd0) &&
        I_slot_result[89:87]==5 && I_slot_result[86:85]==2 && I_slot_result[52:21]==0 &&
        (!S_finish || I_slot_result[84:53]==O_token);
    wire S_mem_match=I_mem_result_wr && I_mem_result_tag=={13'd0,S_index} &&
        I_mem_result_token==O_token && I_mem_result_generation==0;
    wire S_border=S_x<8 || S_x>=632 || S_y<8 || S_y>=472;
    wire S_panel=S_x>=48 && S_x<592 && S_y>=144 && S_y<336;
    assign O_slot_valid=!I_reset && (S_state==ALLOC_SEND || S_state==FINISH_SEND);
    assign O_slot_command={S_finish ? 3'd1 : 3'd0,3'd5,2'd2,S_finish ? O_token : 32'd0,
        32'd0,32'h414c5254,3'd0,2'd0,1'b1,O_error==0,S_finish,S_finish,1'b0,1'b0};
    assign O_slot_result_ready=!I_reset && (S_state==ALLOC_WAIT || S_state==FINISH_WAIT);
    assign O_mem_valid=!I_reset && S_state==WRITE_SEND;
    assign O_mem_wr=1'b1;
    assign O_mem_addr=21'h177000+{2'd0,S_index};
    assign O_mem_data=S_border ? 32'hfff0f0ff : (S_panel ? 32'hb01018ff : 32'h300408ff);
    assign O_mem_mask=4'd0;
    assign O_mem_tag={13'd0,S_index};
    assign O_mem_token=O_token;
    assign O_mem_generation=32'd0;
    assign O_mem_result_ready=!I_reset && S_state==WRITE_WAIT;
    assign O_busy=S_state!=IDLE && S_state!=READY && S_state!=FAULT;
    assign O_ready=!I_reset && S_state==READY;
    assign O_generation=32'd0;
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_index<=0; S_x<=0; S_y<=0; O_token<=0; O_error<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            case(S_state)
                IDLE:if(I_enable) begin S_index<=0; S_x<=0; S_y<=0; O_error<=0; S_state<=ALLOC_SEND; end
                ALLOC_SEND:if(I_slot_ready) S_state<=ALLOC_WAIT;
                ALLOC_WAIT:if(I_slot_result_valid) begin
                    if(!S_slot_match) O_response_discarded<=1;
                    else if(I_slot_result[96:93]!=0 || I_slot_result[84:53]==0) begin O_error<=1; S_state<=FAULT; end
                    else begin O_token<=I_slot_result[84:53]; S_state<=WRITE_SEND; end
                end
                WRITE_SEND:if(I_mem_ready) S_state<=WRITE_WAIT;
                WRITE_WAIT:if(I_mem_result_valid) begin
                    if(!S_mem_match) O_response_discarded<=1;
                    else if(I_mem_result_error!=0) begin O_error<=2; S_state<=FINISH_SEND; end
                    else if(S_index==19'd307199) S_state<=FINISH_SEND;
                    else begin
                        S_index<=S_index+1'b1;
                        if(S_x==639) begin S_x<=0; S_y<=S_y+1'b1; end else S_x<=S_x+1'b1;
                        S_state<=WRITE_SEND;
                    end
                end
                FINISH_SEND:if(I_slot_ready) S_state<=FINISH_WAIT;
                FINISH_WAIT:if(I_slot_result_valid) begin
                    if(!S_slot_match) O_response_discarded<=1;
                    else if(O_error!=0) S_state<=FAULT;
                    else if(I_slot_result[96:93]!=0) begin O_error<=3; S_state<=FAULT; end
                    else S_state<=READY;
                end
                READY,FAULT:begin end
                default:begin O_error<=4; S_state<=FAULT; end
            endcase
        end
    end
endmodule
