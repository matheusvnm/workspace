#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation claude
  write_manifest claude.yaml <<'YAML'
apiVersion: workspace/v1
kind: PluginSet
metadata:
  name: claude-code
spec:
  harness: claude-code
  marketplaces:
    - name: plannotator
      source: backnotprop/plannotator
  plugins:
    - plannotator@plannotator
    - other@claude-plugins-official
---
apiVersion: workspace/v1
kind: PermissionPolicy
metadata:
  name: claude-code
spec:
  harness: claude-code
  defaultMode: acceptEdits
  additionalDirectories: ["~/.claude/plans"]
  allow: ["Bash(git status *)"]
  ask: ["Bash(git push --force*)"]
  deny: ["Read(//**/.env)"]
---
apiVersion: workspace/v1
kind: PermissionPolicy
metadata:
  name: extra
spec:
  harness: claude-code
  allow: ["WebFetch"]
YAML
  load_manifests
  SETTINGS="$HOME/.claude/settings.json"
}

write_plugin_state() {
  mkdir -p "$HOME/.claude/plugins"
  printf '%s\n' "$1" >"$HOME/.claude/plugins/known_marketplaces.json"
  printf '%s\n' "$2" >"$HOME/.claude/plugins/installed_plugins.json"
}

@test "permissions merge every policy and expand the home folder" {
  run render_claude_permissions
  [ "$status" -eq 0 ]
  [ "$(jq -c .allow <<<"$output")" = '["Bash(git status *)","WebFetch"]' ]
  [ "$(jq -c .deny <<<"$output")" = '["Read(//**/.env)"]' ]
  [ "$(jq -r .defaultMode <<<"$output")" = acceptEdits ]
  [ "$(jq -r '.additionalDirectories[0]' <<<"$output")" = "$HOME/.claude/plans" ]
}

@test "settings apply creates the file when it is missing" {
  claude_settings_apply
  [ "$(jq -r '."$schema"' "$SETTINGS")" = "https://json.schemastore.org/claude-code-settings.json" ]
  [ "$(jq -c .permissions.ask "$SETTINGS")" = '["Bash(git push --force*)"]' ]
}

@test "settings apply keeps the keys that Claude Code owns" {
  mkdir -p "$HOME/.claude"
  echo '{"model":"opus","enabledPlugins":{"x@y":true},"permissions":{"allow":["Bash(rm *)"]}}' >"$SETTINGS"
  WORKSPACE_CONFIRM=y run claude_settings_apply
  [ "$status" -eq 0 ]
  [ "$(jq -r .model "$SETTINGS")" = opus ]
  [ "$(jq -r '.enabledPlugins["x@y"]' "$SETTINGS")" = true ]
  [ "$(jq -c .permissions.allow "$SETTINGS")" = '["Bash(git status *)","WebFetch"]' ]
  backups=("$HOME"/.claude/settings.json.backup.*)
  [ "$(jq -c .permissions.allow "${backups[0]}")" = '["Bash(rm *)"]' ]
}

@test "settings apply is a no-op when only the format differs" {
  claude_settings_apply
  jq -c . "$SETTINGS" >"$SETTINGS.compact"
  mv "$SETTINGS.compact" "$SETTINGS"
  run claude_settings_apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"Claude settings up to date"* ]]
  [ -z "$(ls "$HOME/.claude" | grep backup || true)" ]
}

@test "settings apply keeps the file when the user declines" {
  mkdir -p "$HOME/.claude"
  echo '{"model":"opus"}' >"$SETTINGS"
  WORKSPACE_CONFIRM=n run claude_settings_apply
  [ "$status" -eq 0 ]
  [ "$(cat "$SETTINGS")" = '{"model":"opus"}' ]
}

@test "settings apply in dry run shows the diff and writes nothing" {
  mkdir -p "$HOME/.claude"
  echo '{"model":"opus"}' >"$SETTINGS"
  DRY_RUN=1 run claude_settings_apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"+++"* ]]
  [ "$(cat "$SETTINGS")" = '{"model":"opus"}' ]
}

@test "settings apply fails on a file that is not JSON" {
  mkdir -p "$HOME/.claude"
  echo 'not json' >"$SETTINGS"
  run claude_settings_apply
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not valid JSON"* ]]
}

@test "plugins apply adds missing marketplaces and plugins" {
  log_stub_calls claude
  claude_plugins_apply
  grep -qx "claude plugin marketplace add backnotprop/plannotator --scope user" "$STUB_LOG"
  grep -qx "claude plugin install plannotator@plannotator --scope user" "$STUB_LOG"
  grep -qx "claude plugin install other@claude-plugins-official --scope user" "$STUB_LOG"
}

@test "plugins apply adds the marketplaces but not the plugins that the user declines" {
  log_stub_calls claude
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none run claude_plugins_apply
  [ "$status" -eq 0 ]
  grep -qx "claude plugin marketplace add backnotprop/plannotator --scope user" "$STUB_LOG"
  ! grep -q "claude plugin install" "$STUB_LOG"
}

@test "plugins apply skips what is already present" {
  write_plugin_state '{"plannotator":{}}' '{"version":2,"plugins":{"plannotator@plannotator":[],"other@claude-plugins-official":[]}}'
  log_stub_calls claude
  run claude_plugins_apply
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
}

@test "plugins apply in dry run calls nothing" {
  log_stub_calls claude
  DRY_RUN=1 run claude_plugins_apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"would add marketplace plannotator (backnotprop/plannotator)"* ]]
  [[ "$output" == *"would install plugin plannotator@plannotator"* ]]
  [ ! -s "$STUB_LOG" ]
}

@test "status reports missing plugins and settings drift" {
  write_plugin_state '{"plannotator":{}}' '{"version":2,"plugins":{"plannotator@plannotator":[]}}'
  run claude_status
  [ "$status" -eq 0 ]
  [[ "$output" == *"✔ plugin plannotator@plannotator"* ]]
  [[ "$output" == *"✘ plugin other@claude-plugins-official"* ]]
  [[ "$output" == *"drifted"* ]]
}

@test "the repo manifests render the Claude Code permissions" {
  MANIFEST_DIR="$REPO_ROOT/manifests" load_manifests
  run render_claude_permissions
  [ "$status" -eq 0 ]
  jq -e '.allow | index("Bash(git push *)")' <<<"$output" >/dev/null
  jq -e '.ask | index("Bash(git push --force*)")' <<<"$output" >/dev/null
  jq -e '.ask | index("Read(//**/.env)")' <<<"$output" >/dev/null
  [ "$(jq -r .defaultMode <<<"$output")" = acceptEdits ]
}
