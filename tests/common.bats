#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation
}

@test "confirm returns yes when WORKSPACE_CONFIRM is y" {
  WORKSPACE_CONFIRM=y run confirm "Proceed?"
  [ "$status" -eq 0 ]
}

@test "confirm returns no when WORKSPACE_CONFIRM is n" {
  WORKSPACE_CONFIRM=n run confirm "Proceed?"
  [ "$status" -eq 1 ]
}

@test "ensure_link creates a missing link and its parent dir" {
  touch "$WORKSPACE_DIR/source.md"
  ensure_link "$WORKSPACE_DIR/source.md" "$HOME/a/b/target.md"
  [ "$(readlink "$HOME/a/b/target.md")" = "$WORKSPACE_DIR/source.md" ]
}

@test "ensure_link is silent when the link is already correct" {
  touch "$WORKSPACE_DIR/source.md"
  ln -s "$WORKSPACE_DIR/source.md" "$HOME/target.md"
  run ensure_link "$WORKSPACE_DIR/source.md" "$HOME/target.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ensure_link replaces a link that points somewhere else" {
  touch "$WORKSPACE_DIR/source.md"
  ln -s /nonexistent/old.md "$HOME/target.md"
  ensure_link "$WORKSPACE_DIR/source.md" "$HOME/target.md"
  [ "$(readlink "$HOME/target.md")" = "$WORKSPACE_DIR/source.md" ]
}

@test "ensure_link keeps a regular file when the user declines" {
  touch "$WORKSPACE_DIR/source.md"
  echo original >"$HOME/target.md"
  WORKSPACE_CONFIRM=n run ensure_link "$WORKSPACE_DIR/source.md" "$HOME/target.md"
  [ "$status" -eq 0 ]
  [ ! -L "$HOME/target.md" ]
  [ "$(cat "$HOME/target.md")" = original ]
}

@test "ensure_link backs up a regular file and links when the user confirms" {
  touch "$WORKSPACE_DIR/source.md"
  echo original >"$HOME/target.md"
  WORKSPACE_CONFIRM=y ensure_link "$WORKSPACE_DIR/source.md" "$HOME/target.md"
  [ -L "$HOME/target.md" ]
  backups=("$HOME"/target.md.backup.*)
  [ "$(cat "${backups[0]}")" = original ]
}

@test "ensure_link changes nothing in dry run" {
  touch "$WORKSPACE_DIR/source.md"
  DRY_RUN=1 run ensure_link "$WORKSPACE_DIR/source.md" "$HOME/target.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"would link"* ]]
  [ ! -e "$HOME/target.md" ]
}
