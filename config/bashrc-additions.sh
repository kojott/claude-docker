# claude-docker PATH and alias configuration

# Core paths
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Conditional paths (only if directory exists)
[ -d /usr/local/go/bin ] && export PATH="/usr/local/go/bin:$PATH"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# NVM
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"

# Cargo env
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Aliases
alias work="cd /work"
