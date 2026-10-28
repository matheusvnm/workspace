# shellcheck shell=bash
SKILLS_DIR="${SKILLS_DIR:-$CLAUDE_DIR/skills}"

require_node() {
  command -v node >/dev/null 2>&1 || die "node is missing. Run: just apply toolset/core"
  node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 20) ? 0 : 1)' \
    || die "Node 22.20 or later is required by the skills CLI"
}

check_skill_name() {
  local skill_dir="$1" expected actual
  expected="$(basename "$skill_dir")"
  actual="$(skill_frontmatter_name "$skill_dir")"
  [ "$actual" = "$expected" ] || die "skill $skill_dir: name '$actual' does not match folder '$expected'"
}

apply_local_skills() {
  local source_json="$1" source name
  source="$(jq -r '.spec.source' <<<"$source_json")"
  while IFS= read -r name; do
    if [ -z "$name" ]; then
      continue
    fi
    check_skill_name "$WORKSPACE_DIR/${source#./}/$name"
    ensure_link "$WORKSPACE_DIR/${source#./}/$name" "$SKILLS_DIR/$name"
  done <<<"$(local_skill_names "$source_json")"
}

apply_remote_skills() {
  local source_json="$1" source name missing=""
  source="$(jq -r '.spec.source' <<<"$source_json")"
  while IFS= read -r name; do
    if [ -n "$name" ] && [ ! -f "$SKILLS_DIR/$name/SKILL.md" ]; then
      missing="$missing $name"
    fi
  done <<<"$(jq -r '.spec.skills[]' <<<"$source_json")"
  if [ -z "$missing" ]; then
    ok "skills from $source present"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    log "would add from $source:$missing"
    return 0
  fi
  require_node
  set --
  for name in $missing; do
    set -- "$@" --skill "$name"
  done
  DISABLE_TELEMETRY=1 npx -y skills add "$source" -g -a claude-code --copy -y "$@" </dev/null || die "skills add failed for $source"
  for name in $missing; do
    [ -f "$SKILLS_DIR/$name/SKILL.md" ] || die "skill $name was not installed from $source"
  done
  ok "skills from $source installed:$missing"
}

skillsource_apply() {
  case "$(jq -r '.spec.source' <<<"$1")" in
    ./*) apply_local_skills "$1" ;;
    *) apply_remote_skills "$1" ;;
  esac
}

skillsource_status() {
  local source_json="$1" name
  printf 'skillsource/%s (%s)\n' "$(jq -r '.metadata.name' <<<"$source_json")" "$(jq -r '.spec.source' <<<"$source_json")"
  while IFS= read -r name; do
    if [ -z "$name" ]; then
      continue
    fi
    if [ -f "$SKILLS_DIR/$name/SKILL.md" ]; then
      printf '  ✔ %s\n' "$name"
    else
      printf '  ✘ %s\n' "$name"
    fi
  done <<<"$(skill_names_of_source "$source_json")"
}
