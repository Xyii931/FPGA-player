# FPGA-player 功能自检

本目录提供播放器和基础诊断使用的22项ModelSim自检。默认套件为 `Lean`，从仓库根目录运行：

```powershell
& ./src/sim/run_p0.ps1 -Suite P0
& ./src/sim/run_p0.ps1 -Suite Storage
& ./src/sim/run_p0.ps1 -Suite Media
& ./src/sim/run_p0.ps1 -Suite Lean
```

`-Suite All`可代替上述四次运行。单项示例：

```powershell
& ./src/sim/run_p0.ps1 -Suite Lean -Case lean_media_source,lean_player_ctrl,lean_image_loader
& ./src/sim/run_p0.ps1 -Suite Lean -Case lean_video,lean_player_core
```

| 套件 | 项数 | 范围 |
|---|---:|---|
| `P0` | 4 | reset_sync、reset_gen、PLL树、基础HDMI视频源 |
| `Storage` | 8 | SPI字节、SD PHY/CSD/扇区、扇区CDC、FAT挂载/簇链/文件 |
| `Media` | 4 | BMP、WAV、双时钟FIFO、音频帧FIFO |
| `Lean` | 6 | 文件源、控制、错误装载、完整四旋转视频、音频、播放整合 |
| `All` | 22 | 上述全部用例 |

`lean_video`对四次完整640×480 BMP进行4×307200逐像素黄金比较，并使用真实native SDRAM控制器与独立器件模型。`lean_image_loader`专查坏尺寸/签名、取消、终态/写入退休及重用。`lean_audio`检查分块WAV读取、循环、左右声道、音量/静音和ACR。`lean_player_core`检查四文件切换、并发音频、坏图跳过和拔卡重插。

完整视频和整合用例在本机耗时较长。**不要同时启动同一个case**：每项使用固定工作库和原始日志目录；各批次归档才区分运行。源码改变后，旧进程结果只适用于其展开时的版本。

## 工具、日志和返回值

默认ModelSim为 `D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe`，可用 `-VsimPath` 覆盖。中文仓库路径使用临时空闲盘符映射，不搬动源码。执行策略阻止脚本时，可使用进程级 `-ExecutionPolicy Bypass`。

每项失败继续收集其他项，所有项成功退出0，否则退出1。结果保存在 `build/<suite>/<批次>/summary.json`，包含各项退出码、耗时及console/stderr/transcript路径；原始工作库与日志在 `build/<case>/`。先找首个编译/加载错误或自检FAIL，不把波形活动、仅编译成功或部分PASS当作整个用例通过。

## 模型边界

- `models/player_pll_models.v`：PLL功能替身，只由相关测试脚本加载，不与真实PLL包装同库。
- `models/sd_spi_card_model.v`：SD SPI卡端点。
- `models/sim_sdr_device.v`：独立SDRAM命令模型。
- `models/sim_lean_media_card.v`：主机域扇区端点，不覆盖SD SPI。
- `models/player_bram32k_model.v`：RAM功能替身，不验证原语映射。

`lean_player_core`中的帧存储端点不代表真实SDRAM，native SDRAM另由`lean_video`覆盖。厂商HDMI核、PLL硬件相位、引脚、电气行为、实际供数与长期稳定性需TD和板测。

可选真实TD RAM模型：

```powershell
$env:FPGA_PLAYER_NATIVE_BRAM = '1'
try {
    & ./src/sim/run_p0.ps1 -Suite Media -Case async_fifo,audio_frame_fifo
} finally {
    Remove-Item Env:FPGA_PLAYER_NATIVE_BRAM
}
```

库目录默认位于本机TD安装的 `sim_release/eg4`，可用 `FPGA_PLAYER_TD_SIM_DIR` 覆盖。`load_player_bram.do`保证每个工作库只选一种实现。厂商功能模型通过仍不代表物理映射、完整CDC或时序通过。

已有验证的批次和限制见[验证记录](../../docs/verification.md)，实物验证顺序见[验证与上板](../../docs/验证与上板.md)。
