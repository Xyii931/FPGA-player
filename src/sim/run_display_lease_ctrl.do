# Real project lock controller and slot manager. No physical retirement assumptions.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_lease_ctrl]
file mkdir $build_dir
cd $build_dir
transcript file display_lease_ctrl.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display fb_slot_manager.v]
vlog -work work [file join $script_dir .. rtl display display_lease_ctrl.v]
vlog -work work [file join $script_dir tb_display_lease_ctrl.v]
vsim -voptargs=+acc work.tb_display_lease_ctrl
onfinish stop
run -all
if {[examine -radix binary /tb_display_lease_ctrl/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
