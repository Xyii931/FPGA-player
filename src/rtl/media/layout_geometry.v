// Nominal fit rectangles inside one 640x480 composed framebuffer.
// No pixels, memory or filesystem ownership here.
module layout_geometry (
    input wire [2:0] I_layout,
    input wire [3:0] I_part,
    output reg [15:0] O_x,O_y,O_width,O_height
);
    always @* begin
        O_x=0; O_y=0; O_width=640; O_height=480;
        case(I_layout)
            1:if(I_part!=0) begin O_x=462; O_y=18; O_width=160; O_height=120; end
            2:begin O_x=I_part[0] ? 16'd320 : 16'd0; O_width=320; end
            3:begin
                O_x=I_part[0] ? 16'd320 : 16'd0;
                O_y=I_part[1] ? 16'd240 : 16'd0; O_width=320; O_height=240;
            end
            4:begin
                case(I_part)
                    1,4,7:O_x=213;
                    2,5,8:O_x=426;
                    default:O_x=0;
                endcase
                if(I_part>=6) O_y=320; else if(I_part>=3) O_y=160;
                O_width=213; O_height=144;
            end
            default:begin end
        endcase
    end
endmodule
