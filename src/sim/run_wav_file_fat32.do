# Real WAV file owner; peers, or SD sectors plus a no-pipeline PCM sink, are fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build wav_file_fat32]
file mkdir $build_dir
cd $build_dir
transcript file wav_file_fat32.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
foreach source {fat32_mount.v fat32_chain_walk.v fat32_file_reader.v fat32_dir_stream.v fat32_dir_parser.v fat32_directory.v fat32_path_lookup.v fat32_sector_arbiter.v fat32_sector_port.v fat32_core.v} {
    vlog -work work [file join $script_dir .. rtl storage $source]
}
foreach source {common/reset_sync.v common/async_fifo.v media/audio_frame_fifo.v media/wav_parser.v media/apt_parser.v media/audio_file_decoder.v media/wav_track_source.v media/audio_slot_recycle.v media/wav_audio_slot.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir .. rtl media wav_file_source.v]
vlog -work work [file join $script_dir tb_wav_file_fat32.v]
vsim -voptargs=+acc work.tb_wav_file_fat32 {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_wav_file_fat32/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
