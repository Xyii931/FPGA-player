onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build native_sdram_ctrl]
file mkdir $build_dir
cd $build_dir
transcript file native_sdram_ctrl.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage native_sdram_ctrl.v]
vlog -work work [file join $script_dir models sim_sdr_device.v]
vlog -work work [file join $script_dir tb_native_sdram_ctrl.v]
vsim -voptargs=+acc work.tb_native_sdram_ctrl
onfinish stop
run -all
if {[examine -radix binary /tb_native_sdram_ctrl/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
