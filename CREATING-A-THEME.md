# Creating a custom theme

A step-by-step walkthrough for adding a new theme like Joker, Illidan, or
Warframe (see the [README](README.md#custom-themes) for the full list).
This covers a **static** theme -- one palette, toggled on/off, no schedule.
If you want something that evolves over time instead (like Hellsing's four
time-of-day tiers), skip to [Scheduled themes instead of static](#scheduled-themes-instead-of-static)
at the end.

You can follow this yourself, or hand it to Claude as a spec ("build a
theme for X using CREATING-A-THEME.md") -- either way the steps and file
locations are the same.

## 0. Pick an id

Lowercase, no spaces, matches a Waybar/Hyprland variable-name-safe string
(e.g. `illidan`, `bloodelves`, `warthunder`). This id is used as the
filename/key everywhere below -- pick it before starting.

## 1. Decide the color story

Six hand-picked colors define the theme (everything else -- containers,
outlines, surface tiers -- gets derived automatically):

| Role | What it should be |
|---|---|
| `primary` / `on_primary` | The single color that says "this is the theme" at a glance, and a high-contrast color to put text/icons on top of it |
| `secondary` / `on_secondary` | A supporting accent color |
| `tertiary` / `on_tertiary` | A highlight color -- a special ability, a specific detail, something that stands out |
| `error` / `on_error` | A red/warning color, distinct in hue from tertiary so error states don't blend in |
| `background` / `on_background` | A near-black tinted toward the theme's mood, and a high-contrast foreground for text on top of it |

Plus two terminal accent colors, `term_blue` and `term_cyan`, for kitty's
ANSI blue/cyan slots (pick anything that fits -- these are minor).

**Why hand-pick instead of generating everything from one seed color**:
Matugen's own dark-mode contrast math keeps `primary` pale and washed out
regardless of how intense the seed is -- it's tuned for readability, not
drama. Hand-picking the six perceptually-important roles above and letting
Matugen fill in everything else (which its contrast math *does* get right)
is the established pattern here.

## 2. Generate the three color files

Write your six pairs (plus the two terminal colors) to a small JSON file:

```json
{
  "primary": "#rrggbb", "on_primary": "#rrggbb",
  "secondary": "#rrggbb", "on_secondary": "#rrggbb",
  "tertiary": "#rrggbb", "on_tertiary": "#rrggbb",
  "error": "#rrggbb", "on_error": "#rrggbb",
  "background": "#rrggbb", "on_background": "#rrggbb",
  "term_blue": "#rrggbb", "term_cyan": "#rrggbb"
}
```

Then run:

```sh
python3 ~/.config/hypr/scripts/gen-theme-colors.py <id> your-colors.json
```

This writes all three files the rest of the system expects:

- `~/.config/ml4w/colors/<id>.json` (Quickshell)
- `~/.config/hypr/colors/<id>.conf` (Hyprland)
- `~/projects/noctalia-dotfiles/.config/noctalia/palettes/<id>.json` (Noctalia)

Requires `matugen` on `PATH` (already installed as part of this setup).

## 3. Source wallpapers

Directory: `~/Pictures/wallpaper/<id>/` (not tracked in git -- same as
every other theme's wallpapers). 3-5 images is plenty; prefer 4K.

Wallhaven's public API needs no auth:

```sh
curl -s "https://wallhaven.cc/api/v1/search?q=<search+term>&categories=100&purity=100&atleast=3840x2160&sorting=favorites&order=desc" \
  | jq -r '.data[].path'
```

Download a few of the returned URLs into the theme's folder as `01.jpg`,
`02.jpg`, etc. If a 4K-only search returns too few hits, drop
`atleast=3840x2160` and accept 1920x1080+ instead rather than leaving the
folder empty.

## 4. Source a logo for fastfetch

Path: `~/.config/fastfetch/assets/<id>-face.png`. A transparent-background
character portrait or logo mark works best. pngegg.com is a good source:
search, open a result's detail page (`/en/png-XXXXX`), and the actual CDN
image URL is embedded there (something like `https://e7.pngegg.com/...png`).

**Required step, learned the hard way**: convert whatever you download to
true 8-bit RGBA before wiring it in --

```sh
magick your-download.png -define png:color-type=6 ~/.config/fastfetch/assets/<id>-face.png
```

Fastfetch's kitty-image rendering silently breaks on 4-bit indexed PNGs
(renders nothing, or a corrupted tiny patch) -- several sourced logos hit
exactly this the first time. Verify with `file`:

```sh
file ~/.config/fastfetch/assets/<id>-face.png
# should say "8-bit/color RGBA" or "8-bit colormap" -- NOT "4-bit colormap"
```

## 5. Write the toggle script

Create `~/.config/hypr/scripts/<id>-theme.sh`:

```bash
#!/usr/bin/env bash
# Static "<Theme Name>" theme -- <one-line color story>.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="<id>"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/<id>"
COLORS_JSON="$HOME/.config/ml4w/colors/<id>.json"
COLORS_CONF="$HOME/.config/hypr/colors/<id>.conf"
LOGO="$HOME/.config/fastfetch/assets/<id>-face.png"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "<App Name>" "<on-quote>" 2>/dev/null || true
else
    deactivate_static_theme "$ID"
    notify-send -a "<App Name>" "<off-quote>" 2>/dev/null || true
fi
```

`apply_static_theme`/`deactivate_static_theme` (from `custom-theme-lib.sh`)
handle the wallpaper swap, the three-surface color sync, the fastfetch logo
swap, and cleanly preempting/restoring Hellsing and whatever other static
theme might be active -- you don't need to touch any of that.

**On the quotes**: use real ones, verbatim, when the source material has
them -- verify the exact wording with a web search rather than trusting
memory, quotes drift. When it doesn't (no characters, or something too new
to have quotable dialogue findable), write clearly-flavor text and say so
in the script's own comment rather than presenting it as a real quote.

**Optional: play a sound alongside the on-notification.** Source a short
clip (myinstants.com is a reliable source for game voice lines -- its pages
embed a direct mp3 URL you can `curl` straight out of the page source; a
soundboard search often turns up multiple takes of the same line, so
listen to more than one candidate before picking), save it to
`~/.config/hypr/sounds/<id>.mp3`, then add one line after the on-branch's
`notify-send`:

```bash
    play_theme_sound "$HOME/.config/hypr/sounds/<id>.mp3"
```

`play_theme_sound` (in `custom-theme-lib.sh`) backgrounds `paplay` and
no-ops if the file doesn't exist, so this is safe to add even before the
sound file itself is in place.

**No single clip fits, or several are worth keeping?** Point `SOUND` at a
*directory* instead of a file (`~/.config/hypr/sounds/<id>/`, one or more
`*.mp3` files inside) -- `play_theme_sound` picks one at random each time
the theme is turned on, no code change needed beyond the path. Good fits:
multiple takes of the same line all worth keeping (War Thunder: EN/FR voice
comms), or no single spoken quote works but several real lines/music
snippets do (Blood Elves: zone/city theme music, since Thalassian NPC lines
aren't cleanly clippable; Warframe: several community-favorite lines, since
the theme's actual on-notification quote has no findable clip).

**No real audio exists at all?** Skip the sound entirely rather than
faking one or substituting an unrelated clip just to have *something* --
same principle as the no-fake-quotes rule above. Proxima (Mortal Shell II)
has none for exactly this reason.

**Spoken dialogue with no clean pre-isolated clip anywhere (myinstants has
nothing, only full cutscenes/compilations exist)?** Don't guess a
timestamp by trimming blind and hoping the wording matches -- pull that
video's captions as text instead of relying on your own ear:

```sh
yt-dlp --skip-download --write-auto-sub --write-sub --sub-lang en \
  --sub-format vtt -o <id>.%(ext)s <video-url>
```

`--write-sub` grabs official manually-authored captions if the video has
them (higher confidence -- sometimes even speaker-labeled, e.g. SWTOR's
"Deceived" trailer); `--write-auto-sub` falls back to YouTube's
auto-generated ones otherwise (still text you can read and grep, not
something guessed by ear). Grep the `.vtt` for a distinctive phrase, read
the surrounding per-word timestamps to find a clean sentence boundary, then
pull audio and trim exactly like the soundtrack case above (`-ss`/`-t`
before `-i`, verify non-silent with `volumedetect`). This is how
Xal'atath's, Yennefer's, Triss's, Tzeentch's, Slaanesh's, Darth Malgus's,
King Arthur: Legion IX's, and Tainted Grail's sounds were sourced -- all
were previously skipped as "no sound" for exactly the ear-verification
problem this solves.

Downloading a short clip of a game's actual soundtrack (not a spoken line)
works the same way but needs a different source than myinstants.com --
search YouTube for the official/OST upload, pull audio with `yt-dlp -x
--audio-format mp3` (a standalone binary from its GitHub releases works
fine, no install needed), then trim a short section:

```sh
ffmpeg -ss <start-seconds> -t 20 -i full-track.mp3 \
  -af "afade=t=in:st=0:d=2,afade=t=out:st=18:d=2" \
  -codec:a libmp3lame -q:a 4 ~/.config/hypr/sounds/<id>/<name>.mp3
```

Put `-ss`/`-t` **before** `-i`, not after -- trimming after `-i` seeks
unreliably on some mp3s and can silently produce a clip with real-looking
duration but no actual audio (caught once by ear, confirmed with `ffmpeg
-af volumedetect -f null /dev/null`, mean/max volume near -90dB). Sanity
check any trimmed clip that way before wiring it in if you can't listen to
it directly.

```sh
chmod +x ~/.config/hypr/scripts/<id>-theme.sh
bash -n ~/.config/hypr/scripts/<id>-theme.sh   # syntax check
```

## 6. Register it in the picker

Add one line to `~/.config/hypr/scripts/noctalia-theme-picker.sh`, in the
`add "..."` list:

```bash
add "<Display Name>"    "$SCRIPTS_DIR/<id>-theme.sh on"
```

## 7. Test it

```sh
~/.config/hypr/scripts/<id>-theme.sh on
# check: wallpaper changed, colors changed (bar/panels/borders), logo shows
# in a fresh fastfetch run, notification fired
cat ~/.cache/ml4w/active-static-theme   # should say <id>

~/.config/hypr/scripts/<id>-theme.sh off
# check: active-static-theme is gone, whatever was running before (Hellsing,
# or nothing) comes back correctly
```

If you have another theme already on, also test switching directly between
them (pick one from the picker, then immediately pick another) -- you
should see only the new theme's on-notification, nothing from Hellsing in
between.

## 8. Document and commit

- Add a row to the theme table in this repo's [README](README.md#static-themes----one-shot-no-schedule).
- Copy the new/changed files from `~/.config/...` into their matching paths
  under `~/projects/hyprlnd/` (everything under `.config/hypr/scripts/`,
  `.config/ml4w/colors/`, `.config/hypr/colors/`, `.config/fastfetch/assets/`,
  `.config/hypr/sounds/` lives in `hyprlnd`, not here).
- Commit `hyprlnd` (the script, colors, logo) and `noctalia-dotfiles` (the
  Noctalia palette JSON, the README update) separately.

## Scheduled themes instead of static

If the theme should evolve over time the way Hellsing does (multiple tiers
keyed to time of day) rather than being a single on/off palette, the shape
is different enough that it's not a variant of the steps above -- see
`hellsing-lib.sh` (shared tier-application logic) and
`hellsing-scheduler.sh` (the poller) in `hyprlnd` as the worked example, and
the "Building an 'evolving' / scheduled theme" section of
`hyprlnd`'s `.claude/skills/noctalia-theme/SKILL.md` for the checklist.
