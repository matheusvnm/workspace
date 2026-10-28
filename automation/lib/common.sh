# shellcheck shell=bash
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKIPPED_FILE="${SKIPPED_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/workspace/skipped}"
IS_SELECT="${IS_SELECT:-0}"
IS_RESELECT="${IS_RESELECT:-0}"
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

is_skipped() { [ -f "$SKIPPED_FILE" ] && grep -qxF "$1" "$SKIPPED_FILE"; }

remember_skipped() {
  if is_skipped "$1"; then
    return 0
  fi
  mkdir -p "$(dirname "$SKIPPED_FILE")"
  printf '%s\n' "$1" >>"$SKIPPED_FILE"
}

forget_skipped() {
  local remaining
  if ! is_skipped "$1"; then
    return 0
  fi
  remaining="$(mktemp)"
  grep -vxF "$1" "$SKIPPED_FILE" >"$remaining" || true
  mv "$remaining" "$SKIPPED_FILE"
}

read_group_choice() {
  local prompt="$1" reply
  if [ -n "${WORKSPACE_GROUP_CHOICE:-}" ]; then
    GROUP_CHOICE="$WORKSPACE_GROUP_CHOICE"
    return 0
  fi
  { : </dev/tty; } 2>/dev/null || die "the selection needs a terminal. Run: just setup-ci"
  while true; do
    printf '%s [a]ll, [o]ne by one, [N]one: ' "$prompt" >/dev/tty
    IFS= read -r reply </dev/tty || reply=n
    case "$reply" in
      a | A | all) GROUP_CHOICE=all ;;
      o | O | one) GROUP_CHOICE=one ;;
      "" | n | N | none) GROUP_CHOICE=none ;;
      *) continue ;;
    esac
    return 0
  done
}

choose_items() {
  local group="$1" key pending=""
  shift
  SELECTED_ITEMS=""
  if [ "$IS_SELECT" = 0 ] || [ "$DRY_RUN" = 1 ]; then
    SELECTED_ITEMS="$*"
    return 0
  fi
  if [ "$#" -eq 0 ]; then
    return 0
  fi
  log "$group:"
  for key in "$@"; do
    if [ "$IS_RESELECT" = 0 ] && is_skipped "$key"; then
      log "  - $key (skipped before)"
    else
      log "  + $key"
      pending="$pending $key"
    fi
  done
  if [ -z "$pending" ]; then
    return 0
  fi
  read_group_choice "Install from $group?"
  for key in $pending; do
    if [ "$GROUP_CHOICE" = all ] || { [ "$GROUP_CHOICE" = one ] && confirm "Install $key?"; }; then
      SELECTED_ITEMS="$SELECTED_ITEMS $key"
      forget_skipped "$key"
    else
      remember_skipped "$key"
    fi
  done
}

is_link_to() { [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; }

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
  if is_link_to "$source" "$destination"; then
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
