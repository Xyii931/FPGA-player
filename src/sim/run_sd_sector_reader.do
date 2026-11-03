onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build sd_sector_reader]
file mkdir $build_dir
cd $build_dir
transcript file sd_sector_reader.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl storage sector_cdc_bridge.v]
vlog -work work [file join $script_dir .. rtl storage spi_byte_master.v]
vlog -work work [file join $script_dir .. rtl storage sd_spi_phy.v]
vlog -work work [file join $script_dir .. rtl storage sd_csd_decode.v]
vlog -work work [file join $script_dir .. rtl storage sd_sector_reader.v]
vlog -work work [file join $script_dir .. rtl storage sd_storage.v]
vlog -work work [file join $script_dir models sd_spi_card_model.v]
vlog -work work [file join $script_dir tb_sd_sector_reader.v]
vsim -voptargs=+acc work.tb_sd_sector_reader
onfinish stop
run -all
if {[examine -radix binary /tb_sd_sector_reader/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
