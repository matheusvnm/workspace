#!/bin/bash

###############################################################################
# Install Git Hooks
#
# Installs the post-merge hook to auto-notify about config changes
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Installing git hooks..."

# Check if we're in a git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Install post-merge hook
if [ -f "$SCRIPT_DIR/hooks/post-merge" ]; then
    cp "$SCRIPT_DIR/hooks/post-merge" "$REPO_ROOT/.git/hooks/post-merge"
    chmod +x "$REPO_ROOT/.git/hooks/post-merge"
    echo "✓ Installed post-merge hook"
else
    echo "Error: post-merge hook not found in scripts/hooks/"
    exit 1
fi

echo "Git hooks installed successfully!"
