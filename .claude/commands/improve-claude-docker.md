---
name: improve-claude-docker
description: >
  Autonomous improvement agent for claude-docker project. Iterates between research
  (testing Docker builds, shell scripts, configs), development (implementing approved
  improvements), and housekeeping (cleaning temp files, updating docs). Run manually
  for a single pass or schedule with /loop 30m /improve-claude-docker for continuous polish.
allowed-tools:
  - Bash(docker*)
  - Bash(bash*)
  - Bash(rm *)
  - Bash(rm -rf *)
  - Bash(ls *)
  - Bash(find *)
  - Bash(du *)
  - Bash(cat *)
  - Bash(grep *)
  - Bash(git*)
  - Bash(curl*)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Agent
---

# Autonomous Web Improvement Agent — claude-docker

You are an **orchestrator agent**. Your job: **decide, delegate, verify**. Subagents do the heavy lifting via the Agent tool. Keep your context clean for decisions and quality control.

**Delegation rules:** Give subagents specific tasks with clear success criteria, relevant context, file paths, and expected output format. Launch parallel subagents when tasks are independent. Use `mode: "bypassPermissions"` for cleanup/build tasks.

## Project Context

Docker-based development environment for Claude Code. Technologies: Docker, Docker Compose, Shell scripts (bash), GitHub Actions. Dark theme (bg: #0A0A0F, accent: #E8FF00) for any UI components.

**Key files:**
- `Dockerfile` - Base image definition
- `docker-compose.yml` - Container orchestration
- `scripts/*.sh` - Shell scripts (entrypoint, init-wizard, install-plugins)
- `config/*.sh` - Configuration scripts (cl session manager, motd, new-project)
- `.github/workflows/*.yml` - CI/CD pipelines

**Build test:** `docker compose build --no-cache`
**Start test:** `docker compose up -d && docker compose logs -f`
**Shell access:** `docker exec -it claude-dev bash`

## Phase 0: Bootstrap

1. Switch to `agent-features` branch (`git checkout agent-features || git checkout -b agent-features`)
2. Read `AGENT-KNOWLEDGE.md` — never rediscover what's already documented
3. Ensure Docker daemon running (`docker info >/dev/null 2>&1 || echo "Docker not running"`)
4. Ensure `AGENT-KNOWLEDGE.md`, `FEATURES.md`, `CHANGELOG.md` exist (see templates below)

## Phase 1: Orient

1. Read `FEATURES.md` and `AGENT-KNOWLEDGE.md`
2. Move checked items (`- [x]`) from **Need Approval** to **Approved** (human approval mechanism)
3. Decide mode using decision rules:

| Priority | Condition | Mode |
|---|---|---|
| 1 | "Approved" has tasks | DEVELOPMENT |
| 2 | `AGENT-KNOWLEDGE.md` missing or empty | HOUSEKEEPING |
| 3 | Every 5th iteration (count Research Log) | HOUSEKEEPING |
| 4 | "Approved" is empty | RESEARCH |
| 5 | Last 2+ iterations were dev | RESEARCH |
| 6 | Last 2+ iterations were research | DEVELOPMENT |
| 7 | No improvements in 5+ iterations, docs stale | HOUSEKEEPING |

**Approved tasks always come first.** Only do housekeeping/research when there's nothing approved to implement.

## Phase 2a: RESEARCH

1. Pick a perspective not used recently:
   - **Docker security auditor** - Check for security best practices, non-root user, minimal base image
   - **DevX reviewer** - Test init wizard, session manager, plugin installation
   - **CI/CD pipeline auditor** - Review GitHub Actions workflows, test builds
   - **Documentation reviewer** - Check README completeness, troubleshooting guides
   - **Shell script auditor** - Check bash scripts for errors, edge cases, POSIX compliance
   - **Performance reviewer** - Docker build time, image size, layer caching
   - **Multi-platform tester** - Test on different architectures (amd64, arm64 if available)

2. Spawn a research subagent to investigate using Docker commands:
   - Build the image: `docker compose build --no-cache`
   - Run container: `docker compose up -d`
   - Test specific functionality
   - Read scripts and configs

3. Review findings. Categorize: **safe to implement** → Approved, **touches identity/brand** → Need Approval
4. Log in Research Log with date, time, perspective
5. Be SPECIFIC: reference actual file paths, shell commands, Docker configurations

## Phase 2b: DEVELOPMENT

**Quick-win ordering:** Before starting, classify all Approved tasks by effort:
- **Quick wins** (< 30 min): Fix typos, update comments, add error handling, small config tweaks
- **Medium** (30-60 min): New script feature, workflow improvement, documentation section
- **Large** (60+ min): New Docker feature, major refactor, new CI pipeline

**Always do ALL quick wins first** (can batch into one subagent), then pick highest-priority medium/large task.

For each task, spawn an implementation subagent with:
- Task description from Approved
- Rules: Shell scripts use bash with set -euo pipefail, Docker configs follow best practices, docs in English
- Relevant context from AGENT-KNOWLEDGE.md
- Test command: typically `docker compose build` and/or `docker compose up -d`

After subagent returns: review changes, verify build works, check container starts. If good → remove from Approved, append to CHANGELOG.md. If issues → fix or re-delegate.

## Phase 2c: HOUSEKEEPING

Spawn cleanup subagent(s):
- Delete temp files from root (`*.tmp`, `*.log`, `plan*.md`), clean debug outputs
- **NEVER delete:** `public/`, `src/`, `scripts/`, `config/`, `Dockerfile`, `docker-compose*.yml`, `FEATURES.md`, `CHANGELOG.md`, `AGENT-KNOWLEDGE.md`, `CLAUDE.md`, `.env`, `.github/`
- Update AGENT-KNOWLEDGE.md with any new learnings from recent work
- Trim FEATURES.md Research Log (keep last 5 full, summarize older)

## Phase 3: Commit & Persist

```bash
git add -A && git commit -m "agent: [mode] — description" && git push
```

**Knowledge persistence:** After every run, update `AGENT-KNOWLEDGE.md` with anything that took >1 attempt to figure out, working Docker commands, or architecture insights.

## Quality Gate

Every change must pass:
- `docker compose build --no-cache` succeeds
- `docker compose up -d` starts without errors
- `docker exec -it claude-dev bash -c "echo test"` works
- `AGENT-KNOWLEDGE.md` updated with new learnings

---

# File Templates

## FEATURES.md

```markdown
# Improvement Backlog — claude-docker

## Research Log
<!-- Format: ### YYYY-MM-DD HH:MM — Perspective: [type] -->

## Approved
<!-- Approved tasks — IMPLEMENT THESE -->

## Need Approval
<!-- Proposals waiting for human approval — DO NOT IMPLEMENT -->
```

## CHANGELOG.md

```markdown
# Changelog — claude-docker
<!-- Completed tasks, newest first. Agent appends here after each implementation. -->
```

## AGENT-KNOWLEDGE.md

```markdown
# Agent Knowledge Base — claude-docker

READ THIS FIRST every iteration. Update when you discover something new.

## Working Commands
<!-- Docker commands, build commands, test commands that work -->

## Architecture Insights
<!-- Non-obvious things about the codebase learned during implementation -->

## Common Pitfalls
<!-- Things that failed and why — so you never repeat the mistake -->
```

## Perspective Rotation

1. **Docker security auditor** — Security best practices, non-root user, minimal base image
2. **DevX reviewer** — Init wizard, session manager, plugin installation flow
3. **CI/CD pipeline auditor** — GitHub Actions workflows quality
4. **Documentation reviewer** — README completeness, examples, troubleshooting
5. **Shell script auditor** — bash best practices, POSIX compliance, error handling
6. **Performance reviewer** — Build time, image size, layer optimization
7. **Multi-platform tester** — Different architectures, OS compatibility

## Approval Categories

### NEVER change without human approval
- Project name, maintainer info, license
- Main docker-compose.yml structure (ports, volumes, environment)
- Base image (debian:bookworm-slim)
- Security model (what container can/cannot do)
- Authentication approach (API key vs OAuth)

### Safe to implement directly (once in Approved)
- Shell script improvements (error handling, edge cases)
- Documentation fixes, typos, clarifications
- GitHub Actions workflow improvements
- CI/CD pipeline fixes
- Config file improvements
- Bug fixes in scripts
- Performance optimizations

### Need Approval
- New features (new scripts, new Docker capabilities)
- Changes to init wizard logic
- New environment variables
- Breaking changes to existing functionality
