#!/bin/bash
# Docker entrypoint for claude-docker
set -eo pipefail

# Source bashrc for PATH setup
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Auth persistence: CLAUDE_CONFIG_DIR=/home/dev/.claude (set in Dockerfile)
# makes Claude store ALL config inside ~/.claude/ which is on the Docker volume.
# No symlinks or file copying needed — everything persists naturally.

# Find the active config file (Claude checks .config.json first, then .claude.json)
CONFIG_FILE=""
if [ -f "$CLAUDE_CONFIG_DIR/.config.json" ]; then
    CONFIG_FILE="$CLAUDE_CONFIG_DIR/.config.json"
elif [ -f "$CLAUDE_CONFIG_DIR/.claude.json" ]; then
    CONFIG_FILE="$CLAUDE_CONFIG_DIR/.claude.json"
fi

# Clean up stale symlink/files from previous entrypoint versions
[ -L "$HOME/.claude.json" ] && rm -f "$HOME/.claude.json"
[ -f "$CLAUDE_CONFIG_DIR/claude.json" ] && rm -f "$CLAUDE_CONFIG_DIR/claude.json"

# Sync lastOnboardingVersion to prevent re-onboarding after Claude updates.
# Claude Code re-shows the welcome screen when the running version differs
# from lastOnboardingVersion in the config file.
if [ -n "$CONFIG_FILE" ]; then
    CLAUDE_VER=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [ -n "$CLAUDE_VER" ]; then
        STORED_VER=$(grep -o '"lastOnboardingVersion"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" 2>/dev/null | grep -o '[0-9][0-9.]*' || true)
        if [ -n "$STORED_VER" ] && [ "$STORED_VER" != "$CLAUDE_VER" ]; then
            sed -i "s/\"lastOnboardingVersion\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"lastOnboardingVersion\": \"$CLAUDE_VER\"/" "$CONFIG_FILE"
        fi
    fi
fi

# Ensure hooks configuration in settings.json (for existing volumes after rebuild)
SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ] && ! grep -q '"hooks"' "$SETTINGS_FILE" 2>/dev/null; then
    # Add hooks config before the closing brace
    HOOKS_JSON='  "hooks": {"PostToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "/usr/local/bin/post-plugin-save-hook", "timeout": 10}]}]}'
    sed -i '$s/}$/,\n'"$(echo "$HOOKS_JSON" | sed 's/[\/&]/\\&/g')"'\n}/' "$SETTINGS_FILE"
fi

# Configure git identity from env vars
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Clipboard backend setup (default: osc52, no action needed)
case "${CLIPBOARD_BACKEND:-osc52}" in
    x11)
        if [ -n "$DISPLAY" ] && [ -e "/tmp/.X11-unix/X${DISPLAY#*:}" ] 2>/dev/null; then
            if ! command -v xclip >/dev/null 2>&1; then
                echo "Installing xclip for X11 clipboard..."
                sudo apt-get update -qq && sudo apt-get install -y -qq xclip > /dev/null 2>&1
            fi
        else
            echo "Warning: CLIPBOARD_BACKEND=x11 but DISPLAY not set or X11 socket not mounted."
            echo "See docker-compose.x11.example.yml for setup instructions."
        fi
        ;;
    wayland)
        if [ -n "$WAYLAND_DISPLAY" ]; then
            if ! command -v wl-copy >/dev/null 2>&1; then
                echo "Installing wl-clipboard for Wayland..."
                sudo apt-get update -qq && sudo apt-get install -y -qq wl-clipboard > /dev/null 2>&1
            fi
        else
            echo "Warning: CLIPBOARD_BACKEND=wayland but WAYLAND_DISPLAY not set."
            echo "See docker-compose.wayland.example.yml for setup instructions."
        fi
        ;;
    osc52|"")
        # Default: tmux config handles everything via OSC 52
        ;;
    *)
        echo "Warning: Unknown CLIPBOARD_BACKEND='$CLIPBOARD_BACKEND'. Valid values: osc52, x11, wayland."
        echo "Falling back to osc52 (default)."
        ;;
esac

# GitHub CLI auth if token provided
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
fi

# Background claude-gc loop (every 15 minutes)
if command -v claude-gc >/dev/null 2>&1; then
    (
        while true; do
            sleep 900
            claude-gc --quiet 2>/dev/null || true
        done
    ) &
fi

# First run: interactive wizard
if [ ! -f "$HOME/.claude/.docker-init-done" ]; then
    if [ -t 0 ] && [ -t 1 ]; then
        # Interactive terminal - run wizard
        init-wizard
    fi
fi

# Reinstall check: volume persisted but container rebuilt
if [ -f "$HOME/.claude/.installed-packages.json" ] && [ -f "$HOME/.claude/.docker-init-done" ]; then
    # Quick check if reinstall is needed by looking for key binaries
    needs_reinstall=false

    # Check a few key packages from receipts
    if grep -q '"python"' "$HOME/.claude/.installed-packages.json" 2>/dev/null; then
        command -v python3 >/dev/null 2>&1 || needs_reinstall=true
    fi
    if grep -q '"go"' "$HOME/.claude/.installed-packages.json" 2>/dev/null; then
        command -v go >/dev/null 2>&1 || needs_reinstall=true
    fi
    if grep -q '"rust"' "$HOME/.claude/.installed-packages.json" 2>/dev/null; then
        command -v rustc >/dev/null 2>&1 || needs_reinstall=true
    fi
    if grep -q '"vim"' "$HOME/.claude/.installed-packages.json" 2>/dev/null; then
        command -v vim >/dev/null 2>&1 || needs_reinstall=true
    fi

    if [ "$needs_reinstall" = true ]; then
        echo "Detected missing packages, reinstalling in background..."
        echo "(Run 'tail -f /tmp/reinstall.log' to monitor progress)"
        init-wizard --silent > /tmp/reinstall.log 2>&1 &
    fi
fi

# Autostart mode: launch cl session manager
if [ "${CLAUDE_AUTOSTART:-0}" = "1" ]; then
    exec cl
fi

# Default: run provided command or bash
exec "$@"
