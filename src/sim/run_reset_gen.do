# Run from repository root: vsim -c -do "do src/sim/run_reset_gen.do"
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build reset_gen]
file mkdir $build_dir
cd $build_dir
transcript file reset_gen.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common reset_gen.v]
vlog -work work [file join $script_dir tb_reset_gen.v]
vsim -voptargs=+acc work.tb_reset_gen
onfinish stop
run -all
if {[examine -radix binary /tb_reset_gen/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
