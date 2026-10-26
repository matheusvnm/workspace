#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
source "$WORKSPACE_DIR/automation/kinds/opencode.sh"
source "$WORKSPACE_DIR/automation/kinds/skillsource.sh"

mode=delete
case "${1:-}" in
  "") ;;
  --dry-run) mode=dry-run ;;
  --check) mode=check ;;
  *) die "usage: prune.sh [--dry-run|--check]" ;;
esac

candidate_count=0
deleted_count=0
lock_file="$HOME/.agents/.skill-lock.json"
cache_dir="${OPENCODE_CACHE_DIR:-$HOME/.cache/opencode}"

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
    DISABLE_TELEMETRY=1 npx -y skills remove -g -y "$name" </dev/null || warn "skills remove failed for $name"
  fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    rm -rf "$path"
  fi
}

consider() {
  local path="$1" reason="$2"
  candidate_count=$((candidate_count + 1))
  printf '• %s (%s, %s)\n' "$path" "$reason" "$(describe_path "$path")"
  if [ "$mode" != delete ]; then
    return 0
  fi
  if confirm "Delete $path?"; then
    remove_path "$path"
    deleted_count=$((deleted_count + 1))
    ok "deleted $path"
  fi
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
      consider "$entry" "broken symlink"
      continue
    fi
    if matches_any "$name" "$declared"; then
      continue
    fi
    consider "$entry" "undeclared"
  done
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

scan_dir "$SKILLS_DIR" "$declared_skills"
scan_dir "$HOME/.claude/skills" "$owned_skills" "synced"
scan_dir "$HOME/.claude/agents" "$owned_agents"
scan_dir "$HOME/.codex/skills" ""
scan_dir "$OPENCODE_DIR/skills" ""
scan_dir "$OPENCODE_DIR/agents" "$declared_agents"
scan_dir "$OPENCODE_DIR/commands" "$declared_commands"
scan_dir "$cache_dir/packages" ""

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
    log "$deleted_count of $candidate_count candidates deleted"
    if [ "$deleted_count" -gt 0 ]; then
      restart_opencode_service
    fi
    ;;
esac
