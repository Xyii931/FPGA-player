# RTL导航

使用Verilog-2001，命名沿用 `I_` 输入、`O_` 输出、`IO_` 双向端口和 `S_` 内部信号。

建议按以下顺序阅读：

1. `top/lean_player_top.v`：板级引脚、启动、PLL/复位、TF、SDRAM和HDMI连接。
2. `top/lean_player_core.v`：图片目标/装载/提交状态、音频请求仲裁和状态跨域。
3. `storage/lean_media_source.v`、`lean_root_scan.v`：FAT32根目录、最多16图/首WAV及两文件上下文。
4. `media/lean_image_loader.v`、`bmp_parser.v`：整帧清空、固定尺寸解码、四方向映射及失败退休。
5. `display/lean_scanout.v`、`storage/lean_frame_memory.v`：双帧、双行bank、帧边界提交及原生SDRAM。
6. `media/lean_audio.v`：有界WAV补充、单路FIFO、音量和48 kHz输出。
7. `top/lean_player_ctrl.v`、`display/lean_status_osd.v`：按键、短UART命令和ASCII状态。

`storage/fat32_files.v` 与 `fat32_volume.v` 是独立文件/挂载自检使用的薄包装，不属于主工程实例层次。`top/p0_hdmi_top.v` 和 `display/video_pattern_axis.v` 用于基础HDMI诊断。

连接时必须保持：

- `I_pll_reset`独立产生，同时进入两个PLL，不能由业务复位或失锁反馈驱动。
- 文件字节、Begin、终态与取消握手分别退休，掉卡不局部清空CDC队列。
- 新帧必须等解析、文件终态及实际存储写入全部完成后提交。
- 旧帧读事件全部退休并收到提交ACK后，才允许重写旧slot。
- `bmp_parser`输出RRGGBBAA，帧存储为ffRRGGBB；音频配置在视频域一致采纳。

详细端口和错误约定见[系统设计](../../docs/design/README.md)。当前未完成时序收敛及硬件验收，不能仅凭RTL或功能模型判断真实PLL、RAM和HDMI行为。
