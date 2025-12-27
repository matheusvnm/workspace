#!/bin/bash
###############################################################################
# Developer Tools Installation Script for macOS
#
# This script orchestrates all setup scripts for a fresh macOS installation.
# It's idempotent - safe to run multiple times.
###############################################################################

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
# Pre-flight Checks
###############################################################################

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only."
        log_error "Detected OS: $OSTYPE"
        exit 1
    fi
    log_success "Running on macOS ($(sw_vers -productVersion))"
}

###############################################################################
# Main
###############################################################################

main() {
    log_section "Developer Tools Installation Script"
    log_info "Setting up your macOS development environment"
    echo ""

    check_macos

    # Run each installer in order
    log_section "Step 1: Homebrew & Dependencies"
    "$SCRIPT_DIR/scripts/install-brew.sh"

    log_section "Step 2: Shell Integration"
    "$SCRIPT_DIR/scripts/install-shell.sh"

    log_section "Step 3: Starship Prompt"
    "$SCRIPT_DIR/scripts/install-starship.sh"

    log_section "Step 4: Claude Profiles"
    "$SCRIPT_DIR/scripts/install-claude-profile.sh"

    log_section "Setup Complete!"
    log_success "Your developer environment is ready!"
    echo ""
    log_info "Restart your terminal or run: source ~/.zshrc"
    log_info "Then try: claude profile list"
}

main
exit 0
