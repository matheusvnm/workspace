#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation toolset
  TOOLSET_TAPPED='{"kind":"ToolSet","metadata":{"name":"ai"},"spec":{"taps":["anomalyco/tap"],"brew":["anomalyco/tap/opencode-v2"],"cask":["codex"]}}'
  TOOLSET_AI='{"kind":"ToolSet","metadata":{"name":"ai"},"spec":{"cask":["claude"],"uninstall":{"brew":["anomalyco/tap/opencode-v2"],"cask":["codex"]}}}'
  TOOLSET_CORE='{"kind":"ToolSet","metadata":{"name":"core"},"spec":{"brew":["git","jq"]}}'
}

@test "render_brewfile writes taps, brews and casks in order and trusts tap items" {
  expected='tap "anomalyco/tap"
brew "anomalyco/tap/opencode-v2", trusted: true
cask "codex"'
  [ "$(render_brewfile "$TOOLSET_TAPPED")" = "$expected" ]
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

stub_brew_with_opencode_installed() {
  stub_command brew '
echo "brew $*" >>"$STUB_LOG"
case "$*" in
  "list --formula opencode-v2") exit 0 ;;
  "list --cask codex") exit 1 ;;
esac
exit 0'
}

@test "uninstall removes an installed package when the user confirms" {
  stub_brew_with_opencode_installed
  WORKSPACE_CONFIRM=y run toolset_uninstall "$TOOLSET_AI"
  [ "$status" -eq 0 ]
  grep -qx "brew uninstall anomalyco/tap/opencode-v2" "$STUB_LOG"
  ! grep -q "brew uninstall --cask codex" "$STUB_LOG"
}

@test "uninstall keeps a package when the user declines" {
  stub_brew_with_opencode_installed
  WORKSPACE_CONFIRM=n run toolset_uninstall "$TOOLSET_AI"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kept brew anomalyco/tap/opencode-v2"* ]]
  ! grep -q "brew uninstall" "$STUB_LOG"
}

@test "uninstall in dry run changes nothing" {
  stub_brew_with_opencode_installed
  DRY_RUN=1 run toolset_uninstall "$TOOLSET_AI"
  [ "$status" -eq 0 ]
  [[ "$output" == *"would uninstall brew anomalyco/tap/opencode-v2"* ]]
  ! grep -q "brew uninstall" "$STUB_LOG"
}

@test "apply uninstalls before it installs" {
  stub_brew_with_opencode_installed
  WORKSPACE_CONFIRM=y run toolset_apply "$TOOLSET_AI"
  [ "$status" -eq 0 ]
  uninstall_line="$(grep -n 'brew uninstall' "$STUB_LOG" | head -n 1 | cut -d: -f1)"
  bundle_line="$(grep -n 'brew bundle --no-upgrade' "$STUB_LOG" | head -n 1 | cut -d: -f1)"
  [ "$uninstall_line" -lt "$bundle_line" ]
}

@test "status shows packages that must be absent" {
  stub_brew_with_opencode_installed
  run toolset_status "$TOOLSET_AI"
  [[ "$output" == *"✘ absent brew anomalyco/tap/opencode-v2"* ]]
  [[ "$output" == *"✔ absent cask codex"* ]]
}
