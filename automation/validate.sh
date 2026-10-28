#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"

schema="$WORKSPACE_DIR/schemas/workspace.v1.json"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

document_count=0
while IFS= read -r -d '' file; do
  relative="${file#"$MANIFEST_DIR"/}"
  flat_name="$(printf '%s' "$relative" | tr '/' '_')"
  index=0
  while IFS= read -r document; do
    if [ -z "$document" ] || [ "$document" = null ]; then
      continue
    fi
    printf '%s\n' "$document" >"$workdir/$flat_name.$index.json"
    index=$((index + 1))
    document_count=$((document_count + 1))
  done <<<"$(yq e -o=json -I=0 '.' "$file")"
done < <(manifest_files)

[ "$document_count" -gt 0 ] || die "no manifest documents in $MANIFEST_DIR"

uvx check-jsonschema --schemafile "$schema" "$workdir"/*.json

load_manifests

duplicates="$(query_manifests_raw 'group_by([.kind, .metadata.name]) | map(select(length > 1) | "\(.[0].kind)/\(.[0].metadata.name)") | join(", ")')"
[ -z "$duplicates" ] || die "duplicate resources: $duplicates"

remote_wildcards="$(query_manifests_raw '[.[] | select(.kind == "SkillSource" and (.spec.source | startswith("./") | not) and (.spec.skills | index("*"))) | .metadata.name] | join(", ")')"
[ -z "$remote_wildcards" ] || die "remote SkillSource cannot use \"*\": $remote_wildcards"

undeclared_marketplaces="$(query_manifests_raw '
  [.[] | select(.kind == "PluginSet")] as $plugin_sets
  | ([$plugin_sets[] | (.spec.marketplaces // [])[] | .name] + ["claude-plugins-official"]) as $known_marketplaces
  | [$plugin_sets[] | .spec.plugins[] | split("@")[1] | select(. as $marketplace | $known_marketplaces | index($marketplace) | not)]
  | unique | join(", ")')"
[ -z "$undeclared_marketplaces" ] || die "plugins use undeclared marketplaces: $undeclared_marketplaces"

ok "manifests valid ($document_count documents)"
