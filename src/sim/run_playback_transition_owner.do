# Actual transition owner/timeline with explicit executor/audio protocol peers.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build playback_transition_owner]
file mkdir $build_dir
cd $build_dir
transcript file playback_transition_owner.log
vlib work
vmap work [file join $build_dir work]
foreach source {av_event_timeline.v playback_transition_owner.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_playback_transition_owner.v]
vsim -voptargs=+acc work.tb_playback_transition_owner
onfinish stop
run -all
if {[examine -radix binary /tb_playback_transition_owner/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
