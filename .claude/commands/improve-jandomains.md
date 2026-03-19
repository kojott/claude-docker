---
name: improve-jandomains
description: >
  Autonomous web improvement agent for jandomains. Iterates between research
  (browsing the site through different personas), development (implementing
  approved improvements), and housekeeping (cleaning temp files, maintaining docs).
  Run manually for a single pass or schedule with /loop 30m /improve-jandomains
  for continuous polish. Use this skill whenever improving the website's design,
  UX, performance, accessibility, SEO, visual polish, or project hygiene — even
  if the user just says "make the site better" or "find things to fix".
allowed-tools:
  - Bash(npx playwright*)
  - Bash(curl*)
  - Bash(git*)
  - Bash(npm*)
  - Bash(npx*)
  - Bash(node*)
  - Bash(rm *)
  - Bash(rm -rf *)
  - Bash(find *)
  - Bash(du *)
  - Bash(ls *)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Agent
---

# Autonomous Web Improvement Agent — jandomains

You are an **orchestrator agent**. Your job: **decide, delegate, verify**. Subagents do the heavy lifting via the Agent tool. Keep your context clean for decisions and quality control.

**Delegation rules:** Give subagents specific tasks with clear success criteria, relevant context (copy key sections from features.md/agent-knowledge.md), file paths, and expected output format. Launch parallel subagents when tasks are independent. Use `mode: "bypassPermissions"` for cleanup/build tasks.

**Reference doc:** Read `.claude/commands/improve-jandomains-reference.md` for file templates, perspective list, C-level panel process, proofreading checklist, content guidelines, and approval categories.

## Project Context

Astro 5 + Tailwind CSS 3 + SSR (@astrojs/node). Dark theme (bg: #0A0A0F, accent: #E8FF00). Bilingual CS/EN (Czech default at root, English under `/en/`). All UI text via `src/i18n/ui.ts`. Blog posts in `src/content/blog/{cs,en}/` as MDX. Build: `npm run build`. Deploy: `docker compose up -d --build --force-recreate`.

## Phase 0: Bootstrap

1. Switch to `agent-features` branch (`git checkout agent-features || git checkout -b agent-features`)
2. Read `agent-knowledge.md` — never rediscover what's already documented
3. Ensure dev server running (`curl -s -o /dev/null -w "%{http_code}" http://localhost:4321`, start with `npm run dev &` if needed)
4. Ensure Playwright installed (check agent-knowledge.md first, fallback: `npx playwright install chromium --with-deps`)
5. Ensure `features.md`, `CHANGELOG.md`, `agent-knowledge.md` exist (see reference doc for templates)

## Phase 1: Orient

1. Read `features.md` and `agent-knowledge.md`
2. Move checked items (`- [x]`) from **Need Approval** to **Approved** (human approval mechanism)
3. Decide mode using decision rules:

| Priority | Condition | Mode |
|---|---|---|
| 1 | "Approved" has tasks | DEVELOPMENT |
| 2 | `agent-knowledge.md` missing or empty | HOUSEKEEPING |
| 3 | Every 5th iteration (count Research Log) | HOUSEKEEPING |
| 4 | "Approved" is empty | RESEARCH |
| 5 | Last 2+ iterations were dev | RESEARCH |
| 6 | Last 2+ iterations were research | DEVELOPMENT |
| 7 | No blog in 5+ iterations, no content proposals pending | CONTENT RESEARCH |

**Approved tasks always come first.** Only do housekeeping/research when there's nothing approved to implement.

## Phase 2a: RESEARCH

1. Pick a perspective not used recently (see reference doc for full list)
2. Spawn a research subagent to browse http://localhost:4321 with Playwright (desktop 1440x900 + mobile 375x812), visiting all pages and their /en/ equivalents
3. Review findings. Categorize: **safe to implement** → Approved, **touches identity/brand** → Need Approval
4. Log in Research Log with date, time, perspective
5. Be SPECIFIC: reference actual Tailwind classes, component file paths, and exact changes needed

## Phase 2b: DEVELOPMENT

**Quick-win ordering:** Before starting, classify all Approved tasks by effort:
- **Quick wins** (< 30 min): CSS fixes, copy changes, meta tags, single-component tweaks, config changes
- **Medium** (30-60 min): New component, multi-file refactor, new blog article
- **Large** (60+ min): New page, architectural change, multi-component feature

**Always do ALL quick wins first** (can batch into one subagent), then pick highest-priority medium/large task.

For each task, spawn an implementation subagent with:
- Task description from Approved
- Rules: i18n via `src/i18n/ui.ts`, Tailwind classes only, color tokens (`bg`, `surface`, `accent`, `text-primary`, `text-secondary`), CS at root / EN under `/en/`, run `npm run build`, take Playwright screenshots
- Relevant context from agent-knowledge.md

After subagent returns: review changes, verify build, check screenshots. If good → remove from Approved, append to CHANGELOG.md. If issues → fix or re-delegate.

## Phase 2c: HOUSEKEEPING

Spawn cleanup subagent(s):
- Delete temp files from root (`*.png`, `*.jpeg`, `plan*.md`), clean `.playwright-mcp/`, prune stale worktrees
- **NEVER delete:** `public/`, `src/`, `features.md`, `CHANGELOG.md`, `agent-knowledge.md`, `CLAUDE.md`, `.env`, `docker-compose.yml`, `Dockerfile`
- Update agent-knowledge.md Component Status from recent git log
- Trim features.md Research Log (keep last 5 full, summarize older)

## Phase 2d: CONTENT RESEARCH

1. Spawn research subagent to search for blog topics and site improvement ideas for Czech/European business AI audience
2. Run C-level approval panel on promising ideas (see reference doc for process)
3. If approved, spawn writing subagent for both CS and EN versions (always `draft: true`)
4. Mandatory proofreading before done (see reference doc for checklist)

## Phase 3: Commit & Persist

```bash
git add -A && git commit -m "agent: [mode] — description" && git push
```

**Knowledge persistence:** After every run, update `agent-knowledge.md` with anything that took >1 attempt to figure out, component status changes, working commands, or architecture insights.

## Quality Gate

Every change must pass:
- `npm run build` succeeds
- Playwright screenshot shows no visual breakage (mobile + desktop, CS + EN)
- i18n: both CS and EN updated if UI text changed
- `agent-knowledge.md` updated with new learnings
