local keys = require("after_rain.binding_profiles.lib")
local programs = keys.programs

local section = {
    common_apps = keys.section(10, "常用应用"),
    common_functions = keys.section(20, "常用功能"),
    window = keys.section(30, "窗口"),
    workspace = keys.section(40, "工作区"),
    session = keys.section(50, "会话"),
    screenshots = keys.section(60, "截图"),
    hardware = keys.section(70, "硬件"),
    help = keys.section(80, "帮助"),
}

local M = {}

function M.apply()
    keys.bind("SUPER + F1", section.help, "搜索全部快捷键",
        hl.dsp.exec_cmd(programs.bin .. "/after-rain-shell toggle-keybindings"))
    keys.bind("SUPER + Space", section.common_apps, "打开 Rainlight", hl.dsp.exec_cmd(programs.menu))
    keys.bind("SUPER + Return", section.common_apps, "打开终端", hl.dsp.exec_cmd(programs.terminal))
    keys.bind("SUPER + E", section.common_apps, "打开文件管理器", hl.dsp.exec_cmd(programs.file_manager))
    keys.bind("SUPER + K", section.common_apps, "打开 After Rain 控制中心",
        hl.dsp.exec_cmd(programs.bin .. "/after-rain-menu"))

    keys.bind("SUPER + Q", section.common_functions, "关闭当前窗口", hl.dsp.window.close())
    keys.bind("SUPER + F", section.common_functions, "切换全屏",
        hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
    keys.bind("SUPER + CTRL + L", section.session, "锁定会话", hl.dsp.exec_cmd(programs.locker))

    keys.bind_navigation(section.window)
    keys.bind_workspaces(section.workspace, nil)
    keys.bind_input(section.common_functions)
    keys.bind_screenshots(section.screenshots)
    keys.bind_hardware(section.hardware)
end

return M
