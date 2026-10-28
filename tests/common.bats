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

skipped_keys() { cat "$HOME/.config/workspace/skipped" 2>/dev/null; }

@test "choose_items selects every item when the selection is off" {
  choose_items toolset/core brew/a brew/b
  [ "$SELECTED_ITEMS" = "brew/a brew/b" ]
  [ -z "$(skipped_keys)" ]
}

@test "choose_items selects every item when the user approves the group" {
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=all choose_items toolset/core brew/a brew/b
  [ "$SELECTED_ITEMS" = " brew/a brew/b" ]
  [ -z "$(skipped_keys)" ]
}

@test "choose_items remembers every item when the user declines the group" {
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none choose_items toolset/core brew/a brew/b
  [ -z "$SELECTED_ITEMS" ]
  [ "$(skipped_keys)" = "brew/a
brew/b" ]
}

@test "choose_items asks about each item one by one" {
  confirm() { [ "$1" = "Install brew/b?" ]; }
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=one choose_items toolset/core brew/a brew/b
  [ "$SELECTED_ITEMS" = " brew/b" ]
  [ "$(skipped_keys)" = "brew/a" ]
}

@test "choose_items does not ask again about an item that the user skipped before" {
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none choose_items toolset/core brew/a
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=all run choose_items toolset/core brew/a brew/b
  [[ "$output" == *"- brew/a (skipped before)"* ]]
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=all choose_items toolset/core brew/a brew/b
  [ "$SELECTED_ITEMS" = " brew/b" ]
}

@test "choose_items with reselect asks again and forgets the selected items" {
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none choose_items toolset/core brew/a
  IS_SELECT=1 IS_RESELECT=1 WORKSPACE_GROUP_CHOICE=all choose_items toolset/core brew/a
  [ "$SELECTED_ITEMS" = " brew/a" ]
  [ -z "$(skipped_keys)" ]
}

@test "choose_items in dry run selects every item and remembers nothing" {
  DRY_RUN=1 IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none choose_items toolset/core brew/a
  [ "$SELECTED_ITEMS" = "brew/a" ]
  [ ! -e "$HOME/.config/workspace/skipped" ]
}
