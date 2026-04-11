# claude-docker

Secure Docker sandbox for running Claude Code in YOLO mode. Debian-based image with interactive init wizard for runtimes, tools, and Claude plugins.

## Quick Reference

```bash
# Build
docker compose build                    # standard build
docker compose build --no-cache         # clean rebuild

# Single instance
docker compose up -d                    # start
docker exec -it claude-dev bash         # connect
docker compose down                     # stop (volumes kept)

# Multi-instance (any folder)
./claude.sh ~/projects/my-app           # Anthropic API
./minimax.sh ~/projects/my-app          # MiniMax API
./claude.sh list                        # running instances
./claude.sh stop ~/projects/my-app      # stop instance

# Smoke test (local)
docker build -t claude-docker:test .
docker run --rm claude-docker:test id -u dev              # expect: 1000
docker run --rm claude-docker:test bash -lc "node --version"
docker run --rm claude-docker:test bash -lc "claude --version"
```

## Architecture

```
Dockerfile                    Base image (debian:bookworm-slim + NVM + Node 24 + Claude CLI)
docker-compose.yml            Single-instance orchestration
docker-compose.minimax.yml    MiniMax API variant
claude.sh / minimax.sh        Multi-instance launchers

scripts/
  docker-entrypoint.sh        Container startup (auth, git, gc loop, wizard trigger)
  init-wizard.sh              Interactive TUI for package selection
  install-plugins.sh          Claude plugin installer
  save-plugins.sh             Plugin receipt persistence
  clip2docker.sh              macOS clipboard image to container
  setup-claude-settings.sh    Base Claude settings writer

config/
  cl.sh                       Tmux session manager
  new-project.sh              Project scaffolder
  motd.sh                     Login message (active sessions)
  bashrc-additions.sh         Shell PATH and aliases (sourced, no error handling)
  profile-path.sh             Login shell PATH
  tmux-cl.conf                Tmux config for cl sessions
```

## Conventions

### Shell scripts
- Shebang: `#!/bin/bash` (container scripts) or `#!/usr/bin/env bash` (host launchers)
- All scripts use `set -euo pipefail` (except `bashrc-additions.sh` which is sourced)
- Header comment: script name, purpose, usage
- Constants: `readonly UPPERCASE_NAME="value"`
- Colors: ANSI escapes as readonly variables
- NVM sourcing: `[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"`
- Script dir: `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`
- No external dependencies beyond standard Unix tools

### Docker
- Base: `debian:bookworm-slim` (do not change)
- Non-root user: `dev` (UID 1000)
- Security: `cap_drop: ALL` + minimal `cap_add`
- `CLAUDE_CONFIG_DIR=/home/dev/.claude` — all Claude state on persistent volume
- Named volumes for caches: cargo, rustup, bun, go, apt-cache
- Container name parameterized via `${CONTAINER_NAME:-...}` for multi-instance

### Git
- Branch: `main` (CI/CD target), `agent-features` (development)
- Conventional Commits required: `fix:`, `feat:`, `feat!:`
- Tags `v*` trigger multi-arch release builds to ghcr.io
- release-please manages versioning and CHANGELOG

## Verification

After any change, verify:

```bash
docker compose build                                        # image builds
docker compose up -d && docker compose logs --tail=20       # starts clean
docker exec -it claude-dev bash -c "echo ok"                # shell works
```

CI smoke tests (`.github/workflows/ci.yml`) check: dev user UID, node, claude CLI, git/tmux/curl, CLAUDE_CONFIG_DIR, entrypoint executable.

## Deep Dive (read on demand)
- [Full user documentation](README.md) — installation, config, auth, wizard, session manager, troubleshooting
- [Improvement backlog](FEATURES.md) — research log, approved/pending tasks
- [CI pipeline design](docs/plans/2026-03-03-ci-pipeline-design.md) — why 3 separate workflows
- [CI implementation plan](docs/plans/2026-03-03-ci-pipeline-plan.md) — step-by-step (completed)

## Learnings
<!-- Add non-obvious discoveries from PR reviews and debugging here -->

## Gotchas
- `bashrc-additions.sh` is sourced (not executed) — no `set -euo pipefail`
- Rebuild preserves volumes but reinstalls packages from receipts in background — check `/tmp/reinstall.log`
- `docker compose down -v` deletes auth — use `down` without `-v` to keep credentials
- The `dev` user has passwordless sudo — intentional for dev container, not a bug
