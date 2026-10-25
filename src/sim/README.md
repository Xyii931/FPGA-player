# 仿真与集中验证

本目录保存自检测试台、仿真端点模型、ModelSim `.do` 脚本和PowerShell批量入口。**2026-10-25用户授权后已实际运行P0六项、Storage十六项及多批Media定向测试，并依据失败日志修复。Media完整套件尚未全部通过；涉及后续RTL改动的用例须以相应最终复测为准。** 环境和基础结果见 [基础仿真记录](../../docs/record/2026-10-25-P0-基础仿真.md)，后续修复与定向测试见 [TD综合检查](../../docs/record/2026-10-25-P0-TD综合检查.md)；测试通过不代表阶段验收或硬件通过。

播放控制续测加入连续64次随机效果与原xorshift序列精确模7的比较、重排计算期间NEXT/PREV和GOTO覆盖，以及单项QUAD循环取图；索引读取检查最后一个物理标题的40—127全部非法地址。图片装载测试修正写命令保存宽度，目录源测试把反压施加到上一候选真正复制完之后，相关断言保留。显示视频链的`TAIL_ONLY=1`仅运行case14—16及最后正常提交，默认0仍为完整回归；局部通过须与完整运行区分，不能计为Media全套通过。

续测已完成105份脚本的独立编译检查；该检查没有展开或运行测试，不计作105项仿真通过。`player_console`新增全部双字节组合、完整16位有符号偏移范围、合法菜单步进闭包和恢复/UART同时请求检查；`async_fifo`增加实际375/434位控制载荷（包括非整字节高位），其满空、回绕、反压及停钟复位检查保留。`fb_line_reader`修正两处未跨采样沿的ready脉冲，`frame_commit_cdc`测试参数避开Verilog关键字；八份集成测试的共享信号声明移到首次使用之前。

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
| `Media` | 83 | 图像/音频、槽与显示链、时间线、播放策略、UI/UART、OSD、告警、演示与恢复 |
| `All` | 105 | 上述三套用例合并 |

计数对应当前 `run_p0.ps1`，新增用例时以脚本清单为准。`run_storage.ps1`、`run_media.ps1`只是对应套件的快捷入口。

运行器会通过Tcl `source`加载脚本，保证 `[info script]`定位到实际文件，并显式捕获加载/执行错误。旧版ModelSim在中文路径下不能可靠创建工作库；仓库路径包含非ASCII字符时，运行器自动建立临时空闲盘符映射，结束后释放，不复制或搬动项目文件。日志中的临时盘符路径对应当前仓库内的同一文件。

默认程序路径为 `D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe`，可覆盖：

```powershell
& ./src/sim/run_p0.ps1 -Suite All -VsimPath 'D:/你的安装目录/vsim.exe'
```

