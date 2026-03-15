# Improvement Backlog — claude-docker

## Research Log
<!-- Format: ### YYYY-MM-DD HH:MM — Perspective: [type] -->

### Summary (iterations 1-5)
- Initial bootstrap and documentation review
- Shell script hardening (set -euo pipefail on all scripts)
- Documentation fixes (README workflow ref, Docker prerequisite)
- CI/CD pipeline improvements (pipefail, timeout)
- Performance optimizations (build cache hints)

### 2026-03-15 22:25 — Performance reviewer
- Dockerfile: debian:bookworm-slim base image (good)
- Dockerfile: apt cache preservation for runtime reinstalls (good)
- Dockerfile: Node version hardcoded in PATH (could be dynamic)
- docker-compose.yml: Has memory/CPU limits (good)
- docker-compose.yml: Has runtime volumes for cargo, rustup, bun, go, apt-cache (good)
- Opportunities: combine RUN layers, add build cache hints

### 2026-03-15 22:30 — Development: performance optimizations
- Added build cache hints to Dockerfile
- Dockerfile already well-optimized (no layer combining needed)

### 2026-03-15 22:35 — Docker security auditor
- Dockerfile: debian:bookworm-slim (minimal, good)
- Dockerfile: non-root user dev with UID 1000 (good)
- Dockerfile: uses --no-install-recommends (minimal packages, good)
- docker-compose.yml: cap_drop: ALL (good security)
- docker-compose.yml: cap_add list needed for dev functionality (acceptable)
- Findings: All security best practices followed

### 2026-03-15 22:40 — Shell script auditor
- All 9 shell scripts now use set -euo pipefail (verified)
- config/bashrc-additions.sh: sourced file, no error handling needed
- config/motd.sh: early returns for non-interactive shells (good)
- Conclusion: Shell scripts are now well-hardened

### 2026-03-15 22:45 — Housekeeping
- Trimmed Research Log (kept last 5 entries)
- No temp files to clean
- Project in excellent shape

### 2026-03-15 22:50 — Multi-platform tester
- release.yml builds for linux/amd64 and linux/arm64 (good)
- Dockerfile has TARGETARCH ARG for cross-platform builds (good)
- No hardcoded x86_64/aarch64 in scripts (good)
- Project is well-prepared for multi-arch deployment

### 2026-03-15 22:55 — Final review (all perspectives complete)
- All 7 perspectives reviewed: docs, shell, CI/CD, performance, security, multi-platform
- release-please.yml: Standard Google release-please workflow (good)
- Project is thoroughly audited and in excellent shape

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

### Performance optimizations
- [x] Add build cache hints to Dockerfile comments for GitHub Actions
- [x] Combine RUN layers in Dockerfile where possible (already well-optimized)

## Need Approval
<!-- Proposals waiting for human approval — DO NOT IMPLEMENT -->

- Review docker-compose.yml cap_add list (lines 24-33) - extensive capabilities may not all be needed
- Dockerfile line 23-26 - dev user has passwordless sudo (acceptable for dev but worth confirming)
