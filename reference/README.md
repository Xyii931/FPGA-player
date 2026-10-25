# 参考例程与厂商IP资料

本目录保存提供的TF/HDMI、I2S/音频实验工程、厂商IP手册、源文件和示例素材，用于查阅板级接口、核对IP参数及阅读实验实现。播放器正式工程位于 [src/](../src/README.md)，其使用方法见[项目使用说明](../docs/使用说明.md)。

| 资料 | 内容入口 | 工程入口 |
|---|---|---|
| `lab_ex4_tf` | [代码说明](lab_ex4_tf/代码说明.md)、[设计文档](lab_ex4_tf/设计参考例程文档.md) | [lab_ex5_i2s_v1.0.al](lab_ex4_tf/src/td_project/lab_ex5_i2s_v1.0.al) |
| `lab_ex5_i2s` | [代码说明](lab_ex5_i2s/代码说明.md)、[设计文档](lab_ex5_i2s/设计参考例程文档.md) | [HDMI1.4b_Transmitter_v1.0.al](lab_ex5_i2s/src/td_project/HDMI1.4b_Transmitter_v1.0.al) |

原资料的标题和工程名存在不一致：第一套工程名含i2s，两份代码说明沿用了TF视频标题。阅读时应结合实际顶层判断；原文件保持原内容。原TD工程含生成机器路径，若单独使用，需在本机核对源路径、工具版本和约束，未对其重新进行综合或硬件验证。

## 文件位置

- `src/user_source/hdl_source/`：参考顶层、存储、HDMI及音频逻辑，含IP、ROM和初始化文件。
- `src/user_source/constraints_source/`：原板级引脚与时序约束。
- `src/td_project/`、`al_ip/`：TD工程及IP配置。
- `doc/`：HDMI IP手册、图片素材、转换与写卡工具。
- 根部MD/DOCX：对应实验说明和设计文档。

参考实验的写卡工具及素材协议只适用于对应实验，使用前需阅读其说明和源码。播放器读取FAT32中的BMP/WAV文件，格式以项目使用说明为准。

## 正式工程使用的厂商依赖

主工程直接引用 `lab_ex5_i2s/src/user_source/hdl_source/` 中三份文件：

- `hdmi1.4b_transmitter_core/hdmi_1_4b_transmitter_core_wrapper.enc.v`：厂商HDMI发送加密核。
- `hdmi_phy_warpper.v`：HDMI物理层包装。
- `lane_lvds_10_1.v`：串行输出包装。

`src/ip/player_sys_pll.v`、`player_video_pll.v`和`player_sdram_phy.v`的参数来源在文件注释中注明，可结合例程IP目录核对。文件系统、图片装载、旋转、双帧调度和播放控制的项目实现见正式RTL。厂商加密核与器件原语是工程依赖，复现须使用支持这些依赖的TD环境，并遵守相关权利方的使用条款。

构建缓存、日志和工具用户配置不属于参考源文件，不纳入提交。
