local programs = require("after_rain.programs")

hl.on("hyprland.start", function()
    hl.exec_cmd(programs.bin .. "/after-rain-session-start")
    -- Register IBus as a Wayland input method instead of starting its GTK
    -- panel as an ordinary toplevel.  The daemon keeps XIM enabled for
    -- XWayland applications such as ChatGPT.
    hl.exec_cmd(programs.bin .. "/after-rain-ibus-wayland")
    hl.exec_cmd("pgrep -x hyprpaper >/dev/null || hyprpaper")
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")
    hl.exec_cmd("pgrep -x waybar >/dev/null || env GDK_BACKEND=wayland waybar")
    hl.exec_cmd(programs.bin .. "/after-rain-workspace watch")
end)
