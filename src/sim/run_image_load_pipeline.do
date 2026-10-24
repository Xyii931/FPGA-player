# Actual automatic image owner + BMP loader + slot/pin chain; explicit file/memory/reader peers.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build image_load_pipeline]
file mkdir $build_dir
cd $build_dir
transcript file image_load_pipeline.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
foreach source {image_reservation_cdc.v image_load_owner.v image_load_pipeline.v bmp_parser.v rle_parser.v image_file_decoder.v bmp_file_source.v image_geometry.v image_scaler.v image_rotate.v image_transform.v layout_geometry.v bmp_frame_load_ctrl.v bmp_frame_loader.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
foreach source {fb_slot_arbiter.v fb_slot_manager.v fb_writer.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_image_load_pipeline.v]
vsim -voptargs=+acc work.tb_image_load_pipeline
onfinish stop
run -all
if {[examine -radix binary /tb_image_load_pipeline/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
