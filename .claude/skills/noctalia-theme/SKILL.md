---
name: noctalia-theme
description: Build a custom Noctalia v5 color theme (static palette or time-based/evolving), and keep it in sync with any still-running ml4w Quickshell apps. Use when the user wants a new Noctalia look, a themed palette, or a scheduled/evolving theme.
---

# Noctalia custom theming

Noctalia v5 is a standalone native shell (not Quickshell), with its own color
engine and app-theming system. This covers building a custom static palette,
making it evolve over time, and the one real gotcha: it won't touch anything
outside itself unless you wire that up explicitly.

## Custom palette file format

Location: `~/.config/noctalia/palettes/<name>.json`. Select it with:

```toml
# ~/.config/noctalia/config.toml, or via:
# noctalia msg color-scheme-set custom <name>
```

Shape — a `dark` key (required) and optional `light` key (falls back to
`dark` if omitted), each with 16 Material-style roles plus a `terminal` block:

```json
{
  "dark": {
    "mPrimary": "#e01530", "mOnPrimary": "#fdf4dc",
    "mSecondary": "#e6b325", "mOnSecondary": "#120b04",
    "mTertiary": "#a3122e", "mOnTertiary": "#fdf0e4",
    "mError": "#ff2f3a", "mOnError": "#170404",
    "mSurface": "#090606", "mOnSurface": "#f7e8c9",
    "mSurfaceVariant": "#2a1414", "mOnSurfaceVariant": "#e8c98a",
    "mOutline": "#9c1f2e", "mShadow": "#000000",
    "mHover": "#1e1112", "mOnHover": "#f7e8c9",
    "terminal": {
      "background": "#090606", "foreground": "#f7e8c9",
      "cursor": "#e01530", "cursorText": "#090606",
      "selectionBg": "#e01530", "selectionFg": "#fdf4dc",
      "normal":  { "black": "#000000", "red": "#e01530", "green": "#6b7a3a", "yellow": "#e6b325", "blue": "#4a5a8a", "magenta": "#a3122e", "cyan": "#4a7a7a", "white": "#f7e8c9" },
      "bright":  { "black": "#3a2020", "red": "#ff4050", "green": "#8b9a5a", "yellow": "#f0c840", "blue": "#7a8aca", "magenta": "#c04060", "cyan": "#6a9a9a", "white": "#fff0d0" }
    }
  }
}
```

Apply and verify:

```sh
noctalia msg config-reload            # if referenced from config.toml
noctalia msg color-scheme-set custom <name>
grep -A6 '^\[theme\]' ~/.local/state/noctalia/settings.toml   # source="custom", custom_palette="<name>"
```

## App theming (kitty, GTK, etc.) is opt-in

Wallpaper/palette changes only recolor Noctalia's own UI by default — nothing
else. To also theme other apps, add to `config.toml`:

```toml
[theme.templates]
enable_builtin_templates = true
builtin_ids = ["kitty", "gtk3", "gtk4"]   # noctalia theme --list-templates for the full catalog
```

Each builtin template's own `apply.sh` (under `/usr/share/noctalia/assets/templates/<id>/`)
self-wires into the target app safely — e.g. kitty's appends
`include themes/noctalia.conf` to the end of `kitty.conf` rather than
overwriting it, so it coexists with an existing Matugen-based include (last
include wins in kitty, so Noctalia's takes precedence without deleting the
old one). Force a render without waiting for a real change:
`noctalia msg templates-apply`.

## Folder icons that match the palette

Beyond kitty/GTK colors, a theme can also recolor the GTK folder icon set
via the `papirus-icons` community template (`noctalia theme --list-templates`
lists it under category `system`). Enable it like a builtin template but in
the community namespace:

```toml
[theme.templates]
enable_community_templates = true
community_ids = ["papirus-icons"]
```

