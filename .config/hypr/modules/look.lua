-- Ported from conf/windows/default.conf, conf/decorations/default.conf,
-- conf/layouts/default.conf, conf/misc.conf and conf/animations/standard.conf.

local c = require("modules.colors")

hl.config({
    general = {
        -- windows/default.conf set gaps 10/20, but layouts/default.conf was
        -- sourced after it and zeroed them -- 0 is what you actually had.
        gaps_in         = 0,
        gaps_out        = 0,
        gaps_workspaces = 0,
        border_size     = 2,
        col = {
            active_border   = { colors = { c.primary, c.on_primary }, angle = 90 },
            inactive_border = c.on_primary,
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding           = 10,
        active_opacity     = 1.0,
        inactive_opacity   = 0.9,
        fullscreen_opacity = 1.0,
        blur = {
            enabled           = true,
            size              = 4,
            passes            = 4,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = true,
        },
        shadow = {
            enabled      = true,
            range        = 32,
            render_power = 2,
            color        = "rgba(00000050)",
        },
    },

    dwindle = {
        preserve_split = true,
    },

    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        initial_workspace_tracking = 1,
        on_focus_under_fullscreen  = 1,
        allow_session_lock_restore = true,
    },

    animations = {
        enabled = true,
    },
})

-- animations/standard.conf
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })
