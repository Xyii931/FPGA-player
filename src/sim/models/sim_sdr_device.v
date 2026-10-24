`timescale 1ns/1ps
// TEST ONLY: independent command-level SDR fixture, not a vendor timing library.
// Loaded only by run_frame_memory.do. Cannot prove tAC/tOH, board phase or TD support.
module sim_sdr_device #(
    parameter integer CAS_LATENCY=3,
    parameter integer T_RP=3,T_RCD=3,T_RFC=10,T_RAS=6,T_RC=9,
    parameter integer T_RRD=2,T_WR=3,T_WTR=2,T_MRD=2
) (
    input wire I_clk,I_reset,I_cke,I_ras_n,I_cas_n,I_we_n,
    input wire [10:0] I_addr,
    input wire [1:0] I_ba,
    input wire [3:0] I_dm,
    inout wire [31:0] IO_dq,
    output reg O_fault,
    output reg [31:0] O_reads,O_writes,O_refreshes
);
    reg [31:0] S_memory[0:2097151];
    reg [3:0] S_open,S_drive;
    reg [10:0] S_rows[0:3];
    integer S_cycle,S_activate[0:3],S_precharge[0:3],S_write[0:3],S_read[0:3];
    integer S_last_activate,S_last_refresh,S_last_write,S_last_mode,S_initial_refresh,S_i;
    reg S_mode;
    reg [CAS_LATENCY-1:0] S_read_valid;
    reg [31:0] S_read_data[0:CAS_LATENCY-1];
    reg [3:0] S_dm0,S_dm1;
    reg [31:0] S_dq;
    wire [2:0] S_command={I_ras_n,I_cas_n,I_we_n};
    wire [20:0] S_address={S_rows[I_ba],I_ba,I_addr[7:0]};
    genvar lane;
    generate for(lane=0;lane<4;lane=lane+1) begin: g_dq
        assign IO_dq[lane*8+:8]=S_drive[lane] ? S_dq[lane*8+:8] : 8'bz;
    end endgenerate
    task fail;
        input [767:0] message;
        begin O_fault=1; $display("FAIL SDR fixture cycle %0d: %0s",S_cycle,message); $finish; end
    endtask
    always @(posedge I_clk) begin
        if(I_reset) begin
            S_cycle=0; S_open=0; S_mode=0; S_initial_refresh=0;
            S_last_activate=-1000; S_last_refresh=-1000; S_last_write=-1000; S_last_mode=-1000;
            S_read_valid<=0; S_drive<=0; S_dq<=0; S_dm0<=15; S_dm1<=15;
            O_fault=0; O_reads=0; O_writes=0; O_refreshes=0;
            for(S_i=0;S_i<4;S_i=S_i+1) begin
                S_rows[S_i]=0; S_activate[S_i]=-1000; S_precharge[S_i]=-1000;
                S_write[S_i]=-1000; S_read[S_i]=-1000;
            end
            for(S_i=0;S_i<CAS_LATENCY;S_i=S_i+1) S_read_data[S_i]<=0;
        end else begin
            S_cycle=S_cycle+1;
            S_dm0<=I_dm; S_dm1<=S_dm0;
            S_read_valid<={S_read_valid[CAS_LATENCY-2:0],1'b0};
            for(S_i=1;S_i<CAS_LATENCY;S_i=S_i+1) S_read_data[S_i]<=S_read_data[S_i-1];
            // Positive tAC stand-in: value changes AFTER the device edge, so the
            // controller must capture the preceding value at the following edge.
            if(S_read_valid[CAS_LATENCY-1]) begin
                S_dq<=#1 S_read_data[CAS_LATENCY-1]; S_drive<=#1 ~S_dm1;
            end else S_drive<=#1 0;
            if(I_cke && S_command!=3'b111) begin
                if(S_cycle-S_last_refresh<T_RFC) fail("command inside tRFC");
                if(S_cycle-S_last_mode<T_MRD) fail("command inside tMRD");
                case(S_command)
                    3'b011:begin
                        if(S_open[I_ba] || S_cycle-S_precharge[I_ba]<T_RP ||
                            S_cycle-S_activate[I_ba]<T_RC || S_cycle-S_last_activate<T_RRD) fail("ACT timing/open bank");
                        S_open[I_ba]=1; S_rows[I_ba]=I_addr; S_activate[I_ba]=S_cycle; S_last_activate=S_cycle;
                    end
                    3'b010:begin
                        for(S_i=0;S_i<4;S_i=S_i+1) if(I_addr[10] || S_i==I_ba) begin
                            if(S_open[S_i] && (S_cycle-S_activate[S_i]<T_RAS || S_cycle-S_write[S_i]<T_WR ||
                                S_cycle-S_read[S_i]<CAS_LATENCY+1)) fail("PRE before row/write/read retirement");
                            S_open[S_i]=0; S_precharge[S_i]=S_cycle;
                        end
                    end
                    3'b001:begin
                        if(S_open!=0) fail("refresh with open row");
                        for(S_i=0;S_i<4;S_i=S_i+1)
                            if(S_cycle-S_precharge[S_i]<T_RP) fail("refresh before tRP");
                        S_last_refresh=S_cycle; O_refreshes=O_refreshes+1;
                        if(!S_mode) S_initial_refresh=S_initial_refresh+1;
                    end
                    3'b000:begin
                        if(S_open!=0 || S_initial_refresh<8 || I_addr!=(11'h200 | (CAS_LATENCY<<4)) || I_ba!=0)
                            fail("MRS/init/BL1/CAS configuration");
                        S_mode=1; S_last_mode=S_cycle;
                    end
                    3'b100:begin
                        if(!S_mode || !S_open[I_ba] || S_cycle-S_activate[I_ba]<T_RCD || I_addr[10])
                            fail("WRITE without valid open row");
                        if(S_drive!=0) fail("controller/device DQ contention");
                        for(S_i=0;S_i<4;S_i=S_i+1) if(!I_dm[S_i]) begin
                            if((^IO_dq[S_i*8+:8])===1'bx) fail("WRITE sampled X/Z");
                            S_memory[S_address][S_i*8+:8]=IO_dq[S_i*8+:8];
                        end
                        S_write[I_ba]=S_cycle; S_last_write=S_cycle; O_writes=O_writes+1;
                    end
                    3'b101:begin
                        if(!S_mode || !S_open[I_ba] || S_cycle-S_activate[I_ba]<T_RCD ||
                            S_cycle-S_last_write<T_WTR || I_addr[10]) fail("READ row/turnaround timing");
                        S_read_valid[0]<=1; S_read_data[0]<=S_memory[S_address];
                        S_read[I_ba]=S_cycle; O_reads=O_reads+1;
                    end
                    default:fail("unsupported SDR command");
                endcase
            end
        end
    end
endmodule
