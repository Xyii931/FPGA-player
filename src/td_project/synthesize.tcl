# Run through run_synthesis.ps1; optional place/route, never bit generation/programming.
set repo_root [file normalize [file join [file dirname [info script]] .. ..]]
set project_name $::env(FPGA_PLAYER_PROJECT)
if {$project_name ni {p0_hdmi lean_player}} {puts stderr "Invalid project"; exit 1}
set top_name ${project_name}_top
set run_name $project_name
set module_name ""
if {[info exists ::env(FPGA_PLAYER_MODULE)]} {set module_name $::env(FPGA_PLAYER_MODULE)}
if {$module_name ne ""} {
    if {$project_name ne "lean_player" || $module_name ni {lean_media_source audio_frame_fifo}} {
        puts stderr "Invalid module scope"; exit 1
    }
    set top_name $module_name
    set run_name $module_name
}
set project_file [file join $repo_root src td_project ${project_name}.al]
set step startup
if {[catch {
    puts "PLAYER_TD_STAGE import_device"
    set step import_device
    import_device eagle_s20.db -package EG4S20BG256
    puts "PLAYER_TD_STAGE open_project"
    set step open_project
    # TD resolves the relative source entries against its working directory.
    set build_dir [pwd]
    cd [file dirname $project_file]
    open_project [file tail $project_file] -single_run
    cd $build_dir
    load_run_param -run syn_1
    puts "PLAYER_TD_STAGE elaborate"
    set step elaborate
    commit_param -step design
    elaborate -top $top_name
    puts "PLAYER_TD_STAGE constraints"
    set step constraints
    if {$module_name eq ""} {
        set constraint_name [expr {$project_name eq "lean_player" ? "player" : $project_name}]
        read_adc [file join $repo_root src constraints ${constraint_name}.adc]
        read_sdc [file join $repo_root src constraints ${constraint_name}.sdc]
    } else {
        # read_sdc initializes TD's netlist/SDC context; direct create_clock here
        # otherwise emits USR-8122. These clocks only scope module analysis.
        set scope_sdc [file join $build_dir ${run_name}_scope.sdc]
        set scope_file [open $scope_sdc w]
        if {$module_name eq "audio_frame_fifo"} {
            puts $scope_file {create_clock -name write_clk -period 12.000 [get_ports I_write_clk]}
            puts $scope_file {create_clock -name read_clk -period 40.000 [get_ports I_read_clk]}
        } else {
            puts $scope_file {create_clock -name host_clk -period 12.000 [get_ports I_clk]}
        }
        close $scope_file
        read_sdc $scope_sdc
    }
    export_db ${run_name}_elaborate.db
    puts "PLAYER_TD_STAGE optimize_rtl"
    set step optimize_rtl
    commit_param -step rtl
    optimize_rtl
    report_area -file ${run_name}_rtl.area
    export_db ${run_name}_rtl.db
    puts "PLAYER_TD_STAGE optimize_gate"
    set step optimize_gate
    commit_param -step gate
    if {$project_name eq "lean_player" && $module_name eq ""} {
        # EG4 skips hold repair above 90% occupied slices. Prefer area mapping
        # and stronger packing to leave room for physical delay repair.
        set_param gate map_mode area_prior
        set_param gate pack_effort high
    }
    if {$module_name eq ""} {
        optimize_gate -packarea ${run_name}_gate.area
    } else {
        # TD's own SynIpFlow uses -ip for internal ports without physical PADs.
        export_sdc_target -file ${run_name}.ip.map
        export_sdc_target -file ${run_name}.ipr.map -encrypt
        optimize_gate -ip -mapsim ${run_name}.ip.v -release ${run_name}.ipr.v -maparea ${run_name}_gate.area
        # Resource/timing inspection needs the mapped design, not an IP package.
        # TD 6.2.168116 crashes in create_syn_ip for this internal-bus top.
    }
    legalize_phy_inst
    # TD's command guide requires reloading SDC after physical legalization:
    # mapping introduces the hard SDRAM pins and IO registers used by STA.
    if {$module_name eq ""} {
        read_sdc [file join $repo_root src constraints ${constraint_name}.sdc]
    } else {
        read_sdc $scope_sdc
    }
    export_db ${run_name}_gate.db
    puts "PLAYER_TD_STAGE timing"
    set step timing
    update_timing
    report_clock_summary -file ${run_name}_clocks.rpt
    report_timing_status -file ${run_name}_gate.ts
    report_timing_summary -file ${run_name}_gate.timing
    puts "PLAYER_TD_SYNTH_PASS $run_name"
    if {[info exists ::env(FPGA_PLAYER_PLACE_ROUTE)] && $::env(FPGA_PLAYER_PLACE_ROUTE) eq "1"} {
        if {$module_name ne ""} {error "Place/route requires a board top"}
        puts "PLAYER_TD_STAGE place"
        set step place
        load_run_param -run phy_1
        if {$project_name eq "lean_player"} {
            # Fixed placement seed, strategy and effort for lean_player.
            set_param flow enable_seed on
            # open_project -single_run uses the active in-memory properties.
            # Apply parameters to that context before committing the step.
            set_param place seed 2
            set_param place pr_strategy 2
            set_param place effort high
        }
        if {[info exists ::env(FPGA_PLAYER_SEED)]} {
            set_param flow enable_seed on
            set_param place seed $::env(FPGA_PLAYER_SEED)
        }
        if {[info exists ::env(FPGA_PLAYER_PR_STRATEGY)]} {
            set_param place pr_strategy $::env(FPGA_PLAYER_PR_STRATEGY)
        }
        commit_param -step place
        report_param -stage place -file ${run_name}_place.params
        place
        update_timing -mode manhattan
        report_timing_summary -file ${run_name}_place.timing
        export_db ${run_name}_place.db
        puts "PLAYER_TD_STAGE route"
        set step route
        # TD 6.2.168116 can create conflicting routes when its automatic hold
        # insertion runs inside route. The documented standalone fix_hold flow
        # repairs the same design after a clean route checkpoint instead.
        # Timing acceptance still uses the final report AFTER hold repair.
        set_param route fix_hold off
        if {$project_name eq "lean_player" ||
            ([info exists ::env(FPGA_PLAYER_ROUTE_MULTITRY)] &&
             $::env(FPGA_PLAYER_ROUTE_MULTITRY) eq "1")} {
            set_param route multi_try_route_bad_qor_check off
        }
        # Commit AFTER overrides, as in the standalone physical flow; retain
        # the effective settings with the result rather than just the defaults.
        commit_param -step route
        report_param -stage route -file ${run_name}_route.params
        route
        export_db ${run_name}_route.db
        puts "PLAYER_TD_STAGE hold_fix"
        set step hold_fix
        fix_hold
        update_timing -mode final
        report_area -io_info -file ${run_name}_phy.area
        report_timing_status -file ${run_name}_phy.ts
        report_timing_summary -file ${run_name}_pr.timing
        report_timing_exception -file ${run_name}_exception.timing
        # EG4 does not support report_clock_utilization. Save the supported
        # clock summary; actual edge/period information is in *_pr.timing.
        report_clock_summary -file ${run_name}_phy_clocks.rpt
        export_db ${run_name}_pr.db
        puts "PLAYER_TD_ROUTE_PASS $run_name"
    }
} detail]} {
    puts stderr "PLAYER_TD_SYNTH_FAIL $run_name step=$step: $detail"
    exit 1
}
exit 0
