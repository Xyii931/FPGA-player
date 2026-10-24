# Real native control/arbitration, independent SDR command fixture (no vendor PHY).
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build frame_memory]
file mkdir $build_dir
cd $build_dir
transcript file frame_memory.log
vlib work
vmap work [file join $build_dir work]
foreach source {native_sdram_ctrl frame_mem_arbiter player_frame_memory} {
    vlog -work work [file join $script_dir .. rtl storage $source.v]
}
vlog -work work [file join $script_dir models sim_sdr_device.v]
vlog -work work [file join $script_dir tb_frame_memory.v]
vsim -voptargs=+acc work.tb_frame_memory
onfinish stop
run -all
if {[examine -radix binary /tb_frame_memory/S_test_pass] ne "1"} {
    echo "FAIL: frame_memory simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
