# Pixel-domain audio building blocks only; no encrypted/vendor IP required.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build audio_foundation]
file mkdir $build_dir
cd $build_dir
transcript file audio_foundation.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common samp_tick.v]
vlog -work work [file join $script_dir .. rtl common acr_gen.v]
vlog -work work [file join $script_dir .. rtl media pcm16_to_pcm24.v]
vlog -work work [file join $script_dir tb_audio_foundation.v]
vsim -voptargs=+acc work.tb_audio_foundation
onfinish stop
run -all
if {[examine -radix binary /tb_audio_foundation/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
