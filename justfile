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
    brew bundle --file={{ deps_dir }}/Brewfile
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
shell: shell-starship shell-zshrc
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
    [ -f "WORKSPACE_DIR/config/.aliases" ]   && source "WORKSPACE_DIR/config/.aliases"
    [ -f "WORKSPACE_DIR/config/.functions" ] && source "WORKSPACE_DIR/config/.functions"
    # <<< workspace-bootstrap <<<
    BLOCK
    )
    block="${block//WORKSPACE_DIR/{{ workspace }}}"

    if grep -qF "$marker" {{ zshrc }} 2>/dev/null; then
        echo "✔ .zshrc already contains workspace block — skipping."
    else
        echo "" >> {{ zshrc }}
        echo "$block" >> {{ zshrc }}
        echo "✔ Added workspace source block to {{ zshrc }}"
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

# ══════════════════════════════════════════════════════════════════════════════
# Health Check & Diagnostics
# ══════════════════════════════════════════════════════════════════════════════

[group("health")]
[doc("Verify which workspace tools are installed and reachable")]
doctor:
    #!/usr/bin/env bash
    set -uo pipefail
    ok=0; missing=0

    check() {
        if command -v "$1" &>/dev/null; then
            printf "  ✔ %-14s %s\n" "$1" "$(command -v "$1")"
            ((ok++))
        else
            printf "  ✘ %-14s not found\n" "$1"
            ((missing++))
        fi
    }

    echo "CLI tools:"
    for cmd in brew git gh just jq tree wget btop uv acli aws gcloud; do
        check "$cmd"
    done

    echo ""
    echo "LLM tools:"
    for cmd in claude opencode; do
        check "$cmd"
    done

    echo ""
    echo "Shell:"
    check starship

    echo ""
    echo "Symlinks:"
    for link in "{{ starship_cfg }}"; do
        if [ -L "$link" ]; then
            printf "  ✔ %-40s → %s\n" "$link" "$(readlink "$link")"
        elif [ -e "$link" ]; then
            printf "  ⚠ %-40s exists but is not a symlink\n" "$link"
        else
            printf "  ✘ %-40s missing\n" "$link"
            ((missing++))
        fi
    done

    echo ""
    echo "Result: $ok ok, $missing missing"
    [ $missing -eq 0 ] || echo "Run 'just setup' to fix missing items."
