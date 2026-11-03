# FPGA-player 功能自检

本目录提供24项ModelSim自检。从仓库根目录运行：

```powershell
& ./src/sim/run_tests.ps1 -Suite All
```

| 套件 | 项数 | 范围 |
|---|---:|---|
| `Common` | 3 | 复位同步、复位管理与PLL功能模型 |
| `Storage` | 10 | SPI字节、SD PHY/CSD/扇区、扇区CDC、FAT挂载/簇链/文件、原生SDRAM及读卡到目录扫描集成 |
| `Media` | 4 | BMP、WAV、双时钟FIFO、音频帧FIFO |
| `Lean` | 7 | 文件源、控制、图像装载、四方向视频、音频、SDRAM音频缓存、播放器集成 |

默认套件为`Lean`。使用`-Case`选择所属套件中的单项：

```powershell
& ./src/sim/run_tests.ps1 -Suite Storage -Case scan_chain
& ./src/sim/run_tests.ps1 -Suite Lean -Case lean_audio_cache
& ./src/sim/run_tests.ps1 -Suite Lean -Case lean_video,lean_player_core
```

## 音频缓存

正式工程默认`AUDIO_CACHE=1`。`lean_audio_cache`单元测试连接实际native SDRAM控制器和独立器件模型，检查首图许可、字节打包、尾字补零、写入退休、读取范围、取消、文件错误、Begin失败、旧读返回排空与媒体恢复。

```powershell
& ./src/sim/run_tests.ps1 -Suite Lean -Case lean_audio_cache
```

额外设置`FPGA_PLAYER_CACHE_FULL=1`，同一测试会填满4194304字节，检查最后合法字地址及尾部读取。运行后移除该环境变量。

缓存配置的音频解码测试检查逐样本PCM、左右声道、循环、音量、静音、ACR及100 ms上游暂停：

```powershell
$env:FPGA_PLAYER_AUDIO_CACHE = '1'
try {
    & ./src/sim/run_tests.ps1 -Suite Lean -Case lean_audio
} finally {
    Remove-Item Env:FPGA_PLAYER_AUDIO_CACHE
}
```

该测试使用功能字存储端点。`AUDIO_TRAFFIC`记录采样数、欠载及文件源命令和字节数；设置`FPGA_PLAYER_AUDIO_CACHE=0`可选择直接文件供数接口。

正式缓存配置的播放器集成测试：

```powershell
$env:FPGA_PLAYER_CACHED_MEDIA = '1'
try {
    & ./src/sim/run_tests.ps1 -Suite Lean -Case lean_player_core
} finally {
    Remove-Item Env:FPGA_PLAYER_CACHED_MEDIA
}
```

此场景使用实际native SDRAM控制器和独立器件模型，检查首图优先、完整WAV缓存、播放中切图与90°旋转、逐帧307200像素、连续音频、零欠载，以及拔卡重插后的缓存撤销与重建。缓存就绪后检查TF音频请求不增加。SD侧使用功能扇区端点。

## 图像与存储

`lean_video`对四个方向分别进行完整640×480输出的逐像素比较，使用实际native SDRAM控制器与独立器件模型。`lean_image_loader`检查坏尺寸/签名、取消、文件终态、写入退休及缓冲复用。

`native_sdram_ctrl`检查读写数据与tag、跨行访问、停钟封锁、复位恢复及异步复位释放DQ驱动。`scan_chain`使用SD SPI卡模型和稀疏FAT32镜像，检查50 MHz SD时钟、8.333 MHz SPI下从读卡到发现四张图片的链路。

`lean_player_core`测试台的默认配置为`AUDIO_CACHE=0`，检查文件服务和流式供数；`FPGA_PLAYER_CACHED_MEDIA=1`切换到正式缓存配置。以下扩展场景各次只选择一个，变量名均以`FPGA_PLAYER_`开头、值为`1`：

