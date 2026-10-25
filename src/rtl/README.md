# RTL 导航

本目录使用 Verilog-2001。信号沿用 `I_` 输入、`O_` 输出、`IO_` 双向端口及 `S_` 内部信号的命名风格。2026-10-25已通过P0六项基础仿真、Storage十六项（含修复后复测）及部分Media定向测试和基础视频工程综合；完整播放器及硬件仍待验证，具体范围见 [TD综合检查](../../docs/record/2026-10-25-P0-TD综合检查.md)。

## 模块分工

| 目录 | 职责 | 代表模块 |
|---|---|---|
| `common/` | 时钟、复位、CDC基础及板载输入/串口 | `pll_tree`、`reset_gen`、`reset_sync`、`async_fifo`、`board_inputs`、`uart_rx/tx` |
| `storage/` | TF/Flash、FAT32、文件服务及 SDRAM | `sd_storage`、`fat32_core`、`media_file_service`、`player_sector_source`、`flash_ctrl`、`native_sdram_ctrl`、`player_frame_memory` |
| `media/` | 素材索引、解码、变换、播放与音频时间线 | `media_scan_ctrl`、`image_load_pipeline`、`playlist_player_ctrl`、`wav_track_source`、`audio_playback`、`av_event_timeline` |
| `display/` | 帧槽、资源所有权、显示提交、行读取、转场和文字叠加 | `fb_slot_manager`、`display_host_owner`、`display_video_pipeline`、`scanout_engine`、`osd_menu_builder`、`glyph_cache` |
| `top/` | 多模块连接与板载控制 | `player_top`、`player_memory_top`、`player_autoplay`、`player_av_core`、`player_settings`、`player_osd`、`player_hdmi` |

模块名中的 `ctrl` 通常负责事务状态，`cdc` 负责跨域协议，`source` 提供文件/字节/样本，`pipeline` 或包装模块连接一条功能链。具体端口契约见 [设计02](../../docs/design/02-模块接口规格.md)。

## 从顶层阅读

1. `top/player_top.v`：PLL与复位、物理IO、统一UI/UART、设置/字库、媒体主体、颜色/OSD、HDMI以及LED。
2. `top/player_memory_top.v`：把播放主体的逻辑读写接入实际帧存储与 SDRAM。
3. `top/player_autoplay.v`：自动扫描、播放控制、音视频主体与控制跨域的集成入口。
4. `top/player_av_core.v`：媒体输入、图片装载、常驻安全页初始化、显示资源与音轨/时间线的连接。
5. `top/media_io.v`：存储/文件服务、索引扫描与图像/音频文件通路。

需要调整交互行为时读 `top/player_ui_ctrl.v` 与 `top/player_console.v`；调整播放切换、告警或恢复时读 `media/playlist_player_ctrl.v`。目录内还保留基础诊断及独立测试使用的模块，是否进入正式工程由 `player.al` 清单决定。

## 时钟与事务规则

| 时钟 | 目标频率 | 主要用途 |
|---|---:|---|
| 板载输入 | 50 MHz | PLL参考、启动计数、长按复位检测 |
| `O_sd_card_clk` | 100 MHz | TF/Flash侧逻辑；TF SPI位时钟由控制器生成 |
| `O_ext_mem_clk` | 125 MHz | 主控制与存储逻辑 |
| `O_ext_mem_clk_sft` | 125 MHz、配置180° | SDRAM移相通道 |
| `O_video_clk` | 25 MHz | 视频像素、音频采样调度及HDMI像素接口 |
| `O_hdmi_5x_clk` | 125 MHz | HDMI串行器 |

这些是待验证的PLL配置目标。真实频率、相位和锁定行为由 TD报告与板测确认。

- `pll_tree` 只连接真实PLL包装；PLL reset不由业务复位输出或失锁反馈生成。
- 跨域数据通过FIFO或稳定邮箱协议传递。修改时保留命令、结果和完整身份字段，不能只同步多位数据的各个位。
- `valid/ready` 接口在等待接收时保持载荷；事务成功与回收依赖真实返回。取消需要等待相关文件、内存和槽资源退休。
- 媒体重载/源切换通过隔离与排空完成，避免单独复位某侧FIFO或清除仍在使用的画面资源。
- 图片写入完成并由槽管理确认后才发布；前台切换和旧源退休分别处理。

上述规则关系到停钟、热插拔、取消及告警恢复。修改这些通路时，联读对应自检和 [验证方案](../../docs/design/07-验证方案.md)。
