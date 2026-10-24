# Real arbiter/candidate/reader/CDC/RAM; scanout and memory are explicit endpoints.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build display_reader_arbiter]
file mkdir $build_dir
cd $build_dir
transcript file display_reader_arbiter.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl display fb_line_reader.v]
vlog -work work [file join $script_dir .. rtl display fb_reader.v]
vlog -work work [file join $script_dir .. rtl display display_candidate_ctrl.v]
vlog -work work [file join $script_dir .. rtl display display_reader_arbiter.v]
vlog -work work [file join $script_dir tb_display_reader_arbiter.v]
vsim -voptargs=+acc work.tb_display_reader_arbiter
onfinish stop
run -all
if {[examine -radix binary /tb_display_reader_arbiter/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
