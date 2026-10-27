# Starting constraints for the physical player; timing closure is NOT established.
create_clock -name clk_50m -period 20 -waveform {0 10} [get_ports {I_clk_50m}]
derive_clocks
# Review all five PLL outputs, including memory 180 degrees and video 5:1.
# The 25 MHz video and 125 MHz host domains cross only through async_fifo
# Gray-pointer synchronizers (scanout commit/event/reply, status, audio) and
# reset_sync chains. Keep every intra-domain and memory path analyzed; exclude
# only this audited CDC pair. All other clock relationships remain analyzed.
set_clock_groups -asynchronous \
    -group [get_clocks {u_pll/u_video/u_pll.clkc[0]}] \
    -group [get_clocks {u_pll/u_sys/u_pll.clkc[1]}]
# Pre-driven SDRAM WRITE data is launched at least one host cycle before the
# WRITE command and held through the device edge. Constrain only the DQ pins
# as a two-cycle path; the hard-IP 5 ns check still applies at the command edge.
set_multicycle_path -setup 2 \
    -from [get_clocks {u_pll/u_sys/u_pll.clkc[1]}] \
    -to [get_pins {u_sdram/u_memory.dq[*]}]
set_multicycle_path -hold 1 \
    -from [get_clocks {u_pll/u_sys/u_pll.clkc[1]}] \
    -to [get_pins {u_sdram/u_memory.dq[*]}]
# CDC mailbox payload constraints, reset recovery/removal, TF input/output delay,
# DDC/TMDS electrical timing and all unconstrained paths require actual TD/IP/
# board specifications. Do not treat this baseline as a complete timing signoff.
