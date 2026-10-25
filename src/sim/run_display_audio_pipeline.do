# Actual WAV preparation and deadline scheduler with full display resources/slot manager.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_audio_pipeline]
file mkdir $build_dir
cd $build_dir
transcript file display_audio_pipeline.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
foreach source {video_timing.v transition_plan.v transition_map.v blend_unit.v fb_slot_manager.v display_lease_ctrl.v display_source_guard.v fb_line_reader.v fb_reader.v frame_commit_cdc.v display_lease_cdc.v display_candidate_ctrl.v display_reader_arbiter.v scanout_engine.v video_color_adjust.v display_video_pipeline.v display_host_owner.v display_resource_pipeline.v display_deadline_cdc.v display_deadline_scheduler.v display_timed_pipeline.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
foreach source {media/audio_frame_fifo.v media/wav_parser.v media/apt_parser.v media/audio_file_decoder.v media/wav_track_source.v media/audio_track_guard.v media/audio_mix.v media/audio_playback.v media/audio_slot_recycle.v media/wav_audio_slot.v media/audio_prepare_guard.v media/wav_audio_prepared.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir tb_display_audio_pipeline.v]
vsim -voptargs=+acc work.tb_display_audio_pipeline {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_display_audio_pipeline/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
