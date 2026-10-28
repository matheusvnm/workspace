# shellcheck shell=bash
installer_field() { jq -r "$2" <<<"$1"; }

installer_apply() {
  local installer="$1" name bin script hint post_command
  name="$(installer_field "$installer" '.metadata.name')"
  bin="$(installer_field "$installer" '.spec.bin')"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "installer/$name present"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    log "would install installer/$name"
    return 0
  fi
  script="$(installer_field "$installer" '.spec.script')"
  bash "$WORKSPACE_DIR/$script" </dev/null || die "installer/$name failed"
  command -v "$bin" >/dev/null 2>&1 || die "installer/$name finished but $bin is not on PATH"
  while IFS= read -r post_command; do
    if [ -n "$post_command" ]; then
      bash -c "$post_command" </dev/null || die "installer/$name post step failed: $post_command"
    fi
  done <<<"$(installer_field "$installer" '(.spec.post // [])[]')"
  ok "installer/$name installed"
  hint="$(installer_field "$installer" '.spec.hint // empty')"
  if [ -n "$hint" ]; then
    log "Next: $hint"
  fi
}

installers_apply() {
  local group="$1" installer pending="" key
  while IFS= read -r installer; do
    if [ -z "$installer" ]; then
      continue
    fi
    if command -v "$(installer_field "$installer" '.spec.bin')" >/dev/null 2>&1; then
      ok "installer/$(installer_field "$installer" '.metadata.name') present"
    else
      pending="$pending installer/$(installer_field "$installer" '.metadata.name')"
    fi
  done
  # shellcheck disable=SC2086
  choose_items "$group" $pending
  for key in $SELECTED_ITEMS; do
    installer_apply "$(resource_by_ref "$key")"
  done
}

installer_status() {
  local installer="$1" name bin
  name="$(installer_field "$installer" '.metadata.name')"
  bin="$(installer_field "$installer" '.spec.bin')"
  if command -v "$bin" >/dev/null 2>&1; then
    printf '✔ installer/%s (%s)\n' "$name" "$(command -v "$bin")"
  elif is_skipped "installer/$name"; then
    printf -- '- installer/%s (skipped)\n' "$name"
  else
    printf '✘ installer/%s (%s missing)\n' "$name" "$bin"
  fi
}
