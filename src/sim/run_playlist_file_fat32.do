# Real FAT32 + file source + parser + store; only the SD sector endpoint is stimulus.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build playlist_file_fat32]
file mkdir $build_dir
cd $build_dir
transcript file playlist_file_fat32.log
vlib work
vmap work [file join $build_dir work]
foreach source {fat32_mount.v fat32_chain_walk.v fat32_file_reader.v fat32_dir_stream.v fat32_dir_parser.v fat32_directory.v fat32_path_lookup.v fat32_sector_arbiter.v fat32_sector_port.v fat32_core.v} {
    vlog -work work [file join $script_dir .. rtl storage $source]
}
foreach source {playlist_parser.v media_index_store.v directory_index_source.v playlist_index_builder.v playlist_file_source.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_playlist_file_fat32.v]
vsim -voptargs=+acc work.tb_playlist_file_fat32
onfinish stop
run -all
if {[examine -radix binary /tb_playlist_file_fat32/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
