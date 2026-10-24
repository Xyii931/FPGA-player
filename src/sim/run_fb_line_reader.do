# Real CDC FIFO and line RAMs, logical variable-latency memory endpoints only.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build fb_line_reader]
file mkdir $build_dir
cd $build_dir
transcript file fb_line_reader.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
vlog -work work [file join $script_dir .. rtl display fb_line_reader.v]
vlog -work work [file join $script_dir tb_fb_line_reader.v]
vsim -voptargs=+acc work.tb_fb_line_reader
onfinish stop
run -all
if {[examine -radix binary /tb_fb_line_reader/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
