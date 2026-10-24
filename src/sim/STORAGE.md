# 存储模块集中验证

状态：SPI/SD/CSD、扇区队列、CDC、FAT32、共享媒体文件服务及自动挂载/扫描的RTL已编写。`media_io`已连接真实TF链、索引扫描、BMP帧装载和双WAV文件/播放槽；物理SDRAM与整机播放顶层仍待实现。均未编译、仿真、综合或板测，不宣称TF卡或文件播放已经可用。

当前入口包含P0六组、Media68组、Storage14组、All88组。下文旧批次数量为历史记录，以此处为准。

仓库根目录执行以下之一：

```powershell
& ./src/sim/run_storage.ps1
& ./src/sim/run_p0.ps1 -Suite All
```

前者十三组存储测试，后者八十五组（P0六组、Media六十六组、Storage十三组）。可传`-VsimPath '实际vsim.exe路径'`；日志在`src/sim/build/storage/<批次>/`或`all/<批次>/`，包括summary.json及原始日志。不要同时运行两个批次，独立脚本会共用每用例的work和transcript目录。

| 用例 | 准备检查 | 边界 |
|---|---|---|
| spi_byte_master | mode0、MSB顺序、4/6/10/250完整周期除数、传输中修改除数不生效、非法除数反压、RX保持、中途reset | 不验证IO时序或实际卡采样边沿 |
| sd_spi_phy | 80个高CS启动时钟、R1/R2/R3/R7打包、响应反压、CMD9的16 B/CRC/中途取消/参数拒绝、CMD17、CMD18双块、CRC、CMD12 stuff及忙等待、取消/反压超时先排完块、错误令牌/令牌超时/响应超时/忙超时、非法参数拒绝 | 卡行为为显式测试假设，没有实卡兼容性结论 |
| sd_csd_decode | CSD v1读块长度换算、v2最小/普通/2^32扇区上限、CCS不匹配、非法结构/结束位/读块长度 | 仅字段解码，不代表实际卡容量已读取验证 |
| sd_sector_reader | 三种卡类型、HCS/CCS/CMD16/CMD9/块与字节寻址、容量快照/卡尾合法读取/越界拒绝、ACMD41累计预算、四项队列与块边界优先仲裁、逐字节身份和标记、CRC前不交付、终态反压、活动/排队/等待输出时取消、取消完成前拒绝同身份复用、坏CRC清退队列、空闲探测掉卡与插回、旧请求不重放 | 缩短时间与初始化除数；另有125/100及25/100 MHz真实sd_storage集成；不覆盖默认1秒/2秒物理时间、实卡容量报告或文件系统 |

