onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_video]
file mkdir $build_dir
cd $build_dir
transcript file lean_video.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl media bmp_parser.v]
vlog -work work [file join $script_dir .. rtl media lean_image_loader.v]
vlog -work work [file join $script_dir .. rtl display video_timing.v]
vlog -work work [file join $script_dir .. rtl display lean_scanout.v]
vlog -work work [file join $script_dir .. rtl storage native_sdram_ctrl.v]
vlog -work work [file join $script_dir .. rtl storage lean_frame_memory.v]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir models sim_sdr_device.v]
vlog -work work [file join $script_dir tb_lean_video.v]
vsim -voptargs=+acc work.tb_lean_video {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_lean_video/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
