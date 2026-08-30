#!/usr/bin/env python3
"""Generate a custom theme's three color files from six hand-picked color
pairs, using a matugen scaffold for the supporting roles (containers,
outlines, surface tiers) that Material's own contrast math already gets
right. See ~/projects/noctalia-dotfiles/CREATING-A-THEME.md for the full
theme-creation walkthrough this is step 2 of.

Usage:
    gen-theme-colors.py <theme-id> <colors.json>

<colors.json> must have exactly these keys (all hex strings, "#rrggbb"):
    primary, on_primary
    secondary, on_secondary
    tertiary, on_tertiary
    error, on_error
    background, on_background
    term_blue, term_cyan

Writes:
    ~/.config/ml4w/colors/<theme-id>.json               (Quickshell)
    ~/.config/hypr/colors/<theme-id>.conf                (Hyprland)
    ~/projects/noctalia-dotfiles/.config/noctalia/palettes/<theme-id>.json

Requires `matugen` on PATH.
"""
import json
import subprocess
import sys
from pathlib import Path

REQUIRED_KEYS = [
    "primary", "on_primary", "secondary", "on_secondary",
    "tertiary", "on_tertiary", "error", "on_error",
    "background", "on_background", "term_blue", "term_cyan",
]

QUICKSHELL_DIR = Path.home() / ".config/ml4w/colors"
HYPRLAND_DIR = Path.home() / ".config/hypr/colors"
NOCTALIA_DIR = Path.home() / "projects/noctalia-dotfiles/.config/noctalia/palettes"


