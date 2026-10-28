#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  export SKILLS_DIR="$HOME/.agents/skills"
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
  create_skill "$WORKSPACE_DIR/llms/skills/mine"
  touch "$WORKSPACE_DIR/llms/commands/run.md"
  create_skill "$HOME/.agents/skills/kept"
  create_skill "$HOME/.agents/skills/tool-jira"
  create_skill "$HOME/.agents/skills/orphan"
  ln -s "$WORKSPACE_DIR/llms/skills/mine" "$HOME/.agents/skills/mine"
  log_stub_calls npx
}

prune() {
  bash "$REPO_ROOT/automation/prune.sh" "$@"
}

@test "dry run lists only undeclared entries and deletes nothing" {
  run prune --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"$HOME/.agents/skills/orphan"* ]]
  [[ "$output" != *"skills/kept "* ]]
  [[ "$output" != *"tool-jira"* ]]
  [[ "$output" != *"skills/mine "* ]]
  [[ "$output" == *"1 candidates"* ]]
  [ -d "$HOME/.agents/skills/orphan" ]
}

@test "a broken symlink is a candidate even when its name is declared" {
  ln -s /nonexistent "$HOME/.agents/skills/kept-broken"
  rm -rf "$HOME/.agents/skills/kept"
  ln -s /nonexistent "$HOME/.agents/skills/kept"
  run prune --dry-run
  [[ "$output" == *"$HOME/.agents/skills/kept (broken symlink"* ]]
}

@test "claude synced dir is never a candidate" {
  mkdir -p "$HOME/.claude/skills/synced" "$HOME/.claude/skills/stray"
  run prune --dry-run
  [[ "$output" != *"synced"* ]]
  [[ "$output" == *"$HOME/.claude/skills/stray"* ]]
}

@test "commands from the repo and owned commands are kept" {
  mkdir -p "$HOME/.config/opencode/commands"
  ln -s "$WORKSPACE_DIR/llms/commands/run.md" "$HOME/.config/opencode/commands/run.md"
  touch "$HOME/.config/opencode/commands/tool-review.md" "$HOME/.config/opencode/commands/old.md"
  run prune --dry-run
  [[ "$output" == *"commands/old.md"* ]]
  [[ "$output" != *"commands/run.md"* ]]
  [[ "$output" != *"tool-review.md"* ]]
}

@test "every entry of the OpenCode 1 plugin cache is a candidate" {
  mkdir -p "$HOME/.cache/opencode/packages/superpowers@git+https:"
  run prune --dry-run
  [[ "$output" == *"packages/superpowers@git+https:"* ]]
}

@test "confirmed candidates are deleted" {
  WORKSPACE_CONFIRM=y run prune
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.agents/skills/orphan" ]
  [ -d "$HOME/.agents/skills/kept" ]
}

@test "declined candidates are kept" {
  WORKSPACE_CONFIRM=n run prune
  [ "$status" -eq 0 ]
  [ -d "$HOME/.agents/skills/orphan" ]
}

@test "lock-tracked skills are removed with the skills CLI" {
  mkdir -p "$HOME/.agents"
  echo '{"version":3,"skills":{"orphan":{"source":"x/y"}}}' >"$HOME/.agents/.skill-lock.json"
  WORKSPACE_CONFIRM=y run prune
  grep -qx "npx -y skills remove -g -y orphan" "$STUB_LOG"
  [ ! -e "$HOME/.agents/skills/orphan" ]
}

@test "check mode fails with candidates and passes without" {
  run prune --check
  [ "$status" -eq 1 ]
  rm -rf "$HOME/.agents/skills/orphan"
  run prune --check
  [ "$status" -eq 0 ]
}
