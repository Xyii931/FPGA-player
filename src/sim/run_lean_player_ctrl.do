onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_player_ctrl]
file mkdir $build_dir
cd $build_dir
transcript file lean_player_ctrl.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl top lean_player_ctrl.v]
vlog -work work [file join $script_dir tb_lean_player_ctrl.v]
vsim -voptargs=+acc work.tb_lean_player_ctrl
onfinish stop
run -all
if {[examine -radix binary /tb_lean_player_ctrl/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
