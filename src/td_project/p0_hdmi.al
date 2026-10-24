<?xml version="1.0" encoding="UTF-8"?>
<Project Version="3" Minor="2" Path=".">
    <Project_Created_Time />
    <TD_Version>6.2.168116</TD_Version>
    <Name>p0_hdmi</Name>
    <HardWare>
        <Family>EG4</Family>
        <Device>EG4S20BG256</Device>
        <Speed />
    </HardWare>
    <Source_Files>
        <Verilog>
            <File Path="../rtl/common/reset_sync.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="1" />
                </FileInfo>
            </File>
            <File Path="../rtl/common/reset_gen.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="2" />
                </FileInfo>
            </File>
            <File Path="../rtl/common/pll_tree.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="3" />
                </FileInfo>
            </File>
            <File Path="../ip/player_sys_pll.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="4" />
                </FileInfo>
            </File>
            <File Path="../ip/player_video_pll.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="5" />
                </FileInfo>
            </File>
            <File Path="../rtl/display/video_pattern_axis.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="6" />
                </FileInfo>
            </File>
            <File Path="../rtl/top/p0_hdmi_top.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="7" />
                </FileInfo>
            </File>
            <File Path="../../reference/lab_ex5_i2s/src/user_source/hdl_source/hdmi_phy_warpper.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="8" />
                </FileInfo>
            </File>
            <File Path="../../reference/lab_ex5_i2s/src/user_source/hdl_source/lane_lvds_10_1.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="9" />
                </FileInfo>
            </File>
            <File Path="../../reference/lab_ex5_i2s/src/user_source/hdl_source/hdmi1.4b_transmitter_core/hdmi_1_4b_transmitter_core_wrapper.enc.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="design_1" />
                    <Attr Name="CompileOrder" Val="10" />
                </FileInfo>
            </File>
        </Verilog>
        <ADC_FILE>
            <File Path="../constraints/p0_hdmi.adc">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="constraint_1" />
                    <Attr Name="CompileOrder" Val="1" />
                </FileInfo>
            </File>
        </ADC_FILE>
        <SDC_FILE>
            <File Path="../constraints/p0_hdmi.sdc">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true" />
                    <Attr Name="UsedInP&amp;R" Val="true" />
                    <Attr Name="BelongTo" Val="constraint_1" />
                    <Attr Name="CompileOrder" Val="1" />
                </FileInfo>
            </File>
        </SDC_FILE>
    </Source_Files>
    <FileSets>
        <FileSet Name="design_1" Type="DesignFiles">
        </FileSet>
        <FileSet Name="constraint_1" Type="ConstrainFiles">
        </FileSet>
    </FileSets>
    <TOP_MODULE>
        <LABEL>p0_hdmi_top</LABEL>
        <MODULE>p0_hdmi_top</MODULE>
        <CREATEINDEX>user</CREATEINDEX>
    </TOP_MODULE>
    <Property>
    </Property>
    <Device_Settings>
    </Device_Settings>
    <Configurations>
    </Configurations>
    <Runs>
        <Run Name="syn_1" Type="Synthesis" ConstraintSet="constraint_1" Description="" Active="true">
            <Strategy Name="Default_Synthesis_Strategy">
            </Strategy>
            <UserParams>
            </UserParams>
        </Run>
        <Run Name="phy_1" Type="PhysicalDesign" ConstraintSet="constraint_1" Description="" SynRun="syn_1" Active="true">
            <Strategy Name="Default_PhysicalDesign_Strategy">
            </Strategy>
            <UserParams>
            </UserParams>
        </Run>
    </Runs>
    <Project_Settings>
    </Project_Settings>
</Project>