| sector_cdc_bridge | 两种时钟比、取消与请求同队列、旧字节/终态/取消确认顺序、最小FIFO及寄存缓冲满反压稳定、媒体短暂失效拒绝旧排队请求、host停钟屏障、33-bit容量首次提交/换卡/停钟后更换、共享reset清除旧返回、urgent独立电平同步 | 显式协议端点，本组为桥独立端点测试，真实reader集成由sd_sector_reader组另测；未接FAT32，不证明物理CDC |
| fat32_mount | 真实sector_port及volume包装，裸卷/MBR第二主分区、活动FAT、簇大小移位和整除、坏签名/BPB/版本/簇数/FAT长度/根簇/卡容量/分区边界、完整标签/字节数/last、底层错误、结果反压、掉卡后排完旧扇区再重挂载 | 独立host扇区模型，未通过SPI链路挂载实际卡；不含目录/路径/文件 |
| fat32_chain_walk | 真实sector_port、跨三FAT扇区碎片链、同扇区缓存、FAT高4位忽略、提前EOC、空闲/保留/坏簇/越界、自环/两类多簇环、预算、地址溢出、底层错误、结果反压、取消/失效等待实际有序确认后再复用 | 独立host扇区模型；单次索引定位，不替代文件大小、三个打开上下文或完整文件内容校验 |
| fat32_file_reader | 三文件真实reader/chain_walk/sector_port包装，独立请求排队、碎片/偏移/短尾/EOF、urgent在扇区边界生效、检查点/向后seek、空文件/未打开/非法描述符/越界、提前EOC/坏链/跨扇区环/底层CRC错、取消等物理ack及文件终态、同epoch复用门控、掉卡清退及重装、close | host扇区模型，单个125 MHz域，并非真实SD SPI/路径打开/WAV端到端；不宣称吞吐、资源或所有环均在短读前检测 |
| fat32_dir_parser | 8.3/NT小写、12/26/32/64 B ASCII LFN、65 B拒绝、非ASCII回退、checksum/type/顺序/终止填充错误、删除/卷标/点目录、非法短名、反压、残缺目录/end错误/cancel和再启动 | 原始目录字节激励；不含存储、目录链或按路径匹配 |
| fat32_core | 真实mount/path/directory/parser/walker/file_reader/arbiter/sector_port，按路径打开并装载、三context读取/空文件/seek/EOF、边读边查询/枚举共享缓冲、根/子目录及LFN名称/别名、open同拍优先、两阶段累计预算及warning、entry/name/done反压、定位/扫描取消及正常stop、文件取消不被枚举阻塞、打开结果保留槽、占用/未找到/目录拒绝、装载后取消回滚、物理与文件取消退休、unmount/短暂掉卡/挂载失败、旧终态保持、排空后原子换geometry/generation、底层错误及恢复 | host扇区端点，未经过真实SD SPI/CDC，未连接WAV/BMP、索引或整机；无吞吐/资源/时序证据 |
| fat32_path_lookup | 真实lookup/directory/parser/walker、根目录/多级/重复及尾随分隔符、大小写/LFN/8.3、64 B/非ASCII回退warning、未找到/非目录、累计预算、非法路径/last、取消/短暂掉卡/底层错误、joined结果反压 | checked-sector模型，不含描述符load、真实sector_port/SPI或整机 |
| fat32_sector_arbiter | 真实arbiter+sector_port、urgent/priority/同分轮转、三个私有RAM完整逐字节核对、结果持有时他客户端继续、新请求门控、未提交/物理/复制阶段取消、真实done及延迟ack、短暂失效不重放、已发布终态保持及恢复 | host扇区端点；未同时连接真实mount/path/file_reader，无在播吞吐、最大阻塞、RAM映射或TD时序结论 |
| fat32_directory | 真实dir_stream/parser/chain_walk，跨扇区且跨非连续簇的LFN、每簇2扇区、00提前停止/EOC、预算/环/非法首簇、正常stop/取消/媒体失效等待在途退休、底层错误及恢复 | checked-sector模型，不含真实sector_port/SPI；文件reader组另测真实sector_port；不含路径与在播共享仲裁 |

下述SPI和reader接线全部100 MHz同域。`spi_byte_master`不管理CS，`sd_spi_phy`持有完整卡事务；`sd_sector_reader`向PHY发命令，扇区先进入512×8同步RAM，CRC及物理终态成功后才输出。sector_reader使用CMD17每次服务一块，1—128块请求可以暂停并在下一块之前重新仲裁；PHY多块能力另行自检。持续≥2.5 MB/s和最大音频阻塞仍只是待测目标。

所有byte/done/cancel_done均须valid/ready握手。done带context/tag/error；取消握手只接收请求，cancel_done须等待物理事务和对应请求终态都排空。取消允许撤销等待字节，已发布终态保持不变。文件层只有汇总其所有扇区与跨域返回后，才可向音轨回收控制器确认retired。不能直接把单次sector cancel_ready接音轨retired。

默认400 kHz初始化、25 MHz工作；ACMD41预算1秒、失败后2秒重试、500 ms空闲CMD13探测。card_present仅等于通信确认的card_ready，没有物理检测引脚。CRC或读错误会撤销ready，当前请求返回原错、其他旧请求返回11；上层必须处理媒体失效，不能把旧文件继续读到新卡。默认数据输出反压100 ms超时返回8，已完成卡事务不因此强制重初始化。

错误0成功，1响应超时，2令牌超时，3数据错误令牌，4CRC错，5协议错，6取消，7参数错，8反压超时，9忙超时，10初始化预算到期，11媒体失效。除数和时间参数合法性见设计02；驱动需保持100 MHz工作，复位/掉卡不复位HDMI。

