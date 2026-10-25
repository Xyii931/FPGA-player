onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build osd_menu_builder]
file mkdir $build_dir
cd $build_dir
transcript file osd_menu_builder.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
foreach source {video_ui_cdc osd_title_snapshot osd_menu_builder} {
    vlog -work work [file join $script_dir .. rtl display $source.v]
}
vlog -work work [file join $script_dir tb_osd_menu_builder.v]
vsim -voptargs=+acc work.tb_osd_menu_builder
onfinish stop
run -all
if {[examine -radix binary /tb_osd_menu_builder/S_test_pass] ne "1"} {
    echo "FAIL: OSD menu ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
