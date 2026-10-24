# Run with: vsim -c -do "do src/sim/run_reset_sync.do"
# Paths are relative to this script, so other working directories also work.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build reset_sync]
file mkdir $build_dir
cd $build_dir
transcript file reset_sync.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir tb_reset_sync.v]
vsim -voptargs=+acc work.tb_reset_sync
onfinish stop
run -all
if {[examine -radix binary /tb_reset_sync/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
