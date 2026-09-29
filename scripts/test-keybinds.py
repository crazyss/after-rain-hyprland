#!/usr/bin/env python3
"""Exercise live-JSON and legacy fallback paths of the keybinding browser."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
PROGRAM = ROOT / "bin" / "after-rain-keybinds"


def invoke(environment: dict[str, str]) -> list[dict[str, object]]:
    result = subprocess.run(
        [str(PROGRAM), "--dump-json"],
        check=True,
        capture_output=True,
        text=True,
        env={**os.environ, **environment},
    )
    return json.loads(result.stdout)


with tempfile.TemporaryDirectory() as temporary:
    fixture = Path(temporary) / "binds.json"
    fixture.write_text(
        json.dumps(
            [
                {
                    "modmask": 65,
                    "key": "K",
                    "description": "[帮助] 搜索全部快捷键",
                    "dispatcher": "exec",
                    "submap": "",
                },
                {
                    "modmask": 0,
                    "key": "Print",
                    "description": "[截图] 截取区域",
                    "dispatcher": "exec",
                    "submap": "default",
                },
            ]
        ),
        encoding="utf-8",
    )
    live = invoke({"AFTER_RAIN_BINDINGS_JSON": str(fixture)})
    assert live[0]["category"] == "帮助"
    assert live[0]["description"] == "搜索全部快捷键"
    assert live[0]["keys"] == "Super+Shift+K"

fallback = invoke({"XDG_CONFIG_HOME": str(ROOT / "config")})
assert any(item["keys"] == "Super+F1" for item in fallback)
assert not any(item["keys"].casefold() == "i" for item in fallback)
print("Keybinding browser tests passed.")
