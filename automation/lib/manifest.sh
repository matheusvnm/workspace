# shellcheck shell=bash
MANIFEST_DIR="${MANIFEST_DIR:-$WORKSPACE_DIR/manifests}"

manifest_files() {
  find "$MANIFEST_DIR" -type f -name '*.yaml' -print0 | sort -z
}

load_manifests() {
  if [ ! -d "$MANIFEST_DIR" ] || [ -z "$(find "$MANIFEST_DIR" -type f -name '*.yaml' -print -quit)" ]; then
    die "no manifests in $MANIFEST_DIR"
  fi
  MANIFEST_JSON="$(manifest_files | xargs -0 yq e -o=json -I=0 '.' | jq -s -c 'map(select(. != null))')"
  export MANIFEST_JSON
}

query_manifests() { jq -c "$@" <<<"$MANIFEST_JSON"; }
query_manifests_raw() { jq -r "$@" <<<"$MANIFEST_JSON"; }

resources_of_kind() {
  query_manifests --arg kind "$1" '.[] | select(.kind == $kind)'
}

resource_by_ref() {
  local ref="$1" kind name resource
  kind="${ref%%/*}"
  name="${ref#*/}"
  if [ "$kind" = "$ref" ] || [ -z "$name" ]; then
    die "invalid ref: $ref (use kind/name, e.g. toolset/core)"
  fi
  resource="$(query_manifests --arg kind "$kind" --arg name "$name" \
    '.[] | select((.kind | ascii_downcase) == ($kind | ascii_downcase) and .metadata.name == $name)')"
  [ -n "$resource" ] || die "resource not found: $ref"
  printf '%s\n' "$resource"
}

owned_names() {
  query_manifests_raw --arg type "$1" '.[] | select(.kind == "Installer") | (.spec.owns[$type] // [])[]'
}

package_name() {
  local spec="$1" scope="" rest
  case "$spec" in
    @*)
      scope="@"
      rest="${spec#@}"
      ;;
    *) rest="$spec" ;;
  esac
  case "$rest" in
    *@*) rest="${rest%@*}" ;;
  esac
  printf '%s%s\n' "$scope" "$rest"
}

local_skill_names() {
  local source_json="$1" source dir name
  source="$(jq -r '.spec.source' <<<"$source_json")"
  for dir in "$WORKSPACE_DIR/${source#./}"/*/; do
    if [ ! -f "${dir}SKILL.md" ]; then
      continue
    fi
    name="$(basename "$dir")"
    if jq -e --arg name "$name" '.spec.skills | (index("*") or index($name))' <<<"$source_json" >/dev/null; then
      printf '%s\n' "$name"
    fi
  done
}

skill_names_of_source() {
  case "$(jq -r '.spec.source' <<<"$1")" in
    ./*) local_skill_names "$1" ;;
    *) jq -r '.spec.skills[]' <<<"$1" ;;
  esac
}

declared_skill_names() {
  local source_json
  while IFS= read -r source_json; do
    if [ -n "$source_json" ]; then
      skill_names_of_source "$source_json"
    fi
  done <<<"$(resources_of_kind SkillSource)"
}

markdown_names() {
  local file
  for file in "$1"/*.md; do
    if [ -f "$file" ]; then
      basename "$file"
    fi
  done
}

skill_frontmatter_name() {
  sed -n 's/^name:[[:space:]]*//p' "$1/SKILL.md" | head -n 1 | tr -d "\"'"
}
