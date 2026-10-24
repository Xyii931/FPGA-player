# 媒体模块集中验证

本批目录候选及根目录回退、素材索引存储、播放列表/BMP/WAV解析、BMP文件供数及完整离屏帧装载所有者、双源行预取与缓存交接、帧配置提交CDC及真实首行门控、候选首行准备/按bank回收、七转场坐标与RGB混合、WAV文件所有者、音频基础、异步缓冲、单轨欠载包络、混音、读侧集成、槽回收协议及整段转场所有者RTL和自检已准备，尚未编译、仿真或综合。使用项目RTL和显式协议端点，列表、目录、BMP及WAV文件集成用例包含真实FAT32 core；无需实体TF卡、SDRAM或HDMI IP，可以和P0分开验证；提前编写不表示P1/P2/P3已验收。Media当前六十六组用例，All合计八十五组（含Storage十三组）；默认P0仍为原六组。

仓库根目录执行：

```powershell
& ./src/sim/run_media.ps1
$LASTEXITCODE
```

也可一次运行全部已准备用例：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

两种入口均可用 `-VsimPath '实际vsim.exe路径'`。媒体批次日志在 `src/sim/build/media/<批次>/`；全量批次在 `src/sim/build/all/<批次>/`，均有summary.json、控制台和错误日志。操作失败保留日志，不以脚本存在或静态检查替代仿真结果。

## BMP解析器及接入边界

- 在125 MHz域启动file_size/tag事务，随后按原始文件顺序供应字节；每次valid&&ready才推进。源在反压时须保持data/last，last标记实际文件末尾。
- 先握手元数据，再输出RGBA及归一坐标；正高BMP从底行到顶行到达，不能按输出次序直接假定顶行先。BGRA原alpha丢弃，输出alpha统一255。
- 输入允许头后间隙和末尾附加字节，全部消费后且待传像素完成握手才成功done。头部bfSize必须与实际文件大小一致，biSizeImage为0或精确跨度×高度；其他格式拒绝。
- 下游必须写未提交的离屏槽；成功done才能转READY，err/abort时释放或作废整个装载结果。已传像素不能在后续读错时撤回。
- 读失败用I_stream_error，取消用I_abort，两者均在同域传入；错误终态后上游停止旧流。重新启动前必须排空/取消旧读取上下文，parser不负责区分无tag的晚返回字节。
- 模块无内部看门狗；源停止供数不等于EOF，须由上层按事务超时取消。reset直接清事务，不产生完成事件。

## 自检准备的场景

合法文件覆盖24/32-bit、正负高度、1×1、24-bit四种padding跨度、头后间隙、末尾字节、biSizeImage=0、BGRA非255输入alpha；逐像素检查颜色/坐标/last和数量。元数据及像素端使用长等待和伪随机反压，检查等待期间载荷稳定、tag匹配和终态只出现一次。

非法输入覆盖签名、DIB、planes、bpp、compression、0/负/过大宽度、0/过大/INT_MIN高度、越界offset、短文件、bfSize/biSizeImage不一致、早last/缺失last、读错及取消后再启动。1920×1080仅验证头部接受与元数据后取消，不宣称跑过最大图的全部像素。

当前没有实际仿真结果或资源报告；本轮不会把解析器接到仍未核实的SDRAM接口，也不把这些定向用例代替完整播放器集成验证。

## 音频基础自检

`audio_foundation`用例覆盖：

- 默认25 MHz采样累加器按独立闭式计数公式比较每拍进位，检查首拍521、后续520/521拍间隔及复位后的重新起相；运行250000像素拍和另一次60000拍的复位重启段。
- 固定ACR每48次采样事件产生一次N6144/CTS25000；测量模式跳过首边界，按独立时钟沿编号比较完整窗口，预期约25000拍。检验寄存tick到ACR的一拍消费延迟。
- 单独N128测量实例检查1、37、1048575拍精确间隔、1048576拍溢出不发valid、溢出历史保留、后续正常窗恢复及reset清除；不向真实HDMI核发送这些测试参数。
- PCM一级弹性寄存器遍历全部65536种16-bit码值，双声道用互补码型，与有符号整数乘256的参考值比较；核对索引/last、背压载荷稳定、连续接受/发送及待传数据复位丢弃后重入。

音频模块接入时，samp_tick和acr_gen都在像素域，暂停/静音不得停采样；PCM转换器按其数据源所在域工作，跨到像素域用异步FIFO，接口见设计02 §5.13。当前WAV顺序解析、单音轨缓冲、欠载包络、混音与双轨读侧集成已编写，尚无解码双上下文或文件音频HDMI接入；这些测试不证明音质、真实采样频率或终端兼容性。p0_hdmi_top继续保持静音视频配置，TD工程不加入本批音频文件。

## WAV解析与自检

`wav_parser`在125 MHz文件流域工作，接收从文件偏移0开始的valid/ready字节流，先发布data_offset/data_bytes/total_frames，再输出PCM24双声道、sample_index和sample_last。启动、tag、取消、读错和终态约定见设计02 §5.13。仅支持fmt先于data的标准PCM16/48 kHz/双声道，拒绝浮点、扩展格式和重复fmt/data；无需在TF上试错才能验证这些格式分支。

`wav_parser`用例准备了以下检查：

- 标准44B头、fmt扩展、RIFF内多个奇/偶/空未知块、非零pad、文件尾字节，以及0帧data；检查恰好消费全部file_size字节。
- 正负满幅、零、小幅与左右互补采样，用独立有符号整数乘256比较每帧输出、index、最后标记及总数；输入空拍、元数据等待和输出长/随机反压时载荷稳定。
- RIFF/WAVE签名错误、RIFF范围64位溢出、短fmt、不支持的format/channels/rate/byte_rate/block_align/bits、data非4倍数和越界、缺失/重复fmt/data、data先于fmt。
- RIFF尾残缺块头、未知奇数块缺pad、早last/末尾缺last、输入读错、待传采样取消、部分头reset和重新启动；后续块坏时不能发成功终态。

`sample_last`只表示data最后一帧，之后可能仍有块或文件尾需要检查；done成功才代表整个文件流解析完成。与BMP后台帧不同，流式音频一旦播放不能撤回，后续错误必须由上层淡出、作废未播放缓冲并恢复。本组件尚无文件seek/断点恢复、双文件上下文或音轨预充策略，也不负责识别旧事务晚返回数据；单轨FIFO见下节，外部上下文和恢复策略仍需后续audio_decoder/调度器实现。

单独运行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_wav_parser.do'
```

当前所有场景仅准备了测试代码，未运行验证，不宣称样本值、RIFF边界或资源时序已通过。

## 双时钟FIFO与音轨缓冲

`async_fifo`提供通用valid/ready双时钟传输，`audio_frame_fifo`在其上包装一条音轨的48-bit双声道数据和水位。默认每轨2048帧（12 KiB RAM），后续两条音轨各实例化一路。容量包括预取中的当前头项，不能额外多写一项。所有FIFO源码和测试均未运行验证。

`async_fifo`自检准备四种配置：4项最小容量、16项快读/慢写、16项同频不同相位、2048项125 MHz写/25 MHz读。用独立队列对每次实际读写握手检查顺序、丢失/重复、容量和输出等待稳定；先填满停读，再长随机双向传输并多次回绕，排空后验证不重放旧RAM。另包含有未读数据时停读时钟并共享flush、读侧停钟时先填满、停止写时钟期间复位及恢复。模型不能模拟物理亚稳态或证明Gray偏斜达标。

`audio_frame_fifo`使用生产2048×48参数，逐帧比较左右声道与参考序列；停在0、511、512、1023、1024、2048帧水位并检查need_fill/prefilled门限，随后跨门限读空，检查满空反压及非空flush后不泄漏旧音频。

接入约定：

- 写侧通常为125 MHz解码域，读侧25 MHz像素域。valid/ready必须各在自己的时钟域使用；水位已在本地由同步指针计算，不要将两侧水位直接交叉采样。
- 两侧共同接同一 `I_async_flush` 请求，上电必须显式置位，内部各自异步置位、两拍同步释放。禁止单侧清指针；媒体切换先取消/隔离旧字节事务，再flush缓冲。此flush不接像素全局reset或HDMI reset，也不用于每次普通样本欠载。
- RAM仅存L/R48位，调用方必须独立维护文件身份、total_frames、sample_index和完成/错误事件，不能在接WAV时丢弃这些信息。先消费最后采样再处理文件上下文释放，不能只以FIFO空判定EOF。
- 预充标志只是“水位足够”的状态，不会自动播放或自动读走样本。暂停应停止消费该轨，采样节拍仍持续；单轨欠载判断见下节，音频读侧暂停见audio_playback；视频/系统时间线的完整暂停仍未接入。
- 写水位可偏高、读水位可偏低，都是跨域延迟带来的保守估计。它们不能替代实际已播放样本索引，更不能实现±500 ms音画偏移。
- TD接入时必须检查双口RAM推断及块映射、同步链、指针Gray总线最大延迟/偏斜和本域路径。当前未添加针对真实实例的CDC例外，不能用整个时钟域false path代替约束审查。

单独自检脚本为 `run_async_fifo.do` 和 `run_audio_frame_fifo.do`；通常直接执行 `run_media.ps1` 或 `run_p0.ps1 -Suite All` 一次收集，无需逐项往返。

## 单轨欠载包络

`audio_track_guard`接在每条audio_frame_fifo的读侧，clk/reset/tick及控制均在25 MHz域。FIFO的valid/left/right/prefilled接guard对应输入，guard的O_ready返回FIFO的I_ready。仅采样tick允许握手；每tick都输出一对有效PCM24，等待时输出零。不能将此不可反压输出直接接要求valid保持的弹性接口。输入tick沿之后更新输出，后级寄存器在下个沿接收，不要混用输入tick与寄存后valid。

起播及欠载恢复要求有效帧和重新预充，首帧1/64、64次消费后精确全幅。正在供数时缺帧只记一次O_underrun，快照最后实际输出，以63/64至0/64在64个采样内降零；淡出中不消耗FIFO，数据提前回流也等淡出完成再恢复。正常EOF、撤销供数许可同样淡出，不记欠载。O_consumed只对应真实FIFO握手，合成淡出与等待零样本不能推进文件位置。

外部上下文仍未实现，接入时必须满足：

- I_end是“全部真实采样已消费”，不能由FIFO空或解析done推导。I_tail_ready只允许在确认短尾已可读时放行，解决短文件不足1024帧无法起播；必须计入跨域可见延迟。
- I_enable为轨供数许可，不能直接连接系统PAUSE。完整暂停还须实时音轨短淡出、保存最后消费索引、停止消费并在恢复时重建锚点。本模块的保持值淡出不代表这些已经实现。
- 新轨或媒体flush必须一并清guard的包络与该轨FIFO，先隔离旧流；不复位视频基础设施。单纯欠载不flush。恢复迟到及音画重对齐由上层记录和处理。

`tb_audio_track_guard`准备逐采样整数参考检查：正负满幅、负数舍入、起播与部分渐入时欠载、恰64采样淡出、提前回流不打断淡出、预充门控、短尾、正常EOF、撤销许可、非tick不消费及非零淡出时异步复位；核对消费和欠载事件总数。独立脚本 `run_audio_track_guard.do` 已加入Media/All，尚未运行。它不验证双轨混音、真实FIFO集成、HDMI、音质、DSP资源或时序。

## 双轨混音与交叉淡化

`audio_mix`是两路guard之后的混音计算组件，参数默认FADE_SAMPLES=9600，对48 kHz为200 ms。命令握手后的下一采样开始，k=1..N的进度精确为floor(k×65536/N)，正反向权重相加恒为65536；末样本达到目标。同端点请求在下一采样直接完成。忙时反压新命令，直到末样本输出才发done并更新active_b。外部必须等待这个done后再释放旧轨，不能按已送入的样本数提前清上下文。

音量0—16（超范围钳16）和静音目标在采样边界更新，Q16增益每次最多变化1024，最多64采样到达精确目标；不停止输出valid。混合权重和主音量在流水中随样本传递，提示音PCM先叠加再衰减，最后饱和到24位，O_clipped随输出对齐。尚无提示音ROM或提示音自身包络；外部音源须处理自身起止边界。

接线：两路guard必须在同一个原始tick上运行，以其中一路寄存O_sample_valid接mix.I_sample_tick（同时保证另一路valid同拍），两组寄存PCM接A/B。mix有三级寄存流水，输入沿之后第2个后续上升沿产生输出；不能将未延迟的原始tick用于混音输入或HDMI valid。mix.O_sample_valid/left/right是后续HDMI采样口的数据来源，但本轮未连接真实HDMI。它不产生FIFO ready，guard启停、实际消费索引、EOF、恢复锚点和完整暂停仍由上层负责，不能认为权重为零便自动停止读轨。guard自身包络会额外缩放音轨，不承诺任意素材振幅随权重线性。

`tb_audio_mix`准备四种窗口9600/7/1/65536，用独立64位有符号除法黄金值逐采样核对PCM、饱和、增益及流水valid/done；覆盖双向全部窗口、同端点请求、命令与采样同拍、没有tick时不推进、连续/间歇输入、全部32种音量编码、静音/恢复和中途改目标音量、提示音饱和以及未排空流水时reset取消。脚本 `run_audio_mix.do` 已加入Media/All，尚未执行，不证明乘法器数量、25 MHz时序、真实双轨消费或播放音质。TD仍须审查DSP/LUT映射、宽位算术路径及整体资源预算。

## 双轨读侧集成与暂停

`audio_playback`在25 MHz域连接外部两路audio_frame_fifo的读口，内部实例化两路guard和mix。写侧、FIFO共同flush、可靠跨域元数据和旧事务隔离仍由上层提供。槽闲置时先flush外部FIFO、隔离旧写返回，再以load_valid/ready送total_frames/start_index；不能只清guard后把旧RAM队列当新文件。元数据非法时单拍load_error，不启用槽；next_index只按真实读握手增加，代表下一待消费帧，不是扬声器实际播放位置。

初次start只启动A；fade_valid/ready可切至准备好的B或切回A。未启用轨只预充，不自行消费。目标guard在接收切换时重建包络，命令延一拍进入mix，与新轨首样本对齐。fade_done在最终音频输出时发布，同时关闭旧轨并产生release_a/b；外部才能安全回收该槽，文件关闭/取消事务尚须自己完成。流水排出期间旧轨可能额外消费数帧，索引如实记录，不根据淡化长度猜索引。

pause为电平请求。已在切轨时先等待切换完成，并等待pause_allow（上层保证图像转场允许冻结），再持续消费64个采样并以独立后级包络降零；最后零样本排出后paused置1，保留FIFO和guard状态，不再消费，仍送有效零样本。恢复等待已启用轨可读，保留且运行中的轨不必强制重新凑1024帧；正常预充/短尾规则继续保护欠载轨。恢复渐入64步。此处只实现音频读侧暂停，视频冻结、UI/UART事件和全局时间线重关联尚未接入。

音量、静音、提示音控制在原始采样沿锁存，与guard采样对齐。输出比原始tick晚4个时钟；HDMI后续须使用本组件的寄存sample_valid，不能继续沿用原始tick。暂停包络覆盖整个混合输出，包含提示音；告警提示音的优先级调度尚未实现。

`tb_audio_playback`实际加载项目FIFO/guard/mix，125 MHz写、25 MHz读，缩小为每轨16帧、预充8帧及7采样切换以便定位；生产容量/9600窗由各独立测试准备覆盖。集成用独立帧序列和整数算术逐样本核对PCM、4拍valid、两轨绝对索引/消费事件、闲轨不消费、双向切换/旧轨释放、切换中暂停请求及allow延迟、淡出后冻结/保留恢复、start_index非零的短尾、正常EOF/零长度、欠载及补充恢复、错误元数据拒绝/重装。统一入口已包含 `run_audio_playback.do`，尚未运行；不证明CDC元数据传输、文件身份隔离、真实WAV读取、暂停的系统同步、DSP/时序或HDMI音质。

## WAV单轨供数与跨域事件

`wav_track_source`内含真实wav_parser、每轨48-bit audio_frame_fifo及独立85-bit事件FIFO。125 MHz侧接带完整16位epoch的WAV字节，25 MHz侧输出PCM和头/终态事件；并非将多位元数据直接接两拍触发器。PCM RAM仍按每轨2048×48预算，额外4×85事件存储和控制资源须单独由TD核对。

每次安全共同flush后只能start一个事务。字节流从start握手的下一拍开始，旧epoch或当前解析已结束时的字节会被接收并丢弃；低8位相同也不认为相同事务。流错误也须携带匹配epoch；本地abort取消当前活动解析。错误/取消发持续cancel_valid/ready给文件层，并产生一次跨域终态。终态在源域寄存至事件FIFO接受，避免将单拍done直接跨域。

读侧先接受header事件，随后PCM才有效；可将头信息映射为audio_playback对应槽的load事务，总帧数来自header、起点为0。成功终态表示文件解析完成，不表示FIFO播放完毕；错误终态接受后failed锁存并撤销未消费PCM（取消例外），上层须淡出/停用该轨，等待旧流水排空并回收。已经播放的样本无法撤回。双槽字节到PCM链路已由后述wav_audio_player连接，真实文件所有者见末节，HDMI仍待实现。

安全复用不能省略：确认读侧已停用并排空、文件层已实际取消/排空旧返回，再共同flush两侧FIFO/解析/事件，之后以新epoch启动。O_quiescent仅表示解码侧没有未入队终态或未接受的取消请求，不能据此单独flush；cancel请求接受也不等于文件I/O已经排空。epoch不得在旧事务仍能返回时复用。单槽回收协议见下节；双槽所有者见后述wav_audio_player，真实文件所有者见末节，共享端点仲裁仍待接入，禁止单侧清指针。

`tb_wav_track_source`准备两种时钟比（125→25及25→125 MHz）和4/16帧容量，各跑6种场景：长文件反压并混入旧标记字节/错误、满FIFO加一个待传样本时取消、匹配流错误、音频侧停钟时flush并排队头和终态后恢复、空data、头前签名失败。逐帧核对PCM24/声道/epoch，核对事件字段/顺序/唯一性与反压稳定、未接头前无PCM、错误后禁止读出、持续取消握手以及终态后不能直接重启。新增 `run_wav_track_source.do` 已加入统一入口，全部未执行；不验证物理CDC约束、文件层取消完成、有限epoch回绕安全、生产存储映射或真实TF读取/HDMI。

## 音轨槽安全回收协议

`audio_slot_recycle`按设计02的5.18节接线，每槽一份。decode侧回收请求触发持续abort与文件退休请求，audio侧通过同步stop请求所有者停用并排空。两侧完成确认和source.quiescent都到达才共同flush；随后等待source.start_ready、audio域复位释放和四相确认归零，再发done并开放新start。新事务必须同时满足controller.available和source.start_ready。上电显式全局reset会执行初始化flush，不发回收done；初始化也需要audio所有者确认idle。该控制器不自行关闭播放包络、不提供文件取消实现，也不判断epoch回绕。新增双槽链路在下一节实现读侧所有者。

`I_io_retired`只能来自实际旧事务排空，不能接cancel_ready；`I_audio_idle`只能来自停止消费及流水排空后的持久确认，不能简单接!enabled或release。停止期间所有者仍须处理待接收事件。对方停钟/卡住时会持续等待；不得以超时直接清FIFO。全局复位是独立强制丢弃入口，不替代正常回收。

`tb_audio_slot_recycle`用显式协议端点准备检查各方延迟、连续三轮回收、忙时禁止复用、文件确认未归零时阻塞、audio停钟前后握手、停钟期间共同flush与恢复、source复位未释放时等待、全局reset取消在途回收及初始化不发done。它是控制协议测试，未实例化source/playback或真实文件层，不证明端到端排空、物理CDC、相位或TD时序。独立脚本`run_audio_slot_recycle.do`已加入Media/All，尚未执行。

## WAV双槽到PCM集成

`wav_audio_player`接收两路带16-bit epoch的WAV字节，低位切片为A、高位为B；decode域start/recycle/cancel/retire与audio域play/fade/pause/event接口分开。每槽`wav_audio_slot`组合真实source、回收控制和一项事件弹性寄存器，头事件原子装载playback的total_frames，起点为0。外部事件反压时输出保持，槽flush明确取消旧事件。原始tick继续由samp_tick提供，寄存PCM/sample_valid供后续HDMI接入；当前仍未接真实HDMI。

playback现提供每槽stop/clear/idle：停止槽不再消费、guard淡出后再排空五个audio时钟才确认idle，暂停时停止槽仍获得tick完成包络。局部clear只清本槽元数据和guard。文件层retired仍需由外部真实I/O排空产生；不能把测试文件端点移入硬件替代它。错误自动使该槽停止，回收、下一文件和背景循环仍由调度方明确发命令。release为audio域单拍，不能直接送decode域recycle。

`tb_wav_audio_player`使用16帧FIFO、8帧预充、7采样淡化及125/25 MHz时钟，准备双WAV并行供数、提前play、事件反压、字节到消费帧身份、左右声道及索引、全幅稳态输出、valid四拍、双向切换、延迟取消接受及文件退休、旧epoch丢弃、槽重装、暂停中活动槽回收、另一槽隔离和EOF。文件端点只有在旧字节全部返回后才给retired；独立回收测试仍覆盖停钟。此测试未覆盖真实文件系统/HDMI/物理CDC，不替代mix/guard独立黄金算术测试。`run_wav_audio_player.do`已加入集中入口，尚未运行。


## 播放列表解析与字符串复制

`playlist_parser`已准备RTL和自检，尚未运行任何HDL工具。它接收文件大小、16-bit tag、32-bit介质generation及从偏移0开始的完整字节流；支持GLOBAL/ITEM、缺省继承、重复有效键、路径规范化、ASCII/双字节标题、CR/LF/CRLF、末行无换行、最多64个候选条目。具体接口及warning位见设计02 §5.5.1。

每次`item_valid`时，接收方先保存条目配置，再用`string_kind`（0=file、1=audio、2=title）与`string_address`逐字节同步读出路径/标题；地址在上升沿采样，该拍之后得到数据。全部复制到自己的暂存索引后，才握手`item_ready`。等待期间输入反压，字符串不被下一ITEM覆盖；不要把本组件的临时RAM地址作为永久路径引用。根相对输出均为绝对路径，相对路径加`/PLAY/`，规范化后总长不得超过64字节。

解析器不承担FAT32请求或读取退休。`abort/stream_error`可撤销未接收条目，但不能撤回此前已接收的候选；终态done保持到握手。只有真实文件读取已退休、解析done成功且介质generation仍有效，才能原子提交暂存索引。文件错误用stream_error通知，早last/缺last报读取错误；若源无返回也无错误，本组件不会凭空判断EOF，需上层超时处理。无有效条目时，后续indexer再决定目录回退；本组件不排序、不检查素材存在性，也不连接WAV/BMP或整机。

准备检查合法GLOBAL/ITEM、后续GLOBAL只影响后续项、全部转场/时长、重复与非法值回退、非法节/键/无file、路径64字节和穿越/非法字符、255/256字节行、ASCII/双字节标题截断、64/66项、元数据/字符串/终态反压、精确last、读错、取消、reset与重新启动。均未执行。

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playlist_parser.do'
```

