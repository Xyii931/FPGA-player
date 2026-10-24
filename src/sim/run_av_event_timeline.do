# AV event timeline; video execution is an explicit peer. No physical memory or HDMI verification.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build av_event_timeline]
file mkdir $build_dir
cd $build_dir
transcript file av_event_timeline.log
vlib work
vmap work [file join $build_dir work]
foreach source {common/reset_sync.v common/async_fifo.v common/samp_tick.v display/video_timing.v display/transition_plan.v media/av_event_timeline.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir tb_av_event_timeline.v]
vsim -voptargs=+acc work.tb_av_event_timeline
onfinish stop
run -all
if {[examine -radix binary /tb_av_event_timeline/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
