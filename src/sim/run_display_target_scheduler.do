# Actual scheduler and timestamp FIFOs; reference raster/clock availability are fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_target_scheduler]
file mkdir $build_dir
cd $build_dir
transcript file display_target_scheduler.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
foreach source {display_deadline_cdc.v display_deadline_scheduler.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_display_target_scheduler.v]
vsim -voptargs=+acc work.tb_display_target_scheduler
onfinish stop
run -all
if {[examine -radix binary /tb_display_target_scheduler/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
