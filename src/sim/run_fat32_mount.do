onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build fat32_mount]
file mkdir $build_dir
cd $build_dir
transcript file fat32_mount.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage fat32_sector_port.v]
vlog -work work [file join $script_dir .. rtl storage fat32_mount.v]
vlog -work work [file join $script_dir .. rtl storage fat32_volume.v]
vlog -work work [file join $script_dir tb_fat32_mount.v]
vsim -voptargs=+acc work.tb_fat32_mount
onfinish stop
run -all
if {[examine -radix binary /tb_fat32_mount/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