独立日志`src/sim/build/playlist_parser/playlist_parser.log`，S_test_pass及退出码沿用现有约定。`run_media.ps1`现在四十六组，`run_p0.ps1 -Suite All`六十五组；不要同时运行共享用例work/transcript目录的批次。无需接板。

## 素材索引存储、排序与提交

`media_index_store`是独立host域存储块，现由builder和file_source接入parser及真实FAT32接口；本节单独自检仍使用手工候选。调用方先begin(tag,generation)，再依次提交条目元数据及拼接的file/audio/title字节帧；last仅标记合计最后字节。解析器的同步字符串读口需要调用方先读出再送入索引块，不能把两模块的ready/valid直接对接；先复制完当前候选后才允许parser释放其临时字符串。具体信号、范围、错误码见设计02 §5.5.2。

finish选择name/list/random，排序只交换槽引用，配置、音轨和标题仍跟随原项。name按规范化后的完整图片路径做ASCII不分大小写稳定排序；random允许指定seed，同输入同seed可复现，零seed等效1。排序完成后仍等待显式commit和source_retired，后者必须来自真实源事务排空。只有源解析/枚举成功且介质代次仍有效，调用方才应发commit；本模块不会从手工retired信号证明真实I/O完成。

读取方先acquire取得count/generation/revision，再按逻辑索引读元数据和一个字符串字节，请求/结果携带匹配的16-bit read_tag。结果valid保持到ready；读口通过同步RAM流水返回，不可假定请求同拍有数据。整份快照持续持有至release握手，已提交新索引时仍可读旧快照；下一次构建等旧bank释放。不要把槽号跨快照保存为永久文件身份。掉卡/代次变化会作废active及旧快照的新读请求，已发布结果保持，调用方仍需核对当前介质状态并主动释放快照。两个bank有效数据约21.77 KiB，实际映射、整体是否放得下及125 MHz时序都待TD。

手工记录自检准备覆盖输入序、稳定重名/大小写/前缀及64字节末尾比较、完整file/audio/title复制、64项逆序排序、第65项拒绝、8/64项随机排列的唯一性/完整性/身份及seed可复现；同时检查未退休不得提交、旧快照跨提交保留与bank阻塞、同拍acquire/commit及release/read优先级、字符串/结果/终态反压、非法元数据/帧/order、构建/排序/待提交取消、失效/代次变化、空索引及reset恢复。尚未执行，不证明FAT32连接、真正目录回退、素材有效性、实际BRAM推断、均匀随机性、性能或整机行为。

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_media_index_store.do'
```

日志`src/sim/build/media_index_store/media_index_store.log`，失败或未到S_test_pass返回1，完整自检返回0。新增用例已加入Media/All，暂不需要接板。

## 列表解析到索引构建

`playlist_index_builder`在host域实例化真实parser和store，已把临时字符串同步读取、单字节寄存、索引写入和parser条目释放接在一起。先start(file_size/tag/generation/seed)，再发送带同一tag/generation的完整文件字节流；匹配字节会受parser和复制过程反压，其他身份字节在当前事务期间接收丢弃。active、snapshot与带tag索引读口沿用store接口，可在构建新索引时继续持有旧索引。

源事务另以retire_valid/ready(tag,generation,error)通知真实排空，包括空文件、取消或尚未实际发起I/O的启动失败；错身份记录不能解除等待。成功退休须晚于所有文件字节交付，允许与最后字节同拍；若传输字节数不符则整个构建失败。外部文件所有者需要将实际read done、取消完成和旧返回排空合并成此记录，不能用cancel_ready或parser.done代替。只有收到匹配成功退休、parser成功且非零候选、排序完成和当前介质有效，才会自动commit。零项返回error5/fallback_required，不替换旧active；真正目录回退由下一层执行。

abort/stream_error/介质失效阻止提交并持续source_cancel至匹配源退休，旧字节继续接收丢弃，两个子模块也要消费终态后才对外done。source_cancel是同域电平，外部所有者负责真正cancel valid/ready协议及退休，不可把它直接当cancel_done。已提交成功的决定不因之后abort/错误重写；媒体失效仍使active作废，调用方需检查身份。已发布done保持直至握手，忙时不能启动下一命令。未收到源退休时会一直等待，没有以超时强行清FIFO的路径。

本节自检仅用文件字节和退休端点激励，目录模式显式关闭；脚本另加载目录source依赖。准备覆盖字符串及元数据对应、GLOBAL继承与告警、name/list/random与seed可复现、64项与最大长度、旧快照并发读取/提交/bank反压、错身份字节和退休、延迟/错误/提前退休、末字节与退休同拍、零项回退、early/missing last、复制/输入/排序/等待退休期取消和错误、短暂掉卡及新generation、启动即失败、提交后错误、终态/索引读反压和reset恢复。全部尚未执行；不证明真实FAT32排空、素材存在性、目录回退、BRAM映射、125 MHz或完整播放器。

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playlist_index_builder.do'
```

单项日志`src/sim/build/playlist_index_builder/playlist_index_builder.log`。Media入口六十六组、All八十五组；仍不需要接板，不要同时运行共享work/transcript的批次。

## FAT32列表文件所有者与真实core集成

`playlist_file_source`在125 MHz host域取得显式空闲槽租约后，打开固定`/PLAY/PLAYLIST.TXT`，消费open结果，启动外部builder，再以完整16位tag作read epoch从偏移0读取全部文件。没有新增索引RAM或第二个文件系统。接口见设计02 §5.5.4；它是文件I/O所有者，尚非完整media_indexer或整机顶层。

`I_lease_grant`只能由确认槽已关闭、旧请求及取消均退休的调度方提供，禁止直接常接1占用在播槽；测试中授予租约是明确夹具条件。共享返回按context分流，其他槽的ready为0，本槽旧身份接收丢弃。成功open即承担关闭义务；builder未启动时取消也须关闭。开始过builder时，即使未接受read，关闭后也恰好发送一条retire。实际cancel握手后，必须消费匹配file.done和cancel_done；未握手cancel可在done已消费后撤回。不要把source.done当成builder提交成功，上层须分别消费两者结果。

连接同一个core的open/path/read/cancel/close端口，端口后缀对应，例如`source.O_fs_read_valid → core.I_read_valid`、`core.O_byte_generation → source.I_fs_byte_generation`。builder的start/byte/retire连接source对应build端点；builder.source_cancel/tag/generation回接source.build_cancel，source.build_stream_error接builder.stream_error。两者共用media_valid/generation和全局reset，外部abort同时给两者。完整命名接线可参照`tb_playlist_file_fat32.v`，其中SD扇区端点和测试租约不能复制进硬件作为实现。

| 用例 | 已准备的自检范围 | 边界 |
|---|---|---|
| playlist_file_source | 真实source/parser/store；租约等待、三个context、锁存载荷、固定路径、open/byte/done/cancel_done错身份与跨槽隔离、反压、空/缺失列表、启动前及读前取消、延迟取消确认、done与cancel同拍/未握手cancel撤回、末字节与done同拍、offset/count/EOF错误、原始I/O诊断、短暂失效、退休记录及终态保持、全局reset恢复 | FAT32是协议激励端点，不证明目录/簇链或真实排空 |
| playlist_file_fat32 | 真实fat32_core及其mount/path/file_reader/arbiter/sector_port与source/parser/store；700字节列表跨非连续簇、逐字节读取快照路径/元数据、缺文件、零长文件、取消、底层读错、在途物理请求时掉卡及延迟取消确认、显式重新挂载与新代次重建 | 仅SD host扇区端点是夹具；未加载sd_storage/SPI/CDC、真实卡或HDMI，不证明性能/物理时序 |

以上均未编译或执行。先运行P0与Storage基础组，再运行Media；也可在仓库根目录用`& ./src/sim/run_p0.ps1 -Suite All`串行收集79组结果。只跑本块时：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playlist_file_source.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playlist_file_fat32.do'
```

两项日志分别在`src/sim/build/playlist_file_source/playlist_file_source.log`和`src/sim/build/playlist_file_fat32/playlist_file_fat32.log`，PASS标志与退出码0/1沿用现有约定。当前不需接板，用户可保留到后续集中验证；所有P0—P7验收保持未勾选。目录内部回退及列表转目录的扫描所有者见后两节；素材存在性检查及完整安全播放调度仍待实现，资源超预算问题也没有因此解决。


## 目录候选索引与根目录回退

`directory_index_source`及builder目录模式的RTL、两份自检和脚本已准备，均未编译、仿真、综合或板测。先扫描`/PLAY/IMG`，仅在该目录缺失/非目录（14/15）或成功零候选时尝试根目录，两次共用总扇区预算。读取错误、预算失败、取消或失效不回退、不提交部分索引。达到64项时请求正常stop，告警表示可能截断，不表示已经发现第65项。

候选须为普通文件，具有大小写不敏感`.bmp`后缀、非空主体、合法ASCII单分量、size≥54及first_cluster≥2；拼接路径最多64 B。title取文件名主体前40 B，audio为空。只检查目录元数据，没有读取BMP头或像素，不能据此判定图片有效。duration/transition/transition_ms/order/seed由调用方提供并在start锁存。

硬件接线使用同一个`playlist_index_builder`：列表模式显式置`I_directory_mode=0`；目录模式置1，提供默认配置、总预算及独占namespace/store的`I_directory_lease_grant`。租约请求先于授权，不可把grant无条件接1。builder的完整enum命令/path/entry/name/done及stop/cancel端点逐项连接同一`fat32_core`对应接口，媒体有效性/代次和reset共用host域信号。两个生产者串行使用唯一双bank store及原快照读口，目录source只新增64 B同步名称缓冲。参考接线见`tb_directory_index_fat32.v`；测试的租约与SD端点不能作为硬件实现。

成功enum_done在最后候选复制时到达，会等复制完才消费；错误done或取消可撤销未完成候选。所有枚举真实退休、非零候选排序完成且介质代次有效后才commit。取消持续请求enum_cancel，等待匹配enum_done及store终态。旧快照跨提交的规则不变。目录结果通过builder.done返回；详细error/warning及原始诊断见设计02 §5.5.5。

| 用例 | 已准备的范围 | 限制 |
|---|---|---|
| directory_index_source | 真实source/store；租约、路径与配置快照、候选筛选、64 B路径/40 B标题、同步复制反压、最后候选/done并发、提前EOF、复制中读错、14/15/空目录回退、累计预算、tag回绕/旧身份、快照/bank阻塞、64项stop、取消/失效/非法配置/reset | enum为协议激励端点，不证明真实FAT32或图片内容 |
| directory_index_fat32 | 真实core/file_source/parser/目录source及同一store；先构建碎片列表，再切目录替换索引、缺/空IMG到根、根空保留旧active、排序/配置、IMG扇区错误、延迟物理取消确认、掉卡/显式重挂载、忙时mode隔离 | SD host扇区端点为夹具，不含真实SPI/CDC、BMP字节或整机 |

建议先运行原P0、Storage及列表测试，再运行这两项；`-Suite All`串行收集全部79组（每组独立加载所需RTL），也可在仓库根目录单独运行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_directory_index_source.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_directory_index_fat32.do'
```

独立日志分别在`src/sim/build/directory_index_source/directory_index_source.log`及`src/sim/build/directory_index_fat32/directory_index_fat32.log`，保持S_test_pass与退出码0/1约定。Media现48组、Storage13组、All65组、默认P0六组，均待实际执行；不要同时启动共享用例目录的批次。

本节测试显式切换模式，下一节media_index_scan已封装列表source.done与builder.done的协调及缺失/零项自动启动目录模式。后续还需BMP内容验证、真实文件装载及完整播放链。新增64 B缓冲未解决既有约113 KiB超100 KiB规划目标的问题，没有BRAM映射、吞吐、时序或板测结论。所有P0—P7验收保持未勾选。


## 列表到目录的自动扫描所有者

`media_scan_ctrl`及`media_index_scan`的RTL、控制协议自检和真实core集成自检已准备，均未编译、仿真、综合或板测。包装内部只含一个列表file_source与一个共享builder，builder继续持有唯一双bank索引；没有新增文件系统、索引副本或RAM数组。接口见设计02 §5.5.6。

对外一次start锁存context/tag/generation/seed、列表路径预算、目录总预算和目录默认配置。context须0..2、两个预算非零，duration/transition_ms/order须满足store范围；非法配置返回4且不启动子模块。列表定位预算与目录总预算独立，目录内部主路径和根回退共用后者，并非全扫描总I/O限制。列表用原tag，目录用tag+1，目录内部根回退再加1，均按16位回绕，generation不变。

先消费列表source.done；若实际启动过builder，还必须分别消费builder.done，允许两者任意先后或同拍到达。仅缺列表（source=5且未启动builder）或成功零项（source=0、builder=5/count=0/未提交）自动发一次目录命令；其他打开/读取/解析错误、协议错误、取消或失效不回退。成功必须有非零候选及实际commit。用户取消与短暂失效锁存并等待真实退休，未启动的后续阶段撤销；已经实际commit的成功决定保持。不能用builder上次遗留的committed、source.done或取消接受代替本次提交/退休。

推荐硬件连接`media_index_scan`到同一`fat32_core`：所有fs open/path/read/byte/done/cancel/cancel_done/close端口逐项连接，enum命令及路径/条目/名称/终态/stop/cancel逐项对应，media_valid/generation接core.mounted/generation，共用host域时钟与全局reset。原active、snapshot acquire/release和带tag同步读口直接保留。源返回必须按context路由，其他在播槽仍由外部所有者服务，不将多个消费者的ready无条件或合并。完整接线见`tb_media_index_scan_fat32.v`。

外部先确认所选context已关闭、旧读及取消已退休，namespace及builder无其他所有者，再授予`I_lease_grant`；lease_request先于grant。包装从接受start到scan.done握手持有租约，不提前交给下一扫描。内部子模块的授权来自这份已取得租约，不表示硬件可以把外部grant常接1。旧快照可继续读取，并可能阻止下一次构建；扫描器不会强行释放它。core仍需上层显式挂载，卡重新ready不等于旧mounted恢复。

done返回error/count/committed/used_directory/list_missing和独立list_warning/directory_warning、各阶段错误、原始文件/目录诊断。`used_directory`表示已选择目录路径，`directory_started`表示目录start真实握手；`list_started`表示file_source启动。未启动阶段的原始诊断可能仍保留上次载荷，只在对应started为1时使用。扫描成功仍只是候选索引就绪，不证明BMP/WAV存在且可解码；媒体失效会独立撤销active，读取方继续核对代次。

| 用例 | 已准备的范围 | 限制 |
|---|---|---|
| media_scan_ctrl | 租约、载荷快照、两份终态任意先后/同拍、无builder时不等待、错身份排空、缺/零列表自动目录、tag回绕、错误不回退、用户取消与短暂失效、提交后取消保持、旧committed隔离、非法配置/不一致终态/reset | 子模块命令/终态是协议激励，不证明真实I/O |
| media_index_scan_fat32 | 真实scan/source/builder/parser/store及core；碎片列表、缺/空/非空零项列表自动目录、IMG到根及tag回绕、旧快照跨目录提交、bank阻塞时取消且未启动builder、根空保留旧active、原始错误、列表/目录物理请求取消、延迟ack、掉卡及显式重挂载、快照路径/标题/配置逐字节检查 | 只有SD host扇区端点为夹具，不含真实SPI/CDC、BMP内容、SDRAM或整机 |

先验证已有P0/Storage和列表/目录基础用例，再看这两组；也可用All一次收集全部79组，每组独立加载依赖。单独运行（仓库根目录）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_media_scan_ctrl.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_media_index_scan_fat32.do'
```

日志在`src/sim/build/media_scan_ctrl/media_scan_ctrl.log`和`src/sim/build/media_index_scan_fat32/media_index_scan_fat32.log`，仍使用S_test_pass及退出码0/1。Media46组、Storage13组、All65组、默认P0六组，均未实际执行；不要同时运行共享用例目录的批次。用户可保留到后续集中验证，本轮无须接板。

BMP真实文件供数及WAV文件所有者见后两节，图像写入、共享文件仲裁与播放调度仍待实现。SDRAM真实IP响应契约、UI/OSD/UART/Flash、HDMI音频及完整top仍待接入。现有约113 KiB规划超100 KiB目标，新增控制寄存器未解决资源问题；没有BRAM映射、吞吐或时序结论，不勾选任何阶段验收。

## BMP文件供数与真实解析

`bmp_file_source`及两组自检脚本已准备，均未编译、仿真、综合或板测。接口先在设计02 §5.7.1细化；source内部仅实例化一个真实`bmp_parser`，没有新增路径或帧RAM，按完整文件长度从offset0读取，输出候选header与RGBA/x/y/pixel_last。

连接同一host域的`fat32_core`：media_valid/generation接core.mounted/generation，fs open/path/read/byte/done/cancel/cancel_done/close逐项对应，共用全局reset；完整例子见`tb_bmp_file_fat32.v`。路径由调用方在start后按ready逐字节提供，必须以`/`开头，长度1..64 B，last与长度相符；sector_budget只限制路径定位，整个文件read仍按reader自身大小/簇链预算处理。start锁存context/tag/generation/path_length/budget，不能在忙时换路径快照；不用8位parser tag替代16位文件epoch。

外部须先确认所选context已关闭、旧read和cancel已退休并取得open/path namespace独占权，再按lease_request授予grant；租约持续至source.done握手。硬件仍需真实仲裁，不能把测试中单所有者fixture的常量grant移植到top，也不能与media_index_scan直接并接namespace或将多个消费者ready无条件合并。其他context可继续读。core显式挂载，卡恢复ready不会自动重挂载。

输出header与pixel分别支持ready反压，`O_tag/O_generation`在整个租约内标识所属命令。首像素可能在完整文件读完前到达，下游只写LOADING目标；BMP正高归一坐标后仍按底行先到达，32bit的输入alpha统一改成255。source只有在文件done、已接受取消的cancel_done、close及实际parser.done都完成后才发终态。成功source.done仍需下游等待真实存储写响应、完整性检查和帧边界，才能提交READY，不能把它当作SDRAM完成。未启动parser时header元数据可能是旧载荷，只以本次header握手为准。

终态error=0成功、1文件/存储错、2取消、3失效、4配置/协议错、5BMP解析拒绝，优先级3>2>1>4>5；另保留原始file/storage/path_warning/parser诊断。短暂掉卡和取消锁存；已发布done保持结果，但消费方继续核对当前代次。自己取消open/read后的正常error8保留根因，不误报成新I/O错误。没有超时强行回收或自动帧提交。

| 用例 | 已准备的范围 | 限制 |
|---|---|---|
| bmp_file_source | 真实source/parser；租约及命令快照、context与身份隔离、24/32bit正负高、行padding/头后间隙/尾字节、header与pixel反压、末字节/done同拍、parser先成功而file.done迟到、短文件/坏签名、offset/last/count/EOF错误、原始I/O诊断、取消与延迟ack、done/cancel同拍及未接受cancel撤回、close反压、读前/开路径中取消、64 B路径边界、非法配置/路径last、短暂失效、终态保持、全局reset | 文件端点为协议激励；不证明FAT32几何或真实SD卡 |
| bmp_file_fat32 | 真实source/parser/core及全部FAT32依赖；700 B BMP的cluster4→6碎片链，pixel_offset=510使首像素横跨簇边界，逐像素核对24bit底行先/32bit顶行先、元数据与反压、坏BMP/缺文件/长度不符、数据扇区错误、在途物理取消及延迟ack、掉卡/显式重挂载及代次、真实context关闭后才done | 只有SD host扇区返回是夹具，无SD SPI/CDC、存储写入、缩放、HDMI或整机 |

建议先运行P0、Storage与已有bmp_parser，再运行本块；后续集中验证也可直接用`& ./src/sim/run_p0.ps1 -Suite All`串行收集79组。单独运行时在仓库根目录执行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_bmp_file_source.do'
$LASTEXITCODE
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_bmp_file_fat32.do'
$LASTEXITCODE
```

