#!/usr/bin/env python3
"""Static contracts for the first-party Quickshell foundation."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHELL = ROOT / "config/quickshell/after-rain"


def require(path: Path, needle: str) -> None:
    text = path.read_text(encoding="utf-8")
    if needle not in text:
        raise SystemExit(f"missing {needle!r} in {path.relative_to(ROOT)}")


required = [
    "shell.qml",
    "Core/ShellState.qml",
    "Core/ShellController.qml",
    "Core/BindingsModel.qml",
    "Generated/Theme.qml",
    "Surfaces/KeybindingsOverlay.qml",
    "Ui/SurfaceFrame.qml",
    "Ui/Keycap.qml",
]
for relative in required:
    if not (SHELL / relative).is_file():
        raise SystemExit(f"missing Quickshell file: {relative}")

shell_text = (SHELL / "shell.qml").read_text(encoding="utf-8")
functions = set(re.findall(r"function\s+([A-Za-z0-9_]+)\s*\(", shell_text))
allowed = {
    "ping",
    "version",
    "toggleKeybindings",
    "showKeybindings",
    "hideKeybindings",
    "reloadBindings",
}
if functions != allowed:
    raise SystemExit(f"unexpected Quickshell IPC functions: {sorted(functions)}")
if "Hyprland.requestSocketPath.length > 0" not in shell_text:
    raise SystemExit("shell health must require a live Hyprland IPC socket")

all_qml = "\n".join(
    path.read_text(encoding="utf-8") for path in sorted(SHELL.rglob("*.qml"))
)
for forbidden in ("execDetached", "eval(", "run(command", "dispatch(request"):
    if forbidden in all_qml:
        raise SystemExit(f"forbidden extensible execution path in QML: {forbidden}")

bindings = SHELL / "Core/BindingsModel.qml"
require(bindings, 'command: ["hyprctl", "-j", "binds"]')
require(bindings, 'hyprctl.exec(["hyprctl", "-j", "binds"])')

overlay = SHELL / "Surfaces/KeybindingsOverlay.qml"
require(overlay, 'WlrLayershell.namespace: "after-rain-keybindings"')
require(overlay, "WlrKeyboardFocus.None")
require(overlay, "Keys.onEscapePressed")

unit = (ROOT / "config/systemd/user/after-rain-shell.service").read_text(
    encoding="utf-8"
)
if "Restart=on-failure" not in unit or "@AFTER_RAIN_BIN_ROOT@" not in unit:
    raise SystemExit("after-rain-shell.service is missing restart or path templating")
if "ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE" not in unit:
    raise SystemExit("after-rain-shell.service must be restricted to Hyprland")
if "ExecStartPost=@AFTER_RAIN_BIN_ROOT@/after-rain-shell wait-ready" not in unit:
    raise SystemExit("after-rain-shell.service must verify typed IPC readiness")
if "WantedBy=" in unit:
    raise SystemExit("after-rain-shell.service must not start in every graphical session")

for service in (
    "waybar",
    "swaync",
    "swayosd",
    "hypridle",
    "hyprpaper",
    "hyprpolkitagent",
):
    dropin = ROOT / f"config/systemd/user/{service}.service.d/after-rain-session.conf"
    require(dropin, "ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE")

lua = (ROOT / "config/hypr/after_rain/bindings.lua").read_text(encoding="utf-8")
if lua.count("/after-rain-shell toggle-keybindings") != 2:
    raise SystemExit("both keybinding shortcuts must use the shell fallback wrapper")

autostart = (ROOT / "config/hypr/after_rain/autostart.lua").read_text(
    encoding="utf-8"
)
if "/after-rain-session-start" not in autostart:
    raise SystemExit("Hyprland must use the deterministic session startup helper")
session_start = (ROOT / "bin/after-rain-session-start").read_text(encoding="utf-8")
if "dbus-update-activation-environment" not in session_start or "HYPRLAND_INSTANCE_SIGNATURE" not in session_start:
    raise SystemExit("session startup must export the Hyprland signature")
environment_import = session_start.index('"$dbus_update_cli" --systemd')
shell_start = session_start.index('"$systemctl_cli" --user start --no-block')
if environment_import > shell_start:
    raise SystemExit("Hyprland environment import must precede shell service startup")

print("Quickshell contract tests passed.")
