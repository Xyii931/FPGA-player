# TD工程与上板入口

| 工程 | 顶层 | 用途 | 约束 |
|---|---|---|---|
| [lean_player.al](lean_player.al) | `lean_player_top` | 图片/音频播放器 | `../constraints/player.adc`、`player.sdc` |
| [p0_hdmi.al](p0_hdmi.al) | `p0_hdmi_top` | 无TF、无文件音频的基础视频诊断 | `../constraints/p0_hdmi.adc`、`p0_hdmi.sdc` |

目标器件为 `EG4S20BG256`，已有通过时序的物理实现使用TD V6.2.168116；其他版本需要重新核对资源与最终时序。主工程有46份Verilog源文件，含三份厂商HDMI依赖；诊断工程10份。测试台和功能替身不加入综合工程。所有相对路径以本目录为基准，保持仓库结构即可打开。

## 综合命令

主工程已配置TD内置的单seed流程：只运行seed 1、一个任务，先布线，再独立执行 `fix_hold`，最后生成bit。该配置保存在 `.al` 的 `MultiSeed` 中，Reset后仍保留；不修改TD安装文件。电脑侧验证结果及限制见[当前项目状况](../../docs/当前项目状况.md)。

### GUI操作

1. 关闭当前工程，重新打开 `lean_player.al`，确保TD重新读取工程配置；本机英文验证目录为 `D:/FPGA-player/src/td_project/lean_player.al`。
2. 首次使用更新后的工程，Reset `syn_1`，从源码重新综合，再运行 `phy_1`。只有已确认综合参数及源码一致时，才可只Reset并重跑 `phy_1`。
3. 运行日志应显示只有一个seed且值为1，子任务依次执行 `route`、独立 `fix_hold` 和 `bitgen`。报告及bit位于 `lean_player_Runs/phy_1/seed_1/`；检查 `lean_player_phy.ts` 和 `lean_player_pr.timing` 中最终setup/hold余量均非负。

`MultiSeed` 是TD的功能名称，这里只配置一次运行，不进行多seed搜索。不要关闭该开关，否则会恢复此前失败的默认流程。bit生成成功仍须另查最终时序及严重告警。

### 脚本操作

从仓库根目录运行：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player
& ./src/td_project/run_synthesis.ps1 -Project p0_hdmi
```

需要继续布局布线时，显式使用 `-PlaceAndRoute`：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project p0_hdmi -PlaceAndRoute
& ./src/td_project/run_synthesis.ps1 -Project lean_player -PlaceAndRoute
```

此选项从当前源码重新综合，继续布局、布线并输出最终时序报告；不能与 `-Module` 同用。它不生成bit，也不下载。结果的 `Stage=Routed` 时，`Passed`还要求最终setup/hold非负；缺少时序报告或时序未通过均返回失败退出码。约束覆盖和电气检查仍须单独完成。

主播放器脚本设置 `gate map_mode area_prior` 和 `gate pack_effort high`，减少切片占用，为hold修复留出空间。当前映射数据库已验证的布局配置为seed 1、`place pr_strategy 2`、`place effort high`，脚本采用相同默认值；原默认布局在本次SD分频调整后触发局部增量布线冲突。TD 6.2.168116的自动hold修复也曾引发布线冲突，因此脚本先执行 `route` 并保存 `*_route.db`，随后单独执行手册支持的 `fix_hold`，最终时序报告在修复后生成。图形界面由工程内的单seed配置调用TD自带的分步布线/hold修复流程。EG4在切片占用超过90%时可能跳过hold修复。

脚本通过 `open_project -single_run` 运行，布局参数直接设置到当前内存上下文；该模式下仅使用 `set_param -run phy_1 ...` 曾出现保存值更新、实际布局仍使用默认值的情况。布局前保存 `*_place.params` 并在日志打印实际参数，应据此确认配置生效。

`lean_player.al` 的 `syn_1` 保存了面积优先映射和high打包力度，`phy_1` 保存了策略2和high布局力度，`MultiSeed` 固定seed 1。GUI子任务应出现 `set_param place seed 1`；子任务自身的 `flow enable_seed` 显示off不表示没有使用seed，应结合上层单seed配置和实际place命令核对。脚本入口则在单次运行上下文中显式启用seed，两种入口都需要核对最终时序。

### GUI布线失败或生成bit后时序未通过

TD V6.2.168116的本机GUI运行中，即使面积设置已生效、slice占用只有82.74%，仍在route内部自动hold修复插入缓冲后出现 `PHY-8023` 与 `RUN-8102`。这是该批次的布线资源冲突，不能把报错中的通用资源提示直接当作容量超限。当前GUI单seed流程与正式脚本均关闭route内的自动修复，再独立执行 `fix_hold`，最终报告仍检查hold。仅关闭自动修复而省略独立 `fix_hold` 不能替代完整流程。

2026-10-31提供的TD V6.2.178840 GUI日志中，LUT为16309/19600，slice占用91.53%，最终setup/hold余量为−0.298/−0.044 ns，工具明确提示占用超过90%而跳过hold修复。日志还显示 `enable_seed=off`、路由内自动hold修复开启。这次运行与脚本流程不同；日志未包含综合阶段，不能仅凭它确定面积映射设置是否生效。两条SDRAM封装位置告警PHY-7002仍需单独确认。