def hx(c):
    c = c.lstrip('#')
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    ar, ag, ab = hx(a)
    br, bg, bb = hx(b)
    r = round(ar + (br - ar) * t)
    g = round(ag + (bg - ag) * t)
    bl = round(ab + (bb - ab) * t)
    return f"#{r:02x}{g:02x}{bl:02x}"


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    theme_id, colors_path = sys.argv[1], sys.argv[2]

    with open(colors_path) as f:
        c = json.load(f)

    missing = [k for k in REQUIRED_KEYS if k not in c]
    if missing:
        print(f"Missing keys in {colors_path}: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

    PRIMARY, ON_PRIMARY = c["primary"], c["on_primary"]
    SECONDARY, ON_SECONDARY = c["secondary"], c["on_secondary"]
    TERTIARY, ON_TERTIARY = c["tertiary"], c["on_tertiary"]
    ERROR, ON_ERROR = c["error"], c["on_error"]
    BACKGROUND, ON_BACKGROUND = c["background"], c["on_background"]
    TERM_BLUE, TERM_CYAN = c["term_blue"], c["term_cyan"]

    # matugen's own dark-mode contrast math keeps "primary" pale/washed out
    # regardless of seed intensity -- that's why every perceptually-important
    # role above is hand-picked rather than trusted from this scaffold. Only
    # the supporting roles (containers, outlines, surface tiers) come from it.
    result = subprocess.run(
        ["matugen", "color", "hex", PRIMARY, "-t", "scheme-content", "-j", "hex"],
        capture_output=True, text=True, check=True,
    )
    scaffold, _ = json.JSONDecoder().raw_decode(result.stdout)
    colors = {k: v["dark"]["color"] for k, v in scaffold["colors"].items()}

    colors.update({
        "primary": PRIMARY, "on_primary": ON_PRIMARY,
        "secondary": SECONDARY, "on_secondary": ON_SECONDARY,
        "tertiary": TERTIARY, "on_tertiary": ON_TERTIARY,
        "error": ERROR, "on_error": ON_ERROR,
        "background": BACKGROUND, "on_background": ON_BACKGROUND,
        "surface": BACKGROUND, "on_surface": ON_BACKGROUND,
        "surface_dim": BACKGROUND, "surface_bright": mix(BACKGROUND, ON_BACKGROUND, 0.35),
        "surface_container_lowest": mix(BACKGROUND, "#000000", 0.3),
        "surface_container_low": BACKGROUND,
        "surface_container": mix(BACKGROUND, PRIMARY, 0.08),
        "surface_container_high": mix(BACKGROUND, PRIMARY, 0.16),
        "surface_container_highest": mix(BACKGROUND, PRIMARY, 0.24),
        "surface_variant": mix(BACKGROUND, PRIMARY, 0.12),
        "on_surface_variant": mix(ON_BACKGROUND, PRIMARY, 0.15),
        "outline": mix(PRIMARY, BACKGROUND, 0.35),
        "outline_variant": mix(PRIMARY, BACKGROUND, 0.65),
        "primary_container": mix(PRIMARY, BACKGROUND, 0.55),
        "on_primary_container": mix(ON_PRIMARY, PRIMARY, 0.2),
        "secondary_container": mix(SECONDARY, BACKGROUND, 0.65),
        "on_secondary_container": mix(ON_SECONDARY, SECONDARY, 0.15),
        "tertiary_container": mix(TERTIARY, BACKGROUND, 0.55),
        "on_tertiary_container": mix(ON_TERTIARY, TERTIARY, 0.2),
        "error_container": mix(ERROR, BACKGROUND, 0.55),
        "on_error_container": mix(ON_ERROR, ERROR, 0.2),
        "source_color": PRIMARY,
        "surface_tint": PRIMARY,
        "inverse_surface": ON_BACKGROUND,
        "inverse_on_surface": mix(BACKGROUND, "#000000", 0.2),
        "inverse_primary": mix(PRIMARY, "#000000", 0.35),
        "scrim": "#000000",
        "shadow": "#000000",
    })
    colors["term_blue"] = TERM_BLUE
    colors["term_cyan"] = TERM_CYAN

    QUICKSHELL_DIR.mkdir(parents=True, exist_ok=True)
    HYPRLAND_DIR.mkdir(parents=True, exist_ok=True)
    NOCTALIA_DIR.mkdir(parents=True, exist_ok=True)

    # --- Quickshell colors.json ---
    qs_path = QUICKSHELL_DIR / f"{theme_id}.json"
    with open(qs_path, "w") as f:
        json.dump(colors, f, indent=4, sort_keys=True)
        f.write("\n")

    # --- Hyprland colors.conf ---
    hypr_path = HYPRLAND_DIR / f"{theme_id}.conf"
    with open(hypr_path, "w") as f:
        for k in sorted(colors.keys()):
            f.write(f"${k} = rgba({colors[k].lstrip('#')}ff)\n")

    # --- Noctalia custom palette ---
    noctalia = {
        "dark": {
            "mPrimary": PRIMARY, "mOnPrimary": ON_PRIMARY,
            "mSecondary": SECONDARY, "mOnSecondary": ON_SECONDARY,
            "mTertiary": TERTIARY, "mOnTertiary": ON_TERTIARY,
            "mError": ERROR, "mOnError": ON_ERROR,
            "mSurface": BACKGROUND, "mOnSurface": ON_BACKGROUND,
            "mSurfaceVariant": colors["surface_variant"], "mOnSurfaceVariant": colors["on_surface_variant"],
            "mOutline": colors["outline"], "mShadow": "#000000",
            "mHover": colors["surface_container_high"], "mOnHover": ON_BACKGROUND,
            "terminal": {
                "background": BACKGROUND, "foreground": ON_BACKGROUND,
                "cursor": PRIMARY, "cursorText": BACKGROUND,
                "selectionBg": PRIMARY, "selectionFg": ON_PRIMARY,
                "normal": {
                    "black": mix(BACKGROUND, "#000000", 0.4),
                    "red": TERTIARY, "green": SECONDARY,
                    "yellow": mix(SECONDARY, "#FFD400", 0.4),
                    "blue": TERM_BLUE, "magenta": PRIMARY, "cyan": TERM_CYAN,
                    "white": ON_BACKGROUND,
                },
                "bright": {
                    "black": colors["outline_variant"],
                    "red": mix(TERTIARY, "#FFFFFF", 0.25),
                    "green": mix(SECONDARY, "#FFFFFF", 0.25),
                    "yellow": mix(SECONDARY, "#FFFFFF", 0.5),
                    "blue": mix(TERM_BLUE, "#FFFFFF", 0.25),
                    "magenta": mix(PRIMARY, "#FFFFFF", 0.25),
                    "cyan": mix(TERM_CYAN, "#FFFFFF", 0.25),
                    "white": "#FFFFFF",
                },
            },
        }
    }
    noctalia_path = NOCTALIA_DIR / f"{theme_id}.json"
    with open(noctalia_path, "w") as f:
        json.dump(noctalia, f, indent=2)
        f.write("\n")

    print(f"Generated {theme_id}:")
    print(f"  {qs_path}")
    print(f"  {hypr_path}")
    print(f"  {noctalia_path}")


if __name__ == "__main__":
    main()
