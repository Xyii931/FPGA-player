# Real FAT32 files/enumeration + shared index; SD endpoint and selectable RAM model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build directory_index_fat32]
file mkdir $build_dir
cd $build_dir
transcript file directory_index_fat32.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
foreach source {fat32_mount.v fat32_chain_walk.v fat32_file_reader.v fat32_dir_stream.v fat32_dir_parser.v fat32_directory.v fat32_path_lookup.v fat32_sector_arbiter.v fat32_sector_port.v fat32_core.v} {
    vlog -work work [file join $script_dir .. rtl storage $source]
}
foreach source {playlist_parser.v media_index_store.v directory_index_source.v playlist_index_builder.v playlist_file_source.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_directory_index_fat32.v]
vsim -voptargs=+acc work.tb_directory_index_fat32 {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_directory_index_fat32/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
