---
name: writing-skills
description: Use when creating new skills, editing existing skills, or improving skill quality. Enhanced version of writing-skills with Anthropic's complete guide, best practices, and expert insights as local references.
---

# Writing Skills

Enhanced skill-writing guide. Combines `superpowers:writing-skills` TDD methodology with Anthropic's official references and expert insights — all stored locally for deep consultation.

**Announce at start:** "Using writing-skills — enhanced skill authoring with full Anthropic references."

## Workflow

1. **Read `superpowers:writing-skills`** for TDD methodology (RED-GREEN-REFACTOR), CSO, and skill structure
2. **Consult this skill's references** (below) for deep guidance on specific aspects
3. **Follow writing-skills checklist** for deployment

## When to Consult Which Reference

| You need... | Read... |
|---|---|
| **Skill structure, frontmatter, naming rules** | `references/anthropic-best-practices.md` → "Skill structure" section |
| **Progressive disclosure patterns** (how to split SKILL.md + reference files) | `references/anthropic-best-practices.md` → "Progressive disclosure patterns" |
| **Degrees of freedom** (how prescriptive to be) | `references/anthropic-best-practices.md` → "Set appropriate degrees of freedom" |
| **Writing effective descriptions** | `references/anthropic-best-practices.md` → "Writing effective descriptions" + `superpowers:writing-skills` CSO section |
| **Workflow patterns** (sequential, multi-MCP, iterative, context-aware, domain-specific) | `references/anthropic-complete-guide.md` → Chapter 5 "Patterns and troubleshooting" |
| **Use case categories** (document creation, workflow automation, MCP enhancement) | `references/anthropic-complete-guide.md` → Chapter 2 "Planning and design" |
| **Success metrics** (quantitative + qualitative) | `references/anthropic-complete-guide.md` → "Define success criteria" |
| **Distribution** (organization-wide, API, plugins, open standard) | `references/anthropic-complete-guide.md` → Chapter 4 "Distribution and sharing" |
| **Troubleshooting** (skill won't trigger, overtriggers, instructions not followed) | `references/anthropic-complete-guide.md` → Chapter 5 "Troubleshooting" |
| **Executable scripts in skills** (error handling, utility scripts, validation) | `references/anthropic-best-practices.md` → "Advanced: Skills with executable code" |
| **Evaluation-driven development** (build evals before docs) | `references/anthropic-best-practices.md` → "Evaluation and iteration" |
| **Iterative development with Claude A/B** | `references/anthropic-best-practices.md` → "Develop Skills iteratively with Claude" |
| **Operational philosophy** (verification, plan-first, compounding engineering) | `references/boris-cherny-insights.md` + `/boris` skill (auto-updated) |
| **Skills vs CLAUDE.md vs hooks vs subagents** | `references/boris-cherny-insights.md` → "When to use what" |
| **Claude Code workflows, worktrees, permissions, hooks** | `/boris` skill (maintained separately, always up-to-date) |
| **Testing and bulletproofing** | `superpowers:writing-skills` → Testing sections + `testing-skills-with-subagents.md` |
| **Real-world skill patterns from Anthropic** (9 types, gotchas, progressive disclosure examples, description writing, memory, scripts) | `references/thariq-lessons-skills.md` — from Thariq (Anthropic engineer, Claude Code team) |

## Key Principles (Condensed from All Sources)

### 1. Conciseness is King
Context window is a public good. Only add context Claude doesn't already have. Challenge every token: "Does Claude really need this?" Keep SKILL.md body under 500 lines.

### 2. Description = When to Use, NOT What It Does
- Start with "Use when..."
- Include trigger phrases users would actually say
- Write in third person
- NEVER summarize the skill's workflow in the description (Claude will shortcut and skip the body)
- Structure: `[When to use it] + [Trigger conditions] + [Key capabilities]`

### 3. Progressive Disclosure (3 Levels)
- **Level 1 (always loaded):** YAML frontmatter name + description
- **Level 2 (loaded on trigger):** SKILL.md body — keep focused
- **Level 3 (loaded on demand):** Reference files in `references/` — Claude reads only when needed

### 4. Degrees of Freedom
- **Low freedom** (exact scripts, no params): Fragile/critical operations (migrations, deployments)
- **Medium freedom** (pseudocode, configurable): Preferred patterns with acceptable variation
- **High freedom** (text instructions): Multiple valid approaches, context-dependent decisions

### 5. Verification > Trust
Give Claude a way to verify its work — scripts, validators, checklists. "You don't trust; you instrument." Feedback loops (run validator → fix → repeat) greatly improve output quality.

### 6. Plan Before Execute
Pour energy into the plan so Claude can 1-shot the implementation. Use workflows with explicit steps, checklists, and validation gates.

### 7. Test with TDD (from writing-skills)
No skill without a failing test first. RED (baseline without skill) → GREEN (minimal skill) → REFACTOR (close loopholes). See `superpowers:writing-skills` for full methodology.

## Quick Checklist

Before deploying any skill:

- [ ] Description starts with "Use when..." and has trigger phrases
- [ ] Description does NOT summarize the workflow
- [ ] SKILL.md under 500 lines
- [ ] Large references in separate files (progressive disclosure)
- [ ] Consistent terminology throughout
- [ ] No time-sensitive information
- [ ] File references max one level deep from SKILL.md
- [ ] Tested with pressure scenarios (RED-GREEN-REFACTOR)
- [ ] Feedback loops for quality-critical operations
- [ ] Forward slashes in all paths (no backslashes)

## References

- `references/anthropic-best-practices.md` — Anthropic's official skill authoring best practices (from platform.claude.com). Deep dive on structure, descriptions, progressive disclosure, degrees of freedom, evaluation, executable code, patterns.
- `references/anthropic-complete-guide.md` — "The Complete Guide to Building Skills for Claude" (33-page PDF converted to markdown). Full lifecycle: fundamentals, planning, testing, distribution, 5 workflow patterns, troubleshooting.
- `references/anthropic-complete-guide.pdf` — Original PDF for visual reference.
- `references/boris-cherny-insights.md` — Unique operational insights from Boris Cherny (Head of Claude Code). Verification philosophy, compounding engineering, skills vs other features, subagent patterns.
- `references/thariq-lessons-skills.md` — "Lessons from Building Claude Code: How We Use Skills" by Thariq (@trq212, Anthropic engineer, Claude Code team). 9 skill categories, concrete examples with code, tips on gotchas sections, progressive disclosure hub-and-spoke pattern, description writing, memory/data persistence, composable scripts. First-party source — same authority level as Boris Cherny.
- `/boris` skill — Broader Claude Code workflow tips from Boris (worktrees, permissions, hooks, parallel sessions, etc.). Maintained separately — always current. Consult for general Claude Code context when designing skills.
