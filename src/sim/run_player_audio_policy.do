onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build player_audio_policy]
file mkdir $build_dir
cd $build_dir
transcript file player_audio_policy.log
vlib work
vmap work [file join $build_dir work]
foreach source {common/reset_sync.v media/audio_track_guard.v media/audio_mix.v media/audio_playback.v media/bgm_loop_cdc.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir tb_player_audio_policy.v]
vsim -voptargs=+acc work.tb_player_audio_policy
onfinish stop
run -all
if {[examine -radix binary /tb_player_audio_policy/S_test_pass] ne "1"} {
    echo "FAIL: player audio policy ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
