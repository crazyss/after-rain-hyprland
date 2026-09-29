local programs = require("after_rain.programs")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && { systemctl --user reset-failed after-rain-shell.service >/dev/null 2>&1 || true; systemctl --user start after-rain-shell.service swaync.service swayosd.service hyprpolkitagent.service xdg-desktop-portal-hyprland.service; }")
    -- Replace any stale daemon inherited from another desktop session.  A
    -- pgrep guard can match a dying GNOME IBus process and leave this Hyprland
    -- session without an IBus bus at all.
    hl.exec_cmd("/usr/bin/ibus-daemon -drx")
    hl.exec_cmd("pgrep -x hyprpaper >/dev/null || hyprpaper")
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")
    hl.exec_cmd("pgrep -x waybar >/dev/null || env GDK_BACKEND=wayland waybar")
    hl.exec_cmd(programs.bin .. "/after-rain-workspace watch")
end)