如PowerShell执行策略阻止脚本，可对本次进程使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./src/sim/run_p0.ps1 -Suite P0
```

单项复查仍使用运行器，以保留路径兼容和错误退出处理；用例必须属于指定套件：

```powershell
& ./src/sim/run_p0.ps1 -Suite P0 -Case reset_sync
& ./src/sim/run_p0.ps1 -Suite Media -Case demo_media,raw_recovery
& ./src/sim/run_p0.ps1 -Suite Media -Case osd_menu_builder,osd_text_video
```

`demo_media`保留真实DEM1 CRC、Flash CDC、FAT32挂载/路径/文件与后端退休检查，新增64图加64音轨（反序ID配对）的完整4096 B黄金列表比较、一次请求跨八扇区读取、每64 B边界反压、列表首条和下一条准备拍取消，以及重建9项无音轨目录后的有效字节/扇区补零/旧扇区隔离检查。元数据改为同步RAM后，另比较各次内部完整记录与不可变DEM1夹具原表，检查末条素材offset/size/CRC字序、根目录首/中/末扇区及FAT资产首末窗口的完整黄金字节、反压与旧目录隔离、完整16bit ID配对、重复/重叠/孤立音轨拒绝。资产、目录、FAT三类内部读取均在中途取消，要求内部读排空后才发终态。最大目录夹具使用CRC正确的一字节不透明载荷，仅测试目录所有者，不能证明图像或音轨可解码；原RLE/WAV字节用例保留。

后端缓冲同步化另增加1025 B和513 B不透明文件，通过真实FAT读取并逐字节比较；直接跨扇区读取覆盖完整512 B、末尾单字节、补零及EOF后旧内容隔离。Flash端插入字节间隙，输出端在首/末字节和短载荷边界反压；在首/中/末字节准备拍取消后再读，并分别破坏第二批首字节和第三批末字节，要求CRC拒绝。内部同步读和小头快照另对照不可变Flash夹具；不以此替代物理RAM验证。

`raw_recovery`比较恢复BMP列表完整文本及62 B/854 B文件的全部字节，后端插入字节间隙、文件接收端反压；不复位地重扫更短目录，在配对读取中途停用、排空后重启，核对旧第二素材变为新第一素材。最后一次重扫改为末字节与真实后端终态同拍到达，覆盖短文件、跨扇区和准备周期。两入口的新增检查已在17时后复测通过；测试不验证推断RAM映射或真实Flash/SD信号。

`osd_menu_builder`包含全部65536个16位值的十进制转换比较、三种输入模式（内部快照、整总线保持邮箱、标题RAM加小邮箱）的菜单/标题/告警字节和反压检查，以及稳定载荷CDC的全零首次发布、更新合并、停钟与在途共同复位。邮箱夹具分别使用16位和131位载荷，覆盖64位比较分组及末尾不足64位的分组，并在捕获与判断两拍之间改变输入，检查发布的仍是同沿快照。标题RAM夹具独立比较全部360 B，覆盖复制中途仅标题发布序号变化后的整份重试、非法读地址、边界发布、源更新期间保持旧快照、字体停钟、复制中共同复位及不变状态不重复发布；`player_layout`另检查应用标题、长度与发布序号同沿更新。菜单、标题RAM和布局新增检查已在17时后相应用例复测通过；具体批次见验证记录。`osd_text_video`比较完整640×480帧的文字图层像素，并在停止、恢复字体域时钟后再次比较整帧，检查渲染器增加准备拍后仍能按时供行。字体字节由测试端点提供，不能代替真实Flash和硬件CDC时序验证。

`osd_fonts`使用真实SPI控制器、Flash仲裁器、设置和字形缓存，Flash芯片由模型提供。除400槽CLOCK替换、locked/pin保护和错误重试外，还连续读取受保护字形，覆盖查询、替换、填充及元数据同地址读写；复位后检查400槽全部失效，再重新装入字形。另在候选槽译码完成后、替换决策之前增加pin，检查决策使用实时保护。这些RTL测试不能验证物理BRAM的冲突读写行为或真实Flash时序。

## 索引、缩放与音轨RAM的两种测试方式

索引、缩放、音轨及相关列表/目录、图像加载和AV集成脚本统一调用`load_player_bram.do`，每次只编译一个`player_bram32k`实现。默认加载`models/player_bram32k_model.v`，用于检查同步读、索引排序和bank保持协议；它不能证明32K原语参数、字节使能或真实硬件时序正确。`tb_media_index_store`另有4096×8、2560×8和1920×32三个RAM夹具，遍历全部合法地址，检查双端口读写、独立时钟、使能保持、各字节通道及写一半时读取另一半。`tb_image_scaler`在原有独立黄金像素比较之外，检查行bank完整装载及身份、一拍读回、完整地址未被截断，以及取消/复位后重用。这些检查已运行功能及TD原语模型测试；缩放器后续分拍版本的结果单列在验证记录中。

`async_fifo`保留四组原推断存储配置，增加四组48bit显式32K配置（含生产2048帧深度），使用独立队列比较每次握手的完整数据，覆盖满容量、至少八倍容量的连续流、回绕、反压及任一侧停钟时共同flush。`audio_frame_fifo`原双声道配对、2048帧和512/1024阈值自检保留；音轨回收、文件、淡化、时间线和显示音频测试入口也已补齐RAM依赖，均需重新运行。功能替身不验证真实双时钟原语或Gray总线物理时序。

先执行功能回归，再设置环境变量执行相同用例的真实TD包装/厂商模型检查；后者编译本机TD库及`src/ip/player_bram32k.v`，不同时加载功能替身。安装路径不同可设置`FPGA_PLAYER_TD_SIM_DIR`为TD的`sim_release/eg4`目录。原语模型解密/支持失败会报错退出，不自动回退为功能替身。

```powershell
& ./src/sim/run_p0.ps1 -Suite Media -Case media_index_store,playlist_index_builder,playlist_file_source,playlist_file_fat32,directory_index_source,directory_index_fat32,media_index_scan_fat32
& ./src/sim/run_p0.ps1 -Suite Media -Case image_scaler,bmp_image_scaler,image_transform,image_transform_writer,bmp_frame_loader,image_load_reservation,image_load_pipeline,player_av_core
& ./src/sim/run_p0.ps1 -Suite Storage -Case media_file_service
& ./src/sim/run_p0.ps1 -Suite Media -Case async_fifo,audio_frame_fifo,audio_playback,wav_track_source,wav_file_fat32,wav_audio_player,audio_prepare_guard,av_timeline_wav,display_audio_pipeline
$env:FPGA_PLAYER_NATIVE_BRAM = '1'
try {
    & ./src/sim/run_p0.ps1 -Suite Media -Case media_index_store,image_scaler,async_fifo,audio_frame_fifo
} finally {
    Remove-Item Env:FPGA_PLAYER_NATIVE_BRAM
}
```

日志会明确写出所用实现。厂商模型即使通过也不替代TD实际块映射、整机容量、布局布线或板测；本轮未执行上述命令。

## 日志与结果

批量脚本为每个用例启动独立ModelSim进程；某项失败后继续收集其他结果。全部成功返回0，存在失败返回1；程序路径不存在时直接报错。分套件运行时，每次执行后立即查看 `$LASTEXITCODE`；连续运行后该变量只表示最后一次脚本的退出码，各批次的完整结果保存在各自的 `summary.json`。

```text
src/sim/build/<suite>/<run-id>/
  summary.json              每项Passed、ExitCode、耗时及日志路径
  <case>-console.log        标准输出
  <case>-stderr.log         标准错误
  <case>-startup.log        脚本切换transcript前的启动日志
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
| `models/player_bram32k_model.v` | 索引、缩放及音轨双端口RAM功能替身，仅由测试脚本加载，不验证32K原语 |

