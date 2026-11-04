-- Parses ~/.config/hypr/colors.conf (lines like `$primary = rgba(5ED0FFff)`)
-- into a Lua table, so the existing theme scripts -- which cp a palette
-- into colors.conf and then `hyprctl reload` -- keep working unchanged.
--
-- Usage: local c = require("modules.colors"); c.primary --> "rgba(5ED0FFff)"

local path = os.getenv("HOME") .. "/.config/hypr/colors.conf"
local colors = {}

local f = io.open(path, "r")
if f then
    for raw in f:lines() do
        local line = raw:gsub("#.*$", "")
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name and value ~= "" then
            colors[name] = value
        end
    end
    f:close()
end

-- Fallbacks so a missing/partial colors.conf never breaks the whole config.
colors.primary    = colors.primary    or "rgba(5ED0FFff)"
colors.on_primary = colors.on_primary or "rgba(01131Aff)"

return colors
