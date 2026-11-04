#!/usr/bin/env bash
# Fresh-machine bootstrap for this desktop: installs the required packages
# for the current distro, then symlinks this repo's dotfiles into place.
# Anything already present at a target path is moved into a timestamped
# backup dir first (see link(), unchanged from before).
#
# Package installation is distro-specific (see install_packages() below);
# the symlink phase is not -- it's plain bash against $HOME, identical
# everywhere, and runs last regardless of which branch installed packages.
#
# Sets up the Noctalia-only end state: Hyprland + Noctalia + Quickshell +
# our own custom-theme system. ml4w/Waybar (the profile this setup used to
# dual-boot between) has been fully retired and uninstalled -- rofi, kitty,
# matugen, gtk, etc. are now this repo's own tracked configs, not vestiges
# of that profile. ~/projects/hyprlnd is a frozen historical snapshot of
# the old ml4w-based setup, kept for reference only, not meant to be
# reinstalled from -- it has its own install.sh if that's ever wanted.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.noctalia-dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

TARGETS=(
    ".config/hypr"
    ".config/quickshell"
    ".config/noctalia"
    ".config/fastfetch"
    ".config/ml4w"
    ".config/kitty"
    ".config/gtk-3.0"
    ".config/gtk-4.0"
    ".config/matugen"
    ".config/rofi"
    ".config/sidepad"
    ".config/qt6ct"
    ".config/btop"
    ".config/bashrc"
    ".config/xsettingsd"
    ".local/share/noctalia/plugins/ai-usage"
    ".local/share/noctalia/plugins/steam-library"
    ".bashrc"
    ".zshrc"
    ".gtkrc-2.0"
    ".Xresources"
)

# Verified end-to-end on Arch/CachyOS (this machine). The Fedora and NixOS
# branches are best-effort: built from current upstream docs/COPR status
# (checked at the time this was written, not from memory), but this repo
# has no Fedora or NixOS box to actually run them on -- confirm package
# names before relying on them, and report back anything stale.
ARCH_PACKAGES=(
    hyprland hypridle hyprlock hyprpaper hyprpicker hyprshade hyprshutdown hyprsunset
    quickshell noctalia
    rofi grim grimblast-git slurp imagemagick jq ffmpeg wl-clipboard libnotify
    matugen xdg-desktop-portal-hyprland power-profiles-daemon kitty fastfetch qt6ct
    otf-font-awesome noto-fonts-cjk ttf-firacode-nerd ttf-jetbrains-mono-nerd ttf-fira-sans
    awww polkit-gnome networkmanager bluez bluez-utils
    eza fzf tty-clock btop
    papirus-icon-theme bibata-cursor-git
    python-pillow
    libsecret gnome-keyring
    # libsecret (secret-tool)/gnome-keyring: encrypted-at-rest credential
    # storage for the steam-library widget's Steam Web API key -- the same
    # Secret Service store GNOME apps/browsers use for saved passwords.
    # bibata-cursor-git: confirm this AUR package actually provides the exact
    # "Bibata-Modern-Ice" variant conf/autostart.conf's `hyprctl setcursor`
    # line names -- this machine's copy predates this install.sh and was
    # never actually installed via pacman/AUR, so the real source is
    # unconfirmed. Same caveat for ttf-fira-sans above.
    # python-pillow: only needed if you enable Noctalia's community "brave"
    # theme template (~/.local/state/noctalia/community-templates/brave) --
    # its apply.sh imports PIL to paint the theme's background PNGs.
)

# dnf names to confirm at implementation/first-run time -- based on current
# Fedora repo contents, not exhaustively verified package-by-package.
FEDORA_PACKAGES=(
    hyprland hypridle hyprlock hyprpaper hyprpicker
    rofi grim slurp ImageMagick jq ffmpeg wl-clipboard libnotify kitty fastfetch qt6ct
)
# quickshell and noctalia need COPRs on Fedora releases before ~44; see
# install_packages_fedora() for the exact commands and a caveat about a
# known Qt-version mismatch with the quickshell COPR on Fedora 43.

detect_distro() {
    [ -f /etc/os-release ] || { echo "unknown"; return; }
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}${ID_LIKE:+ $ID_LIKE}" in
        *arch*) echo "arch" ;;
        *fedora*) echo "fedora" ;;
        *nixos*) echo "nixos" ;;
        *) echo "unknown" ;;
    esac
}

install_packages_arch() {
    if ! command -v yay >/dev/null 2>&1; then
        echo ":: yay not found -- bootstrapping it first"
        sudo pacman -S --needed --noconfirm base-devel git
        local tmp; tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    echo ":: Installing packages via yay (works whether they're in an official repo or the AUR)"
    yay -S --needed --noconfirm "${ARCH_PACKAGES[@]}"

    # oh-my-posh isn't packaged for Arch/AUR under a stable name -- this
    # machine's copy lives in ~/.local/bin, placed by oh-my-posh's own
    # official installer (https://ohmyposh.dev/docs/installation/linux),
    # not pacman/yay. Skip if already present so re-runs are idempotent.
    if ! command -v oh-my-posh >/dev/null 2>&1; then
        echo ":: Installing oh-my-posh via its official installer"
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
    fi
}

