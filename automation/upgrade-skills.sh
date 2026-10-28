#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$WORKSPACE_DIR/automation/lib/manifest.sh"
source "$WORKSPACE_DIR/automation/kinds/skillsource.sh"

load_manifests

while IFS= read -r source_json; do
  if [ -n "$source_json" ]; then
    skillsource_upgrade "$source_json"
  fi
done <<<"$(resources_of_kind SkillSource)"
