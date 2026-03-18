# interstella-claude-marketplace

Private Claude Code plugin marketplace.

## Plugins

### interstella-skills

Enhanced Claude Code skills:

- **x-writing-skills** — Enhanced skill authoring guide with Anthropic references
- **x-claude-md-improver** — Enhanced CLAUDE.md optimizer with framework-aware auditing
- **x-product-bible** — Product vision/bible document writing guide with PMF, JTBD, and competitive positioning frameworks
- **screenshot** — Webpage/HTML screenshot capture via capture-website-cli
- **wait-on-resources** — Wait for services/ports using wait-on instead of sleep/polling

## Recommended Community Skills

Standalone skills worth installing alongside this marketplace:

### boris — Claude Code Workflow Tips

53 tips from Boris Cherny (creator of Claude Code), compiled by [@CarolinaCherry](https://github.com/carolinacherry). Auto-updates on each use.

```bash
mkdir -p ~/.claude/skills/boris && curl -L -o ~/.claude/skills/boris/SKILL.md https://howborisusesclaudecode.com/api/install
```

Source: [howborisusesclaudecode.com](https://howborisusesclaudecode.com)

### get-shit-done — Spec-Driven Development System

Meta-prompting, context engineering and spec-driven development system for Claude Code by TÂCHES. Solves context rot — quality degradation as Claude fills its context window.

```bash
npx get-shit-done-cc@latest
```

Source: [github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)
