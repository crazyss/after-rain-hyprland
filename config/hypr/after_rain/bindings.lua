-- Binding profile loader. Profile names are deliberately mapped through a
-- whitelist; machine-local strings are never passed directly to require().
local profiles = {
    standard = "after_rain.binding_profiles.standard",
    ["zh-pinyin"] = "after_rain.binding_profiles.zh_pinyin",
    minimal = "after_rain.binding_profiles.minimal",
}

local selected = "standard"
local ok, overrides = pcall(require, "after_rain_local")
if ok and type(overrides) == "table" and type(overrides.binding_profile) == "string" then
    selected = overrides.binding_profile
end

if selected == "custom" then
    local loaded, problem = pcall(require, "after_rain_bindings")
    if not loaded then
        error("binding_profile 'custom' requires ~/.config/hypr/after_rain_bindings.lua: " .. tostring(problem))
    end
    return
end

local module_name = profiles[selected]
if module_name == nil then
    error("unknown binding_profile '" .. selected .. "' (expected standard, zh-pinyin, minimal, or custom)")
end

require(module_name).apply()
