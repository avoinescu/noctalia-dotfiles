-- Ported from conf/keybindings/default.conf.
-- `description` feeds scripts/keybindings.sh (reads `hyprctl binds -j`).

local mainMod = "SUPER"
local S       = "~/.config/hypr/scripts/"

local function bind(keys, dispatcher, desc, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(keys, dispatcher, opts)
end

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

local function m(keys) return mainMod .. " + " .. keys end

-- Applications
bind(m("RETURN"), exec("~/.config/hypr/settings/terminal.sh"), "Open the terminal")
bind(m("B"),      exec("~/.config/hypr/settings/browser.sh"),  "Open the browser")
bind(m("E"),      exec("~/.config/hypr/settings/filemanager"), "Open the filemanager")
bind(m("CTRL + E"), exec("noctalia msg panel-open launcher /emo"), "Open the emoji picker (Noctalia launcher)")
bind(m("CTRL + C"), exec("noctalia msg panel-open launcher"),      "Open the launcher / calculator")

-- Display zoom (was a `hyprctl keyword` + awk one-liner; `keyword` no longer exists)
local function zoom(delta)
    return function()
        local z = hl.get_config("cursor.zoom_factor") or 1.0
        z = math.max(1.0, z + delta)
        hl.config({ cursor = { zoom_factor = z } })
    end
end
bind(m("SHIFT + mouse_down"), zoom(0.5),  "Increase display zoom")
bind(m("SHIFT + mouse_up"),   zoom(-0.5), "Decrease display zoom")
bind(m("SHIFT + Z"), function() hl.config({ cursor = { zoom_factor = 1.0 } }) end, "Reset display zoom")

-- Windows
bind(m("Q"),         hl.dsp.window.close(), "Kill active window")
bind(m("SHIFT + Q"), exec("hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"), "Quit active window and all open instances")
bind(m("F"),         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Set active window to fullscreen")
bind(m("M"),         hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }), "Maximize window")
bind(m("T"),         hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(m("SHIFT + T"), exec(S .. "toggle-workspace-float.sh"), "Float all windows")
bind(m("ALT + T"), function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.pin())
end, "Toggle active window into floating + pinned mode")
bind(m("J"), hl.dsp.layout("togglesplit"), "Toggle split")
bind(m("K"), hl.dsp.layout("swapsplit"),   "Swapsplit")
bind(m("G"), hl.dsp.group.toggle(),        "Toggle window group")

for _, d in ipairs({ "left", "right", "up", "down" }) do
    bind(m(d),           hl.dsp.focus({ direction = d }),        "Move focus " .. d)
    bind(m("ALT + " .. d), hl.dsp.window.swap({ direction = d }), "Swap tiled window " .. d)
end

bind(m("mouse:272"), hl.dsp.window.drag(),   "Move window with the mouse",   { mouse = true })
bind(m("mouse:273"), hl.dsp.window.resize(), "Resize window with the mouse", { mouse = true })

bind(m("SHIFT + right"), hl.dsp.window.resize({ x = 100,  y = 0,    relative = true }), "Increase window width with keyboard")
bind(m("SHIFT + left"),  hl.dsp.window.resize({ x = -100, y = 0,    relative = true }), "Reduce window width with keyboard")
bind(m("SHIFT + down"),  hl.dsp.window.resize({ x = 0,    y = 100,  relative = true }), "Increase window height with keyboard")
bind(m("SHIFT + up"),    hl.dsp.window.resize({ x = 0,    y = -100, relative = true }), "Reduce window height with keyboard")

-- Was two `binde = ALT,Tab` lines (cyclenext, then bringactivetotop)
bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, "Cycle between windows", { repeating = true })

