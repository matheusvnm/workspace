# shellcheck shell=bash

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

uninstall_entries() {
  jq -r '((.spec.uninstall.brew // [])[] | "brew \(.)"), ((.spec.uninstall.cask // [])[] | "cask \(.)")' <<<"$1"
}

toolset_uninstall() {
  local toolset="$1" type item
  while IFS=' ' read -r type item; do
    if [ -z "$item" ] || ! is_package_installed "$type" "$item"; then
      continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      log "would uninstall $type $item"
      continue
    fi
    if ! confirm "Uninstall $type $item?"; then
      warn "kept $type $item"
      continue
    fi
    if [ "$type" = cask ]; then
      brew uninstall --cask "$item" </dev/null
    else
      brew uninstall "$item" </dev/null
    fi
    ok "uninstalled $type $item"
  done <<<"$(uninstall_entries "$toolset")"
}

toolset_apply() {
  local toolset="$1" name
  name="$(toolset_name "$toolset")"
  toolset_uninstall "$toolset"
  if [ "$DRY_RUN" = 1 ]; then
    HOMEBREW_NO_AUTO_UPDATE=1 with_brewfile "$toolset" brew bundle check --no-upgrade --verbose || true
    return 0
  fi
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
  while IFS=' ' read -r type item; do
    if [ -z "$item" ]; then
      continue
    fi
    if is_package_installed "$type" "$item"; then
      printf '  ✘ absent %s %s\n' "$type" "$item"
    else
      printf '  ✔ absent %s %s\n' "$type" "$item"
    fi
  done <<<"$(uninstall_entries "$toolset")"
}
