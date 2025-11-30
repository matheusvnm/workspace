# Developer Tools Setup (Tools)

Automated setup for macOS developer environment with tool installation and AI CLI configuration management.

## What This Does

This repository provides:

1. **Automated Tool Installation** - Installs all essential developer tools via Homebrew Bundle
2. **AI CLI Configuration** - Manages reusable configurations for Claude Code and Gemini CLI
3. **Cross-Machine Sync** - Version control your tools and configurations across multiple machines

## Quick Start

```bash
# Clone repository
git clone <repo-url> ~/tools
cd ~/tools

# Install developer tools
./install.sh

# Setup AI CLI configurations (interactive)
./scripts/setup-configs.sh

# Install git hooks for auto-sync
./scripts/install-git-hooks.sh

# Add your API keys
vim .env.claude    # Add: ANTHROPIC_API_KEY=your_key
vim .env.gemini    # Add: GEMINI_API_KEY=your_key

# Reload shell
source ~/.zshrc
```

## Installed Tools

### GUI Applications
- VS Code, Docker Desktop, Slack
- Redis Insight, DBeaver, MongoDB Compass, Postman

### CLI Tools
- GitHub CLI (gh), Just, UV, Git
- Claude Code, Gemini CLI
- Standard utilities: wget, jq, tree

## Configuration System

### How It Works

All AI CLI configurations are **symlinked** from this repo to your home directory:
- `configs/claude/` → `~/.claude/`
- `configs/gemini/` → `~/.gemini/`

**Benefits:**
- ✅ Changes made locally are automatically reflected in the repo
- ✅ Version control your custom commands and agents
- ✅ Easy sync across machines via git pull/push

### Directory Structure

```
configs/
├── claude/
│   ├── commands/         # Custom slash commands (*.md)
│   ├── agents/           # Custom subagents (*.md)
│   ├── settings.json     # Global settings
│   └── .env.example      # Environment variables template
└── gemini/
    ├── commands/         # Custom commands (*.toml)
    └── .env.example      # Environment variables template
```

## Environment Variables

API keys and secrets are stored in `.env` files (gitignored):
- `.env.claude` - Claude Code API keys
- `.env.gemini` - Gemini CLI API keys

These are automatically loaded in your shell profile during setup.

## Documentation & Resources

### Claude Code
- [Custom Commands Guide](https://docs.anthropic.com/en/docs/build-with-claude/claude-code/custom-commands)
- [Subagents Guide](https://docs.anthropic.com/en/docs/build-with-claude/claude-code/custom-agents)
- [Settings & Configuration](https://docs.anthropic.com/en/docs/build-with-claude/claude-code/settings)
- [Permissions System](https://docs.anthropic.com/en/docs/build-with-claude/claude-code/permissions)

### Gemini CLI
- [Custom Commands Documentation](https://geminicli.com/docs/cli/custom-commands/)
- [Configuration Guide](https://geminicli.com/docs/get-started/configuration/)
- [CLI Commands Reference](https://geminicli.com/docs/cli/commands/)
- [GitHub Repository](https://github.com/google-gemini/gemini-cli)

### Homebrew
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [Brewfile Documentation](https://docs.brew.sh/Manpage#bundle-subcommand)
