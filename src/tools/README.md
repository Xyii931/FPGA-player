# 素材工具

本目录的三个 Python 脚本使用标准库，负责准备播放器素材。下列命令从仓库根目录执行；输入文件由使用者提供，输出文件的父目录需已存在。工具已编写，当前尚未执行素材转换或与硬件做一致性验证。

## BMP 转 RLE1

```powershell
python src/tools/media_pack.py rle input.bmp slide.rle
python src/tools/media_pack.py inspect slide.rle
```

转换器接受40字节DIB头、未压缩的24/32位BMP，最大1920×1080，BMP透明度按不透明处理。RLE1携带尺寸、像素游程与CRC。TF播放列表可以显式引用RLE文件；自动目录扫描当前仍以BMP为候选。

可加 `--logo` 检查输出是否适合64 KiB Logo预留区，但当前没有独立开机Logo加载显示流程。

## DEM1 Flash 演示包

准备 `manifest.json`，路径相对于该JSON文件：

```json
{
  "entries": [
    {"type": "image", "id": 0, "path": "slide.rle"},
    {"type": "audio", "id": 0, "path": "track.wav"}
  ]
}
```

```powershell
python src/tools/media_pack.py pack manifest.json demo.dem
python src/tools/media_pack.py inspect demo.dem
```

演示图片使用RLE1，关联音频使用48 kHz双声道PCM16 WAV；相同id配对，图片可不配音频。工具限制最多128个条目并检查格式、容量、重复标识、范围和CRC；板级播放器另有最多64张图片的限制，准备manifest时需遵守，工具当前不单独检查图片数量上限。播放器在实际读取并验证包后建立内部只读目录，复用原有文件和播放链路。

工具的 `inspect` 验证包结构、CRC和素材格式；它不检查板级资源、时序或实际播放结果，输出成功后仍需经过播放器端及硬件验证。

`demo.dem` **只包含W25Q64从 `0x100000` 开始、容量7 MiB的演示区域**，不是整片Flash镜像，也不是FPGA bitstream。本工具不连接烧录器、不写Flash。无卡演示需要另行把有效包写入指定区域。

## WAV 与 APT0

```powershell
python src/tools/apt0.py encode input.wav output.apt
python src/tools/apt0.py decode output.apt decoded.wav
```

输入/输出WAV为48 kHz、双声道、有符号PCM16。APT0为本项目的有损ADPCM容器，与Microsoft IMA ADPCM WAVE不同；解码结果不能按原始WAV逐样本相等来验收。文件头和分块契约见 [设计02](../../docs/design/02-模块接口规格.md)。

## HZK16 字库区域

```powershell
python src/tools/font_pack.py HZK16 font-region.bin
```

输入必须为完整94×94区位槽，共282752字节，每字32字节；16行、每行2字节、最高位在左。工具保留固定槽位并清零未分配GB2312槽，输出供W25Q64的 `0x010000` 字库区域使用。字形数据由使用者提供；输出不包含设置区或演示区。

三个工具默认拒绝覆盖已有输出，确需覆盖时添加 `--force`。各区域地址以 [设计02](../../docs/design/02-模块接口规格.md) 为统一依据，写入Flash前核对目标芯片和起始地址。
