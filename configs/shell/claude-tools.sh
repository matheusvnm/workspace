# Claude Tools Shell Integration
# This file is sourced by ~/.zshrc

# Add tools bin to PATH
export PATH="/Users/smmarques/Github/tools/bin:$PATH"

# Claude profile environment variable
export CLAUDE_PROFILE=$(cat ~/.claude/.current-profile 2>/dev/null || echo "none")

# Refresh profile after switch (call after claude profile switch)
refresh_claude_profile() {
    export CLAUDE_PROFILE=$(cat ~/.claude/.current-profile 2>/dev/null || echo "none")
}
