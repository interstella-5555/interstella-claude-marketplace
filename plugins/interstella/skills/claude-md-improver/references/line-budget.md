# CLAUDE.md Line Budget Analysis

## How Claude Code loads instructions

Claude Code's system prompt contains ~50 built-in instructions. CLAUDE.md content is injected as a user message with the caveat: "this context may or may not be relevant to your tasks."

All CLAUDE.md files in the directory hierarchy are loaded at startup — they are NOT progressively disclosed. Every line costs tokens in every session regardless of relevance.

## Budget math

- Claude reliably follows ~150-200 total instructions
- System prompt already uses ~50
- Your budget: ~100-150 instructions across ALL loaded CLAUDE.md files
- At ~1-2 lines per instruction, target **under 200 lines per file**

## Multi-level hierarchy

| Level | Loaded when | Scope |
|-------|-------------|-------|
| `~/.claude/CLAUDE.md` | Every session, every project | Global user prefs |
| `workspace/CLAUDE.md` | Every session in workspace | Workspace-wide rules |
| `project/CLAUDE.md` | Every session in project | Project-specific rules |
| `.claude/rules/*.md` | On demand (path-matched) | File-type specific rules |
| `subdir/CLAUDE.md` | When Claude reads files in that dir | Feature/domain specific |

**Key insight:** Global + workspace + project CLAUDE.md all load together. If global is 20 lines, workspace is 75 lines, and project is 200 lines, that's 295 lines — already over budget.

## Optimization strategies

1. **Use `.claude/rules/` with `paths:` frontmatter** for file-type-specific rules — loaded on demand, not at startup
2. **Use `@path/to/file` imports** to reference docs Claude reads only when relevant
3. **Move architecture docs to `ai-docs/`** — Claude reads them when exploring code
4. **Keep global CLAUDE.md tiny** (under 30 lines) — these load in EVERY project

## Sources

- [Anthropic official docs](https://code.claude.com/docs/en/memory)
- [Anthropic best practices](https://code.claude.com/docs/en/best-practices)
- Boris Cherny (Head of Claude Code) — ruthless iteration, let Claude write its own rules
- [Anthropic: The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) — progressive disclosure principles