install_packages_fedora() {
    echo ":: Installing packages via dnf"
    sudo dnf install -y "${FEDORA_PACKAGES[@]}"

    if ! command -v quickshell >/dev/null 2>&1; then
        echo ":: quickshell not in official repos -- enabling the errornointernet/quickshell COPR"
        echo "   NOTE: this COPR isn't maintained by upstream Quickshell and has had a known"
        echo "   Qt-version mismatch on at least Fedora 43 (COPR built against Qt 6.9, Fedora"
        echo "   43 ships 6.10+) -- check https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell/"
        echo "   if this install fails."
        sudo dnf copr enable -y errornointernet/quickshell
        sudo dnf install -y quickshell
    fi

    if ! command -v noctalia >/dev/null 2>&1; then
        if ! sudo dnf install -y noctalia; then
            echo ":: noctalia not in official repos on this release -- falling back to the"
            echo "   zhangyi6324/noctalia-shell COPR (official repos have it from Fedora 44 on)"
            sudo dnf copr enable -y zhangyi6324/noctalia-shell
            sudo dnf install -y noctalia-shell
        fi
    fi
}

NIXOS_FLAKE_SNIPPET='
# --- Noctalia (official flake input + module: docs.noctalia.dev) ---
inputs.noctalia = {
  url = "github:noctalia-dev/noctalia";
  inputs.nixpkgs.follows = "nixpkgs";
};

# System-wide:
#   imports = [ inputs.noctalia.nixosModules.default ];
#   programs.noctalia = { enable = true; recommendedServices.enable = true; };
#
# Or per-user via home-manager:
#   home-manager.users.<you> = {
#     imports = [ inputs.noctalia.homeModules.default ];
#     programs.noctalia.enable = true;
#   };

# Also needed:
#   programs.hyprland.enable = true;
#   networking.networkmanager.enable = true;
#   hardware.bluetooth.enable = true;
#   services.power-profiles-daemon.enable = true;  # or services.tuned.enable
#   services.upower.enable = true;
'

install_packages_nixos() {
    echo ":: NixOS is declarative -- this script will not nix-env install anything."
    local out="$REPO_DIR/flake.nix.example"
    printf '%s\n' "$NIXOS_FLAKE_SNIPPET" > "$out"
    echo ":: Wrote $out -- add its contents to your own system flake, then run:"
    echo "     sudo nixos-rebuild switch"
    echo "   (a privileged, user-specific rebuild this script can't safely do for you)."
    echo "   The symlink phase below still runs -- .config/hypr/quickshell/noctalia are"
    echo "   plain files, not Nix-managed, regardless of how the packages got installed."
}

link() {
    local src="$1" dest="$2"

    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        echo "ok      $dest (already linked)"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${dest#"$HOME"/}")"
        mv "$dest" "$BACKUP_DIR/${dest#"$HOME"/}"
        echo "backup  $dest -> $BACKUP_DIR/${dest#"$HOME"/}"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "link    $dest -> $src"
}

distro="$(detect_distro)"
case "$distro" in
    arch) install_packages_arch ;;
    fedora) install_packages_fedora ;;
    nixos) install_packages_nixos ;;
    *)
        echo "error: unrecognized or unsupported distro (checked /etc/os-release)." >&2
        echo "Supported: Arch-like (pacman), Fedora (dnf), NixOS." >&2
        exit 1
        ;;
esac

echo
echo ":: Linking dotfiles"
for path in "${TARGETS[@]}"; do
    link "$REPO_DIR/$path" "$HOME/$path"
done

SETTINGS_SNAPSHOT="$REPO_DIR/.local/state/noctalia/settings.toml"
if [ -f "$SETTINGS_SNAPSHOT" ]; then
    echo
    echo ":: A saved Noctalia settings snapshot is available -- active"
    echo "   theme/palette, enabled plugins and app-color templates, and"
    echo "   monitor-specific layout (lockscreen widget positions,"
    echo "   wallpaper-per-monitor). Without it Noctalia just boots with its"
    echo "   own defaults, which is fine too -- easy to redo via Settings."
    echo "   The monitor-layout part only makes full sense if this is the"
    echo "   same machine/monitor setup (same connector names) it was"
    echo "   captured on."
    read -r -p "   Restore it now? [y/N] " restore_settings
    if [[ "$restore_settings" =~ ^[Yy]$ ]]; then
        dest="$HOME/.local/state/noctalia/settings.toml"
        if [ -e "$dest" ]; then
            mkdir -p "$BACKUP_DIR/.local/state/noctalia"
            mv "$dest" "$BACKUP_DIR/.local/state/noctalia/settings.toml"
            echo "   backup   $dest -> $BACKUP_DIR/.local/state/noctalia/settings.toml"
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$SETTINGS_SNAPSHOT" "$dest"
        echo "   restored $dest"
        echo "   (location.address was blanked before committing -- set it again in Settings for the weather widget)"
    else
        echo "   Skipped -- Noctalia will use its own defaults."
    fi
fi

if [ -d "$BACKUP_DIR" ]; then
    echo
    echo "Backed up replaced files/dirs to: $BACKUP_DIR"
fi
