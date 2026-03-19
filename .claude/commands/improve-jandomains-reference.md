# improve-jandomains Reference

Detailed templates, checklists, and processes for the autonomous improvement agent.

## File Templates

### `features.md`

```markdown
# Web Improvement Backlog — jandomains

## Research Log
<!-- Format: ### YYYY-MM-DD HH:MM — Perspective: [user type] -->

## Approved
<!-- Approved tasks — IMPLEMENT THESE -->

## Need Approval
<!-- Proposals waiting for human approval — DO NOT IMPLEMENT -->
```

### `CHANGELOG.md`

```markdown
# Changelog — jandomains
<!-- Completed tasks, newest first. Agent appends here after each implementation. -->
```

### `agent-knowledge.md`

```markdown
# Agent Knowledge Base — jandomains

READ THIS FIRST every iteration. Update when you discover something new.

## Environment & Tools
<!-- Working commands, paths, versions — things that took trial and error to find -->

## Architecture Insights
<!-- Non-obvious things about the codebase learned during implementation -->

## Common Pitfalls
<!-- Things that failed and why — so you never repeat the mistake -->

## Component Status
<!-- Format: Component — status (done/needs-work) — last checked date — notes -->
```

## Perspective Rotation

Cycle through these (never repeat same one twice in a row):

1. **First-time visitor** — 3-second test: who is Jiri, what does he offer?
2. **Potential client (HR/L&D)** — Proof of quality: case studies, testimonials, workshop descriptions
3. **Technical auditor** — Lighthouse, Core Web Vitals, semantic HTML, Astro best practices
4. **Mobile user** — Everything at 375px: touch targets, readability, scroll
5. **Design critic** — Typography, whitespace, color harmony (#0A0A0F + #E8FF00), micro-interactions
6. **Competitive analyst** — Compare to top AI consultants' sites
7. **Power user** — Keyboard nav, dark mode contrast, speed, attention to detail
8. **Accessibility auditor** — Screen reader, contrast (yellow-on-dark), focus states, ARIA
9. **Content strategist** — Copy quality, CTA clarity, storytelling, CS vs EN consistency
10. **International visitor** — Does EN feel native? Translations complete?
11. **Innovation scout** — Web search for cool features, Astro plugins, UX patterns for consultant/developer blogs

## C-Level Approval Panel

For content/feature proposals, spawn **one subagent per persona** (parallel):

**Personas and evaluation criteria:**
- **CEO:** Strategic positioning? Would I share with my board?
- **CTO:** Helps team work with AI? Technically credible?
- **CFO:** Measurable ROI? Justifies AI investment?
- **CHRO/CPO:** Team transformation? Hiring/skills/culture?
- **COO:** Improves operations? Efficiency gains?

Each returns: APPROVE / NEUTRAL / REJECT with 2-3 sentence reasoning.

**Rules:**
- 2+ APPROVE (no REJECT) → **Approved**
- 1 APPROVE + rest NEUTRAL → **Approved** (lower priority)
- Any REJECT → **Need Approval** for human review
- All NEUTRAL → drop it

## Blog Proofreading Checklist

### Language & Grammar
- Spelling, typos, missing diacritics (CS)
- Grammar (subject-verb agreement, tense consistency)
- **CS-specific:** tykání consistency ("ty" form), Czech quotes „…", preposition mutations (k→ke, s→se, z→ze, v→ve), loanword declension, gender agreement with "AI" (neuter: "AI dokázalo")
- **EN-specific:** natural English (not translationese), consistent spelling variant

### Factual Accuracy
- Statistics consistent across articles
- Company/product names correct
- Dates and figures plausible

### Technical Correctness
- MDX syntax valid (no unclosed tags, correct imports)
- Component props: `TLDRBox` needs `title`, `Callout` needs `type` ("tip"/"warning"), `PullQuote` has no required props
- Internal link slugs match existing files
- External links plausible

### Frontmatter
- `lang` matches directory (cs/en)
- `translationSlug` matches paired article filename
- `draft: true` is set
- `tags` consistent with existing taxonomy
- `description` under 160 chars

### Tone & Style
- CS: Jiri's voice — direct, practitioner, light humor, no corporate speak
- EN: natural rewrite, not literal translation
- Short paragraphs, scannable structure

### Analytics of web visitors
- all can be found here: https://t.swingingdogs.com/share/jandomains?auth=PGl-ZhcyVcMgQ7JMtTvFO 

## Content Direction Guidelines

**Good ideas** move the needle:
- Drive traffic (SEO, shareable, answers real search queries)
- Build authority (backed by data, shows expertise)
- Support sales (address objections, show ROI, help readers convince their boss)
- Help readers/attendees (practical advice, tools, templates, checklists)
- Create reusable value (resources people bookmark — calculators, cheat sheets, frameworks)

**Avoid:**
- Generic "what is AI" explainers
- Pure hype without substance
- Topics without Jiri's credible angle
- Too technical for target audience (managers, not developers)
- Rehashes of existing articles
- Features that add complexity without clear user value

## Approval Categories

### NEVER change without human approval
- Name, bio, contact details, personal information
- Main navigation structure (Header/Footer link targets)
- Brand colors (#0A0A0F, #E8FF00), logo, visual identity
- Removal of existing published content or pages
- Domain, routing, deployment, Docker configuration
- i18n route structure (CS at root, EN under `/en/`)
- API endpoints or webhook integrations
- Lead magnet funnel (ai-tahak, bonus pages)

### C-level panel can approve
- New blog articles (`draft: true`), tools/resources, blog features
- Interactive elements (calculators, checklists, quizzes)
- New components enhancing existing pages
- Content improvements (better CTAs, clearer copy)

### Safe to implement directly (once in Approved)
- CSS polish, performance, accessibility, SEO meta
- Bug fixes, responsive improvements, loading states
- Code cleanup within existing components
- Deleting temp/debug files, updating documentation
- Draft blog articles (`draft: true`)
