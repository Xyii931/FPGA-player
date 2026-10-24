onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build sd_spi_phy]
file mkdir $build_dir
cd $build_dir
transcript file sd_spi_phy.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl storage spi_byte_master.v]
vlog -work work [file join $script_dir .. rtl storage sd_spi_phy.v]
vlog -work work [file join $script_dir tb_sd_spi_phy.v]
vsim -voptargs=+acc work.tb_sd_spi_phy
onfinish stop
run -all
if {[examine -radix binary /tb_sd_spi_phy/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