`sector_cdc_bridge`连接host与sd两域：request/cancel同一命令FIFO、byte/done/cancel_done同一返回FIFO，各有一项寄存缓冲保证满反压期间载荷稳定。取消确认只能排在旧字节和终态之后，host须继续接收/丢弃旧字节，不能停接字节后只等取消完成。同身份在终态和取消完成前不得复用。桥不产生文件级epoch，也不替代文件事务汇总。

sd侧ready下降时，桥持续请求host停止新请求，拒绝所有尚未交给reader的旧请求，再确认命令队列已排空，完成停止撤销握手后才开放。停止/开放分开保持，host停钟或快速掉卡/插回均不能跳过屏障；已交reader的请求仍由reader清退并返回终态。桥的host card_ready表示提交许可。媒体失效后，host应撤销尚未接受的旧文件请求；已进入返回FIFO的旧数据继续带原身份交付，由文件层丢弃。

`sd_storage`现已连接桥和真实reader/PHY，sd_sector_reader组还准备两种异频host集成场景，复用引脚级卡模型覆盖读/取消/媒体恢复。取消时，host持续丢弃原身份的旧返回，直到有序确认；不会通过停接旧字节跳过排空。host card_ready是桥提交许可，O_sd_high_capacity/O_sd_card_error属于sd域诊断，需同步快照后供host使用。

`sd_storage.O_capacity_sectors[32:0]`现在提供host域容量快照，仅card_ready有效时可用。reader在CMD9的16 B和CRC通过且CSD/CCS一致后发布ready；桥在停止握手后锁存容量，并在开放往返握手后将容量与host ready一起提交。不能直接把SD域诊断逐位同步当作此快照。2^32扇区是允许的上限，不能缩窄成32位。

挂载接法：同一host时钟/全局复位连接`sd_storage`与`fat32_volume`，card_ready/capacity输入包装，包装的request/byte/done/cancel/cancel_done端口按同名对应连接（I/O方向相反）。start为valid/ready命令，result同样握手，成功参数在mounted有效期内使用。当前没有将该包装加入板级顶层；挂载期独占存储请求口。`fat32_chain_walk`则使用共享的checked read/result/buffer接口，外部所有者仲裁后才能复用同一sector_port，缓存不得跨缓冲所有者切换保留。

`fat32_files`连接三描述符reader与独占sector_port，所有`sd_`前缀事务端口属于host时钟；load仅装载描述符，不能当作路径open。输入read的offset/length可裁剪到文件尾，字节带context/epoch/offset/last，独立done给出实际消费计数；仅在done成功时确认完整读取。read cancel的ack须晚于底层实际排空及文件done接收，旧字节/终态应持续接收；close不能越过该context的pending/terminal。失去mounted会清除所有打开身份，旧请求不会在新介质重放。共享全局reset仍是唯一可以直接丢弃在途状态的操作。

`fat32_directory`不使用文件reader的三个描述符，连接独立dir_stream和parser、共用它独占的checked端口。parser见00后请求stream停止，等二者终态汇总才done；取消/错误时撤销局部entry/name，等checked事务退休。目录扫描不能与文件reader直接并接SD口；新增arbiter按下述接线隔离缓冲，完整core接法见后文，后台在播扫描的带宽/最大阻塞也没有验证。目录warning为单拍诊断，路径模块输出整次查询累计OR，后续索引器继续汇总。


本轮新增组件接线：同一个host时钟和全局reset下，`fat32_mount`的checked端口接`fat32_sector_arbiter`客户端0，`fat32_path_lookup`接客户端1，`fat32_file_reader`的sector端口接客户端2；打包总线低切片为客户端0、高切片为客户端2。挂载/路径context可使用0，文件context按reader实际输出；client编号不是文件context。路径/挂载的priority与urgent由上层配置；文件priority用reader输出，文件客户端urgent可由三文件urgent归并，但不能因此承诺实时延迟。

arbiter的port端口接一个真实`fat32_sector_port`的start/result/buffer接口，再由该sector_port完整request/byte/done/cancel/cancel_done连接`sd_storage`host口；card_ready取host原子许可。mount无abort输出，其arbiter abort接0，掉卡由双方card_ready处理；path/read abort接各自真实输出。各客户端只读自己的同步私有缓冲，不再直读共用sector_port RAM。已有`fat32_volume`/`fat32_files`含自己的独占sector_port，不适合同时套进这条共享链。

