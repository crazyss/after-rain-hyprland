#!/usr/bin/env python3
"""Regression checks for offline IBus recovery and engine switching."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def write_executable(path: Path, source: str) -> None:
    path.write_text(source, encoding="utf-8")
    path.chmod(0o755)


def run(command: Path, environment: dict[str, str]) -> str:
    return subprocess.run(
        [str(command)],
        env=environment,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def main() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        commands = root / "bin"
        commands.mkdir()
        daemon_marker = root / "daemon-running"
        daemon_count = root / "daemon-count"
        engine_state = root / "engine"

        write_executable(
            commands / "ibus",
            """#!/usr/bin/env bash
set -euo pipefail
[[ -e "$IBUS_DAEMON_MARKER" ]] || exit 1
[[ "${1:-}" == engine ]] || exit 2
if [[ -n "${2:-}" ]]; then
  printf '%s\n' "$2" > "$IBUS_ENGINE_STATE"
else
  cat "$IBUS_ENGINE_STATE"
fi
""",
        )
        write_executable(
            commands / "ibus-daemon",
            """#!/usr/bin/env bash
set -euo pipefail
touch "$IBUS_DAEMON_MARKER"
printf 'xkb:us::eng\n' > "$IBUS_ENGINE_STATE"
count=0
[[ ! -e "$IBUS_DAEMON_COUNT" ]] || count=$(cat "$IBUS_DAEMON_COUNT")
printf '%s\n' "$((count + 1))" > "$IBUS_DAEMON_COUNT"
""",
        )
        write_executable(commands / "notify-send", "#!/usr/bin/env bash\nexit 0\n")

        environment = os.environ | {
            "PATH": f"{commands}:{os.environ['PATH']}",
            "AFTER_RAIN_IBUS_DAEMON": str(commands / "ibus-daemon"),
            "IBUS_DAEMON_MARKER": str(daemon_marker),
            "IBUS_DAEMON_COUNT": str(daemon_count),
            "IBUS_ENGINE_STATE": str(engine_state),
        }

        status = ROOT / "bin/after-rain-input-status"
        toggle = ROOT / "bin/after-rain-input-toggle"
        assert json.loads(run(status, environment))["class"] == "offline"

        assert run(toggle, environment) == "libpinyin"
        assert engine_state.read_text(encoding="utf-8").strip() == "libpinyin"
        assert json.loads(run(status, environment))["class"] == "chinese"

        assert run(toggle, environment) == "xkb:us::eng"
        assert engine_state.read_text(encoding="utf-8").strip() == "xkb:us::eng"
        assert json.loads(run(status, environment))["class"] == "english"
        assert daemon_count.read_text(encoding="utf-8").strip() == "1"

    print("Input-method recovery checks passed.")


if __name__ == "__main__":
    main()
