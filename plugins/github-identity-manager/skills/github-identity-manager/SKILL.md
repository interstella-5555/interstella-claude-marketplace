---
name: github-identity-manager
description: "Manual invocation only. Set up, repair, or modify multi-account GitHub identity management. Keys in ~/.ssh/, passphrase in macOS Keychain, zero prompts. Configures git CLI (SSH auth + commit signing), gh CLI (per-directory account switching) — all with directory-based automatic account selection. Use when user explicitly invokes this skill."
---

# GitHub Identity Manager

Manages GitHub identity: SSH auth, commit signing, and `gh` CLI — with automatic directory-based account switching.

| Component | Implementation |
|---|---|
| Private keys | `~/.ssh/` on disk (Ed25519) |
| SSH agent | macOS ssh-agent |
| Commit signing | `ssh-keygen` (silent, no prompt) |
| Auth experience | Passphrase in macOS Keychain (zero prompts) |
| Extra requirements | None |

**Infrastructure:**
- `includeIf` directory-based git config switching
- Per-account gitconfigs (user, email, signingkey)
- `gpg.format = ssh` for commit signing
- direnv for `gh` CLI auto-switching
- All remotes use `git@github.com:`

**macOS only.** Requires Git 2.36+.

**Technical reference (read on demand):**
- `references/setup-guide.md` — Full step-by-step setup

---

## On Start

### Prerequisites check

```bash
git --version       # Must be 2.36+
which gh            # Must be installed
which direnv        # Must be installed
```

