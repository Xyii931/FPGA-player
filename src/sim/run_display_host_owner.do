# Real host owner, lease/guard/slot/commit CDC/reader; publication/video refs are endpoints.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_host_owner]
file mkdir $build_dir
cd $build_dir
transcript file display_host_owner.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
foreach source {fb_slot_manager.v display_lease_ctrl.v display_source_guard.v frame_commit_cdc.v fb_line_reader.v fb_reader.v display_host_owner.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_display_host_owner.v]
vsim -voptargs=+acc work.tb_display_host_owner
onfinish stop
run -all
if {[examine -radix binary /tb_display_host_owner/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
