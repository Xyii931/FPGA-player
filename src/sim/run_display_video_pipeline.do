# Real CDC, resource owners, scanout, reader and RAM; logical memory fixture only.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_video_pipeline]
file mkdir $build_dir
cd $build_dir
transcript file display_video_pipeline.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
foreach source {video_timing.v transition_plan.v transition_map.v blend_unit.v fb_line_reader.v fb_reader.v frame_commit_cdc.v display_candidate_ctrl.v display_reader_arbiter.v scanout_engine.v video_color_adjust.v display_video_pipeline.v} {
    vlog -work work [file join $script_dir .. rtl display $source]
}
vlog -work work [file join $script_dir tb_display_video_pipeline.v]
vsim -voptargs=+acc work.tb_display_video_pipeline
onfinish stop
run -all
if {[examine -radix binary /tb_display_video_pipeline/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
