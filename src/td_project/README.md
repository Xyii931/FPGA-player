# TD工程与上板入口

| 工程 | 顶层 | 用途 | 约束 |
|---|---|---|---|
| [lean_player.al](lean_player.al) | `lean_player_top` | 图片/音频播放器 | `../constraints/player.adc`、`player.sdc` |
| [p0_hdmi.al](p0_hdmi.al) | `p0_hdmi_top` | 无TF、无文件音频的基础视频诊断 | `../constraints/p0_hdmi.adc`、`p0_hdmi.sdc` |

目标器件为 `EG4S20BG256`，当前使用TD V6.2.168116。主工程有46份Verilog源文件，含三份厂商HDMI依赖；诊断工程10份。测试台和功能替身不加入综合工程。所有相对路径以本目录为基准，保持仓库结构即可打开。

## 综合命令

从仓库根目录运行：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player
& ./src/td_project/run_synthesis.ps1 -Project p0_hdmi
```

默认项目为 `lean_player`。可选模块检查仅保留实际依赖：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player -Module lean_media_source
& ./src/td_project/run_synthesis.ps1 -Project lean_player -Module audio_frame_fifo
```

默认TD路径为 `D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/bin/td_commands_prompt.exe`，可用 `-TdPath` 覆盖。中文路径通过临时空闲盘符映射处理，不复制工程；脚本只释放自己建立的映射。

日志保存在 `.local/td-build/<项目>/<批次>/`，模块另有模块名子目录。`summary.json`记录错误、严重警告、容量和setup/hold WNS。**`Passed=true`只表示综合流程、容量及严重诊断检查通过，时序另看 `TimingMet`。** 现有脚本不布局布线、不生成bit、不下载或烧Flash。

## 时钟与原语

50 MHz板载输入进入两个PLL，目标输出为100 MHz、125 MHz、125 MHz/180°、25 MHz和HDMI 5倍125 MHz。`src/ip/`包装沿用原厂参数与反馈并引出真实lock，不能由RTL替身确认频率、相位或上电行为。

顶层通过带初值计数器产生16个50 MHz周期、约320 ns的PLL启动复位，业务复位不重启PLL。初值映射、启动脉宽、lock及复位释放须用TD报告和板测确认。

视频总时序800×525、有效640×480，25 MHz时钟对应约59.52 Hz。音频48 kHz，输出PCM24与ACR。SDRAM为器件集成原语，不是外部存储芯片。

主工程直接使用的厂商文件位于 `reference/lab_ex5_i2s/src/user_source/hdl_source/`：HDMI加密核、`hdmi_phy_warpper.v`及`lane_lvds_10_1.v`。PLL/SDRAM包装在注释中标注参数来源，相关IP配置、厂商手册和实验工程见[参考资料说明](../../reference/README.md)。

## 上板前检查

主工程最近一次综合为17605 LUT、9403寄存器、32 BRAM9K、2 BRAM32K、3 DSP，容量满足；setup/hold WNS为−9.357/+0.471 ns，仍不满足时序。[验证记录](../../docs/verification.md)列出批次与适用范围。

当前SDC仅提供50 MHz主时钟和 `derive_clocks`，没有使用宽泛false path掩盖违例。需要继续检查域内路径、FIFO/复位跨域、移相SDRAM、IO延迟和未约束路径，随后布局布线并复查实际时序。

核对板卡版本和ADC中的TMDS、DDC/HPD、TF、UART及Flash引脚，再生成下载文件。素材、按键、串口及主工程LED含义见[使用说明](../../docs/使用说明.md)。实物测试需要完成供电、接线、下载及画面/声音观察，电脑侧验证须保存对应版本的编译、仿真与实现报告。

基础诊断工程的LED1/2分别显示系统/视频PLL lock，LED3为HDMI核lock，LED4为约1.49 Hz心跳；KEY1可重新触发。该入口没有HPD自动恢复，建议先连接显示器。它不验证TF、SDRAM、文件音频或播放器整机容量。
