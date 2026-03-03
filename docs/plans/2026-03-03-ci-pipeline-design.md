# CI Pipeline Design

## Goal

Set up CI pipeline that builds multi-arch (amd64+arm64) image to ghcr.io, runs smoke tests on every push/PR, and automates versioning via Conventional Commits + release-please.

## Workflow Structure: 3 Files

### 1. `.github/workflows/ci.yml` — Continuous Integration

- **Trigger:** push to main, PR to main
- Build image (native arch only, no push) — fast feedback
- Run smoke tests in container:
  - `dev` user exists with UID 1000
  - `node --version` works
  - `claude --version` works
  - `git`, `tmux`, `curl` available
  - `CLAUDE_CONFIG_DIR` set to `/home/dev/.claude`
  - entrypoint script exists and is executable

### 2. `.github/workflows/release.yml` — Release Build + Push

- **Trigger:** tag push `v*` (created by release-please), `workflow_dispatch`
- Multi-arch build (linux/amd64, linux/arm64) via buildx + QEMU
- Push to ghcr.io with semver tags
- GitHub Actions cache (type=gha)
- Replaces existing `build-push.yml`

### 3. `.github/workflows/release-please.yml` — Automated Versioning

- **Trigger:** push to main
- Uses `google-github-actions/release-please-action@v4`
- Analyzes conventional commits to determine version bump:
  - `fix:` → patch (1.0.x)
  - `feat:` → minor (1.x.0)
  - `feat!:` or `BREAKING CHANGE:` → major (x.0.0)
- Creates/updates a Release PR with CHANGELOG
- On merge of Release PR → creates git tag + GitHub Release

## End-to-End Flow

```
Developer commits with conventional prefix (fix:/feat:/feat!:)
  → push to main
    → ci.yml: build + smoke tests (fast, native arch)
    → release-please.yml: creates/updates Release PR with CHANGELOG

Maintainer merges Release PR
  → push to main
    → release-please.yml: creates tag v1.2.3 + GitHub Release
    → tag v1.2.3 triggers release.yml: multi-arch build + push to ghcr.io
```

## Image Tags

```
ghcr.io/kojott/claude-docker:1.2.3    (exact version)
ghcr.io/kojott/claude-docker:1.2      (minor)
ghcr.io/kojott/claude-docker:latest   (default branch only)
```

## Registry

- ghcr.io (GitHub Container Registry)
- Auth via `GITHUB_TOKEN` (no additional secrets needed)

## Decisions

- **3 separate workflows** instead of 1 monolith — clear separation of concerns
- **Native arch only for CI** — multi-arch via QEMU is slow, CI needs fast feedback
- **Smoke tests inline** — no separate test script file, keeps it simple
- **release-please over semantic-release** — no npm dependency, native GitHub Action, creates reviewable Release PRs
