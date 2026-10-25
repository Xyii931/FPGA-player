# TD 工程与板载入口

本目录包含正式播放器和独立基础视频两个工程。2026-10-25已使用TD V6.2.168116加载两个工程，并完成基础视频工程综合；完整播放器早期映射统计严重超出资源容量；本日17:13展开的整机复测已完成，容量检查失败（163704 LUT、61545寄存器、227个BRAM9K），不是可下载版本。该批早于后续缩放/APT修改。尚未布局布线、生成bit或下载，结果见 [TD综合检查](../../docs/record/2026-10-25-P0-TD综合检查.md)。

## 选择工程

| 工程 | 顶层 | 用途 | 约束 |
|---|---|---|---|
| [player.al](player.al) | `player_top` | TF/Flash素材、图像/音频、SDRAM、OSD、菜单/UART与HDMI的正式集成入口 | `../constraints/player.adc`、`../constraints/player.sdc` |
| [p0_hdmi.al](p0_hdmi.al) | `p0_hdmi_top` | 无TF、无文件音频的基础视频诊断 | `../constraints/p0_hdmi.adc`、`../constraints/p0_hdmi.sdc` |

目标为 `EG4` / `EG4S20BG256`。工程沿用参考TD 6.2格式，本机TD已成功加载、解析真实IP并展开顶层。当前 `player.al` 包含150项Verilog源文件和ADC/SDC各一份；基础视频工程包含10项Verilog源文件和对应约束。

两个工程的 `UsedInP&R` 属性值均采用XML转义形式 `UsedInP&amp;R` 保存，解析后仍为 `UsedInP&R`。`p0_hdmi.al` 原有12处未转义写法已修复；两个工程均通过标准XML解析及源文件引用检查，并已实际在TD加载。

工程路径相对本目录。两个工程均直接引用 `reference/lab_ex5_i2s/src/user_source/hdl_source/` 中：

- `hdmi1.4b_transmitter_core/hdmi_1_4b_transmitter_core_wrapper.enc.v`：真实加密HDMI核。
- `hdmi_phy_warpper.v`、`lane_lvds_10_1.v`：TMDS映射与串行输出。

保留仓库相对结构，使用支持EG4的TD原语库。测试台和 `sim/models/` 不加入综合工程。PLL包装位于 `src/ip/`，沿用参考原语配置并引出真实lock；SDRAM包装使用器件集成存储原语。

## 时钟与启动

50 MHz板载时钟进入两个PLL，目标输出100 MHz、125 MHz、125 MHz/180°、25 MHz和视频5倍125 MHz。逐项核对实际TD时钟报告、反馈连接、lock和存储相位。

顶层通过带初值的计数器产生16个50 MHz周期的PLL启动reset，约320 ns。其初值映射、复位脉宽和器件上电行为尚待确认；仿真替身不能作为硬件依据。业务全局复位不反馈重启PLL。

视频基线为640×480，25 MHz像素时钟，800×525总时序，对应约59.52 Hz。音频基线为48 kHz双声道，输出PCM24与ACR。基础诊断工程固定关闭音频输入。

## 正式播放器操作

以下为RTL逻辑定义，按键/拨码极性和实际管脚必须与板卡版本核对。

| 输入 | 行为 |
|---|---|
| KEY1 | 菜单外短按上一项；长按3秒业务全局复位 |
| KEY2 | 菜单外下一项 |
| KEY3 | 菜单外切换自动播放；缩略图模式下退出到普通播放 |
| KEY4 | 打开菜单；编辑/子菜单中返回，菜单根处关闭 |
| 菜单内KEY1/2/3 | 移动或修改 / 移动或修改 / 进入或确认 |
| SW1 | 上电采纳及变化时更新AUTO设置 |
| SW2 | 持续强制静音，优先于软件静音设置 |
| SW3 | 上电采纳及变化时选择普通/PiP版式 |
| SW4 | 强制选择Flash DEM1演示源 |

SW1/SW3在设置初始化、输入稳定后各采纳一次，覆盖已恢复的AUTO/版式；之后由拨码变化产生配置事件，菜单和UART也可更新这两项。SW2/SW4按稳定电平持续覆盖，不依赖变化事件。

源选择优先级为SW4强制DEMO → 显式恢复 → TF控制器未就绪时自动DEMO → TF。自动DEMO依据底层TF控制器的ready，不依据FAT挂载或素材扫描结果：TF控制器已就绪但FAT错误/没有素材时，不会因此自动改选DEMO或恢复。演示需要有效Flash包；恢复需UART显式请求。切换等待在途事务排空，不能按瞬时开关电平判断素材已经切换完成。

LED按低电平点亮编码：LED1两PLL均锁定、LED2 SDRAM初始化完成、LED3已有有效普通画面、LED4汇总播放器/存储/HDMI桥/会话故障。LED用于定位阶段，不能替代完整状态与日志。

