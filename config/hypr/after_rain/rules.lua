hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "rainlight-launcher",
    match = { class = "^(dev.afterrain.Rainlight|rainlight)$" },
    float = true,
    center = true,
    size = { 780, 570 },
    stay_focused = true,
})

hl.window_rule({
    name = "keybinding-browser",
    match = { class = "^(dev.afterrain.Keybindings|after-rain-keybinds)$" },
    float = true,
    center = true,
    size = { 900, 680 },
    stay_focused = true,
})

hl.window_rule({
    name = "fix-xwayland-drag",
    match = { xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name = "after-rain-tools",
    match = { class = "^(after-rain-audio|after-rain-network|after-rain-bluetooth)$" },
    float = true,
    center = true,
    size = { 1400, 900 },
})

for _, namespace in ipairs({ "waybar", "swaync-control-center", "hyprlauncher", "after-rain-keybindings" }) do
    hl.layer_rule({
        name = namespace .. "-blur",
        match = { namespace = namespace },
        blur = true,
        ignore_alpha = 0.15,
    })
end
