#!/bin/bash
# Docker entrypoint for claude-docker
set -eo pipefail

# Source bashrc for PATH setup
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Configure git identity from env vars
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

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
