onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build osd_text_video]
file mkdir $build_dir
cd $build_dir
transcript file osd_text_video.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
foreach source {video_timing ascii_font8x16 gb2312_text_decoder glyph_cache osd_text_store osd_line_renderer osd_line_bridge osd_text_backend osd_text_video osd_menu_builder video_ui_cdc osd_title_snapshot} {
    vlog -work work [file join $script_dir .. rtl display $source.v]
}
vlog -work work [file join $script_dir .. rtl top player_osd.v]
vlog -work work [file join $script_dir tb_osd_text_video.v]
vsim -voptargs=+acc work.tb_osd_text_video
onfinish stop
run -all
if {[examine -radix binary /tb_osd_text_video/S_test_pass] ne "1"} {
    echo "FAIL: OSD video ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
