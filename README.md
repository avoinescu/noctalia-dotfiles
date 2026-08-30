# noctalia-dotfiles

The one actively maintained repo for this desktop: Noctalia's own config,
Hyprland's config, and the custom Quickshell apps/theme system built on top
of it. It started out holding only what was purely Noctalia's (split out
from [`hyprlnd`](../hyprlnd), the ml4w-based Hyprland dotfiles, because
Noctalia's directories were never touched by ml4w's installer to begin
with) -- `.config/hypr`, the live Quickshell apps, and `.config/ml4w/colors`
later moved here too, once keeping them git-tracked in `hyprlnd` meant a
manual copy for every edit (its live files were symlinked into a plain,
non-git directory, not into that repo). `hyprlnd` is now frozen, kept only
as a historical snapshot of the dormant ml4w/Waybar profile; see
[Relationship to hyprlnd](#relationship-to-hyprlnd).

Noctalia is now the sole daily-driver shell on this machine. The old `ml4w`
profile (Waybar/swaync/rofi/hypridle) is kept installed but dormant -- a
one-command fallback (`switch-shell-profile.sh ml4w`) rather than something
actively maintained.

## What's here

```
.config/noctalia/
  config.toml               hand-written bar layout, app theming, widgets
  palettes/
    hellsing-*.json          4 tiers of the scheduled Hellsing theme
    joker.json                the static Joker theme
.local/share/noctalia/plugins/ai-usage/
  plugin.toml, service.luau, bar.luau
.config/hypr/
  conf/, scripts/, sounds/, settings/    Hyprland config + the custom-theme
                                          system -- see Custom themes/Theme
                                          picker below and Relationship to
                                          hyprlnd for the full script list
.config/quickshell/
  shell.qml, CustomTheme/, PowerApp/, AIUsageApp/, ThemePickerApp/,
  overview/, shared/                      the live Quickshell apps
.config/ml4w/colors/
  <id>.json per static theme              generated palette data (the one
                                           part of ml4w's own directory tree
                                           that's entirely ours)
.config/fastfetch/
  config.jsonc, config-zerotrust.jsonc,   sed-rewritten in place on every
  assets/<id>-face.png                    theme apply to swap the ASCII logo
```

`.config/noctalia`, `.config/hypr`, and `.config/quickshell` are each one
symlink straight into this repo (see [Install](#install)) -- drop a new
palette into `palettes/`, or edit a hypr script or QML app, and it's already
live, no separate copy step. `.config/ml4w/colors` is a symlink nested one
level inside the still-ml4w-owned `~/.config/ml4w` tree, for the same reason
-- see [Relationship to hyprlnd](#relationship-to-hyprlnd).

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
  between the `ml4w` and `noctalia` profiles live -- see
  [Relationship to hyprlnd](#relationship-to-hyprlnd).
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
  mechanism and its `settings.ini` gotcha (below) documented in this
  repo's `noctalia-theme` skill.

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

Both scripts live under `.config/hypr/scripts` rather than anywhere
Noctalia-native, because they reach outside anything Noctalia owns:

- **`wallpaper_changed`** -- Noctalia's own wallpaper picker never runs
  ml4w's full Matugen pipeline (retired along with the rest of ml4w's own
  bar/panels), so the two Quickshell panels with no Noctalia equivalent that
  are still kept around (`PowerWindow`, `AIUsageWindow` -- see
  `shell.qml`) would otherwise keep showing stale colors.
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
(`~/.config/hypr/scripts/listeners.sh`), which is a stronger version of
the same fix. Worth remembering before wiring any *new* hook that writes
into ml4w-shared config.

## Custom themes

54 hand-built palettes beyond Noctalia's own built-in/wallpaper-derived
schemes. One is scheduled (Hellsing); the other 53 are static one-shot
toggles sharing `~/.config/hypr/scripts/custom-theme-lib.sh`
for apply/deactivate logic and cross-theme preemption -- a single
`~/.cache/ml4w/active-static-theme` file tracks whichever one (if any) is
on, so turning on any theme cleanly turns off whatever else was active,
including Hellsing (restored -- tier and all -- if it was preempted).

Want to add another one? [**CREATING-A-THEME.md**](CREATING-A-THEME.md) is
a step-by-step walkthrough of the whole process (also documented as a
reusable pattern in this repo's `noctalia-theme` skill).

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
the fastfetch logo swap -- also lives here, under `.config/hypr`:

- `.config/hypr/scripts/hellsing-lib.sh` -- shared tier-application logic
- `.config/hypr/scripts/hellsing-scheduler.sh` -- the 5-minute poller,
  autostarted unconditionally (both shell profiles)
- `.config/hypr/scripts/hellsing-theme.sh` -- instant on/off (the poller
  alone means waiting up to 5 minutes to see anything change)
- Toggle file: `.config/hypr/settings/hellsing-theme` (`on`/`off`)

### Static themes -- one-shot, no schedule

Each is a single palette, deliberately not scheduled (a time-of-day
evolution doesn't fit any of these the way it does Hellsing). One-shot
apply/revert script per theme, also here
(`.config/hypr/scripts/<id>-theme.sh`), palette at `palettes/<id>.json`. Each on/off toggle also fires a themed notification;
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
| `arthas` | Frostmourne ice-blue, plague green, blood crimson, on near-black navy | "Frostmourne hungers." | "At long last... no king rules forever, my son." -- Terenas Menethil's spirit, as Arthas dies atop Icecrown Citadel | Random: the real in-game Lich King "Frostmourne hungers" line, or a second real Lich King greeting line |
| `bloodelves` | Gold and crimson with an arcane-green undertone, on deep maroon-black | "Anu belore dela'na! (The sun guides us.)" -- real Thalassian NPC line | "Anar'alah! (By the Light!)" -- real Thalassian NPC line | Random: Eversong Woods or Silvermoon City soundtrack snippet (Burning Crusade) |
| `proxima` | Sacred amber flame, ashen stone, electric-blue lightning accent, on near-black bone | "Harden. Endure. Become the shell." (flavor -- Mortal Shell II released days before this theme was built, no canonical Proxima dialogue was findable yet) | "The shell falls silent once more." (flavor) | None -- no findable dialogue to source from yet |
| `warframe` | Tenno cyan, Orokin gold, void purple, on deep space black | "Tenno... wake up." -- the Lotus, game's intro line | "The Old War is over. But another war... is just beginning." -- the Lotus | Random: one of 4 real in-game/community lines (that exact intro line has no findable clip) |
| `warthunder` | Olive drab, gunmetal gray, tracer orange, on asphalt near-black | "A good pilot can fly anything that flies..." -- real in-game loading-screen hint (no characters to quote) | "Prepare for the next sortie." (flavor) | Random: "Attack the D point" (EN), "Cible detruite" (FR) real voice comms, or the "Angry Russian Tank Instructor" soundboard clip |
| `undead` | Forsaken royal purple, plague-olive, bone-ivory, necrotic red, on crypt-black | "Did you think we had forgotten?... Behold, now, the terrible vengeance of the Forsaken! Death to the Scourge!" -- Sylvanas, founding the Forsaken | "Give my regards to the endless dark." -- Sylvanas, Heroes of the Storm | Sylvanas's real in-game Banshee Wail sound effect |
| `xalatath` | Void purple, void-whisper teal, ancient-dagger gold, on obsidian | "Inevitably... the Void consumes everything." -- real Mythic+ affix line | "We will survive." -- real on-click farewell line | "The walls between realms are thin here, so easy to tear open" -- real in-game voice-over line, trimmed from a full compilation using its captions |
| `sylvanas` | Banshee spectral teal, Forsaken purple, Dark Ranger blood-crimson, on near-black | "ON YOUR KNEES! The Banshee Queen has plans for you!" -- real combat line | "It shall be done. However long it takes." -- her real Shadowlands 9.2 epilogue line, accepting her Maw penance | Random: 4 real lines/sounds ("For the Horde!", her Hearthstone intro, a combat line, her laugh) |
| `protoss` | Psionic gold, shield blue, khala-purple, on void-black | "My life for Aiur!" -- real Zealot line | "En Taro Adun" -- real Khalani ritual phrase | Random: 8 user-picked real clips (Power Overwhelming, Adun Toridas, and more) |
| `terran` | Dominion thruster blue, gunmetal steel, warning-siren amber, on gunmetal-navy | "Rock and Roll!" -- real Marine combat bark | "Good to go." -- real Marine/SCV bark | Random: 3 real Marine/SCV barks |
| `zerg` | Creep purple, acid-toxin green, bioluminescent orange, on organic near-black | "The Swarm is eternal. The Swarm is the future." -- real Overmind line | "The swarm recedes... for now." (flavor) | A real zergling screech |
| `kerrigan` | Chitin magenta, psionic gold-orange, blade-crimson, on near-black violet | "I am the Swarm... vengeance shall be mine. For I am the Queen of Blades." -- real line | "I don't know if I deserve redemption... but our universe does." -- her real Legacy of the Void ending line | Her real "Kerrigan reporting" Heroes of the Storm select line |
| `khorne` | Blood-red (dominant), brass/bronze, dark crimson, on near-black | "Blood for the Blood God! Skulls for the Skull Throne!" -- real recurring WH40K war cry | "Khorne cares not from whence the blood flows, only that it flows." -- real lore line | Random: 2 real "Blood for the Blood God" clips |
| `tzeentch` | Pink Horror magenta, Blue Horror cyan, gold sorcery accent, on deep void-blue-black | "I am Tzeentch, and you are the puppet that dances to my tune." -- real Book of Tzeentch line | flavor text | "I have seen your fate, perhaps we can change it for the better" -- real Tzeentch-faction sorcerer diplomacy line, Total War: Warhammer III |
| `nurgle` | Putrid green (dominant), rust/decay brown, bile-yellow, on swampy near-black | "...through such decay, life begins anew." -- real Tome of Decay line | "Decay is the victor in all battles, the opposition to which there is no resistance." -- real Tome of Decay line | Random: 3 real Total War: Warhammer lines |
| `slaanesh` | Excess pink/magenta, decadent purple, pearl/opulent gold, on deep purple-black | "Come to me... Partake of perfection!" -- real Total War: Warhammer III line | "For I am Slaanesh... My Thirst for you shall never be sated." -- real Liber Chaotica line | "We are the feaster of pain, the herald of Slaanesh, and your time has come" -- real Exalted Keeper of Secrets pre-battle speech, Total War: Warhammer III |
| `acecombat` | Sky blue, cloud white/silver, HUD-orange, on aviation navy-black | Mihaly Shilage's "This aircraft is my body... I must put my soul into it." | Avril Mead's "To Skies Unknown... the path to mankind's vast future remains standing, Granddad." | The real in-game AWACS radio alert tone |
| `geralt` | Medallion silver, toxic potion-green, sign-magic amber, on dark leather-brown near-black | "Evil is evil... I prefer not to choose at all." -- real line (The Last Wish / Witcher 3) | flavor text | The real in-game delivery of that same line |
| `yennefer` | Deep violet sorcery, obsidian black-and-white, lilac/pearl accent, on near-black | flavor text | "I am not a tool. I am Yennefer of Vengerberg." -- real line | "Well, chop chop, and don't get killed, witcher" -- real in-game line to Geralt, Witcher 3 |
| `triss` | Fiery red hair, warm amber/copper fire-magic, cool sapphire accent, on near-black | flavor text | "We had our chance, but... let it go." -- real line | "Don't worry about me, Geralt. And please be careful" -- real in-game line, Witcher 3 |
| `baldursgate` | D&D parchment gold, arcane purple, torch-fire orange, on dark-fantasy near-black | Astarion's real "FULL CONCENTRATED POWER OF THE SUN!" line (BG3) | flavor text | Random: 3 real Astarion lines, including "I was right there!" |
| `dante` | Signature red, Rebellion steel-blue, hellfire-orange, on stylish near-black | "Jackpot!" -- real DMC catchphrase | flavor text | Random: 2 real "Jackpot!" takes (DMC3, Marvel vs. Capcom 3) |
| `vergil` | Signature blue, Yamato steel-silver, cold Devil-Trigger ice-blue, on near-black | "Might controls everything. Without strength, you cannot protect anything." -- real DMC3 line | flavor text | A real Vergil voice line |
| `doom` | Hellish red/orange, UAC tech-cyan, on near-black | "Rip and tear, until it is done." -- real Doom Eternal codex/narration line | flavor text | Random: 2 real lines ("Rip and tear", "The only thing they fear is you") |
| `skyrim` | Nordic ice-blue, stone-gray, dragonfire-orange, on near-black | "Dovahkiin, Dovahkiin, naal ok zin los vahriin..." -- real Dragon-tongue lyrics | flavor text | A snippet of the real "Dragonborn" theme song (Jeremy Soule), the vocal chant section |
| `homm3` | Parchment gold, heraldic blue, bronze, on near-black | flavor text (game is almost entirely unvoiced) | flavor text | A snippet of the real main-menu theme (Romero/King/Baca) |
| `kingarthur` | Roman imperial red/gold, decayed dark-fantasy green, on near-black | "We are the Night Legion, the ultimate army of Rome. We are more powerful than ever, and we are ready to return." -- real line, official reveal trailer | "My name is Gaius Julius Mento. I died centuries ago." -- real line, same trailer | The on-quote line itself, trimmed from that trailer's audio |
| `godfather` | Classic mafia noir: black, gold, deep blood-red | "I'm gonna make him an offer he can't refuse." -- Don Vito Corleone, real film line | "...a man who doesn't spend time with his family can never be a real man." -- real film line | The real film line, on-notification's |
| `dracula` | Gothic blood-red, castle stone-gray, pale moonlight-blue, on near-black | "What is a man?! A miserable little pile of secrets! But enough talk, HAVE AT YOU!!!" -- real Castlevania: Symphony of the Night line | flavor text | The real in-game delivery of that line |
| `quake` | Gladiatorial gold, arena blood-red, gunmetal, on near-black | "Quad Damage!" -- real Quake III Arena announcer callout | flavor text | The real announcer line |
| `silenthill` | Rust/blood-red, fog-gray, tarnished gold, on dim near-black | flavor text (Pyramid Head has no dialogue -- silent and faceless by design) | flavor text | Random: 2 real Silent Hill siren effects, not a spoken quote |
| `residentevil` | S.T.A.R.S. blood-red, Spencer Mansion moss-green, tarnished gold, on near-black | Barry Burton's real "...almost a Jill sandwich!" line (1996 original) | flavor text | The real in-game delivery of that line |
| `kotor` | Jedi-console blue, credit-chip gold, Sith-purple, on near-black | HK-47's real "Statement: HK-47 is ready to serve, master." line | flavor text, in his verified speech pattern | A real HK-47 voice line |
| `darthmaul` | Sith blood-red, Zabrak-tattoo black, saber-gold, on near-black | Maul's real Phantom Menace line -- one of only 33 words he speaks in the film | flavor text | A real Darth Maul voice line |
| `darthmalgus` | Sith Empire crimson, ash-black, void-purple, on near-black | Real trimmed line from SWTOR's "Deceived" cinematic | flavor text | "Our time has come" -- the same real line, trimmed from the trailer's own manually-authored closed captions |
| `darthvader` | Imperial black, lightsaber blood-red, life-support gray, on near-black | "No. I am your father." -- the real, exact line (not the commonly-misquoted "Luke, I am your father") | flavor text | The real film/in-game delivery of that exact line |
| `taintedgrail` | Rot-green, aged bronze/leather, blood-red accent, on bleak near-black | "The King is dead. Long live the rot." -- real line | "Silence is the only honest thing left in Avalon." -- real line | "What secrets and mysteries will you find, in the land of everlasting autumn" -- real narrator line, official 0.6 launch trailer |
| `titanfall2` | Vanguard thruster blue, Titan-armor gold, plasma-orange, on gunmetal near-black | BT-7274's real "Protocol 3: Protect the Pilot." line | flavor text | Random: 3 real in-game lines |
| `revan` | Steel-grey mask, dark-past crimson, redemption-saber electric-blue, on cold near-black | flavor text (his KOTOR/SWTOR ending is player-choice-driven, so no single canonical line fits an on-notification) | Revan's real dark-side line to Malak at the Star Forge: "This is the way of the Dark Side, Malak -- all things end in death." | None -- nothing clean findable, not faked |
| `darthnihilus` | Void black, sickly mask-gold, near-black maroon shroud, ash grey | Visas Marr's real line describing him: "He is a wound in the Force, more presence than flesh, and in his wake life dies... sacrificing itself to his hunger." | Kreia's real line: "The will behind his power is a primal thing. And it devours him as he devours others." | A real growled in-game line, volume-boosted to this collection's baseline |
| `meetrasurik` | Jedi lightsaber blue, weathered robe tan, Force-wound pale grey-white, on near-black | flavor text (she's a heavily player-scripted, often-silent protagonist -- no verifiable fixed line) | flavor text | None -- no findable dialogue to source from |
| `sauron` | Fiery Eye-of-Sauron orange, Mordor black-red, molten ring-gold, on ashen near-black | The real Ring-verse: "One Ring to rule them all, One Ring to find them, One Ring to bring them all and in the darkness bind them." | flavor text | The real Ring-verse recitation |
| `fellowship` | Shire/Lothlorien forest green, Rivendell gold, elvish silver-blue, on deep-forest near-black | The Council of Elrond's real line: "You have my sword. And you have my bow. And my axe." | Frodo's real line, same scene: "I will take the Ring, though I do not know the way." | Gimli's real "And my axe!" clip |
| `corban` | Tempered steel, forge/hearth orange, Elyon's holy white-gold, on cold-iron near-black | Real book text (*Malice*, book 1): "Both the brave man and the coward feel the same. The only difference between them is that the brave man faces his fear, does not run." | flavor text | None -- unadapted book series, no findable clip |
| `snaka` | Venomous serpent green/black, toxic yellow-green highlight | flavor text (no verifiable Snaka quote exists in any searchable source) | flavor text | None -- unadapted book series |
| `ulfrir` | Icy wolf grey-blue, wintery, snow-white highlight | Real book text (*The Shadow of the Gods*): `"It is Ulfrir," Elvar breathed, stumbling away, looking again at the mound.` | flavor text | None -- unadapted book series |
| `likrifa` | Dragon-fire orange-red, dark scale-red, ember gold | flavor text (no verifiable Lik-Rifa quote found -- checked her wiki and the book's full quote page) | flavor text | None -- unadapted book series |
| `vaas` | Jungle green, blood-red madness, tribal tattoo orange, on near-black | Vaas's real "definition of insanity" monologue (Far Cry 3) | Same monologue, verified via a full transcript | The complete real ~34s monologue clip |
| `agentsmith` | Classic Matrix code-green, black suit, lighter code-green highlight | "Human beings are a disease, a cancer of this planet. You're a plague, and we are the cure." -- real film line | "Never send a human to do a machine's job." -- real film line | Random: 3 real film clips (the disease monologue, "Mr. Anderson", "I'm gonna enjoy watching you die") |
| `murderbot` | Gunmetal-grey SecUnit armor, dark chassis, media-feed screen-blue, warning orange | The real, verbatim opening line of *All Systems Red*: "I could have become a mass murderer after I hacked my governor module, but then I realized I could access the combined feed of entertainment channels..." | Real book line: "Also, you may have noticed, I don't care." | None -- no findable clip for this narration-heavy book-first property |
| `atreides` | Arrakis spice/sand amber, deep desert-night blue, Ibad-eyes cyan, on near-black | The real Litany Against Fear: "I must not fear. Fear is the mind-killer. Fear is the little-death that brings total obliteration." | flavor text | Paul reciting the Litany, trimmed from a Dune (2021) scene clip via its captions |

## Theme picker

A QML grid (`ThemePickerApp`, part of the `qs` shell process alongside
`PowerApp`/`AIUsageApp`) replaced the old rofi text menu once 40
static themes plus Hellsing made a plain list hard to browse -- one card per
theme, showing its name and a real wallpaper thumbnail pulled fresh from
`~/Pictures/wallpaper/<id>/` every time the picker opens, click to apply.
The currently-active theme's card gets a highlighted border. A search field
filters by name. Deliberately scoped to *only* our own custom themes, not a
general Noctalia scheme picker: no "Wallpaper (auto)", no builtin schemes,
no community palettes -- those are still reachable via Noctalia's own
Settings if wanted.

Both the grid and the old rofi menu (`noctalia-theme-picker.sh`, kept as an
unbound fallback -- run it directly, `bash
~/.config/hypr/scripts/noctalia-theme-picker.sh`, if the QML app ever
breaks) read the same list from `~/.config/hypr/scripts/theme-list.sh`, so
they can't drift out of sync. That list has, in order: Hellsing (an "Auto,
current tier" entry plus all four tiers individually as forced previews --
a forced tier auto-corrects back within 5 minutes if it doesn't match the
scheduler's current-hour tier, since Hellsing's poller doesn't know the
difference between a preview and a real change), then all 53 static themes
from the table above. Known limitation: since all 5 Hellsing entries apply
via the same `ACTIVE_STATIC` marker, their cards all highlight together in
the grid with no way to tell which specific tier is actually active.

## Keybinds

| Keybind | Action |
|---|---|
| `Super+Shift+N` | Switch shell profile (`ml4w` ⇄ `noctalia`) |
| `Super+Shift+P` | Open the custom-theme picker (QML grid, noctalia profile only) |
| `Super+Shift+C` | Toggle Noctalia's control center panel (noctalia profile only) |

The theme picker replaced the old dedicated `Super+Shift+J` (Joker) /
`Super+Shift+V` (Hellsing) toggle keybinds -- both are still one click away
as menu entries.

## Relationship to hyprlnd

`hyprlnd` is **frozen** (archived, no further edits) -- it's kept only as a
historical snapshot of the dormant ml4w/Waybar profile: Waybar (all themes),
swaync, rofi theming, matugen, `com.ml4w/*` minus `colors/`. Its own
`install.sh` still works standalone if that legacy profile is ever wanted on
a fresh machine, since this repo's bootstrap does not set it up.

Everything actively maintained now lives here, including the Hyprland
config and custom-theme system that used to require a manual copy into
`hyprlnd` for every edit:

- `.config/hypr/scripts/switch-shell-profile.sh` + the `Super+Shift+N`
  keybind -- the profile switcher, now mostly a fallback path back to the
  dormant `ml4w` profile
- `.config/hypr/scripts/hellsing-*.sh` -- the Hellsing scheduler/lib/toggle
  and the Quickshell/Hyprland halves of every custom theme
- `.config/hypr/scripts/custom-theme-lib.sh` -- shared apply/deactivate
  logic and cross-theme preemption for every static theme
- `.config/hypr/scripts/{joker,illidan,arthas,bloodelves,proxima,warframe,warthunder,undead,xalatath,sylvanas,protoss,terran,zerg,kerrigan,khorne,tzeentch,nurgle,slaanesh,acecombat,geralt,yennefer,triss,baldursgate,dante,vergil,doom,skyrim,homm3,kingarthur,godfather,dracula,quake,silenthill,residentevil,kotor,darthmaul,darthmalgus,darthvader,taintedgrail,titanfall2,revan,darthnihilus,meetrasurik,sauron,fellowship,corban,snaka,ulfrir,likrifa,vaas,agentsmith,murderbot,atreides}-theme.sh`
  -- the 53 static theme toggles
- `.config/hypr/scripts/theme-list.sh` -- single source of truth for every
  picker entry (id/label/tier), read by both pickers below
- `.config/hypr/scripts/theme-list-json.sh` -- emits `theme-list.sh` as
  JSON for `ThemePickerApp` to consume
- `.config/hypr/scripts/noctalia-theme-picker.sh` -- the old rofi theme
  picker, kept as an unbound fallback
- `.config/quickshell/ThemePickerApp/` -- the QML grid theme picker,
  loaded into the main `qs` shell process via `shell.qml`
- `.config/hypr/scripts/gen-theme-colors.py` -- the palette generator used
  in [CREATING-A-THEME.md](CREATING-A-THEME.md)
- `.config/hypr/scripts/noctalia-theme-quickshell.sh` and
  `noctalia-sync-icon-theme.sh` -- this repo's two hooks
- `~/.config/matugen/config-quickshell.toml` -- the scoped Matugen config the
  Quickshell hook uses (still `hyprlnd`-side, part of the frozen ml4w tree,
  read but not written by anything here)
- `.claude/skills/noctalia-theme/SKILL.md` -- the reusable "how to build a
  Noctalia theme on this setup" writeup

### ml4w decoupling and the hypr/quickshell migration

ml4w's own bar/panels/theming were retired once the ml4w-vs-noctalia
comparison ran its course, rather than kept as a live, actively-maintained
parallel system. What's left of ml4w, now split across a frozen `hyprlnd`
and this repo:

- **Migrated here from `hyprlnd`**: `.config/hypr` (all of it), the live
  Quickshell apps (`shell.qml`, `CustomTheme/`, `PowerApp/`, `AIUsageApp/`,
  `ThemePickerApp/`, `overview/`, `shared/` -- the two panels with no
  Noctalia equivalent, a power/session menu and the custom-built AI-usage
  dropdown Noctalia's own `hyprlnd/ai-usage:bar` widget reopens via
  `qs ipc call ai-usage toggle`, still themed by the same
  `colors.json`/`theme-manager` IPC reload every static theme already
  used), `.config/ml4w/colors` (the one part of ml4w's own directory
  that's entirely our generated data), and `.config/fastfetch` (same
  reasoning -- its config files and `assets/` get rewritten on every
  theme apply).
- **Dropped in favor of a native Noctalia command**: the hypr tree used to
  lean on several `ml4w-*` helper scripts for things Noctalia's own CLI
  (`noctalia msg --help`) already covers -- session actions (lock/suspend/
  logout/reboot/shutdown), the clipboard-history panel, night light, and
  dark/light theme-mode toggling (which also re-applies the GTK color
  template, so a separate ml4w script fighting it would have been wrong
  anyway). The emoji-picker and calculator keybinds now open Noctalia's own
  launcher, which has both built in.
- **Self-built, vendored into `.config/hypr/scripts` and a new
  `.config/hypr/settings/`**: the notification-handler wrapper, the sidepad
  dispatcher, the two float toggles, the qs/overview autostart, and the
  low-battery listener -- genuinely still needed, no Noctalia equivalent,
  already ml4w-agnostic under the hood so this was a relocation and a
  rename, not a rewrite.
- **Kept, dormant fallback** (frozen in `hyprlnd`): `switch-shell-profile.sh`
  still switches to it, Waybar (all themes), swaync, rofi, hypridle --
  installed and switchable (`switch-shell-profile.sh ml4w`) but not
  autostarted or actively maintained. Its Matugen-driven re-theming
  (Waybar/rofi/swaync/gtk3/gtk4 color templates) was removed along with the
  rest of the ml4w Quickshell layer, so the fallback's colors are frozen at
  whatever they were the last time this pipeline ran, not live-updating
  with wallpaper changes.
- **Removed entirely**: the ml4w Quickshell Sidebar/Wallpaper-picker/
  Calendar/Welcome panels and the alternate Statusbar/Dock engine
  (redundant with Noctalia's own control-center/OSD/wallpaper-picker,
  confirmed via direct inspection rather than assumption before deleting);
  the separate ml4w Settings app; the ml4w Hyprland Settings app (its one
  load-bearing side effect -- border/gaps values -- baked directly into
  `conf/layouts/default.conf` first); the `gtk-theme-switcher.sh` listener;
  `wallpaper.sh`/`wallpaper-cache.sh`/`wallpaper-effects.sh` and a duplicate
  `toggleallfloat.sh` (all dead, no live keybind pointed at any of them); a
  handful of keybinds/windowrules that pointed at the now-deleted panels.

## Install

```sh
./install.sh
```

A real fresh-machine bootstrap, not just a symlink script: installs the
required packages for the detected distro, then symlinks `.config/hypr`,
`.config/quickshell`, `.config/noctalia`, `.config/ml4w/colors`, and
`.local/share/noctalia/plugins/ai-usage` into place, backing up anything
already there to `~/.noctalia-dotfiles-backups/`.

Sets up the Noctalia-only end state (Hyprland + Noctalia + Quickshell + the
custom-theme system) -- it does not install the dormant ml4w/Waybar profile;
run `hyprlnd`'s own (frozen but still functional) `install.sh` for that.

- **Arch-like** (CachyOS/Manjaro/EndeavourOS included): fully automated,
  verified end-to-end on real hardware. Bootstraps `yay` if missing, then
  installs everything through it (works whether a package is in an official
  repo or the AUR).
- **Fedora**: best-effort -- `dnf` for what's in official repos, plus the
  `errornointernet/quickshell` and (pre-Fedora-44) `zhangyi6324/noctalia-shell`
  COPRs. Built from current upstream docs, not tested on a real Fedora box;
  report back if a package name has drifted.
- **NixOS**: doesn't try to imperatively install anything -- drops a
  `flake.nix.example` using Noctalia's own official flake module
  (`docs.noctalia.dev`) and prints instructions to add it to your system
  flake and `nixos-rebuild switch` yourself, then still symlinks the config
  the same way (those files aren't Nix-managed either way).
