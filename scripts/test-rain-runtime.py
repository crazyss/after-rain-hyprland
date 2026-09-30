#!/usr/bin/env python3
"""Opt-in live Wayland checks. Starts only isolated, temporary Shell instances.

Run with no other rain preview active: python3 scripts/test-rain-runtime.py
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent
QS = shutil.which("qs") or str(Path.home() / ".local/bin/qs")


def main():
    with tempfile.TemporaryDirectory(prefix="rain-runtime-") as directory:
        folder = Path(directory)
        config = folder / "config"
        shutil.copytree(ROOT / "config/quickshell/after-rain", config)
        shell = config / "shell.qml"
        shell.write_text(shell.read_text().replace("ShellId after-rain", "ShellId after-rain-runtime-test"))
        state = folder / "state/after-rain-shell/rain.json"
        env = dict(os.environ, XDG_STATE_HOME=str(folder / "state"))

        def scenario(check, extra=None):
            with (folder / "log").open("w+") as log:
                proc = subprocess.Popen([QS, "-p", str(config), "--no-color"],
                                        env=dict(env, **(extra or {})), stdout=log, stderr=log)
                def ipc(*args):
                    return subprocess.check_output([QS, "ipc", "--pid", str(proc.pid), "call", *args],
                                                   text=True, stderr=subprocess.DEVNULL, timeout=5).strip()
                def status(): return json.loads(ipc("rain", "status"))["data"]
                try:
                    for _ in range(100):
                        if proc.poll() is not None:
                            log.seek(0)
                            raise AssertionError(log.read())
                        try:
                            if status()["initialized"]: break
                        except (subprocess.CalledProcessError, KeyError): pass
                        time.sleep(.05)
                    else: raise AssertionError("Shell readiness timed out")
                    time.sleep(.3)
                    assert ipc("shell", "ping") == "ok"
                    check(ipc, status)
                finally:
                    proc.terminate()
                    try: proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                        proc.wait()
                log.seek(0)
                assert "Binding loop" not in log.read()

        def modes(ipc, status):
            before = status()["requestedMode"]
            assert not json.loads(ipc("rain", "setMode", "invalid"))["ok"]
            assert status()["requestedMode"] == before
            for mode in ("light", "normal", "heavy"):
                assert json.loads(ipc("rain", "setMode", mode))["ok"]
                assert status()["requestedMode"] == mode
            for _ in range(100):
                assert json.loads(ipc("rain", "toggle"))["ok"]
            assert status()["requestedMode"] == "heavy"
            ipc("rain", "setMode", "off")
            assert all(s["effective"] == "disabled" for s in status()["screens"])
        scenario(modes)
        assert json.loads(state.read_text())["mode"] == "off"

        def restore(ipc, status):
            assert status()["requestedMode"] == "off"
            ipc("rain", "toggle")
            assert status()["requestedMode"] == "heavy"
        scenario(restore)
        saved = state.read_text()

        def killed(ipc, status):
            assert status()["killSwitch"]
            assert all(s["suppressedBy"] == ["kill-switch"] for s in status()["screens"])
        scenario(killed, {"AFTER_RAIN_EFFECT": "off"})
        assert state.read_text() == saved

        def broken(ipc, status):
            assert any(s["effective"] == "unavailable" for s in status()["screens"])
            assert ipc("shell", "ping") == "ok"
        surface = config / "Effects/RainSurface.qml"
        original = surface.read_text()
        surface.write_text(original.replace("import QtQuick", "import MissingRainRenderer"))
        scenario(broken)
        surface.write_text(original)
        (config / "Assets/glass-drop.svg").unlink()
        scenario(broken)

        state.write_text("{broken")
        def corrupt(ipc, status):
            assert status()["requestedMode"] == "normal"
            assert status()["lastError"].startswith("STATE_INVALID:")
        scenario(corrupt, {"AFTER_RAIN_EFFECT": "off"})
        assert state.read_text() == "{broken"
        print("PASS: modes, invalid IPC, 100 toggles, restart, kill switch, missing import, texture failure, corrupt state")


if __name__ == "__main__":
    main()
