# Interstella Claude Marketplace

## After pushing to main

After every `git push` to main, refresh the local marketplace and update the plugin:

```bash
claude plugins marketplace update interstella-claude-marketplace && claude plugins update interstella@interstella-claude-marketplace
```

Restart Claude Code session to apply changes.

## Adding a new skill

### Structure

```
plugins/interstella/skills/{skill-name}/
├── SKILL.md
└── references/          # optional, for large reference docs
    └── *.md
```

### SKILL.md frontmatter rules

- `name` — lowercase, hyphens only, max 64 chars
- `description` — **MUST be a single-line string**. Multi-line YAML (`|` or `>`) breaks skill detection. Keep under 1024 chars
- Do NOT add `user-invocable` — it's not used by marketplace skills and may cause issues
- Match the format of existing working skills exactly

Example:
```yaml
---
name: my-skill
description: Use when user asks to do X or mentions Y. Also triggers on "Z".
---
```

### Checklist

1. Create `plugins/interstella/skills/{skill-name}/SKILL.md`
2. Add `references/` dir if skill has large reference docs (progressive disclosure)
3. Update description in both manifests to include new skill name:
   - `.claude-plugin/marketplace.json` → `plugins[0].description`
   - `plugins/interstella/.claude-plugin/plugin.json` → `description`
4. Update `README.md` skills list
5. Commit, push to main
6. Run post-push refresh (see above)
7. Restart Claude Code session
8. Verify with `/plugin` or by invoking the skill

### Moving a local skill to marketplace

When migrating from `~/.claude/skills/{name}/`:
1. Copy SKILL.md and references/ to marketplace structure
2. **Normalize frontmatter** — convert multi-line description to single-line, remove `user-invocable`
3. Follow the checklist above
4. After confirming skill works from marketplace, delete `~/.claude/skills/{name}/`

## Known issues

- **Skill detection bug ([#15178](https://github.com/anthropics/claude-code/issues/15178)):** Skills from custom marketplaces may not appear in `/plugin` UI "Installed components" list, but they load and work when invoked. Verify with `/interstella:{skill-name}`.
- **Character budget:** If many plugins are installed, skills may be excluded from context. Check with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var if skills stop triggering.
