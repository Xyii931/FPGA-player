onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build spi_byte_master]
file mkdir $build_dir
cd $build_dir
transcript file spi_byte_master.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage spi_byte_master.v]
vlog -work work [file join $script_dir tb_spi_byte_master.v]
vsim -voptargs=+acc work.tb_spi_byte_master
onfinish stop
run -all
if {[examine -radix binary /tb_spi_byte_master/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
