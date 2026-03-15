# Improvement Backlog — claude-docker

## Research Log
<!-- Format: ### YYYY-MM-DD HH:MM — Perspective: [type] -->

### 2026-03-15 21:45 — Initial bootstrap
- Agent initialized with Docker-focused perspectives

### 2026-03-15 22:00 — Documentation reviewer
- Reviewed Dockerfile, docker-compose.yml, scripts/, config/, README, GitHub workflows
- Identified 20+ improvement opportunities
- Key findings: shell script hardening (set -u), documentation gaps, workflow fixes
- Full findings in research agent output

### 2026-03-15 22:05 — Development: shell script hardening
- Implemented set -euo pipefail on all 9 shell scripts
- Fixed: scripts/docker-entrypoint.sh, init-wizard.sh, install-plugins.sh, save-plugins.sh, clip2docker.sh, render-templates.sh, setup-claude-settings.sh, config/cl.sh, config/new-project.sh

### 2026-03-15 22:10 — Development: documentation fixes
- Fixed README.md workflow reference (build-push.yml → release.yml)
- Added Docker prerequisite notice to troubleshooting section

### 2026-03-15 22:15 — CI/CD pipeline auditor
- Reviewed .github/workflows/ci.yml and release.yml
- CI: Well-structured with smoke tests (UID, node, claude CLI, tools, config)
- Release: Multi-arch build (amd64, arm64) to ghcr.io
- Found: cache mode=max may be slow; could add build timeout
- Found: smoke tests could use set -o pipefail for better error handling

### 2026-03-15 22:20 — Development: CI/CD improvements
- Added set -o pipefail to smoke tests
- Added 30-minute timeout to CI job

## Approved
<!-- Approved tasks — IMPLEMENT THESE -->

### Quick Wins (shell script hardening)
- [x] Add `set -euo pipefail` to scripts/docker-entrypoint.sh (line 3)
- [x] Add `set -euo pipefail` to scripts/init-wizard.sh (line 5)
- [x] Add `set -euo pipefail` to scripts/install-plugins.sh (line 4)
- [x] Add `set -euo pipefail` to scripts/save-plugins.sh (line 3)
- [x] Add `set -euo pipefail` to scripts/clip2docker.sh (line 8)
- [x] Add `set -euo pipefail` to scripts/render-templates.sh (line 4)
- [x] Add `set -euo pipefail` to scripts/setup-claude-settings.sh (line 3)
- [x] Add `set -euo pipefail` to config/cl.sh (line 6)
- [x] Add `set -euo pipefail` to config/new-project.sh (line 4)

### Documentation fixes
- [x] Fix README.md line 690 - incorrect workflow reference (should be release.yml not build-push.yml)
- [x] Add Docker requirement notice to README troubleshooting section

### CI/CD improvements
- [x] Add `set -o pipefail` to CI smoke test script in .github/workflows/ci.yml (lines 32-62)
- [x] Add build-timeout to CI workflow to prevent hung builds (30 min)

## Need Approval
<!-- Proposals waiting for human approval — DO NOT IMPLEMENT -->

- Review docker-compose.yml cap_add list (lines 24-33) - extensive capabilities may not all be needed
- Dockerfile line 23-26 - dev user has passwordless sudo (acceptable for dev but worth confirming)
