onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build player_console]
file mkdir $build_dir
cd $build_dir
transcript file player_console.log
vlib work
vmap work [file join $build_dir work]
foreach source {uart_rx uart_tx uart_line_buffer} {
    vlog -work work [file join $script_dir .. rtl common $source.v]
}
foreach source {player_ui_ctrl player_console} {
    vlog -work work [file join $script_dir .. rtl top $source.v]
}
vlog -work work [file join $script_dir tb_player_console.v]
vsim -voptargs=+acc work.tb_player_console
onfinish stop
run -all
if {[examine -radix binary /tb_player_console/S_test_pass] ne "1"} {
    echo "FAIL: player_console ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
