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

## Approved
<!-- Approved tasks — IMPLEMENT THESE -->

### Quick Wins (shell script hardening)
- [ ] Add `set -uo pipefail` to scripts/docker-entrypoint.sh (line 3 - missing -u)
- [ ] Add `set -uo pipefail` to scripts/init-wizard.sh (line 5 - missing -u)
- [ ] Add `set -uo pipefail` to scripts/install-plugins.sh (line 4 - missing -u)
- [ ] Add `set -uo pipefail` to scripts/save-plugins.sh (line 3 - missing -u)
- [ ] Add `set -uo pipefail` to scripts/clip2docker.sh (line 8 - has -u but ensure consistency)

### Documentation fixes
- [ ] Fix README.md line 690 - incorrect workflow reference (should be release.yml not build-push.yml)
- [ ] Add Docker requirement notice to README troubleshooting section

## Need Approval
<!-- Proposals waiting for human approval — DO NOT IMPLEMENT -->

- Review docker-compose.yml cap_add list (lines 24-33) - extensive capabilities may not all be needed
- Dockerfile line 23-26 - dev user has passwordless sudo (acceptable for dev but worth confirming)
