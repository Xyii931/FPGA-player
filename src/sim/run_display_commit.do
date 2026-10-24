# Real CDC FIFOs, explicit prepare and true-retirement protocol endpoints.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_commit]
file mkdir $build_dir
cd $build_dir
transcript file display_commit.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
vlog -work work [file join $script_dir .. rtl display frame_commit_cdc.v]
vlog -work work [file join $script_dir .. rtl display display_commit.v]
foreach source {fb_line_reader.v fb_reader.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_display_commit.v]
vsim -voptargs=+acc work.tb_display_commit
onfinish stop
run -all
if {[examine -radix binary /tb_display_commit/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
