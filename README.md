# interstella-claude-marketplace

Private Claude Code plugin marketplace.

## Installation

### 1. Add the marketplace

```bash
claude plugins marketplace add interstella-claude-marketplace https://github.com/interstella-5555/interstella-claude-marketplace
```

### 2. Install a plugin

```bash
# Install the interstella plugin (general-purpose skills)
claude plugins install interstella@interstella-claude-marketplace

# Install github-identity-manager
claude plugins install github-identity-manager@interstella-claude-marketplace

# Install current-time (injects timestamp into every prompt)
claude plugins install current-time@interstella-claude-marketplace

# Install statusline (git branch/worktree + PR + context usage in the status bar)
claude plugins install statusline@interstella-claude-marketplace
```

### 3. Restart Claude Code

Skills load on session start. After installing, restart Claude Code to make them available.

### Updating

```bash
claude plugins marketplace update interstella-claude-marketplace
claude plugins update interstella@interstella-claude-marketplace
claude plugins update github-identity-manager@interstella-claude-marketplace
claude plugins update current-time@interstella-claude-marketplace
claude plugins update statusline@interstella-claude-marketplace
```

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

### current-time

Injects the current date and time into every prompt via a `UserPromptSubmit` hook, so Claude always knows what time it is. No skills — just a hook.

### statusline

A fast POSIX-`sh` status line showing git branch/worktree, GitHub PR (with draft/merged/closed state, cached), and context-window usage. Since Claude Code only supports status lines via `settings.json`, this plugin ships the script and you wire it in once — or run the one-line installer. See [`plugins/statusline/README.md`](plugins/statusline/README.md).

### github-identity-manager

Multi-account GitHub identity management. Invoke as `/github-identity-manager`.

Set up or repair: SSH authentication, commit signing, and `gh` CLI — with directory-based automatic account switching. Keys in `~/.ssh/`, passphrase in macOS Keychain — zero prompts after initial setup.

[Single-account setup guide (gist)](https://gist.github.com/interstella-5555/971f9111f58a67630e56d23e253814d9)

## Recommended Community Skills

Standalone skills worth installing alongside this marketplace:

### boris — Claude Code Workflow Tips

53 tips from Boris Cherny (creator of Claude Code), compiled by [@CarolinaCherry](https://github.com/carolinacherry). Auto-updates on each use.

```bash
mkdir -p ~/.claude/skills/boris && curl -L -o ~/.claude/skills/boris/SKILL.md https://howborisusesclaudecode.com/api/install
```

Source: [howborisusesclaudecode.com](https://howborisusesclaudecode.com)


