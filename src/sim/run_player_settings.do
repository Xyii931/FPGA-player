# Explicit NOR pin peer; not a vendor flash electrical/power-fail timing model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build player_settings]
file mkdir $build_dir
cd $build_dir
transcript file player_settings.log
vlib work
vmap work [file join $build_dir work]
foreach source {common/reset_sync.v storage/spi_byte_master.v storage/flash_ctrl.v storage/flash_cmd_arbiter.v storage/settings_store.v top/player_settings.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir models sim_spi_nor.v]
vlog -work work [file join $script_dir tb_player_settings.v]
vsim -voptargs=+acc work.tb_player_settings
onfinish stop
run -all
if {[examine -radix binary /tb_player_settings/S_test_pass] ne "1"} {
    echo "FAIL: settings ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
