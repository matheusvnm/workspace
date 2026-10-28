#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
for module in toolset installer skillsource claude; do
  source "$WORKSPACE_DIR/automation/kinds/$module.sh"
done

[ "$#" -eq 1 ] || die "usage: just get <toolset|installer|skillsource|claude>"

load_manifests

case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
  toolset | toolsets) kind=ToolSet status_function=toolset_status ;;
  installer | installers) kind=Installer status_function=installer_status ;;
  skillsource | skillsources | skills) kind=SkillSource status_function=skillsource_status ;;
  pluginset | permissionpolicy | claude | claude-code)
    claude_status
    exit 0
    ;;
  *) die "unknown kind: $1" ;;
esac

while IFS= read -r resource; do
  if [ -n "$resource" ]; then
    "$status_function" "$resource"
  fi
done <<<"$(resources_of_kind "$kind")"
