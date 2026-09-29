#!/usr/bin/env python3
"""Static contracts for selectable Hyprland binding profiles."""

from __future__ import annotations

from pathlib import Path
import re
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
PROFILE_ROOT = ROOT / "config/hypr/after_rain/binding_profiles"
PROFILES = {
    "standard": PROFILE_ROOT / "standard.lua",
    "zh-pinyin": PROFILE_ROOT / "zh_pinyin.lua",
    "minimal": PROFILE_ROOT / "minimal.lua",
}


def normalized(keys: str) -> str:
    return re.sub(r"\s+", "", keys).upper()


def helper_bindings(text: str) -> tuple[list[tuple[str, str]], list[str]]:
    generated: list[tuple[str, str]] = []
    section_references: list[str] = []
    navigation = re.search(r"keys\.bind_navigation\(\s*section\.(\w+)\s*\)", text)
    if navigation:
        section_references.append(navigation.group(1))
        for direction in ("left", "right", "up", "down"):
            generated.extend(
                (
                    (f"SUPER + {direction}", "移动焦点"),
                    (f"SUPER + SHIFT + {direction}", "移动窗口"),
                    (f"SUPER + CTRL + {direction}", "调整窗口"),
                )
            )
        generated.extend(
            (("SUPER + mouse:272", "拖动窗口"), ("SUPER + mouse:273", "调整窗口大小"))
        )
    workspace = re.search(
        r'keys\.bind_workspaces\(\s*section\.(\w+)\s*,\s*(?:"([A-Za-z])"|nil)\s*\)',
        text,
    )
    if workspace:
        section_references.append(workspace.group(1))
        for number in (*range(1, 10), 0):
            generated.extend(
                (
                    (f"SUPER + {number}", "切换工作区"),
                    (f"SUPER + SHIFT + {number}", "移动窗口到工作区"),
                )
            )
        if workspace.group(2):
            key = workspace.group(2)
            generated.extend(
                ((f"SUPER + {key}", "切换暂存区"), (f"SUPER + SHIFT + {key}", "移动窗口到暂存区"))
            )
    helper_specs = (
        ("input", (("CTRL + Space", "切换中英文输入"),)),
        (
            "screenshots",
            (("Print", "区域截图"), ("ALT + Print", "窗口截图"), ("SHIFT + Print", "显示器截图")),
        ),
        (
            "hardware",
            tuple(
                (key, "硬件")
                for key in (
                    "XF86AudioRaiseVolume",
                    "XF86AudioLowerVolume",
                    "XF86AudioMute",
                    "XF86AudioPlay",
                    "XF86AudioNext",
                    "XF86AudioPrev",
                )
            ),
        ),
    )
    for helper, bindings in helper_specs:
        match = re.search(rf"keys\.bind_{helper}\(\s*section\.(\w+)\s*\)", text)
        if match:
            section_references.append(match.group(1))
            generated.extend(bindings)
    return generated, section_references


def validate_profile(name: str, path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    section_definitions = re.findall(
        r'(\w+)\s*=\s*keys\.section\(\s*(\d+)\s*,\s*"([^"]+)"\s*\)', text
    )
    if not section_definitions:
        raise SystemExit(f"binding profile {name} defines no help-screen sections")
    sections = {identifier: (int(order), label) for identifier, order, label in section_definitions}
    orders = [order for order, _label in sections.values()]
    labels = [label for _order, label in sections.values()]
    if len(orders) != len(set(orders)) or len(labels) != len(set(labels)):
        raise SystemExit(f"binding profile {name} has duplicate section orders or labels")
    if not any(label.startswith("常用") for label in labels):
        raise SystemExit(f"binding profile {name} has no common-use section")

    explicit = re.findall(
        r'keys\.bind\(\s*"([^"]+)"\s*,\s*section\.(\w+)\s*,\s*"([^"]+)"',
        text,
        flags=re.S,
    )
    bindings = [(keys, description) for keys, _section, description in explicit]
    references = [section for _keys, section, _description in explicit]
    generated, helper_references = helper_bindings(text)
    bindings.extend(generated)
    references.extend(helper_references)
    if not bindings:
        raise SystemExit(f"binding profile {name} is empty")
    undefined = sorted(set(references) - set(sections))
    if undefined:
        raise SystemExit(f"binding profile {name} references undefined sections: {undefined}")

    seen: dict[str, str] = {}
    for keys, description in bindings:
        identity = normalized(keys)
        if identity in seen:
            raise SystemExit(
                f"binding profile {name} duplicates {keys}: {seen[identity]} / {description}"
            )
        seen[identity] = description
        if re.fullmatch(r"[A-Z]", identity):
            raise SystemExit(f"binding profile {name} captures an unmodified letter: {keys}")
        if description == "锁定会话" and not {"SUPER", "CTRL"}.issubset(identity.split("+")):
            raise SystemExit(f"binding profile {name} lock action is too easy to trigger: {keys}")
        if description == "打开电源菜单" and not {"SUPER", "CTRL", "SHIFT"}.issubset(
            identity.split("+")
        ):
            raise SystemExit(f"binding profile {name} power action is too easy to trigger: {keys}")

    if "SUPER+F1" not in seen:
        raise SystemExit(f"binding profile {name} has no discoverable help shortcut")


loader = (ROOT / "config/hypr/after_rain/bindings.lua").read_text(encoding="utf-8")
for profile, path in PROFILES.items():
    if not path.is_file():
        raise SystemExit(f"missing binding profile: {profile}")
    if f'["{profile}"]' not in loader and f"{profile} =" not in loader:
        raise SystemExit(f"binding loader does not whitelist {profile}")
    validate_profile(profile, path)

if 'require, "after_rain_bindings"' not in loader:
    raise SystemExit("custom binding profile must use the fixed after_rain_bindings module")
if "require(selected)" in loader or "require(overrides.binding_profile)" in loader:
    raise SystemExit("binding loader must not require a caller-controlled module name")

custom_example = ROOT / "config/hypr/after_rain_bindings.lua.example"
validate_profile("custom example", custom_example)

if shutil.which("Hyprland"):
    with tempfile.TemporaryDirectory() as temporary:
        for profile in (*PROFILES, "custom"):
            profile_root = Path(temporary) / profile
            shutil.copytree(ROOT / "config/hypr", profile_root)
            local_text = (profile_root / "after_rain_local.lua.example").read_text(
                encoding="utf-8"
            )
            local_text = local_text.replace(
                'binding_profile = "standard"', f'binding_profile = "{profile}"'
            )
            (profile_root / "after_rain_local.lua").write_text(local_text, encoding="utf-8")
            if profile == "custom":
                shutil.copy2(
                    profile_root / "after_rain_bindings.lua.example",
                    profile_root / "after_rain_bindings.lua",
                )
            result = subprocess.run(
                ["Hyprland", "--config", str(profile_root / "hyprland.lua"), "--verify-config"],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode != 0:
                raise SystemExit(
                    f"Hyprland rejected binding profile {profile}:\n{result.stdout}{result.stderr}"
                )

print("Binding profile tests passed.")
