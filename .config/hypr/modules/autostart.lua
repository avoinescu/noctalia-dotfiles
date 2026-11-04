-- Ported from conf/autostart.conf, conf/cursor.conf and hyprland.conf's
-- trailing exec-once. "hyprland.start" fires once per session (like
-- exec-once), not on every `hyprctl reload`.

hl.on("hyprland.start", function()
    -- Portals need the Wayland env before anything else talks to them.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    hl.exec_cmd("~/.config/hypr/scripts/listeners.sh --startall")
    -- No awww-daemon: Noctalia draws its own wallpaper layer
    -- (namespace "noctalia-wallpaper"). awww mapped a second background
    -- layer above it showing a stale image, hiding every theme/wallpaper
    -- change.
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("~/.config/hypr/scripts/start-quickshell-panels.sh")
    hl.exec_cmd("~/.config/hypr/scripts/gtk.sh")

    -- Start Noctalia and make sure nothing from the retired ml4w/waybar
    -- profile is lingering.
    hl.exec_cmd("~/.config/hypr/scripts/switch-shell-profile.sh")

    hl.exec_cmd("~/.config/hypr/scripts/cleanup.sh")
end)
