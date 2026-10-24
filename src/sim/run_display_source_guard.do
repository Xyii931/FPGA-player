# Real dual-clock reader and lock owner; external reference proofs are explicit.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_source_guard]
file mkdir $build_dir
cd $build_dir
transcript file display_source_guard.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl display fb_slot_manager.v]
vlog -work work [file join $script_dir .. rtl display display_lease_ctrl.v]
vlog -work work [file join $script_dir .. rtl display display_source_guard.v]
vlog -work work [file join $script_dir .. rtl display fb_line_reader.v]
vlog -work work [file join $script_dir .. rtl display fb_reader.v]
vlog -work work [file join $script_dir tb_display_source_guard.v]
vsim -voptargs=+acc work.tb_display_source_guard
onfinish stop
run -all
if {[examine -radix binary /tb_display_source_guard/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
