local programs = require("after_rain.programs")

local M = { programs = programs }
local registered = {}
local section_orders = {}
local section_names = {}

local function identity(keys)
    return keys:gsub("%s+", ""):upper()
end

function M.section(order, name)
    if type(order) ~= "number" or order < 0 or order > 999 or order % 1 ~= 0 then
        error("binding section order must be an integer from 0 to 999")
    end
    if type(name) ~= "string" or name == "" or name:find("|", 1, true) or name:find("]", 1, true) then
        error("binding section name must be non-empty and cannot contain | or ]")
    end
    if section_orders[order] then
        error("duplicate binding section order " .. order .. " (already used by " .. section_orders[order] .. ")")
    end
    if section_names[name] then
        error("duplicate binding section name " .. name)
    end
    section_orders[order] = name
    section_names[name] = order
    return { order = order, name = name }
end

function M.bind(keys, section, description, dispatcher, options)
    if type(keys) ~= "string" or keys == "" then
        error("binding keys must be a non-empty string")
    end
    if type(description) ~= "string" or description == "" then
        error("binding " .. keys .. " requires a description")
    end
    if type(section) == "string" then
        section = M.section(500, section)
    end
    if type(section) ~= "table" or type(section.order) ~= "number" or type(section.name) ~= "string" then
        error("binding " .. keys .. " requires a section created by keys.section")
    end
    local binding_id = identity(keys)
    if registered[binding_id] then
        error("duplicate binding " .. keys .. " (already registered as " .. registered[binding_id] .. ")")
    end
    registered[binding_id] = description

    options = options or {}
    options.description = string.format("[%03d|%s] %s", section.order, section.name, description)
    hl.bind(keys, dispatcher, options)
end

function M.bind_navigation(section)
    local directions = {
        { key = "left", direction = "left" },
        { key = "right", direction = "right" },
        { key = "up", direction = "up" },
        { key = "down", direction = "down" },
    }
    for _, item in ipairs(directions) do
        M.bind("SUPER + " .. item.key, section, "移动焦点 " .. item.key,
            hl.dsp.focus({ direction = item.direction }))
        M.bind("SUPER + SHIFT + " .. item.key, section, "移动窗口 " .. item.key,
            hl.dsp.window.move({ direction = item.direction }))
    end
    M.bind("SUPER + CTRL + left", section, "缩窄窗口",
        hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
    M.bind("SUPER + CTRL + right", section, "加宽窗口",
        hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
    M.bind("SUPER + CTRL + up", section, "缩短窗口",
        hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
    M.bind("SUPER + CTRL + down", section, "加高窗口",
        hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
    M.bind("SUPER + mouse:272", section, "拖动窗口", hl.dsp.window.drag(), { mouse = true })
    M.bind("SUPER + mouse:273", section, "调整窗口大小", hl.dsp.window.resize(), { mouse = true })
end

function M.bind_workspaces(section, scratchpad_key)
    local people = { "Lin Wan", "Aoi Takamori", "Seo Ji-an", "Clara Reed" }
    for workspace = 1, 10 do
        local key = workspace % 10
        local label = "工作区 " .. workspace
        if people[workspace] then
            label = label .. " · " .. people[workspace]
            M.bind("SUPER + " .. key, section, label,
                hl.dsp.exec_cmd(programs.bin .. "/after-rain-workspace " .. workspace))
        else
            M.bind("SUPER + " .. key, section, label, hl.dsp.focus({ workspace = workspace }))
        end
        M.bind("SUPER + SHIFT + " .. key, section, "移动窗口到工作区 " .. workspace,
            hl.dsp.window.move({ workspace = workspace }))
    end
    if type(scratchpad_key) == "string" and scratchpad_key ~= "" then
        M.bind("SUPER + " .. scratchpad_key, section, "切换暂存区",
            hl.dsp.workspace.toggle_special("magic"))
        M.bind("SUPER + SHIFT + " .. scratchpad_key, section, "移动窗口到暂存区",
            hl.dsp.window.move({ workspace = "special:magic" }))
    end
end

function M.bind_input(section)
    M.bind("CTRL + Space", section, "切换中英文输入",
        hl.dsp.exec_cmd(programs.bin .. "/after-rain-input-toggle"))
end

function M.bind_screenshots(section)
    M.bind("Print", section, "截取区域并复制",
        hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
    M.bind("ALT + Print", section, "截取窗口并复制",
        hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))
    M.bind("SHIFT + Print", section, "截取显示器并复制",
        hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
end

function M.bind_hardware(section)
    M.bind("XF86AudioRaiseVolume", section, "提高音量",
        hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
    M.bind("XF86AudioLowerVolume", section, "降低音量",
        hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
    M.bind("XF86AudioMute", section, "切换静音",
        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
    M.bind("XF86AudioPlay", section, "播放或暂停",
        hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
    M.bind("XF86AudioNext", section, "下一首",
        hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true })
    M.bind("XF86AudioPrev", section, "上一首",
        hl.dsp.exec_cmd("swayosd-client --playerctl prev"), { locked = true })
end

return M
