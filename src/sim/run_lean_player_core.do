onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set script_dir [file dirname [file normalize [info script]]]
set build_dir [file join $script_dir build lean_player_core]
file mkdir $build_dir
cd $build_dir
transcript file lean_player_core.log
vlib work
vmap work [file join $build_dir work]
vlog -work work [file join $script_dir .. rtl common acr_gen.v]
vlog -work work [file join $script_dir .. rtl common async_fifo.v]
vlog -work work [file join $script_dir .. rtl common reset_sync.v]
vlog -work work [file join $script_dir .. rtl common samp_tick.v]
vlog -work work [file join $script_dir .. rtl display ascii_font8x16.v]
vlog -work work [file join $script_dir .. rtl display video_timing.v]
vlog -work work [file join $script_dir .. rtl media audio_frame_fifo.v]
vlog -work work [file join $script_dir .. rtl media bmp_parser.v]
vlog -work work [file join $script_dir .. rtl media wav_parser.v]
vlog -work work [file join $script_dir .. rtl storage fat32_chain_walk.v]
vlog -work work [file join $script_dir .. rtl storage fat32_dir_stream.v]
vlog -work work [file join $script_dir .. rtl storage fat32_file_reader.v]
vlog -work work [file join $script_dir .. rtl storage fat32_mount.v]
vlog -work work [file join $script_dir .. rtl storage fat32_sector_port.v]
vlog -work work [file join $script_dir .. rtl storage lean_root_scan.v]
vlog -work work [file join $script_dir .. rtl storage lean_media_source.v]
vlog -work work [file join $script_dir .. rtl display lean_scanout.v]
vlog -work work [file join $script_dir .. rtl display lean_status_osd.v]
vlog -work work [file join $script_dir .. rtl media lean_audio.v]
vlog -work work [file join $script_dir .. rtl media lean_audio_cache.v]
vlog -work work [file join $script_dir .. rtl media lean_image_loader.v]
vlog -work work [file join $script_dir .. rtl top lean_player_core.v]
vlog -work work [file join $script_dir .. rtl top lean_player_ctrl.v]
vlog -work work [file join $script_dir .. rtl storage native_sdram_ctrl.v]
vlog -work work [file join $script_dir .. rtl storage lean_frame_memory.v]
vlog -work work [file join $script_dir models sim_sdr_device.v]
source [file join $script_dir load_player_bram.do]
vlog -work work [file join $script_dir models sim_lean_media_card.v]
foreach source {spi_byte_master sd_spi_phy sd_csd_decode sd_sector_reader sector_cdc_bridge sd_storage} {
    vlog -work work [file join $script_dir .. rtl storage ${source}.v]
}
vlog -work work [file join $script_dir models sd_spi_card_model.v]
vlog -work work [file join $script_dir tb_lean_player_core.v]
set test_args {}
set test_generics {}
set selected_modes 0
foreach mode {CACHED_MEDIA PERFORMANCE BOARD_MEDIA BOARD_CONTENTION NATIVE_MEDIA SUSTAINED SPI_CONTENTION SPI_MEDIUM IMAGE_BACKPRESSURE CLEAR_CONTENTION SHARED_CONTENTION SHARED_LONG} {
    set env_name FPGA_PLAYER_$mode
    if {[info exists ::env($env_name)] && $::env($env_name) eq "1"} {incr selected_modes}
}
if {$selected_modes>1} {error "Select only one lean_player_core scenario per run"}
if {[info exists ::env(FPGA_PLAYER_CACHED_MEDIA)] && $::env(FPGA_PLAYER_CACHED_MEDIA) eq "1"} {
    set test_args {+CACHED_MEDIA}
    set test_generics {-gUSE_AUDIO_CACHE=1 -gUSE_NATIVE_SDRAM=1}
}
if {[info exists ::env(FPGA_PLAYER_PERFORMANCE)] && $::env(FPGA_PLAYER_PERFORMANCE) eq "1"} {
    set test_args {+PERFORMANCE +LONG_AUDIO}
    set test_generics {-gUSE_SD_SPI=1 -gUSE_NATIVE_SDRAM=1}
}
if {[info exists ::env(FPGA_PLAYER_BOARD_MEDIA)] && $::env(FPGA_PLAYER_BOARD_MEDIA) eq "1"} {
    set test_args {+NATIVE_MEDIA +BOARD_MEDIA +LONG_AUDIO}
    set test_generics {-gUSE_SD_SPI=1 -gUSE_NATIVE_SDRAM=1}
}
if {[info exists ::env(FPGA_PLAYER_BOARD_CONTENTION)] && $::env(FPGA_PLAYER_BOARD_CONTENTION) eq "1"} {
    set test_args {+SPI_CONTEND +LONG_AUDIO}
    set test_generics {-gUSE_SD_SPI=1 -gUSE_NATIVE_SDRAM=1}
}
if {[info exists ::env(FPGA_PLAYER_NATIVE_MEDIA)] && $::env(FPGA_PLAYER_NATIVE_MEDIA) eq "1"} {
    set test_args {+NATIVE_MEDIA +MED_AUDIO}
    set test_generics {-gUSE_NATIVE_SDRAM=1}
}
if {[info exists ::env(FPGA_PLAYER_SUSTAINED)] && $::env(FPGA_PLAYER_SUSTAINED) eq "1"} {
    set test_args {+SUSTAINED +LONG_AUDIO +SD_BYTE_CYCLES=320}
}
if {[info exists ::env(FPGA_PLAYER_SPI_CONTENTION)] && $::env(FPGA_PLAYER_SPI_CONTENTION) eq "1"} {
    set test_args {+SPI_CONTEND}
    set test_generics {-gUSE_SD_SPI=1}
}
if {[info exists ::env(FPGA_PLAYER_SPI_MEDIUM)] && $::env(FPGA_PLAYER_SPI_MEDIUM) eq "1"} {
    set test_args {+SPI_CONTEND +MED_AUDIO}
    set test_generics {-gUSE_SD_SPI=1}
}
if {[info exists ::env(FPGA_PLAYER_IMAGE_BACKPRESSURE)] && $::env(FPGA_PLAYER_IMAGE_BACKPRESSURE) eq "1"} {
    set test_args {+IMAGE_BACKPRESSURE +LONG_AUDIO}
}
if {[info exists ::env(FPGA_PLAYER_CLEAR_CONTENTION)] && $::env(FPGA_PLAYER_CLEAR_CONTENTION) eq "1"} {
    set test_args {+CLEAR_CONTENTION}
}
if {[info exists ::env(FPGA_PLAYER_SHARED_CONTENTION)] && $::env(FPGA_PLAYER_SHARED_CONTENTION) eq "1"} {
    set test_args {+SHARED_CONTENTION +REALISTIC_SD}
}
if {[info exists ::env(FPGA_PLAYER_SHARED_LONG)] && $::env(FPGA_PLAYER_SHARED_LONG) eq "1"} {
    set test_args {+SHARED_CONTENTION +REALISTIC_SD +LONG_AUDIO}
}
if {[info exists ::env(FPGA_PLAYER_SPI_DIVIDER)]} {
    if {![string is integer -strict $::env(FPGA_PLAYER_SPI_DIVIDER)] ||
        $::env(FPGA_PLAYER_SPI_DIVIDER)<4 || $::env(FPGA_PLAYER_SPI_DIVIDER)>65534 ||
        $::env(FPGA_PLAYER_SPI_DIVIDER)%2!=0} {error "FPGA_PLAYER_SPI_DIVIDER must be an even integer in 4..65534"}
    lappend test_generics -gSPI_WORK_DIVIDER=$::env(FPGA_PLAYER_SPI_DIVIDER)
}
if {[info exists ::env(FPGA_PLAYER_ROTATE_ONLY)] && $::env(FPGA_PLAYER_ROTATE_ONLY) eq "1"} {
    if {[lsearch -exact $test_args +PERFORMANCE]<0} {error "FPGA_PLAYER_ROTATE_ONLY requires FPGA_PLAYER_PERFORMANCE=1"}
    lappend test_args +ROTATE_ONLY
}
vsim -voptargs=+acc {*}$test_generics work.tb_lean_player_core {*}$bram_extra_tops {*}$test_args
onfinish stop
run -all
if {[examine -radix binary /tb_lean_player_core/S_test_pass] ne "1"} {quit -force -code 1}
quit -force -code 0
