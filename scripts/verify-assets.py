#!/usr/bin/env python3
"""Verify artwork checksums, PNG structure and desktop-safe metadata."""

from __future__ import annotations

import hashlib
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "assets/manifest.yml"
TEXT_CHUNKS = {b"tEXt", b"zTXt", b"iTXt", b"eXIf"}


def png_chunks(path: Path) -> tuple[int, int, set[bytes]]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("not a PNG")
    offset = 8
    chunks: set[bytes] = set()
    width = height = 0
    while offset + 12 <= len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + length]
        chunks.add(kind)
        if kind == b"IHDR":
            width, height = struct.unpack(">II", payload[:8])
        offset += 12 + length
        if kind == b"IEND":
            break
    return width, height, chunks


def main() -> int:
    text = MANIFEST.read_text(encoding="utf-8")
    entries = re.findall(
        r'- file: "([^"]+)"\n\s+sha256: "([0-9a-f]{64})"', text
    )
    if not entries:
        print("No assets found in manifest", file=sys.stderr)
        return 1
    failed = False
    for relative, expected in entries:
        path = ROOT / "assets" / relative
        if not path.is_file():
            print(f"missing: {relative}", file=sys.stderr)
            failed = True
            continue
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            print(f"checksum mismatch: {relative}", file=sys.stderr)
            failed = True
            continue
        try:
            width, height, chunks = png_chunks(path)
        except ValueError as error:
            print(f"{relative}: {error}", file=sys.stderr)
            failed = True
            continue
        forbidden = chunks & TEXT_CHUNKS
        if forbidden:
            names = ", ".join(kind.decode("ascii") for kind in sorted(forbidden))
            print(f"metadata chunks found in {relative}: {names}", file=sys.stderr)
            failed = True
        if relative.startswith("wallpapers/") and width / height < 2.2:
            print(f"wallpaper is not ultrawide: {relative} ({width}x{height})", file=sys.stderr)
            failed = True
        print(f"OK {relative} {width}x{height}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
