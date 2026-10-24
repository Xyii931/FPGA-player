# Run from repository root: vsim -c -do "do src/sim/run_clk_monitor.do"
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build clk_monitor]
file mkdir $build_dir
cd $build_dir
transcript file clk_monitor.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common clk_monitor.v]
vlog -work work [file join $script_dir tb_clk_monitor.v]
vsim -voptargs=+acc work.tb_clk_monitor
onfinish stop
run -all
if {[examine -radix binary /tb_clk_monitor/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