| 变量后缀 | 检查内容 |
|---|---|
| `CACHED_MEDIA` | 完整WAV缓存、native SDRAM、切图旋转及媒体恢复 |
| `NATIVE_MEDIA` | native SDRAM与功能扇区端点，完成两图装载及并发音频 |
| `BOARD_MEDIA` | SD SPI与native SDRAM控制器共同运行，完成两图装载 |
| `BOARD_CONTENTION` | 双控制器30 ms并发供数、样本连续及图片推进 |
| `SUSTAINED` | 约260 kB/s扇区端点下500 ms连续音频与图片并发 |
| `SPI_CONTENTION` / `SPI_MEDIUM` | SD SPI控制器与卡模型的图片/音频并发 |
| `IMAGE_BACKPRESSURE` | 图片写入阻塞220 ms时音频连续，解除后完整像素比较 |
| `CLEAR_CONTENTION` | 旋转清屏阻塞时的音频并发 |
| `SHARED_CONTENTION` / `SHARED_LONG` | 限制扇区速率时的共享供数 |
| `PERFORMANCE` | 双控制器下装载、切图、旋转计时及完整帧比较 |

除`CACHED_MEDIA`外，表中场景使用`AUDIO_CACHE=0`。例如运行双控制器文件供数测试：

```powershell
$env:FPGA_PLAYER_BOARD_MEDIA = '1'
try {
    & ./src/sim/run_tests.ps1 -Suite Lean -Case lean_player_core
} finally {
    Remove-Item Env:FPGA_PLAYER_BOARD_MEDIA
}
```

`PERFORMANCE`可附加`FPGA_PLAYER_ROTATE_ONLY=1`，只检查首图和一次90°旋转；`FPGA_PLAYER_SPI_DIVIDER`接受4—65534内的偶数，默认6。50 MHz SD域下分频6对应8.333 MHz SPI。仿真计时用于模型内测量。

## TD RAM模型

RAM相关测试默认使用功能模型。选择TD安装目录的RAM模型：

```powershell
$env:FPGA_PLAYER_NATIVE_BRAM = '1'
try {
    & ./src/sim/run_tests.ps1 -Suite Media -Case async_fifo,audio_frame_fifo
} finally {
    Remove-Item Env:FPGA_PLAYER_NATIVE_BRAM
}
```

库目录默认为TD安装目录中的`sim_release/eg4`，可用`FPGA_PLAYER_TD_SIM_DIR`指定。`load_player_bram.do`保证每个工作库只加载一种实现。

音频缓存配置可同时检查18000个连续采样，覆盖8192帧FIFO两次地址回绕：

```powershell
$env:FPGA_PLAYER_AUDIO_CACHE = '1'
$env:FPGA_PLAYER_NATIVE_BRAM = '1'
$env:FPGA_PLAYER_AUDIO_WRAP = '1'
try {
    & ./src/sim/run_tests.ps1 -Suite Lean -Case lean_audio
} finally {
    Remove-Item Env:FPGA_PLAYER_AUDIO_CACHE, Env:FPGA_PLAYER_NATIVE_BRAM, Env:FPGA_PLAYER_AUDIO_WRAP
}
```

## 工具与结果

通过`-VsimPath`指定ModelSim的`vsim.exe`。脚本将中文仓库路径映射到临时空闲盘符。ModelSim 10.1c的自动优化存在兼容问题时，使用`-NoVopt`：

```powershell
& ./src/sim/run_tests.ps1 -Suite All -NoVopt -VsimPath '<ModelSim安装目录>/vsim.exe'
```

每项独立运行；全部成功退出0，否则退出1。结果归档在`build/<suite>/<批次>/summary.json`，包含退出码、耗时及日志路径；原始工作库位于`build/<case>/`。通过条件为本次transcript已刷新、包含PASS、退出码为0且无脚本错误。

完整视频、容量和集成测试耗时较长。同一个case共用工作库，不要并发运行。

## 模型范围

| 模型 | 用途 |
|---|---|
| `player_pll_models.v` | PLL功能替身，由测试脚本加载 |
| `sd_spi_card_model.v` | SD SPI卡端点 |
| `sim_sdr_device.v` | 独立SDRAM命令模型 |
| `sim_lean_media_card.v` | 主机域功能扇区端点 |
| `player_bram32k_model.v` | RAM功能端点 |

测试模型不进入综合。厂商加密HDMI核、PLL硬件相位、引脚及电气行为通过TD与实板检查。测试结果见[验证记录](../../docs/verification.md)，板测步骤见[验证与上板](../../docs/验证与上板.md)。
