onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_player_core]
file mkdir $build_dir
cd $build_dir
transcript file lean_player_core.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common acr_gen.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common samp_tick.v]
vlog -work work [file join $script_dir .. rtl display ascii_font8x16.v]
vlog -work work [file join $script_dir .. rtl display video_timing.v]
vlog -work work [file join $script_dir .. rtl media audio_frame_fifo.v]
vlog -work work [file join $script_dir .. rtl media bmp_parser.v]
vlog -work work [file join $script_dir .. rtl media wav_parser.v]
vlog -work work [file join $script_dir .. rtl storage fat32_chain_walk.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_stream.v]
vlog -work work [file join $script_dir .. rtl storage fat32_file_reader.v]
vlog -work work [file join $script_dir .. rtl storage fat32_mount.v]
vlog -work work [file join $script_dir .. rtl storage fat32_sector_port.v]
vlog -work work [file join $script_dir .. rtl storage lean_root_scan.v]
vlog -work work [file join $script_dir .. rtl storage lean_media_source.v]
vlog -work work [file join $script_dir .. rtl display lean_scanout.v]
vlog -work work [file join $script_dir .. rtl display lean_status_osd.v]
vlog -work work [file join $script_dir .. rtl media lean_audio.v]
vlog -work work [file join $script_dir .. rtl media lean_image_loader.v]
vlog -work work [file join $script_dir .. rtl top lean_player_core.v]
vlog -work work [file join $script_dir .. rtl top lean_player_ctrl.v]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir models sim_lean_media_card.v]
vlog -work work [file join $script_dir tb_lean_player_core.v]
vsim -voptargs=+acc work.tb_lean_player_core {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_lean_player_core/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
