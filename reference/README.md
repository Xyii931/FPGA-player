# 厂商HDMI依赖与IP手册

本目录保存播放器正式工程直接使用的安路HDMI发送核、PHY和串行器包装，以及对应IP手册。文件取自提供的官方`lab_ex5_i2s`参考例程，保留原文件名、内容及相对目录。

## 工程依赖

下列文件位于`lab_ex5_i2s/src/user_source/hdl_source/`，由[lean_player.al](../src/td_project/lean_player.al)直接引用：

| 文件 | 用途 |
|---|---|
| [hdmi1.4b_transmitter_core/hdmi_1_4b_transmitter_core_wrapper.enc.v](lab_ex5_i2s/src/user_source/hdl_source/hdmi1.4b_transmitter_core/hdmi_1_4b_transmitter_core_wrapper.enc.v) | 厂商HDMI发送加密核 |
| [hdmi_phy_warpper.v](lab_ex5_i2s/src/user_source/hdl_source/hdmi_phy_warpper.v) | HDMI物理层包装 |
| [lane_lvds_10_1.v](lab_ex5_i2s/src/user_source/hdl_source/lane_lvds_10_1.v) | HDMI串行输出包装 |

IP接口和配置说明见[HDMI1.4b Transmitter手册](lab_ex5_i2s/doc/APUG092_HDMI1.4b_Transmitter_V1.0.docx)。

`src/ip/`中的PLL、RAM和SDRAM包装使用TD提供的EG4器件原语，参数来源保留在各文件注释中。文件系统、图片装载、旋转、缓存调度及播放控制的项目实现见[正式源码](../src/README.md)。

构建须使用支持上述加密核和器件原语的Anlogic TD环境，并遵守相关权利方的使用条款。工程操作见[TD工程说明](../src/td_project/README.md)，播放器使用方法见[使用说明](../docs/使用说明.md)。
