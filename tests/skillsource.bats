#!/usr/bin/env bats

load helpers

setup() {
  setup_workspace
  load_automation skillsource
  LOCAL_SOURCE='{"kind":"SkillSource","metadata":{"name":"local"},"spec":{"source":"./llms/skills","skills":["*"]}}'
  REMOTE_SOURCE='{"kind":"SkillSource","metadata":{"name":"remote"},"spec":{"source":"owner/repo","skills":["alpha","beta"]}}'
  stub_command node 'exit 0'
}

stub_npx_that_installs() {
  stub_command npx '
echo "npx $*" >>"$STUB_LOG"
while [ $# -gt 0 ]; do
  if [ "$1" = "--skill" ]; then
    mkdir -p "$HOME/.claude/skills/$2"
    printf -- "---\nname: %s\n---\n" "$2" >"$HOME/.claude/skills/$2/SKILL.md"
    shift
  fi
  shift
done'
}

@test "local skills are linked into the claude skills dir" {
  create_skill "$WORKSPACE_DIR/llms/skills/upskill"
  skillsource_apply "$LOCAL_SOURCE"
  [ "$(readlink "$HOME/.claude/skills/upskill")" = "$WORKSPACE_DIR/llms/skills/upskill" ]
}

@test "a local skill with a mismatched name fails" {
  create_skill "$WORKSPACE_DIR/llms/skills/upskill" other-name
  run skillsource_apply "$LOCAL_SOURCE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not match folder"* ]]
}

@test "remote skills that are present do not call npx" {
  log_stub_calls npx
  create_skill "$HOME/.claude/skills/alpha"
  create_skill "$HOME/.claude/skills/beta"
  run skillsource_apply "$REMOTE_SOURCE"
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
}

@test "missing remote skills are added globally for claude code only" {
  stub_npx_that_installs
  create_skill "$HOME/.claude/skills/alpha"
  run skillsource_apply "$REMOTE_SOURCE"
  [ "$status" -eq 0 ]
  grep -qx "npx -y skills add owner/repo -g -a claude-code --copy -y --skill beta" "$STUB_LOG"
}

@test "remote apply fails when npx does not create the skill" {
  log_stub_calls npx
  run skillsource_apply "$REMOTE_SOURCE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"skill alpha was not installed from owner/repo"* ]]
}

@test "remote apply in dry run calls nothing" {
  log_stub_calls npx
  DRY_RUN=1 run skillsource_apply "$REMOTE_SOURCE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"would add from owner/repo: alpha beta"* ]]
  [ ! -s "$STUB_LOG" ]
}
