# FPGA-player 功能自检

本目录提供播放器和基础诊断使用的24项ModelSim自检。默认套件为 `Lean`，从仓库根目录运行：

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
| `Storage` | 10 | SPI字节、SD PHY/CSD/扇区、扇区CDC、FAT挂载/簇链/文件、原生SDRAM，以及SD到目录扫描的集成测试 |
| `Media` | 4 | BMP、WAV、双时钟FIFO、音频帧FIFO |
| `Lean` | 6 | 文件源、控制、错误装载、完整四旋转视频、音频、播放整合 |
| `All` | 24 | 上述全部用例 |

`scan_chain` 使用 SD SPI 卡模型和稀疏 FAT32 镜像，检查 50 MHz SD 时钟、6.25 MHz SPI 工作速率下从读卡到发现四张图片的链路；它不能代替真实卡、布线和物理时序验证。

图片清屏阻塞时的音频并发检查可单独运行：

```powershell
$env:FPGA_PLAYER_CLEAR_CONTENTION = '1'
& ./src/sim/run_p0.ps1 -Suite Lean -Case lean_player_core
Remove-Item Env:FPGA_PLAYER_CLEAR_CONTENTION
```

该用例人为延长清屏等待并检查音频样本和欠载。另可将环境变量改为 `FPGA_PLAYER_SHARED_CONTENTION=1`，检查限制扇区传输速率时图片和音频并发读取；运行完后移除该变量。这些用例使用功能替身，不能证明实际 TF 卡吞吐和 HDMI 音质。

将环境变量设为 `FPGA_PLAYER_IMAGE_BACKPRESSURE=1` 可检查图片加载时写入阻塞：暂停图片写入220 ms（超过音频FIFO的170.7 ms容量），检查音频仍持续读取、样本连续，以及解除阻塞后的整帧像素。该测试人为制造阻塞，并使用扇区及帧存储功能模型，不能推断实板阻塞时长或确认物理故障原因。

设为 `FPGA_PLAYER_SPI_MEDIUM=1` 可通过真实 SD SPI 控制器与模拟卡运行图片、音频并发测试，并统计 30 ms 内的图片字节数；模型使用 512 字节簇、固定的读卡等待，帧存储仍是功能替身，所得速率不代表实际 TF 卡。

设为 `FPGA_PLAYER_SUSTAINED=1` 可运行 500 ms 连续播放压力测试：主机扇区替身每 320 个 83.333 MHz 周期传一字节（约 260 kB/s），同时加载图片，逐样本检查连续性、欠载和图片推进。测试使用长 WAV，避免短文件或大缓冲掩盖持续供数不足。

设为 `FPGA_PLAYER_NATIVE_MEDIA=1` 可将完整播放器接到真实 native SDRAM 控制器和独立器件模型，检查首次显示、显示期间切图、后台 WAV 播放、帧缓冲保护和写入退休；记录首帧及切图的仿真耗时，检查普通方向两张图片各恰好读取 1801 个数据扇区、写入 307200 个像素。此模式仍使用主机扇区替身，耗时不代表真实卡的加载时间。上述场景变量每次只设置一个，用完移除。

同时使用 SD SPI 与 native SDRAM 控制器的并发检查：

```powershell
$env:FPGA_PLAYER_BOARD_CONTENTION = '1'
try {
    & ./src/sim/run_p0.ps1 -Suite Lean -Case lean_player_core
} finally {
    Remove-Item Env:FPGA_PLAYER_BOARD_CONTENTION
}
```

该场景使用板级初始化周期数和长 WAV，在图片装载与实际 SDRAM 访问同时进行时，检查 30 ms 音频采样连续性、零欠载、图片字节推进及卡协议错误。它覆盖两控制器共同运行的供数路径，不等待整张图片完成。

完整两图加载另可选用下述长场景：

```powershell
$env:FPGA_PLAYER_BOARD_MEDIA = '1'
try {
    & ./src/sim/run_p0.ps1 -Suite Lean -Case lean_player_core
} finally {
    Remove-Item Env:FPGA_PLAYER_BOARD_MEDIA
}
```

该场景恢复两控制器的初始化等待，加载首图并切换到第二图，从音频开始播放起逐样本检查连续性和欠载。卡模型加入输出与连线延迟；两图仍须满足扇区数、像素写入数和显示内容检查。模型首帧与切图分别以 5 秒为上限，整体仿真超时为 12 秒；这些门限只用于发现模型内的重复读取或停滞，不是实际卡或板卡的性能保证。ModelSim 运行此场景可能需要较长时间。

