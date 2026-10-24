# Run from repository root: vsim -c -do "do src/sim/run_p0_video_source.do"
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build p0_video_source]
file mkdir $build_dir
cd $build_dir
transcript file p0_video_source.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display video_timing.v]
vlog -work work [file join $script_dir .. rtl display video_test_pattern.v]
vlog -work work [file join $script_dir .. rtl display p0_video_source.v]
vlog -work work [file join $script_dir tb_p0_video_source.v]
vsim -voptargs=+acc work.tb_p0_video_source
onfinish stop
run -all
if {[examine -radix binary /tb_p0_video_source/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
