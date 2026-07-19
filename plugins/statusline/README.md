# statusline

A fast POSIX-`sh` status line for Claude Code. It reads the JSON that Claude Code pipes on stdin and renders, separated by ` · `:

- **Git branch / worktree** — `⎇ branch`, or `⎇ worktree: name` inside a git worktree. Resolved by walking up the directory tree and parsing `.git/HEAD` directly (no `git` subprocess), so it's cheap and works in monorepos and subdirs.
- **GitHub PR** — for non-`main`/`master` branches, shows a clickable `PR #123` with `(draft)` / `(merged)` / `(closed)` state. Uses `gh pr view`, cached in `/tmp` with a 60s TTL and refreshed in the background so it never blocks rendering.
- **Context usage** — `NN% context`, colored yellow at ≥30% and bold red at ≥50%.
- **Model + effort** — the active model's display name, and the reasoning effort (`low`/`medium`/`high`/`xhigh`/`max`) when the model supports it, e.g. `Opus 4.8 · high effort`.

Requires `jq` and (for the PR segment) the `gh` CLI.

## Why setup is manual

Claude Code does **not** let plugins declare a status line — `statusLine` is a settings-only feature. This plugin just ships the script; you point `settings.json` at it once per machine.

## Setup

Assuming the `interstella-claude-marketplace` is already added:

```bash
claude plugins install statusline@interstella-claude-marketplace
```

Then symlink the shipped script to a stable path (the plugin cache dir is versioned by commit hash, so the glob keeps the link valid across updates):

```bash
ln -sf ~/.claude/plugins/cache/interstella-claude-marketplace/statusline/*/statusline-command.sh \
       ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

Finally, add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  }
}
```

Restart Claude Code (or start a new session) to see it.

## One-shot install on another machine (no plugin needed)

Paste this prompt into Claude Code and let it do the install:

> Download https://raw.githubusercontent.com/interstella-5555/interstella-claude-marketplace/main/plugins/statusline/statusline-command.sh to `~/.claude/statusline-command.sh`, make it executable, and add a `statusLine` entry to `~/.claude/settings.json` (type `command`, command `~/.claude/statusline-command.sh`), creating the file if it doesn't exist. Then tell me to restart Claude Code.
