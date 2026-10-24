// CFG1 double-copy store. Only a verified final commit changes the selected copy.
module settings_store (
    input wire I_clk,I_reset,I_load_valid,I_save_valid,
    output wire O_load_ready,O_save_ready,
    input wire [1023:0] I_config,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg O_done_save,O_initialized,O_found,
    output reg [3:0] O_error,
    output reg [1023:0] O_config,
    output reg [31:0] O_sequence,
    output wire O_busy,
    output wire O_flash_valid,
    input wire I_flash_ready,
    output wire [1:0] O_flash_op,
    output wire [23:0] O_flash_address,
    output wire [15:0] O_flash_length,O_flash_tag,
    output wire O_write_valid,
    input wire I_write_ready,
    output wire [7:0] O_write_data,
    output wire O_write_last,
    input wire I_read_valid,
    output wire O_read_ready,
    input wire [7:0] I_read_data,
    input wire I_read_last,I_flash_done_valid,
    output wire O_flash_done_ready,
    input wire [3:0] I_flash_error,
    input wire [15:0] I_flash_tag
);
    localparam [2:0] IDLE=0,REQUEST=1,TRANSFER=2,WAIT_DONE=3,CHECK=4,BUILD_CRC=5,RESULT=6;
    localparam [2:0] LOAD_A=0,LOAD_B=1,ERASE=2,BODY=3,VERIFY=4,COMMIT=5,FINAL=6;
    reg [2:0] S_state,S_job;
    reg S_active_bank,S_target_bank;
    reg [7:0] S_index;
    reg [15:0] S_tag;
    reg [1023:0] S_save_config;
    reg [31:0] S_save_sequence,S_crc,S_save_crc;
    reg [7:0] S_record[0:147];
    reg S_read_bad,S_compare_bad,S_load_failed;
    wire S_read_job=S_job==LOAD_A || S_job==LOAD_B || S_job==VERIFY || S_job==FINAL;
    wire [7:0] S_length=S_job==BODY || S_job==VERIFY ? 8'd144 : S_job==COMMIT ? 8'd4 : 8'd148;
    wire S_bank=S_job==LOAD_A ? 1'b0 : S_job==LOAD_B ? 1'b1 : S_target_bank;
    wire [31:0] S_record_sequence={S_record[11],S_record[10],S_record[9],S_record[8]};
    wire [31:0] S_sequence_delta=S_record_sequence-O_sequence;
    wire S_record_valid=S_index==148 && !S_read_bad &&
        {S_record[0],S_record[1],S_record[2],S_record[3]}==32'h43464731 &&
        {S_record[5],S_record[4]}==1 && {S_record[7],S_record[6]}==128 &&
        {S_record[143],S_record[142],S_record[141],S_record[140]}==~S_crc &&
        {S_record[147],S_record[146],S_record[145],S_record[144]}==0;
    assign O_load_ready=!I_reset && S_state==IDLE;
    assign O_save_ready=O_load_ready && O_initialized && !S_load_failed && !I_load_valid;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_busy=S_state!=IDLE;
    assign O_flash_valid=!I_reset && S_state==REQUEST;
    assign O_flash_op=S_read_job ? 2'd0 : S_job==ERASE ? 2'd2 : 2'd1;
    assign O_flash_address=(S_bank ? 24'h001000 : 24'h000000)+(S_job==COMMIT ? 24'd144 : 24'd0);
    assign O_flash_length=S_job==ERASE ? 16'd4096 : {8'd0,S_length};
    assign O_flash_tag=S_tag;
    assign O_write_valid=!I_reset && S_state==TRANSFER && !S_read_job && S_job!=ERASE;
    assign O_write_data=S_job==COMMIT ? 8'd0 : record_byte(S_index);
    assign O_write_last=S_index+8'd1==S_length;
    assign O_read_ready=!I_reset && S_state==TRANSFER && S_read_job;
    assign O_flash_done_ready=!I_reset && (S_state==WAIT_DONE || S_state==TRANSFER);

    function [31:0] crc_byte;
        input [31:0] crc;
        input [7:0] data;
        reg [31:0] value;
        integer bit_index;
        begin
            value=crc^{24'd0,data};
            for(bit_index=0;bit_index<8;bit_index=bit_index+1)
                value=value[0] ? (value>>1)^32'hedb88320 : value>>1;
            crc_byte=value;
        end
    endfunction
    function [7:0] record_byte;
        input [7:0] address;
        begin
            case(address)
                0:record_byte="C"; 1:record_byte="F"; 2:record_byte="G"; 3:record_byte="1";
                4:record_byte=1; 5:record_byte=0; 6:record_byte=128; 7:record_byte=0;
                8,9,10,11:record_byte=S_save_sequence[(address-8)*8+:8];
                140,141,142,143:record_byte=S_save_crc[(address-140)*8+:8];
                144,145,146,147:record_byte=0;
                default:record_byte=address>=12 && address<140 ? S_save_config[(address-12)*8+:8] : 8'd0;
            endcase
        end
    endfunction
    task begin_job;
        input [2:0] job;
        begin
            S_job<=job; S_index<=0; S_read_bad<=0; S_compare_bad<=0;
            S_crc<=32'hffffffff; S_tag<=S_tag+1'b1; S_state<=REQUEST;
        end
    endtask
    integer S_word;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=IDLE; S_job<=LOAD_A; S_active_bank<=0; S_target_bank<=0;
            S_index<=0; S_tag<=0; S_save_config<=0; S_save_sequence<=0;
            S_crc<=32'hffffffff; S_save_crc<=0; S_read_bad<=0; S_compare_bad<=0; S_load_failed<=0;
            O_done_save<=0; O_initialized<=0; O_found<=0; O_error<=0; O_config<=0; O_sequence<=0;
        end else case(S_state)
            IDLE:if(I_load_valid) begin
                O_found<=0; O_config<=0; O_sequence<=0; O_error<=0; O_done_save<=0; S_load_failed<=0;
                begin_job(LOAD_A);
            end else if(I_save_valid && O_save_ready) begin
                S_save_config<=I_config; S_save_sequence<=O_found ? O_sequence+32'd1 : 32'd1;
                S_target_bank<=O_found ? !S_active_bank : 1'b0;
                S_index<=0; S_crc<=32'hffffffff; O_done_save<=1; O_error<=0; S_state<=BUILD_CRC;
            end
            BUILD_CRC:begin
                S_crc<=crc_byte(S_crc,record_byte(S_index));
                if(S_index==139) begin S_save_crc<=~crc_byte(S_crc,record_byte(S_index)); begin_job(ERASE); end
                else S_index<=S_index+1'b1;
            end
            REQUEST:if(I_flash_ready) S_state<=S_job==ERASE ? WAIT_DONE : TRANSFER;
            TRANSFER:begin
                if(S_read_job && I_read_valid) begin
                    S_record[S_index]<=I_read_data;
                    if(S_index<140) S_crc<=crc_byte(S_crc,I_read_data);
                    if(I_read_last!=(S_index+8'd1==S_length)) S_read_bad<=1;
                    if((S_job==VERIFY || S_job==FINAL) && I_read_data!=record_byte(S_index)) S_compare_bad<=1;
                    S_index<=S_index+1'b1;
                    if(S_index+8'd1==S_length) S_state<=WAIT_DONE;
                end
                if(!S_read_job && O_write_valid && I_write_ready) begin
                    S_index<=S_index+1'b1;
                    if(S_index+8'd1==S_length) S_state<=WAIT_DONE;
                end
                // Physical preflight/WEL/timeout may fail before any payload byte.
                if(I_flash_done_valid) begin
                    S_read_bad<=1; O_error<=I_flash_tag!=S_tag ? 4'd5 : I_flash_error!=0 ? I_flash_error : 4'd5;
                    if(S_job==LOAD_A || S_job==LOAD_B) S_load_failed<=1;
                    S_state<=S_job==LOAD_A || S_job==LOAD_B ? CHECK : RESULT;
                end
            end
            WAIT_DONE:if(I_flash_done_valid) begin
                if(I_flash_tag!=S_tag || I_flash_error!=0) begin
                    S_read_bad<=1; O_error<=I_flash_tag!=S_tag ? 4'd5 : I_flash_error;
                    if(S_job==LOAD_A || S_job==LOAD_B) S_load_failed<=1;
                    if(S_job==LOAD_A || S_job==LOAD_B) S_state<=CHECK;
                    else S_state<=RESULT;
                end else S_state<=CHECK;
            end
            CHECK:case(S_job)
                LOAD_A,LOAD_B:begin
                    if(S_record_valid && (!O_found || (S_sequence_delta!=0 && !S_sequence_delta[31]))) begin
                        O_found<=1; O_sequence<=S_record_sequence; S_active_bank<=S_job==LOAD_B;
                        for(S_word=0;S_word<128;S_word=S_word+1) O_config[S_word*8+:8]<=S_record[S_word+12];
                    end
                    if(S_job==LOAD_A) begin_job(LOAD_B);
                    else begin O_initialized<=1; S_state<=RESULT; end
                end
                ERASE:begin_job(BODY);
                BODY:begin_job(VERIFY);
                VERIFY:if(S_read_bad || S_compare_bad || S_index!=144) begin O_error<=6; S_state<=RESULT; end
                    else begin_job(COMMIT);
                COMMIT:begin_job(FINAL);
                FINAL:if(!S_record_valid || S_compare_bad || S_record_sequence!=S_save_sequence) begin O_error<=6; S_state<=RESULT; end
                    else begin
                        O_found<=1; O_sequence<=S_save_sequence; S_active_bank<=S_target_bank;
                        O_config<=S_save_config; O_error<=0; S_state<=RESULT;
                    end
                default:begin O_error<=5; S_state<=RESULT; end
            endcase
            RESULT:if(I_done_ready) S_state<=IDLE;
            default:begin O_error<=5; S_state<=RESULT; end
        endcase
    end
endmodule
