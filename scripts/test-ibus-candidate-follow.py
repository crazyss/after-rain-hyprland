#!/usr/bin/env python3
"""Unit checks for the X11 IBus candidate follower."""

from __future__ import annotations

import importlib.machinery
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MODULE = importlib.machinery.SourceFileLoader(
    "after_rain_ibus_candidate_follow",
    str(ROOT / "bin/after-rain-ibus-candidate-follow"),
).load_module()


def main() -> None:
    assert MODULE.candidate_position((100, 200, 0, 20), (300, 80), (0, 0, 1920, 1080)) == (
        100,
        220,
    )
    assert MODULE.candidate_position((1850, 1000, 0, 20), (300, 80), (0, 0, 1920, 1080)) == (
        1620,
        920,
    )
    assert MODULE.candidate_position((-900, 100, 0, 20), (250, 60), (-1280, 0, 1280, 1024)) == (
        -900,
        120,
    )

    parser = MODULE.CursorParser()
    header = (
        "method call time=1 sender=:1.0 destination=(null destination) "
        "serial=1 path=/org/freedesktop/IBus/Panel; "
        "interface=org.freedesktop.IBus.Panel; member=SetCursorLocation"
    )
    assert parser.feed(header) is None
    assert parser.feed("   int32 2466") is None
    assert parser.feed("   int32 1326") is None
    assert parser.feed("   int32 0") is None
    assert parser.feed("   int32 20") == (2466, 1326, 0, 20)

    print("IBus candidate follower checks passed.")


if __name__ == "__main__":
    main()
