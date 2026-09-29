local programs = require("after_rain.programs")

local function bind(keys, category, description, dispatcher, options)
    options = options or {}
    options.description = "[" .. category .. "] " .. description
    hl.bind(keys, dispatcher, options)
end

-- Applications and session
bind("SUPER + Return", "应用", "打开终端", hl.dsp.exec_cmd(programs.terminal))
bind("SUPER + Space", "应用", "打开 Rainlight", hl.dsp.exec_cmd(programs.menu))
bind("SUPER + K", "桌面", "打开 After Rain 控制中心", hl.dsp.exec_cmd(programs.bin .. "/after-rain-menu"))
bind("SUPER + SHIFT + K", "帮助", "搜索全部快捷键", hl.dsp.exec_cmd(programs.bin .. "/after-rain-keybinds"))
bind("SUPER + F1", "帮助", "搜索全部快捷键", hl.dsp.exec_cmd(programs.bin .. "/after-rain-keybinds"))
bind("SUPER + E", "应用", "打开文件管理器", hl.dsp.exec_cmd(programs.file_manager))
bind("SUPER + SHIFT + F", "应用", "打开文件管理器（备用）", hl.dsp.exec_cmd(programs.file_manager))
bind("SUPER + SHIFT + B", "应用", "打开浏览器", hl.dsp.exec_cmd(programs.browser))
bind("SUPER + C", "窗口", "关闭当前窗口", hl.dsp.window.close())
bind("SUPER + Q", "窗口", "关闭当前窗口（备用）", hl.dsp.window.close())
bind("SUPER + F", "窗口", "切换全屏", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind("SUPER + V", "窗口", "切换浮动", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + P", "窗口", "切换伪平铺", hl.dsp.window.pseudo())
bind("SUPER + J", "窗口", "切换分割方向", hl.dsp.layout("togglesplit"))
bind("SUPER + CTRL + L", "桌面", "锁定会话", hl.dsp.exec_cmd(programs.locker))
bind("SUPER + Escape", "桌面", "打开电源菜单", hl.dsp.exec_cmd("wlogout -b 3"))

-- Desktop controls
bind("SUPER + N", "桌面", "切换通知中心", hl.dsp.exec_cmd("swaync-client -t -sw"))
bind("SUPER + comma", "桌面", "关闭最近通知", hl.dsp.exec_cmd("swaync-client --close-latest"))
bind("SUPER + SHIFT + comma", "桌面", "清空通知", hl.dsp.exec_cmd("swaync-client -C"))
bind("SUPER + CTRL + comma", "桌面", "切换勿扰模式", hl.dsp.exec_cmd("swaync-client -d"))
bind("SUPER + SHIFT + Space", "桌面", "显示或隐藏状态栏", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
bind("SUPER + CTRL + Space", "桌面", "下一张壁纸", hl.dsp.exec_cmd(programs.bin .. "/after-rain-wallpaper next"))
bind("SUPER + CTRL + A", "应用", "打开音频混音器", hl.dsp.exec_cmd("kitty --class after-rain-audio wiremix"))
bind("SUPER + CTRL + W", "应用", "打开 Wi-Fi 管理", hl.dsp.exec_cmd("kitty --class after-rain-network nmtui"))
bind("SUPER + CTRL + B", "应用", "打开蓝牙管理", hl.dsp.exec_cmd("kitty --class after-rain-bluetooth bluetui"))
bind("CTRL + Space", "输入", "切换中英文输入", hl.dsp.exec_cmd(programs.bin .. "/after-rain-input-toggle"))

local directions = { left = "left", right = "right", up = "up", down = "down" }
for key, direction in pairs(directions) do
    bind("SUPER + " .. key, "窗口", "移动焦点 " .. key, hl.dsp.focus({ direction = direction }))
    bind("SUPER + SHIFT + " .. key, "窗口", "移动窗口 " .. key, hl.dsp.window.move({ direction = direction }))
end
bind("SUPER + CTRL + left", "窗口", "缩窄窗口", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
bind("SUPER + CTRL + right", "窗口", "加宽窗口", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
bind("SUPER + CTRL + up", "窗口", "缩短窗口", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
bind("SUPER + CTRL + down", "窗口", "加高窗口", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

local people = { "Lin Wan", "Aoi Takamori", "Seo Ji-an", "Clara Reed" }
for workspace = 1, 10 do
    local key = workspace % 10
    local label = "工作区 " .. workspace
    if people[workspace] then
        label = label .. " · " .. people[workspace]
        bind("SUPER + " .. key, "工作区", label, hl.dsp.exec_cmd(programs.bin .. "/after-rain-workspace " .. workspace))
    else
        bind("SUPER + " .. key, "工作区", label, hl.dsp.focus({ workspace = workspace }))
    end
    bind("SUPER + SHIFT + " .. key, "工作区", "移动窗口到工作区 " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end
bind("SUPER + S", "工作区", "切换暂存区", hl.dsp.workspace.toggle_special("magic"))
bind("SUPER + SHIFT + S", "工作区", "移动窗口到暂存区", hl.dsp.window.move({ workspace = "special:magic" }))

-- Screenshots
bind("Print", "截图", "截取区域并复制", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
bind("ALT + Print", "截图", "截取窗口并复制", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))
bind("SHIFT + Print", "截图", "截取显示器并复制", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))

-- Mouse and hardware keys
bind("SUPER + mouse:272", "窗口", "拖动窗口", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "窗口", "调整窗口大小", hl.dsp.window.resize(), { mouse = true })
bind("XF86AudioRaiseVolume", "硬件", "提高音量", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", "硬件", "降低音量", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
bind("XF86AudioMute", "硬件", "切换静音", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
bind("XF86AudioPlay", "硬件", "播放或暂停", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
bind("XF86AudioNext", "硬件", "下一首", hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true })
bind("XF86AudioPrev", "硬件", "上一首", hl.dsp.exec_cmd("swayosd-client --playerctl prev"), { locked = true })
