# shellcheck shell=bash
OPENCODE_V2_FORMULA="anomalyco/tap/opencode-v2"

render_brewfile() {
  jq -r 'def trust_suffix: if contains("/") then ", trusted: true" else "" end;
         ((.spec.taps // [])[] | "tap \"\(.)\""),
         ((.spec.brew // [])[] | "brew \"\(.)\"\(trust_suffix)"),
         ((.spec.cask // [])[] | "cask \"\(.)\"\(trust_suffix)")' <<<"$1"
}

toolset_name() { jq -r '.metadata.name' <<<"$1"; }

with_brewfile() {
  local toolset="$1" brewfile exit_status=0
  shift
  brewfile="$(mktemp)"
  render_brewfile "$toolset" >"$brewfile"
  "$@" --file="$brewfile" </dev/null || exit_status=$?
  rm -f "$brewfile"
  return "$exit_status"
}

is_package_installed() {
  local type="$1" item="$2"
  if [ "$type" = cask ]; then
    brew list --cask "$item" >/dev/null 2>&1 </dev/null
  else
    brew list --formula "${item##*/}" >/dev/null 2>&1 </dev/null
  fi
}

installed_opencode_v1() {
  local formula version
  formula="$(brew list --formula --full-name 2>/dev/null </dev/null | grep -E '(^|/)opencode$' | head -n 1 || true)"
  [ -n "$formula" ] || return 1
  version="$(brew list --versions "$formula" 2>/dev/null </dev/null | awk '{print $2}')"
  case "$version" in
    1.*) printf '%s\n' "$formula" ;;
    *) return 1 ;;
  esac
}

migrate_opencode_if_needed() {
  local toolset="$1" formula
  if ! jq -e --arg formula "$OPENCODE_V2_FORMULA" '(.spec.brew // []) | index($formula)' <<<"$toolset" >/dev/null; then
    return 0
  fi
  formula="$(installed_opencode_v1)" || return 0
  if [ "$DRY_RUN" = 1 ]; then
    log "would uninstall $formula (OpenCode 1) before installing $OPENCODE_V2_FORMULA"
    return 0
  fi
  if ! confirm "Uninstall $formula (OpenCode 1)? $OPENCODE_V2_FORMULA requires it."; then
    die "OpenCode 1 is still installed. Uninstall it, or remove $OPENCODE_V2_FORMULA from the manifest."
  fi
  brew uninstall "$formula" </dev/null
  brew update </dev/null
  if brew list --cask opencode-desktop >/dev/null 2>&1 </dev/null; then
    brew upgrade --cask opencode-desktop </dev/null || warn "opencode-desktop upgrade failed"
  fi
  ok "OpenCode 1 removed"
}

toolset_apply() {
  local toolset="$1" name
  name="$(toolset_name "$toolset")"
  if [ "$DRY_RUN" = 1 ]; then
    migrate_opencode_if_needed "$toolset"
    with_brewfile "$toolset" brew bundle check --no-upgrade --verbose || true
    return 0
  fi
  migrate_opencode_if_needed "$toolset"
  with_brewfile "$toolset" brew bundle --no-upgrade || die "toolset/$name failed"
  ok "toolset/$name applied"
}

toolset_pick() {
  local toolset="$1" tap type item
  while IFS= read -r tap; do
    if [ -n "$tap" ]; then
      brew tap "$tap" </dev/null
    fi
  done <<<"$(jq -r '(.spec.taps // [])[]' <<<"$toolset")"
  while IFS=' ' read -r type item; do
    if [ -z "$item" ] || is_package_installed "$type" "$item"; then
      continue
    fi
    if ! confirm "Install $type $item?"; then
      continue
    fi
    if [ "$type" = cask ]; then
      brew install --cask "$item" </dev/null
    else
      if [ "$item" = "$OPENCODE_V2_FORMULA" ]; then
        migrate_opencode_if_needed "$toolset"
      fi
      brew install "$item" </dev/null
    fi
  done <<<"$(jq -r '((.spec.brew // [])[] | "brew \(.)"), ((.spec.cask // [])[] | "cask \(.)")' <<<"$toolset")"
}

toolset_status() {
  local toolset="$1" type item
  printf 'toolset/%s\n' "$(toolset_name "$toolset")"
  while IFS=' ' read -r type item; do
    if [ -z "$item" ]; then
      continue
    fi
    if is_package_installed "$type" "$item"; then
      printf '  ✔ %s %s\n' "$type" "$item"
    else
      printf '  ✘ %s %s\n' "$type" "$item"
    fi
  done <<<"$(jq -r '((.spec.brew // [])[] | "brew \(.)"), ((.spec.cask // [])[] | "cask \(.)")' <<<"$toolset")"
}
