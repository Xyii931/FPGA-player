# Elaborate the actual TF/BMP/two-WAV/transition/display hierarchy, then test stop CDC.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build player_av_core]
file mkdir $build_dir
cd $build_dir
transcript file player_av_core.log
vlib work
vmap work [file join $build_dir work]
foreach folder {common storage media display} {
    foreach source [lsort [glob -directory [file join $script_dir .. rtl $folder] *.v]] {
        vlog -work work $source
    }
}
vlog -work work [file join $script_dir .. rtl top media_io.v]
vlog -work work [file join $script_dir .. rtl top player_av_core.v]
vlog -work work [file join $script_dir .. rtl top player_autoplay.v]
vlog -work work [file join $script_dir tb_audio_stop_cdc.v]
vlog -work work [file join $script_dir tb_player_control.v]
vlog -work work [file join $script_dir tb_media_item_fetch.v]
# No run: this checks resolution/parameters of the complete real AV component chain.
vsim -voptargs=+acc work.player_av_core
quit -sim
vsim -voptargs=+acc work.player_autoplay
quit -sim
foreach test {tb_audio_stop_cdc tb_player_control tb_media_item_fetch} {
    vsim -voptargs=+acc work.$test
    onfinish stop
    run -all
    if {[examine -radix binary /$test/S_test_pass] ne "1"} {
        echo "FAIL: simulation ended without a passing result: $test"
        quit -force -code 1
    }
    quit -sim
}
quit -force -code 0
