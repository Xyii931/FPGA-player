onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build resident_frame]
file mkdir $build_dir
cd $build_dir
transcript file resident_frame.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media resident_frame_init.v]
vlog -work work [file join $script_dir .. rtl display slot_cmd_mux2.v]
vlog -work work [file join $script_dir .. rtl display fb_slot_manager.v]
vlog -work work [file join $script_dir tb_resident_frame.v]
vsim -voptargs=+acc work.tb_resident_frame
onfinish stop
run -all
if {[examine -radix binary /tb_resident_frame/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
