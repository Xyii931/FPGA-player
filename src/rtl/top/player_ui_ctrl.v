// Single host-domain owner for board/menu/UART runtime settings.
// Feature mask prevents accepting a setting whose actual consumer is not wired.
module player_ui_ctrl #(
    parameter [14:0] FEATURE_MASK=15'h7fff
) (
    input wire I_clk,I_reset,
    input wire [3:0] I_key_release,I_switch,I_switch_changed,
    input wire I_switch_initialized,I_active,I_player_busy,I_fault,I_session_ready,I_session_busy,
    input wire [6:0] I_count,
    input wire [5:0] I_current_index,
    input wire [1:0] I_effective_order,
    input wire I_effective_order_valid,
    input wire I_settings_initialized,I_restore_valid,I_restore_found,
    output wire O_restore_ready,
    input wire [239:0] I_restore_config,
    input wire [3:0] I_restore_override,
    output reg O_save_valid,
    input wire I_save_ready,I_save_done_valid,
    output wire O_save_done_ready,
    input wire [3:0] I_save_error,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [4:0] I_request_op,
    input wire [3:0] I_request_key,
    input wire [15:0] I_request_value,
    input wire [5:0] I_request_text_length,
    input wire [319:0] I_request_text,
    output reg O_alert,O_recovery,
    output reg [5:0] O_alert_length,
    output reg [319:0] O_alert_text,
    output reg O_result_valid,
    input wire I_result_ready,
    output reg [3:0] O_result_error,
    output reg O_result_pending,
    output reg [15:0] O_result_base,O_result_effective,
    output wire [239:0] O_config,
    output reg [2:0] O_default_override,
    output reg O_order_override,
    output wire O_auto,O_mute,
    output reg O_pause,O_next,O_prev,O_goto,O_reload,O_rescan,
    output reg [5:0] O_goto_index,
    output reg O_menu,O_menu_root,O_menu_edit,O_menu_confirm,
    output reg [2:0] O_menu_group,
    output reg [3:0] O_menu_row,
    output wire [3:0] O_menu_key,
    output wire [15:0] O_menu_value,
    output reg O_board_interrupt,O_selftest,
    output reg [3:0] O_ui_error
);
    localparam [4:0] NEXT=0,PREV=1,PLAY=2,PLAY_INDEX=3,PAUSE=4,RESUME=5,
        SET=6,GET=7,DEFAULT=8,SCAN=9,RELOAD=10,MODE=11,SAVE=12,ALERT=13,ALERT_OFF=14,RECOVER=15;
    reg [15:0] S_config[0:14];
    wire [239:0] S_menu_steps;
    reg S_switch_seen;
    reg [3:0] S_switch_pending;
    reg S_redraw_pending,S_redraw_active,S_redraw_seen;
    reg S_restore_seen,S_saving,S_save_uart;
    reg [2:0] S_board_quiet;
    reg [26:0] S_alert_clock;
    reg [9:0] S_alert_seconds;
    function valid_alert_text;
        input [319:0] text;
        input [5:0] length;
        integer i;
        reg lead,valid;
        reg [7:0] value;
        begin
            lead=0; valid=length!=0 && length<=40;
            // Console text is right-aligned. Walk fixed byte lanes from the
            // first declared byte to the last, without forty variable shifters.
            for(i=39;i>=0;i=i-1) if(i<length) begin
                value=text[i*8+:8];
                if(lead) begin
                    if(value<8'ha1 || value>8'hfe) valid=0;
                    lead=0;
                end else if(value>=8'ha1 && value<=8'hfe) lead=1;
                else if(value<8'h20 || value>8'h7e) valid=0;
            end
            valid_alert_text=valid && !lead;
        end
    endfunction
    wire S_board_event=|I_key_release || |I_switch_changed || |S_switch_pending ||
        (I_switch_initialized && !S_switch_seen);
    wire S_request=I_request_valid && O_request_ready;
    assign O_request_ready=!I_reset && I_settings_initialized && !S_saving && !O_result_valid &&
        !S_board_event && S_board_quiet==7 && !(I_restore_valid && O_restore_ready);
    assign O_restore_ready=!I_reset && !S_restore_seen && !S_saving;
    assign O_save_done_ready=!I_reset && S_saving && !O_save_valid;
    assign O_auto=I_settings_initialized && !O_alert && S_config[0][0] && S_config[5]!=4 && !S_redraw_pending && !S_redraw_active;
    assign O_mute=S_config[10][0] || I_switch[1];
    genvar g;
    generate for(g=0;g<15;g=g+1) begin:g_config
        assign O_config[g*16+:16]=S_config[g];
        // Each setting has constant bounds and stride. Step before selecting
        // the menu entry, so row decode does not precede variable arithmetic.
        assign S_menu_steps[g*16+:16]=step_value(g,S_config[g],I_key_release[1]);
    end endgenerate
    function [15:0] default_value;
        input [3:0] key;
        begin case(key)
            0,12:default_value=1;
            1:default_value=10;
            3:default_value=400;
            9:default_value=12;
            14:default_value=8;
            default:default_value=0;
        endcase end
    endfunction
    function valid_value;
        input [3:0] key;
        input [15:0] value;
        reg signed [15:0] number;
        reg [8:0] offset_magnitude;
        begin
            number=value;
            // The range test below admits only +/-500. Use nine unsigned
            // bits for divisibility, avoiding a sign-extended 32-bit remainder.
            offset_magnitude=number[15] ? -number : number;
            case(key)
                0,7,10,12:valid_value=value<=1;
                1:valid_value=value>=1 && value<=600;
                2:valid_value=value<=7;
                3:valid_value=value==200 || value==400 || value==600 || value==1000;
                4:valid_value=value<=2;
                5:valid_value=value<=4;
                6:valid_value=value<=3;
                8,13:valid_value=number>=-4 && number<=4;
                9,14:valid_value=value<=16;
                11:valid_value=number>=-500 && number<=500 && offset_magnitude%9'd10==0;
                default:valid_value=0;
            endcase
        end
    endfunction
    function [3:0] menu_key;
        input [2:0] group;
        input [3:0] row;
        begin
            menu_key=15;
            case(group)
                0:case(row) 0:menu_key=0; 1:menu_key=1; 2:menu_key=2; 3:menu_key=3; 4:menu_key=4; default:begin end endcase
                1:case(row) 0:menu_key=5; 1:menu_key=6; 2:menu_key=7; 3:menu_key=8; 4:menu_key=13; 5:menu_key=14; default:begin end endcase
                2:case(row) 0:menu_key=9; 1:menu_key=10; 2:menu_key=11; default:begin end endcase
                3:if(row==0) menu_key=12;
                default:begin end
            endcase
        end
    endfunction
    function [3:0] last_row;
        input [2:0] group;
        begin case(group) 0,1,3:last_row=5; 2:last_row=2; default:last_row=1; endcase end
    endfunction
    function [15:0] step_value;
        input [3:0] key;
        input [15:0] value;
        input increment;
        reg signed [15:0] number,minimum,maximum,step;
        begin
            number=value; minimum=0; maximum=1; step=1;
            case(key)
                1:begin minimum=1; maximum=600; end
                2:maximum=7;
                3:begin
                    minimum=200; maximum=1000; step=200;
                    if(increment && number==600) step=400;
                    if(!increment && number==1000) step=400;
                end
                4:maximum=2;
                5:maximum=4;
                6:maximum=3;
                8,13:begin minimum=-4; maximum=4; end
                9,14:maximum=16;
                11:begin minimum=-500; maximum=500; step=10; end
                default:begin end
            endcase
            step_value=increment ? (number>=maximum ? minimum : number+step) :
                (number<=minimum ? maximum : number-step);
        end
    endfunction
    wire [3:0] S_menu_key=menu_key(O_menu_group,O_menu_row);
    assign O_menu_key=S_menu_key;
    assign O_menu_value=S_menu_key<15 ? S_config[S_menu_key] : 16'd0;
    task write_config;
        input [3:0] key;
        input [15:0] value;
        begin
            // SET validates before this call. Other callers use constants,
            // switches or step_value on the validated configuration bank.
            // Revalidating here duplicates arithmetic and puts the complete
            // menu step calculation in series with the range checker.
            // synthesis translate_off
            if(key<15 && !valid_value(key,value)) begin
                $display("FAIL: player_ui_ctrl write_config received invalid value"); $stop;
            end
            // synthesis translate_on
            if(key<15 && FEATURE_MASK[key]) begin
                S_config[key]<=value;
                case(key)
                    1:O_default_override[0]<=1;
                    2:O_default_override[1]<=1;
                    3:O_default_override[2]<=1;
                    4:O_order_override<=1;
                    default:begin end
                endcase
                // Actual background redraw keeps the old front frame until commit.
                if((key==5 || key==6 || key==7) && S_config[key]!=value && I_active) S_redraw_pending<=1;
            end else O_ui_error<=key>=15 ? 4'd2 : 4'd3;
        end
    endtask
    integer S_i;
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            for(S_i=0;S_i<15;S_i=S_i+1) S_config[S_i]<=default_value(S_i);
            S_switch_seen<=0; S_switch_pending<=0;
            O_default_override<=0; O_order_override<=0;
            S_redraw_pending<=0; S_redraw_active<=0; S_redraw_seen<=0; S_board_quiet<=0;
            S_restore_seen<=0; S_saving<=0; S_save_uart<=0; O_save_valid<=0;
            O_alert<=0; O_recovery<=0; O_alert_length<=0; O_alert_text<=0; S_alert_clock<=0; S_alert_seconds<=0;
            O_pause<=0; O_next<=0; O_prev<=0; O_goto<=0; O_goto_index<=0; O_reload<=0; O_rescan<=0;
            O_menu<=0; O_menu_root<=1; O_menu_edit<=0; O_menu_confirm<=0; O_menu_group<=0; O_menu_row<=0;
            O_result_valid<=0; O_result_error<=0; O_result_pending<=0; O_result_base<=0; O_result_effective<=0;
            O_board_interrupt<=0; O_selftest<=0; O_ui_error<=0;
        end else begin
            if(O_alert) begin
                if(S_alert_clock==27'd124999999) begin
                    S_alert_clock<=0;
                    if(S_alert_seconds<=1) begin O_alert<=0; S_alert_seconds<=0; end
                    else S_alert_seconds<=S_alert_seconds-1'b1;
                end else S_alert_clock<=S_alert_clock+1'b1;
            end
            O_next<=0; O_prev<=0; O_goto<=0; O_reload<=0; O_rescan<=0; O_board_interrupt<=0; O_selftest<=0;
            if(O_save_valid && I_save_ready) O_save_valid<=0;
            if(S_board_event || O_board_interrupt) S_board_quiet<=0;
            else if(S_board_quiet!=7) S_board_quiet<=S_board_quiet+1'b1;
            if(S_redraw_active && I_player_busy) S_redraw_seen<=1;
            if(S_redraw_active && ((S_redraw_seen && !I_player_busy) || !I_session_ready || I_fault)) S_redraw_active<=0;
            if(I_settings_initialized && S_redraw_pending && !S_redraw_active && !I_player_busy && I_active &&
                I_session_ready && !I_fault && !S_board_event && !I_request_valid && S_board_quiet==7) begin
                O_goto<=1; O_goto_index<=I_current_index; S_redraw_pending<=0;
                S_redraw_active<=1; S_redraw_seen<=0;
            end
            if(O_result_valid && I_result_ready) O_result_valid<=0;
            S_switch_pending<=S_switch_pending | I_switch_changed;
            if(I_settings_initialized && I_switch_initialized && !S_switch_seen) begin
                S_switch_seen<=1; S_switch_pending<=4'b0101;
            end
            // Board events have priority; each pending switch is handled once.
            if(I_restore_valid && O_restore_ready) begin
                S_restore_seen<=1;
                if(I_restore_found) begin
                    for(S_i=0;S_i<15;S_i=S_i+1) begin
                        if(valid_value(S_i,I_restore_config[S_i*16+:16])) S_config[S_i]<=I_restore_config[S_i*16+:16];
                        else begin S_config[S_i]<=default_value(S_i); O_ui_error<=2; end
                    end
                    O_default_override<=I_restore_override[2:0]; O_order_override<=I_restore_override[3];
                end
            end else if(I_settings_initialized) begin
            if(|I_key_release) begin
                O_ui_error<=0;
                if(I_key_release[3]) begin
                    O_menu_confirm<=0;
                    if(!O_menu) begin O_menu<=1; O_menu_root<=1; O_menu_edit<=0; end
                    else if(O_menu_edit) O_menu_edit<=0;
                    else if(!O_menu_root) begin O_menu_root<=1; O_menu_row<=0; end
                    else O_menu<=0;
                end else if(!O_menu) begin
                    O_prev<=I_key_release[0]; O_next<=I_key_release[1];
                    O_board_interrupt<=I_key_release[0] || I_key_release[1];
                    if(I_key_release[2]) begin
                        if(S_config[5]==4) begin write_config(5,0); O_pause<=0; O_board_interrupt<=1; end
                        else S_config[0]<=!S_config[0][0];
                    end
                end else if(O_menu_root) begin
                    if(I_key_release[0]) O_menu_group<=O_menu_group==0 ? 3'd4 : O_menu_group-1'b1;
                    else if(I_key_release[1]) O_menu_group<=O_menu_group==4 ? 3'd0 : O_menu_group+1'b1;
                    else if(I_key_release[2]) begin O_menu_root<=0; O_menu_row<=0; end
                end else if(O_menu_edit) begin
                    if(I_key_release[2]) O_menu_edit<=0;
                    else if(I_key_release[0] || I_key_release[1]) begin
                        // Select a register's write enable, not a shared 240-bit
                        // stepped-data mux followed by a second write decoder.
                        for(S_i=0;S_i<15;S_i=S_i+1)
                            if(S_menu_key==S_i && FEATURE_MASK[S_i]) begin
                                S_config[S_i]<=S_menu_steps[S_i*16+:16];
                                case(S_i)
                                    1:O_default_override[0]<=1;
                                    2:O_default_override[1]<=1;
                                    3:O_default_override[2]<=1;
                                    4:O_order_override<=1;
                                    default:begin end
                                endcase
                                if((S_i==5 || S_i==6 || S_i==7) && I_active &&
                                    S_config[S_i]!=S_menu_steps[S_i*16+:16]) S_redraw_pending<=1;
                            end
                        if(S_menu_key>=15) O_ui_error<=2;
                        else if(!FEATURE_MASK[S_menu_key]) O_ui_error<=3;
                        if(S_menu_key>=5 && S_menu_key<=7) O_board_interrupt<=1;
                    end
                end else if(I_key_release[0] || I_key_release[1]) begin
                    O_menu_confirm<=0;
                    O_menu_row<=I_key_release[1] ? (O_menu_row==last_row(O_menu_group) ? 4'd0 : O_menu_row+1'b1) :
                        (O_menu_row==0 ? last_row(O_menu_group) : O_menu_row-1'b1);
                end else if(I_key_release[2]) begin
                    if(S_menu_key<15) begin
                        if(FEATURE_MASK[S_menu_key]) O_menu_edit<=1; else O_ui_error<=3;
                    end else if(O_menu_group==0 && O_menu_row==5) O_pause<=!O_pause;
                    else if(O_menu_group==3) case(O_menu_row)
                        1:if(!I_session_busy && !I_player_busy && I_session_ready) begin O_rescan<=1; O_board_interrupt<=1; end else O_ui_error<=4;
                        2:begin O_recovery<=0; O_reload<=1; O_board_interrupt<=1; end
                        3:if(!S_saving && I_save_ready) begin O_save_valid<=1; S_saving<=1; S_save_uart<=0; end
                            else O_ui_error<=4;
                        4:if(O_menu_confirm) begin
                            for(S_i=0;S_i<15;S_i=S_i+1) S_config[S_i]<=default_value(S_i);
                            O_default_override<=3'b111; O_order_override<=1;
                            O_menu_confirm<=0; O_pause<=0;
                            if(I_active && (S_config[5]!=0 || S_config[6]!=0 || S_config[7]!=0)) S_redraw_pending<=1;
                            O_board_interrupt<=1;
                        end else O_menu_confirm<=1;
                        5:O_selftest<=1;
                        default:begin end
                    endcase
                    else if(O_menu_group==4) O_selftest<=1;
                end
            end else if(S_switch_seen && S_switch_pending[0]) begin
                S_config[0]<=I_switch[0]; S_switch_pending[0]<=0;
            end else if(S_switch_seen && S_switch_pending[2]) begin
                if(FEATURE_MASK[5]) write_config(5,I_switch[2] ? 16'd1 : 16'd0);
                else if(I_switch[2]) O_ui_error<=3;
                S_switch_pending[2]<=0;
            end else if(|S_switch_pending) S_switch_pending<=I_switch_changed;
            end
            // Request admission already excludes board/switch handling and
            // restore acceptance. Do not repeat that priority chain in every
            // UART-controlled register's data/enable path.
            if(S_request) begin
                O_result_valid<=1; O_result_error<=0; O_result_pending<=0; O_result_base<=0; O_result_effective<=0;
                case(I_request_op)
                    NEXT,PREV,PLAY_INDEX:begin
                        if(!I_session_ready || !I_active || I_count==0) O_result_error<=5;
                        else if(O_alert || I_player_busy || I_fault || I_switch[3] || S_redraw_pending || S_redraw_active) O_result_error<=4;
                        else if(I_request_op==PLAY_INDEX && (I_request_value>=I_count || I_request_value>=64)) O_result_error<=2;
                        else begin
                            O_pause<=0; O_result_pending<=1;
                            if(I_request_op==NEXT) O_next<=1;
                            else if(I_request_op==PREV) O_prev<=1;
                            else begin O_goto<=1; O_goto_index<=I_request_value[5:0]; end
                        end
                    end
                    PLAY,RESUME:O_pause<=0;
                    PAUSE:O_pause<=1;
                    SET:if(I_request_key>=15 || !valid_value(I_request_key,I_request_value)) O_result_error<=2;
                        else if(!FEATURE_MASK[I_request_key]) O_result_error<=3;
                        else begin write_config(I_request_key,I_request_value); O_result_base<=I_request_value;
                            O_result_effective<=I_request_key==10 ? {15'd0,(I_request_value[0] || I_switch[1])} : I_request_value; end
                    GET:if(I_request_key>=15) O_result_error<=2;
                        else begin O_result_base<=I_request_key==6 ? S_config[6]*16'd90 : S_config[I_request_key];
                            O_result_effective<=I_request_key==10 ? {15'd0,O_mute} :
                                I_request_key==6 ? S_config[6]*16'd90 :
                                I_request_key==4 && I_effective_order_valid ? {14'd0,I_effective_order} : S_config[I_request_key]; end
                    DEFAULT:begin
                        for(S_i=0;S_i<15;S_i=S_i+1) S_config[S_i]<=default_value(S_i);
                        O_default_override<=3'b111; O_order_override<=1;
                        O_pause<=0;
                        if(I_active && (S_config[5]!=0 || S_config[6]!=0 || S_config[7]!=0)) S_redraw_pending<=1;
                    end
                    SCAN:if(I_player_busy || I_session_busy || !I_session_ready || I_fault || S_redraw_pending || S_redraw_active) O_result_error<=4;
                        else begin O_rescan<=1; O_result_pending<=1; end
                    RELOAD:if(O_recovery) begin O_recovery<=0; O_reload<=1; end
                        else if(!I_session_ready && !I_session_busy) O_result_error<=5;
                        else if(I_fault) O_result_error<=6;
                        else begin O_reload<=1; O_result_pending<=1; end
                    MODE:case(I_request_value)
                        0:if(I_switch[3]) O_result_error<=4;
                            else begin O_recovery<=0; O_menu<=0; O_menu_edit<=0; O_pause<=0; write_config(5,0); end
                        1:if(I_switch[3]) O_result_error<=4;
                            else begin O_menu<=0; O_menu_edit<=0; O_pause<=0; write_config(5,4); end
                        2:begin O_menu<=1; O_menu_root<=1; O_menu_edit<=0; end
                        3:O_selftest<=1;
                        default:O_result_error<=3;
                    endcase
                    SAVE:if(!I_save_ready) O_result_error<=4;
                        else begin O_save_valid<=1; S_saving<=1; S_save_uart<=1; O_result_valid<=0; end
                    ALERT:if(I_request_value==0 || I_request_value>600 ||
                        !valid_alert_text(I_request_text,I_request_text_length)) O_result_error<=2;
                        else begin
                            O_alert<=1; O_alert_length<=I_request_text_length;
                            O_alert_text<=I_request_text << ((40-I_request_text_length)*8);
                            S_alert_seconds<=I_request_value[9:0]; S_alert_clock<=0;
                            O_menu<=0; O_menu_edit<=0;
                        end
                    RECOVER:if(I_switch[3]) O_result_error<=4;
                        else begin O_recovery<=1; O_menu<=0; O_menu_edit<=0; end
                    ALERT_OFF:begin O_alert<=0; S_alert_seconds<=0; S_alert_clock<=0; end
                    default:O_result_error<=1;
                endcase
            end
            if(I_save_done_valid && O_save_done_ready) begin
                S_saving<=0; O_ui_error<=I_save_error==0 ? 4'd0 : 4'd6;
                if(S_save_uart) begin
                    O_result_valid<=1; O_result_error<=I_save_error==0 ? 4'd0 : 4'd6; O_result_pending<=0;
                    O_result_base<=0; O_result_effective<=0;
                end
            end
        end
    end
endmodule
