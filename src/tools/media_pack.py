"""RLE1 images and DEM1 flash-region packs, using only the Python standard library.

    python src/tools/media_pack.py rle input.bmp output.rle
    python src/tools/media_pack.py pack manifest.json output.dem
    python src/tools/media_pack.py inspect output.dem

Manifest: {"entries": [{"type": "image", "id": 0, "path": "slide.rle"},
                       {"type": "audio", "id": 0, "path": "track.wav"}]}
Paths resolve relative to the manifest. Output is the demo region only: flash
base 0x100000, capacity 7 MiB. It never contains settings, fonts or boot firmware.
"""
import argparse
import io
import json
from pathlib import Path
import struct
import wave
import zlib

DEMO_BYTES = 7 * 1024 * 1024
MAX_ENTRIES = 128


def crc32(data):
    return zlib.crc32(data) & 0xffffffff


def write_new(path, payload, force):
    # Exclusive creation is also enforced when an output path races with a user save.
    with Path(path).open('wb' if force else 'xb') as stream:
        stream.write(payload)


def bmp_pixels(data):
    if len(data) < 54 or data[:2] != b'BM':
        raise ValueError('Expected a Windows BMP with a 40-byte DIB header')
    size, offset = struct.unpack_from('<I4xI', data, 2)
    dib, width, signed_height, planes, bpp, compression = struct.unpack_from('<IiiHHI', data, 14)
    height = abs(signed_height)
    if dib != 40 or planes != 1 or bpp not in (24, 32) or compression:
        raise ValueError('Only uncompressed 24/32-bit BMP with BITMAPINFOHEADER is supported')
    if not 1 <= width <= 1920 or not 1 <= height <= 1080:
        raise ValueError('Image dimensions must be 1..1920 by 1..1080')
    stride = ((width * (bpp // 8) + 3) // 4) * 4
    image_bytes = struct.unpack_from('<I', data, 34)[0]
    if size != len(data) or offset < 54 or offset + height * stride > size:
        raise ValueError('BMP file size, pixel offset or payload is inconsistent')
    if image_bytes not in (0, stride * height):
        raise ValueError('BMP biSizeImage does not match the pixel layout')
    pixels = []
    for y in range(height):
        row = y if signed_height < 0 else height - 1 - y
        for x in range(width):
            position = offset + row * stride + x * (bpp // 8)
            blue, green, red = data[position:position + 3]
            # Match the BMP hardware decoder: BMP alpha is treated as opaque.
            pixels.append((red << 24) | (green << 16) | (blue << 8) | 255)
    return width, height, pixels


def encode_rle(data):
    width, height, pixels = bmp_pixels(data)
    payload = bytearray()
    color, run = pixels[0], 0
    for pixel in pixels:
        if pixel != color or run == 65535:
            payload += struct.pack('<HI', run, color)
            color, run = pixel, 0
        run += 1
    payload += struct.pack('<HI', run, color)
    return struct.pack('<4sHHII', b'RLE1', width, height, len(payload), crc32(payload)) + payload


def inspect_rle(data):
    if len(data) < 22:
        raise ValueError('Truncated RLE1 image')
    magic, width, height, size, checksum = struct.unpack_from('<4sHHII', data)
    if magic != b'RLE1' or not 1 <= width <= 1920 or not 1 <= height <= 1080:
        raise ValueError('Invalid RLE1 signature/dimensions')
    if size != len(data) - 16 or size % 6 or crc32(data[16:]) != checksum:
        raise ValueError('RLE1 payload length or CRC mismatch')
    pixels = 0
    for position in range(16, len(data), 6):
        run = struct.unpack_from('<H', data, position)[0]
        pixels += run
        if not run or pixels > width * height:
            raise ValueError('RLE1 zero run or pixel overflow')
    if pixels != width * height:
        raise ValueError('RLE1 pixel count does not cover the canvas')
    return {'format': 'RLE1', 'width': width, 'height': height,
            'bytes': len(data), 'runs': size // 6, 'crc32': f'{checksum:08x}'}


def inspect_wav(data):
    # Check the physical RIFF boundary in addition to wave's format handling.
    if len(data) < 12 or data[:4] != b'RIFF' or data[8:12] != b'WAVE':
        raise ValueError('Expected RIFF/WAVE audio')
    if struct.unpack_from('<I', data, 4)[0] + 8 != len(data):
        raise ValueError('RIFF size does not match the audio file')
    with wave.open(io.BytesIO(data), 'rb') as source:
        if (source.getnchannels(), source.getframerate(), source.getsampwidth(), source.getcomptype()) != (2, 48000, 2, 'NONE'):
            raise ValueError('Demo audio must be stereo PCM16 at 48000 Hz')
        frames = source.getnframes()
        if frames < 1 or len(source.readframes(frames)) != frames * 4:
            raise ValueError('Empty or truncated WAV sample payload')
    return {'format': 'WAV', 'frames': frames, 'bytes': len(data)}


def inspect_demo(data):
    if not 16 <= len(data) <= DEMO_BYTES:
        raise ValueError('DEM1 size is outside its 7 MiB flash region')
    magic, version, count, table_bytes, checksum = struct.unpack_from('<4sHHII', data)
    if magic != b'DEM1' or version != 1 or not 1 <= count <= MAX_ENTRIES or table_bytes != count * 20:
        raise ValueError('Invalid DEM1 signature/version/table shape')
    end = 16 + table_bytes
    if end > len(data) or crc32(data[16:end]) != checksum:
        raise ValueError('DEM1 table is truncated or has a bad CRC')
    entries, seen, ranges, images = [], set(), [], set()
    for i in range(count):
        kind, identity, offset, size, checksum, reserved = struct.unpack_from('<HHIIII', data, 16 + i * 20)
        if kind not in (1, 2) or (kind, identity) in seen or reserved:
            raise ValueError(f'DEM1 entry {i}: invalid type, duplicate identity or nonzero reserved')
        seen.add((kind, identity))
        if offset < end or not size or offset + size > len(data) or offset + size > DEMO_BYTES:
            raise ValueError(f'DEM1 entry {i}: offset/size is outside the payload region')
        ranges.append((offset, offset + size))
        content = data[offset:offset + size]
        if crc32(content) != checksum:
            raise ValueError(f'DEM1 entry {i}: file CRC mismatch')
        if kind == 1:
            detail = inspect_rle(content)
            images.add(identity)
        else:
            detail = inspect_wav(content)
        entries.append({'type': 'image' if kind == 1 else 'audio', 'id': identity,
                        'offset': offset, 'size': size, **detail})
    ranges.sort()
    if any(ranges[i][1] > ranges[i + 1][0] for i in range(len(ranges) - 1)):
        raise ValueError('DEM1 entries overlap')
    if not images or any(e['id'] not in images for e in entries if e['type'] == 'audio'):
        raise ValueError('DEM1 requires an image and an image for every associated audio id')
    return {'format': 'DEM1', 'flash_base': '0x100000', 'bytes': len(data),
            'image_count': len(images), 'entries': entries}


def pack_demo(manifest):
    document = json.loads(manifest.read_text(encoding='utf-8-sig'))
    entries = document['entries']
    if not isinstance(entries, list) or not 1 <= len(entries) <= MAX_ENTRIES:
        raise ValueError('Manifest requires 1..128 entries')
    offset = 16 + len(entries) * 20
    table, payload = bytearray(), bytearray()
    for entry in entries:
        kind = {'image': 1, 'audio': 2}[entry['type']]
        identity = entry['id']
        if not isinstance(identity, int) or isinstance(identity, bool) or not 0 <= identity <= 65535:
            raise ValueError('Each id must be an integer in 0..65535')
        content = (manifest.parent / entry['path']).read_bytes()
        if offset + len(content) > DEMO_BYTES:
            raise ValueError('Pack exceeds the 7 MiB demo region')
        table += struct.pack('<HHIIII', kind, identity, offset, len(content), crc32(content), 0)
        payload += content
        offset += len(content)
    result = struct.pack('<4sHHII', b'DEM1', 1, len(entries), len(table), crc32(table)) + table + payload
    inspect_demo(result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest='command', required=True)
    for name in ('rle', 'pack'):
        command = commands.add_parser(name)
        command.add_argument('source', type=Path)
        command.add_argument('target', type=Path)
        command.add_argument('--force', action='store_true', help='overwrite the specified output file')
        if name == 'rle':
            command.add_argument('--logo', action='store_true', help='also require the image to fit the 64 KiB logo region')
    inspect = commands.add_parser('inspect')
    inspect.add_argument('source', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'rle':
            result = encode_rle(args.source.read_bytes())
            if args.logo and len(result) > 65536:
                raise ValueError('RLE1 exceeds the 64 KiB logo region; simplify the artwork')
            detail = inspect_rle(result)
            write_new(args.target, result, args.force)
        elif args.command == 'pack':
            result = pack_demo(args.source)
            detail = inspect_demo(result)
            write_new(args.target, result, args.force)
        else:
            result = args.source.read_bytes()
            detail = inspect_rle(result) if result[:4] == b'RLE1' else inspect_demo(result)
        print(json.dumps(detail, ensure_ascii=False, indent=2))
    except (OSError, ValueError, KeyError, TypeError, struct.error, wave.Error, EOFError) as error:
        parser.exit(1, f'error: {error}\n')


if __name__ == '__main__':
    main()
