# Integration uses real FIFOs/guards/mixer; RAM implementation selected by loader.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build audio_playback]
file mkdir $build_dir
cd $build_dir
transcript file audio_playback.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl media audio_frame_fifo.v]
vlog -work work [file join $script_dir .. rtl media audio_track_guard.v]
vlog -work work [file join $script_dir .. rtl media audio_mix.v]
vlog -work work [file join $script_dir .. rtl media audio_playback.v]
vlog -work work [file join $script_dir tb_audio_playback.v]
vsim -voptargs=+acc work.tb_audio_playback {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_audio_playback/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
