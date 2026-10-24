# Project WAV/APT0 parsers only; no vendor libraries or external assets.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build audio_file_decoder]
file mkdir $build_dir
cd $build_dir
transcript file audio_file_decoder.log
vlib work
vmap work [file join $build_dir work]
foreach source {wav_parser apt_parser audio_file_decoder} {
    vlog -work work [file join $script_dir .. rtl media $source.v]
}
vlog -work work [file join $script_dir tb_audio_file_decoder.v]
vsim -voptargs=+acc work.tb_audio_file_decoder
onfinish stop
run -all
if {[examine -radix binary /tb_audio_file_decoder/S_test_pass] ne "1"} {
    echo "FAIL: decoder ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
