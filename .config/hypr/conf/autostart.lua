-- DEAD CODE, currently never executed: Hyprland's Lua-config entry point
-- (~/.config/hypr/hyprland.lua.disabled) is disabled, so nothing ever
-- require()s this file, and hl.on/hl.exec_cmd never run. hyprland.conf
-- instead sources the plain conf/autostart.conf, which execs
-- ~/.config/hypr/scripts/autostart-shell.sh for the shell-profile branch
-- this file was meant to provide. Don't edit here expecting it to take
-- effect -- if the Lua config tree ever gets re-enabled, port this logic
-- back into autostart-shell.sh's approach (reusing switch-shell-profile.sh)
-- rather than reviving the duplicate branching below as-is.
hl.on("hyprland.start", function ()
    local HOME = os.getenv("HOME")

    -- Read wallpaper app setting
    local wallpaper_app = "quickshell"
    local f = io.open(HOME .. "/.config/ml4w/settings/wallpaper-app", "r")
    if f then
        wallpaper_app = f:read("*l"):match("^%s*(.-)%s*$")
        f:close()
    end

    -- Read shell profile setting ("ml4w" or "noctalia"). Noctalia owns its own
    -- bar/notifications/lock, so those don't start when it's the active
    -- profile -- see ~/.config/hypr/scripts/switch-shell-profile.sh.
    local shell_profile = "ml4w"
    local sf = io.open(HOME .. "/.config/ml4w/settings/shell-profile", "r")
    if sf then
        shell_profile = sf:read("*l"):match("^%s*(.-)%s*$")
        sf:close()
    end

    -- Export variables to systemd
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Restart portals so they catch the environment
    hl.exec_cmd("systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")

    -- awww daemon
    hl.exec_cmd("awww-daemon")

    -- Load cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    -- Start listeners
    hl.exec_cmd("~/.config/ml4w/listeners.sh --startall")

    -- Start waybar (ml4w profile only -- Noctalia draws its own bar)
    if shell_profile ~= "noctalia" then
        hl.exec_cmd(HOME .. "/.config/waybar/launch.sh")
    end

    -- Start polkit daemon
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Restore wallpaper (skip for quickshell — handled inside ml4w-autostart)
    if wallpaper_app ~= "quickshell" then
        hl.exec_cmd("~/.config/ml4w/scripts/ml4w-wallpaper-app --restore")
    end

    -- Autostart scripts
    hl.exec_cmd("~/.config/ml4w/scripts/ml4w-autostart > ~/.mydotfiles/ml4w-autostart.log 2>&1")

    -- Load GTK settings
    hl.exec_cmd("~/.config/hypr/scripts/gtk.sh")

    -- Start swaync / hypridle (ml4w profile only -- Noctalia has its own
    -- notification daemon and its own idle/lock screen)
    if shell_profile ~= "noctalia" then
        hl.exec_cmd("swaync")
        hl.exec_cmd("hypridle")
    else
        hl.exec_cmd("noctalia")
    end

    -- Hellsing restriction-release theme scheduler (toggle:
    -- ~/.config/ml4w/settings/hellsing-theme). Runs regardless of profile --
    -- see ~/.config/hypr/scripts/hellsing-scheduler.sh.
    hl.exec_cmd("~/.config/hypr/scripts/hellsing-scheduler.sh > ~/.cache/ml4w/hellsing-scheduler.log 2>&1")

    -- Load cliphist history
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Start autostart cleanup
    hl.exec_cmd("~/.config/hypr/scripts/cleanup.sh")
end)
