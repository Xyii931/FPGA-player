# Real shared TF media path elaboration, then shared-service/session self-check.
# The executed test uses real FAT32/mux; SD sectors and session handshakes are fixtures.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build media_file_service]
file mkdir $build_dir
cd $build_dir
transcript file media_file_service.log
vlib work
vmap work [file join $build_dir work]
foreach folder {common storage media display} {
    foreach source [lsort [glob -directory [file join $script_dir .. rtl $folder] *.v]] {
        vlog -work work $source
    }
}
vlog -work work [file join $script_dir .. rtl top media_io.v]
vlog -work work [file join $script_dir tb_media_file_service.v]
# Verify the full real TF/scan/BMP/two-WAV hierarchy resolves. No pin simulation here.
vsim -voptargs=+acc work.media_io
quit -sim
vsim -voptargs=+acc work.tb_media_file_service
onfinish stop
run -all
if {[examine -radix binary /tb_media_file_service/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