日志为`src/sim/build/bmp_file_source/bmp_file_source.log`及`src/sim/build/bmp_file_fat32/bmp_file_fat32.log`，沿用S_test_pass与退出码0/1。Media46组、Storage13组、All65组、默认P0六组，均待运行；不要同时启动共享用例目录的批次。本轮无须接板，保留全部P0—P7验收未勾选。

WAV真实文件所有者见下一节；缩放实现准备见末节，SDRAM writer/reader最终仍依赖真实IP响应契约，不能伪造固定延迟。现有约113 KiB资源规划超100 KiB目标尚未解决，没有放得下、吞吐或时序结论；BMP这块完成的是文件到像素候选的桥接。

## WAV真实文件所有者与音轨槽退休

`wav_file_source`及两组自检和脚本已准备，均未编译、仿真、综合或板测。先在设计02 §5.13.1明确文件结果、解码事件及槽回收的边界，再实现RTL。文件桥只在decode/host域管理open/path/read/byte/done/cancel/cancel_done/close，不包含第二份parser、FIFO或PCM RAM；既有音频模块接口保持原样。

start锁存context/tag/generation/path_length/sector_budget/read_priority。路径为1..64 B绝对ASCII路径，由调用方保留快照并在open接受后按ready逐字节供给；last必须与长度相符。定位预算非零，不表示整个WAV的总读预算。context须0..2且已关闭、旧读与取消已退休；外部取得namespace/context独占租约后给grant，持有至文件done握手。lease_request先于grant，不能常量授权实际硬件或与扫描/BMP源直接并接共享端点。

文件接口逐项连接同一`fat32_core`，media_valid/generation接core.mounted/generation，共用全局reset。桥的`I_clk`必须与对应槽decode时钟及文件host时钟相同。track端口按下表接单个`wav_audio_slot`；接`wav_audio_player`时使用对应槽的打包切片，低位A、高位B，不跨域直连audio控制。

| 文件桥端口 | 对应槽端口 |
|---|---|
| O_track_start_valid / I_track_start_ready | I_start_valid / O_start_ready |
| O_track_file_size / O_track_epoch | I_file_size / I_epoch |
| O_track_byte_valid / I_track_byte_ready / data / last / epoch | I_byte_valid / O_byte_ready / I_byte_data / I_byte_last / I_byte_epoch |
| O_track_stream_error / O_track_stream_error_epoch | I_stream_error_valid / I_stream_error_epoch |
| I_track_cancel_valid / O_track_cancel_ready / I_track_cancel_epoch | O_cancel_valid / I_cancel_ready / O_cancel_epoch |
| I_io_retire_request / O_io_retired | O_io_retire_request / I_io_retired |

已发read需真实done，已接受cancel还需真实cancel_done，随后完成close；桥才发布文件终态。槽的retire_request触发停止新文件请求和必要取消，确认只依据真实文件退休，不能先等PCM清空或audio idle。关闭后保持retired至request撤销，归零后才允许下一命令；空闲桥同样响应这次四相握手。slot自己继续等待decode.quiescent和真实audio idle，再共同flush。文件关闭后或done已经被消费时，桥仍接收本槽同epoch的迟到decoder cancel，防止取消未接受导致quiescent永远不成立。

`source.done`只报告文件：error0完整读取并关闭、1文件/存储错、2取消/槽退休、3介质失效、4配置/流协议错、5活动期decoder请求取消，优先级3>2>1>4>5；保留原始文件、存储与路径warning。decoder错误详情以音频域terminal event为准；迟到解码错误不改写已发布文件结果。读取成功既不证明WAV合法，也不表示PCM播完；已缓存音频不得仅因file.done提前flush。文件已关闭后掉卡，上层仍须按generation显式回收在播槽。

`read_priority`在decode域锁存；audio域need_fill不能直接驱动core.urgent，水位到host域的CDC、双轨共享仲裁和完整调度尚未实现。调用方仍显式发recycle，不能把audio域单拍release直接送decode域。局部/媒体reset不得强行清掉在途文件事务，只可按回收协议处理；全局reset须与core及槽共同使用。

| 用例 | 已准备的范围 | 限制 |
|---|---|---|
| wav_file_source | 真实桥，文件/解码控制协议端点；租约与快照/priority、slot未ready时禁新start、路径和身份隔离、字节/track start反压、末字节done同拍、读取后等待终态、decoder取消/迟到cancel、空闲及活动退休四相握手、取消延迟ack/同拍done/未接受撤回、close反压、offset/last/count/EOF、原始I/O诊断、读前与开路径中取消、短暂失效/代次变化、64 B路径、非法配置、终态保持/reset | 不含真实parser或FAT32；文件成功不证明解码或音频消费 |
| wav_file_fat32 | 真实桥/core/单个wav_audio_slot，包含source/parser/PCM与事件FIFO/recycle；700 B WAV通过cluster4→6碎片链，data_offset510使首帧左右声道跨簇；奇数JUNK及padding、RIFF后尾字节，逐帧PCM24符号/声道/顺序/事件epoch核对、FIFO满反压、4帧短音轨/零data、新epoch重装、坏WAV/缺文件、SD错误/物理取消延迟ack、掉卡与显式重挂载、音频停钟期间文件独立退休而槽继续等待 | SD host扇区与无流水PCM接收方是测试端点，没有真实播放owner、双轨共享仲裁、SPI/CDC、混音或HDMI |

集成测试的PCM接收方在stop后不再握手且无未排空流水，因此用可见stop确认idle；真实播放器必须继续使用实际消费/淡出和流水排空后的idle，不能照搬这个测试端点替代播放所有者。

先运行P0、Storage及已有wav_parser/wav_track_source/audio_slot_recycle/wav_audio_player基础组，再运行本块；也可后续一次执行All收集79组。仓库根目录单独执行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_wav_file_source.do'
$LASTEXITCODE
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_wav_file_fat32.do'
$LASTEXITCODE
```

日志分别为`src/sim/build/wav_file_source/wav_file_source.log`及`src/sim/build/wav_file_fat32/wav_file_fat32.log`，沿用S_test_pass和退出码0/1。Media46组、Storage13组、All65组、P0六组，均未运行；集中命令`& ./src/sim/run_p0.ps1 -Suite All`，不要同时启动共享用例目录的批次。本轮无需接板，用户可保留到后续集中验证。

文件到像素候选、文件到单轨PCM的连接现已有代码准备；SDRAM写入、共享文件所有者仲裁、完整播放调度、安全页、UI/OSD/UART/Flash、HDMI音频及top仍未完成。SDRAM真实响应契约和约113 KiB超100 KiB资源规划问题仍待处理，没有放得下、吞吐或时序结论；所有P0—P7验收保持未勾选。

## 最近邻/双线性缩放与BMP像素集成

新增`src/rtl/media/image_scaler.v`，接口详见设计02 §5.8.1。两条1920×32源行缓存共15 KiB，支持1..1920×1..1080源图和宽高各1..640的预旋转目标；最近邻/双线性由命令显式选择，不会自行降级。源按每行x递增、y递增或递减输入，输出保留相同行序和归一化坐标。模块不做等比尺寸计算、四方向旋转、版式、SDRAM写入或帧提交。

接线在同一个decode/host域完成：

- `bmp_file_source`的header握手用于启动scaler；外层先保存目标尺寸、算法、完整tag/generation，取得scaler的start_ready后才接受header。源width/height/bottom_up接scaler对应输入，目标宽高是旋转前尺寸。
- 源RGBA/x/y/pixel_last和valid接scaler输入，scaler.O_pixel_ready返回源pixel_ready。scaler输出连接未来writer的候选像素口，writer反压返回I_pixel_ready。BMP源A固定255，本模块对RGBA四通道同样插值。
- 源失败需锁存并通知scaler.I_stream_error；scaler失败需锁存并取消源，等待真实文件退休。scaler.done_valid是保持型结果，bmp_parser.done是脉冲、bmp_file_source.done_valid是文件与parser联合退休，不能混接。最终owner须分别保存并汇总所有结果，不能只看最后一个模块或最后像素。
- scaler成功要求全部源像素及全部目标像素握手；下采样未使用的尾行仍需消费检查。BMP尾字节或文件done可晚于缩放成功，上层仍须检查源终态、generation及真实writer写响应，再决定READY。scaler错误不代表文件取消完成，不能直接释放租约或复用context。

Q16计算固定为`step=floor((src<<16)/dst)`、`origin=(step>>1)−32768`、`s=origin+d*step`。底行先从最后一个目的y开始减step，仍使用同一坐标定义。最近邻就近取整后钳边，双线性用16位小数、水平不提前舍入，最终加`2^31`再右移32。启动共用32步恢复除法器，四拍同步读邻点加一拍归集、四拍逐通道插值，另有控制与握手开销；资源映射及吞吐须后续测量。

| 用例 | 已准备覆盖（未运行） | 边界 |
|---|---|---|
| image_scaler | 直接目的坐标与64位四项加权黄金比较；两种算法/行序，RGBA/x/y/last，非整比、放大/缩小/等尺寸、1×1、300×200、640×480、完整1920×1080到640×360与1×1、1920宽/1080高窄长图；启动快照、输入空拍/输出反压、跳行/尾行消费、配置/坐标/last错误、流错、取消优先、保持终态、reset及不清RAM后重装 | 源为程序化像素；不验证BMP、文件、旋转或硬件RAM |
| bmp_image_scaler | 真实bmp_parser→image_scaler；24/32bit、顶/底行、两种算法、奇数宽padding、头后间隙、非零尾字节、header与输出反压、alpha归一；刻意让scaler先成功，随后BMP尾部流错仍判整体失败；正常重装 | 字节端点与像素接收端为夹具；没有文件core、SDRAM、完整图像owner或帧提交 |

先运行P0、Storage及原bmp_parser/bmp_file_source/bmp_file_fat32，再看新增两组。可保留至后续集中执行，在仓库根目录运行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只运行本块：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_scaler.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_bmp_image_scaler.do'
```

日志位于`src/sim/build/image_scaler/image_scaler.log`及`src/sim/build/bmp_image_scaler/bmp_image_scaler.log`，沿用S_test_pass和退出码0/1。最大源图完整像素激励比原小图更耗仿真时间，请等到PASS或明确失败；不要并行运行共享目录的批次。当前Media46组、Storage13组、All65组、P0六组，全部未经编译/执行，本轮无须接板。

等比适配与四方向映射的实现准备见下一节，随后仍需接真实writer/reader。SDRAM响应契约仍需真实IP证据；两行RAM属于既有规划，不解决约113 KiB超100 KiB的资源问题。没有硬件放得下、125 MHz时序或P2验收结论。

## 等比适配、四方向坐标与组合像素管线

新增`image_geometry.v`、`image_rotate.v`、`image_transform.v`，接口见设计02 §5.8.2。它们分别计算旋转后的等比适配、将缩放结果映射到画布坐标、组合唯一geometry/scaler/rotate；没有新增行RAM或整帧RAM。rotation=0/1/2/3为顺时针0/90/180/270度，与BMP的bottom_up行序独立。

geometry先比较旋转后源宽高的交叉积，受限轴取矩形尺寸，另一轴floor且至少1像素；居中取floor，奇数余量留右/下。640×480原图适配全屏并转90度时，pre=480×360、image=360×480、偏移(140,0)。目标矩形必须在640×480画布内，17位加法拒绝起点+尺寸溢出。算法选择仍明确保留nearest/bilinear。

`image_transform`的接线为：

- `bmp_file_source`输出header时，由外层确认已持有LOADING目标并用transform.start握手接受源width/height/bottom_up，同时送目标矩形、rotation、bilinear、完整tag/generation快照。外层须让源header握手与transform.start接受保持一致，不能只接valid而遗漏ready。
- transform先发布geometry_valid及pre/image六个几何字段；外层保存它们并让未来writer准备接收，再给geometry_ready。此握手之前不接收源像素，不要求使用方预先知道计算时长。错误/取消无需geometry_ready就能退休。
- 源pixel valid/RGBA/x/y/last接transform输入，pixel_ready返回源；transform输出同组字段接writer，writer.ready返回。旋转后输出保留输入到达顺序，90/270会按列到达；last为任务结束，不是每行末或屏幕(639,479)。writer必须按明确x/y写入，黑边由其独立清屏保证。
- transform等实际启动过的scaler和rotate都完成，才保持done_valid/error/tag/generation。若rotate先送完目标，scaler仍可能在消费下采样不用的源尾行；此时不能复用任务。发生内部协议错误时先保留根因，再取消同伴，内部abort不会把协议error2改成用户取消error4。
- 文件错误/掉卡/代次变化由外层锁存、通知transform流错或取消，并退休真实source；反向transform失败也须取消并等待文件关闭。transform未实例化文件core、source或writer，成功不保证BMP尾部、真实写响应或READY提交。统一reset撤销像素管线，不能局部reset后继续接收旧文件流。

| 用例 | 已准备覆盖（未运行） | 边界 |
|---|---|---|
| image_geometry | 实际geometry的直接整数参考、四方向宽高交换、256组矩形、居中floor/极窄最少1像素、640×480转90、17位边界拒绝、命令快照、取消/结果冻结/reset；同一用例还运行真实rotate，检查四方向×双行序、非对称RGBA与坐标、全640×480、480×360转90/270、连续像素/反压、非法配置/坐标/last、流错、最后待传像素取消/reset | 无scaler、文件或SDRAM；旋转只做坐标，不验证转置写性能 |
| image_transform | 真实geometry/scaler/rotate及包装；直接Q16/64位四项黄金RGBA与旋转坐标，四方向×两算法×两行序、640×480转90、300×200放大、完整1920×1080到画中画区域及窄长图；几何授权延迟/快照、配置/源协议错误、源尾行出错而rotate已完成、末像素反压时取消、外部流错/取消优先、等待两真实终态、结果冻结/reset和重用 | 像素两端为夹具，无BMP/文件owner、SDRAM、版式重绘或帧提交 |

可留到后续集中执行。先看P0/Storage、原BMP及缩放基础组，再看新增两组；仓库根目录可一次串行收集当前全部79组：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独运行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_geometry.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_transform.do'
```

日志为`src/sim/build/image_geometry/image_geometry.log`及`src/sim/build/image_transform/image_transform.log`，沿用S_test_pass和退出码0/1；不要并行运行共享用例目录的批次。当前Media46组、Storage13组、All65组、P0六组，均未编译或执行，本轮无需接板。

图像链已准备到适配、缩放、旋转后的候选坐标；帧槽管理实现见下一节。真实writer/reader、完整帧提交、版式/转场、共享文件所有者仲裁、完整调度、安全页、UI/OSD/UART/Flash、HDMI音频及top仍待实现。SDRAM真实响应契约及约113 KiB超100 KiB资源规划仍待解决，不能声称项目代码已全部完成或P2通过。

## 帧槽装载租约与读锁

新增`src/rtl/display/fb_slot_manager.v`，同125 MHz管理域，接口见设计02 §3.1.1。六槽字地址固定、状态低切片属于slot0；记录素材、版式、方向、generation、单调装载token及A/B/合成三个读引用。这里只管理元数据，不分配像素RAM、不连接SDRAM、不代替真实writer/reader或完整显示提交控制器。

连接顺序为：

1. 装载owner用ALLOC请求明确槽号（FREE/ERROR），保存返回token/base/generation；像素任务在该LOADING租约内完成清屏及所有区域写入。slot4用于缩略图、slot5用于常驻页的用途由上层安排，不自动抢占。
2. producer实际结束（含文件关闭、解析/缩放终态）且所有已提交memory事务真实结束后，才同时确认两个retired并发送FINISH；success必须汇总像素覆盖/源与写入状态。最后像素、写命令接受或cancel_ready都不足以表示退休。成功READY，失败ERROR，已失效任务真实退休后FREE。
3. A/B所有者READ_ACQUIRE在可靠跨域提交协议确定的同域帧界接受，合成owner可独立加读锁。各owner最多持一个槽，同槽可共享三个引用。此接口不原子替换整组A/B配置；首行准备、转场/音频及完整提交CDC仍由后续控制器负责。
4. reader停止发请求并排空全部行读取与流水引用后，才置reader_retired发送READ_RELEASE。引用未清不能写入或EVICT；最后引用释放后有效槽READY、失效槽FREE。旧介质代次也必须允许用旧租约释放。

掉卡/代次变化立即禁止给旧素材新增读引用，未读READY自动FREE；已显示READ_LOCK维持完整旧帧，LOADING仍占用并持续cancel_loading直到真实FINISH。短暂失效恢复不恢复该任务的有效性。resident只允许slot5，可保存安全页且不受TF失效影响，仍须真实装载与读写互斥。默认32位token分配到最大后停止新ALLOC，禁止回绕污染；缩短位宽仅用于测试，全局reset才重建租约空间，不提供媒体局部reset。

`tb_fb_slot_manager`准备六槽地址/元数据、三owner引用、分别延迟producer/memory/reader退休、帧界门控、覆盖拒绝、旧身份/非法命令、失败重装/驱逐、瞬时失效/代次替换/FINISH同拍失效、结果冻结、resident及小token空间耗尽/reset等协议自检。所有退休与frame_boundary均为显式测试输入；没有伪造SDRAM固定延迟，没有证明真实写完成、像素覆盖、提交CDC、资源或时序。

用户可保留到后续集中运行，本轮不需接板。在仓库根目录：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只跑本块：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_fb_slot_manager.do'
```

日志为`src/sim/build/fb_slot_manager/fb_slot_manager.log`，沿用S_test_pass与退出码0/1。当前Media46组、Storage13组、All65组、P0六组，全部未编译或执行；不要同时运行共用目录的批次，所有P0—P7验收继续未勾选。

逻辑writer的完整写事务与生产终态汇总见下一节；SDRAM适配层仍依赖IP接收/返回/刷新契约。帧槽代码不解决约113 KiB超100 KiB规划问题，完整帧提交、reader、版式/转场及最终top仍有工作。

## 逻辑framebuffer写入与像素链集成

新增`src/rtl/display/fb_writer.v`，接口见设计02 §5.9.1、写退休端点见§3.3。支持整槽CLEAR、旋转坐标REGION、先完整清屏再覆盖区域CLEAR_REGION；最多8笔包含暂存命令的在途信用，可参数化。writer只存待退休tag，不增加像素RAM或覆盖位图。

接线与退休关系：

- 先从slot_manager取得LOADING槽的token/base/generation，外层确认独占租约后给writer.lease_grant。writer的start快照slot/token/generation/tag、操作、背景、pre宽高、image偏移、rotation、bottom_up及source_expected；来自transform几何时，应让writer.start和transform.geometry握手一致。
- writer输入为transform旋转后的RGBA/x/y/last。它从预旋转宽高、方向和行序独立产生期望坐标，逐点核对后写`base+y*640+x`；90/270按列写入合法，last是任务最后像素。每个REGION覆盖自己的有效矩形，但并不代表整个槽已清屏/所有版式区域齐全。
- 每个mem_valid/ready接受的写都有唯一tag32及槽lease_token32/generation32，必须返回同身份write_done。默认按序退休，允许同拍接受/返回；原始存储error另存。错租约/代次响应丢弃，同租约错tag报告协议错并继续等待真实队首；不能把错误tag当成排空证据。已呈现但被反压的命令取消后仍保持到接受，再等真实完成。
- `source_expected=1`声明start前已经启动的真实源义务。source终态必须匹配完整tag/token/generation，即使writer配置错、取消或失效也要等此终态；cancel_source通知外层结束真实文件/像素管线。IDLE的source_ready为0，避免未接受start便吞掉终态。成功源结果不能早于全部像素接受，可与最后像素同拍。已有内部根因时，同伴取消产生的源错误保留诊断而不覆盖根因。
- writer.done等已呈现/接受写请求全部真实退休及所声明源终态，再保持error、原始source/memory诊断、接受/退休/像素计数。外层仅在当前done且全部源与区域汇总后向slot_manager FINISH，不能在处理过程中用暂时memory_retired=1提前提交。

真实文件装载时，source终态必须汇总文件关闭/解析和transform，不能只接transform.done：BMP尾部/文件终态可能更晚失败。集成用例没有真实文件，因此以transform终态作为该测试像素源的结束；这种简化不能照搬成生产文件owner。

