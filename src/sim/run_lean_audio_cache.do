onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_audio_cache]
file mkdir $build_dir
cd $build_dir
transcript file lean_audio_cache.log
vlib work
vmap work [file join $build_dir work]
foreach name {lean_audio_cache} {
    vlog -work work [file join $script_dir .. rtl media ${name}.v]
}
foreach name {native_sdram_ctrl lean_frame_memory} {
    vlog -work work [file join $script_dir .. rtl storage ${name}.v]
}
vlog -work work [file join $script_dir models sim_sdr_device.v]
vlog -work work [file join $script_dir tb_lean_audio_cache.v]
set test_args {}
if {[info exists ::env(FPGA_PLAYER_CACHE_FULL)] && $::env(FPGA_PLAYER_CACHE_FULL) eq "1"} {set test_args {+FULL_CAPACITY}}
vsim -voptargs=+acc work.tb_lean_audio_cache {*}$test_args
onfinish stop
run -all
if {[examine -radix binary /tb_lean_audio_cache/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
