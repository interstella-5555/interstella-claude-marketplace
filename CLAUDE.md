# Interstella Claude Marketplace

## After pushing to main

After every `git push` to main, refresh the local marketplace and update the plugin:

```bash
claude plugins marketplace update interstella-claude-marketplace && claude plugins update interstella-skills@interstella-claude-marketplace
```

Restart Claude Code session to apply changes.
