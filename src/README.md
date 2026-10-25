# FPGA-player 源码与工程

主入口为 [td_project/lean_player.al](td_project/lean_player.al)，板级顶层为 `rtl/top/lean_player_top.v`。本目录包含播放器、基础HDMI诊断以及功能自检所需的源码和脚本。

| 目录 | 内容 |
|---|---|
| `rtl/common/` | PLL树、复位、FIFO、按键、UART及音频时基 |
| `rtl/storage/` | SD SPI、FAT32根目录/文件、原生SDRAM控制及双帧存储 |
| `rtl/media/` | BMP/WAV解析、图像装载及单路循环音频 |
| `rtl/display/` | 时序、行缓存扫描、ASCII状态及HDMI AXIS桥 |
| `rtl/top/` | 板级包装、播放核心/控制、HDMI和基础视频诊断 |
| `ip/` | 真实PLL、32K RAM及器件集成SDRAM原语包装 |
| `constraints/` | 两个工程的引脚和起始时序约束 |
| `sim/` | 当前功能相关的23项自检、脚本及独立模型 |
| `td_project/` | 主工程、诊断工程和综合入口 |

数据链路为TF → SD SPI/CDC → 已校验扇区 → FAT32 → BMP/WAV。BMP写入非活动帧，行缓存从活动帧读取；WAV进入双时钟样本FIFO，在视频域输出音频与ACR，最后连接厂商HDMI核。

操作和素材要求见[使用说明](../docs/使用说明.md)，模块契约见[系统设计](../docs/design/README.md)。SDRAM、PLL和HDMI原语参数仍须在TD与实物上确认；当前时序尚未通过。
