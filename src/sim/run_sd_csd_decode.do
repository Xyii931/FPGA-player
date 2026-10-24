onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build sd_csd_decode]
file mkdir $build_dir
cd $build_dir
transcript file sd_csd_decode.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage sd_csd_decode.v]
vlog -work work [file join $script_dir tb_sd_csd_decode.v]
vsim -voptargs=+acc work.tb_sd_csd_decode
onfinish stop
run -all
if {[examine -radix binary /tb_sd_csd_decode/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
