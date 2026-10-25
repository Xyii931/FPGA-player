// Small stop-and-wait ASCII console. N/P/?; A0/1, R0..3, T01..60, V0..4, M0/1.
// One complete command per CR/LF; invalid/overlong lines never partly execute.
module lean_player_ctrl #(
    parameter integer CLOCK_HZ=125000000
) (
    input wire I_clk,I_reset,
    input wire [3:0] I_key_release,
    input wire I_rx_valid,I_rx_error,
    input wire [7:0] I_rx_data,
    output wire O_tx_valid,
    input wire I_tx_ready,
    output reg [7:0] O_tx_data,
    input wire I_active,I_busy,I_changed,
    input wire [3:0] I_current,
    input wire [4:0] I_count,
    input wire [3:0] I_error,
    output reg O_next,O_prev,O_reload,
    output reg O_auto,O_mute,
    output reg [1:0] O_rotation,
    output reg [2:0] O_volume,
    output reg [5:0] O_interval,
    output reg [31:0] O_dropped
);
    reg [31:0] S_second;
    reg [5:0] S_elapsed;
    reg [23:0] S_line;
    reg [1:0] S_length,S_reply;
    reg S_bad,S_last_cr;
    reg [5:0] S_tx_index;
    reg [3:0] S_current,S_error;
    reg [4:0] S_count;
    reg S_auto,S_mute,S_busy;
    reg [1:0] S_rotation;
    reg [2:0] S_volume;
    reg [5:0] S_interval;
    wire S_newline=I_rx_data==13 || I_rx_data==10;
    wire S_skip_lf=I_rx_data==10 && S_last_cr;
    wire S_line_end=I_rx_valid && S_newline && !S_skip_lf && (S_length!=0 || S_bad);
    wire [7:0] S_tens=S_line[15:8],S_ones=S_line[7:0];
    wire [6:0] S_seconds=(S_tens-8'd48)*7'd10+(S_ones-8'd48);
    wire S_valid_time=S_length==3 && S_line[23:16]=="T" && S_tens>="0" && S_tens<="6" &&
        S_ones>="0" && S_ones<="9" && S_seconds>=1 && S_seconds<=60;
    function [7:0] hex_digit;
        input [3:0] value;
        begin hex_digit=value<10 ? 8'd48+value : 8'd55+value; end
    endfunction
    assign O_tx_valid=!I_reset && S_reply!=0;
    // Status values are a single host-domain snapshot; numbers are hexadecimal.
    always @* begin
        O_tx_data=8'h20;
        if(S_reply==1) case(S_tx_index)
            0:O_tx_data="O"; 1:O_tx_data="K"; 2:O_tx_data=13; default:O_tx_data=10;
        endcase
        else if(S_reply==2) case(S_tx_index)
            0:O_tx_data="E"; 1,2:O_tx_data="R"; 3:O_tx_data=13; default:O_tx_data=10;
        endcase
        else case(S_tx_index)
            0:O_tx_data="I"; 1,6,11,15,19,24,28,32,36:O_tx_data=":";
            2:O_tx_data="0"; 3:O_tx_data=hex_digit(S_current);
            5:O_tx_data="N"; 7:O_tx_data=hex_digit({3'd0,S_count[4]}); 8:O_tx_data=hex_digit(S_count[3:0]);
            10:O_tx_data="A"; 12:O_tx_data=hex_digit({3'd0,S_auto});
            14:O_tx_data="R"; 16:O_tx_data=hex_digit({2'd0,S_rotation});
            18:O_tx_data="T"; 20:O_tx_data=hex_digit({2'd0,S_interval[5:4]}); 21:O_tx_data=hex_digit(S_interval[3:0]);
            23:O_tx_data="V"; 25:O_tx_data=hex_digit({1'b0,S_volume});
            27:O_tx_data="M"; 29:O_tx_data=hex_digit({3'd0,S_mute});
            31:O_tx_data="B"; 33:O_tx_data=hex_digit({3'd0,S_busy});
            35:O_tx_data="E"; 37:O_tx_data=hex_digit(S_error);
            38:O_tx_data=13; 39:O_tx_data=10;
            default:begin end
        endcase
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_second<=0; S_elapsed<=0; S_line<=0; S_length<=0; S_reply<=0;
            S_bad<=0; S_last_cr<=0; S_tx_index<=0; O_next<=0; O_prev<=0; O_reload<=0;
            O_auto<=1; O_mute<=0; O_rotation<=0; O_volume<=4; O_interval<=5; O_dropped<=0;
            S_current<=0; S_count<=0; S_auto<=0; S_mute<=0; S_busy<=0;
            S_rotation<=0; S_volume<=0; S_interval<=0; S_error<=0;
        end else begin
            O_next<=0; O_prev<=0; O_reload<=0;
            if(!I_active || I_busy || I_changed || !O_auto) begin S_second<=0; S_elapsed<=0; end
            else if(S_second==CLOCK_HZ-1) begin
                S_second<=0;
                if(S_elapsed==O_interval-1) begin S_elapsed<=0; O_next<=1; end
                else S_elapsed<=S_elapsed+1'b1;
            end else S_second<=S_second+1'b1;
            // UART commands below have priority when a board event coincides.
            if(I_key_release[0]) O_prev<=1;
            if(I_key_release[1]) O_next<=1;
            if(I_key_release[2]) O_auto<=!O_auto;
            if(I_key_release[3]) begin O_rotation<=O_rotation+1'b1; O_reload<=1; end
            if(O_tx_valid && I_tx_ready) begin
                if((S_reply==1 && S_tx_index==3) || (S_reply==2 && S_tx_index==4) || S_tx_index==39) begin
                    S_reply<=0; S_tx_index<=0;
                end else S_tx_index<=S_tx_index+1'b1;
            end
            if(I_rx_error) S_bad<=1;
            if(I_rx_valid) begin
                S_last_cr<=I_rx_data==13;
                if(!S_skip_lf) begin
                    if(S_line_end) begin
                        S_line<=0; S_length<=0; S_bad<=0;
                        if(S_reply!=0) O_dropped<=O_dropped+1'b1;
                        else begin
                            S_reply<=1; S_tx_index<=0;
                            if(S_bad || I_rx_error) S_reply<=2;
                            else if(S_length==1 && S_line[7:0]=="N") begin O_next<=1; O_prev<=0; end
                            else if(S_length==1 && S_line[7:0]=="P") begin O_prev<=1; O_next<=0; end
                            else if(S_length==1 && S_line[7:0]=="?") begin
                                S_reply<=3; S_current<=I_current; S_count<=I_count; S_error<=I_error;
                                S_auto<=O_auto; S_rotation<=O_rotation; S_interval<=O_interval;
                                S_volume<=O_volume; S_mute<=O_mute; S_busy<=I_busy;
                            end
                            else if(S_length==2 && S_line[15:8]=="A" && (S_line[7:0]=="0" || S_line[7:0]=="1")) begin
                                O_auto<=S_line[0]; S_second<=0; S_elapsed<=0;
                            end
                            else if(S_length==2 && S_line[15:8]=="M" && (S_line[7:0]=="0" || S_line[7:0]=="1")) O_mute<=S_line[0];
                            else if(S_length==2 && S_line[15:8]=="R" && S_line[7:0]>="0" && S_line[7:0]<="3") begin
                                O_rotation<=S_line[1:0]; O_reload<=1;
                            end
                            else if(S_length==2 && S_line[15:8]=="V" && S_line[7:0]>="0" && S_line[7:0]<="4") O_volume<=S_line[2:0];
                            else if(S_valid_time) begin O_interval<=S_seconds[5:0]; S_second<=0; S_elapsed<=0; end
                            else S_reply<=2;
                        end
                    end else if(!S_newline) begin
                        if(S_length==3) S_bad<=1;
                        else begin S_line<={S_line[15:0],I_rx_data}; S_length<=S_length+1'b1; end
                    end
                end
            end
        end
    end
endmodule