UART为115200、8N1，ADC定义RX为F12、TX为D12。可先发送 `PING`、`VER`、`STAT`，再使用 `NEXT/PREV`、`PLAY n`、`PAUSE/RESUME`、`SET/GET`、`SCAN`、`RELOAD`、`SAVE`、`MODE`、`ALERT`、`RECOVER`等；完整语法见 [设计02](../../docs/design/02-模块接口规格.md)。主机每次等待应答，长事务收到pending后继续等待DONE/ERR。SELFTEST返回的未测试项不表示硬件通过。

串口终端用CR、LF或CRLF结束每行，接收器不提供硬件流控。`PLAY n`使用从0开始的索引；ALERT文字支持可打印ASCII或GB2312字节，最多40字节，中文不要用UTF-8发送。`RECOVER`的OK表示请求已接受，仍需等待扫描就绪；`SAVE`的OK则在实际Flash保存成功后返回。

`RECOVER`只读扫描TF前64 MiB内从扇区边界起始的连续BMP，最多64张，不恢复碎片文件，也不写卡。`RELOAD`、菜单重载或 `MODE PLAY`退出恢复。SW4强制DEMO时，RECOVER请求返回busy。

中文需要在W25Q64的 `0x010000` 写入字库区域；无卡演示在 `0x100000` 写入DEM1包。准备方法见 [素材工具](../tools/README.md)。

## 基础视频诊断操作

打开 `p0_hdmi.al`，将HDMI B接显示器。KEY1按住立即复位，释放后重新读EDID；不同于正式播放器的长按3秒。SW2/SW1对应逻辑模式00彩条、01灰阶、10白边框/十字、11单像素棋盘。

该工程LED1系统PLL锁定、LED2视频PLL锁定、LED3 HDMI核锁定、LED4约1.49 Hz心跳；未连接HPD自动恢复，显示器应先连接，无画面可用KEY1重新触发。此工程不验证TF、SDRAM、文件音频或正式播放器资源。

## 命令行综合

从仓库根目录运行，按需选择工程：

```powershell
& ./src/td_project/run_synthesis.ps1 -Project p0_hdmi
& ./src/td_project/run_synthesis.ps1 -Project player
& ./src/td_project/run_synthesis.ps1 -Project player -Module player_osd
& ./src/td_project/run_synthesis.ps1 -Project player -Module osd_menu_builder
& ./src/td_project/run_synthesis.ps1 -Project player -Module player_ui_ctrl
& ./src/td_project/run_synthesis.ps1 -Project player -Module display_event_executor
& ./src/td_project/run_synthesis.ps1 -Project player -Module fb_line_reader
& ./src/td_project/run_synthesis.ps1 -Project player -Module fb_slot_arbiter
& ./src/td_project/run_synthesis.ps1 -Project player -Module playlist_player_ctrl
& ./src/td_project/run_synthesis.ps1 -Project player -Module audio_frame_fifo
& ./src/td_project/run_synthesis.ps1 -Project player -Module wav_audio_prepared
& ./src/td_project/run_synthesis.ps1 -Project player -Module demo_sector_source
```

默认TD路径为 `D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/bin/td_commands_prompt.exe`，可用 `-TdPath` 覆盖。脚本自动处理中文仓库路径，结果保存在 `.local/td-build/<工程>/<批次>/`，包含 `summary.json`、控制台日志、资源报告、设计数据库和综合阶段时序。脚本只运行综合，不进行布局布线、bit生成或下载。退出码0及`Passed=true`表示流程完成、生成gate资源报告、资源不超器件容量且无ERROR或CRITICAL-WARNING；不要求时序裕量为正，普通警告仍须审阅。汇总中的 `ResourceFits` 和 `Resources` 只记录容量检查，必须另外查看`*_gate.ts`和`*_gate.timing`，不能将综合流程完成当作时序通过。

汇总中的 `SetupWnsNs`、`HoldWnsNs` 来自综合时序报告；`TimingMet` 只有在两个字段均存在且非负时才为true。负裕量会显示提示，但不会改变仅检查流程和容量的 `Passed`。仍须检查时序覆盖率、具体路径和约束是否完整；即使 `TimingMet=true`，也不等于布局布线后或板级时序通过。

基础视频工程当前占用1800/19600 LUT、1425/19600寄存器、10/64 BRAM9K、0/16 BRAM32K、0/29 DSP和2/4 PLL。综合阶段setup/hold WNS为+5.552/+0.646 ns；这不是最终布线时序。该诊断工程没有使用系统PLL的两路125 MHz存储时钟，不能用它确认完整播放器的五路时钟和存储相位。

