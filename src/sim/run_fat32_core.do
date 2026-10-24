onerror {quit -force -code 1}
onbreak {quit -force -code 1}
# The real core now also enumerates directories; keep the same batch/log entry.
# No PLL/SD SPI substitutes or exclusive volume/files wrappers are loaded here.
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build fat32_core]
file mkdir $build_dir
cd $build_dir
transcript file fat32_core.log
vlib work
vmap work [file join $build_dir work]
foreach source {fat32_sector_port.v fat32_mount.v fat32_chain_walk.v fat32_dir_stream.v fat32_dir_parser.v fat32_directory.v fat32_path_lookup.v fat32_file_reader.v fat32_sector_arbiter.v fat32_core.v} {
    vlog -work work [file join $script_dir .. rtl storage $source]
}
vlog -work work [file join $script_dir tb_fat32_core.v]
vsim -voptargs=+acc work.tb_fat32_core
onfinish stop
run -all
if {[examine -radix binary /tb_fat32_core/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
