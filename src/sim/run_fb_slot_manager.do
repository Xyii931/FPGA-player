# Real slot manager. Retirement and frame boundaries are explicit protocol inputs.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build fb_slot_manager]
file mkdir $build_dir
cd $build_dir
transcript file fb_slot_manager.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display fb_slot_manager.v]
vlog -work work [file join $script_dir tb_fb_slot_manager.v]
vsim -voptargs=+acc work.tb_fb_slot_manager
onfinish stop
run -all
if {[examine -radix binary /tb_fb_slot_manager/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
