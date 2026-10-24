# Real two-direction publication FIFOs. Video resource proofs are explicit fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_lease_cdc]
file mkdir $build_dir
cd $build_dir
transcript file display_lease_cdc.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync.v async_fifo.v} {
    vlog -work work [file join $script_dir .. rtl common $source]
}
vlog -work work [file join $script_dir .. rtl display display_lease_cdc.v]
vlog -work work [file join $script_dir tb_display_lease_cdc.v]
vsim -voptargs=+acc work.tb_display_lease_cdc
onfinish stop
run -all
if {[examine -radix binary /tb_display_lease_cdc/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
