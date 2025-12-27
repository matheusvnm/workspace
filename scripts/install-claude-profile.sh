#!/bin/bash
# Setup Claude profile system
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_WRAPPER="$REPO_ROOT/bin/claude"
CLAUDE_DIR="$HOME/.claude"
STATE_FILE="$CLAUDE_DIR/.current-profile"

echo ">>> Setting up Claude profiles..."

# Make wrapper executable
chmod +x "$CLAUDE_WRAPPER"

# Create .claude directory
mkdir -p "$CLAUDE_DIR"

# Set default profile if none exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "Default profile set to: work"

    # Run initial switch to create symlinks (skip login during install)
    "$CLAUDE_WRAPPER" profile switch work --no-login
fi

# Install git hooks
HOOKS_SRC="$REPO_ROOT/scripts/hooks"
HOOKS_DEST="$REPO_ROOT/.git/hooks"
if [[ -d "$HOOKS_SRC" ]]; then
    cp "$HOOKS_SRC"/* "$HOOKS_DEST/" 2>/dev/null || true
    chmod +x "$HOOKS_DEST"/* 2>/dev/null || true
fi

echo ">>> Claude profiles ready"
