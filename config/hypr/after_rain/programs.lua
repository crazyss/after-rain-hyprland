local programs = {
    terminal = "ghostty",
    file_manager = "nautilus --new-window",
    browser = "google-chrome",
    locker = "hyprlock",
    bin = "@AFTER_RAIN_BIN_ROOT@",
}

local ok, overrides = pcall(require, "after_rain_local")
if ok and type(overrides) == "table" and type(overrides.programs) == "table" then
    for key, value in pairs(overrides.programs) do
        programs[key] = value
    end
end

programs.menu = programs.bin .. "/rainlight"
return programs
