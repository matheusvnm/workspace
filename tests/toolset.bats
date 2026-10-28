#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation toolset
  TOOLSET_TAPPED='{"kind":"ToolSet","metadata":{"name":"ai"},"spec":{"taps":["anomalyco/tap"],"brew":["anomalyco/tap/opencode-v2"],"cask":["codex"]}}'
  TOOLSET_AI='{"kind":"ToolSet","metadata":{"name":"ai"},"spec":{"cask":["claude"],"uninstall":{"brew":["anomalyco/tap/opencode-v2"],"cask":["codex"]}}}'
  TOOLSET_MISSING='{"kind":"ToolSet","metadata":{"name":"fake"},"spec":{"brew":["fake-alpha"],"cask":["fake-app"]}}'
}

@test "render_brewfile writes taps, brews and casks in order and trusts tap items" {
  expected='tap "anomalyco/tap"
brew "anomalyco/tap/opencode-v2", trusted: true
cask "codex"'
  [ "$(render_brewfile "$TOOLSET_TAPPED")" = "$expected" ]
}

stub_brew_with_nothing_installed() {
  stub_command brew '
echo "brew $*" >>"$STUB_LOG"
case "$*" in
  "list "*) exit 1 ;;
  "info "*) printf "%s\n" "${BREW_INFO_JSON:-}" ;;
esac
exit 0'
}

@test "apply installs the missing packages with brew bundle" {
  stub_brew_with_nothing_installed
  run toolset_apply "$TOOLSET_MISSING"
  [ "$status" -eq 0 ]
  grep -q "brew bundle --no-upgrade" "$STUB_LOG"
}

@test "apply in dry run lists the missing packages and installs nothing" {
  stub_brew_with_nothing_installed
  DRY_RUN=1 run toolset_apply "$TOOLSET_MISSING"
  [ "$status" -eq 0 ]
  [[ "$output" == *"would install brew fake-alpha"* ]]
  [[ "$output" == *"would install cask fake-app"* ]]
  ! grep -q "brew bundle" "$STUB_LOG"
}

@test "apply installs nothing when the user declines the group" {
  stub_brew_with_nothing_installed
  IS_SELECT=1 WORKSPACE_GROUP_CHOICE=none run toolset_apply "$TOOLSET_MISSING"
  [ "$status" -eq 0 ]
  ! grep -q "brew bundle" "$STUB_LOG"
}

@test "apply skips a formula that is on PATH but not managed by brew" {
  stub_brew_with_nothing_installed
  stub_command fake-alpha 'exit 0'
  DRY_RUN=1 run toolset_apply "$TOOLSET_MISSING"
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew fake-alpha is present at $STUB_BIN/fake-alpha and brew does not manage it. Skipped."* ]]
  [[ "$output" != *"would install brew fake-alpha"* ]]
}

@test "apply checks the bin of a formula when the tool set declares one" {
  stub_brew_with_nothing_installed
  stub_command fake-alpha-bin 'exit 0'
  DRY_RUN=1 run toolset_apply "$(jq -c '.spec.bins = {"fake-alpha": "fake-alpha-bin"}' <<<"$TOOLSET_MISSING")"
  [[ "$output" == *"brew fake-alpha is present at $STUB_BIN/fake-alpha-bin"* ]]
}

@test "apply skips a cask whose app is already in the Applications folder" {
  stub_brew_with_nothing_installed
  mkdir -p "$APPLICATIONS_DIR/Fake.app"
  BREW_INFO_JSON='{"casks":[{"artifacts":[{"uninstall":[]},{"app":["Fake.app"]}]}]}' DRY_RUN=1 run toolset_apply "$TOOLSET_MISSING"
  [[ "$output" == *"cask fake-app is present at $APPLICATIONS_DIR/Fake.app"* ]]
  [[ "$output" != *"would install cask fake-app"* ]]
}

@test "apply skips a cask whose binary target is already on PATH" {
  stub_brew_with_nothing_installed
  stub_command fake-cli 'exit 0'
  BREW_INFO_JSON='{"casks":[{"artifacts":[{"binary":["/opt/x/bin/real",{"target":"/usr/local/bin/fake-cli"}]}]}]}' DRY_RUN=1 run toolset_apply "$TOOLSET_MISSING"
  [[ "$output" == *"cask fake-app is present at $STUB_BIN/fake-cli"* ]]
}

@test "toolset_with_keys keeps the taps and only the selected packages" {
  expected='tap "anomalyco/tap"
cask "codex"'
  [ "$(render_brewfile "$(toolset_with_keys "$TOOLSET_TAPPED" " cask/codex")")" = "$expected" ]
}

stub_brew_with_opencode_installed() {
  stub_command brew '
echo "brew $*" >>"$STUB_LOG"
case "$*" in
  "list --formula opencode-v2") exit 0 ;;
  "list --cask codex") exit 1 ;;
  "list --cask claude") exit 1 ;;
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