`fat32_path_lookup`先接受start(length,budget)，再接收指定长度字节及精确last；路径最多64 B，大小写不敏感，从根开始，`/`重复合并，尾随`/`要求目录，拒绝`.`/`..`及非法ASCII。取消后发送者撤销本帧剩余字节，继续等result。result保持到握手，找到条目先停目录并等待真正退休；预算是整条路径累计数据扇区数。独立path结果须交file_reader的load并等待load_result，不能直接视为已打开文件；fat32_core现已封装此流程。挂载更新和已发布旧代际结果由core协调，不能把新卡参数写进仍在使用旧geometry的客户端。

共享缓冲增加三份512×8 RAM，每次成功扇区复制约514拍；复制期间不抢占。某客户端不接result不会堵住其他客户端，但它必须在自己下一条请求前消费完其缓冲。取消/失效可使复制不完整，error非0时禁止使用该缓冲；已发布终态保持，调用方仍须核对介质代际。持续urgent可能饿死后台查询，尚无最大阻塞保证。两组新增测试均只准备未执行。


统一接入推荐使用`fat32_core`，不要再给它额外套volume/files/arbiter/sector_port；它已包含这些基础模块的共享结构。`I_clk/I_reset`、host `I_card_ready/I_capacity_sectors`来自`sd_storage`；完整`sd_` request/byte/done/cancel/cancel_done端口逐项对应连接，仍在host域。`I_unmount`接host域媒体失效/软卸载请求，禁止用它复位SD CDC或HDMI。

控制顺序：等待card_ready→mount valid/ready→消费mount_result；error=0且mounted后发送open(context,tag,path_length,budget)，随后发送精确长度的path/data/last；等待open_result成功并消费后才可read。context0/1/2建议图片/audio_A/audio_B；目标必须先close，不能覆盖已打开槽。占用返回16、目录不能作为普通文件打开返回17；无媒体/非法context/占用等前置拒绝不会收path，应在看到open_result时撤销尚未发送的帧。取消打开用open_cancel，取消读取用context/epoch握手，两者不能互换。

每次接受mount，32-bit generation加一，包括失败尝试；mounted只在成功后有效。open_result及read byte/done/cancel_done均携带所对应代次。上层在mounted下降时撤回尚未握手的旧open/read/enum命令，继续接收旧字节/终态/取消确认并按代次丢弃；generation不替代排空。close及取消确认未完成时不得复用同context。core不会自动挂载/重试，目录枚举接法见下文。

mount请求等待时不接受新open/read，旧数据和完成/取消继续服务。只有quiescent、card_ready及无unmount时mount_ready才有效；未消费的open/mount/enum_done/读done/cancel_done都会阻止换卷，不能停接终态再等重新挂载。I_unmount或短暂掉卡使mounted持续0，ready恢复不能自动复用旧文件。挂载成功才更新geometry；已发布旧结果保持原generation及载荷。当前仅准备自检，尚无SPI端到端或真实卡验证。

目录枚举接法：成功挂载后发送`enum valid/ready(tag,path_length,sector_budget)`及独立`enum_path`字节流（精确last），例如`/`或`/PLAY/IMG`。依次握手`enum_entry`元数据，再接收`enum_name`至last；`enum_tag/enum_generation`覆盖本次所有输出。最后消费保持的`enum_done`及error/storage_error/sectors/warning。条目仅作候选，done成功且介质代次仍有效才可交索引提交。前置无媒体/已取消直接done且不收路径，发送者撤回本帧；非法帧返回13、未找到14、目标非目录15。路径和最终扫描共用累计目录数据扇区预算，FAT查询另计；预算不足返回10，warning为两阶段累计OR。

open与enum一次只接受一个，同拍open优先；等待枚举结果时也不能开始新open/enum，但三个文件context仍可读/close/cancel。两种操作都共用真实path_lookup，枚举定位结束并等joined结果后才让真实directory接管客户端1，沿用三份私有RAM及唯一sector_port；不需要额外SD请求口或文件描述符。新增实例的资源映射和在播延迟尚未验证。

提前停止用`enum_stop`：定位期间仍须发完路径，成功定位后可不扫描；扫描期允许丢弃未完整名称并等底层退休，正常返回0。取消用`enum_cancel`，可中断路径接收或扫描，返回8；掉卡/卸载返回1。取消或stop后丢弃不完整名称，仍须消费enum_done；已发布done不被后续取消/失效改写。未消费done阻止重新挂载。与文件cancel/context/epoch接口分开使用。

