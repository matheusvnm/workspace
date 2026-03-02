#!/bin/bash
set -euo pipefail

function install_homebrew() {
    echo "→ Checking Homebrew..."
    if command -v brew >/dev/null 2>&1; then
        echo "✔ Homebrew already installed: $(command -v brew)"
        return 0
    fi

    echo "→ Installing Homebrew (non-interactive)..."
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this script (handle macOS Intel and Apple Silicon)
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "✘ Homebrew installation failed"
        exit 1
    fi

    echo "✔ Homebrew installed: $(command -v brew)"
    return 0
}

function install_just() {
    echo "→ Checking just (justfile executor)..."

    if command -v just >/dev/null 2>&1; then
        echo "✔ just already installed: $(command -v just)"
        return 0
    fi

    echo "→ Installing just via Homebrew..."
    brew update || true
    brew install just

    if ! command -v just >/dev/null 2>&1; then
        echo "✘ just installation failed"
        exit 1
    fi

    echo "✔ just installed: $(command -v just)"
    return 0
}

echo "→ Bootstrapping starting."
install_homebrew
install_just
echo "✔ Bootstrapping complete."
