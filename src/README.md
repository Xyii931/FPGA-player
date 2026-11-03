# FPGA-player 源码与工程

主入口为 [td_project/lean_player.al](td_project/lean_player.al)，板级顶层为 `rtl/top/lean_player_top.v`。本目录包含播放器、基础HDMI诊断以及功能自检所需的源码和脚本。

| 目录 | 内容 |
|---|---|
| `rtl/common/` | PLL树、复位、FIFO、按键、UART及音频时基 |
| `rtl/storage/` | SD SPI、FAT32根目录/文件、原生SDRAM控制及双帧存储 |
| `rtl/media/` | BMP/WAV解析、图像装载、SDRAM音频缓存及循环播放 |
| `rtl/display/` | 时序、行缓存扫描、ASCII状态及HDMI AXIS桥 |
| `rtl/top/` | 板级包装、播放核心/控制、HDMI和基础视频诊断 |
| `ip/` | 真实PLL、32K RAM及器件集成SDRAM原语包装 |
| `constraints/` | 两个工程的引脚和起始时序约束 |
| `sim/` | 当前功能相关的25项自检、脚本及独立模型 |
| `td_project/` | 主工程、诊断工程和综合入口 |

数据链路为TF → SD SPI/CDC → 已校验扇区 → FAT32 → BMP/WAV。BMP写入非活动帧，行缓存从活动帧读取。首图提交后，`lean_audio_cache`把完整WAV存入SDRAM，随后由`lean_audio`从缓存循环解码，送入双时钟样本FIFO，在视频域输出音频与ACR，最后连接厂商HDMI核。缓存完成后，音乐播放不再读取TF卡。

## 工程结构与依赖

主工程 `lean_player.al` 引用47份Verilog文件：本项目40份RTL、4份IP包装，以及参考目录中的3份厂商HDMI依赖；另引用 `player.adc` 和 `player.sdc`。这些依赖均使用相对路径，须保持仓库目录结构。

基础视频诊断工程 `p0_hdmi.al` 引用19份Verilog文件和自身的两份约束，与主工程共用部分模块。主工程以外的4份RTL用于诊断和自检：

| 文件 | 用途 |
|---|---|
| `rtl/top/p0_hdmi_top.v`、`rtl/display/video_pattern_axis.v` | 无TF卡的基础HDMI视频诊断 |
| `rtl/storage/fat32_files.v`、`rtl/storage/fat32_volume.v` | 文件读取、挂载自检使用的薄包装 |

`sim/` 中的25个测试台、对应 `.do` 脚本和模型供功能验证使用，不加入综合。运行结果保存在 `sim/build/`，TD报告保存在仓库根目录的 `.local/td-build/`；生成文件不纳入源码管理。

操作和素材要求见[使用说明](../docs/使用说明.md)，模块契约见[系统设计](../docs/design/README.md)，仿真、实现和实板运行结果见[当前项目状况](../docs/当前项目状况.md)。
