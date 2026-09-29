local theme = require("after_rain.theme")
local colors = theme.colors
local geometry = theme.geometry

hl.config({
    general = {
        gaps_in = geometry.gap_inner,
        gaps_out = geometry.gap_outer,
        border_size = geometry.border,
        col = {
            active_border = { colors = { colors.accent, colors.accent_warm }, angle = 45 },
            inactive_border = colors.surface_high,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = geometry.radius,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        shadow = {
            enabled = true,
            range = 28,
            render_power = 3,
            color = colors.background,
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            vibrancy = 0.16,
        },
    },
    animations = { enabled = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = colors.background,
    },
    cursor = {
        inactive_timeout = 4,
        hide_on_key_press = true,
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
    },
    master = { new_status = "master" },
})

hl.curve("rainEase", { type = "bezier", points = { { 0.2, 0.9 }, { 0.2, 1.0 } } })
hl.curve("rainPop", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "rainPop", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "rainEase", style = "popin 92%" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "rainEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "rainEase", style = "slidefade 18%" })
