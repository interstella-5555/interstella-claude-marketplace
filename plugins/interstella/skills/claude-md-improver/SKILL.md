---
name: claude-md-improver
description: Use when user asks to "optimize claude.md", "clean up claude.md", "review claude.md", "make claude.md shorter", "audit claude.md", or "/x-claude-md-improver".
---

# X-Claude-MD-Improver

Enhanced CLAUDE.md auditor. Combines `claude-md-management:claude-md-improver` quality scoring with aggressive signal-to-noise optimization, framework-aware auditing, and verified Anthropic knowledge sources.

**Announce at start:** "Using x-claude-md-improver — enhanced CLAUDE.md optimization with framework-aware auditing."

## Workflow

1. **Read `claude-md-management:claude-md-improver`** for quality assessment methodology (scoring rubric, templates, update guidelines)
2. **Then follow this skill's enhanced process** (below) for aggressive optimization
3. **Validate** using both quality score AND line count

## Enhanced Process

### Phase 1: Discovery

Find all CLAUDE.md files in scope:
- Project root `./CLAUDE.md`
- Parent directories (workspace-level)
- User global `~/.claude/CLAUDE.md`
- Subdirectory/package-level files
- `.claude/rules/*.md` files

Read project configs (`package.json`, `turbo.json`, `tsconfig.json`, framework configs) to understand what Claude can infer from the codebase without CLAUDE.md telling it.

Count total lines across all files that load at startup. See `references/line-budget.md` for budget math.

### Phase 2: Classify Every Line

For every line, ask: **"Would removing this cause Claude to make mistakes?"** If not, cut it.

| Category | Criteria | Examples |
|---|---|---|
| **KEEP** | Claude would get this wrong without it | Non-obvious commands, gotchas that break builds, style rules deviating from defaults, workflow rules Claude can't infer |
| **CUT** | Claude can figure it out from code/tools | Directory trees, standard framework patterns, architecture docs, code examples, config values, obvious conventions |
| **MOVE** | Valid but belongs elsewhere | Path-specific rules → `.claude/rules/*.md`, framework details → `references/`, task workflows → skills |
| **CONDENSE** | Useful but too verbose | Multi-line explanations → single line, redundant examples → one example |

### Phase 3: Framework-Aware Audit

Detect project type and flag over-documentation:

**Next.js / App Router:**
- CUT: App Router file conventions, server/client component explanation, metadata API docs
- KEEP: Custom middleware gotchas, non-standard routing, critical import restrictions

**Monorepo (Turborepo/Nx):**
- CUT: Package dependency graph (inferable from package.json), workspace structure tree
- KEEP: Cross-package import rules, build order gotchas, workspace-specific commands

**Expo / React Native:**
- CUT: Standard Expo commands, Metro bundler config, EAS build basics
- KEEP: Platform-specific gotchas, native module quirks, OTA update restrictions

**TanStack (Start/Router/Query):**
- CUT: Standard TanStack patterns, loader/action setup, query key conventions
- KEEP: Custom integrations, non-standard configurations, migration-specific issues

**Detection method:**
1. Detect package manager from lockfile
2. Find workspace config (`workspaces` in package.json, `pnpm-workspace.yaml`)
3. Resolve workspace globs to find all package.json files
4. Read each workspace's package.json to detect framework dependencies

### Phase 4: Present Report

Show a table for each CLAUDE.md file:

```
## {file path} — {current lines} lines

| Line(s) | Category | Content summary | Reason |
|---------|----------|-----------------|--------|
| 9-26    | CUT      | Monorepo structure tree | `ls` |
| 137-144 | KEEP     | SwapKit import rules | Build-breaking gotcha |
| 181-238 | CUT      | Wallet system architecture | Readable from code |

Projected: {current} → {projected} lines ({cut count} lines removed)
```

Also run the `claude-md-management:claude-md-improver` quality assessment to generate a quality score (A-F). Present both: line reduction AND quality score.

### Phase 5: Interactive Approval

Walk through each section with the user one by one:
- Current content (abbreviated)
- Proposed action (KEEP/CUT/MOVE/CONDENSE)
- Reason

Wait for user to approve or reject each before moving on.

### Phase 6: Rewrite

After approval, rewrite following these formatting rules:
- **Dense over verbose** — one line per rule when possible
- **Group by concern** — commands, gotchas, code style, workflow
- **Imperative mood** — "Use X" not "You should use X"
- **No code examples unless the rule IS the example**
- **No "Benefits:" or "Why:" sections** unless the WHY is non-obvious
- **Flat heading hierarchy** — `##`, not deeply nested
- **CRITICAL / NEVER / MUST for hard rules** — use sparingly, only for build-breaking gotchas

### Phase 7: Validate

1. Count lines — target under 200 per file
2. Re-run "would removing this cause mistakes?" on each remaining line
3. Check no critical rules were accidentally cut
4. Verify no duplicate rules across the CLAUDE.md hierarchy
5. Re-run quality assessment — score should improve or maintain

## Anti-Patterns to Flag

| Anti-Pattern | Fix |
|---|---|
| Architecture docs in CLAUDE.md | Claude reads code; link to docs if needed |
| Code examples for standard patterns | Claude knows tRPC/Next.js/React Query |
| Config values hardcoded in instructions | They change; Claude should read from source |
| Same rule in multiple CLAUDE.md levels | Keep in the most appropriate level only |
| "Don't do X" without why | Add the reason or Claude will rationalize ignoring it |
| Linting/formatting rules | Use Biome/ESLint + hooks, not instructions |
| Task-specific content | Use skills or separate docs |
| File-by-file descriptions | Claude can explore the codebase |

## Knowledge Sources

Best practices come ONLY from verified Anthropic sources:
- Official Anthropic docs (code.claude.com, docs.anthropic.com)
- Anthropic engineering blog posts
- Anthropic employees on X/blogs:
  - Boris Cherny (head of Claude Code) — @bcherny
  - Thariq Shihipar (Claude Code engineer) — @trq212
  - Barry Zhang (agent architecture) — @barry_zyj
  - Erik Schluntz (tool use, SWE-Bench) — @ErikSchluntz
  - Alex Albert (head of Claude Relations) — @alexalbert__
  - Cat Wu (founding PM Claude Code) — @_catwu
- Do NOT use community guides or random "how to write CLAUDE.md" articles

For broader Claude Code context, consult the `/boris` skill.

## References

- `references/line-budget.md` — Token budget math and multi-level hierarchy
- `references/anthropic-skills-guide.md` — Anthropic's official guide on progressive disclosure and instruction design principles (converted from PDF)
- `references/anthropic-skills-guide.pdf` — Original PDF for visual reference
- `claude-md-management:claude-md-improver` — Base quality scoring, templates, update guidelines (auto-updated via plugin)
- `/boris` skill — Claude Code workflow tips, CLAUDE.md best practices from Boris Cherny (auto-updated)
