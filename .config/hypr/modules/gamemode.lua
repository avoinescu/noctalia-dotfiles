-- Game mode. scripts/gamemode.sh calls `hyprctl eval "activate_gamemode()"`
-- to turn it on and touches ~/.cache/hypr/gamemode-enabled; to turn it off it
-- removes that file and reloads.
--
-- Because this module re-applies game mode on load whenever the flag file
-- exists, game mode now survives `hyprctl reload` (which every theme switch
-- does) -- that's what the old, never-wired-up load-gamemode.sh was for.

function activate_gamemode()
    hl.config({
        animations = { enabled = false },
        decoration = {
            shadow             = { enabled = false },
            blur               = { enabled = false },
            active_opacity     = 1.0,
            inactive_opacity   = 1.0,
            fullscreen_opacity = 1.0,
            rounding           = 0,
        },
        general = {
            gaps_in     = 0,
            gaps_out    = 0,
            border_size = 1,
        },
    })
end

local flag = io.open(os.getenv("HOME") .. "/.cache/hypr/gamemode-enabled", "r")
if flag then
    flag:close()
    activate_gamemode()
end
