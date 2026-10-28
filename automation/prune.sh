#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
source "$WORKSPACE_DIR/automation/kinds/skillsource.sh"
source "$WORKSPACE_DIR/automation/kinds/claude.sh"

mode=delete
case "${1:-}" in
  "") ;;
  --dry-run) mode=dry-run ;;
  --check) mode=check ;;
  *) die "usage: prune.sh [--dry-run|--check]" ;;
esac

candidate_count=0
removed_count=0
lock_file="$HOME/.agents/.skill-lock.json"
built_in_marketplaces="claude-plugins-official"
obsolete_paths="$HOME/.config/opencode
$HOME/.cache/opencode
$HOME/.codex"

matches_any() {
  local name="$1" patterns="$2" pattern
  while IFS= read -r pattern; do
    if [ -z "$pattern" ]; then
      continue
    fi
    # shellcheck disable=SC2254
    case "$name" in
      $pattern) return 0 ;;
    esac
  done <<<"$patterns"
  return 1
}

describe_path() {
  local path="$1"
  if [ -L "$path" ] && [ -e "$path" ]; then
    printf 'symlink -> %s' "$(readlink "$path")"
  elif [ -L "$path" ]; then
    printf 'broken symlink -> %s' "$(readlink "$path")"
  elif [ -d "$path" ]; then
    printf 'directory'
  else
    printf 'file'
  fi
}

is_lock_tracked() {
  [ -f "$lock_file" ] && jq -e --arg name "$1" '.skills[$name]' "$lock_file" >/dev/null 2>&1
}

remove_path() {
  local path="$1" name
  name="$(basename "$path")"
  if [ "$(dirname "$path")" = "$SKILLS_DIR" ] && is_lock_tracked "$name"; then
    DISABLE_TELEMETRY=1 npx -y skills remove -g -a claude-code -y "$name" </dev/null || warn "skills remove failed for $name"
  fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    rm -rf "$path"
  fi
}

offer() {
  local description="$1"
  shift
  candidate_count=$((candidate_count + 1))
  printf '• %s\n' "$description"
  if [ "$mode" != delete ] || ! confirm "Remove $description?"; then
    return 0
  fi
  if "$@" </dev/null; then
    removed_count=$((removed_count + 1))
    ok "removed $description"
  else
    warn "could not remove $description"
  fi
}

consider_path() {
  offer "$1 ($2, $(describe_path "$1"))" remove_path "$1"
}

scan_dir() {
  local dir="$1" declared="$2" skipped="${3:-}" entry name
  if [ ! -d "$dir" ]; then
    return 0
  fi
  for entry in "$dir"/*; do
    if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
      continue
    fi
    name="$(basename "$entry")"
    if matches_any "$name" "$skipped"; then
      continue
    fi
    if [ -L "$entry" ] && [ ! -e "$entry" ]; then
      consider_path "$entry" "broken symlink"
      continue
    fi
    if matches_any "$name" "$declared"; then
      continue
    fi
    consider_path "$entry" "undeclared"
  done
}

scan_plugins() {
  local declared plugin_id
  declared="$(declared_plugin_ids)"
  while IFS= read -r plugin_id; do
    if [ -n "$plugin_id" ] && ! grep -qxF "$plugin_id" <<<"$declared"; then
      offer "Claude plugin $plugin_id (undeclared)" claude plugin uninstall "$plugin_id" --scope user
    fi
  done <<<"$(installed_plugin_ids)"
}

scan_marketplaces() {
  local declared name
  declared="$(declared_marketplaces | cut -d' ' -f1)
$built_in_marketplaces"
  while IFS= read -r name; do
    if [ -n "$name" ] && ! grep -qxF "$name" <<<"$declared"; then
      offer "Claude marketplace $name (undeclared)" claude plugin marketplace remove "$name"
    fi
  done <<<"$(known_marketplace_names)"
}

scan_obsolete_paths() {
  local path
  while IFS= read -r path; do
    if [ -e "$path" ] || [ -L "$path" ]; then
      consider_path "$path" "obsolete"
    fi
  done <<<"$obsolete_paths"
}

load_manifests

owned_skills="$(owned_names skills)"
owned_commands="$(owned_names commands)"
owned_agents="$(owned_names agents)"
declared_skills="$(declared_skill_names)
$owned_skills"
declared_commands="$(markdown_names "$WORKSPACE_DIR/llms/commands")
$owned_commands"
declared_agents="$(markdown_names "$WORKSPACE_DIR/llms/agents")
$owned_agents"

scan_dir "$SKILLS_DIR" "$declared_skills" "synced"
scan_dir "$CLAUDE_DIR/agents" "$declared_agents"
scan_dir "$CLAUDE_DIR/commands" "$declared_commands"
scan_dir "$HOME/.agents/skills" "$owned_skills"
scan_plugins
scan_marketplaces
scan_obsolete_paths

case "$mode" in
  check)
    if [ "$candidate_count" -gt 0 ]; then
      fail "$candidate_count prune candidates (run: just prune)"
      exit 1
    fi
    ok "no prune candidates"
    ;;
  dry-run)
    log "$candidate_count candidates (dry run, nothing deleted)"
    ;;
  delete)
    log "$removed_count of $candidate_count candidates removed"
    ;;
esac
