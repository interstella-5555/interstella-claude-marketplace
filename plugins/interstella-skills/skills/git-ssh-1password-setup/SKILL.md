---
name: git-ssh-1password-setup
description: "Set up or repair multi-account GitHub SSH authentication and commit signing with 1Password. Use when: user wants to configure SSH keys for GitHub, set up commit signing, manage multiple GitHub accounts, fix 'Permission denied' SSH errors, fix 'Unverified' commits, or says 'set up git signing', 'fix my SSH', 'configure 1Password SSH', 'my commits are unverified'. Handles fresh setup (guided wizard) and repair mode (detect + fix issues)."
---

# Git SSH + 1Password Setup

Multi-account GitHub SSH auth and commit signing via 1Password. Two modes: **setup** (fresh) and **repair** (existing).

**macOS only.** Requires 1Password 8+ and Git 2.36+.

Read `references/setup-guide.md` for the full technical reference before proceeding.

## Mode Detection

Run discovery to determine mode:

```bash
# Check for existing 1Password setup signals
ls ~/.1password/agent.sock 2>/dev/null          # symlink exists?
cat ~/.ssh/config 2>/dev/null | grep -i IdentityAgent  # agent configured?
cat ~/.gitconfig 2>/dev/null | grep -i includeIf       # directory switching?
ls ~/.ssh/1password/*.pub 2>/dev/null            # pub keys on disk?
git config --global gpg.ssh.program 2>/dev/null  # op-ssh-sign configured?
git config --global commit.gpgsign 2>/dev/null   # signing enabled?
```

- **All signals present** → Repair mode
- **Some or none** → Setup mode (partial setup = resume from where it broke)

---

## Repair Mode

Run these checks **in order**. Stop at first failure, report it, ask to fix.

### Check 1: Prerequisites

```bash
git --version    # Must be 2.36+
ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign  # Must exist
```

### Check 2: 1Password agent reachable

```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Must list at least one key. If empty/error → agent not running or symlink broken
```

### Check 3: SSH config correct

```bash
cat ~/.ssh/config
# Must contain: IdentityAgent ~/.1password/agent.sock
# Should NOT contain: Host aliases for github (e.g. Host github-work)
# Should NOT contain: IdentityFile pointing to private keys
```

### Check 4: Git directory-based switching

```bash
cat ~/.gitconfig | grep -A1 includeIf
# Must have includeIf blocks pointing to per-account gitconfig files
```

For each includeIf target file, verify it contains:
- `[user]` with name, email, signingkey
- `[gpg] format = ssh`
- `[gpg "ssh"] program = .../op-ssh-sign`
- `[core] sshCommand = ssh -i ~/.ssh/1password/<name>.pub -o IdentitiesOnly=yes`

### Check 5: Public keys on disk match agent

```bash
# For each .pub in ~/.ssh/1password/:
# Extract fingerprint and compare with agent keys
ssh-keygen -lf ~/.ssh/1password/<name>.pub
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Fingerprints must match
```

### Check 6: SSH auth works per account

For each account/directory pair, `cd` into a repo in that directory and:

```bash
ssh -T git@github.com 2>&1
# Must show: Hi <expected-account>! You've successfully authenticated...
```

If wrong account → `core.sshCommand` not picking up the right key.

### Check 7: Commit signing works

For each account, test in a repo in the matching directory:

```bash
git commit --allow-empty -m "test signing verify"
# 1Password should show Touch ID prompt
# Then check:
git log --show-signature -1
```

### Check 8: Remotes use SSH (not HTTPS or Host aliases)

```bash
# For each repo directory configured in includeIf:
for dir in ~/<directory>/*/; do
  [ -d "$dir/.git" ] || continue
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  echo "$(basename $dir): $url"
done
# All should be git@github.com:org/repo.git
# Flag any https:// or Host alias remotes
```

### Check 9: GitHub has signing keys

This can't be verified programmatically (requires GitHub auth scope). Ask the user:

> "Have you added your SSH keys as **both** Authentication Key and Signing Key on each GitHub account? (https://github.com/settings/keys)"

### Report

After all checks, summarize:
- What passed
- What failed (with specific fix for each)
- Ask permission before fixing anything

---

## Setup Mode

### Phase 1: Discovery

Ask and discover — **never assume**:

