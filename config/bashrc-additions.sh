# claude-docker PATH and alias configuration

# Core paths
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Conditional paths (only if directory exists)
[ -d "$HOME/.iterm2" ] && export PATH="$HOME/.iterm2:$PATH"
[ -d /usr/local/go/bin ] && export PATH="/usr/local/go/bin:$PATH"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# NVM
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"

# Cargo env
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# iTerm2 shell integration (enables imgcat, image paste, drag & drop)
# ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX is required — without it,
# the script detects TERM=screen* inside tmux and exits early.
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# Aliases
alias work="cd /work"

# First-run wizard trigger (entrypoint may not run interactively)
if [ ! -f "$HOME/.claude/.docker-init-done" ] && [ -t 0 ] && [ -t 1 ]; then
    init-wizard
fi
