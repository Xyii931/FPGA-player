// Basic playback menu; additional display/system configuration belongs above it.
// All events and levels are HOST-domain. SW1 is an event, SW2 a hard override.
module player_board_ctrl (
    input wire I_clk,I_reset,
    input wire [3:0] I_key_release,I_switch,I_switch_changed,
    input wire I_switch_initialized,
    output reg O_auto,O_pause,O_mute,
    output reg O_next,O_prev,O_reload,O_rescan,
    output reg O_menu,
    output reg [2:0] O_menu_row
);
    reg S_initialized;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_initialized<=0; O_auto<=1; O_pause<=0; O_mute<=0;
            O_next<=0; O_prev<=0; O_reload<=0; O_rescan<=0; O_menu<=0; O_menu_row<=0;
        end else begin
            O_next<=0; O_prev<=0; O_reload<=0; O_rescan<=0;
            if(I_switch_initialized) begin
                if(!S_initialized || I_switch_changed[0]) O_auto<=I_switch[0];
                S_initialized<=1;
            end
            if(I_key_release[3]) O_menu<=!O_menu;
            if(O_menu) begin
                if(I_key_release[0]) O_menu_row<=O_menu_row==0 ? 3'd4 : O_menu_row-1'b1;
                else if(I_key_release[1]) O_menu_row<=O_menu_row==4 ? 3'd0 : O_menu_row+1'b1;
                else if(I_key_release[2]) case(O_menu_row)
                    0:O_auto<=!O_auto;
                    1:O_pause<=!O_pause;
                    2:O_mute<=!O_mute;
                    3:begin O_rescan<=1; O_menu<=0; end
                    4:begin O_reload<=1; O_menu<=0; end
                    default:O_menu_row<=0;
                endcase
            end else begin
                O_prev<=I_key_release[0]; O_next<=I_key_release[1];
                if(I_key_release[2]) O_auto<=!O_auto;
            end
        end
    end
endmodule
