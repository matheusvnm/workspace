#!/usr/bin/env bash
set -euo pipefail

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "✔ Homebrew present: $(command -v brew)"
    return 0
  fi
  echo "→ Installing Homebrew"
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      break
    fi
  done
  command -v brew >/dev/null 2>&1 || {
    echo "✘ Homebrew install failed" >&2
    exit 1
  }
  echo "✔ Homebrew installed: $(command -v brew)"
}

install_formula() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✔ $1 present"
    return 0
  fi
  brew install "$1"
}

install_homebrew
install_formula just
install_formula yq
install_formula jq
echo "✔ Bootstrap complete. Next: just setup"
