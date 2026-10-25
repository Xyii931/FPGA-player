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
    localparam [5:0] HEADER_REQ=0,HEADER_WAIT=1,HEADER_CHECK=2,TABLE_REQ=3,TABLE_WAIT=4,
        TABLE_BYTES=5,TABLE_SAVE=6,COMPARE=7,TABLE_END=8,DATA_REQ=9,DATA_WAIT=10,
        DATA_CRC=11,DATA_END=12,LIST_FIND=13,LIST_PAIR=14,LIST_WRITE=15,ONLINE=16,FAILED=17,
        RAW_IDLE=18,RAW_REQ=19,RAW_WAIT=20,RAW_CHECK=21,RAW_ACCEPT=22,RAW_NEXT=23,
        CAT_STORE=24,COMPARE_REQ=25,DATA_META=26,DATA_META_WAIT=27,
        LIST_CHECK=28,LIST_META_WAIT=29,LIST_PAIR_REQ=30,TABLE_READ=31,DATA_READ=32,
        REJECT=33,LIST_FINISH=34,TABLE_VALIDATE=35;
    localparam [3:0] Q_IDLE=0,Q_MAP=1,Q_FLASH=2,Q_WAIT=3,Q_STREAM=4,Q_DONE=5,
        Q_LIST=6,Q_ASSET=7,Q_LOOKUP=8,Q_META_WAIT=9,Q_BUFFER=10,Q_DECODE=11;
    reg [5:0] S_boot;
    reg [3:0] S_q;
    reg [3:0] S_failure;
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
    reg [7:0] S_buffer_q;
    // Only the small fixed header is inspected in parallel. The sector itself
    // has one synchronous read port; never mux its 512 byte lanes into logic.
    reg [271:0] S_header;
    wire S_buffer_write=!I_reset && S_backend_byte_valid && S_fetch_active && S_fetch_count<512;
    wire S_buffer_boot_read=S_boot==TABLE_READ || S_boot==DATA_READ;
    // Four words per catalog entry: type/id, offset, size, CRC. One synchronous
    // read port is shared by boot verification and online sector generation.
    reg [31:0] S_catalog[0:511];
    reg [31:0] S_catalog_q;
    reg [127:0] S_catalog_result,S_current;
    reg [2:0] S_catalog_phase;
    reg [6:0] S_catalog_index,S_catalog_request;
    reg S_catalog_start,S_catalog_done;
    reg [1:0] S_store_word;
    reg [31:0] S_stream_size;
    reg [15:0] S_stream_type;
    // Keep catalog references rather than 64 repeated text records. Publish the
    // same 4096-byte logical file using a single synchronous map read per item.
    reg [16:0] S_playlist_map[0:63];
    reg [16:0] S_playlist_row;
    reg [159:0] S_record;
    reg [32:0] S_record_end;
    reg [7:0] S_entries,S_entry,S_compare;
    reg [31:0] S_table_crc,S_expected_table_crc,S_crc,S_data_position;
    reg [9:0] S_position;
    reg [6:0] S_images;
    reg [7:0] S_list_image,S_list_audio;
    reg S_list_has_audio;
    reg [31:0] S_lba;
    reg [7:0] S_sectors;
    reg [8:0] S_byte;
    reg [9:0] S_payload;
    reg S_cancel,S_is_flash,S_cancel_pending;
    reg [31:0] S_asset_address;
    wire S_buffer_stream_read=S_q==Q_BUFFER && {1'b0,S_byte}<S_payload;
    wire [8:0] S_buffer_address=S_buffer_boot_read ? S_position[8:0] : S_byte;
    // Freeze sector arithmetic before range checking / metadata admission.
    // Do not cascade LBA -> cluster -> directory entry -> asset in one cycle.
    reg [31:0] S_cluster,S_asset_relative,S_fat_base,S_directory_base;
    reg [7:0] S_fat_asset;
    reg S_is_playlist,S_is_fat,S_is_directory;
    wire [7:0] S_asset=S_asset_relative[21:14];
    wire [31:0] S_asset_offset={18'd0,S_asset_relative[13:0]}<<9;
    // Freeze the validated header's table bound before comparing records.
    reg [11:0] S_table_end;
    wire [11:0] S_table_offset={S_entry,4'd0}+{2'd0,S_entry,2'd0};
    wire [5:0] S_playlist_address={S_cluster[2:0],S_byte[8:6]};
    wire [31:0] S_end=S_current[63:32]+S_current[95:64];
    wire [31:0] S_other_end=S_catalog_result[63:32]+S_catalog_result[95:64];
    wire [31:0] S_fat_cluster=S_fat_base | {25'd0,S_byte[8:2]};
    // Each asset occupies 128 complete FAT sectors; its index is independent
    // of the byte within a sector. Only use this 8-bit value in the FAT range.
    wire S_fat_meta=S_is_fat && S_fat_cluster>=256 && S_fat_asset<S_entries;
    wire [31:0] S_directory_entry=S_directory_base | {28'd0,S_byte[8:5]};
    wire S_directory_meta=S_is_directory && S_cluster!=16 && S_directory_entry!=0 &&
        S_directory_entry<={24'd0,S_entries};
    // The directory range check proves entry 1..128 before this is admitted.
    wire [6:0] S_stream_index=S_is_fat ? S_fat_asset[6:0] : S_directory_entry[6:0]-7'd1;
    wire [1:0] S_catalog_read_word=S_catalog_phase[1:0]-2'd1;
    wire [6:0] S_catalog_write_index=RECOVERY!=0 ? S_entries[6:0] : S_entry[6:0];
    wire S_catalog_idle=S_catalog_phase==0 && !S_catalog_start;
    wire S_cancel_match=I_cancel_valid && O_cancel_ready && I_cancel_context==O_byte_context && I_cancel_tag==O_byte_tag;
    wire S_boot_catalog_read=(S_boot==COMPARE_REQ && S_compare!=S_entry) || S_boot==DATA_META ||
        (S_boot==LIST_FIND && S_entry!=S_entries) || (S_boot==LIST_PAIR_REQ && S_compare!=S_entries);
    wire S_online_catalog_read=!(S_cancel || S_cancel_match) &&
        ((S_q==Q_MAP && S_cluster>=256 && S_asset<S_entries) ||
         (S_q==Q_LOOKUP && !S_is_playlist && (S_fat_meta || S_directory_meta)));
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
    assign O_quiescent=S_q==Q_IDLE && !O_cancel_done_valid && !S_cancel_pending &&
        !S_fetch_active && !S_fetch_offer && !S_fetch_start && S_catalog_idle;
    always @(posedge I_clk) begin
        if(S_buffer_write) S_buffer[S_fetch_count[8:0]]<=S_backend_byte;
        if(!I_reset && (S_buffer_boot_read || S_buffer_stream_read))
            S_buffer_q<=S_buffer[S_buffer_address];
    end
    genvar G_header_byte;
    generate for(G_header_byte=0;G_header_byte<34;G_header_byte=G_header_byte+1) begin : g_header
        always @(posedge I_clk) begin
            if(S_buffer_write && S_fetch_count==G_header_byte)
                S_header[G_header_byte*8+:8]<=S_backend_byte;
        end
    end endgenerate
    // No RAM reset and no output mux inside its read assignment. Entries become
    // usable only after all four words have been written. No collision is used.
    always @(posedge I_clk) begin
        if(!I_reset && S_boot==CAT_STORE)
            S_catalog[{S_catalog_write_index,S_store_word}]<=S_record[S_store_word*32+:32];
        if(!I_reset && S_catalog_phase>=1 && S_catalog_phase<=4)
            S_catalog_q<=S_catalog[{S_catalog_index,S_catalog_read_word}];
    end
    // Data selection is independent of admission/cancel/range checks. The
    // reader freezes this register on the edge AFTER start is raised.
    always @(posedge I_clk) begin
        if(I_reset) begin S_catalog_request<=0; S_catalog_start<=0; end
        else begin
            S_catalog_start<=S_boot_catalog_read || S_online_catalog_read;
            if(S_boot==COMPARE_REQ || S_boot==LIST_PAIR_REQ) S_catalog_request<=S_compare[6:0];
            else if(S_boot==DATA_META || S_boot==LIST_FIND) S_catalog_request<=S_entry[6:0];
            else if(S_q==Q_MAP) S_catalog_request<=S_asset[6:0];
            else S_catalog_request<=S_stream_index;
        end
    end
    // Calculate a candidate mapping on every completed catalog read. Only
    // Q_ASSET may admit it after checking size/range/cancel; other results are
    // harmless scratch values. Keep the long admission decode off RAM data.
    always @(posedge I_clk) begin
        if(I_reset) begin S_asset_address<=0; S_payload<=0; end
        else if(S_catalog_done) begin
            S_asset_address<=(RECOVERY!=0 ? 32'd0 : 32'h100000)+S_catalog_result[63:32]+S_asset_offset;
            S_payload<=S_catalog_result[95:64]-S_asset_offset>=512 ? 10'd512 : S_catalog_result[95:64]-S_asset_offset;
        end
    end
    // Command data is independent of validation/next-state priority. Capture
    // only in request states, then retain it through the real backend terminal.
    always @(posedge I_clk) begin
        if(I_reset) begin S_fetch_address<=0; O_flash_length<=0; end
        else if(S_boot==HEADER_REQ) begin S_fetch_address<=32'h100000; O_flash_length<=16; end
        else if(S_boot==TABLE_REQ) begin S_fetch_address<=32'h100010+{20'd0,S_table_offset}; O_flash_length<=20; end
        else if(S_boot==DATA_REQ) begin
            S_fetch_address<=32'h100000+S_current[63:32]+S_data_position;
            O_flash_length<=S_current[95:64]-S_data_position>=512 ? 10'd512 : S_current[95:64]-S_data_position;
        end else if(S_boot==RAW_REQ) begin S_fetch_address<=S_raw_scan<<9; O_flash_length<=512; end
        else if(S_q==Q_FLASH) begin S_fetch_address<=S_asset_address; O_flash_length<=RECOVERY!=0 ? 10'd512 : S_payload; end
    end
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_catalog_phase<=0; S_catalog_done<=0; S_catalog_index<=0; S_catalog_result<=0;
        end else begin
            S_catalog_done<=0;
            case(S_catalog_phase)
                0:if(S_catalog_start) begin S_catalog_index<=S_catalog_request; S_catalog_phase<=1; end
                1:S_catalog_phase<=2;
                2:begin S_catalog_result[31:0]<=S_catalog_q; S_catalog_phase<=3; end
                3:begin S_catalog_result[63:32]<=S_catalog_q; S_catalog_phase<=4; end
                4:begin S_catalog_result[95:64]<=S_catalog_q; S_catalog_phase<=5; end
                5:begin S_catalog_result[127:96]<=S_catalog_q; S_catalog_phase<=0; S_catalog_done<=1; end
                default:S_catalog_phase<=0;
            endcase
        end
    end
    // No content reset. Construction and online reads are disjoint; shorter
    // rebuilds use S_images to hide stale entries, including the zero padding.
    always @(posedge I_clk) begin
        if(!I_reset && S_boot==LIST_WRITE)
            S_playlist_map[S_images[5:0]]<={S_list_has_audio,S_list_audio,S_list_image};
        if(!I_reset && S_q==Q_LIST && {1'b0,S_playlist_address}<S_images)
            S_playlist_row<=S_playlist_map[S_playlist_address];
    end
    // Read engine owns its buffer through terminal. No local cancel resets it.
    always @(posedge I_clk) begin
        if(I_reset) begin S_fetch_offer<=0; S_fetch_active<=0; S_fetch_done<=0; S_fetch_bad<=0; S_fetch_count<=0; S_raw_tag<=0; end
        else begin
            S_fetch_done<=0;
            if(S_fetch_start) begin S_fetch_offer<=1; S_fetch_bad<=0; S_fetch_count<=0; S_raw_tag<=S_raw_tag+1'b1; end
            if(S_fetch_offer && S_backend_ready) begin S_fetch_offer<=0; S_fetch_active<=1; end
            if(S_backend_byte_valid && S_fetch_active) begin
                if(S_fetch_count>=512) S_fetch_bad<=1;
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
        begin S_fetch_start<=1; end
    endtask
    task fail;
        input [3:0] error;
        // Register the selected cause before publishing a terminal. Avoid
        // decoding every validation state through one shared error/ready mux.
        begin S_failure<=error; S_boot<=REJECT; end
    endtask
    wire [31:0] S_header_magic=S_header[31:0];
    wire [15:0] S_header_count=S_header[63:48];
    wire [31:0] S_header_table_bytes=S_header[95:64];
    // Out-of-range counts are rejected independently; only 1..128 can publish.
    wire [11:0] S_header_table_expected={S_header_count[7:0],4'd0}+{2'd0,S_header_count[7:0],2'd0};
    wire [31:0] S_raw_file_size=S_header[47:16];
    wire [31:0] S_raw_pixel_offset=S_header[111:80];
    wire [31:0] S_raw_dib=S_header[143:112];
    wire [31:0] S_raw_width=S_header[175:144];
    wire [31:0] S_raw_signed_height=S_header[207:176];
    wire [31:0] S_raw_height=S_raw_signed_height[31] ? 32'd0-S_raw_signed_height : S_raw_signed_height;
    wire [15:0] S_raw_bpp=S_header[239:224];
    wire [63:0] S_raw_row=(({32'd0,S_raw_width}*(S_raw_bpp==24 ? 64'd3 : 64'd4)+64'd3)>>2)<<2;
    wire [63:0] S_raw_required={32'd0,S_raw_pixel_offset}+S_raw_row*{32'd0,S_raw_height};
    wire S_raw_header_valid=S_header[15:0]==16'h4d42 &&
        (S_raw_dib==40 || S_raw_dib==108 || S_raw_dib==124) &&
        S_raw_width!=0 && S_raw_width<=1920 && S_raw_height!=0 && S_raw_height<=1080 &&
        S_header[223:208]==1 && (S_raw_bpp==24 || S_raw_bpp==32) &&
        S_header[271:240]==0 &&
        S_raw_pixel_offset>=14+S_raw_dib && S_raw_file_size>=S_raw_required &&
        S_raw_file_size<=32'd8388608 &&
        {32'd0,S_raw_file_size}+({32'd0,S_raw_scan}<<9)<=({32'd0,RECOVERY_SECTORS}<<9);
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_boot<=RECOVERY!=0 ? RAW_IDLE : HEADER_REQ; S_q<=Q_IDLE; S_verified<=0; O_error<=0;
            S_failure<=0;
            S_raw_scan<=0; S_raw_start<=0; S_raw_size<=0; S_raw_next<=0; S_raw_verifying<=0; S_raw_lost<=0;
            S_fetch_start<=0;
            S_store_word<=0; S_current<=0; S_table_end<=0;
            S_stream_size<=0; S_stream_type<=0;
            S_entries<=0; S_entry<=0; S_compare<=0; S_position<=0; S_record<=0;
            S_record_end<=0;
            S_table_crc<=32'hffffffff; S_expected_table_crc<=0; S_crc<=32'hffffffff; S_data_position<=0;
            S_images<=0; S_list_image<=0; S_list_audio<=0; S_list_has_audio<=0;
            S_lba<=0; S_sectors<=0; S_byte<=0; S_cancel<=0; S_cancel_pending<=0; S_is_flash<=0;
            S_cluster<=0; S_asset_relative<=0; S_fat_base<=0; S_directory_base<=0;
            S_fat_asset<=0;
            S_is_playlist<=0; S_is_fat<=0; S_is_directory<=0;
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
                HEADER_REQ:begin fetch; S_boot<=HEADER_WAIT; end
                HEADER_WAIT:if(S_fetch_done) begin if(S_fetch_bad) fail(1); else S_boot<=HEADER_CHECK; end
                HEADER_CHECK:if(S_header_magic!=32'h314d4544 || S_header[47:32]!=1 ||
                    S_header_count==0 || S_header_count>128 || S_header_table_bytes!={20'd0,S_header_table_expected}) fail(2);
                    else begin
                        S_entries<=S_header_count[7:0]; S_entry<=0; S_table_crc<=32'hffffffff;
                        S_table_end<=S_header_table_expected+12'd16;
                        S_expected_table_crc<=S_header[127:96]; S_boot<=TABLE_REQ;
                    end
                TABLE_REQ:begin fetch; S_boot<=TABLE_WAIT; end
                TABLE_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) fail(1);
                    else begin S_record<=0; S_position<=0; S_boot<=TABLE_READ; end
                end
                TABLE_READ:S_boot<=TABLE_BYTES;
                TABLE_BYTES:begin
                    S_record[S_position*8+:8]<=S_buffer_q;
                    S_table_crc<=crc_byte(S_table_crc,S_buffer_q);
                    if(S_position==19) S_boot<=TABLE_SAVE;
                    else begin S_position<=S_position+1'b1; S_boot<=TABLE_READ; end
                end
                TABLE_SAVE:begin
                    S_record_end<={1'b0,S_record[63:32]}+{1'b0,S_record[95:64]}; S_boot<=TABLE_VALIDATE;
                end
                TABLE_VALIDATE:if((S_record[15:0]!=1 && S_record[15:0]!=2) || S_record[159:128]!=0 ||
                    S_record[63:32]<{20'd0,S_table_end} || S_record[95:64]==0 ||
                    S_record_end>33'h700000) fail(3);
                    else begin
                        S_current<=S_record[127:0]; S_store_word<=0; S_boot<=CAT_STORE;
                    end
                CAT_STORE:if(S_store_word==3) begin
                    if(RECOVERY!=0) begin
                        S_entries<=S_entries+1'b1; S_raw_scan<=S_raw_next; S_raw_verifying<=0;
                        S_boot<=S_entries==63 ? RAW_NEXT : RAW_REQ;
                    end else begin S_compare<=0; S_boot<=COMPARE_REQ; end
                end else S_store_word<=S_store_word+1'b1;
                COMPARE_REQ:if(S_compare==S_entry) begin
                    if(S_entry+8'd1==S_entries) S_boot<=TABLE_END;
                    else begin S_entry<=S_entry+1'b1; S_boot<=TABLE_REQ; end
                end else S_boot<=COMPARE;
                COMPARE:if(S_catalog_done) begin
                    if((S_current[15:0]==S_catalog_result[15:0] && S_current[31:16]==S_catalog_result[31:16]) ||
                        (S_current[63:32]<S_other_end && S_catalog_result[63:32]<S_end)) fail(3);
                    else begin S_compare<=S_compare+1'b1; S_boot<=COMPARE_REQ; end
                end
                TABLE_END:if((S_table_crc^32'hffffffff)!=S_expected_table_crc) fail(4);
                    else begin S_entry<=0; S_data_position<=0; S_crc<=32'hffffffff; S_boot<=DATA_META; end
                DATA_META:S_boot<=DATA_META_WAIT;
                DATA_META_WAIT:if(S_catalog_done) begin S_current<=S_catalog_result; S_boot<=DATA_REQ; end
                DATA_REQ:begin
                    fetch;
                    S_boot<=DATA_WAIT;
                end
                DATA_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) fail(1); else begin S_position<=0; S_boot<=DATA_READ; end
                end
                DATA_READ:S_boot<=DATA_CRC;
                DATA_CRC:begin
                    S_crc<=crc_byte(S_crc,S_buffer_q);
                    if(S_position+10'd1==O_flash_length) begin S_data_position<=S_data_position+O_flash_length; S_boot<=DATA_END; end
                    else begin S_position<=S_position+1'b1; S_boot<=DATA_READ; end
                end
                DATA_END:if(S_data_position<S_current[95:64]) S_boot<=DATA_REQ;
                    else if((S_crc^32'hffffffff)!=S_current[127:96]) fail(5);
                    else if(S_entry+8'd1==S_entries) begin S_entry<=0; S_images<=0; S_boot<=LIST_FIND; end
                    else begin S_entry<=S_entry+1'b1; S_data_position<=0; S_crc<=32'hffffffff; S_boot<=DATA_META; end
                LIST_FIND:if(S_entry==S_entries) S_boot<=LIST_FINISH;
                    else S_boot<=LIST_META_WAIT;
                LIST_FINISH:begin
                    if(S_images==0) fail(6); else begin S_verified<=1; S_boot<=ONLINE; end
                end
                LIST_META_WAIT:if(S_catalog_done) begin S_current<=S_catalog_result; S_boot<=LIST_CHECK; end
                LIST_CHECK:if(S_current[15:0]==1) begin
                    if(S_images==64) fail(6);
                    else begin S_list_image<=S_entry; S_list_audio<=0; S_list_has_audio<=0; S_compare<=0; S_boot<=LIST_PAIR_REQ; end
                end else begin
                    // Orphan audio is rejected rather than silently ignored.
                    S_compare<=0; S_list_has_audio<=0; S_boot<=LIST_PAIR_REQ;
                end
                LIST_PAIR_REQ:if(S_compare==S_entries) begin
                    if(S_current[15:0]==2) begin if(!S_list_has_audio) fail(6); else begin S_entry<=S_entry+1'b1; S_boot<=LIST_FIND; end end
                    else S_boot<=LIST_WRITE;
                end else S_boot<=LIST_PAIR;
                LIST_PAIR:if(S_catalog_done) begin
                    if(S_catalog_result[15:0]!=S_current[15:0] && S_catalog_result[31:16]==S_current[31:16]) begin
                        S_list_has_audio<=1; S_list_audio<=S_compare;
                    end
                    S_compare<=S_compare+1'b1; S_boot<=LIST_PAIR_REQ;
                end
                LIST_WRITE:begin
                    S_images<=S_images+1'b1; S_entry<=S_entry+1'b1; S_boot<=LIST_FIND;
                end
                RAW_IDLE:if(I_recovery_enable && I_raw_card_ready && !S_fetch_active && !S_fetch_offer && !S_fetch_start && S_catalog_idle) begin
                    S_raw_scan<=0; S_entries<=0; S_entry<=0; S_images<=0; S_raw_verifying<=0; S_raw_lost<=0; O_error<=0; S_boot<=RAW_REQ;
                end
                RAW_REQ:if(!I_recovery_enable || !I_raw_card_ready || S_raw_lost) S_boot<=RAW_IDLE;
                    else if(S_raw_scan>=RECOVERY_SECTORS) begin
                        if(S_entries==0) fail(7); else begin S_entry<=0; S_boot<=LIST_FIND; end
                    end else begin fetch; S_boot<=RAW_WAIT; end
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
                    S_record<={32'd0,32'd0,S_raw_size,(S_raw_start<<9),8'd0,S_entries,16'd1};
                    S_store_word<=0; S_boot<=CAT_STORE;
                end
                RAW_NEXT:begin S_entry<=0; S_images<=0; S_boot<=LIST_FIND; end
                REJECT:begin O_error<=S_failure; S_verified<=0; S_boot<=FAILED; end
                ONLINE,FAILED:begin end
                default:fail(15);
            endcase
            case(S_q)
                Q_IDLE:if(I_request_valid && O_request_ready) begin
                    S_lba<=I_lba; S_sectors<=I_count; S_byte<=0; S_cancel<=0;
                    O_byte_context<=I_context; O_done_context<=I_context; O_byte_tag<=I_tag; O_done_tag<=I_tag; O_done_error<=0;
                    if(I_count==0 || {1'b0,I_lba}+{25'd0,I_count}>33'd4194304) begin O_done_error<=1; S_q<=Q_DONE; end
                    else S_q<=Q_DECODE;
                end
                Q_DECODE:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else begin
                        S_cluster<=S_lba-32'd32798; // data LBA32800, cluster2
                        S_asset_relative<=S_lba-32'd33054;
                        S_fat_base<=(S_lba-32'd32)<<7;
                        S_fat_asset<=(S_lba-32'd34)>>7;
                        S_directory_base<=(S_lba-32'd32800)<<4;
                        S_is_playlist<=S_lba>=32830 && S_lba<32838;
                        S_is_fat<=S_lba>=32 && S_lba<32800;
                        S_is_directory<=(S_lba>=32800 && S_lba<=32808) || S_lba==32814;
                        S_q<=Q_MAP;
                    end
                Q_MAP:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else if(S_cluster>=256 && S_asset<S_entries) begin
                        S_q<=Q_ASSET;
                    end else begin S_is_flash<=0; S_q<=Q_LOOKUP; end
                // A cancelled internal read still drains before terminal/new
                // admission, so its completion cannot satisfy the next request.
                Q_ASSET:if(S_catalog_done) begin
                    if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else if(S_asset_offset<S_catalog_result[95:64]) begin
                        S_is_flash<=1; S_q<=Q_FLASH;
                    end else begin S_is_flash<=0; S_q<=Q_LOOKUP; end
                end
                Q_LOOKUP:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else if(S_is_playlist) S_q<=Q_LIST;
                    else if(S_fat_meta || S_directory_meta) S_q<=Q_META_WAIT;
                    else S_q<=Q_STREAM;
                Q_META_WAIT:if(S_catalog_done) begin
                    S_stream_type<=S_catalog_result[15:0]; S_stream_size<=S_catalog_result[95:64];
                    if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else S_q<=Q_STREAM;
                end
                Q_LIST:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else S_q<=Q_STREAM;
                Q_FLASH:begin fetch; S_q<=Q_WAIT; end
                Q_WAIT:if(S_fetch_done) begin
                    if(S_fetch_bad) begin O_done_error<=2; S_q<=Q_DONE; end
                    else if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else S_q<=Q_BUFFER;
                end
                Q_BUFFER:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else S_q<=Q_STREAM;
                Q_STREAM:if(S_cancel || S_cancel_match) begin O_done_error<=7; S_q<=Q_DONE; end
                    else if(O_byte_valid && I_byte_ready) begin
                        if(S_byte==511) begin
                            S_byte<=0;
                            if(S_sectors==1) S_q<=Q_DONE;
                            else begin S_lba<=S_lba+1'b1; S_sectors<=S_sectors-1'b1; S_q<=Q_DECODE; end
                        end else begin
                            S_byte<=S_byte+1'b1;
                            if(S_is_flash) S_q<=Q_BUFFER;
                            else if(S_is_playlist && S_byte[5:0]==63) S_q<=Q_LIST;
                            else if(!S_is_flash && ((S_is_fat && S_byte[1:0]==3) ||
                                (S_is_directory && S_byte[4:0]==31))) S_q<=Q_LOOKUP;
                        end
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
        if(S_is_flash) begin if({1'b0,S_byte}<S_payload) O_byte_data=S_buffer_q; end
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
            C_cluster=S_fat_cluster;
            if(C_cluster==0) C_fat=32'h0ffffff8;
            else if(C_cluster==1 || C_cluster==10 || C_cluster==16) C_fat=32'h0fffffff;
            else if(C_cluster>=2 && C_cluster<10) C_fat=C_cluster+1;
            else if(C_cluster>=32 && C_cluster<32+(({25'd0,S_images}*32'd64+511)>>9))
                C_fat=C_cluster+1==32+(({25'd0,S_images}*32'd64+511)>>9) ? 32'h0fffffff : C_cluster+1;
            else if(C_cluster>=256) begin
                C_relative=C_cluster-256; C_asset={24'd0,S_fat_asset};
                if(C_asset<S_entries) begin
                    C_sectors=(S_stream_size+511)>>9;
                    if((C_relative & 32'h3fff)<C_sectors)
                        C_fat=(C_relative & 32'h3fff)+1==C_sectors ? 32'h0fffffff : C_cluster+1;
                end
            end
            O_byte_data=C_fat >> (S_byte[1:0]*8);
        end else if(S_cluster>=32 && S_cluster<40) begin
            C_relative=((S_cluster-32)<<9)+S_byte;
            if(C_relative<{25'd0,S_images}*32'd64)
                O_byte_data=list_byte(S_byte[5:0],S_playlist_row[7:0],S_playlist_row[15:8],S_playlist_row[16]);
        end else if((S_cluster>=2 && S_cluster<=10) || S_cluster==16) begin
            C_entry=S_directory_entry;
            if(S_cluster==16) begin
                if(S_byte[8:5]==0) begin C_valid=1; C_name="PLAYLISTTXT"; C_dir_cluster=32; C_dir_size={25'd0,S_images}*32'd64; C_attr=8'h20; end
            end else if(C_entry==0) begin C_valid=1; C_name="PLAY       "; C_dir_cluster=16; C_attr=8'h10; end
            else if(C_entry<=S_entries) begin
                C_valid=1; C_asset=C_entry-1; C_attr=8'h20; C_dir_cluster=256+(C_asset<<14); C_dir_size=S_stream_size;
                C_name={asset_name(C_asset,0,S_stream_type==2),asset_name(C_asset,1,S_stream_type==2),
                    asset_name(C_asset,2,S_stream_type==2),asset_name(C_asset,3,S_stream_type==2),32'h20202020,
                    asset_name(C_asset,8,S_stream_type==2),asset_name(C_asset,9,S_stream_type==2),asset_name(C_asset,10,S_stream_type==2)};
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
