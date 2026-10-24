#!/usr/bin/env python3
"""Pack a 94x94 HZK16 font region for W25Q64 address 0x010000.

  python src/tools/font_pack.py HZK16 font-region.bin

Each input slot is 32 bytes: 16 rows, two bytes per row, MSB at left.
Output retains all 8836 slots; unassigned GB2312 slots are zeroed.
Program this region at 0x010000; it does not contain the settings sectors.
Source glyph licensing and glyph appearance belong to the supplied font.
"""
import argparse
import json
from pathlib import Path
import zlib

FONT_ADDRESS = 0x010000
FONT_BYTES = 94 * 94 * 32


def pack_font(source):
    if len(source) != FONT_BYTES:
        raise ValueError(f'Expected exactly {FONT_BYTES} bytes of 94x94 HZK16 slots')
    output = bytearray(FONT_BYTES)
    assigned = 0
    for high in range(0xa1, 0xff):
        for low in range(0xa1, 0xff):
            try:
                bytes((high, low)).decode('gb2312')
            except UnicodeDecodeError:
                continue
            slot = (high - 0xa1) * 94 + low - 0xa1
            offset = slot * 32
            output[offset:offset + 32] = source[offset:offset + 32]
            assigned += 1
    return bytes(output), assigned


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--force', action='store_true', help='Overwrite an existing output region')
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error('Source and output must differ')
    try:
        output, assigned = pack_font(args.source.read_bytes())
        with args.output.open('wb' if args.force else 'xb') as target:
            target.write(output)
    except (OSError, ValueError) as exc:
        parser.exit(1, f'Font error: {exc}\n')
    print(json.dumps({'file': str(args.output), 'flash_address': f'0x{FONT_ADDRESS:06x}',
                      'bytes': len(output), 'slots': 8836, 'assigned_slots': assigned,
                      'crc32_iso_hdlc': f'{zlib.crc32(output):08x}'}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
