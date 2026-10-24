// Copy one retained index item, then release the bank BEFORE publishing it.
// All ports are host-domain. String reads have one clock of latency.
module media_item_fetch (
    input wire I_clk,I_reset,I_media_valid,
    input wire [31:0] I_media_generation,
    input wire I_start_valid,
    output wire O_start_ready,
    input wire [5:0] I_index,
    input wire [15:0] I_tag,
    input wire [31:0] I_revision,
    input wire I_abort,
    output wire O_busy,O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_error,
    output reg [5:0] O_index,
    output reg [15:0] O_tag,
    output reg [31:0] O_generation,O_revision,
    output reg [6:0] O_count,O_file_length,O_audio_length,
    output reg [5:0] O_title_length,
    output reg [9:0] O_duration,O_transition_ms,
    output reg [2:0] O_transition,
    output reg [6:0] O_policy,
    input wire [1:0] I_string_kind,
    input wire [6:0] I_string_address,
    output reg [7:0] O_string_data,
    output wire O_acquire_valid,
    input wire I_acquire_ready,I_snapshot_valid,
    input wire [6:0] I_snapshot_count,
    input wire [31:0] I_snapshot_generation,I_snapshot_revision,
    output wire O_release_valid,
    input wire I_release_ready,
    output wire O_read_valid,
    input wire I_read_ready,
    output wire [5:0] O_read_index,
    output wire [1:0] O_read_kind,
    output wire [6:0] O_read_address,
    output wire [15:0] O_read_tag,
    input wire I_read_result_valid,
    output wire O_read_result_ready,
    input wire [6:0] I_read_file_length,I_read_audio_length,
    input wire [5:0] I_read_title_length,
    input wire [9:0] I_read_duration,I_read_transition_ms,
    input wire [2:0] I_read_transition,
    input wire [6:0] I_read_policy,
    input wire [7:0] I_read_data,
    input wire [15:0] I_read_tag,
    input wire [3:0] I_read_error,
    output reg O_response_discarded
);
    localparam [2:0] IDLE=0,ACQUIRE=1,SNAPSHOT=2,OFFER=3,READ=4,RELEASE=5,RESULT=6;
    reg [2:0] S_state;
    reg S_cancel,S_first,S_buffer_valid;
    reg [1:0] S_kind;
    reg [6:0] S_address;
    reg [7:0] S_strings[0:167];
    wire S_active=S_state!=IDLE && S_state!=RESULT;
    wire S_invalid=!I_media_valid || I_media_generation!=O_generation;
    wire S_cancel_now=S_cancel || I_abort || S_invalid;
    wire S_metadata_ok=I_read_file_length!=0 && I_read_file_length<=64 &&
        I_read_audio_length<=64 && I_read_title_length<=40 &&
        I_read_duration!=0 && I_read_duration<=600 && I_read_transition<=7 &&
        (I_read_transition_ms==200 || I_read_transition_ms==400 ||
         I_read_transition_ms==600 || I_read_transition_ms==1000);
    wire S_metadata_same={I_read_file_length,I_read_audio_length,I_read_title_length,
        I_read_duration,I_read_transition_ms,I_read_transition,I_read_policy}==
        {O_file_length,O_audio_length,O_title_length,O_duration,O_transition_ms,O_transition,O_policy};
    wire S_result=I_read_result_valid && O_read_result_ready && I_read_tag==O_tag;
    wire S_copy=S_result && I_read_error==0 && !S_cancel_now &&
        (S_first ? S_metadata_ok : S_metadata_same);
    wire [6:0] S_file_length=S_first ? I_read_file_length : O_file_length;
    wire [6:0] S_audio_length=S_first ? I_read_audio_length : O_audio_length;
    wire [5:0] S_title_length=S_first ? I_read_title_length : O_title_length;
    wire [7:0] S_write_address=S_kind==0 ? {1'b0,S_address} :
        (S_kind==1 ? 8'd64+S_address : 8'd128+S_address);
    wire [7:0] S_read_address=I_string_kind==0 ? {1'b0,I_string_address} :
        (I_string_kind==1 ? 8'd64+I_string_address : 8'd128+I_string_address);
    wire S_string_valid=(I_string_kind==0 && I_string_address<O_file_length) ||
        (I_string_kind==1 && I_string_address<O_audio_length) ||
        (I_string_kind==2 && I_string_address<{1'b0,O_title_length});
    assign O_start_ready=!I_reset && S_state==IDLE;
    assign O_busy=S_state!=IDLE;
    assign O_done_valid=!I_reset && S_state==RESULT;
    assign O_acquire_valid=!I_reset && S_state==ACQUIRE && !S_cancel_now;
    assign O_release_valid=!I_reset && S_state==RELEASE;
    assign O_read_valid=!I_reset && S_state==OFFER;
    assign {O_read_index,O_read_kind,O_read_address,O_read_tag}={O_index,S_kind,S_address,O_tag};
    assign O_read_result_ready=!I_reset && S_state==READ;
    // No reset on the string RAM; published lengths delimit initialized bytes.
    always @(posedge I_clk) begin
        if(S_copy) S_strings[S_write_address]<=I_read_data;
        if(!I_reset && S_string_valid && S_buffer_valid)
            O_string_data<=S_strings[S_read_address];
        else O_string_data<=0;
    end
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_state<=IDLE; S_cancel<=0; S_first<=1; S_buffer_valid<=0; S_kind<=0; S_address<=0;
            O_error<=0; O_index<=0; O_tag<=0; O_generation<=0; O_revision<=0;
            O_count<=0; O_file_length<=0; O_audio_length<=0; O_title_length<=0;
            O_duration<=0; O_transition_ms<=0; O_transition<=0; O_policy<=0; O_response_discarded<=0;
        end else begin
            O_response_discarded<=0;
            if(S_active && S_cancel_now) begin
                S_cancel<=1;
                if(O_error==0) O_error<=S_invalid ? 4'd3 : 4'd2;
            end
            case(S_state)
                IDLE:if(I_start_valid) begin
                    S_buffer_valid<=0;
                    O_index<=I_index; O_tag<=I_tag; O_generation<=I_media_generation;
                    O_revision<=I_revision; O_error<=0; O_count<=0;
                    O_file_length<=0; O_audio_length<=0; O_title_length<=0;
                    O_duration<=0; O_transition_ms<=0; O_transition<=0; O_policy<=0;
                    S_kind<=0; S_address<=0; S_first<=1; S_cancel<=0;
                    if(!I_media_valid || I_abort) begin O_error<=!I_media_valid ? 4'd3 : 4'd2; S_state<=RESULT; end
                    else S_state<=ACQUIRE;
                end
                ACQUIRE:if(S_cancel_now) S_state<=RESULT;
                    else if(I_acquire_ready) S_state<=SNAPSHOT;
                SNAPSHOT:if(I_snapshot_valid) begin
                    O_count<=I_snapshot_count;
                    if(S_cancel_now) S_state<=RELEASE;
                    else if(I_snapshot_generation!=O_generation ||
                        (O_revision!=0 && I_snapshot_revision!=O_revision)) begin O_error<=4; S_state<=RELEASE; end
                    else if(I_snapshot_count==0 || I_snapshot_count>64 || {1'b0,O_index}>=I_snapshot_count) begin
                        O_error<=1; S_state<=RELEASE;
                    end else begin O_revision<=I_snapshot_revision; S_state<=OFFER; end
                end
                OFFER:if(I_read_ready) S_state<=READ;
                READ:if(I_read_result_valid) begin
                    if(I_read_tag!=O_tag) O_response_discarded<=1;
                    else if(S_cancel_now) S_state<=RELEASE;
                    else if(I_read_error!=0) begin O_error<=I_read_error; S_state<=RELEASE; end
                    else if(!(S_first ? S_metadata_ok : S_metadata_same)) begin O_error<=5; S_state<=RELEASE; end
                    else begin
                        if(S_first) begin
                            O_file_length<=I_read_file_length; O_audio_length<=I_read_audio_length;
                            O_title_length<=I_read_title_length; O_duration<=I_read_duration;
                            O_transition_ms<=I_read_transition_ms; O_transition<=I_read_transition; O_policy<=I_read_policy; S_first<=0;
                        end
                        S_state<=OFFER;
                        if(S_kind==0 && S_address+7'd1==S_file_length) begin
                            S_address<=0;
                            if(S_audio_length!=0) S_kind<=1;
                            else if(S_title_length!=0) S_kind<=2;
                            else S_state<=RELEASE;
                        end else if(S_kind==1 && S_address+7'd1==S_audio_length) begin
                            S_address<=0;
                            if(S_title_length!=0) S_kind<=2; else S_state<=RELEASE;
                        end else if(S_kind==2 && S_address+7'd1=={1'b0,S_title_length}) S_state<=RELEASE;
                        else S_address<=S_address+7'd1;
                    end
                end
                RELEASE:if(I_release_ready) begin
                    S_buffer_valid<=O_error==0 && !S_cancel_now;
                    S_state<=RESULT;
                end
                RESULT:if(I_done_ready) S_state<=IDLE;
                default:begin S_cancel<=1; O_error<=6; S_state<=RELEASE; end
            endcase
        end
    end
endmodule
