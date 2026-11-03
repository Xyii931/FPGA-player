# FPGA-player 源码与工程

主入口为 [td_project/lean_player.al](td_project/lean_player.al)，板级顶层为 `rtl/top/lean_player_top.v`。本目录包含播放器源码、器件IP包装、约束、构建脚本和功能自检。

| 目录 | 内容 |
|---|---|
| `rtl/common/` | PLL树、复位、FIFO、按键、UART及音频时基 |
| `rtl/storage/` | SD SPI、FAT32根目录/文件、原生SDRAM控制及双帧存储 |
| `rtl/media/` | BMP/WAV解析、图像装载、SDRAM音频缓存及循环播放 |
| `rtl/display/` | 时序、行缓存扫描、ASCII状态及HDMI AXIS桥 |
| `rtl/top/` | 板级包装、播放核心、播放控制和HDMI接口 |
| `ip/` | 真实PLL、32K RAM及器件集成SDRAM原语包装 |
| `constraints/` | 播放器的引脚和时序约束 |
| `sim/` | 当前功能相关的24项自检、脚本及独立模型 |
| `td_project/` | 播放器主工程及综合、布局布线入口 |

数据链路为TF → SD SPI/CDC → 已校验扇区 → FAT32 → BMP/WAV。BMP写入非活动帧，行缓存从活动帧读取。首图提交后，`lean_audio_cache`把完整WAV存入SDRAM，随后由`lean_audio`从缓存循环解码，送入双时钟样本FIFO，在视频域输出音频与ACR，最后连接厂商HDMI核。缓存完成后，音乐播放不再读取TF卡。

## 工程结构与依赖

主工程 `lean_player.al` 引用47份Verilog文件：本项目40份RTL、4份IP包装，以及参考目录中的3份厂商HDMI依赖；另引用 `player.adc` 和 `player.sdc`。这些依赖均使用相对路径，须保持仓库目录结构。

`rtl/storage/fat32_files.v`和`rtl/storage/fat32_volume.v`是文件读取与挂载自检使用的薄包装，不加入主工程。

`sim/`中的24个测试台、对应`.do`脚本和模型供功能验证使用，不加入综合。统一入口为[run_tests.ps1](sim/run_tests.ps1)。运行结果保存在`sim/build/`，TD报告保存在仓库根目录的`.local/td-build/`；生成文件不纳入源码管理。

操作和素材要求见[使用说明](../docs/使用说明.md)，模块契约见[系统设计](../docs/design/README.md)，仿真、实现和实板运行结果见[当前项目状况](../docs/当前项目状况.md)。
