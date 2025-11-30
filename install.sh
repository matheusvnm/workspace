#!/bin/bash

###############################################################################
# Developer Tools Installation Script for macOS
#
# This script uses Homebrew Bundle (Brewfile) to install all tools.
# It's idempotent - safe to run multiple times, only installs what's missing.
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# Logging Functions
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

###############################################################################
# System Validation
###############################################################################

check_macos() {
    log_section "Checking Operating System"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only."
        log_error "Detected OS: $OSTYPE"
        exit 1
    fi

    log_success "Running on macOS ($(sw_vers -productVersion))"
}

###############################################################################
# Homebrew Setup
###############################################################################

install_homebrew() {
    log_section "Checking Homebrew"

    if command -v brew &> /dev/null; then
        log_success "Homebrew is already installed ($(brew --version | head -n1))"
        return 0
    fi

    log_warning "Homebrew not found. Installing Homebrew..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if command -v brew &> /dev/null; then
        log_success "Homebrew installed successfully"
    else
        log_error "Failed to install Homebrew"
        exit 1
    fi
}

update_homebrew() {
    log_info "Updating Homebrew..."
    brew update
    log_success "Homebrew updated"
}

###############################################################################
# Install Tools via Brewfile
###############################################################################

install_from_brewfile() {
    log_section "Installing Tools from Brewfile"

    if [ ! -f "Brewfile" ]; then
        log_error "Brewfile not found in current directory"
        log_error "Please run this script from the repository root"
        exit 1
    fi

    log_info "Installing all tools from Brewfile..."
    log_info "This may take a while on first run..."
    echo ""

    if brew bundle --verbose; then
        log_success "All tools from Brewfile installed successfully"
    else
        log_warning "Some tools may have failed to install"
        log_info "Run 'brew bundle cleanup --force' to remove unlisted tools"
    fi
}

###############################################################################
# Post-Installation
###############################################################################

show_post_install_notes() {
    log_section "Post-Installation Notes"

    echo ""
    log_info "🐳 Docker:"
    echo "  Start Docker Desktop from Applications to complete setup"
    echo "  Open /Applications/Docker.app"
    echo ""

    log_info "🔑 GitHub CLI:"
    echo "  Authenticate with: gh auth login"
    echo ""

    log_info "💻 VS Code:"
    echo "  Launch from Applications or run 'code' command"
    echo "  Install extensions: code --install-extension <extension-id>"
    echo ""

    log_info "🤖 Claude Code:"
    echo "  Configure with your API key if needed"
    echo ""

    log_info "📦 Managing Tools:"
    echo "  Update all: brew update && brew upgrade && brew upgrade --cask"
    echo "  List installed: brew bundle list"
    echo "  Cleanup: brew bundle cleanup"
    echo ""
}

###############################################################################
# Main Installation Flow
###############################################################################

main() {
    log_section "Developer Tools Installation Script"
    log_info "Using Homebrew Bundle for dependency management"
    echo ""

    check_macos
    install_homebrew
    update_homebrew
    install_from_brewfile

    log_section "Setup Complete!"
    log_success "Your developer environment is ready!"

    show_post_install_notes
}

# Run main function
main

exit 0
