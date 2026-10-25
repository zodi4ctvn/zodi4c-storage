Locales = Locales or {}

local fallback = Locales.en or {}
local selected = Locales[Config.Locale] or fallback

local merged = {}
for key, value in pairs(fallback) do
    merged[key] = value
end
for key, value in pairs(selected) do
    merged[key] = value
end

Config.Locales = merged

--- Returns a translated string. Optional arguments are passed to string.format.
function L(key, ...)
    local value = Config.Locales[key] or key
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, value, ...)
        return ok and formatted or value
    end
    return value
end
