# Real BMP parser/scaler; selectable RAM model, no filesystem/framebuffer substitute.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build bmp_image_scaler]
file mkdir $build_dir
cd $build_dir
transcript file bmp_image_scaler.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir .. rtl media bmp_parser.v]
vlog -work work [file join $script_dir .. rtl media image_scaler.v]
vlog -work work [file join $script_dir tb_bmp_image_scaler.v]
vsim -voptargs=+acc work.tb_bmp_image_scaler {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_bmp_image_scaler/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
