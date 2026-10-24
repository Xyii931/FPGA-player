# Logical protocol endpoints only; does not validate physical SDRAM or SD timing.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build bmp_frame_loader]
file mkdir $build_dir
cd $build_dir
transcript file bmp_frame_loader.log
vlib work
vmap work [file join $build_dir work]
foreach source {bmp_parser.v rle_parser.v image_file_decoder.v bmp_file_source.v image_geometry.v image_scaler.v image_rotate.v image_transform.v layout_geometry.v bmp_frame_load_ctrl.v bmp_frame_loader.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
foreach source {fb_writer.v fb_slot_manager.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_bmp_frame_loader.v]
vsim -voptargs=+acc work.tb_bmp_frame_loader
onfinish stop
run -all
if {[examine -radix binary /tb_bmp_frame_loader/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
