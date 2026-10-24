onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build player_layout]
file mkdir $build_dir
cd $build_dir
transcript file player_layout.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media playlist_player_ctrl.v]
vlog -work work [file join $script_dir .. rtl display player_status_osd.v]
vlog -work work [file join $script_dir tb_player_layout.v]
vsim -voptargs=+acc work.tb_player_layout
onfinish stop
run -all
if {[examine -radix binary /tb_player_layout/S_test_pass] ne "1"} {
    echo "FAIL: playlist policy ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
