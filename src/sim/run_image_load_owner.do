# Explicit slot and loader protocol peers; the integration case uses the real chain.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build image_load_owner]
file mkdir $build_dir
cd $build_dir
transcript file image_load_owner.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media image_load_owner.v]
vlog -work work [file join $script_dir tb_image_load_owner.v]
vsim -voptargs=+acc work.tb_image_load_owner
onfinish stop
run -all
if {[examine -radix binary /tb_image_load_owner/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
