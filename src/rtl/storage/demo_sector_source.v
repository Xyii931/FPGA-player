// Real DEM1 Flash bytes -> verified assets -> internal read-only FAT32 sectors.
// No synthetic completion: every Flash transaction drains its actual terminal.
module demo_sector_source #(
    parameter integer RECOVERY=0,
    parameter integer RECOVERY_SECTORS=131072
) (
    input wire I_clk,I_reset,
    input wire I_recovery_enable,I_raw_card_ready,
    output wire O_raw_request_valid,
    input wire I_raw_request_ready,
    output wire [31:0] O_raw_lba,
    output wire [15:0] O_raw_tag,
    input wire I_raw_byte_valid,
    output wire O_raw_byte_ready,
    input wire [7:0] I_raw_byte_data,
    input wire I_raw_sector_last,I_raw_request_last,
    input wire [15:0] I_raw_byte_tag,
    input wire I_raw_done_valid,
    output wire O_raw_done_ready,
    input wire [3:0] I_raw_done_error,
    input wire [15:0] I_raw_done_tag,
    output wire O_ready,
    output reg [3:0] O_error,
    output wire O_flash_valid,
    input wire I_flash_ready,
    output wire [23:0] O_flash_address,
    output reg [9:0] O_flash_length,
    input wire I_flash_byte_valid,
    output wire O_flash_byte_ready,
    input wire [7:0] I_flash_byte_data,
    input wire I_flash_byte_last,I_flash_done_valid,
    output wire O_flash_done_ready,
    input wire [3:0] I_flash_error,
    input wire I_request_valid,
    output wire O_request_ready,
    input wire [31:0] I_lba,
    input wire [7:0] I_count,
    input wire [1:0] I_context,
    input wire [15:0] I_tag,
    output wire O_byte_valid,
    input wire I_byte_ready,
    output reg [7:0] O_byte_data,
    output wire O_sector_last,O_request_last,
    output reg [1:0] O_byte_context,O_done_context,O_cancel_done_context,
    output reg [15:0] O_byte_tag,O_done_tag,O_cancel_done_tag,
    output wire O_done_valid,
    input wire I_done_ready,
    output reg [3:0] O_done_error,
    input wire I_cancel_valid,
    output wire O_cancel_ready,
    input wire [1:0] I_cancel_context,
    input wire [15:0] I_cancel_tag,
    output reg O_cancel_done_valid,
    input wire I_cancel_done_ready,
    output wire O_quiescent
);
    localparam [4:0] HEADER_REQ=0,HEADER_WAIT=1,HEADER_CHECK=2,TABLE_REQ=3,TABLE_WAIT=4,
        TABLE_BYTES=5,TABLE_SAVE=6,COMPARE=7,TABLE_END=8,DATA_REQ=9,DATA_WAIT=10,
        DATA_CRC=11,DATA_END=12,LIST_FIND=13,LIST_PAIR=14,LIST_WRITE=15,ONLINE=16,FAILED=17,RAW_IDLE=18,RAW_REQ=19,RAW_WAIT=20,RAW_CHECK=21,RAW_ACCEPT=22,RAW_NEXT=23;
    localparam [2:0] Q_IDLE=0,Q_MAP=1,Q_FLASH=2,Q_WAIT=3,Q_STREAM=4,Q_DONE=5;
    reg [4:0] S_boot;
    reg [2:0] S_q;
    reg S_verified,S_fetch_start,S_fetch_done,S_fetch_bad,S_fetch_active,S_fetch_offer;
    reg [9:0] S_fetch_count;
    reg [31:0] S_fetch_address,S_raw_scan,S_raw_start,S_raw_size,S_raw_next;
    reg [15:0] S_raw_tag;
    reg S_raw_verifying,S_raw_lost;
    wire S_backend_byte_valid=RECOVERY!=0 ? I_raw_byte_valid : I_flash_byte_valid;
    wire [7:0] S_backend_byte=RECOVERY!=0 ? I_raw_byte_data : I_flash_byte_data;
    wire S_backend_last=RECOVERY!=0 ? I_raw_request_last : I_flash_byte_last;
    wire S_backend_done=RECOVERY!=0 ? I_raw_done_valid : I_flash_done_valid;
    wire [3:0] S_backend_error=RECOVERY!=0 ? I_raw_done_error : I_flash_error;
    wire S_backend_ready=RECOVERY!=0 ? I_raw_request_ready : I_flash_ready;
    assign O_flash_address=S_fetch_address[23:0];
    assign O_raw_request_valid=RECOVERY!=0 && !I_reset && S_fetch_offer;
    assign O_raw_lba=S_fetch_address>>9;
    assign O_raw_tag=S_raw_tag;
    assign O_raw_byte_ready=RECOVERY!=0 && !I_reset && S_fetch_active;
    assign O_raw_done_ready=RECOVERY!=0 && !I_reset && S_fetch_active;
    reg [7:0] S_buffer[0:511];
    reg [31:0] S_offsets[0:127],S_sizes[0:127],S_crcs[0:127];
    reg [15:0] S_types[0:127],S_ids[0:127];
    reg [7:0] S_playlist[0:4095];
    reg [159:0] S_record;
    reg [7:0] S_entries,S_entry,S_compare;
    reg [31:0] S_table_crc,S_expected_table_crc,S_crc,S_data_position;
    reg [9:0] S_position;
    reg [6:0] S_images,S_list_slot;
    reg [7:0] S_list_image,S_list_audio;
    reg [5:0] S_list_byte;
    reg S_list_has_audio;
    reg [31:0] S_lba;
    reg [7:0] S_sectors;
    reg [8:0] S_byte;
    reg [9:0] S_payload;
    reg S_cancel,S_is_flash,S_cancel_pending;
    reg [31:0] S_asset_address;
    wire [31:0] S_cluster=S_lba-32'd32798; // data LBA32800, cluster2
    wire [31:0] S_asset_relative=S_cluster-32'd256;
    wire [7:0] S_asset=S_asset_relative[21:14];
    wire [31:0] S_asset_offset={18'd0,S_asset_relative[13:0]}<<9;
    wire [31:0] S_table_bytes={24'd0,S_entries}*32'd20;
    wire [31:0] S_end=S_offsets[S_entry]+S_sizes[S_entry];
    wire [31:0] S_other_end=S_offsets[S_compare]+S_sizes[S_compare];
    wire S_cancel_match=I_cancel_valid && O_cancel_ready && I_cancel_context==O_byte_context && I_cancel_tag==O_byte_tag;
    function [31:0] crc_byte;
        input [31:0] crc;
        input [7:0] data;
        reg [31:0] value;
        integer k;
        begin
            value=crc^{24'd0,data};
            for(k=0;k<8;k=k+1) value=value[0] ? (value>>1)^32'hedb88320 : value>>1;
            crc_byte=value;
        end
    endfunction
    function [7:0] hex_digit;
        input [3:0] value;
        begin hex_digit=value<10 ? 8'd48+value : 8'd55+value; end
    endfunction
    function [7:0] asset_name;
        input [7:0] entry;
        input [3:0] at;
        input audio;
        begin
            case(at)
                0:asset_name="D";
                1:asset_name=hex_digit(0);
                2:asset_name=hex_digit(entry[7:4]);
                3:asset_name=hex_digit(entry[3:0]);
                4,5,6,7:asset_name=" ";
                8:asset_name=audio ? "W" : RECOVERY!=0 ? "B" : "R";
                9:asset_name=audio ? "A" : RECOVERY!=0 ? "M" : "L";
                10:asset_name=audio ? "V" : RECOVERY!=0 ? "P" : "E";
                default:asset_name=0;
            endcase
        end
    endfunction
    function [7:0] list_byte;
        input [5:0] at;
        input [7:0] image,audio;
        input has_audio;
        begin
            list_byte=8'd32;
            if(at<12) list_byte=96'h5b4954454d5d0a66696c653d >> ((11-at)*8); // [ITEM] LF file=
            else if(at==12) list_byte="/";
            else if(at>=13 && at<=16) list_byte=asset_name(image,at-13,0);
            else if(at==17) list_byte=".";
            else if(at>=18 && at<=20) list_byte=asset_name(image,at-10,0);
            else if(at==21 || at==63) list_byte=10;
            else if(has_audio) begin
                if(at>=22 && at<=27) list_byte=48'h617564696f3d >> ((27-at)*8); // audio=
                else if(at==28) list_byte="/";
                else if(at>=29 && at<=32) list_byte=asset_name(audio,at-29,1);
                else if(at==33) list_byte=".";
                else if(at>=34 && at<=36) list_byte=asset_name(audio,at-26,1);
                else if(at==37) list_byte=10;
            end
        end
    endfunction
    assign O_ready=S_verified && !I_reset && (RECOVERY==0 || (I_raw_card_ready && I_recovery_enable && !S_raw_lost));
    assign O_flash_valid=RECOVERY==0 && !I_reset && S_fetch_offer;
    assign O_flash_byte_ready=RECOVERY==0 && !I_reset && S_fetch_active;
    assign O_flash_done_ready=RECOVERY==0 && !I_reset && S_fetch_active;
    assign O_request_ready=O_ready && S_q==Q_IDLE && !O_cancel_done_valid;
    assign O_byte_valid=!I_reset && S_q==Q_STREAM && !S_cancel;
    assign O_sector_last=S_byte==511;
    assign O_request_last=S_byte==511 && S_sectors==1;
    assign O_done_valid=!I_reset && S_q==Q_DONE;
    assign O_cancel_ready=!I_reset && !O_cancel_done_valid && !S_cancel_pending;
    assign O_quiescent=S_q==Q_IDLE && !O_cancel_done_valid && !S_cancel_pending && !S_fetch_active && !S_fetch_offer && !S_fetch_start;
    // Read engine owns its buffer through terminal. No local cancel resets it.
    always @(posedge I_clk) begin
        if(I_reset) begin S_fetch_offer<=0; S_fetch_active<=0; S_fetch_done<=0; S_fetch_bad<=0; S_fetch_count<=0; S_raw_tag<=0; end
        else begin
            S_fetch_done<=0;
            if(S_fetch_start) begin S_fetch_offer<=1; S_fetch_bad<=0; S_fetch_count<=0; S_raw_tag<=S_raw_tag+1'b1; end
            if(S_fetch_offer && S_backend_ready) begin S_fetch_offer<=0; S_fetch_active<=1; end
            if(S_backend_byte_valid && S_fetch_active) begin
                if(S_fetch_count<512) S_buffer[S_fetch_count[8:0]]<=S_backend_byte;
                else S_fetch_bad<=1;
                S_fetch_count<=S_fetch_count+1'b1;
                if(S_backend_last!=(S_fetch_count+10'd1==O_flash_length)) S_fetch_bad<=1;
                if(RECOVERY!=0 && (I_raw_byte_tag!=S_raw_tag || I_raw_sector_last!=S_backend_last)) S_fetch_bad<=1;
            end
            if(S_backend_done && S_fetch_active) begin
                S_fetch_active<=0; S_fetch_done<=1;
                if(S_backend_error!=0 || S_fetch_count+((S_backend_byte_valid && S_fetch_active) ? 10'd1 : 10'd0)!=O_flash_length ||
                    (RECOVERY!=0 && I_raw_done_tag!=S_raw_tag)) S_fetch_bad<=1;
            end
        end
    end
    task fetch;
        input [31:0] address;
        input [9:0] length;
        begin S_fetch_address<=address; O_flash_length<=length; S_fetch_start<=1; end
    endtask
    task fail;
        input [3:0] error;
        begin O_error<=error; S_boot<=FAILED; S_verified<=0; end
    endtask
    wire [31:0] S_header_magic={S_buffer[3],S_buffer[2],S_buffer[1],S_buffer[0]};
    wire [15:0] S_header_count={S_buffer[7],S_buffer[6]};
    wire [31:0] S_header_table_bytes={S_buffer[11],S_buffer[10],S_buffer[9],S_buffer[8]};
    wire [31:0] S_raw_file_size={S_buffer[5],S_buffer[4],S_buffer[3],S_buffer[2]};
    wire [31:0] S_raw_pixel_offset={S_buffer[13],S_buffer[12],S_buffer[11],S_buffer[10]};
    wire [31:0] S_raw_dib={S_buffer[17],S_buffer[16],S_buffer[15],S_buffer[14]};
    wire [31:0] S_raw_width={S_buffer[21],S_buffer[20],S_buffer[19],S_buffer[18]};
    wire [31:0] S_raw_signed_height={S_buffer[25],S_buffer[24],S_buffer[23],S_buffer[22]};
    wire [31:0] S_raw_height=S_raw_signed_height[31] ? 32'd0-S_raw_signed_height : S_raw_signed_height;
    wire [15:0] S_raw_bpp={S_buffer[29],S_buffer[28]};
    wire [63:0] S_raw_row=(({32'd0,S_raw_width}*(S_raw_bpp==24 ? 64'd3 : 64'd4)+64'd3)>>2)<<2;
    wire [63:0] S_raw_required={32'd0,S_raw_pixel_offset}+S_raw_row*{32'd0,S_raw_height};
    wire S_raw_header_valid={S_buffer[1],S_buffer[0]}==16'h4d42 &&
        (S_raw_dib==40 || S_raw_dib==108 || S_raw_dib==124) &&
        S_raw_width!=0 && S_raw_width<=1920 && S_raw_height!=0 && S_raw_height<=1080 &&
        {S_buffer[27],S_buffer[26]}==1 && (S_raw_bpp==24 || S_raw_bpp==32) &&
        {S_buffer[33],S_buffer[32],S_buffer[31],S_buffer[30]}==0 &&
        S_raw_pixel_offset>=14+S_raw_dib && S_raw_file_size>=S_raw_required &&
        S_raw_file_size<=32'd8388608 &&
        {32'd0,S_raw_file_size}+({32'd0,S_raw_scan}<<9)<=({32'd0,RECOVERY_SECTORS}<<9);
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_boot<=RECOVERY!=0 ? RAW_IDLE : HEADER_REQ; S_q<=Q_IDLE; S_verified<=0; O_error<=0;
            S_raw_scan<=0; S_raw_start<=0; S_raw_size<=0; S_raw_next<=0; S_raw_verifying<=0; S_raw_lost<=0;
            S_fetch_start<=0; S_fetch_address<=0; O_flash_length<=0;
            S_entries<=0; S_entry<=0; S_compare<=0; S_position<=0; S_record<=0;
            S_table_crc<=32'hffffffff; S_expected_table_crc<=0; S_crc<=32'hffffffff; S_data_position<=0;
            S_images<=0; S_list_slot<=0; S_list_image<=0; S_list_audio<=0; S_list_byte<=0; S_list_has_audio<=0;
            S_lba<=0; S_sectors<=0; S_byte<=0; S_payload<=0; S_cancel<=0; S_cancel_pending<=0; S_is_flash<=0; S_asset_address<=0;
            O_byte_context<=0; O_byte_tag<=0; O_done_context<=0; O_done_tag<=0; O_done_error<=0;
            O_cancel_done_valid<=0; O_cancel_done_context<=0; O_cancel_done_tag<=0;
        end else begin
            S_fetch_start<=0;
            if(O_cancel_done_valid && I_cancel_done_ready) O_cancel_done_valid<=0;
            if(I_cancel_valid && O_cancel_ready) begin
                O_cancel_done_context<=I_cancel_context; O_cancel_done_tag<=I_cancel_tag;
                // A held sector terminal already proves backend retirement. A
                // cancel accepted alongside its consumption must also complete.
                if(S_q!=Q_IDLE && S_q!=Q_DONE && S_cancel_match) begin S_cancel<=1; S_cancel_pending<=1; end
                else O_cancel_done_valid<=1;
            end
            if(S_q==Q_DONE && S_cancel_pending) begin O_cancel_done_valid<=1; S_cancel_pending<=0; end
            if(RECOVERY!=0 && !I_raw_card_ready) S_raw_lost<=1;
            case(S_boot)
                HEADER_REQ:begin fetch(24'h100000,10'd16); S_boot<=HEADER_WAIT; end
                HEADER_WAIT:if(S_fetch_done) begin if(S_fetch_bad) fail(1); else S_boot<=HEADER_CHECK; end
                HEADER_CHECK:if(S_header_magic!=32'h314d4544 || {S_buffer[5],S_buffer[4]}!=1 ||
                    S_header_count==0 || S_header_count>128 || S_header_table_bytes!={16'd0,S_header_count}*32'd20) fail(2);
                    else begin
                        S_entries<=S_header_count[7:0]; S_entry<=0; S_table_crc<=32'hffffffff;
                        S_expected_table_crc<={S_buffer[15],S_buffer[14],S_buffer[13],S_buffer[12]}; S_boot<=TABLE_REQ;
                    end
                TABLE_REQ:begin fetch(24'h100010+S_entry*24'd20,10'd20); S_boot<=TABLE_WAIT; end
                TABLE_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) fail(1);
                    else begin S_record<=0; S_position<=0; S_boot<=TABLE_BYTES; end
                end
                TABLE_BYTES:begin
                    S_record[S_position*8+:8]<=S_buffer[S_position];
                    S_table_crc<=crc_byte(S_table_crc,S_buffer[S_position]);
                    if(S_position==19) S_boot<=TABLE_SAVE; else S_position<=S_position+1'b1;
                end
                TABLE_SAVE:if((S_record[15:0]!=1 && S_record[15:0]!=2) || S_record[159:128]!=0 ||
                    S_record[63:32]<32'd16+S_table_bytes || S_record[95:64]==0 ||
                    {1'b0,S_record[63:32]}+{1'b0,S_record[95:64]}>33'h700000) fail(3);
                    else begin
                        S_types[S_entry]<=S_record[15:0]; S_ids[S_entry]<=S_record[31:16];
                        S_offsets[S_entry]<=S_record[63:32]; S_sizes[S_entry]<=S_record[95:64]; S_crcs[S_entry]<=S_record[127:96];
                        S_compare<=0; S_boot<=COMPARE;
                    end
                COMPARE:if(S_compare==S_entry) begin
                    if(S_entry+8'd1==S_entries) S_boot<=TABLE_END;
                    else begin S_entry<=S_entry+1'b1; S_boot<=TABLE_REQ; end
                end else if((S_types[S_entry]==S_types[S_compare] && S_ids[S_entry]==S_ids[S_compare]) ||
                    (S_offsets[S_entry]<S_other_end && S_offsets[S_compare]<S_end)) fail(3);
                    else S_compare<=S_compare+1'b1;
                TABLE_END:if((S_table_crc^32'hffffffff)!=S_expected_table_crc) fail(4);
                    else begin S_entry<=0; S_data_position<=0; S_crc<=32'hffffffff; S_boot<=DATA_REQ; end
                DATA_REQ:begin
                    fetch(24'h100000+S_offsets[S_entry]+S_data_position,
                        S_sizes[S_entry]-S_data_position>=512 ? 10'd512 : S_sizes[S_entry]-S_data_position);
                    S_boot<=DATA_WAIT;
                end
                DATA_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) fail(1); else begin S_position<=0; S_boot<=DATA_CRC; end
                end
                DATA_CRC:begin
                    S_crc<=crc_byte(S_crc,S_buffer[S_position]);
                    if(S_position+10'd1==O_flash_length) begin S_data_position<=S_data_position+O_flash_length; S_boot<=DATA_END; end
                    else S_position<=S_position+1'b1;
                end
                DATA_END:if(S_data_position<S_sizes[S_entry]) S_boot<=DATA_REQ;
                    else if((S_crc^32'hffffffff)!=S_crcs[S_entry]) fail(5);
                    else if(S_entry+8'd1==S_entries) begin S_entry<=0; S_images<=0; S_boot<=LIST_FIND; end
                    else begin S_entry<=S_entry+1'b1; S_data_position<=0; S_crc<=32'hffffffff; S_boot<=DATA_REQ; end
                LIST_FIND:if(S_entry==S_entries) begin
                    if(S_images==0) fail(6); else begin S_verified<=1; S_boot<=ONLINE; end
                end else if(S_types[S_entry]==1) begin
                    if(S_images==64) fail(6);
                    else begin S_list_image<=S_entry; S_list_audio<=0; S_list_has_audio<=0; S_compare<=0; S_boot<=LIST_PAIR; end
                end else begin
                    // Orphan audio is rejected rather than silently ignored.
                    S_compare<=0; S_list_has_audio<=0; S_boot<=LIST_PAIR;
                end
                LIST_PAIR:if(S_compare==S_entries) begin
                    if(S_types[S_entry]==2) begin if(!S_list_has_audio) fail(6); else begin S_entry<=S_entry+1'b1; S_boot<=LIST_FIND; end end
                    else begin S_list_byte<=0; S_list_slot<=S_images; S_boot<=LIST_WRITE; end
                end else begin
                    if(S_types[S_compare]!=S_types[S_entry] && S_ids[S_compare]==S_ids[S_entry]) begin
                        S_list_has_audio<=1; S_list_audio<=S_compare;
                    end
                    S_compare<=S_compare+1'b1;
                end
                LIST_WRITE:begin
                    S_playlist[{S_list_slot[5:0],S_list_byte}]<=list_byte(S_list_byte,S_list_image,S_list_audio,S_list_has_audio);
                    if(S_list_byte==63) begin S_images<=S_images+1'b1; S_entry<=S_entry+1'b1; S_boot<=LIST_FIND; end
                    else S_list_byte<=S_list_byte+1'b1;
                end
                RAW_IDLE:if(I_recovery_enable && I_raw_card_ready && !S_fetch_active && !S_fetch_offer && !S_fetch_start) begin
                    S_raw_scan<=0; S_entries<=0; S_entry<=0; S_images<=0; S_raw_verifying<=0; S_raw_lost<=0; O_error<=0; S_boot<=RAW_REQ;
                end
                RAW_REQ:if(!I_recovery_enable || !I_raw_card_ready || S_raw_lost) S_boot<=RAW_IDLE;
                    else if(S_raw_scan>=RECOVERY_SECTORS) begin
                        if(S_entries==0) fail(7); else begin S_entry<=0; S_boot<=LIST_FIND; end
                    end else begin fetch(S_raw_scan<<9,10'd512); S_boot<=RAW_WAIT; end
                RAW_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) begin S_raw_scan<=S_raw_verifying ? S_raw_start+1'b1 : S_raw_scan+1'b1; S_raw_verifying<=0; S_boot<=RAW_REQ; end
                    else if(S_raw_verifying) begin
                        if(S_raw_scan+1'b1>=S_raw_next) S_boot<=RAW_ACCEPT;
                        else begin S_raw_scan<=S_raw_scan+1'b1; S_boot<=RAW_REQ; end
                    end else S_boot<=RAW_CHECK;
                end
                RAW_CHECK:if(S_raw_header_valid) begin
                    S_raw_start<=S_raw_scan; S_raw_size<=S_raw_file_size;
                    S_raw_next<=S_raw_scan+((S_raw_file_size+511)>>9);
                    if(S_raw_file_size<=512) S_boot<=RAW_ACCEPT;
                    else begin S_raw_verifying<=1; S_raw_scan<=S_raw_scan+1'b1; S_boot<=RAW_REQ; end
                end else begin S_raw_scan<=S_raw_scan+1'b1; S_boot<=RAW_REQ; end
                RAW_ACCEPT:begin
                    S_offsets[S_entries]<=S_raw_start<<9; S_sizes[S_entries]<=S_raw_size;
                    S_types[S_entries]<=1; S_ids[S_entries]<={8'd0,S_entries}; S_crcs[S_entries]<=0;
                    S_entries<=S_entries+1'b1; S_raw_scan<=S_raw_next; S_raw_verifying<=0;
                    S_boot<=S_entries==63 ? RAW_NEXT : RAW_REQ;
                end
                RAW_NEXT:begin S_entry<=0; S_images<=0; S_boot<=LIST_FIND; end
                ONLINE,FAILED:begin end
                default:fail(15);
            endcase
            case(S_q)
                Q_IDLE:if(I_request_valid && O_request_ready) begin
                    S_lba<=I_lba; S_sectors<=I_count; S_byte<=0; S_cancel<=0;
                    O_byte_context<=I_context; O_done_context<=I_context; O_byte_tag<=I_tag; O_done_tag<=I_tag; O_done_error<=0;
                    if(I_count==0 || {1'b0,I_lba}+{25'd0,I_count}>33'd4194304) begin O_done_error<=1; S_q<=Q_DONE; end
                    else S_q<=Q_MAP;
                end
                Q_MAP:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else if(S_cluster>=256 && S_asset<S_entries && S_asset_offset<S_sizes[S_asset]) begin
                        S_is_flash<=1; S_asset_address<=(RECOVERY!=0 ? 32'd0 : 32'h100000)+S_offsets[S_asset]+S_asset_offset;
                        S_payload<=S_sizes[S_asset]-S_asset_offset>=512 ? 10'd512 : S_sizes[S_asset]-S_asset_offset;
                        S_q<=Q_FLASH;
                    end else begin S_is_flash<=0; S_q<=Q_STREAM; end
                Q_FLASH:begin fetch(S_asset_address,RECOVERY!=0 ? 10'd512 : S_payload); S_q<=Q_WAIT; end
                Q_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) begin O_done_error<=2; S_q<=Q_DONE; end
                    else if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else S_q<=Q_STREAM;
                end
                Q_STREAM:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else if(O_byte_valid && I_byte_ready) begin
                        if(S_byte==511) begin
                            S_byte<=0;
                            if(S_sectors==1) S_q<=Q_DONE;
                            else begin S_lba<=S_lba+1'b1; S_sectors<=S_sectors-1'b1; S_q<=Q_MAP; end
                        end else S_byte<=S_byte+1'b1;
                    end
                Q_DONE:if(I_done_ready) S_q<=Q_IDLE;
                default:begin O_done_error<=15; S_q<=Q_DONE; end
            endcase
            if(RECOVERY!=0 && (!I_recovery_enable || !I_raw_card_ready || S_raw_lost) &&
                !S_fetch_active && !S_fetch_offer && !S_fetch_start && S_q==Q_IDLE && S_boot!=RAW_IDLE) begin
                S_verified<=0; S_boot<=RAW_IDLE;
            end
        end
    end
    // Metadata synthesis: 512-byte sectors, reserved32, FAT32768, data LBA32800.
    reg [31:0] C_fat,C_cluster,C_size,C_dir_cluster,C_dir_size;
    reg [31:0] C_entry,C_asset,C_relative,C_sectors;
    reg [87:0] C_name;
    reg [7:0] C_attr;
    reg C_valid;
    always @* begin
        O_byte_data=0; C_fat=0; C_cluster=0; C_size=0; C_dir_cluster=0; C_dir_size=0;
        C_entry=0; C_asset=0; C_relative=0; C_sectors=0; C_name=0; C_attr=0; C_valid=0;
        if(S_is_flash) begin if({1'b0,S_byte}<S_payload) O_byte_data=S_buffer[S_byte]; end
        else if(S_lba==0) begin
            case(S_byte)
                0:O_byte_data=8'heb; 1:O_byte_data=8'h58; 2:O_byte_data=8'h90;
                12:O_byte_data=2; 13:O_byte_data=1; 14:O_byte_data=32; 16:O_byte_data=1;
                34:O_byte_data=8'h40; // total sectors 0x00400000
                37:O_byte_data=8'h80; // FAT sectors 0x00008000
                44:O_byte_data=2;
                510:O_byte_data=8'h55; 511:O_byte_data=8'haa;
                default:begin end
            endcase
        end else if(S_lba>=32 && S_lba<32800) begin
            C_cluster=((S_lba-32)<<7)+{25'd0,S_byte[8:2]};
            if(C_cluster==0) C_fat=32'h0ffffff8;
            else if(C_cluster==1 || C_cluster==10 || C_cluster==16) C_fat=32'h0fffffff;
            else if(C_cluster>=2 && C_cluster<10) C_fat=C_cluster+1;
            else if(C_cluster>=32 && C_cluster<32+(({25'd0,S_images}*32'd64+511)>>9))
                C_fat=C_cluster+1==32+(({25'd0,S_images}*32'd64+511)>>9) ? 32'h0fffffff : C_cluster+1;
            else if(C_cluster>=256) begin
                C_relative=C_cluster-256; C_asset=C_relative>>14;
                if(C_asset<S_entries) begin
                    C_sectors=(S_sizes[C_asset]+511)>>9;
                    if((C_relative & 32'h3fff)<C_sectors)
                        C_fat=(C_relative & 32'h3fff)+1==C_sectors ? 32'h0fffffff : C_cluster+1;
                end
            end
            O_byte_data=C_fat >> (S_byte[1:0]*8);
        end else if(S_cluster>=32 && S_cluster<40) begin
            C_relative=((S_cluster-32)<<9)+S_byte;
            if(C_relative<{25'd0,S_images}*32'd64) O_byte_data=S_playlist[C_relative[11:0]];
        end else if((S_cluster>=2 && S_cluster<=10) || S_cluster==16) begin
            C_entry=(S_cluster-2)*16+{28'd0,S_byte[8:5]};
            if(S_cluster==16) begin
                if(S_byte[8:5]==0) begin C_valid=1; C_name="PLAYLISTTXT"; C_dir_cluster=32; C_dir_size={25'd0,S_images}*32'd64; C_attr=8'h20; end
            end else if(C_entry==0) begin C_valid=1; C_name="PLAY       "; C_dir_cluster=16; C_attr=8'h10; end
            else if(C_entry<=S_entries) begin
                C_valid=1; C_asset=C_entry-1; C_attr=8'h20; C_dir_cluster=256+(C_asset<<14); C_dir_size=S_sizes[C_asset];
                C_name={asset_name(C_asset,0,S_types[C_asset]==2),asset_name(C_asset,1,S_types[C_asset]==2),
                    asset_name(C_asset,2,S_types[C_asset]==2),asset_name(C_asset,3,S_types[C_asset]==2),32'h20202020,
                    asset_name(C_asset,8,S_types[C_asset]==2),asset_name(C_asset,9,S_types[C_asset]==2),asset_name(C_asset,10,S_types[C_asset]==2)};
            end
            if(C_valid) begin
                if(S_byte[4:0]<11) O_byte_data=C_name >> ((10-S_byte[4:0])*8);
                else case(S_byte[4:0])
                    11:O_byte_data=C_attr;
                    20:O_byte_data=C_dir_cluster[23:16]; 21:O_byte_data=C_dir_cluster[31:24];
                    26:O_byte_data=C_dir_cluster[7:0]; 27:O_byte_data=C_dir_cluster[15:8];
                    28:O_byte_data=C_dir_size[7:0]; 29:O_byte_data=C_dir_size[15:8];
                    30:O_byte_data=C_dir_size[23:16]; 31:O_byte_data=C_dir_size[31:24];
                    default:begin end
                endcase
            end
        end
    end
endmodule
