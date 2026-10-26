# shellcheck shell=bash
REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup_workspace() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export WORKSPACE_DIR="$BATS_TEST_TMPDIR/workspace"
  export MANIFEST_DIR="$WORKSPACE_DIR/manifests"
  export STUB_BIN="$BATS_TEST_TMPDIR/bin"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  export WORKSPACE_CONFIRM=n
  unset DRY_RUN SKILLS_DIR OPENCODE_DIR OPENCODE_CACHE_DIR MANIFEST_JSON
  mkdir -p "$HOME" "$MANIFEST_DIR" "$STUB_BIN" \
    "$WORKSPACE_DIR/llms/skills" "$WORKSPACE_DIR/llms/commands" "$WORKSPACE_DIR/llms/agents" "$WORKSPACE_DIR/config"
  : >"$STUB_LOG"
  ln -s "$REPO_ROOT/automation" "$WORKSPACE_DIR/automation"
  ln -s "$REPO_ROOT/schemas" "$WORKSPACE_DIR/schemas"
  export PATH="$STUB_BIN:$PATH"
}

write_manifest() {
  mkdir -p "$(dirname "$MANIFEST_DIR/$1")"
  cat >"$MANIFEST_DIR/$1"
}

stub_command() {
  printf '#!/usr/bin/env bash\n%s\n' "$2" >"$STUB_BIN/$1"
  chmod +x "$STUB_BIN/$1"
}

log_stub_calls() {
  stub_command "$1" "echo \"$1 \$*\" >>\"\$STUB_LOG\""
}

create_skill() {
  mkdir -p "$1"
  printf -- '---\nname: %s\ndescription: test skill\n---\n' "${2:-$(basename "$1")}" >"$1/SKILL.md"
}

load_automation() {
  # shellcheck source=/dev/null
  source "$REPO_ROOT/automation/lib/common.sh"
  # shellcheck source=/dev/null
  source "$REPO_ROOT/automation/lib/manifest.sh"
  local module
  for module in "$@"; do
    # shellcheck source=/dev/null
    source "$REPO_ROOT/automation/kinds/$module.sh"
  done
}
