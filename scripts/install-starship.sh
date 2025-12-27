#!/bin/bash
# Install/update Starship configuration
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
STARSHIP_SRC="$REPO_ROOT/configs/starship.toml"
STARSHIP_DEST="$HOME/.config/starship.toml"

echo ">>> Setting up Starship prompt..."

mkdir -p "$HOME/.config"

# Backup existing config if different
if [[ -f "$STARSHIP_DEST" ]]; then
    if ! diff -q "$STARSHIP_SRC" "$STARSHIP_DEST" &>/dev/null; then
        cp "$STARSHIP_DEST" "$STARSHIP_DEST.backup.$(date +%s)"
        echo "Backed up existing starship.toml"
    fi
fi

# Symlink to repo config (so updates sync via git)
ln -sf "$STARSHIP_SRC" "$STARSHIP_DEST"

echo ">>> Starship config linked"
