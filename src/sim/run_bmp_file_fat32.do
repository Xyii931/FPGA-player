# Real BMP source/parser; protocol endpoints or SD host sectors are fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build bmp_file_fat32]
file mkdir $build_dir
cd $build_dir
transcript file bmp_file_fat32.log
vlib work
vmap work [file join $build_dir work]
foreach source {fat32_mount.v fat32_chain_walk.v fat32_file_reader.v fat32_dir_stream.v fat32_dir_parser.v fat32_directory.v fat32_path_lookup.v fat32_sector_arbiter.v fat32_sector_port.v fat32_core.v} {
    vlog -work work [file join $script_dir .. rtl storage $source]
}
foreach source {bmp_parser.v rle_parser.v image_file_decoder.v bmp_file_source.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_bmp_file_fat32.v]
vsim -voptargs=+acc work.tb_bmp_file_fat32
onfinish stop
run -all
if {[examine -radix binary /tb_bmp_file_fat32/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
