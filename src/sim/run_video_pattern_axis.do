# User-run self-test; no encrypted core or vendor simulation library required.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build video_pattern_axis]
file mkdir $build_dir
cd $build_dir
transcript file video_pattern_axis.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display video_pattern_axis.v]
vlog -work work [file join $script_dir tb_video_pattern_axis.v]
vsim -voptargs=+acc work.tb_video_pattern_axis
onfinish stop
run -all
if {[examine -radix binary /tb_video_pattern_axis/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
