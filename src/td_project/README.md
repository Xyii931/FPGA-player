# TD工程与上板入口

| 工程 | 顶层 | 用途 | 约束 |
|---|---|---|---|
| [lean_player.al](lean_player.al) | `lean_player_top` | 图片与音频播放器 | `../constraints/player.adc`、`player.sdc` |

目标器件为`EG4S20BG256`，验证环境为Anlogic TD V6.2.168116。工程引用47份Verilog文件和两份约束。相对路径以本目录为基准，须保持仓库结构。测试台和仿真替身不加入综合工程。

## GUI操作

1. 打开仓库中的 `lean_player.al`。使用其他目录中的副本时，须同步源码、约束和参考依赖。
2. 从源码重新综合 `syn_1`，再运行 `phy_1`。只有确认源码和综合参数一致后，才可复用已有综合数据库。
3. 保持工程的 `MultiSeed` 开启。工程固定seed 2、一个任务，依次执行布线、独立 `fix_hold` 和bit生成。
4. 查看 `lean_player_Runs/phy_1/seed_2/` 中的 `lean_player_phy.ts` 与 `lean_player_pr.timing`，确认最终setup/hold非负，并检查严重告警、引脚和约束覆盖。

`MultiSeed` 为TD的流程名称；此配置仅执行一次运行。bit生成成功与时序、严重诊断验收分别判断。

## 脚本操作

从仓库根目录运行，默认执行综合：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player
```

继续执行布局布线和独立hold修复：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player -PlaceAndRoute
```

`-PlaceAndRoute`从源码重新综合并执行至最终布线检查。脚本不生成bit、不下载至FPGA，也不烧写Flash。

通过 `-TdPath` 指定安装环境中的TD命令行程序；下面的安装目录须替换为实际路径：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project lean_player -PlaceAndRoute `
    -TdPath '<TD安装目录>/bin/td_commands_prompt.exe'
```

中文路径由脚本通过临时空闲盘符映射处理；脚本只释放自己建立的映射。

## 实现参数与报告

主工程采用面积优先映射和high打包力度：`gate map_mode area_prior`、`gate pack_effort high`。布局固定seed 2、策略2、high力度。

布线采用 `route fix_hold off`，主工程同时关闭 `route multi_try_route_bad_qor_check`；参数先设置再提交。完成 `route` 后独立执行 `fix_hold`，最终时序在hold修复后检查。不得省略独立hold修复或以布线前报告代替最终时序。

脚本在 `open_project -single_run` 上下文设置实际参数，并保存 `*_place.params`、`*_route.params`。GUI流程由工程的 `MultiSeed` 配置指定seed，子任务应出现 `set_param place seed 2`；子任务的 `flow enable_seed` 显示off时，应结合上层配置和实际place命令确认。

结果保存在`.local/td-build/lean_player/<批次>/`。`summary.json`记录实际阶段、错误、严重告警、资源和时序：

- `Stage=Synthesis`：`Passed` 检查流程、容量和严重诊断，时序另看 `TimingMet`。
- `Stage=Routed`：`Passed` 还要求最终setup/hold非负；缺少时序报告或仍有严重告警时返回失败。
- 最终报告为 `*_phy.ts`、`*_pr.timing`、`*_phy.area` 及约束例外报告。

当前实现结果及SDRAM位置告警见[验证记录](../../docs/verification.md)。

## 时钟与原语

下表为主播放器工程的时钟配置。

| 时钟域 | 频率 / 相位 |
|---|---|
| SD与板级输入 | 板载50 MHz |
| 主机 | 83.333333 MHz |
| SDRAM | 83.333333 MHz，210°，目标延后7 ns |
| 视频 | 25 MHz |
| HDMI串行 | 125 MHz |

系统PLL另有未使用的100 MHz输出；`O_clk_125m`、`O_clk_125m_sft` 两个包装端口的实际目标频率为83.333333 MHz。两个PLL均引出真实lock。

顶层通过带初值计数器产生16个50 MHz周期、约320 ns的PLL启动复位，业务复位不重启PLL。PLL相位、初值映射、启动脉宽和lock须结合TD报告与硬件检查。

视频总时序800×525、有效640×480，25 MHz对应约59.52 Hz；音频为48 kHz PCM24及ACR。TF卡SPI初始化约200 kHz，工作约8.333 MHz（`WORK_DIVIDER=6`）。SDRAM采用器件集成原语，无需外接芯片。

厂商HDMI加密核、 `hdmi_phy_warpper.v` 和 `lane_lvds_10_1.v` 位于 `reference/lab_ex5_i2s/src/user_source/hdl_source/`。PLL和SDRAM包装的参数来源见源码注释及[参考资料说明](../../reference/README.md)。

## 上板检查

当前SDC包含50 MHz主时钟、`derive_clocks`、主机/视频及主机/SD跨域双向10 ns纯数据路径上限，以及与提前驱动协议对应的SDRAM DQ多周期例外。Gray指针包含在路径上限内；命令、地址、掩码及其他存储路径继续接受时序分析。须核对例外覆盖、IO延迟和未约束路径。

下载前核对板卡版本、目标器件、ADC引脚、最终时序和严重告警。素材、接线、按键与主工程LED含义见[使用说明](../../docs/使用说明.md)，逐项检查见[验证与上板](../../docs/验证与上板.md)。
