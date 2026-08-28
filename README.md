# noctalia-dotfiles

Personal Noctalia v5 shell config, split out from [`hyprlnd`](../hyprlnd) (the
ml4w-based Hyprland dotfiles) because it isn't part of that repo's ml4w
symlink farm at all -- Noctalia's own config directories were never touched by
ml4w's install.sh, so they get their own repo and their own installer instead
of being force-fit into that one.

Both `ml4w` and `noctalia` shell profiles currently coexist on this machine so
they can be compared side by side; see [Relationship to hyprlnd](#relationship-to-hyprlnd).

## What's here

```
.config/noctalia/
  config.toml               hand-written bar layout, app theming, widgets
  palettes/
    hellsing-*.json          4 tiers of the scheduled Hellsing theme
    joker.json                the static Joker theme
.local/share/noctalia/plugins/ai-usage/
  plugin.toml, service.luau, bar.luau
```

The whole `.config/noctalia` directory is one symlink into this repo (see
[Install](#install)) -- drop a new palette straight into `palettes/` and it's
already live, no separate copy step.

GUI changes made from Noctalia's own Settings save to
`~/.local/state/noctalia/settings.toml` (not tracked here -- see the
[Noctalia docs](https://docs.noctalia.dev/noctalia/configuration/)) and win
over `config.toml`. If a widget doesn't look right, its own gear icon
(middle-click it) is the fastest fix rather than editing this repo.

## Bar layout

One bar (`[bar.default]`), top, matching Waybar's "starter" theme module list
so switching between profiles is a fair comparison rather than Noctalia's own
defaults:

| Position | Widgets |
|---|---|
| start | launcher, settings, active window |
| center | workspaces |
| end | updates, AI usage, cpu, memory, volume, bluetooth, battery, network, clipboard, caffeine, nightlight, tray, shell profile switcher, control center, session, clock |

Non-obvious widgets:

- **`updates`** -- the community plugin `yuuto/arch-updater`
  (github.com/noctalia-dev/community-plugins), not self-built: pacman + AUR +
  Flatpak, background upgrades with polkit, rollback, history. Replaces
  ml4w's `custom/updates` + `installupdates.sh` for this profile. Reused
  rather than rebuilt because it only orchestrates trusted system
  package-manager tools, unlike anything credential-reading.
- **`ai_usage`** -- our own plugin (`.local/share/noctalia/plugins/ai-usage/`).
  Polls the *same* `waybar-format.sh` script the ml4w Waybar setup already
  uses (`hyprlnd`'s `.config/waybar/scripts/ai-usage/`) rather than
  reimplementing the backend, and a click reopens the existing Quickshell
  `AIUsageWindow` panel via `qs ipc call ai-usage toggle` rather than
  reimplementing the dropdown in Luau. No credential-reading binary of its
  own, same principle as the Waybar module it mirrors.
- **`shell_profile`** -- a `custom_button` running the exact same script as
  Waybar's `custom/shell-profile` button and `$mainMod+SHIFT+N`: flips
  between the `ml4w` and `noctalia` profiles live. Lives in `hyprlnd`, not
  here -- see [Relationship to hyprlnd](#relationship-to-hyprlnd).
- **`cpu` / `memory`** -- Noctalia's builtin `sysmon` widget type, `stat =
  "cpu_usage"` / `"ram_used"` (not an obvious key name from the widget type
  alone).

Deliberately left out (no clean 1:1 Noctalia equivalent yet): the disk/language
pieces of Waybar's `group/hardware`, and `custom/ml4w-welcome` (ML4W-app-specific,
nothing to port it to).

## App theming

Off by default in Noctalia -- a wallpaper/palette change only recolors
Noctalia's own UI unless templates are explicitly enabled:

```toml
[theme.templates]
enable_builtin_templates   = true
builtin_ids                = ["kitty", "gtk3", "gtk4"]
enable_community_templates = true
community_ids               = ["papirus-icons"]
```

- **`kitty` / `gtk3` / `gtk4`** (builtin) -- each one's own `apply.sh` safely
  appends its own include rather than overwriting anything (kitty: `include
  themes/noctalia.conf` at the end of `kitty.conf`, after the existing
  ml4w/Matugen include -- last include wins, so this takes precedence without
  deleting the old one; GTK: an `@import` appended to `gtk.css`).
- **`papirus-icons`** (community) -- recolors the *local* copy of the Papirus
  icon theme's folders to the closest named color for whatever palette is
  active (HSV-weighted hue match against Papirus's ~24 named folder colors),
  and switches Papirus-Dark/Papirus-Light by the palette's surface luminance.
  Requires `papirus-icon-theme` installed (official `extra` repo). Full
  mechanism and its `settings.ini` gotcha (below) documented in
  `hyprlnd`'s `noctalia-theme` skill.

**Gotcha inherited from this machine's GTK setup**: `papirus-icons` only sets
the icon theme via `gsettings`, but `~/.config/hypr/scripts/gtk.sh` pushes
values *from* `gtk-3.0/4.0/settings.ini` *into* gsettings on every login (the
opposite direction) -- so without the `colors_changed` hook below, a
recolored icon theme would silently revert on the next login, and most GTK3
apps (which read `settings.ini` directly) would never see it at all.

## Hooks

```toml
[hooks]
wallpaper_changed = "~/.config/hypr/scripts/noctalia-theme-quickshell.sh $NOCTALIA_WALLPAPER_PATH"
colors_changed     = "~/.config/hypr/scripts/noctalia-sync-icon-theme.sh"
```

Both scripts live in `hyprlnd`, not here (see below), because they reach
outside anything Noctalia owns:

- **`wallpaper_changed`** -- Noctalia's own wallpaper picker never runs
  ml4w's `wallpaper.sh`/Matugen pipeline, so the still-running ml4w
  Quickshell panels (Sidebar, Power, `AIUsageWindow`) would otherwise keep
  showing stale colors. Re-runs a scoped Matugen pass for just those, then
  tells Quickshell to reload.
- **`colors_changed`** -- fires on *every* palette resolve, not just a real
  wallpaper change (e.g. `color-scheme-set`). Mirrors the `papirus-icons`
  icon-theme choice from gsettings into `settings.ini` (see the gotcha
  above).

**Second-order gotcha, hit and fixed once already**: writing to a
shared config file like `settings.ini` from a hook can wake up something
*else* that watches that file with no idea a "noctalia profile" concept
exists. On this machine, `~/.config/ml4w/listeners/gtk-theme-switcher.sh` is
an inotify watcher (predates Noctalia entirely) that reacts to *any* write to
`settings.ini` by unconditionally relaunching Waybar -- which is exactly how
Noctalia re-resolving its own palette on startup once caused Waybar to
reappear seconds after switching to the `noctalia` profile. Fixed in that
listener (in `hyprlnd`) by having it check the shell-profile setting and
no-op under `noctalia`. Worth remembering before wiring any *new* hook that
writes into ml4w-shared config.

## Custom themes

Two hand-built palettes beyond Noctalia's own built-in/wallpaper-derived
schemes, both documented as a reusable pattern in `hyprlnd`'s
`noctalia-theme` skill.

### Hellsing -- scheduled, 4 tiers

A "Control Art Restriction System": color intensity ramps up through the day
like Alucard's restriction releases, muted brick-red by morning to full
blood-crimson/gold/black by night.

| Tier | Hours | Feel |
|---|---|---|
| `seal` | 06-11 | muted, restrained |
| `release-1` | 11-17 | "Let's go to work." |
| `release-2` | 17-21 | the hounds are loose |
| `release-true` | 21-06 | all restrictions lifted |

Applies to Noctalia's own palette *and* the still-running ml4w Quickshell
apps and Hyprland's window borders (three separate theming surfaces, kept in
sync by one generator). Palettes here: `palettes/hellsing-*.json`. Everything
else -- the poller, the shared apply logic, the Quickshell/Hyprland color
files, the wallpaper pool, the fastfetch logo swap -- lives in `hyprlnd`:

- `~/.config/hypr/scripts/hellsing-lib.sh` -- shared tier-application logic
- `~/.config/hypr/scripts/hellsing-scheduler.sh` -- the 5-minute poller,
  autostarted unconditionally (both shell profiles)
- `~/.config/hypr/scripts/hellsing-theme.sh` -- instant on/off (the poller
  alone means waiting up to 5 minutes to see anything change)
- Toggle file: `~/.config/ml4w/settings/hellsing-theme` (`on`/`off`)

### Joker -- static, no schedule

Purple suit / toxic-green hair / blood-red smile on near-black. Deliberately
*not* scheduled -- a time-of-day evolution doesn't make sense for this one,
unlike Hellsing. One-shot apply/revert instead of a poller:
`~/.config/hypr/scripts/joker-theme.sh` (in `hyprlnd`). Palette here:
`palettes/joker.json`.

Since Hellsing's poller and Joker's one-shot script both touch the same
shared resources (fastfetch logo, ml4w `colors.json`, Hyprland
`colors.conf`), each preempts the other's toggle *and* state file directly
before applying, so neither can lose a race to the other within Hellsing's
5-minute poll window. Turning one off restores whatever the other's toggle
was before it was preempted, rather than guessing.

## Keybinds

| Keybind | Action |
|---|---|
| `Super+Shift+N` | Switch shell profile (`ml4w` ⇄ `noctalia`) |
| `Super+Shift+J` | Toggle Joker theme |
| `Super+Shift+C` | Toggle Noctalia's control center panel (noctalia profile only) |
| `Super+Shift+V` | Toggle Hellsing theme (instant, doesn't wait for the poller) |

All three scripts live in `hyprlnd` since they reach into the ml4w-managed
hypr config tree; see below.

## Relationship to hyprlnd

`hyprlnd` owns everything that isn't purely Noctalia's own file:

- `~/.config/hypr/scripts/switch-shell-profile.sh` + the `Super+Shift+N`
  keybind + the Waybar button -- the profile switcher itself
- `~/.config/hypr/scripts/hellsing-*.sh` -- the Hellsing scheduler/lib/toggle
  and the ml4w-side (Quickshell/Hyprland) halves of both custom themes
- `~/.config/hypr/scripts/joker-theme.sh`
- `~/.config/hypr/scripts/noctalia-theme-quickshell.sh` and
  `noctalia-sync-icon-theme.sh` -- this repo's two hooks
- `~/.config/matugen/config-quickshell.toml` -- the scoped Matugen config the
  Quickshell hook uses
- `.claude/skills/noctalia-theme/SKILL.md` -- the reusable "how to build a
  Noctalia theme on this setup" writeup

This repo only owns the files that are purely Noctalia's: `config.toml`,
`palettes/`, and the `ai-usage` plugin.

## Install

```sh
./install.sh
```

Symlinks `.config/noctalia` and `.local/share/noctalia/plugins/ai-usage` into
place, backing up anything already there to `~/.noctalia-dotfiles-backups/`.
