from __future__ import annotations

import argparse
from hashlib import sha256
from pathlib import Path
import struct
import zlib

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    checksum = zlib.crc32(kind)
    checksum = zlib.crc32(payload, checksum) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", checksum)


def read_p3(path: Path) -> tuple[int, int, bytes]:
    tokens: list[str] = []
    for line in path.read_text(encoding="ascii").splitlines():
        tokens.extend(line.split("#", 1)[0].split())

    if len(tokens) < 4 or tokens[0] != "P3":
        raise ValueError("input must be an ASCII P3 PPM file")
    width = int(tokens[1])
    height = int(tokens[2])
    maximum = int(tokens[3])
    values = [int(value) for value in tokens[4:]]
    expected = width * height * 3
    if width <= 0 or height <= 0 or maximum <= 0:
        raise ValueError("invalid PPM dimensions or maximum value")
    if len(values) != expected:
        raise ValueError(f"expected {expected} channel values, found {len(values)}")
    if any(value < 0 or value > maximum for value in values):
        raise ValueError("PPM channel value is out of range")

    if maximum != 255:
        values = [(value * 255 + maximum // 2) // maximum for value in values]
    return width, height, bytes(values)


def write_rgb_png(path: Path, width: int, height: int, pixels: bytes) -> None:
    stride = width * 3
    scanlines = b"".join(
        b"\x00" + pixels[row * stride : (row + 1) * stride]
        for row in range(height)
    )
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    encoded = (
        PNG_SIGNATURE
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", zlib.compress(scanlines, level=9))
        + png_chunk(b"IEND", b"")
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded)


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert a simulator-generated P3 frame to deterministic RGB PNG.")
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    width, height, pixels = read_p3(args.input)
    write_rgb_png(args.output, width, height, pixels)
    digest = sha256(args.output.read_bytes()).hexdigest()
    print(f"wrote {args.output} ({width}x{height}, sha256={digest})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
