#!/usr/bin/env bats

load helpers

setup() {
  command -v uvx >/dev/null || skip "uvx is not installed"
  setup_workspace
  write_manifest tools/core.yaml <<'YAML'
apiVersion: workspace/v1
kind: ToolSet
metadata:
  name: core
spec:
  brew: [git]
YAML
}

validate() {
  bash "$REPO_ROOT/automation/validate.sh"
}

@test "validate accepts valid manifests" {
  run validate
  [ "$status" -eq 0 ]
  [[ "$output" == *"manifests valid (1 documents)"* ]]
}

@test "validate rejects an unknown kind" {
  write_manifest bad.yaml <<'YAML'
apiVersion: workspace/v1
kind: Unknown
metadata:
  name: bad
spec: {}
YAML
  run validate
  [ "$status" -ne 0 ]
}

@test "validate rejects an unknown spec key" {
  write_manifest bad.yaml <<'YAML'
apiVersion: workspace/v1
kind: ToolSet
metadata:
  name: extra
spec:
  brew: [git]
  pip: [requests]
YAML
  run validate
  [ "$status" -ne 0 ]
}

@test "validate rejects a duplicate kind and name" {
  write_manifest tools/again.yaml <<'YAML'
apiVersion: workspace/v1
kind: ToolSet
metadata:
  name: core
spec:
  brew: [jq]
YAML
  run validate
  [ "$status" -eq 1 ]
  [[ "$output" == *"duplicate resources: ToolSet/core"* ]]
}

@test "validate rejects a wildcard on a remote skill source" {
  write_manifest skills.yaml <<'YAML'
apiVersion: workspace/v1
kind: SkillSource
metadata:
  name: remote
spec:
  source: owner/repo
  skills: ["*"]
YAML
  run validate
  [ "$status" -eq 1 ]
  [[ "$output" == *'remote SkillSource cannot use "*": remote'* ]]
}
