# Project arithmetic RTL only; no physical display/memory timing assumptions.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build blend_unit]
file mkdir $build_dir
cd $build_dir
transcript file blend_unit.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display blend_unit.v]
vlog -work work [file join $script_dir tb_blend_unit.v]
vsim -voptargs=+acc work.tb_blend_unit
onfinish stop
run -all
if {[examine -radix binary /tb_blend_unit/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
