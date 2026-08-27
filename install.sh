#!/usr/bin/env bash
# Installs this repo's Noctalia config by symlinking it into place.
# Mirrors the pattern used by ~/projects/hyprlnd/install.sh. Anything already
# present at a target path is moved into a timestamped backup dir first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.noctalia-dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

TARGETS=(
    ".config/noctalia"
    ".local/share/noctalia/plugins/ai-usage"
)

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

for path in "${TARGETS[@]}"; do
    link "$REPO_DIR/$path" "$HOME/$path"
done

if [ -d "$BACKUP_DIR" ]; then
    echo
    echo "Backed up replaced files/dirs to: $BACKUP_DIR"
fi
