# 图片与背景音乐素材

本目录保存当前作品上板演示使用的6张图片和20秒背景音乐，与技术文档中的实物演示使用同一套素材。

## 复制到TF卡

将TF卡准备为FAT32文件系统，把本目录的6个BMP文件和 `SHORT20.WAV` 直接复制到卡的根目录：

```text
TF卡根目录/
├── PIC010.BMP
├── PIC011.BMP
├── PIC015.BMP
├── PIC026.BMP
├── PIC028.BMP
├── PIC029.BMP
└── SHORT20.WAV
```

播放器自动扫描图片并循环播放背景音乐。图片按FAT目录项的出现顺序播放，文件名中的数字不决定播放顺序。使用本套背景音乐时，根目录保留 `SHORT20.WAV` 这一个WAV即可。

可直接复制上述7个文件；本说明保留在项目内。完整按键、旋转和串口操作见[使用说明](../docs/使用说明.md)。

## 素材规格

| 素材 | 格式 |
|---|---|
| 6张BMP图片 | 640×480、24-bit RGB、未压缩，每张921654字节 |
| SHORT20.WAV | 20秒、48 kHz、双声道、16-bit整数PCM，3840044字节 |

## 图片来源

图片通过Lorem Picsum选取自Unsplash，经过居中裁剪、缩放并转换为640×480 BMP。作者及原作品链接如下，使用许可见[Unsplash License](https://unsplash.com/license)。

| 文件 | 摄影作者 | 原作品 |
|---|---|---|
| PIC010.BMP | Paul Jarvis | [6J--NXulQCs](https://unsplash.com/photos/6J--NXulQCs) |
| PIC011.BMP | Paul Jarvis | [Cm7oKel-X2Q](https://unsplash.com/photos/Cm7oKel-X2Q) |
| PIC015.BMP | Paul Jarvis | [NYDo21ssGao](https://unsplash.com/photos/NYDo21ssGao) |
| PIC026.BMP | Paul Jarvis | [gkT4FfgHO5o](https://unsplash.com/photos/gkT4FfgHO5o) |
| PIC028.BMP | Jerry Adney | [_WiFMBRT7Aw](https://unsplash.com/photos/_WiFMBRT7Aw) |
| PIC029.BMP | Go Wild | [V0yAek6BgGk](https://unsplash.com/photos/V0yAek6BgGk) |

## 背景音乐署名

`SHORT20.WAV` 使用 Kevin MacLeod 创作的 **Meditation Impromptu 01**，来源为 [Incompetech](https://incompetech.com/)，采用 [Creative Commons Attribution 4.0 International（CC BY 4.0）](https://creativecommons.org/licenses/by/4.0/) 授权。

本项目截取原曲前20秒，转换为48 kHz、双声道PCM16 WAV，用于循环背景音乐演示。随项目分发该音频时保留上述作者、作品名称、来源、授权链接及处理说明。
