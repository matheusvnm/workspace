#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation opencode
  write_manifest opencode.yaml <<'YAML'
apiVersion: workspace/v1
kind: PluginSet
metadata:
  name: opencode
spec:
  harness: opencode
  plugins:
    - package: plain@latest
    - package: "@scope/with-options@latest"
      options:
        mode: fast
---
apiVersion: workspace/v1
kind: PermissionPolicy
metadata:
  name: opencode
spec:
  harness: opencode
  rules:
    shell:
      deny: ["rm -rf /*"]
      ask: ["git push --force*"]
      allow: ["git status *"]
      default: ask
    read:
      default: allow
      ask: ["*.env"]
YAML
  load_manifests
}

@test "render writes fixed shell and update keys" {
  run render_opencode_config
  [ "$status" -eq 0 ]
  [ "$(jq -r .shell <<<"$output")" = zsh ]
  [ "$(jq -r .update <<<"$output")" = disable ]
  [ "$(jq -r '."$schema"' <<<"$output")" = "https://opencode.ai/config.json" ]
}

@test "render keeps a plugin without options as a string" {
  [ "$(render_opencode_config | jq -c '.plugins[0]')" = '"plain@latest"' ]
}

@test "render turns a plugin with options into an object" {
  [ "$(render_opencode_config | jq -c '.plugins[1]')" = '{"package":"@scope/with-options@latest","options":{"mode":"fast"}}' ]
}

@test "render orders rules default, allow, ask, deny for each action" {
  actual="$(render_opencode_config | jq -r '.permissions[] | "\(.action) \(.effect) \(.resource)"')"
  expected="shell ask *
shell allow git status *
shell ask git push --force*
shell deny rm -rf /*
read allow *
read ask *.env"
  [ "$actual" = "$expected" ]
}

@test "apply writes the config when it is missing" {
  opencode_apply
  cmp -s <(render_opencode_config) "$HOME/.config/opencode/opencode.json"
}

@test "apply is a no-op when the config matches" {
  opencode_apply
  run opencode_apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"opencode.json up to date"* ]]
  [ -z "$(ls "$HOME/.config/opencode" | grep backup || true)" ]
}

@test "apply keeps a different config when the user declines" {
  mkdir -p "$HOME/.config/opencode"
  echo '{"plugin":["old"]}' >"$HOME/.config/opencode/opencode.json"
  WORKSPACE_CONFIRM=n run opencode_apply
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.config/opencode/opencode.json")" = '{"plugin":["old"]}' ]
}

@test "apply backs up and replaces a different config when the user confirms" {
  mkdir -p "$HOME/.config/opencode"
  echo '{"plugin":["old"]}' >"$HOME/.config/opencode/opencode.json"
  WORKSPACE_CONFIRM=y run opencode_apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"/connect"* ]]
  cmp -s <(render_opencode_config) "$HOME/.config/opencode/opencode.json"
  backups=("$HOME"/.config/opencode/opencode.json.backup.*)
  [ "$(cat "${backups[0]}")" = '{"plugin":["old"]}' ]
}

@test "apply in dry run shows the diff and writes nothing" {
  mkdir -p "$HOME/.config/opencode"
  echo '{}' >"$HOME/.config/opencode/opencode.json"
  DRY_RUN=1 run opencode_apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"+++"* ]]
  [ "$(cat "$HOME/.config/opencode/opencode.json")" = '{}' ]
}

@test "the repo manifests render both plugins and an explicit external_directory default" {
  MANIFEST_DIR="$REPO_ROOT/manifests" load_manifests
  run render_opencode_config
  [ "$status" -eq 0 ]
  [ "$(jq '.plugins | length' <<<"$output")" -eq 2 ]
  [ "$(jq -r '.permissions[] | select(.action == "external_directory" and .resource == "*") | .effect' <<<"$output")" = ask ]
}