遇到这种情况，应从源码重新综合，不能只对旧 `*_gate.db` 重跑布局。使用当前工程文件和脚本，并指定本机TD命令行程序，例如：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player -PlaceAndRoute `
    -TdPath 'D:/TD_6.2.1/bin/td_commands_prompt.exe'
```

请先确认该可执行文件在本机存在。核对新批次日志中的 `map_mode area_prior`、`pack_effort high`、启用的seed 1，以及 `route` 之后独立执行的 `fix_hold`。检查 `summary.json` 中的 `Stage`、`TimingMet`、错误和严重告警；**bit生成成功不代表时序通过。** 若相同流程在其他TD版本仍失败，应保留该批次的 `console.log`、`*_gate.area`、`*_phy.area`、`*_phy.ts`、`*_pr.timing`，按具体失败路径继续定位。

默认项目为 `lean_player`。可选模块检查仅保留实际依赖：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player -Module lean_media_source
& ./src/td_project/run_synthesis.ps1 -Project lean_player -Module audio_frame_fifo
```

默认TD路径为 `D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/bin/td_commands_prompt.exe`，可用 `-TdPath` 覆盖。中文路径通过临时空闲盘符映射处理，不复制工程；脚本只释放自己建立的映射。

日志保存在 `.local/td-build/<项目>/<批次>/`，模块另有模块名子目录。`summary.json`记录实际完成的 `Stage`、请求的 `RequestedStage`、错误、严重警告、容量和setup/hold WNS；失败时不会仅因请求了布线就标成 `Routed`。默认 `Stage=Synthesis` 时，**`Passed=true`只表示综合流程、容量及严重诊断检查通过，时序另看 `TimingMet`。** 使用 `-PlaceAndRoute` 后改查最终布线的 `*_phy.ts`、`*_pr.timing`、`*_phy.area`和时序例外报告。脚本不生成bit、不下载或烧Flash。

## 时钟与原语

50 MHz板载输入进入两个PLL，PLL目标输出包括未使用的100 MHz时钟、主机域83.333333 MHz、SDRAM域83.333333 MHz/210°（目标延后7 ns）、视频25 MHz和HDMI 5倍125 MHz。系统PLL保留原厂反馈和VCO配置，主机/存储输出分频为12，并引出真实lock。`O_clk_125m`、`O_clk_125m_sft`保留历史名称。12 ns周期用于改善硬SDRAM读采样余量；串口和轮播计时同时校准。本次频率/相位须核对新的TD推导报告，RTL替身不能确认硬件相位或上电行为。

顶层通过带初值计数器产生16个50 MHz周期、约320 ns的PLL启动复位，业务复位不重启PLL。初值映射、启动脉宽、lock及复位释放须用TD报告和板测确认。

视频总时序800×525、有效640×480，25 MHz时钟对应约59.52 Hz。音频48 kHz，输出PCM24与ACR。SDRAM为器件集成原语，不是外部存储芯片。

播放器顶层的SD域直接使用板载50 MHz时钟；TF卡SPI初始化约200 kHz，工作约6.25 MHz（`WORK_DIVIDER=8`）。修改工作分频会影响物理采样预算，须重新布局布线、生成bit并验证实际卡片；不能仅凭无延迟模型提高线速。

主工程直接使用的厂商文件位于 `reference/lab_ex5_i2s/src/user_source/hdl_source/`：HDMI加密核、`hdmi_phy_warpper.v`及`lane_lvds_10_1.v`。PLL/SDRAM包装在注释中标注参数来源，相关IP配置、厂商手册和实验工程见[参考资料说明](../../reference/README.md)。

## 上板前检查

主工程的最新资源、功能回归和最终时序结果见[当前项目状况](../../docs/当前项目状况.md)。[验证记录](../../docs/verification.md)保留修复基线的历史结果；修改RTL或PLL后须使用新批次复测。

当前SDC提供50 MHz主时钟、`derive_clocks`、主机/视频及主机/SD跨域双向10 ns纯数据路径上限，以及与提前驱动协议对应的SDRAM DQ多周期例外。Gray指针包含在该上限内；命令/地址/掩码和其他存储路径仍接受时序分析。脚本在原语合法化后重读SDC，并在布线后独立修复hold。需要核对例外实际覆盖、剩余时序、IO延迟和未约束路径，不能只凭约束文字签收。

核对板卡版本和ADC中的TMDS、DDC/HPD、TF、UART及Flash引脚，再生成下载文件。素材、按键、串口及主工程LED含义见[使用说明](../../docs/使用说明.md)。实物测试需要完成供电、接线、下载及画面/声音观察，电脑侧验证须保存对应版本的编译、仿真与实现报告。

基础诊断工程的LED1/2分别显示系统/视频PLL lock，LED3为HDMI核lock，LED4为约1.49 Hz心跳；KEY1可重新触发。该入口没有HPD自动恢复，建议先连接显示器。它不验证TF、SDRAM、文件音频或播放器整机容量。