后端逻辑write_done端点目前未连接EG_PHY_SDRAM物理适配。真实适配必须依据IP实际接收/完成/刷新行为产生确认；不能由ready、固定十拍或读rvalid伪造。逻辑8笔在途不证明硬件IP能多笔接收，不代表显示带宽/125 MHz时序已达到。该writer不读源槽，不能单独完成完整COMPOSE或存储内旋转。

| 用例 | 已准备覆盖（未运行） | 边界 |
|---|---|---|
| fb_writer | 整307200字CLEAR、CLEAR_REGION清屏响应屏障、区域四方向/两行序、命令快照/租约、精确地址/RGBA/mask/last、8笔信用饱和、排队及零延迟完成、源/写退休任意先后、反压时取消仍保持命令、错源/返回身份、错tag不能排空、坐标/last/提前源成功、源/存储诊断、失效/非法配置/resident/reset；小tag空间耗尽不回绕及最后合法tag精确成功 | source与write_done为协议激励，无物理SDRAM、文件或生产owner |
| image_transform_writer | 真实geometry/scaler/rotate/transform/writer/slot_manager；四旋转配两算法与双行序、四次完整黑底清屏、最终全帧黑边及独立Q16黄金RGBA；基于真实LOADING状态授租，FINISH提前保持但等writer真实done，分别延迟transform源终态或最后写响应都不提前READY，逐区域结束后EVICT复用 | 程序化像素、逻辑写完成与测试帧数组为端点；无BMP/FAT32、真实SDRAM/reader或原子显示提交 |

用户可等代码继续补齐后集中验证，本轮不需接板。仓库根目录执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只跑本块：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_fb_writer.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_transform_writer.do'
```

日志分别为`src/sim/build/fb_writer/fb_writer.log`及`src/sim/build/image_transform_writer/image_transform_writer.log`，沿用S_test_pass与退出码0/1。整槽清屏自检比小图协议用例更耗仿真时间，请等明确PASS/FAIL。当前Media46组、Storage13组、All65组、P0六组，全部未经编译或执行；不要并发启动共用用例目录的批次。

完整文件到writer的任务所有者现见下一节；后续还需真实SDRAM适配、reader与提交CDC、版式/转场及最终top；约113 KiB超100 KiB资源规划仍未解决，没有资源、吞吐、时序或P2验收结论。


## 完整BMP离屏帧装载所有者

新增`src/rtl/media/bmp_frame_load_ctrl.v`及`bmp_frame_loader.v`，接口见设计02 §5.9.2。loader唯一实例化现有file_source（含parser）、transform（含geometry/scaler/rotate）与writer，不新增路径/像素缓存，不实例化core、slot_manager或物理SDRAM。每次CLEAR_REGION先完整清背景再放入一张适配后的BMP；layout当前只是结果元数据，多素材版式仍待后续调度。

接线顺序：外部确认所选context已关闭、旧I/O已排空且open/path namespace独占后给root.lease_grant；root.start接受命令快照并请求slot ALLOC。真实非零token成功后才启动file_source，路径流由调用方保存快照并按ready提供。header握手启动transform，geometry握手启动writer。loader的fs端点直接沿用file_source，mem端点沿用writer（每笔接受写都要同tag/token/generation的真实write_done）；slot命令及结果接唯一或经过仲裁的slot_manager，producer/memory退休确认随FINISH提供。不得和扫描/双音轨直接并接namespace或命令口，也不得用ready/固定等待代替写退休。

root分别记录子任务实际启动与唯一匹配终态。writer.source只在真实文件关闭/解析终态和transform终态都收到后发布；source_error为0/1，详细诊断在root结果中。写错取消文件/变换并等待真实read.done、已接受cancel的cancel_done、close、parser/transform终态及所有写响应；来自writer根因的同伴取消不反馈成新的writer用户取消，保留原始写错。全部退休才FINISH，成功决策后普通abort不改已呈现success；媒体失效仍可由槽管理器拒绝。异常FINISH/零token保留slot_owned隔离，结果消费仅释放namespace，busy仍为1，禁止重新start；需要查明槽状态，不能局部reset硬清。

root.done保持error/context/slot/tag/generation/token、published/slot_owned、三started标志、各原始error及接受/退休写数和像素数。error为0成功、1配置、2槽、3文件/BMP、4变换、5writer、6媒体、7用户取消、8协议；媒体6优先取消7，其余保留首因，异常FINISH另报告协议8。published只表示实际FINISH发布过READY，消费时仍须核对当前媒体代次与槽状态，不等于前台帧提交。全局reset必须与core/所有者/存储统一；无自动重试/超时或安全页文件绕过。

| 用例 | 已准备覆盖（未运行） | 边界 |
|---|---|---|
| bmp_frame_load_ctrl | 两类槽命令反压/快照、租约门控、file/transform终态任意先后及同拍、联合source保持、file晚失败、writer错误等同伴退休、header/geometry前取消、错身份、瞬断、FINISH决策边界、配置/保留context、拒绝/零token/异常FINISH隔离、结果冻结及reset | 子模块/槽返回是显式协议激励 |
| bmp_frame_loader | 真实完整像素链与slot_manager，四次整槽清背景/四方向/两种BMP位宽及行序，逐点核对整帧；分别延迟file.done/close/最后写响应、晚文件错、写错等待read.done和真实cancel_done/close、头前打开错及无需局部reset重装、媒体瞬断 | FAT文件协议与逻辑写响应/帧数组为端点，没有真实core/SDRAM/reader/提交CDC |

你可以继续集中验证，不需要现在接板。在仓库根目录执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只检查本块时，先运行已有复位和依赖模块测试，再运行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_bmp_frame_load_ctrl.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_bmp_frame_loader.do'
```

日志为`src/sim/build/bmp_frame_load_ctrl/bmp_frame_load_ctrl.log`及`src/sim/build/bmp_frame_loader/bmp_frame_loader.log`，沿用S_test_pass和退出码0/1。整帧清屏比较需要更多仿真时间，等明确PASS/FAIL；不要并发运行共用用例目录的批次。当前Media46组、Storage13组、All65组、P0六组，全部未编译/运行；无资源、时序、吞吐或板测结论。

行预取reader现见下一节；后续还需真实SDRAM接收/完成/刷新契约及适配、提交CDC和scanout、五版式/七转场、共享文件所有者仲裁、完整播放调度、UI/Flash和最终top。约113 KiB超100 KiB资源规划仍未解决，所有阶段验收保持未勾选。


## 双源行预取、缓存所有权与有序退休

新增`src/rtl/display/fb_line_reader.v`与`fb_reader.v`，接口见设计02 §5.10.1。A/B各两条640×32双口行RAM，共10 KiB；只缓存完整源行，不能替代完整帧。每源任务/终态各一份真实async_fifo，默认深度4，四FIFO裸载荷共386 B及pending-tag共64 B需单列资源，实际块RAM分配和寄存器另由TD核对，约113 KiB超100 KiB规划仍未解决。

使用方法：

1. host侧先取得并持续保持对应source的slot_manager READ_LOCK，向lease端口给slot/token/generation；video侧通过后续可靠提交CDC取得同一身份，不能裸跨多位租约。掉卡后已持读锁的旧完整帧仍可读取，lease_valid不能直接接media_valid。
2. video发task，携带source、slot/base/y/bank、token/generation、epoch/tag及已换算为host域的deadline。bank必须空闲，task接受即预约；base核对固定槽表、y<480。host逐字读base+y*640+x，默认8笔包含暂存的信用；读响应身份匹配且实际到达才写预约行，无固定延迟推断。命令反压后取消仍保持valid及全部载荷。
3. 640笔真实成功返回并将line终态通过FIFO消费后，该bank才允许video同步读。bank/x读取一拍输出RGBA与身份，无输出反压，可每video拍一个像素；扫描控制须同拍延迟。可反复读已完整bank复用源行，新y需要新任务。另一bank后台填充时，原有效bank持续可读。
4. 不再引用该bank后发release，匹配bank/token/generation/epoch/tag且最后像素输出已排空才释放；旧身份release接收丢弃，不影响新行。bank状态属于video域，不能裸跨到host作为锁证明。
5. 切槽停用用video域retire_request/ack四相协议。立即停止task/read、清本地许可，撤销未消费line结果是明确取消例外；有序barrier排在全部已接受任务后，host取消后仍排空已呈现/接受读，各旧退休记录先于barrier进入同一FIFO。video自动消费至barrier及自身像素排空才ack；请求撤销后才恢复。host_retired仅证明本reader内部，外部scanout/混合流水须另行排空，然后才能向slot_manager RELEASE。时钟停顿只延迟确认，不提供超时硬回收或局部flush。

fb_reader统一任务/line结果source0=A/source1=B；其余端口低切片A、高切片B。例如mem_addr为42位、mem_tag/token/generation为64位、read_x为20位、RGBA为64位，bank_valid为4位且每源低bank0/高bank1。两路mem客户端仍独立，未来仲裁器须保留客户端路由；每实例单调tag相同数值不能跨源混淆。line结果保持选择，等待时另一源结果不能抢占；停止相应源可撤销其未消费结果。

错误为0成功、1配置、2租约、3存储、4返回协议、5退休取消、6tag耗尽，优先级2>5>3>4>6>1，保留原始memory_error及接受/退休计数。错token/generation返回丢弃，当前租约错tag不能当作实际完成，仍须等真实响应；耗尽不回绕，退休不重建tag空间，只有统一global reset可重建。结果错误不会发布半行，外部欠载回退和VIDEO_UND属于未来scanout。

| 用例 | 已准备检查（未运行） | 边界 |
|---|---|---|
| fb_line_reader | 两bank/完整640像素/重复源行、结果反压与发布门控、8笔信用饱和、地址/身份/单调tag、错token/错tag与存储错、瞬时租约失效、非法base/y/未持租约、slot5末字、release错身份及最后像素排空、双任务排队/命令反压时停止、host/video分别停钟与恢复；小tag空间/同拍响应及统一reset | host租约与逻辑读返回为显式协议端点，不证明真实锁获取/SDRAM |
| fb_reader | 真实A/B reader与各自CDC、可变延迟独立存储端点、保持轮转结果仲裁、并行正反向x读取、缓存复用、一源退休另一源持续读取、旧release隔离、单源错误和双源barrier | 无真实slot_manager读锁流程、提交CDC、完整scanout、物理仲裁/SDRAM或HDMI |

后续可集中运行，无需现在接板：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独运行本块前先验证原复位/FIFO和已有依赖模块：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_fb_line_reader.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_fb_reader.do'
```

日志为`src/sim/build/fb_line_reader/fb_line_reader.log`及`src/sim/build/fb_reader/fb_reader.log`，保持S_test_pass及退出码0/1约定；不要并发启动共享work/log目录的批次。当前Media46组、Storage13组、All65组、P0六组，全部未编译/执行。本轮只做人工及纯文本审查，不替代RTL语法/展开、功能、双口RAM映射、物理CDC/Gray偏斜、125 MHz时序、显示带宽或板测。

帧配置提交CDC现见下一节；下一步为资源所有者与scanout控制，后续还有截止时间存储仲裁、真实SDRAM适配、五版式/七转场、共享文件仲裁与播放调度、UI/Flash、完整HDMI音频和最终top，仍不能宣布整个项目代码已完成。


## 帧配置提交CDC与真实首行门控

新增`src/rtl/display/frame_commit_cdc.v`（协议核）及`display_commit.v`（固定显示配置包装），见设计02 §5.11.1。配置247位，含A/B完整身份与角色、效果/进度、颜色参数和候选首行身份；加自动epoch32/tag16后295位命令经真实async_fifo送video，95位结果FIFO返回host。默认两FIFO裸载荷195 B及全部配置/状态寄存器需计资源，不能忽略TD实际RAM粒度，约113 KiB超100 KiB规划仍未解决。

调用方式：host先取得并保持实际读锁，用lease_valid/slots/tokens/generations/resident提供证据；submit握手快照配置并分配单调epoch。使用O_next_epoch可规划候选任务，耗尽为0且新提交返回error5，禁止回绕。video资源所有者接prepare请求，按pending配置安排真实reader首行/必要音频，真实prepare.done匹配epoch/tag才结束准备。display包装仍独立核对reader四bank的valid/slot/y/token/generation/epoch/tag和audio display epoch，不因prepare.done声称成功就跳过行证据。I_allow_apply为video域外部授权，I_video_abort锁存撤销；提交前授权/取消必须通过可靠所有者，host取消同步有延迟，最终以applied事实判断是否已生效。

全部准备成功且某个后续frame_start才原子更新active整组字段；准备终态和帧界同拍会等下一帧，场中保持。失败/提交前取消先等已启动prepare真实终态，再请求候选资源退休，旧active不变；未启动prepare不等虚构done，但候选所有者仍要确认已无候选义务。成功生效后retire_old=1携带旧active，真实退完旧资源才向host返回成功；首次没有旧active则没有旧退休义务。retire请求接受与done分开，错身份丢弃，同拍接受/匹配done允许。retire错误保留原始码、applied事实及quarantined，禁止继续复用未知资源，不自动回滚或假释放。

retire不能直接连fb_reader整源retire_request：旧新配置可共享读锁而占不同bank，整源flush会同时清新前台。资源所有者应按retire配置身份取消旧任务/释放旧bank并排空外部scanout/混合流水；共享锁继续保留，不再使用才在真实reader和外部流水都退休后READ_RELEASE。现有每owner只持一个槽，活跃source换槽、ALERT抢占和候选资源规划仍需后续所有者实现，本块没有自动取锁/释放、扫描输出或完整播放器调度。

host.done保持error/prepare_error/retire_error、tag/epoch/previous_epoch、applied/retired/quarantined，直到消费；跨域四相归零后才接受下一项。error0成功/1配置/2准备/3提交前取消/4授权撤销/5epoch耗尽/6退休失败，退休失败隔离优先，其余提交前4>3>2。host/video任一停钟只延迟事务，禁止超时伪造完成。所有相关所有者与流水必须统一global reset，媒体局部reset不能清提交状态。

| 用例 | 已准备覆盖（未运行） | 边界 |
|---|---|---|
| frame_commit_cdc | 快照/反压、真实准备/退休终态与身份、帧界/readiness、首项/替换/候选错误、取消前后边界、授权、时钟停止恢复、结果保持、退休同拍返回、已apply/未apply退休失败隔离、2位epoch耗尽/reset | 配置核32位测试载荷，prepare/retire为协议端点，不是实际所有者 |
| display_commit | 真实fb_reader首行填充和双源CDC、host范围/租约拒绝、首行缺失/完整但epoch错、音频epoch/授权门控、整组场中保持/帧界apply、alternating bank提交及旧bank逐个释放、部分候选失败保持旧前台 | 存储为显式同拍逻辑响应、准备/退休为测试所有者；无真实取锁/扫描流水/HDMI |

后续可集中执行，无需现在接板：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独本块时先验证原复位/FIFO及reader，然后：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_frame_commit_cdc.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_commit.do'
```

日志`src/sim/build/frame_commit_cdc/frame_commit_cdc.log`与`src/sim/build/display_commit/display_commit.log`，S_test_pass和退出码0/1约定不变。当前Media68/Storage13/All87/P0六组，全部未编译/执行；不要并发使用同一用例目录。仅静态审查不证明HDL功能、RAM映射、物理CDC、资源/125 MHz时序、带宽或板测通过。

下一步继续资源所有者与scanout控制，随后还需完整转场/版式、存储仲裁和真实SDRAM适配、共享文件仲裁与播放调度、UI/Flash、HDMI音频及最终top；不能宣布完整项目已写完。


## 七转场坐标、行需求与RGB混合（2026-10-23，未验证）

本块新增`transition_plan/transition_map/blend_unit`，精确端口见02 §5.12.1，数学见04 §4。它们只做video同域运算；真实reader、候选/旧配置资源所有者、扫描预取/欠载、转场帧时间线与HDMI接入仍未完成。

连接方法：

1. 将effect0..6、progress0..65536与epoch/tag送plan的start握手；保存的done全部字段保持，只有error0才允许交给map。zoom两个32位除法器并行32拍，调用者须提前安排，不能在像素路径执行可变除法。
2. 将合法plan全部同名字段接map配置口。config_ready仅证明map算术流水空；帧界授权、真实行准备和外部reader/blend流水退休由所有者负责。安装配置须在消隐期给输入valid留空拍并等map流水空，不能将valid永久置1后仍期待config_ready。输入光栅不能反压，map两级连续输出逻辑A/B use、源x/y、权重及对齐控制/身份。
3. 扫描前以query_y查询整行所需源行，映射逻辑A/B到实际reader source。zoom的B行可能与屏幕y不同，重复行可复用完整bank。mosaic中间阈值为保守两源集合，允许额外读取。预取失败不能读取半填bank。
4. map坐标送真实reader同步读口时，其use/weight、控制及身份须等长旁路；实际RGB与这些字段一起送blend，blend再延迟两级。当前集成测试直接由坐标生成RGB，所以map到blend总计四级；该数不包含真实reader延迟。

固定640×480；t0/t1明确为A/B原图；默认硬边。zoom使用Q16半像素最近邻，中心矩形零宽/高为空，乘加后钳位；blend三个通道并行，`(A*(65536-w)+B*w+32768)>>16`，未使用源为黑，DE0输出黑。非法权重钳位65536并随像素报告weight_error。16px软边与smoothstep尚未实现。

| 用例 | 准备的检查 | 范围限制 |
|---|---|---|
| transition_pixel | 真实plan/map/blend；七效果各t0/32768/65536完整640×480帧；t1/69/16384/65535网格及矩形边界；全部屏幕行独立遍历检查不漏源；零宽/高及1像素zoom、映射/RGB/控制/epoch/tag、计划快照与保持、非法计划不覆旧配置、稀疏valid、除法/像素中断reset及恢复 | 源RGB由坐标生成，无reader/文件/SDRAM、帧进度所有者或HDMI |
| blend_unit | 全部65537个合法Q16权重、三个通道独立码值、四种use组合、非法65537/131071钳位、DE0/空拍、连续与稀疏输入、固定延迟、复位中断后重用 | 无真实像素源、资源或显示时序结论 |

用户可留到代码补齐后集中执行。仓库根目录运行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独重跑：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_transition_pixel.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_blend_unit.do'
```

日志在`src/sim/build/transition_pixel/transition_pixel.log`及`src/sim/build/blend_unit/blend_unit.log`，沿用S_test_pass及退出码0/1；不要并发使用同一用例work/log目录。整帧及逐行参考检查较多，请等到明确PASS/FAIL。当前Media68/Storage13/All87/P0六组，全部未经编译或运行，P0—P7验收未勾选。

本轮仅人工及纯文本审查。无新增像素RAM/ROM，但两个迭代除法器、zoom乘加、六个RGB乘积及控制寄存器仍须计入综合；既有约113 KiB超100 KiB资源规划仍未解决。没有DSP/资源、物理CDC、25 MHz时序、行截止时间、SDRAM带宽或板测结论。后续继续真实scanout和资源所有者、版式/帧时间线、存储仲裁及物理SDRAM适配、共享文件仲裁/播放调度、UI/Flash、HDMI音频与最终top，完整项目尚未写完。


## 真实行缓存扫描与整行欠载回退（2026-10-23，未验证）

`scanout_engine`（117端口）组合timing/map/blend，reader在外部连接；接口见02 §5.11.2。没有新增RGB行RAM，使用已有两源双bank。video_timing新增只读O_raster_x/O_raster_y，两处旧实例明确空接，原时序不改。

连接与授权：

1. 将可信plan全部字段及完整物理source mask/from_source、slot/token/generation/epoch/tag送配置握手。每帧首条光栅行的消隐窗口最多接受一次，必须本地任务/释放已退休、像素流水空。外部资源所有者须先完成真实READ_LOCK、候选首行及必要音频，再协调display_commit与本地安装；pending不能未经apply授权直接使用。配置输入没有跨域功能。
2. task/line/read/pixel/bank/release端口分别与fb_reader同名反向连接。task源0/1为物理源，逻辑A=from_source、B=另一源。line_ready只消费本模块实际接受任务的完整匹配终态，外部候选任务与结果必须由所有者仲裁；不能直接并接两个消费者。
3. 根据O_prefetch_y/O_active_epoch提供已可靠交付到video域的I_deadline_valid/y/epoch/deadline。deadline是125 MHz域绝对标签，匹配目标才发请求。当前模块不实现跨PLL时间换算，不可将video本地计数直接相连。测试使用明确标签，仅检查流转。
4. 配置可允许扫描器认领匹配源身份的完整行；O_owned_banks包括本地已呈现/已接受/已采用的bank，外部准备候选须避开这些bank，并协调同拍任务仲裁。扫描器不会释放不属于自己的其他epoch候选。I_retire_epoch/O_epoch_retired只证明本扫描器不再使用该epoch，槽所有者还须汇总外部候选、任务和其他消费者。
5. I_stop_request保持至O_stop_ack，再撤请求并等ack归零。停止不撤已经呈现的task/release，等真实行终态、逐bank释放和五级引用排空；不得提前撤租约或对共享reader做整源flush。停止后旧配置失效，重新配置才恢复。只允许与reader/存储统一全局reset。

每有效行HS起点统一查找整组完整源行，未齐全则重复上一次完整行的bank与映射y，真实屏幕坐标及同步继续推进，O_video_und/und_count报告。晚到数据不在行中替换；未使用的晚行在自身五级引用为零时即可释放，允许下一行恢复。首次无完整行输出黑是启动兜底，不能代替真实提交首行门控。

读取与输出：map两级、真实reader同步一拍、blend两级，共五级、每拍一像素。重复行保留之前映射y来保证整个混合行一致，输出y仍为当前屏幕y。返回核对valid/bank/x/token/generation/epoch/tag；意外身份错误只输出黑并对齐pixel_fault/contract_fault诊断。正常行欠载与契约错误是两种情况，均不读取半填行。颜色、OSD及HDMI AXIS适配仍在后续连接。

新增`tb_scanout_engine.v/run_scanout_engine.do`准备以下场景，均未执行：

- 七效果中间进度完整640×480帧与两种from_source角色，独立坐标/定点/颜色参考核对实际reader RAM输出、五级时序与身份。
- 倒退epoch配置拒绝后继续完整旧画面；外部任务预填未来epoch候选bank，本地停止不释放该bank；没有deadline授权时光栅继续、无任务发出，及时授权后首行仍正常。
- 一源第7行延迟至该行开始后才返回，整行重复第6行且第8行恢复；实际存储错误使第3行重复第2行，检查原始错误、没有半行发布。
- 返回像素tag损坏，指定像素黑色及fault同拍，不混入另一源；任务/释放在反压时载荷不变。
- 停止发生在task尚未握手，host/video分别停钟与真实读返回延迟、错行tag不消费、释放反压均不得提前ack；真实退休后四相归零，再安装新配置扫描完整帧。

运行（仓库根目录）：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单项重跑：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_scanout_engine.do'
```

