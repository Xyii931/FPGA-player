onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build fat32_directory]
file mkdir $build_dir
cd $build_dir
transcript file fat32_directory.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage fat32_chain_walk.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_stream.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_parser.v]
vlog -work work [file join $script_dir .. rtl storage fat32_directory.v]
vlog -work work [file join $script_dir tb_fat32_directory.v]
vsim -voptargs=+acc work.tb_fat32_directory
onfinish stop
run -all
if {[examine -radix binary /tb_fat32_directory/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
