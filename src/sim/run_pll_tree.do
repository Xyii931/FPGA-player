# Run from repository root: vsim -c -do "do src/sim/run_pll_tree.do"
# Wiring/reset integration only: ideal substitutes, no vendor library required.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build pll_tree]
file mkdir $build_dir
cd $build_dir
transcript file pll_tree.log
vlib work
vmap work [file join $build_dir work]
# Do NOT also compile src/ip/player_*_pll.v into this simulation library.
vlog -work work [file join $script_dir models player_pll_models.v]
vlog -work work [file join $script_dir .. rtl common pll_tree.v]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common reset_gen.v]
vlog -work work [file join $script_dir tb_pll_tree.v]
vsim -voptargs=+acc work.tb_pll_tree
onfinish stop
run -all
if {[examine -radix binary /tb_pll_tree/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
