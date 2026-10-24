# Starting constraints for the physical player; timing closure is NOT established.
create_clock -name clk_50m -period 20 -waveform {0 10} [get_ports {I_clk_50m}]
derive_clocks
# Review all five PLL outputs, including memory 180 degrees and video 5:1.
# No broad clock-group/false-path exclusions; related paths must remain analyzed.
# CDC mailbox payload constraints, reset recovery/removal, TF input/output delay,
# DDC/TMDS electrical timing and all unconstrained paths require actual TD/IP/
# board specifications. Do not treat this baseline as a complete timing signoff.