`-Module`支持`osd_menu_builder`、`player_osd`、`fb_slot_arbiter`、`playlist_player_ctrl`、`media_index_store`、`display_candidate_ctrl`、`image_scaler`、`audio_frame_fifo`、`wav_audio_prepared`及`demo_sector_source`，结果保存到 `.local/td-build/player/<模块>/<批次>/`。它使用TD的IP映射流程，内部总线端口不作为封装引脚进行容量判断，仍检查实际pad及LUT、寄存器等资源；不加载板级ADC/SDC。脚本生成模块时钟约束再通过 `read_sdc` 加载：host为8 ns、font为10 ns、video为40 ns；单时钟的builder使用font时钟，候选控制器使用video时钟，其余单时钟模块使用host时钟。音频FIFO分别约束write=8 ns、read=40 ns，双轨组件分别约束decode=8 ns、audio=40 ns；尚未补齐Gray总线最大延迟/偏斜和全部CDC约束，不能把模块时钟存在或综合`TimingMet`当作CDC已验证。模块结果不包含整机占用，也不证明完整CDC、IO或布局布线时序。

`player_osd`门级映射后另加载 `*_payload.sdc`，只将有保持握手保证的UI邮箱载荷限定为20 ns最大数据路径延迟。现版源端先捕获622bit元数据/标题序号，复制并检查360 B标题RAM后才翻转请求；目的端经过两级同步、额外请求寄存、valid及builder接收后才使用。约束查询已改为`u_snapshot/u_state/S_payload*`，包括小邮箱载荷寄存器，以及被吸收进builder DSP输入寄存器的host→font路径；保留请求/ack同步器和各域内部路径的正常检查。它没有将整个时钟域设为false path，也没有完成整机所有CDC约束。TD 6.2在映射前加入该例外会于导出IP目标映射时崩溃，故采用映射后加载；旧失败批次按失败保留。本版新增标题RAM和层级变更尚未重新综合，需核对约束查询是否命中、跨域路径及RAM实际映射；该例外不构成标题RAM跨域读取已验证的依据。

## 后续验证分工

用户已在本轮授权助手直接运行电脑侧编译、仿真和综合，并根据实际结果修复代码。用户另负责核对实物板卡版本、接线与供电、连接下载器/显示器/TF卡，以及观察和记录实际画面、声音、按键和LED。下载前先核对引脚与实现报告；本次尚未下载或烧写。

## 用户验证步骤

1. 先按 [仿真说明](../sim/README.md) 运行P0、Storage、Media，保存失败项日志。
2. 在TD打开所需工程，核对器件、顶层、真实IP/原语、源清单与ADC/SDC。
3. 综合后检查初值/PLL映射、RAM与逻辑占用及错误警告。完整播放器优化前的整机映射中间统计为191451 LUT，远超器件19600容量；OSD、槽仲裁和播放控制正在逐块优化，尚未取得优化后的整机报告，不能相加单模块结果代替整机复测。
4. 实现后检查五路时钟、setup/hold、CDC与复位路径、IO时序及所有未约束路径。SDC目前只有50 MHz主时钟与 `derive_clocks`，尚未完成时序约束。
5. 核对实际板卡与ADC，特别是TMDS差分、DDC/HPD、TF、Flash及串口；满足实现要求后生成并下载bit文件。
6. 分步验证基础视频、单图、音轨、版式/转场、OSD/设置、演示/恢复、告警及热插拔，保存异常状态和对应日志。

反馈时提供工程名、TD版本、完整错误日志、资源/时钟/时序报告，以及bit文件生成时间和板上现象。硬件相位、供数能力、200 ms告警目标、HDMI兼容性和长期稳定性均需实测。


模块实际验证结果如下，原始批次和限制见[授权复测记录](../../docs/record/2026-10-25-P0-TD综合检查.md)。这些模块资源不能相加当成整机映射结论。

- `media_index_store`：字符串显式使用`player_bram32k`。TD实际映射6个BRAM32K、10个BRAM9K，setup WNS为−1.969 ns；功能与TD RAM模型自检通过，125 MHz时序尚未通过。
- `image_scaler`：两条1920×32行缓存实际映射4个BRAM32K。坐标及每通道插值分拍后，模块综合使用1820 LUT、1042寄存器、4 DSP，setup/hold WNS为+0.118/+0.609 ns；该综合阶段时序通过，最终像素回归结果见记录，不等于布线后时序通过。
- `audio_frame_fifo`与`wav_audio_prepared`：默认2048×48源码目标每轨3个BRAM32K；TD双轨模块实际收窄为合计4个32K块，另用2个9K块。APT分拍后双轨综合仍未满足时序；WAV控制及跨时钟路径需要继续处理。不能用源码目标或单模块映射承诺整机RAM余量。
- `demo_sector_source`：列表使用64×17同步配对记录，目录元数据使用512×32同步RAM，后端512×8缓冲同步读。默认Flash实例实际使用4个BRAM9K、3268 LUT、1190寄存器，setup WNS为−1.078 ns；demo/recovery功能自检通过，未达125 MHz。模块综合不覆盖恢复实例或完整双实例占用。

完整工程基线容量检查失败。后续需先按层级资源热点重构，再重新综合整机并处理时序、CDC和IO约束，满足要求后才能布局布线。当前没有生成或下载正式播放器bit文件。
