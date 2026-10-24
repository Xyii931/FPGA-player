# Real scan controller; command/terminal protocol stimulus only.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build media_scan_ctrl]
file mkdir $build_dir
cd $build_dir
transcript file media_scan_ctrl.log
vlib work
vmap work [file join $build_dir work]
foreach source {media_scan_ctrl.v} {
    vlog -work work [file join $script_dir .. rtl media $source]
}
vlog -work work [file join $script_dir tb_media_scan_ctrl.v]
vsim -voptargs=+acc work.tb_media_scan_ctrl
onfinish stop
run -all
if {[examine -radix binary /tb_media_scan_ctrl/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
