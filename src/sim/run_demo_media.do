onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build demo_media]
file mkdir $build_dir
cd $build_dir
transcript file demo_media.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl storage flash_read_cdc.v]
vlog -work work [file join $script_dir .. rtl storage demo_sector_source.v]
vlog -work work [file join $script_dir .. rtl storage fat32_mount.v]
vlog -work work [file join $script_dir .. rtl storage fat32_chain_walk.v]
vlog -work work [file join $script_dir .. rtl storage fat32_file_reader.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_stream.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_parser.v]
vlog -work work [file join $script_dir .. rtl storage fat32_directory.v]
vlog -work work [file join $script_dir .. rtl storage fat32_path_lookup.v]
vlog -work work [file join $script_dir .. rtl storage fat32_sector_arbiter.v]
vlog -work work [file join $script_dir .. rtl storage fat32_sector_port.v]
vlog -work work [file join $script_dir .. rtl storage fat32_core.v]
vlog -work work [file join $script_dir tb_demo_media.v]
vsim -voptargs=+acc work.tb_demo_media
onfinish stop
run -all
if {[examine -radix binary /tb_demo_media/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
