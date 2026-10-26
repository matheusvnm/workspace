#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation toolset
  TOOLSET_AI='{"kind":"ToolSet","metadata":{"name":"ai"},"spec":{"taps":["anomalyco/tap"],"brew":["anomalyco/tap/opencode-v2"],"cask":["codex"]}}'
  TOOLSET_CORE='{"kind":"ToolSet","metadata":{"name":"core"},"spec":{"brew":["git","jq"]}}'
}

stub_brew_with_opencode_v1() {
  stub_command brew '
echo "brew $*" >>"$STUB_LOG"
case "$*" in
  "list --formula --full-name") echo "git"; echo "anomalyco/tap/opencode" ;;
  "list --versions anomalyco/tap/opencode") echo "opencode 1.18.32" ;;
  "list --cask opencode-desktop") exit 1 ;;
esac
exit 0'
}

@test "render_brewfile writes taps, brews and casks in order and trusts tap items" {
  expected='tap "anomalyco/tap"
brew "anomalyco/tap/opencode-v2", trusted: true
cask "codex"'
  [ "$(render_brewfile "$TOOLSET_AI")" = "$expected" ]
}

@test "migration is skipped for a toolset without opencode-v2" {
  stub_brew_with_opencode_v1
  run migrate_opencode_if_needed "$TOOLSET_CORE"
  [ "$status" -eq 0 ]
  ! grep -q uninstall "$STUB_LOG"
}

@test "migration is skipped when OpenCode 1 is not installed" {
  stub_command brew 'echo "brew $*" >>"$STUB_LOG"; [ "$*" = "list --formula --full-name" ] && echo git; exit 0'
  run migrate_opencode_if_needed "$TOOLSET_AI"
  [ "$status" -eq 0 ]
  ! grep -q uninstall "$STUB_LOG"
}

@test "migration stops when the user declines the OpenCode 1 uninstall" {
  stub_brew_with_opencode_v1
  WORKSPACE_CONFIRM=n run migrate_opencode_if_needed "$TOOLSET_AI"
  [ "$status" -eq 1 ]
  [[ "$output" == *"OpenCode 1 is still installed"* ]]
  ! grep -q uninstall "$STUB_LOG"
}

@test "migration uninstalls OpenCode 1 when the user confirms" {
  stub_brew_with_opencode_v1
  WORKSPACE_CONFIRM=y run migrate_opencode_if_needed "$TOOLSET_AI"
  [ "$status" -eq 0 ]
  grep -qx "brew uninstall anomalyco/tap/opencode" "$STUB_LOG"
  grep -qx "brew update" "$STUB_LOG"
}

@test "apply in dry run checks the bundle and installs nothing" {
  log_stub_calls brew
  DRY_RUN=1 run toolset_apply "$TOOLSET_CORE"
  [ "$status" -eq 0 ]
  grep -q "brew bundle check" "$STUB_LOG"
  ! grep -q "brew bundle --no-upgrade" "$STUB_LOG"
}

@test "apply in dry run does not let brew auto-update" {
  stub_command brew 'echo "brew $* auto_update_off=${HOMEBREW_NO_AUTO_UPDATE:-}" >>"$STUB_LOG"'
  DRY_RUN=1 run toolset_apply "$TOOLSET_CORE"
  [ "$status" -eq 0 ]
  grep -q "brew bundle check .* auto_update_off=1" "$STUB_LOG"
}

@test "pick installs only the confirmed items that are missing" {
  stub_command brew '
echo "brew $*" >>"$STUB_LOG"
case "$*" in
  "list --formula git") exit 0 ;;
  "list --formula jq") exit 1 ;;
esac
exit 0'
  WORKSPACE_CONFIRM=y run toolset_pick "$TOOLSET_CORE"
  [ "$status" -eq 0 ]
  grep -qx "brew install jq" "$STUB_LOG"
  ! grep -qx "brew install git" "$STUB_LOG"
}
