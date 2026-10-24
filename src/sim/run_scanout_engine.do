# Real project reader/RAM/CDC; only logical memory responses are test endpoints.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build scanout_engine]
file mkdir $build_dir
cd $build_dir
transcript file scanout_engine.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl display video_timing.v]
vlog -work work [file join $script_dir .. rtl display transition_plan.v]
vlog -work work [file join $script_dir .. rtl display transition_map.v]
vlog -work work [file join $script_dir .. rtl display blend_unit.v]
vlog -work work [file join $script_dir .. rtl display fb_line_reader.v]
vlog -work work [file join $script_dir .. rtl display fb_reader.v]
vlog -work work [file join $script_dir .. rtl display display_source_guard.v]
vlog -work work [file join $script_dir .. rtl display scanout_engine.v]
vlog -work work [file join $script_dir tb_scanout_engine.v]
vsim -voptargs=+acc work.tb_scanout_engine
onfinish stop
run -all
if {[examine -radix binary /tb_scanout_engine/S_test_pass] ne "1"} {
    echo "FAIL: simulation ended without a passing result"
    quit -force -code 1
}
quit -force -code 0
