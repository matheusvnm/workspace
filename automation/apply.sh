#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
for module in toolset installer skillsource claude conventions; do
  source "$WORKSPACE_DIR/automation/kinds/$module.sh"
done

refs=""
for argument in "$@"; do
  case "$argument" in
    --select) export IS_SELECT=1 ;;
    --reselect) export IS_SELECT=1 IS_RESELECT=1 ;;
    -*) die "unknown option: $argument" ;;
    *) refs="$refs $argument" ;;
  esac
done

apply_resource() {
  local resource="$1" kind
  kind="$(jq -r '.kind' <<<"$resource")"
  case "$kind" in
    ToolSet) toolset_apply "$resource" ;;
    Installer) installers_apply "installer/$(jq -r '.metadata.name' <<<"$resource")" <<<"$resource" ;;
    SkillSource) skillsource_apply "$resource" ;;
    PluginSet | PermissionPolicy) claude_apply ;;
    *) die "unsupported kind: $kind" ;;
  esac
}

apply_kind() {
  local resource
  while IFS= read -r resource; do
    if [ -n "$resource" ]; then
      apply_resource "$resource"
    fi
  done <<<"$(resources_of_kind "$1")"
}

load_manifests

if [ -z "$refs" ]; then
  apply_kind ToolSet
  installers_apply installers <<<"$(resources_of_kind Installer)"
  apply_kind SkillSource
  claude_apply
  conventions_apply
  exit 0
fi

for ref in $refs; do
  resource="$(resource_by_ref "$ref")"
  apply_resource "$resource"
done
