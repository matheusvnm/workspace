#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  write_manifest skills.yaml <<'YAML'
apiVersion: workspace/v1
kind: SkillSource
metadata:
  name: remote
spec:
  source: owner/repo
  skills: [kept]
---
apiVersion: workspace/v1
kind: SkillSource
metadata:
  name: local
spec:
  source: ./llms/skills
  skills: ["*"]
YAML
  write_manifest installers.yaml <<'YAML'
apiVersion: workspace/v1
kind: Installer
metadata:
  name: tool
spec:
  bin: tool
  script: automation/installers/tool.sh
  owns:
    skills: ["tool*"]
    commands: ["tool-*"]
YAML
  write_manifest claude.yaml <<'YAML'
apiVersion: workspace/v1
kind: PluginSet
metadata:
  name: claude-code
spec:
  harness: claude-code
  marketplaces:
    - name: kept-market
      source: owner/kept-market
  plugins:
    - kept@kept-market
YAML
  create_skill "$WORKSPACE_DIR/llms/skills/mine"
  touch "$WORKSPACE_DIR/llms/commands/bruh.md"
  create_skill "$HOME/.claude/skills/kept"
  create_skill "$HOME/.claude/skills/tool-jira"
  create_skill "$HOME/.claude/skills/orphan"
  ln -s "$WORKSPACE_DIR/llms/skills/mine" "$HOME/.claude/skills/mine"
  log_stub_calls npx
  log_stub_calls claude
}

prune() {
  bash "$REPO_ROOT/automation/prune.sh" "$@"
}

write_plugin_state() {
  mkdir -p "$HOME/.claude/plugins"
  printf '%s\n' "$1" >"$HOME/.claude/plugins/known_marketplaces.json"
  printf '%s\n' "$2" >"$HOME/.claude/plugins/installed_plugins.json"
}

@test "dry run lists only undeclared skills and deletes nothing" {
  run prune --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"$HOME/.claude/skills/orphan"* ]]
  [[ "$output" != *"skills/kept "* ]]
  [[ "$output" != *"tool-jira"* ]]
  [[ "$output" != *"skills/mine "* ]]
  [[ "$output" == *"1 candidates"* ]]
  [ -d "$HOME/.claude/skills/orphan" ]
}

@test "a broken symlink is a candidate even when its name is declared" {
  rm -rf "$HOME/.claude/skills/kept"
  ln -s /nonexistent "$HOME/.claude/skills/kept"
  run prune --dry-run
  [[ "$output" == *"$HOME/.claude/skills/kept (broken symlink"* ]]
}

@test "the synced skills folder is never a candidate" {
  mkdir -p "$HOME/.claude/skills/synced"
  run prune --dry-run
  [[ "$output" != *"synced"* ]]
}

@test "repo commands and owned commands are kept" {
  mkdir -p "$HOME/.claude/commands"
  ln -s "$WORKSPACE_DIR/llms/commands/bruh.md" "$HOME/.claude/commands/bruh.md"
  touch "$HOME/.claude/commands/tool-review.md" "$HOME/.claude/commands/old.md"
  run prune --dry-run
  [[ "$output" == *"commands/old.md"* ]]
  [[ "$output" != *"commands/bruh.md"* ]]
  [[ "$output" != *"tool-review.md"* ]]
}

@test "undeclared agents are candidates" {
  mkdir -p "$HOME/.claude/agents"
  touch "$HOME/.claude/agents/stray.md"
  run prune --dry-run
  [[ "$output" == *"$HOME/.claude/agents/stray.md"* ]]
}

@test "only owned skills stay in ~/.agents/skills" {
  create_skill "$HOME/.agents/skills/tool-jira"
  create_skill "$HOME/.agents/skills/humanizer"
  run prune --dry-run
  [[ "$output" == *"$HOME/.agents/skills/humanizer"* ]]
  [[ "$output" != *".agents/skills/tool-jira"* ]]
}

@test "obsolete OpenCode and Codex folders are candidates" {
  mkdir -p "$HOME/.config/opencode" "$HOME/.cache/opencode" "$HOME/.codex"
  run prune --dry-run
  [[ "$output" == *"$HOME/.config/opencode (obsolete"* ]]
  [[ "$output" == *"$HOME/.cache/opencode (obsolete"* ]]
  [[ "$output" == *"$HOME/.codex (obsolete"* ]]
}

@test "undeclared plugins and marketplaces are candidates" {
  write_plugin_state '{"kept-market":{},"claude-plugins-official":{},"stray-market":{}}' \
    '{"version":2,"plugins":{"kept@kept-market":[],"stray@stray-market":[]}}'
  run prune --dry-run
  [[ "$output" == *"Claude plugin stray@stray-market"* ]]
  [[ "$output" == *"Claude marketplace stray-market"* ]]
  [[ "$output" != *"kept@kept-market"* ]]
  [[ "$output" != *"marketplace claude-plugins-official"* ]]
  [[ "$output" != *"marketplace kept-market"* ]]
  [ ! -s "$STUB_LOG" ]
}

@test "confirmed plugin and marketplace candidates are removed with the claude CLI" {
  write_plugin_state '{"stray-market":{}}' '{"version":2,"plugins":{"stray@stray-market":[]}}'
  WORKSPACE_CONFIRM=y run prune
  [ "$status" -eq 0 ]
  grep -qx "claude plugin uninstall stray@stray-market --scope user" "$STUB_LOG"
  grep -qx "claude plugin marketplace remove stray-market" "$STUB_LOG"
}

@test "confirmed candidates are deleted" {
  WORKSPACE_CONFIRM=y run prune
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/orphan" ]
  [ -d "$HOME/.claude/skills/kept" ]
}

@test "declined candidates are kept" {
  WORKSPACE_CONFIRM=n run prune
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude/skills/orphan" ]
}

@test "lock-tracked skills are removed with the skills CLI for claude-code" {
  mkdir -p "$HOME/.agents"
  echo '{"version":3,"skills":{"orphan":{"source":"x/y"}}}' >"$HOME/.agents/.skill-lock.json"
  WORKSPACE_CONFIRM=y run prune
  grep -qx "npx -y skills remove -g -a claude-code -y orphan" "$STUB_LOG"
  [ ! -e "$HOME/.claude/skills/orphan" ]
}

@test "check mode fails with candidates and passes without" {
  run prune --check
  [ "$status" -eq 1 ]
  rm -rf "$HOME/.claude/skills/orphan"
  run prune --check
  [ "$status" -eq 0 ]
}
