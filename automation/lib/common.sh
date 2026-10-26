# shellcheck shell=bash
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '%s\n' "$*"; }
ok() { printf '✔ %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
fail() { printf '✘ %s\n' "$*" >&2; }
die() {
  fail "$*"
  exit 1
}

timestamp() { date +%Y%m%d%H%M%S; }

confirm() {
  local prompt="$1" reply
  case "${WORKSPACE_CONFIRM:-}" in
    y) return 0 ;;
    n) return 1 ;;
  esac
  { : </dev/tty; } 2>/dev/null || return 1
  printf '%s [y/N] ' "$prompt" >/dev/tty
  IFS= read -r reply </dev/tty || return 1
  case "$reply" in
    y | Y | yes | YES) return 0 ;;
    *) return 1 ;;
  esac
}

move_to_backup() {
  local path="$1" backup
  backup="$path.backup.$(timestamp)"
  mv "$path" "$backup"
  log "backup: $backup"
}

copy_to_backup() {
  local path="$1" backup
  backup="$path.backup.$(timestamp)"
  cp -p "$path" "$backup"
  log "backup: $backup"
}

ensure_link() {
  local source="$1" destination="$2"
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    log "would link $destination -> $source"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  if [ -L "$destination" ]; then
    rm "$destination"
  elif [ -e "$destination" ]; then
    if ! confirm "Replace $destination with a link to $source?"; then
      warn "kept $destination"
      return 0
    fi
    move_to_backup "$destination"
  fi
  ln -s "$source" "$destination"
  ok "linked $destination -> $source"
}
