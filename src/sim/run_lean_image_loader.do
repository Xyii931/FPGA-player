onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_image_loader]
file mkdir $build_dir
cd $build_dir
transcript file lean_image_loader.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media bmp_parser.v]
vlog -work work [file join $script_dir .. rtl media lean_image_loader.v]
vlog -work work [file join $script_dir tb_lean_image_loader.v]
vsim -voptargs=+acc work.tb_lean_image_loader
onfinish stop
run -all
if {[examine -radix binary /tb_lean_image_loader/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
