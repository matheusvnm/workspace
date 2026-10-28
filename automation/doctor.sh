#!/usr/bin/env bash
# shellcheck disable=SC2329
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
for module in toolset skillsource claude conventions; do
  source "$WORKSPACE_DIR/automation/kinds/$module.sh"
done

has_failure=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label"
    has_failure=1
  fi
}

is_link_to() { [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; }

is_skill_ready() {
  [ -f "$SKILLS_DIR/$1/SKILL.md" ] && [ "$(skill_frontmatter_name "$SKILLS_DIR/$1")" = "$1" ]
}

is_plugin_installed() { installed_plugin_ids | grep -qxF "$1"; }

is_marketplace_known() { known_marketplace_names | grep -qxF "$1"; }

is_zsh_path_ready() {
  grep -qxF "$ZSH_BLOCK_START" "$HOME/.zshrc" && zsh -ic 'printf %s "$PATH"' 2>/dev/null | grep -qF "$HOME/.local/bin"
}

check "manifests are valid" bash "$WORKSPACE_DIR/automation/validate.sh"
load_manifests

while IFS= read -r toolset; do
  if [ -z "$toolset" ]; then
    continue
  fi
  name="$(toolset_name "$toolset")"
  if HOMEBREW_NO_AUTO_UPDATE=1 with_brewfile "$toolset" brew bundle check --no-upgrade >/dev/null 2>&1; then
    ok "toolset/$name installed"
  else
    warn "toolset/$name incomplete (expected if you skipped items with --pick)"
  fi
  while IFS=' ' read -r type item; do
    if [ -n "$item" ] && is_package_installed "$type" "$item"; then
      warn "$type $item is still installed (toolset/$name lists it in uninstall)"
    fi
  done <<<"$(uninstall_entries "$toolset")"
done <<<"$(resources_of_kind ToolSet)"

for binary in claude node npx yq jq $(query_manifests_raw '.[] | select(.kind == "Installer") | .spec.bin'); do
  check "$binary is on PATH" command -v "$binary"
done
check "Claude settings match the manifests" is_claude_settings_rendered
check "CLAUDE.md is linked" is_link_to "$WORKSPACE_DIR/llms/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
check "starship.toml is linked" is_link_to "$WORKSPACE_DIR/config/starship.toml" "$HOME/.config/starship.toml"

for file in "$WORKSPACE_DIR"/llms/commands/*.md "$WORKSPACE_DIR"/llms/agents/*.md; do
  if [ -f "$file" ]; then
    folder="$(basename "$(dirname "$file")")"
    check "$folder/$(basename "$file") is linked" is_link_to "$file" "$CLAUDE_DIR/$folder/$(basename "$file")"
  fi
done

while IFS= read -r skill; do
  if [ -n "$skill" ]; then
    check "skill $skill is installed" is_skill_ready "$skill"
  fi
done <<<"$(declared_skill_names)"

while IFS=' ' read -r marketplace_name marketplace_source; do
  if [ -n "$marketplace_name" ]; then
    check "marketplace $marketplace_name ($marketplace_source) is known" is_marketplace_known "$marketplace_name"
  fi
done <<<"$(declared_marketplaces)"

while IFS= read -r plugin_id; do
  if [ -n "$plugin_id" ]; then
    check "plugin $plugin_id is installed" is_plugin_installed "$plugin_id"
  fi
done <<<"$(declared_plugin_ids)"

check "no prune candidates" bash "$WORKSPACE_DIR/automation/prune.sh" --check
check "zshrc block is present and ~/.local/bin is on PATH" is_zsh_path_ready

exit "$has_failure"
