local monitors = {
    { output = "", mode = "preferred", position = "auto", scale = 1 },
}

local ok, overrides = pcall(require, "after_rain_local")
if ok and type(overrides) == "table" and type(overrides.monitors) == "table" then
    monitors = overrides.monitors
end

for _, monitor in ipairs(monitors) do
    hl.monitor(monitor)
end
