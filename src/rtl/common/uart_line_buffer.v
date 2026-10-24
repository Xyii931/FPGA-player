// Two complete-line slots, independent receive and parser read ports.
// Never publish a truncated line; overload drops whole lines and publishes error=3.
module uart_line_buffer (
    input wire I_clk,I_reset,I_rx_valid,I_frame_error,
    input wire [7:0] I_rx_data,
    output wire O_line_valid,
    input wire I_line_ready,
    output wire [7:0] O_line_length,
    output wire [1:0] O_line_error,
    input wire [6:0] I_read_address,
    output reg [7:0] O_read_data,
    output reg [31:0] O_dropped_lines
);
    reg [7:0] S_memory[0:255];
    reg S_head,S_tail,S_last_cr,S_discard,S_drop_pending;
    reg [1:0] S_count,S_bad;
    reg [7:0] S_length,S_lengths[0:1];
    reg [1:0] S_errors[0:1];
    wire S_pop=O_line_valid && I_line_ready;
    wire S_free=S_count<2 || S_pop;
    wire S_newline=I_rx_data==8'h0d || I_rx_data==8'h0a;
    wire S_skip=I_rx_data==8'h0a && S_last_cr;
    wire S_byte=I_rx_valid && !S_skip;
    wire S_line_end=S_byte && S_newline && !S_discard && S_free && (S_length!=0 || S_bad!=0);
    wire S_error_offer=S_drop_pending && S_free && S_length==0 && S_bad==0 && !S_discard && !I_rx_valid && !I_frame_error;
    wire S_push=S_line_end || S_error_offer;
    wire S_printable=I_rx_data>=32 && I_rx_data!=127 || I_rx_data==9;
    wire S_write=S_byte && !S_newline && !S_discard && S_free && S_printable && S_length<128;
    assign O_line_valid=!I_reset && S_count!=0;
    assign O_line_length=S_lengths[S_head];
    assign O_line_error=S_errors[S_head];
    // No RAM clear. Parser releases its head only after copying all needed bytes.
    always @(posedge I_clk) begin
        if(S_write && !I_reset) S_memory[{S_tail,S_length[6:0]}]<=I_rx_data;
        O_read_data<=S_memory[{S_head,I_read_address}];
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_head<=0; S_tail<=0; S_count<=0; S_last_cr<=0; S_discard<=0; S_drop_pending<=0;
            S_length<=0; S_bad<=0; S_lengths[0]<=0; S_lengths[1]<=0; S_errors[0]<=0; S_errors[1]<=0;
            O_dropped_lines<=0;
        end else begin
            if(S_pop) S_head<=!S_head;
            if(S_push) begin
                S_lengths[S_tail]<=S_error_offer ? 8'd0 : S_length;
                S_errors[S_tail]<=S_error_offer ? 2'd3 : S_bad;
                S_tail<=!S_tail; S_length<=0; S_bad<=0;
                if(S_error_offer) S_drop_pending<=0;
            end
            case({S_push,S_pop})
                2'b10:S_count<=S_count+1'b1;
                2'b01:S_count<=S_count-1'b1;
                default:begin end
            endcase
            if(I_frame_error) begin
                if(S_free && !S_discard) S_bad<=2;
                else begin S_discard<=1; S_drop_pending<=1; end
            end
            if(I_rx_valid) begin
                S_last_cr<=I_rx_data==8'h0d;
                if(!S_skip) begin
                    if(S_discard) begin
                        if(S_newline) begin
                            S_discard<=0; S_drop_pending<=1;
                            if(O_dropped_lines!=32'hffffffff) O_dropped_lines<=O_dropped_lines+1'b1;
                        end
                    end else if(!S_free) begin
                        if(!S_newline) S_discard<=1;
                        else begin
                            S_drop_pending<=1;
                            if(O_dropped_lines!=32'hffffffff) O_dropped_lines<=O_dropped_lines+1'b1;
                        end
                    end else if(!S_newline) begin
                        if(I_rx_data==8 || I_rx_data==127) begin
                            if(S_length!=0 && S_bad==0) S_length<=S_length-1'b1;
                        end else if(!S_printable) S_bad<=2;
                        else if(S_length==128) S_bad<=1;
                        else S_length<=S_length+1'b1;
                    end
                end
            end
        end
    end
endmodule
