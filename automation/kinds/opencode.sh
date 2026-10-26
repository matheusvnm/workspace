# shellcheck shell=bash
OPENCODE_DIR="${OPENCODE_DIR:-$HOME/.config/opencode}"

render_opencode_config() {
  jq --indent 2 '
    def plugin_entry: if .options then {package, options} else .package end;
    def expand_rule:
      .key as $action
      | .value as $rule
      | (if $rule.default then [{action: $action, resource: "*", effect: $rule.default}] else [] end)
        + [($rule.allow // [])[] | {action: $action, resource: ., effect: "allow"}]
        + [($rule.ask // [])[] | {action: $action, resource: ., effect: "ask"}]
        + [($rule.deny // [])[] | {action: $action, resource: ., effect: "deny"}];
    {
      "$schema": "https://opencode.ai/config.json",
      shell: "zsh",
      update: "disable",
      plugins: [.[] | select(.kind == "PluginSet" and .spec.harness == "opencode") | .spec.plugins[] | plugin_entry],
      permissions: [.[] | select(.kind == "PermissionPolicy" and .spec.harness == "opencode") | .spec.rules | to_entries[] | expand_rule[]]
    }' <<<"$MANIFEST_JSON"
}

opencode_major_version() {
  opencode --version 2>/dev/null | sed -E -n 's/^[^0-9]*([0-9]+)\..*/\1/p' | head -n 1
}

opencode_output() {
  local output_file exit_status
  output_file="$(mktemp)"
  opencode "$@" >"$output_file" 2>/dev/null
  exit_status=$?
  cat "$output_file"
  rm -f "$output_file"
  return "$exit_status"
}

restart_opencode_service() {
  local major
  command -v opencode >/dev/null 2>&1 || return 0
  major="$(opencode_major_version)"
  if [ -z "$major" ] || [ "$major" -lt 2 ]; then
    return 0
  fi
  if opencode service status >/dev/null 2>&1; then
    opencode service restart >/dev/null 2>&1 && ok "opencode service restarted"
  fi
  return 0
}

opencode_apply() {
  local destination="$OPENCODE_DIR/opencode.json" rendered had_v1_config=0
  rendered="$(mktemp)"
  render_opencode_config >"$rendered"
  if [ -f "$destination" ] && cmp -s "$rendered" "$destination"; then
    rm -f "$rendered"
    ok "opencode.json up to date"
    return 0
  fi
  if [ -e "$destination" ]; then
    diff -u "$destination" "$rendered" || true
    if [ "$DRY_RUN" = 1 ]; then
      rm -f "$rendered"
      return 0
    fi
    if ! confirm "Overwrite $destination with the rendered config?"; then
      rm -f "$rendered"
      warn "kept $destination"
      return 0
    fi
    if jq -e 'has("plugin")' "$destination" >/dev/null 2>&1; then
      had_v1_config=1
    fi
    move_to_backup "$destination"
  elif [ "$DRY_RUN" = 1 ]; then
    log "would write $destination:"
    cat "$rendered"
    rm -f "$rendered"
    return 0
  fi
  mkdir -p "$OPENCODE_DIR"
  chmod 644 "$rendered"
  mv "$rendered" "$destination"
  ok "rendered $destination"
  restart_opencode_service
  if [ "$had_v1_config" = 1 ]; then
    log "Next: open OpenCode and run /connect -> Anthropic -> Import Claude Code subscription."
  fi
}

opencode_status() {
  local destination="$OPENCODE_DIR/opencode.json" rendered
  rendered="$(mktemp)"
  render_opencode_config >"$rendered"
  printf 'opencode\n'
  jq -r '.plugins[] | if type == "string" then . else .package end | "  plugin " + .' "$rendered"
  printf '  %s permission rules\n' "$(jq '.permissions | length' "$rendered")"
  if [ -f "$destination" ] && cmp -s "$rendered" "$destination"; then
    printf '  ✔ %s matches the manifests\n' "$destination"
  else
    printf '  ✘ %s drifted (run: just diff pluginset/opencode)\n' "$destination"
  fi
  rm -f "$rendered"
}
