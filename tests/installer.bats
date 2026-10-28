#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation installer
  mkdir -p "$WORKSPACE_DIR/scripts"
  write_manifest installers.yaml <<'YAML'
apiVersion: workspace/v1
kind: Installer
metadata:
  name: present
spec:
  bin: present-tool
  script: scripts/present.sh
---
apiVersion: workspace/v1
kind: Installer
metadata:
  name: missing
spec:
  bin: missing-tool
  script: scripts/missing.sh
YAML
  printf 'echo "ran missing.sh" >>"$STUB_LOG"\nprintf "#!/bin/sh\\n" >"$STUB_BIN/missing-tool"\nchmod +x "$STUB_BIN/missing-tool"\n' >"$WORKSPACE_DIR/scripts/missing.sh"
  stub_command present-tool 'exit 0'
  load_manifests
}

@test "installers apply runs only the scripts of the missing installers" {
  run installers_apply installers <<<"$(resources_of_kind Installer)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"installer/present present"* ]]
  [[ "$output" == *"installer/missing installed"* ]]
  [ "$(cat "$STUB_LOG")" = "ran missing.sh" ]
}

@test "installers apply runs no script when the user declines the group" {
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none run installers_apply installers <<<"$(resources_of_kind Installer)"
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
  grep -qx "installer/missing" "$HOME/.config/workspace/skipped"
}
