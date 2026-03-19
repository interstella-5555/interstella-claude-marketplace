---
name: github-identity-manager
description: "Manual invocation only. Set up, repair, or modify multi-account GitHub identity management with 1Password. Configures git CLI (SSH auth + commit signing), gh CLI (per-directory account switching), and 1Password SSH agent — all with directory-based automatic account selection. Also works for single-account setups (signed commits + 1Password SSH). Use when user explicitly invokes this skill."
---

# GitHub Identity Manager

Manages GitHub identity: SSH auth, commit signing, and `gh` CLI — all via 1Password, with automatic directory-based account switching.

**What this sets up:**
- **`git` CLI** — SSH push/pull with the right key per directory, commits signed via 1Password Touch ID
- **`gh` CLI** — automatically authenticated as the right GitHub account per directory
- **1Password SSH agent** — private keys never leave 1Password, no keys on disk
- **Directory-based switching** — `cd ~/work/` = work account, `cd ~/personal/` = personal account. Automatic, no manual switching.

**macOS only.** Requires Git 2.36+ and 1Password 8+ with active subscription.

Read `references/setup-guide.md` for the full technical reference.

---

## On Start

### Prerequisites check

```bash
git --version                   # Must be 2.36+
which gh                        # Must be installed
ls /Applications/1Password.app  # Must be installed
ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign  # Must exist
```

- **git missing** → install: `brew install git`
- **gh missing** → install: `brew install gh`
- **1Password missing** → tell user: "1Password 8+ with an active subscription is required. Install from https://1password.com/downloads/mac — I can't install it for you."
- **op-ssh-sign missing** → 1Password too old or SSH agent not enabled. Guide user to enable it.

### Single vs Multi account

Run discovery:

```bash
# Check for multi-account signals
cat ~/.gitconfig 2>/dev/null | grep -c includeIf
gh auth status 2>&1 | grep -c "Logged in"
```

If **no multi-account setup detected**, explain:

> "This skill manages your GitHub identity — SSH keys, commit signing, and CLI authentication — all through 1Password.
>
> **Multi-account** (2+ GitHub accounts): Full setup with directory-based automatic switching. Your git and gh commands use the right account based on which folder you're in.
>
> **Single account**: Simplified setup — signed commits via Touch ID, SSH through 1Password, gh authenticated. No directory switching needed.
>
> How many GitHub accounts do you use?"

### Mode detection

```bash
ls ~/.1password/agent.sock 2>/dev/null
cat ~/.ssh/config 2>/dev/null | grep -i IdentityAgent
cat ~/.gitconfig 2>/dev/null | grep -i includeIf
ls ~/.ssh/1password/*.pub 2>/dev/null
git config --global commit.gpgsign 2>/dev/null
gh auth status 2>&1
```

- **All signals present** → **Repair mode**
- **Some or none** → **Setup mode** (partial = resume from where it broke)

Also check if user mentioned a **specific task** (add account, change folder, change key, etc.) → handle that directly without full setup/repair.

---

## Incremental Changes

If user invokes with a specific request, handle it directly:

### "Add a new GitHub account"

1. Ask: account username, directory for repos, 1Password vault
2. Create SSH key in 1Password (guide user)
3. Save pub key to `~/.ssh/1password/<name>.pub`
4. Add `includeIf` block to `~/.gitconfig`
5. Create `~/.gitconfig-<name>` with user/signing/sshCommand
6. Add vault to `agent.toml` if needed
7. `gh auth login` for the new account
8. Add to `__auto_gh_account` in shell config
9. Add key to GitHub (Authentication + Signing)
10. Verify with test commit

### "Change my repo directory"

1. Ask: which account, old dir, new dir
2. Update `includeIf "gitdir:..."` in `~/.gitconfig`
3. Update `__auto_gh_account` case pattern in shell config
4. Verify

### "My key changed in 1Password"

1. Ask: which account
2. Get new public key from user (copy from 1Password)
3. Update `~/.ssh/1password/<name>.pub`
4. Update `signingkey` in `~/.gitconfig-<name>`
5. Update key on GitHub (remove old, add new — both Auth + Signing)
6. Verify

### "Remove an account"

