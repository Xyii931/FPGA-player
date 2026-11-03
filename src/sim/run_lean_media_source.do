onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_media_source]
file mkdir $build_dir
cd $build_dir
transcript file lean_media_source.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage fat32_sector_port.v]
vlog -work work [file join $script_dir .. rtl storage fat32_mount.v]
vlog -work work [file join $script_dir .. rtl storage fat32_chain_walk.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_stream.v]
vlog -work work [file join $script_dir .. rtl storage fat32_file_reader.v]
vlog -work work [file join $script_dir .. rtl storage lean_root_scan.v]
vlog -work work [file join $script_dir .. rtl storage lean_media_source.v]
vlog -work work [file join $script_dir tb_lean_media_source.v]
vsim -voptargs=+acc work.tb_lean_media_source
onfinish stop
run -all
if {[examine -radix binary /tb_lean_media_source/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
