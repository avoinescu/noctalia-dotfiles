# noctalia-dotfiles

Personal Noctalia v5 shell config, split out from [`hyprlnd`](../hyprlnd) (the
ml4w-based Hyprland dotfiles) because it isn't part of that repo's ml4w
symlink farm at all -- Noctalia's own config directories were never touched by
ml4w's install.sh, so they get their own repo and their own installer instead
of being force-fit into that one.

## What's here

- `.config/noctalia/config.toml` -- hand-written bar layout, app-theming
  (`[theme.templates]`), and widget settings. GUI changes made from Noctalia's
  own Settings save to `~/.local/state/noctalia/settings.toml` (not tracked
  here -- see [docs](https://docs.noctalia.dev/noctalia/configuration/)) and
  win over this file.
- `.local/share/noctalia/plugins/ai-usage/` -- a small self-owned bar plugin:
  polls the same `waybar-format.sh` script the ml4w Waybar setup uses (in
  `hyprlnd`, at `.config/waybar/scripts/ai-usage/`), and a click reopens the
  existing Quickshell `AIUsageWindow` panel over `qs ipc call ai-usage
  toggle`. No separate credential-reading binary, same principle as the
  Waybar module it mirrors.

## Relationship to hyprlnd

Both `ml4w` and `noctalia` shell profiles currently coexist on this machine,
toggled live by `~/.config/hypr/scripts/switch-shell-profile.sh` (tracked in
`hyprlnd`, since it lives inside the ml4w-managed hypr config tree). That
script and the Hyprland/Waybar wiring around it stay in `hyprlnd` -- this repo
only owns the files that are purely Noctalia's.

## Install

```sh
./install.sh
```

Symlinks `.config/noctalia` and `.local/share/noctalia/plugins/ai-usage` into
place, backing up anything already there to `~/.noctalia-dotfiles-backups/`.
