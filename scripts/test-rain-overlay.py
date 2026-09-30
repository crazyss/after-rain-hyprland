#!/usr/bin/env python3
"""Rain IPC boundary and renderer contracts; no desktop mutation required."""
from pathlib import Path
import json
import os
import re
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
QML = ROOT / "config/quickshell/after-rain"


class RainTests(unittest.TestCase):
    def test_renderer_boundary(self):
        surface = (QML / "Effects/RainSurface.qml").read_text() + (QML / "Effects/GlassDroplets.qml").read_text()
        for contract in ('mask: Region {}', 'surfaceFormat.opaque: false',
                         'WlrKeyboardFocus.None', 'WlrLayer.Top',
                         'ExclusionMode.Ignore', 'beadCount: surface.liveCap',
                         'updatesEnabled: visible'):
            self.assertIn(contract, surface)
        for source in ("shell.qml", "Effects/RainSlot.qml", "Effects/RainSurface.qml", "Core/RainController.qml"):
            self.assertNotIn("import QtQuick.Particles", (QML / source).read_text())
            self.assertNotIn("RainStreaks", (QML / source).read_text())
        ipc = (QML / "Core/RainIpc.qml").read_text()
        self.assertEqual(set(re.findall(r"function\s+(\w+)\(", ipc)),
                         {"status", "setMode", "toggle"})
        ET.parse(QML / "Assets/glass-drop.svg")
        ET.parse(QML / "Assets/rain-streak.svg")

    def test_cli(self):
        with tempfile.TemporaryDirectory(prefix="rain-cli-test-") as directory:
            folder = Path(directory)
            fake = folder / "qs"
            fake.write_text('#!/usr/bin/env python3\nimport json,os,sys\n'
                            'open(os.environ["RAIN_CALL"],"w").write(json.dumps(sys.argv[1:]))\n'
                            'print(os.environ.get("RAIN_REPLY",\'{"ok":true,"data":{"schema":1}}\'))\n')
            fake.chmod(0o755)
            env = dict(os.environ, PATH=f"{folder}:{os.environ['PATH']}",
                       RAIN_CALL=str(folder / "call"))
            def call(*args):
                return subprocess.run([str(ROOT / "bin/after-rain-shell"), "rain", *args],
                                      env=env, capture_output=True, text=True)
            for mode in ("off", "light", "normal", "heavy"):
                result = call(mode)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(json.loads(result.stdout)["ok"])
                self.assertEqual(json.loads((folder / "call").read_text()),
                                 ["-c", "after-rain", "ipc", "call", "rain", "setMode", mode])
            for args in (("invalid",), (), ("normal", "extra")):
                (folder / "call").unlink(missing_ok=True)
                result = call(*args)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, "")
                self.assertFalse((folder / "call").exists())
                self.assertFalse(json.loads(result.stderr)["ok"])
            env["RAIN_REPLY"] = '{"ok":false,"error":{"code":"STATE_WRITE"}}'
            result = call("toggle")
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertEqual(json.loads(result.stderr)["error"]["code"], "STATE_WRITE")


if __name__ == "__main__":
    unittest.main()
