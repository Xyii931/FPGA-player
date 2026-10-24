# Real logical writer; explicit queued write completions, no vendor SDRAM model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build fb_writer]
file mkdir $build_dir
cd $build_dir
transcript file fb_writer.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl display fb_writer.v]
vlog -work work [file join $script_dir tb_fb_writer.v]
vsim -voptargs=+acc work.tb_fb_writer
onfinish stop
run -all
if {[examine -radix binary /tb_fb_writer/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
