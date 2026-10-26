#!/usr/bin/env bash
# shellcheck disable=SC2329
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
for module in toolset skillsource opencode conventions; do
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

is_opencode_rendered() {
  local rendered exit_status
  rendered="$(mktemp)"
  render_opencode_config >"$rendered"
  cmp -s "$rendered" "$OPENCODE_DIR/opencode.json"
  exit_status=$?
  rm -f "$rendered"
  return "$exit_status"
}

is_skill_ready() {
  [ -f "$SKILLS_DIR/$1/SKILL.md" ] && [ "$(skill_frontmatter_name "$SKILLS_DIR/$1")" = "$1" ]
}

is_opencode_v2() {
  local major
  major="$(opencode_major_version)"
  [ -n "$major" ] && [ "$major" -ge 2 ]
}

contains_text() { grep -qiF -- "$2" <<<"$1"; }

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
done <<<"$(resources_of_kind ToolSet)"

for binary in opencode node npx yq jq $(query_manifests_raw '.[] | select(.kind == "Installer") | .spec.bin'); do
  check "$binary is on PATH" command -v "$binary"
done
check "OpenCode is version 2 or later" is_opencode_v2
check "opencode.json matches the manifests" is_opencode_rendered
check "AGENTS.md is linked" is_link_to "$WORKSPACE_DIR/llms/AGENTS.md" "$OPENCODE_DIR/AGENTS.md"
check "starship.toml is linked" is_link_to "$WORKSPACE_DIR/config/starship.toml" "$HOME/.config/starship.toml"

for file in "$WORKSPACE_DIR"/llms/commands/*.md "$WORKSPACE_DIR"/llms/agents/*.md; do
  if [ -f "$file" ]; then
    folder="$(basename "$(dirname "$file")")"
    check "$folder/$(basename "$file") is linked" is_link_to "$file" "$OPENCODE_DIR/$folder/$(basename "$file")"
  fi
done

declared_skills="$(declared_skill_names)"
while IFS= read -r skill; do
  if [ -n "$skill" ]; then
    check "skill $skill is installed" is_skill_ready "$skill"
  fi
done <<<"$declared_skills"

check "no prune candidates" bash "$WORKSPACE_DIR/automation/prune.sh" --check

plugin_list="$(opencode_output plugin list || true)"
check "OpenCode loads claude-auth" contains_text "$plugin_list" "claude-auth"
check "OpenCode loads plannotator" contains_text "$plugin_list" "plannotator"

skill_list="$(opencode_output api skill.list || true)"
while IFS= read -r skill; do
  if [ -n "$skill" ]; then
    check "OpenCode sees skill $skill" contains_text "$skill_list" "$skill"
  fi
done <<<"$declared_skills"

command_list="$(opencode_output api command.list || true)"
for command_name in run bruh plannotator-review plannotator-annotate plannotator-last; do
  check "OpenCode sees command /$command_name" contains_text "$command_list" "$command_name"
done

check "zshrc block is present and ~/.local/bin is on PATH" is_zsh_path_ready

exit "$has_failure"