-- Actions
bind(m("CTRL + R"),  hl.dsp.reload_config(),                 "Reload Hyprland configuration")
bind(m("SHIFT + R"), exec(S .. "loadconfig.sh"),             "Reload hyprland config")
bind(m("SHIFT + A"), exec(S .. "toggle-animations.sh"),      "Toggle animations")
bind(m("PRINT"),     exec(S .. "screenshot.sh"),             "Take a screenshot")
bind(m("ALT + F"),   exec(S .. "screenshot.sh --instant"),   "Take an instant full-screen screenshot")
bind(m("ALT + S"),   exec(S .. "screenshot.sh --instant-area"), "Take an instant area screenshot")
bind(m("ALT + A"),   exec(S .. "text-extractor.sh"),         "Extract text from an area")
bind(m("CTRL + P"),  exec("qs ipc call power toggle"),       "Start Power Menu")
bind(m("SHIFT + W"), exec("noctalia msg wallpaper-random"),  "Change the wallpaper")
bind(m("CTRL + W"),  exec("noctalia msg settings-open wallpaper"), "Open wallpaper selector")
bind(m("R"),         exec(S .. "launcher.sh"),               "Open application launcher")
bind(m("CTRL + K"),  exec(S .. "keybindings.sh"),            "Show keybindings")
bind(m("SHIFT + P"), exec("qs ipc call theme-picker toggle"), "Pick a custom theme")
bind(m("SHIFT + B"), exec("qs ipc call book-alerts toggle"),  "Toggle Book Alerts panel")
bind(m("SHIFT + C"), exec("noctalia msg panel-toggle control-center"), "Toggle Noctalia control center")
bind(m("V"),         exec("noctalia msg panel-toggle clipboard"),      "Open clipboard manager")
bind(m("SHIFT + M"), exec("noctalia msg theme-mode-toggle"),           "Toggle light/dark mode")
bind(m("ALT + G"),   exec(S .. "gamemode.sh"),                         "Toggle game mode")
bind(m("CTRL + L"),  exec("pidof hyprlock || hyprlock"),               "Lock Screen")
bind(m("SHIFT + H"), exec("noctalia msg nightlight-force-toggle"),     "Toggle night light")
bind("CTRL + Tab",   exec("qs -p $HOME/.config/quickshell/overview ipc call overview toggle"), "Open Select Window Menu")

-- Sidepad
bind(m("CTRL + right"), exec(S .. "sidepad-dispatch.sh"),          "Open Sidepad")
bind(m("CTRL + left"),  exec(S .. "sidepad-dispatch.sh --hide"),   "Close Sidepad")
bind(m("S"),            exec(S .. "sidepad-dispatch.sh --init"),   "Init Sidepad")
bind(m("SHIFT + S"),    exec(S .. "sidepad-dispatch.sh --select"), "Select Sidepad")

-- Workspaces
for i = 1, 10 do
    local key = tostring(i % 10) -- workspace 10 is on key 0
    bind(m(key),              hl.dsp.focus({ workspace = i }),        "Open workspace " .. i)
    bind(m("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }), "Move active window to workspace " .. i)
    bind(m("CTRL + " .. key),  exec(S .. "moveTo.sh " .. i),          "Move all windows to workspace " .. i)
end
bind(m("Tab"),         hl.dsp.focus({ workspace = "m+1" }),   "Open next workspace")
bind(m("SHIFT + Tab"), hl.dsp.focus({ workspace = "m-1" }),   "Open previous workspace")
bind(m("mouse_down"),  hl.dsp.focus({ workspace = "e+1" }),   "Open next workspace")
bind(m("mouse_up"),    hl.dsp.focus({ workspace = "e-1" }),   "Open previous workspace")
bind(m("CTRL + down"), hl.dsp.focus({ workspace = "empty" }), "Open the next empty workspace")

-- Hardware keys
bind("XF86MonBrightnessUp",   exec("brightnessctl -q s +10%"), "Increase brightness by 10%")
bind("XF86MonBrightnessDown", exec("brightnessctl -q s 10%-"), "Reduce brightness by 10%")
bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Increase volume by 5%", { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      "Reduce volume by 5%",   { locked = true, repeating = true })
bind("XF86AudioMute",    exec("pactl set-sink-mute @DEFAULT_SINK@ toggle"),     "Toggle mute")
bind("XF86AudioPlay",    exec("playerctl play-pause"), "Audio play pause")
bind("XF86AudioPause",   exec("playerctl pause"),      "Audio pause")
bind("XF86AudioNext",    exec("playerctl next"),       "Audio next")
bind("XF86AudioPrev",    exec("playerctl previous"),   "Audio previous")
bind("XF86AudioMicMute", exec("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), "Toggle microphone")
bind("XF86Calculator",   exec("noctalia msg panel-open launcher"), "Open calculator")
-- XF86Lock was dropped: 0.57 rejects it as an unknown key (hyprlang silently
-- ignored it, so it never worked). SUPER+CTRL+L still locks.
bind("code:238", exec("brightnessctl -d smc::kbd_backlight s +10"), "Keyboard backlight up")
bind("code:237", exec("brightnessctl -d smc::kbd_backlight s 10-"), "Keyboard backlight down")
