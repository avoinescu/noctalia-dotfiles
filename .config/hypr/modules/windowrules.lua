-- Ported from conf/ml4w.conf (windowrule blocks).
-- The swaync layerrules there were dropped: swaync is retired (masked by
-- switch-shell-profile.sh), Noctalia owns notifications now.

local function floating(name, class, size, pin)
    hl.window_rule({
        name   = name,
        match  = { class = class },
        float  = true,
        center = true,
        pin    = pin or nil,
        size   = size,
    })
end

floating("pavucontrol",          "(.*org.pulseaudio.pavucontrol.*)",  "700 600",  true)
floating("waypaper",             "(.*waypaper.*)",                     "900 700",  true)
floating("newelle",              "(io.github.qwersyk.Newelle)",        "1000 700", true)
floating("blueman-manager",      "(blueman-manager)",                  "800 600")
floating("nwg-look",             "(nwg-look)",                         "700 600")
floating("nwg-displays",         "(nwg-displays)",                     "900 600")
floating("missioncenter",        "(io.missioncenter.MissionCenter)",   "900 600",  true)
floating("gnome-calculator",     "(org.gnome.Calculator)",             "700 600")
floating("hyprland-share-picker","(hyprland-share-picker)",            "600 400",  true)
floating("nm-connection-editor", "(nm-connection-editor)",             "800 700")
floating("dotfiles-floating",    "(dotfiles-floating)",                "1000 700")
floating("dotfiles-sidepad",     "(dotfiles-sidepad)",                 "1000 700", true)

hl.window_rule({
    name   = "Picture-in-Picture",
    match  = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float  = true,
    pin    = true,
    center = true,
})
