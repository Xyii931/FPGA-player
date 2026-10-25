# Real planner, scaler and mapper; candidate pixel endpoint only, no SDRAM model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build image_transform]
file mkdir $build_dir
cd $build_dir
transcript file image_transform.log
vlib work
vmap work [file join $build_dir work]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir .. rtl media image_geometry.v]
vlog -work work [file join $script_dir .. rtl media image_scaler.v]
vlog -work work [file join $script_dir .. rtl media image_rotate.v]
vlog -work work [file join $script_dir .. rtl media image_transform.v]
vlog -work work [file join $script_dir tb_image_transform.v]
vsim -voptargs=+acc work.tb_image_transform {*}$bram_extra_tops
onfinish stop
run -all
if {[examine -radix binary /tb_image_transform/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