- **git missing/old** → `brew install git`
- **gh missing** → `brew install gh`
- **direnv missing** → `brew install direnv` + shell hook ([direnv setup](https://direnv.net/docs/hook.html))

### Detect current state

```bash
cat ~/.ssh/config 2>/dev/null | grep -i UseKeychain
ls ~/.ssh/id_ed25519_* 2>/dev/null
cat ~/.gitconfig 2>/dev/null | grep -c includeIf
gh auth status 2>&1 | grep -c "Logged in"
```

### Mode detection

- **All signals present** → **Repair mode**
- **Some or none** → **Setup mode** (partial = resume from where it broke)
- **User mentions specific task** (add account, change folder, etc.) → **Incremental change** (handle directly)

---

## Incremental Changes

If user invokes with a specific request, handle it directly.

### "Add a new GitHub account"

1. Ask: account username, directory for repos
2. Ask: key name suffix (e.g. `github_work`) — explain it becomes part of the filename
3. `ssh-keygen -t ed25519 -C "<email>" -f ~/.ssh/id_ed25519_<suffix>`
4. `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_<suffix>`
5. Add `includeIf` block to `~/.gitconfig`
6. Create `~/.gitconfig-<suffix>` with user/signing/sshCommand
7. `gh auth login` for the new account
8. Create `.envrc` in account directory
9. Add key to GitHub (Authentication + Signing)
10. Verify with test commit

### "Change my repo directory"

1. Ask: which account, old dir, new dir
2. Update `includeIf "gitdir:..."` in `~/.gitconfig`
3. Move `.envrc` to new directory (or update path)
4. Verify

### "My key changed" / "Regenerate key"

1. Ask: which account
2. `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_<suffix>`, then `ssh-add --apple-use-keychain`
3. Update `signingkey` in `~/.gitconfig-<suffix>`
4. Update key on GitHub (remove old, add new — both Auth + Signing)
5. Verify

### "Remove an account"

1. Ask: which account
2. Remove `includeIf` block from `~/.gitconfig`
3. Backup `~/.gitconfig-<suffix>` to `~/.ssh/backup/`
4. Backup private key to `~/.ssh/backup/`
5. Remove `.envrc` from the account's directory
6. `gh auth logout <account>`
7. Tell user to remove key from GitHub manually

---

## Repair Mode

Run checks **in order**. Stop at first failure, report, ask to fix.

### Check 1: Prerequisites
```bash
git --version    # 2.36+
which gh
which direnv
```

### Check 2: SSH agent

```bash
ssh-add -l
# Must list keys. Empty → run ssh-add --apple-use-keychain for each key
```

### Check 3: SSH config

Must have `AddKeysToAgent yes` and `UseKeychain yes`. No `IdentityAgent`.

```bash
cat ~/.ssh/config
```

If `~/.ssh/config` has an existing `Host *` block with other directives:
- **Add** `AddKeysToAgent yes` and `UseKeychain yes` into that existing block (don't create a duplicate `Host *`)
- If the existing block has **conflicting** values (e.g. `AddKeysToAgent no`), ask user before changing
- Other `Host` blocks (for VPS, servers, etc.) should be left untouched

### Check 4: Global git config
```bash
git config --global commit.gpgsign
# Must be "true" — otherwise commits aren't signed automatically
cat ~/.gitconfig | grep -A1 includeIf
# Must have includeIf blocks for each account directory
```

### Check 5: Per-account gitconfigs

For each `~/.gitconfig-<suffix>`, verify:

- `[user]` name, email, signingkey
- `[gpg] format = ssh`
- `[core] sshCommand` set with correct key path + `-o IdentitiesOnly=yes`
- No `gpg.ssh.program` (defaults to `ssh-keygen`)
- `signingkey` is path to `.pub` file
- `sshCommand` uses `~/.ssh/id_ed25519_<suffix>`

### Check 6: Public keys match agent

```bash
ssh-keygen -lf ~/.ssh/id_ed25519_<suffix>.pub
ssh-add -l
# Fingerprints must match
```

### Check 7: SSH auth per account

For each account, from a repo in the matching directory:
```bash
ssh -i ~/.ssh/id_ed25519_<suffix> -o IdentitiesOnly=yes -T git@github.com 2>&1
# Must show correct username
```
> **Important:** Do NOT use bare `ssh -T git@github.com` — with multiple keys in the agent, SSH tries them in order and GitHub accepts the first match. The test would pass with the wrong account.

### Check 8: Commit signing

For each account, from a repo in the matching directory:
```bash
git checkout -b test-signing
git commit --allow-empty -m "verify signing"
git log --show-signature -1
# Must show valid signature (silent, no prompt)
```
Clean up after:
```bash
git checkout main && git branch -D test-signing
```

### Check 9: gh CLI per account

For each account directory:
```bash
cd ~/<directory>/some-repo && gh auth status
# Must show correct account
cat ~/<directory>/.envrc | grep GH_TOKEN
```

### Check 10: Remotes use SSH
```bash
for dir in ~/<directory>/*/; do
  [ -d "$dir/.git" ] || continue
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  echo "$(basename $dir): $url"
done
# All should be git@github.com:... (not https://)
```

### Report

Summarize: what passed, what failed (with specific fix for each). Ask permission before fixing.

---

## Setup Mode

### Phase 1: Discovery

**Never assume — discover and ask. One question at a time.**

1. **How many GitHub accounts?** Username and purpose of each.

2. **Single or multi-account?**

   If only one account → skip to question 3 (single-account flow, no `includeIf`, no direnv).

   If multiple accounts, present these two layout options with visual examples:

   > **Option A — Primary + secondary.** One account is the default everywhere. The other only activates in its directory:
   >
   > ```
   > ~/
   > ├── code/              ← interstella-5555 (primary — also the default everywhere)
   > │   ├── project-a/
   > │   └── project-b/
   > ├── thorswap/          ← paz-ts (only in this directory)
   > │   ├── project-c/
   > │   └── project-d/
   > └── random-project/    ← interstella-5555 (primary kicks in)
   > ```
   >
   > Git config:
   > ```
   > ~/.gitconfig                ← [user] for interstella-5555 (global default)
   >                               + [includeIf "gitdir:~/thorswap/"]
   > ~/.gitconfig-thorswap       ← [user] for paz-ts (overrides in ~/thorswap/)
   > ```
   >
   > **Option B — Strict separation.** Each account only works in its designated directory. Repos outside have no identity:
   >
   > ```
   > ~/
   > ├── code/              ← interstella-5555 (only here)
   > │   ├── project-a/
   > │   └── project-b/
   > ├── thorswap/          ← paz-ts (only here)
   > │   ├── project-c/
   > │   └── project-d/
   > └── random-project/    ← ⚠️ no identity — commits unsigned, push may fail
   > ```
   >
   > Git config:
   > ```
   > ~/.gitconfig                ← no [user] section, only includeIf blocks
   >                               + [includeIf "gitdir:~/code/"]
   >                               + [includeIf "gitdir:~/thorswap/"]
   > ~/.gitconfig-interstella    ← [user] for interstella-5555
   > ~/.gitconfig-thorswap       ← [user] for paz-ts
   > ```
   >
   > Which layout?

3. **Email and privacy:**

   > Each account needs an email for commits. This email appears in three places that **must all match**:
   > - `ssh-keygen -C "<email>"` (key comment — identifies the key)
   > - `user.email` in gitconfig (attached to every commit)
   > - Email on your GitHub account (GitHub checks this for the "Verified" badge)
   >
   > **For privacy:** go to [github.com/settings/emails](https://github.com/settings/emails) on each account:
   > 1. Enable **"Keep my email address private"**
   > 2. Copy the noreply address: `<id>+<username>@users.noreply.github.com`
   >
   > Using the noreply alias means your real email never appears in public commit history.
   >
   > What email for each account?

4. **Key name suffix:**

   > What suffix for each account's SSH key files? This becomes part of the filename and the gitconfig filename.
   >
   > Examples:
   > - `github_interstella` → key: `~/.ssh/id_ed25519_github_interstella`, config: `~/.gitconfig-github_interstella`
   > - `personal` → key: `~/.ssh/id_ed25519_personal`, config: `~/.gitconfig-personal`
   >
   > What suffix for each account?

5. **Where are repos?** Scan:
   ```bash
   find ~ -maxdepth 3 -name ".git" -type d 2>/dev/null | head -30
   ```
   Group by parent directory. Compare to chosen layout (Option A or B). If repos aren't separated by account yet, **propose** how to reorganize. **Never move repos without explicit per-repo confirmation.**

6. **Existing SSH keys and config?**
   ```bash
   ls -la ~/.ssh/*.pub 2>/dev/null
   cat ~/.ssh/config 2>/dev/null
   ssh-add -l 2>/dev/null
   ```
   If `~/.ssh/config` already has a `Host *` block, note it — will need to merge (not overwrite) in Phase 3.

7. **Existing signing/GPG?**
   ```bash
   git config --global gpg.format
   git config --global user.signingkey
   git config --global gpg.ssh.program
   ```

8. **gh CLI status?**
   ```bash
   gh auth status 2>&1
   ```

9. **Non-GitHub SSH usage?**
   > "Do you use SSH keys for anything other than GitHub? (VPS, servers, other git hosting) — I need to know so I don't break those connections."

### Phase 2: Present Plan

Before touching anything, show what will be created/modified:

- `~/.ssh/config` — SSH agent/keychain configuration
- `~/.ssh/id_ed25519_<suffix>` + `.pub` per account — key pairs on disk
- `~/.gitconfig` — directory-based account switching (`includeIf`)
- `~/.gitconfig-<suffix>` per account — SSH key, signing, identity
- `<directory>/.envrc` per account — direnv `gh` CLI auto-switching

**User must do manually:**
- Add keys to GitHub as Authentication + Signing keys
- `gh auth login` for each account (prompted when ready)

Ask for confirmation before proceeding.

### Phase 3: Execute

Follow `references/setup-guide.md`, using values gathered in Phase 1 (accounts, emails, suffixes, layout option). Do NOT re-ask questions already answered. For each step: explain → do → verify → next.

**For single-account setup:** skip `includeIf`, put everything in `~/.gitconfig` directly. Skip direnv.

**For primary + secondary (Option A):** put primary identity in `~/.gitconfig` global `[user]` section. Only the secondary account gets an `includeIf` override.

**Interactive commands** — three commands require user input and cannot be run by Claude directly:
- `ssh-keygen` — prompts for passphrase
- `ssh-add --apple-use-keychain` — prompts for passphrase
- `gh auth login` — interactive browser auth

When you reach these steps, tell the user:
> "This command needs your input. Run it yourself by typing `!` followed by the command in Claude Code — this runs it in the current session so I can see the output. Example:
> ```
> ! ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_github
> ```
> The `!` prefix runs shell commands directly from the Claude Code prompt."

### Phase 4: Verify

Run all Repair Mode checks (1-10). Everything should pass.

### Phase 5: Cleanup

If old infrastructure found (from previous setup):

> "I found remnants of a previous setup:
> - [list: GPG, old keys, GPG_TTY, 1Password config, Host aliases, etc.]
>
> Want me to clean these up?"

**SSH keys:** backup to `~/.ssh/backup/` (never delete):
> "Old keys backed up to `~/.ssh/backup/`. To remove permanently: `trash ~/.ssh/backup/` (moves to macOS Trash — still recoverable). Keys used for non-GitHub purposes were NOT touched."

**GitHub keys:** tell user to manually review at https://github.com/settings/keys — for each account.

---

## Critical Rules

- **macOS only**
- **Never delete private keys** — `mv` to backup, suggest `trash` for permanent removal
- **Never move repos** without per-repo confirmation
- **Always verify after each step**
- **Ask about non-GitHub SSH usage** before touching any key or SSH config
- **One question at a time**
- **Show don't tell** — run commands to discover, don't ask user to describe
- **`trash` over `rm`** — always mention it moves to macOS Trash (recoverable)
- **Key suffix is user's choice** — always ask, suggest based on account names, never assume
