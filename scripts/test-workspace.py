#!/usr/bin/env python3
"""Integration checks for direct and IPC-driven workspace wallpaper mapping."""

from __future__ import annotations

import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        config = root / "config"
        wallpapers = config / "hypr/wallpapers"
        runtime = root / "runtime"
        socket_dir = runtime / "hypr/test-signature"
        commands = root / "bin"
        state = root / "state"
        hyprctl_log = root / "hyprctl.log"
        wallpapers.mkdir(parents=True)
        socket_dir.mkdir(parents=True)
        commands.mkdir()
        for number in range(1, 5):
            (wallpapers / f"0{number}-character-ultrawide.png").write_bytes(b"png-test")

        hyprctl = commands / "hyprctl"
        hyprctl.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$*\" >> \"$HYPRCTL_LOG\"\n"
            "if [[ \"${1:-}\" == activeworkspace ]]; then echo '{\"id\":1}'; fi\n"
            "if [[ \"${1:-}\" == hyprpaper ]]; then echo \"MON: $XDG_CONFIG_HOME/hypr/wallpapers/$(readlink \"$XDG_CONFIG_HOME/hypr/wallpapers/current.png\")\"; fi\n"
            "exit 0\n",
            encoding="utf-8",
        )
        hyprctl.chmod(0o755)
        hyprpaper = commands / "hyprpaper"
        hyprpaper.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
        hyprpaper.chmod(0o755)
        environment = os.environ | {
            "PATH": f"{commands}:{ROOT / 'bin'}:{os.environ['PATH']}",
            "XDG_CONFIG_HOME": str(config),
            "XDG_STATE_HOME": str(state),
            "XDG_RUNTIME_DIR": str(runtime),
            "HYPRLAND_INSTANCE_SIGNATURE": "test-signature",
            "HYPRCTL_LOG": str(hyprctl_log),
        }

        subprocess.run([str(ROOT / "bin/after-rain-workspace"), "2"], env=environment, check=True)
        assert "dispatch hl.dsp.focus({ workspace = 2 })" in hyprctl_log.read_text(
            encoding="utf-8"
        )
        assert os.readlink(wallpapers / "current.png").startswith("02-")

        socket_path = socket_dir / ".socket2.sock"
        ready = threading.Event()

        def serve() -> None:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
                server.bind(str(socket_path))
                server.listen(1)
                ready.set()
                connection, _ = server.accept()
                with connection:
                    connection.sendall(b"workspacev2>>3,3\n")
                    time.sleep(0.2)

        thread = threading.Thread(target=serve, daemon=True)
        thread.start()
        assert ready.wait(2)
        watcher = subprocess.Popen(
            [str(ROOT / "bin/after-rain-workspace"), "watch"],
            env=environment,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline:
                if (wallpapers / "current.png").is_symlink() and os.readlink(wallpapers / "current.png").startswith("03-"):
                    break
                time.sleep(0.05)
            else:
                raise AssertionError("workspace IPC event did not select wallpaper 3")
        finally:
            watcher.terminate()
            watcher.wait(timeout=2)
        print("Workspace wallpaper checks passed.")


if __name__ == "__main__":
    main()
