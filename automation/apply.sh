#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
for module in toolset installer skillsource claude conventions; do
  source "$WORKSPACE_DIR/automation/kinds/$module.sh"
done

is_pick=0
refs=""
for argument in "$@"; do
  case "$argument" in
    --pick) is_pick=1 ;;
    -*) die "unknown option: $argument" ;;
    *) refs="$refs $argument" ;;
  esac
done

apply_resource() {
  local resource="$1" kind
  kind="$(jq -r '.kind' <<<"$resource")"
  case "$kind" in
    ToolSet)
      if [ "$is_pick" = 1 ]; then
        toolset_pick "$resource"
      else
        toolset_apply "$resource"
      fi
      ;;
    Installer) installer_apply "$resource" ;;
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
  [ "$is_pick" = 0 ] || die "--pick needs a toolset ref, e.g. just apply --pick toolset/apps"
  apply_kind ToolSet
  apply_kind Installer
  apply_kind SkillSource
  claude_apply
  conventions_apply
  exit 0
fi

for ref in $refs; do
  resource="$(resource_by_ref "$ref")"
  apply_resource "$resource"
done