1. Ask: which account
2. Remove `includeIf` block from `~/.gitconfig`
3. Backup `~/.gitconfig-<name>` to `~/.ssh/backup/`
4. Remove from `__auto_gh_account` in shell config
5. `gh auth logout <account>`
6. Tell user to remove key from GitHub manually

---

## Repair Mode

Run these checks **in order**. Stop at first failure, report, ask to fix.

### Check 1: Prerequisites
```bash
git --version    # 2.36+
ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign
which gh
```

### Check 2: 1Password agent reachable
```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Must list keys. Empty/error → agent not running or symlink broken
```

### Check 3: SSH config
```bash
cat ~/.ssh/config
# Must: IdentityAgent ~/.1password/agent.sock
# Should NOT: Host aliases for github, IdentityFile to private keys
```

### Check 4: Git directory switching
```bash
cat ~/.gitconfig | grep -A1 includeIf
# Must have includeIf blocks for each account directory
```

For each per-account gitconfig, verify:
- `[user]` name, email, signingkey
- `[gpg] format = ssh`
- `[gpg "ssh"] program = .../op-ssh-sign`
- `[core] sshCommand = ssh -i ~/.ssh/1password/<name>.pub -o IdentitiesOnly=yes`

### Check 5: Public keys match agent
```bash
ssh-keygen -lf ~/.ssh/1password/<name>.pub   # per key
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Fingerprints must match
```

### Check 6: SSH auth per account
For each account, from a repo in the matching directory:
```bash
ssh -T git@github.com 2>&1
# Must show correct username
```

### Check 7: Commit signing
For each account, in a repo in the matching directory:
```bash
git commit --allow-empty -m "verify signing"
git log --show-signature -1
# Must show valid signature. 1Password Touch ID should prompt.
```

### Check 8: gh CLI per account
For each account directory:
```bash
cd ~/<directory>/some-repo
gh auth status
# Must show correct account
```

Also verify auto-switching mechanism exists in shell config:
```bash
grep -A5 "__auto_gh_account\|GH_TOKEN" ~/.zshrc ~/.bashrc 2>/dev/null
# Or check for direnv .envrc files with GH_TOKEN
```

### Check 9: Remotes use SSH
```bash
for dir in ~/<directory>/*/; do
  [ -d "$dir/.git" ] || continue
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  echo "$(basename $dir): $url"
done
# All should be git@github.com:... (not https://, not Host aliases)
```

### Check 10: GitHub keys
Can't verify programmatically. Ask:
> "Have you added your SSH keys as **both** Authentication Key and Signing Key on each GitHub account? Check at https://github.com/settings/keys"

### Report

Summarize: what passed, what failed (with specific fix for each). Ask permission before fixing.

---

## Setup Mode

### Phase 1: Discovery

**Never assume — discover and ask:**

1. **How many GitHub accounts?** Username and purpose of each.

2. **Where are repos?** Scan:
   ```bash
   find ~ -maxdepth 3 -name ".git" -type d 2>/dev/null | head -30
   ```
   Group by parent directory. If not separated by account, **propose** a layout (e.g. `~/work/`, `~/personal/`). **Never move repos without explicit per-repo confirmation.**

3. **Existing SSH keys?**
   ```bash
   ls -la ~/.ssh/*.pub ~/.ssh/**/*.pub 2>/dev/null
   cat ~/.ssh/config 2>/dev/null
   SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l 2>/dev/null
   ```

4. **Existing signing/GPG?**
   ```bash
   git config --global gpg.format
   git config --global user.signingkey
   grep -E "GPG_TTY|gpg" ~/.zshrc ~/.bashrc 2>/dev/null
   which gpg 2>/dev/null
   ```

5. **1Password SSH keys?** Ask:
   > "Do you have SSH keys in 1Password for GitHub already? If yes, tell me their names. If not, I'll guide you through creating them."

6. **1Password vaults?** Ask:
   > "Are your SSH keys all in the same 1Password vault, or different vaults?"

7. **gh CLI status?**
   ```bash
   gh auth status 2>&1
   ```

8. **Non-GitHub SSH usage?** Ask:
   > "Do you use SSH keys for anything other than GitHub? (VPS, servers, other git hosting) — I need to know so I don't break those connections."

### Phase 2: Present Plan

Before touching anything:

