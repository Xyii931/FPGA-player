# AV event timeline; video execution is an explicit peer. No physical memory or HDMI verification.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build av_timeline_wav]
file mkdir $build_dir
cd $build_dir
transcript file av_timeline_wav.log
vlib work
vmap work [file join $build_dir work]
foreach source {common/reset_sync.v common/async_fifo.v common/samp_tick.v display/video_timing.v display/transition_plan.v media/av_event_timeline.v media/audio_frame_fifo.v media/wav_parser.v media/apt_parser.v media/audio_file_decoder.v media/wav_track_source.v media/audio_track_guard.v media/audio_mix.v media/audio_playback.v media/audio_slot_recycle.v media/wav_audio_slot.v media/audio_prepare_guard.v media/wav_audio_prepared.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir tb_av_timeline_wav.v]
vsim -voptargs=+acc work.tb_av_timeline_wav
onfinish stop
run -all
if {[examine -radix binary /tb_av_timeline_wav/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
