# Real WAV parser and both FIFOs; functional RAM or installed TD models selected by loader.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build wav_track_source]
file mkdir $build_dir
cd $build_dir
transcript file wav_track_source.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl media audio_frame_fifo.v]
vlog -work work [file join $script_dir .. rtl media wav_parser.v]
vlog -work work [file join $script_dir .. rtl media apt_parser.v]
vlog -work work [file join $script_dir .. rtl media audio_file_decoder.v]
vlog -work work [file join $script_dir .. rtl media wav_track_source.v]
vlog -work work [file join $script_dir tb_wav_track_source.v]
vsim -voptargs=+acc work.tb_wav_track_source {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_wav_track_source/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