Requires `papirus-icon-theme` installed (official `extra` repo, not AUR —
`sudo pacman -S papirus-icon-theme`; needs a real terminal for the sudo
password prompt, not this session's shell). On each palette resolve it:

1. Computes an HSV-weighted (hue-dominant) nearest match between the
   palette's primary/source color and Papirus's ~24 named folder colors
   (`red`, `carmine`, `magenta`, etc.).
2. Recolors the user's *local* copy of Papirus/Papirus-Dark/Papirus-Light
   (`~/.local/share/icons/`, copied from `/usr/share/icons/` on first run)
   via a bundled `papirus-folders` script — the system package itself is
   never touched.
3. Picks Papirus-Dark vs Papirus-Light by the palette's surface-color
   luminance and calls `gsettings set org.gnome.desktop.interface
   icon-theme <variant>`.

**Gotcha**: step 3 only writes gsettings/dconf. If GTK settings on this
machine follow the sway-wiki settings.ini pattern (`~/.config/hypr/scripts/
gtk.sh` pushes values *from* `gtk-3.0/4.0/settings.ini` *into* gsettings on
every login — the opposite direction), the recolored theme silently
reverts on the next login, and GTK3 apps reading settings.ini directly
never see it at all. Fix by mirroring gsettings back into both
`settings.ini` files on Noctalia's `colors_changed` hook — see
`~/projects/hyprlnd/.config/hypr/scripts/noctalia-sync-icon-theme.sh`. Test
the direction on any given machine before assuming this gotcha applies:
`grep icon-theme ~/.config/gtk-3.0/settings.ini` before and after
`noctalia msg templates-apply` tells you immediately.

**Second-order gotcha**: writing `settings.ini` at all can wake up other,
unrelated things that watch that file. On this setup,
`~/.config/ml4w/listeners/gtk-theme-switcher.sh` is an inotify watcher
(predates and knows nothing about the noctalia profile) that reacts to
*any* write to `settings.ini` by unconditionally relaunching waybar and
re-running Matugen from the wallpaper -- exactly the both-bars-visible bug
this caused the first time `noctalia-sync-icon-theme.sh` fired under the
noctalia profile (Noctalia re-resolving its palette on its own startup was
enough). Before writing any shared config file from a Noctalia hook,
`grep -rl "$FILE_BASENAME" ~/.config/ml4w/listeners/ ~/.config/hypr/scripts/`
to check who else watches it, and gate their reaction on
`~/.config/ml4w/settings/shell-profile` if so -- see
`~/projects/hyprlnd/.config/ml4w/listeners/gtk-theme-switcher.sh`'s
`apply_theme()` for the pattern.

## Hooks: reaching things Noctalia doesn't own

`[hooks]` in `config.toml` runs a shell command on specific events —
`wallpaper_changed` (exposes `$NOCTALIA_WALLPAPER_PATH`/`$NOCTALIA_WALLPAPER_CONNECTOR`)
and `colors_changed` (fires after every palette resolve, including a
`color-scheme-set` call, not just wallpaper — no special env vars). This is
the escape hatch for anything the builtin/community template catalog doesn't
cover — e.g. re-running a scoped Matugen pass to feed a still-running,
non-Noctalia Quickshell app that reads its own `colors.json`. See
`~/projects/hyprlnd/.config/hypr/scripts/noctalia-theme-quickshell.sh` and
its matching `~/.config/matugen/config-quickshell.toml` (a trimmed Matugen
config with only the templates that Quickshell app still reads) for the
worked example.

## Building an "evolving" / scheduled theme

Noctalia's own `mode = "auto"` only does a binary dark/light switch off
sunrise/sunset (via the location service) — there's no builtin multi-stage
scheduler. For more than two stages (e.g. a themed "intensity ramps up
through the day" effect), write your own:

1. Design N palettes as JSON (above), one per stage.
2. A poller script (5-minute `sleep` loop is fine — more robust across
   suspend/resume than computing an exact sleep-until, and cheap): map
   current time to a stage, compare against a state file, and if it
   changed, run `noctalia msg color-scheme-set custom <stage-name>` (+ any
   hook-equivalent work for other apps) and update the state file.
3. Autostart the poller once (Hyprland `exec-once`/`hl.exec_cmd`, or a
   systemd user unit) — not per-login-per-profile, since it should run
   regardless of which shell profile is active if it's also feeding
   non-Noctalia apps.
4. Gate it behind a simple on/off toggle file so it's a one-line disable,
   e.g. `~/.config/ml4w/settings/<name>-theme` containing `on`/`off`.
5. Enable `papirus-icons` (see above) so folder icons track the palette too
   — it's automatic per-palette once enabled, no per-stage work needed.

Full worked example: `~/projects/hyprlnd/.config/hypr/scripts/hellsing-scheduler.sh`
(a 4-stage Hellsing-inspired palette keyed to time of day) plus its generator
script pattern — write one Python/shell script that derives *both* the
Noctalia palette JSON and any other app's color file from one shared
per-stage color definition, so the two never drift apart. Don't hand-pick
values Material's own contrast math already gets right (containers, outline,
surface tiers) — `matugen color hex "#<seed>" -m dark -t scheme-content -j hex`
gives a correctly-contrasted full role set from just a seed color to use as a
scaffold, then override only the perceptually-important roles
(primary/secondary/tertiary/background + their `on_*` pairs) by hand for the
dramatic effect you actually want.

**Gotcha:** matugen's `-t scheme-expressive` (and `rainbow`/`fruit-salad`)
deliberately rotate the palette hue *away* from the seed color — that's the
scheme's whole point, not a bug. If you want the generated colors to actually
resemble your seed hex, use `scheme-content`, `scheme-fidelity`, or
`scheme-tonal-spot` instead.

## Building a static (one-shot) theme

Not every custom theme should evolve over time (a scheduled Hellsing-style
ramp doesn't make sense for, say, a single character or game's aesthetic).
The full walkthrough (color picking, palette generation via
`gen-theme-colors.py`, wallpaper/logo sourcing, the fastfetch 4-bit-PNG
gotcha, testing, docs) is written up step by step in
`~/projects/noctalia-dotfiles/CREATING-A-THEME.md` -- follow that directly
when asked to build one; the summary below is just the toggle-script shape.
Skip the poller entirely and write a one-shot apply/revert script sourcing
`~/projects/hyprlnd/.config/hypr/scripts/custom-theme-lib.sh`:

```bash
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"
ID="mytheme"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/mytheme"
COLORS_JSON="$HOME/.config/ml4w/colors/mytheme.json"
COLORS_CONF="$HOME/.config/hypr/colors/mytheme.conf"
LOGO="$HOME/.config/fastfetch/assets/mytheme-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"
TARGET="${1:-}"
[ -z "$TARGET" ] && { [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"; }

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "My Theme" "A fitting on-quote." 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "My Theme" "A fitting off-quote." 2>/dev/null || true
fi
```

`apply_static_theme`/`deactivate_static_theme` handle the three-surface sync
(Noctalia palette, ml4w Quickshell `colors.json`, Hyprland `colors.conf`),
the wallpaper swap, and the fastfetch logo swap. Generate the three color
files the same way as a scheduled theme's stages (matugen scaffold + hand
overrides for primary/secondary/tertiary/background) — see
`~/projects/hyprlnd/.claude/skills/noctalia-theme/` example generator
scripts referenced above; for several themes at once, one Python script with
a `{theme_id: {overrides...}}` dict beats N near-duplicate scripts.

