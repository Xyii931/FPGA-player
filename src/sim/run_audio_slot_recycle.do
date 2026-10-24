# Protocol test only; external file/player completion is explicitly driven.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build audio_slot_recycle]
file mkdir $build_dir
cd $build_dir
transcript file audio_slot_recycle.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl media audio_slot_recycle.v]
vlog -work work [file join $script_dir tb_audio_slot_recycle.v]
vsim -voptargs=+acc work.tb_audio_slot_recycle
onfinish stop
run -all
if {[examine -radix binary /tb_audio_slot_recycle/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
