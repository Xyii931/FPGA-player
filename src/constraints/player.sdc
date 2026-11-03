# Starting constraints for the physical player; timing closure is NOT established.
create_clock -name clk_50m -period 20 -waveform {0 10} [get_ports {I_clk_50m}]
derive_clocks
# Review all five PLL outputs: unused SD PLL output 100 MHz, host/memory 83.333333 MHz,
# memory +7 ns / 210 degrees, and video 25/125 MHz.
# Host/video and host/SD cross through FIFO pointers, held payloads, reset
# synchronizers and independent status bits. Bound EVERY crossing to the
# fastest participating source period (10 ns), including the Gray pointers.
# Unlike clock_groups, datapath_only preserves the physical delay bounds;
# TD excludes phase-based hold checks for these asynchronous protocols.
set_max_delay -datapath_only 10 \
    -from [get_clocks {u_pll/u_sys/u_pll.clkc[1]}] \
    -to [get_clocks {u_pll/u_video/u_pll.clkc[0]}]
set_max_delay -datapath_only 10 \
    -from [get_clocks {u_pll/u_video/u_pll.clkc[0]}] \
    -to [get_clocks {u_pll/u_sys/u_pll.clkc[1]}]
set_max_delay -datapath_only 10 \
    -from [get_clocks {u_pll/u_sys/u_pll.clkc[1]}] \
    -to [get_clocks {clk_50m}]
set_max_delay -datapath_only 10 \
    -from [get_clocks {clk_50m}] \
    -to [get_clocks {u_pll/u_sys/u_pll.clkc[1]}]
# Pre-driven SDRAM WRITE data is launched at least one host cycle before the
# WRITE command and held through the device edge. Constrain only the DQ pins
# as a two-cycle path; the hard-IP 5 ns check still applies at the command edge.
# Command/address/mask pins retain the single-cycle 7 ns phase budget.
set_multicycle_path -setup 2 \
    -from [get_clocks {u_pll/u_sys/u_pll.clkc[1]}] \
    -to [get_pins {u_sdram/u_memory.dq[*]}]
set_multicycle_path -hold 1 \
    -from [get_clocks {u_pll/u_sys/u_pll.clkc[1]}] \
    -to [get_pins {u_sdram/u_memory.dq[*]}]
# CDC mailbox payload constraints, reset recovery/removal, TF input/output delay,
# DDC/TMDS electrical timing and all unconstrained paths require actual TD/IP/
# board specifications. Do not treat this baseline as a complete timing signoff.
