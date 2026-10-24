# Real WAV file owner; peers, or SD sectors plus a no-pipeline PCM sink, are fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build wav_file_source]
file mkdir $build_dir
cd $build_dir
transcript file wav_file_source.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media wav_file_source.v]
vlog -work work [file join $script_dir tb_wav_file_source.v]
vsim -voptargs=+acc work.tb_wav_file_source
onfinish stop
run -all
if {[examine -radix binary /tb_wav_file_source/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
