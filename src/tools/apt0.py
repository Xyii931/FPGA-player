#!/usr/bin/env python3
"""Project APT0 converter/reference decoder; Python standard library only.

  python src/tools/apt0.py encode input.wav output.apt
  python src/tools/apt0.py decode input.apt decoded.wav

WAV input/output: 48000 Hz, stereo, signed PCM16. Encoding is lossy.
The container is APT0 from design 02, not Microsoft IMA ADPCM WAVE.
"""
import argparse
from pathlib import Path
import struct
import wave

HEADER = struct.Struct('<4sIHHHHII')
FRAMES_PER_BLOCK = 1017
BLOCK_BYTES = 1024
STEP = (
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130,
    143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449,
    494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411,
    1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660,
    4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493,
    10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385,
    24623, 27086, 29794, 32767,
)
INDEX = (-1, -1, -1, -1, 2, 4, 6, 8)


def ima_decode(code, predictor, index):
    step = STEP[index]
    delta = step // 8
    for mask, divisor in ((1, 4), (2, 2), (4, 1)):
        if code & mask:
            delta += step // divisor
    predictor += -delta if code & 8 else delta
    return max(-32768, min(32767, predictor)), max(0, min(88, index + INDEX[code & 7]))


def encode_channel(samples):
    predictor, index = samples[0], 0
    result = bytearray(struct.pack('<hBB', predictor, index, 0))
    packed = 0
    for position in range(1, FRAMES_PER_BLOCK):
        target = samples[min(position, len(samples) - 1)]
        difference = target - predictor
        code = 8 if difference < 0 else 0
        magnitude = abs(difference)
        step = STEP[index]
        for mask, threshold in ((4, step), (2, step // 2), (1, step // 4)):
            if magnitude >= threshold:
                code |= mask
                magnitude -= threshold
        predictor, index = ima_decode(code, predictor, index)
        if position & 1:
            packed = code
        else:
            result.append(packed | (code << 4))
    return bytes(result)


def decode_channel(block):
    predictor, index, reserved = struct.unpack_from('<hBB', block)
    if index > 88 or reserved:
        raise ValueError('Invalid channel step_index/reserved')
    result = [predictor]
    for value in block[4:]:
        for code in (value & 15, value >> 4):
            predictor, index = ima_decode(code, predictor, index)
            result.append(predictor)
    return result


def encode(source, target, force=False):
    with wave.open(str(source), 'rb') as pcm:
        if (pcm.getnchannels(), pcm.getsampwidth(), pcm.getframerate(), pcm.getcomptype()) != (2, 2, 48000, 'NONE'):
            raise ValueError('Input must be PCM16 stereo at 48000 Hz')
        frames = pcm.getnframes()
        size = 24 + ((frames + 1016) // 1017) * BLOCK_BYTES
        if frames > 0xffffffff or size > 0xffffffff:
            raise ValueError('File exceeds the 32-bit player size contract')
        with target.open('wb' if force else 'xb') as apt:
            apt.write(HEADER.pack(b'APT0', 48000, 2, 1, 1024, 24, frames, 0))
            left = frames
            while left:
                count = min(left, FRAMES_PER_BLOCK)
                payload = pcm.readframes(count)
                if len(payload) != count * 4:
                    raise ValueError('Truncated WAV sample payload')
                pairs = list(struct.iter_unpack('<hh', payload))
                apt.write(encode_channel([pair[0] for pair in pairs]))
                apt.write(encode_channel([pair[1] for pair in pairs]))
                left -= count


def decode(source, target, force=False):
    with source.open('rb') as apt:
        header = apt.read(24)
        if len(header) != 24:
            raise ValueError('APT0 requires a 24-byte header')
        magic, rate, channels, codec, align, header_bytes, frames, reserved = HEADER.unpack(header)
        if (magic, rate, channels, codec, align, header_bytes, reserved) != (b'APT0', 48000, 2, 1, 1024, 24, 0):
            raise ValueError('Unsupported APT0 header')
        expected = 24 + ((frames + 1016) // 1017) * BLOCK_BYTES
        if source.stat().st_size != expected or expected > 0xffffffff:
            raise ValueError('APT0 length does not match total_frames/block padding')
        with target.open('wb' if force else 'xb') as output:
            with wave.open(output, 'wb') as pcm:
                pcm.setparams((2, 2, 48000, frames, 'NONE', 'not compressed'))
                left = frames
                while left:
                    block = apt.read(BLOCK_BYTES)
                    if len(block) != BLOCK_BYTES:
                        raise ValueError('Truncated APT0 block')
                    a, b = decode_channel(block[:512]), decode_channel(block[512:])
                    count = min(left, FRAMES_PER_BLOCK)
                    pcm.writeframesraw(b''.join(struct.pack('<hh', a[i], b[i]) for i in range(count)))
                    left -= count


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('operation', choices=('encode', 'decode'))
    parser.add_argument('source', type=Path)
    parser.add_argument('target', type=Path)
    parser.add_argument('--force', action='store_true', help='Overwrite an existing target')
    args = parser.parse_args()
    if args.source.resolve() == args.target.resolve():
        parser.error('Source and target must differ')
    try:
        (encode if args.operation == 'encode' else decode)(args.source, args.target, args.force)
    except (OSError, ValueError, EOFError, wave.Error, struct.error) as exc:
        parser.exit(1, f'APT0 error: {exc}\n')


if __name__ == '__main__':
    main()
