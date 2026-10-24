# Actual image pins/slot ownership; file/memory/reader proofs remain explicit fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build image_reservation_cdc]
file mkdir $build_dir
cd $build_dir
transcript file image_reservation_cdc.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
foreach source {image_reservation_cdc.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
foreach source {fb_slot_arbiter.v fb_slot_manager.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_image_reservation_cdc.v]
vsim -voptargs=+acc work.tb_image_reservation_cdc
onfinish stop
run -all
if {[examine -radix binary /tb_image_reservation_cdc/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
