# Workspace

This repository controls the setup of a macOS work machine for Claude Code and Claude Desktop. It is the single source of truth for:

- Command-line tools and desktop applications.
- Agent skills, commands, agents and global rules.
- Claude Code plugins and permissions.
- The shell prompt and the shell configuration.

Contents:

1. [Quick start](#1-quick-start)
2. [Model](#2-model)
3. [Repository layout](#3-repository-layout)
4. [Manifest reference](#4-manifest-reference)
5. [Recipes](#5-recipes)
6. [Procedures: add, remove, update](#6-procedures-add-remove-update)
7. [Extend the system: add a new kind](#7-extend-the-system-add-a-new-kind)
8. [Change checklist](#8-change-checklist)
9. [Prune and ownership](#9-prune-and-ownership)
10. [Permission model](#10-permission-model)
11. [Troubleshooting](#11-troubleshooting)
12. [Migration from OpenCode](#12-migration-from-opencode)

## 1. Quick start

On a new Mac:

```bash
git clone <this-repository> workspace
cd workspace
./bootstrap.sh
just setup
```

- `bootstrap.sh` installs Homebrew, `just`, `yq` and `jq`.
- `just setup` validates the manifests, applies them, asks you about each item to prune, and runs `just doctor`.

Open a new terminal after the setup. Then do these steps one time:

1. Run `twg setup` to sign in to Atlassian.
2. Run `sentry auth login` to sign in to Sentry.
3. Start `claude` and sign in to your Claude account.

Run `just setup` again at any time. A second run makes no changes.

## 2. Model

The repository uses a declarative model, like Kubernetes:

- **Manifests** (`manifests/`) declare the necessary state of the machine.
- **The reconciler** (`automation/`) compares the real state with the manifests. Then it changes the machine to match them.
- **Prune** finds items that no manifest declares. It asks you before it deletes each item.

Content that is not configuration stays in plain files. The reconciler finds these files by convention (see [Conventions](#conventions)).

Rules of the model:

- The manifests and the `llms/` folder are the only sources of truth. Do not edit the generated files on the machine.
- Every recipe is idempotent. You can run it many times.
- Tools are additive. The reconciler does not uninstall a tool when you remove it from a manifest. It uninstalls only the packages in the `uninstall` list of a tool set.
- Skills, commands, agents, Claude Code plugins and marketplaces are not additive. Prune removes them when no manifest declares them.

## 3. Repository layout

```
bootstrap.sh                 Installs Homebrew, just, yq and jq
justfile                     The CLI: setup, get, diff, apply, prune, validate, doctor, upgrade, test, lint
manifests/                   Desired state (YAML)
  tools/<name>.yaml          One ToolSet for each file
  installers.yaml            Installer documents
  skills.yaml                SkillSource documents
  claude.yaml                PluginSet and PermissionPolicy for Claude Code
schemas/workspace.v1.json    JSON Schema for all manifests
automation/                  The reconciler (bash 3.2, yq, jq)
  lib/common.sh              Log, confirm, links, backups
  lib/manifest.sh            Load and query the manifests
  kinds/<kind>.sh            Apply and status functions for each kind
  apply.sh get.sh prune.sh validate.sh doctor.sh
  installers/<name>.sh       Install scripts for Installer documents
tests/                       bats tests for the reconciler
llms/
  CLAUDE.md                  Global rules for agents (all projects)
  skills/<name>/SKILL.md     Local skills
  commands/<name>.md         Claude Code commands
  agents/<name>.md           Claude Code subagents
CLAUDE.md                    Rules for agents in this repository
config/                      starship.toml, .aliases, .functions
```

## 4. Manifest reference

### Envelope

Each YAML document has the same envelope:

```yaml
# yaml-language-server: $schema=../schemas/workspace.v1.json
apiVersion: workspace/v1
kind: ToolSet
metadata:
  name: core
  description: Daily CLI baseline
spec: {}
```

| Field | Rule |
|---|---|
| `apiVersion` | Always `workspace/v1`. |
| `kind` | One of the kinds below. |
| `metadata.name` | Lowercase letters, digits and hyphens. Unique in its kind. |
| `metadata.description` | Optional text. |
| `spec` | Fields of the kind. Unknown fields are errors. |

- A file can hold many documents. Use `---` between them.
- The first line sets the schema for VS Code. Use `../schemas/...` in `manifests/` and `../../schemas/...` in `manifests/tools/`.
- A command line refers to a resource as `kind/name` in lowercase, for example `toolset/core`.

### Kinds

| Kind | Purpose | `spec` fields |
|---|---|---|
| `ToolSet` | A group of Homebrew packages | `taps`, `brew`, `cask` (one of `brew` or `cask` is necessary), `uninstall: {brew, cask}` (packages that must not be installed) |
| `Installer` | A tool that has no Homebrew package | `bin` and `script` (necessary), `post`, `hint`, `owns` |
| `SkillSource` | A source of skills | `source` (`owner/repo` or `./path`), `skills` (`["*"]` only for a local path) |
| `PluginSet` | Claude Code marketplaces and plugins | `harness: claude-code`, `marketplaces: [{name, source}]`, `plugins: ["<plugin>@<marketplace>"]` |
| `PermissionPolicy` | Claude Code permissions | `harness: claude-code`, `defaultMode`, `allow`, `ask`, `deny`, `additionalDirectories` |

A plugin must come from a marketplace in `marketplaces` or from the built-in `claude-plugins-official` marketplace. Otherwise, `just validate` fails.

`Installer.owns` lists the skills, commands and agents that the tool installs by itself. Prune keeps them. Example: `owns: { skills: ["twg*"] }`.

### Conventions

| Item | Source | Destination |
|---|---|---|
| Global rules | `llms/CLAUDE.md` | Link at `~/.claude/CLAUDE.md` |
| Claude settings | `manifests/claude.yaml` | The `$schema` and `permissions` keys of `~/.claude/settings.json`. Claude Code owns the other keys. |
| Commands | `llms/commands/*.md` | Links in `~/.claude/commands/` |
| Agents | `llms/agents/*.md` | Links in `~/.claude/agents/` |
| Skills | `manifests/skills.yaml` and `llms/skills/` | `~/.claude/skills/` |
| Prompt | `config/starship.toml` | Link at `~/.config/starship.toml` |
| Shell | `config/.aliases`, `config/.functions` | Managed block in `~/.zshrc` |

## 5. Recipes

| Recipe | Result |
|---|---|
| `just` | Shows all recipes. |
| `just setup` | Runs `validate`, `apply`, `prune` and `doctor`. |
| `just setup-ci` | Runs the setup with no questions. Prune only shows the items. |
| `just get <kind>` | Shows the declared resources and their status. Kinds: `toolset`, `installer`, `skillsource`, `claude`. |
| `just diff [kind/name...]` | Shows the changes that `apply` will make. It changes nothing. |
| `just apply [kind/name...]` | Changes the machine to match the manifests. With no argument, it applies all. |
| `just apply --pick toolset/<name>` | Asks you about each package of a tool set. |
| `just prune [--dry-run]` | Asks you about each item that no manifest declares, then deletes it. |
| `just validate` | Validates the manifests against the schema. |
| `just doctor` | Shows a `✔` or `✘` line for each part of the machine state. |
| `just upgrade` | Upgrades the Homebrew packages, the skills, the Claude Code marketplaces and the plugins. |
| `just test` | Runs the reconciler tests. |
| `just lint` | Runs `shellcheck` on the reconciler scripts. |

## 6. Procedures: add, remove, update

Each procedure ends with the [change checklist](#8-change-checklist).

Terms: "remove" applies to an entry in a list or a table. "Delete" applies to a file, a folder or a manifest document.

### 6.1 Homebrew tool

**Add:**

1. Select a tool set in `manifests/tools/`. If no tool set fits, see 6.2.
2. Add the package name to `brew` or `cask`. Add a short comment after the name.
3. If the package comes from a tap, add the tap to `taps`. Use the full name, for example `oven-sh/bun/bun`. The reconciler tells Homebrew to trust each full name.
4. Run `just apply toolset/<name>`.

**Remove:**

1. Remove the line from the tool set.
2. The reconciler does not uninstall it. To uninstall the package, add it to `uninstall` of the tool set. `just apply` asks before it uninstalls it.

**Update:** run `just upgrade`.

### 6.2 Tool set

**Add:**

1. Create `manifests/tools/<name>.yaml`:

   ```yaml
   # yaml-language-server: $schema=../../schemas/workspace.v1.json
   apiVersion: workspace/v1
   kind: ToolSet
   metadata:
     name: <name>
     description: <purpose>
   spec:
     brew:
       - <package>   # <purpose>
   ```

2. Run `just apply toolset/<name>`.

**Remove:** delete the file. The packages stay installed.

### 6.3 Tool with no Homebrew package (Installer)

**Add:**

1. Create `automation/installers/<name>.sh`. Start it with `#!/usr/bin/env bash` and `set -euo pipefail`. The script must install the binary and must not ask questions.
2. Run `chmod +x automation/installers/<name>.sh`.
3. Add a document to `manifests/installers.yaml`:

   ```yaml
   ---
   apiVersion: workspace/v1
   kind: Installer
   metadata:
     name: <name>
     description: <purpose>
   spec:
     bin: <binary-name>
     script: automation/installers/<name>.sh
     post: ["<command to run one time after the install>"]
     hint: <one-time step for the user, for example a sign-in>
     owns:
       skills: ["<glob of skills that the tool installs>"]
       commands: ["<glob of commands that the tool installs>"]
   ```

4. Run `just apply installer/<name>`.

The reconciler skips the installer when `bin` is on `PATH`.

**Remove:**

1. Delete the document and the script.
2. Uninstall the tool with its own procedure.
3. Run `just prune`. Prune now offers the skills and commands that the tool owned.

### 6.4 External skill

**Add:**

1. Find the repository and the skill names: `npx skills add <owner/repo> --list`.
2. In `manifests/skills.yaml`, add the names to the `SkillSource` of that repository, or add a new document:

   ```yaml
   ---
   apiVersion: workspace/v1
   kind: SkillSource
   metadata:
     name: <name>
     description: <purpose>
   spec:
     source: <owner/repo>
     skills: [<skill-name>]
   ```

3. Run `just apply skillsource/<name>`.
4. Add the skill to the skills table in `llms/CLAUDE.md`, with the condition to load it.

The skills CLI installs the skill into `~/.claude/skills/<name>`.

**Remove:**

1. Remove the name from `skills`. Delete the document if the list is empty.
2. Remove the skill from the table in `llms/CLAUDE.md`.
3. Run `just prune`.

**Update:** run `just upgrade`.

### 6.5 Local skill

**Add:**

1. Create `llms/skills/<name>/SKILL.md`:

   ```markdown
   ---
   name: <name>
   description: <when to use the skill, in one or two sentences>
   ---

   # <Title>

   <instructions>
   ```

2. The `name` must be the same as the folder name. Use lowercase letters, digits and hyphens.
3. Run `just apply skillsource/local`.
4. Add the skill to the skills table in `llms/CLAUDE.md`.

The skill is a link in `~/.claude/skills/`. A change to the file applies immediately.

**Remove:** delete the folder, update `llms/CLAUDE.md`, then run `just prune`.

### 6.6 Claude Code plugin

**Add:**

1. If the plugin is not in `claude-plugins-official`, add its marketplace to `marketplaces` of the `PluginSet` in `manifests/claude.yaml`. Example: `{name: plannotator, source: backnotprop/plannotator}`.
2. Add `<plugin>@<marketplace>` to `plugins`.
3. Run `just apply pluginset/claude-code`.

**Remove:**

1. Remove the entry from `plugins`. Remove its marketplace from `marketplaces` if no other plugin uses it.
2. Run `just prune`. Prune runs `claude plugin uninstall` and `claude plugin marketplace remove`.

**Update:** run `just upgrade`.

### 6.7 Permission

1. Open `PermissionPolicy` in `manifests/claude.yaml`.
2. Write the rule in the Claude Code syntax. Examples: `Bash(git push *)`, `Read(~/path/**)`, `Read(//**/.env)`, `WebFetch(domain:example.com)`.
3. Put the rule in `allow`, `ask` or `deny`.
4. Run `just apply pluginset/claude-code`.

To make a dangerous form of an allowed command safe, add the dangerous form to `ask`. Example: `allow: ["Bash(git push *)"]` and `ask: ["Bash(git push --force*)"]`.

### 6.8 Command

**Add:**

1. Create `llms/commands/<name>.md` with frontmatter `description`. Use `$ARGUMENTS` for the arguments.
2. Run `just apply`. The reconciler links the file in `~/.claude/commands/`.
3. Add the command to the commands table in `llms/CLAUDE.md`.

**Remove:** delete the file, update `llms/CLAUDE.md`, then run `just prune`.

### 6.9 Agent

**Add:**

1. Create `llms/agents/<name>.md` in the Claude Code subagent format. The frontmatter `name` and `description` are necessary. The frontmatter `tools` and `model` are optional.
2. Run `just apply`. The reconciler links the file in `~/.claude/agents/`.

**Remove:** delete the file, then run `just prune`.

### 6.10 Global rules (`llms/CLAUDE.md`)

1. Edit `llms/CLAUDE.md`. Use US English and ASD-STE100 (load the `asd-ste100` skill).
2. Keep the section numbers. Add a new section at the end.
3. Keep the skills and commands tables the same as the manifests and `llms/commands/`.

The file is a link. A change applies to new sessions immediately.

## 7. Extend the system: add a new kind

Add a new kind only when no current kind can declare the item. For example, a new harness or a new type of configuration file. `automation/kinds/claude.sh` is an example of a complete kind.

1. **Schema.** In `schemas/workspace.v1.json`:
   - Add the kind to the `kind` enum.
   - Add a definition in `$defs` with `additionalProperties: false`.
   - Add an `if`/`then` entry in `allOf` that connects the kind to its definition.
2. **Reconciler.** Create `automation/kinds/<kind>.sh` with two functions:
   - `<kind>_apply <resource-json>`: changes the machine. It must be idempotent. It must obey `DRY_RUN=1` (print, do not change). It must call `confirm` before it replaces or deletes a file of the user. Example: `claude_apply`.
   - `<kind>_status <resource-json>`: prints `✔` or `✘` lines. Example: `claude_status`.
3. **Dispatch.** Source the new file in `automation/apply.sh` and `automation/get.sh`. Add the kind to the `case` in `apply_resource`, to the full apply sequence, and to the `case` in `get.sh`.
4. **Prune.** If the kind installs files that prune must keep or delete, add them to the declared lists and `scan_dir` calls in `automation/prune.sh`.
5. **Doctor.** Add the checks for the kind to `automation/doctor.sh`.
6. **Tests.** Create `tests/<kind>.bats`. Use `setup_workspace` from `tests/helpers.bash`. Stub external commands with `stub_command` or `log_stub_calls`. Test the apply result, the no-op second run, the dry run and each confirmation path.
7. **Documentation.** Update sections 3, 4 and 6 of this file.

Rules for reconciler code:

- Use bash 3.2 syntax. Do not use associative arrays, `mapfile` or `${var,,}`.
- Quote every path. The repository path can contain spaces.
- Read questions from `/dev/tty` through `confirm`. Add `</dev/null` to commands in loops that read a here-string.
- Do not write comments. Use clear names.

## 8. Change checklist

Do these steps after each change:

1. `just validate`
2. `just test` (if you changed `automation/` or `tests/`)
3. `just lint` (if you changed a script)
4. `just diff` — read the planned changes.
5. `just apply` or `just apply <kind/name>`
6. `just prune` (if you removed an item)
7. `just doctor` — all checks must show `✔`.
8. Commit with a Conventional Commits message, for example `feat: add terraform to the cloud tool set`.

## 9. Prune and ownership

Prune examines these items:

- `~/.claude/skills` (but not `synced/`, which Claude Desktop controls)
- `~/.claude/agents` and `~/.claude/commands`
- `~/.agents/skills` (only the skills that an `Installer` owns stay)
- The Claude Code plugins and marketplaces that no manifest declares. The `claude-plugins-official` marketplace stays.
- The obsolete folders `~/.config/opencode`, `~/.cache/opencode` and `~/.codex`

An item is a candidate when no manifest declares it, or when it is a broken link. Prune asks you before it removes each item. The default answer is No. `just prune --dry-run` only shows the candidates.

Prune removes a plugin with `claude plugin uninstall` and a marketplace with `claude plugin marketplace remove`. It removes a skill that the skills CLI tracks with `npx skills remove`.

Some tools install their own skills or commands. The `owns` field of an `Installer` tells prune to keep these items.

## 10. Permission model

Claude Code applies `deny` rules first, then `ask` rules, then `allow` rules. The sequence in the file has no effect. Thus an `ask` rule always overrides an `allow` rule for the same command.

- Read-only commands such as `ls`, `cat` and `git status` need no rule.
- In a compound command (`&&`, `;`, `|`), each part must be allowed.
- `defaultMode: acceptEdits` lets Claude Code edit files in the project with no question.
- `additionalDirectories` gives Claude Code access to folders out of the project, for example `~/.claude/plans`.

Limits:

- Permission rules are not a sandbox. An allowed interpreter (`python`, `node`, `bun`) can run any code.
- Rules match the command text. Thus `git -C . push` does not match `git push *`.
- A plain `git push` with no branch name does not match the branch rules. Always push with an explicit branch name.

## 11. Troubleshooting

| Problem | Procedure |
|---|---|
| `just validate` shows a schema error | Read the file name and the field in the error. Compare it with [Manifest reference](#4-manifest-reference). |
| Claude settings drifted | Run `just diff pluginset/claude-code`, then `just apply pluginset/claude-code`. Make permanent changes in `manifests/claude.yaml`. |
| A plugin is not installed | Run `claude plugin marketplace list` and `claude plugin list`. Then run `just apply pluginset/claude-code`. |
| `skill <name> was not installed` | Run `npx skills add <owner/repo> --list` and compare the names with the manifest. |
| `name ... does not match folder` | Make the `name` in `SKILL.md` the same as the folder name. |

## 12. Migration from OpenCode

The workspace supported OpenCode and Codex before. Now it supports only Claude Code and Claude Desktop.

1. Close OpenCode. Run the migration from a terminal such as iTerm.
2. Run `just setup`. It asks before it uninstalls each OpenCode and Codex package.
3. Prune asks before it deletes each obsolete folder: `~/.config/opencode`, `~/.cache/opencode` and `~/.codex`.
4. If you installed twg before the migration, run `twg skills install --agent claude -y` one time.
5. Move your old plans from `~/.agents/plans` to `~/.claude/plans`. Move your old specifications from `~/.agents/spec` to `~/.claude/specs`.
6. Run `just setup` again. It must make no changes.
7. Run `just doctor`. All checks must show `✔`.
