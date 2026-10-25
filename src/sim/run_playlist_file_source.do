# Real file source / builder / parser / store; FAT32 endpoint and selectable RAM model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build playlist_file_source]
file mkdir $build_dir
cd $build_dir
transcript file playlist_file_source.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
foreach source {playlist_parser.v media_index_store.v directory_index_source.v playlist_index_builder.v playlist_file_source.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_playlist_file_source.v]
vsim -voptargs=+acc work.tb_playlist_file_source {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_playlist_file_source/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
