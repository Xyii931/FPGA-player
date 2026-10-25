# 正式工程源码

本目录保存播放器源码、硬件工程、约束、测试和素材工具。主要入口是 [player_top.v](rtl/top/player_top.v)，对应 TD工程 [player.al](td_project/player.al)。功能已编写并连接；2026-10-25已通过P0六项基础仿真、Storage十六项（含修复后复测）及部分Media定向测试和基础视频工程综合。完整播放器已发现严重资源超预算，综合检查未通过，布局布线及硬件验证尚未执行，见 [TD综合检查](../docs/record/2026-10-25-P0-TD综合检查.md)。

## 目录职责

| 目录 | 内容 | 使用场景 |
|---|---|---|
| [rtl/](rtl/README.md) | 通用逻辑、存储、媒体、显示和顶层模块 | 阅读及修改播放器功能 |
| `ip/` | 两个 PLL、集成 SDRAM 及显式32K块RAM包装 | 综合时加载真实器件原语 |
| `constraints/` | 播放器与基础视频工程各自的 ADC/SDC | TD 引脚分配及起始时序约束 |
| [td_project/](td_project/README.md) | `player.al`、`p0_hdmi.al` | TD 综合、实现和生成下载文件 |
| [sim/](sim/README.md) | 自检测试台、设备模型、ModelSim脚本和批量入口 | 在硬件验证前定位模块与集成问题 |
| [tools/](tools/README.md) | Python 素材转换与打包工具 | 准备音频、压缩图片、字库和 Flash 演示包 |

## 功能如何连接

```text
TF SPI ──────────────┐
Flash DEM1 ──────────┼─ 源切换 → FAT32/文件服务 → 播放列表/目录索引
TF连续BMP恢复目录 ──┘                         │
                         ┌───────────────────┴──────────────────┐
                         ↓                                      ↓
                  BMP/RLE1解码与变换                      WAV/APT0解码
                         ↓                                      ↓
                 帧槽/SDRAM → 转场/扫描                   双音轨缓冲/混音
                         ↓                                      ↓
                    颜色调整/OSD                         音量/提示音/ACR
                         └───────────────────┬──────────────────┘
                                             ↓
                                         HDMI核/PHY
```

按键、菜单与 UART 共用运行配置；Flash 保存设置并为字库和演示素材提供读取通道。告警通过常驻画面槽及真实事务取消/恢复流程接入播放控制。

## 维护入口与边界

- 板级接线看 `rtl/top/player_top.v`；播放流程看 `rtl/media/playlist_player_ctrl.v`；统一用户配置看 `rtl/top/player_ui_ctrl.v`。
- 协议、字段、地址和跨时钟域契约以 [设计02](../docs/design/02-模块接口规格.md) 为依据；本目录说明用于导航。
- 修改模块接口时同步检查实例、测试台与 TD清单。新增综合源码需加入 `player.al`，测试台及仿真模型不加入该工程。
- 正式 Verilog 已独立保存；不需要从 `.local/` 重新生成源码。后续直接维护正式文件。
- `player.al` 仍通过相对路径引用 `reference/lab_ex5_i2s/` 中三个 HDMI 核/PHY文件；移动工程时保留仓库相对结构。
- `p0_hdmi_top` 是基础视频诊断顶层，用于单独排查视频链路；正式播放使用 `player_top`。

当前 ADC/SDC 只是待核对基线。器件库、PLL、上电初值、引脚、资源、时序和整机性能需要通过实际工具与板测确认。
