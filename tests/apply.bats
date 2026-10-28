#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  write_manifest tools/core.yaml <<'YAML'
apiVersion: workspace/v1
kind: ToolSet
metadata:
  name: core
spec:
  brew: [git]
YAML
  write_manifest skills.yaml <<'YAML'
apiVersion: workspace/v1
kind: SkillSource
metadata:
  name: local
spec:
  source: ./llms/skills
  skills: ["*"]
YAML
  write_manifest claude.yaml <<'YAML'
apiVersion: workspace/v1
kind: PluginSet
metadata:
  name: claude-code
spec:
  harness: claude-code
  plugins:
    - plain@claude-plugins-official
YAML
  create_skill "$WORKSPACE_DIR/llms/skills/upskill"
  log_stub_calls brew
  log_stub_calls claude
}

apply() {
  bash "$REPO_ROOT/automation/apply.sh" "$@"
}

@test "apply with a ref only touches that resource" {
  run apply skillsource/local
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/skills/upskill" ]
  [ ! -e "$HOME/.claude/settings.json" ]
  [ ! -s "$STUB_LOG" ]
}

@test "apply with a pluginset ref installs plugins and writes the Claude settings" {
  run apply pluginset/claude-code
  [ "$status" -eq 0 ]
  grep -qx "claude plugin install plain@claude-plugins-official --scope user" "$STUB_LOG"
  [ "$(jq -r '."$schema"' "$HOME/.claude/settings.json")" = "https://json.schemastore.org/claude-code-settings.json" ]
}

@test "apply fails for an unknown ref" {
  run apply toolset/missing
  [ "$status" -eq 1 ]
  [[ "$output" == *"resource not found: toolset/missing"* ]]
}

@test "apply rejects --pick without a ref" {
  run apply --pick
  [ "$status" -eq 1 ]
  [[ "$output" == *"--pick needs a toolset ref"* ]]
}

@test "diff (dry run) of everything writes nothing" {
  mkdir -p "$HOME/.oh-my-zsh"
  DRY_RUN=1 run apply
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/upskill" ]
  [ ! -e "$HOME/.claude/settings.json" ]
  [ ! -e "$HOME/.zshrc" ]
  ! grep -q "brew bundle --no-upgrade" "$STUB_LOG"
  ! grep -q "claude plugin install" "$STUB_LOG"
}

@test "get lists the status of a kind" {
  run bash "$REPO_ROOT/automation/get.sh" skillsource
  [ "$status" -eq 0 ]
  [[ "$output" == *"skillsource/local"* ]]
  [[ "$output" == *"✘ upskill"* ]]
}

@test "get fails for an unknown kind" {
  run bash "$REPO_ROOT/automation/get.sh" widgets
  [ "$status" -eq 1 ]
}
