#!/bin/sh
# PATH configuration for login shells (loaded via /etc/profile.d/)
export NVM_DIR="/home/dev/.nvm"
export PATH="/home/dev/.nvm/versions/node/v24.14.0/bin:/home/dev/bin:/home/dev/.local/bin:$PATH"

# Conditional paths for runtimes installed by init-wizard
[ -d /usr/local/go/bin ] && export PATH="/usr/local/go/bin:$PATH"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"

# Source cargo env if available
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
