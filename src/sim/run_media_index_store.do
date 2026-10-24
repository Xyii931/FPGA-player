# Independent index records only: no FAT32, vendor IP or source-retirement model.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build media_index_store]
file mkdir $build_dir
cd $build_dir
transcript file media_index_store.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl media media_index_store.v]
vlog -work work [file join $script_dir .. rtl media player_order_ctrl.v]
vlog -work work [file join $script_dir tb_media_index_store.v]
vsim -voptargs=+acc work.tb_media_index_store
onfinish stop
run -all
if {[examine -radix binary /tb_media_index_store/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
