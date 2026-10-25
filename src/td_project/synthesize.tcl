# Run through run_synthesis.ps1; no place/route, bit generation or programming.
set repo_root [file normalize [file join [file dirname [info script]] .. ..]]
set project_name $::env(FPGA_PLAYER_PROJECT)
if {$project_name ni {p0_hdmi player}} {puts stderr "Invalid project"; exit 1}
set top_name ${project_name}_top
set run_name $project_name
set module_name ""
if {[info exists ::env(FPGA_PLAYER_MODULE)]} {set module_name $::env(FPGA_PLAYER_MODULE)}
if {$module_name ne ""} {
    if {$project_name ne "player" || $module_name ni {osd_menu_builder player_osd player_ui_ctrl display_event_executor fb_line_reader fb_slot_arbiter playlist_player_ctrl media_index_store display_candidate_ctrl image_scaler audio_frame_fifo wav_audio_prepared demo_sector_source}} {
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
        read_adc [file join $repo_root src constraints ${project_name}.adc]
        read_sdc [file join $repo_root src constraints ${project_name}.sdc]
    } else {
        # read_sdc initializes TD's netlist/SDC context; direct create_clock here
        # otherwise emits USR-8122. These clocks only scope module analysis.
        set scope_sdc [file join $build_dir ${run_name}_scope.sdc]
        set scope_file [open $scope_sdc w]
        if {$module_name eq "osd_menu_builder"} {
            puts $scope_file {create_clock -name font_clk -period 10.000 [get_ports I_clk]}
        } elseif {$module_name eq "display_candidate_ctrl"} {
            puts $scope_file {create_clock -name video_clk -period 40.000 [get_ports I_clk]}
        } elseif {$module_name eq "audio_frame_fifo"} {
            puts $scope_file {create_clock -name write_clk -period 8.000 [get_ports I_write_clk]}
            puts $scope_file {create_clock -name read_clk -period 40.000 [get_ports I_read_clk]}
        } elseif {$module_name in {display_event_executor fb_line_reader}} {
            puts $scope_file {create_clock -name host_clk -period 8.000 [get_ports I_host_clk]}
            puts $scope_file {create_clock -name video_clk -period 40.000 [get_ports I_video_clk]}
        } elseif {$module_name eq "wav_audio_prepared"} {
            puts $scope_file {create_clock -name decode_clk -period 8.000 [get_ports I_decode_clk]}
            puts $scope_file {create_clock -name audio_clk -period 40.000 [get_ports I_audio_clk]}
        } elseif {$module_name eq "player_osd"} {
            puts $scope_file {create_clock -name host_clk -period 8.000 [get_ports I_host_clk]}
            puts $scope_file {create_clock -name font_clk -period 10.000 [get_ports I_font_clk]}
            puts $scope_file {create_clock -name video_clk -period 40.000 [get_ports I_video_clk]}
        } else {
            puts $scope_file {create_clock -name host_clk -period 8.000 [get_ports I_clk]}
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
    if {$module_name eq "player_osd"} {
        # Small UI metadata is captured before the complete title RAM copy;
        # only a validated copy can publish its request. Two font synchronizers,
        # request_seen, valid and builder admission add further settling time.
        # Bound the held metadata path to 20 ns; review matches after mapping.
        # Apply AFTER mapping: TD 6.2 crashes exporting the IP target map when
        # this get_regs exception is present before optimize_gate/export_sdc_target.
        set payload_sdc [file join $build_dir ${run_name}_payload.sdc]
        set payload_file [open $payload_sdc w]
        puts $payload_file {set_max_delay -datapath_only 20.000 -from [get_regs -hier {u_snapshot/u_state/S_payload*}] -to [get_clocks font_clk]}
        # Some held payload registers are absorbed into builder DSP inputs.
        # Restrict those paths by BOTH clocks and the builder's DSP pins, so
        # no host/font intra-clock path or request/ack synchronizer is relaxed.
        puts $payload_file {set_max_delay -datapath_only 20.000 -from [get_clocks host_clk] -through [get_pins -of [get_cells -hier -filter {REF_NAME == EG_PHY_MULT18} {u_builder/*}]] -to [get_clocks font_clk]}
        close $payload_file
        read_sdc $payload_sdc
    }
    export_db ${run_name}_gate.db
    puts "PLAYER_TD_STAGE timing"
    set step timing
    update_timing
    report_clock_summary -file ${run_name}_clocks.rpt
    report_timing_status -file ${run_name}_gate.ts
    report_timing_summary -file ${run_name}_gate.timing
    puts "PLAYER_TD_SYNTH_PASS $run_name"
} detail]} {
    puts stderr "PLAYER_TD_SYNTH_FAIL $run_name step=$step: $detail"
    exit 1
}
exit 0
