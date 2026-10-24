# Real CDC FIFOs, explicit prepare and true-retirement protocol endpoints.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build frame_commit_cdc]
file mkdir $build_dir
cd $build_dir
transcript file frame_commit_cdc.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
vlog -work work [file join $script_dir .. rtl display frame_commit_cdc.v]
vlog -work work [file join $script_dir tb_frame_commit_cdc.v]
vsim -voptargs=+acc work.tb_frame_commit_cdc
onfinish stop
run -all
if {[examine -radix binary /tb_frame_commit_cdc/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
