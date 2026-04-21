# Run Claude Command: $COMMAND

Search for a Claude command named `$COMMAND` in `.claude/commands/` directories under the current project and execute it.

## Instructions

1. **Find the command**: Search recursively under the current working directory for `.claude/commands/$COMMAND.md`. Check paths like:
   - `.claude/commands/$COMMAND.md`
   - Any nested `.claude/commands/$COMMAND.md` found via `./**/.claude/commands/`
   - Also try matching with subdirectory separators (e.g., if `$COMMAND` contains `:`, replace `:` with `/` and search for that path)

2. **If found**: Read the file content and execute the instructions contained in it. If the command contains `$PLACEHOLDER` variables and the user provided arguments below, substitute them accordingly. If the command has a single placeholder, replace it with the full arguments string.

3. **If NOT found**: List all available commands by searching for all `.md` files under `./**/.claude/commands/` directories. Present them as a list so the user can pick one. Format each entry as the filename without the `.md` extension. If subdirectories exist, show them as `directory/name`.

## Arguments

```
$ARGUMENTS
```
