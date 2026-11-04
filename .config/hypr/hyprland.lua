--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--
-- Hyprland >= 0.57 only reads this Lua config; the old hyprlang tree
-- (hyprland.conf + conf/*.conf) is no longer loaded at all. This is a
-- faithful port of that tree's *effective* values. Modules live in
-- ~/.config/hypr/modules/.
--
-- colors.conf is still the source of truth for the palette: every
-- *-theme.sh copies a palette into it and runs `hyprctl reload`, and
-- modules/colors.lua parses it on each load, so themes keep working as-is.
--
-- API reference: /usr/share/hypr/stubs/hl.meta.lua
-- Check for errors: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

require("modules.monitors")
require("modules.environment")
require("modules.input")
require("modules.look")        -- general / decoration / layout / misc / animations
require("modules.autostart")
require("modules.keybindings")
require("modules.windowrules")
require("modules.gamemode")    -- must stay last: overrides look.lua when active

-- Optional machine-local overrides (not tracked).
local custom = os.getenv("HOME") .. "/.config/hypr/custom.lua"
local f = io.open(custom, "r")
if f then
    f:close()
    dofile(custom)
end
