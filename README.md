# FPGA-player

基于安路 HX4S20 系列开发板的 HDMI 图片与音频播放器，目标器件为 `EG4S20BG256`。项目使用 Verilog-2001，通过 TF 卡读取素材，在片内集成 SDRAM 中保存画面，经 HDMI 输出视频和音频，并提供板载菜单、UART 控制和 Flash 设置保存。

**当前状态：主功能源码、顶层接线、TD工程和自检脚本已编写。2026-10-25已通过P0六项、Storage十六项仿真（含修复后复测）、部分Media定向测试及基础视频工程综合；完整播放器已发现严重资源超预算，综合检查未通过，布局布线和上板尚未执行，P0—P7 尚未验收。** 结果见 [基础仿真记录](docs/record/2026-10-25-P0-基础仿真.md) 和 [TD综合检查](docs/record/2026-10-25-P0-TD综合检查.md)。基础视频工程占用1800/19600 LUT，不能据此推断完整播放器能装入器件；完整播放器本日基线最终报告为163704/19600 LUT、61545/19600寄存器、227/64 BRAM9K，容量不通过；后续模块修改尚不能替代整机复测。

## 已编写的功能

| 部分 | 当前源码内容 |
|---|---|
| 时钟与复位 | 50 MHz 输入、双 PLL、五路输出、锁定状态和分域复位 |
| 存储与文件 | TF SPI、FAT32、共享文件服务、播放列表与目录扫描、帧存储仲裁和 SDRAM 控制 |
| 图像与显示 | BMP/RLE1 解码、缩放与旋转、五种版式、七种转场、行缓存扫描、颜色调整 |
| 音频 | 48 kHz 双声道 PCM16 WAV、APT0、双音轨缓冲与混音、BGM 循环、音量/静音/暂停、HDMI PCM/ACR |
| 操作与文字 | 板载按键/拨码、中文 OSD、标题与缩略图标签、菜单、UART、CFG1 设置保存 |
| 特殊流程 | 告警常驻页与提示音、音轨书签恢复、DEM1 Flash 演示、显式连续 BMP 扇区恢复扫描 |

表中描述源码范围，不代表功能已验证。独立开机 Logo 加载显示流程尚未实现；外接编码器、红外、720p 和频谱不属于当前板载基线。

## 目录与入口

| 路径 | 用途 |
|---|---|
| [src/README.md](src/README.md) | 正式工程目录、数据链路和维护入口 |
| [src/rtl/README.md](src/rtl/README.md) | RTL 分层、关键模块与连接规则 |
| [src/td_project/README.md](src/td_project/README.md) | TD工程选择、依赖、时钟、板载操作与实现检查 |
| [src/sim/README.md](src/sim/README.md) | 集中仿真命令、日志位置与结果判读 |
| [src/tools/README.md](src/tools/README.md) | RLE1、DEM1、APT0 和字库工具用法 |
| [docs/design/README.md](docs/design/README.md) | 设计规范、接口和验收标准索引 |
| `reference/` | 厂商/开发板参考工程；当前工程仍引用其中的 HDMI 核与 PHY |

日常维护直接修改 `src/` 下的正式代码。打开 TD 或运行自检不需要执行 `.local/` 中的生成器和过程脚本。

## 开始验证

从仓库根目录运行 PowerShell：

```powershell
& ./src/sim/run_p0.ps1 -Suite P0
& ./src/sim/run_p0.ps1 -Suite Storage
& ./src/sim/run_p0.ps1 -Suite Media
```

也可用下面一条命令代替上述三条，收集全部用例：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
```

默认 ModelSim 路径为 `D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe`，其他安装位置可用 `-VsimPath` 指定。先查看失败用例和日志，再打开 `src/td_project/player.al` 进行综合与实现。独立基础视频诊断入口为 `p0_hdmi.al`，两者的顶层、引脚和 LED 含义有所不同，详见 TD 说明。

后续验证顺序建议为：时钟/复位与基础视频 → 存储和 TF 单图 → 音频 → 版式/转场 → 菜单/设置 → Flash 演示/恢复 → 告警与热插拔。中文显示需要提供字库，无卡素材演示需要先写入有效 DEM1 包。
