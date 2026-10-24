# Public AXIS/controls/mailbox checks only; no real HDMI/PLL/PHY substitution.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build player_board]
file mkdir $build_dir
cd $build_dir
transcript file player_board.log
vlib work
vmap work [file join $build_dir work]
foreach source {reset_sync key_long_reset board_inputs} {
    vlog -work work [file join $script_dir .. rtl common $source.v]
}
foreach source {scanout_axis_bridge video_ui_cdc player_status_osd video_color_adjust} {
    vlog -work work [file join $script_dir .. rtl display $source.v]
}
vlog -work work [file join $script_dir .. rtl top player_board_ctrl.v]
vlog -work work [file join $script_dir tb_player_board.v]
vsim -voptargs=+acc work.tb_player_board
onfinish stop
run -all
if {[examine -radix binary /tb_player_board/S_test_pass] ne "1"} {
    echo "FAIL: player_board ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
