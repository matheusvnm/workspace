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

toolset_entries() {
  jq -r '((.spec.brew // [])[] | "brew \(.)"), ((.spec.cask // [])[] | "cask \(.)")' <<<"$1"
}

cask_artifact_names() {
  brew info --json=v2 --cask "$1" 2>/dev/null </dev/null \
    | jq -r '.casks[0].artifacts[]? | (.app // .binary // empty) | ((.[1] | objects | .target) // .[0]) | split("/") | last'
}

cask_location() {
  local artifact directory
  while IFS= read -r artifact; do
    case "$artifact" in
      "") ;;
      *.app)
        for directory in "${APPLICATIONS_DIR:-/Applications}" "$HOME/Applications"; do
          if [ -e "$directory/$artifact" ]; then
            printf '%s\n' "$directory/$artifact"
            return 0
          fi
        done
        ;;
      *) type -P "$artifact" && return 0 ;;
    esac
  done <<<"$(cask_artifact_names "$1")"
  return 1
}

unmanaged_location() {
  local toolset="$1" type="$2" item="$3" bin
  bin="$(jq -r --arg item "$item" '.spec.bins[$item] // empty' <<<"$toolset")"
  if [ -n "$bin" ]; then
    type -P "$bin"
  elif [ "$type" = cask ]; then
    cask_location "$item"
  else
    type -P "${item##*/}"
  fi
}

toolset_missing_keys() {
  local toolset="$1" type item location
  while IFS=' ' read -r type item; do
    if [ -z "$item" ] || is_package_installed "$type" "$item"; then
      continue
    fi
    if location="$(unmanaged_location "$toolset" "$type" "$item")"; then
      warn "$type $item is present at $location and brew does not manage it. Skipped."
      continue
    fi
    printf '%s/%s\n' "$type" "$item"
  done <<<"$(toolset_entries "$toolset")"
}

toolset_with_keys() {
  jq -c --arg keys "$2" '($keys | split(" ")) as $keys
    | .spec.brew = [(.spec.brew // [])[] | select(("brew/" + .) | IN($keys[]))]
    | .spec.cask = [(.spec.cask // [])[] | select(("cask/" + .) | IN($keys[]))]' <<<"$1"
}

toolset_apply() {
  local toolset="$1" name missing key
  name="$(toolset_name "$toolset")"
  toolset_uninstall "$toolset"
  missing="$(toolset_missing_keys "$toolset")"
  # shellcheck disable=SC2086
  choose_items "toolset/$name" $missing
  if [ -z "$SELECTED_ITEMS" ]; then
    ok "toolset/$name has nothing to install"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    for key in $SELECTED_ITEMS; do
      log "would install ${key%%/*} ${key#*/}"
    done
    return 0
  fi
  with_brewfile "$(toolset_with_keys "$toolset" "$SELECTED_ITEMS")" brew bundle --no-upgrade || die "toolset/$name failed"
  ok "toolset/$name applied"
}

toolset_status() {
  local toolset="$1" type item location
  printf 'toolset/%s\n' "$(toolset_name "$toolset")"
  while IFS=' ' read -r type item; do
    if [ -z "$item" ]; then
      continue
    fi
    if is_package_installed "$type" "$item"; then
      printf '  ✔ %s %s\n' "$type" "$item"
    elif location="$(unmanaged_location "$toolset" "$type" "$item")"; then
      printf '  ! %s %s (not managed by brew: %s)\n' "$type" "$item" "$location"
    elif is_skipped "$type/$item"; then
      printf '  - %s %s (skipped)\n' "$type" "$item"
    else
      printf '  ✘ %s %s\n' "$type" "$item"
    fi
  done <<<"$(toolset_entries "$toolset")"
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
