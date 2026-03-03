# CI Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up CI pipeline with smoke tests, release-please versioning, and multi-arch release builds to ghcr.io.

**Architecture:** Three separate GitHub Actions workflows — ci.yml for build+test on every push/PR, release-please.yml for automated versioning via Conventional Commits, and release.yml for multi-arch image builds on tag push. release-please uses `simple` release-type with `version.txt` as the version source of truth.

**Tech Stack:** GitHub Actions, Docker Buildx, QEMU, release-please-action v4, ghcr.io

---

### Task 1: Create release-please config files

**Files:**
- Create: `release-please-config.json`
- Create: `.release-please-manifest.json`
- Create: `version.txt`

**Step 1: Create version.txt with initial version**

```
1.0.0
```

This is the source of truth for release-please `simple` release-type.

**Step 2: Create release-please-config.json**

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "simple",
      "changelog-path": "CHANGELOG.md",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true
    }
  }
}
```

- `simple` release-type: updates `version.txt` and `CHANGELOG.md`
- `bump-minor-pre-major` / `bump-patch-for-minor-pre-major`: while on 1.x, breaking changes bump minor, not major (safer for early project)

**Step 3: Create .release-please-manifest.json**

```json
{
  ".": "1.0.0"
}
```

This tells release-please the current version. Must match `version.txt`.

**Step 4: Commit**

```bash
git add version.txt release-please-config.json .release-please-manifest.json
git commit -m "chore: add release-please config and version tracking"
```

---

### Task 2: Create CI workflow

**Files:**
- Create: `.github/workflows/ci.yml`

**Step 1: Write ci.yml**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build image
        uses: docker/build-push-action@v6
        with:
          context: .
          load: true
          tags: claude-docker:test
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Smoke tests
        run: |
          echo "=== Running smoke tests ==="

          # Test: dev user exists with UID 1000
          uid=$(docker run --rm claude-docker:test id -u dev)
          [ "$uid" = "1000" ] && echo "PASS: dev user UID is 1000" || { echo "FAIL: dev user UID is $uid"; exit 1; }

          # Test: node is available
          docker run --rm claude-docker:test bash -lc "node --version" | grep -q "^v" \
            && echo "PASS: node is available" || { echo "FAIL: node not found"; exit 1; }

          # Test: claude CLI is available
          docker run --rm claude-docker:test bash -lc "claude --version" | grep -q "." \
            && echo "PASS: claude CLI is available" || { echo "FAIL: claude CLI not found"; exit 1; }

          # Test: essential tools available
          for tool in git tmux curl; do
            docker run --rm claude-docker:test which $tool > /dev/null \
              && echo "PASS: $tool is available" || { echo "FAIL: $tool not found"; exit 1; }
          done

          # Test: CLAUDE_CONFIG_DIR is set correctly
          config_dir=$(docker run --rm claude-docker:test bash -lc 'echo $CLAUDE_CONFIG_DIR')
          [ "$config_dir" = "/home/dev/.claude" ] \
            && echo "PASS: CLAUDE_CONFIG_DIR is set" || { echo "FAIL: CLAUDE_CONFIG_DIR is '$config_dir'"; exit 1; }

          # Test: entrypoint exists and is executable
          docker run --rm claude-docker:test test -x /usr/local/bin/docker-entrypoint.sh \
            && echo "PASS: entrypoint is executable" || { echo "FAIL: entrypoint not executable"; exit 1; }

          echo "=== All smoke tests passed ==="
```

Key decisions:
- `load: true` loads image into docker daemon (needed for `docker run`)
- No QEMU/multi-arch — native arch only for fast CI
- Each test is independent — clear PASS/FAIL output
- `bash -lc` for commands that need PATH from login shell (node, claude)

**Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add CI workflow with build and smoke tests"
```

---

### Task 3: Create release-please workflow

**Files:**
- Create: `.github/workflows/release-please.yml`

**Step 1: Write release-please.yml**

```yaml
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

That's it. release-please reads `release-please-config.json` and `.release-please-manifest.json` automatically from the repo root. No need to specify `release-type` — it's in the config file.

**Step 2: Commit**

```bash
git add .github/workflows/release-please.yml
git commit -m "ci: add release-please workflow for automated versioning"
```

---

### Task 4: Rename and update release workflow

**Files:**
- Delete: `.github/workflows/build-push.yml`
- Create: `.github/workflows/release.yml`

**Step 1: Delete old workflow, create release.yml**

Delete `.github/workflows/build-push.yml` and create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

This is the same as the old `build-push.yml` — just renamed for clarity.

**Step 2: Commit**

```bash
git rm .github/workflows/build-push.yml
git add .github/workflows/release.yml
git commit -m "ci: rename build-push to release workflow"
```

---

### Task 5: Test CI locally

**Step 1: Build the image locally to verify Dockerfile builds**

```bash
docker build -t claude-docker:test .
```

Expected: successful build.

**Step 2: Run smoke tests locally**

```bash
# dev user UID
docker run --rm claude-docker:test id -u dev
# Expected: 1000

# node
docker run --rm claude-docker:test bash -lc "node --version"
# Expected: v24.x.x

# claude
docker run --rm claude-docker:test bash -lc "claude --version"
# Expected: version string

# tools
docker run --rm claude-docker:test which git tmux curl
# Expected: paths

# CLAUDE_CONFIG_DIR
docker run --rm claude-docker:test bash -lc 'echo $CLAUDE_CONFIG_DIR'
# Expected: /home/dev/.claude

# entrypoint
docker run --rm claude-docker:test test -x /usr/local/bin/docker-entrypoint.sh && echo OK
# Expected: OK
```

**Step 3: If any test fails, fix the issue and re-test**

---

### Task 6: Validate workflow YAML syntax

**Step 1: Install actionlint if available, or validate manually**

```bash
# Quick YAML syntax check — make sure no parse errors
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))"
```

Expected: no output (no errors).

**Step 2: Validate JSON configs**

```bash
python3 -c "import json; json.load(open('release-please-config.json'))"
python3 -c "import json; json.load(open('.release-please-manifest.json'))"
```

Expected: no output (no errors).

---

### Task 7: Push and verify CI runs on GitHub

**Step 1: Push all changes to main**

```bash
git push origin main
```

**Step 2: Check CI workflow ran successfully**

```bash
gh run list --workflow=ci.yml --limit=1
gh run view <run-id>
```

Expected: CI workflow triggered, build succeeded, smoke tests passed.

**Step 3: Check release-please created a Release PR**

```bash
gh pr list --label "autorelease: pending"
```

Expected: A new PR titled something like "chore(main): release 1.0.1" with CHANGELOG updates.

**Step 4: If CI fails, investigate logs, fix, and push again**

```bash
gh run view <run-id> --log-failed
```
