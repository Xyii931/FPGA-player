# Byte fixtures only: no filesystem, SD card, vendor IP or index commit model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build playlist_parser]
file mkdir $build_dir
cd $build_dir
transcript file playlist_parser.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media playlist_parser.v]
vlog -work work [file join $script_dir tb_playlist_parser.v]
vsim -voptargs=+acc work.tb_playlist_parser
onfinish stop
run -all
if {[examine -radix binary /tb_playlist_parser/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
