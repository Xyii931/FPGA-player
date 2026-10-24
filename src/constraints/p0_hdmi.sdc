# P0 diagnostic starting constraints, NOT a timing-closure claim.
create_clock -name clk_50m -period 20 -waveform {0 10} [get_ports {I_clk_50m}]
# TD derives EG_PHY_PLL output clocks from their actual primitive parameters.
derive_clocks
# Deliberately no exclusive/asynchronous grouping of pixel and 5x clocks.
# Preserve all real timing paths through the reused reference PHY.
# No broad false paths or invented IO delays. Review unconstrained paths,
# asynchronous key/switch entry, reset recovery/removal, DDC and TMDS using
# board/IP specifications and actual TD reports before declaring P0 passed.
# The unused system PLL clock outputs may be optimized out of this video-only
# build; use a separate clock/storage experiment to validate those outputs.
