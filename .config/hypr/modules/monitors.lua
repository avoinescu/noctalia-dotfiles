-- Ported from conf/monitors/default.conf

hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0",    scale = 1 })
hl.monitor({ output = "DP-2", mode = "3440x1440@144", position = "2560x0", scale = 1 })

-- Anything else that gets plugged in.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
