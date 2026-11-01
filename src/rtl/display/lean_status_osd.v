// One built-in ASCII status row. All inputs are VIDEO-domain coherent snapshots.
module lean_status_osd (
    input wire I_de,I_valid,
    input wire [15:0] I_x,I_y,
    input wire [23:0] I_rgb,
    input wire [3:0] I_current,I_error,
    input wire [4:0] I_count,
    input wire I_auto,I_mute,I_busy,
    input wire [1:0] I_rotation,
    input wire [2:0] I_volume,
    input wire [7:0] I_dbg_type,
    output wire [23:0] O_rgb
);
    reg [7:0] C_char;
    wire [7:0] S_bits;
    wire [4:0] S_number={1'b0,I_current}+5'd1;
    function [7:0] hex_digit;
        input [3:0] digit;
        begin hex_digit=digit<10 ? 8'd48+digit : 8'd55+digit; end
    endfunction
    always @* begin
        C_char=" ";
        case(I_x[8:3])
            0:C_char="I"; 1:C_char="M"; 2:C_char="G";
            4:C_char=hex_digit({3'd0,S_number[4]}); 5:C_char=hex_digit(S_number[3:0]);
            6:C_char="/"; 7:C_char=hex_digit({3'd0,I_count[4]}); 8:C_char=hex_digit(I_count[3:0]);
            10:C_char="A"; 11:C_char=hex_digit({3'd0,I_auto});
            13:C_char="R"; 14:C_char=hex_digit({2'd0,I_rotation});
            16:C_char=hex_digit(I_dbg_type[7:4]); 17:C_char=hex_digit(I_dbg_type[3:0]);
            19:C_char="M"; 20:C_char=hex_digit({3'd0,I_mute});
            22:C_char="B"; 23:C_char=hex_digit({3'd0,I_busy});
            25:C_char="E"; 26:C_char=hex_digit(I_error);
            default:begin end
        endcase
    end
    ascii_font8x16 u_font(.I_char(C_char),.I_row(I_y[3:0]),.O_bits(S_bits));
    assign O_rgb=I_de && I_valid && I_y<16 && I_x<216 ?
        (S_bits[7-I_x[2:0]] ? 24'hffffff : 24'h101820) : I_rgb;
endmodule


