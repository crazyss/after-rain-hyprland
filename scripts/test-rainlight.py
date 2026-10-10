#!/usr/bin/env python3
"""Headless behavior checks for Rainlight's parser and result model."""

from __future__ import annotations

import importlib.machinery
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("rainlight", str(ROOT / "bin/rainlight"))
SPEC = importlib.util.spec_from_loader("rainlight", LOADER)
assert SPEC is not None
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


def main() -> None:
    cases = {"2+3*4": "14", "(12-2)/5": "2", "2**8": "256", "pi*2": "6.28318530718"}
    for expression, expected in cases.items():
        assert MODULE.calculate(expression) == expected
    for forbidden in ("__import__('os')", "open('/etc/passwd')", "2**99"):
        try:
            MODULE.calculate(forbidden)
        except (ValueError, TypeError):
            pass
        else:
            raise AssertionError(f"unsafe calculator input accepted: {forbidden}")

    class FakeApp:
        def __init__(self, name: str, shown: bool = True) -> None:
            self.name = name
            self.shown = shown

        def should_show(self) -> bool:
            return self.shown

        def get_display_name(self) -> str:
            return self.name

    original_get_all = MODULE.Gio.AppInfo.get_all
    MODULE.Gio.AppInfo.get_all = lambda: [
        FakeApp("Zulu"), FakeApp("Hidden", shown=False), FakeApp("Alpha")
    ]
    try:
        assert [app.get_display_name() for app in MODULE.visible_apps()] == ["Alpha", "Zulu"]
    finally:
        MODULE.Gio.AppInfo.get_all = original_get_all

    launcher = MODULE.Rainlight()
    expectations = {
        "? Hyprland": ("网页搜索", "搜索：Hyprland"),
        "= 4*25": ("安全计算器", "100"),
        "@2": ("工作区", "工作区 2 · 高森葵"),
        "#林晚": ("壁纸画廊", "林晚"),
        "> true": ("命令模式", "true"),
    }
    for query, (expected_mode, expected_first) in expectations.items():
        mode, results = launcher._compose(query)
        assert mode == expected_mode
        assert results and results[0].title == expected_first
    print("Rainlight behavior checks passed.")


if __name__ == "__main__":
    main()