PLL替身与真实包装同名，只由相关测试脚本选用，不与真实PLL文件同时加载。其他用例也可能在测试台中提供明确的文件、字节或内存协议端点，覆盖范围需结合测试台开头说明阅读。

近期功能用例包括 `resident_frame`（常驻页写入/槽管理）、`demo_media`（DEM1校验/Flash CDC/FAT32）、`raw_recovery`（连续BMP扫描/目录/文件读取），以及已有 `player_layout`、`wav_track_source` 中的告警/书签恢复场景。

## 验证边界

仿真通过后仍须验证TD原语/加密核、PLL频率与相位、上电初始化、实际引脚、资源和时序。端点模型不能证明TF/Flash/SDRAM电气行为、HDMI显示器兼容性或完整整机性能；TF/DEMO/恢复源切换、供数、告警时限及长期运行需要后续集成和板测。

[MEDIA.md](MEDIA.md)保留了较细的媒体测试场景及阶段记录，其中旧计数和当时的功能缺口不代表当前状态。当前运行方式看本页，接口看 [设计02](../../docs/design/02-模块接口规格.md)，验收标准看 [验证方案](../../docs/design/07-验证方案.md)。

当前各批原始summary、独立console日志及适用RTL范围见[授权复测记录](../../docs/record/2026-10-25-P0-TD综合检查.md)。`tb_image_scaler.FULL_SIZE`默认1，保留全部最大尺寸用例；设0仅用于局部排错，不能记作完整缩放回归。新增检查覆盖坐标/插值各分拍的取消与重用；APT解码自检还覆盖各算术阶段取消及接近4 GiB的长度边界。
