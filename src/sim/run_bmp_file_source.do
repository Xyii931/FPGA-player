# Real BMP source/parser; protocol endpoints or SD host sectors are fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build bmp_file_source]
file mkdir $build_dir
cd $build_dir
transcript file bmp_file_source.log
vlib work
vmap work [file join $build_dir work]
foreach source {bmp_parser.v rle_parser.v image_file_decoder.v bmp_file_source.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_bmp_file_source.v]
vsim -voptargs=+acc work.tb_bmp_file_source
onfinish stop
run -all
if {[examine -radix binary /tb_bmp_file_source/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
