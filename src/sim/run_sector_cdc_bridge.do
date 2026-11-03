onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build sector_cdc_bridge]
file mkdir $build_dir
cd $build_dir
transcript file sector_cdc_bridge.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl storage sector_cdc_bridge.v]
vlog -work work [file join $script_dir tb_sector_cdc_bridge.v]
vsim -voptargs=+acc work.tb_sector_cdc_bridge
onfinish stop
run -all
if {[examine -radix binary /tb_sector_cdc_bridge/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
