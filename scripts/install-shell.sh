#!/bin/bash
# Install shell integration (PATH, aliases, env vars)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SHELL_CONFIG="$REPO_ROOT/configs/shell/claude-tools.sh"
ZSHRC="$HOME/.zshrc"
MARKER="# >>> claude-tools >>>"
END_MARKER="# <<< claude-tools <<<"

echo ">>> Setting up shell integration..."

# Create zshrc if missing
touch "$ZSHRC"

# Remove old integration if present
if grep -q "$MARKER" "$ZSHRC"; then
    sed -i '' "/$MARKER/,/$END_MARKER/d" "$ZSHRC"
fi

# Append new integration
cat >> "$ZSHRC" << EOF
$MARKER
source "$SHELL_CONFIG"
$END_MARKER
EOF

echo ">>> Shell integration installed in ~/.zshrc"
