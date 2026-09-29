#!/usr/bin/env python3
"""Regression check for deterministic Hyprland session service startup."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def write_executable(path: Path, source: str) -> None:
    path.write_text(source, encoding="utf-8")
    path.chmod(0o755)


def main() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        log = root / "commands.log"
        systemctl = root / "systemctl"
        dbus_update = root / "dbus-update-activation-environment"
        write_executable(
            systemctl,
            "#!/usr/bin/env bash\nprintf 'systemctl %s\\n' \"$*\" >> \"$COMMAND_LOG\"\n",
        )
        write_executable(
            dbus_update,
            "#!/usr/bin/env bash\nprintf 'dbus %s\\n' \"$*\" >> \"$COMMAND_LOG\"\n",
        )
        environment = os.environ | {
            "AFTER_RAIN_SYSTEMCTL": str(systemctl),
            "AFTER_RAIN_DBUS_UPDATE": str(dbus_update),
            "COMMAND_LOG": str(log),
            "DISPLAY": ":9",
            "WAYLAND_DISPLAY": "wayland-test",
            "XDG_CURRENT_DESKTOP": "Hyprland",
            "XDG_SESSION_TYPE": "wayland",
            "HYPRLAND_INSTANCE_SIGNATURE": "test-signature",
        }
        subprocess.run(
            [str(ROOT / "bin/after-rain-session-start")],
            env=environment,
            check=True,
        )
        commands = log.read_text(encoding="utf-8").splitlines()
        assert commands[0].startswith("systemctl --user import-environment ")
        assert "HYPRLAND_INSTANCE_SIGNATURE" in commands[0]
        assert commands[1].startswith("dbus --systemd ")
        stop_index = next(i for i, line in enumerate(commands) if " stop " in line)
        portal_start_index = next(
            i
            for i, line in enumerate(commands)
            if " start xdg-desktop-portal-hyprland.service" in line
        )
        desktop_start_index = next(
            i
            for i, line in enumerate(commands)
            if " start --no-block after-rain-shell.service" in line
        )
        assert stop_index < portal_start_index < desktop_start_index
        assert "xdg-desktop-portal-gtk.service" in commands[stop_index]

        missing = environment.copy()
        missing.pop("HYPRLAND_INSTANCE_SIGNATURE")
        failed = subprocess.run(
            [str(ROOT / "bin/after-rain-session-start")],
            env=missing,
            capture_output=True,
            text=True,
        )
        assert failed.returncode == 2
        assert "active Hyprland session" in failed.stderr

    print("Session startup ordering checks passed.")


if __name__ == "__main__":
    main()