日志`src/sim/build/scanout_engine/scanout_engine.log`，S_test_pass及退出码0/1约定不变；整帧黄金比较耗时，请等明确PASS/FAIL，不并发共享work/log目录。当前Media68/Storage13/All87/P0六组，全部未编译或运行，P0—P7验收保持未勾选。纯文本审查不能证明HDL语法/功能、RAM映射、资源、五级25 MHz时序、物理CDC、SDRAM行截止或板测。

剩余关键工作是候选/旧配置资源所有者、实际锁/换槽/ALERT与deadline换算、完整提交到本地安装、转场时间线/五版式、六客户端存储仲裁与真实SDRAM证据/适配、共享文件仲裁/播放调度、UI/OSD/UART/Flash、HDMI音频及最终top。既有约113 KiB超100 KiB规划仍未解决；扫描器的元数据、每bank五级引用位和控制旁路也须计入综合，不能声称完整项目已完成。


## 物理双源读锁所有者（2026-10-23，未验证）

`display_lease_ctrl`（59端口）在125 MHz host域管理真实slot_manager owner0/1读引用；不改每owner单槽，也不直接访问像素。正常换图以物理源轮换：当前源持锁扫描、空闲源取得新图、提交双源转场、完成后帧界只用目标源，旧源真实退休并释放后再装下一项。两源都活动时第三目标需等待，不能覆盖在用源；完整ALERT和候选资源调度仍待上层实现。

连接：

1. start用op0取得/op1释放，source0/1、slot/token/generation/tag；done保持error/slot_error和完整身份、changed/cancel_late。已有同身份lease可直接复用，重复取得也是源占用冲突；不会为同source自动换槽。
2. slot_cmd/result与真实fb_slot_manager经独占或保持选择仲裁连接；控制器只用ACQUIRE/RELEASE。其他管理器输入asset/layout/rotation/resident/success在这两op不使用，由仲裁器正确赋值；producer_retired/memory_retired只供真实生产事务，不能因本测试fixture而在最终系统常接1。对照全部实际slot状态/读引用/token/generation/resident后才输出lease_valid/slots/tokens/generations/resident给reader及display_commit。
3. source_idle是host域可靠授权，含无active/pending配置、候选和未来读义务；acquire_permit须来自真实帧界/资源协议。不能裸跨video单拍或以常1代替。许可形成保持命令后即使脉冲结束，valid/载荷保持至真实ready。
4. release先等旧ack归零，再保持retire_request；真实所有者须停止该源新读、汇总已呈现/接受任务、完整bank及外部scanout流水才给本轮ack。此端点未集成，不能简单接FIFO空、source_idle或cancel_ready。只有该源不再被active/candidate共享时才允许源级stop，否则须按bank回收。控制器等真实RELEASE结果清实际读引用，再撤请求并等ack归零，才done。
5. 早abort可以取消未呈现命令；晚取得取消仍等真实结果，changed=1表示锁确实取得，须另发release。退休已开始后的release.abort只记cancel_late并完成释放。授权撤销/实际引用丢失/孤立owner0/1引用造成quarantined，保留owned未知义务，消费done也不能重用；统一global reset须与reader、槽和全部外部任务共同处理，禁止媒体局部reset绕过。

掉卡不会自行清现有读锁，旧generation仍可保留扫描及按原身份释放。新取得由slot_manager校验有效介质；resident slot5允许无卡使用。lease_valid按真实状态匹配而不是媒体当前代次，quarantine保持时仍有实际有效锁不会被凭空撤销。

新增`tb_display_lease_ctrl.v/run_display_lease_ctrl.do`连接真实槽管理器，准备六槽实际ALLOC/FINISH，并检查双源轮换、同槽共享、源冲突与错误身份、介质失效/常驻页、许可等待、载荷/终态保持、错返回、旧ack和四相归零、早/晚取消、停钟、取得/释放期间授权瞬断、成功结果与实际引用不符、实际引用丢失/孤立引用隔离以及统一reset重用。退休/授权是显式协议端点，没有真实reader、候选首行、跨域许可、完整提交/ALERT、物理SDRAM或性能证据；所有自检均未运行。

用户可继续留到代码补齐后集中执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单项重跑：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_lease_ctrl.do'
```

日志`src/sim/build/display_lease_ctrl/display_lease_ctrl.log`，沿用S_test_pass与退出码0/1；不并发共享work/log目录。当前Media68/Storage13/All87/P0六组。只做人工与纯文本检查，未编译、仿真、综合或上板，全部验收未勾选。

两源裸租约元数据138bit=17.25 B，另有命令/结果/状态寄存器，无新像素RAM；实际资源须综合，既有约113 KiB超100 KiB规划仍未解决。接下来仍需可靠idle/帧许可和真实退休桥、候选首行/旧配置回收、commit到scanout安装、deadline换算、ALERT/转场时间线/五版式、存储仲裁及真实SDRAM证据/适配、共享文件仲裁/播放调度、UI/OSD/UART/Flash、HDMI音频及最终top；不能宣布全部代码已完成。


## 显示源跨域保留与真实reader退休（2026-10-23，未验证）

`display_source_guard`（19端口）连接host125 MHz读锁控制与video25 MHz资源所有者/reader，接口见02 §3.1.3。两源各自四相电平握手，只跨源域寄存bit；不传多位租约，不新增RAM/FIFO，不生成flush或局部reset。

连接顺序：

1. host将目标source的reserve置1，保持至lease事务终态消费及退休ack归零。video在真实frame_start且该源in_use=0时才给grant并置video_block；in_use必须汇总active/pending/候选及同拍新入口，video_block阻止将来新配置/任务，不得与in_use组合自锁。在用源不会被本桥停读。
2. host_source_idle/host_acquire_permit直接接display_lease_ctrl对应输入，获得授权后才start取得/释放。取锁完成后撤reserve，等待host_busy=0以及video侧解除block，再准备新候选/开始读；不能在保留中启动候选。
3. lease_ctrl.retire_request接host_retire_request，host_retire_ack返回lease_ctrl.retire_ack；video_reader_stop接fb_reader.retire_request，真实fb_reader.retire_ack返回video_reader_ack。只有源已排除active/pending/候选配置引用后才会grant，所以允许在该源做完整停止；仍被新前台共享的源不得用此退休路径。
4. 外部资源所有者分别给video_owner_retired和video_pipeline_retired，汇总该源候选/任务及scanout外部流水；真实readerack只代表内部任务、写bank与同步像素已退，不能替代外部证明。三个条件共同到达才给host确认。请求归零后先撤reader_stop，等真实readerack0，最后才让host ack0；保留释放也等待这一过程完成。
5. host/video停钟仅延迟握手。早撤reserve仍完成已发保留请求的四相归零；获得保留后该源in_use再次出现为协议错，video_fault保持并同步到host_fault，host授权撤销。已开始的未知退休不假装完成，隔离需统一global reset。共享reset必须同时重置相关槽/reader/任务所有者，不能把它当媒体软复位。

新增`tb_display_source_guard.v/run_display_source_guard.do`连接真实guard、lease_ctrl、slot_manager及fb_reader/FIFO/行RAM，准备两槽真实ALLOC/FINISH后取锁、在用源无grant/stop、一个源完整行及在途读、另一源持续像素/身份、真实读响应延迟与barrier退休、外部owner/pipeline分别延迟、命令反压、host/video分别停钟、真实reader ack归零、两轮退休/旧ack、早撤保留、双源并发授权与独立归零，以及授权违例/统一reset恢复。测试的存储响应为显式零延迟逻辑端点，in_use和外部引用证明由TB驱动；没有真实scanout按源汇总、候选首行、完整资源所有者或物理SDRAM，未运行。

后续集中运行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单项重跑：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_source_guard.do'
```

日志`src/sim/build/display_source_guard/display_source_guard.log`，S_test_pass及退出码0/1约定不变；不要并发共享work/log目录。当前Media68/Storage13/All87/P0六组，均未编译、仿真、综合或板测，全部P0—P7验收保持未勾选。

两源各26bit寄存控制/同步状态，另有两域reset_sync，实际综合映射和同步器布局/约束待确认。没有资源、物理CDC、125/25 MHz时序、行预取截止或真实SDRAM带宽结论；既有约113 KiB超100 KiB规划未解决。完整in_use/外部按源引用证明、候选首行/旧配置回收、commit到scanout安装、deadline换算、ALERT/帧时间线/五版式、存储仲裁及物理SDRAM证据/适配、共享文件与播放调度、UI/Flash、HDMI音频和最终top仍需继续。

## 扫描器按源占用与退休证明（代码准备，未验证）

`scanout_engine`增加I_source_block和三组两位输出O_source_in_use/O_source_owner_retired/O_source_pipeline_retired，共117端口。block接source_guard.O_video_block。配置使用已保留source时保持等待；未阻塞的合法配置在呈现期间就计入in_use，避免帧界安装与保留同拍竞争。已安装配置按完整source_mask占用，即使转场端点暂时只读其中一路，也不能提前释放另一读锁。

owner证明来自本地真实bank认领、已呈现/接受任务、释放保持以及本拍新任务/认领；pipeline证明来自该源两bank五级引用与本拍新像素引用。in_use同时包含这些本地引用；配置移除source后仍等真实行终态、bank释放和像素排空，随后guard才可在后续帧界保留和停止reader。另一源扫描不阻塞本源证明。reset期间不发布退休证明，无新增寄存器/RAM/FIFO。

完整资源所有者应将本扫描器in_use与候选/其他任务占用按位OR；owner/pipeline_retired分别与对应外部证明按位AND。不要把reader所有reserved bank直接并入in_use：未认领bank可能正等待reader整源退休清理，形成循环依赖。当前输出只证明本扫描器，不证明尚未实现的候选所有者已退休。

扩展既有`tb_scanout_engine.v/run_scanout_engine.do`，加入真实source_guard，准备双源活动、配置移除单源、跨帧release反压不提前grant/reader_stop、另一源持续真实像素且退休证明独立、真实reader barrier与ack归零、保留源的新配置保持等待、解除保留后重新完整扫描、未阻塞pending与帧界保留竞争，以及video停钟保持真实引用、不制造退休证明。原有七效果逐像素与所有停止测试保留；guard场景无外部候选，读锁由夹具保持，不能代替完整资源所有者/lease_ctrl集成。原display_source_guard用例继续覆盖真实lease_ctrl/slot_manager，两个用例都未执行。

无新增批次或日志：Media68/Storage13/All87/P0六组。后续运行同一`run_scanout_engine.do`，日志仍为`src/sim/build/scanout_engine/scanout_engine.log`；集中命令仍为`& ./src/sim/run_p0.ps1 -Suite All`。未编译、仿真、综合或板测，P0—P7验收未勾选。下一块继续候选资源所有者及提交到本地安装协调；deadline换算、物理SDRAM和最终top等缺口仍在。

## 候选首行资源所有者（代码准备，未验证）

`display_candidate_ctrl`（88端口）在video域接display_commit的prepare和未生效候选retire（retire_old=0），使用真实reader的整行任务/终态及按bank释放接口；详细接口见02 §5.11.3。首行y/bank/tag由外部完整配置所有者指定，deadline为已可靠交付的host绝对标签。暂不处理旧配置retire_old=1，也不自动取/放读锁；不得将所有retire请求不分来源直接接入。

1. 目标bank已被reader保留或外部认领时等待。接受后立即以claim_banks保留全部候选目标（含尚未发请求的第二路），外部分配器须尊重；owned_banks只表示实际成功取得的bank。合法未阻塞pending从呈现起计入source_in_use。外层将它与scanout/其他任务占用OR，owner_retired与各owner真实证明AND；I_authorized必须为video域可靠身份授权，不裸接host多位租约状态。
2. 任务串行按源发出，已呈现请求在取消/授权变化后仍保持到接受，随后等完整source/bank/slot/base/y/token/generation/epoch/deadline/tag匹配的真实line。未呈现的第二源不会因取消被额外启动。真实失败保存line_error/memory_error，已成功兄弟bank仍由本owner保留。prepare.done为保持结果，发布后冻结，不等于bank释放。
3. 取消和授权撤销即使是短脉冲也锁存至候选结束。成功结果已发布后仍不改写，但不再允许候选接管。新配置实际安装并认领全部成功bank，或完整核对seed并承诺在adopt同沿全部认领后，才以匹配epoch/tag的adopt握手移交所有权；仅config_applied脉冲、部分claim或取消后的claim都不足以移交。握手不发送release。
4. 未生效候选retire核对全部成功bank的实际valid/reserved及完整身份，且不能已被其他所有者认领；逐路release保持至真实ready后才done。未启动prepare时可直接retire证明无本地义务。身份消失/外部意外认领或释放握手时失去证明返回retire_error4并隔离，保留不确定bank；已呈现release仍不能撤。没有整源stop、超时假完成或局部reset回收。

`tb_display_candidate_ctrl.v/run_display_candidate_ctrl.do`实际连接88口candidate与84口双源reader、FIFO/行RAM，存储为显式零延迟逻辑端点。准备：

- 双源首行成功与旧前台bank并存，旧bank持续真实像素/epoch/tag不变；部分接管拒绝、完整接管不释放bank。
- task反压中取消，仍接受并退休已呈现请求，不启动另一源；host停钟不造line完成、错line身份不消费。
- reader第二源真实存储错误，保留第一源成功bank后精确回收，旧前台不受影响。
- release反压/video停钟不提前done，保持task/release载荷与prepare/retire结果。
- 单源/配置快照、非法行号不占bank、取消发生在prepare前的空退休。
- 成功结果发布后取消/授权撤销短脉冲不改写结果但阻止接管，目标占用/源保留等待。
- 错retire身份不能消费；bank证明损坏、release已呈现后才丢证明仍须排空，返回隔离且禁止复用，统一reset恢复。

测试中的adopt/claimed为显式扫描器接管证明端点，读锁由夹具保持，没有真实display_commit/scanout/lease_ctrl端到端或任务/结果/释放仲裁、候选首行需求推导、物理SDRAM。不能把这些端点作为尚未实现部分的验证结果；全部测试及黄金算术均未执行。

集中命令不变：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只跑本项：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_candidate_ctrl.do'
```

安装不同用runner的-VsimPath指定实际路径，日志`src/sim/build/display_candidate_ctrl/display_candidate_ctrl.log`，沿用S_test_pass与退出码0/1；不要并发共享work/log目录。当前Media68/Storage13/All87/P0六组。没有HDL编译、仿真、综合、TD或板测，全部P0—P7验收未勾选。

本模块新增约333bit寄存状态/快照/保持输出（约41.625 B裸bit），另有组合身份核对，不新增RAM/FIFO；实际资源、时序和物理CDC仍未验证，既有约113 KiB超100 KiB预算未解决。下一步继续任务/结果/释放仲裁与旧配置所有者、首行bank接管及commit到本地安装协调；后续deadline换算、转场时间线/五版式、存储仲裁和真实SDRAM证据/适配、共享文件/播放调度、UI/Flash/HDMI音频和最终top仍未完成。

## 共享reader任务、结果及释放仲裁（代码准备，未验证）

`display_reader_arbiter`（26端口）在video域连接client0扫描器、client1候选首行owner及同一个fb_reader。task每client179bit、line207bit、release每client每source113bit，完整高低位定义见02 §5.11.4。该模块处理video客户端接口，后续SDRAM侧六客户端存储仲裁仍是另一块工作。

任务先由本地寄存缓冲接受，再保持到reader真实ready；四bank分别保存完整任务及client归属，实际reader接受后才允许匹配终态退休。结果只向实际owner给valid，其他client的ready不参与；身份不符或尚未发送的结果不消费、不清义务，锁存contract_fault。成功bank即使终态已消费也仍按真实reader reserved禁止重用，直到owner实际释放。

两source的release分别轮转并寄存保持快照。producer的ready只在真实reader接受该项时回传，不在捕获进本地缓冲时提前返回。producer在等待期间仍须保持valid和载荷，违例保留诊断，已经呈现给reader的快照仍完成。candidate或scanout仍须核对释放身份/实际引用，reader_discarded不能丢弃；仲裁不赋予未知bank的释放授权。

O_task_reserved表示从本地接受直到真实终态被client消费的bank义务，外层候选分配须合并该预约及真实bank状态。I_task_block每client四位，阻止尚未接受的新任务；已经接受的任务不因block/取消撤回。O_source_in_use/owner_retired汇总本地在途和两client待传请求，须与各owner证明共同接guard，不能先停reader再等待被取消的line。没有flush、超时假完成或局部reset。

本块不处理候选prepare与扫描器本拍新任务的bank分配竞争。完整所有者还须在创建任务/接受prepare前协调预约；仅把两个请求送进仲裁器可能造成双方已认领同bank的错误设计，不能据此宣布已解决。scanout的像素读口和bank元数据仍按原接口直接接reader；完整配置安装/旧配置回收/接管控制待后续连接。

新增`tb_display_reader_arbiter.v/run_display_reader_arbiter.do`，实际连接26口仲裁、88口candidate、84口reader和FIFO/行RAM，准备：

- 缓冲scan任务时candidate后来到达不得换请求；实际行只向原owner，scan反压不能把结果交给candidate。
- 候选完成时旧bank持续真实像素/身份；scan与candidate同源释放及另一源释放并行，真实reader拒绝前不返回ready，另一源可先完成。
- host/video分别停钟，候选或仲裁在途不能提前退休；候选task已入缓冲后取消仍真实发送/排空，不启动未呈现第二源。
- 成功bank在真实release前不能再次给另一client；同source同tag、不同epoch的先后任务依各自归属交付。
- blocked任务不挡另一可用任务，连续0/1/0/1轮转，四bank同时在途，producer推进载荷不覆盖旧结果的身份记录。
- 未实际发出任务的精确身份结果、错误身份结果不消费/不清记录并诊断；真实结果恢复后继续退休。
- reader真实存储错误只交对应client；release生产者改写等待载荷时诊断且保持reader侧原快照，统一reset恢复。

扫描器在本测试中为显式协议端点，部分用例将client1切换为手动端点以制造相同bank/标签和协议违例；没有实际scanout/commit/lease_ctrl端到端、完整bank预约协调或物理SDRAM。存储为明确零延迟逻辑响应，deadline为测试标签，不证明换算/带宽。所有测试均未编译或执行。

集中命令仍为`& ./src/sim/run_p0.ps1 -Suite All`，当前Media68/Storage13/All87/P0六组；不要并发共享work/log目录。单项：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_reader_arbiter.do'
```

安装路径不同用runner的-VsimPath；日志`src/sim/build/display_reader_arbiter/display_reader_arbiter.log`，S_test_pass和退出码0/1约定不变。未运行HDL编译、仿真、综合、TD或板测，全部P0—P7验收未勾选。

四bank任务记录4×179bit=89.5 B裸载荷，加task/两源release缓冲和归属/诊断，约1142bit寄存控制（142.75 B），不新增像素RAM/FIFO；实际映射与25 MHz时序仍待综合。既有约113 KiB超100 KiB预算未解决。实际bank预约协调、配置安装/接管及旧配置回收现接入下述组合块；完整host资源所有者、deadline换算、转场时间线/版式、存储仲裁与物理SDRAM证据/适配、共享文件/播放、UI/Flash/HDMI音频与最终top仍未完成。

## 实际显示管线（代码和自检准备，未验证）

