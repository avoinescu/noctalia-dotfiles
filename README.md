# noctalia-dotfiles

Personal Noctalia v5 shell config, split out from [`hyprlnd`](../hyprlnd) (the
ml4w-based Hyprland dotfiles) because it isn't part of that repo's ml4w
symlink farm at all -- Noctalia's own config directories were never touched by
ml4w's install.sh, so they get their own repo and their own installer instead
of being force-fit into that one.

Noctalia is now the sole daily-driver shell on this machine. The old `ml4w`
profile (Waybar/swaync/rofi/hypridle) is kept installed but dormant -- a
one-command fallback (`switch-shell-profile.sh ml4w`) rather than something
actively maintained; see [Relationship to hyprlnd](#relationship-to-hyprlnd).

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
  ml4w's full Matugen pipeline (retired along with the rest of ml4w's own
  bar/panels), so the two Quickshell panels with no Noctalia equivalent that
  are still kept around (`PowerWindow`, `AIUsageWindow` -- see
  `hyprlnd`'s `shell.qml`) would otherwise keep showing stale colors.
  Re-runs a scoped Matugen pass for just those, then tells Quickshell to
  reload.
- **`colors_changed`** -- fires on *every* palette resolve, not just a real
  wallpaper change (e.g. `color-scheme-set`). Mirrors the `papirus-icons`
  icon-theme choice from gsettings into `settings.ini` (see the gotcha
  above).

**Second-order gotcha, hit once already**: writing to a shared config file
like `settings.ini` from a hook can wake up something *else* that watches
that file with no idea a "noctalia profile" concept exists. On this machine,
`~/.config/ml4w/listeners/gtk-theme-switcher.sh` was an inotify watcher
(predating Noctalia) that reacted to *any* write to `settings.ini` by
unconditionally relaunching Waybar -- which is exactly how Noctalia
re-resolving its own palette on startup once caused Waybar to reappear
seconds after switching to the `noctalia` profile. First fixed with a
profile-check no-op guard in that listener; since ml4w's own Waybar/swaync
were fully retired, the listener itself is no longer started at all
(`~/.config/ml4w/listeners.sh`, in `hyprlnd`), which is a stronger version of
the same fix. Worth remembering before wiring any *new* hook that writes
into ml4w-shared config.

## Custom themes

Eight hand-built palettes beyond Noctalia's own built-in/wallpaper-derived
schemes. One is scheduled (Hellsing); the other seven are static one-shot
toggles sharing `~/.config/hypr/scripts/custom-theme-lib.sh` (in `hyprlnd`)
for apply/deactivate logic and cross-theme preemption -- a single
`~/.cache/ml4w/active-static-theme` file tracks whichever one (if any) is
on, so turning on any theme cleanly turns off whatever else was active,
including Hellsing (restored -- tier and all -- if it was preempted).

Want to add another one? [**CREATING-A-THEME.md**](CREATING-A-THEME.md) is
a step-by-step walkthrough of the whole process (also documented as a
reusable pattern in `hyprlnd`'s `noctalia-theme` skill).

### Hellsing -- scheduled, 4 tiers

A "Control Art Restriction System": color intensity ramps up through the day
like Alucard's restriction releases, muted brick-red by morning to full
blood-crimson/gold/black by night.

| Tier | Hours | Feel | Sound on transition |
|---|---|---|---|
| `seal` | 06-11 | muted, restrained | None -- the restrained state has no release line to play |
| `release-1` | 11-17 | "Let's go to work." | Real Japanese-dub "Control Art Restriction Systems 3-2-1" release line |
| `release-2` | 17-21 | the hounds are loose | Same clip as release-1 -- the source scene doesn't split into two separate moments |
| `release-true` | 21-06 | all restrictions lifted | Real Japanese-dub "Bird of Hermes" full-power line |

Applies to Noctalia's own palette *and* the two surviving ml4w Quickshell
panels (Power, AI-usage) and Hyprland's window borders (three separate
theming surfaces, kept in sync by one generator). Palettes here:
`palettes/hellsing-*.json`. Everything else -- the poller, the shared apply
logic, the sounds, the Quickshell/Hyprland color files, the wallpaper pool,
the fastfetch logo swap -- lives in `hyprlnd`:

- `~/.config/hypr/scripts/hellsing-lib.sh` -- shared tier-application logic
- `~/.config/hypr/scripts/hellsing-scheduler.sh` -- the 5-minute poller,
  autostarted unconditionally (both shell profiles)
- `~/.config/hypr/scripts/hellsing-theme.sh` -- instant on/off (the poller
  alone means waiting up to 5 minutes to see anything change)
- Toggle file: `~/.config/ml4w/settings/hellsing-theme` (`on`/`off`)

### Static themes -- one-shot, no schedule

Each is a single palette, deliberately not scheduled (a time-of-day
evolution doesn't fit any of these the way it does Hellsing). One-shot
apply/revert script per theme in `hyprlnd`
(`~/.config/hypr/scripts/<id>-theme.sh`), palette here at
`palettes/<id>.json`. Each on/off toggle also fires a themed notification;
quotes are verbatim where the source material has real ones, flavor text
(clearly not claimed as a quote) where it doesn't.

Every theme but Proxima also plays a real sound alongside its
on-notification -- `play_theme_sound` (in `custom-theme-lib.sh`) accepts
either a single `~/.config/hypr/sounds/<id>.mp3` (played every time) or a
`~/.config/hypr/sounds/<id>/` directory of clips (one picked at random each
time), silently skipped if neither exists. Random pools exist where either
multiple takes of the same line were worth keeping (War Thunder) or no
single spoken quote fit and several real in-game lines/music snippets do
(Blood Elves' zone/city theme music, Warframe's community-favorite lines).
Proxima has none -- Mortal Shell II has no findable dialogue at all yet, so
per the no-fake-quotes rule below, it also gets no fake sound.

| Theme | Feel | On-notification | Off-notification | Sound on select |
|---|---|---|---|---|
| `joker` | Purple suit / toxic-green / blood-red on near-black | "Why So Serious? Introduce a little anarchy." | "You wouldn't want to miss the ending." | Heath Ledger's "Why so serious?" line |
| `illidan` | Fel-green energy, demon purple, on near-black | "You are not prepared!" | "The Betrayer stands down." (flavor) | The real in-game "You are not prepared!" line |
| `arthas` | Frostmourne ice-blue, plague green, blood crimson, on near-black navy | "Frostmourne hungers." | "At long last... no king rules forever, my son." -- Terenas Menethil's spirit, as Arthas dies atop Icecrown Citadel | The real in-game Lich King "Frostmourne hungers" voice line |
| `bloodelves` | Gold and crimson with an arcane-green undertone, on deep maroon-black | "Anu belore dela'na! (The sun guides us.)" -- real Thalassian NPC line | "Anar'alah! (By the Light!)" -- real Thalassian NPC line | Random: Eversong Woods or Silvermoon City soundtrack snippet (Burning Crusade) |
| `proxima` | Sacred amber flame, ashen stone, electric-blue lightning accent, on near-black bone | "Harden. Endure. Become the shell." (flavor -- Mortal Shell II released days before this theme was built, no canonical Proxima dialogue was findable yet) | "The shell falls silent once more." (flavor) | None -- no findable dialogue to source from yet |
| `warframe` | Tenno cyan, Orokin gold, void purple, on deep space black | "Tenno... wake up." -- the Lotus, game's intro line | "The Old War is over. But another war... is just beginning." -- the Lotus | Random: one of 4 real in-game/community lines (that exact intro line has no findable clip) |
| `warthunder` | Olive drab, gunmetal gray, tracer orange, on asphalt near-black | "A good pilot can fly anything that flies..." -- real in-game loading-screen hint (no characters to quote) | "Prepare for the next sortie." (flavor) | Random: "Attack the D point" (EN) or "Cible detruite" (FR) real voice comms |

## Theme picker

A rofi menu (`noctalia-theme-picker.sh`, `hyprlnd`) instead of one keybind
per theme -- that stopped scaling once seven static themes plus Hellsing
were in the mix. Deliberately scoped to *only* our own custom themes, not a
general Noctalia scheme picker: no "Wallpaper (auto)", no builtin schemes,
no community palettes -- those are still reachable via Noctalia's own
Settings if wanted. Lists, in order: Hellsing (an "Auto, current tier" entry
plus all four tiers individually as forced previews -- a forced tier
auto-corrects back within 5 minutes if it doesn't match the scheduler's
current-hour tier, since Hellsing's poller doesn't know the difference
between a preview and a real change), then all seven static themes from the
table above.

## Keybinds

| Keybind | Action |
|---|---|
| `Super+Shift+N` | Switch shell profile (`ml4w` ⇄ `noctalia`) |
| `Super+Shift+P` | Open the Noctalia theme picker (rofi menu, noctalia profile only) |
| `Super+Shift+C` | Toggle Noctalia's control center panel (noctalia profile only) |

The theme picker replaced the old dedicated `Super+Shift+J` (Joker) /
`Super+Shift+V` (Hellsing) toggle keybinds -- both are still one click away
as menu entries. All scripts behind these binds live in `hyprlnd` since they
reach into the ml4w-managed hypr config tree; see below.

## Relationship to hyprlnd

`hyprlnd` owns everything that isn't purely Noctalia's own file:

- `~/.config/hypr/scripts/switch-shell-profile.sh` + the `Super+Shift+N`
  keybind -- the profile switcher, now mostly a fallback path back to the
  dormant `ml4w` profile (see below)
- `~/.config/hypr/scripts/hellsing-*.sh` -- the Hellsing scheduler/lib/toggle
  and the ml4w-side (Quickshell/Hyprland) halves of every custom theme
- `~/.config/hypr/scripts/custom-theme-lib.sh` -- shared apply/deactivate
  logic and cross-theme preemption for every static theme
- `~/.config/hypr/scripts/{joker,illidan,arthas,bloodelves,proxima,warframe,warthunder}-theme.sh`
  -- the seven static theme toggles
- `~/.config/hypr/scripts/noctalia-theme-picker.sh` -- the rofi theme picker
- `~/.config/hypr/scripts/gen-theme-colors.py` -- the palette generator used
  in [CREATING-A-THEME.md](CREATING-A-THEME.md)
- `~/.config/hypr/scripts/noctalia-theme-quickshell.sh` and
  `noctalia-sync-icon-theme.sh` -- this repo's two hooks
- `~/.config/matugen/config-quickshell.toml` -- the scoped Matugen config the
  Quickshell hook uses
- `.claude/skills/noctalia-theme/SKILL.md` -- the reusable "how to build a
  Noctalia theme on this setup" writeup

### ml4w decoupling (Noctalia is now the sole daily-driver shell)

ml4w's own bar/panels/theming were retired once the ml4w-vs-noctalia
comparison ran its course, rather than kept as a live, actively-maintained
parallel system. What's left of ml4w in `hyprlnd`, post-decoupling:

- **Kept, extracted from the old ml4w mega-shell**: `~/.config/quickshell/
  {PowerApp,AIUsageApp,CustomTheme}/` + a trimmed `shell.qml` -- the two
  panels with no Noctalia equivalent (a power/session menu, and the
  custom-built AI-usage dropdown Noctalia's own `hyprlnd/ai-usage:bar`
  widget reopens via `qs ipc call ai-usage toggle`), still themed by the
  same `colors.json`/`theme-manager` IPC reload every static theme already
  used. The standalone Quickshell `overview/` (Alt-Tab-style workspace
  switcher, `Ctrl+Tab`) was already independent of the old mega-shell and
  needed no change.
- **Kept, dormant fallback**: `switch-shell-profile.sh`, Waybar (all
  themes), swaync, rofi, hypridle -- installed and switchable
  (`switch-shell-profile.sh ml4w`) but not autostarted or actively
  maintained. Its Matugen-driven re-theming (Waybar/rofi/swaync/gtk3/gtk4
  color templates) was removed along with the rest of the ml4w Quickshell
  layer, so the fallback's colors are frozen at whatever they were the last
  time this pipeline ran, not live-updating with wallpaper changes.
- **Removed entirely**: the ml4w Quickshell Sidebar/Wallpaper-picker/
  Calendar/Welcome panels and the alternate Statusbar/Dock engine
  (redundant with Noctalia's own control-center/OSD/wallpaper-picker,
  confirmed via direct inspection rather than assumption before deleting);
  the separate ml4w Settings app; the ml4w Hyprland Settings app (its one
  load-bearing side effect -- border/gaps values -- baked directly into
  `conf/layouts/default.conf` first); the `gtk-theme-switcher.sh` listener;
  a handful of keybinds/windowrules that pointed at the now-deleted panels.

This repo only owns the files that are purely Noctalia's: `config.toml`,
`palettes/`, and the `ai-usage` plugin.

## Install

```sh
./install.sh
```

Symlinks `.config/noctalia` and `.local/share/noctalia/plugins/ai-usage` into
place, backing up anything already there to `~/.noctalia-dotfiles-backups/`.
