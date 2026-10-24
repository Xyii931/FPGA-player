# Real geometry/scaler/rotate/transform/writer/slot manager. Logical completion endpoint.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build image_transform_writer]
file mkdir $build_dir
cd $build_dir
transcript file image_transform_writer.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media image_geometry.v]
vlog -work work [file join $script_dir .. rtl media image_scaler.v]
vlog -work work [file join $script_dir .. rtl media image_rotate.v]
vlog -work work [file join $script_dir .. rtl media image_transform.v]
vlog -work work [file join $script_dir .. rtl display fb_writer.v]
vlog -work work [file join $script_dir .. rtl display fb_slot_manager.v]
vlog -work work [file join $script_dir tb_image_transform_writer.v]
vsim -voptargs=+acc work.tb_image_transform_writer
onfinish stop
run -all
if {[examine -radix binary /tb_image_transform_writer/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