`display_video_pipeline`（83端口）组合真实plan/首行query、candidate、reader arbiter、scanout与双源reader，保留既有FIFO/行RAM。它在接受prepare同拍预约目标bank，避免扫描器同时创建同bank任务；已有扫描任务继续真实退休。候选成功后，`frame_commit_cdc/display_commit.O_apply_valid`驱动同沿配置安装及全部seed bank接管，连效果端点暂时不用的源也移交。旧配置按完整247位配置/epoch/tag核对，等真实bank释放和流水退休才返回成功，禁止以整源flush替代共享源的旧配置回收。

接线：pending配置按02 §5.11.5的247位格式打包，prepare及retire的valid/ready/结果身份逐一相连；pipeline.O_can_apply合并外层最终授权后送commit.I_allow_apply，commit.O_apply_valid接pipeline.I_apply_valid。不要使用延迟的O_applied_pulse驱动安装。pipeline的源占用证明与其他owner汇总后接guard；先取消/排空本地候选和扫描任务，再允许guard停reader。host租约总线仅接reader host端口，video授权和host绝对deadline须可靠交付到video域，不能裸跨域。

新`tb_display_video_pipeline.v/run_display_video_pipeline.do`实际连接57口frame_commit_cdc与83口pipeline，准备以下自检：

- 七效果中点各一个完整640×480帧；同色逻辑存储数据检查实际像素、epoch和行连续性，不替代独立转场坐标/混合算术黄金测试。
- 首次提交及连续epoch提交的CDC active、scanout安装、candidate整组移交同沿；进度0/65536仍接管全部启用源的bank，旧epoch真实退休后才host done。
- 在途读被memory反压时取消不提前完成，host/video分别停钟与恢复；迟到取消只回收候选，旧active保持。
- 第二源真实memory error后回收成功同伴，prepare接受当拍的bank预约冲突断言，错误退休身份和非法apply隔离，统一reset恢复。
- 缺绝对deadline时不接受prepare；首行query不符先报错，不虚构未启动candidate的任务/资源义务。

读锁、授权和绝对deadline是显式夹具，memory为零延迟、按真实请求标签返回的逻辑端点；真实reader仍完成640笔行读取及身份验证。本用例不含display_commit包装的host范围/首行音频门控、display_lease_ctrl/guard完整host所有者或物理SDRAM。任务/结果/释放的专门反压与身份用例仍由现有候选/仲裁/扫描器测试分别覆盖，不能从此用例推出实机吞吐、相位、物理CDC、资源或25 MHz时序。

集中验证可继续留到代码准备完成后执行，当前Media68/Storage13/All87/P0六组：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只跑本项：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_video_pipeline.do'
$LASTEXITCODE
```

日志`src/sim/build/display_video_pipeline/display_video_pipeline.log`；runner汇总在`src/sim/build/all/<批次>/summary.json`。工具路径不同用-VsimPath，不要并发共享work/log目录。沿用S_test_pass和退出码0/1，全部HDL编译/仿真/综合/TD/上板均未执行，所有P0—P7验收继续未勾选。

新增根配置/身份/FSM保持寄存状态1022bit（127.75 B裸bit，不含2bit reset同步），另实例化一份24口plan与48口首行query map；新增scanout seed是控制/元数据接线，没有新像素RAM/FIFO。实际逻辑/DSP和时序未知，既有约113 KiB超100 KiB预算未解决。host显示事务控制现见下节，可靠租约发布及host/video全链、deadline换算和帧时间线仍待连接；物理SDRAM材料、版式/颜色、共享文件/播放调度及最终top仍需继续。

## host 显示资源事务（2026-10-24，代码与自检准备，未验证）

`display_host_owner`（97端口）实际组合lease_ctrl与source_guard。输入247位目标配置及tag：相同租约复用，空源在真实帧许可后取锁；已占源身份不符直接拒绝，不为第三个目标覆盖旧前台。每次取放锁都保持源保留，等待完整租约快照在video安装的可靠确认，再解除保留并等待四相归零。它随后提交原配置，成功后仅释放不在新mask中的源，未生效失败仅回收本次新增锁。未知资源保留隔离，不按固定拍数强制释放；普通取消在apply之后不回滚。

连接见02 §3.1.4：槽命令/结果口接真实slot_manager或保持选择的共享仲裁；owner0/1由本块独占。guard的video帧界/占用/reader ack/owner及pipeline退休证明接真实显示管线及其他所有者，block/reader_stop回连对应端点。commit的valid/ready、原配置/tag、next_epoch与完整结果接frame_commit_cdc，音频门控由外层给出。不要把host观测active或lease总线裸接video。

发布端口发送170位请求：version32及完整租约138={valid2,slots6,tokens64,generations64,resident2}。`I_publish_ready`只确认请求接收；带同version的done必须证明快照已在video安装。发布反压/停钟不能解除reserve。该用例的发布端点仍为夹具；真实CDC发布器现见下节；本轮没有以双触发器采样多位总线或请求入队来代替安装确认。

新增`tb_display_host_owner.v/run_display_host_owner.do`实际加载host owner内部lease/guard、真实slot_manager、frame_commit_cdc和双源reader/FIFO/行RAM，准备18组场景：

- 首次提交、双源共享旧锁、仅提交目标后真实释放旧源；候选失败仅清理新增锁、旧前台身份保留。
- 槽命令反压后晚取得取消，保留真实acquired/late事实并实际回收；提交请求反压中取消不能撤valid，明确epoch0未启动远端可清理新增锁。
- 发布请求与video安装确认分别反压，错version/提交tag不推进所有权；每个变化的源都须处于video block。
- 第三目标占用拒绝、掉卡后失效槽拒绝及resident安全页；真实prepare和旧配置退休终态分别延迟，不能提前释放锁。
- 实际reader有640字行请求在途时旧锁保留，host/video分别停钟不造完成；晚abort保留实际已生效的新active。
- 发布失败、生效后退休失败均保留未知资源并隔离；早取消/非法配置不产生副作用，32位发布版本耗尽不回绕，统一reset恢复。

发布安装由明确的理想夹具执行，video prepare/retire及外部像素引用也是协议端点；本用例**没有连接实际scanout或display_video_pipeline，也没有可靠租约发布CDC或物理SDRAM**。reader行任务与barrier真实执行，memory为显式同拍tag/token/generation回显的逻辑端点。槽ALLOCATION/FINISH夹具准备完整帧元数据，不证明真实BMP装载和写退休。不能从这些夹具推断显示正确、实机带宽、物理CDC、资源或时序。

根状态/快照/保持结果928bit（116 B，不含已有lease/guard及reset同步），无新像素RAM/FIFO；实际资源仍待综合，约113 KiB超100 KiB预算未解决。原始租约首错保留，acquired/released是本次真实改变事实；quarantine下done可能仍带reserve或锁，不等同资源已全部释放。

当前Media68/Storage13/All87/P0六组，用户可继续留到代码准备完成后集中验证：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只运行本项：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_host_owner.do'
$LASTEXITCODE
```

日志`src/sim/build/display_host_owner/display_host_owner.log`，整批summary在`src/sim/build/all/<批次>/summary.json`。工具路径不同使用-VsimPath；不要并发共享work/log目录。沿用S_test_pass与退出码0/1。全部HDL编译、仿真、综合、TD、黄金模型及上板均未执行，所有验收未勾选。

可靠租约发布CDC现已补齐（见下节）；下一块把host owner与实际video pipeline接通；随后仍有可靠deadline/音频授权、帧时间线/ALERT与高层播放调度、版式/颜色/OSD、六客户端存储仲裁及物理SDRAM真实契约、共享文件/上下文所有权、UI/UART/Flash/HDMI音频与最终top，完整播放器尚未完成。

## 可靠租约发布与真实 host 链（2026-10-24，代码与自检准备，未验证）

`display_lease_cdc`（26端口）用真实双向async_fifo发布完整租约，170位请求={version32,leases138}、36位结果={error4,version32}，默认各四项。仅一笔host事务在途；接收请求后保存快照，video实际安装后才返回同版本终态。版本从1连续递增、不回绕；错误保留旧video快照并隔离。变化源按完整69位身份比较，在安装沿核对block、无引用、owner/pipeline真实退休和无guard fault；未变化的另一源可以继续使用。host/video必须与slot、owner、guard、reader和commit使用同一global reset，不能只清一侧FIFO。

接线：host owner的publish请求/结果成组接本模块；`O_publish_ready`只表示请求接收，不能代替结果。video侧block、in_use、owner_retired、pipeline_retired和guard_fault接同域真实证明。`I_video_query_config`取可靠配置CDC的pending或active完整配置，`O_video_authorized`逐源核对mask/slot/token/generation/resident后接实际显示管线的授权输入；禁止裸跨host配置或租约。`I_video_install_enable`为video本域安装许可，常1可尝试立即安装，但每次仍核对实时资源证明。host原始真实租约继续给reader的host口。

新增两组，各自独立work/log目录，原host owner端点用例保留：

| 用例 | 准备检查 | 边界 |
|---|---|---|
| display_lease_cdc | 15类场景：接受后输入变化不改快照、安装延迟和结果反压、全身份授权/撤销、相同快照与另一源继续使用、失效租约、host/video分别停钟、安装沿重查引用、范围/版本错误、错返回version丢弃、两域版本耗尽、双停钟统一reset及恢复；token单字段变化分别缺失五项许可均拒绝且保留旧快照 | 双向FIFO及同步器真实；资源证明和query配置为video同域夹具。错结果/版本耗尽用层次force故障注入，不能据此推断真实亚稳态行为 |
| display_lease_cdc_host | 18类真实owner/lease CDC/guard/slot/commit CDC/reader连接场景：取放锁后真实FIFO安装再解除保留、请求/结果反压、失败新锁补偿回收、实际旧reader在途及停钟、取消早晚区别、掉卡/resident、发布许可故障与隔离；prepare成功需要真实已安装租约授权 | prepare/retire、pipeline退休及外部像素引用仍为端点；memory为同拍逻辑响应。未连接实际scanout或display_video_pipeline、真实BMP装载、物理SDRAM或HDMI |

默认新增FIFO载荷存储824bit（103 B），本块状态/快照/保持结果寄存592bit（74 B），不含FIFO控制/reset_sync与实际RAM映射粒度；既有约113 KiB超100 KiB预算仍未解决。纯文本统计不能当作综合资源报告。

当前Media68/Storage13/All87/P0六组。用户可等后续代码齐备后集中执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独检查新增两组（仓库根目录，先协议、再集成）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_lease_cdc.do'
$LASTEXITCODE
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_lease_cdc_host.do'
$LASTEXITCODE
```

日志分别在`src/sim/build/display_lease_cdc/display_lease_cdc.log`和`src/sim/build/display_lease_cdc_host/display_lease_cdc_host.log`；批量summary在`src/sim/build/all/<批次>/summary.json`。沿用S_test_pass与退出码0/1，安装位置不同时用runner的-VsimPath；不要并发共享用例目录。所有HDL编译/仿真、黄金模型、TD、综合、时序、物理CDC及板测均未执行，P0—P7验收不勾选。

上述资源整链现已组装代码（见下节）；可靠deadline换算、真实音频证明及播放器其余缺口继续保留，当前不能宣布完整项目完成。

## 实际 host/video 显示资源链（2026-10-24，代码与自检准备，未验证）

`display_resource_pipeline`（130端口）组合host owner、可靠lease CDC、配置commit CDC与实际video pipeline，内部包含lease/guard、候选、reader仲裁、scanout及双源reader/行RAM。host提交完整247位配置；本块先取得真实READ_LOCK并可靠安装video租约，随后真实prepare/帧界apply；新配置生效并等旧配置、reader和像素引用真实退休后，才释放不再使用的物理源。错误只按真实终态回收新增锁，未知状态保留隔离。

接入时，slot命令/结果及槽状态接真实slot_manager或保持选择的共享仲裁，owner0/1由本块独占。frame_start、源in_use、owner/pipeline退休、reader ack和停止请求已内部真实互连，不能另用常量或外部理想确认覆盖。host active仅为收到终态后的观测，video授权来自可靠lease CDC对实际pending配置的完整身份核对。提交握手前再次核对当前host租约（含resident），防止只依赖启动时的快照校验。

外部继续提供两个独立逻辑memory端点及真实返回，以及video域的prepare/scan deadline事务；deadline数值编码host125 MHz绝对时间，不能用video计数冒充。`O_pending_*`和`O_prefetch_y/O_video_active_epoch`用于后续deadline/音频所有者。音频required时，`I_audio_ready`与`I_audio_epoch`均须已可靠进入video域且epoch等于pending才允许apply；本块没有真实PCM或播放时间线。`I_scan_stop/O_scan_stop_ack`不是提交取消/候选回收的替代品。

video资源故障先本域锁存，再单bit双级同步回host，阻止新start并向既有事务传递abort。发布/提交结果仍必须真实返回，不能因隔离而伪造done；实际提交结果带回时保留未知资源。O_error及各原始原因来自owner冻结终态，隔离诊断可以独立后置。该组合层只增加3bit故障/同步寄存器和两域reset_sync（另4bit），无额外FIFO或像素RAM；内部原有FIFO/RAM仍占资源，约113 KiB超100 KiB预算问题尚未解决。

新增`tb_display_resource_pipeline.v/run_display_resource_pipeline.do`，真实slot_manager与整条内部显示资源链连接，准备15类场景：

- 首项完整640×480帧的307200像素、RGB/epoch/行连续性、真实锁和可靠租约安装，以及全部seed同沿移交。
- 增加第二源、提交目标单源后实际释放旧源、复用已释放的物理源装第三项；忙源身份冲突不改旧前台或锁。
- 真实候选读请求反压中取消、host停钟不能造完成；恢复后只回收新取得源；reader存储错误和错误首行同样保留旧前台。
- 缺失deadline或错deadline epoch不启动候选；audio ready和epoch分别核对，错epoch跨两个真实帧界仍不apply。
- video停钟不完成配置安装；旧scanout读请求实际在途时，即使新源已在帧界生效，也保留旧锁并等待真实任务/像素退休。
- 掉卡后普通槽拒绝及resident安全页；槽命令反压中的晚取消仍记录实际取放锁与发布事实。
- 在发布后、提交前故障注入当前host resident证明，验证本地拒绝且epoch0未启动远端，新增锁真实回收。
- video fault锁存/跨域阻止新任务：空闲时即使内部owner仍ready也不能接收；在途义务真实排空后仍保留未知锁及隔离，统一global reset恢复。

原有独立用例及其端点边界均保留。此新用例不再有理想prepare/retire/帧界计数夹具，但槽装载ALLOCATION/FINISH、逻辑memory同拍返回、绝对deadline及audio-ready仍为显式端点；不证明真实BMP装载/物理SDRAM契约、deadline换算器、真实音轨、独立效果算术、颜色处理、HDMI、物理CDC/资源/时序或板测。

当前Media68/Storage13/All87/P0六组，继续可等代码齐备后集中执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

只跑本项（仓库根目录）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_resource_pipeline.do'
$LASTEXITCODE
```

日志`src/sim/build/display_resource_pipeline/display_resource_pipeline.log`，批量summary在`src/sim/build/all/<批次>/summary.json`，沿用S_test_pass与退出码0/1。路径不同用批量脚本-VsimPath，不并发共享用例work/log目录。全部HDL编译/仿真、黄金模型、TD、综合、时序、物理CDC及上板均未执行，P0—P7验收不勾选。

可靠host绝对deadline换算及准备/扫描目标调度与资源链协调现已补齐代码（见后续两节），真实音频准备证明仍待连接；其后仍有帧时间线/ALERT与播放调度、五版式/多素材/颜色/OSD、六客户端存储仲裁和物理SDRAM真实契约、共享FAT namespace/context所有权、UI/UART/Flash/HDMI音频及最终top，完整播放器尚未完成。

## 可靠 host 绝对 deadline 换算（2026-10-24，代码与自检准备，未验证）

`display_deadline_cdc`（31端口）接受video域的kind/epoch/row/tag及目标video时间，通过真实请求FIFO在host接收沿取得host时间戳，再经回包FIFO返回。只有完整154位请求身份匹配的结果才能结束本次在途；错身份消费丢弃继续等待。请求154位、回包190位，默认各4项，仅一笔video事务在途。它提供时间换算组件，尚未替代prepare/scan目标调度或存储仲裁。

设回包被video实际接受时的本域时间为V、请求起点为Vo、目标为T，elapsed E=V−Vo、remaining R=T−V；默认频率比5，输出host绝对deadline为`host_stamp+R×5−16`（模2^32）。host_stamp在该video接收沿之前取得，因此保留一个过去的host锚点会让截止更早。为防旧锚点/下游反压耗尽实际余量，另输出video有效期`U=T−E−ceil((16+32+2)/5)`；只有当前video时间严格早于U且许可有效才可消费。计算使用宽乘法和半区间比较，参数范围限制单次时间差不超过半周。

这些保守界依赖声明的连续稳定整数频率比和待核对的phase margin，不能证明真实PLL时钟抖动/相位或硬件跨域时序。`I_enable`须由外层在时钟不可用期间撤销，并在video恢复首沿仍无效；不得裸接异步组合lock。时钟停止期间仅握手等待，不由超时制造done；enable撤销/abort在途后仍等真实回包。结果反压期间O_error/身份/deadline/U冻结，O_deadline_usable是实时消费资格；过期、取消、撤许可锁存，恢复许可或counter回绕不能复活同一终态。

`O_host_time`/`O_video_time`在各自域每拍递增并允许模回绕，必须与资源链统一global reset；后续存储仲裁须使用本模块的同一O_host_time，不能使用另一个起点或reset的自由计数器。后续缓存结果须保留U并持续检查有效期，完整匹配kind/epoch/row/tag；准备/扫描协调器还要在新配置/行目标变化时使旧缓存失效。本轮没有将既有整链测试的常数deadline宣称为真实换算结果。

error0成功、1身份非法、2过期/余量不足、3目标超范围、4取消/许可撤销、5host契约隔离、6序号耗尽/内部隔离。远端sequence从1递增不回绕，仅实际远端请求消耗；本地拒绝/开始即取消返回sequence0。host再次检查序号和身份；host/video隔离属于各自时钟域，不能裸跨。统一global reset清除所有在途和时间基准，不能用媒体flush单清一侧。

新增`tb_display_deadline_cdc.v/run_display_deadline_cdc.do`准备16类场景：

- 接受后改变输入，核对完整请求快照、host真实接收沿时间戳、结果载荷反压保持及实际host余量。
- 在目标video沿记录实际host计数，独立检查deadline足够早；不以重复RTL换算式作为唯一依据。
- 结果超过U撤usable但不改冻结error；过期后强制模拟counter回绕也不能复活。
- epoch0、row480、过去/零距离/半区间及超MAX目标本地拒绝，不发host采样或消耗远端sequence。
- 请求与回包分别反压、开始即取消、呈现请求后取消仍真实排空、host停钟、video停钟及撤时钟许可。
- 超时只锁存overdue，不替代真实回包；强制模拟时间回绕后仍返回过期。held成功后撤许可/晚abort均不可复活，error继续冻结。
- 逐一破坏sequence、origin、target、kind、epoch、row、tag七字段，经真实回包FIFO写端注入，均丢弃并继续等真实回包；不强制读valid破坏空队列指针。
- host序号/身份契约隔离、video序号耗尽、双域时间跨32位回绕、双停钟统一reset及恢复、disabled服务拒绝接收、真实回包已无新鲜余量时返回过期。

时钟许可/目标为显式测试端点，force用于故障、反压与回绕边界注入。请求/回包反压同时关闭对应真实FIFO写valid，避免仅阻止上层状态推进却产生重复写入。未连接deadline目标调度、实际资源链或存储仲裁；不证明物理CDC/时钟关系、真实SDRAM带宽、综合资源/时序或硬件通过。