单独运行（仓库根目录）：

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_fat32_core.do'
```

沿用`build/fat32_core/fat32_core.log`、`S_test_pass`及退出码0/1；集中脚本包含十三组Storage/八十五组All，枚举场景直接加入core用例。测试只连接host扇区端点，不证明真实SPI/CDC、SD卡或吞吐。本次未执行该命令。

播放列表的真实FAT32文件所有者及其与parser/store的集成自检已准备，列入Media入口（见MEDIA.md）：`run_playlist_file_fat32.do`使用同一真实core，只有SD扇区返回为夹具，不另建volume/files包装。目录候选及主目录到根目录回退的真实core集成另见`run_directory_index_fat32.do`及MEDIA.md，两种模式串行复用唯一索引store。单次扫描包装media_index_scan及run_media_index_scan_fat32.do已准备列表转目录自动启动；外部仍需提供真实租约/媒体管理，素材校验与WAV/BMP文件连接尚未完成。真实卡容量/CSD兼容性与读取性能仍待验证。TD须确认512×8 RAM映射、SPI输出时序、MISO输入约束和跨域同步链/Gray偏斜，以及容量bundled-data握手路径的稳定窗口/约束；不要把测试模型或testbench加入TD工程。FAT32只读，不修复介质。


单BMP到完整离屏帧的`bmp_frame_loader`与控制器已准备（未验证），真实文件桥、变换、逻辑writer及slot_manager的集成测试见`run_bmp_frame_loader.do`及MEDIA.md。此测试使用文件协议端点；不能代替`bmp_file_fat32/fat32_core`或实际SD验证。外部仍必须提供独占namespace/context租约和槽命令仲裁，以及具有真实逐写退休依据的SDRAM适配，不能直接并接扫描/BMP/两音轨的文件命令。当前All八十五组，Storage仍十三组，所有代码均待用户实际运行验证。


`fb_line_reader/fb_reader`逻辑行读取代码和两组自检已准备（未验证），见MEDIA.md与02 §5.10.1。mem读命令是`O_mem_valid/I_mem_ready`，真实读返回是`I_mem_valid/O_mem_ready`，tag/token/generation按客户端独立路由；不能接write_done、伪造固定读延迟或忽略刷新。两路独立端点供后续截止时间仲裁器接入，当前没有新增物理SDRAM适配或完整提交CDC。默认Media68/All87组，Storage仍十三组；资源、时序和真实卡/显示并发性能均待后续验证。


帧配置提交CDC与真实首行门控`frame_commit_cdc/display_commit`及两组自检已准备（未验证），见MEDIA.md/02 §5.11.1。host必须先持真实READ_LOCK，video匹配同epoch完整首行/必要音频才可帧界apply；done等真实候选/旧配置资源退休。所有者不能整源flush仍共享新前台的reader，须按配置身份回收旧bank/排空外部流水后才释放引用。本CDC不自动获取/释放槽或解决owner单槽限制，不证明物理SDRAM/仲裁带宽。Media68/All87，Storage仍十三组，所有代码待后续实际验证。


七转场坐标与RGB混合两组运算自检已准备，Media68/All87，Storage仍十三组；见MEDIA.md。整行查询返回安全源行集合（mosaic中间阈值允许多读），zoom使用Q16映射；测试没有真实reader/SDRAM或预取调度，不证明带宽或行截止时间。所有HDL验证留用户后续集中执行。


真实reader扫描集成自检`scanout_engine`已准备（未验证），Media68/All87、Storage十三组，见MEDIA.md。包括整行欠载回退、真实行错误、bank/外部流水退休与停钟；deadline换算、租约/候选所有者、真实SDRAM及仲裁仍未接入，无带宽/时序结论。

该scanout用例现扩展真实source_guard接入，用实际按源引用证明等待任务、bank release及像素排空后才允许整源reader退休；含单源释放跨帧反压、另一源继续扫描、保留配置阻塞及帧界竞争。无新增批次；无外部候选/完整资源所有者，未运行，详见MEDIA.md末节。

Media新增display_candidate_ctrl用例，使用真实reader准备指定首行、取消后排空及精确bank回收；持续读取旧前台验证隔离的激励已准备，接管/授权及存储仍为逻辑端点。Media68/All87/Storage13，无物理SDRAM、仲裁或完整显示提交验证结果，见MEDIA.md候选首行所有者节。

Media另新增display_reader_arbiter用例，真实candidate/arbiter/reader/CDC/RAM连接，准备四bank在途身份/归属、等待真实行终态及reader实际release接受。扫描器和存储为逻辑端点，无物理SDRAM适配、存储端六客户端仲裁或带宽验证；此为video域reader客户端端口仲裁，详见MEDIA.md末节。


物理双源读锁控制`display_lease_ctrl`与真实槽管理器集成自检已准备（未验证），Media68/All87，Storage十三组。控制真实取得/退休后释放及旧generation保留，不访问物理SDRAM；idle/帧许可/完整reader退休跨域桥和共享命令仲裁仍待接入，见02 §3.1.2及MEDIA.md。


显示源跨域保留/退休桥`display_source_guard`与真实lease/slot/reader集成自检已准备（未验证），Media68/All87、Storage十三组；见MEDIA.md。reader真实barrier与外部owner/scanout证明共同确认退休，归零等readerack0，不用固定拍数；配置引用汇总/候选所有者和物理SDRAM验证仍未完成。

显示video域配置引用现由`display_video_pipeline`汇总真实candidate/arbiter/scanout：新增Media用例实际连接配置CDC与双源reader，准备同拍bank预约、原子安装/移交及完整旧epoch回收。当前Media68/All87、Storage十三组；测试边界见MEDIA.md末节。完整host槽锁/授权、六客户端存储仲裁和物理SDRAM接收/返回/刷新/写退休契约仍未完成，不把video端口仲裁或逻辑响应夹具当作物理存储证据。

2026-10-24新增display_host_owner的Media用例，真实lease/guard/slot/commit CDC/reader连接，准备先取锁并等待video租约安装确认、提交后真实释放移除源、失败只回收新锁与旧reader在途保护。发布安装及video prepare/retire是显式夹具，可靠发布CDC与显示全链尚待接通；槽共享命令仲裁及物理SDRAM仍未实现。当前Media68/All87/Storage13，所有HDL验证均未运行，操作见MEDIA.md末节。

2026-10-24新增可靠租约发布CDC及真实host链集成两组Media测试，当前Media68/Storage13/All87/P0六组。完整video租约通过双向FIFO安装/确认，取放锁期间保持reserve；错误不丢旧身份。prepare/retire/像素引用及逻辑memory仍为端点，未连接实际scanout或物理SDRAM，全部HDL未运行；命令及边界见MEDIA.md末节。

2026-10-24新增display_resource_pipeline实际host/video资源整链用例，Media68/Storage13/All87/P0六组。真实槽锁、租约安装和候选/scanout/reader退休已互连；不把FIFO空或最后像素当作锁可释放。槽装载、deadline、音频和逻辑memory仍为夹具，真实物理SDRAM/共享仲裁未实现，所有HDL未运行；见MEDIA.md末节。

2026-10-24新增display_deadline_cdc用例，Media68/Storage13/All87/P0六组。真实host接收沿时间戳经可靠FIFO回传，保守deadline及有效期给后续仲裁使用，后续仲裁须使用同一host计数基准。目标/时钟许可仍为夹具，prepare/scan协调与物理存储未接入，所有HDL未运行；见MEDIA.md末节。

2026-10-24新增deadline调度/实际定时资源链两组，Media68/Storage13/All87/P0六组。真实任务携带转换host deadline，后续仲裁使用同一O_host_time；原外部deadline用例仍为其独立边界，真实物理SDRAM/仲裁/写退休未完成。全部HDL未运行，见MEDIA.md末节。

2026-10-24新增实际WAV准备证明与定时显示链连接两组Media自检，当前Media68/Storage13/All87/P0六组。音轨serial跨本槽flush保持，真实PCM读域水位决定预充/短尾资格；不把文件done当播放准备。文件字节、bind命令与I/O退休仍为端点，未连接完整共享文件上下文或物理存储；全部HDL未运行，见MEDIA.md末节。

2026-10-24新增AV事件时间线两组Media自检，当前Media68/Storage13/All87/P0六组。显示帧命令携带完整事务身份及目标时间，只有实际apply回报才推进；此轮执行对端尚未连接真实逐帧候选/reader/SDRAM适配，不将它当物理存储退休依据。音频真实WAV测试不替代共享FAT namespace/context与TF公平供数。全部HDL未运行，见MEDIA.md末节。

2026-10-24补充自动选槽/装载所有者与真实BMP-slot-pin整链两组，当前Media68/Storage13/All87/P0六组。临时候选stage与真实pin按位OR保护统一槽仲裁，只有实际host pin完整身份确认或明确discard才撤stage；文件namespace/context独占许可仍由上层提供。全部HDL未执行，运行入口和端点边界见[MEDIA.md](MEDIA.md)末节，验收保持未勾选。
## 共享文件服务与自动启动（2026-10-24，未运行）

`media_file_mux`提供图片、音轨A/B、扫描四调用方与三个context的真实租约/namespace仲裁。三份95bit读终态寄存允许一个客户端反压时，其他context继续返回；close仅在真实core握手后回ready。`media_file_service`组合唯一core；`media_storage`进一步连接真实SD CDC/reader/SPI；`media_io`接入现有真实扫描/BMP/WAV管线及`media_session_ctrl`。

media_io的host125 MHz、SD100 MHz、video/audio25 MHz与共同基础设施reset必须实际连接。I_session_enable置1后自动挂载/扫描；I_session_reload与I_session_rescan为host域单拍请求。扫描配置仍从I_scan_*输入，成功committed且非空后O_session_allow_start才允许图片/音轨start握手。reload/掉卡先abort和排空，音轨每槽提交一次真实recycle；stage、索引快照及显示读锁仍须其实际所有者释放。volume/pause/播放/绑定命令属video域，文件与recycle命令属host域；O_storage_sd_high_capacity/card_error为原生SD域诊断。

```powershell
& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_media_file_service.do'
& ./src/sim/run_storage.ps1
$LASTEXITCODE
```

新增一个集中用例：先编译并展开真实media_io层次，再运行真实mux/core三文件字节/身份、独立done反压、context0图片/扫描互斥、扫描与音轨读取并行、迟到cancel、挂载租约屏障、掉卡退休和重新挂载；同一用例中的session控制器使用显式握手端点检查失败重试、扫描、重扫、重载等待和禁用时的真实终态排空。SD扇区是夹具，没有模拟真实TF电气协议；media_io仅作层次展开，未执行完整BMP/WAV/视频联合行为。日志为build/media_file_service/media_file_service.log，退出码0/1；All汇总沿用build/all/<批次>/summary.json。先运行已有P0/复位和存储基础，再运行本组；TD/物理频率/CDC/资源/带宽仍须后续验证。


原生SDRAM后端（2026-10-24，代码与用例准备，未运行）：新增 `native_sdram_ctrl/frame_mem_arbiter/player_frame_memory/player_sdram_phy`，`player_memory_top`已经将两路真实显示读、图片写接入该后端。原加密参考工程保持原样；原生控制器直接执行JEDEC命令并按其时序退休，不能据此宣称参考IP写完成已获证实。

后续集中验证单组命令：`& 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe' -c -do 'do src/sim/run_frame_memory.do'`；也已加入 `& ./src/sim/run_p0.ps1 -Suite Storage` 和All。日志 `src/sim/build/frame_memory/frame_memory.log`，退出码0/1。准备的测试通过原始SDRAM引脚连接独立命令夹具，核对初始化/四bank行切换/实际DQ读回/字节掩码/六client返回身份/EDF/结果反压期间刷新，以及移相器件时钟停止后不伪造写退休、不重放命令。夹具仅由本脚本加载，不替代EG_PHY原语库或器件时序模型，未覆盖最终TF到HDMI整机行为。全部编译/仿真/综合/TD/板测均未执行；当前P0六组、Media69、Storage15、All90。

硬件仍须核对2M×32几何、MRS=0x230、125MHz两相时钟、tAC/tOH及命令/DQ建立保持、刷新周期、队列映射资源和实际双源带宽。975拍刷新、CAS3及各时序参数是源码中的待验证配置；现有约113KiB预算问题仍未闭合。结果容量预留及源码位宽检查不能证明资源/带宽达标。
