# Project arithmetic RTL only; no physical display/memory timing assumptions.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build transition_pixel]
file mkdir $build_dir
cd $build_dir
transcript file transition_pixel.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display transition_plan.v]
vlog -work work [file join $script_dir .. rtl display transition_map.v]
vlog -work work [file join $script_dir .. rtl display blend_unit.v]
vlog -work work [file join $script_dir tb_transition_pixel.v]
vsim -voptargs=+acc work.tb_transition_pixel
onfinish stop
run -all
if {[examine -radix binary /tb_transition_pixel/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
