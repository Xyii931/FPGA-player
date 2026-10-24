onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build osd_text_store]
file mkdir $build_dir
cd $build_dir
transcript file osd_text_store.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display gb2312_text_decoder.v]
vlog -work work [file join $script_dir .. rtl display osd_text_store.v]
vlog -work work [file join $script_dir tb_osd_text_store.v]
vsim -voptargs=+acc work.tb_osd_text_store
onfinish stop
run -all
if {[examine -radix binary /tb_osd_text_store/S_test_pass] ne "1"} {
    echo "FAIL: OSD text store ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
