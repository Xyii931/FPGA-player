// One held UI snapshot: small metadata mailbox plus a 360-byte dual-clock RAM.
// I_serial changes atomically with every replacement of the complete title bus.
// Capture, copy, validate, then publish; a changed serial discards the whole copy.
module osd_title_snapshot (
    input wire I_host_clk,I_font_clk,I_async_reset,I_boundary,I_release,
    input wire [589:0] I_state,
    input wire [2879:0] I_titles,
    input wire [31:0] I_serial,
    output wire [589:0] O_state,
    output wire O_state_valid,
    input wire I_title_read,
    input wire [3:0] I_title_line,
    input wire [5:0] I_title_address,
    output wire [7:0] O_title_data
);
    localparam [2:0] CAPTURE=0,COPY=1,CHECK=2,OFFER=3,RETIRE=4,LOAD=5;
    reg [2:0] S_state;
    reg [3:0] S_line;
    reg [5:0] S_byte;
    reg [8:0] S_write_address;
    reg [7:0] S_titles[0:359];
    reg [7:0] S_read_q;
    reg [319:0] S_shift;
    reg S_read_valid;
    wire S_host_reset,S_font_reset,S_capture_ready;
    wire [621:0] S_host_state,S_font_state;
    wire S_discard=I_serial!=S_host_state[621:590];
    wire [8:0] S_read_address={5'd0,I_title_line}*9'd40+{3'd0,I_title_address};
    reg [319:0] C_title;
    reset_sync u_host_reset(.I_clk(I_host_clk),.I_async_reset(I_async_reset),.O_reset(S_host_reset));
    reset_sync u_font_reset(.I_clk(I_font_clk),.I_async_reset(I_async_reset),.O_reset(S_font_reset));
    video_ui_cdc #(.WIDTH(622),.HOLD_PAYLOAD(1),.MANUAL_CAPTURE(1)) u_state (
        .I_host_clk(I_host_clk),.I_video_clk(I_font_clk),.I_async_reset(I_async_reset),
        .I_frame_start(I_boundary),.I_release(I_release),
        .I_capture_valid(S_state==CAPTURE),.I_publish_valid(S_state==OFFER),
        .I_discard_valid(S_state==CHECK && S_discard),
        .O_capture_ready(S_capture_ready),.O_host_state(S_host_state),
        .I_state({I_serial,I_state}),.O_state(S_font_state),.O_state_valid(O_state_valid));
    assign O_state=S_font_state[589:0];
    // Return the RAM value one font cycle after the request; invalid requests
    // return zero without relying on out-of-range or cross-port collision data.
    assign O_title_data=S_read_valid && O_state_valid ? S_read_q : 8'd0;
    always @* begin
        C_title=0;
        case(S_line)
            0:C_title=I_titles[0+:320];
            1:C_title=I_titles[320+:320];
            2:C_title=I_titles[640+:320];
            3:C_title=I_titles[960+:320];
            4:C_title=I_titles[1280+:320];
            5:C_title=I_titles[1600+:320];
            6:C_title=I_titles[1920+:320];
            7:C_title=I_titles[2240+:320];
            8:C_title=I_titles[2560+:320];
            default:begin end
        endcase
    end
    always @(posedge I_host_clk) begin
        if(!S_host_reset && S_state==COPY) S_titles[S_write_address]<=S_shift[319:312];
    end
    always @(posedge I_font_clk) begin
        if(!S_font_reset && I_title_read && O_state_valid)
            S_read_q<=S_titles[S_read_address<360 ? S_read_address : 9'd0];
    end
    always @(posedge I_font_clk or posedge S_font_reset) begin
        if(S_font_reset) S_read_valid<=0;
        else S_read_valid<=I_title_read && O_state_valid && I_title_line<9 && I_title_address<40;
    end
    always @(posedge I_host_clk or posedge S_host_reset) begin
        if(S_host_reset) begin S_state<=CAPTURE; S_line<=0; S_byte<=0; S_write_address<=0; S_shift<=0; end
        else case(S_state)
            CAPTURE:if(S_capture_ready) begin S_line<=0; S_byte<=0; S_write_address<=0; S_state<=LOAD; end
            LOAD:begin S_shift<=C_title; S_state<=COPY; end
            COPY:begin
                S_shift<={S_shift[311:0],8'd0};
                S_write_address<=S_write_address+9'd1;
                if(S_byte==39) begin
                    S_byte<=0;
                    if(S_line==8) S_state<=CHECK;
                    else begin S_line<=S_line+4'd1; S_state<=LOAD; end
                end else S_byte<=S_byte+6'd1;
            end
            CHECK:S_state<=S_discard ? CAPTURE : OFFER;
            OFFER:S_state<=RETIRE;
            RETIRE:if(S_capture_ready) S_state<=CAPTURE;
            default:S_state<=CAPTURE;
        endcase
    end
endmodule
