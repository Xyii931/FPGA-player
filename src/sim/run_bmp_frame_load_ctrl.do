# Logical protocol endpoints only; does not validate physical SDRAM or SD timing.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build bmp_frame_load_ctrl]
file mkdir $build_dir
cd $build_dir
transcript file bmp_frame_load_ctrl.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media bmp_frame_load_ctrl.v]
vlog -work work [file join $script_dir tb_bmp_frame_load_ctrl.v]
vsim -voptargs=+acc work.tb_bmp_frame_load_ctrl
onfinish stop
run -all
if {[examine -radix binary /tb_bmp_frame_load_ctrl/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
