#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation
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
  name: remote
spec:
  source: owner/repo
  skills: [alpha, beta]
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
YAML
}

@test "load_manifests reads every document of every file" {
  load_manifests
  [ "$(jq length <<<"$MANIFEST_JSON")" -eq 4 ]
}

@test "load_manifests fails when the manifest dir has no yaml" {
  rm -rf "$MANIFEST_DIR"/*
  run load_manifests
  [ "$status" -eq 1 ]
  [[ "$output" == *"no manifests"* ]]
}

@test "resource_by_ref finds a resource with a case-insensitive kind" {
  load_manifests
  run resource_by_ref ToolSet/core
  [ "$status" -eq 0 ]
  [ "$(jq -r .metadata.name <<<"$output")" = core ]
  run resource_by_ref toolset/core
  [ "$(jq -r .kind <<<"$output")" = ToolSet ]
}

@test "resource_by_ref fails for an unknown resource" {
  load_manifests
  run resource_by_ref toolset/missing
  [ "$status" -eq 1 ]
  [[ "$output" == *"resource not found: toolset/missing"* ]]
}

@test "resource_by_ref fails for a ref without a slash" {
  load_manifests
  run resource_by_ref core
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid ref"* ]]
}

@test "declared_skill_names lists remote skills and local skill folders" {
  create_skill "$WORKSPACE_DIR/llms/skills/local-one"
  mkdir -p "$WORKSPACE_DIR/llms/skills/not-a-skill"
  load_manifests
  run declared_skill_names
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | sort | tr '\n' ' ')" = "alpha beta local-one " ]
}

@test "owned_names lists the owned globs of a type" {
  load_manifests
  [ "$(owned_names skills)" = "tool*" ]
  [ -z "$(owned_names commands)" ]
}
