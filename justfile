# ──────────────────────────────────────────────────────────────────────────────
# Workspace Bootstrap
# One repo to rule them all: deps, shell, configs, and LLM tooling.
# Run `just` to see all available recipes.
# ──────────────────────────────────────────────────────────────────────────────

set shell := ["bash", "-euo", "pipefail", "-c"]

workspace  := justfile_directory()
home       := env("HOME")

# ─── Paths ────────────────────────────────────────────────────────────────────

config_dir := workspace / "config"
deps_dir   := workspace / "deps"
llms_dir   := workspace / "llms"

opencode_cfg := home / ".config" / "opencode"
starship_cfg := home / ".config" / "starship.toml"
zshrc        := home / ".zshrc"

# ─── Env Vars ─────────────────────────────────────────────────────────────────

export HOMEBREW_NO_ENV_HINTS := "1"

# ─── Default: list recipes ────────────────────────────────────────────────────

[doc("Show all available recipes")]
default:
    @just --list --unsorted

[group("setup")]
[doc("Run the full workspace setup (deps + shell + llms)")]
setup: deps shell llms
    @echo ""
    @echo "✔ Workspace fully configured."
    @echo "  Restart your terminal or run: exec zsh"

[group("setup")]
[doc("Run full setup non-interactively (CI or scripted installs)")]
setup-ci: brew-install shell llms
    @echo "✔ CI setup complete."

# ══════════════════════════════════════════════════════════════════════════════
# Dependencies
# ══════════════════════════════════════════════════════════════════════════════

[group("deps")]
[doc("Install Homebrew (if missing) and all Brewfile packages")]
deps: brew-install

[group("deps")]
[doc("Install all tools and apps from the Brewfile")]
brew-install:
    brew bundle --file={{ deps_dir }}/Brewfile --verbose
    @echo "✔ Brewfile packages installed."

[group("deps")]
[doc("Show what would be installed/upgraded (dry run)")]
brew-dry-run:
    brew bundle check --file={{ deps_dir }}/Brewfile --verbose || true

[group("deps")]
[doc("Update Homebrew and upgrade all installed packages")]
brew-upgrade:
    brew update && brew upgrade && brew cleanup
    @echo "✔ All packages upgraded."

# ══════════════════════════════════════════════════════════════════════════════
# Shell Configuration
# ══════════════════════════════════════════════════════════════════════════════

[group("shell")]
[doc("Configure shell: starship prompt, aliases, and functions")]
shell: shell-starship shell-oh-my-zsh shell-zshrc
    @echo "✔ Shell configured."

[group("shell")]
[doc("Symlink starship.toml into ~/.config/")]
shell-starship:
    @mkdir -p "$(dirname {{ starship_cfg }})"
    @if [ -L {{ starship_cfg }} ]; then rm {{ starship_cfg }}; fi
    ln -sf {{ config_dir }}/starship.toml {{ starship_cfg }}
    @echo "✔ Starship config linked: {{ starship_cfg }} → {{ config_dir }}/starship.toml"

[group("shell")]
[doc("Ensure .zshrc sources workspace aliases, functions, and env")]
shell-zshrc:
    #!/usr/bin/env bash
    set -euo pipefail
    marker="# >>> workspace-bootstrap >>>"
    end_marker="# <<< workspace-bootstrap <<<"
    block=$(cat <<'BLOCK'
    # >>> workspace-bootstrap >>>
    # Managed by: github.com/smmarques/workspace — do not edit this block.
    eval "$(starship init zsh)"
    [ -f "WORKSPACE_DIR/config/.aliases" ]   && source "WORKSPACE_DIR/config/.aliases"
    [ -f "WORKSPACE_DIR/config/.functions" ] && source "WORKSPACE_DIR/config/.functions"
    # <<< workspace-bootstrap <<<
    BLOCK
    )
    block="${block//WORKSPACE_DIR/{{ workspace }}}"

    if grep -qF "$marker" {{ zshrc }} 2>/dev/null; then
        echo "✔ .zshrc already contains workspace block — skipping."
        exit 0
    fi 

    echo "" >> {{ zshrc }}
    echo "$block" >> {{ zshrc }}
    echo "✔ Added workspace source block to {{ zshrc }}"


[group("shell")]
[doc("Install oh-my-zsh if missing (non-destructive)")]
shell-oh-my-zsh:
    #!/usr/bin/env bash
    set -euo pipefail
    dest="$HOME/.oh-my-zsh"

    if [ -d "$dest" ]; then
        echo "✔ oh-my-zsh already installed at $dest"
        exit 0
    fi

    echo "→ Installing oh-my-zsh via official installer..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Verify installation
    if [ -d "$dest" ]; then
        echo "✔ oh-my-zsh installed: $dest"
    else
        echo "✘ oh-my-zsh installation failed"
        exit 1
    fi

# ══════════════════════════════════════════════════════════════════════════════
# LLM Tooling (OpenCode)
# ══════════════════════════════════════════════════════════════════════════════

[group("llms")]
[doc("Install all OpenCode configs: permissions, agents, skills, and commands")]
llms: llms-configs llms-agents llms-skills llms-commands
    @echo "✔ LLM tooling configured."

[group("llms")]
[doc("Copy OpenCode permission config into ~/.config/opencode/")]
llms-configs:
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{ llms_dir }}/opencode.json"
    dest="{{ opencode_cfg }}/opencode.json"

    if [ ! -f "$src" ]; then
        echo "⊘ No opencode.json found — skipping."
        exit 0
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "✔ OpenCode config installed: $dest"

[group("llms")]
[doc("Symlink agents from this repo into ~/.config/opencode/agents/")]
llms-agents:
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{ llms_dir }}/agents"
    dest="{{ opencode_cfg }}/agents"

    mkdir -p "$dest"

    shopt -s nullglob
    files=("$src"/*.md)
    if [ ${#files[@]} -eq 0 ]; then
        echo "⊘ No agents found in $src — skipping."
        exit 0
    fi

    for f in "${files[@]}"; do
        name=$(basename "$f")
        target="$dest/$name"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$f" ]; then
            continue
        fi
        ln -sf "$f" "$target"
        echo "  → linked agent: $name"
    done
    echo "✔ OpenCode agents linked."

[group("llms")]
[doc("Symlink skills from this repo into ~/.config/opencode/skills/")]
llms-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{ llms_dir }}/skills"
    dest="{{ opencode_cfg }}/skills"

    mkdir -p "$dest"

    shopt -s nullglob
    dirs=("$src"/*/)
    if [ ${#dirs[@]} -eq 0 ]; then
        echo "⊘ No skills found in $src — skipping."
        exit 0
    fi

    for skill_dir in "${dirs[@]}"; do
        name=$(basename "$skill_dir")
        target="$dest/$name"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "${skill_dir%/}" ]; then
            continue
        fi
        ln -sf "${skill_dir%/}" "$target"
        echo "  → linked skill: $name"
    done
    echo "✔ OpenCode skills linked."

[group("llms")]
[doc("Symlink commands from this repo into ~/.config/opencode/commands/")]
llms-commands:
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{ llms_dir }}/commands"
    dest="{{ opencode_cfg }}/commands"

    shopt -s nullglob
    files=("$src"/*.md)
    if [ ${#files[@]} -eq 0 ]; then
        echo "⊘ No commands found in $src — skipping."
        exit 0
    fi

    mkdir -p "$dest"

    for f in "${files[@]}"; do
        name=$(basename "$f")
        target="$dest/$name"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$f" ]; then
            continue
        fi
        ln -sf "$f" "$target"
        echo "  → linked command: $name"
    done
    echo "✔ OpenCode commands linked."