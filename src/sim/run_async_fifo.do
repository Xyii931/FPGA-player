# User-run dual-clock self-test; functional RAM or installed TD models selected by loader.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build async_fifo]
file mkdir $build_dir
cd $build_dir
transcript file async_fifo.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir tb_async_fifo.v]
if {[llength $bram_extra_tops]} {
    vsim -voptargs=+acc work.tb_async_fifo [lindex $bram_extra_tops 0]
} else {
    vsim -voptargs=+acc work.tb_async_fifo
}
onfinish stop
run -all
if {[examine -radix binary /tb_async_fifo/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