默认新增FIFO裸载荷1376bit（172 B），本块状态/快照/计数/结果寄存550bit（68.75 B，不含FIFO控制/reset_sync）；实际RAM粒度/映射和既有约113 KiB超100 KiB预算仍待解决。当前Media68/Storage13/All87/P0六组，继续可留到代码齐备后集中执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独验证本项（仓库根目录）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_deadline_cdc.do'
$LASTEXITCODE
```

日志`src/sim/build/display_deadline_cdc/display_deadline_cdc.log`；全量summary在`src/sim/build/all/<批次>/summary.json`，退出码0/1与S_test_pass约定沿用。工具路径不同用批量-VsimPath，不并发共享用例目录。全部HDL/黄金模型/TD/综合/时序/物理CDC及板测未执行，P0—P7验收不勾选。目标帧/行选择、prepare/scan公平请求及缓存有效期已补齐代码并接资源链，见下节。

## 实际 deadline 调度与定时显示链（2026-10-24，代码与自检准备，未验证）

`display_deadline_scheduler`（30端口）以真实frame_start建立video时间锚点，组合真实deadline CDC；准备和扫描缺少缓存时轮转预约，先寄存不可变请求再呈现给桥，已呈现请求不因取消/目标改变而撤销。完整回包匹配且仍相关、可用时才装缓存，迟到结果真实排空。普通取消/过期不等于资源退休。

固定时序与当前实际scanout一致：800×525、首可见行35。准备选择有至少32000 video拍提前量的最近帧界，扫描行y的目标为`frame_origin+(35+y)×800`，对应选择整行缓存的line_start，提前量至少64拍。已错过的当前帧扫描行不改成下一帧deadline来掩盖迟到，scanout继续按原协议记录欠载/回退。准备缓存完整核对pending config/epoch/tag，扫描缓存核对active epoch/tag/y/frame_origin，均持续核对有效期。

准备deadline到期只撤消费资格，保留原计划目标帧；到达目标frame_start且候选实际就绪、音频等最终门控成立才apply。候选/音频迟到则保持旧前台，错过目标后重新选择并换算下一帧；已接受任务仍带原deadline，不被悄悄改写。过期和错过目标分别锁存，不能因32位时间回绕复活旧记录。

video_abort只清准备授权，旧前台扫描继续。clock_enable撤销清两类缓存/帧锚点，恢复后必须重新观察真实frame_start；错误间隔或缺失帧界会隔离，不能继续使用失效相位预测。时钟许可仍由外层可靠交付，默认5:1比和phase margin仍待TD/硬件验证。各域隔离按所属域同步，不能裸跨video忙位或多位时间。

`display_timed_pipeline`（128端口）已把上述调度器接到完整resource_pipeline的真实pending/active/prefetch/frame_start及prepare/scan deadline输入，计划目标帧还参与apply门控。后续存储仲裁使用其同一O_host_time。外层继续提供audio_ready/epoch和clock_enable，槽/逻辑memory成组接口保留；原外部deadline资源链及其用例不改写，新用例独立验证实际定时链。

新增两组：

| 用例 | 准备检查 | 边界 |
|---|---|---|
| display_deadline_scheduler | 12类：准备/扫描轮转、真实观察帧目标、行首目标、deadline到期仍在原帧apply、错过帧重新计划、同epoch完整config/tag改变、scan y/tag/epoch/帧身份、错过当前行不延期掩盖、首次必须观察frame、prepare取消隔离、时钟撤销恢复重锚、反压/host停钟取消真实排空、错误/缺失帧节奏隔离与reset、帧末不足提前量选再下一帧 | 真实timestamp桥与FIFO；参考raster与时钟许可是明确端点，无实际scanout |
| display_timed_pipeline | 6类：实际首行及scanout任务使用转换deadline、在选定目标帧apply、完整307200像素帧、双源增加/单源切换后真实释放锁、无时钟许可禁止候选/取消回收、真实memory反压取消、音频迟到跨多个真实帧重新计划、video停钟及恢复后真实重锚 | 完整真实owner/lease+commit CDC/candidate/arbiter/scanout/reader/RAM/slot_manager和deadline链；逻辑memory同拍返回、槽ALLOCATION/FINISH装载、clock_enable和audio_ready仍为端点 |

scheduler除内部bridge外新增956bit控制/缓存寄存（119.5 B，不含reset_sync）；timed组合层增加两位host同步及reset_sync，无额外像素RAM/FIFO。bridge原有双向FIFO和计数寄存、resource链RAM/FIFO继续占用资源，约113 KiB超100 KiB预算尚未解决，不以文本位数代替综合结果。

当前Media68/Storage13/All87/P0六组，用户可继续等代码齐备后集中执行：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单独先调度、再实际整链（仓库根目录）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_deadline_scheduler.do'
$LASTEXITCODE
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_timed_pipeline.do'
$LASTEXITCODE
```

日志分别`src/sim/build/display_deadline_scheduler/display_deadline_scheduler.log`和`src/sim/build/display_timed_pipeline/display_timed_pipeline.log`，全量summary仍在`src/sim/build/all/<批次>/summary.json`。保持S_test_pass与退出码0/1，工具路径不同用批量-VsimPath，不并发共享用例目录。所有HDL编译/仿真、黄金模型、TD、综合/时序/物理CDC及板测均未执行，P0—P7验收不勾选。

下一块补真实音频准备证明和显示提交授权，再推进帧时间线/ALERT与播放调度、五版式/多素材/颜色/OSD、六客户端存储仲裁/物理SDRAM契约、共享文件context/namespace、UI/UART/Flash/HDMI音频与最终top；当前不能宣布完整播放器已完成。

## 实际音频准备证明与显示绑定（2026-10-24，代码与自检准备，未验证）

`audio_prepare_guard`（51端口）与`wav_audio_prepared`（95端口）把真实双槽WAV事件、PCM保守读水位、预充及实际播放索引形成的证明接入显示提交。后者组合两份真实wav_audio_slot及audio_playback，作为wav_audio_player的替代包装；原模块/用例保持。不能在最终top同时实例化两套PCM链当成一个双槽。guard增加355bit（44.375 B）控制/身份寄存，不增加PCM RAM、事件FIFO或时钟；既有链/reset_sync另计，约113 KiB规划超100 KiB目标仍未解决，实际映射待综合。

完整身份为display epoch32/tag16与slot1/track epoch16/slot serial32；serial从1递增且跨局部flush保留，不能只比音轨epoch低8位或在回收后重用旧证明。只有真实header已经装载并被外部事件消费者接受后才建立身份。事件反压可能延后证明，但不会用文件done或decode写水位绕过读域事实。合法parser错误只撤对应轨资格，停止期间仍允许消费丢弃旧事件；非法事件顺序/完整身份/成功帧数或serial耗尽则全局隔离到统一reset。

bind请求全部属于audio/video域，valid/ready接受后完整快照直到unbind或实际显示生效确认。O_bind_error是接受后的单拍错误：0成功、1零display epoch/serial、2可靠pending epoch/tag不匹配、3真实音轨身份不匹配/未装载、4fresh索引/enable或reuse enable不合法。普通拒绝不占绑定、不隔离。fresh可在真实预充前绑定，只有实际PCM valid且预充，或保守读水位覆盖全部剩余短尾时才能给ready；零帧合法轨要求真实loaded/end，无须造PCM。reuse_active用于沿用当前已启用背景音乐，保留实际消费位置、不重新起播，不要求重新预充；这只证明同一活动轨身份，不保证此后无欠载。

pending身份改变、选中槽clear/stop/failed/loaded失效、fresh消费位置移动或reuse失去enabled会锁存O_binding_revoked；恢复旧输入不得复活旧绑定，必须显式unbind后重新核对。暂停/切轨忙仅临时撤资格，另一槽回收不清当前槽身份。普通撤销不产生文件退休或音轨播放完成，调度器必须处理实际占用。

连接方法（全部控制在同一实际25 MHz时钟与统一global reset）：

- wav_audio_prepared.I_audio_clk连接display_timed_pipeline.I_video_clk；decode仍是125 MHz，不得把decode输入裸跨到bind/pending口。
- 显示的O_pending_valid/epoch/tag直接接音频的I_pending_valid/epoch/tag。音频O_audio_ready/epoch直接接显示I_audio_ready/epoch；bind由后续可靠调度命令提供，不能把host多位总线直接接入。
- 音频I_display_audio_applied直接接`display.O_local_applied && display.O_video_active_config[52]`。这是实际生效后的寄存事实，不能自行猜测帧界，也不能额外延迟。guard在消费报告沿核对前一沿ready事实，输出O_audio_accepted及对应epoch/tag；无前一沿证明的生效报告隔离，不能把已生效事务伪装成取消。
- 音频准备契约隔离应进入video授权所有者的I_video_abort路径；普通撤销由调度器决定重绑定或取消。禁止用本地错误复位PLL/HDMI、采样发生器或强清在途I/O。

准备证明不触发play/fade，不表示音轨已经播放。实际执行仍须按05的图像转场中点、±500 ms偏移和样本边界安排；完整host绑定命令CDC、播放时间线/ALERT与文件namespace/context所有权尚未完成。

| 用例 | 已准备覆盖 | 实际边界 |
|---|---|---|
| audio_prepare_guard | 20类：无身份拒绝、完整epoch/初始serial、真实不足预充、完整短尾/零帧、事件反压、pending tag变化锁存、fresh位置移动/reuse持续、暂停恢复、另一槽回收隔离、同epoch回收新serial、abort、迟到解析错误、前一沿生效证明、双域分别停钟、serial耗尽、无证明生效隔离、选中槽回收、B槽/高位epoch、非法pending/索引拒绝、错身份终态隔离 | 真实WAV解析/PCM及事件FIFO/双槽元数据/guard/mix/回收；文件字节、无外部文件义务时的退休对端和独立显示报告为夹具，force/内部赋值只做故障注入 |
| display_audio_pipeline | 3类：无真实音轨及预充不足跨帧不apply，真实预充后计划帧apply/接受同一epoch/tag并输出完整307200像素；迟到WAV错误在事件反压下撤销真实显示资格并取消释放锁；真实完整短尾接实际定时显示完整帧 | 真实WAV准备+deadline调度/换算+host/video资源链/slot_manager/reader行RAM；逻辑memory同拍返回、图像槽装载、WAV字节、可靠bind命令、I/O退休和clock_enable为明确端点，没有执行音轨时间线或HDMI |

原来的资源/定时显示用例仍保留其独立audio-ready端点，不将新集成范围追溯到旧用例。此新测试不验证共享FAT namespace/context、TF实时供数、APT、±500 ms/转场中点、物理SDRAM/CDC/时序/资源、HDMI或板测；不能据此宣布完整播放器已完成。

后续集中运行（本轮未执行），先看复位/PLL及存储基础，再看已有WAV/定时显示链，最后看这两项。仓库根目录：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

当前Media68/Storage13/All87/P0六组。单独运行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_audio_prepare_guard.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_audio_pipeline.do'
```

日志为`src/sim/build/audio_prepare_guard/audio_prepare_guard.log`与`src/sim/build/display_audio_pipeline/display_audio_pipeline.log`，summary仍在`src/sim/build/all/<批次>/summary.json`；退出码0/1及S_test_pass约定不变，不并发共享work/log。所有HDL编译/仿真、黄金模型、TD、综合/时序/物理CDC及板测未执行，P0—P7验收不勾选。

下一块继续播放事件时间线与音画锚点调度，随后还有转场帧推进/ALERT、版式/颜色/OSD、共享文件所有权、六客户端存储仲裁/物理SDRAM、UI/UART/Flash、HDMI与最终top。

## 音画事件时间线（2026-10-24，代码与自检准备，未验证）

`av_event_timeline`（84端口）使用实际video/audio共同25 MHz时钟、来自deadline链的同一I_time，以及真实扫描frame_start和原始sample_tick。它接收已可靠交付的事务epoch32/tag16、effect、duration_frames1—60、偏移steps−50..50（每步10 ms）和音频动作/完整音轨身份。事务epoch严格递增，不替代下游每次实际显示提交的epoch；host命令需要另行可靠CDC，不能裸跨多位总线。

正常准备完成后，在420000拍帧栅格上选择起点S，中点h=ceil(N/2)、V=S+h×420000、A=V+steps×250000。起点和必要音频事件均至少留32000拍提前量，因此负偏移可能推迟视觉起点。k=0..N，共N+1个端点进度命令，覆盖N个帧间隔；17拍恢复除法求商余，再按帧累加，末帧精确65536。默认12/24/36/60帧为偶数；奇数N明确使用第一次progress≥0.5的帧作为中点。

每条视频命令携带transaction epoch/tag、effect、index、Q16 progress、目标video时间，并保持valid/载荷到ready。ready仅说明执行对端接收；唯一在途必须等完整身份的真实done（error/applied/time分别给出）才能退休。错身份消费丢弃继续等。真实apply时间须不早于目标且位于已观察帧栅格；先apply后资源退休失败仍保存已显示事实，不继续下一帧，无applied却报成功则隔离。执行迟到可重排尚未呈现的音频目标，已呈现/执行的音频不能假装重新对齐：原始O_planned_*保留，O_audio_target_time表示当前目标，实际锚点和有符号偏差分别记录。

音频动作0无新事件、1首次start A、2fade到指定槽、3沿用同一启用背景轨。fresh启动前要求完整slot/epoch16/serial32/实际index匹配，resources_ready/epoch/tag表示同域可靠准备许可；RUN以后资源所有者继续持有并通过I_abort撤销。真实WAV包装的O_audio_ready只在计划前作为该许可，起播后fresh证明正常撤销不应被错误地当作事务取消。沿用背景轨不重启、不清消费位置、不造新采样锚点。

play/fade命令在到达音频目标后呈现并保持到实际ready；命令接受时间和首个实际消费分别记录。audio_playback的O_consumed为前一消费沿寄存事实，因此在观察沿记录I_time−1及next_index−1；空轨使用命令后首个真实sample_tick作为零源锚点。fade要等真实fade_done/active_b，原始sample_tick仍持续，不因暂停/静音/时间线等待而停。内部锚点误差是逻辑采样与帧的关系，不代表扬声器/显示器端到端误差。

O_pause_allow在准备前与事务完成后允许实际音频暂停；转场执行中须用`pause_request && O_pause_allow`接既有播放pause输入，以免待执行命令被暂停请求阻塞。取消、音轨身份变化、时钟撤许可及帧节奏异常阻止新事件，已呈现valid不撤回；显示cancel保持到真实返回。若音频命令已经接受，取消须保持O_audio_stop_request直到真实停止ack，再等ack归零；不得将!enabled/FIFO空/固定计时当作读侧完整停止证明。此证明也不替代文件close、旧I/O排空或槽全部退休。没有超时假完成或强制局部flush。

本块增加893bit（111.625 B）控制/身份/时间寄存，无RAM/FIFO。帧栅格常数取余、乘法与初始化除法的实际映射/时序仍待综合；整体约113 KiB规划超100 KiB目标尚未解决。

| 用例 | 已准备覆盖 | 明确边界 |
|---|---|---|
| av_event_timeline | 26类：奇数进度/精确端点；默认锚点；正负500 ms；资源等待；视频OFFER反压取消；音频stop四相；错身份；显示迟到重排；音频OFFER稳定；转场后暂停许可；非法配置；显示拒绝；撤时钟许可；缺帧节奏；晚接受音频取消；同背景轨复用；未启动取消；事务epoch重复；32位时间回绕；停钟不造完成；已执行负偏移后视觉迟到保留真实误差；完整音轨epoch变化；非法apply时间；先apply后退休失败保留事实；无applied成功隔离。各终态反压时施加新abort核对结果冻结 | 使用真实video_timing/transition_plan；显示接收/执行/退休、音频消费/fade/stop是显式测试对端，17拍tick用于缩短协议场景，不代表真实48 kHz |
| av_timeline_wav | 5类：真实WAV首消费建立默认锚点；双槽真实9600样本fade输出后才完成；负500 ms音频实际先于画面；同背景轨沿用位置不重新起播；合法空WAV零源样本锚点 | 真实WAV解析、PCM及事件FIFO、prepared guard、playback/guard/mix/recycle与默认samp_tick，实际25 MHz采样；WAV字节与已无文件义务时I/O退休、可靠bind命令和显示执行/退休仍是明确端点 |

两组均未连接真实逐帧候选/scanout/reader资源适配器。原display_timed_pipeline一次性提交和display_audio_pipeline单配置整链保留；不能据此宣称跨多个实际显示提交的完整转场已经实现。该适配现由后述display_event_executor实现并准备av_timeline_display实际显示整链，保留transaction与底层epoch映射；这不改变上述两个音画用例的显示端点边界，也不证明真实AV合并已完成。其后还有ALERT/书签/停留时间/索引策略、版式/颜色/OSD、共享文件context、物理SDRAM/仲裁、UI/UART/Flash、HDMI及最终top。

用户后续集中运行（本轮未执行）：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

当前Media68/Storage13/All87/P0六组；先复位/PLL、存储基础与既有显示/WAV链，再看本块。单项：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_av_event_timeline.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_av_timeline_wav.do'
```

日志`src/sim/build/av_event_timeline/av_event_timeline.log`与`src/sim/build/av_timeline_wav/av_timeline_wav.log`；批量summary在`src/sim/build/all/<批次>/summary.json`。S_test_pass与退出码0/1保持，不并发共享work/log；含实际大量采样/帧周期，请等明确结果。HDL编译/仿真、黄金模型、TD、综合/时序/物理CDC及板测全部未运行，P0—P7验收不勾选。

## 指定目标帧的真实显示链

display_deadline_scheduler与display_timed_pipeline新增参数USE_TARGET，默认0保留原自动选择帧。设为1时，I_target_valid/epoch32/tag16/time32由可靠video域所有者提供，身份必须匹配实际pending epoch/tag，时间使用此链O_video_time及真实frame_start的帧栅格。新增四口已在原两份直接调用的自检中连接；其他自动模式调用也须将这些口显式接0。

指定帧距离当前时间足够且在换算器1048576拍范围内时按指定帧准备；更远先等待，缺失或错身份不启动prepare，原active扫描继续。目标已过去或不足32000拍准备量时，选择不早于原目标的下一可行帧，始终按420000拍整帧顺延。错栅格及半区间歧义隔离，不用自动目标掩盖无效许可。完整配置、底层epoch/tag及原始target共同参与缓存和在途相关性检查，已呈现转换请求仍等真实回包；过期deadline只撤消费资格，不推走已选apply帧。

目标侧带不是host跨域入口。后续执行适配器须明确映射时间线transaction epoch/tag/index到每次底层commit身份，可靠交付目标，保留原目标并在真实O_local_applied后记录实际apply时间，最终等待提交/旧资源退休结果。不能直接将timeline epoch当commit epoch，也不能把ready、目标沿或prepare成功当作done。本轮只完成该适配的指定帧基础，时间线和逐帧显示尚未组装；负偏移起播后的音频授权仍需协调。

| 用例 | 已准备覆盖 | 明确边界 |
|---|---|---|
| display_target_scheduler | 14类：缺失/错epoch/错tag仍服务旧scan、指定未来帧、远期等待换算范围、同epoch改目标缓存失效、撤销/恢复不复活、提前量不足、错过后整帧重试、abort隔离、停钟重锚、host停钟时改目标真实排空、错栅格、半区间歧义、过去目标及完整config变化、mod32回绕、valid为0时数据不授权 | 真实deadline CDC/FIFO和计数器，参考帧栅格/目标所有者为端点；回绕用例仅初始化实际计数器，不替代bridge结果 |
| display_target_pipeline | 6类：远期目标/完整身份等待、同源32768进度不重新取锁或发布且等待实际旧epoch退休、音频阻塞后恰一帧顺延、取消等真实reader/存储排空、撤目标跨原目标沿再恢复、video停钟恢复 | 复用tb_display_timed_pipeline的真实host owner/lease/commit/candidate/scanout/reader/slot_manager/行RAM，原自动模式六类保持；逻辑memory/图像装载/可靠clock_enable/音频许可为端点，无真实timeline映射、文件供数、物理SDRAM或HDMI |

scheduler自身控制/身份缓存寄存增加64bit至1020bit（127.5 B，不含bridge/reset），无额外像素RAM或FIFO；实际资源映射、常数取余的路径与整体超预算问题待综合确认。

