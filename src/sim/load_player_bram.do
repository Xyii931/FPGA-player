# Source from a case script after vmap. Exactly one implementation in this work library.
# Default: functional storage substitute. Native: real wrapper plus installed TD models.
set bram_script_dir [file dirname [file normalize [info script]]]
set bram_extra_tops {}
if {[info exists ::env(FPGA_PLAYER_NATIVE_BRAM)] && $::env(FPGA_PLAYER_NATIVE_BRAM) ni {0 1}} {
    error "FPGA_PLAYER_NATIVE_BRAM must be 0 (functional) or 1 (installed TD models)"
}
if {[info exists ::env(FPGA_PLAYER_NATIVE_BRAM)] && $::env(FPGA_PLAYER_NATIVE_BRAM) eq "1"} {
    set bram_vendor_dir {D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/sim_release/eg4}
    if {[info exists ::env(FPGA_PLAYER_TD_SIM_DIR)]} {set bram_vendor_dir $::env(FPGA_PLAYER_TD_SIM_DIR)}
    foreach bram_source {eg_phy_glbl.v eg_phy_bram.v eg_phy_bram32k.v eg_logic_bram.v} {
        set bram_path [file join $bram_vendor_dir $bram_source]
        if {![file isfile $bram_path]} {error "TD RAM model missing: $bram_path"}
        vlog -work work $bram_path
    }
    vlog -work work [file join $bram_script_dir .. ip player_bram32k.v]
    set bram_extra_tops {work.glbl}
    echo "RAM implementation: installed TD models and real EG4 32K wrapper"
} else {
    vlog -work work [file join $bram_script_dir models player_bram32k_model.v]
    echo "RAM implementation: functional substitute; no primitive/mapping validation"
}
