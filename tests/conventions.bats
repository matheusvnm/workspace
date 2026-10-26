#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation opencode conventions
}

@test "zsh block is appended when it is missing" {
  printf 'export EDITOR=vim\n' >"$HOME/.zshrc"
  apply_zsh_block
  run cat "$HOME/.zshrc"
  [[ "$output" == "export EDITOR=vim"* ]]
  [[ "$output" == *"# >>> workspace-bootstrap >>>"* ]]
  [[ "$output" == *".local/bin"* ]]
  [[ "$output" == *"$WORKSPACE_DIR/config/.aliases"* ]]
}

@test "zsh block replaces an old block and keeps the other lines" {
  printf 'before\n# >>> workspace-bootstrap >>>\nold line\n# <<< workspace-bootstrap <<<\nafter\n' >"$HOME/.zshrc"
  apply_zsh_block
  run cat "$HOME/.zshrc"
  [[ "$output" != *"old line"* ]]
  [ "$(head -n 1 "$HOME/.zshrc")" = before ]
  [ "$(tail -n 1 "$HOME/.zshrc")" = after ]
  [ "$(grep -c '# >>> workspace-bootstrap >>>' "$HOME/.zshrc")" -eq 1 ]
}

@test "zsh block is a no-op on the second run" {
  printf 'before\n' >"$HOME/.zshrc"
  apply_zsh_block
  run apply_zsh_block
  [[ "$output" == *"zshrc block up to date"* ]]
  [ "$(ls -a "$HOME" | grep -c 'zshrc.backup' || true)" -eq 1 ]
}

@test "zsh block in dry run writes nothing" {
  printf 'before\n' >"$HOME/.zshrc"
  DRY_RUN=1 run apply_zsh_block
  [ "$(cat "$HOME/.zshrc")" = before ]
}

@test "zsh block in dry run does not create a missing zshrc" {
  DRY_RUN=1 run apply_zsh_block
  [ "$status" -eq 0 ]
  [[ "$output" == *"# >>> workspace-bootstrap >>>"* ]]
  [ ! -e "$HOME/.zshrc" ]
}

@test "zsh block creates a missing zshrc" {
  apply_zsh_block
  grep -qxF "# >>> workspace-bootstrap >>>" "$HOME/.zshrc"
}

@test "link_markdown_files links every markdown file" {
  touch "$WORKSPACE_DIR/llms/commands/run.md" "$WORKSPACE_DIR/llms/commands/bruh.md" "$WORKSPACE_DIR/llms/commands/notes.txt"
  link_markdown_files "$WORKSPACE_DIR/llms/commands" "$HOME/.config/opencode/commands"
  [ "$(readlink "$HOME/.config/opencode/commands/run.md")" = "$WORKSPACE_DIR/llms/commands/run.md" ]
  [ "$(readlink "$HOME/.config/opencode/commands/bruh.md")" = "$WORKSPACE_DIR/llms/commands/bruh.md" ]
  [ ! -e "$HOME/.config/opencode/commands/notes.txt" ]
}

@test "conventions_apply links rules, commands and starship" {
  touch "$WORKSPACE_DIR/llms/AGENTS.md" "$WORKSPACE_DIR/llms/commands/run.md" "$WORKSPACE_DIR/config/starship.toml"
  mkdir -p "$HOME/.oh-my-zsh"
  conventions_apply
  [ "$(readlink "$HOME/.config/opencode/AGENTS.md")" = "$WORKSPACE_DIR/llms/AGENTS.md" ]
  [ "$(readlink "$HOME/.config/opencode/commands/run.md")" = "$WORKSPACE_DIR/llms/commands/run.md" ]
  [ "$(readlink "$HOME/.config/starship.toml")" = "$WORKSPACE_DIR/config/starship.toml" ]
}