**Why a shared lib and not pairwise preemption**: the very first two static
themes (Joker, Hellsing-as-a-toggle) preempted each other directly by name
(`joker-theme.sh` writing Hellsing's toggle file, and vice versa). That
stops scaling almost immediately — N themes means N-1 preemption
relationships each. `custom-theme-lib.sh` replaces this with a single
`~/.cache/ml4w/active-static-theme` file naming whichever static theme (if
any) is currently on; turning a new one on looks up and turns off whatever
name is in that file, and turning it off restores Hellsing's toggle
(including re-applying its current tier immediately, not waiting for the
poller) if this theme had preempted it. Every static theme script — and
Hellsing's own "on" path, via `deactivate_active_static_theme` — goes
through this, so adding theme N+1 costs zero new preemption code.

**Real quotes, sourced not invented**: when the source material has actual
character/game quotes, use them verbatim (verify wording via web search
rather than trusting memory — quotes drift). When it doesn't (a vehicle
sim with no characters, or a franchise too new/niche to have quotable
dialogue findable), say so in the script's own comment rather than
presenting invented flavor text as a real quote.

## Hard rule: `matugen color hex` argument order

The value comes before the flags: `matugen color hex "#rrggbb" -m dark -t
scheme-content ...`. `matugen color <hex>` (skipping the `hex` subcommand)
fails with "unrecognized subcommand" — easy to miss since the top-level
`--help` doesn't show the `hex`/`rgb`/`hsl` subcommands of `color` at a
glance.
