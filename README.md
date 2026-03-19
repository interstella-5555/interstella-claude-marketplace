# interstella-claude-marketplace

Private Claude Code plugin marketplace.

## Plugins

### interstella

General-purpose Claude Code skills. Invoke as `/interstella:<skill-name>`.

| Skill | Description |
|---|---|
| **creating-skills** | Skill authoring guide with Anthropic references and TDD methodology |
| **claude-md-improver** | CLAUDE.md optimizer with framework-aware auditing and signal-to-noise optimization |
| **product-bible** | Product vision/bible document guide with PMF, JTBD, and competitive positioning frameworks |
| **screenshot** | Webpage/HTML screenshot capture via capture-website-cli |
| **wait-on-resources** | Wait for services/ports using wait-on instead of sleep/polling |

### github-identity-manager

Multi-account GitHub identity management via 1Password. Invoke as `/github-identity-manager`.

Set up or repair: SSH authentication, commit signing (Touch ID), and `gh` CLI — all with directory-based automatic account switching. Also works for single-account setups.

[Setup guide (gist)](https://gist.github.com/interstella-5555/971f9111f58a67630e56d23e253814d9)

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
