# shellcheck shell=bash
ZSH_BLOCK_START="# >>> workspace-bootstrap >>>"
ZSH_BLOCK_END="# <<< workspace-bootstrap <<<"

render_zsh_block() {
  cat <<EOF
$ZSH_BLOCK_START
# Managed by $WORKSPACE_DIR (just apply). Do not edit this block.
case ":\$PATH:" in *":\$HOME/.local/bin:"*) ;; *) export PATH="\$HOME/.local/bin:\$PATH" ;; esac
command -v starship >/dev/null 2>&1 && eval "\$(starship init zsh)"
[ -f "$WORKSPACE_DIR/config/.aliases" ] && source "$WORKSPACE_DIR/config/.aliases"
[ -f "$WORKSPACE_DIR/config/.functions" ] && source "$WORKSPACE_DIR/config/.functions"
$ZSH_BLOCK_END
EOF
}

apply_zsh_block() {
  local zshrc="$HOME/.zshrc" current="$HOME/.zshrc" candidate
  if [ ! -e "$zshrc" ]; then
    current=/dev/null
  fi
  candidate="$(mktemp)"
  if grep -qxF "$ZSH_BLOCK_START" "$current"; then
    ZSH_BLOCK="$(render_zsh_block)" awk -v start="$ZSH_BLOCK_START" -v end="$ZSH_BLOCK_END" '
      $0 == start { print ENVIRON["ZSH_BLOCK"]; skipping = 1; next }
      $0 == end { skipping = 0; next }
      !skipping { print }
    ' "$current" >"$candidate"
  else
    {
      cat "$current"
      printf '\n'
      render_zsh_block
    } >"$candidate"
  fi
  if cmp -s "$candidate" "$current"; then
    rm -f "$candidate"
    ok "zshrc block up to date"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    diff -u "$current" "$candidate" || true
    rm -f "$candidate"
    return 0
  fi
  if [ -e "$zshrc" ]; then
    copy_to_backup "$zshrc"
  fi
  cat "$candidate" >"$zshrc"
  rm -f "$candidate"
  ok "zshrc block updated"
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    log "would install oh-my-zsh"
    return 0
  fi
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "oh-my-zsh installed"
}

link_markdown_files() {
  local source_dir="$1" destination_dir="$2" file
  for file in "$source_dir"/*.md; do
    if [ -f "$file" ]; then
      ensure_link "$file" "$destination_dir/$(basename "$file")"
    fi
  done
}

conventions_apply() {
  ensure_link "$WORKSPACE_DIR/llms/AGENTS.md" "$OPENCODE_DIR/AGENTS.md"
  link_markdown_files "$WORKSPACE_DIR/llms/commands" "$OPENCODE_DIR/commands"
  link_markdown_files "$WORKSPACE_DIR/llms/agents" "$OPENCODE_DIR/agents"
  ensure_link "$WORKSPACE_DIR/config/starship.toml" "$HOME/.config/starship.toml"
  install_oh_my_zsh
  apply_zsh_block
}