先运行P0复位与PLL，再运行已有deadline/资源链和本块；也可后续一次串行收集当前Media68/Storage13/All87/P0六组：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单项命令（仓库根目录，本轮未执行）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_target_scheduler.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_target_pipeline.do'
```

日志分别为`src/sim/build/display_target_scheduler/display_target_scheduler.log`及`src/sim/build/display_target_pipeline/display_target_pipeline.log`；S_test_pass与退出码0/1保持，批量汇总仍为`build/all/<批次>/summary.json`。不要并发共享同一用例work/log。两组含真实帧等待，请等明确PASS/FAIL。只做静态文本审查，所有HDL/模型/编译/仿真/综合/TD/板测未执行，P0—P7验收不勾选，不提交或推送Git。

## 时间线逐帧执行与真实显示资源

新增display_event_executor（71口），通过真实async_fifo将时间线video域命令送至唯一host显示入口，再可靠返回实际事务终态。请求完整保存sequence32、timeline epoch32/tag16/index16、config247及target32；回包echo全部请求及底层commit epoch、六个原始错误、applied/retired/quarantined。错身份消费丢弃仍保留唯一在途；O_backend_error与O_error分别表示原始host错误和本适配器归类。取消不撤已呈现valid，不以固定等待/停钟/FIFO接受或frame_start制造完成。

接线要求：

- timeline.O_video_*接executor.I_event_*，cancel接O_video_cancel；executor.O_done_valid/epoch/tag/index/error/applied/apply_time接timeline.I_video_done_*，ready反向连接。完整实例如tb_av_timeline_display。
- executor.O_host_start_valid/config/tag/abort、O_host_done_ready与display_timed_pipeline对应host端口连接，输入其next_epoch和真实完整done；该host入口由executor独占。host多位载荷只经两向FIFO跨域。
- video_time/frame_start/active_valid、pending/active完整config/epoch/tag、local_applied及新增O_bank_busy4接executor对应输入。executor目标侧带接timed目标四口，video_abort接I_video_abort；时钟许可必须可靠同域，不能裸接PLL lock。
- timed设置USE_TARGET=1、PREPARE_IN_VBLANK=1。既有video/resource/timed组合层新增bank占用输出后现为84/131/133口；旧用例显式留空观察口，原功能测试保持。
- I_config由外层可靠video资源所有者提供，executor覆盖effect/progress、首行y=0、按实际空闲选择bank、首行tag={tag,tag}，保留来源lease和其他属性。当前七硬边效果第0输出行所需源行均为0，其他几何不能直接套用。
- 此路径要求config.audio_required=0；为1则拒绝，避免默默跳过fresh证明。音频许可由时间线计划前resources_ready/epoch/tag及持续资源所有者负责，起播后fresh正常撤销不重复门控每一显示帧。新显示整链audio_action=0，真实音频证明与负偏移所有者尚待组装。

已存在前台时，执行器由真实帧界建锚，在帧age=412032..415903且目标已到或剩余不超过8000拍时选择bank并发送host命令。这样不会在帧初选到最后一行一直持有的bank，也不提前占据扫描所需的双缓存之一。timed在消隐模式下只于最后8000拍允许prepare消费，目标是即将到来的帧；target/消隐模式且active存在时，转换最小提前量为2048拍，其余模式仍32000。窗口、125/25 MHz整数时钟关系和实际带宽/最坏延迟尚未验证；来不及则按真实帧顺延，未知义务保留，不能把该余量当硬件已达标。撤clock_enable后等新真实帧重建相位。

实际O_local_applied为前一video沿的寄存事实，executor校验完整active身份及底层epoch映射后记录video_time−1；时间必须不早于原目标且相差整数帧。host回包只有与本地事实一致才可成功。先apply后旧资源退休失败保留原实际画面和时间；缺失本地事实、无applied成功、非法或重复apply、映射变化隔离，隔离保持video_abort直到全局reset。done反压期间结果冻结。done消费后还等inflight/cancel两边归零及底层实际ready再允许下一命令，避免上一请求的取消串入下一事务。

| 用例 | 已准备覆盖 | 明确边界 |
|---|---|---|
| display_event_executor | 18类：bank等待本地取消；真实FIFO/底层不同epoch及time−1；连续帧身份/空闲bank与host OFFER冻结；已呈现取消及四相归零停钟；video停钟等真实回包；错误host身份；完整pending许可；错apply身份；已apply退休失败保留事实/原始错误；无applied成功；缺少本地apply；重复apply；撤clock_enable；序号耗尽；audio_required拒绝；late cancel；pending epoch变化；host停止不假退休。各终态反压再施加abort检查冻结 | 使用真实375/434bit双向FIFO；实际显示prepare/apply/退休是明确协议对端，不用该单测声称显示资源整链完成 |
| av_timeline_display | 4类：七效果分别0/32768/65536，共21次真实连续progress提交，逐可见像素用独立红/蓝参考核对fade/slide/push/wipe/blinds/mosaic/zoom，实际中点与末帧时间、完整timeline与commit映射、原两源锁/发布仅取得一次、全部真实退休及零欠载；取消等真实候选存储退休并释放新锁；late cancel保留真实active锁和生效事实；host停钟恢复 | 真实av_event_timeline、executor、host owner/lease/commit CDC、deadline、candidate/arbiter/scanout/reader/slot_manager/行RAM。图像槽装载和立即应答的逻辑memory为夹具，可靠clock_enable和resources_ready为端点；audio_action=0，无真实音频/文件/物理SDRAM/HDMI/top结论 |

新增FIFO载荷3236bit（404.5 B），executor控制/快照/身份/帧锚寄存1771bit（221.375 B），另计FIFO控制与同步读寄存。无额外像素RAM；实际映射/常数运算路径、整体约113 KiB超100 KiB规划仍待解决。

用户后续先P0、存储和已有显示/音频基础，再看本块；全部代码准备后可集中串行执行当前Media68/Storage13/All87/P0六组（本轮未执行）：

```powershell
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

单项（仓库根目录）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_display_event_executor.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_av_timeline_display.do'
```

日志为`src/sim/build/display_event_executor/display_event_executor.log`及`src/sim/build/av_timeline_display/av_timeline_display.log`，批量汇总`build/all/<批次>/summary.json`，退出码0/1；不要并发共享work/log。真实多帧和逐像素用例较长，请等明确结果。只执行文本审查；HDL编译/仿真/黄金模型/TD/综合/时序/物理CDC及上板均未运行，P0—P7不勾选，不提交或推送Git。整段转场所有者现见下一节，完整播放资源调度及双轨许可/供数仍须继续；ALERT、书签、版式/颜色/OSD、共享文件context、物理存储仲裁、UI/UART/Flash、HDMI/top仍未完成。

## 整段转场与最终单源资源收束（2026-10-24，准备，未执行）

`playback_transition_owner`内部只实例化一份真实`av_event_timeline`，外接`display_event_executor`与`display_timed_pipeline`。从start冻结双图和音轨身份，到全部动画帧实际执行，再追加index=ffff的完整单源提交；等待applied、retired、active完整配置与实际单源租约安装后，才报告settled并降低图片hold。正常结束保留to；取消/普通失败按最后实际applied进度小于32768选from，否则选to。取消可以error=3但settled=1，表示画面及图片锁已安全收束，原转场仍被取消。

不能用“最后一帧到了”、ready握手、commit旧epoch retired或冻结config回接来代替真实旧图释放。dwell_start来自最后动画帧实际生效时间，settle_time另计。无法安全收束时保留双源请求，阻止普通start；显式recover只能选择旧冻结配置之一，等再次真实单源提交及租约证明。永久隔离须共同global reset。图片hold仅为同域保留请求，音轨hold不是文件/读侧退休证明，实际跨域所有者仍待连接。

| 用例 | 已准备覆盖 | 明确边界 |
|---|---|---|
| playback_transition_owner | 16类：冻结与正常3帧+1收束、反向from、计划前pause、等图取消、首帧后/中点后取消、retired后仍等真实lease与错源proof、撤to/from proof、显式恢复、fresh接受后ready撤销、fade终态、bind失败、音频取消等stop ack归零、收束后late abort、非法audio_required、owner停钟及终态反压冻结 | 真实owner和内部timeline；executor、audio guard/play/fade/消费/stop为显式协议端点；音频tick加速，不验证真实WAV或样本节奏 |
| playback_transition_display | 7类：连续正反转场共8提交，保留源复用与旧A/旧B实际READ_RELEASE、单源/双源及from方向逐可见像素比较、候选真实memory在途取消、首帧后取消选from、中点后取消选to、缺图显式恢复、host停钟、单源OFFER后late abort；终态反压核对实际slot_readers/host-owned/video lease | 真实owner内部timeline、executor双FIFO、timed/deadline、host/lease/commit/candidate/arbiter/scanout/reader/slot_manager/行RAM；audio_action=0，图像可用快照/槽装载/即时逻辑memory/时钟许可仍为夹具，没有真实AV/文件/物理SDRAM/HDMI/top结论 |

本层1026bit寄存，内部timeline另计893bit，无新增RAM/FIFO。只按声明清点，未验证TD映射或时序；整机约113 KiB超100 KiB规划仍未解决。

用户集中验证时先看P0/存储及已有显示、音频基础结果，再执行本块。仓库根目录单项运行：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playback_transition_owner.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playback_transition_display.do'
```

也可以用`& ./src/sim/run_p0.ps1 -Suite All`串行收集全部85组（Media68/Storage13/P0六组），再检查`$LASTEXITCODE`及`src/sim/build/all/<批次>/summary.json`。两个新增日志分别为`build/playback_transition_owner/playback_transition_owner.log`与`build/playback_transition_display/playback_transition_display.log`。退出码0/1，不能并发使用相同work/log。真实显示逐像素测试较长，应等待明确终态。

本轮仅静态文本审查，未编译、仿真、执行黄金/行为模型、综合、TD或上板；P0—P7不勾选。下一步接实际图片装载/保留快照与音轨stop/双轨供数所有者，再接完整播放索引/停留/ALERT/书签；共享文件namespace、版式/颜色/OSD/软边、存储仲裁/物理SDRAM、UI/UART/Flash、APT及HDMI/top仍未完成。

## 图片保留CDC与共享槽命令（2026-10-24，准备，未执行）

`image_reservation_cdc`接收video域显式update(epoch/tag/reservation)，通过真实双向FIFO在host安装pin，再发布同身份图片可用proof。host核对实际槽的READY/READ_LOCK及slot/token/generation/resident/stale；媒体短暂失效撤proof但不擅自撤pin。新update接受后旧proof立即失效，即使输入切回旧值也不借用正在释放的pin。新请求失败保留旧host pin，必须显式重试/可靠撤销，不能把失败done当资源已空。

`fb_slot_arbiter`连接三client的115bit命令与97bit结果，接受后保持到真实manager结果由该client消费。FINISH、READ_RELEASE、READ_ACQUIRE分别要求真实producer/memory退休、reader退休、帧许可；不满足时可服务其他已具备条件的client。pin集合阻止ALLOC/EVICT，已接受及同拍mutation让新pin等待实际槽操作退休。所有生产者的ALLOC/EVICT必须经过该入口，不能旁路，否则保留契约不成立。

| 用例 | 已准备覆盖 | 明确边界 |
|---|---|---|
| image_reservation_cdc | 18类：完整身份pin、READY→READ_LOCK、缺帧许可/缺reader退休不接收、pin期间ALLOC/EVICT拒绝、可靠缩减、禁止原地换身份、范围/未完成槽/零epoch、已接受mutation与pin竞争、两域分别停钟、短暂媒体失效及真实旧read lock退休、resident、done反压期间proof撤销、sequence耗尽、三client同时请求、未退休FINISH不阻塞其他client、错结果隔离、输入切回旧值不复活proof、video enable撤销不放pin | 真实保留双FIFO、三client仲裁与slot_manager；producer/reader退休和帧许可是显式协议端点，无真实扫描/物理CDC结论 |
| image_load_reservation | 5类：真实BMP loader/parser/geometry/scaler/rotate/writer/slot_manager接保留链，LOADING不能产生proof，实际file.done/close/最后write_done均退休后才发布，独立完整307200像素与旋转核对；pin期间维护EVICT及实际新loader ALLOC拒绝且无新文件/写入；READ_LOCK不撤可用；撤pin不释放实际reader，release后才能EVICT；无局部reset重装token递增及新proof身份；瞬时媒体失效保留pin/读锁后实际退休 | FAT文件协议、逻辑memory数组和reader命令/退休为端点；没有真实FAT/SD/物理SDRAM、scanout或完整AV合并结论 |

保留通道33口、1288bit控制/记录寄存；仲裁器19口、221bit顺序寄存；两向FIFO裸载荷1772bit，另计FIFO控制/读寄存/reset。无像素RAM增加，TD实际资源/时序及约113 KiB超100 KiB问题未解决。

接线：arbiter.O_mutating_slots→pins.I_mutating_slots，pins.O_host_pinned_slots→arbiter.I_pinned_slots，真实slot_manager状态只接pins的host端；O_images给同域转场资源判断。loader为client0、显示host owner为client1、维护为client2。**外层仍须自动选槽、取得文件namespace/context租约，并把转场hold增减转换成显式update，可靠确认后再启动转场**；本块没有完成该外层调度。

仓库根目录运行（本轮未执行）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_reservation_cdc.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_load_reservation.do'
# 全量串行执行当前87组：
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

新增日志分别`src/sim/build/image_reservation_cdc/image_reservation_cdc.log`和`src/sim/build/image_load_reservation/image_load_reservation.log`，All汇总`build/all/<批次>/summary.json`。退出码0/1，不并发共享work/log。先看P0/存储/已有BMP与显示基础，再定位本块失败。仅做文本审查，未运行HDL/黄金行为模型/仿真/TD/综合/上板，P0—P7继续不勾选。

下一步接自动选槽、转场保留请求适配与共享文件许可，再补音轨停止/双轨实时供数、完整索引/停留/ALERT/书签；版式/颜色/OSD/软边、六客户端存储仲裁/物理SDRAM、UI/UART/Flash、APT、HDMI及最终top仍未完成。

## 转场与图片保留组合层（2026-10-24，准备，未执行）

`playback_image_pipeline`以一份真实`playback_transition_owner`、一份`image_reservation_cdc`及新的`playback_image_ctrl`，替换原来外层手动的保留/转场握手。start冻结全部命令，先可靠安装双图pin并等实际图片proof，再呈现owner.start；owner完成真实动画和最终单源显示/读锁退休后，保持其done并可靠缩减host pin，最后才报告外部done。转场前取消也先收完已呈现pin事务，再可靠恢复原pin集合。slot/token/generation/resident完整关联，不裸跨host状态。

缩减/恢复失败不会重跑画面或猜资源已空：O_pin_error保留原始错误，O_sync_required阻止下一转场，I_retry_pin_valid/O_retry_pin_ready仅重试冻结pin目标；结果带O_retry_result。已启动的转场错误另报O_transition_error，dwell_start保留最后动画实际时间，settle_time保留单源实际时间。O_transition_started=0的本次结果将音画时间等事实清0，避免误报上次转场。永久隔离仍需共同global reset，不单侧flush。

| 用例 | 已准备覆盖 | 明确边界 |
|---|---|---|
| playback_image_ctrl | 18类：命令快照、pin接受不能代替确认、pin确认但图片未就绪、已呈现pin取消保持、恢复原空pin/单源pin、已呈现owner.start取消保持、实际转场结果等待、final pin阻塞时owner.done不消费、初次pin失败、最终缩减/取消恢复失败及显式retry、错pin结果身份、成功与installed tuple矛盾隔离、非法hold、失败保留双源和显式owner recovery、撤时钟许可、非法配置、最终同步晚abort；结果反压冻结 | controller真实，pin与transition结果是显式协议端点；不将该单测当资源链或硬件验证 |
| playback_image_display | 6类：真实pipeline内部ctrl/pin双FIFO/owner/timeline接executor、timed/deadline、host/lease/commit/candidate/scanout/reader/slot_manager及三client槽arbiter；连续正反8提交和独立单/双源逐像素比较；pin中EVICT拒绝、真实旧锁释放及host pin缩减后旧槽可EVICT；转场启动前取消恢复原空pin；真实candidate memory在途取消；中点后取消选to；final pin时停host保持真实owner.done；final pin OFFER后late abort | 图片可用proof为真实CDC输出；槽装载/即时逻辑memory/时钟许可为夹具，audio_action=0；不证明真实文件供数、真实音频/完整AV、物理SDRAM或HDMI |

控制器57口、新增871bit寄存，无新FIFO/像素RAM；组合层140口，不复制原owner/pin/timeline状态或存储。原约113 KiB超100 KiB规划问题与实际TD资源/时序仍未解决。

接线：pipeline取代原transition owner实例，event端连接原executor，active/lease取同video域真实timed输出；host状态接真实slot_manager，O_host_pinned_slots与arbiter.I_pinned_slots相连，arbiter.O_mutating_slots回接I_mutating_slots。音频接口仍接同一25 MHz实际音轨guard/player，不能同时并接另一个转场所有者。图片装载/空闲槽选择、FAT namespace/context独占许可和音轨stop/双轨实时供数仍须后续上层处理。

仓库根目录命令（本轮未执行）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playback_image_ctrl.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_playback_image_display.do'
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

当前Media68/Storage13/All87/P0六组。新增日志`src/sim/build/playback_image_ctrl/playback_image_ctrl.log`及`build/playback_image_display/playback_image_display.log`；汇总`build/all/<批次>/summary.json`，退出码0/1，不并发共享work/log。先看P0/存储、BMP/显示/保留基础，再定位组合层。仅运行纯文本检查，HDL编译/仿真/黄金行为模型/综合/TD/物理CDC/上板均未执行，P0—P7不勾选。

下一步补自动选槽与装载协调、共享文件namespace/context许可，随后接音轨stop/双轨实时供数和完整播放索引/停留/ALERT/书签；版式/颜色/OSD/软边、六客户端存储仲裁/物理SDRAM、UI/UART/Flash、APT、HDMI及最终top仍未完成。

## 自动选槽与装载协调（2026-10-24，准备，未执行）

`image_load_pipeline`组合一份真实`image_load_owner`和`bmp_frame_loader`，上层显式请求包含素材身份、矩形、旋转、缩放、背景色与文件参数。先查完整缓存，次选FREE/ERROR，最后对可回收READY发真实EVICT；只用0..4，5保留安全页。全忙等待，已呈现维护/装载命令不因取消撤回。缓存复用READ_LOCK不释放其实际读者，不重新读文件。

接线：原loader命令为统一arbiter client0，显示为client1，O_evict_command115及返回97为client2；外部其他维护者须另仲裁。arbiter.I_pinned_slots接真实image_reservation_cdc.O_host_pinned_slots OR owner.O_staged_slots，owner.I_pinned_slots只观察真实host pin，I_mutating_slots观察arbiter实际输出。I_host_reservation接host端真实138bit保留状态。文件O_lease_request/active仍来自真实loader，I_lease_grant必须来自实际namespace/context所有者；本测试grant是明确端点，尚未实现共享文件许可。

结果error0且stage有效才是可交付候选。O_lease_token为最终候选身份，O_loader_lease_token为真实装载过程身份；O_published保留真实发布事实，不单独表示本次成功。done消费后stage继续保护并阻止下一start；上层发可靠保留update，看到host reservation持有完整slot/token/generation后，以同身份stage_release(discard=0)交接。discard=1只撤临时候选保护，不清真实pin/读锁。媒体变化仍保留stage等明确丢弃；矛盾终态也保护所选槽，quarantine保持到共同global reset，不得局部flush释放未知占用。O_frozen_request为接受时的223bit快照。

| 用例 | 已准备内容 | 端点边界 |
|---|---|---|
| image_load_owner | 19类：请求冻结、成功结果前瞻stage、结果反压与消费后保持、错stage/pin身份拒绝、实际pin交接、READ_LOCK精确缓存、几何/缩放/背景色变化、外部重装token、FREE/ERROR选择及pin/mutation排除、READY先真实EVICT、reader/resident排除、全忙不碰slot5、EVICT/start反压取消保持、错loader/EVICT结果不清债务、原始slot/loader错误、未发布成功/未知占用/变token隔离、媒体变化/非法矩形/late abort | 槽和loader是显式协议端点；不证明真实文件/写入/CDC或硬件行为 |
| image_load_pipeline | 7类：真实BMP/parser/geometry/scaler/rotate/writer/slot/仲裁/pin CDC；槽0/1/2实际写范围和整帧独立像素核对；最后写响应/file close延迟不提前发布；video停钟仍保护stage；结果前后EVICT拒绝；真实pin交接；READ_LOCK缓存不重读；改变旋转选择新槽保留旧显示；最后真实reader释放后旧槽可EVICT；全忙等待/取消；掉卡保留候选；已接受EVICT取消等真实结果 | 文件协议、带反压逻辑write_done和帧数组、显示reader退休是夹具；未连接真实FAT/SD/SPI、scanout/转场、音频或物理SDRAM，不产生完整AV/带宽/时序证据 |

新增owner66口、pipeline182口，控制/缓存元数据1375bit（其中完整缓存995bit），wrapper无新增状态/像素RAM/FIFO。不重复计算原loader/slot/pin组件；约113 KiB超100 KiB整机预算问题及实际TD资源/时序仍待解决。

仓库根目录命令（本轮未执行）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_load_owner.do'
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_image_load_pipeline.do'
& ./src/sim/run_p0.ps1 -Suite All
$LASTEXITCODE
```

当前Media68/Storage13/All87/P0六组。新增日志在`src/sim/build/image_load_owner/image_load_owner.log`和`build/image_load_pipeline/image_load_pipeline.log`，All汇总`build/all/<批次>/summary.json`。退出码0/1，不并发共享work/log。先运行P0与已有复位/存储/BMP/槽/保留基础，再定位本块；只做纯文本审查，所有HDL编译/仿真/黄金行为模型/综合/TD/物理CDC/板测均未执行，P0—P7继续不勾选。

共享文件namespace/三context许可、真实TF/BMP/双WAV连接及自动挂载/扫描现已编写，入口见[STORAGE.md](STORAGE.md)“共享文件服务与自动启动”。当前Media68/Storage14/All88/P0六组，均未运行。接下来按主链补自动索引到装载/转场调度、音轨stop所有者及整机控制；完整停留/暂停/ALERT/书签、版式/颜色/OSD/软边、六客户端存储仲裁/物理SDRAM、UI/UART/Flash、APT、HDMI与最终top仍待完成。

2026-10-24更新（代码已编写，未验证）：`player_av_core`接通真实媒体、双槽停止回收、图片保留与转场显示；`player_autoplay`继续接入单项索引复制、自动BMP/WAV装载、命令邮箱、NEXT/PREV/GOTO合并与video域停留/暂停计时。该组合仍需要真实逻辑存储端点和最终HDMI/板级top，并不包含ALERT/书签、完整背景音乐循环、扩展版式/OSD/UI/Flash/APT。

集中验证时先跑已有P0/Storage基础，再执行 `& ./src/sim/run_p0.ps1 -Suite Media`，或单组 `& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_player_av_core.do'`。本组先准备展开两个真实组合顶层，再顺序运行音频双槽回收、命令邮箱/待接受音频取消、真实索引存储到单项复制三个自检；显示执行、轨身份、文件退休/音频idle仍有明确夹具，不是整机TF/BMP/WAV/HDMI联合行为或物理SDRAM测试。日志 `src/sim/build/player_av_core/player_av_core.log`，退出码0/1。当前Media69/Storage14/All89/P0六组；全部HDL/仿真/综合/TD/板测未执行。
