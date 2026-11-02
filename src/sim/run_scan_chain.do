onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build scan_chain]
file mkdir $build_dir
cd $build_dir
transcript file scan_chain.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
foreach source [glob [file join $script_dir .. rtl storage *.v]] {vlog -work work $source}
vlog -work work [file join $script_dir models sd_spi_card_model.v]
vlog -work work [file join $script_dir tb_scan_chain.v]
vsim -voptargs=+acc work.tb_scan_chain
onfinish stop
run -all
if {[examine -radix binary /tb_scan_chain/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
