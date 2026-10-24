# TD 工程与板载入口

本目录包含正式播放器和独立基础视频两个工程。文件已准备，尚未在TD中加载、综合、布局布线或下载；没有资源、时序或板测通过记录。

## 选择工程

| 工程 | 顶层 | 用途 | 约束 |
|---|---|---|---|
| [player.al](player.al) | `player_top` | TF/Flash素材、图像/音频、SDRAM、OSD、菜单/UART与HDMI的正式集成入口 | `../constraints/player.adc`、`../constraints/player.sdc` |
| [p0_hdmi.al](p0_hdmi.al) | `p0_hdmi_top` | 无TF、无文件音频的基础视频诊断 | `../constraints/p0_hdmi.adc`、`../constraints/p0_hdmi.sdc` |

目标为 `EG4` / `EG4S20BG256`。工程沿用参考TD 6.2格式，实际加载兼容性待验证。当前 `player.al` 包含148项Verilog源文件和ADC/SDC各一份；基础视频工程包含10项Verilog源文件和对应约束。

两个工程的 `UsedInP&R` 属性值均采用XML转义形式 `UsedInP&amp;R` 保存，解析后仍为 `UsedInP&R`。`p0_hdmi.al` 原有12处未转义写法已修复；两个工程均通过标准XML解析及源文件引用检查。该检查不代表TD工程已经成功加载，实际加载、综合与实现仍待验证。

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

## 用户验证步骤

1. 先按 [仿真说明](../sim/README.md) 运行P0、Storage、Media，保存失败项日志。
2. 在TD打开所需工程，核对器件、顶层、真实IP/原语、源清单与ADC/SDC。
3. 综合后检查初值/PLL映射、RAM与逻辑占用及错误警告。现有资源估算已超原预算，可能需要按报告优化或裁剪。
4. 实现后检查五路时钟、setup/hold、CDC与复位路径、IO时序及所有未约束路径。SDC目前只有50 MHz主时钟与 `derive_clocks`，尚未完成时序约束。
5. 核对实际板卡与ADC，特别是TMDS差分、DDC/HPD、TF、Flash及串口；满足实现要求后生成并下载bit文件。
6. 分步验证基础视频、单图、音轨、版式/转场、OSD/设置、演示/恢复、告警及热插拔，保存异常状态和对应日志。

反馈时提供工程名、TD版本、完整错误日志、资源/时钟/时序报告，以及bit文件生成时间和板上现象。硬件相位、供数能力、200 ms告警目标、HDMI兼容性和长期稳定性均需实测。
