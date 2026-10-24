# Backend tests only: this does not yet exercise pixel/line-buffer composition.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build osd_fonts]
file mkdir $build_dir
cd $build_dir
transcript file osd_fonts.log
vlib work
vmap work [file join $build_dir work]
foreach source {common/reset_sync.v storage/spi_byte_master.v storage/flash_ctrl.v storage/flash_cmd_arbiter.v storage/settings_store.v top/player_settings.v display/glyph_cache.v display/gb2312_text_decoder.v display/ascii_font8x16.v} {
    vlog -work work [file join $script_dir .. rtl $source]
}
vlog -work work [file join $script_dir models sim_spi_nor.v]
vlog -work work [file join $script_dir tb_osd_fonts.v]
vsim -voptargs=+acc work.tb_osd_fonts
onfinish stop
run -all
if {[examine -radix binary /tb_osd_fonts/S_test_pass] ne "1"} {
    echo "FAIL: font backend ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
