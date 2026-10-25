onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_audio]
file mkdir $build_dir
cd $build_dir
transcript file lean_audio.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl common samp_tick.v]
vlog -work work [file join $script_dir .. rtl common acr_gen.v]
vlog -work work [file join $script_dir .. rtl media wav_parser.v]
vlog -work work [file join $script_dir .. rtl media audio_frame_fifo.v]
vlog -work work [file join $script_dir .. rtl media lean_audio.v]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir tb_lean_audio.v]
vsim -voptargs=+acc work.tb_lean_audio {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_lean_audio/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
