# Compatibility

Validated target: Ubuntu 26.04.1 LTS, Hyprland 0.56.2, Hyprpaper 0.8.4,
SwayNC 0.12.4, 3440×1440 Wayland session.

Rainlight requires Python 3, PyGObject and GTK 4. Its application catalog uses
the standard freedesktop desktop-entry database. Workspace wallpaper sync uses
Hyprland's `.socket2.sock` IPC event stream and supports both the current
`$XDG_RUNTIME_DIR/hypr/` path and the legacy `/tmp/hypr/` path.

The public monitor rule is intentionally generic. Hyprland releases before the
current window-rule block syntax may need rule conversion. Omarchy-specific
Lua/Quickshell modules are intentionally not required.