> "Here's what I'll set up:
>
> **Tools:** `git` (SSH auth + signed commits) + `gh` (CLI per account) + 1Password (SSH agent + Touch ID signing)
>
> **Files I'll create/modify:**
> - `~/.ssh/config` — 1Password agent for all SSH connections
> - `~/.gitconfig` — directory-based account switching (`includeIf`)
> - `~/.gitconfig-<name>` per account — SSH key, signing, identity
> - `~/.ssh/1password/<name>.pub` — public keys for key selection
> - `~/.config/1Password/ssh/agent.toml` — enable vaults
> - `~/.zshrc` or direnv — `gh` CLI auto-switching per directory
>
> **You'll need to do manually:**
> - Create SSH keys in 1Password (I'll guide you)
> - Add keys to GitHub as Authentication + Signing keys
> - `gh auth login` for each account (I'll prompt you when)
>
> **I won't touch:**
> - Existing SSH keys used for non-GitHub purposes
> - Your repos (no moving without permission)
>
> Ready?"

### Phase 3: Execute

Follow `references/setup-guide.md`. For each step: explain → do → verify → next.

#### 3a: 1Password SSH keys
Guide user through creating Ed25519 keys in 1Password. Verify agent sees them.

#### 3b: Agent symlink + config
```bash
mkdir -p ~/.1password
ln -s "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ~/.1password/agent.sock
```
Update `~/.config/1Password/ssh/agent.toml` for additional vaults.

#### 3c: SSH config
Write `~/.ssh/config` with `IdentityAgent ~/.1password/agent.sock`.

#### 3d: Public keys to disk
```bash
mkdir -p ~/.ssh/1password
echo "<pub-key>" > ~/.ssh/1password/<name>.pub
```

#### 3e: Git config
- `~/.gitconfig` — global settings + `includeIf` blocks
- `~/.gitconfig-<name>` per account — user, signing, sshCommand

**For single-account setup:** skip `includeIf`, put everything in `~/.gitconfig` directly.

#### 3f: gh CLI setup
For each account:
```bash
gh auth login
# Interactive: GitHub.com → SSH → select key → authenticate in browser
```

Then set up auto-switching. **Prefer shell function over direnv** (works in all contexts):

```bash
# Add to ~/.zshrc (or ~/.bashrc):
__auto_gh_account() {
  case "$PWD" in
    ~/work*)     export GH_TOKEN=$(gh auth token --user <work-username>) ;;
    ~/personal*) export GH_TOKEN=$(gh auth token --user <personal-username>) ;;
    *) unset GH_TOKEN ;;
  esac
}
chpwd_functions+=(__auto_gh_account)  # zsh: runs on every cd
__auto_gh_account                      # run once on shell start
```

For bash, use `PROMPT_COMMAND` instead of `chpwd_functions`.

**For single-account setup:** skip auto-switching, just `gh auth login` once.

#### 3g: GitHub keys
Guide user to add each key as both Authentication + Signing key on GitHub.

#### 3h: Fix remotes
Scan for HTTPS and Host alias remotes. Ask before converting:
> "Found X repos using HTTPS and Y using Host aliases. Convert them all to `git@github.com:...`?"

### Phase 4: Verify

Run all Repair Mode checks (1-10). Everything should pass.

### Phase 5: Cleanup

If old infrastructure found:

> "I found remnants of a previous setup:
> - [list: GPG, old keys, GPG_TTY, Host aliases, etc.]
>
> 1Password now handles everything. Want me to clean these up?"

**SSH keys:** backup to `~/.ssh/backup/` (never delete). After everything works:
> "Old keys backed up to `~/.ssh/backup/`. To remove permanently: `trash ~/.ssh/backup/` (moves to macOS Trash — still recoverable). Keys used for non-GitHub purposes were NOT touched."

**GitHub keys:** tell user to manually review at https://github.com/settings/keys — delete old GPG keys, old SSH auth keys, and old SSH signing keys that are no longer needed. **Do this for each account.**

---

## Critical Rules

- **macOS only**
- **Never delete private keys** — `mv` to backup, suggest `trash` for permanent removal
- **Never move repos** without per-repo confirmation
- **Always verify after each step**
- **Ask about non-GitHub SSH usage** before touching any key
- **One question at a time**
- **Show don't tell** — run commands to discover, don't ask user to describe
- **`trash` over `rm`** — always mention it moves to macOS Trash (recoverable)