1. **How many GitHub accounts?** Ask for username and purpose of each (personal, work, etc.)
2. **Where are repos cloned?** Scan for git repos:
   ```bash
   find ~ -maxdepth 3 -name ".git" -type d 2>/dev/null | head -30
   ```
   Group by parent directory. Ask if the user wants directory-based separation. If repos aren't already separated by account, **propose** a directory layout (e.g. `~/personal/`, `~/work/`) but **never move repos without explicit confirmation**.
3. **Existing SSH keys?** Scan and show:
   ```bash
   ls -la ~/.ssh/*.pub 2>/dev/null
   cat ~/.ssh/config 2>/dev/null
   ```
4. **Existing signing setup?** Check for GPG or old SSH signing:
   ```bash
   git config --global gpg.format
   git config --global gpg.program
   git config --global user.signingkey
   grep -E "GPG_TTY|gpg" ~/.zshrc ~/.bashrc 2>/dev/null
   which gpg 2>/dev/null
   ```
5. **1Password SSH keys?** Ask:
   > "Do you already have SSH keys in 1Password for GitHub? If not, I'll walk you through creating them. If yes, tell me their names and I'll verify the agent serves them."

6. **1Password vaults?** Ask:
   > "Are your SSH keys all in the same 1Password vault (Private), or in different vaults?"

### Phase 2: Present Plan

Before touching anything, present the complete plan:

> "Here's what I'll set up:
>
> **SSH Config** (`~/.ssh/config`): 1Password agent for all connections
> **Git Config** (`~/.gitconfig`): Directory-based account switching via `includeIf`
> **Per-account configs** (`~/.gitconfig-<name>`): SSH command, signing key, identity for each account
> **Public keys** (`~/.ssh/1password/<name>.pub`): For key selection (public only, not secrets)
> **Agent config** (`~/.config/1Password/ssh/agent.toml`): Enable all vaults with SSH keys
>
> **You'll need to do manually:**
> - Create SSH keys in 1Password (if not done)
> - Add keys to GitHub (Authentication + Signing) for each account
>
> **I won't touch:**
> - Your existing SSH keys (used for VPS/servers)
> - Your repos (no moving, no remote changes yet)
>
> Want to proceed?"

Wait for confirmation.

### Phase 3: Execute

Follow `references/setup-guide.md` steps 1-7. For each step:
1. Explain what you're about to do
2. Do it
3. Verify it worked
4. Move to next step

**Key rules:**
- **Never delete SSH keys.** If old keys need removing, move to `~/.ssh/backup/` using `mv` (not `rm`). At the end, tell the user: "Old keys backed up to `~/.ssh/backup/`. To remove them permanently: `trash ~/.ssh/backup/` (moves to macOS Trash, recoverable)."
- **Never move repos** without explicit confirmation per repo.
- **Ask before each destructive action** (removing Host aliases from ssh config, changing remotes).
- **Fix remotes last** (Step 8) — ask first: "I found X repos using HTTPS and Y using Host aliases. Want me to convert them all to `git@github.com:...`?"

### Phase 4: Verify

Run all Repair Mode checks (Check 1-9). Everything should pass.

### Phase 5: Cleanup Offer

If old signing infrastructure was found in Phase 1, offer cleanup:

> "I found remnants of your old signing setup:
> - [list what was found: GPG, old keys, GPG_TTY in zshrc, etc.]
>
> Since 1Password now handles everything, these can be removed. Want me to clean them up?"

For old SSH keys: backup to `~/.ssh/backup/`, never `rm`. Mention:

> "Old keys backed up to `~/.ssh/backup/`. When you're confident everything works, you can permanently remove them with `trash ~/.ssh/backup/` (goes to macOS Trash, still recoverable). SSH keys used for non-GitHub purposes (VPS, servers) were NOT touched."

For GitHub old keys: tell user to manually review and delete at https://github.com/settings/keys for each account.

---

## Critical Rules

- **macOS only** — this skill does not support Windows or Linux
- **Never delete private keys** — always `mv` to backup, suggest `trash` to user
- **Never move repos** without per-repo confirmation
- **Always verify after each step** — don't assume success
- **Ask about non-GitHub SSH usage** before touching any key — VPS, servers, other services must not break
- **One question at a time** — don't overwhelm with multiple questions
- **Show don't tell** — run commands to discover state rather than asking the user to describe it
