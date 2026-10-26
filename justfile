set shell := ["bash", "-euo", "pipefail", "-c"]

export HOMEBREW_NO_ENV_HINTS := "1"
export WORKSPACE_DIR := justfile_directory()

automation := justfile_directory() / "automation"

[doc("List all recipes")]
default:
    @just --list --unsorted

[group("setup")]
[doc("Validate, apply, prune and verify the whole workspace")]
setup: validate apply prune doctor

[group("setup")]
[doc("Run setup with no prompts; prune runs as a dry run")]
setup-ci:
    just validate
    WORKSPACE_CONFIRM=n just apply
    just prune --dry-run
    just doctor

[group("ops")]
[doc("Show declared resources and their status: just get toolset|installer|skillsource|opencode")]
get kind:
    bash "{{ automation }}/get.sh" {{ kind }}

[group("ops")]
[doc("Show planned changes and write nothing: just diff [kind/name...]")]
diff *refs:
    DRY_RUN=1 bash "{{ automation }}/apply.sh" {{ refs }}

[group("ops")]
[doc("Converge the machine to the manifests: just apply [--pick] [kind/name...]")]
apply *args:
    bash "{{ automation }}/apply.sh" {{ args }}

[group("ops")]
[doc("Delete undeclared skills, agents, commands and old caches, one by one: just prune [--dry-run|--check]")]
prune *args:
    bash "{{ automation }}/prune.sh" {{ args }}

[group("ops")]
[doc("Validate the manifests against the schema")]
validate:
    bash "{{ automation }}/validate.sh"

[group("ops")]
[doc("Verify the machine state")]
doctor:
    bash "{{ automation }}/doctor.sh"

[group("ops")]
[doc("Upgrade brew packages, skills and OpenCode plugins")]
upgrade:
    brew update
    brew upgrade
    DISABLE_TELEMETRY=1 npx -y skills update -g -y
    opencode plugin update

[group("dev")]
[doc("Run the automation tests")]
test:
    bats "{{ justfile_directory() }}/tests"

[group("dev")]
[doc("Lint the automation scripts")]
lint:
    find "{{ automation }}" "{{ justfile_directory() }}/bootstrap.sh" -name '*.sh' -print0 | xargs -0 shellcheck -x -e SC1090,SC1091