`lean_video`对四次完整640×480 BMP进行4×307200逐像素黄金比较，并使用真实native SDRAM控制器与独立器件模型。`lean_image_loader`专查坏尺寸/签名、取消、终态/写入退休及重用。`lean_audio`检查分块WAV读取、循环、左右声道、音量/静音和ACR。`lean_player_core`检查四文件切换、并发音频、坏图跳过和拔卡重插。

完整视频和整合用例耗时较长。**不要同时启动同一个case**：每项使用固定工作库和原始日志目录；各批次归档区分运行。测试结果只适用于展开时的源码版本。

`native_sdram_ctrl`是短命令测试，检查读写数据与tag、跨行访问、停钟后的接口封锁、复位恢复，以及异步复位释放DQ驱动。它使用独立SDRAM器件模型，不能代替物理相位、电气和器件时序验证。

## 工具、日志和返回值

通过 `-VsimPath` 指定ModelSim的 `vsim.exe` 路径。中文仓库路径使用临时空闲盘符映射，不搬动源码。执行策略阻止脚本时，可使用进程级 `-ExecutionPolicy Bypass`。

ModelSim 10.1c（Tcl 8.4）若在自动优化阶段停滞，可加 `-NoVopt`：脚本为每个用例生成临时 `.do`，把 `-voptargs=+acc` 换成 `-novopt`。默认使用10.3c的vopt行为。`load_player_bram.do` 与RAM相关用例采用Tcl 8.4兼容写法，可直接 `source`。

每项失败继续收集其他项，所有项成功退出0，否则退出1。结果保存在 `build/<suite>/<批次>/summary.json`，包含各项退出码、耗时及console/stderr/transcript路径；原始工作库与日志在 `build/<case>/`。每项要求transcript由对应运行刷新且含 `^# PASS`，并拒绝 `Startup command`、`syntax error` 等脚本错误；缺少PASS或transcript均判失败。仅编译成功或部分PASS不视为整个用例通过。

ModelSim 10.1c 示例：

```powershell
& ./src/sim/run_p0.ps1 -Suite All -NoVopt -VsimPath '<ModelSim安装目录>/vsim.exe'
```

## 模型边界

- `models/player_pll_models.v`：PLL功能替身，只由相关测试脚本加载，不与真实PLL包装同库。
- `models/sd_spi_card_model.v`：SD SPI卡端点。
- `models/sim_sdr_device.v`：独立SDRAM命令模型。
- `models/sim_lean_media_card.v`：主机域扇区端点，不覆盖SD SPI。
- `models/player_bram32k_model.v`：RAM功能替身，不验证原语映射。

`lean_player_core`默认使用帧存储功能端点；`FPGA_PLAYER_NATIVE_MEDIA=1` 时改用 native SDRAM 控制器和独立器件模型，`FPGA_PLAYER_BOARD_MEDIA=1` 进一步使用 SD SPI 控制器及卡模型。`lean_video` 另覆盖完整四方向逐像素比较。厂商HDMI核、PLL硬件相位、引脚、电气行为、实际供数与长期稳定性需TD和板测。

可选真实TD RAM模型：

```powershell
$env:FPGA_PLAYER_NATIVE_BRAM = '1'
try {
    & ./src/sim/run_p0.ps1 -Suite Media -Case async_fifo,audio_frame_fifo
} finally {
    Remove-Item Env:FPGA_PLAYER_NATIVE_BRAM
}
```

库目录位于TD安装目录中的 `sim_release/eg4`，可用 `FPGA_PLAYER_TD_SIM_DIR` 指定。`load_player_bram.do`保证每个工作库只选一种实现。厂商功能模型通过仍不代表物理映射、完整CDC或时序通过。

音频播放器还可用真实 TD RAM 模型检查 18000 个连续采样，跨越 8192 帧 FIFO 的两次地址回绕，包含 100 ms 上游服务暂停、循环、左右声道、音量/静音及 ACR 检查：

```powershell
$env:FPGA_PLAYER_NATIVE_BRAM = '1'
$env:FPGA_PLAYER_AUDIO_WRAP = '1'
try {
    & ./src/sim/run_p0.ps1 -Suite Lean -Case lean_audio
} finally {
    Remove-Item Env:FPGA_PLAYER_NATIVE_BRAM
    Remove-Item Env:FPGA_PLAYER_AUDIO_WRAP
}
```

已有验证的批次和限制见[验证记录](../../docs/verification.md)，实物验证顺序见[验证与上板](../../docs/验证与上板.md)。
