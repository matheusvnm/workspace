# Developer Tools Setup

Automated setup script for installing essential developer tools on macOS using Homebrew Bundle.

## Overview

This repository uses a **Brewfile** to declaratively manage all your developer tools. Perfect for setting up a new Mac or keeping multiple machines in sync.

## Tools Included

### GUI Applications
- **Visual Studio Code** - Code editor
- **Docker Desktop** - Containerization platform
- **Redis Insight** - Redis GUI
- **DBeaver Community** - Universal database tool
- **Slack** - Team communication
- **MongoDB Compass** - MongoDB GUI
- **Postman** - API testing platform

### CLI Tools
- **GitHub CLI (gh)** - GitHub command line tool
- **Just** - Command runner for justfiles
- **UV** - Python package manager
- **Git** - Version control
- **Wget** - Network downloader
- **jq** - JSON processor
- **tree** - Directory structure viewer
- **Gemini CLI** - Google's AI CLI tool
- **Claude Code** - AI-powered CLI assistant

## Prerequisites

- macOS
- Internet connection
- Administrator access

## Installation

### Quick Start

```bash
git clone https://github.com/yourusername/tools.git
cd tools
chmod +x install.sh
./install.sh
```

### What Happens

The script will:
1. ✓ Verify you're running on macOS
2. ✓ Install Homebrew if not present
3. ✓ Update Homebrew
4. ✓ Install all tools from Brewfile
5. ✓ Show post-installation notes

## Using Brewfile Directly

You can also use the Brewfile directly with Homebrew:

```bash
# Install all dependencies
brew bundle

# Check what would be installed
brew bundle check

# List all dependencies
brew bundle list

# Cleanup (remove tools not in Brewfile)
brew bundle cleanup
```

## Adding New Tools

Simply edit the `Brewfile`:

```ruby
# For CLI tools
brew "tool-name"

# For GUI applications
cask "app-name"

# For custom taps
tap "owner/repo"
brew "owner/repo/tool"
```

Then run:
```bash
brew bundle
```

## Managing Tools

### Update All Tools

```bash
brew update
brew upgrade
brew upgrade --cask
```

### Check Brewfile Status

```bash
# Check if all Brewfile dependencies are installed
brew bundle check

# List what's in the Brewfile
brew bundle list
```

### Cleanup

```bash
# Remove tools not listed in Brewfile
brew bundle cleanup --force
```

### Search for Tools

```bash
# Search Homebrew
brew search <name>

# Check if a package exists
brew info <name>
```

## Post-Installation

After running the script:

1. **Start Docker Desktop** from Applications

2. **Authenticate GitHub CLI**:
   ```bash
   gh auth login
   ```

3. **Configure Claude Code** with your API key if needed

4. **Install VS Code extensions**:
   ```bash
   code --install-extension <extension-id>
   ```

## Updating

```bash
# Update Homebrew
brew update

# Update all packages
brew upgrade

# Update cask applications
brew upgrade --cask

# Or update from Brewfile
brew bundle
```

## Backing Up Your Setup

To export your current Homebrew setup:

```bash
# Export all installed packages
brew bundle dump --describe --force

# This creates/updates your Brewfile with current installations
```

## Features

- **Declarative**: All tools defined in one Brewfile
- **Idempotent**: Safe to run multiple times
- **Version Control**: Track tool changes in git
- **Portable**: Share your setup across machines
- **Simple**: Native Homebrew solution
- **Fast**: Homebrew's parallel installation

## Troubleshooting

### Homebrew Issues

```bash
# Diagnose problems
brew doctor

# Update Homebrew itself
brew update

# Reinstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Tool Installation Fails

```bash
# Try installing manually
brew install <tool-name>

# Check for issues
brew info <tool-name>

# Force reinstall
brew reinstall <tool-name>
```

### Permission Issues

```bash
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Brewfile Not Found

Make sure you're running the script from the repository directory:
```bash
cd /path/to/tools
./install.sh
```

## Files

- `Brewfile` - Declarative list of all tools
- `install.sh` - Installation script
- `.gitignore` - Git ignore patterns
- `README.md` - This file

## Why Brewfile?

Homebrew Bundle (Brewfile) is the standard way to manage dependencies on macOS:

- ✅ Native to Homebrew
- ✅ Simple syntax
- ✅ Handles both CLI and GUI apps
- ✅ Version controllable
- ✅ Easy to share
- ✅ Wide tool support
- ✅ Declarative dependency management

## Resources

- [Homebrew Bundle Documentation](https://github.com/Homebrew/homebrew-bundle)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Brewfile Examples](https://github.com/Homebrew/homebrew-bundle)

## License

MIT License - Feel free to use and modify as needed.
