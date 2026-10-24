# 仿真与集中验证

本目录保存自检测试台、仿真端点模型、ModelSim `.do` 脚本和PowerShell批量入口。**所有HDL用例均已准备但尚未编译或运行，没有仿真通过记录。**

## 运行入口

在仓库根目录打开PowerShell，建议先基础、再存储、再媒体：

```powershell
& ./src/sim/run_p0.ps1 -Suite P0
& ./src/sim/run_p0.ps1 -Suite Storage
& ./src/sim/run_p0.ps1 -Suite Media
```

或者用 `All` 代替上述三次运行，无需重复执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

| 套件 | 当前用例数 | 主要范围 |
|---|---:|---|
| `P0`（默认） | 6 | 复位、PLL连接/失锁、时钟监测、基础视频源 |
| `Storage` | 16 | SPI/TF、容量、扇区CDC、FAT32、文件服务、帧存储、Flash设置 |
| `Media` | 82 | 图像/音频、槽与显示链、时间线、播放策略、UI/UART、OSD、告警、演示与恢复 |
| `All` | 104 | 上述三套用例合并 |

计数对应当前 `run_p0.ps1`，新增用例时以脚本清单为准。`run_storage.ps1`、`run_media.ps1`只是对应套件的快捷入口。

默认程序路径为 `D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe`，可覆盖：

```powershell
& ./src/sim/run_p0.ps1 -Suite All -VsimPath 'D:/你的安装目录/vsim.exe'
```

如PowerShell执行策略阻止脚本，可对本次进程使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./src/sim/run_p0.ps1 -Suite P0
```

单项复查示例：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_demo_media.do'
```

## 日志与结果

批量脚本为每个用例启动独立ModelSim进程；某项失败后继续收集其他结果。全部成功返回0，存在失败返回1；程序路径不存在时直接报错。分套件运行时，每次执行后立即查看 `$LASTEXITCODE`；连续运行后该变量只表示最后一次脚本的退出码，各批次的完整结果保存在各自的 `summary.json`。

```text
src/sim/build/<suite>/<run-id>/
  summary.json              每项Passed、ExitCode、耗时及日志路径
  <case>-console.log        标准输出
  <case>-stderr.log         标准错误
  <case>.log                本次生成的用例日志副本（若存在）

src/sim/build/<case>/        各.do脚本的工作库和原始日志
```

先看 `summary.json` 中失败的Case，再读该项日志中的首个编译/加载错误或自检失败。批次目录区分不同运行，不要把旧日志当成当前结果。`.do`脚本按各测试台完成标志和失败退出码判断结果，看到波形活动不代表通过。

## 文件与模型

| 文件 | 用途 |
|---|---|
| `tb_*.v` | 独立模块或集成功能的自检测试台 |
| `run_*.do` | 选择所需真实模块与模型，建立工作库、执行并返回退出码 |
| `models/player_pll_models.v` | PLL替身，模拟时钟、锁定延迟、失锁、停钟与恢复 |
| `models/sd_spi_card_model.v` | TF SPI卡的测试模型 |
| `models/sim_spi_nor.v` | SPI NOR Flash测试模型 |
| `models/sim_sdr_device.v` | SDRAM器件测试模型 |

PLL替身与真实包装同名，只由相关测试脚本选用，不与真实PLL文件同时加载。其他用例也可能在测试台中提供明确的文件、字节或内存协议端点，覆盖范围需结合测试台开头说明阅读。

近期功能用例包括 `resident_frame`（常驻页写入/槽管理）、`demo_media`（DEM1校验/Flash CDC/FAT32）、`raw_recovery`（连续BMP扫描/目录/文件读取），以及已有 `player_layout`、`wav_track_source` 中的告警/书签恢复场景。

## 验证边界

仿真通过后仍须验证TD原语/加密核、PLL频率与相位、上电初始化、实际引脚、资源和时序。端点模型不能证明TF/Flash/SDRAM电气行为、HDMI显示器兼容性或完整整机性能；TF/DEMO/恢复源切换、供数、告警时限及长期运行需要后续集成和板测。

[MEDIA.md](MEDIA.md)保留了较细的媒体测试场景及阶段记录，其中旧计数和当时的功能缺口不代表当前状态。当前运行方式看本页，接口看 [设计02](../../docs/design/02-模块接口规格.md)，验收标准看 [验证方案](../../docs/design/07-验证方案.md)。
