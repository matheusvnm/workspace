#!/bin/bash

###############################################################################
# Configuration Setup for Claude Code and Gemini CLI
#
# Features:
# - Interactive selection (claude, gemini, or both)
# - Symlink-based installation
# - Environment variable setup
# - Shell profile integration
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

###############################################################################
# Selection Menu
###############################################################################

show_menu() {
    echo ""
    echo "Select which configurations to install:"
    echo "  1) Claude Code only"
    echo "  2) Gemini CLI only"
    echo "  3) Both"
    echo "  4) Exit"
    echo ""
}

###############################################################################
# Claude Code Setup
###############################################################################

setup_claude() {
    log_info "Setting up Claude Code configurations..."

    # Create directories
    mkdir -p ~/.claude

    # Symlink commands
    if [ -d "$REPO_ROOT/configs/claude/commands" ]; then
        rm -rf ~/.claude/commands
        ln -sf "$REPO_ROOT/configs/claude/commands" ~/.claude/commands
        log_success "Linked Claude commands directory"
    fi

    # Symlink agents
    if [ -d "$REPO_ROOT/configs/claude/agents" ]; then
        rm -rf ~/.claude/agents
        ln -sf "$REPO_ROOT/configs/claude/agents" ~/.claude/agents
        log_success "Linked Claude agents directory"
    fi

    # Symlink settings
    if [ -f "$REPO_ROOT/configs/claude/settings.json" ]; then
        rm -f ~/.claude/settings.json
        ln -sf "$REPO_ROOT/configs/claude/settings.json" ~/.claude/settings.json
        log_success "Linked Claude settings.json"
    fi

    # Setup environment variables
    if [ ! -f "$REPO_ROOT/.env.claude" ]; then
        if [ -f "$REPO_ROOT/configs/claude/.env.example" ]; then
            log_warning "Creating .env.claude from template..."
            cp "$REPO_ROOT/configs/claude/.env.example" "$REPO_ROOT/.env.claude"
            log_warning "Please edit .env.claude and add your API keys"
        fi
    else
        log_success ".env.claude already exists"
    fi

    # Add to shell profile
    add_to_shell_profile "claude"

    log_success "Claude Code setup complete!"
}

###############################################################################
# Gemini CLI Setup
###############################################################################

setup_gemini() {
    log_info "Setting up Gemini CLI configurations..."

    # Create directories
    mkdir -p ~/.gemini

    # Symlink commands
    if [ -d "$REPO_ROOT/configs/gemini/commands" ]; then
        rm -rf ~/.gemini/commands
        ln -sf "$REPO_ROOT/configs/gemini/commands" ~/.gemini/commands
        log_success "Linked Gemini commands directory"
    fi

    # Setup environment variables
    if [ ! -f "$REPO_ROOT/.env.gemini" ]; then
        if [ -f "$REPO_ROOT/configs/gemini/.env.example" ]; then
            log_warning "Creating .env.gemini from template..."
            cp "$REPO_ROOT/configs/gemini/.env.example" "$REPO_ROOT/.env.gemini"
            log_warning "Please edit .env.gemini and add your API keys"
        fi
    else
        log_success ".env.gemini already exists"
    fi

    # Add to shell profile
    add_to_shell_profile "gemini"

    log_success "Gemini CLI setup complete!"
}

###############################################################################
# Shell Profile Integration
###############################################################################

add_to_shell_profile() {
    local tool=$1
    local env_file="$REPO_ROOT/.env.$tool"

    # Detect shell
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = *"zsh"* ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = *"bash"* ]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [ -z "$shell_rc" ]; then
        log_warning "Could not detect shell. Please manually add to your shell profile:"
        echo "export \$(grep -v '^#' $env_file | xargs)"
        return
    fi

    # Check if already added
    if grep -q "\.env\.$tool" "$shell_rc" 2>/dev/null; then
        log_info "$tool environment already in $shell_rc"
        return
    fi

    # Add to shell profile
    cat >> "$shell_rc" << EOF

# Auto-load $tool environment variables
if [ -f "$env_file" ]; then
  export \$(grep -v '^#' "$env_file" | xargs 2>/dev/null)
fi
EOF

    log_success "Added $tool environment to $shell_rc"
    log_warning "Run 'source $shell_rc' to load environment in current shell"
}

###############################################################################
# Verify Setup
###############################################################################

verify_setup() {
    local tool=$1

    echo ""
    log_info "Verifying $tool setup..."

    if [ "$tool" = "claude" ]; then
        if [ -L ~/.claude/commands ] && [ -L ~/.claude/agents ]; then
            log_success "Claude symlinks verified"
            ls -la ~/.claude/
        else
            log_error "Claude symlinks missing"
        fi
    elif [ "$tool" = "gemini" ]; then
        if [ -L ~/.gemini/commands ]; then
            log_success "Gemini symlinks verified"
            ls -la ~/.gemini/
        else
            log_error "Gemini symlinks missing"
        fi
    fi
}

###############################################################################
# Main
###############################################################################

main() {
    echo ""
    echo "======================================"
    echo "  Configuration Setup"
    echo "======================================"

    # Interactive menu
    while true; do
        show_menu
        read -p "Enter choice [1-4]: " choice

        case $choice in
            1)
                setup_claude
                verify_setup "claude"
                break
                ;;
            2)
                setup_gemini
                verify_setup "gemini"
                break
                ;;
            3)
                setup_claude
                setup_gemini
                verify_setup "claude"
                verify_setup "gemini"
                break
                ;;
            4)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please enter 1-4."
                ;;
        esac
    done

    echo ""
    echo "======================================"
    echo "  Setup Complete!"
    echo "======================================"
    echo ""
    log_info "Next steps:"
    echo "  1. Edit .env.claude and/or .env.gemini with your API keys"
    echo "  2. Reload your shell: source ~/.zshrc (or ~/.bashrc)"
    echo "  3. Verify: echo \$ANTHROPIC_API_KEY or \$GEMINI_API_KEY"
    echo ""
}

main
