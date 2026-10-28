# shellcheck shell=bash
CLAUDE_SETTINGS_SCHEMA="https://json.schemastore.org/claude-code-settings.json"

render_claude_permissions() {
  jq --arg home "$HOME" '
    def expand_home: if startswith("~/") then $home + .[1:] else . end;
    [.[] | select(.kind == "PermissionPolicy" and .spec.harness == "claude-code") | .spec] as $policies
    | ([$policies[] | .defaultMode // empty] | if length > 0 then {defaultMode: .[-1]} else {} end)
      + {
          allow: [$policies[] | (.allow // [])[]],
          ask: [$policies[] | (.ask // [])[]],
          deny: [$policies[] | (.deny // [])[]],
          additionalDirectories: [$policies[] | (.additionalDirectories // [])[] | expand_home]
        }' <<<"$MANIFEST_JSON"
}

managed_claude_settings() {
  jq -S -n --arg schema "$CLAUDE_SETTINGS_SCHEMA" --argjson permissions "$(render_claude_permissions)" \
    '{"$schema": $schema, permissions: $permissions}'
}

current_managed_claude_settings() {
  jq -S '{"$schema": ."$schema", permissions: .permissions}' "$1" 2>/dev/null
}

is_claude_settings_rendered() {
  local settings="$CLAUDE_DIR/settings.json"
  [ -f "$settings" ] && [ "$(current_managed_claude_settings "$settings")" = "$(managed_claude_settings)" ]
}

claude_settings_apply() {
  local destination="$CLAUDE_DIR/settings.json" current desired rendered
  desired="$(managed_claude_settings)"
  if [ -f "$destination" ]; then
    current="$(current_managed_claude_settings "$destination")" || die "$destination is not valid JSON"
    if [ "$current" = "$desired" ]; then
      ok "Claude settings up to date"
      return 0
    fi
    diff -u <(printf '%s\n' "$current") <(printf '%s\n' "$desired") || true
  elif [ "$DRY_RUN" = 1 ]; then
    log "would create $destination with the managed keys"
  fi
  if [ "$DRY_RUN" = 1 ]; then
    return 0
  fi
  if [ -f "$destination" ] && ! confirm "Update the managed keys (\$schema, permissions) in $destination?"; then
    warn "kept $destination"
    return 0
  fi
  rendered="$(mktemp)"
  if [ -f "$destination" ]; then
    copy_to_backup "$destination"
    jq --indent 2 --argjson managed "$desired" '. + $managed' "$destination" >"$rendered"
  else
    mkdir -p "$CLAUDE_DIR"
    jq --indent 2 -n --argjson managed "$desired" '$managed' >"$rendered"
  fi
  cat "$rendered" >"$destination"
  rm -f "$rendered"
  ok "Claude settings updated"
}

known_marketplace_names() {
  local file="$CLAUDE_DIR/plugins/known_marketplaces.json"
  if [ -f "$file" ]; then
    jq -r 'keys[]' "$file"
  fi
}

installed_plugin_ids() {
  local file="$CLAUDE_DIR/plugins/installed_plugins.json"
  if [ -f "$file" ]; then
    jq -r '(.plugins // {}) | keys[]' "$file"
  fi
}

declared_marketplaces() {
  query_manifests_raw '.[] | select(.kind == "PluginSet" and .spec.harness == "claude-code") | (.spec.marketplaces // [])[] | "\(.name) \(.source)"'
}

declared_plugin_ids() {
  query_manifests_raw '.[] | select(.kind == "PluginSet" and .spec.harness == "claude-code") | .spec.plugins[]'
}

require_claude() {
  command -v claude >/dev/null 2>&1 || die "claude is missing. Run: just apply toolset/ai"
}

claude_plugins_apply() {
  local known installed name source plugin_id
  known="$(known_marketplace_names)"
  installed="$(installed_plugin_ids)"
  while IFS=' ' read -r name source; do
    if [ -z "$name" ] || grep -qxF "$name" <<<"$known"; then
      continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      log "would add marketplace $name ($source)"
      continue
    fi
    require_claude
    claude plugin marketplace add "$source" --scope user </dev/null || die "marketplace add failed: $source"
    ok "marketplace $name added"
  done <<<"$(declared_marketplaces)"
  while IFS= read -r plugin_id; do
    if [ -z "$plugin_id" ] || grep -qxF "$plugin_id" <<<"$installed"; then
      continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      log "would install plugin $plugin_id"
      continue
    fi
    require_claude
    claude plugin install "$plugin_id" --scope user </dev/null || die "plugin install failed: $plugin_id"
    ok "plugin $plugin_id installed"
  done <<<"$(declared_plugin_ids)"
}

claude_apply() {
  claude_plugins_apply
  claude_settings_apply
}

claude_status() {
  local installed plugin_id
  installed="$(installed_plugin_ids)"
  printf 'claude-code\n'
  while IFS= read -r plugin_id; do
    if [ -z "$plugin_id" ]; then
      continue
    fi
    if grep -qxF "$plugin_id" <<<"$installed"; then
      printf '  ✔ plugin %s\n' "$plugin_id"
    else
      printf '  ✘ plugin %s\n' "$plugin_id"
    fi
  done <<<"$(declared_plugin_ids)"
  printf '  %s permission rules\n' "$(render_claude_permissions | jq '[.allow, .ask, .deny] | add | length')"
  if is_claude_settings_rendered; then
    printf '  ✔ %s matches the manifests\n' "$CLAUDE_DIR/settings.json"
  else
    printf '  ✘ %s drifted (run: just diff pluginset/claude-code)\n' "$CLAUDE_DIR/settings.json"
  fi
}
