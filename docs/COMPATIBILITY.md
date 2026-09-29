# Compatibility

Static validation target: Ubuntu 26.04.1 LTS, Hyprland 0.56.2 with Lua
configuration, Hyprpaper 0.8.4, SwayNC 0.12.4 and a 3440×1440 display. The
installed Lua config passes `Hyprland --verify-config`; live-session acceptance
requires logging back into Hyprland because the current session is GNOME.

Rainlight requires Python 3, PyGObject and GTK 4. Its application catalog uses
the standard freedesktop desktop-entry database. Workspace wallpaper sync uses
Hyprland's `.socket2.sock` IPC event stream and supports both the current
`$XDG_RUNTIME_DIR/hypr/` path and the legacy `/tmp/hypr/` path.

The public monitor rule is intentionally generic. Hyprland releases before 0.55
do not support the canonical Lua configuration and must use the retained legacy
Hyprlang files. Quickshell is not yet a runtime dependency; the planned unified
shell targets Quickshell 0.3.1 and keeps Waybar/SwayNC/SwayOSD as fallbacks.
