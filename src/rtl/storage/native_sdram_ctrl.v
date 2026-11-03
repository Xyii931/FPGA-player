// Native SDR SDRAM commands, 2M x 32: {row[10:0], bank[1:0], column[7:0]}.
// All timing parameters are CLOCK CYCLES, pending TD/device/board verification.
// I_clk_sft is the related 83.333333 MHz device clock delayed 7 ns from I_clk.
// It must have one rising edge strictly between each pair of I_clk rising edges.
module native_sdram_ctrl #(
    parameter integer INIT_CYCLES=25000,
    // Maximum refresh command interval: 650 * 12 ns = 7.8 us.
    parameter integer REFRESH_CYCLES=650,
    parameter integer CAS_LATENCY=3,
    parameter integer T_RP=3,T_RCD=3,T_RFC=10,T_RAS=6,T_RC=9,
    parameter integer T_RRD=2,T_WR=3,T_WTR=2,T_MRD=2,
    parameter integer SLOT_BITS=4
) (
    input wire I_clk,I_clk_sft,I_reset,
    input wire I_cmd_valid,
    output wire O_cmd_ready,
    input wire I_cmd_wr,
    input wire [20:0] I_cmd_addr,
    input wire [31:0] I_cmd_data,I_cmd_tag,
    input wire [3:0] I_cmd_mask,
    output wire O_result_valid,
    input wire I_result_ready,
    output wire O_result_wr,
    output wire [31:0] O_result_data,O_result_tag,
    output wire [3:0] O_result_error,
    output reg O_initialized,O_clock_fault,
    output wire O_device_busy,O_busy,
    output reg O_refresh_pulse,
    output wire O_sdram_clk,
    output reg O_sdram_cke,O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n,
    output reg [10:0] O_sdram_addr,
    output reg [1:0] O_sdram_ba,
    output reg [3:0] O_sdram_dm,
    inout wire [31:0] IO_sdram_dq
);
    localparam integer DEPTH=1<<SLOT_BITS;
    localparam integer READ_DELAY=CAS_LATENCY+2,WRITE_DELAY=T_WR+1;
    // Start early enough to finish an active row/command, drain both pipes,
    // precharge and issue REFRESH before the configured command deadline.
    // The conservative sum also covers FSM transitions and refresh recovery.
    localparam integer REFRESH_MARGIN=T_RAS+T_RCD+T_RP+T_WR+
        READ_DELAY+WRITE_DELAY+T_RFC+8;
    localparam integer REFRESH_TRIGGER=REFRESH_CYCLES-REFRESH_MARGIN;
    localparam [3:0] POWER=0,WAKE=1,INIT_PRE=2,INIT_RP=3,INIT_REF=4,
        INIT_RFC=5,INIT_MODE=6,MODE_WAIT=7,RUN=8,ROW_RP=9,ROW_RCD=10,
        REF_PRE=11,REF_RP=12,DO_REFRESH=13,REF_RFC=14;
    localparam [10:0] MODE_WORD=11'h200 | (CAS_LATENCY<<4);
    function integer counter_bits;
        input integer count;
        integer remaining;
        begin
            counter_bits=1;
            remaining=count-1;
            while(remaining>1) begin counter_bits=counter_bits+1; remaining=remaining>>1; end
        end
    endfunction
    localparam integer REFRESH_BITS=counter_bits(REFRESH_TRIGGER);
    reg [3:0] S_state;
    reg [31:0] S_power_count;
    reg [REFRESH_BITS-1:0] S_refresh_count;
    reg [7:0] S_wait,S_activate_gap,S_read_gap,S_write_gap;
    reg [3:0] S_init_refresh,S_open;
    reg [10:0] S_row[0:3];
    reg [7:0] S_precharge_wait[0:3],S_ras_wait[0:3],S_rc_wait[0:3];
    reg [SLOT_BITS-1:0] S_head,S_tail;
    reg [SLOT_BITS:0] S_count;
    reg [31:0] S_tags[0:DEPTH-1],S_data[0:DEPTH-1];
    reg S_wr[0:DEPTH-1],S_complete[0:DEPTH-1];
    reg [READ_DELAY-1:0] S_read_pipe;
    reg [WRITE_DELAY-1:0] S_write_pipe;
    reg [SLOT_BITS-1:0] S_read_slot[0:READ_DELAY-1],S_write_slot[0:WRITE_DELAY-1];
    reg [31:0] S_read_sample,S_dq_data;
    reg S_dq_drive;
    // WRITE data is driven one clk cycle before the WRITE command, so the
    // device receives a full cycle plus the device-clock phase for DQ setup.
    reg S_wr_pending;
    reg [1:0] S_wr_bank;
    reg [7:0] S_wr_col;
    reg [3:0] S_wr_mask;
    reg [SLOT_BITS-1:0] S_wr_slot;
    // Related-clock path, intentionally NOT an asynchronous bit synchronizer.
    // Every command interval must contain its actual shifted/device clock edge.
    reg [3:0] S_shift_edges,S_previous_edges;
    reg S_phase_armed;
    reg S_phase_fault_q;
    reg S_retire_read,S_retire_write;
    reg [SLOT_BITS-1:0] S_retire_read_slot,S_retire_write_slot;
    reg [31:0] S_retire_read_data;
    wire [3:0] S_expected_edges=S_previous_edges+4'd1;
    wire S_phase_fault=S_phase_armed && S_shift_edges!=S_expected_edges;
    integer S_i;
    wire [1:0] S_bank=I_cmd_addr[9:8];
    wire [10:0] S_wanted_row=I_cmd_addr[20:10];
    // Compare banks in parallel; muxing a whole row before its equality check
    // lengthens the ready/command/DQ-drive path to the memory pads.
    wire S_row_hit=(S_bank==0 && S_open[0] && S_row[0]==S_wanted_row) ||
        (S_bank==1 && S_open[1] && S_row[1]==S_wanted_row) ||
        (S_bank==2 && S_open[2] && S_row[2]==S_wanted_row) ||
        (S_bank==3 && S_open[3] && S_row[3]==S_wanted_row);
    wire S_refresh_due=S_refresh_count==REFRESH_TRIGGER-1;
    wire S_capacity=S_count<DEPTH;
    wire S_turn_ok=I_cmd_wr ? S_write_gap==0 : S_read_gap==0;
    wire S_fire=I_cmd_valid && O_cmd_ready;
    wire S_take=O_result_valid && I_result_ready;
    wire S_pipes_empty=S_read_pipe==0 && S_write_pipe==0;
    wire S_all_precharge=S_ras_wait[0]==0 && S_ras_wait[1]==0 &&
        S_ras_wait[2]==0 && S_ras_wait[3]==0 &&
        S_precharge_wait[0]==0 && S_precharge_wait[1]==0 &&
        S_precharge_wait[2]==0 && S_precharge_wait[3]==0;
    assign O_cmd_ready=!I_reset && !O_clock_fault && O_initialized && S_state==RUN && !S_refresh_due &&
        S_capacity && S_row_hit && S_turn_ok && !S_wr_pending;
    assign O_result_valid=!I_reset && !O_clock_fault && S_count!=0 && S_complete[S_head];
    assign {O_result_wr,O_result_data,O_result_tag}={S_wr[S_head],S_data[S_head],S_tags[S_head]};
    // This SDR device has no per-word error acknowledgement or ECC.
    assign O_result_error=4'd0;
    assign O_busy=O_clock_fault || !O_initialized || S_state!=RUN || S_count!=0 || !S_pipes_empty;
    assign O_device_busy=O_initialized && (S_state!=RUN || !S_pipes_empty || S_wr_pending ||
        {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}!=3'b111);
    assign O_sdram_clk=I_clk_sft;
    // S_dq_drive already clears asynchronously with I_reset. A second reset
    // mux here would add a host-reset-to-device-data half-cycle path.
    assign IO_sdram_dq=S_dq_drive ? S_dq_data : 32'bz;

    // READ data appears after the CAS edge. Capture at the FOLLOWING device edge,
    // before its next data change, then transfer on the next related logic edge.
    // This is a half-cycle timing path that must be constrained and checked in TD.
    always @(posedge I_clk_sft or posedge I_reset) begin
        if(I_reset) begin S_read_sample<=0; S_shift_edges<=0; end
        else begin
            S_shift_edges<=S_shift_edges+4'd1;
            if(S_read_pipe[READ_DELAY-1]) S_read_sample<=IO_sdram_dq;
        end
    end
    always @(posedge I_clk or posedge I_reset) begin
        if(I_reset) begin
            S_state<=POWER; S_power_count<=0; S_refresh_count<=0; S_wait<=0;
            S_activate_gap<=0; S_read_gap<=0; S_write_gap<=0; S_init_refresh<=0; S_open<=0;
            S_head<=0; S_tail<=0; S_count<=0; S_read_pipe<=0; S_write_pipe<=0;
            S_dq_data<=0; S_dq_drive<=0; O_initialized<=0; O_refresh_pulse<=0;
            S_wr_pending<=0; S_wr_bank<=0; S_wr_col<=0; S_wr_mask<=0; S_wr_slot<=0;
            S_previous_edges<=0; S_phase_armed<=0; S_phase_fault_q<=0; O_clock_fault<=0;
            S_retire_read<=0; S_retire_write<=0; S_retire_read_slot<=0; S_retire_write_slot<=0;
            S_retire_read_data<=0;
            O_sdram_cke<=0; O_sdram_ras_n<=1; O_sdram_cas_n<=1; O_sdram_we_n<=1;
            O_sdram_addr<=0; O_sdram_ba<=0; O_sdram_dm<=15;
            for(S_i=0;S_i<4;S_i=S_i+1) begin
                S_row[S_i]<=0; S_precharge_wait[S_i]<=0; S_ras_wait[S_i]<=0; S_rc_wait[S_i]<=0;
            end
            for(S_i=0;S_i<DEPTH;S_i=S_i+1) begin
                S_complete[S_i]<=0;
            end
            for(S_i=0;S_i<READ_DELAY;S_i=S_i+1) S_read_slot[S_i]<=0;
            for(S_i=0;S_i<WRITE_DELAY;S_i=S_i+1) S_write_slot[S_i]<=0;
        end else begin
            // Commands and write-data enable span the intervening shifted edge.
            {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b111;
            O_sdram_addr<=0; O_sdram_ba<=0; O_sdram_dm<=15; S_dq_drive<=0; O_refresh_pulse<=0;
            S_previous_edges<=S_shift_edges;
            S_phase_fault_q<=S_phase_fault;
            if(S_power_count>=3) S_phase_armed<=1;
            if(S_activate_gap!=0) S_activate_gap<=S_activate_gap-1'b1;
            if(S_read_gap!=0) S_read_gap<=S_read_gap-1'b1;
            if(S_write_gap!=0) S_write_gap<=S_write_gap-1'b1;
            for(S_i=0;S_i<4;S_i=S_i+1) begin
                if(S_precharge_wait[S_i]!=0) S_precharge_wait[S_i]<=S_precharge_wait[S_i]-1'b1;
                if(S_ras_wait[S_i]!=0) S_ras_wait[S_i]<=S_ras_wait[S_i]-1'b1;
                if(S_rc_wait[S_i]!=0) S_rc_wait[S_i]<=S_rc_wait[S_i]-1'b1;
            end
            // Age is needed only up to the refresh threshold. Saturation
            // avoids a 32-bit comparator in command and DQ-drive enables.
            if(O_initialized && !S_refresh_due) S_refresh_count<=S_refresh_count+1'b1;
            S_read_pipe<={S_read_pipe[READ_DELAY-2:0],S_fire && !I_cmd_wr};
            S_write_pipe<={S_write_pipe[WRITE_DELAY-2:0],S_wr_pending};
            S_read_slot[0]<=S_tail;
            S_write_slot[0]<=S_wr_pending ? S_wr_slot : S_tail;
            for(S_i=1;S_i<READ_DELAY;S_i=S_i+1) S_read_slot[S_i]<=S_read_slot[S_i-1];
            for(S_i=1;S_i<WRITE_DELAY;S_i=S_i+1) S_write_slot[S_i]<=S_write_slot[S_i-1];
            // Align completion candidates with the registered phase check.
            // No result is published before the actual device edge is checked;
            // the half-cycle counter path ends at S_phase_fault_q only.
            S_retire_read<=S_read_pipe[READ_DELAY-1];
            S_retire_write<=S_write_pipe[WRITE_DELAY-1];
            S_retire_read_slot<=S_read_slot[READ_DELAY-1];
            S_retire_write_slot<=S_write_slot[WRITE_DELAY-1];
            S_retire_read_data<=S_read_sample;
            if(S_retire_read && !S_phase_fault_q && !O_clock_fault) begin
                S_complete[S_retire_read_slot]<=1;
                S_data[S_retire_read_slot]<=S_retire_read_data;
            end
            if(S_retire_write && !S_phase_fault_q && !O_clock_fault) begin
                // WRITE was emitted at its shifted edge; DQ hold and tWR expired.
                S_complete[S_retire_write_slot]<=1;
                S_data[S_retire_write_slot]<=0;
            end
            case({S_fire,S_take})
                2'b10:S_count<=S_count+1'b1;
                2'b01:S_count<=S_count-1'b1;
                default:begin end
            endcase
            if(S_take) begin S_complete[S_head]<=0; S_head<=S_head+1'b1; end
            if(S_fire) begin
                S_tags[S_tail]<=I_cmd_tag; S_wr[S_tail]<=I_cmd_wr; S_complete[S_tail]<=0; S_tail<=S_tail+1'b1;
                O_sdram_ba<=S_bank;
                O_sdram_addr<={3'd0,I_cmd_addr[7:0]}; // A10=0: keep the row open.
                if(I_cmd_wr) begin
                    // Pre-drive data now; the WRITE command follows next cycle.
                    S_wr_pending<=1; S_wr_bank<=S_bank; S_wr_col<=I_cmd_addr[7:0];
                    S_wr_mask<=I_cmd_mask; S_wr_slot<=S_tail;
                    S_dq_drive<=1; S_dq_data<=I_cmd_data;
                end else begin
                    {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b101;
                    // DQM also masks reads: every READ and its data window use zero.
                    O_sdram_dm<=0;
                    S_precharge_wait[S_bank]<=CAS_LATENCY+2; S_write_gap<=CAS_LATENCY+3;
                end
            end
            // DQM has read latency. Keep reads unmasked through every pending return.
            if(S_read_pipe!=0) O_sdram_dm<=0;
            if(O_clock_fault || S_phase_fault_q) begin
                // Do not retire a logical WRITE when its device clock never ran.
                // Unknown pin history cannot be repaired by replay or a timeout.
                // A command accepted on the fault-detection edge remains owed.
                // The registered phase fault gates the output pins; the
                // completion checks below still use the live comparison.
                O_clock_fault<=1;
                {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b111;
                S_dq_drive<=0; O_sdram_dm<=15; S_wr_pending<=0;
            end else if(S_wr_pending) begin
                {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b100;
                O_sdram_ba<=S_wr_bank; O_sdram_addr<={3'd0,S_wr_col};
                S_dq_drive<=1; O_sdram_dm<=S_wr_mask;
                S_precharge_wait[S_wr_bank]<=T_WR; S_read_gap<=T_WTR;
                S_wr_pending<=0;
            end else case(S_state)
                POWER:if(S_power_count==INIT_CYCLES-1) begin
                    O_sdram_cke<=1; S_wait<=2; S_state<=WAKE;
                end else S_power_count<=S_power_count+1'b1;
                WAKE:if(S_wait==1) S_state<=INIT_PRE; else S_wait<=S_wait-1'b1;
                INIT_PRE:begin
                    {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b010;
                    O_sdram_addr<=11'h400; S_open<=0; S_wait<=T_RP; S_state<=INIT_RP;
                end
                INIT_RP:if(S_wait==1) S_state<=INIT_REF; else S_wait<=S_wait-1'b1;
                INIT_REF:begin
                    {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b001;
                    S_init_refresh<=S_init_refresh+1'b1; S_wait<=T_RFC; S_state<=INIT_RFC;
                end
                INIT_RFC:if(S_wait==1) S_state<=S_init_refresh==8 ? INIT_MODE : INIT_REF;
                    else S_wait<=S_wait-1'b1;
                INIT_MODE:begin
                    {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b000;
                    O_sdram_addr<=MODE_WORD; S_wait<=T_MRD; S_state<=MODE_WAIT;
                end
                MODE_WAIT:if(S_wait==1) begin O_initialized<=1; S_refresh_count<=0; S_state<=RUN; end
                    else S_wait<=S_wait-1'b1;
                RUN:if(S_refresh_due) S_state<=REF_PRE;
                    else if(I_cmd_valid && S_capacity && !S_row_hit) begin
                        if(S_open[S_bank]) begin
                            if(S_precharge_wait[S_bank]==0 && S_ras_wait[S_bank]==0) begin
                                {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b010;
                                O_sdram_ba<=S_bank; O_sdram_addr<=0; S_open[S_bank]<=0;
                                S_wait<=T_RP; S_state<=ROW_RP;
                            end
                        end else if(S_rc_wait[S_bank]==0 && S_activate_gap==0) begin
                            {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b011;
                            O_sdram_ba<=S_bank; O_sdram_addr<=S_wanted_row;
                            S_open[S_bank]<=1; S_row[S_bank]<=S_wanted_row;
                            S_ras_wait[S_bank]<=T_RAS; S_rc_wait[S_bank]<=T_RC; S_activate_gap<=T_RRD;
                            S_wait<=T_RCD; S_state<=ROW_RCD;
                        end
                    end
                ROW_RP:if(S_wait==1) S_state<=RUN; else S_wait<=S_wait-1'b1;
                ROW_RCD:if(S_wait==1) S_state<=RUN; else S_wait<=S_wait-1'b1;
                REF_PRE:if(S_pipes_empty && S_all_precharge) begin
                    {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b010;
                    O_sdram_addr<=11'h400; S_open<=0; S_wait<=T_RP; S_state<=REF_RP;
                end
                REF_RP:if(S_wait==1) S_state<=DO_REFRESH; else S_wait<=S_wait-1'b1;
                DO_REFRESH:begin
                    {O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n}<=3'b001;
                    S_refresh_count<=0; S_wait<=T_RFC; O_refresh_pulse<=1; S_state<=REF_RFC;
                end
                REF_RFC:if(S_wait==1) S_state<=RUN; else S_wait<=S_wait-1'b1;
                default:begin O_initialized<=0; S_state<=POWER; S_power_count<=0; O_sdram_cke<=0; end
            endcase
        end
    end
    // synthesis translate_off
    initial begin
        if(INIT_CYCLES<4 || REFRESH_CYCLES<32 || REFRESH_CYCLES<=REFRESH_MARGIN ||
            (CAS_LATENCY!=2 && CAS_LATENCY!=3) ||
            T_RP<1 || T_RP>255 || T_RCD<1 || T_RCD>255 || T_RFC<1 || T_RFC>255 ||
            T_RAS<1 || T_RAS>255 || T_RC<T_RAS || T_RC>255 || T_RRD<1 || T_RRD>255 ||
            T_WR<1 || T_WR>255 || T_WTR<1 || T_WTR>255 || T_MRD<1 || T_MRD>255 ||
            SLOT_BITS<2 || SLOT_BITS>6) begin
            $display("FAIL: native_sdram_ctrl invalid timing/queue parameters"); $stop;
        end
    end
    // synthesis translate_on
endmodule
